<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="DirtyDetail.aspx.cs" Inherits="NTPC_FEC.RoadClean.DirtyDetail" %>
<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定溢散源管理平台 - 道路髒污通報單詳情</title>
    
    <link rel="shortcut icon" href="../favicon.ico" type="image/x-icon" />

    <!-- 本地化樣式依賴 -->
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
            font-size: 1.02rem; font-weight: 700; color: var(--brand-navy); margin: 0;
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

        /* 資訊清單表格排版 (Info Grid) */
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
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

        /* 類型標籤 Badges */
        .kind-badge {
            display: inline-flex; align-items: center; gap: 4px;
            padding: 4px 10px; border-radius: 6px;
            font-size: 13px; font-weight: 700;
        }
        .kind-EB { background: #fee2e2; color: #b91c1c; border: 1px solid #fca5a5; }
        .kind-EF { background: #e0f2fe; color: #0369a1; border: 1px solid #7dd3fc; }
        .kind-ES { background: #fef3c7; color: #b45309; border: 1px solid #fde68a; }
        .kind-OS { background: #f3e8ff; color: #6b21a8; border: 1px solid #d8b4fe; }
        .kind-OR { background: #ecfdf5; color: #047857; border: 1px solid #a7f3d0; }

        /* 地圖容器 */
        #map {
            width: 100%;
            height: 380px;
            border-radius: 8px;
            z-index: 10;
        }

        /* 地圖標記 Pin */
        .custom-map-marker { display: flex; align-items: center; justify-content: center; }
        .marker-pin {
            width: 32px; height: 32px;
            border-radius: 50% 50% 50% 0;
            background: #ef4444;
            position: absolute; transform: rotate(-45deg);
            left: 50%; top: 50%; margin: -20px 0 0 -16px;
            box-shadow: 0 3px 8px rgba(0, 0, 0, 0.35);
            border: 2px solid #ffffff;
            display: flex; align-items: center; justify-content: center;
            cursor: pointer;
        }
        .marker-pin.marker-end { background: #f59e0b; }
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
        .photo-column {
            background: #ffffff;
            padding: 12px;
            display: flex;
            flex-direction: column;
            align-items: center;
        }
        .photo-column-header {
            width: 100%;
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 8px;
        }
        .badge-before {
            background: #fee2e2;
            color: #dc2626;
            font-weight: 700;
            padding: 3px 8px;
            border-radius: 4px;
            font-size: 12px;
            display: inline-flex; align-items: center; gap: 4px;
        }
        .badge-after {
            background: #ecfdf5;
            color: #059669;
            font-weight: 700;
            padding: 3px 8px;
            border-radius: 4px;
            font-size: 12px;
            display: inline-flex; align-items: center; gap: 4px;
        }
        .photo-preview-wrap {
            width: 100%;
            height: 220px;
            border-radius: 6px;
            overflow: hidden;
            background: #0f172a;
            position: relative;
            cursor: pointer;
            display: flex; align-items: center; justify-content: center;
        }
        .photo-preview-wrap img {
            width: 100%;
            height: 100%;
            object-fit: contain;
            transition: transform 0.25s ease;
        }
        .photo-preview-wrap:hover img {
            transform: scale(1.03);
        }
        .photo-zoom-overlay {
            position: absolute;
            inset: 0;
            background: rgba(0, 0, 0, 0.35);
            display: flex; align-items: center; justify-content: center;
            opacity: 0;
            transition: opacity 0.2s;
            color: #ffffff;
            font-size: 1.5rem;
        }
        .photo-preview-wrap:hover .photo-zoom-overlay {
            opacity: 1;
        }
        .photo-empty-placeholder {
            width: 100%;
            height: 220px;
            border-radius: 6px;
            border: 2px dashed #cbd5e1;
            background: #f8fafc;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            color: #94a3b8;
            font-size: 13px;
            text-align: center;
            padding: 16px;
        }
        .photo-empty-placeholder i {
            font-size: 2.2rem;
            margin-bottom: 8px;
            color: #cbd5e1;
        }

        /* 退回警示列 */
        .alert-gback {
            background: #fef2f2;
            border: 1px solid #fca5a5;
            border-left: 5px solid #ef4444;
            color: #991b1b;
            padding: 12px 16px;
            border-radius: 8px;
            margin-bottom: 16px;
            font-weight: 700;
            display: flex; align-items: center; gap: 10px;
        }

        /* 燈箱 Modal */
        .lightbox-modal {
            position: fixed; inset: 0; z-index: 1080;
            background: rgba(0, 0, 0, 0.85);
            display: flex; align-items: center; justify-content: center;
            padding: 16px;
        }
        .lightbox-content {
            position: relative;
            max-width: 90vw;
            max-height: 90vh;
            display: flex; flex-direction: column; align-items: center;
        }
        .lightbox-content img {
            max-width: 100%;
            max-height: 85vh;
            object-fit: contain;
            border-radius: 8px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.6);
        }
        .lightbox-close {
            position: absolute;
            top: -44px; right: 0;
            background: rgba(255, 255, 255, 0.2);
            border: none; color: #ffffff;
            font-size: 1.5rem; width: 38px; height: 38px; border-radius: 50%;
            display: flex; align-items: center; justify-content: center;
            cursor: pointer; transition: background 0.2s;
        }
        .lightbox-close:hover { background: rgba(255, 255, 255, 0.4); }

        /* 列印樣式優化 (@media print) */
        @media print {
            body { background: #ffffff !important; color: #000000 !important; }
            .top-navbar, .no-print, .stepper-container, .btn, .lightbox-modal { display: none !important; }
            .card-modern { border: 1px solid #000000 !important; box-shadow: none !important; margin-bottom: 14px !important; }
            .card-modern-header { background: #f0f0f0 !important; border-bottom: 1px solid #000000 !important; }
            .info-cell { background: #ffffff !important; border: 1px solid #cccccc !important; }
            .comparison-pair-card { page-break-inside: avoid; border: 1px solid #000000 !important; }
            #map { height: 260px !important; border: 1px solid #000000 !important; }
            .container-fluid-custom { padding: 0 !important; max-width: 100% !important; }
            .print-header { display: block !important; margin-bottom: 16px; text-align: center; }
            .print-header h3 { margin: 0; font-size: 20pt; font-weight: bold; }
            .print-header p { margin: 4px 0 0; font-size: 11pt; color: #555; }
        }

        .print-header { display: none; }

        @media screen and (max-width: 767px) {
            .pair-grid { grid-template-columns: 1fr; }
            .stepper-container { padding: 12px 8px; }
            .step-title { font-size: 11px; }
            .photo-preview-wrap { height: 180px; }
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div id="detailApp" v-cloak>
            <!-- 1. 頂部導覽列 -->
            <header class="top-navbar no-print">
                <div class="brand-title">
                    <button type="button" class="nav-btn mr-2" v-on:click="goBack" title="返回清單">
                        <i class="fas fa-arrow-left"></i>
                        <span class="d-none d-sm-inline">返回清單</span>
                    </button>
                    <i class="fas fa-clipboard-list text-white"></i>
                    <span>道路污染通報案件詳情</span>
                    <span v-if="detail.ShowId" class="badge badge-light text-dark font-weight-bold ml-2" style="font-size: 0.85rem;">
                        {{ detail.ShowId }}
                    </span>
                </div>

                <div class="d-flex align-items-center gap-2">
                    <!-- 列印案件按鈕 -->
                    <button type="button" class="nav-btn bg-white text-dark shadow-sm" v-on:click="printReport" title="列印案件">
                        <i class="fas fa-print"></i>
                        <span class="d-none d-md-inline">列印案件</span>
                    </button>

                    <!-- 依案件狀態動態切換操作按鈕 -->
                    <template v-if="detail.StatusCode === 1">
                        <a :href="'NewDirty.aspx?id=' + encodeURIComponent(detail.DirtyId) + '&mode=edit'" class="btn btn-warning btn-sm font-weight-bold shadow-sm ml-2">
                            <i class="fas fa-edit mr-1"></i> 編輯案件
                        </a>
                        <a :href="'SetSG_Dirty.aspx?id=' + encodeURIComponent(detail.DirtyId)" class="btn btn-primary btn-sm font-weight-bold shadow-sm ml-2">
                            <i class="fas fa-paper-plane mr-1"></i> 派工通報
                        </a>
                    </template>
                    <template v-else-if="detail.StatusCode === 2">
                        <a :href="'ImproveDirty.aspx?id=' + encodeURIComponent(detail.DirtyId)" class="btn btn-success btn-sm font-weight-bold shadow-sm ml-2">
                            <i class="fas fa-tools mr-1"></i> 改善回報
                        </a>
                    </template>
                </div>
            </header>

            <!-- 主作業容器 -->
            <main class="container-fluid-custom">
                <!-- 列印專用抬頭 (僅在列印時顯示) -->
                <div class="print-header">
                    <h3>新北市固定溢散源管理系統 - 道路污染通報報告單</h3>
                    <p>列印時間：{{ printTime }} ｜ 通報案號：{{ detail.ShowId }}</p>
                    <hr />
                </div>

                <!-- 載入中骨架提示 -->
                <div v-if="loading" class="text-center py-5">
                    <div class="spinner-border text-primary" style="width: 3rem; height: 3rem;" role="status">
                        <span class="sr-only">讀取中...</span>
                    </div>
                    <p class="text-muted font-weight-bold mt-3">正在載入通報案件資料，請稍候...</p>
                </div>

                <!-- 載入失敗錯誤提示 -->
                <div v-else-if="errorMessage" class="alert alert-danger shadow-sm my-4">
                    <i class="fas fa-exclamation-triangle mr-2"></i>
                    <strong>載入失敗：</strong> {{ errorMessage }}
                    <div class="mt-3">
                        <button type="button" class="btn btn-outline-danger btn-sm" v-on:click="loadDetail">重新整理重試</button>
                    </div>
                </div>

                <!-- 資料展示主體 -->
                <div v-else>
                    <!-- 案件退回重辦警告卡片 -->
                    <div v-if="detail.G_Back === 'Y'" class="alert-gback shadow-sm">
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
                            <div class="step-time">{{ detail.ReportDate || '未填寫' }}</div>
                        </div>

                        <!-- 步驟 2: 派工改善通報 -->
                        <div class="step-item" :class="getStepClass(2)">
                            <div class="step-circle">
                                <i v-if="detail.StatusCode > 2" class="fas fa-check"></i>
                                <span v-else>2</span>
                            </div>
                            <div class="step-title">{{ detail.G_Back === 'Y' ? '案件退回待重派' : '派工改善通報' }}</div>
                            <div class="step-time">{{ detail.SetComDate || '待通報' }}</div>
                        </div>

                        <!-- 步驟 3: 改善完成結案 -->
                        <div class="step-item" :class="getStepClass(3)">
                            <div class="step-circle">
                                <i v-if="detail.StatusCode === 3" class="fas fa-check"></i>
                                <span v-else>3</span>
                            </div>
                            <div class="step-title">改善完成結案</div>
                            <div class="step-time">{{ detail.ImproveDate || '待改善' }}</div>
                        </div>
                    </div>

                    <!-- 3. 雙欄主要工作區 -->
                    <div class="row">
                        <!-- 左側：案件資訊與照片對照專區 (Col-lg-7) -->
                        <div class="col-12 col-lg-7">
                            <!-- 卡片 1：查核基本資訊 -->
                            <div class="card-modern">
                                <div class="card-modern-header">
                                    <h2 class="card-modern-title">
                                        <i class="fas fa-info-circle text-primary"></i>
                                        <span>查核基本資訊</span>
                                    </h2>
                                    <span class="badge px-3 py-1 font-weight-bold" :class="detail.StatusBadgeClass" style="font-size: 13px;">
                                        {{ detail.StatusText }}
                                    </span>
                                </div>
                                <div class="card-modern-body">
                                    <div class="info-grid">
                                        <div class="info-cell">
                                            <div class="info-label"><i class="fas fa-hashtag"></i> 通報案號</div>
                                            <div class="info-val text-primary">{{ detail.ShowId }}</div>
                                        </div>

                                        <div class="info-cell">
                                            <div class="info-label"><i class="fas fa-calendar-alt"></i> 查核時間</div>
                                            <div class="info-val">{{ detail.ReportDate || '未填寫' }}</div>
                                        </div>

                                        <div class="info-cell">
                                            <div class="info-label"><i class="fas fa-user"></i> 查核人員</div>
                                            <div class="info-val">{{ detail.ReportUserName || detail.ReportUser || '---' }}</div>
                                        </div>

                                        <div class="info-cell">
                                            <div class="info-label"><i class="fas fa-tag"></i> 通報類別</div>
                                            <div class="info-val">
                                                <span class="kind-badge" :class="'kind-' + detail.Kind">
                                                    {{ detail.KindName }}
                                                </span>
                                            </div>
                                        </div>
                                    </div>

                                    <!-- 查核通報補充說明 -->
                                    <div class="mt-3">
                                        <div class="info-label"><i class="fas fa-comment-dots"></i> 查核說明 / 現場狀況描述</div>
                                        <div class="p-3 bg-light rounded border text-dark" style="min-height: 48px; line-height: 1.6;">
                                            {{ detail.Comm || '無補充描述說明' }}
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- 卡片 2：派工與改善歷程 -->
                            <div class="card-modern">
                                <div class="card-modern-header">
                                    <h2 class="card-modern-title">
                                        <i class="fas fa-tasks text-success"></i>
                                        <span>通報派工與改善歷程</span>
                                    </h2>
                                    <small class="text-muted font-weight-bold" v-if="detail.SetComDate">
                                        派工時間：{{ detail.SetComDate }}
                                    </small>
                                </div>
                                <div class="card-modern-body">
                                    <div class="info-grid mb-3">
                                        <div class="info-cell">
                                            <div class="info-label"><i class="fas fa-building"></i> 權責處理單位</div>
                                            <div class="info-val text-info font-weight-bold">{{ detail.G_ComName || '尚未指定' }}</div>
                                        </div>

                                        <div class="info-cell">
                                            <div class="info-label"><i class="fas fa-user-check"></i> 通報派工人員</div>
                                            <div class="info-val">{{ detail.S_UserName || '尚未指派' }}</div>
                                        </div>

                                        <div class="info-cell">
                                            <div class="info-label"><i class="fas fa-calendar-check"></i> 處理回報時間</div>
                                            <div class="info-val" :class="detail.ImproveDate ? 'text-success' : 'text-muted'">
                                                {{ detail.ImproveDate || '尚未回報完成' }}
                                            </div>
                                        </div>

                                        <div class="info-cell">
                                            <div class="info-label"><i class="fas fa-user-edit"></i> 改善回報人員</div>
                                            <div class="info-val">{{ detail.G_UserName || '尚未回報' }}</div>
                                        </div>
                                    </div>

                                    <!-- 改善處理備註說明 -->
                                    <div>
                                        <div class="info-label"><i class="fas fa-sticky-note"></i> 處理備註 / 成果說明</div>
                                        <div class="p-3 bg-light rounded border text-dark" style="min-height: 48px; line-height: 1.6;">
                                            {{ detail.G_Memo || '尚無改善回報備註' }}
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- 卡片 3：改善前後照片對照專區 -->
                            <div class="card-modern">
                                <div class="card-modern-header">
                                    <h2 class="card-modern-title">
                                        <i class="fas fa-images text-warning"></i>
                                        <span>改善前後照片對照專區</span>
                                    </h2>
                                    <span class="badge badge-secondary px-2 py-1">
                                        共 {{ (detail.SitePhotoPairs || []).length + (detail.EvidencePhotoPairs || []).length }} 組對照
                                    </span>
                                </div>
                                <div class="card-modern-body">
                                    <!-- A. 疑似髒污點現場照片組 -->
                                    <div class="mb-4">
                                        <h6 class="font-weight-bold text-danger d-flex align-items-center gap-2 mb-3">
                                            <i class="fas fa-exclamation-circle"></i> 疑似髒污點現場照片對照 ({{ (detail.SitePhotoPairs || []).length }} 組)
                                        </h6>

                                        <div v-if="(detail.SitePhotoPairs || []).length > 0">
                                            <div v-for="pair in detail.SitePhotoPairs" :key="'site_' + pair.PairIndex" class="comparison-pair-card">
                                                <div class="pair-header">
                                                    <span>對照組 #{{ pair.PairIndex }}</span>
                                                    <span class="text-muted small">點擊照片可放大全螢幕檢視</span>
                                                </div>
                                                <div class="pair-grid">
                                                    <!-- 改善前 -->
                                                    <div class="photo-column">
                                                        <div class="photo-column-header">
                                                            <span class="badge-before"><i class="fas fa-clock"></i> 改善前 (查核現場)</span>
                                                            <small class="text-muted text-truncate" style="max-width: 140px;">{{ pair.BeforeFileName }}</small>
                                                        </div>
                                                        <div v-if="pair.BeforeExists" class="photo-preview-wrap" v-on:click="openLightbox(pair.BeforeUrl, '改善前現場照片 #' + pair.PairIndex)">
                                                            <img :src="pair.BeforeUrl" :alt="'改善前現場照片 ' + pair.PairIndex" />
                                                            <div class="photo-zoom-overlay"><i class="fas fa-search-plus"></i></div>
                                                        </div>
                                                        <div v-else class="photo-empty-placeholder">
                                                            <i class="fas fa-image"></i>
                                                            <span>無查核照片</span>
                                                        </div>
                                                    </div>

                                                    <!-- 改善後 -->
                                                    <div class="photo-column">
                                                        <div class="photo-column-header">
                                                            <span class="badge-after"><i class="fas fa-check-circle"></i> 改善後成果</span>
                                                            <small class="text-muted text-truncate" style="max-width: 140px;">{{ pair.AfterFileName || '待上傳' }}</small>
                                                        </div>
                                                        <div v-if="pair.AfterExists" class="photo-preview-wrap" v-on:click="openLightbox(pair.AfterUrl, '改善後成果照片 #' + pair.PairIndex)">
                                                            <img :src="pair.AfterUrl" :alt="'改善後成果照片 ' + pair.PairIndex" />
                                                            <div class="photo-zoom-overlay"><i class="fas fa-search-plus"></i></div>
                                                        </div>
                                                        <div v-else class="photo-empty-placeholder">
                                                            <i class="fas fa-clock"></i>
                                                            <span>待權責單位回報改善照片</span>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                        <div v-else class="text-muted small py-3 bg-light rounded text-center border">
                                            此案件無疑似髒污點現場照片紀錄
                                        </div>
                                    </div>

                                    <!-- B. 佐證照片組 -->
                                    <div>
                                        <h6 class="font-weight-bold text-info d-flex align-items-center gap-2 mb-3">
                                            <i class="fas fa-clipboard-check"></i> 佐證照片對照 ({{ (detail.EvidencePhotoPairs || []).length }} 組)
                                        </h6>

                                        <div v-if="(detail.EvidencePhotoPairs || []).length > 0">
                                            <div v-for="pair in detail.EvidencePhotoPairs" :key="'evi_' + pair.PairIndex" class="comparison-pair-card">
                                                <div class="pair-header">
                                                    <span>佐證組 #{{ pair.PairIndex }}</span>
                                                    <span class="text-muted small">點擊照片可放大全螢幕檢視</span>
                                                </div>
                                                <div class="pair-grid">
                                                    <!-- 改善前佐證 -->
                                                    <div class="photo-column">
                                                        <div class="photo-column-header">
                                                            <span class="badge-before"><i class="fas fa-clock"></i> 查核佐證</span>
                                                            <small class="text-muted text-truncate" style="max-width: 140px;">{{ pair.BeforeFileName }}</small>
                                                        </div>
                                                        <div v-if="pair.BeforeExists" class="photo-preview-wrap" v-on:click="openLightbox(pair.BeforeUrl, '查核佐證照片 #' + pair.PairIndex)">
                                                            <img :src="pair.BeforeUrl" :alt="'查核佐證照片 ' + pair.PairIndex" />
                                                            <div class="photo-zoom-overlay"><i class="fas fa-search-plus"></i></div>
                                                        </div>
                                                        <div v-else class="photo-empty-placeholder">
                                                            <i class="fas fa-image"></i>
                                                            <span>無佐證照片</span>
                                                        </div>
                                                    </div>

                                                    <!-- 改善後佐證 -->
                                                    <div class="photo-column">
                                                        <div class="photo-column-header">
                                                            <span class="badge-after"><i class="fas fa-check-circle"></i> 改善後佐證</span>
                                                            <small class="text-muted text-truncate" style="max-width: 140px;">{{ pair.AfterFileName || '待上傳' }}</small>
                                                        </div>
                                                        <div v-if="pair.AfterExists" class="photo-preview-wrap" v-on:click="openLightbox(pair.AfterUrl, '改善後佐證照片 #' + pair.PairIndex)">
                                                            <img :src="pair.AfterUrl" :alt="'改善後佐證照片 ' + pair.PairIndex" />
                                                            <div class="photo-zoom-overlay"><i class="fas fa-search-plus"></i></div>
                                                        </div>
                                                        <div v-else class="photo-empty-placeholder">
                                                            <i class="fas fa-clock"></i>
                                                            <span>待權責單位回報改善佐證</span>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                        <div v-else class="text-muted small py-3 bg-light rounded text-center border">
                                            此案件無佐證照片紀錄
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- 右側：GIS 地圖與快捷操作 (Col-lg-5, Sticky) -->
                        <div class="col-12 col-lg-5">
                            <div class="sticky-sidebar">
                                <!-- 卡片 4：現場地理位置 (Leaflet Map) -->
                                <div class="card-modern">
                                    <div class="card-modern-header">
                                        <h2 class="card-modern-title">
                                            <i class="fas fa-map-marked-alt text-danger"></i>
                                            <span>現場地理位置</span>
                                        </h2>
                                        <!-- 地圖控制按鈕 (Header 右側配置，零遮擋圖層選單) -->
                                        <div class="d-flex align-items-center gap-1 no-print">
                                            <button type="button" class="btn btn-outline-secondary btn-sm" v-on:click="resetMapView" title="重設地圖全景">
                                                <i class="fas fa-crosshairs"></i> 全景
                                            </button>
                                            <button type="button" class="btn btn-outline-primary btn-sm" v-on:click="openGoogleMaps" title="以 Google 地圖開啟並導航">
                                                <i class="fas fa-external-link-alt"></i> 導航
                                            </button>
                                        </div>
                                    </div>
                                    <div class="card-modern-body p-2">
                                        <!-- 地圖容器 -->
                                        <div id="map"></div>

                                        <!-- 坐標晶片數值 -->
                                        <div class="mt-3 px-2">
                                            <div class="row no-gutters">
                                                <div class="col-12 mb-2">
                                                    <div class="p-2 bg-light rounded border">
                                                        <div class="small font-weight-bold text-danger">
                                                            <i class="fas fa-map-pin mr-1"></i> 通報點 1 (起點 / 髒污主點)
                                                        </div>
                                                        <div class="d-flex justify-content-between small text-muted mt-1">
                                                            <span>TWD97: X={{ detail.S_UTME ? detail.S_UTME.toFixed(0) : '0' }}, Y={{ detail.S_UTMN ? detail.S_UTMN.toFixed(0) : '0' }}</span>
                                                            <span v-if="detail.Lat > 0">WGS84: {{ detail.Lat.toFixed(5) }}, {{ detail.Lon.toFixed(5) }}</span>
                                                        </div>
                                                    </div>
                                                </div>

                                                <div class="col-12" v-if="detail.S_UTME1 > 0 && detail.S_UTMN1 > 0">
                                                    <div class="p-2 bg-light rounded border">
                                                        <div class="small font-weight-bold text-warning">
                                                            <i class="fas fa-map-pin mr-1"></i> 通報點 2 (終點 / 延伸點)
                                                        </div>
                                                        <div class="d-flex justify-content-between small text-muted mt-1">
                                                            <span>TWD97: X={{ detail.S_UTME1.toFixed(0) }}, Y={{ detail.S_UTMN1.toFixed(0) }}</span>
                                                            <span v-if="detail.Lat1 > 0">WGS84: {{ detail.Lat1.toFixed(5) }}, {{ detail.Lon1.toFixed(5) }}</span>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <!-- 卡片 5：快捷動作與列印設定 (Screen Only) -->
                                <div class="card-modern no-print">
                                    <div class="card-modern-header">
                                        <h2 class="card-modern-title">
                                            <i class="fas fa-bolt text-warning"></i>
                                            <span>快捷操作</span>
                                        </h2>
                                    </div>
                                    <div class="card-modern-body">
                                        <div class="d-flex flex-column gap-2">
                                            <button type="button" class="btn btn-outline-dark font-weight-bold w-100 mb-2 py-2" v-on:click="copyCaseId">
                                                <i class="fas fa-copy mr-1"></i> 複製通報案號 ({{ detail.ShowId }})
                                            </button>

                                            <button type="button" class="btn btn-outline-primary font-weight-bold w-100 mb-2 py-2" v-on:click="printReport">
                                                <i class="fas fa-print mr-1"></i> 列印完整報告單
                                            </button>

                                            <button type="button" class="btn btn-outline-secondary font-weight-bold w-100 py-2" v-on:click="goBack">
                                                <i class="fas fa-list mr-1"></i> 返回通報案件清單
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </main>

            <!-- 4. 點擊照片放大燈箱 (Lightbox Modal) -->
            <div v-if="lightbox.visible" class="lightbox-modal" v-on:click.self="closeLightbox">
                <div class="lightbox-content">
                    <button type="button" class="lightbox-close" v-on:click="closeLightbox" title="關閉">&times;</button>
                    <img :src="lightbox.url" :alt="lightbox.title" />
                    <div class="text-white mt-2 small font-weight-bold">{{ lightbox.title }}</div>
                </div>
            </div>
        </div>
    </form>

    <!-- 本地核心 JS 依賴 -->
    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>
    <script src="../Scripts/leaflet/leaflet.js"></script>

    <script>
        (function () {
            const { createApp, ref, reactive, computed, onMounted, nextTick } = Vue;

            createApp({
                setup() {
                    const loading = ref(true);
                    const errorMessage = ref('');
                    const printTime = ref('');

                    const detail = reactive({
                        DirtyId: '',
                        ShowId: '',
                        Comm: '',
                        Kind: '',
                        KindName: '',
                        ReportDate: '',
                        ReportUser: '',
                        ReportUserName: '',
                        SetComDate: '',
                        S_User: '',
                        S_UserName: '',
                        S_ComName: '',
                        G_Com: '',
                        G_ComName: '',
                        ImproveDate: '',
                        G_User: '',
                        G_UserName: '',
                        G_Memo: '',
                        G_Back: 'N',
                        StatusCode: 1,
                        StatusText: '暫存未通報',
                        StatusBadgeClass: 'badge-secondary',
                        S_UTME: 0,
                        S_UTMN: 0,
                        S_UTME1: 0,
                        S_UTMN1: 0,
                        Lat: 0,
                        Lon: 0,
                        Lat1: 0,
                        Lon1: 0,
                        SitePhotoPairs: [],
                        EvidencePhotoPairs: []
                    });

                    // 燈箱狀態
                    const lightbox = reactive({
                        visible: false,
                        url: '',
                        title: ''
                    });

                    // Leaflet 實例 (嚴格非響應式原生變數)
                    let leafletMap = null;
                    let markersGroup = null;

                    // 取得 URL 查詢參數
                    const getUrlParam = (param) => {
                        const urlParams = new URLSearchParams(window.location.search);
                        return urlParams.get(param) || '';
                    };

                    // 計算 Stepper 完成百分比
                    const stepperProgress = computed(() => {
                        if (detail.StatusCode === 3) return 100;
                        if (detail.StatusCode === 2) return 50;
                        return 0;
                    });

                    // 計算 Stepper 狀態樣式
                    const getStepClass = (step) => {
                        if (detail.StatusCode > step) return 'completed';
                        if (detail.StatusCode === step) return 'active';
                        return '';
                    };

                    // 載入案件詳情
                    const loadDetail = () => {
                        const dirtyId = getUrlParam('id');
                        if (!dirtyId) {
                            loading.value = false;
                            errorMessage.value = '未指定通報案號參數 (?id=)';
                            return;
                        }

                        loading.value = true;
                        errorMessage.value = '';

                        axios.get('DirtyDetail.aspx', {
                            params: {
                                action: 'getdetail',
                                id: dirtyId,
                                t: new Date().getTime()
                            }
                        })
                        .then(res => {
                            loading.value = false;
                            if (res.data && res.data.Success) {
                                Object.assign(detail, res.data.Data);
                                nextTick(() => {
                                    initMap();
                                });
                            } else {
                                errorMessage.value = (res.data && res.data.Message) || '查無案件詳細紀錄';
                            }
                        })
                        .catch(err => {
                            loading.value = false;
                            errorMessage.value = '伺服器網路連線異常：' + (err.message || err);
                        });
                    };

                    // 初始化 Leaflet 地圖
                    const initMap = () => {
                        const mapDiv = document.getElementById('map');
                        if (!mapDiv) return;

                        // 預設以新北市中心點座標
                        let centerLat = 25.0123;
                        let centerLon = 121.4657;
                        let defaultZoom = 13;

                        if (detail.Lat > 0 && detail.Lon > 0) {
                            centerLat = detail.Lat;
                            centerLon = detail.Lon;
                            defaultZoom = 16;
                        }

                        if (!leafletMap) {
                            leafletMap = L.map('map', {
                                center: [centerLat, centerLon],
                                zoom: defaultZoom,
                                zoomControl: true
                            });

                            // 1. 底圖圖層宣告 (臺灣通用電子地圖 EMAP、正射影像圖、OSM)
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
                            L.control.layers(baseMaps, null, { position: 'topright' }).addTo(leafletMap);

                            markersGroup = L.layerGroup().addTo(leafletMap);
                        } else {
                            leafletMap.setView([centerLat, centerLon], defaultZoom);
                            markersGroup.clearLayers();
                        }

                        // 標記 Pin 1 (通報點 1)
                        if (detail.Lat > 0 && detail.Lon > 0) {
                            const icon1 = L.divIcon({
                                className: 'custom-map-marker',
                                html: '<div class="marker-pin"><span class="marker-num">1</span></div>',
                                iconSize: [32, 32],
                                iconAnchor: [16, 32],
                                popupAnchor: [0, -32]
                            });

                            const popupContent1 = `
                                <div style="min-width: 180px; font-size: 13px;">
                                    <div style="font-weight: 700; color: #b91c1c; margin-bottom: 4px;">通報點 1 (主污染點)</div>
                                    <div><strong>案號：</strong>${detail.ShowId}</div>
                                    <div><strong>類別：</strong>${detail.KindName}</div>
                                    <div><strong>WGS84：</strong>${detail.Lat.toFixed(5)}, ${detail.Lon.toFixed(5)}</div>
                                </div>
                            `;

                            L.marker([detail.Lat, detail.Lon], { icon: icon1 })
                                .addTo(markersGroup)
                                .bindPopup(popupContent1)
                                .openPopup();
                        }

                        // 標記 Pin 2 (通報點 2，若有)
                        if (detail.Lat1 > 0 && detail.Lon1 > 0) {
                            const icon2 = L.divIcon({
                                className: 'custom-map-marker',
                                html: '<div class="marker-pin marker-end"><span class="marker-num">2</span></div>',
                                iconSize: [32, 32],
                                iconAnchor: [16, 32],
                                popupAnchor: [0, -32]
                            });

                            const popupContent2 = `
                                <div style="min-width: 180px; font-size: 13px;">
                                    <div style="font-weight: 700; color: #b45309; margin-bottom: 4px;">通報點 2 (延伸點)</div>
                                    <div><strong>案號：</strong>${detail.ShowId}</div>
                                    <div><strong>WGS84：</strong>${detail.Lat1.toFixed(5)}, ${detail.Lon1.toFixed(5)}</div>
                                </div>
                            `;

                            L.marker([detail.Lat1, detail.Lon1], { icon: icon2 })
                                .addTo(markersGroup)
                                .bindPopup(popupContent2);

                            // 若有兩個點位，連線示意
                            L.polyline([[detail.Lat, detail.Lon], [detail.Lat1, detail.Lon1]], {
                                color: '#ef4444',
                                weight: 3,
                                dashArray: '5, 8'
                            }).addTo(markersGroup);

                            // 自動縮放全覽這兩點
                            leafletMap.fitBounds([[detail.Lat, detail.Lon], [detail.Lat1, detail.Lon1]], {
                                padding: [40, 40]
                            });
                        }
                    };

                    // 重設地圖全景
                    const resetMapView = () => {
                        if (!leafletMap) return;
                        if (detail.Lat > 0 && detail.Lon > 0) {
                            if (detail.Lat1 > 0 && detail.Lon1 > 0) {
                                leafletMap.fitBounds([[detail.Lat, detail.Lon], [detail.Lat1, detail.Lon1]], { padding: [40, 40] });
                            } else {
                                leafletMap.setView([detail.Lat, detail.Lon], 16);
                            }
                        }
                    };

                    // 開啟 Google 地圖導航
                    const openGoogleMaps = () => {
                        if (detail.Lat > 0 && detail.Lon > 0) {
                            const gmapUrl = 'https://www.google.com/maps/dir/?api=1&destination=' + detail.Lat + ',' + detail.Lon;
                            window.open(gmapUrl, '_blank');
                        } else {
                            alert('本案件尚無有效之 GPS 坐標資料');
                        }
                    };

                    // 複製通報案號
                    const copyCaseId = () => {
                        if (!detail.ShowId) return;
                        if (navigator.clipboard) {
                            navigator.clipboard.writeText(detail.ShowId).then(() => {
                                alert('通報案號「' + detail.ShowId + '」已成功複製到剪貼簿！');
                            });
                        } else {
                            alert('案號：' + detail.ShowId);
                        }
                    };

                    // 燈箱開啟與關閉
                    const openLightbox = (url, title) => {
                        if (!url) return;
                        lightbox.url = url;
                        lightbox.title = title || '';
                        lightbox.visible = true;
                    };

                    const closeLightbox = () => {
                        lightbox.visible = false;
                        lightbox.url = '';
                        lightbox.title = '';
                    };

                    // 列印報告單
                    const printReport = () => {
                        const now = new Date();
                        printTime.value = now.getFullYear() + '-' +
                            String(now.getMonth() + 1).padStart(2, '0') + '-' +
                            String(now.getDate()).padStart(2, '0') + ' ' +
                            String(now.getHours()).padStart(2, '0') + ':' +
                            String(now.getMinutes()).padStart(2, '0');
                        window.print();
                    };

                    // 返回上一頁或清單
                    const goBack = () => {
                        const parmode = getUrlParam('parmode');
                        if (parmode) {
                            window.location.href = 'Dirty_List.aspx?mode=' + encodeURIComponent(parmode);
                        } else if (document.referrer && document.referrer.indexOf('Dirty_List.aspx') >= 0) {
                            window.location.href = document.referrer;
                        } else {
                            window.location.href = 'Dirty_List.aspx';
                        }
                    };

                    onMounted(() => {
                        loadDetail();
                    });

                    return {
                        loading,
                        errorMessage,
                        detail,
                        lightbox,
                        printTime,
                        stepperProgress,
                        getStepClass,
                        loadDetail,
                        resetMapView,
                        openGoogleMaps,
                        copyCaseId,
                        openLightbox,
                        closeLightbox,
                        printReport,
                        goBack
                    };
                }
            }).mount('#detailApp');
        })();
    </script>
</body>
</html>