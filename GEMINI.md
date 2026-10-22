# NTPC_FEC 專案永久開發與部署鐵律 (Project Rules)

本檔案為 `d:\NTPC_FEC`（新北市固定溢散源管理平台，正式機測試站台 `D:\Web\NTPC_FECM`）的最高指導原則，所有程式碼撰寫與打包發布均須嚴格遵守：

## 1. 編碼與語法鐵律 (防止 IIS 編譯錯誤與亂碼)
- **檔案編碼**：所有 `.aspx`、`.Master`、`.ashx`、`.cs` 檔案存檔時**必須使用 UTF-8 with BOM (`utf-8-sig`)**，嚴禁無 BOM 的 UTF-8（否則 Windows Server IIS 預設以 CP950 Big5 解讀會造成中文亂碼）。
- **C# 5.0 語法限制**：專案已於 `NTPC_FEC.csproj` 鎖定 `<LangVersion>5</LangVersion>`。全專案嚴禁使用 C# 6.0+ 語法：
  - 禁止字串插值 `$"..."`（請一律使用 `string.Format(...)` 或 `+` 串接）。
  - 禁止 Null 條件運算子 `?.`（請一律使用顯式 `!= null` 與 `!= DBNull.Value` 判斷）。
  - 禁止自動屬性初始化 `public List<T> Items { get; set; } = new List<T>();`（請寫在建構子中）。
  - 禁止區域函式（Local Functions）與運算式主體屬性（`=>`）。
- **ASPX 中的 Vue 語法限制**：
  - 嚴禁在 `.aspx` / `.Master` 中使用 `@click`、`@submit`、`@change` 等 `@` 縮寫（避免 ASP.NET 解析器誤判），**一律使用完整指令 `v-on:click`、`v-on:submit`、`v-on:change`**。
  - 掛載容器（如 `#loginApp`）必須加上 `v-cloak` 與 `[v-cloak] { display: none !important; }` 防止未編譯模板閃爍。

## 2. 本地化靜態資源鐵律 (避開機房資安 CSP 阻擋)
- 前端核心庫與地圖庫一律引用本地路徑，禁止依賴外部 JS CDN：
  - Vue 3：`Scripts/vue.global.prod.js`
  - Axios：`Scripts/axios.min.js`
  - Bootstrap 4：`Content/bootstrap.min.css`、`Scripts/bootstrap.bundle.min.js`
  - Leaflet 1.9.4：`Content/leaflet/leaflet.css`、`Scripts/leaflet/leaflet.js`（所有地圖功能統一使用 Leaflet.js）

## 3. 安全打包與發布鐵律 (`deploy_manifest.json` + `Scripts/deploy_pack.py`)
- **不可排除 `Scripts/` 目錄**：Windows 不分大小寫，前端資源位於 `Scripts/`，絕不可將 `"scripts"` 列入排除目錄；僅可排除 `.py`、`.ps1` 等開發腳本檔案。
- **`App_Code` 防衝突機制**：本專案為 Web Application，所有 `.cs` 已預編譯入 `bin\NTPC_FEC.dll`。打包 zip 時，`App_Code` 下的 `.cs` 必須自動寫入空註解覆蓋檔（`// Precompiled into bin/NTPC_FEC.dll`），以確保用戶在正式機解壓縮覆蓋時自動清空殘留的 `App_Code` 原始碼，避免觸發 IIS 動態編譯與 `CS0433` 型別重複定義錯誤。
- **強制打包自檢**：每次執行 `python d:\NTPC_FEC\Scripts\deploy_pack.py` 時，腳本會自動依據 `deploy_manifest.json` 驗證 zip 內所有必備檔案、BOM 標頭與語法合規性，自檢全數通過才算完成。
