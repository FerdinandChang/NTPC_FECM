# 新北市固定溢散源管理平台 (NTPC_FECM)

新北市環境保護局固定溢散源自主管理管理平台 (New Taipei City Fugitive Emission Control Management Platform)。

---

## 📌 專案簡介
本平台提供新北市轄內固定溢散源業者及主管機關進行申報、自主管理填報、現場稽巡查、案件管制作業、審查與統計分析。
自 1.0.0 起全面進行現代化架構重構，1.1.0 版進一步導入三大巡檢核心業務模組（道路洗掃巡檢、道路破壞通報、車行路段查核）、本地化 Leaflet 1.9.4 地圖圖台、權限體系服務與具備語法合規與防 IIS CS0433 衝突的正式機打包自動化機制。

---

## 🛠️ 技術棧 (Tech Stack)
- **Runtime / Framework**：.NET Framework 4.8 / ASP.NET Web Forms
- **Language**：C# 5.0 相容規範（嚴格防止 IIS 編譯不相容）
- **Database**：Microsoft SQL Server（使用參數化查詢與 `DbHelper`）
- **Frontend**：Bootstrap 4, jQuery 3.6.4, Vue 3, Leaflet 1.9.4, SweetAlert2, Font Awesome (本地化離線版)
- **Deployment Automation**：Python 3 (`deploy_manifest.json` + `Scripts/deploy_pack.py`)

---

## 📁 目錄結構

```text
d:\NTPC_FEC/
│
├── App_Code/               # 核心共用元件與後端服務分層
│   ├── Helpers/            # 資料庫存取協助工具 (DbHelper.cs)
│   ├── Models/             # 資料模型 (UserAccount.cs, MenuModule.cs)
│   └── Services/           # 商業邏輯 (AuthService.cs, MenuService.cs, PermissionService.cs)
│
├── RoadClean/              # 道路洗掃與髒污巡檢模組
│   ├── NewCleanChk.aspx    # 洗掃作業現場自主檢核填報
│   ├── NewDirty.aspx       # 道路髒污巡查通報
│   ├── ImproveDirty.aspx   # 髒污改善回報
│   ├── Dirty_List.aspx     # 髒污案件管理清單
│   ├── DirtyDetail.aspx    # 髒污案件明細與歷程
│   ├── Clean_List.aspx     # 洗掃作業執行清單
│   └── RoadClean_Sum.aspx  # 洗掃成果統計分析 (Highcharts 圖表)
│
├── RoadBreak/              # 道路破壞與施工巡查模組
│   ├── NewBreak.aspx       # 道路破壞通報填報
│   ├── Break_List.aspx     # 道路破壞清單
│   └── BreakDetail.aspx    # 道路破壞明細檢視
│
├── RoadBSC/                # 車行路段查核模組
│   ├── NewBSC.aspx         # 路段巡查作業填報
│   ├── BSC_List.aspx       # 路段巡查清單
│   └── BSCDetail.aspx      # 路段查核明細
│
├── Modules/                # 各業務功能頁面模組
│   └── Manager/            # 系統管理模組 (AccountManagement.aspx, PasswordChange.aspx)
│
├── Content/                # 樣式檔與本機靜態資源 (Bootstrap, FontAwesome, Leaflet)
├── Scripts/                # JavaScript 庫 (Vue 3, Axios, jQuery, Leaflet, Highcharts)
├── images/                 # 圖標與介面圖像資產
│
├── Default.aspx            # 現代化登入首頁 (AJAX 登入 + SweetAlert2)
├── ClientLogin.aspx        # 業者端快速登入入口
├── MainPage.Master         # 平台母版頁 (含響應式導航列與全載具佈局)
├── MainPage.aspx           # 登入後儀表板 (模組化功能卡片導覽)
├── ValidateCode.ashx       # 安全動態圖形驗證碼產生器
├── Logout.aspx             # 安全登出與 Session 註銷處理
├── Web.config.template     # 正式機安全設定檔範本 (不含敏感密碼)
├── deploy_manifest.json    # 正式機打包清單與強制自檢配置
├── GEMINI.md               # 專案永久開發與部署鐵律指南
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
專案內建 Python 自動化打包腳本，依據 `deploy_manifest.json` 執行編碼檢查、建置編譯、防 CS0433 衝突覆蓋與完整性自檢：
```powershell
python Scripts\deploy_pack.py
```
執行完成後，打包產物將輸出於 `dist/` 目錄中（例如 `dist/NTPC_FEC_Release_YYYYMMDD_HHMMSS.zip`），可直接上傳並解壓縮部署於正式機 IIS 站台。

---

## 📝 版本維護與歷程規範
本專案嚴格遵循語意化版本（Semantic Versioning）與版本歷程紀錄規範：
- 每次版本更新均於 [CHANGELOG.md](CHANGELOG.md) 詳載版本號、發布日期及重要改動事項。
- 遵循 Git Tag 標註版本（如 `v1.0.0`、`v1.1.0`）。
