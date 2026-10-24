---
name: inspection-ui-standard
description: >-
  新北市固定溢散源管理平台 (NTPC_FEC) 巡檢與現場查核頁面之現代化全載具自適應 UI/UX 標準規範與程式碼樣板。
  適用於道路潔淨巡檢、裸露地巡查、營建工地巡查、車行路段巡查等所有外勤與內勤查核頁面開發與重構。
---

# NTPC_FEC 現場巡查頁面 UI/UX 標準規範 (Inspection UI Standard)

本規範提煉自 [`RoadClean/NewCleanChk.aspx`](file:///d:/NTPC_FEC/RoadClean/NewCleanChk.aspx)，定義新北市固定溢散源管理平台全載具（Desktop、Tablet、Mobile）自適應巡檢頁面的標準架構、視覺樣式與核心互動元件。後續所有巡查模組（如裸露地、營建工地、洗掃街查核等）均須延續套用此規範。

---

## 一、核心設計哲學與全載具佈局架構

### 1. 寬螢幕電腦端 (Desktop, $\ge 1200\text{px}$)：雙欄黃金聯動佈局
- **左欄 (40% 寬度，Sticky 浮動固頂)**：
  - **巡查基本設定卡片**：行政區、巡查對象下拉選單、長度/寬度/起訖點等規格晶片（Stat Chips）。
  - **智慧現場地圖 (Leaflet.js)**：
    - 自動標記點位座標 Pin，點擊 Pin 雙向聯動捲動至右側檢核點。
    - **地圖控制項零遮擋規範**：地圖內部右上角保留給 Leaflet 圖層切換器；「GPS 定位」與「重設全景」快捷鍵一律配置在卡片標題列（Header）右側，杜絕任何圖層選單展開時的按鈕疊層遮擋。
  - **稽查人員簽章面板**：簽名縮圖預覽、確定送出與取消按鈕。
- **右欄 (60% 寬度，主檢核作業區)**：
  - **進度追蹤列**：即時顯示「完成進度 X / Y 點 (Z%)」與「⚡ 一鍵全部合格 (全滿分)」按鈕。
  - **檢核點卡片清單**：各點位獨立卡片，包含現場狀況切換與題目評分。

### 2. 平板載具端 (Tablet, $768\text{px} \sim 1199\text{px}$)
- 上半部基本設定與地圖 1:1 水平並列，下半部檢核點卡片完整展開，按鈕加大至適合手指觸控。

### 3. 手機行動端 (Mobile, $< 768\text{px}$)：外勤極致體驗
- **單欄 100% 流動佈局**：所有輸入與卡片寬度自適應，嚴禁任何水平溢出或橫向捲軸。
- **地圖收合/展開控制**：標題列右側提供「收合地圖 / 展開地圖」切換，避免外勤滑動頁面時手指卡在地圖縮放手勢中。
- **常駐浮動動作列 (Sticky Bottom Bar)**：固定於螢幕最底部，隨時可點選「手寫簽名」與「確定送出」，不必滑到最底端。
- **RWD 中性引導文案鐵律**：嚴禁在提示文字使用「左側」、「上方」等絕對方位詞（例如手機版單欄排版時「左側」會造成誤解），應改為中性功能敘述（例如「請先選取行政區與巡檢道路」），並搭配一鍵跳轉動作按鈕。

---

## 二、標準 Design Tokens 與 CSS 樣式庫

在巡檢頁面 `<head>` 引入以下標準樣式宣告：

```html
<!-- 本地化樣式依賴 -->
<link rel="stylesheet" href="../Content/bootstrap.min.css" />
<link rel="stylesheet" href="../Content/fontawesome/css/all.min.css" />
<link rel="stylesheet" href="../Content/leaflet/leaflet.css" />

<style>
    :root {
        --brand-primary: #0099e5;     /* 新北天空青藍 (Navbar/強調) */
        --brand-blue: #0284c7;        /* 科技藍 (按鈕/選中) */
        --brand-dark-blue: #0b1f7d;   /* 海軍深藍 (標題/Tag) */
        --brand-navy: #0f172a;        /* 標題文字主色 */
        --bg-canvas: #f1f5f9;         /* 頁面灰底 */
        --surface: #ffffff;           /* 卡片純白底色 */
        --border-color: #e2e8f0;      /* 邊框線條 */
        --text-main: #0f172a;         /* 內文主要文字 */
        --text-muted: #64748b;        /* 次要說明文字 */
    }

    * { box-sizing: border-box; -webkit-tap-highlight-color: transparent; }
    body {
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, "Noto Sans TC", "微軟正黑體", sans-serif;
        background-color: var(--bg-canvas);
        margin: 0; padding: 0;
        color: var(--text-main);
        overflow-x: hidden;
    }
    [v-cloak] { display: none !important; }

    /* 頂部導覽列 */
    .top-navbar {
        background: linear-gradient(135deg, #0099e5 0%, #0284c7 100%);
        color: #ffffff;
        height: 56px;
        display: flex; align-items: center; justify-content: space-between;
        padding: 0 16px;
        box-shadow: 0 2px 10px rgba(0, 153, 229, 0.25);
        position: sticky; top: 0; z-index: 1020;
    }

    /* 現代卡片 */
    .card-modern {
        background: var(--surface);
        border-radius: 12px;
        box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05), 0 4px 12px rgba(15, 23, 42, 0.05);
        margin-bottom: 16px;
        border: 1px solid var(--border-color);
        overflow: hidden;
    }
    .card-modern-header {
        padding: 12px 16px;
        background: #ffffff;
        border-bottom: 1px solid var(--border-color);
        display: flex; align-items: center; justify-content: space-between;
    }
    .card-modern-title {
        font-size: 1rem; font-weight: 700; color: var(--brand-navy); margin: 0;
        display: flex; align-items: center; gap: 8px;
    }
    .card-modern-body { padding: 16px; }

    /* 桌面端左欄固頂 */
    @media screen and (min-width: 1200px) {
        .sticky-sidebar {
            position: sticky; top: 72px;
            max-height: calc(100vh - 88px);
            overflow-y: auto; padding-right: 4px;
        }
    }

    /* 地圖控制與收合 */
    #map { width: 100%; height: 380px; border-radius: 8px; z-index: 10; transition: height 0.3s ease; }
    #map.map-collapsed { height: 120px !important; }

    /* 地圖座標標記 (Marker Pin) */
    .custom-map-marker { display: flex; align-items: center; justify-content: center; }
    .marker-pin {
        width: 32px; height: 32px;
        border-radius: 50% 50% 50% 0;
        background: #0284c7;
        position: absolute; transform: rotate(-45deg);
        left: 50%; top: 50%; margin: -20px 0 0 -16px;
        box-shadow: 0 3px 8px rgba(0, 0, 0, 0.35);
        border: 2px solid #ffffff;
        display: flex; align-items: center; justify-content: center;
        cursor: pointer;
    }
    .marker-num { transform: rotate(45deg); color: #ffffff; font-weight: 800; font-size: 13px; }

    /* 現場狀況開關 (Segmented Buttons) */
    .status-toggle-row {
        display: flex; align-items: center; justify-content: space-between;
        background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px;
        padding: 8px 12px; margin-bottom: 8px;
    }
    .segmented-group { display: inline-flex; background: #e2e8f0; padding: 3px; border-radius: 8px; gap: 2px; }
    .segment-btn {
        border: none; background: transparent; padding: 6px 16px;
        border-radius: 6px; font-size: 13px; font-weight: 600; color: #475569;
        cursor: pointer; min-height: 36px;
    }
    .segment-btn.active-yes { background: #10b981; color: #ffffff; box-shadow: 0 1px 4px rgba(16, 185, 129, 0.35); }
    .segment-btn.active-no { background: #64748b; color: #ffffff; box-shadow: 0 1px 4px rgba(100, 116, 139, 0.35); }

    /* 評分晶片 (Score Chips) - 熱區大於 42px */
    .score-chips-container { display: flex; flex-wrap: wrap; gap: 8px; }
    .score-chip-btn {
        border: 1px solid #cbd5e1; background: #ffffff; color: #334155;
        padding: 8px 14px; border-radius: 8px; font-size: 13px; font-weight: 600;
        cursor: pointer; display: inline-flex; align-items: center; gap: 6px;
        min-height: 42px; transition: all 0.15s ease;
    }
    .score-chip-btn.selected-100 { background: #ecfdf5; border-color: #10b981; color: #047857; font-weight: 700; box-shadow: 0 0 0 2px rgba(16, 185, 129, 0.2); }
    .score-chip-btn.selected-80  { background: #f0f9ff; border-color: #0284c7; color: #0369a1; font-weight: 700; box-shadow: 0 0 0 2px rgba(2, 132, 199, 0.2); }
    .score-chip-btn.selected-60  { background: #fffbeb; border-color: #f59e0b; color: #b45309; font-weight: 700; box-shadow: 0 0 0 2px rgba(245, 158, 11, 0.2); }
    .score-chip-btn.selected-0   { background: #fef2f2; border-color: #ef4444; color: #b91c1c; font-weight: 700; box-shadow: 0 0 0 2px rgba(239, 68, 68, 0.2); }

    /* 手機底部懸浮列 */
    @media screen and (max-width: 991px) {
        body { padding-bottom: 76px; }
        .mobile-bottom-bar {
            display: flex; position: fixed; bottom: 0; left: 0; right: 0; z-index: 1010;
            background: #ffffff; border-top: 1px solid #e2e8f0;
            box-shadow: 0 -4px 16px rgba(0, 0, 0, 0.08);
            padding: 10px 16px; padding-bottom: calc(10px + env(safe-area-inset-bottom, 0px));
            gap: 10px;
        }
        .mobile-bottom-bar .btn { flex: 1; font-weight: 700; padding: 10px; border-radius: 8px; }
    }
</style>
```

---

## 三、四大核心互動元件 HTML / Vue 範本

### 1. 現場環境狀況開關 (Segmented Yes/No)
```html
<div class="status-toggle-row">
    <span class="status-toggle-title">
        <i class="fas fa-tree text-success"></i> 行道樹
    </span>
    <div class="segmented-group">
        <button type="button" class="segment-btn" :class="{ 'active-yes': pt.STree === 'Y' }" v-on:click="mode !== 'read' && (pt.STree = 'Y')">
            有
        </button>
        <button type="button" class="segment-btn" :class="{ 'active-no': pt.STree === 'N' }" v-on:click="mode !== 'read' && (pt.STree = 'N')">
            無
        </button>
    </div>
</div>
```

### 2. 評分晶片與扣分原因滑出面板 (Score Chips)
```html
<div class="score-chips-container">
    <button v-for="opt in q.Options" :key="opt.Score" type="button" class="score-chip-btn" 
            :class="getScoreChipClass(getScoreObj(pt, q.ChkCode).Score, opt.Score)" 
            v-on:click="mode !== 'read' && setPointScore(pt, q.ChkCode, opt.Score)">
        <i :class="getScoreIcon(opt.Score)"></i>
        {{ opt.Text }}
    </button>
</div>

<!-- 小於 100 分時滑出缺失原因多選/單選標籤 -->
<div v-if="getScoreObj(pt, q.ChkCode).Score !== null && getScoreObj(pt, q.ChkCode).Score < 100 && q.SubItems.length > 0" class="subitem-panel">
    <small class="font-weight-bold text-danger d-block">請點選主要缺失原因：</small>
    <div class="subitem-pill-group">
        <button v-for="sub in q.SubItems" :key="sub" type="button" class="subitem-pill" 
                :class="{ 'active': getScoreObj(pt, q.ChkCode).ChiItem1 === sub }" 
                v-on:click="mode !== 'read' && (getScoreObj(pt, q.ChkCode).ChiItem1 = sub)">
            {{ sub }}
        </button>
    </div>
</div>
```

### 3. 一鍵全部合格 (Quick Pass All) 邏輯
```javascript
quickPassAll() {
    if (this.pointList.length === 0) return;
    this.pointList.forEach(pt => {
        pt.STree = 'Y';
        pt.SIsland = 'Y';
        pt.CivilSide = 'N';
        [...this.questions.RCC, ...this.questions.FLD].forEach(q => {
            const scoreObj = this.getScoreObj(pt, q.ChkCode);
            scoreObj.Score = 100;
            scoreObj.ChiItem1 = '';
        });
    });
    this.alertMessage = '已為全部檢核點套用 100 分滿分合格！';
    this.alertType = 'success';
}
```

### 4. 全螢幕高解析平滑觸控手寫簽名板 (Full-Screen PointerEvents Canvas)
簽名板一律採用全螢幕沉浸式（`width: 100vw; height: 100dvh;`），並使用 **Pointer Events API** 與 **中點二階貝茲曲線** 達成極致滑順手寫效果，徹底消除斷筆與瀏覽器手勢衝突：

```javascript
initCanvas() {
    const canvas = document.getElementById('sigCanvas');
    if (!canvas) return;
    const container = canvas.parentElement;
    const rect = container.getBoundingClientRect();
    const dpr = window.devicePixelRatio || 1;

    canvas.width = Math.round(rect.width * dpr);
    canvas.height = Math.round(rect.height * dpr);
    canvas.style.width = rect.width + 'px';
    canvas.style.height = rect.height + 'px';

    this.canvasCtx = canvas.getContext('2d');
    this.canvasCtx.scale(dpr, dpr);
    this.canvasCtx.strokeStyle = '#0f172a';
    this.canvasCtx.lineWidth = 3.5;
    this.canvasCtx.lineCap = 'round';
    this.canvasCtx.lineJoin = 'round';

    let isDrawing = false;
    let lastX = 0, lastY = 0;

    const getPos = e => {
        const r = canvas.getBoundingClientRect();
        return { x: e.clientX - r.left, y: e.clientY - r.top };
    };

    const down = e => {
        e.preventDefault();
        try { canvas.setPointerCapture(e.pointerId); } catch (err) {}
        isDrawing = true;
        const pos = getPos(e);
        lastX = pos.x; lastY = pos.y;
        this.canvasCtx.beginPath();
        this.canvasCtx.moveTo(lastX, lastY);
    };

    const move = e => {
        if (!isDrawing) return;
        e.preventDefault();
        const pos = getPos(e);
        const midX = (lastX + pos.x) / 2;
        const midY = (lastY + pos.y) / 2;
        this.canvasCtx.quadraticCurveTo(lastX, lastY, midX, midY);
        this.canvasCtx.stroke();
        lastX = pos.x; lastY = pos.y;
    };

    const up = e => {
        if (!isDrawing) return;
        isDrawing = false;
        try { canvas.releasePointerCapture(e.pointerId); } catch (err) {}
        this.canvasCtx.lineTo(lastX, lastY);
        this.canvasCtx.stroke();
        this.canvasCtx.closePath();
    };

    canvas.addEventListener('pointerdown', down, { passive: false });
    canvas.addEventListener('pointermove', move, { passive: false });
    canvas.addEventListener('pointerup', up, { passive: false });
    canvas.addEventListener('pointercancel', up, { passive: false });
}
```

---

## 四、後端 C# 5.0 座標轉換標準演算法 (TWD97 轉 WGS84)

巡檢點位若儲存為二度分帶 TWD97（如 $X \approx 298000, Y \approx 2767000$），請直接複製以下標準函式以符合 C# 5.0 規範並回傳經緯度給 Leaflet 地圖：

```csharp
private static void Twd97ToWgs84(double x, double y, out double lat, out double lon)
{
    if (x <= 0 || y <= 0) { lat = 0; lon = 0; return; }

    double a = 6378137.0;
    double b = 6356752.314245;
    double lon0 = 121.0 * Math.PI / 180.0;
    double k0 = 0.9999;
    double dx = 250000.0;

    double e = Math.Sqrt(1.0 - (b * b) / (a * a));
    double e2 = e * e / (1.0 - e * e);
    x -= dx;

    double M = y / k0;
    double mu = M / (a * (1.0 - Math.Pow(e, 2) / 4.0 - 3.0 * Math.Pow(e, 4) / 64.0 - 5.0 * Math.Pow(e, 6) / 256.0));
    double e1 = (1.0 - Math.Sqrt(1.0 - Math.Pow(e, 2))) / (1.0 + Math.Sqrt(1.0 - Math.Pow(e, 2)));

    double J1 = (3.0 * e1 / 2.0 - 27.0 * Math.Pow(e1, 3) / 32.0);
    double J2 = (21.0 * Math.Pow(e1, 2) / 16.0 - 55.0 * Math.Pow(e1, 4) / 32.0);
    double J3 = (151.0 * Math.Pow(e1, 3) / 96.0);
    double J4 = (1097.0 * Math.Pow(e1, 4) / 512.0);

    double fp = mu + J1 * Math.Sin(2.0 * mu) + J2 * Math.Sin(4.0 * mu) + J3 * Math.Sin(6.0 * mu) + J4 * Math.Sin(8.0 * mu);

    double C1 = e2 * Math.Pow(Math.Cos(fp), 2);
    double T1 = Math.Pow(Math.Tan(fp), 2);
    double R1 = a * (1.0 - Math.Pow(e, 2)) / Math.Pow(1.0 - Math.Pow(e, 2) * Math.Pow(Math.Sin(fp), 2), 1.5);
    double N1 = a / Math.Sqrt(1.0 - Math.Pow(e, 2) * Math.Pow(Math.Sin(fp), 2));
    double D = x / (N1 * k0);

    double latRad = fp - (N1 * Math.Tan(fp) / R1) * (Math.Pow(D, 2) / 2.0 - (5.0 + 3.0 * T1 + 10.0 * C1 - 4.0 * Math.Pow(C1, 2) - 9.0 * e2) * Math.Pow(D, 4) / 24.0 + (61.0 + 90.0 * T1 + 298.0 * C1 + 45.0 * Math.Pow(T1, 2) - 252.0 * e2 - 3.0 * Math.Pow(C1, 2)) * Math.Pow(D, 6) / 720.0);
    double lonRad = lon0 + (D - (1.0 + 2.0 * T1 + C1) * Math.Pow(D, 3) / 6.0 + (5.0 - 2.0 * C1 + 28.0 * T1 - 3.0 * Math.Pow(C1, 2) + 8.0 * e2 + 24.0 * Math.Pow(T1, 2)) * Math.Pow(D, 5) / 120.0) / Math.Cos(fp);

    lat = latRad * 180.0 / Math.PI;
    lon = lonRad * 180.0 / Math.PI;
}
```

---

## 五、案件詳情檢視頁面 (Detail View) 置頂端與階段進度時間軸標準規範

本規範提煉自 [`RoadBSC/BSCDetail.aspx`](file:///d:/NTPC_FEC/RoadBSC/BSCDetail.aspx)、[`RoadBreak/BreakDetail.aspx`](file:///d:/NTPC_FEC/RoadBreak/BreakDetail.aspx) 與 [`RoadClean/DirtyDetail.aspx`](file:///d:/NTPC_FEC/RoadClean/DirtyDetail.aspx)，所有通報單/案件詳情檢視頁面的置頂端佈局與階段進度展示必須嚴格統一。

### 1. 置頂端四層視覺架構 (Visual Hierarchy)
```html
<!-- 1. 置頂深青藍漸層導覽列 (Sticky Top Navbar) -->
<header class="top-navbar no-print"> ... </header>

<!-- 2. 列印專用報表頁首 (螢幕隱藏，列印時顯現) -->
<div class="print-only-header"> ... </div>

<!-- 3. 主作業容器 (固定最大寬度 1560px 居中) -->
<main class="container-fluid-custom">
    <!-- A. 案件退回重辦警告卡片 (若 G_Back === 'Y' / IsBack 觸發) -->
    <div v-if="detail.IsBack || detail.G_Back === 'Y'" class="alert-gback shadow-sm"> ... </div>

    <!-- B. 通報階段進度時間軸 (Status Stepper) -->
    <div class="stepper-container shadow-sm no-print"> ... </div>

    <!-- C. 雙欄卡片佈局 (左欄基本設定與地圖 40%，右欄照片成果對照 60%) -->
    <div class="row"> ... </div>
</main>
```

### 2. 置頂導覽列 (Top Navbar) 標準規範
- **外層標籤**：一律使用 `<header class="top-navbar no-print">`（列印時自動隱藏）。
- **左側品牌區塊 (`.brand-title`)**：
  - **返回按鈕**：統一使用 `.nav-btn.mr-2`，文案統一為「`返回清單`」（手機端使用 `<span class="d-none d-sm-inline">返回清單</span>` 自適應收合為純箭頭）。
  - **模組圖示**：一律為純白 `text-white`（如 `<i class="fas fa-road text-white"></i>`），嚴禁刺眼黃色或雜色。
  - **標題文字**：純白粗體 `1.08rem`，如 `人行道與交通島裸露覆土通報單`。
  - **案號徽章**：一律使用標準白底黑字徽章 `<span v-if="detail.Show_ID" class="badge badge-light text-dark font-weight-bold ml-2" style="font-size: 0.85rem;">{{ detail.Show_ID }}</span>`，只放純案號，嚴禁在頂部塞入狀態標籤或深色底。
- **右側功能動作區塊 (`.d-flex.align-items-center.gap-2`)**：
  - **列印案件按鈕**：統一使用白底黑字陰影膠囊按鈕 `<button type="button" class="nav-btn bg-white text-dark shadow-sm" v-on:click="printCase"><i class="fas fa-print"></i><span class="d-none d-md-inline">列印案件</span></button>`。
  - **路線導航按鈕**（若有點位坐標）：`<button v-if="detail.Lat && detail.Lng" type="button" class="nav-btn bg-white text-dark shadow-sm ml-2" v-on:click="openGoogleMaps"><i class="fas fa-location-arrow text-success"></i><span class="d-none d-md-inline">路線導航</span></button>`。
  - **狀態動作按鈕**：必須依 `numericStatusCode` 案件狀態動態切換（**結案時嚴禁顯示派工或回報按鈕**）：
    - **待派工 (狀態 1)**：顯示 `btn-warning`「`<i class="fas fa-edit mr-1"></i> 編輯案件`」與 `btn-primary`「`<i class="fas fa-paper-plane mr-1"></i> 派工通報`」。
    - **待改善 (狀態 2)**：顯示 `btn-success`「`<i class="fas fa-tools mr-1"></i> 改善回報`」。
    - **已結案 (狀態 3)**：不顯示派工或改善按鈕，維持界面乾淨。

### 3. 通報階段進度時間軸 (Status Stepper) 標準樣板
```html
<div class="stepper-container shadow-sm no-print">
    <div class="stepper-line">
        <div class="stepper-line-fill" :style="{ width: stepperProgress + '%' }"></div>
    </div>

    <!-- 步驟 1: 現場查核立案 -->
    <div class="step-item" :class="getStepClass(1)">
        <div class="step-circle">
            <i v-if="numericStatusCode > 1" class="fas fa-check"></i>
            <span v-else>1</span>
        </div>
        <div class="step-title">現場查核立案</div>
        <div class="step-time">{{ detail.Report_Date || '未填寫' }}</div>
    </div>

    <!-- 步驟 2: 派工改善通報 -->
    <div class="step-item" :class="getStepClass(2)">
        <div class="step-circle">
            <i v-if="numericStatusCode > 2" class="fas fa-check"></i>
            <span v-else>2</span>
        </div>
        <div class="step-title">{{ (detail.IsBack || detail.G_Back === 'Y') ? '案件退回待重派' : '派工改善通報' }}</div>
        <div class="step-time">{{ detail.SetCOM_Date || '待通報' }}</div>
    </div>

    <!-- 步驟 3: 改善完成結案 -->
    <div class="step-item" :class="getStepClass(3)">
        <div class="step-circle">
            <i v-if="numericStatusCode === 3" class="fas fa-check"></i>
            <span v-else>3</span>
        </div>
        <div class="step-title">改善完成結案</div>
        <div class="step-time">{{ detail.Improve_Date || '待改善' }}</div>
    </div>
</div>
```

### 4. 前端 Vue 響應邏輯核心範本
```javascript
computed: {
    // 狀態數值歸一化 (1: 待派工, 2: 待改善, 3: 已結案)
    numericStatusCode() {
        if (!this.detail) return 1;
        if (this.detail.StatusCode === 3 || this.detail.StatusCode === 'IMPROVED' || (this.detail.Improve_Date && this.detail.Improve_Date.trim() !== '')) return 3;
        if (this.detail.StatusCode === 2 || this.detail.StatusCode === 'DISPATCHED' || (this.detail.SetCOM_Date && this.detail.SetCOM_Date.trim() !== '')) return 2;
        return 1;
    },
    // 時間軸進度條百分比
    stepperProgress() {
        if (this.numericStatusCode === 3) return 100;
        if (this.numericStatusCode === 2) return 50;
        return 0;
    }
},
methods: {
    // 時間軸各節點樣式計算
    getStepClass(step) {
        if (this.numericStatusCode > step) return 'completed';
        if (this.numericStatusCode === step) return 'active';
        return '';
    }
}
```

### 5. 必備 CSS 樣式 Tokens
```css
/* 主容器佈局 */
.container-fluid-custom {
    max-width: 1560px;
    margin: 0 auto;
    padding: 16px;
}

/* 頂部導覽列按鈕 */
.nav-btn {
    background: rgba(255, 255, 255, 0.18);
    border: none; color: #ffffff;
    font-size: 0.92rem; font-weight: 600; cursor: pointer;
    height: 36px; border-radius: 8px;
    display: inline-flex; align-items: center; justify-content: center;
    padding: 0 14px; gap: 6px;
    transition: all 0.2s; text-decoration: none;
}
.nav-btn:hover { background-color: rgba(255, 255, 255, 0.32); color: #ffffff; text-decoration: none; }
.top-navbar .brand-title {
    font-size: 1.08rem; font-weight: 700; margin: 0;
    display: flex; align-items: center; gap: 8px;
}

/* 階段時間軸 (Status Stepper) */
.stepper-container {
    display: flex; align-items: center; justify-content: space-between;
    background: #ffffff; border-radius: 12px;
    padding: 16px 24px; margin-bottom: 16px;
    border: 1px solid var(--border-color); position: relative;
}
.step-item {
    display: flex; flex-direction: column; align-items: center;
    position: relative; z-index: 2; flex: 1;
}
.step-circle {
    width: 36px; height: 36px; border-radius: 50%;
    background: #e2e8f0; color: #64748b;
    display: flex; align-items: center; justify-content: center;
    font-weight: 700; font-size: 14px; margin-bottom: 6px;
    border: 3px solid #ffffff; box-shadow: 0 0 0 2px #cbd5e1;
    transition: all 0.3s;
}
.step-item.active .step-circle { background: var(--brand-blue); color: #ffffff; box-shadow: 0 0 0 2px var(--brand-blue); }
.step-item.completed .step-circle { background: #10b981; color: #ffffff; box-shadow: 0 0 0 2px #10b981; }
.step-title { font-size: 13px; font-weight: 700; color: #475569; margin-bottom: 2px; }
.step-item.active .step-title { color: var(--brand-blue); }
.step-item.completed .step-title { color: #047857; }
.step-time { font-size: 11px; color: #94a3b8; }

.stepper-line { position: absolute; top: 34px; left: 16%; right: 16%; height: 3px; background: #e2e8f0; z-index: 1; }
.stepper-line-fill { height: 100%; background: #10b981; transition: width 0.4s ease; }

/* 退回醒目警示 */
.alert-gback {
    background-color: #fef2f2; border: 1px solid #f87171;
    border-left: 6px solid #dc2626; border-radius: 8px;
    padding: 12px 16px; margin-bottom: 16px;
    color: #991b1b; font-size: 14px;
}
```

---

## 六、全站清單管理與至頂標頭標準規範 (List & Top Navbar Standard)

本標準適用於所有管制清單、任務清單與巡查成果列表（如 `FAC_List.aspx`、`Bare_List.aspx`、`CaseList.aspx`、`Clean_List.aspx`、`BSC_List.aspx`、`Break_List.aspx` 等）：

### 1. 置頂深青藍導覽列 (Sticky Top Navbar, 高度 56~60px)
- **左側固定導航**：
  - 清單頁面一律為「回首頁」或「回選單」：`<a href="../MainPage.aspx" class="nav-btn mr-2" title="返回主選單"><i class="fas fa-home"></i><span class="d-none d-sm-inline">回首頁</span></a>`。
  - 詳情/編輯頁面一律為「返回清單」：`<button type="button" class="nav-btn mr-2" v-on:click="goBack" title="返回清單"><i class="fas fa-arrow-left"></i><span class="d-none d-sm-inline">返回清單</span></button>`。
  - 模組標題與母體數據 Badge：`<a class="navbar-brand-title"><i class="fas fa-[icon] text-white"></i><span>模組標題</span><span class="badge badge-light text-dark font-weight-bold ml-1">{{ stats.Total }} 處</span></a>`。
- **右側功能動作**：
  - 主要動作（如「新增調查/場所」）：一律使用綠色 `<button class="btn btn-success btn-sm font-weight-bold shadow-sm mr-2"><i class="fas fa-plus-circle mr-1"></i>新增...</button>`。
  - 外勤特有功能（「附近場所」或「收合/展開地圖」）：使用白底或透明 `nav-btn`。

### 2. 複合多條件篩選卡片 (Card Modern - Filter)
- 點擊卡片標題列可直接折疊/展開，右側具備 `<i class="fas" :class="filterCollapsed ? 'fa-chevron-down' : 'fa-chevron-up'"></i>`。
- 底部狀態與操作列固定：
  - 左側顯示：`共查詢到 <strong class="text-primary">{{ totalCount }}</strong> 筆符合資料`。
  - 右側依序為：`[重設條件]`（`btn-outline-secondary btn-sm mr-2`，圖示 `fa-undo`）與 `[立即查詢]`（`btn-primary btn-sm px-3`，圖示 `fa-search`）。

### 3. 清單卡片標題列之「大四元標準工具列」
卡片 Header 右側統一配置標準工具組：
1. **重新整理**：`<button type="button" class="btn btn-sm btn-outline-secondary mr-2" v-on:click="fetchList" :disabled="loading"><i class="fas fa-sync-alt mr-1" :class="{ 'fa-spin': loading }"></i><span class="d-none d-md-inline">重新整理</span></button>`。
2. **匯出 EXCEL**：`<button type="button" class="btn btn-sm btn-outline-success font-weight-bold mr-2" v-on:click="exportExcel" :disabled="exporting || totalCount === 0"><i class="fas fa-file-excel mr-1"></i><span class="d-none d-md-inline">{{ exporting ? '匯出中...' : '匯出 EXCEL' }}</span></button>`。
3. **每頁筆數選擇器**：支援 10 / 15 / 30 / 50 筆切換。


### 4. 自適應現代化底部分頁列標準規範 (Responsive Pagination Footer Standard)

全專案所有資料清單頁面換頁導覽列**統一以 `FAC/FAC_List.aspx` 為唯一標準樣式**，徹底解決手機等小尺寸載具下多頁碼按鈕嚴重擠壓折行、跳動與觸控不易之問題。

#### (1) 設計原則與全載具互動特點
- **桌面端 (Desktop, $\ge 768\text{px}$)**：
  - 採左右兩端分列（`justify-content: space-between`）。
  - 左側：資料筆數資訊（`顯示第 X 至 Y 筆，共 Z 筆`）。
  - 右側：控制按鈕群（首頁、上一頁、頁碼膠囊、下一頁、末頁），首頁與末頁顯示文字與圖示。
- **手機行動端 (Mobile, $< 768\text{px}$)**：
  - 採垂直置中堆疊佈局（`flex-direction: column; align-items: center`）。
  - 上方：獨立置中顯示資料筆數資訊。
  - 下方：滿寬按鈕組（`width: 100%`）：
    - **首頁 / 末頁 (`.btn-edge`)**：隱藏文字（`d-none d-md-inline`），僅保留雙箭頭圖示（« 與 »），寬度固定 40px，精簡空間。
    - **上一頁 / 下一頁 (`.btn-step`)**：寬度設定為 `flex: 1` 自動撐滿剩餘空間，確保手指單手觸控熱區大於 42px。
    - **頁碼狀態膠囊 (`.page-indicator-pill`)**：置中淡綠底綠字圓角方塊（如 `1 / 13`），不隨點擊縮放變形，廢除傳統會造成手機折行的一長串數字頁碼按鈕。

#### (2) 標準 HTML / Vue 樣板
```html
<!-- 自適應底部分頁導覽列 (Responsive Pagination Footer) -->
<div v-if="!loading && totalCount > 0" class="pagination-footer">
    <div class="pagination-footer-info">
        顯示第 <strong class="text-dark">{{ (pageIndex - 1) * pageSize + 1 }}</strong> 至 
        <strong class="text-dark">{{ Math.min(pageIndex * pageSize, totalCount) }}</strong> 筆，共 
        <strong class="text-dark">{{ totalCount }}</strong> 筆
    </div>
    <div class="pagination-action-group">
        <button type="button" class="btn-page-ctrl btn-edge" :disabled="pageIndex <= 1" v-on:click="goToPage(1)" title="第一頁">
            <i class="fas fa-angle-double-left"></i>
            <span class="d-none d-md-inline ml-1">首頁</span>
        </button>
        <button type="button" class="btn-page-ctrl btn-step" :disabled="pageIndex <= 1" v-on:click="goToPage(pageIndex - 1)" title="上一頁">
            <i class="fas fa-chevron-left mr-1"></i>
            <span>上一頁</span>
        </button>
        <div class="page-indicator-pill" title="目前頁次 / 總頁數">
            <span>{{ pageIndex }}</span>
            <span class="mx-1 text-muted" style="opacity: 0.5; font-weight: normal;">/</span>
            <span>{{ totalPages }}</span>
        </div>
        <button type="button" class="btn-page-ctrl btn-step" :disabled="pageIndex >= totalPages" v-on:click="goToPage(pageIndex + 1)" title="下一頁">
            <span>下一頁</span>
            <i class="fas fa-chevron-right ml-1"></i>
        </button>
        <button type="button" class="btn-page-ctrl btn-edge" :disabled="pageIndex >= totalPages" v-on:click="goToPage(totalPages)" title="最後一頁">
            <span class="d-none d-md-inline ml-1">末頁</span>
            <i class="fas fa-angle-double-right"></i>
        </button>
    </div>
</div>
```

#### (3) 標準 CSS 樣式 Tokens
```css
/* 自適應現代化底部分頁列 (Responsive Pagination Footer) */
.pagination-footer {
    background: #ffffff;
    border-top: 1px solid #e2e8f0;
    padding: 12px 16px;
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 10px;
}
@media (min-width: 768px) {
    .pagination-footer {
        flex-direction: row;
        justify-content: space-between;
        align-items: center;
        padding: 12px 20px;
        gap: 16px;
    }
}

.pagination-footer-info {
    font-size: 0.88rem;
    color: #64748b;
    text-align: center;
    white-space: nowrap !important;
}
@media (min-width: 768px) {
    .pagination-footer-info {
        text-align: left;
    }
}

.pagination-action-group {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 6px;
    width: 100%;
    max-width: 100%;
}
@media (min-width: 768px) {
    .pagination-action-group {
        width: auto;
        justify-content: flex-end;
    }
}

.btn-page-ctrl {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    height: 38px;
    padding: 0 14px;
    font-size: 0.9rem;
    font-weight: 500;
    color: #334155;
    background: #ffffff;
    border: 1px solid #cbd5e1;
    border-radius: 8px;
    box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
    transition: all 0.15s ease-in-out;
    white-space: nowrap !important;
    text-decoration: none !important;
    user-select: none;
    touch-action: manipulation;
}
.btn-page-ctrl:hover:not(:disabled) {
    background: #f1f5f9;
    color: #0f172a;
    border-color: #94a3b8;
}
.btn-page-ctrl:active:not(:disabled) {
    background: #e2e8f0;
    transform: translateY(1px);
}
.btn-page-ctrl:disabled,
.btn-page-ctrl.disabled {
    background: #f8fafc;
    color: #94a3b8;
    border-color: #e2e8f0;
    cursor: not-allowed;
    opacity: 0.55;
    box-shadow: none;
}

/* 頁碼指示膠囊 */
.page-indicator-pill {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    height: 38px;
    padding: 0 12px;
    background: #f0fdf4;
    border: 1px solid #bbf7d0;
    border-radius: 8px;
    font-size: 0.88rem;
    font-weight: 700;
    color: #166534;
    white-space: nowrap !important;
}

/* 手機端大按鈕排版 (Mobile Touch Optimized) */
@media (max-width: 767.98px) {
    .btn-page-ctrl.btn-step {
        flex: 1;
        min-width: 0;
        padding: 0 8px;
    }
    .btn-page-ctrl.btn-edge {
        width: 40px;
        min-width: 40px;
        padding: 0;
        flex-shrink: 0;
    }
    .page-indicator-pill {
        flex-shrink: 0;
        padding: 0 10px;
        font-size: 0.84rem;
    }
}
```

---

## 七、專案鐵律自檢清單 (Checklist)

在任何新頁面發布或重構套用時，務必執行以下檢查：
1. [ ] **檔案編碼**：`.aspx`、`.aspx.cs` 必須存為 `UTF-8 with BOM`。
2. [ ] **Vue 語法限制**：禁止使用 `@click`、`@submit` 等，一律使用完整 `v-on:click`，容器須掛上 `v-cloak`。
3. [ ] **Vue 3 與 Leaflet 物件隔離 (防 project 崩潰)**：嚴禁將 Leaflet 實例宣告在 `data()` 響應式中，必須使用 `markRaw(instance)` 並指派給非響應式原生屬性。
4. [ ] **靜態資源本地化**：嚴禁外部 CDN，引用本地 `Scripts/vue.global.prod.js`、`Scripts/leaflet/leaflet.js`、`Content/leaflet/leaflet.css`。
5. [ ] **C# 5.0 語法合規**：嚴禁使用字串插值 `$"..."`、Null 條件運算子 `?.`、區域函式。
6. [ ] **清單頁大四元工具列齊備**：清單標題列必須包含「重新整理」、「匯出 EXCEL」與「每頁筆數選擇器」。
7. [ ] **全載具自適應分頁列**：清單換頁一律統一使用 `pagination-footer`、`pagination-action-group`、`btn-page-ctrl`、`page-indicator-pill`（以 `FAC/FAC_List.aspx` 為唯一標準），嚴禁手機端使用多數字折行按鈕。
8. [ ] **打包自檢**：執行 `python Scripts/deploy_pack.py` 確保冒煙驗證 100% 通過。

