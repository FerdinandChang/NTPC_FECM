<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="managerList_Bare.aspx.cs" Inherits="NTPC_FEC.Manager.managerList_Bare" %>

<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定溢散源管理審查平台 - 裸露地案件審查作業</title>

    <!-- 專屬 Favicon -->
    <link rel="shortcut icon" href="../favicon.ico" type="image/x-icon" />

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

        /* 頂部導覽列 */
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
            font-size: 1.12rem;
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
            transition: all 0.2s;
            text-decoration: none;
        }

        .nav-btn:hover {
            background-color: rgba(255, 255, 255, 0.32);
            color: #ffffff;
            text-decoration: none;
        }

        /* 模式切換分頁列 */
        .nav-mode-bar {
            background: #ffffff;
            border-bottom: 1px solid var(--border-color);
            padding: 0 20px;
            display: flex;
            gap: 6px;
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
            padding: 13px 18px;
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
            padding: 2px 7px;
            border-radius: 12px;
            font-weight: 700;
        }

        /* 統計指標卡片 */
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
            gap: 12px;
            margin-bottom: 16px;
        }

        .stat-card {
            background: #ffffff;
            border-radius: 10px;
            border: 1px solid var(--border-color);
            padding: 14px 16px;
            display: flex;
            align-items: center;
            gap: 14px;
            box-shadow: 0 1px 3px rgba(15, 23, 42, 0.03);
            transition: transform 0.2s, box-shadow 0.2s;
        }

        .stat-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 10px rgba(15, 23, 42, 0.06);
        }

        .stat-icon-wrapper {
            width: 44px;
            height: 44px;
            border-radius: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.25rem;
            flex-shrink: 0;
        }

        .stat-val {
            font-size: 1.45rem;
            font-weight: 700;
            line-height: 1.2;
            color: var(--brand-navy);
        }

        .stat-lbl {
            font-size: 12px;
            color: var(--text-muted);
            margin-top: 2px;
        }

        /* 現代卡片 */
        .card-modern {
            background: var(--surface);
            border-radius: 12px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05), 0 4px 12px rgba(15, 23, 42, 0.04);
            margin-bottom: 16px;
            border: 1px solid var(--border-color);
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

        .card-modern-body {
            padding: 16px;
        }

        /* 批次操作提示列 */
        .batch-bar {
            background: linear-gradient(135deg, #eff6ff 0%, #dbeafe 100%);
            border: 1px solid #bfdbfe;
            border-radius: 10px;
            padding: 12px 16px;
            margin-bottom: 16px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-wrap: wrap;
            gap: 10px;
        }

        /* 表格樣式 */
        .modern-table {
            width: 100%;
            border-collapse: separate;
            border-spacing: 0;
        }

        .modern-table th {
            background: #f8fafc;
            color: #475569;
            font-weight: 700;
            font-size: 13px;
            padding: 12px 14px;
            border-bottom: 2px solid var(--border-color);
            white-space: nowrap;
        }

        .modern-table td {
            padding: 12px 14px;
            border-bottom: 1px solid #f1f5f9;
            font-size: 13px;
            vertical-align: middle;
            color: var(--text-main);
        }

        .modern-table tbody tr {
            transition: background-color 0.15s ease;
        }

        .modern-table tbody tr:hover {
            background-color: #f8fafc;
        }

        /* 狀態徽章 */
        .badge-status-inv1 {
            background-color: #ecfdf5;
            color: #047857;
            border: 1px solid #a7f3d0;
            font-weight: 700;
            padding: 4px 8px;
            border-radius: 6px;
            display: inline-flex;
            align-items: center;
            gap: 4px;
        }

        .badge-status-inv2 {
            background-color: #eff6ff;
            color: #0369a1;
            border: 1px solid #bfdbfe;
            font-weight: 700;
            padding: 4px 8px;
            border-radius: 6px;
            display: inline-flex;
            align-items: center;
            gap: 4px;
        }

        .badge-status-inv3 {
            background-color: #fef3c7;
            color: #b45309;
            border: 1px solid #fde68a;
            font-weight: 700;
            padding: 4px 8px;
            border-radius: 6px;
            display: inline-flex;
            align-items: center;
            gap: 4px;
        }

        .badge-status-other {
            background-color: #f1f5f9;
            color: #475569;
            border: 1px solid #cbd5e1;
            font-weight: 600;
            padding: 4px 8px;
            border-radius: 6px;
            display: inline-flex;
            align-items: center;
            gap: 4px;
        }

        /* 側邊抽屜式面板 (Drawer / Offcanvas) */
        .drawer-overlay {
            position: fixed;
            top: 0; left: 0; right: 0; bottom: 0;
            background: rgba(15, 23, 42, 0.45);
            z-index: 1050;
            backdrop-filter: blur(2px);
            opacity: 0;
            visibility: hidden;
            transition: all 0.25s ease;
        }

        .drawer-overlay.active {
            opacity: 1;
            visibility: visible;
        }

        .drawer-panel {
            position: fixed;
            top: 0; right: 0; bottom: 0;
            width: 780px;
            max-width: 95vw;
            background: #ffffff;
            z-index: 1060;
            box-shadow: -4px 0 24px rgba(0, 0, 0, 0.15);
            transform: translateX(100%);
            transition: transform 0.3s cubic-bezier(0.16, 1, 0.3, 1);
            display: flex;
            flex-direction: column;
        }

        .drawer-panel.active {
            transform: translateX(0);
        }

        .drawer-header {
            padding: 16px 20px;
            border-bottom: 1px solid var(--border-color);
            display: flex;
            align-items: center;
            justify-content: space-between;
            background: #f8fafc;
        }

        .drawer-body {
            padding: 20px;
            overflow-y: auto;
            flex: 1;
        }

        /* 案件卡片 */
        .case-item-card {
            background: #ffffff;
            border: 1px solid var(--border-color);
            border-radius: 10px;
            padding: 16px;
            margin-bottom: 14px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.03);
            transition: all 0.2s ease;
        }

        .case-item-card:hover {
            border-color: #cbd5e1;
            box-shadow: 0 3px 8px rgba(0,0,0,0.06);
        }

        /* 案件照片縮圖 */
        .case-photo-thumb {
            width: 90px;
            height: 68px;
            object-fit: cover;
            border-radius: 6px;
            border: 1px solid #cbd5e1;
            cursor: pointer;
            transition: transform 0.2s;
        }

        .case-photo-thumb:hover {
            transform: scale(1.05);
            border-color: var(--brand-blue);
        }

        /* 歷史時間軸 */
        .timeline-item {
            position: relative;
            padding-left: 24px;
            padding-bottom: 12px;
            border-left: 2px solid #e2e8f0;
        }

        .timeline-item:last-child {
            border-left-color: transparent;
            padding-bottom: 0;
        }

        .timeline-dot {
            position: absolute;
            left: -6px;
            top: 2px;
            width: 10px;
            height: 10px;
            border-radius: 50%;
            background: var(--brand-blue);
            box-shadow: 0 0 0 3px #e0f2fe;
        }

        /* 手機端自適應卡片 */
        @media screen and (max-width: 991px) {
            .table-desktop-view {
                display: none !important;
            }

            .mobile-card-list {
                display: block !important;
            }

            .mobile-fac-card {
                background: #ffffff;
                border: 1px solid var(--border-color);
                border-radius: 12px;
                padding: 16px;
                margin-bottom: 12px;
                box-shadow: 0 2px 6px rgba(15, 23, 42, 0.04);
            }
        }

        @media screen and (min-width: 992px) {
            .table-desktop-view {
                display: table !important;
            }

            .mobile-card-list {
                display: none !important;
            }
        }

        /* 快速載入遮罩 */
        .loading-spinner {
            display: inline-block;
            width: 1.5rem;
            height: 1.5rem;
            border: 3px solid rgba(2, 132, 199, 0.2);
            border-top-color: #0284c7;
            border-radius: 50%;
            animation: spin 0.8s linear infinite;
        }

        @keyframes spin {
            to { transform: rotate(360deg); }
        }

        /* 地圖彈窗高度 */
        #modalMap {
            width: 100%;
            height: 420px;
            border-radius: 8px;
            z-index: 10;
        }
    </style>
</head>
<body>
    <div id="bareApp" v-cloak>
        <!-- 頂部導覽列 -->
        <header class="top-navbar">
            <div class="d-flex align-items-center">
                <a href="../MainPage.aspx?sub=menu1b" class="nav-btn mr-3" title="返回裸露地選單">
                    <i class="fas fa-arrow-left"></i>
                    <span class="d-none d-sm-inline">返回主選單</span>
                </a>
                <div class="navbar-brand-title">
                    <i class="fas fa-layer-group text-white"></i>
                    <span>裸露地管理審查平台</span>
                    <span class="badge badge-light text-dark font-weight-bold ml-2 d-none d-md-inline" style="font-size: 0.82rem;">案件審查作業</span>
                </div>
            </div>

            <div class="d-flex align-items-center gap-2">
                <span class="badge badge-pill badge-light mr-2 d-none d-sm-inline-block py-2 px-3 text-secondary" style="font-size: 13px;">
                    <i class="fas fa-user-shield mr-1 text-primary"></i> {{ currentUser }}
                </span>
                <button type="button" class="nav-btn" v-on:click="fetchList" :disabled="loading" title="重新整理資料">
                    <i class="fas fa-sync-alt" :class="{ 'fa-spin': loading }"></i>
                    <span class="d-none d-sm-inline">重新整理</span>
                </button>
            </div>
        </header>

        <!-- 模式切換分頁列 -->
        <nav class="nav-mode-bar">
            <div class="nav-mode-item" :class="{ 'active': currentMode === 'INV1' }" v-on:click="switchMode('INV1')">
                <i class="fas fa-bolt text-success"></i>
                <span>待初審</span>
                <span class="tab-badge badge-success ml-1">{{ stats.CountInv1 }}</span>
            </div>

            <div class="nav-mode-item" :class="{ 'active': currentMode === 'INV2' }" v-on:click="switchMode('INV2')">
                <i class="fas fa-search text-primary"></i>
                <span>待複審</span>
                <span class="tab-badge badge-primary ml-1">{{ stats.CountInv2 }}</span>
            </div>

            <div class="nav-mode-item" :class="{ 'active': currentMode === 'INV3' }" v-on:click="switchMode('INV3')">
                <i class="fas fa-balance-scale text-warning"></i>
                <span>待三審</span>
                <span class="tab-badge badge-warning ml-1">{{ stats.CountInv3 }}</span>
            </div>

            <div class="nav-mode-item" :class="{ 'active': currentMode === 'ALL' }" v-on:click="switchMode('ALL')">
                <i class="fas fa-list text-secondary"></i>
                <span>全部場址清單</span>
                <span class="tab-badge badge-secondary ml-1">{{ stats.CountTotal }}</span>
            </div>
        </nav>

        <!-- 主體內容區塊 -->
        <main class="container-fluid px-3 px-md-4 py-3">
            <!-- 統計數據卡片列 -->
            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-icon-wrapper bg-success text-white">
                        <i class="fas fa-clipboard-check"></i>
                    </div>
                    <div>
                        <div class="stat-val">{{ stats.CountInv1 }}</div>
                        <div class="stat-lbl">待初審場址數</div>
                    </div>
                </div>

                <div class="stat-card">
                    <div class="stat-icon-wrapper bg-info text-white">
                        <i class="fas fa-search-plus"></i>
                    </div>
                    <div>
                        <div class="stat-val">{{ stats.CountInv2 }}</div>
                        <div class="stat-lbl">待複審場址數</div>
                    </div>
                </div>

                <div class="stat-card">
                    <div class="stat-icon-wrapper bg-warning text-white">
                        <i class="fas fa-gavel"></i>
                    </div>
                    <div>
                        <div class="stat-val">{{ stats.CountInv3 }}</div>
                        <div class="stat-lbl">待三審場址數</div>
                    </div>
                </div>

                <div class="stat-card">
                    <div class="stat-icon-wrapper bg-dark text-white">
                        <i class="fas fa-mountain"></i>
                    </div>
                    <div>
                        <div class="stat-val">{{ totalCases }}</div>
                        <div class="stat-lbl">查核案件總數 ({{ totalCount }} 場址)</div>
                    </div>
                </div>
            </div>

            <!-- 多條件篩選卡片 -->
            <div class="card-modern">
                <div class="card-modern-header">
                    <div class="card-modern-title">
                        <i class="fas fa-filter text-primary"></i>
                        <span>條件篩選與過濾</span>
                    </div>
                    <div>
                        <button type="button" class="btn btn-sm btn-outline-secondary" v-on:click="resetFilter">
                            <i class="fas fa-undo-alt mr-1"></i> 重設條件
                        </button>
                    </div>
                </div>
                <div class="card-modern-body">
                    <div class="row">
                        <div class="col-12 col-md-3 mb-2">
                            <label class="small font-weight-bold text-muted mb-1">裸露地編號</label>
                            <div class="input-group input-group-sm">
                                <div class="input-group-prepend">
                                    <span class="input-group-text"><i class="fas fa-hashtag"></i></span>
                                </div>
                                <input type="text" class="form-control" v-model="filter.bareGroundNo" placeholder="請輸入編號關鍵字..." v-on:keyup.enter="fetchList" />
                            </div>
                        </div>

                        <div class="col-12 col-md-3 mb-2">
                            <label class="small font-weight-bold text-muted mb-1">地址 / 地號</label>
                            <div class="input-group input-group-sm">
                                <div class="input-group-prepend">
                                    <span class="input-group-text"><i class="fas fa-map-marker-alt"></i></span>
                                </div>
                                <input type="text" class="form-control" v-model="filter.addr" placeholder="請輸入地址或地號..." v-on:keyup.enter="fetchList" />
                            </div>
                        </div>

                        <div class="col-12 col-md-2 mb-2">
                            <label class="small font-weight-bold text-muted mb-1">地目分類</label>
                            <div class="input-group input-group-sm">
                                <div class="input-group-prepend">
                                    <span class="input-group-text"><i class="fas fa-tag"></i></span>
                                </div>
                                <input type="text" class="form-control" v-model="filter.landUse" placeholder="地目..." v-on:keyup.enter="fetchList" />
                            </div>
                        </div>

                        <div class="col-12 col-md-4 mb-2">
                            <label class="small font-weight-bold text-muted mb-1">查核日期區間</label>
                            <div class="d-flex align-items-center gap-1">
                                <input type="date" class="form-control form-control-sm" v-model="filter.dateStart" />
                                <span class="text-muted px-1">至</span>
                                <input type="date" class="form-control form-control-sm" v-model="filter.dateEnd" />
                                <button type="button" class="btn btn-sm btn-primary px-3 ml-2 text-nowrap" v-on:click="fetchList" :disabled="loading">
                                    <i class="fas fa-search mr-1"></i> 搜尋
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- 批次審核操作工具列 (待審模式下若有勾選則出現) -->
            <div v-if="currentMode !== 'ALL' && selectedItems.length > 0" class="batch-bar shadow-sm">
                <div class="d-flex align-items-center">
                    <i class="fas fa-check-circle text-primary mr-2" style="font-size: 1.2rem;"></i>
                    <span class="font-weight-bold text-dark">
                        已選取 {{ selectedItems.length }} 處場址案件
                    </span>
                    <span class="text-muted small ml-2 d-none d-sm-inline">
                        (即將批次審核為合格並推進至下一審查階段)
                    </span>
                </div>
                <div class="d-flex align-items-center gap-2">
                    <button type="button" class="btn btn-sm btn-outline-secondary" v-on:click="selectedItems = []">
                        取消全選
                    </button>
                    <button type="button" class="btn btn-sm btn-success font-weight-bold shadow-sm" v-on:click="openBatchModal">
                        <i class="fas fa-stamp mr-1"></i> ⚡ 批次審核合格 ({{ selectedItems.length }})
                    </button>
                </div>
            </div>

            <!-- 主清單卡片 -->
            <div class="card-modern">
                <div class="card-modern-header">
                    <div class="card-modern-title">
                        <i class="fas fa-list-alt text-primary"></i>
                        <span>{{ getModeTitle() }}</span>
                        <span class="badge badge-light text-muted border ml-2">共 {{ items.length }} 筆場址</span>
                    </div>

                    <div class="d-flex align-items-center gap-2">
                        <div v-if="currentMode !== 'ALL'" class="custom-control custom-checkbox mr-2 d-none d-md-inline-block">
                            <input type="checkbox" class="custom-control-input" id="chkSelectAll" :checked="isAllSelected" v-on:change="toggleSelectAll" />
                            <label class="custom-control-label small font-weight-bold cursor-pointer" for="chkSelectAll">全選此頁</label>
                        </div>
                    </div>
                </div>

                <div class="card-modern-body p-0">
                    <!-- 載入中遮罩 -->
                    <div v-if="loading" class="text-center py-5">
                        <div class="loading-spinner mb-2"></div>
                        <div class="text-muted font-weight-bold">正在檢索裸露地查核資料，請稍候...</div>
                    </div>

                    <!-- 無資料提示 -->
                    <div v-else-if="items.length === 0" class="text-center py-5">
                        <i class="fas fa-inbox text-muted mb-3" style="font-size: 3rem; opacity: 0.5;"></i>
                        <h6 class="font-weight-bold text-secondary">目前查無符合條件的裸露地場址</h6>
                        <p class="text-muted small">請嘗試放寬篩選條件或切換不同審查階段分頁。</p>
                    </div>

                    <!-- 桌面端現代化表格 -->
                    <table v-else class="modern-table table-desktop-view">
                        <thead>
                            <tr>
                                <th style="width: 44px; text-align: center;" v-if="currentMode !== 'ALL'">
                                    <input type="checkbox" :checked="isAllSelected" v-on:change="toggleSelectAll" />
                                </th>
                                <th style="width: 140px;">列管編號</th>
                                <th>場址地址 / 地號</th>
                                <th style="width: 120px;">地目分類</th>
                                <th style="width: 180px;">GPS 坐標</th>
                                <th style="width: 150px;">最近查核時間</th>
                                <th style="width: 110px;">當前狀態</th>
                                <th style="width: 170px; text-align: center;">功能操作</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr v-for="item in items" :key="item.Bare_ID">
                                <td style="text-align: center;" v-if="currentMode !== 'ALL'">
                                    <input type="checkbox" :value="item.Bare_ID" v-model="selectedItems" />
                                </td>
                                <td>
                                    <div class="font-weight-bold text-dark">{{ item.BareGroundNo }}</div>
                                    <small class="text-muted">ID: {{ item.Bare_ID }}</small>
                                </td>
                                <td>
                                    <div class="font-weight-600 text-dark">{{ item.ADDR }}</div>
                                </td>
                                <td>
                                    <span class="badge badge-light border text-secondary px-2 py-1">
                                        {{ item.LAND_USE }}
                                    </span>
                                </td>
                                <td>
                                    <div class="small text-muted mb-1">{{ item.CoordText }}</div>
                                    <button v-if="item.Latitude > 0 && item.Longitude > 0" type="button" class="btn btn-xs btn-outline-info py-0 px-2" v-on:click="openMapModal(item)">
                                        <i class="fas fa-map-marked-alt mr-1"></i> 查看地圖
                                    </button>
                                </td>
                                <td>
                                    <div class="small font-weight-bold text-dark">{{ item.Last_Check_Date }}</div>
                                    <small class="text-muted">件數: {{ item.Case_Count }} 筆</small>
                                </td>
                                <td>
                                    <span :class="getStatusBadgeClass(item.Last_INV_State)">
                                        {{ item.Last_State_Name }}
                                    </span>
                                </td>
                                <td style="text-align: center;">
                                    <button type="button" class="btn btn-sm btn-primary font-weight-bold px-3 shadow-sm" v-on:click="openDrawer(item)">
                                        <i class="fas fa-clipboard-list mr-1"></i> 查核紀錄
                                    </button>
                                </td>
                            </tr>
                        </tbody>
                    </table>

                    <!-- 手機端外勤自適應卡片流 -->
                    <div class="mobile-card-list p-3" v-if="!loading && items.length > 0">
                        <div v-for="item in items" :key="item.Bare_ID" class="mobile-fac-card">
                            <div class="d-flex justify-content-between align-items-start mb-2">
                                <div>
                                    <div class="font-weight-bold text-dark" style="font-size: 1.05rem;">{{ item.BareGroundNo }}</div>
                                    <small class="text-muted">ID: {{ item.Bare_ID }} | 地目: {{ item.LAND_USE }}</small>
                                </div>
                                <span :class="getStatusBadgeClass(item.Last_INV_State)">
                                    {{ item.Last_State_Name }}
                                </span>
                            </div>

                            <div class="text-dark font-weight-600 mb-2">
                                <i class="fas fa-map-marker-alt text-danger mr-1"></i> {{ item.ADDR }}
                            </div>

                            <div class="d-flex justify-content-between align-items-center border-top pt-2 mt-2">
                                <div class="small text-muted">
                                    <div><i class="far fa-clock mr-1"></i> 最近: {{ item.Last_Check_Date }}</div>
                                    <div><i class="fas fa-folder-open mr-1"></i> 案件數: {{ item.Case_Count }} 筆</div>
                                </div>
                                <div class="d-flex gap-1">
                                    <button v-if="item.Latitude > 0 && item.Longitude > 0" type="button" class="btn btn-sm btn-outline-secondary" v-on:click="openMapModal(item)">
                                        <i class="fas fa-map-marked-alt"></i>
                                    </button>
                                    <button type="button" class="btn btn-sm btn-primary font-weight-bold" v-on:click="openDrawer(item)">
                                        <i class="fas fa-clipboard-list mr-1"></i> 查核紀錄
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </main>

        <!-- 側邊抽屜式面板 (Drawer / Offcanvas) -->
        <div class="drawer-overlay" :class="{ 'active': drawer.visible }" v-on:click="closeDrawer"></div>
        <div class="drawer-panel" :class="{ 'active': drawer.visible }">
            <div class="drawer-header">
                <div>
                    <h5 class="font-weight-bold text-dark mb-0 d-flex align-items-center">
                        <i class="fas fa-folder-open text-primary mr-2"></i>
                        <span>場址查核紀錄與審查</span>
                    </h5>
                    <small v-if="drawer.facInfo" class="text-muted">
                        {{ drawer.facInfo.BareGroundNo }} - {{ drawer.facInfo.ADDR }}
                    </small>
                </div>
                <button type="button" class="btn btn-sm btn-light border rounded-circle" v-on:click="closeDrawer" style="width: 32px; height: 32px;">
                    <i class="fas fa-times"></i>
                </button>
            </div>

            <div class="drawer-body">
                <!-- 場址基本摘要晶片 -->
                <div v-if="drawer.facInfo" class="p-3 bg-light rounded mb-3 border">
                    <div class="row small">
                        <div class="col-6 mb-1">
                            <span class="text-muted">列管編號：</span>
                            <span class="font-weight-bold text-dark">{{ drawer.facInfo.BareGroundNo }}</span>
                        </div>
                        <div class="col-6 mb-1">
                            <span class="text-muted">地目類別：</span>
                            <span class="font-weight-bold text-dark">{{ drawer.facInfo.LAND_USE }}</span>
                        </div>
                        <div class="col-12 mb-1">
                            <span class="text-muted">場址地址：</span>
                            <span class="font-weight-bold text-dark">{{ drawer.facInfo.ADDR }}</span>
                        </div>
                        <div class="col-12" v-if="drawer.facInfo.Latitude > 0 && drawer.facInfo.Longitude > 0">
                            <span class="text-muted">GPS 座標：</span>
                            <span class="text-dark">{{ drawer.facInfo.Latitude }}, {{ drawer.facInfo.Longitude }}</span>
                            <button type="button" class="btn btn-xs btn-link p-0 ml-2" v-on:click="openMapModal(drawer.facInfo)">
                                <i class="fas fa-map-marked-alt mr-1"></i> 地圖定位
                            </button>
                        </div>
                    </div>
                </div>

                <!-- 案件清單載入中 -->
                <div v-if="drawer.loading" class="text-center py-5">
                    <div class="loading-spinner mb-2"></div>
                    <div class="text-muted small">載入歷次查核案件紀錄中...</div>
                </div>

                <!-- 案件無資料 -->
                <div v-else-if="drawer.cases.length === 0" class="text-center py-5">
                    <i class="fas fa-clipboard text-muted mb-2" style="font-size: 2.5rem; opacity: 0.5;"></i>
                    <div class="text-secondary font-weight-bold">該場址目前無查核案件資料</div>
                </div>

                <!-- 查核案件卡片清單 -->
                <div v-else>
                    <div class="d-flex justify-content-between align-items-center mb-3">
                        <h6 class="font-weight-bold text-dark mb-0">歷次查核明細 (共 {{ drawer.cases.length }} 次)</h6>
                    </div>

                    <div v-for="c in drawer.cases" :key="c.INV_NO" class="case-item-card">
                        <div class="d-flex justify-content-between align-items-start mb-2">
                            <div>
                                <span class="badge badge-dark mr-2">案號: {{ c.INV_NO }}</span>
                                <span class="font-weight-bold text-dark">{{ c.Check_Date }}</span>
                            </div>
                            <span :class="getStatusBadgeClass(c.INV_State)">
                                {{ c.State_Name }}
                            </span>
                        </div>

                        <!-- 面積與規格資訊 -->
                        <div class="p-2 rounded bg-light border mb-2 small text-muted">
                            <i class="fas fa-ruler-combined text-primary mr-1"></i>
                            <span class="text-dark font-weight-600">{{ c.AreaSpec }}</span>
                        </div>

                        <!-- 周界概況與廢棄物 -->
                        <div class="small mb-1">
                            <span class="text-muted font-weight-bold">周界概況：</span>
                            <span class="text-dark">{{ c.Around_Memo }}</span>
                        </div>
                        <div class="small mb-2">
                            <span class="text-muted font-weight-bold">廢棄物外觀：</span>
                            <span class="text-dark">{{ c.Waste_Type }}</span>
                        </div>

                        <!-- 照片縮圖預覽 -->
                        <div v-if="c.Photos && c.Photos.length > 0" class="mb-3">
                            <small class="text-muted d-block font-weight-bold mb-1">現場照片：</small>
                            <div class="d-flex flex-wrap gap-2">
                                <img v-for="(p, pIdx) in c.Photos" :key="pIdx" :src="p" class="case-photo-thumb" v-on:click="previewPhoto(p)" title="點擊放大檢視" />
                            </div>
                        </div>

                        <!-- 審查歷程歷史時間軸 -->
                        <div v-if="c.Histories && c.Histories.length > 0" class="mt-2 pt-2 border-top">
                            <small class="text-muted font-weight-bold d-block mb-2">審查歷程記錄：</small>
                            <div class="timeline-container pl-1">
                                <div v-for="(h, hIdx) in c.Histories" :key="hIdx" class="timeline-item">
                                    <div class="timeline-dot"></div>
                                    <div class="small d-flex justify-content-between">
                                        <span class="font-weight-bold text-dark">{{ h.Chk_User }} ({{ h.State_Name }})</span>
                                        <span class="text-muted">{{ h.Chk_Date }}</span>
                                    </div>
                                    <div class="small text-secondary">
                                        結果：<span class="font-weight-bold text-primary">{{ h.Chk_Result }}</span>
                                        <span v-if="h.Chk_Memo" class="ml-2 text-muted">「{{ h.Chk_Memo }}」</span>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- 功能操作動作列 -->
                        <div class="d-flex justify-content-end align-items-center gap-2 mt-3 pt-2 border-top">
                            <!-- 查看查核結果表 (唯讀檢視) -->
                            <a :href="c.UrlView" target="_blank" class="btn btn-sm btn-outline-secondary font-weight-bold">
                                <i class="fas fa-eye mr-1"></i> 檢視詳情
                            </a>

                            <!-- 初審按鈕 (INV_State === 'A00') -->
                            <a v-if="c.CanFirstChk" :href="c.UrlFirstChk" class="btn btn-sm btn-success font-weight-bold">
                                <i class="fas fa-edit mr-1"></i> 初審作業
                            </a>

                            <!-- 複審按鈕 (INV_State === 'A01') -->
                            <a v-if="c.CanDoubleChk" :href="c.UrlDoubleChk" class="btn btn-sm btn-primary font-weight-bold">
                                <i class="fas fa-check-double mr-1"></i> 複審作業
                            </a>

                            <!-- 三審按鈕 (INV_State === 'A02') -->
                            <a v-if="c.CanTroubleChk" :href="c.UrlTroubleChk" class="btn btn-sm btn-warning font-weight-bold">
                                <i class="fas fa-gavel mr-1"></i> 三審作業
                            </a>

                            <!-- 單筆快速合格審核按鈕 -->
                            <button v-if="c.CanFirstChk || c.CanDoubleChk || c.CanTroubleChk" type="button" class="btn btn-sm btn-outline-success font-weight-bold" v-on:click="openSingleBatchModal(c)">
                                <i class="fas fa-stamp mr-1"></i> 快速合格
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- 批次審查合格確認 Modal -->
        <div class="modal fade" id="batchModal" tabindex="-1" role="dialog" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered" role="document">
                <div class="modal-content shadow">
                    <div class="modal-header bg-light">
                        <h5 class="modal-title font-weight-bold text-dark">
                            <i class="fas fa-stamp text-success mr-2"></i> 批次審核合格確認
                        </h5>
                        <button type="button" class="close" data-dismiss="modal" aria-label="Close" v-on:click="hideModal('batchModal')">
                            <span aria-hidden="true">&times;</span>
                        </button>
                    </div>
                    <div class="modal-body">
                        <p class="text-dark mb-2">
                            您即將把選取的 <span class="font-weight-bold text-primary">{{ batchTargetCount }}</span> 筆查核案件審核為<strong>「合格」</strong>，並推進至下一審查階段。
                        </p>

                        <div class="form-group mb-2">
                            <label class="small font-weight-bold text-muted mb-1">審查意見 / 備註：</label>
                            <input type="text" class="form-control" v-model="batchMemo" placeholder="請輸入審核意見..." />
                        </div>

                        <div class="d-flex flex-wrap gap-1 mb-2">
                            <small class="text-muted d-block w-100 mb-1">常用意見片語：</small>
                            <button type="button" class="btn btn-xs btn-outline-secondary py-0" v-on:click="batchMemo = '現場查核符合規定，審查通過。'">
                                符合規定通過
                            </button>
                            <button type="button" class="btn btn-xs btn-outline-secondary py-0" v-on:click="batchMemo = '現勘無裸露逸散情形，准予備查。'">
                                無逸散准予備查
                            </button>
                            <button type="button" class="btn btn-xs btn-outline-secondary py-0" v-on:click="batchMemo = '現場防制措施齊備，審核合格。'">
                                防制措施齊備
                            </button>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary font-weight-bold" data-dismiss="modal" v-on:click="hideModal('batchModal')">取消</button>
                        <button type="button" class="btn btn-success font-weight-bold px-4" v-on:click="executeBatchPass" :disabled="batchSubmitting">
                            <i class="fas fa-check mr-1" :class="{ 'fa-spin': batchSubmitting }"></i>
                            {{ batchSubmitting ? '審核中...' : '確認送出' }}
                        </button>
                    </div>
                </div>
            </div>
        </div>

        <!-- 現場地圖 Modal -->
        <div class="modal fade" id="mapModal" tabindex="-1" role="dialog" aria-hidden="true">
            <div class="modal-dialog modal-lg modal-dialog-centered" role="document">
                <div class="modal-content shadow">
                    <div class="modal-header bg-light">
                        <h5 class="modal-title font-weight-bold text-dark d-flex align-items-center">
                            <i class="fas fa-map-marked-alt text-primary mr-2"></i>
                            <span>裸露地現場點位地圖</span>
                            <span v-if="mapTarget" class="badge badge-light border ml-2 text-muted font-normal" style="font-size: 0.85rem;">
                                {{ mapTarget.BareGroundNo }}
                            </span>
                        </h5>
                        <button type="button" class="close" data-dismiss="modal" aria-label="Close" v-on:click="hideModal('batchModal')">
                            <span aria-hidden="true">&times;</span>
                        </button>
                    </div>
                    <div class="modal-body p-3">
                        <div id="modalMap"></div>
                        <div v-if="mapTarget" class="mt-2 d-flex justify-content-between align-items-center text-muted small">
                            <div>
                                <i class="fas fa-map-pin text-danger mr-1"></i>
                                <span>{{ mapTarget.ADDR }} ({{ mapTarget.Latitude }}, {{ mapTarget.Longitude }})</span>
                            </div>
                            <a :href="'https://www.google.com/maps?q=' + mapTarget.Latitude + ',' + mapTarget.Longitude" target="_blank" class="btn btn-xs btn-outline-primary">
                                <i class="fas fa-external-link-alt mr-1"></i> 開啟 Google Maps 導航
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- 照片放大燈箱 Modal -->
        <div class="modal fade" id="photoModal" tabindex="-1" role="dialog" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered modal-lg" role="document">
                <div class="modal-content bg-transparent border-0">
                    <div class="modal-body p-0 text-center position-relative">
                        <button type="button" class="btn btn-sm btn-dark rounded-circle position-absolute" data-dismiss="modal" v-on:click="hideModal('photoModal')" style="top: 10px; right: 10px; z-index: 10; width: 36px; height: 36px;">
                            <i class="fas fa-times text-white"></i>
                        </button>
                        <img :src="previewPhotoUrl" class="img-fluid rounded shadow-lg" style="max-height: 80vh; background: #ffffff;" />
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- 本地核心依賴腳本 -->
    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>
    <script src="../Scripts/leaflet/leaflet.js"></script>
    <script src="../Scripts/jquery.min.js"></script>
    <script src="../Scripts/bootstrap.bundle.min.js"></script>

    <!-- 若資安阻擋或載入異常，提供全相容防禦 Mock -->
    <script type="text/javascript">
        if (typeof window.jQuery === 'undefined') {
            window.jQuery = window.$ = function () {
                return {
                    modal: function () {},
                    show: function () {},
                    hide: function () {},
                    on: function () {},
                    find: function () { return this; },
                    each: function () { return this; }
                };
            };
            window.jQuery.fn = window.jQuery.prototype = window.jQuery();
        }
    </script>

    <script type="text/javascript">
        (function () {
            const { createApp, markRaw } = Vue;

            createApp({
                data() {
                    return {
                        currentUser: '載入中...',
                        currentMode: 'INV1',
                        loading: false,
                        items: [],
                        selectedItems: [],
                        totalCount: 0,
                        totalCases: 0,
                        stats: {
                            CountInv1: 0,
                            CountInv2: 0,
                            CountInv3: 0,
                            CountTotal: 0
                        },
                        filter: {
                            bareGroundNo: '',
                            addr: '',
                            landUse: '',
                            dateStart: '',
                            dateEnd: ''
                        },
                        drawer: {
                            visible: false,
                            loading: false,
                            facInfo: null,
                            cases: []
                        },
                        batchMemo: '審核合格，符合規定。',
                        batchTargetCount: 0,
                        batchSubmitting: false,
                        batchTargetPairs: '',
                        mapTarget: null,
                        previewPhotoUrl: ''
                    };
                },
                computed: {
                    isAllSelected() {
                        if (this.items.length === 0) return false;
                        return this.items.length === this.selectedItems.length;
                    }
                },
                mounted() {
                    // 解析網址列是否有自訂 mode
                    const urlParams = new URLSearchParams(window.location.search);
                    const qMode = urlParams.get('mode');
                    if (qMode && ['INV1', 'INV2', 'INV3', 'ALL'].includes(qMode.toUpperCase())) {
                        this.currentMode = qMode.toUpperCase();
                    }

                    this.leafletMap = null;
                    this.leafletMarker = null;

                    this.initData();
                },
                methods: {
                    async initData() {
                        try {
                            const res = await axios.get('managerList_Bare.aspx', {
                                params: { action: 'get_init_data', mode: this.currentMode }
                            });
                            if (res.data && res.data.Success) {
                                this.currentUser = res.data.CurrentUser;
                                if (res.data.Stats) {
                                    this.stats = res.data.Stats;
                                }
                            }
                        } catch (err) {
                            console.error('初始化失敗:', err);
                        }
                        this.fetchList();
                    },

                    async fetchList() {
                        this.loading = true;
                        this.selectedItems = [];
                        try {
                            const res = await axios.get('managerList_Bare.aspx', {
                                params: {
                                    action: 'get_list',
                                    mode: this.currentMode,
                                    bareGroundNo: this.filter.bareGroundNo,
                                    addr: this.filter.addr,
                                    landUse: this.filter.landUse,
                                    dateStart: this.filter.dateStart,
                                    dateEnd: this.filter.dateEnd
                                }
                            });

                            if (res.data && res.data.Success) {
                                this.items = res.data.Items || [];
                                this.totalCount = res.data.TotalCount || 0;
                                this.totalCases = res.data.TotalCases || 0;
                            } else {
                                alert((res.data && res.data.Message) || '查詢失敗');
                            }
                        } catch (err) {
                            console.error('查詢清單失敗:', err);
                            alert('網路連線或伺服器異常，請重新整理');
                        } finally {
                            this.loading = false;
                        }
                    },

                    switchMode(mode) {
                        if (this.currentMode === mode) return;
                        this.currentMode = mode;
                        // 更新網址 QueryString (不刷新頁面)
                        const url = new URL(window.location);
                        url.searchParams.set('mode', mode);
                        window.history.replaceState({}, '', url);

                        this.fetchList();
                    },

                    resetFilter() {
                        this.filter.bareGroundNo = '';
                        this.filter.addr = '';
                        this.filter.landUse = '';
                        this.filter.dateStart = '';
                        this.filter.dateEnd = '';
                        this.fetchList();
                    },

                    toggleSelectAll(e) {
                        if (e.target.checked) {
                            this.selectedItems = this.items.map(it => it.Bare_ID);
                        } else {
                            this.selectedItems = [];
                        }
                    },

                    getModeTitle() {
                        switch (this.currentMode) {
                            case 'INV1': return '待初審裸露地清單';
                            case 'INV2': return '待複審裸露地清單';
                            case 'INV3': return '待三審裸露地清單';
                            default: return '全部裸露地場址清單';
                        }
                    },

                    getStatusBadgeClass(stateCode) {
                        switch (stateCode) {
                            case 'A00': return 'badge-status-inv1';
                            case 'A01': return 'badge-status-inv2';
                            case 'A02': return 'badge-status-inv3';
                            default: return 'badge-status-other';
                        }
                    },

                    async openDrawer(item) {
                        this.drawer.visible = true;
                        this.drawer.loading = true;
                        this.drawer.facInfo = item;
                        this.drawer.cases = [];

                        try {
                            const res = await axios.get('managerList_Bare.aspx', {
                                params: {
                                    action: 'get_cases',
                                    bareId: item.Bare_ID,
                                    mode: this.currentMode
                                }
                            });

                            if (res.data && res.data.Success) {
                                this.drawer.cases = res.data.Cases || [];
                                if (res.data.FacInfo) {
                                    this.drawer.facInfo = res.data.FacInfo;
                                }
                            } else {
                                alert((res.data && res.data.Message) || '載入查核案件明細失敗');
                            }
                        } catch (err) {
                            console.error('載入案件明細失敗:', err);
                            alert('載入查核明細發生錯誤');
                        } finally {
                            this.drawer.loading = false;
                        }
                    },

                    closeDrawer() {
                        this.drawer.visible = false;
                    },

                    showModal(modalId) {
                        if (typeof $ !== 'undefined' && typeof $.fn === 'object' && typeof $.fn.modal === 'function') {
                            try {
                                $('#' + modalId).modal('show');
                                return;
                            } catch (e) {}
                        }
                        const el = document.getElementById(modalId);
                        if (el) {
                            el.classList.add('show');
                            el.style.display = 'block';
                            el.removeAttribute('aria-hidden');
                            el.setAttribute('aria-modal', 'true');
                            let backdrop = document.getElementById('backdrop-' + modalId);
                            if (!backdrop) {
                                backdrop = document.createElement('div');
                                backdrop.id = 'backdrop-' + modalId;
                                backdrop.className = 'modal-backdrop fade show';
                                document.body.appendChild(backdrop);
                            }
                            document.body.classList.add('modal-open');
                        }
                    },

                    hideModal(modalId) {
                        if (typeof $ !== 'undefined' && typeof $.fn === 'object' && typeof $.fn.modal === 'function') {
                            try {
                                $('#' + modalId).modal('hide');
                                return;
                            } catch (e) {}
                        }
                        const el = document.getElementById(modalId);
                        if (el) {
                            el.classList.remove('show');
                            el.style.display = 'none';
                            el.setAttribute('aria-hidden', 'true');
                            el.removeAttribute('aria-modal');
                            const backdrop = document.getElementById('backdrop-' + modalId);
                            if (backdrop && backdrop.parentNode) {
                                backdrop.parentNode.removeChild(backdrop);
                            }
                            document.body.classList.remove('modal-open');
                        }
                    },

                    previewPhoto(url) {
                        this.previewPhotoUrl = url;
                        this.showModal('photoModal');
                    },

                    // 批次審核：針對清單選取的場址 (取其待審案件)
                    async openBatchModal() {
                        if (this.selectedItems.length === 0) return;
                        this.batchTargetCount = this.selectedItems.length;

                        // 找出選取的場址對應之最新案件
                        let pairs = [];
                        for (let bid of this.selectedItems) {
                            const target = this.items.find(x => x.Bare_ID === bid);
                            if (target) {
                                pairs.push(bid + ':0'); // 0 代表自動鎖定當前狀態待審案件
                            }
                        }
                        this.batchTargetPairs = pairs.join(',');
                        this.batchMemo = '現場查核符合規定，審查通過。';
                        this.showModal('batchModal');
                    },

                    // 單筆快速審核：在抽屜中針對特定 INV_NO
                    openSingleBatchModal(c) {
                        this.batchTargetCount = 1;
                        this.batchTargetPairs = c.Bare_ID + ':' + c.INV_NO;
                        this.batchMemo = '審核合格，符合規定。';
                        this.showModal('batchModal');
                    },

                    async executeBatchPass() {
                        if (this.batchSubmitting) return;
                        this.batchSubmitting = true;

                        try {
                            const formData = new URLSearchParams();
                            formData.append('action', 'batch_pass');
                            formData.append('mode', this.currentMode);
                            formData.append('items', this.batchTargetPairs);
                            formData.append('memo', this.batchMemo);

                            const res = await axios.post('managerList_Bare.aspx', formData);
                            if (res.data && res.data.Success) {
                                alert(res.data.Message || '審核成功！');
                                this.hideModal('batchModal');
                                this.selectedItems = [];
                                // 若抽屜開著，重新載入抽屜資料
                                if (this.drawer.visible && this.drawer.facInfo) {
                                    this.openDrawer(this.drawer.facInfo);
                                }
                                // 刷新統計與主列表
                                this.initData();
                            } else {
                                alert((res.data && res.data.Message) || '批次審核失敗');
                            }
                        } catch (err) {
                            console.error('批次審核異常:', err);
                            alert('批次審核發生錯誤，請稍後再試');
                        } finally {
                            this.batchSubmitting = false;
                        }
                    },

                    openMapModal(item) {
                        this.mapTarget = item;
                        this.showModal('mapModal');

                        this.$nextTick(() => {
                            setTimeout(() => {
                                this.initLeafletMap(item.Latitude, item.Longitude, item.BareGroundNo, item.ADDR);
                            }, 300);
                        });
                    },

                    initLeafletMap(lat, lng, no, addr) {
                        if (!lat || !lng || lat === 0 || lng === 0) return;

                        if (!this.leafletMap) {
                            // 嚴格遵守 SKILL：Leaflet 實例使用 markRaw 隔離，杜絕 Vue 3 響應式包裝引發的 project 錯誤
                            const mapInstance = L.map('modalMap', {
                                center: [lat, lng],
                                zoom: 16
                            });

                            L.tileLayer('https://wmts.nlsc.gov.tw/wmts/EMAP/default/GoogleMapsCompatible/{z}/{y}/{x}', {
                                maxZoom: 19,
                                attribution: '&copy; 國土測繪圖資服務雲'
                            }).addTo(mapInstance);

                            this.leafletMap = markRaw(mapInstance);
                        } else {
                            this.leafletMap.setView([lat, lng], 16);
                            this.leafletMap.invalidateSize();
                        }

                        if (this.leafletMarker) {
                            this.leafletMap.removeLayer(this.leafletMarker);
                        }

                        const marker = L.marker([lat, lng]).addTo(this.leafletMap);
                        marker.bindPopup('<strong>' + no + '</strong><br/>' + addr).openPopup();
                        this.leafletMarker = markRaw(marker);
                    }
                }
            }).mount('#bareApp');
        })();
    </script>
</body>
</html>
