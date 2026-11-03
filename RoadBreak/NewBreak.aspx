<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="NewBreak.aspx.cs" Inherits="NTPC_FEC.RoadBreak.NewBreak" %>

<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定逸散源管理平台 - 道路破損現場通報</title>

    <!-- 專屬 Favicon -->
    <link rel="shortcut icon" href="../favicon.ico" type="image/x-icon" />

    <!-- 本地化核心樣式庫 -->
    <link rel="stylesheet" href="../Content/bootstrap.min.css" />
    <link rel="stylesheet" href="../Content/fontawesome/css/all.min.css" />
    <link rel="stylesheet" href="../Content/leaflet/leaflet.css" />

    <style>
        :root {
            --brand-primary: #0284c7;     /* 主色調藍 */
            --brand-dark-blue: #0b1f7d;   /* 深藍 */
            --brand-navy: #0f172a;        /* 標題深色 */
            --bg-canvas: #f8fafc;         /* 底色 */
            --surface: #ffffff;           /* 白色基底 */
            --border-color: #cbd5e1;      /* 邊框線 */
            --text-main: #1e293b;         /* 內文主要 */
            --text-muted: #64748b;        /* 次要文字 */
            --accent-req: #dc2626;        /* 必填紅星標記 */
            --accent-orange: #d97706;     /* 提示黃橘 */
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
        }

        [v-cloak] {
            display: none !important;
        }

        /* 頂部導覽列 */
        .top-navbar {
            background: linear-gradient(135deg, #0284c7 0%, #0369a1 100%);
            color: #ffffff;
            height: 54px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 0 16px;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
            position: sticky;
            top: 0;
            z-index: 1020;
        }

        .top-navbar .brand-title {
            font-size: 1.1rem;
            font-weight: 700;
            margin: 0;
            display: flex;
            align-items: center;
        }

        .nav-btn {
            background: rgba(255, 255, 255, 0.18);
            border: 1px solid rgba(255, 255, 255, 0.35);
            color: #ffffff;
            border-radius: 6px;
            padding: 5px 12px;
            font-size: 0.88rem;
            font-weight: 600;
            transition: all 0.2s ease;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 5px;
            cursor: pointer;
        }

        .nav-btn:hover {
            background: rgba(255, 255, 255, 0.3);
            color: #ffffff;
            text-decoration: none;
        }

        .mode-badge {
            font-size: 0.75rem;
            padding: 3px 8px;
            border-radius: 12px;
            font-weight: 700;
        }
        .badge-new { background-color: #10b981; color: #ffffff; }
        .badge-edit { background-color: #f59e0b; color: #1e293b; }

        /* 主容器 */
        .main-container {
            max-width: 1280px;
            margin: 16px auto 70px auto;
            padding: 0 12px;
        }

        /* 專案標準表單排版 (符合 inspection-ui-standard card-modern 規範) */
        .break-form-table {
            width: 100%;
            background-color: var(--surface);
            border: 1px solid var(--border-color);
            border-collapse: collapse;
            margin-bottom: 24px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05), 0 4px 12px rgba(15, 23, 42, 0.05);
            border-radius: 12px;
            overflow: hidden;
        }

        .break-form-table tr {
            border-bottom: 1px solid var(--border-color);
        }

        .break-form-table td.field-header {
            width: 160px;
            min-width: 140px;
            background-color: #f8fafc;
            color: #334155;
            font-weight: 700;
            font-size: 0.96rem;
            padding: 14px 18px;
            vertical-align: top;
            border-right: 1px solid var(--border-color);
            line-height: 1.4;
        }

        .break-form-table td.field-header .req-star {
            color: #dc2626;
            margin-right: 2px;
            font-size: 1.05rem;
        }

        .break-form-table td.field-body {
            background-color: #ffffff;
            padding: 14px 18px;
            font-size: 0.95rem;
            vertical-align: middle;
            color: var(--text-main);
        }

        /* 單選與核取方塊排版 */
        .radio-options-row, .checkbox-options-row {
            display: flex;
            flex-wrap: wrap;
            align-items: center;
            gap: 16px;
        }

        .custom-check-item {
            display: inline-flex;
            align-items: center;
            cursor: pointer;
            margin: 0;
            user-select: none;
            font-size: 0.95rem;
        }

        .custom-check-item input[type="radio"],
        .custom-check-item input[type="checkbox"] {
            width: 18px;
            height: 18px;
            margin-right: 6px;
            cursor: pointer;
            accent-color: #0284c7;
        }

        /* 尺寸輸入框 (科技淡藍底) */
        .dimension-row {
            display: flex;
            align-items: center;
            flex-wrap: wrap;
            gap: 10px;
            margin-top: 10px;
            padding: 8px 12px;
            background: #f0f9ff;
            border-radius: 6px;
            border: 1px solid #bae6fd;
        }

        .dimension-input {
            width: 90px;
            padding: 5px 8px;
            font-size: 0.92rem;
            border: 1px solid #cbd5e1;
            border-radius: 4px;
            background-color: #ffffff;
            text-align: right;
            font-weight: 600;
        }

        .dimension-input:focus {
            border-color: #0284c7;
            outline: none;
            box-shadow: 0 0 0 3px rgba(2, 132, 199, 0.15);
        }

        /* 反映地點各列排版 */
        .location-grid-row {
            display: flex;
            align-items: center;
            gap: 10px;
            margin-bottom: 8px;
            flex-wrap: wrap;
        }

        .location-grid-row:last-child {
            margin-bottom: 0;
        }

        .loc-label {
            min-width: 140px;
            color: #334155;
            font-weight: 600;
            font-size: 0.92rem;
        }

        .input-subtle {
            border: 1px solid #cbd5e1;
            background-color: #fffefb;
            padding: 6px 10px;
            font-size: 0.92rem;
            border-radius: 4px;
            color: #1e293b;
            transition: all 0.2s ease;
        }

        .input-subtle:focus {
            border-color: #0284c7;
            background-color: #ffffff;
            outline: none;
            box-shadow: 0 0 0 3px rgba(2, 132, 199, 0.15);
        }

        .coord-input {
            width: 150px;
            text-align: center;
            font-family: monospace;
            font-weight: 700;
        }

        /* 地圖點選按鈕 */
        .btn-map-picker {
            background: linear-gradient(135deg, #0284c7 0%, #0369a1 100%);
            color: #ffffff;
            border: none;
            padding: 6px 14px;
            border-radius: 6px;
            font-weight: 700;
            font-size: 0.88rem;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            gap: 6px;
            box-shadow: 0 2px 6px rgba(2, 132, 199, 0.3);
            transition: all 0.2s ease;
        }

        .btn-map-picker:hover {
            filter: brightness(1.1);
            color: #ffffff;
            text-decoration: none;
        }

        /* 現場照片 7 格上傳卡片區 */
        .photo-slots-container {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(290px, 1fr));
            gap: 14px;
            margin-top: 10px;
        }

        .photo-slot-card {
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 10px;
            background: #ffffff;
            transition: all 0.2s ease;
            position: relative;
        }

        .photo-slot-card:hover {
            border-color: #0284c7;
            box-shadow: 0 3px 10px rgba(0, 0, 0, 0.05);
        }

        .slot-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 8px;
        }

        .slot-title {
            font-weight: 700;
            font-size: 0.9rem;
            color: #0369a1;
        }

        .slot-preview-area {
            height: 140px;
            background: #f8fafc;
            border: 1px dashed #cbd5e1;
            border-radius: 6px;
            display: flex;
            align-items: center;
            justify-content: center;
            overflow: hidden;
            position: relative;
            cursor: pointer;
        }

        .slot-preview-area img {
            width: 100%;
            height: 100%;
            object-fit: cover;
        }

        .slot-empty-hint {
            color: #94a3b8;
            font-size: 0.82rem;
            text-align: center;
            padding: 8px;
        }

        .slot-empty-hint i {
            font-size: 1.8rem;
            display: block;
            margin-bottom: 4px;
            color: #cbd5e1;
        }

        .slot-controls {
            display: flex;
            align-items: center;
            gap: 8px;
            margin-top: 8px;
        }

        .btn-upload-file {
            background-color: #f1f5f9;
            border: 1px solid #cbd5e1;
            color: #334155;
            padding: 4px 10px;
            border-radius: 4px;
            font-size: 0.82rem;
            font-weight: 600;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            gap: 4px;
            transition: all 0.15s ease;
        }

        .btn-upload-file:hover {
            background-color: #e2e8f0;
            color: #0f172a;
        }

        .btn-clear-slot {
            background: none;
            border: none;
            color: #dc2626;
            font-size: 0.85rem;
            cursor: pointer;
            padding: 4px 8px;
            border-radius: 4px;
        }

        .btn-clear-slot:hover {
            background: #fee2e2;
        }

        /* 提示備註小字 */
        .notice-text {
            color: #b45309;
            font-size: 0.85rem;
            line-height: 1.4;
            margin: 4px 0 0 0;
        }

        .notice-danger {
            color: #dc2626;
            font-weight: 600;
        }

        /* 地圖彈窗 Modal */
        .map-modal-backdrop {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(15, 23, 42, 0.65);
            z-index: 1050;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 16px;
        }

        .map-modal-dialog {
            width: 95vw;
            max-width: 1000px;
            height: 85vh;
            background: #ffffff;
            border-radius: 12px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.3);
            display: flex;
            flex-direction: column;
            overflow: hidden;
        }

        .map-modal-header {
            padding: 12px 18px;
            background: #0284c7;
            color: #ffffff;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .map-modal-header h5 {
            margin: 0;
            font-size: 1.05rem;
            font-weight: 700;
        }

        .map-modal-body {
            flex: 1;
            position: relative;
            background: #e2e8f0;
        }

        #modalMap {
            width: 100%;
            height: 100%;
        }

        .map-modal-footer {
            padding: 10px 18px;
            background: #f8fafc;
            border-top: 1px solid #e2e8f0;
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-wrap: wrap;
            gap: 10px;
        }

        /* 照片燈箱 Lightbox */
        .lightbox-modal {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(0, 0, 0, 0.88);
            z-index: 1090;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }

        .lightbox-img {
            max-width: 95vw;
            max-height: 90vh;
            border-radius: 6px;
            box-shadow: 0 8px 30px rgba(0, 0, 0, 0.5);
        }

        .lightbox-close {
            position: absolute;
            top: 16px;
            right: 16px;
            background: rgba(255, 255, 255, 0.25);
            color: #ffffff;
            border: none;
            border-radius: 50%;
            width: 40px;
            height: 40px;
            font-size: 1.4rem;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        /* 標記 Pin */
        .marker-pin {
            width: 32px;
            height: 32px;
            border-radius: 50% 50% 50% 0;
            background: #dc2626;
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
        .marker-icon {
            transform: rotate(45deg);
            color: #ffffff;
            font-size: 13px;
        }

        /* 尺寸與坐標通用類別 */
        .dimension-item-wrap {
            display: inline-flex;
            align-items: center;
            gap: 6px;
        }

        .coord-inputs-group {
            display: flex;
            align-items: center;
            gap: 10px;
            flex-wrap: wrap;
        }

        .coord-item {
            display: inline-flex;
            align-items: center;
            gap: 6px;
        }

        /* =========================================================
           小尺寸螢幕 RWD 現代化極致體驗 (iPhone 16 / 手機直式 / 平板)
           ========================================================= */
        @media screen and (max-width: 767.98px) {
            body {
                padding-bottom: 76px !important;
            }

            .top-navbar {
                height: 52px !important;
                padding: 0 10px !important;
            }

            .top-navbar .brand-title {
                font-size: 1rem !important;
            }

            .top-navbar .nav-btn {
                padding: 4px 8px !important;
                font-size: 0.8rem !important;
            }

            .main-container {
                margin: 8px auto 80px auto !important;
                padding: 0 6px !important;
            }

            /* 表單表格全面轉為單欄流動卡片 (Full-width Mobile Stack) */
            .break-form-table {
                border: 1px solid var(--border-color) !important;
                border-radius: 12px !important;
                display: block !important;
                width: 100% !important;
                box-shadow: 0 1px 4px rgba(0, 0, 0, 0.05) !important;
            }

            .break-form-table tbody {
                display: block !important;
                width: 100% !important;
            }

            .break-form-table tr {
                display: block !important;
                width: 100% !important;
                border-bottom: 1px solid var(--border-color) !important;
                background-color: #ffffff !important;
            }

            .break-form-table tr:last-child {
                border-bottom: none !important;
            }

            .break-form-table td.field-header {
                display: block !important;
                width: 100% !important;
                min-width: 100% !important;
                border-right: none !important;
                border-bottom: 1px solid #f1f5f9 !important;
                background-color: #f8fafc !important;
                color: #1e293b !important;
                font-size: 0.96rem !important;
                font-weight: 700 !important;
                padding: 10px 14px !important;
            }

            .break-form-table td.field-body {
                display: block !important;
                width: 100% !important;
                padding: 12px 10px !important;
            }

            /* 單選與複選項目大熱區晶片 (Touch-friendly Chip Buttons >= 44px) */
            .radio-options-row, .checkbox-options-row {
                display: grid !important;
                grid-template-columns: repeat(2, 1fr) !important;
                gap: 8px !important;
                width: 100% !important;
            }

            .custom-check-item {
                background: #f8fafc !important;
                border: 1px solid #cbd5e1 !important;
                border-radius: 8px !important;
                padding: 10px 10px !important;
                min-height: 44px !important;
                display: flex !important;
                align-items: center !important;
                font-size: 13.5px !important;
                line-height: 1.25 !important;
                margin: 0 !important;
                word-break: break-all !important;
                transition: all 0.15s ease !important;
            }

            .custom-check-item:active {
                background: #e0f2fe !important;
                border-color: #0284c7 !important;
            }

            .custom-check-item input[type="radio"],
            .custom-check-item input[type="checkbox"] {
                width: 20px !important;
                height: 20px !important;
                margin-right: 8px !important;
                flex-shrink: 0 !important;
                accent-color: #0284c7 !important;
            }

            /* 尺寸長寬在手機端自適應雙欄並列 */
            .dimension-row {
                display: grid !important;
                grid-template-columns: 1fr 1fr !important;
                gap: 8px !important;
                padding: 10px !important;
                width: 100% !important;
            }

            .dimension-item-wrap {
                display: flex !important;
                align-items: center !important;
                gap: 6px !important;
                width: 100% !important;
            }

            .dimension-input {
                flex: 1 !important;
                width: 100% !important;
                height: 42px !important;
                font-size: 16px !important; /* 防止 iOS Safari 自動放大網頁 */
                padding: 6px 10px !important;
                text-align: center !important;
            }

            .area-calc-pill {
                grid-column: span 2 !important;
                text-align: center !important;
                margin-top: 4px !important;
            }

            /* 反映地點直立式展開，輸入框高度 42px 好點擊 */
            .location-grid-row {
                flex-direction: column !important;
                align-items: stretch !important;
                gap: 6px !important;
                margin-bottom: 12px !important;
            }

            .loc-label {
                min-width: 100% !important;
                font-size: 13px !important;
                font-weight: 700 !important;
                color: #475569 !important;
                margin-bottom: 2px !important;
            }

            .input-subtle {
                width: 100% !important;
                min-width: 100% !important;
                height: 42px !important;
                font-size: 15px !important;
                padding: 8px 12px !important;
            }

            .coord-inputs-group {
                display: grid !important;
                grid-template-columns: 1fr 1fr !important;
                gap: 8px !important;
                width: 100% !important;
            }

            .coord-item {
                display: flex !important;
                flex-direction: column !important;
                gap: 4px !important;
                width: 100% !important;
            }

            .coord-input {
                width: 100% !important;
                height: 42px !important;
                font-size: 15px !important;
                text-align: center !important;
            }

            .btn-map-picker {
                width: 100% !important;
                margin-left: 0 !important;
                margin-top: 8px !important;
                height: 44px !important;
                font-size: 14px !important;
                justify-content: center !important;
            }

            /* 7 格照片上傳在手機端以 2 欄整齊排列 */
            .photo-slots-container {
                grid-template-columns: repeat(2, 1fr) !important;
                gap: 8px !important;
            }

            .photo-slot-card {
                padding: 6px !important;
            }

            .slot-header {
                margin-bottom: 4px !important;
            }

            .slot-title {
                font-size: 12px !important;
            }

            .slot-preview-area {
                height: 105px !important;
            }

            .slot-empty-hint {
                padding: 4px !important;
                font-size: 11px !important;
            }

            .slot-empty-hint i {
                font-size: 1.3rem !important;
                margin-bottom: 2px !important;
            }

            .slot-controls {
                margin-top: 4px !important;
            }

            .btn-upload-file {
                width: 100% !important;
                justify-content: center !important;
                padding: 6px 4px !important;
                font-size: 11.5px !important;
            }

            .btn-clear-slot {
                padding: 2px 4px !important;
                font-size: 11px !important;
            }

            /* 手機端底部常駐懸浮工具列 (Mobile Sticky Action Bar) */
            .mobile-bottom-bar {
                display: flex !important;
                position: fixed;
                bottom: 0;
                left: 0;
                right: 0;
                z-index: 1010;
                background: #ffffff;
                border-top: 1px solid #e2e8f0;
                box-shadow: 0 -4px 16px rgba(0, 0, 0, 0.08);
                padding: 8px 12px;
                padding-bottom: calc(8px + env(safe-area-inset-bottom, 0px));
                gap: 8px;
            }

            .mobile-bottom-bar .btn {
                flex: 1;
                font-weight: 700;
                padding: 10px 6px;
                border-radius: 8px;
                font-size: 14px;
                display: flex;
                align-items: center;
                justify-content: center;
                min-height: 42px;
            }
        }

        @media screen and (min-width: 768px) {
            .mobile-bottom-bar {
                display: none !important;
            }
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div id="breakApp" v-cloak>
            <!-- 頂部導覽列 -->
            <header class="top-navbar no-print">
                <div class="d-flex align-items-center">
                    <a href="../MainPage.aspx" class="nav-btn mr-2" title="返回主選單">
                        <i class="fas fa-home"></i>
                        <span class="d-none d-sm-inline">回首頁</span>
                    </a>
                    <h1 class="brand-title">
                        <i class="fas fa-road mr-2"></i>
                        <span>道路破損現場通報</span>
                        <span class="mode-badge ml-2" :class="mode === 'new' ? 'badge-new' : 'badge-edit'">
                            {{ mode === 'new' ? '新增通報' : '案件編輯' }}
                        </span>
                    </h1>
                </div>
                <div class="d-flex align-items-center gap-2">
                    <button type="button" class="btn btn-warning btn-sm font-weight-bold px-3 shadow-sm" v-on:click="submitForm" :disabled="isSubmitting">
                        <i class="fas fa-paper-plane mr-1" :class="{ 'fa-spin': isSubmitting }"></i>
                        {{ isSubmitting ? '儲存中...' : '送出通報' }}
                    </button>
                </div>
            </header>

            <!-- 主表單內容 -->
            <main class="main-container">
                <!-- 狀態警示橫幅 -->
                <div v-if="alertMessage" class="alert alert-dismissible fade show" :class="'alert-' + alertType" role="alert">
                    <i class="fas" :class="alertType === 'success' ? 'fa-check-circle' : 'fa-exclamation-triangle'"></i>
                    <strong class="ml-1">{{ alertMessage }}</strong>
                    <button type="button" class="close" v-on:click="alertMessage = ''">&times;</button>
                </div>

                <!-- 1:1 對標經典公務表格結構 -->
                <table class="break-form-table">
                    <!-- 1. 路面損壞-類別 -->
                    <tr>
                        <td class="field-header">
                            <span class="req-star">*</span>路面損壞-類別
                        </td>
                        <td class="field-body">
                            <div class="radio-options-row">
                                <label v-for="cat in damageCategories" :key="cat" class="custom-check-item">
                                    <input type="radio" name="Damage_Category" :value="cat" v-model="form.Damage_Category" />
                                    <span>{{ cat }}</span>
                                </label>
                            </div>
                        </td>
                    </tr>

                    <!-- 2. 路面損壞-性質 -->
                    <tr>
                        <td class="field-header">
                            <span class="req-star">*</span>路面損壞-性質
                        </td>
                        <td class="field-body">
                            <div class="radio-options-row">
                                <label v-for="dt in damageTypes" :key="dt" class="custom-check-item">
                                    <input type="radio" name="Damage_Type" :value="dt" v-model="form.Damage_Type" />
                                    <span>{{ dt }}</span>
                                </label>
                            </div>

                            <!-- 提示文字 -->
                            <p class="notice-text mt-2" v-if="isManholeType">
                                (如為人手孔蓋損壞，請於說明欄註明人手孔蓋形狀及單位標誌)
                            </p>
                            <p class="notice-text mt-2" v-else>
                                (如為人手孔蓋損壞，請於說明欄註明人手孔蓋形狀及單位標誌)
                            </p>

                            <!-- 尺寸長度與寬度 -->
                            <div class="dimension-row">
                                <div class="dimension-item-wrap">
                                    <span class="font-weight-bold text-dark">長：</span>
                                    <input type="number" step="0.1" min="0" inputmode="decimal" class="dimension-input" v-model="form.Damage_Length" placeholder="0.0" />
                                    <span class="text-muted font-weight-bold">m</span>
                                </div>
                                <div class="dimension-item-wrap">
                                    <span class="font-weight-bold text-dark">寬：</span>
                                    <input type="number" step="0.1" min="0" inputmode="decimal" class="dimension-input" v-model="form.Damage_Width" placeholder="0.0" />
                                    <span class="text-muted font-weight-bold">m</span>
                                </div>
                                <div v-if="calcArea > 0" class="area-calc-pill">
                                    <span class="badge badge-info px-2 py-1 font-weight-bold">
                                        估算面積：{{ calcArea }} 平方公尺
                                    </span>
                                </div>
                            </div>
                        </td>
                    </tr>

                    <!-- 3. 反映地點 -->
                    <tr>
                        <td class="field-header">
                            <span class="req-star">*</span>反映地點
                        </td>
                        <td class="field-body">
                            <!-- 所屬區 -->
                            <div class="location-grid-row">
                                <span class="loc-label">所屬區：</span>
                                <select class="input-subtle" style="min-width: 160px;" v-model="form.TOWN_CODE">
                                    <option value="">-- 請選擇所屬區 --</option>
                                    <option v-for="t in towns" :key="t.TownNo" :value="t.TownNo">
                                        {{ t.TownName }}
                                    </option>
                                </select>
                            </div>

                            <!-- 地址、路段或地標 -->
                            <div class="location-grid-row">
                                <span class="loc-label">地址、路段或地標：</span>
                                <input type="text" class="input-subtle" style="flex: 1; min-width: 280px;" v-model.trim="form.ROAD_Name" placeholder="例如：中興路一段、新莊中正路等" />
                            </div>

                            <!-- 地點描述 (寬度與地址列完全一致對齊) -->
                            <div class="location-grid-row" style="align-items: flex-start;">
                                <span class="loc-label pt-md-1">地點描述：</span>
                                <div style="flex: 1; min-width: 280px;">
                                    <input type="text" class="input-subtle w-100" v-model.trim="form.Location_Desc" placeholder="輸入地點特徵 (例如：便利商店前、路燈編號370050前方...)" />
                                    <div class="text-muted small mt-1">(例如便利商店前、路燈編號370050前方...)</div>
                                </div>
                            </div>

                            <!-- 座標X、座標Y 與地圖按鈕 -->
                            <div class="location-grid-row">
                                <div class="coord-inputs-group">
                                    <div class="coord-item">
                                        <span class="loc-label">坐標X (TWD97)：</span>
                                        <input type="text" class="input-subtle coord-input" v-model="form.S_UTME" placeholder="X 坐標" v-on:change="onManualCoordChange" />
                                    </div>
                                    <div class="coord-item">
                                        <span class="loc-label">坐標Y (TWD97)：</span>
                                        <input type="text" class="input-subtle coord-input" v-model="form.S_UTMN" placeholder="Y 坐標" v-on:change="onManualCoordChange" />
                                    </div>
                                </div>
                                <button type="button" class="btn-map-picker" v-on:click="openMapModal">
                                    <i class="fas fa-map-marked-alt mr-1"></i> 電子地圖-點選座標
                                </button>
                            </div>
                            <p class="notice-text">
                                (請在電子地圖上點選反映地點，或直接輸入經緯度坐標)
                            </p>
                        </td>
                    </tr>

                    <!-- 4. 車道 -->
                    <tr>
                        <td class="field-header">
                            <span class="req-star">*</span>車道
                        </td>
                        <td class="field-body">
                            <div class="checkbox-options-row">
                                <label v-for="lane in laneOptions" :key="lane" class="custom-check-item">
                                    <input type="checkbox" :value="lane" v-model="selectedLanes" v-on:change="onLaneChange(lane)" />
                                    <span>{{ lane }}</span>
                                </label>
                            </div>
                        </td>
                    </tr>

                    <!-- 5. 方向 -->
                    <tr>
                        <td class="field-header">
                            <span class="req-star">*</span>方向
                        </td>
                        <td class="field-body">
                            <div class="radio-options-row">
                                <label v-for="dir in directionOptions" :key="dir" class="custom-check-item">
                                    <input type="radio" name="Direction" :value="dir" v-model="form.Direction" />
                                    <span>{{ dir }}</span>
                                </label>
                            </div>
                        </td>
                    </tr>

                    <!-- 6. 道路型態 -->
                    <tr>
                        <td class="field-header">
                            <span class="req-star">*</span>道路型態
                        </td>
                        <td class="field-body">
                            <div class="radio-options-row">
                                <label v-for="rt in roadTypeOptions" :key="rt" class="custom-check-item">
                                    <input type="radio" name="Road_Type" :value="rt" v-model="form.Road_Type" />
                                    <span>{{ rt }}</span>
                                </label>
                            </div>
                        </td>
                    </tr>

                    <!-- 7. 其他說明 -->
                    <tr>
                        <td class="field-header">
                            其他說明
                        </td>
                        <td class="field-body">
                            <textarea class="input-subtle w-100" rows="4" v-model="form.Memo" placeholder="請補充現場相關狀況或特殊備註說明..."></textarea>
                        </td>
                    </tr>

                    <!-- 8. 現場照片 (對標 7 格照片獨立上傳規格) -->
                    <tr>
                        <td class="field-header">
                            現場照片
                        </td>
                        <td class="field-body">
                            <p class="notice-danger mb-1">
                                檔案類型限 jpg,jpeg,png,gif,heic，單一檔案上傳上限為15MB
                            </p>

                            <!-- 隱藏的獨立檔案上傳 input -->
                            <input type="file" ref="slotFileInput" accept="image/jpeg,image/png,image/gif,image/heic,image/*" capture="environment" style="display:none;" v-on:change="onSlotFileSelected" />

                            <!-- 7 格獨立照片排版 -->
                            <div class="photo-slots-container">
                                <div v-for="slot in 7" :key="slot" class="photo-slot-card">
                                    <div class="slot-header">
                                        <span class="slot-title">{{ slot }}. 現場照片</span>
                                        <button v-if="hasPhotoInSlot(slot)" type="button" class="btn-clear-slot" v-on:click="clearSlotPhoto(slot)" title="清除照片">
                                            <i class="fas fa-trash-alt mr-1"></i> 清除
                                        </button>
                                    </div>

                                    <!-- 預覽區塊 -->
                                    <div class="slot-preview-area" v-on:click="handleSlotClick(slot)">
                                        <img v-if="getSlotPhoto(slot)" :src="getSlotPhoto(slot).PreviewUrl || getSlotPhoto(slot).Url" :alt="'照片 ' + slot" />
                                        <div v-else class="slot-empty-hint">
                                            <i class="fas fa-camera"></i>
                                            <span>點此拍照或選擇檔案</span>
                                        </div>
                                    </div>

                                    <!-- 控制項 -->
                                    <div class="slot-controls">
                                        <button type="button" class="btn-upload-file" v-on:click="triggerSlotUpload(slot)">
                                            <i class="fas fa-folder-open"></i> 選擇檔案
                                        </button>
                                        <small class="text-truncate text-muted flex-1" style="max-width: 180px;">
                                            {{ getSlotPhoto(slot) ? (getSlotPhoto(slot).FileName || '已選取檔案') : '沒有選擇檔案' }}
                                        </small>
                                    </div>
                                </div>
                            </div>

                            <p class="notice-text mt-3">
                                (若為建案工地，請上傳施工告示牌照片)
                            </p>
                        </td>
                    </tr>
                </table>

                <!-- 底部按鈕列 (電腦端顯示) -->
                <div class="d-none d-md-flex align-items-center justify-content-center gap-3 mt-4 mb-4">
                    <button type="button" class="btn btn-secondary px-4 font-weight-bold" v-on:click="goBack">
                        <i class="fas fa-arrow-left mr-1"></i> 返回清單
                    </button>
                    <button type="button" class="btn btn-primary px-5 font-weight-bold shadow" v-on:click="submitForm" :disabled="isSubmitting">
                        <i class="fas fa-paper-plane mr-1" :class="{ 'fa-spin': isSubmitting }"></i>
                        {{ isSubmitting ? '通報中...' : (mode === 'new' ? '確定送出通報' : '更新通報單') }}
                    </button>
                </div>
            </main>

            <!-- 手機端常駐底部懸浮動作列 (Mobile Sticky Action Bar) -->
            <div class="mobile-bottom-bar no-print">
                <button type="button" class="btn btn-secondary" v-on:click="goBack">
                    <i class="fas fa-arrow-left mr-1"></i> 返回
                </button>
                <button type="button" class="btn btn-info text-white" v-on:click="openMapModal">
                    <i class="fas fa-map-marked-alt mr-1"></i> 地圖
                </button>
                <button type="button" class="btn btn-warning font-weight-bold text-dark shadow-sm" v-on:click="submitForm" :disabled="isSubmitting">
                    <i class="fas fa-paper-plane mr-1" :class="{ 'fa-spin': isSubmitting }"></i>
                    {{ isSubmitting ? '儲存中...' : (mode === 'new' ? '送出通報' : '更新通報') }}
                </button>
            </div>

            <!-- 電子地圖彈窗 (點選座標 Modal) -->
            <div v-if="isMapModalOpen" class="map-modal-backdrop" v-on:click="closeMapModal">
                <div class="map-modal-dialog" v-on:click.stop>
                    <div class="map-modal-header">
                        <h5><i class="fas fa-map-marked-alt mr-2"></i> 電子地圖 - 點選反映地點坐標</h5>
                        <button type="button" class="close text-white" v-on:click="closeMapModal">&times;</button>
                    </div>
                    <div class="map-modal-body">
                        <div id="modalMap"></div>
                    </div>
                    <div class="map-modal-footer">
                        <div class="d-flex align-items-center gap-3">
                            <span class="small font-weight-bold text-primary">
                                目前選定坐標：
                                X={{ form.S_UTME || '未選取' }} , Y={{ form.S_UTMN || '未選取' }}
                                <span v-if="form.Lat" class="text-muted font-weight-normal">({{ Number(form.Lat).toFixed(5) }}, {{ Number(form.Lon).toFixed(5) }})</span>
                            </span>
                        </div>
                        <div class="d-flex align-items-center gap-2">
                            <button type="button" class="btn btn-outline-primary btn-sm" v-on:click="getCurrentGpsLocation">
                                <i class="fas fa-crosshairs mr-1"></i> GPS 定位
                            </button>
                            <button type="button" class="btn btn-success btn-sm font-weight-bold px-3" v-on:click="closeMapModal">
                                <i class="fas fa-check mr-1"></i> 確認帶回坐標
                            </button>
                        </div>
                    </div>
                </div>
            </div>

            <!-- 照片燈箱視窗 (Lightbox) -->
            <div v-if="lightboxImg" class="lightbox-modal" v-on:click="lightboxImg = null">
                <button type="button" class="lightbox-close" v-on:click="lightboxImg = null">&times;</button>
                <img :src="lightboxImg" class="lightbox-img" v-on:click.stop alt="放大檢視照片" />
            </div>
        </div>
    </form>

    <!-- 本地化核心腳本庫 -->
    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>
    <script src="../Scripts/leaflet/leaflet.js"></script>
    <script src="../Scripts/fec-offline-sentinel.js?v=20261102_01"></script>

    <script type="text/javascript">
        // TWD97 與 WGS84 高精度雙向轉換演算法
        const Twd97Wgs84Helper = {
            twd97ToWgs84: function(x, y) {
                if (!x || !y || x <= 0 || y <= 0) return { lat: 0, lon: 0 };
                const a = 6378137.0;
                const b = 6356752.314245;
                const lon0 = 121.0 * Math.PI / 180.0;
                const k0 = 0.9999;
                const dx = 250000.0;

                const e = Math.sqrt(1.0 - (b * b) / (a * a));
                const e2 = (e * e) / (1.0 - e * e);
                const xShift = x - dx;

                const M = y / k0;
                const mu = M / (a * (1.0 - Math.pow(e, 2) / 4.0 - 3.0 * Math.pow(e, 4) / 64.0 - 5.0 * Math.pow(e, 6) / 256.0));
                const e1 = (1.0 - Math.sqrt(1.0 - Math.pow(e, 2))) / (1.0 + Math.sqrt(1.0 - Math.pow(e, 2)));

                const J1 = (3.0 * e1 / 2.0 - 27.0 * Math.pow(e1, 3) / 32.0);
                const J2 = (21.0 * Math.pow(e1, 2) / 16.0 - 55.0 * Math.pow(e1, 4) / 32.0);
                const J3 = (151.0 * Math.pow(e1, 3) / 96.0);
                const J4 = (1097.0 * Math.pow(e1, 4) / 512.0);

                const fp = mu + J1 * Math.sin(2.0 * mu) + J2 * Math.sin(4.0 * mu) + J3 * Math.sin(6.0 * mu) + J4 * Math.sin(8.0 * mu);

                const C1 = e2 * Math.pow(Math.cos(fp), 2);
                const T1 = Math.pow(Math.tan(fp), 2);
                const R1 = a * (1.0 - Math.pow(e, 2)) / Math.pow(1.0 - Math.pow(e, 2) * Math.pow(Math.sin(fp), 2), 1.5);
                const N1 = a / Math.sqrt(1.0 - Math.pow(e, 2) * Math.pow(Math.sin(fp), 2));
                const D = xShift / (N1 * k0);

                const latRad = fp - (N1 * Math.tan(fp) / R1) * (Math.pow(D, 2) / 2.0 - (5.0 + 3.0 * T1 + 10.0 * C1 - 4.0 * Math.pow(C1, 2) - 9.0 * e2) * Math.pow(D, 4) / 24.0 + (61.0 + 90.0 * T1 + 298.0 * C1 + 45.0 * Math.pow(T1, 2) - 252.0 * e2 - 3.0 * Math.pow(C1, 2)) * Math.pow(D, 6) / 720.0);
                const lonRad = lon0 + (D - (1.0 + 2.0 * T1 + C1) * Math.pow(D, 3) / 6.0 + (5.0 - 2.0 * C1 + 28.0 * T1 - 3.0 * Math.pow(C1, 2) + 8.0 * e2 + 24.0 * Math.pow(T1, 2)) * Math.pow(D, 5) / 120.0) / Math.cos(fp);

                return {
                    lat: latRad * 180.0 / Math.PI,
                    lon: lonRad * 180.0 / Math.PI
                };
            },

            wgs84ToTwd97: function(lat, lon) {
                if (!lat || !lon || lat <= 0 || lon <= 0) return { x: 0, y: 0 };
                const a = 6378137.0;
                const b = 6356752.314245;
                const lon0 = 121.0 * Math.PI / 180.0;
                const k0 = 0.9999;
                const dx = 250000.0;

                const e = Math.sqrt(1.0 - (b * b) / (a * a));
                const e2 = (e * e) / (1.0 - e * e);

                const latRad = lat * Math.PI / 180.0;
                const lonRad = lon * Math.PI / 180.0;

                const T = Math.pow(Math.tan(latRad), 2);
                const C = e2 * Math.pow(Math.cos(latRad), 2);
                const A = (lonRad - lon0) * Math.cos(latRad);

                const M = a * ((1.0 - Math.pow(e, 2) / 4.0 - 3.0 * Math.pow(e, 4) / 64.0 - 5.0 * Math.pow(e, 6) / 256.0) * latRad
                    - (3.0 * Math.pow(e, 2) / 8.0 + 3.0 * Math.pow(e, 4) / 32.0 + 45.0 * Math.pow(e, 6) / 1024.0) * Math.sin(2.0 * latRad)
                    + (15.0 * Math.pow(e, 4) / 256.0 + 45.0 * Math.pow(e, 6) / 1024.0) * Math.sin(4.0 * latRad)
                    - (35.0 * Math.pow(e, 6) / 3072.0) * Math.sin(6.0 * latRad));

                const N = a / Math.sqrt(1.0 - Math.pow(e, 2) * Math.pow(Math.sin(latRad), 2));

                const x = dx + k0 * N * (A + (1.0 - T + C) * Math.pow(A, 3) / 6.0 + (5.0 - 18.0 * T + Math.pow(T, 2) + 72.0 * C - 58.0 * e2) * Math.pow(A, 5) / 120.0);
                const y = k0 * (M + N * Math.tan(latRad) * (Math.pow(A, 2) / 2.0 + (5.0 - T + 9.0 * C + 4.0 * Math.pow(C, 2)) * Math.pow(A, 4) / 24.0 + (61.0 - 58.0 * T + Math.pow(T, 2) + 600.0 * C - 330.0 * e2) * Math.pow(A, 6) / 720.0));

                return {
                    x: Math.round(x),
                    y: Math.round(y)
                };
            }
        };

        const { createApp } = Vue;

        createApp({
            data() {
                return {
                    mode: 'new',
                    caseId: '',
                    fromId: '',
                    currentUser: '系統查核員',
                    draftSentinel: null,

                    // 下拉與核選清單
                    towns: [],
                    damageCategories: ['路面損壞', '交通標線損壞不良'],
                    damageTypes: ['坑洞', '龜裂', '凹陷', '人手孔蓋週邊破損', '人手孔蓋欠平順', '補綻(臨補)'],
                    laneOptions: ['路口', '車道1', '車道2', '車道3', '車道4', '車道5', '車道交界處', '全車道'],
                    directionOptions: ['單號', '雙號', '無法判定'],
                    roadTypeOptions: ['平面', '非平面'],

                    // 車道多選模型
                    selectedLanes: ['全車道'],

                    // 主表單模型 (完全對標新規格)
                    form: {
                        Break_ID: '',
                        Show_ID: '',
                        Report_Date: '',
                        Damage_Category: '路面損壞',
                        Damage_Type: '坑洞',
                        Damage_Length: '',
                        Damage_Width: '',
                        TOWN_CODE: '',
                        ROAD_Name: '',
                        Location_Desc: '',
                        S_UTME: '',
                        S_UTMN: '',
                        Lat: '',
                        Lon: '',
                        Lane_Info: '全車道',
                        Direction: '無法判定',
                        Road_Type: '平面',
                        Memo: ''
                    },

                    // 7 格照片模型槽位陣列: 每個元素為 { Slot: 1~7, FileName: '', Url: '', PreviewUrl: '', Base64: '', Deleted: false }
                    photosSlots: [],
                    activeUploadingSlot: 1,

                    // UI 狀態
                    isMapModalOpen: false,
                    isSubmitting: false,
                    alertMessage: '',
                    alertType: 'info',
                    lightboxImg: null
                };
            },

            computed: {
                isManholeType() {
                    return this.form.Damage_Type === '人手孔蓋週邊破損' || this.form.Damage_Type === '人手孔蓋欠平順';
                },
                calcArea() {
                    const l = parseFloat(this.form.Damage_Length);
                    const w = parseFloat(this.form.Damage_Width);
                    if (!isNaN(l) && !isNaN(w) && l > 0 && w > 0) {
                        return (l * w).toFixed(2);
                    }
                    return 0;
                }
            },

            created() {
                this.modalMap = null;
                this.modalMarker = null;
                this.initEmptySlots();
            },

            mounted() {
                const urlParams = new URLSearchParams(window.location.search);
                const m = urlParams.get('mode');
                this.fromId = urlParams.get('fromId') || '';
                if (m && m.toLowerCase() === 'edit') {
                    this.mode = 'edit';
                    this.caseId = urlParams.get('id') || '';
                } else if (!m && urlParams.get('id')) {
                    this.mode = 'edit';
                    this.caseId = urlParams.get('id') || '';
                } else {
                    this.mode = 'new';
                }

                this.loadInitData();
                this.initDraftSentinel();
            },

            methods: {
                // 初始化 7 個空槽位
                initEmptySlots() {
                    this.photosSlots = [];
                    for (let i = 1; i <= 7; i++) {
                        this.photosSlots.push({
                            Slot: i,
                            FileName: '',
                            Url: '',
                            PreviewUrl: '',
                            Base64: '',
                            Deleted: false
                        });
                    }
                },

                // 取得指定槽位照片
                getSlotPhoto(slot) {
                    const item = this.photosSlots.find(p => p.Slot === slot);
                    if (item && (item.PreviewUrl || item.Url) && !item.Deleted) {
                        return item;
                    }
                    return null;
                },

                hasPhotoInSlot(slot) {
                    return this.getSlotPhoto(slot) !== null;
                },

                // 0. 初始化離線草稿守護器
                initDraftSentinel() {
                    if (this.mode !== 'new' || typeof FecOfflineSentinel === 'undefined') return;
                    this.draftSentinel = FecOfflineSentinel.create({
                        storageKey: 'FEC_DRAFT_ROADBREAK_NEW',
                        bannerPosition: 'top',
                        getData: () => {
                            if (this.mode !== 'new') return null;
                            return {
                                form: this.form,
                                selectedLanes: this.selectedLanes,
                                photosSlots: this.photosSlots.map(p => ({
                                    Slot: p.Slot,
                                    FileName: p.FileName,
                                    PreviewUrl: p.PreviewUrl,
                                    Base64: p.Base64,
                                    Deleted: p.Deleted
                                }))
                            };
                        },
                        restoreData: (saved) => {
                            if (saved && saved.form) {
                                Object.assign(this.form, saved.form);
                            }
                            if (saved && saved.selectedLanes && Array.isArray(saved.selectedLanes)) {
                                this.selectedLanes = saved.selectedLanes;
                            }
                            if (saved && saved.photosSlots && Array.isArray(saved.photosSlots)) {
                                this.photosSlots = saved.photosSlots;
                            }
                            this.showAlert('已自動還原上次儲存的離線草稿內容！', 'success');
                        }
                    });
                    if (this.draftSentinel && this.draftSentinel.checkAndPromptRestore) {
                        this.draftSentinel.checkAndPromptRestore();
                    }
                },

                // 車道連動處理
                onLaneChange(targetLane) {
                    if (targetLane === '全車道') {
                        if (this.selectedLanes.includes('全車道')) {
                            this.selectedLanes = ['全車道'];
                        }
                    } else {
                        // 若選取了其他車道，自動移除「全車道」
                        const idx = this.selectedLanes.indexOf('全車道');
                        if (idx >= 0) {
                            this.selectedLanes.splice(idx, 1);
                        }
                    }
                    this.form.Lane_Info = this.selectedLanes.join(',');
                },

                // 載入初始選單
                loadInitData() {
                    axios.get('NewBreak.aspx?action=getinit')
                        .then(res => {
                            if (res.data && res.data.Success) {
                                const d = res.data.Data;
                                this.towns = d.Towns || [];
                                if (d.DamageCategories) this.damageCategories = d.DamageCategories;
                                if (d.DamageTypes) this.damageTypes = d.DamageTypes;
                                if (d.LaneOptions) this.laneOptions = d.LaneOptions;
                                if (d.DirectionOptions) this.directionOptions = d.DirectionOptions;
                                if (d.RoadTypeOptions) this.roadTypeOptions = d.RoadTypeOptions;
                                this.currentUser = d.CurrentUser || this.currentUser;

                                if (this.mode === 'new') {
                                    this.form.Break_ID = d.GeneratedCaseId || '';
                                    this.form.Report_Date = d.ReportDate || '';
                                    if (this.fromId) {
                                        this.loadFromPreviousCase(this.fromId);
                                    } else {
                                        if (this.towns.length > 0 && !this.form.TOWN_CODE) {
                                            // 預設五股區 (6501500) 或第一個
                                            const wugu = this.towns.find(t => t.TownName.includes('五股'));
                                            this.form.TOWN_CODE = wugu ? wugu.TownNo : this.towns[0].TownNo;
                                        }
                                        // 自動嘗試定位
                                        this.tryAutoGps();
                                    }
                                } else {
                                    this.loadCaseData(this.caseId);
                                }
                            } else {
                                this.showAlert(res.data.Message || '載入設定失敗', 'danger');
                            }
                        })
                        .catch(err => {
                            console.error(err);
                            this.showAlert('連線伺服器異常，無法載入初始設定', 'danger');
                        });
                },

                // 依前案建立後續持續追蹤複查通報
                loadFromPreviousCase(prevId) {
                    if (!prevId) return;
                    axios.get('NewBreak.aspx?action=getcase&id=' + encodeURIComponent(prevId))
                        .then(res => {
                            if (res.data && res.data.Success) {
                                const c = res.data.Data;
                                this.form.TOWN_CODE = c.TOWN_CODE || this.form.TOWN_CODE;
                                this.form.ROAD_Name = c.ROAD_Name || '';
                                this.form.Location_Desc = c.Location_Desc || '';
                                this.form.Damage_Category = c.Damage_Category || '路面損壞';
                                this.form.Damage_Type = c.Damage_Type || '坑洞';
                                this.form.Damage_Length = c.Damage_Length || '';
                                this.form.Damage_Width = c.Damage_Width || '';
                                this.form.Lane_Info = c.Lane_Info || '全車道';
                                this.form.Direction = c.Direction || '無法判定';
                                this.form.Road_Type = c.Road_Type || '平面';
                                this.form.S_UTME = c.S_UTME || '';
                                this.form.S_UTMN = c.S_UTMN || '';
                                this.form.Lat = c.Lat || '';
                                this.form.Lon = c.Lon || '';
                                this.form.Memo = '【持續追蹤複查案件】原通報反映編號：' + (c.Show_ID || c.Break_ID) + (c.Memo ? '；原說明：' + c.Memo : '');
                                if (this.form.Lane_Info) {
                                    this.selectedLanes = this.form.Lane_Info.split(',').filter(x => x.trim().length > 0);
                                }
                                this.showAlert('已自動帶入原追蹤案件（' + (c.Show_ID || prevId) + '）之反映地點、坐標與損壞資訊，請上傳最新複查照片後送出！', 'info');
                            }
                        })
                        .catch(err => console.error(err));
                },

                // 載入案件資料 (編輯模式)
                loadCaseData(id) {
                    if (!id) return;
                    axios.get('NewBreak.aspx?action=getcase&id=' + encodeURIComponent(id))
                        .then(res => {
                            if (res.data && res.data.Success) {
                                const c = res.data.Data;
                                this.form.Break_ID = c.Break_ID;
                                this.form.Show_ID = c.Show_ID;
                                this.form.Report_Date = c.Report_Date;
                                this.form.TOWN_CODE = c.TOWN_CODE;
                                this.form.ROAD_Name = c.ROAD_Name;
                                this.form.Location_Desc = c.Location_Desc || '';
                                this.form.Damage_Category = c.Damage_Category || '路面損壞';
                                this.form.Damage_Type = c.Damage_Type || '坑洞';
                                this.form.Damage_Length = c.Damage_Length || '';
                                this.form.Damage_Width = c.Damage_Width || '';
                                this.form.Lane_Info = c.Lane_Info || '全車道';
                                this.form.Direction = c.Direction || '無法判定';
                                this.form.Road_Type = c.Road_Type || '平面';
                                this.form.Memo = c.Memo || '';
                                this.form.S_UTME = c.S_UTME || '';
                                this.form.S_UTMN = c.S_UTMN || '';
                                this.form.Lat = c.Lat || '';
                                this.form.Lon = c.Lon || '';

                                // 車道反解陣列
                                if (this.form.Lane_Info) {
                                    this.selectedLanes = this.form.Lane_Info.split(',').filter(x => x.trim().length > 0);
                                }

                                // 7 格照片槽位填充
                                if (c.Photos && Array.isArray(c.Photos)) {
                                    c.Photos.forEach(p => {
                                        const target = this.photosSlots.find(s => s.Slot === p.Slot);
                                        if (target) {
                                            target.FileName = p.FileName;
                                            target.Url = p.Url;
                                            target.PreviewUrl = p.Url;
                                            target.Deleted = false;
                                        }
                                    });
                                }
                            } else {
                                this.showAlert(res.data.Message || '找不到案件資料', 'danger');
                            }
                        })
                        .catch(err => {
                            console.error(err);
                            this.showAlert('讀取案件資料失敗', 'danger');
                        });
                },

                // 手動輸入坐標時反算經緯度
                onManualCoordChange() {
                    const x = parseFloat(this.form.S_UTME);
                    const y = parseFloat(this.form.S_UTMN);
                    if (!isNaN(x) && !isNaN(y) && x > 100000 && y > 100000) {
                        const geo = Twd97Wgs84Helper.twd97ToWgs84(x, y);
                        this.form.Lat = geo.lat.toFixed(6);
                        this.form.Lon = geo.lon.toFixed(6);
                    }
                },

                // 電子地圖彈窗開啟
                openMapModal() {
                    this.isMapModalOpen = true;
                    this.$nextTick(() => {
                        this.initOrUpdateModalMap();
                    });
                },

                closeMapModal() {
                    this.isMapModalOpen = false;
                },

                initOrUpdateModalMap() {
                    let centerLat = 25.012363;
                    let centerLon = 121.465715;
                    let zoom = 14;

                    if (this.form.Lat && this.form.Lon) {
                        centerLat = parseFloat(this.form.Lat);
                        centerLon = parseFloat(this.form.Lon);
                        zoom = 17;
                    }

                    if (!this.modalMap) {
                        this.modalMap = L.map('modalMap', {
                            center: [centerLat, centerLon],
                            zoom: zoom,
                            zoomControl: false
                        });

                        L.control.zoom({ position: 'bottomright' }).addTo(this.modalMap);

                        const emap = L.tileLayer('https://wmts.nlsc.gov.tw/wmts/EMAP/default/GoogleMapsCompatible/{z}/{y}/{x}', {
                            maxZoom: 19,
                            attribution: '&copy; 內政部國土測繪中心'
                        });
                        const photo = L.tileLayer('https://wmts.nlsc.gov.tw/wmts/PHOTO2/default/GoogleMapsCompatible/{z}/{y}/{x}', {
                            maxZoom: 19,
                            attribution: '&copy; 內政部國土測繪中心'
                        });
                        emap.addTo(this.modalMap);

                        L.control.layers({ "通用電子地圖": emap, "空拍正射影像": photo }, null, { position: 'topright' }).addTo(this.modalMap);

                        this.modalMap.on('click', (e) => {
                            this.setModalMarkerPosition(e.latlng.lat, e.latlng.lng, false);
                        });
                    } else {
                        this.modalMap.invalidateSize();
                        this.modalMap.setView([centerLat, centerLon], zoom);
                    }

                    if (this.form.Lat && this.form.Lon) {
                        this.setModalMarkerPosition(parseFloat(this.form.Lat), parseFloat(this.form.Lon), true);
                    }
                },

                setModalMarkerPosition(lat, lon, panTo) {
                    if (!lat || !lon || isNaN(lat) || isNaN(lon)) return;

                    const twd = Twd97Wgs84Helper.wgs84ToTwd97(lat, lon);
                    this.form.Lat = lat.toFixed(6);
                    this.form.Lon = lon.toFixed(6);
                    this.form.S_UTME = twd.x;
                    this.form.S_UTMN = twd.y;

                    const iconHtml = '<div class="marker-pin"><i class="fas fa-exclamation-triangle marker-icon"></i></div>';
                    const customIcon = L.divIcon({
                        className: '',
                        html: iconHtml,
                        iconSize: [32, 32],
                        iconAnchor: [16, 32]
                    });

                    if (this.modalMarker) {
                        this.modalMarker.setLatLng([lat, lon]);
                    } else {
                        this.modalMarker = L.marker([lat, lon], {
                            icon: customIcon,
                            draggable: true
                        }).addTo(this.modalMap);

                        this.modalMarker.on('dragend', (e) => {
                            const pos = e.target.getLatLng();
                            this.setModalMarkerPosition(pos.lat, pos.lng, false);
                        });
                    }

                    if (panTo && this.modalMap) {
                        this.modalMap.panTo([lat, lon]);
                    }
                },

                tryAutoGps() {
                    if (navigator.geolocation) {
                        navigator.geolocation.getCurrentPosition(
                            pos => {
                                const lat = pos.coords.latitude;
                                const lon = pos.coords.longitude;
                                const twd = Twd97Wgs84Helper.wgs84ToTwd97(lat, lon);
                                this.form.Lat = lat.toFixed(6);
                                this.form.Lon = lon.toFixed(6);
                                this.form.S_UTME = twd.x;
                                this.form.S_UTMN = twd.y;
                            },
                            () => { },
                            { enableHighAccuracy: true, timeout: 6000, maximumAge: 0 }
                        );
                    }
                },

                getCurrentGpsLocation() {
                    if (!navigator.geolocation) {
                        alert('您的裝置或瀏覽器不支援 GPS 定位');
                        return;
                    }
                    navigator.geolocation.getCurrentPosition(
                        pos => {
                            const lat = pos.coords.latitude;
                            const lon = pos.coords.longitude;
                            this.setModalMarkerPosition(lat, lon, true);
                            if (this.modalMap) this.modalMap.setView([lat, lon], 17);
                        },
                        err => {
                            alert('無法取得 GPS 坐標，請確認已授權定位權限');
                        },
                        { enableHighAccuracy: true, timeout: 10000, maximumAge: 0 }
                    );
                },

                // 槽位上傳控制
                triggerSlotUpload(slot) {
                    this.activeUploadingSlot = slot;
                    if (this.$refs.slotFileInput) {
                        this.$refs.slotFileInput.click();
                    }
                },

                handleSlotClick(slot) {
                    const p = this.getSlotPhoto(slot);
                    if (p) {
                        this.lightboxImg = p.PreviewUrl || p.Url;
                    } else {
                        this.triggerSlotUpload(slot);
                    }
                },

                onSlotFileSelected(e) {
                    const files = e.target.files;
                    if (!files || files.length === 0) return;

                    const file = files[0];
                    // 檔案大小上限 15MB 檢查
                    if (file.size > 15 * 1024 * 1024) {
                        alert('單一照片檔案大小不可超過 15MB！');
                        e.target.value = '';
                        return;
                    }

                    const slot = this.activeUploadingSlot;
                    const target = this.photosSlots.find(s => s.Slot === slot);
                    if (!target) return;

                    const reader = new FileReader();
                    reader.onload = (event) => {
                        const img = new Image();
                        img.onload = () => {
                            // Canvas 自動等比無損壓縮
                            const canvas = document.createElement('canvas');
                            const maxDim = 1920;
                            let w = img.width;
                            let h = img.height;
                            if (w > maxDim || h > maxDim) {
                                if (w > h) {
                                    h = Math.round((h * maxDim) / w);
                                    w = maxDim;
                                } else {
                                    w = Math.round((w * maxDim) / h);
                                    h = maxDim;
                                }
                            }
                            canvas.width = w;
                            canvas.height = h;
                            const ctx = canvas.getContext('2d');
                            ctx.drawImage(img, 0, 0, w, h);

                            const compressedBase64 = canvas.toDataURL('image/jpeg', 0.85);
                            target.FileName = file.name;
                            target.PreviewUrl = compressedBase64;
                            target.Base64 = compressedBase64;
                            target.Deleted = false;
                        };
                        img.src = event.target.result;
                    };
                    reader.readAsDataURL(file);

                    e.target.value = '';
                },

                clearSlotPhoto(slot) {
                    const target = this.photosSlots.find(s => s.Slot === slot);
                    if (target) {
                        target.PreviewUrl = '';
                        target.Base64 = '';
                        target.Deleted = true;
                    }
                },

                showAlert(msg, type) {
                    this.alertMessage = msg;
                    this.alertType = type || 'info';
                    window.scrollTo({ top: 0, behavior: 'smooth' });
                },

                // 送出通報
                submitForm() {
                    if (!navigator.onLine) {
                        alert('⚠️ 現場網路已離線！系統已自動保存本機最新草稿，請待恢復連線後再按送出。');
                        return;
                    }

                    // 1:1 對標嚴格驗證
                    if (!this.form.Damage_Category) {
                        this.showAlert('請選擇【路面損壞-類別】！', 'danger');
                        return;
                    }
                    if (!this.form.Damage_Type) {
                        this.showAlert('請選擇【路面損壞-性質】！', 'danger');
                        return;
                    }
                    if (!this.form.TOWN_CODE) {
                        this.showAlert('請選擇反映地點之【所屬區】！', 'danger');
                        return;
                    }
                    if (!this.form.ROAD_Name) {
                        this.showAlert('請填寫反映地點之【地址、路段或地標】！', 'danger');
                        return;
                    }
                    if (!this.form.S_UTME || !this.form.S_UTMN || this.form.S_UTME < 100000 || this.form.S_UTMN < 100000) {
                        this.showAlert('請點選【電子地圖-點選座標】取得正確通報坐標！', 'danger');
                        return;
                    }
                    if (this.selectedLanes.length === 0) {
                        this.showAlert('請至少選取一個【車道】！', 'danger');
                        return;
                    }
                    if (!this.form.Direction) {
                        this.showAlert('請選取【方向】(單號/雙號/無法判定)！', 'danger');
                        return;
                    }
                    if (!this.form.Road_Type) {
                        this.showAlert('請選取【道路型態】(平面/非平面)！', 'danger');
                        return;
                    }

                    this.form.Lane_Info = this.selectedLanes.join(',');
                    this.isSubmitting = true;
                    this.showAlert('正在儲存通報單，請稍候...', 'info');

                    const payload = {
                        Mode: this.mode,
                        Break_ID: this.form.Break_ID,
                        Damage_Category: this.form.Damage_Category,
                        Damage_Type: this.form.Damage_Type,
                        Damage_Length: this.form.Damage_Length,
                        Damage_Width: this.form.Damage_Width,
                        TOWN_CODE: this.form.TOWN_CODE,
                        ROAD_Name: this.form.ROAD_Name,
                        Location_Desc: this.form.Location_Desc,
                        Lane_Info: this.form.Lane_Info,
                        Direction: this.form.Direction,
                        Road_Type: this.form.Road_Type,
                        Memo: this.form.Memo,
                        S_UTME: this.form.S_UTME,
                        S_UTMN: this.form.S_UTMN,
                        Lat: this.form.Lat || null,
                        Lon: this.form.Lon || null,
                        Photos: this.photosSlots.map(s => ({
                            Slot: s.Slot,
                            FileName: s.FileName,
                            Base64: s.Base64 || null,
                            Deleted: s.Deleted
                        }))
                    };

                    axios.post('NewBreak.aspx?action=save', payload)
                        .then(res => {
                            this.isSubmitting = false;
                            if (res.data && res.data.Success) {
                                if (this.draftSentinel) {
                                    this.draftSentinel.clearDraft();
                                }
                                alert(res.data.Message || '通報單送出成功！');
                                window.location.href = '../RoadBreak/Break_List.aspx?mode=BreakEdit';
                            } else {
                                this.showAlert(res.data.Message || '儲存失敗', 'danger');
                            }
                        })
                        .catch(err => {
                            this.isSubmitting = false;
                            console.error(err);
                            this.showAlert('伺服器連線失敗或執行錯誤', 'danger');
                        });
                },

                goBack() {
                    if (confirm('是否確認離開？未儲存的通報內容將會遺失。')) {
                        if (window.history.length > 1) {
                            window.history.back();
                        } else {
                            window.location.href = '../MainPage.aspx?sub=menu4';
                        }
                    }
                }
            }
        }).mount('#breakApp');
    </script>
</body>
</html>
