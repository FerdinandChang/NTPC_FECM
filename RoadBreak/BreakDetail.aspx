<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="BreakDetail.aspx.cs" Inherits="NTPC_FEC.RoadBreak.BreakDetail" %>

<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定逸散源管理平台 - 道路破損通報案件檢視</title>

    <!-- 專屬 Favicon -->
    <link rel="shortcut icon" href="../favicon.ico" type="image/x-icon" />

    <!-- 本地化核心樣式庫 -->
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
            gap: 8px;
        }

        .nav-btn {
            background: rgba(255, 255, 255, 0.18);
            border: 1px solid rgba(255, 255, 255, 0.3);
            color: #ffffff !important;
            font-size: 0.9rem;
            font-weight: 600;
            cursor: pointer;
            height: 36px;
            border-radius: 8px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            padding: 0 12px;
            gap: 6px;
            transition: all 0.2s;
            text-decoration: none !important;
            white-space: nowrap;
            flex-shrink: 0;
        }

        .nav-btn:hover {
            background-color: rgba(255, 255, 255, 0.32);
            color: #ffffff !important;
            text-decoration: none !important;
        }

        .top-navbar .brand-title {
            font-size: 1.05rem;
            font-weight: 700;
            margin: 0;
            display: flex;
            align-items: center;
            gap: 8px;
            min-width: 0;
            flex: 1;
            overflow: hidden;
        }

        .brand-title-text {
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .navbar-actions {
            display: flex;
            align-items: center;
            gap: 6px;
            flex-shrink: 0;
        }

        /* 主容器佈局 */
        .container-fluid-custom {
            max-width: 1400px;
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
            padding: 14px 20px;
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
            width: 34px; height: 34px;
            border-radius: 50%;
            background: #e2e8f0;
            color: #64748b;
            display: flex; align-items: center; justify-content: center;
            font-weight: 700; font-size: 13px;
            margin-bottom: 4px;
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
            position: absolute;
            top: 31px; left: 16%; right: 16%;
            height: 3px;
            background: #e2e8f0;
            z-index: 1;
        }
        .stepper-line-fill {
            height: 100%;
            background: #10b981;
            transition: width 0.4s ease;
        }

        /* 退回醒目警示 */
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

        /* 建議持續追蹤醒目提示卡 */
        .alert-follow {
            background: linear-gradient(135deg, #f0f9ff 0%, #e0f2fe 100%);
            border: 1px solid #7dd3fc;
            border-left: 6px solid #0284c7;
            border-radius: 10px;
            padding: 14px 18px;
            margin-bottom: 16px;
            color: #0c4a6e;
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-wrap: wrap;
            gap: 12px;
        }

        /* ========================================================
           專案標準三大專題卡片排版樣式 (符合 inspection-ui-standard)
           ======================================================== */
        .gov-card {
            background: #ffffff;
            border-radius: 12px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05), 0 4px 12px rgba(15, 23, 42, 0.05);
            margin-bottom: 20px;
            border: 1px solid var(--border-color);
            overflow: hidden;
        }

        .gov-header {
            background: #ffffff;
            color: var(--brand-navy);
            font-size: 1.05rem;
            font-weight: 700;
            text-align: left;
            padding: 14px 20px;
            letter-spacing: 0.5px;
            border-bottom: 1px solid var(--border-color);
            user-select: none;
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-wrap: wrap;
            gap: 10px;
        }

        .gov-table {
            width: 100%;
            border-collapse: collapse;
            background: #ffffff;
            margin: 0;
        }

        .gov-table td, .gov-table th {
            border: 1px solid var(--border-color);
            padding: 12px 16px;
            font-size: 14px;
            vertical-align: middle;
        }

        .gov-label {
            background-color: #f8fafc;
            color: #334155;
            font-weight: 700;
            width: 140px;
            min-width: 120px;
            text-align: left;
            white-space: nowrap;
        }

        .gov-val {
            background-color: #ffffff;
            color: var(--text-main);
            font-weight: 500;
        }

        .gov-val-highlight {
            color: var(--brand-blue);
            font-weight: 700;
            font-size: 15px;
        }

        .gov-val-danger {
            color: #b91c1c;
            font-weight: 700;
        }

        .btn-streetview {
            background: #ffffff;
            border: 1px solid #cbd5e1;
            color: #1e293b !important;
            font-size: 12px;
            font-weight: 700;
            padding: 4px 10px;
            border-radius: 6px;
            display: inline-flex;
            align-items: center;
            gap: 5px;
            cursor: pointer;
            transition: all 0.2s;
            text-decoration: none !important;
            box-shadow: 0 1px 2px rgba(0,0,0,0.05);
        }

        .btn-streetview:hover {
            background: #f0f9ff;
            color: var(--brand-blue) !important;
            border-color: var(--brand-blue);
        }

        /* 現場地圖容器與收合控制 */
        #map {
            width: 100%;
            height: 360px;
            border-radius: 8px;
            border: 1px solid #cbd5e1;
            z-index: 10;
            transition: height 0.3s ease;
            margin-top: 8px;
        }
        #map.map-collapsed {
            height: 120px !important;
        }

        /* 自訂地圖圖釘 (Custom Marker) */
        .custom-map-marker {
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .marker-pin {
            width: 34px;
            height: 34px;
            border-radius: 50% 50% 50% 0;
            background: #ef4444;
            position: absolute;
            transform: rotate(-45deg);
            left: 50%;
            top: 50%;
            margin: -20px 0 0 -20px;
            display: flex;
            align-items: center;
            justify-content: center;
            box-shadow: 0 2px 5px rgba(0, 0, 0, 0.4);
        }

        .marker-pin i {
            transform: rotate(45deg);
            color: #ffffff;
            font-size: 14px;
        }

        /* 照片晶片與縮圖 */
        .photo-chip-list {
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
            align-items: center;
        }

        .photo-badge-btn {
            background: #f0f9ff;
            border: 1px solid #bae6fd;
            color: #0369a1;
            padding: 5px 12px;
            border-radius: 6px;
            font-weight: 700;
            font-size: 13px;
            display: inline-flex;
            align-items: center;
            gap: 6px;
            cursor: pointer;
            transition: all 0.2s;
            box-shadow: 0 1px 2px rgba(0, 0, 0, 0.04);
        }

        .photo-badge-btn:hover {
            background: #e0f2fe;
            border-color: var(--brand-blue);
            transform: translateY(-1px);
            box-shadow: 0 2px 6px rgba(2, 132, 199, 0.15);
        }

        .photo-mini-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(130px, 1fr));
            gap: 10px;
            margin-top: 10px;
        }

        .photo-mini-card {
            border: 1px solid #cbd5e1;
            border-radius: 6px;
            overflow: hidden;
            background: #ffffff;
            cursor: pointer;
            transition: all 0.2s;
        }

        .photo-mini-card:hover {
            border-color: #0284c7;
            transform: scale(1.02);
            box-shadow: 0 4px 10px rgba(0, 0, 0, 0.12);
        }

        .photo-mini-card img {
            width: 100%;
            height: 90px;
            object-fit: cover;
            display: block;
        }

        .photo-mini-caption {
            font-size: 11px;
            font-weight: 700;
            text-align: center;
            padding: 4px 6px;
            background: #f8fafc;
            color: #334155;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        /* 現場成果照片 Before/After 對比區樣式 */
        .comparison-card {
            border: 1px solid var(--border-color);
            border-radius: 8px;
            margin-bottom: 14px;
            background: #ffffff;
            overflow: hidden;
        }

        .comparison-header {
            background: #f8fafc;
            padding: 10px 14px;
            font-weight: 700;
            border-bottom: 1px solid var(--border-color);
            display: flex;
            justify-content: space-between;
            align-items: center;
            font-size: 14px;
        }

        .comparison-body {
            display: flex;
            padding: 12px;
            gap: 12px;
        }

        .photo-pane {
            flex: 1;
            display: flex;
            flex-direction: column;
        }

        .photo-tag {
            font-size: 12px;
            font-weight: 700;
            padding: 3px 8px;
            border-radius: 4px;
            margin-bottom: 6px;
            display: inline-flex;
            align-items: center;
            gap: 4px;
            align-self: flex-start;
        }

        .photo-tag-before {
            background: #fee2e2;
            color: #b91c1c;
        }

        .photo-tag-after {
            background: #dcfce7;
            color: #15803d;
        }

        .photo-frame {
            position: relative;
            height: 220px;
            border-radius: 6px;
            overflow: hidden;
            border: 1px solid #cbd5e1;
            cursor: pointer;
            background: #000000;
        }

        .photo-frame img {
            width: 100%;
            height: 100%;
            object-fit: cover;
            transition: transform 0.3s ease;
        }

        .photo-frame:hover img {
            transform: scale(1.03);
        }

        .photo-overlay {
            position: absolute;
            bottom: 0; left: 0; right: 0;
            padding: 6px 10px;
            background: linear-gradient(to top, rgba(15, 23, 42, 0.8) 0%, transparent 100%);
            color: #ffffff;
            font-size: 0.75rem;
            display: flex;
            justify-content: space-between;
            align-items: flex-end;
            opacity: 0;
            transition: opacity 0.2s ease;
        }

        .photo-frame:hover .photo-overlay {
            opacity: 1;
        }

        .photo-empty {
            height: 220px;
            border-radius: 6px;
            border: 2px dashed #cbd5e1;
            background: #f8fafc;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            color: #94a3b8;
            padding: 16px;
            text-align: center;
        }

        .photo-empty i {
            font-size: 2rem;
            margin-bottom: 6px;
            color: #cbd5e1;
        }

        /* 照片燈箱 (Lightbox Modal) */
        .lightbox-modal {
            position: fixed;
            top: 0; left: 0; right: 0; bottom: 0;
            background: rgba(15, 23, 42, 0.92);
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
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.6);
            object-fit: contain;
        }

        .lightbox-toolbar {
            margin-top: 14px;
            display: flex;
            align-items: center;
            gap: 12px;
            color: #ffffff;
            background: rgba(0, 0, 0, 0.6);
            padding: 8px 18px;
            border-radius: 30px;
            backdrop-filter: blur(8px);
        }

        .lightbox-close-btn {
            position: absolute;
            top: -40px; right: 0;
            background: transparent;
            border: none;
            color: #ffffff;
            font-size: 1.8rem;
            cursor: pointer;
            transition: transform 0.2s;
        }

        .lightbox-close-btn:hover {
            transform: scale(1.2);
            color: #ef4444;
        }

        /* 友善列印樣式 (Print Optimization) */
        @media print {
            .top-navbar, .no-print, .lightbox-modal, .stepper-container {
                display: none !important;
            }

            body {
                background: #ffffff !important;
                color: #000000 !important;
                font-size: 11pt;
                padding: 0;
                margin: 0;
            }

            .container-fluid-custom {
                width: 100% !important;
                max-width: 100% !important;
                padding: 0 !important;
            }

            .gov-card {
                box-shadow: none !important;
                border: 1px solid #000000 !important;
                page-break-inside: avoid;
                margin-bottom: 12px !important;
            }

            .gov-header {
                background: #f1f5f9 !important;
                color: #000000 !important;
                border-bottom: 1px solid #000000 !important;
            }

            .gov-label {
                background: #e2e8f0 !important;
                color: #000000 !important;
                border: 1px solid #000000 !important;
            }

            .gov-val {
                background: #ffffff !important;
                border: 1px solid #000000 !important;
            }

            #map {
                height: 250px !important;
                border: 1px solid #000000 !important;
                page-break-inside: avoid;
            }

            .comparison-body {
                flex-direction: row !important;
            }

            .photo-frame {
                height: 180px !important;
            }
        }

        /* ========================================================
           小尺寸行動端 RWD 優化 (符合 inspection-ui-standard 規範)
           ======================================================== */
        @media screen and (max-width: 767.98px) {
            body {
                padding-bottom: 76px !important;
            }

            .top-navbar {
                height: 52px !important;
                padding: 0 10px !important;
            }

            .nav-btn {
                height: 34px !important;
                padding: 0 10px !important;
                font-size: 0.85rem !important;
            }

            .top-navbar .brand-title {
                font-size: 0.95rem !important;
                gap: 6px !important;
            }

            .container-fluid-custom {
                padding: 10px 8px !important;
                overflow-x: hidden !important;
            }

            /* 階段時間軸手機版緊湊自適應 (防右側裁切) */
            .stepper-container {
                padding: 12px 6px !important;
                margin-bottom: 12px !important;
                border-radius: 10px !important;
            }

            .step-item {
                min-width: 0 !important;
                padding: 0 2px !important;
            }

            .step-circle {
                width: 28px !important;
                height: 28px !important;
                font-size: 12px !important;
                margin-bottom: 4px !important;
            }

            .stepper-line {
                top: 26px !important;
                left: 16% !important;
                right: 16% !important;
            }

            .step-title {
                font-size: 12px !important;
                white-space: nowrap !important;
                overflow: hidden !important;
                text-overflow: ellipsis !important;
                max-width: 100% !important;
            }

            .step-time {
                font-size: 10px !important;
                white-space: nowrap !important;
            }

            /* 警示與追蹤卡片手機版堆疊 */
            .alert-follow {
                padding: 12px !important;
                flex-direction: column !important;
                align-items: stretch !important;
            }

            .alert-follow .btn {
                flex: 1 !important;
                text-align: center !important;
            }

            /* 現代卡片與標頭 */
            .gov-card {
                border-radius: 12px !important;
                margin-bottom: 14px !important;
                border: 1px solid var(--border-color) !important;
            }

            .gov-header {
                font-size: 0.98rem !important;
                padding: 10px 14px !important;
            }

            /* 表格轉現代緊湊 Key-Value 雙欄列 (杜絕傳統單欄無限拉長與 inline width 破版) */
            .gov-table,
            .gov-table tbody {
                display: block !important;
                width: 100% !important;
            }

            .gov-table tr {
                display: flex !important;
                flex-wrap: wrap !important;
                width: 100% !important;
                border-bottom: none !important;
            }

            .gov-table th.gov-label {
                width: 112px !important;
                min-width: 112px !important;
                max-width: 112px !important;
                flex: 0 0 112px !important;
                padding: 10px 12px !important;
                font-size: 13px !important;
                background-color: #f8fafc !important;
                color: #334155 !important;
                border: none !important;
                border-top: 1px solid var(--border-color) !important;
                border-right: 1px solid var(--border-color) !important;
                display: flex !important;
                align-items: center !important;
                white-space: normal !important;
                line-height: 1.35 !important;
            }

            .gov-table td.gov-val,
            .gov-table td.gov-val[style] {
                width: calc(100% - 112px) !important;
                min-width: calc(100% - 112px) !important;
                max-width: calc(100% - 112px) !important;
                flex: 0 0 calc(100% - 112px) !important;
                padding: 10px 12px !important;
                font-size: 13.5px !important;
                background-color: #ffffff !important;
                border: none !important;
                border-top: 1px solid var(--border-color) !important;
                word-break: break-word !important;
                overflow-wrap: anywhere !important;
            }

            /* 針對地圖、照片與長篇說明採用上下滿版區塊呈現 */
            .gov-table tr.gov-row-stack th.gov-label {
                width: 100% !important;
                min-width: 100% !important;
                max-width: 100% !important;
                flex: 0 0 100% !important;
                border-right: none !important;
                padding: 8px 12px !important;
                background-color: #f8fafc !important;
                color: var(--brand-navy) !important;
            }

            .gov-table tr.gov-row-stack td.gov-val,
            .gov-table tr.gov-row-stack td.gov-val[style] {
                width: 100% !important;
                min-width: 100% !important;
                max-width: 100% !important;
                flex: 0 0 100% !important;
                padding: 12px !important;
            }

            #map {
                height: 240px;
            }

            .photo-mini-grid {
                grid-template-columns: repeat(2, 1fr) !important;
                gap: 8px !important;
            }

            .comparison-body {
                flex-direction: column !important;
                padding: 10px !important;
                gap: 10px !important;
            }

            .photo-frame,
            .photo-empty {
                height: 175px !important;
            }

            /* 手機端常駐底部懸浮動作列 (Sticky Bottom Bar - 符合 SKILL.md 規範) */
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
                padding: 9px 8px;
                border-radius: 8px;
                font-size: 13.5px;
                display: inline-flex;
                align-items: center;
                justify-content: center;
                min-height: 42px;
                white-space: nowrap;
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
        <div id="app" v-cloak>
            <!-- 1. 頂部品牌導覽列 -->
            <header class="top-navbar no-print">
                <div class="brand-title">
                    <button type="button" class="nav-btn" v-on:click="goBack" title="返回清單">
                        <i class="fas fa-arrow-left"></i>
                        <span class="d-none d-sm-inline">返回清單</span>
                    </button>
                    <i class="fas fa-road text-white flex-shrink-0"></i>
                    <span class="brand-title-text">道路破損通報單</span>
                    <span v-if="caseData.Show_ID" class="badge badge-light text-dark font-weight-bold ml-1 d-none d-md-inline-block" style="font-size: 0.85rem;">
                        {{ caseData.Show_ID }}
                    </span>
                </div>

                <div class="navbar-actions">
                    <!-- 路平報馬仔外部直連 -->
                    <a v-if="effectiveRdmId" :href="'https://rdm.ntpc.gov.tw/ROAD/SatisfySurvey.aspx?id=' + encodeURIComponent(effectiveRdmId)"
                       target="_blank" rel="noopener" class="nav-btn" title="開啟新北市路平報馬仔系統案件網頁">
                        <i class="fas fa-external-link-alt"></i>
                        <span class="d-none d-lg-inline">路平報馬仔 ({{ effectiveRdmId }})</span>
                    </a>

                    <!-- 列印案件按鈕 (桌面端顯示) -->
                    <button type="button" class="nav-btn d-none d-md-inline-flex" v-on:click="printReport" title="列印案件紀錄">
                        <i class="fas fa-print"></i>
                        <span class="d-none d-lg-inline">列印案件</span>
                    </button>

                    <!-- Google 導航 -->
                    <button v-if="caseData.Lat && caseData.Lng" type="button" class="nav-btn" v-on:click="openGoogleMaps" title="以 Google Maps 開啟位置導航">
                        <i class="fas fa-location-arrow"></i>
                        <span class="d-none d-lg-inline">路線導航</span>
                    </button>

                    <!-- 依案件狀態與權限動態切換核心操作按鈕 -->
                    <template v-if="numericStatusCode === 1">
                        <a v-if="userPerms.CanEdit" :href="'NewBreak.aspx?id=' + encodeURIComponent(caseData.Break_ID)" class="btn btn-warning text-dark btn-sm font-weight-bold shadow-sm d-none d-md-inline-flex align-items-center" style="min-height: 36px; padding: 0 12px; border-radius: 8px;" title="編輯案件">
                            <i class="fas fa-edit mr-1"></i> 編輯案件
                        </a>
                        <a v-if="userPerms.CanDispatch" :href="'SetSG_Break.aspx?id=' + encodeURIComponent(caseData.Break_ID)" class="btn btn-success btn-sm font-weight-bold shadow-sm d-none d-md-inline-flex align-items-center" style="min-height: 36px; padding: 0 14px; border-radius: 8px;" title="派工通報">
                            <i class="fas fa-paper-plane mr-1"></i> 派工通報
                        </a>
                    </template>
                    <template v-else-if="numericStatusCode === 2 || caseData.Need_Follow === 'Y'">
                        <a v-if="userPerms.CanImprove" :href="'ImproveBreak.aspx?id=' + encodeURIComponent(caseData.Break_ID)" class="btn btn-success btn-sm font-weight-bold shadow-sm d-none d-md-inline-flex align-items-center" style="min-height: 36px; padding: 0 14px; border-radius: 8px;" title="處理回報 / 更新結案">
                            <i class="fas fa-tools mr-1"></i> {{ caseData.Need_Follow === 'Y' ? '更新追蹤回報' : '處理回報' }}
                        </a>
                    </template>
                </div>
            </header>

            <!-- 主作業容器 -->
            <main class="container-fluid-custom">
                <!-- 載入中動畫 -->
                <div v-if="loading" class="text-center py-5">
                    <div class="spinner-border text-primary" role="status" style="width: 3rem; height: 3rem;">
                        <span class="sr-only">載入中...</span>
                    </div>
                    <div class="mt-3 font-weight-bold text-muted">讀取案件詳細資料中，請稍候...</div>
                </div>

                <!-- 錯誤警告提示 -->
                <div v-else-if="errorMessage" class="alert alert-danger shadow-sm d-flex align-items-center" role="alert">
                    <i class="fas fa-exclamation-triangle fa-2x mr-3 text-danger"></i>
                    <div>
                        <h5 class="alert-heading font-weight-bold mb-1">案件載入失敗</h5>
                        <p class="mb-0">{{ errorMessage }}</p>
                    </div>
                </div>

                <!-- 案件主要內容區 -->
                <div v-else>
                    <!-- 案件退回重辦警告卡片 (若 G_Back === 'Y') -->
                    <div v-if="caseData.G_Back === 'Y'" class="alert-gback shadow-sm">
                        <div class="font-weight-bold d-flex align-items-center gap-2">
                            <i class="fas fa-exclamation-circle fa-lg"></i>
                            <span>非處理單位權責，此案件已被退回！</span>
                        </div>
                        <div class="mt-2 pl-4" v-if="caseData.G_Memo">
                            <strong>退回備註說明：</strong> {{ caseData.G_Memo }}
                        </div>
                    </div>

                    <!-- 建議機關持續追蹤提醒卡片 (若 Need_Follow === 'Y') -->
                    <div v-if="caseData.Need_Follow === 'Y'" class="alert-follow shadow-sm">
                        <div>
                            <div class="font-weight-bold d-flex align-items-center gap-2" style="font-size: 1rem;">
                                <i class="fas fa-search-location fa-lg text-primary"></i>
                                <span>本案標記為【建議機關持續追蹤列管】</span>
                            </div>
                            <div class="mt-1 small">
                                {{ caseData.Follow_Memo || ('路平報馬仔回報：「' + (caseData.G_Memo || caseData.G_Fix_Status) + '」，尚未永久刨鋪，建議機關持續追蹤複查。') }}
                            </div>
                        </div>
                        <div class="d-flex flex-wrap align-items-center gap-2 no-print">
                            <a :href="'NewBreak.aspx?mode=new&fromId=' + encodeURIComponent(caseData.Break_ID)" class="btn btn-primary btn-sm font-weight-bold shadow-sm">
                                <i class="fas fa-plus-circle mr-1"></i> 建立後續複查通報
                            </a>
                            <a v-if="userPerms.CanImprove" :href="'ImproveBreak.aspx?id=' + encodeURIComponent(caseData.Break_ID)" class="btn btn-outline-primary btn-sm font-weight-bold bg-white">
                                <i class="fas fa-edit mr-1"></i> 更新回報為正式結案
                            </a>
                        </div>
                    </div>

                    <!-- 通報階段進度時間軸 (Status Stepper) -->
                    <div class="stepper-container shadow-sm no-print">
                        <div class="stepper-line">
                            <div class="stepper-line-fill" :style="{ width: stepperProgress + '%' }"></div>
                        </div>

                        <!-- 步驟 1: 現場查核立案 -->
                        <div class="step-item" :class="getStepClass(1)">
                            <div class="step-circle">
                                <i v-if="numericStatusCode > 1" class="fas fa-check"></i>
                                <span v-else>1</span>
                            </div>
                            <div class="step-title">現場查核立案</div>
                            <div class="step-time">{{ caseData.Report_Date || '未填寫' }}</div>
                        </div>

                        <!-- 步驟 2: 派工改善通報 -->
                        <div class="step-item" :class="getStepClass(2)">
                            <div class="step-circle">
                                <i v-if="numericStatusCode > 2" class="fas fa-check"></i>
                                <span v-else>2</span>
                            </div>
                            <div class="step-title">{{ caseData.G_Back === 'Y' ? '案件退回重派' : '派工改善通報' }}</div>
                            <div class="step-time">{{ caseData.SetCOM_Date || '待通報' }}</div>
                        </div>

                        <!-- 步驟 3: 改善完成結案 / 建議持續追蹤 -->
                        <div class="step-item" :class="getStepClass(3)">
                            <div class="step-circle">
                                <i v-if="numericStatusCode === 3" class="fas" :class="caseData.Need_Follow === 'Y' ? 'fa-search' : 'fa-check'"></i>
                                <span v-else>3</span>
                            </div>
                            <div class="step-title">{{ caseData.Need_Follow === 'Y' ? '建議持續追蹤' : '改善完成結案' }}</div>
                            <div class="step-time">{{ caseData.Improve_Date || '待改善' }}</div>
                        </div>
                    </div>

                    <!-- ========================================================
                         三大區塊一：【通報項目】
                         ======================================================== -->
                    <div class="gov-card">
                        <div class="gov-header">
                            <div class="d-flex align-items-center gap-2">
                                <i class="fas fa-file-alt text-primary"></i>
                                <span>通報項目</span>
                            </div>
                            <a v-if="effectiveRdmId" :href="'https://rdm.ntpc.gov.tw/ROAD/SatisfySurvey.aspx?id=' + encodeURIComponent(effectiveRdmId)"
                               target="_blank" rel="noopener" class="btn btn-sm btn-outline-primary font-weight-bold no-print" style="font-size: 12px; padding: 3px 8px;">
                                <i class="fas fa-external-link-alt mr-1"></i> 路平報馬仔 ({{ effectiveRdmId }})
                            </a>
                        </div>
                        <table class="gov-table">
                            <tbody>
                                <tr>
                                    <th class="gov-label">反映編號</th>
                                    <td class="gov-val gov-val-highlight" style="width: 35%;">
                                        <div class="d-flex flex-wrap align-items-center gap-1">
                                            <span>{{ effectiveRdmId || caseData.Show_ID }}</span>
                                            <span v-if="effectiveRdmId && caseData.Show_ID && effectiveRdmId !== caseData.Show_ID" class="text-muted small">
                                                (案號: {{ caseData.Show_ID }})
                                            </span>
                                            <span class="badge" :class="caseData.StatusBadgeClass">{{ caseData.StatusText }}</span>
                                        </div>
                                    </td>
                                    <th class="gov-label">反映日期</th>
                                    <td class="gov-val" style="width: 35%;">
                                        {{ caseData.Report_Date || '無紀錄' }}
                                    </td>
                                </tr>
                                <tr>
                                    <th class="gov-label">申訴類別</th>
                                    <td class="gov-val">機關查報</td>
                                    <th class="gov-label">反映方式</th>
                                    <td class="gov-val">行動查報</td>
                                </tr>
                                <tr>
                                    <th class="gov-label">反映類別</th>
                                    <td class="gov-val font-weight-bold text-dark">
                                        {{ caseData.Damage_Category || '路面損壞' }}
                                    </td>
                                    <th class="gov-label">路面損壞-性質</th>
                                    <td class="gov-val gov-val-danger">
                                        <span>{{ caseData.Damage_Type || '坑洞' }}</span>
                                        <span class="ml-2 font-weight-normal text-dark d-inline-block">
                                            長：{{ caseData.Damage_Length || '0' }}m&nbsp;&nbsp;寬：{{ caseData.Damage_Width || '0' }}m
                                        </span>
                                    </td>
                                </tr>
                                <tr>
                                    <th class="gov-label">損壞型式(PCI)</th>
                                    <td class="gov-val">{{ caseData.PCI_Type || caseData.Damage_Type || '坑洞' }}</td>
                                    <th class="gov-label">嚴重程度(PCI)</th>
                                    <td class="gov-val"><span class="badge badge-info px-2">{{ caseData.PCI_Severity || '輕' }}</span></td>
                                </tr>
                                <tr>
                                    <th class="gov-label">監造建議修補事項</th>
                                    <td class="gov-val" colspan="3">
                                        {{ caseData.Supervisor_Suggest || '尚未設定' }}
                                    </td>
                                </tr>
                                <tr class="gov-row-stack">
                                    <th class="gov-label" style="vertical-align: top;">反映地點</th>
                                    <td class="gov-val" colspan="3">
                                        <div class="mb-2">
                                            <strong>所屬區：</strong>
                                            <span class="text-dark font-weight-bold">{{ caseData.TOWN_NA || '新北市' }}</span>
                                            <span class="ml-1">{{ caseData.ROAD_Name }}</span>
                                            <span v-if="caseData.Location_Desc" class="text-secondary ml-1 font-weight-bold">({{ caseData.Location_Desc }})</span>
                                        </div>

                                        <div class="d-flex flex-wrap align-items-center justify-content-between gap-2 mb-2" style="font-size: 13px;">
                                            <div>
                                                <i class="fas fa-map-pin text-danger mr-1"></i>
                                                <strong>坐標：</strong>
                                                <span>X={{ caseData.S_UTME || caseData.Lng || '-' }}，Y={{ caseData.S_UTMN || caseData.Lat || '-' }}</span>
                                            </div>
                                            <div class="d-flex flex-wrap align-items-center gap-1 no-print">
                                                <button v-if="caseData.Lat && caseData.Lng" type="button" class="btn-streetview" v-on:click="openStreetView(caseData.Lat, caseData.Lng)">
                                                    <i class="fas fa-street-view text-warning"></i> Google街景
                                                </button>
                                                <button v-if="caseData.Lat && caseData.Lng" type="button" class="btn-streetview" v-on:click="resetMapView">
                                                    <i class="fas fa-crosshairs text-info"></i> 地圖置中
                                                </button>
                                                <button type="button" class="btn-streetview" v-on:click="toggleMapCollapse">
                                                    <i class="fas text-primary" :class="mapCollapsed ? 'fa-expand-alt' : 'fa-compress-alt'"></i>
                                                    {{ mapCollapsed ? '展開地圖' : '收合地圖' }}
                                                </button>
                                            </div>
                                        </div>

                                        <!-- 嵌入 Leaflet 國土測繪電子地圖 -->
                                        <div id="map" :class="{ 'map-collapsed': mapCollapsed }"></div>
                                    </td>
                                </tr>
                                <tr>
                                    <th class="gov-label">車道</th>
                                    <td class="gov-val" style="width: 35%;">
                                        {{ caseData.Lane_Info || '全車道' }}
                                    </td>
                                    <th class="gov-label">方向</th>
                                    <td class="gov-val" style="width: 35%;">
                                        {{ caseData.Direction || '無法判定' }}
                                    </td>
                                </tr>
                                <tr>
                                    <th class="gov-label">道路型態</th>
                                    <td class="gov-val">
                                        {{ caseData.Road_Type || '平面' }}
                                    </td>
                                    <th class="gov-label">處理單位(公所)</th>
                                    <td class="gov-val">
                                        {{ caseData.District_Office || (caseData.TOWN_NA ? caseData.TOWN_NA + '公所' : '-') }}
                                    </td>
                                </tr>
                                <tr>
                                    <th class="gov-label">處理單位</th>
                                    <td class="gov-val">
                                        {{ caseData.Handle_Unit || caseData.G_COM_NAME || '-' }}
                                    </td>
                                    <th class="gov-label">處理狀態</th>
                                    <td class="gov-val">
                                        {{ caseData.Handle_Status || caseData.StatusText || '機關自行修補' }}
                                    </td>
                                </tr>
                                <tr>
                                    <th class="gov-label">其他說明</th>
                                    <td class="gov-val" colspan="3" style="white-space: pre-wrap;">{{ caseData.Memo || '無其他說明' }}</td>
                                </tr>
                                <tr>
                                    <th class="gov-label">養工處分派說明</th>
                                    <td class="gov-val" colspan="3" style="white-space: pre-wrap;">{{ caseData.Dispatch_Memo || '無額外分派說明' }}</td>
                                </tr>
                                <tr class="gov-row-stack">
                                    <th class="gov-label" style="vertical-align: top;">現場照片</th>
                                    <td class="gov-val" colspan="3">
                                        <div v-if="beforePhotos.length > 0">
                                            <!-- 文字連結清單 -->
                                            <div class="d-flex flex-wrap align-items-center gap-3 mb-2">
                                                <a v-for="(p, idx) in beforePhotos" :key="'link-' + idx" href="javascript:void(0)" class="text-primary font-weight-bold" style="text-decoration: underline;" v-on:click="openLightbox(p.Url, p.Title, p.FileName, p.Size, p.Time)">
                                                    {{ p.Title || ('照片 ' + (idx + 1)) }}
                                                </a>
                                            </div>
                                            <!-- 縮圖預覽卡片 -->
                                            <div class="photo-mini-grid">
                                                <div v-for="(p, idx) in beforePhotos" :key="'mini-' + idx" class="photo-mini-card" v-on:click="openLightbox(p.Url, p.Title, p.FileName, p.Size, p.Time)">
                                                    <img :src="p.Url" :alt="p.FileName" loading="lazy" />
                                                    <div class="photo-mini-caption">{{ p.Title || ('照片 ' + (idx + 1)) }}</div>
                                                </div>
                                            </div>
                                        </div>
                                        <div v-else class="text-muted small">
                                            <i class="fas fa-camera-retro mr-1"></i>尚未上傳現場照片
                                        </div>
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>

                    <!-- ========================================================
                         三大區塊二：【處理回報】
                         ======================================================== -->
                    <div class="gov-card">
                        <div class="gov-header">
                            <div class="d-flex align-items-center gap-2">
                                <i class="fas fa-tools text-primary"></i>
                                <span>處理回報</span>
                            </div>
                        </div>
                        <table class="gov-table">
                            <tbody>
                                <tr>
                                    <th class="gov-label">完工日期(派工)</th>
                                    <td class="gov-val" style="width: 35%;">
                                        {{ caseData.Dispatch_Done_Date || '無派工' }}
                                    </td>
                                    <th class="gov-label">完工回報(派工)</th>
                                    <td class="gov-val" style="width: 35%;">
                                        {{ caseData.Dispatch_Report_Date || '無派工' }}
                                    </td>
                                </tr>
                                <tr>
                                    <th class="gov-label">完工日期</th>
                                    <td class="gov-val" style="width: 35%;">
                                        <span v-if="caseData.Improve_Date" class="text-success font-weight-bold">{{ caseData.Improve_Date }}</span>
                                        <span v-else class="text-muted">待改善完工</span>
                                    </td>
                                    <th class="gov-label">完工回報日期</th>
                                    <td class="gov-val" style="width: 35%;">
                                        <span v-if="caseData.G_Report_Date || caseData.Improve_Date" class="text-success font-weight-bold">
                                            {{ caseData.G_Report_Date || caseData.Improve_Date }}
                                        </span>
                                        <span v-else class="text-muted">待回報</span>
                                    </td>
                                </tr>
                                <tr>
                                    <th class="gov-label">路面損壞-性質</th>
                                    <td class="gov-val" colspan="3">
                                        {{ caseData.Damage_Type || '路面損壞' }}
                                        <span class="ml-1 d-inline-block">長：{{ caseData.Damage_Length || '0' }}m&nbsp;&nbsp;寬：{{ caseData.Damage_Width || '0' }}m&nbsp;&nbsp;共{{ caseData.Damage_Count || '1' }}處</span>
                                    </td>
                                </tr>
                                <tr>
                                    <th class="gov-label">後續修復情形</th>
                                    <td class="gov-val gov-val-highlight" colspan="3" style="white-space: pre-wrap;">{{ caseData.G_Fix_Status || caseData.G_Memo || '尚未回報修復情形' }}</td>
                                </tr>
                                <tr>
                                    <th class="gov-label">所屬道路</th>
                                    <td class="gov-val" colspan="3">
                                        {{ caseData.ROAD_Name }}
                                    </td>
                                </tr>
                                <tr>
                                    <th class="gov-label">承辦人</th>
                                    <td class="gov-val" style="width: 35%;">
                                        {{ caseData.G_UserName || caseData.G_USER || '-' }}
                                    </td>
                                    <th class="gov-label">聯絡電話</th>
                                    <td class="gov-val" style="width: 35%;">
                                        {{ caseData.G_Contact_Phone || '-' }}
                                    </td>
                                </tr>
                                <tr>
                                    <th class="gov-label">處理說明</th>
                                    <td class="gov-val" colspan="3" style="white-space: pre-wrap;">{{ caseData.G_Memo || caseData.G_Fix_Status || '尚未填寫處理說明' }}</td>
                                </tr>
                                <tr class="gov-row-stack">
                                    <th class="gov-label" style="vertical-align: top;">完工照片</th>
                                    <td class="gov-val" colspan="3">
                                        <div v-if="afterPhotos.length > 0">
                                            <div class="photo-chip-list mb-2">
                                                <button v-for="(p, idx) in afterPhotos" :key="'after-chip-' + idx" type="button" class="photo-badge-btn" v-on:click="openLightbox(p.Url, p.Title, p.FileName, p.Size, p.Time)">
                                                    <i class="fas fa-check-circle text-success"></i> 照片{{ idx + 1 }}
                                                </button>
                                            </div>
                                            <div class="photo-mini-grid">
                                                <div v-for="(p, idx) in afterPhotos" :key="'after-mini-' + idx" class="photo-mini-card" v-on:click="openLightbox(p.Url, p.Title, p.FileName, p.Size, p.Time)">
                                                    <img :src="p.Url" :alt="p.FileName" loading="lazy" />
                                                    <div class="photo-mini-caption text-success font-weight-bold">完工照片 {{ idx + 1 }}</div>
                                                </div>
                                            </div>
                                        </div>
                                        <div v-else class="text-muted small">
                                            <i class="fas fa-tools mr-1"></i>尚未上傳完工改善照片
                                        </div>
                                    </td>
                                </tr>
                                <tr>
                                    <th class="gov-label">延遲原因</th>
                                    <td class="gov-val" colspan="3">
                                        <span v-if="caseData.G_Delay_Reason" class="text-danger font-weight-bold">{{ caseData.G_Delay_Reason }}</span>
                                        <span v-else class="text-muted">無延遲</span>
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>

                    <!-- ========================================================
                         三大區塊三：【結案回覆】 (嚴格無滿意度調查)
                         ======================================================== -->
                    <div class="gov-card">
                        <div class="gov-header">
                            <div class="d-flex align-items-center gap-2">
                                <i class="fas fa-check-circle text-success"></i>
                                <span>結案回覆</span>
                            </div>
                        </div>
                        <table class="gov-table">
                            <tbody>
                                <tr>
                                    <th class="gov-label">回覆時間</th>
                                    <td class="gov-val" style="width: 35%;">
                                        {{ caseData.G_Reply_Date || caseData.Improve_Date || '尚未回覆' }}
                                    </td>
                                    <th class="gov-label">回覆方式</th>
                                    <td class="gov-val" style="width: 35%;">
                                        {{ caseData.G_Reply_Type || '-' }}
                                    </td>
                                </tr>
                                <tr class="gov-row-stack">
                                    <th class="gov-label" style="vertical-align: top;">回覆說明</th>
                                    <td class="gov-val" colspan="3" style="line-height: 1.75; font-size: 14px; white-space: pre-wrap;">{{ caseData.G_Reply_Memo || '尚未填寫結案回覆說明' }}</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>

                    <!-- ========================================================
                         稽查成果專用：【現場佐證照片 vs 改善後成果對比區】
                         ======================================================== -->
                    <div class="gov-card no-print" v-if="photos.length > 0">
                        <div class="gov-header">
                            <div class="d-flex align-items-center gap-2">
                                <i class="fas fa-images text-primary"></i>
                                <span>現場成果照片檢視與前後對比</span>
                            </div>
                            <span class="badge badge-pill badge-primary">共 {{ photos.length }} 組點位</span>
                        </div>
                        <div class="p-2 p-md-3">
                            <div v-for="item in photos" :key="item.Index" class="comparison-card">
                                <div class="comparison-header">
                                    <span>
                                        <i class="fas fa-map-pin text-danger mr-1"></i>
                                        {{ item.Title }}
                                    </span>
                                    <div class="d-flex align-items-center gap-2">
                                        <span v-if="item.AfterExists" class="badge badge-success">
                                            <i class="fas fa-check mr-1"></i>已完成改善
                                        </span>
                                        <span v-else class="badge badge-warning text-dark">
                                            <i class="fas fa-hourglass-half mr-1"></i>待改善上傳
                                        </span>
                                    </div>
                                </div>

                                <div class="comparison-body">
                                    <!-- 佐證照片 (Before) -->
                                    <div class="photo-pane">
                                        <div class="photo-tag photo-tag-before">
                                            <i class="fas fa-history"></i>
                                            <span>{{ item.BeforeTitle || '現場佐證照片' }}</span>
                                        </div>

                                        <div v-if="item.BeforeExists" class="photo-frame" v-on:click="openLightbox(item.BeforeUrl, item.BeforeTitle || '現場佐證照片', item.BeforeFileName, item.BeforeSize, item.BeforeTime)">
                                            <img :src="item.BeforeUrl" :alt="item.BeforeFileName" loading="lazy" />
                                            <div class="photo-overlay">
                                                <span><i class="fas fa-search-plus mr-1"></i>點擊放大</span>
                                                <span>{{ formatFileSize(item.BeforeSize) }}</span>
                                            </div>
                                        </div>
                                        <div v-else class="photo-empty">
                                            <i class="fas fa-image"></i>
                                            <span>未提供佐證照片</span>
                                        </div>
                                    </div>

                                    <!-- 改善後照片 (After) -->
                                    <div class="photo-pane">
                                        <div class="photo-tag photo-tag-after">
                                            <i class="fas fa-check-circle"></i>
                                            <span>{{ item.AfterTitle || '改善後成果照片' }}</span>
                                        </div>

                                        <div v-if="item.AfterExists" class="photo-frame" v-on:click="openLightbox(item.AfterUrl, item.AfterTitle || '改善後成果照片', item.AfterFileName, item.AfterSize, item.AfterTime)">
                                            <img :src="item.AfterUrl" :alt="item.AfterFileName" loading="lazy" />
                                            <div class="photo-overlay">
                                                <span><i class="fas fa-search-plus mr-1"></i>點擊放大</span>
                                                <span>{{ formatFileSize(item.AfterSize) }}</span>
                                            </div>
                                        </div>
                                        <div v-else class="photo-empty">
                                            <i class="fas fa-tools"></i>
                                            <span class="font-weight-bold">尚未上傳改善成果</span>
                                            <small class="mt-1 text-muted">權責單位完成修復後將於此呈現</small>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                </div>
            </main>

            <!-- 手機端常駐底部懸浮動作列 (遵循專案 SKILL 規範) -->
            <nav v-if="!loading && !errorMessage" class="mobile-bottom-bar no-print">
                <button type="button" class="btn btn-secondary" v-on:click="goBack">
                    <i class="fas fa-arrow-left mr-1"></i> 返回清單
                </button>
                <a v-if="effectiveRdmId" :href="'https://rdm.ntpc.gov.tw/ROAD/SatisfySurvey.aspx?id=' + encodeURIComponent(effectiveRdmId)"
                   target="_blank" rel="noopener" class="btn btn-outline-primary">
                    <i class="fas fa-external-link-alt mr-1"></i> 路平網頁
                </a>
                <template v-if="numericStatusCode === 1">
                    <a v-if="userPerms.CanEdit" :href="'NewBreak.aspx?id=' + encodeURIComponent(caseData.Break_ID)" class="btn btn-warning text-dark">
                        <i class="fas fa-edit mr-1"></i> 編輯
                    </a>
                    <a v-if="userPerms.CanDispatch" :href="'SetSG_Break.aspx?id=' + encodeURIComponent(caseData.Break_ID)" class="btn btn-success">
                        <i class="fas fa-paper-plane mr-1"></i> 派工通報
                    </a>
                </template>
                <template v-else-if="numericStatusCode === 2 || caseData.Need_Follow === 'Y'">
                    <a v-if="userPerms.CanImprove" :href="'ImproveBreak.aspx?id=' + encodeURIComponent(caseData.Break_ID)" class="btn btn-success">
                        <i class="fas fa-tools mr-1"></i> {{ caseData.Need_Follow === 'Y' ? '更新追蹤' : '處理回報' }}
                    </a>
                </template>
            </nav>

            <!-- 照片放大燈箱 (Lightbox Modal) -->
            <div v-if="lightbox.show" class="lightbox-modal no-print" v-on:click.self="closeLightbox">
                <div class="lightbox-content">
                    <button type="button" class="lightbox-close-btn" v-on:click="closeLightbox" title="關閉燈箱">
                        <i class="fas fa-times"></i>
                    </button>
                    <img :src="lightbox.url" :alt="lightbox.title" class="lightbox-img" />
                    <div class="lightbox-toolbar">
                        <span><i class="fas fa-file-image mr-1"></i>{{ lightbox.title }}</span>
                        <span v-if="lightbox.fileSize">({{ formatFileSize(lightbox.fileSize) }})</span>
                        <a :href="lightbox.url" target="_blank" class="btn btn-sm btn-outline-light py-0 px-2 ml-2">
                            <i class="fas fa-external-link-alt mr-1"></i>原圖另開
                        </a>
                    </div>
                </div>
            </div>
        </div>
    </form>

    <!-- 本地化核心腳本庫 -->
    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>
    <script src="../Scripts/leaflet/leaflet.js"></script>

    <script>
        const { createApp, markRaw } = Vue;

        createApp({
            data() {
                return {
                    breakId: '',
                    parMode: '',
                    caseData: {},
                    photos: [],
                    beforePhotos: [],
                    afterPhotos: [],
                    userPerms: {},
                    loading: true,
                    errorMessage: '',
                    leafletMap: null,
                    marker: null,
                    mapCollapsed: false,
                    lightbox: {
                        show: false,
                        url: '',
                        title: '',
                        fileName: '',
                        fileSize: 0,
                        time: ''
                    }
                };
            },

            computed: {
                effectiveRdmId() {
                    if (!this.caseData) return '';
                    if (this.caseData.RDM_Case_ID) return this.caseData.RDM_Case_ID;
                    if (this.caseData.Show_ID && /^\d{6,10}$/.test(this.caseData.Show_ID)) {
                        return this.caseData.Show_ID;
                    }
                    return '';
                },

                numericStatusCode() {
                    if (!this.caseData) return 1;
                    if (this.caseData.Improve_Date) return 3;
                    if (this.caseData.SetCOM_Date) return 2;
                    return 1;
                },

                stepperProgress() {
                    const code = this.numericStatusCode;
                    if (code === 1) return 0;
                    if (code === 2) return 50;
                    if (code === 3) return 100;
                    return 0;
                }
            },

            mounted() {
                const params = new URLSearchParams(window.location.search);
                this.breakId = params.get('id') || '';
                this.parMode = params.get('mode') || '';

                if (!this.breakId) {
                    this.loading = false;
                    this.errorMessage = '未指定案件編號參數 (id)。';
                    return;
                }

                this.loadCaseDetail();
            },

            methods: {
                // 讀取案件詳細資訊
                loadCaseDetail() {
                    this.loading = true;
                    this.errorMessage = '';

                    axios.get('BreakDetail.aspx', {
                        params: {
                            action: 'getcasedetail',
                            id: this.breakId,
                            _t: new Date().getTime()
                        }
                    })
                    .then(res => {
                        const data = res.data;
                        if (data.NeedLogin) {
                            alert('登入已逾時，將返回登入頁');
                            window.location.href = '../Default.aspx';
                            return;
                        }
                        if (data.Success) {
                            this.caseData = data.Case;
                            this.photos = data.Photos || [];
                            this.beforePhotos = data.BeforePhotos || [];
                            this.afterPhotos = data.AfterPhotos || [];
                            this.userPerms = data.UserPerms || {};
                            this.loading = false;

                            // 初始化地圖 (DOM 渲染後)
                            this.$nextTick(() => {
                                this.initMap();
                            });
                        } else {
                            this.loading = false;
                            this.errorMessage = data.Message || '讀取資料失敗';
                        }
                    })
                    .catch(err => {
                        this.loading = false;
                        this.errorMessage = '伺服器網路連線異常，請稍候再試。';
                        console.error('API Error:', err);
                    });
                },

                // 初始化 Leaflet 地圖 (物件隔離，杜絕 proxy 造成 project 報錯)
                initMap() {
                    const mapEl = document.getElementById('map');
                    if (!mapEl) return;

                    let lat = parseFloat(this.caseData.Lat);
                    let lng = parseFloat(this.caseData.Lng);

                    // 若無有效坐標，預設新北市府坐標
                    const hasValidCoords = (!isNaN(lat) && !isNaN(lng) && lat > 0 && lng > 0);
                    if (!hasValidCoords) {
                        lat = 25.0123;
                        lng = 121.4657;
                    }

                    try {
                        const mapInstance = L.map('map', {
                            center: [lat, lng],
                            zoom: hasValidCoords ? 17 : 12,
                            zoomControl: true
                        });

                        // 臺灣通用電子地圖底圖
                        const emapLayer = L.tileLayer('https://wmts.nlsc.gov.tw/wmts/EMAP/default/GoogleMapsCompatible/{z}/{y}/{x}', {
                            maxZoom: 19,
                            attribution: '© 國土測繪圖資服務雲'
                        });

                        // 衛星影像底圖
                        const photoLayer = L.tileLayer('https://wmts.nlsc.gov.tw/wmts/PHOTO2/default/GoogleMapsCompatible/{z}/{y}/{x}', {
                            maxZoom: 19,
                            attribution: '© 國土測繪圖資服務雲'
                        });

                        emapLayer.addTo(mapInstance);

                        // 圖層控制器
                        const baseMaps = {
                            "臺灣通用電子地圖": emapLayer,
                            "正射影像圖 (空拍)": photoLayer
                        };
                        L.control.layers(baseMaps, null, { position: 'topright' }).addTo(mapInstance);

                        // 標記 Pin
                        if (hasValidCoords) {
                            const customIcon = L.divIcon({
                                className: 'custom-map-marker',
                                html: '<div class="marker-pin"><i class="fas fa-exclamation"></i></div>',
                                iconSize: [34, 34],
                                iconAnchor: [17, 34]
                            });

                            const popupHtml = `
                                <div style="min-width: 180px; font-size: 13px;">
                                    <div style="font-weight: 700; color: #0284c7; margin-bottom: 4px;">${this.caseData.Show_ID}</div>
                                    <div><strong>路名：</strong>${this.caseData.ROAD_Name || '未填'}</div>
                                    <div><strong>行政區：</strong>${this.caseData.TOWN_NA || '未填'}</div>
                                    <div><strong>性質：</strong>${this.caseData.Damage_Type || '坑洞'}</div>
                                </div>
                            `;

                            this.marker = markRaw(L.marker([lat, lng], { icon: customIcon }).addTo(mapInstance).bindPopup(popupHtml));
                        }

                        this.leafletMap = markRaw(mapInstance);
                    } catch (e) {
                        console.error('Leaflet Init Error:', e);
                    }
                },

                // 重設地圖置中
                resetMapView() {
                    if (this.leafletMap && this.caseData.Lat && this.caseData.Lng) {
                        this.leafletMap.setView([this.caseData.Lat, this.caseData.Lng], 17, { animate: true });
                        if (this.marker) {
                            this.marker.openPopup();
                        }
                    }
                },

                // 收合 / 展開地圖
                toggleMapCollapse() {
                    this.mapCollapsed = !this.mapCollapsed;
                    setTimeout(() => {
                        if (this.leafletMap) {
                            this.leafletMap.invalidateSize();
                        }
                    }, 260);
                },

                // 開啟 Google 街景
                openStreetView(lat, lng) {
                    if (!lat || !lng) return;
                    const url = 'https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=' + lat + ',' + lng;
                    window.open(url, '_blank');
                },

                // 開啟 Google 地圖路線規劃導航
                openGoogleMaps() {
                    if (this.caseData.Lat && this.caseData.Lng) {
                        const url = 'https://www.google.com/maps/dir/?api=1&destination=' + this.caseData.Lat + ',' + this.caseData.Lng;
                        window.open(url, '_blank');
                    }
                },

                // 步驟進度樣式
                getStepClass(step) {
                    const code = this.numericStatusCode;
                    if (code > step) return 'completed';
                    if (code === step) return 'active';
                    return '';
                },

                // 開啟燈箱放大檢視
                openLightbox(url, title, fileName, fileSize, time) {
                    this.lightbox = {
                        show: true,
                        url: url,
                        title: title || '現場照片',
                        fileName: fileName || '',
                        fileSize: fileSize || 0,
                        time: time || ''
                    };
                },

                // 關閉燈箱
                closeLightbox() {
                    this.lightbox.show = false;
                },

                // 友善列印
                printReport() {
                    window.print();
                },

                // 返回上一頁
                goBack() {
                    if (this.parMode) {
                        window.location.href = 'Break_List.aspx?mode=' + this.parMode;
                    } else if (document.referrer && document.referrer.indexOf('Break_List') !== -1) {
                        window.location.href = document.referrer;
                    } else {
                        window.location.href = 'Break_List.aspx';
                    }
                },

                // 格式化檔案大小
                formatFileSize(bytes) {
                    if (!bytes || bytes <= 0) return '0 B';
                    const k = 1024;
                    const sizes = ['B', 'KB', 'MB', 'GB'];
                    const i = Math.floor(Math.log(bytes) / Math.log(k));
                    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
                }
            }
        }).mount('#app');
    </script>
</body>
</html>
