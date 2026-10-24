<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Check_Step1.aspx.cs" Inherits="NTPC_FEC.Manager.Check_Step1" %>

<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定溢散源管理審查平台 - 固定污染源現場查核紀錄審查</title>

    <!-- 專屬 Favicon -->
    <link rel="shortcut icon" href="../favicon.ico" type="image/x-icon" />

    <!-- 本地化樣式依賴 -->
    <link rel="stylesheet" href="../Content/bootstrap.min.css" />
    <link rel="stylesheet" href="../Content/fontawesome/css/all.min.css" />
    <link rel="stylesheet" href="../Content/leaflet/leaflet.css" />

    <style>
        :root {
            --brand-primary: #0099e5;     /* 新北天空青藍 (Navbar/強調) */
            --brand-blue: #0284c7;        /* 科技藍 (按鈕/選中) */
            --brand-dark-blue: #0b1f7d;   /* 海軍深藍 (標題/Tag) */
            --brand-navy: #0f172a;        /* 標題文字主色 */
            --bg-canvas: #f1f5f9;         /* 頁面灰底 */
            --surface: #ffffff;           /* 卡片純白底色 */
            --border-color: #e2e8f0;      /* 邊框線條 */
            --text-main: #0f172a;         /* 內文主要文字 */
            --text-muted: #64748b;        /* 次要說明文字 */
            --success-color: #10b981;     /* 合格綠 */
            --warning-color: #f59e0b;     /* 警告橙 */
            --danger-color: #ef4444;      /* 違規紅 */
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

        /* 頂部品牌導覽列 */
        .top-navbar {
            background: linear-gradient(135deg, #0099e5 0%, #0284c7 100%);
            color: #ffffff;
            height: 60px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 0 20px;
            box-shadow: 0 2px 10px rgba(0, 153, 229, 0.25);
            position: sticky;
            top: 0;
            z-index: 1020;
        }

        .navbar-brand-title {
            font-size: 1.12rem;
            font-weight: 700;
            display: flex;
            align-items: center;
            gap: 10px;
            color: #ffffff;
            text-decoration: none;
            letter-spacing: 0.5px;
        }

        .navbar-brand-title:hover {
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
                top: 76px;
                max-height: calc(100vh - 92px);
                overflow-y: auto;
                padding-right: 4px;
            }
        }

        /* 審查階段時間軸 (Status Stepper) */
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
            text-align: center;
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

        /* 現場地圖 */
        #map {
            width: 100%;
            height: 260px;
            border-radius: 8px;
            z-index: 10;
            transition: height 0.3s ease;
        }
        #map.map-collapsed {
            height: 100px !important;
        }

        /* 資訊清單表格 (Key-Value) */
        .info-table {
            width: 100%;
            margin-bottom: 0;
            font-size: 0.92rem;
        }
        .info-table th {
            width: 32%;
            background-color: #f8fafc;
            color: #475569;
            font-weight: 600;
            border-top: 1px solid var(--border-color);
            padding: 8px 10px;
            vertical-align: middle;
        }
        .info-table td {
            color: #0f172a;
            border-top: 1px solid var(--border-color);
            padding: 8px 10px;
            vertical-align: middle;
        }

        /* 缺失評等統計卡片 */
        .score-hero-card {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 16px 20px;
            border-radius: 10px;
            margin-bottom: 16px;
        }
        .score-hero-card.qualified {
            background: #ecfdf5;
            border: 1px solid #a7f3d0;
            color: #065f46;
        }
        .score-hero-card.minor {
            background: #fffbeb;
            border: 1px solid #fde68a;
            color: #92400e;
        }
        .score-hero-card.major {
            background: #fef2f2;
            border: 1px solid #fecaca;
            color: #991b1b;
        }
        .score-big-num {
            font-size: 2.2rem;
            font-weight: 800;
            line-height: 1;
        }

        /* 設施違規清單項目卡片 */
        .sec-item-card {
            border: 1px solid var(--border-color);
            border-radius: 8px;
            margin-bottom: 12px;
            overflow: hidden;
            background: #ffffff;
            transition: box-shadow 0.2s;
        }
        .sec-item-card:hover {
            box-shadow: 0 2px 8px rgba(0,0,0,0.06);
        }
        .sec-item-header {
            padding: 10px 14px;
            background: #f8fafc;
            display: flex;
            align-items: center;
            justify-content: space-between;
            border-bottom: 1px solid var(--border-color);
        }
        .sec-item-header.has-violation {
            background: #fff1f2;
            border-bottom: 1px solid #fecdd3;
        }
        .sec-item-body {
            padding: 12px 14px;
        }

        /* 照片畫廊 Grid */
        .gallery-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
            gap: 12px;
        }
        .gallery-card {
            border: 1px solid var(--border-color);
            border-radius: 8px;
            overflow: hidden;
            background: #ffffff;
            box-shadow: 0 1px 3px rgba(0,0,0,0.04);
            display: flex;
            flex-direction: column;
        }
        .gallery-img-wrap {
            position: relative;
            width: 100%;
            height: 140px;
            background: #e2e8f0;
            cursor: pointer;
            overflow: hidden;
        }
        .gallery-img-wrap img {
            width: 100%;
            height: 100%;
            object-fit: cover;
            transition: transform 0.3s ease;
        }
        .gallery-img-wrap:hover img {
            transform: scale(1.05);
        }
        .gallery-caption {
            padding: 8px 10px;
            font-size: 0.85rem;
            flex: 1;
        }
        .gallery-title {
            font-weight: 700;
            color: var(--brand-navy);
            margin-bottom: 2px;
        }
        .gallery-memo {
            color: var(--text-muted);
            font-size: 0.78rem;
            line-height: 1.3;
        }

        /* 簽名板展示卡 */
        .signature-card {
            border: 1px solid var(--border-color);
            border-radius: 8px;
            padding: 10px;
            background: #ffffff;
            text-align: center;
        }
        .signature-img {
            max-width: 100%;
            height: 90px;
            object-fit: contain;
            border: 1px dashed #cbd5e1;
            border-radius: 6px;
            background: #fafafa;
        }

        /* 審核操作面板 (Sticky Action Box) */
        .review-action-box {
            background: #f8fafc;
            border: 2px solid #bae6fd;
            border-radius: 10px;
            padding: 16px;
            margin-bottom: 16px;
        }
        .review-decision-group {
            display: flex;
            gap: 12px;
            margin-bottom: 12px;
        }
        .review-decision-btn {
            flex: 1;
            border: 2px solid #cbd5e1;
            background: #ffffff;
            padding: 10px;
            border-radius: 8px;
            text-align: center;
            font-weight: 700;
            cursor: pointer;
            transition: all 0.2s;
            color: #475569;
        }
        .review-decision-btn.active-pass {
            border-color: #10b981;
            background: #ecfdf5;
            color: #065f46;
            box-shadow: 0 0 0 3px rgba(16, 185, 129, 0.2);
        }
        .review-decision-btn.active-fail {
            border-color: #ef4444;
            background: #fef2f2;
            color: #991b1b;
            box-shadow: 0 0 0 3px rgba(239, 68, 68, 0.2);
        }
        .quick-memo-chips {
            display: flex;
            flex-wrap: wrap;
            gap: 6px;
            margin-bottom: 10px;
        }
        .quick-memo-chip {
            background: #e2e8f0;
            border: none;
            border-radius: 6px;
            padding: 4px 10px;
            font-size: 0.78rem;
            color: #334155;
            cursor: pointer;
            transition: background 0.15s;
        }
        .quick-memo-chip:hover {
            background: #cbd5e1;
        }

        /* 歷史審核時間線 */
        .timeline-container {
            position: relative;
            padding-left: 20px;
        }
        .timeline-container::before {
            content: '';
            position: absolute;
            left: 7px;
            top: 6px;
            bottom: 6px;
            width: 2px;
            background: #cbd5e1;
        }
        .timeline-item {
            position: relative;
            margin-bottom: 14px;
        }
        .timeline-dot {
            position: absolute;
            left: -20px;
            top: 4px;
            width: 14px;
            height: 14px;
            border-radius: 50%;
            background: var(--brand-blue);
            border: 2px solid #ffffff;
            box-shadow: 0 0 0 2px #cbd5e1;
        }
        .timeline-dot.pass { background: #10b981; }
        .timeline-dot.fail { background: #ef4444; }

        /* 燈箱 Modal (Lightbox) */
        .lightbox-modal {
            position: fixed;
            top: 0; left: 0; right: 0; bottom: 0;
            background: rgba(15, 23, 42, 0.92);
            z-index: 2050;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .lightbox-content-wrap {
            max-width: 90vw;
            max-height: 80vh;
            display: flex;
            align-items: center;
            justify-content: center;
            position: relative;
        }
        .lightbox-img {
            max-width: 100%;
            max-height: 80vh;
            object-fit: contain;
            border-radius: 6px;
            box-shadow: 0 8px 30px rgba(0,0,0,0.5);
            transition: transform 0.2s ease;
        }
        .lightbox-toolbar {
            margin-top: 14px;
            display: flex;
            gap: 12px;
            align-items: center;
        }

        /* 手機底部懸浮列 */
        @media screen and (max-width: 991px) {
            body { padding-bottom: 76px; }
            .mobile-bottom-bar {
                display: flex;
                position: fixed;
                bottom: 0; left: 0; right: 0;
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

        /* 列印樣式規範 */
        @media print {
            .no-print, .top-navbar, .mobile-bottom-bar, .sticky-sidebar, .review-action-box {
                display: none !important;
            }
            body {
                background: #ffffff;
                color: #000000;
            }
            .container-fluid-custom {
                max-width: 100%;
                padding: 0;
            }
            .card-modern {
                box-shadow: none;
                border: 1px solid #000000;
                page-break-inside: avoid;
            }
        }
    </style>
</head>
<body>
    <div id="app" v-cloak>
        <!-- 1. 置頂深青藍漸層導覽列 (Sticky Top Navbar) -->
        <header class="top-navbar no-print">
            <div class="d-flex align-items-center">
                <a :href="'managerList.aspx?INV_State=' + mode" class="nav-btn mr-2" title="返回審查清單">
                    <i class="fas fa-arrow-left"></i>
                    <span class="d-none d-sm-inline">返回清單</span>
                </a>
                <span class="navbar-brand-title">
                    <i class="fas fa-clipboard-check text-white"></i>
                    <span>固定污染源現場查核紀錄審查</span>
                </span>
                <span v-if="facInfo.C_NO" class="badge badge-light text-dark font-weight-bold ml-2 d-none d-md-inline" style="font-size: 0.85rem;">
                    管編：{{ facInfo.C_NO }}
                </span>
                <span v-if="recordData.INV_NO" class="badge badge-warning text-dark font-weight-bold ml-2" style="font-size: 0.85rem;">
                    案號 #{{ recordData.INV_NO }}
                </span>
            </div>

            <div class="d-flex align-items-center gap-2">
                <!-- 審核階段膠囊 -->
                <span class="badge badge-light text-primary font-weight-bold mr-2 px-2 py-1" style="font-size: 0.9rem;">
                    {{ currentStageTitle }}
                </span>

                <!-- 一鍵捲動至審核區 (手機/小螢幕特別實用) -->
                <button v-if="canReview" type="button" class="nav-btn bg-white text-dark shadow-sm mr-2" v-on:click="scrollToReview">
                    <i class="fas fa-edit text-primary"></i>
                    <span class="d-none d-md-inline">快速審核</span>
                </button>

                <!-- 列印按鈕 -->
                <button type="button" class="nav-btn bg-white text-dark shadow-sm" v-on:click="printCase">
                    <i class="fas fa-print"></i>
                    <span class="d-none d-md-inline">列印案件</span>
                </button>
            </div>
        </header>

        <!-- 2. 主工作作業區 -->
        <main class="container-fluid-custom">
            <!-- 載入中狀態提示 -->
            <div v-if="loading" class="text-center py-5">
                <div class="spinner-border text-primary" role="status" style="width: 3rem; height: 3rem;">
                    <span class="sr-only">資料載入中...</span>
                </div>
                <h5 class="mt-3 text-muted">正在載入查核紀錄與審查歷程，請稍候...</h5>
            </div>

            <div v-else>
                <!-- A. 通報/審查階段進度時間軸 (Status Stepper) -->
                <div class="stepper-container shadow-sm no-print">
                    <div class="stepper-line">
                        <div class="stepper-line-fill" :style="{ width: stepperProgress + '%' }"></div>
                    </div>

                    <!-- 步驟 1: 現場查核立案 -->
                    <div class="step-item" :class="getStepClass(1)">
                        <div class="step-circle">
                            <i v-if="numericStepCode > 1" class="fas fa-check"></i>
                            <span v-else>1</span>
                        </div>
                        <div class="step-title">現場查核立案</div>
                        <div class="step-time">{{ recordData.INV_DATE || '未填寫' }}</div>
                    </div>

                    <!-- 步驟 2: 主管初審 -->
                    <div class="step-item" :class="getStepClass(2)">
                        <div class="step-circle">
                            <i v-if="numericStepCode > 2" class="fas fa-check"></i>
                            <span v-else>2</span>
                        </div>
                        <div class="step-title">初審核定 (A00)</div>
                        <div class="step-time">{{ getStepAuditInfo('A00') }}</div>
                    </div>

                    <!-- 步驟 3: 主管複審 -->
                    <div class="step-item" :class="getStepClass(3)">
                        <div class="step-circle">
                            <i v-if="numericStepCode > 3" class="fas fa-check"></i>
                            <span v-else>3</span>
                        </div>
                        <div class="step-title">複審核定 (A01)</div>
                        <div class="step-time">{{ getStepAuditInfo('A01') }}</div>
                    </div>

                    <!-- 步驟 4: 三審核備 / 結案 -->
                    <div class="step-item" :class="getStepClass(4)">
                        <div class="step-circle">
                            <i v-if="numericStepCode === 4" class="fas fa-check"></i>
                            <span v-else>4</span>
                        </div>
                        <div class="step-title">三審備查 (A02) / 結案</div>
                        <div class="step-time">{{ getStepAuditInfo('A02') }}</div>
                    </div>
                </div>

                <!-- B. 雙欄主版面 (左欄 40%，右欄 60%) -->
                <div class="row">
                    <!-- 左欄 (40% 寬度，固頂側邊欄) -->
                    <div class="col-12 col-xl-5">
                        <div class="sticky-sidebar">
                            <!-- ⚡ 審核作業面板 (核心功能) -->
                            <div id="reviewPanel" class="card-modern border-primary shadow-sm" style="border-width: 2px;">
                                <div class="card-modern-header bg-light">
                                    <h3 class="card-modern-title text-primary">
                                        <i class="fas fa-gavel text-primary"></i>
                                        <span>【{{ currentStageTitle }}】審查作業</span>
                                    </h3>
                                    <span v-if="canReview" class="badge badge-success px-2 py-1">可執行審查</span>
                                    <span v-else class="badge badge-secondary px-2 py-1">檢視模式</span>
                                </div>
                                <div class="card-modern-body">
                                    <div v-if="canReview">
                                        <label class="font-weight-bold text-dark d-block mb-2">審查結果決定：</label>
                                        <div class="review-decision-group">
                                            <div class="review-decision-btn" :class="{ 'active-pass': reviewForm.chkResult === 'PASS' }"
                                                 v-on:click="reviewForm.chkResult = 'PASS'">
                                                <i class="fas fa-check-circle mr-1 text-success"></i> 審查通過 (核定)
                                            </div>
                                            <div class="review-decision-btn" :class="{ 'active-fail': reviewForm.chkResult === 'FAIL' }"
                                                 v-on:click="reviewForm.chkResult = 'FAIL'">
                                                <i class="fas fa-times-circle mr-1 text-danger"></i> 退回修正 (退件)
                                            </div>
                                        </div>

                                        <label class="font-weight-bold text-dark d-block mb-1">常用審查意見：</label>
                                        <div class="quick-memo-chips">
                                            <button type="button" class="quick-memo-chip" v-on:click="applyQuickMemo('審查通過，核予備查。')">核予備查</button>
                                            <button type="button" class="quick-memo-chip" v-on:click="applyQuickMemo('現場查核無缺失，防制設施符合規定。')">符合規定</button>
                                            <button type="button" class="quick-memo-chip" v-on:click="applyQuickMemo('缺失點數無誤，請公私場所依限完成改善。')">缺失依限改善</button>
                                            <button type="button" class="quick-memo-chip" v-on:click="applyQuickMemo('現場佐證照片模糊，請補正清晰照片後重送。')">照片補正</button>
                                            <button type="button" class="quick-memo-chip" v-on:click="applyQuickMemo('部分缺失事項未詳述，退回修正。')">退回修正</button>
                                        </div>

                                        <div class="form-group mb-3">
                                            <label class="font-weight-bold text-dark">審查詳細說明 / 指示：</label>
                                            <textarea class="form-control" rows="3" v-model="reviewForm.chkMemo"
                                                      placeholder="請輸入審查意見或修正指示..."></textarea>
                                        </div>

                                        <button type="button" class="btn btn-primary btn-block font-weight-bold py-2 shadow-sm"
                                                :disabled="submittingReview" v-on:click="confirmSubmitReview">
                                            <i v-if="submittingReview" class="fas fa-spinner fa-spin mr-1"></i>
                                            <i v-else class="fas fa-paper-plane mr-1"></i>
                                            確認送出【{{ currentStageTitle }}】
                                        </button>
                                    </div>
                                    <div v-else class="text-center py-3 text-muted">
                                        <i class="fas fa-info-circle fa-2x text-info mb-2"></i>
                                        <p class="mb-0 font-weight-bold">目前處於唯讀狀態或非本階段待審案件。</p>
                                        <small>當前案件狀態：{{ currentCaseState }} ({{ currentStageTitle }})</small>
                                    </div>
                                </div>
                            </div>

                            <!-- 場所基本資料卡片 -->
                            <div class="card-modern">
                                <div class="card-modern-header">
                                    <h3 class="card-modern-title">
                                        <i class="fas fa-industry text-primary"></i>
                                        <span>場所基本資料</span>
                                    </h3>
                                    <button v-if="facInfo.Lat && facInfo.Lng" type="button" class="btn btn-sm btn-outline-success" v-on:click="openGoogleMaps">
                                        <i class="fas fa-location-arrow mr-1"></i>Google 導航
                                    </button>
                                </div>
                                <div class="card-modern-body p-0">
                                    <table class="table info-table">
                                        <tbody>
                                            <tr>
                                                <th>場所名稱</th>
                                                <td class="font-weight-bold text-primary">{{ facInfo.FAC_NAME }}</td>
                                            </tr>
                                            <tr>
                                                <th>管制編號</th>
                                                <td><span class="badge badge-light border text-dark font-weight-bold">{{ facInfo.C_NO || '無' }}</span></td>
                                            </tr>
                                            <tr>
                                                <th>行業別</th>
                                                <td>{{ facInfo.INDUSTRIAL_Name || '未分類' }}</td>
                                            </tr>
                                            <tr>
                                                <th>工廠地址</th>
                                                <td>{{ facInfo.ADDR || '未填寫' }}</td>
                                            </tr>
                                            <tr>
                                                <th>地號</th>
                                                <td>{{ facInfo.Land_no || '無' }}</td>
                                            </tr>
                                            <tr>
                                                <th>負責人 / 電話</th>
                                                <td>{{ facInfo.BOSS_NAME || '未填寫' }} / {{ facInfo.TEL || '無' }}</td>
                                            </tr>
                                            <tr>
                                                <th>聯絡人</th>
                                                <td>{{ facInfo.Content_Name || '未填寫' }}</td>
                                            </tr>
                                            <tr>
                                                <th>統編 / 工證</th>
                                                <td>{{ facInfo.S_C_ID || '無' }} / {{ facInfo.Lic_NO || '無' }}</td>
                                            </tr>
                                        </tbody>
                                    </table>
                                </div>
                            </div>

                            <!-- 現場智慧地圖 (Leaflet) -->
                            <div class="card-modern">
                                <div class="card-modern-header">
                                    <h3 class="card-modern-title">
                                        <i class="fas fa-map-marked-alt text-success"></i>
                                        <span>工廠現場位置圖</span>
                                    </h3>
                                    <div class="d-flex align-items-center">
                                        <button type="button" class="btn btn-sm btn-outline-secondary mr-1" v-on:click="toggleMapCollapse">
                                            <i :class="isMapCollapsed ? 'fas fa-expand-alt' : 'fas fa-compress-alt'"></i>
                                            <span class="d-none d-sm-inline ml-1">{{ isMapCollapsed ? '展開地圖' : '收合地圖' }}</span>
                                        </button>
                                        <button type="button" class="btn btn-sm btn-outline-primary" v-on:click="resetMapView" title="重設全景">
                                            <i class="fas fa-crosshairs"></i>
                                        </button>
                                    </div>
                                </div>
                                <div class="card-modern-body p-2">
                                    <div id="map" :class="{ 'map-collapsed': isMapCollapsed }"></div>
                                    <div v-if="!facInfo.Lat || !facInfo.Lng" class="text-center py-2 text-muted small">
                                        <i class="fas fa-exclamation-triangle text-warning mr-1"></i>尚未取得精確經緯度座標，地圖已自動置中於新北市。
                                    </div>
                                </div>
                            </div>

                            <!-- 審查歷程時間線卡片 -->
                            <div class="card-modern">
                                <div class="card-modern-header">
                                    <h3 class="card-modern-title">
                                        <i class="fas fa-history text-secondary"></i>
                                        <span>歷次審查軌跡 ({{ checkHistory.length }})</span>
                                    </h3>
                                </div>
                                <div class="card-modern-body">
                                    <div v-if="checkHistory.length === 0" class="text-center py-3 text-muted">
                                        尚無歷史審查紀錄（本次為首次審查）。
                                    </div>
                                    <div v-else class="timeline-container">
                                        <div v-for="(h, idx) in checkHistory" :key="idx" class="timeline-item">
                                            <div class="timeline-dot" :class="{ 'pass': h.Chk_Result === '通過', 'fail': h.Chk_Result === '退件' }"></div>
                                            <div class="d-flex justify-content-between align-items-center mb-1">
                                                <strong class="text-dark">{{ h.State_Name || '審核作業' }}</strong>
                                                <span class="badge" :class="h.Chk_Result === '通過' ? 'badge-success' : 'badge-danger'">{{ h.Chk_Result }}</span>
                                            </div>
                                            <div class="small text-muted mb-1">
                                                審查人：{{ h.Chk_UserName }} | {{ h.Chk_Date }}
                                            </div>
                                            <div class="small p-2 bg-light rounded border text-dark">
                                                {{ h.Chk_Memo || '無特殊意見說明' }}
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- 右欄 (60% 寬度，主查核作業成果區) -->
                    <div class="col-12 col-xl-7">
                        <!-- 查核概況與缺失記點評等 Hero 卡片 -->
                        <div class="card-modern">
                            <div class="card-modern-header">
                                <h3 class="card-modern-title">
                                    <i class="fas fa-clipboard-list text-primary"></i>
                                    <span>現場查核概況與記點評等</span>
                                </h3>
                                <span class="badge badge-info px-2 py-1" style="font-size: 0.85rem;">
                                    查核日期：{{ recordData.INV_DATE || '未填寫' }}
                                </span>
                            </div>
                            <div class="card-modern-body">
                                <!-- 缺失點數狀態看板 -->
                                <div class="score-hero-card" :class="{
                                    'qualified': recordData.LossLevel === 'QUALIFIED',
                                    'minor': recordData.LossLevel === 'MINOR',
                                    'major': recordData.LossLevel === 'MAJOR'
                                }">
                                    <div>
                                        <h5 class="font-weight-bold mb-1">
                                            <span v-if="recordData.LossLevel === 'QUALIFIED'"><i class="fas fa-check-circle mr-1"></i>各項防制設施合格</span>
                                            <span v-else-if="recordData.LossLevel === 'MINOR'"><i class="fas fa-exclamation-circle mr-1"></i>有缺失 (限期改善)</span>
                                            <span v-else><i class="fas fa-times-circle mr-1"></i>重大缺失 (依規定處分)</span>
                                        </h5>
                                        <div class="small font-weight-bold">{{ recordData.LossWarning }}</div>
                                        <div v-if="recordData.TotalLossPoint > 0" class="mt-2 text-danger small font-weight-bold">
                                            <i class="fas fa-calendar-alt mr-1"></i>指定改善期限：{{ recordData.ImproveDeadline }}
                                        </div>
                                    </div>
                                    <div class="text-right">
                                        <div class="small font-weight-bold">缺失點數合計</div>
                                        <div class="score-big-num">{{ recordData.TotalLossPoint }} <small style="font-size: 1rem;">點</small></div>
                                    </div>
                                </div>

                                <!-- 現場查核作業條件 -->
                                <div class="row">
                                    <div class="col-sm-6 mb-2">
                                        <div class="p-2 border rounded bg-light">
                                            <small class="text-muted d-block">當日天氣狀況</small>
                                            <strong><i class="fas fa-cloud-sun text-warning mr-1"></i>{{ recordData.weather || '晴' }}</strong>
                                        </div>
                                    </div>
                                    <div class="col-sm-6 mb-2">
                                        <div class="p-2 border rounded bg-light">
                                            <small class="text-muted d-block">現場操作狀況</small>
                                            <strong><i class="fas fa-cogs text-secondary mr-1"></i>{{ recordData.Work_State || '正常操作中' }}</strong>
                                        </div>
                                    </div>
                                    <div class="col-12" v-if="recordData.Work_Memo && recordData.Work_Memo !== '無'">
                                        <div class="p-2 border rounded bg-light">
                                            <small class="text-muted d-block">操作狀況概述說明</small>
                                            <div>{{ recordData.Work_Memo }}</div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- 九大項防制設施查核詳細紀錄 -->
                        <div class="card-modern">
                            <div class="card-modern-header">
                                <h3 class="card-modern-title">
                                    <i class="fas fa-shield-alt text-info"></i>
                                    <span>九大防制設施詳細查核結果</span>
                                </h3>
                                <div class="d-flex gap-2">
                                    <button type="button" class="btn btn-sm btn-outline-secondary" v-on:click="toggleAllSections">
                                        {{ allSectionsExpanded ? '全部收合' : '全部展開' }}
                                    </button>
                                </div>
                            </div>
                            <div class="card-modern-body">
                                <div v-for="sec in sections" :key="sec.Id" class="sec-item-card">
                                    <div class="sec-item-header" :class="{ 'has-violation': sec.LossPoint > 0 }"
                                         style="cursor: pointer;" v-on:click="toggleSection(sec.Id)">
                                        <div class="d-flex align-items-center">
                                            <i :class="expandedSections[sec.Id] ? 'fas fa-chevron-down mr-2' : 'fas fa-chevron-right mr-2'" style="font-size: 0.8rem;"></i>
                                            <strong :class="sec.LossPoint > 0 ? 'text-danger' : 'text-dark'">{{ sec.Title }}</strong>
                                        </div>
                                        <div>
                                            <span v-if="sec.LossPoint === 0" class="badge badge-success px-2 py-1">
                                                <i class="fas fa-check mr-1"></i>合格 (0 點)
                                            </span>
                                            <span v-else class="badge badge-danger px-2 py-1">
                                                <i class="fas fa-exclamation-triangle mr-1"></i>違規記 {{ sec.LossPoint }} 點
                                            </span>
                                        </div>
                                    </div>

                                    <div v-show="expandedSections[sec.Id]" class="sec-item-body">
                                        <!-- 違規缺失項目 -->
                                        <div v-if="sec.Violations && sec.Violations.length > 0" class="mb-3">
                                            <strong class="text-danger d-block mb-1">
                                                <i class="fas fa-times-circle mr-1"></i>缺失項目與法條依據：
                                            </strong>
                                            <ul class="mb-0 pl-3">
                                                <li v-for="(v, vIdx) in sec.Violations" :key="vIdx" class="text-danger font-weight-bold mb-1">
                                                    {{ v }}
                                                </li>
                                            </ul>
                                        </div>

                                        <!-- 合格或採行設施項目 -->
                                        <div v-if="sec.CompliantItems && sec.CompliantItems.length > 0">
                                            <strong class="text-success d-block mb-1">
                                                <i class="fas fa-check-circle mr-1"></i>現場採行合格措施：
                                            </strong>
                                            <ul class="mb-0 pl-3 text-muted">
                                                <li v-for="(c, cIdx) in sec.CompliantItems" :key="cIdx">
                                                    {{ c }}
                                                </li>
                                            </ul>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- 設備統計與原物料製程面板 -->
                        <div class="card-modern">
                            <div class="card-modern-header">
                                <h3 class="card-modern-title">
                                    <i class="fas fa-tools text-secondary"></i>
                                    <span>設備統計與原物料製程資料 ({{ devSummary.length }} 類)</span>
                                </h3>
                                <button type="button" class="btn btn-sm btn-outline-primary" v-on:click="openDeviceModal">
                                    <i class="fas fa-list-alt mr-1"></i>查看設備與製程明細
                                </button>
                            </div>
                            <div class="card-modern-body">
                                <div v-if="devSummary.length === 0" class="text-muted text-center py-2">
                                    無登錄之特定防制設備統計數據。
                                </div>
                                <div v-else class="d-flex flex-wrap gap-2">
                                    <div v-for="(dev, dIdx) in devSummary" :key="dIdx" class="badge badge-light border p-2 mr-2 mb-2" style="font-size: 0.9rem;">
                                        <span class="text-muted mr-1">[{{ dev.pCode }}]</span>
                                        <strong class="text-dark">{{ dev.Device_Name }}</strong>
                                        <span class="badge badge-primary ml-2">{{ dev.pCount }} 台</span>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- 環境潛勢與其他查核事項 -->
                        <div class="card-modern">
                            <div class="card-modern-header">
                                <h3 class="card-modern-title">
                                    <i class="fas fa-seedling text-success"></i>
                                    <span>環境潛勢調查與其他查核備註</span>
                                </h3>
                            </div>
                            <div class="card-modern-body p-0">
                                <table class="table info-table">
                                    <tbody>
                                        <tr>
                                            <th>環境潛勢項目</th>
                                            <td>{{ recordData.EnvirCheck_Item || '無' }} {{ recordData.EnvirCheck_Other ? '(' + recordData.EnvirCheck_Other + ')' : '' }}</td>
                                        </tr>
                                        <tr>
                                            <th>許可不符項目</th>
                                            <td>
                                                狀態：{{ recordData.OtherChkAns1 || '無' }} / 事項：{{ recordData.OtherChkAns2 || '無' }}
                                            </td>
                                        </tr>
                                        <tr>
                                            <th>其他稽查說明</th>
                                            <td>{{ recordData.OtherChkMemo || '無特殊備註' }}</td>
                                        </tr>
                                    </tbody>
                                </table>
                            </div>
                        </div>

                        <!-- 現場採證照片畫廊 (Photo Gallery) -->
                        <div class="card-modern">
                            <div class="card-modern-header">
                                <h3 class="card-modern-title">
                                    <i class="fas fa-camera text-primary"></i>
                                    <span>現場採證照片畫廊 ({{ photoGallery.length }} 張)</span>
                                </h3>
                                <small class="text-muted">點選任意照片可全螢幕放大檢視</small>
                            </div>
                            <div class="card-modern-body">
                                <div v-if="photoGallery.length === 0" class="text-center py-4 text-muted">
                                    <i class="fas fa-images fa-2x mb-2"></i>
                                    <p>此查核案件無上傳現場佐證照片。</p>
                                </div>
                                <div v-else class="gallery-grid">
                                    <div v-for="(photo, pIdx) in photoGallery" :key="pIdx" class="gallery-card">
                                        <div class="gallery-img-wrap" v-on:click="openLightbox(pIdx)">
                                            <img :src="photo.Url" :alt="photo.Name" loading="lazy" />
                                        </div>
                                        <div class="gallery-caption">
                                            <div class="gallery-title">{{ photo.Name }}</div>
                                            <div v-if="photo.Memo" class="gallery-memo">{{ photo.Memo }}</div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- 現場三方數位簽章確認 (Digital Signatures) -->
                        <div class="card-modern">
                            <div class="card-modern-header">
                                <h3 class="card-modern-title">
                                    <i class="fas fa-signature text-dark"></i>
                                    <span>現場三方數位簽章確認</span>
                                </h3>
                            </div>
                            <div class="card-modern-body">
                                <div class="row">
                                    <div class="col-12 col-md-4 mb-3">
                                        <div class="signature-card">
                                            <small class="font-weight-bold text-dark d-block mb-1">
                                                <i class="fas fa-user-check text-primary mr-1"></i>稽查人員簽名
                                            </small>
                                            <img v-if="signatures.sig1" :src="signatures.sig1" class="signature-img" alt="稽查人員簽名"
                                                 v-on:click="openSingleImage(signatures.sig1, '稽查人員簽名')" />
                                            <div v-else class="text-muted small py-4 bg-light rounded">未簽署</div>
                                        </div>
                                    </div>

                                    <div class="col-12 col-md-4 mb-3">
                                        <div class="signature-card">
                                            <small class="font-weight-bold text-dark d-block mb-1">
                                                <i class="fas fa-user-friends text-info mr-1"></i>會同人員簽名
                                            </small>
                                            <img v-if="signatures.sig2" :src="signatures.sig2" class="signature-img" alt="會同人員簽名"
                                                 v-on:click="openSingleImage(signatures.sig2, '會同人員簽名')" />
                                            <div v-else class="text-muted small py-4 bg-light rounded">未簽署</div>
                                        </div>
                                    </div>

                                    <div class="col-12 col-md-4 mb-3">
                                        <div class="signature-card">
                                            <small class="font-weight-bold text-dark d-block mb-1">
                                                <i class="fas fa-building text-success mr-1"></i>廠方代表簽名
                                            </small>
                                            <img v-if="signatures.sig3" :src="signatures.sig3" class="signature-img" alt="廠方代表簽名"
                                                 v-on:click="openSingleImage(signatures.sig3, '廠方代表簽名')" />
                                            <div v-else class="text-muted small py-4 bg-light rounded">未簽署</div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </main>

        <!-- 3. 手機端常駐浮動動作列 (Sticky Bottom Bar) -->
        <div v-if="canReview" class="mobile-bottom-bar d-lg-none no-print">
            <button type="button" class="btn btn-outline-secondary" v-on:click="scrollToPhotos">
                <i class="fas fa-images mr-1"></i>現場照片
            </button>
            <button type="button" class="btn btn-primary" v-on:click="scrollToReview">
                <i class="fas fa-gavel mr-1"></i>審核作業
            </button>
        </div>

        <!-- 4. 設備與製程明細 Modal -->
        <div v-if="showDevModal" class="lightbox-modal" v-on:click.self="showDevModal = false">
            <div class="card-modern shadow-lg" style="width: 800px; max-width: 95vw; max-height: 85vh; display: flex; flex-direction: column;">
                <div class="card-modern-header bg-light">
                    <h4 class="card-modern-title">
                        <i class="fas fa-boxes text-primary"></i>
                        <span>設備與製程明細清單</span>
                    </h4>
                    <button type="button" class="close" v-on:click="showDevModal = false">&times;</button>
                </div>
                <div class="card-modern-body p-3" style="overflow-y: auto;">
                    <h6 class="font-weight-bold text-dark mb-2">設備清單 ({{ deviceDetails.length }} 筆)</h6>
                    <table class="table table-sm table-bordered text-center mb-4">
                        <thead class="thead-light">
                            <tr>
                                <th>設備編號</th>
                                <th>設備代碼</th>
                                <th>設備名稱</th>
                                <th>存放物料</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr v-if="deviceDetails.length === 0"><td colspan="4" class="text-muted">查無設備明細</td></tr>
                            <tr v-for="(dev, idx) in deviceDetails" :key="idx">
                                <td>{{ dev.Device_NO }}</td>
                                <td>{{ dev.Device_Code }}</td>
                                <td>{{ dev.Device_Name }}</td>
                                <td>{{ dev.Store_substance }}</td>
                            </tr>
                        </tbody>
                    </table>

                    <h6 class="font-weight-bold text-dark mb-2">製程清單 ({{ processDetails.length }} 筆)</h6>
                    <table class="table table-sm table-bordered text-center mb-0">
                        <thead class="thead-light">
                            <tr>
                                <th>製程編號</th>
                                <th>製程名稱</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr v-if="processDetails.length === 0"><td colspan="2" class="text-muted">查無製程明細</td></tr>
                            <tr v-for="(pr, idx) in processDetails" :key="idx">
                                <td>{{ pr.Process_NO }}</td>
                                <td>{{ pr.Process_Name }}</td>
                            </tr>
                        </tbody>
                    </table>
                </div>
                <div class="card-modern-header justify-content-end bg-light">
                    <button type="button" class="btn btn-secondary" v-on:click="showDevModal = false">關閉</button>
                </div>
            </div>
        </div>

        <!-- 5. 全螢幕相片 Lightbox 燈箱 -->
        <div v-if="lightbox.show" class="lightbox-modal" v-on:click.self="closeLightbox">
            <div class="lightbox-content-wrap">
                <img :src="lightbox.currentUrl" :alt="lightbox.title" class="lightbox-img" :style="{ transform: 'rotate(' + lightbox.rotate + 'deg)' }" />
            </div>
            <div class="text-white text-center mt-2 font-weight-bold">{{ lightbox.title }}</div>
            <div class="lightbox-toolbar">
                <button type="button" class="btn btn-sm btn-light" v-on:click="rotateLightbox" title="向右旋轉 90 度">
                    <i class="fas fa-redo"></i> 旋轉
                </button>
                <a :href="lightbox.currentUrl" target="_blank" class="btn btn-sm btn-info" title="新分頁查看原圖">
                    <i class="fas fa-external-link-alt"></i> 原圖
                </a>
                <button type="button" class="btn btn-sm btn-danger font-weight-bold" v-on:click="closeLightbox">
                    <i class="fas fa-times"></i> 關閉 (ESC)
                </button>
            </div>
        </div>
    </div>

    <!-- 本地端核心前端腳本 -->
    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>
    <script src="../Scripts/leaflet/leaflet.js"></script>

    <script>
        const { createApp, markRaw } = Vue;

        createApp({
            data() {
                return {
                    loading: true,
                    mode: 'INV1',
                    facId: '',
                    token: '',
                    invNo: '',
                    currentStageTitle: '初審作業',
                    currentCaseState: '',
                    canReview: false,
                    isReadOnly: false,
                    facInfo: {},
                    recordData: {},
                    sections: [],
                    devSummary: [],
                    photoGallery: [],
                    signatures: {},
                    checkHistory: [],
                    expandedSections: {},
                    allSectionsExpanded: true,
                    isMapCollapsed: false,
                    // 審查表單
                    reviewForm: {
                        chkResult: 'PASS',
                        chkMemo: ''
                    },
                    submittingReview: false,
                    // 設備明細彈窗
                    showDevModal: false,
                    deviceDetails: [],
                    processDetails: [],
                    // Lightbox 燈箱
                    lightbox: {
                        show: false,
                        currentUrl: '',
                        title: '',
                        rotate: 0
                    }
                };
            },
            computed: {
                numericStepCode() {
                    const st = this.currentCaseState;
                    if (st === 'A00') return 2;
                    if (st === 'A01') return 3;
                    if (st === 'A02' || st === 'A03' || st === '結案') return 4;
                    return 1;
                },
                stepperProgress() {
                    if (this.numericStepCode === 4) return 100;
                    if (this.numericStepCode === 3) return 66;
                    if (this.numericStepCode === 2) return 33;
                    return 0;
                }
            },
            mounted() {
                this.parseUrlParams();
                this.loadCaseData();
                window.addEventListener('keydown', this.handleKeyDown);
            },
            beforeUnmount() {
                window.removeEventListener('keydown', this.handleKeyDown);
            },
            methods: {
                parseUrlParams() {
                    const p = new URLSearchParams(window.location.search);
                    this.facId = p.get('fac') || '';
                    this.token = p.get('fac1') || '';
                    this.mode = (p.get('mode') || 'INV1').toUpperCase();
                    this.invNo = p.get('inv') || '';
                },
                loadCaseData() {
                    this.loading = true;
                    axios.get('Check_Step1.aspx', {
                        params: {
                            action: 'get_data',
                            fac: this.facId,
                            fac1: this.token,
                            mode: this.mode,
                            inv: this.invNo
                        }
                    })
                    .then(res => {
                        const data = res.data;
                        if (!data.Success) {
                            alert(data.Message || '載入資料失敗');
                            this.loading = false;
                            return;
                        }
                        this.facInfo = data.FacInfo || {};
                        this.recordData = data.RecordData || {};
                        this.sections = data.Sections || [];
                        this.devSummary = data.DevSummary || [];
                        this.photoGallery = data.PhotoGallery || [];
                        this.signatures = data.Signatures || {};
                        this.checkHistory = data.CheckHistory || [];
                        this.currentStageTitle = data.CurrentStageTitle || '案件審查作業';
                        this.currentCaseState = data.CurrentCaseState || '';
                        this.canReview = data.CanReview;
                        this.isReadOnly = data.IsReadOnly;

                        // 預設全展開九大設施
                        this.sections.forEach(s => {
                            this.expandedSections[s.Id] = true;
                        });

                        this.loading = false;
                        this.$nextTick(() => {
                            this.initLeafletMap();
                        });
                    })
                    .catch(err => {
                        alert('載入資料發生網路錯誤：' + err.message);
                        this.loading = false;
                    });
                },
                initLeafletMap() {
                    const mapEl = document.getElementById('map');
                    if (!mapEl) return;

                    let lat = parseFloat(this.facInfo.Lat);
                    let lng = parseFloat(this.facInfo.Lng);
                    let hasCoords = true;

                    if (!lat || !lng || isNaN(lat) || isNaN(lng) || lat <= 0 || lng <= 0) {
                        lat = 25.0125;
                        lng = 121.4657; // 新北市政府座標預設值
                        hasCoords = false;
                    }

                    // 遵守鐵律：Leaflet 實例使用原生非響應式屬性隔離存放
                    this.leafletMap = markRaw(L.map('map', {
                        center: [lat, lng],
                        zoom: hasCoords ? 16 : 12,
                        zoomControl: true
                    }));

                    L.tileLayer('https://wmts.nlsc.gov.tw/wmts/EMAP/default/GoogleMapsCompatible/{z}/{y}/{x}', {
                        maxZoom: 19,
                        attribution: '&copy; 內政部國土測繪中心 臺灣通用電子地圖'
                    }).addTo(this.leafletMap);

                    if (hasCoords) {
                        const marker = L.marker([lat, lng]).addTo(this.leafletMap);
                        marker.bindPopup('<strong>' + (this.facInfo.FAC_NAME || '工廠場所') + '</strong><br>' + (this.facInfo.ADDR || '')).openPopup();
                    }
                },
                resetMapView() {
                    if (!this.leafletMap) return;
                    let lat = parseFloat(this.facInfo.Lat) || 25.0125;
                    let lng = parseFloat(this.facInfo.Lng) || 121.4657;
                    this.leafletMap.setView([lat, lng], 16);
                },
                toggleMapCollapse() {
                    this.isMapCollapsed = !this.isMapCollapsed;
                    setTimeout(() => {
                        if (this.leafletMap) this.leafletMap.invalidateSize();
                    }, 350);
                },
                toggleSection(id) {
                    this.expandedSections[id] = !this.expandedSections[id];
                },
                toggleAllSections() {
                    this.allSectionsExpanded = !this.allSectionsExpanded;
                    this.sections.forEach(s => {
                        this.expandedSections[s.Id] = this.allSectionsExpanded;
                    });
                },
                applyQuickMemo(text) {
                    if (this.reviewForm.chkMemo) {
                        this.reviewForm.chkMemo += ' ' + text;
                    } else {
                        this.reviewForm.chkMemo = text;
                    }
                },
                confirmSubmitReview() {
                    const resText = this.reviewForm.chkResult === 'PASS' ? '【審查通過】' : '【退回修正】';
                    const confirmMsg = '確定要送出本案之' + resText + '審查結果嗎？\n\n' +
                                      '場所：' + this.facInfo.FAC_NAME + '\n' +
                                      '階段：' + this.currentStageTitle + '\n' +
                                      '意見：' + (this.reviewForm.chkMemo || '無');

                    if (!confirm(confirmMsg)) return;

                    this.submittingReview = true;
                    const params = new URLSearchParams();
                    params.append('action', 'submit_review');
                    params.append('fac', this.facId);
                    params.append('mode', this.mode);
                    params.append('inv', this.invNo);
                    params.append('chkResult', this.reviewForm.chkResult);
                    params.append('chkMemo', this.reviewForm.chkMemo || '');

                    axios.post('Check_Step1.aspx', params)
                    .then(res => {
                        this.submittingReview = false;
                        const data = res.data;
                        if (!data.Success) {
                            alert(data.Message || '審核作業送出失敗');
                            return;
                        }
                        alert(data.Message);
                        window.location.href = data.RedirectUrl || ('managerList.aspx?INV_State=' + this.mode);
                    })
                    .catch(err => {
                        this.submittingReview = false;
                        alert('送出失敗（網路連線錯誤）：' + err.message);
                    });
                },
                openDeviceModal() {
                    axios.get('Check_Step1.aspx', {
                        params: {
                            action: 'get_device_detail',
                            facId: this.facId
                        }
                    })
                    .then(res => {
                        const data = res.data;
                        if (data.Success) {
                            this.deviceDetails = data.Devices || [];
                            this.processDetails = data.Processes || [];
                            this.showDevModal = true;
                        }
                    });
                },
                openLightbox(idx) {
                    if (!this.photoGallery[idx]) return;
                    this.lightbox.currentUrl = this.photoGallery[idx].Url;
                    this.lightbox.title = this.photoGallery[idx].Name + (this.photoGallery[idx].Memo ? ' - ' + this.photoGallery[idx].Memo : '');
                    this.lightbox.rotate = 0;
                    this.lightbox.show = true;
                },
                openSingleImage(url, title) {
                    if (!url) return;
                    this.lightbox.currentUrl = url;
                    this.lightbox.title = title;
                    this.lightbox.rotate = 0;
                    this.lightbox.show = true;
                },
                closeLightbox() {
                    this.lightbox.show = false;
                },
                rotateLightbox() {
                    this.lightbox.rotate = (this.lightbox.rotate + 90) % 360;
                },
                handleKeyDown(e) {
                    if (e.key === 'Escape') {
                        if (this.lightbox.show) this.closeLightbox();
                        if (this.showDevModal) this.showDevModal = false;
                    }
                },
                scrollToReview() {
                    const el = document.getElementById('reviewPanel');
                    if (el) el.scrollIntoView({ behavior: 'smooth' });
                },
                scrollToPhotos() {
                    window.scrollTo({ top: document.body.scrollHeight, behavior: 'smooth' });
                },
                openGoogleMaps() {
                    const lat = this.facInfo.Lat;
                    const lng = this.facInfo.Lng;
                    if (lat && lng) {
                        window.open('https://www.google.com/maps/dir/?api=1&destination=' + lat + ',' + lng, '_blank');
                    }
                },
                printCase() {
                    window.print();
                },
                getStepClass(step) {
                    if (this.numericStepCode > step) return 'completed';
                    if (this.numericStepCode === step) return 'active';
                    return '';
                },
                getStepAuditInfo(stateId) {
                    const match = this.checkHistory.find(h => h.State_Name && h.State_Name.indexOf(stateId) >= 0);
                    if (match) {
                        return match.Chk_UserName + ' (' + match.Chk_Result + ')';
                    }
                    return '待審核';
                }
            }
        }).mount('#app');
    </script>
</body>
</html>
