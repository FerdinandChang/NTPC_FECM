# 新北市固定溢散源管理平台 (NTPC_FECM)

新北市環境保護局固定溢散源自主管理管理平台 (New Taipei City Fugitive Emission Control Management Platform)。

---

## 📌 專案簡介
本平台提供新北市轄內固定溢散源業者及主管機關進行自主管理申報、施工機具查核、裸露地列管、洗車設備監控、道路洗掃巡檢、案件初複三審管制作業、統計分析、衛星植生綠覆率圖台管理及 LINE 官方帳號智慧推播服務。
自 1.0.0 完成現代化架構重構，1.1.0 建立巡檢規範與本地地圖庫，1.2.0 實現全業務模組標準化整合，1.3.0 導入 LINE 智慧推播與洗車設備名冊，1.4.0 全面實作全域資安防護（未授權過濾、上傳目錄防 WebShell）、政府資安規範之 30 分鐘閒置自動登出與預警、外勤離線草稿守護器（FEC Offline Sentinel）及原生 PowerShell 自動化安全發布工具。

---

## 🛠️ 技術棧 (Tech Stack)
- **Runtime / Framework**：.NET Framework 4.8 / ASP.NET Web Forms
- **Language**：C# 5.0 相容規範（嚴格防止 IIS 編譯不相容）
- **Database**：Microsoft SQL Server（使用參數化查詢與 `DbHelper`）
- **Frontend**：Bootstrap 4, jQuery (3.6.0/3.6.4/3.7.1), Vue 3, Leaflet 1.9.4, SweetAlert2, Font Awesome, QRCode.js (本地化離線版)
- **Deployment Automation**：PowerShell (`Deploy-Pack.ps1`) / Python 3 (`deploy_pack.py`) + `deploy_manifest.json`

---

## 📁 目錄結構

```text
d:\NTPC_FEC/
│
├── App_Code/               # 核心共用元件與後端服務分層
│   ├── Helpers/            # 資料庫存取協助工具 (DbHelper.cs)
│   ├── Models/             # 資料模型 (UserAccount.cs, MenuModule.cs)
│   ├── Security/           # 全域身分驗證過濾與資安防護模組 (AuthFilterModule.cs)
│   └── Services/           # 商業邏輯 (AuthService.cs, MenuService.cs, PermissionService.cs, PendingTaskService.cs)
│
├── Upload/                 # 檔案上傳目錄 (配置專屬 Web.config 嚴格禁止執行任何腳本)
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
├── Scripts/                # JavaScript 庫 (Vue 3, Axios, jQuery, Leaflet, Highcharts, QRCode, fec-offline-sentinel.js)
│   ├── Deploy-Pack.ps1     # 原生 PowerShell 一鍵安全打包防呆工具
│   └── deploy_pack.py      # Python 版安全打包工具
├── images/                 # 圖標與介面圖像資產 (含 LINE 官方識別與 QR 圖檔)
│
├── Default.aspx            # 現代化登入首頁 (AJAX 登入 + SweetAlert2 + 逾時自動提示)
├── ClientLogin.aspx        # 業者端快速登入入口
├── MainPage.Master         # 平台母版頁 (含全域 30 分鐘閒置倒數、心跳保活與預警彈窗)
├── MainPage.aspx           # 登入後儀表板 (模組化功能卡片導覽與待辦統計徽章)
├── OutLink.aspx            # 外部系統單一簽入 (SSO) 安全跳轉橋接
├── ValidateCode.ashx       # 安全動態圖形驗證碼產生器
├── KeepAlive.ashx          # 外勤長表單 Session 展延心跳接收端
├── Global.asax             # 全域應用程式事件與例外日誌持久化
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
本專案提供原生 PowerShell（推薦）與 Python 自動化打包工具，嚴格依據 `deploy_manifest.json` 執行 UTF-8 BOM 檢查、C# 5.0 語法前檢、建置編譯、App_Code 防 CS0433 衝突覆蓋與完整性自檢：

- **PowerShell 原生一鍵打包（免安裝 Python）**：
  ```powershell
  .\Scripts\Deploy-Pack.ps1
  ```
- **Python 版打包工具**：
  ```powershell
  python Scripts\deploy_pack.py
  ```
執行完成後，發布壓縮包將輸出於 `dist/` 目錄中（例如 `dist/NTPC_FEC_Release_YYYYMMDD_HHMMSS.zip`），可直接上傳並解壓縮部署於正式機 IIS 站台。

---

## 📝 版本維護與歷程規範
本專案嚴格遵循語意化版本（Semantic Versioning）與版本歷程紀錄規範：
- 每次版本更新均於 [CHANGELOG.md](CHANGELOG.md) 詳載版本號、發布日期及重要改動事項。
- 遵循 Git Tag 標註版本（如 `v1.0.0`、`v1.1.0`、`v1.2.0`、`v1.3.0`、`v1.4.0`）。
