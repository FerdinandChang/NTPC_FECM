# 更新日誌 (CHANGELOG)

本專案遵循 [Semantic Versioning](https://semver.org/lang/zh-TW/) 與 [Keep a Changelog](https://keepachangelog.com/zh-TW/1.0.0/) 規範記錄每次版本重要歷程。

---

## [1.3.0] - 2026-10-24

### 🚀 版本概述
新北市固定溢散源管理平台（NTPC_FECM）發布 1.3.0 版本。本版本隆重推出新北市固定源 LINE 官方帳號與智慧推播通報模組（`LINE/Line.aspx`）、上線出入口洗車台設備完整清單管制模組（`Wash/WashList.aspx`）、實作高安全性管理員臨時密碼重設與通知信寄送服務，並針對空品惡化通報與全站各業務清單執行深度自適應 RWD 與行動端卡片化優化。

### ✨ 主要歷程與改動

#### 1. LINE 官方帳號智慧通報與綁定模組 (`LINE/`)
- **LINE 官方帳號整合服務 (`LINE/Line.aspx`, `Line.aspx.cs`)**：
  - 整合新北市環保局固定溢散源 LINE 官方帳號，提供現場巡查、空品惡化預警與業者端即時雙向推播。
  - 實作智慧帳號綁定流程，支援動態產生專屬綁定 QR Code（引入本地庫 `Scripts/qrcode.min.js` 及各解析度圖標資產）。
  - 提供圖文選單快捷入口說明與各類環保法規/防制措施指引。

#### 2. 洗車設備名冊與運作管理模組 (`Wash/`)
- **洗車設備名冊與管制清單 (`Wash/WashList.aspx`, `WashList.aspx.cs`)**：
  - 完整收錄新北市營建工地、砂石場、預拌混凝土廠等車輛出入口洗車設備基本資料與設施型式。
  - 整合洗車設施運作狀態、定期自主檢驗履歷與歷史稽查紀錄。
  - 納入 `deploy_manifest.json` 正式機發布清單。

#### 3. 帳號安全與臨時密碼發行郵件服務
- **高強度臨時密碼重設機制 (`App_Code/Services/AuthService.cs`)**：
  - 實作安全 RNG 加密亂數與 Fisher-Yates 演算法生成 10 碼高強度臨時密碼。
  - 實作管理員一鍵重設密碼並經由 `MailService` 發送密碼通知信至該帳號信箱。
  - 舊密碼自動封存至 `UserPwdHistory` 歷史記錄表，並將 `LastPwdChangeDate` 設為 NULL，強制使用者於首次登入時變更密碼。
- **管理端帳號介面強化 (`Modules/Manager/AccountManagement.aspx`)**：
  - 介面整合「重設臨時密碼」彈跳視窗（Modal），直覺展示收件信箱並回傳即時發送狀態。

#### 4. 空品惡化通報與自主申報全載具 RWD 重構
- **空品惡化應變申報 (`OwnReport/Report_AirQuality.aspx`, `AirQuality_List.aspx`)**：
  - 全面優化通報填報表單與通報清單，徹底解決手機端破版與換行問題。
  - 強化自主檢查照片上傳即時預覽與縮圖點擊放大功能。
- **自主防制措施照片申報 (`OwnReport/PIC_Report.aspx`, `PIC_Report_List.aspx`)**：
  - 採用卡片化流動式版面，提升現場外勤與工地人員操作流暢度。

#### 5. 全站列表與明細深度行動端優化 (消除橫向捲動)
- **行動端卡片式清單全面落地**：
  - 在 `FAC/Charts.aspx`、`FAC/FAC_List.aspx`、`Machine/NewMac.aspx` 等頁面實作小螢幕專屬數據卡片，外勤人員於手機端無需橫向捲動即可瀏覽完整欄位。
  - 優化工具列按鈕與搜尋輸入框水平排列防折行排版（`flex-wrap: nowrap`）。
  - 修復行動端頂部導覽列過長文字溢出問題，自適應縮小字體與標籤。

#### 6. NDVI 植被監測背景排程增強 (`NdviJob/`)
- **排程自動化批次腳本 (`NdviJob/run_monthly.bat`)**：
  - 建立 Windows 工作排程器批次腳本，確保每月 Sentinel-2 圖磚產製自動無痛運作。

#### 7. 打包清單與安全規範完善
- **打包配置更新 (`deploy_manifest.json`, `Scripts/deploy_pack.py`)**：
  - 修正中文字元編碼，將 `LINE/Line.aspx`、`Wash/WashList.aspx` 及 LINE 相關圖示完整列入打包必備檔案。
  - `.gitignore` 補充排除 `Microsoft/` 暫存目錄。

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

---

## [1.0.0] - 2026-10-21

### 🚀 版本概述
新北市固定溢散源管理平台（NTPC_FECM）正式發布 1.0.0 版本。本版本完成了自既有舊版 ASP.NET 系統的現代化重構，導入分層架構、RWD 響應式介面設計、資安強化與自動化打包流程，大幅提升系統效能、資安合規性與維運便利性。
