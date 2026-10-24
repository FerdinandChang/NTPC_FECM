<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Dirty_List.aspx.cs" Inherits="NTPC_FEC.RoadClean.Dirty_List" %>
<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定溢散源管理平台 - 道路髒污管理清單</title>

    <!-- 專屬 Favicon -->
    <link rel="shortcut icon" href="../favicon.ico" type="image/x-icon" />

    <!-- Bootstrap 4 & FontAwesome 本地化樣式 -->
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

        /* 頂部指標統計卡片 */
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
            user-select: none;
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

        /* 篩選多選晶片標籤 */
        .filter-chip-group {
            display: flex;
            flex-wrap: wrap;
            gap: 6px;
        }

        .filter-chip {
            border: 1px solid #cbd5e1;
            background: #ffffff;
            color: #475569;
            font-size: 13px;
            font-weight: 600;
            padding: 5px 12px;
            border-radius: 20px;
            cursor: pointer;
            transition: all 0.15s ease;
            user-select: none;
        }

        .filter-chip:hover {
            border-color: var(--brand-blue);
            color: var(--brand-blue);
        }

        .filter-chip.active {
            background: #e0f2fe;
            border-color: #0284c7;
            color: #0369a1;
            font-weight: 700;
            box-shadow: 0 1px 3px rgba(2, 132, 199, 0.2);
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

        /* 污染類別徽章 */
        .kind-badge {
            display: inline-flex;
            align-items: center;
            gap: 5px;
            padding: 3px 9px;
            border-radius: 6px;
            font-size: 12px;
            font-weight: 700;
            white-space: nowrap !important;
        }

        .kind-eb {
            background: #fef3c7;
            color: #92400e;
            border: 1px solid #fde68a;
        }

        .kind-ef {
            background: #e0f2fe;
            color: #0369a1;
            border: 1px solid #bae6fd;
        }

        .kind-es {
            background: #f1f5f9;
            color: #334155;
            border: 1px solid #cbd5e1;
        }

        .kind-other {
            background: #f3f4f6;
            color: #4b5563;
            border: 1px solid #e5e7eb;
        }

        /* 案件狀態徽章 */
        .status-chip {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 4px 10px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 700;
            white-space: nowrap !important;
        }

        /* 坐標顯示晶片 */
        .coord-chip {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            color: #475569;
            font-size: 11px;
            font-weight: 600;
            padding: 2px 6px;
            border-radius: 4px;
            display: inline-flex;
            align-items: center;
            gap: 4px;
        }

        /* 操作按鈕群組 - 嚴格單行不換行 */
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
            text-decoration: none !important;
        }

        .btn-action:hover {
            transform: translateY(-1px);
        }

        @media (max-width: 767.98px) {
            .btn-action {
                flex: 1;
                justify-content: center;
                min-height: 42px;
                font-size: 14px;
            }
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

        /* 模態彈窗 (Modals) */
        .modal-overlay {
            position: fixed;
            top: 0; left: 0; right: 0; bottom: 0;
            background: rgba(15, 23, 42, 0.65);
            z-index: 1050;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 16px;
            backdrop-filter: blur(4px);
        }

        .modal-dialog-custom {
            background: #ffffff;
            border-radius: 12px;
            width: 100%;
            max-width: 820px;
            max-height: 90vh;
            display: flex;
            flex-direction: column;
            box-shadow: 0 10px 32px rgba(15, 23, 42, 0.25);
            overflow: hidden;
            animation: modalFadeIn 0.2s ease;
        }

        @keyframes modalFadeIn {
            from { opacity: 0; transform: scale(0.96); }
            to { opacity: 1; transform: scale(1); }
        }

        .modal-header-custom {
            padding: 16px 20px;
            background: linear-gradient(135deg, #0099e5 0%, #0284c7 100%);
            color: #ffffff;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .modal-body-custom {
            padding: 20px;
            overflow-y: auto;
            flex: 1;
        }

        .modal-footer-custom {
            padding: 14px 20px;
            background: #f8fafc;
            border-top: 1px solid var(--border-color);
            display: flex;
            justify-content: flex-end;
            gap: 10px;
        }

        /* 預覽照片網格 */
        .modal-photo-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
            gap: 12px;
            margin-top: 8px;
        }

        .modal-photo-card {
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            overflow: hidden;
            height: 115px;
            background: #0f172a;
            cursor: pointer;
            position: relative;
            box-shadow: 0 2px 6px rgba(0,0,0,0.05);
            transition: transform 0.15s ease;
        }

        .modal-photo-card:hover {
            transform: scale(1.03);
        }

        .modal-photo-card img {
            width: 100%;
            height: 100%;
            object-fit: cover;
        }

        .modal-photo-tag {
            position: absolute;
            bottom: 4px;
            left: 4px;
            background: rgba(15, 23, 42, 0.75);
            color: #ffffff;
            font-size: 10px;
            font-weight: 600;
            padding: 2px 6px;
            border-radius: 4px;
            backdrop-filter: blur(3px);
        }

        /* 全螢幕照片燈箱 (Lightbox) */
        .img-lightbox-overlay {
            position: fixed;
            top: 0; left: 0; right: 0; bottom: 0;
            background: rgba(15, 23, 42, 0.95);
            z-index: 2000;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
            backdrop-filter: blur(8px);
        }

        .img-lightbox-overlay img {
            max-width: 90vw;
            max-height: 85vh;
            border-radius: 8px;
            object-fit: contain;
            box-shadow: 0 10px 40px rgba(0, 0, 0, 0.5);
        }

        .lightbox-close-btn {
            position: absolute;
            top: 20px;
            right: 20px;
            background: rgba(255, 255, 255, 0.2);
            color: #ffffff;
            border: none;
            width: 44px;
            height: 44px;
            border-radius: 50%;
            font-size: 1.4rem;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: background 0.2s;
        }

        .lightbox-close-btn:hover {
            background: rgba(255, 255, 255, 0.4);
        }
    </style>
</head>
<body>
    <div id="dirtyListApp" v-cloak>
        <!-- 頂部品牌導覽列 -->
                <!-- 頂部品牌導覽列 (全站標準左側導航、右側主操作) -->
        <header class="top-navbar">
            <div class="d-flex align-items-center">
                <a href="../MainPage.aspx?sub=menu4" class="nav-btn mr-2" title="返回主選單">
                    <i class="fas fa-home"></i>
                    <span class="d-none d-sm-inline">回首頁</span>
                </a>
                <a href="Dirty_List.aspx" class="navbar-brand-title">
                    <i class="fas fa-trash-alt text-white"></i>
                    <span>路面髒污查核與通報管理</span>
                </a>
            </div>
            <div class="d-flex align-items-center gap-2">
                <a href="NewDirty.aspx?mode=new" class="btn btn-success btn-sm font-weight-bold shadow-sm mr-2">
                    <i class="fas fa-plus-circle mr-1"></i>
                    <span class="d-none d-sm-inline">新增髒污通報</span>
                </a>
            </div>
        </header>

        <!-- 業務模式分頁切換列 (比照 Clean_List 規範) -->
        <nav class="nav-mode-bar">
            <div class="nav-mode-item" :class="{ 'active': filter.Mode === 'DirtyEdit' }" v-on:click="switchMode('DirtyEdit')">
                <i class="fas fa-edit"></i>
                <span>查核紀錄暫存 (未通報)</span>
                <span class="tab-badge badge badge-secondary">{{ counts.EditCount }}</span>
            </div>

            <div class="nav-mode-item" :class="{ 'active': filter.Mode === 'DirtyImprove' }" v-on:click="switchMode('DirtyImprove')">
                <i class="fas fa-tools"></i>
                <span>路污改善回報 (處理中)</span>
                <span class="tab-badge badge badge-warning text-dark">{{ counts.ImproveCount }}</span>
            </div>

            <div class="nav-mode-item" :class="{ 'active': filter.Mode === 'Finish' }" v-on:click="switchMode('Finish')">
                <i class="fas fa-check-double"></i>
                <span>路污改善成果 (已完成)</span>
                <span class="tab-badge badge badge-success">{{ counts.FinishCount }}</span>
            </div>

            <div class="nav-mode-item" :class="{ 'active': filter.Mode === 'All' }" v-on:click="switchMode('All')">
                <i class="fas fa-layer-group"></i>
                <span>全部案件總覽</span>
                <span class="tab-badge badge badge-dark">{{ counts.TotalCount }}</span>
            </div>
        </nav>

        <main class="container-fluid py-4 px-lg-4">
            <!-- 頂部指標統計卡片群 (四欄對齊 Clean_List) -->
            <div class="row mb-3">
                <div class="col-6 col-lg-3 mb-2 mb-lg-0">
                    <div class="stat-card" v-on:click="switchMode('DirtyEdit')" style="cursor: pointer;">
                        <div class="stat-icon bg-light text-secondary">
                            <i class="fas fa-file-signature"></i>
                        </div>
                        <div>
                            <div class="stat-val">{{ counts.EditCount }}</div>
                            <div class="stat-label">未通報 / 暫存案件</div>
                        </div>
                    </div>
                </div>

                <div class="col-6 col-lg-3 mb-2 mb-lg-0">
                    <div class="stat-card" v-on:click="switchMode('DirtyImprove')" style="cursor: pointer;">
                        <div class="stat-icon bg-warning text-dark">
                            <i class="fas fa-exclamation-triangle"></i>
                        </div>
                        <div>
                            <div class="stat-val text-warning">{{ counts.ImproveCount }}</div>
                            <div class="stat-label">待改善回報案件</div>
                        </div>
                    </div>
                </div>

                <div class="col-6 col-lg-3 mb-2 mb-lg-0">
                    <div class="stat-card" v-on:click="switchMode('Finish')" style="cursor: pointer;">
                        <div class="stat-icon bg-success text-white">
                            <i class="fas fa-check-double"></i>
                        </div>
                        <div>
                            <div class="stat-val text-success">{{ counts.FinishCount }}</div>
                            <div class="stat-label">已完成改善成果</div>
                        </div>
                    </div>
                </div>

                <div class="col-6 col-lg-3 mb-2 mb-lg-0">
                    <div class="stat-card" v-on:click="switchMode('All')" style="cursor: pointer;">
                        <div class="stat-icon bg-primary text-white">
                            <i class="fas fa-layer-group"></i>
                        </div>
                        <div>
                            <div class="stat-val text-primary">{{ counts.TotalCount }}</div>
                            <div class="stat-label">全部道路髒污案件</div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- 案件條件篩選卡片 (完全對齊 Clean_List 樣板格式) -->
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
                        <!-- 通報案號關鍵字 -->
                        <div class="col-12 col-md-4 mb-3">
                            <label class="font-weight-bold text-muted small mb-1">
                                <i class="fas fa-hashtag text-primary mr-1"></i> 通報案號
                            </label>
                            <input type="text" class="form-control" v-model="filter.ShowId" 
                                   placeholder="輸入案號關鍵字搜尋..." v-on:keyup.enter="handleSearch" />
                        </div>

                        <!-- 處理單位選單 -->
                        <div class="col-12 col-md-4 mb-3">
                            <label class="font-weight-bold text-muted small mb-1">
                                <i class="fas fa-building text-info mr-1"></i> 處理權責單位
                            </label>
                            <select class="form-control" v-model="selectedUnit" v-on:change="onUnitChange" style="font-weight: 600;">
                                <option value="">全部處理單位 ({{ unitList.length }} 單位)</option>
                                <option v-for="u in unitList" :key="u.UnitId" :value="u.UnitId">
                                    {{ u.UnitName }}
                                </option>
                            </select>
                        </div>

                        <!-- 巡查起訖日期區間 -->
                        <div class="col-12 col-md-4 mb-3">
                            <label class="font-weight-bold text-muted small mb-1">
                                <i class="far fa-calendar-alt text-primary mr-1"></i> 查核起訖日期
                            </label>
                            <div class="d-flex align-items-center" style="width: 100%;">
                                <input type="date" class="form-control" style="flex: 1; min-width: 0;" v-model="filter.ReportDateS" />
                                <span class="mx-2 text-muted font-weight-bold">~</span>
                                <input type="date" class="form-control" style="flex: 1; min-width: 0;" v-model="filter.ReportDateE" />
                            </div>
                        </div>

                        <!-- 污染類型多選晶片 -->
                        <div class="col-12 mb-3">
                            <label class="font-weight-bold text-muted small mb-1">
                                <i class="fas fa-tags text-warning mr-1"></i> 污染類型 (可複選)
                            </label>
                            <div class="filter-chip-group">
                                <button type="button" class="filter-chip" :class="{ 'active': isKindSelected('EB') }" 
                                        v-on:click="toggleKind('EB')">
                                    <i class="fas fa-hard-hat mr-1"></i> 營建工程道路污染 (EB)
                                </button>
                                <button type="button" class="filter-chip" :class="{ 'active': isKindSelected('EF') }" 
                                        v-on:click="toggleKind('EF')">
                                    <i class="fas fa-industry mr-1"></i> 固定逸散道路污染 (EF)
                                </button>
                                <button type="button" class="filter-chip" :class="{ 'active': isKindSelected('ES') }" 
                                        v-on:click="toggleKind('ES')">
                                    <i class="fas fa-truck-moving mr-1"></i> 道路砂石堆積污染 (ES)
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- 快捷日期按鈕與搜尋列 (完全比照 Clean_List) -->
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

                    <!-- 查無資料 -->
                    <div v-else-if="caseList.length === 0" class="text-center py-5">
                        <div class="mb-3 text-muted" style="font-size: 3rem;">
                            <i class="far fa-folder-open"></i>
                        </div>
                        <h5 class="font-weight-bold text-secondary">查無符合條件的道路髒污紀錄</h5>
                        <p class="text-muted small">請嘗試放寬篩選條件或點選「不限日期」。</p>
                        <a href="NewDirty.aspx?mode=new" class="btn btn-primary font-weight-bold px-4 mt-2">
                            <i class="fas fa-plus mr-1"></i> 建立第一筆髒污通報單
                        </a>
                    </div>

                    <!-- 寬螢幕桌面端表格 (Desktop & Tablet) -->
                    <div v-else class="table-responsive d-none d-md-block">
                        <table class="table-modern">
                            <thead>
                                <tr>
                                    <th style="width: 150px;">通報案號</th>
                                    <th style="width: 170px;">污染類型</th>
                                    <th style="width: 160px;">查核時間 / 人員</th>
                                    <th style="width: 160px;">通報時間 / 人員</th>
                                    <th style="width: 170px;">處理單位 / 回報時間</th>
                                    <th>通報補充與現場坐標</th>
                                    <th style="width: 120px;">案件狀態</th>
                                    <th style="min-width: 220px; width: 220px; white-space: nowrap;" class="text-center">操作功能</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr v-for="item in caseList" :key="item.DirtyId">
                                    <!-- 通報案號 -->
                                    <td>
                                        <div class="font-weight-bold text-dark" style="font-size: 15px;">{{ item.ShowId }}</div>
                                        <small class="text-muted">案號: {{ item.DirtyId }}</small>
                                    </td>

                                    <!-- 污染類型 -->
                                    <td>
                                        <span class="kind-badge" :class="getKindClass(item.Kind)">
                                            <i :class="getKindIcon(item.Kind)"></i>
                                            <span>{{ item.KindName }}</span>
                                        </span>
                                    </td>

                                    <!-- 查核時間 / 人員 -->
                                    <td>
                                        <div class="small font-weight-bold text-secondary">{{ item.ReportDate || '--' }}</div>
                                        <small class="text-muted"><i class="fas fa-user-edit mr-1"></i> {{ item.ReportUserName || '未登錄' }}</small>
                                    </td>

                                    <!-- 通報時間 / 人員 -->
                                    <td>
                                        <div class="small font-weight-bold" :class="item.SetComDate ? 'text-secondary' : 'text-muted'">
                                            {{ item.SetComDate || '尚未通報' }}
                                        </div>
                                        <small v-if="item.S_UserName" class="text-muted">
                                            <i class="fas fa-paper-plane mr-1"></i> {{ item.S_UserName }}
                                        </small>
                                    </td>

                                    <!-- 處理單位 / 回報時間 -->
                                    <td>
                                        <div class="font-weight-bold text-dark">{{ item.G_ComName || '未派工' }}</div>
                                        <small v-if="item.ImproveDate" class="text-success font-weight-bold">
                                            <i class="fas fa-check-circle mr-1"></i> {{ item.ImproveDate }}
                                        </small>
                                    </td>

                                    <!-- 補充與坐標 -->
                                    <td>
                                        <div class="text-truncate" style="max-width: 260px;" :title="item.Comm">
                                            {{ item.Comm || '無特別補充' }}
                                        </div>
                                        <div class="mt-1" v-if="item.S_UTME > 0">
                                            <span class="coord-chip">
                                                <i class="fas fa-map-marker-alt text-danger"></i> TWD97: {{ Math.round(item.S_UTME) }}, {{ Math.round(item.S_UTMN) }}
                                            </span>
                                        </div>
                                    </td>

                                    <!-- 案件狀態 -->
                                    <td>
                                        <span class="badge px-2 py-1 font-weight-bold" :class="item.StatusBadgeClass" style="font-size: 12px;">
                                            {{ item.StatusText }}
                                        </span>
                                    </td>

                                    <!-- 功能按鈕群 (嚴格單行不換行) -->
                                    <td class="text-center" style="white-space: nowrap;">
                                        <div class="action-btn-group justify-content-center">
                                            <!-- 暫存未通報狀態 (StatusCode === 1) -->
                                            <template v-if="item.StatusCode === 1">
                                                <a :href="'NewDirty.aspx?id=' + encodeURIComponent(item.DirtyId) + '&mode=edit'" 
                                                   class="btn btn-sm btn-warning btn-action text-dark font-weight-bold" title="查核資料異動">
                                                    <i class="fas fa-pencil-alt"></i> 編輯
                                                </a>
                                                <a :href="'SetSG_Dirty.aspx?id=' + encodeURIComponent(item.DirtyId)" 
                                                   class="btn btn-sm btn-primary btn-action font-weight-bold" title="通報派工給權責單位">
                                                    <i class="fas fa-paper-plane"></i> 通報
                                                </a>
                                                <button type="button" class="btn btn-sm btn-info btn-action font-weight-bold" 
                                                        v-on:click="openCasePreview(item.DirtyId)" title="快速查看詳情">
                                                    <i class="fas fa-eye"></i> 詳情
                                                </button>
                                                <button type="button" class="btn btn-sm btn-outline-danger btn-action" 
                                                        v-on:click="openDeleteModal(item)" title="刪除案件">
                                                    <i class="fas fa-trash-alt"></i>
                                                </button>
                                            </template>

                                            <!-- 待改善回報狀態 (StatusCode === 2) -->
                                            <template v-else-if="item.StatusCode === 2">
                                                <a :href="'ImproveDirty.aspx?id=' + encodeURIComponent(item.DirtyId)" 
                                                   class="btn btn-sm btn-success btn-action font-weight-bold shadow-sm" title="填寫改善後成果回報">
                                                    <i class="fas fa-check-circle"></i> 改善回報
                                                </a>
                                                <button type="button" class="btn btn-sm btn-info btn-action font-weight-bold" 
                                                        v-on:click="openCasePreview(item.DirtyId)" title="快速查看詳情">
                                                    <i class="fas fa-eye"></i> 詳情
                                                </button>
                                            </template>

                                            <!-- 已完成改善成果 (StatusCode === 3) -->
                                            <template v-else>
                                                <button type="button" class="btn btn-sm btn-info btn-action font-weight-bold" 
                                                        v-on:click="openCasePreview(item.DirtyId)" title="查看改善成果詳情">
                                                    <i class="fas fa-file-alt"></i> 詳細資料
                                                </button>
                                            </template>
                                        </div>
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>

                    <!-- 手機端自適應卡片清單 (Mobile Cards) -->
                    <div class="d-block d-md-none p-3">
                        <div v-for="item in caseList" :key="item.DirtyId" class="mobile-card">
                            <div class="mobile-card-header">
                                <div class="d-flex align-items-center gap-2">
                                    <span class="kind-badge" :class="getKindClass(item.Kind)">
                                        {{ item.KindName }}
                                    </span>
                                    <span class="font-weight-bold text-dark">{{ item.ShowId }}</span>
                                </div>
                                <span class="badge px-2 py-1 font-weight-bold" :class="item.StatusBadgeClass">
                                    {{ item.StatusText }}
                                </span>
                            </div>

                            <div class="small text-muted mb-2">
                                <i class="far fa-clock mr-1"></i> {{ item.ReportDate }} 
                                <span class="ml-2"><i class="fas fa-user-edit mr-1"></i> {{ item.ReportUserName }}</span>
                            </div>

                            <div class="small text-dark font-weight-bold mb-2" v-if="item.G_ComName">
                                <i class="fas fa-building text-info mr-1"></i> 處理單位：{{ item.G_ComName }}
                                <span v-if="item.ImproveDate" class="text-success ml-2">({{ item.ImproveDate }} 改善)</span>
                            </div>

                            <!-- 補充說明與坐標 -->
                            <div class="p-2 bg-light rounded small text-secondary mb-3">
                                <div>{{ item.Comm || '無補充描述' }}</div>
                                <div class="mt-1 text-muted" v-if="item.S_UTME > 0">
                                    <i class="fas fa-map-marker-alt text-danger mr-1"></i>坐標: {{ Math.round(item.S_UTME) }}, {{ Math.round(item.S_UTMN) }}
                                </div>
                            </div>

                            <!-- 手機動作按鈕列 -->
                            <div class="action-btn-group pt-2 border-top">
                                <template v-if="item.StatusCode === 1">
                                    <a :href="'NewDirty.aspx?id=' + encodeURIComponent(item.DirtyId) + '&mode=edit'" class="btn btn-warning btn-action text-dark font-weight-bold">
                                        <i class="fas fa-pencil-alt"></i> 編輯
                                    </a>
                                    <a :href="'SetSG_Dirty.aspx?id=' + encodeURIComponent(item.DirtyId)" class="btn btn-primary btn-action font-weight-bold">
                                        <i class="fas fa-paper-plane"></i> 通報
                                    </a>
                                    <button type="button" class="btn btn-info btn-action font-weight-bold" v-on:click="openCasePreview(item.DirtyId)">
                                        <i class="fas fa-eye"></i> 詳情
                                    </button>
                                    <button type="button" class="btn btn-outline-danger btn-action" v-on:click="openDeleteModal(item)">
                                        <i class="fas fa-trash-alt"></i>
                                    </button>
                                </template>
                                <template v-else-if="item.StatusCode === 2">
                                    <a :href="'ImproveDirty.aspx?id=' + encodeURIComponent(item.DirtyId)" class="btn btn-success btn-action font-weight-bold shadow-sm">
                                        <i class="fas fa-check-circle"></i> 改善回報
                                    </a>
                                    <button type="button" class="btn btn-info btn-action font-weight-bold" v-on:click="openCasePreview(item.DirtyId)">
                                        <i class="fas fa-eye"></i> 詳情
                                    </button>
                                </template>
                                <template v-else>
                                    <button type="button" class="btn btn-info btn-action font-weight-bold" v-on:click="openCasePreview(item.DirtyId)">
                                        <i class="fas fa-file-alt"></i> 詳細資料
                                    </button>
                                </template>
                            </div>
                        </div>
                    </div>

                    <!-- 分頁導覽列 (Server-side Pagination 對齊 Clean_List) -->
                    <div v-if="totalCount > 0" class="pagination-container">
                        <div class="d-flex align-items-center gap-2 small text-muted font-weight-bold">
                            <span>顯示第 {{ (filter.PageIndex - 1) * filter.PageSize + 1 }} ~ {{ Math.min(filter.PageIndex * filter.PageSize, totalCount) }} 筆，共 {{ totalCount }} 筆</span>
                            <span class="mx-2">|</span>
                            <span>每頁</span>
                            <select class="custom-select custom-select-sm" style="width: 75px;" v-model.number="filter.PageSize" v-on:change="onPageSizeChange">
                                <option :value="10">10</option>
                                <option :value="20">20</option>
                                <option :value="50">50</option>
                                <option :value="100">100</option>
                            </select>
                            <span>筆</span>
                        </div>

                        <!-- 頁碼切換按鈕群 -->
                        <div class="d-flex align-items-center gap-1">
                            <button type="button" class="page-link-custom" :class="{ 'disabled': filter.PageIndex <= 1 }" v-on:click="gotoPage(1)" title="第一頁">
                                <i class="fas fa-angle-double-left"></i>
                            </button>
                            <button type="button" class="page-link-custom" :class="{ 'disabled': filter.PageIndex <= 1 }" v-on:click="gotoPage(filter.PageIndex - 1)" title="上一頁">
                                <i class="fas fa-angle-left"></i>
                            </button>

                            <template v-for="p in pageRange" :key="p">
                                <button v-if="p !== '...'" type="button" class="page-link-custom" :class="{ 'active': filter.PageIndex === p }" v-on:click="gotoPage(p)">
                                    {{ p }}
                                </button>
                                <span v-else class="px-2 text-muted">...</span>
                            </template>

                            <button type="button" class="page-link-custom" :class="{ 'disabled': filter.PageIndex >= totalPages }" v-on:click="gotoPage(filter.PageIndex + 1)" title="下一頁">
                                <i class="fas fa-angle-right"></i>
                            </button>
                            <button type="button" class="page-link-custom" :class="{ 'disabled': filter.PageIndex >= totalPages }" v-on:click="gotoPage(totalPages)" title="最末頁">
                                <i class="fas fa-angle-double-right"></i>
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </main>

        <!-- 1. 案件快速詳情預覽對話框 (Detail Preview Modal) -->
        <div v-if="previewCase" class="modal-overlay" v-on:click.self="previewCase = null">
            <div class="modal-dialog-custom">
                <div class="modal-header-custom">
                    <h5 class="modal-title font-weight-bold m-0" style="font-size: 1.1rem;">
                        <i class="fas fa-file-invoice mr-2"></i> 道路髒污通報單 - {{ previewCase.ShowId }}
                    </h5>
                    <button type="button" class="close text-white" v-on:click="previewCase = null" style="font-size: 1.5rem; opacity: 0.9;">
                        &times;
                    </button>
                </div>
                <div class="modal-body-custom">
                    <!-- 基本資料摘要 -->
                    <div class="bg-light p-3 rounded mb-3 border">
                        <div class="row">
                            <div class="col-6 col-md-4 mb-2">
                                <small class="text-muted d-block font-weight-bold">查核時間</small>
                                <span class="font-weight-bold text-dark">{{ previewCase.ReportDate }}</span>
                            </div>
                            <div class="col-6 col-md-4 mb-2">
                                <small class="text-muted d-block font-weight-bold">查核填報人員</small>
                                <span class="font-weight-bold text-dark">{{ previewCase.ReportUserName }}</span>
                            </div>
                            <div class="col-6 col-md-4 mb-2">
                                <small class="text-muted d-block font-weight-bold">污染類型</small>
                                <span class="kind-badge" :class="getKindClass(previewCase.Kind)">{{ previewCase.KindName }}</span>
                            </div>
                            <div class="col-6 col-md-4 mb-2">
                                <small class="text-muted d-block font-weight-bold">通報派工時間 / 人員</small>
                                <span>{{ previewCase.SetComDate || '尚未通報' }} {{ previewCase.S_UserName ? '(' + previewCase.S_UserName + ')' : '' }}</span>
                            </div>
                            <div class="col-6 col-md-4 mb-2">
                                <small class="text-muted d-block font-weight-bold">處理權責單位</small>
                                <span class="font-weight-bold text-primary">{{ previewCase.G_ComName || '未派工' }}</span>
                            </div>
                            <div class="col-6 col-md-4 mb-2">
                                <small class="text-muted d-block font-weight-bold">改善回報時間 / 人員</small>
                                <span class="text-success font-weight-bold">{{ previewCase.ImproveDate || '未回報' }} {{ previewCase.G_UserName ? '(' + previewCase.G_UserName + ')' : '' }}</span>
                            </div>
                            <div class="col-12 mb-2">
                                <small class="text-muted d-block font-weight-bold">通報坐標 (TWD97)</small>
                                <span class="coord-chip mr-2">坐標 1: {{ Math.round(previewCase.S_UTME) }}, {{ Math.round(previewCase.S_UTMN) }}</span>
                                <span v-if="previewCase.S_UTME1 > 0" class="coord-chip">
                                    坐標 2: {{ Math.round(previewCase.S_UTME1) }}, {{ Math.round(previewCase.S_UTMN1) }}
                                </span>
                            </div>
                            <div class="col-12">
                                <small class="text-muted d-block font-weight-bold">補充說明與路況特徵</small>
                                <div class="p-2 bg-white rounded border text-secondary font-weight-bold mt-1">
                                    {{ previewCase.Comm || '無補充描述' }}
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- 現場照片 -->
                    <div class="mb-3">
                        <h6 class="font-weight-bold text-danger">
                            <i class="fas fa-camera mr-1"></i> 疑似髒污點現場照片 ({{ (previewCase.Photos1 || []).length }} 張)
                        </h6>
                        <div v-if="(previewCase.Photos1 || []).length > 0" class="modal-photo-grid">
                            <div v-for="(p, idx) in previewCase.Photos1" :key="idx" class="modal-photo-card" 
                                 v-on:click="openFullImage(p.Url)">
                                <img :src="p.Url" alt="現場照片" />
                                <span class="modal-photo-tag">照片 {{ idx + 1 }}</span>
                            </div>
                        </div>
                        <div v-else class="text-muted small py-2 bg-light rounded text-center">尚無疑似髒污點照片</div>
                    </div>

                    <!-- 佐證照片 -->
                    <div class="mb-3">
                        <h6 class="font-weight-bold text-info">
                            <i class="fas fa-clipboard-check mr-1"></i> 佐證照片 ({{ (previewCase.Photos2 || []).length }} 張)
                        </h6>
                        <div v-if="(previewCase.Photos2 || []).length > 0" class="modal-photo-grid">
                            <div v-for="(p, idx) in previewCase.Photos2" :key="idx" class="modal-photo-card" 
                                 v-on:click="openFullImage(p.Url)">
                                <img :src="p.Url" alt="佐證照片" />
                                <span class="modal-photo-tag">佐證 {{ idx + 1 }}</span>
                            </div>
                        </div>
                        <div v-else class="text-muted small py-2 bg-light rounded text-center">尚無佐證照片</div>
                    </div>

                    <!-- 改善成果照片 -->
                    <div v-if="(previewCase.ImprovePhotos || []).length > 0">
                        <h6 class="font-weight-bold text-success">
                            <i class="fas fa-check-circle mr-1"></i> 改善後成果照片 ({{ previewCase.ImprovePhotos.length }} 張)
                        </h6>
                        <div class="modal-photo-grid">
                            <div v-for="(p, idx) in previewCase.ImprovePhotos" :key="idx" class="modal-photo-card" 
                                 v-on:click="openFullImage(p.Url)">
                                <img :src="p.Url" alt="改善照片" />
                                <span class="modal-photo-tag">改善後 {{ idx + 1 }}</span>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="modal-footer-custom">
                    <a :href="'DirtyDetail.aspx?id=' + encodeURIComponent(previewCase.DirtyId)" class="btn btn-outline-primary font-weight-bold px-3">
                        <i class="fas fa-external-link-alt mr-1"></i> 開啟完整報告單
                    </a>
                    <button type="button" class="btn btn-secondary font-weight-bold px-4" v-on:click="previewCase = null">關閉</button>
                </div>
            </div>
        </div>

        <!-- 2. 刪除確認對話框 (Delete Modal) -->
        <div v-if="deleteTarget" class="modal-overlay" v-on:click.self="deleteTarget = null">
            <div class="modal-dialog-custom" style="max-width: 480px;">
                <div class="modal-body-custom p-4 text-center">
                    <div class="text-danger mb-3" style="font-size: 3.2rem;">
                        <i class="fas fa-exclamation-circle"></i>
                    </div>
                    <h5 class="font-weight-bold text-dark mb-2">確定要刪除這筆髒污通報紀錄嗎？</h5>
                    <p class="text-muted small mb-4">
                        通報案號：<strong>{{ deleteTarget.ShowId }}</strong><br />
                        刪除後相關案件資料與磁碟上傳照片將一併清理，此操作無法復原！
                    </p>
                    <div class="d-flex justify-content-center gap-2">
                        <button type="button" class="btn btn-secondary font-weight-bold px-4 mr-2" v-on:click="deleteTarget = null">取消</button>
                        <button type="button" class="btn btn-danger font-weight-bold px-4" :disabled="submitting" v-on:click="confirmDelete">
                            <span v-if="!submitting">確定刪除</span>
                            <span v-else>處理中...</span>
                        </button>
                    </div>
                </div>
            </div>
        </div>

        <!-- 3. 全螢幕照片燈箱 (Lightbox) -->
        <div v-if="lightboxImgUrl" class="img-lightbox-overlay" v-on:click.self="lightboxImgUrl = null">
            <button type="button" class="lightbox-close-btn" v-on:click="lightboxImgUrl = null">&times;</button>
            <img :src="lightboxImgUrl" alt="放大照片" />
        </div>
    </div>

    <!-- 本地核心腳本依賴 -->
    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>

    <script>
        const { createApp } = Vue;

        createApp({
            data() {
                return {
                    loading: false,
                    submitting: false,
                    counts: {
                        EditCount: 0,
                        ImproveCount: 0,
                        FinishCount: 0,
                        TotalCount: 0
                    },
                    unitList: [],
                    selectedUnit: '',
                    filter: {
                        Mode: 'DirtyEdit', // 'DirtyEdit', 'DirtyImprove', 'Finish', 'All'
                        ShowId: '',
                        Kinds: [],
                        Units: [],
                        ReportDateS: '',
                        ReportDateE: '',
                        SetComDateS: '',
                        SetComDateE: '',
                        ImproveDateS: '',
                        ImproveDateE: '',
                        PageIndex: 1,
                        PageSize: 20
                    },
                    totalCount: 0,
                    caseList: [],
                    previewCase: null,
                    deleteTarget: null,
                    lightboxImgUrl: null
                };
            },
            computed: {
                totalPages() {
                    return Math.max(1, Math.ceil(this.totalCount / this.filter.PageSize));
                },
                pageRange() {
                    const current = this.filter.PageIndex;
                    const total = this.totalPages;
                    const delta = 2;
                    const range = [];
                    const rangeWithDots = [];
                    let l;

                    for (let i = 1; i <= total; i++) {
                        if (i === 1 || i === total || (i >= current - delta && i <= current + delta)) {
                            range.push(i);
                        }
                    }

                    for (let i of range) {
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
                // 從網址讀取 mode 參數
                const urlParams = new URLSearchParams(window.location.search);
                const qMode = urlParams.get('mode');
                if (qMode) {
                    this.filter.Mode = qMode;
                }

                this.loadUnits();
                this.loadCounts();
                this.loadList();
            },
            methods: {
                // 1. 標題切換
                getModeTitle() {
                    if (this.filter.Mode === 'DirtyEdit') return '查核紀錄暫存清單 (未通報)';
                    if (this.filter.Mode === 'DirtyImprove') return '路污改善回報清單 (處理中)';
                    if (this.filter.Mode === 'Finish') return '路污改善成果列表 (已結案)';
                    return '全部道路髒污案件總覽';
                },

                // 2. 切換業務階段 Tab
                switchMode(mode) {
                    if (this.filter.Mode === mode) return;
                    this.filter.Mode = mode;
                    this.filter.PageIndex = 1;

                    // 同步 URL 不重新整理頁面
                    const newUrl = window.location.pathname + '?mode=' + encodeURIComponent(mode);
                    window.history.pushState({ path: newUrl }, '', newUrl);

                    this.loadCounts();
                    this.loadList();
                },

                // 3. 取得階段統計數量
                loadCounts() {
                    axios.get('Dirty_List.aspx?action=getcounts').then(res => {
                        if (res.data && res.data.Success) {
                            this.counts = res.data.Data;
                        }
                    }).catch(() => {});
                },

                // 4. 取得處理單位清單
                loadUnits() {
                    axios.get('Dirty_List.aspx?action=getunits').then(res => {
                        if (res.data && res.data.Success) {
                            this.unitList = res.data.Data || [];
                        }
                    }).catch(() => {});
                },

                // 5. 取得案件列表
                loadList() {
                    this.loading = true;
                    axios.post('Dirty_List.aspx?action=getlist', this.filter).then(res => {
                        this.loading = false;
                        if (res.data && res.data.Success) {
                            this.caseList = res.data.Items || [];
                            this.totalCount = res.data.TotalCount || 0;
                            this.filter.PageIndex = res.data.PageIndex || 1;
                        }
                    }).catch(err => {
                        this.loading = false;
                        alert('載入清單失敗：' + err.message);
                    });
                },

                // 6. 搜尋與重設
                handleSearch() {
                    this.filter.PageIndex = 1;
                    this.loadList();
                    this.loadCounts();
                },
                resetFilter() {
                    this.filter.ShowId = '';
                    this.filter.Kinds = [];
                    this.filter.Units = [];
                    this.selectedUnit = '';
                    this.filter.ReportDateS = '';
                    this.filter.ReportDateE = '';
                    this.filter.SetComDateS = '';
                    this.filter.SetComDateE = '';
                    this.filter.ImproveDateS = '';
                    this.filter.ImproveDateE = '';
                    this.filter.PageIndex = 1;
                    this.loadList();
                    this.loadCounts();
                },

                // 7. 日期快捷切換 (對齊 Clean_List)
                setDateShortcut(type) {
                    const now = new Date();
                    const formatDate = d => {
                        const y = d.getFullYear();
                        const m = String(d.getMonth() + 1).padStart(2, '0');
                        const day = String(d.getDate()).padStart(2, '0');
                        return y + '-' + m + '-' + day;
                    };

                    if (type === 'all') {
                        this.filter.ReportDateS = '';
                        this.filter.ReportDateE = '';
                    } else if (type === 'today') {
                        const s = formatDate(now);
                        this.filter.ReportDateS = s;
                        this.filter.ReportDateE = s;
                    } else if (type === 'week') {
                        const past = new Date(now.getTime() - 6 * 24 * 60 * 60 * 1000);
                        this.filter.ReportDateS = formatDate(past);
                        this.filter.ReportDateE = formatDate(now);
                    } else if (type === 'month') {
                        const past = new Date(now.getFullYear(), now.getMonth() - 1, now.getDate());
                        this.filter.ReportDateS = formatDate(past);
                        this.filter.ReportDateE = formatDate(now);
                    } else if (type === 'quarter') {
                        const past = new Date(now.getFullYear(), now.getMonth() - 3, now.getDate());
                        this.filter.ReportDateS = formatDate(past);
                        this.filter.ReportDateE = formatDate(now);
                    }
                    this.handleSearch();
                },

                // 8. 污染類別多選操作
                isKindSelected(kind) {
                    return this.filter.Kinds.indexOf(kind) >= 0;
                },
                toggleKind(kind) {
                    const idx = this.filter.Kinds.indexOf(kind);
                    if (idx >= 0) {
                        this.filter.Kinds.splice(idx, 1);
                    } else {
                        this.filter.Kinds.push(kind);
                    }
                    this.handleSearch();
                },

                // 9. 處理單位變更
                onUnitChange() {
                    this.filter.Units = this.selectedUnit ? [this.selectedUnit] : [];
                    this.handleSearch();
                },

                // 10. 分頁操作 (對齊 Clean_List)
                gotoPage(p) {
                    if (p < 1 || p > this.totalPages || p === this.filter.PageIndex) return;
                    this.filter.PageIndex = p;
                    this.loadList();
                },
                onPageSizeChange() {
                    this.filter.PageIndex = 1;
                    this.loadList();
                },

                // 11. 快速詳情預覽 Modal
                openCasePreview(dirtyId) {
                    axios.get('Dirty_List.aspx?action=getcasepreview&id=' + encodeURIComponent(dirtyId)).then(res => {
                        if (res.data && res.data.Success) {
                            this.previewCase = res.data.Data;
                        } else {
                            alert(res.data ? res.data.Message : '載入案件詳情失敗');
                        }
                    }).catch(err => {
                        alert('讀取詳情發生錯誤：' + err.message);
                    });
                },
                openFullImage(url) {
                    this.lightboxImgUrl = url;
                },

                // 12. 刪除確認 Modal
                openDeleteModal(item) {
                    this.deleteTarget = item;
                },
                confirmDelete() {
                    if (!this.deleteTarget) return;
                    this.submitting = true;
                    axios.post('Dirty_List.aspx?action=delete', { DirtyId: this.deleteTarget.DirtyId }).then(res => {
                        this.submitting = false;
                        if (res.data && res.data.Success) {
                            this.deleteTarget = null;
                            this.loadList();
                            this.loadCounts();
                        } else {
                            alert(res.data ? res.data.Message : '刪除失敗');
                        }
                    }).catch(err => {
                        this.submitting = false;
                        alert('刪除操作失敗：' + err.message);
                    });
                },

                // 13. 樣式與圖標工具
                getKindClass(kind) {
                    if (kind === 'EB') return 'kind-eb';
                    if (kind === 'EF') return 'kind-ef';
                    if (kind === 'ES') return 'kind-es';
                    return 'kind-other';
                },
                getKindIcon(kind) {
                    if (kind === 'EB') return 'fas fa-hard-hat';
                    if (kind === 'EF') return 'fas fa-industry';
                    if (kind === 'ES') return 'fas fa-truck-moving';
                    return 'fas fa-tag';
                },

                // 14. 匯出篩選結果為 EXCEL
                exportExcel() {
                    const form = document.createElement('form');
                    form.method = 'POST';
                    form.action = 'Dirty_List.aspx?action=export';
                    form.style.display = 'none';

                    const input = document.createElement('input');
                    input.type = 'hidden';
                    input.name = 'filterJson';
                    input.value = JSON.stringify(this.filter);
                    form.appendChild(input);

                    document.body.appendChild(form);
                    form.submit();
                    document.body.removeChild(form);
                }
            }
        }).mount('#dirtyListApp');
    </script>
</body>
</html>
