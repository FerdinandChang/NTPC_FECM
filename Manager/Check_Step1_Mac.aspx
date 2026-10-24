<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Check_Step1_Mac.aspx.cs" Inherits="NTPC_FEC.Manager.Check_Step1_Mac" %>

<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定溢散源管理審查平台 - 施工機具現場查核紀錄審查</title>

    <!-- 專屬 Favicon -->
    <link rel="shortcut icon" href="../favicon.ico" type="image/x-icon" />

    <!-- 本地化樣式依賴 (避開外部 CDN 資安阻擋) -->
    <link rel="stylesheet" href="../Content/bootstrap.min.css" />
    <link rel="stylesheet" href="../Content/fontawesome/css/all.min.css" />
    <link rel="stylesheet" href="../Content/leaflet/leaflet.css" />

    <style>
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

        /* 置頂導覽列 */
        .top-navbar {
            background: linear-gradient(135deg, #0099e5 0%, #0284c7 100%);
            color: #ffffff;
            height: 56px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 0 16px;
            box-shadow: 0 2px 10px rgba(0, 153, 229, 0.25);
            position: sticky;
            top: 0;
            z-index: 1020;
        }

        .top-navbar .brand-title {
            font-size: 1.08rem;
            font-weight: 700;
            margin: 0;
            display: flex;
            align-items: center;
            gap: 8px;
            color: #ffffff;
            text-decoration: none;
        }

        .nav-btn {
            background: rgba(255, 255, 255, 0.18);
            border: 1px solid rgba(255, 255, 255, 0.3);
            color: #ffffff;
            font-size: 0.9rem;
            font-weight: 600;
            cursor: pointer;
            height: 36px;
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
            background-color: rgba(255, 255, 255, 0.32);
            color: #ffffff;
            text-decoration: none;
        }

        /* 導覽列白色實心動作按鈕 */
        .nav-btn-action {
            background: #ffffff;
            color: var(--brand-navy);
            border: none;
            font-size: 0.88rem;
            font-weight: 700;
            cursor: pointer;
            height: 36px;
            border-radius: 8px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            padding: 0 14px;
            gap: 6px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
            transition: all 0.2s;
            text-decoration: none;
        }

        .nav-btn-action:hover {
            background: #f8fafc;
            color: var(--brand-blue);
            box-shadow: 0 2px 6px rgba(0, 0, 0, 0.15);
            text-decoration: none;
        }

        /* 主容器佈局 */
        .container-fluid-custom {
            max-width: 1600px;
            margin: 0 auto;
            padding: 16px;
        }

        /* 通報階段時間軸 (Status Stepper) */
        .stepper-container {
            display: flex;
            align-items: center;
            justify-content: space-between;
            background: #ffffff;
            border-radius: 12px;
            padding: 16px 24px;
            margin-bottom: 16px;
            border: 1px solid var(--border-color);
            position: relative;
        }

        .step-item {
            display: flex;
            flex-direction: column;
            align-items: center;
            position: relative;
            z-index: 2;
            flex: 1;
        }

        .step-circle {
            width: 36px;
            height: 36px;
            border-radius: 50%;
            background: #e2e8f0;
            color: #64748b;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 700;
            font-size: 14px;
            margin-bottom: 6px;
            border: 3px solid #ffffff;
            box-shadow: 0 0 0 2px #cbd5e1;
            transition: all 0.3s;
        }

        .step-item.active .step-circle {
            background: var(--brand-blue);
            color: #ffffff;
            box-shadow: 0 0 0 2px var(--brand-blue);
        }

        .step-item.completed .step-circle {
            background: #10b981;
            color: #ffffff;
            box-shadow: 0 0 0 2px #10b981;
        }

        .step-title {
            font-size: 13px;
            font-weight: 700;
            color: #475569;
            margin-bottom: 2px;
            text-align: center;
        }

        .step-item.active .step-title {
            color: var(--brand-blue);
        }

        .step-item.completed .step-title {
            color: #047857;
        }

        .step-time {
            font-size: 11px;
            color: #94a3b8;
        }

        .stepper-line {
            position: absolute;
            top: 34px;
            left: 12%;
            right: 12%;
            height: 3px;
            background: #e2e8f0;
            z-index: 1;
        }

        .stepper-line-fill {
            height: 100%;
            background: #10b981;
            transition: width 0.4s ease;
        }

        /* 現代卡片 */
        .card-modern {
            background: var(--surface);
            border-radius: 12px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05), 0 4px 12px rgba(15, 23, 42, 0.05);
            margin-bottom: 16px;
            border: 1px solid var(--border-color);
            overflow: hidden;
        }

        .card-modern-header {
            padding: 12px 16px;
            background: #ffffff;
            border-bottom: 1px solid var(--border-color);
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .card-modern-title {
            font-size: 1rem;
            font-weight: 700;
            color: var(--brand-navy);
            margin: 0;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .card-modern-body {
            padding: 16px;
        }

        /* 桌面端左欄固頂 */
        @media screen and (min-width: 1200px) {
            .sticky-sidebar {
                position: sticky;
                top: 72px;
                max-height: calc(100vh - 88px);
                overflow-y: auto;
                padding-right: 4px;
            }
        }

        /* 規格數據晶片組 (Stat Chips) */
        .stat-chip-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(130px, 1fr));
            gap: 10px;
            margin-top: 10px;
            margin-bottom: 12px;
        }

        .stat-chip {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 10px 12px;
            text-align: center;
            transition: all 0.2s;
        }

        .stat-chip:hover {
            border-color: #cbd5e1;
            background: #f1f5f9;
        }

        .stat-chip-label {
            font-size: 12px;
            color: var(--text-muted);
            margin-bottom: 4px;
        }

        .stat-chip-value {
            font-size: 1.15rem;
            font-weight: 700;
            color: var(--brand-blue);
        }

        .stat-chip-unit {
            font-size: 11px;
            color: #64748b;
            margin-left: 2px;
        }

        /* 資訊清單表格 */
        .info-table {
            width: 100%;
            border-collapse: collapse;
        }

        .info-table th {
            width: 32%;
            background-color: #f8fafc;
            color: #475569;
            font-weight: 600;
            font-size: 13px;
            padding: 10px 12px;
            border-bottom: 1px solid #e2e8f0;
            vertical-align: middle;
        }

        .info-table td {
            font-size: 13px;
            padding: 10px 12px;
            border-bottom: 1px solid #e2e8f0;
            color: #0f172a;
            vertical-align: middle;
            word-break: break-all;
        }

        .info-table tr:last-child th,
        .info-table tr:last-child td {
            border-bottom: none;
        }

        /* 地圖容器 */
        #map {
            width: 100%;
            height: 260px;
            border-radius: 8px;
            z-index: 10;
            transition: height 0.3s ease;
        }

        #map.map-collapsed {
            height: 80px !important;
        }

        /* 地圖標記 Pin */
        .custom-map-marker {
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .marker-pin {
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

        .marker-pin i {
            transform: rotate(45deg);
            color: #ffffff;
            font-size: 13px;
        }

        /* 檢測項目與狀態點檢卡片 */
        .check-item-row {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 9px 12px;
            border-bottom: 1px solid #f1f5f9;
            font-size: 13px;
        }

        .check-item-row:last-child {
            border-bottom: none;
        }

        .check-item-title {
            color: #334155;
            font-weight: 500;
            flex: 1;
            padding-right: 10px;
        }

        /* 檢測數值雙欄對比卡片 */
        .smoke-test-box {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 10px;
            padding: 14px;
            margin-bottom: 12px;
        }

        .smoke-test-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 10px;
            padding-bottom: 8px;
            border-bottom: 1px dashed #cbd5e1;
        }

        .smoke-test-title {
            font-size: 14px;
            font-weight: 700;
            color: var(--brand-navy);
            display: flex;
            align-items: center;
            gap: 6px;
        }

        /* 照片網格 */
        .photo-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
            gap: 14px;
        }

        .photo-card {
            background: #ffffff;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
            transition: transform 0.2s, box-shadow 0.2s;
            display: flex;
            flex-direction: column;
        }

        .photo-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 10px rgba(0, 0, 0, 0.1);
        }

        .photo-img-wrap {
            position: relative;
            width: 100%;
            height: 130px;
            background: #f1f5f9;
            overflow: hidden;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .photo-img {
            width: 100%;
            height: 100%;
            object-fit: cover;
            transition: transform 0.3s;
        }

        .photo-card:hover .photo-img {
            transform: scale(1.05);
        }

        .photo-empty {
            color: #94a3b8;
            font-size: 12px;
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 6px;
        }

        .photo-title-bar {
            padding: 8px 10px;
            background: #ffffff;
            border-top: 1px solid #e2e8f0;
            font-size: 12px;
            font-weight: 600;
            color: #334155;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        /* 審查歷史時間軸 */
        .history-timeline {
            position: relative;
            padding-left: 20px;
        }

        .history-timeline::before {
            content: '';
            position: absolute;
            left: 7px;
            top: 4px;
            bottom: 4px;
            width: 2px;
            background: #cbd5e1;
        }

        .history-item {
            position: relative;
            margin-bottom: 14px;
        }

        .history-item:last-child {
            margin-bottom: 0;
        }

        .history-dot {
            position: absolute;
            left: -20px;
            top: 4px;
            width: 16px;
            height: 16px;
            border-radius: 50%;
            background: #ffffff;
            border: 3px solid var(--brand-blue);
        }

        .history-content {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 10px 14px;
        }

        /* 審查作業晶片按鈕 */
        .audit-choice-group {
            display: flex;
            gap: 10px;
            margin-bottom: 12px;
        }

        .audit-choice-btn {
            flex: 1;
            padding: 12px;
            border-radius: 8px;
            border: 2px solid #e2e8f0;
            background: #ffffff;
            font-weight: 700;
            font-size: 15px;
            color: #475569;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            transition: all 0.2s;
        }

        .audit-choice-btn.active-pass {
            border-color: #10b981;
            background: #ecfdf5;
            color: #047857;
            box-shadow: 0 2px 6px rgba(16, 185, 129, 0.25);
        }

        .audit-choice-btn.active-fail {
            border-color: #ef4444;
            background: #fef2f2;
            color: #b91c1c;
            box-shadow: 0 2px 6px rgba(239, 68, 68, 0.25);
        }

        /* 常用意見片語標籤 */
        .phrase-pill-group {
            display: flex;
            flex-wrap: wrap;
            gap: 6px;
            margin-bottom: 10px;
        }

        .phrase-pill {
            background: #f1f5f9;
            border: 1px solid #cbd5e1;
            border-radius: 6px;
            padding: 4px 10px;
            font-size: 12px;
            color: #334155;
            cursor: pointer;
            transition: all 0.15s;
        }

        .phrase-pill:hover {
            background: #e2e8f0;
            color: #0f172a;
        }

        /* Lightbox 全螢幕圖片檢視 Modal */
        .lightbox-modal {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(15, 23, 42, 0.88);
            z-index: 2000;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }

        .lightbox-content {
            position: relative;
            max-width: 90vw;
            max-height: 85vh;
            display: flex;
            flex-direction: column;
            align-items: center;
        }

        .lightbox-img {
            max-width: 100%;
            max-height: 75vh;
            border-radius: 8px;
            box-shadow: 0 8px 30px rgba(0, 0, 0, 0.5);
            transition: transform 0.3s ease;
        }

        .lightbox-toolbar {
            margin-top: 14px;
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .lightbox-btn {
            background: rgba(255, 255, 255, 0.2);
            border: 1px solid rgba(255, 255, 255, 0.4);
            color: #ffffff;
            border-radius: 6px;
            padding: 6px 14px;
            font-size: 13px;
            cursor: pointer;
            transition: all 0.2s;
        }

        .lightbox-btn:hover {
            background: rgba(255, 255, 255, 0.35);
        }

        /* 手機底部懸浮列 */
        @media screen and (max-width: 991px) {
            body {
                padding-bottom: 76px;
            }

            .mobile-bottom-bar {
                display: flex;
                position: fixed;
                bottom: 0;
                left: 0;
                right: 0;
                z-index: 1010;
                background: #ffffff;
                border-top: 1px solid #e2e8f0;
                box-shadow: 0 -4px 16px rgba(0, 0, 0, 0.08);
                padding: 10px 16px;
                padding-bottom: calc(10px + env(safe-area-inset-bottom, 0px));
                gap: 10px;
            }

            .mobile-bottom-bar .btn {
                flex: 1;
                font-weight: 700;
                padding: 10px;
                border-radius: 8px;
            }
        }

        /* 列印專用樣式 */
        @media print {
            .no-print, .top-navbar, .stepper-container, .mobile-bottom-bar, #map, .lightbox-modal {
                display: none !important;
            }

            body {
                background: #ffffff !important;
                color: #000000 !important;
            }

            .container-fluid-custom {
                max-width: 100% !important;
                padding: 0 !important;
            }

            .card-modern {
                box-shadow: none !important;
                border: 1px solid #666666 !important;
                page-break-inside: avoid;
                margin-bottom: 12px !important;
            }

            .card-modern-header {
                background: #f0f0f0 !important;
                border-bottom: 1px solid #666666 !important;
            }

            .print-header {
                display: block !important;
                text-align: center;
                margin-bottom: 16px;
                border-bottom: 2px solid #000;
                padding-bottom: 8px;
            }
        }

        .print-header {
            display: none;
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div id="app" v-cloak>
            <!-- 1. 置頂導覽列 (Sticky Top Navbar) -->
            <header class="top-navbar no-print">
                <div class="d-flex align-items-center">
                    <button type="button" class="nav-btn mr-2" v-on:click="goBack" title="返回審查清單">
                        <i class="fas fa-arrow-left"></i>
                        <span class="d-none d-sm-inline">返回清單</span>
                    </button>
                    <a class="brand-title">
                        <i class="fas fa-truck-pickup text-white"></i>
                        <span>施工機具審查作業</span>
                        <span v-if="macData.mac_Type" class="badge badge-light text-dark font-weight-bold ml-1 d-none d-md-inline" style="font-size: 0.85rem;">
                            {{ macData.mac_Type }} #{{ macId }}
                        </span>
                        <span v-if="reviewStageTitle" class="badge badge-warning text-dark font-weight-bold ml-1" style="font-size: 0.82rem;">
                            {{ reviewStageTitle }}
                        </span>
                    </a>
                </div>

                <div class="d-flex align-items-center gap-2">
                    <button type="button" class="nav-btn-action" v-on:click="printCase" title="列印此紀錄">
                        <i class="fas fa-print"></i>
                        <span class="d-none d-md-inline">列印案件</span>
                    </button>
                    <button v-if="isReviewMode" type="button" class="btn btn-warning btn-sm font-weight-bold shadow-sm ml-2" v-on:click="scrollToReview">
                        <i class="fas fa-clipboard-check mr-1"></i>
                        <span>前往審查</span>
                    </button>
                </div>
            </header>

            <!-- 列印專用抬頭 (紙本呈現) -->
            <div class="print-header">
                <h3 style="margin: 0; font-weight: 800;">新北市政府環境保護局 - 施工機具現場查核紀錄表</h3>
                <small>場所名稱：{{ facInfo.FAC_NAME }} ({{ facInfo.FAC_ID }}) ｜ 機具編號：#{{ macId }} ｜ 列印時間：{{ printDateStr }}</small>
            </div>

            <!-- 主作業容器 -->
            <main class="container-fluid-custom">
                <!-- 2. 階段進度時間軸 (Status Stepper) -->
                <div class="stepper-container shadow-sm no-print">
                    <div class="stepper-line">
                        <div class="stepper-line-fill" :style="{ width: stepperProgress + '%' }"></div>
                    </div>

                    <!-- 步驟 1: 現場調查建檔 -->
                    <div class="step-item" :class="getStepClass(1)">
                        <div class="step-circle">
                            <i v-if="numericStepCode > 1" class="fas fa-check"></i>
                            <span v-else>1</span>
                        </div>
                        <div class="step-title">現場調查建檔</div>
                        <div class="step-time">{{ macData.Check_date_format || '未填寫' }}</div>
                    </div>

                    <!-- 步驟 2: 審核作業評定 -->
                    <div class="step-item" :class="getStepClass(2)">
                        <div class="step-circle">
                            <i v-if="numericStepCode > 2" class="fas fa-check"></i>
                            <span v-else>2</span>
                        </div>
                        <div class="step-title">{{ getStep2Title() }}</div>
                        <div class="step-time">{{ getLatestReviewTime() }}</div>
                    </div>

                    <!-- 步驟 3: 核發標章結案 -->
                    <div class="step-item" :class="getStepClass(3)">
                        <div class="step-circle">
                            <i v-if="numericStepCode === 3" class="fas fa-check"></i>
                            <span v-else>3</span>
                        </div>
                        <div class="step-title">核發標章結案</div>
                        <div class="step-time">{{ macData.Mark_NO ? '標章: ' + macData.Mark_NO : '待核發' }}</div>
                    </div>
                </div>

                <!-- 載入中骨架提示 -->
                <div v-if="loading" class="text-center py-5">
                    <div class="spinner-border text-primary" role="status" style="width: 3rem; height: 3rem;">
                        <span class="sr-only">資料載入中...</span>
                    </div>
                    <p class="text-muted mt-3 font-weight-bold">正在讀取機具與場所詳細資料，請稍候...</p>
                </div>

                <!-- 主要雙欄內容佈局 (Desktop: 40% 左欄 / 60% 右欄) -->
                <div v-else class="row">
                    <!-- ====================== 左欄 (40% 寬度) ====================== -->
                    <div class="col-xl-5 col-lg-5 col-md-12">
                        <div class="sticky-sidebar">
                            <!-- 卡片 1: 場所基本資料 -->
                            <div class="card-modern">
                                <div class="card-modern-header">
                                    <h5 class="card-modern-title">
                                        <i class="fas fa-building text-primary"></i> 場所基本資料
                                    </h5>
                                    <span class="badge badge-light text-dark font-weight-bold">{{ facInfo.FAC_ID }}</span>
                                </div>
                                <div class="card-modern-body p-0">
                                    <table class="info-table">
                                        <tbody>
                                            <tr>
                                                <th>場所名稱</th>
                                                <td class="font-weight-bold text-primary">{{ facInfo.FAC_NAME || '-' }}</td>
                                            </tr>
                                            <tr>
                                                <th>管制編號</th>
                                                <td>{{ facInfo.C_NO || '-' }}</td>
                                            </tr>
                                            <tr>
                                                <th>行業別</th>
                                                <td>{{ facInfo.Industrial || facInfo.INDUSTRIAL_Name || '-' }}</td>
                                            </tr>
                                            <tr>
                                                <th>工廠登記證</th>
                                                <td>{{ facInfo.Lic_NO || '-' }}</td>
                                            </tr>
                                            <tr>
                                                <th>統一編號</th>
                                                <td>{{ facInfo.S_C_ID || '-' }}</td>
                                            </tr>
                                            <tr>
                                                <th>場所性質</th>
                                                <td>{{ facInfo.FAC_TYPE1 || '-' }}</td>
                                            </tr>
                                            <tr>
                                                <th>場所地址</th>
                                                <td>{{ facInfo.ADDR || '-' }}</td>
                                            </tr>
                                            <tr>
                                                <th>座落地號</th>
                                                <td>{{ facInfo.Land_no || '-' }}</td>
                                            </tr>
                                            <tr>
                                                <th>作業用地面積</th>
                                                <td>{{ facInfo.Use_Area ? facInfo.Use_Area + ' ㎡' : '-' }}</td>
                                            </tr>
                                            <tr>
                                                <th>負責人 / 電話</th>
                                                <td>{{ facInfo.BOSS_NAME || '-' }} ｜ {{ facInfo.TEL || '-' }}</td>
                                            </tr>
                                            <tr>
                                                <th>聯絡人 / 傳真</th>
                                                <td>{{ facInfo.Content_Name || '-' }} ｜ {{ facInfo.FAX || '-' }}</td>
                                            </tr>
                                        </tbody>
                                    </table>
                                </div>
                            </div>

                            <!-- 卡片 2: 現場地理位置與地圖 (Leaflet.js) -->
                            <div class="card-modern no-print">
                                <div class="card-modern-header">
                                    <h5 class="card-modern-title">
                                        <i class="fas fa-map-marker-alt text-danger"></i> 場所地理位置
                                    </h5>
                                    <div class="d-flex align-items-center gap-1">
                                        <button v-if="facInfo.Lat && facInfo.Lng" type="button" class="btn btn-outline-success btn-sm font-weight-bold" v-on:click="openGoogleMaps" title="開啟 Google Maps 路線導航">
                                            <i class="fas fa-location-arrow mr-1"></i>導航
                                        </button>
                                        <button type="button" class="btn btn-outline-secondary btn-sm ml-1" v-on:click="toggleMapCollapse">
                                            <i class="fas" :class="mapCollapsed ? 'fa-expand-alt' : 'fa-compress-alt'"></i>
                                            <span class="d-none d-sm-inline">{{ mapCollapsed ? '展開' : '收合' }}</span>
                                        </button>
                                    </div>
                                </div>
                                <div class="card-modern-body p-2">
                                    <div id="map" :class="{ 'map-collapsed': mapCollapsed }"></div>
                                    <div v-if="!facInfo.Lat || !facInfo.Lng" class="text-center text-muted small py-2">
                                        <i class="fas fa-info-circle mr-1"></i>本場所尚未建立 TWD97 / WGS84 座標資料
                                    </div>
                                    <div v-else class="d-flex justify-content-between align-items-center px-1 pt-2 small text-muted">
                                        <span>經緯度：{{ facInfo.Lat.toFixed(5) }}, {{ facInfo.Lng.toFixed(5) }}</span>
                                        <span class="badge badge-success">座標已校驗</span>
                                    </div>
                                </div>
                            </div>

                            <!-- 卡片 3: 機具產權與營運狀況 -->
                            <div class="card-modern">
                                <div class="card-modern-header">
                                    <h5 class="card-modern-title">
                                        <i class="fas fa-id-card-alt text-info"></i> 機具產權與營運狀況
                                    </h5>
                                </div>
                                <div class="card-modern-body p-0">
                                    <table class="info-table">
                                        <tbody>
                                            <tr>
                                                <th>調查日期</th>
                                                <td class="font-weight-bold text-dark">{{ macData.Check_date_format || '-' }}</td>
                                            </tr>
                                            <tr>
                                                <th>機具產權人</th>
                                                <td>{{ macData.mac_boss1 || '-' }} {{ macData.mac_boss2 || '' }}</td>
                                            </tr>
                                            <tr>
                                                <th>產權人電話</th>
                                                <td>{{ macData.mac_boss_tel || '-' }}</td>
                                            </tr>
                                            <tr>
                                                <th>操作駕駛姓名</th>
                                                <td class="font-weight-bold">{{ macData.Driver_Name || '-' }}</td>
                                            </tr>
                                            <tr>
                                                <th>駕駛聯絡電話</th>
                                                <td>{{ macData.Driver_Tel || '-' }}</td>
                                            </tr>
                                            <tr>
                                                <th>專責駕駛操作</th>
                                                <td>
                                                    <span class="badge" :class="macData.one_Driver === '是' ? 'badge-success' : 'badge-secondary'">
                                                        {{ macData.one_Driver || '未填寫' }}
                                                    </span>
                                                </td>
                                            </tr>
                                            <tr>
                                                <th>常駐本場所</th>
                                                <td>
                                                    <span class="badge" :class="macData.Always_Here === '是' ? 'badge-primary' : 'badge-light text-dark'">
                                                        {{ macData.Always_Here || '-' }}
                                                    </span>
                                                </td>
                                            </tr>
                                            <tr>
                                                <th>運輸進出模式</th>
                                                <td>{{ macData.Move_Mode || '-' }}</td>
                                            </tr>
                                            <tr>
                                                <th>機具使用時機</th>
                                                <td>{{ macData.When_To_Use || '-' }}</td>
                                            </tr>
                                            <tr>
                                                <th>燃料油品來源</th>
                                                <td>{{ macData.Oil_From || '-' }}</td>
                                            </tr>
                                            <tr>
                                                <th>排放黑煙行為</th>
                                                <td>
                                                    <span class="badge" :class="macData.Black_Smoke === '有' ? 'badge-danger' : 'badge-success'">
                                                        {{ macData.Black_Smoke === '有' ? '有排放黑煙' : '無排放黑煙' }}
                                                    </span>
                                                </td>
                                            </tr>
                                            <tr>
                                                <th>曾受陳情檢舉</th>
                                                <td>
                                                    <span class="badge" :class="macData.Report_Black_Smoke === '有' ? 'badge-danger' : 'badge-light text-dark'">
                                                        {{ macData.Report_Black_Smoke || '無' }}
                                                    </span>
                                                </td>
                                            </tr>
                                        </tbody>
                                    </table>
                                </div>
                            </div>

                            <!-- 卡片 4: 保養與防制設備 -->
                            <div class="card-modern">
                                <div class="card-modern-header">
                                    <h5 class="card-modern-title">
                                        <i class="fas fa-wrench text-warning"></i> 保養維護與防制設備
                                    </h5>
                                </div>
                                <div class="card-modern-body p-0">
                                    <table class="info-table">
                                        <tbody>
                                            <tr>
                                                <th>保養地點</th>
                                                <td>{{ macData.Maintenance_Place || '-' }}</td>
                                            </tr>
                                            <tr>
                                                <th>保養廠名稱</th>
                                                <td>{{ macData.Maintenance_PlaceName || '-' }}</td>
                                            </tr>
                                            <tr>
                                                <th>平常保養頻率</th>
                                                <td>
                                                    {{ macData.Maintenance_Frequency || '-' }} {{ macData.Maintenance_Frequency_Unit || '' }}
                                                </td>
                                            </tr>
                                            <tr>
                                                <th>保養方式</th>
                                                <td>{{ macData.Maintenance_Type || '-' }}</td>
                                            </tr>
                                            <tr>
                                                <th>年均維修費用</th>
                                                <td>{{ formatCurrency(macData.Maintenance_Price) }}</td>
                                            </tr>
                                            <tr>
                                                <th>污染防制設備</th>
                                                <td>
                                                    <span class="badge" :class="macData.Control_equipment === '有' ? 'badge-success' : 'badge-secondary'">
                                                        {{ macData.Control_equipment === '有' ? '已加裝防制設備' : (macData.Control_equipment || '無') }}
                                                    </span>
                                                </td>
                                            </tr>
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- ====================== 右欄 (60% 寬度) ====================== -->
                    <div class="col-xl-7 col-lg-7 col-md-12">
                        <!-- 卡片 1: 機具核心規格與性能 -->
                        <div class="card-modern">
                            <div class="card-modern-header">
                                <h5 class="card-modern-title">
                                    <i class="fas fa-cogs text-primary"></i> 施工機具規格與性能數據
                                </h5>
                                <span class="badge badge-primary font-weight-bold" style="font-size: 0.85rem;">
                                    {{ macData.Brand || '' }} {{ macData.model || '' }}
                                </span>
                            </div>
                            <div class="card-modern-body">
                                <!-- 數據晶片組 (Stat Chips) -->
                                <div class="stat-chip-grid">
                                    <div class="stat-chip">
                                        <div class="stat-chip-label">出廠年份</div>
                                        <div class="stat-chip-value">{{ macData.Out_YEAR || '-' }}</div>
                                    </div>
                                    <div class="stat-chip">
                                        <div class="stat-chip-label">機具總重</div>
                                        <div class="stat-chip-value">
                                            {{ macData.Weight || '-' }}<span class="stat-chip-unit">噸</span>
                                        </div>
                                    </div>
                                    <div class="stat-chip">
                                        <div class="stat-chip-label">額定馬力</div>
                                        <div class="stat-chip-value">
                                            {{ macData.Power || '-' }}<span class="stat-chip-unit">{{ macData.Power_Unit || 'HP' }}</span>
                                        </div>
                                    </div>
                                    <div class="stat-chip">
                                        <div class="stat-chip-label">額定轉速</div>
                                        <div class="stat-chip-value">
                                            {{ macData.Rotating_speed || '-' }}<span class="stat-chip-unit">rpm</span>
                                        </div>
                                    </div>
                                    <div class="stat-chip">
                                        <div class="stat-chip-label">引擎排氣量</div>
                                        <div class="stat-chip-value">
                                            {{ macData.Exhaust_volume || '-' }}<span class="stat-chip-unit">c.c.</span>
                                        </div>
                                    </div>
                                    <div class="stat-chip">
                                        <div class="stat-chip-label">購置費用</div>
                                        <div class="stat-chip-value" style="font-size: 1rem;">
                                            {{ formatCurrency(macData.MachinePrice) }}
                                        </div>
                                    </div>
                                </div>

                                <!-- 詳細規格表 -->
                                <table class="info-table mt-3">
                                    <tbody>
                                        <tr>
                                            <th>種類型式</th>
                                            <td class="font-weight-bold text-dark">{{ macData.mac_Type || '-' }}</td>
                                        </tr>
                                        <tr>
                                            <th>廠牌名稱</th>
                                            <td>{{ macData.Brand || '-' }}</td>
                                        </tr>
                                        <tr>
                                            <th>機具型號</th>
                                            <td>{{ macData.model || '-' }}</td>
                                        </tr>
                                        <tr>
                                            <th>機身號碼 (PIN)</th>
                                            <td class="font-weight-bold text-primary">{{ macData.PIN || '-' }}</td>
                                        </tr>
                                        <tr>
                                            <th>引擎號碼</th>
                                            <td class="font-weight-bold text-dark">{{ macData.Engine_NO || '-' }}</td>
                                        </tr>
                                        <tr>
                                            <th>排氣管朝向</th>
                                            <td>{{ macData.Exhaust_Side || '-' }}</td>
                                        </tr>
                                        <tr>
                                            <th>油門型式</th>
                                            <td>{{ macData.accelerator || '-' }}</td>
                                        </tr>
                                    </tbody>
                                </table>
                            </div>
                        </div>

                        <!-- 卡片 2: 排煙狀況目視判別與 8 大點檢程序 -->
                        <div class="card-modern">
                            <div class="card-modern-header">
                                <h5 class="card-modern-title">
                                    <i class="fas fa-smog text-secondary"></i> 目視排煙判別與點檢程序
                                </h5>
                                <span class="badge badge-light text-muted">查核項目</span>
                            </div>
                            <div class="card-modern-body">
                                <h6 class="font-weight-bold text-dark mb-2">一、排煙狀況目視判別</h6>
                                <div class="row mb-3">
                                    <div class="col-md-4 col-sm-12 mb-2">
                                        <div class="p-2 border rounded bg-light text-center">
                                            <small class="text-muted d-block font-weight-bold">啟動瞬間</small>
                                            <span class="badge mt-1" :class="getSmokeStatusBadge(macData.Smoke_Start)">
                                                {{ macData.Smoke_Start || '未記錄' }}
                                            </span>
                                        </div>
                                    </div>
                                    <div class="col-md-4 col-sm-12 mb-2">
                                        <div class="p-2 border rounded bg-light text-center">
                                            <small class="text-muted d-block font-weight-bold">暖機階段</small>
                                            <span class="badge mt-1" :class="getSmokeStatusBadge(macData.Smoke_Warn)">
                                                {{ macData.Smoke_Warn || '未記錄' }}
                                            </span>
                                        </div>
                                    </div>
                                    <div class="col-md-4 col-sm-12 mb-2">
                                        <div class="p-2 border rounded bg-light text-center">
                                            <small class="text-muted d-block font-weight-bold">檢測階段</small>
                                            <span class="badge mt-1" :class="getSmokeStatusBadge(macData.Smoke_Test)">
                                                {{ macData.Smoke_Test || '未記錄' }}
                                            </span>
                                        </div>
                                    </div>
                                </div>

                                <h6 class="font-weight-bold text-dark mb-2">二、不透光率檢測點檢程序 (8 大項)</h6>
                                <div class="border rounded">
                                    <div class="check-item-row">
                                        <span class="check-item-title">1. 循序漸進增加油門開度，以逐漸增加引擎轉速，觀察有無異音</span>
                                        <span class="badge" :class="getItemPassBadge(macData.Light_Item1)">{{ macData.Light_Item1 || '未填寫' }}</span>
                                    </div>
                                    <div class="check-item-row">
                                        <span class="check-item-title">2. 排氣管有無破洞、漏氣</span>
                                        <span class="badge" :class="getItemPassBadge(macData.Light_Item2)">{{ macData.Light_Item2 || '未填寫' }}</span>
                                    </div>
                                    <div class="check-item-row">
                                        <span class="check-item-title">3. 引擎運轉時溫度是否無偏高情形</span>
                                        <span class="badge" :class="getItemPassBadge(macData.Light_Item3)">{{ macData.Light_Item3 || '未填寫' }}</span>
                                    </div>
                                    <div class="check-item-row">
                                        <span class="check-item-title">4. 潤滑機油是否足夠 (本項應於暖車前檢查)</span>
                                        <span class="badge" :class="getItemPassBadge(macData.Light_Item4)">{{ macData.Light_Item4 || '未填寫' }}</span>
                                    </div>
                                    <div class="check-item-row">
                                        <span class="check-item-title">5. 引擎本體有無漏油現象</span>
                                        <span class="badge" :class="getItemPassBadge(macData.Light_Item5)">{{ macData.Light_Item5 || '未填寫' }}</span>
                                    </div>
                                    <div class="check-item-row">
                                        <span class="check-item-title">6. 循序漸進增加油門開度，觀察機具本體有無明顯搖晃</span>
                                        <span class="badge" :class="getItemPassBadge(macData.Light_Item6)">{{ macData.Light_Item6 || '未填寫' }}</span>
                                    </div>
                                    <div class="check-item-row">
                                        <span class="check-item-title">7. 機具外觀有無嚴重損壞</span>
                                        <span class="badge" :class="getItemPassBadge(macData.Light_Item7)">{{ macData.Light_Item7 || '未填寫' }}</span>
                                    </div>
                                    <div class="check-item-row">
                                        <span class="check-item-title">8. 引擎運轉時排氣管或引擎本體附近有無明顯排放白煙</span>
                                        <span class="badge" :class="getItemPassBadge(macData.Light_Item8)">{{ macData.Light_Item8 || '未填寫' }}</span>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- 卡片 3: 不透光率排煙儀器檢測結果 -->
                        <div class="card-modern">
                            <div class="card-modern-header">
                                <h5 class="card-modern-title">
                                    <i class="fas fa-tachometer-alt text-success"></i> 施工機具不透光率儀器排煙檢測結果
                                </h5>
                                <span class="badge badge-light text-muted">法規標準值 ≤ 1.0 m⁻¹</span>
                            </div>
                            <div class="card-modern-body">
                                <div class="row">
                                    <!-- 啟動值 -->
                                    <div class="col-md-6 col-sm-12">
                                        <div class="smoke-test-box">
                                            <div class="smoke-test-header">
                                                <span class="smoke-test-title">
                                                    <i class="fas fa-play text-primary"></i> 啟動值排煙檢測
                                                </span>
                                                <span class="badge" :class="macData.opaque_Start_Pass ? 'badge-success' : 'badge-danger'">
                                                    {{ macData.opaque_Start_Pass ? '判定合格' : '超出標準' }}
                                                </span>
                                            </div>

                                            <div class="d-flex justify-content-between mb-2 small text-muted">
                                                <span>檢測前排氣管溫度：</span>
                                                <strong class="text-dark">{{ macData.Tempeture_Start || '-' }} ℃</strong>
                                            </div>

                                            <table class="table table-sm table-bordered text-center mb-2 small">
                                                <thead class="bg-light">
                                                    <tr>
                                                        <th>第 1 次</th>
                                                        <th>第 2 次</th>
                                                        <th>第 3 次</th>
                                                        <th class="bg-primary text-white">平均值</th>
                                                    </tr>
                                                </thead>
                                                <tbody>
                                                    <tr>
                                                        <td>{{ macData.opaque_Start1 || '-' }}</td>
                                                        <td>{{ macData.opaque_Start2 || '-' }}</td>
                                                        <td>{{ macData.opaque_Start3 || '-' }}</td>
                                                        <td class="font-weight-bold text-primary" style="font-size: 1rem;">
                                                            {{ macData.opaque_Start_Avg }}
                                                        </td>
                                                    </tr>
                                                </tbody>
                                            </table>
                                            <small class="text-muted d-block text-right">單位：m⁻¹</small>
                                        </div>
                                    </div>

                                    <!-- 運行值 -->
                                    <div class="col-md-6 col-sm-12">
                                        <div class="smoke-test-box">
                                            <div class="smoke-test-header">
                                                <span class="smoke-test-title">
                                                    <i class="fas fa-forward text-warning"></i> 運行值排煙檢測 (全負荷)
                                                </span>
                                                <span class="badge" :class="macData.opaque_Run_Pass ? 'badge-success' : 'badge-danger'">
                                                    {{ macData.opaque_Run_Pass ? '判定合格' : '超出標準' }}
                                                </span>
                                            </div>

                                            <div class="d-flex justify-content-between mb-2 small text-muted">
                                                <span>檢測前排氣管溫度：</span>
                                                <strong class="text-dark">{{ macData.Tempeture_Run || '-' }} ℃</strong>
                                            </div>

                                            <table class="table table-sm table-bordered text-center mb-2 small">
                                                <thead class="bg-light">
                                                    <tr>
                                                        <th>第 1 次</th>
                                                        <th>第 2 次</th>
                                                        <th>第 3 次</th>
                                                        <th class="bg-warning text-dark font-weight-bold">平均值</th>
                                                    </tr>
                                                </thead>
                                                <tbody>
                                                    <tr>
                                                        <td>{{ macData.opaque_Run1 || '-' }}</td>
                                                        <td>{{ macData.opaque_Run2 || '-' }}</td>
                                                        <td>{{ macData.opaque_Run3 || '-' }}</td>
                                                        <td class="font-weight-bold text-dark" style="font-size: 1rem;">
                                                            {{ macData.opaque_Run_Avg }}
                                                        </td>
                                                    </tr>
                                                </tbody>
                                            </table>
                                            <small class="text-muted d-block text-right">單位：m⁻¹</small>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- 卡片 4: 施工機具核發標章 -->
                        <div class="card-modern">
                            <div class="card-modern-header">
                                <h5 class="card-modern-title">
                                    <i class="fas fa-certificate text-warning"></i> 施工機具核發標章資料
                                </h5>
                                <span v-if="macData.Mark_NO" class="badge" :class="macData.IsExpired ? 'badge-danger' : 'badge-success'">
                                    {{ macData.IsExpired ? '標章已逾期' : '標章有效' }}
                                </span>
                            </div>
                            <div class="card-modern-body p-0">
                                <table class="info-table">
                                    <tbody>
                                        <tr>
                                            <th>標章編號</th>
                                            <td class="font-weight-bold" style="font-size: 1.05rem; color: #0284c7;">
                                                {{ macData.Mark_NO || '尚未核發' }}
                                            </td>
                                        </tr>
                                        <tr>
                                            <th>標章有效期限</th>
                                            <td>
                                                <span>{{ macData.Mark_Deadline_format || '-' }}</span>
                                                <span v-if="macData.IsExpired" class="badge badge-danger ml-2">已過期</span>
                                            </td>
                                        </tr>
                                    </tbody>
                                </table>
                            </div>
                        </div>

                        <!-- 卡片 5: 佐證照片與證明文件 (Lightbox 相簿) -->
                        <div class="card-modern">
                            <div class="card-modern-header">
                                <h5 class="card-modern-title">
                                    <i class="fas fa-images text-info"></i> 查核佐證照片與證明文件
                                </h5>
                                <span class="badge badge-light text-muted">共 {{ photoList.length }} 項文件</span>
                            </div>
                            <div class="card-modern-body">
                                <div class="photo-grid">
                                    <div v-for="(p, idx) in photoList" :key="idx" class="photo-card">
                                        <div class="photo-img-wrap" v-on:click="p.Exists && openLightbox(idx)">
                                            <img v-if="p.Exists" :src="p.Url" :alt="p.Title" class="photo-img" />
                                            <div v-else class="photo-empty">
                                                <i class="fas fa-image fa-2x"></i>
                                                <span>尚未上傳照片</span>
                                            </div>
                                        </div>
                                        <div class="photo-title-bar">
                                            <span class="text-truncate" :title="p.Title">{{ p.Title }}</span>
                                            <span v-if="p.Exists" class="badge badge-success">已具備</span>
                                            <span v-else class="badge badge-light text-muted">缺漏</span>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- 卡片 6: 歷次審核紀錄 (時間軸) -->
                        <div class="card-modern">
                            <div class="card-modern-header">
                                <h5 class="card-modern-title">
                                    <i class="fas fa-history text-secondary"></i> 歷次案件審核紀錄
                                </h5>
                                <span class="badge badge-light text-dark">{{ historyList.length }} 筆歷程</span>
                            </div>
                            <div class="card-modern-body">
                                <div v-if="historyList.length === 0" class="text-center py-4 text-muted">
                                    <i class="fas fa-inbox fa-2x mb-2 d-block"></i>
                                    <span>目前尚無任何審核評定紀錄</span>
                                </div>
                                <div v-else class="history-timeline">
                                    <div v-for="(h, idx) in historyList" :key="idx" class="history-item">
                                        <div class="history-dot"></div>
                                        <div class="history-content">
                                            <div class="d-flex justify-content-between align-items-center mb-1">
                                                <div>
                                                    <strong class="text-dark">{{ h.Name }}</strong>
                                                    <span class="badge badge-secondary ml-2">{{ h.State_Name }}</span>
                                                </div>
                                                <small class="text-muted">{{ h.Chk_Date }}</small>
                                            </div>
                                            <div class="mb-1">
                                                審核結果：
                                                <span class="badge" :class="h.Chk_Result === '通過' ? 'badge-success' : 'badge-danger'">
                                                    {{ h.Chk_Result }}
                                                </span>
                                            </div>
                                            <div v-if="h.Chk_Memo" class="small text-muted p-2 bg-white rounded border">
                                                {{ h.Chk_Memo }}
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- 卡片 7: 審核作業面板 (僅在審查模式出現) -->
                        <div v-if="isReviewMode" id="reviewPanel" class="card-modern border-primary shadow">
                            <div class="card-modern-header bg-primary text-white">
                                <h5 class="card-modern-title text-white">
                                    <i class="fas fa-stamp text-white"></i> {{ reviewStageTitle }} 評定作業
                                </h5>
                                <span class="badge badge-light text-primary font-weight-bold">請填寫審查判定</span>
                            </div>
                            <div class="card-modern-body">
                                <!-- 審核結果晶片選取 -->
                                <label class="font-weight-bold text-dark d-block mb-2">審核結果判定：</label>
                                <div class="audit-choice-group">
                                    <button type="button" class="audit-choice-btn" :class="{ 'active-pass': reviewForm.chkResult === 'PASS' }" v-on:click="reviewForm.chkResult = 'PASS'">
                                        <i class="fas fa-check-circle fa-lg text-success"></i>
                                        <span>審查通過</span>
                                    </button>
                                    <button type="button" class="audit-choice-btn" :class="{ 'active-fail': reviewForm.chkResult === 'FAIL' }" v-on:click="reviewForm.chkResult = 'FAIL'">
                                        <i class="fas fa-times-circle fa-lg text-danger"></i>
                                        <span>案件退回 (退件補正)</span>
                                    </button>
                                </div>

                                <!-- 常用意見快速片語 -->
                                <label class="font-weight-bold text-muted small d-block mb-1">快速套用審核說明：</label>
                                <div class="phrase-pill-group">
                                    <button type="button" class="phrase-pill" v-on:click="applyPhrase('各項機具規格齊全，不透光率儀器檢測數值符合法規標準，予以審查通過。')">
                                        <i class="fas fa-plus mr-1"></i>合格通過
                                    </button>
                                    <button type="button" class="phrase-pill" v-on:click="applyPhrase('檢測數據合格且防制設備運作正常，同意核發施工機具標章。')">
                                        <i class="fas fa-plus mr-1"></i>核發標章
                                    </button>
                                    <button type="button" class="phrase-pill" v-on:click="applyPhrase('上傳之機身編號或引擎編號照片模糊不清，請重新拍攝清晰照片後再審。')">
                                        <i class="fas fa-plus mr-1"></i>照片模糊退補
                                    </button>
                                    <button type="button" class="phrase-pill" v-on:click="applyPhrase('缺少海關證明或原廠出廠證明文件，請備齊證明資料後補正。')">
                                        <i class="fas fa-plus mr-1"></i>證明文件缺漏
                                    </button>
                                    <button type="button" class="phrase-pill" v-on:click="applyPhrase('不透光率排煙檢測平均值超出 1.0 m⁻¹ 標準，請檢修保養後重新檢測上傳。')">
                                        <i class="fas fa-plus mr-1"></i>排煙檢測超標
                                    </button>
                                </div>

                                <!-- 審核說明輸入框 -->
                                <div class="form-group mb-3">
                                    <label class="font-weight-bold text-dark">審查意見與備註說明：</label>
                                    <textarea v-model="reviewForm.chkMemo" class="form-control" rows="4" placeholder="請輸入具體審查說明或退件改善要求..." style="resize: vertical;"></textarea>
                                </div>

                                <!-- 按鈕組 -->
                                <div class="d-flex justify-content-end gap-2">
                                    <button type="button" class="btn btn-outline-secondary px-3 mr-2" v-on:click="goBack">
                                        <i class="fas fa-times mr-1"></i>取消返回
                                    </button>
                                    <button type="button" class="btn btn-primary px-4 font-weight-bold shadow-sm" :disabled="submittingReview" v-on:click="submitReview">
                                        <i class="fas" :class="submittingReview ? 'fa-spinner fa-spin' : 'fa-paper-plane'"></i>
                                        <span class="ml-1">{{ submittingReview ? '儲存中...' : '確認送出審查' }}</span>
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </main>

            <!-- 3. 行動載具底部懸浮動作列 (Mobile Bottom Bar) -->
            <div v-if="isReviewMode" class="mobile-bottom-bar d-lg-none no-print">
                <button type="button" class="btn btn-outline-secondary" v-on:click="goBack">
                    <i class="fas fa-arrow-left mr-1"></i>返回
                </button>
                <button type="button" class="btn btn-primary" v-on:click="scrollToReview">
                    <i class="fas fa-clipboard-check mr-1"></i>前往審查
                </button>
            </div>

            <!-- 4. 全螢幕照片檢視 Lightbox Modal -->
            <div v-if="lightbox.show" class="lightbox-modal no-print" v-on:click.self="closeLightbox">
                <div class="lightbox-content">
                    <img :src="lightbox.currentUrl" :alt="lightbox.title" class="lightbox-img" :style="{ transform: 'rotate(' + lightbox.rotate + 'deg)' }" />
                    <div class="text-white text-center mt-2 font-weight-bold" style="font-size: 1.05rem;">
                        {{ lightbox.title }}
                    </div>
                    <div class="lightbox-toolbar">
                        <button type="button" class="lightbox-btn" v-on:click="prevLightbox">
                            <i class="fas fa-chevron-left mr-1"></i>上一張
                        </button>
                        <button type="button" class="lightbox-btn" v-on:click="rotateLightbox">
                            <i class="fas fa-redo mr-1"></i>旋轉
                        </button>
                        <button type="button" class="lightbox-btn" v-on:click="openOriginalImage">
                            <i class="fas fa-external-link-alt mr-1"></i>原圖
                        </button>
                        <button type="button" class="lightbox-btn" v-on:click="nextLightbox">
                            下一張<i class="fas fa-chevron-right ml-1"></i>
                        </button>
                        <button type="button" class="lightbox-btn" style="background: rgba(239, 68, 68, 0.6);" v-on:click="closeLightbox">
                            <i class="fas fa-times mr-1"></i>關閉 (ESC)
                        </button>
                    </div>
                </div>
            </div>
        </div>
    </form>

    <!-- 本地化核心腳本依賴 -->
    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>
    <script src="../Scripts/leaflet/leaflet.js"></script>

    <script>
        const { createApp, markRaw } = Vue;

        createApp({
            data() {
                return {
                    loading: true,
                    submittingReview: false,
                    facId: '',
                    macId: 0,
                    mode: 'MAC1',
                    hash: '',
                    isReviewMode: true,
                    reviewStageTitle: '審查作業',
                    mapCollapsed: false,
                    leafletMap: null,
                    marker: null,

                    facInfo: {},
                    macData: {},
                    photoList: [],
                    historyList: [],

                    reviewForm: {
                        chkResult: 'PASS',
                        chkMemo: ''
                    },

                    lightbox: {
                        show: false,
                        currentIndex: 0,
                        currentUrl: '',
                        title: '',
                        rotate: 0
                    },

                    printDateStr: new Date().toLocaleDateString('zh-TW', { year: 'numeric', month: '2-digit', day: '2-digit' })
                };
            },
            computed: {
                numericStepCode() {
                    if (this.macData.Mark_NO && this.macData.Mark_NO.trim() !== '') {
                        return 3;
                    }
                    if (this.historyList.length > 0 || this.macData.Mac_State === 'A01' || this.macData.Mac_State === 'A02') {
                        return 2;
                    }
                    return 1;
                },
                stepperProgress() {
                    if (this.numericStepCode === 3) return 100;
                    if (this.numericStepCode === 2) return 50;
                    return 0;
                }
            },
            mounted() {
                this.parseUrlParams();
                this.fetchData();
                window.addEventListener('keydown', this.handleKeyDown);
            },
            beforeUnmount() {
                window.removeEventListener('keydown', this.handleKeyDown);
                if (this.leafletMap) {
                    this.leafletMap.remove();
                }
            },
            methods: {
                parseUrlParams() {
                    const urlParams = new URLSearchParams(window.location.search);
                    this.facId = (urlParams.get('fac') || '').trim();
                    this.macId = parseInt(urlParams.get('macid') || '0', 10);
                    this.mode = (urlParams.get('mode') || 'MAC1').trim().toUpperCase();
                    this.hash = (urlParams.get('fac1') || '').trim();
                },
                fetchData() {
                    this.loading = true;
                    axios.get('Check_Step1_Mac.aspx', {
                        params: {
                            action: 'get_data',
                            fac: this.facId,
                            macid: this.macId,
                            mode: this.mode,
                            fac1: this.hash
                        }
                    })
                    .then(res => {
                        this.loading = false;
                        const data = res.data;
                        if (!data.Success) {
                            alert(data.Message || '讀取資料失敗');
                            return;
                        }

                        this.facInfo = data.FacInfo || {};
                        this.macData = data.MacData || {};
                        this.photoList = data.PhotoList || [];
                        this.historyList = data.HistoryList || [];
                        this.isReviewMode = data.IsReviewMode;
                        this.reviewStageTitle = data.ReviewStageTitle || '審查作業';

                        // 初始化預設審核說明
                        if (this.isReviewMode && !this.reviewForm.chkMemo) {
                            this.reviewForm.chkMemo = '各項資料與檢測數據合規，同意予以通過。';
                        }

                        // 初始化 Leaflet 地圖
                        this.$nextTick(() => {
                            this.initMap();
                        });
                    })
                    .catch(err => {
                        this.loading = false;
                        alert('載入失敗（網路或伺服器連線異常）：' + err.message);
                    });
                },
                initMap() {
                    if (this.leafletMap) return;
                    const mapEl = document.getElementById('map');
                    if (!mapEl) return;

                    let lat = parseFloat(this.facInfo.Lat) || 25.0116;
                    let lng = parseFloat(this.facInfo.Lng) || 121.4658;
                    const hasValidCoords = (this.facInfo.Lat > 0 && this.facInfo.Lng > 0);

                    // 依據鐵律：使用 markRaw 隔離 Leaflet 物件，避免 Vue 3 響應式包裝代理導致 crash
                    const mapInstance = L.map('map', {
                        center: [lat, lng],
                        zoom: hasValidCoords ? 16 : 12,
                        zoomControl: true,
                        attributionControl: false
                    });

                    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                        maxZoom: 19
                    }).addTo(mapInstance);

                    if (hasValidCoords) {
                        const customIcon = L.divIcon({
                            className: 'custom-map-marker',
                            html: '<div class="marker-pin"><i class="fas fa-truck-pickup"></i></div>',
                            iconSize: [32, 32],
                            iconAnchor: [16, 32]
                        });

                        const markerInstance = L.marker([lat, lng], { icon: customIcon }).addTo(mapInstance);
                        markerInstance.bindPopup('<strong>' + (this.facInfo.FAC_NAME || this.facInfo.FAC_ID) + '</strong><br/>施工機具編號 #' + this.macId);
                        this.marker = markRaw(markerInstance);
                    }

                    this.leafletMap = markRaw(mapInstance);
                },
                toggleMapCollapse() {
                    this.mapCollapsed = !this.mapCollapsed;
                    this.$nextTick(() => {
                        if (this.leafletMap) {
                            setTimeout(() => {
                                this.leafletMap.invalidateSize();
                            }, 320);
                        }
                    });
                },
                openGoogleMaps() {
                    const lat = this.facInfo.Lat;
                    const lng = this.facInfo.Lng;
                    if (lat && lng) {
                        window.open('https://www.google.com/maps/dir/?api=1&destination=' + lat + ',' + lng, '_blank');
                    }
                },
                printCase() {
                    window.print();
                },
                goBack() {
                    if (this.mode === 'READ') {
                        window.location.href = '../Machine/macList.aspx';
                    } else if (this.mode === 'READ1') {
                        window.location.href = '../Machine/macList.aspx?mode=reject';
                    } else if (this.mode === 'READ2') {
                        window.location.href = '../Machine/macList.aspx?mode=search';
                    } else if (this.mode === 'READMAC1') {
                        window.location.href = 'managerList.aspx?INV_State=MAC1';
                    } else if (this.mode === 'READMAC2') {
                        window.location.href = 'managerList.aspx?INV_State=MAC2';
                    } else {
                        window.location.href = 'managerList.aspx?INV_State=' + this.mode;
                    }
                },
                scrollToReview() {
                    const el = document.getElementById('reviewPanel');
                    if (el) {
                        el.scrollIntoView({ behavior: 'smooth' });
                    }
                },
                applyPhrase(text) {
                    this.reviewForm.chkMemo = text;
                },
                submitReview() {
                    if (!this.reviewForm.chkResult) {
                        alert('請先選取審核結果判定（通過或退回）');
                        return;
                    }

                    const resultText = (this.reviewForm.chkResult === 'PASS') ? '審查通過' : '退件重辦';
                    if (!confirm('確認要送出【' + resultText + '】的審核結果嗎？')) {
                        return;
                    }

                    this.submittingReview = true;
                    const params = new URLSearchParams();
                    params.append('action', 'submit_review');
                    params.append('fac', this.facId);
                    params.append('macid', this.macId.toString());
                    params.append('mode', this.mode);
                    params.append('chkResult', this.reviewForm.chkResult);
                    params.append('chkMemo', this.reviewForm.chkMemo || '');

                    axios.post('Check_Step1_Mac.aspx', params)
                    .then(res => {
                        this.submittingReview = false;
                        const data = res.data;
                        if (!data.Success) {
                            alert(data.Message || '審核作業送出失敗');
                            return;
                        }
                        alert(data.Message);
                        window.location.href = data.RedirectUrl || ('managerList.aspx?INV_State=' + this.mode);
                    })
                    .catch(err => {
                        this.submittingReview = false;
                        alert('送出失敗（網路連線異常）：' + err.message);
                    });
                },
                openLightbox(idx) {
                    const p = this.photoList[idx];
                    if (!p || !p.Exists) return;
                    this.lightbox.currentIndex = idx;
                    this.lightbox.currentUrl = p.Url;
                    this.lightbox.title = p.Title + ' (' + p.FileName + ')';
                    this.lightbox.rotate = 0;
                    this.lightbox.show = true;
                },
                closeLightbox() {
                    this.lightbox.show = false;
                },
                rotateLightbox() {
                    this.lightbox.rotate = (this.lightbox.rotate + 90) % 360;
                },
                prevLightbox() {
                    let nextIdx = this.lightbox.currentIndex - 1;
                    while (nextIdx >= 0 && !this.photoList[nextIdx].Exists) {
                        nextIdx--;
                    }
                    if (nextIdx >= 0) {
                        this.openLightbox(nextIdx);
                    }
                },
                nextLightbox() {
                    let nextIdx = this.lightbox.currentIndex + 1;
                    while (nextIdx < this.photoList.length && !this.photoList[nextIdx].Exists) {
                        nextIdx++;
                    }
                    if (nextIdx < this.photoList.length) {
                        this.openLightbox(nextIdx);
                    }
                },
                openOriginalImage() {
                    if (this.lightbox.currentUrl) {
                        window.open(this.lightbox.currentUrl, '_blank');
                    }
                },
                handleKeyDown(e) {
                    if (e.key === 'Escape') {
                        if (this.lightbox.show) this.closeLightbox();
                    } else if (e.key === 'ArrowLeft') {
                        if (this.lightbox.show) this.prevLightbox();
                    } else if (e.key === 'ArrowRight') {
                        if (this.lightbox.show) this.nextLightbox();
                    }
                },
                getStepClass(step) {
                    if (this.numericStepCode > step) return 'completed';
                    if (this.numericStepCode === step) return 'active';
                    return '';
                },
                getStep2Title() {
                    if (this.macData.Mac_State === 'A01') return '複審作業中';
                    if (this.macData.Mac_State === 'A02') return '三審作業中';
                    if (this.macData.Mac_State === 'A00') return '初審作業中';
                    return '審查作業評定';
                },
                getLatestReviewTime() {
                    if (this.historyList.length > 0) {
                        return this.historyList[0].Chk_Date;
                    }
                    return '審查進行中';
                },
                getSmokeStatusBadge(status) {
                    if (!status) return 'badge-secondary';
                    if (status.indexOf('無') >= 0 || status.indexOf('正常') >= 0 || status.indexOf('合格') >= 0) return 'badge-success';
                    if (status.indexOf('微') >= 0) return 'badge-warning';
                    return 'badge-danger';
                },
                getItemPassBadge(val) {
                    if (!val) return 'badge-secondary';
                    if (val === '是' || val.indexOf('無') >= 0 || val.indexOf('正常') >= 0 || val.indexOf('足夠') >= 0) return 'badge-success';
                    return 'badge-danger';
                },
                formatCurrency(val) {
                    if (!val || val === '0' || val === '0.00' || val === '-') return '-';
                    const num = parseFloat(val);
                    if (isNaN(num)) return val;
                    return num.toLocaleString() + ' 元';
                }
            }
        }).mount('#app');
    </script>
</body>
</html>
