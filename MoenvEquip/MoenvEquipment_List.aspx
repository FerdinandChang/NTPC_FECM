<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="MoenvEquipment_List.aspx.cs" Inherits="NTPC_FEC.MoenvEquip.MoenvEquipment_List" %>

<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定逸散源管理平台 - 環境部施工機具資料分析</title>

    <link rel="shortcut icon" href="../favicon.ico" type="image/x-icon" />
    <link rel="stylesheet" href="../Content/bootstrap.min.css" />
    <link rel="stylesheet" href="../Content/fontawesome/css/all.min.css" />

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
            --accent-success: #10b981;
            --accent-warning: #f59e0b;
            --accent-danger: #ef4444;
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
            padding: 0 16px;
            box-shadow: 0 2px 10px rgba(0, 153, 229, 0.25);
            position: sticky;
            top: 0;
            z-index: 1020;
        }

        .navbar-brand-title {
            font-size: 1.12rem;
            font-weight: 700;
            display: flex;
            align-items: center;
            gap: 10px;
            color: #ffffff !important;
            text-decoration: none !important;
            white-space: nowrap !important;
            flex-shrink: 0;
        }

        .nav-btn {
            background: rgba(255, 255, 255, 0.18);
            border: 1px solid rgba(255, 255, 255, 0.3);
            color: #ffffff !important;
            font-size: 0.88rem;
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
            text-decoration: none !important;
        }
        .nav-btn:hover {
            background-color: rgba(255, 255, 255, 0.32);
            color: #ffffff !important;
            text-decoration: none !important;
        }

        .nav-top-btn {
            display: inline-flex !important;
            align-items: center !important;
            justify-content: center !important;
            height: 36px !important;
            min-height: 36px !important;
            border-radius: 8px !important;
            font-size: 0.88rem !important;
            font-weight: 600 !important;
            padding: 0 12px !important;
            transition: all 0.15s ease-in-out;
            text-decoration: none !important;
            flex-shrink: 0 !important;
        }

        /* 業務模式分頁切換列 */
        .nav-mode-bar {
            background: #ffffff;
            border-bottom: 1px solid var(--border-color);
            padding: 0 16px;
            display: flex;
            gap: 6px;
            overflow-x: auto;
            white-space: nowrap;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.03);
        }

        .nav-mode-item {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 13px 18px;
            font-size: 14px;
            font-weight: 600;
            color: #64748b;
            border-bottom: 3px solid transparent;
            cursor: pointer;
            transition: all 0.2s ease;
            text-decoration: none !important;
        }
        .nav-mode-item:hover {
            color: var(--brand-blue);
            background: #f8fafc;
        }
        .nav-mode-item.active {
            color: var(--brand-blue);
            border-bottom-color: var(--brand-blue);
            font-weight: 700;
            background: rgba(2, 132, 199, 0.04);
        }

        /* 5 張統計指標卡片網格 */
        .kpi-grid-5 {
            display: grid;
            grid-template-columns: repeat(5, 1fr);
            gap: 12px;
            margin-bottom: 16px;
        }
        @media (max-width: 1199.98px) {
            .kpi-grid-5 {
                grid-template-columns: repeat(3, 1fr);
            }
        }
        @media (max-width: 767.98px) {
            .kpi-grid-5 {
                grid-template-columns: repeat(2, 1fr);
                gap: 8px;
            }
            .kpi-grid-5 .stat-card:last-child {
                grid-column: span 2;
            }
        }

        .stat-card {
            background: #ffffff;
            border-radius: 12px;
            border: 1.5px solid var(--border-color);
            padding: 14px 16px;
            display: flex;
            align-items: center;
            gap: 12px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.03);
            transition: all 0.2s ease;
            cursor: pointer;
            user-select: none;
            position: relative;
        }
        .stat-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(15, 23, 42, 0.08);
        }
        .stat-card.active-gold {
            border-color: #f59e0b;
            background: #fffbeb;
            box-shadow: 0 0 0 3px rgba(245, 158, 11, 0.2);
        }
        .stat-card.active-silver {
            border-color: #0284c7;
            background: #f0f9ff;
            box-shadow: 0 0 0 3px rgba(2, 132, 199, 0.2);
        }
        .stat-card.active-bronze {
            border-color: #ea580c;
            background: #fff7ed;
            box-shadow: 0 0 0 3px rgba(234, 88, 12, 0.2);
        }
        .stat-card.active-fail {
            border-color: #ef4444;
            background: #fef2f2;
            box-shadow: 0 0 0 3px rgba(239, 68, 68, 0.2);
        }
        .stat-card.active-qualified {
            border-color: #10b981;
            background: #ecfdf5;
            box-shadow: 0 0 0 3px rgba(16, 185, 129, 0.2);
        }

        .stat-icon {
            width: 44px;
            height: 44px;
            border-radius: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 20px;
            flex-shrink: 0;
        }

        /* 現代卡片 */
        .card-modern {
            background: var(--surface);
            border-radius: 12px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05), 0 4px 12px rgba(15, 23, 42, 0.04);
            border: 1px solid var(--border-color);
            margin-bottom: 18px;
            overflow: hidden;
        }
        .card-modern-header {
            padding: 12px 18px;
            background: #ffffff;
            border-bottom: 1px solid var(--border-color);
            display: flex;
            align-items: center;
            justify-content: space-between;
        }
        .card-modern-title {
            font-size: 1rem;
            font-weight: 700;
            color: var(--brand-navy);
            margin: 0;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        /* 表格樣式 */
        .table-custom {
            width: 100%;
            margin-bottom: 0;
            border-collapse: collapse;
        }
        .table-custom th {
            background-color: #f8fafc;
            color: #475569;
            font-weight: 700;
            font-size: 13px;
            border-bottom: 2px solid #e2e8f0;
            padding: 12px 12px;
            white-space: nowrap;
        }
        .table-custom td {
            padding: 11px 12px;
            vertical-align: middle;
            border-top: 1px solid #f1f5f9;
            font-size: 13.5px;
            color: #1e293b;
        }
        .table-custom tbody tr:hover {
            background-color: #f8fafc;
        }

        /* 標章與狀態膠囊 */
        .badge-pill-custom {
            padding: 4px 10px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 700;
            display: inline-flex;
            align-items: center;
            gap: 4px;
            white-space: nowrap;
        }
        .badge-gold { background: #fef3c7; color: #b45309; border: 1px solid #fde68a; }
        .badge-silver { background: #e0f2fe; color: #0369a1; border: 1px solid #bae6fd; }
        .badge-bronze { background: #ffedd5; color: #c2410c; border: 1px solid #fed7aa; }
        .badge-fail { background: #fee2e2; color: #b91c1c; border: 1px solid #fecaca; }
        .badge-pass { background: #d1fae5; color: #047857; border: 1px solid #a7f3d0; }
        .badge-info-muted { background: #f1f5f9; color: #475569; border: 1px solid #cbd5e1; }
        .badge-photo-link {
            background: #f0fdf4;
            color: #15803d;
            border: 1px solid #bbf7d0;
            cursor: pointer;
            transition: all 0.15s ease;
        }
        .badge-photo-link:hover {
            background: #dcfce7;
            transform: translateY(-1px);
        }

        /* 行動端卡片 */
        .mobile-item-card {
            background: #ffffff;
            border: 1px solid var(--border-color);
            border-radius: 10px;
            padding: 14px;
            margin-bottom: 10px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.03);
        }

        .btn-icon-mobile {
            display: inline-flex !important;
            align-items: center;
            justify-content: center;
            height: 34px !important;
            min-width: 34px !important;
            padding: 0 10px;
            white-space: nowrap !important;
            flex-shrink: 0 !important;
            border-radius: 8px !important;
        }
        @media (max-width: 767.98px) {
            .btn-icon-mobile {
                width: 34px !important;
                padding: 0 !important;
            }
        }

        /* 全載具自適應分頁頁尾 */
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
        }
        .btn-page-ctrl:hover:not(:disabled) {
            background: #f1f5f9;
            color: #0f172a;
            border-color: #94a3b8;
        }
        .btn-page-ctrl:disabled {
            opacity: 0.45;
            cursor: not-allowed;
            background: #f8fafc;
        }

        .page-indicator-pill {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            height: 38px;
            min-width: 76px;
            padding: 0 12px;
            font-size: 0.88rem;
            font-weight: 600;
            color: var(--brand-navy);
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            user-select: none;
            white-space: nowrap !important;
        }

        /* 詳情彈窗與輪播 */
        .modal-custom-backdrop {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(15, 23, 42, 0.65);
            backdrop-filter: blur(3px);
            z-index: 1050;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 16px;
        }
        .modal-custom-card {
            background: #ffffff;
            border-radius: 14px;
            width: 100%;
            max-width: 1060px;
            max-height: 90vh;
            display: flex;
            flex-direction: column;
            box-shadow: 0 20px 45px rgba(0, 0, 0, 0.25);
            animation: modalFadeIn 0.2s ease-out;
            overflow: hidden;
        }
        @keyframes modalFadeIn {
            from { opacity: 0; transform: scale(0.96); }
            to { opacity: 1; transform: scale(1); }
        }

        .details-table {
            width: 100%;
            border-collapse: collapse;
        }
        .details-table th {
            width: 32%;
            background: #f8fafc;
            color: #475569;
            font-weight: 600;
            font-size: 13px;
            padding: 9px 12px;
            border-bottom: 1px solid #e2e8f0;
            border-right: 1px solid #e2e8f0;
            white-space: nowrap;
        }
        .details-table td {
            padding: 9px 12px;
            font-size: 13.5px;
            color: #0f172a;
            border-bottom: 1px solid #e2e8f0;
        }
        .details-table tr.highlight-completeness th {
            background-color: #f0fdfa;
            color: #0d9488;
            font-weight: 700;
        }
        .details-table tr.highlight-completeness td {
            background-color: #f0fdfa;
        }

        /* 輪播區塊 */
        .carousel-box {
            position: relative;
            background: #000;
            border-radius: 10px;
            overflow: hidden;
            height: 280px;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .carousel-box img {
            max-height: 280px;
            max-width: 100%;
            object-fit: contain;
            cursor: zoom-in;
            user-select: none;
        }
        .carousel-nav-btn {
            position: absolute;
            top: 50%;
            transform: translateY(-50%);
            background: rgba(0, 0, 0, 0.55);
            color: #ffffff;
            border: none;
            width: 36px;
            height: 36px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            transition: all 0.2s ease;
            z-index: 5;
        }
        .carousel-nav-btn:hover {
            background: rgba(0, 0, 0, 0.85);
            transform: translateY(-50%) scale(1.08);
        }
        .carousel-nav-btn.prev { left: 10px; }
        .carousel-nav-btn.next { right: 10px; }

        .photo-upload-zone {
            border: 2px dashed #94a3b8;
            border-radius: 10px;
            padding: 20px 16px;
            text-align: center;
            background: #f8fafc;
            cursor: pointer;
            transition: all 0.2s ease;
        }
        .photo-upload-zone:hover {
            border-color: var(--brand-blue);
            background: #f0f9ff;
        }

        /* Lightbox 大圖彈窗 */
        .lightbox-backdrop {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(0, 0, 0, 0.88);
            z-index: 1090;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
            cursor: zoom-out;
        }
        .lightbox-backdrop img {
            max-width: 95vw;
            max-height: 92vh;
            border-radius: 8px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.5);
        }
    </style>
</head>
<body>
    <div id="app" v-cloak>
        <!-- 1. 頂部深青藍導覽列 (Sticky Top Navbar) -->
        <header class="top-navbar">
            <div class="d-flex align-items-center">
                <a href="../MainPage.aspx" class="nav-btn mr-2" title="返回系統主選單">
                    <i class="fas fa-home"></i>
                    <span class="d-none d-sm-inline">回首頁</span>
                </a>
                <a href="MoenvEquipment_List.aspx" class="navbar-brand-title">
                    <i class="fas fa-truck-monster text-white"></i>
                    <span>環境部施工機具資料分析</span>
                    <span class="badge badge-light text-dark font-weight-bold ml-1 d-none d-md-inline" style="font-size: 0.82rem;">
                        {{ stats.TotalMainCount }} 輛合格
                    </span>
                </a>
            </div>
            <div class="d-flex align-items-center" style="gap: 8px;">
                <a href="MoenvEquipment_Upload.aspx" class="btn btn-success nav-top-btn font-weight-bold shadow-sm" title="匯入環境部 Excel 清冊">
                    <i class="fas fa-file-upload"></i>
                    <span class="d-none d-sm-inline ml-1">匯入環境部 Excel</span>
                </a>
            </div>
        </header>

        <!-- 2. 業務模式分頁切換列 -->
        <nav class="nav-mode-bar">
            <a href="MoenvEquipment_List.aspx" class="nav-mode-item active">
                <i class="fas fa-chart-bar"></i>
                <span>資料統計與分析清冊</span>
                <span class="badge badge-primary font-weight-bold ml-1">{{ totalCount }}</span>
            </a>
            <a href="MoenvEquipment_Upload.aspx" class="nav-mode-item">
                <i class="fas fa-cloud-upload-alt"></i>
                <span>匯入環境部 Excel 資料</span>
            </a>
        </nav>

        <!-- 3. 主內容區 -->
        <main class="container-fluid py-3 px-md-4" style="max-width: 1640px;">
            <!-- A. 5 張統計指標卡片網格 (點擊可直接快速篩選) -->
            <div class="kpi-grid-5">
                <!-- 1. 金級 -->
                <div class="stat-card" :class="{ 'active-gold': filter.badgeLevel === '金級' }" v-on:click="toggleBadgeFilter('金級')" title="點擊快速篩選「金級」機具（再次點擊取消）">
                    <div class="stat-icon" style="background: #fef3c7; color: #d97706;">
                        <i class="fas fa-medal"></i>
                    </div>
                    <div>
                        <div class="text-muted small font-weight-bold">🏅 金級機具總數</div>
                        <div class="h4 mb-0 font-weight-bold" style="color: #b45309;">
                            {{ formatNumber(stats.GoldCount) }} <small class="text-muted" style="font-size: 0.78rem;">輛</small>
                        </div>
                    </div>
                </div>

                <!-- 2. 銀級 -->
                <div class="stat-card" :class="{ 'active-silver': filter.badgeLevel === '銀級' }" v-on:click="toggleBadgeFilter('銀級')" title="點擊快速篩選「銀級」機具（再次點擊取消）">
                    <div class="stat-icon" style="background: #e0f2fe; color: #0284c7;">
                        <i class="fas fa-award"></i>
                    </div>
                    <div>
                        <div class="text-muted small font-weight-bold">🥈 銀級機具總數</div>
                        <div class="h4 mb-0 font-weight-bold" style="color: #0369a1;">
                            {{ formatNumber(stats.SilverCount) }} <small class="text-muted" style="font-size: 0.78rem;">輛</small>
                        </div>
                    </div>
                </div>

                <!-- 3. 普級 -->
                <div class="stat-card" :class="{ 'active-bronze': filter.badgeLevel === '普級' }" v-on:click="toggleBadgeFilter('普級')" title="點擊快速篩選「普級」機具（再次點擊取消）">
                    <div class="stat-icon" style="background: #ffedd5; color: #ea580c;">
                        <i class="fas fa-certificate"></i>
                    </div>
                    <div>
                        <div class="text-muted small font-weight-bold">🥉 普級機具總數</div>
                        <div class="h4 mb-0 font-weight-bold" style="color: #c2410c;">
                            {{ formatNumber(stats.BronzeCount) }} <small class="text-muted" style="font-size: 0.78rem;">輛</small>
                        </div>
                    </div>
                </div>

                <!-- 4. 未通過 -->
                <div class="stat-card" :class="{ 'active-fail': filter.badgeLevel === '未通過' }" v-on:click="toggleBadgeFilter('未通過')" title="點擊切換查看「未通過」機具（再次點擊返回主清冊）">
                    <div class="stat-icon" style="background: #fee2e2; color: #dc2626;">
                        <i class="fas fa-times-circle"></i>
                    </div>
                    <div>
                        <div class="text-muted small font-weight-bold">❌ 未通過機具總數</div>
                        <div class="h4 mb-0 font-weight-bold text-danger">
                            {{ formatNumber(stats.FailCount) }} <small class="text-muted" style="font-size: 0.78rem;">輛</small>
                        </div>
                    </div>
                </div>

                <!-- 5. 資料完整率 -->
                <div class="stat-card" :class="{ 'active-qualified': filter.qualifiedStatus !== '' }" v-on:click="toggleQualifiedFilter" title="點擊循環篩選「完整 / 不完整」狀態">
                    <div class="stat-icon" style="background: #d1fae5; color: #059669;">
                        <i class="fas fa-clipboard-check"></i>
                    </div>
                    <div>
                        <div class="text-muted small font-weight-bold">
                            📋 資料完整率
                            <span v-if="filter.qualifiedStatus === '1'" class="badge badge-success ml-1">僅完整</span>
                            <span v-if="filter.qualifiedStatus === '0'" class="badge badge-danger ml-1">僅不完整</span>
                        </div>
                        <div class="h4 mb-0 font-weight-bold text-success">
                            {{ stats.QualifiedRate }}%
                            <small class="text-muted font-weight-normal" style="font-size: 0.75rem;">
                                ({{ formatNumber(stats.QualifiedCount) }}/{{ formatNumber(stats.TotalMainCount) }})
                            </small>
                        </div>
                    </div>
                </div>
            </div>

            <!-- B. 進階多條件篩選卡片 -->
            <div class="card-modern">
                <div class="card-modern-header" style="cursor: pointer;" v-on:click="filterCollapsed = !filterCollapsed">
                    <h2 class="card-modern-title">
                        <i class="fas fa-filter text-primary"></i>
                        <span>進階多條件篩選工具</span>
                        <span v-if="filter.badgeLevel" class="badge badge-primary ml-2">標章：{{ filter.badgeLevel }}</span>
                        <span v-if="filter.qualifiedStatus === '1'" class="badge badge-success ml-1">資料完整</span>
                        <span v-if="filter.qualifiedStatus === '0'" class="badge badge-danger ml-1">資料不完整</span>
                    </h2>
                    <button type="button" class="btn btn-link btn-sm text-muted p-0">
                        <i class="fas" :class="filterCollapsed ? 'fa-chevron-down' : 'fa-chevron-up'"></i>
                    </button>
                </div>
                <div class="card-body p-3" v-show="!filterCollapsed">
                    <div class="row">
                        <div class="col-12 col-sm-6 col-md-3 col-lg-2 mb-2">
                            <label class="small font-weight-bold text-muted mb-1">檢測日期 (起)</label>
                            <input type="date" class="form-control form-control-sm" v-model="filter.dateFrom" v-on:change="doSearch" />
                        </div>
                        <div class="col-12 col-sm-6 col-md-3 col-lg-2 mb-2">
                            <label class="small font-weight-bold text-muted mb-1">檢測日期 (迄)</label>
                            <input type="date" class="form-control form-control-sm" v-model="filter.dateTo" v-on:change="doSearch" />
                        </div>
                        <div class="col-12 col-sm-6 col-md-3 col-lg-2 mb-2">
                            <label class="small font-weight-bold text-muted mb-1">機具種類</label>
                            <select class="form-control form-control-sm" v-model="filter.equipType" v-on:change="doSearch">
                                <option value="">-- 全機種種類 --</option>
                                <option v-for="t in equipTypeList" :key="t" :value="t">{{ t }}</option>
                            </select>
                        </div>
                        <div class="col-12 col-sm-6 col-md-3 col-lg-2 mb-2">
                            <label class="small font-weight-bold text-muted mb-1">申請類型</label>
                            <select class="form-control form-control-sm" v-model="filter.applyType" v-on:change="doSearch">
                                <option value="">-- 全類型 --</option>
                                <option v-for="a in applyTypeList" :key="a" :value="a">{{ a }}</option>
                            </select>
                        </div>
                        <div class="col-6 col-sm-6 col-md-3 col-lg-2 mb-2">
                            <label class="small font-weight-bold text-muted mb-1">計畫類型</label>
                            <select class="form-control form-control-sm" v-model="filter.projectType" v-on:change="doSearch">
                                <option value="">-- 全計畫 --</option>
                                <option value="營建">營建</option>
                                <option value="逸散">逸散</option>
                            </select>
                        </div>
                        <div class="col-6 col-sm-6 col-md-3 col-lg-2 mb-2">
                            <label class="small font-weight-bold text-muted mb-1">標章等級</label>
                            <select class="form-control form-control-sm" v-model="filter.badgeLevel" v-on:change="doSearch">
                                <option value="">-- 全部等級 --</option>
                                <option value="金級">🏅 金級</option>
                                <option value="銀級">🥈 銀級</option>
                                <option value="普級">🥉 普級</option>
                                <option value="未通過">❌ 未通過 (退件)</option>
                            </select>
                        </div>
                        <div class="col-12 col-md-9 mb-2">
                            <label class="small font-weight-bold text-muted mb-1">關鍵字查詢 (所有者 / 統編 / 廠牌 / 型式 / 引擎號碼 / 機械牌號 / 標章號碼)</label>
                            <input type="text" class="form-control form-control-sm" placeholder="請輸入關鍵字後按 Enter 鍵進行查詢..." v-model="filter.keyword" v-on:keyup.enter="doSearch" />
                        </div>
                        <div class="col-12 col-md-3 mb-2">
                            <label class="small font-weight-bold text-muted mb-1">資料完整性狀態</label>
                            <select class="form-control form-control-sm" v-model="filter.qualifiedStatus" v-on:change="doSearch">
                                <option value="">-- 全部狀態 --</option>
                                <option value="1">✔ 資料完整</option>
                                <option value="0">⚠ 資料不完整</option>
                            </select>
                        </div>
                    </div>

                    <div class="d-flex flex-column flex-md-row justify-content-between align-items-center mt-2 pt-3 border-top">
                        <div class="small text-muted mb-2 mb-md-0">
                            <i class="fas fa-info-circle text-primary mr-1"></i>
                            目前查詢到 <strong class="text-primary">{{ formatNumber(totalCount) }}</strong> 筆符合條件施工機具資料
                            <span class="text-secondary ml-1">(上方金/銀/普/未通過卡片可快速聯動篩選)</span>
                        </div>
                        <div class="d-flex align-items-center w-100 w-md-auto" style="gap: 8px;">
                            <button type="button" class="btn btn-outline-secondary btn-sm flex-fill flex-md-grow-0 px-3" style="height: 36px;" v-on:click="resetFilter">
                                <i class="fas fa-undo mr-1"></i>重設條件
                            </button>
                            <button type="button" class="btn btn-primary btn-sm font-weight-bold flex-fill flex-md-grow-0 px-4" style="height: 36px;" v-on:click="doSearch">
                                <i class="fas fa-search mr-1"></i>立即查詢
                            </button>
                        </div>
                    </div>
                </div>
            </div>

            <!-- C. 清冊列表卡片 -->
            <div class="card-modern">
                <div class="card-modern-header d-flex align-items-center justify-content-between">
                    <div class="d-flex align-items-center text-nowrap" style="overflow: hidden; min-width: 0;">
                        <h2 class="card-modern-title mb-0">
                            <i class="fas fa-list-alt text-primary"></i>
                            <span>環境部施工機具分析與檢測清冊</span>
                        </h2>
                        <span class="badge badge-light border text-dark font-weight-bold ml-2">
                            共 {{ formatNumber(totalCount) }} 筆
                        </span>
                        <span class="badge badge-secondary ml-1 d-none d-md-inline">
                            頁次 {{ pageIndex }} / {{ totalPages }}
                        </span>
                    </div>

                    <!-- 操作按鈕工具組 -->
                    <div class="d-flex align-items-center flex-shrink-0 ml-2">
                        <!-- 1. 重新整理 -->
                        <button type="button" class="btn btn-sm btn-outline-secondary btn-icon-mobile mr-2" v-on:click="fetchList" :disabled="loading" title="重新整理清冊">
                            <i class="fas fa-sync-alt" :class="{ 'fa-spin': loading }"></i>
                            <span class="d-none d-md-inline ml-1">重新整理</span>
                        </button>

                        <!-- 2. 匯出 EXCEL -->
                        <button type="button" class="btn btn-sm btn-outline-success font-weight-bold btn-icon-mobile mr-2" v-on:click="exportExcel" :disabled="exporting || totalCount === 0" title="匯出目前篩選結果至 Excel">
                            <i class="fas fa-file-excel"></i>
                            <span class="d-none d-md-inline ml-1">{{ exporting ? '匯出中...' : '匯出 EXCEL' }}</span>
                        </button>

                        <!-- 3. 每頁筆數選擇 -->
                        <div class="d-inline-flex align-items-center">
                            <span class="small text-muted mr-1 d-none d-lg-inline">每頁：</span>
                            <select class="form-control form-control-sm d-inline-block w-auto" style="height: 34px;" v-model.number="pageSize" v-on:change="changePageSize">
                                <option :value="10">10 筆</option>
                                <option :value="15">15 筆</option>
                                <option :value="30">30 筆</option>
                                <option :value="50">50 筆</option>
                            </select>
                        </div>
                    </div>
                </div>

                <!-- 載入中狀態 -->
                <div v-if="loading" class="text-center py-5">
                    <div class="spinner-border text-primary mb-2" role="status"></div>
                    <div class="text-muted small font-weight-bold">正在載入機具資料...</div>
                </div>

                <!-- 無資料狀態 -->
                <div v-else-if="list.length === 0" class="text-center py-5 px-3">
                    <i class="fas fa-search fa-3x text-muted mb-3" style="opacity: 0.4;"></i>
                    <h5 class="font-weight-bold text-dark mb-1">目前條件下無符合機具資料</h5>
                    <p class="text-muted small mb-3">請調整檢測日期區間、機具種類或關鍵字，或前往匯入最新環境部 Excel 清冊。</p>
                    <button type="button" class="btn btn-outline-primary btn-sm mr-2" v-on:click="resetFilter">
                        <i class="fas fa-undo mr-1"></i>重設篩選條件
                    </button>
                    <a href="MoenvEquipment_Upload.aspx" class="btn btn-success btn-sm font-weight-bold">
                        <i class="fas fa-file-upload mr-1"></i>前往匯入環境部清冊
                    </a>
                </div>

                <!-- 資料表格 (Desktop / Tablet >= 768px) -->
                <div v-else class="table-responsive d-none d-md-block">
                    <table class="table-custom">
                        <thead>
                            <tr>
                                <th style="width: 20%;">機具所有者</th>
                                <th class="text-center" style="width: 8%;">計畫類型</th>
                                <th class="text-center" style="width: 9%;">廠牌</th>
                                <th class="text-center" style="width: 11%;">機具種類</th>
                                <th class="text-center" style="width: 11%;">型式</th>
                                <th class="text-center" style="width: 10%;">引擎號碼</th>
                                <th class="text-center" style="width: 9%;">檢測日期</th>
                                <th class="text-center" style="width: 7%;">標章等級</th>
                                <th class="text-center" style="width: 6%;">是否完整</th>
                                <th class="text-center" style="width: 9%;">照片 / 操作</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr v-for="item in list" :key="item.Id">
                                <td>
                                    <div class="font-weight-bold text-dark">{{ item.OwnerName || '無資料' }}</div>
                                    <div class="small text-muted" v-if="item.TaxId || item.BadgeNumber">
                                        <span v-if="item.TaxId" class="mr-2">統編：{{ item.TaxId }}</span>
                                        <span v-if="item.BadgeNumber">標章：{{ item.BadgeNumber }}</span>
                                    </div>
                                </td>
                                <td class="text-center">
                                    <span class="badge badge-light border text-secondary px-2 py-1">{{ item.ProjectType || '營建' }}</span>
                                </td>
                                <td class="text-center font-weight-bold">{{ item.Brand || '-' }}</td>
                                <td class="text-center">{{ item.EquipType || '-' }}</td>
                                <td class="text-center"><code>{{ item.Model || '-' }}</code></td>
                                <td class="text-center"><small class="text-monospace">{{ item.EngineNumber || '-' }}</small></td>
                                <td class="text-center">{{ item.TestDate || '-' }}</td>
                                <td class="text-center">
                                    <span class="badge-pill-custom" :class="getBadgeClass(item.BadgeLevel)">
                                        {{ item.BadgeLevel || '未分級' }}
                                    </span>
                                </td>
                                <td class="text-center">
                                    <template v-if="item.BadgeLevel !== '未通過'">
                                        <span v-if="item.IsQualified" class="badge-pill-custom badge-pass">完整</span>
                                        <span v-else class="badge-pill-custom badge-fail">不完整</span>
                                    </template>
                                    <span v-else class="text-muted small">-</span>
                                </td>
                                <td class="text-center text-nowrap">
                                    <span class="badge-pill-custom badge-photo-link mr-1" v-on:click="openDetails(item.Id)" title="點擊檢視與上傳照片">
                                        <i class="fas fa-camera"></i> {{ item.PhotoCount }}
                                    </span>
                                    <button type="button" class="btn btn-sm btn-outline-primary font-weight-bold py-1 px-2" v-on:click="openDetails(item.Id)">
                                        查看詳情
                                    </button>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>

                <!-- 行動端卡片式清單 (Mobile < 768px) -->
                <div v-if="!loading && list.length > 0" class="d-block d-md-none p-2">
                    <div v-for="item in list" :key="'m_' + item.Id" class="mobile-item-card">
                        <div class="d-flex justify-content-between align-items-start mb-2">
                            <div class="font-weight-bold text-dark pr-2" style="font-size: 0.98rem;">
                                {{ item.OwnerName || '未載明所有者' }}
                            </div>
                            <span class="badge-pill-custom flex-shrink-0" :class="getBadgeClass(item.BadgeLevel)">
                                {{ item.BadgeLevel || '未分級' }}
                            </span>
                        </div>
                        <div class="small text-muted mb-2" style="line-height: 1.6;">
                            <div><strong>種類 / 廠牌：</strong>{{ item.EquipType || '-' }} / {{ item.Brand || '-' }} ({{ item.Model || '-' }})</div>
                            <div><strong>引擎號碼：</strong>{{ item.EngineNumber || '-' }} ｜ <strong>檢測：</strong>{{ item.TestDate || '-' }}</div>
                        </div>
                        <div class="d-flex justify-content-between align-items-center pt-2 border-top">
                            <div class="d-flex align-items-center" style="gap: 6px;">
                                <span class="badge badge-light border">{{ item.ProjectType || '營建' }}</span>
                                <template v-if="item.BadgeLevel !== '未通過'">
                                    <span v-if="item.IsQualified" class="badge-pill-custom badge-pass">完整</span>
                                    <span v-else class="badge-pill-custom badge-fail">不完整</span>
                                </template>
                                <span class="badge-pill-custom badge-photo-link" v-on:click="openDetails(item.Id)">
                                    <i class="fas fa-camera"></i> {{ item.PhotoCount }} 張
                                </span>
                            </div>
                            <button type="button" class="btn btn-sm btn-primary font-weight-bold px-3" v-on:click="openDetails(item.Id)">
                                查看詳情
                            </button>
                        </div>
                    </div>
                </div>

                <!-- 自適應響應式分頁控制列 -->
                <div v-if="!loading && totalCount > 0" class="pagination-footer">
                    <div class="pagination-footer-info">
                        顯示第 <strong class="text-dark">{{ (pageIndex - 1) * pageSize + 1 }}</strong> 至
                        <strong class="text-dark">{{ Math.min(pageIndex * pageSize, totalCount) }}</strong> 筆，共
                        <strong class="text-dark">{{ formatNumber(totalCount) }}</strong> 筆
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
        </main>

        <!-- 4. 機具詳細資訊與檢測審核 Modal -->
        <div v-if="showModal && currentDetail" class="modal-custom-backdrop" v-on:click.self="closeDetails">
            <div class="modal-custom-card">
                <div class="card-modern-header bg-light">
                    <h3 class="card-modern-title" style="font-size: 1.08rem;">
                        <i class="fas fa-tools text-primary"></i>
                        <span>施工機具詳細規格 － {{ currentDetail.Brand || '' }} {{ currentDetail.Model || '' }}</span>
                        <span class="badge-pill-custom ml-2" :class="getBadgeClass(currentDetail.BadgeLevel)">
                            {{ currentDetail.BadgeLevel || '未分級' }}
                        </span>
                    </h3>
                    <button type="button" class="btn btn-sm btn-outline-secondary" v-on:click="closeDetails">
                        <i class="fas fa-times mr-1"></i>關閉
                    </button>
                </div>

                <div class="p-3 p-md-4" style="overflow-y: auto; flex: 1;">
                    <div class="row">
                        <!-- 左側：19 項規格與文件明細表 -->
                        <div class="col-12 col-lg-7 mb-3 mb-lg-0">
                            <div class="d-flex justify-content-between align-items-center mb-2">
                                <span class="font-weight-bold text-dark">
                                    <i class="fas fa-clipboard-list text-primary mr-1"></i>機具基本規格與文件檢核
                                </span>
                                <small class="text-teal font-weight-bold" style="color: #0f766e;">
                                    <span style="display:inline-block; width:10px; height:10px; background:#0d9488; border-radius:2px; margin-right:4px;"></span>標示底色者為完整性檢核欄位
                                </small>
                            </div>
                            <div class="border rounded overflow-hidden">
                                <table class="details-table">
                                    <tbody>
                                        <tr v-for="field in detailFields" :key="field.key" :class="{ 'highlight-completeness': field.isCheck }">
                                            <th>{{ field.label }}</th>
                                            <td>
                                                <template v-if="field.key === 'Id'">
                                                    <code class="px-2 py-1 bg-light border rounded text-primary font-weight-bold">{{ currentDetail.Id }}</code>
                                                    <small class="text-muted ml-2">(照片目錄：/NTPCEPD_New/MoenvEquip/Uploads/{{ currentDetail.Id }}/)</small>
                                                </template>
                                                <template v-else-if="field.key === 'ProjectType'">
                                                    <select class="form-control form-control-sm d-inline-block w-auto font-weight-bold"
                                                            v-model="currentDetail.ProjectType"
                                                            v-on:change="changeDetailProjectType">
                                                        <option value="營建">營建</option>
                                                        <option value="逸散">逸散</option>
                                                    </select>
                                                    <span v-if="projectTypeSavedMsg" class="small text-success font-weight-bold ml-2">
                                                        <i class="fas fa-check-circle"></i> {{ projectTypeSavedMsg }}
                                                    </span>
                                                </template>
                                                <template v-else-if="field.key === 'IsQualified'">
                                                    <span v-if="isDetailQualified" class="badge-pill-custom badge-pass">完整</span>
                                                    <span v-else class="badge-pill-custom badge-fail">不完整</span>
                                                </template>
                                                <template v-else>
                                                    {{ currentDetail[field.key] || '無' }}
                                                </template>
                                            </td>
                                        </tr>
                                    </tbody>
                                </table>
                            </div>
                        </div>

                        <!-- 右側：照片輪播與互動上傳 -->
                        <div class="col-12 col-lg-5">
                            <div class="d-flex justify-content-between align-items-center mb-2">
                                <span class="font-weight-bold text-dark">
                                    <i class="fas fa-images text-primary mr-1"></i>機具現場照片 ({{ photosList.length }} 張)
                                </span>
                                <button v-if="photosList.length > 0" type="button" class="btn btn-sm btn-outline-danger py-0 px-2" v-on:click="deleteCurrentPhoto">
                                    <i class="fas fa-trash-alt mr-1"></i>刪除此張照片
                                </button>
                            </div>

                            <!-- 輪播展示區 -->
                            <div class="carousel-box mb-3">
                                <template v-if="photosList.length > 0">
                                    <button v-if="photosList.length > 1" type="button" class="carousel-nav-btn prev" v-on:click="moveSlide(-1)" title="上一張">
                                        <i class="fas fa-chevron-left"></i>
                                    </button>
                                    <img :src="getPhotoUrl(photosList[currentSlideIdx].PhotoPath)"
                                         alt="機具照片"
                                         v-on:click="openLightbox(getPhotoUrl(photosList[currentSlideIdx].PhotoPath))"
                                         title="點擊放大檢視" />
                                    <button v-if="photosList.length > 1" type="button" class="carousel-nav-btn next" v-on:click="moveSlide(1)" title="下一張">
                                        <i class="fas fa-chevron-right"></i>
                                    </button>
                                    <div style="position: absolute; bottom: 10px; left: 50%; transform: translateX(-50%); background: rgba(0,0,0,0.65); color: #fff; padding: 2px 12px; border-radius: 12px; font-size: 12px; font-weight: 700;">
                                        {{ currentSlideIdx + 1 }} / {{ photosList.length }}
                                    </div>
                                </template>
                                <div v-else class="text-center text-light px-3" style="opacity: 0.75;">
                                    <i class="fas fa-camera-retro fa-2x mb-2"></i>
                                    <div class="small">目前尚無現場照片，請於下方上傳</div>
                                </div>
                            </div>

                            <!-- 拖曳或點選上傳區 -->
                            <div class="photo-upload-zone" v-on:click="triggerPhotoInput">
                                <i class="fas fa-cloud-upload-alt fa-2x text-primary mb-2"></i>
                                <div class="font-weight-bold text-dark" style="font-size: 0.92rem;">
                                    {{ photoUploading ? '正在上傳照片中...' : '點擊此處上傳機具照片' }}
                                </div>
                                <div class="small text-muted mt-1">支援單次選取多張圖片 (.jpg, .jpeg, .png)</div>
                                <input type="file" ref="photoInput" multiple accept="image/*,.jpg,.jpeg,.png" style="display: none;" v-on:change="handlePhotoUpload" />
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- 5. Lightbox 大圖檢視 -->
        <div v-if="lightboxUrl" class="lightbox-backdrop" v-on:click="lightboxUrl = ''">
            <img :src="lightboxUrl" alt="機具大圖預覽" />
        </div>
    </div>

    <!-- 本地化核心 JS 庫 -->
    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>
    <script>
        const { createApp } = Vue;

        createApp({
            data: function () {
                return {
                    loading: false,
                    exporting: false,
                    filterCollapsed: false,
                    equipTypeList: [],
                    applyTypeList: [],
                    filter: {
                        dateFrom: '',
                        dateTo: '',
                        equipType: '',
                        applyType: '',
                        projectType: '',
                        badgeLevel: '',
                        qualifiedStatus: '',
                        keyword: ''
                    },
                    stats: {
                        GoldCount: 0,
                        SilverCount: 0,
                        BronzeCount: 0,
                        FailCount: 0,
                        QualifiedCount: 0,
                        TotalMainCount: 0,
                        QualifiedRate: 0
                    },
                    list: [],
                    totalCount: 0,
                    pageIndex: 1,
                    pageSize: 15,

                    // 詳情 Modal 狀態
                    showModal: false,
                    currentEquipId: 0,
                    currentDetail: null,
                    photosList: [],
                    currentSlideIdx: 0,
                    photoUploading: false,
                    projectTypeSavedMsg: '',
                    lightboxUrl: '',

                    detailFields: [
                        { label: '照片目錄 ID', key: 'Id' },
                        { label: '計畫類型', key: 'ProjectType' },
                        { label: '核發單位', key: 'IssuingUnit' },
                        { label: '檢測縣市', key: 'TestCounty' },
                        { label: '機具所有者', key: 'OwnerName' },
                        { label: '申請類型', key: 'ApplyType', isCheck: true },
                        { label: '統一編號', key: 'TaxId' },
                        { label: '機具廠牌', key: 'Brand', isCheck: true },
                        { label: '機具種類', key: 'EquipType', isCheck: true },
                        { label: '機械牌號碼', key: 'PlateNumber' },
                        { label: '機具年份', key: 'EquipYear', isCheck: true },
                        { label: '機具型式', key: 'Model', isCheck: true },
                        { label: '機具引擎編號', key: 'EngineNumber', isCheck: true },
                        { label: '排氣量 (c.c)', key: 'Displacement' },
                        { label: '最大額定馬力 (hp)', key: 'MaxHorsePower', isCheck: true },
                        { label: '最大額定功率轉速', key: 'MaxPowerSpeed', isCheck: true },
                        { label: '檢測方式', key: 'TestMethod' },
                        { label: '標章編號', key: 'BadgeNumber' },
                        { label: '檢測值 (m-1)', key: 'TestValue' },
                        { label: '複測值 (m-1)', key: 'RetestValue' },
                        { label: '檢測日期', key: 'TestDate' },
                        { label: '核發日期', key: 'IssueDate' },
                        { label: '標章等級', key: 'BadgeLevel' },
                        { label: '標章狀態', key: 'BadgeStatus' },
                        { label: '購買證明文件', key: 'BuyDoc', isCheck: true },
                        { label: '出廠排放標準證明', key: 'EmissionDoc', isCheck: true },
                        { label: '機具標章照片', key: 'BadgePhoto', isCheck: true },
                        { label: '機具檢測紀錄文件證明', key: 'RecordDoc', isCheck: true },
                        { label: '資料完整性', key: 'IsQualified', isCheck: true }
                    ]
                };
            },
            computed: {
                totalPages: function () {
                    if (this.totalCount <= 0) return 1;
                    return Math.ceil(this.totalCount / this.pageSize);
                },
                isDetailQualified: function () {
                    if (!this.currentDetail) return false;
                    var v = this.currentDetail.IsQualified;
                    return v === 'True' || v === 'true' || v === '1' || v === true;
                }
            },
            mounted: function () {
                this.initPage();
            },
            methods: {
                formatNumber: function (num) {
                    var n = Number(num) || 0;
                    return n.toLocaleString('zh-TW');
                },
                getBadgeClass: function (level) {
                    var lv = (level || '').trim();
                    if (lv === '金級') return 'badge-gold';
                    if (lv === '銀級') return 'badge-silver';
                    if (lv === '普級') return 'badge-bronze';
                    if (lv === '未通過') return 'badge-fail';
                    return 'badge-info-muted';
                },
                initPage: function () {
                    var self = this;
                    axios.get('MoenvEquipment_List.aspx?action=init').then(function (res) {
                        var data = res.data;
                        if (data && data.success) {
                            self.equipTypeList = data.equipTypes || [];
                            self.applyTypeList = data.applyTypes || [];
                            self.filter.dateFrom = data.defaultDateFrom || '';
                            self.filter.dateTo = data.defaultDateTo || '';
                        }
                        self.fetchList();
                    }).catch(function () {
                        self.fetchList();
                    });
                },
                doSearch: function () {
                    this.pageIndex = 1;
                    this.fetchList();
                },
                fetchList: function () {
                    var self = this;
                    this.loading = true;
                    axios.get('MoenvEquipment_List.aspx', {
                        params: {
                            action: 'search',
                            dateFrom: this.filter.dateFrom,
                            dateTo: this.filter.dateTo,
                            equipType: this.filter.equipType,
                            applyType: this.filter.applyType,
                            projectType: this.filter.projectType,
                            badgeLevel: this.filter.badgeLevel,
                            qualifiedStatus: this.filter.qualifiedStatus,
                            keyword: this.filter.keyword,
                            pageIndex: this.pageIndex,
                            pageSize: this.pageSize,
                            _t: Date.now()
                        }
                    }).then(function (res) {
                        self.loading = false;
                        var data = res.data;
                        if (data && data.success) {
                            self.stats = data.stats || self.stats;
                            self.list = data.items || [];
                            self.totalCount = data.totalCount || 0;
                        }
                    }).catch(function () {
                        self.loading = false;
                    });
                },
                resetFilter: function () {
                    var year = new Date().getFullYear();
                    var today = new Date().toISOString().split('T')[0];
                    this.filter.dateFrom = year + '-01-01';
                    this.filter.dateTo = today;
                    this.filter.equipType = '';
                    this.filter.applyType = '';
                    this.filter.projectType = '';
                    this.filter.badgeLevel = '';
                    this.filter.qualifiedStatus = '';
                    this.filter.keyword = '';
                    this.pageIndex = 1;
                    this.fetchList();
                },
                toggleBadgeFilter: function (badgeVal) {
                    if (this.filter.badgeLevel === badgeVal) {
                        this.filter.badgeLevel = '';
                    } else {
                        this.filter.badgeLevel = badgeVal;
                    }
                    this.pageIndex = 1;
                    this.fetchList();
                },
                toggleQualifiedFilter: function () {
                    if (this.filter.qualifiedStatus === '') {
                        this.filter.qualifiedStatus = '0';
                    } else if (this.filter.qualifiedStatus === '0') {
                        this.filter.qualifiedStatus = '1';
                    } else {
                        this.filter.qualifiedStatus = '';
                    }
                    this.pageIndex = 1;
                    this.fetchList();
                },
                changePageSize: function () {
                    this.pageIndex = 1;
                    this.fetchList();
                },
                goToPage: function (p) {
                    if (p < 1 || p > this.totalPages) return;
                    this.pageIndex = p;
                    this.fetchList();
                },
                exportExcel: function () {
                    var self = this;
                    if (this.exporting) return;
                    this.exporting = true;

                    var params = [
                        'action=export',
                        'dateFrom=' + encodeURIComponent(this.filter.dateFrom || ''),
                        'dateTo=' + encodeURIComponent(this.filter.dateTo || ''),
                        'equipType=' + encodeURIComponent(this.filter.equipType || ''),
                        'applyType=' + encodeURIComponent(this.filter.applyType || ''),
                        'projectType=' + encodeURIComponent(this.filter.projectType || ''),
                        'badgeLevel=' + encodeURIComponent(this.filter.badgeLevel || ''),
                        'qualifiedStatus=' + encodeURIComponent(this.filter.qualifiedStatus || ''),
                        'keyword=' + encodeURIComponent(this.filter.keyword || '')
                    ].join('&');

                    window.location.href = 'MoenvEquipment_List.aspx?' + params;

                    setTimeout(function () {
                        self.exporting = false;
                    }, 3000);
                },
                openDetails: function (id) {
                    var self = this;
                    this.currentEquipId = id;
                    this.projectTypeSavedMsg = '';
                    axios.get('MoenvEquipment_List.aspx', {
                        params: { action: 'detail', id: id, _t: Date.now() }
                    }).then(function (res) {
                        var data = res.data;
                        if (data && data.success) {
                            self.currentDetail = data.data || {};
                            if (!self.currentDetail.ProjectType) {
                                self.currentDetail.ProjectType = '營建';
                            }
                            self.photosList = data.photos || [];
                            self.currentSlideIdx = 0;
                            self.showModal = true;
                        } else {
                            alert((data && data.message) ? data.message : '無法讀取機具詳情');
                        }
                    }).catch(function () {
                        alert('載入詳情失敗，請確認網路連線');
                    });
                },
                closeDetails: function () {
                    this.showModal = false;
                    this.currentDetail = null;
                    this.fetchList();
                },
                changeDetailProjectType: function () {
                    var self = this;
                    if (!this.currentDetail) return;
                    axios.get('MoenvEquipment_List.aspx', {
                        params: {
                            action: 'update_project_type',
                            id: this.currentDetail.Id,
                            projectType: this.currentDetail.ProjectType
                        }
                    }).then(function (res) {
                        if (res.data && res.data.success) {
                            self.projectTypeSavedMsg = '已儲存';
                            setTimeout(function () {
                                self.projectTypeSavedMsg = '';
                            }, 2000);
                        } else {
                            alert((res.data && res.data.message) ? res.data.message : '儲存失敗');
                        }
                    });
                },
                getPhotoUrl: function (photoPath) {
                    if (!photoPath) return '';
                    var p = photoPath.trim().replace(/\\/g, '/');
                    var idx = p.indexOf('Uploads/');
                    if (idx >= 0) {
                        return '/NTPCEPD_New/MoenvEquip/' + p.substring(idx);
                    }
                    var idxLower = p.toLowerCase().indexOf('uploads/');
                    if (idxLower >= 0) {
                        return '/NTPCEPD_New/MoenvEquip/' + p.substring(idxLower);
                    }
                    if (p.indexOf('/NTPCEPD_New/') === 0) {
                        return p;
                    }
                    return '/NTPCEPD_New/MoenvEquip/Uploads/' + p.replace(/^~?\/?/, '');
                },
                moveSlide: function (dir) {
                    if (this.photosList.length <= 1) return;
                    this.currentSlideIdx = (this.currentSlideIdx + dir + this.photosList.length) % this.photosList.length;
                },
                triggerPhotoInput: function () {
                    if (this.$refs.photoInput) {
                        this.$refs.photoInput.value = '';
                        this.$refs.photoInput.click();
                    }
                },
                handlePhotoUpload: function (e) {
                    var self = this;
                    var files = e.target.files;
                    if (!files || files.length === 0) return;

                    var formData = new FormData();
                    formData.append('equipId', this.currentEquipId);
                    for (var i = 0; i < files.length; i++) {
                        formData.append('files', files[i]);
                    }

                    this.photoUploading = true;
                    axios.post('MoenvEquipment_List.aspx?action=upload_photo', formData, {
                        headers: { 'Content-Type': 'multipart/form-data' }
                    }).then(function (res) {
                        self.photoUploading = false;
                        var data = res.data;
                        if (data && data.success) {
                            var newPhotos = data.photos || [];
                            self.photosList = self.photosList.concat(newPhotos);
                            self.currentSlideIdx = self.photosList.length - 1;
                        } else {
                            alert((data && data.message) ? data.message : '照片上傳失敗');
                        }
                    }).catch(function () {
                        self.photoUploading = false;
                        alert('照片上傳連線失敗');
                    });
                },
                deleteCurrentPhoto: function () {
                    var self = this;
                    if (this.photosList.length === 0) return;
                    if (!confirm('確定要刪除這張機具照片嗎？此動作無法復原。')) return;

                    var target = this.photosList[this.currentSlideIdx];
                    axios.get('MoenvEquipment_List.aspx', {
                        params: { action: 'delete_photo', photoId: target.Id }
                    }).then(function (res) {
                        if (res.data && res.data.success) {
                            self.photosList.splice(self.currentSlideIdx, 1);
                            if (self.currentSlideIdx >= self.photosList.length) {
                                self.currentSlideIdx = Math.max(0, self.photosList.length - 1);
                            }
                        } else {
                            alert((res.data && res.data.message) ? res.data.message : '刪除照片失敗');
                        }
                    });
                },
                openLightbox: function (url) {
                    this.lightboxUrl = url;
                }
            }
        }).mount('#app');
    </script>
</body>
</html>
