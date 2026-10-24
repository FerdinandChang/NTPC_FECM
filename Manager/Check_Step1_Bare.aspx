<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Check_Step1_Bare.aspx.cs" Inherits="NTPC_FEC.Manager.Check_Step1_Bare" %>

<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定溢散源管理審查平台 - 裸露地案件審查作業</title>

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

        /* 主作業容器 */
        .container-fluid-custom {
            max-width: 1560px;
            margin: 0 auto;
            padding: 16px;
        }

        /* 階段時間軸 (Status Stepper) */
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

        /* 退回醒目警示卡片 */
        .alert-gback {
            background-color: #fef2f2;
            border: 1px solid #f87171;
            border-left: 6px solid #dc2626;
            border-radius: 8px;
            padding: 12px 16px;
            margin-bottom: 16px;
            color: #991b1b;
            font-size: 14px;
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
            margin-top: 12px;
            margin-bottom: 12px;
        }

        .stat-chip {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 10px 12px;
            text-align: center;
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
            padding: 9px 12px;
            border: 1px solid #e2e8f0;
            vertical-align: middle;
            white-space: nowrap;
        }

        .info-table td {
            color: #0f172a;
            font-size: 13.5px;
            padding: 9px 12px;
            border: 1px solid #e2e8f0;
            vertical-align: middle;
            word-break: break-all;
        }

        /* 智慧現場地圖 */
        #map {
            width: 100%;
            height: 330px;
            border-radius: 8px;
            z-index: 10;
        }

        /* 標記 Marker Pin */
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

        .marker-icon {
            transform: rotate(45deg);
            color: #ffffff;
            font-size: 13px;
        }

        /* 巡查簽名卡片 */
        .signature-box {
            background: #ffffff;
            border: 1px dashed #cbd5e1;
            border-radius: 8px;
            padding: 12px;
            text-align: center;
            min-height: 140px;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
        }

        .signature-box img {
            max-width: 100%;
            max-height: 120px;
            object-fit: contain;
            cursor: pointer;
            transition: transform 0.2s;
        }

        .signature-box img:hover {
            transform: scale(1.05);
        }

        /* 4格現場相片相簿 */
        .photo-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 14px;
        }

        @media (max-width: 576px) {
            .photo-grid {
                grid-template-columns: 1fr;
            }
        }

        .photo-card {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 10px;
            overflow: hidden;
            display: flex;
            flex-direction: column;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
            transition: transform 0.15s, box-shadow 0.15s;
        }

        .photo-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 10px rgba(0, 0, 0, 0.1);
        }

        .photo-card-header {
            padding: 8px 12px;
            background: #f1f5f9;
            font-size: 13px;
            font-weight: 700;
            color: #334155;
            border-bottom: 1px solid #e2e8f0;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .photo-card-body {
            height: 220px;
            position: relative;
            background: #0f172a;
            display: flex;
            align-items: center;
            justify-content: center;
            overflow: hidden;
            cursor: pointer;
        }

        .photo-card-body img {
            max-width: 100%;
            max-height: 100%;
            object-fit: contain;
            transition: transform 0.25s;
        }

        .photo-card-body:hover img {
            transform: scale(1.04);
        }

        .photo-empty {
            height: 220px;
            background: #f8fafc;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            color: #94a3b8;
            font-size: 13px;
            gap: 8px;
        }

        /* 審核操作面板 (Review Box) */
        .review-panel {
            background: #ffffff;
            border: 2px solid #0284c7;
            border-radius: 12px;
            padding: 20px;
            box-shadow: 0 4px 16px rgba(2, 132, 199, 0.12);
        }

        .review-segmented-group {
            display: flex;
            gap: 12px;
            margin-bottom: 16px;
        }

        .review-segment-btn {
            flex: 1;
            padding: 12px 16px;
            border-radius: 8px;
            border: 2px solid #cbd5e1;
            background: #f8fafc;
            color: #475569;
            font-size: 15px;
            font-weight: 700;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            transition: all 0.2s;
        }

        .review-segment-btn.active-pass {
            background: #ecfdf5;
            border-color: #10b981;
            color: #047857;
            box-shadow: 0 0 0 3px rgba(16, 185, 129, 0.2);
        }

        .review-segment-btn.active-fail {
            background: #fef2f2;
            border-color: #ef4444;
            color: #b91c1c;
            box-shadow: 0 0 0 3px rgba(239, 68, 68, 0.2);
        }

        /* 常用審核意見標籤 */
        .quick-pills-wrap {
            display: flex;
            flex-wrap: wrap;
            gap: 6px;
            margin-bottom: 10px;
        }

        .quick-pill {
            background: #f1f5f9;
            border: 1px solid #cbd5e1;
            color: #334155;
            padding: 4px 10px;
            border-radius: 16px;
            font-size: 12px;
            cursor: pointer;
            transition: all 0.15s;
        }

        .quick-pill:hover {
            background: #e2e8f0;
            border-color: #94a3b8;
            color: #0f172a;
        }

        /* 歷史審查記錄時間軸表格 */
        .history-table {
            width: 100%;
            border-collapse: collapse;
        }

        .history-table th {
            background-color: #f8fafc;
            color: #475569;
            font-weight: 600;
            font-size: 13px;
            padding: 10px 12px;
            border-bottom: 2px solid #cbd5e1;
        }

        .history-table td {
            font-size: 13.5px;
            padding: 10px 12px;
            border-bottom: 1px solid #e2e8f0;
            vertical-align: middle;
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

        @media screen and (min-width: 992px) {
            .mobile-bottom-bar {
                display: none;
            }
        }

        /* 燈箱視窗 (Lightbox) */
        .lightbox-modal {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(15, 23, 42, 0.9);
            z-index: 2000;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }

        .lightbox-content {
            position: relative;
            max-width: 92vw;
            max-height: 90vh;
            display: flex;
            flex-direction: column;
            align-items: center;
        }

        .lightbox-content img {
            max-width: 100%;
            max-height: 80vh;
            object-fit: contain;
            border-radius: 8px;
            box-shadow: 0 10px 25px rgba(0, 0, 0, 0.5);
            transition: transform 0.2s ease-out;
        }

        .lightbox-toolbar {
            margin-top: 12px;
            display: flex;
            gap: 12px;
            background: rgba(0, 0, 0, 0.6);
            padding: 8px 16px;
            border-radius: 20px;
        }

        .lightbox-btn {
            background: transparent;
            border: none;
            color: #ffffff;
            font-size: 16px;
            cursor: pointer;
            padding: 4px 8px;
            border-radius: 4px;
        }

        .lightbox-btn:hover {
            background: rgba(255, 255, 255, 0.2);
        }

        /* 列印樣式 */
        @media print {
            .no-print, .top-navbar, .mobile-bottom-bar, .lightbox-modal {
                display: none !important;
            }

            body {
                background: #ffffff;
                color: #000000;
            }

            .card-modern {
                box-shadow: none !important;
                border: 1px solid #94a3b8 !important;
                page-break-inside: avoid;
            }

            .print-only-header {
                display: block !important;
                text-align: center;
                margin-bottom: 20px;
            }
        }

        .print-only-header {
            display: none;
        }
    </style>
</head>
<body>
    <div id="app" v-cloak>
        <!-- 1. 置頂深青藍漸層導覽列 (Sticky Top Navbar) -->
        <header class="top-navbar no-print">
            <div class="d-flex align-items-center">
                <a :href="backUrl" class="nav-btn mr-2" title="返回審查清單">
                    <i class="fas fa-arrow-left"></i>
                    <span class="d-none d-sm-inline">返回清單</span>
                </a>
                <span class="brand-title">
                    <i class="fas fa-mountain text-white"></i>
                    <span>裸露地案件審查作業</span>
                </span>
                <span v-if="main.BareGroundNo" class="badge badge-light text-dark font-weight-bold ml-2" style="font-size: 0.85rem;">
                    {{ main.BareGroundNo }}
                </span>
                <span v-if="inv.INV_NO" class="badge badge-info ml-1 font-weight-bold d-none d-md-inline" style="font-size: 0.82rem;">
                    第 {{ inv.INV_NO }} 次巡查
                </span>
                <span class="badge ml-2 font-weight-bold" :class="getModeBadgeClass(mode)">
                    {{ reviewStateTitle }}
                </span>
            </div>

            <div class="d-flex align-items-center gap-2">
                <button type="button" class="nav-btn bg-white text-dark shadow-sm" v-on:click="printCase">
                    <i class="fas fa-print"></i>
                    <span class="d-none d-md-inline">列印案件</span>
                </button>
                <button v-if="hasCoordinates" type="button" class="nav-btn bg-white text-dark shadow-sm ml-2" v-on:click="openGoogleMaps">
                    <i class="fas fa-location-arrow text-success"></i>
                    <span class="d-none d-md-inline">場址導航</span>
                </button>
                <button v-if="canReview" type="button" class="btn btn-warning btn-sm font-weight-bold ml-2 shadow-sm" v-on:click="scrollToReview">
                    <i class="fas fa-clipboard-check mr-1"></i>
                    <span class="d-none d-sm-inline">審核作業</span>
                </button>
            </div>
        </header>

        <!-- 2. 列印專用報表頁首 (螢幕隱藏，列印時顯現) -->
        <div class="print-only-header">
            <h2 style="font-size: 20px; font-weight: bold; margin-bottom: 4px;">新北市固定溢散源管理審查平台</h2>
            <h3 style="font-size: 16px; margin-bottom: 8px;">裸露地案件現場巡查與審核紀錄表</h3>
            <div style="font-size: 12px; color: #555;">
                場址編號：{{ main.BareGroundNo || '--' }} ｜ 巡查次數：第 {{ inv.INV_NO || 1 }} 次 ｜ 列印時間：{{ printTime }}
            </div>
            <hr style="margin: 10px 0;" />
        </div>

        <!-- 3. 主作業容器 (固定最大寬度 1560px 居中) -->
        <main class="container-fluid-custom">
            <!-- 載入中骨架狀態 -->
            <div v-if="loading" class="text-center py-5">
                <div class="spinner-border text-primary" role="status" style="width: 3rem; height: 3rem;"></div>
                <div class="mt-3 font-weight-bold text-muted">正在載入裸露地案件資料...</div>
            </div>

            <!-- 錯誤訊息提示 -->
            <div v-if="errorMessage" class="alert alert-danger shadow-sm">
                <i class="fas fa-exclamation-triangle mr-2"></i>{{ errorMessage }}
                <div class="mt-2">
                    <a :href="backUrl" class="btn btn-sm btn-outline-danger">返回審查清單</a>
                </div>
            </div>

            <div v-if="!loading && !errorMessage">
                <!-- A. 案件退回重辦警告卡片 (若當前處於退回狀態觸發) -->
                <div v-if="isRejectedCase" class="alert-gback shadow-sm">
                    <div class="font-weight-bold d-flex align-items-center">
                        <i class="fas fa-exclamation-circle mr-2 fa-lg"></i>
                        <span>此案件先前審查已退件，目前狀態為待修正或補正巡查</span>
                    </div>
                    <div class="mt-1" style="font-size: 13px;" v-if="lastRejectMemo">
                        <strong>退件原因：</strong>{{ lastRejectMemo }}
                    </div>
                </div>

                <!-- B. 通報階段進度時間軸 (Status Stepper) -->
                <div class="stepper-container shadow-sm no-print">
                    <div class="stepper-line">
                        <div class="stepper-line-fill" :style="{ width: stepperProgress + '%' }"></div>
                    </div>

                    <!-- 步驟 1: 現場巡查立案 -->
                    <div class="step-item" :class="getStepClass(1)">
                        <div class="step-circle">
                            <i v-if="stepperStage > 1" class="fas fa-check"></i>
                            <span v-else>1</span>
                        </div>
                        <div class="step-title">現場巡查立案</div>
                        <div class="step-time">{{ inv.Check_Date || '未填寫' }}</div>
                    </div>

                    <!-- 步驟 2: 課長初審審核 -->
                    <div class="step-item" :class="getStepClass(2)">
                        <div class="step-circle">
                            <i v-if="stepperStage > 2" class="fas fa-check"></i>
                            <span v-else>2</span>
                        </div>
                        <div class="step-title">課長初審審核</div>
                        <div class="step-time">{{ getStepTime('A00') }}</div>
                    </div>

                    <!-- 步驟 3: 承辦複審審查 -->
                    <div class="step-item" :class="getStepClass(3)">
                        <div class="step-circle">
                            <i v-if="stepperStage > 3" class="fas fa-check"></i>
                            <span v-else>3</span>
                        </div>
                        <div class="step-title">承辦複審審查</div>
                        <div class="step-time">{{ getStepTime('A01') }}</div>
                    </div>

                    <!-- 步驟 4: 審定結案 -->
                    <div class="step-item" :class="getStepClass(4)">
                        <div class="step-circle">
                            <i v-if="stepperStage === 4" class="fas fa-check"></i>
                            <span v-else>4</span>
                        </div>
                        <div class="step-title">審定備查結案</div>
                        <div class="step-time">{{ getStepTime('A02') }}</div>
                    </div>
                </div>

                <!-- C. 雙欄卡片佈局 (Desktop 40% / 60%) -->
                <div class="row">
                    <!-- ================= 左欄 (40% 寬度，Sticky 浮動固頂) ================= -->
                    <div class="col-12 col-xl-5">
                        <div class="sticky-sidebar">
                            <!-- 卡片 1: 裸露地基本資料 -->
                            <div class="card-modern">
                                <div class="card-modern-header">
                                    <h4 class="card-modern-title">
                                        <i class="fas fa-info-circle text-primary"></i>
                                        <span>裸露地基本資料</span>
                                    </h4>
                                    <span class="badge badge-primary px-2 py-1 font-weight-bold">
                                        {{ main.TownName || '新北市' }}
                                    </span>
                                </div>
                                <div class="card-modern-body p-0">
                                    <table class="info-table">
                                        <tbody>
                                            <tr>
                                                <th>場址編號</th>
                                                <td><strong>{{ main.BareGroundNo || '--' }}</strong></td>
                                            </tr>
                                            <tr>
                                                <th>行政區</th>
                                                <td>{{ main.TownName || '--' }}</td>
                                            </tr>
                                            <tr>
                                                <th>場址地址</th>
                                                <td>{{ main.ADDR || '未填寫地址' }}</td>
                                            </tr>
                                            <tr>
                                                <th>使用地類別 (地目)</th>
                                                <td>{{ main.Land_USE || '--' }}</td>
                                            </tr>
                                            <tr>
                                                <th>GPS 坐標 (WGS84)</th>
                                                <td>
                                                    <span v-if="hasCoordinates">
                                                        緯度: {{ main.Latitude }}<br />
                                                        經度: {{ main.Longtitude }}
                                                    </span>
                                                    <span v-else class="text-muted">暫無坐標</span>
                                                </td>
                                            </tr>
                                        </tbody>
                                    </table>
                                </div>
                            </div>

                            <!-- 卡片 2: 現場智慧地圖 (Leaflet.js) -->
                            <div class="card-modern">
                                <div class="card-modern-header">
                                    <h4 class="card-modern-title">
                                        <i class="fas fa-map-marked-alt text-primary"></i>
                                        <span>現場地理位置</span>
                                    </h4>
                                    <div class="d-flex align-items-center gap-1">
                                        <button type="button" class="btn btn-xs btn-outline-secondary py-1 px-2" v-on:click="resetMapView" title="重設視角">
                                            <i class="fas fa-compress-arrows-alt"></i> 重設
                                        </button>
                                        <button v-if="hasCoordinates" type="button" class="btn btn-xs btn-outline-primary py-1 px-2 ml-1" v-on:click="openGoogleMaps" title="Google 導航">
                                            <i class="fas fa-external-link-alt"></i> 導航
                                        </button>
                                    </div>
                                </div>
                                <div class="card-modern-body p-2">
                                    <div id="map"></div>
                                    <div v-if="!hasCoordinates" class="text-center text-muted py-2 font-weight-bold" style="font-size: 13px;">
                                        <i class="fas fa-info-circle mr-1"></i>此場址無有效座標，顯示新北市預設中心點
                                    </div>
                                </div>
                            </div>

                            <!-- 卡片 3: 巡查人員手寫簽章 -->
                            <div class="card-modern">
                                <div class="card-modern-header">
                                    <h4 class="card-modern-title">
                                        <i class="fas fa-signature text-primary"></i>
                                        <span>現場巡查員簽章</span>
                                    </h4>
                                    <span class="badge badge-light text-muted font-weight-bold">
                                        {{ inv.ChkUserName || inv.Chk_User || '巡查人員' }}
                                    </span>
                                </div>
                                <div class="card-modern-body">
                                    <div v-if="signatures.Sig1Base64 || signatures.Sig1Url" class="signature-box" v-on:click="openLightbox(signatures.Sig1Base64 || signatures.Sig1Url, '巡查人員手寫簽名')">
                                        <img :src="signatures.Sig1Base64 || signatures.Sig1Url" alt="巡查人員簽名" title="點擊放大簽名" />
                                        <small class="text-muted mt-2 d-block">
                                            <i class="fas fa-search-plus mr-1"></i>點擊放大預覽手寫簽名
                                        </small>
                                    </div>
                                    <div v-else class="signature-box">
                                        <i class="fas fa-file-signature text-muted fa-2x mb-2"></i>
                                        <span class="text-muted font-weight-bold" style="font-size: 13px;">本案件尚未上傳手寫簽名</span>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- ================= 右欄 (60% 寬度，主查核與審核作業區) ================= -->
                    <div class="col-12 col-xl-7">
                        <!-- 卡片 4: 現場查核概況與規格量測 -->
                        <div class="card-modern">
                            <div class="card-modern-header">
                                <h4 class="card-modern-title">
                                    <i class="fas fa-clipboard-list text-primary"></i>
                                    <span>現場查核概況與規格量測</span>
                                </h4>
                                <span class="badge badge-info px-2 py-1 font-weight-bold">
                                    查核時間：{{ inv.Check_Date || '--' }}
                                </span>
                            </div>
                            <div class="card-modern-body">
                                <!-- 規格晶片組 (長、寬、高、體積、面積) -->
                                <div class="stat-chip-grid">
                                    <div class="stat-chip">
                                        <div class="stat-chip-label">堆置長度</div>
                                        <div class="stat-chip-value">
                                            {{ inv.pLength != null ? inv.pLength.toFixed(1) : '0.0' }}
                                            <span class="stat-chip-unit">m</span>
                                        </div>
                                    </div>
                                    <div class="stat-chip">
                                        <div class="stat-chip-label">堆置寬度</div>
                                        <div class="stat-chip-value">
                                            {{ inv.pWidth != null ? inv.pWidth.toFixed(1) : '0.0' }}
                                            <span class="stat-chip-unit">m</span>
                                        </div>
                                    </div>
                                    <div class="stat-chip">
                                        <div class="stat-chip-label">堆置高度</div>
                                        <div class="stat-chip-value">
                                            {{ inv.pHeight != null ? inv.pHeight.toFixed(1) : '0.0' }}
                                            <span class="stat-chip-unit">m</span>
                                        </div>
                                    </div>
                                    <div class="stat-chip">
                                        <div class="stat-chip-label">堆置概估體積</div>
                                        <div class="stat-chip-value text-danger">
                                            {{ inv.pVolume != null ? inv.pVolume.toFixed(1) : '0.0' }}
                                            <span class="stat-chip-unit">m³</span>
                                        </div>
                                    </div>
                                    <div class="stat-chip">
                                        <div class="stat-chip-label">場址面積</div>
                                        <div class="stat-chip-value text-success">
                                            {{ inv.pArea != null ? inv.pArea.toFixed(1) : '0.0' }}
                                            <span class="stat-chip-unit">m²</span>
                                        </div>
                                    </div>
                                </div>

                                <table class="info-table mt-3">
                                    <tbody>
                                        <tr>
                                            <th style="width: 25%;">場址周界概況</th>
                                            <td>
                                                <div style="white-space: pre-wrap;">{{ inv.Around_Memo || '無特殊周界說明' }}</div>
                                            </td>
                                        </tr>
                                        <tr>
                                            <th>廢棄物種類、外觀</th>
                                            <td>
                                                <div style="white-space: pre-wrap;">{{ inv.Waste_Type || '無填報廢棄物' }}</div>
                                            </td>
                                        </tr>
                                        <tr>
                                            <th>現場環境概況說明</th>
                                            <td>
                                                <div style="white-space: pre-wrap;">{{ inv.Surroundings || '無補充說明' }}</div>
                                            </td>
                                        </tr>
                                    </tbody>
                                </table>
                            </div>
                        </div>

                        <!-- 卡片 5: 現場巡查照片展示 (4 格現代相簿) -->
                        <div class="card-modern">
                            <div class="card-modern-header">
                                <h4 class="card-modern-title">
                                    <i class="fas fa-camera-retro text-primary"></i>
                                    <span>裸露地現場巡查照片 (共 4 張)</span>
                                </h4>
                                <small class="text-muted">點選照片可開啟全螢幕檢視與旋轉</small>
                            </div>
                            <div class="card-modern-body">
                                <div class="photo-grid">
                                    <div v-for="p in photos" :key="p.Index" class="photo-card">
                                        <div class="photo-card-header">
                                            <span>
                                                <i class="fas fa-image text-primary mr-1"></i>
                                                {{ p.Title }}
                                            </span>
                                            <span v-if="p.HasFile" class="badge badge-success">已上傳</span>
                                            <span v-else class="badge badge-light text-muted">未拍攝</span>
                                        </div>
                                        <div v-if="p.HasFile" class="photo-card-body" v-on:click="openLightbox(p.Url, p.Title)">
                                            <img :src="p.Url" :alt="p.Title" />
                                        </div>
                                        <div v-else class="photo-empty">
                                            <i class="fas fa-file-image fa-2x"></i>
                                            <span>查無此張照片檔案</span>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- 卡片 6: 案件審核作業面板 (核心功能) -->
                        <div id="reviewCard" class="card-modern">
                            <div class="card-modern-header bg-light">
                                <h4 class="card-modern-title">
                                    <i class="fas fa-user-check text-primary"></i>
                                    <span>{{ reviewStateTitle }}作業面板</span>
                                </h4>
                                <span class="badge" :class="canReview ? 'badge-primary' : 'badge-secondary'">
                                    {{ canReview ? '待審核中' : '唯讀檢視' }}
                                </span>
                            </div>
                            <div class="card-modern-body">
                                <!-- 可審查模式 -->
                                <div v-if="canReview" class="review-panel">
                                    <div class="d-flex justify-content-between align-items-center mb-3">
                                        <span class="font-weight-bold" style="font-size: 15px;">
                                            <i class="fas fa-tasks text-primary mr-1"></i>請選擇審查判定結果：
                                        </span>
                                        <small class="text-muted">審核人：<strong>{{ currentUser }}</strong></small>
                                    </div>

                                    <!-- 審查結果切換按鈕 (PASS / FAIL) -->
                                    <div class="review-segmented-group">
                                        <button type="button" class="review-segment-btn" :class="{ 'active-pass': reviewForm.result === 'PASS' }" v-on:click="setReviewResult('PASS')">
                                            <i class="fas fa-check-circle fa-lg text-success"></i>
                                            <span>審核通過 (合格)</span>
                                        </button>
                                        <button type="button" class="review-segment-btn" :class="{ 'active-fail': reviewForm.result === 'FAIL' }" v-on:click="setReviewResult('FAIL')">
                                            <i class="fas fa-times-circle fa-lg text-danger"></i>
                                            <span>審核退件 (退回補正)</span>
                                        </button>
                                    </div>

                                    <!-- 常用快速評語標籤 -->
                                    <div class="mb-2">
                                        <small class="font-weight-bold text-muted d-block mb-1">
                                            <i class="fas fa-magic mr-1"></i>常用審核意見快捷填入：
                                        </small>
                                        <div class="quick-pills-wrap">
                                            <button v-for="pill in currentQuickPills" :key="pill" type="button" class="quick-pill" v-on:click="applyQuickPill(pill)">
                                                + {{ pill }}
                                            </button>
                                        </div>
                                    </div>

                                    <!-- 審核意見輸入框 -->
                                    <div class="form-group mb-3">
                                        <label for="reviewMemo" class="font-weight-bold" style="font-size: 13.5px;">
                                            審核意見說明：<span class="text-danger">*</span>
                                        </label>
                                        <textarea id="reviewMemo" v-model="reviewForm.memo" class="form-control" rows="4" placeholder="請填寫審核意見或退件理由（例如：審核合格，符合規定 / 照片拍攝角度不佳請重測...）"></textarea>
                                    </div>

                                    <!-- 動作按鈕群 -->
                                    <div class="d-flex align-items-center justify-content-end gap-2 pt-2">
                                        <a :href="backUrl" class="btn btn-outline-secondary px-4 py-2 mr-2 font-weight-bold">
                                            取消返回
                                        </a>
                                        <button type="button" class="btn btn-success px-4 py-2 font-weight-bold shadow-sm" :disabled="submitting" v-on:click="submitReview">
                                            <span v-if="submitting" class="spinner-border spinner-border-sm mr-1"></span>
                                            <i v-else class="fas fa-paper-plane mr-1"></i>
                                            確認儲存審查結果
                                        </button>
                                    </div>
                                </div>

                                <!-- 唯讀檢視模式 -->
                                <div v-else class="text-center py-4 bg-light rounded">
                                    <i class="fas fa-lock text-muted fa-2x mb-2"></i>
                                    <h5 class="font-weight-bold text-secondary mb-1">本案件目前為唯讀檢視狀態</h5>
                                    <p class="text-muted mb-0" style="font-size: 13px;">
                                        案件目前狀態為「<strong>{{ inv.State_Name || '已完成' }}</strong>」，若需審查請先確認是否具備審核權限或從待審清單開啟。
                                    </p>
                                    <div class="mt-3">
                                        <a :href="backUrl" class="btn btn-sm btn-outline-primary">返回裸露地審查清單</a>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- 卡片 7: 歷次審查歷程記錄 (Review History Timeline) -->
                        <div class="card-modern">
                            <div class="card-modern-header">
                                <h4 class="card-modern-title">
                                    <i class="fas fa-history text-primary"></i>
                                    <span>案件審查歷程記錄</span>
                                </h4>
                                <span class="badge badge-light font-weight-bold">共 {{ histories.length }} 筆審核歷程</span>
                            </div>
                            <div class="card-modern-body p-0">
                                <div v-if="histories.length > 0" class="table-responsive">
                                    <table class="history-table">
                                        <thead>
                                            <tr>
                                                <th style="width: 140px;">審核時間</th>
                                                <th style="width: 100px;">審核人員</th>
                                                <th style="width: 110px;">審核階段</th>
                                                <th style="width: 100px;">判定結果</th>
                                                <th>審核意見說明</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <tr v-for="(h, idx) in histories" :key="idx">
                                                <td class="text-muted font-weight-bold">{{ h.Chk_Date }}</td>
                                                <td><strong>{{ h.Chk_User }}</strong></td>
                                                <td><span class="badge badge-info">{{ h.State_Name || '審核' }}</span></td>
                                                <td>
                                                    <span class="badge" :class="h.Chk_Result === '通過' ? 'badge-success' : 'badge-danger'" style="font-size: 12px; padding: 5px 9px;">
                                                        {{ h.Chk_Result }}
                                                    </span>
                                                </td>
                                                <td style="white-space: pre-wrap;">{{ h.Chk_Memo || '--' }}</td>
                                            </tr>
                                        </tbody>
                                    </table>
                                </div>
                                <div v-else class="text-center py-4 text-muted font-weight-bold">
                                    <i class="fas fa-inbox fa-2x mb-2 d-block text-black-50"></i>
                                    目前尚無審查歷程紀錄
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </main>

        <!-- 4. 手機端浮動動作列 (Sticky Bottom Bar) -->
        <div v-if="canReview" class="mobile-bottom-bar shadow-lg">
            <button type="button" class="btn btn-outline-danger" v-on:click="setReviewResult('FAIL'); scrollToReview();">
                <i class="fas fa-times mr-1"></i>退件
            </button>
            <button type="button" class="btn btn-success" v-on:click="setReviewResult('PASS'); scrollToReview();">
                <i class="fas fa-check mr-1"></i>通過
            </button>
            <button type="button" class="btn btn-primary" v-on:click="scrollToReview">
                <i class="fas fa-edit mr-1"></i>填寫意見
            </button>
        </div>

        <!-- 5. 全螢幕照片檢視燈箱 (Lightbox Modal) -->
        <div v-if="lightbox.show" class="lightbox-modal no-print" v-on:click.self="closeLightbox">
            <div class="lightbox-content">
                <img :src="lightbox.url" :alt="lightbox.title" :style="{ transform: 'rotate(' + lightbox.rotation + 'deg)' }" />
                <div class="lightbox-toolbar">
                    <button type="button" class="lightbox-btn" v-on:click="rotateLightbox(-90)" title="逆時針旋轉">
                        <i class="fas fa-undo"></i>
                    </button>
                    <button type="button" class="lightbox-btn" v-on:click="rotateLightbox(90)" title="順時針旋轉">
                        <i class="fas fa-redo"></i>
                    </button>
                    <a :href="lightbox.url" target="_blank" class="lightbox-btn text-white text-decoration-none" title="新分頁檢視原圖">
                        <i class="fas fa-external-link-alt"></i>
                    </a>
                    <button type="button" class="lightbox-btn text-danger font-weight-bold" v-on:click="closeLightbox" title="關閉檢視">
                        <i class="fas fa-times"></i>
                    </button>
                </div>
                <div class="text-white text-center mt-2 font-weight-bold" style="font-size: 14px;">
                    {{ lightbox.title }}
                </div>
            </div>
        </div>
    </div>

    <!-- 本地端核心前端腳本 (避開 CDN) -->
    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>
    <script src="../Scripts/leaflet/leaflet.js"></script>

    <script>
        const { createApp, ref, reactive, computed, onMounted, nextTick } = Vue;

        createApp({
            data() {
                return {
                    loading: true,
                    submitting: false,
                    errorMessage: '',
                    mode: 'INV1',
                    currentUser: '',
                    reviewStateTitle: '案件審查',
                    canReview: false,
                    main: {},
                    inv: {},
                    photos: [],
                    signatures: { Sig1Url: '', Sig1Base64: '', Sig2Url: '', Sig2Base64: '' },
                    histories: [],
                    reviewForm: {
                        result: 'PASS',
                        memo: '審核合格，符合規定'
                    },
                    lightbox: {
                        show: false,
                        url: '',
                        title: '',
                        rotation: 0
                    },
                    printTime: new Date().toLocaleString('zh-TW', { hour12: false })
                };
            },
            computed: {
                backUrl() {
                    return 'managerList_Bare.aspx?mode=' + encodeURIComponent(this.mode || 'INV1');
                },
                hasCoordinates() {
                    if (!this.main.Latitude || !this.main.Longtitude) return false;
                    const lat = parseFloat(this.main.Latitude);
                    const lng = parseFloat(this.main.Longtitude);
                    return !isNaN(lat) && !isNaN(lng) && lat > 0 && lng > 0;
                },
                stepperStage() {
                    // 1: 現場立案, 2: 初審, 3: 複審, 4: 結案
                    const state = this.inv.INV_State || '';
                    if (state === 'A02' || state === 'A03' || state === '99') return 4;
                    if (state === 'A01') return 3;
                    if (state === 'A00') return 2;
                    return 1;
                },
                stepperProgress() {
                    if (this.stepperStage === 4) return 100;
                    if (this.stepperStage === 3) return 66;
                    if (this.stepperStage === 2) return 33;
                    return 0;
                },
                isRejectedCase() {
                    const state = this.inv.INV_State || '';
                    return state === '00' || (this.histories.length > 0 && this.histories[0].Chk_Result === '退件');
                },
                lastRejectMemo() {
                    for (let i = 0; i < this.histories.length; i++) {
                        if (this.histories[i].Chk_Result === '退件') {
                            return this.histories[i].Chk_Memo;
                        }
                    }
                    return '';
                },
                currentQuickPills() {
                    if (this.reviewForm.result === 'PASS') {
                        return [
                            '審核合格，符合規定',
                            '照片完整清晰，同意備查',
                            '量測數據無誤，予以通過',
                            '現場環境維護良好，通過審查'
                        ];
                    } else {
                        return [
                            '現場無適當覆蓋或防塵措施，請補正改善',
                            '現場照片拍攝模糊不全，請重新巡查補拍',
                            '堆置規格與體積數據有疑義，退回現場重測',
                            '未附巡查人員簽名，請補簽後再送審'
                        ];
                    }
                }
            },
            mounted() {
                this.loadCaseData();
            },
            methods: {
                getUrlParam(param) {
                    const urlParams = new URLSearchParams(window.location.search);
                    return urlParams.get(param) || '';
                },
                getModeBadgeClass(m) {
                    const mode = (m || '').toUpperCase();
                    if (mode === 'INV1') return 'badge-success';
                    if (mode === 'INV2') return 'badge-primary';
                    if (mode === 'INV3') return 'badge-warning';
                    return 'badge-secondary';
                },
                getStepClass(step) {
                    if (this.stepperStage > step) return 'completed';
                    if (this.stepperStage === step) return 'active';
                    return '';
                },
                getStepTime(stateId) {
                    if (!this.histories || this.histories.length === 0) return '待審核';
                    for (let i = 0; i < this.histories.length; i++) {
                        if (this.histories[i].State_Name && this.histories[i].State_Name.indexOf(stateId) !== -1) {
                            return this.histories[i].Chk_Date;
                        }
                    }
                    return '待審核';
                },
                async loadCaseData() {
                    this.loading = true;
                    this.errorMessage = '';
                    try {
                        const params = {
                            action: 'get_data',
                            mode: this.getUrlParam('mode') || 'INV1',
                            id: this.getUrlParam('id'),
                            id1: this.getUrlParam('id1'),
                            id2: this.getUrlParam('id2')
                        };

                        const res = await axios.get('Check_Step1_Bare.aspx', { params: params });
                        if (res.data && res.data.Success) {
                            this.mode = res.data.Mode || 'INV1';
                            this.currentUser = res.data.CurrentUser || '';
                            this.reviewStateTitle = res.data.ReviewStateTitle || '案件審查';
                            this.canReview = !!res.data.CanReview;
                            this.main = res.data.Main || {};
                            this.inv = res.data.Inv || {};
                            this.photos = res.data.Photos || [];
                            this.signatures = res.data.Signatures || { Sig1Url: '', Sig1Base64: '', Sig2Url: '', Sig2Base64: '' };
                            this.histories = res.data.Histories || [];

                            // 預設審核意見
                            if (this.canReview) {
                                this.reviewForm.result = 'PASS';
                                this.reviewForm.memo = '審核合格，符合規定';
                            }

                            this.loading = false;
                            this.$nextTick(() => {
                                this.initMap();
                            });
                        } else {
                            this.errorMessage = (res.data && res.data.Message) ? res.data.Message : '載入案件失敗';
                            this.loading = false;
                        }
                    } catch (err) {
                        this.errorMessage = '伺服器通訊失敗：' + (err.message || err);
                        this.loading = false;
                    }
                },
                initMap() {
                    const mapEl = document.getElementById('map');
                    if (!mapEl) return;

                    let lat = parseFloat(this.main.Latitude);
                    let lng = parseFloat(this.main.Longtitude);
                    const isValid = !isNaN(lat) && !isNaN(lng) && lat > 0 && lng > 0;

                    if (!isValid) {
                        lat = 25.0123;
                        lng = 121.4657; // 新北市政府中心座標
                    }

                    // 避免 Vue 響應式封裝 Leaflet 實例 (使用原生屬性 this.leafletMap)
                    if (this.leafletMap) {
                        this.leafletMap.remove();
                        this.leafletMap = null;
                    }

                    const map = L.map('map', {
                        center: [lat, lng],
                        zoom: isValid ? 16 : 12,
                        zoomControl: true
                    });

                    // 台灣通用電子地圖 (EMAP)
                    L.tileLayer('https://wmts.nlsc.gov.tw/wmts/EMAP/default/GoogleMapsCompatible/{z}/{y}/{x}', {
                        maxZoom: 19,
                        attribution: '&copy; 內政部國土測繪中心'
                    }).addTo(map);

                    if (isValid) {
                        const customIcon = L.divIcon({
                            className: 'custom-map-marker',
                            html: '<div class="marker-pin"><i class="fas fa-mountain marker-icon"></i></div>',
                            iconSize: [32, 32],
                            iconAnchor: [16, 32],
                            popupAnchor: [0, -32]
                        });

                        const marker = L.marker([lat, lng], { icon: customIcon }).addTo(map);
                        marker.bindPopup(`
                            <div style="font-size: 13px; line-height: 1.5;">
                                <strong style="color: #0284c7;">${this.main.BareGroundNo || '裸露地場址'}</strong><br />
                                地址：${this.main.ADDR || '--'}<br />
                                坐標：${lat.toFixed(5)}, ${lng.toFixed(5)}
                            </div>
                        `).openPopup();
                    }

                    this.leafletMap = map;
                    this.savedLat = lat;
                    this.savedLng = lng;
                    this.savedZoom = isValid ? 16 : 12;
                },
                resetMapView() {
                    if (this.leafletMap && this.savedLat && this.savedLng) {
                        this.leafletMap.setView([this.savedLat, this.savedLng], this.savedZoom);
                    }
                },
                setReviewResult(res) {
                    this.reviewForm.result = res;
                    if (res === 'PASS') {
                        if (!this.reviewForm.memo || this.reviewForm.memo.indexOf('退') !== -1) {
                            this.reviewForm.memo = '審核合格，符合規定';
                        }
                    } else {
                        if (!this.reviewForm.memo || this.reviewForm.memo.indexOf('合格') !== -1) {
                            this.reviewForm.memo = '現場無適當覆蓋防制措施，退回現場補正改善';
                        }
                    }
                },
                applyQuickPill(text) {
                    this.reviewForm.memo = text;
                },
                scrollToReview() {
                    const el = document.getElementById('reviewCard');
                    if (el) {
                        el.scrollIntoView({ behavior: 'smooth', block: 'center' });
                        const memoInput = document.getElementById('reviewMemo');
                        if (memoInput) memoInput.focus();
                    }
                },
                async submitReview() {
                    if (!this.reviewForm.memo || !this.reviewForm.memo.trim()) {
                        alert('請輸入審核意見說明！');
                        const memoInput = document.getElementById('reviewMemo');
                        if (memoInput) memoInput.focus();
                        return;
                    }

                    const confirmMsg = this.reviewForm.result === 'PASS'
                        ? '確定要「通過」此裸露地案件審核嗎？'
                        : '確定要「退件」此裸露地案件嗎？';

                    if (!confirm(confirmMsg)) return;

                    this.submitting = true;
                    try {
                        const formData = new URLSearchParams();
                        formData.append('action', 'submit_check');
                        formData.append('mode', this.mode);
                        formData.append('id', this.getUrlParam('id'));
                        formData.append('id1', this.getUrlParam('id1'));
                        formData.append('id2', this.getUrlParam('id2'));
                        formData.append('result', this.reviewForm.result);
                        formData.append('memo', this.reviewForm.memo.trim());

                        const res = await axios.post('Check_Step1_Bare.aspx', formData);
                        if (res.data && res.data.Success) {
                            alert(res.data.Message || '審核作業已完成！');
                            if (res.data.NextUrl) {
                                window.location.href = res.data.NextUrl;
                            } else {
                                window.location.href = this.backUrl;
                            }
                        } else {
                            alert('審核失敗：' + ((res.data && res.data.Message) ? res.data.Message : '未知錯誤'));
                            this.submitting = false;
                        }
                    } catch (err) {
                        alert('送出審核失敗：' + (err.message || err));
                        this.submitting = false;
                    }
                },
                openGoogleMaps() {
                    if (!this.hasCoordinates) return;
                    const lat = encodeURIComponent(this.main.Latitude);
                    const lng = encodeURIComponent(this.main.Longtitude);
                    window.open(`https://www.google.com/maps/dir/?api=1&destination=${lat},${lng}`, '_blank');
                },
                printCase() {
                    window.print();
                },
                openLightbox(url, title) {
                    if (!url) return;
                    this.lightbox.url = url;
                    this.lightbox.title = title || '現場照片檢視';
                    this.lightbox.rotation = 0;
                    this.lightbox.show = true;
                },
                closeLightbox() {
                    this.lightbox.show = false;
                },
                rotateLightbox(deg) {
                    this.lightbox.rotation = (this.lightbox.rotation + deg) % 360;
                }
            }
        }).mount('#app');
    </script>
</body>
</html>
