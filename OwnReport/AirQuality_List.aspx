<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="AirQuality_List.aspx.cs" Inherits="NTPC_FEC.OwnReport.AirQuality_List" %>
<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定溢散源管理平台 - 空品不良應變回報清單</title>

    <!-- 專屬 Favicon -->
    <link rel="shortcut icon" href="../favicon.ico" type="image/x-icon" />

    <!-- Bootstrap 4 & FontAwesome 本地化樣式依賴 (符合機房資安規範) -->
    <link rel="stylesheet" href="../Content/bootstrap.min.css" />
    <link rel="stylesheet" href="../Content/fontawesome/css/all.min.css" />

    <style>
        :root {
            --brand-primary: #0099e5;     /* 新北天空青藍 */
            --brand-blue: #0284c7;        /* 科技藍 */
            --brand-dark-blue: #0b1f7d;   /* 海軍深藍 */
            --brand-navy: #0f172a;        /* 標題文字主色 */
            --bg-canvas: #f8fafc;         /* 頁面灰底 */
            --surface: #ffffff;           /* 卡片純白底色 */
            --border-color: #e2e8f0;      /* 邊框線條 */
            --text-main: #0f172a;         /* 內文主要文字 */
            --text-muted: #64748b;        /* 次要說明文字 */
            --status-warn: #f59e0b;       /* 警告黃 */
            --status-danger: #ef4444;     /* 異常紅 */
            --status-success: #10b981;    /* 正常綠 */
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

        /* 頂部深青藍品牌導覽列 */
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

        .brand-title {
            font-size: 1.12rem;
            font-weight: 700;
            margin: 0;
            display: flex;
            align-items: center;
            gap: 8px;
            color: #ffffff;
            letter-spacing: 0.3px;
        }

        .nav-btn {
            background: rgba(255, 255, 255, 0.18);
            border: 1px solid rgba(255, 255, 255, 0.25);
            color: #ffffff;
            font-size: 0.9rem;
            font-weight: 600;
            cursor: pointer;
            height: 38px;
            border-radius: 8px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            padding: 0 14px;
            gap: 6px;
            transition: all 0.2s ease;
            text-decoration: none;
        }

        .nav-btn:hover {
            background-color: rgba(255, 255, 255, 0.32);
            color: #ffffff;
            text-decoration: none;
            transform: translateY(-1px);
        }

        .nav-btn-success {
            background: #10b981;
            border-color: #059669;
            color: #ffffff;
        }
        .nav-btn-success:hover {
            background: #059669;
            color: #ffffff;
        }

        /* 主容器佈局 */
        .container-fluid-custom {
            max-width: 1600px;
            margin: 0 auto;
            padding: 16px;
        }

        /* 現代卡片 */
        .card-modern {
            background: var(--surface);
            border-radius: 12px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05), 0 4px 12px rgba(15, 23, 42, 0.04);
            margin-bottom: 20px;
            border: 1px solid var(--border-color);
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

        /* 統計指標卡片網格 */
        .stat-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
            gap: 14px;
            margin-bottom: 20px;
        }

        .stat-card {
            background: #ffffff;
            border-radius: 10px;
            border: 1px solid var(--border-color);
            padding: 16px;
            display: flex;
            align-items: center;
            gap: 14px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.03);
            transition: all 0.2s ease;
        }

        .stat-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.06);
        }

        .stat-icon {
            width: 46px;
            height: 46px;
            border-radius: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.35rem;
            flex-shrink: 0;
        }

        .stat-icon.primary { background: #e0f2fe; color: #0284c7; }
        .stat-icon.success { background: #ecfdf5; color: #10b981; }
        .stat-icon.warning { background: #fef3c7; color: #d97706; }
        .stat-icon.purple  { background: #ede9fe; color: #7c3aed; }
        .stat-icon.rose    { background: #ffe4e6; color: #e11d48; }
        .stat-icon.amber   { background: #ffedd5; color: #ea580c; }

        .stat-content {
            flex: 1;
            min-width: 0;
        }

        .stat-val {
            font-size: 1.45rem;
            font-weight: 800;
            line-height: 1.2;
            color: var(--brand-navy);
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .stat-label {
            font-size: 12px;
            font-weight: 600;
            color: #64748b;
            margin-top: 2px;
        }

        .stat-subtext {
            font-size: 11px;
            color: #94a3b8;
            margin-top: 1px;
        }

        /* 篩選標籤晶片 */
        .date-chip-group {
            display: flex;
            flex-wrap: wrap;
            gap: 6px;
            margin-top: 8px;
        }

        .date-chip {
            background: #f1f5f9;
            border: 1px solid #cbd5e1;
            color: #475569;
            font-size: 12px;
            font-weight: 600;
            padding: 3px 10px;
            border-radius: 6px;
            cursor: pointer;
            transition: all 0.15s ease;
        }

        .date-chip:hover {
            background: #e2e8f0;
            color: #0f172a;
        }

        .date-chip.active {
            background: var(--brand-blue);
            border-color: var(--brand-blue);
            color: #ffffff;
            box-shadow: 0 1px 3px rgba(2, 132, 199, 0.3);
        }

        /* 現代化資料表格 */
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
            padding: 13px 14px;
            border-bottom: 2px solid var(--border-color);
            border-top: none;
            white-space: nowrap;
            vertical-align: middle;
        }

        .table-modern td {
            padding: 13px 14px;
            vertical-align: middle;
            border-bottom: 1px solid var(--border-color);
            color: var(--text-main);
            font-size: 13.5px;
            background: #ffffff;
        }

        .table-modern tbody tr:hover td {
            background: #f8fafc;
        }

        /* 削減量晶片 */
        .pollutant-badge {
            display: inline-block;
            font-size: 11px;
            font-weight: 700;
            padding: 2px 6px;
            border-radius: 4px;
            margin: 1px;
            background: #f1f5f9;
            color: #334155;
            border: 1px solid #e2e8f0;
            white-space: nowrap;
        }
        .pollutant-badge.has-val {
            background: #eff6ff;
            color: #1d4ed8;
            border-color: #bfdbfe;
        }

        /* 手機卡片式視圖 */
        .mobile-card-list {
            display: none;
        }

        @media screen and (max-width: 991px) {
            .desktop-table-container {
                display: none;
            }
            .mobile-card-list {
                display: block;
            }
        }

        .mobile-item-card {
            background: #ffffff;
            border: 1px solid var(--border-color);
            border-radius: 10px;
            padding: 16px;
            margin-bottom: 14px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
        }

        .mobile-item-header {
            display: flex;
            align-items: flex-start;
            justify-content: space-between;
            margin-bottom: 10px;
            gap: 10px;
        }

        .mobile-item-title {
            font-size: 1rem;
            font-weight: 700;
            color: var(--brand-navy);
            margin: 0;
            line-height: 1.3;
        }

        .mobile-item-row {
            display: flex;
            align-items: center;
            justify-content: space-between;
            font-size: 13px;
            padding: 4px 0;
            color: #475569;
        }

        .mobile-item-label {
            color: #64748b;
            font-weight: 600;
        }

        .mobile-reduction-grid {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 6px;
            background: #f8fafc;
            border-radius: 8px;
            padding: 10px;
            margin: 10px 0;
            border: 1px solid #e2e8f0;
        }

        .mobile-red-item {
            text-align: center;
        }
        .mobile-red-label {
            font-size: 11px;
            color: #64748b;
            font-weight: 600;
        }
        .mobile-red-val {
            font-size: 13px;
            font-weight: 700;
            color: #0284c7;
        }

        /* 操作按鈕群組 */
        .btn-action-group {
            display: inline-flex;
            gap: 5px;
        }

        /* 模態框與全螢幕覆蓋 */
        .modal-custom-header {
            background: linear-gradient(135deg, #0099e5 0%, #0284c7 100%);
            color: #ffffff;
            padding: 14px 20px;
            border-top-left-radius: 10px;
            border-top-right-radius: 10px;
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

        .detail-info-table th {
            width: 140px;
            background: #f8fafc;
            color: #475569;
            font-size: 13px;
            font-weight: 700;
            vertical-align: middle;
            border-top: none;
        }
        .detail-info-table td {
            font-size: 13.5px;
            vertical-align: middle;
            border-top: none;
        }

        /* 讀取指示器 */
        .loading-overlay {
            position: fixed;
            top: 0; left: 0; right: 0; bottom: 0;
            background: rgba(255, 255, 255, 0.7);
            z-index: 1050;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
        }

        /* 分頁列樣式 */
        .pagination-modern {
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-wrap: wrap;
            gap: 12px;
            padding-top: 16px;
            border-top: 1px solid var(--border-color);
        }
    </style>
</head>
<body>
    <div id="app" v-cloak>
        <!-- 頂部品牌導覽列 -->
        <header class="top-navbar">
            <div class="d-flex align-items-center">
                <a href="../MainPage.aspx" class="nav-btn mr-3">
                    <i class="fas fa-arrow-left"></i>
                    <span class="d-none d-sm-inline">回主系統</span>
                </a>
                <h1 class="brand-title">
                    <i class="fas fa-smog text-white"></i>
                    <span>空品不良應變回報管理清單</span>
                </h1>
                <span class="badge badge-light text-dark font-weight-bold ml-2 d-none d-md-inline" style="font-size: 0.85rem;">
                    <i class="fas fa-user-shield text-primary mr-1" v-if="isManager"></i>
                    <i class="fas fa-building text-info mr-1" v-else></i>
                    {{ isManager ? '環保局管理端' : (userFacName || '公私場所') }}
                </span>
            </div>

            <div class="d-flex align-items-center gap-2">
                <a :href="'Report_AirQuality.aspx?mode=new' + (!isManager && userFacId ? '&fac=' + userFacId : '')" class="nav-btn nav-btn-success mr-2">
                    <i class="fas fa-plus"></i>
                    <span class="d-none d-md-inline">新增回報單</span>
                </a>
                <button type="button" class="nav-btn mr-2" v-on:click="exportExcel" :disabled="loading">
                    <i class="fas fa-file-excel text-success"></i>
                    <span class="d-none d-md-inline">匯出 Excel</span>
                </button>
                <button type="button" class="nav-btn" v-on:click="fetchList(true)" :disabled="loading" title="重新整理">
                    <i class="fas fa-sync-alt" :class="{ 'fa-spin': loading }"></i>
                </button>
            </div>
        </header>

        <!-- 主作業容器 -->
        <main class="container-fluid-custom">
            <!-- 頂部統計指標卡片網格 -->
            <div class="stat-grid">
                <!-- 卡片 1: 總申報案件 -->
                <div class="stat-card">
                    <div class="stat-icon primary">
                        <i class="fas fa-file-invoice"></i>
                    </div>
                    <div class="stat-content">
                        <div class="stat-val">{{ stats.TotalCount }}</div>
                        <div class="stat-label">應變回報總件數</div>
                        <div class="stat-subtext">目前篩選條件下回報</div>
                    </div>
                </div>

                <!-- 卡片 2: 配合減排案件與比率 -->
                <div class="stat-card">
                    <div class="stat-icon success">
                        <i class="fas fa-hand-holding-heart"></i>
                    </div>
                    <div class="stat-content">
                        <div class="stat-val text-success">
                            {{ stats.LessYesCount }} <small style="font-size: 0.75rem; font-weight: 700;">({{ stats.ComplianceRate }}%)</small>
                        </div>
                        <div class="stat-label">配合執行減排率</div>
                        <div class="stat-subtext">未配合: {{ stats.LessNoCount }} 件</div>
                    </div>
                </div>

                <!-- 卡片 3: TSP / PM10 削減量 -->
                <div class="stat-card">
                    <div class="stat-icon warning">
                        <i class="fas fa-wind"></i>
                    </div>
                    <div class="stat-content">
                        <div class="stat-val text-warning">{{ stats.TotalTSP }} <small style="font-size: 0.75rem;">kg</small></div>
                        <div class="stat-label">TSP 粒狀物削減量</div>
                        <div class="stat-subtext">PM10: {{ stats.TotalPM10 }} kg</div>
                    </div>
                </div>

                <!-- 卡片 4: PM2.5 削減量 -->
                <div class="stat-card">
                    <div class="stat-icon amber">
                        <i class="fas fa-lungs"></i>
                    </div>
                    <div class="stat-content">
                        <div class="stat-val text-danger">{{ stats.TotalPM25 }} <small style="font-size: 0.75rem;">kg</small></div>
                        <div class="stat-label">PM2.5 細懸浮微粒削減</div>
                        <div class="stat-subtext">重點關注細微粒污染物</div>
                    </div>
                </div>

                <!-- 卡片 5: SOx / NOx 削減量 -->
                <div class="stat-card">
                    <div class="stat-icon purple">
                        <i class="fas fa-smog"></i>
                    </div>
                    <div class="stat-content">
                        <div class="stat-val text-primary">{{ stats.TotalSOx }} / {{ stats.TotalNOx }} <small style="font-size: 0.75rem;">kg</small></div>
                        <div class="stat-label">SOx / NOx 削減量</div>
                        <div class="stat-subtext">硫氧化物與氮氧化物</div>
                    </div>
                </div>

                <!-- 卡片 6: VOCs 削減量 -->
                <div class="stat-card">
                    <div class="stat-icon rose">
                        <i class="fas fa-fire-alt"></i>
                    </div>
                    <div class="stat-content">
                        <div class="stat-val text-danger">{{ stats.TotalVOCs }} <small style="font-size: 0.75rem;">kg</small></div>
                        <div class="stat-label">VOCs 揮發性有機物削減</div>
                        <div class="stat-subtext">揮發性有機污染物累計</div>
                    </div>
                </div>
            </div>

            <!-- 條件篩選卡片 -->
            <div class="card-modern">
                <div class="card-modern-header">
                    <h2 class="card-modern-title">
                        <i class="fas fa-filter text-primary"></i>
                        <span>條件篩選與查詢</span>
                    </h2>
                    <div class="d-flex align-items-center gap-2">
                        <button type="button" class="btn btn-sm btn-primary px-3" v-on:click="handleSearch">
                            <i class="fas fa-search mr-1"></i> 查詢
                        </button>
                        <button type="button" class="btn btn-sm btn-outline-secondary px-3" v-on:click="resetFilters">
                            <i class="fas fa-undo mr-1"></i> 重設
                        </button>
                    </div>
                </div>
                <div class="card-modern-body">
                    <div class="row">
                        <!-- 公私場所選單 (管理員可選，業者鎖定) -->
                        <div class="col-12 col-md-4 col-lg-3 mb-3">
                            <label class="form-label font-weight-bold" style="font-size: 13px;">
                                <i class="fas fa-building text-secondary mr-1"></i> 公私場所：
                            </label>
                            <select class="form-control form-control-sm" v-model="filters.facId" :disabled="!isManager">
                                <option v-for="f in facList" :key="f.FacId" :value="f.FacId">
                                    {{ f.FacName }} {{ f.CNo ? '(' + f.CNo + ')' : '' }}
                                </option>
                            </select>
                        </div>

                        <!-- 應變日期起訖 -->
                        <div class="col-12 col-md-5 col-lg-4 mb-3">
                            <label class="form-label font-weight-bold" style="font-size: 13px;">
                                <i class="fas fa-calendar-alt text-secondary mr-1"></i> 應變通報日期區間：
                            </label>
                            <div class="d-flex align-items-center gap-2">
                                <input type="date" class="form-control form-control-sm" v-model="filters.dateStart" />
                                <span class="text-muted px-1">至</span>
                                <input type="date" class="form-control form-control-sm" v-model="filters.dateEnd" />
                            </div>
                            <!-- 快速時間標籤晶片 -->
                            <div class="date-chip-group">
                                <span class="date-chip" :class="{ active: activeDateRange === 'today' }" v-on:click="setDateRange('today')">今日</span>
                                <span class="date-chip" :class="{ active: activeDateRange === 'week' }" v-on:click="setDateRange('week')">近 7 日</span>
                                <span class="date-chip" :class="{ active: activeDateRange === 'month' }" v-on:click="setDateRange('month')">近 1 個月</span>
                                <span class="date-chip" :class="{ active: activeDateRange === '3months' }" v-on:click="setDateRange('3months')">近 3 個月</span>
                                <span class="date-chip" :class="{ active: activeDateRange === 'year' }" v-on:click="setDateRange('year')">今年度</span>
                            </div>
                        </div>

                        <!-- 操作狀況 -->
                        <div class="col-6 col-md-3 col-lg-2 mb-3">
                            <label class="form-label font-weight-bold" style="font-size: 13px;">
                                <i class="fas fa-cogs text-secondary mr-1"></i> 操作狀況：
                            </label>
                            <select class="form-control form-control-sm" v-model="filters.status">
                                <option value="ALL">全部狀況</option>
                                <option value="操作中">操作中 / 正常操作</option>
                                <option value="降載運轉">降載運轉</option>
                                <option value="停機歲修">停機歲修</option>
                                <option value="其它">其它</option>
                            </select>
                        </div>

                        <!-- 配合執行減排 -->
                        <div class="col-6 col-md-3 col-lg-1 mb-3">
                            <label class="form-label font-weight-bold" style="font-size: 13px;">
                                <i class="fas fa-check-circle text-secondary mr-1"></i> 配合減排：
                            </label>
                            <select class="form-control form-control-sm" v-model="filters.less">
                                <option value="ALL">全部</option>
                                <option value="是">配合 (是)</option>
                                <option value="否">未配合 (否)</option>
                            </select>
                        </div>

                        <!-- 通知方式 -->
                        <div class="col-6 col-md-3 col-lg-2 mb-3">
                            <label class="form-label font-weight-bold" style="font-size: 13px;">
                                <i class="fas fa-bullhorn text-secondary mr-1"></i> 通知方式：
                            </label>
                            <select class="form-control form-control-sm" v-model="filters.contentType">
                                <option value="ALL">全部方式</option>
                                <option value="電話">電話</option>
                                <option value="簡訊">簡訊</option>
                                <option value="Line">Line</option>
                                <option value="公文">公文</option>
                                <option value="傳真">傳真</option>
                                <option value="其它">其它</option>
                            </select>
                        </div>

                        <!-- 關鍵字搜尋 -->
                        <div class="col-12 col-md-6 col-lg-4 mb-3">
                            <label class="form-label font-weight-bold" style="font-size: 13px;">
                                <i class="fas fa-search text-secondary mr-1"></i> 關鍵字搜尋：
                            </label>
                            <div class="input-group input-group-sm">
                                <input type="text" class="form-control" v-model="filters.keyword" placeholder="搜尋場所名稱、管制編號、具體措施..." v-on:keyup.enter="handleSearch" />
                                <div class="input-group-append">
                                    <button class="btn btn-outline-secondary" type="button" v-if="filters.keyword" v-on:click="filters.keyword = ''; handleSearch();">
                                        <i class="fas fa-times"></i>
                                    </button>
                                    <button class="btn btn-primary" type="button" v-on:click="handleSearch">
                                        <i class="fas fa-search"></i>
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- 資料清單主卡片 -->
            <div class="card-modern">
                <div class="card-modern-header">
                    <div class="d-flex align-items-center">
                        <h2 class="card-modern-title">
                            <i class="fas fa-list text-primary"></i>
                            <span>應變回報單清單</span>
                        </h2>
                        <span class="badge badge-info font-weight-bold ml-2" style="font-size: 0.8rem;">
                            共 {{ totalCount }} 筆資料
                        </span>
                    </div>

                    <div class="d-flex align-items-center gap-2">
                        <label class="d-none d-sm-inline text-muted font-weight-bold mb-0" style="font-size: 13px;">每頁：</label>
                        <select class="form-control form-control-sm" style="width: 80px;" v-model="filters.pageSize" v-on:change="handlePageSizeChange">
                            <option :value="10">10 筆</option>
                            <option :value="20">20 筆</option>
                            <option :value="50">50 筆</option>
                            <option :value="100">100 筆</option>
                        </select>
                    </div>
                </div>

                <div class="card-modern-body p-0">
                    <!-- 桌面端表格檢視 (Desktop View) -->
                    <div class="desktop-table-container table-responsive">
                        <table class="table table-modern">
                            <thead>
                                <tr>
                                    <th style="width: 60px;" class="text-center">項次</th>
                                    <th style="width: 105px;" class="text-center">應變日期</th>
                                    <th style="width: 105px;" class="text-center">管制編號</th>
                                    <th style="min-width: 180px;">公私場所名稱</th>
                                    <th style="width: 80px;" class="text-center">行政區</th>
                                    <th style="width: 90px;" class="text-center">通知方式</th>
                                    <th style="width: 95px;" class="text-center">操作狀況</th>
                                    <th style="width: 90px;" class="text-center">配合減排</th>
                                    <th style="width: 120px;" class="text-center">執行時間</th>
                                    <th style="min-width: 220px;">污染物削減量 (kg)</th>
                                    <th style="min-width: 200px;">具體措施 / 原因</th>
                                    <th style="width: 120px;" class="text-center">操作</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr v-for="(item, idx) in list" :key="item.pIndex">
                                    <td class="text-center text-muted font-weight-bold" style="font-size: 12px;">
                                        {{ (filters.pageIndex - 1) * filters.pageSize + idx + 1 }}
                                    </td>
                                    <td class="text-center font-weight-bold text-dark">
                                        {{ item.OverDate }}
                                    </td>
                                    <td class="text-center font-mono font-weight-bold text-secondary">
                                        {{ item.C_NO || '--' }}
                                    </td>
                                    <td>
                                        <a href="javascript:void(0)" class="font-weight-bold text-primary" v-on:click="openDetail(item)" :title="'點擊檢視 ' + item.CNAM + ' 詳細內容'">
                                            {{ item.CNAM }}
                                        </a>
                                    </td>
                                    <td class="text-center">
                                        <span class="badge badge-light text-dark">{{ item.County || '--' }}</span>
                                    </td>
                                    <td class="text-center">
                                        <span class="badge badge-secondary">{{ item.ContentType || '電話' }}</span>
                                    </td>
                                    <td class="text-center">
                                        <span class="badge" :class="getStatusBadgeClass(item.Status)">
                                            {{ item.Status || '正常操作' }}
                                        </span>
                                    </td>
                                    <td class="text-center">
                                        <span v-if="item.Less === '是' || item.Less === 'Y'" class="badge badge-success px-2 py-1">
                                            <i class="fas fa-check mr-1"></i>配合
                                        </span>
                                        <span v-else class="badge badge-danger px-2 py-1">
                                            <i class="fas fa-times mr-1"></i>未配合
                                        </span>
                                    </td>
                                    <td class="text-center font-mono text-muted" style="font-size: 12.5px;">
                                        {{ item.RunTimeStart }} ~ {{ item.RunTimeEnd }}
                                    </td>
                                    <td>
                                        <div class="d-flex flex-wrap">
                                            <span class="pollutant-badge" :class="{ 'has-val': parseFloat(item.TSP) > 0 }" title="TSP">TSP: {{ item.TSP }}</span>
                                            <span class="pollutant-badge" :class="{ 'has-val': parseFloat(item.PM10) > 0 }" title="PM10">PM10: {{ item.PM10 }}</span>
                                            <span class="pollutant-badge" :class="{ 'has-val': parseFloat(item.PM25) > 0 }" title="PM2.5">PM2.5: {{ item.PM25 }}</span>
                                            <span class="pollutant-badge" :class="{ 'has-val': parseFloat(item.SOx) > 0 }" title="SOx">SOx: {{ item.SOx }}</span>
                                            <span class="pollutant-badge" :class="{ 'has-val': parseFloat(item.NOx) > 0 }" title="NOx">NOx: {{ item.NOx }}</span>
                                            <span class="pollutant-badge" :class="{ 'has-val': parseFloat(item.VOCs) > 0 }" title="VOCs">VOCs: {{ item.VOCs }}</span>
                                        </div>
                                    </td>
                                    <td>
                                        <div v-if="item.Less === '是' || item.Less === 'Y'" class="text-truncate" style="max-width: 220px;" :title="item.LessMe">
                                            <small class="text-dark">{{ item.LessMe || '未填寫具體措施' }}</small>
                                        </div>
                                        <div v-else class="text-truncate text-danger" style="max-width: 220px;" :title="item.NoReason">
                                            <small><i class="fas fa-exclamation-triangle mr-1"></i>{{ item.NoReason || '未填寫原因' }}</small>
                                        </div>
                                    </td>
                                    <td class="text-center">
                                        <div class="btn-action-group">
                                            <button type="button" class="btn btn-sm btn-outline-info" title="快速檢視" v-on:click="openDetail(item)">
                                                <i class="fas fa-eye"></i>
                                            </button>
                                            <a :href="'Report_AirQuality.aspx?mode=edit&fac=' + item.FAC_ID + '&id=' + item.pIndex" class="btn btn-sm btn-outline-primary" title="完整編輯" v-if="item.CanEdit">
                                                <i class="fas fa-edit"></i>
                                            </a>
                                            <button type="button" class="btn btn-sm btn-outline-danger" title="刪除案件" v-if="item.CanDelete" v-on:click="confirmDelete(item)">
                                                <i class="fas fa-trash-alt"></i>
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                                <tr v-if="list.length === 0 && !loading">
                                    <td colspan="12" class="text-center py-5">
                                        <div class="text-muted">
                                            <i class="fas fa-folder-open fa-3x mb-3 text-secondary" style="opacity: 0.5;"></i>
                                            <div class="font-weight-bold" style="font-size: 15px;">查無符合條件的空品不良應變回報單</div>
                                            <div class="small mt-1">您可以嘗試調整篩選條件，或點擊右上角「新增回報單」進行填報。</div>
                                            <button type="button" class="btn btn-sm btn-outline-primary mt-3" v-on:click="resetFilters">
                                                <i class="fas fa-undo mr-1"></i> 重設篩選條件
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>

                    <!-- 行動端卡片檢視 (Mobile View) -->
                    <div class="mobile-card-list p-3">
                        <div v-for="item in list" :key="item.pIndex" class="mobile-item-card">
                            <div class="mobile-item-header">
                                <div>
                                    <h3 class="mobile-item-title">{{ item.CNAM }}</h3>
                                    <small class="text-muted font-mono font-weight-bold">{{ item.C_NO || '無管編' }} · {{ item.County || '新北市' }}</small>
                                </div>
                                <div>
                                    <span v-if="item.Less === '是' || item.Less === 'Y'" class="badge badge-success">配合減排</span>
                                    <span v-else class="badge badge-danger">未配合</span>
                                </div>
                            </div>

                            <div class="mobile-item-row">
                                <span class="mobile-item-label"><i class="fas fa-calendar-day mr-1"></i>應變日期：</span>
                                <span class="font-weight-bold text-dark">{{ item.OverDate }}</span>
                            </div>
                            <div class="mobile-item-row">
                                <span class="mobile-item-label"><i class="fas fa-clock mr-1"></i>執行時間：</span>
                                <span>{{ item.RunTimeStart }} ~ {{ item.RunTimeEnd }}</span>
                            </div>
                            <div class="mobile-item-row">
                                <span class="mobile-item-label"><i class="fas fa-cogs mr-1"></i>操作狀況：</span>
                                <span class="badge" :class="getStatusBadgeClass(item.Status)">{{ item.Status }}</span>
                            </div>
                            <div class="mobile-item-row">
                                <span class="mobile-item-label"><i class="fas fa-bullhorn mr-1"></i>通知方式：</span>
                                <span>{{ item.ContentType }}</span>
                            </div>

                            <!-- 削減量指標網格 -->
                            <div class="mobile-reduction-grid">
                                <div class="mobile-red-item">
                                    <div class="mobile-red-label">TSP</div>
                                    <div class="mobile-red-val">{{ item.TSP }}</div>
                                </div>
                                <div class="mobile-red-item">
                                    <div class="mobile-red-label">PM10</div>
                                    <div class="mobile-red-val">{{ item.PM10 }}</div>
                                </div>
                                <div class="mobile-red-item">
                                    <div class="mobile-red-label">PM2.5</div>
                                    <div class="mobile-red-val text-danger">{{ item.PM25 }}</div>
                                </div>
                                <div class="mobile-red-item">
                                    <div class="mobile-red-label">SOx</div>
                                    <div class="mobile-red-val">{{ item.SOx }}</div>
                                </div>
                                <div class="mobile-red-item">
                                    <div class="mobile-red-label">NOx</div>
                                    <div class="mobile-red-val">{{ item.NOx }}</div>
                                </div>
                                <div class="mobile-red-item">
                                    <div class="mobile-red-label">VOCs</div>
                                    <div class="mobile-red-val">{{ item.VOCs }}</div>
                                </div>
                            </div>

                            <!-- 措施摘要 -->
                            <div class="small bg-light p-2 rounded mb-3 text-secondary">
                                <strong class="d-block mb-1 text-dark" v-if="item.Less === '是' || item.Less === 'Y'">具體減排措施：</strong>
                                <strong class="d-block mb-1 text-danger" v-else>未配合原因：</strong>
                                {{ (item.Less === '是' || item.Less === 'Y' ? item.LessMe : item.NoReason) || '無詳細內容' }}
                            </div>

                            <!-- 手機底部大按鈕 -->
                            <div class="d-flex gap-2">
                                <button type="button" class="btn btn-outline-info btn-sm flex-fill py-2" v-on:click="openDetail(item)">
                                    <i class="fas fa-eye mr-1"></i> 詳細資料
                                </button>
                                <a :href="'Report_AirQuality.aspx?mode=edit&fac=' + item.FAC_ID + '&id=' + item.pIndex" class="btn btn-outline-primary btn-sm flex-fill py-2" v-if="item.CanEdit">
                                    <i class="fas fa-edit mr-1"></i> 編輯
                                </a>
                                <button type="button" class="btn btn-outline-danger btn-sm py-2 px-3" v-if="item.CanDelete" v-on:click="confirmDelete(item)" title="刪除">
                                    <i class="fas fa-trash-alt"></i>
                                </button>
                            </div>
                        </div>

                        <div v-if="list.length === 0 && !loading" class="text-center py-5 text-muted">
                            <i class="fas fa-folder-open fa-3x mb-2 text-secondary" style="opacity: 0.5;"></i>
                            <p class="font-weight-bold">目前無符合條件的回報單</p>
                        </div>
                    </div>

                    <!-- 現代分頁控制列 -->
                    <div class="pagination-modern px-3 pb-3" v-if="totalPages > 1">
                        <div class="text-muted" style="font-size: 13px;">
                            顯示第 <strong>{{ (filters.pageIndex - 1) * filters.pageSize + 1 }}</strong> 至 <strong>{{ Math.min(filters.pageIndex * filters.pageSize, totalCount) }}</strong> 筆，共 <strong>{{ totalCount }}</strong> 筆資料
                        </div>

                        <nav aria-label="分頁導航">
                            <ul class="pagination pagination-sm mb-0">
                                <li class="page-item" :class="{ disabled: filters.pageIndex <= 1 }">
                                    <a class="page-link" href="javascript:void(0)" v-on:click="changePage(1)" title="首頁">首頁</a>
                                </li>
                                <li class="page-item" :class="{ disabled: filters.pageIndex <= 1 }">
                                    <a class="page-link" href="javascript:void(0)" v-on:click="changePage(filters.pageIndex - 1)">上一頁</a>
                                </li>

                                <li class="page-item" v-for="p in visiblePages" :key="p" :class="{ active: p === filters.pageIndex }">
                                    <a class="page-link" href="javascript:void(0)" v-on:click="changePage(p)">{{ p }}</a>
                                </li>

                                <li class="page-item" :class="{ disabled: filters.pageIndex >= totalPages }">
                                    <a class="page-link" href="javascript:void(0)" v-on:click="changePage(filters.pageIndex + 1)">下一頁</a>
                                </li>
                                <li class="page-item" :class="{ disabled: filters.pageIndex >= totalPages }">
                                    <a class="page-link" href="javascript:void(0)" v-on:click="changePage(totalPages)" title="末頁">末頁</a>
                                </li>
                            </ul>
                        </nav>
                    </div>
                </div>
            </div>
        </main>

        <!-- 案件快速詳細資料彈窗 (Detail Modal) -->
        <div class="modal fade" id="detailModal" tabindex="-1" role="dialog" aria-hidden="true">
            <div class="modal-dialog modal-lg modal-dialog-centered" role="document">
                <div class="modal-content border-0 shadow">
                    <div class="modal-custom-header">
                        <h5 class="modal-custom-title">
                            <i class="fas fa-info-circle"></i>
                            <span>應變回報單詳細資訊</span>
                        </h5>
                        <button type="button" class="close text-white" data-dismiss="modal" aria-label="Close" style="outline: none;">
                            <span aria-hidden="true">&times;</span>
                        </button>
                    </div>
                    <div class="modal-body p-4" v-if="activeDetail">
                        <div class="d-flex align-items-center justify-content-between mb-3 border-bottom pb-2">
                            <div>
                                <h4 class="font-weight-bold text-dark mb-1">{{ activeDetail.Item.CNAM }}</h4>
                                <div class="text-muted small">
                                    <span class="mr-3">管制編號：<strong class="text-dark">{{ activeDetail.Item.C_NO }}</strong></span>
                                    <span class="mr-3">行政區：<strong class="text-dark">{{ activeDetail.TownName || activeDetail.Item.County }}</strong></span>
                                    <span v-if="activeDetail.Address">場所地址：<strong class="text-dark">{{ activeDetail.Address }}</strong></span>
                                </div>
                            </div>
                            <div>
                                <span v-if="activeDetail.Item.Less === '是' || activeDetail.Item.Less === 'Y'" class="badge badge-success px-3 py-2" style="font-size: 0.9rem;">
                                    <i class="fas fa-check-circle mr-1"></i> 配合執行減排
                                </span>
                                <span v-else class="badge badge-danger px-3 py-2" style="font-size: 0.9rem;">
                                    <i class="fas fa-exclamation-circle mr-1"></i> 未配合減排
                                </span>
                            </div>
                        </div>

                        <table class="table table-bordered detail-info-table mb-4">
                            <tbody>
                                <tr>
                                    <th>應變通報日期</th>
                                    <td class="font-weight-bold text-primary">{{ activeDetail.Item.OverDate }}</td>
                                    <th>環保局通知方式</th>
                                    <td>{{ activeDetail.Item.ContentType }}</td>
                                </tr>
                                <tr>
                                    <th>操作狀況</th>
                                    <td>
                                        <span class="badge" :class="getStatusBadgeClass(activeDetail.Item.Status)">
                                            {{ activeDetail.Item.Status }}
                                        </span>
                                    </td>
                                    <th>執行時間區間</th>
                                    <td class="font-mono">{{ activeDetail.Item.RunTimeStart }} ~ {{ activeDetail.Item.RunTimeEnd }}</td>
                                </tr>
                                <tr v-if="activeDetail.Item.Less === '是' || activeDetail.Item.Less === 'Y'">
                                    <th>具體減排措施</th>
                                    <td colspan="3" class="text-dark" style="white-space: pre-wrap; line-height: 1.6;">
                                        {{ activeDetail.Item.LessMe || '未填寫具體措施內容' }}
                                    </td>
                                </tr>
                                <tr v-else>
                                    <th class="text-danger">未配合原因</th>
                                    <td colspan="3" class="text-danger font-weight-bold" style="white-space: pre-wrap; line-height: 1.6;">
                                        {{ activeDetail.Item.NoReason || '未填寫未配合原因' }}
                                    </td>
                                </tr>
                            </tbody>
                        </table>

                        <h6 class="font-weight-bold text-dark mb-2">
                            <i class="fas fa-chart-bar text-primary mr-1"></i> 各項污染物削減量申報 (單位：公斤 kg)
                        </h6>
                        <div class="table-responsive mb-4">
                            <table class="table table-sm table-bordered text-center mb-0">
                                <thead class="bg-light">
                                    <tr>
                                        <th>TSP</th>
                                        <th>PM10</th>
                                        <th>PM2.5</th>
                                        <th>SOx</th>
                                        <th>NOx</th>
                                        <th>VOCs</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr class="font-weight-bold font-mono">
                                        <td class="text-dark">{{ activeDetail.Item.TSP }}</td>
                                        <td class="text-dark">{{ activeDetail.Item.PM10 }}</td>
                                        <td class="text-danger">{{ activeDetail.Item.PM25 }}</td>
                                        <td class="text-primary">{{ activeDetail.Item.SOx }}</td>
                                        <td class="text-primary">{{ activeDetail.Item.NOx }}</td>
                                        <td class="text-warning">{{ activeDetail.Item.VOCs }}</td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>

                        <div class="row text-muted small border-top pt-3">
                            <div class="col-md-4">
                                填報人員：<strong>{{ activeDetail.Item.InputUser || '未記錄' }}</strong>
                            </div>
                            <div class="col-md-4">
                                建立時間：<strong>{{ activeDetail.Item.CreateDate || '--' }}</strong>
                            </div>
                            <div class="col-md-4">
                                最後修改：<strong>{{ activeDetail.Item.EditDate || '--' }}</strong>
                            </div>
                        </div>
                    </div>
                    <div class="modal-footer bg-light">
                        <a v-if="activeDetail && activeDetail.Item.CanEdit" :href="'Report_AirQuality.aspx?mode=edit&fac=' + activeDetail.Item.FAC_ID + '&id=' + activeDetail.Item.pIndex" class="btn btn-primary px-3">
                            <i class="fas fa-edit mr-1"></i> 前往完整編輯頁
                        </a>
                        <button type="button" class="btn btn-secondary px-4" data-dismiss="modal">關閉</button>
                    </div>
                </div>
            </div>
        </div>

        <!-- 刪除確認彈窗 (Delete Confirmation Modal) -->
        <div class="modal fade" id="deleteModal" tabindex="-1" role="dialog" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered" role="document">
                <div class="modal-content border-0 shadow">
                    <div class="modal-header bg-danger text-white">
                        <h5 class="modal-title font-weight-bold">
                            <i class="fas fa-exclamation-triangle mr-2"></i> 確認刪除回報單
                        </h5>
                        <button type="button" class="close text-white" data-dismiss="modal" aria-label="Close">
                            <span aria-hidden="true">&times;</span>
                        </button>
                    </div>
                    <div class="modal-body p-4" v-if="deletingItem">
                        <p class="mb-2">您確定要刪除以下這筆空品不良應變回報單嗎？此動作將無法復原：</p>
                        <div class="bg-light p-3 rounded border">
                            <div>公私場所：<strong class="text-dark">{{ deletingItem.CNAM }}</strong></div>
                            <div>應變日期：<strong class="text-primary">{{ deletingItem.OverDate }}</strong></div>
                            <div>管制編號：<strong class="text-secondary">{{ deletingItem.C_NO }}</strong></div>
                            <div>操作狀況：<span>{{ deletingItem.Status }}</span></div>
                        </div>
                    </div>
                    <div class="modal-footer bg-light">
                        <button type="button" class="btn btn-secondary" data-dismiss="modal">取消</button>
                        <button type="button" class="btn btn-danger font-weight-bold" v-on:click="executeDelete" :disabled="isDeleting">
                            <i class="fas fa-trash-alt mr-1"></i> {{ isDeleting ? '刪除中...' : '確認刪除' }}
                        </button>
                    </div>
                </div>
            </div>
        </div>

        <!-- 全螢幕讀取指示器 -->
        <div class="loading-overlay" v-if="loading">
            <div class="spinner-border text-primary mb-2" role="status" style="width: 3rem; height: 3rem;">
                <span class="sr-only">資料載入中...</span>
            </div>
            <div class="font-weight-bold text-dark">資料讀取中，請稍候...</div>
        </div>
    </div>

    <!-- 本地化依賴 (符合資安與離線原則) -->
    <script src="../Scripts/jquery.min.js"></script>
    <script src="../Scripts/bootstrap.bundle.min.js"></script>
    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>

    <script>
        const { createApp } = Vue;

        createApp({
            data() {
                return {
                    loading: false,
                    isDeleting: false,
                    isManager: false,
                    currentUser: '',
                    userFacId: '',
                    userFacName: '',
                    facList: [],
                    list: [],
                    totalCount: 0,
                    totalPages: 1,
                    stats: {
                        TotalCount: 0,
                        LessYesCount: 0,
                        LessNoCount: 0,
                        ComplianceRate: 0,
                        TotalTSP: 0,
                        TotalPM10: 0,
                        TotalPM25: 0,
                        TotalSOx: 0,
                        TotalNOx: 0,
                        TotalVOCs: 0
                    },
                    filters: {
                        facId: 'ALL',
                        dateStart: '',
                        dateEnd: '',
                        contentType: 'ALL',
                        status: 'ALL',
                        less: 'ALL',
                        keyword: '',
                        pageIndex: 1,
                        pageSize: 20
                    },
                    activeDateRange: 'month',
                    activeDetail: null,
                    deletingItem: null
                };
            },
            computed: {
                visiblePages() {
                    const pages = [];
                    const current = this.filters.pageIndex;
                    const total = this.totalPages;
                    const delta = 2;

                    for (let i = Math.max(1, current - delta); i <= Math.min(total, current + delta); i++) {
                        pages.push(i);
                    }
                    return pages;
                }
            },
            mounted() {
                this.initPage();
            },
            methods: {
                // 初始化載入
                initPage() {
                    this.loading = true;
                    axios.get('AirQuality_List.aspx?action=getinitdata')
                        .then(res => {
                            if (res.data && res.data.Success) {
                                const d = res.data.Data;
                                this.isManager = d.IsManager;
                                this.currentUser = d.CurrentUser;
                                this.userFacId = d.UserFacId;
                                this.userFacName = d.UserFacName;
                                this.facList = d.FacList || [];

                                // 預設日期區間
                                this.filters.dateStart = d.DefaultDateStart;
                                this.filters.dateEnd = d.DefaultDateEnd;

                                if (!this.isManager && this.userFacId) {
                                    this.filters.facId = this.userFacId;
                                }

                                this.fetchList();
                            } else {
                                alert(res.data ? res.data.Message : '初始化載入失敗');
                                this.loading = false;
                            }
                        })
                        .catch(err => {
                            console.error(err);
                            alert('網路連線錯誤，無法載入初始化資料');
                            this.loading = false;
                        });
                },

                // 查詢列表與統計
                fetchList(resetPage) {
                    if (resetPage) {
                        this.filters.pageIndex = 1;
                    }
                    this.loading = true;

                    const params = {
                        action: 'getlist',
                        facId: this.filters.facId,
                        dateStart: this.filters.dateStart,
                        dateEnd: this.filters.dateEnd,
                        contentType: this.filters.contentType,
                        status: this.filters.status,
                        less: this.filters.less,
                        keyword: this.filters.keyword,
                        pageIndex: this.filters.pageIndex,
                        pageSize: this.filters.pageSize
                    };

                    axios.get('AirQuality_List.aspx', { params: params })
                        .then(res => {
                            this.loading = false;
                            if (res.data && res.data.Success) {
                                const d = res.data.Data;
                                this.list = d.Items || [];
                                this.totalCount = d.TotalCount || 0;
                                this.totalPages = d.TotalPages || 1;
                                this.stats = d.Stats || this.stats;
                            } else {
                                alert(res.data ? res.data.Message : '查詢失敗');
                            }
                        })
                        .catch(err => {
                            this.loading = false;
                            console.error(err);
                            alert('網路請求異常，無法取得回報單清單');
                        });
                },

                handleSearch() {
                    this.fetchList(true);
                },

                handlePageSizeChange() {
                    this.fetchList(true);
                },

                changePage(page) {
                    if (page < 1 || page > this.totalPages || page === this.filters.pageIndex) return;
                    this.filters.pageIndex = page;
                    this.fetchList(false);
                    window.scrollTo({ top: 320, behavior: 'smooth' });
                },

                // 重設條件
                resetFilters() {
                    this.filters.facId = this.isManager ? 'ALL' : this.userFacId;
                    this.filters.contentType = 'ALL';
                    this.filters.status = 'ALL';
                    this.filters.less = 'ALL';
                    this.filters.keyword = '';
                    this.setDateRange('month');
                    this.fetchList(true);
                },

                // 快捷日期標籤切換
                setDateRange(type) {
                    this.activeDateRange = type;
                    const today = new Date();
                    const fmt = d => d.toISOString().split('T')[0];

                    const endStr = fmt(today);
                    let startStr = '';

                    if (type === 'today') {
                        startStr = endStr;
                    } else if (type === 'week') {
                        const d = new Date();
                        d.setDate(today.getDate() - 7);
                        startStr = fmt(d);
                    } else if (type === 'month') {
                        const d = new Date();
                        d.setMonth(today.getMonth() - 1);
                        startStr = fmt(d);
                    } else if (type === '3months') {
                        const d = new Date();
                        d.setMonth(today.getMonth() - 3);
                        startStr = fmt(d);
                    } else if (type === 'year') {
                        startStr = today.getFullYear() + '-01-01';
                    }

                    this.filters.dateStart = startStr;
                    this.filters.dateEnd = endStr;
                },

                // 操作狀況 Badge 樣式
                getStatusBadgeClass(status) {
                    switch (status) {
                        case '操作中':
                        case '正常操作':
                            return 'badge-success';
                        case '降載運轉':
                            return 'badge-warning';
                        case '停機歲修':
                            return 'badge-secondary';
                        case '其它':
                            return 'badge-info';
                        default:
                            return 'badge-light text-dark';
                    }
                },

                // 開啟詳細檢視彈窗
                openDetail(item) {
                    this.loading = true;
                    axios.get('AirQuality_List.aspx?action=getdetail&id=' + item.pIndex)
                        .then(res => {
                            this.loading = false;
                            if (res.data && res.data.Success) {
                                this.activeDetail = res.data.Data;
                                $('#detailModal').modal('show');
                            } else {
                                alert(res.data ? res.data.Message : '讀取案件明細失敗');
                            }
                        })
                        .catch(err => {
                            this.loading = false;
                            console.error(err);
                            alert('網路連線錯誤，無法載入詳細資訊');
                        });
                },

                // 觸發刪除確認
                confirmDelete(item) {
                    this.deletingItem = item;
                    $('#deleteModal').modal('show');
                },

                // 執行刪除
                executeDelete() {
                    if (!this.deletingItem) return;
                    this.isDeleting = true;

                    axios.post('AirQuality_List.aspx?action=delete&id=' + this.deletingItem.pIndex)
                        .then(res => {
                            this.isDeleting = false;
                            if (res.data && res.data.Success) {
                                $('#deleteModal').modal('hide');
                                this.deletingItem = null;
                                alert('回報單已成功刪除！');
                                this.fetchList();
                            } else {
                                alert(res.data ? res.data.Message : '刪除失敗');
                            }
                        })
                        .catch(err => {
                            this.isDeleting = false;
                            console.error(err);
                            alert('刪除請求失敗，請稍後再試');
                        });
                },

                // 匯出 Excel
                exportExcel() {
                    const params = new URLSearchParams({
                        action: 'exportexcel',
                        facId: this.filters.facId,
                        dateStart: this.filters.dateStart,
                        dateEnd: this.filters.dateEnd,
                        contentType: this.filters.contentType,
                        status: this.filters.status,
                        less: this.filters.less,
                        keyword: this.filters.keyword
                    });
                    window.location.href = 'AirQuality_List.aspx?' + params.toString();
                }
            }
        }).mount('#app');
    </script>
</body>
</html>
