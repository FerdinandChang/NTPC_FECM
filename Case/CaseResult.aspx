<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="CaseResult.aspx.cs" Inherits="NTPC_FEC.Case.CaseResult" %>

<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定溢散源管理平台 - 固定污染源查核結果確認單</title>

    <!-- 專屬 Favicon -->
    <link rel="shortcut icon" href="../favicon.ico" type="image/x-icon" />

    <!-- Bootstrap 4 & FontAwesome 本地化樣式 -->
    <link rel="stylesheet" href="../Content/bootstrap.min.css" />
    <link rel="stylesheet" href="../Content/fontawesome/css/all.min.css" />

    <!-- Leaflet.js 本地化樣式 -->
    <link rel="stylesheet" href="../Content/leaflet/leaflet.css" />

    <style>
        :root {
            --brand-primary: #0099e5;
            --brand-blue: #0284c7;
            --brand-dark-blue: #0b1f7d;
            --brand-navy: #0f172a;
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

        .nav-btn {
            background: rgba(255, 255, 255, 0.18);
            border: none;
            color: #ffffff;
            font-size: 0.92rem;
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

        .brand-title {
            font-size: 1.05rem;
            font-weight: 700;
            margin: 0;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        /* 主容器佈局 */
        .container-fluid-custom {
            max-width: 1560px;
            margin: 0 auto;
            padding: 16px;
        }

        /* 現代卡片 */
        .card-modern {
            background: var(--surface);
            border-radius: 12px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05), 0 4px 12px rgba(15, 23, 42, 0.05);
            margin-bottom: 16px;
            border: 1px solid var(--border-color);
            overflow: hidden;
            transition: border-color 0.2s, box-shadow 0.2s;
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
            left: 16%;
            right: 16%;
            height: 3px;
            background: #e2e8f0;
            z-index: 1;
        }

        .stepper-line-fill {
            height: 100%;
            background: #10b981;
            transition: width 0.4s ease;
        }

        /* 地圖控制與收合 */
        #map {
            width: 100%;
            height: 280px;
            border-radius: 8px;
            z-index: 10;
            transition: height 0.3s ease;
        }

        #map.map-collapsed {
            height: 80px !important;
        }

        /* 標記 Pin */
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

        .marker-num {
            transform: rotate(45deg);
            color: #ffffff;
            font-weight: 800;
            font-size: 13px;
        }

        /* 統計資訊晶片 (Stat Chips) */
        .stat-chips-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(130px, 1fr));
            gap: 10px;
            margin-bottom: 12px;
        }

        .stat-chip {
            background: #f8fafc;
            border: 1px solid var(--border-color);
            border-radius: 8px;
            padding: 8px 10px;
        }

        .stat-chip-label {
            font-size: 11px;
            color: var(--text-muted);
            margin-bottom: 2px;
            font-weight: 600;
        }

        .stat-chip-value {
            font-size: 13px;
            font-weight: 700;
            color: var(--brand-navy);
            word-break: break-all;
        }

        /* 缺失點數儀表大字 */
        .loss-badge-score {
            font-size: 2.2rem;
            font-weight: 800;
            line-height: 1;
        }

        /* 查核設施清單樣式 */
        .section-item-card {
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 12px;
            margin-bottom: 12px;
            background: #ffffff;
            transition: all 0.2s;
        }

        .section-item-card.has-loss {
            border-left: 5px solid #ef4444;
            background: #fffafa;
        }

        .section-item-card.no-loss {
            border-left: 5px solid #10b981;
        }

        .section-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 8px;
        }

        .section-title {
            font-size: 14px;
            font-weight: 700;
            color: #1e293b;
        }

        /* 照片縮圖列 */
        .photo-gallery-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
            gap: 12px;
            margin-top: 10px;
        }

        .photo-thumb-card {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 6px;
            text-align: center;
            cursor: pointer;
            transition: transform 0.2s, box-shadow 0.2s;
        }

        .photo-thumb-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 10px rgba(0, 0, 0, 0.08);
            border-color: #cbd5e1;
        }

        .photo-thumb-img {
            width: 100%;
            height: 100px;
            object-fit: cover;
            border-radius: 6px;
            background: #e2e8f0;
        }

        .photo-thumb-label {
            font-size: 11px;
            font-weight: 700;
            color: #334155;
            margin-top: 4px;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .photo-thumb-memo {
            font-size: 10px;
            color: #64748b;
            margin-top: 2px;
            line-height: 1.2;
            height: 24px;
            overflow: hidden;
            display: -webkit-box;
            -webkit-line-clamp: 2;
            -webkit-box-orient: vertical;
        }

        /* 三方簽名板專區 */
        .sig-panel-grid {
            display: grid;
            grid-template-columns: 1fr;
            gap: 12px;
        }

        .sig-box {
            background: #f8fafc;
            border: 1px solid var(--border-color);
            border-radius: 8px;
            padding: 12px;
            display: flex;
            flex-direction: column;
            gap: 8px;
        }

        .sig-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .sig-title {
            font-size: 13px;
            font-weight: 700;
            color: #334155;
            display: flex;
            align-items: center;
            gap: 6px;
        }

        .sig-preview-area {
            width: 100%;
            height: 120px;
            background: #ffffff;
            border: 1px dashed #cbd5e1;
            border-radius: 6px;
            display: flex;
            align-items: center;
            justify-content: center;
            overflow: hidden;
            position: relative;
        }

        .sig-preview-img {
            max-width: 100%;
            max-height: 100%;
            object-fit: contain;
        }

        /* 全螢幕平滑手寫簽名板 */
        .sig-modal-backdrop {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(15, 23, 42, 0.75);
            backdrop-filter: blur(4px);
            z-index: 2000;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 12px;
        }

        .sig-modal-container {
            background: #ffffff;
            border-radius: 12px;
            width: 100%;
            max-width: 640px;
            overflow: hidden;
            box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.3);
            display: flex;
            flex-direction: column;
        }

        .sig-modal-header {
            padding: 12px 16px;
            background: #0f172a;
            color: #ffffff;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .sig-canvas-container {
            width: 100%;
            height: 320px;
            background: #ffffff;
            touch-action: none;
            position: relative;
        }

        #sigCanvas {
            width: 100%;
            height: 100%;
            cursor: crosshair;
            display: block;
        }

        .sig-modal-footer {
            padding: 12px 16px;
            background: #f8fafc;
            border-top: 1px solid #e2e8f0;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        /* 圖片放大 Lightbox Modal */
        .lightbox-backdrop {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(0, 0, 0, 0.85);
            z-index: 2100;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 16px;
        }

        .lightbox-content {
            max-width: 90vw;
            max-height: 90vh;
            border-radius: 8px;
            box-shadow: 0 10px 25px rgba(0, 0, 0, 0.5);
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

        /* 列印專用樣式 */
        .print-only-header {
            display: none;
        }

        @media print {
            .no-print {
                display: none !important;
            }

            body {
                background: #ffffff;
                font-size: 12pt;
                color: #000000;
            }

            .container-fluid-custom {
                max-width: 100% !important;
                padding: 0 !important;
            }

            .print-only-header {
                display: block !important;
                text-align: center;
                margin-bottom: 20px;
                border-bottom: 2px solid #000000;
                padding-bottom: 10px;
            }

            .print-only-header h2 {
                font-size: 18pt;
                font-weight: 800;
                margin: 0 0 6px 0;
            }

            .print-only-header p {
                font-size: 11pt;
                margin: 0;
                color: #333333;
            }

            .card-modern {
                box-shadow: none !important;
                border: 1px solid #cccccc !important;
                break-inside: avoid;
                margin-bottom: 12px !important;
            }

            .col-xl-5, .col-xl-7 {
                max-width: 100% !important;
                flex: 0 0 100% !important;
            }

            .sticky-sidebar {
                position: static !important;
                max-height: none !important;
                overflow: visible !important;
            }

            #map {
                display: none !important;
            }

            .sig-preview-area {
                height: 90px !important;
                border: 1px solid #999999 !important;
            }

            .photo-thumb-card {
                break-inside: avoid;
            }
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div id="app" v-cloak>
            <!-- 1. 置頂深青藍導覽列 (Sticky Top Navbar) -->
            <header class="top-navbar no-print">
                <div class="d-flex align-items-center">
                    <button type="button" class="nav-btn mr-2" v-on:click="goBack" title="返回案件清單">
                        <i class="fas fa-arrow-left"></i>
                        <span class="d-none d-sm-inline">返回清單</span>
                    </button>
                    <div class="brand-title">
                        <i class="fas fa-file-signature text-white"></i>
                        <span>固定污染源查核結果確認單</span>
                        <span v-if="facInfo.C_NO" class="badge badge-light text-dark font-weight-bold ml-2" style="font-size: 0.85rem;">
                            {{ facInfo.C_NO }}
                        </span>
                    </div>
                </div>

                <div class="d-flex align-items-center gap-2">
                    <!-- 列印案件按鈕 (白底黑字陰影膠囊) -->
                    <button type="button" class="nav-btn bg-white text-dark shadow-sm" v-on:click="printResult" title="列印成果報告單">
                        <i class="fas fa-print mr-1"></i>
                        <span class="d-none d-md-inline">列印案件</span>
                    </button>

                    <!-- 路線導航按鈕 -->
                    <button v-if="facInfo.Lat && facInfo.Lng" type="button" class="nav-btn bg-white text-dark shadow-sm ml-2" v-on:click="openGoogleMaps" title="開啟 Google 地圖導航">
                        <i class="fas fa-location-arrow text-success mr-1"></i>
                        <span class="d-none d-md-inline">路線導航</span>
                    </button>

                    <!-- 儲存送出按鈕 (非唯讀模式) -->
                    <button v-if="mode !== 'read'" type="button" class="btn btn-success btn-sm font-weight-bold ml-2 shadow-sm" v-on:click="submitSave" :disabled="saving">
                        <i class="fas fa-check-circle mr-1"></i>
                        <span>{{ saving ? '儲存中...' : '儲存簽章確認' }}</span>
                    </button>
                </div>
            </header>

            <!-- 2. 列印專用報表頁首 -->
            <div class="print-only-header">
                <h2>新北市政府環境保護局 固定污染源逸散防制設施現場查核成果單</h2>
                <p>公私場所：{{ facInfo.FAC_NAME }} (管制編號: {{ facInfo.C_NO }}) ｜ 查核日期：{{ recordData.INV_DATE }}</p>
            </div>

            <!-- 3. 主作業容器 -->
            <main class="container-fluid-custom">
                <!-- A. 通報階段進度時間軸 (Status Stepper) -->
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
                        <div class="step-time">{{ recordData.INV_DATE || '未填寫' }}</div>
                    </div>

                    <!-- 步驟 2: 三方簽署確認 -->
                    <div class="step-item" :class="getStepClass(2)">
                        <div class="step-circle">
                            <i v-if="numericStatusCode > 2" class="fas fa-check"></i>
                            <span v-else>2</span>
                        </div>
                        <div class="step-title">三方簽章確認</div>
                        <div class="step-time">{{ hasAllSignatures ? '已全數簽署' : '待確認簽章' }}</div>
                    </div>

                    <!-- 步驟 3: 改善結案 / 歸檔 -->
                    <div class="step-item" :class="getStepClass(3)">
                        <div class="step-circle">
                            <i v-if="numericStatusCode === 3" class="fas fa-check"></i>
                            <span v-else>3</span>
                        </div>
                        <div class="step-title">{{ recordData.TotalLossPoint === 0 ? '查核合格結案' : '限期改善完成' }}</div>
                        <div class="step-time">{{ recordData.TotalLossPoint === 0 ? '即刻合格' : (recordData.ImproveDeadline || '限期改善') }}</div>
                    </div>
                </div>

                <!-- B. 雙欄卡片佈局 -->
                <div class="row">
                    <!-- 左欄 (40% 寬度，Sticky 側邊固頂) -->
                    <div class="col-xl-5 col-lg-5 col-md-12">
                        <div class="sticky-sidebar">
                            <!-- 卡片 1: 場所基本資料 -->
                            <div class="card-modern">
                                <div class="card-modern-header">
                                    <h3 class="card-modern-title">
                                        <i class="fas fa-building text-primary"></i>
                                        場所基本資料
                                    </h3>
                                    <span class="badge badge-secondary">{{ facInfo.FAC_ID }}</span>
                                </div>
                                <div class="card-modern-body">
                                    <div class="stat-chips-grid">
                                        <div class="stat-chip">
                                            <div class="stat-chip-label">管制編號</div>
                                            <div class="stat-chip-value">{{ facInfo.C_NO || '無' }}</div>
                                        </div>
                                        <div class="stat-chip">
                                            <div class="stat-chip-label">負責人</div>
                                            <div class="stat-chip-value">{{ facInfo.BOSS_NAME || '未填' }}</div>
                                        </div>
                                        <div class="stat-chip">
                                            <div class="stat-chip-label">電話</div>
                                            <div class="stat-chip-value">{{ facInfo.TEL || '未填' }}</div>
                                        </div>
                                        <div class="stat-chip">
                                            <div class="stat-chip-label">查核天氣</div>
                                            <div class="stat-chip-value"><i class="fas fa-cloud-sun text-warning mr-1"></i>{{ recordData.weather || '晴' }}</div>
                                        </div>
                                    </div>

                                    <div class="mb-2">
                                        <small class="text-muted d-block font-weight-bold">場所名稱：</small>
                                        <span class="font-weight-bold text-dark" style="font-size: 1.05rem;">{{ facInfo.FAC_NAME }}</span>
                                    </div>
                                    <div class="mb-2">
                                        <small class="text-muted d-block font-weight-bold">場所地址：</small>
                                        <span class="text-dark">{{ facInfo.ADDR || '未填寫地址' }}</span>
                                    </div>
                                    <div class="mb-2">
                                        <small class="text-muted d-block font-weight-bold">查核日期時間：</small>
                                        <span class="text-dark font-weight-bold"><i class="far fa-clock text-info mr-1"></i>{{ recordData.INV_DATE }}</span>
                                    </div>
                                    <div class="mb-2">
                                        <small class="text-muted d-block font-weight-bold">操作狀況：</small>
                                        <span class="badge badge-info p-1 px-2 font-weight-bold">{{ recordData.Work_State || '正常操作' }}</span>
                                        <span class="text-muted ml-2" v-if="recordData.Work_Memo && recordData.Work_Memo !== '無'">({{ recordData.Work_Memo }})</span>
                                    </div>
                                </div>
                            </div>

                            <!-- 卡片 2: 現場智慧地圖 (Leaflet) -->
                            <div class="card-modern no-print">
                                <div class="card-modern-header">
                                    <h3 class="card-modern-title">
                                        <i class="fas fa-map-marked-alt text-primary"></i>
                                        現場位置定位
                                    </h3>
                                    <div class="d-flex align-items-center gap-1">
                                        <button type="button" class="btn btn-sm btn-outline-secondary py-1 px-2" v-on:click="toggleMapCollapse" :title="mapCollapsed ? '展開地圖' : '收合地圖'">
                                            <i :class="mapCollapsed ? 'fas fa-chevron-down' : 'fas fa-chevron-up'"></i>
                                            <span class="d-none d-sm-inline ml-1">{{ mapCollapsed ? '展開' : '收合' }}</span>
                                        </button>
                                        <button type="button" class="btn btn-sm btn-outline-primary py-1 px-2 ml-1" v-on:click="resetMapView" title="重設地圖全景視角">
                                            <i class="fas fa-crosshairs"></i>
                                        </button>
                                    </div>
                                </div>
                                <div class="card-modern-body p-2">
                                    <div id="map" :class="{ 'map-collapsed': mapCollapsed }"></div>
                                </div>
                            </div>

                            <!-- 卡片 3: 三方電子簽章確認 (核心亮點) -->
                            <div class="card-modern">
                                <div class="card-modern-header">
                                    <h3 class="card-modern-title">
                                        <i class="fas fa-signature text-primary"></i>
                                        三方電子簽章確認
                                    </h3>
                                    <span v-if="mode === 'read'" class="badge badge-secondary">唯讀檢視</span>
                                    <span v-else class="badge badge-success">待簽署確認</span>
                                </div>
                                <div class="card-modern-body">
                                    <div class="sig-panel-grid">
                                        <!-- 1. 稽查人員 (Sig1) -->
                                        <div class="sig-box">
                                            <div class="sig-header">
                                                <div class="sig-title">
                                                    <i class="fas fa-user-shield text-info"></i>
                                                    <span>環保局稽查人員</span>
                                                </div>
                                                <div class="d-flex align-items-center gap-1">
                                                    <span v-if="signatures.sig1" class="badge badge-success">已簽署</span>
                                                    <span v-else class="badge badge-secondary">未簽署</span>
                                                    <button v-if="mode !== 'read'" type="button" class="btn btn-xs btn-outline-primary py-0 px-2 ml-2" v-on:click="openSignatureModal('sig1', '環保局稽查人員')">
                                                        <i class="fas fa-pen"></i> {{ signatures.sig1 ? '重簽' : '簽名' }}
                                                    </button>
                                                </div>
                                            </div>
                                            <div class="sig-preview-area">
                                                <img v-if="signatures.sig1" :src="signatures.sig1" class="sig-preview-img" alt="稽查人員簽名" />
                                                <span v-else class="text-muted small"><i class="fas fa-pen-nib mr-1"></i>點擊「簽名」進行手寫簽章</span>
                                            </div>
                                        </div>

                                        <!-- 2. 會同人員 (Sig2) -->
                                        <div class="sig-box">
                                            <div class="sig-header">
                                                <div class="sig-title">
                                                    <i class="fas fa-user-friends text-secondary"></i>
                                                    <span>會同人員 / 陪同人員</span>
                                                </div>
                                                <div class="d-flex align-items-center gap-1">
                                                    <span v-if="signatures.sig2" class="badge badge-success">已簽署</span>
                                                    <span v-else class="badge badge-secondary">未簽署</span>
                                                    <button v-if="mode !== 'read'" type="button" class="btn btn-xs btn-outline-primary py-0 px-2 ml-2" v-on:click="openSignatureModal('sig2', '會同人員 / 陪同人員')">
                                                        <i class="fas fa-pen"></i> {{ signatures.sig2 ? '重簽' : '簽名' }}
                                                    </button>
                                                </div>
                                            </div>
                                            <div class="sig-preview-area">
                                                <img v-if="signatures.sig2" :src="signatures.sig2" class="sig-preview-img" alt="會同人員簽名" />
                                                <span v-else class="text-muted small"><i class="fas fa-pen-nib mr-1"></i>點擊「簽名」進行手寫簽章</span>
                                            </div>
                                        </div>

                                        <!-- 3. 廠方代表 (Sig3) -->
                                        <div class="sig-box">
                                            <div class="sig-header">
                                                <div class="sig-title">
                                                    <i class="fas fa-user-tie text-success"></i>
                                                    <span>受檢廠方代表確認</span>
                                                </div>
                                                <div class="d-flex align-items-center gap-1">
                                                    <span v-if="signatures.sig3" class="badge badge-success">已簽署</span>
                                                    <span v-else class="badge badge-secondary">未簽署</span>
                                                    <button v-if="mode !== 'read'" type="button" class="btn btn-xs btn-outline-primary py-0 px-2 ml-2" v-on:click="openSignatureModal('sig3', '受檢廠方代表')">
                                                        <i class="fas fa-pen"></i> {{ signatures.sig3 ? '重簽' : '簽名' }}
                                                    </button>
                                                </div>
                                            </div>
                                            <div class="sig-preview-area">
                                                <img v-if="signatures.sig3" :src="signatures.sig3" class="sig-preview-img" alt="廠方代表簽名" />
                                                <span v-else class="text-muted small"><i class="fas fa-pen-nib mr-1"></i>點擊「簽名」進行手寫簽章</span>
                                            </div>
                                        </div>
                                    </div>

                                    <!-- 底部動作按鈕 (桌面固頂欄底) -->
                                    <div class="mt-3 pt-3 border-top no-print d-flex gap-2">
                                        <button v-if="mode !== 'read'" type="button" class="btn btn-success font-weight-bold flex-fill" v-on:click="submitSave" :disabled="saving">
                                            <i class="fas fa-save mr-1"></i> {{ saving ? '儲存中...' : '儲存簽章確認' }}
                                        </button>
                                        <button type="button" class="btn btn-outline-secondary font-weight-bold" v-on:click="goBack">
                                            <i class="fas fa-times mr-1"></i> {{ mode === 'read' ? '關閉' : '取消' }}
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- 右欄 (60% 寬度，主查核成果展示作業區) -->
                    <div class="col-xl-7 col-lg-7 col-md-12">
                        <!-- 卡片 1: 查核總結與缺失判定卡片 -->
                        <div class="card-modern">
                            <div class="card-modern-header">
                                <h3 class="card-modern-title">
                                    <i class="fas fa-clipboard-check text-primary"></i>
                                    查核結果判定與改善期限
                                </h3>
                                <span class="badge p-2" :class="recordData.TotalLossPoint === 0 ? 'badge-success' : (recordData.TotalLossPoint < 10 ? 'badge-warning text-dark' : 'badge-danger')" style="font-size: 0.9rem;">
                                    {{ recordData.TotalLossPoint === 0 ? '查核合格' : (recordData.TotalLossPoint < 10 ? '限期改善' : '重大違規') }}
                                </span>
                            </div>
                            <div class="card-modern-body">
                                <div class="row align-items-center mb-3">
                                    <div class="col-sm-4 text-center border-right">
                                        <small class="text-muted d-block font-weight-bold">缺失點數合計</small>
                                        <div class="loss-badge-score my-1" :class="recordData.TotalLossPoint === 0 ? 'text-success' : 'text-danger'">
                                            {{ recordData.TotalLossPoint }}
                                            <small style="font-size: 1rem;">點</small>
                                        </div>
                                        <span v-if="recordData.TotalLossPoint === 0" class="badge badge-success">完全合格</span>
                                        <span v-else-if="recordData.TotalLossPoint < 10" class="badge badge-warning text-dark">未達10點</span>
                                        <span v-else class="badge badge-danger">達10點(含)以上</span>
                                    </div>
                                    <div class="col-sm-8 pl-sm-3 mt-3 mt-sm-0">
                                        <!-- 0 點: 無缺失 -->
                                        <div v-if="recordData.TotalLossPoint === 0" class="alert alert-success m-0">
                                            <h5 class="alert-heading font-weight-bold"><i class="fas fa-check-circle mr-1"></i> 本次查核符合防制法規標準！</h5>
                                            <p class="mb-0 small">公私場所各項逸散性粒狀污染物防制設施均依規定妥善採行，現場無重大揚塵或違反規定情形，予以合格結案。</p>
                                        </div>

                                        <!-- 1~9 點: 限期改善 -->
                                        <div v-else-if="recordData.TotalLossPoint < 10" class="alert alert-warning m-0 text-dark">
                                            <h6 class="font-weight-bold text-danger"><i class="fas fa-exclamation-triangle mr-1"></i> 缺失點數合計未達10點，限期改善。</h6>
                                            <div class="my-2 d-flex align-items-center flex-wrap gap-2">
                                                <span class="font-weight-bold text-dark">改善期限：</span>
                                                <input v-if="mode !== 'read'" type="date" class="form-control form-control-sm d-inline-block" style="max-width: 170px; font-weight: bold;" v-model="recordData.ImproveDeadline" />
                                                <span v-else class="badge badge-danger font-weight-bold p-1 px-2" style="font-size: 0.95rem;">{{ recordData.ImproveDeadline }}</span>
                                            </div>
                                            <small class="text-danger d-block font-weight-bold">(屆期未改善或未完成改善者，依違反本辦法規定處分)</small>
                                        </div>

                                        <!-- 10 點(含)以上: 重大違規 -->
                                        <div v-else class="alert alert-danger m-0">
                                            <h6 class="font-weight-bold text-danger"><i class="fas fa-times-circle mr-1"></i> 稽查當次之缺失點數合計10點(含)以上！</h6>
                                            <p class="mb-0 small">缺失嚴重或未設置必要防制設施，依空氣污染防制法相關規定逕行處分。</p>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- 卡片 2: 9 大防制設施詳細查核結果清單與佐證照片 -->
                        <div class="card-modern">
                            <div class="card-modern-header">
                                <h3 class="card-modern-title">
                                    <i class="fas fa-th-list text-primary"></i>
                                    防制設施詳細查核結果 (9大項目)
                                </h3>
                                <small class="text-muted">包含現場缺失項目與成果照片</small>
                            </div>
                            <div class="card-modern-body">
                                <div v-for="sec in sections" :key="sec.Id" class="section-item-card" :class="sec.LossPoint > 0 ? 'has-loss' : 'no-loss'">
                                    <div class="section-header">
                                        <div class="section-title">
                                            <span class="badge badge-pill badge-primary mr-2">{{ sec.Id }}</span>
                                            {{ sec.Title }}
                                        </div>
                                        <div>
                                            <span v-if="sec.LossPoint === 0" class="badge badge-success"><i class="fas fa-check mr-1"></i>合格 (0點)</span>
                                            <span v-else class="badge badge-danger"><i class="fas fa-exclamation mr-1"></i>缺失扣 {{ sec.LossPoint }} 點</span>
                                        </div>
                                    </div>

                                    <!-- 違規項目清單 -->
                                    <div v-if="sec.Violations && sec.Violations.length > 0" class="mb-2 p-2 rounded" style="background-color: #fee2e2;">
                                        <small class="font-weight-bold text-danger d-block mb-1"><i class="fas fa-times-circle mr-1"></i> 現場查核缺失情事：</small>
                                        <ul class="mb-0 pl-3 small text-danger font-weight-bold">
                                            <li v-for="v in sec.Violations" :key="v">{{ v }}</li>
                                        </ul>
                                    </div>

                                    <!-- 合格項清單 (若無違規) -->
                                    <div v-else-if="sec.CompliantItems && sec.CompliantItems.length > 0" class="mb-2 p-2 rounded" style="background-color: #ecfdf5;">
                                        <small class="font-weight-bold text-success d-block mb-1"><i class="fas fa-check-circle mr-1"></i> 符合規範項目：</small>
                                        <div class="small text-success">
                                            <span v-for="(ci, cidx) in sec.CompliantItems" :key="ci">
                                                {{ ci }}<span v-if="cidx < sec.CompliantItems.length - 1">、</span>
                                            </span>
                                        </div>
                                    </div>

                                    <!-- 第五項：洗車台規格專用顯示區 -->
                                    <div v-if="sec.Id === 5" class="stat-chips-grid my-2">
                                        <div class="stat-chip">
                                            <div class="stat-chip-label">洗車設備型式</div>
                                            <div class="stat-chip-value">{{ recordData.WashCar_Type || '加壓沖洗設備' }}</div>
                                        </div>
                                        <div class="stat-chip">
                                            <div class="stat-chip-label">沖洗平台長寬</div>
                                            <div class="stat-chip-value">{{ recordData.WashCar_Length || '-' }} x {{ recordData.WashCar_Width || '-' }} m</div>
                                        </div>
                                        <div class="stat-chip">
                                            <div class="stat-chip-label">水槽深度 / 水深</div>
                                            <div class="stat-chip-value">{{ recordData.SinkDepth || '-' }} / {{ recordData.SinkWaterDepth || '-' }} cm</div>
                                        </div>
                                        <div class="stat-chip">
                                            <div class="stat-chip-label">加壓馬達馬力</div>
                                            <div class="stat-chip-value">{{ recordData.MotorHP || '-' }} HP</div>
                                        </div>
                                    </div>

                                    <!-- 佐證照片列表 -->
                                    <div v-if="getSectionPhotos(sec).length > 0">
                                        <small class="text-muted font-weight-bold d-block mt-2"><i class="fas fa-camera text-info mr-1"></i> 現場查核佐證照片：</small>
                                        <div class="photo-gallery-grid">
                                            <div v-for="p in getSectionPhotos(sec)" :key="p.Key" class="photo-thumb-card" v-on:click="openLightbox(p.Url, p.Label, p.Memo)">
                                                <img :src="p.Url" class="photo-thumb-img" :alt="p.Label" />
                                                <div class="photo-thumb-label">{{ p.Label }}</div>
                                                <div class="photo-thumb-memo" :title="p.Memo">{{ p.Memo || '無說明' }}</div>
                                            </div>
                                        </div>
                                    </div>
                                    <div v-else class="text-muted small mt-1">
                                        <i class="fas fa-info-circle mr-1"></i> 本項目無上傳現場佐證照片
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- 卡片 3: 環境潛勢調查及許可不符項目 -->
                        <div class="card-modern">
                            <div class="card-modern-header">
                                <h3 class="card-modern-title">
                                    <i class="fas fa-exclamation-circle text-primary"></i>
                                    環境潛勢調查及許可不符項目
                                </h3>
                                <button type="button" class="btn btn-sm btn-outline-info py-1 px-2 no-print" v-on:click="openDeviceModal">
                                    <i class="fas fa-industry mr-1"></i> 原物料與製程設備資料
                                </button>
                            </div>
                            <div class="card-modern-body">
                                <div class="row mb-3">
                                    <div class="col-md-6">
                                        <small class="text-muted d-block font-weight-bold">環境潛勢調查項目：</small>
                                        <span class="font-weight-bold text-dark">{{ recordData.EnvirCheck_Item || '無明顯環境潛勢問題' }}</span>
                                        <div v-if="recordData.EnvirCheck_Other" class="small text-muted mt-1">其他說明: {{ recordData.EnvirCheck_Other }}</div>
                                    </div>
                                    <div class="col-md-6">
                                        <small class="text-muted d-block font-weight-bold">許可不符查核狀態：</small>
                                        <span class="badge" :class="recordData.OtherChkAns1 === '有' ? 'badge-danger' : 'badge-success'">{{ recordData.OtherChkAns1 || '無' }}</span>
                                        <span class="ml-2 text-dark font-weight-bold" v-if="recordData.OtherChkAns2">({{ recordData.OtherChkAns2 }})</span>
                                        <div v-if="recordData.OtherChkMemo" class="small text-muted mt-1">說明: {{ recordData.OtherChkMemo }}</div>
                                    </div>
                                </div>

                                <!-- 許可不符照片 -->
                                <div v-if="existingPhotos.File_10a || existingPhotos.File_10b">
                                    <small class="text-muted font-weight-bold d-block"><i class="fas fa-camera text-info mr-1"></i> 許可不符佐證照片：</small>
                                    <div class="photo-gallery-grid">
                                        <div v-if="existingPhotos.File_10a" class="photo-thumb-card" v-on:click="openLightbox(existingPhotos.File_10a, '許可不符照片 1', recordData.FileMemo_10a)">
                                            <img :src="existingPhotos.File_10a" class="photo-thumb-img" alt="許可不符照片 1" />
                                            <div class="photo-thumb-label">許可不符照片 1</div>
                                            <div class="photo-thumb-memo">{{ recordData.FileMemo_10a || '無說明' }}</div>
                                        </div>
                                        <div v-if="existingPhotos.File_10b" class="photo-thumb-card" v-on:click="openLightbox(existingPhotos.File_10b, '許可不符照片 2', recordData.FileMemo_10b)">
                                            <img :src="existingPhotos.File_10b" class="photo-thumb-img" alt="許可不符照片 2" />
                                            <div class="photo-thumb-label">許可不符照片 2</div>
                                            <div class="photo-thumb-memo">{{ recordData.FileMemo_10b || '無說明' }}</div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- 卡片 4: 執行道路髒污抽查 -->
                        <div class="card-modern">
                            <div class="card-modern-header">
                                <h3 class="card-modern-title">
                                    <i class="fas fa-road text-primary"></i>
                                    執行道路髒污抽查
                                </h3>
                                <span class="badge" :class="recordData.CleanRoad_Ans1 === '是' ? 'badge-info' : 'badge-secondary'">
                                    {{ recordData.CleanRoad_Ans1 === '是' ? '有抽查認養路段' : '未抽查' }}
                                </span>
                            </div>
                            <div class="card-modern-body">
                                <div class="row">
                                    <div class="col-md-6 mb-2">
                                        <small class="text-muted d-block font-weight-bold">抽查道路路名：</small>
                                        <span class="font-weight-bold text-dark">{{ recordData.CleanRoad_Ans2_RoadName || '無指定路名' }}</span>
                                    </div>
                                    <div class="col-md-6 mb-2">
                                        <small class="text-muted d-block font-weight-bold">路段清潔狀況等級：</small>
                                        <span v-if="recordData.CleanRoad_Ans2_CleanLV_A === 'Y'" class="badge badge-success mr-1">良好(A級) {{ recordData.CleanRoad_Ans2_CleanLength_A }}m</span>
                                        <span v-if="recordData.CleanRoad_Ans2_CleanLV_B === 'Y'" class="badge badge-info mr-1">普通(B級) {{ recordData.CleanRoad_Ans2_CleanLength_B }}m</span>
                                        <span v-if="recordData.CleanRoad_Ans2_CleanLV_C === 'Y'" class="badge badge-danger mr-1">待改進(C級) {{ recordData.CleanRoad_Ans2_CleanLength_C }}m</span>
                                        <span v-if="!recordData.CleanRoad_Ans2_CleanLV_A && !recordData.CleanRoad_Ans2_CleanLV_B && !recordData.CleanRoad_Ans2_CleanLV_C" class="text-muted">未註記</span>
                                    </div>
                                    <div class="col-md-6 mb-2">
                                        <small class="text-muted d-block font-weight-bold">水溝是否保持暢通：</small>
                                        <span class="badge" :class="recordData.CleanRoad_Ans3 === '是' ? 'badge-success' : 'badge-warning'">{{ recordData.CleanRoad_Ans3 || '是' }}</span>
                                    </div>
                                    <div class="col-md-6 mb-2" v-if="recordData.CleanRoad_Ans4">
                                        <small class="text-muted d-block font-weight-bold">抽查備註說明：</small>
                                        <span class="text-dark">{{ recordData.CleanRoad_Ans4 }}</span>
                                    </div>
                                </div>

                                <!-- 道路抽查照片 -->
                                <div v-if="existingPhotos.File_11a || existingPhotos.File_11b" class="mt-2">
                                    <small class="text-muted font-weight-bold d-block"><i class="fas fa-camera text-info mr-1"></i> 道路抽查照片：</small>
                                    <div class="photo-gallery-grid">
                                        <div v-if="existingPhotos.File_11a" class="photo-thumb-card" v-on:click="openLightbox(existingPhotos.File_11a, '道路抽查照片 1', recordData.FileMemo_11a)">
                                            <img :src="existingPhotos.File_11a" class="photo-thumb-img" alt="道路抽查照片 1" />
                                            <div class="photo-thumb-label">道路抽查照片 1</div>
                                            <div class="photo-thumb-memo">{{ recordData.FileMemo_11a || '無說明' }}</div>
                                        </div>
                                        <div v-if="existingPhotos.File_11b" class="photo-thumb-card" v-on:click="openLightbox(existingPhotos.File_11b, '道路抽查照片 2', recordData.FileMemo_11b)">
                                            <img :src="existingPhotos.File_11b" class="photo-thumb-img" alt="道路抽查照片 2" />
                                            <div class="photo-thumb-label">道路抽查照片 2</div>
                                            <div class="photo-thumb-memo">{{ recordData.FileMemo_11b || '無說明' }}</div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </main>

            <!-- 4. 全螢幕平滑手寫簽名板 Modal (Pointer Events + 貝茲曲線) -->
            <div v-if="sigModalOpen" class="sig-modal-backdrop no-print" v-on:click.self="closeSignatureModal">
                <div class="sig-modal-container">
                    <div class="sig-modal-header">
                        <h5 class="m-0 font-weight-bold" style="font-size: 1.05rem;">
                            <i class="fas fa-signature mr-2"></i>請於下方空白區手寫簽名 ({{ currentSigRoleName }})
                        </h5>
                        <button type="button" class="btn btn-sm btn-outline-light py-0 px-2" v-on:click="closeSignatureModal">&times;</button>
                    </div>
                    <div class="sig-canvas-container">
                        <canvas id="sigCanvas"></canvas>
                    </div>
                    <div class="sig-modal-footer">
                        <button type="button" class="btn btn-outline-danger font-weight-bold" v-on:click="clearSignature">
                            <i class="fas fa-eraser mr-1"></i> 清除重寫
                        </button>
                        <div class="d-flex gap-2">
                            <button type="button" class="btn btn-secondary font-weight-bold" v-on:click="closeSignatureModal">
                                取消
                            </button>
                            <button type="button" class="btn btn-primary font-weight-bold ml-2" v-on:click="applySignature">
                                <i class="fas fa-check mr-1"></i> 確認簽署
                            </button>
                        </div>
                    </div>
                </div>
            </div>

            <!-- 5. 圖片放大檢視 Lightbox Modal -->
            <div v-if="lightboxOpen" class="lightbox-backdrop no-print" v-on:click="closeLightbox">
                <div class="text-center" style="max-width: 90vw;">
                    <img :src="lightboxUrl" class="lightbox-content img-fluid mb-2" alt="大圖檢視" />
                    <div class="text-white font-weight-bold" style="font-size: 1.1rem;">{{ lightboxTitle }}</div>
                    <div class="text-light small mt-1" v-if="lightboxMemo">說明: {{ lightboxMemo }}</div>
                    <div class="text-muted small mt-2">點擊任意處關閉</div>
                </div>
            </div>

            <!-- 6. 原物料與製程設備統計 Modal -->
            <div v-if="deviceModalOpen" class="sig-modal-backdrop no-print" v-on:click.self="deviceModalOpen = false">
                <div class="sig-modal-container" style="max-width: 720px; max-height: 85vh; overflow-y: auto;">
                    <div class="sig-modal-header">
                        <h5 class="m-0 font-weight-bold" style="font-size: 1.05rem;">
                            <i class="fas fa-industry mr-2"></i> 申報原物料與防制設備統計
                        </h5>
                        <button type="button" class="btn btn-sm btn-outline-light py-0 px-2" v-on:click="deviceModalOpen = false">&times;</button>
                    </div>
                    <div class="p-3">
                        <table class="table table-sm table-bordered table-striped">
                            <thead class="thead-light">
                                <tr>
                                    <th style="width: 25%;">設備類型代碼</th>
                                    <th>設備名稱</th>
                                    <th style="width: 25%; text-align: center;">申報數量</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr v-for="d in devSummary" :key="d.pCode + d.Device_Name">
                                    <td><span class="badge badge-secondary">{{ d.pCode }}</span></td>
                                    <td>{{ d.Device_Name }}</td>
                                    <td class="text-center font-weight-bold text-primary">{{ d.pCount }}</td>
                                </tr>
                                <tr v-if="!devSummary || devSummary.length === 0">
                                    <td colspan="3" class="text-center text-muted py-3">無申報防制設備資料</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                    <div class="sig-modal-footer justify-content-end">
                        <button type="button" class="btn btn-secondary font-weight-bold" v-on:click="deviceModalOpen = false">關閉</button>
                    </div>
                </div>
            </div>

            <!-- 7. 手機版底部常駐懸浮工具列 -->
            <div class="mobile-bottom-bar no-print">
                <button type="button" class="btn btn-outline-primary" v-on:click="openSignatureModal('sig1', '稽查人員')">
                    <i class="fas fa-pen mr-1"></i> 手寫簽名
                </button>
                <button v-if="mode !== 'read'" type="button" class="btn btn-success" v-on:click="submitSave" :disabled="saving">
                    <i class="fas fa-save mr-1"></i> {{ saving ? '儲存中...' : '儲存簽章' }}
                </button>
            </div>
        </div>
    </form>

    <!-- 本地核心腳本引用 (嚴禁依賴外部 CDN) -->
    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>
    <script src="../Scripts/bootstrap.bundle.min.js"></script>
    <script src="../Scripts/leaflet/leaflet.js"></script>

    <script>
        const { createApp, markRaw } = Vue;

        createApp({
            data() {
                return {
                    loading: true,
                    saving: false,
                    facId: '',
                    invNo: 0,
                    mode: 'edit',
                    backParam: '0',
                    facInfo: {},
                    recordData: {},
                    sections: [],
                    devSummary: [],
                    existingPhotos: {},
                    signatures: {
                        sig1: '',
                        sig2: '',
                        sig3: ''
                    },

                    // 地圖控制
                    mapCollapsed: false,

                    // 簽名彈窗
                    sigModalOpen: false,
                    currentSigKey: 'sig1',
                    currentSigRoleName: '環保局稽查人員',
                    canvasCtx: null,

                    // Lightbox 大圖彈窗
                    lightboxOpen: false,
                    lightboxUrl: '',
                    lightboxTitle: '',
                    lightboxMemo: '',

                    // 設備 Modal
                    deviceModalOpen: false
                };
            },
            computed: {
                // 狀態代碼計算
                numericStatusCode() {
                    if (this.hasAllSignatures) return 3;
                    if (this.signatures.sig1 || this.signatures.sig2 || this.signatures.sig3) return 2;
                    return 1;
                },
                stepperProgress() {
                    if (this.numericStatusCode === 3) return 100;
                    if (this.numericStatusCode === 2) return 50;
                    return 0;
                },
                hasAllSignatures() {
                    return Boolean(this.signatures.sig1 && this.signatures.sig3);
                }
            },
            mounted() {
                this.initData();
            },
            methods: {
                // 1. 初始化頁面資料
                async initData() {
                    const urlParams = new URLSearchParams(window.location.search);
                    this.facId = urlParams.get('id') || '';
                    const token = urlParams.get('id1') || '';
                    const invNo = urlParams.get('id2') || '0';
                    this.mode = urlParams.get('mode') || 'edit';
                    this.backParam = urlParams.get('back') || '0';

                    if (!this.facId || !invNo || invNo === '0') {
                        alert('缺少必要之場所編號或查核編號！');
                        return;
                    }

                    try {
                        const resp = await axios.get(`CaseResult.aspx?action=init&id=${encodeURIComponent(this.facId)}&id1=${encodeURIComponent(token)}&id2=${encodeURIComponent(invNo)}&mode=${encodeURIComponent(this.mode)}&back=${encodeURIComponent(this.backParam)}`);
                        if (resp.data && resp.data.Success) {
                            this.facInfo = resp.data.FacInfo || {};
                            this.recordData = resp.data.RecordData || {};
                            this.sections = resp.data.Sections || [];
                            this.devSummary = resp.data.DevSummary || [];
                            this.existingPhotos = resp.data.ExistingPhotos || {};
                            this.signatures = resp.data.Signatures || { sig1: '', sig2: '', sig3: '' };

                            // 初始化現場地圖
                            this.$nextTick(() => {
                                this.initMap();
                            });
                        } else {
                            alert(resp.data.Message || '資料載入失敗！');
                        }
                    } catch (err) {
                        console.error('載入失敗:', err);
                        alert('系統通訊異常，請稍後再試。');
                    } finally {
                        this.loading = false;
                    }
                },

                // 2. 初始化現場地圖 (Leaflet)
                initMap() {
                    const mapEl = document.getElementById('map');
                    if (!mapEl || this.leafletMap) return;

                    let lat = this.facInfo.Lat || 25.0123;
                    let lng = this.facInfo.Lng || 121.4657;

                    const map = L.map('map', {
                        center: [lat, lng],
                        zoom: 16,
                        zoomControl: true
                    });

                    L.tileLayer('https://wmts.nlsc.gov.tw/wmts/EMAP/default/GoogleMapsCompatible/{z}/{y}/{x}', {
                        maxZoom: 19,
                        attribution: '&copy; 內政部臺灣通用電子地圖'
                    }).addTo(map);

                    // 標記 Pin
                    if (this.facInfo.Lat && this.facInfo.Lng) {
                        const markerHtml = `
                            <div class="custom-map-marker">
                                <div class="marker-pin">
                                    <span class="marker-num"><i class="fas fa-industry"></i></span>
                                </div>
                            </div>
                        `;
                        const icon = L.divIcon({
                            html: markerHtml,
                            className: '',
                            iconSize: [32, 32],
                            iconAnchor: [16, 32]
                        });
                        L.marker([lat, lng], { icon: icon })
                            .addTo(map)
                            .bindPopup(`<b>${this.facInfo.FAC_NAME}</b><br/>${this.facInfo.ADDR || ''}`)
                            .openPopup();
                    }

                    // 物件隔離防止 Vue 響應式污染
                    this.leafletMap = markRaw(map);
                },

                // 地圖操作
                toggleMapCollapse() {
                    this.mapCollapsed = !this.mapCollapsed;
                    this.$nextTick(() => {
                        if (this.leafletMap) this.leafletMap.invalidateSize();
                    });
                },
                resetMapView() {
                    if (!this.leafletMap) return;
                    let lat = this.facInfo.Lat || 25.0123;
                    let lng = this.facInfo.Lng || 121.4657;
                    this.leafletMap.setView([lat, lng], 16);
                },
                openGoogleMaps() {
                    if (this.facInfo.Lat && this.facInfo.Lng) {
                        window.open(`https://www.google.com/maps/dir/?api=1&destination=${this.facInfo.Lat},${this.facInfo.Lng}`);
                    }
                },

                // 3. 獲取項目照片清單
                getSectionPhotos(sec) {
                    if (!sec || !sec.Photos) return [];
                    const res = [];
                    sec.Photos.forEach(p => {
                        if (this.existingPhotos[p.Key]) {
                            res.push({
                                Key: p.Key,
                                Label: p.Label,
                                Memo: p.Memo,
                                Url: this.existingPhotos[p.Key]
                            });
                        }
                    });
                    return res;
                },

                // 4. 階段樣式
                getStepClass(step) {
                    if (this.numericStatusCode > step) return 'completed';
                    if (this.numericStatusCode === step) return 'active';
                    return '';
                },

                // 5. 手寫簽名彈窗 (Pointer Events API + 貝茲曲線)
                openSignatureModal(sigKey, roleName) {
                    this.currentSigKey = sigKey;
                    this.currentSigRoleName = roleName;
                    this.sigModalOpen = true;

                    this.$nextTick(() => {
                        this.initCanvas();
                    });
                },
                closeSignatureModal() {
                    this.sigModalOpen = false;
                },
                initCanvas() {
                    const canvas = document.getElementById('sigCanvas');
                    if (!canvas) return;
                    const container = canvas.parentElement;
                    const rect = container.getBoundingClientRect();
                    const dpr = window.devicePixelRatio || 1;

                    canvas.width = Math.round(rect.width * dpr);
                    canvas.height = Math.round(rect.height * dpr);
                    canvas.style.width = rect.width + 'px';
                    canvas.style.height = rect.height + 'px';

                    this.canvasCtx = canvas.getContext('2d');
                    this.canvasCtx.scale(dpr, dpr);
                    this.canvasCtx.strokeStyle = '#0f172a';
                    this.canvasCtx.lineWidth = 3.5;
                    this.canvasCtx.lineCap = 'round';
                    this.canvasCtx.lineJoin = 'round';

                    let isDrawing = false;
                    let lastX = 0, lastY = 0;

                    const getPos = e => {
                        const r = canvas.getBoundingClientRect();
                        return { x: e.clientX - r.left, y: e.clientY - r.top };
                    };

                    const down = e => {
                        e.preventDefault();
                        try { canvas.setPointerCapture(e.pointerId); } catch (err) {}
                        isDrawing = true;
                        const pos = getPos(e);
                        lastX = pos.x; lastY = pos.y;
                        this.canvasCtx.beginPath();
                        this.canvasCtx.moveTo(lastX, lastY);
                    };

                    const move = e => {
                        if (!isDrawing) return;
                        e.preventDefault();
                        const pos = getPos(e);
                        const midX = (lastX + pos.x) / 2;
                        const midY = (lastY + pos.y) / 2;
                        this.canvasCtx.quadraticCurveTo(lastX, lastY, midX, midY);
                        this.canvasCtx.stroke();
                        lastX = pos.x; lastY = pos.y;
                    };

                    const up = e => {
                        if (!isDrawing) return;
                        isDrawing = false;
                        try { canvas.releasePointerCapture(e.pointerId); } catch (err) {}
                        this.canvasCtx.lineTo(lastX, lastY);
                        this.canvasCtx.stroke();
                        this.canvasCtx.closePath();
                    };

                    canvas.addEventListener('pointerdown', down, { passive: false });
                    canvas.addEventListener('pointermove', move, { passive: false });
                    canvas.addEventListener('pointerup', up, { passive: false });
                    canvas.addEventListener('pointercancel', up, { passive: false });
                },
                clearSignature() {
                    const canvas = document.getElementById('sigCanvas');
                    if (canvas && this.canvasCtx) {
                        const dpr = window.devicePixelRatio || 1;
                        this.canvasCtx.clearRect(0, 0, canvas.width / dpr, canvas.height / dpr);
                    }
                },
                applySignature() {
                    const canvas = document.getElementById('sigCanvas');
                    if (!canvas) return;
                    const dataUrl = canvas.toDataURL('image/png');
                    this.signatures[this.currentSigKey] = dataUrl;
                    this.sigModalOpen = false;
                },

                // 6. Lightbox 照片放大檢視
                openLightbox(url, title, memo) {
                    this.lightboxUrl = url;
                    this.lightboxTitle = title;
                    this.lightboxMemo = memo;
                    this.lightboxOpen = true;
                },
                closeLightbox() {
                    this.lightboxOpen = false;
                },

                // 7. 設備 Modal 開啟
                openDeviceModal() {
                    this.deviceModalOpen = true;
                },

                // 8. 儲存結果與簽章
                async submitSave() {
                    if (this.saving) return;
                    this.saving = true;

                    const payload = {
                        facId: this.facInfo.FAC_ID,
                        invNo: this.recordData.INV_NO,
                        improveDeadline: this.recordData.ImproveDeadline,
                        sig1: this.signatures.sig1,
                        sig2: this.signatures.sig2,
                        sig3: this.signatures.sig3
                    };

                    try {
                        const resp = await axios.post('CaseResult.aspx?action=save', payload);
                        if (resp.data && resp.data.Success) {
                            alert(resp.data.Message || '儲存成功！');
                            this.goBack();
                        } else {
                            alert(resp.data.Message || '儲存失敗，請重試！');
                        }
                    } catch (err) {
                        console.error('儲存異常:', err);
                        alert('儲存作業發生異常，請檢查網路連線。');
                    } finally {
                        this.saving = false;
                    }
                },

                // 9. 返回清單
                goBack() {
                    if (this.backParam === '1') {
                        window.location.href = 'CaseList.aspx?mode=reject';
                    } else if (this.backParam === '2') {
                        window.close();
                    } else {
                        window.location.href = 'CaseList.aspx';
                    }
                },

                // 10. 列印案件成果
                printResult() {
                    window.print();
                }
            }
        }).mount('#app');
    </script>
</body>
</html>
