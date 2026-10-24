<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Charts.aspx.cs" Inherits="NTPC_FEC.FAC.Charts" %>

<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定溢散源管理平台 - 工廠統計分析</title>

    <!-- 專屬 Favicon -->
    <link rel="shortcut icon" href="../favicon.ico" type="image/x-icon" />

    <!-- 本地化樣式依賴 -->
    <link rel="stylesheet" href="../Content/bootstrap.min.css" />
    <link rel="stylesheet" href="../Content/fontawesome/css/all.min.css" />

    <style>
        :root {
            --brand-primary: #0099e5;     /* 新北天空青藍 (Navbar/強調) */
            --brand-blue: #0284c7;        /* 科技藍 (按鈕/選中) */
            --brand-dark-blue: #0b1f7d;   /* 海軍深藍 (標題/Tag) */
            --brand-navy: #0f172a;        /* 標題文字主色 */
            --bg-canvas: #f8fafc;         /* 頁面灰底 */
            --surface: #ffffff;           /* 卡片純白底色 */
            --border-color: #e2e8f0;      /* 邊框線條 */
            --text-main: #0f172a;         /* 內文主要文字 */
            --text-muted: #64748b;        /* 次要說明文字 */
            --accent-green: #10b981;      /* 成功/合格綠 */
            --accent-amber: #f59e0b;      /* 警示琥珀橙 */
            --accent-indigo: #6366f1;     /* 靛紫特色色 */
        }

        * {
            box-sizing: border-box;
            -webkit-tap-highlight-color: transparent;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, "Noto Sans TC", "微軟正黑體", sans-serif;
            background-color: var(--bg-canvas);
            margin: 0;
            padding: 0;
            color: var(--text-main);
            overflow-x: hidden;
            min-height: 100vh;
        }

        [v-cloak] {
            display: none !important;
        }

        /* 頂部品牌導覽列 */
        .top-navbar {
            background: linear-gradient(135deg, #0099e5 0%, #0284c7 100%);
            color: #ffffff;
            height: 60px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 0 20px;
            box-shadow: 0 2px 10px rgba(0, 153, 229, 0.25);
            position: sticky;
            top: 0;
            z-index: 1020;
        }

        .navbar-brand-title {
            font-size: 1.15rem;
            font-weight: 700;
            display: flex;
            align-items: center;
            gap: 10px;
            color: #ffffff;
            text-decoration: none;
            letter-spacing: 0.5px;
        }

        .navbar-brand-title:hover {
            color: #ffffff;
            text-decoration: none;
        }

        .nav-btn {
            background: rgba(255, 255, 255, 0.18);
            border: none;
            color: #ffffff;
            font-size: 0.9rem;
            font-weight: 600;
            cursor: pointer;
            height: 36px;
            border-radius: 8px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            padding: 0 14px;
            gap: 6px;
            transition: all 0.2s ease;
            text-decoration: none;
        }

        .nav-btn:hover {
            background-color: rgba(255, 255, 255, 0.32);
            color: #ffffff;
            text-decoration: none;
        }

        /* 主容器佈局 */
        .container-fluid-custom {
            max-width: 1560px;
            margin: 0 auto;
            padding: 20px 16px 40px 16px;
        }

        /* 頂部 KPI 指標卡片 */
        .kpi-row {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
            gap: 16px;
            margin-bottom: 20px;
        }

        .kpi-card {
            background: var(--surface);
            border-radius: 12px;
            border: 1px solid var(--border-color);
            padding: 18px 20px;
            display: flex;
            align-items: center;
            gap: 16px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04), 0 4px 12px rgba(15, 23, 42, 0.03);
            transition: transform 0.2s ease, box-shadow 0.2s ease;
            position: relative;
            overflow: hidden;
        }

        .kpi-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 16px rgba(15, 23, 42, 0.08);
        }

        .kpi-card::before {
            content: "";
            position: absolute;
            left: 0;
            top: 0;
            bottom: 0;
            width: 4px;
        }

        .kpi-card.blue::before { background-color: var(--brand-primary); }
        .kpi-card.green::before { background-color: var(--accent-green); }
        .kpi-card.amber::before { background-color: var(--accent-amber); }
        .kpi-card.indigo::before { background-color: var(--accent-indigo); }

        .kpi-icon-box {
            width: 50px;
            height: 50px;
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.4rem;
            flex-shrink: 0;
        }

        .kpi-card.blue .kpi-icon-box { background: #e0f2fe; color: #0284c7; }
        .kpi-card.green .kpi-icon-box { background: #ecfdf5; color: #059669; }
        .kpi-card.amber .kpi-icon-box { background: #fef3c7; color: #d97706; }
        .kpi-card.indigo .kpi-icon-box { background: #e0e7ff; color: #4f46e5; }

        .kpi-info {
            display: flex;
            flex-direction: column;
        }

        .kpi-val {
            font-size: 1.8rem;
            font-weight: 800;
            line-height: 1.1;
            color: var(--brand-navy);
            letter-spacing: -0.5px;
        }

        .kpi-label {
            font-size: 0.85rem;
            font-weight: 600;
            color: var(--text-muted);
            margin-top: 4px;
        }

        /* 維度切換模式列 */
        .nav-mode-bar {
            background: #ffffff;
            border-radius: 12px;
            border: 1px solid var(--border-color);
            padding: 6px;
            display: flex;
            gap: 6px;
            overflow-x: auto;
            white-space: nowrap;
            margin-bottom: 20px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.03);
            scrollbar-width: thin;
        }

        .nav-mode-item {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 10px 18px;
            font-size: 14px;
            font-weight: 600;
            color: #64748b;
            border-radius: 8px;
            cursor: pointer;
            transition: all 0.2s ease;
            user-select: none;
            border: 1px solid transparent;
        }

        .nav-mode-item:hover {
            color: var(--brand-blue);
            background: #f1f5f9;
        }

        .nav-mode-item.active {
            color: #ffffff;
            background: linear-gradient(135deg, #0099e5 0%, #0284c7 100%);
            font-weight: 700;
            box-shadow: 0 2px 6px rgba(0, 153, 229, 0.35);
        }

        /* 現代卡片 */
        .card-modern {
            background: var(--surface);
            border-radius: 12px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05), 0 4px 12px rgba(15, 23, 42, 0.04);
            border: 1px solid var(--border-color);
            margin-bottom: 20px;
            overflow: hidden;
        }

        .card-modern-header {
            padding: 14px 20px;
            background: #ffffff;
            border-bottom: 1px solid var(--border-color);
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-wrap: wrap;
            gap: 12px;
        }

        .card-modern-title {
            font-size: 1.05rem;
            font-weight: 700;
            color: var(--brand-navy);
            margin: 0;
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .card-modern-body {
            padding: 20px;
        }

        /* 圖表容器 */
        .chart-wrapper {
            position: relative;
            min-height: 420px;
            width: 100%;
        }

        .pie-chart-wrapper {
            min-height: 380px;
            width: 100%;
        }

        /* 篩選標籤晶片 (Filter Stat Chip) */
        .filter-stat-chip {
            display: inline-flex;
            align-items: center;
            background: #e0f2fe;
            color: #0369a1;
            padding: 6px 14px;
            border-radius: 20px;
            font-size: 13px;
            font-weight: 700;
            gap: 8px;
            border: 1px solid #bae6fd;
        }

        .filter-stat-chip .btn-clear {
            background: none;
            border: none;
            color: #0369a1;
            cursor: pointer;
            padding: 0;
            font-size: 14px;
            line-height: 1;
            display: flex;
            align-items: center;
        }

        .filter-stat-chip .btn-clear:hover {
            color: #dc2626;
        }

        /* 搜尋與表格工具列 */
        .card-tools-group {
            display: flex;
            align-items: center;
            gap: 8px;
            flex-wrap: nowrap;
            margin-left: auto;
        }

        .search-box {
            position: relative;
            width: 250px;
            flex-shrink: 1;
        }

        .search-box input {
            padding-left: 36px;
            border-radius: 8px;
            border: 1px solid var(--border-color);
            font-size: 13px;
            height: 38px;
            width: 100%;
        }

        .search-box input:focus {
            border-color: var(--brand-blue);
            box-shadow: 0 0 0 3px rgba(2, 132, 199, 0.15);
        }

        .search-box .search-icon {
            position: absolute;
            left: 12px;
            top: 50%;
            transform: translateY(-50%);
            color: #94a3b8;
            font-size: 13px;
        }

        /* 行動端卡片式清單 (小螢幕免橫向捲動) */
        .mobile-card-list {
            display: flex;
            flex-direction: column;
            gap: 10px;
            padding: 12px;
        }

        .mobile-data-card {
            background: #ffffff;
            border: 1px solid var(--border-color);
            border-radius: 10px;
            padding: 12px 14px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
            transition: all 0.15s ease;
            position: relative;
        }

        .mobile-data-card:active {
            background-color: #f8fafc;
            transform: scale(0.99);
        }

        .card-row-top {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 8px;
        }

        .m-seq-badge {
            background: #f1f5f9;
            color: #64748b;
            font-size: 11px;
            font-weight: 700;
            min-width: 22px;
            height: 22px;
            border-radius: 6px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            padding: 0 4px;
            margin-right: 4px;
        }

        .card-fac-name {
            font-size: 0.98rem;
            font-weight: 700;
            color: var(--brand-navy);
            line-height: 1.35;
            margin-bottom: 8px;
            word-break: break-all;
        }

        .card-prop-tags {
            display: flex;
            flex-direction: column;
            gap: 5px;
            font-size: 12px;
            margin-bottom: 6px;
        }

        .prop-item {
            display: flex;
            align-items: center;
            flex-wrap: wrap;
            gap: 6px;
            color: #334155;
            line-height: 1.4;
        }

        .prop-label {
            color: #94a3b8;
            font-weight: 600;
            font-size: 11px;
            flex-shrink: 0;
        }

        .card-addr-row {
            font-size: 11px;
            color: #64748b;
            padding-top: 8px;
            margin-top: 4px;
            border-top: 1px dashed #e2e8f0;
            display: flex;
            align-items: flex-start;
            line-height: 1.4;
            word-break: break-all;
        }

        /* 現代明細表格 */
        .table-responsive-custom {
            border-radius: 8px;
            border: 1px solid var(--border-color);
            overflow-x: auto;
        }

        .modern-table {
            width: 100%;
            margin-bottom: 0;
            border-collapse: separate;
            border-spacing: 0;
        }

        .modern-table thead th {
            background: #f8fafc;
            color: #475569;
            font-size: 13px;
            font-weight: 700;
            padding: 12px 14px;
            border-bottom: 1px solid var(--border-color);
            white-space: nowrap;
            vertical-align: middle;
        }

        .modern-table tbody tr {
            transition: background-color 0.15s ease;
        }

        .modern-table tbody tr:hover {
            background-color: #f1f7ff;
        }

        .modern-table tbody td {
            padding: 12px 14px;
            font-size: 13px;
            color: #334155;
            border-bottom: 1px solid #f1f5f9;
            vertical-align: middle;
        }

        .badge-cno {
            background: #e0f2fe;
            color: #0284c7;
            font-weight: 700;
            padding: 4px 8px;
            border-radius: 6px;
            font-size: 12px;
            border: 1px solid #bae6fd;
            cursor: pointer;
            transition: all 0.15s ease;
        }

        .badge-cno:hover {
            background: #0284c7;
            color: #ffffff;
            text-decoration: none;
        }

                /* ========================================================
           自適應現代化底部分頁列 (Responsive Pagination Footer)
           解決小尺寸螢幕 (手機) 壅擠與按鈕折行難以點擊問題
           ======================================================== */
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

        /* 載入中骨架畫面 */
        .loading-mask {
            position: absolute;
            top: 0; left: 0; right: 0; bottom: 0;
            background: rgba(255, 255, 255, 0.85);
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            z-index: 50;
            border-radius: 12px;
        }

        .spinner-custom {
            width: 40px;
            height: 40px;
            border: 3px solid #e2e8f0;
            border-top-color: var(--brand-blue);
            border-radius: 50%;
            animation: spin 0.8s linear infinite;
        }

        @keyframes spin {
            to { transform: rotate(360deg); }
        }

        /* 列印樣式 */
        @media print {
            .no-print, .top-navbar, .nav-mode-bar, .pagination-footer, .btn-group, .search-box {
                display: none !important;
            }
            body {
                background: #ffffff;
            }
            .container-fluid-custom {
                max-width: 100% !important;
                padding: 0 !important;
            }
            .card-modern {
                box-shadow: none !important;
                border: 1px solid #ccc !important;
                break-inside: avoid;
            }
        }

        @media (max-width: 767.98px) {
            .container-fluid-custom {
                padding: 12px 10px 40px 10px;
            }
            .top-navbar {
                padding: 0 12px;
            }
            .navbar-brand-title {
                font-size: 1rem;
            }
            .kpi-row {
                grid-template-columns: 1fr 1fr;
                gap: 10px;
            }
            .kpi-card {
                padding: 12px 14px;
            }
            .kpi-icon-box {
                width: 40px;
                height: 40px;
                font-size: 1.15rem;
            }
            .kpi-val {
                font-size: 1.45rem;
            }
            .chart-wrapper {
                min-height: 320px;
            }
            .card-modern-header {
                padding: 10px 12px;
                gap: 8px;
            }
            .card-tools-group {
                width: 100%;
                margin-top: 4px;
                display: flex;
                align-items: center;
                gap: 6px;
                flex-wrap: nowrap;
            }
            .search-box {
                flex: 1;
                width: auto;
                min-width: 110px;
            }
            .search-box input {
                height: 36px;
                font-size: 12px;
                padding-left: 28px;
            }
            .search-box .search-icon {
                left: 9px;
                font-size: 11px;
            }
            .tool-page-select {
                height: 36px !important;
                width: 82px !important;
                font-size: 12px !important;
                padding: 0 4px !important;
                flex-shrink: 0;
            }
            .tool-export-btn {
                height: 36px !important;
                font-size: 12px !important;
                padding: 0 10px !important;
                flex-shrink: 0;
            }
            .pagination-bar {
                flex-direction: column;
                align-items: center;
                gap: 8px;
                text-align: center;
            }
        }
    </style>
</head>
<body>
    <div id="app" v-cloak>
        <!-- 頂部置頂導覽列 -->
        <header class="top-navbar no-print">
            <div class="d-flex align-items-center">
                <a href="../MainPage.aspx" class="nav-btn mr-2" title="返回系統主頁">
                    <i class="fas fa-chevron-left"></i>
                    <span class="d-none d-sm-inline">回主頁</span>
                </a>
                <div class="navbar-brand-title">
                    <i class="fas fa-industry text-white"></i>
                    <span>公私場所逸散源統計分析</span>
                    <span class="badge badge-light text-dark font-weight-bold ml-1 d-none d-md-inline" style="font-size: 0.75rem;">FAC-STAT</span>
                </div>
            </div>

            <div class="d-flex align-items-center">
                <button type="button" class="nav-btn bg-white text-dark shadow-sm" v-on:click="printPage" title="列印報表">
                    <i class="fas fa-print"></i>
                    <span class="d-none d-sm-inline">列印</span>
                </button>
            </div>
        </header>

        <!-- 主作業容器 -->
        <main class="container-fluid-custom">
            <!-- 1. 頂部四大 KPI 指標卡片 -->
            <section class="kpi-row no-print">
                <div class="kpi-card blue">
                    <div class="kpi-icon-box">
                        <i class="fas fa-building"></i>
                    </div>
                    <div class="kpi-info">
                        <div class="kpi-val">{{ kpis.TotalFac.toLocaleString() }}</div>
                        <div class="kpi-label">公私場所總數 (家)</div>
                    </div>
                </div>

                <div class="kpi-card green">
                    <div class="kpi-icon-box">
                        <i class="fas fa-clipboard-check"></i>
                    </div>
                    <div class="kpi-info">
                        <div class="kpi-val">{{ kpis.RegFac.toLocaleString() }}</div>
                        <div class="kpi-label">列管場所數量 (家)</div>
                    </div>
                </div>

                <div class="kpi-card amber">
                    <div class="kpi-icon-box">
                        <i class="fas fa-cogs"></i>
                    </div>
                    <div class="kpi-info">
                        <div class="kpi-val">{{ kpis.TotalProcess.toLocaleString() }}</div>
                        <div class="kpi-label">列管製程總數 (項)</div>
                    </div>
                </div>

                <div class="kpi-card indigo">
                    <div class="kpi-icon-box">
                        <i class="fas fa-map-marked-alt"></i>
                    </div>
                    <div class="kpi-info">
                        <div class="kpi-val">{{ kpis.TotalTowns.toLocaleString() }}</div>
                        <div class="kpi-label">涵蓋行政區數 (區)</div>
                    </div>
                </div>
            </section>

            <!-- 2. 六大維度切換頁籤 -->
            <nav class="nav-mode-bar no-print">
                <div v-for="dim in dimensionList" :key="dim.id" 
                     class="nav-mode-item" :class="{ 'active': currentDim === dim.id }"
                     v-on:click="switchDimension(dim.id)">
                    <i :class="dim.icon"></i>
                    <span>{{ dim.name }}</span>
                    <span v-if="currentDim === dim.id && chartData.TotalCount" class="badge badge-light text-primary font-weight-bold ml-1">
                        {{ chartData.TotalCount }}
                    </span>
                </div>
            </nav>

            <!-- 3. 雙圖表展示區塊 (主柱狀/條狀圖 + 佔比圓餅圖) -->
            <div class="row">
                <!-- 左側主圖表 (7 欄寬度) -->
                <div class="col-xl-8 col-lg-7 col-12 mb-3">
                    <div class="card-modern h-100 position-relative">
                        <div v-if="isChartLoading" class="loading-mask">
                            <div class="spinner-custom"></div>
                            <small class="text-muted mt-2 font-weight-bold">統計圖表載入中...</small>
                        </div>

                        <div class="card-modern-header">
                            <div class="card-modern-title">
                                <i class="fas fa-chart-bar text-primary"></i>
                                <span>{{ currentDimObj.name }}統計長條圖</span>
                                <small class="text-muted font-weight-normal d-none d-sm-inline">(點擊柱體可下鑽過濾明細)</small>
                            </div>
                            <div class="btn-group btn-group-sm" role="group">
                                <button type="button" class="btn btn-outline-secondary" 
                                        :class="{ 'active': chartType === 'column' }"
                                        v-on:click="changeChartType('column')">
                                    <i class="fas fa-chart-column mr-1"></i>直條
                                </button>
                                <button type="button" class="btn btn-outline-secondary" 
                                        :class="{ 'active': chartType === 'bar' }"
                                        v-on:click="changeChartType('bar')">
                                    <i class="fas fa-bars mr-1"></i>橫條
                                </button>
                            </div>
                        </div>

                        <div class="card-modern-body p-2">
                            <div id="mainChart" class="chart-wrapper"></div>
                        </div>
                    </div>
                </div>

                <!-- 右側佔比圓餅/甜甜圈圖 (5 欄寬度) -->
                <div class="col-xl-4 col-lg-5 col-12 mb-3">
                    <div class="card-modern h-100 position-relative">
                        <div v-if="isChartLoading" class="loading-mask">
                            <div class="spinner-custom"></div>
                            <small class="text-muted mt-2 font-weight-bold">佔比分析載入中...</small>
                        </div>

                        <div class="card-modern-header">
                            <div class="card-modern-title">
                                <i class="fas fa-chart-pie text-success"></i>
                                <span>各項目佔比分析</span>
                            </div>
                            <span class="badge badge-info" style="font-size: 0.8rem;">
                                共 {{ chartData.Data ? chartData.Data.length : 0 }} 類別
                            </span>
                        </div>

                        <div class="card-modern-body p-2">
                            <div id="pieChart" class="pie-chart-wrapper"></div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- 4. 下鑽明細清單作業卡片 -->
            <section class="card-modern position-relative" id="detailSection">
                <div v-if="isDetailLoading" class="loading-mask">
                    <div class="spinner-custom"></div>
                    <small class="text-muted mt-2 font-weight-bold">公私場所清單載入中...</small>
                </div>

                <div class="card-modern-header">
                    <div class="d-flex align-items-center flex-wrap gap-2">
                        <div class="card-modern-title mr-3">
                            <i class="fas fa-list-ul text-primary"></i>
                            <span>{{ currentDimObj.name }}詳細清單</span>
                        </div>

                        <!-- 篩選條件提示晶片 -->
                        <div v-if="currentFilter !== 'ALL'" class="filter-stat-chip">
                            <span><i class="fas fa-filter mr-1"></i>當前過濾：<strong>{{ currentFilter }}</strong></span>
                            <span class="badge badge-light text-primary font-weight-bold ml-1">{{ filteredList.length }} 筆</span>
                            <button type="button" class="btn-clear ml-1" v-on:click="resetFilter" title="清除篩選，檢視全部">
                                <i class="fas fa-times-circle"></i>
                            </button>
                        </div>
                        <div v-else class="text-muted font-weight-bold" style="font-size: 13px;">
                            (共 {{ filteredList.length }} 筆)
                        </div>
                    </div>

                    <!-- 搜尋框、每頁筆數與匯出按鈕：嚴格同一行水平排列不折行 -->
                    <div class="card-tools-group">
                        <div class="search-box">
                            <i class="fas fa-search search-icon"></i>
                            <input type="text" class="form-control form-control-sm" 
                                   v-model="searchKeyword" 
                                   placeholder="搜尋管制編號、名稱、地址..." />
                        </div>
                        <select class="form-control form-control-sm tool-page-select" style="width: 105px; height: 38px; flex-shrink: 0;" v-model="pageSize">
                            <option :value="10">每頁 10 筆</option>
                            <option :value="25">每頁 25 筆</option>
                            <option :value="50">每頁 50 筆</option>
                            <option :value="100">每頁 100 筆</option>
                        </select>
                        <button type="button" class="btn btn-sm btn-outline-success font-weight-bold text-nowrap d-inline-flex align-items-center justify-content-center tool-export-btn" style="height: 38px; flex-shrink: 0; padding: 0 14px; gap: 6px;" v-on:click="exportExcel" title="匯出 Excel 報表">
                            <i class="fas fa-file-excel"></i>
                            <span>匯出</span>
                        </button>
                    </div>
                </div>

                <div class="card-modern-body p-0">
                    <!-- 電腦端/寬螢幕：標準資料表格 (>= 768px 顯示) -->
                    <div class="table-responsive-custom d-none d-md-block">
                        <table class="modern-table">
                            <thead>
                                <tr>
                                    <th style="width: 50px; text-align: center;">序</th>
                                    <th style="width: 110px;">管制編號</th>
                                    <th>公私場所名稱</th>
                                    <th style="width: 90px; text-align: center;">行政區</th>
                                    <!-- 依維度動態切換欄位 -->
                                    <template v-if="currentDim === 'process' || currentDim === 'licyear'">
                                        <th style="width: 100px;">製程編號</th>
                                        <th>製程名稱</th>
                                        <th style="width: 90px; text-align: center;">核發年度</th>
                                        <th>許可證號</th>
                                    </template>
                                    <template v-else-if="currentDim === 'industrial'">
                                        <th style="width: 160px;">行業別</th>
                                        <th style="width: 100px;">行業代碼</th>
                                        <th>地址</th>
                                    </template>
                                    <template v-else-if="currentDim === 'group'">
                                        <th style="width: 110px; text-align: center;">分級組別</th>
                                        <th>地址</th>
                                    </template>
                                    <template v-else>
                                        <th style="width: 100px; text-align: center;">列管狀況</th>
                                        <th style="width: 100px; text-align: center;">分級組別</th>
                                        <th>地址</th>
                                    </template>
                                    <th style="width: 80px; text-align: center;">動作</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr v-if="pagedList.length === 0">
                                    <td :colspan="tableColCount" class="text-center py-4 text-muted">
                                        <i class="fas fa-inbox fa-2x mb-2 d-block text-secondary"></i>
                                        查無相符之公私場所資料
                                    </td>
                                </tr>
                                <tr v-for="(item, idx) in pagedList" :key="idx">
                                    <td style="text-align: center;" class="text-muted font-weight-bold">
                                        {{ (currentPage - 1) * pageSize + idx + 1 }}
                                    </td>
                                    <td>
                                        <span class="badge-cno" v-on:click="openFacModal(item.FAC_ID)" title="檢視詳細資訊">
                                            {{ item.管制編號 || '-' }}
                                        </span>
                                    </td>
                                    <td class="font-weight-bold text-dark">
                                        {{ item.場所名稱 || item.名稱 || '-' }}
                                    </td>
                                    <td style="text-align: center;">
                                        <span class="badge badge-light border text-secondary font-weight-normal px-2 py-1">
                                            {{ item.行政區 || '-' }}
                                        </span>
                                    </td>

                                    <!-- 動態維度欄位內容 -->
                                    <template v-if="currentDim === 'process' || currentDim === 'licyear'">
                                        <td>{{ item.製程編號 || '-' }}</td>
                                        <td>{{ item.製程名稱 || '-' }}</td>
                                        <td style="text-align: center;">
                                            <span class="badge badge-secondary px-2 py-1">
                                                {{ item.核發年度 ? item.核發年度 + '年' : '-' }}
                                            </span>
                                        </td>
                                        <td><code>{{ item.許可證號 || '-' }}</code></td>
                                    </template>
                                    <template v-else-if="currentDim === 'industrial'">
                                        <td>{{ item.行業別 || '-' }}</td>
                                        <td><code>{{ item.行業代碼 || '-' }}</code></td>
                                        <td class="text-muted">{{ item.地址 || '-' }}</td>
                                    </template>
                                    <template v-else-if="currentDim === 'group'">
                                        <td style="text-align: center;">
                                            <span class="badge badge-primary px-2 py-1">{{ item.分級組別 || '-' }}</span>
                                        </td>
                                        <td class="text-muted">{{ item.地址 || '-' }}</td>
                                    </template>
                                    <template v-else>
                                        <td style="text-align: center;">
                                            <span class="badge" :class="item.列管狀況 === '列管' ? 'badge-success' : 'badge-secondary'">
                                                {{ item.列管狀況 || '-' }}
                                            </span>
                                        </td>
                                        <td style="text-align: center;">
                                            <span class="badge badge-light border text-dark">{{ item.分級組別 || '-' }}</span>
                                        </td>
                                        <td class="text-muted">{{ item.地址 || '-' }}</td>
                                    </template>

                                    <td style="text-align: center;">
                                        <button type="button" class="btn btn-sm btn-outline-primary py-0 px-2" 
                                                v-on:click="openFacModal(item.FAC_ID)" title="檢視詳細資料">
                                            <i class="fas fa-eye"></i>
                                        </button>
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>

                    <!-- 行動端/小螢幕：卡片式清單 (< 768px 顯示，徹底避免橫移視窗) -->
                    <div class="mobile-card-list d-md-none">
                        <div v-if="pagedList.length === 0" class="text-center py-4 text-muted bg-white rounded">
                            <i class="fas fa-inbox fa-2x mb-2 d-block text-secondary"></i>
                            查無相符之公私場所資料
                        </div>

                        <div v-for="(item, idx) in pagedList" :key="'m-' + idx" 
                             class="mobile-data-card" 
                             v-on:click="openFacModal(item.FAC_ID)">
                            <!-- 卡片頂部：序號、管制編號、行政區、詳細動作 -->
                            <div class="card-row-top">
                                <div class="d-flex align-items-center">
                                    <span class="m-seq-badge">{{ (currentPage - 1) * pageSize + idx + 1 }}</span>
                                    <span class="badge-cno" title="檢視詳細資訊">
                                        {{ item.管制編號 || '-' }}
                                    </span>
                                </div>
                                <div class="d-flex align-items-center">
                                    <span class="badge badge-light border text-secondary font-weight-normal px-2 py-1 mr-1">
                                        {{ item.行政區 || '-' }}
                                    </span>
                                    <button type="button" class="btn btn-sm btn-outline-primary py-0 px-2" title="檢視詳細資料">
                                        <i class="fas fa-eye"></i>
                                    </button>
                                </div>
                            </div>

                            <!-- 場所名稱 -->
                            <div class="card-fac-name">
                                {{ item.場所名稱 || item.名稱 || '-' }}
                            </div>

                            <!-- 動態維度屬性標籤 -->
                            <div class="card-prop-tags">
                                <!-- 製程 / 年度 -->
                                <template v-if="currentDim === 'process' || currentDim === 'licyear'">
                                    <div class="prop-item">
                                        <span class="prop-label">製程：</span>
                                        <strong>{{ item.製程編號 }} {{ item.製程名稱 }}</strong>
                                    </div>
                                    <div class="prop-item" v-if="item.核發年度">
                                        <span class="prop-label">年度：</span>
                                        <span class="badge badge-secondary px-2 py-1">{{ item.核發年度 }}年</span>
                                    </div>
                                    <div class="prop-item" v-if="item.許可證號">
                                        <span class="prop-label">證號：</span>
                                        <code>{{ item.許可證號 }}</code>
                                    </div>
                                </template>

                                <!-- 行業別 -->
                                <template v-else-if="currentDim === 'industrial'">
                                    <div class="prop-item">
                                        <span class="prop-label">行業：</span>
                                        <strong>{{ item.行業別 || '-' }}</strong>
                                        <code v-if="item.行業代碼">({{ item.行業代碼 }})</code>
                                    </div>
                                </template>

                                <!-- 分級組別 -->
                                <template v-else-if="currentDim === 'group'">
                                    <div class="prop-item">
                                        <span class="prop-label">分級：</span>
                                        <span class="badge badge-primary px-2 py-1">{{ item.分級組別 || '-' }}</span>
                                    </div>
                                </template>

                                <!-- 列管狀況 -->
                                <template v-else>
                                    <div class="prop-item">
                                        <span class="prop-label">狀況：</span>
                                        <span class="badge" :class="item.列管狀況 === '列管' ? 'badge-success' : 'badge-secondary'">
                                            {{ item.列管狀況 || '-' }}
                                        </span>
                                        <span v-if="item.分級組別" class="badge badge-light border text-dark ml-1">
                                            {{ item.分級組別 }}
                                        </span>
                                    </div>
                                </template>
                            </div>

                            <!-- 地址資訊 (若有) -->
                            <div class="card-addr-row" v-if="item.地址">
                                <i class="fas fa-map-marker-alt text-danger mr-1" style="font-size: 11px; margin-top: 2px;"></i>
                                <span>{{ item.地址 }}</span>
                            </div>
                        </div>
                    </div>

                    <!-- 自適應底部分頁導覽列 (Responsive Pagination Footer) -->
                    <div v-if="totalCount > 0" class="pagination-footer no-print">
                        <div class="pagination-footer-info">
                            顯示第 <strong class="text-dark">{{ totalCount === 0 ? 0 : (currentPage - 1) * pageSize + 1 }}</strong> 至 <strong class="text-dark">{{ Math.min(currentPage * pageSize, totalCount) }}</strong> 筆，共 <strong class="text-dark">{{ totalCount }}</strong> 筆
                        </div>
                        <div class="pagination-action-group">
                            <button type="button" class="btn-page-ctrl btn-edge" :disabled="currentPage <= 1" v-on:click="changePage(1)" title="第一頁">
                                <i class="fas fa-angle-double-left"></i>
                                <span class="d-none d-md-inline ml-1">首頁</span>
                            </button>
                            <button type="button" class="btn-page-ctrl btn-step" :disabled="currentPage <= 1" v-on:click="changePage(currentPage - 1)" title="上一頁">
                                <i class="fas fa-chevron-left mr-1"></i>
                                <span>上一頁</span>
                            </button>
                            <div class="page-indicator-pill" title="目前頁次 / 總頁數">
                                <span>{{ currentPage }}</span>
                                <span class="mx-1 text-muted" style="opacity: 0.5; font-weight: normal;">/</span>
                                <span>{{ totalPages || 1 }}</span>
                            </div>
                            <button type="button" class="btn-page-ctrl btn-step" :disabled="currentPage >= totalPages" v-on:click="changePage(currentPage + 1)" title="下一頁">
                                <span>下一頁</span>
                                <i class="fas fa-chevron-right ml-1"></i>
                            </button>
                            <button type="button" class="btn-page-ctrl btn-edge" :disabled="currentPage >= totalPages" v-on:click="changePage(totalPages)" title="最後一頁">
                                <span class="d-none d-md-inline ml-1">末頁</span>
                                <i class="fas fa-angle-double-right"></i>
                            </button>
                        </div>
                    </div>
                </div>
            </section>
        </main>

        <!-- 5. 公私場所詳細資訊彈窗 (Modal) -->
        <div class="modal fade" id="facModal" tabindex="-1" role="dialog" aria-hidden="true">
            <div class="modal-dialog modal-lg modal-dialog-centered" role="document">
                <div class="modal-content shadow-lg border-0" style="border-radius: 12px; overflow: hidden;">
                    <div class="modal-header text-white" style="background: linear-gradient(135deg, #0099e5 0%, #0284c7 100%);">
                        <h5 class="modal-title font-weight-bold">
                            <i class="fas fa-industry mr-2"></i>公私場所詳細資訊
                        </h5>
                        <button type="button" class="close text-white" data-dismiss="modal" aria-label="Close">
                            <span aria-hidden="true">&times;</span>
                        </button>
                    </div>

                    <div class="modal-body p-4" v-if="modalFac">
                        <!-- 基本資料卡 -->
                        <div class="card mb-3 border-0 bg-light">
                            <div class="card-body p-3">
                                <div class="row">
                                    <div class="col-md-6 mb-2">
                                        <small class="text-muted font-weight-bold d-block">管制編號：</small>
                                        <span class="font-weight-bold text-primary font-size-lg">{{ modalFac.C_NO || '-' }}</span>
                                    </div>
                                    <div class="col-md-6 mb-2">
                                        <small class="text-muted font-weight-bold d-block">公私場所名稱：</small>
                                        <span class="font-weight-bold text-dark">{{ modalFac.FAC_NAME || '-' }}</span>
                                    </div>
                                    <div class="col-md-6 mb-2">
                                        <small class="text-muted font-weight-bold d-block">行政區 / 地址：</small>
                                        <span>【{{ modalFac.TOWN || '未填' }}】 {{ modalFac.ADDR || '-' }}</span>
                                    </div>
                                    <div class="col-md-6 mb-2">
                                        <small class="text-muted font-weight-bold d-block">行業別：</small>
                                        <span>{{ modalFac.IndustryName || modalFac.INDUSTRIAL_Code1 || '-' }}</span>
                                    </div>
                                    <div class="col-md-6 mb-2">
                                        <small class="text-muted font-weight-bold d-block">列管狀況：</small>
                                        <span class="badge" :class="modalFac.FAC_TYPE === '列管' ? 'badge-success' : 'badge-secondary'">
                                            {{ modalFac.FAC_TYPE || '-' }}
                                        </span>
                                    </div>
                                    <div class="col-md-6 mb-2">
                                        <small class="text-muted font-weight-bold d-block">分級組別：</small>
                                        <span class="badge badge-info">{{ modalFac.FAC_Group || '-' }}</span>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- 製程清單 -->
                        <div class="d-flex align-items-center justify-content-between mb-2">
                            <h6 class="font-weight-bold text-dark mb-0">
                                <i class="fas fa-cogs text-primary mr-1"></i>登記製程與許可證清單
                            </h6>
                            <span class="badge badge-light border">共 {{ modalProcesses.length }} 項製程</span>
                        </div>

                        <div class="table-responsive" style="max-height: 250px; overflow-y: auto;">
                            <table class="table table-sm table-bordered table-hover mb-0" style="font-size: 13px;">
                                <thead class="thead-light">
                                    <tr>
                                        <th style="width: 80px;">製程編號</th>
                                        <th>製程代碼</th>
                                        <th>製程名稱</th>
                                        <th style="width: 80px; text-align: center;">核發年度</th>
                                        <th>許可證號</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr v-if="modalProcesses.length === 0">
                                        <td colspan="5" class="text-center text-muted py-3">查無登記製程資料</td>
                                    </tr>
                                    <tr v-for="(p, pIdx) in modalProcesses" :key="pIdx">
                                        <td class="font-weight-bold">{{ p.Process_NO || '-' }}</td>
                                        <td>{{ p.Process_Code || '-' }}</td>
                                        <td>{{ p.Process_Name || '-' }}</td>
                                        <td style="text-align: center;">
                                            <span class="badge badge-secondary">{{ p.Lic_Year ? p.Lic_Year + '年' : '-' }}</span>
                                        </td>
                                        <td><code>{{ p.Process_Lic || '-' }}</code></td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>

                    <div class="modal-footer bg-light p-2">
                        <button type="button" class="btn btn-secondary btn-sm" data-dismiss="modal">關閉</button>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- 本地腳本庫依賴 -->
    <script src="../Scripts/jquery.min.js"></script>
    <script src="../Scripts/bootstrap.bundle.min.js"></script>
    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>
    <script src="../Scripts/highcharts.js"></script>

    <script type="text/javascript">
        (function () {
            const { createApp } = Vue;

            createApp({
                data() {
                    return {
                        // 頂部 KPI
                        kpis: {
                            TotalFac: 0,
                            RegFac: 0,
                            TotalProcess: 0,
                            TotalTowns: 0
                        },
                        // 六大維度定義
                        dimensionList: [
                            { id: 'factype', name: '列管狀況', icon: 'fas fa-shield-alt' },
                            { id: 'process', name: '製程名稱', icon: 'fas fa-cogs' },
                            { id: 'licyear', name: '核發年度', icon: 'fas fa-calendar-alt' },
                            { id: 'town', name: '行政區分佈', icon: 'fas fa-map-marker-alt' },
                            { id: 'industrial', name: '行業別統計', icon: 'fas fa-industry' },
                            { id: 'group', name: '分級組別', icon: 'fas fa-layer-group' }
                        ],
                        currentDim: 'factype',
                        chartType: 'column', // 'column' or 'bar'
                        isRefreshing: false,
                        isChartLoading: false,
                        isDetailLoading: false,

                        // 圖表數據
                        chartData: {
                            Dimension: 'factype',
                            TotalCount: 0,
                            Data: []
                        },
                        mainChartInstance: null,
                        pieChartInstance: null,

                        // 明細資料與篩選
                        currentFilter: 'ALL',
                        rawDetailList: [],
                        searchKeyword: '',
                        currentPage: 1,
                        pageSize: 25,

                        // 彈窗公私場所詳細
                        modalFac: null,
                        modalProcesses: []
                    };
                },
                computed: {
                    currentDimObj() {
                        const found = this.dimensionList.find(d => d.id === this.currentDim);
                        return found || this.dimensionList[0];
                    },
                    filteredList() {
                        if (!this.searchKeyword || !this.searchKeyword.trim()) {
                            return this.rawDetailList;
                        }
                        const kw = this.searchKeyword.trim().toLowerCase();
                        return this.rawDetailList.filter(item => {
                            return Object.values(item).some(val => {
                                return String(val).toLowerCase().indexOf(kw) !== -1;
                            });
                        });
                    },
                    totalCount() {
                        return this.filteredList.length;
                    },
                    totalPages() {
                        return Math.ceil(this.totalCount / this.pageSize) || 1;
                    },
                    pagedList() {
                        const start = (this.currentPage - 1) * this.pageSize;
                        return this.filteredList.slice(start, start + this.pageSize);
                    },
                    tableColCount() {
                        if (this.currentDim === 'process' || this.currentDim === 'licyear') return 9;
                        if (this.currentDim === 'industrial') return 8;
                        if (this.currentDim === 'group') return 7;
                        return 8;
                    }
                },
                watch: {
                    searchKeyword() {
                        this.currentPage = 1;
                    },
                    pageSize() {
                        this.currentPage = 1;
                    }
                },
                mounted() {
                    this.loadKpis();
                    this.loadDimension(this.currentDim);
                },
                methods: {
                    // 載入頂部四大 KPI
                    loadKpis() {
                        axios.get('Charts.aspx?action=getkpis')
                            .then(res => {
                                if (res.data && res.data.Success) {
                                    this.kpis = res.data.Data;
                                }
                            })
                            .catch(err => {
                                console.error('載入 KPI 失敗：', err);
                            });
                    },

                    // 切換維度
                    switchDimension(dimId) {
                        if (this.currentDim === dimId) return;
                        this.currentDim = dimId;
                        this.currentFilter = 'ALL';
                        this.searchKeyword = '';
                        this.currentPage = 1;
                        this.loadDimension(dimId);
                    },

                    // 載入當前維度圖表與明細
                    loadDimension(dimId) {
                        this.loadChartData(dimId);
                        this.loadDetailData(dimId, this.currentFilter);
                    },

                    // 取得圖表匯總數據
                    loadChartData(dimId) {
                        this.isChartLoading = true;
                        axios.get('Charts.aspx?action=getchartdata&dim=' + encodeURIComponent(dimId))
                            .then(res => {
                                this.isChartLoading = false;
                                if (res.data && res.data.Success) {
                                    this.chartData = res.data;
                                    this.renderCharts();
                                }
                            })
                            .catch(err => {
                                this.isChartLoading = false;
                                console.error('載入圖表數據失敗：', err);
                            });
                    },

                    // 取得明細清單
                    loadDetailData(dimId, filter) {
                        this.isDetailLoading = true;
                        axios.get('Charts.aspx?action=getdetail&dim=' + encodeURIComponent(dimId) + '&filter=' + encodeURIComponent(filter))
                            .then(res => {
                                this.isDetailLoading = false;
                                if (res.data && res.data.Success) {
                                    this.rawDetailList = res.data.Data || [];
                                    this.currentPage = 1;
                                }
                            })
                            .catch(err => {
                                this.isDetailLoading = false;
                                console.error('載入明細清單失敗：', err);
                            });
                    },

                    // 繪製/更新 Highcharts 圖表
                    renderCharts() {
                        if (typeof Highcharts === 'undefined') return;

                        const vm = this;
                        const items = this.chartData.Data || [];
                        const categories = items.map(x => x.Name);
                        const seriesData = items.map(x => {
                            return {
                                name: x.Name,
                                y: x.Count,
                                percent: x.Percent
                            };
                        });

                        // 1. 繪製主柱狀圖 (Column / Bar)
                        this.mainChartInstance = Highcharts.chart('mainChart', {
                            chart: {
                                type: this.chartType,
                                backgroundColor: 'transparent'
                            },
                            title: {
                                text: ''
                            },
                            credits: { enabled: false },
                            xAxis: {
                                categories: categories,
                                crosshair: true,
                                labels: {
                                    style: {
                                        fontSize: '12px',
                                        fontFamily: '微軟正黑體'
                                    },
                                    rotation: this.chartType === 'column' && categories.length > 8 ? -35 : 0
                                }
                            },
                            yAxis: {
                                min: 0,
                                title: {
                                    text: '數量 (家 / 項)',
                                    style: { fontSize: '13px', fontWeight: 'bold' }
                                }
                            },
                            legend: { enabled: false },
                            tooltip: {
                                headerFormat: '<span style="font-size:12px; font-weight:bold;">{point.key}</span><br/>',
                                pointFormat: '<span style="color:{point.color}">\u25CF</span> 數量：<b>{point.y}</b> 家 (佔比 {point.percent}%)'
                            },
                            plotOptions: {
                                series: {
                                    borderRadius: 4,
                                    cursor: 'pointer',
                                    colorByPoint: true,
                                    dataLabels: {
                                        enabled: true,
                                        format: '{point.y}',
                                        style: {
                                            fontWeight: 'bold',
                                            color: '#0f172a'
                                        }
                                    },
                                    point: {
                                        events: {
                                            click: function () {
                                                vm.applyFilter(this.category || this.name);
                                            }
                                        }
                                    }
                                }
                            },
                            series: [{
                                name: this.currentDimObj.name,
                                data: seriesData
                            }]
                        });

                        // 2. 繪製圓餅/甜甜圈佔比圖 (Donut)
                        const pieData = items.map(x => {
                            return {
                                name: x.Name,
                                y: x.Count,
                                percent: x.Percent
                            };
                        });

                        this.pieChartInstance = Highcharts.chart('pieChart', {
                            chart: {
                                type: 'pie',
                                backgroundColor: 'transparent'
                            },
                            title: {
                                text: ''
                            },
                            credits: { enabled: false },
                            tooltip: {
                                pointFormat: '<b>{point.y}</b> 家 (<b>{point.percentage:.1f}%</b>)'
                            },
                            plotOptions: {
                                pie: {
                                    innerSize: '55%', // 甜甜圈樣式
                                    allowPointSelect: true,
                                    cursor: 'pointer',
                                    dataLabels: {
                                        enabled: true,
                                        format: '<b>{point.name}</b>: {point.percentage:.1f} %',
                                        style: { fontSize: '11px' }
                                    },
                                    point: {
                                        events: {
                                            click: function () {
                                                vm.applyFilter(this.name);
                                            }
                                        }
                                    }
                                }
                            },
                            series: [{
                                name: '佔比',
                                colorByPoint: true,
                                data: pieData
                            }]
                        });
                    },

                    // 切換直條 / 橫條圖
                    changeChartType(type) {
                        if (this.chartType === type) return;
                        this.chartType = type;
                        this.renderCharts();
                    },

                    // 點擊圖表柱位 / 扇形執行下鑽過濾
                    applyFilter(filterName) {
                        if (!filterName) return;
                        this.currentFilter = filterName;
                        this.loadDetailData(this.currentDim, filterName);

                        // 平滑捲動至下方明細清單
                        const el = document.getElementById('detailSection');
                        if (el) {
                            el.scrollIntoView({ behavior: 'smooth', block: 'start' });
                        }
                    },

                    // 清除過濾條件
                    resetFilter() {
                        this.currentFilter = 'ALL';
                        this.loadDetailData(this.currentDim, 'ALL');
                    },

                    // 分頁跳轉
                    changePage(p) {
                        if (p < 1 || p > this.totalPages) return;
                        this.currentPage = p;
                    },

                    // 開啟單一公私場所詳細 Modal
                    openFacModal(facId) {
                        if (!facId) return;
                        this.modalFac = null;
                        this.modalProcesses = [];

                        axios.get('Charts.aspx?action=getfacinfo&facid=' + encodeURIComponent(facId))
                            .then(res => {
                                if (res.data && res.data.Success) {
                                    this.modalFac = res.data.Fac;
                                    this.modalProcesses = res.data.Processes || [];
                                    $('#facModal').modal('show');
                                } else {
                                    alert(res.data ? res.data.Message : '無法讀取公私場所資料');
                                }
                            })
                            .catch(err => {
                                console.error('讀取公私場所詳細失敗：', err);
                                alert('連線伺服器失敗，請稍後再試');
                            });
                    },

                    // 匯出當前維度明細 Excel
                    exportExcel() {
                        const url = 'Charts.aspx?action=exportexcel&dim=' + 
                                    encodeURIComponent(this.currentDim) + 
                                    '&filter=' + encodeURIComponent(this.currentFilter);
                        window.open(url, '_blank');
                    },

                    // 重新整理全部
                    reloadAll() {
                        this.isRefreshing = true;
                        this.loadKpis();
                        this.loadDimension(this.currentDim);
                        setTimeout(() => {
                            this.isRefreshing = false;
                        }, 800);
                    },

                    // 列印頁面
                    printPage() {
                        window.print();
                    }
                }
            }).mount('#app');
        })();
    </script>
</body>
</html>
