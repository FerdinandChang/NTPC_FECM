<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="ReportUpload.aspx.cs" Inherits="NTPC_FEC.Wash.ReportUpload" %>
<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定溢散源管理平台 - 洗掃作業月報上傳回傳</title>

    <!-- 專屬 Favicon -->
    <link rel="shortcut icon" href="../favicon.ico" type="image/x-icon" />

    <!-- 本地化樣式依賴 -->
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

        /* 頂部導覽列 */
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
            font-size: 1.12rem;
            font-weight: 700;
            display: flex;
            align-items: center;
            gap: 10px;
            letter-spacing: 0.5px;
            color: #ffffff;
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
            transition: all 0.2s ease;
            text-decoration: none;
        }

        .nav-btn:hover {
            background-color: rgba(255, 255, 255, 0.32);
            color: #ffffff;
            text-decoration: none;
        }

        .nav-btn-light {
            background: #ffffff;
            color: #0284c7;
            font-weight: 700;
            border: none;
            box-shadow: 0 2px 6px rgba(0, 0, 0, 0.12);
        }

        .nav-btn-light:hover {
            background: #f0f9ff;
            color: #0369a1;
        }

        /* 主作業容器 (最適化全寬限制與邊界吸收) */
        .container-fluid-custom {
            max-width: 1680px;
            margin: 0 auto;
            padding: 20px 24px;
            width: 100%;
            box-sizing: border-box;
        }

        @media (max-width: 768px) {
            .container-fluid-custom {
                padding: 14px 12px;
            }
        }

        /* 現代卡片 */
        .card-modern {
            background: var(--surface);
            border-radius: 12px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05), 0 4px 12px rgba(15, 23, 42, 0.04);
            margin-bottom: 20px;
            border: 1px solid var(--border-color);
            overflow: hidden;
            transition: transform 0.2s ease, box-shadow 0.2s ease;
        }

        .card-modern-header {
            padding: 14px 18px;
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
            gap: 8px;
        }

        .card-modern-body {
            padding: 18px;
        }

        /* 桌面端左欄固頂 */
        @media screen and (min-width: 1200px) {
            .sticky-left-col {
                position: sticky;
                top: 76px;
                max-height: calc(100vh - 92px);
                overflow-y: auto;
                padding-right: 4px;
            }
        }

        /* 場所資訊晶片 */
        .fac-badge-panel {
            background: #f0fdf4;
            border: 1px solid #bbf7d0;
            border-radius: 10px;
            padding: 12px 14px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 14px;
            gap: 8px;
        }

        .fac-badge-title {
            font-size: 0.92rem;
            font-weight: 700;
            color: #166534;
            display: flex;
            align-items: center;
            gap: 6px;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }

        .fac-badge-id {
            background: #15803d;
            color: #ffffff;
            font-size: 0.8rem;
            font-weight: 700;
            padding: 3px 8px;
            border-radius: 6px;
            letter-spacing: 0.5px;
            flex-shrink: 0;
        }

        /* 12 格月份矩陣按鈕 */
        .month-matrix-grid {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 8px;
            margin-bottom: 16px;
        }

        .month-chip {
            background: #f8fafc;
            border: 1.5px solid #e2e8f0;
            border-radius: 8px;
            padding: 8px 4px;
            text-align: center;
            cursor: pointer;
            transition: all 0.2s ease;
            position: relative;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            min-height: 52px;
        }

        .month-chip:hover {
            border-color: var(--brand-primary);
            background: #f0f9ff;
            transform: translateY(-2px);
        }

        .month-chip.active {
            border-color: var(--brand-blue);
            background: #e0f2fe;
            box-shadow: 0 0 0 3px rgba(2, 132, 199, 0.2);
        }

        .month-chip-num {
            font-size: 0.95rem;
            font-weight: 700;
            color: var(--brand-navy);
            line-height: 1.2;
        }

        .month-chip.active .month-chip-num {
            color: #0369a1;
        }

        .month-chip-status {
            font-size: 0.72rem;
            font-weight: 600;
            margin-top: 2px;
        }

        .status-badge-done {
            color: #047857;
            background: #d1fae5;
            padding: 1px 5px;
            border-radius: 4px;
        }

        .status-badge-empty {
            color: #94a3b8;
        }

        /* 拖曳上傳 Dropzone */
        .upload-dropzone {
            border: 2px dashed #cbd5e1;
            border-radius: 12px;
            background: #f8fafc;
            padding: 24px 14px;
            text-align: center;
            cursor: pointer;
            transition: all 0.25s ease;
            position: relative;
            margin-bottom: 14px;
        }

        .upload-dropzone:hover, .upload-dropzone.drag-active {
            border-color: var(--brand-blue);
            background: #f0f9ff;
        }

        .upload-icon-circle {
            width: 52px;
            height: 52px;
            border-radius: 50%;
            background: #e0f2fe;
            color: var(--brand-blue);
            display: inline-flex;
            align-items: center;
            justify-content: center;
            font-size: 24px;
            margin-bottom: 10px;
            transition: transform 0.2s ease;
        }

        .upload-dropzone:hover .upload-icon-circle {
            transform: scale(1.08);
        }

        .upload-dropzone-title {
            font-size: 0.98rem;
            font-weight: 700;
            color: var(--brand-navy);
            margin-bottom: 4px;
        }

        .upload-dropzone-subtitle {
            font-size: 0.8rem;
            color: var(--text-muted);
            margin-bottom: 10px;
        }

        /* 檔案預覽卡片 */
        .file-preview-card {
            background: #ffffff;
            border: 1px solid var(--border-color);
            border-radius: 10px;
            padding: 12px 14px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 14px;
            box-shadow: 0 2px 6px rgba(0, 0, 0, 0.04);
            gap: 10px;
        }

        .file-preview-info {
            display: flex;
            align-items: center;
            gap: 10px;
            overflow: hidden;
            flex-grow: 1;
        }

        .file-type-icon {
            width: 40px;
            height: 40px;
            border-radius: 8px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 18px;
            flex-shrink: 0;
        }

        .icon-pdf { background: #fee2e2; color: #dc2626; }
        .icon-doc { background: #e0f2fe; color: #0284c7; }
        .icon-xls { background: #ecfdf5; color: #10b981; }
        .icon-img { background: #f3e8ff; color: #9333ea; }
        .icon-zip { background: #fef3c7; color: #d97706; }
        .icon-def { background: #f1f5f9; color: #475569; }

        .file-preview-name {
            font-weight: 700;
            font-size: 0.92rem;
            color: var(--brand-navy);
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
            max-width: 200px;
        }

        .file-preview-size {
            font-size: 0.78rem;
            color: var(--text-muted);
        }

        /* 覆蓋警告橫幅 */
        .overwrite-banner {
            background-color: #fffbeb;
            border: 1px solid #fde68a;
            border-left: 5px solid #f59e0b;
            border-radius: 8px;
            padding: 10px 12px;
            margin-bottom: 14px;
            color: #92400e;
            font-size: 0.85rem;
        }

        /* 右側緊湊統計卡片 (Grid 最適化排版，絕不跑版) */
        .stat-card-compact {
            background: #ffffff;
            border: 1px solid var(--border-color);
            border-radius: 10px;
            padding: 12px 14px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
            display: flex;
            align-items: center;
            gap: 12px;
            height: 100%;
            transition: transform 0.2s, box-shadow 0.2s;
        }

        .stat-card-compact:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 10px rgba(15, 23, 42, 0.08);
        }

        .stat-compact-icon {
            width: 42px;
            height: 42px;
            border-radius: 8px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 18px;
            flex-shrink: 0;
        }

        .bg-light-primary { background: #e0f2fe; }
        .bg-light-success { background: #dcfce7; }
        .bg-light-info { background: #e0e7ff; }

        .stat-compact-title {
            font-size: 0.78rem;
            font-weight: 600;
            color: var(--text-muted);
            margin-bottom: 2px;
        }

        .stat-compact-val {
            font-size: 1.25rem;
            font-weight: 800;
            color: var(--brand-navy);
            line-height: 1.1;
        }

        /* 歷史記錄現代表格 (最適化欄寬與彈性縮放) */
        .history-table {
            width: 100%;
            border-collapse: separate;
            border-spacing: 0;
            table-layout: auto;
        }

        .history-table th {
            background: #f8fafc;
            color: #475569;
            font-weight: 700;
            font-size: 0.85rem;
            padding: 12px 14px;
            border-bottom: 2px solid var(--border-color);
            white-space: nowrap;
            vertical-align: middle;
        }

        .history-table td {
            padding: 12px 14px;
            border-bottom: 1px solid var(--border-color);
            font-size: 0.9rem;
            vertical-align: middle;
            color: var(--text-main);
            transition: background-color 0.15s ease;
        }

        .history-table tbody tr:hover td {
            background-color: #f1f5f9;
        }

        .year-month-tag {
            background: #0f172a;
            color: #ffffff;
            font-weight: 700;
            font-size: 0.82rem;
            padding: 3px 8px;
            border-radius: 6px;
            white-space: nowrap;
            display: inline-block;
        }

        /* 檔案標籤膠囊 (支援超長檔名截斷與 Tooltip) */
        .file-badge-link {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 5px 10px;
            border-radius: 6px;
            background: #f1f5f9;
            color: #0369a1;
            font-weight: 600;
            text-decoration: none;
            transition: all 0.2s ease;
            max-width: 100%;
        }

        .file-badge-link:hover {
            background: #e0f2fe;
            color: #0284c7;
            text-decoration: none;
        }

        .file-item-icon {
            font-size: 16px;
            flex-shrink: 0;
        }

        .file-item-name {
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
            font-size: 0.88rem;
        }

        /* 上傳人員晶片 (杜絕超長公司名換行撐爆) */
        .user-chip {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 6px;
            padding: 3px 8px;
            display: inline-flex;
            align-items: center;
            gap: 5px;
            font-size: 0.82rem;
            font-weight: 600;
            color: #334155;
            max-width: 150px;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }

        /* 操作按鈕群組 */
        .btn-action-group .btn {
            padding: 4px 8px;
            border-radius: 6px;
        }

        /* 手機切換頁籤 */
        .mobile-tabs {
            display: none;
            margin-bottom: 16px;
        }

        @media screen and (max-width: 991px) {
            .mobile-tabs {
                display: flex;
                background: #e2e8f0;
                padding: 4px;
                border-radius: 10px;
                gap: 4px;
            }

            .mobile-tab-btn {
                flex: 1;
                border: none;
                background: transparent;
                padding: 10px;
                font-weight: 700;
                font-size: 0.95rem;
                color: #475569;
                border-radius: 8px;
                cursor: pointer;
                text-align: center;
            }

            .mobile-tab-btn.active {
                background: #ffffff;
                color: var(--brand-blue);
                box-shadow: 0 2px 6px rgba(0, 0, 0, 0.08);
            }

            .month-matrix-grid {
                grid-template-columns: repeat(3, 1fr);
            }
        }

        /* 手機卡片視圖 (外勤觸控友善) */
        .history-card-item {
            background: #ffffff;
            border: 1px solid var(--border-color);
            border-radius: 10px;
            padding: 12px 14px;
            margin-bottom: 10px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
        }

        .history-card-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 8px;
        }

        .history-card-row {
            display: flex;
            font-size: 0.85rem;
            margin-bottom: 5px;
        }

        .history-card-label {
            width: 75px;
            color: var(--text-muted);
            font-weight: 600;
            flex-shrink: 0;
        }

        .history-card-val {
            color: var(--text-main);
            font-weight: 500;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }

        .history-card-actions {
            margin-top: 10px;
            padding-top: 8px;
            border-top: 1px dashed var(--border-color);
            display: flex;
            gap: 8px;
        }

        .history-card-actions .btn {
            flex: 1;
            min-height: 40px;
            font-weight: 600;
            display: flex;
            align-items: center;
            justify-content: center;
            border-radius: 8px;
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div id="app" v-cloak>
            <!-- 頂部品牌導覽列 -->
            <header class="top-navbar">
                <div class="navbar-brand-title">
                    <a href="../MainPage.aspx" class="nav-btn mr-1" title="返回主選單">
                        <i class="fas fa-chevron-left"></i>
                        <span class="d-none d-sm-inline">返回</span>
                    </a>
                    <i class="fas fa-truck-moving text-white"></i>
                    <span>洗掃報表回傳</span>
                    <span v-if="currentFacId" class="badge badge-light text-dark font-weight-bold ml-2 d-none d-md-inline" style="font-size: 0.85rem;">
                        {{ currentFacId }}
                    </span>
                </div>

                <div class="d-flex align-items-center gap-2">
                    <a href="ReportUpload_List.aspx" class="nav-btn nav-btn-light" title="前往洗掃紀錄清單">
                        <i class="fas fa-list-ul mr-1"></i>
                        <span class="d-none d-sm-inline">洗掃紀錄清單</span>
                    </a>
                    <button type="button" class="nav-btn ml-2" v-on:click="refreshAll" title="重新整理資料">
                        <i class="fas fa-sync-alt" :class="{ 'fa-spin': loading }"></i>
                    </button>
                    <div class="d-none d-lg-flex align-items-center text-white ml-2" style="font-size: 0.88rem; opacity: 0.95;">
                        <i class="fas fa-user-circle mr-1"></i>
                        <span>{{ userName }}</span>
                    </div>
                </div>
            </header>

            <!-- 主作業區 (標準 container-fluid-custom) -->
            <div class="container-fluid-custom">
                <!-- 手機版頁籤切換 (小於 992px) -->
                <div class="mobile-tabs d-lg-none">
                    <button type="button" class="mobile-tab-btn" :class="{ 'active': mobileActiveTab === 'upload' }" v-on:click="mobileActiveTab = 'upload'">
                        <i class="fas fa-cloud-upload-alt mr-1"></i> 報表回傳作業
                    </button>
                    <button type="button" class="mobile-tab-btn" :class="{ 'active': mobileActiveTab === 'history' }" v-on:click="mobileActiveTab = 'history'">
                        <i class="fas fa-history mr-1"></i> 歷程紀錄 ({{ historyRecords.length }})
                    </button>
                </div>

                <!-- 雙欄黃金自適應佈局 (大螢幕 xl: 4:8, 中螢幕 lg: 5:7) -->
                <div class="row">
                    <!-- 左欄：報表上傳作業區 -->
                    <div class="col-12 col-lg-5 col-xl-4 mb-3 mb-lg-0" :class="{ 'd-none d-lg-block': mobileActiveTab !== 'upload' }">
                        <div class="sticky-left-col">
                            <!-- 場所識別與設定卡片 -->
                            <div class="card-modern">
                                <div class="card-modern-header">
                                    <h3 class="card-modern-title">
                                        <i class="fas fa-building text-primary"></i>
                                        <span>回報對象與年度</span>
                                    </h3>
                                    <span v-if="isManager" class="badge badge-primary px-2 py-1">管理員代傳模式</span>
                                    <span v-else class="badge badge-success px-2 py-1">場所自主回傳</span>
                                </div>
                                <div class="card-modern-body">
                                    <!-- 工廠下拉選單 (管理員) 或純文字唯讀 (廠家) -->
                                    <div class="form-group">
                                        <label class="font-weight-bold" style="font-size: 0.9rem;">
                                            公私場所名稱 / 管制代碼：
                                        </label>
                                        <div v-if="isManager">
                                            <select class="form-control font-weight-bold" v-model="currentFacId" v-on:change="onFacChange">
                                                <option v-for="fac in facList" :key="fac.FacId" :value="fac.FacId">
                                                    [{{ fac.FacId }}] {{ fac.FacName }}
                                                </option>
                                            </select>
                                        </div>
                                        <div v-else class="fac-badge-panel">
                                            <div class="fac-badge-title">
                                                <i class="fas fa-check-circle text-success"></i>
                                                <span :title="currentFacName || currentFacId">{{ currentFacName || currentFacId }}</span>
                                            </div>
                                            <span class="fac-badge-id">{{ currentFacId }}</span>
                                        </div>
                                    </div>

                                    <!-- 回報年度選擇 -->
                                    <div class="form-group">
                                        <label class="font-weight-bold" style="font-size: 0.9rem;">
                                            回報年度：
                                        </label>
                                        <select class="form-control font-weight-bold" v-model="selectedYear" v-on:change="onYearChange">
                                            <option v-for="y in yearList" :key="y.Year" :value="y.Year">
                                                {{ y.Text }}
                                            </option>
                                        </select>
                                    </div>

                                    <!-- 12 格月份矩陣按鈕選取器 -->
                                    <div class="form-group mb-0">
                                        <label class="font-weight-bold d-flex justify-content-between align-items-center" style="font-size: 0.9rem;">
                                            <span>選取回報月份：</span>
                                            <small class="text-muted">點選快速切換與即時查驗</small>
                                        </label>
                                        <div class="month-matrix-grid">
                                            <div v-for="m in 12" :key="m" class="month-chip"
                                                 :class="{ 'active': selectedMonth === m }"
                                                 v-on:click="selectMonth(m)">
                                                 <span class="month-chip-num">{{ m < 10 ? '0' + m : m }} 月</span>
                                                 <span class="month-chip-status" v-if="isMonthUploaded(m)">
                                                     <span class="status-badge-done"><i class="fas fa-check"></i> 已繳</span>
                                                 </span>
                                                 <span class="month-chip-status status-badge-empty" v-else>
                                                     未繳
                                                 </span>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- 檔案上傳與送出卡片 -->
                            <div class="card-modern">
                                <div class="card-modern-header">
                                    <h3 class="card-modern-title">
                                        <i class="fas fa-file-upload text-info"></i>
                                        <span>【{{ selectedYear }} 年 {{ selectedMonth }} 月】檔案上傳</span>
                                    </h3>
                                    <span v-if="currentMonthRecord && currentMonthRecord.Exists" class="badge badge-warning text-dark font-weight-bold">
                                        已存在舊檔
                                    </span>
                                </div>
                                <div class="card-modern-body">
                                    <!-- 舊檔案覆蓋警告橫幅 -->
                                    <div v-if="currentMonthRecord && currentMonthRecord.Exists" class="overwrite-banner">
                                        <div class="font-weight-bold mb-1">
                                            <i class="fas fa-exclamation-triangle mr-1"></i> 注意：本月份已回傳過報表！
                                        </div>
                                        <div>
                                            前次上傳時間：<strong>{{ currentMonthRecord.Record.UploadDate }}</strong><br />
                                            回報人員：{{ currentMonthRecord.Record.UploadUserName }} ({{ currentMonthRecord.Record.FileName }})
                                        </div>
                                        <div class="mt-2">
                                            <button type="button" class="btn btn-sm btn-outline-warning text-dark bg-white font-weight-bold" v-on:click="downloadCurrentMonthFile">
                                                <i class="fas fa-download mr-1"></i> 下載舊有報表檢視
                                            </button>
                                        </div>
                                    </div>

                                    <!-- 拖曳與點擊上傳區 (Dropzone) -->
                                    <input type="file" ref="fileInput" class="d-none" 
                                           accept=".pdf,.doc,.docx,.xls,.xlsx,.jpg,.jpeg,.png,.zip,.rar,.7z,.csv" 
                                           v-on:change="onFileSelected" />

                                    <div class="upload-dropzone" 
                                         :class="{ 'drag-active': isDragging }"
                                         v-on:click="triggerFileInput"
                                         v-on:dragover.prevent="onDragOver"
                                         v-on:dragleave.prevent="onDragLeave"
                                         v-on:drop.prevent="onFileDrop">
                                        <div class="upload-icon-circle">
                                            <i class="fas fa-cloud-upload-alt"></i>
                                        </div>
                                        <div class="upload-dropzone-title">
                                            點擊此處選取檔案，或直接將檔案拖曳至此
                                        </div>
                                        <div class="upload-dropzone-subtitle">
                                            支援格式：PDF、Word、Excel、圖片、ZIP (單檔上限 25MB)
                                        </div>
                                        <button type="button" class="btn btn-sm btn-primary px-3 font-weight-bold">
                                            <i class="fas fa-folder-open mr-1"></i> 瀏覽電腦檔案
                                        </button>
                                    </div>

                                    <!-- 已選檔案預覽卡片 -->
                                    <div v-if="selectedFile" class="file-preview-card">
                                        <div class="file-preview-info">
                                            <div class="file-type-icon" :class="getFileIconClass(selectedFile.name)">
                                                <i :class="getFileFaIcon(selectedFile.name)"></i>
                                            </div>
                                            <div>
                                                <div class="file-preview-name" :title="selectedFile.name">{{ selectedFile.name }}</div>
                                                <div class="file-preview-size">{{ formatSize(selectedFile.size) }}</div>
                                            </div>
                                        </div>
                                        <div>
                                            <button type="button" class="btn btn-sm btn-outline-danger" v-on:click.stop="clearSelectedFile" title="移除重新選取">
                                                <i class="fas fa-times"></i>
                                            </button>
                                        </div>
                                    </div>

                                    <!-- 上傳進度條 -->
                                    <div v-if="uploadProgress > 0 && uploadProgress < 100" class="progress mb-3" style="height: 10px; border-radius: 6px;">
                                        <div class="progress-bar progress-bar-striped progress-bar-animated bg-success" :style="{ width: uploadProgress + '%' }"></div>
                                    </div>

                                    <!-- 確定送出按鈕 -->
                                    <button type="button" class="btn btn-primary btn-block py-2 font-weight-bold shadow-sm"
                                            :disabled="!selectedFile || uploading"
                                            v-on:click="submitUpload">
                                        <i v-if="uploading" class="fas fa-spinner fa-spin mr-1"></i>
                                        <i v-else class="fas fa-paper-plane mr-1"></i>
                                        <span>{{ uploading ? '報表檔案上傳中，請稍候...' : (currentMonthRecord && currentMonthRecord.Exists ? '確認覆蓋並更新報表' : '確認送出回傳月報') }}</span>
                                    </button>

                                    <!-- 提示訊息 -->
                                    <div v-if="alertMessage" class="alert mt-3 mb-0" :class="'alert-' + alertType" role="alert">
                                        <i class="fas mr-1" :class="alertType === 'success' ? 'fa-check-circle' : 'fa-exclamation-circle'"></i>
                                        {{ alertMessage }}
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- 右欄：歷史報表與繳交紀錄 (最適化響應式排版) -->
                    <div class="col-12 col-lg-7 col-xl-8" :class="{ 'd-none d-lg-block': mobileActiveTab !== 'history' }">
                        <!-- 年度統計膠囊卡片 (Bootstrap 3等分 Grid，徹底防止溢出) -->
                        <div class="row mb-3">
                            <div class="col-12 col-sm-4 mb-2 mb-sm-0">
                                <div class="stat-card-compact">
                                    <div class="stat-compact-icon bg-light-primary text-primary">
                                        <i class="fas fa-calendar-check"></i>
                                    </div>
                                    <div>
                                        <div class="stat-compact-title">{{ selectedYear }} 年度已繳交</div>
                                        <div class="stat-compact-val text-primary">
                                            {{ yearUploadedCount }} <small style="font-size: 0.82rem; font-weight: normal; color: #64748b;">/ 12 個月</small>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div class="col-12 col-sm-4 mb-2 mb-sm-0">
                                <div class="stat-card-compact">
                                    <div class="stat-compact-icon bg-light-success text-success">
                                        <i class="fas fa-file-invoice"></i>
                                    </div>
                                    <div>
                                        <div class="stat-compact-title">累計繳交總份數</div>
                                        <div class="stat-compact-val text-success">
                                            {{ historyRecords.length }} <small style="font-size: 0.82rem; font-weight: normal; color: #64748b;">份</small>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div class="col-12 col-sm-4">
                                <div class="stat-card-compact">
                                    <div class="stat-compact-icon bg-light-info text-info">
                                        <i class="fas fa-percentage"></i>
                                    </div>
                                    <div>
                                        <div class="stat-compact-title">{{ selectedYear }} 年度繳交率</div>
                                        <div class="stat-compact-val text-info">
                                            {{ Math.round((yearUploadedCount / 12) * 100) }}%
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- 歷史紀錄清單卡片 -->
                        <div class="card-modern shadow-sm">
                            <div class="card-modern-header flex-wrap">
                                <div class="d-flex align-items-center mb-1 mb-sm-0">
                                    <h3 class="card-modern-title">
                                        <i class="fas fa-history text-secondary"></i>
                                        <span>洗掃作業月報歷史清單</span>
                                    </h3>
                                    <span class="badge badge-light border text-muted ml-2 font-weight-bold" style="font-size: 0.8rem;">
                                        共 {{ filteredRecords.length }} 筆
                                    </span>
                                </div>

                                <div class="d-flex align-items-center gap-2">
                                    <!-- 搜尋框 -->
                                    <div class="input-group input-group-sm" style="width: 175px;">
                                        <input type="text" class="form-control" placeholder="搜尋檔名或人員..." v-model="filterKeyword" />
                                        <div class="input-group-append" v-if="filterKeyword">
                                            <button class="btn btn-outline-secondary" type="button" v-on:click="filterKeyword = ''" title="清除搜尋">
                                                <i class="fas fa-times"></i>
                                            </button>
                                        </div>
                                    </div>

                                    <!-- 視圖切換 (桌面端/平板) -->
                                    <div class="btn-group btn-group-sm d-none d-md-inline-flex ml-2">
                                        <button type="button" class="btn" :class="viewMode === 'table' ? 'btn-primary' : 'btn-outline-secondary'" v-on:click="viewMode = 'table'" title="表格檢視">
                                            <i class="fas fa-table"></i>
                                        </button>
                                        <button type="button" class="btn" :class="viewMode === 'card' ? 'btn-primary' : 'btn-outline-secondary'" v-on:click="viewMode = 'card'" title="卡片檢視">
                                            <i class="fas fa-th-large"></i>
                                        </button>
                                    </div>
                                </div>
                            </div>

                            <div class="card-modern-body p-0">
                                <!-- 電腦端表格檢視 (Table View) -->
                                <div class="table-responsive" v-if="filteredRecords.length > 0 && viewMode === 'table'">
                                    <table class="history-table">
                                        <thead>
                                            <tr>
                                                <th style="width: 105px;" class="text-center">回報年月</th>
                                                <th>報表檔案名稱</th>
                                                <th style="width: 90px;" class="text-center">檔案大小</th>
                                                <th style="width: 140px;" class="text-center">上傳時間</th>
                                                <th style="width: 140px;">上傳人員</th>
                                                <th style="width: 85px;" class="text-center">操作功能</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <tr v-for="item in filteredRecords" :key="item.Pid">
                                                <td class="text-center">
                                                    <span class="year-month-tag">
                                                        {{ item.Year }}年 {{ item.Month < 10 ? '0' + item.Month : item.Month }}月
                                                    </span>
                                                </td>
                                                <td>
                                                    <a :href="'ReportUpload.aspx?action=download&facId=' + encodeURIComponent(item.FacId) + '&year=' + item.Year + '&month=' + item.Month" 
                                                       class="file-badge-link" target="_blank" :title="'點擊下載檢視：' + (item.FileName || item.DiskFileName)">
                                                        <i :class="getFileFaIcon(item.FileName || item.DiskFileName)" class="file-item-icon"></i>
                                                        <span class="file-item-name">
                                                            {{ item.FileName || item.DiskFileName }}
                                                        </span>
                                                    </a>
                                                </td>
                                                <td class="text-center">
                                                    <span class="badge badge-light border text-dark font-weight-bold" style="font-size: 0.8rem;">
                                                        {{ item.FileSizeFormatted }}
                                                    </span>
                                                </td>
                                                <td class="text-center" style="font-size: 0.82rem; color: #475569; font-weight: 600;">
                                                    {{ item.UploadDate }}
                                                </td>
                                                <td>
                                                    <div class="user-chip" :title="item.UploadUserName || item.UploadUser">
                                                        <i class="fas fa-user-circle text-primary"></i>
                                                        <span>{{ item.UploadUserName || item.UploadUser }}</span>
                                                    </div>
                                                </td>
                                                <td class="text-center">
                                                    <div class="btn-group btn-group-sm btn-action-group">
                                                        <a :href="'ReportUpload.aspx?action=download&facId=' + encodeURIComponent(item.FacId) + '&year=' + item.Year + '&month=' + item.Month" 
                                                           class="btn btn-outline-primary" title="下載此報表">
                                                            <i class="fas fa-download"></i>
                                                        </a>
                                                        <button type="button" class="btn btn-outline-danger" title="刪除此筆報表"
                                                                v-on:click="confirmDelete(item)">
                                                            <i class="fas fa-trash-alt"></i>
                                                        </button>
                                                    </div>
                                                </td>
                                            </tr>
                                        </tbody>
                                    </table>
                                </div>

                                <!-- 卡片檢視 (手機或切換模式) -->
                                <div class="p-3" v-else-if="filteredRecords.length > 0 && viewMode === 'card'">
                                    <div v-for="item in filteredRecords" :key="item.Pid" class="history-card-item">
                                        <div class="history-card-header">
                                            <span class="year-month-tag">
                                                {{ item.Year }}年 {{ item.Month < 10 ? '0' + item.Month : item.Month }}月
                                            </span>
                                            <span class="badge badge-light border text-secondary font-weight-bold">
                                                {{ item.FileSizeFormatted }}
                                            </span>
                                        </div>

                                        <div class="history-card-row">
                                            <div class="history-card-label">報表檔案</div>
                                            <div class="history-card-val">
                                                <a :href="'ReportUpload.aspx?action=download&facId=' + encodeURIComponent(item.FacId) + '&year=' + item.Year + '&month=' + item.Month" 
                                                   class="file-badge-link" target="_blank" :title="item.FileName || item.DiskFileName">
                                                    <i :class="getFileFaIcon(item.FileName || item.DiskFileName)" class="file-item-icon"></i>
                                                    <span class="file-item-name">{{ item.FileName || item.DiskFileName }}</span>
                                                </a>
                                            </div>
                                        </div>

                                        <div class="history-card-row">
                                            <div class="history-card-label">上傳時間</div>
                                            <div class="history-card-val text-muted small font-weight-bold">
                                                {{ item.UploadDate }}
                                            </div>
                                        </div>

                                        <div class="history-card-row">
                                            <div class="history-card-label">上傳人員</div>
                                            <div class="history-card-val">
                                                <span class="user-chip" :title="item.UploadUserName || item.UploadUser">
                                                    <i class="fas fa-user-circle text-primary"></i>
                                                    <span>{{ item.UploadUserName || item.UploadUser }}</span>
                                                </span>
                                            </div>
                                        </div>

                                        <div class="history-card-actions">
                                            <a :href="'ReportUpload.aspx?action=download&facId=' + encodeURIComponent(item.FacId) + '&year=' + item.Year + '&month=' + item.Month" 
                                               class="btn btn-outline-primary">
                                                <i class="fas fa-download mr-1"></i> 下載報表
                                            </a>
                                            <button type="button" class="btn btn-outline-danger" v-on:click="confirmDelete(item)">
                                                <i class="fas fa-trash-alt mr-1"></i> 刪除紀錄
                                            </button>
                                        </div>
                                    </div>
                                </div>

                                <!-- 空資料狀態 -->
                                <div v-else class="text-center py-5">
                                    <div class="mb-3 text-muted" style="font-size: 44px; opacity: 0.35;">
                                        <i class="fas fa-folder-open"></i>
                                    </div>
                                    <h5 class="text-muted font-weight-bold" style="font-size: 1rem;">目前無符合條件之歷史報表紀錄</h5>
                                    <p class="text-muted small mb-0">
                                        請於左側選取回報年月，並拖曳或選取檔案送出回報。
                                    </p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </form>

    <!-- 本地化 JS 庫依賴 -->
    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>

    <script>
        const { createApp } = Vue;

        createApp({
            data() {
                return {
                    loading: false,
                    uploading: false,
                    uploadProgress: 0,
                    alertMessage: '',
                    alertType: 'success',

                    // 使用者資訊
                    userId: '',
                    userName: '',
                    isManager: false,
                    currentFacId: '',
                    currentFacName: '',

                    // 選單與配置
                    facList: [],
                    yearList: [],
                    selectedYear: 115,
                    selectedMonth: 1,

                    // 檔案上傳
                    selectedFile: null,
                    isDragging: false,

                    // 當前選定年月的已有記錄
                    currentMonthRecord: null,

                    // 歷史清單
                    historyRecords: [],
                    filterKeyword: '',

                    // 行動端分頁與視圖模式 ('table' or 'card')
                    mobileActiveTab: 'upload',
                    viewMode: window.innerWidth < 768 ? 'card' : 'table'
                };
            },
            computed: {
                // 當前選取年度的已回報月數
                yearUploadedCount() {
                    return this.historyRecords.filter(r => r.Year === this.selectedYear).length;
                },
                // 過濾後的歷史記錄
                filteredRecords() {
                    if (!this.filterKeyword || !this.filterKeyword.trim()) {
                        return this.historyRecords;
                    }
                    const kw = this.filterKeyword.trim().toLowerCase();
                    return this.historyRecords.filter(r => {
                        const name = (r.FileName || '').toLowerCase();
                        const user = (r.UploadUserName || '').toLowerCase();
                        const ym = (r.Year + '年' + r.Month + '月').toLowerCase();
                        return name.includes(kw) || user.includes(kw) || ym.includes(kw);
                    });
                }
            },
            mounted() {
                window.addEventListener('resize', this.handleResize);
                this.loadInitData();
            },
            beforeUnmount() {
                window.removeEventListener('resize', this.handleResize);
            },
            methods: {
                handleResize() {
                    if (window.innerWidth < 768 && this.viewMode !== 'card') {
                        this.viewMode = 'card';
                    }
                },

                // 1. 載入初始化使用者、工廠與年度
                async loadInitData() {
                    this.loading = true;
                    try {
                        const res = await axios.get('ReportUpload.aspx?action=init');
                        if (res.data && res.data.Success) {
                            const d = res.data;
                            this.userId = d.User.UserId;
                            this.userName = d.User.UserName;
                            this.isManager = d.User.IsManager;
                            this.currentFacId = d.User.FacId;
                            this.currentFacName = d.User.FacName;

                            this.facList = d.FacList || [];
                            this.yearList = d.Years || [];
                            this.selectedYear = d.DefaultYear;
                            this.selectedMonth = d.DefaultMonth;

                            // 載入當前年月是否已有檔案
                            await this.checkCurrentMonthRecord();
                            // 載入歷史紀錄
                            await this.loadHistoryRecords();
                        } else if (res.data && res.data.NeedLogin) {
                            alert(res.data.Message);
                            window.location.href = '../Default.aspx';
                        } else {
                            this.showAlert(res.data ? res.data.Message : '初始化失敗', 'danger');
                        }
                    } catch (err) {
                        this.showAlert('載入初始化資料失敗：' + (err.message || err), 'danger');
                    } finally {
                        this.loading = false;
                    }
                },

                // 2. 切換公私場所 (管理員切換)
                async onFacChange() {
                    const match = this.facList.find(f => f.FacId === this.currentFacId);
                    this.currentFacName = match ? match.FacName : this.currentFacId;
                    await this.checkCurrentMonthRecord();
                    await this.loadHistoryRecords();
                },

                // 3. 切換年度
                async onYearChange() {
                    await this.checkCurrentMonthRecord();
                    await this.loadHistoryRecords();
                },

                // 4. 點選月份矩陣
                async selectMonth(m) {
                    this.selectedMonth = m;
                    this.clearAlert();
                    await this.checkCurrentMonthRecord();
                },

                // 5. 判斷某月份是否已回報 (矩陣指示)
                isMonthUploaded(m) {
                    return this.historyRecords.some(r => r.Year === this.selectedYear && r.Month === m);
                },

                // 6. 檢查當前選定年月是否已存在紀錄
                async checkCurrentMonthRecord() {
                    if (!this.currentFacId || !this.selectedYear || !this.selectedMonth) return;
                    try {
                        const res = await axios.get('ReportUpload.aspx', {
                            params: {
                                action: 'checkexists',
                                facId: this.currentFacId,
                                year: this.selectedYear,
                                month: this.selectedMonth
                            }
                        });
                        if (res.data && res.data.Success) {
                            this.currentMonthRecord = res.data;
                        }
                    } catch (err) {
                        console.error('檢查月份紀錄失敗', err);
                    }
                },

                // 7. 載入歷史報表清單
                async loadHistoryRecords() {
                    if (!this.currentFacId) return;
                    try {
                        const res = await axios.get('ReportUpload.aspx', {
                            params: {
                                action: 'gethistory',
                                facId: this.currentFacId
                            }
                        });
                        if (res.data && res.data.Success) {
                            this.historyRecords = res.data.Records || [];
                        }
                    } catch (err) {
                        console.error('載入歷史清單失敗', err);
                    }
                },

                // 8. 重新整理全部
                async refreshAll() {
                    await this.checkCurrentMonthRecord();
                    await this.loadHistoryRecords();
                    this.showAlert('資料已重新整理', 'success');
                },

                // 9. 觸發原生檔案選擇器
                triggerFileInput() {
                    this.$refs.fileInput.click();
                },

                // 10. 選取檔案處理
                onFileSelected(e) {
                    const files = e.target.files;
                    if (files && files.length > 0) {
                        this.validateAndSetFile(files[0]);
                    }
                },

                // 11. 拖曳檔案處理
                onDragOver() {
                    this.isDragging = true;
                },
                onDragLeave() {
                    this.isDragging = false;
                },
                onFileDrop(e) {
                    this.isDragging = false;
                    const files = e.dataTransfer.files;
                    if (files && files.length > 0) {
                        this.validateAndSetFile(files[0]);
                    }
                },

                // 12. 檔案檢核
                validateAndSetFile(file) {
                    this.clearAlert();
                    // 25MB 上限
                    if (file.size > 25 * 1024 * 1024) {
                        this.showAlert('檔案大小超過 25MB 限制，請縮減檔案後再試！', 'danger');
                        return;
                    }
                    this.selectedFile = file;
                },

                // 13. 清除選取之檔案
                clearSelectedFile() {
                    this.selectedFile = null;
                    if (this.$refs.fileInput) {
                        this.$refs.fileInput.value = '';
                    }
                },

                // 14. 送出檔案上傳
                async submitUpload() {
                    if (!this.selectedFile) {
                        this.showAlert('請選取要上傳的報表檔案！', 'danger');
                        return;
                    }

                    if (!this.currentFacId) {
                        this.showAlert('請先確認公私場所！', 'danger');
                        return;
                    }

                    // 若已有檔案，跳出提示詢問
                    if (this.currentMonthRecord && this.currentMonthRecord.Exists) {
                        const ok = confirm(`【${this.selectedYear}年${this.selectedMonth}月】已有上傳報表，是否確定覆蓋更新？`);
                        if (!ok) return;
                    }

                    this.uploading = true;
                    this.uploadProgress = 10;
                    this.clearAlert();

                    const formData = new FormData();
                    formData.append('file', this.selectedFile);
                    formData.append('facId', this.currentFacId);
                    formData.append('year', this.selectedYear);
                    formData.append('month', this.selectedMonth);

                    try {
                        const res = await axios.post('ReportUpload.aspx?action=upload', formData, {
                            headers: { 'Content-Type': 'multipart/form-data' },
                            onUploadProgress: (pe) => {
                                if (pe.total) {
                                    this.uploadProgress = Math.round((pe.loaded * 90) / pe.total);
                                }
                            }
                        });

                        this.uploadProgress = 100;

                        if (res.data && res.data.Success) {
                            this.showAlert(res.data.Message || '月報表上傳成功！', 'success');
                            this.clearSelectedFile();
                            await this.checkCurrentMonthRecord();
                            await this.loadHistoryRecords();
                        } else {
                            this.showAlert(res.data ? res.data.Message : '上傳失敗', 'danger');
                        }
                    } catch (err) {
                        this.showAlert('上傳作業失敗：' + (err.message || err), 'danger');
                    } finally {
                        this.uploading = false;
                        setTimeout(() => { this.uploadProgress = 0; }, 1000);
                    }
                },

                // 15. 下載當前月份之舊報表
                downloadCurrentMonthFile() {
                    if (!this.currentFacId) return;
                    window.location.href = `ReportUpload.aspx?action=download&facId=${encodeURIComponent(this.currentFacId)}&year=${this.selectedYear}&month=${this.selectedMonth}`;
                },

                // 16. 刪除報表紀錄
                async confirmDelete(item) {
                    const ym = `${item.Year}年${item.Month}月`;
                    const ok = confirm(`確定要永久刪除【${ym}】之月報表與實體檔案嗎？此動作無法復原！`);
                    if (!ok) return;

                    try {
                        const res = await axios.post(`ReportUpload.aspx?action=delete&pid=${item.Pid}`);
                        if (res.data && res.data.Success) {
                            this.showAlert(res.data.Message || '報表已成功刪除！', 'success');
                            await this.checkCurrentMonthRecord();
                            await this.loadHistoryRecords();
                        } else {
                            this.showAlert(res.data ? res.data.Message : '刪除失敗', 'danger');
                        }
                    } catch (err) {
                        this.showAlert('刪除作業失敗：' + (err.message || err), 'danger');
                    }
                },

                // 工具函式
                showAlert(msg, type) {
                    this.alertMessage = msg;
                    this.alertType = type || 'success';
                },
                clearAlert() {
                    this.alertMessage = '';
                },
                formatSize(bytes) {
                    if (!bytes) return '0 B';
                    if (bytes < 1024) return bytes + ' B';
                    if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
                    return (bytes / (1024 * 1024)).toFixed(2) + ' MB';
                },
                getFileFaIcon(filename) {
                    if (!filename) return 'fas fa-file';
                    const ext = filename.split('.').pop().toLowerCase();
                    if (ext === 'pdf') return 'fas fa-file-pdf text-danger';
                    if (['doc', 'docx'].includes(ext)) return 'fas fa-file-word text-primary';
                    if (['xls', 'xlsx', 'csv'].includes(ext)) return 'fas fa-file-excel text-success';
                    if (['jpg', 'jpeg', 'png'].includes(ext)) return 'fas fa-file-image text-info';
                    if (['zip', 'rar', '7z'].includes(ext)) return 'fas fa-file-archive text-warning';
                    return 'fas fa-file-alt text-secondary';
                },
                getFileIconClass(filename) {
                    if (!filename) return 'icon-def';
                    const ext = filename.split('.').pop().toLowerCase();
                    if (ext === 'pdf') return 'icon-pdf';
                    if (['doc', 'docx'].includes(ext)) return 'icon-doc';
                    if (['xls', 'xlsx', 'csv'].includes(ext)) return 'icon-xls';
                    if (['jpg', 'jpeg', 'png'].includes(ext)) return 'icon-img';
                    if (['zip', 'rar', '7z'].includes(ext)) return 'icon-zip';
                    return 'icon-def';
                }
            }
        }).mount('#app');
    </script>
</body>
</html>
