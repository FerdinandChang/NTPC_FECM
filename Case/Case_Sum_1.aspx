<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Case_Sum_1.aspx.cs" Inherits="NTPC_FEC.Case.Case_Sum_1" %>

<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定溢散源管理平台 - 固定污染源管辦改善歷程追蹤統計</title>

    <!-- 專屬 Favicon -->
    <link rel="shortcut icon" href="../favicon.ico" type="image/x-icon" />

    <!-- 本地化樣式依賴 (避開機房資安 CSP 阻擋) -->
    <link rel="stylesheet" href="../Content/bootstrap.min.css" />
    <link rel="stylesheet" href="../Content/fontawesome/css/all.min.css" />

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
            --color-improved: #10b981;    /* 改善成功綠 */
            --color-warning: #f59e0b;     /* 警示橘黃 */
            --color-danger: #ef4444;      /* 嚴重紅 */
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

        /* 1. 置頂深青藍漸層導覽列 (Sticky Top Navbar - 嚴格依據 inspection-ui-standard 規範) */
        .top-navbar {
            background: linear-gradient(135deg, #0099e5 0%, #0284c7 100%);
            color: #ffffff !important;
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
            font-size: 1.08rem;
            font-weight: 700;
            margin: 0;
            display: flex;
            align-items: center;
            gap: 8px;
            color: #ffffff !important;
        }

        .top-navbar .brand-title .title-text {
            color: #ffffff !important;
        }

        .top-navbar .brand-title i {
            color: #ffffff !important;
        }

        /* 標題旁白底數量徽章 - 深色文字確保清晰高對比度 */
        .top-navbar .brand-count-badge {
            background-color: #ffffff !important;
            color: #0f172a !important;
            font-size: 0.85rem !important;
            font-weight: 800 !important;
            padding: 4px 10px;
            border-radius: 12px;
            box-shadow: 0 1px 4px rgba(0, 0, 0, 0.18);
            letter-spacing: 0.5px;
        }

        .nav-btn {
            background: rgba(255, 255, 255, 0.18);
            border: 1px solid rgba(255, 255, 255, 0.3);
            color: #ffffff !important;
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
            transition: all 0.2s ease;
            text-decoration: none !important;
        }

        .nav-btn:hover {
            background-color: rgba(255, 255, 255, 0.32);
            color: #ffffff !important;
            text-decoration: none !important;
        }

        /* 白底黑字陰影膠囊按鈕 (右側功能動作標準樣式) */
        .nav-btn.bg-white {
            background: #ffffff !important;
            color: #0f172a !important;
            box-shadow: 0 2px 6px rgba(0, 0, 0, 0.12) !important;
            border: 1px solid rgba(0, 0, 0, 0.08) !important;
        }

        .nav-btn.bg-white:hover {
            background-color: #f8fafc !important;
            color: #0284c7 !important;
        }

        .nav-btn.bg-white:disabled {
            opacity: 0.55;
            cursor: not-allowed;
        }

        /* 2. 列印專用報表頁首 (螢幕隱藏，列印時顯現) */
        .print-only-header {
            display: none;
        }

        /* 3. 主作業容器 (固定最大寬度 1560px 居中) */
        .container-fluid-custom {
            max-width: 1560px;
            margin: 0 auto;
            padding: 16px;
        }

        /* 現代卡片 */
        .card-modern {
            background: var(--surface);
            border-radius: 12px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05), 0 4px 12px rgba(15, 23, 42, 0.04);
            margin-bottom: 16px;
            border: 1px solid var(--border-color);
            overflow: hidden;
            transition: box-shadow 0.2s ease;
        }

        .card-modern:hover {
            box-shadow: 0 4px 16px rgba(15, 23, 42, 0.08);
        }

        .card-modern-header {
            padding: 12px 18px;
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
            padding: 16px 18px;
        }

        /* 標籤晶片按鈕 (Town & Field Chips) */
        .chip-group {
            display: flex;
            flex-wrap: wrap;
            gap: 6px;
        }

        .chip-item {
            display: inline-flex;
            align-items: center;
            padding: 5px 12px;
            border-radius: 20px;
            font-size: 13px;
            font-weight: 600;
            border: 1px solid #cbd5e1;
            background: #ffffff;
            color: #475569;
            cursor: pointer;
            transition: all 0.15s ease;
            user-select: none;
            min-height: 32px;
        }

        .chip-item:hover {
            border-color: var(--brand-blue);
            color: var(--brand-blue);
            background: #f0f9ff;
        }

        .chip-item.active {
            background: var(--brand-blue);
            color: #ffffff;
            border-color: var(--brand-blue);
            box-shadow: 0 1px 4px rgba(2, 132, 199, 0.3);
        }

        .chip-item.active-field {
            background: #0284c7;
            color: #ffffff;
            border-color: #0284c7;
            box-shadow: 0 1px 4px rgba(2, 132, 199, 0.25);
        }

        /* 統計摘要晶片 */
        .stat-card-group {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 12px;
            margin-bottom: 16px;
        }

        .stat-card {
            background: #ffffff;
            border: 1px solid var(--border-color);
            border-radius: 10px;
            padding: 12px 16px;
            display: flex;
            align-items: center;
            gap: 14px;
        }

        .stat-icon {
            width: 44px;
            height: 44px;
            border-radius: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 20px;
        }

        .stat-icon.blue { background: #e0f2fe; color: #0284c7; }
        .stat-icon.green { background: #d1fae5; color: #059669; }
        .stat-icon.orange { background: #fef3c7; color: #d97706; }
        .stat-icon.purple { background: #ede9fe; color: #7c3aed; }

        .stat-num {
            font-size: 1.35rem;
            font-weight: 800;
            color: var(--brand-navy);
            line-height: 1.2;
        }

        .stat-label {
            font-size: 12px;
            color: var(--text-muted);
            font-weight: 600;
        }

        /* 改善歷程矩陣表格 */
        .matrix-table-wrapper {
            overflow-x: auto;
            border: 1px solid var(--border-color);
            border-radius: 8px;
            background: #ffffff;
            -webkit-overflow-scrolling: touch;
        }

        .matrix-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 13px;
            min-width: 760px;
        }

        .matrix-table th {
            background: #f8fafc;
            color: #475569;
            font-weight: 700;
            padding: 9px 12px;
            border: 1px solid #e2e8f0;
            text-align: center;
            white-space: nowrap;
        }

        .matrix-table th.th-item-title {
            text-align: left;
            min-width: 160px;
            background: #f1f5f9;
        }

        .matrix-table td {
            padding: 8px 10px;
            border: 1px solid #e2e8f0;
            text-align: center;
            vertical-align: middle;
            color: #334155;
        }

        .matrix-table td.td-item-title {
            text-align: left;
            font-weight: 600;
            background: #ffffff;
            color: #1e293b;
        }

        /* 改善標註：比前次分數降低時的高亮風格 */
        .td-improved {
            background-color: #ecfdf5 !important;
            color: #047857 !important;
            font-weight: 800 !important;
            position: relative;
        }

        .td-improved::after {
            content: "✓";
            color: #10b981;
            font-size: 10px;
            margin-left: 2px;
            vertical-align: super;
        }

        /* 改善次數與狀況列 */
        .td-times-col {
            background: #fffbeb;
            font-weight: 700;
            color: #b45309;
            min-width: 80px;
        }

        .td-status-col {
            background: #f8fafc;
            font-weight: 700;
            min-width: 85px;
        }

        .status-tag-yes {
            color: #059669;
            background: #d1fae5;
            padding: 3px 8px;
            border-radius: 4px;
            font-size: 12px;
            display: inline-block;
        }

        .status-tag-no {
            color: #64748b;
            background: #f1f5f9;
            padding: 3px 8px;
            border-radius: 4px;
            font-size: 12px;
            display: inline-block;
        }

        /* 場所主資訊標籤列 */
        .fac-info-banner {
            background: #f8fafc;
            border-bottom: 1px solid var(--border-color);
            padding: 12px 18px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-wrap: wrap;
            gap: 10px;
        }

        .fac-title-group {
            display: flex;
            align-items: center;
            flex-wrap: wrap;
            gap: 8px;
        }

        .fac-cno-badge {
            background: var(--brand-dark-blue);
            color: #ffffff;
            padding: 4px 10px;
            border-radius: 6px;
            font-size: 13px;
            font-weight: 700;
            letter-spacing: 0.5px;
        }

        .fac-name-text {
            font-size: 1.05rem;
            font-weight: 800;
            color: var(--brand-navy);
        }

        .fac-town-badge {
            background: #e0f2fe;
            color: #0369a1;
            padding: 3px 9px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 700;
        }

        .fac-ind-badge {
            background: #f1f5f9;
            color: #475569;
            padding: 3px 9px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 600;
        }

        .fac-summary-badge {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 6px 12px;
            border-radius: 8px;
            font-size: 13px;
            font-weight: 700;
        }

        .fac-summary-badge.yes {
            background: #ecfdf5;
            color: #047857;
            border: 1px solid #a7f3d0;
        }

        .fac-summary-badge.no {
            background: #f8fafc;
            color: #64748b;
            border: 1px solid #e2e8f0;
        }

        /* 製程簡述列 */
        .process-hint {
            font-size: 12px;
            color: #64748b;
            margin-bottom: 10px;
            padding: 0 4px;
        }

        /* 動作列 */
        .action-bar {
            display: flex;
            align-items: center;
            justify-content: flex-end;
            gap: 10px;
            padding-top: 10px;
            border-top: 1px dashed var(--border-color);
            margin-top: 12px;
        }

        /* 列印模式排版設定 */
        @media print {
            .no-print {
                display: none !important;
            }
            .print-only-header {
                display: block !important;
                text-align: center;
                margin-bottom: 20px;
            }
            .print-only-header h2 {
                margin: 0;
                font-size: 18pt;
                font-weight: bold;
                color: #000000;
            }
            .print-only-header h3 {
                margin: 6px 0;
                font-size: 14pt;
                font-weight: bold;
                color: #000000;
            }
            .print-only-header p {
                margin: 4px 0 0 0;
                font-size: 10pt;
                color: #555555;
                border-bottom: 2px solid #000000;
                padding-bottom: 6px;
            }
            .container-fluid-custom {
                max-width: 100% !important;
                padding: 0 !important;
            }
            .card-modern {
                box-shadow: none !important;
                border: 1px solid #999 !important;
                break-inside: avoid;
            }
            body {
                background-color: #ffffff !important;
            }
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div id="app" v-cloak>
            <!-- 1. 置頂深青藍漸層導覽列 (Sticky Top Navbar - 嚴格依據 inspection-ui-standard 規範) -->
            <header class="top-navbar no-print">
                <div class="brand-title">
                    <a href="../MainPage.aspx?sub=menu4" class="nav-btn mr-2" title="返回主選單">
                        <i class="fas fa-arrow-left"></i>
                        <span class="d-none d-sm-inline">返回清單</span>
                    </a>
                    <i class="fas fa-chart-line text-white"></i>
                    <span class="title-text">固定污染源管辦改善歷程追蹤統計</span>
                    <span v-if="hasSearched && facList.length > 0" class="brand-count-badge ml-2">
                        {{ facList.length }} 家場所
                    </span>
                </div>
            </header>

            <!-- 2. 列印專用報表頁首 (螢幕隱藏，列印時顯現) -->
            <div class="print-only-header">
                <h2>新北市固定溢散源管理平台</h2>
                <h3>固定污染源管辦改善歷程追蹤統計表</h3>
                <p>統計區間：{{ filter.DateStart }} ～ {{ filter.DateEnd }} ｜ 列印日期：{{ printDate }}</p>
            </div>

            <!-- 3. 主內容作業區 (最大寬度 1560px 居中) -->
            <main class="container-fluid-custom">
                <!-- A. 篩選設定卡片 -->
                <div class="card-modern no-print">
                    <div class="card-modern-header">
                        <h2 class="card-modern-title">
                            <i class="fas fa-filter text-primary"></i>
                            篩選條件與統計設定
                        </h2>
                        <button type="button" class="btn btn-sm btn-link text-muted font-weight-bold p-0" v-on:click="filterCollapsed = !filterCollapsed">
                            {{ filterCollapsed ? '展開條件' : '收合條件' }}
                            <i :class="filterCollapsed ? 'fas fa-chevron-down ml-1' : 'fas fa-chevron-up ml-1'"></i>
                        </button>
                    </div>

                    <div v-show="!filterCollapsed" class="card-modern-body">
                        <!-- 第 1 列：基本文字欄位 -->
                        <div class="row">
                            <div class="col-12 col-md-3 mb-3">
                                <label class="font-weight-bold text-muted small mb-1">管制編號</label>
                                <input type="text" class="form-control form-control-sm" v-model="filter.C_NO" placeholder="例如：F1234567" v-on:keyup.enter="searchData" />
                            </div>
                            <div class="col-12 col-md-3 mb-3">
                                <label class="font-weight-bold text-muted small mb-1">公私場所名稱</label>
                                <input type="text" class="form-control form-control-sm" v-model="filter.FAC_NAME" placeholder="場所關鍵字" v-on:keyup.enter="searchData" />
                            </div>
                            <div class="col-12 col-md-3 mb-3">
                                <label class="font-weight-bold text-muted small mb-1">行業別</label>
                                <input type="text" class="form-control form-control-sm" v-model="filter.Industry" placeholder="行業關鍵字" v-on:keyup.enter="searchData" />
                            </div>
                            <div class="col-12 col-md-3 mb-3">
                                <label class="font-weight-bold text-muted small mb-1">程序別 / 許可證字號</label>
                                <input type="text" class="form-control form-control-sm" v-model="filter.Process" placeholder="製程或許可證" v-on:keyup.enter="searchData" />
                            </div>
                        </div>

                        <!-- 第 2 列：巡查日期區間與快捷鍵 -->
                        <div class="row">
                            <div class="col-12 col-md-6 mb-3">
                                <label class="font-weight-bold text-muted small mb-1">巡查日期區間 (起始 ～ 結束)</label>
                                <div class="d-flex align-items-center gap-2">
                                    <input type="date" class="form-control form-control-sm" v-model="filter.DateStart" />
                                    <span class="mx-1 text-muted">～</span>
                                    <input type="date" class="form-control form-control-sm" v-model="filter.DateEnd" />
                                </div>
                            </div>
                            <div class="col-12 col-md-6 mb-3 d-flex align-items-end">
                                <div class="btn-group btn-group-sm mb-1" role="group">
                                    <button type="button" class="btn btn-outline-secondary" v-on:click="setDateRange('3m')">近 3 個月</button>
                                    <button type="button" class="btn btn-outline-secondary" v-on:click="setDateRange('6m')">近 6 個月</button>
                                    <button type="button" class="btn btn-outline-secondary" v-on:click="setDateRange('thisYear')">今年至今</button>
                                </div>
                            </div>
                        </div>

                        <!-- 第 3 列：行政區多選標籤 (Chips) -->
                        <div class="mb-3">
                            <div class="d-flex align-items-center justify-content-between mb-1">
                                <label class="font-weight-bold text-muted small m-0">
                                    行政區選取 (已選 {{ filter.Towns.length }} / {{ townOptions.length }} 區)
                                </label>
                                <div>
                                    <button type="button" class="btn btn-xs btn-outline-primary py-0 px-2 mr-1" v-on:click="selectAllTowns">全選</button>
                                    <button type="button" class="btn btn-xs btn-outline-secondary py-0 px-2" v-on:click="clearAllTowns">清除</button>
                                </div>
                            </div>
                            <div class="chip-group p-2 bg-light rounded border">
                                <span v-for="t in townOptions" :key="t.Code" class="chip-item" :class="{ 'active': isTownSelected(t.Code) }" v-on:click="toggleTown(t.Code)">
                                    {{ t.Name }}
                                </span>
                            </div>
                        </div>

                        <!-- 第 4 列：管辦改善次數區間與改善狀況 -->
                        <div class="row">
                            <div class="col-12 col-md-4 mb-3">
                                <label class="font-weight-bold text-muted small mb-1">管辦改善次數篩選</label>
                                <div class="d-flex align-items-center gap-2">
                                    <input type="number" class="form-control form-control-sm" placeholder="大於等於" v-model.number="filter.SpecialTimesMin" min="0" />
                                    <span class="mx-1 text-muted">～</span>
                                    <input type="number" class="form-control form-control-sm" placeholder="小於等於" v-model.number="filter.SpecialTimesMax" min="0" />
                                </div>
                            </div>
                            <div class="col-12 col-md-4 mb-3">
                                <label class="font-weight-bold text-muted small mb-1">改善狀況判定過濾</label>
                                <div class="d-flex align-items-center gap-3 mt-1">
                                    <div class="custom-control custom-radio custom-control-inline">
                                        <input type="radio" id="statusAll" name="improveStatus" class="custom-control-input" value="全部" v-model="filter.ImproveStatus" />
                                        <label class="custom-control-label" for="statusAll">全部</label>
                                    </div>
                                    <div class="custom-control custom-radio custom-control-inline">
                                        <input type="radio" id="statusYes" name="improveStatus" class="custom-control-input" value="已改善" v-model="filter.ImproveStatus" />
                                        <label class="custom-control-label text-success font-weight-bold" for="statusYes">已改善</label>
                                    </div>
                                    <div class="custom-control custom-radio custom-control-inline">
                                        <input type="radio" id="statusNo" name="improveStatus" class="custom-control-input" value="無改善" v-model="filter.ImproveStatus" />
                                        <label class="custom-control-label text-secondary font-weight-bold" for="statusNo">無改善</label>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- 第 5 列：顯示設定 (管辦改善項目勾選) -->
                        <div class="mb-3">
                            <div class="d-flex align-items-center justify-content-between mb-1">
                                <label class="font-weight-bold text-muted small m-0">
                                    顯示管辦改善項目 (已選 {{ filter.SpecialFields.length }} / {{ fieldOptions.length }} 項)
                                </label>
                                <div>
                                    <button type="button" class="btn btn-xs btn-outline-primary py-0 px-2 mr-1" v-on:click="selectAllFields">全選</button>
                                    <button type="button" class="btn btn-xs btn-outline-secondary py-0 px-2" v-on:click="clearAllFields">清除</button>
                                </div>
                            </div>
                            <div class="chip-group p-2 bg-light rounded border">
                                <span v-for="f in fieldOptions" :key="f.Code" class="chip-item" :class="{ 'active-field': isFieldSelected(f.Code) }" v-on:click="toggleField(f.Code)">
                                    <i class="fas fa-check-circle mr-1" v-if="isFieldSelected(f.Code)"></i>
                                    {{ f.Code }}. {{ f.Name }}
                                </span>
                            </div>
                        </div>

                        <!-- 動作按鈕列 -->
                        <div class="action-bar">
                            <button type="button" class="btn btn-success btn-sm px-3 font-weight-bold" v-on:click="exportExcel" :disabled="loading || facList.length === 0" title="匯出當前統計結果為 Excel">
                                <i class="fas fa-file-excel mr-1"></i> 匯出 Excel
                            </button>
                            <button type="button" class="btn btn-light btn-sm px-3" v-on:click="resetFilter" :disabled="loading">
                                <i class="fas fa-undo mr-1"></i> 重設條件
                            </button>
                            <button type="button" class="btn btn-primary btn-sm px-4 font-weight-bold" v-on:click="searchData" :disabled="loading">
                                <i class="fas fa-search mr-1" v-if="!loading"></i>
                                <span class="spinner-border spinner-border-sm mr-1" v-if="loading"></span>
                                {{ loading ? '資料統計分析中...' : '開始統計分析' }}
                            </button>
                        </div>
                    </div>
                </div>

                <!-- B. 統計總覽摘要晶片 -->
                <div v-if="hasSearched && !loading && facList.length > 0" class="stat-card-group">
                    <div class="stat-card">
                        <div class="stat-icon blue">
                            <i class="fas fa-industry"></i>
                        </div>
                        <div>
                            <div class="stat-num">{{ facList.length }}</div>
                            <div class="stat-label">列管場所總數</div>
                        </div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-icon green">
                            <i class="fas fa-check-double"></i>
                        </div>
                        <div>
                            <div class="stat-num">{{ statImprovedCount }}</div>
                            <div class="stat-label">有效改善場所數 ({{ statImprovedRate }}%)</div>
                        </div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-icon orange">
                            <i class="fas fa-bolt"></i>
                        </div>
                        <div>
                            <div class="stat-num">{{ statTotalTimes }}</div>
                            <div class="stat-label">累積改善次數總計</div>
                        </div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-icon purple">
                            <i class="fas fa-calendar-alt"></i>
                        </div>
                        <div>
                            <div class="stat-num">{{ months.length }}</div>
                            <div class="stat-label">涵蓋統計月份數</div>
                        </div>
                    </div>
                </div>

                <!-- C. 查詢結果列表 -->
                <div v-if="loading" class="text-center py-5">
                    <div class="spinner-border text-primary" style="width: 3rem; height: 3rem;" role="status">
                        <span class="sr-only">載入中...</span>
                    </div>
                    <p class="text-muted font-weight-bold mt-3">資料計算分析中，請稍候...</p>
                </div>

                <div v-else-if="hasSearched && facList.length === 0" class="card-modern text-center py-5">
                    <div class="card-modern-body">
                        <i class="fas fa-search text-muted fa-3x mb-3" style="opacity: 0.4;"></i>
                        <h4 class="font-weight-bold text-muted">查無符合條件的公私場所</h4>
                        <p class="text-muted small">請嘗試放寬篩選條件或縮小查詢區間後再次點選統計。</p>
                        <button type="button" class="btn btn-outline-primary btn-sm mt-2" v-on:click="resetFilter">重設條件</button>
                    </div>
                </div>

                <div v-else-if="!hasSearched" class="card-modern text-center py-5">
                    <div class="card-modern-body">
                        <i class="fas fa-chart-bar text-primary fa-3x mb-3" style="opacity: 0.5;"></i>
                        <h4 class="font-weight-bold text-dark">準備進行管辦改善歷程追蹤統計</h4>
                        <p class="text-muted small">請點選上方「開始統計分析」按鈕，系統將自動比對各場所在查詢期間的扣分演變與改善次數。</p>
                        <button type="button" class="btn btn-primary px-4 font-weight-bold" v-on:click="searchData">
                            <i class="fas fa-play mr-1"></i> 立即執行統計
                        </button>
                    </div>
                </div>

                <!-- D. 資料卡片清單 (每家場所一張現代卡片) -->
                <div v-else>
                    <div v-for="fac in facList" :key="fac.FAC_ID" class="card-modern mb-3">
                        <!-- 場所標題列 -->
                        <div class="fac-info-banner">
                            <div class="fac-title-group">
                                <span class="fac-cno-badge">{{ fac.C_NO }}</span>
                                <span class="fac-name-text">{{ fac.FAC_NAME }}</span>
                                <span class="fac-town-badge" v-if="fac.TOWN_NA">{{ fac.TOWN_NA }}</span>
                                <span class="fac-ind-badge" v-if="fac.INDUSTRIAL_Name">{{ fac.INDUSTRIAL_Name }}</span>
                                <span class="badge badge-info" v-if="fac.CheckTime_LV">分級: {{ fac.CheckTime_LV }}</span>
                            </div>
                            <div class="d-flex align-items-center gap-2">
                                <div class="badge badge-warning p-2 font-weight-bold" style="font-size: 13px;">
                                    管辦改善次數: <span class="font-weight-bolder">{{ fac.Special_Times }}</span>
                                </div>
                                <div class="fac-summary-badge" :class="fac.Improve === '已改善' ? 'yes' : 'no'">
                                    <i :class="fac.Improve === '已改善' ? 'fas fa-check-circle text-success' : 'fas fa-minus-circle text-muted'"></i>
                                    {{ fac.Improve }}
                                </div>
                            </div>
                        </div>

                        <!-- 卡片內容：製程與月度矩陣表格 -->
                        <div class="card-modern-body p-3">
                            <div class="process-hint" v-if="fac.ProcessList">
                                <i class="fas fa-cogs mr-1"></i> 製程與許可：{{ fac.ProcessList }}
                            </div>

                            <div class="matrix-table-wrapper">
                                <table class="matrix-table">
                                    <thead>
                                        <tr>
                                            <th class="th-item-title">管辦項目</th>
                                            <th v-for="m in months" :key="m" style="min-width: 65px;">{{ m }}</th>
                                            <th class="td-times-col">改善次數</th>
                                            <th class="td-status-col">改善狀況</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <tr v-for="item in fac.ItemRows" :key="item.ItemCode">
                                            <td class="td-item-title">{{ item.ItemName }}</td>
                                            <td v-for="m in months" :key="m" :class="{ 'td-improved': item.MonthPoints[m] && item.MonthPoints[m].IsImproved }">
                                                {{ item.MonthPoints[m] ? item.MonthPoints[m].Text : '----' }}
                                            </td>
                                            <td class="td-times-col">{{ item.ItemImproveTimes }}</td>
                                            <td class="td-status-col">
                                                <span :class="item.ItemStatus === '已改善' ? 'status-tag-yes' : 'status-tag-no'">
                                                    {{ item.ItemStatus }}
                                                </span>
                                            </td>
                                        </tr>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>
            </main>
        </div>
    </form>

    <!-- 本地端核心前端腳本庫 -->
    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>

    <script>
        const { createApp } = Vue;

        createApp({
            data() {
                return {
                    loading: false,
                    hasSearched: false,
                    filterCollapsed: false,
                    townOptions: [],
                    fieldOptions: [],
                    months: [],
                    facList: [],
                    filter: {
                        C_NO: '',
                        FAC_NAME: '',
                        Industry: '',
                        Process: '',
                        DateStart: '',
                        DateEnd: '',
                        Towns: [],
                        SpecialTimesMin: null,
                        SpecialTimesMax: null,
                        ImproveStatus: '全部',
                        SpecialFields: []
                    }
                };
            },
            computed: {
                statImprovedCount() {
                    return this.facList.filter(f => f.Improve === '已改善').length;
                },
                statImprovedRate() {
                    if (this.facList.length === 0) return 0;
                    return Math.round((this.statImprovedCount / this.facList.length) * 100);
                },
                statTotalTimes() {
                    return this.facList.reduce((sum, f) => sum + (f.Special_Times || 0), 0);
                },
                printDate() {
                    const d = new Date();
                    const m = (d.getMonth() + 1);
                    const day = d.getDate();
                    return d.getFullYear() + '/' + (m < 10 ? '0' + m : m) + '/' + (day < 10 ? '0' + day : day);
                }
            },
            created() {
                this.loadInitialData();
            },
            methods: {
                // 載入行政區與項目等初始資料
                loadInitialData() {
                    this.loading = true;
                    axios.get('Case_Sum_1.aspx?action=getInitialData')
                        .then(res => {
                            if (res.data && res.data.Success) {
                                const d = res.data.Data;
                                this.townOptions = d.Towns || [];
                                this.fieldOptions = d.SpecialFields || [];
                                this.filter.DateStart = d.DefaultDateStart || '';
                                this.filter.DateEnd = d.DefaultDateEnd || '';

                                // 預設全選行政區與管辦項目
                                this.filter.Towns = this.townOptions.map(t => t.Code);
                                this.filter.SpecialFields = this.fieldOptions.map(f => f.Code);
                            }
                        })
                        .catch(err => {
                            console.error('載入初始設定失敗：', err);
                        })
                        .finally(() => {
                            this.loading = false;
                        });
                },
                // 行政區切換與選擇
                isTownSelected(code) {
                    return this.filter.Towns.indexOf(code) >= 0;
                },
                toggleTown(code) {
                    const idx = this.filter.Towns.indexOf(code);
                    if (idx >= 0) {
                        this.filter.Towns.splice(idx, 1);
                    } else {
                        this.filter.Towns.push(code);
                    }
                },
                selectAllTowns() {
                    this.filter.Towns = this.townOptions.map(t => t.Code);
                },
                clearAllTowns() {
                    this.filter.Towns = [];
                },
                // 管辦項目切換與選擇
                isFieldSelected(code) {
                    return this.filter.SpecialFields.indexOf(code) >= 0;
                },
                toggleField(code) {
                    const idx = this.filter.SpecialFields.indexOf(code);
                    if (idx >= 0) {
                        this.filter.SpecialFields.splice(idx, 1);
                    } else {
                        this.filter.SpecialFields.push(code);
                    }
                },
                selectAllFields() {
                    this.filter.SpecialFields = this.fieldOptions.map(f => f.Code);
                },
                clearAllFields() {
                    this.filter.SpecialFields = [];
                },
                // 日期快速切換
                setDateRange(type) {
                    const now = new Date();
                    const fmt = d => d.toISOString().split('T')[0];
                    this.filter.DateEnd = fmt(now);

                    if (type === '3m') {
                        const s = new Date(now.getFullYear(), now.getMonth() - 3, now.getDate());
                        this.filter.DateStart = fmt(s);
                    } else if (type === '6m') {
                        const s = new Date(now.getFullYear(), now.getMonth() - 6, now.getDate());
                        this.filter.DateStart = fmt(s);
                    } else if (type === 'thisYear') {
                        const s = new Date(now.getFullYear(), 0, 1);
                        this.filter.DateStart = fmt(s);
                    }
                },
                // 重設條件
                resetFilter() {
                    this.filter.C_NO = '';
                    this.filter.FAC_NAME = '';
                    this.filter.Industry = '';
                    this.filter.Process = '';
                    this.filter.SpecialTimesMin = null;
                    this.filter.SpecialTimesMax = null;
                    this.filter.ImproveStatus = '全部';
                    this.selectAllTowns();
                    this.selectAllFields();
                    this.setDateRange('thisYear');
                },
                // 執行統計查詢
                searchData() {
                    this.loading = true;
                    axios.post('Case_Sum_1.aspx?action=searchData', this.filter)
                        .then(res => {
                            if (res.data && res.data.Success) {
                                this.months = res.data.Months || [];
                                this.facList = res.data.Data || [];
                                this.hasSearched = true;
                            } else {
                                alert((res.data && res.data.Message) || '統計失敗');
                            }
                        })
                        .catch(err => {
                            console.error('查詢失敗：', err);
                            alert('查詢失敗，請檢查網路連線或伺服器回應');
                        })
                        .finally(() => {
                            this.loading = false;
                        });
                },
                // 匯出 Excel
                exportExcel() {
                    this.loading = true;
                    axios.post('Case_Sum_1.aspx?action=exportExcel', this.filter)
                        .then(res => {
                            if (res.data && res.data.Success) {
                                const base64 = res.data.Base64;
                                const fileName = res.data.FileName || 'Case_Sum_1.xls';
                                const byteCharacters = atob(base64);
                                const byteNumbers = new Array(byteCharacters.length);
                                for (let i = 0; i < byteCharacters.length; i++) {
                                    byteNumbers[i] = byteCharacters.charCodeAt(i);
                                }
                                const byteArray = new Uint8Array(byteNumbers);
                                const blob = new Blob([byteArray], { type: 'application/vnd.ms-excel;charset=utf-8' });
                                const link = document.createElement('a');
                                link.href = URL.createObjectURL(blob);
                                link.download = fileName;
                                document.body.appendChild(link);
                                link.click();
                                document.body.removeChild(link);
                            } else {
                                alert((res.data && res.data.Message) || '匯出失敗');
                            }
                        })
                        .catch(err => {
                            console.error('匯出失敗：', err);
                            alert('匯出 Excel 失敗');
                        })
                        .finally(() => {
                            this.loading = false;
                        });
                },
                // 列印
                printReport() {
                    window.print();
                }
            }
        }).mount('#app');
    </script>
</body>
</html>
