<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="CaseList.aspx.cs" Inherits="NTPC_FEC.Case.CaseList" %>

<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定逸散源管理平台 - 固定污染源巡查與任務派遣管理</title>

    <!-- 專屬 Favicon -->
    <link rel="shortcut icon" href="../favicon.ico" type="image/x-icon" />

    <!-- 本地化樣式庫：Bootstrap 4, FontAwesome 5, Leaflet 1.9.4 -->
    <link rel="stylesheet" href="../Content/bootstrap.min.css" />
    <link rel="stylesheet" href="../Content/fontawesome/css/all.min.css" />
    <link rel="stylesheet" href="../Content/leaflet/leaflet.css" />

    <style>
        :root {
            --brand-primary: #0099e5;     /* 新北青藍 */
            --brand-blue: #0284c7;        /* 科技藍 */
            --brand-dark-blue: #0b1f7d;   /* 海軍深藍 */
            --brand-navy: #0f172a;        /* 標題深色 */
            --brand-case: #386b70;        /* 巡查任務派遣主色 (青灰綠) */
            --brand-case-dark: #274d51;   /* 深青灰綠 */
            --brand-case-light: #eef6f6;  /* 淺青灰綠 */
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

        .nav-btn-link {
            color: #ffffff;
            background: rgba(255, 255, 255, 0.18);
            border-radius: 8px;
            padding: 6px 14px;
            font-size: 0.9rem;
            font-weight: 600;
            display: inline-flex;
            align-items: center;
            gap: 6px;
            transition: all 0.2s ease;
            text-decoration: none;
            border: 1px solid rgba(255, 255, 255, 0.3);
        }

        .nav-btn-link:hover {
            background: rgba(255, 255, 255, 0.32);
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
            color: var(--brand-case);
            background: #f8fafc;
        }

        .nav-mode-item.active {
            color: var(--brand-case-dark);
            border-bottom-color: var(--brand-case);
            font-weight: 700;
            background: var(--brand-case-light);
        }

        .tab-badge {
            font-size: 11px;
            padding: 2px 8px;
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
            gap: 8px;
            white-space: nowrap !important;
        }

        @media screen and (max-width: 576px) {
            .card-modern-header {
                padding: 10px 12px;
            }
            .card-modern-title {
                font-size: 0.95rem;
                gap: 6px;
            }
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
            transition: all 0.2s ease;
            cursor: pointer;
            height: 100%;
        }

        .stat-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
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

        /* 地圖容器與控制列 */
        #caseMap {
            width: 100%;
            height: 380px;
            border-radius: 8px;
            z-index: 10;
            transition: height 0.3s ease;
        }

        #caseMap.map-collapsed {
            height: 120px !important;
        }

        /* 地圖標記 Pin */
        .custom-fac-marker {
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .fac-marker-pin {
            width: 32px;
            height: 32px;
            border-radius: 50% 50% 50% 0;
            background: #0284c7;
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

        .fac-marker-pin.pin-major { background: #ef4444; }
        .fac-marker-pin.pin-minor { background: #f59e0b; }
        .fac-marker-pin.pin-zero  { background: #10b981; }

        .fac-marker-num {
            transform: rotate(45deg);
            color: #ffffff;
            font-weight: 800;
            font-size: 12px;
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
            padding: 12px 14px;
            border-bottom: 2px solid var(--border-color);
            border-top: none;
            white-space: nowrap;
        }

        .table-modern td {
            padding: 12px 14px;
            vertical-align: middle;
            border-bottom: 1px solid var(--border-color);
            color: var(--text-main);
            font-size: 14px;
            background: #ffffff;
        }

        .table-modern tbody tr:hover td {
            background: #f1f5f9;
        }

        /* 缺失記點膠囊標籤 */
        .loss-badge {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            font-size: 13px;
            font-weight: 700;
            padding: 4px 10px;
            border-radius: 20px;
            white-space: nowrap;
        }

        .loss-zero {
            background: #ecfdf5;
            color: #047857;
            border: 1px solid #a7f3d0;
        }

        .loss-minor {
            background: #fffbeb;
            color: #b45309;
            border: 1px solid #fde68a;
        }

        .loss-major {
            background: #fef2f2;
            color: #dc2626;
            border: 1px solid #fecaca;
        }

        /* 派遣警示 Tag */
        .mission-tag {
            display: inline-block;
            background: #fef2f2;
            color: #b91c1c;
            border: 1px solid #fca5a5;
            padding: 2px 6px;
            border-radius: 4px;
            font-size: 12px;
            font-weight: 700;
            margin-top: 4px;
        }

        /* 行政區選擇晶片 (Town Chips) */
        .town-chips-wrapper {
            display: flex;
            flex-wrap: wrap;
            gap: 6px;
            max-height: 110px;
            overflow-y: auto;
            padding: 4px 0;
        }

        .town-chip-btn {
            border: 1px solid #cbd5e1;
            background: #ffffff;
            color: #334155;
            padding: 4px 10px;
            border-radius: 6px;
            font-size: 12px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.15s ease;
        }

        .town-chip-btn.active {
            background: var(--brand-case);
            color: #ffffff;
            border-color: var(--brand-case-dark);
            font-weight: 700;
        }

        /* 查詢篩選底部操作列 RWD */
        .filter-footer-container {
            display: flex;
            flex-direction: column;
            gap: 10px;
        }

        .filter-footer-actions {
            display: flex;
            align-items: center;
            justify-content: flex-end;
            gap: 8px;
            width: 100%;
        }

        @media (min-width: 576px) {
            .filter-footer-container {
                flex-direction: row;
                align-items: center;
                justify-content: space-between;
                gap: 0;
            }
            .filter-footer-actions {
                width: auto;
            }
        }

        /* 動作按鈕群組 - 單行排版防折行 */
        .action-btn-group {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 5px;
            flex-wrap: nowrap !important;
            white-space: nowrap !important;
        }

        .btn-action {
            padding: 4px 10px;
            font-size: 12px;
            font-weight: 600;
            border-radius: 6px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 4px;
            transition: all 0.15s ease;
            min-height: 32px;
            white-space: nowrap !important;
            text-decoration: none !important;
        }

        /* 歷程比對 Modal 樣式 (現代化雙欄防跑版設計) */
        .modal-compare-dialog {
            max-width: 96vw;
            margin: 1rem auto;
        }

        .compare-header-box {
            background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
            color: #ffffff;
            padding: 12px 20px;
            border-bottom: 2px solid #334155;
        }

        .compare-control-bar {
            background: #f8fafc;
            border-bottom: 1px solid #e2e8f0;
            padding: 14px 20px;
        }

        .compare-sec-card {
            border: 1px solid #cbd5e1;
            border-radius: 10px;
            margin-bottom: 20px;
            overflow: hidden;
            background: #ffffff;
            box-shadow: 0 2px 8px rgba(15, 23, 42, 0.05);
        }

        .compare-sec-header {
            padding: 12px 18px;
            background: #f1f5f9;
            border-bottom: 1px solid #cbd5e1;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .compare-sec-body {
            padding: 16px;
            background: #f8fafc;
        }

        /* 雙欄獨立卡片 (解決左右黏在一起跑版) */
        .record-box {
            border-radius: 8px;
            overflow: hidden;
            background: #ffffff;
            height: 100%;
            display: flex;
            flex-direction: column;
            box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
            border: 2px solid transparent;
        }

        .record-box-a {
            border-color: #60a5fa;
        }

        .record-box-a .record-box-header {
            background: #eff6ff;
            border-bottom: 1.5px solid #bfdbfe;
            padding: 10px 14px;
        }

        .record-box-b {
            border-color: #94a3b8;
        }

        .record-box-b .record-box-header {
            background: #f1f5f9;
            border-bottom: 1.5px solid #cbd5e1;
            padding: 10px 14px;
        }

        .record-box-body {
            flex: 1 1 auto;
            padding: 14px;
        }

        .item-violation-box {
            background: #fef2f2;
            border: 1px solid #fecaca;
            border-radius: 6px;
            padding: 7px 12px;
            font-size: 13px;
            line-height: 1.4;
        }

        .item-compliant-box {
            background: #f0fdf4;
            border: 1px solid #bbf7d0;
            border-radius: 6px;
            padding: 7px 12px;
            font-size: 13px;
            line-height: 1.4;
        }

        .info-detail-box {
            border: 1px solid #e2e8f0;
            border-radius: 6px;
            background: #f8fafc;
            overflow: hidden;
        }

        .info-detail-row {
            display: flex;
            gap: 10px;
            padding: 6px 10px;
            border-bottom: 1px solid #e2e8f0;
            font-size: 13px;
            line-height: 1.4;
        }

        .info-detail-row:last-child {
            border-bottom: none;
        }

        .info-detail-label {
            flex: 0 0 38%;
            max-width: 38%;
            color: #64748b;
            font-weight: 700;
        }

        .info-detail-value {
            flex: 1 1 auto;
            color: #0f172a;
            word-break: break-all;
        }

        .photo-empty-state {
            background: #f8fafc;
            border: 1px dashed #cbd5e1;
            border-radius: 6px;
            padding: 18px 10px;
            text-align: center;
            color: #94a3b8;
            font-size: 12px;
        }

        .compare-photo-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(130px, 1fr));
            gap: 10px;
            margin-top: 8px;
        }

        .compare-photo-card {
            border: 1px solid #e2e8f0;
            border-radius: 6px;
            overflow: hidden;
            background: #ffffff;
            cursor: pointer;
            transition: transform 0.15s ease, box-shadow 0.15s ease;
        }

        .compare-photo-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 10px rgba(0,0,0,0.12);
        }

        .photo-img-wrapper {
            width: 100%;
            height: 95px;
            background: #f1f5f9;
            display: flex;
            align-items: center;
            justify-content: center;
            overflow: hidden;
        }

        .compare-photo-thumb {
            width: 100%;
            height: 100%;
            object-fit: cover;
            display: block;
        }

        .photo-placeholder {
            color: #94a3b8;
            font-size: 11px;
        }

        .compare-photo-label {
            font-size: 11px;
            font-weight: 700;
            padding: 3px 6px;
            background: #f8fafc;
            color: #475569;
            border-top: 1px solid #e2e8f0;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .compare-photo-memo {
            font-size: 11px;
            color: #64748b;
            padding: 2px 6px 4px 6px;
            background: #ffffff;
            line-height: 1.25;
            max-height: 38px;
            overflow: hidden;
        }

        @media (max-width: 991px) {
            .modal-compare-dialog {
                max-width: 98vw;
                margin: 0.5rem auto;
            }
        }

        /* 抽屜面板 (Offcanvas Drawer) */
        .drawer-overlay {
            position: fixed;
            top: 0; left: 0; right: 0; bottom: 0;
            background: rgba(15, 23, 42, 0.5);
            z-index: 1040;
            display: flex;
            justify-content: flex-end;
            backdrop-filter: blur(2px);
            animation: fadeIn 0.2s ease;
        }

        .drawer-content {
            background: #ffffff;
            width: var(--drawer-width, 1080px);
            max-width: 96vw;
            min-width: 540px;
            height: 100%;
            box-shadow: -6px 0 28px rgba(0, 0, 0, 0.22);
            display: flex;
            flex-direction: column;
            position: relative;
            overflow: hidden;
            transition: width 0.2s cubic-bezier(0.2, 0, 0, 1);
            animation: slideInRight 0.25s ease;
        }

        .drawer-content.resizing {
            transition: none !important;
            user-select: none;
        }

        /* 左側邊緣滑鼠拖曳拉桿 */
        .drawer-resize-handle {
            position: absolute;
            top: 0;
            left: 0;
            width: 10px;
            height: 100%;
            cursor: ew-resize;
            z-index: 1060;
            background: transparent;
            transition: background 0.15s ease;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .drawer-resize-handle:hover,
        .drawer-resize-handle.active {
            background: rgba(0, 123, 255, 0.25);
        }

        .drawer-resize-handle::after {
            content: '';
            width: 4px;
            height: 48px;
            border-radius: 2px;
            background: #cbd5e1;
            transition: background 0.15s ease, height 0.15s ease;
        }

        .drawer-resize-handle:hover::after,
        .drawer-resize-handle.active::after {
            background: #007bff;
            height: 64px;
        }

        /* 缺失項目膠囊徽章標籤 */
        .loss-item-tag {
            display: inline-block;
            background-color: #fff1f0;
            border: 1px solid #ffa39e;
            color: #cf1322;
            padding: 3px 8px;
            border-radius: 4px;
            font-size: 0.85rem;
            line-height: 1.35;
            margin-bottom: 4px;
            margin-right: 4px;
            word-break: break-word;
            text-align: left;
            box-shadow: 0 1px 2px rgba(207, 19, 34, 0.06);
        }

        .loss-item-tag i {
            margin-right: 4px;
        }

        .loss-item-tag:last-child {
            margin-bottom: 0;
        }

        /* 抽屜內緊湊型動作按鈕 */
        .drawer-action-btn {
            padding: 3px 7px !important;
            font-size: 0.82rem !important;
            line-height: 1.2 !important;
        }

        @keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
        @keyframes slideInRight { from { transform: translateX(100%); } to { transform: translateX(0); } }

        .drawer-header {
            padding: 16px 20px;
            background: linear-gradient(135deg, #386b70 0%, #274d51 100%);
            color: #ffffff;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .drawer-body {
            padding: 20px;
            overflow-y: auto;
            flex: 1;
        }

        .drawer-footer {
            padding: 12px 20px;
            background: #f8fafc;
            border-top: 1px solid var(--border-color);
            display: flex;
            justify-content: flex-end;
            gap: 10px;
        }

        /* 手機卡片式排版 */
        @media screen and (max-width: 991px) {
            .desktop-table-container {
                display: none !important;
            }
            .mobile-card-container {
                display: block !important;
            }
        }

        @media screen and (min-width: 992px) {
            .desktop-table-container {
                display: block !important;
            }
            .mobile-card-container {
                display: none !important;
            }
        }

        .fac-card-mobile {
            background: #ffffff;
            border: 1px solid var(--border-color);
            border-radius: 10px;
            padding: 16px;
            margin-bottom: 12px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.03);
        }
    </style>
</head>
<body>
    <div id="caseListApp" v-cloak>
        <!-- 頂部深青藍漸層導覽列 (全站標準左側導航、右側使用者與輔助操作) -->
        <header class="top-navbar">
            <div class="d-flex align-items-center">
                <a href="../MainPage.aspx?sub=menu1" class="nav-btn mr-2" title="返回主選單">
                    <i class="fas fa-home"></i>
                    <span class="d-none d-sm-inline">回首頁</span>
                </a>
                <a href="CaseList.aspx" class="navbar-brand-title">
                    <i class="fas fa-clipboard-check text-white"></i>
                    <span>固定源巡查與派遣管理</span>
                    <span class="badge badge-light text-dark font-weight-bold ml-1">
                        {{ counts.Total }} 筆
                    </span>
                </a>
            </div>

        </header>

        <!-- 業務模式分頁切換列 -->
        <nav class="nav-mode-bar">
            <div class="nav-mode-item" :class="{ 'active': filter.Mode === 'all' }" v-on:click="setMode('all')">
                <i class="fas fa-globe-asia"></i> 全部巡查 / 環域
                <span class="tab-badge badge-secondary ml-1">{{ counts.Total }}</span>
            </div>
            <div class="nav-mode-item" :class="{ 'active': filter.Mode === 'reject' }" v-on:click="setMode('reject')">
                <i class="fas fa-file-signature text-danger"></i> 查核暫存 (草稿)
                <span class="tab-badge badge-danger ml-1">{{ counts.Draft }}</span>
            </div>
            <div class="nav-mode-item" :class="{ 'active': filter.Mode === 'back' }" v-on:click="setMode('back')">
                <i class="fas fa-undo-alt text-warning"></i> 退件紀錄
                <span class="tab-badge badge-warning ml-1">{{ counts.Back }}</span>
            </div>
            <div class="nav-mode-item" :class="{ 'active': filter.Mode === 'mission7day' }" v-on:click="setMode('mission7day')">
                <i class="fas fa-exclamation-triangle text-danger"></i> 巡查派遣 (7天未改善)
                <span class="tab-badge badge-danger ml-1">{{ counts.Mission7Day }}</span>
            </div>
            <div class="nav-mode-item" :class="{ 'active': filter.Mode === 'mission2times' }" v-on:click="setMode('mission2times')">
                <i class="fas fa-shield-alt text-purple" style="color: #9333ea;"></i> 提報稽查 (稽查列管)
                <span class="tab-badge badge-info ml-1" style="background: #9333ea;">{{ counts.Mission2Times }}</span>
            </div>
            <div class="nav-mode-item" :class="{ 'active': filter.Mode === 'project' }" v-on:click="setMode('project')">
                <i class="fas fa-anchor text-primary"></i> 臺北港專區
                <span class="tab-badge badge-primary ml-1">{{ counts.Project }}</span>
            </div>
            <div class="nav-mode-item" :class="{ 'active': filter.Mode === 'search' }" v-on:click="setMode('search')">
                <i class="fas fa-history text-secondary"></i> 查核紀錄查詢
            </div>
        </nav>

        <!-- 主體內容容器 -->
        <main class="container-fluid py-3 px-3 px-lg-4">
            <!-- 1. KPI 統計指標卡片 -->
            <div class="row mb-3">
                <div class="col-6 col-md-4 col-xl-2 mb-2">
                    <div class="stat-card" v-on:click="setMode('reject')">
                        <div class="stat-icon bg-danger-light text-danger" style="background:#fee2e2;">
                            <i class="fas fa-edit"></i>
                        </div>
                        <div>
                            <div class="stat-val text-danger">{{ counts.Draft }}</div>
                            <div class="stat-label">暫存待修正</div>
                        </div>
                    </div>
                </div>
                <div class="col-6 col-md-4 col-xl-2 mb-2">
                    <div class="stat-card" v-on:click="setMode('back')">
                        <div class="stat-icon text-warning" style="background:#fef3c7;">
                            <i class="fas fa-reply-all"></i>
                        </div>
                        <div>
                            <div class="stat-val text-warning">{{ counts.Back }}</div>
                            <div class="stat-label">退回待重辦</div>
                        </div>
                    </div>
                </div>
                <div class="col-6 col-md-4 col-xl-2 mb-2">
                    <div class="stat-card" v-on:click="setMode('mission7day')">
                        <div class="stat-icon text-danger" style="background:#fee2e2;">
                            <i class="fas fa-hourglass-half"></i>
                        </div>
                        <div>
                            <div class="stat-val text-danger">{{ counts.Mission7Day }}</div>
                            <div class="stat-label">7天未改善派遣</div>
                        </div>
                    </div>
                </div>
                <div class="col-6 col-md-4 col-xl-2 mb-2">
                    <div class="stat-card" v-on:click="setMode('mission2times')">
                        <div class="stat-icon" style="background:#f3e8ff; color:#9333ea;">
                            <i class="fas fa-balance-scale"></i>
                        </div>
                        <div>
                            <div class="stat-val" style="color:#9333ea;">{{ counts.Mission2Times }}</div>
                            <div class="stat-label">提報稽查列管</div>
                        </div>
                    </div>
                </div>
                <div class="col-6 col-md-4 col-xl-2 mb-2">
                    <div class="stat-card" v-on:click="setMode('project')">
                        <div class="stat-icon bg-info-light text-info" style="background:#e0f2fe;">
                            <i class="fas fa-ship"></i>
                        </div>
                        <div>
                            <div class="stat-val text-info">{{ counts.Project }}</div>
                            <div class="stat-label">臺北港專區</div>
                        </div>
                    </div>
                </div>
                <div class="col-6 col-md-4 col-xl-2 mb-2">
                    <div class="stat-card">
                        <div class="stat-icon bg-success-light text-success" style="background:#dcfce7;">
                            <i class="fas fa-calendar-check"></i>
                        </div>
                        <div>
                            <div class="stat-val text-success">{{ counts.InvMonth }}</div>
                            <div class="stat-label">本月查核場次</div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- 2. 智慧現場地圖卡片 (遵循 inspection-ui-standard) -->
            <div class="card-modern">
                <div class="card-modern-header">
                    <div class="card-modern-title" style="white-space: nowrap !important; flex-shrink: 0;">
                        <i class="fas fa-map-marked-alt text-primary"></i>
                        <span class="text-nowrap font-weight-bold" style="white-space: nowrap !important;">現場智慧巡查地圖</span>
                        <span class="badge badge-light border text-muted ml-1 ml-sm-2 font-weight-normal text-nowrap" style="font-size:11px; white-space: nowrap !important;">
                            <span class="d-none d-sm-inline">標記點位數：</span>{{ mapMarkerCount }}<span class="d-inline d-sm-none"> 點</span>
                        </span>
                    </div>
                    <!-- 控制項零遮擋：定位與全景重設統一置於 Header 右側，支援極致 RWD (手機端純圖示無文字，確保小標不折行) -->
                    <div class="d-flex align-items-center gap-1 gap-sm-2 flex-shrink-0" style="white-space: nowrap !important;">
                        <button type="button" class="btn btn-sm btn-outline-primary px-2" v-on:click="locateMyGps" title="GPS 我的位置">
                            <i class="fas fa-crosshairs"></i><span class="d-none d-md-inline ml-1">GPS 我的位置</span>
                        </button>
                        <button type="button" class="btn btn-sm btn-outline-secondary px-2" v-on:click="resetMapView" title="全景重設">
                            <i class="fas fa-compress-arrows-alt"></i><span class="d-none d-md-inline ml-1">全景</span>
                        </button>
                        <button type="button" class="btn btn-sm btn-outline-dark px-2" v-on:click="isMapCollapsed = !isMapCollapsed" :title="isMapCollapsed ? '展開地圖' : '收合地圖'">
                            <i :class="isMapCollapsed ? 'fas fa-chevron-down' : 'fas fa-chevron-up'"></i><span class="d-none d-md-inline ml-1">{{ isMapCollapsed ? '展開地圖' : '收合地圖' }}</span>
                        </button>
                    </div>
                </div>
                <div class="card-modern-body p-0">
                    <div id="caseMap" :class="{ 'map-collapsed': isMapCollapsed }"></div>
                </div>
            </div>

            <!-- 3. 複合條件搜尋與外勤 GPS 定位卡片 (全站標準折疊與操作列) -->
            <div class="card-modern">
                <div class="card-modern-header" style="cursor: pointer;" v-on:click="filterCollapsed = !filterCollapsed">
                    <div class="card-modern-title">
                        <i class="fas fa-filter text-primary"></i>
                        <span>查詢與篩選設定</span>
                    </div>
                    <div class="d-flex align-items-center gap-2">
                        <button type="button" class="btn btn-sm btn-outline-success" v-on:click.stop="searchNearbyGps">
                            <i class="fas fa-street-view mr-1"></i> 搜尋附近場所 (環域 3km)
                        </button>
                        <button type="button" class="btn btn-link btn-sm text-muted p-0 ml-2">
                            <i class="fas" :class="filterCollapsed ? 'fa-chevron-down' : 'fa-chevron-up'"></i>
                        </button>
                    </div>
                </div>
                <div class="card-modern-body" v-show="!filterCollapsed">
                    <div class="row">
                        <div class="col-12 col-md-4 col-lg-3 mb-2">
                            <label class="small font-weight-bold text-muted mb-1">公私場所名稱</label>
                            <input type="text" id="searchFacNameInput" class="form-control form-control-sm" v-model="filter.FacName" placeholder="輸入關鍵字..." v-on:keyup.enter="loadData(1)" />
                        </div>
                        <div class="col-12 col-md-4 col-lg-3 mb-2">
                            <label class="small font-weight-bold text-muted mb-1">管制編號 (C_NO)</label>
                            <input type="text" class="form-control form-control-sm" v-model="filter.CNo" placeholder="如 F1234567" v-on:keyup.enter="loadData(1)" />
                        </div>
                        <div class="col-12 col-md-4 col-lg-3 mb-2">
                            <label class="small font-weight-bold text-muted mb-1">統一編號</label>
                            <input type="text" class="form-control form-control-sm" v-model="filter.ScId" placeholder="8碼統一編號..." v-on:keyup.enter="loadData(1)" />
                        </div>
                        <div class="col-12 col-md-4 col-lg-3 mb-2">
                            <label class="small font-weight-bold text-muted mb-1">排序方式</label>
                            <select class="form-control form-control-sm" v-model="filter.SortBy" v-on:change="loadData(1)">
                                <option value="loss_desc">缺失記點 (高至低)</option>
                                <option value="loss_asc">缺失記點 (低至高)</option>
                                <option value="date_desc">最近巡查日期 (近至遠)</option>
                                <option value="name_asc">場所名稱 (筆畫順序)</option>
                            </select>
                        </div>
                    </div>

                    <!-- 行政區選取晶片 -->
                    <div class="mt-2">
                        <div class="d-flex align-items-center justify-content-between mb-1">
                            <label class="small font-weight-bold text-muted m-0">新北市行政區選取 (已選 {{ filter.Towns.length }} 區)：</label>
                            <div>
                                <button type="button" class="btn btn-link btn-sm p-0 mr-2 text-primary font-weight-bold" v-on:click="selectAllTowns">全選</button>
                                <button type="button" class="btn btn-link btn-sm p-0 text-muted" v-on:click="clearAllTowns">清除</button>
                            </div>
                        </div>
                        <div class="town-chips-wrapper">
                            <button type="button" v-for="t in townList" :key="t.TOWN_NO" 
                                    class="town-chip-btn" :class="{ 'active': filter.Towns.includes(t.TOWN_NA) }"
                                    v-on:click="toggleTown(t.TOWN_NA)">
                                {{ t.TOWN_NA }}
                            </button>
                        </div>
                    </div>

                    <div class="filter-footer-container mt-3 pt-2 border-top">
                        <div class="small text-muted text-nowrap">
                            共查詢到 <strong class="text-primary font-weight-bold">{{ totalCount }}</strong> 家巡查場所
                        </div>
                        <div class="filter-footer-actions">
                            <button type="button" class="btn btn-outline-secondary btn-sm" v-on:click="resetFilter">
                                <i class="fas fa-undo mr-1"></i> 重設條件
                            </button>
                            <button type="button" class="btn btn-primary btn-sm px-3 font-weight-bold" v-on:click="loadData(1)">
                                <i class="fas fa-search mr-1"></i> 立即查詢
                            </button>
                        </div>
                    </div>
                </div>
            </div>

            <!-- 4. 公私場所查核清單卡片 -->
            <div class="card-modern">
                <div class="card-modern-header">
                    <div class="d-flex align-items-center gap-2">
                        <div class="card-modern-title">
                            <i class="fas fa-list-alt text-primary"></i>
                            <span>巡查場所列表</span>
                        </div>
                        <span class="badge badge-light border text-dark font-weight-bold ml-1">
                            共 {{ totalCount }} 家
                        </span>
                        <span class="badge badge-secondary ml-1 d-none d-sm-inline">
                            頁次 {{ currentPage }} / {{ totalPages }}
                        </span>
                    </div>
                    <div class="d-flex align-items-center">
                        <div class="text-muted small mr-2 d-none d-xl-inline" v-if="gpsDistanceMessage">
                            <i class="fas fa-location-arrow text-success mr-1"></i>{{ gpsDistanceMessage }}
                        </div>

                        <!-- 1. 重新整理 -->
                        <button type="button" class="btn btn-sm btn-outline-secondary mr-2" v-on:click="loadData(currentPage)" :disabled="loading" title="重新整理場所清單">
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
                                <option :value="15">15 筆</option>
                                <option :value="30">30 筆</option>
                                <option :value="50">50 筆</option>
                            </select>
                        </div>
                    </div>
                </div>
                <div class="card-modern-body p-0">
                    <!-- 載入中動畫 -->
                    <div v-if="loading" class="text-center py-5">
                        <div class="spinner-border text-primary" role="status">
                            <span class="sr-only">載入中...</span>
                        </div>
                        <div class="mt-2 text-muted small font-weight-bold">正在讀取場所與查核資料...</div>
                    </div>

                    <!-- 無資料提示 -->
                    <div v-else-if="items.length === 0" class="text-center py-5 text-muted">
                        <i class="fas fa-folder-open fa-3x mb-3 text-secondary"></i>
                        <div>查無符合篩選條件的公私場所。</div>
                    </div>

                    <!-- 電腦版表格佈局 -->
                    <div v-else class="desktop-table-container table-responsive">
                        <table class="table table-modern">
                            <thead>
                                <tr>
                                    <th style="width: 120px;">管制編號</th>
                                    <th style="min-width: 220px;">公私場所名稱</th>
                                    <th style="width: 160px;">行政區 / 行業別</th>
                                    <th style="min-width: 200px;">製程摘要</th>
                                    <th style="width: 120px;">統一編號</th>
                                    <th style="width: 110px;" class="text-center">缺失記點</th>
                                    <th style="min-width: 200px;">最新查核說明</th>
                                    <th style="width: 200px;" class="text-center">操作功能</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr v-for="item in items" :key="item.FAC_ID" :id="'fac-row-' + item.FAC_ID">
                                    <td>
                                        <span class="badge badge-light border text-dark font-weight-bold" style="font-size:13px;">
                                            {{ item.C_NO || '-' }}
                                        </span>
                                    </td>
                                    <td>
                                        <div class="font-weight-bold text-dark">{{ item.FAC_NAME }}</div>
                                        <div v-if="item.Mission" class="mission-tag">
                                            <i class="fas fa-bell mr-1"></i>{{ item.Mission }}
                                        </div>
                                        <div v-if="item.MissionDeadline" class="small text-danger font-weight-bold">
                                            <i class="far fa-clock mr-1"></i>{{ item.MissionDeadline }}
                                        </div>
                                    </td>
                                    <td>
                                        <div class="font-weight-bold text-primary">{{ item.TOWN || '-' }}</div>
                                        <div class="small text-muted">{{ item.Industrial || '-' }}</div>
                                    </td>
                                    <td>
                                        <div class="small text-muted" style="max-width:280px; line-height: 1.4;">
                                            {{ item.ProcessSummary }}
                                        </div>
                                    </td>
                                    <td>
                                        <button type="button" class="btn btn-link btn-sm p-0 text-dark font-weight-bold text-decoration-none" 
                                                v-on:click="openGcModal(item.S_C_ID)">
                                            {{ item.S_C_ID || '-' }}
                                            <i class="fas fa-external-link-alt text-muted small ml-1"></i>
                                        </button>
                                    </td>
                                    <td class="text-center">
                                        <span class="loss-badge" :class="item.Loss_CSS">
                                            <i class="fas mr-1" :class="item.Loss_Point > 0 ? 'fa-exclamation-circle' : 'fa-check-circle'"></i>
                                            {{ item.Loss_Point }} 點
                                        </span>
                                    </td>
                                    <td>
                                        <div class="small text-secondary" style="max-width: 260px;">
                                            <div class="text-muted font-weight-bold mb-1">
                                                查核日期：{{ item.LastInvDate }}
                                            </div>
                                            {{ item.Loss_Detail }}
                                        </div>
                                    </td>
                                    <td class="text-center">
                                        <div class="action-btn-group">
                                            <button type="button" class="btn btn-sm btn-info btn-action" v-on:click="openFacDrawer(item)">
                                                <i class="fas fa-list-alt"></i> 查核歷程
                                            </button>
                                            <button type="button" class="btn btn-sm btn-warning btn-action text-dark" v-on:click="navigateNewCase(item, false)">
                                                <i class="fas fa-plus"></i> 新增巡查
                                            </button>
                                            <button v-if="item.HasActiveMission" type="button" class="btn btn-sm btn-outline-danger btn-action" v-on:click="openCancelMissionModal(item)">
                                                <i class="fas fa-times"></i> 移除派遣
                                            </button>
                                            <button v-if="item.Lat && item.Lng" type="button" class="btn btn-sm btn-light btn-action border" v-on:click="panToMap(item.Lat, item.Lng, item)">
                                                <i class="fas fa-map-pin text-primary"></i>
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>

                    <!-- 手機端卡片流動排版 -->
                    <div v-if="items.length > 0" class="mobile-card-container p-3">
                        <div v-for="item in items" :key="item.FAC_ID" class="fac-card-mobile">
                            <div class="d-flex align-items-center justify-content-between mb-2">
                                <span class="badge badge-light border text-dark font-weight-bold">
                                    {{ item.C_NO || '-' }}
                                </span>
                                <span class="loss-badge" :class="item.Loss_CSS">
                                    {{ item.Loss_Point }} 點
                                </span>
                            </div>
                            <div class="font-weight-bold text-dark h6 mb-1">{{ item.FAC_NAME }}</div>
                            <div class="small text-muted mb-2">
                                <i class="fas fa-map-marker-alt text-primary mr-1"></i>{{ item.TOWN }} | {{ item.ADDR }}
                            </div>
                            <div v-if="item.Mission" class="mission-tag mb-2 d-block">
                                <i class="fas fa-bell mr-1"></i>{{ item.Mission }}
                            </div>
                            <div class="small text-muted mb-2">
                                <strong>最新查核：</strong>{{ item.LastInvDate }} - {{ item.Loss_Detail }}
                            </div>
                            <div class="d-flex align-items-center justify-content-between pt-2 border-top">
                                <button type="button" class="btn btn-link btn-sm p-0 text-muted" v-on:click="openGcModal(item.S_C_ID)">
                                    統編：{{ item.S_C_ID || '-' }}
                                </button>
                                <div class="action-btn-group">
                                    <button type="button" class="btn btn-sm btn-info btn-action" v-on:click="openFacDrawer(item)">
                                        <i class="fas fa-list-alt"></i> 歷程
                                    </button>
                                    <button type="button" class="btn btn-sm btn-warning btn-action text-dark" v-on:click="navigateNewCase(item, false)">
                                        <i class="fas fa-plus"></i> 新增
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- 分頁控制列 -->
                    <div class="p-3 d-flex align-items-center justify-content-between border-top bg-light" v-if="totalPages > 1">
                        <div class="small text-muted">
                            顯示第 {{ (pageIndex - 1) * pageSize + 1 }} 至 {{ Math.min(pageIndex * pageSize, totalCount) }} 筆，共 {{ totalCount }} 筆
                        </div>
                        <ul class="pagination pagination-sm m-0">
                            <li class="page-item" :class="{ 'disabled': pageIndex <= 1 }">
                                <a class="page-link" href="javascript:void(0)" v-on:click="loadData(pageIndex - 1)">上一頁</a>
                            </li>
                            <li v-for="p in visiblePages" :key="p" class="page-item" :class="{ 'active': p === pageIndex }">
                                <a class="page-link" href="javascript:void(0)" v-on:click="loadData(p)">{{ p }}</a>
                            </li>
                            <li class="page-item" :class="{ 'disabled': pageIndex >= totalPages }">
                                <a class="page-link" href="javascript:void(0)" v-on:click="loadData(pageIndex + 1)">下一頁</a>
                            </li>
                        </ul>
                    </div>
                </div>
            </div>
        </main>

        <!-- 5. 場所歷程與查核抽屜 (Offcanvas Drawer) -->
        <div v-if="isDrawerOpen" class="drawer-overlay" v-on:click.self="closeFacDrawer">
            <div class="drawer-content" :class="{ 'resizing': isResizingDrawer }" :style="{ width: drawerWidth + 'px' }">
                <!-- 左側拖曳拉桿 -->
                <div class="drawer-resize-handle" 
                     :class="{ 'active': isResizingDrawer }" 
                     title="按住左右拖曳可調整視窗寬度"
                     v-on:mousedown.stop="startDrawerResize"></div>

                <div class="drawer-header d-flex justify-content-between align-items-center">
                    <div>
                        <h5 class="m-0 font-weight-bold text-white">
                            <i class="fas fa-building mr-2"></i>{{ activeFac.FAC_NAME }}
                        </h5>
                        <small class="text-white-50">管制編號：{{ activeFac.C_NO || '-' }} | 行政區：{{ activeFac.TOWN || '-' }}</small>
                    </div>
                    <div class="d-flex align-items-center gap-2">
                        <!-- 寬度切換快速按鈕 -->
                        <button type="button" class="btn btn-sm btn-outline-light font-weight-bold text-white mr-2" 
                                v-on:click="toggleDrawerWidthMode" 
                                :title="getDrawerWidthModeTitle">
                            <i class="fas mr-1" :class="getDrawerWidthModeIcon"></i>
                            <span class="d-none d-sm-inline">{{ drawerWidthLabel }}</span>
                        </button>
                        <button type="button" class="btn btn-sm btn-light" v-on:click="closeFacDrawer">
                            <i class="fas fa-times"></i>
                        </button>
                    </div>
                </div>
                    <button type="button" class="btn btn-sm btn-light" v-on:click="closeFacDrawer">
                        <i class="fas fa-times"></i>
                    </button>
                </div>

                <div class="bg-light px-3 border-bottom">
                    <ul class="nav nav-tabs border-0">
                        <li class="nav-item">
                            <a class="nav-link font-weight-bold" :class="{ 'active': drawerTab === 'invs' }" href="javascript:void(0)" v-on:click="drawerTab = 'invs'">
                                <i class="fas fa-clipboard-list mr-1"></i> 歷次現場查核清單 ({{ drawerInvs.length }})
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link font-weight-bold" :class="{ 'active': drawerTab === 'basic' }" href="javascript:void(0)" v-on:click="drawerTab = 'basic'">
                                <i class="fas fa-info-circle mr-1"></i> 場所基本資料維護
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link font-weight-bold" :class="{ 'active': drawerTab === 'diagrams' }" href="javascript:void(0)" v-on:click="drawerTab = 'diagrams'">
                                <i class="fas fa-images mr-1"></i> 配置圖與流程圖
                            </a>
                        </li>
                    </ul>
                </div>

                <div class="drawer-body">
                    <!-- Tab 1: 歷次現場查核紀錄 -->
                    <div v-if="drawerTab === 'invs'">
                        <div class="d-flex align-items-center justify-content-between mb-3 flex-wrap gap-2">
                            <div class="d-flex align-items-center">
                                <h6 class="font-weight-bold text-dark m-0 mr-2">現場巡查歷程紀錄</h6>
                                <span class="badge badge-secondary">{{ drawerInvs.length }} 次</span>
                            </div>
                            <div class="d-flex align-items-center gap-2">
                                <button type="button" class="btn btn-sm btn-outline-primary font-weight-bold" 
                                        v-on:click="openCompareModalByDefault" 
                                        :disabled="(drawerInvs && drawerInvs.length < 2)" 
                                        title="比對任意兩次現場查核紀錄之評核與照片">
                                    <i class="fas fa-columns mr-1"></i> 歷程雙向比對
                                </button>
                                <button type="button" class="btn btn-sm btn-success font-weight-bold" v-on:click="navigateNewCase(activeFac, false)">
                                    <i class="fas fa-plus mr-1"></i> 進行新增巡查
                                </button>
                            </div>
                        </div>

                        <!-- 勾選比對提示工具列 -->
                        <div v-if="selectedCompareInvNos && selectedCompareInvNos.length > 0" class="alert alert-info py-2 px-3 mb-3 d-flex align-items-center justify-content-between flex-wrap gap-2">
                            <div class="small">
                                <i class="fas fa-info-circle mr-1"></i>
                                已選取 <strong class="text-primary font-weight-bold">{{ selectedCompareInvNos.length }}</strong> / 2 筆紀錄進行比對
                                <span v-if="selectedCompareInvNos.length === 2" class="text-success font-weight-bold ml-1">（已就緒）</span>
                                <span v-else class="text-muted ml-1">（請勾選任 2 筆進入雙向對照）</span>
                            </div>
                            <div class="d-flex align-items-center">
                                <button type="button" class="btn btn-primary btn-sm px-3 mr-2 font-weight-bold shadow-sm" 
                                        :disabled="selectedCompareInvNos.length !== 2" 
                                        v-on:click="startCompareSelected">
                                    <i class="fas fa-exchange-alt mr-1"></i> 開始雙向比對
                                </button>
                                <button type="button" class="btn btn-link btn-sm text-secondary p-0" v-on:click="selectedCompareInvNos = []">
                                    清除勾選
                                </button>
                            </div>
                        </div>

                        <div v-if="(!drawerInvs || drawerInvs.length === 0)" class="text-center py-5 text-muted">
                            <i class="fas fa-clipboard-check fa-3x mb-2 text-secondary"></i>
                            <div>目前尚無任何現場查核紀錄。</div>
                        </div>

                        <div v-else class="table-responsive">
                            <table class="table table-bordered table-hover align-middle mb-0" style="min-width: 860px;">
                                <thead class="thead-light">
                                    <tr>
                                        <th style="width: 44px;" class="text-center" title="勾選兩筆進行比對">比對</th>
                                        <th style="width: 125px;">巡查時間 / 屬性</th>
                                        <th style="width: 85px;" class="text-center">運作狀態</th>
                                        <th style="width: 75px;" class="text-center">缺失記點</th>
                                        <th style="min-width: 280px;">缺失項目內容</th>
                                        <th style="width: 85px;" class="text-center">審核狀態</th>
                                        <th style="width: 145px;" class="text-center">功能動作</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr v-for="inv in drawerInvs" :key="inv.INV_NO">
                                        <td class="text-center align-middle">
                                            <input type="checkbox" :value="inv.INV_NO" v-model="selectedCompareInvNos" v-on:change="onCompareCheckboxChange(inv.INV_NO)" title="選擇此筆" />
                                        </td>
                                        <td>
                                            <div class="font-weight-bold">{{ inv.INV_DATE }}</div>
                                            <span class="badge badge-secondary">{{ inv.INV_TYPE }}</span>
                                        </td>
                                        <td class="text-center">{{ inv.Work_State || '正常操作' }}</td>
                                        <td class="text-center">
                                            <span class="loss-badge" :class="inv.Total_Loss_Point > 0 ? 'loss-major' : 'loss-zero'">
                                                {{ inv.Total_Loss_Point }} 點
                                            </span>
                                        </td>
                                        <td>
                                            <div v-if="!inv.Loss_Detail || inv.Loss_Detail.trim() === '' || inv.Loss_Detail === '無缺失' || inv.Total_Loss_Point === 0" class="text-success small font-weight-bold">
                                                <i class="fas fa-check-circle mr-1"></i>全項符合防制規範 (無缺失)
                                            </div>
                                            <div v-else class="d-flex flex-column align-items-start">
                                                <span v-for="(item, idx) in parseLossDetails(inv.Loss_Detail)" :key="idx" class="loss-item-tag">
                                                    <i class="fas fa-exclamation-circle text-danger"></i>{{ item }}
                                                </span>
                                            </div>
                                        </td>
                                        <td class="text-center">
                                            <span class="badge font-weight-bold" :class="getInvStateBadgeClass(inv.INV_State)">
                                                {{ inv.State_Name }}
                                            </span>
                                        </td>
                                        <td class="text-center">
                                            <div class="action-btn-group">
                                                <button type="button" class="btn btn-sm btn-outline-dark btn-action drawer-action-btn" title="與相鄰歷程比對" v-on:click="quickCompareInv(inv)">
                                                    <i class="fas fa-exchange-alt"></i>
                                                </button>
                                                <button v-if="inv.CanEdit" type="button" class="btn btn-sm btn-outline-primary btn-action drawer-action-btn" title="修改" v-on:click="navigateEditCase(inv.INV_NO)">
                                                    <i class="fas fa-edit"></i>
                                                </button>
                                                <button v-if="inv.CanSubmit" type="button" class="btn btn-sm btn-outline-success btn-action drawer-action-btn" title="送出審查" v-on:click="submitUploadCheck(inv.INV_NO, inv.INV_DATE)">
                                                    <i class="fas fa-paper-plane"></i>
                                                </button>
                                                <button v-if="inv.CanSign" type="button" class="btn btn-sm btn-outline-warning btn-action drawer-action-btn text-dark" title="簽名確認" v-on:click="navigateResultCase(inv.INV_NO, false)">
                                                    <i class="fas fa-signature"></i>
                                                </button>
                                                <button type="button" class="btn btn-sm btn-outline-info btn-action drawer-action-btn" title="檢視詳細" v-on:click="navigateResultCase(inv.INV_NO, true)">
                                                    <i class="fas fa-eye"></i>
                                                </button>
                                                <button v-if="inv.CanDelete" type="button" class="btn btn-sm btn-outline-danger btn-action drawer-action-btn" title="刪除紀錄" v-on:click="deleteInvRecord(inv.INV_NO, inv.INV_DATE)">
                                                    <i class="fas fa-trash"></i>
                                                </button>
                                            </div>
                                        </td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>

                    <!-- Tab 2: 場所基本資料維護 -->
                    <div v-if="drawerTab === 'basic'">
                        <div class="d-flex align-items-center justify-content-between mb-3">
                            <h6 class="font-weight-bold text-dark m-0">公私場所登記資料</h6>
                            <span v-if="!activeFacInfo.CanEdit" class="badge badge-light border text-muted">
                                <i class="fas fa-lock mr-1"></i>僅首次巡查可修改基本資料
                            </span>
                        </div>

                        <div class="row">
                            <div class="col-md-6 mb-3">
                                <label class="small font-weight-bold text-muted">場所名稱</label>
                                <input type="text" class="form-control" v-model="activeFacInfo.FAC_NAME" :readonly="!activeFacInfo.CanEdit" />
                            </div>
                            <div class="col-md-6 mb-3">
                                <label class="small font-weight-bold text-muted">管制編號</label>
                                <input type="text" class="form-control" v-model="activeFacInfo.C_NO" :readonly="!activeFacInfo.CanEdit" />
                            </div>
                            <div class="col-md-12 mb-3">
                                <label class="small font-weight-bold text-muted">場所地址</label>
                                <input type="text" class="form-control" v-model="activeFacInfo.ADDR" :readonly="!activeFacInfo.CanEdit" />
                            </div>
                            <div class="col-md-6 mb-3">
                                <label class="small font-weight-bold text-muted">地號</label>
                                <input type="text" class="form-control" v-model="activeFacInfo.Land_no" :readonly="!activeFacInfo.CanEdit" />
                            </div>
                            <div class="col-md-6 mb-3">
                                <label class="small font-weight-bold text-muted">工廠登記證編號</label>
                                <input type="text" class="form-control" v-model="activeFacInfo.Lic_NO" :readonly="!activeFacInfo.CanEdit" />
                            </div>
                            <div class="col-md-6 mb-3">
                                <label class="small font-weight-bold text-muted">電話</label>
                                <input type="text" class="form-control" v-model="activeFacInfo.TEL" :readonly="!activeFacInfo.CanEdit" />
                            </div>
                            <div class="col-md-6 mb-3">
                                <label class="small font-weight-bold text-muted">傳真</label>
                                <input type="text" class="form-control" v-model="activeFacInfo.FAX" :readonly="!activeFacInfo.CanEdit" />
                            </div>
                            <div class="col-md-6 mb-3">
                                <label class="small font-weight-bold text-muted">統一編號</label>
                                <input type="text" class="form-control" v-model="activeFacInfo.S_C_ID" :readonly="!activeFacInfo.CanEdit" />
                            </div>
                            <div class="col-md-6 mb-3">
                                <label class="small font-weight-bold text-muted">負責人姓名</label>
                                <input type="text" class="form-control" v-model="activeFacInfo.BOSS_NAME" :readonly="!activeFacInfo.CanEdit" />
                            </div>
                            <div class="col-md-6 mb-3">
                                <label class="small font-weight-bold text-muted">聯絡人姓名</label>
                                <input type="text" class="form-control" v-model="activeFacInfo.Content_Name" :readonly="!activeFacInfo.CanEdit" />
                            </div>
                        </div>

                        <div v-if="activeFacInfo.CanEdit" class="text-right mt-3 pt-2 border-top">
                            <button type="button" class="btn btn-success font-weight-bold px-4" v-on:click="saveFacEditInfo">
                                <i class="fas fa-save mr-1"></i> 儲存異動
                            </button>
                        </div>
                    </div>

                    <!-- Tab 3: 配置圖與製程流程圖 -->
                    <div v-if="drawerTab === 'diagrams'">
                        <div v-if="drawerDiagrams.length === 0" class="text-center py-5 text-muted">
                            <i class="fas fa-file-image fa-3x mb-2 text-secondary"></i>
                            <div>該公私場所尚未上傳配置圖或製程流程圖。</div>
                        </div>
                        <div v-else class="row">
                            <div v-for="d in drawerDiagrams" :key="d.FileName" class="col-12 mb-3">
                                <div class="card border">
                                    <div class="card-header bg-white font-weight-bold d-flex justify-content-between align-items-center">
                                        <span><i class="fas fa-file-alt text-primary mr-2"></i>{{ d.FileType }} ({{ d.FileName }})</span>
                                        <a :href="d.FileUrl" target="_blank" class="btn btn-sm btn-outline-primary">
                                            <i class="fas fa-external-link-alt mr-1"></i>另開檢視
                                        </a>
                                    </div>
                                    <div class="card-body p-2 text-center">
                                        <div v-if="d.IsPdf === 'true'">
                                            <div class="mb-2">
                                                <a :href="d.FileUrl" target="_blank" class="btn btn-primary btn-sm px-3 shadow-sm font-weight-bold">
                                                    <i class="fas fa-file-pdf mr-1"></i> 開啟 PDF 原檔檢視 (支援手勢縮放/翻頁)
                                                </a>
                                            </div>
                                            <iframe :src="d.FileUrl" style="width:100%; height:450px; border:1px solid #e2e8f0; border-radius:6px;"></iframe>
                                        </div>
                                        <div v-else>
                                            <a :href="d.FileUrl" target="_blank">
                                                <img :src="d.FileUrl" class="img-fluid rounded border shadow-sm" style="max-height:450px;" />
                                            </a>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="drawer-footer">
                    <button type="button" class="btn btn-secondary" v-on:click="closeFacDrawer">關閉視窗</button>
                </div>
            </div>
        </div>

        <!-- 7. 歷次現場查核雙向比對視窗 (Compare Modal) -->
        <div v-if="isCompareModalOpen" class="modal fade show d-block" tabindex="-1" style="background: rgba(15, 23, 42, 0.7); z-index: 1060; overflow-y: auto;">
            <div class="modal-dialog modal-dialog-scrollable modal-compare-dialog">
                <div class="modal-content border-0 shadow-lg" style="border-radius: 12px; overflow: hidden;">
                    <!-- 標題列 -->
                    <div class="compare-header-box d-flex align-items-center justify-content-between">
                        <div class="d-flex align-items-center">
                            <i class="fas fa-columns text-primary fa-lg mr-2"></i>
                            <div>
                                <h5 class="m-0 font-weight-bold text-white">現場查核歷程雙向比對</h5>
                                <div class="small text-white-50">{{ activeFac.FAC_NAME }} ({{ activeFac.C_NO }})</div>
                            </div>
                        </div>
                        <button type="button" class="close text-white" style="font-size: 1.8rem;" v-on:click="isCompareModalOpen = false">&times;</button>
                    </div>

                    <!-- 控制選單與過濾列 -->
                    <div class="compare-control-bar">
                        <div class="row align-items-end">
                            <div class="col-lg-5 col-md-5 col-12 mb-2 mb-md-0">
                                <label class="small font-weight-bold text-muted mb-1 d-flex align-items-center">
                                    <span class="badge badge-primary mr-1">紀錄 A (基準)</span> 選擇查核時間：
                                </label>
                                <select class="form-control font-weight-bold" style="height: 38px;" v-model="compareInvNoA" v-on:change="fetchCompareData">
                                    <option v-for="inv in drawerInvs" :key="'A_' + inv.INV_NO" :value="inv.INV_NO">
                                        {{ inv.INV_DATE }} (缺失記點: {{ inv.Total_Loss_Point }}點, {{ inv.Work_State }})
                                    </option>
                                </select>
                            </div>
                            <div class="col-lg-2 col-md-2 col-12 mb-2 mb-md-0 text-center">
                                <button type="button" class="btn btn-outline-secondary font-weight-bold w-100" style="height: 38px;" v-on:click="swapCompareInvs" title="左右紀錄對調">
                                    <i class="fas fa-exchange-alt mr-1"></i> 左右對調
                                </button>
                            </div>
                            <div class="col-lg-5 col-md-5 col-12">
                                <label class="small font-weight-bold text-muted mb-1 d-flex align-items-center">
                                    <span class="badge badge-secondary mr-1">紀錄 B (對照)</span> 選擇查核時間：
                                </label>
                                <select class="form-control font-weight-bold" style="height: 38px;" v-model="compareInvNoB" v-on:change="fetchCompareData">
                                    <option v-for="inv in drawerInvs" :key="'B_' + inv.INV_NO" :value="inv.INV_NO">
                                        {{ inv.INV_DATE }} (缺失記點: {{ inv.Total_Loss_Point }}點, {{ inv.Work_State }})
                                    </option>
                                </select>
                            </div>
                        </div>

                        <div class="d-flex align-items-center justify-content-between mt-3 pt-2 border-top flex-wrap gap-2">
                            <div class="d-flex align-items-center gap-2">
                                <button type="button" class="btn btn-sm" 
                                        :class="compareOnlyDiff ? 'btn-warning text-dark font-weight-bold' : 'btn-outline-secondary'" 
                                        v-on:click="compareOnlyDiff = !compareOnlyDiff">
                                    <i class="fas fa-filter mr-1"></i>
                                    {{ compareOnlyDiff ? '目前顯示：僅缺失/差異項目' : '過濾：僅看缺失/差異設施' }}
                                </button>
                                <span class="small text-muted" v-if="compareData && compareData.DiffSummary">
                                    已改善: <strong class="text-success">{{ compareData.DiffSummary.ImprovedCount }}</strong> 項 / 
                                    新發生: <strong class="text-danger">{{ compareData.DiffSummary.WorsenedCount }}</strong> 項 / 
                                    未改善: <strong class="text-warning">{{ compareData.DiffSummary.ContinuedCount }}</strong> 項 / 
                                    其他項目差異: <strong class="text-info">{{ compareData.DiffSummary.InfoChangedCount }}</strong> 項
                                </span>
                            </div>
                            <div class="small text-muted">
                                <i class="fas fa-search-plus mr-1 text-primary"></i>點擊任意現場照片可開啟原圖放大檢視
                            </div>
                        </div>
                    </div>

                    <!-- 比對內容 Body -->
                    <div class="modal-body p-3" style="background: #f1f5f9;">
                        <!-- Loading 狀態 -->
                        <div v-if="compareLoading" class="text-center py-5">
                            <div class="spinner-border text-primary" role="status"></div>
                            <div class="mt-2 text-muted font-weight-bold">載入歷程評核與現場照片中...</div>
                        </div>

                        <div v-else-if="compareData">
                            <!-- 1. 查核總覽與缺失分差額指標卡片 -->
                            <div class="card border-0 shadow-sm mb-3" style="border-radius: 8px;">
                                <div class="card-body p-3">
                                    <div class="row align-items-center">
                                        <!-- 左：紀錄 A 摘要 -->
                                        <div class="col-md-5 col-12 text-center text-md-left border-right mb-3 mb-md-0">
                                            <div class="small text-muted font-weight-bold mb-1">
                                                <i class="fas fa-calendar-alt text-primary mr-1"></i> {{ compareData.InvA.InvDate }}
                                            </div>
                                            <div class="d-flex align-items-center justify-content-center justify-content-md-start gap-2">
                                                <span class="badge badge-primary px-2 py-1 font-weight-bold">紀錄 A</span>
                                                <span class="font-weight-bold text-dark">{{ compareData.InvA.WorkState }}</span>
                                                <span class="text-muted small">({{ compareData.InvA.Inspector }})</span>
                                            </div>
                                            <div class="mt-2">
                                                <span class="loss-badge" :class="compareData.InvA.TotalLossPoint > 0 ? 'loss-major' : 'loss-zero'" style="font-size: 1.1rem; padding: 6px 14px;">
                                                    缺失總記點：{{ compareData.InvA.TotalLossPoint }} 點
                                                </span>
                                            </div>
                                        </div>

                                        <!-- 中：差異指標 -->
                                        <div class="col-md-2 col-12 text-center py-2 mb-3 mb-md-0">
                                            <div class="small text-muted font-weight-bold mb-1">缺失增減評估</div>
                                            <div class="font-weight-bold" :class="compareData.DiffSummary.DeltaClass" style="font-size: 1.15rem;">
                                                <i class="fas mr-1" :class="compareData.DiffSummary.DeltaIcon"></i>
                                                {{ compareData.DiffSummary.DeltaText }}
                                            </div>
                                            <div class="text-muted small mt-1">
                                                (A 比 B: {{ compareData.DiffSummary.LossDelta >= 0 ? '+' : '' }}{{ compareData.DiffSummary.LossDelta }} 點)
                                            </div>
                                        </div>

                                        <!-- 右：紀錄 B 摘要 -->
                                        <div class="col-md-5 col-12 text-center text-md-right border-left">
                                            <div class="small text-muted font-weight-bold mb-1">
                                                <i class="fas fa-calendar-alt text-secondary mr-1"></i> {{ compareData.InvB.InvDate }}
                                            </div>
                                            <div class="d-flex align-items-center justify-content-center justify-content-md-end gap-2">
                                                <span class="badge badge-secondary px-2 py-1 font-weight-bold">紀錄 B</span>
                                                <span class="font-weight-bold text-dark">{{ compareData.InvB.WorkState }}</span>
                                                <span class="text-muted small">({{ compareData.InvB.Inspector }})</span>
                                            </div>
                                            <div class="mt-2">
                                                <span class="loss-badge" :class="compareData.InvB.TotalLossPoint > 0 ? 'loss-major' : 'loss-zero'" style="font-size: 1.1rem; padding: 6px 14px;">
                                                    缺失總記點：{{ compareData.InvB.TotalLossPoint }} 點
                                                </span>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- 2. 九大防制設施評核與現場照片雙欄獨立卡片比對 (解決跑版) -->
                            <div v-for="diff in filteredDiffSections" :key="diff.Id" class="compare-sec-card">
                                <!-- 設施標題列 -->
                                <div class="compare-sec-header">
                                    <div class="font-weight-bold text-dark d-flex align-items-center gap-2">
                                        <span class="badge badge-dark px-2 py-1" style="font-size: 0.95rem;">{{ diff.Id }}</span>
                                        <span style="font-size: 1.05rem;">{{ diff.Title }}</span>
                                    </div>
                                    <div>
                                        <span class="badge font-weight-bold px-3 py-1" style="font-size: 0.85rem;" :class="diff.DiffClass">
                                            {{ diff.DiffBadge }}
                                        </span>
                                    </div>
                                </div>

                                <!-- 雙欄排版 (左紀錄 A / 右紀錄 B) -->
                                <div class="compare-sec-body">
                                    <div class="row">
                                        <!-- 左欄：紀錄 A 獨立卡片 -->
                                        <div class="col-12 col-lg-6 mb-3 mb-lg-0">
                                            <div class="record-box record-box-a">
                                                <div class="record-box-header d-flex align-items-center justify-content-between">
                                                    <div class="d-flex align-items-center text-truncate mr-2">
                                                        <span class="badge badge-primary mr-2 flex-shrink-0 font-weight-bold">紀錄 A (基準)</span>
                                                        <span class="font-weight-bold text-dark text-truncate">{{ compareData.InvA.InvDate }}</span>
                                                    </div>
                                                    <span v-if="!diff.SectionA.IsInfo" class="badge font-weight-bold flex-shrink-0 px-2 py-1" :class="diff.SectionA.LossPoint > 0 ? 'badge-danger' : 'badge-success'">
                                                        {{ diff.SectionA.LossPoint > 0 ? '記 ' + diff.SectionA.LossPoint + ' 點' : '0 點 (合格)' }}
                                                    </span>
                                                </div>

                                                <div class="record-box-body">
                                                    <!-- 評核狀態判定 -->
                                                    <div v-if="diff.SectionA.IsInfo" class="mb-3">
                                                        <div class="small font-weight-bold text-muted mb-1">填報內容：</div>
                                                        <div v-if="diff.SectionA.Details && diff.SectionA.Details.length > 0" class="info-detail-box">
                                                            <div v-for="(d, dIdx) in diff.SectionA.Details" :key="'dA_' + dIdx" class="info-detail-row">
                                                                <span class="info-detail-label">{{ d.Label }}</span>
                                                                <span class="info-detail-value">{{ d.Value }}</span>
                                                            </div>
                                                        </div>
                                                        <div v-else class="small text-muted font-italic">本項無文字填報內容</div>
                                                    </div>
                                                    <div class="mb-3" v-if="!diff.SectionA.IsInfo">
                                                        <div class="small font-weight-bold text-muted mb-1">查核結果判定：</div>
                                                        <div v-if="diff.SectionA.Violations && diff.SectionA.Violations.length > 0">
                                                            <div v-for="(v, vIdx) in diff.SectionA.Violations" :key="'vA_' + vIdx" class="item-violation-box mb-1">
                                                                <i class="fas fa-times-circle text-danger mr-1"></i>
                                                                <span class="font-weight-bold text-danger">{{ v }}</span>
                                                            </div>
                                                        </div>
                                                        <div v-else class="item-compliant-box">
                                                            <i class="fas fa-check-circle text-success mr-1"></i>
                                                            <span class="font-weight-bold text-success">全項符合防制規範</span>
                                                        </div>
                                                    </div>

                                                    <!-- 現場照片 -->
                                                    <div class="border-top pt-2">
                                                        <div class="d-flex align-items-center justify-content-between mb-2">
                                                            <span class="small font-weight-bold text-muted"><i class="fas fa-camera text-primary mr-1"></i>現場拍攝照片：</span>
                                                            <span class="badge badge-light border text-muted" v-if="diff.SectionA.Photos && diff.SectionA.Photos.length > 0">共 {{ diff.SectionA.Photos.length }} 張</span>
                                                        </div>
                                                        <div v-if="diff.SectionA.Photos && diff.SectionA.Photos.length > 0" class="compare-photo-grid">
                                                            <div v-for="p in diff.SectionA.Photos" :key="'pA_' + p.Key" class="compare-photo-card" v-on:click="openCompareLightbox(p.Url, p.Label, p.Memo)">
                                                                <div class="photo-img-wrapper">
                                                                    <img v-if="p.Url" :src="p.Url" class="compare-photo-thumb" :alt="p.Label" />
                                                                    <div v-else class="photo-placeholder"><i class="far fa-image mr-1"></i>無照片</div>
                                                                </div>
                                                                <div class="compare-photo-label" :title="p.Label">{{ p.Label }}</div>
                                                                <div v-if="p.Memo" class="compare-photo-memo" :title="p.Memo">{{ p.Memo }}</div>
                                                            </div>
                                                        </div>
                                                        <div v-else class="photo-empty-state">
                                                            <i class="far fa-image fa-lg text-muted mb-1 d-block"></i>
                                                            <span>本次巡查未拍攝本項照片</span>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>

                                        <!-- 右欄：紀錄 B 獨立卡片 -->
                                        <div class="col-12 col-lg-6">
                                            <div class="record-box record-box-b">
                                                <div class="record-box-header d-flex align-items-center justify-content-between">
                                                    <div class="d-flex align-items-center text-truncate mr-2">
                                                        <span class="badge badge-secondary mr-2 flex-shrink-0 font-weight-bold">紀錄 B (對照)</span>
                                                        <span class="font-weight-bold text-dark text-truncate">{{ compareData.InvB.InvDate }}</span>
                                                    </div>
                                                    <span v-if="!diff.SectionB.IsInfo" class="badge font-weight-bold flex-shrink-0 px-2 py-1" :class="diff.SectionB.LossPoint > 0 ? 'badge-danger' : 'badge-success'">
                                                        {{ diff.SectionB.LossPoint > 0 ? '記 ' + diff.SectionB.LossPoint + ' 點' : '0 點 (合格)' }}
                                                    </span>
                                                </div>

                                                <div class="record-box-body">
                                                    <!-- 評核狀態判定 -->
                                                    <div v-if="diff.SectionB.IsInfo" class="mb-3">
                                                        <div class="small font-weight-bold text-muted mb-1">填報內容：</div>
                                                        <div v-if="diff.SectionB.Details && diff.SectionB.Details.length > 0" class="info-detail-box">
                                                            <div v-for="(d, dIdx) in diff.SectionB.Details" :key="'dB_' + dIdx" class="info-detail-row">
                                                                <span class="info-detail-label">{{ d.Label }}</span>
                                                                <span class="info-detail-value">{{ d.Value }}</span>
                                                            </div>
                                                        </div>
                                                        <div v-else class="small text-muted font-italic">本項無文字填報內容</div>
                                                    </div>
                                                    <div class="mb-3" v-if="!diff.SectionB.IsInfo">
                                                        <div class="small font-weight-bold text-muted mb-1">查核結果判定：</div>
                                                        <div v-if="diff.SectionB.Violations && diff.SectionB.Violations.length > 0">
                                                            <div v-for="(v, vIdx) in diff.SectionB.Violations" :key="'vB_' + vIdx" class="item-violation-box mb-1">
                                                                <i class="fas fa-times-circle text-danger mr-1"></i>
                                                                <span class="font-weight-bold text-danger">{{ v }}</span>
                                                            </div>
                                                        </div>
                                                        <div v-else class="item-compliant-box">
                                                            <i class="fas fa-check-circle text-success mr-1"></i>
                                                            <span class="font-weight-bold text-success">全項符合防制規範</span>
                                                        </div>
                                                    </div>

                                                    <!-- 現場照片 -->
                                                    <div class="border-top pt-2">
                                                        <div class="d-flex align-items-center justify-content-between mb-2">
                                                            <span class="small font-weight-bold text-muted"><i class="fas fa-camera text-secondary mr-1"></i>現場拍攝照片：</span>
                                                            <span class="badge badge-light border text-muted" v-if="diff.SectionB.Photos && diff.SectionB.Photos.length > 0">共 {{ diff.SectionB.Photos.length }} 張</span>
                                                        </div>
                                                        <div v-if="diff.SectionB.Photos && diff.SectionB.Photos.length > 0" class="compare-photo-grid">
                                                            <div v-for="p in diff.SectionB.Photos" :key="'pB_' + p.Key" class="compare-photo-card" v-on:click="openCompareLightbox(p.Url, p.Label, p.Memo)">
                                                                <div class="photo-img-wrapper">
                                                                    <img v-if="p.Url" :src="p.Url" class="compare-photo-thumb" :alt="p.Label" />
                                                                    <div v-else class="photo-placeholder"><i class="far fa-image mr-1"></i>無照片</div>
                                                                </div>
                                                                <div class="compare-photo-label" :title="p.Label">{{ p.Label }}</div>
                                                                <div v-if="p.Memo" class="compare-photo-memo" :title="p.Memo">{{ p.Memo }}</div>
                                                            </div>
                                                        </div>
                                                        <div v-else class="photo-empty-state">
                                                            <i class="far fa-image fa-lg text-muted mb-1 d-block"></i>
                                                            <span>本次巡查未拍攝本項照片</span>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div v-if="filteredDiffSections.length === 0" class="card p-5 text-center text-muted">
                                <i class="fas fa-check-double fa-3x text-success mb-3"></i>
                                <h6 class="font-weight-bold text-dark">兩次查核無任何差異或缺失項目</h6>
                                <p class="small text-muted m-0">所有防制設施皆正常合規，可點擊上方切換為檢視全部設施。</p>
                            </div>
                        </div>
                    </div>

                    <!-- 底部按鈕 -->
                    <div class="modal-footer bg-white py-2">
                        <button type="button" class="btn btn-secondary font-weight-bold px-4" v-on:click="isCompareModalOpen = false">關閉比對視窗</button>
                    </div>
                </div>
            </div>
        </div>
        <!-- 8. 比對現場照片放大檢視 (Lightbox Modal) -->
        <div v-if="compareLightboxPhoto" class="modal fade show d-block" tabindex="-1" style="background: rgba(0,0,0,0.85); z-index: 1070;" v-on:click="compareLightboxPhoto = null">
            <div class="modal-dialog modal-dialog-centered modal-lg" v-on:click.stop>
                <div class="modal-content border-0 bg-transparent text-white">
                    <div class="d-flex justify-content-between align-items-center p-2">
                        <span class="font-weight-bold" style="font-size: 1.1rem;">{{ compareLightboxPhoto.label }}</span>
                        <button type="button" class="close text-white" style="font-size: 2rem;" v-on:click="compareLightboxPhoto = null">&times;</button>
                    </div>
                    <div class="modal-body p-0 text-center">
                        <img :src="compareLightboxPhoto.url" class="img-fluid rounded shadow-lg" style="max-height: 75vh;" :alt="compareLightboxPhoto.label" />
                        <div v-if="compareLightboxPhoto.memo" class="bg-dark text-white p-2 mt-2 rounded small text-left">
                            <i class="fas fa-comment-dots text-warning mr-1"></i><strong>照片備註：</strong>{{ compareLightboxPhoto.memo }}
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- 6. 移除派遣任務對話框 (Modal) -->
        <div v-if="isCancelModalOpen" class="modal fade show d-block" tabindex="-1" style="background: rgba(0,0,0,0.5);">
            <div class="modal-dialog modal-dialog-centered">
                <div class="modal-content border-0 shadow">
                    <div class="modal-header bg-danger text-white">
                        <h5 class="modal-title font-weight-bold">
                            <i class="fas fa-exclamation-triangle mr-2"></i>移除派遣案件設定
                        </h5>
                        <button type="button" class="close text-white" v-on:click="isCancelModalOpen = false">&times;</button>
                    </div>
                    <div class="modal-body">
                        <p class="mb-2"><strong>場所名稱：</strong>{{ cancelTargetFac.FAC_NAME }}</p>
                        <p class="text-muted small mb-3">移除派遣後，該場所將不再出現在待派遣或列管督導清單中。</p>
                        <label class="font-weight-bold small text-muted">請輸入移除原因：</label>
                        <textarea class="form-control" rows="3" v-model="cancelReasonInput" placeholder="請詳述移除派遣之原因..."></textarea>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary btn-sm" v-on:click="isCancelModalOpen = false">取消</button>
                        <button type="button" class="btn btn-danger btn-sm font-weight-bold" v-on:click="confirmCancelMission">
                            確定移除
                        </button>
                    </div>
                </div>
            </div>
        </div>

        <!-- 7. 商工登記查詢彈窗 (Modal) -->
        <div v-if="isGcModalOpen" class="modal fade show d-block" tabindex="-1" style="background: rgba(0,0,0,0.5);">
            <div class="modal-dialog modal-dialog-centered">
                <div class="modal-content border-0 shadow">
                    <div class="modal-header bg-dark text-white">
                        <h5 class="modal-title font-weight-bold">
                            <i class="fas fa-landmark mr-2"></i>經濟部商工登記資料
                        </h5>
                        <button type="button" class="close text-white" v-on:click="isGcModalOpen = false">&times;</button>
                    </div>
                    <div class="modal-body">
                        <div v-if="gcLoading" class="text-center py-4">
                            <div class="spinner-border text-primary"></div>
                            <div class="mt-2 text-muted small">查詢經濟部商業司資料中...</div>
                        </div>
                        <div v-else-if="!gcData" class="text-center py-4 text-muted">
                            查無此統一編號之商工登記資料。
                        </div>
                        <table v-else class="table table-bordered table-sm mb-0">
                            <tr>
                                <th class="bg-light" style="width: 35%;">統一編號</th>
                                <td>{{ gcData.Business_Accounting_NO || currentScId }}</td>
                            </tr>
                            <tr>
                                <th class="bg-light">公司行號名稱</th>
                                <td class="font-weight-bold text-primary">{{ gcData.Company_Name }}</td>
                            </tr>
                            <tr>
                                <th class="bg-light">公司狀態</th>
                                <td><span class="badge badge-info">{{ gcData.Company_Status_Desc }}</span></td>
                            </tr>
                            <tr>
                                <th class="bg-light">負責人姓名</th>
                                <td>{{ gcData.Responsible_Name }}</td>
                            </tr>
                            <tr>
                                <th class="bg-light">公司登記地址</th>
                                <td>{{ gcData.Company_Location }}</td>
                            </tr>
                        </table>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary btn-sm" v-on:click="isGcModalOpen = false">關閉</button>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- 本地端核心前端腳本 (依 GEMINI.md 避開外部 CDN) -->
    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>
    <script src="../Scripts/jquery-3.6.4.min.js"></script>
    <script src="../Scripts/bootstrap.bundle.min.js"></script>
    <script src="../Scripts/leaflet/leaflet.js"></script>

    <script>
        const { createApp } = Vue;

        createApp({
            data() {
                return {
                    currentUser: '<%= User != null && User.Identity != null ? User.Identity.Name : "系統使用者" %>',
                    filter: {
                        Mode: 'all',
                        FacName: '',
                        CNo: '',
                        ScId: '',
                        Towns: [],
                        SortBy: 'loss_desc'
                    },
                    counts: {
                        Draft: 0,
                        Back: 0,
                        Mission7Day: 0,
                        Mission2Times: 0,
                        Project: 0,
                        InvMonth: 0,
                        Total: 0
                    },
                    townList: [],
                    items: [],
                    totalCount: 0,
                    pageIndex: 1,
                    pageSize: 15,
                    loading: false,
                    exporting: false,
                    isMapCollapsed: false,
                    mapMarkerCount: 0,
                    gpsDistanceMessage: '',

                    // 抽屜面板控制
                    isDrawerOpen: false,
                    drawerWidth: 1080,
                    drawerWidthMode: 'wide',
                    isResizingDrawer: false,
                    drawerTab: 'invs',
                    activeFac: {},
                    activeFacInfo: {},
                    drawerInvs: [],
                    drawerDiagrams: [],

                    // 移除派遣
                    isCancelModalOpen: false,
                    cancelTargetFac: {},
                    cancelReasonInput: '',

                    // 商工登記
                    isGcModalOpen: false,
                    gcLoading: false,
                    currentScId: '',
                    gcData: null,

                    // 歷程比對控制狀態
                    selectedCompareInvNos: [],
                    isCompareModalOpen: false,
                    compareLoading: false,
                    compareData: null,
                    compareInvNoA: null,
                    compareInvNoB: null,
                    compareOnlyDiff: false,
                    compareLightboxPhoto: null
                };
            },
            computed: {
                drawerWidthLabel: function () {
                    if (this.drawerWidthMode === 'full') return '標準版';
                    if (this.drawerWidthMode === 'wide') return '全螢幕';
                    return '寬版';
                },
                getDrawerWidthModeIcon: function () {
                    if (this.drawerWidthMode === 'full') return 'fa-compress-arrows-alt';
                    if (this.drawerWidthMode === 'wide') return 'fa-expand';
                    return 'fa-expand-arrows-alt';
                },
                getDrawerWidthModeTitle: function () {
                    if (this.drawerWidthMode === 'full') return '切換為標準寬度 (880px)';
                    if (this.drawerWidthMode === 'wide') return '切換為全螢幕模式 (96vw)';
                    return '切換為寬版模式 (1180px)';
                },
                totalPages() {
                    return Math.ceil(this.totalCount / this.pageSize) || 1;
                },
                filteredDiffSections() {
                    if (!this.compareData || !this.compareData.DiffSections) return [];
                    if (!this.compareOnlyDiff) return this.compareData.DiffSections;
                    return this.compareData.DiffSections.filter(d => d.HasDifference);
                },
                visiblePages() {
                    const pages = [];
                    const start = Math.max(1, this.pageIndex - 2);
                    const end = Math.min(this.totalPages, start + 4);
                    for (let p = start; p <= end; p++) {
                        pages.push(p);
                    }
                    return pages;
                }
            },
            created() {
                // 由 URL 解析預設 mode
                const params = new URLSearchParams(window.location.search);
                const modeParam = params.get('mode');
                if (modeParam) {
                    this.filter.Mode = modeParam.toLowerCase();
                }
                // 若帶入特定 facId 亦可自動展開
                this.defFacId = params.get('id');
            },
            mounted() {
                // 讀取抽屜寬度喜好
                try {
                    var savedWidth = localStorage.getItem('fec_drawer_width');
                    if (savedWidth) {
                        var parsedW = parseInt(savedWidth, 10);
                        if (parsedW >= 540 && parsedW <= window.innerWidth * 0.96) {
                            this.drawerWidth = parsedW;
                        }
                    }
                    var savedMode = localStorage.getItem('fec_drawer_width_mode');
                    if (savedMode) {
                        this.drawerWidthMode = savedMode;
                    }
                } catch (e) {}

                this.initMap();
                this.loadTowns();
                this.loadCounts();
                this.loadData(1);
                this.$nextTick(function () {
                    setTimeout(function () {
                        if (this.leafletMap) {
                            this.leafletMap.invalidateSize();
                        }
                    }.bind(this), 300);
                });
            },
            watch: {
                isMapCollapsed: function () {
                    setTimeout(function () {
                        if (this.leafletMap) {
                            this.leafletMap.invalidateSize();
                        }
                    }.bind(this), 350);
                }
            },
            methods: {
                // 1. 初始化 Leaflet 地圖 (遵循 inspection-ui-standard 物件隔離)
                initMap() {
                    const defaultCenter = [25.012, 121.465]; // 新北市板橋
                    this.leafletMap = L.map('caseMap', {
                        center: defaultCenter,
                        zoom: 12,
                        zoomControl: true
                    });

                    L.tileLayer('https://wmts.nlsc.gov.tw/wmts/EMAP/default/GoogleMapsCompatible/{z}/{y}/{x}', {
                        maxZoom: 19,
                        attribution: '臺灣通用電子地圖 &copy; 國土測繪中心'
                    }).addTo(this.leafletMap);

                    this.markersGroup = L.layerGroup().addTo(this.leafletMap);
                },

                // 2. 載入行政區選單
                async loadTowns() {
                    try {
                        const res = await axios.get('CaseList.aspx?action=gettowns');
                        if (res.data && res.data.Success) {
                            this.townList = res.data.Towns || [];
                        }
                    } catch (e) {
                        console.error('載入行政區失敗', e);
                    }
                },

                // 3. 載入 KPI 統計數字
                async loadCounts() {
                    try {
                        const res = await axios.get('CaseList.aspx?action=getcounts');
                        if (res.data && res.data.Success) {
                            this.counts = res.data.Counts;
                        }
                    } catch (e) {
                        console.error('載入統計指標失敗', e);
                    }
                },

                // 4. 切換業務模式
                setMode(m) {
                    this.filter.Mode = m;
                    this.gpsDistanceMessage = '';
                    this.loadData(1);
                },

                // 5. 載入場所清單
                async loadData(page = 1) {
                    this.pageIndex = page;
                    this.loading = true;
                    try {
                        const payload = {
                            Mode: this.filter.Mode,
                            FacName: this.filter.FacName,
                            CNo: this.filter.CNo,
                            ScId: this.filter.ScId,
                            Towns: this.filter.Towns,
                            SortBy: this.filter.SortBy,
                            PageIndex: this.pageIndex,
                            PageSize: this.pageSize
                        };
                        const res = await axios.post('CaseList.aspx?action=getlist', payload);
                        if (res.data && res.data.Success) {
                            this.items = res.data.Items || [];
                            this.totalCount = res.data.Total || 0;
                            this.updateMapMarkers();

                            if (this.defFacId) {
                                const target = this.items.find(x => x.FAC_ID === this.defFacId);
                                if (target) {
                                    this.openFacDrawer(target);
                                }
                                this.defFacId = null;
                            }
                        } else {
                            alert(res.data.Message || '讀取清單失敗');
                        }
                    } catch (e) {
                        console.error('讀取清單失敗', e);
                    } finally {
                        this.loading = false;
                    }
                },

                // 6. 更新地圖點位
                updateMapMarkers() {
                    if (!this.leafletMap || !this.markersGroup) return;
                    this.markersGroup.clearLayers();

                    const validPoints = [];
                    this.items.forEach(item => {
                        if (item.Lat && item.Lng && item.Lat > 0 && item.Lng > 0) {
                            let pinClass = 'pin-zero';
                            if (item.Loss_Point >= 10) pinClass = 'pin-major';
                            else if (item.Loss_Point > 0) pinClass = 'pin-minor';

                            const customIcon = L.divIcon({
                                className: 'custom-fac-marker',
                                html: `<div class="fac-marker-pin ${pinClass}"><span class="fac-marker-num">${item.Loss_Point}</span></div>`,
                                iconSize: [32, 32],
                                iconAnchor: [16, 32],
                                popupAnchor: [0, -28]
                            });

                            const marker = L.marker([item.Lat, item.Lng], { icon: customIcon });
                            const popupHtml = `
                                <div style="min-width:200px;">
                                    <div class="font-weight-bold" style="color:#0f172a; font-size:14px;">${item.FAC_NAME}</div>
                                    <div class="small text-muted mt-1">管編：${item.C_NO || '-'} | 行政區：${item.TOWN || '-'}</div>
                                    <div class="small mt-1">缺失記點：<span class="badge ${item.Loss_Point > 0 ? 'badge-danger' : 'badge-success'}">${item.Loss_Point} 點</span></div>
                                    ${item.Mission ? `<div class="mission-tag mt-1">${item.Mission}</div>` : ''}
                                    <div class="mt-2 pt-2 border-top d-flex gap-1">
                                        <button class="btn btn-sm btn-info py-0 px-2" style="font-size:11px;" onclick="window.caseAppHelper.openDrawer('${item.FAC_ID}')">查看歷程</button>
                                        <button class="btn btn-sm btn-warning py-0 px-2" style="font-size:11px;" onclick="window.caseAppHelper.navNewCase('${item.FAC_ID}')">新增查核</button>
                                    </div>
                                </div>
                            `;
                            marker.bindPopup(popupHtml);
                            this.markersGroup.addLayer(marker);
                            validPoints.push([item.Lat, item.Lng]);
                        }
                    });

                    this.mapMarkerCount = validPoints.length;
                    if (validPoints.length > 0) {
                        const bounds = L.latLngBounds(validPoints);
                        this.leafletMap.fitBounds(bounds, { padding: [30, 30], maxZoom: 15 });
                    }
                },

                // 7. 外勤 GPS 我的位置
                locateMyGps() {
                    if (!("geolocation" in navigator)) {
                        alert("此裝置或瀏覽器不支援 GPS 定位");
                        return;
                    }
                    navigator.geolocation.getCurrentPosition(pos => {
                        const lat = pos.coords.latitude;
                        const lng = pos.coords.longitude;
                        if (this.myGpsMarker) {
                            this.leafletMap.removeLayer(this.myGpsMarker);
                        }
                        this.myGpsMarker = L.circleMarker([lat, lng], {
                            radius: 9,
                            color: '#ffffff',
                            fillColor: '#0099e5',
                            fillOpacity: 1,
                            weight: 3
                        }).addTo(this.leafletMap);
                        this.myGpsMarker.bindPopup("<strong>目前 GPS 位置</strong>").openPopup();
                        this.leafletMap.setView([lat, lng], 15);
                    }, err => {
                        alert("GPS 定位失敗：" + err.message);
                    }, { enableHighAccuracy: true });
                },

                // 8. 重設地圖全景
                resetMapView() {
                    if (!this.leafletMap) return;
                    this.leafletMap.setView([25.012, 121.465], 12);
                },

                // 9. 外勤 GPS 環域搜尋 (半徑 3 公里內場所)
                searchNearbyGps() {
                    if (!("geolocation" in navigator)) {
                        alert("此裝置或瀏覽器不支援 GPS 定位");
                        return;
                    }
                    this.loading = true;
                    navigator.geolocation.getCurrentPosition(async pos => {
                        const lat = pos.coords.latitude;
                        const lng = pos.coords.longitude;
                        try {
                            const res = await axios.post('CaseList.aspx?action=getnearby', {
                                Lat: lat,
                                Lng: lng,
                                RadiusMeters: 3000
                            });
                            if (res.data && res.data.Success) {
                                this.items = res.data.Items || [];
                                this.totalCount = this.items.length;
                                this.gpsDistanceMessage = `已定位所在座標 (${lat.toFixed(4)}, ${lng.toFixed(4)})，篩選 3 公里內場所共 ${this.items.length} 家`;
                                this.updateMapMarkers();
                            } else {
                                alert(res.data.Message || '周邊搜尋失敗');
                            }
                        } catch (e) {
                            alert('周邊搜尋發生異常');
                        } finally {
                            this.loading = false;
                        }
                    }, err => {
                        this.loading = false;
                        alert("GPS 定位取得失敗：" + err.message);
                    }, { enableHighAccuracy: true });
                },

                // 10. 平移地圖至指定點位
                panToMap(lat, lng, item) {
                    if (!this.leafletMap) return;
                    this.leafletMap.setView([lat, lng], 16);
                    if (this.isMapCollapsed) {
                        this.isMapCollapsed = false;
                    }
                    // 觸發高亮提示
                    window.scrollTo({ top: 180, behavior: 'smooth' });
                },

                // 11. 行政區選擇輔助
                toggleTown(tName) {
                    const idx = this.filter.Towns.indexOf(tName);
                    if (idx >= 0) {
                        this.filter.Towns.splice(idx, 1);
                    } else {
                        this.filter.Towns.push(tName);
                    }
                },
                selectAllTowns() {
                    this.filter.Towns = this.townList.map(t => t.TOWN_NA);
                },
                clearAllTowns() {
                    this.filter.Towns = [];
                },
                resetFilter() {
                    this.filter.FacName = '';
                    this.filter.CNo = '';
                    this.filter.ScId = '';
                    this.filter.Towns = [];
                    this.filter.SortBy = 'loss_desc';
                    this.loadData(1);
                },

                // 12. 開啟場所抽屜面板 (歷次查核與基本資料)
                async openFacDrawer(fac) {
                    this.activeFac = fac;
                    this.isDrawerOpen = true;
                    this.drawerTab = 'invs';
                    try {
                        const res = await axios.get('CaseList.aspx?action=getfachistory&facId=' + fac.FAC_ID);
                        if (res.data && res.data.Success) {
                            this.activeFacInfo = res.data.FacInfo || {};
                            this.drawerInvs = res.data.Invs || [];
                            this.drawerDiagrams = res.data.Diagrams || [];
                        } else {
                            alert(res.data.Message || '讀取場所歷程失敗');
                        }
                    } catch (e) {
                        console.error('讀取場所歷程失敗', e);
                    }
                },
                closeFacDrawer() {
                    this.isDrawerOpen = false;
                },

                // 抽屜尺寸模式切換
                toggleDrawerWidthMode() {
                    if (this.drawerWidthMode === 'default') {
                        this.drawerWidthMode = 'wide';
                        this.drawerWidth = Math.min(1180, Math.floor(window.innerWidth * 0.92));
                    } else if (this.drawerWidthMode === 'wide') {
                        this.drawerWidthMode = 'full';
                        this.drawerWidth = Math.floor(window.innerWidth * 0.96);
                    } else {
                        this.drawerWidthMode = 'default';
                        this.drawerWidth = 880;
                    }
                    try {
                        localStorage.setItem('fec_drawer_width_mode', this.drawerWidthMode);
                        localStorage.setItem('fec_drawer_width', this.drawerWidth.toString());
                    } catch (e) {}
                },

                // 抽屜滑鼠拖曳調整寬度
                startDrawerResize(e) {
                    this.isResizingDrawer = true;
                    var self = this;
                    var startX = e.clientX;
                    var startWidth = self.drawerWidth;

                    var onMouseMove = function (moveEvent) {
                        if (!self.isResizingDrawer) return;
                        var deltaX = startX - moveEvent.clientX;
                        var newWidth = startWidth + deltaX;
                        var minW = 540;
                        var maxW = Math.floor(window.innerWidth * 0.96);
                        if (newWidth < minW) newWidth = minW;
                        if (newWidth > maxW) newWidth = maxW;
                        self.drawerWidth = newWidth;
                    };

                    var onMouseUp = function () {
                        if (self.isResizingDrawer) {
                            self.isResizingDrawer = false;
                            document.removeEventListener('mousemove', onMouseMove);
                            document.removeEventListener('mouseup', onMouseUp);
                            try {
                                localStorage.setItem('fec_drawer_width', self.drawerWidth.toString());
                            } catch (err) {}
                        }
                    };

                    document.addEventListener('mousemove', onMouseMove);
                    document.addEventListener('mouseup', onMouseUp);
                    e.preventDefault();
                },

                // 解析缺失內容為陣列項目
                parseLossDetails(lossDetailStr) {
                    if (!lossDetailStr) return [];
                    var items = lossDetailStr.split('；');
                    var result = [];
                    for (var i = 0; i < items.length; i++) {
                        var s = items[i].trim();
                        if (s.length > 0 && s !== '無缺失') {
                            result.push(s);
                        }
                    }
                    return result;
                },

                // 13. 儲存場所基本資料維護
                async saveFacEditInfo() {
                    try {
                        const payload = {
                            FacId: this.activeFac.FAC_ID,
                            FacName: this.activeFacInfo.FAC_NAME,
                            CNo: this.activeFacInfo.C_NO,
                            Addr: this.activeFacInfo.ADDR,
                            LandNo: this.activeFacInfo.Land_no,
                            Fax: this.activeFacInfo.FAX,
                            Tel: this.activeFacInfo.TEL,
                            ScId: this.activeFacInfo.S_C_ID,
                            LicNo: this.activeFacInfo.Lic_NO,
                            BossName: this.activeFacInfo.BOSS_NAME,
                            ContentName: this.activeFacInfo.Content_Name
                        };
                        const res = await axios.post('CaseList.aspx?action=savefacedit', payload);
                        if (res.data && res.data.Success) {
                            alert(res.data.Message);
                            this.loadData(this.pageIndex);
                        } else {
                            alert(res.data.Message || '儲存失敗');
                        }
                    } catch (e) {
                        alert('儲存發生異常');
                    }
                },

                // 14. 查核狀態徽章樣式
                getInvStateBadgeClass(state) {
                    switch (state) {
                        case 'A00a': return 'badge-danger';
                        case 'A00b': return 'badge-warning';
                        case 'A00': return 'badge-info';
                        case 'INV1': return 'badge-primary';
                        case 'INV2': return 'badge-secondary';
                        case 'INV3': return 'badge-dark';
                        case 'A03': return 'badge-success';
                        default: return 'badge-light border';
                    }
                },

                // 15. 送出審核 (UploadCheck)
                async submitUploadCheck(invNo, invDate) {
                    if (!confirm(`是否確定將此筆資料送出審核？\n巡查時間：${invDate}`)) return;
                    try {
                        const res = await axios.get(`CaseList.aspx?action=uploadcheck&facId=${this.activeFac.FAC_ID}&invNo=${invNo}`);
                        if (res.data && res.data.Success) {
                            alert(res.data.Message);
                            this.openFacDrawer(this.activeFac);
                            this.loadCounts();
                            this.loadData(this.pageIndex);
                        } else {
                            alert(res.data.Message || '送出失敗');
                        }
                    } catch (e) {
                        alert('送審異常');
                    }
                },

                // 16. 刪除查核紀錄 (DelInv)
                async deleteInvRecord(invNo, invDate) {
                    if (!confirm(`是否確定刪除此筆查核紀錄？\n巡查時間：${invDate}`)) return;
                    try {
                        const res = await axios.get(`CaseList.aspx?action=delinv&facId=${this.activeFac.FAC_ID}&invNo=${invNo}`);
                        if (res.data && res.data.Success) {
                            alert(res.data.Message);
                            this.openFacDrawer(this.activeFac);
                            this.loadCounts();
                            this.loadData(this.pageIndex);
                        } else {
                            alert(res.data.Message || '刪除失敗');
                        }
                    } catch (e) {
                        alert('刪除異常');
                    }
                },

                // 17. 移除派遣對話框控制
                openCancelMissionModal(fac) {
                    this.cancelTargetFac = fac;
                    this.cancelReasonInput = '';
                    this.isCancelModalOpen = true;
                },
                async confirmCancelMission() {
                    if (!this.cancelReasonInput.trim()) {
                        alert('請輸入移除派遣原因！');
                        return;
                    }
                    try {
                        const payload = {
                            FacId: this.cancelTargetFac.FAC_ID,
                            FinishInvNo: this.cancelTargetFac.Last_INV_NO || 0,
                            CancelReason: this.cancelReasonInput.trim()
                        };
                        const res = await axios.post('CaseList.aspx?action=cancelmission', payload);
                        if (res.data && res.data.Success) {
                            alert(res.data.Message);
                            this.isCancelModalOpen = false;
                            this.loadCounts();
                            this.loadData(this.pageIndex);
                        } else {
                            alert(res.data.Message || '移除派遣失敗');
                        }
                    } catch (e) {
                        alert('移除派遣發生異常');
                    }
                },

                // 18. 商工登記 Modal 控制 (GCIS API)
                async openGcModal(scId) {
                    if (!scId || scId === '-') {
                        alert('該場所無有效統一編號');
                        return;
                    }
                    this.currentScId = scId;
                    this.isGcModalOpen = true;
                    this.gcLoading = true;
                    this.gcData = null;
                    try {
                        const url = `https://data.gcis.nat.gov.tw/od/data/api/5F64D864-61CB-4D0D-8AD9-492047CC1EA6?$format=json&$filter=Business_Accounting_NO eq ${scId}`;
                        const res = await axios.get(url);
                        if (res.data && Array.isArray(res.data) && res.data.length > 0) {
                            this.gcData = res.data[0];
                        }
                    } catch (e) {
                        console.warn('商工登記 API 查詢失敗', e);
                    } finally {
                        this.gcLoading = false;
                    }
                },

                // 19. 導航至 NewCase.aspx / CaseResult.aspx
                async navigateNewCase(fac, isRe) {
                    try {
                        const res = await axios.get('CaseList.aspx?action=gettoken&facId=' + fac.FAC_ID);
                        const token = (res.data && res.data.Token) ? res.data.Token : fac.Md5Token;
                        const mode = isRe ? 'new_re' : 'new';
                        window.location.href = `NewCase.aspx?mode=${mode}&id=${fac.FAC_ID}&id1=${token}`;
                    } catch (e) {
                        window.location.href = `NewCase.aspx?mode=new&id=${fac.FAC_ID}&id1=${fac.Md5Token}`;
                    }
                },
                async navigateEditCase(invNo) {
                    const facId = this.activeFac.FAC_ID;
                    try {
                        const res = await axios.get('CaseList.aspx?action=gettoken&facId=' + facId);
                        const token = (res.data && res.data.Token) ? res.data.Token : '';
                        window.location.href = `NewCase.aspx?mode=edit&id=${facId}&id1=${token}&id2=${invNo}`;
                    } catch (e) {
                        window.location.href = `NewCase.aspx?mode=edit&id=${facId}&id2=${invNo}`;
                    }
                },
                async navigateResultCase(invNo, isRead) {
                    const facId = this.activeFac.FAC_ID;
                    try {
                        const res = await axios.get('CaseList.aspx?action=gettoken&facId=' + facId);
                        const token = (res.data && res.data.Token) ? res.data.Token : '';
                        const readParam = isRead ? '&mode=read' : '';
                        window.location.href = `CaseResult.aspx?id=${facId}&id1=${token}&id2=${invNo}${readParam}`;
                    } catch (e) {
                        window.location.href = `CaseResult.aspx?id=${facId}&id2=${invNo}`;
                    }
                },
                onPromptNewCase() {
                    alert('公私場所防制設施查核需指定受檢場所，請先由下方清單或搜尋欄查詢選定場所，並點選該場所右側之「查核」按鈕進入填報！');
                    this.filterCollapsed = false;
                    this.$nextTick(() => {
                        const input = document.getElementById('searchFacNameInput');
                        if (input) input.focus();
                    });
                },

                // 21. 歷程比對相關方法
                onCompareCheckboxChange(invNo) {
                    if (!this.selectedCompareInvNos) this.selectedCompareInvNos = [];
                    if (this.selectedCompareInvNos.length > 2) {
                        this.selectedCompareInvNos = this.selectedCompareInvNos.slice(-2);
                    }
                },
                openCompareModalByDefault() {
                    if (!this.drawerInvs || this.drawerInvs.length < 2) {
                        alert('該場所查核紀錄不足 2 筆，無法進行歷程比對！');
                        return;
                    }
                    if (this.selectedCompareInvNos && this.selectedCompareInvNos.length === 2) {
                        this.compareInvNoA = this.selectedCompareInvNos[0];
                        this.compareInvNoB = this.selectedCompareInvNos[1];
                    } else {
                        this.compareInvNoA = this.drawerInvs[0].INV_NO;
                        this.compareInvNoB = this.drawerInvs[1].INV_NO;
                    }
                    this.isCompareModalOpen = true;
                    this.fetchCompareData();
                },
                startCompareSelected() {
                    if (!this.selectedCompareInvNos || this.selectedCompareInvNos.length !== 2) {
                        alert('請勾選任 2 筆紀錄進行比對！');
                        return;
                    }
                    this.compareInvNoA = this.selectedCompareInvNos[0];
                    this.compareInvNoB = this.selectedCompareInvNos[1];
                    this.isCompareModalOpen = true;
                    this.fetchCompareData();
                },
                quickCompareInv(inv) {
                    if (!this.drawerInvs || this.drawerInvs.length < 2) {
                        alert('查核紀錄不足 2 筆，無法進行歷程比對！');
                        return;
                    }
                    const idx = this.drawerInvs.findIndex(x => x.INV_NO === inv.INV_NO);
                    let targetNoB = 0;
                    if (idx >= 0 && idx + 1 < this.drawerInvs.length) {
                        targetNoB = this.drawerInvs[idx + 1].INV_NO;
                    } else if (idx > 0) {
                        targetNoB = this.drawerInvs[idx - 1].INV_NO;
                    } else {
                        targetNoB = this.drawerInvs[1].INV_NO;
                    }
                    this.compareInvNoA = inv.INV_NO;
                    this.compareInvNoB = targetNoB;
                    this.isCompareModalOpen = true;
                    this.fetchCompareData();
                },
                async fetchCompareData() {
                    if (!this.activeFac || !this.activeFac.FAC_ID) return;
                    if (!this.compareInvNoA || !this.compareInvNoB) return;
                    this.compareLoading = true;
                    try {
                        const url = `CaseList.aspx?action=compareinvs&facId=${this.activeFac.FAC_ID}&invNoA=${this.compareInvNoA}&invNoB=${this.compareInvNoB}`;
                        const res = await axios.get(url);
                        if (res.data && res.data.Success) {
                            this.compareData = res.data;
                        } else {
                            alert(res.data.Message || '讀取比對資料失敗');
                        }
                    } catch (e) {
                        console.error('讀取比對資料異常', e);
                        alert('讀取歷程比對資料發生異常');
                    } finally {
                        this.compareLoading = false;
                    }
                },
                swapCompareInvs() {
                    const temp = this.compareInvNoA;
                    this.compareInvNoA = this.compareInvNoB;
                    this.compareInvNoB = temp;
                    this.fetchCompareData();
                },
                openCompareLightbox(url, label, memo) {
                    if (!url) return;
                    this.compareLightboxPhoto = { url: url, label: label, memo: memo };
                },

                // 20. 匯出 Excel 報表
                exportExcel() {
                    if (this.totalCount === 0) {
                        alert('目前無符合條件之場所資料可供匯出！');
                        return;
                    }
                    this.exporting = true;
                    const params = new URLSearchParams();
                    params.append('action', 'exportExcel');
                    params.append('Mode', this.filter.Mode || 'all');
                    params.append('FacName', this.filter.FacName || '');
                    params.append('CNo', this.filter.CNo || '');
                    params.append('ScId', this.filter.ScId || '');
                    params.append('SortBy', this.filter.SortBy || 'loss_desc');
                    if (this.filter.Towns && this.filter.Towns.length > 0) {
                        params.append('Towns', this.filter.Towns.join(','));
                    }

                    axios.post('CaseList.aspx', params, { responseType: 'blob' })
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
                            const timeStr = now.getFullYear() + ('0' + (now.getMonth() + 1)).slice(-2) + ('0' + now.getDate()).slice(-2) + ('0' + now.getHours()).slice(-2) + ('0' + now.getMinutes()).slice(-2);
                            link.download = '固定源巡查場所清單_' + timeStr + '.xls';
                            document.body.appendChild(link);
                            link.click();
                            document.body.removeChild(link);
                            window.URL.revokeObjectURL(link.href);
                        })
                        .catch(err => {
                            console.error('匯出 Excel 失敗:', err);
                            alert('匯出 Excel 失敗，請稍後再試');
                        })
                        .finally(() => {
                            this.exporting = false;
                        });
                }
            }
        }).mount('#caseListApp');

        // 地圖 Popup 全域橋接
        window.caseAppHelper = {
            openDrawer: function (facId) {
                const app = document.querySelector('#caseListApp').__vue_app__._instance.proxy;
                const fac = app.items.find(x => x.FAC_ID === facId);
                if (fac) app.openFacDrawer(fac);
            },
            navNewCase: function (facId) {
                const app = document.querySelector('#caseListApp').__vue_app__._instance.proxy;
                const fac = app.items.find(x => x.FAC_ID === facId);
                if (fac) app.navigateNewCase(fac, false);
            }
        };
    </script>
</body>
</html>
