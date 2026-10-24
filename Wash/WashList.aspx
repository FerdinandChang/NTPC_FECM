<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="WashList.aspx.cs" Inherits="NTPC_FEC.Wash.WashList" %>
<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定溢散源管理平台 - 道路認養洗/掃街里程日誌</title>

    <!-- 專屬 Favicon -->
    <link rel="shortcut icon" href="../favicon.ico" type="image/x-icon" />

    <!-- 本地化樣式依賴 (Bootstrap 4 & FontAwesome) -->
    <link rel="stylesheet" href="../Content/bootstrap.min.css" />
    <link rel="stylesheet" href="../Content/fontawesome/css/all.min.css" />

    <style>
        :root {
            --brand-primary: #0099e5;     /* 新北天空青藍 */
            --brand-navy: #0f172a;        /* 標題深色 */
            --brand-blue: #0284c7;        /* 科技藍 */
            --brand-dark-blue: #0b1f7d;   /* 海軍深藍 */
            --bg-canvas: #f8fafc;         /* 頁面灰底 */
            --surface: #ffffff;           /* 卡片純白底色 */
            --border-color: #e2e8f0;      /* 邊框線條 */
            --text-main: #0f172a;         /* 內文主要文字 */
            --text-muted: #64748b;        /* 次要說明文字 */
            --status-wash: #0284c7;       /* 洗街藍 */
            --status-sweep: #f59e0b;      /* 掃街橙 */
            --status-both: #10b981;       /* 洗+掃綠 */
            --danger-color: #ef4444;      /* 刪除警告紅 */
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

        .nav-btn {
            background: rgba(255, 255, 255, 0.18);
            border: 1px solid rgba(255, 255, 255, 0.35);
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
            transition: all 0.2s;
            text-decoration: none;
        }

        .nav-btn:hover {
            background: rgba(255, 255, 255, 0.3);
            color: #ffffff;
            text-decoration: none;
        }

        .nav-btn-highlight {
            background: #ffffff;
            border: 1px solid #ffffff;
            color: var(--brand-blue) !important;
            box-shadow: 0 2px 6px rgba(0, 0, 0, 0.15);
        }

        .nav-btn-highlight:hover {
            background: #f0fdf4;
            color: #047857 !important;
        }

        /* 統計指標卡片 */
        .stat-card {
            background: var(--surface);
            border-radius: 12px;
            border: 1px solid var(--border-color);
            padding: 16px 18px;
            display: flex;
            align-items: center;
            gap: 16px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04), 0 4px 10px rgba(15, 23, 42, 0.03);
            transition: transform 0.2s, box-shadow 0.2s;
            height: 100%;
        }

        .stat-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 14px rgba(15, 23, 42, 0.08);
        }

        .stat-icon {
            width: 48px;
            height: 48px;
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.4rem;
            flex-shrink: 0;
        }

        .stat-val {
            font-size: 1.6rem;
            font-weight: 800;
            line-height: 1.2;
            color: var(--brand-navy);
        }

        .stat-label {
            font-size: 13px;
            font-weight: 600;
            color: var(--text-muted);
            margin-top: 2px;
        }

        .stat-sub {
            font-size: 11px;
            color: #94a3b8;
            margin-top: 2px;
        }

        /* 現代卡片容器 */
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

        /* 月份快捷切換 Pills */
        .month-pills-container {
            display: flex;
            flex-wrap: wrap;
            gap: 6px;
            align-items: center;
        }

        .month-pill-btn {
            border: 1px solid #e2e8f0;
            background: #ffffff;
            color: #475569;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 12.5px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.15s ease;
        }

        .month-pill-btn:hover {
            border-color: var(--brand-blue);
            color: var(--brand-blue);
            background: #f0f9ff;
        }

        .month-pill-btn.active {
            background: var(--brand-blue);
            border-color: var(--brand-blue);
            color: #ffffff;
            box-shadow: 0 2px 6px rgba(2, 132, 199, 0.35);
        }

        /* 模式切換頁籤 */
        .nav-mode-bar {
            background: #ffffff;
            border-bottom: 1px solid var(--border-color);
            padding: 0 20px;
            display: flex;
            gap: 8px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.03);
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
            padding: 14px 16px;
            border-bottom: 2px solid var(--border-color);
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

        /* 執行方式晶片 Badge */
        .type-badge {
            display: inline-flex;
            align-items: center;
            gap: 5px;
            padding: 4px 10px;
            border-radius: 6px;
            font-weight: 700;
            font-size: 12.5px;
            white-space: nowrap;
        }

        .type-badge-wash {
            background: #e0f2fe;
            color: #0369a1;
            border: 1px solid #7dd3fc;
        }

        .type-badge-sweep {
            background: #fef3c7;
            color: #b45309;
            border: 1px solid #fcd34d;
        }

        .type-badge-both {
            background: #dcfce7;
            color: #15803d;
            border: 1px solid #86efac;
        }

        /* 照片縮圖元件 */
        .photo-thumb-box {
            display: inline-flex;
            align-items: center;
            gap: 8px;
        }

        .thumb-img-wrapper {
            position: relative;
            width: 58px;
            height: 58px;
            border-radius: 8px;
            overflow: hidden;
            border: 2px solid #e2e8f0;
            cursor: pointer;
            box-shadow: 0 1px 4px rgba(0, 0, 0, 0.08);
            transition: transform 0.2s, border-color 0.2s;
            background: #f1f5f9;
        }

        .thumb-img-wrapper:hover {
            transform: scale(1.06);
            border-color: var(--brand-blue);
        }

        .thumb-img {
            width: 100%;
            height: 100%;
            object-fit: cover;
            display: block;
        }

        .thumb-tag {
            position: absolute;
            bottom: 0;
            left: 0;
            right: 0;
            background: rgba(15, 23, 42, 0.75);
            color: #ffffff;
            font-size: 10px;
            font-weight: 600;
            text-align: center;
            padding: 1px 0;
            line-height: 1.2;
        }

        .thumb-empty {
            width: 58px;
            height: 58px;
            border-radius: 8px;
            border: 1px dashed #cbd5e1;
            display: inline-flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            font-size: 10.5px;
            color: #94a3b8;
            background: #f8fafc;
        }

        /* 動作按鈕群 */
        .btn-action {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 4px;
            height: 34px;
            padding: 0 12px;
            border-radius: 6px;
            font-size: 13px;
            font-weight: 600;
            cursor: pointer;
            border: 1px solid transparent;
            transition: all 0.15s ease;
            text-decoration: none !important;
        }

        .btn-action-edit {
            background: #f0f9ff;
            color: #0284c7;
            border-color: #bae6fd;
        }

        .btn-action-edit:hover {
            background: #0284c7;
            color: #ffffff;
        }

        .btn-action-del {
            background: #fef2f2;
            color: #ef4444;
            border-color: #fecaca;
        }

        .btn-action-del:hover {
            background: #ef4444;
            color: #ffffff;
        }

        /* 月曆時間軸展示 (Calendar Grid) */
        .calendar-grid {
            display: grid;
            grid-template-columns: repeat(7, 1fr);
            gap: 12px;
        }

        .cal-day-card {
            background: #ffffff;
            border-radius: 10px;
            border: 1px solid var(--border-color);
            padding: 12px;
            min-height: 110px;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            transition: all 0.2s ease;
        }

        .cal-day-card:hover {
            border-color: var(--brand-blue);
            box-shadow: 0 3px 8px rgba(2, 132, 199, 0.12);
        }

        .cal-day-card.has-data {
            background: #f0fdf4;
            border-color: #86efac;
        }

        .cal-day-card.is-today {
            border: 2px solid var(--brand-blue);
            background: #f0f9ff;
        }

        .cal-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 6px;
        }

        .cal-date-num {
            font-size: 1.15rem;
            font-weight: 800;
            color: var(--brand-navy);
        }

        .cal-dow {
            font-size: 11.5px;
            font-weight: 600;
            color: #64748b;
        }

        .cal-dow.text-weekend {
            color: #ef4444;
        }

        .cal-body {
            font-size: 12px;
            color: #334155;
            flex-grow: 1;
        }

        /* 手機外勤卡片 (Mobile Card View) */
        .mobile-record-card {
            background: #ffffff;
            border-radius: 12px;
            border: 1px solid var(--border-color);
            padding: 16px;
            margin-bottom: 14px;
            box-shadow: 0 1px 4px rgba(0, 0, 0, 0.05);
        }

        .mobile-record-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            border-bottom: 1px solid #f1f5f9;
            padding-bottom: 10px;
            margin-bottom: 10px;
        }

        .mobile-record-actions {
            display: flex;
            gap: 8px;
            margin-top: 12px;
            padding-top: 10px;
            border-top: 1px solid #f1f5f9;
        }

        .mobile-record-actions .btn-action {
            flex: 1;
            min-height: 42px;
            font-size: 14px;
        }

        /* 燈箱 Modal */
        .modal-mask {
            position: fixed;
            top: 0; left: 0; right: 0; bottom: 0;
            background: rgba(15, 23, 42, 0.7);
            backdrop-filter: blur(4px);
            z-index: 1050;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 16px;
            animation: fadeIn 0.15s ease;
        }

        .modal-box {
            background: #ffffff;
            border-radius: 16px;
            max-width: 680px;
            width: 100%;
            overflow: hidden;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.25);
            animation: zoomIn 0.2s ease;
        }

        @keyframes fadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }

        @keyframes zoomIn {
            from { opacity: 0; transform: scale(0.95); }
            to { opacity: 1; transform: scale(1); }
        }

        /* 浮動 Toast 輕提示 */
        .toast-notify {
            position: fixed;
            top: 76px;
            left: 50%;
            transform: translateX(-50%);
            z-index: 1090;
            padding: 12px 24px;
            border-radius: 30px;
            color: #ffffff;
            font-weight: 600;
            font-size: 14px;
            display: flex;
            align-items: center;
            gap: 10px;
            box-shadow: 0 4px 16px rgba(0, 0, 0, 0.2);
            animation: slideDownToast 0.25s ease;
        }

        @keyframes slideDownToast {
            from { opacity: 0; transform: translate(-50%, -15px); }
            to { opacity: 1; transform: translate(-50%, 0); }
        }

        .toast-success { background: #10b981; }
        .toast-danger  { background: #ef4444; }
        .toast-info    { background: #0284c7; }

        @media screen and (max-width: 768px) {
            .calendar-grid {
                grid-template-columns: repeat(2, 1fr);
            }
            .stat-val { font-size: 1.35rem; }
        }
    </style>
</head>
<body>
    <div id="washApp" v-cloak>
        <!-- 頂部品牌導覽列 -->
        <header class="top-navbar">
            <div class="d-flex align-items-center">
                <a href="../Index.aspx" class="nav-btn mr-2" title="返回管理平台首頁">
                    <i class="fas fa-home"></i>
                </a>
                <span class="navbar-brand-title">
                    <i class="fas fa-tint text-warning"></i>
                    <span>道路認養洗/掃街里程日誌</span>
                </span>
            </div>

            <div class="d-flex align-items-center gap-2">
                <!-- 月報管理按鈕 -->
                <a href="ReportUpload_List.aspx" class="nav-btn d-none d-md-inline-flex" title="洗掃月報上傳管理">
                    <i class="fas fa-file-upload"></i>
                    <span>月報管理</span>
                </a>

                <!-- 匯出 Excel 按鈕 -->
                <button type="button" class="nav-btn d-none d-sm-inline-flex" v-on:click="exportExcel" :disabled="loading || records.length === 0" title="匯出本月洗掃日誌 Excel 報表">
                    <i class="fas fa-file-excel text-success"></i>
                    <span>匯出 Excel</span>
                </button>

                <!-- 新增日誌按鈕 -->
                <a :href="newRecordUrl" class="nav-btn nav-btn-highlight" title="填報全新洗掃日誌">
                    <i class="fas fa-plus"></i>
                    <span>填報日誌</span>
                </a>

                <!-- 場所或使用者徽章 -->
                <span class="badge badge-light text-dark px-2 py-1 ml-2 d-none d-lg-inline-flex align-items-center" style="font-size: 12px; height: 32px;">
                    <i class="fas fa-user-circle text-primary mr-1"></i>
                    {{ userName || '使用者' }}
                </span>
            </div>
        </header>

        <!-- Toast 訊息提示 -->
        <div v-if="toast.show" :class="['toast-notify', 'toast-' + toast.type]">
            <i :class="toast.icon"></i>
            <span>{{ toast.message }}</span>
        </div>

        <main class="container-fluid py-3 px-lg-4">
            <!-- 頂部 KPI 統計看板 -->
            <div class="row mb-3">
                <div class="col-6 col-lg-2 mb-2 mb-lg-0">
                    <div class="stat-card">
                        <div class="stat-icon" style="background: #e0f2fe; color: #0284c7;">
                            <i class="fas fa-calendar-check"></i>
                        </div>
                        <div>
                            <div class="stat-val">{{ kpi.TotalCount }} <small style="font-size: 13px;">次</small></div>
                            <div class="stat-label">本月作業總次數</div>
                            <div class="stat-sub">執勤天數: {{ kpi.ActiveDays }} 天</div>
                        </div>
                    </div>
                </div>

                <div class="col-6 col-lg-2 mb-2 mb-lg-0">
                    <div class="stat-card">
                        <div class="stat-icon" style="background: #e0f2fe; color: #0284c7;">
                            <i class="fas fa-shower"></i>
                        </div>
                        <div>
                            <div class="stat-val">{{ kpi.WashLength }} <small style="font-size: 13px;">m</small></div>
                            <div class="stat-label">累計洗街長度</div>
                            <div class="stat-sub">{{ (kpi.WashLength / 1000).toFixed(2) }} km</div>
                        </div>
                    </div>
                </div>

                <div class="col-6 col-lg-2 mb-2 mb-lg-0">
                    <div class="stat-card">
                        <div class="stat-icon" style="background: #fef3c7; color: #b45309;">
                            <i class="fas fa-broom"></i>
                        </div>
                        <div>
                            <div class="stat-val">{{ kpi.SweepLength }} <small style="font-size: 13px;">m</small></div>
                            <div class="stat-label">累計掃街長度</div>
                            <div class="stat-sub">{{ (kpi.SweepLength / 1000).toFixed(2) }} km</div>
                        </div>
                    </div>
                </div>

                <div class="col-6 col-lg-3 mb-2 mb-lg-0">
                    <div class="stat-card">
                        <div class="stat-icon" style="background: #dcfce7; color: #16a34a;">
                            <i class="fas fa-road"></i>
                        </div>
                        <div>
                            <div class="stat-val text-success">{{ kpi.TotalLengthKm }} <small style="font-size: 13px;">km</small></div>
                            <div class="stat-label">認養洗掃總長度</div>
                            <div class="stat-sub">共 {{ kpi.TotalLength }} 公尺</div>
                        </div>
                    </div>
                </div>

                <div class="col-12 col-lg-3 mb-2 mb-lg-0">
                    <div class="stat-card">
                        <div class="stat-icon" style="background: #f3e8ff; color: #9333ea;">
                            <i class="fas fa-camera"></i>
                        </div>
                        <div>
                            <div class="stat-val text-purple">{{ kpi.TotalPhotoCount }} <small style="font-size: 13px;">張</small></div>
                            <div class="stat-label">現場照片佐證</div>
                            <div class="stat-sub">洗前: {{ kpi.BeforePhotoCount }} 張 / 洗後: {{ kpi.AfterPhotoCount }} 張</div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- 查詢篩選條件卡片 -->
            <div class="card-modern mb-3">
                <div class="card-modern-header">
                    <h2 class="card-modern-title">
                        <i class="fas fa-filter text-primary"></i>
                        <span>日誌篩選與公私場所選取</span>
                    </h2>

                    <!-- 當前查看場所名稱標籤 -->
                    <span v-if="currentFacName" class="badge badge-pill badge-primary px-3 py-2" style="font-size: 13px;">
                        <i class="fas fa-industry mr-1"></i> {{ currentFacName }}
                    </span>
                </div>

                <div class="card-modern-body">
                    <div class="row align-items-center">
                        <!-- 民國年選單 -->
                        <div class="col-12 col-sm-6 col-md-2 mb-3">
                            <label class="font-weight-bold text-muted small mb-1">年度 (民國)</label>
                            <select class="form-control" v-model="filter.year" v-on:change="loadList">
                                <option v-for="y in yearList" :key="y" :value="y">{{ y }} 年</option>
                            </select>
                        </div>

                        <!-- 月份選單 -->
                        <div class="col-12 col-sm-6 col-md-2 mb-3">
                            <label class="font-weight-bold text-muted small mb-1">月份</label>
                            <select class="form-control" v-model="filter.month" v-on:change="loadList">
                                <option v-for="m in 12" :key="m" :value="m">{{ m }} 月</option>
                            </select>
                        </div>

                        <!-- 公私場所選單 (管理者可切換，業者鎖定) -->
                        <div class="col-12 col-md-5 mb-3">
                            <label class="font-weight-bold text-muted small mb-1">
                                認養公私場所
                                <span v-if="!isManager" class="text-danger ml-1">(帳號鎖定)</span>
                            </label>
                            <div v-if="isManager">
                                <select class="form-control" v-model="filter.facId" v-on:change="onFacChange">
                                    <option v-for="fac in facList" :key="fac.FacId" :value="fac.FacId">
                                        {{ fac.FacName }} ({{ fac.FacId }})
                                    </option>
                                </select>
                            </div>
                            <div v-else>
                                <input type="text" class="form-control bg-light" :value="currentFacName + ' (' + filter.facId + ')'" readonly />
                            </div>
                        </div>

                        <!-- 執行方式篩選 -->
                        <div class="col-6 col-md-3 mb-3">
                            <label class="font-weight-bold text-muted small mb-1">執行方式</label>
                            <select class="form-control" v-model="filter.washType" v-on:change="loadList">
                                <option value="">全部執行方式</option>
                                <option value="洗">洗街</option>
                                <option value="掃">掃街</option>
                                <option value="洗+掃">洗+掃街</option>
                            </select>
                        </div>
                    </div>

                    <!-- 1~12 月快速膠囊 Pills 切換列 -->
                    <div class="d-flex align-items-center flex-wrap pt-2 border-top">
                        <span class="small font-weight-bold text-muted mr-2">月份切換：</span>
                        <div class="month-pills-container">
                            <button v-for="m in 12" :key="m" type="button" 
                                    :class="['month-pill-btn', { 'active': filter.month === m }]"
                                    v-on:click="selectMonth(m)">
                                {{ m }}月
                            </button>
                        </div>

                        <!-- 關鍵字快速篩選 -->
                        <div class="ml-auto mt-2 mt-md-0 d-flex gap-2 align-items-center">
                            <div class="input-group input-group-sm" style="max-width: 240px;">
                                <input type="text" class="form-control" placeholder="篩選人員姓名..." v-model="filter.keyword" v-on:keyup.enter="loadList" />
                                <div class="input-group-append">
                                    <button class="btn btn-outline-primary" type="button" v-on:click="loadList">
                                        <i class="fas fa-search"></i>
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- 模式切換與內容展示卡片 -->
            <div class="card-modern">
                <!-- 頁籤模式切換列 -->
                <div class="nav-mode-bar">
                    <div :class="['nav-mode-item', { 'active': activeTab === 'list' }]" v-on:click="activeTab = 'list'">
                        <i class="fas fa-list-alt"></i>
                        <span>詳細作業日誌清單</span>
                        <span class="badge badge-primary ml-1" style="font-size: 11px;">{{ records.length }} 筆</span>
                    </div>

                    <div :class="['nav-mode-item', { 'active': activeTab === 'calendar' }]" v-on:click="activeTab = 'calendar'">
                        <i class="fas fa-calendar-alt"></i>
                        <span>月份作業全覽日曆</span>
                        <span class="badge badge-success ml-1" style="font-size: 11px;">{{ kpi.ActiveDays }} 天已出勤</span>
                    </div>
                </div>

                <!-- 載入中狀態 -->
                <div v-if="loading" class="text-center py-5">
                    <div class="spinner-border text-primary" role="status" style="width: 3rem; height: 3rem;"></div>
                    <p class="mt-3 text-muted font-weight-bold">正在讀取洗掃日誌與照片資料...</p>
                </div>

                <div v-else class="card-modern-body p-0">
                    <!-- 視角一：詳細作業清單 (Desktop Table + Mobile Cards) -->
                    <div v-if="activeTab === 'list'">
                        <!-- 空資料提示 -->
                        <div v-if="records.length === 0" class="text-center py-5 px-3">
                            <i class="fas fa-clipboard-list text-muted mb-3" style="font-size: 3.5rem; opacity: 0.4;"></i>
                            <h4 class="font-weight-bold text-muted">本月份尚無洗掃日誌紀錄</h4>
                            <p class="text-muted small">請選取不同月份，或點選下方按鈕開始填報今日洗掃街作業。</p>
                            <a :href="newRecordUrl" class="btn btn-primary px-4 py-2 font-weight-bold shadow-sm">
                                <i class="fas fa-plus mr-1"></i> 立即填報洗掃日誌
                            </a>
                        </div>

                        <!-- 桌面端表格 (大於等於 768px) -->
                        <div v-else class="d-none d-md-block table-responsive">
                            <table class="table-modern">
                                <thead>
                                    <tr>
                                        <th style="width: 60px;" class="text-center">序號</th>
                                        <th style="width: 140px;">洗掃日期</th>
                                        <th style="width: 130px;">作業時段</th>
                                        <th style="width: 90px;" class="text-center">執行方式</th>
                                        <th style="width: 180px;">洗掃長度</th>
                                        <th style="width: 110px;">作業人員</th>
                                        <th style="width: 170px;">現場佐證照片</th>
                                        <th style="width: 130px;" class="text-center">操作功能</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr v-for="(item, idx) in records" :key="item.PIndex">
                                        <td class="text-center font-weight-bold text-muted">{{ idx + 1 }}</td>
                                        <td>
                                            <div class="font-weight-bold text-navy">{{ item.WashDate }}</div>
                                            <span :class="['small font-weight-bold', item.IsWeekend ? 'text-danger' : 'text-muted']">
                                                {{ item.DayOfWeekStr }}
                                            </span>
                                        </td>
                                        <td>
                                            <span class="badge badge-light border text-secondary px-2 py-1" style="font-size: 13px;">
                                                <i class="far fa-clock mr-1"></i> {{ item.WashTimeRange }}
                                            </span>
                                        </td>
                                        <td class="text-center">
                                            <span :class="['type-badge', getWashTypeClass(item.WashType)]">
                                                <i :class="getWashTypeIcon(item.WashType)"></i>
                                                {{ item.WashType }}
                                            </span>
                                        </td>
                                        <td>
                                            <div class="d-flex flex-column small">
                                                <div>左側: <b class="text-dark">{{ item.Length1 }}</b> m | 右側: <b class="text-dark">{{ item.Length2 }}</b> m</div>
                                                <div class="font-weight-bold text-primary mt-1">合計: {{ item.TotalLength }} 公尺</div>
                                            </div>
                                        </td>
                                        <td>
                                            <div class="d-flex align-items-center gap-1 font-weight-bold text-dark">
                                                <i class="fas fa-user-circle text-muted"></i>
                                                <span>{{ item.PPL || '未填寫' }}</span>
                                            </div>
                                        </td>
                                        <td>
                                            <div class="photo-thumb-box">
                                                <!-- 洗掃前照片 -->
                                                <div v-if="item.BeforePhoto.Exists" class="thumb-img-wrapper" v-on:click="previewPhoto(item.BeforePhoto.Url, '洗掃前現場照片', item)">
                                                    <img :src="item.BeforePhoto.Url" class="thumb-img" alt="洗掃前照片" />
                                                    <div class="thumb-tag">洗前</div>
                                                </div>
                                                <div v-else class="thumb-empty" title="尚未上傳洗掃前照片">
                                                    <i class="fas fa-image mb-1"></i>
                                                    <span>無前照</span>
                                                </div>

                                                <!-- 洗掃後照片 -->
                                                <div v-if="item.AfterPhoto.Exists" class="thumb-img-wrapper" v-on:click="previewPhoto(item.AfterPhoto.Url, '洗掃後現場照片', item)">
                                                    <img :src="item.AfterPhoto.Url" class="thumb-img" alt="洗掃後照片" />
                                                    <div class="thumb-tag">洗後</div>
                                                </div>
                                                <div v-else class="thumb-empty" title="尚未上傳洗掃後照片">
                                                    <i class="fas fa-image mb-1"></i>
                                                    <span>無後照</span>
                                                </div>
                                            </div>
                                        </td>
                                        <td class="text-center">
                                            <div class="d-inline-flex gap-2">
                                                <a :href="item.EditUrl" class="btn-action btn-action-edit" title="編輯此筆日誌紀錄">
                                                    <i class="fas fa-edit"></i>
                                                    <span>編輯</span>
                                                </a>
                                                <button type="button" class="btn-action btn-action-del" v-on:click="confirmDelete(item)" title="刪除此筆日誌紀錄">
                                                    <i class="fas fa-trash-alt"></i>
                                                    <span>刪除</span>
                                                </button>
                                            </div>
                                        </td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>

                        <!-- 手機外勤自適應卡片 (小於 768px) -->
                        <div v-else class="p-3">
                            <div v-for="(item, idx) in records" :key="item.PIndex" class="mobile-record-card">
                                <div class="mobile-record-header">
                                    <div class="d-flex align-items-center gap-2">
                                        <span class="badge badge-secondary">#{{ idx + 1 }}</span>
                                        <span class="font-weight-bold text-navy" style="font-size: 1.05rem;">{{ item.WashDate }}</span>
                                        <span :class="['small font-weight-bold', item.IsWeekend ? 'text-danger' : 'text-muted']">
                                            ({{ item.DayOfWeekStr }})
                                        </span>
                                    </div>
                                    <span :class="['type-badge', getWashTypeClass(item.WashType)]">
                                        <i :class="getWashTypeIcon(item.WashType)"></i>
                                        {{ item.WashType }}
                                    </span>
                                </div>

                                <div class="row small mb-2">
                                    <div class="col-6 mb-1">
                                        <span class="text-muted">時段:</span>
                                        <span class="font-weight-bold text-dark ml-1">{{ item.WashTimeRange }}</span>
                                    </div>
                                    <div class="col-6 mb-1">
                                        <span class="text-muted">人員:</span>
                                        <span class="font-weight-bold text-dark ml-1">{{ item.PPL || '未填寫' }}</span>
                                    </div>
                                    <div class="col-12 mt-1">
                                        <span class="text-muted">里程:</span>
                                        <span class="font-weight-bold text-primary ml-1">合計 {{ item.TotalLength }} m (左: {{ item.Length1 }}m / 右: {{ item.Length2 }}m)</span>
                                    </div>
                                </div>

                                <!-- 照片預覽列 -->
                                <div class="d-flex align-items-center gap-2 pt-2 border-top">
                                    <span class="small font-weight-bold text-muted mr-1">照片佐證:</span>
                                    <div v-if="item.BeforePhoto.Exists" class="thumb-img-wrapper" v-on:click="previewPhoto(item.BeforePhoto.Url, '洗掃前現場照片', item)">
                                        <img :src="item.BeforePhoto.Url" class="thumb-img" alt="洗掃前照片" />
                                        <div class="thumb-tag">洗前</div>
                                    </div>
                                    <div v-else class="thumb-empty">無前照</div>

                                    <div v-if="item.AfterPhoto.Exists" class="thumb-img-wrapper" v-on:click="previewPhoto(item.AfterPhoto.Url, '洗掃後現場照片', item)">
                                        <img :src="item.AfterPhoto.Url" class="thumb-img" alt="洗掃後照片" />
                                        <div class="thumb-tag">洗後</div>
                                    </div>
                                    <div v-else class="thumb-empty">無後照</div>
                                </div>

                                <div class="mobile-record-actions">
                                    <a :href="item.EditUrl" class="btn-action btn-action-edit">
                                        <i class="fas fa-edit mr-1"></i> 編輯日誌
                                    </a>
                                    <button type="button" class="btn-action btn-action-del" v-on:click="confirmDelete(item)">
                                        <i class="fas fa-trash-alt mr-1"></i> 刪除紀錄
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- 視角二：月份作業全覽日曆 -->
                    <div v-if="activeTab === 'calendar'" class="p-3">
                        <div class="calendar-grid">
                            <div v-for="d in dailySummaries" :key="d.DayNum" 
                                 :class="['cal-day-card', { 'has-data': d.HasRecords, 'is-today': d.IsToday }]">
                                <div class="cal-header">
                                    <span class="cal-date-num">{{ d.DayNum }} <small style="font-size: 11px; font-weight: normal;">日</small></span>
                                    <span :class="['cal-dow', { 'text-weekend': d.IsWeekend }]">{{ d.DayOfWeekStr }}</span>
                                </div>

                                <div class="cal-body">
                                    <div v-if="d.HasRecords">
                                        <div class="badge badge-success mb-1" style="font-size: 11px;">
                                            <i class="fas fa-check-circle mr-1"></i> 已洗掃 {{ d.RecordCount }} 次
                                        </div>
                                        <div class="font-weight-bold text-dark small">合計: {{ d.TotalLength }} m</div>

                                        <!-- 當日每筆日誌快速連結 -->
                                        <div class="mt-2 d-flex flex-column gap-1">
                                            <a v-for="r in d.Records" :key="r.PIndex" :href="r.EditUrl" class="small text-primary text-truncate" title="點擊編輯此筆紀錄">
                                                <i class="fas fa-caret-right mr-1"></i>{{ r.WashTime_Start }} [{{ r.WashType }}] {{ r.TotalLength }}m
                                            </a>
                                        </div>
                                    </div>
                                    <div v-else class="text-muted small d-flex flex-column justify-content-between h-100">
                                        <span>未執行作業</span>
                                        <a :href="'DataInput.aspx?id=' + encodeURIComponent(filter.facId) + '&id1=' + encodeURIComponent(token) + '&date=' + d.DateStr + '&mode=new'" 
                                           class="btn btn-sm btn-outline-secondary mt-2 py-0" style="font-size: 11px;">
                                            + 補登
                                        </a>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </main>

        <!-- 照片預覽燈箱 Modal -->
        <div v-if="photoModal.show" class="modal-mask" v-on:click.self="photoModal.show = false">
            <div class="modal-box">
                <div class="card-modern-header">
                    <h3 class="card-modern-title">
                        <i class="fas fa-image text-primary"></i>
                        <span>{{ photoModal.title }}</span>
                    </h3>
                    <button type="button" class="close" v-on:click="photoModal.show = false">
                        <span>&times;</span>
                    </button>
                </div>
                <div class="p-3 text-center bg-dark">
                    <img :src="photoModal.url" class="img-fluid rounded" style="max-height: 68vh; object-fit: contain;" alt="照片大圖預覽" />
                </div>
                <div class="card-modern-header bg-light">
                    <div class="small text-muted" v-if="photoModal.item">
                        <div>作業日期：<b>{{ photoModal.item.WashDate }}</b> ({{ photoModal.item.WashTimeRange }})</div>
                        <div>執行人員：<b>{{ photoModal.item.PPL || '未具名' }}</b> | 合計長度：<b>{{ photoModal.item.TotalLength }} 公尺</b></div>
                    </div>
                    <div class="d-flex gap-2">
                        <a :href="photoModal.url" target="_blank" class="btn btn-sm btn-outline-primary font-weight-bold">
                            <i class="fas fa-external-link-alt mr-1"></i> 開啟原圖
                        </a>
                        <button type="button" class="btn btn-sm btn-secondary font-weight-bold" v-on:click="photoModal.show = false">
                            關閉
                        </button>
                    </div>
                </div>
            </div>
        </div>

        <!-- 刪除確認 Modal -->
        <div v-if="deleteModal.show" class="modal-mask" v-on:click.self="deleteModal.show = false">
            <div class="modal-box" style="max-width: 460px;">
                <div class="card-modern-header bg-danger text-white">
                    <h3 class="card-modern-title text-white">
                        <i class="fas fa-exclamation-triangle"></i>
                        <span>確認刪除日誌紀錄</span>
                    </h3>
                    <button type="button" class="close text-white" v-on:click="deleteModal.show = false">
                        <span>&times;</span>
                    </button>
                </div>
                <div class="p-4 text-center">
                    <i class="fas fa-trash-alt text-danger mb-3" style="font-size: 3rem;"></i>
                    <h5 class="font-weight-bold text-dark">您確定要刪除這筆洗掃日誌嗎？</h5>
                    <p class="text-muted small mt-2" v-if="deleteModal.item">
                        日期：<b>{{ deleteModal.item.WashDate }}</b><br />
                        時段：<b>{{ deleteModal.item.WashTimeRange }}</b><br />
                        執行長度：<b>{{ deleteModal.item.TotalLength }} 公尺</b><br />
                        <span class="text-danger font-weight-bold">注意：刪除後將連同上傳之現場相片檔案一併永久抹除，無法還原！</span>
                    </p>
                </div>
                <div class="card-modern-header bg-light justify-content-end gap-2">
                    <button type="button" class="btn btn-outline-secondary px-3 font-weight-bold" v-on:click="deleteModal.show = false" :disabled="deleteModal.loading">
                        取消
                    </button>
                    <button type="button" class="btn btn-danger px-4 font-weight-bold" v-on:click="executeDelete" :disabled="deleteModal.loading">
                        <span v-if="deleteModal.loading" class="spinner-border spinner-border-sm mr-1"></span>
                        確定刪除
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- 本地化腳本依賴 (Vue 3, Axios) -->
    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>

    <script>
        const { createApp, ref, reactive, onMounted, computed } = Vue;

        createApp({
            setup() {
                // 狀態資料
                const loading = ref(false);
                const activeTab = ref('list'); // 'list' | 'calendar'
                const isManager = ref(false);
                const userFacId = ref('');
                const userName = ref('');
                const currentFacName = ref('');
                const token = ref('');
                const yearList = ref([]);
                const facList = ref([]);

                const filter = reactive({
                    facId: '',
                    year: new Date().getFullYear() - 1911,
                    month: new Date().getMonth() + 1,
                    washType: '',
                    keyword: ''
                });

                const records = ref([]);
                const dailySummaries = ref([]);
                const kpi = reactive({
                    TotalCount: 0,
                    ActiveDays: 0,
                    WashCount: 0,
                    SweepCount: 0,
                    BothCount: 0,
                    WashLength: 0,
                    SweepLength: 0,
                    TotalLength: 0,
                    TotalLengthKm: 0.0,
                    BeforePhotoCount: 0,
                    AfterPhotoCount: 0,
                    TotalPhotoCount: 0
                });

                // 照片預覽燈箱
                const photoModal = reactive({
                    show: false,
                    url: '',
                    title: '',
                    item: null
                });

                // 刪除確認 Modal
                const deleteModal = reactive({
                    show: false,
                    item: null,
                    loading: false
                });

                // Toast 提示
                const toast = reactive({
                    show: false,
                    message: '',
                    type: 'info',
                    icon: 'fas fa-info-circle',
                    timer: null
                });

                const showToast = (message, type = 'info') => {
                    if (toast.timer) clearTimeout(toast.timer);
                    toast.message = message;
                    toast.type = type;
                    toast.icon = type === 'success' ? 'fas fa-check-circle' :
                                 type === 'danger' ? 'fas fa-exclamation-circle' : 'fas fa-info-circle';
                    toast.show = true;
                    toast.timer = setTimeout(() => {
                        toast.show = false;
                    }, 3500);
                };

                // 新增紀錄的 URL
                const newRecordUrl = computed(() => {
                    const fid = encodeURIComponent(filter.facId || '');
                    const tk = encodeURIComponent(token.value || '');
                    return 'DataInput.aspx?id=' + fid + '&id1=' + tk + '&mode=new';
                });

                // 取得執行方式 Badge 樣式
                const getWashTypeClass = (type) => {
                    if (!type) return 'type-badge-wash';
                    if (type.indexOf('洗') >= 0 && type.indexOf('掃') >= 0) return 'type-badge-both';
                    if (type.indexOf('掃') >= 0) return 'type-badge-sweep';
                    return 'type-badge-wash';
                };

                const getWashTypeIcon = (type) => {
                    if (!type) return 'fas fa-shower';
                    if (type.indexOf('洗') >= 0 && type.indexOf('掃') >= 0) return 'fas fa-sync-alt';
                    if (type.indexOf('掃') >= 0) return 'fas fa-broom';
                    return 'fas fa-shower';
                };

                // 預覽照片
                const previewPhoto = (url, title, item) => {
                    photoModal.url = url;
                    photoModal.title = title;
                    photoModal.item = item;
                    photoModal.show = true;
                };

                // 點選月份膠囊
                const selectMonth = (m) => {
                    filter.month = m;
                    loadList();
                };

                // 工廠變更
                const onFacChange = () => {
                    const found = facList.value.find(f => f.FacId === filter.facId);
                    if (found) {
                        currentFacName.value = found.FacName;
                    }
                    loadList();
                };

                // 初始化載入
                const initData = async () => {
                    loading.value = true;
                    try {
                        const urlParams = new URLSearchParams(window.location.search);
                        const reqId = urlParams.get('id') || '';

                        const res = await axios.get('WashList.aspx?action=getinitdata' + (reqId ? '&id=' + encodeURIComponent(reqId) : ''));
                        if (res.data && res.data.Success) {
                            isManager.value = res.data.IsManager;
                            userFacId.value = res.data.UserFacId || '';
                            userName.value = res.data.UserName || '';
                            yearList.value = res.data.YearList || [];
                            facList.value = res.data.FacList || [];
                            token.value = res.data.Token || '';

                            filter.facId = res.data.CurrentFacId || '';
                            currentFacName.value = res.data.CurrentFacName || '';
                            filter.year = res.data.CurrentYear || filter.year;
                            filter.month = res.data.CurrentMonth || filter.month;

                            await loadList();
                        } else {
                            showToast(res.data ? res.data.Message : '初始化失敗', 'danger');
                        }
                    } catch (err) {
                        console.error('初始化錯誤', err);
                        showToast('系統載入失敗：' + (err.message || '網路通訊異常'), 'danger');
                    } finally {
                        loading.value = false;
                    }
                };

                // 載入日誌清單
                const loadList = async () => {
                    if (!filter.facId) return;
                    loading.value = true;
                    try {
                        const params = new URLSearchParams();
                        params.append('action', 'getlist');
                        params.append('facId', filter.facId);
                        params.append('year', filter.year);
                        params.append('month', filter.month);
                        if (filter.washType) params.append('washType', filter.washType);
                        if (filter.keyword) params.append('keyword', filter.keyword);

                        const res = await axios.get('WashList.aspx?' + params.toString());
                        if (res.data && res.data.Success) {
                            records.value = res.data.Records || [];
                            dailySummaries.value = res.data.DailySummaries || [];
                            token.value = res.data.Token || token.value;

                            if (res.data.FacName) {
                                currentFacName.value = res.data.FacName;
                            }

                            // 拷貝 KPI
                            if (res.data.KPI) {
                                Object.assign(kpi, res.data.KPI);
                            }
                        } else {
                            showToast(res.data ? res.data.Message : '載入清單失敗', 'danger');
                        }
                    } catch (err) {
                        console.error('載入清單錯誤', err);
                        showToast('清單讀取失敗：' + (err.message || '網路通訊異常'), 'danger');
                    } finally {
                        loading.value = false;
                    }
                };

                // 匯出 Excel
                const exportExcel = () => {
                    if (!filter.facId) {
                        showToast('請先選取欲匯出之公私場所', 'danger');
                        return;
                    }
                    const url = 'WashList.aspx?action=exportexcel&facId=' + encodeURIComponent(filter.facId) +
                                '&year=' + filter.year + '&month=' + filter.month;
                    window.open(url, '_blank');
                };

                // 確認刪除對話框
                const confirmDelete = (item) => {
                    deleteModal.item = item;
                    deleteModal.show = true;
                };

                // 執行刪除
                const executeDelete = async () => {
                    if (!deleteModal.item) return;
                    deleteModal.loading = true;
                    try {
                        const payload = {
                            facId: deleteModal.item.FacId,
                            pIndex: deleteModal.item.PIndex
                        };
                        const res = await axios.post('WashList.aspx?action=deletedata', payload);
                        if (res.data && res.data.Success) {
                            deleteModal.show = false;
                            showToast(res.data.Message || '紀錄已成功刪除！', 'success');
                            await loadList();
                        } else {
                            showToast(res.data ? res.data.Message : '刪除失敗', 'danger');
                        }
                    } catch (err) {
                        console.error('刪除錯誤', err);
                        showToast('刪除失敗：' + (err.message || '網路通訊異常'), 'danger');
                    } finally {
                        deleteModal.loading = false;
                    }
                };

                onMounted(() => {
                    initData();
                });

                return {
                    loading,
                    activeTab,
                    isManager,
                    userFacId,
                    userName,
                    currentFacName,
                    token,
                    yearList,
                    facList,
                    filter,
                    records,
                    dailySummaries,
                    kpi,
                    photoModal,
                    deleteModal,
                    toast,
                    newRecordUrl,
                    getWashTypeClass,
                    getWashTypeIcon,
                    previewPhoto,
                    selectMonth,
                    onFacChange,
                    loadList,
                    exportExcel,
                    confirmDelete,
                    executeDelete
                };
            }
        }).mount('#washApp');
    </script>
</body>
</html>
