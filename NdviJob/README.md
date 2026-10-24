# NdviJob — 新北市 NDVI 月報自動更新 (Sentinel-2)

每月自動抓取 Sentinel-2 L2A（Microsoft Planetary Computer STAC，免費開放，不需金鑰）→ 去雲/雲影 → 逐像素中位數合成 NDVI → 水體 + NDVI 離散分級 → 以新北市 29 區界裁切 → 產生 XYZ 圖磚、各區統計 `stats.json`、`index.json`，並**只保留最近 6 期**。前端頁面為 `NDVI/NdviMap.aspx`。

> 失敗時**不會動到舊資料**：圖磚先寫到 `.build_<期別>`，成功才原子替換；覆蓋率 < 5% 或查無影像會直接中止並保留舊圖磚。

## 檔案配置（正式機）

| 位置 | 內容 |
|---|---|
| `D:\NdviJob\ndvi_build.py` | 主程式 |
| `D:\NdviJob\towns-10t.json` | 行政區界來源（taiwan-atlas，內政部 `TOWN_MOI`） |
| `D:\NdviJob\Run-NdviBuild.ps1` | 排程包裝：單一實例鎖、失敗重試 3 次(間隔 30 分)、事件檢視器、清理舊記錄 |
| `D:\NdviJob\Register-NdviTask.ps1` | 註冊 / 移除排程 |
| `D:\NdviJob\venv\` | Python 3.12 虛擬環境（已建立） |
| `D:\NdviJob\work\` | 工作目錄：`<期別>\ndvi_class.tif`、`ndvi_q.tif`（供變化偵測）、`logs\` |
| `D:\Web\NTPC_FECM\NDVI\Tiles\` | **輸出（網站讀取）**：`index.json`、`<期別>\{z}\{x}\{y}.png`、`<期別>\stats.json`、`web.config` |

`NDVI/Tiles/` 與 `NdviJob/` 已列入 `deploy_manifest.json` 的 `exclude_dirs`，**發布 zip 不會覆蓋或刪除排程產生的圖磚**。`deploy_pack.py` 已調整為巢狀目錄也套用排除。

## 一次性安裝

1. 把 `NdviJob\` 內的 `ndvi_build.py`、`towns-10t.json`、`Run-NdviBuild.ps1`、`Register-NdviTask.ps1` 複製到正式機 `D:\NdviJob\`。
2. 發布含 `NDVI\NdviMap.aspx`、`NDVI\Data\ntpc_towns.json` 的新版（`deploy_pack.py`）。
3. （已完成）Python 3.12 與 venv：
   ```powershell
   D:\Python312\python.exe -m venv D:\NdviJob\venv
   D:\NdviJob\venv\Scripts\pip.exe install numpy rasterio pystac-client planetary-computer mercantile pillow shapely pyproj
   ```
4. **先手動跑一次**（約 15~20 分鐘，上個月）：
   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File D:\NdviJob\Run-NdviBuild.ps1
   ```
   完成後開 `NDVI/NdviMap.aspx` 驗證。想補歷史期別：`-Month 2026-08`、`-Month 2026-07`…（由舊到新各跑一次）。
5. 註冊排程（系統管理員）：
   ```powershell
   powershell -ExecutionPolicy Bypass -File D:\NdviJob\Register-NdviTask.ps1
   schtasks /Run /TN NTPC_FEC_NDVI_Monthly      # 立即用排程帳號(SYSTEM)試跑
   ```
   預設每月 **2 日 03:00**（月底影像進 STAC 約有 1~2 天延遲）；排程以 `SYSTEM` 執行，若有網路 Proxy 需確認 SYSTEM 也能連外（用 `schtasks /Run` 試跑即可驗證）。

## 實測數據（開發機，2026-09，全市 10 m）

- 8 景 Sentinel-2，耗時 **16.8 分鐘**，771 張圖磚（z10–z14），**整期僅 3.4 MB**（6 期約 20 MB）。
- 有效覆蓋率 98.6%。

## 分級

| 類別 | 條件 | 色 |
|---|---|---|
| 水體 | SCL=水 的有效觀測過半 | `#2B8CBE` |
| 建物/不透水 | NDVI < 0.1 | `#9CA3AF` |
| 裸露/稀疏 | 0.1–0.2 | `#F97316` |
| 低植被 | 0.2–0.4 | `#FACC15` |
| 中植被 | 0.4–0.6 | `#84CC16` |
| 高植被 | > 0.6 | `#15803D` |

## 品質機制

- **雲/雲影**：用 SCL 波段排除 0,1,3,8,9,10,11；多景逐像素取中位數。
- **覆蓋率不足自動補救**：當月有效覆蓋 < 85%（雲多/颱風月）→ 自動往前多取 15 天影像重算，採覆蓋率較高者（`--min-coverage`、`--auto-pad-days` 可調）。
- **反射率偏移**：L2A 處理基線 ≥ 04.00 的 DN 有 +1000 offset，已先扣除再算 NDVI。
- 影像取得失敗自動重試；整體失敗由 `Run-NdviBuild.ps1` 再重試 3 次。

## 維運

| 項目 | 方式 |
|---|---|
| 執行記錄 | `D:\NdviJob\work\logs\run_*.log`、`ndvi_<期別>.log` |
| 失敗通知 | 事件檢視器 → Windows 記錄 → 應用程式，來源 `NdviJob`（1000=成功、1001=失敗）；`work\logs\LAST_FAILED.txt` |
| 重跑某月 | `Run-NdviBuild.ps1 -Month 2026-08`（同期別會原子覆蓋） |
| 調整保留期數 | `ndvi_build.py --keep N`（預設 6） |
| 快速測試（小範圍） | `ndvi_build.py --month 2026-09 --towns 板橋區,永和區 --out <測試目錄> --work <測試目錄>` |
| 移除排程 | `Register-NdviTask.ps1 -Remove` |

## 已知限制

- 行政區界為簡化版（`towns-10t`），區面積與官方數字有數 % 的差距（河岸、海岸線最明顯），統計僅供趨勢參考。
- 10 m 解析度無法辨識小於 ~20 m 的目標（單一建物、窄巷）。
- 底圖由使用者瀏覽器連 `wmts.nlsc.gov.tw`；若機關網路阻擋，需改底圖來源。
- 資料來源：Contains modified Copernicus Sentinel data (ESA)，經 Microsoft Planetary Computer 取得。
