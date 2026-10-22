<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="NewCleanChk.aspx.cs" Inherits="NTPC_FEC.RoadClean.NewCleanChk" %>

<!DOCTYPE html>

<html lang="zh-TW">

<head runat="server">

    <meta charset="utf-8" />

    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />

    <title>新北市固定溢散源管理平台 - 道路潔淨巡檢表</title>

    

    <!-- 專屬 Favicon & 手機主畫面圖標 -->

    <link rel="shortcut icon" href="../favicon.ico" type="image/x-icon" />

    

    <!-- Bootstrap 4 & FontAwesome 本地化樣式 -->

    <link rel="stylesheet" href="../Content/bootstrap.min.css" />

    <link rel="stylesheet" href="../Content/fontawesome/css/all.min.css" />

    

    <!-- Leaflet.js 本地化樣式 -->

    <link rel="stylesheet" href="../Content/leaflet/leaflet.css" />

    

    <style>

        :root {

            --brand-primary: #0099e5;

            --brand-navy: #0f172a;

            --brand-blue: #0284c7;

            --brand-dark-blue: #0b1f7d;

            --bg-canvas: #f1f5f9;

            --surface: #ffffff;

            --border-color: #e2e8f0;

            --text-main: #0f172a;

            --text-muted: #64748b;

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



        /* 頂部導覽列 (新北經典天藍與現代陰影) */

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

            font-size: 1.15rem;

            font-weight: 700;

            letter-spacing: 0.5px;

            margin: 0;

            display: flex;

            align-items: center;

        }



        .nav-btn {

            background: rgba(255, 255, 255, 0.15);

            border: none;

            color: #ffffff;

            font-size: 1.1rem;

            cursor: pointer;

            width: 38px;

            height: 38px;

            border-radius: 8px;

            display: flex;

            align-items: center;

            justify-content: center;

            transition: all 0.2s;

        }



        .nav-btn:hover {

            background-color: rgba(255, 255, 255, 0.3);

            transform: scale(1.05);

        }



        /* 主容器佈局 */

        .page-container {

            max-width: 1600px;

            margin: 0 auto;

            padding: 16px;

        }



        /* 現代卡片設計 */

        .card-modern {

            background: var(--surface);

            border-radius: 12px;

            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05), 0 4px 12px rgba(15, 23, 42, 0.05);

            margin-bottom: 16px;

            border: 1px solid var(--border-color);

            transition: transform 0.2s, box-shadow 0.2s;

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



        /* 桌面寬螢幕左側欄浮動黏著 (Desktop Sticky Sidebar) */

        @media screen and (min-width: 1200px) {

            .sticky-sidebar {

                position: sticky;

                top: 72px;

                max-height: calc(100vh - 88px);

                overflow-y: auto;

                padding-right: 4px;

            }

            .sticky-sidebar::-webkit-scrollbar {

                width: 6px;

            }

            .sticky-sidebar::-webkit-scrollbar-thumb {

                background: #cbd5e1;

                border-radius: 4px;

            }

        }



        /* 統計與資訊小晶片 (Stat Chips) */

        .info-grid {

            display: grid;

            grid-template-columns: repeat(2, 1fr);

            gap: 10px;

            margin-top: 12px;

        }



        .info-chip {

            background: #f8fafc;

            border: 1px solid #e2e8f0;

            border-radius: 8px;

            padding: 8px 12px;

            display: flex;

            flex-direction: column;

        }



        .info-chip-label {

            font-size: 12px;

            color: var(--text-muted);

            margin-bottom: 2px;

            font-weight: 500;

        }



        .info-chip-val {

            font-size: 14px;

            font-weight: 700;

            color: var(--brand-navy);

        }



        /* 地圖樣式與控制項 */

        .map-card-wrapper {

            position: relative;

            overflow: hidden;

            border-radius: 10px;

        }



        #map {

            width: 100%;

            height: 380px;

            border-radius: 8px;

            z-index: 10;

            transition: height 0.3s ease;

        }



        #map.map-collapsed {

            height: 120px !important;

        }



        /* 覆蓋 Leaflet Control Layers 圖示防破圖與美化 */

        .leaflet-control-layers-toggle {

            background-size: 20px 20px !important;

        }



        /* 自訂地圖編號圖標 Marker */

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



        .marker-pin.completed {

            background: #10b981;

        }



        .marker-num {

            transform: rotate(45deg);

            color: #ffffff;

            font-weight: 800;

            font-size: 13px;

        }



        /* 頂部巡檢進度追蹤看板 */

        .progress-banner {

            background: linear-gradient(135deg, #eff6ff 0%, #e0f2fe 100%);

            border: 1px solid #bfdbfe;

            border-radius: 12px;

            padding: 12px 18px;

            margin-bottom: 16px;

            display: flex;

            align-items: center;

            justify-content: space-between;

            flex-wrap: wrap;

            gap: 12px;

        }



        .progress-info {

            display: flex;

            align-items: center;

            gap: 12px;

        }



        .progress-badge {

            background: #0284c7;

            color: #ffffff;

            font-weight: 700;

            font-size: 13px;

            padding: 4px 10px;

            border-radius: 12px;

        }



        /* 檢核點卡片 */

        .point-card {

            background: #ffffff;

            border-radius: 12px;

            border: 1px solid var(--border-color);

            margin-bottom: 18px;

            box-shadow: 0 2px 8px rgba(15, 23, 42, 0.04);

            overflow: hidden;

            transition: border-color 0.2s, box-shadow 0.2s;

        }



        .point-card:hover {

            border-color: #93c5fd;

            box-shadow: 0 4px 16px rgba(2, 132, 199, 0.08);

        }



        .point-card-header {

            background: #f8fafc;

            border-bottom: 1px solid var(--border-color);

            padding: 12px 16px;

            display: flex;

            align-items: center;

            justify-content: space-between;

        }



        .point-tag {

            background: #0b1f7d;

            color: #ffffff;

            font-weight: 700;

            padding: 4px 10px;

            border-radius: 6px;

            font-size: 13px;

            margin-right: 8px;

        }



        .point-title {

            font-size: 1.05rem;

            font-weight: 700;

            color: #1e293b;

        }



        /* 區塊子標題 */

        .section-divider {

            font-size: 12px;

            font-weight: 700;

            letter-spacing: 0.5px;

            color: #64748b;

            text-transform: uppercase;

            margin: 16px 0 8px 0;

            display: flex;

            align-items: center;

            gap: 8px;

        }



        .section-divider::after {

            content: "";

            flex: 1;

            height: 1px;

            background: #e2e8f0;

        }



        /* 現場狀況開關按鈕群 (Segmented Buttons / Pills) - 觸控友善 */

        .status-toggle-row {

            display: flex;

            align-items: center;

            justify-content: space-between;

            background: #f8fafc;

            border: 1px solid #e2e8f0;

            border-radius: 8px;

            padding: 8px 12px;

            margin-bottom: 8px;

        }



        .status-toggle-title {

            font-size: 14px;

            font-weight: 600;

            color: #334155;

            display: flex;

            align-items: center;

            gap: 6px;

        }



        .segmented-group {

            display: inline-flex;

            background: #e2e8f0;

            padding: 3px;

            border-radius: 8px;

            gap: 2px;

        }



        .segment-btn {

            border: none;

            background: transparent;

            padding: 6px 16px;

            border-radius: 6px;

            font-size: 13px;

            font-weight: 600;

            color: #475569;

            cursor: pointer;

            transition: all 0.15s ease;

            min-height: 36px;

            display: inline-flex;

            align-items: center;

            justify-content: center;

        }



        .segment-btn.active-yes {

            background: #10b981;

            color: #ffffff;

            box-shadow: 0 1px 4px rgba(16, 185, 129, 0.35);

        }



        .segment-btn.active-no {

            background: #64748b;

            color: #ffffff;

            box-shadow: 0 1px 4px rgba(100, 116, 139, 0.35);

        }



        /* 題目清單卡片項目 */

        .question-item {

            border: 1px solid #e2e8f0;

            background: #ffffff;

            border-radius: 8px;

            padding: 12px;

            margin-bottom: 10px;

            transition: all 0.2s;

        }



        .question-item:hover {

            border-color: #cbd5e1;

        }



        .question-item-title {

            font-size: 14px;

            font-weight: 600;

            color: #1e293b;

            margin-bottom: 8px;

        }



        /* 評分晶片 (Score Badges / Chips) */

        .score-chips-container {

            display: flex;

            flex-wrap: wrap;

            gap: 8px;

        }



        .score-chip-btn {

            border: 1px solid #cbd5e1;

            background: #ffffff;

            color: #334155;

            padding: 8px 14px;

            border-radius: 8px;

            font-size: 13px;

            font-weight: 600;

            cursor: pointer;

            display: inline-flex;

            align-items: center;

            gap: 6px;

            transition: all 0.15s ease;

            min-height: 42px; /* 滿足觸控標準 42px+ */

        }



        .score-chip-btn:hover {

            background: #f1f5f9;

            border-color: #94a3b8;

        }



        /* 選中評分樣式 (綠/藍/橘/紅) */

        .score-chip-btn.selected-100 {

            background: #ecfdf5;

            border-color: #10b981;

            color: #047857;

            font-weight: 700;

            box-shadow: 0 0 0 2px rgba(16, 185, 129, 0.2);

        }



        .score-chip-btn.selected-80 {

            background: #f0f9ff;

            border-color: #0284c7;

            color: #0369a1;

            font-weight: 700;

            box-shadow: 0 0 0 2px rgba(2, 132, 199, 0.2);

        }



        .score-chip-btn.selected-60 {

            background: #fffbeb;

            border-color: #f59e0b;

            color: #b45309;

            font-weight: 700;

            box-shadow: 0 0 0 2px rgba(245, 158, 11, 0.2);

        }



        .score-chip-btn.selected-0 {

            background: #fef2f2;

            border-color: #ef4444;

            color: #b91c1c;

            font-weight: 700;

            box-shadow: 0 0 0 2px rgba(239, 68, 68, 0.2);

        }



        /* 不需填寫溫和標籤 */

        .noneed-box {

            background: #f1f5f9;

            border: 1px dashed #cbd5e1;

            border-radius: 8px;

            padding: 10px 14px;

            font-size: 13px;

            color: #64748b;

            display: inline-flex;

            align-items: center;

            gap: 6px;

        }



        /* 扣分缺失原因展開面板 */

        .subitem-panel {

            margin-top: 10px;

            padding: 10px 12px;

            background: #fff7ed;

            border: 1px solid #fed7aa;

            border-radius: 8px;

            animation: fadeIn 0.2s ease-in-out;

        }



        .subitem-pill-group {

            display: flex;

            flex-wrap: wrap;

            gap: 6px;

            margin-top: 6px;

        }



        .subitem-pill {

            background: #ffffff;

            border: 1px solid #fdba74;

            color: #9a3412;

            padding: 5px 12px;

            border-radius: 6px;

            font-size: 13px;

            font-weight: 500;

            cursor: pointer;

            transition: all 0.15s;

        }



        .subitem-pill.active {

            background: #ea580c;

            border-color: #ea580c;

            color: #ffffff;

            font-weight: 700;

        }



        /* 稽查簽名板展示區 */

        .signature-preview-card {

            border: 2px dashed #cbd5e1;

            border-radius: 10px;

            background: #f8fafc;

            height: 180px;

            display: flex;

            flex-direction: column;

            align-items: center;

            justify-content: center;

            cursor: pointer;

            transition: all 0.2s;

            position: relative;

            overflow: hidden;

        }



        .signature-preview-card:hover {

            border-color: var(--brand-blue);

            background: #f0f9ff;

        }



        .signature-preview-card img {

            max-width: 100%;

            max-height: 100%;

            object-fit: contain;

        }



                /* 手寫簽名全螢幕沈浸式彈窗 (大範圍滿版書寫) */
        .sig-modal-backdrop {
            position: fixed;
            top: 0;
            left: 0;
            width: 100vw;
            height: 100vh;
            height: 100dvh;
            background: #ffffff;
            z-index: 9999;
            display: flex;
            flex-direction: column;
            padding: 0;
            margin: 0;
            overflow: hidden;
        }

        .sig-modal-window {
            background: #ffffff;
            border-radius: 0;
            width: 100vw;
            height: 100vh;
            height: 100dvh;
            max-width: 100% !important;
            margin: 0;
            padding: 0;
            display: flex;
            flex-direction: column;
            box-shadow: none;
            overflow: hidden;
            flex: 1;
        }

        .sig-modal-header {
            background: linear-gradient(135deg, #0b1f7d 0%, #0284c7 100%);
            color: #ffffff;
            padding: 10px 16px;
            height: 52px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-shrink: 0;
            box-shadow: 0 2px 6px rgba(0, 0, 0, 0.15);
        }

        .sig-canvas-wrapper {
            position: relative;
            flex: 1;
            width: 100%;
            height: 100%;
            background: #fcfdfe;
            touch-action: none !important;
            user-select: none;
            -webkit-user-select: none;
            overflow: hidden;
        }

        #sigCanvas {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            display: block;
            touch-action: none !important;
            user-select: none;
            cursor: crosshair;
        }

        .sig-canvas-tip {
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            color: #cbd5e1;
            font-size: 1.15rem;
            font-weight: 700;
            letter-spacing: 2px;
            pointer-events: none;
            user-select: none;
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 8px;
            transition: opacity 0.3s;
        }

        .sig-canvas-baseline {
            position: absolute;
            bottom: 25%;
            left: 8%;
            right: 8%;
            height: 2px;
            border-bottom: 2px dashed #e2e8f0;
            pointer-events: none;
        }

        .sig-modal-footer {
            padding: 12px 16px;
            padding-bottom: calc(12px + env(safe-area-inset-bottom, 0px));
            background: #f8fafc;
            border-top: 1px solid #e2e8f0;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 10px;
            flex-shrink: 0;
            min-height: 60px;
        }



        /* 手機行動端底部常駐動作列 (Sticky Bottom Bar) */

        .mobile-bottom-bar {

            display: none;

        }



        @media screen and (max-width: 991px) {

            body {

                padding-bottom: 76px; /* 避開底部懸浮條 */

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

                align-items: center;

                justify-content: space-between;

                gap: 10px;

            }

            .mobile-bottom-bar .btn {

                flex: 1;

                font-weight: 700;

                padding: 10px;

                border-radius: 8px;

            }

            #map {

                height: 280px;

            }

        }



        @keyframes fadeIn {

            from { opacity: 0; transform: translateY(-4px); }

            to { opacity: 1; transform: translateY(0); }

        }

    </style>

</head>

<body>

    <div id="cleanApp" v-cloak>

        <!-- 頂部導覽列 -->

        <header class="top-navbar">

            <div class="d-flex align-items-center">

                <button type="button" class="nav-btn mr-2" v-on:click="goBack" title="返回巡檢列表">

                    <i class="fas fa-arrow-left"></i>

                </button>

                <h1 class="brand-title">

                    <i class="fas fa-route mr-2 text-warning"></i>

                    <span class="d-none d-sm-inline">新北市固定溢散源管理平台 - </span>道路潔淨巡檢

                </h1>

            </div>

            <div class="d-flex align-items-center" style="gap: 8px;">

                <span class="badge badge-light d-none d-md-inline-block px-2 py-1 font-weight-bold">

                    {{ mode === 'read' ? '檢視紀錄' : (mode === 'edit' ? '編輯巡檢' : '現場填報') }}

                </span>

                <a href="../MainPage.aspx" class="btn btn-sm btn-outline-light">

                    <i class="fas fa-home mr-1"></i> 回主控台

                </a>

            </div>

        </header>



        <!-- 主頁面容器 -->

        <main class="page-container">

            <!-- 狀態提示訊息 -->

            <div v-if="alertMessage" :class="'alert alert-' + alertType + ' alert-dismissible fade show'" role="alert">

                <strong>{{ alertType === 'success' ? '✅ 成功：' : '⚠️ 提示：' }}</strong> {{ alertMessage }}

                <button type="button" class="close" v-on:click="alertMessage = ''" aria-label="Close">

                    <span aria-hidden="true">&times;</span>

                </button>

            </div>



            <!-- 審核退回/備註意見提示橫幅 -->

            <div v-if="examineMemo" class="alert alert-warning border-warning shadow-sm mb-3">

                <div class="d-flex align-items-center mb-1">

                    <i class="fas fa-exclamation-triangle text-danger mr-2 fa-lg"></i>

                    <strong class="text-danger" style="font-size: 15px;">審核意見 / 退回補件原因：</strong>

                </div>

                <div class="pl-4 font-weight-bold text-dark" style="font-size: 14px; white-space: pre-wrap;">{{ examineMemo }}</div>

            </div>



            <!-- 主佈局區塊 (雙欄 / 單欄自適應) -->

            <div class="row">

                <!-- ============================================== -->

                <!-- 左欄：基本資訊 + 地圖 + 簽章 (寬螢幕固頂)      -->

                <!-- ============================================== -->

                <div class="col-12 col-xl-5">

                    <div class="sticky-sidebar">

                        <!-- 卡片 1：巡檢基本設定 -->

                        <div class="card-modern" id="config-card">

                            <div class="card-modern-header">

                                <h2 class="card-modern-title">

                                    <i class="fas fa-sliders-h text-primary"></i> 巡檢路段設定

                                </h2>

                                <div class="d-flex align-items-center" style="gap: 6px;">

                                    <span v-if="caseStateText" :class="'badge ' + caseStateBadgeClass">{{ caseStateText }}</span>

                                    <span class="badge badge-info">{{ chkId ? chkId : '自動發號' }}</span>

                                </div>

                            </div>

                            <div class="card-modern-body">

                                <div class="form-group mb-2">

                                    <label class="font-weight-bold text-muted small mb-1">

                                        <i class="fas fa-map-marker-alt text-danger mr-1"></i> 行政區 <span class="text-danger">*</span>

                                    </label>

                                    <select class="form-control form-control-lg" v-model="selectedTown" v-on:change="onTownChange" :disabled="mode === 'read'" style="font-size: 15px; font-weight: 600;">

                                        <option value="">-- 請選擇行政區 --</option>

                                        <option v-for="t in townList" :key="t.TownNo" :value="t.TownName">{{ t.TownName }}</option>

                                    </select>

                                </div>



                                <div class="form-group mb-2">

                                    <label class="font-weight-bold text-muted small mb-1">

                                        <i class="fas fa-road text-primary mr-1"></i> 巡檢道路 <span class="text-danger">*</span>

                                    </label>

                                    <select class="form-control form-control-lg" v-model="selectedRdid" v-on:change="onRoadChange" :disabled="mode === 'read' || !selectedTown" style="font-size: 15px; font-weight: 600;">

                                        <option value="">{{ selectedTown ? '-- 請選擇要巡檢的道路 --' : '-- 請先選擇行政區 --' }}</option>

                                        <option v-for="r in roadList" :key="r.Rdid" :value="r.Rdid">{{ r.RoadName }}</option>

                                    </select>

                                </div>



                                <!-- 道路詳細規格晶片 (選定道路後顯示) -->

                                <div class="info-grid" v-if="selectedRdid">

                                    <div class="info-chip">

                                        <span class="info-chip-label">巡檢長度</span>

                                        <span class="info-chip-val text-primary">{{ roadInfo.Dis ? roadInfo.Dis + ' km' : '--' }}</span>

                                    </div>

                                    <div class="info-chip">

                                        <span class="info-chip-label">道路寬度</span>

                                        <span class="info-chip-val text-primary">{{ roadInfo.Wid ? roadInfo.Wid + ' m' : '--' }}</span>

                                    </div>

                                    <div class="info-chip" v-if="roadInfo.StartPlace">

                                        <span class="info-chip-label">起點位置</span>

                                        <span class="info-chip-val small text-truncate" :title="roadInfo.StartPlace">{{ roadInfo.StartPlace }}</span>

                                    </div>

                                    <div class="info-chip" v-if="roadInfo.EndPlace">

                                        <span class="info-chip-label">訖點位置</span>

                                        <span class="info-chip-val small text-truncate" :title="roadInfo.EndPlace">{{ roadInfo.EndPlace }}</span>

                                    </div>

                                    <div class="info-chip" style="grid-column: span 2;">

                                        <span class="info-chip-label">巡查時間</span>

                                        <span class="info-chip-val font-weight-normal text-secondary">{{ chkDate }}</span>

                                    </div>

                                </div>

                            </div>

                        </div>



                        <!-- 卡片 2：智慧巡檢地圖 -->

                        <div class="card-modern">

                            <div class="card-modern-header">

                                <h2 class="card-modern-title">

                                    <i class="fas fa-map-marked-alt text-success"></i> 現場巡檢地圖

                                </h2>

                                <div class="d-flex align-items-center" style="gap: 6px;">

                                    <button type="button" class="btn btn-xs btn-outline-danger font-weight-bold" v-on:click="locateUser" title="GPS定位當前位置">

                                        <i class="fas fa-crosshairs mr-1"></i> 定位

                                    </button>

                                    <button type="button" class="btn btn-xs btn-outline-primary font-weight-bold" v-on:click="resetMapView" title="路段全景視野">

                                        <i class="fas fa-expand mr-1"></i> 全景

                                    </button>

                                    <button type="button" class="btn btn-xs btn-outline-secondary d-md-none" v-on:click="toggleMapCollapse">

                                        <i :class="isMapCollapsed ? 'fas fa-chevron-down' : 'fas fa-chevron-up'"></i>

                                        {{ isMapCollapsed ? '展開' : '收合' }}

                                    </button>

                                </div>

                            </div>

                            <div class="card-modern-body p-0">

                                <div class="map-card-wrapper">

                                    <div id="map" :class="{ 'map-collapsed': isMapCollapsed }"></div>

                                </div>

                            </div>

                        </div>



                        <!-- 卡片 3：稽查簽名 (桌面端常駐於側邊欄，手機版置底/浮動) -->

                        <div class="card-modern d-none d-lg-block">

                            <div class="card-modern-header">

                                <h2 class="card-modern-title">

                                    <i class="fas fa-file-signature text-warning"></i> 稽查人員簽章

                                </h2>

                                <span v-if="signatureImg" class="badge badge-success">

                                    <i class="fas fa-check mr-1"></i> 已簽名

                                </span>

                            </div>

                            <div class="card-modern-body text-center">

                                <div class="signature-preview-card" v-on:click="mode !== 'read' && openSignatureModal()" title="點擊進行手寫簽章">

                                    <img v-if="signatureImg" :src="signatureImg" alt="稽查人員手寫簽章" />

                                    <div v-else class="text-muted">

                                        <i class="fas fa-signature fa-3x mb-2" :class="mode === 'read' ? 'text-secondary' : 'text-primary'" style="opacity: 0.5;"></i>

                                        <p class="font-weight-bold mb-0">{{ mode === 'read' ? '未簽名 / 無手寫簽章' : '點擊此處進行手寫簽名' }}</p>

                                        <small v-if="mode !== 'read'" class="text-secondary">支援觸控筆與手機觸控書寫</small>

                                    </div>

                                </div>



                                <div class="mt-3 d-flex justify-content-center" style="gap: 10px;">

                                    <button v-if="mode !== 'read'" type="button" class="btn btn-success btn-lg px-4 font-weight-bold" :disabled="saving" v-on:click="submitCheck">

                                        <span v-if="saving" class="spinner-border spinner-border-sm mr-1"></span>

                                        <i v-else class="fas fa-cloud-upload-alt mr-1"></i>

                                        {{ saving ? '儲存中...' : '確定送出' }}

                                    </button>

                                    <button type="button" class="btn btn-outline-secondary px-3 font-weight-bold" v-on:click="goBack">

                                        {{ mode === 'read' ? '返回巡檢清單' : '取消' }}

                                    </button>

                                </div>

                            </div>

                        </div>

                    </div>

                </div>



                <!-- ============================================== -->

                <!-- 右欄：檢核點清單與填報主作業區                 -->

                <!-- ============================================== -->

                <div class="col-12 col-xl-7">

                    <!-- 未選擇道路之指引引導 -->

                    <div v-if="!selectedRdid" class="card-modern text-center py-4 px-3">

                        <div class="py-3">

                            <i class="fas fa-clipboard-list fa-3x text-muted mb-3" style="opacity: 0.35;"></i>

                            <h5 class="font-weight-bold text-secondary mb-2">請先選取「行政區」與「巡檢道路」</h5>

                            <p class="text-muted small mb-3">選定路段後，系統將自動載入該道路之全部檢核點位與評分項目。</p>

                            <button type="button" class="btn btn-sm btn-outline-primary font-weight-bold d-inline-flex align-items-center" v-on:click="scrollToConfig">

                                <i class="fas fa-arrow-up mr-1"></i> 前往選擇巡檢路段

                            </button>

                        </div>

                    </div>



                    <!-- 已選擇道路：主檢核區 -->

                    <div v-else>

                        <!-- 頂部進度看板與一鍵全合格 -->

                        <div class="progress-banner">

                            <div class="progress-info">

                                <span class="progress-badge">

                                    <i class="fas fa-check-circle mr-1"></i> 進度 {{ calcProgress() }}

                                </span>

                                <span class="font-weight-bold text-dark">

                                    共 {{ pointList.length }} 個檢核點

                                </span>

                            </div>

                            <div v-if="mode !== 'read'">

                                <button type="button" class="btn btn-sm btn-outline-primary font-weight-bold bg-white" v-on:click="quickPassAll" title="將所有檢核點設為滿分 100 分">

                                    <i class="fas fa-bolt text-warning mr-1"></i> 一鍵全部合格 (全滿分)

                                </button>

                            </div>

                        </div>



                        <!-- 檢核點卡片清單 -->

                        <div v-for="(pt, pIdx) in pointList" :key="pt.PointId" :id="'point-card-' + pt.PIndex" class="point-card">

                            <!-- 點位標題列 -->

                            <div class="point-card-header">

                                <div class="d-flex align-items-center">

                                    <span class="point-tag">第 {{ pt.PIndex }} 點</span>

                                    <span class="point-title">{{ pt.PointPlace }}</span>

                                </div>

                                <button v-if="pt.Lat > 0" type="button" class="btn btn-xs btn-outline-info" v-on:click="focusPointOnMap(pt)" title="地圖對焦此點">

                                    <i class="fas fa-map-pin mr-1"></i> 地圖定位

                                </button>

                            </div>



                            <div class="card-modern-body">

                                <!-- 區塊 1：現場狀況 (開關按鈕組) -->

                                <div class="section-divider">

                                    <i class="fas fa-info-circle text-info"></i> 現場環境狀況

                                </div>



                                <div class="status-toggle-row">

                                    <span class="status-toggle-title">

                                        <i class="fas fa-tree text-success"></i> 行道樹

                                    </span>

                                    <div class="segmented-group">

                                        <button type="button" class="segment-btn" :class="{ 'active-yes': pt.STree === 'Y' }" v-on:click="mode !== 'read' && (pt.STree = 'Y')">

                                            有

                                        </button>

                                        <button type="button" class="segment-btn" :class="{ 'active-no': pt.STree === 'N' }" v-on:click="mode !== 'read' && (pt.STree = 'N')">

                                            無

                                        </button>

                                    </div>

                                </div>



                                <div class="status-toggle-row">

                                    <span class="status-toggle-title">

                                        <i class="fas fa-walking text-primary"></i> 人行道或分隔島

                                    </span>

                                    <div class="segmented-group">

                                        <button type="button" class="segment-btn" :class="{ 'active-yes': pt.SIsland === 'Y' }" v-on:click="mode !== 'read' && (pt.SIsland = 'Y')">

                                            有

                                        </button>

                                        <button type="button" class="segment-btn" :class="{ 'active-no': pt.SIsland === 'N' }" v-on:click="mode !== 'read' && (pt.SIsland = 'N')">

                                            無

                                        </button>

                                    </div>

                                </div>



                                <div class="status-toggle-row">

                                    <span class="status-toggle-title">

                                        <i class="fas fa-hard-hat text-warning"></i> 營建工地

                                    </span>

                                    <div class="segmented-group">

                                        <button type="button" class="segment-btn" :class="{ 'active-yes': pt.CivilSide === 'Y' }" v-on:click="mode !== 'read' && (pt.CivilSide = 'Y')">

                                            有

                                        </button>

                                        <button type="button" class="segment-btn" :class="{ 'active-no': pt.CivilSide === 'N' }" v-on:click="mode !== 'read' && (pt.CivilSide = 'N')">

                                            無

                                        </button>

                                    </div>

                                </div>



                                <!-- 區塊 2：潔淨度檢核項目 (RCC) -->

                                <div class="section-divider">

                                    <i class="fas fa-broom text-primary"></i> 潔淨度檢核項目 (RCC)

                                </div>



                                <div v-for="q in questions.RCC" :key="q.ChkCode" class="question-item">

                                    <div class="question-item-title">{{ q.Title }}</div>



                                    <!-- 不需填寫溫和標籤 -->

                                    <div v-if="isNoNeed(pt, q.ChkCode)">

                                        <span class="noneed-box">

                                            <i class="fas fa-ban text-muted"></i> 現場環境無此設施，依規定不需填寫

                                        </span>

                                    </div>



                                    <!-- 評分晶片群 -->

                                    <div v-else>

                                        <div class="score-chips-container">

                                            <button v-for="opt in q.Options" :key="opt.Score" type="button" class="score-chip-btn" :class="getScoreChipClass(getScoreObj(pt, q.ChkCode).Score, opt.Score)" v-on:click="mode !== 'read' && setPointScore(pt, q.ChkCode, opt.Score)">

                                                <i :class="getScoreIcon(opt.Score)"></i>

                                                {{ opt.Text }}

                                            </button>

                                        </div>



                                        <!-- 扣分缺失原因 (低於 100 分自動展開) -->

                                        <div v-if="getScoreObj(pt, q.ChkCode).Score !== null && getScoreObj(pt, q.ChkCode).Score < 100 && q.SubItems && q.SubItems.length > 0" class="subitem-panel">

                                            <small class="font-weight-bold text-danger d-block">

                                                <i class="fas fa-exclamation-triangle mr-1"></i> 請點選主要缺失原因：

                                            </small>

                                            <div class="subitem-pill-group">

                                                <button v-for="sub in q.SubItems" :key="sub" type="button" class="subitem-pill" :class="{ 'active': getScoreObj(pt, q.ChkCode).ChiItem1 === sub }" v-on:click="mode !== 'read' && (getScoreObj(pt, q.ChkCode).ChiItem1 = sub)">

                                                    {{ sub }}

                                                </button>

                                            </div>

                                        </div>

                                    </div>

                                </div>



                                <!-- 區塊 3：道路淹水潛勢調查 (FLD) -->

                                <div class="section-divider">

                                    <i class="fas fa-water text-info"></i> 道路淹水潛勢調查 (FLD)

                                </div>



                                <div v-for="q in questions.FLD" :key="q.ChkCode" class="question-item">

                                    <div class="question-item-title">{{ q.Title }}</div>

                                    <div class="score-chips-container">

                                        <button v-for="opt in q.Options" :key="opt.Score" type="button" class="score-chip-btn" :class="getScoreChipClass(getScoreObj(pt, q.ChkCode).Score, opt.Score)" v-on:click="mode !== 'read' && setPointScore(pt, q.ChkCode, opt.Score)">

                                            <i :class="getScoreIcon(opt.Score)"></i>

                                            {{ opt.Text }}

                                        </button>

                                    </div>

                                </div>

                            </div>

                        </div>



                        <!-- 手機/平板端內嵌簽名區塊 (於清單底部呈現) -->

                        <div class="card-modern d-block d-lg-none mt-4">

                            <div class="card-modern-header">

                                <h2 class="card-modern-title">

                                    <i class="fas fa-file-signature text-warning"></i> 稽查人員簽章

                                </h2>

                                <span v-if="signatureImg" class="badge badge-success">

                                    <i class="fas fa-check mr-1"></i> 已簽名

                                </span>

                            </div>

                            <div class="card-modern-body text-center">

                                <div class="signature-preview-card" v-on:click="mode !== 'read' && openSignatureModal()" title="點擊進行手寫簽章">

                                    <img v-if="signatureImg" :src="signatureImg" alt="稽查人員手寫簽章" />

                                    <div v-else class="text-muted">

                                        <i class="fas fa-signature fa-2x mb-2 text-primary" style="opacity: 0.6;"></i>

                                        <p class="font-weight-bold mb-0">點擊此處進行手寫簽名</p>

                                    </div>

                                </div>

                            </div>

                        </div>

                    </div>

                </div>

            </div>

        </main>



        <!-- ============================================== -->

        <!-- 手機端底部常駐動作列 (Sticky Bottom Bar)        -->

        <!-- ============================================== -->

        <div class="mobile-bottom-bar" v-if="selectedRdid && mode !== 'read'">

            <button type="button" class="btn btn-outline-primary" v-on:click="openSignatureModal">

                <i :class="signatureImg ? 'fas fa-check-circle text-success' : 'fas fa-pen-nib'"></i>

                {{ signatureImg ? '重簽' : '手寫簽名' }}

            </button>

            <button v-if="mode !== 'read'" type="button" class="btn btn-success" :disabled="saving" v-on:click="submitCheck">

                <span v-if="saving" class="spinner-border spinner-border-sm mr-1"></span>

                <i v-else class="fas fa-paper-plane mr-1"></i>

                {{ saving ? '送出中...' : '確定送出' }}

            </button>

        </div>



        <!-- ============================================== -->

        <!-- 電子手寫簽章彈窗 (高解析 Canvas 觸控優化)       -->

        <!-- ============================================== -->

                <!-- ============================================== -->
        <!-- 電子手寫簽章全螢幕畫布 (Pointer Events 頂級平滑觸控) -->
        <!-- ============================================== -->
        <div v-if="showSigModal" class="sig-modal-backdrop">
            <div class="sig-modal-window">
                <div class="sig-modal-header">
                    <div class="d-flex align-items-center">
                        <i class="fas fa-pen-nib mr-2 fa-lg text-warning"></i>
                        <span class="font-weight-bold" style="font-size: 1.1rem;">稽查人員手寫簽署</span>
                    </div>
                    <div class="d-flex align-items-center" style="gap: 12px;">
                        <small class="badge badge-light d-none d-sm-inline-block px-2 py-1">
                            <i class="fas fa-mobile-alt mr-1"></i> 手機可橫放書寫更寬廣
                        </small>
                        <button type="button" class="btn btn-sm btn-outline-light px-2 py-1" v-on:click="closeSignatureModal" title="關閉">
                            <i class="fas fa-times fa-lg"></i>
                        </button>
                    </div>
                </div>
                <div class="sig-canvas-wrapper">
                    <!-- 書寫參考背景線與指引 -->
                    <div class="sig-canvas-baseline"></div>
                    <div class="sig-canvas-tip" v-if="!hasDrawnSignature">
                        <i class="fas fa-signature fa-2x mb-1" style="opacity: 0.6;"></i>
                        <span>請於此全螢幕區域流暢書寫簽名</span>
                        <small style="font-size: 12px; font-weight: normal; color: #94a3b8;">支援手指、觸控筆及 Apple Pencil</small>
                    </div>
                    <canvas id="sigCanvas"></canvas>
                </div>
                <div class="sig-modal-footer">
                    <button type="button" class="btn btn-outline-danger font-weight-bold px-3 py-2" v-on:click="clearCanvas">
                        <i class="fas fa-eraser mr-1"></i> 清除重簽
                    </button>
                    <div class="d-flex" style="gap: 10px;">
                        <button type="button" class="btn btn-outline-secondary font-weight-bold px-3 py-2" v-on:click="closeSignatureModal">
                            取消
                        </button>
                        <button type="button" class="btn btn-success font-weight-bold px-4 py-2" v-on:click="saveSignature">
                            <i class="fas fa-check mr-1"></i> 完成簽署
                        </button>
                    </div>
                </div>
            </div>
        </div>

    </div>



    <!-- 引用本地 Vue 3 & Axios (避開外連 CSP 阻擋) -->

    <script src="../Scripts/vue.global.prod.js"></script>

    <script src="../Scripts/axios.min.js"></script>

    

    <!-- 引用本地 Leaflet.js (完全免外連) -->

    <script src="../Scripts/leaflet/leaflet.js"></script>



    <script>

        const { createApp, markRaw } = Vue;



        createApp({

            data() {

                return {

                    mode: 'new',

                    chkId: '',

                    chkDate: '',

                    caseState: 1001,

                    examineMemo: '',

                    listMode: '',

                    selectedTown: '',

                    selectedRdid: '',

                    townList: [],

                    roadList: [],

                    roadInfo: {},

                    pointList: [],

                    questions: { RCC: [], FLD: [] },

                    signatureImg: '',

                    showSigModal: false,
                    hasDrawnSignature: false,

                    saving: false,

                    alertMessage: '',

                    alertType: 'info',

                    isMapCollapsed: false,

                    // 新北市 29 行政區中心點座標對照表

                    townCoords: {

                        '板橋區': [25.0113, 121.4657], '三重區': [25.0614, 121.4881], '中和區': [24.9995, 121.5002],

                        '永和區': [25.0084, 121.5177], '新莊區': [25.0359, 121.4503], '新店區': [24.9682, 121.5416],

                        '樹林區': [24.9912, 121.4247], '鶯歌區': [24.9547, 121.3545], '三峽區': [24.9338, 121.3736],

                        '淡水區': [25.1756, 121.4429], '汐止區': [25.0630, 121.6589], '瑞芳區': [25.1086, 121.8105],

                        '土城區': [24.9729, 121.4447], '蘆洲區': [25.0849, 121.4735], '五股區': [25.0829, 121.4385],

                        '泰山區': [25.0594, 121.4316], '林口區': [25.0779, 121.3934], '深坑區': [25.0016, 121.6157],

                        '石碇區': [24.9917, 121.6582], '坪林區': [24.9372, 121.7118], '三芝區': [25.2582, 121.5008],

                        '石門區': [25.2904, 121.5684], '八里區': [25.1468, 121.3976], '平溪區': [25.0259, 121.7386],

                        '雙溪區': [25.0335, 121.8657], '貢寮區': [25.0221, 121.9083], '金山區': [25.2219, 121.6378],

                        '萬里區': [25.1783, 121.6888], '烏來區': [24.8654, 121.5505]

                    },

                    // Canvas 繪圖變數

                    canvasCtx: null,

                    isDrawing: false,

                    lastX: 0,

                    lastY: 0

                };

            },

            created() {

                // 使用非響應式原生屬性存放 Leaflet 物件，杜絕 Vue 3 Proxy 污染

                this.leafletMap = null;

                this.pointMarkers = [];

                this.userLocationMarker = null;

            },

            computed: {

                caseStateText() {

                    switch (this.caseState) {

                        case 1001: return '草稿';

                        case 2001: return '待審核';

                        case 2101: return '審核通過';

                        case 2201: return '已駁回';

                        case 2301: return '退回補件';

                        default: return '';

                    }

                },

                caseStateBadgeClass() {

                    switch (this.caseState) {

                        case 1001: return 'badge-secondary';

                        case 2001: return 'badge-warning text-dark';

                        case 2101: return 'badge-success';

                        case 2201: return 'badge-danger';

                        case 2301: return 'badge-danger';

                        default: return 'badge-light';

                    }

                }

            },

            async mounted() {

                const urlParams = new URLSearchParams(window.location.search);

                this.mode = (urlParams.get('mode') || 'new').toLowerCase();

                // 容錯支援所有單號參數名稱: chkId, chkID, chkid, id
                this.chkId = urlParams.get('chkId') || urlParams.get('chkID') || urlParams.get('chkid') || urlParams.get('id') || '';

                // 接收返回模式參數
                this.listMode = urlParams.get('listMode') || urlParams.get('fromMode') || '';



                const now = new Date();

                this.chkDate = now.getFullYear() + '-' +

                    String(now.getMonth() + 1).padStart(2, '0') + '-' +

                    String(now.getDate()).padStart(2, '0') + ' ' +

                    String(now.getHours()).padStart(2, '0') + ':' +

                    String(now.getMinutes()).padStart(2, '0');



                this.initLeafletMap();

                await this.fetchTowns();



                if (this.mode === 'edit' || this.mode === 'read') {

                    if (this.chkId) {

                        await this.fetchRecord(this.chkId);

                    }

                }

            },

            methods: {

                // 初始化 Leaflet 開源地圖 (隔離 Vue 3 響應式代理)

                initLeafletMap() {

                    this.$nextTick(() => {

                        const mapEl = document.getElementById('map');

                        if (!mapEl) return;



                        if (this.leafletMap) {

                            this.leafletMap.remove();

                            this.leafletMap = null;

                        }



                        const defaultCenter = [25.0113, 121.4657]; // 新北市政府 (板橋)

                        const mapInstance = L.map('map', {

                            center: defaultCenter,

                            zoom: 13,

                            zoomControl: true,

                            preferCanvas: true

                        });



                        // markRaw 確保 Leaflet 原生物件不被 Proxy 包裝

                        this.leafletMap = markRaw(mapInstance);



                        // 設定 Leaflet 預設圖示路徑

                        L.Icon.Default.imagePath = '../Content/leaflet/images/';



                        // 載入臺灣通用電子地圖 (NLSC WMTS)

                        const emap = markRaw(L.tileLayer('https://wmts.nlsc.gov.tw/wmts/EMAP/default/GoogleMapsCompatible/{z}/{y}/{x}', {

                            maxZoom: 19,

                            crossOrigin: true,

                            attribution: '&copy; <a href="https://maps.nlsc.gov.tw/" target="_blank">國土測繪圖資</a> | 新北市環保局'

                        }));



                        // 備用圖層：OpenStreetMap

                        const osm = markRaw(L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {

                            maxZoom: 19,

                            crossOrigin: true,

                            attribution: '&copy; <a href="https://www.openstreetmap.org/copyright" target="_blank">OpenStreetMap</a>'

                        }));



                        emap.addTo(this.leafletMap);



                        // 圖層控制項 (位於右上角，不受任何按鈕阻擋)

                        L.control.layers({

                            '臺灣通用電子地圖': emap,

                            'OpenStreetMap': osm

                        }, null, { position: 'topright' }).addTo(this.leafletMap);



                        setTimeout(() => {

                            if (this.leafletMap) {

                                this.leafletMap.invalidateSize(false);

                            }

                        }, 300);

                    });

                },



                // 地圖重設視野

                resetMapView() {

                    if (!this.leafletMap) return;

                    this.leafletMap.invalidateSize(false);



                    if (this.pointMarkers && this.pointMarkers.length > 0) {

                        const group = new L.featureGroup(this.pointMarkers);

                        this.leafletMap.fitBounds(group.getBounds(), { padding: [30, 30], animate: false });

                    } else if (this.selectedTown && this.townCoords[this.selectedTown]) {

                        this.leafletMap.setView(this.townCoords[this.selectedTown], 14, { animate: false });

                    } else {

                        this.leafletMap.setView([25.0113, 121.4657], 13, { animate: false });

                    }

                },



                // GPS 現場定位

                locateUser() {

                    if (!navigator.geolocation) {

                        alert('您的裝置或瀏覽器不支援定位功能！');

                        return;

                    }

                    navigator.geolocation.getCurrentPosition(

                        pos => {

                            if (!this.leafletMap) return;

                            const lat = pos.coords.latitude;

                            const lng = pos.coords.longitude;

                            this.leafletMap.invalidateSize(false);

                            this.leafletMap.setView([lat, lng], 16, { animate: false });



                            if (this.userLocationMarker) {

                                this.leafletMap.removeLayer(this.userLocationMarker);

                            }



                            const circleMarker = L.circleMarker([lat, lng], {

                                radius: 9,

                                fillColor: '#0284c7',

                                color: '#ffffff',

                                weight: 3,

                                opacity: 1,

                                fillOpacity: 0.9

                            });



                            this.userLocationMarker = markRaw(circleMarker);

                            this.userLocationMarker.addTo(this.leafletMap).bindPopup('<b>📍 您的當前位置</b>').openPopup();

                        },

                        err => {

                            alert('無法取得您的位置：' + err.message);

                        },

                        { enableHighAccuracy: true, timeout: 6000 }

                    );

                },



                // 手機地圖展開/收合

                toggleMapCollapse() {

                    this.isMapCollapsed = !this.isMapCollapsed;

                    this.$nextTick(() => {

                        setTimeout(() => {

                            if (this.leafletMap) {

                                this.leafletMap.invalidateSize(false);

                            }

                        }, 300);

                    });

                },



                // 取得行政區列表

                async fetchTowns() {

                    try {

                        const res = await axios.get('NewCleanChk.aspx?action=getTowns');

                        if (res.data.Success) {

                            this.townList = res.data.Data;

                        }

                    } catch (e) {

                        console.error('行政區載入失敗', e);

                    }

                },



                // 行政區切換 (手動變更)

                async onTownChange() {

                    this.selectedRdid = '';

                    this.roadList = [];

                    this.roadInfo = {};

                    this.pointList = [];

                    this.clearPointMarkers();



                    if (!this.selectedTown) return;



                    if (this.leafletMap && this.townCoords[this.selectedTown]) {

                        this.leafletMap.invalidateSize(false);

                        this.leafletMap.setView(this.townCoords[this.selectedTown], 14, { animate: false });

                    }



                    await this.fetchRoadsByTown(this.selectedTown);

                },



                // 依行政區載入道路清單 (不重設已選道路與點位)

                async fetchRoadsByTown(town) {

                    if (!town) {

                        this.roadList = [];

                        return;

                    }

                    try {

                        const res = await axios.get('NewCleanChk.aspx?action=getRoads&town=' + encodeURIComponent(town));

                        if (res.data.Success) {

                            this.roadList = res.data.Data || [];

                        }

                    } catch (e) {

                        console.error('道路清單載入失敗', e);

                    }

                },



                // 道路切換

                async onRoadChange() {

                    if (!this.selectedRdid) return;



                    try {

                        const res = await axios.get('NewCleanChk.aspx?action=getRoadDetail&rdid=' + encodeURIComponent(this.selectedRdid));

                        if (res.data.Success) {

                            this.roadInfo = res.data.Road;

                            this.questions = res.data.Questions;



                            this.pointList = res.data.Points.map(pt => {

                                return {

                                    PointId: pt.PointId,

                                    PIndex: pt.PIndex,

                                    PointPlace: pt.PointPlace,

                                    Lat: pt.Lat || 0,

                                    Lng: pt.Lng || 0,

                                    STree: 'Y',

                                    SIsland: 'Y',

                                    CivilSide: 'N',

                                    Scores: {}

                                };

                            });



                            // 預填預設滿分 (100)

                            this.pointList.forEach(pt => {

                                [...this.questions.RCC, ...this.questions.FLD].forEach(q => {

                                    pt.Scores[q.ChkCode] = {

                                        ChkCode: q.ChkCode,

                                        Score: 100,

                                        ChiItem1: ''

                                    };

                                });

                            });



                            // 於地圖標繪檢核點 Marker

                            this.renderPointMarkers();

                        }

                    } catch (e) {

                        console.error('道路詳情載入失敗', e);

                    }

                },



                // 在地圖上繪製檢核點標記

                renderPointMarkers() {

                    this.clearPointMarkers();

                    if (!this.leafletMap) {

                        this.$nextTick(() => {

                            if (this.leafletMap) this.renderPointMarkers();

                        });

                        return;

                    }

                    const validBounds = [];



                    this.pointList.forEach(pt => {

                        if (pt.Lat > 0 && pt.Lng > 0) {

                            const markerIcon = L.divIcon({

                                className: 'custom-map-marker',

                                html: '<div class="marker-pin"><span class="marker-num">' + pt.PIndex + '</span></div>',

                                iconSize: [32, 42],

                                iconAnchor: [16, 42],

                                popupAnchor: [0, -36]

                            });



                            const markerInstance = L.marker([pt.Lat, pt.Lng], { icon: markerIcon });

                            const marker = markRaw(markerInstance);

                            marker.addTo(this.leafletMap);

                            marker.bindPopup('<b>第 ' + pt.PIndex + ' 檢核點</b><br>' + pt.PointPlace);

                            marker.on('click', () => {

                                this.scrollToPoint(pt.PIndex);

                            });



                            this.pointMarkers.push(marker);

                            validBounds.push([pt.Lat, pt.Lng]);

                        }

                    });



                    if (validBounds.length > 0) {

                        this.leafletMap.fitBounds(validBounds, { padding: [40, 40], animate: false });

                    }

                },



                clearPointMarkers() {

                    if (this.leafletMap && this.pointMarkers) {

                        this.pointMarkers.forEach(m => this.leafletMap.removeLayer(m));

                    }

                    this.pointMarkers = [];

                },



                focusPointOnMap(pt) {

                    if (this.leafletMap && pt.Lat > 0 && pt.Lng > 0) {

                        this.leafletMap.invalidateSize(false);

                        this.leafletMap.setView([pt.Lat, pt.Lng], 17, { animate: false });

                    }

                },



                scrollToConfig() {

                    const el = document.getElementById('config-card');

                    if (el) {

                        el.scrollIntoView({ behavior: 'smooth', block: 'start' });

                    }

                },



                scrollToPoint(index) {

                    const el = document.getElementById('point-card-' + index);

                    if (el) {

                        el.scrollIntoView({ behavior: 'smooth', block: 'center' });

                    }

                },



                // 取得題目計分物件

                getScoreObj(pt, chkCode) {

                    if (!pt.Scores[chkCode]) {

                        pt.Scores[chkCode] = { ChkCode: chkCode, Score: 100, ChiItem1: '' };

                    }

                    return pt.Scores[chkCode];

                },



                // 判斷是否為「不需填寫」

                isNoNeed(pt, chkCode) {

                    if (chkCode === 'RCC005' && pt.STree === 'N') return true;

                    if (chkCode === 'RCC004' && pt.SIsland === 'N') return true;

                    if (chkCode === 'RCC006' && pt.CivilSide === 'N') return true;

                    return false;

                },



                // 設定評分

                setPointScore(pt, chkCode, score) {

                    const obj = this.getScoreObj(pt, chkCode);

                    obj.Score = score;

                    if (score === 100) {

                        obj.ChiItem1 = '';

                    }

                },



                // 評分按鈕高亮 Class

                getScoreChipClass(currentScore, targetScore) {

                    if (currentScore !== targetScore) return '';

                    if (targetScore >= 100) return 'selected-100';

                    if (targetScore >= 80) return 'selected-80';

                    if (targetScore >= 60) return 'selected-60';

                    return 'selected-0';

                },



                getScoreIcon(score) {

                    if (score >= 100) return 'fas fa-check-circle text-success';

                    if (score >= 80) return 'fas fa-thumbs-up text-primary';

                    if (score >= 60) return 'fas fa-minus-circle text-warning';

                    return 'fas fa-times-circle text-danger';

                },



                // 一鍵全合格

                quickPassAll() {

                    if (this.pointList.length === 0) return;

                    this.pointList.forEach(pt => {

                        pt.STree = 'Y';

                        pt.SIsland = 'Y';

                        pt.CivilSide = 'N';

                        [...this.questions.RCC, ...this.questions.FLD].forEach(q => {

                            const scoreObj = this.getScoreObj(pt, q.ChkCode);

                            scoreObj.Score = 100;

                            scoreObj.ChiItem1 = '';

                        });

                    });

                    this.alertMessage = '已為全部檢核點套用 100 分滿分合格！';

                    this.alertType = 'success';

                    setTimeout(() => { this.alertMessage = ''; }, 3000);

                },



                // 計算完成度

                calcProgress() {

                    if (this.pointList.length === 0) return '0 / 0';

                    let doneCount = 0;

                    this.pointList.forEach(pt => {

                        let isComplete = true;

                        [...this.questions.RCC, ...this.questions.FLD].forEach(q => {

                            if (!this.isNoNeed(pt, q.ChkCode)) {

                                const score = this.getScoreObj(pt, q.ChkCode).Score;

                                if (score === null || score === undefined) isComplete = false;

                            }

                        });

                        if (isComplete) doneCount++;

                    });

                    return doneCount + ' / ' + this.pointList.length + ' (' + Math.round((doneCount / this.pointList.length) * 100) + '%)';

                },



                // 手寫簽名彈窗管理

                                // 手寫簽名全螢幕彈窗管理 (Pointer Events 高性能平滑流暢觸控)
                openSignatureModal() {
                    this.showSigModal = true;
                    this.hasDrawnSignature = !!this.signatureImg;
                    document.body.style.overflow = 'hidden'; // 鎖定背景捲動

                    this.$nextTick(() => {
                        setTimeout(() => {
                            this.initCanvas();
                        }, 60);
                    });
                },

                closeSignatureModal() {
                    document.body.style.overflow = '';
                    this.showSigModal = false;
                },

                initCanvas() {
                    const canvas = document.getElementById('sigCanvas');
                    if (!canvas) return;
                    const container = canvas.parentElement;
                    if (!container) return;

                    const rect = container.getBoundingClientRect();
                    const width = rect.width;
                    const height = rect.height;

                    if (width <= 0 || height <= 0) {
                        setTimeout(() => this.initCanvas(), 100);
                        return;
                    }

                    const dpr = window.devicePixelRatio || 1;
                    canvas.width = Math.round(width * dpr);
                    canvas.height = Math.round(height * dpr);
                    canvas.style.width = width + 'px';
                    canvas.style.height = height + 'px';

                    this.canvasCtx = canvas.getContext('2d');
                    this.canvasCtx.scale(dpr, dpr);
                    this.canvasCtx.strokeStyle = '#0f172a'; // 深鋼筆墨色
                    this.canvasCtx.lineWidth = 3.5;
                    this.canvasCtx.lineCap = 'round';
                    this.canvasCtx.lineJoin = 'round';

                    // 移除舊的監聽避免重複累積
                    if (this._sigListeners) {
                        canvas.removeEventListener('pointerdown', this._sigListeners.down);
                        canvas.removeEventListener('pointermove', this._sigListeners.move);
                        canvas.removeEventListener('pointerup', this._sigListeners.up);
                        canvas.removeEventListener('pointercancel', this._sigListeners.up);
                    }

                    let isDrawing = false;
                    let lastX = 0;
                    let lastY = 0;

                    const getPos = e => {
                        const r = canvas.getBoundingClientRect();
                        return {
                            x: e.clientX - r.left,
                            y: e.clientY - r.top
                        };
                    };

                    const down = e => {
                        e.preventDefault();
                        try {
                            canvas.setPointerCapture(e.pointerId);
                        } catch (err) {}
                        isDrawing = true;
                        this.hasDrawnSignature = true;
                        const pos = getPos(e);
                        lastX = pos.x;
                        lastY = pos.y;
                        this.canvasCtx.beginPath();
                        this.canvasCtx.moveTo(lastX, lastY);
                    };

                    const move = e => {
                        if (!isDrawing) return;
                        e.preventDefault();
                        const pos = getPos(e);

                        // 使用中點二階貝茲曲線平滑渲染
                        const midX = (lastX + pos.x) / 2;
                        const midY = (lastY + pos.y) / 2;
                        this.canvasCtx.quadraticCurveTo(lastX, lastY, midX, midY);
                        this.canvasCtx.stroke();

                        lastX = pos.x;
                        lastY = pos.y;
                    };

                    const up = e => {
                        if (!isDrawing) return;
                        isDrawing = false;
                        try {
                            canvas.releasePointerCapture(e.pointerId);
                        } catch (err) {}
                        this.canvasCtx.lineTo(lastX, lastY);
                        this.canvasCtx.stroke();
                        this.canvasCtx.closePath();
                    };

                    canvas.addEventListener('pointerdown', down, { passive: false });
                    canvas.addEventListener('pointermove', move, { passive: false });
                    canvas.addEventListener('pointerup', up, { passive: false });
                    canvas.addEventListener('pointercancel', up, { passive: false });

                    this._sigListeners = { down, move, up };
                },

                clearCanvas() {
                    const canvas = document.getElementById('sigCanvas');
                    if (canvas && this.canvasCtx) {
                        const dpr = window.devicePixelRatio || 1;
                        this.canvasCtx.clearRect(0, 0, canvas.width / dpr, canvas.height / dpr);
                        this.hasDrawnSignature = false;
                    }
                },

                saveSignature() {
                    const canvas = document.getElementById('sigCanvas');
                    if (canvas && this.hasDrawnSignature) {
                        this.signatureImg = canvas.toDataURL('image/png');
                    }
                    this.closeSignatureModal();
                },



                // 提交巡檢紀錄

                async submitCheck() {

                    if (!this.selectedTown || !this.selectedRdid) {

                        alert('請先選擇行政區與巡檢道路！');

                        return;

                    }



                    if (!this.signatureImg) {

                        alert('請先完成稽查人員手寫簽名！');

                        this.openSignatureModal();

                        return;

                    }



                    const payload = {

                        Mode: this.mode,

                        ChkId: this.chkId,

                        Rdid: this.selectedRdid,

                        Signature: this.signatureImg,

                        Points: this.pointList.map(pt => {

                            return {

                                PointId: pt.PointId,

                                PIndex: pt.PIndex,

                                STree: pt.STree,

                                SIsland: pt.SIsland,

                                CivilSide: pt.CivilSide,

                                Scores: Object.values(pt.Scores)

                            };

                        })

                    };



                    this.saving = true;

                    try {

                        const res = await axios.post('NewCleanChk.aspx?action=save', payload);

                        if (res.data.Success) {

                            alert('🎉 巡檢紀錄已成功儲存！單號：' + res.data.ChkId);

                            window.location.href = 'Clean_List.aspx';

                        } else {

                            alert('儲存失敗：' + res.data.Message);

                        }

                    } catch (e) {

                        alert('通訊異常，請稍後再試！');

                    } finally {

                        this.saving = false;

                    }

                },



                // 讀取既有紀錄

                async fetchRecord(chkId) {

                    try {

                        const res = await axios.get('NewCleanChk.aspx?action=getRecord&chkId=' + encodeURIComponent(chkId));

                        if (res.data.Success) {

                            const d = res.data;

                            this.chkId = d.ChkId || chkId;

                            if (d.ChkDate) this.chkDate = d.ChkDate;

                            this.caseState = d.CaseState || 1001;

                            this.examineMemo = d.ExamineMemo || '';



                            // 1. 設置行政區並載入該行政區道路清單

                            this.selectedTown = (d.Town || '').trim();

                            await this.fetchRoadsByTown(this.selectedTown);



                            // 2. 設置巡檢道路並載入檢核點與題庫

                            this.selectedRdid = (d.Rdid || '').trim();

                            await this.onRoadChange();



                            // 3. 回填現場環境狀況 (行道樹、分隔島、營建工地)

                            if (d.PointMain && d.PointMain.length > 0) {

                                d.PointMain.forEach(pm => {

                                    const pmPointId = (pm.PointId || '').trim();

                                    const pt = this.pointList.find(p => (p.PointId || '').trim() === pmPointId || (p.PIndex && p.PIndex === pm.PIndex));

                                    if (pt) {

                                        if (pm.STree) pt.STree = pm.STree;

                                        if (pm.SIsland) pt.SIsland = pm.SIsland;

                                        if (pm.CivilSide) pt.CivilSide = pm.CivilSide;

                                    }

                                });

                            }



                            // 4. 回填評分與缺失原因資料 (防禦寬鬆比對與數字轉換)

                            if (d.Scores && d.Scores.length > 0) {

                                d.Scores.forEach(s => {

                                    const sPointId = (s.PointId || '').trim();

                                    const sChkCode = (s.ChkCode || '').trim();

                                    const pt = this.pointList.find(p => (p.PointId || '').trim() === sPointId || (p.PIndex && p.PIndex === s.PIndex));

                                    if (pt) {

                                        if (!pt.Scores[sChkCode]) {

                                            pt.Scores[sChkCode] = { ChkCode: sChkCode, Score: 100, ChiItem1: '' };

                                        }

                                        pt.Scores[sChkCode].Score = (s.Score !== null && s.Score !== undefined) ? Number(s.Score) : null;

                                        pt.Scores[sChkCode].ChiItem1 = (s.ChiItem1 || '').trim();

                                    }

                                });

                            }



                            // 5. 回填稽查人員手寫簽章

                            this.signatureImg = d.Signature || '';



                        } else {

                            this.showAlert(res.data.Message || '查無此巡檢紀錄！', 'danger');

                        }

                    } catch (e) {

                        console.error('紀錄載入失敗', e);

                        this.showAlert('載入巡檢紀錄時發生連線或伺服器錯誤', 'danger');

                    }

                },



                goBack() {

                    let targetMode = this.listMode;

                    if (!targetMode) {

                        if (this.caseState === 2301) targetMode = 'back';

                        else if (this.caseState === 2001) targetMode = 'examine';

                        else if (this.caseState === 2101) targetMode = 'search';

                        else if (this.caseState === 1001 || this.caseState === 2201) targetMode = 'apply';

                        else if (this.mode === 'read') targetMode = 'search';

                        else targetMode = 'apply';

                    }

                    window.location.href = 'Clean_List.aspx?mode=' + encodeURIComponent(targetMode);

                }

            }

        }).mount('#cleanApp');

    </script>

</body>

</html>

