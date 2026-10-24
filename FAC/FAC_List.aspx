<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="FAC_List.aspx.cs" Inherits="NTPC_FEC.FAC.FAC_List" %>

<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定溢散源管理平台 - 固定污染源公私場所管理清單</title>

    <!-- 專屬 Favicon -->
    <link rel="shortcut icon" href="../favicon.ico" type="image/x-icon" />

    <!-- 本地化樣式庫：Bootstrap 4, FontAwesome 5, Leaflet 1.9.4 -->
    <link rel="stylesheet" href="../Content/bootstrap.min.css" />
    <link rel="stylesheet" href="../Content/fontawesome/css/all.min.css" />
    <link rel="stylesheet" href="../Content/leaflet/leaflet.css" />

    <style>
        :root {
            --brand-primary: #0099e5;     /* 新北天空青藍 */
            --brand-blue: #0284c7;        /* 科技藍 */
            --brand-dark-blue: #0b1f7d;   /* 海軍深藍 */
            --brand-navy: #0f172a;        /* 標題文字主色 */
            --brand-factory: #0d9488;     /* 固定源工業墨綠 */
            --brand-factory-light: #f0fdfa;
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
            color: #ffffff;
            text-decoration: none;
            letter-spacing: 0.5px;
            white-space: nowrap !important;
            flex-shrink: 0;
        }
        .navbar-brand-title:hover {
            color: #ffffff;
            text-decoration: none;
        }

        .nav-btn {
            background: rgba(255, 255, 255, 0.18);
            border: 1px solid rgba(255, 255, 255, 0.3);
            color: #ffffff;
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
            color: #ffffff;
            text-decoration: none !important;
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
            text-decoration: none;
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

        /* 統計指標卡片 */
        .stat-card {
            background: #ffffff;
            border-radius: 12px;
            border: 1px solid var(--border-color);
            padding: 14px 18px;
            display: flex;
            align-items: center;
            gap: 14px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.03);
            transition: transform 0.2s;
        }
        .stat-card:hover {
            transform: translateY(-2px);
        }
        .stat-icon {
            width: 44px;
            height: 44px;
            border-radius: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 20px;
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
            padding: 13px 18px;
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

        /* 地圖控制與收合 */
        #map {
            width: 100%;
            height: 360px;
            border-radius: 0 0 12px 12px;
            z-index: 10;
            transition: height 0.3s ease;
        }
        #map.map-collapsed {
            height: 0 !important;
            padding: 0 !important;
            border: none !important;
        }

        /* 地圖標記 Pin */
        .custom-map-marker {
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .marker-pin {
            width: 32px;
            height: 32px;
            border-radius: 50% 50% 50% 0;
            background: #0d9488;
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
        .marker-icon {
            transform: rotate(45deg);
            color: #ffffff;
            font-size: 13px;
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
            padding: 12px 14px;
            white-space: nowrap;
        }
        .table-custom td {
            padding: 12px 14px;
            vertical-align: middle;
            border-top: 1px solid #f1f5f9;
            font-size: 13.5px;
            color: #1e293b;
        }
        .table-custom tbody tr:hover {
            background-color: #f8fafc;
        }

        /* 行動端卡片 */
        .mobile-item-card {
            background: #ffffff;
            border: 1px solid var(--border-color);
            border-radius: 10px;
            padding: 14px;
            margin-bottom: 12px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.03);
        }

        /* 徽章樣式 */
        .badge-pill-custom {
            padding: 4px 10px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
            display: inline-flex;
            align-items: center;
            gap: 4px;
        }

        /* 歷史歷程時間軸 */
        .timeline {
            position: relative;
            padding-left: 24px;
            margin-top: 10px;
        }
        .timeline::before {
            content: '';
            position: absolute;
            left: 7px;
            top: 4px;
            bottom: 4px;
            width: 2px;
            background: #e2e8f0;
        }
        .timeline-item {
            position: relative;
            margin-bottom: 20px;
        }
        .timeline-dot {
            position: absolute;
            left: -24px;
            top: 4px;
            width: 16px;
            height: 16px;
            border-radius: 50%;
            background: #0284c7;
            border: 3px solid #ffffff;
            box-shadow: 0 0 0 1px #cbd5e1;
        }
        .timeline-content {
            background: #f8fafc;
            border-radius: 8px;
            padding: 10px 14px;
            border: 1px solid #e2e8f0;
        }

        /* 模態彈窗自定義 */
        .modal-custom-backdrop {
            position: fixed;
            top: 0; left: 0; right: 0; bottom: 0;
            background: rgba(15, 23, 42, 0.55);
            backdrop-filter: blur(2px);
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
            max-width: 680px;
            max-height: 90vh;
            display: flex;
            flex-direction: column;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
            overflow: hidden;
            animation: modalFadeIn 0.2s ease-out;
        }
        @keyframes modalFadeIn {
            from { opacity: 0; transform: scale(0.96); }
            to { opacity: 1; transform: scale(1); }
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
    <div id="app" v-cloak>
        <!-- 1. 頂部深青藍導覽列 (Sticky Top Navbar) -->
        <header class="top-navbar">
            <div class="d-flex align-items-center">
                <a href="../MainPage.aspx" class="nav-btn mr-2" title="返回主選單">
                    <i class="fas fa-home"></i>
                    <span class="d-none d-sm-inline">回首頁</span>
                </a>
                <a href="FAC_List.aspx" class="navbar-brand-title">
                    <i class="fas fa-industry text-white"></i>
                    <span class="text-nowrap" style="white-space: nowrap; font-size: clamp(0.92rem, 3.6vw, 1.12rem);">公私場所固定污染源管理</span>
                    <span class="badge badge-light text-dark font-weight-bold ml-1 d-none d-lg-inline" style="font-size: 0.8rem; white-space: nowrap;">
                        {{ stats.Total }} 處場所
                    </span>
                </a>
            </div>
            <div class="d-flex align-items-center gap-2">
                <!-- 派遣模式下的確定派遣快捷鈕 -->
                <button v-if="currentMode === 'mission'" type="button" class="btn btn-warning btn-sm font-weight-bold shadow-sm mr-2"
                        :disabled="selectedFacIds.length === 0" v-on:click="openDispatchModal">
                    <i class="fas fa-paper-plane mr-1"></i>
                    確定派遣 ({{ selectedFacIds.length }})
                </button>

                <!-- 異動模式下的新增場所按鈕 -->
                <button v-if="currentMode === 'edit'" type="button" class="btn btn-success btn-sm font-weight-bold shadow-sm mr-2"
                        v-on:click="addNewFac">
                    <i class="fas fa-plus-circle mr-1"></i>
                    新增場所
                </button>

                <!-- 外勤 GPS 定位搜尋周邊場所按鈕 -->
                <button type="button" class="btn btn-sm btn-light font-weight-bold text-dark shadow-sm mr-2 d-inline-flex align-items-center" style="height: 36px; gap: 6px;" v-on:click="locateNearby" :disabled="locatingNearby">
                    <i class="fas fa-crosshairs text-primary" :class="{ 'fa-spin': locatingNearby }"></i>
                    <span class="text-dark font-weight-bold ml-1">{{ locatingNearby ? '定位中...' : '附近場所' }}</span>
                </button>

                <!-- 地圖收合/展開開關 -->
                <button type="button" class="nav-btn" v-on:click="toggleMapCollapse" :title="isMapCollapsed ? '展開地圖' : '收合地圖'">
                    <i class="fas" :class="isMapCollapsed ? 'fa-map-marked-alt' : 'fa-compress-arrows-alt'"></i>
                    <span class="d-none d-lg-inline">{{ isMapCollapsed ? '展開地圖' : '收合地圖' }}</span>
                </button>
            </div>
        </header>

        <!-- 2. 業務模式分頁切換列 (read, mission, edit, opendata) -->
        <nav class="nav-mode-bar">
            <div class="nav-mode-item" :class="{ 'active': currentMode === 'read' }" v-on:click="switchMode('read')">
                <i class="fas fa-clipboard-check"></i>
                <span>列管場所查詢</span>
                <span class="badge badge-primary font-weight-bold ml-1">{{ stats.Regulated }}</span>
            </div>
            <div class="nav-mode-item" :class="{ 'active': currentMode === 'mission' }" v-on:click="switchMode('mission')">
                <i class="fas fa-tasks"></i>
                <span>稽查派遣管理</span>
                <span class="badge badge-warning font-weight-bold ml-1">{{ stats.Dispatched }}</span>
            </div>
            <div class="nav-mode-item" :class="{ 'active': currentMode === 'edit' }" v-on:click="switchMode('edit')">
                <i class="fas fa-edit"></i>
                <span>場所資料異動維護</span>
                <span class="badge badge-info font-weight-bold ml-1">{{ stats.Unregulated }}</span>
            </div>
            <div class="nav-mode-item" :class="{ 'active': currentMode === 'opendata' }" v-on:click="switchMode('opendata')">
                <i class="fas fa-external-link-alt"></i>
                <span>開放資料與許可證</span>
            </div>
        </nav>

        <!-- 主體內容區塊 -->
        <main class="container-fluid py-3 px-md-4">
            <!-- 3. 核心 KPI 統計看板 -->
            <div class="row mb-3">
                <div class="col-6 col-md-3 mb-2">
                    <div class="stat-card">
                        <div class="stat-icon" style="background: #e0f2fe; color: #0284c7;">
                            <i class="fas fa-building"></i>
                        </div>
                        <div>
                            <div class="text-muted small font-weight-bold">登記場所總數</div>
                            <div class="h4 mb-0 font-weight-bold">{{ stats.Total }}</div>
                        </div>
                    </div>
                </div>
                <div class="col-6 col-md-3 mb-2">
                    <div class="stat-card">
                        <div class="stat-icon" style="background: #ccfbf1; color: #0d9488;">
                            <i class="fas fa-shield-alt"></i>
                        </div>
                        <div>
                            <div class="text-muted small font-weight-bold">正式列管場所</div>
                            <div class="h4 mb-0 font-weight-bold text-success">{{ stats.Regulated }}</div>
                        </div>
                    </div>
                </div>
                <div class="col-6 col-md-3 mb-2">
                    <div class="stat-card">
                        <div class="stat-icon" style="background: #fef3c7; color: #d97706;">
                            <i class="fas fa-paper-plane"></i>
                        </div>
                        <div>
                            <div class="text-muted small font-weight-bold">指派派遣紀錄</div>
                            <div class="h4 mb-0 font-weight-bold text-warning">{{ stats.Dispatched }}</div>
                        </div>
                    </div>
                </div>
                <div class="col-6 col-md-3 mb-2">
                    <div class="stat-card">
                        <div class="stat-icon" style="background: #f1f5f9; color: #475569;">
                            <i class="fas fa-history"></i>
                        </div>
                        <div>
                            <div class="text-muted small font-weight-bold">本月異動紀錄</div>
                            <div class="h4 mb-0 font-weight-bold text-dark">{{ stats.UpdatedThisMonth }}</div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- 4. 智慧現場地圖卡片 (Leaflet.js) -->
            <div class="card-modern mb-3" v-show="!isMapCollapsed">
                <div class="card-modern-header">
                    <h2 class="card-modern-title">
                        <i class="fas fa-map-marked-alt text-primary"></i>
                        <span>場所空間地理分佈 (Leaflet)</span>
                        <small class="text-muted font-weight-normal ml-2" v-if="mapMarkerCount > 0">
                            已標記 {{ mapMarkerCount }} 處座標場所
                        </small>
                    </h2>
                    <div class="d-flex align-items-center gap-2">
                        <button type="button" class="btn btn-sm btn-outline-secondary" v-on:click="resetMapView" title="重設地圖全景">
                            <i class="fas fa-globe-asia mr-1"></i> 新北全景
                        </button>
                        <button type="button" class="btn btn-sm btn-outline-primary" v-on:click="locateNearby" title="定位當前位置">
                            <i class="fas fa-location-arrow mr-1"></i> 定位當前
                        </button>
                    </div>
                </div>
                <div id="map"></div>
            </div>

            <!-- 5. 複合多條件篩選卡片 -->
            <div class="card-modern mb-3">
                <div class="card-modern-header" style="cursor: pointer;" v-on:click="filterCollapsed = !filterCollapsed">
                    <h2 class="card-modern-title">
                        <i class="fas fa-filter text-primary"></i>
                        <span>篩選與搜尋條件</span>
                        <small class="text-muted font-weight-normal ml-2" v-if="hasActiveFilter">
                            (已套用自訂篩選)
                        </small>
                    </h2>
                    <button type="button" class="btn btn-link btn-sm text-muted p-0">
                        <i class="fas" :class="filterCollapsed ? 'fa-chevron-down' : 'fa-chevron-up'"></i>
                    </button>
                </div>
                <div class="card-body p-3" v-show="!filterCollapsed">
                    <div class="row">
                        <div class="col-12 col-sm-6 col-md-3 mb-2">
                            <label class="small font-weight-bold text-muted mb-1">管制編號</label>
                            <input type="text" class="form-control form-control-sm" placeholder="例如：F010..." v-model="filter.cNo" v-on:keyup.enter="doSearch" />
                        </div>
                        <div class="col-12 col-sm-6 col-md-3 mb-2">
                            <label class="small font-weight-bold text-muted mb-1">公私場所名稱</label>
                            <input type="text" class="form-control form-control-sm" placeholder="廠名關鍵字..." v-model="filter.facName" v-on:keyup.enter="doSearch" />
                        </div>
                        <div class="col-12 col-sm-6 col-md-3 mb-2">
                            <label class="small font-weight-bold text-muted mb-1">統一編號</label>
                            <input type="text" class="form-control form-control-sm" placeholder="8碼統編..." v-model="filter.scId" v-on:keyup.enter="doSearch" />
                        </div>
                        <div class="col-12 col-sm-6 col-md-3 mb-2">
                            <label class="small font-weight-bold text-muted mb-1">行政區</label>
                            <select class="form-control form-control-sm" v-model="filter.town" v-on:change="doSearch">
                                <option value="">-- 全新北市 --</option>
                                <option v-for="t in townList" :key="t" :value="t">{{ t }}</option>
                            </select>
                        </div>
                        <div class="col-12 col-sm-6 col-md-3 mb-2">
                            <label class="small font-weight-bold text-muted mb-1">行業別關鍵字</label>
                            <input type="text" class="form-control form-control-sm" placeholder="代碼或名稱..." v-model="filter.industrial" v-on:keyup.enter="doSearch" />
                        </div>
                        <div class="col-12 col-sm-6 col-md-3 mb-2">
                            <label class="small font-weight-bold text-muted mb-1">製程名稱</label>
                            <input type="text" class="form-control form-control-sm" placeholder="製程關鍵字..." v-model="filter.processName" v-on:keyup.enter="doSearch" />
                        </div>
                        <div class="col-12 col-sm-6 col-md-3 mb-2">
                            <label class="small font-weight-bold text-muted mb-1">許可證字號</label>
                            <input type="text" class="form-control form-control-sm" placeholder="許可證號..." v-model="filter.processLic" v-on:keyup.enter="doSearch" />
                        </div>
                        <div class="col-12 col-sm-6 col-md-3 mb-2">
                            <label class="small font-weight-bold text-muted mb-1">巡查分組 / 案件狀態</label>
                            <div class="input-group input-group-sm">
                                <input type="text" class="form-control" placeholder="分組..." v-model="filter.facGroup" v-on:keyup.enter="doSearch" />
                                <input type="text" class="form-control" placeholder="狀態..." v-model="filter.facType" v-on:keyup.enter="doSearch" />
                            </div>
                        </div>
                    </div>
                    <div class="d-flex justify-content-between align-items-center mt-2 pt-2 border-top">
                        <div class="small text-muted">
                            共查詢到 <strong class="text-primary">{{ totalCount }}</strong> 筆場所資料
                        </div>
                        <div>
                            <button type="button" class="btn btn-outline-secondary btn-sm mr-2" v-on:click="resetFilter">
                                <i class="fas fa-undo mr-1"></i> 重設條件
                            </button>
                            <button type="button" class="btn btn-primary btn-sm px-3" v-on:click="doSearch">
                                <i class="fas fa-search mr-1"></i> 立即查詢
                            </button>
                        </div>
                    </div>
                </div>
            </div>

            <!-- 6. 資料列表清單卡片 (標準大四元操作工具列) -->
            <div class="card-modern">
                <div class="card-modern-header">
                    <div class="d-flex align-items-center gap-2">
                        <h2 class="card-modern-title">
                            <i class="fas fa-list-alt text-primary"></i>
                            <span>場所清單列表</span>
                        </h2>
                        <span class="badge badge-light border text-dark font-weight-bold ml-1">
                            共 {{ totalCount }} 筆
                        </span>
                        <span class="badge badge-secondary ml-1 d-none d-sm-inline">
                            頁次 {{ pageIndex }} / {{ totalPages }}
                        </span>
                    </div>
                    <div class="d-flex align-items-center">
                        <!-- 1. 重新整理 -->
                        <button type="button" class="btn btn-sm btn-outline-secondary mr-2" v-on:click="doSearch" :disabled="loading" title="重新整理場所列表">
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
                    <div class="spinner-border text-primary" role="status">
                        <span class="sr-only">讀取中...</span>
                    </div>
                    <div class="text-muted small mt-2">資料讀取中，請稍候...</div>
                </div>

                <!-- 無資料狀態 -->
                <div v-else-if="items.length === 0" class="text-center py-5">
                    <i class="fas fa-folder-open fa-3x text-muted mb-2"></i>
                    <p class="text-muted font-weight-bold">目前無符合條件之場所資料</p>
                    <button type="button" class="btn btn-sm btn-outline-primary" v-on:click="resetFilter">重設篩選條件</button>
                </div>

                <!-- 桌面端表格 (Desktop Table) -->
                <div v-else class="table-responsive d-none d-lg-block">
                    <table class="table-custom">
                        <thead>
                            <tr>
                                <th v-if="currentMode === 'mission'" style="width: 40px; text-align: center;">
                                    <input type="checkbox" v-on:change="toggleSelectAll" :checked="isAllSelected" />
                                </th>
                                <th style="width: 120px;">管制編號</th>
                                <th style="min-width: 220px;">場所名稱 / 派遣資訊</th>
                                <th style="width: 100px;">統一編號</th>
                                <th style="width: 160px;">行業別</th>
                                <th style="width: 140px;">行政區 / 地址</th>
                                <th style="min-width: 240px;">製程名稱 / 許可證</th>
                                <th style="width: 90px; text-align: center;">狀態</th>
                                <th style="width: 190px; text-align: center;">功能動作</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr v-for="item in items" :key="item.FAC_ID">
                                <td v-if="currentMode === 'mission'" style="text-align: center;">
                                    <input type="checkbox" :value="item.FAC_ID" v-model="selectedFacIds" />
                                </td>
                                <td>
                                    <span class="font-weight-bold text-primary">{{ item.C_NO || '-' }}</span>
                                    <div class="small text-muted">{{ item.FAC_ID }}</div>
                                </td>
                                <td>
                                    <div class="font-weight-bold text-dark">{{ item.FAC_NAME }}</div>
                                    <div v-if="item.Mission" class="small text-danger font-weight-bold mt-1">
                                        <i class="fas fa-exclamation-circle mr-1"></i>{{ item.Mission }}
                                    </div>
                                    <div v-if="item.MissionDeadline" class="small text-warning font-weight-bold">
                                        {{ item.MissionDeadline }}
                                    </div>
                                </td>
                                <td>{{ item.S_C_ID || '-' }}</td>
                                <td>
                                    <span class="small">{{ item.Industrial }}</span>
                                </td>
                                <td>
                                    <span class="badge badge-light border text-dark font-weight-bold">{{ item.TOWN || '未指定' }}</span>
                                    <div class="small text-muted text-truncate" style="max-width: 140px;" :title="item.ADDR">{{ item.ADDR }}</div>
                                </td>
                                <td>
                                    <div class="small text-muted" v-if="item.ProcessCount > 0" :title="item.ProcessSummary">
                                        <span class="badge badge-info mr-1">{{ item.ProcessCount }} 製程</span>
                                        <span class="text-truncate d-inline-block align-bottom" style="max-width: 180px;">{{ item.ProcessSummary }}</span>
                                    </div>
                                    <div v-else class="small text-muted">無登記製程</div>
                                </td>
                                <td style="text-align: center;">
                                    <span class="badge" :class="item.FAC_Type === '列管' ? 'badge-success' : 'badge-secondary'">
                                        {{ item.FAC_Type || '非列管' }}
                                    </span>
                                </td>
                                <td style="text-align: center;">
                                    <div class="btn-group btn-group-sm">
                                        <!-- 詳細資料 -->
                                        <a :href="item.DetailUrl" class="btn btn-outline-info" title="查看詳細案件資料">
                                            <i class="fas fa-eye"></i>
                                        </a>

                                        <!-- 地圖定位跳轉 -->
                                        <button v-if="item.Lat && item.Lng" type="button" class="btn btn-outline-primary"
                                                v-on:click="panToMap(item)" title="在地圖中查看">
                                            <i class="fas fa-map-marker-alt"></i>
                                        </button>

                                        <!-- 圖資管理 -->
                                        <button type="button" class="btn btn-outline-secondary" v-on:click="openFilesModal(item)" title="廠區與製程圖資管理">
                                            <i class="fas fa-images"></i>
                                        </button>

                                        <!-- 資料異動 -->
                                        <button type="button" class="btn btn-outline-warning" v-on:click="openEditModal(item)" title="資料異動修改">
                                            <i class="fas fa-edit"></i>
                                        </button>

                                        <!-- 異動歷程 -->
                                        <button type="button" class="btn btn-outline-dark" v-on:click="openHistoryModal(item)" title="查看歷史異動紀錄">
                                            <i class="fas fa-history"></i>
                                        </button>

                                        <!-- 開放資料外連 -->
                                        <a v-if="item.OpenDataUrl" :href="item.OpenDataUrl" target="_blank" class="btn btn-outline-success" title="環境部開放資料許可證">
                                            <i class="fas fa-external-link-alt"></i>
                                        </a>
                                    </div>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>

                <!-- 手機與平板卡片清單 (Mobile Cards) -->
                <div v-if="!loading && items.length > 0" class="d-lg-none p-3">
                    <div v-for="item in items" :key="item.FAC_ID" class="mobile-item-card">
                        <div class="d-flex justify-content-between align-items-start mb-2">
                            <div class="d-flex align-items-center">
                                <input v-if="currentMode === 'mission'" type="checkbox" :value="item.FAC_ID" v-model="selectedFacIds" class="mr-2" />
                                <div>
                                    <div class="font-weight-bold text-dark" style="font-size: 15px;">{{ item.FAC_NAME }}</div>
                                    <span class="small font-weight-bold text-primary">{{ item.C_NO || item.FAC_ID }}</span>
                                </div>
                            </div>
                            <span class="badge" :class="item.FAC_Type === '列管' ? 'badge-success' : 'badge-secondary'">
                                {{ item.FAC_Type || '非列管' }}
                            </span>
                        </div>

                        <div class="small text-muted mb-1">
                            <i class="fas fa-map-marker-alt text-danger mr-1"></i>
                            <span class="font-weight-bold text-dark">[{{ item.TOWN || '新北市' }}]</span> {{ item.ADDR || '無詳細地址' }}
                        </div>
                        <div class="small text-muted mb-1">
                            <i class="fas fa-industry mr-1"></i> 行業：{{ item.Industrial }}
                        </div>
                        <div v-if="item.ProcessCount > 0" class="small text-muted mb-2">
                            <i class="fas fa-cogs mr-1"></i> 製程：{{ item.ProcessSummary }}
                        </div>

                        <div v-if="item.Mission" class="alert alert-danger py-1 px-2 small mb-2 font-weight-bold">
                            <i class="fas fa-exclamation-triangle mr-1"></i> {{ item.Mission }}
                        </div>

                        <div class="d-flex justify-content-between align-items-center pt-2 border-top">
                            <div>
                                <button v-if="item.Lat && item.Lng" type="button" class="btn btn-outline-primary btn-sm py-1 px-2 mr-1" v-on:click="panToMap(item)">
                                    <i class="fas fa-map-marked-alt mr-1"></i>地圖
                                </button>
                                <button type="button" class="btn btn-outline-secondary btn-sm py-1 px-2 mr-1" v-on:click="openFilesModal(item)">
                                    <i class="fas fa-image mr-1"></i>圖資
                                </button>
                                <button type="button" class="btn btn-outline-warning btn-sm py-1 px-2" v-on:click="openEditModal(item)">
                                    <i class="fas fa-edit mr-1"></i>異動
                                </button>
                            </div>
                            <div>
                                <a :href="item.DetailUrl" class="btn btn-primary btn-sm py-1 px-3 font-weight-bold">
                                    詳細 <i class="fas fa-chevron-right ml-1"></i>
                                </a>
                            </div>
                        </div>
                    </div>
                </div>

                                <!-- 自適應底部分頁導覽列 (Responsive Pagination Footer) -->
                <div v-if="!loading && items.length > 0" class="pagination-footer">
                    <div class="pagination-footer-info">
                        顯示第 <strong class="text-dark">{{ (pageIndex - 1) * pageSize + 1 }}</strong> 至 <strong class="text-dark">{{ Math.min(pageIndex * pageSize, totalCount) }}</strong> 筆，共 <strong class="text-dark">{{ totalCount }}</strong> 筆
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
                            <span class="d-none d-md-inline mr-1">末頁</span>
                            <i class="fas fa-angle-double-right"></i>
                        </button>
                    </div>
                </div>
            </div>
        </main>

        <!-- 模態彈窗 A: 圖資管理與上傳 Modal -->
        <div v-if="showFilesModal" class="modal-custom-backdrop" v-on:click.self="showFilesModal = false">
            <div class="modal-custom-card">
                <div class="card-modern-header">
                    <h3 class="card-modern-title">
                        <i class="fas fa-images text-primary"></i>
                        <span>廠區與製程圖資檔案管理</span>
                    </h3>
                    <button type="button" class="close" v-on:click="showFilesModal = false">&times;</button>
                </div>
                <div class="p-3" style="overflow-y: auto;">
                    <div class="bg-light p-2 rounded mb-3">
                        <div class="font-weight-bold text-dark">{{ activeItem.FAC_NAME }}</div>
                        <div class="small text-muted">管制編號：{{ activeItem.C_NO || '-' }} | 場所編號：{{ activeItem.FAC_ID }}</div>
                    </div>

                    <!-- 上傳新圖資 -->
                    <div class="card p-3 mb-3 border">
                        <h6 class="font-weight-bold text-primary mb-2"><i class="fas fa-upload mr-1"></i> 上傳新圖資檔案</h6>
                        <div class="form-row">
                            <div class="col-6 mb-2">
                                <label class="small text-muted font-weight-bold mb-1">對應製程</label>
                                <select class="form-control form-control-sm" v-model="uploadForm.processNo">
                                    <option value="全廠">全廠配置</option>
                                    <option v-for="p in processOptions" :key="p.Process_NO" :value="p.Process_NO">
                                        [{{ p.Process_NO }}] {{ p.Process_Name }}
                                    </option>
                                </select>
                            </div>
                            <div class="col-6 mb-2">
                                <label class="small text-muted font-weight-bold mb-1">圖資類別</label>
                                <select class="form-control form-control-sm" v-model="uploadForm.fileType">
                                    <option value="廠區配置圖">廠區配置圖</option>
                                    <option value="製程流程圖">製程流程圖</option>
                                    <option value="管線分佈圖">管線分佈圖</option>
                                    <option value="其他佐證資料">其他佐證資料</option>
                                </select>
                            </div>
                            <div class="col-12 mb-2">
                                <label class="small text-muted font-weight-bold mb-1">選擇檔案 (JPG, PNG, PDF, DWG)</label>
                                <input type="file" ref="fileInput" class="form-control-file border rounded p-1 small" />
                            </div>
                        </div>
                        <div class="text-right mt-1">
                            <button type="button" class="btn btn-sm btn-primary" :disabled="uploading" v-on:click="submitUploadFile">
                                <i class="fas fa-cloud-upload-alt mr-1"></i> {{ uploading ? '上傳處理中...' : '開始上傳' }}
                            </button>
                        </div>
                    </div>

                    <!-- 現有檔案清單 -->
                    <h6 class="font-weight-bold text-dark mb-2"><i class="fas fa-folder-open mr-1"></i> 目前已上傳圖資 ({{ fileList.length }})</h6>
                    <div v-if="fileList.length === 0" class="text-center py-3 text-muted small border rounded">
                        目前尚無上傳圖資檔案
                    </div>
                    <div v-else class="table-responsive">
                        <table class="table table-sm table-bordered mb-0 small">
                            <thead class="bg-light">
                                <tr>
                                    <th>檔案名稱</th>
                                    <th>製程/類別</th>
                                    <th>上傳時間/人員</th>
                                    <th style="width: 70px; text-align: center;">操作</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr v-for="f in fileList" :key="f.FileName">
                                    <td>
                                        <a :href="f.FileUrl" target="_blank" class="font-weight-bold text-primary">
                                            <i class="fas fa-paperclip mr-1"></i>{{ f.FileName }}
                                        </a>
                                    </td>
                                    <td>{{ f.Process_NO }} / {{ f.File_Type }}</td>
                                    <td>
                                        <div>{{ f.UploadDate }}</div>
                                        <span class="text-muted">{{ f.UploadUserName }}</span>
                                    </td>
                                    <td style="text-align: center;">
                                        <button type="button" class="btn btn-outline-danger btn-sm py-0 px-1" title="刪除檔案" v-on:click="deleteFile(f.FileName)">
                                            <i class="fas fa-trash-alt"></i>
                                        </button>
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
                <div class="p-3 border-top bg-light text-right">
                    <button type="button" class="btn btn-secondary btn-sm" v-on:click="showFilesModal = false">關閉</button>
                </div>
            </div>
        </div>

        <!-- 模態彈窗 B: 場所資料異動編輯 Modal -->
        <div v-if="showEditModal" class="modal-custom-backdrop" v-on:click.self="showEditModal = false">
            <div class="modal-custom-card">
                <div class="card-modern-header">
                    <h3 class="card-modern-title">
                        <i class="fas fa-edit text-warning"></i>
                        <span>場所基本資料異動編輯</span>
                    </h3>
                    <button type="button" class="close" v-on:click="showEditModal = false">&times;</button>
                </div>
                <div class="p-3" style="overflow-y: auto;">
                    <div class="form-group mb-2">
                        <label class="small font-weight-bold text-muted mb-1">公私場所名稱 <span class="text-danger">*</span></label>
                        <input type="text" class="form-control form-control-sm" v-model="editForm.facName" />
                    </div>
                    <div class="form-row">
                        <div class="col-6 mb-2">
                            <label class="small font-weight-bold text-muted mb-1">管制編號</label>
                            <input type="text" class="form-control form-control-sm" v-model="editForm.cNo" />
                        </div>
                        <div class="col-6 mb-2">
                            <label class="small font-weight-bold text-muted mb-1">統一編號</label>
                            <input type="text" class="form-control form-control-sm" v-model="editForm.scId" />
                        </div>
                    </div>
                    <div class="form-group mb-2">
                        <label class="small font-weight-bold text-muted mb-1">場所地址</label>
                        <input type="text" class="form-control form-control-sm" v-model="editForm.addr" />
                    </div>
                    <div class="form-row">
                        <div class="col-6 mb-2">
                            <label class="small font-weight-bold text-muted mb-1">連絡電話</label>
                            <input type="text" class="form-control form-control-sm" v-model="editForm.tel" />
                        </div>
                        <div class="col-6 mb-2">
                            <label class="small font-weight-bold text-muted mb-1">聯絡人姓名</label>
                            <input type="text" class="form-control form-control-sm" v-model="editForm.contentName" />
                        </div>
                    </div>
                    <div class="alert alert-info py-2 px-3 small mt-2 mb-0">
                        <i class="fas fa-info-circle mr-1"></i> 儲存後將同步寫入異動歷程軌跡（FAC_EditHis），可隨時追溯歷史變更紀錄。
                    </div>
                </div>
                <div class="p-3 border-top bg-light d-flex justify-content-between">
                    <button type="button" class="btn btn-secondary btn-sm" v-on:click="showEditModal = false">取消</button>
                    <button type="button" class="btn btn-success btn-sm px-4" :disabled="savingEdit" v-on:click="submitEdit">
                        <i class="fas fa-save mr-1"></i> {{ savingEdit ? '儲存中...' : '確認儲存異動' }}
                    </button>
                </div>
            </div>
        </div>

        <!-- 模態彈窗 C: 異動歷程 Timeline Modal -->
        <div v-if="showHistoryModal" class="modal-custom-backdrop" v-on:click.self="showHistoryModal = false">
            <div class="modal-custom-card">
                <div class="card-modern-header">
                    <h3 class="card-modern-title">
                        <i class="fas fa-history text-dark"></i>
                        <span>場所歷次異動紀錄軌跡</span>
                    </h3>
                    <button type="button" class="close" v-on:click="showHistoryModal = false">&times;</button>
                </div>
                <div class="p-3" style="overflow-y: auto;">
                    <div class="bg-light p-2 rounded mb-3">
                        <div class="font-weight-bold text-dark">{{ activeItem.FAC_NAME }}</div>
                        <div class="small text-muted">場所編號：{{ activeItem.FAC_ID }} | 目前管編：{{ activeItem.C_NO || '-' }}</div>
                    </div>

                    <div v-if="historyList.length === 0" class="text-center py-4 text-muted small">
                        尚無任何歷史異動記錄
                    </div>
                    <div v-else class="timeline">
                        <div v-for="h in historyList" :key="h.Row_Index" class="timeline-item">
                            <div class="timeline-dot"></div>
                            <div class="timeline-content">
                                <div class="d-flex justify-content-between align-items-center mb-1">
                                    <span class="font-weight-bold text-dark small"><i class="fas fa-user-edit mr-1"></i> {{ h.Edit_User }}</span>
                                    <span class="text-muted small">{{ h.Edit_Date }}</span>
                                </div>
                                <div v-if="h.Changes && h.Changes.length > 0">
                                    <div v-for="(c, cIdx) in h.Changes" :key="cIdx" class="small py-1 border-top">
                                        <span class="badge badge-light border text-muted mr-1">{{ c.Field }}</span>
                                        <span class="text-muted text-decoration-line-through">{{ c.OldValue }}</span>
                                        <i class="fas fa-arrow-right mx-1 text-primary" style="font-size: 10px;"></i>
                                        <strong class="text-success">{{ c.NewValue }}</strong>
                                    </div>
                                </div>
                                <div v-else class="small text-muted">場所建立或狀態標記異動</div>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="p-3 border-top bg-light text-right">
                    <button type="button" class="btn btn-secondary btn-sm" v-on:click="showHistoryModal = false">關閉</button>
                </div>
            </div>
        </div>

        <!-- 模態彈窗 D: 確定派遣確認 Modal -->
        <div v-if="showDispatchModal" class="modal-custom-backdrop" v-on:click.self="showDispatchModal = false">
            <div class="modal-custom-card" style="max-width: 500px;">
                <div class="card-modern-header">
                    <h3 class="card-modern-title">
                        <i class="fas fa-paper-plane text-warning"></i>
                        <span>案件指派確認</span>
                    </h3>
                    <button type="button" class="close" v-on:click="showDispatchModal = false">&times;</button>
                </div>
                <div class="p-3">
                    <p class="mb-2">您已選取 <strong class="text-danger">{{ selectedFacIds.length }}</strong> 處公私場所進行稽查任務派遣：</p>
                    <div class="form-group mb-3">
                        <label class="small font-weight-bold text-muted mb-1">派遣原因</label>
                        <select class="form-control" v-model="dispatchReason">
                            <option value="一般派遣">一般派遣</option>
                            <option value="分級管理">分級管理</option>
                            <option value="交辦案件">交辦案件</option>
                            <option value="陳情案件">陳情案件</option>
                            <option value="環境部建議稽查名單">環境部建議稽查名單</option>
                        </select>
                    </div>
                    <div class="alert alert-warning py-2 px-3 small mb-0">
                        <i class="fas fa-info-circle mr-1"></i> 指派完成後，系統將於現場巡查清單註記派遣日期與期限。
                    </div>
                </div>
                <div class="p-3 border-top bg-light d-flex justify-content-between">
                    <button type="button" class="btn btn-secondary btn-sm" v-on:click="showDispatchModal = false">取消</button>
                    <button type="button" class="btn btn-warning btn-sm font-weight-bold px-4" :disabled="dispatching" v-on:click="submitDispatch">
                        <i class="fas fa-check mr-1"></i> {{ dispatching ? '指派中...' : '確定送出派遣' }}
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- 本地核心前端依賴 -->
    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>
    <script src="../Scripts/leaflet/leaflet.js"></script>

    <script>
        const { createApp, markRaw } = Vue;

        createApp({
            data() {
                return {
                    currentMode: 'read',
                    isMapCollapsed: false,
                    filterCollapsed: false,
                    loading: false,
                    exporting: false,
                    locatingNearby: false,
                    uploading: false,
                    savingEdit: false,
                    dispatching: false,

                    // 統計資訊
                    stats: {
                        Total: 0,
                        Regulated: 0,
                        Unregulated: 0,
                        Dispatched: 0,
                        UpdatedThisMonth: 0
                    },

                    // 篩選條件
                    filter: {
                        cNo: '',
                        facName: '',
                        scId: '',
                        town: '',
                        industrial: '',
                        facGroup: '',
                        processName: '',
                        processLic: '',
                        facType: ''
                    },

                    // 清單與分頁
                    items: [],
                    totalCount: 0,
                    pageIndex: 1,
                    pageSize: 15,

                    // 行政區列表
                    townList: [
                        '板橋區', '三重區', '中和區', '永和區', '新莊區', '新店區', '樹林區', '鶯歌區',
                        '三峽區', '淡水區', '汐止區', '瑞芳區', '土城區', '蘆洲區', '五股區', '泰山區',
                        '林口區', '深坑區', '石碇區', '坪林區', '三芝區', '石門區', '八里區', '平溪區',
                        '雙溪區', '貢寮區', '金山區', '萬里區', '烏來區'
                    ],

                    // 勾選場所 (派遣模式)
                    selectedFacIds: [],

                    // 彈窗狀態
                    showFilesModal: false,
                    showEditModal: false,
                    showHistoryModal: false,
                    showDispatchModal: false,

                    // 作用中場所與彈窗資料
                    activeItem: {},
                    processOptions: [],
                    fileList: [],
                    historyList: [],
                    uploadForm: {
                        processNo: '全廠',
                        fileType: '廠區配置圖'
                    },
                    editForm: {
                        facId: '',
                        facName: '',
                        cNo: '',
                        scId: '',
                        addr: '',
                        tel: '',
                        contentName: ''
                    },
                    dispatchReason: '一般派遣',

                    // 地圖相關非響應式標記
                    mapMarkerCount: 0
                };
            },
            computed: {
                totalPages() {
                    return Math.max(1, Math.ceil(this.totalCount / this.pageSize));
                },
                isAllSelected() {
                    if (this.items.length === 0) return false;
                    return this.items.every(item => this.selectedFacIds.includes(item.FAC_ID));
                },
                hasActiveFilter() {
                    return Object.values(this.filter).some(val => val !== '');
                }
            },
            created() {
                // 從 URL 參數解析初始 mode
                const urlParams = new URLSearchParams(window.location.search);
                const modeParam = urlParams.get('mode');
                if (modeParam && ['read', 'mission', 'edit', 'opendata'].includes(modeParam.toLowerCase())) {
                    this.currentMode = modeParam.toLowerCase();
                }
            },
            mounted() {
                this.initLeafletMap();
                this.loadCounts();
                this.doSearch();
            },
            methods: {
                // 1. 初始化 Leaflet 地圖 (遵守物件隔離防崩潰規範)
                initLeafletMap() {
                    const mapEl = document.getElementById('map');
                    if (!mapEl) return;

                    // 預設以新北市中心 (板橋) 為視野
                    const mapInstance = L.map('map', {
                        center: [25.0118, 121.4658],
                        zoom: 12,
                        zoomControl: true
                    });

                    // 臺灣通用電子地圖 WMTS 圖層
                    const emapLayer = L.tileLayer('https://wmts.nlsc.gov.tw/wmts/EMAP/default/GoogleMapsCompatible/{z}/{y}/{x}', {
                        maxZoom: 19,
                        attribution: '&copy; 內政部國土測繪中心'
                    });

                    // 衛星正射影像圖層
                    const photoLayer = L.tileLayer('https://wmts.nlsc.gov.tw/wmts/PHOTO2/default/GoogleMapsCompatible/{z}/{y}/{x}', {
                        maxZoom: 19,
                        attribution: '&copy; 內政部國土測繪中心'
                    });

                    emapLayer.addTo(mapInstance);

                    // 右上角圖層控制
                    L.control.layers({
                        "臺灣通用電子地圖": emapLayer,
                        "衛星正射影像": photoLayer
                    }, null, { position: 'topright' }).addTo(mapInstance);

                    // 建立 MarkerCluster 或 Marker 群組
                    this.markerGroup = L.layerGroup().addTo(mapInstance);

                    // 使用 markRaw 徹底隔離 Leaflet 原生實例，避免 Vue 3 Proxy 封裝導致 project/unproject 拋錯
                    this.leafletMap = markRaw(mapInstance);

                    setTimeout(() => {
                        this.leafletMap.invalidateSize();
                    }, 300);
                },

                // 2. 切換業務模式分頁 (read, mission, edit, opendata)
                switchMode(mode) {
                    this.currentMode = mode;
                    this.selectedFacIds = [];
                    this.pageIndex = 1;
                    this.doSearch();

                    // 更新 URL 參數
                    const newUrl = window.location.pathname + '?mode=' + mode;
                    window.history.replaceState({ path: newUrl }, '', newUrl);
                },

                // 3. 取得統計 KPI 指標
                async loadCounts() {
                    try {
                        const res = await axios.get('FAC_List.aspx?action=getcounts');
                        if (res.data && res.data.Success) {
                            this.stats = res.data.Counts;
                        }
                    } catch (err) {
                        console.error('載入統計數據失敗:', err);
                    }
                },

                // 匯出 EXCEL 報表
                exportExcel() {
                    if (this.totalCount === 0) {
                        alert('目前無符合條件之場所資料可供匯出！');
                        return;
                    }
                    this.exporting = true;
                    const params = new URLSearchParams();
                    params.append('action', 'exportExcel');
                    params.append('mode', this.currentMode || 'read');
                    for (const key in this.filter) {
                        if (this.filter[key]) {
                            params.append(key, this.filter[key]);
                        }
                    }

                    axios.post('FAC_List.aspx', params, { responseType: 'blob' })
                        .then(res => {
                            const contentType = (res.headers && res.headers['content-type']) || '';
                            if (contentType.indexOf('application/vnd.ms-excel') === -1) {
                                const reader = new FileReader();
                                reader.onload = () => {
                                    alert(reader.result || '匯出 Excel 失敗');
                                };
                                reader.readAsText(res.data);
                                return;
                            }
                            const blob = new Blob([res.data], { type: 'application/vnd.ms-excel' });
                            const link = document.createElement('a');
                            link.href = window.URL.createObjectURL(blob);
                            const now = new Date();
                            const timeStr = now.getFullYear() + ('0' + (now.getMonth() + 1)).slice(-2) + ('0' + now.getDate()).slice(-2);
                            link.download = '固定源場所清單_' + timeStr + '.xls';
                            document.body.appendChild(link);
                            link.click();
                            document.body.removeChild(link);
                        })
                        .catch(err => {
                            console.error('匯出 Excel 失敗:', err);
                            alert('匯出 Excel 失敗，請稍後再試');
                        })
                        .finally(() => {
                            this.exporting = false;
                        });
                },

                // 4. 複合查詢場所清單
                async doSearch() {
                    this.loading = true;
                    try {
                        const payload = {
                            Mode: this.currentMode,
                            CNo: this.filter.cNo.trim(),
                            FacName: this.filter.facName.trim(),
                            ScId: this.filter.scId.trim(),
                            Town: this.filter.town,
                            Industrial: this.filter.industrial.trim(),
                            FacGroup: this.filter.facGroup.trim(),
                            ProcessName: this.filter.processName.trim(),
                            ProcessLic: this.filter.processLic.trim(),
                            FacType: this.filter.facType.trim(),
                            PageIndex: this.pageIndex,
                            PageSize: this.pageSize
                        };

                        const res = await axios.post('FAC_List.aspx?action=getlist', payload);
                        if (res.data && res.data.Success) {
                            this.items = res.data.Items || [];
                            this.totalCount = res.data.Total || 0;
                            this.updateMapMarkers();
                        } else {
                            alert(res.data.Message || '查詢失敗');
                        }
                    } catch (err) {
                        console.error('查詢場所清單出錯:', err);
                        alert('載入清單失敗，請檢查網路連線或稍後再試');
                    } finally {
                        this.loading = false;
                    }
                },

                // 5. 更新地圖上的標記 Pin
                updateMapMarkers() {
                    if (!this.leafletMap || !this.markerGroup) return;

                    this.markerGroup.clearLayers();
                    const validCoords = [];

                    this.items.forEach(item => {
                        if (item.Lat && item.Lng && item.Lat > 0 && item.Lng > 0) {
                            validCoords.push([item.Lat, item.Lng]);

                            // 建立自訂 Marker HTML
                            const iconHtml = `
                                <div class="marker-pin">
                                    <i class="fas fa-industry marker-icon"></i>
                                </div>
                            `;

                            const customIcon = L.divIcon({
                                className: 'custom-map-marker',
                                html: iconHtml,
                                iconSize: [32, 32],
                                iconAnchor: [16, 32],
                                popupAnchor: [0, -30]
                            });

                            const marker = L.marker([item.Lat, item.Lng], { icon: customIcon });

                            // Popup 內容
                            const popupContent = `
                                <div style="min-width: 200px; font-family: sans-serif;">
                                    <h6 style="font-weight: 700; margin-bottom: 4px; color: #0f172a;">${item.FAC_NAME}</h6>
                                    <div style="font-size: 12px; color: #0284c7; font-weight: 600; margin-bottom: 4px;">管編：${item.C_NO || item.FAC_ID}</div>
                                    <div style="font-size: 12px; color: #475569; margin-bottom: 6px;">[${item.TOWN || '新北市'}] ${item.ADDR || ''}</div>
                                    <div style="font-size: 11px; color: #64748b; margin-bottom: 8px;">行業：${item.Industrial}</div>
                                    <div style="display: flex; gap: 6px;">
                                        <a href="${item.DetailUrl}" class="btn btn-primary btn-sm py-0 px-2" style="font-size: 11px;">詳細案件</a>
                                        <a href="https://www.google.com/maps/dir/?api=1&destination=${item.Lat},${item.Lng}" target="_blank" class="btn btn-outline-success btn-sm py-0 px-2" style="font-size: 11px;">Google導航</a>
                                    </div>
                                </div>
                            `;
                            marker.bindPopup(popupContent);
                            this.markerGroup.addLayer(marker);
                        }
                    });

                    this.mapMarkerCount = validCoords.length;

                    // 若有點位且非收合狀態，自動適應視野
                    if (validCoords.length > 0 && !this.isMapCollapsed) {
                        try {
                            const bounds = L.latLngBounds(validCoords);
                            this.leafletMap.fitBounds(bounds, { padding: [30, 30], maxZoom: 15 });
                        } catch (e) {}
                    }
                },

                // 6. 平移至指定場所
                panToMap(item) {
                    if (!this.leafletMap || !item.Lat || !item.Lng) return;
                    if (this.isMapCollapsed) {
                        this.isMapCollapsed = false;
                        setTimeout(() => {
                            this.leafletMap.invalidateSize();
                            this.doPan(item);
                        }, 300);
                    } else {
                        this.doPan(item);
                    }
                },
                doPan(item) {
                    this.leafletMap.setView([item.Lat, item.Lng], 16, { animate: true });
                    window.scrollTo({ top: 120, behavior: 'smooth' });
                },

                // 7. 外勤 GPS 定位附近場所
                locateNearby() {
                    if (!("geolocation" in navigator)) {
                        alert("您的裝置不支援 GPS 定位功能");
                        return;
                    }

                    this.locatingNearby = true;
                    navigator.geolocation.getCurrentPosition(
                        async (position) => {
                            const lat = position.coords.latitude;
                            const lng = position.coords.longitude;

                            if (this.leafletMap) {
                                this.leafletMap.setView([lat, lng], 15);
                                L.circleMarker([lat, lng], {
                                    radius: 8,
                                    fillColor: '#0099e5',
                                    color: '#ffffff',
                                    weight: 2,
                                    fillOpacity: 0.9
                                }).addTo(this.leafletMap).bindPopup("您的目前位置").openPopup();
                            }

                            try {
                                const res = await axios.post('FAC_List.aspx?action=getnearby', {
                                    Lat: lat,
                                    Lng: lng,
                                    RadiusMeters: 5000
                                });

                                if (res.data && res.data.Success) {
                                    this.items = res.data.Items || [];
                                    this.totalCount = this.items.length;
                                    this.pageIndex = 1;
                                    this.updateMapMarkers();
                                    alert(`已自動為您找出周邊近距離之 ${this.items.length} 處工廠場所！`);
                                }
                            } catch (e) {
                                console.error('搜尋附近場所失敗:', e);
                            } finally {
                                this.locatingNearby = false;
                            }
                        },
                        (error) => {
                            this.locatingNearby = false;
                            alert("無法取得您的目前 GPS 座標，請確認瀏覽器已允許存取定位權限。");
                        },
                        { enableHighAccuracy: true, timeout: 10000, maximumAge: 0 }
                    );
                },

                // 8. 重設地圖視野至全景
                resetMapView() {
                    if (!this.leafletMap) return;
                    this.leafletMap.setView([25.0118, 121.4658], 12);
                },

                // 9. 地圖展開/收合開關
                toggleMapCollapse() {
                    this.isMapCollapsed = !this.isMapCollapsed;
                    if (!this.isMapCollapsed && this.leafletMap) {
                        setTimeout(() => {
                            this.leafletMap.invalidateSize();
                        }, 300);
                    }
                },

                // 10. 重設篩選
                resetFilter() {
                    this.filter = {
                        cNo: '',
                        facName: '',
                        scId: '',
                        town: '',
                        industrial: '',
                        facGroup: '',
                        processName: '',
                        processLic: '',
                        facType: ''
                    };
                    this.pageIndex = 1;
                    this.doSearch();
                },

                // 11. 分頁切換
                goToPage(p) {
                    if (p < 1 || p > this.totalPages || p === this.pageIndex) return;
                    this.pageIndex = p;
                    this.doSearch();
                },
                changePageSize() {
                    this.pageIndex = 1;
                    this.doSearch();
                },

                // 12. 批次全選控制
                toggleSelectAll(e) {
                    if (e.target.checked) {
                        this.selectedFacIds = this.items.map(item => item.FAC_ID);
                    } else {
                        this.selectedFacIds = [];
                    }
                },

                // 13. 開啟圖資管理彈窗
                async openFilesModal(item) {
                    this.activeItem = item;
                    this.uploadForm.processNo = '全廠';
                    this.uploadForm.fileType = '廠區配置圖';
                    this.fileList = [];
                    this.processOptions = [];
                    this.showFilesModal = true;

                    // 載入製程選項與檔案清單
                    try {
                        const [procRes, fileRes] = await Promise.all([
                            axios.get(`FAC_List.aspx?action=getprocesses&facId=${item.FAC_ID}`),
                            axios.get(`FAC_List.aspx?action=getfiles&facId=${item.FAC_ID}`)
                        ]);

                        if (procRes.data && procRes.data.Success) {
                            this.processOptions = procRes.data.Processes || [];
                        }
                        if (fileRes.data && fileRes.data.Success) {
                            this.fileList = fileRes.data.Files || [];
                        }
                    } catch (e) {
                        console.error('載入圖資資料失敗:', e);
                    }
                },

                // 14. 提交上傳圖資檔案
                async submitUploadFile() {
                    const fileInput = this.$refs.fileInput;
                    if (!fileInput || !fileInput.files || fileInput.files.length === 0) {
                        alert('請選擇欲上傳之圖資檔案！');
                        return;
                    }

                    const formData = new FormData();
                    formData.append('file', fileInput.files[0]);
                    formData.append('facId', this.activeItem.FAC_ID);
                    formData.append('processNo', this.uploadForm.processNo);
                    formData.append('fileType', this.uploadForm.fileType);

                    this.uploading = true;
                    try {
                        const res = await axios.post('FAC_List.aspx?action=uploadfile', formData, {
                            headers: { 'Content-Type': 'multipart/form-data' }
                        });
                        if (res.data && res.data.Success) {
                            alert(res.data.Message || '檔案上傳成功！');
                            fileInput.value = '';
                            // 重新整理檔案清單
                            const fileRes = await axios.get(`FAC_List.aspx?action=getfiles&facId=${this.activeItem.FAC_ID}`);
                            if (fileRes.data && fileRes.data.Success) {
                                this.fileList = fileRes.data.Files || [];
                            }
                        } else {
                            alert(res.data.Message || '上傳失敗');
                        }
                    } catch (e) {
                        console.error('上傳錯誤:', e);
                        alert('上傳失敗，請檢查檔案格式與大小');
                    } finally {
                        this.uploading = false;
                    }
                },

                // 15. 刪除圖資檔案
                async deleteFile(fileName) {
                    if (!confirm(`確定要刪除圖資檔案「${fileName}」嗎？`)) return;

                    try {
                        const res = await axios.get(`FAC_List.aspx?action=delfile&facId=${this.activeItem.FAC_ID}&fileName=${encodeURIComponent(fileName)}`);
                        if (res.data && res.data.Success) {
                            alert('圖資檔案已成功刪除');
                            const fileRes = await axios.get(`FAC_List.aspx?action=getfiles&facId=${this.activeItem.FAC_ID}`);
                            if (fileRes.data && fileRes.data.Success) {
                                this.fileList = fileRes.data.Files || [];
                            }
                        } else {
                            alert(res.data.Message || '刪除失敗');
                        }
                    } catch (e) {
                        alert('刪除失敗');
                    }
                },

                // 16. 開啟資料異動編輯彈窗
                openEditModal(item) {
                    this.activeItem = item;
                    this.editForm = {
                        facId: item.FAC_ID,
                        facName: item.FAC_NAME,
                        cNo: item.C_NO,
                        scId: item.S_C_ID,
                        addr: item.ADDR,
                        tel: item.TEL,
                        contentName: item.Content_Name
                    };
                    this.showEditModal = true;
                },

                // 17. 儲存場所基本資料異動
                async submitEdit() {
                    if (!this.editForm.facName.trim()) {
                        alert('請填寫場所名稱！');
                        return;
                    }

                    this.savingEdit = true;
                    try {
                        const res = await axios.post('FAC_List.aspx?action=saveedit', this.editForm);
                        if (res.data && res.data.Success) {
                            alert(res.data.Message || '異動已儲存成功！');
                            this.showEditModal = false;
                            this.loadCounts();
                            this.doSearch();
                        } else {
                            alert(res.data.Message || '儲存失敗');
                        }
                    } catch (e) {
                        console.error('儲存異動失敗:', e);
                        alert('儲存失敗');
                    } finally {
                        this.savingEdit = false;
                    }
                },

                // 18. 開啟異動歷程軌跡彈窗
                async openHistoryModal(item) {
                    this.activeItem = item;
                    this.historyList = [];
                    this.showHistoryModal = true;

                    try {
                        const res = await axios.get(`FAC_List.aspx?action=gethistory&facId=${item.FAC_ID}`);
                        if (res.data && res.data.Success) {
                            this.historyList = res.data.History || [];
                        }
                    } catch (e) {
                        console.error('載入歷程失敗:', e);
                    }
                },

                // 19. 新增場所
                async addNewFac() {
                    if (!confirm('是否確定建立一筆新場所資料？')) return;

                    try {
                        const res = await axios.get('FAC_List.aspx?action=addfac');
                        if (res.data && res.data.Success) {
                            alert(`新場所建立成功！案號：${res.data.FacId}`);
                            this.loadCounts();
                            this.doSearch();
                        } else {
                            alert(res.data.Message || '建立失敗');
                        }
                    } catch (e) {
                        alert('建立失敗');
                    }
                },

                // 20. 確定派遣彈窗與送出
                openDispatchModal() {
                    if (this.selectedFacIds.length === 0) {
                        alert('請先勾選欲派遣之公私場所！');
                        return;
                    }
                    this.dispatchReason = '一般派遣';
                    this.showDispatchModal = true;
                },
                async submitDispatch() {
                    this.dispatching = true;
                    try {
                        const payload = {
                            Reason: this.dispatchReason,
                            FacIds: this.selectedFacIds
                        };
                        const res = await axios.post('FAC_List.aspx?action=dispatchmission', payload);
                        if (res.data && res.data.Success) {
                            alert(res.data.Message || '派遣指派成功！');
                            this.showDispatchModal = false;
                            this.selectedFacIds = [];
                            this.loadCounts();
                            this.doSearch();
                        } else {
                            alert(res.data.Message || '派遣失敗');
                        }
                    } catch (e) {
                        console.error('派遣指派錯誤:', e);
                        alert('派遣指派失敗');
                    } finally {
                        this.dispatching = false;
                    }
                }
            }
        }).mount('#app');
    </script>
</body>
</html>
