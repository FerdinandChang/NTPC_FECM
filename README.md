# 新北市固定溢散源管理平台 (NTPC_FECM)

新北市環境保護局固定溢散源自主管理管理平台 (New Taipei City Fugitive Emission Control Management Platform)。

---

## 📌 專案簡介
本平台提供新北市轄內固定溢散源業者及主管機關進行申報、自主管理填報、審查、統計分析與管制作業。
自 1.0.0 版本起，專案全面進行現代化架構重構，採用響應式介面 (RWD)、分層設計模式 (Separation of Concerns)、強化資安防護及自動化部署工具。

---

## 🛠️ 技術棧 (Tech Stack)
- **Runtime / Framework**：.NET Framework 4.8 / ASP.NET Web Forms
- **Language**：C# 8.0+
- **Database**：Microsoft SQL Server (使用參數化查詢與 `DbHelper`)
- **Frontend**：Bootstrap 5, jQuery 3.6.4, Vue 3, SweetAlert2, Font Awesome
- **Deployment Automation**：Python 3 (`Scripts/deploy_pack.py`)

---

## 📁 目錄結構

```text
d:\NTPC_FEC/
│
├── App_Code/               # 核心共用元件與後端服務分層
│   ├── Helpers/            # 資料庫存取協助工具 (DbHelper.cs)
│   ├── Models/             # 資料模型 (UserAccount.cs, MenuModule.cs)
│   └── Services/           # 商業邏輯 (AuthService.cs, MenuService.cs)
│
├── Content/                # 樣式檔與本機靜態資源 (Bootstrap, CSS)
├── Scripts/                # JavaScript 腳本庫與自動化部署工具
│   └── deploy_pack.py      # 正式機安全建置與一鍵打包腳本
├── Modules/                # 各業務功能頁面模組
├── images/                 # 圖標與介面圖像資產
│
├── Default.aspx            # 現代化登入首頁 (AJAX 登入 + SweetAlert2)
├── ClientLogin.aspx        # 業者端快速登入入口
├── MainPage.Master         # 平台母版頁 (含響應式導航列與佈局)
├── MainPage.aspx           # 登入後儀表板 (模組化功能卡片導覽)
├── ValidateCode.ashx       # 安全動態圖形驗證碼產生器
├── Logout.aspx             # 安全登出與 Session 註銷處理
├── Web.config.template     # 正式機安全設定檔範本 (不含敏感密碼)
├── NTPC_FEC.csproj         # Visual Studio / MSBuild 專案檔
├── CHANGELOG.md            # 專案版本更新重要歷程紀錄
└── 自主管理平台操作手冊R8.pdf # 平台標準操作手冊
```

---

## 🚀 快速開始與部署說明

### 1. 本地開發設定
1. 複製 `Web.config.template` 為 `Web.config`。
2. 開啟 `Web.config`，依本地或測試伺服器環境配置 SQL Server 連線字串與 SMTP 參數：
   ```xml
   <connectionStrings>
     <add name="MainConnectionString" connectionString="Data Source={SERVER};Initial Catalog=NTPC_FEC;User ID={USER};Password={PASSWORD}" providerName="System.Data.SqlClient" />
   </connectionStrings>
   ```
3. 使用 Visual Studio 2019/2022 開啟 `NTPC_FEC.csproj`，或使用命令列執行建置：
   ```powershell
   dotnet build NTPC_FEC.csproj
   ```

### 2. 正式機安全發布打包 (Release Packaging)
專案內建 Python 自動化打包腳本，會自動建置 Release DLL 並過濾備份與臨時檔：
```powershell
python Scripts\deploy_pack.py
```
執行完成後，打包產物將輸出於 `dist/` 目錄中（例如 `dist/NTPC_FEC_Release_YYYYMMDD_HHMMSS.zip`），可直接上傳並解壓縮部署於 IIS 站台。

---

## 📝 版本維護與歷程規範
本專案嚴格遵循語意化版本（Semantic Versioning）與版本歷程紀錄規範：
- 每次版本更新均於 [CHANGELOG.md](CHANGELOG.md) 詳載版本號、發布日期及重要改動事項。
- 遵循 Git Tag 標註版本（如 `v1.0.0`）。
