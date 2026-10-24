# 新北市固定溢散源管理平台 (NTPC_FECM)

新北市環境保護局固定溢散源自主管理管理平台 (New Taipei City Fugitive Emission Control Management Platform)。

---

## 📌 專案簡介
本平台提供新北市轄內固定溢散源業者及主管機關進行自主管理申報、施工機具查核、裸露地列管、洗車設備監控、道路洗掃巡檢、案件初複三審管制作業、統計分析、衛星植生綠覆率圖台管理及 LINE 官方帳號智慧推播服務。
自 1.0.0 完成現代化架構重構，1.1.0 建立巡檢規範與本地地圖庫，1.2.0 實現全業務模組標準化整合與待辦統計服務，1.3.0 正式導入 LINE 官方帳號智慧通報推播、洗車台設備完整名冊管理、高安全性臨時密碼郵件發行及深度行動端 RWD 卡片化體驗。

---

## 🛠️ 技術棧 (Tech Stack)
- **Runtime / Framework**：.NET Framework 4.8 / ASP.NET Web Forms
- **Language**：C# 5.0 相容規範（嚴格防止 IIS 編譯不相容）
- **Database**：Microsoft SQL Server（使用參數化查詢與 `DbHelper`）
- **Frontend**：Bootstrap 4, jQuery (3.6.0/3.6.4/3.7.1), Vue 3, Leaflet 1.9.4, SweetAlert2, Font Awesome, QRCode.js (本地化離線版)
- **Deployment Automation**：Python 3 (`deploy_manifest.json` + `Scripts/deploy_pack.py`)

---

## 📁 目錄結構

```text
d:\NTPC_FEC/
│
├── App_Code/               # 核心共用元件與後端服務分層
│   ├── Helpers/            # 資料庫存取協助工具 (DbHelper.cs)
│   ├── Models/             # 資料模型 (UserAccount.cs, MenuModule.cs)
│   └── Services/           # 商業邏輯 (AuthService.cs, MenuService.cs, PermissionService.cs, PendingTaskService.cs)
│
├── LINE/                   # LINE 官方帳號智慧通報模組 (Line.aspx, Line.aspx.cs)
├── Wash/                   # 洗車設備與出入口沖洗監控模組 (WashList.aspx, ReportUpload.aspx, DataInput.aspx)
├── Machine/                # 施工機具管理模組 (NewMac.aspx, macList.aspx)
├── BareGround/             # 裸露地管制作業模組 (NewBare.aspx, Bare_List.aspx, BareResult.aspx)
├── Case/                   # 營建工程與案件管理模組 (NewCase.aspx, CaseList.aspx, Case_Sum.aspx)
├── Manager/                # 案件初/複/三審審核作業模組 (managerList.aspx, Check_Step1.aspx 等)
├── FAC/                    # 固定污染源稽查管理模組 (FAC_List.aspx, FAC_Detail.aspx, Charts.aspx)
├── OwnReport/              # 業者自主申報與空品惡化應變模組 (PIC_Report.aspx, Report_AirQuality.aspx)
├── NDVI/                   # 植生指標與衛星綠覆率圖台模組 (NdviMap.aspx, ntpc_towns.json)
├── NdviJob/                # 衛星圖磚背景排程建置腳本 (ndvi_build.py, run_monthly.bat)
│
├── RoadClean/              # 道路洗掃與髒污巡檢模組 (NewCleanChk.aspx, NewDirty.aspx, Clean_List.aspx 等)
├── RoadBreak/              # 道路破壞與施工巡查模組 (NewBreak.aspx, Break_List.aspx, BreakDetail.aspx)
├── RoadBSC/                # 車行路段查核模組 (NewBSC.aspx, BSC_List.aspx, BSCDetail.aspx)
│
├── Modules/                # 系統維運模組
│   └── Manager/            # 帳號管理與密碼維護 (AccountManagement.aspx, PasswordChange.aspx)
│
├── Content/                # 樣式檔與本機靜態資源 (Bootstrap, FontAwesome, Leaflet)
├── Scripts/                # JavaScript 庫 (Vue 3, Axios, jQuery, Leaflet, Highcharts, QRCode)
├── images/                 # 圖標與介面圖像資產 (含 LINE 官方識別與 QR 圖檔)
│
├── Default.aspx            # 現代化登入首頁 (AJAX 登入 + SweetAlert2)
├── ClientLogin.aspx        # 業者端快速登入入口
├── MainPage.Master         # 平台母版頁 (全載具自適應導航列與佈局)
├── MainPage.aspx           # 登入後儀表板 (模組化功能卡片導覽與待辦統計徽章)
├── OutLink.aspx            # 外部系統單一簽入 (SSO) 安全跳轉橋接
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
專案內建自動化打包腳本，依據 `deploy_manifest.json` 執行編碼檢查、建置編譯、防 CS0433 衝突覆蓋與完整性自檢：
```powershell
python Scripts\deploy_pack.py
```
執行完成後，打包產物將輸出於 `dist/` 目錄中（例如 `dist/NTPC_FEC_Release_YYYYMMDD_HHMMSS.zip`），可直接上傳並解壓縮部署於正式機 IIS 站台。

---

## 📝 版本維護與歷程規範
本專案嚴格遵循語意化版本（Semantic Versioning）與版本歷程紀錄規範：
- 每次版本更新均於 [CHANGELOG.md](CHANGELOG.md) 詳載版本號、發布日期及重要改動事項。
- 遵循 Git Tag 標註版本（如 `v1.0.0`、`v1.1.0`、`v1.2.0`、`v1.3.0`）。
