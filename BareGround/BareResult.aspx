<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="BareResult.aspx.cs" Inherits="NTPC_FEC.BareGround.BareResult" %>
<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定溢散源管理平台 - 裸露地現場巡查成果報告</title>

    <!-- 專屬 Favicon -->
    <link rel="shortcut icon" href="../favicon.ico" type="image/x-icon" />

    <!-- 本地化樣式依賴 (避開機房資安阻擋) -->
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

        /* 頂部導覽列 (符合 inspection-ui-standard 規範) */
        .top-navbar {
            background: linear-gradient(135deg, #0099e5 0%, #0284c7 100%);
            color: #ffffff;
            height: 56px;
            display: flex; align-items: center; justify-content: space-between;
            padding: 0 16px;
            box-shadow: 0 2px 10px rgba(0, 153, 229, 0.25);
            position: sticky; top: 0; z-index: 1020;
        }
        .top-navbar .brand-title {
            font-size: 1.08rem; font-weight: 700; margin: 0;
            display: flex; align-items: center; gap: 8px;
        }
        .nav-btn {
            background: rgba(255, 255, 255, 0.18);
            border: none; color: #ffffff;
            font-size: 0.92rem; font-weight: 600; cursor: pointer;
            height: 36px; border-radius: 8px;
            display: inline-flex; align-items: center; justify-content: center;
            padding: 0 14px; gap: 6px;
            transition: all 0.2s; text-decoration: none;
        }
        .nav-btn:hover { background-color: rgba(255, 255, 255, 0.32); color: #ffffff; text-decoration: none; }

        /* 主容器 */
        .container-fluid-custom {
            max-width: 1560px;
            margin: 0 auto;
            padding: 16px;
        }

        /* 桌面端左側欄固頂 */
        @media screen and (min-width: 1200px) {
            .sticky-sidebar {
                position: sticky; top: 72px;
                max-height: calc(100vh - 88px);
                overflow-y: auto; padding-right: 4px;
            }
            .sticky-sidebar::-webkit-scrollbar { width: 6px; }
            .sticky-sidebar::-webkit-scrollbar-thumb { background: #cbd5e1; border-radius: 4px; }
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
            display: flex; align-items: center; justify-content: space-between;
        }
        .card-modern-title {
            font-size: 1rem; font-weight: 700; color: var(--brand-navy); margin: 0;
            display: flex; align-items: center; gap: 8px;
        }
        .card-modern-body { padding: 16px; }

        /* 階段進度時間軸 (Status Stepper) */
        .stepper-container {
            display: flex; align-items: center; justify-content: space-between;
            background: #ffffff; border-radius: 12px;
            padding: 16px 24px; margin-bottom: 16px;
            border: 1px solid var(--border-color); position: relative;
        }
        .step-item {
            display: flex; flex-direction: column; align-items: center;
            position: relative; z-index: 2; flex: 1; text-align: center;
        }
        .step-circle {
            width: 36px; height: 36px; border-radius: 50%;
            background: #e2e8f0; color: #64748b;
            display: flex; align-items: center; justify-content: center;
            font-weight: 700; font-size: 14px; margin-bottom: 6px;
            border: 3px solid #ffffff; box-shadow: 0 0 0 2px #cbd5e1;
            transition: all 0.3s;
        }
        .step-item.active .step-circle { background: var(--brand-blue); color: #ffffff; box-shadow: 0 0 0 2px var(--brand-blue); }
        .step-item.completed .step-circle { background: #10b981; color: #ffffff; box-shadow: 0 0 0 2px #10b981; }
        .step-title { font-size: 13px; font-weight: 700; color: #475569; margin-bottom: 2px; }
        .step-item.active .step-title { color: var(--brand-blue); }
        .step-item.completed .step-title { color: #047857; }
        .step-time { font-size: 11px; color: #94a3b8; }
        .stepper-line { position: absolute; top: 34px; left: 16%; right: 16%; height: 3px; background: #e2e8f0; z-index: 1; }
        .stepper-line-fill { height: 100%; background: #10b981; transition: width 0.4s ease; }

        /* 規格晶片群組 (Stat Chips) */
        .stat-chip-group { display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 12px; }
        .stat-chip {
            background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px;
            padding: 6px 12px; font-size: 13px; font-weight: 600; color: #475569;
            display: inline-flex; align-items: center; gap: 6px;
        }
        .stat-chip strong { color: var(--brand-navy); font-weight: 700; }

        /* 地圖區域 (零遮擋規範) */
        #map {
            width: 100%; height: 320px; border-radius: 8px; z-index: 10;
            transition: height 0.3s ease;
        }
        #map.map-collapsed { height: 90px !important; }

        /* 自訂地圖 Pin */
        .custom-map-marker { display: flex; align-items: center; justify-content: center; }
        .marker-pin {
            width: 34px; height: 34px;
            border-radius: 50% 50% 50% 0;
            background: #0284c7;
            position: absolute; transform: rotate(-45deg);
            left: 50%; top: 50%; margin: -22px 0 0 -17px;
            box-shadow: 0 3px 8px rgba(0, 0, 0, 0.35);
            border: 2px solid #ffffff;
            display: flex; align-items: center; justify-content: center;
            cursor: pointer;
        }
        .marker-icon-inner { transform: rotate(45deg); color: #ffffff; font-size: 14px; }

        /* 數值儀表卡片 (Stat Metric Grid) */
        .metric-grid {
            display: grid; grid-template-columns: repeat(auto-fit, minmax(130px, 1fr));
            gap: 12px; margin-bottom: 16px;
        }
        .metric-card {
            background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 10px;
            padding: 12px; text-align: center;
        }
        .metric-label { font-size: 12px; font-weight: 600; color: #64748b; margin-bottom: 4px; }
        .metric-value { font-size: 1.25rem; font-weight: 800; color: var(--brand-dark-blue); }
        .metric-unit { font-size: 11px; font-weight: 600; color: #94a3b8; margin-left: 2px; }

        /* 現場環境說明區塊 */
        .detail-memo-box {
            background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px;
            padding: 12px 14px; margin-bottom: 12px;
        }
        .detail-memo-title {
            font-size: 13px; font-weight: 700; color: #334155; margin-bottom: 6px;
            display: flex; align-items: center; gap: 6px;
        }
        .detail-memo-content {
            font-size: 13.5px; color: #1e293b; line-height: 1.6; white-space: pre-wrap; word-break: break-all;
        }

        /* 現場照片網格 (Photo Grid) */
        .photo-grid {
            display: grid; grid-template-columns: repeat(2, 1fr);
            gap: 14px;
        }
        @media screen and (max-width: 576px) {
            .photo-grid { grid-template-columns: 1fr; }
        }
        .photo-card {
            background: #ffffff; border: 1px solid #e2e8f0; border-radius: 10px;
            overflow: hidden; transition: transform 0.2s, box-shadow 0.2s;
            position: relative;
        }
        .photo-card:hover { transform: translateY(-2px); box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08); }
        .photo-header {
            background: #f8fafc; border-bottom: 1px solid #e2e8f0;
            padding: 8px 12px; font-size: 13px; font-weight: 700; color: #334155;
            display: flex; align-items: center; justify-content: space-between;
        }
        .photo-wrapper {
            position: relative; width: 100%; padding-top: 66.6%; /* 3:2 比例 */
            background: #f1f5f9; cursor: pointer; overflow: hidden;
        }
        .photo-img {
            position: absolute; top: 0; left: 0; width: 100%; height: 100%;
            object-fit: cover; transition: transform 0.3s ease;
        }
        .photo-card:hover .photo-img { transform: scale(1.03); }
        .photo-placeholder {
            position: absolute; top: 0; left: 0; width: 100%; height: 100%;
            display: flex; flex-direction: column; align-items: center; justify-content: center;
            color: #94a3b8; font-size: 13px;
        }
        .photo-footer {
            padding: 6px 12px; font-size: 11.5px; color: #64748b;
            background: #ffffff; border-top: 1px solid #f1f5f9;
            display: flex; justify-content: space-between;
        }

        /* 簽名板展示區 */
        .signature-preview-box {
            border: 2px dashed #cbd5e1; border-radius: 10px;
            padding: 16px; text-align: center; background: #f8fafc;
            position: relative; min-height: 180px;
            display: flex; flex-direction: column; align-items: center; justify-content: center;
        }
        .signature-img { max-width: 100%; max-height: 160px; object-fit: contain; }

        /* 全螢幕觸控手寫簽名板 (符合標準元件 4) */
        .sig-fullscreen-modal {
            position: fixed; top: 0; left: 0; width: 100vw; height: 100dvh;
            background: rgba(15, 23, 42, 0.75); backdrop-filter: blur(4px);
            z-index: 2000; display: flex; flex-direction: column;
        }
        .sig-modal-header {
            height: 56px; background: #0f172a; color: #ffffff;
            display: flex; align-items: center; justify-content: space-between;
            padding: 0 16px;
        }
        .sig-canvas-container {
            flex: 1; position: relative; width: 100%; background: #ffffff;
            touch-action: none; user-select: none;
        }
        #sigCanvas {
            width: 100%; height: 100%; display: block; touch-action: none;
        }
        .sig-modal-footer {
            height: 64px; background: #ffffff; border-top: 1px solid #e2e8f0;
            display: flex; align-items: center; justify-content: space-between;
            padding: 0 16px; gap: 12px;
        }

        /* 照片燈箱 Modal */
        .lightbox-modal {
            position: fixed; top: 0; left: 0; width: 100vw; height: 100dvh;
            background: rgba(0, 0, 0, 0.9); z-index: 2100;
            display: flex; flex-direction: column; justify-content: center; align-items: center;
        }
        .lightbox-img {
            max-width: 90vw; max-height: 80vh; object-fit: contain;
            border-radius: 6px; box-shadow: 0 8px 32px rgba(0,0,0,0.5);
        }
        .lightbox-close-btn {
            position: absolute; top: 16px; right: 20px;
            background: transparent; border: none; color: #ffffff; font-size: 28px;
            cursor: pointer; z-index: 2110;
        }
        .lightbox-title {
            color: #ffffff; font-size: 15px; margin-top: 12px; font-weight: 600;
        }

        /* 列印專用樣式 (@media print) */
        .print-only-header { display: none; }
        @media print {
            .no-print { display: none !important; }
            body { background: #ffffff !important; color: #000000 !important; }
            .container-fluid-custom { max-width: 100% !important; padding: 0 !important; }
            .card-modern { box-shadow: none !important; border: 1px solid #000000 !important; margin-bottom: 12px !important; }
            .card-modern-header { background: #f0f0f0 !important; border-bottom: 1px solid #000000 !important; }
            .print-only-header {
                display: block !important; text-align: center; margin-bottom: 20px; padding-bottom: 10px;
                border-bottom: 2px solid #000000;
            }
            .print-only-header h2 { font-size: 18pt; font-weight: 800; margin: 0 0 6px 0; }
            .print-only-header p { font-size: 10pt; color: #444; margin: 0; }
            #map { height: 200px !important; border: 1px solid #000 !important; }
            .photo-grid { grid-template-columns: repeat(2, 1fr) !important; gap: 8px !important; }
            .photo-wrapper { padding-top: 60% !important; }
            .sticky-sidebar { position: static !important; max-height: none !important; overflow: visible !important; }
        }
    </style>
</head>
<body>
    <div id="app" v-cloak>
        <!-- 1. 置頂深青藍漸層導覽列 (Sticky Top Navbar) -->
        <header class="top-navbar no-print">
            <div class="d-flex align-items-center">
                <button type="button" class="nav-btn mr-2" v-on:click="goBack" title="返回上一頁">
                    <i class="fas fa-arrow-left"></i>
                    <span class="d-none d-sm-inline">{{ backBtnText }}</span>
                </button>
                <h1 class="brand-title">
                    <i class="fas fa-layer-group text-white"></i>
                    <span>裸露地現場巡查成果報告</span>
                </h1>
                <span v-if="detail && (detail.BareGroundNo || detail.Bare_ID)" class="badge badge-light text-dark font-weight-bold ml-2" style="font-size: 0.85rem;">
                    {{ detail.BareGroundNo || detail.Bare_ID }}
                </span>
            </div>

            <div class="d-flex align-items-center">
                <!-- 列印按鈕 (符合規範：白底黑字陰影膠囊) -->
                <button type="button" class="nav-btn bg-white text-dark shadow-sm mr-2" v-on:click="printReport" title="列印或匯出成果單">
                    <i class="fas fa-print"></i>
                    <span class="d-none d-md-inline">列印報告</span>
                </button>

                <!-- 路線導航按鈕 -->
                <button v-if="detail && detail.Latitude && detail.Longtitude" type="button" class="nav-btn bg-white text-dark shadow-sm mr-2" v-on:click="openGoogleMaps" title="以 Google Maps 開啟導航">
                    <i class="fas fa-location-arrow text-success"></i>
                    <span class="d-none d-md-inline">路線導航</span>
                </button>

                <!-- 外勤簽名按鈕 -->
                <button type="button" class="nav-btn btn-warning text-dark font-weight-bold shadow-sm" v-on:click="openSignatureModal" title="進行手寫電子簽章">
                    <i class="fas fa-file-signature"></i>
                    <span class="d-none d-sm-inline">{{ detail && detail.HasSig ? '重簽確認' : '手寫簽署' }}</span>
                </button>
            </div>
        </header>

        <!-- 2. 列印專用報表頁首 (螢幕隱藏，列印時顯現) -->
        <div class="print-only-header">
            <h2>新北市政府環境保護局 - 裸露地現場巡查成果紀錄單</h2>
            <p>列印時間：{{ printTimestamp }} ｜ 管制編號：{{ (detail && detail.BareGroundNo) ? detail.BareGroundNo : '未登錄' }} ｜ 紀錄序號：第 {{ (detail && detail.INV_NO) ? detail.INV_NO : 1 }} 次巡查</p>
        </div>

        <!-- 3. 主作業容器 -->
        <main class="container-fluid-custom">
            <!-- Loading 指示 -->
            <div v-if="loading" class="text-center py-5">
                <div class="spinner-border text-primary" style="width: 3rem; height: 3rem;" role="status">
                    <span class="sr-only">讀取中...</span>
                </div>
                <div class="text-muted mt-3 font-weight-bold">正在讀取裸露地巡查成果資產與影像圖檔...</div>
            </div>

            <!-- 錯誤警示 -->
            <div v-if="errorMessage" class="alert alert-danger shadow-sm my-3" role="alert">
                <i class="fas fa-exclamation-triangle mr-2"></i>
                <strong>讀取失敗：</strong>{{ errorMessage }}
                <button type="button" class="btn btn-sm btn-outline-danger ml-3" v-on:click="fetchCaseData">重試</button>
            </div>

            <div v-if="!loading && detail">
                <!-- 通報階段進度時間軸 (Status Stepper) -->
                <div class="stepper-container shadow-sm no-print">
                    <div class="stepper-line">
                        <div class="stepper-line-fill" :style="{ width: stepperProgress + '%' }"></div>
                    </div>

                    <!-- 步驟 1: 現場查核建檔 -->
                    <div class="step-item" :class="getStepClass(1)">
                        <div class="step-circle">
                            <i v-if="stepperStage > 1" class="fas fa-check"></i>
                            <span v-else>1</span>
                        </div>
                        <div class="step-title">現場查核建檔</div>
                        <div class="step-time">{{ detail.Check_Date || '查核完成' }}</div>
                    </div>

                    <!-- 步驟 2: 巡查人員簽核 -->
                    <div class="step-item" :class="getStepClass(2)">
                        <div class="step-circle">
                            <i v-if="stepperStage > 2" class="fas fa-check"></i>
                            <span v-else>2</span>
                        </div>
                        <div class="step-title">稽查人員簽署</div>
                        <div class="step-time">{{ detail.HasSig ? (detail.SigUpdateTime || '已簽核') : '待簽核' }}</div>
                    </div>

                    <!-- 步驟 3: 查核成果歸檔 -->
                    <div class="step-item" :class="getStepClass(3)">
                        <div class="step-circle">
                            <i v-if="stepperStage >= 3" class="fas fa-check"></i>
                            <span v-else>3</span>
                        </div>
                        <div class="step-title">{{ detail.INV_StateName || '成果歸檔核定' }}</div>
                        <div class="step-time">{{ detail.INV_State ? ('狀態: ' + detail.INV_State) : '已歸檔' }}</div>
                    </div>
                </div>

                <!-- 雙欄黃金自適應佈局 (寬螢幕左 40% 固頂、右 60% 主資料區) -->
                <div class="row">
                    <!-- 左欄：基本資料、智慧地圖、簽名卡片 -->
                    <div class="col-xl-5 col-lg-5 mb-4">
                        <div class="sticky-sidebar">
                            <!-- 卡片 1: 裸露地基本資料 -->
                            <div class="card-modern">
                                <div class="card-modern-header">
                                    <h2 class="card-modern-title">
                                        <i class="fas fa-info-circle text-primary"></i>
                                        <span>場址基本資料</span>
                                    </h2>
                                    <span class="badge badge-info px-2 py-1 font-weight-bold" style="font-size: 12px;">
                                        序號 #{{ detail.INV_NO }}
                                    </span>
                                </div>
                                <div class="card-modern-body">
                                    <!-- 規格晶片列 (Stat Chips) -->
                                    <div class="stat-chip-group">
                                        <span class="stat-chip">
                                            <i class="fas fa-barcode text-muted"></i> 管制編號：<strong>{{ detail.BareGroundNo || '未填寫' }}</strong>
                                        </span>
                                        <span class="stat-chip">
                                            <i class="fas fa-tag text-muted"></i> 地目分區：<strong>{{ detail.Land_USE || '未填寫' }}</strong>
                                        </span>
                                        <span class="stat-chip">
                                            <i class="fas fa-user-check text-muted"></i> 查核人員：<strong>{{ detail.InputUser || '系統查核員' }}</strong>
                                        </span>
                                    </div>

                                    <div class="detail-memo-box mb-2">
                                        <div class="detail-memo-title">
                                            <i class="fas fa-map-marker-alt text-danger"></i> 場址地址 / 坐落位置
                                        </div>
                                        <div class="detail-memo-content font-weight-bold text-dark">
                                            {{ detail.ADDR || '未登載場址地址' }}
                                        </div>
                                    </div>

                                    <div class="d-flex justify-content-between align-items-center text-muted" style="font-size: 12.5px;">
                                        <div>
                                            <i class="fas fa-crosshairs text-secondary mr-1"></i>
                                            GPS 坐標：{{ (detail.Latitude && detail.Longtitude) ? (detail.Latitude + ', ' + detail.Longtitude) : '未定位' }}
                                        </div>
                                        <div>
                                            <i class="fas fa-calendar-alt text-secondary mr-1"></i>
                                            查核：{{ detail.Check_Date || '未記錄' }}
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- 卡片 2: 智慧現場地圖 (Leaflet 零遮擋標準) -->
                            <div class="card-modern">
                                <div class="card-modern-header">
                                    <h2 class="card-modern-title">
                                        <i class="fas fa-map-marked-alt text-info"></i>
                                        <span>智慧現場地圖</span>
                                    </h2>
                                    <div class="d-flex align-items-center gap-2">
                                        <button type="button" class="btn btn-xs btn-outline-secondary py-1 px-2 mr-1" v-on:click="resetMapView" title="重設地圖全景" style="font-size: 11px;">
                                            <i class="fas fa-compress-arrows-alt"></i> 全景
                                        </button>
                                        <button type="button" class="btn btn-xs btn-outline-secondary py-1 px-2" v-on:click="toggleMapCollapse" style="font-size: 11px;">
                                            <i :class="isMapCollapsed ? 'fas fa-chevron-down' : 'fas fa-chevron-up'"></i>
                                            {{ isMapCollapsed ? '展開' : '收合' }}
                                        </button>
                                    </div>
                                </div>
                                <div class="card-modern-body p-2">
                                    <div id="map" :class="{ 'map-collapsed': isMapCollapsed }"></div>
                                </div>
                            </div>

                            <!-- 卡片 3: 巡查人員簽章面板 -->
                            <div class="card-modern">
                                <div class="card-modern-header">
                                    <h2 class="card-modern-title">
                                        <i class="fas fa-signature text-success"></i>
                                        <span>巡查人員簽章</span>
                                    </h2>
                                    <button type="button" class="btn btn-sm btn-outline-primary py-1 px-2 font-weight-bold" v-on:click="openSignatureModal">
                                        <i class="fas fa-pen-alt mr-1"></i> {{ detail.HasSig ? '更換簽名' : '立即手寫簽署' }}
                                    </button>
                                </div>
                                <div class="card-modern-body">
                                    <div class="signature-preview-box">
                                        <img v-if="detail.HasSig && detail.SigUrl" :src="detail.SigUrl" alt="稽查人員電子簽章" class="signature-img" />
                                        <div v-else class="text-center py-4 text-muted">
                                            <i class="fas fa-signature fa-2x mb-2 text-secondary"></i>
                                            <div class="font-weight-bold">目前尚未建立手寫簽名圖檔</div>
                                            <small class="text-muted">請點選上方按鈕開啟平滑手寫板簽署</small>
                                        </div>
                                    </div>
                                    <div v-if="detail.HasSig" class="d-flex justify-content-between align-items-center mt-2 text-muted" style="font-size: 11.5px;">
                                        <span><i class="fas fa-check-circle text-success mr-1"></i> 已完成電子簽章認證</span>
                                        <span>更新於：{{ detail.SigUpdateTime || '本次巡查' }}</span>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- 右欄：現場概況與量測、現場照片成果 -->
                    <div class="col-xl-7 col-lg-7 mb-4">
                        <!-- 卡片 4: 現場概況與量測數據規格 -->
                        <div class="card-modern">
                            <div class="card-modern-header">
                                <h2 class="card-modern-title">
                                    <i class="fas fa-ruler-combined text-primary"></i>
                                    <span>現場量測與堆置概況</span>
                                </h2>
                                <span class="badge badge-success px-2 py-1 font-weight-bold">
                                    {{ detail.INV_StateName || '已查核' }}
                                </span>
                            </div>
                            <div class="card-modern-body">
                                <!-- 規格儀表網格 -->
                                <div class="metric-grid">
                                    <div class="metric-card">
                                        <div class="metric-label">概估長度 (L)</div>
                                        <div class="metric-value">{{ detail.pLength || '0.0' }}<span class="metric-unit">m</span></div>
                                    </div>
                                    <div class="metric-card">
                                        <div class="metric-label">概估寬度 (W)</div>
                                        <div class="metric-value">{{ detail.pWidth || '0.0' }}<span class="metric-unit">m</span></div>
                                    </div>
                                    <div class="metric-card">
                                        <div class="metric-label">概估高度 (H)</div>
                                        <div class="metric-value">{{ detail.pHeight || '0.0' }}<span class="metric-unit">m</span></div>
                                    </div>
                                    <div class="metric-card" style="background: #e0f2fe; border-color: #bae6fd;">
                                        <div class="metric-label" style="color: #0369a1;">堆置總量概估</div>
                                        <div class="metric-value" style="color: #0284c7;">{{ detail.pVolume || '0.0' }}<span class="metric-unit" style="color: #0369a1;">m³</span></div>
                                    </div>
                                    <div class="metric-card" style="background: #f0fdf4; border-color: #bbf7d0;">
                                        <div class="metric-label" style="color: #15803d;">場址面積概估</div>
                                        <div class="metric-value" style="color: #16a34a;">{{ detail.pArea || '0.0' }}<span class="metric-unit" style="color: #15803d;">m²</span></div>
                                    </div>
                                </div>

                                <!-- 詳細定性說明項目 -->
                                <div class="detail-memo-box">
                                    <div class="detail-memo-title">
                                        <i class="fas fa-compass text-info"></i> 場址周界概況
                                    </div>
                                    <div class="detail-memo-content">
                                        {{ detail.Around_Memo ? detail.Around_Memo : '無特殊周界說明' }}
                                    </div>
                                </div>

                                <div class="detail-memo-box">
                                    <div class="detail-memo-title">
                                        <i class="fas fa-dumpster text-warning"></i> 廢棄物種類、外觀
                                    </div>
                                    <div class="detail-memo-content">
                                        {{ detail.Waste_Type ? detail.Waste_Type : '現場無明顯堆置廢棄物或未記載' }}
                                    </div>
                                </div>

                                <div class="detail-memo-box mb-0">
                                    <div class="detail-memo-title">
                                        <i class="fas fa-clipboard-list text-secondary"></i> 現場環境概況說明
                                    </div>
                                    <div class="detail-memo-content">
                                        {{ detail.surroundings ? detail.surroundings : '現場環境狀況良好或無額外附註' }}
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- 卡片 5: 現場照片成果 (4 張對照) -->
                        <div class="card-modern">
                            <div class="card-modern-header">
                                <h2 class="card-modern-title">
                                    <i class="fas fa-camera text-primary"></i>
                                    <span>現場查核照片成果 (4 張檢視)</span>
                                </h2>
                                <span class="text-muted" style="font-size: 12px;">點選照片可開啟全螢幕高解析燈箱檢視</span>
                            </div>
                            <div class="card-modern-body">
                                <div class="photo-grid">
                                    <div v-for="photo in detail.Photos" :key="photo.Index" class="photo-card shadow-sm">
                                        <div class="photo-header">
                                            <span><i class="fas fa-image text-primary mr-1"></i> {{ photo.Title }}</span>
                                            <span v-if="photo.HasFile" class="badge badge-success">已上傳</span>
                                            <span v-else class="badge badge-light text-muted">無圖檔</span>
                                        </div>
                                        <div class="photo-wrapper" v-on:click="photo.HasFile && openLightbox(photo)">
                                            <img v-if="photo.HasFile" :src="photo.Url" :alt="photo.Title" class="photo-img" loading="lazy" />
                                            <div v-else class="photo-placeholder">
                                                <i class="fas fa-image fa-2x mb-2 text-muted"></i>
                                                <span>尚未檢附現場照片</span>
                                            </div>
                                        </div>
                                        <div class="photo-footer">
                                            <span>{{ photo.HasFile ? ('檔案大小: ' + photo.FileSize) : '無檔案' }}</span>
                                            <span>{{ photo.HasFile ? photo.UpdateTime : '--' }}</span>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </main>

        <!-- 4. 全螢幕高解析平滑手寫簽名板 (符合標準元件 4 規範) -->
        <div v-if="showSigModal" class="sig-fullscreen-modal no-print">
            <div class="sig-modal-header">
                <div class="d-flex align-items-center font-weight-bold" style="font-size: 1.05rem;">
                    <i class="fas fa-file-signature text-warning mr-2"></i>
                    <span>巡查人員手寫簽章認證</span>
                </div>
                <button type="button" class="btn btn-sm btn-outline-light" v-on:click="closeSignatureModal">
                    <i class="fas fa-times"></i>
                </button>
            </div>

            <div class="sig-canvas-container" id="sigContainer">
                <canvas id="sigCanvas"></canvas>
            </div>

            <div class="sig-modal-footer">
                <div>
                    <button type="button" class="btn btn-outline-secondary font-weight-bold" v-on:click="clearCanvas">
                        <i class="fas fa-eraser mr-1"></i> 清除重寫
                    </button>
                </div>
                <div class="d-flex gap-2">
                    <button type="button" class="btn btn-light font-weight-bold mr-2" v-on:click="closeSignatureModal">
                        取消返回
                    </button>
                    <button type="button" class="btn btn-primary font-weight-bold px-4" :disabled="savingSig" v-on:click="saveSignature">
                        <i v-if="savingSig" class="fas fa-spinner fa-spin mr-1"></i>
                        <i v-else class="fas fa-check mr-1"></i>
                        {{ savingSig ? '儲存中...' : '確定送出簽名' }}
                    </button>
                </div>
            </div>
        </div>

        <!-- 5. 高解析照片燈箱 Modal -->
        <div v-if="activeLightboxPhoto" class="lightbox-modal no-print" v-on:click.self="closeLightbox">
            <button type="button" class="lightbox-close-btn" v-on:click="closeLightbox" title="關閉">
                <i class="fas fa-times"></i>
            </button>
            <img :src="activeLightboxPhoto.Url" :alt="activeLightboxPhoto.Title" class="lightbox-img" />
            <div class="lightbox-title">{{ activeLightboxPhoto.Title }} ｜ {{ activeLightboxPhoto.UpdateTime }}</div>
            <div class="mt-2">
                <a :href="activeLightboxPhoto.Url" target="_blank" class="btn btn-sm btn-outline-light mr-2">
                    <i class="fas fa-external-link-alt mr-1"></i> 原圖新分頁開啟
                </a>
                <button type="button" class="btn btn-sm btn-light" v-on:click="closeLightbox">關閉</button>
            </div>
        </div>
    </div>

    <!-- 本地化依賴腳本 (避開 CDN 資安阻擋) -->
    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>
    <script src="../Scripts/leaflet/leaflet.js"></script>

    <script>
        const { createApp, markRaw } = Vue;

        createApp({
            data() {
                return {
                    loading: true,
                    errorMessage: '',
                    bareId: '',
                    token: '',
                    invNo: '',
                    mode: 'read',
                    backParam: '',
                    detail: null,

                    // 地圖收合狀態
                    isMapCollapsed: false,

                    // 簽名板狀態
                    showSigModal: false,
                    savingSig: false,
                    canvasCtx: null,
                    hasDrawn: false,

                    // 照片燈箱
                    activeLightboxPhoto: null,

                    // 列印戳記
                    printTimestamp: ''
                };
            },
            computed: {
                backBtnText() {
                    if (this.backParam === '2') return '關閉視窗';
                    return '返回清單';
                },
                stepperStage() {
                    if (!this.detail) return 1;
                    if (this.detail.HasSig) return 3;
                    return 2;
                },
                stepperProgress() {
                    if (this.stepperStage === 3) return 100;
                    if (this.stepperStage === 2) return 50;
                    return 0;
                }
            },
            mounted() {
                this.parseUrlParams();
                this.updatePrintTimestamp();
                this.fetchCaseData();

                // 註冊 Esc 鍵關閉燈箱與簽名板
                window.addEventListener('keydown', (e) => {
                    if (e.key === 'Escape') {
                        if (this.activeLightboxPhoto) this.closeLightbox();
                        if (this.showSigModal) this.closeSignatureModal();
                    }
                });
            },
            methods: {
                parseUrlParams() {
                    const params = new URLSearchParams(window.location.search);
                    this.bareId = params.get('id') || '';
                    this.token = params.get('id1') || '';
                    this.invNo = params.get('id2') || '';
                    this.mode = (params.get('mode') || 'read').toLowerCase();
                    this.backParam = params.get('back') || '';
                },
                updatePrintTimestamp() {
                    const now = new Date();
                    const y = now.getFullYear();
                    const m = String(now.getMonth() + 1).padStart(2, '0');
                    const d = String(now.getDate()).padStart(2, '0');
                    const h = String(now.getHours()).padStart(2, '0');
                    const mi = String(now.getMinutes()).padStart(2, '0');
                    this.printTimestamp = y + '-' + m + '-' + d + ' ' + h + ':' + mi;
                },
                getStepClass(step) {
                    if (this.stepperStage > step) return 'completed';
                    if (this.stepperStage === step) return 'active';
                    return '';
                },
                goBack() {
                    if (this.backParam === '1') {
                        window.location.href = 'Bare_List.aspx?mode=reject';
                    } else if (this.backParam === '2') {
                        window.close();
                    } else if (this.backParam === '3') {
                        window.location.href = 'Bare_List.aspx?mode=identify';
                    } else {
                        window.location.href = 'Bare_List.aspx';
                    }
                },
                printReport() {
                    window.print();
                },
                openGoogleMaps() {
                    if (!this.detail || !this.detail.Latitude || !this.detail.Longtitude) return;
                    const url = 'https://www.google.com/maps/dir/?api=1&destination=' + encodeURIComponent(this.detail.Latitude + ',' + this.detail.Longtitude);
                    window.open(url, '_blank');
                },
                fetchCaseData() {
                    this.loading = true;
                    this.errorMessage = '';

                    const url = 'BareResult.aspx?action=getcase&id=' + encodeURIComponent(this.bareId) +
                        '&id1=' + encodeURIComponent(this.token) +
                        '&id2=' + encodeURIComponent(this.invNo) +
                        '&mode=' + encodeURIComponent(this.mode);

                    axios.get(url)
                        .then(res => {
                            this.loading = false;
                            if (res.data && res.data.Success) {
                                this.detail = res.data.Data;
                                this.$nextTick(() => {
                                    this.initMap();
                                    // 若 mode === 'sig' 且尚未簽署，主動提示開啟簽名板
                                    if (this.mode === 'sig' && !this.detail.HasSig) {
                                        this.openSignatureModal();
                                    }
                                });
                            } else {
                                this.errorMessage = (res.data && res.data.Message) ? res.data.Message : '讀取失敗';
                            }
                        })
                        .catch(err => {
                            this.loading = false;
                            this.errorMessage = '伺服器網路連線異常：' + (err.message || err);
                        });
                },

                // ---------------- 地圖相關邏輯 (物件隔離防崩潰) ----------------
                initMap() {
                    if (!this.detail) return;
                    const mapEl = document.getElementById('map');
                    if (!mapEl) return;

                    // 若已有地圖實例先清理
                    if (this.leafletMap) {
                        try { this.leafletMap.remove(); } catch (e) {}
                        this.leafletMap = null;
                    }

                    let lat = parseFloat(this.detail.Latitude);
                    let lng = parseFloat(this.detail.Longtitude);

                    // 預設新北市中心坐標 (若未定位)
                    let hasCoord = true;
                    if (isNaN(lat) || isNaN(lng) || lat <= 0 || lng <= 0) {
                        lat = 25.011629;
                        lng = 121.462823;
                        hasCoord = false;
                    }

                    // 建立 Leaflet Map (markRaw 隔離)
                    const mapInstance = L.map('map', {
                        center: [lat, lng],
                        zoom: hasCoord ? 16 : 12,
                        zoomControl: true
                    });
                    this.leafletMap = markRaw(mapInstance);

                    // 加入台灣通用電子地圖底圖
                    const emapLayer = L.tileLayer('https://wmts.nlsc.gov.tw/wmts/EMAP/default/GoogleMapsCompatible/{z}/{y}/{x}', {
                        maxZoom: 19,
                        attribution: '&copy; <a href="https://maps.nlsc.gov.tw/" target="_blank">NLSC</a>'
                    }).addTo(this.leafletMap);

                    // 影像衛星圖層
                    const photoLayer = L.tileLayer('https://wmts.nlsc.gov.tw/wmts/PHOTO2/default/GoogleMapsCompatible/{z}/{y}/{x}', {
                        maxZoom: 19,
                        attribution: '&copy; NLSC'
                    });

                    // 增加圖層切換控制項 (右上角，符合規範)
                    L.control.layers({
                        "通用電子地圖": emapLayer,
                        "正射衛星影像": photoLayer
                    }, null, { position: 'topright' }).addTo(this.leafletMap);

                    // 若有真實坐標，建立自訂標記 Pin
                    if (hasCoord) {
                        const iconHtml = '<div class="custom-map-marker"><div class="marker-pin"><i class="fas fa-layer-group marker-icon-inner"></i></div></div>';
                        const customIcon = L.divIcon({
                            className: 'custom-div-icon',
                            html: iconHtml,
                            iconSize: [34, 34],
                            iconAnchor: [17, 34],
                            popupAnchor: [0, -32]
                        });

                        const popupHtml = '<div style="font-size:13px; line-height:1.5;">' +
                            '<strong style="color:#0284c7;"><i class="fas fa-layer-group mr-1"></i>' + (this.detail.BareGroundNo || this.detail.Bare_ID) + '</strong><br/>' +
                            '<span>地址：' + (this.detail.ADDR || '未填寫') + '</span><br/>' +
                            '<a href="https://www.google.com/maps/dir/?api=1&destination=' + lat + ',' + lng + '" target="_blank" style="color:#0284c7; font-weight:700;">開啟導航 &raquo;</a>' +
                            '</div>';

                        const marker = L.marker([lat, lng], { icon: customIcon }).addTo(this.leafletMap);
                        marker.bindPopup(popupHtml).openPopup();
                    }
                },
                resetMapView() {
                    if (!this.leafletMap || !this.detail) return;
                    let lat = parseFloat(this.detail.Latitude);
                    let lng = parseFloat(this.detail.Longtitude);
                    if (!isNaN(lat) && !isNaN(lng) && lat > 0 && lng > 0) {
                        this.leafletMap.setView([lat, lng], 16);
                    }
                },
                toggleMapCollapse() {
                    this.isMapCollapsed = !this.isMapCollapsed;
                    setTimeout(() => {
                        if (this.leafletMap) this.leafletMap.invalidateSize();
                    }, 350);
                },

                // ---------------- 燈箱預覽邏輯 ----------------
                openLightbox(photo) {
                    this.activeLightboxPhoto = photo;
                },
                closeLightbox() {
                    this.activeLightboxPhoto = null;
                },

                // ---------------- 全螢幕平滑手寫簽名板 (標準元件 4) ----------------
                openSignatureModal() {
                    this.showSigModal = true;
                    this.hasDrawn = false;
                    this.$nextTick(() => {
                        this.initCanvas();
                    });
                },
                closeSignatureModal() {
                    this.showSigModal = false;
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
                        this.hasDrawn = true;
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
                clearCanvas() {
                    const canvas = document.getElementById('sigCanvas');
                    if (!canvas || !this.canvasCtx) return;
                    const dpr = window.devicePixelRatio || 1;
                    this.canvasCtx.clearRect(0, 0, canvas.width / dpr, canvas.height / dpr);
                    this.hasDrawn = false;
                },
                saveSignature() {
                    const canvas = document.getElementById('sigCanvas');
                    if (!canvas || !this.hasDrawn) {
                        alert('請先在手寫區域完成簽名後再點選儲存！');
                        return;
                    }

                    const base64Data = canvas.toDataURL('image/png');
                    this.savingSig = true;

                    const payload = {
                        Bare_ID: this.bareId,
                        Token: this.token,
                        INV_NO: this.detail.INV_NO,
                        SigBase64: base64Data
                    };

                    axios.post('BareResult.aspx?action=savesignature', payload)
                        .then(res => {
                            this.savingSig = false;
                            if (res.data && res.data.Success) {
                                alert(res.data.Message || '簽名儲存成功！');
                                this.detail.HasSig = true;
                                this.detail.SigUrl = res.data.SigUrl;
                                this.detail.SigUpdateTime = res.data.SigUpdateTime;
                                this.closeSignatureModal();
                            } else {
                                alert('儲存失敗：' + (res.data && res.data.Message ? res.data.Message : '未知錯誤'));
                            }
                        })
                        .catch(err => {
                            this.savingSig = false;
                            alert('網路通訊失敗：' + (err.message || err));
                        });
                }
            }
        }).mount('#app');
    </script>
</body>
</html>
