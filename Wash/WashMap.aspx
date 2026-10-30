<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="WashMap.aspx.cs" Inherits="NTPC_FEC.Wash.WashMap" %>

<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定逸散源管理平台 - 道路洗掃路段與現場查核空間地圖</title>

    <!-- 專屬 Favicon -->
    <link rel="shortcut icon" href="../favicon.ico" type="image/x-icon" />

    <!-- 本地化核心樣式庫 (嚴守無外部 CDN 資安規範) -->
    <link rel="stylesheet" href="../Content/bootstrap.min.css" />
    <link rel="stylesheet" href="../Content/fontawesome/css/all.min.css" />
    <link rel="stylesheet" href="../Content/leaflet/leaflet.css" />

    <style>
        :root {
            --brand-primary: #0099e5;
            --brand-blue: #0284c7;
            --brand-dark-blue: #0b1f7d;
            --brand-navy: #0f172a;
            --bg-canvas: #f1f5f9;
            --surface: #ffffff;
            --border-color: #e2e8f0;
            --text-main: #0f172a;
            --text-muted: #64748b;
        }

        * { box-sizing: border-box; -webkit-tap-highlight-color: transparent; }
        html, body { height: 100%; width: 100%; margin: 0; padding: 0; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, "Noto Sans TC", "微軟正黑體", sans-serif;
            background-color: var(--bg-canvas);
            color: var(--text-main);
            overflow: hidden;
        }
        [v-cloak] { display: none !important; }

        /* 頂部導覽列 (符合 inspection-ui-standard 規範) */
        .top-navbar {
            background: linear-gradient(135deg, #0099e5 0%, #0284c7 100%);
            color: #ffffff;
            height: 56px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 0 14px;
            box-shadow: 0 2px 10px rgba(0, 153, 229, 0.25);
            position: relative;
            z-index: 1020;
        }
        .top-navbar .brand-title {
            font-size: 1.05rem;
            font-weight: 700;
            letter-spacing: 0.3px;
            margin: 0;
            display: flex;
            align-items: center;
            color: #ffffff;
            min-width: 0;
        }
        .nav-btn {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            height: 34px;
            padding: 0 12px;
            border-radius: 8px;
            background: rgba(255, 255, 255, 0.2);
            color: #ffffff !important;
            font-size: 0.85rem;
            font-weight: 600;
            text-decoration: none !important;
            border: 1px solid rgba(255, 255, 255, 0.35);
            transition: all 0.2s ease;
            white-space: nowrap;
            cursor: pointer;
            flex: none;
        }
        .nav-btn:hover {
            background: rgba(255, 255, 255, 0.32);
            transform: translateY(-1px);
        }
        .nav-btn-amber {
            background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
            border-color: #fbbf24;
            box-shadow: 0 2px 6px rgba(217, 119, 6, 0.35);
        }
        .nav-btn-amber:hover {
            background: linear-gradient(135deg, #fbbf24 0%, #b45309 100%);
        }

        /* 雙欄主體佈局 */
        .app-layout {
            display: flex;
            height: calc(100vh - 56px);
            width: 100vw;
            overflow: hidden;
            position: relative;
        }
        .side-panel {
            width: 440px;
            flex: none;
            background: var(--bg-canvas);
            border-right: 1px solid var(--border-color);
            overflow: hidden;
            padding: 10px 12px;
            z-index: 20;
            display: flex;
            flex-direction: column;
            gap: 10px;
            height: 100%;
        }
        .map-wrapper {
            flex: 1;
            position: relative;
            min-width: 0;
            height: 100%;
        }
        #map {
            width: 100%;
            height: 100%;
            z-index: 10;
            background: #dde6ef;
        }

        /* 現代卡片 */
        .card-modern {
            background: var(--surface);
            border-radius: 12px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05), 0 4px 12px rgba(15, 23, 42, 0.04);
            border: 1px solid var(--border-color);
            overflow: hidden;
            flex: none;
        }
        .card-modern-header {
            padding: 8px 12px;
            border-bottom: 1px solid var(--border-color);
            display: flex;
            align-items: center;
            justify-content: space-between;
            background: #ffffff;
        }
        .card-modern-title {
            font-size: 0.9rem;
            font-weight: 700;
            color: var(--brand-navy);
            margin: 0;
            display: flex;
            align-items: center;
            gap: 6px;
        }
        .card-modern-body {
            padding: 10px 12px;
        }

        /* KPI 統計指標列 */
        .stat-grid {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 6px;
        }
        .stat-chip {
            background: #f8fafc;
            border: 1px solid var(--border-color);
            border-radius: 8px;
            padding: 6px 4px;
            text-align: center;
            transition: all 0.15s ease;
            cursor: pointer;
            user-select: none;
        }
        .stat-chip:hover {
            transform: translateY(-1px);
            border-color: var(--brand-blue);
            box-shadow: 0 2px 6px rgba(2, 132, 199, 0.12);
        }
        .stat-chip.active-stat {
            background: #eff6ff;
            border-color: #0284c7;
            box-shadow: inset 0 0 0 1px #0284c7;
        }
        .stat-chip .stat-val {
            font-size: 1.05rem;
            font-weight: 800;
            line-height: 1.15;
        }
        .stat-chip .stat-lbl {
            font-size: 0.68rem;
            color: var(--text-muted);
            margin-top: 2px;
            white-space: nowrap;
        }

        /* 篩選晶片樣式 */
        .filter-sec-label {
            font-size: 0.72rem;
            font-weight: 700;
            color: #475569;
            margin-bottom: 4px;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }
        .chip-group {
            display: flex;
            gap: 5px;
            flex-wrap: wrap;
        }
        .chip-btn {
            border: 1px solid #cbd5e1;
            background: #ffffff;
            color: #334155;
            padding: 3px 9px;
            border-radius: 16px;
            font-size: 0.75rem;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.15s ease;
            display: inline-flex;
            align-items: center;
            gap: 4px;
            user-select: none;
        }
        .chip-btn:hover {
            border-color: var(--brand-blue);
            color: var(--brand-blue);
        }
        .chip-btn.active {
            background: var(--brand-blue);
            border-color: var(--brand-blue);
            color: #ffffff;
        }
        .chip-btn .dot {
            width: 8px;
            height: 8px;
            border-radius: 50%;
            display: inline-block;
        }

        /* 進階篩選滾動盒 */
        .adv-filter-box {
            max-height: 215px;
            overflow-y: auto;
            padding-right: 2px;
        }

        /* 清單容器 (彈性撐滿剩餘高度) */
        .result-card-container {
            flex: 1;
            display: flex;
            flex-direction: column;
            min-height: 0;
            background: var(--surface);
            border-radius: 12px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05), 0 4px 12px rgba(15, 23, 42, 0.04);
            border: 1px solid var(--border-color);
            overflow: hidden;
        }
        .result-tabs {
            display: flex;
            border-bottom: 1px solid var(--border-color);
            background: #f8fafc;
            flex: none;
        }
        .result-tab-btn {
            flex: 1;
            text-align: center;
            padding: 8px 6px;
            font-size: 0.82rem;
            font-weight: 700;
            color: #64748b;
            cursor: pointer;
            border-bottom: 2.5px solid transparent;
            transition: all 0.15s ease;
            user-select: none;
        }
        .result-tab-btn:hover {
            color: var(--brand-blue);
            background: #ffffff;
        }
        .result-tab-btn.active {
            color: var(--brand-blue);
            border-bottom-color: var(--brand-blue);
            background: #ffffff;
        }
        .result-toolbar {
            padding: 6px 12px;
            border-bottom: 1px solid #f1f5f9;
            background: #ffffff;
            display: flex;
            align-items: center;
            justify-content: space-between;
            font-size: 0.76rem;
            color: #64748b;
            flex: none;
        }
        .result-card-body {
            flex: 1;
            overflow-y: auto;
            padding: 8px 10px;
            min-height: 0;
        }

        /* 工廠與路段卡片 */
        .wash-item-card {
            border: 1px solid var(--border-color);
            border-radius: 9px;
            padding: 9px 11px;
            margin-bottom: 7px;
            background: #ffffff;
            cursor: pointer;
            transition: all 0.15s ease;
            position: relative;
        }
        .wash-item-card:hover {
            border-color: #38bdf8;
            background: #f0f9ff;
            transform: translateY(-1px);
            box-shadow: 0 3px 8px rgba(2, 132, 199, 0.1);
        }
        .wash-item-card.selected {
            border-color: #0284c7;
            background: #e0f2fe;
            box-shadow: inset 0 0 0 1px #0284c7;
        }
        .wash-item-card.cat-A {
            border-left: 4px solid #2563eb;
        }
        .wash-item-card.cat-B {
            border-left: 4px solid #f97316;
        }
        .wash-item-card.cat-C {
            border-left: 4px solid #94a3b8;
        }

        /* 標籤徽章 */
        .w-tag {
            display: inline-flex;
            align-items: center;
            padding: 1px 6px;
            border-radius: 4px;
            font-size: 0.69rem;
            font-weight: 700;
            margin-right: 4px;
            margin-top: 2px;
        }
        .w-tag-blue { background: #dbeafe; color: #1d4ed8; }
        .w-tag-amber { background: #fef3c7; color: #b45309; }
        .w-tag-green { background: #dcfce7; color: #15803d; }
        .w-tag-red { background: #fee2e2; color: #b91c1c; }
        .w-tag-purple { background: #ede9fe; color: #6d28d9; }
        .w-tag-gray { background: #f1f5f9; color: #475569; }

        /* 地圖右上狀態膠囊與左下圖例 */
        .map-status-pill {
            position: absolute;
            top: 12px;
            left: 56px;
            z-index: 500;
            background: rgba(15, 23, 42, 0.86);
            color: #ffffff;
            padding: 6px 14px;
            border-radius: 20px;
            font-size: 0.8rem;
            font-weight: 600;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
            pointer-events: none;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .map-legend-box {
            position: absolute;
            bottom: 24px;
            left: 14px;
            z-index: 500;
            background: rgba(255, 255, 255, 0.96);
            border: 1px solid #cbd5e1;
            border-radius: 10px;
            padding: 10px 12px;
            font-size: 0.74rem;
            box-shadow: 0 4px 14px rgba(15, 23, 42, 0.14);
            max-width: 245px;
        }
        .legend-row {
            display: flex;
            align-items: center;
            gap: 7px;
            margin: 3px 0;
            color: #334155;
        }
        .legend-line {
            width: 22px;
            height: 0;
            border-top: 4px solid #2563eb;
            display: inline-block;
        }
        .legend-line.dashed {
            border-top-style: dashed;
        }

        /* 放大時路名常駐標籤 */
        .leaflet-tooltip.road-lbl {
            background: rgba(30, 58, 138, 0.9);
            color: #ffffff;
            border: none;
            border-radius: 4px;
            padding: 1px 6px;
            font-size: 11px;
            font-weight: 700;
            box-shadow: 0 1px 4px rgba(0,0,0,0.3);
            white-space: nowrap;
        }
        .leaflet-tooltip.road-lbl.est {
            background: rgba(180, 83, 9, 0.9);
        }
        .leaflet-tooltip.road-lbl::before {
            display: none;
        }

        /* Popup 內部表格與每月里程長條圖 */
        .pop-wrap {
            font-size: 12px;
            line-height: 1.45;
            min-width: 290px;
            max-width: 360px;
            color: #1e293b;
        }
        .pop-title {
            font-size: 14px;
            font-weight: 800;
            color: #0f172a;
            margin-bottom: 4px;
            border-bottom: 2px solid #e2e8f0;
            padding-bottom: 4px;
        }
        .pop-tbl {
            width: 100%;
            border-collapse: collapse;
            margin-top: 4px;
        }
        .pop-tbl td {
            padding: 2px 4px;
            border-bottom: 1px solid #f1f5f9;
            vertical-align: top;
        }
        .pop-tbl td.k {
            color: #64748b;
            white-space: nowrap;
            width: 72px;
            font-weight: 600;
        }
        .bars-box {
            display: grid;
            grid-auto-flow: column;
            grid-auto-columns: 1fr;
            gap: 3px;
            margin-top: 6px;
            align-items: end;
            height: 60px;
            padding: 4px 4px 16px;
            background: #f8fafc;
            border-radius: 6px;
            border: 1px solid #e2e8f0;
        }
        .bar-col {
            display: flex;
            flex-direction: column;
            justify-content: flex-end;
            height: 100%;
            position: relative;
            align-items: stretch;
        }
        .bar-w {
            background: #2563eb;
            border-radius: 2px 2px 0 0;
        }
        .bar-s {
            background: #d97706;
        }
        .bar-col span {
            position: absolute;
            bottom: -14px;
            left: 0;
            right: 0;
            text-align: center;
            font-size: 9px;
            color: #64748b;
            font-weight: 600;
        }
        .aud-tbl {
            width: 100%;
            border-collapse: collapse;
            margin-top: 4px;
            font-size: 11px;
        }
        .aud-tbl th, .aud-tbl td {
            border: 1px solid #e2e8f0;
            padding: 2px 4px;
            text-align: center;
        }
        .aud-tbl th {
            background: #f1f5f9;
            color: #475569;
            font-weight: 700;
        }

        /* 遮罩彈窗 (Excel 更新精靈與資料說明) */
        .custom-modal-overlay {
            position: fixed;
            inset: 0;
            background: rgba(15, 23, 42, 0.6);
            backdrop-filter: blur(3px);
            z-index: 2000;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 16px;
        }
        .custom-modal-card {
            background: #ffffff;
            border-radius: 14px;
            max-width: 680px;
            width: 100%;
            max-height: 88vh;
            display: flex;
            flex-direction: column;
            box-shadow: 0 20px 50px rgba(0, 0, 0, 0.3);
            overflow: hidden;
        }
        .custom-modal-header {
            padding: 14px 18px;
            background: linear-gradient(135deg, #0099e5 0%, #0284c7 100%);
            color: #ffffff;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }
        .custom-modal-body {
            padding: 18px;
            overflow-y: auto;
            font-size: 0.88rem;
            line-height: 1.6;
        }
        .custom-modal-footer {
            padding: 12px 18px;
            border-top: 1px solid var(--border-color);
            background: #f8fafc;
            display: flex;
            justify-content: flex-end;
            gap: 8px;
        }
        .upload-dropzone {
            border: 2px dashed #38bdf8;
            background: #f0f9ff;
            border-radius: 12px;
            padding: 24px 16px;
            text-align: center;
            cursor: pointer;
            transition: all 0.2s ease;
        }
        .upload-dropzone:hover, .upload-dropzone.dragover {
            background: #e0f2fe;
            border-color: #0284c7;
        }

        /* 手機版響應式切換按鈕 */
        .mobile-view-toggle {
            display: none;
            position: fixed;
            bottom: 18px;
            left: 50%;
            transform: translateX(-50%);
            z-index: 1050;
            background: #0f172a;
            color: #ffffff;
            border-radius: 28px;
            padding: 4px;
            box-shadow: 0 6px 20px rgba(0, 0, 0, 0.35);
            border: 1px solid rgba(255, 255, 255, 0.2);
        }
        .mobile-toggle-btn {
            border: none;
            background: transparent;
            color: #cbd5e1;
            padding: 7px 16px;
            border-radius: 24px;
            font-size: 0.82rem;
            font-weight: 700;
        }
        .mobile-toggle-btn.active {
            background: #0284c7;
            color: #ffffff;
        }

        @media (max-width: 767.98px) {
            .top-navbar .brand-subtitle-badge { display: none !important; }
            .side-panel {
                width: 100%;
                position: absolute;
                inset: 0;
                z-index: 30;
                overflow-y: auto;
            }
            .side-panel.mobile-hidden {
                display: none !important;
            }
            .mobile-view-toggle {
                display: inline-flex;
            }
            .map-status-pill {
                left: 12px;
                right: 12px;
                font-size: 0.74rem;
            }
        }
    </style>
</head>
<body>
    <form id="form1" runat="server" onsubmit="return false;">
        <div id="washMapApp" v-cloak>
            <!-- 頂部導覽列 -->
            <header class="top-navbar">
                <div class="d-flex align-items-center" style="gap: 10px; min-width: 0;">
                    <a href="../MainPage.aspx" class="nav-btn" title="返回系統主控儀表板">
                        <i class="fas fa-arrow-left mr-1"></i> 返回主頁
                    </a>
                    <h1 class="brand-title text-truncate">
                        <i class="fas fa-road mr-2"></i>
                        <span class="text-truncate">新北市列管逸散工廠 — 道路洗掃路段與現場查核地圖</span>
                        <span class="badge badge-light ml-2 brand-subtitle-badge" style="font-size: 0.75rem; color: #0284c7;">
                            115年 1–{{ nm }}月
                        </span>
                    </h1>
                </div>

                <div class="d-flex align-items-center" style="gap: 8px;">
                    <button type="button" class="nav-btn nav-btn-amber" v-on:click="openUploadModal" title="匯入最新月份道路洗掃抽查統計表或洗掃日誌 Excel">
                        <i class="fas fa-file-excel mr-1"></i>
                        <span>數據更新 <span class="d-none d-md-inline">(匯入Excel)</span></span>
                    </button>
                    <button type="button" class="nav-btn" v-on:click="exportCsv" title="將目前篩選清單匯出為 CSV 報表">
                        <i class="fas fa-download mr-1"></i>
                        <span class="d-none d-sm-inline">匯出 CSV</span>
                    </button>
                    <button type="button" class="nav-btn" v-on:click="showInfoModal = true" title="檢視資料來源與更新說明">
                        <i class="fas fa-info-circle mr-1"></i>
                        <span class="d-none d-lg-inline">資料說明</span>
                    </button>
                </div>
            </header>

            <!-- 雙欄主體容器 -->
            <div class="app-layout">
                <!-- 左側控制與清單面板 -->
                <aside class="side-panel" :class="{ 'mobile-hidden': mobileView === 'map' }">

                    <!-- 1. KPI 即時統計卡片 -->
                    <div class="card-modern">
                        <div class="card-modern-body" style="padding: 8px 10px;">
                            <div class="stat-grid">
                                <div class="stat-chip" :class="{ 'active-stat': isDefaultCatFilter }" v-on:click="resetQuickStatFilter" title="點擊顯示全部符合條件工廠">
                                    <div class="stat-val text-primary">{{ filteredFactories.length }}</div>
                                    <div class="stat-lbl">顯示工廠 (總{{ allFactories.length }})</div>
                                </div>
                                <div class="stat-chip" :class="{ 'active-stat': isOnlyCatA }" v-on:click="toggleOnlyCatA" title="點擊快速篩選：有洗掃紀錄 (A類)">
                                    <div class="stat-val" style="color: #2563eb;">{{ countCatA }}</div>
                                    <div class="stat-lbl">有洗掃紀錄(A)</div>
                                </div>
                                <div class="stat-chip" :class="{ 'active-stat': filters.hiOnly }" v-on:click="toggleHiOnly" title="點擊切換：只看高風險逸散行業">
                                    <div class="stat-val text-danger">{{ countHighRisk }}</div>
                                    <div class="stat-lbl">高風險行業</div>
                                </div>
                                <div class="stat-chip" v-on:click="switchSortToKm" title="1~NM月累計洗掃總里程 / 認養道路總長">
                                    <div class="stat-val text-success">{{ totalWashKm }}</div>
                                    <div class="stat-lbl">累計洗掃(km)</div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- 2. 搜尋與複合篩選卡片 -->
                    <div class="card-modern">
                        <div class="card-modern-header">
                            <h2 class="card-modern-title">
                                <i class="fas fa-filter text-primary"></i>
                                <span>空間篩選與圖層控制</span>
                            </h2>
                            <div class="d-flex align-items-center" style="gap: 6px;">
                                <button type="button" class="btn btn-sm btn-outline-secondary py-0 px-2" style="font-size: 0.74rem;" v-on:click="resetFilters">
                                    <i class="fas fa-undo mr-1"></i>重置
                                </button>
                                <button type="button" class="btn btn-sm btn-light py-0 px-2 border" style="font-size: 0.74rem;" v-on:click="showAdvFilters = !showAdvFilters">
                                    <i class="fas" :class="showAdvFilters ? 'fa-chevron-up' : 'fa-chevron-down'"></i>
                                    {{ showAdvFilters ? '收合條件' : '展開條件' }}
                                </button>
                            </div>
                        </div>

                        <div class="card-modern-body">
                            <!-- 行政區 + 關鍵字搜尋 -->
                            <div class="d-flex" style="gap: 6px; margin-bottom: 8px;">
                                <select class="form-control form-control-sm" style="width: 138px; flex: none; font-weight: 600;" v-model="filters.dist" v-on:change="onDistChange">
                                    <option value="">全部行政區</option>
                                    <option v-for="d in districtOptions" :key="d.name" :value="d.name">
                                        {{ d.name }} ({{ d.count }})
                                    </option>
                                </select>
                                <div class=" position-relative flex-grow-1">
                                    <input type="text" class="form-control form-control-sm" placeholder="搜尋廠名 / 管編 / 認養路名 / 地址..." v-model.trim="filters.keyword" />
                                </div>
                            </div>

                            <!-- 洗掃狀態 A / B / C 常駐切換晶片 -->
                            <div class="chip-group">
                                <span class="chip-btn" :class="{ active: filters.cats.A }" v-on:click="toggleCat('A')" title="115年1–NM月有洗街或掃街里程紀錄">
                                    <span class="dot" style="background: #2563eb;"></span>
                                    有洗掃紀錄 ({{ totalCatCounts.A }})
                                </span>
                                <span class="chip-btn" :class="{ active: filters.cats.B }" v-on:click="toggleCat('B')" title="列入洗掃名單或推動名單但目前無里程">
                                    <span class="dot" style="background: #f97316;"></span>
                                    列入無紀錄 ({{ totalCatCounts.B }})
                                </span>
                                <span class="chip-btn" :class="{ active: filters.cats.C }" v-on:click="toggleCat('C')" title="183家列管工廠但未列入道路洗掃">
                                    <span class="dot" style="background: #94a3b8;"></span>
                                    其他列管 ({{ totalCatCounts.C }})
                                </span>
                            </div>

                            <!-- 展開之進階篩選區 -->
                            <div v-show="showAdvFilters" class="adv-filter-box mt-2 pt-2 border-top">
                                <!-- 洗掃級別與髒污分級 -->
                                <div class="mb-2">
                                    <div class="filter-sec-label">
                                        <span>認養級別 / 現場查核髒污分級 / 方式</span>
                                    </div>
                                    <div class="chip-group">
                                        <span class="chip-btn" :class="{ active: filters.lv === '第一級' }" v-on:click="toggleSingleFilter('lv', '第一級')">第一級</span>
                                        <span class="chip-btn" :class="{ active: filters.lv === '第二級' }" v-on:click="toggleSingleFilter('lv', '第二級')">第二級</span>
                                        <span class="chip-btn" :class="{ active: filters.lv === '第三級' }" v-on:click="toggleSingleFilter('lv', '第三級')">第三級</span>
                                        <span class="chip-btn" :class="{ active: filters.dirt === 'A' }" v-on:click="toggleSingleFilter('dirt', 'A')">髒污 A 級</span>
                                        <span class="chip-btn" :class="{ active: filters.dirt === 'B' }" v-on:click="toggleSingleFilter('dirt', 'B')">髒污 B 級</span>
                                        <span class="chip-btn" :class="{ active: filters.how === '洗掃並行' }" v-on:click="toggleSingleFilter('how', '洗掃並行')">洗掃並行</span>
                                        <span class="chip-btn" :class="{ active: filters.how === '洗街' }" v-on:click="toggleSingleFilter('how', '洗街')">純洗街</span>
                                        <span class="chip-btn" :class="{ active: filters.how === '掃街' }" v-on:click="toggleSingleFilter('how', '掃街')">純掃街</span>
                                    </div>
                                </div>

                                <!-- 行業群組 -->
                                <div class="mb-2">
                                    <div class="filter-sec-label">
                                        <span>逸散行業群組 (前4項為高風險)</span>
                                        <div>
                                            <a href="javascript:void(0)" class="mr-2" v-on:click="setAllGroups(true)">全選</a>
                                            <a href="javascript:void(0)" v-on:click="setAllGroups(false)">全不選</a>
                                        </div>
                                    </div>
                                    <div class="chip-group">
                                        <span v-for="g in groupDefs" :key="g.name"
                                              class="chip-btn"
                                              :class="{ active: filters.groups[g.name] }"
                                              v-on:click="toggleGroup(g.name)">
                                            <span class="dot" :style="{ background: g.color }"></span>
                                            {{ g.name }} ({{ g.count }})
                                        </span>
                                    </div>
                                </div>

                                <!-- 圖層開關與清冊來源 -->
                                <div>
                                    <div class="filter-sec-label">
                                        <span>空間圖層與列管清冊</span>
                                    </div>
                                    <div class="chip-group">
                                        <span class="chip-btn" :class="{ active: layers.showRoads }" v-on:click="toggleRoadLayer">
                                            <i class="fas fa-route"></i> 顯示洗掃路段線條
                                        </span>
                                        <span class="chip-btn" :class="{ active: layers.showRoadLabels }" v-on:click="toggleRoadLabelLayer">
                                            <i class="fas fa-tag"></i> 放大顯示路名(Z≥16)
                                        </span>
                                        <span class="chip-btn" :class="{ active: filters.listSrc.in183 }" v-on:click="filters.listSrc.in183 = !filters.listSrc.in183">
                                            183家列管清冊
                                        </span>
                                        <span class="chip-btn" :class="{ active: filters.listSrc.non183 }" v-on:click="filters.listSrc.non183 = !filters.listSrc.non183">
                                            非清冊(僅在洗掃表)
                                        </span>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- 3. 結果清單容器 (工廠 / 認養路段雙頁籤) -->
                    <div class="result-card-container">
                        <div class="result-tabs">
                            <div class="result-tab-btn" :class="{ active: activeTab === 'fac' }" v-on:click="activeTab = 'fac'">
                                <i class="fas fa-industry mr-1"></i>工廠清單 ({{ filteredFactories.length }})
                            </div>
                            <div class="result-tab-btn" :class="{ active: activeTab === 'road' }" v-on:click="activeTab = 'road'">
                                <i class="fas fa-road mr-1"></i>認養路段 ({{ groupedRoads.length }})
                            </div>
                        </div>

                        <!-- 工廠頁籤排序列 -->
                        <div v-if="activeTab === 'fac'" class="result-toolbar">
                            <span>共 <strong>{{ filteredFactories.length }}</strong> 家工廠，認養路長 <strong>{{ totalRoadLineKm }}</strong> km</span>
                            <div class="d-flex align-items-center" style="gap: 4px;">
                                <span>排序：</span>
                                <select class="form-control form-control-sm py-0 px-1" style="height: 24px; font-size: 0.75rem; width: auto;" v-model="sortBy">
                                    <option value="km">累計洗掃里程 ↓</option>
                                    <option value="roadlen">認養路段長度 ↓</option>
                                    <option value="audit">最近抽查日期 ↓</option>
                                    <option value="id">管制編號 ↑</option>
                                </select>
                            </div>
                        </div>

                        <!-- 路段頁籤說明列 -->
                        <div v-else class="result-toolbar">
                            <span>依行政區與道路聚合共 <strong>{{ groupedRoads.length }}</strong> 條洗掃路段</span>
                            <span class="text-primary font-weight-bold">實線=具名 / 虛線=推估</span>
                        </div>

                        <!-- 清單滾動主體 -->
                        <div class="result-card-body">
                            <!-- 頁籤 1：工廠列表 -->
                            <template v-if="activeTab === 'fac'">
                                <div v-if="sortedFactories.length === 0" class="text-center text-muted py-5">
                                    <i class="fas fa-search fa-2x mb-2 d-block opacity-50"></i>
                                    沒有符合篩選條件的工廠，請調整篩選晶片或關鍵字
                                </div>
                                <div v-for="f in sortedFactories" :key="f.id"
                                     class="wash-item-card"
                                     :class="['cat-' + f._cat, { selected: selectedFacId === f.id }]"
                                     v-on:click="focusFactory(f)">
                                    <div class="d-flex justify-content-between align-items-start" style="gap: 6px;">
                                        <div class="font-weight-bold text-dark" style="font-size: 0.86rem; line-height: 1.3;">
                                            <span class="d-inline-block rounded-circle mr-1" :style="{ width: '9px', height: '9px', background: getGroupColor(f.grp) }"></span>
                                            {{ f.n }}
                                        </div>
                                        <span v-if="f._tot > 0" class="badge badge-primary" style="font-size: 0.72rem; flex: none;">
                                            {{ f._tot.toFixed(1) }} km
                                        </span>
                                        <span v-else-if="f._cat === 'B'" class="badge badge-warning text-white" style="font-size: 0.7rem; flex: none; background:#f97316;">
                                            無里程紀錄
                                        </span>
                                        <span v-else class="badge badge-secondary" style="font-size: 0.7rem; flex: none;">
                                            未列洗掃
                                        </span>
                                    </div>

                                    <div class="text-muted mt-1" style="font-size: 0.74rem;">
                                        <span class="font-weight-bold text-secondary">{{ f.id }}</span>
                                        · {{ f.d || '未填區' }}
                                        · {{ f.grp }}
                                    </div>

                                    <!-- 標籤列 -->
                                    <div class="mt-1">
                                        <span v-if="f.hi" class="w-tag w-tag-red">高風險</span>
                                        <span v-if="f.info && f.info.lv" class="w-tag w-tag-purple">{{ f.info.lv }}</span>
                                        <span v-if="f.info && f.info.dirt" class="w-tag" :class="f.info.dirt === 'A' ? 'w-tag-green' : 'w-tag-amber'">
                                            髒污{{ f.info.dirt }}級
                                        </span>
                                        <span v-if="f.info && f.info.how" class="w-tag w-tag-blue">{{ f.info.how }}</span>
                                        <span v-if="f.info && f.info.freq" class="w-tag w-tag-gray">{{ f.info.freq }}</span>
                                        <span v-if="f._latestAud" class="w-tag" :class="f._latestAud.ok === '是' ? 'w-tag-green' : (f._latestAud.ok === '否' ? 'w-tag-red' : 'w-tag-gray')">
                                            {{ f._latestAud.m }}:{{ f._latestAud.ok || '未抽查' }}
                                        </span>
                                    </div>

                                    <!-- 路段資訊列 -->
                                    <div v-if="f.g && f.g.mode !== 'none'" class="mt-1 pt-1 border-top d-flex justify-content-between align-items-center" style="font-size: 0.73rem;">
                                        <span :style="{ color: f.g.mode === 'name' ? '#1d4ed8' : '#b45309', fontWeight: 600 }">
                                            <i class="fas fa-road mr-1"></i>
                                            {{ f.g.mode === 'name' ? f.g.name : ('推估：' + (f.g.name || '周邊道路')) }}
                                        </span>
                                        <span class="text-muted">{{ f.g.L }} km</span>
                                    </div>
                                </div>
                            </template>

                            <!-- 頁籤 2：認養路段列表 -->
                            <template v-else>
                                <div v-if="groupedRoads.length === 0" class="text-center text-muted py-5">
                                    <i class="fas fa-road fa-2x mb-2 d-block opacity-50"></i>
                                    目前篩選範圍內無道路幾何資料
                                </div>
                                <div v-for="rd in groupedRoads" :key="rd.key"
                                     class="wash-item-card"
                                     :style="{ borderLeft: '4px solid ' + (rd.mode === 'name' ? '#2563eb' : '#d97706') }"
                                     v-on:click="focusRoadGroup(rd)">
                                    <div class="d-flex justify-content-between align-items-start">
                                        <div class="font-weight-bold" style="font-size: 0.86rem; color: #0f172a;">
                                            <i class="fas fa-map-signs mr-1" :class="rd.mode === 'name' ? 'text-primary' : 'text-warning'"></i>
                                            {{ rd.dist }} · {{ rd.name }}
                                        </div>
                                        <span class="badge" :class="rd.mode === 'name' ? 'badge-primary' : 'badge-warning text-white'" style="font-size: 0.72rem;">
                                            {{ rd.totalKm.toFixed(2) }} km
                                        </span>
                                    </div>
                                    <div class="mt-1">
                                        <span class="w-tag" :class="rd.mode === 'name' ? 'w-tag-blue' : 'w-tag-amber'">
                                            {{ rd.mode === 'name' ? '工廠申報具體路名 (實線)' : '系統推估最近主幹道 (虛線)' }}
                                        </span>
                                        <span class="w-tag w-tag-gray">{{ rd.facs.length }} 家認養廠</span>
                                    </div>
                                    <div class="text-muted mt-1" style="font-size: 0.73rem;">
                                        認養工廠：{{ rd.facNamesText }}
                                    </div>
                                </div>
                            </template>
                        </div>
                    </div>
                </aside>

                <!-- 右側 Leaflet 地圖區 -->
                <main class="map-wrapper">
                    <div id="map"></div>

                    <!-- 地圖左上狀態膠囊 -->
                    <div class="map-status-pill">
                        <i class="fas fa-satellite-dish text-info"></i>
                        <span>
                            顯示 <strong>{{ filteredFactories.length }}</strong> 廠 · 有洗掃 <strong>{{ countCatA }}</strong> 廠 · 累計 <strong>{{ totalWashKm }}</strong> km
                            <span v-if="updatedAt" class="ml-1 opacity-75">(更新: {{ updatedAt }})</span>
                        </span>
                    </div>

                    <!-- 左下浮動圖例 -->
                    <div class="map-legend-box">
                        <div class="d-flex justify-content-between align-items-center mb-1">
                            <strong style="font-size: 0.78rem; color: #0f172a;">
                                <i class="fas fa-layer-group text-primary mr-1"></i>洗掃路段與工廠圖例
                            </strong>
                            <a href="javascript:void(0)" class="text-muted" style="font-size: 0.7rem;" v-on:click="legendCollapsed = !legendCollapsed">
                                {{ legendCollapsed ? '展開' : '收合' }}
                            </a>
                        </div>
                        <div v-show="!legendCollapsed">
                            <div class="legend-row">
                                <span class="legend-line" style="border-top-color: #2563eb;"></span>
                                <span>有洗掃紀錄 · 申報路名 (實線)</span>
                            </div>
                            <div class="legend-row">
                                <span class="legend-line dashed" style="border-top-color: #3b82f6;"></span>
                                <span>有洗掃紀錄 · 推估道路 (虛線)</span>
                            </div>
                            <div class="legend-row">
                                <span class="legend-line dashed" style="border-top-color: #f97316;"></span>
                                <span>列入洗掃但無里程紀錄</span>
                            </div>
                            <div class="legend-row mt-1 pt-1 border-top">
                                <span class="d-inline-block rounded-circle" style="width:11px;height:11px;background:#2563eb;border:2px solid #f59e0b;"></span>
                                <span>有洗掃紀錄工廠 (橘外環)</span>
                            </div>
                            <div class="legend-row">
                                <span class="d-inline-block rounded-circle" style="width:10px;height:10px;background:#64748b;border:1.5px solid #ffffff;box-shadow:0 0 2px #000;"></span>
                                <span>一般列管工廠 (圓點為行業色)</span>
                            </div>
                        </div>
                    </div>
                </main>
            </div>

            <!-- 手機版底部視角切換膠囊 -->
            <div class="mobile-view-toggle">
                <button type="button" class="mobile-toggle-btn" :class="{ active: mobileView === 'list' }" v-on:click="setMobileView('list')">
                    <i class="fas fa-list-ul mr-1"></i>篩選與清單 ({{ filteredFactories.length }})
                </button>
                <button type="button" class="mobile-toggle-btn" :class="{ active: mobileView === 'map' }" v-on:click="setMobileView('map')">
                    <i class="fas fa-map-marked-alt mr-1"></i>檢視地圖
                </button>
            </div>

            <!-- ================================================================= -->
            <!-- Modal 1: 每月 Excel 數據更新精靈 (支援道路洗掃抽查統計表 & 洗掃日誌) -->
            <!-- ================================================================= -->
            <div v-if="showUploadModal" class="custom-modal-overlay" v-on:click.self="showUploadModal = false">
                <div class="custom-modal-card">
                    <div class="custom-modal-header">
                        <h5 class="m-0 font-weight-bold" style="font-size: 1rem;">
                            <i class="fas fa-file-excel mr-2"></i>每月道路洗掃數據更新 (匯入 Excel)
                        </h5>
                        <button type="button" class="btn btn-sm text-white p-0" style="font-size: 1.1rem;" v-on:click="showUploadModal = false">
                            <i class="fas fa-times"></i>
                        </button>
                    </div>

                    <div class="custom-modal-body">
                        <div class="alert alert-info py-2 px-3 mb-2" style="font-size: 0.81rem;">
                            <div class="font-weight-bold mb-1"><i class="fas fa-database mr-1"></i>SQL Server 結構化資料表與增量寫入引擎：</div>
                            <div>1. <strong>《道路洗掃抽查統計表 YYYY MM.xlsx》</strong>：寫入 <code>WashMap_Factory</code> 與 <code>WashMap_MonthlyAudit</code> 資料表。</div>
                            <div>2. <strong>《115道路洗掃日誌 YYYY MM.xlsx》</strong>：寫入 <code>WashMap_MonthlyLog</code> 資料表。</div>
                            <div v-if="sqlAuditMonths.length || sqlLogMonths.length" class="mt-1 pt-1 border-top" style="border-color: rgba(2,132,199,0.2) !important;">
                                <div>• <strong>SQL 已收錄查核月份：</strong>{{ sqlAuditMonths.join('、') || '尚無' }}</div>
                                <div>• <strong>SQL 已收錄日誌月份：</strong>{{ sqlLogMonths.join('、') || '尚無' }}</div>
                            </div>
                        </div>

                        <!-- 增量寫入模式切換 -->
                        <div class="p-2 mb-3 rounded border bg-light d-flex align-items-center justify-content-between" style="font-size: 0.82rem;">
                            <label class="m-0 d-flex align-items-center" style="cursor: pointer; font-weight: 600; color: #0f172a;">
                                <input type="checkbox" class="mr-2" v-model="onlyNewMonths" />
                                <span>僅針對「新月份與當月最新異動」寫入 SQL（自動略過 SQL 已收錄之舊月份，免重複讀取舊資料）</span>
                            </label>
                            <span class="badge" :class="onlyNewMonths ? 'badge-success' : 'badge-warning text-white'">
                                {{ onlyNewMonths ? '增量寫入模式' : '全月份重刷模式' }}
                            </span>
                        </div>

                        <!-- 拖放或點擊選檔區 -->
                        <div class="upload-dropzone"
                             :class="{ dragover: isDraggingFile }"
                             v-on:click="triggerFileInput"
                             v-on:dragover.prevent="isDraggingFile = true"
                             v-on:dragleave.prevent="isDraggingFile = false"
                             v-on:drop.prevent="onFileDrop">
                            <input type="file" id="excelFileInput" multiple accept=".xlsx,.xls" style="display: none;" v-on:change="onFileSelect" />
                            <i class="fas fa-cloud-upload-alt fa-3x text-primary mb-2"></i>
                            <div class="font-weight-bold text-dark" style="font-size: 0.95rem;">
                                點擊此處選擇 Excel 檔案，或將檔案直接拖曳至此
                            </div>
                            <div class="text-muted mt-1" style="font-size: 0.78rem;">
                                支援 <code>.xlsx</code> / <code>.xls</code> 格式，可一次選取「抽查統計表」與「洗掃日誌」兩個檔案
                            </div>
                        </div>

                        <!-- 已選取待上傳檔案列表 -->
                        <div v-if="selectedFiles.length > 0" class="mt-3">
                            <div class="font-weight-bold mb-1" style="font-size: 0.82rem;">已選取待匯入檔案 ({{ selectedFiles.length }})：</div>
                            <div v-for="(f, idx) in selectedFiles" :key="idx" class="d-flex justify-content-between align-items-center bg-light border rounded px-3 py-1 mb-1">
                                <span>
                                    <i class="fas fa-file-excel text-success mr-2"></i>
                                    <strong>{{ f.name }}</strong>
                                    <small class="text-muted ml-2">({{ (f.size / 1024).toFixed(1) }} KB)</small>
                                </span>
                                <button type="button" class="btn btn-sm text-danger p-0" v-on:click="removeSelectedFile(idx)">
                                    <i class="fas fa-trash-alt"></i>
                                </button>
                            </div>
                        </div>

                        <!-- 上傳更新結果報告 -->
                        <div v-if="uploadResult" class="mt-3 p-3 rounded border" :class="uploadResult.Success ? 'bg-light border-success' : 'bg-light border-danger'">
                            <div class="font-weight-bold" :class="uploadResult.Success ? 'text-success' : 'text-danger'">
                                <i class="fas mr-1" :class="uploadResult.Success ? 'fa-check-circle' : 'fa-exclamation-triangle'"></i>
                                {{ uploadResult.Message }}
                            </div>
                            <div v-if="uploadResult.Summary" class="mt-2" style="font-size: 0.8rem;">
                                <div>• <strong>儲存位置：</strong>{{ uploadResult.Summary.StorageMode || 'SQL Server' }}</div>
                                <div>• <strong>處理檔案：</strong>{{ (uploadResult.Summary.ProcessedFiles || []).join('、') }}</div>
                                <div>• <strong>更新工廠總數：</strong>{{ uploadResult.Summary.UpdatedFactoryCount }} 家（新加入列管：{{ uploadResult.Summary.AddedNewFactoryCount }} 家）</div>
                                <div v-if="uploadResult.Summary.AuditMonths && uploadResult.Summary.AuditMonths.length">
                                    • <strong>本次寫入 SQL 查核月份：</strong><span class="text-primary font-weight-bold">{{ uploadResult.Summary.AuditMonths.join('、') }}</span>（共寫入 {{ uploadResult.Summary.UpdatedAuditRecordCount }} 筆）
                                </div>
                                <div v-if="uploadResult.Summary.SkippedAuditMonths && uploadResult.Summary.SkippedAuditMonths.length" class="text-muted">
                                    • <strong>已存於 SQL 自動略過之舊查核月份：</strong>{{ uploadResult.Summary.SkippedAuditMonths.join('、') }}
                                </div>
                                <div v-if="uploadResult.Summary.LogMonths && uploadResult.Summary.LogMonths.length">
                                    • <strong>本次寫入 SQL 日誌月份：</strong><span class="text-primary font-weight-bold">{{ uploadResult.Summary.LogMonths.join('、') }}</span>（共寫入 {{ uploadResult.Summary.UpdatedLogRecordCount }} 筆）
                                </div>
                                <div v-if="uploadResult.Summary.SkippedLogMonths && uploadResult.Summary.SkippedLogMonths.length" class="text-muted">
                                    • <strong>已存於 SQL 自動略過之舊日誌月份：</strong>{{ uploadResult.Summary.SkippedLogMonths.join('、') }}
                                </div>
                                <div v-if="uploadResult.Summary.UnmatchedItems && uploadResult.Summary.UnmatchedItems.length" class="mt-1 text-muted">
                                    • <small>未在183家座標庫內之項目 ({{ uploadResult.Summary.UnmatchedItems.length }})：{{ uploadResult.Summary.UnmatchedItems.slice(0, 8).join('、') }}</small>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="custom-modal-footer">
                        <button type="button" class="btn btn-secondary btn-sm px-3" v-on:click="showUploadModal = false">關閉</button>
                        <button type="button" class="btn btn-primary btn-sm px-4 font-weight-bold"
                                :disabled="selectedFiles.length === 0 || isUploading"
                                v-on:click="submitExcelUpload">
                            <span v-if="isUploading" class="spinner-border spinner-border-sm mr-1"></span>
                            <i v-else class="fas fa-upload mr-1"></i>
                            {{ isUploading ? '正在解析並更新圖台...' : '開始匯入更新' }}
                        </button>
                    </div>
                </div>
            </div>

            <!-- ================================================================= -->
            <!-- Modal 2: 資料來源與每月更新操作說明                                -->
            <!-- ================================================================= -->
            <div v-if="showInfoModal" class="custom-modal-overlay" v-on:click.self="showInfoModal = false">
                <div class="custom-modal-card">
                    <div class="custom-modal-header">
                        <h5 class="m-0 font-weight-bold" style="font-size: 1rem;">
                            <i class="fas fa-info-circle mr-2"></i>道路洗掃路段與查核地圖 — 資料說明與更新指南
                        </h5>
                        <button type="button" class="btn btn-sm text-white p-0" style="font-size: 1.1rem;" v-on:click="showInfoModal = false">
                            <i class="fas fa-times"></i>
                        </button>
                    </div>
                    <div class="custom-modal-body">
                        <h6 class="font-weight-bold text-primary"><i class="fas fa-database mr-1"></i>1. 資料整合來源</h6>
                        <p class="mb-2">{{ noteInfo.factory_source || '整合新北市列管固定逸散污染源清冊（183家）及道路洗掃認養與推動名單。' }}</p>
                        <p class="mb-3">{{ noteInfo.wash_source || '整合「道路洗掃日誌」各月份每日洗街/掃街公里數與「道路洗掃抽查統計表」分級及歷月現場抽查結果。' }}</p>

                        <h6 class="font-weight-bold text-primary"><i class="fas fa-route mr-1"></i>2. 洗掃路段幾何繪製原則</h6>
                        <p class="mb-3">{{ noteInfo.road_geom || '當廠方申報具體路名時，截取廠址周邊最接近申報長度的該道路線段（實線）；當未填具體路名時，自動以廠址最近的主次要道路繪製推估示意線段（虛線）。' }}</p>

                        <h6 class="font-weight-bold text-primary"><i class="fas fa-sync-alt mr-1"></i>3. 每月新數據更新操作步驟</h6>
                        <ol class="pl-3 mb-0">
                            <li>點擊畫面右上角橘色按鈕 <strong>「數據更新 (匯入Excel)」</strong>。</li>
                            <li>直接選取機關每月整理的 <code>道路洗掃抽查統計表 YYYY MM.xlsx</code> 及/或 <code>115道路洗掃日誌 YYYY MM.xlsx</code>。</li>
                            <li>點擊 <strong>「開始匯入更新」</strong>，系統會自動依管制編號與廠名比對更新，並同時寫入伺服器資料檔與資料庫備份，全站立即生效！</li>
                        </ol>
                    </div>
                    <div class="custom-modal-footer">
                        <button type="button" class="btn btn-primary btn-sm px-4" v-on:click="showInfoModal = false">我知道了</button>
                    </div>
                </div>
            </div>
        </div>
    </form>

    <!-- 本地化核心 JS 庫 (嚴守無外部 CDN 規範) -->
    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>
    <script src="../Scripts/leaflet/leaflet.js"></script>

    <script>
        (function () {
            var GROUP_COLORS = {
                '瀝青拌合': '#b91c1c',
                '水泥及混凝土': '#d97706',
                '鋼鐵及金屬鑄造': '#7c3aed',
                '石化、化學及鍋爐': '#db2777',
                '堆置場及砂石': '#0891b2',
                '窯業、耐火及玻璃': '#4f46e5',
                '其他': '#64748b'
            };
            var GROUP_ORDER = [
                '瀝青拌合',
                '水泥及混凝土',
                '鋼鐵及金屬鑄造',
                '石化、化學及鍋爐',
                '堆置場及砂石',
                '窯業、耐火及玻璃',
                '其他'
            ];

            var mapInstance = null;
            var roadLayerGroup = null;
            var roadLabelGroup = null;
            var facLayerGroup = null;
            var facMarkerMap = {};

            var app = Vue.createApp({
                data: function () {
                    var initGroups = {};
                    for (var i = 0; i < GROUP_ORDER.length; i++) {
                        initGroups[GROUP_ORDER[i]] = true;
                    }
                    return {
                        nm: 9,
                        updatedAt: '',
                        noteInfo: {},
                        allFactories: [],
                        selectedFacId: '',
                        activeTab: 'fac',
                        sortBy: 'km',
                        showAdvFilters: true,
                        legendCollapsed: false,
                        mobileView: 'list',

                        filters: {
                            dist: '',
                            keyword: '',
                            hiOnly: false,
                            lv: '',
                            dirt: '',
                            how: '',
                            cats: { A: true, B: true, C: true },
                            groups: initGroups,
                            listSrc: { in183: true, non183: true }
                        },

                        layers: {
                            showRoads: true,
                            showRoadLabels: true
                        },

                        showUploadModal: false,
                        showInfoModal: false,
                        isDraggingFile: false,
                        selectedFiles: [],
                        isUploading: false,
                        uploadResult: null,
                        onlyNewMonths: true,
                        sqlLogMonths: [],
                        sqlAuditMonths: []
                    };
                },
                computed: {
                    totalCatCounts: function () {
                        var counts = { A: 0, B: 0, C: 0 };
                        for (var i = 0; i < this.allFactories.length; i++) {
                            var c = this.allFactories[i]._cat;
                            if (counts[c] !== undefined) counts[c]++;
                        }
                        return counts;
                    },
                    groupDefs: function () {
                        var counts = {};
                        for (var i = 0; i < GROUP_ORDER.length; i++) counts[GROUP_ORDER[i]] = 0;
                        for (var j = 0; j < this.allFactories.length; j++) {
                            var g = this.allFactories[j].grp || '其他';
                            counts[g] = (counts[g] || 0) + 1;
                        }
                        var list = [];
                        for (var k = 0; k < GROUP_ORDER.length; k++) {
                            var name = GROUP_ORDER[k];
                            list.push({
                                name: name,
                                color: GROUP_COLORS[name] || '#64748b',
                                count: counts[name] || 0
                            });
                        }
                        return list;
                    },
                    districtOptions: function () {
                        var map = {};
                        for (var i = 0; i < this.allFactories.length; i++) {
                            var d = this.allFactories[i].d;
                            if (d) map[d] = (map[d] || 0) + 1;
                        }
                        var keys = Object.keys(map).sort(function (a, b) { return map[b] - map[a]; });
                        var res = [];
                        for (var j = 0; j < keys.length; j++) {
                            res.push({ name: keys[j], count: map[keys[j]] });
                        }
                        return res;
                    },
                    filteredFactories: function () {
                        var self = this;
                        var kw = (this.filters.keyword || '').toLowerCase();
                        return this.allFactories.filter(function (f) {
                            if (!self.filters.cats[f._cat]) return false;
                            if (!self.filters.groups[f.grp || '其他']) return false;
                            if (self.filters.hiOnly && !f.hi) return false;
                            if (f.ls && !self.filters.listSrc.in183) return false;
                            if (!f.ls && !self.filters.listSrc.non183) return false;
                            if (self.filters.dist && f.d !== self.filters.dist) return false;

                            if (self.filters.lv) {
                                if (!f.info || f.info.lv !== self.filters.lv) return false;
                            }
                            if (self.filters.dirt) {
                                if (!f.info || f.info.dirt !== self.filters.dirt) return false;
                            }
                            if (self.filters.how) {
                                if (!f.info || f.info.how !== self.filters.how) return false;
                            }

                            if (kw) {
                                var roadNames = (f.r || []).map(function (r) { return r.road || ''; }).join(' ');
                                var gName = (f.g && f.g.name) ? f.g.name : '';
                                var hay = [f.id, f.n, f.oldn || '', f.d || '', f.a || '', f.i || '', f.p || '', roadNames, gName].join(' ').toLowerCase();
                                if (hay.indexOf(kw) === -1) return false;
                            }
                            return true;
                        });
                    },
                    sortedFactories: function () {
                        var arr = this.filteredFactories.slice();
                        var s = this.sortBy;
                        arr.sort(function (a, b) {
                            if (s === 'km') return (b._tot - a._tot) || a.id.localeCompare(b.id);
                            if (s === 'roadlen') {
                                var la = (a.g && a.g.L) ? a.g.L : 0;
                                var lb = (b.g && b.g.L) ? b.g.L : 0;
                                return (lb - la) || (b._tot - a._tot);
                            }
                            if (s === 'audit') {
                                var da = (a._latestAud && a._latestAud.dt) ? a._latestAud.dt : '';
                                var db = (b._latestAud && b._latestAud.dt) ? b._latestAud.dt : '';
                                return db.localeCompare(da) || (b._tot - a._tot);
                            }
                            return a.id.localeCompare(b.id);
                        });
                        return arr;
                    },
                    groupedRoads: function () {
                        var map = {};
                        for (var i = 0; i < this.filteredFactories.length; i++) {
                            var f = this.filteredFactories[i];
                            if (!f.g || f.g.mode === 'none' || !f.g.lines || !f.g.lines.length) continue;
                            var rName = f.g.name || '周邊認養道路';
                            var key = (f.d || '') + '__' + rName + '__' + f.g.mode;
                            if (!map[key]) {
                                map[key] = {
                                    key: key,
                                    dist: f.d || '',
                                    name: rName,
                                    mode: f.g.mode,
                                    totalKm: 0,
                                    facs: []
                                };
                            }
                            map[key].totalKm += (f.g.L || 0);
                            map[key].facs.push(f);
                        }
                        var list = Object.keys(map).map(function (k) {
                            var item = map[k];
                            item.facNamesText = item.facs.map(function (x) { return x.n; }).join('、');
                            return item;
                        });
                        list.sort(function (a, b) {
                            if (a.mode !== b.mode) return a.mode === 'name' ? -1 : 1;
                            return b.totalKm - a.totalKm;
                        });
                        return list;
                    },
                    countCatA: function () {
                        var c = 0;
                        for (var i = 0; i < this.filteredFactories.length; i++) {
                            if (this.filteredFactories[i]._cat === 'A') c++;
                        }
                        return c;
                    },
                    countHighRisk: function () {
                        var c = 0;
                        for (var i = 0; i < this.filteredFactories.length; i++) {
                            if (this.filteredFactories[i].hi) c++;
                        }
                        return c;
                    },
                    totalWashKm: function () {
                        var sum = 0;
                        for (var i = 0; i < this.filteredFactories.length; i++) {
                            sum += (this.filteredFactories[i]._tot || 0);
                        }
                        return Math.round(sum).toLocaleString();
                    },
                    totalRoadLineKm: function () {
                        var sum = 0;
                        for (var i = 0; i < this.filteredFactories.length; i++) {
                            var f = this.filteredFactories[i];
                            if (f.g && f.g.L) sum += f.g.L;
                        }
                        return sum.toFixed(1);
                    },
                    isOnlyCatA: function () {
                        return this.filters.cats.A && !this.filters.cats.B && !this.filters.cats.C;
                    },
                    isDefaultCatFilter: function () {
                        return this.filters.cats.A && this.filters.cats.B && this.filters.cats.C && !this.filters.hiOnly;
                    }
                },
                watch: {
                    filteredFactories: function () {
                        this.renderMapLayers();
                    }
                },
                mounted: function () {
                    this.initMap();
                    this.loadInitData();
                },
                methods: {
                    initMap: function () {
                        mapInstance = L.map('map', {
                            center: [25.06, 121.45],
                            zoom: 12,
                            preferCanvas: true
                        });

                        var nlscEmap = L.tileLayer('https://wmts.nlsc.gov.tw/wmts/EMAP/default/GoogleMapsCompatible/{z}/{y}/{x}', {
                            maxZoom: 19,
                            attribution: '© 內政部國土測繪中心 NLSC'
                        });
                        var nlscPhoto = L.tileLayer('https://wmts.nlsc.gov.tw/wmts/PHOTO2/default/GoogleMapsCompatible/{z}/{y}/{x}', {
                            maxZoom: 19,
                            attribution: '© 內政部國土測繪中心正射影像'
                        });
                        var nlscHybrid = L.layerGroup([
                            L.tileLayer('https://wmts.nlsc.gov.tw/wmts/PHOTO2/default/GoogleMapsCompatible/{z}/{y}/{x}', { maxZoom: 19 }),
                            L.tileLayer('https://wmts.nlsc.gov.tw/wmts/EMAP2/default/GoogleMapsCompatible/{z}/{y}/{x}', { maxZoom: 19, opacity: 0.85 })
                        ]);

                        nlscEmap.addTo(mapInstance);
                        L.control.layers({
                            '臺灣通用電子地圖 (含路名門牌)': nlscEmap,
                            '正射影像 (航照空拍)': nlscPhoto,
                            '電子地圖＋正射影像套疊': nlscHybrid
                        }, null, { position: 'topright' }).addTo(mapInstance);

                        L.control.scale({ imperial: false, position: 'bottomright' }).addTo(mapInstance);

                        roadLayerGroup = L.layerGroup().addTo(mapInstance);
                        roadLabelGroup = L.layerGroup();
                        facLayerGroup = L.layerGroup().addTo(mapInstance);

                        var self = this;
                        mapInstance.on('zoomend', function () {
                            self.syncRoadLabelVisibility();
                        });
                    },

                    loadInitData: function () {
                        var self = this;
                        axios.get('WashMapHandler.ashx?action=getinit&_t=' + Date.now())
                            .then(function (res) {
                                if (res.data && res.data.Success && res.data.Data) {
                                    self.applyDataset(res.data.Data);
                                } else {
                                    alert((res.data && res.data.Message) || '載入洗掃地圖資料失敗');
                                }
                            })
                            .catch(function (err) {
                                alert('讀取洗掃路段資料發生錯誤：' + err.message);
                            });
                    },

                    applyDataset: function (dataObj) {
                        this.nm = dataObj.NM || 9;
                        this.updatedAt = dataObj.UPDATED_AT || '';
                        this.noteInfo = dataObj.NOTE || {};
                        this.sqlLogMonths = dataObj.SQL_LOG_MONTHS || [];
                        this.sqlAuditMonths = dataObj.SQL_AUDIT_MONTHS || [];
                        var rawF = dataObj.F || [];

                        for (var i = 0; i < rawF.length; i++) {
                            var f = rawF[i];
                            var wArr = f.w || [];
                            var sArr = f.s || [];
                            var wSum = 0, sSum = 0;
                            for (var m = 0; m < wArr.length; m++) wSum += (Number(wArr[m]) || 0);
                            for (var n = 0; n < sArr.length; n++) sSum += (Number(sArr[n]) || 0);
                            f._wSum = Math.round(wSum * 100) / 100;
                            f._sSum = Math.round(sSum * 100) / 100;
                            f._tot = Math.round((wSum + sSum) * 100) / 100;

                            if (f._tot > 0) {
                                f._cat = 'A';
                            } else if (f.st === 'wash' || f.st === 'push' || (f.r && f.r.length > 0)) {
                                f._cat = 'B';
                            } else {
                                f._cat = 'C';
                            }

                            var auds = f.aud || [];
                            var latestAud = null;
                            for (var aIdx = auds.length - 1; aIdx >= 0; aIdx--) {
                                if (auds[aIdx] && (auds[aIdx].dt || auds[aIdx].ok)) {
                                    latestAud = auds[aIdx];
                                    break;
                                }
                            }
                            f._latestAud = latestAud;
                        }

                        this.allFactories = rawF;
                        this.renderMapLayers();
                    },

                    getGroupColor: function (grp) {
                        return GROUP_COLORS[grp] || '#64748b';
                    },

                    renderMapLayers: function () {
                        if (!mapInstance) return;
                        roadLayerGroup.clearLayers();
                        roadLabelGroup.clearLayers();
                        facLayerGroup.clearLayers();
                        facMarkerMap = {};

                        var self = this;
                        var list = this.filteredFactories;

                        for (var i = 0; i < list.length; i++) {
                            (function (f) {
                                // 1. 繪製洗掃路段幾何
                                if (f.g && f.g.mode !== 'none' && f.g.lines && f.g.lines.length) {
                                    var isNamed = (f.g.mode === 'name');
                                    var lineColor = (f._cat === 'A')
                                        ? (isNamed ? '#2563eb' : '#3b82f6')
                                        : '#f97316';
                                    var dashPattern = (f._cat === 'A' && isNamed) ? null : '8, 6';

                                    // 白色外框底線
                                    var casing = L.polyline(f.g.lines, {
                                        color: '#ffffff',
                                        weight: 9,
                                        opacity: 0.9,
                                        lineCap: 'round'
                                    });
                                    // 主色線段
                                    var mainLine = L.polyline(f.g.lines, {
                                        color: lineColor,
                                        weight: 5,
                                        opacity: 0.92,
                                        dashArray: dashPattern,
                                        lineCap: 'round'
                                    });

                                    var roadTip = '<b>' + self.escapeHtml(f.n) + '</b> (' + f.id + ')<br>'
                                        + (isNamed ? ('申報認養路段：<b>' + self.escapeHtml(f.g.name) + '</b>') : ('推估最近道路：<b>' + self.escapeHtml(f.g.name || '周邊道路') + '</b>'))
                                        + ' · ' + f.g.L + ' km<br>1–' + self.nm + '月累計洗掃：<b>' + f._tot.toFixed(1) + ' km</b>';
                                    mainLine.bindTooltip(roadTip, { sticky: true });
                                    mainLine.on('click', function () {
                                        self.focusFactory(f);
                                    });

                                    roadLayerGroup.addLayer(casing);
                                    roadLayerGroup.addLayer(mainLine);

                                    // 廠門至道路吸附點虛線
                                    if (f.g.snap && f.g.snap.length === 2 && f.g.gap > 8) {
                                        var connector = L.polyline([[f.la, f.lo], f.g.snap], {
                                            color: lineColor,
                                            weight: 2,
                                            opacity: 0.7,
                                            dashArray: '3, 5'
                                        });
                                        roadLayerGroup.addLayer(connector);
                                    }

                                    // 放大時顯示路名標籤
                                    var longestSeg = f.g.lines[0];
                                    for (var sIdx = 1; sIdx < f.g.lines.length; sIdx++) {
                                        if (f.g.lines[sIdx].length > longestSeg.length) {
                                            longestSeg = f.g.lines[sIdx];
                                        }
                                    }
                                    if (longestSeg && longestSeg.length > 0) {
                                        var midPt = longestSeg[Math.floor(longestSeg.length / 2)];
                                        var lblText = isNamed
                                            ? ('🛣 ' + f.g.name + ' (' + f.g.L + 'km)')
                                            : ('🛣 [推估] ' + (f.g.name || '最近道路') + ' (' + f.g.L + 'km)');
                                        var lblMarker = L.circleMarker(midPt, { radius: 0, opacity: 0, fillOpacity: 0 })
                                            .bindTooltip(lblText, {
                                                permanent: true,
                                                direction: 'center',
                                                className: 'road-lbl' + (isNamed ? '' : ' est')
                                            });
                                        roadLabelGroup.addLayer(lblMarker);
                                    }
                                }

                                // 2. 繪製工廠點位與外環
                                var grpColor = self.getGroupColor(f.grp);
                                var radius = f._cat === 'A' ? 8 : (f._cat === 'B' ? 7 : 6);

                                if (f._cat !== 'C' || f.hi) {
                                    var ringColor = f._cat === 'A' ? '#f59e0b' : (f._cat === 'B' ? '#fb923c' : '#ef4444');
                                    var ring = L.circleMarker([f.la, f.lo], {
                                        radius: radius + 4,
                                        color: ringColor,
                                        weight: 2,
                                        opacity: 0.85,
                                        fillOpacity: 0,
                                        interactive: false
                                    });
                                    facLayerGroup.addLayer(ring);
                                }

                                var marker = L.circleMarker([f.la, f.lo], {
                                    radius: radius,
                                    color: '#ffffff',
                                    weight: 2,
                                    fillColor: grpColor,
                                    fillOpacity: f._cat === 'C' ? 0.78 : 0.96
                                });

                                marker.bindTooltip('<b>' + self.escapeHtml(f.n) + '</b> (' + f.id + ')<br>' + self.escapeHtml(f.grp || '') + ' · 累計洗掃 ' + f._tot.toFixed(1) + ' km');
                                marker.bindPopup(function () { return self.buildPopupHtml(f); }, { maxWidth: 380 });
                                marker.on('click', function () {
                                    self.selectedFacId = f.id;
                                });

                                facLayerGroup.addLayer(marker);
                                facMarkerMap[f.id] = marker;
                            })(list[i]);
                        }

                        if (this.layers.showRoads) {
                            if (!mapInstance.hasLayer(roadLayerGroup)) mapInstance.addLayer(roadLayerGroup);
                        } else {
                            if (mapInstance.hasLayer(roadLayerGroup)) mapInstance.removeLayer(roadLayerGroup);
                        }
                        this.syncRoadLabelVisibility();
                    },

                    syncRoadLabelVisibility: function () {
                        if (!mapInstance) return;
                        if (this.layers.showRoadLabels && this.layers.showRoads && mapInstance.getZoom() >= 16) {
                            if (!mapInstance.hasLayer(roadLabelGroup)) mapInstance.addLayer(roadLabelGroup);
                        } else {
                            if (mapInstance.hasLayer(roadLabelGroup)) mapInstance.removeLayer(roadLabelGroup);
                        }
                    },

                    buildPopupHtml: function (f) {
                        var catBadge = f._cat === 'A'
                            ? '<span class="w-tag w-tag-blue">有洗掃紀錄 (' + f._tot.toFixed(1) + ' km)</span>'
                            : (f._cat === 'B' ? '<span class="w-tag w-tag-amber">列入洗掃無紀錄</span>' : '<span class="w-tag w-tag-gray">未列洗掃</span>');
                        var hiBadge = f.hi ? '<span class="w-tag w-tag-red">高風險逸散行業</span>' : '';
                        var lsBadge = f.ls ? '<span class="w-tag w-tag-green">183家列管清冊</span>' : '<span class="w-tag w-tag-amber">非183清冊(洗掃表)</span>';

                        var infoBadges = '';
                        if (f.info) {
                            if (f.info.lv) infoBadges += '<span class="w-tag w-tag-purple">' + this.escapeHtml(f.info.lv) + '</span>';
                            if (f.info.dirt) infoBadges += '<span class="w-tag ' + (f.info.dirt === 'A' ? 'w-tag-green' : 'w-tag-amber') + '">髒污' + this.escapeHtml(f.info.dirt) + '級</span>';
                            if (f.info.how) infoBadges += '<span class="w-tag w-tag-blue">' + this.escapeHtml(f.info.how) + '</span>';
                            if (f.info.freq) infoBadges += '<span class="w-tag w-tag-gray">頻率:' + this.escapeHtml(f.info.freq) + '</span>';
                        }

                        var roadRows = '';
                        if (f.r && f.r.length) {
                            var rItems = [];
                            for (var i = 0; i < f.r.length; i++) {
                                var r = f.r[i];
                                rItems.push('<b>' + this.escapeHtml(r.road || '未填路名') + '</b>'
                                    + (r.cls ? ' (' + this.escapeHtml(r.cls) + ')' : '')
                                    + (r.lanes ? ' · ' + r.lanes + '車道' : '')
                                    + (r.km ? ' · 認養 ' + r.km + ' km' : ''));
                            }
                            roadRows += '<tr><td class="k">申報路段</td><td>' + rItems.join('<br>') + '</td></tr>';
                        }
                        if (f.g && f.g.mode !== 'none') {
                            var gDesc = f.g.mode === 'name'
                                ? ('<span class="text-primary font-weight-bold">🛣 ' + this.escapeHtml(f.g.name) + '</span> · 實繪 ' + f.g.L + ' km')
                                : ('<span style="color:#b45309;font-weight:700;">🛣 [推估] ' + this.escapeHtml(f.g.name || '周邊道路') + '</span> · 示意 ' + f.g.L + ' km');
                            roadRows += '<tr><td class="k">地圖幾何</td><td>' + gDesc + '</td></tr>';
                        }

                        // 每月洗掃里程長條圖
                        var maxM = 0.01;
                        var wArr = f.w || [];
                        var sArr = f.s || [];
                        for (var m = 0; m < this.nm; m++) {
                            var totM = (Number(wArr[m]) || 0) + (Number(sArr[m]) || 0);
                            if (totM > maxM) maxM = totM;
                        }
                        var barsHtml = '';
                        if (f._tot > 0) {
                            var cols = '';
                            for (var k = 0; k < this.nm; k++) {
                                var wv = Number(wArr[k]) || 0;
                                var sv = Number(sArr[k]) || 0;
                                var wh = Math.round((wv / maxM) * 40);
                                var sh = Math.round((sv / maxM) * 40);
                                var wDays = (f.wd && f.wd[k]) ? f.wd[k] : 0;
                                var sDays = (f.sd && f.sd[k]) ? f.sd[k] : 0;
                                var tip = (k + 1) + '月：洗街 ' + wv + ' km (' + wDays + '天) / 掃街 ' + sv + ' km (' + sDays + '天)';
                                cols += '<div class="bar-col" title="' + tip + '">'
                                    + '<div class="bar-w" style="height:' + wh + 'px"></div>'
                                    + '<div class="bar-s" style="height:' + sh + 'px"></div>'
                                    + '<span>' + (k + 1) + '月</span></div>';
                            }
                            barsHtml = '<div class="mt-2 font-weight-bold" style="font-size:11px;">115年 1–' + this.nm + '月 洗掃里程 (藍=洗街 ' + f._wSum.toFixed(1) + 'km / 橘=掃街 ' + f._sSum.toFixed(1) + 'km)</div>'
                                + '<div class="bars-box">' + cols + '</div>';
                        }

                        // 歷月現場抽查紀錄表
                        var audHtml = '';
                        if (f.aud && f.aud.length) {
                            var aRows = '';
                            for (var a = 0; a < f.aud.length; a++) {
                                var ar = f.aud[a];
                                var okColor = ar.ok === '是' ? '#15803d' : (ar.ok === '否' ? '#b91c1c' : '#64748b');
                                aRows += '<tr>'
                                    + '<td>' + this.escapeHtml(ar.m || '') + '</td>'
                                    + '<td>' + this.escapeHtml(ar.dt || '-') + '</td>'
                                    + '<td>' + this.escapeHtml(ar.log || '-') + '</td>'
                                    + '<td style="font-weight:700;color:' + okColor + '">' + this.escapeHtml(ar.ok || '-') + '</td>'
                                    + '<td>' + this.escapeHtml(ar.up || '-') + '</td>'
                                    + '</tr>';
                            }
                            audHtml = '<div class="mt-2 font-weight-bold" style="font-size:11px;">現場抽查紀錄 (道路洗掃抽查統計表)</div>'
                                + '<div style="max-height:110px;overflow-y:auto;"><table class="aud-tbl"><thead><tr><th>月份</th><th>抽查日期</th><th>日誌</th><th>合格</th><th>自主上傳</th></tr></thead><tbody>'
                                + aRows + '</tbody></table></div>';
                        }

                        return '<div class="pop-wrap">'
                            + '<div class="pop-title">' + this.escapeHtml(f.n) + '</div>'
                            + '<div class="mb-1">' + catBadge + hiBadge + lsBadge + infoBadges + '</div>'
                            + '<table class="pop-tbl">'
                            + '<tr><td class="k">管制編號</td><td><b>' + this.escapeHtml(f.id) + '</b> (' + this.escapeHtml(f.d || '') + ')</td></tr>'
                            + '<tr><td class="k">廠場地址</td><td>' + this.escapeHtml(f.a || '-') + '</td></tr>'
                            + '<tr><td class="k">行業/程序</td><td>' + this.escapeHtml(f.grp || '') + ' — ' + this.escapeHtml(f.i || '') + (f.p ? ' (' + this.escapeHtml(f.p) + ')' : '') + '</td></tr>'
                            + roadRows
                            + '</table>'
                            + barsHtml
                            + audHtml
                            + '<div class="mt-2 pt-2 border-top d-flex justify-content-between">'
                            + '<a href="../Wash/ReportUpload_List.aspx" class="btn btn-sm btn-outline-primary py-0 px-2" style="font-size:11px;"><i class="fas fa-list mr-1"></i>洗掃紀錄列表</a>'
                            + '<a href="../FAC/FAC_List.aspx?mode=read" class="btn btn-sm btn-outline-secondary py-0 px-2" style="font-size:11px;"><i class="fas fa-industry mr-1"></i>列管廠基本檔</a>'
                            + '</div>'
                            + '</div>';
                    },

                    focusFactory: function (f) {
                        this.selectedFacId = f.id;
                        if (window.innerWidth < 768) {
                            this.setMobileView('map');
                        }
                        if (!mapInstance) return;

                        if (f.g && f.g.lines && f.g.lines.length) {
                            var pts = [[f.la, f.lo]];
                            for (var i = 0; i < f.g.lines.length; i++) {
                                for (var j = 0; j < f.g.lines[i].length; j++) {
                                    pts.push(f.g.lines[i][j]);
                                }
                            }
                            mapInstance.fitBounds(pts, { padding: [60, 60], maxZoom: 17 });
                        } else {
                            mapInstance.setView([f.la, f.lo], 16);
                        }

                        var m = facMarkerMap[f.id];
                        if (m) {
                            setTimeout(function () { m.openPopup(); }, 180);
                        }
                    },

                    focusRoadGroup: function (rd) {
                        if (window.innerWidth < 768) {
                            this.setMobileView('map');
                        }
                        if (!mapInstance || !rd.facs || !rd.facs.length) return;
                        var pts = [];
                        for (var i = 0; i < rd.facs.length; i++) {
                            var f = rd.facs[i];
                            pts.push([f.la, f.lo]);
                            if (f.g && f.g.lines) {
                                for (var s = 0; s < f.g.lines.length; s++) {
                                    for (var p = 0; p < f.g.lines[s].length; p++) {
                                        pts.push(f.g.lines[s][p]);
                                    }
                                }
                            }
                        }
                        if (pts.length) {
                            mapInstance.fitBounds(pts, { padding: [60, 60], maxZoom: 17 });
                        }
                        var firstFac = rd.facs[0];
                        this.selectedFacId = firstFac.id;
                        var m = facMarkerMap[firstFac.id];
                        if (m) {
                            setTimeout(function () { m.openPopup(); }, 200);
                        }
                    },

                    onDistChange: function () {
                        if (!this.filters.dist || !mapInstance) return;
                        var pts = [];
                        for (var i = 0; i < this.filteredFactories.length; i++) {
                            var f = this.filteredFactories[i];
                            pts.push([f.la, f.lo]);
                        }
                        if (pts.length > 0) {
                            mapInstance.fitBounds(pts, { padding: [50, 50], maxZoom: 15 });
                        }
                    },

                    toggleCat: function (c) {
                        this.filters.cats[c] = !this.filters.cats[c];
                    },

                    toggleSingleFilter: function (field, val) {
                        this.filters[field] = (this.filters[field] === val) ? '' : val;
                    },

                    toggleGroup: function (gName) {
                        this.filters.groups[gName] = !this.filters.groups[gName];
                    },

                    setAllGroups: function (val) {
                        for (var i = 0; i < GROUP_ORDER.length; i++) {
                            this.filters.groups[GROUP_ORDER[i]] = val;
                        }
                    },

                    toggleRoadLayer: function () {
                        this.layers.showRoads = !this.layers.showRoads;
                        this.renderMapLayers();
                    },

                    toggleRoadLabelLayer: function () {
                        this.layers.showRoadLabels = !this.layers.showRoadLabels;
                        this.syncRoadLabelVisibility();
                    },

                    resetQuickStatFilter: function () {
                        this.filters.cats.A = true;
                        this.filters.cats.B = true;
                        this.filters.cats.C = true;
                        this.filters.hiOnly = false;
                    },

                    toggleOnlyCatA: function () {
                        if (this.isOnlyCatA) {
                            this.filters.cats.A = true;
                            this.filters.cats.B = true;
                            this.filters.cats.C = true;
                        } else {
                            this.filters.cats.A = true;
                            this.filters.cats.B = false;
                            this.filters.cats.C = false;
                        }
                    },

                    toggleHiOnly: function () {
                        this.filters.hiOnly = !this.filters.hiOnly;
                    },

                    switchSortToKm: function () {
                        this.activeTab = 'fac';
                        this.sortBy = 'km';
                    },

                    resetFilters: function () {
                        this.filters.dist = '';
                        this.filters.keyword = '';
                        this.filters.hiOnly = false;
                        this.filters.lv = '';
                        this.filters.dirt = '';
                        this.filters.how = '';
                        this.filters.cats.A = true;
                        this.filters.cats.B = true;
                        this.filters.cats.C = true;
                        this.filters.listSrc.in183 = true;
                        this.filters.listSrc.non183 = true;
                        this.setAllGroups(true);
                        if (mapInstance) {
                            mapInstance.setView([25.06, 121.45], 12);
                        }
                    },

                    setMobileView: function (v) {
                        this.mobileView = v;
                        if (v === 'map' && mapInstance) {
                            setTimeout(function () { mapInstance.invalidateSize(); }, 150);
                        }
                    },

                    // ==================== Excel 匯入更新功能 ====================
                    openUploadModal: function () {
                        this.selectedFiles = [];
                        this.uploadResult = null;
                        this.showUploadModal = true;
                    },

                    triggerFileInput: function () {
                        var el = document.getElementById('excelFileInput');
                        if (el) {
                            el.value = '';
                            el.click();
                        }
                    },

                    onFileSelect: function (e) {
                        var files = e.target.files;
                        this.addFilesToQueue(files);
                    },

                    onFileDrop: function (e) {
                        this.isDraggingFile = false;
                        var files = e.dataTransfer ? e.dataTransfer.files : null;
                        this.addFilesToQueue(files);
                    },

                    addFilesToQueue: function (fileList) {
                        if (!fileList || !fileList.length) return;
                        for (var i = 0; i < fileList.length; i++) {
                            var f = fileList[i];
                            var low = f.name.toLowerCase();
                            if (low.indexOf('.xlsx') !== -1 || low.indexOf('.xls') !== -1) {
                                this.selectedFiles.push(f);
                            }
                        }
                    },

                    removeSelectedFile: function (idx) {
                        this.selectedFiles.splice(idx, 1);
                    },

                    submitExcelUpload: function () {
                        if (!this.selectedFiles.length || this.isUploading) return;
                        var self = this;
                        this.isUploading = true;
                        this.uploadResult = null;

                        var fd = new FormData();
                        fd.append('onlyNewMonths', this.onlyNewMonths ? '1' : '0');
                        for (var i = 0; i < this.selectedFiles.length; i++) {
                            fd.append('file_' + i, this.selectedFiles[i]);
                        }

                        axios.post('WashMapHandler.ashx?action=uploadexcel', fd, {
                            headers: { 'Content-Type': 'multipart/form-data' }
                        })
                        .then(function (res) {
                            self.isUploading = false;
                            if (res.data) {
                                self.uploadResult = res.data;
                                if (res.data.Success && res.data.Data) {
                                    self.applyDataset(res.data.Data);
                                    self.selectedFiles = [];
                                }
                            }
                        })
                        .catch(function (err) {
                            self.isUploading = false;
                            self.uploadResult = {
                                Success: false,
                                Message: '上傳解析失敗：' + (err.message || '伺服器回應異常')
                            };
                        });
                    },

                    // ==================== CSV 報表匯出 ====================
                    exportCsv: function () {
                        var cols = [
                            '管制編號', '廠名', '行政區', '地址', '行業群組', '行業別', '程序別', '高風險行業',
                            '洗掃狀態分類', '認養級別', '髒污分級', '洗掃方式', '洗掃頻率',
                            '申報認養道路', '地圖繪製道路', '繪製模式', '道路長度_km',
                            '1至' + this.nm + '月洗街合計_km', '1至' + this.nm + '月掃街合計_km', '1至' + this.nm + '月總計_km',
                            '最近抽查月份', '最近抽查日期', '最近抽查結果'
                        ];

                        var lines = [cols.join(',')];
                        for (var i = 0; i < this.sortedFactories.length; i++) {
                            var f = this.sortedFactories[i];
                            var rStr = (f.r || []).map(function (r) { return (r.road || '') + (r.km ? '(' + r.km + 'km)' : ''); }).join(' / ');
                            var audM = f._latestAud ? (f._latestAud.m || '') : '';
                            var audDt = f._latestAud ? (f._latestAud.dt || '') : '';
                            var audOk = f._latestAud ? (f._latestAud.ok || '') : '';

                            var row = [
                                f.id,
                                f.n,
                                f.d || '',
                                f.a || '',
                                f.grp || '',
                                f.i || '',
                                f.p || '',
                                f.hi ? '是' : '否',
                                f._cat,
                                (f.info && f.info.lv) ? f.info.lv : '',
                                (f.info && f.info.dirt) ? f.info.dirt : '',
                                (f.info && f.info.how) ? f.info.how : '',
                                (f.info && f.info.freq) ? f.info.freq : '',
                                rStr,
                                (f.g && f.g.name) ? f.g.name : '',
                                (f.g && f.g.mode) ? f.g.mode : 'none',
                                (f.g && f.g.L) ? f.g.L : 0,
                                f._wSum,
                                f._sSum,
                                f._tot,
                                audM,
                                audDt,
                                audOk
                            ].map(function (v) {
                                var s = String(v === null || v === undefined ? '' : v).replace(/"/g, '""');
                                return /[,"\n]/.test(s) ? ('"' + s + '"') : s;
                            });
                            lines.push(row.join(','));
                        }

                        var blob = new Blob(['\uFEFF' + lines.join('\r\n')], { type: 'text/csv;charset=utf-8' });
                        var a = document.createElement('a');
                        a.href = URL.createObjectURL(blob);
                        a.download = '新北市逸散工廠_洗掃路段與查核統計_' + new Date().toISOString().slice(0, 10) + '.csv';
                        a.click();
                    },

                    escapeHtml: function (str) {
                        if (!str) return '';
                        return String(str)
                            .replace(/&/g, '&amp;')
                            .replace(/</g, '&lt;')
                            .replace(/>/g, '&gt;')
                            .replace(/"/g, '&quot;');
                    }
                }
            });

            app.mount('#washMapApp');
        })();
    </script>
</body>
</html>
