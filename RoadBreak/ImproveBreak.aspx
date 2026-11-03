<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="ImproveBreak.aspx.cs" Inherits="NTPC_FEC.RoadBreak.ImproveBreak" %>
<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定逸散源管理平台 - 道路髒污破損處理回報</title>
    
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

        /* 頂部導覽列 (新北經典天藍與現代陰影，右上角保持清爽無多餘按鈕) */
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
            border: 1px solid rgba(255, 255, 255, 0.35);
            color: #ffffff !important;
            font-size: 0.88rem;
            font-weight: 600;
            cursor: pointer;
            border-radius: 8px;
            display: inline-flex; align-items: center; justify-content: center; gap: 6px;
            padding: 6px 14px;
            text-decoration: none !important;
            transition: all 0.2s ease;
        }
        .nav-btn:hover {
            background: rgba(255, 255, 255, 0.3);
            color: #ffffff !important;
            text-decoration: none !important;
            transform: translateY(-1px);
        }

        /* 主容器 */
        .main-container {
            max-width: 1280px;
            margin: 16px auto 60px auto;
            padding: 0 16px;
        }

        /* 專案標準現代卡片 (card-modern) */
        .report-section-card {
            background: var(--surface);
            border: 1px solid var(--border-color);
            border-radius: 12px;
            margin-bottom: 20px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05), 0 4px 12px rgba(15, 23, 42, 0.05);
            overflow: hidden;
        }

        /* 卡片標題列 (白底、深藍字、配專屬圖示) */
        .section-banner-title {
            background: #ffffff;
            color: var(--brand-navy);
            font-weight: 700;
            font-size: 1.05rem;
            padding: 14px 20px;
            border-bottom: 1px solid var(--border-color);
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-wrap: wrap;
            gap: 10px;
            letter-spacing: 0.5px;
        }

        /* 路平報馬仔三合一智慧連動面板 */
        .rdm-sync-panel {
            background: linear-gradient(180deg, #f0f9ff 0%, #ffffff 100%);
            border: 2px solid #bae6fd;
            border-radius: 12px;
            padding: 16px 20px;
            margin-bottom: 20px;
            box-shadow: 0 2px 10px rgba(2, 132, 199, 0.08);
        }
        .rdm-sync-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-wrap: wrap;
            gap: 8px;
            margin-bottom: 12px;
        }
        .rdm-sync-title {
            font-weight: 800;
            color: #0369a1;
            font-size: 1rem;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .rdm-sync-controls {
            display: flex;
            align-items: center;
            flex-wrap: wrap;
            gap: 8px;
        }
        .rdm-id-input {
            flex: 1;
            min-width: 240px;
            border: 1.5px solid #7dd3fc;
            border-radius: 8px;
            padding: 8px 12px;
            font-size: 0.94rem;
            font-weight: 600;
            color: #0f172a;
            background: #ffffff;
        }
        .rdm-id-input:focus {
            border-color: var(--brand-blue);
            outline: none;
            box-shadow: 0 0 0 3px rgba(2, 132, 199, 0.18);
        }

        /* 欄位表格排版 (乾淨淺灰底標題，純白內容) */
        .report-table {
            width: 100%;
            border-collapse: collapse;
        }

        .report-table tr {
            border-bottom: 1px solid var(--border-color);
        }

        .report-table td {
            padding: 12px 18px;
            font-size: 0.94rem;
            vertical-align: middle;
        }

        .report-table td.cell-label {
            width: 160px;
            background-color: #f8fafc;
            color: #334155;
            font-weight: 700;
            border-right: 1px solid var(--border-color);
            text-align: left;
            line-height: 1.4;
        }

        .report-table td.cell-val {
            background-color: #ffffff;
            color: var(--text-main);
        }

        .report-table td.cell-val-highlight {
            font-weight: 700;
            color: var(--brand-blue);
        }

        /* 輸入控制項樣式 */
        .form-input-custom {
            border: 1px solid #cbd5e1;
            background-color: #ffffff;
            padding: 8px 12px;
            font-size: 0.94rem;
            border-radius: 6px;
            color: var(--text-main);
            transition: all 0.2s ease;
        }
        .form-input-custom:focus {
            border-color: var(--brand-blue);
            background-color: #ffffff;
            outline: none;
            box-shadow: 0 0 0 3px rgba(2, 132, 199, 0.15);
        }

        /* 內嵌地圖 */
        #embedMap {
            width: 100%;
            height: 260px;
            border-radius: 8px;
            border: 1px solid var(--border-color);
            margin-top: 8px;
            z-index: 1;
        }

        /* 完工照片卡片網格 */
        .photos-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
            gap: 12px;
            margin-top: 10px;
        }

        .photo-slot {
            border: 1px solid #cbd5e1;
            border-radius: 6px;
            overflow: hidden;
            background: #ffffff;
            position: relative;
        }

        .photo-slot img {
            width: 100%;
            height: 140px;
            object-fit: cover;
            cursor: pointer;
        }

        .photo-slot-bar {
            padding: 6px 8px;
            background: #f8fafc;
            display: flex;
            align-items: center;
            justify-content: space-between;
            font-size: 0.82rem;
            font-weight: 700;
            border-top: 1px solid #e2e8f0;
        }

        .btn-del-img {
            color: #dc2626;
            background: none;
            border: none;
            cursor: pointer;
            padding: 2px 6px;
            border-radius: 4px;
        }
        .btn-del-img:hover {
            background: #fee2e2;
        }

        .upload-placeholder {
            height: 140px;
            border: 2px dashed #0284c7;
            background: #f0f9ff;
            border-radius: 6px;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            transition: all 0.2s;
        }
        .upload-placeholder:hover {
            background: #e0f2fe;
        }

        /* 智慧判讀：正式結案 vs 建議持續追蹤卡片 */
        .follow-choice-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 12px;
        }
        .follow-option-card {
            border: 2px solid #cbd5e1;
            border-radius: 10px;
            padding: 14px 16px;
            cursor: pointer;
            background: #ffffff;
            transition: all 0.2s ease;
            display: flex;
            align-items: flex-start;
            gap: 12px;
        }
        .follow-option-card:hover {
            border-color: #94a3b8;
            background: #f8fafc;
        }
        .follow-option-card.active-close {
            border-color: #10b981;
            background: #f0fdf4;
            box-shadow: 0 0 0 3px rgba(16, 185, 129, 0.12);
        }
        .follow-option-card.active-follow {
            border-color: #0284c7;
            background: #f0f9ff;
            box-shadow: 0 0 0 3px rgba(2, 132, 199, 0.15);
        }

        /* 燈箱與通用 Modal */
        .lightbox-modal {
            position: fixed;
            top: 0; left: 0; right: 0; bottom: 0;
            background: rgba(0, 0, 0, 0.88);
            z-index: 1090;
            display: flex; align-items: center; justify-content: center;
            padding: 20px;
        }
        .lightbox-img {
            max-width: 95vw;
            max-height: 90vh;
            border-radius: 6px;
            box-shadow: 0 8px 30px rgba(0, 0, 0, 0.5);
        }
        .lightbox-close {
            position: absolute; top: 16px; right: 16px;
            background: rgba(255, 255, 255, 0.25);
            color: #ffffff;
            border: none; border-radius: 50%;
            width: 40px; height: 40px;
            font-size: 1.4rem; cursor: pointer;
            display: flex; align-items: center; justify-content: center;
        }

        .back-modal-backdrop {
            position: fixed; top: 0; left: 0; right: 0; bottom: 0;
            background: rgba(15, 23, 42, 0.65);
            z-index: 1060;
            display: flex; align-items: center; justify-content: center;
            padding: 16px;
        }
        .back-modal-dialog {
            width: 95vw; max-width: 600px;
            background: #ffffff;
            border-radius: 10px;
            box-shadow: 0 10px 25px rgba(0, 0, 0, 0.3);
            overflow: hidden;
        }
        .back-modal-header {
            background: #dc2626; color: #ffffff;
            padding: 12px 18px;
            display: flex; align-items: center; justify-content: space-between;
        }
        .parse-modal-header {
            background: linear-gradient(135deg, #0099e5 0%, #0284c7 100%);
            color: #ffffff;
            padding: 12px 18px;
            display: flex; align-items: center; justify-content: space-between;
        }
        .back-modal-body { padding: 18px; }
        .back-modal-footer {
            padding: 12px 18px;
            background: #f8fafc;
            border-top: 1px solid #e2e8f0;
            display: flex; align-items: center; justify-content: flex-end; gap: 8px;
        }

        /* 專用響應式輔助類別 */
        .time-input-group {
            display: flex;
            align-items: center;
            gap: 8px;
            width: 100%;
        }

        .dimension-row-mobile {
            display: flex;
            align-items: center;
            flex-wrap: wrap;
            gap: 12px;
        }

        /* =========================================================
           小尺寸螢幕 RWD 現代化極致體驗 (iPhone 16 / 440px / 平板)
           ========================================================= */
        @media screen and (max-width: 767.98px) {
            body {
                padding-bottom: 78px !important;
            }

            .top-navbar {
                height: 52px !important;
                padding: 0 12px !important;
            }

            .top-navbar h1 {
                font-size: 0.95rem !important;
                white-space: nowrap !important;
                overflow: hidden !important;
                text-overflow: ellipsis !important;
            }

            .main-container {
                margin: 8px auto 80px auto !important;
                padding: 0 6px !important;
            }

            .rdm-sync-panel {
                padding: 12px !important;
                margin-bottom: 14px !important;
            }

            .rdm-sync-controls {
                flex-direction: column !important;
                align-items: stretch !important;
            }

            .rdm-id-input {
                width: 100% !important;
                min-width: 100% !important;
                height: 42px !important;
                font-size: 16px !important;
            }

            .rdm-sync-controls .btn {
                width: 100% !important;
                min-height: 42px !important;
                display: flex !important;
                align-items: center !important;
                justify-content: center !important;
            }

            .follow-choice-grid {
                grid-template-columns: 1fr !important;
            }

            .report-section-card {
                border-radius: 12px !important;
                margin-bottom: 14px !important;
                box-shadow: 0 1px 4px rgba(0, 0, 0, 0.05) !important;
                border: 1px solid var(--border-color) !important;
            }

            .section-banner-title {
                font-size: 1rem !important;
                padding: 12px 14px !important;
                letter-spacing: 0.5px !important;
            }

            /* 欄位表格轉單欄直式卡片 (Full-width Mobile Stack) */
            .report-table,
            .report-table tbody,
            .report-table tr,
            .report-table td,
            .report-table th {
                display: block !important;
                width: 100% !important;
                box-sizing: border-box !important;
            }

            .report-table tr {
                border-bottom: 1px solid var(--border-color) !important;
                background-color: #ffffff !important;
            }

            .report-table tr:last-child {
                border-bottom: none !important;
            }

            .report-table td.cell-label {
                width: 100% !important;
                min-width: 100% !important;
                border-right: none !important;
                border-bottom: 1px solid #f1f5f9 !important;
                background-color: #f8fafc !important;
                color: #1e293b !important;
                font-size: 0.95rem !important;
                font-weight: 700 !important;
                padding: 10px 14px !important;
            }

            .report-table td.cell-val {
                width: 100% !important;
                min-width: 100% !important;
                padding: 12px 14px !important;
            }

            .report-table td.cell-val[style] {
                width: 100% !important;
            }

            .form-input-custom,
            select.form-input-custom,
            input.form-input-custom {
                width: 100% !important;
                min-width: 100% !important;
                max-width: 100% !important;
                height: 44px !important;
                font-size: 16px !important;
            }

            .form-input-custom[style] {
                width: 100% !important;
            }

            textarea.form-input-custom {
                height: auto !important;
                min-height: 110px !important;
            }

            /* 時間輸入組手機版自適應 */
            .time-input-group {
                display: flex !important;
                gap: 6px !important;
                width: 100% !important;
            }

            .time-input-group input {
                flex: 1 !important;
                min-width: 0 !important;
                width: auto !important;
            }

            .time-input-group button {
                flex-shrink: 0 !important;
                height: 44px !important;
                padding: 0 12px !important;
                font-size: 14px !important;
                font-weight: 600 !important;
                white-space: nowrap !important;
            }

            /* 尺寸長寬共幾處在手機版均分網格 */
            .dimension-row-mobile {
                display: grid !important;
                grid-template-columns: 1fr 1fr 1fr !important;
                gap: 8px !important;
                width: 100% !important;
                align-items: center !important;
            }

            .dimension-item {
                display: flex;
                align-items: center;
                gap: 4px;
                min-width: 0;
            }

            .dimension-item input {
                height: 42px !important;
                padding: 4px !important;
                font-size: 15px !important;
                min-width: 0 !important;
                flex: 1 !important;
            }

            /* 完工照片網格手機端 2 欄排列 */
            .photos-grid {
                grid-template-columns: repeat(2, 1fr) !important;
                gap: 8px !important;
            }

            .photo-slot,
            .upload-placeholder {
                height: 120px !important;
            }

            /* 手機端底部常駐懸浮動作列 (Mobile Sticky Action Bar) */
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
                padding: 10px 6px;
                border-radius: 8px;
                font-size: 14px;
                display: flex;
                align-items: center;
                justify-content: center;
                min-height: 42px;
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
    <div id="improveApp" v-cloak>
        <!-- 頂部導覽列 (右上角保持清爽無多餘按鈕) -->
        <header class="top-navbar">
            <div class="d-flex align-items-center">
                <a :href="'BreakDetail.aspx?id=' + encodeURIComponent(breakId)" class="nav-btn mr-2" title="返回案件檢視">
                    <i class="fas fa-arrow-left"></i>
                    <span class="d-none d-sm-inline">返回明細</span>
                </a>
                <h1 class="h6 mb-0 font-weight-bold">
                    <i class="fas fa-tools mr-1 text-warning"></i> 道路髒污破損 - 處理回報與結案追蹤
                </h1>
            </div>
        </header>

        <!-- 主體內容區 -->
        <main class="main-container">
            <!-- 載入中動畫 -->
            <div v-if="loading" class="text-center py-5">
                <i class="fas fa-spinner fa-spin fa-2x text-primary mb-3"></i>
                <div class="text-muted font-weight-bold">正在載入通報案件資料，請稍候...</div>
            </div>

            <!-- 錯誤提示 -->
            <div v-else-if="errorMessage" class="alert alert-danger shadow-sm">
                <i class="fas fa-exclamation-triangle mr-2"></i> {{ errorMessage }}
                <div class="mt-2">
                    <button type="button" class="btn btn-sm btn-outline-danger" v-on:click="loadInitData">重試載入</button>
                    <a :href="'BreakDetail.aspx?id=' + encodeURIComponent(breakId)" class="btn btn-sm btn-secondary ml-2">返回明細</a>
                </div>
            </div>

            <div v-else>
                <!-- ==================== 0. 新北市路平報馬仔系統 — 三合一智慧連動面板 ==================== -->
                <div class="rdm-sync-panel">
                    <div class="rdm-sync-header">
                        <div class="rdm-sync-title">
                            <i class="fas fa-sync-alt text-primary"></i>
                            <span>新北市路平報馬仔系統 — 處理回報與結案回覆智慧帶入</span>
                        </div>
                        <span class="badge badge-info px-2 py-1">自動爬蟲 + 剪貼簿備援 + 外部直連</span>
                    </div>
                    <div class="rdm-sync-controls">
                        <input type="text" class="rdm-id-input" v-model.trim="form.rdmCaseId" v-on:input="onRdmIdInput"
                               placeholder="輸入路平報馬仔編號 (如 2078092) 或直接貼上 SatisfySurvey.aspx?id=... 網址" />
                        <button type="button" class="btn btn-primary font-weight-bold px-3 shadow-sm" :disabled="isFetchingRdm" v-on:click="fetchFromRdm">
                            <i class="fas mr-1" :class="isFetchingRdm ? 'fa-spinner fa-spin' : 'fa-bolt'"></i>
                            {{ isFetchingRdm ? '正在同步路平資料與照片...' : '⚡ 自動抓取路平回報與照片' }}
                        </button>
                        <button type="button" class="btn btn-outline-primary font-weight-bold bg-white px-3" v-on:click="openClipboardParseModal">
                            <i class="fas fa-paste mr-1"></i> 📋 貼上網頁文字智慧解析
                        </button>
                        <a v-if="form.rdmCaseId" :href="'https://rdm.ntpc.gov.tw/ROAD/SatisfySurvey.aspx?id=' + encodeURIComponent(form.rdmCaseId)"
                           target="_blank" rel="noopener" class="btn btn-outline-info font-weight-bold bg-white px-3">
                            <i class="fas fa-external-link-alt mr-1"></i> ↗ 開啟路平網頁 ({{ form.rdmCaseId }})
                        </a>
                    </div>
                    <div v-if="rdmSyncMessage" class="mt-2 small font-weight-bold" :class="rdmSyncSuccess ? 'text-success' : 'text-danger'">
                        <i class="fas mr-1" :class="rdmSyncSuccess ? 'fa-check-circle' : 'fa-info-circle'"></i>
                        {{ rdmSyncMessage }}
                    </div>
                </div>

                <!-- ==================== 1. 通報項目 ==================== -->
                <div class="report-section-card">
                    <div class="section-banner-title">
                        <div>
                            <i class="fas fa-file-alt text-primary mr-2"></i>
                            <span>通報項目</span>
                        </div>
                        <span v-if="form.rdmCaseId" class="badge badge-primary px-2 py-1" style="font-size: 0.82rem;">
                            路平反映編號：{{ form.rdmCaseId }}
                        </span>
                    </div>
                    <table class="report-table">
                        <tr>
                            <td class="cell-label">反映編號</td>
                            <td class="cell-val cell-val-highlight" style="width: 35%;">
                                {{ form.rdmCaseId || caseData.Show_ID }}
                                <span v-if="form.rdmCaseId && caseData.Show_ID && form.rdmCaseId !== caseData.Show_ID" class="text-muted small ml-1">
                                    (本系統案號: {{ caseData.Show_ID }})
                                </span>
                            </td>
                            <td class="cell-label">反映日期</td>
                            <td class="cell-val">{{ caseData.Report_Date || '-' }}</td>
                        </tr>
                        <tr>
                            <td class="cell-label">申訴類別</td>
                            <td class="cell-val">機關查報</td>
                            <td class="cell-label">反映方式</td>
                            <td class="cell-val">行動查報</td>
                        </tr>
                        <tr>
                            <td class="cell-label">反映類別</td>
                            <td class="cell-val font-weight-bold text-primary">{{ caseData.Damage_Category || '路面損壞' }}</td>
                            <td class="cell-label">路面損壞-性質</td>
                            <td class="cell-val font-weight-bold text-danger">
                                {{ caseData.Damage_Type || '坑洞' }}
                                <span v-if="caseData.Damage_Length || caseData.Damage_Width" class="text-muted font-weight-normal ml-2">
                                    長：{{ caseData.Damage_Length || '0' }}m 寬：{{ caseData.Damage_Width || '0' }}m
                                </span>
                            </td>
                        </tr>
                        <tr>
                            <td class="cell-label">損壞型式(PCI)</td>
                            <td class="cell-val">{{ form.pciType || caseData.Damage_Type || '坑洞' }}</td>
                            <td class="cell-label">嚴重程度(PCI)</td>
                            <td class="cell-val">
                                <span class="badge badge-info px-2">{{ form.pciSeverity || '輕' }}</span>
                            </td>
                        </tr>
                        <tr>
                            <td class="cell-label">監造建議修補事項</td>
                            <td class="cell-val text-muted" colspan="3">{{ form.supervisorSuggest || '尚未設定' }}</td>
                        </tr>
                        <tr>
                            <td class="cell-label">反映地點</td>
                            <td class="cell-val" colspan="3">
                                <div class="font-weight-bold text-dark mb-1">
                                    所屬區：{{ caseData.TOWN_NA }} {{ caseData.ROAD_Name }}
                                    <span v-if="caseData.Location_Desc" class="text-secondary font-weight-normal">({{ caseData.Location_Desc }})</span>
                                </div>
                                <div class="small text-muted mb-1 d-flex flex-wrap align-items-center gap-3">
                                    <span>
                                        <i class="fas fa-map-pin text-danger mr-1"></i>
                                        反映地點坐標：X坐標：{{ caseData.S_UTME || '-' }}，Y坐標：{{ caseData.S_UTMN || '-' }}
                                    </span>
                                    <button v-if="caseData.Lat && caseData.Lng" type="button" class="btn btn-xs btn-outline-success btn-sm py-0 px-2" v-on:click="openGoogleStreetView">
                                        <i class="fas fa-street-view mr-1"></i> Google街景圖
                                    </button>
                                </div>

                                <!-- 內嵌地圖展示 -->
                                <div id="embedMap"></div>
                            </td>
                        </tr>
                        <tr>
                            <td class="cell-label">車道</td>
                            <td class="cell-val" style="width: 35%;">{{ caseData.Lane_Info || '全車道' }}</td>
                            <td class="cell-label">方向</td>
                            <td class="cell-val" style="width: 35%;">{{ caseData.Direction || '無法判定' }}</td>
                        </tr>
                        <tr>
                            <td class="cell-label">道路型態</td>
                            <td class="cell-val">{{ caseData.Road_Type || '平面' }}</td>
                            <td class="cell-label">處理單位(公所)</td>
                            <td class="cell-val">{{ form.districtOffice || caseData.District_Office || (caseData.TOWN_NA ? caseData.TOWN_NA + '公所' : '-') }}</td>
                        </tr>
                        <tr>
                            <td class="cell-label">處理單位</td>
                            <td class="cell-val">{{ form.handleUnit || caseData.Handle_Unit || caseData.G_COM_NAME || '健利營造有限公司' }}</td>
                            <td class="cell-label">處理狀態</td>
                            <td class="cell-val">{{ form.handleStatus || caseData.Handle_Status || '機關自行修補' }}</td>
                        </tr>
                        <tr>
                            <td class="cell-label">其他說明</td>
                            <td class="cell-val" colspan="3">{{ caseData.Memo || '無其他說明' }}</td>
                        </tr>
                        <tr>
                            <td class="cell-label">養工處分派說明</td>
                            <td class="cell-val text-muted" colspan="3">
                                {{ form.dispatchMemo || caseData.Dispatch_Memo || caseData.Memo || '無額外分派說明' }}
                            </td>
                        </tr>
                        <!-- 佐證照片縮圖區 -->
                        <tr v-if="evidencePhotos.length > 0">
                            <td class="cell-label">改善前現場照片</td>
                            <td class="cell-val" colspan="3">
                                <div class="d-flex flex-wrap gap-2">
                                    <div v-for="(p, idx) in evidencePhotos" :key="idx" class="border rounded p-1 text-center" style="width: 140px;">
                                        <img :src="p.Url" :alt="p.Title" style="width: 100%; height: 90px; object-fit: cover; cursor: pointer; border-radius: 4px;" v-on:click="viewLightbox(p.Url, p.Title)" />
                                        <div class="small text-muted mt-1 text-truncate font-weight-bold">{{ p.Title }}</div>
                                    </div>
                                </div>
                            </td>
                        </tr>
                    </table>
                </div>

                <!-- ==================== 2. 處理回報 ==================== -->
                <div class="report-section-card">
                    <div class="section-banner-title">
                        <div>
                            <i class="fas fa-tools text-primary mr-2"></i>
                            <span>處理回報</span>
                        </div>
                        <small class="text-muted font-weight-normal">可透過上方路平報馬仔工具自動帶入或手動編輯</small>
                    </div>
                    <table class="report-table">
                        <tr>
                            <td class="cell-label">完工日期(派工)</td>
                            <td class="cell-val" style="width: 35%;">{{ form.dispatchDoneDate || '無派工' }}</td>
                            <td class="cell-label">完工回報日期(派工)</td>
                            <td class="cell-val">{{ form.dispatchReportDate || '無派工' }}</td>
                        </tr>
                        <tr>
                            <td class="cell-label"><span class="text-danger font-weight-bold mr-1">*</span>完工日期</td>
                            <td class="cell-val">
                                <input type="text" class="form-input-custom w-100" v-model.trim="form.improveDate" placeholder="YYYY/MM/DD HH:mm" />
                            </td>
                            <td class="cell-label"><span class="text-danger font-weight-bold mr-1">*</span>完工回報日期</td>
                            <td class="cell-val">
                                <input type="text" class="form-input-custom w-100" v-model.trim="form.gReportDate" placeholder="YYYY/MM/DD HH:mm" />
                            </td>
                        </tr>
                        <tr>
                            <td class="cell-label">路面損壞-性質</td>
                            <td class="cell-val" colspan="3">
                                <div>
                                    <div class="font-weight-bold text-dark mb-2">{{ form.damageType || caseData.Damage_Type || '路面損壞' }}</div>
                                    <div class="dimension-row-mobile">
                                        <div class="dimension-item">
                                            <span class="text-secondary font-weight-bold">長:</span>
                                            <input type="number" step="0.1" inputmode="decimal" class="form-input-custom text-center" v-model="form.damageLength" placeholder="長度" />
                                            <span class="text-muted">m</span>
                                        </div>
                                        <div class="dimension-item">
                                            <span class="text-secondary font-weight-bold">寬:</span>
                                            <input type="number" step="0.1" inputmode="decimal" class="form-input-custom text-center" v-model="form.damageWidth" placeholder="寬度" />
                                            <span class="text-muted">m</span>
                                        </div>
                                        <div class="dimension-item">
                                            <span class="text-secondary font-weight-bold">共:</span>
                                            <input type="text" class="form-input-custom text-center" v-model="form.damageCount" placeholder="處數" />
                                            <span class="text-muted">處</span>
                                        </div>
                                    </div>
                                </div>
                            </td>
                        </tr>
                        <tr>
                            <td class="cell-label"><span class="text-danger font-weight-bold mr-1">*</span>後續修復情形</td>
                            <td class="cell-val" colspan="3">
                                <input type="text" list="fixStatusOptions" class="form-input-custom w-100" v-model.trim="form.gFixStatus" v-on:change="onFixStatusChange" placeholder="請選擇或輸入後續修復情形..." />
                                <datalist id="fixStatusOptions">
                                    <option value="現況輕微龜裂屬堪用，持續追蹤加強巡查"></option>
                                    <option value="已完成常溫瀝青冷料暫補，恢復平整通行"></option>
                                    <option value="已完成熱拌瀝青刨鋪修補完成"></option>
                                    <option value="人手孔蓋周邊已調平改善完成"></option>
                                    <option value="已通報主管機關/管線權責單位接續進場處理"></option>
                                </datalist>
                            </td>
                        </tr>
                        <tr>
                            <td class="cell-label">所屬道路</td>
                            <td class="cell-val font-weight-bold" colspan="3">
                                {{ caseData.ROAD_Name }}
                            </td>
                        </tr>
                        <tr>
                            <td class="cell-label"><span class="text-danger font-weight-bold mr-1">*</span>承辦人</td>
                            <td class="cell-val">
                                <input type="text" class="form-input-custom" v-model.trim="form.gUser" placeholder="輸入承辦人姓名或代號" />
                            </td>
                            <td class="cell-label"><span class="text-danger font-weight-bold mr-1">*</span>聯絡電話</td>
                            <td class="cell-val">
                                <input type="text" class="form-input-custom" v-model.trim="form.gContactPhone" placeholder="例如：02-89926441" />
                            </td>
                        </tr>
                        <tr>
                            <td class="cell-label"><span class="text-danger font-weight-bold mr-1">*</span>處理說明</td>
                            <td class="cell-val" colspan="3">
                                <textarea class="form-input-custom w-100" rows="3" v-model="form.gMemo" v-on:input="evaluateFollowUpStatus" placeholder="請詳述現場勘查與改善作業摘要..."></textarea>
                            </td>
                        </tr>
                        <tr>
                            <td class="cell-label">完工照片</td>
                            <td class="cell-val" colspan="3">
                                <input type="file" ref="fileInput" accept="image/jpeg,image/png,image/gif,image/heic,image/*" capture="environment" multiple style="display:none;" v-on:change="handleFilesSelected" />

                                <div class="photos-grid">
                                    <!-- 既有/已上傳/路平爬蟲下載之改善後完工照片 -->
                                    <div v-for="(p, idx) in improvePhotosList" :key="idx" class="photo-slot">
                                        <img :src="p.PreviewUrl || p.Url" :alt="'照片 ' + (idx + 1)" v-on:click="viewLightbox(p.PreviewUrl || p.Url, '完工照片 ' + (idx + 1))" />
                                        <div class="photo-slot-bar">
                                            <span class="text-primary font-weight-bold">完工照片 {{ idx + 1 }}</span>
                                            <button type="button" class="btn-del-img" v-on:click="removeImprovePhoto(idx)" title="刪除照片">
                                                <i class="fas fa-trash-alt mr-1"></i>刪除
                                            </button>
                                        </div>
                                    </div>

                                    <!-- 新增照片按鈕方塊 -->
                                    <div class="upload-placeholder" v-on:click="triggerFileInput">
                                        <i class="fas fa-camera fa-2x text-primary mb-1"></i>
                                        <span class="font-weight-bold text-primary small">拍照 / 選取完工照片</span>
                                        <small class="text-muted">支援路平自動抓取或手動上傳</small>
                                    </div>
                                </div>
                            </td>
                        </tr>
                        <tr>
                            <td class="cell-label">延遲原因</td>
                            <td class="cell-val" colspan="3">
                                <input type="text" class="form-input-custom w-100" v-model.trim="form.gDelayReason" placeholder="如未逾期完工免填，若有天候或特殊工程阻礙請在此說明" />
                            </td>
                        </tr>
                    </table>
                </div>

                <!-- ==================== 3. 結案回覆 ==================== -->
                <div class="report-section-card">
                    <div class="section-banner-title">
                        <div>
                            <i class="fas fa-check-circle text-success mr-2"></i>
                            <span>結案回覆</span>
                        </div>
                    </div>
                    <table class="report-table">
                        <tr>
                            <td class="cell-label">回覆時間</td>
                            <td class="cell-val">
                                <input type="text" class="form-input-custom w-100" v-model.trim="form.gReplyDate" placeholder="YYYY/MM/DD HH:mm" />
                            </td>
                            <td class="cell-label">回覆方式</td>
                            <td class="cell-val">
                                <input type="text" class="form-input-custom w-100" v-model.trim="form.gReplyType" placeholder="例如：網路回覆、電話回覆或免回覆" />
                            </td>
                        </tr>
                        <tr>
                            <td class="cell-label">回覆說明</td>
                            <td class="cell-val" colspan="3">
                                <textarea class="form-input-custom w-100" rows="5" v-model="form.gReplyMemo" v-on:input="evaluateFollowUpStatus" placeholder="輸入予民眾或提報單位之公務回覆說明..."></textarea>
                            </td>
                        </tr>
                    </table>
                </div>

                <!-- ==================== 4. 智慧判讀：建議持續追蹤 vs 正式結案 ==================== -->
                <div class="report-section-card">
                    <div class="section-banner-title">
                        <div>
                            <i class="fas fa-clipboard-check text-primary mr-2"></i>
                            <span>案件最終處置判定（正式結案 vs 建議機關持續追蹤）</span>
                        </div>
                        <span v-if="detectedFollowKeywords.length > 0" class="badge badge-info px-2 py-1">
                            偵測到追蹤關鍵字：{{ detectedFollowKeywords.join('、') }}
                        </span>
                    </div>
                    <div class="p-3">
                        <div v-if="detectedFollowKeywords.length > 0" class="alert alert-info mb-3 d-flex align-items-start" style="border-left: 4px solid #0284c7;">
                            <i class="fas fa-search-plus mt-1 mr-2 text-primary"></i>
                            <div class="small">
                                <strong>系統智慧判讀提醒：</strong>
                                偵測到處理回報或結案回覆文字含有「<strong>{{ detectedFollowKeywords.join('、') }}</strong>」（例如輕微龜裂堪用、持續追蹤加強巡查或暫補尚未刨鋪），系統已自動建議切換為<strong>【🔍 建議機關持續追蹤】</strong>，提醒機關後續複查列管！
                            </div>
                        </div>

                        <div class="follow-choice-grid">
                            <div class="follow-option-card" :class="{ 'active-close': form.needFollow === 'N' }" v-on:click="selectFollowMode('N')">
                                <input type="radio" name="needFollowRadio" value="N" v-model="form.needFollow" class="mt-1" />
                                <div>
                                    <div class="font-weight-bold text-success" style="font-size: 1rem;">
                                        <i class="fas fa-check-circle mr-1"></i> 完成整個通報案件（正式結案）
                                    </div>
                                    <div class="small text-muted mt-1">
                                        道路破損已實質修補完成，無須後續追蹤複查，案件狀態歸檔為「已改善結案」。
                                    </div>
                                </div>
                            </div>

                            <div class="follow-option-card" :class="{ 'active-follow': form.needFollow === 'Y' }" v-on:click="selectFollowMode('Y')">
                                <input type="radio" name="needFollowRadio" value="Y" v-model="form.needFollow" class="mt-1" />
                                <div>
                                    <div class="font-weight-bold text-primary" style="font-size: 1rem;">
                                        <i class="fas fa-search-location mr-1"></i> 建議機關持續追蹤列管
                                    </div>
                                    <div class="small text-muted mt-1">
                                        處置文字屬「堪用觀察、持續追蹤加強巡查、冷料暫補或錄案排程」，標記提醒機關持續追蹤後續改善。
                                    </div>
                                </div>
                            </div>
                        </div>

                        <div v-if="form.needFollow === 'Y'" class="mt-3 p-3 rounded" style="background: #f8fafc; border: 1px solid #bae6fd;">
                            <label class="font-weight-bold text-primary small mb-1">
                                <i class="fas fa-bell mr-1"></i> 持續追蹤建議與提醒事項（將顯示於案件明細與通知信）：
                            </label>
                            <textarea class="form-input-custom w-100" rows="2" v-model.trim="form.followMemo"
                                      placeholder="例如：工務局回報現況輕微龜裂屬堪用持續追蹤加強巡查，建議本機關下次例行巡檢時優先複查該路段是否惡化。"></textarea>
                        </div>
                    </div>
                </div>

                <!-- 桌面版底部操作按鈕列 (中大尺寸螢幕顯示) -->
                <div class="d-none d-md-flex align-items-center justify-content-center gap-3 mt-4 mb-4">
                    <a :href="'BreakDetail.aspx?id=' + encodeURIComponent(breakId)" class="btn btn-secondary px-4 font-weight-bold">
                        <i class="fas fa-arrow-left mr-1"></i> 返回案件檢視
                    </a>
                    <button type="button" class="btn btn-outline-danger px-4 font-weight-bold bg-white" v-on:click="openBackModal">
                        <i class="fas fa-undo mr-1"></i> 非權責退回
                    </button>
                    <button type="button" class="btn btn-primary px-5 font-weight-bold shadow" :disabled="isSubmitting" v-on:click="submitImprove">
                        <i class="fas fa-paper-plane mr-1" :class="{ 'fa-spin': isSubmitting }"></i>
                        {{ isSubmitting ? '儲存中...' : (form.needFollow === 'Y' ? '儲存回報並標記持續追蹤' : '送出處理回報並正式結案') }}
                    </button>
                </div>
            </div>
        </main>

        <!-- 手機端底部常駐懸浮操作工具列 (小尺寸 RWD 拇指操作) -->
        <nav class="mobile-bottom-bar d-md-none">
            <a :href="'BreakDetail.aspx?id=' + encodeURIComponent(breakId)" class="btn btn-outline-secondary">
                <i class="fas fa-arrow-left mr-1"></i>返回
            </a>
            <button type="button" class="btn btn-outline-danger" v-on:click="openBackModal">
                <i class="fas fa-undo mr-1"></i>退回
            </button>
            <button type="button" class="btn btn-primary" style="flex: 2;" :disabled="isSubmitting" v-on:click="submitImprove">
                <i class="fas fa-paper-plane mr-1" :class="{ 'fa-spin': isSubmitting }"></i>
                {{ isSubmitting ? '處理中...' : (form.needFollow === 'Y' ? '儲存並持續追蹤' : '送出並結案') }}
            </button>
        </nav>

        <!-- 智慧剪貼簿解析 Modal (防封鎖備援機制) -->
        <div v-if="isParseModalOpen" class="back-modal-backdrop" v-on:click="closeClipboardParseModal">
            <div class="back-modal-dialog" v-on:click.stop>
                <div class="parse-modal-header">
                    <h6 class="mb-0 font-weight-bold"><i class="fas fa-paste mr-1"></i> 貼上路平報馬仔網頁文字 — 智慧自動拆解填入</h6>
                    <button type="button" class="close text-white" v-on:click="closeClipboardParseModal">&times;</button>
                </div>
                <div class="back-modal-body">
                    <div class="alert alert-info small mb-2">
                        <i class="fas fa-lightbulb mr-1"></i>
                        <strong>防權限封鎖備援工具：</strong>請在「新北市路平報馬仔系統」案件網頁按 <code>Ctrl+A</code> 全選、<code>Ctrl+C</code> 複製後，貼入下方文字框，系統將自動拆解【處理回報】與【結案回覆】所有欄位！
                    </div>
                    <textarea class="form-input-custom w-100" rows="8" v-model="rawPastedText"
                              placeholder="請在此處貼上 (Ctrl+V) 從路平報馬仔網頁複製的全部文字..."></textarea>
                </div>
                <div class="back-modal-footer">
                    <button type="button" class="btn btn-secondary btn-sm" v-on:click="closeClipboardParseModal">取消</button>
                    <button type="button" class="btn btn-primary btn-sm font-weight-bold px-3" :disabled="!rawPastedText" v-on:click="applyClipboardParse">
                        <i class="fas fa-magic mr-1"></i> 立即解析並填入表單
                    </button>
                </div>
            </div>
        </div>

        <!-- 退回通報 Modal -->
        <div v-if="isBackModalOpen" class="back-modal-backdrop" v-on:click="closeBackModal">
            <div class="back-modal-dialog" v-on:click.stop>
                <div class="back-modal-header">
                    <h6 class="mb-0 font-weight-bold"><i class="fas fa-exclamation-triangle mr-1"></i> 非本單位權責 - 退回通報</h6>
                    <button type="button" class="close text-white" v-on:click="closeBackModal">&times;</button>
                </div>
                <div class="back-modal-body">
                    <div class="alert alert-warning small mb-3">
                        <i class="fas fa-info-circle mr-1"></i>
                        退回後系統將自動通知通報單位重新派工，並解除本單位改善列管。
                    </div>
                    <label class="font-weight-bold text-dark small"><span class="text-danger mr-1">*</span>退回原因詳細說明：</label>
                    <textarea class="form-input-custom w-100" rows="4" v-model.trim="backReason" placeholder="例如：經查該路段非屬本處轄管道路，權屬高公局/區公所轄管，建請退回重派..."></textarea>
                </div>
                <div class="back-modal-footer">
                    <button type="button" class="btn btn-secondary btn-sm" v-on:click="closeBackModal">取消</button>
                    <button type="button" class="btn btn-danger btn-sm font-weight-bold px-3" :disabled="isSubmitting || !backReason" v-on:click="confirmBack">
                        確認退回
                    </button>
                </div>
            </div>
        </div>

        <!-- 燈箱 Modal -->
        <div v-if="lightboxImg" class="lightbox-modal" v-on:click="lightboxImg = null">
            <button type="button" class="lightbox-close" v-on:click="lightboxImg = null">&times;</button>
            <img :src="lightboxImg" class="lightbox-img" v-on:click.stop :alt="lightboxTitle || '放大照片'" />
        </div>
    </div>

    <!-- 本地核心腳本庫 -->
    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>
    <script src="../Scripts/leaflet/leaflet.js"></script>

    <script type="text/javascript">
        const { createApp } = Vue;

        createApp({
            data() {
                return {
                    breakId: '',
                    loading: true,
                    isSubmitting: false,
                    isFetchingRdm: false,
                    rdmSyncMessage: '',
                    rdmSyncSuccess: false,
                    errorMessage: '',

                    // 案件主體資訊
                    caseData: {},
                    evidencePhotos: [],

                    // 改善完工照片清單: [{ FileName, Url, PreviewUrl, Base64Data, IsDeleted }]
                    improvePhotosList: [],
                    deletedImprovePhotos: [],

                    // 偵測到的持續追蹤關鍵字
                    detectedFollowKeywords: [],

                    // 表單模型 (完整對標路平報馬仔欄位 + 持續追蹤判定，不強制預帶時間或帳號)
                    form: {
                        rdmCaseId: '',
                        needFollow: 'N',
                        followMemo: '',
                        pciType: '',
                        pciSeverity: '輕',
                        supervisorSuggest: '尚未設定',
                        districtOffice: '',
                        handleUnit: '',
                        handleStatus: '',
                        dispatchMemo: '',
                        dispatchDoneDate: '無派工',
                        dispatchReportDate: '無派工',
                        improveDate: '',
                        gReportDate: '',
                        damageType: '',
                        damageLength: '',
                        damageWidth: '',
                        damageCount: '1',
                        gFixStatus: '',
                        gUser: '',
                        gContactPhone: '',
                        gMemo: '',
                        gDelayReason: '',
                        gReplyType: '',
                        gReplyDate: '',
                        gReplyMemo: ''
                    },

                    // 智慧剪貼簿解析 Modal
                    isParseModalOpen: false,
                    rawPastedText: '',

                    // 退回 Modal
                    isBackModalOpen: false,
                    backReason: '',

                    // 燈箱
                    lightboxImg: null,
                    lightboxTitle: ''
                };
            },

            created() {
                this.embedMap = null;
                this.embedMarker = null;
            },

            mounted() {
                const urlParams = new URLSearchParams(window.location.search);
                this.breakId = urlParams.get('id') || '';
                if (!this.breakId) {
                    this.errorMessage = '網址參數缺少案件編號 id。';
                    this.loading = false;
                    return;
                }
                this.loadInitData();
            },

            methods: {
                // 載入案件初值
                loadInitData() {
                    this.loading = true;
                    this.errorMessage = '';
                    axios.get('ImproveBreak.aspx?action=init&id=' + encodeURIComponent(this.breakId))
                        .then(res => {
                            this.loading = false;
                            if (res.data && res.data.Success) {
                                const c = res.data.Case;
                                this.caseData = c;
                                this.evidencePhotos = res.data.EvidencePhotos || [];

                                // 完工照片填充
                                const oldImps = res.data.ImprovePhotos || [];
                                this.deletedImprovePhotos = [];
                                this.improvePhotosList = oldImps.map(p => ({
                                    FileName: p.FileName,
                                    Url: p.Url,
                                    PreviewUrl: p.Url,
                                    Base64Data: '',
                                    IsDeleted: false
                                }));

                                // 若 Show_ID 為 7~10 碼純數字，預設亦帶入 rdmCaseId
                                let defaultRdmId = c.RDM_Case_ID || '';
                                if (!defaultRdmId && c.Show_ID && /^\d{6,10}$/.test(c.Show_ID)) {
                                    defaultRdmId = c.Show_ID;
                                }

                                // 綁定表單回覆欄位 (不自動帶入現在時間、不自動帶入登入帳號或公文範本)
                                this.form.rdmCaseId = defaultRdmId;
                                this.form.needFollow = c.Need_Follow || 'N';
                                this.form.followMemo = c.Follow_Memo || '';
                                this.form.pciType = c.PCI_Type || c.Damage_Type || '坑洞';
                                this.form.pciSeverity = c.PCI_Severity || '輕';
                                this.form.supervisorSuggest = c.Supervisor_Suggest || '尚未設定';
                                this.form.districtOffice = c.District_Office || '';
                                this.form.handleUnit = c.Handle_Unit || '';
                                this.form.handleStatus = c.Handle_Status || '';
                                this.form.dispatchMemo = c.Dispatch_Memo || '';
                                this.form.dispatchDoneDate = c.Dispatch_Done_Date || '無派工';
                                this.form.dispatchReportDate = c.Dispatch_Report_Date || '無派工';

                                this.form.improveDate = c.Improve_Date || '';
                                this.form.gReportDate = c.G_Report_Date || '';
                                this.form.damageType = c.Damage_Type || '坑洞';
                                this.form.damageLength = c.Damage_Length || '0';
                                this.form.damageWidth = c.Damage_Width || '0';
                                this.form.damageCount = c.Damage_Count || '1';
                                this.form.gFixStatus = c.G_Fix_Status || '';
                                this.form.gUser = c.G_UserName || c.G_USER || '';
                                this.form.gContactPhone = c.G_Contact_Phone || '';
                                this.form.gMemo = c.G_Memo || '';
                                this.form.gDelayReason = c.G_Delay_Reason || '';
                                this.form.gReplyType = c.G_Reply_Type || '';
                                this.form.gReplyDate = c.G_Reply_Date || '';
                                this.form.gReplyMemo = c.G_Reply_Memo || '';

                                this.evaluateFollowUpStatus();

                                // 地圖延遲渲染
                                this.$nextTick(() => {
                                    this.initEmbedMap();
                                });
                            } else {
                                this.errorMessage = res.data.Message || '讀取案件失敗';
                            }
                        })
                        .catch(err => {
                            this.loading = false;
                            console.error(err);
                            this.errorMessage = '伺服器通訊異常，無法載入案件資料';
                        });
                },

                // 當貼上路平網址時自動擷取 id
                onRdmIdInput() {
                    const val = this.form.rdmCaseId || '';
                    const match = val.match(/[?&]id=(\d+)/i);
                    if (match && match[1]) {
                        this.form.rdmCaseId = match[1];
                    }
                },

                // 機制 1：呼叫後端自動爬取路平報馬仔網頁與完工照片
                fetchFromRdm() {
                    if (!this.form.rdmCaseId) {
                        alert('請先輸入新北市路平報馬仔反映編號 (例如 2078092) 或貼上案件網址！');
                        return;
                    }

                    this.isFetchingRdm = true;
                    this.rdmSyncMessage = '';
                    axios.get('ImproveBreak.aspx?action=fetch_rdm&rdmId=' + encodeURIComponent(this.form.rdmCaseId))
                        .then(res => {
                            this.isFetchingRdm = false;
                            if (res.data && res.data.Success && res.data.Data) {
                                const d = res.data.Data;
                                this.applyParsedRdmObject(d);
                                this.rdmSyncSuccess = true;
                                const photoCount = (d.DownloadedPhotos && d.DownloadedPhotos.length) ? d.DownloadedPhotos.length : 0;
                                this.rdmSyncMessage = res.data.Message + (photoCount > 0 ? '（並已自動帶入 ' + photoCount + ' 張完工照片）' : '');
                            } else {
                                this.rdmSyncSuccess = false;
                                this.rdmSyncMessage = (res.data && res.data.Message) || '無法自動抓取路平資料，請改用「貼上網頁文字智慧解析」。';
                                if (res.data && res.data.NeedClipboardFallback) {
                                    this.openClipboardParseModal();
                                }
                            }
                        })
                        .catch(err => {
                            this.isFetchingRdm = false;
                            console.error(err);
                            this.rdmSyncSuccess = false;
                            this.rdmSyncMessage = '連線異常，請點選「📋 貼上網頁文字智慧解析」手動貼上文字。';
                        });
                },

                // 將後端或前端解析出的路平資料套用至表單
                applyParsedRdmObject(d) {
                    if (d.RDM_Case_ID) this.form.rdmCaseId = d.RDM_Case_ID;
                    if (d.PCI_Type) this.form.pciType = d.PCI_Type;
                    if (d.PCI_Severity) this.form.pciSeverity = d.PCI_Severity;
                    if (d.Supervisor_Suggest) this.form.supervisorSuggest = d.Supervisor_Suggest;
                    if (d.District_Office) this.form.districtOffice = d.District_Office;
                    if (d.Handle_Unit) this.form.handleUnit = d.Handle_Unit;
                    if (d.Handle_Status) this.form.handleStatus = d.Handle_Status;
                    if (d.Dispatch_Memo) this.form.dispatchMemo = d.Dispatch_Memo;
                    if (d.Dispatch_Done_Date) this.form.dispatchDoneDate = d.Dispatch_Done_Date;
                    if (d.Dispatch_Report_Date) this.form.dispatchReportDate = d.Dispatch_Report_Date;

                    if (d.Improve_Date) this.form.improveDate = d.Improve_Date;
                    if (d.G_Report_Date) this.form.gReportDate = d.G_Report_Date;
                    if (d.Damage_Type) this.form.damageType = d.Damage_Type;
                    if (d.Damage_Length !== undefined && d.Damage_Length !== null && d.Damage_Length !== '') this.form.damageLength = d.Damage_Length;
                    if (d.Damage_Width !== undefined && d.Damage_Width !== null && d.Damage_Width !== '') this.form.damageWidth = d.Damage_Width;
                    if (d.Damage_Count) this.form.damageCount = d.Damage_Count;
                    if (d.G_Fix_Status) this.form.gFixStatus = d.G_Fix_Status;
                    if (d.G_User) this.form.gUser = d.G_User;
                    if (d.G_Contact_Phone) this.form.gContactPhone = d.G_Contact_Phone;
                    if (d.G_Memo) this.form.gMemo = d.G_Memo;
                    if (d.G_Delay_Reason !== undefined && d.G_Delay_Reason !== null) this.form.gDelayReason = d.G_Delay_Reason;
                    if (d.G_Reply_Date) this.form.gReplyDate = d.G_Reply_Date;
                    if (d.G_Reply_Type) this.form.gReplyType = d.G_Reply_Type;
                    if (d.G_Reply_Memo) this.form.gReplyMemo = d.G_Reply_Memo;

                    // 若後端有自動下載完工照片，加入清單
                    if (d.DownloadedPhotos && d.DownloadedPhotos.length > 0) {
                        d.DownloadedPhotos.forEach(p => {
                            if (p.Base64Data) {
                                this.improvePhotosList.push({
                                    FileName: p.FileName || '改善後佐證照片.jpg',
                                    PreviewUrl: p.Base64Data,
                                    Base64Data: p.Base64Data,
                                    IsDeleted: false
                                });
                            }
                        });
                    }

                    this.evaluateFollowUpStatus();
                },

                // 機制 2：前端智慧剪貼簿解析器 Modal
                openClipboardParseModal() {
                    this.rawPastedText = '';
                    this.isParseModalOpen = true;
                },

                closeClipboardParseModal() {
                    this.isParseModalOpen = false;
                },

                applyClipboardParse() {
                    const text = (this.rawPastedText || '').trim();
                    if (!text) return;

                    const extractField = (label, stopLabels) => {
                        const stops = stopLabels.join('|');
                        const regex = new RegExp(label + '[\\s\\t：:]*([\\s\\S]*?)(?=(?:' + stops + ')[\\s\\t：:]|$)', 'i');
                        const m = text.match(regex);
                        return m && m[1] ? m[1].trim() : '';
                    };

                    // 切割區段：處理回報、結案回覆、滿意度調查
                    let reportSection = text;
                    let replySection = '';
                    const idxReport = text.indexOf('處理回報');
                    const idxReply = text.indexOf('結案回覆');
                    const idxSatisfy = text.indexOf('滿意度調查');

                    if (idxReport >= 0) {
                        if (idxReply > idxReport) {
                            reportSection = text.substring(idxReport, idxReply);
                            replySection = idxSatisfy > idxReply ? text.substring(idxReply, idxSatisfy) : text.substring(idxReply);
                        } else {
                            reportSection = idxSatisfy > idxReport ? text.substring(idxReport, idxSatisfy) : text.substring(idxReport);
                        }
                    }

                    const d = {};
                    const mRdmId = text.match(/反映編號[\s\t：:]*(\d{5,12})/);
                    if (mRdmId) d.RDM_Case_ID = mRdmId[1];

                    const mDoneDispatch = reportSection.match(/完工日期\(派工\)[\s\t：:]*([^\r\n\t]+)/);
                    if (mDoneDispatch) d.Dispatch_Done_Date = mDoneDispatch[1].trim();

                    const mRepDispatch = reportSection.match(/完工回報日期\(派工\)[\s\t：:]*([^\r\n\t]+)/);
                    if (mRepDispatch) d.Dispatch_Report_Date = mRepDispatch[1].trim();

                    const mImpDate = reportSection.match(/(?:^|\n|\t)完工日期[\s\t：:]*([0-9/\- :]+)/);
                    if (mImpDate) d.Improve_Date = mImpDate[1].trim();

                    const mRepDate = reportSection.match(/(?:^|\n|\t)完工回報日期[\s\t：:]*([0-9/\- :]+)/);
                    if (mRepDate) d.G_Report_Date = mRepDate[1].trim();

                    const mDmg = reportSection.match(/路面損壞-性質[\s\t：:]*([^\r\n]+)/);
                    if (mDmg) {
                        const dmgStr = mDmg[1].trim();
                        const mL = dmgStr.match(/長[：:]\s*([0-9.]+)/);
                        const mW = dmgStr.match(/寬[：:]\s*([0-9.]+)/);
                        const mC = dmgStr.match(/共\s*([0-9]+)\s*處/);
                        if (mL) d.Damage_Length = mL[1];
                        if (mW) d.Damage_Width = mW[1];
                        if (mC) d.Damage_Count = mC[1];
                        const idxL = dmgStr.indexOf('長');
                        if (idxL > 0) d.Damage_Type = dmgStr.substring(0, idxL).trim();
                    }

                    const mFix = reportSection.match(/後續修復情形[\s\t：:]*([^\r\n\t]+)/);
                    if (mFix) d.G_Fix_Status = mFix[1].trim();

                    const mUser = reportSection.match(/承辦人[\s\t：:]*([^\r\n\t]+)/);
                    if (mUser && mUser[1].trim() !== '聯絡電話') d.G_User = mUser[1].trim();

                    const mPhone = reportSection.match(/聯絡電話[\s\t：:]*([0-9\-()#ext]+)/i);
                    if (mPhone) d.G_Contact_Phone = mPhone[1].trim();

                    const mMemo = reportSection.match(/處理說明[\s\t：:]*([\s\S]*?)(?=完工照片|延遲原因|$)/);
                    if (mMemo) d.G_Memo = mMemo[1].trim();

                    if (replySection) {
                        const mReplyTime = replySection.match(/回覆時間[\s\t：:]*([0-9/\- :]+)/);
                        if (mReplyTime) d.G_Reply_Date = mReplyTime[1].trim();

                        const mReplyType = replySection.match(/回覆方式[\s\t：:]*([^\r\n\t]+)/);
                        if (mReplyType) d.G_Reply_Type = mReplyType[1].trim();

                        const mReplyMemo = replySection.match(/回覆說明[\s\t：:]*([\s\S]*?)$/);
                        if (mReplyMemo) d.G_Reply_Memo = mReplyMemo[1].trim();
                    }

                    this.applyParsedRdmObject(d);
                    this.closeClipboardParseModal();
                    this.rdmSyncSuccess = true;
                    this.rdmSyncMessage = '已透過剪貼簿智慧解析成功帶入【處理回報】與【結案回覆】欄位！';
                },

                // 智慧判讀：檢查是否含有持續追蹤關鍵字
                evaluateFollowUpStatus() {
                    const combined = (this.form.gFixStatus || '') + ' ' + (this.form.gMemo || '') + ' ' + (this.form.gReplyMemo || '');
                    const keywords = ['持續追蹤', '加強巡查', '堪用', '觀察', '錄案', '暫補', '臨補', '擇期', '開口契約', '預計'];
                    const matched = [];
                    keywords.forEach(kw => {
                        if (combined.indexOf(kw) >= 0) {
                            matched.push(kw);
                        }
                    });
                    this.detectedFollowKeywords = matched;

                    if (matched.length > 0) {
                        this.form.needFollow = 'Y';
                        if (!this.form.followMemo) {
                            this.form.followMemo = '路平報馬仔回報：「' + (this.form.gMemo || this.form.gFixStatus) + '」，尚未永久刨鋪修復，建議機關持續追蹤複查。';
                        }
                    }
                },

                selectFollowMode(mode) {
                    this.form.needFollow = mode;
                    if (mode === 'Y' && !this.form.followMemo) {
                        this.form.followMemo = '路平報馬仔回報：「' + (this.form.gMemo || this.form.gFixStatus) + '」，建議機關持續追蹤複查。';
                    }
                },

                // 初始化反映地點地圖
                initEmbedMap() {
                    let lat = 25.012363;
                    let lon = 121.465715;
                    let zoom = 14;

                    if (this.caseData.Lat && this.caseData.Lng) {
                        lat = parseFloat(this.caseData.Lat);
                        lon = parseFloat(this.caseData.Lng);
                        zoom = 17;
                    }

                    if (!document.getElementById('embedMap')) return;

                    if (!this.embedMap) {
                        this.embedMap = L.map('embedMap', {
                            center: [lat, lon],
                            zoom: zoom,
                            zoomControl: false
                        });

                        L.control.zoom({ position: 'bottomright' }).addTo(this.embedMap);

                        const emap = L.tileLayer('https://wmts.nlsc.gov.tw/wmts/EMAP/default/GoogleMapsCompatible/{z}/{y}/{x}', {
                            maxZoom: 19,
                            attribution: '&copy; 內政部國土測繪中心'
                        });
                        emap.addTo(this.embedMap);

                        if (this.caseData.Lat && this.caseData.Lng) {
                            const iconHtml = '<div style="width:28px;height:28px;border-radius:50% 50% 50% 0;background:#dc2626;position:absolute;transform:rotate(-45deg);left:50%;top:50%;margin:-18px 0 0 -14px;box-shadow:0 3px 8px rgba(0,0,0,0.35);border:2px solid #fff;"></div>';
                            const customIcon = L.divIcon({
                                className: '',
                                html: iconHtml,
                                iconSize: [28, 28],
                                iconAnchor: [14, 28]
                            });
                            this.embedMarker = L.marker([lat, lon], { icon: customIcon }).addTo(this.embedMap);
                        }
                    } else {
                        this.embedMap.invalidateSize();
                        this.embedMap.setView([lat, lon], zoom);
                    }
                },

                // Google 街景圖
                openGoogleStreetView() {
                    if (this.caseData.Lat && this.caseData.Lng) {
                        const url = 'https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=' + this.caseData.Lat + ',' + this.caseData.Lng;
                        window.open(url, '_blank');
                    }
                },

                // 當修復情形切換時，自動同步至處理說明並重新判讀追蹤狀態
                onFixStatusChange() {
                    if (this.form.gFixStatus && this.form.gFixStatus !== '其他' && !this.form.gMemo) {
                        this.form.gMemo = this.form.gFixStatus;
                    }
                    this.evaluateFollowUpStatus();
                },

                // 照片上傳處理
                triggerFileInput() {
                    if (this.$refs.fileInput) {
                        this.$refs.fileInput.click();
                    }
                },

                handleFilesSelected(e) {
                    const files = e.target.files;
                    if (!files || files.length === 0) return;

                    Array.from(files).forEach(file => {
                        const reader = new FileReader();
                        reader.onload = (event) => {
                            const img = new Image();
                            img.onload = () => {
                                const canvas = document.createElement('canvas');
                                const maxDim = 1920;
                                let w = img.width;
                                let h = img.height;
                                if (w > maxDim || h > maxDim) {
                                    if (w > h) {
                                        h = Math.round((h * maxDim) / w);
                                        w = maxDim;
                                    } else {
                                        w = Math.round((w * maxDim) / h);
                                        h = maxDim;
                                    }
                                }
                                canvas.width = w;
                                canvas.height = h;
                                const ctx = canvas.getContext('2d');
                                ctx.drawImage(img, 0, 0, w, h);

                                const compressedBase64 = canvas.toDataURL('image/jpeg', 0.85);
                                this.improvePhotosList.push({
                                    FileName: file.name,
                                    PreviewUrl: compressedBase64,
                                    Base64Data: compressedBase64,
                                    IsDeleted: false
                                });
                            };
                            img.src = event.target.result;
                        };
                        reader.readAsDataURL(file);
                    });

                    e.target.value = '';
                },

                removeImprovePhoto(idx) {
                    const p = this.improvePhotosList[idx];
                    if (p && p.Url && p.FileName && !p.Base64Data) {
                        this.deletedImprovePhotos.push({
                            FileName: p.FileName,
                            Base64Data: null,
                            IsDeleted: true
                        });
                    }
                    this.improvePhotosList.splice(idx, 1);
                },

                // 燈箱放大
                viewLightbox(url, title) {
                    this.lightboxImg = url;
                    this.lightboxTitle = title || '';
                },

                // 退回 Modal 操作
                openBackModal() {
                    this.backReason = '';
                    this.isBackModalOpen = true;
                },

                closeBackModal() {
                    this.isBackModalOpen = false;
                },

                confirmBack() {
                    if (!this.backReason) {
                        alert('請填寫非本單位權責之退回原因！');
                        return;
                    }

                    if (!confirm('是否確定將案件退回重新派工？')) return;

                    this.isSubmitting = true;
                    const payload = {
                        Break_ID: this.breakId,
                        IsBack: true,
                        G_Memo: this.backReason,
                        ImprovePhotos: []
                    };

                    axios.post('ImproveBreak.aspx?action=save', payload)
                        .then(res => {
                            this.isSubmitting = false;
                            this.closeBackModal();
                            if (res.data && res.data.Success) {
                                alert(res.data.Message || '案件已成功退回！');
                                window.location.href = res.data.RedirectUrl || ('BreakDetail.aspx?id=' + encodeURIComponent(this.breakId));
                            } else {
                                alert(res.data.Message || '退回失敗');
                            }
                        })
                        .catch(err => {
                            this.isSubmitting = false;
                            console.error(err);
                            alert('連線伺服器失敗，退回失敗');
                        });
                },

                // 送出處理回報
                submitImprove() {
                    if (!this.form.improveDate) {
                        alert('請輸入【完工日期】！');
                        return;
                    }
                    if (!this.form.gReportDate) {
                        alert('請輸入【完工回報日期】！');
                        return;
                    }
                    if (!this.form.gUser) {
                        alert('請輸入【承辦人】！');
                        return;
                    }
                    if (!this.form.gContactPhone) {
                        alert('請輸入【聯絡電話】！');
                        return;
                    }
                    if (!this.form.gMemo) {
                        alert('請輸入【處理說明】！');
                        return;
                    }

                    const confirmMsg = this.form.needFollow === 'Y'
                        ? '本案將儲存處理回報，並標記為【🔍 建議機關持續追蹤】。確認送出？'
                        : '確認送出道路破損處理回報並【✅ 正式結案】？';

                    if (!confirm(confirmMsg)) return;

                    this.isSubmitting = true;

                    const allPhotosPayload = this.deletedImprovePhotos.concat(
                        this.improvePhotosList.map(p => ({
                            FileName: p.FileName,
                            Base64Data: p.Base64Data || null,
                            IsDeleted: p.IsDeleted || false
                        }))
                    );

                    const payload = {
                        Break_ID: this.breakId,
                        IsBack: false,
                        RDM_Case_ID: this.form.rdmCaseId,
                        Need_Follow: this.form.needFollow,
                        Follow_Memo: this.form.followMemo,
                        PCI_Type: this.form.pciType,
                        PCI_Severity: this.form.pciSeverity,
                        Supervisor_Suggest: this.form.supervisorSuggest,
                        District_Office: this.form.districtOffice,
                        Handle_Unit: this.form.handleUnit,
                        Handle_Status: this.form.handleStatus,
                        Dispatch_Memo: this.form.dispatchMemo,
                        Dispatch_Done_Date: this.form.dispatchDoneDate,
                        Dispatch_Report_Date: this.form.dispatchReportDate,
                        Improve_Date: this.form.improveDate,
                        G_Report_Date: this.form.gReportDate,
                        Damage_Type: this.form.damageType,
                        Damage_Length: this.form.damageLength,
                        Damage_Width: this.form.damageWidth,
                        Damage_Count: this.form.damageCount,
                        G_Fix_Status: this.form.gFixStatus,
                        G_User: this.form.gUser,
                        G_Contact_Phone: this.form.gContactPhone,
                        G_Memo: this.form.gMemo,
                        G_Delay_Reason: this.form.gDelayReason,
                        G_Reply_Type: this.form.gReplyType,
                        G_Reply_Date: this.form.gReplyDate,
                        G_Reply_Memo: this.form.gReplyMemo,
                        ImprovePhotos: allPhotosPayload
                    };

                    axios.post('ImproveBreak.aspx?action=save', payload)
                        .then(res => {
                            this.isSubmitting = false;
                            if (res.data && res.data.Success) {
                                alert(res.data.Message || '處理回報已成功送出！');
                                window.location.href = res.data.RedirectUrl || ('BreakDetail.aspx?id=' + encodeURIComponent(this.breakId));
                            } else {
                                alert(res.data.Message || '儲存失敗');
                            }
                        })
                        .catch(err => {
                            this.isSubmitting = false;
                            console.error(err);
                            alert('連線伺服器失敗，儲存失敗');
                        });
                }
            }
        }).mount('#improveApp');
    </script>
</body>
</html>
