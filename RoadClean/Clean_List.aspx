<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Clean_List.aspx.cs" Inherits="NTPC_FEC.RoadClean.Clean_List" %>

<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定溢散源管理平台 - 道路潔淨巡檢列表</title>

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

        /* 模式切換頁籤 */
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

        /* 評分晶片 Badge - 嚴格單行不換行 */
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

        /* 狀態徽章 */
        .status-chip {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 4px 10px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 700;
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
    </style>
</head>
<body>
    <div id="listApp" v-cloak>
        <!-- 頂部品牌導覽列 -->
        <header class="top-navbar">
            <a href="Clean_List.aspx" class="navbar-brand-title">
                <i class="fas fa-broom"></i>
                <span>新北市固定溢散源 - 道路潔淨巡檢</span>
            </a>
            <div class="d-flex align-items-center gap-2">
                <a :href="'NewCleanChk.aspx?mode=new&listMode=' + currentMode" class="btn btn-warning font-weight-bold text-dark px-3 shadow-sm mr-2" style="border-radius: 8px;">
                    <i class="fas fa-plus-circle"></i>
                    <span class="d-none d-sm-inline ml-1">新增巡檢</span>
                </a>
                <a href="../MainPage.aspx?sub=menu4" class="btn btn-outline-light font-weight-bold px-3" style="border-radius: 8px;">
                    <i class="fas fa-chevron-left"></i>
                    <span class="d-none d-sm-inline ml-1">回選單</span>
                </a>
            </div>
        </header>

        <!-- 業務模式分頁切換列 -->
        <nav class="nav-mode-bar">
            <div class="nav-mode-item" :class="{ 'active': currentMode === 'apply' }" v-on:click="switchMode('apply')">
                <i class="fas fa-edit"></i>
                <span>查核紀錄暫存 (草稿)</span>
                <span class="tab-badge badge badge-secondary">{{ counts.Apply }}</span>
            </div>
            <div class="nav-mode-item" :class="{ 'active': currentMode === 'back' }" v-on:click="switchMode('back')">
                <i class="fas fa-undo-alt"></i>
                <span>退回補正案件</span>
                <span class="tab-badge badge badge-warning text-dark">{{ counts.Back }}</span>
            </div>
            <div class="nav-mode-item" :class="{ 'active': currentMode === 'examine' }" v-on:click="switchMode('examine')">
                <i class="fas fa-clipboard-check"></i>
                <span>案件審核</span>
                <span class="tab-badge badge badge-primary">{{ counts.Examine }}</span>
            </div>
            <div class="nav-mode-item" :class="{ 'active': currentMode === 'search' }" v-on:click="switchMode('search')">
                <i class="fas fa-check-circle"></i>
                <span>調查成果列表</span>
                <span class="tab-badge badge badge-success">{{ counts.Search }}</span>
            </div>
            <div class="nav-mode-item" :class="{ 'active': currentMode === 'all' }" v-on:click="switchMode('all')">
                <i class="fas fa-layer-group"></i>
                <span>全部案件</span>
                <span class="tab-badge badge badge-dark">{{ counts.Total }}</span>
            </div>
        </nav>

        <main class="container-fluid py-4 px-lg-4">
            <!-- 頂部統計指標卡片 -->
            <div class="row mb-3">
                <div class="col-6 col-lg-3 mb-2 mb-lg-0">
                    <div class="stat-card" v-on:click="switchMode('apply')" style="cursor: pointer;">
                        <div class="stat-icon bg-light text-secondary">
                            <i class="fas fa-file-signature"></i>
                        </div>
                        <div>
                            <div class="stat-val">{{ counts.Apply }}</div>
                            <div class="stat-label">暫存草稿 / 駁回</div>
                        </div>
                    </div>
                </div>
                <div class="col-6 col-lg-3 mb-2 mb-lg-0">
                    <div class="stat-card" v-on:click="switchMode('examine')" style="cursor: pointer;">
                        <div class="stat-icon bg-primary text-white">
                            <i class="fas fa-clock"></i>
                        </div>
                        <div>
                            <div class="stat-val text-primary">{{ counts.Examine }}</div>
                            <div class="stat-label">待審核案件</div>
                        </div>
                    </div>
                </div>
                <div class="col-6 col-lg-3 mb-2 mb-lg-0">
                    <div class="stat-card" v-on:click="switchMode('back')" style="cursor: pointer;">
                        <div class="stat-icon bg-warning text-dark">
                            <i class="fas fa-exclamation-triangle"></i>
                        </div>
                        <div>
                            <div class="stat-val text-warning">{{ counts.Back }}</div>
                            <div class="stat-label">待補正案件</div>
                        </div>
                    </div>
                </div>
                <div class="col-6 col-lg-3 mb-2 mb-lg-0">
                    <div class="stat-card" v-on:click="switchMode('search')" style="cursor: pointer;">
                        <div class="stat-icon bg-success text-white">
                            <i class="fas fa-check-double"></i>
                        </div>
                        <div>
                            <div class="stat-val text-success">{{ counts.Search }}</div>
                            <div class="stat-label">已審核通過</div>
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
                        <div class="col-12 col-md-4 mb-3">
                            <label class="font-weight-bold text-muted small mb-1">
                                <i class="fas fa-map-marker-alt text-danger mr-1"></i> 行政區
                            </label>
                            <select class="form-control" v-model="filter.selectedTown" style="font-weight: 600;">
                                <option value="">全部行政區 ({{ towns.length }} 區)</option>
                                <option v-for="t in towns" :key="t.TownNo" :value="t.TownName">
                                    {{ t.TownName }} ({{ t.TownNo }})
                                </option>
                            </select>
                        </div>

                        <!-- 巡檢道路關鍵字 -->
                        <div class="col-12 col-md-4 mb-3">
                            <label class="font-weight-bold text-muted small mb-1">
                                <i class="fas fa-road text-info mr-1"></i> 巡檢道路名稱
                            </label>
                            <input type="text" class="form-control" v-model="filter.roadName" placeholder="例如：中正路、民權路..." v-on:keyup.enter="handleSearch" />
                        </div>

                        <!-- 日期區間 (寬度與高度完全對齊左側欄位) -->
                        <div class="col-12 col-md-4 mb-3">
                            <label class="font-weight-bold text-muted small mb-1">
                                <i class="far fa-calendar-alt text-primary mr-1"></i> 巡查起訖日期
                            </label>
                            <div class="d-flex align-items-center" style="width: 100%;">
                                <input type="date" class="form-control" style="flex: 1; min-width: 0;" v-model="filter.dateS" />
                                <span class="mx-2 text-muted font-weight-bold">~</span>
                                <input type="date" class="form-control" style="flex: 1; min-width: 0;" v-model="filter.dateE" />
                            </div>
                        </div>
                    </div>

                    <!-- 快捷日期按鈕與搜尋列 -->
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

            <!-- 批次快速審核/批次送件工具列 -->
            <div v-if="hasBatchAction || selectedChkIds.length > 0" class="batch-action-bar">
                <div class="d-flex align-items-center gap-3">
                    <div class="custom-control custom-checkbox ml-2">
                        <input type="checkbox" class="custom-control-input" id="chkAllBatch" :checked="isAllSelected" v-on:change="toggleSelectAll" />
                        <label class="custom-control-label font-weight-bold" for="chkAllBatch">
                            全選本頁 (已選取 {{ selectedChkIds.length }} 筆)
                        </label>
                    </div>
                </div>
                <div class="d-flex align-items-center gap-2">
                    <button type="button" class="btn btn-sm btn-outline-light font-weight-bold" v-on:click="clearSelection" :disabled="selectedChkIds.length === 0">
                        清除選取
                    </button>
                    <!-- examine 模式：批次審核通過 -->
                    <button v-if="currentMode === 'examine'" type="button" class="btn btn-sm btn-warning font-weight-bold text-dark px-3 shadow" :disabled="selectedChkIds.length === 0" v-on:click="openBatchExamineModal">
                        <i class="fas fa-bolt mr-1"></i> 批次審核通過
                    </button>
                    <!-- apply / back 模式：批次送出審查 (批次送件) -->
                    <button v-if="currentMode === 'apply' || currentMode === 'back'" type="button" class="btn btn-sm btn-primary font-weight-bold px-3 shadow" :disabled="selectedChkIds.length === 0" v-on:click="openBatchPutCheckModal">
                        <i class="fas fa-paper-plane mr-1"></i> 批次送出審查 (批次送件)
                    </button>
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
                    <div>
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
                        <h5 class="font-weight-bold text-secondary">查無符合條件的巡檢紀錄</h5>
                        <p class="text-muted small">請嘗試放寬篩選條件或點選「不限日期」。</p>
                        <a :href="'NewCleanChk.aspx?mode=new&listMode=' + currentMode" class="btn btn-primary font-weight-bold px-4 mt-2">
                            <i class="fas fa-plus mr-1"></i> 建立第一筆現場巡檢
                        </a>
                    </div>

                    <!-- 寬螢幕桌面端表格 (Desktop & Tablet) -->
                    <div v-else class="table-responsive d-none d-md-block">
                        <table class="table-modern">
                            <thead>
                                <tr>
                                    <th v-if="hasBatchAction" style="width: 48px;" class="text-center">選取</th>
                                    <th style="width: 160px;">巡檢編號</th>
                                    <th style="width: 90px;">行政區</th>
                                    <th style="width: 150px; min-width: 120px;">巡檢道路</th>
                                    <th style="width: 140px;">巡檢日期</th>
                                    <th style="width: 130px;">檢核點明細</th>
                                    <th style="width: 160px; min-width: 155px; white-space: nowrap;">道路評級</th>
                                    <th style="width: 160px; min-width: 155px; white-space: nowrap;">淹水評級</th>
                                    <th style="width: 110px;">案件階段</th>
                                    <th style="min-width: 220px; width: 220px; white-space: nowrap;" class="text-center">操作功能</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr v-for="item in list" :key="item.ChkId">
                                    <!-- 批次核取方塊 -->
                                    <td v-if="hasBatchAction" class="text-center">
                                        <div v-if="isItemSelectable(item)" class="custom-control custom-checkbox">
                                            <input type="checkbox" class="custom-control-input" :id="'chk_' + item.ChkId" :value="item.ChkId" v-model="selectedChkIds" />
                                            <label class="custom-control-label" :for="'chk_' + item.ChkId"></label>
                                        </div>
                                    </td>

                                    <!-- 巡檢編號 -->
                                    <td>
                                        <div class="font-weight-bold text-dark">{{ item.ChkId }}</div>
                                        <small class="text-muted">填報員: {{ item.CreateUser || '未登錄' }}</small>
                                    </td>

                                    <!-- 行政區 -->
                                    <td>
                                        <span class="town-chip">{{ item.Town }}</span>
                                    </td>

                                    <!-- 巡檢道路 -->
                                    <td>
                                        <div class="font-weight-bold text-dark" style="font-size: 15px;">{{ item.RoadName }}</div>
                                    </td>

                                    <!-- 巡檢日期 -->
                                    <td>
                                        <div class="small font-weight-bold text-secondary">{{ item.ChkDate }}</div>
                                    </td>

                                    <!-- 檢核點明細 -->
                                    <td>
                                        <button type="button" class="btn btn-sm btn-light border py-1 px-2 font-weight-bold small text-primary" v-on:click="openPointModal(item)">
                                            <i class="fas fa-map-pin mr-1"></i> {{ item.PointCount }} 個檢核點
                                        </button>
                                    </td>

                                    <!-- 道路潔淨評級 -->
                                    <td style="white-space: nowrap;">
                                        <span class="score-badge" :class="getScoreClass(item.RoadScore)">
                                            <i :class="getScoreIcon(item.RoadScore)"></i>
                                            <span>{{ item.RoadScore >= 0 ? item.RoadScore + ' 分' : '未評' }} ({{ item.RoadScoreLv }})</span>
                                        </span>
                                    </td>

                                    <!-- 淹水潛勢評級 -->
                                    <td style="white-space: nowrap;">
                                        <span class="score-badge" :class="getScoreClass(item.FloodScore)">
                                            <i :class="getScoreIcon(item.FloodScore)"></i>
                                            <span>{{ item.FloodScore >= 0 ? item.FloodScore + ' 分' : '未評' }} ({{ item.FloodScoreLv }})</span>
                                        </span>
                                    </td>

                                    <!-- 案件階段狀態 -->
                                    <td>
                                        <span class="badge px-2 py-1 font-weight-bold" :class="item.StateBadge" style="font-size: 12px;">
                                            {{ item.StateName }}
                                        </span>
                                        <div v-if="item.ExamineMemo" class="small text-danger font-weight-bold mt-1" :title="item.ExamineMemo">
                                            <i class="fas fa-info-circle mr-1"></i>退回意見
                                        </div>
                                    </td>

                                    <!-- 功能按鈕 -->
                                    <td class="text-center" style="white-space: nowrap;">
                                        <div class="action-btn-group justify-content-center">
                                            <!-- 草稿(1001) / 退回(2301) 狀態 -->
                                            <template v-if="item.CaseState === 1001 || item.CaseState === 2301">
                                                <a :href="'NewCleanChk.aspx?mode=edit&chkId=' + item.ChkId + '&listMode=' + currentMode" class="btn btn-sm btn-warning btn-action text-dark font-weight-bold" title="編輯修改">
                                                    <i class="fas fa-pencil-alt"></i> 編輯
                                                </a>
                                                <button type="button" class="btn btn-sm btn-primary btn-action font-weight-bold" v-on:click="openPutCheckModal(item)" title="送出審查">
                                                    <i class="fas fa-paper-plane"></i> 送審
                                                </button>
                                                <button v-if="item.CaseState === 1001" type="button" class="btn btn-sm btn-outline-danger btn-action" v-on:click="openDeleteModal(item)" title="刪除草稿">
                                                    <i class="fas fa-trash-alt"></i>
                                                </button>
                                            </template>

                                            <!-- 待審核(2001) 狀態 -->
                                            <template v-else-if="item.CaseState === 2001">
                                                <button type="button" class="btn btn-sm btn-success btn-action font-weight-bold shadow-sm" v-on:click="openExamineModal(item)" title="進行審核">
                                                    <i class="fas fa-stamp"></i> 審核
                                                </button>
                                                <a :href="'NewCleanChk.aspx?mode=read&chkId=' + item.ChkId + '&listMode=' + currentMode" class="btn btn-sm btn-info btn-action font-weight-bold" title="檢視詳細">
                                                    <i class="fas fa-eye"></i> 檢視
                                                </a>
                                            </template>

                                            <!-- 已審核通過(2101) 或 駁回(2201) -->
                                            <template v-else>
                                                <a :href="'NewCleanChk.aspx?mode=read&chkId=' + item.ChkId + '&listMode=' + currentMode" class="btn btn-sm btn-info btn-action font-weight-bold" title="檢視詳細">
                                                    <i class="fas fa-file-alt"></i> 詳細資料
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
                        <div v-for="item in list" :key="item.ChkId" class="mobile-card">
                            <div class="mobile-card-header">
                                <div class="d-flex align-items-center gap-2">
                                    <div v-if="hasBatchAction && isItemSelectable(item)" class="custom-control custom-checkbox d-inline-block mr-1">
                                        <input type="checkbox" class="custom-control-input" :id="'chk_m_' + item.ChkId" :value="item.ChkId" v-model="selectedChkIds" />
                                        <label class="custom-control-label" :for="'chk_m_' + item.ChkId"></label>
                                    </div>
                                    <span class="town-chip">{{ item.Town }}</span>
                                    <span class="font-weight-bold text-dark">{{ item.ChkId }}</span>
                                </div>
                                <span class="badge px-2 py-1 font-weight-bold" :class="item.StateBadge">
                                    {{ item.StateName }}
                                </span>
                            </div>

                            <h3 class="mobile-card-title mb-2">{{ item.RoadName }}</h3>
                            <div class="small text-muted mb-2">
                                <i class="far fa-clock mr-1"></i> {{ item.ChkDate }} 
                                <span class="ml-2"><i class="fas fa-user-edit mr-1"></i> {{ item.CreateUser }}</span>
                            </div>

                            <!-- 評級晶片 -->
                            <div class="d-flex flex-wrap gap-2 mb-3">
                                <span class="score-badge" :class="getScoreClass(item.RoadScore)">
                                    <i :class="getScoreIcon(item.RoadScore)"></i>
                                    潔淨: {{ item.RoadScore >= 0 ? item.RoadScore + '分' : '未評' }} ({{ item.RoadScoreLv }})
                                </span>
                                <span class="score-badge" :class="getScoreClass(item.FloodScore)">
                                    <i :class="getScoreIcon(item.FloodScore)"></i>
                                    淹水: {{ item.FloodScore >= 0 ? item.FloodScore + '分' : '未評' }} ({{ item.FloodScoreLv }})
                                </span>
                                <button type="button" class="btn btn-sm btn-light border py-1 px-2 font-weight-bold small text-primary" v-on:click="openPointModal(item)">
                                    {{ item.PointCount }} 點位
                                </button>
                            </div>

                            <!-- 退回意見提示 -->
                            <div v-if="item.ExamineMemo" class="alert alert-warning py-2 px-3 small font-weight-bold mb-3">
                                <i class="fas fa-exclamation-triangle mr-1"></i> 審核意見：{{ item.ExamineMemo }}
                            </div>

                            <!-- 手機動作按鈕列 -->
                            <div class="action-btn-group pt-2 border-top">
                                <template v-if="item.CaseState === 1001 || item.CaseState === 2301">
                                    <a :href="'NewCleanChk.aspx?mode=edit&chkId=' + item.ChkId + '&listMode=' + currentMode" class="btn btn-warning btn-action text-dark font-weight-bold">
                                        <i class="fas fa-pencil-alt"></i> 編輯修改
                                    </a>
                                    <button type="button" class="btn btn-primary btn-action font-weight-bold" v-on:click="openPutCheckModal(item)">
                                        <i class="fas fa-paper-plane"></i> 送審
                                    </button>
                                    <button v-if="item.CaseState === 1001" type="button" class="btn btn-outline-danger btn-action" v-on:click="openDeleteModal(item)">
                                        <i class="fas fa-trash-alt"></i> 刪除
                                    </button>
                                </template>
                                <template v-else-if="item.CaseState === 2001">
                                    <button type="button" class="btn btn-success btn-action font-weight-bold shadow-sm" v-on:click="openExamineModal(item)">
                                        <i class="fas fa-stamp"></i> 案件審核
                                    </button>
                                    <a :href="'NewCleanChk.aspx?mode=read&chkId=' + item.ChkId + '&listMode=' + currentMode" class="btn btn-info btn-action font-weight-bold">
                                        <i class="fas fa-eye"></i> 檢視
                                    </a>
                                </template>
                                <template v-else>
                                    <a :href="'NewCleanChk.aspx?mode=read&chkId=' + item.ChkId + '&listMode=' + currentMode" class="btn btn-info btn-action font-weight-bold">
                                        <i class="fas fa-file-alt"></i> 詳細資料
                                    </a>
                                </template>
                            </div>
                        </div>
                    </div>

                    <!-- 分頁導覽列 (Server-side Pagination) -->
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

        <!-- 1. 案件審核對話框 (Examine Modal) -->
        <div class="modal fade" id="examineModal" tabindex="-1" role="dialog" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered" role="document">
                <div class="modal-content border-0 shadow-lg" style="border-radius: 12px;">
                    <div class="modal-header bg-primary text-white" style="border-radius: 12px 12px 0 0;">
                        <h5 class="modal-title font-weight-bold">
                            <i class="fas fa-stamp mr-1"></i> 道路潔淨巡檢 - 案件審查
                        </h5>
                        <button type="button" class="close text-white" data-dismiss="modal" aria-label="Close">
                            <span aria-hidden="true">&times;</span>
                        </button>
                    </div>
                    <div class="modal-body p-4" v-if="activeItem">
                        <div class="bg-light p-3 rounded mb-3 border">
                            <div class="font-weight-bold text-dark" style="font-size: 15px;">{{ activeItem.ChkId }} - {{ activeItem.RoadName }}</div>
                            <div class="small text-muted mt-1">
                                行政區：<span class="town-chip mr-2">{{ activeItem.Town }}</span>
                                巡查時間：{{ activeItem.ChkDate }}
                            </div>
                        </div>

                        <div class="form-group">
                            <label class="font-weight-bold text-dark">審查結果決定：</label>
                            <div class="d-flex gap-2">
                                <button type="button" class="btn flex-fill font-weight-bold" 
                                        :class="examineForm.result === 2101 ? 'btn-success shadow-sm' : 'btn-outline-success'" 
                                        v-on:click="examineForm.result = 2101">
                                    <i class="fas fa-check-circle mr-1"></i> 通過 (2101)
                                </button>
                                <button type="button" class="btn flex-fill font-weight-bold" 
                                        :class="examineForm.result === 2301 ? 'btn-warning text-dark shadow-sm' : 'btn-outline-warning text-dark'" 
                                        v-on:click="examineForm.result = 2301">
                                    <i class="fas fa-undo mr-1"></i> 退回補正 (2301)
                                </button>
                                <button type="button" class="btn flex-fill font-weight-bold" 
                                        :class="examineForm.result === 2201 ? 'btn-danger shadow-sm' : 'btn-outline-danger'" 
                                        v-on:click="examineForm.result = 2201">
                                    <i class="fas fa-times-circle mr-1"></i> 駁回 (2201)
                                </button>
                            </div>
                        </div>

                        <div class="form-group mb-0">
                            <label class="font-weight-bold text-dark">
                                審查備忘錄 / 意見說明：
                                <span v-if="examineForm.result !== 2101" class="text-danger small">* 退回或駁回時請具體載明原因</span>
                            </label>
                            <textarea class="form-control" rows="3" v-model="examineForm.memo" placeholder="請輸入審查意見或修正指示..."></textarea>
                        </div>
                    </div>
                    <div class="modal-footer bg-light" style="border-radius: 0 0 12px 12px;">
                        <button type="button" class="btn btn-secondary font-weight-bold px-3" data-dismiss="modal">取消</button>
                        <button type="button" class="btn btn-primary font-weight-bold px-4" :disabled="submitting" v-on:click="submitExamine">
                            <span v-if="!submitting">確定送出審查</span>
                            <span v-else>處理中...</span>
                        </button>
                    </div>
                </div>
            </div>
        </div>

        <!-- 2. 批次審核通過確認視窗 (Batch Examine Modal) -->
        <div class="modal fade" id="batchExamineModal" tabindex="-1" role="dialog" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered" role="document">
                <div class="modal-content border-0 shadow-lg" style="border-radius: 12px;">
                    <div class="modal-header bg-warning text-dark" style="border-radius: 12px 12px 0 0;">
                        <h5 class="modal-title font-weight-bold">
                            <i class="fas fa-bolt mr-1"></i> 批次快速審核通過確認
                        </h5>
                        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                            <span aria-hidden="true">&times;</span>
                        </button>
                    </div>
                    <div class="modal-body p-4">
                        <p class="font-weight-bold text-dark mb-2">
                            您即將批次審核通過下列 <strong class="text-primary">{{ selectedChkIds.length }}</strong> 筆案件：
                        </p>
                        <div class="p-2 bg-light border rounded mb-3" style="max-height: 120px; overflow-y: auto;">
                            <span v-for="id in selectedChkIds" :key="id" class="badge badge-secondary mr-1 mb-1 p-1">
                                {{ id }}
                            </span>
                        </div>
                        <div class="form-group mb-0">
                            <label class="font-weight-bold text-dark">批次審查備忘錄：</label>
                            <input type="text" class="form-control" v-model="batchMemo" placeholder="快速審查通過" />
                        </div>
                    </div>
                    <div class="modal-footer bg-light" style="border-radius: 0 0 12px 12px;">
                        <button type="button" class="btn btn-secondary font-weight-bold" data-dismiss="modal">取消</button>
                        <button type="button" class="btn btn-success font-weight-bold px-4" :disabled="submitting" v-on:click="submitBatchExamine">
                            <span v-if="!submitting">確認一鍵全部通過</span>
                            <span v-else>處理中...</span>
                        </button>
                    </div>
                </div>
            </div>
        </div>

        <!-- 2.5 批次送出審查 (批次送件) 確認視窗 -->
        <div class="modal fade" id="batchPutCheckModal" tabindex="-1" role="dialog" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered" role="document">
                <div class="modal-content border-0 shadow-lg" style="border-radius: 12px;">
                    <div class="modal-header bg-primary text-white" style="border-radius: 12px 12px 0 0;">
                        <h5 class="modal-title font-weight-bold">
                            <i class="fas fa-paper-plane mr-1"></i> 批次送出審查 (批次送件)
                        </h5>
                        <button type="button" class="close text-white" data-dismiss="modal" aria-label="Close">
                            <span aria-hidden="true">&times;</span>
                        </button>
                    </div>
                    <div class="modal-body p-4">
                        <p class="font-weight-bold text-dark mb-2">
                            您即將批次送出審查下列 <strong class="text-primary">{{ selectedChkIds.length }}</strong> 筆巡檢案件：
                        </p>
                        <div class="p-2 bg-light border rounded mb-3" style="max-height: 120px; overflow-y: auto;">
                            <span v-for="id in selectedChkIds" :key="id" class="badge badge-secondary mr-1 mb-1 p-1">
                                {{ id }}
                            </span>
                        </div>
                        <div class="alert alert-warning py-2 px-3 small font-weight-bold mb-0">
                            <i class="fas fa-shield-alt mr-1"></i> <strong>自動完整性與照片檢核防呆：</strong><br />
                            系統將自動逐筆檢核現場照片 (規定至少 2 張)、道路淹水潛勢照片 (至少 1 張) 及各點位題庫欄位。未填妥或缺照片之案件將被自動攔截並列出報告，唯有完全合格之案件才會送出審查。
                        </div>
                    </div>
                    <div class="modal-footer bg-light" style="border-radius: 0 0 12px 12px;">
                        <button type="button" class="btn btn-secondary font-weight-bold px-3" data-dismiss="modal">取消</button>
                        <button type="button" class="btn btn-primary font-weight-bold px-4" :disabled="submitting" v-on:click="submitBatchPutCheck">
                            <span v-if="!submitting"><i class="fas fa-check-circle mr-1"></i> 開始逐筆檢驗並送審</span>
                            <span v-else><i class="fas fa-spinner fa-spin mr-1"></i> 正在檢核送件中...</span>
                        </button>
                    </div>
                </div>
            </div>
        </div>

        <!-- 2.6 批次送件檢核結果報告對話框 (Batch Result Modal) -->
        <div class="modal fade" id="batchPutResultModal" tabindex="-1" role="dialog" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered modal-lg" role="document">
                <div class="modal-content border-0 shadow-lg" style="border-radius: 12px;">
                    <div class="modal-header bg-dark text-white" style="border-radius: 12px 12px 0 0;">
                        <h5 class="modal-title font-weight-bold">
                            <i class="fas fa-clipboard-check mr-2 text-warning"></i> 批次送件檢核結果報告
                        </h5>
                        <button type="button" class="close text-white" data-dismiss="modal" aria-label="Close">
                            <span aria-hidden="true">&times;</span>
                        </button>
                    </div>
                    <div class="modal-body p-4" v-if="batchResult">
                        <!-- 統計摘要卡片 -->
                        <div class="row mb-3">
                            <div class="col-6">
                                <div class="p-3 bg-light rounded border border-success text-center">
                                    <div class="small text-muted font-weight-bold">檢核合格並已送審</div>
                                    <div class="h3 font-weight-bold text-success mb-0">
                                        <i class="fas fa-check-circle mr-1"></i> {{ batchResult.PassedCount }} <small class="text-muted" style="font-size: 0.9rem;">筆</small>
                                    </div>
                                </div>
                            </div>
                            <div class="col-6">
                                <div class="p-3 bg-light rounded border border-danger text-center">
                                    <div class="small text-muted font-weight-bold">未達標準自動攔截</div>
                                    <div class="h3 font-weight-bold text-danger mb-0">
                                        <i class="fas fa-times-circle mr-1"></i> {{ batchResult.FailedCount }} <small class="text-muted" style="font-size: 0.9rem;">筆</small>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <div class="alert alert-info py-2 px-3 small font-weight-bold mb-3">
                            <i class="fas fa-info-circle mr-1"></i> {{ batchResult.Message }}
                        </div>

                        <!-- 攔截案件缺失明細清單 -->
                        <div v-if="batchResult.FailedCases && batchResult.FailedCases.length > 0">
                            <h6 class="font-weight-bold text-dark mb-2">
                                <i class="fas fa-exclamation-triangle text-danger mr-1"></i> 未符合標準之案件清單 (已保留於草稿，請點擊補正)：
                            </h6>
                            <div class="list-group" style="max-height: 280px; overflow-y: auto;">
                                <div v-for="(fc, idx) in batchResult.FailedCases" :key="idx" class="list-group-item list-group-item-action flex-column align-items-start p-3 mb-2 border rounded">
                                    <div class="d-flex w-100 justify-content-between align-items-center mb-1">
                                        <h6 class="mb-0 font-weight-bold text-dark">
                                            <span class="badge badge-secondary mr-2">{{ fc.ChkId }}</span>
                                            {{ fc.RoadName }}
                                        </h6>
                                        <a :href="'NewCleanChk.aspx?mode=edit&chkId=' + fc.ChkId + '&listMode=' + currentMode" target="_blank" class="btn btn-xs btn-outline-warning font-weight-bold">
                                            <i class="fas fa-pencil-alt mr-1"></i> 前往補件
                                        </a>
                                    </div>
                                    <ul class="mb-0 pl-3 mt-2 small">
                                        <li v-for="(err, eidx) in fc.Errors" :key="eidx" class="text-danger font-weight-bold mb-1">
                                            {{ err }}
                                        </li>
                                    </ul>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="modal-footer bg-light" style="border-radius: 0 0 12px 12px;">
                        <button type="button" class="btn btn-primary font-weight-bold px-4" data-dismiss="modal">我知道了</button>
                    </div>
                </div>
            </div>
        </div>

        <!-- 3. 送審前完整度與照片檢核防呆對話框 (PutCheck Modal) -->
        <div class="modal fade" id="putCheckModal" tabindex="-1" role="dialog" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered" role="document">
                <div class="modal-content border-0 shadow-lg" style="border-radius: 12px;">
                    <div class="modal-header bg-primary text-white" style="border-radius: 12px 12px 0 0;">
                        <h5 class="modal-title font-weight-bold">
                            <i class="fas fa-clipboard-check mr-1"></i> 送審完整度檢核確認
                        </h5>
                        <button type="button" class="close text-white" data-dismiss="modal" aria-label="Close">
                            <span aria-hidden="true">&times;</span>
                        </button>
                    </div>
                    <div class="modal-body p-4 text-center" v-if="activeItem">
                        <!-- 案件基本摘要 -->
                        <div class="p-3 bg-light rounded text-left mb-3 border">
                            <div class="font-weight-bold text-dark" style="font-size: 1.05rem;">
                                <i class="fas fa-road text-primary mr-1"></i> {{ activeItem.RoadName }}
                                <span class="badge badge-info ml-1">{{ activeItem.Town }}</span>
                            </div>
                            <div class="text-muted small mt-1">
                                查核單號：<span class="font-weight-bold text-secondary">{{ activeItem.ChkId }}</span>
                                <span class="mx-2">|</span>
                                巡查日期：{{ activeItem.ChkDate }}
                            </div>
                        </div>

                        <!-- 狀態 1: 正在防呆檢核 -->
                        <div v-if="checkingValidation" class="py-4 text-center">
                            <div class="spinner-border text-primary mb-3" role="status" style="width: 2.5rem; height: 2.5rem;">
                                <span class="sr-only">Loading...</span>
                            </div>
                            <div class="font-weight-bold text-dark">正在檢驗表單各欄位與照片完整度...</div>
                            <div class="text-muted small mt-1">檢查現場照片 (至少2張)、淹水照片 (至少1張) 及各點位指標評分</div>
                        </div>

                        <!-- 狀態 2: 檢核未通過 (明確阻擋) -->
                        <div v-else-if="validationResult && !validationResult.IsValid" class="text-left">
                            <div class="alert alert-danger border-danger shadow-sm mb-3">
                                <div class="d-flex align-items-center mb-2">
                                    <i class="fas fa-times-circle text-danger fa-2x mr-2"></i>
                                    <div>
                                        <h6 class="font-weight-bold text-danger mb-0">未達送審標準，系統已自動阻擋！</h6>
                                        <div class="small text-danger">該案件尚有表單欄位或必備照片未齊全：</div>
                                    </div>
                                </div>
                                <hr class="my-2 border-danger opacity-25" />
                                <ul class="mb-0 pl-3 small">
                                    <li v-for="(err, idx) in validationResult.Errors" :key="idx" class="font-weight-bold text-danger mb-1">
                                        {{ err }}
                                    </li>
                                </ul>
                            </div>
                            <div class="text-muted small mb-0 text-center">
                                <i class="fas fa-lightbulb text-warning mr-1"></i> 請點擊下方按鈕前往編輯頁面補齊資料與上傳照片後，再行送審。
                            </div>
                        </div>

                        <!-- 狀態 3: 檢核通過 (合格) -->
                        <div v-else-if="validationResult && validationResult.IsValid" class="text-left">
                            <div class="alert alert-success border-success shadow-sm mb-3">
                                <div class="d-flex align-items-center">
                                    <i class="fas fa-check-circle text-success fa-2x mr-3"></i>
                                    <div>
                                        <h6 class="font-weight-bold text-success mb-1">表單資料與照片檢核完全合格！</h6>
                                        <div class="small text-muted">點位評估欄位已填寫完整，現場照片 (已達2張) 與淹水潛勢照片均已正確上傳。</div>
                                    </div>
                                </div>
                            </div>
                            <div class="text-center font-weight-bold text-dark mt-2 mb-1">
                                是否確定將此巡檢紀錄正式送出審查？
                            </div>
                            <div class="text-center text-muted small">
                                送出後案件狀態將轉為「審查中」，呈送主管進行審查。
                            </div>
                        </div>
                    </div>
                    <div class="modal-footer bg-light" style="border-radius: 0 0 12px 12px;">
                        <!-- 未通過：前往補正按鈕 -->
                        <template v-if="validationResult && !validationResult.IsValid">
                            <button type="button" class="btn btn-secondary font-weight-bold px-3" data-dismiss="modal">關閉</button>
                            <a v-if="activeItem" :href="'NewCleanChk.aspx?mode=edit&chkId=' + activeItem.ChkId + '&listMode=' + currentMode" class="btn btn-warning font-weight-bold px-4 text-dark shadow-sm">
                                <i class="fas fa-pencil-alt mr-1"></i> 前往補齊資料與照片
                            </a>
                        </template>
                        <!-- 合格：確認送審按鈕 -->
                        <template v-else-if="validationResult && validationResult.IsValid">
                            <button type="button" class="btn btn-secondary font-weight-bold px-3 mr-2" data-dismiss="modal">取消</button>
                            <button type="button" class="btn btn-primary font-weight-bold px-4 shadow" :disabled="submitting" v-on:click="submitPutCheck">
                                <i class="fas fa-paper-plane mr-1"></i>
                                <span v-if="!submitting">確定送審</span>
                                <span v-else>處理中...</span>
                            </button>
                        </template>
                        <template v-else>
                            <button type="button" class="btn btn-secondary font-weight-bold px-3" data-dismiss="modal">取消</button>
                        </template>
                    </div>
                </div>
            </div>
        </div>

        <!-- 4. 刪除確認對話框 (Delete Modal) -->
        <div class="modal fade" id="deleteModal" tabindex="-1" role="dialog" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered" role="document">
                <div class="modal-content border-0 shadow" style="border-radius: 12px;">
                    <div class="modal-body p-4 text-center" v-if="activeItem">
                        <div class="text-danger mb-3" style="font-size: 3rem;">
                            <i class="fas fa-exclamation-circle"></i>
                        </div>
                        <h5 class="font-weight-bold text-dark mb-2">確定刪除此筆巡檢草稿？</h5>
                        <p class="text-muted small mb-4">
                            單號：{{ activeItem.ChkId }}（{{ activeItem.RoadName }}）<br />
                            注意：刪除後資料與手寫簽章檔案將永久移除，無法復原！
                        </p>
                        <div class="d-flex justify-content-center gap-2">
                            <button type="button" class="btn btn-secondary font-weight-bold px-4 mr-2" data-dismiss="modal">取消</button>
                            <button type="button" class="btn btn-danger font-weight-bold px-4" :disabled="submitting" v-on:click="submitDelete">
                                <span v-if="!submitting">確定刪除</span>
                                <span v-else>刪除中...</span>
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- 5. 檢核點明細彈窗 (Points Detail Modal - On-demand 極速加載) -->
        <div class="modal fade" id="pointModal" tabindex="-1" role="dialog" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered modal-lg" role="document">
                <div class="modal-content border-0 shadow-lg" style="border-radius: 12px;">
                    <div class="modal-header bg-dark text-white" style="border-radius: 12px 12px 0 0;">
                        <h5 class="modal-title font-weight-bold">
                            <i class="fas fa-map-marked-alt mr-1"></i> 檢核點評分細項清單
                        </h5>
                        <button type="button" class="close text-white" data-dismiss="modal" aria-label="Close">
                            <span aria-hidden="true">&times;</span>
                        </button>
                    </div>
                    <div class="modal-body p-3" v-if="activeItem">
                        <div class="d-flex justify-content-between align-items-center mb-3 p-2 bg-light rounded border">
                            <span class="font-weight-bold text-dark">{{ activeItem.ChkId }} - {{ activeItem.RoadName }}</span>
                            <span class="town-chip">{{ activeItem.Town }}</span>
                        </div>

                        <!-- 點位加載中 -->
                        <div v-if="pointLoading" class="text-center py-4">
                            <div class="spinner-border spinner-border-sm text-primary"></div>
                            <span class="ml-2 font-weight-bold text-muted">正在載入檢核點資料...</span>
                        </div>

                        <div v-else class="table-responsive">
                            <table class="table table-sm table-bordered text-center mb-0">
                                <thead class="thead-light">
                                    <tr>
                                        <th style="width: 70px;">序號</th>
                                        <th>檢核點位置</th>
                                        <th style="width: 130px;">道路潔淨得分</th>
                                        <th style="width: 100px;">潔淨評級</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr v-for="(pt, idx) in activePoints" :key="idx">
                                        <td>{{ idx + 1 }}</td>
                                        <td class="text-left font-weight-bold">{{ pt.Place }}</td>
                                        <td>
                                            <span class="font-weight-bold" :class="pt.Score >= 85 ? 'text-success' : (pt.Score >= 60 ? 'text-warning' : 'text-danger')">
                                                {{ pt.Score }} 分
                                            </span>
                                        </td>
                                        <td>
                                            <span class="score-badge" :class="getScoreClass(pt.Score)">{{ pt.ScoreLv }}</span>
                                        </td>
                                    </tr>
                                    <tr v-if="activePoints.length === 0">
                                        <td colspan="4" class="text-muted py-3">查無此單號的檢核點明細</td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                    <div class="modal-footer bg-light" style="border-radius: 0 0 12px 12px;">
                        <button type="button" class="btn btn-secondary font-weight-bold px-4" data-dismiss="modal">關閉</button>
                    </div>
                </div>
            </div>
        </div>

    </div>

    <!-- 本地腳本庫 -->
    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>
    <script src="../Scripts/jquery-3.6.4.min.js"></script>
    <script src="../Scripts/bootstrap.bundle.min.js"></script>

    <script>
        const { createApp } = Vue;

        createApp({
            data() {
                return {
                    currentMode: 'apply',
                    towns: [],
                    counts: {
                        Apply: 0,
                        Back: 0,
                        Examine: 0,
                        Search: 0,
                        Total: 0
                    },
                    filter: {
                        selectedTown: '',
                        roadName: '',
                        dateS: '',
                        dateE: ''
                    },
                    list: [],
                    pageIndex: 1,
                    pageSize: 20,
                    totalCount: 0,
                    totalPages: 1,
                    selectedChkIds: [],
                    activeItem: null,
                    activePoints: [],
                    pointLoading: false,
                    loading: false,
                    submitting: false,
                    examineForm: {
                        result: 2101,
                        memo: ''
                    },
                    batchMemo: '快速審查通過',
                    checkingValidation: false,
                    validationResult: null,
                    batchResult: null
                };
            },
            computed: {
                hasBatchAction() {
                    return this.currentMode === 'apply' || this.currentMode === 'back' || this.currentMode === 'examine';
                },
                isAllSelected() {
                    const selectable = this.list.filter(x => this.isItemSelectable(x));
                    return selectable.length > 0 && this.selectedChkIds.length === selectable.length;
                },
                pageRange() {
                    const range = [];
                    const cur = this.pageIndex;
                    const total = this.totalPages;
                    if (total <= 7) {
                        for (let i = 1; i <= total; i++) range.push(i);
                    } else {
                        range.push(1);
                        if (cur > 3) range.push('...');
                        const start = Math.max(2, cur - 1);
                        const end = Math.min(total - 1, cur + 1);
                        for (let i = start; i <= end; i++) range.push(i);
                        if (cur < total - 2) range.push('...');
                        range.push(total);
                    }
                    return range;
                }
            },
            mounted() {
                const params = new URLSearchParams(window.location.search);
                const modeParam = params.get('mode');
                if (modeParam) {
                    this.currentMode = modeParam.toLowerCase();
                }

                // 查核紀錄暫存(草稿)與退回補正預設不限日期，讓所有待辦案件一目了然
                if (this.currentMode === 'apply' || this.currentMode === 'back') {
                    this.setDateShortcut('all');
                } else {
                    this.setDateShortcut('month');
                }

                this.loadTowns();
                this.loadCounts();
                this.loadList();
            },
            methods: {
                getModeTitle() {
                    switch (this.currentMode) {
                        case 'apply': return '查核紀錄暫存列表 (草稿 / 駁回)';
                        case 'back': return '退回補正案件列表';
                        case 'examine': return '案件審核列表 (待審查)';
                        case 'search': return '調查成果列表 (已審核通過)';
                        case 'all': return '全部巡查案件列表';
                        default: return '巡檢案件列表';
                    }
                },
                switchMode(mode) {
                    if (this.currentMode === mode) return;
                    this.currentMode = mode;
                    this.pageIndex = 1;
                    this.selectedChkIds = [];

                    if (mode === 'apply' || mode === 'back') {
                        this.setDateShortcut('all');
                    }

                    const url = new URL(window.location.href);
                    url.searchParams.set('mode', mode);
                    window.history.replaceState({}, '', url.toString());

                    this.loadList();
                },
                async loadTowns() {
                    try {
                        const res = await axios.get('Clean_List.aspx?action=gettowns');
                        if (res.data && res.data.Success) {
                            this.towns = res.data.Data;
                        }
                    } catch (e) {
                        console.error('載入行政區失敗:', e);
                    }
                },
                async loadCounts() {
                    try {
                        const res = await axios.get('Clean_List.aspx?action=getcounts');
                        if (res.data && res.data.Success) {
                            this.counts.Apply = res.data.Apply || 0;
                            this.counts.Back = res.data.Back || 0;
                            this.counts.Examine = res.data.Examine || 0;
                            this.counts.Search = res.data.Search || 0;
                            this.counts.Total = res.data.Total || 0;
                        }
                    } catch (e) {
                        console.error('載入統計數失敗:', e);
                    }
                },
                handleSearch() {
                    this.pageIndex = 1;
                    this.loadList();
                },
                async loadList() {
                    this.loading = true;
                    this.selectedChkIds = [];
                    try {
                        const payload = {
                            Mode: this.currentMode,
                            Towns: this.filter.selectedTown ? [this.filter.selectedTown] : [],
                            RoadName: this.filter.roadName,
                            DateS: this.filter.dateS,
                            DateE: this.filter.dateE,
                            States: [],
                            PageIndex: this.pageIndex,
                            PageSize: this.pageSize
                        };
                        const res = await axios.post('Clean_List.aspx?action=getlist', payload);
                        if (res.data && res.data.Success) {
                            this.list = res.data.Data || [];
                            this.totalCount = res.data.Total || 0;
                            this.totalPages = res.data.TotalPages || 1;
                        } else {
                            alert(res.data ? res.data.Message : '資料載入失敗');
                        }
                    } catch (e) {
                        alert('查詢巡檢清單異常，請檢查資料庫連線');
                    } finally {
                        this.loading = false;
                        this.loadCounts();
                    }
                },
                gotoPage(p) {
                    if (p < 1 || p > this.totalPages || p === this.pageIndex) return;
                    this.pageIndex = p;
                    this.loadList();
                },
                onPageSizeChange() {
                    this.pageIndex = 1;
                    this.loadList();
                },
                setDateShortcut(type) {
                    if (type === 'all') {
                        this.filter.dateS = '';
                        this.filter.dateE = '';
                        return;
                    }

                    const now = new Date();
                    const format = d => {
                        const y = d.getFullYear();
                        const m = String(d.getMonth() + 1).padStart(2, '0');
                        const day = String(d.getDate()).padStart(2, '0');
                        return `${y}-${m}-${day}`;
                    };

                    this.filter.dateE = format(now);
                    const start = new Date();
                    if (type === 'today') {
                        // start is today
                    } else if (type === 'week') {
                        start.setDate(now.getDate() - 7);
                    } else if (type === 'month') {
                        start.setMonth(now.getMonth() - 1);
                    } else if (type === 'quarter') {
                        start.setMonth(now.getMonth() - 3);
                    }
                    this.filter.dateS = format(start);
                },
                resetFilter() {
                    this.filter.selectedTown = '';
                    this.filter.roadName = '';
                    this.pageIndex = 1;
                    if (this.currentMode === 'apply' || this.currentMode === 'back') {
                        this.setDateShortcut('all');
                    } else {
                        this.setDateShortcut('month');
                    }
                    this.loadList();
                },
                isItemSelectable(item) {
                    if (!item) return false;
                    if (this.currentMode === 'examine') return item.CaseState === 2001;
                    if (this.currentMode === 'apply' || this.currentMode === 'back') {
                        return item.CaseState === 1001 || item.CaseState === 2301 || item.CaseState === 2201;
                    }
                    return false;
                },
                toggleSelectAll(e) {
                    if (e.target.checked) {
                        this.selectedChkIds = this.list
                            .filter(x => this.isItemSelectable(x))
                            .map(x => x.ChkId);
                    } else {
                        this.selectedChkIds = [];
                    }
                },
                clearSelection() {
                    this.selectedChkIds = [];
                },
                getScoreClass(score) {
                    if (score === null || score === undefined || score < 0) return 'score-none';
                    if (score >= 85) return 'score-a';
                    if (score >= 60) return 'score-b';
                    return 'score-c';
                },
                getScoreIcon(score) {
                    if (score === null || score === undefined || score < 0) return 'far fa-question-circle';
                    if (score >= 85) return 'fas fa-check-circle';
                    if (score >= 60) return 'fas fa-exclamation-circle';
                    return 'fas fa-times-circle';
                },
                // 開啟點位明細視窗 (On-Demand 極速獲取單筆點位明細)
                async openPointModal(item) {
                    this.activeItem = item;
                    this.activePoints = [];
                    this.pointLoading = true;
                    $('#pointModal').modal('show');

                    try {
                        const res = await axios.get('Clean_List.aspx?action=getpointdetail&chkId=' + encodeURIComponent(item.ChkId));
                        if (res.data && res.data.Success) {
                            this.activePoints = res.data.Data || [];
                        }
                    } catch (e) {
                        console.error('獲取檢核點失敗', e);
                    } finally {
                        this.pointLoading = false;
                    }
                },
                openPutCheckModal(item) {
                    this.activeItem = item;
                    this.validationResult = null;
                    this.checkingValidation = true;
                    $('#putCheckModal').modal('show');

                    // 即時向後端端點請求表單完整度與照片檢核
                    axios.get('Clean_List.aspx?action=validatecase&chkId=' + encodeURIComponent(item.ChkId))
                        .then(res => {
                            if (res.data && res.data.Success) {
                                this.validationResult = res.data;
                            } else {
                                this.validationResult = {
                                    IsValid: false,
                                    Errors: [res.data ? res.data.Message : '伺服器檢驗端點未正常回應']
                                };
                            }
                        })
                        .catch(err => {
                            this.validationResult = {
                                IsValid: false,
                                Errors: ['檢核通訊發生異常，請稍後再試']
                            };
                        })
                        .finally(() => {
                            this.checkingValidation = false;
                        });
                },
                async submitPutCheck() {
                    if (!this.activeItem) return;
                    if (this.validationResult && !this.validationResult.IsValid) {
                        alert('本案件資料或必備照片未齊全，無法送出審查！');
                        return;
                    }

                    this.submitting = true;
                    try {
                        const res = await axios.post('Clean_List.aspx?action=putcheck', { ChkId: this.activeItem.ChkId });
                        if (res.data && res.data.Success) {
                            $('#putCheckModal').modal('hide');
                            alert(res.data.Message || '送審成功！');
                            this.loadList();
                            this.loadCounts();
                        } else {
                            if (res.data && res.data.Errors && res.data.Errors.length > 0) {
                                alert(res.data.Message + '\n\n' + res.data.Errors.join('\n'));
                            } else {
                                alert(res.data ? res.data.Message : '送審失敗');
                            }
                        }
                    } catch (e) {
                        alert('操作異常，請洽系統管理員');
                    } finally {
                        this.submitting = false;
                    }
                },
                openExamineModal(item) {
                    this.activeItem = item;
                    this.examineForm.result = 2101;
                    this.examineForm.memo = '';
                    $('#examineModal').modal('show');
                },
                async submitExamine() {
                    if (!this.activeItem) return;
                    if (this.examineForm.result !== 2101 && !this.examineForm.memo.trim()) {
                        alert('退回補正或駁回案件時，必須填寫審查備忘錄/意見說明！');
                        return;
                    }

                    this.submitting = true;
                    try {
                        const payload = {
                            ChkId: this.activeItem.ChkId,
                            Result: this.examineForm.result,
                            Memo: this.examineForm.memo
                        };
                        const res = await axios.post('Clean_List.aspx?action=examine', payload);
                        if (res.data && res.data.Success) {
                            $('#examineModal').modal('hide');
                            alert(res.data.Message || '審核作業完成！');
                            this.loadList();
                        } else {
                            alert(res.data ? res.data.Message : '審核失敗');
                        }
                    } catch (e) {
                        alert('審核作業異常');
                    } finally {
                        this.submitting = false;
                    }
                },
                openBatchPutCheckModal() {
                    if (this.selectedChkIds.length === 0) return;
                    $('#batchPutCheckModal').modal('show');
                },
                async submitBatchPutCheck() {
                    if (this.selectedChkIds.length === 0) return;
                    this.submitting = true;
                    try {
                        const payload = {
                            ChkIds: this.selectedChkIds
                        };
                        const res = await axios.post('Clean_List.aspx?action=batchputcheck', payload);
                        $('#batchPutCheckModal').modal('hide');

                        if (res.data) {
                            this.batchResult = res.data;
                            if (res.data.FailedCount > 0) {
                                // 有未通過的案件，彈出詳細檢驗結果視窗
                                $('#batchPutResultModal').modal('show');
                            } else {
                                alert(res.data.Message || '勾選之案件全數檢核合格，已成功送出審查！');
                            }
                            this.selectedChkIds = [];
                            this.loadList();
                            this.loadCounts();
                        } else {
                            alert('批次送件端點未回應結果');
                        }
                    } catch (e) {
                        alert('批次送件作業異常，請稍後再試');
                    } finally {
                        this.submitting = false;
                    }
                },
                openBatchExamineModal() {
                    if (this.selectedChkIds.length === 0) return;
                    this.batchMemo = '快速審查通過';
                    $('#batchExamineModal').modal('show');
                },
                async submitBatchExamine() {
                    if (this.selectedChkIds.length === 0) return;
                    this.submitting = true;
                    try {
                        const payload = {
                            ChkIds: this.selectedChkIds,
                            Memo: this.batchMemo
                        };
                        const res = await axios.post('Clean_List.aspx?action=multiexamine', payload);
                        if (res.data && res.data.Success) {
                            $('#batchExamineModal').modal('hide');
                            alert(res.data.Message || '批次審核完成！');
                            this.loadList();
                        } else {
                            alert(res.data ? res.data.Message : '批次審核失敗');
                        }
                    } catch (e) {
                        alert('批次審核異常');
                    } finally {
                        this.submitting = false;
                    }
                },
                openDeleteModal(item) {
                    this.activeItem = item;
                    $('#deleteModal').modal('show');
                },
                async submitDelete() {
                    if (!this.activeItem) return;
                    this.submitting = true;
                    try {
                        const res = await axios.post('Clean_List.aspx?action=delete', { ChkId: this.activeItem.ChkId });
                        if (res.data && res.data.Success) {
                            $('#deleteModal').modal('hide');
                            alert(res.data.Message || '草稿已刪除！');
                            this.loadList();
                        } else {
                            alert(res.data ? res.data.Message : '刪除失敗');
                        }
                    } catch (e) {
                        alert('刪除作業異常');
                    } finally {
                        this.submitting = false;
                    }
                }
            }
        }).mount('#listApp');
    </script>
</body>
</html>
