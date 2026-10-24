<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="oFAC_List.aspx.cs" Inherits="NTPC_FEC.FAC.oFAC_List" %>

<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定溢散源管理平台 - 固定污染源許可證管理清單</title>

    <!-- 專屬 Favicon -->
    <link rel="shortcut icon" href="../favicon.ico" type="image/x-icon" />

    <!-- 本地化依賴：Bootstrap 4, FontAwesome 5 -->
    <link rel="stylesheet" href="../Content/bootstrap.min.css" />
    <link rel="stylesheet" href="../Content/fontawesome/css/all.min.css" />

    <style>
        :root {
            --brand-primary: #0099e5;     /* 新北青藍 */
            --brand-blue: #0284c7;        /* 科技藍 */
            --brand-dark-blue: #0b1f7d;   /* 海軍深藍 */
            --brand-navy: #0f172a;        /* 標題深色 */
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
            box-sizing: border-box;
        }

        .top-navbar-left {
            display: flex;
            align-items: center;
            gap: 10px;
            min-width: 0;
            flex: 1 1 auto;
            overflow: hidden;
        }

        .top-navbar-right {
            display: flex;
            align-items: center;
            flex-shrink: 0;
            margin-left: 8px;
        }

        .navbar-brand-title {
            font-size: 1.15rem;
            font-weight: 700;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            color: #ffffff;
            text-decoration: none;
            letter-spacing: 0.5px;
            white-space: nowrap !important;
            min-width: 0;
        }

        .navbar-brand-title:hover {
            color: #ffffff;
            text-decoration: none;
        }

        .brand-text {
            white-space: nowrap !important;
            display: inline-block;
        }

        .brand-badge {
            font-size: 12px;
            white-space: nowrap !important;
            padding: 3px 8px;
            border-radius: 6px;
            flex-shrink: 0;
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
            padding: 0 12px;
            gap: 6px;
            transition: all 0.2s ease;
            text-decoration: none !important;
            flex-shrink: 0;
            white-space: nowrap !important;
        }

        .nav-btn:hover {
            background-color: rgba(255, 255, 255, 0.32);
            color: #ffffff !important;
            text-decoration: none !important;
        }

        .btn-header-add {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            height: 36px;
            white-space: nowrap !important;
        }

        /* 頂部導覽列與標籤頁在小尺寸螢幕下的 RWD 優化 (防止跳行與文字過大) */
        @media (max-width: 768px) {
            .top-navbar {
                height: 54px;
                padding: 0 12px;
            }
            .top-navbar-left {
                gap: 8px;
            }
            .navbar-brand-title {
                font-size: 1rem;
                gap: 6px;
            }
            .brand-text {
                font-size: 1rem;
            }
            .brand-badge {
                font-size: 11px;
                padding: 2px 6px;
            }
            .nav-btn {
                height: 34px;
                padding: 0 10px;
            }
            .btn-header-add {
                height: 34px;
            }
        }

        @media (max-width: 576px) {
            .top-navbar {
                height: 50px;
                padding: 0 10px;
            }
            .top-navbar-left {
                gap: 6px;
            }
            .navbar-brand-title {
                font-size: 0.92rem;
                gap: 6px;
            }
            .navbar-brand-title i {
                font-size: 0.95rem;
            }
            .brand-text {
                font-size: 0.92rem;
                letter-spacing: 0;
            }
            .brand-badge {
                font-size: 11px;
                padding: 2px 5px;
            }
            .nav-btn {
                width: 32px;
                height: 32px;
                padding: 0;
                border-radius: 6px;
            }
            .btn-header-add {
                width: 32px;
                height: 32px;
                padding: 0;
                border-radius: 6px;
            }
            .nav-mode-bar {
                padding: 0 8px;
                gap: 4px;
            }
            .nav-mode-item {
                padding: 10px 10px;
                font-size: 13px;
                gap: 6px;
            }
            .nav-mode-item .tab-badge {
                font-size: 11px;
                padding: 1px 5px;
            }
        }

        @media (max-width: 380px) {
            .top-navbar {
                padding: 0 6px;
            }
            .navbar-brand-title {
                font-size: 0.85rem;
                gap: 4px;
            }
            .brand-text {
                font-size: 0.85rem;
            }
            .brand-badge {
                font-size: 10px;
                padding: 1px 4px;
            }
            .nav-mode-item {
                padding: 8px 8px;
                font-size: 12px;
            }
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
            padding: 2px 8px;
            border-radius: 12px;
            font-weight: 700;
        }

        /* 主作業容器 */
        .container-fluid-custom {
            max-width: 1560px;
            margin: 0 auto;
            padding: 20px;
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

        /* 統計晶片 (Stat Chips) */
        .stat-chip {
            background: #f1f5f9;
            border-radius: 8px;
            padding: 10px 14px;
            border: 1px solid var(--border-color);
            display: inline-flex;
            align-items: center;
            gap: 10px;
        }

        .stat-chip-icon {
            width: 36px;
            height: 36px;
            border-radius: 8px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 16px;
        }

        /* 膠囊式按鈕組 */
        .segmented-group {
            display: inline-flex;
            background: #f1f5f9;
            padding: 3px;
            border-radius: 8px;
            border: 1px solid var(--border-color);
        }

        .segment-btn {
            border: none;
            background: transparent;
            padding: 6px 14px;
            border-radius: 6px;
            font-size: 13px;
            font-weight: 600;
            color: #64748b;
            cursor: pointer;
            transition: all 0.2s;
        }

        .segment-btn.active {
            background: #ffffff;
            color: var(--brand-blue);
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
        }

        /* 篩選面板底部操作列 (兩行式響應排版) */
        .filter-footer-bar {
            display: flex;
            flex-direction: column;
            gap: 10px;
            margin-top: 12px;
            padding-top: 12px;
            border-top: 1px solid var(--border-color);
        }
        .filter-footer-info {
            font-size: 13px;
            color: #64748b;
            line-height: 1.4;
            display: flex;
            align-items: center;
        }
        .filter-footer-actions {
            display: flex;
            align-items: center;
            justify-content: flex-end;
            gap: 8px;
        }
        .filter-footer-actions .btn {
            white-space: nowrap !important;
        }
        @media (max-width: 576px) {
            .filter-footer-actions {
                width: 100%;
            }
            .filter-footer-actions .btn {
                flex: 1 1 50%;
                display: inline-flex;
                align-items: center;
                justify-content: center;
                padding: 7px 10px;
            }
        }

        /* 電腦端表格容器與佈局 - 嚴格防溢出與防擠壓 */
        .desktop-table-container {
            width: 100%;
            overflow-x: auto;
            -webkit-overflow-scrolling: touch;
            background: #ffffff;
        }

        .table-modern {
            width: 100%;
            min-width: 1360px; /* 關鍵鎖定最小寬度，防止視窗縮小強行擠壓最後一欄 */
            margin-bottom: 0;
            border-collapse: separate;
            border-spacing: 0;
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
            height: 32px;
            min-height: 32px;
            white-space: nowrap !important;
            flex-shrink: 0;
            border: 1px solid transparent;
            cursor: pointer;
            text-decoration: none !important;
            line-height: 1;
        }

        .btn-action i {
            font-size: 12.5px;
        }

        .btn-action-update {
            background: #f0f9ff;
            color: #0284c7;
            border-color: #bae6fd;
        }
        .btn-action-update:hover {
            background: #0284c7;
            color: #ffffff;
            border-color: #0284c7;
        }

        .btn-action-edit {
            background: #fffbeb;
            color: #b45309;
            border-color: #fde68a;
        }
        .btn-action-edit:hover {
            background: #f59e0b;
            color: #ffffff;
            border-color: #f59e0b;
        }

        .btn-action-unlock {
            background: #fef2f2;
            color: #dc2626;
            border-color: #fecaca;
        }
        .btn-action-unlock:hover {
            background: #dc2626;
            color: #ffffff;
            border-color: #dc2626;
        }

        .btn-action-view {
            background: #f8fafc;
            color: #475569;
            border-color: #cbd5e1;
        }
        .btn-action-view:hover {
            background: #64748b;
            color: #ffffff;
            border-color: #64748b;
        }

        /* 欄位寬度與換行鎖定 */
        .col-action {
            width: 235px !important;
            min-width: 235px !important;
            max-width: 235px !important;
            text-align: center !important;
            white-space: nowrap !important;
        }

        .col-file {
            width: 125px !important;
            min-width: 125px !important;
            text-align: center !important;
            white-space: nowrap !important;
        }

        .file-chip {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            width: 88px;
            min-width: 88px;
            max-width: 88px;
            height: 26px;
            min-height: 26px;
            padding: 0 4px;
            font-size: 11.5px;
            font-weight: 600;
            border-radius: 4px;
            text-decoration: none !important;
            white-space: nowrap !important;
            line-height: 1;
            transition: all 0.15s;
            box-sizing: border-box;
            gap: 4px;
        }
        .file-chip i {
            font-size: 12px;
            margin-right: 0 !important;
            flex-shrink: 0;
        }
        .file-chip span {
            line-height: 1;
            display: inline-block;
        }
        .file-chip-lic {
            background: #f0f9ff;
            color: #0284c7;
            border: 1px solid #bae6fd;
        }
        .file-chip-lic:hover {
            background: #e0f2fe;
            color: #0369a1;
            border-color: #7dd3fc;
            text-decoration: none !important;
        }
        .file-chip-unlock {
            background: #fef2f2;
            color: #b91c1c;
            border: 1px solid #fecaca;
        }
        .file-chip-unlock:hover {
            background: #fee2e2;
            color: #991b1b;
            border-color: #fca5a5;
            text-decoration: none !important;
        }
        .file-chip-empty {
            background: #f8fafc;
            color: #94a3b8;
            border: 1px dashed #cbd5e1;
            cursor: default;
        }

        .table-modern thead th {
            background: #f8fafc;
            color: #475569;
            font-size: 13px;
            font-weight: 700;
            padding: 12px 14px;
            border-top: none;
            border-bottom: 2px solid var(--border-color);
            white-space: nowrap;
            vertical-align: middle;
        }

        .table-modern tbody td {
            padding: 14px;
            font-size: 13.5px;
            color: var(--text-main);
            border-top: 1px solid var(--border-color);
            vertical-align: middle;
        }

        .table-modern tbody tr:hover {
            background-color: #f8fafc;
        }

        /* 行動端卡片清單 (隱藏於桌面端) */
        .mobile-card-list {
            display: none;
        }

        @media (max-width: 991.98px) {
            .desktop-table-container {
                display: none;
            }
            .mobile-card-list {
                display: flex;
                flex-direction: column;
                gap: 12px;
            }
        }

        .mobile-item-card {
            background: #ffffff;
            border: 1px solid var(--border-color);
            border-radius: 10px;
            padding: 16px;
            box-shadow: 0 1px 4px rgba(0, 0, 0, 0.04);
        }

        .mobile-item-header {
            display: flex;
            align-items: flex-start;
            justify-content: space-between;
            margin-bottom: 10px;
            border-bottom: 1px dashed var(--border-color);
            padding-bottom: 8px;
        }

        .mobile-item-body {
            font-size: 13.5px;
            line-height: 1.6;
        }

        .mobile-item-footer {
            margin-top: 12px;
            padding-top: 10px;
            border-top: 1px solid var(--border-color);
            display: flex;
            gap: 8px;
            flex-wrap: wrap;
        }

        /* 狀態徽章 */
        .badge-status {
            padding: 4px 8px;
            border-radius: 6px;
            font-size: 12px;
            font-weight: 700;
        }
        .badge-valid { background: #ecfdf5; color: #047857; border: 1px solid #a7f3d0; }
        .badge-expired { background: #fef2f2; color: #b91c1c; border: 1px solid #fecaca; }
        .badge-unlocked { background: #f1f5f9; color: #475569; border: 1px solid #cbd5e1; }

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

        /* 模態彈窗 (Modals) */
        .modal-overlay {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(15, 23, 42, 0.6);
            backdrop-filter: blur(4px);
            z-index: 1050;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 16px;
        }

        .modal-container {
            background: #ffffff;
            border-radius: 14px;
            width: 100%;
            max-width: 680px;
            max-height: 90vh;
            display: flex;
            flex-direction: column;
            box-shadow: 0 10px 25px rgba(0, 0, 0, 0.2);
            animation: modalFadeIn 0.2s ease-out;
            overflow: hidden;
        }

        .modal-container-lg {
            max-width: 860px;
        }

        @keyframes modalFadeIn {
            from { opacity: 0; transform: translateY(12px) scale(0.98); }
            to { opacity: 1; transform: translateY(0) scale(1); }
        }

        .modal-header-custom {
            padding: 16px 20px;
            background: #ffffff;
            border-bottom: 1px solid var(--border-color);
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .modal-title-custom {
            font-size: 1.12rem;
            font-weight: 700;
            color: var(--brand-navy);
            margin: 0;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .modal-body-custom {
            padding: 20px;
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

        .close-btn {
            background: transparent;
            border: none;
            color: #94a3b8;
            font-size: 20px;
            cursor: pointer;
            padding: 4px;
            line-height: 1;
            transition: color 0.15s;
        }
        .close-btn:hover {
            color: #0f172a;
        }

        /* 檔案拖曳上傳區 */
        .upload-dropzone {
            border: 2px dashed #cbd5e1;
            border-radius: 10px;
            padding: 24px;
            text-align: center;
            background: #f8fafc;
            cursor: pointer;
            transition: all 0.2s;
        }
        .upload-dropzone:hover {
            border-color: var(--brand-blue);
            background: #f0f9ff;
        }

        /* 浮動提示 Toast */
        .toast-container-custom {
            position: fixed;
            top: 76px;
            right: 20px;
            z-index: 1080;
            max-width: 360px;
        }
        .alert-toast {
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
            border-radius: 8px;
            margin-bottom: 10px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 12px 16px;
            animation: slideInRight 0.3s ease;
        }
        @keyframes slideInRight {
            from { transform: translateX(100%); opacity: 0; }
            to { transform: translateX(0); opacity: 1; }
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">
    </form>

    <div id="app" v-cloak>
        <!-- 頂部品牌導覽列 (全站標準左側導航、右側主操作) -->
        <header class="top-navbar">
            <div class="top-navbar-left">
                <a href="../MainPage.aspx" class="nav-btn" title="返回主選單">
                    <i class="fas fa-home"></i>
                    <span class="d-none d-sm-inline">回首頁</span>
                </a>
                <a href="oFAC_List.aspx" class="navbar-brand-title" title="固定污染源許可證管理">
                    <i class="fas fa-industry text-white"></i>
                    <span class="brand-text">固定污染源許可證管理</span>
                    <span class="badge badge-light text-dark font-weight-bold brand-badge">
                        {{ counts.Total }} 筆
                    </span>
                </a>
            </div>
            <div class="top-navbar-right">
                <button type="button" class="btn btn-success btn-sm btn-header-add font-weight-bold shadow-sm" v-on:click="openAddModal" title="新增列管製程">
                    <i class="fas fa-plus"></i>
                    <span class="d-none d-sm-inline ml-1">新增列管製程</span>
                </button>
            </div>
        </header>

        <!-- 業務狀態分頁切換列 (Tabs) -->
        <nav class="nav-mode-bar">
            <div class="nav-mode-item" :class="{ 'active': currentMode === 'valid' }" v-on:click="switchMode('valid')">
                <i class="fas fa-check-circle text-success"></i>
                <span>有效許可證</span>
                <span class="tab-badge badge badge-success">{{ counts.Valid }}</span>
            </div>
            <div class="nav-mode-item" :class="{ 'active': currentMode === 'expired' }" v-on:click="switchMode('expired')">
                <i class="fas fa-exclamation-triangle text-danger"></i>
                <span>失效許可證</span>
                <span class="tab-badge badge badge-danger">{{ counts.Expired }}</span>
            </div>
            <div class="nav-mode-item" :class="{ 'active': currentMode === 'unlocked' }" v-on:click="switchMode('unlocked')">
                <i class="fas fa-archive text-secondary"></i>
                <span>解列許可證</span>
                <span class="tab-badge badge badge-secondary">{{ counts.Unlocked }}</span>
            </div>
            <div class="nav-mode-item" :class="{ 'active': currentMode === 'all' }" v-on:click="switchMode('all')">
                <i class="fas fa-list text-primary"></i>
                <span>全部清單</span>
                <span class="tab-badge badge badge-primary">{{ counts.Total }}</span>
            </div>
        </nav>

        <!-- 主作業容器 -->
        <main class="container-fluid-custom">
            <!-- 浮動訊息 Toast -->
            <div class="toast-container-custom" v-if="toast.show">
                <div class="alert alert-toast" :class="'alert-' + toast.type">
                    <div class="d-flex align-items-center">
                        <i :class="toast.icon" class="mr-2"></i>
                        <span>{{ toast.message }}</span>
                    </div>
                    <button type="button" class="close ml-2" v-on:click="toast.show = false">&times;</button>
                </div>
            </div>

            <!-- 篩選面板卡片 -->
            <div class="card-modern">
                <div class="card-modern-header">
                    <h2 class="card-modern-title">
                        <i class="fas fa-filter text-primary"></i>
                        <span>條件篩選查詢</span>
                    </h2>
                    <div class="d-flex align-items-center">
                        <button type="button" class="btn btn-sm btn-outline-secondary" v-on:click="isFilterCollapsed = !isFilterCollapsed">
                            <i :class="isFilterCollapsed ? 'fas fa-chevron-down' : 'fas fa-chevron-up'"></i>
                            <span class="ml-1">{{ isFilterCollapsed ? '展開篩選' : '收合篩選' }}</span>
                        </button>
                    </div>
                </div>

                <div class="card-modern-body" v-show="!isFilterCollapsed">
                    <div class="row">
                        <!-- 管制編號 -->
                        <div class="col-12 col-md-3 col-lg-3 mb-3">
                            <label class="font-weight-bold text-muted small mb-1">管制編號</label>
                            <input type="text" class="form-control form-control-sm" v-model="filter.cNo" placeholder="請輸入管制編號 (模糊查詢)" v-on:keyup.enter="searchData" />
                        </div>
                        <!-- 公私場所名稱 -->
                        <div class="col-12 col-md-3 col-lg-3 mb-3">
                            <label class="font-weight-bold text-muted small mb-1">公私場所名稱</label>
                            <input type="text" class="form-control form-control-sm" v-model="filter.facName" placeholder="請輸入場所名稱" v-on:keyup.enter="searchData" />
                        </div>
                        <!-- 製程名稱 -->
                        <div class="col-12 col-md-3 col-lg-3 mb-3">
                            <label class="font-weight-bold text-muted small mb-1">製程名稱</label>
                            <input type="text" class="form-control form-control-sm" v-model="filter.processName" placeholder="請輸入製程名稱" v-on:keyup.enter="searchData" />
                        </div>
                        <!-- 許可證字號 -->
                        <div class="col-12 col-md-3 col-lg-3 mb-3">
                            <label class="font-weight-bold text-muted small mb-1">許可證字號</label>
                            <input type="text" class="form-control form-control-sm" v-model="filter.processLic" placeholder="請輸入許可證字號" v-on:keyup.enter="searchData" />
                        </div>

                        <!-- 有效期限區間 -->
                        <div class="col-12 col-md-6 col-lg-4 mb-3">
                            <label class="font-weight-bold text-muted small mb-1">有效期限區間</label>
                            <div class="d-flex align-items-center">
                                <input type="date" class="form-control form-control-sm" v-model="filter.startDateS" />
                                <span class="mx-2 text-muted">~</span>
                                <input type="date" class="form-control form-control-sm" v-model="filter.startDateE" />
                            </div>
                        </div>

                        <!-- 展延期限區間 -->
                        <div class="col-12 col-md-6 col-lg-4 mb-3">
                            <label class="font-weight-bold text-muted small mb-1">展延期限區間</label>
                            <div class="d-flex align-items-center">
                                <input type="date" class="form-control form-control-sm" v-model="filter.continueDateS" />
                                <span class="mx-2 text-muted">~</span>
                                <input type="date" class="form-control form-control-sm" v-model="filter.continueDateE" />
                            </div>
                        </div>

                        <!-- 工務期限狀態 -->
                        <div class="col-12 col-md-6 col-lg-4 mb-3">
                            <label class="font-weight-bold text-muted small mb-1">工務期限狀態</label>
                            <div>
                                <div class="segmented-group">
                                    <button type="button" class="segment-btn" :class="{ 'active': filter.workDeadline === 'ALL' }" v-on:click="filter.workDeadline = 'ALL'">全部</button>
                                    <button type="button" class="segment-btn" :class="{ 'active': filter.workDeadline === 'Y' }" v-on:click="filter.workDeadline = 'Y'">有期限</button>
                                    <button type="button" class="segment-btn" :class="{ 'active': filter.workDeadline === 'N' }" v-on:click="filter.workDeadline = 'N'">無期限</button>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- 底部操作列 (分開成兩行顯示：第一行統計文字、第二行按鈕選項) -->
                    <div class="filter-footer-bar">
                        <!-- 第一行：文字 (全寬顯示，防止折行跑版) -->
                        <div class="filter-footer-info">
                            <i class="fas fa-info-circle text-primary mr-1"></i>
                            <span>共查詢到 <strong class="text-primary font-weight-bold">{{ totalCount }}</strong> 筆製程許可證</span>
                        </div>
                        <!-- 第二行：按鈕選項 (獨立一行，手機端平分寬度防疊合) -->
                        <div class="filter-footer-actions">
                            <button type="button" class="btn btn-outline-secondary btn-sm" v-on:click="resetFilter">
                                <i class="fas fa-undo mr-1"></i> 重設條件
                            </button>
                            <button type="button" class="btn btn-primary btn-sm px-3" v-on:click="searchData">
                                <i class="fas fa-search mr-1"></i> 立即查詢
                            </button>
                        </div>
                    </div>
                </div>
            </div>

            <!-- 清單列表卡片 (標準大四元操作工具列) -->
            <div class="card-modern">
                <div class="card-modern-header">
                    <div class="d-flex align-items-center gap-2">
                        <h2 class="card-modern-title">
                            <i class="fas fa-list-alt text-primary"></i>
                            <span>{{ getModeTitle() }}</span>
                        </h2>
                        <span class="badge badge-light border text-dark font-weight-bold ml-1">
                            共 {{ totalCount }} 筆
                        </span>
                        <span class="badge badge-secondary ml-1 d-none d-sm-inline">
                            頁次 {{ pageIndex }} / {{ totalPages }}
                        </span>
                    </div>

                    <div class="d-flex align-items-center">
                        <!-- 1. 重新整理 -->
                        <button type="button" class="btn btn-sm btn-outline-secondary mr-2" v-on:click="loadData" :disabled="loading" title="重新整理列表">
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
                                <option :value="10">10 筆</option>
                                <option :value="15">15 筆</option>
                                <option :value="30">30 筆</option>
                                <option :value="50">50 筆</option>
                            </select>
                        </div>
                    </div>
                </div>

                <!-- 載入中動畫 -->
                <div v-if="loading" class="text-center py-5">
                    <div class="spinner-border text-primary" role="status">
                        <span class="sr-only">載入中...</span>
                    </div>
                    <div class="text-muted mt-2 font-weight-bold">正在檢索資料庫許可證資訊...</div>
                </div>

                <!-- 無資料畫面 -->
                <div v-else-if="list.length === 0" class="text-center py-5">
                    <div class="text-muted mb-2">
                        <i class="fas fa-folder-open fa-3x" style="color: #cbd5e1;"></i>
                    </div>
                    <h5 class="text-muted font-weight-bold">查無任何符合條件的許可證資料</h5>
                    <p class="text-muted small">請嘗試調整篩選條件，或點選右上角「新增列管製程」建立新資料。</p>
                </div>

                <!-- 電腦端表格視圖 (Desktop Table) -->
                <div v-else class="desktop-table-container">
                    <table class="table-modern">
                        <thead>
                            <tr>
                                <th style="width: 110px; min-width: 110px; white-space: nowrap;">管制編號</th>
                                <th style="min-width: 240px;">公私場所名稱</th>
                                <th style="min-width: 180px;">製程編號 / 名稱</th>
                                <th style="min-width: 200px;">許可證類別 / 字號</th>
                                <th style="width: 110px; min-width: 110px; white-space: nowrap;">有效起日</th>
                                <th style="width: 125px; min-width: 125px; white-space: nowrap;">有效迄日<br /><small class="text-primary font-weight-bold">工務期限</small></th>
                                <th style="width: 125px; min-width: 125px; white-space: nowrap;" v-if="currentMode !== 'unlocked'">展延期限</th>
                                <th style="width: 125px; min-width: 125px; white-space: nowrap;" v-else>解列公文日期</th>
                                <th class="col-file">相關文件</th>
                                <th class="col-action">功能操作</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr v-for="item in list" :key="item.OFacId + '_' + item.ProcessId">
                                <!-- 管制編號 -->
                                <td>
                                    <span class="font-weight-bold text-dark">{{ item.CNo }}</span>
                                </td>
                                <!-- 場所名稱 -->
                                <td>
                                    <div class="font-weight-bold text-navy" style="font-size: 14px;">{{ item.FacName }}</div>
                                    <small class="text-muted" v-if="item.PMemo">備註: {{ item.PMemo }}</small>
                                </td>
                                <!-- 製程編號 / 名稱 -->
                                <td>
                                    <div class="badge badge-secondary mb-1">製程 {{ item.ProcessId }}</div>
                                    <div class="font-weight-bold text-dark">{{ item.ProcessName }}</div>
                                </td>
                                <!-- 許可證類別 / 字號 -->
                                <td>
                                    <span class="badge" :class="item.ProcessType === '操作' ? 'badge-info' : 'badge-primary'">
                                        {{ item.ProcessType }}許可證
                                    </span>
                                    <div class="small font-weight-bold text-muted mt-1">{{ item.ProcessLic || '無字號' }}</div>
                                </td>
                                <!-- 有效起日 -->
                                <td>
                                    <span>{{ item.StartDate || '-' }}</span>
                                </td>
                                <!-- 有效迄日 / 工務期限 -->
                                <td>
                                    <div>
                                        <span v-if="item.IsExpired" class="badge badge-danger font-weight-bold" title="已逾有效迄日">
                                            {{ item.EndDate }} (逾期)
                                        </span>
                                        <span v-else>{{ item.EndDate || '-' }}</span>
                                    </div>
                                    <div v-if="item.WorkDeadline" class="small text-primary font-weight-bold mt-1">
                                        {{ item.WorkDeadline }}
                                    </div>
                                </td>
                                <!-- 展延期限 / 解列日期 -->
                                <td v-if="currentMode !== 'unlocked'">
                                    <span v-if="item.ContinueAlert" class="font-weight-bold text-danger" title="展延期限需注意">
                                        {{ item.ContinueDeadline }}
                                    </span>
                                    <span v-else :class="{ 'text-success': item.ContinueDeadline }">
                                        {{ item.ContinueDeadline || '-' }}
                                    </span>
                                </td>
                                <td v-else>
                                    <span class="font-weight-bold text-secondary">{{ item.UnlockDocDate || '-' }}</span>
                                </td>
                                <!-- 相關文件 -->
                                <td class="col-file">
                                    <div class="d-inline-flex flex-column align-items-center" style="gap: 4px;">
                                        <!-- 許可證 -->
                                        <a v-if="item.LicFileUrl" :href="item.LicFileUrl" target="_blank" class="file-chip file-chip-lic" title="點擊檢視許可證 PDF">
                                            <i class="fas fa-file-pdf text-danger"></i><span>許可證</span>
                                        </a>
                                        <span v-else class="file-chip file-chip-empty">
                                            <span>無許可證</span>
                                        </span>

                                        <!-- 解列公文 (若有) -->
                                        <a v-if="item.UnlockFileUrl" :href="item.UnlockFileUrl" target="_blank" class="file-chip file-chip-unlock" title="點擊檢視解列公文 PDF">
                                            <i class="fas fa-file-pdf text-danger"></i><span>解列公文</span>
                                        </a>
                                    </div>
                                </td>
                                <!-- 功能操作按鈕 - 單行膠囊群組，嚴禁折行 -->
                                <td class="col-action">
                                    <div class="action-btn-group">
                                        <!-- 檔案更新 -->
                                        <button type="button" class="btn-action btn-action-update" v-on:click="openUploadModal(item)" title="更新許可證 PDF 並檢視歷程">
                                            <i class="fas fa-upload"></i>
                                            <span>更新</span>
                                        </button>
                                        <!-- 編輯 -->
                                        <button type="button" class="btn-action btn-action-edit" v-on:click="openEditModal(item)" title="編輯製程資料">
                                            <i class="fas fa-edit"></i>
                                            <span>編輯</span>
                                        </button>
                                        <!-- 解列 / 檢視解列 -->
                                        <button v-if="!item.IsUnlocked" type="button" class="btn-action btn-action-unlock" v-on:click="openUnlockModal(item, false)" title="解除列管作業">
                                            <i class="fas fa-lock-open"></i>
                                            <span>解列</span>
                                        </button>
                                        <button v-else type="button" class="btn-action btn-action-view" v-on:click="openUnlockModal(item, true)" title="檢視解列公文與資訊">
                                            <i class="fas fa-eye"></i>
                                            <span>檢視</span>
                                        </button>
                                    </div>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>

                <!-- 行動端卡片視圖 (Mobile Cards) -->
                <div v-if="!loading && list.length > 0" class="mobile-card-list p-3">
                    <div v-for="item in list" :key="'m_' + item.OFacId + '_' + item.ProcessId" class="mobile-item-card">
                        <div class="mobile-item-header">
                            <div>
                                <span class="badge badge-primary mr-1">{{ item.CNo }}</span>
                                <span class="font-weight-bold text-dark" style="font-size: 15px;">{{ item.FacName }}</span>
                            </div>
                            <div>
                                <span v-if="item.IsUnlocked" class="badge badge-unlocked">已解列</span>
                                <span v-else-if="item.IsExpired" class="badge badge-expired">已逾期</span>
                                <span v-else class="badge badge-valid">有效中</span>
                            </div>
                        </div>

                        <div class="mobile-item-body">
                            <div><span class="text-muted">製程：</span><strong>{{ item.ProcessId }} - {{ item.ProcessName }}</strong></div>
                            <div><span class="text-muted">許可證：</span>{{ item.ProcessType }}證 ({{ item.ProcessLic || '無字號' }})</div>
                            <div><span class="text-muted">有效起訖：</span>{{ item.StartDate || '-' }} ~ {{ item.EndDate || '-' }}</div>
                            <div v-if="item.WorkDeadline"><span class="text-muted">工務期限：</span><span class="text-primary font-weight-bold">{{ item.WorkDeadline }}</span></div>
                            <div v-if="!item.IsUnlocked && item.ContinueDeadline"><span class="text-muted">展延期限：</span><span :class="{ 'text-danger font-weight-bold': item.ContinueAlert }">{{ item.ContinueDeadline }}</span></div>
                            <div v-if="item.IsUnlocked"><span class="text-muted">解列日期：</span><span class="font-weight-bold text-secondary">{{ item.UnlockDocDate }}</span></div>
                            <div v-if="item.PMemo"><span class="text-muted">備註說明：</span>{{ item.PMemo }}</div>
                        </div>

                        <div class="mobile-item-footer">
                            <a v-if="item.LicFileUrl" :href="item.LicFileUrl" target="_blank" class="btn btn-sm btn-outline-primary flex-fill">
                                <i class="fas fa-file-pdf mr-1"></i>許可證 PDF
                            </a>
                            <button type="button" class="btn btn-sm btn-outline-info flex-fill" v-on:click="openUploadModal(item)">
                                <i class="fas fa-upload mr-1"></i>上傳更新
                            </button>
                            <button type="button" class="btn btn-sm btn-outline-warning flex-fill" v-on:click="openEditModal(item)">
                                <i class="fas fa-edit mr-1"></i>編輯
                            </button>
                            <button v-if="!item.IsUnlocked" type="button" class="btn btn-sm btn-outline-danger flex-fill" v-on:click="openUnlockModal(item, false)">
                                <i class="fas fa-lock-open mr-1"></i>解列
                            </button>
                            <button v-else type="button" class="btn btn-sm btn-outline-secondary flex-fill" v-on:click="openUnlockModal(item, true)">
                                <i class="fas fa-eye mr-1"></i>公文
                            </button>
                        </div>
                    </div>
                </div>

                <!-- 自適應底部分頁導覽列 (Responsive Pagination Footer) -->
                <div v-if="!loading && totalCount > 0" class="pagination-footer">
                    <div class="pagination-footer-info">
                        顯示第 <strong class="text-dark">{{ (filter.pageIndex - 1) * filter.pageSize + 1 }}</strong> 至 <strong class="text-dark">{{ Math.min(filter.pageIndex * filter.pageSize, totalCount) }}</strong> 筆，共 <strong class="text-dark">{{ totalCount }}</strong> 筆
                    </div>
                    <div class="pagination-action-group">
                        <button type="button" class="btn-page-ctrl btn-edge" :disabled="filter.pageIndex <= 1" v-on:click="goToPage(1)" title="第一頁">
                            <i class="fas fa-angle-double-left"></i>
                            <span class="d-none d-md-inline ml-1">首頁</span>
                        </button>
                        <button type="button" class="btn-page-ctrl btn-step" :disabled="filter.pageIndex <= 1" v-on:click="goToPage(filter.pageIndex - 1)" title="上一頁">
                            <i class="fas fa-chevron-left mr-1"></i>
                            <span>上一頁</span>
                        </button>
                        <div class="page-indicator-pill" title="目前頁次 / 總頁數">
                            <span>{{ filter.pageIndex }}</span>
                            <span class="mx-1 text-muted" style="opacity: 0.5; font-weight: normal;">/</span>
                            <span>{{ totalPages }}</span>
                        </div>
                        <button type="button" class="btn-page-ctrl btn-step" :disabled="filter.pageIndex >= totalPages" v-on:click="goToPage(filter.pageIndex + 1)" title="下一頁">
                            <span>下一頁</span>
                            <i class="fas fa-chevron-right ml-1"></i>
                        </button>
                        <button type="button" class="btn-page-ctrl btn-edge" :disabled="filter.pageIndex >= totalPages" v-on:click="goToPage(totalPages)" title="最後一頁">
                            <span class="d-none d-md-inline ml-1">末頁</span>
                            <i class="fas fa-angle-double-right"></i>
                        </button>
                    </div>
                </div>
            </div>
        </main>

        <!-- ======================= MODAL 1: 新增 / 編輯製程資料 ======================= -->
        <div class="modal-overlay" v-if="modalEdit.show" v-on:click.self="modalEdit.show = false">
            <div class="modal-container">
                <div class="modal-header-custom">
                    <h3 class="modal-title-custom">
                        <i :class="modalEdit.isEdit ? 'fas fa-edit text-warning' : 'fas fa-plus-circle text-primary'"></i>
                        <span>{{ modalEdit.isEdit ? '編輯列管製程資料' : '新增公私場所列管製程' }}</span>
                    </h3>
                    <button type="button" class="close-btn" v-on:click="modalEdit.show = false">&times;</button>
                </div>

                <div class="modal-body-custom">
                    <div class="row">
                        <!-- 管制編號 -->
                        <div class="col-12 col-md-6 mb-3">
                            <label class="font-weight-bold small text-muted">管制編號 <span class="text-danger">*</span></label>
                            <input type="text" class="form-control form-control-sm" v-model="formProcess.cNo" :disabled="modalEdit.isEdit" placeholder="請輸入管制編號" v-on:blur="onCheckCNoBlur" />
                            <small class="text-success font-weight-bold mt-1 d-block" v-if="formProcess.facFound && !modalEdit.isEdit">
                                <i class="fas fa-check-circle mr-1"></i>已存在場所：{{ formProcess.facName }}
                            </small>
                            <small class="text-info mt-1 d-block" v-else-if="!modalEdit.isEdit && formProcess.cNo && !formProcess.facFound">
                                <i class="fas fa-info-circle mr-1"></i>新管制編號，請於下方填寫場所名稱
                            </small>
                        </div>

                        <!-- 場所名稱 -->
                        <div class="col-12 col-md-6 mb-3">
                            <label class="font-weight-bold small text-muted">公私場所名稱 <span class="text-danger">*</span></label>
                            <input type="text" class="form-control form-control-sm" v-model="formProcess.facName" :disabled="modalEdit.isEdit || formProcess.facFound" placeholder="請輸入公私場所名稱" />
                        </div>

                        <!-- 製程編號 -->
                        <div class="col-12 col-md-6 mb-3">
                            <label class="font-weight-bold small text-muted">製程編號 <span class="text-danger">*</span></label>
                            <input type="text" class="form-control form-control-sm" v-model="formProcess.processId" :disabled="modalEdit.isEdit" placeholder="例如: 01, 02" />
                        </div>

                        <!-- 製程名稱 -->
                        <div class="col-12 col-md-6 mb-3">
                            <label class="font-weight-bold small text-muted">製程名稱 <span class="text-danger">*</span></label>
                            <input type="text" class="form-control form-control-sm" v-model="formProcess.processName" placeholder="例如: 鍋爐程序, 烤漆程序" />
                        </div>

                        <!-- 許可證類別 -->
                        <div class="col-12 col-md-6 mb-3">
                            <label class="font-weight-bold small text-muted">許可證類別 <span class="text-danger">*</span></label>
                            <div>
                                <div class="segmented-group">
                                    <button type="button" class="segment-btn" :class="{ 'active': formProcess.processType === '操作' }" v-on:click="formProcess.processType = '操作'">操作許可證</button>
                                    <button type="button" class="segment-btn" :class="{ 'active': formProcess.processType === '設置' }" v-on:click="formProcess.processType = '設置'">設置許可證</button>
                                </div>
                            </div>
                        </div>

                        <!-- 許可證字號 -->
                        <div class="col-12 col-md-6 mb-3">
                            <label class="font-weight-bold small text-muted">許可證字號</label>
                            <input type="text" class="form-control form-control-sm" v-model="formProcess.processLic" placeholder="例如: 新北市環操證字第F0000-00號" />
                        </div>

                        <!-- 有效起日 -->
                        <div class="col-12 col-md-6 mb-3">
                            <label class="font-weight-bold small text-muted">有效起日</label>
                            <input type="date" class="form-control form-control-sm" v-model="formProcess.startDate" />
                        </div>

                        <!-- 有效迄日 -->
                        <div class="col-12 col-md-6 mb-3">
                            <label class="font-weight-bold small text-muted">有效迄日</label>
                            <input type="date" class="form-control form-control-sm" v-model="formProcess.endDate" />
                        </div>

                        <!-- 工務期限 -->
                        <div class="col-12 col-md-6 mb-3">
                            <label class="font-weight-bold small text-muted">工務期限</label>
                            <input type="date" class="form-control form-control-sm" v-model="formProcess.workDeadline" />
                        </div>

                        <!-- 展延期限 -->
                        <div class="col-12 col-md-6 mb-3">
                            <label class="font-weight-bold small text-muted">展延期限</label>
                            <input type="date" class="form-control form-control-sm" v-model="formProcess.continueDeadline" />
                        </div>

                        <!-- 備註說明 -->
                        <div class="col-12 mb-2">
                            <label class="font-weight-bold small text-muted">備註說明</label>
                            <textarea class="form-control form-control-sm" rows="3" v-model="formProcess.pMemo" placeholder="選填，輸入其他備註事由"></textarea>
                        </div>
                    </div>
                </div>

                <div class="modal-footer-custom">
                    <button type="button" class="btn btn-outline-secondary btn-sm" v-on:click="modalEdit.show = false">取消</button>
                    <button type="button" class="btn btn-primary btn-sm px-4" :disabled="modalEdit.submitting" v-on:click="submitProcess">
                        <i class="fas fa-spinner fa-spin mr-1" v-if="modalEdit.submitting"></i>
                        <span>{{ modalEdit.isEdit ? '儲存變更' : '新增製程' }}</span>
                    </button>
                </div>
            </div>
        </div>

        <!-- ======================= MODAL 2: 檔案更新與歷史紀錄 ======================= -->
        <div class="modal-overlay" v-if="modalUpload.show" v-on:click.self="modalUpload.show = false">
            <div class="modal-container modal-container-lg">
                <div class="modal-header-custom">
                    <h3 class="modal-title-custom">
                        <i class="fas fa-file-upload text-info"></i>
                        <span>許可證檔案更新與歷程紀錄</span>
                    </h3>
                    <button type="button" class="close-btn" v-on:click="modalUpload.show = false">&times;</button>
                </div>

                <div class="modal-body-custom">
                    <!-- 標的資訊 -->
                    <div class="alert alert-light border mb-3">
                        <div class="row small">
                            <div class="col-12 col-md-6">
                                <span class="text-muted">管制編號：</span><strong>{{ modalUpload.item.CNo }}</strong>
                            </div>
                            <div class="col-12 col-md-6">
                                <span class="text-muted">場所名稱：</span><strong>{{ modalUpload.item.FacName }}</strong>
                            </div>
                            <div class="col-12 col-md-6 mt-1">
                                <span class="text-muted">製程名稱：</span><strong>製程 {{ modalUpload.item.ProcessId }} - {{ modalUpload.item.ProcessName }}</strong>
                            </div>
                            <div class="col-12 col-md-6 mt-1">
                                <span class="text-muted">許可字號：</span><strong>{{ modalUpload.item.ProcessLic || '無字號' }}</strong>
                            </div>
                        </div>
                    </div>

                    <!-- 上傳區 -->
                    <div class="mb-4">
                        <label class="font-weight-bold small text-muted mb-2">上傳最新許可證 PDF 檔案</label>
                        <div class="upload-dropzone" v-on:click="triggerFileInput('licFileInput')">
                            <i class="fas fa-cloud-upload-alt fa-2x text-primary mb-2"></i>
                            <div class="font-weight-bold text-dark" v-if="!selectedLicFile">點擊此處或拖曳 PDF 檔案至此上傳</div>
                            <div class="font-weight-bold text-primary" v-else>
                                <i class="fas fa-file-pdf mr-1 text-danger"></i>已選取檔案：{{ selectedLicFile.name }} ({{ formatFileSize(selectedLicFile.size) }})
                            </div>
                            <small class="text-muted d-block mt-1">僅限上傳 .pdf 檔案，上傳後舊版檔案將自動轉存為歷史紀錄</small>
                        </div>
                        <input type="file" id="licFileInput" ref="licFileInput" accept="application/pdf" style="display: none;" v-on:change="onLicFileChange" />
                    </div>

                    <!-- 上傳歷史清單 -->
                    <div>
                        <h6 class="font-weight-bold text-navy mb-2">
                            <i class="fas fa-history text-muted mr-1"></i>歷史上傳紀錄
                        </h6>
                        <div class="table-responsive" style="max-height: 220px; overflow-y: auto;">
                            <table class="table table-sm table-bordered small">
                                <thead class="thead-light">
                                    <tr>
                                        <th style="width: 140px;">上傳時間</th>
                                        <th style="width: 100px;">上傳人員</th>
                                        <th>檔案名稱</th>
                                        <th style="width: 90px; text-align: center;">檔案預覽</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr v-if="uploadHistory.length === 0">
                                        <td colspan="4" class="text-center text-muted py-3">尚無任何歷史上傳紀錄</td>
                                    </tr>
                                    <tr v-for="(h, idx) in uploadHistory" :key="idx" :class="{ 'table-secondary text-muted': h.IsDeleted }">
                                        <td>{{ h.UploadDate }}</td>
                                        <td>{{ h.UploadUserName }}</td>
                                        <td>
                                            <span v-if="h.IsDeleted" class="badge badge-secondary mr-1">歷史備份</span>
                                            <span>{{ h.UploadFileName }}</span>
                                        </td>
                                        <td class="text-center">
                                            <a :href="h.FileUrl" target="_blank" class="btn btn-xs btn-outline-primary py-0 px-2">
                                                <i class="fas fa-download mr-1"></i>下載
                                            </a>
                                        </td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>

                <div class="modal-footer-custom">
                    <button type="button" class="btn btn-outline-secondary btn-sm" v-on:click="modalUpload.show = false">關閉</button>
                    <button type="button" class="btn btn-success btn-sm px-4" :disabled="!selectedLicFile || modalUpload.submitting" v-on:click="submitUploadLic">
                        <i class="fas fa-spinner fa-spin mr-1" v-if="modalUpload.submitting"></i>
                        <span>確認上傳檔案</span>
                    </button>
                </div>
            </div>
        </div>

        <!-- ======================= MODAL 3: 解除列管與公文檢視 ======================= -->
        <div class="modal-overlay" v-if="modalUnlock.show" v-on:click.self="modalUnlock.show = false">
            <div class="modal-container">
                <div class="modal-header-custom">
                    <h3 class="modal-title-custom">
                        <i :class="modalUnlock.isViewOnly ? 'fas fa-eye text-secondary' : 'fas fa-lock-open text-danger'"></i>
                        <span>{{ modalUnlock.isViewOnly ? '檢視解列資訊與公文' : '製程解除列管作業' }}</span>
                    </h3>
                    <button type="button" class="close-btn" v-on:click="modalUnlock.show = false">&times;</button>
                </div>

                <div class="modal-body-custom">
                    <!-- 標的資訊 -->
                    <div class="alert alert-light border mb-3">
                        <div class="small">
                            <div><span class="text-muted">管制編號：</span><strong>{{ modalUnlock.data.CNo }}</strong></div>
                            <div><span class="text-muted">公私場所：</span><strong>{{ modalUnlock.data.FacName }}</strong></div>
                            <div><span class="text-muted">製程項目：</span><strong>製程 {{ modalUnlock.data.ProcessId }} - {{ modalUnlock.data.ProcessName }}</strong></div>
                        </div>
                    </div>

                    <div class="row">
                        <!-- 解列公文日期 -->
                        <div class="col-12 mb-3">
                            <label class="font-weight-bold small text-muted">解列公文日期 <span class="text-danger" v-if="!modalUnlock.isViewOnly">*</span></label>
                            <input type="date" class="form-control form-control-sm" v-model="modalUnlock.data.UnlockDocDate" :disabled="modalUnlock.isViewOnly" />
                        </div>

                        <!-- 解列說明 -->
                        <div class="col-12 mb-3">
                            <label class="font-weight-bold small text-muted">解列說明事由</label>
                            <textarea class="form-control form-control-sm" rows="3" v-model="modalUnlock.data.UnlockMemo" :disabled="modalUnlock.isViewOnly" placeholder="請輸入解除列管原因或核准字號說明"></textarea>
                        </div>

                        <!-- 解列公文檔案 -->
                        <div class="col-12 mb-2">
                            <label class="font-weight-bold small text-muted">解列公文檔案 (PDF)</label>

                            <!-- 已有公文檔案 -->
                            <div v-if="modalUnlock.data.UnlockFileUrl" class="mb-2 p-2 bg-light border rounded d-flex align-items-center justify-content-between">
                                <div class="small text-truncate">
                                    <i class="fas fa-file-pdf text-danger mr-1"></i>
                                    <span>{{ modalUnlock.data.UnlockFileName }}</span>
                                </div>
                                <a :href="modalUnlock.data.UnlockFileUrl" target="_blank" class="btn btn-sm btn-outline-primary py-1">
                                    <i class="fas fa-external-link-alt mr-1"></i>線上檢視
                                </a>
                            </div>

                            <!-- 上傳新公文檔案 (非純檢視模式) -->
                            <div v-if="!modalUnlock.isViewOnly">
                                <div class="upload-dropzone p-3" v-on:click="triggerFileInput('unlockFileInput')">
                                    <i class="fas fa-file-upload text-danger mr-1"></i>
                                    <span v-if="!selectedUnlockFile">點擊選取解列公文 PDF (選填)</span>
                                    <span v-else class="text-danger font-weight-bold">{{ selectedUnlockFile.name }} ({{ formatFileSize(selectedUnlockFile.size) }})</span>
                                </div>
                                <input type="file" id="unlockFileInput" ref="unlockFileInput" accept="application/pdf" style="display: none;" v-on:change="onUnlockFileChange" />
                            </div>
                        </div>
                    </div>
                </div>

                <div class="modal-footer-custom">
                    <button type="button" class="btn btn-outline-secondary btn-sm" v-on:click="modalUnlock.show = false">
                        {{ modalUnlock.isViewOnly ? '關閉' : '取消' }}
                    </button>
                    <button v-if="!modalUnlock.isViewOnly" type="button" class="btn btn-danger btn-sm px-4" :disabled="modalUnlock.submitting" v-on:click="submitUnlock">
                        <i class="fas fa-spinner fa-spin mr-1" v-if="modalUnlock.submitting"></i>
                        <span>確認解除列管</span>
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- 本地核心庫引用 -->
    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>

    <script>
        const { createApp, ref, reactive, computed, onMounted } = Vue;

        createApp({
            setup() {
                const currentMode = ref('valid');
                const loading = ref(false);
                const isFilterCollapsed = ref(false);

                // 統計數據
                const counts = reactive({
                    Valid: 0,
                    Expired: 0,
                    Unlocked: 0,
                    Total: 0
                });

                // 篩選參數
                const filter = reactive({
                    cNo: '',
                    facName: '',
                    processName: '',
                    processLic: '',
                    startDateS: '',
                    startDateE: '',
                    continueDateS: '',
                    continueDateE: '',
                    workDeadline: 'ALL',
                    pageIndex: 1,
                    pageSize: 20
                });

                // 資料清單與分頁
                const list = ref([]);
                const totalCount = ref(0);

                // 浮動訊息 Toast
                const toast = reactive({
                    show: false,
                    type: 'success',
                    message: '',
                    icon: 'fas fa-check-circle'
                });

                const showToast = (message, type = 'success') => {
                    toast.message = message;
                    toast.type = type;
                    toast.icon = type === 'success' ? 'fas fa-check-circle' : (type === 'danger' ? 'fas fa-exclamation-circle' : 'fas fa-info-circle');
                    toast.show = true;
                    setTimeout(() => {
                        toast.show = false;
                    }, 3500);
                };

                // 總頁數計算
                const totalPages = computed(() => {
                    return Math.max(1, Math.ceil(totalCount.value / filter.pageSize));
                });

                // 可見分頁頁碼 (最多顯示 5 個)
                const visiblePages = computed(() => {
                    const current = filter.pageIndex;
                    const total = totalPages.value;
                    let start = Math.max(1, current - 2);
                    let end = Math.min(total, start + 4);
                    if (end - start < 4) {
                        start = Math.max(1, end - 4);
                    }
                    const pages = [];
                    for (let i = start; i <= end; i++) {
                        pages.push(i);
                    }
                    return pages;
                });

                // 模式標題
                const getModeTitle = () => {
                    switch (currentMode.value) {
                        case 'valid': return '有效許可證清單 (列管中)';
                        case 'expired': return '失效許可證清單 (已逾期)';
                        case 'unlocked': return '解列許可證清單 (已結案)';
                        case 'all': return '全數許可證總表一覽';
                        default: return '許可證清單';
                    }
                };

                // 檔案大小格式化
                const formatFileSize = (bytes) => {
                    if (!bytes) return '0 B';
                    const k = 1024;
                    const sizes = ['B', 'KB', 'MB', 'GB'];
                    const i = Math.floor(Math.log(bytes) / Math.log(k));
                    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
                };

                // 載入統計數
                const loadCounts = async () => {
                    try {
                        const res = await axios.get('oFAC_List.aspx?action=getCounts');
                        if (res.data && res.data.Success) {
                            counts.Valid = res.data.Counts.Valid;
                            counts.Expired = res.data.Counts.Expired;
                            counts.Unlocked = res.data.Counts.Unlocked;
                            counts.Total = res.data.Counts.Total;
                        }
                    } catch (err) {
                        console.error('統計查詢失敗', err);
                    }
                };

                // 載入清單資料
                const loadData = async () => {
                    loading.value = true;
                    try {
                        const params = {
                            action: 'getList',
                            mode: currentMode.value,
                            cNo: filter.cNo,
                            facName: filter.facName,
                            processName: filter.processName,
                            processLic: filter.processLic,
                            startDateS: filter.startDateS,
                            startDateE: filter.startDateE,
                            continueDateS: filter.continueDateS,
                            continueDateE: filter.continueDateE,
                            workDeadline: filter.workDeadline,
                            pageIndex: filter.pageIndex,
                            pageSize: filter.pageSize
                        };
                        const res = await axios.get('oFAC_List.aspx', { params });
                        if (res.data && res.data.Success) {
                            list.value = res.data.Items || [];
                            totalCount.value = res.data.Total || 0;
                        } else {
                            showToast(res.data ? res.data.Message : '資料檢索失敗', 'danger');
                        }
                    } catch (err) {
                        console.error('資料檢索失敗', err);
                        showToast('伺服器連線異常，無法載入資料', 'danger');
                    } finally {
                        loading.value = false;
                    }
                };

                // 切換分頁狀態
                const switchMode = (mode) => {
                    currentMode.value = mode;
                    filter.pageIndex = 1;
                    loadData();
                };

                // 搜尋與重設
                const searchData = () => {
                    filter.pageIndex = 1;
                    loadData();
                    loadCounts();
                };

                const resetFilter = () => {
                    filter.cNo = '';
                    filter.facName = '';
                    filter.processName = '';
                    filter.processLic = '';
                    filter.startDateS = '';
                    filter.startDateE = '';
                    filter.continueDateS = '';
                    filter.continueDateE = '';
                    filter.workDeadline = 'ALL';
                    filter.pageIndex = 1;
                    loadData();
                    loadCounts();
                };

                // 分頁切換
                const goToPage = (page) => {
                    if (page < 1 || page > totalPages.value || page === filter.pageIndex) return;
                    filter.pageIndex = page;
                    loadData();
                };

                const onPageSizeChange = () => {
                    filter.pageIndex = 1;
                    loadData();
                };

                // 匯出 Excel
                const exportExcel = () => {
                    const params = new URLSearchParams({
                        action: 'exportExcel',
                        mode: currentMode.value,
                        cNo: filter.cNo,
                        facName: filter.facName,
                        processName: filter.processName,
                        processLic: filter.processLic,
                        startDateS: filter.startDateS,
                        startDateE: filter.startDateE,
                        continueDateS: filter.continueDateS,
                        continueDateE: filter.continueDateE,
                        workDeadline: filter.workDeadline
                    });
                    window.location.href = 'oFAC_List.aspx?' + params.toString();
                };

                // ================= MODAL 1: 新增 / 編輯製程 =================
                const modalEdit = reactive({
                    show: false,
                    isEdit: false,
                    submitting: false
                });

                const formProcess = reactive({
                    oFacId: '',
                    cNo: '',
                    facName: '',
                    facFound: false,
                    processId: '',
                    processName: '',
                    processType: '操作',
                    processLic: '',
                    startDate: '',
                    endDate: '',
                    workDeadline: '',
                    continueDeadline: '',
                    pMemo: ''
                });

                const openAddModal = () => {
                    modalEdit.isEdit = false;
                    modalEdit.submitting = false;
                    formProcess.oFacId = '';
                    formProcess.cNo = '';
                    formProcess.facName = '';
                    formProcess.facFound = false;
                    formProcess.processId = '';
                    formProcess.processName = '';
                    formProcess.processType = '操作';
                    formProcess.processLic = '';
                    formProcess.startDate = '';
                    formProcess.endDate = '';
                    formProcess.workDeadline = '';
                    formProcess.continueDeadline = '';
                    formProcess.pMemo = '';
                    modalEdit.show = true;
                };

                const openEditModal = async (item) => {
                    modalEdit.isEdit = true;
                    modalEdit.submitting = false;
                    try {
                        const res = await axios.get('oFAC_List.aspx', {
                            params: {
                                action: 'getProcessDetail',
                                oFacId: item.OFacId,
                                processId: item.ProcessId
                            }
                        });
                        if (res.data && res.data.Success) {
                            const d = res.data.Detail;
                            formProcess.oFacId = d.OFacId;
                            formProcess.cNo = d.CNo;
                            formProcess.facName = d.FacName;
                            formProcess.facFound = true;
                            formProcess.processId = d.ProcessId;
                            formProcess.processName = d.ProcessName;
                            formProcess.processType = d.ProcessType || '操作';
                            formProcess.processLic = d.ProcessLic;
                            formProcess.startDate = d.StartDate;
                            formProcess.endDate = d.EndDate;
                            formProcess.workDeadline = d.WorkDeadline;
                            formProcess.continueDeadline = d.ContinueDeadline;
                            formProcess.pMemo = d.PMemo;
                            modalEdit.show = true;
                        } else {
                            showToast(res.data ? res.data.Message : '讀取製程資料失敗', 'danger');
                        }
                    } catch (err) {
                        showToast('讀取製程資料失敗', 'danger');
                    }
                };

                const onCheckCNoBlur = async () => {
                    if (!formProcess.cNo || modalEdit.isEdit) return;
                    try {
                        const res = await axios.get('oFAC_List.aspx', {
                            params: {
                                action: 'checkCNo',
                                cNo: formProcess.cNo.trim()
                            }
                        });
                        if (res.data && res.data.Success && res.data.Found) {
                            formProcess.oFacId = res.data.OFacId;
                            formProcess.facName = res.data.FacName;
                            formProcess.facFound = true;
                        } else {
                            formProcess.facFound = false;
                            formProcess.oFacId = '';
                        }
                    } catch (err) {
                        console.error('管制編號檢查失敗', err);
                    }
                };

                const submitProcess = async () => {
                    if (!formProcess.cNo.trim()) {
                        showToast('請輸入管制編號', 'warning');
                        return;
                    }
                    if (!formProcess.facName.trim()) {
                        showToast('請輸入公私場所名稱', 'warning');
                        return;
                    }
                    if (!formProcess.processId.trim()) {
                        showToast('請輸入製程編號', 'warning');
                        return;
                    }
                    if (!formProcess.processName.trim()) {
                        showToast('請輸入製程名稱', 'warning');
                        return;
                    }

                    modalEdit.submitting = true;
                    try {
                        const formData = new FormData();
                        formData.append('isEdit', modalEdit.isEdit ? 'true' : 'false');
                        formData.append('oFacId', formProcess.oFacId);
                        formData.append('cNo', formProcess.cNo.trim());
                        formData.append('facName', formProcess.facName.trim());
                        formData.append('processId', formProcess.processId.trim());
                        formData.append('processName', formProcess.processName.trim());
                        formData.append('processType', formProcess.processType);
                        formData.append('processLic', formProcess.processLic.trim());
                        formData.append('startDate', formProcess.startDate);
                        formData.append('endDate', formProcess.endDate);
                        formData.append('workDeadline', formProcess.workDeadline);
                        formData.append('continueDeadline', formProcess.continueDeadline);
                        formData.append('pMemo', formProcess.pMemo.trim());

                        const res = await axios.post('oFAC_List.aspx?action=saveProcess', formData);
                        if (res.data && res.data.Success) {
                            showToast(res.data.Message, 'success');
                            modalEdit.show = false;
                            loadData();
                            loadCounts();
                        } else {
                            showToast(res.data ? res.data.Message : '儲存失敗', 'danger');
                        }
                    } catch (err) {
                        showToast('伺服器處理異常', 'danger');
                    } finally {
                        modalEdit.submitting = false;
                    }
                };

                // ================= MODAL 2: 檔案更新 =================
                const modalUpload = reactive({
                    show: false,
                    submitting: false,
                    item: {}
                });

                const uploadHistory = ref([]);
                const selectedLicFile = ref(null);
                const licFileInput = ref(null);

                const openUploadModal = async (item) => {
                    modalUpload.item = item;
                    modalUpload.submitting = false;
                    selectedLicFile.value = null;
                    if (licFileInput.value) licFileInput.value.value = '';
                    uploadHistory.value = [];

                    try {
                        const res = await axios.get('oFAC_List.aspx', {
                            params: {
                                action: 'getUploadHistory',
                                oFacId: item.OFacId,
                                processId: item.ProcessId
                            }
                        });
                        if (res.data && res.data.Success) {
                            uploadHistory.value = res.data.Items || [];
                        }
                    } catch (err) {
                        console.error('無法讀取上傳歷程', err);
                    }

                    modalUpload.show = true;
                };

                const triggerFileInput = (id) => {
                    const el = document.getElementById(id);
                    if (el) el.click();
                };

                const onLicFileChange = (e) => {
                    const files = e.target.files;
                    if (files && files.length > 0) {
                        selectedLicFile.value = files[0];
                    }
                };

                const submitUploadLic = async () => {
                    if (!selectedLicFile.value) {
                        showToast('請選取要上傳的 PDF 檔案', 'warning');
                        return;
                    }

                    modalUpload.submitting = true;
                    try {
                        const formData = new FormData();
                        formData.append('oFacId', modalUpload.item.OFacId);
                        formData.append('processId', modalUpload.item.ProcessId);
                        formData.append('file', selectedLicFile.value);

                        const res = await axios.post('oFAC_List.aspx?action=uploadLicFile', formData, {
                            headers: { 'Content-Type': 'multipart/form-data' }
                        });

                        if (res.data && res.data.Success) {
                            showToast(res.data.Message, 'success');
                            modalUpload.show = false;
                            loadData();
                        } else {
                            showToast(res.data ? res.data.Message : '上傳失敗', 'danger');
                        }
                    } catch (err) {
                        showToast('檔案上傳異常', 'danger');
                    } finally {
                        modalUpload.submitting = false;
                    }
                };

                // ================= MODAL 3: 解列 =================
                const modalUnlock = reactive({
                    show: false,
                    isViewOnly: false,
                    submitting: false,
                    data: {
                        oFacId: '',
                        processId: '',
                        cNo: '',
                        facName: '',
                        processName: '',
                        unlockDocDate: '',
                        unlockMemo: '',
                        unlockFileName: '',
                        unlockFileUrl: ''
                    }
                });

                const selectedUnlockFile = ref(null);
                const unlockFileInput = ref(null);

                const openUnlockModal = async (item, viewOnly = false) => {
                    modalUnlock.isViewOnly = viewOnly;
                    modalUnlock.submitting = false;
                    selectedUnlockFile.value = null;
                    if (unlockFileInput.value) unlockFileInput.value.value = '';

                    try {
                        const res = await axios.get('oFAC_List.aspx', {
                            params: {
                                action: 'getUnlockDetail',
                                oFacId: item.OFacId,
                                processId: item.ProcessId
                            }
                        });
                        if (res.data && res.data.Success) {
                            const d = res.data;
                            modalUnlock.data.oFacId = item.OFacId;
                            modalUnlock.data.processId = item.ProcessId;
                            modalUnlock.data.cNo = d.CNo;
                            modalUnlock.data.facName = d.FacName;
                            modalUnlock.data.processName = d.ProcessName;
                            modalUnlock.data.unlockDocDate = d.UnlockDocDate;
                            modalUnlock.data.unlockMemo = d.UnlockMemo;
                            modalUnlock.data.unlockFileName = d.UnlockFileName;
                            modalUnlock.data.unlockFileUrl = d.UnlockFileUrl;
                            modalUnlock.show = true;
                        } else {
                            showToast(res.data ? res.data.Message : '無法讀取解列資訊', 'danger');
                        }
                    } catch (err) {
                        showToast('讀取解列資訊異常', 'danger');
                    }
                };

                const onUnlockFileChange = (e) => {
                    const files = e.target.files;
                    if (files && files.length > 0) {
                        selectedUnlockFile.value = files[0];
                    }
                };

                const submitUnlock = async () => {
                    if (!modalUnlock.data.unlockDocDate) {
                        showToast('請輸入解列公文日期', 'warning');
                        return;
                    }

                    modalUnlock.submitting = true;
                    try {
                        const formData = new FormData();
                        formData.append('oFacId', modalUnlock.data.oFacId);
                        formData.append('processId', modalUnlock.data.processId);
                        formData.append('unlockDocDate', modalUnlock.data.unlockDocDate);
                        formData.append('unlockMemo', modalUnlock.data.unlockMemo || '');
                        if (selectedUnlockFile.value) {
                            formData.append('file', selectedUnlockFile.value);
                        }

                        const res = await axios.post('oFAC_List.aspx?action=saveUnlock', formData, {
                            headers: { 'Content-Type': 'multipart/form-data' }
                        });

                        if (res.data && res.data.Success) {
                            showToast(res.data.Message, 'success');
                            modalUnlock.show = false;
                            loadData();
                            loadCounts();
                        } else {
                            showToast(res.data ? res.data.Message : '解列失敗', 'danger');
                        }
                    } catch (err) {
                        showToast('解列處理失敗', 'danger');
                    } finally {
                        modalUnlock.submitting = false;
                    }
                };

                // 掛載初始化
                onMounted(() => {
                    loadCounts();
                    loadData();
                });

                return {
                    currentMode,
                    loading,
                    isFilterCollapsed,
                    counts,
                    filter,
                    list,
                    totalCount,
                    totalPages,
                    visiblePages,
                    toast,
                    getModeTitle,
                    formatFileSize,
                    switchMode,
                    searchData,
                    resetFilter,
                    goToPage,
                    onPageSizeChange,
                    exportExcel,
                    loadData,
                    // Modal 1
                    modalEdit,
                    formProcess,
                    openAddModal,
                    openEditModal,
                    onCheckCNoBlur,
                    submitProcess,
                    // Modal 2
                    modalUpload,
                    uploadHistory,
                    selectedLicFile,
                    licFileInput,
                    openUploadModal,
                    triggerFileInput,
                    onLicFileChange,
                    submitUploadLic,
                    // Modal 3
                    modalUnlock,
                    selectedUnlockFile,
                    unlockFileInput,
                    openUnlockModal,
                    onUnlockFileChange,
                    submitUnlock
                };
            }
        }).mount('#app');
    </script>
</body>
</html>
