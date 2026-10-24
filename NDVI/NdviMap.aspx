<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="NdviMap.aspx.cs" Inherits="NTPC_FEC.NDVI.NdviMap" %>

<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定溢散源管理平台 - NDVI 植被監測</title>

    <!-- 專屬 Favicon -->
    <link rel="shortcut icon" href="../favicon.ico" type="image/x-icon" />

    <!-- 本地化核心樣式庫 -->
    <link rel="stylesheet" href="../Content/bootstrap.min.css" />
    <link rel="stylesheet" href="../Content/fontawesome/css/all.min.css" />
    <link rel="stylesheet" href="../Content/leaflet/leaflet.css" />

    <style>
        :root {
            --brand-primary: #0099e5;
            --brand-blue: #0284c7;
            --brand-dark-blue: #0b1f7d;
            --brand-navy: #0f172a;
            --bg-canvas: #f1f5f9;
            --surface: #ffffff;
            --border-color: #e2e8f0;
            --text-main: #0f172a;
            --text-muted: #64748b;
        }

        * { box-sizing: border-box; -webkit-tap-highlight-color: transparent; }
        html, body { height: 100%; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, "Noto Sans TC", "微軟正黑體", sans-serif;
            background-color: var(--bg-canvas);
            margin: 0; padding: 0;
            color: var(--text-main);
            overflow-x: hidden;
        }
        [v-cloak] { display: none !important; }

        .top-navbar {
            background: linear-gradient(135deg, #0099e5 0%, #0284c7 100%);
            color: #ffffff;
            height: 56px;
            display: flex; align-items: center; justify-content: space-between;
            padding: 0 16px;
            box-shadow: 0 2px 10px rgba(0, 153, 229, 0.25);
            position: sticky; top: 0; z-index: 1020;
        }
        .top-navbar .title { font-size: 1.1rem; font-weight: 700; display: flex; align-items: center; gap: 8px; }
        .top-navbar a { color: #fff; text-decoration: none; font-size: .9rem; }

        .layout { display: flex; height: calc(100vh - 56px); }
        .side { width: 410px; flex: none; overflow-y: auto; padding: 12px; }
        .mapwrap { flex: 1; position: relative; min-width: 0; }
        #map { position: absolute; top: 0; right: 0; bottom: 0; left: 0; z-index: 10; }

        .card-modern {
            background: var(--surface);
            border-radius: 12px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05), 0 4px 12px rgba(15, 23, 42, 0.05);
            margin-bottom: 12px;
            border: 1px solid var(--border-color);
            overflow: hidden;
        }
        .card-modern-header {
            padding: 10px 14px;
            border-bottom: 1px solid var(--border-color);
            display: flex; align-items: center; justify-content: space-between;
        }
        .card-modern-title { font-size: .95rem; font-weight: 700; color: var(--brand-navy); margin: 0; display: flex; align-items: center; gap: 8px; }
        .card-modern-body { padding: 12px 14px; }
        .lbl { font-size: .8rem; color: var(--text-muted); font-weight: 600; margin: 8px 0 4px; display: block; }

        .seg { display: flex; border: 1px solid var(--border-color); border-radius: 8px; overflow: hidden; }
        .seg button { flex: 1; border: 0; background: #fff; padding: 7px 4px; font-size: .85rem; cursor: pointer; color: var(--text-main); }
        .seg button.on { background: var(--brand-blue); color: #fff; font-weight: 700; }

        .legend-row { display: flex; align-items: center; gap: 8px; font-size: .85rem; padding: 2px 0; }
        .chip { width: 18px; height: 14px; border-radius: 3px; border: 1px solid rgba(0,0,0,.15); flex: none; }

        .stackbar { display: flex; height: 18px; border-radius: 6px; overflow: hidden; background: #e2e8f0; }
        .stackbar > div { height: 100%; }
        .kv { display: flex; justify-content: space-between; font-size: .85rem; padding: 2px 0; }
        .kv b { font-variant-numeric: tabular-nums; }
        .up { color: #15803d; font-weight: 700; }
        .down { color: #b91c1c; font-weight: 700; }

        table.mini { width: 100%; font-size: .8rem; border-collapse: collapse; }
        table.mini th { position: sticky; top: 0; background: #f8fafc; color: var(--text-muted); font-weight: 700; padding: 6px 4px; cursor: pointer; white-space: nowrap; border-bottom: 1px solid var(--border-color); }
        table.mini td { padding: 5px 4px; border-bottom: 1px solid #f1f5f9; font-variant-numeric: tabular-nums; }
        table.mini tr.rowlink { cursor: pointer; }
        table.mini tr.rowlink:hover { background: #f0f9ff; }
        table.mini tr.sel { background: #e0f2fe; }
        .scroll-box { max-height: 300px; overflow-y: auto; }

        .tag { display: inline-block; padding: 1px 7px; border-radius: 10px; font-size: .72rem; font-weight: 700; color: #fff; }
        .tag-h { background: #dc2626; } .tag-m { background: #f59e0b; } .tag-l { background: #16a34a; } .tag-n { background: #94a3b8; }

        .notice { background: #fff7ed; color: #9a3412; border: 1px solid #fed7aa; border-radius: 8px; padding: 8px 10px; font-size: .85rem; margin-bottom: 12px; }
        .busy { position: absolute; top: 10px; left: 50%; transform: translateX(-50%); z-index: 900; background: rgba(15,23,42,.8); color: #fff; padding: 4px 12px; border-radius: 14px; font-size: .8rem; }

        /* 卷簾 */
        #swipeBar { position: absolute; top: 0; bottom: 0; width: 6px; margin-left: -3px; background: #fff; box-shadow: 0 0 6px rgba(0,0,0,.5); z-index: 800; cursor: ew-resize; touch-action: none; }
        #swipeBar .grip { position: absolute; top: 50%; left: 50%; width: 34px; height: 34px; margin: -17px 0 0 -17px; border-radius: 50%; background: #fff; box-shadow: 0 1px 6px rgba(0,0,0,.5); display: flex; align-items: center; justify-content: center; color: var(--brand-blue); }
        .swipe-tag { position: absolute; top: 10px; z-index: 790; background: rgba(15,23,42,.8); color: #fff; padding: 2px 10px; border-radius: 12px; font-size: .8rem; pointer-events: none; }

        .map-toggle { display: none; }
        /* NDVI 為 10 m 分類像素，放大時保持清晰方塊，不做平滑模糊 */
        .ndvi-tile { image-rendering: pixelated; image-rendering: crisp-edges; }

        @media screen and (max-width: 991px) {
            .layout { flex-direction: column; height: auto; }
            .mapwrap { order: -1; flex: none; height: 58vh; position: sticky; top: 56px; z-index: 30; }
            .mapwrap.collapsed { height: 120px; }
            .side { width: 100%; overflow: visible; padding-bottom: 80px; }
            .map-toggle { display: inline-block; }
        }
    </style>
</head>
<body>
    <div id="ndviApp" v-cloak>
        <div class="top-navbar">
            <div class="title"><i class="fas fa-satellite"></i> 新北市 NDVI 植被監測</div>
            <div>
                <button type="button" class="btn btn-sm btn-light map-toggle mr-2" v-on:click="toggleMap">{{ mapCollapsed ? '展開地圖' : '收合地圖' }}</button>
                <a href="../MainPage.aspx"><i class="fas fa-home"></i> 回首頁</a>
            </div>
        </div>

        <div class="layout">
            <aside class="side">
                <div class="notice" v-if="errMsg"><i class="fas fa-exclamation-triangle"></i> {{ errMsg }}</div>

                <!-- 圖層控制 -->
                <div class="card-modern">
                    <div class="card-modern-header"><h6 class="card-modern-title"><i class="fas fa-layer-group text-primary"></i> 圖層控制</h6></div>
                    <div class="card-modern-body">
                        <span class="lbl">底圖</span>
                        <div class="seg">
                            <button type="button" v-bind:class="{on: base==='emap'}" v-on:click="base='emap'">電子地圖</button>
                            <button type="button" v-bind:class="{on: base==='photo'}" v-on:click="base='photo'">正射影像</button>
                            <button type="button" v-bind:class="{on: base==='osm'}" v-on:click="base='osm'">OSM</button>
                        </div>

                        <span class="lbl">檢視模式</span>
                        <div class="seg">
                            <button type="button" v-bind:class="{on: !cmpMode}" v-on:click="cmpMode=false">單期</button>
                            <button type="button" v-bind:class="{on: cmpMode}" v-bind:disabled="periods.length < 2" v-on:click="cmpMode=true">卷簾比對</button>
                        </div>

                        <template v-if="!cmpMode">
                            <span class="lbl">統計期別</span>
                            <select class="form-control form-control-sm" v-model="periodId" v-bind:disabled="!periods.length">
                                <option v-for="p in periods" v-bind:key="p.id" v-bind:value="p.id">{{ p.label }}（{{ p.scenes.length }} 景，覆蓋 {{ p.coverage_pct }}%）</option>
                            </select>
                        </template>
                        <template v-else>
                            <span class="lbl">左側期別 (A)</span>
                            <select class="form-control form-control-sm" v-model="periodA">
                                <option v-for="p in periods" v-bind:key="p.id" v-bind:value="p.id">{{ p.label }}</option>
                            </select>
                            <span class="lbl">右側期別 (B)</span>
                            <select class="form-control form-control-sm" v-model="periodB">
                                <option v-for="p in periods" v-bind:key="p.id" v-bind:value="p.id">{{ p.label }}</option>
                            </select>
                        </template>

                        <span class="lbl">NDVI 透明度 {{ opacity }}%</span>
                        <input type="range" class="custom-range" min="0" max="100" v-model.number="opacity" />
                        <div class="custom-control custom-switch mt-2">
                            <input type="checkbox" class="custom-control-input" id="swNdvi" v-model="showNdvi" />
                            <label class="custom-control-label" for="swNdvi">顯示 NDVI 圖層</label>
                        </div>
                        <div class="custom-control custom-switch mt-1">
                            <input type="checkbox" class="custom-control-input" id="swTown" v-model="showTowns" />
                            <label class="custom-control-label" for="swTown">顯示行政區界</label>
                        </div>
                        <div class="text-muted mt-2" style="font-size:.75rem" v-if="curMeta">
                            資料：Sentinel-2 L2A（10 m），{{ curMeta.range[0] }} ~ {{ curMeta.range[1] }} 逐像素中位數合成，已排除雲/雲影。更新於 {{ curMeta.built.replace('T',' ') }}
                        </div>
                    </div>
                </div>

                <!-- 圖例 -->
                <div class="card-modern" v-if="classes.length">
                    <div class="card-modern-header"><h6 class="card-modern-title"><i class="fas fa-palette text-primary"></i> 圖例</h6></div>
                    <div class="card-modern-body">
                        <div class="legend-row" v-for="c in classes" v-bind:key="c.id"><span class="chip" v-bind:style="{background:c.color}"></span>{{ c.name }}</div>
                        <div class="text-muted mt-1" style="font-size:.75rem">點擊地圖任一處可查詢該位置 NDVI 類別。</div>
                    </div>
                </div>

                <!-- 點查詢 -->
                <div class="card-modern" v-if="pointInfo">
                    <div class="card-modern-header">
                        <h6 class="card-modern-title"><i class="fas fa-crosshairs text-danger"></i> 點位查詢</h6>
                        <button type="button" class="btn btn-sm btn-link p-0" v-on:click="pointInfo=null">關閉</button>
                    </div>
                    <div class="card-modern-body">
                        <div class="kv"><span>座標</span><b>{{ pointInfo.lat.toFixed(5) }}, {{ pointInfo.lng.toFixed(5) }}</b></div>
                        <div class="kv" v-for="r in pointInfo.rows" v-bind:key="r.label">
                            <span>{{ r.label }}</span>
                            <b><span class="chip d-inline-block align-middle mr-1" v-bind:style="{background:r.color}"></span>{{ r.name }}</b>
                        </div>
                        <div class="kv" v-if="pointInfo.change"><span>變化</span><b v-bind:class="pointInfo.changeCls">{{ pointInfo.change }}</b></div>
                    </div>
                </div>

                <!-- 行政區統計 -->
                <div class="card-modern" v-if="selStat">
                    <div class="card-modern-header">
                        <h6 class="card-modern-title"><i class="fas fa-chart-pie text-success"></i> {{ selStat.name }}　{{ curLabel }}</h6>
                        <button type="button" class="btn btn-sm btn-link p-0" v-on:click="clearTown">取消選取</button>
                    </div>
                    <div class="card-modern-body">
                        <div class="stackbar mb-2">
                            <div v-for="c in classes" v-bind:key="c.id" v-bind:style="{width: pct(selStat, c.id) + '%', background: c.color}" v-bind:title="c.name + ' ' + pct(selStat, c.id).toFixed(1) + '%'"></div>
                        </div>
                        <div class="kv"><span>面積</span><b>{{ selStat.area_km2.toFixed(2) }} km²</b></div>
                        <div class="kv"><span>平均 NDVI</span>
                            <b>{{ fmt(selStat.mean_ndvi) }}<span v-if="selDelta !== null" v-bind:class="selDelta >= 0 ? 'up' : 'down'">　{{ selDelta >= 0 ? '▲' : '▼' }} {{ Math.abs(selDelta).toFixed(3) }}</span></b></div>
                        <div class="kv"><span>有效資料覆蓋</span><b>{{ selStat.coverage_pct }}%（平均 {{ selStat.mean_obs }} 次觀測）</b></div>
                        <table class="mini mt-2">
                            <thead><tr><th>類別</th><th>km²</th><th>%</th><th v-if="selPrev">較上期</th></tr></thead>
                            <tbody>
                                <tr v-for="c in classes" v-bind:key="c.id">
                                    <td><span class="chip d-inline-block align-middle mr-1" v-bind:style="{background:c.color}"></span>{{ shortName(c.name) }}</td>
                                    <td>{{ selStat.class_km2[c.id].toFixed(2) }}</td>
                                    <td>{{ pct(selStat, c.id).toFixed(1) }}</td>
                                    <td v-if="selPrev" v-bind:class="diffClass(selStat.class_km2[c.id] - selPrev.class_km2[c.id], c.id)">{{ signed(selStat.class_km2[c.id] - selPrev.class_km2[c.id]) }}</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>

                <!-- 各區排行 -->
                <div class="card-modern" v-if="rankRows.length">
                    <div class="card-modern-header"><h6 class="card-modern-title"><i class="fas fa-ranking-star text-warning"></i> 各區 NDVI 排行（{{ curLabel }}）</h6></div>
                    <div class="card-modern-body p-0">
                        <div class="scroll-box">
                            <table class="mini">
                                <thead>
                                    <tr>
                                        <th v-on:click="sortBy('name')">行政區</th>
                                        <th v-on:click="sortBy('mean_ndvi')">平均NDVI</th>
                                        <th v-on:click="sortBy('delta')" v-if="hasPrev">較上期</th>
                                        <th v-on:click="sortBy('bare_pct')">裸露+不透水%</th>
                                        <th v-on:click="sortBy('green_pct')">中高植被%</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr v-for="r in rankRows" v-bind:key="r.code" class="rowlink" v-bind:class="{sel: r.code===selTown}" v-on:click="selectTown(r.code, true)">
                                        <td>{{ r.name }}</td>
                                        <td>{{ fmt(r.mean_ndvi) }}</td>
                                        <td v-if="hasPrev" v-bind:class="r.delta === null ? '' : (r.delta >= 0 ? 'up' : 'down')">{{ r.delta === null ? '--' : signed(r.delta, 3) }}</td>
                                        <td>{{ r.bare_pct.toFixed(1) }}</td>
                                        <td>{{ r.green_pct.toFixed(1) }}</td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>

                <!-- 裸露地交叉分析 -->
                <div class="card-modern">
                    <div class="card-modern-header">
                        <h6 class="card-modern-title"><i class="fas fa-triangle-exclamation text-danger"></i> 裸露地列管點 × NDVI 交叉</h6>
                        <button type="button" class="btn btn-sm btn-primary" v-bind:disabled="ptsBusy || !periodForPts" v-on:click="analyzePoints">{{ ptsBusy ? '分析中…' : '執行分析' }}</button>
                    </div>
                    <div class="card-modern-body">
                        <div class="text-muted" style="font-size:.8rem" v-if="!ptsRows.length && !ptsMsg">以列管裸露地點位取樣 NDVI 類別；仍為「裸露/稀疏」或「不透水」且植被較上期下降者列為優先查核。</div>
                        <div class="text-muted" style="font-size:.8rem" v-if="ptsMsg">{{ ptsMsg }}</div>
                        <div v-if="ptsRows.length">
                            <div class="mb-1" style="font-size:.8rem">
                                共 {{ ptsRows.length }} 處　<span class="tag tag-h">高 {{ ptsCount.h }}</span> <span class="tag tag-m">中 {{ ptsCount.m }}</span> <span class="tag tag-l">低 {{ ptsCount.l }}</span>
                            </div>
                            <div class="scroll-box">
                                <table class="mini">
                                    <thead><tr><th>優先</th><th>編號 / 地址</th><th>NDVI 類別</th><th>變化</th></tr></thead>
                                    <tbody>
                                        <tr v-for="p in ptsRows" v-bind:key="p.Id" class="rowlink" v-on:click="flyToPoint(p)">
                                            <td><span class="tag" v-bind:class="p.riskCls">{{ p.risk }}</span></td>
                                            <td>{{ p.No }}<br /><span class="text-muted">{{ p.Addr }}</span></td>
                                            <td><span class="chip d-inline-block align-middle mr-1" v-bind:style="{background:p.color}"></span>{{ p.clsName }}</td>
                                            <td v-bind:class="p.trendCls">{{ p.trend }}</td>
                                        </tr>
                                    </tbody>
                                </table>
                            </div>
                            <div class="custom-control custom-switch mt-2">
                                <input type="checkbox" class="custom-control-input" id="swPts" v-model="showPts" />
                                <label class="custom-control-label" for="swPts">在地圖上顯示點位</label>
                            </div>
                        </div>
                    </div>
                </div>
            </aside>

            <main class="mapwrap" v-bind:class="{collapsed: mapCollapsed}">
                <div id="map"></div>
                <div class="busy" v-if="busy">{{ busy }}</div>
                <template v-if="cmpMode">
                    <div class="swipe-tag" style="left:10px">{{ labelOf(periodA) }}</div>
                    <div class="swipe-tag" style="right:10px">{{ labelOf(periodB) }}</div>
                    <div id="swipeBar" ref="swipeBar" v-bind:style="{left: (ratio*100) + '%'}" v-on:pointerdown="swipeDown">
                        <div class="grip"><i class="fas fa-arrows-left-right"></i></div>
                    </div>
                </template>
            </main>
        </div>
    </div>

    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>
    <script src="../Scripts/leaflet/leaflet.js"></script>
    <script>
        (function () {
            var TILE_BASE = '<%= ResolveUrl("~/NDVI/Tiles/") %>';
            var TOWN_URL = '<%= ResolveUrl("~/NDVI/Data/ntpc_towns.json") %>';
            var POINT_URL = '<%= ResolveUrl("~/NDVI/NdviMap.aspx") %>';
            var BLANK = 'data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==';

            var map, baseLayers = {}, curBaseKey = null;
            var ndviLayer = null, ndviLayerB = null;
            var townLayer = null, townById = {};
            var ptsLayer = null, queryMarker = null;
            var tilePromiseCache = {};

            function hexToRgb(h) {
                h = h.replace('#', '');
                return [parseInt(h.substr(0, 2), 16), parseInt(h.substr(2, 2), 16), parseInt(h.substr(4, 2), 16)];
            }

            Vue.createApp({
                data: function () {
                    return {
                        errMsg: '', busy: '',
                        idx: null, periods: [], classes: [],
                        periodId: '', periodA: '', periodB: '', cmpMode: false, ratio: 0.5,
                        opacity: 75, showNdvi: true, showTowns: true, base: 'emap', mapCollapsed: false,
                        statsCache: {}, stat: null, prevStat: null,
                        selTown: '', sortKey: 'mean_ndvi', sortDir: -1,
                        pointInfo: null,
                        showPts: true, ptsBusy: false, ptsMsg: '', ptsRows: []
                    };
                },
                computed: {
                    curMeta: function () {
                        var id = this.cmpMode ? this.periodB : this.periodId;
                        for (var i = 0; i < this.periods.length; i++) { if (this.periods[i].id === id) { return this.periods[i]; } }
                        return null;
                    },
                    curLabel: function () { return this.curMeta ? this.curMeta.label : ''; },
                    periodForPts: function () { return this.periodId || (this.periods.length ? this.periods[0].id : ''); },
                    hasPrev: function () { return !!this.prevStat; },
                    rankRows: function () {
                        var self = this;
                        if (!this.stat) { return []; }
                        var prevMap = {};
                        if (this.prevStat) { this.prevStat.towns.forEach(function (t) { prevMap[t.code] = t; }); }
                        var rows = this.stat.towns.map(function (t) {
                            var tot = Math.max(t.area_km2 - t.nodata_km2, 0.0001);
                            var p = prevMap[t.code];
                            var d = (p && p.mean_ndvi !== null && t.mean_ndvi !== null) ? (t.mean_ndvi - p.mean_ndvi) : null;
                            return {
                                code: t.code, name: t.name, mean_ndvi: t.mean_ndvi, delta: d,
                                bare_pct: 100 * (t.class_km2['2'] + t.class_km2['3']) / tot,
                                green_pct: 100 * (t.class_km2['5'] + t.class_km2['6']) / tot
                            };
                        });
                        var k = this.sortKey, dir = this.sortDir;
                        rows.sort(function (a, b) {
                            var x = a[k], y = b[k];
                            if (x === null) { return 1; } if (y === null) { return -1; }
                            if (typeof x === 'string') { return dir * x.localeCompare(y, 'zh-Hant'); }
                            return dir * (x - y);
                        });
                        return rows;
                    },
                    selStat: function () {
                        if (!this.selTown || !this.stat) { return null; }
                        for (var i = 0; i < this.stat.towns.length; i++) { if (this.stat.towns[i].code === this.selTown) { return this.stat.towns[i]; } }
                        return null;
                    },
                    selPrev: function () {
                        if (!this.selTown || !this.prevStat) { return null; }
                        for (var i = 0; i < this.prevStat.towns.length; i++) { if (this.prevStat.towns[i].code === this.selTown) { return this.prevStat.towns[i]; } }
                        return null;
                    },
                    selDelta: function () {
                        if (!this.selStat || !this.selPrev || this.selStat.mean_ndvi === null || this.selPrev.mean_ndvi === null) { return null; }
                        return this.selStat.mean_ndvi - this.selPrev.mean_ndvi;
                    },
                    ptsCount: function () {
                        var c = { h: 0, m: 0, l: 0 };
                        this.ptsRows.forEach(function (p) { if (p.risk === '高') { c.h++; } else if (p.risk === '中') { c.m++; } else if (p.risk === '低') { c.l++; } });
                        return c;
                    }
                },
                watch: {
                    base: function () { this.applyBase(); },
                    periodId: function () { this.onPeriodChange(); },
                    cmpMode: function () { this.rebuildNdvi(); },
                    periodA: function () { if (this.cmpMode) { this.rebuildNdvi(); } },
                    periodB: function () { if (this.cmpMode) { this.rebuildNdvi(); } },
                    showNdvi: function () { this.rebuildNdvi(); },
                    opacity: function () { this.applyOpacity(); },
                    showTowns: function () { this.applyTownVisibility(); },
                    showPts: function () { this.applyPtsVisibility(); }
                },
                mounted: function () {
                    // 注意: Vue 在 mounted 之後才移除 v-cloak，此時容器仍為 display:none (尺寸 0)，
                    // Leaflet 必須延後到容器可見後再初始化，否則 fitBounds 會算出錯誤縮放層級
                    var self = this;
                    setTimeout(function () {
                        self.initMap();
                        self.loadTowns();
                        self.loadIndex();
                    }, 0);
                },
                methods: {
                    /* ---------- 工具 ---------- */
                    fmt: function (v) { return (v === null || v === undefined) ? '--' : v.toFixed(3); },
                    signed: function (v, d) { d = (d === undefined) ? 2 : d; return (v >= 0 ? '+' : '') + v.toFixed(d); },
                    pct: function (s, cid) { var tot = Math.max(s.area_km2, 0.0001); return 100 * s.class_km2[cid] / tot; },
                    shortName: function (n) { return n.split(' ')[0]; },
                    labelOf: function (id) { for (var i = 0; i < this.periods.length; i++) { if (this.periods[i].id === id) { return this.periods[i].label; } } return id; },
                    diffClass: function (d, cid) {
                        if (Math.abs(d) < 0.005) { return ''; }
                        // 植被類(4,5,6)增加為好; 裸露/不透水(2,3)增加為壞; 水體中性
                        var good = (cid >= 4) ? d > 0 : (cid >= 2 ? d < 0 : null);
                        if (good === null) { return ''; }
                        return good ? 'up' : 'down';
                    },
                    toggleMap: function () { this.mapCollapsed = !this.mapCollapsed; var self = this; setTimeout(function () { map.invalidateSize(); }, 250); },
                    className: function (id) { for (var i = 0; i < this.classes.length; i++) { if (this.classes[i].id === id) { return this.classes[i]; } } return null; },

                    /* ---------- 地圖 ---------- */
                    initMap: function () {
                        map = L.map('map', { center: [25.01, 121.55], zoom: 10, minZoom: 8, maxZoom: 19, zoomControl: true });
                        map.createPane('ndvi'); map.getPane('ndvi').style.zIndex = 250;
                        baseLayers.emap = L.tileLayer('https://wmts.nlsc.gov.tw/wmts/EMAP/default/GoogleMapsCompatible/{z}/{y}/{x}', { maxZoom: 19, attribution: '&copy; 內政部國土測繪中心' });
                        baseLayers.photo = L.tileLayer('https://wmts.nlsc.gov.tw/wmts/PHOTO2/default/GoogleMapsCompatible/{z}/{y}/{x}', { maxZoom: 19, attribution: '&copy; 內政部國土測繪中心' });
                        baseLayers.osm = L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', { maxZoom: 19, attribution: '&copy; OpenStreetMap' });
                        this.applyBase();
                        L.control.scale({ imperial: false }).addTo(map);
                        var self = this;
                        map.on('click', function (e) { self.onMapClick(e.latlng); });
                        map.on('move zoom', function () { self.updateClip(); });
                        map.on('resize', function () { self.updateClip(); });
                    },
                    applyBase: function () {
                        if (curBaseKey) { map.removeLayer(baseLayers[curBaseKey]); }
                        curBaseKey = this.base;
                        baseLayers[curBaseKey].addTo(map);
                        baseLayers[curBaseKey].bringToBack();
                    },
                    loadTowns: function () {
                        var self = this;
                        axios.get(TOWN_URL + '?_=' + Date.now()).then(function (r) {
                            townLayer = L.geoJSON(r.data, {
                                style: function () { return { color: '#0284c7', weight: 1.2, fill: true, fillOpacity: 0, opacity: 0.9 }; },
                                onEachFeature: function (f, layer) {
                                    townById[f.properties.code] = layer;
                                    layer.bindTooltip(f.properties.name, { sticky: true });
                                    layer.on('mouseover', function () { if (f.properties.code !== self.selTown) { layer.setStyle({ fillOpacity: 0.12 }); } });
                                    layer.on('mouseout', function () { if (f.properties.code !== self.selTown) { layer.setStyle({ fillOpacity: 0 }); } });
                                    layer.on('click', function () { self.selectTown(f.properties.code, false); });
                                }
                            });
                            if (self.showTowns) { townLayer.addTo(map); }
                            map.fitBounds(townLayer.getBounds(), { padding: [10, 10] });
                        }).catch(function () { self.errMsg = '行政區界載入失敗'; });
                    },
                    applyTownVisibility: function () {
                        if (!townLayer) { return; }
                        if (this.showTowns) { townLayer.addTo(map); } else { map.removeLayer(townLayer); }
                    },
                    selectTown: function (code, fly) {
                        var prev = this.selTown;
                        if (prev && townById[prev]) { townById[prev].setStyle({ weight: 1.2, color: '#0284c7', fillOpacity: 0 }); }
                        this.selTown = code;
                        var l = townById[code];
                        if (l) {
                            l.setStyle({ weight: 3, color: '#0b1f7d', fillOpacity: 0.05 });
                            if (fly) { map.fitBounds(l.getBounds(), { padding: [20, 20] }); }
                        }
                    },
                    clearTown: function () {
                        var prev = this.selTown;
                        if (prev && townById[prev]) { townById[prev].setStyle({ weight: 1.2, color: '#0284c7', fillOpacity: 0 }); }
                        this.selTown = '';
                    },

                    /* ---------- 資料 ---------- */
                    loadIndex: function () {
                        var self = this;
                        this.busy = '載入 NDVI 索引…';
                        axios.get(TILE_BASE + 'index.json?_=' + Date.now()).then(function (r) {
                            self.idx = r.data;
                            self.periods = r.data.periods || [];
                            self.classes = r.data.classes || [];
                            if (!self.periods.length) { self.errMsg = '尚無 NDVI 資料，請等候排程產生。'; self.busy = ''; return; }
                            self.periodId = self.periods[0].id;
                            self.periodA = self.periods.length > 1 ? self.periods[1].id : self.periods[0].id;
                            self.periodB = self.periods[0].id;
                            self.busy = '';
                        }).catch(function () {
                            self.busy = '';
                            self.errMsg = '尚無 NDVI 圖磚資料（排程尚未執行或 index.json 不存在）。底圖與行政區界仍可使用。';
                        });
                    },
                    loadStats: function (pid) {
                        var self = this;
                        if (this.statsCache[pid]) { return Promise.resolve(this.statsCache[pid]); }
                        var meta = null;
                        this.periods.forEach(function (p) { if (p.id === pid) { meta = p; } });
                        if (!meta) { return Promise.resolve(null); }
                        return axios.get(TILE_BASE + meta.stats + '?_=' + Date.now()).then(function (r) {
                            self.statsCache[pid] = r.data;
                            return r.data;
                        }).catch(function () { return null; });
                    },
                    prevIdOf: function (pid) {
                        for (var i = 0; i < this.periods.length; i++) { if (this.periods[i].id === pid) { return (i + 1 < this.periods.length) ? this.periods[i + 1].id : ''; } }
                        return '';
                    },
                    onPeriodChange: function () {
                        var self = this, pid = this.periodId;
                        if (!pid) { return; }
                        this.rebuildNdvi();
                        var prevId = this.prevIdOf(pid);
                        Promise.all([this.loadStats(pid), prevId ? this.loadStats(prevId) : Promise.resolve(null)]).then(function (res) {
                            if (self.periodId !== pid) { return; }
                            self.stat = res[0]; self.prevStat = res[1];
                        });
                    },

                    /* ---------- NDVI 圖層 / 卷簾 ---------- */
                    makeLayer: function (pid) {
                        return L.tileLayer(TILE_BASE + pid + '/{z}/{x}/{y}.png', {
                            pane: 'ndvi', className: 'ndvi-tile', opacity: this.opacity / 100, minZoom: 8, maxZoom: 19,
                            maxNativeZoom: this.idx ? this.idx.zmax : 14, errorTileUrl: BLANK,
                            attribution: 'Sentinel-2 (ESA/Copernicus) via Microsoft Planetary Computer'
                        });
                    },
                    rebuildNdvi: function () {
                        if (ndviLayer) { map.removeLayer(ndviLayer); ndviLayer = null; }
                        if (ndviLayerB) { map.removeLayer(ndviLayerB); ndviLayerB = null; }
                        if (!this.idx || !this.showNdvi) { return; }
                        if (!this.cmpMode) {
                            if (!this.periodId) { return; }
                            ndviLayer = this.makeLayer(this.periodId).addTo(map);
                        } else {
                            ndviLayer = this.makeLayer(this.periodA).addTo(map);
                            ndviLayerB = this.makeLayer(this.periodB).addTo(map);
                            this.updateClip();
                        }
                    },
                    applyOpacity: function () {
                        if (ndviLayer) { ndviLayer.setOpacity(this.opacity / 100); }
                        if (ndviLayerB) { ndviLayerB.setOpacity(this.opacity / 100); }
                    },
                    updateClip: function () {
                        if (!this.cmpMode || !ndviLayer || !ndviLayerB) { return; }
                        var nw = map.containerPointToLayerPoint([0, 0]);
                        var se = map.containerPointToLayerPoint(map.getSize());
                        var clipX = nw.x + (se.x - nw.x) * this.ratio;
                        var a = ndviLayer.getContainer(), b = ndviLayerB.getContainer();
                        if (a) { a.style.clip = 'rect(' + [nw.y, clipX, se.y, nw.x].join('px,') + 'px)'; }
                        if (b) { b.style.clip = 'rect(' + [nw.y, se.x, se.y, clipX].join('px,') + 'px)'; }
                    },
                    swipeDown: function (ev) {
                        var self = this;
                        var wrap = map.getContainer();
                        ev.preventDefault();
                        var move = function (e) {
                            var rect = wrap.getBoundingClientRect();
                            var r = (e.clientX - rect.left) / rect.width;
                            self.ratio = Math.min(0.98, Math.max(0.02, r));
                            self.updateClip();
                        };
                        var up = function () {
                            window.removeEventListener('pointermove', move);
                            window.removeEventListener('pointerup', up);
                        };
                        window.addEventListener('pointermove', move);
                        window.addEventListener('pointerup', up);
                    },

                    /* ---------- 點查詢 (讀圖磚像素反查類別) ---------- */
                    loadTilePixels: function (pid, z, x, y) {
                        var key = pid + '/' + z + '/' + x + '/' + y;
                        if (tilePromiseCache[key]) { return tilePromiseCache[key]; }
                        var p = new Promise(function (resolve) {
                            var img = new Image();
                            img.onload = function () {
                                var c = document.createElement('canvas');
                                c.width = 256; c.height = 256;
                                var ctx = c.getContext('2d');
                                ctx.drawImage(img, 0, 0);
                                resolve(ctx.getImageData(0, 0, 256, 256).data);
                            };
                            img.onerror = function () { resolve(null); };
                            img.src = TILE_BASE + pid + '/' + z + '/' + x + '/' + y + '.png';
                        });
                        tilePromiseCache[key] = p;
                        return p;
                    },
                    sampleClass: function (pid, latlng) {
                        var self = this;
                        var z = this.idx.zmax;
                        var pt = map.project(latlng, z);
                        var tx = Math.floor(pt.x / 256), ty = Math.floor(pt.y / 256);
                        var px = Math.min(255, Math.floor(pt.x - tx * 256)), py = Math.min(255, Math.floor(pt.y - ty * 256));
                        return this.loadTilePixels(pid, z, tx, ty).then(function (data) {
                            if (!data) { return 0; }
                            var o = (py * 256 + px) * 4;
                            if (data[o + 3] === 0) { return 0; }
                            var best = 0, bd = 1e9;
                            for (var i = 0; i < self.classes.length; i++) {
                                var c = hexToRgb(self.classes[i].color);
                                var d = Math.abs(c[0] - data[o]) + Math.abs(c[1] - data[o + 1]) + Math.abs(c[2] - data[o + 2]);
                                if (d < bd) { bd = d; best = self.classes[i].id; }
                            }
                            return bd <= 30 ? best : 0;
                        });
                    },
                    onMapClick: function (latlng) {
                        var self = this;
                        if (!this.idx || !this.periods.length) { return; }
                        var ids = this.cmpMode ? [this.periodA, this.periodB] : [this.periodId];
                        Promise.all(ids.map(function (pid) { return self.sampleClass(pid, latlng); })).then(function (cls) {
                            var rows = ids.map(function (pid, i) {
                                var c = self.className(cls[i]);
                                return { label: self.labelOf(pid), name: c ? c.name : '無資料（區外/雲遮蔽）', color: c ? c.color : '#ffffff' };
                            });
                            var change = '', changeCls = '';
                            if (cls.length === 2 && cls[0] > 1 && cls[1] > 1) {
                                if (cls[1] > cls[0]) { change = '植被等級上升'; changeCls = 'up'; }
                                else if (cls[1] < cls[0]) { change = '植被等級下降'; changeCls = 'down'; }
                                else { change = '無變化'; }
                            }
                            self.pointInfo = { lat: latlng.lat, lng: latlng.lng, rows: rows, change: change, changeCls: changeCls };
                            if (queryMarker) { map.removeLayer(queryMarker); }
                            queryMarker = L.circleMarker(latlng, { radius: 7, color: '#fff', weight: 2, fillColor: '#dc2626', fillOpacity: 1 }).addTo(map);
                        });
                    },

                    /* ---------- 裸露地點位 × NDVI ---------- */
                    sortBy: function (k) {
                        if (this.sortKey === k) { this.sortDir = -this.sortDir; } else { this.sortKey = k; this.sortDir = (k === 'name') ? 1 : -1; }
                    },
                    analyzePoints: function () {
                        var self = this;
                        var pid = this.periodForPts;
                        var prevId = this.prevIdOf(pid);
                        this.ptsBusy = true; this.ptsMsg = ''; this.ptsRows = [];
                        axios.get(POINT_URL, { params: { action: 'getpoints', _: Date.now() } }).then(function (r) {
                            if (!r.data || !r.data.Success) { throw new Error((r.data && r.data.Message) || '點位載入失敗'); }
                            var pts = r.data.Markers || [];
                            if (!pts.length) { self.ptsMsg = '沒有可用的裸露地座標資料。'; self.ptsBusy = false; return; }
                            return Promise.all(pts.map(function (p) {
                                var ll = L.latLng(p.Lat, p.Lng);
                                return Promise.all([self.sampleClass(pid, ll), prevId ? self.sampleClass(prevId, ll) : Promise.resolve(-1)]).then(function (cc) {
                                    return { p: p, cls: cc[0], prev: cc[1] };
                                });
                            })).then(function (res) {
                                var score = { 3: 100, 2: 90, 4: 60, 5: 30, 6: 10, 1: 0, 0: -1 };
                                var rows = res.map(function (o) {
                                    var c = self.className(o.cls);
                                    var s = score[o.cls];
                                    var drop = (o.prev > 1 && o.cls > 1 && o.cls < o.prev);
                                    var rise = (o.prev > 1 && o.cls > 1 && o.cls > o.prev);
                                    if (drop) { s += 20; }
                                    var risk = s >= 90 ? '高' : (s >= 50 ? '中' : (s >= 0 ? '低' : '--'));
                                    return {
                                        Id: o.p.Id, No: o.p.No, Addr: o.p.Addr, Lat: o.p.Lat, Lng: o.p.Lng, LastDate: o.p.LastDate,
                                        cls: o.cls, clsName: c ? self.shortName(c.name) : '無資料', color: c ? c.color : '#ffffff',
                                        score: s, risk: risk,
                                        riskCls: risk === '高' ? 'tag-h' : (risk === '中' ? 'tag-m' : (risk === '低' ? 'tag-l' : 'tag-n')),
                                        trend: drop ? '植被↓' : (rise ? '植被↑' : (o.prev === -1 ? '' : '持平')),
                                        trendCls: drop ? 'down' : (rise ? 'up' : '')
                                    };
                                });
                                rows.sort(function (a, b) { return b.score - a.score; });
                                self.ptsRows = rows;
                                self.drawPoints();
                                self.ptsBusy = false;
                            });
                        }).catch(function (e) {
                            self.ptsMsg = '分析失敗：' + (e && e.message ? e.message : e);
                            self.ptsBusy = false;
                        });
                    },
                    drawPoints: function () {
                        if (ptsLayer) { map.removeLayer(ptsLayer); }
                        ptsLayer = L.layerGroup();
                        this.ptsRows.forEach(function (p) {
                            var m = L.circleMarker([p.Lat, p.Lng], { radius: 7, color: '#111827', weight: 1.5, fillColor: p.color === '#ffffff' ? '#cbd5e1' : p.color, fillOpacity: 0.95 });
                            m.bindPopup('<b>' + p.No + '</b><br>' + p.Addr + '<br>NDVI 類別：' + p.clsName + '<br>優先度：' + p.risk + '<br>最近查核：' + p.LastDate);
                            ptsLayer.addLayer(m);
                        });
                        if (this.showPts) { ptsLayer.addTo(map); }
                    },
                    applyPtsVisibility: function () {
                        if (!ptsLayer) { return; }
                        if (this.showPts) { ptsLayer.addTo(map); } else { map.removeLayer(ptsLayer); }
                    },
                    flyToPoint: function (p) {
                        if (this.mapCollapsed) { this.mapCollapsed = false; }
                        map.setView([p.Lat, p.Lng], 17);
                        if (this.showPts && ptsLayer) {
                            ptsLayer.eachLayer(function (l) {
                                var ll = l.getLatLng();
                                if (Math.abs(ll.lat - p.Lat) < 1e-7 && Math.abs(ll.lng - p.Lng) < 1e-7) { l.openPopup(); }
                            });
                        }
                    }
                }
            }).mount('#ndviApp');
        })();
    </script>
</body>
</html>
