<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="FAC_Detail.aspx.cs" Inherits="NTPC_FEC.FAC.FAC_Detail" %>
<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定溢散源管理平台 - 固定污染源公私場所資料詳情</title>

    <link rel="shortcut icon" href="../favicon.ico" type="image/x-icon" />

    <!-- 本地化樣式庫依賴 (避開外部 CDN 資安阻擋) -->
    <link rel="stylesheet" href="../Content/bootstrap.min.css" />
    <link rel="stylesheet" href="../Content/fontawesome/css/all.min.css" />
    <link rel="stylesheet" href="../Content/leaflet/leaflet.css" />

    <style>
        :root {
            --brand-primary: #0099e5;     /* 新北天空青藍 */
            --brand-blue: #0284c7;        /* 科技藍 */
            --brand-dark-blue: #0b1f7d;   /* 海軍深藍 */
            --brand-navy: #0f172a;        /* 標題文字主色 */
            --brand-factory: #0d9488;     /* 固定源工業青綠 */
            --brand-factory-light: #f0fdfa;
            --bg-canvas: #f1f5f9;         /* 頁面灰底 */
            --surface: #ffffff;           /* 卡片純白底色 */
            --border-color: #e2e8f0;      /* 邊框線條 */
            --text-main: #0f172a;         /* 內文主色 */
            --text-muted: #64748b;        /* 次要說明 */
            --status-warn: #f59e0b;       /* 警告黃 */
            --status-danger: #ef4444;     /* 異常紅 */
            --status-success: #10b981;    /* 正常綠 */
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

        /* 置頂深青藍漸層導覽列 */
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

        .brand-title {
            font-size: 1.08rem;
            font-weight: 700;
            margin: 0;
            display: flex;
            align-items: center;
            gap: 8px;
            color: #ffffff;
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

        /* 主作業容器 (固定最大寬度 1560px 居中) */
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

        /* 桌面端側欄固頂 */
        @media screen and (min-width: 1200px) {
            .sticky-sidebar {
                position: sticky;
                top: 72px;
                max-height: calc(100vh - 88px);
                overflow-y: auto;
                padding-right: 4px;
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
            background: var(--brand-factory);
            color: #ffffff;
            box-shadow: 0 0 0 2px var(--brand-factory);
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
            color: var(--brand-factory);
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

        /* 警示卡片 */
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

        /* 基本資料統計晶片列 */
        .stat-chips-group {
            display: flex;
            flex-wrap: wrap;
            gap: 8px;
            margin-bottom: 12px;
        }
        .stat-chip {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 6px 12px;
            font-size: 13px;
            color: #334155;
            display: inline-flex;
            align-items: center;
            gap: 6px;
        }
        .stat-chip-label {
            color: #64748b;
            font-size: 12px;
        }
        .stat-chip-val {
            font-weight: 700;
            color: #0f172a;
        }

        /* 地圖控制與容器 */
        #map {
            width: 100%;
            height: 320px;
            border-radius: 8px;
            z-index: 10;
            transition: height 0.3s ease;
        }
        #map.map-collapsed {
            height: 110px !important;
        }

        /* 自定義地圖標記 */
        .marker-pin-fac {
            width: 34px;
            height: 34px;
            border-radius: 50% 50% 50% 0;
            background: var(--brand-factory);
            position: absolute;
            transform: rotate(-45deg);
            left: 50%;
            top: 50%;
            margin: -20px 0 0 -17px;
            box-shadow: 0 3px 8px rgba(0, 0, 0, 0.35);
            border: 2px solid #ffffff;
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
        }
        .marker-icon-fac {
            transform: rotate(45deg);
            color: #ffffff;
            font-size: 14px;
        }

        /* 廠區圖檔展示卡 */
        .file-item-card {
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 10px;
            background: #f8fafc;
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 8px;
            transition: all 0.2s;
        }
        .file-item-card:hover {
            border-color: #cbd5e1;
            background: #ffffff;
            box-shadow: 0 2px 6px rgba(0, 0, 0, 0.05);
        }

        /* 現代導覽頁籤 (Tabs) */
        .nav-tabs-modern {
            border-bottom: 2px solid #e2e8f0;
            gap: 4px;
            margin-bottom: 16px;
        }
        .nav-tabs-modern .nav-link {
            border: none;
            color: #64748b;
            font-weight: 600;
            padding: 10px 18px;
            border-radius: 8px 8px 0 0;
            cursor: pointer;
            position: relative;
            background: transparent;
            font-size: 0.95rem;
            transition: all 0.2s;
        }
        .nav-tabs-modern .nav-link:hover {
            color: var(--brand-factory);
            background: rgba(13, 148, 136, 0.05);
        }
        .nav-tabs-modern .nav-link.active {
            color: var(--brand-factory);
            font-weight: 700;
            background: #ffffff;
            border-bottom: 3px solid var(--brand-factory);
        }

        /* 防制措施二級膠囊切換鈕 */
        .prevent-pills-group {
            display: flex;
            flex-wrap: wrap;
            gap: 6px;
            margin-bottom: 16px;
            background: #f1f5f9;
            padding: 6px;
            border-radius: 10px;
        }
        .prevent-pill-btn {
            border: none;
            background: transparent;
            padding: 6px 14px;
            border-radius: 6px;
            font-size: 13px;
            font-weight: 600;
            color: #475569;
            cursor: pointer;
            transition: all 0.15s;
        }
        .prevent-pill-btn:hover {
            background: #e2e8f0;
            color: #0f172a;
        }
        .prevent-pill-btn.active {
            background: var(--brand-factory);
            color: #ffffff;
            box-shadow: 0 1px 4px rgba(13, 148, 136, 0.35);
        }

        /* 自定義高質感表格 */
        .table-custom {
            width: 100%;
            margin-bottom: 0;
            color: #1e293b;
        }
        .table-custom thead th {
            background-color: #f8fafc;
            color: #475569;
            font-size: 0.85rem;
            font-weight: 700;
            border-bottom: 2px solid #e2e8f0;
            border-top: none;
            padding: 10px 12px;
            white-space: nowrap;
        }
        .table-custom tbody td {
            padding: 10px 12px;
            font-size: 0.9rem;
            border-top: 1px solid #f1f5f9;
            vertical-align: middle;
        }
        .table-custom tbody tr:hover {
            background-color: #f8fafc;
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

        /* 列印專用報表頁首 */
        .print-only-header {
            display: none;
        }
        @media print {
            .no-print {
                display: none !important;
            }
            .print-only-header {
                display: block;
                border-bottom: 2px solid #000;
                padding-bottom: 12px;
                margin-bottom: 20px;
            }
            body {
                background: #ffffff;
                font-size: 12pt;
                color: #000;
            }
            .card-modern {
                box-shadow: none;
                border: 1px solid #ccc;
                page-break-inside: avoid;
            }
            .sticky-sidebar {
                position: static !important;
                max-height: none !important;
                overflow: visible !important;
            }
        }
    </style>
</head>
<body>
    <div id="facApp" v-cloak>
        <!-- 1. 置頂深青藍漸層導覽列 (Sticky Top Navbar) -->
        <header class="top-navbar no-print">
            <div class="d-flex align-items-center">
                <button type="button" class="nav-btn mr-2" v-on:click="goBack" title="返回公私場所清單">
                    <i class="fas fa-arrow-left"></i>
                    <span class="d-none d-sm-inline">返回清單</span>
                </button>
                <div class="brand-title">
                    <i class="fas fa-industry text-white"></i>
                    <span>公私場所詳細資料</span>
                    <span v-if="main.C_NO" class="badge badge-light text-dark font-weight-bold ml-2" style="font-size: 0.85rem;" title="管制編號">
                        {{ main.C_NO }}
                    </span>
                    <span v-if="main.FAC_TYPE" class="badge badge-info ml-1" style="font-size: 0.8rem;">
                        {{ main.FAC_TYPE }}
                    </span>
                </div>
            </div>

            <!-- 右側功能動作群組 -->
            <div class="d-flex align-items-center gap-2">
                <button type="button" class="nav-btn bg-white text-dark shadow-sm" v-on:click="printCase" title="列印公私場所檔案">
                    <i class="fas fa-print"></i>
                    <span class="d-none d-md-inline">列印案件</span>
                </button>

                <button v-if="main.Lat && main.Lng" type="button" class="nav-btn bg-white text-dark shadow-sm ml-2" v-on:click="openGoogleMaps" title="開啟 Google 地圖導航">
                    <i class="fas fa-location-arrow text-success"></i>
                    <span class="d-none d-md-inline">路線導航</span>
                </button>

                <button type="button" class="nav-btn btn-warning text-dark font-weight-bold shadow-sm ml-2" v-on:click="openEditModal" title="編輯基本聯絡與場所資料">
                    <i class="fas fa-edit mr-1"></i>
                    <span class="d-none d-md-inline">編輯資料</span>
                </button>
            </div>
        </header>

        <!-- 2. 列印專用報表頁首 (螢幕隱藏，列印時顯現) -->
        <div class="print-only-header">
            <div class="d-flex justify-content-between align-items-center">
                <div>
                    <h3 class="mb-1 font-weight-bold">新北市政府環境保護局 固定污染源公私場所資料表</h3>
                    <div class="text-muted">列印時間：{{ printTimeStr }} | 系統產製</div>
                </div>
                <div class="text-right">
                    <h5 class="mb-0 font-weight-bold">管制編號：{{ main.C_NO }}</h5>
                    <small>場所代碼：{{ main.FAC_ID }}</small>
                </div>
            </div>
        </div>

        <!-- 3. 主作業容器 -->
        <main class="container-fluid-custom">
            <!-- 載入中骨架提示 -->
            <div v-if="loading" class="text-center py-5">
                <div class="spinner-border text-primary" style="width: 3rem; height: 3rem;" role="status">
                    <span class="sr-only">資料載入中...</span>
                </div>
                <div class="mt-3 font-weight-bold text-muted">正在為您讀取公私場所各項設備、製程與防制措施資料，請稍候...</div>
            </div>

            <!-- 載入失敗警示 -->
            <div v-else-if="errorMessage" class="alert-gback shadow-sm">
                <i class="fas fa-exclamation-triangle mr-2"></i>
                <strong>讀取失敗：</strong>{{ errorMessage }}
                <div class="mt-2">
                    <button type="button" class="btn btn-sm btn-danger" v-on:click="loadDetail">重新載入</button>
                    <button type="button" class="btn btn-sm btn-outline-secondary ml-2" v-on:click="goBack">返回上一頁</button>
                </div>
            </div>

            <!-- 主資料內容區 -->
            <div v-else>
                <!-- A. 列管狀態歷程時間軸 (Status Stepper) -->
                <div class="stepper-container shadow-sm no-print">
                    <div class="stepper-line">
                        <div class="stepper-line-fill" :style="{ width: stepperProgress + '%' }"></div>
                    </div>

                    <!-- 步驟 1: 基本建檔立案 -->
                    <div class="step-item completed">
                        <div class="step-circle">
                            <i class="fas fa-check"></i>
                        </div>
                        <div class="step-title">基本建檔立案</div>
                        <div class="step-time">{{ main.FAC_ID || '已完成' }}</div>
                    </div>

                    <!-- 步驟 2: 管理辦法納管審核 -->
                    <div class="step-item" :class="main.Accept_Date ? 'completed' : 'active'">
                        <div class="step-circle">
                            <i v-if="main.Accept_Date" class="fas fa-check"></i>
                            <span v-else>2</span>
                        </div>
                        <div class="step-title">管理辦法納管</div>
                        <div class="step-time">{{ main.Accept_Date || '未納管/審核中' }}</div>
                    </div>

                    <!-- 步驟 3: 常態列管營運中 / 已解除納管 -->
                    <div class="step-item active">
                        <div class="step-circle">
                            <i v-if="isDelisted" class="fas fa-ban text-warning"></i>
                            <i v-else class="fas fa-industry"></i>
                        </div>
                        <div class="step-title">{{ isDelisted ? '已解除納管' : '持續列管營運中' }}</div>
                        <div class="step-time">{{ isDelisted ? (main.Operating_Date || '已解除') : (main.FAC_TYPE || '常態稽查') }}</div>
                    </div>
                </div>

                <!-- B. 解除納管說明警示條 (若已解除納管) -->
                <div v-if="isDelisted" class="alert alert-warning shadow-sm d-flex align-items-center">
                    <i class="fas fa-info-circle fa-2x mr-3 text-warning"></i>
                    <div>
                        <div class="font-weight-bold">該公私場所已於 {{ main.Operating_Date }} 解除納管：</div>
                        <div class="small">{{ main.Reg_Memo || '無解除納管備註說明' }}</div>
                    </div>
                </div>

                <!-- C. 雙欄卡片佈局 (左欄 40%，右欄 60%) -->
                <div class="row">
                    <!-- ================= 左欄：基本資料、現場地圖與廠區圖檔 (40%) ================= -->
                    <div class="col-xl-5 col-lg-5 col-12">
                        <div class="sticky-sidebar">
                            <!-- 卡片 1: 場所核心概況卡片 -->
                            <div class="card-modern">
                                <div class="card-modern-header">
                                    <h5 class="card-modern-title">
                                        <i class="fas fa-building text-info"></i>
                                        <span>場所核心資料</span>
                                    </h5>
                                    <span class="badge badge-pill badge-primary px-3 py-1" style="font-size: 0.82rem;">
                                        {{ main.TownName || '新北市' }}
                                    </span>
                                </div>
                                <div class="card-modern-body">
                                    <h4 class="font-weight-bold text-dark mb-2">
                                        {{ main.FAC_NAME }}
                                    </h4>

                                    <!-- 晶片標籤列 -->
                                    <div class="stat-chips-group">
                                        <div class="stat-chip" title="管制編號">
                                            <span class="stat-chip-label">管編：</span>
                                            <span class="stat-chip-val text-primary">{{ main.C_NO }}</span>
                                        </div>
                                        <div class="stat-chip" title="行業別">
                                            <span class="stat-chip-label">行業：</span>
                                            <span class="stat-chip-val">{{ main.IndustrialName || '未指定' }}</span>
                                        </div>
                                        <div class="stat-chip" title="大門座標">
                                            <span class="stat-chip-label">TWD97：</span>
                                            <span class="stat-chip-val">{{ main.CoodDisplay }}</span>
                                        </div>
                                    </div>

                                    <!-- 列表詳細資訊 -->
                                    <ul class="list-group list-group-flush mb-3">
                                        <li class="list-group-item px-0 py-2 d-flex justify-content-between align-items-center">
                                            <span class="text-muted"><i class="fas fa-map-marker-alt mr-2 text-danger"></i>廠址地址</span>
                                            <span class="font-weight-bold text-right text-break ml-2" style="max-width: 65%;">
                                                {{ main.ADDR || '未填寫地址' }}
                                                <button type="button" class="btn btn-sm btn-link p-0 ml-1 text-primary" v-on:click="copyText(main.ADDR)" title="複製地址">
                                                    <i class="far fa-copy"></i>
                                                </button>
                                            </span>
                                        </li>
                                        <li class="list-group-item px-0 py-2 d-flex justify-content-between align-items-center">
                                            <span class="text-muted"><i class="fas fa-user mr-2 text-secondary"></i>場所聯絡人</span>
                                            <span class="font-weight-bold">{{ main.Content_Name || '未填寫' }}</span>
                                        </li>
                                        <li class="list-group-item px-0 py-2 d-flex justify-content-between align-items-center">
                                            <span class="text-muted"><i class="fas fa-phone mr-2 text-success"></i>聯絡電話</span>
                                            <span class="font-weight-bold">
                                                <a v-if="main.TEL" :href="'tel:' + main.TEL" class="text-success text-decoration-none">
                                                    <i class="fas fa-phone-volume mr-1"></i>{{ main.TEL }}
                                                </a>
                                                <span v-else class="text-muted">未提供電話</span>
                                            </span>
                                        </li>
                                        <li class="list-group-item px-0 py-2 d-flex justify-content-between align-items-center">
                                            <span class="text-muted"><i class="fas fa-tag mr-2 text-primary"></i>管理辦法適用</span>
                                            <span class="font-weight-bold text-right text-break ml-2">{{ main.RegDisplay || '無' }}</span>
                                        </li>
                                        <li class="list-group-item px-0 py-2 d-flex justify-content-between align-items-center">
                                            <span class="text-muted"><i class="far fa-calendar-check mr-2 text-info"></i>管理辦法納管日</span>
                                            <span class="font-weight-bold">{{ main.Accept_Date || '未填寫' }}</span>
                                        </li>
                                        <li v-if="main.Work_Memo" class="list-group-item px-0 py-2">
                                            <div class="text-muted mb-1"><i class="fas fa-sticky-note mr-2 text-warning"></i>作業備註</div>
                                            <div class="p-2 bg-light rounded text-secondary small" style="white-space: pre-wrap;">{{ main.Work_Memo }}</div>
                                        </li>
                                    </ul>
                                </div>
                            </div>

                            <!-- 卡片 2: 現場智慧地圖 (Leaflet.js) -->
                            <div class="card-modern">
                                <div class="card-modern-header">
                                    <h5 class="card-modern-title">
                                        <i class="fas fa-map-marked-alt text-success"></i>
                                        <span>廠區空間坐標與圖資</span>
                                    </h5>
                                    <div class="d-flex align-items-center gap-1">
                                        <!-- 手機版摺疊開關 -->
                                        <button type="button" class="btn btn-sm btn-outline-secondary d-md-none mr-1" v-on:click="toggleMapCollapse">
                                            <i :class="isMapCollapsed ? 'fas fa-chevron-down' : 'fas fa-chevron-up'"></i>
                                            {{ isMapCollapsed ? '展開' : '收合' }}
                                        </button>
                                        <button type="button" class="btn btn-sm btn-outline-primary" v-on:click="locateUser" title="GPS 定位目前所在位置">
                                            <i class="fas fa-crosshairs"></i>
                                        </button>
                                        <button type="button" class="btn btn-sm btn-outline-secondary ml-1" v-on:click="resetMapView" title="重設全景視角">
                                            <i class="fas fa-expand-arrows-alt"></i>
                                        </button>
                                    </div>
                                </div>
                                <div class="card-modern-body p-2">
                                    <div id="map" :class="{ 'map-collapsed': isMapCollapsed }"></div>
                                    <div class="d-flex justify-content-between align-items-center mt-2 px-1 small text-muted">
                                        <span>
                                            <i class="fas fa-info-circle mr-1"></i>
                                            <span v-if="main.Lat && main.Lng">經緯度: {{ main.Lat }}, {{ main.Lng }}</span>
                                            <span v-else class="text-danger">暫無高精度經緯度坐標</span>
                                        </span>
                                        <a v-if="main.Lat && main.Lng" href="javascript:void(0)" class="text-primary font-weight-bold" v-on:click="openGoogleMaps">
                                            開啟Google導航 <i class="fas fa-external-link-alt ml-1"></i>
                                        </a>
                                    </div>
                                </div>
                            </div>

                            <!-- 卡片 3: 廠區配置圖與製程流程圖 -->
                            <div class="card-modern">
                                <div class="card-modern-header">
                                    <h5 class="card-modern-title">
                                        <i class="fas fa-file-image text-warning"></i>
                                        <span>廠區配置圖與製程流程圖</span>
                                    </h5>
                                    <span class="badge badge-secondary">{{ files.length }} 件檔案</span>
                                </div>
                                <div class="card-modern-body">
                                    <div v-if="files.length === 0" class="text-center py-4 text-muted">
                                        <i class="far fa-folder-open fa-3x mb-2 text-black-50"></i>
                                        <div>未在伺服器上傳廠區配置圖或製程流程圖檔案</div>
                                        <small class="text-muted">(存放目錄: Upload/FAC/{{ main.C_NO }}/)</small>
                                    </div>
                                    <div v-else>
                                        <div v-for="(file, fIdx) in files" :key="fIdx" class="file-item-card">
                                            <div class="d-flex align-items-center text-truncate mr-2">
                                                <i v-if="file.IsPdf" class="far fa-file-pdf fa-2x text-danger mr-2"></i>
                                                <i v-else-if="file.IsImage" class="far fa-file-image fa-2x text-success mr-2"></i>
                                                <i v-else class="far fa-file-alt fa-2x text-primary mr-2"></i>
                                                <div class="text-truncate">
                                                    <div class="font-weight-bold text-truncate" style="max-width: 200px;" :title="file.FileName">
                                                        {{ file.FileName }}
                                                    </div>
                                                    <small class="text-muted">
                                                        <span class="badge badge-light mr-1">{{ file.Category }}</span>
                                                        {{ file.FileSizeStr }}
                                                    </small>
                                                </div>
                                            </div>
                                            <div>
                                                <button v-if="file.IsImage" type="button" class="btn btn-sm btn-outline-info mr-1" v-on:click="previewImage(file)" title="預覽大圖">
                                                    <i class="fas fa-search-plus"></i>
                                                </button>
                                                <a :href="file.FileUrl" target="_blank" class="btn btn-sm btn-outline-primary" title="開啟或下載">
                                                    <i class="fas fa-external-link-alt"></i>
                                                </a>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- ================= 右欄：主檢核區、設備物料、製程與防制措施 (60%) ================= -->
                    <div class="col-xl-7 col-lg-7 col-12">
                        <!-- 現代導覽頁籤 (Nav Tabs) -->
                        <ul class="nav nav-tabs nav-tabs-modern" role="tablist">
                            <li class="nav-item">
                                <button type="button" class="nav-link" :class="{ active: currentTab === 'devices' }" v-on:click="currentTab = 'devices'">
                                    <i class="fas fa-cogs mr-1"></i> 設備與原物料
                                    <span class="badge badge-pill badge-light border ml-1">{{ devices.length }}</span>
                                </button>
                            </li>
                            <li class="nav-item">
                                <button type="button" class="nav-link" :class="{ active: currentTab === 'processes' }" v-on:click="currentTab = 'processes'">
                                    <i class="fas fa-network-wired mr-1"></i> 設備與製程
                                    <span class="badge badge-pill badge-light border ml-1">{{ processes.length }}</span>
                                </button>
                            </li>
                            <li class="nav-item">
                                <button type="button" class="nav-link" :class="{ active: currentTab === 'prevents' }" v-on:click="currentTab = 'prevents'">
                                    <i class="fas fa-shield-alt mr-1"></i> 空污防制措施
                                    <span class="badge badge-pill badge-success ml-1">7類</span>
                                </button>
                            </li>
                            <li class="nav-item">
                                <button type="button" class="nav-link" :class="{ active: currentTab === 'history' }" v-on:click="currentTab = 'history'">
                                    <i class="fas fa-history mr-1"></i> 派工與異動
                                    <span class="badge badge-pill badge-light border ml-1">{{ missions.length + history.length }}</span>
                                </button>
                            </li>
                        </ul>

                        <!-- ================= Tab 1: 設備與原物料 ================= -->
                        <div v-show="currentTab === 'devices'">
                            <div class="card-modern">
                                <div class="card-modern-header">
                                    <h5 class="card-modern-title">
                                        <i class="fas fa-boxes text-primary"></i>
                                        <span>設備與原物料清單</span>
                                    </h5>
                                    <div class="d-flex align-items-center">
                                        <input type="text" v-model="deviceSearch" class="form-control form-control-sm mr-2" placeholder="搜尋設備或物料名稱..." style="width: 180px;" />
                                        <span class="text-muted small">共 {{ filteredDevices.length }} 筆</span>
                                    </div>
                                </div>
                                <div class="card-modern-body p-0">
                                    <div v-if="filteredDevices.length === 0" class="text-center py-5 text-muted">
                                        <i class="fas fa-inbox fa-3x text-black-50 mb-2"></i>
                                        <div>未查得設備與原物料申報資料</div>
                                    </div>
                                    <div v-else class="table-responsive">
                                        <table class="table table-custom">
                                            <thead>
                                                <tr>
                                                    <th>設備編號</th>
                                                    <th>設備名稱</th>
                                                    <th>物料名稱</th>
                                                    <th>物料種類</th>
                                                    <th class="text-right">許可年操作量(噸)</th>
                                                    <th class="text-right">實際年操作量(噸)</th>
                                                    <th class="text-right">許可最大小時量</th>
                                                    <th class="text-right">實際年用量</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                <tr v-for="(dev, dIdx) in filteredDevices" :key="dIdx">
                                                    <td class="font-weight-bold text-primary">
                                                        {{ dev.Device_NO }}
                                                        <span v-if="dev.Device_Code" class="badge badge-light border ml-1">{{ dev.Device_Code }}</span>
                                                    </td>
                                                    <td>{{ dev.Device_Name || '-' }}</td>
                                                    <td class="font-weight-bold">{{ dev.Store_substance || '-' }}</td>
                                                    <td>
                                                        <span v-if="dev.Store_Type" class="badge badge-secondary">{{ dev.Store_Type }}</span>
                                                        <span v-else class="text-muted">-</span>
                                                    </td>
                                                    <td class="text-right font-weight-bold">{{ dev.Lic_sum || '0' }}</td>
                                                    <td class="text-right font-weight-bold text-success">{{ dev.Real_sum || '0' }}</td>
                                                    <td class="text-right">
                                                        <span v-if="dev.Lic_max">{{ dev.Lic_max }} {{ dev.Lic_unit }}</span>
                                                        <span v-else class="text-muted">-</span>
                                                    </td>
                                                    <td class="text-right">
                                                        <span v-if="dev.Real_use">{{ dev.Real_use }} {{ dev.Real_use_unit }}</span>
                                                        <span v-else class="text-muted">-</span>
                                                    </td>
                                                </tr>
                                            </tbody>
                                        </table>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- ================= Tab 2: 設備與製程 ================= -->
                        <div v-show="currentTab === 'processes'">
                            <div class="card-modern">
                                <div class="card-modern-header">
                                    <h5 class="card-modern-title">
                                        <i class="fas fa-sitemap text-info"></i>
                                        <span>設備與製程對應關係</span>
                                    </h5>
                                    <span class="badge badge-pill badge-info">{{ processes.length }} 筆製程</span>
                                </div>
                                <div class="card-modern-body p-0">
                                    <div v-if="processes.length === 0" class="text-center py-5 text-muted">
                                        <i class="fas fa-folder-open fa-3x text-black-50 mb-2"></i>
                                        <div>未查得製程資料</div>
                                    </div>
                                    <div v-else class="table-responsive">
                                        <table class="table table-custom">
                                            <thead>
                                                <tr>
                                                    <th>設備編號</th>
                                                    <th>設備名稱</th>
                                                    <th>設備狀態</th>
                                                    <th>製程編號</th>
                                                    <th>製程名稱</th>
                                                    <th>製程狀態</th>
                                                    <th>許可證字號</th>
                                                    <th>許可年限</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                <tr v-for="(proc, pIdx) in processes" :key="pIdx">
                                                    <td class="font-weight-bold text-primary">
                                                        {{ proc.Device_NO }}
                                                        <span v-if="proc.Device_Code" class="badge badge-light border ml-1">{{ proc.Device_Code }}</span>
                                                    </td>
                                                    <td>{{ proc.Device_Name || '-' }}</td>
                                                    <td>
                                                        <span class="badge badge-pill badge-light border">{{ proc.Device_Type || '一般' }}</span>
                                                    </td>
                                                    <td class="font-weight-bold">{{ proc.Process_NO }}</td>
                                                    <td>{{ proc.Process_Name || '-' }}</td>
                                                    <td>
                                                        <span class="badge badge-pill badge-light border">{{ proc.Process_Type || '正常' }}</span>
                                                    </td>
                                                    <td class="font-weight-bold text-dark">{{ proc.Process_Lic || '-' }}</td>
                                                    <td>{{ proc.Lic_Year || '-' }}</td>
                                                </tr>
                                            </tbody>
                                        </table>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- ================= Tab 3: 7 大空污防制措施 ================= -->
                        <div v-show="currentTab === 'prevents'">
                            <!-- 二級膠囊標籤切換 -->
                            <div class="prevent-pills-group">
                                <button type="button" class="prevent-pill-btn" :class="{ active: preventSubTab === 1 }" v-on:click="preventSubTab = 1">
                                    1. 堆置作業 <span class="badge badge-light ml-1">{{ (prevents.Prevent1 || []).length }}</span>
                                </button>
                                <button type="button" class="prevent-pill-btn" :class="{ active: preventSubTab === 2 }" v-on:click="preventSubTab = 2">
                                    2. 輸送作業 <span class="badge badge-light ml-1">{{ (prevents.Prevent2 || []).length }}</span>
                                </button>
                                <button type="button" class="prevent-pill-btn" :class="{ active: preventSubTab === 3 }" v-on:click="preventSubTab = 3">
                                    3. 車輛運輸 <span class="badge badge-light ml-1">{{ (prevents.Prevent3 || []).length }}</span>
                                </button>
                                <button type="button" class="prevent-pill-btn" :class="{ active: preventSubTab === 4 }" v-on:click="preventSubTab = 4">
                                    4. 製程裝卸 <span class="badge badge-light ml-1">{{ (prevents.Prevent4 || []).length }}</span>
                                </button>
                                <button type="button" class="prevent-pill-btn" :class="{ active: preventSubTab === 5 }" v-on:click="preventSubTab = 5">
                                    5. 裸露區域 <span class="badge badge-light ml-1">{{ (prevents.Prevent5 || []).length }}</span>
                                </button>
                                <button type="button" class="prevent-pill-btn" :class="{ active: preventSubTab === 6 }" v-on:click="preventSubTab = 6">
                                    6. 車行路徑 <span class="badge badge-light ml-1">{{ (prevents.Prevent6 || []).length }}</span>
                                </button>
                                <button type="button" class="prevent-pill-btn" :class="{ active: preventSubTab === 7 }" v-on:click="preventSubTab = 7">
                                    7. 自主管理 <span class="badge badge-light ml-1">{{ (prevents.Prevent7 || []).length }}</span>
                                </button>
                            </div>

                            <!-- 1. 堆置作業 -->
                            <div v-show="preventSubTab === 1" class="card-modern">
                                <div class="card-modern-header">
                                    <h5 class="card-modern-title"><i class="fas fa-cubes text-primary"></i> 堆置作業防制措施</h5>
                                    <span class="badge badge-light border">{{ (prevents.Prevent1 || []).length }} 筆</span>
                                </div>
                                <div class="card-modern-body p-0">
                                    <div v-if="!prevents.Prevent1 || prevents.Prevent1.length === 0" class="text-center py-4 text-muted">無堆置作業防制設施申報資料</div>
                                    <div v-else class="table-responsive">
                                        <table class="table table-custom">
                                            <thead>
                                                <tr>
                                                    <th>防制措施</th>
                                                    <th>防制規定</th>
                                                    <th class="text-right">阻隔牆高(m)</th>
                                                    <th class="text-right">最大堆置高(m)</th>
                                                    <th class="text-right">作業時間覆蓋(%)</th>
                                                    <th class="text-right">未作業時間覆蓋(%)</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                <tr v-for="(item, idx) in prevents.Prevent1" :key="idx">
                                                    <td class="font-weight-bold text-dark">{{ item.Measure }}</td>
                                                    <td>{{ item.Stipulate }}</td>
                                                    <td class="text-right">{{ item.WallHeight || '-' }}</td>
                                                    <td class="text-right">{{ item.StackHeight || '-' }}</td>
                                                    <td class="text-right">{{ formatPercent(item.WorkArea_Percent) }}</td>
                                                    <td class="text-right">{{ formatPercent(item.NotWordArea_Percent) }}</td>
                                                </tr>
                                            </tbody>
                                        </table>
                                    </div>
                                </div>
                            </div>

                            <!-- 2. 輸送作業 -->
                            <div v-show="preventSubTab === 2" class="card-modern">
                                <div class="card-modern-header">
                                    <h5 class="card-modern-title"><i class="fas fa-dolly text-success"></i> 輸送作業防制措施</h5>
                                    <span class="badge badge-light border">{{ (prevents.Prevent2 || []).length }} 筆</span>
                                </div>
                                <div class="card-modern-body p-0">
                                    <div v-if="!prevents.Prevent2 || prevents.Prevent2.length === 0" class="text-center py-4 text-muted">無輸送作業防制設施申報資料</div>
                                    <div v-else class="table-responsive">
                                        <table class="table table-custom">
                                            <thead>
                                                <tr>
                                                    <th style="width: 35%;">防制措施</th>
                                                    <th>防制規定</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                <tr v-for="(item, idx) in prevents.Prevent2" :key="idx">
                                                    <td class="font-weight-bold text-dark">{{ item.Measure }}</td>
                                                    <td>{{ item.Stipulate }}</td>
                                                </tr>
                                            </tbody>
                                        </table>
                                    </div>
                                </div>
                            </div>

                            <!-- 3. 車輛運輸作業 -->
                            <div v-show="preventSubTab === 3" class="card-modern">
                                <div class="card-modern-header">
                                    <h5 class="card-modern-title"><i class="fas fa-truck text-warning"></i> 車輛運輸作業防制措施</h5>
                                    <span class="badge badge-light border">{{ (prevents.Prevent3 || []).length }} 筆</span>
                                </div>
                                <div class="card-modern-body p-0">
                                    <div v-if="!prevents.Prevent3 || prevents.Prevent3.length === 0" class="text-center py-4 text-muted">無車輛運輸防制設施申報資料</div>
                                    <div v-else class="table-responsive">
                                        <table class="table table-custom">
                                            <thead>
                                                <tr>
                                                    <th style="width: 35%;">防制措施</th>
                                                    <th>防制規定</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                <tr v-for="(item, idx) in prevents.Prevent3" :key="idx">
                                                    <td class="font-weight-bold text-dark">{{ item.Measure }}</td>
                                                    <td>{{ item.Stipulate }}</td>
                                                </tr>
                                            </tbody>
                                        </table>
                                    </div>
                                </div>
                            </div>

                            <!-- 4. 製程、操作或裝卸作業 -->
                            <div v-show="preventSubTab === 4" class="card-modern">
                                <div class="card-modern-header">
                                    <h5 class="card-modern-title"><i class="fas fa-industry text-danger"></i> 製程、操作或裝卸作業防制措施</h5>
                                    <span class="badge badge-light border">{{ (prevents.Prevent4 || []).length }} 筆</span>
                                </div>
                                <div class="card-modern-body p-0">
                                    <div v-if="!prevents.Prevent4 || prevents.Prevent4.length === 0" class="text-center py-4 text-muted">無製程裝卸防制設施申報資料</div>
                                    <div v-else class="table-responsive">
                                        <table class="table table-custom">
                                            <thead>
                                                <tr>
                                                    <th style="width: 35%;">防制措施</th>
                                                    <th>防制規定</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                <tr v-for="(item, idx) in prevents.Prevent4" :key="idx">
                                                    <td class="font-weight-bold text-dark">{{ item.Measure }}</td>
                                                    <td>{{ item.Stipulate }}</td>
                                                </tr>
                                            </tbody>
                                        </table>
                                    </div>
                                </div>
                            </div>

                            <!-- 5. 裸露區域 -->
                            <div v-show="preventSubTab === 5" class="card-modern">
                                <div class="card-modern-header">
                                    <h5 class="card-modern-title"><i class="fas fa-mountain text-secondary"></i> 裸露區域防制措施</h5>
                                    <span class="badge badge-light border">{{ (prevents.Prevent5 || []).length }} 筆</span>
                                </div>
                                <div class="card-modern-body p-0">
                                    <div v-if="!prevents.Prevent5 || prevents.Prevent5.length === 0" class="text-center py-4 text-muted">無裸露區域防制設施申報資料</div>
                                    <div v-else class="table-responsive">
                                        <table class="table table-custom">
                                            <thead>
                                                <tr>
                                                    <th style="width: 35%;">防制措施</th>
                                                    <th>防制規定</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                <tr v-for="(item, idx) in prevents.Prevent5" :key="idx">
                                                    <td class="font-weight-bold text-dark">{{ item.Measure }}</td>
                                                    <td>{{ item.Stipulate }}</td>
                                                </tr>
                                            </tbody>
                                        </table>
                                    </div>
                                </div>
                            </div>

                            <!-- 6. 車輛通行路徑及區域 -->
                            <div v-show="preventSubTab === 6" class="card-modern">
                                <div class="card-modern-header">
                                    <h5 class="card-modern-title"><i class="fas fa-road text-info"></i> 車輛通行路徑及區域防制措施</h5>
                                    <span class="badge badge-light border">{{ (prevents.Prevent6 || []).length }} 筆</span>
                                </div>
                                <div class="card-modern-body p-0">
                                    <div v-if="!prevents.Prevent6 || prevents.Prevent6.length === 0" class="text-center py-4 text-muted">無通行路徑防制設施申報資料</div>
                                    <div v-else class="table-responsive">
                                        <table class="table table-custom">
                                            <thead>
                                                <tr>
                                                    <th style="width: 35%;">防制措施</th>
                                                    <th>防制規定</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                <tr v-for="(item, idx) in prevents.Prevent6" :key="idx">
                                                    <td class="font-weight-bold text-dark">{{ item.Measure }}</td>
                                                    <td>{{ item.Stipulate }}</td>
                                                </tr>
                                            </tbody>
                                        </table>
                                    </div>
                                </div>
                            </div>

                            <!-- 7. 自主管理 -->
                            <div v-show="preventSubTab === 7" class="card-modern">
                                <div class="card-modern-header">
                                    <h5 class="card-modern-title"><i class="fas fa-broom text-success"></i> 自主管理洗掃路段</h5>
                                    <span class="badge badge-light border">{{ (prevents.Prevent7 || []).length }} 筆</span>
                                </div>
                                <div class="card-modern-body p-0">
                                    <div v-if="!prevents.Prevent7 || prevents.Prevent7.length === 0" class="text-center py-4 text-muted">無自主管理洗掃申報資料</div>
                                    <div v-else class="table-responsive">
                                        <table class="table table-custom">
                                            <thead>
                                                <tr>
                                                    <th>洗掃路段</th>
                                                    <th>洗掃方式</th>
                                                    <th class="text-right">洗掃長度(m)</th>
                                                    <th class="text-right">洗掃次數</th>
                                                    <th>洗掃頻率</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                <tr v-for="(item, idx) in prevents.Prevent7" :key="idx">
                                                    <td class="font-weight-bold text-dark">{{ item.CleanRoad }}</td>
                                                    <td>{{ item.CleanType || '-' }}</td>
                                                    <td class="text-right font-weight-bold">{{ item.CleanDis || '0' }}</td>
                                                    <td class="text-right">{{ item.CleanTimes || '0' }}</td>
                                                    <td>{{ item.CleanFrequency || '-' }}</td>
                                                </tr>
                                            </tbody>
                                        </table>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- ================= Tab 4: 派工與異動紀錄 ================= -->
                        <div v-show="currentTab === 'history'">
                            <!-- 派遣稽查歷程 -->
                            <div class="card-modern mb-3">
                                <div class="card-modern-header">
                                    <h5 class="card-modern-title"><i class="fas fa-paper-plane text-primary"></i> 派遣稽查紀錄</h5>
                                    <span class="badge badge-light border">{{ missions.length }} 次派工</span>
                                </div>
                                <div class="card-modern-body p-0">
                                    <div v-if="missions.length === 0" class="text-center py-4 text-muted">尚無派工稽查紀錄</div>
                                    <div v-else class="table-responsive">
                                        <table class="table table-custom">
                                            <thead>
                                                <tr>
                                                    <th>派工日期</th>
                                                    <th>派工原因</th>
                                                    <th>稽查結案案號</th>
                                                    <th>狀態</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                <tr v-for="(m, mIdx) in missions" :key="mIdx">
                                                    <td class="font-weight-bold text-dark">{{ m.SendDate }}</td>
                                                    <td>{{ m.pReason || '無指定原因' }}</td>
                                                    <td>
                                                        <span v-if="m.Finish_INV_NO" class="badge badge-success">{{ m.Finish_INV_NO }}</span>
                                                        <span v-else class="text-muted">未完成/待稽查</span>
                                                    </td>
                                                    <td>
                                                        <span v-if="m.Cancel_Date" class="badge badge-secondary">已取消</span>
                                                        <span v-else-if="m.Finish_INV_NO" class="badge badge-success">已結案</span>
                                                        <span v-else class="badge badge-warning text-dark">處理中</span>
                                                    </td>
                                                </tr>
                                            </tbody>
                                        </table>
                                    </div>
                                </div>
                            </div>

                            <!-- 基本資料異動紀錄 -->
                            <div class="card-modern">
                                <div class="card-modern-header">
                                    <h5 class="card-modern-title"><i class="fas fa-history text-secondary"></i> 場所歷史異動紀錄</h5>
                                    <span class="badge badge-light border">{{ history.length }} 筆異動</span>
                                </div>
                                <div class="card-modern-body p-0">
                                    <div v-if="history.length === 0" class="text-center py-4 text-muted">尚無歷史異動紀錄</div>
                                    <div v-else class="table-responsive">
                                        <table class="table table-custom">
                                            <thead>
                                                <tr>
                                                    <th>異動時間</th>
                                                    <th>操作人員</th>
                                                    <th>場所名稱</th>
                                                    <th>廠址 / 聯絡人 / 電話</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                <tr v-for="(h, hIdx) in history" :key="hIdx">
                                                    <td class="font-weight-bold" style="white-space: nowrap;">{{ h.Edit_Date }}</td>
                                                    <td>
                                                        <span class="badge badge-light border">{{ h.Edit_UserName || '系統作業' }}</span>
                                                    </td>
                                                    <td class="font-weight-bold text-dark">{{ h.FAC_NAME || '-' }}</td>
                                                    <td class="small text-muted">
                                                        <span v-if="h.ADDR"><i class="fas fa-map-marker-alt mr-1 text-danger"></i>{{ h.ADDR }}</span>
                                                        <span v-if="h.Content_Name" class="ml-2"><i class="fas fa-user mr-1 text-secondary"></i>{{ h.Content_Name }}</span>
                                                        <span v-if="h.TEL" class="ml-2"><i class="fas fa-phone mr-1 text-success"></i>{{ h.TEL }}</span>
                                                    </td>
                                                </tr>
                                            </tbody>
                                        </table>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </main>

        <!-- 4. 手機端底部常駐浮動動作列 (Sticky Bottom Bar) -->
        <div class="mobile-bottom-bar no-print">
            <button v-if="main.TEL" type="button" class="btn btn-outline-success" v-on:click="callPhone">
                <i class="fas fa-phone-alt mr-1"></i> 致電場所
            </button>
            <button v-if="main.Lat && main.Lng" type="button" class="btn btn-primary" v-on:click="openGoogleMaps">
                <i class="fas fa-location-arrow mr-1"></i> Google導航
            </button>
            <button type="button" class="btn btn-light border" v-on:click="goBack">
                <i class="fas fa-arrow-left mr-1"></i> 返回
            </button>
        </div>

        <!-- 5. 快速編輯基本資料彈窗 (Modal) -->
        <div class="modal fade" id="editModal" tabindex="-1" role="dialog" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered" role="document">
                <div class="modal-content">
                    <div class="modal-header bg-light">
                        <h5 class="modal-title font-weight-bold">
                            <i class="fas fa-edit mr-1 text-primary"></i> 編輯場所基本聯絡資料
                        </h5>
                        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                            <span aria-hidden="true">&times;</span>
                        </button>
                    </div>
                    <div class="modal-body">
                        <div class="form-group">
                            <label class="font-weight-bold">公私場所名稱</label>
                            <input type="text" v-model="editForm.FacName" class="form-control" />
                        </div>
                        <div class="form-group">
                            <label class="font-weight-bold">廠址地址</label>
                            <input type="text" v-model="editForm.Addr" class="form-control" />
                        </div>
                        <div class="form-row">
                            <div class="form-group col-md-6">
                                <label class="font-weight-bold">聯絡人姓名</label>
                                <input type="text" v-model="editForm.ContentName" class="form-control" />
                            </div>
                            <div class="form-group col-md-6">
                                <label class="font-weight-bold">聯絡電話</label>
                                <input type="text" v-model="editForm.Tel" class="form-control" />
                            </div>
                        </div>
                        <div class="form-group">
                            <label class="font-weight-bold">作業備註</label>
                            <textarea v-model="editForm.WorkMemo" class="form-control" rows="3" placeholder="請輸入重要作業說明或補充..."></textarea>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-dismiss="modal">取消</button>
                        <button type="button" class="btn btn-primary" :disabled="saving" v-on:click="submitEditForm">
                            <i v-if="saving" class="fas fa-spinner fa-spin mr-1"></i>
                            {{ saving ? '儲存中...' : '確認儲存' }}
                        </button>
                    </div>
                </div>
            </div>
        </div>

        <!-- 6. 圖片放大檢視 Modal -->
        <div class="modal fade" id="imageModal" tabindex="-1" role="dialog" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered modal-lg" role="document">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title font-weight-bold">{{ modalImageTitle }}</h5>
                        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                            <span aria-hidden="true">&times;</span>
                        </button>
                    </div>
                    <div class="modal-body p-0 text-center bg-dark">
                        <img :src="modalImageUrl" class="img-fluid" style="max-height: 80vh;" :alt="modalImageTitle" />
                    </div>
                    <div class="modal-footer">
                        <a :href="modalImageUrl" target="_blank" class="btn btn-outline-primary btn-sm">新分頁開啟原始大圖</a>
                        <button type="button" class="btn btn-secondary btn-sm" data-dismiss="modal">關閉</button>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- 本地端核心前端庫 (禁止外部 CDN) -->
    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>
    <script src="../Scripts/jquery-3.6.0.min.js"></script>
    <script src="../Scripts/bootstrap.bundle.min.js"></script>
    <script src="../Scripts/leaflet/leaflet.js"></script>

    <script>
        (function () {
            const { createApp, markRaw } = Vue;

            createApp({
                data() {
                    return {
                        loading: true,
                        errorMessage: '',
                        saving: false,

                        // 場所基本資料
                        main: {},
                        devices: [],
                        processes: [],
                        prevents: {},
                        files: [],
                        missions: [],
                        history: [],

                        // 前端互動狀態
                        currentTab: 'devices',
                        preventSubTab: 1,
                        deviceSearch: '',
                        isMapCollapsed: false,

                        // 編輯表單
                        editForm: {
                            FacId: '',
                            FacName: '',
                            Addr: '',
                            Tel: '',
                            ContentName: '',
                            WorkMemo: ''
                        },

                        // 圖檔彈窗
                        modalImageUrl: '',
                        modalImageTitle: '',

                        // 列印時間字串
                        printTimeStr: new Date().toLocaleString()
                    };
                },
                computed: {
                    // 是否已解除納管
                    isDelisted() {
                        return this.main && this.main.Operating_Date && this.main.Operating_Date.trim() !== '';
                    },
                    // 時間軸進度條百分比
                    stepperProgress() {
                        if (this.isDelisted) return 100;
                        if (this.main && this.main.Accept_Date && this.main.Accept_Date.trim() !== '') return 100;
                        return 50;
                    },
                    // 設備搜尋過濾
                    filteredDevices() {
                        if (!this.deviceSearch) return this.devices;
                        const kw = this.deviceSearch.trim().toLowerCase();
                        return this.devices.filter(d => {
                            const name = (d.Device_Name || '').toLowerCase();
                            const no = (d.Device_NO || '').toLowerCase();
                            const sub = (d.Store_substance || '').toLowerCase();
                            return name.indexOf(kw) >= 0 || no.indexOf(kw) >= 0 || sub.indexOf(kw) >= 0;
                        });
                    }
                },
                mounted() {
                    // 原生隔離 Leaflet 實例，禁止放在 Vue 響應式中避免 project 報錯
                    this.leafletMap = null;
                    this.markerGroup = null;

                    this.loadDetail();
                },
                methods: {
                    // 取得 URL 查詢參數
                    getUrlParam(name) {
                        const reg = new RegExp('(^|&)' + name + '=([^&]*)(&|$)', 'i');
                        const r = window.location.search.substr(1).match(reg);
                        return r !== null ? decodeURIComponent(r[2]) : null;
                    },

                    // 載入場所完整詳情
                    loadDetail() {
                        this.loading = true;
                        this.errorMessage = '';

                        const id1 = this.getUrlParam('id1') || this.getUrlParam('id') || this.getUrlParam('facId') || '';
                        const id2 = this.getUrlParam('id2') || this.getUrlParam('chk') || this.getUrlParam('token') || '';

                        if (!id1) {
                            this.loading = false;
                            this.errorMessage = '網址未提供場所代號參數 (?id1=)';
                            return;
                        }

                        let url = 'FAC_Detail.aspx?action=getdetail&id1=' + encodeURIComponent(id1);
                        if (id2) {
                            url += '&id2=' + encodeURIComponent(id2);
                        }

                        axios.get(url)
                            .then(res => {
                                this.loading = false;
                                if (res.data && res.data.Success) {
                                    this.main = res.data.Main || {};
                                    this.devices = res.data.Devices || [];
                                    this.processes = res.data.Processes || [];
                                    this.prevents = res.data.Prevents || {};
                                    this.files = res.data.Files || [];
                                    this.missions = res.data.Missions || [];
                                    this.history = res.data.History || [];

                                    // 初始化地圖 (DOM 渲染後)
                                    this.$nextTick(() => {
                                        this.initMap();
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

                    // 初始化 Leaflet 地圖 (純原生 markRaw 隔離)
                    initMap() {
                        const mapContainer = document.getElementById('map');
                        if (!mapContainer) return;

                        if (this.leafletMap) {
                            try { this.leafletMap.remove(); } catch (e) { }
                            this.leafletMap = null;
                        }

                        // 預設以新北市政府或大門座標為中心
                        const defaultLat = (this.main.Lat && this.main.Lat > 0) ? this.main.Lat : 25.0123;
                        const defaultLng = (this.main.Lng && this.main.Lng > 0) ? this.main.Lng : 121.4657;
                        const defaultZoom = (this.main.Lat && this.main.Lat > 0) ? 16 : 12;

                        const mapInstance = L.map('map', {
                            center: [defaultLat, defaultLng],
                            zoom: defaultZoom,
                            zoomControl: true
                        });

                        // 臺灣通用電子地圖 WMTS 服務
                        const emap = L.tileLayer('https://wmts.nlsc.gov.tw/wmts/EMAP/default/GoogleMapsCompatible/{z}/{y}/{x}', {
                            maxZoom: 19,
                            attribution: '&copy; 內政部國土測繪中心'
                        }).addTo(mapInstance);

                        // 衛星影像航照圖
                        const photo = L.tileLayer('https://wmts.nlsc.gov.tw/wmts/PHOTO2/default/GoogleMapsCompatible/{z}/{y}/{x}', {
                            maxZoom: 19,
                            attribution: '&copy; 國土測繪中心'
                        });

                        L.control.layers({ '臺灣通用電子地圖': emap, '正射衛星影像': photo }, null, { position: 'topright' }).addTo(mapInstance);

                        this.leafletMap = markRaw(mapInstance);
                        this.markerGroup = markRaw(L.layerGroup().addTo(mapInstance));

                        // 若有座標，標記 Pin
                        if (this.main.Lat && this.main.Lng) {
                            this.addFacilityMarker(this.main.Lat, this.main.Lng);
                        }
                    },

                    // 標記工廠大門 Pin
                    addFacilityMarker(lat, lng) {
                        if (!this.markerGroup) return;
                        this.markerGroup.clearLayers();

                        const customIcon = L.divIcon({
                            className: 'custom-fac-marker',
                            html: '<div class="marker-pin-fac"><i class="fas fa-industry marker-icon-fac"></i></div>',
                            iconSize: [34, 34],
                            iconAnchor: [17, 34],
                            popupAnchor: [0, -32]
                        });

                        const popupHtml = `
                            <div style="font-size: 13px; line-height: 1.5; min-width: 180px;">
                                <strong style="color: #0d9488;">${this.main.FAC_NAME}</strong><br />
                                <span style="color: #64748b;">管編：${this.main.C_NO}</span><br />
                                <span>地址：${this.main.ADDR || '未填寫'}</span>
                            </div>
                        `;

                        const marker = L.marker([lat, lng], { icon: customIcon })
                            .bindPopup(popupHtml)
                            .addTo(this.markerGroup);

                        marker.openPopup();
                    },

                    // GPS 定位目前位置
                    locateUser() {
                        if (!navigator.geolocation) {
                            alert('您的瀏覽器不支援 GPS 定位功能。');
                            return;
                        }
                        navigator.geolocation.getCurrentPosition(
                            pos => {
                                const lat = pos.coords.latitude;
                                const lng = pos.coords.longitude;
                                if (this.leafletMap) {
                                    this.leafletMap.setView([lat, lng], 16);
                                    L.circleMarker([lat, lng], {
                                        radius: 8,
                                        fillColor: '#0284c7',
                                        color: '#ffffff',
                                        weight: 2,
                                        fillOpacity: 0.9
                                    }).addTo(this.leafletMap).bindPopup('您的目前位置').openPopup();
                                }
                            },
                            err => {
                                alert('無法取得目前位置：' + err.message);
                            },
                            { enableHighAccuracy: true, timeout: 8000 }
                        );
                    },

                    // 重設全景視角
                    resetMapView() {
                        if (!this.leafletMap) return;
                        if (this.main.Lat && this.main.Lng) {
                            this.leafletMap.setView([this.main.Lat, this.main.Lng], 16);
                        } else {
                            this.leafletMap.setView([25.0123, 121.4657], 12);
                        }
                    },

                    // 手機版摺疊地圖
                    toggleMapCollapse() {
                        this.isMapCollapsed = !this.isMapCollapsed;
                        this.$nextTick(() => {
                            if (this.leafletMap) {
                                this.leafletMap.invalidateSize();
                            }
                        });
                    },

                    // 開啟 Google 地圖導航
                    openGoogleMaps() {
                        if (this.main.Lat && this.main.Lng) {
                            const url = 'https://www.google.com/maps/dir/?api=1&destination=' + this.main.Lat + ',' + this.main.Lng;
                            window.open(url, '_blank');
                        } else if (this.main.ADDR) {
                            const url = 'https://www.google.com/maps/dir/?api=1&destination=' + encodeURIComponent(this.main.ADDR);
                            window.open(url, '_blank');
                        } else {
                            alert('本公私場所尚未登錄座標或地址。');
                        }
                    },

                    // 撥打場所電話 (外勤手機一鍵致電)
                    callPhone() {
                        if (this.main.TEL) {
                            window.location.href = 'tel:' + this.main.TEL;
                        }
                    },

                    // 一鍵複製文字
                    copyText(text) {
                        if (!text) return;
                        if (navigator.clipboard && navigator.clipboard.writeText) {
                            navigator.clipboard.writeText(text).then(() => {
                                alert('已複製地址至剪貼簿：' + text);
                            });
                        } else {
                            const input = document.createElement('input');
                            input.value = text;
                            document.body.appendChild(input);
                            input.select();
                            document.execCommand('copy');
                            document.body.removeChild(input);
                            alert('已複製地址至剪貼簿：' + text);
                        }
                    },

                    // 開啟編輯 Modal
                    openEditModal() {
                        this.editForm = {
                            FacId: this.main.FAC_ID || '',
                            FacName: this.main.FAC_NAME || '',
                            Addr: this.main.ADDR || '',
                            Tel: this.main.TEL || '',
                            ContentName: this.main.Content_Name || '',
                            WorkMemo: this.main.Work_Memo || ''
                        };
                        $('#editModal').modal('show');
                    },

                    // 送出編輯表單
                    submitEditForm() {
                        if (!this.editForm.FacId) return;
                        this.saving = true;

                        axios.post('FAC_Detail.aspx?action=savebasic', this.editForm)
                            .then(res => {
                                this.saving = false;
                                if (res.data && res.data.Success) {
                                    alert(res.data.Message || '場所基本資料更新成功！');
                                    $('#editModal').modal('hide');
                                    this.loadDetail();
                                } else {
                                    alert('更新失敗：' + (res.data.Message || '未知錯誤'));
                                }
                            })
                            .catch(err => {
                                this.saving = false;
                                alert('儲存發生異常：' + (err.message || err));
                            });
                    },

                    // 預覽圖片大圖 Modal
                    previewImage(file) {
                        this.modalImageUrl = file.FileUrl;
                        this.modalImageTitle = file.FileName + ' (' + file.Category + ')';
                        $('#imageModal').modal('show');
                    },

                    // 列印公私場所
                    printCase() {
                        this.printTimeStr = new Date().toLocaleString();
                        window.print();
                    },

                    // 返回上一頁清單
                    goBack() {
                        if (document.referrer && document.referrer.indexOf('FAC_List.aspx') >= 0) {
                            window.history.back();
                        } else {
                            window.location.href = 'FAC_List.aspx';
                        }
                    },

                    // 百分比格式化
                    formatPercent(val) {
                        if (val === null || val === undefined || val === '') return '-';
                        const num = parseFloat(val);
                        if (isNaN(num)) return '-';
                        return (num * (num <= 1 ? 100 : 1)).toFixed(0) + '%';
                    }
                }
            }).mount('#facApp');
        })();
    </script>
</body>
</html>
