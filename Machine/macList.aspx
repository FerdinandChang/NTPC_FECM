<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="macList.aspx.cs" Inherits="NTPC_FEC.Machine.macList" %>

<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定溢散源管理平台 - 作業機具自主管理與檢測清單</title>

    <!-- 專屬 Favicon -->
    <link rel="shortcut icon" href="../favicon.ico" type="image/x-icon" />

    <!-- 本地化核心樣式庫 (無外部 CDN) -->
    <link rel="stylesheet" href="../Content/bootstrap.min.css" />
    <link rel="stylesheet" href="../Content/fontawesome/css/all.min.css" />

    <style>
        :root {
            --brand-primary: #0099e5;     /* 新北天空青藍 (Navbar/強調) */
            --brand-blue: #0284c7;        /* 科技藍 (按鈕/選中) */
            --brand-dark-blue: #0b1f7d;   /* 海軍深藍 (標題/Tag) */
            --brand-navy: #0f172a;        /* 標題文字主色 */
            --brand-purple: #7c3aed;      /* 機具模組代表紫 */
            --brand-purple-light: #f5f3ff;
            --bg-canvas: #f8fafc;         /* 頁面灰底 */
            --surface: #ffffff;           /* 卡片純白底色 */
            --border-color: #e2e8f0;      /* 邊框線條 */
            --text-main: #0f172a;         /* 內文主要文字 */
            --text-muted: #64748b;        /* 次要說明文字 */
            --accent-success: #10b981;    /* 綠色成功/合格 */
            --accent-warning: #f59e0b;    /* 黃橘色注意/暫存 */
            --accent-danger: #ef4444;     /* 紅色缺失/危險 */
        }

        * {
            box-sizing: border-box;
            -webkit-tap-highlight-color: transparent;
        }

        html, body {
            margin: 0 !important;
            padding: 0 !important;
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

        /* 模式切換頁籤列 */
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
            font-size: 0.95rem;
            font-weight: 600;
            color: var(--text-muted);
            border-bottom: 3px solid transparent;
            cursor: pointer;
            transition: all 0.2s;
            text-decoration: none;
        }
        .nav-mode-item:hover {
            color: var(--brand-blue);
            text-decoration: none;
        }
        .nav-mode-item.active {
            color: var(--brand-blue);
            border-bottom-color: var(--brand-blue);
        }

        /* 主容器佈局 */
        .main-container {
            max-width: 1560px;
            margin: 0 auto;
            padding: 20px;
        }

        /* 現代卡片 */
        .card-modern {
            background: var(--surface);
            border-radius: 12px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05), 0 4px 12px rgba(15, 23, 42, 0.04);
            margin-bottom: 20px;
            border: 1px solid var(--border-color);
            overflow: hidden;
            transition: box-shadow 0.2s ease;
        }

        .card-modern-header {
            padding: 14px 20px;
            background: #ffffff;
            border-bottom: 1px solid var(--border-color);
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-wrap: wrap;
            gap: 10px;
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

        /* 統計指標卡片 (Stat Cards) */
        .stat-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
            gap: 16px;
            margin-bottom: 20px;
        }

        .stat-card {
            background: #ffffff;
            border-radius: 12px;
            border: 1px solid var(--border-color);
            padding: 16px 20px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
            transition: transform 0.2s, box-shadow 0.2s;
        }
        .stat-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
        }
        .stat-label {
            font-size: 0.85rem;
            font-weight: 600;
            color: var(--text-muted);
            margin-bottom: 4px;
        }
        .stat-value {
            font-size: 1.65rem;
            font-weight: 800;
            color: var(--brand-navy);
            line-height: 1.2;
        }
        .stat-icon {
            width: 48px;
            height: 48px;
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.3rem;
        }
        .stat-icon.primary { background: #e0f2fe; color: #0284c7; }
        .stat-icon.purple { background: #ede9fe; color: #7c3aed; }
        .stat-icon.warning { background: #fef3c7; color: #d97706; }
        .stat-icon.success { background: #d1fae5; color: #059669; }

        /* 視角切換膠囊 (View Switcher) */
        .view-switcher {
            display: inline-flex;
            background: #e2e8f0;
            padding: 3px;
            border-radius: 8px;
            gap: 3px;
        }
        .view-btn {
            border: none;
            background: transparent;
            padding: 6px 16px;
            border-radius: 6px;
            font-size: 0.88rem;
            font-weight: 600;
            color: #475569;
            cursor: pointer;
            transition: all 0.2s;
            display: inline-flex;
            align-items: center;
            gap: 6px;
        }
        .view-btn.active {
            background: #ffffff;
            color: var(--brand-blue);
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
        }

        /* 篩選欄位 */
        .filter-row {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 14px;
        }
        .form-group-custom label {
            font-size: 0.84rem;
            font-weight: 600;
            color: var(--brand-navy);
            margin-bottom: 5px;
            display: block;
        }
        .form-control-custom {
            height: 38px;
            border-radius: 8px;
            border: 1px solid #cbd5e1;
            font-size: 0.9rem;
            padding: 6px 12px;
            width: 100%;
            transition: all 0.2s;
            background-color: #ffffff;
        }
        .form-control-custom:focus {
            border-color: var(--brand-blue);
            box-shadow: 0 0 0 3px rgba(2, 132, 199, 0.15);
            outline: none;
        }

        /* 表格樣式 */
        .table-modern {
            width: 100%;
            border-collapse: separate;
            border-spacing: 0;
            font-size: 0.92rem;
        }
        .table-modern thead th {
            background-color: #f8fafc;
            color: #475569;
            font-weight: 700;
            padding: 12px 14px;
            border-bottom: 2px solid var(--border-color);
            white-space: nowrap;
        }
        .table-modern tbody tr {
            transition: background-color 0.15s;
        }
        .table-modern tbody tr:hover {
            background-color: #f1f5f9;
        }
        .table-modern tbody td {
            padding: 12px 14px;
            border-bottom: 1px solid var(--border-color);
            vertical-align: middle;
            color: var(--text-main);
        }

        /* 狀態標籤徽章 */
        .badge-status {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 5px;
            padding: 4px 10px;
            border-radius: 6px;
            font-size: 0.82rem;
            font-weight: 600;
            white-space: nowrap !important;
            text-align: center;
        }
        .badge-draft { background: #fef3c7; color: #92400e; border: 1px solid #fde68a; }
        .badge-submitted { background: #e0f2fe; color: #0369a1; border: 1px solid #bae6fd; }
        .badge-approved { background: #dcfce7; color: #15803d; border: 1px solid #bbf7d0; }
        .badge-mac-count {
            background: #ede9fe;
            color: #6d28d9;
            font-weight: 700;
            padding: 3px 10px;
            border-radius: 20px;
            font-size: 0.85rem;
            border: 1px solid #ddd6fe;
        }

        /* 不透光率數據醒目 */
        .opaque-val {
            font-weight: 700;
            font-family: Consolas, monospace;
        }
        .opaque-good { color: #059669; }
        .opaque-warn { color: #d97706; }
        .opaque-danger { color: #dc2626; }

        /* 行動端卡片式清單 */
        @media screen and (max-width: 991px) {
            .table-responsive-mobile table, 
            .table-responsive-mobile thead, 
            .table-responsive-mobile tbody, 
            .table-responsive-mobile th, 
            .table-responsive-mobile td, 
            .table-responsive-mobile tr {
                display: block;
            }
            .table-responsive-mobile thead {
                display: none;
            }
            .table-responsive-mobile tbody tr {
                margin-bottom: 16px;
                border: 1px solid var(--border-color);
                border-radius: 10px;
                background: #ffffff;
                padding: 12px;
                box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
            }
            .table-responsive-mobile tbody td {
                display: flex;
                justify-content: space-between;
                align-items: center;
                border-bottom: 1px dashed var(--border-color);
                padding: 8px 4px;
            }
            .table-responsive-mobile tbody td:last-child {
                border-bottom: none;
                margin-top: 8px;
                padding-top: 10px;
                justify-content: flex-end;
            }
            .table-responsive-mobile tbody td::before {
                content: attr(data-label);
                font-weight: 700;
                color: var(--text-muted);
                font-size: 0.85rem;
                margin-right: 12px;
            }
        }

        /* 抽屜/彈窗 Modal 樣式 */
        .modal-custom {
            display: none;
            position: fixed;
            top: 0; left: 0; right: 0; bottom: 0;
            background: rgba(15, 23, 42, 0.65);
            z-index: 9999;
            align-items: center;
            justify-content: center;
            padding: 16px;
            overflow-y: auto;
        }
        .modal-custom.show {
            display: flex !important;
        }
        .modal-dialog-custom {
            background: #ffffff;
            border-radius: 16px;
            width: 95vw;
            max-width: 1240px;
            max-height: 92vh;
            display: flex;
            flex-direction: column;
            box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.2);
            overflow: hidden;
            animation: modalFadeIn 0.2s ease-out;
        }
        @keyframes modalFadeIn {
            from { opacity: 0; transform: scale(0.96); }
            to { opacity: 1; transform: scale(1); }
        }
        .modal-header-custom {
            padding: 16px 20px;
            background: #f8fafc;
            border-bottom: 1px solid var(--border-color);
            display: flex;
            align-items: center;
            justify-content: space-between;
        }
        .modal-body-custom {
            padding: 20px;
            overflow-y: auto;
        }
        .modal-footer-custom {
            padding: 14px 20px;
            background: #f8fafc;
            border-top: 1px solid var(--border-color);
            display: flex;
            justify-content: flex-end;
            gap: 10px;
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

        /* 資訊清單鍵值展示格 */
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
            gap: 10px;
            background: #f8fafc;
            padding: 12px 16px;
            border-radius: 10px;
            border: 1px solid var(--border-color);
            margin-bottom: 16px;
        }
        .info-item {
            font-size: 0.88rem;
        }
        .info-item-label {
            color: var(--text-muted);
            font-weight: 600;
            margin-bottom: 2px;
        }
        .info-item-val {
            color: var(--brand-navy);
            font-weight: 700;
            word-break: break-all;
        }
    </style>
</head>
<body>
    <div id="macListApp" v-cloak>
        <!-- 頂部品牌導覽列 -->
        <header class="top-navbar">
            <div class="d-flex align-items-center">
                <a href="../MainPage.aspx" class="nav-btn mr-2" title="返回主選單">
                    <i class="fas fa-home"></i>
                    <span class="d-none d-sm-inline">回首頁</span>
                </a>
                <div class="navbar-brand-title">
                    <i class="fas fa-truck-monster text-white"></i>
                    <span>洗掃作業自主管理與車輛清單</span>
                </div>
            </div>
            <div class="d-flex align-items-center gap-2">
                <a href="NewMac.aspx?mode=new" class="btn btn-success btn-sm font-weight-bold shadow-sm">
                    <i class="fas fa-plus-circle mr-1"></i>
                    <span class="d-none d-sm-inline">新增車輛機具</span>
                </a>
            </div>
        </header>

        <!-- 模式切換頁籤列 -->
        <div class="nav-mode-bar">
            <a href="javascript:void(0)" class="nav-mode-item" :class="{ 'active': filter.Mode === '' }" v-on:click="switchMode('')">
                <i class="fas fa-list"></i> 全部調查清單
                <span class="badge badge-light ml-1">{{ counts.TotalMac || 0 }}</span>
            </a>
            <a href="javascript:void(0)" class="nav-mode-item" :class="{ 'active': filter.Mode === 'reject' }" v-on:click="switchMode('reject')">
                <i class="fas fa-clock text-warning"></i> 查核紀錄暫存 (待修正)
                <span class="badge badge-warning text-dark ml-1">{{ counts.DraftMac || 0 }}</span>
            </a>
            <a href="javascript:void(0)" class="nav-mode-item" :class="{ 'active': filter.Mode === 'search' }" v-on:click="switchMode('search')">
                <i class="fas fa-chart-pie text-success"></i> 調查成果列表
                <span class="badge badge-success ml-1">{{ counts.SearchFac || 0 }}</span>
            </a>
        </div>

        <!-- 主作業容器 -->
        <main class="main-container">
            <!-- 警示訊息條 -->
            <div v-if="alertMessage" class="alert alert-dismissible fade show" :class="'alert-' + alertType" role="alert">
                <i class="fas mr-2" :class="alertType === 'success' ? 'fa-check-circle' : 'fa-info-circle'"></i>
                {{ alertMessage }}
                <button type="button" class="close" v-on:click="alertMessage = ''" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>

            <!-- 數據指標摘要統計卡片 (Stat Grid) -->
            <div class="stat-grid">
                <div class="stat-card">
                    <div>
                        <div class="stat-label">公私場所總數</div>
                        <div class="stat-value">{{ counts.TotalFac || 0 }}</div>
                    </div>
                    <div class="stat-icon primary">
                        <i class="fas fa-building"></i>
                    </div>
                </div>
                <div class="stat-card">
                    <div>
                        <div class="stat-label">施工機具列管總台數</div>
                        <div class="stat-value">{{ counts.TotalMac || 0 }}</div>
                    </div>
                    <div class="stat-icon purple">
                        <i class="fas fa-truck-monster"></i>
                    </div>
                </div>
                <div class="stat-card">
                    <div>
                        <div class="stat-label">暫存 / 待送審核</div>
                        <div class="stat-value text-warning">{{ counts.DraftMac || 0 }}</div>
                    </div>
                    <div class="stat-icon warning">
                        <i class="fas fa-edit"></i>
                    </div>
                </div>
                <div class="stat-card">
                    <div>
                        <div class="stat-label">已送審 / 審查中</div>
                        <div class="stat-value text-success">{{ counts.SubmittedMac || 0 }}</div>
                    </div>
                    <div class="stat-icon success">
                        <i class="fas fa-check-double"></i>
                    </div>
                </div>
            </div>

            <!-- 多功能篩選卡片 -->
            <div class="card-modern">
                <div class="card-modern-header">
                    <div class="card-modern-title">
                        <i class="fas fa-filter text-primary"></i>
                        <span>條件篩選與空間查詢</span>
                    </div>
                    <div class="d-flex align-items-center gap-2">
                        <button type="button" class="btn btn-sm btn-outline-secondary" v-on:click="isFilterCollapsed = !isFilterCollapsed">
                            <i class="fas" :class="isFilterCollapsed ? 'fa-chevron-down' : 'fa-chevron-up'"></i>
                            {{ isFilterCollapsed ? '展開條件' : '收合條件' }}
                        </button>
                        <button type="button" class="btn btn-sm btn-outline-info" v-on:click="getLocationAndSearch">
                            <i class="fas fa-crosshairs text-info"></i>
                            <span class="d-none d-sm-inline">附近場所 GPS 定位</span>
                        </button>
                    </div>
                </div>
                <div class="card-modern-body" v-show="!isFilterCollapsed">
                    <div class="filter-row">
                        <div class="form-group-custom">
                            <label>公私場所名稱</label>
                            <input type="text" class="form-control-custom" v-model.trim="filter.FacName" placeholder="例如：新北市政府..." v-on:keyup.enter="handleSearch" />
                        </div>
                        <div class="form-group-custom">
                            <label>管制編號</label>
                            <input type="text" class="form-control-custom" v-model.trim="filter.CNo" placeholder="例如：F..." v-on:keyup.enter="handleSearch" />
                        </div>
                        <div class="form-group-custom">
                            <label>統一編號</label>
                            <input type="text" class="form-control-custom" v-model.trim="filter.ScId" placeholder="8碼統編" v-on:keyup.enter="handleSearch" />
                        </div>
                        <div class="form-group-custom">
                            <label>行政區</label>
                            <select class="form-control-custom" v-model="filter.Town" v-on:change="handleSearch">
                                <option value="">全部行政區</option>
                                <option v-for="t in towns" :key="t.TownNo" :value="t.TownName">{{ t.TownName }}</option>
                            </select>
                        </div>
                        <div class="form-group-custom">
                            <label>機具種類</label>
                            <input type="text" class="form-control-custom" v-model.trim="filter.MacType" list="macTypeList" placeholder="例如：挖土機、發電機" v-on:keyup.enter="handleSearch" />
                            <datalist id="macTypeList">
                                <option v-for="item in macTypes" :key="item" :value="item"></option>
                            </datalist>
                        </div>
                        <div class="form-group-custom">
                            <label>機具廠牌</label>
                            <input type="text" class="form-control-custom" v-model.trim="filter.Brand" placeholder="例如：KOMATSU、CAT" v-on:keyup.enter="handleSearch" />
                        </div>
                        <div class="form-group-custom">
                            <label>型號</label>
                            <input type="text" class="form-control-custom" v-model.trim="filter.Model" placeholder="例如：PC200" v-on:keyup.enter="handleSearch" />
                        </div>
                        <div class="form-group-custom">
                            <label>機身號碼</label>
                            <input type="text" class="form-control-custom" v-model.trim="filter.Pin" placeholder="機身編號 PIN" v-on:keyup.enter="handleSearch" />
                        </div>
                        <div class="form-group-custom">
                            <label>引擎編號</label>
                            <input type="text" class="form-control-custom" v-model.trim="filter.EngineNo" placeholder="Engine No." v-on:keyup.enter="handleSearch" />
                        </div>
                        <div class="form-group-custom">
                            <label>巡查日期 (起)</label>
                            <input type="date" class="form-control-custom" v-model="filter.DateS" />
                        </div>
                        <div class="form-group-custom">
                            <label>巡查日期 (訖)</label>
                            <input type="date" class="form-control-custom" v-model="filter.DateE" />
                        </div>
                        <div class="form-group-custom">
                            <label>平均不透光率(%) 區間</label>
                            <div class="d-flex align-items-center gap-1">
                                <input type="number" step="0.1" class="form-control-custom text-center" v-model="filter.AvgOpaqueS" placeholder="最小值" />
                                <span class="text-muted">~</span>
                                <input type="number" step="0.1" class="form-control-custom text-center" v-model="filter.AvgOpaqueE" placeholder="最大值" />
                            </div>
                        </div>
                    </div>

                    <div class="d-flex justify-content-end align-items-center flex-wrap gap-2 mt-3 pt-3 border-top">
                        <div class="d-flex gap-2">
                            <button type="button" class="btn btn-secondary px-3" v-on:click="resetFilter">
                                <i class="fas fa-undo mr-1"></i> 重設
                            </button>
                            <button type="button" class="btn btn-outline-success px-3" v-on:click="exportCsv">
                                <i class="fas fa-file-excel mr-1"></i> 匯出 CSV
                            </button>
                            <button type="button" class="btn btn-primary px-4 font-weight-bold" v-on:click="handleSearch">
                                <i class="fas fa-search mr-1"></i> 搜尋
                            </button>
                        </div>
                    </div>
                </div>
            </div>

            <!-- 資料列表區塊 -->
            <div class="card-modern">
                <div class="card-modern-header">
                    <div class="d-flex align-items-center gap-3">
                        <div class="card-modern-title">
                            <i class="fas fa-table text-primary"></i>
                            <span>查詢結果清單</span>
                        </div>
                        <!-- 雙重視角切換 -->
                        <div class="view-switcher">
                            <button type="button" class="view-btn" :class="{ 'active': currentView === 'fac' }" v-on:click="switchView('fac')">
                                <i class="fas fa-building"></i> 場所總覽視角
                            </button>
                            <button type="button" class="view-btn" :class="{ 'active': currentView === 'mac' }" v-on:click="switchView('mac')">
                                <i class="fas fa-truck-monster"></i> 機具巡查清單視角
                            </button>
                        </div>
                    </div>
                    <div class="text-muted font-weight-bold" style="font-size: 0.9rem;">
                        共找到 <span class="text-primary font-weight-bold">{{ totalRows }}</span> 筆資料
                    </div>
                </div>

                <div class="card-modern-body p-0">
                    <!-- Loading 遮罩 -->
                    <div v-if="isLoading" class="text-center py-5">
                        <div class="spinner-border text-primary" role="status"></div>
                        <div class="text-muted mt-2 font-weight-bold">資料載入中，請稍候...</div>
                    </div>

                    <!-- 視角 1: 場所總覽視角 (FAC View) -->
                    <div v-else-if="currentView === 'fac'" class="table-responsive-mobile">
                        <table class="table-modern">
                            <thead>
                                <tr>
                                    <th style="width: 140px;">管制編號</th>
                                    <th>場所名稱</th>
                                    <th style="width: 140px;">行政區 / 行業別</th>
                                    <th style="width: 130px;">統一編號</th>
                                    <th style="width: 120px;">列管狀態</th>
                                    <th style="width: 110px; text-align: center;">機具台數</th>
                                    <th style="width: 160px; text-align: right;">操作管理</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr v-for="item in items" :key="item.FAC_ID">
                                    <td data-label="管制編號">
                                        <span class="font-weight-bold text-dark font-monospace">{{ item.C_NO }}</span>
                                    </td>
                                    <td data-label="場所名稱">
                                        <div class="font-weight-bold text-dark">{{ item.FAC_NAME }}</div>
                                        <small class="text-muted d-block" v-if="item.ADDR !== '-'"><i class="fas fa-map-marker-alt text-danger mr-1"></i>{{ item.ADDR }}</small>
                                    </td>
                                    <td data-label="行政區/行業別">
                                        <div><span class="badge badge-light border">{{ item.TOWN_NA }}</span></div>
                                        <small class="text-muted">{{ item.Industrial }}</small>
                                    </td>
                                    <td data-label="統一編號">
                                        <span class="font-monospace text-muted">{{ item.S_C_ID }}</span>
                                    </td>
                                    <td data-label="列管狀態">
                                        <span class="badge badge-secondary">{{ item.FAC_Type1 }}</span>
                                    </td>
                                    <td data-label="機具台數" style="text-align: center;">
                                        <span class="badge-mac-count">
                                            <i class="fas fa-truck-monster mr-1"></i>{{ item.MacCount }} 台
                                        </span>
                                    </td>
                                    <td data-label="操作" style="text-align: right;">
                                        <div class="btn-group btn-group-sm">
                                            <button type="button" class="btn btn-outline-primary" v-on:click="openFacDetail(item.FAC_ID)" title="檢視詳細資訊與機具">
                                                <i class="fas fa-list-ul mr-1"></i> 檢視機具
                                            </button>
                                            <a v-if="filter.Mode !== 'search'" :href="'NewMac.aspx?id=' + item.FAC_ID + '&mode=new'" class="btn btn-outline-success" title="為此場所新增機具">
                                                <i class="fas fa-plus"></i>
                                            </a>
                                        </div>
                                    </td>
                                </tr>
                                <tr v-if="items.length === 0">
                                    <td colspan="7" class="text-center py-5 text-muted">
                                        <i class="fas fa-inbox fa-3x mb-3 d-block text-secondary"></i>
                                        查無符合條件之公私場所資料
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>

                    <!-- 視角 2: 機具巡查清單視角 (Mac View) -->
                    <div v-else class="table-responsive-mobile">
                        <table class="table-modern">
                            <thead>
                                <tr>
                                    <th style="width: 110px;">巡查時間</th>
                                    <th>所屬場所 / 管制編號</th>
                                    <th style="width: 120px;">機具種類</th>
                                    <th style="width: 140px;">廠牌 / 型號</th>
                                    <th style="width: 90px; text-align: center;">出廠年份</th>
                                    <th style="width: 150px;">機身 / 引擎編號</th>
                                    <th style="width: 120px; text-align: center;">平均不透光率</th>
                                    <th style="width: 120px; text-align: center;">審核狀態</th>
                                    <th style="width: 160px; text-align: right;">操作管理</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr v-for="item in items" :key="item.FAC_ID + '_' + item.mac_ID">
                                    <td data-label="巡查時間">
                                        <span class="font-weight-bold text-dark">{{ item.Check_date }}</span>
                                    </td>
                                    <td data-label="所屬場所">
                                        <div class="font-weight-bold text-dark">{{ item.FAC_NAME }}</div>
                                        <small class="text-muted font-monospace">[{{ item.C_NO }}] · {{ item.TOWN_NA }}</small>
                                    </td>
                                    <td data-label="機具種類">
                                        <span class="badge badge-info">{{ item.mac_Type }}</span>
                                    </td>
                                    <td data-label="廠牌/型號">
                                        <div class="font-weight-bold">{{ item.Brand }}</div>
                                        <small class="text-muted">{{ item.model }}</small>
                                    </td>
                                    <td data-label="出廠年份" style="text-align: center;">
                                        <span class="text-secondary font-weight-bold">{{ item.OUT_YEAR }}</span>
                                    </td>
                                    <td data-label="機身/引擎編號">
                                        <div style="font-size: 0.85rem;"><span class="text-muted">機身:</span> {{ item.PIN }}</div>
                                        <div style="font-size: 0.85rem;"><span class="text-muted">引擎:</span> {{ item.Engine_NO }}</div>
                                    </td>
                                    <td data-label="平均不透光率" style="text-align: center;">
                                        <span class="opaque-val" :class="getOpaqueClass(item.opaque_Run_AVG)">
                                            {{ item.opaque_Run_AVG }} %
                                        </span>
                                    </td>
                                    <td data-label="審核狀態" style="text-align: center;">
                                        <span class="badge-status" :class="getStatusBadgeClass(item.Mac_State)">
                                            {{ item.Mac_State_Text }}
                                        </span>
                                    </td>
                                    <td data-label="操作" style="text-align: right;">
                                        <div class="btn-group btn-group-sm">
                                            <!-- 修改按鈕 -->
                                            <a v-if="canEdit(item.Mac_State)" :href="'NewMac.aspx?mode=edit&id=' + item.FAC_ID + '&id2=' + item.mac_ID" class="btn btn-outline-primary" title="修改機具申報">
                                                <i class="fas fa-edit"></i>
                                            </a>
                                            <!-- 送出審核按鈕 -->
                                            <button v-if="canEdit(item.Mac_State)" type="button" class="btn btn-outline-success" v-on:click="submitCheck(item.FAC_ID, item.mac_ID)" title="送出審核">
                                                <i class="fas fa-paper-plane"></i>
                                            </button>
                                            <!-- 刪除按鈕 -->
                                            <button v-if="canEdit(item.Mac_State)" type="button" class="btn btn-outline-danger" v-on:click="deleteMac(item.FAC_ID, item.mac_ID)" title="刪除機具">
                                                <i class="fas fa-trash-alt"></i>
                                            </button>
                                            <!-- 詳細檢視按鈕 -->
                                            <a :href="'NewMac.aspx?mode=view&id=' + item.FAC_ID + '&id2=' + item.mac_ID" class="btn btn-outline-secondary" title="檢視詳細資料">
                                                <i class="fas fa-eye"></i>
                                            </a>
                                        </div>
                                    </td>
                                </tr>
                                <tr v-if="items.length === 0">
                                    <td colspan="9" class="text-center py-5 text-muted">
                                        <i class="fas fa-inbox fa-3x mb-3 d-block text-secondary"></i>
                                        查無符合條件之施工機具巡查資料
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>

                    <!-- 自適應底部分頁導覽列 (Responsive Pagination Footer) -->
                    <div v-if="!isLoading && totalRows > 0" class="pagination-footer">
                        <div class="pagination-footer-info">
                            顯示第 <strong class="text-dark">{{ (filter.PageIndex - 1) * filter.PageSize + 1 }}</strong> 至 <strong class="text-dark">{{ Math.min(filter.PageIndex * filter.PageSize, totalRows) }}</strong> 筆，共 <strong class="text-dark">{{ totalRows }}</strong> 筆
                        </div>
                        <div class="pagination-action-group">
                            <button type="button" class="btn-page-ctrl btn-edge" :disabled="filter.PageIndex <= 1" v-on:click="goToPage(1)" title="第一頁">
                                <i class="fas fa-angle-double-left"></i>
                                <span class="d-none d-md-inline ml-1">首頁</span>
                            </button>
                            <button type="button" class="btn-page-ctrl btn-step" :disabled="filter.PageIndex <= 1" v-on:click="goToPage(filter.PageIndex - 1)" title="上一頁">
                                <i class="fas fa-chevron-left mr-1"></i>
                                <span>上一頁</span>
                            </button>
                            <div class="page-indicator-pill" title="目前頁次 / 總頁數">
                                <span>{{ filter.PageIndex }}</span>
                                <span class="mx-1 text-muted" style="opacity: 0.5; font-weight: normal;">/</span>
                                <span>{{ totalPages }}</span>
                            </div>
                            <button type="button" class="btn-page-ctrl btn-step" :disabled="filter.PageIndex >= totalPages" v-on:click="goToPage(filter.PageIndex + 1)" title="下一頁">
                                <span>下一頁</span>
                                <i class="fas fa-chevron-right ml-1"></i>
                            </button>
                            <button type="button" class="btn-page-ctrl btn-edge" :disabled="filter.PageIndex >= totalPages" v-on:click="goToPage(totalPages)" title="最後一頁">
                                <span class="d-none d-md-inline ml-1">末頁</span>
                                <i class="fas fa-angle-double-right"></i>
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </main>

        <!-- 場所詳細資料與所屬機具抽屜/彈窗 (Modal) -->
        <div class="modal-custom" :class="{ 'show': showDetailModal }" v-on:click.self="showDetailModal = false">
            <div class="modal-dialog-custom">
                <div class="modal-header-custom">
                    <div class="d-flex align-items-center gap-2">
                        <i class="fas fa-building text-primary" style="font-size: 1.2rem;"></i>
                        <h5 class="mb-0 font-weight-bold">{{ selectedFac ? selectedFac.FAC_NAME : (isModalLoading ? '載入場所資訊中...' : '場所資料') }}</h5>
                        <span v-if="selectedFac && selectedFac.C_NO && selectedFac.C_NO !== '-'" class="badge badge-secondary ml-2 font-monospace">[{{ selectedFac.C_NO }}]</span>
                    </div>
                    <button type="button" class="close" v-on:click="showDetailModal = false">
                        <span aria-hidden="true">&times;</span>
                    </button>
                </div>
                <div class="modal-body-custom">
                    <div v-if="isModalLoading" class="text-center py-5">
                        <div class="spinner-border text-primary" role="status"></div>
                        <div class="text-muted mt-2 font-weight-bold">正在讀取場所與機具明細中...</div>
                    </div>
                    <template v-else>
                    <!-- 基本資料網格 -->
                    <div v-if="selectedFac" class="info-grid">
                        <div class="info-item">
                            <div class="info-item-label">行政區</div>
                            <div class="info-item-val">{{ selectedFac.TOWN_NA }}</div>
                        </div>
                        <div class="info-item">
                            <div class="info-item-label">行業別</div>
                            <div class="info-item-val">{{ selectedFac.Industrial }}</div>
                        </div>
                        <div class="info-item">
                            <div class="info-item-label">統一編號</div>
                            <div class="info-item-val">{{ selectedFac.S_C_ID }}</div>
                        </div>
                        <div class="info-item">
                            <div class="info-item-label">工廠登記證</div>
                            <div class="info-item-val">{{ selectedFac.Lic_NO }}</div>
                        </div>
                        <div class="info-item">
                            <div class="info-item-label">負責人</div>
                            <div class="info-item-val">{{ selectedFac.BOSS_NAME }}</div>
                        </div>
                        <div class="info-item">
                            <div class="info-item-label">聯絡人</div>
                            <div class="info-item-val">{{ selectedFac.Content_Name }}</div>
                        </div>
                        <div class="info-item">
                            <div class="info-item-label">連絡電話</div>
                            <div class="info-item-val">{{ selectedFac.TEL }}</div>
                        </div>
                        <div class="info-item">
                            <div class="info-item-label">傳真號碼</div>
                            <div class="info-item-val">{{ selectedFac.FAX }}</div>
                        </div>
                        <div class="info-item" style="grid-column: 1 / -1;">
                            <div class="info-item-label">場所地址</div>
                            <div class="info-item-val">{{ selectedFac.ADDR }}</div>
                        </div>
                    </div>

                    <!-- 所屬機具清單 -->
                    <div class="d-flex align-items-center justify-content-between mb-3">
                        <h6 class="font-weight-bold mb-0 text-dark">
                            <i class="fas fa-truck-monster text-primary mr-2"></i>所屬施工機具列表 (共 {{ facMachines.length }} 台)
                        </h6>
                        <a v-if="selectedFac && filter.Mode !== 'search'" :href="'NewMac.aspx?id=' + selectedFac.FAC_ID + '&mode=new'" class="btn btn-sm btn-success">
                            <i class="fas fa-plus mr-1"></i> 新增機具
                        </a>
                    </div>

                    <div class="table-responsive" style="overflow-x: auto;">
                        <table class="table-modern" style="table-layout: auto;">
                            <thead>
                                <tr>
                                    <th style="width: 105px; white-space: nowrap;">巡查時間</th>
                                    <th style="min-width: 200px;">機具種類 / 廠牌型號</th>
                                    <th style="width: 160px; white-space: nowrap;">機身 / 引擎編號</th>
                                    <th style="width: 85px; text-align: center; white-space: nowrap;">出廠年份</th>
                                    <th style="width: 110px; text-align: center; white-space: nowrap;">平均不透光率</th>
                                    <th style="width: 115px; text-align: center; white-space: nowrap;">審核狀態</th>
                                    <th style="width: 145px; text-align: right; white-space: nowrap;">操作管理</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr v-for="m in facMachines" :key="m.mac_ID">
                                    <td style="white-space: nowrap;">
                                        <span class="font-weight-bold text-dark">{{ m.Check_date }}</span>
                                    </td>
                                    <td>
                                        <div class="d-flex align-items-center flex-wrap gap-1">
                                            <span class="badge badge-info mr-1">{{ m.mac_Type }}</span>
                                            <strong class="text-dark">{{ m.Brand }}</strong>
                                            <span class="text-muted ml-1" v-if="m.model">{{ m.model }}</span>
                                        </div>
                                    </td>
                                    <td style="white-space: nowrap;">
                                        <div style="font-size: 0.83rem; line-height: 1.35;">
                                            <span class="text-muted">機身:</span> <span class="font-monospace text-dark font-weight-bold">{{ m.PIN || '-' }}</span>
                                        </div>
                                        <div style="font-size: 0.83rem; line-height: 1.35;">
                                            <span class="text-muted">引擎:</span> <span class="font-monospace text-dark">{{ m.Engine_NO || '-' }}</span>
                                        </div>
                                    </td>
                                    <td style="text-align: center; white-space: nowrap;">
                                        <span class="text-secondary font-weight-bold">{{ m.OUT_YEAR || '-' }}</span>
                                    </td>
                                    <td style="text-align: center; white-space: nowrap;">
                                        <span class="opaque-val" :class="getOpaqueClass(m.opaque_Run_AVG)">{{ m.opaque_Run_AVG }} %</span>
                                    </td>
                                    <td style="text-align: center; white-space: nowrap;">
                                        <span class="badge-status" :class="getStatusBadgeClass(m.Mac_State)">{{ m.Mac_State_Text }}</span>
                                    </td>
                                    <td style="text-align: right; white-space: nowrap;">
                                        <div class="btn-group btn-group-sm">
                                            <a v-if="canEdit(m.Mac_State)" :href="'NewMac.aspx?mode=edit&id=' + selectedFac.FAC_ID + '&id2=' + m.mac_ID" class="btn btn-outline-primary" title="修改機具申報">
                                                <i class="fas fa-edit"></i>
                                            </a>
                                            <button v-if="canEdit(m.Mac_State)" type="button" class="btn btn-outline-success" v-on:click="submitCheckInModal(selectedFac.FAC_ID, m.mac_ID)" title="送出審核">
                                                <i class="fas fa-paper-plane"></i>
                                            </button>
                                            <button v-if="canEdit(m.Mac_State)" type="button" class="btn btn-outline-danger" v-on:click="deleteMacInModal(selectedFac.FAC_ID, m.mac_ID)" title="刪除機具">
                                                <i class="fas fa-trash-alt"></i>
                                            </button>
                                            <a :href="'NewMac.aspx?mode=view&id=' + selectedFac.FAC_ID + '&id2=' + m.mac_ID" class="btn btn-outline-secondary" title="檢視詳細資料">
                                                <i class="fas fa-eye"></i>
                                            </a>
                                        </div>
                                    </td>
                                </tr>
                                <tr v-if="facMachines.length === 0">
                                    <td colspan="7" class="text-center py-4 text-muted">
                                        此場所目前尚無施工機具申報資料
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                    </template>
                </div>
                <div class="modal-footer-custom">
                    <button type="button" class="btn btn-secondary" v-on:click="showDetailModal = false">關閉</button>
                </div>
            </div>
        </div>
    </div>

    <!-- 本地核心腳本 (Vue 3, Axios) -->
    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>

    <script>
        const { createApp } = Vue;

        createApp({
            data() {
                return {
                    isLoading: false,
                    isModalLoading: false,
                    isFilterCollapsed: false,
                    alertMessage: '',
                    alertType: 'info',
                    currentView: 'fac', // 'fac' (場所總覽) 或 'mac' (機具清單)
                    currentUser: '',
                    towns: [],
                    macTypes: [],
                    counts: {
                        TotalFac: 0,
                        TotalMac: 0,
                        DraftMac: 0,
                        SubmittedMac: 0,
                        SearchFac: 0
                    },
                    filter: {
                        Mode: '',
                        FacName: '',
                        CNo: '',
                        ScId: '',
                        Town: '',
                        MacType: '',
                        Brand: '',
                        Model: '',
                        Pin: '',
                        EngineNo: '',
                        DateS: '',
                        DateE: '',
                        OutYearS: '',
                        OutYearE: '',
                        AvgOpaqueS: '',
                        AvgOpaqueE: '',
                        PageIndex: 1,
                        PageSize: 20
                    },
                    items: [],
                    totalRows: 0,
                    totalPages: 1,

                    // 彈窗
                    showDetailModal: false,
                    selectedFac: null,
                    facMachines: []
                };
            },
            computed: {
                visiblePages() {
                    const current = this.filter.PageIndex;
                    const max = this.totalPages;
                    const pages = [];
                    const start = Math.max(1, current - 2);
                    const end = Math.min(max, current + 2);
                    for (let i = start; i <= end; i++) {
                        pages.push(i);
                    }
                    return pages;
                }
            },
            mounted() {
                // 從 URL 取得 mode 參數
                const urlParams = new URLSearchParams(window.location.search);
                const modeParam = urlParams.get('mode');
                if (modeParam) {
                    this.filter.Mode = modeParam.toLowerCase();
                    if (this.filter.Mode === 'reject') {
                        this.currentView = 'mac'; // 暫存待修正直接切換至機具清單視角
                    }
                }
                this.initPage();
            },
            methods: {
                initPage() {
                    this.isLoading = true;
                    axios.get('macList.aspx?action=getinit&mode=' + encodeURIComponent(this.filter.Mode))
                        .then(res => {
                            if (res.data && res.data.Success) {
                                const d = res.data.Data;
                                this.currentUser = d.CurrentUser;
                                this.towns = d.Towns || [];
                                this.macTypes = d.MacTypes || [];
                                this.counts = d.Counts || this.counts;
                            }
                            this.fetchList();
                        })
                        .catch(err => {
                            this.showAlert('初始化資料失敗：' + err.message, 'danger');
                            this.fetchList();
                        });
                },

                fetchList() {
                    this.isLoading = true;
                    const action = this.currentView === 'fac' ? 'getfaclist' : 'getmaclist';
                    const payload = {
                        ...this.filter,
                        ViewType: this.currentView
                    };

                    axios.post('macList.aspx?action=' + action, payload)
                        .then(res => {
                            this.isLoading = false;
                            if (res.data && res.data.Success) {
                                const d = res.data.Data;
                                this.items = d.Items || [];
                                this.totalRows = d.TotalRows || 0;
                                this.totalPages = d.TotalPages || 1;
                                this.filter.PageIndex = d.PageIndex || 1;
                            } else {
                                this.showAlert(res.data ? res.data.Message : '載入清單失敗', 'danger');
                            }
                        })
                        .catch(err => {
                            this.isLoading = false;
                            this.showAlert('連線錯誤：' + err.message, 'danger');
                        });
                },

                switchMode(mode) {
                    this.filter.Mode = mode;
                    this.filter.PageIndex = 1;
                    if (mode === 'reject') {
                        this.currentView = 'mac';
                    }
                    this.fetchList();
                    this.refreshCounts();
                },

                switchView(view) {
                    this.currentView = view;
                    this.filter.PageIndex = 1;
                    this.fetchList();
                },

                handleSearch() {
                    this.filter.PageIndex = 1;
                    this.fetchList();
                },

                resetFilter() {
                    const currentMode = this.filter.Mode;
                    this.filter = {
                        Mode: currentMode,
                        FacName: '',
                        CNo: '',
                        ScId: '',
                        Town: '',
                        MacType: '',
                        Brand: '',
                        Model: '',
                        Pin: '',
                        EngineNo: '',
                        DateS: '',
                        DateE: '',
                        OutYearS: '',
                        OutYearE: '',
                        AvgOpaqueS: '',
                        AvgOpaqueE: '',
                        PageIndex: 1,
                        PageSize: 20
                    };
                    this.fetchList();
                },

                goToPage(p) {
                    if (p < 1 || p > this.totalPages || p === this.filter.PageIndex) return;
                    this.filter.PageIndex = p;
                    this.fetchList();
                    window.scrollTo({ top: 300, behavior: 'smooth' });
                },

                handlePageSizeChange() {
                    this.filter.PageIndex = 1;
                    this.fetchList();
                },

                refreshData() {
                    this.refreshCounts();
                    this.fetchList();
                },

                refreshCounts() {
                    axios.get('macList.aspx?action=getcounts')
                        .then(res => {
                            if (res.data && res.data.Success) {
                                this.counts = res.data.Data || this.counts;
                            }
                        })
                        .catch(() => {});
                },

                getLocationAndSearch() {
                    if (!("geolocation" in navigator)) {
                        alert("您的裝置或瀏覽器不支援 GPS 定位功能。");
                        return;
                    }
                    this.showAlert("正在取得現場 GPS 座標中...", "info");
                    navigator.geolocation.getCurrentPosition(
                        pos => {
                            this.showAlert(`GPS 定位成功 (緯度: ${pos.coords.latitude.toFixed(4)}, 經度: ${pos.coords.longitude.toFixed(4)})，正在比對附近場所...`, "success");
                            this.handleSearch();
                        },
                        err => {
                            this.showAlert("GPS 定位失敗：" + err.message, "danger");
                        },
                        { enableHighAccuracy: true, timeout: 10000 }
                    );
                },

                openFacDetail(facId) {
                    const self = this;
                    self.selectedFac = null;
                    self.facMachines = [];
                    self.isModalLoading = true;
                    self.showDetailModal = true;

                    axios.get('macList.aspx?action=getfacdetail&facId=' + encodeURIComponent(facId != null ? facId : ''))
                        .then(res => {
                            self.isModalLoading = false;
                            if (res.data && res.data.Success) {
                                self.selectedFac = res.data.Data.Fac;
                                self.facMachines = res.data.Data.Machines || [];
                            } else {
                                alert(res.data ? res.data.Message : '讀取場所資訊失敗');
                                self.showDetailModal = false;
                            }
                        })
                        .catch(err => {
                            self.isModalLoading = false;
                            alert('連線異常：' + (err.response && err.response.data && err.response.data.Message ? err.response.data.Message : err.message));
                            self.showDetailModal = false;
                        });
                },

                submitCheck(facId, macId) {
                    if (!confirm(`確定要將此施工機具送出審核嗎？ (序號: ${macId})`)) return;
                    axios.get(`macList.aspx?action=submitcheck&facId=${encodeURIComponent(facId)}&macId=${encodeURIComponent(macId)}`)
                        .then(res => {
                            if (res.data && res.data.Success) {
                                alert(res.data.Message || '已成功送出審核！');
                                this.refreshData();
                            } else {
                                alert(res.data ? res.data.Message : '送審失敗');
                            }
                        })
                        .catch(err => {
                            alert('連線異常：' + err.message);
                        });
                },

                submitCheckInModal(facId, macId) {
                    if (!confirm(`確定要將此施工機具送出審核嗎？ (序號: ${macId})`)) return;
                    axios.get(`macList.aspx?action=submitcheck&facId=${encodeURIComponent(facId)}&macId=${encodeURIComponent(macId)}`)
                        .then(res => {
                            if (res.data && res.data.Success) {
                                alert(res.data.Message || '已成功送出審核！');
                                this.openFacDetail(facId);
                                this.refreshCounts();
                            } else {
                                alert(res.data ? res.data.Message : '送審失敗');
                            }
                        })
                        .catch(err => {
                            alert('連線異常：' + err.message);
                        });
                },

                deleteMac(facId, macId) {
                    if (!confirm(`確定要刪除這筆機具申報資料嗎？刪除後無法復原！ (序號: ${macId})`)) return;
                    axios.get(`macList.aspx?action=deletemac&facId=${encodeURIComponent(facId)}&macId=${encodeURIComponent(macId)}`)
                        .then(res => {
                            if (res.data && res.data.Success) {
                                alert(res.data.Message || '已成功刪除機具！');
                                this.refreshData();
                            } else {
                                alert(res.data ? res.data.Message : '刪除失敗');
                            }
                        })
                        .catch(err => {
                            alert('連線異常：' + err.message);
                        });
                },

                deleteMacInModal(facId, macId) {
                    if (!confirm(`確定要刪除這筆機具申報資料嗎？刪除後無法復原！ (序號: ${macId})`)) return;
                    axios.get(`macList.aspx?action=deletemac&facId=${encodeURIComponent(facId)}&macId=${encodeURIComponent(macId)}`)
                        .then(res => {
                            if (res.data && res.data.Success) {
                                alert(res.data.Message || '已成功刪除機具！');
                                this.openFacDetail(facId);
                                this.refreshCounts();
                            } else {
                                alert(res.data ? res.data.Message : '刪除失敗');
                            }
                        })
                        .catch(err => {
                            alert('連線異常：' + err.message);
                        });
                },

                exportCsv() {
                    const params = new URLSearchParams();
                    params.append('action', 'exportcsv');
                    for (const key in this.filter) {
                        if (this.filter[key] !== '' && this.filter[key] !== null) {
                            params.append(key, this.filter[key]);
                        }
                    }
                    window.location.href = 'macList.aspx?' + params.toString();
                },

                canEdit(state) {
                    if (this.filter.Mode === 'search') return false;
                    return !state || state === 'A00a' || state === 'A00b';
                },

                getStatusBadgeClass(state) {
                    if (!state || state === 'A00a' || state === 'A00b') return 'badge-draft';
                    if (state === 'A00') return 'badge-submitted';
                    return 'badge-approved';
                },

                getOpaqueClass(val) {
                    const num = parseFloat(val);
                    if (isNaN(num)) return '';
                    if (num <= 20) return 'opaque-good';
                    if (num <= 40) return 'opaque-warn';
                    return 'opaque-danger';
                },

                showAlert(msg, type) {
                    this.alertMessage = msg;
                    this.alertType = type || 'info';
                    window.scrollTo({ top: 0, behavior: 'smooth' });
                }
            }
        }).mount('#macListApp');
    </script>
</body>
</html>
