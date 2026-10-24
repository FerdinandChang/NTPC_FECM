<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Line.aspx.cs" Inherits="NTPC_FEC.LINE.Line" %>
<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定溢散源管理平台 - LINE 即時通報中心</title>

    <link rel="shortcut icon" href="../favicon.ico" type="image/x-icon" />

    <!-- 本地化樣式依賴 (符合機房資安隔離規範) -->
    <link rel="stylesheet" href="../Content/bootstrap.min.css" />
    <link rel="stylesheet" href="../Content/fontawesome/css/all.min.css" />

    <style type="text/css">
        :root {
            --brand-primary: #0099e5;     /* 新北天空青藍 */
            --brand-blue: #0284c7;        /* 科技藍 */
            --brand-dark-blue: #0b1f7d;   /* 海軍深藍 */
            --brand-navy: #0f172a;        /* 標題文字主色 */
            --bg-canvas: #f1f5f9;         /* 頁面灰底 */
            --surface: #ffffff;           /* 卡片純白底色 */
            --border-color: #e2e8f0;      /* 邊框線條 */
            --text-main: #0f172a;         /* 內文主要文字 */
            --text-muted: #64748b;        /* 次要說明文字 */
            --line-green: #06C755;        /* LINE 官方品牌綠 */
            --line-green-dark: #05a847;   /* LINE 官方深綠 */
            --line-green-light: #e8f9ef;  /* LINE 綠底淡色 */
        }

        * { box-sizing: border-box; -webkit-tap-highlight-color: transparent; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, "Noto Sans TC", "微軟正黑體", sans-serif;
            background-color: var(--bg-canvas);
            margin: 0; padding: 0;
            color: var(--text-main);
            overflow-x: hidden;
        }
        [v-cloak] { display: none !important; }

        /* 置頂深青藍漸層導覽列 */
        .top-navbar {
            background: linear-gradient(135deg, #0099e5 0%, #0284c7 100%);
            color: #ffffff;
            height: 58px;
            display: flex; align-items: center; justify-content: space-between;
            padding: 0 16px;
            box-shadow: 0 2px 10px rgba(0, 153, 229, 0.25);
            position: sticky; top: 0; z-index: 1020;
        }

        .top-navbar .brand-title {
            font-size: 1.08rem; font-weight: 700; margin: 0;
            display: flex; align-items: center; gap: 8px; color: #ffffff;
        }

        .nav-btn {
            background: rgba(255, 255, 255, 0.18);
            border: none; color: #ffffff;
            font-size: 0.9rem; font-weight: 600; cursor: pointer;
            height: 36px; border-radius: 8px;
            display: inline-flex; align-items: center; justify-content: center;
            padding: 0 12px; gap: 6px;
            transition: all 0.2s; text-decoration: none;
        }
        .nav-btn:hover { background-color: rgba(255, 255, 255, 0.32); color: #ffffff; text-decoration: none; }

        /* 主容器 */
        .container-fluid-custom {
            max-width: 1560px;
            margin: 0 auto;
            padding: 16px;
        }

        /* 桌面端左欄固頂 */
        @media screen and (min-width: 1200px) {
            .sticky-sidebar {
                position: sticky; top: 74px;
                max-height: calc(100vh - 90px);
                overflow-y: auto; padding-right: 4px;
            }
        }

        /* 現代卡片 */
        .card-modern {
            background: var(--surface);
            border-radius: 12px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05), 0 4px 12px rgba(15, 23, 42, 0.05);
            margin-bottom: 16px;
            border: 1px solid var(--border-color);
            overflow: hidden;
            transition: box-shadow 0.2s ease;
        }
        .card-modern-header {
            padding: 12px 16px;
            background: #ffffff;
            border-bottom: 1px solid var(--border-color);
            display: flex; align-items: center; justify-content: space-between;
        }
        .card-modern-title {
            font-size: 1rem; font-weight: 700; color: var(--brand-navy); margin: 0;
            display: flex; align-items: center; gap: 8px;
        }
        .card-modern-body { padding: 16px; }

        /* LINE 官方品牌特色卡片 */
        .card-line-brand {
            background: #ffffff;
            border-radius: 12px;
            border: 1px solid #bbf7d0;
            box-shadow: 0 4px 16px rgba(6, 199, 85, 0.12);
            overflow: hidden;
            margin-bottom: 16px;
        }
        .card-line-brand-header {
            background: linear-gradient(135deg, #06C755 0%, #05a847 100%);
            color: #ffffff;
            padding: 16px;
            display: flex;
            align-items: center;
            gap: 14px;
        }
        .line-avatar {
            width: 58px; height: 58px;
            border-radius: 50%;
            background: #ffffff;
            padding: 3px;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
            flex-shrink: 0;
        }
        .line-avatar img { width: 100%; height: 100%; border-radius: 50%; object-fit: cover; }
        .line-brand-info { flex: 1; min-width: 0; }
        .line-brand-name {
            font-size: 1.05rem; font-weight: 800; margin: 0 0 2px 0;
            display: flex; align-items: center; gap: 6px;
            line-height: 1.3;
        }
        .line-badge-verified {
            background: #ffffff; color: #06C755;
            font-size: 0.72rem; font-weight: 800;
            padding: 1px 6px; border-radius: 4px;
            display: inline-flex; align-items: center; gap: 3px;
        }
        .line-id-pill {
            font-size: 0.82rem; opacity: 0.95;
            display: flex; align-items: center; gap: 6px;
            color: #e8f9ef;
        }

        .btn-line-join {
            background: #06C755; color: #ffffff !important;
            font-weight: 700; font-size: 0.95rem;
            border-radius: 8px; border: none;
            padding: 10px 18px;
            display: inline-flex; align-items: center; justify-content: center; gap: 8px;
            width: 100%; text-decoration: none !important;
            box-shadow: 0 3px 10px rgba(6, 199, 85, 0.35);
            transition: all 0.2s;
        }
        .btn-line-join:hover {
            background: #05a847;
            transform: translateY(-1px);
            box-shadow: 0 5px 14px rgba(6, 199, 85, 0.45);
        }

        .btn-copy-id {
            background: #f1f5f9; color: #334155;
            font-weight: 600; font-size: 0.86rem;
            border-radius: 8px; border: 1px solid #cbd5e1;
            padding: 8px 14px;
            display: inline-flex; align-items: center; justify-content: center; gap: 6px;
            width: 100%; cursor: pointer; transition: all 0.2s;
        }
        .btn-copy-id:hover { background: #e2e8f0; color: #0f172a; }

        /* QR Code 視覺展示盒 */
        .qr-display-box {
            background: #f8fafc;
            border: 1px dashed #94a3b8;
            border-radius: 10px;
            padding: 12px;
            text-align: center;
        }
        .qr-display-box img {
            max-width: 160px; height: auto;
            border-radius: 8px;
            background: #ffffff;
            padding: 6px;
            box-shadow: 0 2px 6px rgba(0, 0, 0, 0.08);
            cursor: pointer;
            transition: transform 0.2s;
        }
        .qr-display-box img:hover { transform: scale(1.03); }

        /* 業務引導卡片 (Workflow Steps) */
        .workflow-step-item {
            display: flex; gap: 12px;
            padding: 10px 0;
            border-bottom: 1px dashed #e2e8f0;
        }
        .workflow-step-item:last-child { border-bottom: none; }
        .step-num-badge {
            width: 28px; height: 28px; border-radius: 50%;
            background: #e0f2fe; color: #0284c7;
            font-weight: 800; font-size: 13px;
            display: flex; align-items: center; justify-content: center;
            flex-shrink: 0;
        }
        .step-content-title { font-weight: 700; font-size: 0.9rem; margin-bottom: 2px; color: #1e293b; }
        .step-content-desc { font-size: 0.82rem; color: #64748b; margin: 0; line-height: 1.4; }

        /* 篩選標籤晶片群 (Tabs / Filter Chips) */
        .filter-chip-group { display: flex; flex-wrap: wrap; gap: 6px; }
        .filter-chip {
            border: 1px solid #cbd5e1; background: #ffffff; color: #475569;
            padding: 6px 12px; border-radius: 20px; font-size: 0.85rem; font-weight: 600;
            cursor: pointer; display: inline-flex; align-items: center; gap: 6px;
            transition: all 0.15s ease;
        }
        .filter-chip:hover { background: #f8fafc; border-color: #94a3b8; }
        .filter-chip.active {
            background: #0284c7; border-color: #0284c7; color: #ffffff;
            box-shadow: 0 2px 6px rgba(2, 132, 199, 0.3);
        }
        .filter-chip .chip-count {
            background: rgba(0, 0, 0, 0.08);
            border-radius: 10px; padding: 1px 7px; font-size: 0.75rem;
        }
        .filter-chip.active .chip-count {
            background: rgba(255, 255, 255, 0.25);
            color: #ffffff;
        }

        /* LINE 訊息流卡片 (Message Bubble Card) */
        .msg-feed-container { display: flex; flex-direction: column; gap: 14px; }
        .msg-card {
            background: #ffffff;
            border-radius: 12px;
            border: 1px solid var(--border-color);
            box-shadow: 0 2px 6px rgba(0, 0, 0, 0.04);
            overflow: hidden;
            transition: transform 0.15s, box-shadow 0.15s;
            position: relative;
        }
        .msg-card:hover {
            box-shadow: 0 4px 14px rgba(0, 0, 0, 0.08);
            transform: translateY(-2px);
        }

        /* 警示邊條裝飾 */
        .msg-card.severity-warning { border-left: 5px solid #f59e0b; }
        .msg-card.severity-danger { border-left: 5px solid #ef4444; }
        .msg-card.severity-success { border-left: 5px solid #10b981; }
        .msg-card.severity-info { border-left: 5px solid #0284c7; }

        .msg-card-header {
            padding: 12px 16px;
            background: #fafbfc;
            border-bottom: 1px solid #f1f5f9;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 10px;
        }
        .msg-card-title-group {
            display: flex; align-items: center; gap: 8px; flex-wrap: wrap; flex: 1;
        }
        .msg-card-title {
            font-size: 1rem; font-weight: 700; color: #0f172a; margin: 0;
            line-height: 1.4;
        }
        .msg-time-badge {
            font-size: 0.8rem; color: #64748b; white-space: nowrap;
            display: inline-flex; align-items: center; gap: 4px;
        }

        .msg-card-body { padding: 16px; }
        .msg-target-pill {
            display: inline-flex; align-items: center; gap: 6px;
            background: #f1f5f9; color: #475569;
            font-size: 0.78rem; font-weight: 600;
            padding: 3px 9px; border-radius: 6px; margin-bottom: 10px;
        }
        .msg-content-text {
            font-size: 0.94rem; line-height: 1.65; color: #334155;
            white-space: pre-wrap; word-break: break-word;
            margin: 0;
        }

        .msg-card-footer {
            padding: 10px 16px;
            background: #ffffff;
            border-top: 1px solid #f1f5f9;
            display: flex; align-items: center; justify-content: space-between;
            gap: 8px; flex-wrap: wrap;
        }
        .msg-action-btns { display: inline-flex; gap: 8px; }

        /* 自適應底部分頁列 (遵循 inspection-ui-standard) */
        .pagination-footer {
            background: #ffffff;
            border-top: 1px solid #e2e8f0;
            padding: 12px 16px;
            display: flex; flex-direction: column; align-items: center; gap: 10px;
            border-radius: 0 0 12px 12px;
        }
        @media (min-width: 768px) {
            .pagination-footer {
                flex-direction: row; justify-content: space-between;
                align-items: center; padding: 12px 20px; gap: 16px;
            }
        }
        .pagination-footer-info {
            font-size: 0.88rem; color: #64748b; text-align: center;
            white-space: nowrap !important;
        }
        @media (min-width: 768px) { .pagination-footer-info { text-align: left; } }
        .pagination-action-group {
            display: flex; align-items: center; justify-content: center;
            gap: 6px; width: 100%; max-width: 100%;
        }
        @media (min-width: 768px) {
            .pagination-action-group { width: auto; justify-content: flex-end; }
        }
        .btn-page-ctrl {
            display: inline-flex; align-items: center; justify-content: center;
            height: 38px; padding: 0 14px;
            font-size: 0.9rem; font-weight: 500; color: #334155;
            background: #ffffff; border: 1px solid #cbd5e1; border-radius: 8px;
            box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
            transition: all 0.15s ease-in-out;
            white-space: nowrap !important; text-decoration: none !important;
            user-select: none; touch-action: manipulation;
        }
        .btn-page-ctrl:hover:not(:disabled) {
            background: #f1f5f9; color: #0f172a; border-color: #94a3b8;
        }
        .btn-page-ctrl:active:not(:disabled) { background: #e2e8f0; transform: translateY(1px); }
        .btn-page-ctrl:disabled, .btn-page-ctrl.disabled {
            background: #f8fafc; color: #94a3b8; border-color: #e2e8f0;
            cursor: not-allowed; opacity: 0.55; box-shadow: none;
        }
        .page-indicator-pill {
            display: inline-flex; align-items: center; justify-content: center;
            height: 38px; padding: 0 12px;
            background: #f0fdf4; border: 1px solid #bbf7d0; border-radius: 8px;
            font-size: 0.88rem; font-weight: 700; color: #166534;
            white-space: nowrap !important;
        }
        @media (max-width: 767.98px) {
            .btn-page-ctrl.btn-step { flex: 1; min-width: 0; padding: 0 8px; }
            .btn-page-ctrl.btn-edge { width: 40px; min-width: 40px; padding: 0; flex-shrink: 0; }
            .page-indicator-pill { flex-shrink: 0; padding: 0 10px; font-size: 0.84rem; }
        }

        /* 浮動提示 Toast */
        .toast-container {
            position: fixed; bottom: 24px; right: 24px; z-index: 1060;
            display: flex; flex-direction: column; gap: 8px; pointer-events: none;
        }
        .custom-toast {
            background: rgba(15, 23, 42, 0.92); color: #ffffff;
            padding: 10px 18px; border-radius: 8px; font-size: 0.9rem; font-weight: 600;
            box-shadow: 0 4px 14px rgba(0, 0, 0, 0.2);
            pointer-events: auto; animation: toastIn 0.25s ease-out;
            display: flex; align-items: center; gap: 8px;
        }
        @keyframes toastIn {
            from { transform: translateY(15px); opacity: 0; }
            to { transform: translateY(0); opacity: 1; }
        }

        /* 模態彈窗微調 */
        .modal-header-custom {
            background: linear-gradient(135deg, #0099e5 0%, #0284c7 100%);
            color: #ffffff; border-radius: 11px 11px 0 0;
            padding: 14px 20px;
        }
        .modal-header-custom .close { color: #ffffff; opacity: 0.85; text-shadow: none; }
        .modal-header-custom .close:hover { opacity: 1; }

        /* 即時預覽氣泡 */
        .preview-bubble-box {
            background: #849ebf;
            border-radius: 10px;
            padding: 16px;
            max-height: 280px;
            overflow-y: auto;
        }
        .preview-bubble {
            background: #ffffff;
            border-radius: 12px;
            padding: 12px 14px;
            max-width: 90%;
            box-shadow: 0 2px 6px rgba(0, 0, 0, 0.15);
            font-size: 0.9rem;
        }

        /* ==========================================================================
           小尺寸與行動裝置全載具自適應 (Mobile / Small Screen RWD 極致優化)
           ========================================================================== */
        @media (max-width: 767.98px) {
            /* 1. 訊息卡片標頭與時間垂直堆疊，防止文字橫向互相擠壓破版 */
            .msg-card-header {
                flex-direction: column;
                align-items: flex-start;
                padding: 10px 12px;
                gap: 6px;
            }
            .msg-card-title-group {
                width: 100%;
                gap: 6px;
            }
            .msg-card-title {
                font-size: 0.94rem;
                width: 100%;
                margin-top: 2px;
            }
            .msg-time-badge {
                font-size: 0.78rem;
                color: #64748b;
                align-self: flex-start;
            }
            .msg-card-body {
                padding: 12px;
            }
            .msg-content-text {
                font-size: 0.88rem;
                line-height: 1.6;
            }
            /* 2. 訊息卡片底部動作按鈕滿寬排列，觸控友善 */
            .msg-card-footer {
                flex-direction: column;
                align-items: flex-start;
                padding: 10px 12px;
                gap: 8px;
            }
            .msg-action-btns {
                width: 100%;
                display: flex;
                justify-content: flex-end;
                gap: 6px;
            }
            .msg-action-btns .btn {
                flex: 1;
                padding: 5px 8px;
                font-size: 0.8rem;
                text-align: center;
                justify-content: center;
                white-space: nowrap;
            }

            /* 3. 篩選標籤群：支援平滑橫向滑動 (Touch Scroll) 不佔垂直高度 */
            .filter-chip-group {
                display: flex;
                flex-wrap: nowrap;
                overflow-x: auto;
                -webkit-overflow-scrolling: touch;
                padding-bottom: 6px;
                scrollbar-width: thin;
            }
            .filter-chip-group::-webkit-scrollbar {
                height: 4px;
            }
            .filter-chip-group::-webkit-scrollbar-thumb {
                background: #cbd5e1;
                border-radius: 4px;
            }
            .filter-chip {
                flex-shrink: 0;
                font-size: 0.82rem;
                padding: 5px 12px;
                white-space: nowrap;
            }
        }

        @media (max-width: 575.98px) {
            /* 4. 頂部導覽列緊湊適應 (iPhone / 小手機尺寸) */
            .top-navbar {
                height: 52px;
                padding: 0 10px;
            }
            .top-navbar .brand-title {
                font-size: 0.95rem;
                gap: 4px;
            }
            .top-navbar .nav-btn {
                height: 32px;
                padding: 0 8px;
                font-size: 0.8rem;
            }
            .btn-clear-sample {
                padding: 4px 8px !important;
                font-size: 0.8rem !important;
                white-space: nowrap;
            }

            /* 5. 容器與邊距極致收斂，杜絕橫向滾動 */
            .container-fluid-custom {
                padding: 10px 8px;
            }
            .card-modern {
                border-radius: 10px;
                margin-bottom: 12px;
            }
            .card-modern-header {
                padding: 10px 12px;
            }
            .card-modern-title {
                font-size: 0.92rem;
            }
            .card-modern-body {
                padding: 12px 10px;
            }

            /* 6. LINE 官方帳號品牌卡片在小手機緊湊呈現 */
            .card-line-brand {
                margin-bottom: 12px;
                border-radius: 10px;
            }
            .card-line-brand-header {
                padding: 12px 10px;
                gap: 10px;
            }
            .line-avatar {
                width: 46px;
                height: 46px;
                padding: 2px;
            }
            .line-brand-name {
                font-size: 0.92rem;
                line-height: 1.35;
                word-break: break-all;
            }
            .line-badge-verified {
                font-size: 0.68rem;
                padding: 1px 4px;
            }
            .line-id-pill {
                font-size: 0.74rem;
            }
            .btn-line-join {
                font-size: 0.88rem;
                padding: 8px 12px;
            }
            .btn-copy-id {
                font-size: 0.78rem;
                padding: 6px 8px;
            }
            .qr-display-box {
                padding: 10px 8px;
            }
            .qr-display-box img {
                max-width: 120px;
            }

            /* 7. 表單元件文字縮放防破版 */
            .form-control {
                font-size: 0.85rem;
                height: calc(1.5em + 0.75rem + 2px);
            }
            .input-group-text {
                font-size: 0.85rem;
                padding: 0.375rem 0.5rem;
            }

            /* 8. 分頁條在小螢幕高度緊湊適應 */
            .pagination-footer {
                padding: 10px 6px;
                gap: 8px;
            }
            .pagination-footer-info {
                font-size: 0.78rem;
            }
            .pagination-action-group {
                gap: 4px;
            }
            .btn-page-ctrl {
                height: 34px;
                font-size: 0.78rem;
            }
            .btn-page-ctrl.btn-step {
                padding: 0 6px;
            }
            .btn-page-ctrl.btn-edge {
                width: 32px;
                min-width: 32px;
            }
            .page-indicator-pill {
                height: 34px;
                padding: 0 6px;
                font-size: 0.78rem;
            }

            /* 9. 浮動 Toast 靠中防溢出 */
            .toast-container {
                left: 12px;
                right: 12px;
                bottom: 16px;
            }
            .custom-toast {
                font-size: 0.84rem;
                padding: 8px 14px;
            }
        }
    </style>
</head>
<body>
    <div id="lineApp" v-cloak>
        <!-- 頂部深青藍導覽列 (Sticky Top Navbar) -->
        <header class="top-navbar">
            <div class="brand-title">
                <a href="../MainPage.aspx" class="nav-btn mr-1" title="返回主選單">
                    <i class="fas fa-home"></i>
                    <span class="d-none d-sm-inline">回首頁</span>
                </a>
                <div class="d-flex align-items-center ml-1 brand-title-text">
                    <i class="fab fa-line text-white mr-1" style="font-size: 1.3rem;"></i>
                    <span class="font-weight-bold d-none d-sm-inline">LINE 即時通報中心</span>
                    <span class="font-weight-bold d-inline d-sm-none">LINE 即時通報</span>
                    <span class="badge badge-light text-dark font-weight-bold ml-2 d-none d-md-inline" style="font-size: 0.82rem;">
                        {{ stats.TotalCount }} 則
                    </span>
                </div>
            </div>

            <!-- 右側動作區：依指示僅保留「清空範本」按鈕 -->
            <div class="d-flex align-items-center">
                <button type="button" class="btn btn-sm btn-outline-light font-weight-bold shadow-sm btn-clear-sample" v-on:click="clearSamples" title="一鍵清空系統預載之示範推播訊息">
                    <i class="fas fa-eraser mr-1"></i>
                    <span>清空範本</span>
                </button>
            </div>
        </header>

        <!-- 主作業容器 -->
        <main class="container-fluid-custom">
            <!-- 業務引導提示列 -->
            <div class="alert alert-primary shadow-sm border-0 d-flex align-items-center justify-content-between p-3 mb-3" style="border-radius: 10px; background-color: #e0f2fe; color: #0369a1;">
                <div class="d-flex align-items-center">
                    <i class="fas fa-broadcast-tower fa-2x mr-3 text-primary d-none d-sm-block"></i>
                    <div>
                        <div class="font-weight-bold" style="font-size: 0.96rem;">新北市固定污染源空品不良預警應變推播機制</div>
                        <small class="d-block" style="color: #0c4a6e;">
                            當本市測站達橘色提醒或啟動應變作為時，系統將透過 LINE 官方帳號同步推播至各公私場所負責人與環保專責人員手機，請即刻依規執行自主抑塵並於時限內完成線上申報。
                        </small>
                    </div>
                </div>
                <div class="d-none d-lg-block">
                    <span v-if="initData.UserFacName" class="badge badge-primary px-3 py-2" style="font-size: 0.88rem;">
                        <i class="fas fa-building mr-1"></i>{{ initData.UserFacName }}
                    </span>
                </div>
            </div>

            <!-- 全載具雙欄排版 -->
            <div class="row">
                <!-- 左欄：官方帳號導流與應變工作流 (Desktop 40%, Mobile 100%) -->
                <div class="col-12 col-xl-4 col-lg-5">
                    <div class="sticky-sidebar">
                        <!-- LINE 官方帳號綠色品牌卡片 -->
                        <div class="card-line-brand">
                            <div class="card-line-brand-header">
                                <div class="line-avatar">
                                    <img :src="official.LogoUrl" alt="LINE Official Logo" />
                                </div>
                                <div class="line-brand-info">
                                    <div class="line-brand-name">
                                        <span>{{ official.AccountName }}</span>
                                    </div>
                                    <div class="d-flex align-items-center gap-2 mt-1">
                                        <span class="line-badge-verified">
                                            <i class="fas fa-check-circle"></i> 官方認證
                                        </span>
                                        <span class="line-id-pill">
                                            ID: <strong>{{ official.LineId }}</strong>
                                        </span>
                                    </div>
                                </div>
                            </div>

                            <div class="card-modern-body">
                                <p class="text-muted small mb-3" style="line-height: 1.5;">
                                    {{ official.Description }}
                                </p>

                                <div class="row mb-3">
                                    <div class="col-12 mb-2">
                                        <a :href="official.LineJoinUrl" target="_blank" class="btn-line-join">
                                            <i class="fab fa-line fa-lg"></i>
                                            <span>一鍵點擊加入 LINE 好友</span>
                                        </a>
                                    </div>
                                    <div class="col-6 pr-1">
                                        <button type="button" class="btn-copy-id" v-on:click="copyText(official.LineId, '官方帳號 ID 已複製！')">
                                            <i class="fas fa-copy text-primary"></i> 複製 ID
                                        </button>
                                    </div>
                                    <div class="col-6 pl-1">
                                        <button type="button" class="btn-copy-id" v-on:click="copyText(official.LineJoinUrl, '官方好友連結已複製！')">
                                            <i class="fas fa-link text-info"></i> 複製連結
                                        </button>
                                    </div>
                                </div>

                                <!-- QR Code 快速掃描框 -->
                                <div class="qr-display-box">
                                    <div class="small font-weight-bold text-dark mb-2">
                                        <i class="fas fa-qrcode mr-1 text-success"></i> 外勤與業者現場手機掃描加好友
                                    </div>
                                    <img :src="official.QrCodeUrl" alt="QR Code" v-on:click="openQrModal" title="點擊放大 QR Code" />
                                    <div class="small text-muted mt-2">
                                        拿起手機開啟相機或 LINE 掃描器即可秒加入
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- 空品應變閉環三部曲卡片 -->
                        <div class="card-modern">
                            <div class="card-modern-header">
                                <h3 class="card-modern-title">
                                    <i class="fas fa-route text-primary"></i> 空品應變標準作業流程
                                </h3>
                            </div>
                            <div class="card-modern-body p-3">
                                <div class="workflow-step-item">
                                    <div class="step-num-badge">1</div>
                                    <div>
                                        <div class="step-content-title">接收 LINE 即時預警推播</div>
                                        <p class="step-content-desc">當 AQI > 100 達橘色提醒或啟動應變作為，LINE 官方帳號與系統同步推播。</p>
                                    </div>
                                </div>

                                <div class="workflow-step-item">
                                    <div class="step-num-badge">2</div>
                                    <div>
                                        <div class="step-content-title">啟動廠區現場自主防制減量</div>
                                        <p class="step-content-desc">查核洗車台泥砂沉澱清淤、提高出入口及周邊道路灑水頻率、防制設備正常運作。</p>
                                    </div>
                                </div>

                                <div class="workflow-step-item">
                                    <div class="step-num-badge">3</div>
                                    <div>
                                        <div class="step-content-title">線上申報應變成果紀錄</div>
                                        <p class="step-content-desc">於當日規定期限內完成「空品不良自主管理回報」，上傳減量作為與現場抑塵成果。</p>
                                    </div>
                                </div>

                                <div class="mt-3 pt-2">
                                    <a href="../OwnReport/Report_AirQuality.aspx?mode=new" class="btn btn-primary btn-block font-weight-bold shadow-sm py-2">
                                        <i class="fas fa-paper-plane mr-1"></i> 前往填寫空品應變回報
                                    </a>
                                </div>
                            </div>
                        </div>

                        <!-- 近期預警推播日期快捷標籤 -->
                        <div v-if="initData.RecentAlertDates && initData.RecentAlertDates.length > 0" class="card-modern">
                            <div class="card-modern-header">
                                <h3 class="card-modern-title" style="font-size: 0.95rem;">
                                    <i class="far fa-calendar-alt text-warning"></i> 近期通報預警日期快捷查詢
                                </h3>
                            </div>
                            <div class="card-modern-body p-3">
                                <div class="d-flex flex-wrap gap-2">
                                    <button v-for="d in initData.RecentAlertDates" :key="d" type="button" 
                                            class="btn btn-sm btn-outline-secondary font-weight-bold"
                                            :class="{ 'btn-info text-white': filters.dateStart === d && filters.dateEnd === d }"
                                            v-on:click="filterByDate(d)">
                                        <i class="fas fa-calendar-day mr-1"></i>{{ d }}
                                    </button>
                                    <button v-if="filters.dateStart || filters.dateEnd" type="button" class="btn btn-sm btn-outline-danger" v-on:click="clearDateFilter">
                                        <i class="fas fa-times mr-1"></i>清除日期
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- 右欄：多條件篩選與推播訊息流 (Desktop 60%, Mobile 100%) -->
                <div class="col-12 col-xl-8 col-lg-7">
                    <!-- 複合多條件篩選卡片 -->
                    <div class="card-modern">
                        <div class="card-modern-header" style="cursor: pointer;" v-on:click="filterCollapsed = !filterCollapsed">
                            <h3 class="card-modern-title">
                                <i class="fas fa-filter text-primary"></i> 訊息分類與檢索條件
                            </h3>
                            <div>
                                <i class="fas" :class="filterCollapsed ? 'fa-chevron-down' : 'fa-chevron-up'"></i>
                            </div>
                        </div>

                        <div v-show="!filterCollapsed" class="card-modern-body">
                            <!-- 訊息類型快捷 Chips -->
                            <div class="mb-3">
                                <label class="small font-weight-bold text-muted d-block mb-2">訊息類別篩選：</label>
                                <div class="filter-chip-group">
                                    <button type="button" class="filter-chip" :class="{ 'active': filters.msgType === 'ALL' }" v-on:click="setMsgType('ALL')">
                                        <span>全部訊息</span>
                                        <span class="chip-count">{{ stats.TotalCount }}</span>
                                    </button>
                                    <button type="button" class="filter-chip" :class="{ 'active': filters.msgType === 'WARN' }" v-on:click="setMsgType('WARN')">
                                        <i class="fas fa-exclamation-triangle text-warning"></i>
                                        <span>空品預警</span>
                                        <span class="chip-count">{{ stats.WarnCount }}</span>
                                    </button>
                                    <button type="button" class="filter-chip" :class="{ 'active': filters.msgType === 'ACTION' }" v-on:click="setMsgType('ACTION')">
                                        <i class="fas fa-bolt text-danger"></i>
                                        <span>應變措施</span>
                                        <span class="chip-count">{{ stats.ActionCount }}</span>
                                    </button>
                                    <button type="button" class="filter-chip" :class="{ 'active': filters.msgType === 'CLEAR' }" v-on:click="setMsgType('CLEAR')">
                                        <i class="fas fa-check-circle text-success"></i>
                                        <span>解除通報</span>
                                        <span class="chip-count">{{ stats.ClearCount }}</span>
                                    </button>
                                    <button type="button" class="filter-chip" :class="{ 'active': filters.msgType === 'INFO' }" v-on:click="setMsgType('INFO')">
                                        <i class="fas fa-info-circle text-info"></i>
                                        <span>宣導指引</span>
                                        <span class="chip-count">{{ stats.InfoCount }}</span>
                                    </button>
                                </div>
                            </div>

                            <!-- 關鍵字與日期範圍 -->
                            <div class="form-row">
                                <div class="col-md-6 mb-2">
                                    <label class="small font-weight-bold text-muted">關鍵字搜尋：</label>
                                    <div class="input-group">
                                        <div class="input-group-prepend">
                                            <span class="input-group-text"><i class="fas fa-search text-muted"></i></span>
                                        </div>
                                        <input type="text" class="form-control" v-model="filters.keyword" placeholder="搜尋標題、內文或發送對象..." v-on:keyup.enter="handleSearch" />
                                    </div>
                                </div>
                                <div class="col-md-3 col-6 mb-2">
                                    <label class="small font-weight-bold text-muted">發送起始日：</label>
                                    <input type="date" class="form-control" v-model="filters.dateStart" />
                                </div>
                                <div class="col-md-3 col-6 mb-2">
                                    <label class="small font-weight-bold text-muted">發送截止日：</label>
                                    <input type="date" class="form-control" v-model="filters.dateEnd" />
                                </div>
                            </div>

                            <!-- 篩選列底部操作 -->
                            <div class="d-flex align-items-center justify-content-between pt-2 border-top mt-2">
                                <div class="small text-muted">
                                    共查詢到 <strong class="text-primary">{{ totalCount }}</strong> 筆符合推播
                                </div>
                                <div>
                                    <button type="button" class="btn btn-sm btn-outline-secondary mr-2" v-on:click="resetFilters">
                                        <i class="fas fa-undo mr-1"></i>重設條件
                                    </button>
                                    <button type="button" class="btn btn-sm btn-primary px-3" v-on:click="handleSearch">
                                        <i class="fas fa-search mr-1"></i>立即查詢
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- 推播訊息列表卡片 -->
                    <div class="card-modern">
                        <div class="card-modern-header">
                            <h3 class="card-modern-title">
                                <i class="fab fa-line text-success"></i> 近日推播訊息列表
                            </h3>
                            <div class="d-flex align-items-center">
                                <span class="small text-muted mr-2 d-none d-sm-inline">每頁</span>
                                <select class="custom-select custom-select-sm mr-2" style="width: auto;" v-model="pageSize" v-on:change="handlePageSizeChange">
                                    <option :value="10">10 筆</option>
                                    <option :value="15">15 筆</option>
                                    <option :value="30">30 筆</option>
                                    <option :value="50">50 筆</option>
                                </select>
                                <button type="button" class="btn btn-sm btn-outline-secondary" v-on:click="fetchList" :disabled="loading" title="重新整理">
                                    <i class="fas fa-sync-alt" :class="{ 'fa-spin': loading }"></i>
                                    <span class="d-none d-md-inline ml-1">重新整理</span>
                                </button>
                            </div>
                        </div>

                        <!-- 訊息流主區域 -->
                        <div class="card-modern-body p-3">
                            <!-- 載入中狀態 -->
                            <div v-if="loading" class="text-center py-5">
                                <i class="fas fa-circle-notch fa-spin fa-2x text-primary mb-2"></i>
                                <div class="text-muted font-weight-bold">正在取得最新 LINE 推播訊息...</div>
                            </div>

                            <!-- 空資料提示 -->
                            <div v-else-if="items.length === 0" class="text-center py-5">
                                <div class="mb-3">
                                    <i class="far fa-bell-slash fa-3x text-muted" style="opacity: 0.4;"></i>
                                </div>
                                <h5 class="text-secondary font-weight-bold">目前無符合條件之推播訊息</h5>
                                <p class="text-muted small">請嘗試放寬查詢條件、清除關鍵字或選擇其他分類標籤。</p>
                                <button type="button" class="btn btn-sm btn-outline-primary" v-on:click="resetFilters">
                                    <i class="fas fa-undo mr-1"></i>重設查詢條件
                                </button>
                            </div>

                            <!-- 訊息氣泡列表 -->
                            <div v-else class="msg-feed-container">
                                <div v-for="msg in items" :key="msg.Msg_ID" class="msg-card" :class="'severity-' + msg.Severity">
                                    <div class="msg-card-header">
                                        <div class="msg-card-title-group">
                                            <!-- 置頂標籤 -->
                                            <span v-if="msg.Is_Pinned" class="badge badge-warning text-dark font-weight-bold">
                                                <i class="fas fa-thumbtack mr-1"></i>置頂
                                            </span>

                                            <!-- 類型彩色標籤 -->
                                            <span class="badge" :class="getSeverityBadgeClass(msg.Severity)">
                                                {{ msg.Msg_Type_Str }}
                                            </span>

                                            <!-- 示範資料徽章標記 -->
                                            <span v-if="isSample(msg)" class="badge badge-secondary" title="系統初始預載之示範推播，管理員可一鍵清空">
                                                示範資料
                                            </span>

                                            <!-- 訊息標題 -->
                                            <h4 class="msg-card-title">{{ msg.Title }}</h4>
                                        </div>

                                        <!-- 推播時間 -->
                                        <div class="msg-time-badge" :title="'發布時間：' + msg.Send_Date">
                                            <i class="far fa-clock"></i>
                                            <strong>{{ msg.RelativeTime }}</strong>
                                            <span class="d-none d-md-inline text-muted">({{ msg.Send_Date }})</span>
                                        </div>
                                    </div>

                                    <div class="msg-card-body">
                                        <!-- 發布對象標籤 -->
                                        <div class="msg-target-pill">
                                            <i class="fas fa-bullhorn text-primary"></i>
                                            <span>發送對象：{{ msg.Target_Role }}</span>
                                        </div>

                                        <!-- 訊息內文 -->
                                        <p class="msg-content-text">{{ msg.Send_Txt }}</p>
                                    </div>

                                    <div class="msg-card-footer">
                                        <div class="small text-muted">
                                            <i class="fas fa-user-shield mr-1"></i>發布單位：{{ msg.Create_User || '新北市環保局' }}
                                        </div>
                                        <div class="msg-action-btns">
                                            <button type="button" class="btn btn-sm btn-outline-secondary" v-on:click="copyText(msg.Send_Txt, '推播內文已複製！')">
                                                <i class="fas fa-copy mr-1"></i>複製內文
                                            </button>

                                            <!-- 附帶快捷連結 -->
                                            <a v-if="msg.Action_Url" :href="'../' + msg.Action_Url" class="btn btn-sm btn-primary">
                                                <i class="fas fa-external-link-alt mr-1"></i>前往應變
                                            </a>

                                            <!-- 管理員刪除按鈕 -->
                                            <button v-if="initData.IsManager" type="button" class="btn btn-sm btn-outline-danger" v-on:click="confirmDelete(msg)">
                                                <i class="fas fa-trash-alt mr-1"></i>刪除
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- 自適應底部分頁列 (Responsive Pagination Footer) -->
                        <div v-if="!loading && totalCount > 0" class="pagination-footer">
                            <div class="pagination-footer-info">
                                顯示第 <strong class="text-dark">{{ (pageIndex - 1) * pageSize + 1 }}</strong> 至 
                                <strong class="text-dark">{{ Math.min(pageIndex * pageSize, totalCount) }}</strong> 筆，共 
                                <strong class="text-dark">{{ totalCount }}</strong> 筆
                            </div>
                            <div class="pagination-action-group">
                                <button type="button" class="btn-page-ctrl btn-edge" :disabled="pageIndex <= 1" v-on:click="goToPage(1)" title="第一頁">
                                    <i class="fas fa-angle-double-left"></i>
                                    <span class="d-none d-md-inline ml-1">首頁</span>
                                </button>
                                <button type="button" class="btn-page-ctrl btn-step" :disabled="pageIndex <= 1" v-on:click="goToPage(pageIndex - 1)" title="上一頁">
                                    <i class="fas fa-chevron-left mr-1"></i>
                                    <span>上一頁</span>
                                </button>
                                <div class="page-indicator-pill" title="目前頁次 / 總頁數">
                                    <span>{{ pageIndex }}</span>
                                    <span class="mx-1 text-muted" style="opacity: 0.5; font-weight: normal;">/</span>
                                    <span>{{ totalPages }}</span>
                                </div>
                                <button type="button" class="btn-page-ctrl btn-step" :disabled="pageIndex >= totalPages" v-on:click="goToPage(pageIndex + 1)" title="下一頁">
                                    <span>下一頁</span>
                                    <i class="fas fa-chevron-right ml-1"></i>
                                </button>
                                <button type="button" class="btn-page-ctrl btn-edge" :disabled="pageIndex >= totalPages" v-on:click="goToPage(totalPages)" title="最後一頁">
                                    <span class="d-none d-md-inline ml-1">末頁</span>
                                    <i class="fas fa-angle-double-right"></i>
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </main>

        <!-- 管理員發布推播模態窗 (Modal) -->
        <div class="modal fade" id="postModal" tabindex="-1" role="dialog" aria-hidden="true">
            <div class="modal-dialog modal-lg modal-dialog-centered" role="document">
                <div class="modal-content shadow-lg border-0" style="border-radius: 12px; overflow: hidden;">
                    <div class="modal-header modal-header-custom">
                        <h5 class="modal-title font-weight-bold text-white">
                            <i class="fas fa-paper-plane mr-2"></i>發布空品不良 LINE 推播通知
                        </h5>
                        <button type="button" class="close text-white" data-dismiss="modal" aria-label="Close">
                            <span aria-hidden="true">&times;</span>
                        </button>
                    </div>
                    <div class="modal-body p-4">
                        <div class="form-group">
                            <label class="font-weight-bold text-dark"><span class="text-danger">*</span> 推播標題：</label>
                            <input type="text" class="form-control" v-model="newMsg.Title" placeholder="例如：【空品不良預警】八里測站達橘色提醒，請啟動自主減量" />
                        </div>

                        <div class="form-row">
                            <div class="col-md-6 form-group">
                                <label class="font-weight-bold text-dark">訊息分類：</label>
                                <select class="form-control" v-model="newMsg.MsgType" v-on:change="onNewMsgTypeChange">
                                    <option value="WARN">空品不良預警</option>
                                    <option value="ACTION">應變措施啟動</option>
                                    <option value="INFO">防制設施指引</option>
                                    <option value="CLEAR">應變作為解除</option>
                                </select>
                            </div>
                            <div class="col-md-6 form-group">
                                <label class="font-weight-bold text-dark">警示程度：</label>
                                <select class="form-control" v-model="newMsg.Severity">
                                    <option value="warning">橘色提醒 (Warning)</option>
                                    <option value="danger">紅色警示 (Danger)</option>
                                    <option value="info">一般資訊 (Info)</option>
                                    <option value="success">良好解除 (Success)</option>
                                </select>
                            </div>
                        </div>

                        <div class="form-row">
                            <div class="col-md-8 form-group">
                                <label class="font-weight-bold text-dark">發送對象描述：</label>
                                <input type="text" class="form-control" v-model="newMsg.TargetRole" placeholder="例如：新北市全體列管公私場所及營建工地" />
                            </div>
                            <div class="col-md-4 form-group d-flex align-items-center pt-3">
                                <div class="custom-control custom-checkbox">
                                    <input type="checkbox" class="custom-control-input" id="chkPinned" v-model="newMsg.IsPinned" />
                                    <label class="custom-control-label font-weight-bold text-dark" for="chkPinned">設定為重要置頂</label>
                                </div>
                            </div>
                        </div>

                        <div class="form-group">
                            <label class="font-weight-bold text-dark"><span class="text-danger">*</span> 推播內文：</label>
                            <textarea class="form-control" rows="5" v-model="newMsg.SendTxt" placeholder="請輸入欲發送給公私場所之詳細應變指令、預警指標與減量作為說明..."></textarea>
                        </div>

                        <div class="form-group">
                            <label class="font-weight-bold text-dark">關聯動作網址 (選填，點擊按鈕直接跳轉)：</label>
                            <div class="input-group">
                                <input type="text" class="form-control" v-model="newMsg.ActionUrl" placeholder="例如：OwnReport/Report_AirQuality.aspx?mode=new" />
                                <div class="input-group-append">
                                    <button type="button" class="btn btn-outline-secondary" v-on:click="newMsg.ActionUrl = 'OwnReport/Report_AirQuality.aspx?mode=new'">
                                        帶入應變回報
                                    </button>
                                </div>
                            </div>
                        </div>

                        <!-- 即時預覽氣泡 -->
                        <div class="form-group mb-0">
                            <label class="font-weight-bold text-muted small">發送效果即時預覽：</label>
                            <div class="preview-bubble-box">
                                <div class="preview-bubble">
                                    <div class="d-flex align-items-center mb-1">
                                        <img :src="official.LogoUrl" style="width: 20px; height: 20px; border-radius: 50%;" class="mr-1" />
                                        <strong style="color: #06C755; font-size: 0.8rem;">新北空品不良應變通報</strong>
                                        <span class="badge badge-secondary ml-auto" style="font-size: 0.7rem;">剛剛</span>
                                    </div>
                                    <div class="font-weight-bold text-dark mb-1">{{ newMsg.Title || '【標題預覽】' }}</div>
                                    <div class="small text-muted mb-2" style="white-space: pre-wrap;">{{ newMsg.SendTxt || '（內文預覽）' }}</div>
                                    <div v-if="newMsg.ActionUrl" class="text-center pt-1 border-top">
                                        <span class="badge badge-primary px-3 py-1">前往線上應變申報</span>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="modal-footer bg-light">
                        <button type="button" class="btn btn-secondary font-weight-bold" data-dismiss="modal">取消</button>
                        <button type="button" class="btn btn-success font-weight-bold px-4" v-on:click="submitNewMsg" :disabled="submitting">
                            <i class="fas fa-paper-plane mr-1"></i>{{ submitting ? '發布中...' : '確認發布推播' }}
                        </button>
                    </div>
                </div>
            </div>
        </div>

        <!-- QR Code 放大展示模態窗 -->
        <div class="modal fade" id="qrModal" tabindex="-1" role="dialog" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered text-center" role="document" style="max-width: 380px;">
                <div class="modal-content shadow-lg border-0" style="border-radius: 16px; overflow: hidden;">
                    <div class="modal-header modal-header-custom justify-content-center">
                        <h5 class="modal-title font-weight-bold text-white">
                            <i class="fab fa-line mr-2"></i>官方帳號好友 QR Code
                        </h5>
                        <button type="button" class="close text-white position-absolute" style="right: 15px;" data-dismiss="modal" aria-label="Close">
                            <span aria-hidden="true">&times;</span>
                        </button>
                    </div>
                    <div class="modal-body p-4">
                        <div class="mb-3">
                            <img :src="official.LogoUrl" style="width: 48px; height: 48px; border-radius: 50%;" class="shadow-sm" />
                            <div class="font-weight-bold text-dark mt-2">{{ official.AccountName }}</div>
                            <div class="text-muted small">LINE ID: <strong>{{ official.LineId }}</strong></div>
                        </div>
                        <div class="p-3 bg-light rounded-lg border mb-3">
                            <img :src="official.QrCodeUrl" alt="QR Code Large" style="width: 220px; height: 220px; object-fit: contain;" />
                        </div>
                        <p class="text-muted small mb-0">請開啟手機 LINE App「加入好友」以相機對準條碼進行掃描</p>
                    </div>
                    <div class="modal-footer bg-light justify-content-center">
                        <button type="button" class="btn btn-outline-secondary font-weight-bold" data-dismiss="modal">關閉</button>
                        <button type="button" class="btn btn-outline-primary font-weight-bold" v-on:click="downloadQr">
                            <i class="fas fa-download mr-1"></i>下載 QR Code
                        </button>
                        <button type="button" class="btn btn-success font-weight-bold" v-on:click="copyText(official.LineJoinUrl, '加入好友連結已複製！')">
                            <i class="fas fa-link mr-1"></i>複製加入連結
                        </button>
                    </div>
                </div>
            </div>
        </div>

        <!-- 浮動 Toast 提示 -->
        <div class="toast-container">
            <div v-for="t in toasts" :key="t.id" class="custom-toast">
                <i :class="t.icon"></i>
                <span>{{ t.text }}</span>
            </div>
        </div>
    </div>

    <!-- 本地靜態 JS 依賴 (符合機房資安規範) -->
    <script src="../Scripts/jquery.min.js"></script>
    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>
    <script src="../Scripts/bootstrap.bundle.min.js"></script>
    <script src="../Scripts/qrcode.min.js"></script>

    <script type="text/javascript">
        (function () {
            const { createApp } = Vue;

            createApp({
                data() {
                    return {
                        loading: false,
                        submitting: false,
                        filterCollapsed: false,
                        initData: {
                            IsManager: false,
                            CanPost: false,
                            CurrentUser: '',
                            UserFacId: '',
                            UserFacName: '',
                            RecentAlertDates: []
                        },
                        official: {
                            AccountName: '【新北空品不良應變通報】Line官方帳號',
                            LineId: '@ntpc_air',
                            LineJoinUrl: 'https://lin.ee/tI5cnOa',
                            QrCodeUrl: '../images/LINE_QR.png',
                            LogoUrl: '../images/LINEACC_LOGO.png',
                            Description: '加入官方帳號可第一時間獲取新北市最新空氣品質預警、各階段應變啟動通報，並提供固定污染源自主申報線上直達功能。'
                        },
                        stats: {
                            TotalCount: 0,
                            WarnCount: 0,
                            ActionCount: 0,
                            ClearCount: 0,
                            InfoCount: 0
                        },
                        filters: {
                            keyword: '',
                            msgType: 'ALL',
                            dateStart: '',
                            dateEnd: ''
                        },
                        items: [],
                        pageIndex: 1,
                        pageSize: 10,
                        totalCount: 0,
                        totalPages: 1,
                        newMsg: {
                            Title: '',
                            MsgType: 'WARN',
                            MsgTypeStr: '空品不良預警',
                            Severity: 'warning',
                            TargetRole: '新北市全體列管公私場所及營建工地',
                            IsPinned: false,
                            SendTxt: '',
                            ActionUrl: 'OwnReport/Report_AirQuality.aspx?mode=new'
                        },
                        toasts: []
                    };
                },
                mounted() {
                    this.loadInitData();
                    this.fetchList();
                },
                methods: {
                    showToast(text, icon) {
                        const id = Date.now() + Math.random();
                        this.toasts.push({
                            id: id,
                            text: text,
                            icon: icon || 'fas fa-check-circle text-success'
                        });
                        setTimeout(() => {
                            this.toasts = this.toasts.filter(t => t.id !== id);
                        }, 2800);
                    },
                    copyText(text, successMsg) {
                        if (!text) return;
                        if (navigator.clipboard && window.isSecureContext) {
                            navigator.clipboard.writeText(text).then(() => {
                                this.showToast(successMsg || '複製成功！', 'fas fa-check-circle text-success');
                            }).catch(() => {
                                this.fallbackCopyText(text, successMsg);
                            });
                        } else {
                            this.fallbackCopyText(text, successMsg);
                        }
                    },
                    fallbackCopyText(text, successMsg) {
                        const ta = document.createElement('textarea');
                        ta.value = text;
                        ta.style.position = 'fixed';
                        ta.style.left = '-9999px';
                        document.body.appendChild(ta);
                        ta.focus();
                        ta.select();
                        try {
                            document.execCommand('copy');
                            this.showToast(successMsg || '複製成功！', 'fas fa-check-circle text-success');
                        } catch (err) {
                            alert('複製失敗，請手動複製文字：' + text);
                        }
                        document.body.removeChild(ta);
                    },
                    loadInitData() {
                        axios.get('Line.aspx?action=getinitdata')
                            .then(res => {
                                if (res.data && res.data.Success && res.data.Data) {
                                    const d = res.data.Data;
                                    this.initData = d;
                                    if (d.OfficialAccount) {
                                        this.official = d.OfficialAccount;
                                    }
                                    if (d.Stats) {
                                        this.stats = d.Stats;
                                    }
                                }
                            })
                            .catch(err => {
                                console.error('取得初始資料異常：', err);
                            });
                    },
                    fetchList() {
                        this.loading = true;
                        const params = {
                            action: 'getmessages',
                            keyword: this.filters.keyword,
                            msgType: this.filters.msgType,
                            dateStart: this.filters.dateStart,
                            dateEnd: this.filters.dateEnd,
                            pageIndex: this.pageIndex,
                            pageSize: this.pageSize
                        };

                        axios.get('Line.aspx', { params: params })
                            .then(res => {
                                this.loading = false;
                                if (res.data && res.data.Success && res.data.Data) {
                                    const d = res.data.Data;
                                    this.items = d.Items || [];
                                    this.totalCount = d.TotalCount || 0;
                                    this.pageIndex = d.PageIndex || 1;
                                    this.pageSize = d.PageSize || 10;
                                    this.totalPages = d.TotalPages || 1;
                                    if (d.Stats) {
                                        this.stats = d.Stats;
                                    }
                                } else {
                                    this.showToast(res.data ? res.data.Message : '載入推播資料失敗', 'fas fa-exclamation-circle text-danger');
                                }
                            })
                            .catch(err => {
                                this.loading = false;
                                console.error('查詢推播訊息失敗：', err);
                                this.showToast('網路連線失敗或伺服器異常', 'fas fa-exclamation-circle text-danger');
                            });
                    },
                    handleSearch() {
                        this.pageIndex = 1;
                        this.fetchList();
                    },
                    resetFilters() {
                        this.filters.keyword = '';
                        this.filters.msgType = 'ALL';
                        this.filters.dateStart = '';
                        this.filters.dateEnd = '';
                        this.pageIndex = 1;
                        this.fetchList();
                        this.showToast('已重設篩選條件', 'fas fa-info-circle text-info');
                    },
                    setMsgType(type) {
                        this.filters.msgType = type;
                        this.pageIndex = 1;
                        this.fetchList();
                    },
                    filterByDate(dateStr) {
                        this.filters.dateStart = dateStr;
                        this.filters.dateEnd = dateStr;
                        this.pageIndex = 1;
                        this.fetchList();
                        this.showToast('已切換至 ' + dateStr + ' 推播訊息', 'fas fa-calendar-day text-info');
                    },
                    clearDateFilter() {
                        this.filters.dateStart = '';
                        this.filters.dateEnd = '';
                        this.pageIndex = 1;
                        this.fetchList();
                    },
                    handlePageSizeChange() {
                        this.pageIndex = 1;
                        this.fetchList();
                    },
                    goToPage(p) {
                        if (p < 1 || p > this.totalPages || p === this.pageIndex) return;
                        this.pageIndex = p;
                        this.fetchList();
                        window.scrollTo({ top: 120, behavior: 'smooth' });
                    },
                    getSeverityBadgeClass(sev) {
                        switch (sev) {
                            case 'warning': return 'badge-warning text-dark font-weight-bold';
                            case 'danger': return 'badge-danger font-weight-bold';
                            case 'success': return 'badge-success font-weight-bold';
                            case 'info': default: return 'badge-info font-weight-bold';
                        }
                    },
                    openQrModal() {
                        $('#qrModal').modal('show');
                    },
                    openPostModal() {
                        this.newMsg = {
                            Title: '',
                            MsgType: 'WARN',
                            MsgTypeStr: '空品不良預警',
                            Severity: 'warning',
                            TargetRole: '新北市全體列管公私場所及營建工地',
                            IsPinned: false,
                            SendTxt: '',
                            ActionUrl: 'OwnReport/Report_AirQuality.aspx?mode=new'
                        };
                        $('#postModal').modal('show');
                    },
                    onNewMsgTypeChange() {
                        switch (this.newMsg.MsgType) {
                            case 'WARN':
                                this.newMsg.MsgTypeStr = '空品不良預警';
                                this.newMsg.Severity = 'warning';
                                this.newMsg.ActionUrl = 'OwnReport/Report_AirQuality.aspx?mode=new';
                                break;
                            case 'ACTION':
                                this.newMsg.MsgTypeStr = '應變措施啟動';
                                this.newMsg.Severity = 'danger';
                                this.newMsg.ActionUrl = 'OwnReport/Report_AirQuality.aspx?mode=new';
                                break;
                            case 'CLEAR':
                                this.newMsg.MsgTypeStr = '應變作為解除';
                                this.newMsg.Severity = 'success';
                                this.newMsg.ActionUrl = 'OwnReport/AirQuality_List.aspx';
                                break;
                            case 'INFO':
                                this.newMsg.MsgTypeStr = '防制設施指引';
                                this.newMsg.Severity = 'info';
                                this.newMsg.ActionUrl = 'OwnReport/PIC_Report_List.aspx?mode=own';
                                break;
                        }
                    },
                    submitNewMsg() {
                        if (!this.newMsg.Title || !this.newMsg.Title.trim()) {
                            alert('請填寫推播標題！');
                            return;
                        }
                        if (!this.newMsg.SendTxt || !this.newMsg.SendTxt.trim()) {
                            alert('請填寫推播內文！');
                            return;
                        }

                        this.submitting = true;
                        axios.post('Line.aspx?action=sendmessage', this.newMsg)
                            .then(res => {
                                this.submitting = false;
                                if (res.data && res.data.Success) {
                                    $('#postModal').modal('hide');
                                    this.showToast('推播發布成功！', 'fas fa-paper-plane text-success');
                                    this.pageIndex = 1;
                                    this.fetchList();
                                    this.loadInitData();
                                } else {
                                    alert(res.data ? res.data.Message : '發布失敗');
                                }
                            })
                            .catch(err => {
                                this.submitting = false;
                                console.error('發布推播失敗：', err);
                                alert('系統連線異常，發布失敗！');
                            });
                    },
                    isSample(msg) {
                        return msg && (msg.Create_User === 'SYSTEM' || msg.Create_User === 'EPD_ADMIN' || msg.Create_User === 'EPD_TECH' || msg.Create_User === 'EPD_CLEAN');
                    },
                    clearSamples() {
                        if (!confirm('確定要一鍵清空系統預載的 5 筆示範預警推播嗎？\n清空後將完全清空示範資料，僅保留管理員手動發布之推播！')) {
                            return;
                        }
                        axios.get('Line.aspx?action=cleardefaultsamples')
                            .then(res => {
                                if (res.data && res.data.Success) {
                                    this.showToast(res.data.Message || '示範資料已清空！', 'fas fa-eraser text-success');
                                    this.fetchList();
                                    this.loadInitData();
                                } else {
                                    alert(res.data ? res.data.Message : '清空失敗');
                                }
                            })
                            .catch(err => {
                                console.error('清空示範資料失敗：', err);
                                alert('連線異常，請檢查伺服器狀態！');
                            });
                    },
                    downloadQr() {
                        const a = document.createElement('a');
                        a.href = this.official.QrCodeUrl;
                        a.download = 'Line_Official_QRCode.svg';
                        document.body.appendChild(a);
                        a.click();
                        document.body.removeChild(a);
                        this.showToast('QR Code 圖檔已下載！', 'fas fa-download text-success');
                    },
                    confirmDelete(msg) {
                        if (!confirm('確定要刪除推播訊息「' + msg.Title + '」嗎？\n刪除後無法復原！')) {
                            return;
                        }

                        axios.get('Line.aspx?action=deletemessage&id=' + msg.Msg_ID)
                            .then(res => {
                                if (res.data && res.data.Success) {
                                    this.showToast('訊息已成功刪除！', 'fas fa-trash-alt text-success');
                                    this.fetchList();
                                    this.loadInitData();
                                } else {
                                    alert(res.data ? res.data.Message : '刪除失敗');
                                }
                            })
                            .catch(err => {
                                console.error('刪除訊息異常：', err);
                                alert('刪除失敗，請檢查網路連線！');
                            });
                    }
                }
            }).mount('#lineApp');
        })();
    </script>
</body>
</html>



