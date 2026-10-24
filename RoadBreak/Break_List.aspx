<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Break_List.aspx.cs" Inherits="NTPC_FEC.RoadBreak.Break_List" %>

<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定溢散源管理平台 - 道路破損案件清單</title>

    <!-- 專屬 Favicon -->
    <link rel="shortcut icon" href="../favicon.ico" type="image/x-icon" />

    <!-- Bootstrap 4 & FontAwesome 本地化樣式 -->
    <link rel="stylesheet" href="../Content/bootstrap.min.css" />
    <link rel="stylesheet" href="../Content/fontawesome/css/all.min.css" />

    <style>
        :root {
            --brand-primary: #0099e5;     /* 新北天空青藍 */
            --brand-navy: #0f172a;        /* 標題文字主色 */
            --brand-blue: #0284c7;        /* 科技藍 */
            --brand-dark-blue: #0b1f7d;   /* 海軍深藍 */
            --bg-canvas: #f8fafc;         /* 頁面灰底 */
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

        /* 頂部品牌導覽列 (比照 Clean_List.aspx 規格) */
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

        /* 業務模式分頁切換列 (比照 Clean_List.aspx 規格) */
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
            transition: transform 0.15s ease, box-shadow 0.15s ease;
            cursor: pointer;
        }

        .stat-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(15, 23, 42, 0.08);
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

        /* 評級晶片 (比照 Clean_List.aspx 規格，嚴格單行不換行) */
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
            background: #f0f9ff;
            color: #0369a1;
            border: 1px solid #0284c7;
        }

        .score-c {
            background: #fffbeb;
            color: #b45309;
            border: 1px solid #f59e0b;
        }

        .score-d {
            background: #fef2f2;
            color: #b91c1c;
            border: 1px solid #ef4444;
        }

        /* 行政區晶片 */
        .town-chip {
            background: #e0f2fe;
            color: #0369a1;
            padding: 3px 8px;
            border-radius: 6px;
            font-size: 12px;
            font-weight: 700;
            display: inline-block;
        }

        .road-lv-chip {
            background: #f1f5f9;
            color: #475569;
            padding: 2px 6px;
            border-radius: 4px;
            font-size: 11px;
            font-weight: 600;
            border: 1px solid #cbd5e1;
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
            text-decoration: none;
        }

        .btn-action:hover {
            text-decoration: none;
        }

        @media (max-width: 767.98px) {
            .btn-action {
                flex: 1;
                justify-content: center;
                min-height: 42px;
                font-size: 14px;
            }
        }

        /* 手機卡片清單 (Mobile Cards View) */
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

        /* 分頁列樣式 */
        .pagination-container {
            padding: 14px 20px;
            background: #ffffff;
            border-top: 1px solid var(--border-color);
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-wrap: wrap;
            gap: 12px;
        }

        .page-link-custom {
            min-width: 36px;
            height: 36px;
            padding: 0 10px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            border-radius: 6px;
            border: 1px solid var(--border-color);
            background: #ffffff;
            color: var(--text-main);
            font-weight: 600;
            font-size: 13px;
            cursor: pointer;
            transition: all 0.15s ease;
            user-select: none;
        }

        .page-link-custom:hover:not(.disabled) {
            background: #f1f5f9;
            color: var(--brand-blue);
            border-color: var(--brand-blue);
        }

        .page-link-custom.active {
            background: var(--brand-blue);
            color: #ffffff;
            border-color: var(--brand-blue);
            font-weight: 700;
        }

        .page-link-custom.disabled {
            opacity: 0.45;
            cursor: not-allowed;
        }

        /* 照片預覽彈窗樣式 */
        .photo-preview-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
            gap: 12px;
        }

        .photo-preview-thumb {
            width: 100%;
            height: 140px;
            object-fit: cover;
            border-radius: 8px;
            cursor: pointer;
            border: 1px solid var(--border-color);
            transition: transform 0.2s ease;
        }

        .photo-preview-thumb:hover {
            transform: scale(1.03);
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
        }

        .lightbox-overlay {
            position: fixed;
            top: 0; left: 0; right: 0; bottom: 0;
            background: rgba(0, 0, 0, 0.88);
            z-index: 2100;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }

        .lightbox-img {
            max-width: 95vw;
            max-height: 90vh;
            border-radius: 8px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.6);
        }
    </style>
</head>
<body>
    <div id="listApp" v-cloak>
        <!-- 頂部品牌導覽列 (比照 Clean_List.aspx 規格) -->
                <!-- 頂部品牌導覽列 (全站標準左側導航、右側主操作) -->
        <header class="top-navbar">
            <div class="d-flex align-items-center">
                <a href="../MainPage.aspx?sub=menu4" class="nav-btn mr-2" title="返回主選單">
                    <i class="fas fa-home"></i>
                    <span class="d-none d-sm-inline">回首頁</span>
                </a>
                <a href="Break_List.aspx" class="navbar-brand-title">
                    <i class="fas fa-road text-white"></i>
                    <span>道路破損巡查與通報管理</span>
                </a>
            </div>
            <div class="d-flex align-items-center gap-2">
                <a href="NewBreak.aspx?mode=new" class="btn btn-success btn-sm font-weight-bold shadow-sm mr-2">
                    <i class="fas fa-plus-circle mr-1"></i>
                    <span class="d-none d-sm-inline">新增破損巡查</span>
                </a>
            </div>
        </header>

        <!-- 業務模式分頁切換列 (比照 Clean_List.aspx 規格) -->
        <nav class="nav-mode-bar">
            <div class="nav-mode-item" :class="{ 'active': currentMode === 'BreakEdit' }" v-on:click="switchMode('BreakEdit')">
                <i class="fas fa-edit"></i>
                <span>查核紀錄暫存 (草稿)</span>
                <span class="tab-badge badge badge-secondary">{{ counts.BreakEdit || 0 }}</span>
            </div>
            <div class="nav-mode-item" :class="{ 'active': currentMode === 'BreakImprove' }" v-on:click="switchMode('BreakImprove')">
                <i class="fas fa-tools"></i>
                <span>破損改善回報 (處理中)</span>
                <span class="tab-badge badge badge-primary">{{ counts.BreakImprove || 0 }}</span>
            </div>
            <div class="nav-mode-item" :class="{ 'active': currentMode === 'Finish' }" v-on:click="switchMode('Finish')">
                <i class="fas fa-check-double"></i>
                <span>破損改善成果 (已完成)</span>
                <span class="tab-badge badge badge-success">{{ counts.Finish || 0 }}</span>
            </div>
            <div class="nav-mode-item" :class="{ 'active': currentMode === 'all' }" v-on:click="switchMode('all')">
                <i class="fas fa-layer-group"></i>
                <span>全部通報案件</span>
                <span class="tab-badge badge badge-dark">{{ counts.Total || 0 }}</span>
            </div>
        </nav>

        <main class="container-fluid py-4 px-lg-4">
            <!-- 提示訊息 -->
            <div v-if="alertMessage" class="alert alert-dismissible fade show shadow-sm" :class="'alert-' + alertType" role="alert">
                <i class="fas" :class="alertType === 'success' ? 'fa-check-circle' : 'fa-exclamation-triangle'"></i>
                <strong class="ml-1">{{ alertMessage }}</strong>
                <button type="button" class="close" v-on:click="alertMessage = ''">&times;</button>
            </div>

            <!-- 頂部統計指標卡片 (比照 Clean_List.aspx 規格) -->
            <div class="row mb-3">
                <div class="col-6 col-lg-3 mb-2 mb-lg-0">
                    <div class="stat-card" v-on:click="switchMode('BreakEdit')">
                        <div class="stat-icon bg-light text-secondary">
                            <i class="fas fa-file-signature"></i>
                        </div>
                        <div>
                            <div class="stat-val">{{ counts.BreakEdit || 0 }}</div>
                            <div class="stat-label">待通報暫存</div>
                        </div>
                    </div>
                </div>
                <div class="col-6 col-lg-3 mb-2 mb-lg-0">
                    <div class="stat-card" v-on:click="switchMode('BreakImprove')">
                        <div class="stat-icon bg-primary text-white">
                            <i class="fas fa-tools"></i>
                        </div>
                        <div>
                            <div class="stat-val text-primary">{{ counts.BreakImprove || 0 }}</div>
                            <div class="stat-label">改善處理中</div>
                        </div>
                    </div>
                </div>
                <div class="col-6 col-lg-3 mb-2 mb-lg-0">
                    <div class="stat-card" v-on:click="switchMode('Finish')">
                        <div class="stat-icon bg-success text-white">
                            <i class="fas fa-check-double"></i>
                        </div>
                        <div>
                            <div class="stat-val text-success">{{ counts.Finish || 0 }}</div>
                            <div class="stat-label">已改善結案</div>
                        </div>
                    </div>
                </div>
                <div class="col-6 col-lg-3 mb-2 mb-lg-0">
                    <div class="stat-card" v-on:click="switchMode('all')">
                        <div class="stat-icon bg-dark text-white">
                            <i class="fas fa-layer-group"></i>
                        </div>
                        <div>
                            <div class="stat-val text-dark">{{ counts.Total || 0 }}</div>
                            <div class="stat-label">總累計通報</div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- 查詢篩選卡片 (比照 Clean_List.aspx 規格) -->
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
                        <div class="col-12 col-md-4 mb-3">
                            <label class="font-weight-bold text-muted small mb-1">
                                <i class="fas fa-map-marker-alt text-danger mr-1"></i> 行政區
                            </label>
                            <select class="form-control" v-model="filter.TownCode" v-on:change="handleSearch" style="font-weight: 600;">
                                <option value="">全部行政區 ({{ towns.length }} 區)</option>
                                <option v-for="t in towns" :key="t.TownNo" :value="t.TownNo">
                                    {{ t.TownName }} ({{ t.TownNo }})
                                </option>
                            </select>
                        </div>

                        <!-- 道路名稱 / 案號關鍵字 -->
                        <div class="col-12 col-md-4 mb-3">
                            <label class="font-weight-bold text-muted small mb-1">
                                <i class="fas fa-road text-info mr-1"></i> 通報道路名稱 / 案號
                            </label>
                            <input type="text" class="form-control" v-model="filter.RoadName" placeholder="例如：文化路一段、或輸入案號..." v-on:keyup.enter="handleSearch" />
                        </div>

                        <!-- 日期區間 -->
                        <div class="col-12 col-md-4 mb-3">
                            <label class="font-weight-bold text-muted small mb-1">
                                <i class="far fa-calendar-alt text-primary mr-1"></i> {{ getDateLabel() }} 區間
                            </label>
                            <div class="d-flex align-items-center" style="width: 100%;">
                                <input type="date" class="form-control" style="flex: 1; min-width: 0;" v-model="filter.DateS" />
                                <span class="mx-2 text-muted font-weight-bold">~</span>
                                <input type="date" class="form-control" style="flex: 1; min-width: 0;" v-model="filter.DateE" />
                            </div>
                        </div>

                        <!-- 處理單位篩選 (改善與結案模式) -->
                        <div class="col-12 col-md-4 mb-3" v-if="currentMode !== 'BreakEdit'">
                            <label class="font-weight-bold text-muted small mb-1">
                                <i class="fas fa-building text-warning mr-1"></i> 處理權責單位
                            </label>
                            <select class="form-control" v-model="filter.UnitId" v-on:change="handleSearch" style="font-weight: 600;">
                                <option value="">全部處理單位</option>
                                <option v-for="u in units" :key="u.UnitId" :value="u.UnitId">
                                    {{ u.UnitName }}
                                </option>
                            </select>
                        </div>
                    </div>

                    <!-- 快捷日期按鈕與搜尋列 (比照 Clean_List.aspx 規格) -->
                    <div class="d-flex flex-wrap align-items-center justify-content-between pt-2 border-top">
                        <div class="btn-group btn-group-sm mb-2 mb-md-0" role="group">
                            <button type="button" class="btn btn-outline-secondary" v-on:click="setDateShortcut('all')">不限日期</button>
                            <button type="button" class="btn btn-outline-secondary" v-on:click="setDateShortcut('today')">今天</button>
                            <button type="button" class="btn btn-outline-secondary" v-on:click="setDateShortcut('week')">近 7 天</button>
                            <button type="button" class="btn btn-outline-secondary" v-on:click="setDateShortcut('month')">近 1 個月</button>
                            <button type="button" class="btn btn-outline-secondary" v-on:click="setDateShortcut('quarter')">近 3 個月</button>
                        </div>
                        <button type="button" class="btn btn-primary px-4 font-weight-bold shadow-sm" :disabled="loading" v-on:click="handleSearch">
                            <i class="fas fa-search mr-1"></i>
                            <span v-if="!loading">查詢資料</span>
                            <span v-else>查詢中...</span>
                        </button>
                    </div>
                </div>
            </div>

            <!-- 案件列表主要卡片 (比照 Clean_List.aspx 規格) -->
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

                    <!-- 查無資料 -->
                    <div v-else-if="list.length === 0" class="text-center py-5">
                        <div class="mb-3 text-muted" style="font-size: 3rem;">
                            <i class="far fa-folder-open"></i>
                        </div>
                        <h5 class="font-weight-bold text-secondary">查無符合條件的破損通報紀錄</h5>
                        <p class="text-muted small">請嘗試放寬篩選條件或點選「不限日期」。</p>
                        <a href="NewBreak.aspx?mode=new" class="btn btn-primary font-weight-bold px-4 mt-2">
                            <i class="fas fa-plus mr-1"></i> 建立第一筆現場破損通報
                        </a>
                    </div>

                    <!-- 寬螢幕桌面端表格 (Desktop & Tablet) (比照 Clean_List.aspx 規格) -->
                    <div v-else class="table-responsive d-none d-md-block">
                        <table class="table-modern">
                            <thead>
                                <tr>
                                    <th style="width: 170px;">通報編號</th>
                                    <th style="width: 100px;">行政區</th>
                                    <th style="width: 170px; min-width: 140px;">破損道路</th>
                                    <th style="width: 150px;">{{ currentMode === 'BreakEdit' ? '查核時間' : (currentMode === 'BreakImprove' ? '通報時間' : '處理時間') }}</th>
                                    <th style="width: 140px;">佐證照片</th>
                                    <th style="width: 170px; min-width: 150px; white-space: nowrap;">鋪面平整度</th>
                                    <th style="width: 160px; min-width: 140px; white-space: nowrap;">人手孔蓋狀況</th>
                                    <th style="width: 120px;" v-if="currentMode !== 'BreakEdit'">處理單位</th>
                                    <th style="width: 110px;">案件階段</th>
                                    <th style="min-width: 200px; width: 200px; white-space: nowrap;" class="text-center">操作功能</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr v-for="item in list" :key="item.Break_ID">
                                    <!-- 通報編號 -->
                                    <td>
                                        <div class="font-weight-bold text-dark" style="font-family: monospace; font-size: 14px;">
                                            {{ item.Show_ID }}
                                        </div>
                                        <small class="text-muted">
                                            人員: {{ item.Report_UserName || item.Report_User || '未登錄' }}
                                        </small>
                                    </td>

                                    <!-- 行政區 -->
                                    <td>
                                        <span class="town-chip">{{ item.TownName || item.TOWN_CODE }}</span>
                                    </td>

                                    <!-- 破損道路 -->
                                    <td>
                                        <div class="font-weight-bold text-dark" style="font-size: 15px;">
                                            {{ item.ROAD_Name }}
                                        </div>
                                        <span class="road-lv-chip mt-1" v-if="item.ROAD_LV">{{ item.ROAD_LV }}</span>
                                    </td>

                                    <!-- 時間 -->
                                    <td>
                                        <div class="small font-weight-bold text-secondary">
                                            {{ currentMode === 'BreakEdit' ? (item.Report_Date || '-') : (currentMode === 'BreakImprove' ? (item.SetCOM_Date || '-') : (item.Improve_Date || '-')) }}
                                        </div>
                                        <div v-if="item.S_UTME" class="text-muted" style="font-size: 11px;">
                                            ({{ item.S_UTME }}, {{ item.S_UTMN }})
                                        </div>
                                    </td>

                                    <!-- 佐證照片明細 -->
                                    <td>
                                        <button v-if="item.PhotoCount > 0" type="button" class="btn btn-sm btn-light border py-1 px-2 font-weight-bold small text-primary" v-on:click="openPhotoModal(item)">
                                            <i class="fas fa-camera mr-1"></i> {{ item.PhotoCount }} 張照片
                                        </button>
                                        <span v-else class="text-muted small">無照片</span>
                                    </td>

                                    <!-- 鋪面平整度晶片 -->
                                    <td style="white-space: nowrap;">
                                        <span class="score-badge" :class="getSmoothScoreClass(item.Smooth)">
                                            <i :class="getSmoothScoreIcon(item.Smooth)"></i>
                                            <span>{{ item.SmoothName || item.Smooth || '未評' }}</span>
                                        </span>
                                    </td>

                                    <!-- 人手孔蓋狀況晶片 -->
                                    <td style="white-space: nowrap;">
                                        <div class="small font-weight-bold text-dark">
                                            {{ item.HoleName || item.Hole_Conn_St || '-' }}
                                        </div>
                                        <div v-if="item.Memo" class="text-muted small" style="max-width: 180px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;" :title="item.Memo">
                                            <i class="fas fa-comment-alt mr-1"></i>{{ item.Memo }}
                                        </div>
                                    </td>

                                    <!-- 處理單位 (非暫存模式) -->
                                    <td v-if="currentMode !== 'BreakEdit'">
                                        <span class="font-weight-bold text-dark small">{{ item.G_COM_NAME || '-' }}</span>
                                    </td>

                                    <!-- 案件階段狀態徽章 (比照 Clean_List.aspx 規格) -->
                                    <td>
                                        <span class="badge px-2 py-1 font-weight-bold" :class="item.StateBadge" style="font-size: 12px;">
                                            {{ item.StateName }}
                                        </span>
                                        <div v-if="item.G_Memo" class="small text-success font-weight-bold mt-1" :title="item.G_Memo">
                                            <i class="fas fa-check-circle mr-1"></i>已改善
                                        </div>
                                    </td>

                                    <!-- 操作功能按鈕群 (比照 Clean_List.aspx 規格) -->
                                    <td class="text-center" style="white-space: nowrap;">
                                        <div class="action-btn-group justify-content-center">
                                            <!-- 草稿/待通報狀態 -->
                                            <template v-if="!item.SetCOM_Date">
                                                <a :href="'NewBreak.aspx?id=' + item.Break_ID + '&mode=edit'" class="btn btn-sm btn-warning btn-action text-dark font-weight-bold" title="編輯修改">
                                                    <i class="fas fa-pencil-alt"></i> 編輯
                                                </a>
                                                <a :href="'SetSG_Break.aspx?id=' + item.Break_ID" class="btn btn-sm btn-primary btn-action font-weight-bold" title="通報權責單位">
                                                    <i class="fas fa-paper-plane"></i> 通報
                                                </a>
                                                <button type="button" class="btn btn-sm btn-outline-danger btn-action" v-on:click="confirmDelete(item)" title="刪除案件">
                                                    <i class="fas fa-trash-alt"></i>
                                                </button>
                                            </template>

                                            <!-- 改善處理中狀態 -->
                                            <template v-else-if="item.SetCOM_Date && !item.Improve_Date">
                                                <a :href="'ImproveBreak.aspx?id=' + item.Break_ID" class="btn btn-sm btn-success btn-action font-weight-bold shadow-sm" title="改善回報">
                                                    <i class="fas fa-tools"></i> 改善回報
                                                </a>
                                                <a :href="'BreakDetail.aspx?id=' + item.Break_ID" class="btn btn-sm btn-info btn-action font-weight-bold" title="檢視詳細">
                                                    <i class="fas fa-eye"></i> 檢視
                                                </a>
                                            </template>

                                            <!-- 改善已完成狀態 -->
                                            <template v-else>
                                                <a :href="'BreakDetail.aspx?id=' + item.Break_ID" class="btn btn-sm btn-info btn-action font-weight-bold" title="成果檢視">
                                                    <i class="fas fa-file-alt"></i> 詳細資料
                                                </a>
                                            </template>
                                        </div>
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>

                    <!-- 手機端自適應卡片清單 (Mobile Cards) (比照 Clean_List.aspx 規格) -->
                    <div class="d-block d-md-none p-3">
                        <div v-for="item in list" :key="item.Break_ID" class="mobile-card">
                            <div class="mobile-card-header">
                                <div class="d-flex align-items-center gap-2">
                                    <span class="town-chip">{{ item.TownName || item.TOWN_CODE }}</span>
                                    <span class="font-weight-bold text-dark" style="font-family: monospace;">{{ item.Show_ID }}</span>
                                </div>
                                <span class="badge px-2 py-1 font-weight-bold" :class="item.StateBadge">
                                    {{ item.StateName }}
                                </span>
                            </div>

                            <h3 class="mobile-card-title mb-1">{{ item.ROAD_Name }}</h3>
                            <div class="small text-muted mb-2">
                                <i class="far fa-clock mr-1"></i> {{ item.Report_Date }}
                                <span class="ml-2"><i class="fas fa-user-edit mr-1"></i> {{ item.Report_UserName || item.Report_User }}</span>
                            </div>

                            <!-- 狀態晶片群 -->
                            <div class="d-flex flex-wrap gap-2 mb-3">
                                <span class="score-badge" :class="getSmoothScoreClass(item.Smooth)">
                                    <i :class="getSmoothScoreIcon(item.Smooth)"></i>
                                    平整: {{ item.SmoothName || item.Smooth || '未評' }}
                                </span>
                                <span class="score-badge score-b">
                                    <i class="fas fa-circle-notch"></i>
                                    孔蓋: {{ item.HoleName || item.Hole_Conn_St || '-' }}
                                </span>
                                <button v-if="item.PhotoCount > 0" type="button" class="btn btn-sm btn-light border py-1 px-2 font-weight-bold small text-primary" v-on:click="openPhotoModal(item)">
                                    <i class="fas fa-camera mr-1"></i> {{ item.PhotoCount }} 張照片
                                </button>
                            </div>

                            <!-- 補充說明 -->
                            <div v-if="item.Memo" class="alert alert-light py-2 px-3 small text-muted mb-3 border">
                                <i class="fas fa-comment-alt mr-1"></i> 備註：{{ item.Memo }}
                            </div>

                            <!-- 手機動作按鈕列 -->
                            <div class="action-btn-group pt-2 border-top w-100">
                                <template v-if="!item.SetCOM_Date">
                                    <a :href="'NewBreak.aspx?id=' + item.Break_ID + '&mode=edit'" class="btn btn-warning btn-action text-dark font-weight-bold">
                                        <i class="fas fa-pencil-alt"></i> 編輯修改
                                    </a>
                                    <a :href="'SetSG_Break.aspx?id=' + item.Break_ID" class="btn btn-primary btn-action font-weight-bold">
                                        <i class="fas fa-paper-plane"></i> 通報
                                    </a>
                                    <button type="button" class="btn btn-outline-danger btn-action" v-on:click="confirmDelete(item)">
                                        <i class="fas fa-trash-alt"></i> 刪除
                                    </button>
                                </template>
                                <template v-else-if="item.SetCOM_Date && !item.Improve_Date">
                                    <a :href="'ImproveBreak.aspx?id=' + item.Break_ID" class="btn btn-success btn-action font-weight-bold shadow-sm">
                                        <i class="fas fa-tools"></i> 改善回報
                                    </a>
                                    <a :href="'BreakDetail.aspx?id=' + item.Break_ID" class="btn btn-info btn-action font-weight-bold">
                                        <i class="fas fa-eye"></i> 檢視
                                    </a>
                                </template>
                                <template v-else>
                                    <a :href="'BreakDetail.aspx?id=' + item.Break_ID" class="btn btn-info btn-action font-weight-bold w-100">
                                        <i class="fas fa-file-alt"></i> 詳細資料
                                    </a>
                                </template>
                            </div>
                        </div>
                    </div>

                    <!-- 分頁導覽列 (Server-side Pagination) (比照 Clean_List.aspx 規格) -->
                    <div v-if="totalCount > 0" class="pagination-container">
                        <div class="d-flex align-items-center gap-2 small text-muted font-weight-bold">
                            <span>顯示第 {{ (pageIndex - 1) * pageSize + 1 }} ~ {{ Math.min(pageIndex * pageSize, totalCount) }} 筆，共 {{ totalCount }} 筆</span>
                            <span class="mx-2">|</span>
                            <span>每頁</span>
                            <select class="custom-select custom-select-sm" style="width: 75px;" v-model.number="pageSize" v-on:change="onPageSizeChange">
                                <option :value="10">10</option>
                                <option :value="20">20</option>
                                <option :value="50">50</option>
                                <option :value="100">100</option>
                            </select>
                            <span>筆</span>
                        </div>

                        <!-- 頁碼切換按鈕群 -->
                        <div class="d-flex align-items-center gap-1">
                            <button type="button" class="page-link-custom" :class="{ 'disabled': pageIndex <= 1 }" v-on:click="gotoPage(1)" title="第一頁">
                                <i class="fas fa-angle-double-left"></i>
                            </button>
                            <button type="button" class="page-link-custom" :class="{ 'disabled': pageIndex <= 1 }" v-on:click="gotoPage(pageIndex - 1)" title="上一頁">
                                <i class="fas fa-angle-left"></i>
                            </button>

                            <template v-for="p in pageRange" :key="p">
                                <button v-if="p !== '...'" type="button" class="page-link-custom" :class="{ 'active': pageIndex === p }" v-on:click="gotoPage(p)">
                                    {{ p }}
                                </button>
                                <span v-else class="px-2 text-muted">...</span>
                            </template>

                            <button type="button" class="page-link-custom" :class="{ 'disabled': pageIndex >= totalPages }" v-on:click="gotoPage(pageIndex + 1)" title="下一頁">
                                <i class="fas fa-angle-right"></i>
                            </button>
                            <button type="button" class="page-link-custom" :class="{ 'disabled': pageIndex >= totalPages }" v-on:click="gotoPage(totalPages)" title="最末頁">
                                <i class="fas fa-angle-double-right"></i>
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </main>

        <!-- 佐證照片預覽 Modal -->
        <div v-if="activePhotoItem" class="lightbox-overlay" v-on:click="activePhotoItem = null">
            <div class="bg-white p-4 rounded shadow-lg" style="max-width: 800px; width: 95%; max-height: 90vh; overflow-y: auto;" v-on:click.stop>
                <div class="d-flex align-items-center justify-content-between mb-3 border-bottom pb-2">
                    <h5 class="font-weight-bold m-0 text-dark">
                        <i class="fas fa-camera text-primary mr-1"></i>
                        {{ activePhotoItem.Show_ID }} - {{ activePhotoItem.ROAD_Name }} 現場照片
                    </h5>
                    <button type="button" class="close" v-on:click="activePhotoItem = null">&times;</button>
                </div>

                <div v-if="!activePhotoItem.PhotoUrls || activePhotoItem.PhotoUrls.length === 0" class="text-center py-4 text-muted">
                    查無佐證照片檔案
                </div>
                <div v-else class="photo-preview-grid">
                    <div v-for="(url, idx) in activePhotoItem.PhotoUrls" :key="idx" class="text-center">
                        <img :src="url" :alt="'佐證照片 ' + (idx + 1)" class="photo-preview-thumb" v-on:click="openLightbox(url)" />
                        <div class="small font-weight-bold text-muted mt-1">照片 {{ idx + 1 }}</div>
                    </div>
                </div>
            </div>
        </div>

        <!-- 照片大圖燈箱 (Lightbox) -->
        <div v-if="lightboxImg" class="lightbox-overlay" v-on:click="lightboxImg = null">
            <img :src="lightboxImg" class="lightbox-img" v-on:click.stop alt="檢視大圖" />
        </div>
    </div>

    <!-- 本地化 JS 依賴 (比照 Clean_List.aspx 規格) -->
    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>

    <script type="text/javascript">
        const { createApp } = Vue;

        createApp({
            data() {
                return {
                    currentMode: 'BreakEdit',   // 'BreakEdit' | 'BreakImprove' | 'Finish' | 'all'
                    towns: [
                        { TownNo: '6500100', TownName: '板橋區' },
                        { TownNo: '6500200', TownName: '三重區' },
                        { TownNo: '6500300', TownName: '中和區' },
                        { TownNo: '6500400', TownName: '永和區' },
                        { TownNo: '6500500', TownName: '新莊區' },
                        { TownNo: '6500600', TownName: '新店區' },
                        { TownNo: '6500700', TownName: '樹林區' },
                        { TownNo: '6500800', TownName: '鶯歌區' },
                        { TownNo: '6500900', TownName: '三峽區' },
                        { TownNo: '6501000', TownName: '淡水區' },
                        { TownNo: '6501100', TownName: '汐止區' },
                        { TownNo: '6501200', TownName: '瑞芳區' },
                        { TownNo: '6501300', TownName: '土城區' },
                        { TownNo: '6501400', TownName: '蘆洲區' },
                        { TownNo: '6501500', TownName: '五股區' },
                        { TownNo: '6501600', TownName: '泰山區' },
                        { TownNo: '6501700', TownName: '林口區' },
                        { TownNo: '6501800', TownName: '深坑區' },
                        { TownNo: '6501900', TownName: '石碇區' },
                        { TownNo: '6502000', TownName: '坪林區' },
                        { TownNo: '6502100', TownName: '三芝區' },
                        { TownNo: '6502200', TownName: '石門區' },
                        { TownNo: '6502300', TownName: '八里區' },
                        { TownNo: '6502400', TownName: '平溪區' },
                        { TownNo: '6502500', TownName: '雙溪區' },
                        { TownNo: '6502600', TownName: '貢寮區' },
                        { TownNo: '6502700', TownName: '金山區' },
                        { TownNo: '6502800', TownName: '萬里區' },
                        { TownNo: '6502900', TownName: '烏來區' }
                    ],
                    units: [
                        { UnitId: 'U01', UnitName: '新北市政府工務局養護工程處' },
                        { UnitId: 'U02', UnitName: '新北市各區公所工務課' },
                        { UnitId: 'U03', UnitName: '交通部公路局第一區養護工程處' }
                    ],
                    counts: {
                        BreakEdit: 0,
                        BreakImprove: 0,
                        Finish: 0,
                        Total: 0
                    },

                    filter: {
                        TownCode: '',
                        RoadName: '',
                        UnitId: '',
                        DateS: '',
                        DateE: ''
                    },

                    list: [],
                    totalCount: 0,
                    pageIndex: 1,
                    pageSize: 20,
                    totalPages: 1,

                    loading: false,
                    alertMessage: '',
                    alertType: 'info',

                    activePhotoItem: null,
                    lightboxImg: null
                };
            },

            computed: {
                pageRange() {
                    const current = this.pageIndex;
                    const last = this.totalPages;
                    const delta = 2;
                    const left = current - delta;
                    const right = current + delta + 1;
                    const range = [];
                    const rangeWithDots = [];
                    let l;

                    for (let i = 1; i <= last; i++) {
                        if (i === 1 || i === last || (i >= left && i < right)) {
                            range.push(i);
                        }
                    }

                    for (const i of range) {
                        if (l) {
                            if (i - l === 2) {
                                rangeWithDots.push(l + 1);
                            } else if (i - l !== 1) {
                                rangeWithDots.push('...');
                            }
                        }
                        rangeWithDots.push(i);
                        l = i;
                    }

                    return rangeWithDots;
                }
            },

            mounted() {
                const urlParams = new URLSearchParams(window.location.search);
                const m = urlParams.get('mode');
                if (m && ['breakedit', 'breakimprove', 'finish', 'all'].includes(m.toLowerCase())) {
                    if (m.toLowerCase() === 'breakedit') this.currentMode = 'BreakEdit';
                    if (m.toLowerCase() === 'breakimprove') this.currentMode = 'BreakImprove';
                    if (m.toLowerCase() === 'finish') this.currentMode = 'Finish';
                    if (m.toLowerCase() === 'all') this.currentMode = 'all';
                }

                // 查核紀錄暫存(草稿)預設不限日期，讓所有待通報案件一覽無遺；其餘模式預設近1個月
                if (this.currentMode === 'BreakEdit') {
                    this.setDateShortcut('all');
                } else {
                    this.setDateShortcut('month');
                }

                this.loadInitData();
            },

            methods: {
                // 1. 初始化資料
                loadInitData() {
                    this.loading = true;
                    axios.get('Break_List.aspx?action=getinit&_t=' + new Date().getTime())
                        .then(res => {
                            let respData = res.data;
                            if (typeof respData === 'string') {
                                try { respData = JSON.parse(respData); } catch (e) { }
                            }

                            if (respData && respData.Success) {
                                const d = respData.Data || {};
                                if (d.Towns && d.Towns.length > 0) this.towns = d.Towns;
                                if (d.Units && d.Units.length > 0) this.units = d.Units;
                                if (d.Counts) this.counts = d.Counts;

                                // 若不是 BreakEdit 且日期尚未設定，帶入後端預設區間
                                if (this.currentMode !== 'BreakEdit') {
                                    if (!this.filter.DateS && d.DefaultDateS) this.filter.DateS = d.DefaultDateS;
                                    if (!this.filter.DateE && d.DefaultDateE) this.filter.DateE = d.DefaultDateE;
                                }

                                this.loadList();
                            } else {
                                const errMsg = (respData && respData.Message) ? respData.Message : '初始化資料讀取異常';
                                this.showAlert(errMsg, 'danger');
                                this.loading = false;
                                this.loadList();
                            }
                        })
                        .catch(err => {
                            console.error(err);
                            this.showAlert('連線伺服器異常，已使用預設行政區與參數載入', 'warning');
                            this.loading = false;
                            this.loadList();
                        });
                },

                // 2. 切換業務模式
                switchMode(mode) {
                    if (this.currentMode === mode) return;
                    this.currentMode = mode;
                    this.pageIndex = 1;

                    // 同步 URL
                    const url = new URL(window.location.href);
                    url.searchParams.set('mode', mode);
                    window.history.pushState({}, '', url);

                    // 切換至草稿模式預設不限日期，其他模式預設近一個月
                    if (this.currentMode === 'BreakEdit') {
                        this.setDateShortcut('all');
                    } else if (!this.filter.DateS && !this.filter.DateE) {
                        this.setDateShortcut('month');
                    }

                    this.loadList();
                },

                // 3. 查詢清單 (採用 GET 模式，杜絕機房 WAF / 反向代理封鎖 POST 導致 ERR_CONNECTION_RESET)
                loadList() {
                    this.loading = true;

                    const params = {
                        action: 'getlist',
                        mode: this.currentMode,
                        searchId: this.filter.RoadName, // 支援案號、道路名稱、備註綜合關鍵字搜尋
                        roadName: this.filter.RoadName,
                        townCode: this.filter.TownCode,
                        unitId: this.filter.UnitId,
                        dateS: this.filter.DateS,
                        dateE: this.filter.DateE,
                        pageIndex: this.pageIndex,
                        pageSize: this.pageSize,
                        _t: new Date().getTime() // 避開任何快取
                    };

                    axios.get('Break_List.aspx', { params: params })
                        .then(res => {
                            this.loading = false;
                            let respData = res.data;
                            if (typeof respData === 'string') {
                                try {
                                    respData = JSON.parse(respData);
                                } catch (e) {
                                    console.error('API 回傳非 JSON 格式字串：', res.data);
                                    this.showAlert('伺服器回應異常或尚未登入，請重新登入或重新整理', 'danger');
                                    return;
                                }
                            }

                            if (respData && respData.Success) {
                                const d = respData.Data || {};
                                this.list = d.Items || [];
                                this.totalCount = d.TotalRecords || 0;
                                this.totalPages = d.TotalPages || 1;
                                this.refreshCounts();
                            } else {
                                const errMsg = (respData && respData.Message) ? respData.Message : '查詢失敗 (伺服器未回傳具體錯誤訊息)';
                                this.showAlert(errMsg, 'danger');
                            }
                        })
                        .catch(err => {
                            this.loading = false;
                            console.error(err);
                            this.showAlert('伺服器處理查詢失敗：' + (err.message || '連線逾時或網路異常'), 'danger');
                        });
                },

                handleSearch() {
                    this.pageIndex = 1;
                    this.loadList();
                },

                refreshCounts() {
                    axios.get('Break_List.aspx?action=getcounts&_t=' + new Date().getTime())
                        .then(res => {
                            let respData = res.data;
                            if (typeof respData === 'string') {
                                try { respData = JSON.parse(respData); } catch (e) { }
                            }
                            if (respData && respData.Success) {
                                this.counts = respData.Data || this.counts;
                            }
                        });
                },

                // 4. 快捷日期設定 (比照 Clean_List.aspx 規格)
                setDateShortcut(type) {
                    const today = new Date();
                    const fmt = (d) => {
                        const y = d.getFullYear();
                        const m = String(d.getMonth() + 1).padStart(2, '0');
                        const day = String(d.getDate()).padStart(2, '0');
                        return y + '-' + m + '-' + day;
                    };

                    if (type === 'all') {
                        this.filter.DateS = '';
                        this.filter.DateE = '';
                    } else if (type === 'today') {
                        this.filter.DateS = fmt(today);
                        this.filter.DateE = fmt(today);
                    } else if (type === 'week') {
                        const d = new Date();
                        d.setDate(d.getDate() - 7);
                        this.filter.DateS = fmt(d);
                        this.filter.DateE = fmt(today);
                    } else if (type === 'month') {
                        const d = new Date();
                        d.setMonth(d.getMonth() - 1);
                        this.filter.DateS = fmt(d);
                        this.filter.DateE = fmt(today);
                    } else if (type === 'quarter') {
                        const d = new Date();
                        d.setMonth(d.getMonth() - 3);
                        this.filter.DateS = fmt(d);
                        this.filter.DateE = fmt(today);
                    }

                    this.handleSearch();
                },

                resetFilter() {
                    this.filter.TownCode = '';
                    this.filter.RoadName = '';
                    this.filter.UnitId = '';
                    this.setDateShortcut('month');
                },

                // 5. 分頁操作
                gotoPage(p) {
                    if (p < 1 || p > this.totalPages || p === this.pageIndex) return;
                    this.pageIndex = p;
                    this.loadList();
                },

                onPageSizeChange() {
                    this.pageIndex = 1;
                    this.loadList();
                },

                // 6. 匯出 EXCEL
                exportExcel() {
                    const params = new URLSearchParams({
                        action: 'export',
                        mode: this.currentMode,
                        searchId: this.filter.RoadName,
                        townCode: this.filter.TownCode,
                        roadName: this.filter.RoadName,
                        unitId: this.filter.UnitId,
                        dateS: this.filter.DateS,
                        dateE: this.filter.DateE
                    });
                    window.location.href = 'Break_List.aspx?' + params.toString();
                },
                exportCsv() {
                    this.exportExcel();
                },

                // 7. 刪除案件
                confirmDelete(item) {
                    if (!confirm('確定要刪除通報案號「' + item.Show_ID + '」嗎？此操作將同時移除關聯的佐證照片且無法復原！')) {
                        return;
                    }

                    axios.get('Break_List.aspx?action=delete&id=' + encodeURIComponent(item.Break_ID))
                        .then(res => {
                            if (res.data && res.data.Success) {
                                this.showAlert(res.data.Message || '通報單已成功刪除', 'success');
                                this.loadList();
                            } else {
                                this.showAlert(res.data.Message || '刪除失敗', 'danger');
                            }
                        })
                        .catch(err => {
                            console.error(err);
                            this.showAlert('刪除連線異常', 'danger');
                        });
                },

                // 8. 照片檢視
                openPhotoModal(item) {
                    this.activePhotoItem = item;
                },

                openLightbox(url) {
                    this.lightboxImg = url;
                },

                // 9. 輔助樣式與文字 (比照 Clean_List.aspx 規格)
                getModeTitle() {
                    if (this.currentMode === 'BreakEdit') return '查核紀錄暫存列表 (待通報草稿)';
                    if (this.currentMode === 'BreakImprove') return '破損改善回報列表 (處理中案件)';
                    if (this.currentMode === 'Finish') return '破損改善成果列表 (已結案案件)';
                    return '全部破損通報案件總覽';
                },

                getDateLabel() {
                    if (this.currentMode === 'BreakEdit') return '查核日期';
                    if (this.currentMode === 'BreakImprove') return '通報日期';
                    if (this.currentMode === 'Finish') return '改善處理日期';
                    return '巡查日期';
                },

                getSmoothScoreClass(smooth) {
                    if (smooth === '1') return 'score-a';
                    if (smooth === '2') return 'score-b';
                    if (smooth === '3') return 'score-c';
                    if (smooth === '4') return 'score-d';
                    return 'score-b';
                },

                getSmoothScoreIcon(smooth) {
                    if (smooth === '1') return 'fas fa-check-circle';
                    if (smooth === '2') return 'fas fa-wave-square';
                    if (smooth === '3') return 'fas fa-exclamation-triangle';
                    if (smooth === '4') return 'fas fa-ban';
                    return 'fas fa-info-circle';
                },

                showAlert(msg, type) {
                    this.alertMessage = msg;
                    this.alertType = type || 'info';
                    window.scrollTo({ top: 0, behavior: 'smooth' });
                }
            }
        }).mount('#listApp');
    </script>
</body>
</html>
