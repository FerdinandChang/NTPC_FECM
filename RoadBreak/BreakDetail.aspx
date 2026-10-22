<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="BreakDetail.aspx.cs" Inherits="NTPC_FEC.RoadBreak.BreakDetail" %>

<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定溢散源管理平台 - 道路污染通報案件檢視</title>

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
            --accent-success: #10b981;    /* 綠色成功/合格 */
            --accent-warning: #f59e0b;    /* 黃橘色注意 */
            --accent-danger: #ef4444;     /* 紅色缺失/危險 */
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

        .top-navbar .brand-title {
            font-size: 1.08rem;
            font-weight: 700;
            margin: 0;
            display: flex;
            align-items: center;
            gap: 8px;
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

        .card-modern:hover {
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.05), 0 10px 20px rgba(15, 23, 42, 0.08);
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

        /* 案件退回警告橫幅 */
        .rejected-banner {
            background: linear-gradient(135deg, #fef2f2 0%, #fee2e2 100%);
            border-left: 5px solid var(--accent-danger);
            border-radius: 8px;
            padding: 14px 16px;
            margin-bottom: 16px;
            color: #991b1b;
        }

        .rejected-banner-title {
            font-weight: 800;
            font-size: 1rem;
            display: flex;
            align-items: center;
            gap: 8px;
            margin-bottom: 6px;
        }

        /* 屬性資料展示表格/網格 */
        .info-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 12px;
        }

        .info-grid-full {
            grid-column: span 2;
        }

        .info-item {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 10px 14px;
        }

        .info-label {
            font-size: 0.8rem;
            color: var(--text-muted);
            font-weight: 600;
            margin-bottom: 4px;
            display: flex;
            align-items: center;
            gap: 6px;
        }

        .info-value {
            font-size: 0.95rem;
            color: var(--brand-navy);
            font-weight: 700;
            word-break: break-all;
        }

        .info-value-highlight {
            color: var(--brand-blue);
        }

        /* 現場地圖容器 */
        #map {
            width: 100%;
            height: 350px;
            border-radius: 8px;
            border: 1px solid var(--border-color);
            z-index: 10;
            transition: height 0.3s ease;
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
            margin: -22px 0 0 -17px;
            box-shadow: 0 4px 10px rgba(0, 0, 0, 0.4);
            border: 2px solid #ffffff;
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
        }

        .marker-pin i {
            transform: rotate(45deg);
            color: #ffffff;
            font-size: 14px;
        }

        /* 照片對比區 (Photo Comparison Gallery) */
        .comparison-card {
            background: #ffffff;
            border: 1px solid #e2e8f0;
            border-radius: 10px;
            overflow: hidden;
            margin-bottom: 16px;
            transition: transform 0.2s, box-shadow 0.2s;
        }

        .comparison-card:hover {
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
        }

        .comparison-header {
            background: #f8fafc;
            padding: 8px 14px;
            font-weight: 700;
            font-size: 0.9rem;
            color: var(--brand-dark-blue);
            border-bottom: 1px solid #e2e8f0;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .comparison-body {
            display: flex;
            flex-direction: row;
            background: #f1f5f9;
            gap: 1px;
        }

        .photo-pane {
            flex: 1;
            background: #ffffff;
            padding: 12px;
            display: flex;
            flex-direction: column;
            min-width: 0;
        }

        .photo-tag {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 4px 10px;
            border-radius: 6px;
            font-size: 0.8rem;
            font-weight: 700;
            margin-bottom: 8px;
            align-self: flex-start;
        }

        .photo-tag-before {
            background: #fee2e2;
            color: #b91c1c;
        }

        .photo-tag-after {
            background: #ecfdf5;
            color: #047857;
        }

        .photo-frame {
            position: relative;
            width: 100%;
            height: 240px;
            border-radius: 8px;
            background-color: #f8fafc;
            border: 1px solid #e2e8f0;
            display: flex;
            align-items: center;
            justify-content: center;
            overflow: hidden;
            cursor: pointer;
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
            bottom: 0;
            left: 0;
            right: 0;
            padding: 8px 12px;
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
            height: 240px;
            border-radius: 8px;
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
            font-size: 2.2rem;
            margin-bottom: 8px;
            color: #cbd5e1;
        }

        .photo-meta {
            margin-top: 8px;
            font-size: 0.8rem;
            color: var(--text-muted);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        /* 照片燈箱 (Lightbox Modal) */
        .lightbox-modal {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(15, 23, 42, 0.92);
            z-index: 1060;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }

        .lightbox-content {
            position: relative;
            max-width: 90vw;
            max-height: 82vh;
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
            background: rgba(0, 0, 0, 0.5);
            padding: 8px 18px;
            border-radius: 30px;
            backdrop-filter: blur(8px);
        }

        .lightbox-close-btn {
            position: absolute;
            top: -40px;
            right: 0;
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

        /* 手機端底部懸浮列 (Mobile Bottom Sticky Bar) */
        @media screen and (max-width: 991px) {
            body {
                padding-bottom: 74px;
            }

            .info-grid {
                grid-template-columns: 1fr;
            }

            .info-grid-full {
                grid-column: span 1;
            }

            .comparison-body {
                flex-direction: column;
            }

            .photo-frame, .photo-empty {
                height: 200px;
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
                font-size: 0.9rem;
            }
        }

        @media screen and (min-width: 992px) {
            .mobile-bottom-bar {
                display: none;
            }
        }

        /* 友善列印樣式 (Print Optimization) */
        @media print {
            .top-navbar, .mobile-bottom-bar, .no-print, .lightbox-modal {
                display: none !important;
            }

            body {
                background: #ffffff !important;
                color: #000000 !important;
                font-size: 12pt;
                padding: 0;
                margin: 0;
            }

            .container-fluid {
                width: 100% !important;
                max-width: 100% !important;
                padding: 0 !important;
            }

            .card-modern {
                box-shadow: none !important;
                border: 1px solid #000000 !important;
                page-break-inside: avoid;
                margin-bottom: 12px !important;
            }

            .card-modern-header {
                background: #f1f5f9 !important;
                border-bottom: 1px solid #000000 !important;
                color: #000000 !important;
            }

            .info-item {
                border: 1px solid #cccccc !important;
                background: #ffffff !important;
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
                border: 1px solid #cccccc !important;
            }

            .photo-frame img {
                max-height: 180px !important;
            }

            .print-header {
                display: block !important;
                text-align: center;
                margin-bottom: 20px;
                border-bottom: 2px solid #000000;
                padding-bottom: 10px;
            }

            .print-header h2 {
                margin: 0;
                font-weight: bold;
                font-size: 18pt;
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
            <!-- 1. 頂部導覽列 -->
            <header class="top-navbar no-print">
                <div class="brand-title">
                    <button type="button" class="nav-btn mr-2" v-on:click="goBack" title="返回清單">
                        <i class="fas fa-arrow-left"></i>
                        <span class="d-none d-sm-inline">返回清單</span>
                    </button>
                    <i class="fas fa-file-alt text-white"></i>
                    <span>道路污染通報案件檢視</span>
                    <span v-if="caseData.Show_ID" class="badge badge-light text-dark font-weight-bold ml-2" style="font-size: 0.85rem;">
                        {{ caseData.Show_ID }}
                    </span>
                </div>

                <div class="d-flex align-items-center gap-2">
                    <!-- 列印案件按鈕 (BSCDetail 風格) -->
                    <button type="button" class="nav-btn bg-white text-dark shadow-sm" v-on:click="printReport" title="列印案件">
                        <i class="fas fa-print"></i>
                        <span class="d-none d-md-inline">列印案件</span>
                    </button>

                    <!-- Google 導航 -->
                    <button v-if="caseData.Lat && caseData.Lng" type="button" class="nav-btn bg-white text-dark shadow-sm ml-2" v-on:click="openGoogleMaps" title="以 Google Maps 開啟位置導航">
                        <i class="fas fa-location-arrow text-success"></i>
                        <span class="d-none d-md-inline">路線導航</span>
                    </button>

                    <!-- 依案件權限與狀態切換操作按鈕 -->
                    <a v-if="userPerms.CanEdit" :href="'NewBreak.aspx?id=' + encodeURIComponent(caseData.Break_ID)" class="btn btn-warning btn-sm font-weight-bold shadow-sm ml-2" title="編輯案件">
                        <i class="fas fa-edit mr-1"></i> 編輯案件
                    </a>

                    <a v-if="userPerms.CanDispatch" :href="'SetSG_Break.aspx?id=' + encodeURIComponent(caseData.Break_ID)" class="btn btn-primary btn-sm font-weight-bold shadow-sm ml-2" title="派工通報">
                        <i class="fas fa-paper-plane mr-1"></i> 派工通報
                    </a>

                    <a v-if="userPerms.CanImprove" :href="'ImproveBreak.aspx?id=' + encodeURIComponent(caseData.Break_ID)" class="btn btn-success btn-sm font-weight-bold shadow-sm ml-2" title="改善回報">
                        <i class="fas fa-tools mr-1"></i> 改善回報
                    </a>
                </div>
            </header>

            <!-- 列印專用抬頭 (僅在列印時顯示) -->
            <div class="print-header">
                <h2>新北市固定溢散源管理平台 - 道路髒污破損通報案件紀錄單</h2>
                <div class="d-flex justify-content-between mt-2">
                    <span>通報案號：<strong>{{ caseData.Show_ID }}</strong></span>
                    <span>列印時間：<strong>{{ currentPrintTime }}</strong></span>
                    <span>案件狀態：<strong>{{ caseData.StatusText }}</strong></span>
                </div>
            </div>

            <!-- 主作業容器 -->
            <div class="container-fluid py-3 px-3 px-lg-4">
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
                    <!-- 退回警示 Banner (若 G_Back === 'Y') -->
                    <div v-if="caseData.G_Back === 'Y'" class="rejected-banner shadow-sm">
                        <div class="rejected-banner-title">
                            <i class="fas fa-ban"></i>
                            <span>非處理單位權責，本案件已退回</span>
                        </div>
                        <div class="d-flex flex-wrap gap-2 text-danger font-weight-bold mb-1">
                            <span class="mr-3"><i class="fas fa-building mr-1"></i>退回單位：{{ caseData.G_COM_NAME || '未指定' }}</span>
                            <span class="mr-3"><i class="fas fa-user mr-1"></i>回報人員：{{ caseData.G_UserName || '未填寫' }}</span>
                            <span><i class="fas fa-clock mr-1"></i>退回日期：{{ caseData.Improve_Date || '未記錄' }}</span>
                        </div>
                        <div class="mt-1 bg-white p-2 rounded border border-danger">
                            <span class="font-weight-bold text-dark">退回說明備註：</span>
                            <span class="text-danger">{{ caseData.G_Memo || '無詳細說明' }}</span>
                        </div>
                    </div>

                    <!-- 雙欄版面配置 (Desktop 雙欄，Mobile 單欄) -->
                    <div class="row">
                        <!-- 左側欄：案件基本資料、道路現況、地圖與進度 -->
                        <div class="col-12 col-xl-5 mb-3">
                            <!-- 基本通報資訊卡片 -->
                            <div class="card-modern">
                                <div class="card-modern-header">
                                    <h2 class="card-modern-title">
                                        <i class="fas fa-info-circle text-primary"></i>
                                        <span>通報案件基本資訊</span>
                                    </h2>
                                    <span class="badge" :class="caseData.StatusBadgeClass">{{ caseData.StatusText }}</span>
                                </div>
                                <div class="card-modern-body">
                                    <div class="info-grid">
                                        <div class="info-item">
                                            <div class="info-label"><i class="fas fa-hashtag"></i>通報案號</div>
                                            <div class="info-value info-value-highlight">{{ caseData.Show_ID }}</div>
                                        </div>
                                        <div class="info-item">
                                            <div class="info-label"><i class="fas fa-calendar-alt"></i>查核時間</div>
                                            <div class="info-value">{{ caseData.Report_Date || '無紀錄' }}</div>
                                        </div>
                                        <div class="info-item">
                                            <div class="info-label"><i class="fas fa-user-check"></i>查核人員</div>
                                            <div class="info-value">{{ caseData.Report_UserName || '未填' }}</div>
                                        </div>
                                        <div class="info-item">
                                            <div class="info-label"><i class="fas fa-tag"></i>通報類別</div>
                                            <div class="info-value">{{ caseData.KIND_Name }}</div>
                                        </div>
                                        <div class="info-item">
                                            <div class="info-label"><i class="fas fa-building"></i>通報單位</div>
                                            <div class="info-value">{{ caseData.S_COM_NAME || '未指定' }}</div>
                                        </div>
                                        <div class="info-item">
                                            <div class="info-label"><i class="fas fa-clock"></i>通報時間</div>
                                            <div class="info-value">{{ caseData.SetCOM_Date || '無紀錄' }}</div>
                                        </div>
                                        <div class="info-item info-grid-full">
                                            <div class="info-label"><i class="fas fa-user-edit"></i>通報人員</div>
                                            <div class="info-value">{{ caseData.S_UserName || '未填' }}</div>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- 道路現況與鋪面狀況卡片 -->
                            <div class="card-modern">
                                <div class="card-modern-header">
                                    <h2 class="card-modern-title">
                                        <i class="fas fa-road text-primary"></i>
                                        <span>道路現況與破損評估</span>
                                    </h2>
                                </div>
                                <div class="card-modern-body">
                                    <div class="info-grid">
                                        <div class="info-item">
                                            <div class="info-label"><i class="fas fa-map-marker-alt"></i>行政區</div>
                                            <div class="info-value font-weight-bold text-dark">{{ caseData.TOWN_NA || '未填' }}</div>
                                        </div>
                                        <div class="info-item">
                                            <div class="info-label"><i class="fas fa-layer-group"></i>道路級別</div>
                                            <div class="info-value">{{ caseData.ROAD_LV || '未填' }}</div>
                                        </div>
                                        <div class="info-item info-grid-full">
                                            <div class="info-label"><i class="fas fa-map-signs"></i>道路名稱</div>
                                            <div class="info-value info-value-highlight">{{ caseData.ROAD_Name || '未填' }}</div>
                                        </div>
                                        <div class="info-item">
                                            <div class="info-label"><i class="fas fa-align-justify"></i>鋪面平整度</div>
                                            <div class="info-value">{{ caseData.Smooth_Str || '未評定' }}</div>
                                        </div>
                                        <div class="info-item">
                                            <div class="info-label"><i class="fas fa-circle-notch"></i>人手孔蓋銜接狀況</div>
                                            <div class="info-value">{{ caseData.Hole_Conn_St_Str || '未評定' }}</div>
                                        </div>
                                        <div class="info-item info-grid-full">
                                            <div class="info-label"><i class="fas fa-compass"></i>通報坐標 (TWD97 / WGS84)</div>
                                            <div class="info-value" style="font-size:0.875rem;">
                                                <span>TWD97: E {{ caseData.S_UTME || '-' }}, N {{ caseData.S_UTMN || '-' }}</span>
                                                <div v-if="caseData.Lat && caseData.Lng" class="text-muted mt-1">
                                                    WGS84: {{ caseData.Lat.toFixed(6) }}, {{ caseData.Lng.toFixed(6) }}
                                                </div>
                                            </div>
                                        </div>
                                        <div class="info-item info-grid-full">
                                            <div class="info-label"><i class="fas fa-comment-alt"></i>通報補充說明</div>
                                            <div class="info-value" style="font-weight: 500; white-space: pre-wrap;">{{ caseData.Memo || '無補充說明' }}</div>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- 地理位置地圖卡片 (Leaflet) -->
                            <div class="card-modern">
                                <div class="card-modern-header">
                                    <h2 class="card-modern-title">
                                        <i class="fas fa-map-marked-alt text-primary"></i>
                                        <span>案件發生地理位置</span>
                                    </h2>
                                    <div class="d-flex align-items-center gap-2 no-print">
                                        <button v-if="caseData.Lat && caseData.Lng" type="button" class="btn btn-xs btn-outline-primary btn-sm px-2 py-1" v-on:click="resetMapView" title="重新置中地圖">
                                            <i class="fas fa-crosshairs mr-1"></i>置中
                                        </button>
                                        <button v-if="caseData.Lat && caseData.Lng" type="button" class="btn btn-xs btn-outline-success btn-sm px-2 py-1" v-on:click="openGoogleMaps" title="以 Google Maps 開啟">
                                            <i class="fas fa-external-link-alt mr-1"></i>導航
                                        </button>
                                        <button type="button" class="btn btn-xs btn-outline-secondary btn-sm px-2 py-1 d-md-none" v-on:click="toggleMapCollapse">
                                            {{ isMapCollapsed ? '展開' : '收合' }}
                                        </button>
                                    </div>
                                </div>
                                <div class="card-modern-body p-2">
                                    <div id="map" :class="{ 'map-collapsed': isMapCollapsed }"></div>
                                    <div v-if="!caseData.Lat || !caseData.Lng" class="text-center text-muted py-3">
                                        <i class="fas fa-map-pin fa-2x mb-2 text-warning"></i>
                                        <div>此案件尚未記錄有效坐標，無法於地圖展示定位點。</div>
                                    </div>
                                </div>
                            </div>

                            <!-- 處理單位與改善進度卡片 -->
                            <div class="card-modern">
                                <div class="card-modern-header">
                                    <h2 class="card-modern-title">
                                        <i class="fas fa-tools text-primary"></i>
                                        <span>處理單位與改善進度</span>
                                    </h2>
                                    <span v-if="caseData.Improve_Date" class="badge badge-success">已回報</span>
                                    <span v-else-if="caseData.G_COM" class="badge badge-warning text-dark">處理中</span>
                                    <span v-else class="badge badge-secondary">待分派</span>
                                </div>
                                <div class="card-modern-body">
                                    <div class="info-grid">
                                        <div class="info-item info-grid-full">
                                            <div class="info-label"><i class="fas fa-landmark"></i>權責處理單位</div>
                                            <div class="info-value font-weight-bold" :class="caseData.G_COM_NAME ? 'text-primary' : 'text-muted'">
                                                {{ caseData.G_COM_NAME || '尚未分派處理單位' }}
                                            </div>
                                        </div>
                                        <div class="info-item">
                                            <div class="info-label"><i class="fas fa-calendar-check"></i>處理回報日期</div>
                                            <div class="info-value">{{ caseData.Improve_Date || '尚未回報' }}</div>
                                        </div>
                                        <div class="info-item">
                                            <div class="info-label"><i class="fas fa-user-cog"></i>處理回報人員</div>
                                            <div class="info-value">{{ caseData.G_UserName || '尚未回報' }}</div>
                                        </div>
                                        <div class="info-item info-grid-full">
                                            <div class="info-label"><i class="fas fa-clipboard-check"></i>處理改善備註</div>
                                            <div class="info-value" style="font-weight: 500; white-space: pre-wrap;">{{ caseData.G_Memo || '無處理備註' }}</div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- 右側欄：現場佐證照片 vs 改善後照片對比區 -->
                        <div class="col-12 col-xl-7 mb-3">
                            <div class="card-modern">
                                <div class="card-modern-header">
                                    <h2 class="card-modern-title">
                                        <i class="fas fa-images text-primary"></i>
                                        <span>現場照片檢視與成果對比</span>
                                    </h2>
                                    <div class="d-flex align-items-center gap-2">
                                        <span class="badge badge-pill badge-info px-2 py-1">
                                            共 {{ photos.length }} 組佐證點位
                                        </span>
                                    </div>
                                </div>

                                <div class="card-modern-body">
                                    <!-- 若無照片 -->
                                    <div v-if="photos.length === 0" class="text-center py-5">
                                        <i class="fas fa-camera-retro fa-3x text-muted mb-3"></i>
                                        <h5 class="font-weight-bold text-dark">目前無現場照片紀錄</h5>
                                        <p class="text-muted">本案件未上傳現場佐證照片或改善佐證照片。</p>
                                    </div>

                                    <!-- 照片對比清單 -->
                                    <div v-else>
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

                                                    <div v-if="item.BeforeExists" class="photo-meta">
                                                        <span class="text-truncate" :title="item.BeforeFileName">{{ item.BeforeFileName }}</span>
                                                        <a :href="item.BeforeUrl" target="_blank" class="btn btn-xs btn-link p-0 text-primary no-print" title="新分頁檢視原圖">
                                                            <i class="fas fa-external-link-alt"></i> 原圖
                                                        </a>
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

                                                    <div v-if="item.AfterExists" class="photo-meta">
                                                        <span class="text-truncate" :title="item.AfterFileName">{{ item.AfterFileName }}</span>
                                                        <a :href="item.AfterUrl" target="_blank" class="btn btn-xs btn-link p-0 text-success no-print" title="新分頁檢視原圖">
                                                            <i class="fas fa-external-link-alt"></i> 原圖
                                                        </a>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- 照片放大燈箱 (Lightbox Modal) -->
            <div v-if="lightbox.show" class="lightbox-modal no-print" v-on:click.self="closeLightbox">
                <div class="lightbox-content">
                    <button type="button" class="lightbox-close-btn" v-on:click="closeLightbox" title="關閉燈箱">
                        <i class="fas fa-times"></i>
                    </button>
                    <img :src="lightbox.url" :alt="lightbox.title" class="lightbox-img" />
                    <div class="lightbox-toolbar">
                        <span class="font-weight-bold">{{ lightbox.title }}</span>
                        <span>•</span>
                        <span class="text-light" style="font-size:0.85rem;">{{ lightbox.fileName }}</span>
                        <span>•</span>
                        <span class="text-light" style="font-size:0.85rem;">{{ formatFileSize(lightbox.fileSize) }}</span>
                        <a :href="lightbox.url" download class="btn btn-sm btn-outline-light ml-2 py-0 px-2">
                            <i class="fas fa-download mr-1"></i>下載
                        </a>
                        <a :href="lightbox.url" target="_blank" class="btn btn-sm btn-outline-light py-0 px-2">
                            <i class="fas fa-external-link-alt mr-1"></i>原始尺寸
                        </a>
                    </div>
                </div>
            </div>

            <!-- 手機端底部常駐浮動快捷列 (Mobile Bottom Sticky Bar) -->
            <div class="mobile-bottom-bar no-print">
                <button type="button" class="btn btn-outline-secondary" v-on:click="goBack">
                    <i class="fas fa-arrow-left mr-1"></i>上一頁
                </button>
                <button type="button" class="btn btn-primary" v-on:click="printReport">
                    <i class="fas fa-print mr-1"></i>列印
                </button>
                <button v-if="caseData.Lat && caseData.Lng" type="button" class="btn btn-success" v-on:click="openGoogleMaps">
                    <i class="fas fa-location-arrow mr-1"></i>導航
                </button>
                <a v-if="userPerms.CanImprove" :href="'ImproveBreak.aspx?id=' + caseData.Break_ID" class="btn btn-warning font-weight-bold">
                    <i class="fas fa-tools mr-1"></i>改善
                </a>
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
                    loading: true,
                    errorMessage: '',
                    isMapCollapsed: false,
                    currentPrintTime: '',
                    caseData: {
                        Break_ID: '',
                        Show_ID: '',
                        Report_Date: '',
                        Report_UserName: '',
                        S_COM_NAME: '',
                        SetCOM_Date: '',
                        S_UserName: '',
                        KIND: '',
                        KIND_Name: '道路髒污破損(RD)',
                        S_UTME: '',
                        S_UTMN: '',
                        Lat: 0,
                        Lng: 0,
                        TOWN_NA: '',
                        ROAD_LV: '',
                        ROAD_Name: '',
                        Smooth_Str: '',
                        Hole_Conn_St_Str: '',
                        Memo: '',
                        G_COM_NAME: '',
                        Improve_Date: '',
                        G_UserName: '',
                        G_Memo: '',
                        G_Back: '',
                        StatusCode: '',
                        StatusText: '',
                        StatusBadgeClass: 'badge-primary'
                    },
                    photos: [],
                    userPerms: {
                        CanEdit: false,
                        CanDispatch: false,
                        CanImprove: false,
                        UserRole: ''
                    },
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
            created() {
                // Leaflet 實例隔離，絕不放入響應式 data()
                this.leafletMap = null;
                this.marker = null;

                // 取得 QueryString 參數
                const urlParams = new URLSearchParams(window.location.search);
                this.breakId = urlParams.get('id') || '';
                this.parMode = urlParams.get('parmode') || urlParams.get('mode') || '';

                const now = new Date();
                const pad = n => n.toString().padStart(2, '0');
                this.currentPrintTime = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())} ${pad(now.getHours())}:${pad(now.getMinutes())}`;
            },
            mounted() {
                if (!this.breakId) {
                    this.loading = false;
                    this.errorMessage = '網址缺少案件識別碼參數 (id)！';
                    return;
                }
                this.loadCaseDetail();

                // 綁定鍵盤 Esc 關閉燈箱
                window.addEventListener('keydown', (e) => {
                    if (e.key === 'Escape' && this.lightbox.show) {
                        this.closeLightbox();
                    }
                });
            },
            methods: {
                // 載入案件明細與照片對比
                loadCaseDetail() {
                    this.loading = true;
                    this.errorMessage = '';
                    axios.get('BreakDetail.aspx', {
                        params: {
                            action: 'getcasedetail',
                            id: this.breakId
                        }
                    })
                    .then(res => {
                        const data = res.data;
                        if (data.NeedLogin) {
                            alert('登入已逾時，將返回登入頁');
                            window.location.href = '../Login.aspx';
                            return;
                        }
                        if (data.Success) {
                            this.caseData = data.Case;
                            this.photos = data.Photos || [];
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
                            zoom: hasValidCoords ? 16 : 12,
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
                                    <div><strong>狀態：</strong>${this.caseData.StatusText || '通報中'}</div>
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
                        this.leafletMap.setView([this.caseData.Lat, this.caseData.Lng], 16, { animate: true });
                        if (this.marker) {
                            this.marker.openPopup();
                        }
                    }
                },

                // 手機版切換地圖收合/展開
                toggleMapCollapse() {
                    this.isMapCollapsed = !this.isMapCollapsed;
                    setTimeout(() => {
                        if (this.leafletMap) {
                            this.leafletMap.invalidateSize();
                        }
                    }, 350);
                },

                // 開啟 Google 地圖路線規劃導航
                openGoogleMaps() {
                    if (this.caseData.Lat && this.caseData.Lng) {
                        const url = `https://www.google.com/maps/dir/?api=1&destination=${this.caseData.Lat},${this.caseData.Lng}`;
                        window.open(url, '_blank');
                    }
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
                        window.location.href = `Break_List.aspx?mode=${this.parMode}`;
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
