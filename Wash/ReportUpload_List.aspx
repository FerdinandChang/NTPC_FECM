<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="ReportUpload_List.aspx.cs" Inherits="NTPC_FEC.Wash.ReportUpload_List" %>
<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定溢散源管理平台 - 洗掃作業月報上傳管理</title>

    <!-- 專屬 Favicon -->
    <link rel="shortcut icon" href="../favicon.ico" type="image/x-icon" />

    <!-- 本地化樣式庫依賴 -->
    <link rel="stylesheet" href="../Content/bootstrap.min.css" />
    <link rel="stylesheet" href="../Content/fontawesome/css/all.min.css" />

    <style>
        :root {
            --brand-primary: #0099e5;     /* 新北天空青藍 */
            --brand-navy: #0f172a;        /* 標題海軍深色 */
            --brand-blue: #0284c7;        /* 科技藍 */
            --brand-dark-blue: #0b1f7d;   /* 海軍深藍 */
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

        /* 導覽按鈕 */
        .nav-btn {
            background: rgba(255, 255, 255, 0.18);
            border: 1px solid rgba(255, 255, 255, 0.35);
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
            background-color: rgba(255, 255, 255, 0.3);
            color: #ffffff;
            text-decoration: none;
        }

        .nav-btn-highlight {
            background: #ffffff;
            color: #0284c7;
            font-weight: 700;
            border: none;
            box-shadow: 0 2px 6px rgba(0, 0, 0, 0.12);
        }

        .nav-btn-highlight:hover {
            background: #f0f9ff;
            color: #0369a1;
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

        /* 統計指標卡片 */
        .stat-card {
            background: #ffffff;
            border-radius: 12px;
            padding: 16px 20px;
            border: 1px solid var(--border-color);
            box-shadow: 0 2px 6px rgba(0, 0, 0, 0.04);
            display: flex;
            align-items: center;
            gap: 16px;
            transition: all 0.25s ease;
            position: relative;
            overflow: hidden;
        }

        .stat-card:hover {
            transform: translateY(-3px);
            box-shadow: 0 6px 16px rgba(15, 23, 42, 0.08);
            border-color: #cbd5e1;
        }

        .stat-icon {
            width: 48px;
            height: 48px;
            border-radius: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 22px;
            flex-shrink: 0;
        }

        .stat-val {
            font-size: 1.65rem;
            font-weight: 800;
            line-height: 1.2;
            color: var(--brand-navy);
        }

        .stat-label {
            font-size: 0.85rem;
            font-weight: 600;
            color: var(--text-muted);
            margin-top: 2px;
        }

        /* 檔案標籤與 Icon */
        .file-badge {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 5px 10px;
            border-radius: 6px;
            font-size: 13px;
            font-weight: 600;
            border: 1px solid transparent;
        }

        .file-badge-pdf {
            background: #fef2f2;
            color: #b91c1c;
            border-color: #fca5a5;
        }

        .file-badge-excel {
            background: #ecfdf5;
            color: #047857;
            border-color: #6ee7b7;
        }

        .file-badge-word {
            background: #eff6ff;
            color: #1d4ed8;
            border-color: #93c5fd;
        }

        .file-badge-archive {
            background: #fffbeb;
            color: #b45309;
            border-color: #fde68a;
        }

        .file-badge-other {
            background: #f8fafc;
            color: #475569;
            border-color: #cbd5e1;
        }

        /* 表格樣式 */
        .table-modern {
            width: 100%;
            margin-bottom: 0;
            border-collapse: separate;
            border-spacing: 0;
        }

        .table-modern th {
            background-color: #f8fafc;
            color: #475569;
            font-weight: 700;
            font-size: 13.5px;
            padding: 12px 16px;
            border-bottom: 2px solid var(--border-color);
            vertical-align: middle;
            white-space: nowrap;
        }

        .table-modern td {
            padding: 13px 16px;
            vertical-align: middle;
            border-bottom: 1px solid var(--border-color);
            font-size: 14px;
            color: var(--text-main);
            transition: background 0.15s;
        }

        .table-modern tbody tr:hover td {
            background-color: #f1f5f9;
        }

        /* 手機端卡片式檢視 (外勤優化) */
        .mobile-item-card {
            background: #ffffff;
            border: 1px solid var(--border-color);
            border-radius: 10px;
            padding: 14px 16px;
            margin-bottom: 12px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
        }

        .mobile-item-header {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            margin-bottom: 8px;
        }

        .mobile-item-title {
            font-size: 1rem;
            font-weight: 700;
            color: var(--brand-navy);
            margin: 0;
        }

        .mobile-item-row {
            display: flex;
            font-size: 13.5px;
            margin-bottom: 6px;
        }

        .mobile-item-label {
            width: 80px;
            color: var(--text-muted);
            font-weight: 600;
            flex-shrink: 0;
        }

        .mobile-item-val {
            color: var(--text-main);
            font-weight: 500;
            flex-grow: 1;
            word-break: break-all;
        }

        .mobile-item-actions {
            margin-top: 12px;
            padding-top: 10px;
            border-top: 1px dashed var(--border-color);
            display: flex;
            gap: 8px;
        }

        /* 拖曳上傳框 */
        .drop-zone {
            border: 2px dashed #94a3b8;
            border-radius: 10px;
            padding: 30px 20px;
            text-align: center;
            background-color: #f8fafc;
            cursor: pointer;
            transition: all 0.2s ease;
        }

        .drop-zone:hover, .drop-zone.dragover {
            border-color: var(--brand-blue);
            background-color: #f0f9ff;
        }

        .drop-zone-icon {
            font-size: 42px;
            color: #0284c7;
            margin-bottom: 10px;
        }

        /* 彈窗遮罩 */
        .modal-mask {
            position: fixed;
            z-index: 1050;
            top: 0;
            left: 0;
            width: 100vw;
            height: 100vh;
            background-color: rgba(15, 23, 42, 0.6);
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 16px;
        }

        .modal-dialog-custom {
            background: #ffffff;
            border-radius: 12px;
            box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.2), 0 10px 10px -5px rgba(0, 0, 0, 0.1);
            width: 100%;
            max-width: 580px;
            overflow: hidden;
            animation: modalFadeIn 0.2s ease-out;
        }

        @keyframes modalFadeIn {
            from { opacity: 0; transform: scale(0.96); }
            to { opacity: 1; transform: scale(1); }
        }

        .modal-header-custom {
            padding: 14px 20px;
            background: #0284c7;
            color: #ffffff;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .modal-body-custom {
            padding: 20px;
            max-height: calc(85vh - 120px);
            overflow-y: auto;
        }

        .modal-footer-custom {
            padding: 12px 20px;
            background: #f8fafc;
            border-top: 1px solid var(--border-color);
            display: flex;
            justify-content: flex-end;
            gap: 10px;
        }

        /* 操作按鈕最小熱區 (外勤觸控友好 >= 40px) */
        .btn-touch {
            min-height: 40px;
            padding: 8px 14px;
            font-weight: 600;
            border-radius: 8px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 6px;
        }

        /* 載入中遮罩 */
        .loading-overlay {
            position: fixed;
            top: 0; left: 0; width: 100vw; height: 100vh;
            background: rgba(255, 255, 255, 0.7);
            backdrop-filter: blur(2px);
            z-index: 1060;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
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
        <!-- 頂部品牌導覽列 -->
        <header class="top-navbar">
            <div class="d-flex align-items-center">
                <a href="../MainPage.aspx?sub=menu2" class="nav-btn mr-3" title="回功能選單">
                    <i class="fas fa-chevron-left"></i>
                    <span class="d-none d-sm-inline">回選單</span>
                </a>
                <span class="navbar-brand-title">
                    <i class="fas fa-truck-pickup text-white"></i>
                    <span>洗掃作業月報上傳清單</span>
                </span>
                <span v-if="user.IsAdmin" class="badge badge-light text-primary font-weight-bold ml-2 d-none d-md-inline" style="font-size: 0.8rem;">
                    主管管理模式
                </span>
                <span v-else class="badge badge-light text-dark font-weight-bold ml-2 d-none d-md-inline" style="font-size: 0.8rem;">
                    場所自主申報
                </span>
            </div>

            <div class="d-flex align-items-center gap-2">
                <button type="button" class="nav-btn nav-btn-highlight" v-on:click="openUploadModal">
                    <i class="fas fa-cloud-upload-alt text-primary"></i>
                    <span>上傳新月報</span>
                </button>
                <button type="button" class="nav-btn ml-2" v-on:click="reloadAll" title="重新整理">
                    <i class="fas fa-sync-alt" :class="{ 'fa-spin': isLoading }"></i>
                </button>
            </div>
        </header>

        <main class="container-fluid py-4 px-lg-4">
            <!-- 頂部四大統計指標卡片 -->
            <div class="row mb-3">
                <div class="col-6 col-lg-3 mb-2 mb-lg-0">
                    <div class="stat-card" style="cursor: pointer;" v-on:click="filter.Year = ''; filter.Month = ''; handleSearch();">
                        <div class="stat-icon bg-primary text-white">
                            <i class="fas fa-clipboard-check"></i>
                        </div>
                        <div>
                            <div class="stat-val text-primary">{{ counts.TotalCount }}</div>
                            <div class="stat-label">累計申報篇數</div>
                        </div>
                    </div>
                </div>

                <div class="col-6 col-lg-3 mb-2 mb-lg-0">
                    <div class="stat-card" style="cursor: pointer;" v-on:click="filter.Year = counts.CurYear; filter.Month = ''; handleSearch();">
                        <div class="stat-icon bg-info text-white">
                            <i class="fas fa-calendar-alt"></i>
                        </div>
                        <div>
                            <div class="stat-val text-info">{{ counts.CurYearCount }}</div>
                            <div class="stat-label">{{ counts.CurYear }} 年度累計</div>
                        </div>
                    </div>
                </div>

                <div class="col-6 col-lg-3 mb-2 mb-lg-0">
                    <div class="stat-card" style="cursor: pointer;" v-on:click="filter.Year = counts.CurYear; filter.Month = counts.CurMonth; handleSearch();">
                        <div class="stat-icon bg-success text-white">
                            <i class="fas fa-calendar-check"></i>
                        </div>
                        <div>
                            <div class="stat-val text-success">{{ counts.CurMonthCount }}</div>
                            <div class="stat-label">本月已申報</div>
                        </div>
                    </div>
                </div>

                <div class="col-6 col-lg-3 mb-2 mb-lg-0">
                    <div class="stat-card">
                        <div class="stat-icon bg-warning text-dark">
                            <i class="fas fa-industry"></i>
                        </div>
                        <div>
                            <div class="stat-val text-warning">{{ counts.FacCount }}</div>
                            <div class="stat-label">{{ user.IsAdmin ? '列管洗掃場所數' : '本廠申報年度數' }}</div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- 條件篩選卡片 -->
            <div class="card-modern">
                <div class="card-modern-header">
                    <h2 class="card-modern-title">
                        <i class="fas fa-filter text-primary"></i>
                        <span>月報條件篩選</span>
                    </h2>
                    <div class="d-flex align-items-center gap-2">
                        <button type="button" class="btn btn-sm btn-outline-secondary font-weight-bold" v-on:click="resetFilter">
                            <i class="fas fa-redo-alt mr-1"></i> 重設
                        </button>
                    </div>
                </div>

                <div class="card-modern-body">
                    <div class="row">
                        <!-- 場所選擇 (管理員可自由篩選；業者鎖定所屬場所) -->
                        <div class="col-12 col-md-4 mb-3">
                            <label class="font-weight-bold text-muted small mb-1">
                                <i class="fas fa-building text-primary mr-1"></i> 申報場所工廠
                            </label>
                            <select v-if="user.IsAdmin" class="form-control font-weight-bold" v-model="filter.FacId" v-on:change="handleSearch">
                                <option value="">全部場所 ({{ facList.length }} 家)</option>
                                <option v-for="f in facList" :key="f.FacId" :value="f.FacId">
                                    {{ f.FacName }} {{ f.HisCount > 0 ? '(' + f.HisCount + '篇)' : '' }}
                                </option>
                            </select>
                            <input v-else type="text" class="form-control font-weight-bold bg-light" :value="user.UserName + ' (' + user.UserFacId + ')'" readonly />
                        </div>

                        <!-- 申報年度 -->
                        <div class="col-6 col-md-2 mb-3">
                            <label class="font-weight-bold text-muted small mb-1">
                                <i class="far fa-calendar text-info mr-1"></i> 申報年度
                            </label>
                            <select class="form-control font-weight-bold" v-model="filter.Year" v-on:change="handleSearch">
                                <option value="">全部年度</option>
                                <option v-for="y in yearList" :key="y.Year" :value="y.Year">
                                    {{ y.Year }} 年
                                </option>
                            </select>
                        </div>

                        <!-- 申報月份 -->
                        <div class="col-6 col-md-2 mb-3">
                            <label class="font-weight-bold text-muted small mb-1">
                                <i class="far fa-calendar-check text-success mr-1"></i> 申報月份
                            </label>
                            <select class="form-control font-weight-bold" v-model="filter.Month" v-on:change="handleSearch">
                                <option value="">全部月份</option>
                                <option v-for="m in 12" :key="m" :value="m">
                                    {{ m }} 月
                                </option>
                            </select>
                        </div>

                        <!-- 關鍵字搜尋 -->
                        <div class="col-12 col-md-4 mb-3">
                            <label class="font-weight-bold text-muted small mb-1">
                                <i class="fas fa-search text-secondary mr-1"></i> 關鍵字 (上傳者/檔名/場所)
                            </label>
                            <input type="text" class="form-control" v-model="filter.Keyword" placeholder="請輸入關鍵字快速搜尋..." v-on:keyup.enter="handleSearch" />
                        </div>
                    </div>

                    <div class="d-flex flex-wrap justify-content-between align-items-center pt-2 border-top">
                        <div class="text-muted small">
                            <span>顯示筆數：</span>
                            <div class="btn-group btn-group-sm ml-1" role="group">
                                <button type="button" class="btn" :class="filter.PageSize === 10 ? 'btn-primary' : 'btn-outline-secondary'" v-on:click="changePageSize(10)">10</button>
                                <button type="button" class="btn" :class="filter.PageSize === 20 ? 'btn-primary' : 'btn-outline-secondary'" v-on:click="changePageSize(20)">20</button>
                                <button type="button" class="btn" :class="filter.PageSize === 50 ? 'btn-primary' : 'btn-outline-secondary'" v-on:click="changePageSize(50)">50</button>
                            </div>
                        </div>

                        <div class="d-flex align-items-center gap-2 mt-2 mt-sm-0">
                            <button type="button" class="btn btn-primary font-weight-bold px-4" v-on:click="handleSearch">
                                <i class="fas fa-search mr-1"></i> 執行查詢
                            </button>
                            <button type="button" class="btn btn-outline-success font-weight-bold px-3 ml-2" v-on:click="exportExcel">
                                <i class="fas fa-file-excel mr-1"></i> 匯出 Excel
                            </button>
                        </div>
                    </div>
                </div>
            </div>

            <!-- 月報清單卡片 -->
            <div class="card-modern">
                <div class="card-modern-header">
                    <h2 class="card-modern-title">
                        <i class="fas fa-table text-primary"></i>
                        <span>洗掃月報資料列表</span>
                        <span class="badge badge-secondary ml-2" style="font-size: 0.82rem;">共 {{ pagination.TotalRows }} 筆</span>
                    </h2>

                    <!-- 載具檢視切換 (僅電腦寬螢幕顯示切換，手機強制卡片) -->
                    <div class="d-none d-md-flex align-items-center">
                        <div class="btn-group btn-group-sm">
                            <button type="button" class="btn" :class="viewMode === 'table' ? 'btn-primary' : 'btn-outline-secondary'" v-on:click="viewMode = 'table'">
                                <i class="fas fa-list mr-1"></i> 表格檢視
                            </button>
                            <button type="button" class="btn" :class="viewMode === 'card' ? 'btn-primary' : 'btn-outline-secondary'" v-on:click="viewMode = 'card'">
                                <i class="fas fa-th-large mr-1"></i> 卡片檢視
                            </button>
                        </div>
                    </div>
                </div>

                <div class="card-modern-body p-0">
                    <!-- 電腦端表格檢視 (Desktop View) -->
                    <div v-if="viewMode === 'table'" class="table-responsive d-none d-md-block">
                        <table class="table table-modern">
                            <thead>
                                <tr>
                                    <th style="width: 60px;" class="text-center">項次</th>
                                    <th style="width: 200px;">申報場所名稱</th>
                                    <th style="width: 130px;" class="text-center">申報年月</th>
                                    <th>月報檔案 (點擊下載)</th>
                                    <th style="width: 170px;" class="text-center">上傳時間</th>
                                    <th style="width: 140px;" class="text-center">上傳人員</th>
                                    <th style="width: 120px;" class="text-center">功能操作</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr v-for="(item, idx) in list" :key="item.PID">
                                    <td class="text-center font-weight-bold text-muted">
                                        {{ (pagination.PageIndex - 1) * pagination.PageSize + idx + 1 }}
                                    </td>
                                    <td>
                                        <div class="font-weight-bold text-dark">{{ item.FacName }}</div>
                                        <small class="text-muted"><i class="fas fa-id-badge mr-1"></i>{{ item.FacId }}</small>
                                    </td>
                                    <td class="text-center">
                                        <span class="badge badge-info px-2 py-1" style="font-size: 0.88rem;">
                                            {{ item.UploadYear }} 年 {{ item.UploadMonth }} 月
                                        </span>
                                    </td>
                                    <td>
                                        <div v-if="item.FileExists" class="d-flex align-items-center">
                                            <a :href="item.DownloadUrl" class="file-badge mr-2 text-decoration-none" :class="getFileBadgeClass(item.FileExt)" title="點選直接下載檔案">
                                                <i :class="getFileIcon(item.FileExt)"></i>
                                                <span>{{ item.FileName }}</span>
                                            </a>
                                            <small class="text-muted font-weight-bold">({{ item.FileSizeStr }})</small>
                                        </div>
                                        <div v-else class="text-danger small font-weight-bold">
                                            <i class="fas fa-exclamation-triangle mr-1"></i>
                                            <span>{{ item.FileName }} (伺服器端查無實體檔)</span>
                                        </div>
                                    </td>
                                    <td class="text-center text-muted font-weight-bold small">
                                        {{ item.UploadDate || '-' }}
                                    </td>
                                    <td class="text-center">
                                        <span class="badge badge-light border text-dark px-2 py-1" style="font-size: 0.85rem;">
                                            <i class="fas fa-user-circle mr-1 text-primary"></i>
                                            {{ item.UploadUserName }}
                                        </span>
                                    </td>
                                    <td class="text-center">
                                        <div class="btn-group btn-group-sm">
                                            <a v-if="item.FileExists" :href="item.DownloadUrl" class="btn btn-outline-primary" title="下載月報檔案">
                                                <i class="fas fa-download"></i>
                                            </a>
                                            <button type="button" class="btn btn-outline-danger" v-on:click="confirmDelete(item)" title="刪除此申報紀錄">
                                                <i class="fas fa-trash-alt"></i>
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                                <tr v-if="list.length === 0">
                                    <td colspan="7" class="text-center py-5">
                                        <div class="text-muted">
                                            <i class="fas fa-folder-open fa-3x mb-3 text-secondary" style="opacity: 0.5;"></i>
                                            <div class="font-weight-bold">目前條件下查無任何洗掃月報資料</div>
                                            <small class="text-muted mt-1 d-block">請重新調整搜尋條件，或點選右上角「上傳新月報」進行回傳！</small>
                                        </div>
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>

                    <!-- 手機端或切換卡片檢視 (Mobile / Card View) -->
                    <div v-if="viewMode === 'card' || isMobile" class="p-3" :class="{ 'd-md-none': viewMode === 'table' }">
                        <div v-for="(item, idx) in list" :key="item.PID" class="mobile-item-card">
                            <div class="mobile-item-header">
                                <div>
                                    <span class="badge badge-primary px-2 py-1 mr-1">
                                        {{ item.UploadYear }} 年 {{ item.UploadMonth }} 月
                                    </span>
                                    <h3 class="mobile-item-title d-inline-block">{{ item.FacName }}</h3>
                                </div>
                                <span class="badge badge-light border text-muted">#{{ (pagination.PageIndex - 1) * pagination.PageSize + idx + 1 }}</span>
                            </div>

                            <div class="mobile-item-row">
                                <div class="mobile-item-label">場所代號</div>
                                <div class="mobile-item-val font-weight-bold">{{ item.FacId }}</div>
                            </div>

                            <div class="mobile-item-row">
                                <div class="mobile-item-label">檔案名稱</div>
                                <div class="mobile-item-val">
                                    <div v-if="item.FileExists" class="d-inline-flex align-items-center">
                                        <span class="file-badge" :class="getFileBadgeClass(item.FileExt)">
                                            <i :class="getFileIcon(item.FileExt)"></i>
                                            {{ item.FileName }}
                                        </span>
                                        <span class="ml-1 small text-muted font-weight-bold">({{ item.FileSizeStr }})</span>
                                    </div>
                                    <span v-else class="text-danger small font-weight-bold">
                                        <i class="fas fa-exclamation-triangle"></i> 無實體檔案
                                    </span>
                                </div>
                            </div>

                            <div class="mobile-item-row">
                                <div class="mobile-item-label">上傳時間</div>
                                <div class="mobile-item-val text-muted small">{{ item.UploadDate || '-' }}</div>
                            </div>

                            <div class="mobile-item-row">
                                <div class="mobile-item-label">申報人員</div>
                                <div class="mobile-item-val">
                                    <span class="badge badge-light border text-dark">
                                        <i class="fas fa-user mr-1 text-primary"></i>
                                        {{ item.UploadUserName }} ({{ item.UploadUser }})
                                    </span>
                                </div>
                            </div>

                            <div class="mobile-item-actions">
                                <a v-if="item.FileExists" :href="item.DownloadUrl" class="btn btn-sm btn-primary flex-fill btn-touch">
                                    <i class="fas fa-download mr-1"></i> 下載檔案
                                </a>
                                <button type="button" class="btn btn-sm btn-outline-danger flex-fill btn-touch" v-on:click="confirmDelete(item)">
                                    <i class="fas fa-trash-alt mr-1"></i> 刪除紀錄
                                </button>
                            </div>
                        </div>

                        <div v-if="list.length === 0" class="text-center py-5">
                            <i class="fas fa-folder-open fa-3x mb-3 text-secondary" style="opacity: 0.5;"></i>
                            <div class="font-weight-bold text-muted">目前條件下查無任何洗掃月報資料</div>
                        </div>
                    </div>
                </div>

                <!-- 自適應底部分頁導覽列 (Responsive Pagination Footer) -->
                <div v-if="!loading && pagination.TotalRows > 0" class="pagination-footer">
                    <div class="pagination-footer-info">
                        顯示第 <strong class="text-dark">{{ (pagination.PageIndex - 1) * pagination.PageSize + 1 }}</strong> 至 <strong class="text-dark">{{ Math.min(pagination.PageIndex * pagination.PageSize, pagination.TotalRows) }}</strong> 筆，共 <strong class="text-dark">{{ pagination.TotalRows }}</strong> 筆資料
                    </div>
                    <div class="pagination-action-group">
                        <button type="button" class="btn-page-ctrl btn-edge" :disabled="pagination.PageIndex <= 1" v-on:click="changePage(1)" title="第一頁">
                            <i class="fas fa-angle-double-left"></i>
                            <span class="d-none d-md-inline ml-1">首頁</span>
                        </button>
                        <button type="button" class="btn-page-ctrl btn-step" :disabled="pagination.PageIndex <= 1" v-on:click="changePage(pagination.PageIndex - 1)" title="上一頁">
                            <i class="fas fa-chevron-left mr-1"></i>
                            <span>上一頁</span>
                        </button>
                        <div class="page-indicator-pill" title="目前頁次 / 總頁數">
                            <span>{{ pagination.PageIndex }}</span>
                            <span class="mx-1 text-muted" style="opacity: 0.5; font-weight: normal;">/</span>
                            <span>{{ pagination.TotalPages }}</span>
                        </div>
                        <button type="button" class="btn-page-ctrl btn-step" :disabled="pagination.PageIndex >= pagination.TotalPages" v-on:click="changePage(pagination.PageIndex + 1)" title="下一頁">
                            <span>下一頁</span>
                            <i class="fas fa-chevron-right ml-1"></i>
                        </button>
                        <button type="button" class="btn-page-ctrl btn-edge" :disabled="pagination.PageIndex >= pagination.TotalPages" v-on:click="changePage(pagination.TotalPages)" title="最後一頁">
                            <span class="d-none d-md-inline ml-1">末頁</span>
                            <i class="fas fa-angle-double-right"></i>
                        </button>
                    </div>
                </div>
            </div>
        </main>

        <!-- 彈窗一：上傳/覆蓋月報 Modal -->
        <div v-if="showUploadModal" class="modal-mask" v-on:click.self="closeUploadModal">
            <div class="modal-dialog-custom">
                <div class="modal-header-custom">
                    <h5 class="modal-title font-weight-bold mb-0">
                        <i class="fas fa-cloud-upload-alt mr-2"></i> 上傳洗掃作業月報
                    </h5>
                    <button type="button" class="close text-white" v-on:click="closeUploadModal">&times;</button>
                </div>

                <div class="modal-body-custom">
                    <!-- 申報場所 -->
                    <div class="form-group mb-3">
                        <label class="font-weight-bold small text-muted mb-1">
                            <i class="fas fa-building text-primary mr-1"></i> 申報場所工廠 <span class="text-danger">*</span>
                        </label>
                        <select v-if="user.IsAdmin" class="form-control font-weight-bold" v-model="uploadForm.FacId" v-on:change="checkExistingReport">
                            <option value="">-- 請選擇申報工廠 --</option>
                            <option v-for="f in facList" :key="f.FacId" :value="f.FacId">
                                {{ f.FacName }} ({{ f.FacId }})
                            </option>
                        </select>
                        <input v-else type="text" class="form-control font-weight-bold bg-light" :value="user.UserName + ' (' + user.UserFacId + ')'" readonly />
                    </div>

                    <!-- 申報年月 -->
                    <div class="form-row mb-3">
                        <div class="col-6">
                            <label class="font-weight-bold small text-muted mb-1">
                                <i class="far fa-calendar text-info mr-1"></i> 申報年度 (民國) <span class="text-danger">*</span>
                            </label>
                            <select class="form-control font-weight-bold" v-model="uploadForm.Year" v-on:change="checkExistingReport">
                                <option v-for="y in yearList" :key="y.Year" :value="y.Year">
                                    {{ y.Year }} 年
                                </option>
                            </select>
                        </div>
                        <div class="col-6">
                            <label class="font-weight-bold small text-muted mb-1">
                                <i class="far fa-calendar-check text-success mr-1"></i> 申報月份 <span class="text-danger">*</span>
                            </label>
                            <select class="form-control font-weight-bold" v-model="uploadForm.Month" v-on:change="checkExistingReport">
                                <option v-for="m in 12" :key="m" :value="m">
                                    {{ m }} 月
                                </option>
                            </select>
                        </div>
                    </div>

                    <!-- 歷史重複覆蓋警示 -->
                    <div v-if="existingReportNotice" class="alert alert-warning py-2 px-3 small font-weight-bold mb-3">
                        <i class="fas fa-exclamation-triangle mr-1"></i>
                        <span>提示：該場所已於 {{ existingReportNotice.UploadDate }} 申報過 {{ uploadForm.Year }}年{{ uploadForm.Month }}月 之月報檔 ({{ existingReportNotice.FileName }})。再次上傳將會覆蓋舊檔案！</span>
                    </div>

                    <!-- 檔案拖曳與選擇區 -->
                    <div class="form-group mb-2">
                        <label class="font-weight-bold small text-muted mb-1">
                            <i class="fas fa-file-upload text-primary mr-1"></i> 月報檔案 <span class="text-danger">*</span>
                        </label>
                        <div class="drop-zone" :class="{ 'dragover': isDragging }" 
                             v-on:dragover.prevent="isDragging = true" 
                             v-on:dragleave.prevent="isDragging = false" 
                             v-on:drop.prevent="handleFileDrop"
                             v-on:click="$refs.fileInput.click()">
                            <input type="file" ref="fileInput" style="display: none;" v-on:change="handleFileSelect" accept=".pdf,.xls,.xlsx,.doc,.docx,.zip,.rar,.7z,.jpg,.png" />
                            <i class="fas fa-cloud-upload-alt drop-zone-icon"></i>
                            <div v-if="!selectedFile">
                                <div class="font-weight-bold text-dark">點擊或拖曳檔案至此處上傳</div>
                                <small class="text-muted">支援 PDF、Excel、Word、壓縮檔或圖片 (單檔上限 50MB)</small>
                            </div>
                            <div v-else>
                                <div class="font-weight-bold text-primary">{{ selectedFile.name }}</div>
                                <small class="text-muted font-weight-bold">檔案大小：{{ formatFileSize(selectedFile.size) }}</small>
                                <div class="mt-2">
                                    <button type="button" class="btn btn-sm btn-outline-danger" v-on:click.stop="clearSelectedFile">
                                        <i class="fas fa-times mr-1"></i> 清除重新選取
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="modal-footer-custom">
                    <button type="button" class="btn btn-secondary font-weight-bold btn-touch" v-on:click="closeUploadModal" :disabled="isUploading">
                        取消
                    </button>
                    <button type="button" class="btn btn-primary font-weight-bold btn-touch" v-on:click="submitUpload" :disabled="isUploading || !selectedFile">
                        <i class="fas fa-upload mr-1" :class="{ 'fa-spin': isUploading }"></i>
                        <span>{{ isUploading ? '上傳中...' : '確認上傳月報' }}</span>
                    </button>
                </div>
            </div>
        </div>

        <!-- 彈窗二：刪除確認 Modal -->
        <div v-if="showDeleteModal" class="modal-mask" v-on:click.self="showDeleteModal = false">
            <div class="modal-dialog-custom" style="max-width: 440px;">
                <div class="modal-header-custom bg-danger">
                    <h5 class="modal-title font-weight-bold mb-0">
                        <i class="fas fa-trash-alt mr-2"></i> 確認刪除月報
                    </h5>
                    <button type="button" class="close text-white" v-on:click="showDeleteModal = false">&times;</button>
                </div>
                <div class="modal-body-custom">
                    <p class="mb-2">您確定要刪除以下洗掃作業月報申報紀錄嗎？</p>
                    <div class="bg-light p-3 rounded border mb-2">
                        <div class="small text-muted">場所名稱：<strong class="text-dark">{{ itemToDelete ? itemToDelete.FacName : '' }}</strong></div>
                        <div class="small text-muted mt-1">申報年月：<strong class="text-primary">{{ itemToDelete ? itemToDelete.UploadYear + ' 年 ' + itemToDelete.UploadMonth + ' 月' : '' }}</strong></div>
                        <div class="small text-muted mt-1">檔案名稱：<span class="text-danger font-weight-bold">{{ itemToDelete ? itemToDelete.FileName : '' }}</span></div>
                    </div>
                    <small class="text-danger font-weight-bold">
                        <i class="fas fa-info-circle mr-1"></i> 注意：刪除後資料庫紀錄與伺服器實體檔案均將永久清除，無法復原！
                    </small>
                </div>
                <div class="modal-footer-custom">
                    <button type="button" class="btn btn-secondary font-weight-bold btn-touch" v-on:click="showDeleteModal = false">
                        取消
                    </button>
                    <button type="button" class="btn btn-danger font-weight-bold btn-touch" v-on:click="submitDelete">
                        <i class="fas fa-trash-alt mr-1"></i> 確認刪除
                    </button>
                </div>
            </div>
        </div>

        <!-- 全頁載入中遮罩 -->
        <div v-if="isLoading" class="loading-overlay">
            <div class="spinner-border text-primary" role="status" style="width: 3rem; height: 3rem;">
                <span class="sr-only">處理中...</span>
            </div>
            <div class="font-weight-bold text-dark mt-3" style="letter-spacing: 1px;">資料載入處理中，請稍候...</div>
        </div>
    </div>

    <!-- 本地核心庫依賴 (杜絕外部 CDN 依賴) -->
    <script src="../Scripts/jquery-3.6.4.min.js"></script>
    <script src="../Scripts/bootstrap.bundle.min.js"></script>
    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>

    <script>
        const { createApp } = Vue;

        createApp({
            data() {
                return {
                    isLoading: false,
                    isUploading: false,
                    isDragging: false,
                    isMobile: window.innerWidth < 768,
                    viewMode: 'table', // 'table' or 'card'

                    // 當前使用者身分
                    user: {
                        UserId: '',
                        UserName: '',
                        IsAdmin: false,
                        UserFacId: ''
                    },

                    // 統計數值
                    counts: {
                        TotalCount: 0,
                        CurYearCount: 0,
                        CurMonthCount: 0,
                        FacCount: 0,
                        CurYear: 115,
                        CurMonth: 1
                    },

                    // 下拉選單資料來源
                    facList: [],
                    yearList: [],

                    // 篩選條件
                    filter: {
                        FacId: '',
                        Year: '',
                        Month: '',
                        Keyword: '',
                        PageSize: 20
                    },

                    // 分頁資訊
                    pagination: {
                        PageIndex: 1,
                        PageSize: 20,
                        TotalRows: 0,
                        TotalPages: 1
                    },

                    // 清單資料
                    list: [],

                    // 上傳 Modal 控制
                    showUploadModal: false,
                    uploadForm: {
                        FacId: '',
                        Year: 115,
                        Month: 1
                    },
                    selectedFile: null,
                    existingReportNotice: null,

                    // 刪除 Modal 控制
                    showDeleteModal: false,
                    itemToDelete: null
                };
            },
            computed: {
                visiblePages() {
                    const current = this.pagination.PageIndex;
                    const total = this.pagination.TotalPages;
                    const pages = [];
                    let start = Math.max(1, current - 2);
                    let end = Math.min(total, current + 2);

                    for (let i = start; i <= end; i++) {
                        pages.push(i);
                    }
                    return pages;
                }
            },
            mounted() {
                window.addEventListener('resize', this.handleResize);
                this.initData();
            },
            beforeUnmount() {
                window.removeEventListener('resize', this.handleResize);
            },
            methods: {
                handleResize() {
                    this.isMobile = window.innerWidth < 768;
                },

                // 1. 初始化資料
                async initData() {
                    this.isLoading = true;
                    try {
                        const res = await axios.get('ReportUpload_List.aspx?action=getinit');
                        if (res.data && res.data.Success) {
                            const d = res.data.Data;
                            this.user.UserId = d.UserId;
                            this.user.UserName = d.UserName;
                            this.user.IsAdmin = d.IsAdmin;
                            this.user.UserFacId = d.UserFacId;
                            this.facList = d.FacList || [];
                            this.yearList = d.YearList || [];

                            this.uploadForm.Year = d.DefaultYear;
                            this.uploadForm.Month = d.DefaultMonth;
                            this.uploadForm.FacId = d.IsAdmin ? (this.facList.length > 0 ? this.facList[0].FacId : '') : d.UserFacId;

                            // 讀取統計指標與清單
                            await Promise.all([this.loadCounts(), this.loadList()]);
                        } else if (res.data && res.data.NeedLogin) {
                            alert(res.data.Message || '尚未登入，請先登入！');
                            window.location.href = '../Default.aspx';
                        } else {
                            alert(res.data ? res.data.Message : '初始化失敗');
                        }
                    } catch (err) {
                        console.error('initData error:', err);
                        alert('載入使用者初始資訊時發生錯誤！');
                    } finally {
                        this.isLoading = false;
                    }
                },

                // 2. 載入統計數值
                async loadCounts() {
                    try {
                        const res = await axios.get('ReportUpload_List.aspx?action=getcounts');
                        if (res.data && res.data.Success) {
                            this.counts = res.data.Data;
                        }
                    } catch (err) {
                        console.error('loadCounts error:', err);
                    }
                },

                // 3. 載入月報清單
                async loadList() {
                    this.isLoading = true;
                    try {
                        const params = {
                            action: 'getlist',
                            facId: this.filter.FacId,
                            year: this.filter.Year,
                            month: this.filter.Month,
                            keyword: this.filter.Keyword,
                            pageIndex: this.pagination.PageIndex,
                            pageSize: this.filter.PageSize
                        };

                        const res = await axios.get('ReportUpload_List.aspx', { params });
                        if (res.data && res.data.Success) {
                            const d = res.data.Data;
                            this.list = d.Items || [];
                            this.pagination.TotalRows = d.TotalRows;
                            this.pagination.TotalPages = d.TotalPages;
                            this.pagination.PageIndex = d.PageIndex;
                            this.pagination.PageSize = d.PageSize;
                        } else {
                            alert(res.data ? res.data.Message : '讀取月報清單失敗');
                        }
                    } catch (err) {
                        console.error('loadList error:', err);
                        alert('取得月報列表時發生網路或伺服器錯誤！');
                    } finally {
                        this.isLoading = false;
                    }
                },

                // 搜尋與換頁
                handleSearch() {
                    this.pagination.PageIndex = 1;
                    this.loadList();
                },

                resetFilter() {
                    this.filter.FacId = '';
                    this.filter.Year = '';
                    this.filter.Month = '';
                    this.filter.Keyword = '';
                    this.pagination.PageIndex = 1;
                    this.loadList();
                },

                changePageSize(size) {
                    this.filter.PageSize = size;
                    this.pagination.PageIndex = 1;
                    this.loadList();
                },

                changePage(page) {
                    if (page < 1 || page > this.pagination.TotalPages || page === this.pagination.PageIndex) return;
                    this.pagination.PageIndex = page;
                    this.loadList();
                },

                reloadAll() {
                    this.loadCounts();
                    this.loadList();
                },

                // 匯出 Excel
                exportExcel() {
                    const params = new URLSearchParams({
                        action: 'export',
                        facId: this.filter.FacId || '',
                        year: this.filter.Year || '',
                        month: this.filter.Month || '',
                        keyword: this.filter.Keyword || ''
                    });
                    window.location.href = 'ReportUpload_List.aspx?' + params.toString();
                },

                // 上傳 Modal 操作
                openUploadModal() {
                    this.selectedFile = null;
                    this.existingReportNotice = null;
                    if (!this.user.IsAdmin) {
                        this.uploadForm.FacId = this.user.UserFacId;
                    } else if (!this.uploadForm.FacId && this.facList.length > 0) {
                        this.uploadForm.FacId = this.facList[0].FacId;
                    }
                    this.checkExistingReport();
                    this.showUploadModal = true;
                },

                closeUploadModal() {
                    if (this.isUploading) return;
                    this.showUploadModal = false;
                    this.selectedFile = null;
                    this.existingReportNotice = null;
                },

                async checkExistingReport() {
                    if (!this.uploadForm.FacId || !this.uploadForm.Year || !this.uploadForm.Month) {
                        this.existingReportNotice = null;
                        return;
                    }
                    try {
                        const params = {
                            action: 'checkexists',
                            facId: this.uploadForm.FacId,
                            year: this.uploadForm.Year,
                            month: this.uploadForm.Month
                        };
                        const res = await axios.get('ReportUpload_List.aspx', { params });
                        if (res.data && res.data.Success && res.data.Exists) {
                            this.existingReportNotice = {
                                FileName: res.data.FileName,
                                UploadDate: res.data.UploadDate
                            };
                        } else {
                            this.existingReportNotice = null;
                        }
                    } catch (err) {
                        console.error('checkExistingReport error:', err);
                    }
                },

                handleFileSelect(e) {
                    if (e.target.files && e.target.files.length > 0) {
                        this.selectedFile = e.target.files[0];
                    }
                },

                handleFileDrop(e) {
                    this.isDragging = false;
                    if (e.dataTransfer && e.dataTransfer.files && e.dataTransfer.files.length > 0) {
                        this.selectedFile = e.dataTransfer.files[0];
                    }
                },

                clearSelectedFile() {
                    this.selectedFile = null;
                    if (this.$refs.fileInput) {
                        this.$refs.fileInput.value = '';
                    }
                },

                async submitUpload() {
                    if (!this.uploadForm.FacId) {
                        alert('請選擇申報場所！');
                        return;
                    }
                    if (!this.selectedFile) {
                        alert('請選取欲上傳的月報檔案！');
                        return;
                    }

                    if (this.existingReportNotice) {
                        const confirmOverwrite = confirm('警告：該年月已存在月報紀錄，確認要覆蓋原檔案嗎？');
                        if (!confirmOverwrite) return;
                    }

                    this.isUploading = true;
                    try {
                        const formData = new FormData();
                        formData.append('action', 'upload');
                        formData.append('facId', this.uploadForm.FacId);
                        formData.append('year', this.uploadForm.Year);
                        formData.append('month', this.uploadForm.Month);
                        formData.append('file', this.selectedFile);

                        const res = await axios.post('ReportUpload_List.aspx?action=upload', formData, {
                            headers: { 'Content-Type': 'multipart/form-data' }
                        });

                        if (res.data && res.data.Success) {
                            alert(res.data.Message || '上傳成功！');
                            this.closeUploadModal();
                            this.loadCounts();
                            this.loadList();
                        } else {
                            alert(res.data ? res.data.Message : '檔案上傳失敗！');
                        }
                    } catch (err) {
                        console.error('submitUpload error:', err);
                        alert('上傳月報時發生網路或系統錯誤！');
                    } finally {
                        this.isUploading = false;
                    }
                },

                // 刪除紀錄
                confirmDelete(item) {
                    this.itemToDelete = item;
                    this.showDeleteModal = true;
                },

                async submitDelete() {
                    if (!this.itemToDelete) return;
                    this.isLoading = true;
                    try {
                        const params = new URLSearchParams({
                            action: 'deletereport',
                            id: this.itemToDelete.PID
                        });
                        const res = await axios.post('ReportUpload_List.aspx', params);
                        if (res.data && res.data.Success) {
                            alert(res.data.Message || '刪除成功！');
                            this.showDeleteModal = false;
                            this.itemToDelete = null;
                            this.loadCounts();
                            this.loadList();
                        } else {
                            alert(res.data ? res.data.Message : '刪除失敗！');
                        }
                    } catch (err) {
                        console.error('submitDelete error:', err);
                        alert('執行刪除操作時發生錯誤！');
                    } finally {
                        this.isLoading = false;
                    }
                },

                // 輔助格式化工具
                getFileBadgeClass(ext) {
                    if (!ext) return 'file-badge-other';
                    const e = ext.toLowerCase();
                    if (e === 'pdf') return 'file-badge-pdf';
                    if (e === 'xls' || e === 'xlsx') return 'file-badge-excel';
                    if (e === 'doc' || e === 'docx') return 'file-badge-word';
                    if (e === 'zip' || e === 'rar' || e === '7z') return 'file-badge-archive';
                    return 'file-badge-other';
                },

                getFileIcon(ext) {
                    if (!ext) return 'fas fa-file text-secondary';
                    const e = ext.toLowerCase();
                    if (e === 'pdf') return 'fas fa-file-pdf text-danger';
                    if (e === 'xls' || e === 'xlsx') return 'fas fa-file-excel text-success';
                    if (e === 'doc' || e === 'docx') return 'fas fa-file-word text-primary';
                    if (e === 'zip' || e === 'rar' || e === '7z') return 'fas fa-file-archive text-warning';
                    if (e === 'jpg' || e === 'jpeg' || e === 'png') return 'fas fa-file-image text-info';
                    return 'fas fa-file text-secondary';
                },

                formatFileSize(bytes) {
                    if (!bytes) return '0 B';
                    if (bytes >= 1024 * 1024) {
                        return (bytes / (1024 * 1024)).toFixed(2) + ' MB';
                    }
                    if (bytes >= 1024) {
                        return (bytes / 1024).toFixed(2) + ' KB';
                    }
                    return bytes + ' B';
                }
            }
        }).mount('#app');
    </script>
</body>
</html>
