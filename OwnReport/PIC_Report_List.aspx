<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="PIC_Report_List.aspx.cs" Inherits="NTPC_FEC.OwnReport.PIC_Report_List" %>

<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>固定污染源自主管理與改善回報列表 - 新北市固定溢散源管理平台</title>

    <!-- 專屬 Favicon -->
    <link rel="shortcut icon" href="../favicon.ico" type="image/x-icon" />

    <!-- 本地化樣式依賴 (遵循 inspection-ui-standard) -->
    <link rel="stylesheet" href="../Content/bootstrap.min.css" />
    <link rel="stylesheet" href="../Content/fontawesome/css/all.min.css" />

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
            --badge-own: #0284c7;         /* 自主回報標籤色 */
            --badge-wrong: #ea580c;       /* 缺失改善標籤色 */
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

        /* 頂部深青藍漸層導覽列 */
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
            font-size: 0.92rem;
            font-weight: 600;
            cursor: pointer;
            height: 38px;
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

        /* 主作業容器 (符合 inspection-ui-standard 規範 1560px) */
        .container-fluid-custom {
            max-width: 1560px;
            margin: 0 auto;
            padding: 20px 16px;
        }

        /* 統計指標卡區 */
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
            gap: 16px;
            margin-bottom: 20px;
        }

        .stat-card {
            background: var(--surface);
            border: 1px solid var(--border-color);
            border-radius: 12px;
            padding: 16px 20px;
            display: flex;
            align-items: center;
            gap: 16px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
            transition: transform 0.2s ease, box-shadow 0.2s ease;
        }

        .stat-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(15, 23, 42, 0.08);
        }

        .stat-icon {
            width: 50px;
            height: 50px;
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 22px;
            color: #ffffff;
            flex-shrink: 0;
        }

        .stat-info {
            display: flex;
            flex-direction: column;
        }

        .stat-title {
            font-size: 13px;
            font-weight: 600;
            color: var(--text-muted);
            margin-bottom: 4px;
        }

        .stat-value {
            font-size: 24px;
            font-weight: 800;
            color: var(--brand-navy);
            line-height: 1;
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

        /* 篩選標籤晶片群 (Date Chips) */
        .date-chip-group {
            display: flex;
            flex-wrap: wrap;
            gap: 6px;
            margin-bottom: 10px;
        }

        .date-chip-btn {
            border: 1px solid #cbd5e1;
            background: #f8fafc;
            color: #475569;
            padding: 4px 12px;
            border-radius: 6px;
            font-size: 12px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.15s ease;
        }

        .date-chip-btn:hover {
            background: #e2e8f0;
            color: #0f172a;
        }

        .date-chip-btn.active {
            background: #e0f2fe;
            border-color: #0284c7;
            color: #0369a1;
            font-weight: 700;
        }

        /* 表格樣式 */
        .table-custom {
            width: 100%;
            margin-bottom: 0;
            border-collapse: separate;
            border-spacing: 0;
        }

        .table-custom th {
            background-color: #f8fafc;
            color: #475569;
            font-weight: 700;
            font-size: 13px;
            padding: 12px 14px;
            border-bottom: 2px solid var(--border-color);
            border-top: none;
            white-space: nowrap;
        }

        .table-custom td {
            padding: 14px;
            vertical-align: middle;
            font-size: 13.5px;
            border-bottom: 1px solid var(--border-color);
            border-top: none;
            color: var(--text-main);
        }

        .table-custom tbody tr {
            transition: background-color 0.15s ease;
        }

        .table-custom tbody tr:hover {
            background-color: #f1f5f9;
        }

        /* 標籤徽章 */
        .badge-type-own {
            background-color: #e0f2fe;
            color: #0369a1;
            border: 1px solid #bae6fd;
            padding: 4px 10px;
            border-radius: 6px;
            font-weight: 700;
            font-size: 12px;
            display: inline-flex;
            align-items: center;
            gap: 4px;
        }

        .badge-type-wrong {
            background-color: #ffedd5;
            color: #c2410c;
            border: 1px solid #fed7aa;
            padding: 4px 10px;
            border-radius: 6px;
            font-weight: 700;
            font-size: 12px;
            display: inline-flex;
            align-items: center;
            gap: 4px;
        }

        .badge-cno {
            font-family: Consolas, monospace;
            background: #f1f5f9;
            color: #334155;
            border: 1px solid #cbd5e1;
            padding: 2px 6px;
            border-radius: 4px;
            font-size: 12px;
        }

        /* 手機版卡片視圖 (預設在小於 992px 時顯現) */
        .mobile-card-item {
            background: #ffffff;
            border: 1px solid var(--border-color);
            border-radius: 10px;
            padding: 16px;
            margin-bottom: 12px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
        }

        .mobile-card-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 8px;
        }

        .mobile-card-label {
            font-size: 12px;
            color: var(--text-muted);
            font-weight: 600;
        }

        .mobile-card-val {
            font-size: 13.5px;
            font-weight: 600;
            color: var(--text-main);
        }

        /* 分頁控制項 */
        .pagination-container {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 16px 20px;
            background: #ffffff;
            border-top: 1px solid var(--border-color);
            flex-wrap: wrap;
            gap: 12px;
        }

        .page-pill {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            min-width: 36px;
            height: 36px;
            padding: 0 10px;
            border-radius: 8px;
            border: 1px solid #cbd5e1;
            background: #ffffff;
            color: #334155;
            font-size: 13px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.15s ease;
            user-select: none;
        }

        .page-pill:hover:not(.disabled) {
            background: #f1f5f9;
            border-color: #94a3b8;
        }

        .page-pill.active {
            background: var(--brand-blue);
            color: #ffffff;
            border-color: var(--brand-blue);
            font-weight: 700;
        }

        .page-pill.disabled {
            opacity: 0.45;
            cursor: not-allowed;
            background: #f8fafc;
        }

        /* 模態視窗自定義樣式 */
        .modal-custom-header {
            background: linear-gradient(135deg, #0099e5 0%, #0284c7 100%);
            color: #ffffff;
            padding: 16px 20px;
            border-top-left-radius: 12px;
            border-top-right-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .modal-custom-title {
            font-size: 1.1rem;
            font-weight: 700;
            margin: 0;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        /* 空資料狀態與載入中 */
        .empty-state-box {
            text-align: center;
            padding: 60px 20px;
            color: #94a3b8;
        }

        .empty-state-icon {
            font-size: 48px;
            margin-bottom: 16px;
            color: #cbd5e1;
        }

        .loading-overlay {
            position: absolute;
            top: 0; left: 0; right: 0; bottom: 0;
            background: rgba(255, 255, 255, 0.75);
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            z-index: 100;
            border-radius: 12px;
        }

        /* 列印樣式處理 */
        @media print {
            .no-print {
                display: none !important;
            }
            body {
                background: #ffffff !important;
            }
            .card-modern {
                box-shadow: none !important;
                border: 1px solid #ccc !important;
            }
        }
    </style>
</head>
<body>
    <div id="app" v-cloak>
        <!-- 1. 頂部深青藍漸層導覽列 -->
        <header class="top-navbar no-print">
            <div class="d-flex align-items-center gap-3">
                <a href="../MainPage.aspx" class="nav-btn" title="返回管理平台首頁">
                    <i class="fas fa-arrow-left"></i>
                    <span class="d-none d-sm-inline">回首頁</span>
                </a>
                <div class="navbar-brand-title">
                    <i class="fas fa-clipboard-check text-white"></i>
                    <span>固定污染源自主回報與改善列表</span>
                </div>
            </div>

            <div class="d-flex align-items-center gap-2">
                <span v-if="userInfo.FacName" class="badge badge-light text-dark font-weight-bold d-none d-md-inline" style="font-size: 0.85rem; padding: 6px 12px;">
                    <i class="fas fa-building text-primary mr-1"></i> {{ userInfo.FacName }}
                </span>
                <button type="button" class="nav-btn" v-on:click="refreshData" title="重新整理列表">
                    <i class="fas fa-sync-alt" :class="{ 'fa-spin': loading }"></i>
                    <span class="d-none d-md-inline">重新整理</span>
                </button>
            </div>
        </header>

        <!-- 2. 模式切換頁籤列 -->
        <div class="nav-mode-bar no-print">
            <div class="nav-mode-item" :class="{ 'active': currentMode === 'all' }" v-on:click="setMode('all')">
                <i class="fas fa-layer-group"></i> 全部回報紀錄
                <span class="tab-badge badge badge-secondary ml-1">{{ counts.TotalCount }}</span>
            </div>
            <div class="nav-mode-item" :class="{ 'active': currentMode === 'own' }" v-on:click="setMode('own')">
                <i class="fas fa-calendar-check text-info"></i> 自主維護回報
                <span class="tab-badge badge badge-info ml-1">{{ counts.OwnCount }}</span>
            </div>
            <div class="nav-mode-item" :class="{ 'active': currentMode === 'wrong' }" v-on:click="setMode('wrong')">
                <i class="fas fa-tools text-warning"></i> 防制設施缺失改善
                <span class="tab-badge badge badge-warning text-white ml-1">{{ counts.WrongCount }}</span>
            </div>
        </div>

        <!-- 3. 主作業容器 -->
        <main class="container-fluid-custom">
            <!-- A. 統計指標卡區 -->
            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-icon" style="background: linear-gradient(135deg, #0099e5, #0284c7);">
                        <i class="fas fa-file-alt"></i>
                    </div>
                    <div class="stat-info">
                        <span class="stat-title">總回報案件數</span>
                        <span class="stat-value">{{ counts.TotalCount }}</span>
                    </div>
                </div>

                <div class="stat-card">
                    <div class="stat-icon" style="background: linear-gradient(135deg, #06b6d4, #0891b2);">
                        <i class="fas fa-calendar-check"></i>
                    </div>
                    <div class="stat-info">
                        <span class="stat-title">自主維護回報</span>
                        <span class="stat-value text-info">{{ counts.OwnCount }}</span>
                    </div>
                </div>

                <div class="stat-card">
                    <div class="stat-icon" style="background: linear-gradient(135deg, #f97316, #ea580c);">
                        <i class="fas fa-tools"></i>
                    </div>
                    <div class="stat-info">
                        <span class="stat-title">防制設施缺失改善</span>
                        <span class="stat-value text-warning">{{ counts.WrongCount }}</span>
                    </div>
                </div>

                <div class="stat-card">
                    <div class="stat-icon" style="background: linear-gradient(135deg, #10b981, #059669);">
                        <i class="fas fa-clock"></i>
                    </div>
                    <div class="stat-info">
                        <span class="stat-title">本月新增回報</span>
                        <span class="stat-value text-success">{{ counts.MonthCount }}</span>
                    </div>
                </div>
            </div>

            <!-- B. 複合搜尋篩選卡片 -->
            <div class="card-modern no-print">
                <div class="card-modern-header">
                    <h5 class="card-modern-title">
                        <i class="fas fa-filter text-primary"></i> 條件篩選與查詢
                    </h5>
                    <div class="d-flex align-items-center gap-2">
                        <button type="button" class="btn btn-outline-secondary btn-sm" v-on:click="resetFilter">
                            <i class="fas fa-undo mr-1"></i> 重設條件
                        </button>
                        <button type="button" class="btn btn-primary btn-sm font-weight-bold" v-on:click="applyFilter">
                            <i class="fas fa-search mr-1"></i> 開始查詢
                        </button>
                    </div>
                </div>

                <div class="card-modern-body">
                    <div class="row">
                        <!-- 公私場所篩選 -->
                        <div class="col-lg-4 col-md-6 mb-3">
                            <label class="font-weight-bold text-dark small mb-1">
                                <i class="fas fa-industry text-primary mr-1"></i> 公私場所
                            </label>
                            <div v-if="userInfo.FacId && !userInfo.IsAdmin">
                                <input type="text" class="form-control form-control-sm bg-light" :value="userInfo.FacName || userInfo.FacId" readonly />
                            </div>
                            <div v-else>
                                <select class="form-control form-control-sm" v-model="filter.FacId" v-on:change="applyFilter">
                                    <option value="ALL">-- 全部公私場所 --</option>
                                    <option v-for="fac in facList" :key="fac.FacId" :value="fac.FacId">
                                        {{ fac.FacName }} ({{ fac.CNo || fac.FacId }})
                                    </option>
                                </select>
                            </div>
                        </div>

                        <!-- 關鍵字搜尋 -->
                        <div class="col-lg-4 col-md-6 mb-3">
                            <label class="font-weight-bold text-dark small mb-1">
                                <i class="fas fa-search text-primary mr-1"></i> 關鍵字查詢
                            </label>
                            <input type="text" class="form-control form-control-sm" placeholder="輸入場所名稱、管制編號、回報單號..." 
                                   v-model="filter.Keyword" v-on:keyup.enter="applyFilter" />
                        </div>

                        <!-- 日期區間與快捷晶片 -->
                        <div class="col-lg-4 col-md-12 mb-3">
                            <label class="font-weight-bold text-dark small mb-1">
                                <i class="fas fa-calendar-alt text-primary mr-1"></i> 回報日期區間
                            </label>
                            <div class="date-chip-group">
                                <button type="button" class="date-chip-btn" :class="{ 'active': activeDateRange === 'today' }" v-on:click="setDateRange('today')">今日</button>
                                <button type="button" class="date-chip-btn" :class="{ 'active': activeDateRange === '7d' }" v-on:click="setDateRange('7d')">近 7 天</button>
                                <button type="button" class="date-chip-btn" :class="{ 'active': activeDateRange === 'month' }" v-on:click="setDateRange('month')">本月</button>
                                <button type="button" class="date-chip-btn" :class="{ 'active': activeDateRange === '3m' }" v-on:click="setDateRange('3m')">近 3 個月</button>
                                <button type="button" class="date-chip-btn" :class="{ 'active': activeDateRange === 'all' }" v-on:click="setDateRange('all')">不限</button>
                            </div>
                            <div class="d-flex align-items-center gap-2">
                                <input type="date" class="form-control form-control-sm" v-model="filter.DateS" v-on:change="activeDateRange = ''" />
                                <span class="text-muted small">至</span>
                                <input type="date" class="form-control form-control-sm" v-model="filter.DateE" v-on:change="activeDateRange = ''" />
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- C. 資料列表作業區 -->
            <div class="card-modern position-relative">
                <!-- 載入中遮罩 -->
                <div v-if="loading" class="loading-overlay">
                    <div class="spinner-border text-primary mb-2" role="status"></div>
                    <span class="font-weight-bold text-muted small">資料讀取中，請稍候...</span>
                </div>

                <div class="card-modern-header">
                    <div class="d-flex align-items-center gap-2">
                        <h5 class="card-modern-title">
                            <i class="fas fa-list-alt text-primary"></i> 
                            <span>回報資料列表</span>
                        </h5>
                        <span class="badge badge-light text-muted border ml-2">共 {{ totalCount }} 筆</span>
                    </div>

                    <div class="d-flex align-items-center gap-2">
                        <!-- 快速新增回報按鈕 -->
                        <button type="button" class="btn btn-success btn-sm font-weight-bold" v-on:click="openNewReport">
                            <i class="fas fa-plus mr-1"></i> 新增回報
                        </button>
                        <!-- 匯出 Excel 按鈕 -->
                        <button type="button" class="btn btn-outline-success btn-sm" v-on:click="exportExcel">
                            <i class="fas fa-file-excel mr-1"></i> 匯出 Excel
                        </button>
                    </div>
                </div>

                <!-- 桌面版表格 (寬螢幕 $\ge 992px$) -->
                <div class="d-none d-lg-block table-responsive">
                    <table class="table-custom">
                        <thead>
                            <tr>
                                <th style="width: 70px;" class="text-center">#</th>
                                <th style="width: 110px;" class="text-center">回報單號</th>
                                <th>公私場所名稱</th>
                                <th style="width: 130px;" class="text-center">管制編號</th>
                                <th style="width: 100px;" class="text-center">行政區</th>
                                <th style="width: 130px;" class="text-center">回報類型</th>
                                <th style="width: 110px;" class="text-center">查核單號</th>
                                <th style="width: 160px;" class="text-center">回報時間</th>
                                <th style="width: 140px;" class="text-center">操作功能</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr v-for="(item, idx) in list" :key="item.Report_NO">
                                <td class="text-center font-weight-bold text-muted small">
                                    {{ (pageIndex - 1) * pageSize + idx + 1 }}
                                </td>
                                <td class="text-center font-weight-bold text-primary">
                                    #{{ item.Report_NO }}
                                </td>
                                <td>
                                    <div class="font-weight-bold text-dark">{{ item.FAC_NAME }}</div>
                                    <small class="text-muted">場所代碼：{{ item.FAC_ID }}</small>
                                </td>
                                <td class="text-center">
                                    <span class="badge-cno">{{ item.C_NO || '-' }}</span>
                                </td>
                                <td class="text-center">
                                    <span class="text-dark">{{ item.ADDR_TOWN || '-' }}</span>
                                </td>
                                <td class="text-center">
                                    <span v-if="item.Report_Type === '自主回報'" class="badge-type-own">
                                        <i class="fas fa-check-circle"></i> 自主回報
                                    </span>
                                    <span v-else class="badge-type-wrong">
                                        <i class="fas fa-exclamation-triangle"></i> 缺失改善
                                    </span>
                                </td>
                                <td class="text-center text-muted font-weight-bold small">
                                    {{ item.INV_NO ? 'INV-' + item.INV_NO : '-' }}
                                </td>
                                <td class="text-center text-muted small">
                                    {{ item.Report_Date }}
                                </td>
                                <td class="text-center">
                                    <div class="btn-group btn-group-sm">
                                        <button type="button" class="btn btn-outline-primary" v-on:click="openPreview(item)" title="快速查看詳情">
                                            <i class="fas fa-eye"></i>
                                        </button>
                                        <a :href="item.DetailUrl" class="btn btn-primary" title="開啟回報完整表單">
                                            <i class="fas fa-external-link-alt"></i> 查看
                                        </a>
                                    </div>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>

                <!-- 手機/平板卡片清單 (螢幕 $< 992px$) -->
                <div class="d-lg-none p-3">
                    <div v-for="(item, idx) in list" :key="item.Report_NO" class="mobile-card-item">
                        <div class="mobile-card-row">
                            <div class="d-flex align-items-center gap-2">
                                <span class="badge badge-secondary">#{{ item.Report_NO }}</span>
                                <span v-if="item.Report_Type === '自主回報'" class="badge-type-own">
                                    <i class="fas fa-check-circle"></i> 自主回報
                                </span>
                                <span v-else class="badge-type-wrong">
                                    <i class="fas fa-exclamation-triangle"></i> 缺失改善
                                </span>
                            </div>
                            <span class="text-muted small">{{ item.Report_Date }}</span>
                        </div>

                        <div class="font-weight-bold text-dark mb-1" style="font-size: 1.05rem;">
                            {{ item.FAC_NAME }}
                        </div>

                        <div class="mobile-card-row">
                            <span class="mobile-card-label">管制編號 / 行政區</span>
                            <span class="mobile-card-val">
                                <span class="badge-cno mr-1">{{ item.C_NO || '-' }}</span>
                                <span>{{ item.ADDR_TOWN }}</span>
                            </span>
                        </div>

                        <div class="mobile-card-row">
                            <span class="mobile-card-label">關聯查核單號</span>
                            <span class="mobile-card-val text-muted">
                                {{ item.INV_NO ? 'INV-' + item.INV_NO : '無關聯' }}
                            </span>
                        </div>

                        <div class="d-flex gap-2 mt-3 pt-2 border-top">
                            <button type="button" class="btn btn-outline-primary btn-sm flex-fill" v-on:click="openPreview(item)">
                                <i class="fas fa-eye mr-1"></i> 快速預覽
                            </button>
                            <a :href="item.DetailUrl" class="btn btn-primary btn-sm flex-fill text-center">
                                <i class="fas fa-external-link-alt mr-1"></i> 完整內容
                            </a>
                        </div>
                    </div>
                </div>

                <!-- 空資料狀態 -->
                <div v-if="!loading && list.length === 0" class="empty-state-box">
                    <div class="empty-state-icon">
                        <i class="fas fa-folder-open"></i>
                    </div>
                    <h5>查無符合條件的回報資料</h5>
                    <p class="small text-muted mb-3">請嘗試調整搜尋條件、擴大日期範圍或重設篩選。</p>
                    <button type="button" class="btn btn-outline-primary btn-sm" v-on:click="resetFilter">
                        <i class="fas fa-undo mr-1"></i> 重設所有條件
                    </button>
                </div>

                <!-- D. 分頁控制項 -->
                <div class="pagination-container" v-if="totalCount > 0">
                    <div class="d-flex align-items-center gap-2">
                        <span class="small text-muted">每頁顯示</span>
                        <select class="form-control form-control-sm" style="width: 75px;" v-model="pageSize" v-on:change="onPageSizeChange">
                            <option :value="10">10</option>
                            <option :value="20">20</option>
                            <option :value="50">50</option>
                            <option :value="100">100</option>
                        </select>
                        <span class="small text-muted">筆，第 {{ pageIndex }} / {{ totalPages }} 頁</span>
                    </div>

                    <div class="d-flex align-items-center gap-1">
                        <button type="button" class="page-pill" :class="{ 'disabled': pageIndex <= 1 }" v-on:click="changePage(1)" title="第一頁">
                            <i class="fas fa-angle-double-left"></i>
                        </button>
                        <button type="button" class="page-pill" :class="{ 'disabled': pageIndex <= 1 }" v-on:click="changePage(pageIndex - 1)" title="上一頁">
                            <i class="fas fa-angle-left"></i>
                        </button>

                        <button v-for="p in visiblePages" :key="p" type="button" class="page-pill" 
                                :class="{ 'active': p === pageIndex }" v-on:click="changePage(p)">
                            {{ p }}
                        </button>

                        <button type="button" class="page-pill" :class="{ 'disabled': pageIndex >= totalPages }" v-on:click="changePage(pageIndex + 1)" title="下一頁">
                            <i class="fas fa-angle-right"></i>
                        </button>
                        <button type="button" class="page-pill" :class="{ 'disabled': pageIndex >= totalPages }" v-on:click="changePage(totalPages)" title="最末頁">
                            <i class="fas fa-angle-double-right"></i>
                        </button>
                    </div>
                </div>
            </div>
        </main>

        <!-- 4. 快速預覽彈窗 (Detail Modal) -->
        <div class="modal fade" id="previewModal" tabindex="-1" role="dialog" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered modal-lg" role="document">
                <div class="modal-content" style="border-radius: 12px; overflow: hidden; border: none;">
                    <div class="modal-custom-header">
                        <h5 class="modal-custom-title">
                            <i class="fas fa-file-alt text-white"></i>
                            <span>回報單詳細資訊 (#{{ previewItem.Report_NO }})</span>
                        </h5>
                        <button type="button" class="close text-white" data-dismiss="modal" aria-label="Close" style="opacity: 0.9;">
                            <span aria-hidden="true">&times;</span>
                        </button>
                    </div>

                    <div class="modal-body p-4">
                        <div class="row">
                            <div class="col-md-6 mb-3">
                                <label class="text-muted small font-weight-bold d-block">公私場所名稱</label>
                                <div class="font-weight-bold text-dark" style="font-size: 1.05rem;">{{ previewItem.FAC_NAME }}</div>
                            </div>
                            <div class="col-md-6 mb-3">
                                <label class="text-muted small font-weight-bold d-block">管制編號 / 行政區</label>
                                <div>
                                    <span class="badge-cno mr-2">{{ previewItem.C_NO || '-' }}</span>
                                    <span class="font-weight-bold">{{ previewItem.ADDR_TOWN }}</span>
                                </div>
                            </div>
                            <div class="col-md-6 mb-3">
                                <label class="text-muted small font-weight-bold d-block">回報類型</label>
                                <div>
                                    <span v-if="previewItem.Report_Type === '自主回報'" class="badge-type-own">
                                        <i class="fas fa-check-circle"></i> 自主回報
                                    </span>
                                    <span v-else class="badge-type-wrong">
                                        <i class="fas fa-exclamation-triangle"></i> 缺失改善
                                    </span>
                                </div>
                            </div>
                            <div class="col-md-6 mb-3">
                                <label class="text-muted small font-weight-bold d-block">回報時間</label>
                                <div class="font-weight-bold text-dark">{{ previewItem.Report_Date }}</div>
                            </div>
                            <div class="col-md-6 mb-3">
                                <label class="text-muted small font-weight-bold d-block">場所代碼 (FAC_ID)</label>
                                <div class="font-weight-bold text-secondary">{{ previewItem.FAC_ID }}</div>
                            </div>
                            <div class="col-md-6 mb-3">
                                <label class="text-muted small font-weight-bold d-block">關聯查核單號 (INV_NO)</label>
                                <div class="font-weight-bold text-secondary">{{ previewItem.INV_NO ? 'INV-' + previewItem.INV_NO : '無關聯查核單' }}</div>
                            </div>
                            <div class="col-12 mb-2" v-if="previewItem.ADDR">
                                <label class="text-muted small font-weight-bold d-block">場所地址</label>
                                <div class="text-dark">{{ previewItem.ADDR }}</div>
                            </div>
                        </div>
                    </div>

                    <div class="modal-footer bg-light" style="border-top: 1px solid #e2e8f0;">
                        <button type="button" class="btn btn-secondary btn-sm" data-dismiss="modal">關閉視窗</button>
                        <a :href="previewItem.DetailUrl" class="btn btn-primary btn-sm font-weight-bold">
                            <i class="fas fa-external-link-alt mr-1"></i> 前往完整表單內容
                        </a>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- 本地端核心依賴 (避開資安 CSP 阻擋，遵循 GEMINI.md 鐵律) -->
    <script src="../Scripts/jquery.min.js"></script>
    <script src="../Scripts/bootstrap.bundle.min.js"></script>
    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>

    <script>
        const { createApp } = Vue;

        createApp({
            data() {
                // 從 URL 取得預設 mode 參數 (own 或 wrong)
                const urlParams = new URLSearchParams(window.location.search);
                const initialMode = urlParams.get('mode') || 'all';

                return {
                    currentMode: initialMode,
                    loading: false,
                    list: [],
                    totalCount: 0,
                    pageIndex: 1,
                    pageSize: 20,
                    totalPages: 1,
                    facList: [],
                    userInfo: {
                        UserId: '',
                        FacId: '',
                        FacName: '',
                        IsAdmin: true
                    },
                    counts: {
                        TotalCount: 0,
                        OwnCount: 0,
                        WrongCount: 0,
                        MonthCount: 0
                    },
                    activeDateRange: 'month',
                    filter: {
                        FacId: 'ALL',
                        DateS: '',
                        DateE: '',
                        Keyword: ''
                    },
                    previewItem: {}
                };
            },
            computed: {
                visiblePages() {
                    const pages = [];
                    const max = 5;
                    let start = Math.max(1, this.pageIndex - Math.floor(max / 2));
                    let end = Math.min(this.totalPages, start + max - 1);
                    if (end - start + 1 < max) {
                        start = Math.max(1, end - max + 1);
                    }
                    for (let i = start; i <= end; i++) {
                        pages.push(i);
                    }
                    return pages;
                }
            },
            mounted() {
                this.initDefaultDateRange();
                this.loadUserInfo();
                this.loadCounts();
                this.loadFacs();
                this.loadList();
            },
            methods: {
                // 初始化預設為當月日期
                initDefaultDateRange() {
                    this.setDateRange('month');
                },

                // 設定日期快捷區間
                setDateRange(type) {
                    this.activeDateRange = type;
                    const now = new Date();
                    const fmt = d => d.toISOString().split('T')[0];

                    if (type === 'today') {
                        this.filter.DateS = fmt(now);
                        this.filter.DateE = fmt(now);
                    } else if (type === '7d') {
                        const s = new Date();
                        s.setDate(now.getDate() - 7);
                        this.filter.DateS = fmt(s);
                        this.filter.DateE = fmt(now);
                    } else if (type === 'month') {
                        const s = new Date(now.getFullYear(), now.getMonth(), 1);
                        this.filter.DateS = fmt(s);
                        this.filter.DateE = fmt(now);
                    } else if (type === '3m') {
                        const s = new Date(now.getFullYear(), now.getMonth() - 3, 1);
                        this.filter.DateS = fmt(s);
                        this.filter.DateE = fmt(now);
                    } else if (type === 'all') {
                        this.filter.DateS = '';
                        this.filter.DateE = '';
                    }
                },

                // 取得使用者資訊與權限
                async loadUserInfo() {
                    try {
                        const res = await axios.get('PIC_Report_List.aspx?action=getuserinfo');
                        if (res.data && res.data.Success) {
                            this.userInfo = res.data.Data;
                            if (this.userInfo.FacId && !this.userInfo.IsAdmin) {
                                this.filter.FacId = this.userInfo.FacId;
                            }
                        }
                    } catch (e) {
                        console.error('載入使用者資訊失敗', e);
                    }
                },

                // 取得各類別統計計數
                async loadCounts() {
                    try {
                        const res = await axios.get('PIC_Report_List.aspx?action=getcounts');
                        if (res.data && res.data.Success) {
                            this.counts = res.data.Data;
                        }
                    } catch (e) {
                        console.error('載入統計數據失敗', e);
                    }
                },

                // 取得公私場所清單
                async loadFacs() {
                    try {
                        const res = await axios.get('PIC_Report_List.aspx?action=getfacs');
                        if (res.data && res.data.Success) {
                            this.facList = res.data.Data;
                        }
                    } catch (e) {
                        console.error('載入場所清單失敗', e);
                    }
                },

                // 取得分頁回報資料列表
                async loadList() {
                    this.loading = true;
                    try {
                        const payload = {
                            mode: this.currentMode,
                            facId: this.filter.FacId,
                            dateS: this.filter.DateS,
                            dateE: this.filter.DateE,
                            keyword: this.filter.Keyword,
                            pageIndex: this.pageIndex,
                            pageSize: this.pageSize
                        };

                        const res = await axios.post('PIC_Report_List.aspx?action=getlist', payload);
                        if (res.data && res.data.Success) {
                            const data = res.data.Data;
                            this.list = data.Items || [];
                            this.totalCount = data.TotalCount || 0;
                            this.totalPages = data.TotalPages || 1;
                        } else {
                            alert(res.data.Message || '載入資料失敗');
                        }
                    } catch (e) {
                        console.error('查詢列表出錯', e);
                        alert('載入資料發生錯誤，請稍後再試');
                    } finally {
                        this.loading = false;
                    }
                },

                // 模式標籤切換
                setMode(mode) {
                    if (this.currentMode === mode) return;
                    this.currentMode = mode;
                    this.pageIndex = 1;
                    this.loadList();
                },

                // 套用查詢
                applyFilter() {
                    this.pageIndex = 1;
                    this.loadList();
                },

                // 重設條件
                resetFilter() {
                    this.filter.Keyword = '';
                    if (this.userInfo.FacId && !this.userInfo.IsAdmin) {
                        this.filter.FacId = this.userInfo.FacId;
                    } else {
                        this.filter.FacId = 'ALL';
                    }
                    this.setDateRange('month');
                    this.pageIndex = 1;
                    this.loadList();
                },

                // 刷新
                refreshData() {
                    this.loadCounts();
                    this.loadList();
                },

                // 換頁
                changePage(page) {
                    if (page < 1 || page > this.totalPages || page === this.pageIndex) return;
                    this.pageIndex = page;
                    this.loadList();
                    window.scrollTo({ top: 0, behavior: 'smooth' });
                },

                // 每頁筆數調整
                onPageSizeChange() {
                    this.pageIndex = 1;
                    this.loadList();
                },

                // 開啟快速預覽
                async openPreview(item) {
                    this.previewItem = Object.assign({}, item);
                    $('#previewModal').modal('show');
                    try {
                        const res = await axios.get('PIC_Report_List.aspx?action=getpreview&id=' + encodeURIComponent(item.FAC_ID) + '&rep=' + item.Report_NO);
                        if (res.data && res.data.Success) {
                            this.previewItem = res.data.Data;
                        }
                    } catch (e) {
                        console.error('取得預覽詳情失敗', e);
                    }
                },

                // 新增回報跳轉
                openNewReport() {
                    let facId = this.filter.FacId;
                    if (facId === 'ALL') {
                        if (this.facList.length > 0) {
                            facId = this.facList[0].FacId;
                        } else {
                            alert('請先選取欲回報之公私場所');
                            return;
                        }
                    }
                    const targetMode = this.currentMode === 'wrong' ? 'wrong' : 'own';
                    window.location.href = 'PIC_Report.aspx?mode=' + targetMode + '&id=' + encodeURIComponent(facId);
                },

                // 匯出 Excel
                exportExcel() {
                    const params = new URLSearchParams({
                        action: 'export',
                        mode: this.currentMode,
                        facId: this.filter.FacId,
                        dateS: this.filter.DateS,
                        dateE: this.filter.DateE,
                        keyword: this.filter.Keyword
                    });
                    window.open('PIC_Report_List.aspx?' + params.toString(), '_blank');
                }
            }
        }).mount('#app');
    </script>
</body>
</html>
