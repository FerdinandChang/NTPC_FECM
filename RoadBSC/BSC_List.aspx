<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="BSC_List.aspx.cs" Inherits="NTPC_FEC.RoadBSC.BSC_List" %>

<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定溢散源管理平台 - 人行道與交通島裸露覆土管理清單</title>

    <!-- 專屬 Favicon -->
    <link rel="shortcut icon" href="../favicon.ico" type="image/x-icon" />

    <!-- Bootstrap 4 & FontAwesome 本地化樣式 -->
    <link rel="stylesheet" href="../Content/bootstrap.min.css" />
    <link rel="stylesheet" href="../Content/fontawesome/css/all.min.css" />

    <style>
        :root {
            --brand-primary: #0099e5;
            --brand-navy: #0f172a;
            --brand-blue: #0284c7;
            --brand-dark-blue: #0b1f7d;
            --bg-canvas: #f8fafc;
            --surface: #ffffff;
            --border-color: #e2e8f0;
            --text-main: #0f172a;
            --text-muted: #64748b;
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
            padding: 2px 7px;
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

        /* 頂部統計指標卡片 */
        .stat-card {
            background: #ffffff;
            border-radius: 10px;
            border: 1px solid var(--border-color);
            padding: 14px 18px;
            display: flex;
            align-items: center;
            gap: 14px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.03);
            transition: transform 0.15s ease;
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
            font-size: 1.3rem;
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

        /* 評級晶片 Badge - 嚴格單行不換行 */
        .score-badge {
            display: inline-flex;
            align-items: center;
            gap: 5px;
            padding: 4px 10px;
            border-radius: 6px;
            font-weight: 700;
            font-size: 13px;
            white-space: nowrap !important;
            flex-shrink: 0;
        }

        .score-a {
            background: #ecfdf5;
            color: #047857;
            border: 1px solid #10b981;
        }

        .score-b {
            background: #fffbeb;
            color: #b45309;
            border: 1px solid #f59e0b;
        }

        .score-c {
            background: #fef2f2;
            color: #b91c1c;
            border: 1px solid #ef4444;
        }

        .score-none {
            background: #f1f5f9;
            color: #64748b;
            border: 1px solid #cbd5e1;
        }

        /* 行政區晶片 */
        .town-chip {
            background: #e0f2fe;
            color: #0369a1;
            padding: 3px 8px;
            border-radius: 6px;
            font-size: 12px;
            font-weight: 700;
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

        /* 操作按鈕群組 - 嚴格單行排列不換行 */
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

        /* 快速預覽 Modal */
        .modal-mask {
            position: fixed;
            top: 0; left: 0; right: 0; bottom: 0;
            background: rgba(15, 23, 42, 0.65);
            z-index: 2000;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }

        .modal-content-custom {
            background: #ffffff;
            border-radius: 12px;
            max-width: 600px;
            width: 100%;
            overflow: hidden;
            box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.2);
            animation: modalFadeIn 0.2s ease;
        }

        @keyframes modalFadeIn {
            from { opacity: 0; transform: scale(0.95); }
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
            max-height: 75vh;
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
    </style>
</head>
<body>
    <div id="listApp" v-cloak>
        <!-- 頂部品牌導覽列 -->
                <!-- 頂部品牌導覽列 (全站標準左側導航、右側主操作) -->
        <header class="top-navbar">
            <div class="d-flex align-items-center">
                <a href="../MainPage.aspx?sub=menu4" class="nav-btn mr-2" title="返回主選單">
                    <i class="fas fa-home"></i>
                    <span class="d-none d-sm-inline">回首頁</span>
                </a>
                <a href="BSC_List.aspx" class="navbar-brand-title">
                    <i class="fas fa-seedling text-white"></i>
                    <span>車行路段翻轉空污防制管理</span>
                </a>
            </div>
            <div class="d-flex align-items-center gap-2">
                <a href="NewBSC.aspx?mode=new" class="btn btn-success btn-sm font-weight-bold shadow-sm mr-2">
                    <i class="fas fa-plus-circle mr-1"></i>
                    <span class="d-none d-sm-inline">新增路段巡查</span>
                </a>
            </div>
        </header>

        <!-- 業務模式分頁切換列 -->
        <nav class="nav-mode-bar">
            <div class="nav-mode-item" :class="{ 'active': currentMode === 'BSCEdit' }" v-on:click="switchMode('BSCEdit')">
                <i class="fas fa-edit"></i>
                <span>待通報派工案件</span>
                <span class="tab-badge badge badge-warning text-dark">{{ counts.BSCEdit }}</span>
            </div>
            <div class="nav-mode-item" :class="{ 'active': currentMode === 'BSCImprove' }" v-on:click="switchMode('BSCImprove')">
                <i class="fas fa-tools"></i>
                <span>待回報改善案件</span>
                <span class="tab-badge badge badge-primary">{{ counts.BSCImprove }}</span>
            </div>
            <div class="nav-mode-item" :class="{ 'active': currentMode === 'Finish' }" v-on:click="switchMode('Finish')">
                <i class="fas fa-check-circle"></i>
                <span>已改善結案案件</span>
                <span class="tab-badge badge badge-success">{{ counts.Finish }}</span>
            </div>
            <div class="nav-mode-item" :class="{ 'active': currentMode === 'Total' }" v-on:click="switchMode('Total')">
                <i class="fas fa-layer-group"></i>
                <span>全部案件一覽</span>
                <span class="tab-badge badge badge-dark">{{ counts.Total }}</span>
            </div>
        </nav>

        <main class="container-fluid py-4 px-lg-4">
            <!-- 頂部統計指標卡片 -->
            <div class="row mb-3">
                <div class="col-6 col-lg-3 mb-2 mb-lg-0">
                    <div class="stat-card" v-on:click="switchMode('BSCEdit')" style="cursor: pointer;">
                        <div class="stat-icon bg-warning text-dark">
                            <i class="fas fa-clipboard-list"></i>
                        </div>
                        <div>
                            <div class="stat-val text-warning">{{ counts.BSCEdit }}</div>
                            <div class="stat-label">待通報派工案件</div>
                        </div>
                    </div>
                </div>
                <div class="col-6 col-lg-3 mb-2 mb-lg-0">
                    <div class="stat-card" v-on:click="switchMode('BSCImprove')" style="cursor: pointer;">
                        <div class="stat-icon bg-primary text-white">
                            <i class="fas fa-tools"></i>
                        </div>
                        <div>
                            <div class="stat-val text-primary">{{ counts.BSCImprove }}</div>
                            <div class="stat-label">待改善處理案件</div>
                        </div>
                    </div>
                </div>
                <div class="col-6 col-lg-3 mb-2 mb-lg-0">
                    <div class="stat-card" v-on:click="switchMode('Finish')" style="cursor: pointer;">
                        <div class="stat-icon bg-success text-white">
                            <i class="fas fa-check-double"></i>
                        </div>
                        <div>
                            <div class="stat-val text-success">{{ counts.Finish }}</div>
                            <div class="stat-label">已改善結案</div>
                        </div>
                    </div>
                </div>
                <div class="col-6 col-lg-3 mb-2 mb-lg-0">
                    <div class="stat-card" v-on:click="switchMode('Total')" style="cursor: pointer;">
                        <div class="stat-icon bg-light text-secondary">
                            <i class="fas fa-database"></i>
                        </div>
                        <div>
                            <div class="stat-val">{{ counts.Total }}</div>
                            <div class="stat-label">通報案件總數</div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- 查詢篩選卡片 -->
            <div class="card-modern">
                <div class="card-modern-header">
                    <h2 class="card-modern-title">
                        <i class="fas fa-filter text-primary"></i>
                        <span>案件條件篩選</span>
                    </h2>
                    <div class="d-flex align-items-center gap-2">
                        <button type="button" class="btn btn-sm btn-outline-secondary font-weight-bold" v-on:click="resetFilter">
                            <i class="fas fa-redo-alt mr-1"></i> 重設條件
                        </button>
                    </div>
                </div>
                <div class="card-modern-body">
                    <div class="row">
                        <!-- 行政區篩選 -->
                        <div class="col-12 col-md-3 mb-3">
                            <label class="font-weight-bold text-muted small mb-1">
                                <i class="fas fa-map-marker-alt text-danger mr-1"></i> 行政區
                            </label>
                            <select class="form-control" v-model="filter.TownCode" style="font-weight: 600;">
                                <option value="">全部行政區 ({{ towns.length }} 區)</option>
                                <option v-for="t in towns" :key="t.TownNo" :value="t.TownNo">
                                    {{ t.TownName }}
                                </option>
                            </select>
                        </div>

                        <!-- 道路名稱關鍵字 -->
                        <div class="col-12 col-md-3 mb-3">
                            <label class="font-weight-bold text-muted small mb-1">
                                <i class="fas fa-road text-info mr-1"></i> 道路名稱
                            </label>
                            <input type="text" class="form-control" v-model="filter.RoadName" placeholder="例如：文化路、新北大道..." v-on:keyup.enter="handleSearch" />
                        </div>

                        <!-- 通報案號關鍵字 -->
                        <div class="col-12 col-md-3 mb-3">
                            <label class="font-weight-bold text-muted small mb-1">
                                <i class="fas fa-hashtag text-primary mr-1"></i> 通報案號
                            </label>
                            <input type="text" class="form-control" v-model="filter.SearchId" placeholder="搜尋案號..." v-on:keyup.enter="handleSearch" />
                        </div>

                        <!-- 處理單位 -->
                        <div class="col-12 col-md-3 mb-3">
                            <label class="font-weight-bold text-muted small mb-1">
                                <i class="fas fa-building text-warning mr-1"></i> 處理單位
                            </label>
                            <select class="form-control" v-model="filter.UnitId" style="font-weight: 600;">
                                <option value="">全部處理單位</option>
                                <option v-for="u in units" :key="u.UnitId" :value="u.UnitId">
                                    {{ u.UnitName }}
                                </option>
                            </select>
                        </div>

                        <!-- 日期區間 -->
                        <div class="col-12 col-md-6 mb-3">
                            <label class="font-weight-bold text-muted small mb-1">
                                <i class="far fa-calendar-alt text-primary mr-1"></i> {{ getDateFilterLabel() }}
                            </label>
                            <div class="d-flex align-items-center" style="width: 100%;">
                                <input type="date" class="form-control" style="flex: 1; min-width: 0;" v-model="filter.DateS" />
                                <span class="mx-2 text-muted font-weight-bold">~</span>
                                <input type="date" class="form-control" style="flex: 1; min-width: 0;" v-model="filter.DateE" />
                            </div>
                        </div>

                        <!-- 日期快捷選項 -->
                        <div class="col-12 col-md-6 mb-3 d-flex flex-column justify-content-end">
                            <label class="font-weight-bold text-muted small mb-1">快速選取區間</label>
                            <div class="btn-group btn-group-sm" role="group">
                                <button type="button" class="btn btn-outline-secondary" v-on:click="setDateShortcut('all')">不限日期</button>
                                <button type="button" class="btn btn-outline-secondary" v-on:click="setDateShortcut('today')">今天</button>
                                <button type="button" class="btn btn-outline-secondary" v-on:click="setDateShortcut('week')">近 7 天</button>
                                <button type="button" class="btn btn-outline-secondary" v-on:click="setDateShortcut('month')">近 1 個月</button>
                                <button type="button" class="btn btn-outline-secondary" v-on:click="setDateShortcut('quarter')">近 3 個月</button>
                            </div>
                        </div>
                    </div>

                    <!-- 動作執行列 -->
                    <div class="d-flex flex-wrap align-items-center justify-content-between pt-2 border-top">
                        <div class="small text-muted font-weight-bold">
                            <i class="fas fa-info-circle mr-1 text-info"></i>
                            點擊案件之案號或操作按鈕可查看歷程紀錄與現場佐證照片。
                        </div>
                        <button type="button" class="btn btn-primary px-4 font-weight-bold shadow-sm" :disabled="loading" v-on:click="handleSearch">
                            <i class="fas fa-search mr-1"></i>
                            <span v-if="!loading">查詢資料</span>
                            <span v-else>查詢中...</span>
                        </button>
                    </div>
                </div>
            </div>

            <!-- 案件列表主要卡片 -->
            <div class="card-modern">
                <div class="card-modern-header">
                    <h2 class="card-modern-title">
                        <i class="fas fa-list-ul text-primary"></i>
                        <span>{{ getModeTitle() }}</span>
                        <span class="badge badge-pill badge-light border text-muted ml-2 font-weight-bold" style="font-size: 12px;">
                            共 {{ totalCount }} 筆紀錄
                        </span>
                    </h2>
                    <div class="d-flex align-items-center gap-2">
                        <button type="button" class="btn btn-sm btn-outline-success font-weight-bold" v-on:click="exportExcel" :disabled="loading || totalCount === 0" title="匯出當前篩選案件為 EXCEL">
                            <i class="fas fa-file-excel mr-1"></i> 匯出 EXCEL
                        </button>
                        <button type="button" class="btn btn-sm btn-light border font-weight-bold" v-on:click="loadList" title="重新整理">
                            <i class="fas fa-sync-alt" :class="{ 'fa-spin': loading }"></i>
                        </button>
                    </div>
                </div>

                <div class="p-0">
                    <!-- 載入中骨架 -->
                    <div v-if="loading" class="text-center py-5">
                        <div class="spinner-border text-primary" role="status">
                            <span class="sr-only">載入中...</span>
                        </div>
                        <div class="mt-2 text-muted font-weight-bold">資料極速載入中，請稍候...</div>
                    </div>

                    <!-- 查無資料 Empty State -->
                    <div v-else-if="list.length === 0" class="text-center py-5">
                        <div class="mb-3 text-muted" style="font-size: 3rem;">
                            <i class="far fa-folder-open"></i>
                        </div>
                        <h5 class="font-weight-bold text-secondary">查無符合條件的通報案件</h5>
                        <p class="text-muted small">請嘗試放寬篩選條件或點選「不限日期」。</p>
                        <a href="NewBSC.aspx?mode=new" class="btn btn-primary font-weight-bold px-4 mt-2">
                            <i class="fas fa-plus mr-1"></i> 建立第一筆現場通報
                        </a>
                    </div>

                    <!-- 寬螢幕桌面端表格 (Desktop & Tablet) -->
                    <div v-else class="table-responsive d-none d-md-block">
                        <table class="table-modern">
                            <thead>
                                <tr>
                                    <th style="width: 170px;">通報案號</th>
                                    <th style="width: 90px;">行政區</th>
                                    <th style="width: 170px; min-width: 140px;">通報道路</th>
                                    <th style="width: 150px;">查核時間</th>
                                    <th style="width: 155px; white-space: nowrap;">鋪面平整度</th>
                                    <th style="width: 175px; white-space: nowrap;">覆土裸露狀況</th>
                                    <th style="width: 110px;">佐證照片</th>
                                    <th style="width: 110px;">案件階段</th>
                                    <th style="min-width: 200px; width: 200px; white-space: nowrap;" class="text-center">操作功能</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr v-for="item in list" :key="item.BSC_ID">
                                    <!-- 通報案號 -->
                                    <td>
                                        <a :href="item.DetailUrl || ('BSCDetail.aspx?id=' + item.BSC_ID + '&parmode=' + currentMode)" class="font-weight-bold text-primary" title="檢視案件詳細資料">
                                            {{ item.Show_ID }}
                                        </a>
                                        <div class="text-muted font-size-xs" v-if="item.Memo">
                                            <i class="fas fa-sticky-note text-warning mr-1"></i>
                                            {{ truncateText(item.Memo, 20) }}
                                        </div>
                                    </td>

                                    <!-- 行政區 -->
                                    <td>
                                        <span class="town-chip">{{ item.TownName }}</span>
                                    </td>

                                    <!-- 通報道路 -->
                                    <td>
                                        <div class="font-weight-bold text-dark" style="font-size: 15px;">{{ item.ROAD_Name }}</div>
                                        <span class="badge badge-light border text-muted small">{{ item.ROAD_LV }}</span>
                                    </td>

                                    <!-- 查核時間 -->
                                    <td>
                                        <div class="small font-weight-bold text-secondary">{{ item.Report_Date }}</div>
                                        <small class="text-muted">查核員: {{ item.Report_UserName || '未登錄' }}</small>
                                    </td>

                                    <!-- 鋪面平整度評級 -->
                                    <td style="white-space: nowrap;">
                                        <span class="score-badge" :class="getSmoothScoreClass(item.Smooth)">
                                            <i :class="getSmoothIcon(item.Smooth)"></i>
                                            <span>{{ item.SmoothName }}</span>
                                        </span>
                                    </td>

                                    <!-- 覆土狀況評級 -->
                                    <td style="white-space: nowrap;">
                                        <span class="score-badge" :class="getCoverSoilScoreClass(item.Cover_Soil)">
                                            <i :class="getCoverSoilIcon(item.Cover_Soil)"></i>
                                            <span>{{ item.CoverSoilName }}</span>
                                        </span>
                                    </td>

                                    <!-- 佐證照片 -->
                                    <td>
                                        <span v-if="item.PhotoCount > 0" class="badge badge-light border text-primary font-weight-bold px-2 py-1" style="font-size: 12px;">
                                            <i class="fas fa-camera mr-1"></i> {{ item.PhotoCount }} 張
                                        </span>
                                        <span v-else class="text-muted small">無照片</span>
                                    </td>

                                    <!-- 案件階段狀態 -->
                                    <td>
                                        <span v-if="!item.IsSetCom" class="badge badge-warning text-dark px-2 py-1 font-weight-bold" style="font-size: 12px;">
                                            待派工通報
                                        </span>
                                        <span v-else-if="item.IsSetCom && !item.IsImproved" class="badge badge-primary px-2 py-1 font-weight-bold" style="font-size: 12px;">
                                            待回報改善
                                        </span>
                                        <span v-else class="badge badge-success px-2 py-1 font-weight-bold" style="font-size: 12px;">
                                            已改善結案
                                        </span>
                                        <div v-if="item.G_COM_NAME" class="small text-muted font-weight-bold mt-1" :title="item.G_COM_NAME">
                                            <i class="fas fa-building mr-1"></i>{{ truncateText(item.G_COM_NAME, 8) }}
                                        </div>
                                    </td>

                                    <!-- 功能按鈕 -->
                                    <td class="text-center" style="white-space: nowrap;">
                                        <div class="action-btn-group justify-content-center">
                                            <!-- 待派工階段 (未通報) -->
                                            <template v-if="!item.IsSetCom">
                                                <a :href="item.EditUrl || ('NewBSC.aspx?mode=edit&id=' + item.BSC_ID)" class="btn btn-sm btn-warning btn-action text-dark font-weight-bold" title="編輯修改">
                                                    <i class="fas fa-pencil-alt"></i> 編輯
                                                </a>
                                                <a :href="item.SetSGUrl || ('SetSG_BSC.aspx?id=' + item.BSC_ID)" class="btn btn-sm btn-primary btn-action font-weight-bold shadow-sm" title="通報派工">
                                                    <i class="fas fa-paper-plane"></i> 派工
                                                </a>
                                                <a :href="item.DetailUrl || ('BSCDetail.aspx?id=' + item.BSC_ID + '&parmode=' + currentMode)" class="btn btn-sm btn-info btn-action font-weight-bold" title="檢視詳細">
                                                    <i class="fas fa-eye"></i> 檢視
                                                </a>
                                                <button type="button" class="btn btn-sm btn-outline-danger btn-action" v-on:click="deleteCase(item.BSC_ID)" title="刪除案件">
                                                    <i class="fas fa-trash-alt"></i>
                                                </button>
                                            </template>

                                            <!-- 待改善處理階段 -->
                                            <template v-else-if="item.IsSetCom && !item.IsImproved">
                                                <a :href="item.ImproveUrl || ('ImproveBSC.aspx?id=' + item.BSC_ID)" class="btn btn-sm btn-success btn-action font-weight-bold shadow-sm" title="填寫改善處理結果">
                                                    <i class="fas fa-wrench"></i> 回報改善
                                                </a>
                                                <a :href="item.DetailUrl || ('BSCDetail.aspx?id=' + item.BSC_ID + '&parmode=' + currentMode)" class="btn btn-sm btn-info btn-action font-weight-bold" title="檢視詳細">
                                                    <i class="fas fa-eye"></i> 檢視
                                                </a>
                                            </template>

                                            <!-- 已結案 -->
                                            <template v-else>
                                                <a :href="item.DetailUrl || ('BSCDetail.aspx?id=' + item.BSC_ID + '&parmode=' + currentMode)" class="btn btn-sm btn-info btn-action font-weight-bold" title="檢視詳細資料">
                                                    <i class="fas fa-eye"></i> 檢視
                                                </a>
                                            </template>
                                        </div>
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>

                    <!-- 手機端自適應卡片清單 (Mobile Cards) -->
                    <div class="d-block d-md-none p-3">
                        <div v-for="item in list" :key="item.BSC_ID" class="mobile-card">
                            <div class="mobile-card-header">
                                <div class="d-flex align-items-center gap-2">
                                    <span class="town-chip">{{ item.TownName }}</span>
                                    <span class="font-weight-bold text-dark">{{ item.Show_ID }}</span>
                                </div>
                                <span v-if="!item.IsSetCom" class="badge badge-warning text-dark px-2 py-1 font-weight-bold">
                                    待派工
                                </span>
                                <span v-else-if="item.IsSetCom && !item.IsImproved" class="badge badge-primary px-2 py-1 font-weight-bold">
                                    待改善
                                </span>
                                <span v-else class="badge badge-success px-2 py-1 font-weight-bold">
                                    已結案
                                </span>
                            </div>

                            <h3 class="mobile-card-title mb-2">{{ item.ROAD_Name }}</h3>
                            <div class="small text-muted mb-2">
                                <i class="far fa-clock mr-1"></i> {{ item.Report_Date }}
                                <span class="ml-2"><i class="fas fa-user-edit mr-1"></i> {{ item.Report_UserName }}</span>
                            </div>

                            <!-- 評級晶片與佐證照片 -->
                            <div class="d-flex flex-wrap gap-2 mb-3">
                                <span class="score-badge" :class="getSmoothScoreClass(item.Smooth)">
                                    <i :class="getSmoothIcon(item.Smooth)"></i>
                                    平整: {{ item.SmoothName }}
                                </span>
                                <span class="score-badge" :class="getCoverSoilScoreClass(item.Cover_Soil)">
                                    <i :class="getCoverSoilIcon(item.Cover_Soil)"></i>
                                    覆土: {{ item.CoverSoilName }}
                                </span>
                                <span v-if="item.PhotoCount > 0" class="badge badge-light border text-primary font-weight-bold px-2 py-1">
                                    <i class="fas fa-camera mr-1"></i> {{ item.PhotoCount }} 照片
                                </span>
                            </div>

                            <!-- 補充說明提示 -->
                            <div v-if="item.Memo" class="alert alert-light border py-2 px-3 small font-weight-bold mb-3 text-secondary">
                                <i class="fas fa-info-circle mr-1 text-info"></i> 補充說明：{{ item.Memo }}
                            </div>

                            <!-- 手機動作按鈕列 -->
                            <div class="action-btn-group pt-2 border-top">
                                <template v-if="!item.IsSetCom">
                                    <a :href="item.EditUrl || ('NewBSC.aspx?mode=edit&id=' + item.BSC_ID)" class="btn btn-warning btn-action text-dark font-weight-bold">
                                        <i class="fas fa-pencil-alt"></i> 編輯
                                    </a>
                                    <a :href="item.SetSGUrl || ('SetSG_BSC.aspx?id=' + item.BSC_ID)" class="btn btn-primary btn-action font-weight-bold">
                                        <i class="fas fa-paper-plane"></i> 派工
                                    </a>
                                    <a :href="item.DetailUrl || ('BSCDetail.aspx?id=' + item.BSC_ID + '&parmode=' + currentMode)" class="btn btn-info btn-action font-weight-bold">
                                        <i class="fas fa-eye"></i> 檢視
                                    </a>
                                    <button type="button" class="btn btn-outline-danger btn-action" v-on:click="deleteCase(item.BSC_ID)">
                                        <i class="fas fa-trash-alt"></i> 刪除
                                    </button>
                                </template>
                                <template v-else-if="item.IsSetCom && !item.IsImproved">
                                    <a :href="item.ImproveUrl || ('ImproveBSC.aspx?id=' + item.BSC_ID)" class="btn btn-success btn-action font-weight-bold shadow-sm">
                                        <i class="fas fa-wrench"></i> 回報改善
                                    </a>
                                    <a :href="item.DetailUrl || ('BSCDetail.aspx?id=' + item.BSC_ID + '&parmode=' + currentMode)" class="btn btn-info btn-action font-weight-bold">
                                        <i class="fas fa-eye"></i> 檢視
                                    </a>
                                </template>
                                <template v-else>
                                    <a :href="item.DetailUrl || ('BSCDetail.aspx?id=' + item.BSC_ID + '&parmode=' + currentMode)" class="btn btn-info btn-action font-weight-bold">
                                        <i class="fas fa-eye"></i> 檢視
                                    </a>
                                </template>
                            </div>
                        </div>
                    </div>

                    <!-- 自適應底部分頁導覽列 (Responsive Pagination Footer) -->
                    <div v-if="!loading && totalCount > 0" class="pagination-footer">
                        <div class="pagination-footer-info">
                            顯示第 <strong class="text-dark">{{ (pageIndex - 1) * pageSize + 1 }}</strong> 至 <strong class="text-dark">{{ Math.min(pageIndex * pageSize, totalCount) }}</strong> 筆，共 <strong class="text-dark">{{ totalCount }}</strong> 筆
                        </div>
                        <div class="pagination-action-group">
                            <button type="button" class="btn-page-ctrl btn-edge" :disabled="pageIndex <= 1" v-on:click="gotoPage(1)" title="第一頁">
                                <i class="fas fa-angle-double-left"></i>
                                <span class="d-none d-md-inline ml-1">首頁</span>
                            </button>
                            <button type="button" class="btn-page-ctrl btn-step" :disabled="pageIndex <= 1" v-on:click="gotoPage(pageIndex - 1)" title="上一頁">
                                <i class="fas fa-chevron-left mr-1"></i>
                                <span>上一頁</span>
                            </button>
                            <div class="page-indicator-pill" title="目前頁次 / 總頁數">
                                <span>{{ pageIndex }}</span>
                                <span class="mx-1 text-muted" style="opacity: 0.5; font-weight: normal;">/</span>
                                <span>{{ totalPages }}</span>
                            </div>
                            <button type="button" class="btn-page-ctrl btn-step" :disabled="pageIndex >= totalPages" v-on:click="gotoPage(pageIndex + 1)" title="下一頁">
                                <span>下一頁</span>
                                <i class="fas fa-chevron-right ml-1"></i>
                            </button>
                            <button type="button" class="btn-page-ctrl btn-edge" :disabled="pageIndex >= totalPages" v-on:click="gotoPage(totalPages)" title="最後一頁">
                                <span class="d-none d-md-inline ml-1">末頁</span>
                                <i class="fas fa-angle-double-right"></i>
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </main>
    </div>

    <!-- 本地化核心腳本庫 -->
    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>

    <script>
        const { createApp, ref, reactive, computed, onMounted } = Vue;

        const app = createApp({
            setup() {
                const urlParams = new URLSearchParams(window.location.search);
                const queryMode = urlParams.get('mode') || 'BSCEdit';

                const currentMode = ref(queryMode);
                const loading = ref(false);

                // 下拉選單資料
                const towns = ref([]);
                const units = ref([]);

                // 案件各階段計數
                const counts = reactive({
                    BSCEdit: 0,
                    BSCImprove: 0,
                    Finish: 0,
                    Total: 0
                });

                // 篩選模型
                const filter = reactive({
                    Mode: queryMode,
                    SearchId: '',
                    TownCode: '',
                    RoadName: '',
                    UnitId: '',
                    DateS: '',
                    DateE: ''
                });

                // 列表與分頁
                const list = ref([]);
                const totalCount = ref(0);
                const pageIndex = ref(1);
                const pageSize = ref(20);
                const totalPages = ref(1);

                // 取得業務頁籤標題
                const getModeTitle = () => {
                    switch (currentMode.value) {
                        case 'BSCEdit': return '待通報派工案件維護 (未通報)';
                        case 'BSCImprove': return '待回報改善處理案件 (處理中)';
                        case 'Finish': return '已改善結案案件列表';
                        case 'Total': return '全部通報案件成果一覽';
                        default: return '通報案件列表';
                    }
                };

                // 取得日期篩選名稱
                const getDateFilterLabel = () => {
                    switch (currentMode.value) {
                        case 'BSCEdit': return '查核日期區間';
                        case 'BSCImprove': return '通報派工日期區間';
                        case 'Finish': return '改善完成日期區間';
                        default: return '查核日期區間';
                    }
                };

                // 文字長度截斷
                const truncateText = (str, len) => {
                    if (!str) return '';
                    return str.length > len ? str.substring(0, len) + '...' : str;
                };

                // 平整度標籤樣式與圖標
                const getSmoothScoreClass = (code) => {
                    if (code === '1') return 'score-a';
                    if (code === '2') return 'score-b';
                    if (code === '3' || code === '4') return 'score-c';
                    return 'score-none';
                };

                const getSmoothIcon = (code) => {
                    if (code === '1') return 'fas fa-check-circle text-success';
                    if (code === '2') return 'fas fa-exclamation-triangle text-warning';
                    return 'fas fa-times-circle text-danger';
                };

                // 覆土狀況標籤樣式與圖標
                const getCoverSoilScoreClass = (code) => {
                    if (code === '1') return 'score-a';
                    if (code === '2') return 'score-b';
                    if (code === '3' || code === '4') return 'score-c';
                    return 'score-none';
                };

                const getCoverSoilIcon = (code) => {
                    if (code === '1') return 'fas fa-leaf text-success';
                    if (code === '2') return 'fas fa-mountain text-warning';
                    return 'fas fa-exclamation-circle text-danger';
                };

                // 切換業務模式
                const switchMode = (mode) => {
                    currentMode.value = mode;
                    filter.Mode = mode;
                    pageIndex.value = 1;

                    const newUrl = `${window.location.pathname}?mode=${mode}`;
                    window.history.pushState({ path: newUrl }, '', newUrl);

                    loadList();
                };

                // 快捷日期設定
                const setDateShortcut = (type) => {
                    const now = new Date();
                    const formatDate = (d) => {
                        const year = d.getFullYear();
                        const month = String(d.getMonth() + 1).padStart(2, '0');
                        const day = String(d.getDate()).padStart(2, '0');
                        return `${year}-${month}-${day}`;
                    };

                    if (type === 'all') {
                        filter.DateS = '';
                        filter.DateE = '';
                    } else if (type === 'today') {
                        const todayStr = formatDate(now);
                        filter.DateS = todayStr;
                        filter.DateE = todayStr;
                    } else if (type === 'week') {
                        const past = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
                        filter.DateS = formatDate(past);
                        filter.DateE = formatDate(now);
                    } else if (type === 'month') {
                        const past = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
                        filter.DateS = formatDate(past);
                        filter.DateE = formatDate(now);
                    } else if (type === 'quarter') {
                        const past = new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000);
                        filter.DateS = formatDate(past);
                        filter.DateE = formatDate(now);
                    }
                };

                // 統一安全解析伺服器回應資料
                const parseResponseData = (res) => {
                    let d = res ? res.data : null;
                    if (typeof d === 'string') {
                        try {
                            d = JSON.parse(d);
                        } catch (e) {
                            return { Success: false, Message: '伺服器回應非預期資料格式（請確認連線狀態或重新登入）' };
                        }
                    }
                    return d || { Success: false, Message: '伺服器未回傳有效資料' };
                };

                // 載入初始選單資料
                const loadInitData = async () => {
                    try {
                        const res = await axios.get('BSC_List.aspx?action=getinit');
                        const data = parseResponseData(res);
                        if (data && data.Success) {
                            const d = data.Data;
                            towns.value = d.Towns || [];
                            units.value = d.Units || [];
                            Object.assign(counts, d.Counts || {});

                            if (!filter.DateS && !filter.DateE) {
                                filter.DateS = d.DefaultDateS || '';
                                filter.DateE = d.DefaultDateE || '';
                            }
                        } else {
                            console.warn('getinit 回應失敗：', data);
                        }
                    } catch (err) {
                        console.error('getinit 錯誤', err);
                    }
                };

                // 查詢案件列表
                const loadList = async () => {
                    loading.value = true;
                    try {
                        const params = {
                            action: 'getlist',
                            mode: filter.Mode,
                            searchId: filter.SearchId,
                            townCode: filter.TownCode,
                            roadName: filter.RoadName,
                            unitId: filter.UnitId,
                            dateS: filter.DateS,
                            dateE: filter.DateE,
                            pageIndex: pageIndex.value,
                            pageSize: pageSize.value,
                            _t: new Date().getTime()
                        };

                        const res = await axios.get('BSC_List.aspx', { params: params });
                        const data = parseResponseData(res);
                        if (data && data.Success) {
                            const d = data.Data;
                            list.value = d.Items || [];
                            totalCount.value = d.TotalRecords || 0;
                            totalPages.value = d.TotalPages || 1;
                            pageIndex.value = d.PageIndex || 1;
                        } else {
                            const errMsg = (data && data.Message) ? data.Message : '未知錯誤';
                            alert('查詢失敗：' + errMsg);
                        }
                    } catch (err) {
                        console.error('getlist 錯誤', err);
                        alert('載入清單發生錯誤：' + (err.message || '網路異常'));
                    } finally {
                        loading.value = false;
                    }
                };

                // 重新載入計數
                const reloadCounts = async () => {
                    try {
                        const res = await axios.get('BSC_List.aspx?action=getcounts');
                        const data = parseResponseData(res);
                        if (data && data.Success) {
                            Object.assign(counts, data.Data || {});
                        }
                    } catch (err) { }
                };

                // 執行查詢
                const handleSearch = () => {
                    pageIndex.value = 1;
                    loadList();
                    reloadCounts();
                };

                // 重設篩選
                const resetFilter = () => {
                    filter.SearchId = '';
                    filter.TownCode = '';
                    filter.RoadName = '';
                    filter.UnitId = '';
                    filter.DateS = '';
                    filter.DateE = '';
                    pageIndex.value = 1;
                    handleSearch();
                };

                // 匯出 EXCEL
                const exportExcel = () => {
                    const params = new URLSearchParams();
                    params.append('action', 'export');
                    params.append('mode', filter.Mode);
                    if (filter.SearchId) params.append('searchId', filter.SearchId);
                    if (filter.TownCode) params.append('townCode', filter.TownCode);
                    if (filter.RoadName) params.append('roadName', filter.RoadName);
                    if (filter.UnitId) params.append('unitId', filter.UnitId);
                    if (filter.DateS) params.append('dateS', filter.DateS);
                    if (filter.DateE) params.append('dateE', filter.DateE);

                    window.location.href = `BSC_List.aspx?${params.toString()}`;
                };
                const exportCsv = exportExcel;

                // 智慧分頁碼計算
                const visiblePages = computed(() => {
                    const total = totalPages.value;
                    const current = pageIndex.value;
                    if (total <= 7) {
                        return Array.from({ length: total }, (_, i) => i + 1);
                    }
                    const pages = [];
                    if (current <= 4) {
                        for (let i = 1; i <= 5; i++) pages.push(i);
                        pages.push('...');
                        pages.push(total);
                    } else if (current >= total - 3) {
                        pages.push(1);
                        pages.push('...');
                        for (let i = total - 4; i <= total; i++) pages.push(i);
                    } else {
                        pages.push(1);
                        pages.push('...');
                        for (let i = current - 1; i <= current + 1; i++) pages.push(i);
                        pages.push('...');
                        pages.push(total);
                    }
                    return pages;
                });

                // 跳頁
                const gotoPage = (p) => {
                    if (p < 1 || p > totalPages.value || p === pageIndex.value) return;
                    pageIndex.value = p;
                    loadList();
                };

                // 每頁顯示筆數切換
                const onPageSizeChange = () => {
                    pageIndex.value = 1;
                    loadList();
                };

                // 刪除案件
                const deleteCase = async (bscId) => {
                    if (!confirm(`確定要刪除通報單【${bscId}】嗎？此動作將同時清除所有佐證照片且無法復原！`)) {
                        return;
                    }
                    try {
                        const res = await axios.get(`BSC_List.aspx?action=delete&id=${bscId}`);
                        if (res.data && res.data.Success) {
                            alert(res.data.Message || '刪除成功！');
                            loadList();
                            reloadCounts();
                        } else {
                            alert('刪除失敗：' + (res.data ? res.data.Message : '未知錯誤'));
                        }
                    } catch (err) {
                        alert('刪除案件發生例外：' + err.message);
                    }
                };

                onMounted(async () => {
                    await loadInitData();
                    await loadList();
                });

                return {
                    currentMode,
                    loading,
                    towns,
                    units,
                    counts,
                    filter,
                    list,
                    totalCount,
                    pageIndex,
                    pageSize,
                    totalPages,
                    visiblePages,
                    getModeTitle,
                    getDateFilterLabel,
                    truncateText,
                    getSmoothScoreClass,
                    getSmoothIcon,
                    getCoverSoilScoreClass,
                    getCoverSoilIcon,
                    switchMode,
                    setDateShortcut,
                    handleSearch,
                    resetFilter,
                    exportExcel,
                    exportCsv,
                    gotoPage,
                    onPageSizeChange,
                    deleteCase,
                    loadList
                };
            }
        });

        app.mount('#listApp');
    </script>
</body>
</html>
