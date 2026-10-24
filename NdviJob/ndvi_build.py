#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
NTPC_FEC  新北市 NDVI 月報圖磚產生器 (Sentinel-2 L2A, Microsoft Planetary Computer STAC)

流程:
  STAC 搜尋當月 Sentinel-2 -> 依 SCL 去雲/雲影 -> 逐像素中位數合成 NDVI
  -> 水體(SCL) + NDVI 離散分級 -> 用新北市行政區界裁切
  -> 切成 XYZ 圖磚 (PNG-8, 透明) + 各區統計 stats.json + index.json
  -> 原子替換發布, 只保留最近 N 期 (預設 6)

輸出 (預設):  <out>\\index.json
              <out>\\<YYYY-MM>\\{z}\\{x}\\{y}.png
              <out>\\<YYYY-MM>\\stats.json
工作目錄:     <work>\\<YYYY-MM>\\ndvi_class.tif / ndvi_q.tif (供下期變化偵測), <work>\\logs\\

不修改任何現有資料: 任何一步失敗 -> 不動舊圖磚, 結束代碼非 0。
"""
from __future__ import print_function

import argparse
import datetime as dt
import json
import logging
import math
import os
import shutil
import sys
import time

import mercantile
import numpy as np
import planetary_computer as pc
import rasterio
from PIL import Image
from pyproj import Transformer
from pystac_client import Client
from rasterio import features
from rasterio.enums import Resampling
from rasterio.transform import from_bounds, from_origin
from rasterio.warp import reproject
from rasterio.windows import from_bounds as win_from_bounds
import shapely
from shapely.geometry import shape
from shapely.ops import unary_union

STAC_URL = "https://planetarycomputer.microsoft.com/api/stac/v1"
UTM_EPSG = 32651            # 新北市全區落在 UTM 51N, 所有 S2 圖幅同一座標系, 不需逐景重投影
NTPC_COUNTY_CODE = "65000"
SCL_VALID = (2, 4, 5, 6, 7)  # 2 暗部 4 植被 5 裸地 6 水 7 未分類; 排除 0,1,3(雲影),8,9,10(雲/卷雲),11(雪)
SCL_WATER = 6
Q_NODATA = 255              # ndvi_q: 0..200 => ndvi = q/100 - 1

# (id, 名稱, 色碼)   id 0 = 無資料/區外 (透明)
CLASSES = [
    (1, u"水體", "#2B8CBE"),
    (2, u"建物/不透水 (NDVI<0.1)", "#9CA3AF"),
    (3, u"裸露/稀疏 (0.1-0.2)", "#F97316"),
    (4, u"低植被 (0.2-0.4)", "#FACC15"),
    (5, u"中植被 (0.4-0.6)", "#84CC16"),
    (6, u"高植被 (>0.6)", "#15803D"),
]

log = logging.getLogger("ndvi")


# --------------------------------------------------------------------------
# 行政區界 (taiwan-atlas TopoJSON -> shapely)
# --------------------------------------------------------------------------
def decode_topojson_towns(path, county_code=NTPC_COUNTY_CODE):
    with open(path, "rb") as f:
        topo = json.loads(f.read().decode("utf-8"))
    sx, sy = topo["transform"]["scale"]
    tx, ty = topo["transform"]["translate"]

    arcs = []
    for arc in topo["arcs"]:
        x = y = 0
        pts = []
        for dx, dy in arc:
            x += dx
            y += dy
            pts.append((x * sx + tx, y * sy + ty))
        arcs.append(pts)

    def arc_pts(i):
        return arcs[i] if i >= 0 else arcs[~i][::-1]

    def ring(idx_list):
        out = []
        for k, i in enumerate(idx_list):
            p = arc_pts(i)
            out.extend(p if k == 0 else p[1:])
        return out

    def poly(rings):
        return [ring(r) for r in rings]

    towns = []
    for g in topo["objects"]["towns"]["geometries"]:
        p = g.get("properties", {})
        if p.get("COUNTYCODE") != county_code:
            continue
        if g["type"] == "Polygon":
            gj = {"type": "Polygon", "coordinates": poly(g["arcs"])}
        else:
            gj = {"type": "MultiPolygon", "coordinates": [poly(pp) for pp in g["arcs"]]}
        geom = shape(gj)
        if not geom.is_valid:
            geom = geom.buffer(0)
        towns.append({"id": p.get("TOWNID"), "code": p.get("TOWNCODE"),
                      "name": p.get("TOWNNAME"), "geom": geom})
    towns.sort(key=lambda t: t["code"])
    return towns


# --------------------------------------------------------------------------
# STAC
# --------------------------------------------------------------------------
def month_range(month, pad_days):
    y, m = [int(v) for v in month.split("-")]
    start = dt.date(y, m, 1)
    end = dt.date(y + (m == 12), (m % 12) + 1, 1) - dt.timedelta(days=1)
    start = start - dt.timedelta(days=pad_days)
    return start, end


def item_epsg(item):
    """相容新舊 STAC projection extension: proj:epsg (舊) / proj:code='EPSG:xxxxx' (新)"""
    e = item.properties.get("proj:epsg")
    if e:
        return int(e)
    code = item.properties.get("proj:code") or ""
    if code.upper().startswith("EPSG:"):
        return int(code.split(":")[1])
    return None


def search_items(bbox, aoi_wgs, start, end, max_cloud):
    client = Client.open(STAC_URL, modifier=pc.sign_inplace)
    s = client.search(
        collections=["sentinel-2-l2a"], bbox=bbox,
        datetime="%s/%s" % (start.isoformat(), end.isoformat()),
        query={"eo:cloud_cover": {"lt": max_cloud}})
    items = []
    for it in s.items():
        if item_epsg(it) != UTM_EPSG:
            log.warning("skip %s (epsg=%s)", it.id, item_epsg(it))
            continue
        if not shape(it.geometry).intersects(aoi_wgs):
            continue
        items.append(it)
    items.sort(key=lambda i: i.datetime)
    return items


def boa_offset(item):
    """L2A processing baseline >= 04.00 的反射率 DN 有 +1000 offset, 需先扣除再算 NDVI"""
    try:
        return 1000.0 if float(item.properties.get("s2:processing_baseline", "0")) >= 4.0 else 0.0
    except ValueError:
        return 1000.0 if item.datetime.date() >= dt.date(2022, 1, 25) else 0.0


def retry(fn, tries=4, delay=3):
    for k in range(tries):
        try:
            return fn()
        except Exception as e:  # noqa
            if k == tries - 1:
                raise
            log.warning("read retry %d: %s", k + 1, e)
            time.sleep(delay * (k + 1))


def read_rect(ds, left, top, res, w, h, resampling):
    """讀取與目標網格 (left,top,res,w,h) 重疊的部分; 回傳 (r0,c0,array) 或 None"""
    b = ds.bounds
    il, ir = max(left, b.left), min(left + w * res, b.right)
    it_, ib = min(top, b.top), max(top - h * res, b.bottom)
    if ir <= il or it_ <= ib:
        return None
    c0, c1 = int(round((il - left) / res)), int(round((ir - left) / res))
    r0, r1 = int(round((top - it_) / res)), int(round((top - ib) / res))
    if c1 <= c0 or r1 <= r0:
        return None
    win = win_from_bounds(il, ib, ir, it_, transform=ds.transform)
    arr = ds.read(1, window=win, out_shape=(r1 - r0, c1 - c0), resampling=resampling)
    return r0, c0, arr


# --------------------------------------------------------------------------
# 合成
# --------------------------------------------------------------------------
def composite(items, left, top, res, W, H, stripe_rows):
    """回傳 ndvi_q(uint8), obs(uint8 有效觀測數), water_votes(uint8)"""
    ndvi_q = np.full((H, W), Q_NODATA, np.uint8)
    obs = np.zeros((H, W), np.uint8)
    water = np.zeros((H, W), np.uint8)
    offsets = [boa_offset(i) for i in items]
    rs_band = Resampling.average if res > 10 else Resampling.nearest

    for r_start in range(0, H, stripe_rows):
        h = min(stripe_rows, H - r_start)
        s_top = top - r_start * res
        stack = np.full((len(items), h, W), Q_NODATA, np.uint8)
        v_cnt = np.zeros((h, W), np.uint8)
        w_cnt = np.zeros((h, W), np.uint8)
        used = 0
        t0 = time.time()
        for k, item in enumerate(items):
            signed = pc.sign(item)
            hr = {a: signed.assets[a].href for a in ("B04", "B08", "SCL")}

            def _read():
                with rasterio.open(hr["B04"]) as d4, rasterio.open(hr["B08"]) as d8, \
                        rasterio.open(hr["SCL"]) as ds:
                    a = read_rect(d4, left, s_top, res, W, h, rs_band)
                    if a is None:
                        return None
                    r0, c0, red = a
                    _, _, nir = read_rect(d8, left, s_top, res, W, h, rs_band)
                    _, _, scl = read_rect(ds, left, s_top, res, W, h, Resampling.nearest)
                    return r0, c0, red, nir, scl

            got = retry(_read)
            if got is None:
                continue
            r0, c0, red, nir, scl = got
            hh, ww = red.shape
            red = red.astype(np.float32)
            nir = nir.astype(np.float32)
            dn_ok = (red > 0) & (nir > 0)
            red = np.maximum(red - offsets[k], 0)
            nir = np.maximum(nir - offsets[k], 0)
            den = nir + red
            valid = dn_ok & np.isin(scl, SCL_VALID) & (den > 0)
            nd = np.zeros_like(den)
            np.divide(nir - red, den, out=nd, where=den > 0)
            q = np.clip(np.rint((nd + 1.0) * 100.0), 0, 200).astype(np.uint8)
            q[~valid] = Q_NODATA
            stack[k, r0:r0 + hh, c0:c0 + ww] = q
            v_cnt[r0:r0 + hh, c0:c0 + ww] += valid
            w_cnt[r0:r0 + hh, c0:c0 + ww] += (valid & (scl == SCL_WATER))
            used += 1

        # 逐像素中位數 (忽略 255)
        srt = np.sort(stack, axis=0)
        idx = (np.maximum(v_cnt.astype(np.int16) - 1, 0) // 2)[None].astype(np.intp)
        med = np.take_along_axis(srt, idx, axis=0)[0]
        med[v_cnt == 0] = Q_NODATA
        ndvi_q[r_start:r_start + h] = med
        obs[r_start:r_start + h] = v_cnt
        water[r_start:r_start + h] = w_cnt
        log.info("stripe rows %d-%d  items_used=%d  %.0fs", r_start, r_start + h, used, time.time() - t0)
        del stack, srt
    return ndvi_q, obs, water


def classify(ndvi_q, obs, water, town_mask):
    q = ndvi_q.astype(np.int16)
    cls = 2 + (q >= 110).astype(np.uint8) + (q >= 120) + (q >= 140) + (q >= 160)
    cls = cls.astype(np.uint8)
    cls[(obs > 0) & (water.astype(np.int16) * 2 > obs)] = 1
    cls[obs == 0] = 0
    cls[town_mask == 0] = 0
    return cls


# --------------------------------------------------------------------------
# 圖磚
# --------------------------------------------------------------------------
def hex_rgb(h):
    h = h.lstrip("#")
    return [int(h[i:i + 2], 16) for i in (0, 2, 4)]


def build_palette():
    pal = [0] * 768
    for cid, _, col in CLASSES:
        pal[cid * 3:cid * 3 + 3] = hex_rgb(col)
    return pal


def make_tiles(cls, transform, wgs_bbox, zmin, zmax, out_dir):
    pal = build_palette()
    src_crs = "EPSG:%d" % UTM_EPSG
    total = 0
    for z in range(zmax, zmin - 1, -1):
        rs = Resampling.nearest if z >= zmax else Resampling.mode
        n = 0
        for t in mercantile.tiles(wgs_bbox[0], wgs_bbox[1], wgs_bbox[2], wgs_bbox[3], zooms=[z]):
            b = mercantile.xy_bounds(t)
            dst = np.zeros((256, 256), np.uint8)
            reproject(source=cls, destination=dst, src_transform=transform, src_crs=src_crs,
                      dst_transform=from_bounds(b.left, b.bottom, b.right, b.top, 256, 256),
                      dst_crs="EPSG:3857", resampling=rs, src_nodata=0, dst_nodata=0)
            if not dst.any():
                continue
            d = os.path.join(out_dir, str(z), str(t.x))
            if not os.path.isdir(d):
                os.makedirs(d)
            im = Image.fromarray(dst)
            im.putpalette(pal)
            im.save(os.path.join(d, "%d.png" % t.y), optimize=True, transparency=0)
            n += 1
        log.info("z%d: %d tiles", z, n)
        total += n
    return total


# --------------------------------------------------------------------------
# 統計
# --------------------------------------------------------------------------
def town_stats(cls, ndvi_q, obs, town_idx, towns, res):
    nt = len(towns) + 1
    cnt = np.zeros((nt, 8), np.int64)       # [town, cls 0..6] ; cls0 = 區內無資料
    tot = np.zeros(nt, np.int64)
    ssum = np.zeros(nt, np.float64)
    ocnt = np.zeros(nt, np.float64)
    step = 1024
    for r in range(0, cls.shape[0], step):
        ti = town_idx[r:r + step].ravel().astype(np.int64)
        cl = cls[r:r + step].ravel().astype(np.int64)
        qq = ndvi_q[r:r + step].ravel()
        ob = obs[r:r + step].ravel().astype(np.float64)
        inside = ti > 0
        ti, cl, qq, ob = ti[inside], cl[inside], qq[inside], ob[inside]
        cnt += np.bincount(ti * 8 + cl, minlength=nt * 8).reshape(nt, 8)
        ok = qq != Q_NODATA
        tot += np.bincount(ti[ok], minlength=nt)
        ssum += np.bincount(ti[ok], weights=(qq[ok].astype(np.float64) / 100.0 - 1.0), minlength=nt)
        ocnt += np.bincount(ti, weights=ob, minlength=nt)
    km2 = (res * res) / 1e6
    rows = []
    for i, t in enumerate(towns, start=1):
        c = cnt[i]
        area = float(c.sum()) * km2
        rows.append({
            "id": t["id"], "code": t["code"], "name": t["name"],
            "area_km2": round(area, 3),
            "nodata_km2": round(float(c[0]) * km2, 3),
            "coverage_pct": round(100.0 * (1 - float(c[0]) / max(float(c.sum()), 1.0)), 1),
            "mean_ndvi": round(float(ssum[i] / tot[i]), 4) if tot[i] > 0 else None,
            "mean_obs": round(float(ocnt[i] / max(float(c.sum()), 1.0)), 2),
            "class_km2": dict((str(k), round(float(c[k]) * km2, 3)) for k in range(1, 7)),
        })
    csum = cnt[1:].sum(axis=0)
    city_tot = int(tot[1:].sum())
    city = {
        "area_km2": round(float(csum.sum()) * km2, 3),
        "nodata_km2": round(float(csum[0]) * km2, 3),
        "mean_ndvi": round(float(ssum[1:].sum() / city_tot), 4) if city_tot > 0 else None,
        "class_km2": dict((str(k), round(float(csum[k]) * km2, 3)) for k in range(1, 7)),
    }
    return rows, city


# --------------------------------------------------------------------------
# 發布 / 輪替
# --------------------------------------------------------------------------
def write_json_atomic(path, obj):
    tmp = path + ".tmp"
    with open(tmp, "wb") as f:
        f.write(json.dumps(obj, ensure_ascii=False, indent=1).encode("utf-8"))
    os.replace(tmp, path)


def rmtree_force(p):
    if os.path.isdir(p):
        shutil.rmtree(p, ignore_errors=True)


IIS_WEB_CONFIG = u"""<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <system.webServer>
    <staticContent>
      <remove fileExtension=".json" />
      <mimeMap fileExtension=".json" mimeType="application/json" />
    </staticContent>
    <httpProtocol>
      <customHeaders>
        <add name="Cache-Control" value="public, max-age=3600" />
      </customHeaders>
    </httpProtocol>
  </system.webServer>
</configuration>
"""


def ensure_iis_config(out_root):
    """Tiles 目錄內放 web.config: 確保 .json MIME 存在 (IIS 舊設定可能沒有), 圖磚快取 1 小時"""
    p = os.path.join(out_root, "web.config")
    if not os.path.isfile(p):
        with open(p, "wb") as f:
            f.write(IIS_WEB_CONFIG.encode("utf-8"))


def export_towns_geojson(towns, path):
    """輸出前端用的行政區界 GeoJSON (WGS84, 座標取 5 位小數, 約 1m)"""
    feats = []
    for t in towns:
        g = shapely.set_precision(t["geom"].simplify(0.00002, preserve_topology=True), 0.00001)
        feats.append({"type": "Feature",
                      "properties": {"id": t["id"], "code": t["code"], "name": t["name"]},
                      "geometry": json.loads(shapely.to_geojson(g))})
    d = os.path.dirname(path)
    if d and not os.path.isdir(d):
        os.makedirs(d)
    with open(path, "wb") as f:
        f.write(json.dumps({"type": "FeatureCollection", "features": feats},
                           ensure_ascii=False, separators=(",", ":")).encode("utf-8"))


def publish(out_root, period, build_dir, meta, keep, wgs_bounds, zmin, zmax):
    final = os.path.join(out_root, period)
    old = os.path.join(out_root, ".old_" + period)
    rmtree_force(old)
    if os.path.isdir(final):
        os.rename(final, old)
    os.rename(build_dir, final)
    rmtree_force(old)

    idx_path = os.path.join(out_root, "index.json")
    idx = {"periods": []}
    if os.path.isfile(idx_path):
        try:
            with open(idx_path, "rb") as f:
                idx = json.loads(f.read().decode("utf-8"))
        except Exception:  # noqa
            idx = {"periods": []}
    periods = [p for p in idx.get("periods", []) if p["id"] != period]
    periods.append(meta)
    periods.sort(key=lambda p: p["id"], reverse=True)
    for p in periods[keep:]:
        log.info("prune old period %s", p["id"])
        rmtree_force(os.path.join(out_root, p["id"]))
    periods = periods[:keep]
    idx = {
        "updated": dt.datetime.now().isoformat(timespec="seconds"),
        "latest": periods[0]["id"],
        "bounds": wgs_bounds, "zmin": zmin, "zmax": zmax,
        "classes": [{"id": c[0], "name": c[1], "color": c[2]} for c in CLASSES],
        "periods": periods,
    }
    write_json_atomic(idx_path, idx)


# --------------------------------------------------------------------------
def main():
    here = os.path.dirname(os.path.abspath(__file__))
    today = dt.date.today()
    prev = (today.replace(day=1) - dt.timedelta(days=1)).strftime("%Y-%m")

    ap = argparse.ArgumentParser(description="NTPC NDVI monthly tile builder")
    ap.add_argument("--month", default=prev, help="YYYY-MM (預設: 上個月)")
    ap.add_argument("--pad-days", type=int, default=0, help="往前多取幾天影像以補雲 (預設 0)")
    ap.add_argument("--out", default=r"D:\Web\NTPC_FECM\NDVI\Tiles")
    ap.add_argument("--work", default=r"D:\NdviJob\work")
    ap.add_argument("--boundary", default=os.path.join(here, "towns-10t.json"))
    ap.add_argument("--zmin", type=int, default=10)
    ap.add_argument("--zmax", type=int, default=14)
    ap.add_argument("--res", type=int, default=10, choices=[10, 20], help="合成解析度(m); 20 較快")
    ap.add_argument("--max-cloud", type=float, default=70.0, help="單景雲量上限 %%")
    ap.add_argument("--keep", type=int, default=6)
    ap.add_argument("--towns", default="", help="僅處理指定區 (逗號分隔, 測試用), 例: 板橋區,永和區")
    ap.add_argument("--min-coverage", type=float, default=85.0, help="有效覆蓋率目標 %%, 未達則自動延長取樣窗")
    ap.add_argument("--auto-pad-days", type=int, default=15, help="覆蓋率不足時往前延長天數")
    ap.add_argument("--max-items", type=int, default=0, help="僅用前 N 景 (測試用)")
    ap.add_argument("--export-towns", default="", help="只輸出行政區界 GeoJSON 到指定路徑後結束")
    args = ap.parse_args()

    if args.export_towns:
        tw = decode_topojson_towns(args.boundary)
        export_towns_geojson(tw, args.export_towns)
        print("exported %d towns -> %s" % (len(tw), args.export_towns))
        return

    period = args.month
    logdir = os.path.join(args.work, "logs")
    os.makedirs(logdir, exist_ok=True)
    fmt = "%(asctime)s %(levelname)s %(message)s"
    logging.basicConfig(level=logging.INFO, format=fmt, handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler(os.path.join(logdir, "ndvi_%s.log" % period), encoding="utf-8")])
    t_start = time.time()
    log.info("=== NDVI build %s (res=%dm z%d-%d) ===", period, args.res, args.zmin, args.zmax)

    towns = decode_topojson_towns(args.boundary)
    only = [s.strip() for s in args.towns.split(",") if s.strip()]
    if only:
        towns = [t for t in towns if t["name"] in only]
    if not towns:
        raise RuntimeError("no towns matched")
    log.info("towns: %d", len(towns))

    aoi_wgs = unary_union([t["geom"] for t in towns])
    minx, miny, maxx, maxy = aoi_wgs.bounds
    wgs_bbox = [minx, miny, maxx, maxy]
    to_utm = Transformer.from_crs(4326, UTM_EPSG, always_xy=True).transform

    def _fwd(c):
        x, y = to_utm(c[:, 0], c[:, 1])
        return np.column_stack([x, y])

    towns_utm = [shapely.transform(t["geom"], _fwd) for t in towns]
    ub = unary_union(towns_utm).bounds

    res = float(args.res)
    snap = 20.0
    left = math.floor(ub[0] / snap) * snap
    top = math.ceil(ub[3] / snap) * snap
    W = int(math.ceil((ub[2] - left) / res))
    H = int(math.ceil((top - ub[1]) / res))
    transform = from_origin(left, top, res, res)
    log.info("grid %d x %d px (%.1f M px)", W, H, W * H / 1e6)

    env = rasterio.Env(GDAL_DISABLE_READDIR_ON_OPEN="EMPTY_DIR", CPL_VSIL_CURL_ALLOWED_EXTENSIONS=".tif",
                       GDAL_HTTP_MAX_RETRY="5", GDAL_HTTP_RETRY_DELAY="2", GDAL_HTTP_TIMEOUT="60",
                       VSI_CACHE="TRUE", GDAL_HTTP_MULTIPLEX="YES")
    town_idx = np.zeros((H, W), np.uint8)
    shapes = [(g, i) for i, g in enumerate(towns_utm, start=1)]
    features.rasterize(shapes, out=town_idx, transform=transform, fill=0, dtype="uint8")
    inside = town_idx > 0

    # 先用當月影像; 有效覆蓋率不足 (雲多/颱風月) 時, 自動往前延長取樣窗再合成一次
    pads = [args.pad_days] if args.pad_days else [0, args.auto_pad_days]
    ndvi_q = obs = cls = items = None
    covered = 0.0
    start = end = None
    for attempt, pad in enumerate(pads):
        last = (attempt == len(pads) - 1)
        s2, e2 = month_range(period, pad)
        its = search_items(wgs_bbox, aoi_wgs, s2, e2, args.max_cloud)
        if args.max_items:
            its = its[:args.max_items]
        log.info("[try %d] scenes: %d  (%s ~ %s, cloud<%s)", attempt + 1, len(its), s2, e2, args.max_cloud)
        if not its:
            if last and items is None:
                raise RuntimeError("no Sentinel-2 scenes found; keep existing data")
            continue
        for i in its:
            log.info("  %s  %s  cloud=%.1f", i.id, i.datetime.date(), i.properties.get("eo:cloud_cover", -1))
        stripe_rows = int(max(64, min(2048, 220e6 / (len(its) * W))))
        log.info("stripe rows: %d", stripe_rows)
        with env:
            q2, o2, w2 = composite(its, left, top, res, W, H, stripe_rows)
        c2 = classify(q2, o2, w2, town_idx)
        cov2 = float((c2[inside] > 0).mean()) if inside.any() else 0.0
        log.info("[try %d] valid coverage inside AOI: %.1f%%", attempt + 1, cov2 * 100)
        if cov2 >= covered:
            ndvi_q, obs, cls, items, covered, start, end = q2, o2, c2, its, cov2, s2, e2
        if cov2 >= args.min_coverage / 100.0:
            break
        if not last:
            log.warning("coverage %.1f%% < %.0f%%: extend window by %d days", cov2 * 100,
                        args.min_coverage, args.auto_pad_days)
    if cls is None or covered < 0.05:
        raise RuntimeError("coverage too low (%.1f%%); keep existing data" % (covered * 100))
    # 工作目錄: 保留 class / ndvi_q 供下期變化偵測
    wdir = os.path.join(args.work, period)
    os.makedirs(wdir, exist_ok=True)
    prof = dict(driver="GTiff", height=H, width=W, count=1, dtype="uint8",
                crs="EPSG:%d" % UTM_EPSG, transform=transform, compress="lzw")
    with rasterio.open(os.path.join(wdir, "ndvi_class.tif"), "w", nodata=0, **prof) as d:
        d.write(cls, 1)
    with rasterio.open(os.path.join(wdir, "ndvi_q.tif"), "w", nodata=Q_NODATA, **prof) as d:
        d.write(ndvi_q, 1)

    rows, city = town_stats(cls, ndvi_q, obs, town_idx, towns, res)

    os.makedirs(args.out, exist_ok=True)
    ensure_iis_config(args.out)
    build_dir = os.path.join(args.out, ".build_" + period)
    rmtree_force(build_dir)
    os.makedirs(build_dir)
    try:
        n_tiles = make_tiles(cls, transform, wgs_bbox, args.zmin, args.zmax, build_dir)
        meta = {
            "id": period, "label": u"%s年%d月" % tuple(period.split("-")[:1] + [int(period.split("-")[1])]),
            "range": [start.isoformat(), end.isoformat()], "res_m": int(res),
            "scenes": [{"id": i.id, "date": i.datetime.date().isoformat(),
                        "cloud": i.properties.get("eo:cloud_cover")} for i in items],
            "coverage_pct": round(covered * 100, 1), "tiles": n_tiles,
            "stats": "%s/stats.json" % period,
            "built": dt.datetime.now().isoformat(timespec="seconds"),
        }
        write_json_atomic(os.path.join(build_dir, "stats.json"),
                          {"period": meta, "classes": [{"id": c[0], "name": c[1], "color": c[2]} for c in CLASSES],
                           "city": city, "towns": rows})
        publish(args.out, period, build_dir, meta, args.keep,
                [[miny, minx], [maxy, maxx]], args.zmin, args.zmax)
    except Exception:
        rmtree_force(build_dir)
        raise

    # 工作目錄輪替
    kept = sorted([d for d in os.listdir(args.work)
                   if len(d) == 7 and d[4] == "-" and os.path.isdir(os.path.join(args.work, d))], reverse=True)
    for d in kept[args.keep + 1:]:
        rmtree_force(os.path.join(args.work, d))

    log.info("=== DONE %s  tiles=%d  %.1f min ===", period, n_tiles, (time.time() - t_start) / 60.0)


if __name__ == "__main__":
    try:
        main()
    except Exception as e:  # noqa
        logging.getLogger("ndvi").exception("FAILED: %s", e)
        sys.exit(1)
