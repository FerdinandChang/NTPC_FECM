﻿<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Case_Sum.aspx.cs" Inherits="NTPC_FEC.Case.Case_Sum" %>

<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定溢散源管理平台 - 公私場所巡查案件統計</title>

    <!-- 專屬 Favicon -->
    <link rel="shortcut icon" href="../favicon.ico" type="image/x-icon" />

    <!-- Bootstrap 4 & FontAwesome 本地化樣式庫 -->
    <link rel="stylesheet" href="../Content/bootstrap.min.css" />
    <link rel="stylesheet" href="../Content/fontawesome/css/all.min.css" />

    <style>
        :root {
            --brand-primary: #0099e5;     /* 新北天空青藍 */
            --brand-navy: #0f172a;        /* 海軍深藍文字 */
            --brand-blue: #0284c7;        /* 科技藍按鈕 */
            --brand-dark-blue: #0b1f7d;   /* 海軍深藍標籤 */
            --bg-canvas: #f8fafc;         /* 頁面灰底 */
            --surface: #ffffff;           /* 卡片純白底色 */
            --border-color: #e2e8f0;      /* 邊框線條 */
            --text-main: #0f172a;         /* 內文主要文字 */
            --text-muted: #64748b;        /* 次要說明文字 */
            --success-color: #10b981;     /* 綠色合格 */
            --warning-color: #f59e0b;     /* 橙黃輕微缺失 */
            --danger-color: #ef4444;      /* 紅色嚴重缺失 */
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

        /* 頂部品牌導覽列 (自適應流體字型、零折行、全尺寸適配) */
        .top-navbar {
            background: linear-gradient(135deg, #0099e5 0%, #0284c7 100%);
            color: #ffffff;
            height: 56px;
            display: flex;
            align-items: center;
            justify-content: flex-start;
            padding: 0 16px;
            box-shadow: 0 2px 10px rgba(0, 153, 229, 0.25);
            position: sticky;
            top: 0;
            z-index: 1020;
            white-space: nowrap;
            flex-wrap: nowrap;
        }

        .nav-brand-group {
            display: inline-flex;
            align-items: center;
            flex-shrink: 1;
            min-width: 0;
            overflow: hidden;
            white-space: nowrap;
        }

        .navbar-brand-title {
            font-size: clamp(0.85rem, 2.5vw, 1.15rem);
            font-weight: 700;
            display: inline-flex;
            align-items: center;
            gap: 6px;
            color: #ffffff;
            text-decoration: none;
            letter-spacing: 0.3px;
            white-space: nowrap;
            min-width: 0;
        }

        .navbar-brand-title:hover {
            color: #ffffff;
            text-decoration: none;
        }

        .brand-text {
            white-space: nowrap;
            font-size: clamp(0.82rem, 2.6vw, 1.12rem);
            font-weight: 700;
            line-height: 1.2;
        }

        .brand-badge {
            font-size: clamp(0.68rem, 1.9vw, 0.82rem) !important;
            padding: 2px 7px !important;
            white-space: nowrap;
            border-radius: 20px;
            flex-shrink: 0;
            line-height: 1.3;
        }

        .nav-btn {
            background: rgba(255, 255, 255, 0.18);
            border: 1px solid rgba(255, 255, 255, 0.35);
            color: #ffffff;
            font-size: 0.88rem;
            font-weight: 600;
            cursor: pointer;
            height: 34px;
            border-radius: 8px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            padding: 0 11px;
            gap: 5px;
            transition: all 0.2s ease;
            text-decoration: none;
            white-space: nowrap !important;
            word-break: keep-all !important;
            flex-shrink: 0;
        }

        .nav-btn:hover {
            background-color: rgba(255, 255, 255, 0.3);
            color: #ffffff;
            text-decoration: none;
        }

        @media screen and (max-width: 576px) {
            .top-navbar {
                height: 50px;
                padding: 0 8px;
            }
            .navbar-brand-title {
                gap: 4px;
            }
            .brand-text {
                font-size: clamp(0.78rem, 3.2vw, 0.95rem);
            }
            .brand-badge {
                padding: 1px 5px !important;
                font-size: 0.7rem !important;
            }
            .nav-btn {
                height: 32px;
                padding: 0 8px;
                font-size: 0.82rem;
            }
        }

        @media screen and (max-width: 375px) {
            .top-navbar {
                padding: 0 5px;
            }
            .brand-text {
                font-size: 0.75rem;
            }
            .nav-btn {
                padding: 0 6px;
            }
        }

        /* 主作業容器 (流體響應式滿版，充分運用大螢幕解析度避免擠壓) */
        .main-container {
            max-width: 98%;
            width: 100%;
            margin: 0 auto;
            padding: 20px 24px;
        }

        /* 現代卡片 */
        .card-modern {
            background: var(--surface);
            border-radius: 12px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05), 0 4px 12px rgba(15, 23, 42, 0.04);
            border: 1px solid var(--border-color);
            margin-bottom: 20px;
            overflow: hidden;
            transition: box-shadow 0.2s ease;
        }

        .card-modern:hover {
            box-shadow: 0 4px 16px rgba(15, 23, 42, 0.08);
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

        /* KPI 統計看板卡片 */
        .kpi-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
            gap: 16px;
            margin-bottom: 20px;
        }

        .kpi-card {
            background: #ffffff;
            border-radius: 12px;
            border: 1px solid var(--border-color);
            padding: 18px 20px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
            position: relative;
            overflow: hidden;
            transition: transform 0.2s, box-shadow 0.2s;
            cursor: pointer;
        }

        .kpi-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 16px rgba(15, 23, 42, 0.08);
        }

        .kpi-card::before {
            content: '';
            position: absolute;
            left: 0;
            top: 0;
            bottom: 0;
            width: 4px;
        }

        .kpi-card.kpi-total::before { background: var(--brand-blue); }
        .kpi-card.kpi-pass::before { background: var(--success-color); }
        .kpi-card.kpi-minor::before { background: var(--warning-color); }
        .kpi-card.kpi-severe::before { background: var(--danger-color); }

        .kpi-info-title {
            font-size: 0.88rem;
            font-weight: 600;
            color: var(--text-muted);
            margin-bottom: 4px;
        }

        .kpi-info-val {
            font-size: 1.75rem;
            font-weight: 800;
            color: var(--brand-navy);
            line-height: 1.2;
        }

        .kpi-info-sub {
            font-size: 0.8rem;
            color: var(--text-muted);
            margin-top: 4px;
        }

        .kpi-icon-box {
            width: 48px;
            height: 48px;
            border-radius: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.4rem;
        }

        .kpi-total .kpi-icon-box { background: #e0f2fe; color: #0284c7; }
        .kpi-pass .kpi-icon-box { background: #ecfdf5; color: #10b981; }
        .kpi-minor .kpi-icon-box { background: #fffbeb; color: #f59e0b; }
        .kpi-severe .kpi-icon-box { background: #fef2f2; color: #ef4444; }

        /* 篩選標籤晶片 (Chips) */
        .chip-group {
            display: flex;
            flex-wrap: wrap;
            gap: 8px;
        }

        .chip-item {
            padding: 6px 14px;
            border-radius: 20px;
            font-size: 0.85rem;
            font-weight: 600;
            border: 1px solid var(--border-color);
            background: #ffffff;
            color: #475569;
            cursor: pointer;
            user-select: none;
            transition: all 0.15s ease;
            display: inline-flex;
            align-items: center;
            gap: 6px;
        }

        .chip-item:hover {
            border-color: var(--brand-blue);
            color: var(--brand-blue);
            background: #f0f9ff;
        }

        .chip-item.active {
            background: var(--brand-blue);
            color: #ffffff;
            border-color: var(--brand-blue);
            box-shadow: 0 2px 6px rgba(2, 132, 199, 0.3);
        }

        .chip-item.active-success {
            background: var(--success-color);
            color: #ffffff;
            border-color: var(--success-color);
            box-shadow: 0 2px 6px rgba(16, 185, 129, 0.3);
        }

        .chip-item.active-warning {
            background: var(--warning-color);
            color: #ffffff;
            border-color: var(--warning-color);
            box-shadow: 0 2px 6px rgba(245, 158, 11, 0.3);
        }

        .chip-item.active-danger {
            background: var(--danger-color);
            color: #ffffff;
            border-color: var(--danger-color);
            box-shadow: 0 2px 6px rgba(239, 68, 68, 0.3);
        }

        /* 欄位勾選核取方塊排版 */
        .field-checkbox-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
            gap: 8px;
            background: #f8fafc;
            border: 1px solid var(--border-color);
            border-radius: 8px;
            padding: 12px;
        }

        .custom-control-label {
            font-size: 0.88rem;
            font-weight: 600;
            color: #334155;
            cursor: pointer;
        }

        /* 現代資料表格 (大幅擴展最小寬度，保證各欄位充足顯示與橫向滾動體驗) */
        .table-modern-wrap {
            overflow-x: auto;
            border-radius: 8px;
            border: 1px solid var(--border-color);
            background: #ffffff;
            -webkit-overflow-scrolling: touch;
        }

        .table-modern-wrap::-webkit-scrollbar {
            height: 8px;
        }

        .table-modern-wrap::-webkit-scrollbar-track {
            background: #f1f5f9;
            border-radius: 4px;
        }

        .table-modern-wrap::-webkit-scrollbar-thumb {
            background: #cbd5e1;
            border-radius: 4px;
        }

        .table-modern-wrap::-webkit-scrollbar-thumb:hover {
            background: #94a3b8;
        }

        .table-modern {
            width: 100%;
            min-width: 2050px;
            margin: 0;
            border-collapse: separate;
            border-spacing: 0;
            table-layout: auto;
        }

        .table-modern thead th {
            background: #f1f5f9;
            color: #334155;
            font-weight: 700;
            font-size: 0.88rem;
            padding: 12px 14px;
            border-bottom: 2px solid var(--border-color);
            white-space: nowrap;
            user-select: none;
            position: sticky;
            top: 0;
            z-index: 5;
        }

        .table-modern thead th.sortable {
            cursor: pointer;
            transition: background 0.15s;
        }

        .table-modern thead th.sortable:hover {
            background: #e2e8f0;
            color: var(--brand-blue);
        }

        .table-modern tbody tr {
            transition: background 0.15s;
        }

        .table-modern tbody tr:hover {
            background: #f8fafc;
        }

        .table-modern tbody td {
            padding: 12px 14px;
            border-bottom: 1px solid var(--border-color);
            font-size: 0.88rem;
            color: var(--text-main);
            vertical-align: middle;
        }

                /* 缺失分級徽章 */
        .badge-loss {
            font-size: 0.82rem;
            font-weight: 700;
            padding: 5px 12px;
            border-radius: 6px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 6px;
            white-space: nowrap !important;
            word-break: keep-all !important;
            min-width: 105px;
            line-height: 1.2;
        }

        /* 表格內按鈕與標籤一律強制單行不折行 */
        .table-modern td, .table-modern th {
            vertical-align: middle !important;
        }
        .table-modern td .btn {
            white-space: nowrap !important;
            word-break: keep-all !important;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 5px;
            padding: 5px 12px;
        }

        .badge-loss-0 {
            background: #ecfdf5;
            color: #047857;
            border: 1px solid #a7f3d0;
        }

        .badge-loss-1 {
            background: #fffbeb;
            color: #b45309;
            border: 1px solid #fde68a;
        }

        .badge-loss-10 {
            background: #fef2f2;
            color: #b91c1c;
            border: 1px solid #fecaca;
        }

        /* 行動端卡片排版 */
        @media screen and (max-width: 991px) {
            .desktop-only-table {
                display: none;
            }
            .mobile-card-item {
                display: block;
                background: #ffffff;
                border: 1px solid var(--border-color);
                border-radius: 10px;
                padding: 14px;
                margin-bottom: 12px;
                box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
            }
        }

        @media screen and (min-width: 992px) {
            .mobile-card-list {
                display: none;
            }
        }

        /* 缺失項目彈窗內容 */
        .loss-modal-grid {
            display: grid;
            grid-template-columns: 1fr;
            gap: 10px;
        }

        .loss-modal-row {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 10px 14px;
            background: #f8fafc;
            border-radius: 8px;
            border: 1px solid var(--border-color);
        }

        .loss-modal-row.has-loss {
            background: #fff1f2;
            border-color: #fecdd3;
        }

        /* 載入遮罩 */
        .loading-overlay {
            position: fixed;
            top: 0; left: 0; right: 0; bottom: 0;
            background: rgba(255, 255, 255, 0.7);
            display: flex;
            align-items: center;
            justify-content: center;
            z-index: 2000;
        }

        .loading-spinner {
            font-size: 2.5rem;
            color: var(--brand-blue);
        }

        /* 列印隱藏 */
        @media print {
            .no-print {
                display: none !important;
            }
        }

        /* 底部操作列響應式佈局 (小尺寸分兩行) */
        .filter-bottom-bar {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 12px;
        }

        .filter-stat-text {
            font-size: 0.9rem;
            color: var(--text-muted);
            white-space: nowrap;
        }

        .filter-actions {
            display: flex;
            align-items: center;
            gap: 10px;
            white-space: nowrap;
        }

        .filter-actions .btn {
            white-space: nowrap;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            height: 36px;
            padding: 0 18px;
        }

        @media screen and (max-width: 767px) {
            .filter-bottom-bar {
                flex-direction: column;
                align-items: stretch;
                gap: 12px;
            }
            .filter-stat-text {
                text-align: center;
                white-space: normal;
                line-height: 1.5;
            }
            .filter-actions {
                display: flex;
                width: 100%;
                gap: 10px;
            }
            .filter-actions .btn {
                flex: 1;
                height: 40px;
                font-size: 0.95rem;
            }
            .card-modern-header {
                flex-direction: column;
                align-items: flex-start;
                gap: 10px;
            }
            .card-header-actions {
                display: flex;
                align-items: center;
                justify-content: space-between;
                width: 100%;
                flex-wrap: wrap;
                gap: 8px;
            }
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
    </style>
</head>
<body>
    <div id="caseSumApp" v-cloak>
        <!-- 頂部品牌導覽列 -->
        <header class="top-navbar no-print">
            <!-- 左側品牌區：流體字型自適應，嚴格 flex-nowrap 防跑版 -->
            <div class="nav-brand-group">
                <a href="../MainPage.aspx" class="nav-btn mr-2" title="返回主選單">
                    <i class="fas fa-home"></i>
                    <span class="d-none d-md-inline ml-1">回首頁</span>
                </a>
                <a href="Case_Sum.aspx" class="navbar-brand-title">
                    <i class="fas fa-chart-pie text-white flex-shrink-0"></i>
                    <span class="brand-text">公私場所巡查案件統計</span>
                    <span class="badge badge-light text-dark font-weight-bold ml-1 brand-badge">
                        {{ formatNumber(totalRecords) }} <span class="d-none d-sm-inline">筆案件</span><span class="d-inline d-sm-none">筆</span>
                    </span>
                </a>
            </div>
        </header>

        <!-- 主內容區域 -->
        <main class="main-container">
            <!-- 1. KPI 統計概覽看板 (點擊可秒速單選過濾) -->
            <section class="kpi-grid no-print">
                <div class="kpi-card kpi-total" v-on:click="selectAllLossLevels" title="點擊檢視全部案件">
                    <div>
                        <div class="kpi-info-title">巡查案件總數</div>
                        <div class="kpi-info-val">{{ formatNumber(totalRecords) }}</div>
                        <div class="kpi-info-sub">涵蓋公私場所 {{ totalFacs }} 家</div>
                    </div>
                    <div class="kpi-icon-box">
                        <i class="fas fa-clipboard-check"></i>
                    </div>
                </div>

                <div class="kpi-card kpi-pass" v-on:click="selectOnlyLossLevel('無缺失')" title="點擊僅篩選無缺失 (合格) 案件">
                    <div>
                        <div class="kpi-info-title">無缺失案件 (0點)</div>
                        <div class="kpi-info-val text-success">{{ formatNumber(kpiData.zeroCount) }}</div>
                        <div class="kpi-info-sub">合格率 {{ kpiData.zeroPercent }}%</div>
                    </div>
                    <div class="kpi-icon-box">
                        <i class="fas fa-check-circle"></i>
                    </div>
                </div>

                <div class="kpi-card kpi-minor" v-on:click="selectOnlyLossLevel('輕微缺失')" title="點擊僅篩選輕微缺失案件">
                    <div>
                        <div class="kpi-info-title">輕微缺失 (1~9點)</div>
                        <div class="kpi-info-val" style="color: #d97706;">{{ formatNumber(kpiData.minorCount) }}</div>
                        <div class="kpi-info-sub">佔比 {{ kpiData.minorPercent }}%</div>
                    </div>
                    <div class="kpi-icon-box">
                        <i class="fas fa-exclamation-circle"></i>
                    </div>
                </div>

                <div class="kpi-card kpi-severe" v-on:click="selectOnlyLossLevel('嚴重缺失')" title="點擊僅篩選嚴重缺失案件">
                    <div>
                        <div class="kpi-info-title">嚴重缺失 (10點以上)</div>
                        <div class="kpi-info-val text-danger">{{ formatNumber(kpiData.severeCount) }}</div>
                        <div class="kpi-info-sub">佔比 {{ kpiData.severePercent }}% (重點列管)</div>
                    </div>
                    <div class="kpi-icon-box">
                        <i class="fas fa-times-circle"></i>
                    </div>
                </div>
            </section>

            <!-- 2. 多維度篩選設定卡片 -->
            <section class="card-modern no-print">
                <div class="card-modern-header">
                    <div class="card-modern-title">
                        <i class="fas fa-filter text-primary"></i>
                        <span>篩選與顯示設定</span>
                    </div>
                    <div class="d-flex align-items-center gap-2">
                        <button type="button" class="btn btn-sm btn-outline-secondary" v-on:click="resetFilters">
                            <i class="fas fa-undo mr-1"></i>重設條件
                        </button>
                        <button type="button" class="btn btn-sm btn-outline-primary" v-on:click="toggleFilterCollapse">
                            <i :class="filterCollapsed ? 'fas fa-chevron-down' : 'fas fa-chevron-up'"></i>
                            <span class="ml-1">{{ filterCollapsed ? '展開篩選' : '收合篩選' }}</span>
                        </button>
                    </div>
                </div>

                <div class="card-modern-body" v-show="!filterCollapsed">
                    <!-- 關鍵字文字篩選 -->
                    <div class="row">
                        <div class="col-md-3 col-sm-6 mb-3">
                            <label class="font-weight-bold text-muted small mb-1">管制編號</label>
                            <div class="input-group">
                                <div class="input-group-prepend">
                                    <span class="input-group-text"><i class="fas fa-barcode"></i></span>
                                </div>
                                <input type="text" class="form-control" placeholder="例: F1234567" v-model.trim="filters.cNo" v-on:keyup.enter="handleSearchBtnClick" />
                            </div>
                        </div>

                        <div class="col-md-3 col-sm-6 mb-3">
                            <label class="font-weight-bold text-muted small mb-1">公私場所名稱</label>
                            <div class="input-group">
                                <div class="input-group-prepend">
                                    <span class="input-group-text"><i class="fas fa-industry"></i></span>
                                </div>
                                <input type="text" class="form-control" placeholder="輸入場所關鍵字" v-model.trim="filters.facName" v-on:keyup.enter="handleSearchBtnClick" />
                            </div>
                        </div>

                        <div class="col-md-3 col-sm-6 mb-3">
                            <label class="font-weight-bold text-muted small mb-1">行業別名稱</label>
                            <div class="input-group">
                                <div class="input-group-prepend">
                                    <span class="input-group-text"><i class="fas fa-briefcase"></i></span>
                                </div>
                                <input type="text" class="form-control" placeholder="輸入行業別" v-model.trim="filters.industry" v-on:keyup.enter="handleSearchBtnClick" />
                            </div>
                        </div>

                        <div class="col-md-3 col-sm-6 mb-3">
                            <label class="font-weight-bold text-muted small mb-1">程序別 / 製程</label>
                            <div class="input-group">
                                <div class="input-group-prepend">
                                    <span class="input-group-text"><i class="fas fa-cogs"></i></span>
                                </div>
                                <input type="text" class="form-control" placeholder="例: M01、操作許可" v-model.trim="filters.process" v-on:keyup.enter="handleSearchBtnClick" />
                            </div>
                        </div>
                    </div>

                    <!-- 巡查日期區間 -->
                    <div class="row align-items-center mb-3">
                        <div class="col-lg-6 col-md-12 mb-2">
                            <label class="font-weight-bold text-muted small mb-1">巡查日期區間</label>
                            <div class="d-flex align-items-center gap-2">
                                <input type="date" class="form-control" v-model="filters.dateStart" />
                                <span class="text-muted font-weight-bold">至</span>
                                <input type="date" class="form-control" v-model="filters.dateEnd" />
                            </div>
                        </div>
                        <div class="col-lg-6 col-md-12 mb-2">
                            <label class="font-weight-bold text-muted small mb-1 d-block">快速日期選取</label>
                            <div class="chip-group">
                                <button type="button" class="chip-item" v-on:click="setDateRange('today')">今天</button>
                                <button type="button" class="chip-item" v-on:click="setDateRange('thisMonth')">本月</button>
                                <button type="button" class="chip-item" v-on:click="setDateRange('lastMonth')">上月</button>
                                <button type="button" class="chip-item" v-on:click="setDateRange('thisYear')">今年</button>
                                <button type="button" class="chip-item" v-on:click="setDateRange('clear')">全部 (不限)</button>
                            </div>
                        </div>
                    </div>

                    <!-- 缺失分級篩選晶片 -->
                    <div class="mb-3">
                        <label class="font-weight-bold text-muted small mb-1 d-block">缺失分級篩選</label>
                        <div class="chip-group">
                            <button type="button" class="chip-item" :class="{ 'active': filters.lossLevels.length === 3 }" v-on:click="selectAllLossLevels">
                                <i class="fas fa-layer-group"></i> 全部分級
                            </button>
                            <button type="button" class="chip-item" :class="{ 'active-success': filters.lossLevels.indexOf('無缺失') > -1 }" v-on:click="toggleLossLevel('無缺失')">
                                <i class="fas fa-check-circle"></i> 無缺失 (0分)
                            </button>
                            <button type="button" class="chip-item" :class="{ 'active-warning': filters.lossLevels.indexOf('輕微缺失') > -1 }" v-on:click="toggleLossLevel('輕微缺失')">
                                <i class="fas fa-exclamation-circle"></i> 輕微缺失 (1~9分)
                            </button>
                            <button type="button" class="chip-item" :class="{ 'active-danger': filters.lossLevels.indexOf('嚴重缺失') > -1 }" v-on:click="toggleLossLevel('嚴重缺失')">
                                <i class="fas fa-times-circle"></i> 嚴重缺失 (10分以上)
                            </button>
                            <button type="button" class="btn btn-sm btn-link text-primary ml-1" v-on:click="selectAllLossLevels">全選</button>
                        </div>
                    </div>

                    <!-- 行政區多選晶片 -->
                    <div class="mb-3">
                        <div class="d-flex align-items-center justify-content-between mb-1">
                            <label class="font-weight-bold text-muted small mb-0">行政區選取 (已選 {{ filters.towns.length }} 區)</label>
                            <div>
                                <button type="button" class="btn btn-sm btn-link text-primary p-0 mr-2" v-on:click="selectAllTowns">全選</button>
                                <button type="button" class="btn btn-sm btn-link text-secondary p-0" v-on:click="clearTowns">清除</button>
                            </div>
                        </div>
                        <div class="chip-group" style="max-height: 140px; overflow-y: auto; padding: 4px;">
                            <button v-for="t in townList" :key="t.TownNo" type="button" class="chip-item" :class="{ 'active': filters.towns.indexOf(t.TownNo) > -1 }" v-on:click="toggleTown(t.TownNo)">
                                {{ t.TownName }}
                            </button>
                        </div>
                    </div>

                    <!-- 欄位顯示設定 -->
                    <div class="mb-4">
                        <div class="d-flex align-items-center justify-content-between mb-1">
                            <label class="font-weight-bold text-muted small mb-0">報表顯示欄位設定</label>
                            <div>
                                <button type="button" class="btn btn-sm btn-link text-primary p-0 mr-2" v-on:click="selectAllFields">全選</button>
                                <button type="button" class="btn btn-sm btn-link text-secondary p-0" v-on:click="resetDefaultFields">恢復預設</button>
                            </div>
                        </div>
                        <div class="field-checkbox-grid">
                            <div v-for="fld in fieldOptions" :key="fld.key" class="custom-control custom-checkbox">
                                <input type="checkbox" class="custom-control-input" :id="'chk_' + fld.key" :value="fld.key" v-model="filters.showFields" />
                                <label class="custom-control-label" :for="'chk_' + fld.key">{{ fld.label }}</label>
                            </div>
                        </div>
                    </div>

                    <!-- 底部標準操作列 (小尺寸自動分兩行呈現，杜絕擠壓) -->
                    <div class="filter-bottom-bar mt-3 pt-3 border-top">
                        <div class="filter-stat-text">
                            共查詢到 <strong class="text-primary font-weight-bold">{{ formatNumber(totalRecords) }}</strong> 筆巡查案件 (涵蓋 {{ totalFacs }} 家場所)
                        </div>
                        <div class="filter-actions">
                            <button type="button" class="btn btn-outline-secondary btn-sm" v-on:click="resetFilters">
                                <i class="fas fa-undo mr-1"></i> 重設條件
                            </button>
                            <button type="button" class="btn btn-primary btn-sm font-weight-bold" v-on:click="handleSearchBtnClick" :disabled="loading">
                                <i class="fas fa-search mr-1"></i> 立即查詢
                            </button>
                        </div>
                    </div>
                </div>
            </section>

            <!-- 3. 資料清單作業區 -->
            <section class="card-modern">
                <div class="card-modern-header">
                    <div class="d-flex align-items-center gap-2">
                        <div class="card-modern-title">
                            <i class="fas fa-list-alt text-primary"></i>
                            <span>統計查詢結果</span>
                        </div>
                        <span class="badge badge-light border text-dark font-weight-bold ml-1">
                            共 {{ totalRecords }} 筆
                        </span>
                        <span class="badge badge-secondary ml-1 d-none d-sm-inline">
                            頁次 {{ pageIndex }} / {{ totalPages }}
                        </span>
                    </div>

                    <div class="d-flex align-items-center">
                        <!-- 1. 重新整理 -->
                        <button type="button" class="btn btn-sm btn-outline-secondary mr-2" v-on:click="handleSearchBtnClick" :disabled="loading" title="重新整理查詢">
                            <i class="fas fa-sync-alt mr-1" :class="{ 'fa-spin': loading }"></i>
                            <span class="d-none d-md-inline">重新整理</span>
                        </button>

                        <!-- 2. 匯出 EXCEL -->
                        <button type="button" class="btn btn-sm btn-outline-success font-weight-bold mr-2" v-on:click="exportExcel" :disabled="loading || totalRecords === 0" title="匯出篩選結果為 EXCEL 報表">
                            <i class="fas fa-file-excel mr-1"></i>
                            <span class="d-none d-md-inline">匯出 EXCEL</span>
                        </button>

                        <!-- 3. 每頁筆數選擇器 -->
                        <div class="d-inline-flex align-items-center">
                            <span class="small text-muted mr-1 d-none d-lg-inline">每頁：</span>
                            <select class="form-control form-control-sm d-inline-block w-auto" v-model.number="pageSize" v-on:change="onPageSizeChange">
                                <option :value="10">10 筆</option>
                                <option :value="25">25 筆</option>
                                <option :value="50">50 筆</option>
                                <option :value="100">100 筆</option>
                            </select>
                        </div>
                    </div>
                </div>

                <div class="card-modern-body p-0">
                    <!-- 載入中骨架屏 -->
                    <div v-if="loading" class="text-center py-5">
                        <i class="fas fa-circle-notch fa-spin text-primary fa-3x mb-3"></i>
                        <p class="text-muted font-weight-bold mb-0">資料檢索中，請稍候...</p>
                    </div>

                    <!-- 無資料提示 -->
                    <div v-else-if="rows.length === 0" class="text-center py-5">
                        <i class="fas fa-inbox text-muted fa-4x mb-3" style="opacity: 0.3;"></i>
                        <h6 class="font-weight-bold text-secondary mb-1">查無符合條件之巡查案件紀錄</h6>
                        <small class="text-muted">請嘗試放寬日期範圍或調整行政區、缺失等級等篩選條件。</small>
                    </div>

                    <!-- 桌面端表格檢視 -->
                    <div v-else class="table-modern-wrap desktop-only-table">
                        <table class="table-modern">
                            <thead>
                                <tr>
                                    <th v-if="isFieldVisible('C_NO')" class="sortable text-center" style="min-width: 130px; width: 130px; white-space: nowrap;" v-on:click="changeSort('C_NO')">
                                        管制編號 <i :class="getSortIcon('C_NO')"></i>
                                    </th>
                                    <th v-if="isFieldVisible('FAC_NAME')" class="sortable" style="min-width: 250px; white-space: nowrap;" v-on:click="changeSort('FAC_NAME')">
                                        公私場所名稱 <i :class="getSortIcon('FAC_NAME')"></i>
                                    </th>
                                    <th v-if="isFieldVisible('TOWN_NA')" class="sortable text-center" style="min-width: 110px; width: 110px; white-space: nowrap;" v-on:click="changeSort('TOWN_NA')">
                                        行政區 <i :class="getSortIcon('TOWN_NA')"></i>
                                    </th>
                                    <th v-if="isFieldVisible('INDUSTRIAL_Name')" class="sortable" style="min-width: 230px; white-space: nowrap;" v-on:click="changeSort('INDUSTRIAL_Name')">
                                        行業別 <i :class="getSortIcon('INDUSTRIAL_Name')"></i>
                                    </th>
                                    <th v-if="isFieldVisible('ProcessList')" style="min-width: 320px; white-space: nowrap;">
                                        製程編號 / 狀態 / 許可證
                                    </th>
                                    <th v-if="isFieldVisible('CheckTime_LV')" class="text-center" style="min-width: 110px; width: 110px; white-space: nowrap;">
                                        查核頻率
                                    </th>
                                    <th v-if="isFieldVisible('INV_DATE')" class="sortable text-center" style="min-width: 125px; width: 125px; white-space: nowrap;" v-on:click="changeSort('INV_DATE')">
                                        巡查日期 <i :class="getSortIcon('INV_DATE')"></i>
                                    </th>
                                    <th v-if="isFieldVisible('INV_TYPE')" class="text-center" style="min-width: 110px; width: 110px; white-space: nowrap;">
                                        查核屬性
                                    </th>
                                    <th v-if="isFieldVisible('Loss_LV')" class="sortable text-center" style="min-width: 140px; width: 140px; white-space: nowrap;" v-on:click="changeSort('Loss_LV')">
                                        缺失分級 <i :class="getSortIcon('Loss_LV')"></i>
                                    </th>
                                    <th v-if="isFieldVisible('Loss_Point')" class="sortable text-center" style="min-width: 110px; width: 110px; white-space: nowrap;" v-on:click="changeSort('Loss_Point')">
                                        缺失點數 <i :class="getSortIcon('Loss_Point')"></i>
                                    </th>
                                    <th v-if="isFieldVisible('Loss_Detail')" style="min-width: 380px; white-space: nowrap;">
                                        缺失項目摘要
                                    </th>
                                    <th class="text-center" style="min-width: 110px; width: 110px; white-space: nowrap;">
                                        操作
                                    </th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr v-for="(item, idx) in rows" :key="item.FacId + '_' + item.InvDate + '_' + idx">
                                    <td v-if="isFieldVisible('C_NO')" class="text-center font-weight-bold text-dark" style="white-space: nowrap;">
                                        {{ item.CNo || '-' }}
                                    </td>
                                    <td v-if="isFieldVisible('FAC_NAME')" class="font-weight-bold text-primary" style="min-width: 250px; line-height: 1.4;">
                                        {{ item.FacName }}
                                    </td>
                                    <td v-if="isFieldVisible('TOWN_NA')" class="text-center" style="white-space: nowrap;">
                                        <span class="badge badge-light border text-secondary px-2 py-1">{{ item.TownName }}</span>
                                    </td>
                                    <td v-if="isFieldVisible('INDUSTRIAL_Name')" style="min-width: 230px; line-height: 1.4; word-break: break-word;">
                                        {{ item.IndustrialName || '-' }}
                                    </td>
                                    <td v-if="isFieldVisible('ProcessList')" style="min-width: 320px; line-height: 1.4;">
                                        <div v-html="item.ProcessList || '<span class=\'text-muted\'>-</span>'" class="small"></div>
                                    </td>
                                    <td v-if="isFieldVisible('CheckTime_LV')" class="text-center" style="white-space: nowrap;">
                                        <span v-if="item.CheckTimeLv" class="badge badge-secondary">{{ item.CheckTimeLv }}</span>
                                        <span v-else class="text-muted">-</span>
                                    </td>
                                    <td v-if="isFieldVisible('INV_DATE')" class="text-center font-weight-bold" style="white-space: nowrap;">
                                        {{ item.InvDate }}
                                    </td>
                                    <td v-if="isFieldVisible('INV_TYPE')" class="text-center" style="white-space: nowrap;">
                                        {{ item.InvType || '-' }}
                                    </td>
                                    <td v-if="isFieldVisible('Loss_LV')" class="text-center" style="white-space: nowrap;">
                                        <span :class="getLossBadgeClass(item.LossPoint)">
                                            <i :class="getLossBadgeIcon(item.LossPoint)"></i>
                                            {{ item.LossLv }}
                                        </span>
                                    </td>
                                    <td v-if="isFieldVisible('Loss_Point')" class="text-center font-weight-bold" style="white-space: nowrap;" :class="item.LossPoint >= 10 ? 'text-danger' : (item.LossPoint > 0 ? 'text-warning' : 'text-success')">
                                        {{ item.LossPoint }} 點
                                    </td>
                                    <td v-if="isFieldVisible('Loss_Detail')" style="min-width: 380px; line-height: 1.4;">
                                        <div v-html="item.LossDetail" class="small" style="max-height: 85px; overflow-y: auto;"></div>
                                    </td>
                                    <td class="text-center" style="white-space: nowrap; width: 110px;">
                                        <button type="button" class="btn btn-sm btn-outline-info" style="white-space: nowrap;" v-on:click="openLossModal(item)" title="檢視 9 大管制項目記點詳情">
                                            <i class="fas fa-search-plus"></i> 細項
                                        </button>
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>

                    <!-- 行動端卡片檢視 (Mobile) -->
                    <div v-if="!loading && rows.length > 0" class="mobile-card-list p-3">
                        <div v-for="(item, idx) in rows" :key="'mob_' + item.FacId + '_' + item.InvDate + '_' + idx" class="mobile-card-item">
                            <div class="d-flex justify-content-between align-items-start mb-2">
                                <div>
                                    <span class="badge badge-light border text-secondary mr-1">{{ item.TownName }}</span>
                                    <span class="font-weight-bold text-dark">{{ item.CNo }}</span>
                                </div>
                                <span :class="getLossBadgeClass(item.LossPoint)">
                                    {{ item.LossLv }} ({{ item.LossPoint }}點)
                                </span>
                            </div>

                            <h6 class="font-weight-bold text-primary mb-1">{{ item.FacName }}</h6>
                            <div class="small text-muted mb-2">
                                <div><i class="fas fa-calendar-alt mr-1"></i> 巡查日期：{{ item.InvDate }}</div>
                                <div><i class="fas fa-briefcase mr-1"></i> 行業別：{{ item.IndustrialName || '-' }}</div>
                            </div>

                            <div class="d-flex justify-content-end">
                                <button type="button" class="btn btn-sm btn-outline-info" v-on:click="openLossModal(item)">
                                    <i class="fas fa-search-plus mr-1"></i> 檢視 9 大管制細項
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- 自適應底部分頁導覽列 (Responsive Pagination Footer) -->
                    <div v-if="!loading && totalRecords > 0" class="pagination-footer">
                        <div class="pagination-footer-info">
                            顯示第 <strong class="text-dark">{{ (pageIndex - 1) * pageSize + 1 }}</strong> 至 <strong class="text-dark">{{ Math.min(pageIndex * pageSize, totalRecords) }}</strong> 筆，共 <strong class="text-dark">{{ totalRecords }}</strong> 筆
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
                </div>
            </section>
        </main>

        <!-- 缺失項目詳細彈窗 (Modal) -->
        <div class="modal fade" id="lossDetailModal" tabindex="-1" role="dialog" aria-hidden="true">
            <div class="modal-dialog modal-lg modal-dialog-centered" role="document">
                <div class="modal-content border-0 shadow">
                    <div class="modal-header bg-light">
                        <h5 class="modal-title font-weight-bold text-dark">
                            <i class="fas fa-clipboard-list text-primary mr-2"></i>
                            公私場所巡查 9 大管制項目記點詳情
                        </h5>
                        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                            <span aria-hidden="true">&times;</span>
                        </button>
                    </div>

                    <div class="modal-body" v-if="currentModalItem">
                        <!-- 場所基本資訊卡 -->
                        <div class="p-3 bg-light rounded mb-3 border">
                            <div class="row">
                                <div class="col-sm-6 mb-1">
                                    <small class="text-muted d-block">場所名稱</small>
                                    <strong class="text-primary">{{ currentModalItem.FacName }}</strong>
                                </div>
                                <div class="col-sm-3 mb-1">
                                    <small class="text-muted d-block">管制編號</small>
                                    <strong>{{ currentModalItem.CNo }}</strong>
                                </div>
                                <div class="col-sm-3 mb-1">
                                    <small class="text-muted d-block">行政區</small>
                                    <strong>{{ currentModalItem.TownName }}</strong>
                                </div>
                                <div class="col-sm-4 mb-1">
                                    <small class="text-muted d-block">巡查日期</small>
                                    <strong>{{ currentModalItem.InvDate }}</strong>
                                </div>
                                <div class="col-sm-4 mb-1">
                                    <small class="text-muted d-block">查核屬性</small>
                                    <strong>{{ currentModalItem.InvType || '-' }}</strong>
                                </div>
                                <div class="col-sm-4 mb-1">
                                    <small class="text-muted d-block">缺失總分 / 等級</small>
                                    <span :class="getLossBadgeClass(currentModalItem.LossPoint)">
                                        {{ currentModalItem.LossLv }} ({{ currentModalItem.LossPoint }} 點)
                                    </span>
                                </div>
                            </div>
                        </div>

                        <!-- 9 大項目記點清單 -->
                        <div class="loss-modal-grid">
                            <div v-for="s in currentModalItem.ItemScores" :key="s.ItemNo" class="loss-modal-row" :class="{ 'has-loss': s.Point > 0 }">
                                <div class="d-flex align-items-center">
                                    <span class="badge badge-secondary mr-2" style="width: 24px;">{{ s.ItemNo }}</span>
                                    <span class="font-weight-bold" :class="s.Point > 0 ? 'text-danger' : 'text-dark'">{{ s.Title }}</span>
                                </div>

                                <div>
                                    <span v-if="s.Point === 0" class="badge badge-success px-2 py-1">
                                        <i class="fas fa-check mr-1"></i> 合格 (0點)
                                    </span>
                                    <span v-else-if="s.Point >= 10" class="badge badge-danger px-2 py-1">
                                        <i class="fas fa-exclamation-triangle mr-1"></i> 嚴重缺失 (記 {{ s.Point }} 點)
                                    </span>
                                    <span v-else class="badge badge-warning text-dark px-2 py-1 font-weight-bold">
                                        <i class="fas fa-exclamation-circle mr-1"></i> 缺失 (記 {{ s.Point }} 點)
                                    </span>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="modal-footer bg-light">
                        <button type="button" class="btn btn-secondary" data-dismiss="modal">關閉</button>
                    </div>
                </div>
            </div>
        </div>

        <!-- 載入中遮罩 -->
        <div v-if="loading" class="loading-overlay">
            <div class="text-center">
                <i class="fas fa-circle-notch fa-spin loading-spinner"></i>
                <div class="font-weight-bold text-dark mt-2">資料處理中...</div>
            </div>
        </div>
    </div>

    <!-- 本地核心腳本引用 (嚴禁外部 CDN) -->
    <script src="../Scripts/jquery-3.6.0.min.js"></script>
    <script src="../Scripts/bootstrap.bundle.min.js"></script>
    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>

    <script>
        const { createApp } = Vue;

        createApp({
            data() {
                return {
                    loading: false,
                    filterCollapsed: false,
                    townList: [],
                    totalRecords: 0,
                    totalFacs: 0,
                    pageIndex: 1,
                    pageSize: 25,
                    sortField: 'INV_DATE',
                    sortDir: 'desc',
                    kpiData: {
                        zeroCount: 0,
                        zeroPercent: 0,
                        minorCount: 0,
                        minorPercent: 0,
                        severeCount: 0,
                        severePercent: 0
                    },
                    filters: {
                        cNo: '',
                        facName: '',
                        industry: '',
                        process: '',
                        dateStart: '',
                        dateEnd: '',
                        towns: [],
                        lossLevels: ['無缺失', '輕微缺失', '嚴重缺失'],
                        showFields: [
                            'C_NO', 'FAC_NAME', 'TOWN_NA', 'INDUSTRIAL_Name', 
                            'ProcessList', 'CheckTime_LV', 'INV_DATE', 'INV_TYPE', 
                            'Loss_LV', 'Loss_Point', 'Loss_Detail'
                        ]
                    },
                    fieldOptions: [
                        { key: 'C_NO', label: '管制編號' },
                        { key: 'FAC_NAME', label: '公私場所名稱' },
                        { key: 'TOWN_NA', label: '行政區' },
                        { key: 'INDUSTRIAL_Name', label: '行業別' },
                        { key: 'ProcessList', label: '製程編號/狀態/許可證' },
                        { key: 'CheckTime_LV', label: '查核頻率分級' },
                        { key: 'INV_DATE', label: '巡查日期' },
                        { key: 'INV_TYPE', label: '查核屬性' },
                        { key: 'Loss_LV', label: '缺失分級' },
                        { key: 'Loss_Point', label: '缺失點數' },
                        { key: 'Loss_Detail', label: '缺失項目摘要' }
                    ],
                    rows: [],
                    currentModalItem: null
                };
            },
            computed: {
                totalPages() {
                    return Math.max(1, Math.ceil(this.totalRecords / this.pageSize));
                },
                visiblePages() {
                    const pages = [];
                    const maxButtons = 5;
                    let start = Math.max(1, this.pageIndex - Math.floor(maxButtons / 2));
                    let end = Math.min(this.totalPages, start + maxButtons - 1);
                    if (end - start + 1 < maxButtons) {
                        start = Math.max(1, end - maxButtons + 1);
                    }
                    for (let i = start; i <= end; i++) {
                        pages.push(i);
                    }
                    return pages;
                }
            },
            mounted() {
                this.loadTowns();
                this.setDateRange('thisYear');
                this.handleSearchBtnClick();
            },
            methods: {
                formatNumber(val) {
                    if (val === null || val === undefined) return '0';
                    return val.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
                },
                toggleFilterCollapse() {
                    this.filterCollapsed = !this.filterCollapsed;
                },
                isFieldVisible(fldKey) {
                    return this.filters.showFields.indexOf(fldKey) > -1;
                },
                selectAllFields() {
                    this.filters.showFields = this.fieldOptions.map(f => f.key);
                },
                resetDefaultFields() {
                    this.filters.showFields = [
                        'C_NO', 'FAC_NAME', 'TOWN_NA', 'INDUSTRIAL_Name', 
                        'ProcessList', 'CheckTime_LV', 'INV_DATE', 'INV_TYPE', 
                        'Loss_LV', 'Loss_Point', 'Loss_Detail'
                    ];
                },
                loadTowns() {
                    axios.get('Case_Sum.aspx?action=gettowns')
                        .then(res => {
                            if (res.data && res.data.Success) {
                                this.townList = res.data.Towns || [];
                                this.selectAllTowns();
                            }
                        })
                        .catch(err => {
                            console.error('取得行政區失敗', err);
                        });
                },
                selectAllTowns() {
                    this.filters.towns = this.townList.map(t => t.TownNo);
                },
                clearTowns() {
                    this.filters.towns = [];
                },
                toggleTown(tNo) {
                    const idx = this.filters.towns.indexOf(tNo);
                    if (idx > -1) {
                        this.filters.towns.splice(idx, 1);
                    } else {
                        this.filters.towns.push(tNo);
                    }
                },
                selectAllLossLevels() {
                    this.filters.lossLevels = ['無缺失', '輕微缺失', '嚴重缺失'];
                    this.pageIndex = 1;
                    this.doSearch();
                },
                selectOnlyLossLevel(lv) {
                    this.filters.lossLevels = [lv];
                    this.pageIndex = 1;
                    this.doSearch();
                },
                toggleLossLevel(lv) {
                    // 若原本為全選狀態，點擊單一項目的意圖是「只看該項目」
                    if (this.filters.lossLevels.length === 3) {
                        this.filters.lossLevels = [lv];
                    } else {
                        const idx = this.filters.lossLevels.indexOf(lv);
                        if (idx > -1) {
                            if (this.filters.lossLevels.length === 1) {
                                this.filters.lossLevels = ['無缺失', '輕微缺失', '嚴重缺失'];
                            } else {
                                this.filters.lossLevels.splice(idx, 1);
                            }
                        } else {
                            this.filters.lossLevels.push(lv);
                        }
                    }
                    this.pageIndex = 1;
                    this.doSearch();
                },
                setDateRange(type) {
                    const now = new Date();
                    const y = now.getFullYear();
                    const m = now.getMonth(); // 0~11

                    const formatD = (d) => {
                        const month = (d.getMonth() + 1).toString().padStart(2, '0');
                        const day = d.getDate().toString().padStart(2, '0');
                        return d.getFullYear() + '-' + month + '-' + day;
                    };

                    if (type === 'today') {
                        this.filters.dateStart = formatD(now);
                        this.filters.dateEnd = formatD(now);
                    } else if (type === 'thisMonth') {
                        this.filters.dateStart = formatD(new Date(y, m, 1));
                        this.filters.dateEnd = formatD(new Date(y, m + 1, 0));
                    } else if (type === 'lastMonth') {
                        this.filters.dateStart = formatD(new Date(y, m - 1, 1));
                        this.filters.dateEnd = formatD(new Date(y, m, 0));
                    } else if (type === 'thisYear') {
                        this.filters.dateStart = formatD(new Date(y, 0, 1));
                        this.filters.dateEnd = formatD(new Date(y, 11, 31));
                    } else if (type === 'clear') {
                        this.filters.dateStart = '';
                        this.filters.dateEnd = '';
                    }
                    this.pageIndex = 1;
                },
                resetFilters() {
                    this.filters.cNo = '';
                    this.filters.facName = '';
                    this.filters.industry = '';
                    this.filters.process = '';
                    this.filters.lossLevels = ['無缺失', '輕微缺失', '嚴重缺失'];
                    this.selectAllTowns();
                    this.setDateRange('thisYear');
                    this.resetDefaultFields();
                    this.pageIndex = 1;
                    this.doSearch();
                },
                changeSort(field) {
                    if (this.sortField === field) {
                        this.sortDir = this.sortDir === 'asc' ? 'desc' : 'asc';
                    } else {
                        this.sortField = field;
                        this.sortDir = 'desc';
                    }
                    this.pageIndex = 1;
                    this.doSearch();
                },
                getSortIcon(field) {
                    if (this.sortField !== field) return 'fas fa-sort text-muted';
                    return this.sortDir === 'asc' ? 'fas fa-sort-up text-primary' : 'fas fa-sort-down text-primary';
                },
                getLossBadgeClass(point) {
                    if (point === 0) return 'badge-loss badge-loss-0';
                    if (point >= 10) return 'badge-loss badge-loss-10';
                    return 'badge-loss badge-loss-1';
                },
                getLossBadgeIcon(point) {
                    if (point === 0) return 'fas fa-check-circle';
                    if (point >= 10) return 'fas fa-times-circle';
                    return 'fas fa-exclamation-circle';
                },
                onPageSizeChange() {
                    this.pageIndex = 1;
                    this.doSearch();
                },
                goToPage(p) {
                    if (p < 1 || p > this.totalPages || p === this.pageIndex) return;
                    this.pageIndex = p;
                    this.doSearch();
                },
                handleSearchBtnClick() {
                    this.pageIndex = 1;
                    this.doSearch();
                },
                doSearch() {
                    this.loading = true;
                    const payload = {
                        cNo: this.filters.cNo,
                        facName: this.filters.facName,
                        industry: this.filters.industry,
                        process: this.filters.process,
                        dateStart: this.filters.dateStart,
                        dateEnd: this.filters.dateEnd,
                        towns: this.filters.towns,
                        lossLevels: this.filters.lossLevels,
                        pageIndex: this.pageIndex,
                        pageSize: this.pageSize,
                        sortField: this.sortField,
                        sortDir: this.sortDir,
                        showFields: this.filters.showFields
                    };

                    axios.post('Case_Sum.aspx?action=getsumdata', payload)
                        .then(res => {
                            this.loading = false;
                            if (res.data && res.data.Success) {
                                this.rows = res.data.Rows || [];
                                this.totalRecords = res.data.TotalRecords || 0;
                                this.totalFacs = res.data.TotalFacs || 0;
                                if (res.data.PageIndex) {
                                    this.pageIndex = res.data.PageIndex;
                                }
                                this.kpiData.zeroCount = res.data.ZeroLossCount || 0;
                                this.kpiData.zeroPercent = res.data.ZeroLossPercent || 0;
                                this.kpiData.minorCount = res.data.MinorLossCount || 0;
                                this.kpiData.minorPercent = res.data.MinorLossPercent || 0;
                                this.kpiData.severeCount = res.data.SevereLossCount || 0;
                                this.kpiData.severePercent = res.data.SevereLossPercent || 0;
                            } else {
                                alert((res.data && res.data.Message) || '查詢失敗');
                            }
                        })
                        .catch(err => {
                            this.loading = false;
                            console.error('查詢失敗', err);
                            alert('網路通訊失敗，請檢查連線或稍後再試。');
                        });
                },
                openLossModal(item) {
                    this.currentModalItem = item;
                    $('#lossDetailModal').modal('show');
                },
                exportExcel() {
                    const params = new URLSearchParams();
                    params.append('action', 'exportexcel');
                    params.append('cNo', this.filters.cNo);
                    params.append('facName', this.filters.facName);
                    params.append('industry', this.filters.industry);
                    params.append('process', this.filters.process);
                    params.append('dateStart', this.filters.dateStart);
                    params.append('dateEnd', this.filters.dateEnd);
                    params.append('towns', this.filters.towns.join(','));
                    params.append('lossLevels', this.filters.lossLevels.join(','));
                    params.append('showFields', this.filters.showFields.join(','));
                    params.append('sortField', this.sortField);
                    params.append('sortDir', this.sortDir);

                    window.location.href = 'Case_Sum.aspx?' + params.toString();
                }
            }
        }).mount('#caseSumApp');
    </script>
</body>
</html>
