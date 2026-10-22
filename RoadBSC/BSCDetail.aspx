<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="BSCDetail.aspx.cs" Inherits="NTPC_FEC.RoadBSC.BSCDetail" %>
<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定溢散源管理平台 - 人行道與交通島裸露覆土通報單詳情</title>
    
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

        * { box-sizing: border-box; -webkit-tap-highlight-color: transparent; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, "Noto Sans TC", "微軟正黑體", sans-serif;
            background-color: var(--bg-canvas);
            margin: 0; padding: 0;
            color: var(--text-main);
            overflow-x: hidden;
        }
        [v-cloak] { display: none !important; }

        /* 頂部導覽列 */
        .top-navbar {
            background: linear-gradient(135deg, #0099e5 0%, #0284c7 100%);
            color: #ffffff;
            height: 56px;
            display: flex; align-items: center; justify-content: space-between;
            padding: 0 16px;
            box-shadow: 0 2px 10px rgba(0, 153, 229, 0.25);
            position: sticky; top: 0; z-index: 1020;
        }
        .nav-btn {
            background: rgba(255, 255, 255, 0.18);
            border: none; color: #ffffff;
            font-size: 0.92rem; font-weight: 600; cursor: pointer;
            height: 36px; border-radius: 8px;
            display: inline-flex; align-items: center; justify-content: center;
            padding: 0 14px; gap: 6px;
            transition: all 0.2s;
            text-decoration: none;
        }
        .nav-btn:hover { background-color: rgba(255, 255, 255, 0.32); color: #ffffff; text-decoration: none; }
        .top-navbar .brand-title {
            font-size: 1.08rem; font-weight: 700; margin: 0;
            display: flex; align-items: center; gap: 8px;
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
            position: absolute;
            top: 34px; left: 16%; right: 16%;
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

        /* 資訊清單表格排版 (Info Grid) */
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
            gap: 12px;
        }
        .info-cell {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 10px 14px;
        }
        .info-label {
            font-size: 12px;
            font-weight: 600;
            color: var(--text-muted);
            margin-bottom: 4px;
            display: flex; align-items: center; gap: 6px;
        }
        .info-val {
            font-size: 14px;
            font-weight: 700;
            color: var(--text-main);
            word-break: break-all;
        }

        /* 狀態規格晶片 (Stat Chips) */
        .stat-chip {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 5px 12px;
            border-radius: 6px;
            font-size: 13px;
            font-weight: 700;
        }
        .chip-smooth-1 { background: #ecfdf5; color: #047857; border: 1px solid #a7f3d0; }
        .chip-smooth-2 { background: #fef9c3; color: #854d0e; border: 1px solid #fde047; }
        .chip-smooth-3 { background: #ffedd5; color: #9a3412; border: 1px solid #fed7aa; }
        .chip-smooth-4 { background: #fee2e2; color: #991b1b; border: 1px solid #fca5a5; }
        .chip-smooth-other { background: #f1f5f9; color: #475569; border: 1px solid #cbd5e1; }

        .chip-cover-1 { background: #ecfdf5; color: #047857; border: 1px solid #a7f3d0; }
        .chip-cover-2 { background: #fef9c3; color: #854d0e; border: 1px solid #fde047; }
        .chip-cover-3 { background: #ffedd5; color: #9a3412; border: 1px solid #fed7aa; }
        .chip-cover-4 { background: #fee2e2; color: #991b1b; border: 1px solid #fca5a5; }
        .chip-cover-other { background: #f1f5f9; color: #475569; border: 1px solid #cbd5e1; }

        /* 地圖控制與收合 */
        #map { width: 100%; height: 380px; border-radius: 8px; z-index: 10; transition: height 0.3s ease; }
        #map.map-collapsed { height: 120px !important; }

        /* 地圖座標標記 (Marker Pin) */
        .custom-map-marker { display: flex; align-items: center; justify-content: center; }
        .marker-pin {
            width: 32px; height: 32px;
            border-radius: 50% 50% 50% 0;
            background: #0284c7;
            position: absolute; transform: rotate(-45deg);
            left: 50%; top: 50%; margin: -20px 0 0 -16px;
            box-shadow: 0 3px 8px rgba(0, 0, 0, 0.35);
            border: 2px solid #ffffff;
            display: flex; align-items: center; justify-content: center;
            cursor: pointer;
        }
        .marker-num { transform: rotate(45deg); color: #ffffff; font-weight: 800; font-size: 13px; }

        /* 照片對照卡片 (Before/After Comparison Card) */
        .comparison-pair-card {
            background: #ffffff;
            border: 1px solid var(--border-color);
            border-radius: 10px;
            margin-bottom: 16px;
            overflow: hidden;
            box-shadow: 0 1px 3px rgba(0,0,0,0.04);
        }
        .pair-header {
            background: #f8fafc;
            border-bottom: 1px solid var(--border-color);
            padding: 8px 14px;
            font-size: 13px;
            font-weight: 700;
            color: #334155;
            display: flex; align-items: center; justify-content: space-between;
        }
        .pair-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 1px;
            background: var(--border-color);
        }
        .pair-photo-box {
            background: #ffffff;
            padding: 12px;
            display: flex;
            flex-direction: column;
            align-items: center;
            position: relative;
        }
        .photo-tag {
            align-self: flex-start;
            font-size: 11px;
            font-weight: 700;
            padding: 2px 8px;
            border-radius: 4px;
            margin-bottom: 8px;
        }
        .tag-before { background: #fee2e2; color: #dc2626; border: 1px solid #fca5a5; }
        .tag-after { background: #dcfce7; color: #15803d; border: 1px solid #86efac; }

        .img-wrapper {
            width: 100%;
            height: 260px;
            border-radius: 6px;
            overflow: hidden;
            background: #0f172a;
            position: relative;
            cursor: pointer;
            display: flex; align-items: center; justify-content: center;
        }
        .img-wrapper img {
            width: 100%;
            height: 100%;
            object-fit: cover;
            transition: transform 0.3s ease;
        }
        .img-wrapper:hover img {
            transform: scale(1.03);
        }
        .img-overlay-btn {
            position: absolute;
            bottom: 8px; right: 8px;
            background: rgba(15, 23, 42, 0.75);
            color: #ffffff;
            border-radius: 6px;
            padding: 4px 8px;
            font-size: 11px;
            font-weight: 600;
            display: flex; align-items: center; gap: 4px;
            backdrop-filter: blur(4px);
        }
        .img-empty-box {
            width: 100%;
            height: 260px;
            border-radius: 6px;
            background: #f8fafc;
            border: 2px dashed #cbd5e1;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            color: #94a3b8;
            font-size: 13px;
            gap: 8px;
        }
        .img-meta-row {
            width: 100%;
            margin-top: 8px;
            font-size: 11px;
            color: var(--text-muted);
            display: flex; justify-content: space-between; align-items: center;
        }

        /* 燈箱視窗 (Lightbox Modal) */
        .lightbox-backdrop {
            position: fixed;
            top: 0; left: 0; right: 0; bottom: 0;
            background: rgba(15, 23, 42, 0.92);
            z-index: 2000;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            padding: 16px;
        }
        .lightbox-toolbar {
            position: absolute;
            top: 16px; right: 16px;
            display: flex;
            align-items: center;
            gap: 10px;
            z-index: 2001;
        }
        .lightbox-btn {
            background: rgba(255, 255, 255, 0.2);
            border: 1px solid rgba(255, 255, 255, 0.3);
            color: #ffffff;
            font-size: 14px;
            font-weight: 600;
            border-radius: 8px;
            padding: 8px 14px;
            cursor: pointer;
            display: inline-flex; align-items: center; gap: 6px;
            transition: all 0.2s;
        }
        .lightbox-btn:hover { background: rgba(255, 255, 255, 0.35); }
        .lightbox-img-container {
            max-width: 92vw;
            max-height: 84vh;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: transform 0.3s ease;
        }
        .lightbox-img-container img {
            max-width: 100%;
            max-height: 84vh;
            border-radius: 8px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.5);
            object-fit: contain;
        }
        .lightbox-title {
            position: absolute;
            bottom: 16px; left: 24px;
            color: #ffffff;
            font-size: 14px;
            background: rgba(0,0,0,0.5);
            padding: 6px 12px;
            border-radius: 6px;
        }

        /* 手機行動端底部懸浮動作列 */
        @media screen and (max-width: 991px) {
            body { padding-bottom: 76px; }
            .mobile-bottom-bar {
                display: flex; position: fixed; bottom: 0; left: 0; right: 0; z-index: 1010;
                background: #ffffff; border-top: 1px solid #e2e8f0;
                box-shadow: 0 -4px 16px rgba(0, 0, 0, 0.08);
                padding: 10px 16px; padding-bottom: calc(10px + env(safe-area-inset-bottom, 0px));
                gap: 10px;
            }
            .mobile-bottom-bar .btn { flex: 1; font-weight: 700; padding: 10px; border-radius: 8px; }
            .pair-grid { grid-template-columns: 1fr; }
            .stepper-container { padding: 12px; }
            .step-title { font-size: 11px; }
        }

        @media screen and (min-width: 992px) {
            .mobile-bottom-bar { display: none !important; }
        }

        /* 公文陳核列印最佳化樣式 */
        @media print {
            .top-navbar, .mobile-bottom-bar, .no-print, .leaflet-control-container, .btn, .nav-btn {
                display: none !important;
            }
            body { background: #ffffff !important; color: #000000 !important; font-size: 12pt; }
            .container-fluid-custom { max-width: 100% !important; padding: 0 !important; }
            .card-modern { border: 1px solid #cccccc !important; box-shadow: none !important; margin-bottom: 12px !important; }
            .sticky-sidebar { position: static !important; max-height: none !important; overflow: visible !important; }
            .img-wrapper { height: 180px !important; }
            .img-empty-box { height: 180px !important; }
            .print-only-header { display: block !important; text-align: center; margin-bottom: 16px; }
            .print-only-header h2 { margin: 0; font-size: 18pt; font-weight: bold; }
            .print-only-header p { margin: 4px 0 0 0; font-size: 10pt; color: #555; }
        }

        .print-only-header { display: none; }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div id="detailApp" v-cloak>
            <!-- 1. 頂部導覽列 -->
            <header class="top-navbar no-print">
                <div class="brand-title">
                    <a :href="detail.BackListUrl || 'BSC_List.aspx'" class="nav-btn mr-2" title="返回清單">
                        <i class="fas fa-arrow-left"></i>
                        <span class="d-none d-sm-inline">返回清單</span>
                    </a>
                    <i class="fas fa-road text-white"></i>
                    <span>人行道與交通島裸露覆土通報單</span>
                    <span v-if="detail.Show_ID" class="badge badge-light text-dark font-weight-bold ml-2" style="font-size: 0.85rem;">
                        {{ detail.Show_ID }}
                    </span>
                </div>
                <div class="d-flex align-items-center gap-2">
                    <button type="button" class="nav-btn bg-white text-dark shadow-sm" v-on:click="printCase">
                        <i class="fas fa-print"></i>
                        <span class="d-none d-md-inline">列印案件</span>
                    </button>
                    <!-- 依案件狀態動態切換操作按鈕 -->
                    <template v-if="detail.StatusCode === 1">
                        <a :href="detail.EditUrl" class="btn btn-warning btn-sm font-weight-bold shadow-sm ml-2">
                            <i class="fas fa-edit mr-1"></i> 編輯案件
                        </a>
                        <a :href="detail.SetSGUrl" class="btn btn-primary btn-sm font-weight-bold shadow-sm ml-2">
                            <i class="fas fa-paper-plane mr-1"></i> 派工通報
                        </a>
                    </template>
                    <template v-else-if="detail.StatusCode === 2">
                        <a :href="detail.ImproveUrl" class="btn btn-success btn-sm font-weight-bold shadow-sm ml-2">
                            <i class="fas fa-tools mr-1"></i> 改善回報
                        </a>
                    </template>
                </div>
            </header>

            <!-- 列印專用報表頁首 -->
            <div class="print-only-header">
                <h2>新北市固定溢散源管理平台</h2>
                <h3>人行道與交通島裸露覆土現場通報紀錄單</h3>
                <p>通報案號：{{ detail.Show_ID }} ｜ 列印時間：{{ printTime }}</p>
            </div>

            <!-- 主作業容器 -->
            <main class="container-fluid-custom">
                <!-- 載入中骨架屏 -->
                <div v-if="loading" class="text-center py-5">
                    <div class="spinner-border text-primary" role="status" style="width: 3rem; height: 3rem;">
                        <span class="sr-only">資料載入中...</span>
                    </div>
                    <p class="mt-3 text-muted font-weight-bold">正在讀取案件詳情與現場照片...</p>
                </div>

                <!-- 錯誤警告面板 -->
                <div v-else-if="errorMessage" class="alert alert-danger shadow-sm text-center py-4 my-4">
                    <i class="fas fa-exclamation-triangle fa-2x mb-2 text-danger"></i>
                    <h5 class="font-weight-bold">讀取失敗</h5>
                    <p class="mb-3">{{ errorMessage }}</p>
                    <button type="button" class="btn btn-outline-danger btn-sm" v-on:click="loadDetail">
                        <i class="fas fa-redo mr-1"></i> 重新載入
                    </button>
                </div>

                <!-- 案件主要內容區塊 -->
                <div v-else>
                    <!-- 案件退回重辦警告卡片 -->
                    <div v-if="detail.IsBack" class="alert-gback shadow-sm">
                        <div class="font-weight-bold d-flex align-items-center gap-2">
                            <i class="fas fa-exclamation-circle fa-lg"></i>
                            <span>非處理單位權責，此案件已被退回！</span>
                        </div>
                        <div class="mt-2 pl-4" v-if="detail.G_Memo">
                            <strong>退回備註說明：</strong> {{ detail.G_Memo }}
                        </div>
                    </div>

                    <!-- 2. 通報階段進度時間軸 (Status Stepper) -->
                    <div class="stepper-container shadow-sm no-print">
                        <div class="stepper-line">
                            <div class="stepper-line-fill" :style="{ width: stepperProgress + '%' }"></div>
                        </div>

                        <!-- 步驟 1: 現場查核立案 -->
                        <div class="step-item" :class="getStepClass(1)">
                            <div class="step-circle">
                                <i v-if="detail.StatusCode > 1" class="fas fa-check"></i>
                                <span v-else>1</span>
                            </div>
                            <div class="step-title">現場查核立案</div>
                            <div class="step-time">{{ detail.Report_Date || '未填寫' }}</div>
                        </div>

                        <!-- 步驟 2: 派工改善通報 -->
                        <div class="step-item" :class="getStepClass(2)">
                            <div class="step-circle">
                                <i v-if="detail.StatusCode > 2" class="fas fa-check"></i>
                                <span v-else>2</span>
                            </div>
                            <div class="step-title">{{ detail.IsBack ? '案件退回待重派' : '派工改善通報' }}</div>
                            <div class="step-time">{{ detail.SetCOM_Date || '待通報' }}</div>
                        </div>

                        <!-- 步驟 3: 改善完成結案 -->
                        <div class="step-item" :class="getStepClass(3)">
                            <div class="step-circle">
                                <i v-if="detail.StatusCode === 3" class="fas fa-check"></i>
                                <span v-else>3</span>
                            </div>
                            <div class="step-title">改善完成結案</div>
                            <div class="step-time">{{ detail.Improve_Date || '待改善' }}</div>
                        </div>
                    </div>

                    <!-- 3. 雙欄黃金聯動佈局 (Desktop >= 1200px) -->
                    <div class="row">
                        <!-- 左欄：基本資料、現場智慧地圖、處理歷程 (40% 寬度) -->
                        <div class="col-xl-5 col-lg-5 col-12">
                            <div class="sticky-sidebar">
                                <!-- 卡片 A: 現場基本查核資料 -->
                                <section class="card-modern">
                                    <div class="card-modern-header">
                                        <h3 class="card-modern-title">
                                            <i class="fas fa-info-circle text-primary"></i>
                                            現場查核基本資料
                                        </h3>
                                        <span class="badge px-3 py-1 font-weight-bold" :class="detail.StatusBadgeClass" style="font-size: 13px;">
                                            {{ detail.StatusText }}
                                        </span>
                                    </div>
                                    <div class="card-modern-body">
                                        <div class="info-grid">
                                            <div class="info-cell">
                                                <div class="info-label"><i class="fas fa-barcode"></i> 通報案號</div>
                                                <div class="info-val text-primary">{{ detail.Show_ID }}</div>
                                            </div>
                                            <div class="info-cell">
                                                <div class="info-label"><i class="far fa-calendar-alt"></i> 查核時間</div>
                                                <div class="info-val">{{ detail.Report_Date || '未填寫' }}</div>
                                            </div>
                                            <div class="info-cell">
                                                <div class="info-label"><i class="far fa-user"></i> 查核人員</div>
                                                <div class="info-val">{{ detail.Report_UserName || detail.Report_User || '---' }}</div>
                                            </div>
                                            <div class="info-cell">
                                                <div class="info-label"><i class="fas fa-map-marker-alt"></i> 行政區 / 道路級別</div>
                                                <div class="info-val">
                                                    <span class="badge badge-secondary mr-1">{{ detail.TownName }}</span>
                                                    <span class="badge badge-info">{{ detail.ROAD_LV || '市區道路' }}</span>
                                                </div>
                                            </div>
                                            <div class="info-cell" style="grid-column: 1 / -1;">
                                                <div class="info-label"><i class="fas fa-road"></i> 道路名稱 / 路段</div>
                                                <div class="info-val font-weight-bold" style="font-size: 1.05rem;">{{ detail.ROAD_Name || '未填寫' }}</div>
                                            </div>
                                            <div class="info-cell">
                                                <div class="info-label"><i class="fas fa-shoe-prints"></i> 人行道鋪面平整度</div>
                                                <div class="info-val">
                                                    <span class="stat-chip" :class="getSmoothChipClass(detail.Smooth)">
                                                        <i class="fas fa-check-circle" v-if="detail.Smooth === '1'"></i>
                                                        <i class="fas fa-exclamation-triangle" v-else></i>
                                                        {{ detail.SmoothName }}
                                                    </span>
                                                </div>
                                            </div>
                                            <div class="info-cell">
                                                <div class="info-label"><i class="fas fa-mountain"></i> 交通島/人行道覆土狀況</div>
                                                <div class="info-val">
                                                    <span class="stat-chip" :class="getCoverChipClass(detail.Cover_Soil)">
                                                        <i class="fas fa-seedling" v-if="detail.Cover_Soil === '1'"></i>
                                                        <i class="fas fa-exclamation-circle" v-else></i>
                                                        {{ detail.CoverSoilName }}
                                                    </span>
                                                </div>
                                            </div>
                                            <div class="info-cell" style="grid-column: 1 / -1;">
                                                <div class="info-label"><i class="fas fa-comment-alt"></i> 其他通報補充說明</div>
                                                <div class="info-val font-weight-normal text-secondary" style="white-space: pre-wrap;">
                                                    {{ detail.Memo || '無補充描述說明' }}
                                                </div>
                                            </div>
                                            <div class="info-cell" style="grid-column: 1 / -1;">
                                                <div class="info-label"><i class="fas fa-crosshairs"></i> 現場坐標 (TWD97 / WGS84)</div>
                                                <div class="info-val small text-monospace">
                                                    <span class="mr-2">TWD97: E {{ detail.S_UTME }}, N {{ detail.S_UTMN }}</span>
                                                    <span v-if="detail.Lat && detail.Lon" class="text-primary font-weight-bold">
                                                        (緯度: {{ detail.Lat }}, 經度: {{ detail.Lon }})
                                                    </span>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </section>

                                <!-- 卡片 B: 智慧現場地圖 (Leaflet.js) -->
                                <section class="card-modern">
                                    <div class="card-modern-header">
                                        <h3 class="card-modern-title">
                                            <i class="fas fa-map-marked-alt text-success"></i>
                                            現場地理位置地圖
                                        </h3>
                                        <div class="d-flex align-items-center gap-1">
                                            <button type="button" class="btn btn-outline-primary btn-sm px-2 py-1" v-on:click="recenterMap" title="置中到點位">
                                                <i class="fas fa-crosshairs"></i> 定位
                                            </button>
                                            <button type="button" class="btn btn-outline-secondary btn-sm px-2 py-1 d-md-none" v-on:click="toggleMapCollapse">
                                                <i :class="isMapCollapsed ? 'fas fa-chevron-down' : 'fas fa-chevron-up'"></i>
                                                {{ isMapCollapsed ? '展開' : '收合' }}
                                            </button>
                                        </div>
                                    </div>
                                    <div class="card-modern-body p-2">
                                        <div id="map" :class="{ 'map-collapsed': isMapCollapsed }"></div>
                                        <small class="text-muted d-block text-center mt-1">
                                            <i class="fas fa-info-circle mr-1"></i> 點擊地圖標記 Pin 可檢視座標與路段資訊
                                        </small>
                                    </div>
                                </section>

                                <!-- 卡片 C: 派工與改善回報歷程 -->
                                <section class="card-modern">
                                    <div class="card-modern-header">
                                        <h3 class="card-modern-title">
                                            <i class="fas fa-tasks text-warning"></i>
                                            處理派工與改善歷程
                                        </h3>
                                        <small class="text-muted font-weight-bold" v-if="detail.SetCOM_Date">
                                            派工時間：{{ detail.SetCOM_Date }}
                                        </small>
                                    </div>
                                    <div class="card-modern-body">
                                        <div class="info-grid">
                                            <div class="info-cell">
                                                <div class="info-label"><i class="fas fa-building"></i> 通報指派單位</div>
                                                <div class="info-val text-info font-weight-bold">{{ detail.S_COM_NAME || '尚未指派' }}</div>
                                            </div>
                                            <div class="info-cell">
                                                <div class="info-label"><i class="fas fa-user-edit"></i> 派工通報人員</div>
                                                <div class="info-val">{{ detail.S_UserName || detail.S_User || '尚未指派' }}</div>
                                            </div>
                                            <div class="info-cell">
                                                <div class="info-label"><i class="fas fa-hard-hat"></i> 責任處理單位</div>
                                                <div class="info-val font-weight-bold">{{ detail.G_COM_NAME || '尚未指定' }}</div>
                                            </div>
                                            <div class="info-cell">
                                                <div class="info-label"><i class="fas fa-user-check"></i> 改善回報人員</div>
                                                <div class="info-val">{{ detail.G_UserName || detail.G_User || '待回報' }}</div>
                                            </div>
                                            <div class="info-cell" style="grid-column: 1 / -1;">
                                                <div class="info-label"><i class="fas fa-clock"></i> 改善完成時間</div>
                                                <div class="info-val text-success">{{ detail.Improve_Date || '尚未完成改善' }}</div>
                                            </div>
                                            <div class="info-cell" style="grid-column: 1 / -1;">
                                                <div class="info-label"><i class="fas fa-comment-dots"></i> 處理備註 / 結案說明</div>
                                                <div class="info-val font-weight-normal text-secondary" style="white-space: pre-wrap;">
                                                    {{ detail.G_Memo || '尚無處理備註' }}
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </section>
                            </div>
                        </div>

                        <!-- 右欄：現場照片與改善前後對照專區 (60% 寬度) -->
                        <div class="col-xl-7 col-lg-7 col-12">
                            <section class="card-modern">
                                <div class="card-modern-header">
                                    <h3 class="card-modern-title">
                                        <i class="fas fa-images text-danger"></i>
                                        現場佐證與改善照片對照
                                    </h3>
                                    <div class="text-muted small font-weight-bold">
                                        共 {{ (detail.PhotoPairs && detail.PhotoPairs.length) || 0 }} 組照片紀錄
                                    </div>
                                </div>
                                <div class="card-modern-body">
                                    <!-- 若無照片 -->
                                    <div v-if="!detail.PhotoPairs || detail.PhotoPairs.length === 0" class="text-center py-5 text-muted">
                                        <i class="far fa-images fa-3x mb-3 text-secondary"></i>
                                        <p class="font-weight-bold">目前本通報單無佐證照片紀錄</p>
                                    </div>

                                    <!-- 照片對照清單 -->
                                    <div v-else>
                                        <div v-for="pair in detail.PhotoPairs" :key="pair.PairIndex" class="comparison-pair-card">
                                            <div class="pair-header">
                                                <span><i class="fas fa-camera text-primary mr-1"></i> {{ pair.Title }}</span>
                                                <span class="badge badge-light text-dark font-weight-normal">序號 #{{ pair.PairIndex }}</span>
                                            </div>
                                            <div class="pair-grid">
                                                <!-- 1. 改善前現場佐證照片 -->
                                                <div class="pair-photo-box">
                                                    <span class="photo-tag tag-before">
                                                        <i class="fas fa-exclamation-triangle mr-1"></i> 改善前佐證照片
                                                    </span>
                                                    <div v-if="pair.BeforeExists" class="img-wrapper" v-on:click="openLightbox(pair.BeforeUrl, pair.Title + ' (改善前)')">
                                                        <img :src="pair.BeforeUrl" :alt="pair.Title + ' 改善前'" loading="lazy" />
                                                        <div class="img-overlay-btn">
                                                            <i class="fas fa-search-plus"></i> 放大檢視
                                                        </div>
                                                    </div>
                                                    <div v-else class="img-empty-box">
                                                        <i class="far fa-image fa-2x"></i>
                                                        <span>無改善前照片</span>
                                                    </div>
                                                    <div class="img-meta-row" v-if="pair.BeforeExists">
                                                        <span class="text-truncate" style="max-width: 180px;" :title="pair.BeforeFileName">
                                                            {{ pair.BeforeFileName }}
                                                        </span>
                                                        <span>{{ formatFileSize(pair.BeforeSize) }}</span>
                                                    </div>
                                                </div>

                                                <!-- 2. 改善後成果佐證照片 -->
                                                <div class="pair-photo-box">
                                                    <span class="photo-tag tag-after">
                                                        <i class="fas fa-check-circle mr-1"></i> 改善後成果照片
                                                    </span>
                                                    <div v-if="pair.AfterExists" class="img-wrapper" v-on:click="openLightbox(pair.AfterUrl, pair.Title + ' (改善後)')">
                                                        <img :src="pair.AfterUrl" :alt="pair.Title + ' 改善後'" loading="lazy" />
                                                        <div class="img-overlay-btn">
                                                            <i class="fas fa-search-plus"></i> 放大檢視
                                                        </div>
                                                    </div>
                                                    <div v-else class="img-empty-box">
                                                        <i class="fas fa-hourglass-half fa-2x text-warning"></i>
                                                        <span class="font-weight-bold text-dark">待改善單位拍照上傳</span>
                                                        <small class="text-muted">（尚未回報改善後照片）</small>
                                                    </div>
                                                    <div class="img-meta-row" v-if="pair.AfterExists">
                                                        <span class="text-truncate" style="max-width: 180px;" :title="pair.AfterFileName">
                                                            {{ pair.AfterFileName }}
                                                        </span>
                                                        <span>{{ formatFileSize(pair.AfterSize) }}</span>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </section>
                        </div>
                    </div>
                </div>
            </main>

            <!-- 4. 全螢幕照片燈箱 (Lightbox Modal) -->
            <div v-if="lightbox.visible" class="lightbox-backdrop no-print" v-on:click.self="closeLightbox">
                <div class="lightbox-toolbar">
                    <button type="button" class="lightbox-btn" v-on:click="rotateLightbox(-90)" title="逆時針旋轉90度">
                        <i class="fas fa-undo"></i> 逆時針
                    </button>
                    <button type="button" class="lightbox-btn" v-on:click="rotateLightbox(90)" title="順時針旋轉90度">
                        <i class="fas fa-redo"></i> 順時針
                    </button>
                    <a :href="lightbox.url" target="_blank" class="lightbox-btn" title="另開新視窗檢視原始大圖">
                        <i class="fas fa-external-link-alt"></i> 原圖
                    </a>
                    <button type="button" class="lightbox-btn bg-danger border-danger" v-on:click="closeLightbox" title="關閉燈箱">
                        <i class="fas fa-times"></i> 關閉 (ESC)
                    </button>
                </div>

                <div class="lightbox-img-container" :style="{ transform: 'rotate(' + lightbox.rotation + 'deg)' }">
                    <img :src="lightbox.url" :alt="lightbox.title" />
                </div>
                <div class="lightbox-title">{{ lightbox.title }}</div>
            </div>

            <!-- 5. 行動端常駐浮動動作列 (Sticky Bottom Bar) -->
            <nav class="mobile-bottom-bar no-print">
                <a :href="detail.BackListUrl || 'BSC_List.aspx'" class="btn btn-outline-secondary">
                    <i class="fas fa-arrow-left mr-1"></i> 返回
                </a>
                <button type="button" class="btn btn-info" v-on:click="printCase">
                    <i class="fas fa-print mr-1"></i> 列印
                </button>
                <template v-if="detail.StatusCode === 1">
                    <a :href="detail.EditUrl" class="btn btn-warning">
                        <i class="fas fa-edit mr-1"></i> 編輯
                    </a>
                    <a :href="detail.SetSGUrl" class="btn btn-primary">
                        <i class="fas fa-paper-plane mr-1"></i> 派工
                    </a>
                </template>
                <template v-else-if="detail.StatusCode === 2">
                    <a :href="detail.ImproveUrl" class="btn btn-success">
                        <i class="fas fa-tools mr-1"></i> 改善
                    </a>
                </template>
            </nav>
        </div>
    </form>

    <!-- 本地核心腳本依賴 (無外部 CDN 阻擋) -->
    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>
    <script src="../Scripts/leaflet/leaflet.js"></script>

    <script>
        (function () {
            'use strict';
            const { createApp, ref, reactive, computed, nextTick, onMounted, onBeforeUnmount } = Vue;

            createApp({
                setup() {
                    const loading = ref(true);
                    const errorMessage = ref('');
                    const isMapCollapsed = ref(false);
                    const printTime = ref('');

                    const detail = reactive({
                        BSC_ID: '',
                        Show_ID: '',
                        Report_Date: '',
                        Report_User: '',
                        Report_UserName: '',
                        TOWN_CODE: '',
                        TownName: '',
                        ROAD_LV: '',
                        ROAD_Name: '',
                        Smooth: '',
                        SmoothName: '',
                        Cover_Soil: '',
                        CoverSoilName: '',
                        Memo: '',
                        S_UTME: '',
                        S_UTMN: '',
                        Lat: '',
                        Lon: '',
                        SetCOM_Date: '',
                        S_User: '',
                        S_UserName: '',
                        S_COM: '',
                        S_COM_NAME: '',
                        G_COM: '',
                        G_COM_NAME: '',
                        Improve_Date: '',
                        G_User: '',
                        G_UserName: '',
                        G_Memo: '',
                        G_Back: 'N',
                        IsBack: false,
                        StatusCode: 1,
                        StatusText: '暫存未派工',
                        StatusBadgeClass: 'badge-secondary',
                        PhotoPairs: [],
                        EditUrl: '',
                        SetSGUrl: '',
                        ImproveUrl: '',
                        BackListUrl: 'BSC_List.aspx'
                    });

                    // 燈箱狀態
                    const lightbox = reactive({
                        visible: false,
                        url: '',
                        title: '',
                        rotation: 0
                    });

                    // Leaflet 實例 (嚴格非響應式原生變數，徹底隔離防止 project of null)
                    let leafletMap = null;
                    let markerPin = null;

                    // 取得 URL 查詢參數
                    const getUrlParam = function (param) {
                        const urlParams = new URLSearchParams(window.location.search);
                        return urlParams.get(param) || '';
                    };

                    // 計算進度條百分比
                    const stepperProgress = computed(function () {
                        if (detail.StatusCode === 3) return 100;
                        if (detail.StatusCode === 2) return 50;
                        return 0;
                    });

                    // 取得步驟項目樣式
                    const getStepClass = function (step) {
                        if (detail.StatusCode > step) return 'completed';
                        if (detail.StatusCode === step) return 'active';
                        return '';
                    };

                    // 平整度狀態標籤樣式
                    const getSmoothChipClass = function (code) {
                        if (code === '1') return 'chip-smooth-1';
                        if (code === '2') return 'chip-smooth-2';
                        if (code === '3') return 'chip-smooth-3';
                        if (code === '4') return 'chip-smooth-4';
                        return 'chip-smooth-other';
                    };

                    // 覆土狀況標籤樣式
                    const getCoverChipClass = function (code) {
                        if (code === '1') return 'chip-cover-1';
                        if (code === '2') return 'chip-cover-2';
                        if (code === '3') return 'chip-cover-3';
                        if (code === '4') return 'chip-cover-4';
                        return 'chip-cover-other';
                    };

                    // 檔案大小格式化
                    const formatFileSize = function (bytes) {
                        if (!bytes || bytes <= 0) return '';
                        if (bytes < 1024) return bytes + ' B';
                        if (bytes < 1048576) return (bytes / 1024).toFixed(1) + ' KB';
                        return (bytes / 1048576).toFixed(2) + ' MB';
                    };

                    // 載入通報案件資料
                    const loadDetail = function () {
                        const bscId = getUrlParam('id');
                        const chk = getUrlParam('chk');
                        const parmode = getUrlParam('parmode');

                        if (!bscId) {
                            loading.value = false;
                            errorMessage.value = '未指定通報案號參數 (?id=)';
                            return;
                        }

                        loading.value = true;
                        errorMessage.value = '';

                        axios.get('BSCDetail.aspx', {
                            params: {
                                action: 'getdetail',
                                id: bscId,
                                chk: chk,
                                parmode: parmode,
                                t: new Date().getTime()
                            }
                        })
                        .then(function (res) {
                            loading.value = false;
                            if (res.data && res.data.Success) {
                                Object.assign(detail, res.data.Data);
                                nextTick(function () {
                                    initMap();
                                });
                            } else {
                                errorMessage.value = (res.data && res.data.Message) || '查無此案件紀錄';
                            }
                        })
                        .catch(function (err) {
                            loading.value = false;
                            errorMessage.value = '伺服器網路連線異常：' + (err.message || err);
                        });
                    };

                    // 初始化 Leaflet 地圖
                    const initMap = function () {
                        const mapDiv = document.getElementById('map');
                        if (!mapDiv) return;

                        let centerLat = 25.0123;
                        let centerLon = 121.4657;
                        let defaultZoom = 13;

                        const latNum = parseFloat(detail.Lat);
                        const lonNum = parseFloat(detail.Lon);

                        if (!isNaN(latNum) && !isNaN(lonNum) && latNum > 0 && lonNum > 0) {
                            centerLat = latNum;
                            centerLon = lonNum;
                            defaultZoom = 16;
                        }

                        if (!leafletMap) {
                            leafletMap = L.map('map', {
                                center: [centerLat, centerLon],
                                zoom: defaultZoom,
                                zoomControl: true
                            });

                            // 1. 底圖宣告
                            const emapLayer = L.tileLayer('https://wmts.nlsc.gov.tw/wmts/EMAP/default/GoogleMapsCompatible/{z}/{y}/{x}', {
                                maxZoom: 19,
                                attribution: '&copy; 內政部國土測繪中心 臺灣通用電子地圖'
                            });

                            const photoLayer = L.tileLayer('https://wmts.nlsc.gov.tw/wmts/PHOTO2/default/GoogleMapsCompatible/{z}/{y}/{x}', {
                                maxZoom: 19,
                                attribution: '&copy; 內政部國土測繪中心 正射影像圖'
                            });

                            const osmLayer = L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                                maxZoom: 19,
                                attribution: '&copy; OpenStreetMap'
                            });

                            emapLayer.addTo(leafletMap);

                            // 圖層切換控制項 (右上角)
                            const baseMaps = {
                                "通用電子地圖": emapLayer,
                                "正射影像圖": photoLayer,
                                "OpenStreetMap": osmLayer
                            };
                            L.control.layers(baseMaps).addTo(leafletMap);
                        } else {
                            leafletMap.setView([centerLat, centerLon], defaultZoom);
                        }

                        // 清除舊標記
                        if (markerPin) {
                            leafletMap.removeLayer(markerPin);
                            markerPin = null;
                        }

                        // 新增點位 Pin
                        if (!isNaN(latNum) && !isNaN(lonNum) && latNum > 0 && lonNum > 0) {
                            const iconHtml = '<div class="marker-pin"><span class="marker-num"><i class="fas fa-tree"></i></span></div>';
                            const customIcon = L.divIcon({
                                className: 'custom-map-marker',
                                html: iconHtml,
                                iconSize: [32, 32],
                                iconAnchor: [16, 32],
                                popupAnchor: [0, -32]
                            });

                            markerPin = L.marker([latNum, lonNum], { icon: customIcon }).addTo(leafletMap);

                            const popupContent = [
                                '<div style="min-width: 200px; font-family: sans-serif;">',
                                '<div style="font-weight: 700; color: #0f172a; border-bottom: 1px solid #e2e8f0; padding-bottom: 4px; margin-bottom: 6px;">',
                                '<i class="fas fa-road text-primary mr-1"></i> ' + (detail.ROAD_Name || '通報路段'),
                                '</div>',
                                '<div style="font-size: 12px; margin-bottom: 2px;"><strong>行政區：</strong>' + detail.TownName + '</div>',
                                '<div style="font-size: 12px; margin-bottom: 2px;"><strong>平整度：</strong>' + detail.SmoothName + '</div>',
                                '<div style="font-size: 12px; margin-bottom: 2px;"><strong>覆土狀況：</strong>' + detail.CoverSoilName + '</div>',
                                '<div style="font-size: 11px; color: #64748b; margin-top: 4px;">坐標: ' + latNum.toFixed(6) + ', ' + lonNum.toFixed(6) + '</div>',
                                '</div>'
                            ].join('');

                            markerPin.bindPopup(popupContent).openPopup();
                        }
                    };

                    // 重設地圖置中
                    const recenterMap = function () {
                        if (!leafletMap) return;
                        const latNum = parseFloat(detail.Lat);
                        const lonNum = parseFloat(detail.Lon);
                        if (!isNaN(latNum) && !isNaN(lonNum) && latNum > 0 && lonNum > 0) {
                            leafletMap.setView([latNum, lonNum], 16, { animate: true });
                            if (markerPin) markerPin.openPopup();
                        } else {
                            leafletMap.setView([25.0123, 121.4657], 13, { animate: true });
                        }
                    };

                    // 地圖收合/展開切換
                    const toggleMapCollapse = function () {
                        isMapCollapsed.value = !isMapCollapsed.value;
                        nextTick(function () {
                            if (leafletMap) {
                                leafletMap.invalidateSize();
                            }
                        });
                    };

                    // 燈箱開關與旋轉
                    const openLightbox = function (url, title) {
                        lightbox.url = url;
                        lightbox.title = title || '現場佐證照片';
                        lightbox.rotation = 0;
                        lightbox.visible = true;
                    };

                    const closeLightbox = function () {
                        lightbox.visible = false;
                        lightbox.url = '';
                        lightbox.rotation = 0;
                    };

                    const rotateLightbox = function (deg) {
                        lightbox.rotation = (lightbox.rotation + deg) % 360;
                    };

                    // 列印案件
                    const printCase = function () {
                        const now = new Date();
                        printTime.value = now.getFullYear() + '-' +
                            String(now.getMonth() + 1).padStart(2, '0') + '-' +
                            String(now.getDate()).padStart(2, '0') + ' ' +
                            String(now.getHours()).padStart(2, '0') + ':' +
                            String(now.getMinutes()).padStart(2, '0');
                        window.print();
                    };

                    // 鍵盤 ESC 關閉燈箱監聽
                    const onKeyDown = function (e) {
                        if (e.key === 'Escape' && lightbox.visible) {
                            closeLightbox();
                        }
                    };

                    onMounted(function () {
                        window.addEventListener('keydown', onKeyDown);
                        loadDetail();
                    });

                    onBeforeUnmount(function () {
                        window.removeEventListener('keydown', onKeyDown);
                    });

                    return {
                        loading,
                        errorMessage,
                        isMapCollapsed,
                        printTime,
                        detail,
                        lightbox,
                        stepperProgress,
                        getStepClass,
                        getSmoothChipClass,
                        getCoverChipClass,
                        formatFileSize,
                        loadDetail,
                        recenterMap,
                        toggleMapCollapse,
                        openLightbox,
                        closeLightbox,
                        rotateLightbox,
                        printCase
                    };
                }
            }).mount('#detailApp');
        })();
    </script>
</body>
</html>