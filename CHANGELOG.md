# 更新日誌 (CHANGELOG)

本專案遵循 [Semantic Versioning](https://semver.org/lang/zh-TW/) 與 [Keep a Changelog](https://keepachangelog.com/zh-TW/1.0.0/) 規範記錄每次版本重要歷程。

---

## [1.7.0] - 2026-10-30

### 🚀 版本概述
新北市固定逸散源管理平台（NTPC_FECM）發布 1.7.0 版本。本版本隆重推出「環境部施工機具管理與匯入」新模組（`MoenvEquip/`）、全面深化「環域空間分析」之學校敏感受體資料庫與空間交叉警示報表（`BufferAnalysis/`）、完整打通「道路破損派工與改善申報」（`RoadBreak/SetSG_Break.aspx`, `RoadBreak/ImproveBreak.aspx`）閉環流程、重構並上線「巡查專屬照片定位輔助」（`InvPhotoHelper.cs`）以徹底根絕照片錯置歷史痛點，並正式升級 NPOI.OOXML Office 報表核心函式庫，全面強化各業務模組自適應與資安防護。

### ✨ 主要歷程與改動

#### 1. 環境部施工機具管理與批次匯入模組 (`MoenvEquip/`)
- **施工機具多維度資料分析儀表板 (`MoenvEquipment_List.aspx`, `MoenvEquipment_List.aspx.cs`)**：
  - 專屬整合環境部納管施工機具清單，支援型態、號牌/引擎編號、出廠年份、符合出廠標準與審查狀態等全方位維度查詢。
  - 內建統計儀表板卡片，快速呈現各工區機具數量、符合法規標準比率與檢驗合格率。
  - 支援客製化欄位篩選與即時高階報表匯出。
- **施工機具批次匯入與比對分析 (`MoenvEquipment_Upload.aspx`, `MoenvEquipment_Upload.aspx.cs`)**：
  - 支援 Excel 格式批次上傳與解析，具備表頭比對、欄位型別校驗與資料重複性偵測。
  - 上傳前後提供預覽檢核清單與錯誤標記，確保機具資料入庫之正確性與完整性。

#### 2. 環域空間分析模組升級與學校敏感點資料庫深度整合 (`BufferAnalysis/`)
- **新北市全轄區學校敏感受體資料庫 (`BufferAnalysis/Data/ntpc_schools.json`)**：
  - 全面彙整新北市幼兒園、國小、國中、高中職與大專院校精準大地地理座標與學制資訊。
  - 圖台支援獨立學校敏感點圖層開關、自訂圖標與學校基本資料氣泡視窗。
- **學校敏感受體多重距離安全警示**：
  - 實作重點工廠與營建工地鄰近學校之動態安全警示距離過濾門檻（<100m, <300m, <500m），提供環保外勤第一時間評估對周圍學童受體之空氣品質衝擊。
- **學校距離空間分析清冊 Excel 一鍵匯出**：
  - 串接 `BufferHandler.ashx` 後端分析引擎與 NPOI.OOXML，直接產出精準各級學校距離統計與受影響風險報表。

#### 3. 道路髒污破損巡查管理流程閉環補完 (`RoadBreak/`, `RoadClean/`)
- **路面破損缺失改善申報 (`RoadBreak/ImproveBreak.aspx`, `RoadBreak/ImproveBreak.aspx.cs`)**：
  - 完善外勤巡查發現路面破損後之改善通報、改善前後相片對比上傳、施工廠商回報與核銷結案機制。
- **路面破損派工與責任單位移送 (`RoadBreak/SetSG_Break.aspx`, `RoadBreak/SetSG_Break.aspx.cs`)**：
  - 提供路面破損案件即時分派、工務局/各區公所權責單位通知與進度列管追蹤。
- **全載具自適應外勤標準落實 (`RoadClean/NewCleanChk.aspx`, `RoadClean/NewDirty.aspx` 等)**：
  - 全面遵循 `inspection-ui-standard` 規範重構道路潔淨度與洗掃查核介面，深度整合前端相片智慧壓縮與離線防呆。

#### 4. 專屬稽查照片定位與防串場機制 (`App_Code/Helpers/InvPhotoHelper.cs`)
- **精準目錄匹配與歷史照片護欄**：
  - 解決 `INV_NO` 於各場所獨立累加導致照片跨場所錯置之長年問題。
  - 實施「精準目錄優先原則」（`~/Upload/PIC/{FAC_ID}/{INV_NO}/` 與 `~/Upload/PIC/{C_NO}/{INV_NO}/`），杜絕跨目錄合併照片造成的串場問題。
  - 針對舊版無層級目錄加設「巡查日 ±3 天日期護欄」，確保僅抓取相應巡查期間照片，杜絕誤抓其他年度歷史紀錄。

#### 5. 後端 Office 報表核心升級與動態函式庫引用 (`NTPC_FEC.csproj`)
- **引進 NPOI.OOXML / OpenXml 完整套裝庫**：
  - 於專案檔中正規引用 `NPOI.OOXML`、`NPOI.OpenXml4Net`、`NPOI.OpenXmlFormats`、`ICSharpCode.SharpZipLib` 與 `BouncyCastle.Crypto`。
  - 支援超大資料量 `.xlsx` 串流寫入，解決記憶體瓶頸與舊版相容性問題。

#### 6. 核心業務清單與外勤表單全面優化 (Case, BareGround, Wash, OwnReport)
- **營建工地與案件查詢優化 (`Case/CaseList.aspx`, `Case/CaseResult.aspx`, `Case/NewCase.aspx`)**：
  - 大幅優化查詢效能、篩選維度與自適應卡片清單顯示。
- **裸露地管理與分頁優化 (`BareGround/Bare_List.aspx`, `BareGround/BareResult.aspx`)**：
  - 精簡查詢負載，提升地圖圖台定位與歷史巡查切換之順暢度。
- **洗掃作業日誌與範本支援 (`Wash/ReportUpload.aspx`, `洗掃街里程日誌(空白範本).pdf`)**：
  - 上線「洗掃街里程日誌(空白範本)」標準 PDF 下載，並強化日誌批次上傳與審查流程。
- **空品自主管理與應變通報優化 (`OwnReport/Report_AirQuality.aspx`, `OwnReport/AirQuality_List.aspx`)**：
  - 優化業者自主通報資料校驗機制與稽核狀態反饋。

#### 7. 打包清單升級與全自動防呆驗證 (`deploy_manifest.json`, `Deploy-Pack.ps1`)
- **打包發布清單同步**：
  - 將新增模組 `MoenvEquip/`、`RoadBreak/SetSG_Break.aspx`、`RoadBreak/ImproveBreak.aspx`、`BufferAnalysis/Data/ntpc_schools.json`、`洗掃街里程日誌(空白範本).pdf` 以及全套 NPOI OOXML 動態連結庫納入打包白名單。
  - 打包自檢（Post-Pack Verification）100% 驗證通過，確保正式機部屬零遺漏。

---

## [1.6.0] - 2026-10-26

### 🚀 版本概述
新北市固定逸散源管理平台（NTPC_FECM）發布 1.6.0 版本。本版本隆重上線「環域空間分析與 360 環景導覽」模組（`BufferAnalysis/`）、全新導入「安全圖片代理串流處理常式」（`ViewImage.ashx`）與「外勤照片前端智慧等比壓縮器」（`fec-image-compressor.js`），並全面實作 OWASP 標準之 Excel 公式注入防禦（`ExcelExportHelper.cs`）與高精度大地測量座標轉換（`GeoCoordHelper.cs`），實現空間決策輔助與外勤效能大躍進。

### ✨ 主要歷程與改動

#### 1. 環域空間分析與 360 環景導覽模組 (`BufferAnalysis/`)
- **雙欄黃金聯動與多重緩衝區分析 (`BufferMap.aspx`, `BufferHandler.ashx`)**：
  - 以營建工地、固定污染源或道路點位為中心，動態設定 100m、300m、500m、1000m、3000m 空間緩衝區。
  - 交叉分析緩衝區內敏感族群受體（學校、醫院、幼兒園、老人長照機構）、微型感測器數據、即時風向風速箭頭與其他固定源污染排放，提供環保稽查指揮決策支援。
  - 整合 360 度環景實景導覽，支援外勤與主管人員線上身歷其境檢視現場周遭地貌。
  - 於 `MenuService.cs` 工廠資料主選單中正式掛載「環域查詢」功能。

#### 2. 安全圖片串流輸出代理 (`ViewImage.ashx`, `ViewImageHandler.cs`)
- **隔離實體路徑與防目錄穿越**：
  - 取代前端直接請求 `Upload/` 實體圖檔 URL，全面改由 `ViewImage.ashx` 統一安全代理串流輸出（`TransmitFile`）。
  - 嚴格校驗傳入路徑、禁止目錄穿越（`..`），路徑缺失時自動優雅回傳預設無照片圖示（`nophoto.jpg`）。
  - 與 `Upload/Web.config` 唯讀防 WebShell 機制形成完美互補，既杜絕惡意腳本執行，又確保合法圖片正常顯示。

#### 3. 外勤現場照片前端自動等比壓縮器 (`Scripts/fec-image-compressor.js`)
- **智慧壓縮大幅提速外勤上傳**：
  - 外勤現場使用手機拍攝之高畫質大圖（單張 8MB~15MB），於瀏覽器端利用 Canvas 智慧等比縮圖至最適尺寸（最長邊 1600px）並進行高品質 JPEG 壓縮（0.82）。
  - 單張照片體積壓縮至 200KB~400KB（壓縮率達 95%+），徹底根除山區或弱網環境下外勤上傳卡頓、逾時及觸碰 IIS 請求大小限制問題。
  - 全面應用於各外勤巡檢填報模組（`RoadClean/`、`RoadBSC/`、`RoadBreak/`、`BareGround/` 等）。

#### 4. 安全 Excel 匯出與公式注入防禦 (`App_Code/Helpers/ExcelExportHelper.cs`)
- **OWASP 深度防護公式注入 (Formula Injection 防護)**：
  - 自動掃描並消毒所有單元格字串，若以 `=`, `+`, `-`, `@`, `\t`, `\r` 開頭自動加上防禦引號，徹底杜絕 CSV / DDE 惡意公式執行漏洞。
  - 原生支援 RFC 5987 規範多編碼 `Content-Disposition` 標頭，相容 iOS/Safari、Chrome、Edge 等中文檔名不亂碼。
  - 徹底避免 ASP.NET `Response.End()` 引發之 `ThreadAbortException` 例外。

#### 5. 高精度地理座標轉換工具 (`App_Code/Helpers/GeoCoordHelper.cs`)
- **大地測量座標轉換**：
  - 內建高精度雙向轉換演算法，支援台灣二度分帶 TWD97 (TM2) 投影座標與 WGS84 經緯度座標雙向無縫互轉，提供圖台定位與空間分析精確座標運算。

#### 6. 結構化審計資料庫架構與輔助基礎設施 (`DB/`, `App_Code/Helpers/`)
- **結構化審計資料表 (`DB/Sys_AuditLog.sql`)**：
  - 提供資料庫審計追蹤資料表建立腳本，健全系統法規稽核記錄。
- **基礎設施擴充**：
  - 建立 `AjaxResponseHelper.cs`、`JsonHelper.cs`、`PathHelper.cs`、`SecurityTokenHelper.cs` 等通用核心工具類別。

#### 7. 正式機打包清單升級 (`deploy_manifest.json`)
- 將 `ViewImage.ashx`、`Scripts/fec-image-compressor.js`、`BufferAnalysis/BufferMap.aspx`、`BufferAnalysis/BufferHandler.ashx` 列入發布必備檔案清單。

---

## [1.5.0] - 2026-10-25

### 🚀 版本概述
新北市固定逸散源管理平台（NTPC_FECM）發布 1.5.0 版本。本版本實現了核心安全架構的模組化解耦與深度縱深防禦，全面以獨立 `AuthModule` 接管認證與授權以杜絕 IIS 子站台衝突；實作雙重 Anti-CSRF 防護、Magic Bytes 檔案上傳簽章檢核、目錄穿越防禦、特權管理操作審計日誌（Audit Trail），並推出標準化安全錯誤頁面（`Error.aspx`）與全外勤表單斷線守護機制。

---

## [1.4.0] - 2026-10-24

### 🚀 版本概述
新北市固定逸散源管理平台（NTPC_FECM）發布 1.4.0 版本。本版本著重於「全域資安防護」、「政府資安規範相容性（30分鐘閒置自動登出）」、「外勤離線草稿守護（FEC Offline Sentinel）」及「原生 PowerShell 自動化安全發布工具」的全面實作與強化，打造高資安、高可靠性與抗斷網之外勤巡查作業環境。

---

## [1.3.0] - 2026-10-24

### 🚀 版本概述
新北市固定逸散源管理平台（NTPC_FECM）發布 1.3.0 版本。本版本隆重推出新北市固定源 LINE 官方帳號與智慧推播通報模組（`LINE/Line.aspx`）、上線出入口洗車台設備完整清單管制模組（`Wash/WashList.aspx`）、實作高安全性管理員臨時密碼重設與通知信寄送服務，並針對空品惡化通報與全站各業務清單執行深度自適應 RWD 與行動端卡片化優化。

---

## [1.2.0] - 2026-10-24

### 🚀 版本概述
新北市固定逸散源管理平台（NTPC_FECM）發布 1.2.0 版本。本版本實現了多維度環境保護業務模組的全面整合與標準化，涵蓋施工機具管理、裸露地管制作業、營建工程案件審查、固定污染源稽查、洗車設備監控、業者自主申報及 Sentinel-2 衛星 NDVI 植生綠覆率圖台；同時全新上線即時待辦事項統計服務（`PendingTaskService`）與外部系統單一簽入（SSO）跳轉橋接架構。

---

## [1.1.0] - 2026-10-22

### 🚀 版本概述
新北市固定逸散源管理平台（NTPC_FECM）發布 1.1.0 版本。本版本完成了三大核心外勤巡檢業務模組（道路洗掃巡檢、道路破壞通報、車行路段查核）的現代化全載具自適應重構，全面導入本地化 Leaflet 1.9.4 地圖圖台、升級後端權限服務體系，並建立包含語法合規與防 IIS 型別衝突的正式機打包自動化機制。

---

## [1.0.0] - 2026-10-21

### 🚀 版本概述
新北市固定逸散源管理平台（NTPC_FECM）正式發布 1.0.0 版本。本版本完成了自既有舊版 ASP.NET 系統的現代化重構，導入分層架構、RWD 響應式介面設計、資安強化與自動化打包流程，大幅提升系統效能、資安合規性與維運便利性。
