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

## 五、專案鐵律自檢清單 (Checklist)

在新巡查頁面發布或套用時，務必執行以下檢查：
1. [ ] **檔案編碼**：`.aspx`、`.aspx.cs` 必須存為 `UTF-8 with BOM`。
2. [ ] **Vue 語法限制**：禁止使用 `@click`、`@submit` 等，一律使用完整 `v-on:click`，容器須掛上 `v-cloak`。
3. [ ] **Vue 3 與 Leaflet 物件隔離 (防 project 崩潰)**：嚴禁將 Leaflet 實例（`map`、`tileLayer`、`marker`）宣告在 `data()` 響應式中，必須使用 `markRaw(instance)` 並指派給非響應式原生屬性（如 `this.leafletMap`），以避免觸發 `Uncaught TypeError: Cannot read properties of null (reading 'project')`。
4. [ ] **靜態資源本地化**：嚴禁外部 CDN，引用本地 `Scripts/vue.global.prod.js`、`Scripts/leaflet/leaflet.js`、`Content/leaflet/leaflet.css`。
5. [ ] **C# 5.0 語法合規**：嚴禁使用字串插值 `$"..."`、Null 條件運算子 `?.`、區域函式。
6. [ ] **打包自檢**：執行 `python Scripts/deploy_pack.py` 確保冒煙驗證 100% 通過。
