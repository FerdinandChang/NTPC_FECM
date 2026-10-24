<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="CaseList.aspx.cs" Inherits="NTPC_FEC.Case.CaseList" %>

<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定溢散源管理平台 - 固定污染源巡查與任務派遣管理</title>

    <!-- 專屬 Favicon -->
    <link rel="shortcut icon" href="../favicon.ico" type="image/x-icon" />

    <!-- 本地化樣式庫：Bootstrap 4, FontAwesome 5, Leaflet 1.9.4 -->
    <link rel="stylesheet" href="../Content/bootstrap.min.css" />
    <link rel="stylesheet" href="../Content/fontawesome/css/all.min.css" />
    <link rel="stylesheet" href="../Content/leaflet/leaflet.css" />

    <style>
        :root {
            --brand-primary: #0099e5;     /* 新北青藍 */
            --brand-blue: #0284c7;        /* 科技藍 */
            --brand-dark-blue: #0b1f7d;   /* 海軍深藍 */
            --brand-navy: #0f172a;        /* 標題深色 */
            --brand-case: #386b70;        /* 巡查任務派遣主色 (青灰綠) */
            --brand-case-dark: #274d51;   /* 深青灰綠 */
            --brand-case-light: #eef6f6;  /* 淺青灰綠 */
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

        .nav-btn-link {
            color: #ffffff;
            background: rgba(255, 255, 255, 0.18);
            border-radius: 8px;
            padding: 6px 14px;
            font-size: 0.9rem;
            font-weight: 600;
            display: inline-flex;
            align-items: center;
            gap: 6px;
            transition: all 0.2s ease;
            text-decoration: none;
            border: 1px solid rgba(255, 255, 255, 0.3);
        }

        .nav-btn-link:hover {
            background: rgba(255, 255, 255, 0.32);
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
            color: var(--brand-case);
            background: #f8fafc;
        }

        .nav-mode-item.active {
            color: var(--brand-case-dark);
            border-bottom-color: var(--brand-case);
            font-weight: 700;
            background: var(--brand-case-light);
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
        #caseMap {
            width: 100%;
            height: 380px;
            border-radius: 8px;
            z-index: 10;
            transition: height 0.3s ease;
        }

        #caseMap.map-collapsed {
            height: 120px !important;
        }

        /* 地圖標記 Pin */
        .custom-fac-marker {
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .fac-marker-pin {
            width: 32px;
            height: 32px;
            border-radius: 50% 50% 50% 0;
            background: #0284c7;
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

        .fac-marker-pin.pin-major { background: #ef4444; }
        .fac-marker-pin.pin-minor { background: #f59e0b; }
        .fac-marker-pin.pin-zero  { background: #10b981; }

        .fac-marker-num {
            transform: rotate(45deg);
            color: #ffffff;
            font-weight: 800;
            font-size: 12px;
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
            padding: 12px 14px;
            border-bottom: 2px solid var(--border-color);
            border-top: none;
            white-space: nowrap;
        }

        .table-modern td {
            padding: 12px 14px;
            vertical-align: middle;
            border-bottom: 1px solid var(--border-color);
            color: var(--text-main);
            font-size: 14px;
            background: #ffffff;
        }

        .table-modern tbody tr:hover td {
            background: #f1f5f9;
        }

        /* 缺失記點膠囊標籤 */
        .loss-badge {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            font-size: 13px;
            font-weight: 700;
            padding: 4px 10px;
            border-radius: 20px;
            white-space: nowrap;
        }

        .loss-zero {
            background: #ecfdf5;
            color: #047857;
            border: 1px solid #a7f3d0;
        }

        .loss-minor {
            background: #fffbeb;
            color: #b45309;
            border: 1px solid #fde68a;
        }

        .loss-major {
            background: #fef2f2;
            color: #dc2626;
            border: 1px solid #fecaca;
        }

        /* 派遣警示 Tag */
        .mission-tag {
            display: inline-block;
            background: #fef2f2;
            color: #b91c1c;
            border: 1px solid #fca5a5;
            padding: 2px 6px;
            border-radius: 4px;
            font-size: 12px;
            font-weight: 700;
            margin-top: 4px;
        }

        /* 行政區選擇晶片 (Town Chips) */
        .town-chips-wrapper {
            display: flex;
            flex-wrap: wrap;
            gap: 6px;
            max-height: 110px;
            overflow-y: auto;
            padding: 4px 0;
        }

        .town-chip-btn {
            border: 1px solid #cbd5e1;
            background: #ffffff;
            color: #334155;
            padding: 4px 10px;
            border-radius: 6px;
            font-size: 12px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.15s ease;
        }

        .town-chip-btn.active {
            background: var(--brand-case);
            color: #ffffff;
            border-color: var(--brand-case-dark);
            font-weight: 700;
        }

        /* 動作按鈕群組 - 單行排版防折行 */
        .action-btn-group {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 5px;
            flex-wrap: nowrap !important;
            white-space: nowrap !important;
        }

        .btn-action {
            padding: 4px 10px;
            font-size: 12px;
            font-weight: 600;
            border-radius: 6px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 4px;
            transition: all 0.15s ease;
            min-height: 32px;
            white-space: nowrap !important;
            text-decoration: none !important;
        }

        /* 抽屜面板 (Offcanvas Drawer) */
        .drawer-overlay {
            position: fixed;
            top: 0; left: 0; right: 0; bottom: 0;
            background: rgba(15, 23, 42, 0.5);
            z-index: 1040;
            display: flex;
            justify-content: flex-end;
            backdrop-filter: blur(2px);
            animation: fadeIn 0.2s ease;
        }

        .drawer-content {
            background: #ffffff;
            width: 100%;
            max-width: 820px;
            height: 100%;
            box-shadow: -4px 0 24px rgba(0, 0, 0, 0.15);
            display: flex;
            flex-direction: column;
            overflow: hidden;
            animation: slideInRight 0.25s ease;
        }

        @keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
        @keyframes slideInRight { from { transform: translateX(100%); } to { transform: translateX(0); } }

        .drawer-header {
            padding: 16px 20px;
            background: linear-gradient(135deg, #386b70 0%, #274d51 100%);
            color: #ffffff;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .drawer-body {
            padding: 20px;
            overflow-y: auto;
            flex: 1;
        }

        .drawer-footer {
            padding: 12px 20px;
            background: #f8fafc;
            border-top: 1px solid var(--border-color);
            display: flex;
            justify-content: flex-end;
            gap: 10px;
        }

        /* 手機卡片式排版 */
        @media screen and (max-width: 991px) {
            .desktop-table-container {
                display: none !important;
            }
            .mobile-card-container {
                display: block !important;
            }
        }

        @media screen and (min-width: 992px) {
            .desktop-table-container {
                display: block !important;
            }
            .mobile-card-container {
                display: none !important;
            }
        }

        .fac-card-mobile {
            background: #ffffff;
            border: 1px solid var(--border-color);
            border-radius: 10px;
            padding: 16px;
            margin-bottom: 12px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.03);
        }
    </style>
</head>
<body>
    <div id="caseListApp" v-cloak>
        <!-- 頂部深青藍漸層導覽列 (全站標準左側導航、右側使用者與輔助操作) -->
        <header class="top-navbar">
            <div class="d-flex align-items-center">
                <a href="../MainPage.aspx?sub=menu1" class="nav-btn mr-2" title="返回主選單">
                    <i class="fas fa-home"></i>
                    <span class="d-none d-sm-inline">回首頁</span>
                </a>
                <a href="CaseList.aspx" class="navbar-brand-title">
                    <i class="fas fa-clipboard-check text-white"></i>
                    <span>固定源巡查與派遣管理</span>
                    <span class="badge badge-light text-dark font-weight-bold ml-1">
                        {{ counts.Total }} 筆
                    </span>
                </a>
            </div>
            <div class="d-flex align-items-center gap-2">
                <button type="button" class="btn btn-success btn-sm font-weight-bold shadow-sm mr-2" v-on:click="onPromptNewCase">
                    <i class="fas fa-plus-circle mr-1"></i>
                    <span class="d-none d-sm-inline">新增巡查</span>
                </button>
                <span class="d-none d-md-inline text-white small mr-2">
                    <i class="fas fa-user-circle mr-1"></i>{{ currentUser }}
                </span>
                <a href="../FAC/FAC_List.aspx" class="btn btn-outline-light btn-sm font-weight-bold">
                    <i class="fas fa-industry mr-1"></i>場所資料庫
                </a>
            </div>
        </header>

        <!-- 業務模式分頁切換列 -->
        <nav class="nav-mode-bar">
            <div class="nav-mode-item" :class="{ 'active': filter.Mode === 'all' }" v-on:click="setMode('all')">
                <i class="fas fa-globe-asia"></i> 全部巡查 / 環域
                <span class="tab-badge badge-secondary ml-1">{{ counts.Total }}</span>
            </div>
            <div class="nav-mode-item" :class="{ 'active': filter.Mode === 'reject' }" v-on:click="setMode('reject')">
                <i class="fas fa-file-signature text-danger"></i> 查核暫存 (草稿)
                <span class="tab-badge badge-danger ml-1">{{ counts.Draft }}</span>
            </div>
            <div class="nav-mode-item" :class="{ 'active': filter.Mode === 'back' }" v-on:click="setMode('back')">
                <i class="fas fa-undo-alt text-warning"></i> 退件紀錄
                <span class="tab-badge badge-warning ml-1">{{ counts.Back }}</span>
            </div>
            <div class="nav-mode-item" :class="{ 'active': filter.Mode === 'mission7day' }" v-on:click="setMode('mission7day')">
                <i class="fas fa-exclamation-triangle text-danger"></i> 巡查派遣 (7天未改善)
                <span class="tab-badge badge-danger ml-1">{{ counts.Mission7Day }}</span>
            </div>
            <div class="nav-mode-item" :class="{ 'active': filter.Mode === 'mission2times' }" v-on:click="setMode('mission2times')">
                <i class="fas fa-shield-alt text-purple" style="color: #9333ea;"></i> 提報稽查 (稽查列管)
                <span class="tab-badge badge-info ml-1" style="background: #9333ea;">{{ counts.Mission2Times }}</span>
            </div>
            <div class="nav-mode-item" :class="{ 'active': filter.Mode === 'project' }" v-on:click="setMode('project')">
                <i class="fas fa-anchor text-primary"></i> 臺北港專區
                <span class="tab-badge badge-primary ml-1">{{ counts.Project }}</span>
            </div>
            <div class="nav-mode-item" :class="{ 'active': filter.Mode === 'search' }" v-on:click="setMode('search')">
                <i class="fas fa-history text-secondary"></i> 查核紀錄查詢
            </div>
        </nav>

        <!-- 主體內容容器 -->
        <main class="container-fluid py-3 px-3 px-lg-4">
            <!-- 1. KPI 統計指標卡片 -->
            <div class="row mb-3">
                <div class="col-6 col-md-4 col-xl-2 mb-2">
                    <div class="stat-card" v-on:click="setMode('reject')">
                        <div class="stat-icon bg-danger-light text-danger" style="background:#fee2e2;">
                            <i class="fas fa-edit"></i>
                        </div>
                        <div>
                            <div class="stat-val text-danger">{{ counts.Draft }}</div>
                            <div class="stat-label">暫存待修正</div>
                        </div>
                    </div>
                </div>
                <div class="col-6 col-md-4 col-xl-2 mb-2">
                    <div class="stat-card" v-on:click="setMode('back')">
                        <div class="stat-icon text-warning" style="background:#fef3c7;">
                            <i class="fas fa-reply-all"></i>
                        </div>
                        <div>
                            <div class="stat-val text-warning">{{ counts.Back }}</div>
                            <div class="stat-label">退回待重辦</div>
                        </div>
                    </div>
                </div>
                <div class="col-6 col-md-4 col-xl-2 mb-2">
                    <div class="stat-card" v-on:click="setMode('mission7day')">
                        <div class="stat-icon text-danger" style="background:#fee2e2;">
                            <i class="fas fa-hourglass-half"></i>
                        </div>
                        <div>
                            <div class="stat-val text-danger">{{ counts.Mission7Day }}</div>
                            <div class="stat-label">7天未改善派遣</div>
                        </div>
                    </div>
                </div>
                <div class="col-6 col-md-4 col-xl-2 mb-2">
                    <div class="stat-card" v-on:click="setMode('mission2times')">
                        <div class="stat-icon" style="background:#f3e8ff; color:#9333ea;">
                            <i class="fas fa-balance-scale"></i>
                        </div>
                        <div>
                            <div class="stat-val" style="color:#9333ea;">{{ counts.Mission2Times }}</div>
                            <div class="stat-label">提報稽查列管</div>
                        </div>
                    </div>
                </div>
                <div class="col-6 col-md-4 col-xl-2 mb-2">
                    <div class="stat-card" v-on:click="setMode('project')">
                        <div class="stat-icon bg-info-light text-info" style="background:#e0f2fe;">
                            <i class="fas fa-ship"></i>
                        </div>
                        <div>
                            <div class="stat-val text-info">{{ counts.Project }}</div>
                            <div class="stat-label">臺北港專區</div>
                        </div>
                    </div>
                </div>
                <div class="col-6 col-md-4 col-xl-2 mb-2">
                    <div class="stat-card">
                        <div class="stat-icon bg-success-light text-success" style="background:#dcfce7;">
                            <i class="fas fa-calendar-check"></i>
                        </div>
                        <div>
                            <div class="stat-val text-success">{{ counts.InvMonth }}</div>
                            <div class="stat-label">本月查核場次</div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- 2. 智慧現場地圖卡片 (遵循 inspection-ui-standard) -->
            <div class="card-modern">
                <div class="card-modern-header">
                    <div class="card-modern-title">
                        <i class="fas fa-map-marked-alt text-primary"></i>
                        <span>現場智慧巡查地圖</span>
                        <span class="badge badge-light border text-muted ml-2 font-weight-normal" style="font-size:12px;">
                            標記點位數：{{ mapMarkerCount }}
                        </span>
                    </div>
                    <!-- 控制項零遮擋：定位與全景重設統一置於 Header 右側 -->
                    <div class="d-flex align-items-center gap-2">
                        <button type="button" class="btn btn-sm btn-outline-primary" v-on:click="locateMyGps">
                            <i class="fas fa-crosshairs mr-1"></i> GPS 我的位置
                        </button>
                        <button type="button" class="btn btn-sm btn-outline-secondary" v-on:click="resetMapView">
                            <i class="fas fa-compress-arrows-alt mr-1"></i> 全景
                        </button>
                        <button type="button" class="btn btn-sm btn-outline-dark" v-on:click="isMapCollapsed = !isMapCollapsed">
                            <i :class="isMapCollapsed ? 'fas fa-chevron-down' : 'fas fa-chevron-up'"></i>
                            <span class="d-none d-sm-inline">{{ isMapCollapsed ? '展開地圖' : '收合地圖' }}</span>
                        </button>
                    </div>
                </div>
                <div class="card-modern-body p-0">
                    <div id="caseMap" :class="{ 'map-collapsed': isMapCollapsed }"></div>
                </div>
            </div>

            <!-- 3. 複合條件搜尋與外勤 GPS 定位卡片 (全站標準折疊與操作列) -->
            <div class="card-modern">
                <div class="card-modern-header" style="cursor: pointer;" v-on:click="filterCollapsed = !filterCollapsed">
                    <div class="card-modern-title">
                        <i class="fas fa-filter text-primary"></i>
                        <span>查詢與篩選設定</span>
                    </div>
                    <div class="d-flex align-items-center gap-2">
                        <button type="button" class="btn btn-sm btn-outline-success" v-on:click.stop="searchNearbyGps">
                            <i class="fas fa-street-view mr-1"></i> 搜尋附近場所 (環域 3km)
                        </button>
                        <button type="button" class="btn btn-link btn-sm text-muted p-0 ml-2">
                            <i class="fas" :class="filterCollapsed ? 'fa-chevron-down' : 'fa-chevron-up'"></i>
                        </button>
                    </div>
                </div>
                <div class="card-modern-body" v-show="!filterCollapsed">
                    <div class="row">
                        <div class="col-12 col-md-4 col-lg-3 mb-2">
                            <label class="small font-weight-bold text-muted mb-1">公私場所名稱</label>
                            <input type="text" id="searchFacNameInput" class="form-control form-control-sm" v-model="filter.FacName" placeholder="輸入關鍵字..." v-on:keyup.enter="loadData(1)" />
                        </div>
                        <div class="col-12 col-md-4 col-lg-3 mb-2">
                            <label class="small font-weight-bold text-muted mb-1">管制編號 (C_NO)</label>
                            <input type="text" class="form-control form-control-sm" v-model="filter.CNo" placeholder="如 F1234567" v-on:keyup.enter="loadData(1)" />
                        </div>
                        <div class="col-12 col-md-4 col-lg-3 mb-2">
                            <label class="small font-weight-bold text-muted mb-1">統一編號</label>
                            <input type="text" class="form-control form-control-sm" v-model="filter.ScId" placeholder="8碼統一編號..." v-on:keyup.enter="loadData(1)" />
                        </div>
                        <div class="col-12 col-md-4 col-lg-3 mb-2">
                            <label class="small font-weight-bold text-muted mb-1">排序方式</label>
                            <select class="form-control form-control-sm" v-model="filter.SortBy" v-on:change="loadData(1)">
                                <option value="loss_desc">缺失記點 (高至低)</option>
                                <option value="loss_asc">缺失記點 (低至高)</option>
                                <option value="date_desc">最近巡查日期 (近至遠)</option>
                                <option value="name_asc">場所名稱 (筆畫順序)</option>
                            </select>
                        </div>
                    </div>

                    <!-- 行政區選取晶片 -->
                    <div class="mt-2">
                        <div class="d-flex align-items-center justify-content-between mb-1">
                            <label class="small font-weight-bold text-muted m-0">新北市行政區選取 (已選 {{ filter.Towns.length }} 區)：</label>
                            <div>
                                <button type="button" class="btn btn-link btn-sm p-0 mr-2 text-primary font-weight-bold" v-on:click="selectAllTowns">全選</button>
                                <button type="button" class="btn btn-link btn-sm p-0 text-muted" v-on:click="clearAllTowns">清除</button>
                            </div>
                        </div>
                        <div class="town-chips-wrapper">
                            <button type="button" v-for="t in townList" :key="t.TOWN_NO" 
                                    class="town-chip-btn" :class="{ 'active': filter.Towns.includes(t.TOWN_NA) }"
                                    v-on:click="toggleTown(t.TOWN_NA)">
                                {{ t.TOWN_NA }}
                            </button>
                        </div>
                    </div>

                    <div class="d-flex justify-content-between align-items-center mt-3 pt-2 border-top">
                        <div class="small text-muted">
                            共查詢到 <strong class="text-primary">{{ totalCount }}</strong> 家巡查場所
                        </div>
                        <div>
                            <button type="button" class="btn btn-outline-secondary btn-sm mr-2" v-on:click="resetFilter">
                                <i class="fas fa-undo mr-1"></i> 重設條件
                            </button>
                            <button type="button" class="btn btn-primary btn-sm px-3 font-weight-bold" v-on:click="loadData(1)">
                                <i class="fas fa-search mr-1"></i> 立即查詢
                            </button>
                        </div>
                    </div>
                </div>
            </div>

            <!-- 4. 公私場所查核清單卡片 -->
            <div class="card-modern">
                <div class="card-modern-header">
                    <div class="d-flex align-items-center gap-2">
                        <div class="card-modern-title">
                            <i class="fas fa-list-alt text-primary"></i>
                            <span>巡查場所列表</span>
                        </div>
                        <span class="badge badge-light border text-dark font-weight-bold ml-1">
                            共 {{ totalCount }} 家
                        </span>
                        <span class="badge badge-secondary ml-1 d-none d-sm-inline">
                            頁次 {{ currentPage }} / {{ totalPages }}
                        </span>
                    </div>
                    <div class="d-flex align-items-center">
                        <div class="text-muted small mr-2 d-none d-xl-inline" v-if="gpsDistanceMessage">
                            <i class="fas fa-location-arrow text-success mr-1"></i>{{ gpsDistanceMessage }}
                        </div>

                        <!-- 1. 重新整理 -->
                        <button type="button" class="btn btn-sm btn-outline-secondary mr-2" v-on:click="loadData(currentPage)" :disabled="loading" title="重新整理場所清單">
                            <i class="fas fa-sync-alt mr-1" :class="{ 'fa-spin': loading }"></i>
                            <span class="d-none d-md-inline">重新整理</span>
                        </button>

                        <!-- 2. 匯出 EXCEL -->
                        <button type="button" class="btn btn-sm btn-outline-success font-weight-bold mr-2" v-on:click="exportExcel" :disabled="exporting || totalCount === 0" title="匯出篩選結果為 EXCEL 報表">
                            <i class="fas fa-file-excel mr-1"></i>
                            <span class="d-none d-md-inline">{{ exporting ? '匯出中...' : '匯出 EXCEL' }}</span>
                        </button>

                        <!-- 3. 每頁筆數選擇器 -->
                        <div class="d-inline-flex align-items-center">
                            <span class="small text-muted mr-1 d-none d-lg-inline">每頁：</span>
                            <select class="form-control form-control-sm d-inline-block w-auto" v-model="pageSize" v-on:change="changePageSize">
                                <option :value="15">15 筆</option>
                                <option :value="30">30 筆</option>
                                <option :value="50">50 筆</option>
                            </select>
                        </div>
                    </div>
                </div>
                <div class="card-modern-body p-0">
                    <!-- 載入中動畫 -->
                    <div v-if="loading" class="text-center py-5">
                        <div class="spinner-border text-primary" role="status">
                            <span class="sr-only">載入中...</span>
                        </div>
                        <div class="mt-2 text-muted small font-weight-bold">正在讀取場所與查核資料...</div>
                    </div>

                    <!-- 無資料提示 -->
                    <div v-else-if="items.length === 0" class="text-center py-5 text-muted">
                        <i class="fas fa-folder-open fa-3x mb-3 text-secondary"></i>
                        <div>查無符合篩選條件的公私場所。</div>
                    </div>

                    <!-- 電腦版表格佈局 -->
                    <div v-else class="desktop-table-container table-responsive">
                        <table class="table table-modern">
                            <thead>
                                <tr>
                                    <th style="width: 120px;">管制編號</th>
                                    <th style="min-width: 220px;">公私場所名稱</th>
                                    <th style="width: 160px;">行政區 / 行業別</th>
                                    <th style="min-width: 200px;">製程摘要</th>
                                    <th style="width: 120px;">統一編號</th>
                                    <th style="width: 110px;" class="text-center">缺失記點</th>
                                    <th style="min-width: 200px;">最新查核說明</th>
                                    <th style="width: 200px;" class="text-center">操作功能</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr v-for="item in items" :key="item.FAC_ID" :id="'fac-row-' + item.FAC_ID">
                                    <td>
                                        <span class="badge badge-light border text-dark font-weight-bold" style="font-size:13px;">
                                            {{ item.C_NO || '-' }}
                                        </span>
                                    </td>
                                    <td>
                                        <div class="font-weight-bold text-dark">{{ item.FAC_NAME }}</div>
                                        <div v-if="item.Mission" class="mission-tag">
                                            <i class="fas fa-bell mr-1"></i>{{ item.Mission }}
                                        </div>
                                        <div v-if="item.MissionDeadline" class="small text-danger font-weight-bold">
                                            <i class="far fa-clock mr-1"></i>{{ item.MissionDeadline }}
                                        </div>
                                    </td>
                                    <td>
                                        <div class="font-weight-bold text-primary">{{ item.TOWN || '-' }}</div>
                                        <div class="small text-muted">{{ item.Industrial || '-' }}</div>
                                    </td>
                                    <td>
                                        <div class="small text-muted" style="max-width:280px; line-height: 1.4;">
                                            {{ item.ProcessSummary }}
                                        </div>
                                    </td>
                                    <td>
                                        <button type="button" class="btn btn-link btn-sm p-0 text-dark font-weight-bold text-decoration-none" 
                                                v-on:click="openGcModal(item.S_C_ID)">
                                            {{ item.S_C_ID || '-' }}
                                            <i class="fas fa-external-link-alt text-muted small ml-1"></i>
                                        </button>
                                    </td>
                                    <td class="text-center">
                                        <span class="loss-badge" :class="item.Loss_CSS">
                                            <i class="fas mr-1" :class="item.Loss_Point > 0 ? 'fa-exclamation-circle' : 'fa-check-circle'"></i>
                                            {{ item.Loss_Point }} 點
                                        </span>
                                    </td>
                                    <td>
                                        <div class="small text-secondary" style="max-width: 260px;">
                                            <div class="text-muted font-weight-bold mb-1">
                                                查核日期：{{ item.LastInvDate }}
                                            </div>
                                            {{ item.Loss_Detail }}
                                        </div>
                                    </td>
                                    <td class="text-center">
                                        <div class="action-btn-group">
                                            <button type="button" class="btn btn-sm btn-info btn-action" v-on:click="openFacDrawer(item)">
                                                <i class="fas fa-list-alt"></i> 查核歷程
                                            </button>
                                            <button type="button" class="btn btn-sm btn-warning btn-action text-dark" v-on:click="navigateNewCase(item, false)">
                                                <i class="fas fa-plus"></i> 新增巡查
                                            </button>
                                            <button v-if="item.HasActiveMission" type="button" class="btn btn-sm btn-outline-danger btn-action" v-on:click="openCancelMissionModal(item)">
                                                <i class="fas fa-times"></i> 移除派遣
                                            </button>
                                            <button v-if="item.Lat && item.Lng" type="button" class="btn btn-sm btn-light btn-action border" v-on:click="panToMap(item.Lat, item.Lng, item)">
                                                <i class="fas fa-map-pin text-primary"></i>
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>

                    <!-- 手機端卡片流動排版 -->
                    <div v-if="items.length > 0" class="mobile-card-container p-3">
                        <div v-for="item in items" :key="item.FAC_ID" class="fac-card-mobile">
                            <div class="d-flex align-items-center justify-content-between mb-2">
                                <span class="badge badge-light border text-dark font-weight-bold">
                                    {{ item.C_NO || '-' }}
                                </span>
                                <span class="loss-badge" :class="item.Loss_CSS">
                                    {{ item.Loss_Point }} 點
                                </span>
                            </div>
                            <div class="font-weight-bold text-dark h6 mb-1">{{ item.FAC_NAME }}</div>
                            <div class="small text-muted mb-2">
                                <i class="fas fa-map-marker-alt text-primary mr-1"></i>{{ item.TOWN }} | {{ item.ADDR }}
                            </div>
                            <div v-if="item.Mission" class="mission-tag mb-2 d-block">
                                <i class="fas fa-bell mr-1"></i>{{ item.Mission }}
                            </div>
                            <div class="small text-muted mb-2">
                                <strong>最新查核：</strong>{{ item.LastInvDate }} - {{ item.Loss_Detail }}
                            </div>
                            <div class="d-flex align-items-center justify-content-between pt-2 border-top">
                                <button type="button" class="btn btn-link btn-sm p-0 text-muted" v-on:click="openGcModal(item.S_C_ID)">
                                    統編：{{ item.S_C_ID || '-' }}
                                </button>
                                <div class="action-btn-group">
                                    <button type="button" class="btn btn-sm btn-info btn-action" v-on:click="openFacDrawer(item)">
                                        <i class="fas fa-list-alt"></i> 歷程
                                    </button>
                                    <button type="button" class="btn btn-sm btn-warning btn-action text-dark" v-on:click="navigateNewCase(item, false)">
                                        <i class="fas fa-plus"></i> 新增
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- 分頁控制列 -->
                    <div class="p-3 d-flex align-items-center justify-content-between border-top bg-light" v-if="totalPages > 1">
                        <div class="small text-muted">
                            顯示第 {{ (pageIndex - 1) * pageSize + 1 }} 至 {{ Math.min(pageIndex * pageSize, totalCount) }} 筆，共 {{ totalCount }} 筆
                        </div>
                        <ul class="pagination pagination-sm m-0">
                            <li class="page-item" :class="{ 'disabled': pageIndex <= 1 }">
                                <a class="page-link" href="javascript:void(0)" v-on:click="loadData(pageIndex - 1)">上一頁</a>
                            </li>
                            <li v-for="p in visiblePages" :key="p" class="page-item" :class="{ 'active': p === pageIndex }">
                                <a class="page-link" href="javascript:void(0)" v-on:click="loadData(p)">{{ p }}</a>
                            </li>
                            <li class="page-item" :class="{ 'disabled': pageIndex >= totalPages }">
                                <a class="page-link" href="javascript:void(0)" v-on:click="loadData(pageIndex + 1)">下一頁</a>
                            </li>
                        </ul>
                    </div>
                </div>
            </div>
        </main>

        <!-- 5. 場所歷程與查核抽屜 (Offcanvas Drawer) -->
        <div v-if="isDrawerOpen" class="drawer-overlay" v-on:click.self="closeFacDrawer">
            <div class="drawer-content">
                <div class="drawer-header">
                    <div>
                        <h5 class="m-0 font-weight-bold">
                            <i class="fas fa-building mr-2"></i>{{ activeFac.FAC_NAME }}
                        </h5>
                        <small class="text-white-50">管制編號：{{ activeFac.C_NO || '-' }} | 行政區：{{ activeFac.TOWN || '-' }}</small>
                    </div>
                    <button type="button" class="btn btn-sm btn-light" v-on:click="closeFacDrawer">
                        <i class="fas fa-times"></i>
                    </button>
                </div>

                <div class="bg-light px-3 border-bottom">
                    <ul class="nav nav-tabs border-0">
                        <li class="nav-item">
                            <a class="nav-link font-weight-bold" :class="{ 'active': drawerTab === 'invs' }" href="javascript:void(0)" v-on:click="drawerTab = 'invs'">
                                <i class="fas fa-clipboard-list mr-1"></i> 歷次現場查核清單 ({{ drawerInvs.length }})
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link font-weight-bold" :class="{ 'active': drawerTab === 'basic' }" href="javascript:void(0)" v-on:click="drawerTab = 'basic'">
                                <i class="fas fa-info-circle mr-1"></i> 場所基本資料維護
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link font-weight-bold" :class="{ 'active': drawerTab === 'diagrams' }" href="javascript:void(0)" v-on:click="drawerTab = 'diagrams'">
                                <i class="fas fa-images mr-1"></i> 配置圖與流程圖
                            </a>
                        </li>
                    </ul>
                </div>

                <div class="drawer-body">
                    <!-- Tab 1: 歷次現場查核紀錄 -->
                    <div v-if="drawerTab === 'invs'">
                        <div class="d-flex align-items-center justify-content-between mb-3">
                            <h6 class="font-weight-bold text-dark m-0">現場巡查歷程紀錄</h6>
                            <button type="button" class="btn btn-sm btn-success font-weight-bold" v-on:click="navigateNewCase(activeFac, false)">
                                <i class="fas fa-plus mr-1"></i> 進行新增巡查
                            </button>
                        </div>

                        <div v-if="drawerInvs.length === 0" class="text-center py-5 text-muted">
                            <i class="fas fa-clipboard-check fa-3x mb-2 text-secondary"></i>
                            <div>目前尚無任何現場查核紀錄。</div>
                        </div>

                        <div v-else class="table-responsive">
                            <table class="table table-bordered table-hover">
                                <thead class="thead-light">
                                    <tr>
                                        <th style="width:140px;">巡查時間 / 屬性</th>
                                        <th style="width:100px;">運作狀態</th>
                                        <th style="width:90px;" class="text-center">缺失記點</th>
                                        <th>缺失項目內容</th>
                                        <th style="width:100px;" class="text-center">審核狀態</th>
                                        <th style="width:160px;" class="text-center">功能動作</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr v-for="inv in drawerInvs" :key="inv.INV_NO">
                                        <td>
                                            <div class="font-weight-bold">{{ inv.INV_DATE }}</div>
                                            <span class="badge badge-secondary">{{ inv.INV_TYPE }}</span>
                                        </td>
                                        <td>{{ inv.Work_State }}</td>
                                        <td class="text-center">
                                            <span class="loss-badge" :class="inv.Total_Loss_Point > 0 ? 'loss-major' : 'loss-zero'">
                                                {{ inv.Total_Loss_Point }} 點
                                            </span>
                                        </td>
                                        <td>
                                            <div class="small" style="max-width: 250px;">{{ inv.Loss_Detail }}</div>
                                        </td>
                                        <td class="text-center">
                                            <span class="badge font-weight-bold" :class="getInvStateBadgeClass(inv.INV_State)">
                                                {{ inv.State_Name }}
                                            </span>
                                        </td>
                                        <td class="text-center">
                                            <div class="action-btn-group">
                                                <button v-if="inv.CanEdit" type="button" class="btn btn-sm btn-outline-primary btn-action" title="修改資料" v-on:click="navigateEditCase(inv.INV_NO)">
                                                    <i class="fas fa-edit"></i>
                                                </button>
                                                <button v-if="inv.CanSubmit" type="button" class="btn btn-sm btn-outline-success btn-action" title="送出審核" v-on:click="submitUploadCheck(inv.INV_NO, inv.INV_DATE)">
                                                    <i class="fas fa-paper-plane"></i>
                                                </button>
                                                <button v-if="inv.CanSign" type="button" class="btn btn-sm btn-outline-warning btn-action text-dark" title="簽名確認" v-on:click="navigateResultCase(inv.INV_NO, false)">
                                                    <i class="fas fa-signature"></i>
                                                </button>
                                                <button type="button" class="btn btn-sm btn-outline-info btn-action" title="檢視詳細資料" v-on:click="navigateResultCase(inv.INV_NO, true)">
                                                    <i class="fas fa-eye"></i>
                                                </button>
                                                <button v-if="inv.CanDelete" type="button" class="btn btn-sm btn-outline-danger btn-action" title="刪除記錄" v-on:click="deleteInvRecord(inv.INV_NO, inv.INV_DATE)">
                                                    <i class="fas fa-trash"></i>
                                                </button>
                                            </div>
                                        </td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>

                    <!-- Tab 2: 場所基本資料維護 -->
                    <div v-if="drawerTab === 'basic'">
                        <div class="d-flex align-items-center justify-content-between mb-3">
                            <h6 class="font-weight-bold text-dark m-0">公私場所登記資料</h6>
                            <span v-if="!activeFacInfo.CanEdit" class="badge badge-light border text-muted">
                                <i class="fas fa-lock mr-1"></i>僅首次巡查可修改基本資料
                            </span>
                        </div>

                        <div class="row">
                            <div class="col-md-6 mb-3">
                                <label class="small font-weight-bold text-muted">場所名稱</label>
                                <input type="text" class="form-control" v-model="activeFacInfo.FAC_NAME" :readonly="!activeFacInfo.CanEdit" />
                            </div>
                            <div class="col-md-6 mb-3">
                                <label class="small font-weight-bold text-muted">管制編號</label>
                                <input type="text" class="form-control" v-model="activeFacInfo.C_NO" :readonly="!activeFacInfo.CanEdit" />
                            </div>
                            <div class="col-md-12 mb-3">
                                <label class="small font-weight-bold text-muted">場所地址</label>
                                <input type="text" class="form-control" v-model="activeFacInfo.ADDR" :readonly="!activeFacInfo.CanEdit" />
                            </div>
                            <div class="col-md-6 mb-3">
                                <label class="small font-weight-bold text-muted">地號</label>
                                <input type="text" class="form-control" v-model="activeFacInfo.Land_no" :readonly="!activeFacInfo.CanEdit" />
                            </div>
                            <div class="col-md-6 mb-3">
                                <label class="small font-weight-bold text-muted">工廠登記證編號</label>
                                <input type="text" class="form-control" v-model="activeFacInfo.Lic_NO" :readonly="!activeFacInfo.CanEdit" />
                            </div>
                            <div class="col-md-6 mb-3">
                                <label class="small font-weight-bold text-muted">電話</label>
                                <input type="text" class="form-control" v-model="activeFacInfo.TEL" :readonly="!activeFacInfo.CanEdit" />
                            </div>
                            <div class="col-md-6 mb-3">
                                <label class="small font-weight-bold text-muted">傳真</label>
                                <input type="text" class="form-control" v-model="activeFacInfo.FAX" :readonly="!activeFacInfo.CanEdit" />
                            </div>
                            <div class="col-md-6 mb-3">
                                <label class="small font-weight-bold text-muted">統一編號</label>
                                <input type="text" class="form-control" v-model="activeFacInfo.S_C_ID" :readonly="!activeFacInfo.CanEdit" />
                            </div>
                            <div class="col-md-6 mb-3">
                                <label class="small font-weight-bold text-muted">負責人姓名</label>
                                <input type="text" class="form-control" v-model="activeFacInfo.BOSS_NAME" :readonly="!activeFacInfo.CanEdit" />
                            </div>
                            <div class="col-md-6 mb-3">
                                <label class="small font-weight-bold text-muted">聯絡人姓名</label>
                                <input type="text" class="form-control" v-model="activeFacInfo.Content_Name" :readonly="!activeFacInfo.CanEdit" />
                            </div>
                        </div>

                        <div v-if="activeFacInfo.CanEdit" class="text-right mt-3 pt-2 border-top">
                            <button type="button" class="btn btn-success font-weight-bold px-4" v-on:click="saveFacEditInfo">
                                <i class="fas fa-save mr-1"></i> 儲存異動
                            </button>
                        </div>
                    </div>

                    <!-- Tab 3: 配置圖與製程流程圖 -->
                    <div v-if="drawerTab === 'diagrams'">
                        <div v-if="drawerDiagrams.length === 0" class="text-center py-5 text-muted">
                            <i class="fas fa-file-image fa-3x mb-2 text-secondary"></i>
                            <div>該公私場所尚未上傳配置圖或製程流程圖。</div>
                        </div>
                        <div v-else class="row">
                            <div v-for="d in drawerDiagrams" :key="d.FileName" class="col-12 mb-3">
                                <div class="card border">
                                    <div class="card-header bg-white font-weight-bold d-flex justify-content-between align-items-center">
                                        <span><i class="fas fa-file-alt text-primary mr-2"></i>{{ d.FileType }} ({{ d.FileName }})</span>
                                        <a :href="d.FileUrl" target="_blank" class="btn btn-sm btn-outline-primary">
                                            <i class="fas fa-external-link-alt mr-1"></i>另開檢視
                                        </a>
                                    </div>
                                    <div class="card-body p-2 text-center">
                                        <iframe v-if="d.IsPdf === 'true'" :src="d.FileUrl" style="width:100%; height:450px; border:none;"></iframe>
                                        <img v-else :src="d.FileUrl" class="img-fluid rounded" style="max-height:450px;" />
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="drawer-footer">
                    <button type="button" class="btn btn-secondary" v-on:click="closeFacDrawer">關閉視窗</button>
                </div>
            </div>
        </div>

        <!-- 6. 移除派遣任務對話框 (Modal) -->
        <div v-if="isCancelModalOpen" class="modal fade show d-block" tabindex="-1" style="background: rgba(0,0,0,0.5);">
            <div class="modal-dialog modal-dialog-centered">
                <div class="modal-content border-0 shadow">
                    <div class="modal-header bg-danger text-white">
                        <h5 class="modal-title font-weight-bold">
                            <i class="fas fa-exclamation-triangle mr-2"></i>移除派遣案件設定
                        </h5>
                        <button type="button" class="close text-white" v-on:click="isCancelModalOpen = false">&times;</button>
                    </div>
                    <div class="modal-body">
                        <p class="mb-2"><strong>場所名稱：</strong>{{ cancelTargetFac.FAC_NAME }}</p>
                        <p class="text-muted small mb-3">移除派遣後，該場所將不再出現在待派遣或列管督導清單中。</p>
                        <label class="font-weight-bold small text-muted">請輸入移除原因：</label>
                        <textarea class="form-control" rows="3" v-model="cancelReasonInput" placeholder="請詳述移除派遣之原因..."></textarea>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary btn-sm" v-on:click="isCancelModalOpen = false">取消</button>
                        <button type="button" class="btn btn-danger btn-sm font-weight-bold" v-on:click="confirmCancelMission">
                            確定移除
                        </button>
                    </div>
                </div>
            </div>
        </div>

        <!-- 7. 商工登記查詢彈窗 (Modal) -->
        <div v-if="isGcModalOpen" class="modal fade show d-block" tabindex="-1" style="background: rgba(0,0,0,0.5);">
            <div class="modal-dialog modal-dialog-centered">
                <div class="modal-content border-0 shadow">
                    <div class="modal-header bg-dark text-white">
                        <h5 class="modal-title font-weight-bold">
                            <i class="fas fa-landmark mr-2"></i>經濟部商工登記資料
                        </h5>
                        <button type="button" class="close text-white" v-on:click="isGcModalOpen = false">&times;</button>
                    </div>
                    <div class="modal-body">
                        <div v-if="gcLoading" class="text-center py-4">
                            <div class="spinner-border text-primary"></div>
                            <div class="mt-2 text-muted small">查詢經濟部商業司資料中...</div>
                        </div>
                        <div v-else-if="!gcData" class="text-center py-4 text-muted">
                            查無此統一編號之商工登記資料。
                        </div>
                        <table v-else class="table table-bordered table-sm mb-0">
                            <tr>
                                <th class="bg-light" style="width: 35%;">統一編號</th>
                                <td>{{ gcData.Business_Accounting_NO || currentScId }}</td>
                            </tr>
                            <tr>
                                <th class="bg-light">公司行號名稱</th>
                                <td class="font-weight-bold text-primary">{{ gcData.Company_Name }}</td>
                            </tr>
                            <tr>
                                <th class="bg-light">公司狀態</th>
                                <td><span class="badge badge-info">{{ gcData.Company_Status_Desc }}</span></td>
                            </tr>
                            <tr>
                                <th class="bg-light">負責人姓名</th>
                                <td>{{ gcData.Responsible_Name }}</td>
                            </tr>
                            <tr>
                                <th class="bg-light">公司登記地址</th>
                                <td>{{ gcData.Company_Location }}</td>
                            </tr>
                        </table>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary btn-sm" v-on:click="isGcModalOpen = false">關閉</button>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- 本地端核心前端腳本 (依 GEMINI.md 避開外部 CDN) -->
    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>
    <script src="../Scripts/jquery-3.6.4.min.js"></script>
    <script src="../Scripts/bootstrap.bundle.min.js"></script>
    <script src="../Scripts/leaflet/leaflet.js"></script>

    <script>
        const { createApp } = Vue;

        createApp({
            data() {
                return {
                    currentUser: '<%= User != null && User.Identity != null ? User.Identity.Name : "系統使用者" %>',
                    filter: {
                        Mode: 'all',
                        FacName: '',
                        CNo: '',
                        ScId: '',
                        Towns: [],
                        SortBy: 'loss_desc'
                    },
                    counts: {
                        Draft: 0,
                        Back: 0,
                        Mission7Day: 0,
                        Mission2Times: 0,
                        Project: 0,
                        InvMonth: 0,
                        Total: 0
                    },
                    townList: [],
                    items: [],
                    totalCount: 0,
                    pageIndex: 1,
                    pageSize: 15,
                    loading: false,
                    isMapCollapsed: false,
                    mapMarkerCount: 0,
                    gpsDistanceMessage: '',

                    // 抽屜面板控制
                    isDrawerOpen: false,
                    drawerTab: 'invs',
                    activeFac: {},
                    activeFacInfo: {},
                    drawerInvs: [],
                    drawerDiagrams: [],

                    // 移除派遣
                    isCancelModalOpen: false,
                    cancelTargetFac: {},
                    cancelReasonInput: '',

                    // 商工登記
                    isGcModalOpen: false,
                    gcLoading: false,
                    currentScId: '',
                    gcData: null
                };
            },
            computed: {
                totalPages() {
                    return Math.ceil(this.totalCount / this.pageSize) || 1;
                },
                visiblePages() {
                    const pages = [];
                    const start = Math.max(1, this.pageIndex - 2);
                    const end = Math.min(this.totalPages, start + 4);
                    for (let p = start; p <= end; p++) {
                        pages.push(p);
                    }
                    return pages;
                }
            },
            created() {
                // 由 URL 解析預設 mode
                const params = new URLSearchParams(window.location.search);
                const modeParam = params.get('mode');
                if (modeParam) {
                    this.filter.Mode = modeParam.toLowerCase();
                }
                // 若帶入特定 facId 亦可自動展開
                this.defFacId = params.get('id');
            },
            mounted() {
                this.initMap();
                this.loadTowns();
                this.loadCounts();
                this.loadData(1);
                this.$nextTick(function () {
                    setTimeout(function () {
                        if (this.leafletMap) {
                            this.leafletMap.invalidateSize();
                        }
                    }.bind(this), 300);
                });
            },
            watch: {
                isMapCollapsed: function () {
                    setTimeout(function () {
                        if (this.leafletMap) {
                            this.leafletMap.invalidateSize();
                        }
                    }.bind(this), 350);
                }
            },
            methods: {
                // 1. 初始化 Leaflet 地圖 (遵循 inspection-ui-standard 物件隔離)
                initMap() {
                    const defaultCenter = [25.012, 121.465]; // 新北市板橋
                    this.leafletMap = L.map('caseMap', {
                        center: defaultCenter,
                        zoom: 12,
                        zoomControl: true
                    });

                    L.tileLayer('https://wmts.nlsc.gov.tw/wmts/EMAP/default/GoogleMapsCompatible/{z}/{y}/{x}', {
                        maxZoom: 19,
                        attribution: '臺灣通用電子地圖 &copy; 國土測繪中心'
                    }).addTo(this.leafletMap);

                    this.markersGroup = L.layerGroup().addTo(this.leafletMap);
                },

                // 2. 載入行政區選單
                async loadTowns() {
                    try {
                        const res = await axios.get('CaseList.aspx?action=gettowns');
                        if (res.data && res.data.Success) {
                            this.townList = res.data.Towns || [];
                        }
                    } catch (e) {
                        console.error('載入行政區失敗', e);
                    }
                },

                // 3. 載入 KPI 統計數字
                async loadCounts() {
                    try {
                        const res = await axios.get('CaseList.aspx?action=getcounts');
                        if (res.data && res.data.Success) {
                            this.counts = res.data.Counts;
                        }
                    } catch (e) {
                        console.error('載入統計指標失敗', e);
                    }
                },

                // 4. 切換業務模式
                setMode(m) {
                    this.filter.Mode = m;
                    this.gpsDistanceMessage = '';
                    this.loadData(1);
                },

                // 5. 載入場所清單
                async loadData(page = 1) {
                    this.pageIndex = page;
                    this.loading = true;
                    try {
                        const payload = {
                            Mode: this.filter.Mode,
                            FacName: this.filter.FacName,
                            CNo: this.filter.CNo,
                            ScId: this.filter.ScId,
                            Towns: this.filter.Towns,
                            SortBy: this.filter.SortBy,
                            PageIndex: this.pageIndex,
                            PageSize: this.pageSize
                        };
                        const res = await axios.post('CaseList.aspx?action=getlist', payload);
                        if (res.data && res.data.Success) {
                            this.items = res.data.Items || [];
                            this.totalCount = res.data.Total || 0;
                            this.updateMapMarkers();

                            if (this.defFacId) {
                                const target = this.items.find(x => x.FAC_ID === this.defFacId);
                                if (target) {
                                    this.openFacDrawer(target);
                                }
                                this.defFacId = null;
                            }
                        } else {
                            alert(res.data.Message || '讀取清單失敗');
                        }
                    } catch (e) {
                        console.error('讀取清單失敗', e);
                    } finally {
                        this.loading = false;
                    }
                },

                // 6. 更新地圖點位
                updateMapMarkers() {
                    if (!this.leafletMap || !this.markersGroup) return;
                    this.markersGroup.clearLayers();

                    const validPoints = [];
                    this.items.forEach(item => {
                        if (item.Lat && item.Lng && item.Lat > 0 && item.Lng > 0) {
                            let pinClass = 'pin-zero';
                            if (item.Loss_Point >= 10) pinClass = 'pin-major';
                            else if (item.Loss_Point > 0) pinClass = 'pin-minor';

                            const customIcon = L.divIcon({
                                className: 'custom-fac-marker',
                                html: `<div class="fac-marker-pin ${pinClass}"><span class="fac-marker-num">${item.Loss_Point}</span></div>`,
                                iconSize: [32, 32],
                                iconAnchor: [16, 32],
                                popupAnchor: [0, -28]
                            });

                            const marker = L.marker([item.Lat, item.Lng], { icon: customIcon });
                            const popupHtml = `
                                <div style="min-width:200px;">
                                    <div class="font-weight-bold" style="color:#0f172a; font-size:14px;">${item.FAC_NAME}</div>
                                    <div class="small text-muted mt-1">管編：${item.C_NO || '-'} | 行政區：${item.TOWN || '-'}</div>
                                    <div class="small mt-1">缺失記點：<span class="badge ${item.Loss_Point > 0 ? 'badge-danger' : 'badge-success'}">${item.Loss_Point} 點</span></div>
                                    ${item.Mission ? `<div class="mission-tag mt-1">${item.Mission}</div>` : ''}
                                    <div class="mt-2 pt-2 border-top d-flex gap-1">
                                        <button class="btn btn-sm btn-info py-0 px-2" style="font-size:11px;" onclick="window.caseAppHelper.openDrawer('${item.FAC_ID}')">查看歷程</button>
                                        <button class="btn btn-sm btn-warning py-0 px-2" style="font-size:11px;" onclick="window.caseAppHelper.navNewCase('${item.FAC_ID}')">新增查核</button>
                                    </div>
                                </div>
                            `;
                            marker.bindPopup(popupHtml);
                            this.markersGroup.addLayer(marker);
                            validPoints.push([item.Lat, item.Lng]);
                        }
                    });

                    this.mapMarkerCount = validPoints.length;
                    if (validPoints.length > 0) {
                        const bounds = L.latLngBounds(validPoints);
                        this.leafletMap.fitBounds(bounds, { padding: [30, 30], maxZoom: 15 });
                    }
                },

                // 7. 外勤 GPS 我的位置
                locateMyGps() {
                    if (!("geolocation" in navigator)) {
                        alert("此裝置或瀏覽器不支援 GPS 定位");
                        return;
                    }
                    navigator.geolocation.getCurrentPosition(pos => {
                        const lat = pos.coords.latitude;
                        const lng = pos.coords.longitude;
                        if (this.myGpsMarker) {
                            this.leafletMap.removeLayer(this.myGpsMarker);
                        }
                        this.myGpsMarker = L.circleMarker([lat, lng], {
                            radius: 9,
                            color: '#ffffff',
                            fillColor: '#0099e5',
                            fillOpacity: 1,
                            weight: 3
                        }).addTo(this.leafletMap);
                        this.myGpsMarker.bindPopup("<strong>目前 GPS 位置</strong>").openPopup();
                        this.leafletMap.setView([lat, lng], 15);
                    }, err => {
                        alert("GPS 定位失敗：" + err.message);
                    }, { enableHighAccuracy: true });
                },

                // 8. 重設地圖全景
                resetMapView() {
                    if (!this.leafletMap) return;
                    this.leafletMap.setView([25.012, 121.465], 12);
                },

                // 9. 外勤 GPS 環域搜尋 (半徑 3 公里內場所)
                searchNearbyGps() {
                    if (!("geolocation" in navigator)) {
                        alert("此裝置或瀏覽器不支援 GPS 定位");
                        return;
                    }
                    this.loading = true;
                    navigator.geolocation.getCurrentPosition(async pos => {
                        const lat = pos.coords.latitude;
                        const lng = pos.coords.longitude;
                        try {
                            const res = await axios.post('CaseList.aspx?action=getnearby', {
                                Lat: lat,
                                Lng: lng,
                                RadiusMeters: 3000
                            });
                            if (res.data && res.data.Success) {
                                this.items = res.data.Items || [];
                                this.totalCount = this.items.length;
                                this.gpsDistanceMessage = `已定位所在座標 (${lat.toFixed(4)}, ${lng.toFixed(4)})，篩選 3 公里內場所共 ${this.items.length} 家`;
                                this.updateMapMarkers();
                            } else {
                                alert(res.data.Message || '周邊搜尋失敗');
                            }
                        } catch (e) {
                            alert('周邊搜尋發生異常');
                        } finally {
                            this.loading = false;
                        }
                    }, err => {
                        this.loading = false;
                        alert("GPS 定位取得失敗：" + err.message);
                    }, { enableHighAccuracy: true });
                },

                // 10. 平移地圖至指定點位
                panToMap(lat, lng, item) {
                    if (!this.leafletMap) return;
                    this.leafletMap.setView([lat, lng], 16);
                    if (this.isMapCollapsed) {
                        this.isMapCollapsed = false;
                    }
                    // 觸發高亮提示
                    window.scrollTo({ top: 180, behavior: 'smooth' });
                },

                // 11. 行政區選擇輔助
                toggleTown(tName) {
                    const idx = this.filter.Towns.indexOf(tName);
                    if (idx >= 0) {
                        this.filter.Towns.splice(idx, 1);
                    } else {
                        this.filter.Towns.push(tName);
                    }
                },
                selectAllTowns() {
                    this.filter.Towns = this.townList.map(t => t.TOWN_NA);
                },
                clearAllTowns() {
                    this.filter.Towns = [];
                },
                resetFilter() {
                    this.filter.FacName = '';
                    this.filter.CNo = '';
                    this.filter.ScId = '';
                    this.filter.Towns = [];
                    this.filter.SortBy = 'loss_desc';
                    this.loadData(1);
                },

                // 12. 開啟場所抽屜面板 (歷次查核與基本資料)
                async openFacDrawer(fac) {
                    this.activeFac = fac;
                    this.isDrawerOpen = true;
                    this.drawerTab = 'invs';
                    try {
                        const res = await axios.get('CaseList.aspx?action=getfachistory&facId=' + fac.FAC_ID);
                        if (res.data && res.data.Success) {
                            this.activeFacInfo = res.data.FacInfo || {};
                            this.drawerInvs = res.data.Invs || [];
                            this.drawerDiagrams = res.data.Diagrams || [];
                        } else {
                            alert(res.data.Message || '讀取場所歷程失敗');
                        }
                    } catch (e) {
                        console.error('讀取場所歷程失敗', e);
                    }
                },
                closeFacDrawer() {
                    this.isDrawerOpen = false;
                },

                // 13. 儲存場所基本資料維護
                async saveFacEditInfo() {
                    try {
                        const payload = {
                            FacId: this.activeFac.FAC_ID,
                            FacName: this.activeFacInfo.FAC_NAME,
                            CNo: this.activeFacInfo.C_NO,
                            Addr: this.activeFacInfo.ADDR,
                            LandNo: this.activeFacInfo.Land_no,
                            Fax: this.activeFacInfo.FAX,
                            Tel: this.activeFacInfo.TEL,
                            ScId: this.activeFacInfo.S_C_ID,
                            LicNo: this.activeFacInfo.Lic_NO,
                            BossName: this.activeFacInfo.BOSS_NAME,
                            ContentName: this.activeFacInfo.Content_Name
                        };
                        const res = await axios.post('CaseList.aspx?action=savefacedit', payload);
                        if (res.data && res.data.Success) {
                            alert(res.data.Message);
                            this.loadData(this.pageIndex);
                        } else {
                            alert(res.data.Message || '儲存失敗');
                        }
                    } catch (e) {
                        alert('儲存發生異常');
                    }
                },

                // 14. 查核狀態徽章樣式
                getInvStateBadgeClass(state) {
                    switch (state) {
                        case 'A00a': return 'badge-danger';
                        case 'A00b': return 'badge-warning';
                        case 'A00': return 'badge-info';
                        case 'INV1': return 'badge-primary';
                        case 'INV2': return 'badge-secondary';
                        case 'INV3': return 'badge-dark';
                        case 'A03': return 'badge-success';
                        default: return 'badge-light border';
                    }
                },

                // 15. 送出審核 (UploadCheck)
                async submitUploadCheck(invNo, invDate) {
                    if (!confirm(`是否確定將此筆資料送出審核？\n巡查時間：${invDate}`)) return;
                    try {
                        const res = await axios.get(`CaseList.aspx?action=uploadcheck&facId=${this.activeFac.FAC_ID}&invNo=${invNo}`);
                        if (res.data && res.data.Success) {
                            alert(res.data.Message);
                            this.openFacDrawer(this.activeFac);
                            this.loadCounts();
                            this.loadData(this.pageIndex);
                        } else {
                            alert(res.data.Message || '送出失敗');
                        }
                    } catch (e) {
                        alert('送審異常');
                    }
                },

                // 16. 刪除查核紀錄 (DelInv)
                async deleteInvRecord(invNo, invDate) {
                    if (!confirm(`是否確定刪除此筆查核紀錄？\n巡查時間：${invDate}`)) return;
                    try {
                        const res = await axios.get(`CaseList.aspx?action=delinv&facId=${this.activeFac.FAC_ID}&invNo=${invNo}`);
                        if (res.data && res.data.Success) {
                            alert(res.data.Message);
                            this.openFacDrawer(this.activeFac);
                            this.loadCounts();
                            this.loadData(this.pageIndex);
                        } else {
                            alert(res.data.Message || '刪除失敗');
                        }
                    } catch (e) {
                        alert('刪除異常');
                    }
                },

                // 17. 移除派遣對話框控制
                openCancelMissionModal(fac) {
                    this.cancelTargetFac = fac;
                    this.cancelReasonInput = '';
                    this.isCancelModalOpen = true;
                },
                async confirmCancelMission() {
                    if (!this.cancelReasonInput.trim()) {
                        alert('請輸入移除派遣原因！');
                        return;
                    }
                    try {
                        const payload = {
                            FacId: this.cancelTargetFac.FAC_ID,
                            FinishInvNo: this.cancelTargetFac.Last_INV_NO || 0,
                            CancelReason: this.cancelReasonInput.trim()
                        };
                        const res = await axios.post('CaseList.aspx?action=cancelmission', payload);
                        if (res.data && res.data.Success) {
                            alert(res.data.Message);
                            this.isCancelModalOpen = false;
                            this.loadCounts();
                            this.loadData(this.pageIndex);
                        } else {
                            alert(res.data.Message || '移除派遣失敗');
                        }
                    } catch (e) {
                        alert('移除派遣發生異常');
                    }
                },

                // 18. 商工登記 Modal 控制 (GCIS API)
                async openGcModal(scId) {
                    if (!scId || scId === '-') {
                        alert('該場所無有效統一編號');
                        return;
                    }
                    this.currentScId = scId;
                    this.isGcModalOpen = true;
                    this.gcLoading = true;
                    this.gcData = null;
                    try {
                        const url = `https://data.gcis.nat.gov.tw/od/data/api/5F64D864-61CB-4D0D-8AD9-492047CC1EA6?$format=json&$filter=Business_Accounting_NO eq ${scId}`;
                        const res = await axios.get(url);
                        if (res.data && Array.isArray(res.data) && res.data.length > 0) {
                            this.gcData = res.data[0];
                        }
                    } catch (e) {
                        console.warn('商工登記 API 查詢失敗', e);
                    } finally {
                        this.gcLoading = false;
                    }
                },

                // 19. 導航至 NewCase.aspx / CaseResult.aspx
                async navigateNewCase(fac, isRe) {
                    try {
                        const res = await axios.get('CaseList.aspx?action=gettoken&facId=' + fac.FAC_ID);
                        const token = (res.data && res.data.Token) ? res.data.Token : fac.Md5Token;
                        const mode = isRe ? 'new_re' : 'new';
                        window.location.href = `NewCase.aspx?mode=${mode}&id=${fac.FAC_ID}&id1=${token}`;
                    } catch (e) {
                        window.location.href = `NewCase.aspx?mode=new&id=${fac.FAC_ID}&id1=${fac.Md5Token}`;
                    }
                },
                async navigateEditCase(invNo) {
                    const facId = this.activeFac.FAC_ID;
                    try {
                        const res = await axios.get('CaseList.aspx?action=gettoken&facId=' + facId);
                        const token = (res.data && res.data.Token) ? res.data.Token : '';
                        window.location.href = `NewCase.aspx?mode=edit&id=${facId}&id1=${token}&id2=${invNo}`;
                    } catch (e) {
                        window.location.href = `NewCase.aspx?mode=edit&id=${facId}&id2=${invNo}`;
                    }
                },
                async navigateResultCase(invNo, isRead) {
                    const facId = this.activeFac.FAC_ID;
                    try {
                        const res = await axios.get('CaseList.aspx?action=gettoken&facId=' + facId);
                        const token = (res.data && res.data.Token) ? res.data.Token : '';
                        const readParam = isRead ? '&mode=read' : '';
                        window.location.href = `CaseResult.aspx?id=${facId}&id1=${token}&id2=${invNo}${readParam}`;
                    } catch (e) {
                        window.location.href = `CaseResult.aspx?id=${facId}&id2=${invNo}`;
                    }
                },
                onPromptNewCase() {
                    alert('公私場所防制設施查核需指定受檢場所，請先由下方清單或搜尋欄查詢選定場所，並點選該場所右側之「查核」按鈕進入填報！');
                    this.filterCollapsed = false;
                    this.$nextTick(() => {
                        const input = document.getElementById('searchFacNameInput');
                        if (input) input.focus();
                    });
                }
            }
        }).mount('#caseListApp');

        // 地圖 Popup 全域橋接
        window.caseAppHelper = {
            openDrawer: function (facId) {
                const app = document.querySelector('#caseListApp').__vue_app__._instance.proxy;
                const fac = app.items.find(x => x.FAC_ID === facId);
                if (fac) app.openFacDrawer(fac);
            },
            navNewCase: function (facId) {
                const app = document.querySelector('#caseListApp').__vue_app__._instance.proxy;
                const fac = app.items.find(x => x.FAC_ID === facId);
                if (fac) app.navigateNewCase(fac, false);
            }
        };
    </script>
</body>
</html>
