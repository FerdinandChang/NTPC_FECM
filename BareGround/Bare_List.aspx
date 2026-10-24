<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Bare_List.aspx.cs" Inherits="NTPC_FEC.BareGround.Bare_List" %>
<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定溢散源管理平台 - 裸露地調查管理清單</title>
    <!-- 專屬 Favicon -->
    <link rel="shortcut icon" href="../favicon.ico" type="image/x-icon" />
    <!-- 本地化依賴：Bootstrap 4, FontAwesome 5, Leaflet 1.9.4 -->
    <link rel="stylesheet" href="../Content/bootstrap.min.css" />
    <link rel="stylesheet" href="../Content/fontawesome/css/all.min.css" />
    <link rel="stylesheet" href="../Content/leaflet/leaflet.css" />
    <style>
        :root {
            --brand-primary: #0099e5;     /* 新北青藍 */
            --brand-blue: #0284c7;        /* 科技藍 */
            --brand-dark-blue: #0b1f7d;   /* 海軍深藍 */
            --brand-navy: #0f172a;        /* 標題深色 */
            --brand-gold: #9b741e;        /* 裸露地金褐主題色 */
            --brand-gold-light: #fef9c3;  /* 裸露地金褐淺底 */
            --bg-canvas: #f8fafc;         /* 頁面灰底 */
            --surface: #ffffff;           /* 卡片純白底色 */
            --border-color: #e2e8f0;      /* 邊框線條 */
            --text-main: #0f172a;         /* 內文主色 */
            --text-muted: #64748b;        /* 次要說明 */
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
        /* 業務模式分頁切換列 */
        .nav-mode-bar {
            background: #ffffff;
            border-bottom: 1px solid var(--border-color);
            padding: 0 20px;
            display: flex;
            gap: 8px;
            overflow-x: auto;
            white-space: nowrap;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.03);
            scrollbar-width: none;
        }
        .nav-mode-bar::-webkit-scrollbar {
            display: none;
        }
        .nav-mode-item {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 14px 18px;
            font-size: 14px;
            font-weight: 600;
            color: #64748b;
            border-bottom: 3px solid transparent;
            cursor: pointer;
            transition: all 0.2s ease;
            user-select: none;
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
        .tab-badge {
            font-size: 11px;
            padding: 2px 8px;
            border-radius: 12px;
            font-weight: 700;
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
        /* 統計卡片 */
        .stat-card {
            background: #ffffff;
            border-radius: 10px;
            border: 1px solid var(--border-color);
            padding: 14px 18px;
            display: flex;
            align-items: center;
            gap: 14px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.03);
            transition: all 0.2s ease;
            cursor: pointer;
            height: 100%;
        }
        .stat-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
        }
        .stat-icon {
            width: 44px;
            height: 44px;
            border-radius: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.3rem;
            flex-shrink: 0;
        }
        .stat-val {
            font-size: 1.45rem;
            font-weight: 800;
            line-height: 1.2;
            color: var(--brand-navy);
        }
        .stat-label {
            font-size: 12px;
            font-weight: 600;
            color: #64748b;
        }
        /* 地圖容器與控制列 */
        #map {
            width: 100%;
            height: 380px;
            border-radius: 8px;
            z-index: 10;
            transition: height 0.3s ease;
        }
        #map.map-collapsed {
            height: 120px !important;
        }
        /* 批次操作浮動列 */
        .batch-action-bar {
            background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
            color: #ffffff;
            border-radius: 10px;
            padding: 12px 20px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 16px;
            box-shadow: 0 4px 14px rgba(15, 23, 42, 0.18);
            animation: slideDown 0.2s ease;
        }
        @keyframes slideDown {
            from { opacity: 0; transform: translateY(-8px); }
            to { opacity: 1; transform: translateY(0); }
        }
        /* 現代化表格 */
        .table-modern {
            width: 100%;
            border-collapse: separate;
            border-spacing: 0;
            margin: 0;
        }
        .table-modern th {
            background: #f8fafc;
            color: #475569;
            font-weight: 700;
            font-size: 13px;
            padding: 14px 16px;
            border-bottom: 2px solid var(--border-color);
            border-top: none;
            white-space: nowrap;
        }
        .table-modern td {
            padding: 14px 16px;
            vertical-align: middle;
            border-bottom: 1px solid var(--border-color);
            color: var(--text-main);
            font-size: 14px;
            background: #ffffff;
        }
        .table-modern tbody tr:hover td {
            background: #f1f5f9;
        }
        /* 狀態徽章 (Status Chip) */
        .status-chip {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 4px 10px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 700;
            white-space: nowrap;
        }
        .status-draft {
            background: #fef2f2;
            color: #dc2626;
            border: 1px solid #fecaca;
        }
        .status-back {
            background: #fffbeb;
            color: #b45309;
            border: 1px solid #fde68a;
        }
        .status-exam {
            background: #eff6ff;
            color: #1d4ed8;
            border: 1px solid #bfdbfe;
        }
        .status-done {
            background: #ecfdf5;
            color: #047857;
            border: 1px solid #a7f3d0;
        }
        .status-none {
            background: #f1f5f9;
            color: #64748b;
            border: 1px solid #cbd5e1;
        }
        /* 地目标籤 */
        .land-chip {
            background: #fef9c3;
            color: #854d0e;
            padding: 3px 10px;
            border-radius: 6px;
            font-size: 12px;
            font-weight: 700;
            border: 1px solid #fef08a;
            white-space: nowrap !important;
            display: inline-block;
            vertical-align: middle;
            line-height: 1.4;
        }
        /* 操作按鈕群組 - 嚴格單行不換行 */
        .action-btn-group {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 6px;
            flex-wrap: nowrap !important;
            white-space: nowrap !important;
        }
        .btn-action {
            padding: 5px 11px;
            font-size: 13px;
            font-weight: 600;
            border-radius: 6px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 5px;
            transition: all 0.15s ease;
            min-height: 34px;
            white-space: nowrap !important;
            flex-shrink: 0;
            text-decoration: none !important;
        }
        /* 手機卡片清單 (Mobile Card View) */
        .mobile-card {
            background: #ffffff;
            border: 1px solid var(--border-color);
            border-radius: 12px;
            padding: 16px;
            margin-bottom: 12px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
        }
        .mobile-card-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 10px;
            padding-bottom: 8px;
            border-bottom: 1px dashed var(--border-color);
        }
        .mobile-card-title {
            font-size: 1rem;
            font-weight: 700;
            color: var(--brand-navy);
            margin: 0;
        }
        @media (max-width: 767.98px) {
            .btn-action {
                flex: 1;
                justify-content: center;
                min-height: 42px;
                font-size: 14px;
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
        /* 查核紀錄抽屜/彈窗 Modal */
        .inv-history-item {
            background: #f8fafc;
            border: 1px solid var(--border-color);
            border-radius: 10px;
            padding: 16px;
            margin-bottom: 12px;
            transition: all 0.2s;
        }
        .inv-history-item:hover {
            border-color: var(--brand-blue);
            background: #ffffff;
            box-shadow: 0 2px 8px rgba(0,0,0,0.06);
        }
        /* 智慧標記 Marker Pin */
        .marker-pin-custom {
            width: 32px;
            height: 32px;
            border-radius: 50% 50% 50% 0;
            background: #9b741e;
            position: absolute;
            transform: rotate(-45deg);
            left: 50%;
            top: 50%;
            margin: -20px 0 0 -16px;
            box-shadow: 0 3px 8px rgba(0, 0, 0, 0.35);
            border: 2px solid #ffffff;
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
        }
        .marker-pin-custom i {
            transform: rotate(45deg);
            color: #ffffff;
            font-size: 13px;
        }
    </style>
</head>
<body>
    <div id="bareListApp" v-cloak>
        <!-- 頂部品牌導覽列 (全站統一標準：左側導航、右側主操作) -->
        <header class="top-navbar">
            <div class="d-flex align-items-center">
                <a href="../MainPage.aspx" class="nav-btn mr-2" title="返回主選單">
                    <i class="fas fa-home"></i>
                    <span class="d-none d-sm-inline">回首頁</span>
                </a>
                <a href="Bare_List.aspx" class="navbar-brand-title">
                    <i class="fas fa-mountain text-warning"></i>
                    <span>裸露地調查管理</span>
                    <span class="badge badge-light text-dark font-weight-bold ml-1">
                        {{ counts.Sites }} 處場址
                    </span>
                </a>
            </div>
            <div class="d-flex align-items-center gap-2">
                <a href="NewBare.aspx?mode=new" class="btn btn-success btn-sm font-weight-bold shadow-sm mr-2">
                    <i class="fas fa-plus-circle mr-1"></i>
                    <span class="d-none d-sm-inline">新增調查</span>
                </a>
                <button type="button" class="nav-btn" v-on:click="toggleMap" :title="showMap ? '收合地圖' : '展開地圖'">
                    <i class="fas" :class="showMap ? 'fa-compress-arrows-alt' : 'fa-map-marked-alt'"></i>
                    <span class="d-none d-lg-inline">{{ showMap ? '收合地圖' : '展開地圖' }}</span>
                </button>
            </div>
        </header>
        <!-- 業務模式分頁切換列 -->
        <nav class="nav-mode-bar">
            <div class="nav-mode-item" :class="{ 'active': currentMode === 'reject' }" v-on:click="switchMode('reject')">
                <i class="fas fa-edit"></i>
                <span>查核紀錄暫存 (草稿)</span>
                <span class="tab-badge badge badge-danger">{{ counts.Draft }}</span>
            </div>
            <div class="nav-mode-item" :class="{ 'active': currentMode === 'back' }" v-on:click="switchMode('back')">
                <i class="fas fa-undo-alt"></i>
                <span>退件紀錄待補正</span>
                <span class="tab-badge badge badge-warning text-dark">{{ counts.Back }}</span>
            </div>
            <div class="nav-mode-item" :class="{ 'active': currentMode === 'examine' }" v-on:click="switchMode('examine')">
                <i class="fas fa-clipboard-check"></i>
                <span>案件審核中</span>
                <span class="tab-badge badge badge-primary">{{ counts.Examine }}</span>
            </div>
            <div class="nav-mode-item" :class="{ 'active': currentMode === 'identify' }" v-on:click="switchMode('identify')">
                <i class="fas fa-check-circle"></i>
                <span>調查成果列表</span>
                <span class="tab-badge badge badge-success">{{ counts.Done }}</span>
            </div>
            <div class="nav-mode-item" :class="{ 'active': currentMode === 'all' }" v-on:click="switchMode('all')">
                <i class="fas fa-layer-group"></i>
                <span>全部裸露場址</span>
                <span class="tab-badge badge badge-dark">{{ counts.Sites }}</span>
            </div>
        </nav>
        <main class="container-fluid py-4 px-lg-4">
            <!-- 頂部統計指標卡片 -->
            <div class="row mb-3">
                <div class="col-6 col-lg-3 mb-2 mb-lg-0">
                    <div class="stat-card" v-on:click="switchMode('reject')">
                        <div class="stat-icon bg-light text-danger">
                            <i class="fas fa-file-signature"></i>
                        </div>
                        <div>
                            <div class="stat-val text-danger">{{ counts.Draft }}</div>
                            <div class="stat-label">暫存草稿 / 待修正</div>
                        </div>
                    </div>
                </div>
                <div class="col-6 col-lg-3 mb-2 mb-lg-0">
                    <div class="stat-card" v-on:click="switchMode('back')">
                        <div class="stat-icon bg-warning text-dark">
                            <i class="fas fa-exclamation-triangle"></i>
                        </div>
                        <div>
                            <div class="stat-val text-warning">{{ counts.Back }}</div>
                            <div class="stat-label">退件待重辦案件</div>
                        </div>
                    </div>
                </div>
                <div class="col-6 col-lg-3 mb-2 mb-lg-0">
                    <div class="stat-card" v-on:click="switchMode('examine')">
                        <div class="stat-icon bg-primary text-white">
                            <i class="fas fa-clock"></i>
                        </div>
                        <div>
                            <div class="stat-val text-primary">{{ counts.Examine }}</div>
                            <div class="stat-label">初複三審中案件</div>
                        </div>
                    </div>
                </div>
                <div class="col-6 col-lg-3 mb-2 mb-lg-0">
                    <div class="stat-card" v-on:click="switchMode('identify')">
                        <div class="stat-icon bg-success text-white">
                            <i class="fas fa-check-double"></i>
                        </div>
                        <div>
                            <div class="stat-val text-success">{{ counts.Done }}</div>
                            <div class="stat-label">調查成果已核定</div>
                        </div>
                    </div>
                </div>
            </div>
            <!-- 複合多條件篩選卡片 (標準折疊與操作列) -->
            <div class="card-modern">
                <div class="card-modern-header" style="cursor: pointer;" v-on:click="filterCollapsed = !filterCollapsed">
                    <h2 class="card-modern-title">
                        <i class="fas fa-filter text-primary"></i>
                        <span>場址與查核條件篩選</span>
                        <small class="text-muted font-weight-normal ml-2" v-if="hasActiveFilter">
                            (已套用自訂篩選)
                        </small>
                    </h2>
                    <button type="button" class="btn btn-link btn-sm text-muted p-0">
                        <i class="fas" :class="filterCollapsed ? 'fa-chevron-down' : 'fa-chevron-up'"></i>
                    </button>
                </div>
                <div class="card-modern-body" v-show="!filterCollapsed">
                    <div class="row">
                        <!-- 編號關鍵字 -->
                        <div class="col-12 col-md-3 mb-2">
                            <label class="font-weight-bold text-muted small mb-1">裸露地編號</label>
                            <input type="text" class="form-control form-control-sm" v-model="filter.bareGroundNo" placeholder="請輸入編號關鍵字..." v-on:keyup.enter="handleSearch" />
                        </div>
                        <!-- 地址關鍵字 -->
                        <div class="col-12 col-md-3 mb-2">
                            <label class="font-weight-bold text-muted small mb-1">場址地址</label>
                            <input type="text" class="form-control form-control-sm" v-model="filter.addr" placeholder="請輸入地址關鍵字..." v-on:keyup.enter="handleSearch" />
                        </div>
                        <!-- 地目 -->
                        <div class="col-12 col-md-2 mb-2">
                            <label class="font-weight-bold text-muted small mb-1">地目</label>
                            <input type="text" class="form-control form-control-sm" v-model="filter.landUse" placeholder="例如：林、田、建..." v-on:keyup.enter="handleSearch" />
                        </div>
                        <!-- 查核日期區間 -->
                        <div class="col-12 col-md-4 mb-2">
                            <label class="font-weight-bold text-muted small mb-1">最近查核日期區間</label>
                            <div class="d-flex align-items-center gap-2">
                                <input type="date" class="form-control form-control-sm" v-model="filter.dateS" />
                                <span class="text-muted px-1">至</span>
                                <input type="date" class="form-control form-control-sm" v-model="filter.dateE" />
                            </div>
                        </div>
                    </div>
                    <div class="d-flex flex-column flex-sm-row justify-content-between align-items-sm-center mt-2 pt-2 border-top">
                        <div class="small text-muted mb-2 mb-sm-0">
                            共查詢到 <strong class="text-primary">{{ pagination.totalCount }}</strong> 筆場址資料
                        </div>
                        <div class="d-flex align-items-center justify-content-end">
                            <button type="button" class="btn btn-outline-secondary btn-sm mr-2" v-on:click="resetFilter">
                                <i class="fas fa-undo mr-1"></i> 重設條件
                            </button>
                            <button type="button" class="btn btn-primary btn-sm px-3" v-on:click="handleSearch">
                                <i class="fas fa-search mr-1"></i> 立即查詢
                            </button>
                        </div>
                    </div>
                </div>
            </div>
            <!-- 智慧現場地圖卡片 (Leaflet) -->
            <div class="card-modern" v-show="showMap">
                <div class="card-modern-header">
                    <h2 class="card-modern-title">
                        <i class="fas fa-globe-asia text-info"></i>
                        <span>裸露地空間點位分布圖</span>
                        <small class="text-muted font-weight-normal d-none d-md-inline" style="font-size: 0.85rem;">(展示已標定座標之裸露地場址)</small>
                    </h2>
                    <div class="d-flex align-items-center gap-2">
                        <button type="button" class="btn btn-sm btn-outline-primary" v-on:click="locateUser" title="GPS 定位">
                            <i class="fas fa-crosshairs"></i>
                            <span class="d-none d-sm-inline ml-1">GPS 定位</span>
                        </button>
                        <button type="button" class="btn btn-sm btn-outline-secondary ml-1" v-on:click="fitMapBounds" title="重設全景">
                            <i class="fas fa-compress-arrows-alt"></i>
                            <span class="d-none d-sm-inline ml-1">重設全景</span>
                        </button>
                    </div>
                </div>
                <div class="card-modern-body p-0">
                    <div id="map"></div>
                </div>
            </div>
            <!-- 批次送審浮動列 -->
            <div v-if="selectedInvNos.length > 0" class="batch-action-bar">
                <div class="d-flex align-items-center gap-2">
                    <i class="fas fa-check-circle text-success" style="font-size: 1.2rem;"></i>
                    <span>已選取 <strong>{{ selectedInvNos.length }}</strong> 筆暫存案件</span>
                </div>
                <div class="d-flex align-items-center gap-2">
                    <button type="button" class="btn btn-success btn-sm font-weight-bold px-3 shadow-sm" v-on:click="batchUploadCheck">
                        <i class="fas fa-paper-plane mr-1"></i> 一鍵批次送出審查
                    </button>
                    <button type="button" class="btn btn-outline-light btn-sm ml-2" v-on:click="clearSelection">
                        取消選取
                    </button>
                </div>
            </div>
            <!-- 裸露地主清單卡片 (標準清單大四元操作工具列) -->
            <div class="card-modern">
                <div class="card-modern-header">
                    <div class="d-flex align-items-center gap-2">
                        <h2 class="card-modern-title">
                            <i class="fas fa-list-alt text-primary"></i>
                            <span>{{ getModeTitle() }}</span>
                        </h2>
                        <span class="badge badge-light border text-dark font-weight-bold ml-1">
                            共 {{ pagination.totalCount }} 筆
                        </span>
                        <span class="badge badge-secondary ml-1 d-none d-sm-inline">
                            頁次 {{ pagination.pageIndex }} / {{ totalPages }}
                        </span>
                    </div>
                    <div class="d-flex align-items-center">
                        <!-- 1. 重新整理 -->
                        <button type="button" class="btn btn-sm btn-outline-secondary mr-2" v-on:click="fetchList" :disabled="loading" title="重新整理資料">
                            <i class="fas fa-sync-alt mr-1" :class="{ 'fa-spin': loading }"></i>
                            <span class="d-none d-md-inline">重新整理</span>
                        </button>
                        <!-- 2. 匯出 EXCEL -->
                        <button type="button" class="btn btn-sm btn-outline-success font-weight-bold mr-2" v-on:click="exportExcel" :disabled="exporting || pagination.totalCount === 0" title="匯出篩選結果為 EXCEL 報表">
                            <i class="fas fa-file-excel mr-1"></i>
                            <span class="d-none d-md-inline">{{ exporting ? '匯出中...' : '匯出 EXCEL' }}</span>
                        </button>
                        <!-- 3. 每頁筆數選擇器 -->
                        <div class="d-inline-flex align-items-center">
                            <span class="small text-muted mr-1 d-none d-lg-inline">每頁：</span>
                            <select class="form-control form-control-sm d-inline-block w-auto" v-model="pagination.pageSize" v-on:change="changePageSize">
                                <option :value="10">10 筆</option>
                                <option :value="15">15 筆</option>
                                <option :value="30">30 筆</option>
                                <option :value="50">50 筆</option>
                            </select>
                        </div>
                    </div>
                </div>
                <div class="card-modern-body p-0">
                    <!-- 載入中遮罩 -->
                    <div v-if="loading" class="text-center py-5">
                        <div class="spinner-border text-primary" role="status">
                            <span class="sr-only">資料載入中...</span>
                        </div>
                        <p class="text-muted small mt-2">正在載入裸露地資料，請稍候...</p>
                    </div>
                    <!-- 無資料提示 -->
                    <div v-else-if="list.length === 0" class="text-center py-5">
                        <i class="fas fa-inbox text-muted" style="font-size: 3rem; opacity: 0.4;"></i>
                        <p class="text-muted font-weight-bold mt-3">查無符合條件的裸露地場所資料</p>
                        <button type="button" class="btn btn-sm btn-outline-primary" v-on:click="resetFilter">
                            重設篩選條件
                        </button>
                    </div>
                    <!-- 表格與卡片內容區 (以 template v-else 包覆，避免多個 v-else 導致渲染衝突) -->
                    <template v-else>
                        <!-- 桌面端表格 (Desktop Table) -->
                        <div class="d-none d-lg-block table-responsive">
                            <table class="table-modern">
                                <thead>
                                    <tr>
                                        <th style="width: 44px; text-align: center;">
                                            <input type="checkbox" v-model="selectAll" v-on:change="toggleSelectAll" title="全選本頁" />
                                        </th>
                                        <th style="width: 100px;">案號</th>
                                        <th style="width: 130px;">場址編號</th>
                                        <th>場址地址</th>
                                        <th style="width: 140px; min-width: 120px; white-space: nowrap;">地目</th>
                                        <th style="width: 150px;">查核時間</th>
                                        <th style="width: 180px;">堆置概況</th>
                                        <th style="width: 130px; text-align: center;">案件狀態</th>
                                        <th style="width: 250px; text-align: center;">功能操作</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr v-for="item in list" :key="item.INV_NO">
                                        <td style="text-align: center;">
                                            <input type="checkbox" v-model="item.Selected" v-on:change="onItemSelectChange" :disabled="!item.CanUpload" />
                                        </td>
                                        <td>
                                            <span class="badge badge-light border font-weight-bold text-dark">#{{ item.INV_NO }}</span>
                                        </td>
                                        <td>
                                            <strong class="text-primary font-weight-bold">{{ item.BareGroundNo }}</strong>
                                        </td>
                                        <td>
                                            <span class="font-weight-bold text-dark">{{ item.ADDR }}</span>
                                            <div v-if="item.Lat > 0 && item.Lng > 0" class="mt-1">
                                                <a href="javascript:void(0)" class="text-info small font-weight-bold" v-on:click="focusOnMap(item)">
                                                    <i class="fas fa-map-marker-alt text-danger mr-1"></i>{{ item.CoodText }}
                                                </a>
                                            </div>
                                        </td>
                                        <td style="white-space: nowrap;">
                                            <span v-if="item.LAND_USE && item.LAND_USE !== '--'" class="land-chip">
                                                {{ item.LAND_USE }}
                                            </span>
                                            <span v-else class="text-muted">--</span>
                                        </td>
                                        <td>
                                            <span class="text-dark small font-weight-bold">
                                                <i class="far fa-calendar-alt text-muted mr-1"></i>{{ item.Check_DATE }}
                                            </span>
                                        </td>
                                        <td>
                                            <div class="small text-muted" style="line-height: 1.4;">
                                                <div v-if="item.pVolume && item.pVolume !== '-'"><strong>總量:</strong> {{ item.pVolume }}m³</div>
                                                <div v-if="item.pArea && item.pArea !== '-'"><strong>面積:</strong> {{ item.pArea }}m²</div>
                                                <div v-if="(!item.pVolume || item.pVolume === '-') && (!item.pArea || item.pArea === '-')">--</div>
                                            </div>
                                        </td>
                                        <td style="text-align: center;">
                                            <span :class="getStatusClass(item.INV_State)">
                                                <i :class="getStatusIcon(item.INV_State)"></i>
                                                {{ item.State_Name }}
                                            </span>
                                        </td>
                                        <td style="text-align: center;">
                                            <div class="action-btn-group">
                                                <!-- 若為草稿/待補正案件，提供快捷送審 -->
                                                <button v-if="item.CanUpload" type="button" class="btn btn-success btn-action" v-on:click="uploadCheck(item.Bare_ID, item.INV_NO)" title="送出審查">
                                                    <i class="fas fa-paper-plane"></i>
                                                    <span>送審</span>
                                                </button>
                                                <!-- 修改資料 (草稿/待補正) -->
                                                <a v-if="item.CanEdit" :href="'NewBare.aspx?mode=edit&id=' + item.Bare_ID + '&id1=' + item.Token + '&id2=' + item.INV_NO + '&back=' + currentMode" class="btn btn-warning btn-action text-dark" title="修改案件資料">
                                                    <i class="fas fa-edit"></i>
                                                    <span>修改</span>
                                                </a>
                                                <!-- 簽名 -->
                                                <a :href="'BareResult.aspx?id=' + item.Bare_ID + '&id1=' + item.Token + '&id2=' + item.INV_NO + '&mode=sig'" class="btn btn-outline-primary btn-action" title="檢視/簽名">
                                                    <i class="fas fa-signature"></i>
                                                    <span>簽名</span>
                                                </a>
                                                <!-- 詳細成果檢視 -->
                                                <a :href="'BareResult.aspx?id=' + item.Bare_ID + '&id1=' + item.Token + '&id2=' + item.INV_NO + '&mode=read'" class="btn btn-outline-secondary btn-action" title="檢視案件詳細資料">
                                                    <i class="fas fa-eye"></i>
                                                    <span>詳細</span>
                                                </a>
                                                <!-- 查核紀錄 (歷次清單) -->
                                                <button type="button" class="btn btn-outline-info btn-action" v-on:click="openHistoryModal(item)" title="檢視此場址歷次查核">
                                                    <i class="fas fa-history"></i>
                                                    <span>場址歷程</span>
                                                </button>
                                            </div>
                                        </td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                        <!-- 行動端卡片佈局 (Mobile Card View) -->
                        <div class="d-lg-none p-3">
                            <div v-for="item in list" :key="item.INV_NO" class="mobile-card">
                                <div class="mobile-card-header">
                                    <div class="d-flex align-items-center gap-2">
                                        <input v-if="item.CanUpload" type="checkbox" v-model="item.Selected" v-on:change="onItemSelectChange" />
                                        <span class="badge badge-light border text-dark font-weight-bold">#{{ item.INV_NO }}</span>
                                        <span class="mobile-card-title text-primary">{{ item.BareGroundNo }}</span>
                                    </div>
                                    <span :class="getStatusClass(item.INV_State)">
                                        {{ item.State_Name }}
                                    </span>
                                </div>
                                <div class="small mb-2">
                                    <div class="mb-1">
                                        <strong class="text-muted"><i class="fas fa-map-pin mr-1"></i> 地址：</strong>
                                        <span>{{ item.ADDR }}</span>
                                    </div>
                                    <div class="d-flex justify-content-between mb-1">
                                        <div>
                                            <strong class="text-muted"><i class="fas fa-layer-group mr-1"></i> 地目：</strong>
                                            <span class="land-chip">{{ item.LAND_USE || '--' }}</span>
                                        </div>
                                        <div>
                                            <strong class="text-muted"><i class="far fa-calendar-alt mr-1"></i> 時間：</strong>
                                            <span>{{ item.Check_DATE }}</span>
                                        </div>
                                    </div>
                                    <div v-if="item.AreaDetail" class="mb-1 text-muted">
                                        <strong class="text-dark">概況：</strong>{{ item.AreaDetail }}
                                    </div>
                                    <div v-if="item.Lat > 0 && item.Lng > 0" class="mb-1">
                                        <strong class="text-muted"><i class="fas fa-crosshairs mr-1"></i> 座標：</strong>
                                        <a href="javascript:void(0)" class="text-info font-weight-bold" v-on:click="focusOnMap(item)">
                                            {{ item.CoodText }}
                                        </a>
                                    </div>
                                </div>
                                <div class="d-flex gap-2 mt-3 pt-2 border-top">
                                    <button v-if="item.CanUpload" type="button" class="btn btn-success btn-action flex-fill" v-on:click="uploadCheck(item.Bare_ID, item.INV_NO)">
                                        <i class="fas fa-paper-plane mr-1"></i> 送審
                                    </button>
                                    <a v-if="item.CanEdit" :href="'NewBare.aspx?mode=edit&id=' + item.Bare_ID + '&id1=' + item.Token + '&id2=' + item.INV_NO + '&back=' + currentMode" class="btn btn-warning btn-action text-dark flex-fill">
                                        <i class="fas fa-edit mr-1"></i> 修改
                                    </a>
                                    <a :href="'BareResult.aspx?id=' + item.Bare_ID + '&id1=' + item.Token + '&id2=' + item.INV_NO + '&mode=read'" class="btn btn-outline-secondary btn-action flex-fill">
                                        <i class="fas fa-eye mr-1"></i> 詳細
                                    </a>
                                    <button type="button" class="btn btn-outline-info btn-action" v-on:click="openHistoryModal(item)">
                                        <i class="fas fa-history"></i>
                                    </button>
                                </div>
                            </div>
                        </div>
                    </template>
                    <!-- 自適應底部分頁導覽列 (Responsive Pagination Footer) -->
                    <div v-if="!loading && pagination.totalCount > 0" class="pagination-footer">
                        <div class="pagination-footer-info">
                            顯示第 <strong class="text-dark">{{ (pagination.pageIndex - 1) * pagination.pageSize + 1 }}</strong> 至 <strong class="text-dark">{{ Math.min(pagination.pageIndex * pagination.pageSize, pagination.totalCount) }}</strong> 筆，共 <strong class="text-dark">{{ pagination.totalCount }}</strong> 筆
                        </div>
                        <div class="pagination-action-group">
                            <button type="button" class="btn-page-ctrl btn-edge" :disabled="pagination.pageIndex <= 1" v-on:click="goToPage(1)" title="第一頁">
                                <i class="fas fa-angle-double-left"></i>
                                <span class="d-none d-md-inline ml-1">首頁</span>
                            </button>
                            <button type="button" class="btn-page-ctrl btn-step" :disabled="pagination.pageIndex <= 1" v-on:click="goToPage(pagination.pageIndex - 1)" title="上一頁">
                                <i class="fas fa-chevron-left mr-1"></i>
                                <span>上一頁</span>
                            </button>
                            <div class="page-indicator-pill" title="目前頁次 / 總頁數">
                                <span>{{ pagination.pageIndex }}</span>
                                <span class="mx-1 text-muted" style="opacity: 0.5; font-weight: normal;">/</span>
                                <span>{{ pagination.totalPages }}</span>
                            </div>
                            <button type="button" class="btn-page-ctrl btn-step" :disabled="pagination.pageIndex >= pagination.totalPages" v-on:click="goToPage(pagination.pageIndex + 1)" title="下一頁">
                                <span>下一頁</span>
                                <i class="fas fa-chevron-right ml-1"></i>
                            </button>
                            <button type="button" class="btn-page-ctrl btn-edge" :disabled="pagination.pageIndex >= pagination.totalPages" v-on:click="goToPage(pagination.totalPages)" title="最後一頁">
                                <span class="d-none d-md-inline ml-1">末頁</span>
                                <i class="fas fa-angle-double-right"></i>
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </main>
        <!-- 歷次查核紀錄彈窗 (Inspection History Modal) -->
        <div class="modal fade" id="historyModal" tabindex="-1" role="dialog" aria-hidden="true">
            <div class="modal-dialog modal-lg modal-dialog-scrollable" role="document">
                <div class="modal-content">
                    <div class="modal-header bg-light">
                        <h5 class="modal-title font-weight-bold text-dark">
                            <i class="fas fa-history text-info mr-2"></i>
                            <span>裸露地歷次查核紀錄</span>
                            <span v-if="currentSite" class="badge badge-primary ml-2">{{ currentSite.BareGroundNo }}</span>
                        </h5>
                        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                            <span aria-hidden="true">&times;</span>
                        </button>
                    </div>
                    <div class="modal-body p-3">
                        <div v-if="currentSite" class="mb-3 p-3 bg-white border rounded">
                            <div class="row small">
                                <div class="col-12 col-md-6 mb-1">
                                    <strong>場址地址：</strong>{{ currentSite.ADDR }}
                                </div>
                                <div class="col-6 col-md-3 mb-1">
                                    <strong>地目：</strong><span class="land-chip">{{ currentSite.LAND_USE || '--' }}</span>
                                </div>
                                <div class="col-6 col-md-3 mb-1">
                                    <strong>GPS座標：</strong>{{ currentSite.CoodText }}
                                </div>
                            </div>
                        </div>
                        <!-- 歷史紀錄載入遮罩 -->
                        <div v-if="historyLoading" class="text-center py-4">
                            <div class="spinner-border spinner-border-sm text-primary"></div>
                            <span class="ml-2 text-muted small">載入歷次查核資料中...</span>
                        </div>
                        <!-- 無查核紀錄 -->
                        <div v-else-if="historyList.length === 0" class="text-center py-4 text-muted">
                            <i class="fas fa-clipboard-list" style="font-size: 2rem; opacity: 0.3;"></i>
                            <p class="mt-2 font-weight-bold">該場址目前尚無查核紀錄</p>
                            <a :href="'NewBare.aspx?mode=new&bareId=' + (currentSite ? currentSite.Bare_ID : '')" class="btn btn-sm btn-primary">
                                <i class="fas fa-plus mr-1"></i> 新增查核
                            </a>
                        </div>
                        <!-- 歷次查核紀錄清單卡片 -->
                        <div v-else>
                            <div v-for="inv in historyList" :key="inv.INV_NO" class="inv-history-item">
                                <div class="d-flex justify-content-between align-items-center mb-2">
                                    <div class="font-weight-bold text-dark">
                                        <i class="far fa-calendar-check text-success mr-1"></i>
                                        <span>查核時間：{{ inv.Check_DATE }}</span>
                                        <span class="text-muted small ml-2">(案號 #{{ inv.INV_NO }})</span>
                                    </div>
                                    <span :class="getStatusClass(inv.INV_State)">
                                        {{ inv.State_Name }}
                                    </span>
                                </div>
                                <div class="small text-muted mb-2">
                                    <div v-if="inv.Around_Memo" class="mb-1">
                                        <strong class="text-dark">場址周界概況：</strong>{{ inv.Around_Memo }}
                                    </div>
                                    <div v-if="inv.Waste_Type" class="mb-1">
                                        <strong class="text-dark">廢棄物種類、外觀：</strong>{{ inv.Waste_Type }}
                                    </div>
                                    <div v-if="inv.AreaDetail" class="mb-1">
                                        <strong class="text-dark">堆置面積及高度：</strong>{{ inv.AreaDetail }}
                                    </div>
                                    <div v-if="inv.surroundings" class="mb-1">
                                        <strong class="text-dark">環境概況說明：</strong>{{ inv.surroundings }}
                                    </div>
                                </div>
                                <div class="d-flex justify-content-end align-items-center gap-2 pt-2 border-top">
                                    <!-- 修改資料 -->
                                    <a v-if="inv.CanEdit" :href="'NewBare.aspx?mode=edit&id=' + inv.Bare_ID + '&id1=' + inv.Token + '&id2=' + inv.INV_NO + '&back=' + currentMode" class="btn btn-sm btn-warning font-weight-bold text-dark">
                                        <i class="fas fa-edit mr-1"></i> 修改資料
                                    </a>
                                    <!-- 送出審核 -->
                                    <button v-if="inv.CanUpload" type="button" class="btn btn-sm btn-success font-weight-bold" v-on:click="uploadCheck(inv.Bare_ID, inv.INV_NO)">
                                        <i class="fas fa-paper-plane mr-1"></i> 送審
                                    </button>
                                    <!-- 簽名 -->
                                    <a :href="'BareResult.aspx?id=' + inv.Bare_ID + '&id1=' + inv.Token + '&id2=' + inv.INV_NO + '&mode=sig'" class="btn btn-sm btn-outline-primary">
                                        <i class="fas fa-signature mr-1"></i> 簽名
                                    </a>
                                    <!-- 詳細資料 -->
                                    <a :href="'BareResult.aspx?id=' + inv.Bare_ID + '&id1=' + inv.Token + '&id2=' + inv.INV_NO + '&mode=read'" class="btn btn-sm btn-outline-secondary">
                                        <i class="fas fa-eye mr-1"></i> 詳細
                                    </a>
                                    <!-- 刪除案件 -->
                                    <button v-if="inv.CanDelete" type="button" class="btn btn-sm btn-outline-danger" v-on:click="deleteInv(inv.Bare_ID, inv.INV_NO)">
                                        <i class="fas fa-trash-alt mr-1"></i> 刪除
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="modal-footer bg-light">
                        <button type="button" class="btn btn-secondary font-weight-bold" data-dismiss="modal">
                            關閉視窗
                        </button>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <!-- 本地腳本依賴 -->
    <script src="../Scripts/jquery-3.6.4.min.js"></script>
    <script src="../Scripts/bootstrap.bundle.min.js"></script>
    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>
    <script src="../Scripts/leaflet/leaflet.js"></script>
    <script>
        const { createApp, markRaw } = Vue;
        createApp({
            data() {
                // 從 URL QueryString 讀取模式
                const urlParams = new URLSearchParams(window.location.search);
                const initMode = urlParams.get('mode') || 'all';
                return {
                    currentMode: initMode,
                    loading: false,
                    list: [],
                    counts: {
                        Draft: 0,
                        Back: 0,
                        Examine: 0,
                        Done: 0,
                        Sites: 0,
                        TotalInv: 0
                    },
                    filter: {
                        bareGroundNo: '',
                        addr: '',
                        landUse: '',
                        dateS: '',
                        dateE: '',
                        stateFilter: ''
                    },
                    pagination: {
                        pageIndex: 1,
                        pageSize: 15,
                        totalCount: 0,
                        totalPages: 0
                    },
                    showMap: true,
                    exporting: false,
                    selectAll: false,
                    selectedInvNos: [],
                    currentSite: null,
                    historyList: [],
                    historyLoading: false
                };
            },
            mounted() {
                this.initMap();
                this.fetchCounts();
                this.fetchList();
                this.fetchMapData();
                setTimeout(() => {
                    if (this.leafletMap) {
                        this.leafletMap.invalidateSize();
                    }
                }, 400);
            },
            methods: {
                // 1. 初始化 Leaflet 地圖 (遵守物件隔離與零遮擋規範)
                initMap() {
                    const mapEl = document.getElementById('map');
                    if (!mapEl) return;
                    // 新北市中心點
                    const defaultCenter = [25.012, 121.465];
                    const mapInstance = L.map('map', {
                        center: defaultCenter,
                        zoom: 11,
                        zoomControl: false // 自行擺放控制項，防止遮擋
                    });
                    L.control.zoom({ position: 'bottomright' }).addTo(mapInstance);
                    // 臺灣通用電子地圖與開源底圖圖層切換
                    const emapLayer = L.tileLayer('https://wmts.nlsc.gov.tw/wmts/EMAP/default/GoogleMapsCompatible/{z}/{y}/{x}', {
                        maxZoom: 19,
                        attribution: '&copy; 內政部國土測繪中心'
                    });
                    const photoLayer = L.tileLayer('https://wmts.nlsc.gov.tw/wmts/PHOTO2/default/GoogleMapsCompatible/{z}/{y}/{x}', {
                        maxZoom: 19,
                        attribution: '&copy; 內政部國土測繪中心'
                    });
                    const osmLayer = L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                        maxZoom: 19,
                        attribution: '&copy; OpenStreetMap'
                    });
                    emapLayer.addTo(mapInstance);
                    const baseMaps = {
                        "臺灣通用電子地圖": emapLayer,
                        "正射影像圖": photoLayer,
                        "OpenStreetMap": osmLayer
                    };
                    L.control.layers(baseMaps, null, { position: 'topright' }).addTo(mapInstance);
                    // 建立 Marker 圖層群組
                    const markerGroup = L.layerGroup().addTo(mapInstance);
                    // 原生隔離屬性保存，嚴禁放在 Vue data 響應式中
                    this.leafletMap = markRaw(mapInstance);
                    this.leafletMarkerGroup = markRaw(markerGroup);
                },
                // 2. 取得案件狀態 KPI 數量
                fetchCounts() {
                    axios.get('Bare_List.aspx?action=getcounts')
                        .then(res => {
                            if (res.data && res.data.Success) {
                                this.counts = res.data.Counts;
                            }
                        })
                        .catch(err => {
                            console.error('取得計數失敗', err);
                        });
                },
                // 3. 取得裸露地場址與最新查核清單
                fetchList() {
                    this.loading = true;
                    this.selectAll = false;
                    this.selectedInvNos = [];
                    const payload = {
                        Mode: this.currentMode,
                        BareGroundNo: this.filter.bareGroundNo,
                        Addr: this.filter.addr,
                        LandUse: this.filter.landUse,
                        DateS: this.filter.dateS,
                        DateE: this.filter.dateE,
                        StateFilter: this.filter.stateFilter,
                        PageIndex: this.pagination.pageIndex,
                        PageSize: this.pagination.pageSize
                    };
                    axios.post('Bare_List.aspx?action=getlist', payload)
                        .then(res => {
                            this.loading = false;
                            if (res.data && res.data.Success) {
                                this.list = res.data.Data || [];
                                this.pagination.totalCount = res.data.Pagination.TotalCount;
                                this.pagination.totalPages = res.data.Pagination.TotalPages;
                                this.pagination.pageIndex = res.data.Pagination.PageIndex;
                            } else {
                                alert(res.data.Message || '載入失敗');
                            }
                        })
                        .catch(err => {
                            this.loading = false;
                            console.error('查詢清單失敗', err);
                        });
                },
                // 匯出 Excel
                exportExcel() {
                    if (this.exporting) return;
                    this.exporting = true;
                    const params = new URLSearchParams();
                    params.append('action', 'exportexcel');
                    params.append('mode', this.currentMode || 'all');
                    if (this.filter.bareGroundNo) params.append('bareGroundNo', this.filter.bareGroundNo.trim());
                    if (this.filter.addr) params.append('addr', this.filter.addr.trim());
                    if (this.filter.landUse) params.append('landUse', this.filter.landUse.trim());
                    if (this.filter.dateS) params.append('dateS', this.filter.dateS);
                    if (this.filter.dateE) params.append('dateE', this.filter.dateE);
                    if (this.filter.stateFilter) params.append('stateFilter', this.filter.stateFilter);
                    const downloadUrl = 'Bare_List.aspx?' + params.toString();
                    let iframe = document.getElementById('exportIframe');
                    if (!iframe) {
                        iframe = document.createElement('iframe');
                        iframe.id = 'exportIframe';
                        iframe.style.display = 'none';
                        document.body.appendChild(iframe);
                    }
                    iframe.src = downloadUrl;
                    setTimeout(() => {
                        this.exporting = false;
                    }, 2500);
                },
                // 4. 取得智慧地圖點位並渲染
                fetchMapData() {
                    axios.get('Bare_List.aspx?action=getmapdata')
                        .then(res => {
                            if (res.data && res.data.Success && this.leafletMarkerGroup) {
                                this.leafletMarkerGroup.clearLayers();
                                const markers = res.data.Markers || [];
                                const bounds = [];
                                markers.forEach(m => {
                                    if (m.Lat > 0 && m.Lng > 0) {
                                        const latLng = [m.Lat, m.Lng];
                                        bounds.push(latLng);
                                        // 自訂 HTML Marker Pin
                                        const customIcon = L.divIcon({
                                            className: 'custom-map-marker',
                                            html: '<div class="marker-pin-custom"><i class="fas fa-mountain"></i></div>',
                                            iconSize: [32, 32],
                                            iconAnchor: [16, 32],
                                            popupAnchor: [0, -32]
                                        });
                                        const popupContent = `
                                            <div style="min-width: 220px; font-size: 13px;">
                                                <div style="font-weight: 700; color: #0284c7; font-size: 14px; margin-bottom: 4px;">
                                                    <i class="fas fa-hashtag"></i> ${m.BareGroundNo}
                                                </div>
                                                <div style="margin-bottom: 4px;"><strong>地址：</strong>${m.ADDR}</div>
                                                <div style="margin-bottom: 4px;"><strong>地目：</strong>${m.LAND_USE}</div>
                                                <div style="margin-bottom: 4px;"><strong>最近查核：</strong>${m.LastDate}</div>
                                                <div style="margin-bottom: 8px;"><strong>狀態：</strong>${m.StateName}</div>
                                                <a href="https://www.google.com/maps/dir/?api=1&destination=${m.Lat},${m.Lng}" target="_blank" class="btn btn-sm btn-outline-success font-weight-bold" style="width: 100%; text-align: center;">
                                                    <i class="fas fa-location-arrow"></i> Google 導航
                                                </a>
                                            </div>
                                        `;
                                        const marker = L.marker(latLng, { icon: customIcon }).bindPopup(popupContent);
                                        this.leafletMarkerGroup.addLayer(marker);
                                    }
                                });
                                if (bounds.length > 0 && this.leafletMap) {
                                    this.mapBounds = bounds;
                                    this.fitMapBounds();
                                    this.leafletMap.invalidateSize();
                                }
                            }
                        })
                        .catch(err => {
                            console.error('取得地圖點位失敗', err);
                        });
                },
                // 地圖重設全景
                fitMapBounds() {
                    if (this.leafletMap && this.mapBounds && this.mapBounds.length > 0) {
                        this.leafletMap.fitBounds(this.mapBounds, { padding: [30, 30] });
                    }
                },
                // 定位使用者 GPS
                locateUser() {
                    if (!navigator.geolocation) {
                        alert('您的瀏覽器不支援 GPS 定位');
                        return;
                    }
                    navigator.geolocation.getCurrentPosition(pos => {
                        const lat = pos.coords.latitude;
                        const lng = pos.coords.longitude;
                        if (this.leafletMap) {
                            this.leafletMap.setView([lat, lng], 15);
                            L.circleMarker([lat, lng], {
                                radius: 8,
                                fillColor: '#0284c7',
                                color: '#ffffff',
                                weight: 2,
                                opacity: 1,
                                fillOpacity: 0.9
                            }).addTo(this.leafletMap).bindPopup('您的目前位置').openPopup();
                        }
                    }, err => {
                        alert('無法取得定位資訊：' + err.message);
                    });
                },
                // 聚焦於指定場址座標
                focusOnMap(item) {
                    if (!this.showMap) {
                        this.showMap = true;
                    }
                    this.$nextTick(() => {
                        if (this.leafletMap && item.Lat > 0 && item.Lng > 0) {
                            this.leafletMap.setView([item.Lat, item.Lng], 16);
                            // 捲動至地圖區域
                            const mapEl = document.getElementById('map');
                            if (mapEl) {
                                mapEl.scrollIntoView({ behavior: 'smooth', block: 'center' });
                            }
                        }
                    });
                },
                // 切換地圖顯示/收合
                toggleMap() {
                    this.showMap = !this.showMap;
                    if (this.showMap && this.leafletMap) {
                        this.$nextTick(() => {
                            this.leafletMap.invalidateSize();
                        });
                    }
                },
                // 切換業務模式
                switchMode(mode) {
                    this.currentMode = mode;
                    this.pagination.pageIndex = 1;
                    this.fetchList();
                    // 更新網址 QueryString (不刷新頁面)
                    const newUrl = window.location.pathname + '?mode=' + mode;
                    window.history.replaceState({ path: newUrl }, '', newUrl);
                },
                // 搜尋與重設
                handleSearch() {
                    this.pagination.pageIndex = 1;
                    this.fetchList();
                },
                resetFilter() {
                    this.filter = {
                        bareGroundNo: '',
                        addr: '',
                        landUse: '',
                        dateS: '',
                        dateE: '',
                        stateFilter: ''
                    };
                    this.pagination.pageIndex = 1;
                    this.fetchList();
                },
                // 分頁切換
                goToPage(p) {
                    if (p < 1 || p > this.pagination.totalPages || p === this.pagination.pageIndex) return;
                    this.pagination.pageIndex = p;
                    this.fetchList();
                },
                // 全選與勾選切換
                toggleSelectAll() {
                    const checked = this.selectAll;
                    this.list.forEach(item => {
                        if (item.CanUpload) {
                            item.Selected = checked;
                        }
                    });
                    this.updateSelectedInvNos();
                },
                onItemSelectChange() {
                    this.updateSelectedInvNos();
                    this.selectAll = this.list.length > 0 && this.list.every(i => i.Selected || !i.CanUpload);
                },
                updateSelectedInvNos() {
                    this.selectedInvNos = this.list
                        .filter(i => i.Selected && i.CanUpload && (i.INV_NO || i.Last_INV_NO) > 0)
                        .map(i => i.INV_NO || i.Last_INV_NO);
                },
                clearSelection() {
                    this.selectAll = false;
                    this.list.forEach(i => i.Selected = false);
                    this.selectedInvNos = [];
                },
                // 單筆送審
                uploadCheck(bareId, invNo) {
                    if (!confirm('是否確定將案件 (案號 #' + invNo + ') 送出審查？')) return;
                    axios.post('Bare_List.aspx?action=uploadcheck&bareId=' + bareId + '&invNo=' + invNo)
                        .then(res => {
                            if (res.data && res.data.Success) {
                                alert(res.data.Message);
                                this.fetchCounts();
                                this.fetchList();
                                if (this.currentSite && this.currentSite.Bare_ID === bareId) {
                                    this.fetchInvHistory(bareId);
                                }
                            } else {
                                alert(res.data.Message || '送審失敗');
                            }
                        })
                        .catch(err => {
                            alert('送審作業發生異常');
                        });
                },
                // 批次送審
                batchUploadCheck() {
                    if (this.selectedInvNos.length === 0) return;
                    if (!confirm('是否確定將已勾選的 ' + this.selectedInvNos.length + ' 筆暫存案件批次送出審查？')) return;
                    axios.post('Bare_List.aspx?action=batchuploadcheck', { InvNos: this.selectedInvNos })
                        .then(res => {
                            if (res.data && res.data.Success) {
                                alert(res.data.Message);
                                this.clearSelection();
                                this.fetchCounts();
                                this.fetchList();
                            } else {
                                alert(res.data.Message || '批次送審失敗');
                            }
                        })
                        .catch(err => {
                            alert('批次送審作業發生異常');
                        });
                },
                // 刪除查核紀錄
                deleteInv(bareId, invNo) {
                    if (!confirm('是否確定刪除此筆查核紀錄 (案號 #' + invNo + ')？刪除後將無法還原！')) return;
                    axios.post('Bare_List.aspx?action=delinv&bareId=' + bareId + '&invNo=' + invNo)
                        .then(res => {
                            if (res.data && res.data.Success) {
                                alert(res.data.Message);
                                this.fetchCounts();
                                this.fetchList();
                                if (this.currentSite) {
                                    this.fetchInvHistory(bareId);
                                }
                            } else {
                                alert(res.data.Message || '刪除失敗');
                            }
                        })
                        .catch(err => {
                            alert('刪除作業發生異常');
                        });
                },
                // 開啟歷次查核紀錄 Modal
                openHistoryModal(site) {
                    this.currentSite = site;
                    this.historyList = [];
                    this.historyLoading = true;
                    $('#historyModal').modal('show');
                    this.fetchInvHistory(site.Bare_ID);
                },
                // 載入場址查核歷史
                fetchInvHistory(bareId) {
                    this.historyLoading = true;
                    axios.get('Bare_List.aspx?action=getinvlist&bareId=' + bareId)
                        .then(res => {
                            this.historyLoading = false;
                            if (res.data && res.data.Success) {
                                this.historyList = res.data.Data || [];
                            } else {
                                alert(res.data.Message || '載入歷史紀錄失敗');
                            }
                        })
                        .catch(err => {
                            this.historyLoading = false;
                            console.error('載入查核歷史異常', err);
                        });
                },
                // 標題切換
                getModeTitle() {
                    switch (this.currentMode) {
                        case 'reject':
                            return '查核紀錄暫存 (草稿待修正)';
                        case 'back':
                            return '退件紀錄 (待重辦案件)';
                        case 'examine':
                            return '案件初複三審中清單';
                        case 'identify':
                            return '調查成果核定列表';
                        default:
                            return '全部裸露地場址清單';
                    }
                },
                // 狀態樣式對應
                getStatusClass(state) {
                    if (!state) return 'status-chip status-none';
                    if (state === 'A00a') return 'status-chip status-draft';
                    if (state === 'A00b') return 'status-chip status-back';
                    if (state === 'A00' || state === 'A01' || state === 'A02') return 'status-chip status-exam';
                    if (state === 'A03' || state === 'A04') return 'status-chip status-done';
                    return 'status-chip status-none';
                },
                getStatusIcon(state) {
                    if (state === 'A00a') return 'fas fa-pencil-alt';
                    if (state === 'A00b') return 'fas fa-exclamation-circle';
                    if (state === 'A00' || state === 'A01' || state === 'A02') return 'fas fa-hourglass-half';
                    if (state === 'A03' || state === 'A04') return 'fas fa-check-circle';
                    return 'fas fa-info-circle';
                }
            }
        }).mount('#bareListApp');
    </script>
</body>
</html>
