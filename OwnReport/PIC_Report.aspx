<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="PIC_Report.aspx.cs" Inherits="NTPC_FEC.OwnReport.PIC_Report" %>
<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定溢散源管理平台 - 固定污染源現場查核缺失改善與自主回報</title>
    
    <link rel="shortcut icon" href="../favicon.ico" type="image/x-icon" />

    <!-- 本地化樣式依賴 (符合機房資安隔離規範) -->
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

        * { box-sizing: border-box; -webkit-tap-highlight-color: transparent; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, "Noto Sans TC", "微軟正黑體", sans-serif;
            background-color: var(--bg-canvas);
            margin: 0; padding: 0;
            color: var(--text-main);
            overflow-x: hidden;
        }
        [v-cloak] { display: none !important; }

        /* 置頂深青藍導覽列 */
        .top-navbar {
            background: linear-gradient(135deg, #0099e5 0%, #0284c7 100%);
            color: #ffffff;
            height: 56px;
            display: flex; align-items: center; justify-content: space-between;
            padding: 0 16px;
            box-shadow: 0 2px 10px rgba(0, 153, 229, 0.25);
            position: sticky; top: 0; z-index: 1020;
            overflow: hidden; /* 杜絕內容溢出蓋到下方卡片 */
        }
        .nav-btn {
            background: rgba(255, 255, 255, 0.18);
            border: none; color: #ffffff;
            font-size: 0.92rem; font-weight: 600; cursor: pointer;
            height: 36px; border-radius: 8px;
            display: inline-flex; align-items: center; justify-content: center;
            padding: 0 12px; gap: 6px;
            transition: all 0.2s;
            text-decoration: none;
            white-space: nowrap;
            flex-shrink: 0;
        }
        .nav-btn:hover { background-color: rgba(255, 255, 255, 0.32); color: #ffffff; text-decoration: none; }
        .top-navbar .brand-title {
            font-size: 1.05rem; font-weight: 700; margin: 0;
            display: flex; align-items: center; gap: 8px;
            min-width: 0; flex: 1; overflow: hidden;
        }
        .navbar-page-title {
            font-size: 1.02rem; font-weight: 700;
            white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
            display: inline-block;
        }
        .badge-mode-pill {
            font-size: 0.82rem; padding: 4px 8px; white-space: nowrap; flex-shrink: 0;
        }

        /* 主容器佈局 */
        .container-fluid-custom {
            max-width: 1560px;
            margin: 0 auto;
            padding: 16px;
        }

        /* 現代卡片樣式 */
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
            display: flex; align-items: center; justify-content: space-between;
        }
        .card-modern-title {
            font-size: 1rem; font-weight: 700; color: var(--brand-navy); margin: 0;
            display: flex; align-items: center; gap: 8px;
        }
        .card-modern-body { padding: 16px; }

        /* 桌面端側欄固頂 */
        @media screen and (min-width: 1200px) {
            .sticky-sidebar {
                position: sticky; top: 72px;
                max-height: calc(100vh - 88px);
                overflow-y: auto; padding-right: 4px;
            }
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
            width: 36px; height: 36px;
            border-radius: 50%;
            background: #e2e8f0;
            color: #64748b;
            display: flex; align-items: center; justify-content: center;
            font-weight: 700; font-size: 14px;
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
            font-size: 13px; font-weight: 700; color: #475569; margin-bottom: 2px;
        }
        .step-item.active .step-title { color: var(--brand-blue); }
        .step-item.completed .step-title { color: #047857; }
        .step-time { font-size: 11px; color: #94a3b8; }
        .stepper-line {
            position: absolute; top: 34px; left: 18%; right: 18%;
            height: 3px; background: #e2e8f0; z-index: 1;
        }
        .stepper-line-fill {
            height: 100%; background: #10b981; transition: width 0.4s ease;
        }

        /* 警示橫條 */
        .alert-banner {
            border-radius: 10px;
            padding: 12px 18px;
            margin-bottom: 16px;
            display: flex; align-items: center; justify-content: space-between;
            font-size: 0.95rem; font-weight: 600;
        }
        .alert-banner.success { background: #ecfdf5; border: 1px solid #a7f3d0; color: #065f46; }
        .alert-banner.warning { background: #fffbeb; border: 1px solid #fde68a; color: #92400e; border-left: 5px solid #f59e0b; }
        .alert-banner.danger  { background: #fef2f2; border: 1px solid #fecaca; color: #991b1b; border-left: 5px solid #ef4444; }

        /* 地圖區域樣式 */
        #map {
            width: 100%; height: 260px;
            border-radius: 8px; z-index: 10;
            border: 1px solid var(--border-color);
            transition: height 0.25s ease;
        }

        /* 規格晶片 (Stat Chips) */
        .stat-chip-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 8px;
            margin-bottom: 12px;
        }
        .stat-chip {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 8px 10px;
        }
        .stat-chip-label { font-size: 11px; color: #64748b; font-weight: 600; margin-bottom: 2px; }
        .stat-chip-val { font-size: 13px; font-weight: 700; color: #0f172a; word-break: break-all; }

        /* 快速導航按鈕清單 */
        .quick-nav-list {
            display: flex; flex-direction: column; gap: 6px;
        }
        .quick-nav-item {
            display: flex; align-items: center; justify-content: space-between;
            padding: 8px 12px; border-radius: 8px;
            background: #f8fafc; border: 1px solid #e2e8f0;
            color: #334155; text-decoration: none; font-size: 12.5px; font-weight: 600;
            transition: all 0.15s ease;
        }
        .quick-nav-item:hover {
            background: #e0f2fe; border-color: #7dd3fc; color: #0369a1; text-decoration: none;
        }
        .quick-nav-item.has-loss {
            border-left: 4px solid #ef4444; background: #fff1f2;
        }

        /* 九大項檢核卡片特化 */
        .section-card {
            border-radius: 12px;
            background: #ffffff;
            border: 1px solid #e2e8f0;
            margin-bottom: 20px;
            box-shadow: 0 2px 6px rgba(15, 23, 42, 0.04);
            overflow: hidden;
            transition: border-color 0.2s ease;
        }
        .section-card.is-loss {
            border-left: 6px solid #ef4444;
        }
        .section-card.is-ok {
            border-left: 6px solid #10b981;
        }
        .section-header {
            padding: 12px 18px;
            background: #f8fafc;
            border-bottom: 1px solid #e2e8f0;
            display: flex; align-items: center; justify-content: space-between;
            flex-wrap: wrap; gap: 8px;
        }
        .section-title {
            font-size: 1.05rem; font-weight: 700; color: #0f172a; margin: 0;
            display: flex; align-items: center; gap: 8px;
        }
        .section-rule {
            font-size: 11.5px; color: #64748b; font-weight: 500;
        }

        /* 查核勾選事項清單 */
        .check-item-box {
            background: #f8fafc;
            border-radius: 8px;
            padding: 10px 14px;
            margin-bottom: 14px;
            border: 1px solid #e2e8f0;
        }
        .check-item-list {
            margin: 0; padding-left: 20px;
        }
        .check-item-list li {
            font-size: 13px; color: #334155; margin-bottom: 4px; line-height: 1.5;
        }

        /* 照片網格配置 */
        .photo-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(210px, 1fr));
            gap: 12px;
            margin-top: 10px;
        }
        .photo-card {
            background: #ffffff;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            overflow: hidden;
            display: flex; flex-direction: column;
            box-shadow: 0 1px 3px rgba(0,0,0,0.05);
        }
        .photo-card-header {
            background: #f1f5f9;
            padding: 6px 10px;
            font-size: 12px; font-weight: 700; color: #475569;
            border-bottom: 1px solid #e2e8f0;
            display: flex; align-items: center; justify-content: space-between;
        }
        .photo-thumb-wrap {
            width: 100%; height: 145px;
            background: #0f172a;
            position: relative;
            cursor: pointer;
            display: flex; align-items: center; justify-content: center;
            overflow: hidden;
        }
        .photo-thumb-wrap img {
            width: 100%; height: 100%; object-fit: cover;
            transition: transform 0.2s ease;
        }
        .photo-thumb-wrap:hover img {
            transform: scale(1.05);
        }
        .photo-thumb-wrap .zoom-overlay {
            position: absolute; inset: 0;
            background: rgba(0,0,0,0.3);
            display: flex; align-items: center; justify-content: center;
            color: #ffffff; font-size: 20px;
            opacity: 0; transition: opacity 0.2s;
        }
        .photo-thumb-wrap:hover .zoom-overlay { opacity: 1; }

        .photo-card-body {
            padding: 8px 10px;
            flex: 1;
            display: flex; flex-direction: column; justify-content: space-between;
            background: #ffffff;
        }
        .photo-memo-input {
            font-size: 12px;
            border-radius: 6px;
            border: 1px solid #cbd5e1;
            padding: 6px 8px;
            width: 100%;
            transition: border-color 0.15s;
        }
        .photo-memo-input:focus {
            border-color: var(--brand-blue);
            outline: none;
            box-shadow: 0 0 0 2px rgba(2, 132, 199, 0.2);
        }

        /* 空白上傳卡片槽位 */
        .photo-upload-slot {
            width: 100%; height: 145px;
            border: 2px dashed #cbd5e1;
            border-radius: 8px;
            display: flex; flex-direction: column; align-items: center; justify-content: center;
            color: #64748b; cursor: pointer;
            transition: all 0.2s ease;
            background: #f8fafc;
            position: relative;
        }
        .photo-upload-slot:hover {
            border-color: var(--brand-blue);
            color: var(--brand-blue);
            background: #f0f9ff;
        }
        .photo-upload-slot input[type="file"] {
            position: absolute; inset: 0; opacity: 0; cursor: pointer;
            width: 100%; height: 100%;
        }

        /* 圖片放大燈箱 Lightbox */
        .lightbox-modal {
            position: fixed; inset: 0; z-index: 1050;
            background: rgba(15, 23, 42, 0.92);
            display: flex; align-items: center; justify-content: center;
            padding: 20px;
        }
        .lightbox-close-btn {
            position: absolute; top: 16px; right: 20px;
            background: rgba(255, 255, 255, 0.2);
            border: none; color: #ffffff; font-size: 24px;
            width: 44px; height: 44px; border-radius: 50%;
            cursor: pointer; display: flex; align-items: center; justify-content: center;
            transition: background 0.2s;
        }
        .lightbox-close-btn:hover { background: rgba(255, 255, 255, 0.4); }
        .lightbox-content {
            max-width: 90vw; max-height: 85vh;
            display: flex; flex-direction: column; align-items: center;
        }
        .lightbox-content img {
            max-width: 100%; max-height: 75vh;
            border-radius: 8px; box-shadow: 0 10px 30px rgba(0,0,0,0.5);
            object-fit: contain;
        }
        .lightbox-caption {
            margin-top: 12px; color: #ffffff; font-size: 14px;
            text-align: center; background: rgba(0,0,0,0.4);
            padding: 6px 16px; border-radius: 20px;
        }

        /* 手機行動端全載具自適應 RWD 規範 */
        @media screen and (max-width: 991px) {
            body { padding-bottom: 76px; }
            .mobile-bottom-bar {
                display: flex; position: fixed; bottom: 0; left: 0; right: 0; z-index: 1010;
                background: #ffffff; border-top: 1px solid #e2e8f0;
                box-shadow: 0 -4px 16px rgba(0, 0, 0, 0.08);
                padding: 10px 16px; padding-bottom: calc(10px + env(safe-area-inset-bottom, 0px));
                gap: 8px;
            }
            .mobile-bottom-bar .btn { flex: 1; font-weight: 700; padding: 10px; border-radius: 8px; }
        }
        @media screen and (min-width: 992px) {
            .mobile-bottom-bar { display: none !important; }
        }

        @media screen and (max-width: 767px) {
            .top-navbar {
                height: 52px;
                padding: 0 10px;
            }
            .top-navbar .brand-title {
                gap: 5px;
            }
            .nav-btn {
                height: 32px;
                padding: 0 8px;
                font-size: 0.85rem;
                border-radius: 6px;
            }
            .navbar-page-title {
                font-size: 0.94rem;
                max-width: 140px;
            }
            .badge-mode-pill {
                font-size: 0.72rem;
                padding: 3px 6px;
            }
            .container-fluid-custom {
                padding: 10px 8px;
            }
            .stepper-container {
                padding: 12px 6px;
                margin-bottom: 10px;
                border-radius: 10px;
            }
            .step-circle {
                width: 28px; height: 28px;
                font-size: 12px;
                margin-bottom: 3px;
                box-shadow: 0 0 0 1.5px #cbd5e1;
            }
            .stepper-line {
                top: 25px;
                left: 14%; right: 14%;
                height: 2px;
            }
            .step-title {
                font-size: 11px;
                margin-bottom: 1px;
                letter-spacing: -0.5px;
                line-height: 1.2;
                text-align: center;
            }
            .step-time {
                font-size: 9.5px;
                color: #94a3b8;
                white-space: nowrap;
                transform: scale(0.92);
                line-height: 1.2;
                text-align: center;
            }
            .alert-banner {
                padding: 10px 12px;
                font-size: 0.85rem;
                flex-direction: column;
                align-items: flex-start;
                gap: 6px;
                margin-bottom: 10px;
            }
            .alert-banner .badge {
                align-self: flex-start;
                font-size: 0.82rem;
                padding: 4px 8px;
            }
            .stat-chip-grid {
                grid-template-columns: repeat(2, 1fr);
                gap: 6px;
            }
            .stat-chip {
                padding: 6px 8px;
            }
            .stat-chip-label {
                font-size: 10.5px;
                margin-bottom: 1px;
            }
            .stat-chip-val {
                font-size: 12px;
            }
            #map {
                height: 190px;
            }
            .leaflet-popup-content-wrapper {
                font-size: 11.5px;
                padding: 2px;
            }
            .leaflet-popup-content {
                margin: 6px 8px;
                line-height: 1.3;
            }
            .section-card {
                margin-bottom: 12px;
                border-radius: 10px;
            }
            .section-header {
                padding: 10px 12px;
            }
            .section-title {
                font-size: 0.94rem;
            }
            .photo-grid {
                grid-template-columns: repeat(2, 1fr);
                gap: 8px;
            }
            .photo-thumb-wrap, .photo-upload-slot {
                height: 120px;
            }
            .photo-card-header {
                padding: 4px 6px;
                font-size: 11px;
            }
            .photo-memo-input {
                font-size: 11px;
                padding: 4px 6px;
            }
            .card-modern-body {
                padding: 12px;
            }
        }

        @media screen and (max-width: 380px) {
            .navbar-page-title {
                max-width: 115px;
                font-size: 0.88rem;
            }
            .photo-grid {
                grid-template-columns: 1fr;
            }
            .photo-thumb-wrap, .photo-upload-slot {
                height: 140px;
            }
        }

        /* 列印最佳化 */
        @media print {
            .top-navbar, .mobile-bottom-bar, .no-print, .leaflet-control-container, .btn, .nav-btn, .photo-upload-slot {
                display: none !important;
            }
            body { background: #ffffff !important; color: #000000 !important; font-size: 12pt; }
            .container-fluid-custom { max-width: 100% !important; padding: 0 !important; }
            .card-modern, .section-card { border: 1px solid #cccccc !important; box-shadow: none !important; margin-bottom: 12px !important; }
            .sticky-sidebar { position: static !important; max-height: none !important; overflow: visible !important; }
            .print-only-header { display: block !important; text-align: center; margin-bottom: 16px; }
            .print-only-header h2 { margin: 0; font-size: 18pt; font-weight: bold; }
            .print-only-header p { margin: 4px 0 0 0; font-size: 10pt; color: #555; }
        }
        .print-only-header { display: none; }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div id="reportApp" v-cloak>
            <!-- 1. 置頂深青藍導覽列 (Top Navbar) -->
            <header class="top-navbar no-print">
                <div class="brand-title">
                    <a :href="backUrl" class="nav-btn mr-1" title="返回清單">
                        <i class="fas fa-arrow-left"></i>
                        <span class="d-none d-md-inline">返回清單</span>
                    </a>
                    <i class="fas fa-industry text-white d-none d-sm-inline"></i>
                    <span class="navbar-page-title" :title="modeTitle">
                        <span class="d-none d-sm-inline">固定污染源</span>現場查核回報
                    </span>
                    <span v-if="detail && detail.FacInfo && detail.FacInfo.CNo" class="badge badge-light text-dark font-weight-bold d-none d-lg-inline ml-1" style="font-size: 0.82rem;">
                        {{ detail.FacInfo.CNo }}
                    </span>
                    <span v-if="detail" class="badge ml-1 badge-mode-pill" :class="modeBadgeClass">
                        <span class="d-none d-sm-inline">{{ modeTitle }}</span>
                        <span class="d-inline d-sm-none">{{ modeShortTitle }}</span>
                    </span>
                </div>
                <div class="d-flex align-items-center gap-1 gap-sm-2 flex-shrink-0">
                    <button type="button" class="nav-btn bg-white text-dark shadow-sm" v-on:click="printCase" title="列印報表">
                        <i class="fas fa-print"></i>
                        <span class="d-none d-md-inline ml-1">列印</span>
                    </button>
                    <button v-if="detail && detail.FacInfo && detail.FacInfo.Lat" type="button" class="nav-btn bg-white text-dark shadow-sm ml-1" v-on:click="openGoogleMaps" title="廠址導航">
                        <i class="fas fa-location-arrow text-success"></i>
                        <span class="d-none d-md-inline ml-1">導航</span>
                    </button>

                    <!-- 自主回報模式特有：一鍵全正常快速帶入 (手機版收合至底部動作列) -->
                    <button v-if="detail && detail.CanEdit && detail.Mode === 'own'" type="button" class="btn btn-warning btn-sm font-weight-bold shadow-sm ml-1 d-none d-lg-inline-flex" v-on:click="quickPassAll">
                        <i class="fas fa-bolt mr-1"></i> 一鍵正常運行
                    </button>

                    <!-- 儲存送出按鈕 (手機版收合至底部常駐動作列) -->
                    <button v-if="detail && detail.CanEdit" type="button" class="btn btn-success btn-sm font-weight-bold shadow-sm ml-1 d-none d-lg-inline-flex" :disabled="submitting" v-on:click="submitReport">
                        <i class="fas fa-paper-plane mr-1"></i>
                        <span v-if="submitting">儲存中...</span>
                        <span v-else>確定送出回報</span>
                    </button>
                </div>
            </header>

            <!-- 列印專用報表頁首 -->
            <div class="print-only-header">
                <h2>新北市固定溢散源管理平台</h2>
                <h3>公私場所固定污染源現場查核缺失改善與自主回報表</h3>
                <p v-if="detail && detail.FacInfo">
                    公私場所：{{ detail.FacInfo.FacName }} ({{ detail.FacInfo.CNo }}) ｜ 查核日期：{{ detail.InvSummary ? detail.InvSummary.InvDate : '無' }} ｜ 列印時間：{{ printTime }}
                </p>
            </div>

            <!-- 主作業容器 -->
            <main class="container-fluid-custom">
                <!-- 載入中骨架屏 -->
                <div v-if="loading" class="text-center py-5">
                    <div class="spinner-border text-primary" role="status" style="width: 3rem; height: 3rem;">
                        <span class="sr-only">資料載入中...</span>
                    </div>
                    <p class="mt-3 text-muted font-weight-bold">正在讀取公私場所資料與九大項查核紀錄...</p>
                </div>

                <!-- A. 管理者/未綁定特定工廠時的公私場所選取器 -->
                <div v-else-if="needSelectFac" class="card-modern shadow mx-auto my-4" style="max-width: 680px;">
                    <div class="card-modern-header bg-primary text-white">
                        <h6 class="card-modern-title text-white">
                            <i class="fas fa-building mr-1"></i> 請選取公私場所
                        </h6>
                        <span class="badge badge-light text-primary">管理員模式</span>
                    </div>
                    <div class="card-modern-body p-3 p-sm-4">
                        <div class="alert alert-info py-2 px-3 small mb-3">
                            <i class="fas fa-info-circle mr-1"></i> 當前登入帳號未綁定單一公私場所，請選取欲填寫或檢視查核回報之公私場所：
                        </div>
                        <div class="form-group">
                            <label class="font-weight-bold small text-dark">快速搜尋篩選：</label>
                            <input type="text" class="form-control form-control-sm mb-2" v-model="facSearchKey" placeholder="輸入管制編號或廠名關鍵字..." />
                        </div>
                        <div class="form-group">
                            <label class="font-weight-bold small text-dark">公私場所清單 (有現場查核紀錄者優先)：</label>
                            <select class="form-control" v-model="selectedFacId" size="8" style="font-size: 13px;">
                                <option v-for="f in filteredFacOptions" :key="f.FacId" :value="f.FacId">
                                    [{{ f.CNo }}] {{ f.FacName }} ({{ f.FacId }})
                                </option>
                            </select>
                        </div>
                        <button type="button" class="btn btn-primary btn-block font-weight-bold py-2 mt-3" :disabled="!selectedFacId" v-on:click="confirmSelectFac">
                            <i class="fas fa-arrow-right mr-1"></i> 進入該場所回報作業
                        </button>
                    </div>
                </div>

                <!-- B. 錯誤警告面板 -->
                <div v-else-if="errorMessage" class="alert alert-danger shadow-sm text-center py-4 my-4">
                    <i class="fas fa-exclamation-triangle fa-2x mb-2 text-danger"></i>
                    <h5 class="font-weight-bold">讀取失敗</h5>
                    <p class="mb-3">{{ errorMessage }}</p>
                    <button type="button" class="btn btn-outline-danger btn-sm" v-on:click="loadData">
                        <i class="fas fa-redo mr-1"></i> 重新載入
                    </button>
                </div>

                <!-- C. 核心作業區 -->
                <div v-else-if="detail">
                    <!-- A. 通報階段進度時間軸 (Status Stepper) -->
                    <div class="stepper-container shadow-sm no-print">
                        <div class="stepper-line">
                            <div class="stepper-line-fill" :style="{ width: stepperProgress + '%' }"></div>
                        </div>

                        <!-- 步驟 1: 現場查核立案 -->
                        <div class="step-item" :class="getStepClass(1)">
                            <div class="step-circle">
                                <i v-if="numericStep > 1" class="fas fa-check"></i>
                                <span v-else>1</span>
                            </div>
                            <div class="step-title">現場查核立案</div>
                            <div class="step-time">{{ (detail.InvSummary && detail.InvSummary.InvDate) ? detail.InvSummary.InvDate : '查核登記' }}</div>
                        </div>

                        <!-- 步驟 2: 缺失改善/自主回報 -->
                        <div class="step-item" :class="getStepClass(2)">
                            <div class="step-circle">
                                <i v-if="numericStep > 2" class="fas fa-check"></i>
                                <span v-else>2</span>
                            </div>
                            <div class="step-title">{{ detail.Mode === 'own' ? '自主維護填報' : '缺失改善回報' }}</div>
                            <div class="step-time">{{ detail.ReportDate || (detail.CanEdit ? '填寫作業中' : '尚未回報') }}</div>
                        </div>

                        <!-- 步驟 3: 審核結案完成 -->
                        <div class="step-item" :class="getStepClass(3)">
                            <div class="step-circle">
                                <i v-if="numericStep === 3" class="fas fa-check"></i>
                                <span v-else>3</span>
                            </div>
                            <div class="step-title">完成備查/結案</div>
                            <div class="step-time">{{ numericStep === 3 ? '已備查' : '待審核' }}</div>
                        </div>
                    </div>

                    <!-- B. 查核結果狀態橫條 -->
                    <div v-if="detail.InvSummary" class="alert-banner shadow-sm" :class="detail.InvSummary.StatusLevel">
                        <div class="d-flex align-items-center gap-2">
                            <i :class="alertIconClass" class="fa-lg mr-2"></i>
                            <span>{{ detail.InvSummary.StatusAlert }}</span>
                        </div>
                        <div v-if="detail.InvSummary.TotalLossPoint > 0" class="badge badge-danger p-2 font-weight-bold" style="font-size: 0.95rem;">
                            缺失總計 {{ detail.InvSummary.TotalLossPoint }} 點
                        </div>
                    </div>

                    <!-- C. 雙欄主架構 -->
                    <div class="row">
                        <!-- 左欄 (40% 寬度，Sticky 浮動固頂) -->
                        <div class="col-xl-5 col-lg-5 col-12">
                            <div class="sticky-sidebar">
                                <!-- 公私場所基本資料卡片 -->
                                <div class="card-modern">
                                    <div class="card-modern-header">
                                        <h6 class="card-modern-title">
                                            <i class="fas fa-building text-primary"></i> 公私場所基本資料
                                        </h6>
                                        <span class="badge badge-info">{{ detail.FacInfo.CNo }}</span>
                                    </div>
                                    <div class="card-modern-body">
                                        <h5 class="font-weight-bold text-dark mb-2" style="font-size: 1.1rem;">{{ detail.FacInfo.FacName }}</h5>
                                        <p class="text-muted small mb-3">
                                            <i class="fas fa-map-marker-alt text-danger mr-1"></i> {{ detail.FacInfo.Addr }}
                                        </p>

                                        <div class="stat-chip-grid">
                                            <div class="stat-chip">
                                                <div class="stat-chip-label">聯絡電話</div>
                                                <div class="stat-chip-val">{{ detail.FacInfo.Tel || '未填寫' }}</div>
                                            </div>
                                            <div class="stat-chip">
                                                <div class="stat-chip-label">當日天氣</div>
                                                <div class="stat-chip-val">{{ detail.InvSummary ? detail.InvSummary.Weather : '未填寫' }}</div>
                                            </div>
                                            <div class="stat-chip">
                                                <div class="stat-chip-label">現場操作狀況</div>
                                                <div class="stat-chip-val">{{ detail.InvSummary ? detail.InvSummary.WorkState : '正常操作' }}</div>
                                            </div>
                                            <div class="stat-chip">
                                                <div class="stat-chip-label">改善期限</div>
                                                <div class="stat-chip-val text-danger">{{ (detail.InvSummary && detail.InvSummary.ImproveDeadline) ? detail.InvSummary.ImproveDeadline : '無' }}</div>
                                            </div>
                                        </div>

                                        <div v-if="detail.InvSummary && detail.InvSummary.WorkMemo && detail.InvSummary.WorkMemo !== '無'" class="alert alert-light border p-2 small mb-0">
                                            <span class="font-weight-bold text-secondary">現場概述備註：</span>{{ detail.InvSummary.WorkMemo }}
                                        </div>
                                    </div>
                                </div>

                                <!-- 地理空間圖資卡片 (Leaflet.js) -->
                                <div class="card-modern">
                                    <div class="card-modern-header">
                                        <h6 class="card-modern-title">
                                            <i class="fas fa-map-marked-alt text-primary"></i> 現場位置圖
                                        </h6>
                                        <div class="d-flex align-items-center">
                                            <button type="button" class="btn btn-xs btn-outline-primary py-1 px-2 d-inline-block d-md-none mr-1" style="font-size: 11px;" v-on:click="toggleMapCollapse">
                                                <i :class="isMapCollapsed ? 'fas fa-chevron-down' : 'fas fa-chevron-up'"></i>
                                                {{ isMapCollapsed ? '展開地圖' : '收合地圖' }}
                                            </button>
                                            <button type="button" class="btn btn-xs btn-outline-secondary py-1 px-2" style="font-size: 11px;" v-on:click="resetMapView">
                                                <i class="fas fa-crosshairs"></i> 置中
                                            </button>
                                        </div>
                                    </div>
                                    <div class="card-modern-body p-2" v-show="!isMapCollapsed">
                                        <div id="map"></div>
                                        <div class="text-muted small mt-1 px-1 d-flex justify-content-between">
                                            <span>TWD97: {{ detail.FacInfo.Twd97X.toFixed(0) }}, {{ detail.FacInfo.Twd97Y.toFixed(0) }}</span>
                                            <span>WGS84: {{ detail.FacInfo.Lat.toFixed(4) }}, {{ detail.FacInfo.Lng.toFixed(4) }}</span>
                                        </div>
                                    </div>
                                </div>

                                <!-- 九大項快速定位跳轉面板 (桌面端) -->
                                <div class="card-modern no-print d-none d-lg-block">
                                    <div class="card-modern-header">
                                        <h6 class="card-modern-title">
                                            <i class="fas fa-list-ol text-primary"></i> 九大防制項目導航
                                        </h6>
                                        <small class="text-muted">點選快速捲動</small>
                                    </div>
                                    <div class="card-modern-body p-2">
                                        <div class="quick-nav-list">
                                            <a v-for="sec in detail.Sections" :key="sec.Code" :href="'#sec_' + sec.Code" class="quick-nav-item" :class="{ 'has-loss': sec.HasLoss }">
                                                <span>{{ sec.Title }}</span>
                                                <span v-if="sec.HasLoss" class="badge badge-danger">記 {{ sec.LossPoint }} 點</span>
                                                <span v-else class="badge badge-success">合格 (0點)</span>
                                            </a>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- 右欄 (60% 寬度，九大項查核與回報主作業區) -->
                        <div class="col-xl-7 col-lg-7 col-12">
                            <!-- 頂部篩選與進度 -->
                            <div class="card-modern mb-3 no-print">
                                <div class="card-modern-body py-2 px-3 d-flex align-items-center justify-content-between flex-wrap gap-2">
                                    <div class="d-flex align-items-center gap-2">
                                        <span class="font-weight-bold small text-secondary">顯示項目：</span>
                                        <div class="btn-group btn-group-toggle btn-group-sm">
                                            <button type="button" class="btn" :class="filterOnlyLoss ? 'btn-outline-primary' : 'btn-primary'" v-on:click="filterOnlyLoss = false">
                                                全部 9 項 ({{ detail.Sections.length }})
                                            </button>
                                            <button type="button" class="btn" :class="filterOnlyLoss ? 'btn-danger' : 'btn-outline-danger'" v-on:click="filterOnlyLoss = true">
                                                僅看缺失 ({{ lossSectionCount }})
                                            </button>
                                        </div>
                                    </div>
                                    <div class="small font-weight-bold text-muted">
                                        已填報相片：<span class="text-primary font-weight-bold">{{ filledPhotoCount }}</span> 張
                                    </div>
                                </div>
                            </div>

                            <!-- 九大項清單卡片 -->
                            <div v-for="sec in filteredSections" :key="sec.Code" :id="'sec_' + sec.Code" class="section-card" :class="sec.HasLoss ? 'is-loss' : 'is-ok'">
                                <div class="section-header">
                                    <div>
                                        <h6 class="section-title">
                                            <i v-if="sec.HasLoss" class="fas fa-exclamation-circle text-danger"></i>
                                            <i v-else class="fas fa-check-circle text-success"></i>
                                            {{ sec.Title }}
                                        </h6>
                                        <div class="section-rule">{{ sec.LawRule }}</div>
                                    </div>
                                    <div>
                                        <span v-if="sec.HasLoss" class="badge badge-danger p-2" style="font-size: 0.85rem;">
                                            <i class="fas fa-times-circle mr-1"></i> 違規記 {{ sec.LossPoint }} 點
                                        </span>
                                        <span v-else class="badge badge-success p-2" style="font-size: 0.85rem;">
                                            <i class="fas fa-check-circle mr-1"></i> 合格 (0點)
                                        </span>
                                    </div>
                                </div>

                                <div class="card-modern-body">
                                    <!-- 1. 現場查核條文認定事實 -->
                                    <div class="mb-3">
                                        <label class="font-weight-bold small text-dark d-block">
                                            <i class="fas fa-clipboard-check text-secondary mr-1"></i> 現場查核認定事項：
                                        </label>
                                        <div v-if="sec.CheckItems && sec.CheckItems.length > 0" class="check-item-box">
                                            <ul class="check-item-list">
                                                <li v-for="(item, idx) in sec.CheckItems" :key="idx">{{ item }}</li>
                                            </ul>
                                        </div>
                                        <div v-else class="text-muted small pl-2">
                                            無缺失或未勾選特定違規事項。
                                        </div>
                                    </div>

                                    <!-- 2. 現場查核照片 (Audit Photos) -->
                                    <div v-if="sec.AuditPhotos && sec.AuditPhotos.length > 0" class="mb-4">
                                        <label class="font-weight-bold small text-dark d-flex align-items-center justify-content-between">
                                            <span><i class="fas fa-camera text-info mr-1"></i> 稽查人員現場存證照片：</span>
                                            <small class="text-muted">共 {{ sec.AuditPhotos.length }} 張</small>
                                        </label>
                                        <div class="photo-grid">
                                            <div v-for="p in sec.AuditPhotos" :key="p.Key" class="photo-card">
                                                <div class="photo-card-header">
                                                    <span class="text-truncate" :title="p.Title">{{ p.Title }}</span>
                                                    <span v-if="p.Exists" class="badge badge-success">現場照</span>
                                                    <span v-else class="badge badge-secondary">無照片</span>
                                                </div>
                                                <div class="photo-thumb-wrap" v-on:click="openLightbox(p)">
                                                    <img :src="p.Url" :alt="p.Title" />
                                                    <div class="zoom-overlay">
                                                        <i class="fas fa-search-plus"></i>
                                                    </div>
                                                </div>
                                                <div v-if="p.Memo" class="photo-card-body py-1 px-2 small text-muted">
                                                    {{ p.Memo }}
                                                </div>
                                            </div>
                                        </div>
                                    </div>

                                    <hr class="my-3" />

                                    <!-- 3. 改善回報 / 自主回報作業區 (Report Photos & Memo) -->
                                    <div>
                                        <div class="d-flex align-items-center justify-content-between mb-2">
                                            <label class="font-weight-bold small text-primary m-0">
                                                <i class="fas fa-upload text-primary mr-1"></i> {{ detail.Mode === 'own' ? '自主巡報照片與佐證' : '改善完成佐證照片與說明' }}：
                                            </label>
                                            <span v-if="detail.CanEdit" class="badge badge-warning text-dark d-none d-sm-inline">可點選槽位拍照或選檔</span>
                                        </div>

                                        <div class="photo-grid">
                                            <div v-for="rp in sec.ReportPhotos" :key="rp.Key" class="photo-card">
                                                <div class="photo-card-header">
                                                    <span class="text-truncate">{{ rp.Title }}</span>
                                                    <span v-if="rp.Exists || rp.PreviewUrl" class="badge badge-primary">已上傳</span>
                                                    <span v-else class="badge badge-light border text-muted">待上傳</span>
                                                </div>

                                                <!-- 已有照片或預覽圖 -->
                                                <div v-if="rp.PreviewUrl || (rp.Url && rp.Exists)" class="photo-thumb-wrap" v-on:click="openLightbox(rp)">
                                                    <img :src="rp.PreviewUrl || rp.Url" :alt="rp.Title" />
                                                    <div class="zoom-overlay">
                                                        <i class="fas fa-search-plus"></i>
                                                    </div>
                                                </div>

                                                <!-- 編輯模式：未上傳時的拍照/選取上傳槽 -->
                                                <div v-else-if="detail.CanEdit" class="photo-upload-slot">
                                                    <i class="fas fa-camera fa-2x mb-1"></i>
                                                    <span class="small font-weight-bold">拍照 / 上傳</span>
                                                    <input type="file" accept="image/*" v-on:change="handlePhotoUpload($event, rp)" />
                                                </div>

                                                <!-- 唯讀模式：無照片提示 -->
                                                <div v-else class="photo-thumb-wrap" style="background: #f1f5f9; cursor: default;">
                                                    <span class="text-muted small">未提供照片</span>
                                                </div>

                                                <!-- 補充說明輸入框或唯讀文字 -->
                                                <div class="photo-card-body">
                                                    <div v-if="detail.CanEdit">
                                                        <input type="text" class="photo-memo-input" v-model="rp.Memo" placeholder="輸入照片補充說明..." />
                                                        <div v-if="rp.PreviewUrl" class="text-right mt-1">
                                                            <button type="button" class="btn btn-link btn-xs text-danger p-0 font-weight-bold" style="font-size: 11px;" v-on:click="clearUpload(rp)">
                                                                <i class="fas fa-trash-alt mr-1"></i> 清除
                                                            </button>
                                                        </div>
                                                    </div>
                                                    <div v-else class="small text-secondary">
                                                        <span class="font-weight-bold">補充說明：</span>
                                                        <span>{{ rp.Memo || '無說明' }}</span>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- 底部儲存列 (桌面版) -->
                            <div v-if="detail.CanEdit" class="card-modern shadow-sm no-print d-none d-lg-block">
                                <div class="card-modern-body text-center py-3">
                                    <button type="button" class="btn btn-outline-secondary mr-2 px-4" v-on:click="goBack">
                                        <i class="fas fa-undo mr-1"></i> 取消返回
                                    </button>
                                    <button type="button" class="btn btn-success px-5 font-weight-bold shadow-sm" :disabled="submitting" v-on:click="submitReport">
                                        <i class="fas fa-check-circle mr-1"></i>
                                        <span v-if="submitting">資料儲存中，請稍候...</span>
                                        <span v-else>送出回報紀錄</span>
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </main>

            <!-- 手機端懸浮底部動作列 (Sticky Bottom Bar) -->
            <div v-if="detail && detail.CanEdit" class="mobile-bottom-bar no-print">
                <button type="button" class="btn btn-outline-secondary" v-on:click="goBack" style="flex: 0 0 54px;" title="返回">
                    <i class="fas fa-arrow-left"></i>
                </button>
                <button v-if="detail.Mode === 'own'" type="button" class="btn btn-warning font-weight-bold" v-on:click="quickPassAll" style="flex: 1;">
                    <i class="fas fa-bolt mr-1"></i> 一鍵正常
                </button>
                <button type="button" class="btn btn-success font-weight-bold" :disabled="submitting" v-on:click="submitReport" style="flex: 1.3;">
                    <i class="fas fa-paper-plane mr-1"></i> 送出回報
                </button>
            </div>

            <!-- 全螢幕圖片放大燈箱 (Lightbox) -->
            <div v-if="lightbox.show" class="lightbox-modal no-print" v-on:click="closeLightbox">
                <button type="button" class="lightbox-close-btn" v-on:click.stop="closeLightbox">
                    <i class="fas fa-times"></i>
                </button>
                <div class="lightbox-content" v-on:click.stop>
                    <img :src="lightbox.url" :alt="lightbox.title" />
                    <div class="lightbox-caption">
                        <div class="font-weight-bold">{{ lightbox.title }}</div>
                        <div v-if="lightbox.memo" class="small text-white-50 mt-1">{{ lightbox.memo }}</div>
                    </div>
                </div>
            </div>
        </div>
    </form>

    <!-- 本地端核心腳本庫 (依據鐵律禁止依賴外部 CDN) -->
    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>
    <script src="../Scripts/leaflet/leaflet.js"></script>

    <script>
        const { createApp, ref, computed, onMounted, markRaw, nextTick } = Vue;

        createApp({
            data() {
                return {
                    loading: true,
                    errorMessage: '',
                    submitting: false,
                    detail: null,
                    filterOnlyLoss: false,
                    printTime: '',
                    isMapCollapsed: false,
                    needSelectFac: false,
                    facOptions: [],
                    facSearchKey: '',
                    selectedFacId: '',
                    lightbox: {
                        show: false,
                        url: '',
                        title: '',
                        memo: ''
                    }
                };
            },
            computed: {
                backUrl() {
                    const mode = (this.detail && this.detail.Mode) ? this.detail.Mode : 'wrong';
                    return 'PIC_Report_List.aspx?mode=' + mode;
                },
                modeTitle() {
                    if (!this.detail) return '';
                    if (this.detail.Mode === 'own') return '自主維護回報';
                    if (this.detail.Mode === 'read') return '回報紀錄檢視';
                    return '缺失改善回報';
                },
                modeShortTitle() {
                    if (!this.detail) return '';
                    if (this.detail.Mode === 'own') return '自主';
                    if (this.detail.Mode === 'read') return '檢視';
                    return '改善';
                },
                modeBadgeClass() {
                    if (!this.detail) return 'badge-secondary';
                    if (this.detail.Mode === 'own') return 'badge-info';
                    if (this.detail.Mode === 'read') return 'badge-light text-dark';
                    return 'badge-warning text-dark';
                },
                numericStep() {
                    if (!this.detail) return 1;
                    if (this.detail.Mode === 'read') return 3;
                    if (this.detail.CanEdit) return 2;
                    return 1;
                },
                stepperProgress() {
                    if (this.numericStep === 3) return 100;
                    if (this.numericStep === 2) return 50;
                    return 0;
                },
                alertIconClass() {
                    if (!this.detail || !this.detail.InvSummary) return 'fas fa-info-circle';
                    const lvl = this.detail.InvSummary.StatusLevel;
                    if (lvl === 'danger') return 'fas fa-exclamation-triangle text-danger';
                    if (lvl === 'warning') return 'fas fa-exclamation-circle text-warning';
                    return 'fas fa-check-circle text-success';
                },
                filteredFacOptions() {
                    if (!this.facSearchKey || this.facSearchKey.trim() === '') {
                        return this.facOptions;
                    }
                    const k = this.facSearchKey.trim().toLowerCase();
                    return this.facOptions.filter(function(f) {
                        return (f.FacName && f.FacName.toLowerCase().indexOf(k) >= 0) ||
                               (f.CNo && f.CNo.toLowerCase().indexOf(k) >= 0) ||
                               (f.FacId && f.FacId.toLowerCase().indexOf(k) >= 0);
                    });
                },
                lossSectionCount() {
                    if (!this.detail || !this.detail.Sections) return 0;
                    return this.detail.Sections.filter(function (s) { return s.HasLoss; }).length;
                },
                filteredSections() {
                    if (!this.detail || !this.detail.Sections) return [];
                    if (this.filterOnlyLoss) {
                        return this.detail.Sections.filter(function (s) { return s.HasLoss; });
                    }
                    return this.detail.Sections;
                },
                filledPhotoCount() {
                    if (!this.detail || !this.detail.Sections) return 0;
                    let count = 0;
                    this.detail.Sections.forEach(function (sec) {
                        if (sec.ReportPhotos) {
                            sec.ReportPhotos.forEach(function (rp) {
                                if (rp.PreviewUrl || (rp.Url && rp.Exists)) {
                                    count++;
                                }
                            });
                        }
                    });
                    return count;
                }
            },
            mounted() {
                this.printTime = new Date().toLocaleString();
                this.loadData();

                // 註冊鍵盤 ESC 關閉燈箱
                window.addEventListener('keydown', (e) => {
                    if (e.key === 'Escape' && this.lightbox.show) {
                        this.closeLightbox();
                    }
                });
            },
            methods: {
                loadData() {
                    this.loading = true;
                    this.errorMessage = '';

                    const urlParams = new URLSearchParams(window.location.search);
                    const mode = urlParams.get('mode') || 'wrong';
                    const id = urlParams.get('id') || '';
                    const id1 = urlParams.get('id1') || '';
                    const inv = urlParams.get('inv') || '';
                    const rep = urlParams.get('rep') || '';

                    axios.get('PIC_Report.aspx', {
                        params: {
                            action: 'getdata',
                            mode: mode,
                            id: id || this.selectedFacId,
                            id1: id1,
                            inv: inv,
                            rep: rep
                        }
                    })
                    .then(res => {
                        this.loading = false;
                        if (res.data && res.data.Success) {
                            if (res.data.NeedSelectFac) {
                                this.needSelectFac = true;
                                this.facOptions = res.data.FacOptions || [];
                                return;
                            }
                            this.needSelectFac = false;
                            this.detail = res.data.Data;

                            // 若只有缺失且有缺失項目，預設若在 wrong 模式則讓使用者可自由切換
                            if (this.detail.Mode === 'wrong' && this.lossSectionCount > 0) {
                                this.filterOnlyLoss = false;
                            }

                            nextTick(() => {
                                this.initLeafletMap();
                            });
                        } else {
                            this.errorMessage = (res.data && res.data.Message) ? res.data.Message : '讀取案件資料失敗';
                        }
                    })
                    .catch(err => {
                        this.loading = false;
                        this.errorMessage = '伺服器連線失敗：' + (err.message || err);
                    });
                },

                // 初始化 Leaflet 地圖 (遵循隔離鐵律杜絕 project 崩潰)
                initLeafletMap() {
                    if (!this.detail || !this.detail.FacInfo) return;
                    const mapEl = document.getElementById('map');
                    if (!mapEl) return;

                    let lat = this.detail.FacInfo.Lat;
                    let lng = this.detail.FacInfo.Lng;

                    // 若無座標則預設新北市府
                    if (!lat || !lng || lat === 0 || lng === 0) {
                        lat = 25.0123;
                        lng = 121.4657;
                    }

                    if (this.leafletMap) {
                        try { this.leafletMap.remove(); } catch (e) {}
                    }

                    const mapInstance = L.map('map', {
                        center: [lat, lng],
                        zoom: 15,
                        zoomControl: true
                    });

                    L.tileLayer('https://wmts.nlsc.gov.tw/wmts/EMAP/default/GoogleMapsCompatible/{z}/{y}/{x}', {
                        maxZoom: 19,
                        attribution: '&copy; 國土測繪圖資'
                    }).addTo(mapInstance);

                    // 標記工廠 Pin
                    const marker = L.marker([lat, lng]).addTo(mapInstance);
                    const popupContent = '<b>' + (this.detail.FacInfo.FacName || '公私場所') + '</b><br/>' + (this.detail.FacInfo.Addr || '');
                    
                    // 手機端視窗小，避免彈出遮滿全圖，僅於點擊時打開或大螢幕時預設打開
                    if (window.innerWidth >= 768) {
                        marker.bindPopup(popupContent).openPopup();
                    } else {
                        marker.bindPopup(popupContent);
                    }

                    // 使用 markRaw 存於原生屬性中
                    this.leafletMap = markRaw(mapInstance);
                },

                toggleMapCollapse() {
                    this.isMapCollapsed = !this.isMapCollapsed;
                    if (!this.isMapCollapsed && this.leafletMap) {
                        nextTick(() => {
                            this.leafletMap.invalidateSize();
                        });
                    }
                },

                resetMapView() {
                    if (!this.leafletMap || !this.detail || !this.detail.FacInfo) return;
                    let lat = this.detail.FacInfo.Lat;
                    let lng = this.detail.FacInfo.Lng;
                    if (lat && lng && lat > 0 && lng > 0) {
                        this.leafletMap.setView([lat, lng], 15);
                    }
                },

                confirmSelectFac() {
                    if (!this.selectedFacId) return;
                    const url = new URL(window.location.href);
                    url.searchParams.set('id', this.selectedFacId);
                    window.history.replaceState({}, '', url.toString());
                    this.loadData();
                },

                getStepClass(step) {
                    if (this.numericStep > step) return 'completed';
                    if (this.numericStep === step) return 'active';
                    return '';
                },

                openGoogleMaps() {
                    if (!this.detail || !this.detail.FacInfo) return;
                    const lat = this.detail.FacInfo.Lat;
                    const lng = this.detail.FacInfo.Lng;
                    if (lat && lng) {
                        const url = 'https://www.google.com/maps/dir/?api=1&destination=' + lat + ',' + lng;
                        window.open(url, '_blank');
                    }
                },

                printCase() {
                    window.print();
                },

                goBack() {
                    window.location.href = this.backUrl;
                },

                // 燈箱控制
                openLightbox(photo) {
                    const url = photo.PreviewUrl || photo.Url;
                    if (!url || url.indexOf('nophoto.jpg') >= 0) return;
                    this.lightbox.url = url;
                    this.lightbox.title = photo.Title || '現場照片';
                    this.lightbox.memo = photo.Memo || '';
                    this.lightbox.show = true;
                },
                closeLightbox() {
                    this.lightbox.show = false;
                },

                // 處理相片本機選取與即時 Base64 縮圖預覽
                handlePhotoUpload(event, photoItem) {
                    const file = event.target.files[0];
                    if (!file) return;

                    // 檢查檔案大小上限 15MB
                    if (file.size > 15 * 1024 * 1024) {
                        alert('所選取的照片檔案過大（超過 15MB），請壓縮後再上傳。');
                        event.target.value = '';
                        return;
                    }

                    const reader = new FileReader();
                    reader.onload = (e) => {
                        photoItem.PreviewUrl = e.target.result;
                        photoItem.Base64Data = e.target.result;
                        photoItem.FileObj = file;
                    };
                    reader.readAsDataURL(file);
                },

                clearUpload(photoItem) {
                    photoItem.PreviewUrl = '';
                    photoItem.Base64Data = '';
                    photoItem.FileObj = null;
                },

                // 自主回報模式：一鍵填寫全部正常運行
                quickPassAll() {
                    if (!confirm('確定要為各項防制設施一鍵帶入「各項設施正常運作，無粒狀物逸散」嗎？')) {
                        return;
                    }
                    if (this.detail && this.detail.Sections) {
                        this.detail.Sections.forEach(function (sec) {
                            if (sec.ReportPhotos) {
                                sec.ReportPhotos.forEach(function (rp) {
                                    if (!rp.Memo || rp.Memo.trim() === '') {
                                        rp.Memo = '設施正常運作，現場無粒狀污染物質逸散情形。';
                                    }
                                });
                            }
                        });
                    }
                },

                // 送出回報資料
                submitReport() {
                    if (!this.detail || !this.detail.FacInfo) return;

                    if (!confirm('確定要送出本次' + this.modeTitle + '資料嗎？')) {
                        return;
                    }

                    this.submitting = true;

                    const formData = new FormData();
                    formData.append('FAC_ID', this.detail.FacInfo.FacId);
                    formData.append('INV_NO', this.detail.InvSummary ? this.detail.InvSummary.InvNo : 0);
                    formData.append('mode', this.detail.Mode);

                    // 組合補充說明與照片
                    this.detail.Sections.forEach(function (sec) {
                        if (sec.ReportPhotos) {
                            sec.ReportPhotos.forEach(function (rp) {
                                const k = rp.Key;
                                formData.append('FileMemo_' + k, rp.Memo || '');

                                if (rp.FileObj) {
                                    formData.append(k, rp.FileObj);
                                } else if (rp.Base64Data) {
                                    formData.append('PhotoBase64_' + k, rp.Base64Data);
                                }
                            });
                        }
                    });

                    axios.post('PIC_Report.aspx?action=save', formData, {
                        headers: { 'Content-Type': 'multipart/form-data' }
                    })
                    .then(res => {
                        this.submitting = false;
                        if (res.data && res.data.Success) {
                            alert(res.data.Message || '回報成功送出！');
                            const repNo = res.data.Data ? res.data.Data.ReportNo : 1;
                            // 跳轉至唯讀檢視模式
                            window.location.href = 'PIC_Report.aspx?mode=read&id=' + this.detail.FacInfo.FacId + '&inv=' + (this.detail.InvSummary ? this.detail.InvSummary.InvNo : 0) + '&rep=' + repNo;
                        } else {
                            alert('儲存失敗：' + ((res.data && res.data.Message) ? res.data.Message : '未知錯誤'));
                        }
                    })
                    .catch(err => {
                        this.submitting = false;
                        alert('伺服器連線錯誤：' + (err.message || err));
                    });
                }
            }
        }).mount('#reportApp');
    </script>
</body>
</html>
