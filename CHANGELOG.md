# 更新日誌 (CHANGELOG)

本專案遵循 [Semantic Versioning](https://semver.org/lang/zh-TW/) 與 [Keep a Changelog](https://keepachangelog.com/zh-TW/1.0.0/) 規範記錄每次版本重要歷程。

---

## [1.5.0] - 2026-10-25

### 🚀 版本概述
新北市固定溢散源管理平台（NTPC_FECM）發布 1.5.0 版本。本版本實現了核心安全架構的模組化解耦與深度縱深防禦，全面以獨立 `AuthModule` 接管認證與授權以杜絕 IIS 子站台衝突；實作雙重 Anti-CSRF 防護、Magic Bytes 檔案上傳簽章檢核、目錄穿越防禦、特權管理操作審計日誌（Audit Trail），並推出標準化安全錯誤頁面（`Error.aspx`）與全外勤表單斷線守護機制。

### ✨ 主要歷程與改動

#### 1. 模組化全域認證與雙重防禦架構 (`AuthModule.cs`, `AuthRuleService.cs`)
- **解耦 Global.asax，模組化接管全域生命週期**：
  - 獨立 `IHttpModule`（`AuthModule.cs`）完整接管身分驗證、RBAC 權限檢核與錯誤處理，編譯入 DLL，解除對 `Global.asax` 的依賴，徹底杜絕 IIS 虛擬子應用程式環境下的動態編譯與型別衝突。
  - 動態於 PreSendRequestHeaders 注入安全標頭（`X-Content-Type-Options: nosniff`, `X-XSS-Protection: 1; mode=block`, `Referrer-Policy: strict-origin-when-cross-origin`），徹底避免 IIS 500.19 重複標頭報錯。
- **雙重 Anti-CSRF 防禦機制**：
  - 核發 `XSRF-TOKEN` Cookie，自動校驗 Axios 附加之 `X-XSRF-TOKEN` Header 與表單 `__RequestVerificationToken`，有效防範跨站請求偽造。
- **精準 RBAC 角色與模組存取矩陣 (`AuthRuleService.cs`)**：
  - 實作完整許可證位元遮罩（LIC / LIC2）檢核，涵蓋案件初/複/三審、施工機具、裸露地、道路巡檢、固定源等全部模組存取邊界。

#### 2. 檔案處理與路徑安全防禦體系 (`FileSecurityHelper.cs`)
- **檔名消毒與目錄穿越防禦 (Path Traversal 防禦)**：
  - 嚴格過濾檔名中的非法字元、`../`、`..\` 等跳脫符號，並透過 `IsSafePath` 校驗檔案絕對路徑，確保檔案嚴格限制於指定安全目錄之內。
- **檔案頭 Magic Bytes 真實格式驗證**：
  - 支援 PDF、PNG、JPG、GIF、ZIP 等常見格式的位元簽章（Magic Bytes）深度檢核，徹底杜絕竄改副檔名的偽裝惡意檔案上傳。

#### 3. 系統特權管理與重要操作稽核日誌 (`AuditLogger.cs`)
- **操作審計追蹤 (Audit Trail)**：
  - 建立特權管理日誌系統，凡帳號開通/停用、權限角色變更、重設臨時密碼等關鍵操作，自動記錄操作者、來源 IP、時間戳記與操作詳情至 `App_Data/Logs/audit_yyyyMM.log`，符合公務機關資安稽核要求。

#### 4. 全站標準化自訂錯誤提示頁面 (`Error.aspx`)
- **安全錯誤處理與追蹤**：
  - 建立標準化錯誤引導頁面，隱藏詳細伺服器錯誤堆疊與敏感資訊，並自動配發 8 碼錯誤追蹤代碼（TraceId），方便使用者向管理員回報並快速對應伺服器端日誌。
  - `Web.config.template` 整合 `customErrors mode="RemoteOnly" defaultRedirect="~/Error.aspx"`。

#### 5. 外勤巡檢表單全面整合離線草稿守護與 CSRF 防護
- **外勤頁面全面升級**：
  - `BareGround/NewBare.aspx`、`Machine/NewMac.aspx`、`RoadBSC/NewBSC.aspx`、`RoadBreak/NewBreak.aspx`、`RoadClean/NewCleanChk.aspx` 全面整合 `fec-offline-sentinel.js` 弱網感知與本機自動暫存，並全面加入 Anti-CSRF 防偽機制，確保外勤表單操作穩定安全。

#### 6. 正式機發布清單與設定範本最佳化
- **發布清單升級 (`deploy_manifest.json`)**：
  - 移除 `Global.asax`，將 `Error.aspx` 與 `Web.config.template` 納入正式機發布必備檔案。
  - `Web.config.template` 完整配置 `AuthModule` 模組註冊、30 分鐘逾時設定、httpCookies 資安屬性與常用 MIME Types。

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
