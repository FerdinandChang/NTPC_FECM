# 更新日誌 (CHANGELOG)

本專案遵循 [Semantic Versioning](https://semver.org/lang/zh-TW/) 與 [Keep a Changelog](https://keepachangelog.com/zh-TW/1.0.0/) 規範記錄每次版本重要歷程。

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
