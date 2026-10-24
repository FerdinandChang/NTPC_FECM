# 更新日誌 (CHANGELOG)

本專案遵循 [Semantic Versioning](https://semver.org/lang/zh-TW/) 與 [Keep a Changelog](https://keepachangelog.com/zh-TW/1.0.0/) 規範記錄每次版本重要歷程。

---

## [1.4.0] - 2026-10-24

### 🚀 版本概述
新北市固定溢散源管理平台（NTPC_FECM）發布 1.4.0 版本。本版本著重於「全域資安防護」、「政府資安規範相容性（30分鐘閒置自動登出）」、「外勤離線草稿守護（FEC Offline Sentinel）」及「原生 PowerShell 自動化安全發布工具」的全面實作與強化，打造高資安、高可靠性與抗斷網之外勤巡查作業環境。

### ✨ 主要歷程與改動

#### 1. 全域身分驗證過濾與上傳目錄防 WebShell 攻擊
- **全域認證過濾模組 (`App_Code/Security/AuthFilterModule.cs`)**：
  - 實作全域 HTTP 模組攔截未授權存取，涵蓋靜態資源與公開頁面白名單。
  - 針對一般網頁請求：未登入或 Session 逾時強制安全導向 `Default.aspx?reason=timeout`。
  - 針對 AJAX/API 呼叫：自動攔截並回傳標準 HTTP 401 JSON 回應（`{"success":false,"authenticated":false,"message":"連線逾時..."}`），杜絕 API 越權繞過風險。
- **上傳目錄安全隔離 (`Upload/Web.config`)**：
  - 在 `Upload/` 目錄部署專屬安全設定檔，將 IIS 處理常式存取原則限制為唯讀（`accessPolicy="Read"`）。
  - 明確禁用 `.aspx`、`.ashx`、`.asmx`、`.cs`、`.config`、`.exe`、`.bat`、`.cmd` 等副檔名，並設定 `HttpForbiddenHandler`，徹底阻絕任何上傳 WebShell 與惡意腳本執行。

#### 2. 全域例外攔截與資安日誌持久化 (`Global.asax`, `Global.asax.cs`)
- **應用程式生命週期與錯誤攔截**：
  - `Application_Start` 自動呼叫 `EnsurePasswordColumnCapacity()` 確保密碼欄位長度合規。
  - `Application_Error` 全域攔截未預期異常，將時間、使用者帳號、來源 IP、HTTP 方法、請求網址及完整堆疊追蹤安全記錄至 `App_Data/Logs/Error_yyyyMMdd.log`。
  - AJAX 請求自動屏蔽系統錯誤內部細節，統一回應安全的標準 500 JSON，符合 OWASP 資安防護標準。

#### 3. 符合政府機關資安規範之 30 分鐘閒置自動登出與預警機制
- **全域閒置偵測與預警彈窗 (`MainPage.Master`, `Logout.aspx`, `KeepAlive.ashx`)**：
  - 符合政府機關資安規範：連續 30 分鐘無操作強制自動登出。
  - 頂部導航列動態顯示操作有效倒數計時膠囊（`30:00`）。
  - 進入最後 120 秒前跳出全螢幕模糊預警彈窗（`idle-modal-dialog`），支援大數字即時倒數與一鍵延長連線。
  - 全載具操作即時重置：偵測到任何滑鼠移動、鍵盤按鍵、滾輪、點擊或觸控操作，即時無感重置倒數計時，每 5 分鐘自動向 `KeepAlive.ashx` 發送心跳展延 Session。
  - 支援瀏覽器分頁能見度（`visibilitychange`）監聽，防止筆電休眠或背景分頁喚醒後繞過逾時檢驗。
  - 登出時重定向至 `Default.aspx?reason=timeout`，登入頁友善提示逾時登出資訊。

#### 4. 外勤現場巡查離線與本機草稿守護器 (`Scripts/fec-offline-sentinel.js`)
- **弱網與斷網防呆保護**：
  - 外勤現場弱網或斷網時即時感知，於頂部顯示醒目離線警報列。
  - 每 15 秒自動將填報中的表單資料備份暫存至本機 localStorage。
  - 斷線重連或重新整理頁面時，主動提供「一鍵還原上次填報草稿」功能。
  - 表單成功送出後自動安全銷毀本機草稿。
  - 全面應用於外勤表單頁面（`RoadClean/NewCleanChk.aspx`, `BareGround/NewBare.aspx` 等）。

#### 5. 原生 PowerShell 自動化安全發布與防呆打包工具 (`Scripts/Deploy-Pack.ps1`)
- **擺脫外部 Python 環境依賴**：
  - 原生 PowerShell 實作一鍵安全發布工具，相容所有 Windows Server / IIS 環境。
  - 整合 UTF-8 BOM 自動補齊、Vue `@` 語法合規前檢、Release DLL 建置、`App_Code` 防 CS0433 衝突覆蓋及發布包自檢。

#### 6. 正式機發布清單升級 (`deploy_manifest.json`)
- 納入 `KeepAlive.ashx`, `Global.asax`, `Upload/Web.config`, `Scripts/fec-offline-sentinel.js` 等核心防護檔案至發布清單。

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
- **空品惡化預警應變申報 (`OwnReport/Report_AirQuality.aspx`, `AirQuality_List.aspx`)**：
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

---

## [1.1.0] - 2026-10-22

### 🚀 版本概述
新北市固定溢散源管理平台（NTPC_FECM）發布 1.1.0 版本。本版本完成了三大核心外勤巡檢業務模組（道路洗掃巡檢、道路破壞通報、車行路段查核）的現代化全載具自適應重構，全面導入本地化 Leaflet 1.9.4 地圖圖台、升級後端權限服務體系，並建立包含語法合規與防 IIS 型別衝突的正式機打包自動化機制。

---

## [1.0.0] - 2026-10-21

### 🚀 版本概述
新北市固定溢散源管理平台（NTPC_FECM）正式發布 1.0.0 版本。本版本完成了自既有舊版 ASP.NET 系統的現代化重構，導入分層架構、RWD 響應式介面設計、資安強化與自動化打包流程，大幅提升系統效能、資安合規性與維運便利性。
