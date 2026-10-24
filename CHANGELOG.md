# 更新日誌 (CHANGELOG)

本專案遵循 [Semantic Versioning](https://semver.org/lang/zh-TW/) 與 [Keep a Changelog](https://keepachangelog.com/zh-TW/1.0.0/) 規範記錄每次版本重要歷程。

---

## [1.2.0] - 2026-10-24

### 🚀 版本概述
新北市固定溢散源管理平台（NTPC_FECM）發布 1.2.0 版本。本版本實現了多維度環境保護業務模組的全面整合與標準化，涵蓋施工機具管理、裸露地管制作業、營建工程案件審查、固定污染源稽查、洗車設備監控、業者自主申報及 Sentinel-2 衛星 NDVI 植生綠覆率圖台；同時全新上線即時待辦事項統計服務（`PendingTaskService`）與外部系統單一簽入（SSO）跳轉橋接架構。

### ✨ 主要歷程與改動

#### 1. 全業務功能模組全面整合與上線
- **施工機具巡查模組 (`Machine/`)**：
  - `NewMac.aspx` / `macList.aspx`：施工機具設備現場巡查填報、清單管制作業與檢驗履歷追蹤，優化行動端頂部導航列防止文字溢出與折行。
- **裸露地管理模組 (`BareGround/`)**：
  - `NewBare.aspx` / `Bare_List.aspx` / `BareResult.aspx`：裸露地查核填報、列管清單管理與改善成果查核。
- **營建工程與案件管理模組 (`Case/`, `Manager/`)**：
  - `CaseList.aspx` / `NewCase.aspx` / `CaseResult.aspx`：營建工地防制設施查核、申報案件管理與歷程檢視。
  - `Case_Sum.aspx` / `Case_Sum_1.aspx`：查核成果統計與管辦狀況多維度交叉分析。
  - `Manager/managerList.aspx` / `managerList_Bare.aspx`：案件初審、複審、三審綜合管制作業與裸露地審核。
  - `Manager/Check_Step1.aspx` / `Check_Step1_Bare.aspx` / `Check_Step1_Mac.aspx`：多階段案件審核作業介面。
- **固定污染源稽查管理模組 (`FAC/`)**：
  - `FAC_List.aspx` / `FAC_Detail.aspx`：固定源稽巡查清單、詳細稽查紀錄與現場違規項目標註。
  - `Charts.aspx`：固定污染源稽巡查成果圖表統計分析，優化搜尋列與每頁筆數自適應排列。
  - `oFAC_List.aspx`：專案列管固定源清單管制作業。
- **洗車設備與出入口沖洗監控模組 (`Wash/`)**：
  - `ReportUpload.aspx` / `ReportUpload_List.aspx`：洗車設備自主檢查報告上傳審查與清單。
  - `DataInput.aspx`：洗車台運作數據巡查登錄。
- **業者自主申報與空品惡化通報模組 (`OwnReport/`)**：
  - `PIC_Report.aspx`：業者現場自主防制措施照片申報。
  - `Report_AirQuality.aspx` / `AirQuality_List.aspx`：空品惡化預警應變自主通報填報與案件清單。
- **新北市 NDVI 植被監測（Sentinel-2 自動月報） (`NDVI/`, `NdviJob/`)**：
  - `NDVI/NdviMap.aspx`：Leaflet + Vue 3 獨立頁面，取代舊版靜態圖片。支援期別切換、圖層透明度、圖例、行政區界互動與各區 NDVI 排行、點擊地圖查詢 NDVI 類別、兩期卷簾比對、以及「裸露地列管點 × NDVI 交叉分析」優先查核清單。
  - `NdviJob/`：每月自動擷取 Sentinel-2 影像、去雲合成並產製統計數據與圖磚，排程自動執行且不干擾正式發布包。

#### 2. 即時待辦事項與案件審查服務體系 (`PendingTaskService.cs`)
- **待辦統計服務 (`App_Code/Services/PendingTaskService.cs`)**：
  - 封裝高效率參數化 SQL 查詢，即時計算當前登入者所屬角色之待辦件數。
  - 涵蓋初審 (`INV1`)、複審 (`INV2`)、三審 (`INV3`)、7日內巡查派遣、2次以上提報稽查、退件紀錄、暫存草稿及道路破損/覆土改善回報。
- **首頁選單與儀表板動態徽章 (`MenuService.cs`, `MainPage.aspx`)**：
  - 模組卡片自動動態累計顯示待辦總件數徽章。
  - 次選單支援真實案件數量提示；當案件數為 0 時支援優雅的灰色 `0 件` 徽章呈現 (`ShowZero`)，審查進度一目瞭然。

#### 3. 外部系統單一簽入 (SSO) 跳轉橋接 (`OutLink.aspx`)
- **安全外部跳轉機制 (`OutLink.aspx`, `OutLink.aspx.cs`)**：
  - 實作防竄改之單一簽入外部跳轉，安全導向環境部空氣品質監測、中央系統及地政地理資訊圖台。
  - 納入 `deploy_manifest.json` 與發布清單，確保正式機跳轉功能正常運行。

#### 4. 全載具自適應外勤與管理端介面擴展
- **UI/UX 標準全面擴展**：
  - 依據 `inspection-ui-standard` 規範重構所有清單、明細與統計匯總頁面。
  - 優化導航列外勤操作按鈕與浮動工具列（浮動返回、儲存、提交等）。
  - 全站表格、卡片與地圖在各解析度（手機、平板、桌機）皆具備流暢滾動與自適應佈局。

#### 5. 正式機打包清單與版本維護升級
- **發布清單升級 (`deploy_manifest.json`)**：
  - 將 1.2.0 所有新模組完整納入 `required_in_zip`。
  - 將未使用的龐大圖資暫存（如 `tiles/`, `ndvijob/`）排除，確保發布壓縮包輕量高效率。
  - 補充引入本地 jQuery 資源庫版本 (`jquery-3.6.0.min.js`, `jquery-3.7.1.min.js`)。

---

## [1.1.0] - 2026-10-22

### 🚀 版本概述
新北市固定溢散源管理平台（NTPC_FECM）發布 1.1.0 版本。本版本完成了三大核心外勤巡檢業務模組（道路洗掃巡檢、道路破壞通報、車行路段查核）的現代化全載具自適應重構，全面導入本地化 Leaflet 1.9.4 地圖圖台、升級後端權限服務體系，並建立包含語法合規與防 IIS 型別衝突的正式機打包自動化機制。

### ✨ 主要歷程與改動

#### 1. 三大巡檢與查核業務模組現代化重構
- **道路洗掃巡檢模組 (`RoadClean/`)**：
  - `NewCleanChk.aspx`：道路洗掃現場自主檢核填報，具備全載具自適應表單與評分機制。
  - `NewDirty.aspx` / `ImproveDirty.aspx`：道路髒污巡查通報與改善回報流程，整合照片上傳預覽與審查回饋。
  - `Dirty_List.aspx` / `DirtyDetail.aspx`：髒污案件即時清單查詢、關鍵字過濾與案件詳細履歷。
  - `Clean_List.aspx` / `RoadClean_Sum.aspx`：洗掃作業執行清單，並整合 Highcharts 呈現視覺化統計分析圖表。
- **道路破壞巡查模組 (`RoadBreak/`)**：
  - `NewBreak.aspx` / `Break_List.aspx` / `BreakDetail.aspx`：道路破壞與管線施工通報、清單管制作業與案件歷程追蹤。
- **車行路段查核模組 (`RoadBSC/`)**：
  - `NewBSC.aspx` / `BSC_List.aspx` / `BSCDetail.aspx`：車行路段定期巡查作業填報、清單彙整與查核明細。
- **管理端帳號模組 (`Modules/Manager/`)**：
  - `AccountManagement.aspx` / `PasswordChange.aspx`：系統帳號權限管理與密碼安全修改。

#### 2. 本地化地圖圖台升級 (Leaflet 1.9.4)
- **全面擺脫外部圖資依賴**：
  - 引入本地版 Leaflet 1.9.4 核心庫與樣式圖標（`Content/leaflet/`, `Scripts/leaflet/leaflet.js`），取代舊版外部圖台，100% 避開機房資安隔離與 CSP 阻擋。
- **高精度座標轉換支援**：
  - 內建 TWD97 (二度分帶) 與 WGS84 經緯度座標雙向轉換演算法，確保道路點位定位精準。

#### 3. 權限控管與後端架構擴充
- **新增權限服務 (`App_Code/Services/PermissionService.cs`)**：
  - 實作細緻化功能模組權限驗證、操作權限查核與選單安全過濾。
- **資料存取層升級 (`App_Code/Helpers/DbHelper.cs`)**：
  - 擴充更豐富的參數化查詢、交易控制與批次資料集封裝，全面防杜 SQL Injection。
- **選單與導航整合 (`MenuService.cs`, `MainPage.Master`)**：
  - 擴充外勤業務快捷入口，優化主頁面功能卡片呈現。

#### 4. 全載具自適應 UI/UX 標準規範
- **外勤操作介面優化**：
  - 導入全載具自適應標準規範，外勤人員於手機、平板與桌機皆能享有流暢無縫的操作體驗。
  - 本地化部署 Font Awesome 圖標庫（`Content/fontawesome/`），移除所有外部 CDN 外連。

#### 5. 正式機安全打包與防 IIS 衝突部署機制
- **打包配置清單 (`deploy_manifest.json`)**：
  - 明確規範發布包必備檔案、排除目錄（`backup/`, `dist/`, `.git` 等）與排除副檔名。
- **自動化打包工具全面升級 (`Scripts/deploy_pack.py`)**：
  - **編碼與語法前檢**：嚴格檢查所有 `.aspx`、`.Master`、`.cs` 為 UTF-8 with BOM，並限制 C# 5.0 語法合規性。
  - **App_Code 防衝突機制**：自動在發布包之 `App_Code` 產製空註解覆蓋檔，根除 IIS 動態編譯引發之 `CS0433` 型別重複定義錯誤。
  - **打包後完整性自檢**：100% 自動驗證必要檔案（DLL、靜態庫、各模組頁面）是否存在於 Zip 中。

#### 6. 專案瘦身與永久開發鐵律
- **資產清理**：清理逾百個舊版過時之靜態圖檔與重複資產，大幅精簡儲存庫體積。
- **開發鐵律文檔 (`GEMINI.md`)**：建立編碼、語法限制、本地化靜態資源及安全發布的最高指導原則。

---

## [1.0.0] - 2026-10-21

### 🚀 版本概述
新北市固定溢散源管理平台（NTPC_FECM）正式發布 1.0.0 版本。本版本完成了自既有舊版 ASP.NET 系統的現代化重構，導入分層架構、RWD 響應式介面設計、資安強化與自動化打包流程，大幅提升系統效能、資安合規性與維運便利性。

### ✨ 主要歷程與改動

#### 1. 前端現代化與 UI/UX 重構
- **登入頁面重構 (`Default.aspx`, `ClientLogin.aspx`)**：
  - 全面揚棄傳統 PostBack 頁面重載模式，改採非同步 AJAX 登入驗證。
  - 整合 SweetAlert2 彈跳視窗，提供即時、直覺的驗證回饋與錯誤提示。
  - 設計現代化卡片式登入表單，支援圖形動態驗證碼快速點擊更換。
- **主功能介面重構 (`MainPage.Master`, `MainPage.aspx`)**：
  - 導入 Bootstrap 現代化樣式庫與 Font Awesome 圖標，全面支援 RWD 跨裝置瀏覽。
  - 重構頂部導航列（品牌識別、操作人員身份標籤、快速安全登出）。
  - 將既有功能模組重組為直覺化網格卡片（Grid Dashboard），提升操作可讀性與視覺質感。

#### 2. 後端分層架構與程式碼模組化
- **服務層與資料存取分層**：
  - `App_Code/Helpers/DbHelper.cs`：全面採用參數化 SQL 查詢（Parameterized Queries），徹底杜絕 SQL Injection 漏洞與風險。
  - `App_Code/Services/AuthService.cs`：封裝使用者驗證邏輯、密碼檢核、驗證碼匹配與 Session 生命週期管理。
  - `App_Code/Services/MenuService.cs` & `Models/MenuModule.cs`：模組化解析選單與權限對應結構，動態呈現所屬權限之功能項目。
- **動態驗證碼處理 (`ValidateCode.ashx`)**：
  - 實作高辨識度防偽字元圖像生成，降低自動化惡意暴力破解風險。
  - 登入驗證後自動銷毀 Session 驗證碼，防止重放攻擊（Replay Attack）。
- **安全登出機制 (`Logout.aspx`)**：
  - 完整銷毀 Server 端 Session、清除驗證 Cookie 並重定向至登入頁。

#### 3. 資安防護與環境隔離
- **機敏資訊隔離機制**：
  - 提供 `Web.config.template` 範本檔，標準化資料庫連線字串與 SMTP 參數配置。
  - 透過 `.gitignore` 嚴格隔離正式機 `Web.config`，避免連線帳密與私密金鑰進入版本控制庫。
- **離線與資安防護支援**：
  - 本地化核心腳本與樣式資源（Bootstrap, jQuery, Vue, Axios），免除機房 CSP (Content Security Policy) 阻擋或無外網連線異常。

#### 4. 自動化建置與安全發布
- **發布打包自動化工具 (`Scripts/deploy_pack.py`)**：
  - 一鍵執行專案建置編譯（`dotnet build -c Release`），產製最新 DLL。
  - 自動清除非必要檔案與暫存（排除 `Backup/`, `obj/`, `*.pdb`, `*.user`, `*.tmp` 等）。
  - 自動封裝輸出版本 Zip 壓縮包至 `dist/`，提供標準化、無殘留的正式機部署流程。

#### 5. 專案文件與資產整合
- 納入《自主管理平台操作手冊 R8》。
- 建立專案標準架構說明文件（`README.md`）與更新日誌（`CHANGELOG.md`）。
