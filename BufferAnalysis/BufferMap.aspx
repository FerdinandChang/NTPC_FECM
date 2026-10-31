<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="BufferMap.aspx.cs" Inherits="NTPC_FEC.BufferAnalysis.BufferMap" %>

<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定逸散源管理平台 - 環域空間分析與 360 環景導覽</title>

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
            --accent-gold: #f59e0b;       /* 360環景金黃 */
        }

        * { box-sizing: border-box; -webkit-tap-highlight-color: transparent; }
        html, body { height: 100%; width: 100%; margin: 0; padding: 0; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, "Noto Sans TC", "微軟正黑體", sans-serif;
            background-color: var(--bg-canvas);
            color: var(--text-main);
            overflow: hidden;
        }
        [v-cloak] { display: none !important; }

        /* 頂部導覽列 (遵照 inspection-ui-standard 規範：返回在左上角，清爽無雜訊) */
        .top-navbar {
            background: linear-gradient(135deg, #0099e5 0%, #0284c7 100%);
            color: #ffffff;
            height: 56px;
            display: flex; align-items: center; justify-content: space-between;
            padding: 0 14px;
            box-shadow: 0 2px 10px rgba(0, 153, 229, 0.25);
            position: relative; z-index: 1020;
        }
        .top-navbar .brand-title {
            font-size: 1.05rem; font-weight: 700; letter-spacing: 0.3px; margin: 0;
            display: flex; align-items: center; color: #ffffff;
            min-width: 0;
        }
        .nav-btn {
            display: inline-flex; align-items: center; justify-content: center;
            height: 34px; padding: 0 12px; border-radius: 8px;
            background: rgba(255, 255, 255, 0.2); color: #ffffff !important;
            font-size: 0.85rem; font-weight: 600; text-decoration: none !important;
            border: 1px solid rgba(255, 255, 255, 0.35); transition: all 0.2s ease;
            white-space: nowrap; cursor: pointer; flex: none;
        }
        .nav-btn:hover { background: rgba(255, 255, 255, 0.3); transform: translateY(-1px); }

        .nav-tool-btn {
            display: inline-flex; align-items: center; justify-content: center;
            height: 34px; padding: 0 10px; border-radius: 8px;
            font-size: 0.82rem; font-weight: 600; white-space: nowrap;
            transition: all 0.2s ease; cursor: pointer; flex: none;
        }

        /* 主體佈局 (雙欄黃金聯動) */
        .app-layout {
            display: flex;
            height: calc(100vh - 56px);
            width: 100vw;
            overflow: hidden;
            position: relative;
        }
        .side-panel {
            width: 440px;
            flex: none;
            background: var(--bg-canvas);
            border-right: 1px solid var(--border-color);
            overflow-y: hidden;
            padding: 12px;
            z-index: 20;
            display: flex;
            flex-direction: column;
            gap: 12px;
            height: 100%;
        }
        @media (max-width: 767.98px) {
            .side-panel {
                overflow-y: auto !important;
            }
        }
        .map-wrapper {
            flex: 1;
            position: relative;
            min-width: 0;
            height: 100%;
        }
        #map {
            width: 100%;
            height: 100%;
            z-index: 10;
        }

        /* 消除 Leaflet 自訂圖標白邊 */
        .leaflet-div-icon {
            background: transparent !important;
            border: none !important;
        }

        /* 中心定位大圖標與波紋動畫 */
        .center-marker-wrapper {
            position: relative;
            width: 36px;
            height: 48px;
            display: flex;
            justify-content: center;
            align-items: flex-end;
        }
        .center-pin-head {
            font-size: 40px;
            color: #ef4444;
            filter: drop-shadow(0 4px 6px rgba(0,0,0,0.45));
            line-height: 1;
            position: relative;
            z-index: 10;
            transform-origin: 50% 100%;
            animation: markerDrop 0.35s cubic-bezier(0.175, 0.885, 0.32, 1.275);
        }
        .center-ripple {
            position: absolute;
            bottom: -2px;
            left: 50%;
            transform: translateX(-50%);
            width: 16px;
            height: 16px;
            border-radius: 50%;
            background: rgba(239, 68, 68, 0.5);
            box-shadow: 0 0 10px rgba(239, 68, 68, 0.8);
            animation: rippleWave 1.8s infinite ease-out;
            z-index: 5;
        }
        @keyframes markerDrop {
            0% { transform: translateY(-30px) scale(0.5); opacity: 0; }
            100% { transform: translateY(0) scale(1); opacity: 1; }
        }
        @keyframes rippleWave {
            0% { transform: translateX(-50%) scale(0.5); opacity: 1; }
            100% { transform: translateX(-50%) scale(3.5); opacity: 0; }
        }

        /* 現代卡片 */
        .card-modern {
            background: var(--surface);
            border-radius: 12px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05), 0 4px 12px rgba(15, 23, 42, 0.05);
            border: 1px solid var(--border-color);
            overflow: hidden;
            flex: none;
        }
        .card-modern-header {
            padding: 10px 14px;
            border-bottom: 1px solid var(--border-color);
            display: flex; align-items: center; justify-content: space-between;
            background: #ffffff;
        }
        .card-modern-title {
            font-size: .95rem; font-weight: 700; color: var(--brand-navy); margin: 0;
            display: flex; align-items: center; gap: 8px;
        }
        .card-modern-body {
            padding: 12px 14px;
        }

        /* 半徑快速晶片與標籤 */
        .chip-group {
            display: flex; gap: 6px; flex-wrap: wrap; margin-top: 8px;
        }
        .chip-btn {
            border: 1px solid var(--border-color);
            background: #ffffff;
            color: var(--text-main);
            padding: 4px 10px;
            border-radius: 20px;
            font-size: 0.8rem;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.15s ease;
        }
        .chip-btn:hover {
            border-color: var(--brand-blue);
            color: var(--brand-blue);
        }
        .chip-btn.active {
            background: var(--brand-blue);
            border-color: var(--brand-blue);
            color: #ffffff;
        }

        /* 統計指標卡片 */
        .stat-grid {
            display: grid;
            grid-template-columns: repeat(5, 1fr);
            gap: 5px;
        }
        .stat-chip {
            background: #f8fafc;
            border: 1px solid var(--border-color);
            border-radius: 8px;
            padding: 6px 2px;
            text-align: center;
            transition: all 0.15s ease;
        }
        .stat-chip.clickable:hover {
            transform: translateY(-1px);
            box-shadow: 0 2px 6px rgba(0,0,0,0.08);
        }
        .stat-chip .stat-val {
            font-size: 1.05rem; font-weight: 700; line-height: 1.2;
        }
        .stat-chip .stat-lbl {
            font-size: 0.68rem; color: var(--text-muted); margin-top: 2px; white-space: nowrap;
        }

        /* 重點工廠與學校敏感度樣式 */
        .result-item.priority-high {
            border-left: 4px solid #dc2626;
        }
        .result-item.priority-medium {
            border-left: 4px solid #ea580c;
        }
        .result-item.school-card {
            border-left: 4px solid #7c3aed;
            background: #fdfcff;
        }
        .badge-school-high {
            background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);
            color: #ffffff;
            font-size: 0.7rem;
            padding: 2px 7px;
            border-radius: 10px;
            font-weight: 700;
            display: inline-flex;
            align-items: center;
            gap: 3px;
            cursor: pointer;
            box-shadow: 0 1px 4px rgba(220, 38, 38, 0.35);
        }
        .badge-school-medium {
            background: linear-gradient(135deg, #f97316 0%, #ea580c 100%);
            color: #ffffff;
            font-size: 0.7rem;
            padding: 2px 7px;
            border-radius: 10px;
            font-weight: 700;
            display: inline-flex;
            align-items: center;
            gap: 3px;
            cursor: pointer;
            box-shadow: 0 1px 4px rgba(234, 88, 12, 0.3);
        }
        .badge-school-normal {
            background: #f1f5f9;
            color: #475569;
            border: 1px solid #cbd5e1;
            font-size: 0.7rem;
            padding: 2px 7px;
            border-radius: 10px;
            font-weight: 600;
            display: inline-flex;
            align-items: center;
            gap: 3px;
            cursor: pointer;
        }
        .badge-school-normal:hover {
            background: #e2e8f0;
            color: #0f172a;
        }
        .school-dist-tooltip {
            background: rgba(15, 23, 42, 0.92) !important;
            color: #ffffff !important;
            border: 1px solid #f97316 !important;
            border-radius: 12px !important;
            padding: 3px 9px !important;
            font-size: 11px !important;
            font-weight: 700 !important;
            box-shadow: 0 3px 10px rgba(0,0,0,0.3) !important;
        }

        /* 環域結果主卡片容器 (彈性撐滿剩餘高度，內部滾動) */
        .result-card-container {
            flex: 1;
            display: flex;
            flex-direction: column;
            min-height: 0;
            background: var(--surface);
            border-radius: 12px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05), 0 4px 12px rgba(15, 23, 42, 0.05);
            border: 1px solid var(--border-color);
            overflow: hidden;
        }
        .result-card-header {
            padding: 10px 14px;
            border-bottom: 1px solid var(--border-color);
            display: flex; align-items: center; justify-content: space-between;
            background: #ffffff;
            flex: none;
        }
        .result-card-body {
            flex: 1;
            overflow-y: auto;
            padding: 10px 12px;
            min-height: 0;
        }

        /* 行業別手風琴分組樣式 (經典翠綠與科技漸層) */
        .industry-group-item {
            border-radius: 8px;
            overflow: hidden;
            border: 1px solid var(--border-color);
            background: #ffffff;
            margin-bottom: 8px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.04);
            transition: all 0.2s ease;
        }
        .industry-bar-header {
            background: linear-gradient(135deg, #10b981 0%, #059669 100%);
            color: #ffffff;
            padding: 8px 12px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            cursor: pointer;
            user-select: none;
            transition: all 0.15s ease;
        }
        .industry-bar-header:hover {
            filter: brightness(1.06);
        }
        .industry-bar-header.focused {
            background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
            box-shadow: inset 0 0 0 1px rgba(255,255,255,0.4);
        }
        .industry-bar-title {
            font-size: 0.85rem;
            font-weight: 700;
            display: flex;
            align-items: center;
            gap: 6px;
            letter-spacing: 0.3px;
            min-width: 0;
        }
        .industry-group-body {
            padding: 8px;
            background: #f8fafc;
            display: flex;
            flex-direction: column;
            gap: 6px;
            border-top: 1px solid var(--border-color);
        }
        .chevron-icon {
            transition: transform 0.2s ease;
            font-size: 0.75rem;
        }
        .chevron-icon.rotate-90 {
            transform: rotate(90deg);
        }

        /* 場所清單項目 */
        .result-list {
            display: flex; flex-direction: column; gap: 8px;
            padding-right: 2px;
        }
        .result-item {
            background: #ffffff;
            border: 1px solid var(--border-color);
            border-radius: 8px;
            padding: 10px 12px;
            cursor: pointer;
            transition: all 0.15s ease;
        }
        .result-item:hover {
            border-color: var(--brand-blue);
            box-shadow: 0 2px 8px rgba(2, 132, 199, 0.15);
            transform: translateX(2px);
        }
        .result-item.selected {
            border-color: var(--brand-blue);
            background: #f0f9ff;
        }
        .result-item-header {
            display: flex; align-items: center; justify-content: space-between;
            margin-bottom: 3px;
        }
        .result-item-title {
            font-weight: 700; font-size: 0.9rem; color: var(--brand-navy);
            white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
            max-width: 270px;
        }
        .result-item-dist {
            font-size: 0.78rem; font-weight: 700; color: var(--brand-blue);
            white-space: nowrap;
        }
        .result-item-addr {
            font-size: 0.78rem; color: var(--text-muted);
            white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
        }

        /* 360 環景樣式 */
        .pano-town-pills {
            display: flex; gap: 5px; overflow-x: auto; padding-bottom: 4px;
            scrollbar-width: thin;
        }
        .pano-town-pills::-webkit-scrollbar { height: 4px; }
        .pano-town-pills::-webkit-scrollbar-thumb { background: #cbd5e1; border-radius: 4px; }
        .town-pill {
            flex: none;
            font-size: 0.72rem;
            padding: 3px 9px;
            border-radius: 14px;
            background: #f1f5f9;
            color: #475569;
            border: 1px solid #e2e8f0;
            cursor: pointer;
            font-weight: 600;
            transition: all 0.15s ease;
        }
        .town-pill:hover {
            background: #e2e8f0; color: #0f172a;
        }
        .town-pill.active {
            background: #f59e0b; color: #ffffff; border-color: #d97706;
        }

        .pano-vertical-list {
            display: flex; flex-direction: column; gap: 8px;
        }
        .pano-card-item {
            background: #fffbeb;
            border: 1px solid #fde68a;
            border-radius: 8px;
            padding: 9px 12px;
            transition: all 0.15s ease;
        }
        .pano-card-item:hover {
            border-color: #f59e0b;
            box-shadow: 0 2px 8px rgba(245, 158, 11, 0.2);
        }
        .pano-card-title {
            font-size: 0.88rem; font-weight: 700; color: #92400e;
        }

        .badge-pano {
            background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
            color: #ffffff;
            font-size: 0.72rem;
            padding: 3px 8px;
            border-radius: 12px;
            display: inline-flex; align-items: center; gap: 4px;
            font-weight: 600;
        }

        /* 全覽圖庫 Modal 網格卡片 */
        .gallery-card {
            background: #ffffff;
            border: 1px solid #e2e8f0;
            border-radius: 10px;
            padding: 12px;
            height: 100%;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            transition: all 0.2s ease;
        }
        .gallery-card:hover {
            border-color: #f59e0b;
            box-shadow: 0 4px 12px rgba(245, 158, 11, 0.18);
            transform: translateY(-2px);
        }
        .gallery-card-title {
            font-size: 0.92rem; font-weight: 700; color: #0f172a;
            margin-bottom: 4px; line-height: 1.35;
        }
        .gallery-card-addr {
            font-size: 0.75rem; color: #64748b;
        }

        /* 地圖右上狀態小膠囊 (向右偏移 60px 徹底避開 Leaflet Zoom 控制項) */
        .floating-stat {
            position: absolute;
            top: 14px;
            left: 60px;
            z-index: 1000;
            background: rgba(255, 255, 255, 0.96);
            backdrop-filter: blur(8px);
            padding: 6px 14px;
            border-radius: 30px;
            box-shadow: 0 4px 14px rgba(15, 23, 42, 0.15);
            border: 1px solid var(--border-color);
            display: flex; align-items: center; gap: 10px;
            font-size: 0.82rem;
            font-weight: 600;
            color: var(--text-main);
            pointer-events: auto;
        }

        /* 行動端底部常駐懸浮切換藥丸 */
        .mobile-bottom-bar {
            display: none;
        }

        /* ========================================================
           手機與平板極致自適應 RWD 佈局 (< 768px)
           ======================================================== */
        @media (max-width: 767.98px) {
            .top-navbar {
                padding: 0 10px;
            }
            .top-navbar .brand-title {
                font-size: 0.92rem;
            }
            .nav-btn {
                height: 32px;
                padding: 0 8px;
                font-size: 0.8rem;
            }
            .nav-tool-btn {
                width: 32px;
                height: 32px;
                padding: 0 !important;
                border-radius: 8px;
            }

            .app-layout {
                position: relative;
                height: calc(100vh - 56px);
            }
            .side-panel {
                position: absolute;
                top: 0; left: 0;
                width: 100vw;
                height: 100%;
                z-index: 25;
                padding: 10px 10px 75px 10px;
                display: none;
            }
            .side-panel.mobile-active {
                display: flex;
            }
            .map-wrapper {
                position: absolute;
                top: 0; left: 0;
                width: 100vw;
                height: 100%;
                z-index: 10;
                display: none;
            }
            .map-wrapper.mobile-active {
                display: block;
            }

            .mobile-bottom-bar {
                display: flex;
                position: fixed;
                bottom: 12px;
                left: 50%;
                transform: translateX(-50%);
                z-index: 1050;
                background: rgba(15, 23, 42, 0.92);
                backdrop-filter: blur(10px);
                border-radius: 30px;
                padding: 4px;
                box-shadow: 0 6px 20px rgba(0, 0, 0, 0.35);
                border: 1px solid rgba(255, 255, 255, 0.2);
            }
            .mobile-tab-btn {
                background: transparent;
                border: none;
                color: #94a3b8;
                padding: 6px 18px;
                border-radius: 24px;
                font-size: 0.85rem;
                font-weight: 700;
                cursor: pointer;
                transition: all 0.2s ease;
                display: flex; align-items: center; gap: 6px;
            }
            .mobile-tab-btn.active {
                background: var(--brand-blue);
                color: #ffffff;
                box-shadow: 0 2px 10px rgba(2, 132, 199, 0.5);
            }

            .floating-stat {
                top: 10px;
                left: 52px;
                padding: 4px 10px;
                font-size: 0.75rem;
                gap: 8px;
                max-width: calc(100% - 110px);
            }

            .pano-modal-dialog {
                max-width: 100vw;
                height: 100vh;
                margin: 0;
            }
            .pano-modal-content {
                border-radius: 0;
            }
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div id="bufferApp" v-cloak>
            <!-- 頂部導覽列 (左上角返回首頁，清爽專業無雜訊) -->
            <div class="top-navbar">
                <div class="d-flex align-items-center" style="min-width: 0;">
                    <a href="../MainPage.aspx" class="nav-btn mr-2 mr-md-3">
                        <i class="fas fa-chevron-left mr-1"></i><span class="d-none d-sm-inline">返回首頁</span><span class="d-inline d-sm-none">首頁</span>
                    </a>
                    <div class="brand-title text-truncate">
                        <i class="fas fa-radar mr-2"></i>
                        <span class="d-none d-md-inline">新北市固定逸散源管理平台 — </span>環域分析與 360 環景
                    </div>
                </div>
                <div class="d-flex align-items-center" style="gap: 6px; flex: none;">
                    <button type="button" 
                            class="btn btn-sm btn-success text-white shadow-sm nav-tool-btn" 
                            v-on:click="openSchoolExportModal" 
                            title="匯出固定逸散源距離學校分析清冊 (Excel)">
                        <i class="fas fa-file-excel"></i>
                        <span class="d-none d-md-inline ml-1">學校距離Excel</span>
                    </button>
                    <button type="button" 
                            class="btn btn-sm btn-warning text-white shadow-sm nav-tool-btn" 
                            v-on:click="openGalleryModal" 
                            title="360全覽圖庫 (共 {{ panoList.length }} 處)">
                        <i class="fas fa-vr-cardboard"></i>
                        <span class="d-none d-md-inline ml-1">360全覽圖庫 ({{ panoList.length }})</span>
                    </button>
                    <button type="button" 
                            class="btn btn-sm btn-outline-light nav-tool-btn" 
                            v-on:click="openDebugModal" 
                            title="系統診斷">
                        <i class="fas fa-stethoscope"></i>
                        <span class="d-none d-md-inline ml-1">系統診斷</span>
                    </button>
                </div>
            </div>

            <!-- 主佈局架構 -->
            <div class="app-layout">
                <!-- 左側控制面板 (桌機長駐，手機透過下方藥丸切換) -->
                <div class="side-panel" :class="{ 'mobile-active': mobileTab === 'panel' }">
                    <!-- 後端錯誤提示橫幅 (透明化顯示除錯訊息) -->
                    <div v-if="dbError" class="alert alert-danger py-2 px-3 mb-1 small shadow-sm" style="border-radius: 8px;">
                        <div class="d-flex align-items-center justify-content-between mb-1">
                            <b class="text-danger"><i class="fas fa-exclamation-triangle mr-1"></i>資料查詢異常提醒</b>
                            <button type="button" class="btn btn-danger btn-sm py-0 px-2 font-weight-bold" style="font-size: 0.72rem;" v-on:click="openDebugModal">
                                查看診斷詳情
                            </button>
                        </div>
                        <div style="font-size: 0.75rem; word-break: break-all;">{{ dbError }}</div>
                    </div>

                    <!-- 卡片 1: 定位與搜尋目標 -->
                    <div class="card-modern">
                        <div class="card-modern-header">
                            <h3 class="card-modern-title">
                                <i class="fas fa-map-marker-alt text-danger"></i>
                                <span>中心定位點</span>
                            </h3>
                            <button type="button" class="btn btn-sm btn-outline-primary py-0 px-2" style="font-size: 0.75rem;" v-on:click="getCurrentLocation">
                                <i class="fas fa-crosshairs mr-1"></i>GPS定位
                            </button>
                        </div>
                        <div class="card-modern-body">
                            <!-- 行政區快速選擇 (已嚴格鎖定新北市 29 區) -->
                            <div class="form-group mb-2">
                                <div class="d-flex justify-content-between align-items-center mb-1">
                                    <label class="small text-muted font-weight-bold mb-0">新北市行政區跳轉與邊界聚光</label>
                                    <span v-if="selectedTownNo" class="text-primary small cursor-pointer font-weight-bold" style="cursor: pointer;" v-on:click="clearTownSelection">
                                        <i class="fas fa-times-circle mr-1"></i>清除選取
                                    </span>
                                </div>
                                <select class="form-control form-control-sm" v-model="selectedTownNo" v-on:change="onTownChange">
                                    <option value="">-- 全新北市檢視 (無邊界遮罩) --</option>
                                    <option v-for="t in townList" :key="t.no" :value="t.no">{{ t.name }}</option>
                                </select>
                            </div>

                            <!-- 關鍵字搜尋反查 -->
                            <div class="form-group mb-0">
                                <label class="small text-muted font-weight-bold mb-1">場址關鍵字搜尋 (廠名 / 管編 / 地址)</label>
                                <div class="input-group input-group-sm">
                                    <input type="text" class="form-control" placeholder="輸入關鍵字 (如：太平、八里、水泥...)" v-model="searchKey" v-on:keyup.enter="searchTarget" />
                                    <div class="input-group-append">
                                        <button class="btn btn-primary" type="button" v-on:click="searchTarget" :disabled="searching">
                                            <i class="fas fa-search" v-if="!searching"></i>
                                            <i class="fas fa-spinner fa-spin" v-else></i>
                                        </button>
                                    </div>
                                </div>
                            </div>

                            <!-- 搜尋候選結果下拉 -->
                            <div v-if="searchResults.length > 0" class="mt-2 p-1 border rounded bg-light" style="max-height: 150px; overflow-y: auto;">
                                <div class="d-flex justify-content-between align-items-center px-1 mb-1 border-bottom">
                                    <span class="small font-weight-bold text-muted">搜尋結果 ({{ searchResults.length }})</span>
                                    <button type="button" class="close small" style="font-size: 1rem;" v-on:click="searchResults = []">&times;</button>
                                </div>
                                <div v-for="item in searchResults" :key="item.id" class="p-1 small text-truncate rounded" style="cursor: pointer;" v-on:click="selectSearchItem(item)">
                                    <span class="badge badge-secondary mr-1">{{ item.type }}</span>
                                    <b class="text-dark">{{ item.name }}</b>
                                    <div class="text-muted text-truncate" style="font-size: 0.7rem;">{{ item.addr }}</div>
                                </div>
                            </div>

                            <div class="small text-muted mt-2 d-flex justify-content-between align-items-center">
                                <span>座標：{{ centerCoordStr }}</span>
                                <span class="badge badge-light border text-primary" style="font-size: 0.75rem;">
                                    <i class="fas fa-mouse-pointer mr-1"></i>點地圖即時選點
                                </span>
                            </div>
                        </div>
                    </div>

                    <!-- 卡片 2: 環域半徑與圖層設定 -->
                    <div class="card-modern">
                        <div class="card-modern-header">
                            <h3 class="card-modern-title">
                                <i class="fas fa-bullseye text-primary"></i>
                                <span>環域範圍設定</span>
                            </h3>
                            <span class="badge badge-primary font-weight-bold">{{ currentRadius }} 公尺</span>
                        </div>
                        <div class="card-modern-body">
                            <!-- 半徑拉桿 -->
                            <input type="range" class="custom-range" min="100" max="3000" step="100" v-model.number="currentRadius" v-on:input="onRadiusInput" v-on:change="refreshBuffer" />
                            
                            <!-- 快捷半徑 Chips -->
                            <div class="chip-group">
                                <button type="button" class="chip-btn" :class="{ active: currentRadius === 100 }" v-on:click="setRadius(100)">100m</button>
                                <button type="button" class="chip-btn" :class="{ active: currentRadius === 300 }" v-on:click="setRadius(300)">300m</button>
                                <button type="button" class="chip-btn" :class="{ active: currentRadius === 500 }" v-on:click="setRadius(500)">500m</button>
                                <button type="button" class="chip-btn" :class="{ active: currentRadius === 1000 }" v-on:click="setRadius(1000)">1km</button>
                                <button type="button" class="chip-btn" :class="{ active: currentRadius === 3000 }" v-on:click="setRadius(3000)">3km</button>
                            </div>

                            <!-- 圖層勾選過濾 (預設工廠、裸露地、360環景、各級學校四種皆勾選) -->
                            <div class="d-flex align-items-center justify-content-between flex-wrap mt-3 pt-2 border-top" style="gap: 4px;">
                                <div class="custom-control custom-checkbox custom-control-inline mr-1">
                                    <input type="checkbox" class="custom-control-input" id="chkFac" value="fac" v-model="layerOptions" v-on:change="refreshBuffer" />
                                    <label class="custom-control-label small font-weight-bold" for="chkFac" style="cursor: pointer;">
                                        <span class="badge badge-primary mr-1" style="font-size: 0.65rem;">工廠</span>固定源
                                    </label>
                                </div>
                                <div class="custom-control custom-checkbox custom-control-inline mr-1">
                                    <input type="checkbox" class="custom-control-input" id="chkBare" value="bare" v-model="layerOptions" v-on:change="refreshBuffer" />
                                    <label class="custom-control-label small font-weight-bold" for="chkBare" style="cursor: pointer;">
                                        <span class="badge badge-secondary mr-1" style="font-size: 0.65rem;">裸露</span>裸露地
                                    </label>
                                </div>
                                <div class="custom-control custom-checkbox custom-control-inline mr-1">
                                    <input type="checkbox" class="custom-control-input" id="chkPano" value="pano" v-model="layerOptions" v-on:change="refreshBuffer" />
                                    <label class="custom-control-label small text-warning font-weight-bold" for="chkPano" style="cursor: pointer;">
                                        <i class="fas fa-camera mr-1"></i>360環景
                                    </label>
                                </div>
                                <div class="custom-control custom-checkbox custom-control-inline mr-0">
                                    <input type="checkbox" class="custom-control-input" id="chkSchool" value="school" v-model="layerOptions" v-on:change="refreshBuffer" />
                                    <label class="custom-control-label small font-weight-bold" for="chkSchool" style="cursor: pointer; color: #7c3aed;">
                                        <i class="fas fa-graduation-cap mr-1"></i>各級學校
                                    </label>
                                </div>
                            </div>

                            <!-- 學校敏感受體與重點工廠警戒設定列 -->
                            <div class="mt-2 pt-2 border-top">
                                <div class="d-flex align-items-center justify-content-between mb-1">
                                    <span class="small font-weight-bold" style="color: #7c3aed; font-size: 0.75rem;">
                                        <i class="fas fa-school mr-1"></i>學校學制範圍與重點工廠警戒：
                                    </span>
                                    <div class="d-flex align-items-center" style="gap: 4px;">
                                        <span class="small text-muted" style="font-size: 0.7rem;">警戒距：</span>
                                        <select class="custom-select custom-select-sm py-0 px-1" style="height: 22px; width: auto; font-size: 0.72rem;" v-model.number="priorityThreshold" v-on:change="refreshBuffer">
                                            <option :value="100">≤ 100m</option>
                                            <option :value="300">≤ 300m</option>
                                            <option :value="500">≤ 500m</option>
                                        </select>
                                    </div>
                                </div>
                                <div class="d-flex flex-wrap" style="gap: 4px;">
                                    <button type="button" class="chip-btn py-0 px-2" style="font-size: 0.7rem;" :class="{ active: schoolLevelFilter === '' }" v-on:click="setSchoolLevelFilter('')">全部學制</button>
                                    <button type="button" class="chip-btn py-0 px-2" style="font-size: 0.7rem;" :class="{ active: schoolLevelFilter === '幼兒園' }" v-on:click="setSchoolLevelFilter('幼兒園')">幼兒園(含附幼)</button>
                                    <button type="button" class="chip-btn py-0 px-2" style="font-size: 0.7rem;" :class="{ active: schoolLevelFilter === '國小' }" v-on:click="setSchoolLevelFilter('國小')">國小</button>
                                    <button type="button" class="chip-btn py-0 px-2" style="font-size: 0.7rem;" :class="{ active: schoolLevelFilter === '國中' }" v-on:click="setSchoolLevelFilter('國中')">國中</button>
                                    <button type="button" class="chip-btn py-0 px-2" style="font-size: 0.7rem;" :class="{ active: schoolLevelFilter === '高中職' }" v-on:click="setSchoolLevelFilter('高中職')">高中職</button>
                                    <button type="button" class="chip-btn py-0 px-2" style="font-size: 0.7rem;" :class="{ active: schoolLevelFilter === '大專校院' }" v-on:click="setSchoolLevelFilter('大專校院')">大專</button>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- 卡片 3: 環域統計指標 -->
                    <div class="card-modern">
                        <div class="card-modern-header">
                            <h3 class="card-modern-title">
                                <i class="fas fa-chart-pie text-success"></i>
                                <span>環域統計摘要</span>
                            </h3>
                            <div class="d-flex align-items-center" style="gap: 6px;">
                                <span class="small text-muted" v-if="loading"><i class="fas fa-spinner fa-spin"></i> 計算中…</span>
                                <button type="button" class="btn btn-xs btn-outline-success py-0 px-2 font-weight-bold" style="font-size: 0.7rem; border-radius: 10px;" v-on:click="openSchoolExportModal" title="匯出學校距離分析 Excel 清冊">
                                    <i class="fas fa-file-excel mr-1"></i>匯出清冊
                                </button>
                            </div>
                        </div>
                        <div class="card-modern-body">
                            <div class="stat-grid">
                                <div class="stat-chip clickable" v-on:click="onlyPriorityFilter = false; drawPlacesMarkers();" title="顯示全部環域結果" style="cursor: pointer;">
                                    <div class="stat-val text-primary">{{ summary.Total }}</div>
                                    <div class="stat-lbl">全部對象</div>
                                </div>
                                <div class="stat-chip">
                                    <div class="stat-val text-dark">{{ summary.FacCount }}</div>
                                    <div class="stat-lbl">工廠場所</div>
                                </div>
                                <div class="stat-chip clickable" 
                                     :style="onlyPriorityFilter ? 'background: #ea580c; border-color: #c2410c; color: #fff; cursor: pointer;' : 'background: #fff7ed; border-color: #fed7aa; cursor: pointer;'"
                                     v-on:click="toggleOnlyPriorityFilter"
                                     :title="'點擊切換：僅顯示距學校 ≤' + priorityThreshold + 'm 之重點列管工廠'">
                                    <div class="stat-val" :style="onlyPriorityFilter ? 'color: #fff;' : 'color: #ea580c;'">{{ summary.PriorityFacCount || 0 }}</div>
                                    <div class="stat-lbl" :style="onlyPriorityFilter ? 'color: #ffedd5;' : 'color: #c2410c;'">重點工廠</div>
                                </div>
                                <div class="stat-chip" style="background: #f5f3ff; border-color: #ddd6fe;">
                                    <div class="stat-val" style="color: #7c3aed;">{{ summary.SchoolCount || 0 }}</div>
                                    <div class="stat-lbl" style="color: #6d28d9;">各級學校</div>
                                </div>
                                <div class="stat-chip" style="background: #fffbeb; border-color: #fde68a;">
                                    <div class="stat-val text-warning">{{ summary.PanoCount }}</div>
                                    <div class="stat-lbl" style="color: #b45309;">360環景</div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- 卡片 4: 環域搜尋結果清單 (支援距離排序與行業別分類分組統計) -->
                    <div class="result-card-container">
                        <div class="result-card-header flex-column align-items-stretch" style="gap: 8px;">
                            <div class="d-flex align-items-center justify-content-between">
                                <h3 class="card-modern-title">
                                    <i class="fas fa-list-ul text-primary"></i>
                                    <span>環域搜尋結果</span>
                                </h3>
                                <div class="d-flex align-items-center flex-wrap justify-content-end" style="gap: 4px;">
                                    <span v-if="onlyPriorityFilter" class="badge badge-danger font-weight-bold" style="font-size: 0.7rem; cursor: pointer;" v-on:click="toggleOnlyPriorityFilter" title="點此取消重點工廠過濾">
                                        <i class="fas fa-exclamation-circle mr-1"></i>重點工廠(≤{{ priorityThreshold }}m) &times;
                                    </span>
                                    <span v-if="activeFilterIndustry" class="badge badge-warning text-dark font-weight-bold" style="font-size: 0.72rem; cursor: pointer;" v-on:click="clearIndustryFilter" title="點此取消過濾，顯示全部">
                                        <i class="fas fa-filter mr-1"></i>{{ activeFilterIndustry }} &times;
                                    </span>
                                    <span class="badge badge-light border text-primary font-weight-bold" style="font-size: 0.75rem;">
                                        {{ displayPlacesList.length }} 筆場所
                                    </span>
                                </div>
                            </div>

                            <!-- 檢視模式雙切換按鈕：距離排序 vs 行業分類 -->
                            <div class="btn-group btn-group-sm w-100" role="group">
                                <button type="button" class="btn py-1 font-weight-bold" 
                                        :class="resultViewMode === 'list' ? 'btn-primary' : 'btn-light border'" 
                                        style="font-size: 0.75rem;" 
                                        v-on:click="resultViewMode = 'list'">
                                    <i class="fas fa-sort-amount-down-alt mr-1"></i>依距離排序
                                </button>
                                <button type="button" class="btn py-1 font-weight-bold" 
                                        :class="resultViewMode === 'group' ? 'btn-success text-white' : 'btn-light border'" 
                                        style="font-size: 0.75rem;" 
                                        v-on:click="resultViewMode = 'group'">
                                    <i class="fas fa-sitemap mr-1"></i>依行業分類 ({{ industrySummary.length }}組)
                                </button>
                            </div>
                        </div>

                        <div class="result-card-body">
                            <!-- 模式 A: 依距離流水清單 -->
                            <div class="result-list" v-if="resultViewMode === 'list' && displayPlacesList.length > 0">
                                <div v-for="item in displayPlacesList" :key="item.id" 
                                     class="result-item" 
                                     :class="{ 
                                         selected: selectedItemId === item.id,
                                         'priority-high': item.typeKey === 'fac' && item.schoolRiskLevel === 'high',
                                         'priority-medium': item.typeKey === 'fac' && item.schoolRiskLevel === 'medium',
                                         'school-card': item.typeKey === 'school'
                                     }"
                                     v-on:click="focusItem(item)">
                                    <div class="result-item-header">
                                        <div class="result-item-title">
                                            <!-- 類型標籤 (工廠 / 裸露地 / 360環景 / 各級學校) -->
                                            <span class="badge mr-1" 
                                                  :class="item.typeKey === 'fac' ? (item.isPriorityFac ? 'badge-danger' : 'badge-primary') : (item.typeKey === 'bare' ? 'badge-secondary' : (item.typeKey === 'school' ? 'badge-info' : 'badge-warning text-dark'))"
                                                  :style="item.typeKey === 'school' ? 'background-color: #7c3aed; font-size: 0.68rem;' : 'font-size: 0.68rem;'">
                                                <i class="fas fa-camera mr-1" v-if="item.typeKey === 'pano'"></i>
                                                <i class="fas fa-graduation-cap mr-1" v-else-if="item.typeKey === 'school'"></i>
                                                <i class="fas fa-exclamation-triangle mr-1" v-else-if="item.isPriorityFac"></i>{{ item.isPriorityFac ? '重點工廠' : item.type }}
                                            </span>
                                            <!-- 行業別徽章 -->
                                            <span class="badge badge-light border text-success mr-1" style="font-size: 0.68rem;" v-if="item.industry && item.typeKey !== 'school'">
                                                {{ item.industry }}
                                            </span>
                                            <span class="badge badge-light border mr-1" style="font-size: 0.68rem; color: #6d28d9;" v-if="item.typeKey === 'school'">
                                                {{ item.cno }}
                                            </span>
                                            {{ item.name }}
                                        </div>
                                        <div class="result-item-dist">{{ item.dist }}m</div>
                                    </div>
                                    <div class="result-item-addr">{{ item.addr || '無詳細地址紀錄' }}</div>

                                    <!-- 工廠 / 裸露地：顯示「距離最近學校」敏感度連線徽章 -->
                                    <div class="mt-1" v-if="(item.typeKey === 'fac' || item.typeKey === 'bare') && item.nearestSchoolName">
                                        <span :class="item.schoolRiskLevel === 'high' ? 'badge-school-high' : (item.schoolRiskLevel === 'medium' ? 'badge-school-medium' : 'badge-school-normal')"
                                              v-on:click.stop="drawSchoolConnectionLine(item)"
                                              title="點擊在地圖繪製與最近學校之直線距離連線">
                                            <i class="fas fa-graduation-cap"></i>
                                            <span v-if="item.schoolRiskLevel === 'high'">極高敏：距 {{ item.nearestSchoolName }} <b>{{ item.nearestSchoolDist }}m</b></span>
                                            <span v-else-if="item.schoolRiskLevel === 'medium'">重點列管：距 {{ item.nearestSchoolName }} <b>{{ item.nearestSchoolDist }}m</b></span>
                                            <span v-else>最近學校：{{ item.nearestSchoolName }} ({{ item.nearestSchoolDist }}m)</span>
                                            <i class="fas fa-route ml-1" style="opacity: 0.85;"></i>
                                        </span>
                                    </div>

                                    <!-- 1. 工廠場所專屬快捷列 (許可證 / 巡查紀錄 / 360 環景) -->
                                    <div class="d-flex align-items-center justify-content-between mt-2 pt-2 border-top" v-if="item.typeKey === 'fac'">
                                        <div class="d-flex" style="gap: 5px;">
                                            <button type="button" class="btn btn-sm btn-outline-primary py-0 px-2 font-weight-bold" style="font-size: 0.72rem;" v-on:click.stop="openFacProfile(item, 'license')">
                                                <i class="fas fa-file-contract mr-1"></i>許可證
                                            </button>
                                            <button type="button" class="btn btn-sm btn-outline-info py-0 px-2 font-weight-bold" style="font-size: 0.72rem;" v-on:click.stop="openFacProfile(item, 'inspection')">
                                                <i class="fas fa-clipboard-check mr-1"></i>巡查紀錄
                                            </button>
                                        </div>
                                        <div v-if="item.hasPano">
                                            <button type="button" class="badge-pano border-0 cursor-pointer" v-on:click.stop="openPano(item)" :title="item.panoMonthText ? ('拍攝期程：' + item.panoMonthText) : '開啟 360° 實景導覽'">
                                                <i class="fas fa-street-view mr-1"></i>360°<span v-if="item.panoMonthText" class="ml-1" style="font-size: 0.68rem; opacity: 0.9;">({{ item.panoMonthText }})</span>
                                            </button>
                                            <span v-if="item.panoHistory && item.panoHistory.length > 0" class="badge badge-light border text-muted ml-1" style="font-size: 0.62rem;" :title="'含 ' + item.panoHistory.length + ' 個歷史期程'">+{{ item.panoHistory.length }}歷次</span>
                                        </div>
                                    </div>

                                    <!-- 2. 裸露地專屬動作列 -->
                                    <div class="d-flex align-items-center justify-content-between mt-2 pt-2 border-top" v-else-if="item.typeKey === 'bare'">
                                        <span class="small text-muted" v-if="item.facType" style="font-size: 0.72rem;">
                                            地目：{{ item.facType }}
                                        </span>
                                        <span v-else></span>
                                        <div v-if="item.hasPano">
                                            <button type="button" class="badge-pano border-0 cursor-pointer" v-on:click.stop="openPano(item)" :title="item.panoMonthText ? ('拍攝期程：' + item.panoMonthText) : '開啟 360° 實景導覽'">
                                                <i class="fas fa-street-view mr-1"></i>360°<span v-if="item.panoMonthText" class="ml-1" style="font-size: 0.68rem; opacity: 0.9;">({{ item.panoMonthText }})</span>
                                            </button>
                                            <span v-if="item.panoHistory && item.panoHistory.length > 0" class="badge badge-light border text-muted ml-1" style="font-size: 0.62rem;" :title="'含 ' + item.panoHistory.length + ' 個歷史期程'">+{{ item.panoHistory.length }}歷次</span>
                                        </div>
                                    </div>

                                    <!-- 3. 獨立 360 環景點位專屬動作列 -->
                                    <div class="d-flex align-items-center justify-content-between mt-2 pt-2 border-top" v-else-if="item.typeKey === 'pano'">
                                        <span class="small text-muted" style="font-size: 0.72rem;">
                                            <i class="fas fa-vr-cardboard text-warning mr-1"></i>高解析環景實景
                                            <span v-if="item.panoMonthText" class="badge badge-info ml-1" style="font-size: 0.65rem;">{{ item.panoMonthText }}</span>
                                        </span>
                                        <div>
                                            <button type="button" class="badge-pano border-0 cursor-pointer" v-on:click.stop="openPano(item)">
                                                <i class="fas fa-street-view mr-1"></i>開啟 360° 實景導覽
                                            </button>
                                            <span v-if="item.panoHistory && item.panoHistory.length > 0" class="badge badge-light border text-muted ml-1" style="font-size: 0.62rem;" :title="'含 ' + item.panoHistory.length + ' 個歷史期程'">+{{ item.panoHistory.length }}歷次</span>
                                        </div>
                                    </div>

                                    <!-- 4. 各級學校專屬動作列 (支援一鍵以該校為中心反查周邊工廠) -->
                                    <div class="d-flex align-items-center justify-content-between mt-2 pt-2 border-top" v-else-if="item.typeKey === 'school'">
                                        <span class="small text-muted text-truncate" style="font-size: 0.72rem; max-width: 190px;" :title="item.phone">
                                            <i class="fas fa-phone-alt mr-1 text-secondary"></i>{{ item.phone || '新北市各級學校' }}
                                        </span>
                                        <div class="d-flex" style="gap: 5px;">
                                            <a v-if="item.url" :href="item.url" target="_blank" class="btn btn-sm btn-outline-secondary py-0 px-2" style="font-size: 0.7rem;" v-on:click.stop>
                                                <i class="fas fa-globe"></i>
                                            </a>
                                            <button type="button" class="btn btn-sm py-0 px-2 font-weight-bold text-white" style="background: #7c3aed; font-size: 0.72rem;" v-on:click.stop="setSchoolAsCenter(item)">
                                                <i class="fas fa-crosshairs mr-1"></i>設為中心反查工廠
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- 模式 B: 依行業別手風琴分組檢視 (重現舊系統綠色分類手風琴) -->
                            <div class="industry-accordion" v-else-if="resultViewMode === 'group' && industrySummary.length > 0">
                                <div v-for="ind in industrySummary" :key="ind.name" class="industry-group-item">
                                    <div class="industry-bar-header" 
                                         :class="{ focused: activeFilterIndustry === ind.name }"
                                         v-on:click="toggleIndustry(ind.name)">
                                        <div class="industry-bar-title text-truncate" :title="ind.name">
                                            <i class="fas fa-chevron-right chevron-icon" :class="{ 'rotate-90': isIndExpanded(ind.name) }"></i>
                                            <span class="text-truncate">{{ ind.name }}</span>
                                        </div>
                                        <div class="d-flex align-items-center" style="gap: 5px; flex: none;">
                                            <span class="badge badge-pill badge-light text-dark font-weight-bold" style="font-size: 0.72rem;">
                                                共 {{ ind.count }} 筆
                                            </span>
                                            <button type="button" class="btn btn-xs py-0 px-2 font-weight-bold" 
                                                    :class="activeFilterIndustry === ind.name ? 'btn-warning text-dark' : 'btn-outline-light'" 
                                                    style="font-size: 0.68rem; border-radius: 10px;" 
                                                    v-on:click.stop="filterMapByIndustry(ind.name)" 
                                                    :title="activeFilterIndustry === ind.name ? '點此取消地圖聚焦' : '地圖僅高亮顯示此行業點位'">
                                                <i class="fas fa-crosshairs mr-1"></i>{{ activeFilterIndustry === ind.name ? '取消聚焦' : '地圖聚焦' }}
                                            </button>
                                        </div>
                                    </div>

                                    <!-- 手風琴展開內容：該行業別下的場所卡片清單 -->
                                    <div class="industry-group-body" v-if="isIndExpanded(ind.name)">
                                        <div v-for="item in getItemsByIndustry(ind.name)" :key="item.id" 
                                             class="result-item" 
                                             :class="{ 
                                                 selected: selectedItemId === item.id,
                                                 'priority-high': item.typeKey === 'fac' && item.schoolRiskLevel === 'high',
                                                 'priority-medium': item.typeKey === 'fac' && item.schoolRiskLevel === 'medium',
                                                 'school-card': item.typeKey === 'school'
                                             }" 
                                             v-on:click="focusItem(item)">
                                            <div class="result-item-header">
                                                <div class="result-item-title">
                                                    <span class="badge mr-1" 
                                                          :class="item.typeKey === 'fac' ? (item.isPriorityFac ? 'badge-danger' : 'badge-primary') : (item.typeKey === 'bare' ? 'badge-secondary' : (item.typeKey === 'school' ? 'badge-info' : 'badge-warning text-dark'))"
                                                          :style="item.typeKey === 'school' ? 'background-color: #7c3aed; font-size: 0.65rem;' : 'font-size: 0.65rem;'">
                                                        {{ item.isPriorityFac ? '重點工廠' : item.type }}
                                                    </span>
                                                    {{ item.name }}
                                                </div>
                                                <div class="result-item-dist">{{ item.dist }}m</div>
                                            </div>
                                            <div class="result-item-addr">{{ item.addr || '無詳細地址紀錄' }}</div>

                                            <!-- 最近學校距離敏感度徽章 -->
                                            <div class="mt-1" v-if="(item.typeKey === 'fac' || item.typeKey === 'bare') && item.nearestSchoolName">
                                                <span :class="item.schoolRiskLevel === 'high' ? 'badge-school-high' : (item.schoolRiskLevel === 'medium' ? 'badge-school-medium' : 'badge-school-normal')"
                                                      v-on:click.stop="drawSchoolConnectionLine(item)"
                                                      title="點擊在地圖繪製與最近學校之直線距離連線">
                                                    <i class="fas fa-graduation-cap"></i>
                                                    <span v-if="item.schoolRiskLevel === 'high'">極高敏：距 {{ item.nearestSchoolName }} <b>{{ item.nearestSchoolDist }}m</b></span>
                                                    <span v-else-if="item.schoolRiskLevel === 'medium'">重點：距 {{ item.nearestSchoolName }} <b>{{ item.nearestSchoolDist }}m</b></span>
                                                    <span v-else>最近：{{ item.nearestSchoolName }} ({{ item.nearestSchoolDist }}m)</span>
                                                    <i class="fas fa-route ml-1" style="opacity: 0.85;"></i>
                                                </span>
                                            </div>

                                            <!-- 工廠快捷動作列 -->
                                            <div class="d-flex align-items-center justify-content-between mt-2 pt-2 border-top" v-if="item.typeKey === 'fac'">
                                                <div class="d-flex" style="gap: 5px;">
                                                    <button type="button" class="btn btn-sm btn-outline-primary py-0 px-2 font-weight-bold" style="font-size: 0.72rem;" v-on:click.stop="openFacProfile(item, 'license')">
                                                        <i class="fas fa-file-contract mr-1"></i>許可證
                                                    </button>
                                                    <button type="button" class="btn btn-sm btn-outline-info py-0 px-2 font-weight-bold" style="font-size: 0.72rem;" v-on:click.stop="openFacProfile(item, 'inspection')">
                                                        <i class="fas fa-clipboard-check mr-1"></i>巡查紀錄
                                                    </button>
                                                </div>
                                                <div v-if="item.hasPano">
                                                    <button type="button" class="badge-pano border-0 cursor-pointer" v-on:click.stop="openPano(item)" :title="item.panoMonthText ? ('拍攝期程：' + item.panoMonthText) : '開啟 360° 實景導覽'">
                                                        <i class="fas fa-street-view mr-1"></i>360°<span v-if="item.panoMonthText" class="ml-1" style="font-size: 0.68rem; opacity: 0.9;">({{ item.panoMonthText }})</span>
                                                    </button>
                                                    <span v-if="item.panoHistory && item.panoHistory.length > 0" class="badge badge-light border text-muted ml-1" style="font-size: 0.62rem;" :title="'含 ' + item.panoHistory.length + ' 個歷史期程'">+{{ item.panoHistory.length }}歷次</span>
                                                </div>
                                            </div>
                                            <div class="d-flex align-items-center justify-content-between mt-2 pt-2 border-top" v-else-if="item.typeKey === 'school'">
                                                <span class="small text-muted" style="font-size: 0.7rem;">{{ item.cno }}</span>
                                                <button type="button" class="btn btn-sm py-0 px-2 font-weight-bold text-white" style="background: #7c3aed; font-size: 0.7rem;" v-on:click.stop="setSchoolAsCenter(item)">
                                                    <i class="fas fa-crosshairs mr-1"></i>設為中心反查
                                                </button>
                                            </div>
                                            <div class="mt-2 text-right" v-else-if="item.hasPano">
                                                <button type="button" class="badge-pano border-0 cursor-pointer" v-on:click.stop="openPano(item)" :title="item.panoMonthText ? ('拍攝期程：' + item.panoMonthText) : '開啟 360° 實景導覽'">
                                                    <i class="fas fa-street-view mr-1"></i>360° 實景<span v-if="item.panoMonthText" class="ml-1" style="font-size: 0.68rem; opacity: 0.9;">({{ item.panoMonthText }})</span>
                                                </button>
                                                <span v-if="item.panoHistory && item.panoHistory.length > 0" class="badge badge-light border text-muted ml-1" style="font-size: 0.62rem;" :title="'含 ' + item.panoHistory.length + ' 個歷史期程'">+{{ item.panoHistory.length }}歷次</span>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            
                            <!-- 空狀態引導 -->
                            <div v-else class="text-center py-4 px-2 text-muted small">
                                <i class="fas fa-search-location fa-2x mb-2 text-primary" style="opacity: 0.6;"></i>
                                <div class="font-weight-bold text-dark mb-1">半徑 {{ currentRadius }}m 內查無符合對象</div>
                                <div class="mb-3 text-muted" style="font-size: 0.75rem;">
                                    當前中心點周邊無選取之圖層設施。建議擴大搜尋半徑或勾選其他圖層。
                                </div>
                                <div class="d-flex justify-content-center gap-2 mb-2" style="gap: 6px;">
                                    <button type="button" class="btn btn-sm btn-outline-primary" v-on:click="setRadius(1000)" v-if="currentRadius < 1000">
                                        <i class="fas fa-expand mr-1"></i>擴大至 1,000m
                                    </button>
                                    <button type="button" class="btn btn-sm btn-outline-primary" v-on:click="setRadius(3000)" v-if="currentRadius < 3000">
                                        <i class="fas fa-expand mr-1"></i>擴大至 3,000m
                                    </button>
                                </div>
                                <div v-if="panoList.length > 0" class="mt-2 text-center pt-2 border-top">
                                    <span class="text-muted" style="font-size: 0.72rem;">瀏覽全新北市 360 實景：</span><br/>
                                    <button type="button" class="btn btn-sm btn-link text-warning font-weight-bold p-0" v-on:click="openGalleryModal">
                                        <i class="fas fa-vr-cardboard mr-1"></i>開啟 360 全覽圖庫 ({{ panoList.length }})
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- 右側主地圖區 (桌機長駐，手機透過下方藥丸切換) -->
                <div class="map-wrapper" :class="{ 'mobile-active': mobileTab === 'map' }">
                    <!-- 浮動提示 (向右偏移避開左側 zoom 按鈕) -->
                    <div class="floating-stat">
                        <div>
                            <span class="text-muted small">半徑：</span>
                            <b class="text-primary">{{ currentRadius }}m</b>
                        </div>
                        <div class="border-left pl-2">
                            <span class="text-muted small">場所：</span>
                            <b class="text-dark">{{ resultList.length }} 處</b>
                        </div>
                        <div class="border-left pl-2" v-if="summary.PanoCount > 0">
                            <span class="badge-pano">
                                <i class="fas fa-camera mr-1"></i>360 {{ summary.PanoCount }}
                            </span>
                        </div>
                        <div class="border-left pl-2 d-none d-sm-block" v-if="selectedTownName">
                            <span class="badge badge-light border text-primary">
                                <i class="fas fa-map mr-1"></i>{{ selectedTownName }}
                            </span>
                        </div>
                        <!-- 地圖圖層切換：顯示 360 圖標 (依選定行政區動態連動) -->
                        <div class="border-left pl-2 d-none d-md-flex align-items-center">
                            <div class="custom-control custom-checkbox custom-control-inline mb-0 mr-0">
                                <input type="checkbox" class="custom-control-input" id="chkMapPanoPins" v-model="showPanoMapPins" v-on:change="renderPanoMapPins" />
                                <label class="custom-control-label small font-weight-bold text-warning cursor-pointer" for="chkMapPanoPins">
                                    <i class="fas fa-camera mr-1"></i>
                                    <span v-if="selectedTownName">標記 {{ selectedTownName }} 360 ({{ visiblePanoPinsCount }})</span>
                                    <span v-else>標記360圖標 ({{ visiblePanoPinsCount }})</span>
                                </label>
                            </div>
                        </div>
                    </div>

                    <!-- Leaflet 容器 -->
                    <div id="map"></div>
                </div>
            </div>

            <!-- 手機版底部常駐切換藥丸 (僅在小螢幕呈現) -->
            <div class="mobile-bottom-bar">
                <button type="button" class="mobile-tab-btn" :class="{ active: mobileTab === 'map' }" v-on:click="switchMobileTab('map')">
                    <i class="fas fa-map-marked-alt"></i> 地圖全螢幕
                </button>
                <button type="button" class="mobile-tab-btn" :class="{ active: mobileTab === 'panel' }" v-on:click="switchMobileTab('panel')">
                    <i class="fas fa-sliders-h"></i> 條件與清單 ({{ resultList.length }})
                </button>
            </div>

            <!-- 場所全能履歷彈窗 Modal (許可證與巡查紀錄核心視窗) -->
            <div class="modal fade" id="facProfileModal" tabindex="-1" role="dialog" aria-hidden="true">
                <div class="modal-dialog modal-dialog-centered modal-lg" role="document">
                    <div class="modal-content" style="border-radius: 12px; overflow: hidden; max-height: 85vh;">
                        <div class="modal-header py-2 px-3 text-white" style="background: linear-gradient(135deg, #0284c7, #0b1f7d);">
                            <div class="d-flex align-items-center" style="min-width: 0;">
                                <i class="fas fa-building text-warning fa-lg mr-2"></i>
                                <div class="text-truncate">
                                    <h5 class="modal-title font-weight-bold text-truncate mb-0" style="font-size: 1.05rem;">
                                        {{ profileFacName }}
                                    </h5>
                                    <span class="small text-white-50" style="font-size: 0.75rem;">
                                        管編：{{ profileCNo || '無' }} | 代碼：{{ profileFacId }}
                                    </span>
                                </div>
                            </div>
                            <button type="button" class="close text-white" data-dismiss="modal" aria-label="Close" style="opacity: 0.85;">
                                <span aria-hidden="true">&times;</span>
                            </button>
                        </div>

                        <!-- Tab 標籤列 -->
                        <div class="bg-light px-3 pt-2 border-bottom">
                            <ul class="nav nav-tabs border-bottom-0" style="gap: 4px;">
                                <li class="nav-item">
                                    <a class="nav-link font-weight-bold py-2 px-3" 
                                       :class="{ active: profileTab === 'license' }" 
                                       v-on:click="profileTab = 'license'" style="cursor: pointer;">
                                        <i class="fas fa-file-contract mr-1 text-primary"></i>許可證資訊
                                        <span class="badge badge-primary ml-1" v-if="profileData && profileData.Licenses">{{ profileData.Licenses.length }}</span>
                                    </a>
                                </li>
                                <li class="nav-item">
                                    <a class="nav-link font-weight-bold py-2 px-3" 
                                       :class="{ active: profileTab === 'inspection' }" 
                                       v-on:click="profileTab = 'inspection'" style="cursor: pointer;">
                                        <i class="fas fa-clipboard-check mr-1 text-info"></i>巡查查核紀錄
                                        <span class="badge badge-info ml-1" v-if="profileData && profileData.Inspections">{{ profileData.Inspections.length }}</span>
                                    </a>
                                </li>
                                <li class="nav-item">
                                    <a class="nav-link font-weight-bold py-2 px-3" 
                                       :class="{ active: profileTab === 'basic' }" 
                                       v-on:click="profileTab = 'basic'" style="cursor: pointer;">
                                        <i class="fas fa-info-circle mr-1 text-secondary"></i>場所基本檔
                                    </a>
                                </li>
                            </ul>
                        </div>

                        <div class="modal-body p-3" style="max-height: 65vh; overflow-y: auto; background: #f8fafc;">
                            <!-- 載入中骨架 Spinner -->
                            <div v-if="profileLoading" class="text-center py-5 text-muted">
                                <i class="fas fa-spinner fa-spin fa-2x mb-2 text-primary"></i>
                                <div>正在載入場所許可證與歷次巡查紀錄…</div>
                            </div>

                            <div v-else-if="profileData">
                                <!-- Tab 1: 許可證資訊 -->
                                <div v-if="profileTab === 'license'">
                                    <div v-if="profileData.Licenses && profileData.Licenses.length > 0" class="d-flex flex-column" style="gap: 10px;">
                                        <div v-for="(lic, idx) in profileData.Licenses" :key="idx" class="card border shadow-sm" style="border-radius: 8px;">
                                            <div class="card-body p-3">
                                                <div class="d-flex align-items-center justify-content-between mb-2">
                                                    <div class="font-weight-bold text-dark" style="font-size: 0.95rem;">
                                                        <i class="fas fa-certificate text-warning mr-1"></i>{{ lic.ProcessName }}
                                                        <span class="badge badge-light border ml-1">{{ lic.ProcessType }}</span>
                                                    </div>
                                                    <span class="badge font-weight-bold" 
                                                          :class="lic.Status === '有效' || lic.Status === '列管中' ? 'badge-success' : (lic.Status === '已逾期' ? 'badge-danger' : 'badge-warning')">
                                                        {{ lic.Status }}
                                                    </span>
                                                </div>
                                                <div class="row row-cols-1 row-cols-sm-2 g-2 small text-muted">
                                                    <div class="col">
                                                        <b>許可證字號：</b><span class="text-dark font-weight-bold">{{ lic.ProcessLic }}</span>
                                                    </div>
                                                    <div class="col">
                                                        <b>製程代碼：</b><span>{{ lic.ProcessId || '-' }}</span>
                                                    </div>
                                                    <div class="col">
                                                        <b>許可有效期限：</b><span>{{ lic.StartDate }} ~ {{ lic.EndDate }}</span>
                                                    </div>
                                                    <div class="col">
                                                        <b>展延申請期限：</b><span>{{ lic.ContinueDeadline }}</span>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                    <div v-else class="text-center py-4 text-muted small bg-white rounded border">
                                        <i class="fas fa-file-invoice fa-2x mb-2 text-black-50 d-block"></i>
                                        本場所目前無列管之固定污染源操作/設置許可證資料
                                    </div>
                                </div>

                                <!-- Tab 2: 巡查查核紀錄 -->
                                <div v-if="profileTab === 'inspection'">
                                    <div v-if="profileData.Inspections && profileData.Inspections.length > 0" class="d-flex flex-column" style="gap: 8px;">
                                        <div v-for="inv in profileData.Inspections" :key="inv.InvNo" class="card border shadow-sm" style="border-radius: 8px;">
                                            <div class="card-body p-3">
                                                <div class="d-flex align-items-center justify-content-between mb-2">
                                                    <div class="font-weight-bold text-dark" style="font-size: 0.9rem;">
                                                        <i class="fas fa-calendar-check text-info mr-1"></i>查核時間：{{ inv.InvDate }}
                                                        <span class="text-muted small ml-1">(案號: #{{ inv.InvNo }})</span>
                                                    </div>
                                                    <div class="d-flex align-items-center" style="gap: 6px;">
                                                        <span class="badge font-weight-bold" :class="inv.BadgeClass">{{ inv.ResultText }}</span>
                                                        <span class="badge badge-light border text-muted small">{{ inv.StateName }}</span>
                                                    </div>
                                                </div>
                                                <div class="small text-muted mb-2 bg-light p-2 rounded" style="line-height: 1.4;">
                                                    <b>查核備註 / 缺失說明：</b>{{ inv.Memo }}
                                                </div>
                                                <div class="text-right">
                                                    <a :href="inv.ReportUrl" target="_blank" class="btn btn-sm btn-outline-info font-weight-bold py-0 px-2" style="font-size: 0.75rem;">
                                                        <i class="fas fa-external-link-alt mr-1"></i>查看現場查核報告與照片
                                                    </a>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                    <div v-else class="text-center py-4 text-muted small bg-white rounded border">
                                        <i class="fas fa-clipboard-list fa-2x mb-2 text-black-50 d-block"></i>
                                        本場所目前尚無現場巡查查核紀錄
                                    </div>
                                </div>

                                <!-- Tab 3: 基本資料 -->
                                <div v-if="profileTab === 'basic'">
                                    <div class="card border shadow-sm" style="border-radius: 8px;">
                                        <div class="card-body p-3">
                                            <table class="table table-sm table-bordered mb-0 small">
                                                <tbody>
                                                    <tr>
                                                        <th style="width: 25%; background: #f8fafc;">場所名稱</th>
                                                        <td class="font-weight-bold">{{ profileData.Basic.FacName }}</td>
                                                    </tr>
                                                    <tr>
                                                        <th style="background: #f8fafc;">管制編號</th>
                                                        <td>{{ profileData.Basic.CNo || '無' }}</td>
                                                    </tr>
                                                    <tr>
                                                        <th style="background: #f8fafc;">場所代碼</th>
                                                        <td>{{ profileData.Basic.FacId }}</td>
                                                    </tr>
                                                    <tr>
                                                        <th style="background: #f8fafc;">廠址地址</th>
                                                        <td>{{ profileData.Basic.Addr || '無地址紀錄' }}</td>
                                                    </tr>
                                                    <tr>
                                                        <th style="background: #f8fafc;">聯絡電話</th>
                                                        <td>{{ profileData.Basic.Tel || '-' }}</td>
                                                    </tr>
                                                    <tr>
                                                        <th style="background: #f8fafc;">負責人</th>
                                                        <td>{{ profileData.Basic.BossName || '-' }}</td>
                                                    </tr>
                                                    <tr>
                                                        <th style="background: #f8fafc;">列管類型</th>
                                                        <td><span class="badge badge-info">{{ profileData.Basic.FacType }}</span></td>
                                                    </tr>
                                                    <tr>
                                                        <th style="background: #f8fafc;">管理辦法適用</th>
                                                        <td>{{ profileData.Basic.RegNoStr || profileData.Basic.RegNo || '-' }}</td>
                                                    </tr>
                                                </tbody>
                                            </table>
                                            <div class="mt-3 text-center">
                                                <a :href="profileData.Basic.DetailUrl" target="_blank" class="btn btn-sm btn-primary font-weight-bold px-3">
                                                    <i class="fas fa-external-link-alt mr-1"></i>前往完整工廠基本檔 (FAC_Detail.aspx)
                                                </a>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <div class="modal-footer py-2 px-3 bg-light">
                            <button type="button" class="btn btn-sm btn-secondary" data-dismiss="modal">關閉</button>
                        </div>
                    </div>
                </div>
            </div>

            <!-- 360 環景全螢幕彈窗 Modal (單一導覽播放 + 歷史期程快速切換) -->
            <div class="modal fade" id="panoModal" tabindex="-1" role="dialog" aria-hidden="true" data-backdrop="static">
                <div class="modal-dialog modal-dialog-centered modal-xl pano-modal-dialog" role="document">
                    <div class="modal-content pano-modal-content" style="height: 85vh; border: none; overflow: hidden; background: #000;">
                        <div class="modal-header py-2 px-3 text-white" style="background: #0f172a; border-bottom: 1px solid #334155;">
                            <div class="d-flex align-items-center flex-wrap" style="gap: 8px; min-width: 0;">
                                <h5 class="modal-title font-weight-bold text-truncate mb-0" style="font-size: 1rem;">
                                    <i class="fas fa-street-view text-warning mr-2"></i>{{ currentPanoTitle }}
                                </h5>
                                <span class="badge badge-warning text-dark font-weight-bold" style="font-size: 0.72rem;" v-if="currentPanoMonthText">
                                    <i class="fas fa-calendar-alt mr-1"></i>{{ currentPanoMonthText }}
                                </span>
                                <!-- 歷次期程快速切換下拉選單 -->
                                <div class="d-flex align-items-center ml-md-2" v-if="currentPanoHistoryList && currentPanoHistoryList.length > 0">
                                    <span class="text-white-50 small mr-1 font-weight-bold" style="font-size: 0.72rem;">歷史期程：</span>
                                    <select class="custom-select custom-select-sm py-0 px-2" 
                                            style="height: 26px; font-size: 0.75rem; width: auto; background: #1e293b; color: #f8fafc; border-color: #475569;" 
                                            v-model="selectedPanoVersionUrl" 
                                            v-on:change="switchPanoVersion">
                                        <option :value="currentPanoOriginalUrl">{{ currentPanoMonthText || '最新版本' }} (最新)</option>
                                        <option v-for="h in currentPanoHistoryList" :key="h.Url" :value="h.Url">
                                            {{ h.MonthText }} (歷次)
                                        </option>
                                    </select>
                                </div>
                            </div>
                            <button type="button" class="close text-white" aria-label="Close" style="opacity: 0.8;" v-on:click="closePano">
                                <span aria-hidden="true">&times;</span>
                            </button>
                        </div>
                        <div class="modal-body p-0 position-relative" style="height: calc(100% - 45px); background: #000;">
                            <div v-if="panoLoading" class="position-absolute w-100 h-100 d-flex flex-column align-items-center justify-content-center text-white" style="background: rgba(0,0,0,0.7); z-index: 10;">
                                <i class="fas fa-spinner fa-spin fa-3x mb-3 text-warning"></i>
                                <span>正在載入 3DVista 高解析 360° 實景瓦片…</span>
                            </div>
                            <iframe v-if="currentPanoUrl" 
                                    :src="currentPanoUrl" 
                                    style="width: 100%; height: 100%; border: none;" 
                                    allowfullscreen
                                    v-on:load="panoLoading = false">
                            </iframe>
                        </div>
                    </div>
                </div>
            </div>

            <!-- 360° 實景導覽全覽圖庫 Modal (解決 167 筆點位瀏覽難題 + 月份篩選) -->
            <div class="modal fade" id="panoGalleryModal" tabindex="-1" role="dialog" aria-hidden="true">
                <div class="modal-dialog modal-dialog-centered modal-xl" role="document">
                    <div class="modal-content" style="border-radius: 14px; overflow: hidden; max-height: 90vh;">
                        <div class="modal-header py-2 px-3 text-white" style="background: linear-gradient(135deg, #1e293b, #0f172a); border-bottom: 1px solid #334155;">
                            <div class="d-flex align-items-center">
                                <i class="fas fa-vr-cardboard text-warning fa-lg mr-2"></i>
                                <div>
                                    <h5 class="modal-title font-weight-bold mb-0" style="font-size: 1.05rem;">
                                        新北市 360° 實景導覽圖庫全覽
                                    </h5>
                                    <span class="small text-muted" style="color: #cbd5e1 !important; font-size: 0.75rem;">
                                        共收錄 {{ panoList.length }} 處高解析 3DVista 環景影像 (跨 {{ monthList.length }} 個拍攝期程)
                                    </span>
                                </div>
                            </div>
                            <button type="button" class="close text-white" data-dismiss="modal" aria-label="Close" style="opacity: 0.85;">
                                <span aria-hidden="true">&times;</span>
                            </button>
                        </div>
                        
                        <div class="modal-body p-3" style="background: #f8fafc; overflow-y: auto;">
                            <!-- 篩選列 -->
                            <div class="d-flex flex-column flex-md-row justify-content-between align-items-md-center mb-3" style="gap: 10px;">
                                <div class="d-flex flex-column flex-sm-row align-items-sm-center" style="gap: 8px;">
                                    <!-- 關鍵字搜尋 -->
                                    <div class="input-group input-group-sm" style="max-width: 260px;">
                                        <div class="input-group-prepend">
                                            <span class="input-group-text bg-white border-right-0"><i class="fas fa-search text-muted"></i></span>
                                        </div>
                                        <input type="text" class="form-control border-left-0" placeholder="搜尋場所名稱或關鍵字..." v-model="gallerySearchKey" />
                                        <div class="input-group-append" v-if="gallerySearchKey">
                                            <button class="btn btn-outline-secondary py-0" type="button" v-on:click="gallerySearchKey = ''">&times;</button>
                                        </div>
                                    </div>

                                    <!-- 拍攝期程月份篩選下拉選單 -->
                                    <div class="d-flex align-items-center" style="gap: 5px;">
                                        <span class="small font-weight-bold text-muted text-nowrap"><i class="fas fa-calendar-alt mr-1"></i>期程：</span>
                                        <select class="custom-select custom-select-sm" style="width: auto; min-width: 140px;" v-model="galleryActiveMonth">
                                            <option value="">-- 全部期程 (共 {{ panoList.length }} 處) --</option>
                                            <option v-for="m in monthList" :key="m.value" :value="m.value">
                                                {{ m.text }} ({{ m.count }}處)
                                            </option>
                                        </select>
                                    </div>
                                </div>

                                <!-- 行政區篩選標籤膠囊 -->
                                <div class="d-flex flex-wrap align-items-center" style="gap: 5px;">
                                    <button type="button" class="chip-btn" :class="{ active: galleryActiveTown === '' }" v-on:click="galleryActiveTown = ''">
                                        全部 ({{ panoList.length }})
                                    </button>
                                    <button v-for="t in townPanoStats" :key="t.name" type="button" class="chip-btn" :class="{ active: galleryActiveTown === t.name }" v-on:click="galleryActiveTown = t.name">
                                        {{ t.name }} ({{ t.count }})
                                    </button>
                                </div>
                            </div>

                            <!-- 卡片網格 (響應式 Grid) -->
                            <div class="row row-cols-1 row-cols-sm-2 row-cols-md-3 row-cols-lg-4 g-2" v-if="galleryFilteredPanoList.length > 0">
                                <div v-for="p in galleryFilteredPanoList" :key="p.id" class="col mb-3">
                                    <div class="gallery-card">
                                        <div>
                                            <div class="d-flex align-items-start justify-content-between mb-2">
                                                <div class="d-flex align-items-center flex-wrap" style="gap: 4px;">
                                                    <span class="badge badge-warning text-dark font-weight-bold" style="font-size: 0.72rem;">
                                                        <i class="fas fa-map-marker-alt mr-1"></i>{{ p.town || '新北市' }}
                                                    </span>
                                                    <span class="badge badge-info font-weight-bold" style="font-size: 0.68rem;" v-if="p.monthText">
                                                        <i class="fas fa-calendar-alt mr-1"></i>{{ p.monthText }}
                                                    </span>
                                                    <span class="badge badge-light border text-muted" style="font-size: 0.65rem;" v-if="p.history && p.history.length > 0" :title="'含 ' + p.history.length + ' 個歷史期程'">
                                                        <i class="fas fa-history mr-1"></i>含{{ p.history.length }}歷次
                                                    </span>
                                                </div>
                                                <span class="badge badge-light border text-muted" style="font-size: 0.68rem;" v-if="p.lat">
                                                    有定位
                                                </span>
                                            </div>
                                            <div class="gallery-card-title" :title="p.title">
                                                {{ p.title }}
                                            </div>
                                            <div class="gallery-card-addr text-truncate mb-3" :title="p.addr || '無地址紀錄'">
                                                {{ p.addr || '新北市轄區' }}
                                            </div>
                                        </div>
                                        <div class="d-flex" style="gap: 6px;">
                                            <button type="button" class="btn btn-warning btn-sm text-white font-weight-bold flex-fill py-1" style="font-size: 0.75rem;" v-on:click="openPanoFromGallery(p)">
                                                <i class="fas fa-play mr-1"></i>看 360
                                            </button>
                                            <button type="button" class="btn btn-outline-primary btn-sm flex-fill py-1 font-weight-bold" style="font-size: 0.75rem;" v-on:click="locatePanoFromGallery(p)" v-if="p.lat">
                                                <i class="fas fa-crosshairs mr-1"></i>環域定位
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div v-else class="text-center py-5 text-muted">
                                <i class="fas fa-folder-open fa-3x mb-3 text-black-50"></i>
                                <div>查無符合條件之 360 環景場所</div>
                            </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- 資料庫與系統診斷 Modal -->
            <div class="modal fade" id="debugModal" tabindex="-1" role="dialog" aria-hidden="true">
                <div class="modal-dialog modal-dialog-centered modal-lg" role="document">
                    <div class="modal-content" style="border-radius: 12px; overflow: hidden;">
                        <div class="modal-header bg-dark text-white py-2 px-3">
                            <h5 class="modal-title font-weight-bold" style="font-size: 1rem;">
                                <i class="fas fa-stethoscope text-info mr-2"></i>環域分析系統與資料庫診斷
                            </h5>
                            <button type="button" class="close text-white" data-dismiss="modal" aria-label="Close">
                                <span aria-hidden="true">&times;</span>
                            </button>
                        </div>
                        <div class="modal-body p-3" style="font-size: 0.85rem; max-height: 70vh; overflow-y: auto;">
                            <div v-if="debugLoading" class="text-center py-4 text-muted">
                                <i class="fas fa-spinner fa-spin fa-2x mb-2 text-primary"></i>
                                <div>正在探測資料庫結構與連線…</div>
                            </div>
                            <div v-else-if="debugInfo">
                                <div class="alert alert-info py-2 px-3 mb-3">
                                    <b><i class="fas fa-database mr-1"></i>資料庫連線：</b>
                                    <span class="badge" :class="debugInfo.DbConnected ? 'badge-success' : 'badge-danger'">
                                        {{ debugInfo.DbConnected ? '連線成功' : '連線失敗' }}
                                    </span>
                                    <span class="ml-2">{{ debugInfo.DbMessage }}</span>
                                </div>

                                <div class="card mb-3">
                                    <div class="card-header py-1 px-3 bg-light font-weight-bold">
                                        <i class="fas fa-table mr-1 text-primary"></i>資料表欄位動態探測 (Schema Detection)
                                    </div>
                                    <div class="card-body p-2">
                                        <table class="table table-sm table-bordered mb-0">
                                            <tbody>
                                                <tr>
                                                    <td style="width: 35%;">FAC_Main 資料表</td>
                                                    <td>
                                                        <span class="badge" :class="debugInfo.DetectedSchema.FacTableExists ? 'badge-success' : 'badge-danger'">
                                                            {{ debugInfo.DetectedSchema.FacTableExists ? '存在' : '不存在' }}
                                                        </span>
                                                    </td>
                                                </tr>
                                                <tr>
                                                    <td>X / Y 坐標欄位</td>
                                                    <td><b>{{ debugInfo.DetectedSchema.FacXCol }}</b> / <b>{{ debugInfo.DetectedSchema.FacYCol }}</b></td>
                                                </tr>
                                                <tr>
                                                    <td>地址 / 類型欄位</td>
                                                    <td>{{ debugInfo.DetectedSchema.FacAddrCol }} / {{ debugInfo.DetectedSchema.FacTypeCol }}</td>
                                                </tr>
                                                <tr>
                                                    <td>Bare_Main 裸露地表</td>
                                                    <td>
                                                        <span class="badge" :class="debugInfo.DetectedSchema.BareTableExists ? 'badge-success' : 'badge-secondary'">
                                                            {{ debugInfo.DetectedSchema.BareTableExists ? '存在' : '不存在 (已安全略過)' }}
                                                        </span>
                                                    </td>
                                                </tr>
                                                <tr>
                                                    <td>工廠總筆數 / 有座標筆數</td>
                                                    <td><b>{{ debugInfo.TotalFacCount }}</b> 筆 / <b>{{ debugInfo.FacWithCoordCount }}</b> 筆</td>
                                                </tr>
                                                <tr>
                                                    <td>360 環景圖資數量</td>
                                                    <td><b>{{ debugInfo.PanoCount }}</b> 筆目錄</td>
                                                </tr>
                                                <tr>
                                                    <td>新北市各級學校空間圖資</td>
                                                    <td class="d-flex align-items-center justify-content-between">
                                                        <span><b>{{ debugInfo.SchoolCount || 0 }}</b> 所學校 (含幼兒園~大專)</span>
                                                        <button type="button" class="btn btn-xs btn-outline-primary py-0 px-2 font-weight-bold" style="font-size: 0.72rem;" v-on:click="syncSchoolsToDb" :disabled="syncingSchools">
                                                            <i class="fas fa-database mr-1"></i>{{ syncingSchools ? '寫入中...' : '同步建表至資料庫' }}
                                                        </button>
                                                    </td>
                                                </tr>
                                            </tbody>
                                        </table>
                                    </div>
                                </div>

                                <div class="card mb-0" v-if="debugInfo.SampleFacs && debugInfo.SampleFacs.length > 0">
                                    <div class="card-header py-1 px-3 bg-light font-weight-bold">
                                        <i class="fas fa-map-pin mr-1 text-danger"></i>前 3 筆抽樣場所座標驗證
                                    </div>
                                    <div class="card-body p-2">
                                        <div v-for="s in debugInfo.SampleFacs" :key="s.Id" class="mb-2 pb-2 border-bottom">
                                            <div class="font-weight-bold text-dark">{{ s.Name }} ({{ s.Id }})</div>
                                            <div class="text-muted small">
                                                原始坐標：X={{ s.RawX }}, Y={{ s.RawY }}<br/>
                                                換算 WGS84：Lat={{ s.Wgs84Lat }}, Lng={{ s.Wgs84Lng }}
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="modal-footer py-2 px-3">
                            <button type="button" class="btn btn-sm btn-secondary" data-dismiss="modal">關閉</button>
                            <button type="button" class="btn btn-sm btn-primary" v-on:click="fetchDebugInfo">
                                <i class="fas fa-sync-alt mr-1"></i>重新整理
                            </button>
                        </div>
                    </div>
                </div>
            </div>

            <!-- 固定逸散源距離各級學校分析清冊 Excel 匯出 Modal -->
            <div class="modal fade" id="schoolExportModal" tabindex="-1" role="dialog" aria-hidden="true">
                <div class="modal-dialog modal-dialog-centered" role="document">
                    <div class="modal-content" style="border-radius: 14px; overflow: hidden;">
                        <div class="modal-header py-2 px-3 text-white" style="background: linear-gradient(135deg, #059669, #047857);">
                            <h5 class="modal-title font-weight-bold mb-0" style="font-size: 1rem;">
                                <i class="fas fa-file-excel mr-2"></i>匯出「固定逸散源距離各級學校」敏感度清冊
                            </h5>
                            <button type="button" class="close text-white" data-dismiss="modal" aria-label="Close">
                                <span aria-hidden="true">&times;</span>
                            </button>
                        </div>
                        <div class="modal-body p-3" style="font-size: 0.85rem; background: #f8fafc;">
                            <div class="alert alert-success py-2 px-3 mb-3 small">
                                <i class="fas fa-info-circle mr-1"></i>
                                系統已載入新北市各級學校（含<b>幼兒園、國小、國中、高中職、大專校院</b>共 504 校區），以 TWD97 二度分帶計算<b>點到點直線距離</b>，並自動標記紅/橘燈重點工廠。
                            </div>

                            <!-- 匯出範圍模式 -->
                            <div class="form-group mb-3">
                                <label class="font-weight-bold text-dark mb-1">1. 選擇匯出資料範圍：</label>
                                <div class="custom-control custom-radio mb-2">
                                    <input type="radio" id="expModeBuffer" name="expMode" class="custom-control-input" value="buffer" v-model="exportConfig.mode" />
                                    <label class="custom-control-label font-weight-bold text-dark" for="expModeBuffer" style="cursor: pointer;">
                                        當前環域範圍內之固定源 (中心半徑 {{ currentRadius }}m，共 {{ summary.FacCount || 0 }} 家工廠)
                                    </label>
                                </div>
                                <div class="custom-control custom-radio">
                                    <input type="radio" id="expModePriorityAll" name="expMode" class="custom-control-input" value="priority_all" v-model="exportConfig.mode" />
                                    <label class="custom-control-label font-weight-bold text-danger" for="expModePriorityAll" style="cursor: pointer;">
                                        全區/全新北市「鄰近學校重點列管工廠」專案清冊 (距學校 ≤ 警戒距離)
                                    </label>
                                </div>
                            </div>

                            <!-- 行政區篩選 (當選取全區模式時可指定特定行政區或全新北市) -->
                            <div class="form-group mb-3">
                                <label class="font-weight-bold text-dark mb-1">2. 行政區篩選：</label>
                                <select class="form-control form-control-sm" v-model="exportConfig.town">
                                    <option value="">-- 全新北市 (不限行政區) --</option>
                                    <option v-for="t in townList" :key="t.no" :value="t.name">{{ t.name }}</option>
                                </select>
                            </div>

                            <!-- 重點工廠警戒距離門檻 -->
                            <div class="form-group mb-3">
                                <label class="font-weight-bold text-dark mb-1">3. 重點工廠警戒距離門檻：</label>
                                <div class="d-flex align-items-center" style="gap: 8px;">
                                    <select class="form-control form-control-sm" v-model.number="exportConfig.priorityThreshold" style="max-width: 180px;">
                                        <option :value="100">≤ 100 公尺 (極高敏)</option>
                                        <option :value="200">≤ 200 公尺</option>
                                        <option :value="300">≤ 300 公尺 (建議標準)</option>
                                        <option :value="500">≤ 500 公尺 (擴大警戒)</option>
                                        <option :value="1000">≤ 1,000 公尺</option>
                                    </select>
                                    <div class="custom-control custom-checkbox" v-if="exportConfig.mode === 'buffer'">
                                        <input type="checkbox" class="custom-control-input" id="chkExpOnlyPri" v-model="exportConfig.onlyPriority" />
                                        <label class="custom-control-label small font-weight-bold text-danger" for="chkExpOnlyPri" style="cursor: pointer;">
                                            僅匯出重點工廠
                                        </label>
                                    </div>
                                </div>
                            </div>

                            <!-- 學校學制範圍 -->
                            <div class="form-group mb-1">
                                <label class="font-weight-bold text-dark mb-1">4. 比對學校學制範圍：</label>
                                <select class="form-control form-control-sm" v-model="exportConfig.schoolLevels">
                                    <option value="">全部學制 (含幼兒園、國小、國中、高中職、大專校院)</option>
                                    <option value="幼兒園">僅比對：幼兒園 (含國中小附設幼兒園)</option>
                                    <option value="幼兒園,國小">僅比對：幼兒園 + 國小 (學齡前與學童敏感受體)</option>
                                    <option value="國小">僅比對：國小</option>
                                    <option value="國中">僅比對：國中</option>
                                    <option value="高中職">僅比對：高中職</option>
                                    <option value="大專校院">僅比對：大專校院</option>
                                </select>
                            </div>
                        </div>
                        <div class="modal-footer py-2 px-3 bg-light d-flex justify-content-between">
                            <button type="button" class="btn btn-sm btn-secondary" data-dismiss="modal">取消</button>
                            <button type="button" class="btn btn-sm btn-success font-weight-bold px-3" v-on:click="triggerExportSchoolExcel">
                                <i class="fas fa-download mr-1"></i>立即下載 Excel 清冊 (.xls)
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </form>

    <!-- 本地核心腳本庫 (嚴格禁止外網 CDN) -->
    <script src="../Scripts/jquery-3.7.1.min.js"></script>
    <script src="../Scripts/bootstrap.bundle.min.js"></script>
    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>
    <script src="../Scripts/leaflet/leaflet.js"></script>

    <script>
        (function () {
            var API_URL = 'BufferHandler.ashx';

            // 全世界大外框坐標 (用於反向挖洞遮罩)
            var WORLD_RING = [
                [-90, -180],
                [-90, 180],
                [90, 180],
                [90, -180],
                [-90, -180]
            ];

            var app = Vue.createApp({
                data: function () {
                    return {
                        // 手機版切換 Tab ('map' | 'panel')
                        mobileTab: 'map',

                        // 基礎地圖與定位 (預設新北市中心)
                        centerLat: 25.0116,
                        centerLng: 121.4658,
                        centerCoordStr: '25.0116, 121.4658',
                        currentRadius: 500,
                        townList: [],
                        selectedTownNo: '',
                        selectedTownName: '',

                        // 新北市行政區邊界 GeoJSON
                        townGeoJson: null,
                        maskLayer: null,
                        townBoundaryLayer: null,

                        // 搜尋
                        searchKey: '',
                        searching: false,
                        searchResults: [],

                        // 圖層與篩選 (預設四種皆勾選：工廠、裸露地、360環景、各級學校)
                        layerOptions: ['fac', 'bare', 'pano', 'school'],
                        schoolLevelFilter: '',
                        priorityThreshold: 300,
                        onlyPriorityFilter: false,

                        // 結果與統計
                        loading: false,
                        resultList: [],
                        summary: { Total: 0, FacCount: 0, BareCount: 0, PanoCount: 0, SchoolCount: 0, PriorityFacCount: 0 },
                        industrySummary: [],
                        resultViewMode: 'list',
                        activeFilterIndustry: '',
                        expandedIndustries: {},
                        selectedItemId: '',
                        dbError: '',

                        // 學校距離敏感度清冊 Excel 匯出設定
                        exportConfig: {
                            mode: 'buffer',
                            town: '',
                            priorityThreshold: 300,
                            onlyPriority: false,
                            schoolLevels: ''
                        },
                        syncingSchools: false,

                        // 360 環景導覽
                        panoList: [],
                        panoActiveTown: '',
                        showPanoMapPins: true,
                        currentPanoTitle: '',
                        currentPanoUrl: '',
                        currentPanoOriginalUrl: '',
                        currentPanoMonth: '',
                        currentPanoMonthText: '',
                        selectedPanoVersionUrl: '',
                        currentPanoHistoryList: [],
                        panoLoading: false,

                        // 全覽圖庫 Modal 與月份期程版本控制
                        monthList: [],
                        galleryActiveMonth: '',
                        gallerySearchKey: '',
                        galleryActiveTown: '',

                        // 場所全能履歷 Modal (許可證與巡查紀錄)
                        profileLoading: false,
                        profileData: null,
                        profileTab: 'license',
                        profileFacId: '',
                        profileFacName: '',
                        profileCNo: '',

                        // 診斷 Modal
                        debugLoading: false,
                        debugInfo: null
                    };
                },
                computed: {
                    // 當前顯示之場所清單 (支援單一行業聚焦與重點工廠過濾)
                    displayPlacesList: function () {
                        var self = this;
                        return self.resultList.filter(function (item) {
                            if (self.onlyPriorityFilter && !item.isPriorityFac) return false;
                            if (self.activeFilterIndustry && item.industry !== self.activeFilterIndustry) return false;
                            return true;
                        });
                    },

                    // 當前可視 360 圖標數量 (若選取特定行政區則只統計該區)
                    visiblePanoPinsCount: function () {
                        var self = this;
                        var currentTownKey = self.selectedTownName ? self.selectedTownName.replace('區', '') : '';
                        if (!currentTownKey) return self.panoList.length;
                        return self.panoList.filter(function (p) {
                            var str = (p.town || '') + ' ' + (p.addr || '') + ' ' + (p.title || '');
                            return str.indexOf(currentTownKey) !== -1;
                        }).length;
                    },

                    // 計算各行政區 360 數量統計 (供全覽圖庫 Modal 標籤使用)
                    townPanoStats: function () {
                        var counts = {};
                        this.panoList.forEach(function (p) {
                            var t = p.town || '新北其他';
                            counts[t] = (counts[t] || 0) + 1;
                        });
                        var arr = [];
                        for (var key in counts) {
                            arr.push({ name: key, count: counts[key] });
                        }
                        arr.sort(function (a, b) { return b.count - a.count; });
                        return arr;
                    },

                    // 全覽圖庫 Modal 過濾後的 360 清單 (整合行政區、期程月份與關鍵字)
                    galleryFilteredPanoList: function () {
                        var self = this;
                        return self.panoList.filter(function (p) {
                            var matchTown = !self.galleryActiveTown || (p.town === self.galleryActiveTown);
                            var matchMonth = true;
                            if (self.galleryActiveMonth) {
                                if (p.month === self.galleryActiveMonth) {
                                    matchMonth = true;
                                } else if (p.history && p.history.length > 0) {
                                    matchMonth = p.history.some(function (h) { return h.Month === self.galleryActiveMonth; });
                                } else {
                                    matchMonth = false;
                                }
                            }
                            var matchKey = true;
                            if (self.gallerySearchKey && self.gallerySearchKey.trim()) {
                                var q = self.gallerySearchKey.trim().toLowerCase();
                                matchKey = (p.title && p.title.toLowerCase().indexOf(q) >= 0) || (p.addr && p.addr.toLowerCase().indexOf(q) >= 0);
                            }
                            return matchTown && matchMonth && matchKey;
                        });
                    }
                },
                mounted: function () {
                    this.initMap();
                    this.loadTownGeoJson();
                    this.loadInitialData();
                    this.loadPanoList();
                },
                methods: {
                    // 手機版 Tab 切換
                    switchMobileTab: function (tab) {
                        this.mobileTab = tab;
                        if (tab === 'map') {
                            setTimeout(function () {
                                if (window.map) {
                                    window.map.invalidateSize();
                                }
                            }, 150);
                        }
                    },

                    // 初始化 Leaflet 地圖
                    initMap: function () {
                        var self = this;
                        var defaultCenter = [self.centerLat, self.centerLng];

                        window.map = L.map('map', {
                            center: defaultCenter,
                            zoom: 14,
                            zoomControl: true,
                            attributionControl: false
                        });

                        // 台灣國土測繪中心 (NLSC) 臺灣通用電子地圖
                        L.tileLayer('https://wmts.nlsc.gov.tw/wmts/EMAP/default/GoogleMapsCompatible/{z}/{y}/{x}', {
                            maxZoom: 19,
                            minZoom: 9
                        }).addTo(window.map);

                        window.markerLayerGroup = L.layerGroup().addTo(window.map);
                        window.panoMapLayerGroup = L.layerGroup().addTo(window.map);
                        window.schoolLineLayerGroup = L.layerGroup().addTo(window.map);

                        // 即時渲染中心標記與半徑圓形
                        self.renderCenterMarkerImmediate();

                        // 點擊地圖即時選點 (0ms 零延遲換位)
                        window.map.on('click', function (e) {
                            self.centerLat = parseFloat(e.latlng.lat.toFixed(6));
                            self.centerLng = parseFloat(e.latlng.lng.toFixed(6));
                            self.centerCoordStr = self.centerLat + ', ' + self.centerLng;

                            self.renderCenterMarkerImmediate();
                            self.refreshBuffer();
                        });
                    },

                    // 載入新北市行政區邊界 GeoJSON (用於反向挖洞灰底遮罩)
                    loadTownGeoJson: function () {
                        var self = this;
                        axios.get('../NDVI/Data/ntpc_towns.json').then(function (res) {
                            if (res.data) {
                                self.townGeoJson = res.data;
                            }
                        }).catch(function (err) {
                            console.warn('載入邊界 GeoJSON 失敗:', err);
                        });
                    },

                    // 0ms 零延遲即時繪製中心紅色大標記與水波紋圓圈
                    renderCenterMarkerImmediate: function () {
                        var self = this;
                        if (!window.map) return;

                        var latlng = [self.centerLat, self.centerLng];

                        var centerHtml = '<div class="center-marker-wrapper">' +
                            '<div class="center-ripple"></div>' +
                            '<div class="center-pin-head"><i class="fas fa-map-marker-alt"></i></div>' +
                            '</div>';

                        var centerIcon = L.divIcon({
                            className: 'center-custom-pin',
                            html: centerHtml,
                            iconSize: [36, 48],
                            iconAnchor: [18, 48]
                        });

                        if (window.centerMarker) {
                            window.centerMarker.setLatLng(latlng);
                            window.centerMarker.setIcon(centerIcon);
                        } else {
                            window.centerMarker = L.marker(latlng, { 
                                icon: centerIcon, 
                                zIndexOffset: 2000 
                            }).addTo(window.map);
                        }

                        window.centerMarker.bindPopup('<div style="text-align:center;padding:4px;"><b><i class="fas fa-crosshairs text-danger mr-1"></i>環域中心點</b><br/><span style="font-size:12px;color:#64748b;">經緯度：' + self.centerCoordStr + '</span></div>');

                        if (window.bufferCircle) {
                            window.bufferCircle.setLatLng(latlng);
                            window.bufferCircle.setRadius(self.currentRadius);
                        } else {
                            window.bufferCircle = L.circle(latlng, {
                                radius: self.currentRadius,
                                color: '#0284c7',
                                fillColor: '#0284c7',
                                fillOpacity: 0.12,
                                weight: 2,
                                dashArray: '6, 6'
                            }).addTo(window.map);
                        }
                    },

                    // 載入初始行政區與預設值
                    loadInitialData: function () {
                        var self = this;
                        axios.get(API_URL + '?action=getinit').then(function (res) {
                            if (res.data && res.data.Success) {
                                self.townList = res.data.Towns || [];
                                self.currentRadius = res.data.DefaultRadius || 500;
                                if (res.data.MonthList && res.data.MonthList.length > 0) {
                                    self.monthList = res.data.MonthList;
                                }
                                if (res.data.Layers && res.data.Layers.length > 0) {
                                    self.layerOptions = res.data.Layers;
                                }
                                self.refreshBuffer();
                            }
                        }).catch(function (err) {
                            console.error('初始化失敗:', err);
                        });
                    },

                    // 載入現有已就緒的 360 環景清單
                    loadPanoList: function () {
                        var self = this;
                        axios.get(API_URL + '?action=getpanolist').then(function (res) {
                            if (res.data && res.data.Success) {
                                self.panoList = res.data.Data || [];
                                if (res.data.MonthList && res.data.MonthList.length > 0) {
                                    self.monthList = res.data.MonthList;
                                }
                                self.renderPanoMapPins();
                            }
                        }).catch(function (err) {
                            console.error('載入 360 清單失敗:', err);
                        });
                    },

                    // 在地圖上繪製 360 金色相機圖標圖層 (動態與選定行政區連動)
                    renderPanoMapPins: function () {
                        var self = this;
                        if (!window.panoMapLayerGroup) return;
                        window.panoMapLayerGroup.clearLayers();

                        if (!self.showPanoMapPins) return;

                        var currentTownKey = self.selectedTownName ? self.selectedTownName.replace('區', '') : '';

                        self.panoList.forEach(function (p) {
                            if (!p.lat || !p.lng) return;

                            // 若已選定特定行政區，則過濾僅繪製該行政區的 360 點位 (排除灰底遮罩外的其他區點位)
                            if (currentTownKey) {
                                var pStr = (p.town || '') + ' ' + (p.addr || '') + ' ' + (p.title || '');
                                if (pStr.indexOf(currentTownKey) === -1) {
                                    return;
                                }
                            }

                            var panoIconHtml = '<div style="background:linear-gradient(135deg,#f59e0b,#d97706);color:#fff;width:26px;height:26px;border-radius:50%;border:2px solid #fff;box-shadow:0 2px 6px rgba(0,0,0,0.35);display:flex;align-items:center;justify-content:center;font-size:12px;cursor:pointer;"><i class="fas fa-camera"></i></div>';
                            var panoPin = L.divIcon({
                                className: 'map-pano-pin',
                                html: panoIconHtml,
                                iconSize: [26, 26],
                                iconAnchor: [13, 13]
                            });

                            var marker = L.marker([p.lat, p.lng], { icon: panoPin }).addTo(window.panoMapLayerGroup);

                            var panoInfoText = '行政區：' + (p.town || '新北市');
                            if (p.monthText) {
                                panoInfoText += ' | 期程：' + p.monthText;
                            }
                            if (p.history && p.history.length > 0) {
                                panoInfoText += ' (含' + p.history.length + '歷次)';
                            }

                            var popupHtml = '<div style="min-width:220px;padding:2px;">' +
                                '<div style="font-weight:bold;font-size:13px;color:#b45309;margin-bottom:2px;"><i class="fas fa-camera mr-1"></i>' + p.title + '</div>' +
                                '<div style="font-size:11px;color:#64748b;margin-bottom:6px;">' + panoInfoText + '</div>' +
                                '<div class="d-flex" style="gap:4px;">' +
                                '<button type="button" class="btn btn-warning btn-sm text-white font-weight-bold flex-fill py-1" style="font-size:11px;" onclick="window.triggerOpenPanoDirect(\'' + p.id + '\')"><i class="fas fa-street-view mr-1"></i>看 360</button>' +
                                '<button type="button" class="btn btn-outline-primary btn-sm flex-fill py-1" style="font-size:11px;" onclick="window.triggerPanoBufferCenter(' + p.lat + ',' + p.lng + ')"><i class="fas fa-crosshairs mr-1"></i>環域定位</button>' +
                                '</div></div>';

                            marker.bindPopup(popupHtml);
                        });

                        window.triggerOpenPanoDirect = function (panoId) {
                            var target = null;
                            self.panoList.forEach(function (it) { if (it.id === panoId) target = it; });
                            if (target) self.openPanoDirect(target);
                        };

                        window.triggerPanoBufferCenter = function (lat, lng) {
                            self.centerLat = lat;
                            self.centerLng = lng;
                            self.centerCoordStr = lat + ', ' + lng;
                            self.renderCenterMarkerImmediate();
                            window.map.flyTo([lat, lng], 15);
                            self.refreshBuffer();
                        };
                    },

                    // 執行核心環域運算
                    refreshBuffer: function () {
                        var self = this;
                        self.loading = true;
                        self.dbError = '';
                        if (window.schoolLineLayerGroup) {
                            window.schoolLineLayerGroup.clearLayers();
                        }

                        var layersParam = self.layerOptions.join(',');
                        var url = API_URL + '?action=querybuffer&lat=' + self.centerLat + '&lng=' + self.centerLng +
                            '&radius=' + self.currentRadius +
                            '&layers=' + layersParam +
                            '&schoolLevels=' + encodeURIComponent(self.schoolLevelFilter || '') +
                            '&priorityThreshold=' + (self.priorityThreshold || 300);

                        axios.get(url).then(function (res) {
                            self.loading = false;
                            if (res.data && res.data.Success) {
                                self.resultList = res.data.Data || [];
                                self.summary = res.data.Summary || { Total: 0, FacCount: 0, BareCount: 0, PanoCount: 0, SchoolCount: 0, PriorityFacCount: 0 };
                                self.industrySummary = res.data.IndustrySummary || [];
                                self.activeFilterIndustry = '';
                                self.drawPlacesMarkers();

                                if (res.data.SchemaInfo && res.data.SchemaInfo.FacError) {
                                    self.dbError = '固定源查詢發生警告：' + res.data.SchemaInfo.FacError;
                                }
                            } else {
                                self.dbError = res.data ? res.data.Message : '後端回傳查詢失敗';
                            }
                        }).catch(function (err) {
                            self.loading = false;
                            self.dbError = '網路或伺服器連線異常：' + (err.message || err);
                            console.error('環域計算失敗:', err);
                        });
                    },

                    // 繪製周邊場所標記 Pin (整合重點工廠紅橘燈、各級學校學士帽、行業別聚焦與許可證巡查快捷調閱)
                    drawPlacesMarkers: function () {
                        var self = this;
                        window.markerLayerGroup.clearLayers();

                        var targetList = self.resultList;
                        if (self.onlyPriorityFilter) {
                            targetList = targetList.filter(function (item) {
                                return !!item.isPriorityFac;
                            });
                        }
                        if (self.activeFilterIndustry) {
                            targetList = targetList.filter(function (item) {
                                return item.industry === self.activeFilterIndustry;
                            });
                        }

                        targetList.forEach(function (item) {
                            if (!item.lat || !item.lng) return;
                            var p = [item.lat, item.lng];

                            var markerHtml = '';
                            if (item.typeKey === 'school') {
                                markerHtml = '<div style="background:linear-gradient(135deg,#8b5cf6,#6d28d9);color:#fff;width:28px;height:28px;border-radius:50%;border:2px solid #fff;box-shadow:0 3px 8px rgba(109,40,217,0.55);display:flex;align-items:center;justify-content:center;font-size:13px;"><i class="fas fa-graduation-cap"></i></div>';
                            } else if (item.typeKey === 'pano') {
                                markerHtml = '<div style="background:linear-gradient(135deg,#f59e0b,#d97706);color:#fff;width:28px;height:28px;border-radius:50%;border:2px solid #fff;box-shadow:0 3px 8px rgba(245,158,11,0.6);display:flex;align-items:center;justify-content:center;font-size:13px;"><i class="fas fa-camera"></i></div>';
                            } else if (item.typeKey === 'fac' && item.schoolRiskLevel === 'high') {
                                markerHtml = '<div style="background:linear-gradient(135deg,#ef4444,#b91c1c);color:#fff;width:26px;height:26px;border-radius:50%;border:2px solid #fff;box-shadow:0 0 0 3px rgba(239,68,68,0.45), 0 3px 8px rgba(0,0,0,0.4);display:flex;align-items:center;justify-content:center;font-size:11px;"><i class="fas fa-exclamation"></i></div>';
                            } else if (item.typeKey === 'fac' && item.schoolRiskLevel === 'medium') {
                                markerHtml = '<div style="background:linear-gradient(135deg,#f97316,#c2410c);color:#fff;width:24px;height:24px;border-radius:50%;border:2px solid #fff;box-shadow:0 0 0 2px rgba(249,115,22,0.4), 0 2px 6px rgba(0,0,0,0.35);display:flex;align-items:center;justify-content:center;font-size:11px;"><i class="fas fa-industry"></i></div>';
                            } else if (item.hasPano) {
                                markerHtml = '<div style="background:linear-gradient(135deg,#0284c7,#0b1f7d);color:#f59e0b;width:24px;height:24px;border-radius:50%;border:2px solid #fff;box-shadow:0 2px 6px rgba(0,0,0,0.35);display:flex;align-items:center;justify-content:center;font-size:12px;"><i class="fas fa-camera"></i></div>';
                            } else if (item.typeKey === 'fac') {
                                markerHtml = '<div style="background:#0284c7;width:18px;height:18px;border-radius:50%;border:2px solid #fff;box-shadow:0 1px 4px rgba(0,0,0,0.35);"></div>';
                            } else {
                                markerHtml = '<div style="background:#64748b;width:16px;height:16px;border-radius:50%;border:2px solid #fff;box-shadow:0 1px 4px rgba(0,0,0,0.35);"></div>';
                            }

                            var customIcon = L.divIcon({
                                className: 'place-custom-pin',
                                html: markerHtml,
                                iconSize: [28, 28],
                                iconAnchor: [14, 14]
                            });

                            var m = L.marker(p, { icon: customIcon }).addTo(window.markerLayerGroup);

                            var headerColor = item.typeKey === 'school' ? '#7c3aed' : (item.isPriorityFac ? '#ea580c' : '#059669');
                            var headerIcon = item.typeKey === 'school' ? 'fa-graduation-cap' : 'fa-industry';

                            var popupContent = '<div style="min-width:250px;padding:2px;">' +
                                '<div style="font-size:11px;font-weight:bold;color:' + headerColor + ';margin-bottom:2px;"><i class="fas ' + headerIcon + ' mr-1"></i>' + (item.industry || item.type) + '</div>' +
                                '<div style="font-weight:bold;font-size:14px;color:#0f172a;margin-bottom:3px;">' + item.name + '</div>' +
                                (item.cno ? '<div style="font-size:11px;color:#64748b;margin-bottom:2px;">' + (item.typeKey === 'school' ? '學制屬性：' : '管制編號：') + item.cno + '</div>' : '') +
                                '<div style="font-size:12px;color:#64748b;margin-bottom:2px;">距離中心：' + item.dist + ' 公尺</div>' +
                                '<div style="font-size:12px;color:#64748b;margin-bottom:6px;">地址：' + (item.addr || '無詳細地址紀錄') + '</div>';

                            if ((item.typeKey === 'fac' || item.typeKey === 'bare') && item.nearestSchoolName) {
                                var riskBg = item.schoolRiskLevel === 'high' ? '#fef2f2' : (item.schoolRiskLevel === 'medium' ? '#fff7ed' : '#f8fafc');
                                var riskBorder = item.schoolRiskLevel === 'high' ? '#fecaca' : (item.schoolRiskLevel === 'medium' ? '#fed7aa' : '#e2e8f0');
                                var riskColor = item.schoolRiskLevel === 'high' ? '#dc2626' : (item.schoolRiskLevel === 'medium' ? '#ea580c' : '#475569');
                                popupContent += '<div style="background:' + riskBg + ';border:1px solid ' + riskBorder + ';color:' + riskColor + ';border-radius:6px;padding:5px 8px;font-size:11px;margin-bottom:8px;cursor:pointer;" onclick="window.triggerDrawSchoolLine(\'' + item.id + '\')" title="點擊在地圖畫出與該校之直線連線">' +
                                    '<b><i class="fas fa-graduation-cap mr-1"></i>最近學校：</b>' + item.nearestSchoolName + ' (' + item.nearestSchoolLevel + ')<br/>' +
                                    '<b><i class="fas fa-ruler-horizontal mr-1"></i>直線距離：' + item.nearestSchoolDist + ' 公尺</b> <span style="text-decoration:underline;margin-left:4px;">[畫出連線]</span>' +
                                    '</div>';
                            }

                            if (item.typeKey === 'fac') {
                                popupContent += '<div class="d-flex mb-2" style="gap:4px;">' +
                                    '<button type="button" class="btn btn-primary btn-sm flex-fill py-1 font-weight-bold" style="font-size:11px;" onclick="window.triggerOpenFacProfile(\'' + item.id + '\', \'license\')"><i class="fas fa-file-contract mr-1"></i>許可證</button>' +
                                    '<button type="button" class="btn btn-outline-info btn-sm flex-fill py-1 font-weight-bold" style="font-size:11px;" onclick="window.triggerOpenFacProfile(\'' + item.id + '\', \'inspection\')"><i class="fas fa-clipboard-check mr-1"></i>巡查紀錄</button>' +
                                    '</div>';
                            } else if (item.typeKey === 'school') {
                                popupContent += '<button type="button" class="btn btn-sm btn-block text-white font-weight-bold py-1 mb-1" style="background:#7c3aed;font-size:11px;" onclick="window.triggerPanoBufferCenter(' + item.lat + ',' + item.lng + ')"><i class="fas fa-crosshairs mr-1"></i>以此學校為中心反查周邊工廠</button>';
                            }

                            if (item.hasPano) {
                                var panoBtnText = '開啟 360° 實景導覽' + (item.panoMonthText ? ' (' + item.panoMonthText + ')' : '');
                                if (item.panoHistory && item.panoHistory.length > 0) {
                                    panoBtnText += ' [含' + item.panoHistory.length + '歷次]';
                                }
                                popupContent += '<button type="button" class="btn btn-warning btn-sm btn-block text-white font-weight-bold py-1 mt-1" style="font-size:12px;" onclick="window.triggerOpenPano(\'' + item.id + '\')"><i class="fas fa-street-view mr-1"></i>' + panoBtnText + '</button>';
                            }
                            popupContent += '</div>';

                            m.bindPopup(popupContent);
                            m._fecItem = item;
                        });

                        window.triggerOpenPano = function (itemId) {
                            var target = null;
                            self.resultList.forEach(function (it) { if (it.id === itemId) target = it; });
                            if (target) self.openPano(target);
                        };

                        window.triggerOpenFacProfile = function (facId, tab) {
                            var target = null;
                            self.resultList.forEach(function (it) { if (it.id === facId) target = it; });
                            if (target) {
                                self.openFacProfile(target, tab);
                            } else {
                                self.openFacProfile({ id: facId, name: facId, cno: '' }, tab);
                            }
                        };

                        window.triggerDrawSchoolLine = function (itemId) {
                            var target = null;
                            self.resultList.forEach(function (it) { if (it.id === itemId) target = it; });
                            if (target) self.drawSchoolConnectionLine(target);
                        };
                    },

                    // 行業別分組互動輔助函式
                    toggleIndustry: function (indName) {
                        this.expandedIndustries[indName] = !this.expandedIndustries[indName];
                    },
                    isIndExpanded: function (indName) {
                        if (this.expandedIndustries[indName] === undefined) {
                            var idx = -1;
                            for (var i = 0; i < this.industrySummary.length; i++) {
                                if (this.industrySummary[i].name === indName) { idx = i; break; }
                            }
                            return idx < 2;
                        }
                        return !!this.expandedIndustries[indName];
                    },
                    getItemsByIndustry: function (indName) {
                        var self = this;
                        return this.resultList.filter(function (it) {
                            if (self.onlyPriorityFilter && !it.isPriorityFac) return false;
                            return it.industry === indName;
                        });
                    },
                    filterMapByIndustry: function (indName) {
                        if (this.activeFilterIndustry === indName) {
                            this.activeFilterIndustry = '';
                        } else {
                            this.activeFilterIndustry = indName;
                        }
                        this.drawPlacesMarkers();
                    },
                    clearIndustryFilter: function () {
                        this.activeFilterIndustry = '';
                        this.drawPlacesMarkers();
                    },

                    // 滑桿拖動即時更新圓形大小
                    onRadiusInput: function () {
                        if (window.bufferCircle) {
                            window.bufferCircle.setRadius(this.currentRadius);
                        }
                    },

                    // 改變半徑
                    setRadius: function (r) {
                        this.currentRadius = r;
                        this.renderCenterMarkerImmediate();
                        this.refreshBuffer();
                    },

                    // 行政區切換 (平滑飛躍至新北市該行政區中心 + 邊界高亮 + 反向灰底遮罩)
                    onTownChange: function () {
                        var self = this;
                        if (!self.selectedTownNo) {
                            self.clearTownSelection();
                            return;
                        }

                        var targetTown = null;
                        self.townList.forEach(function (item) {
                            if (item.no === self.selectedTownNo) targetTown = item;
                        });

                        if (!targetTown) return;
                        self.selectedTownName = targetTown.name;

                        // 同步左側 360 預設分類
                        self.panoActiveTown = targetTown.name;

                        self.centerLat = targetTown.lat;
                        self.centerLng = targetTown.lng;
                        self.centerCoordStr = targetTown.lat + ', ' + targetTown.lng;
                        self.renderCenterMarkerImmediate();

                        self.renderTownMask(targetTown.name);
                        self.renderPanoMapPins();
                        self.refreshBuffer();

                        if (window.innerWidth < 768) {
                            self.switchMobileTab('map');
                        }
                    },

                    // 清除行政區選取與遮罩
                    clearTownSelection: function () {
                        this.selectedTownNo = '';
                        this.selectedTownName = '';
                        this.panoActiveTown = '';
                        if (this.maskLayer) {
                            window.map.removeLayer(this.maskLayer);
                            this.maskLayer = null;
                        }
                        if (this.townBoundaryLayer) {
                            window.map.removeLayer(this.townBoundaryLayer);
                            this.townBoundaryLayer = null;
                        }
                        this.renderPanoMapPins();
                        this.refreshBuffer();
                    },

                    // 核心：反向灰底遮罩 (Spotlight Inverted Mask) 與邊界高亮繪製
                    renderTownMask: function (townName) {
                        var self = this;
                        if (!self.townGeoJson || !self.townGeoJson.features) return;

                        if (self.maskLayer) {
                            window.map.removeLayer(self.maskLayer);
                            self.maskLayer = null;
                        }
                        if (self.townBoundaryLayer) {
                            window.map.removeLayer(self.townBoundaryLayer);
                            this.townBoundaryLayer = null;
                        }

                        var targetFeature = null;
                        self.townGeoJson.features.forEach(function (f) {
                            if (f.properties && f.properties.name === townName) {
                                targetFeature = f;
                            }
                        });

                        if (!targetFeature) return;

                        // 1. 繪製邊界高亮線條
                        self.townBoundaryLayer = L.geoJSON(targetFeature, {
                            style: {
                                color: '#0099e5',
                                weight: 3.5,
                                opacity: 0.95,
                                fillColor: '#0284c7',
                                fillOpacity: 0.05,
                                dashArray: '6, 6'
                            }
                        }).addTo(window.map);

                        // 2. 建立反向遮罩：全世界大框 - 行政區多邊形 (挖洞效果)
                        var holes = [];
                        if (targetFeature.geometry.type === 'Polygon') {
                            var ring = targetFeature.geometry.coordinates[0].map(function (c) {
                                return [c[1], c[0]];
                            });
                            holes.push(ring);
                        } else if (targetFeature.geometry.type === 'MultiPolygon') {
                            targetFeature.geometry.coordinates.forEach(function (poly) {
                                var ring = poly[0].map(function (c) {
                                    return [c[1], c[0]];
                                });
                                holes.push(ring);
                            });
                        }

                        var maskCoords = [WORLD_RING].concat(holes);
                        self.maskLayer = L.polygon(maskCoords, {
                            fillColor: '#0f172a',
                            fillOpacity: 0.42,
                            stroke: false,
                            interactive: false
                        }).addTo(window.map);

                        window.map.fitBounds(self.townBoundaryLayer.getBounds(), { padding: [35, 35], maxZoom: 15 });
                    },

                    // 關鍵字搜尋反查
                    searchTarget: function () {
                        var self = this;
                        if (!self.searchKey || !self.searchKey.trim()) return;
                        self.searching = true;
                        axios.get(API_URL + '?action=searchtarget&q=' + encodeURIComponent(self.searchKey.trim())).then(function (res) {
                            self.searching = false;
                            if (res.data && res.data.Success) {
                                self.searchResults = res.data.Data || [];
                                if (self.searchResults.length === 0) {
                                    alert('查無符合之場址或關鍵字！');
                                }
                            } else {
                                alert('搜尋異常：' + (res.data ? res.data.Message : '未知錯誤'));
                            }
                        }).catch(function (err) {
                            self.searching = false;
                            alert('搜尋通訊失敗：' + (err.message || err));
                        });
                    },

                    // 選取搜尋目標設為中心
                    selectSearchItem: function (item) {
                        this.centerLat = item.lat;
                        this.centerLng = item.lng;
                        this.centerCoordStr = item.lat + ', ' + item.lng;
                        this.searchResults = [];
                        this.renderCenterMarkerImmediate();
                        window.map.flyTo([item.lat, item.lng], 15, { duration: 0.8 });
                        this.refreshBuffer();

                        if (window.innerWidth < 768) {
                            this.switchMobileTab('map');
                        }
                    },

                    // 瀏覽器 GPS 定位
                    getCurrentLocation: function () {
                        var self = this;
                        if (!navigator.geolocation) {
                            alert('您的瀏覽器不支援 GPS 地理定位');
                            return;
                        }
                        navigator.geolocation.getCurrentPosition(function (pos) {
                            self.centerLat = parseFloat(pos.coords.latitude.toFixed(6));
                            self.centerLng = parseFloat(pos.coords.longitude.toFixed(6));
                            self.centerCoordStr = self.centerLat + ', ' + self.centerLng;
                            self.renderCenterMarkerImmediate();
                            window.map.flyTo([self.centerLat, self.centerLng], 15);
                            self.refreshBuffer();

                            if (window.innerWidth < 768) {
                                self.switchMobileTab('map');
                            }
                        }, function (err) {
                            alert('無法取得目前位置：' + err.message);
                        });
                    },

                    // 點擊左側清單項目聯動地圖
                    focusItem: function (item) {
                        this.selectedItemId = item.id;
                        if (!item.lat || !item.lng) return;

                        if (window.innerWidth < 768) {
                            this.switchMobileTab('map');
                        }

                        window.map.panTo([item.lat, item.lng]);

                        window.markerLayerGroup.eachLayer(function (layer) {
                            if (layer._fecItem && layer._fecItem.id === item.id) {
                                layer.openPopup();
                            }
                        });
                    },

                    // 開啟場所全能履歷 Modal (許可證與巡查紀錄)
                    openFacProfile: function (item, tab) {
                        var self = this;
                        self.profileFacId = item.id;
                        self.profileFacName = item.name;
                        self.profileCNo = item.cno || '';
                        self.profileTab = tab || 'license';
                        self.profileLoading = true;
                        self.profileData = null;
                        $('#facProfileModal').modal('show');

                        axios.get(API_URL + '?action=getfacprofile&facId=' + encodeURIComponent(item.id)).then(function (res) {
                            self.profileLoading = false;
                            if (res.data && res.data.Success) {
                                self.profileData = res.data;
                            } else {
                                alert('取得場所資料失敗：' + (res.data ? res.data.Message : '未知錯誤'));
                            }
                        }).catch(function (err) {
                            self.profileLoading = false;
                            alert('通訊異常：' + (err.message || err));
                        });
                    },

                    // 開啟 360 環景導覽 Modal (自動帶入期程與歷次版本)
                    openPano: function (item) {
                        this.currentPanoTitle = item.name;
                        this.panoLoading = true;
                        this.currentPanoMonth = item.panoMonth || '';
                        this.currentPanoMonthText = item.panoMonthText || '';
                        this.currentPanoOriginalUrl = item.panoUrl;
                        this.currentPanoUrl = item.panoUrl;
                        this.selectedPanoVersionUrl = item.panoUrl;
                        this.currentPanoHistoryList = item.panoHistory || [];
                        $('#panoModal').modal('show');
                    },

                    // 從全覽圖庫或地圖圖標直接開啟
                    openPanoDirect: function (p) {
                        this.currentPanoTitle = p.title;
                        this.panoLoading = true;
                        this.currentPanoMonth = p.month || '';
                        this.currentPanoMonthText = p.monthText || '';
                        this.currentPanoOriginalUrl = p.url;
                        this.currentPanoUrl = p.url;
                        this.selectedPanoVersionUrl = p.url;
                        this.currentPanoHistoryList = p.history || [];
                        $('#panoModal').modal('show');
                    },

                    // 切換 360 歷次歷史期程
                    switchPanoVersion: function () {
                        if (this.selectedPanoVersionUrl && this.selectedPanoVersionUrl !== this.currentPanoUrl) {
                            this.panoLoading = true;
                            this.currentPanoUrl = this.selectedPanoVersionUrl;
                        }
                    },

                    // 關閉 360 導覽時清空 iframe 釋放記憶體
                    closePano: function () {
                        this.currentPanoUrl = '';
                        this.currentPanoOriginalUrl = '';
                        this.selectedPanoVersionUrl = '';
                        this.currentPanoHistoryList = [];
                        this.currentPanoMonth = '';
                        this.currentPanoMonthText = '';
                        this.panoLoading = false;
                        $('#panoModal').modal('hide');
                    },

                    // 從卡片一鍵定位並開啟環域
                    locatePanoDirect: function (p) {
                        if (!p.lat || !p.lng) return;
                        this.centerLat = p.lat;
                        this.centerLng = p.lng;
                        this.centerCoordStr = p.lat + ', ' + p.lng;
                        this.renderCenterMarkerImmediate();
                        window.map.flyTo([p.lat, p.lng], 15);
                        this.refreshBuffer();

                        if (window.innerWidth < 768) {
                            this.switchMobileTab('map');
                        }
                    },

                    // 開啟全覽圖庫 Modal
                    openGalleryModal: function () {
                        this.gallerySearchKey = '';
                        this.galleryActiveTown = this.selectedTownName || this.panoActiveTown || '';
                        $('#panoGalleryModal').modal('show');
                    },

                    // 從全覽圖庫開啟 360 導覽
                    openPanoFromGallery: function (p) {
                        this.openPanoDirect(p);
                    },

                    // 從全覽圖庫進行環域定位
                    locatePanoFromGallery: function (p) {
                        $('#panoGalleryModal').modal('hide');
                        this.locatePanoDirect(p);
                    },

                    // 切換學校學制範圍篩選
                    setSchoolLevelFilter: function (lvl) {
                        this.schoolLevelFilter = lvl;
                        this.refreshBuffer();
                    },

                    // 切換「僅顯示重點工廠」快速篩選
                    toggleOnlyPriorityFilter: function () {
                        this.onlyPriorityFilter = !this.onlyPriorityFilter;
                        this.drawPlacesMarkers();
                    },

                    // 將各級學校設為環域中心，反查該學校周邊所有列管工廠
                    setSchoolAsCenter: function (schoolItem) {
                        if (!schoolItem || !schoolItem.lat || !schoolItem.lng) return;
                        this.centerLat = schoolItem.lat;
                        this.centerLng = schoolItem.lng;
                        this.centerCoordStr = schoolItem.lat + ', ' + schoolItem.lng;
                        this.renderCenterMarkerImmediate();
                        window.map.flyTo([schoolItem.lat, schoolItem.lng], 15, { duration: 0.7 });
                        this.refreshBuffer();

                        if (window.innerWidth < 768) {
                            this.switchMobileTab('map');
                        }
                    },

                    // 在地圖上繪製「固定逸散源 <-> 最近學校」點對點直線距離連線與標籤
                    drawSchoolConnectionLine: function (item) {
                        if (!item || !item.lat || !item.lng || !item.nearestSchoolLat || !item.nearestSchoolLng) return;

                        if (window.innerWidth < 768) {
                            this.switchMobileTab('map');
                        }

                        if (!window.schoolLineLayerGroup) {
                            window.schoolLineLayerGroup = L.layerGroup().addTo(window.map);
                        }
                        window.schoolLineLayerGroup.clearLayers();

                        var pFac = [item.lat, item.lng];
                        var pSch = [item.nearestSchoolLat, item.nearestSchoolLng];
                        var lineColor = item.schoolRiskLevel === 'high' ? '#dc2626' : (item.schoolRiskLevel === 'medium' ? '#ea580c' : '#7c3aed');

                        var poly = L.polyline([pFac, pSch], {
                            color: lineColor,
                            weight: 3.5,
                            dashArray: '8, 6',
                            opacity: 0.95
                        }).addTo(window.schoolLineLayerGroup);

                        poly.bindTooltip('<i class="fas fa-graduation-cap mr-1"></i>' + item.name + ' ⟷ ' + item.nearestSchoolName + '：<b>' + item.nearestSchoolDist + 'm</b>', {
                            permanent: true,
                            direction: 'center',
                            className: 'school-dist-tooltip'
                        }).openTooltip();

                        // 在目標學校畫一個醒目紫光學士帽高亮標記 (避免該校剛好在環域圓圈外而沒顯示)
                        var schIconHtml = '<div style="background:linear-gradient(135deg,#7c3aed,#4c1d95);color:#fff;width:32px;height:32px;border-radius:50%;border:2px solid #fff;box-shadow:0 0 0 4px rgba(124,58,237,0.35), 0 4px 10px rgba(0,0,0,0.4);display:flex;align-items:center;justify-content:center;font-size:15px;"><i class="fas fa-graduation-cap"></i></div>';
                        var schPin = L.divIcon({
                            className: 'nearest-school-highlight-pin',
                            html: schIconHtml,
                            iconSize: [32, 32],
                            iconAnchor: [16, 16]
                        });
                        var schMarker = L.marker(pSch, { icon: schPin, zIndexOffset: 1500 }).addTo(window.schoolLineLayerGroup);
                        schMarker.bindPopup('<div style="min-width:210px;padding:2px;">' +
                            '<div style="font-size:11px;font-weight:bold;color:#7c3aed;"><i class="fas fa-graduation-cap mr-1"></i>最近學校 (' + (item.nearestSchoolLevel || '學校') + ')</div>' +
                            '<div style="font-weight:bold;font-size:14px;color:#0f172a;margin-bottom:4px;">' + item.nearestSchoolName + '</div>' +
                            '<div style="font-size:12px;color:#ea580c;font-weight:bold;margin-bottom:6px;">距「' + item.name + '」直線距離：' + item.nearestSchoolDist + ' 公尺</div>' +
                            '<button type="button" class="btn btn-sm btn-block text-white font-weight-bold py-1" style="background:#7c3aed;font-size:11px;" onclick="window.triggerPanoBufferCenter(' + item.nearestSchoolLat + ',' + item.nearestSchoolLng + ')"><i class="fas fa-crosshairs mr-1"></i>設此學校為環域中心</button>' +
                            '</div>');

                        window.map.fitBounds(L.latLngBounds([pFac, pSch]), { padding: [70, 70], maxZoom: 16 });
                    },

                    // 開啟學校距離敏感度清冊 Excel 匯出設定彈窗
                    openSchoolExportModal: function () {
                        this.exportConfig.town = this.selectedTownName || '';
                        this.exportConfig.priorityThreshold = this.priorityThreshold || 300;
                        this.exportConfig.schoolLevels = this.schoolLevelFilter || '';
                        this.exportConfig.onlyPriority = this.onlyPriorityFilter || false;
                        $('#schoolExportModal').modal('show');
                    },

                    // 觸發下載固定逸散源距離學校清冊 Excel (.xls)
                    triggerExportSchoolExcel: function () {
                        var cfg = this.exportConfig;
                        var url = API_URL + '?action=exportschooldist' +
                            '&mode=' + encodeURIComponent(cfg.mode || 'buffer') +
                            '&lat=' + this.centerLat +
                            '&lng=' + this.centerLng +
                            '&radius=' + this.currentRadius +
                            '&town=' + encodeURIComponent(cfg.town || '') +
                            '&priorityThreshold=' + (cfg.priorityThreshold || 300) +
                            '&onlyPriority=' + (cfg.onlyPriority ? '1' : '0') +
                            '&schoolLevels=' + encodeURIComponent(cfg.schoolLevels || '');

                        $('#schoolExportModal').modal('hide');
                        window.location.href = url;
                    },

                    // 一鍵同步 504 所學校圖資寫入資料庫 School_Main 表
                    syncSchoolsToDb: function () {
                        var self = this;
                        self.syncingSchools = true;
                        axios.get(API_URL + '?action=syncschoolsdb').then(function (res) {
                            self.syncingSchools = false;
                            if (res.data && res.data.Success) {
                                alert(res.data.Message);
                                self.fetchDebugInfo();
                            } else {
                                alert('同步寫入資料庫失敗：' + (res.data ? res.data.Message : '未知錯誤'));
                            }
                        }).catch(function (err) {
                            self.syncingSchools = false;
                            alert('通訊失敗：' + (err.message || err));
                        });
                    },

                    // 開啟診斷 Modal
                    openDebugModal: function () {
                        $('#debugModal').modal('show');
                        this.fetchDebugInfo();
                    },

                    // 取得後端診斷數據
                    fetchDebugInfo: function () {
                        var self = this;
                        self.debugLoading = true;
                        axios.get(API_URL + '?action=debug').then(function (res) {
                            self.debugLoading = false;
                            if (res.data && res.data.Success) {
                                self.debugInfo = res.data.Info;
                            } else {
                                alert('取得診斷數據失敗：' + (res.data ? res.data.Message : '未知錯誤'));
                            }
                        }).catch(function (err) {
                            self.debugLoading = false;
                            alert('診斷通訊失敗：' + (err.message || err));
                        });
                    }
                }
            });

            app.mount('#bufferApp');
        })();
    </script>
</body>
</html>
