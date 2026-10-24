<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="OutLink.aspx.cs" Inherits="NTPC_FEC.OutLink" %>

<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定溢散源管理平台 - 相關外部系統連結</title>

    <!-- 專屬 Favicon -->
    <link rel="shortcut icon" href="favicon.ico" type="image/x-icon" />

    <!-- Bootstrap 4 & FontAwesome 本地化樣式 -->
    <link rel="stylesheet" href="Content/bootstrap.min.css" />
    <link rel="stylesheet" href="Content/fontawesome/css/all.min.css" />

    <style>
        :root {
            --brand-primary: #0099e5;     /* 新北天空青藍 (Navbar/強調) */
            --brand-blue: #0284c7;        /* 科技藍 (按鈕/選中) */
            --brand-dark-blue: #0b1f7d;   /* 海軍深藍 (標題/Tag) */
            --brand-navy: #0f172a;        /* 標題文字主色 */
            --bg-canvas: #f8fafc;         /* 頁面灰底 */
            --surface: #ffffff;           /* 卡片純白底色 */
            --border-color: #e2e8f0;      /* 邊框線條 */
            --text-main: #0f172a;         /* 內文主要文字 */
            --text-muted: #64748b;        /* 次要說明文字 */
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

        /* 頂部導覽列 (符合 SKILL.md 標準規範) */
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
            font-size: 1.08rem;
            font-weight: 700;
            margin: 0;
            display: flex;
            align-items: center;
            gap: 8px;
            color: #ffffff;
        }

        /* 導覽列左上角按鈕 (符合 SKILL.md 標準樣板) */
        .nav-btn {
            background: rgba(255, 255, 255, 0.18);
            border: 1px solid rgba(255, 255, 255, 0.35);
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
            transform: translateY(-1px);
        }

        /* 模式切換頁籤列 (與 Clean_List 一致) */
        .nav-mode-bar {
            background: #ffffff;
            border-bottom: 1px solid var(--border-color);
            padding: 0 20px;
            display: flex;
            gap: 8px;
            overflow-x: auto;
            white-space: nowrap;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.03);
            scrollbar-width: none;
        }

        .nav-mode-bar::-webkit-scrollbar {
            display: none;
        }

        .nav-mode-item {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 14px 18px;
            font-size: 14px;
            font-weight: 600;
            color: #64748b;
            border-bottom: 3px solid transparent;
            cursor: pointer;
            transition: all 0.2s ease;
            user-select: none;
        }

        .nav-mode-item:hover {
            color: var(--brand-blue);
            background: #f8fafc;
        }

        .nav-mode-item.active {
            color: var(--brand-blue);
            border-bottom-color: var(--brand-blue);
            font-weight: 700;
            background: rgba(2, 132, 199, 0.04);
        }

        .tab-badge {
            font-size: 11px;
            padding: 2px 7px;
            border-radius: 12px;
            font-weight: 700;
        }

        /* 現代卡片 (與 Clean_List 一致) */
        .card-modern {
            background: var(--surface);
            border-radius: 12px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05), 0 4px 12px rgba(15, 23, 42, 0.04);
            border: 1px solid var(--border-color);
            margin-bottom: 20px;
            overflow: hidden;
        }

        .card-modern-header {
            padding: 14px 20px;
            background: #ffffff;
            border-bottom: 1px solid var(--border-color);
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .card-modern-title {
            font-size: 1.05rem;
            font-weight: 700;
            color: var(--brand-navy);
            margin: 0;
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .card-modern-body {
            padding: 20px;
        }

        /* 統計卡片 (與 Clean_List 一致) */
        .stat-card {
            background: #ffffff;
            border-radius: 10px;
            border: 1px solid var(--border-color);
            padding: 14px 18px;
            display: flex;
            align-items: center;
            gap: 14px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.03);
            transition: transform 0.15s ease, box-shadow 0.15s ease, border-color 0.15s ease;
            cursor: pointer;
            height: 100%;
        }

        .stat-card:hover {
            transform: translateY(-2px);
            border-color: #0284c7;
            box-shadow: 0 4px 12px rgba(2, 132, 199, 0.12);
        }

        .stat-card.active {
            border-color: #0284c7;
            background: linear-gradient(135deg, #f0f9ff 0%, #e0f2fe 100%);
            box-shadow: 0 0 0 2px rgba(2, 132, 199, 0.25);
        }

        .stat-icon {
            width: 44px;
            height: 44px;
            border-radius: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.3rem;
            flex-shrink: 0;
        }

        .stat-val {
            font-size: 1.45rem;
            font-weight: 800;
            line-height: 1.2;
            color: var(--brand-navy);
        }

        .stat-label {
            font-size: 12px;
            font-weight: 600;
            color: #64748b;
        }

        /* 現代化表格 (與 Clean_List 一致) */
        .table-modern {
            width: 100%;
            border-collapse: separate;
            border-spacing: 0;
            margin: 0;
        }

        .table-modern th {
            background: #f8fafc;
            color: #475569;
            font-weight: 700;
            font-size: 13px;
            padding: 14px 16px;
            border-bottom: 2px solid var(--border-color);
            border-top: none;
            white-space: nowrap;
        }

        .table-modern td {
            padding: 14px 16px;
            vertical-align: middle;
            border-bottom: 1px solid var(--border-color);
            color: var(--text-main);
            font-size: 14px;
            background: #ffffff;
        }

        .table-modern tbody tr:hover td {
            background: #f1f5f9;
        }

        /* 徽章樣式 */
        .authority-badge {
            background: #e0f2fe;
            color: #0369a1;
            padding: 4px 8px;
            border-radius: 6px;
            font-size: 12px;
            font-weight: 700;
            display: inline-flex;
            align-items: center;
            gap: 5px;
            white-space: nowrap;
        }

        .tag-pill {
            font-size: 11px;
            font-weight: 700;
            padding: 3px 8px;
            border-radius: 6px;
            display: inline-block;
            white-space: nowrap;
        }

        .badge-sky     { background-color: #e0f2fe; color: #0369a1; }
        .badge-primary { background-color: #dbeafe; color: #1d4ed8; }
        .badge-warning { background-color: #fef3c7; color: #b45309; }
        .badge-success { background-color: #dcfce7; color: #15803d; }
        .badge-cyan    { background-color: #cffafe; color: #0e7490; }
        .badge-indigo  { background-color: #e0e7ff; color: #4338ca; }
        .badge-purple  { background-color: #ede9fe; color: #6d28d9; }
        .badge-danger  { background-color: #fee2e2; color: #b91c1c; }
        .badge-teal    { background-color: #ccfbf1; color: #0f766e; }
        .badge-secondary { background-color: #f1f5f9; color: #475569; }
        .badge-epd     { background-color: #e0f2fe; color: #184b72; border: 1px solid #bae6fd; }
        .badge-rose    { background-color: #ffe4e6; color: #be123c; }

        /* 代碼標籤 */
        .system-code {
            font-family: Consolas, monospace;
            background: #f1f5f9;
            color: #0284c7;
            padding: 2px 7px;
            border-radius: 4px;
            font-size: 12px;
            font-weight: 700;
            border: 1px solid #cbd5e1;
            display: inline-block;
        }

        /* 系統小頭像圖示 */
        .table-icon-avatar {
            width: 36px;
            height: 36px;
            border-radius: 8px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #ffffff;
            font-size: 1rem;
            flex-shrink: 0;
            box-shadow: 0 2px 6px rgba(0, 0, 0, 0.1);
        }

        /* 操作按鈕群組 (與 Clean_List 一致) */
        .action-btn-group {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 6px;
            flex-wrap: nowrap !important;
            white-space: nowrap !important;
        }

        .btn-action {
            padding: 5px 12px;
            font-size: 13px;
            font-weight: 600;
            border-radius: 6px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 5px;
            transition: all 0.15s ease;
            min-height: 34px;
            white-space: nowrap !important;
            flex-shrink: 0;
            text-decoration: none;
        }

        .btn-action:hover {
            text-decoration: none;
        }

        /* 網格卡片檢視 (Grid View - 修正後的原生 CSS Grid) */
        .portal-grid-clean {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(360px, 1fr));
            gap: 20px;
            padding: 20px;
        }

        .portal-card-clean {
            background: #ffffff;
            border: 1px solid var(--border-color);
            border-radius: 12px;
            padding: 20px;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
            transition: all 0.2s ease;
            position: relative;
        }

        .portal-card-clean:hover {
            border-color: #0284c7;
            box-shadow: 0 8px 20px rgba(2, 132, 199, 0.12);
            transform: translateY(-3px);
        }

        .portal-card-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 12px;
        }

        .portal-card-main {
            display: flex;
            align-items: flex-start;
            gap: 14px;
            margin-bottom: 12px;
        }

        .portal-card-icon {
            width: 48px;
            height: 48px;
            border-radius: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #ffffff;
            font-size: 1.35rem;
            flex-shrink: 0;
            box-shadow: 0 3px 8px rgba(0, 0, 0, 0.12);
        }

        .portal-card-title {
            font-size: 1.05rem;
            font-weight: 700;
            color: var(--brand-navy);
            margin: 0 0 4px 0;
            line-height: 1.35;
        }

        .portal-card-desc {
            font-size: 0.88rem;
            color: var(--text-muted);
            line-height: 1.55;
            margin-bottom: 14px;
            min-height: 52px;
            display: -webkit-box;
            -webkit-line-clamp: 3;
            -webkit-box-orient: vertical;
            overflow: hidden;
        }

        .portal-card-url {
            background-color: #f8fafc;
            border: 1px dashed #cbd5e1;
            border-radius: 6px;
            padding: 6px 10px;
            font-size: 12px;
            color: #64748b;
            margin-bottom: 14px;
            display: flex;
            align-items: center;
            gap: 6px;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }

        .portal-card-url span {
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .portal-card-actions {
            display: flex;
            gap: 8px;
            padding-top: 12px;
            border-top: 1px solid #f1f5f9;
        }

        .portal-card-actions .btn-action {
            flex: 1;
            min-height: 40px;
        }

        /* 手機卡片 (與 Clean_List 一致) */
        .mobile-card {
            background: #ffffff;
            border: 1px solid var(--border-color);
            border-radius: 12px;
            padding: 16px;
            margin-bottom: 12px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
        }

        .mobile-card-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 10px;
            padding-bottom: 8px;
            border-bottom: 1px dashed var(--border-color);
        }

        .mobile-card-title {
            font-size: 1rem;
            font-weight: 700;
            color: var(--brand-navy);
            margin: 0;
        }

        /* 浮動 Toast 提示 */
        .toast-bubble {
            position: fixed;
            bottom: 30px;
            left: 50%;
            transform: translateX(-50%);
            background: #0f172a;
            color: #ffffff;
            padding: 11px 22px;
            border-radius: 30px;
            font-size: 14px;
            font-weight: 600;
            display: flex;
            align-items: center;
            gap: 8px;
            box-shadow: 0 8px 24px rgba(0, 0, 0, 0.25);
            z-index: 9999;
            opacity: 0;
            pointer-events: none;
            transition: all 0.25s ease;
        }

        .toast-bubble.show {
            opacity: 1;
            pointer-events: auto;
            transform: translateX(-50%) translateY(-6px);
        }

        @media (max-width: 767.98px) {
            .btn-action {
                min-height: 42px;
                font-size: 14px;
            }
            .portal-grid-clean {
                grid-template-columns: 1fr;
                padding: 12px;
                gap: 14px;
            }
        }
    </style>
</head>
<body>
    <div id="outLinkApp" v-cloak>
        <!-- 頂部品牌導覽列 (符合 SKILL.md 標準規範：回首頁按鈕置於左上角，中文標題精簡為「相關外部系統連結」) -->
        <header class="top-navbar no-print">
            <div class="brand-title">
                <a href="MainPage.aspx" class="nav-btn mr-2" title="回主選單 / 回首頁">
                    <i class="fas fa-arrow-left"></i>
                    <span class="d-none d-sm-inline">回首頁</span>
                </a>
                <i class="fas fa-network-wired text-white"></i>
                <span>相關外部系統連結</span>
                <span class="badge badge-light text-dark font-weight-bold ml-2" style="font-size: 0.85rem;">
                    共 {{ totalCount }} 個系統
                </span>
            </div>
            <div class="d-flex align-items-center" style="gap: 8px;">
                <button type="button" class="nav-btn" v-on:click="resetFilter" title="重新整理所有過濾條件">
                    <i class="fas fa-sync-alt"></i>
                    <span class="d-none d-md-inline">重整</span>
                </button>
            </div>
        </header>

        <!-- 業務模式分頁切換列 (與 Clean_List 一致) -->
        <nav class="nav-mode-bar">
            <div class="nav-mode-item" :class="{ 'active': currentCategory === '全部' }" v-on:click="setCategory('全部')">
                <i class="fas fa-layer-group"></i>
                <span>全部收錄系統</span>
                <span class="tab-badge badge badge-dark">{{ totalCount }}</span>
            </div>
            <div class="nav-mode-item" :class="{ 'active': currentCategory === '中央申報與許可' }" v-on:click="setCategory('中央申報與許可')">
                <i class="fas fa-industry"></i>
                <span>中央申報與許可</span>
                <span class="tab-badge badge badge-primary">{{ getCategoryCount('中央申報與許可') }}</span>
            </div>
            <div class="nav-mode-item" :class="{ 'active': currentCategory === '公開資訊與監測' }" v-on:click="setCategory('公開資訊與監測')">
                <i class="fas fa-chart-line"></i>
                <span>公開資訊與監測</span>
                <span class="tab-badge badge badge-info">{{ getCategoryCount('公開資訊與監測') }}</span>
            </div>
            <div class="nav-mode-item" :class="{ 'active': currentCategory === '圖資與查核輔助' }" v-on:click="setCategory('圖資與查核輔助')">
                <i class="fas fa-map-marked-alt"></i>
                <span>圖資與查核輔助</span>
                <span class="tab-badge badge badge-success">{{ getCategoryCount('圖資與查核輔助') }}</span>
            </div>
            <div class="nav-mode-item" :class="{ 'active': currentCategory === '新北市主管機關' }" v-on:click="setCategory('新北市主管機關')">
                <i class="fas fa-landmark"></i>
                <span>新北市主管機關</span>
                <span class="tab-badge badge badge-warning text-dark">{{ getCategoryCount('新北市主管機關') }}</span>
            </div>
        </nav>

        <main class="container-fluid py-4 px-lg-4">
            <!-- 頂部統計指標卡片 (與 Clean_List 一致) -->
            <div class="row mb-3">
                <div class="col-6 col-lg-3 mb-2 mb-lg-0">
                    <div class="stat-card" :class="{ active: currentCategory === '中央申報與許可' }" v-on:click="setCategory('中央申報與許可')">
                        <div class="stat-icon bg-primary text-white">
                            <i class="fas fa-industry"></i>
                        </div>
                        <div>
                            <div class="stat-val text-primary">{{ getCategoryCount('中央申報與許可') }}</div>
                            <div class="stat-label">中央申報與許可</div>
                        </div>
                    </div>
                </div>

                <div class="col-6 col-lg-3 mb-2 mb-lg-0">
                    <div class="stat-card" :class="{ active: currentCategory === '公開資訊與監測' }" v-on:click="setCategory('公開資訊與監測')">
                        <div class="stat-icon bg-info text-white">
                            <i class="fas fa-chart-line"></i>
                        </div>
                        <div>
                            <div class="stat-val text-info">{{ getCategoryCount('公開資訊與監測') }}</div>
                            <div class="stat-label">公開資訊與監測</div>
                        </div>
                    </div>
                </div>

                <div class="col-6 col-lg-3 mb-2 mb-lg-0">
                    <div class="stat-card" :class="{ active: currentCategory === '圖資與查核輔助' }" v-on:click="setCategory('圖資與查核輔助')">
                        <div class="stat-icon bg-success text-white">
                            <i class="fas fa-map-marked-alt"></i>
                        </div>
                        <div>
                            <div class="stat-val text-success">{{ getCategoryCount('圖資與查核輔助') }}</div>
                            <div class="stat-label">圖資與查核輔助</div>
                        </div>
                    </div>
                </div>

                <div class="col-6 col-lg-3 mb-2 mb-lg-0">
                    <div class="stat-card" :class="{ active: currentCategory === '新北市主管機關' }" v-on:click="setCategory('新北市主管機關')">
                        <div class="stat-icon bg-warning text-dark">
                            <i class="fas fa-landmark"></i>
                        </div>
                        <div>
                            <div class="stat-val text-warning">{{ getCategoryCount('新北市主管機關') }}</div>
                            <div class="stat-label">新北市主管機關</div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- 系統查詢篩選卡片 (與 Clean_List 一致) -->
            <div class="card-modern">
                <div class="card-modern-header">
                    <h2 class="card-modern-title">
                        <i class="fas fa-filter text-primary"></i>
                        <span>系統條件篩選</span>
                    </h2>
                    <div class="d-flex align-items-center gap-2">
                        <button type="button" class="btn btn-sm btn-outline-secondary font-weight-bold" v-on:click="resetFilter">
                            <i class="fas fa-redo-alt mr-1"></i> 重設條件
                        </button>
                    </div>
                </div>

                <div class="card-modern-body">
                    <div class="row">
                        <!-- 主管機關篩選 -->
                        <div class="col-12 col-md-4 mb-3">
                            <label class="font-weight-bold text-muted small mb-1">
                                <i class="fas fa-shield-alt text-primary mr-1"></i> 主管/權責機關
                            </label>
                            <select class="form-control" v-model="filterAuthority" style="font-weight: 600;">
                                <option value="">全部權責機關 ({{ authorities.length }} 單位)</option>
                                <option v-for="auth in authorities" :key="auth" :value="auth">
                                    {{ auth }}
                                </option>
                            </select>
                        </div>

                        <!-- 系統名稱/關鍵字 -->
                        <div class="col-12 col-md-4 mb-3">
                            <label class="font-weight-bold text-muted small mb-1">
                                <i class="fas fa-search text-info mr-1"></i> 系統名稱 / 代碼 / 關鍵字
                            </label>
                            <input type="text" 
                                   class="form-control" 
                                   v-model="searchKeyword" 
                                   placeholder="例如：CEMS, APMIS, 許可證, 空污費, 地籍..." />
                        </div>

                        <!-- 業務分類篩選 -->
                        <div class="col-12 col-md-4 mb-3">
                            <label class="font-weight-bold text-muted small mb-1">
                                <i class="fas fa-tags text-success mr-1"></i> 業務功能分類
                            </label>
                            <select class="form-control" v-model="currentCategory" style="font-weight: 600;">
                                <option v-for="cat in categories" :key="cat" :value="cat">
                                    {{ cat }} ({{ cat === '全部' ? totalCount : getCategoryCount(cat) }} 個系統)
                                </option>
                            </select>
                        </div>
                    </div>

                    <!-- 快捷分類標籤與動作列 (與 Clean_List 一致) -->
                    <div class="d-flex flex-wrap align-items-center justify-content-between pt-2 border-top">
                        <div class="btn-group btn-group-sm mb-2 mb-md-0" role="group">
                            <button type="button" class="btn btn-outline-secondary" :class="{ 'active font-weight-bold': currentCategory === '全部' }" v-on:click="setCategory('全部')">全部</button>
                            <button type="button" class="btn btn-outline-secondary" :class="{ 'active font-weight-bold': currentCategory === '中央申報與許可' }" v-on:click="setCategory('中央申報與許可')">中央申報許可</button>
                            <button type="button" class="btn btn-outline-secondary" :class="{ 'active font-weight-bold': currentCategory === '公開資訊與監測' }" v-on:click="setCategory('公開資訊與監測')">公開數據監測</button>
                            <button type="button" class="btn btn-outline-secondary" :class="{ 'active font-weight-bold': currentCategory === '圖資與查核輔助' }" v-on:click="setCategory('圖資與查核輔助')">空間圖資工具</button>
                            <button type="button" class="btn btn-outline-secondary" :class="{ 'active font-weight-bold': currentCategory === '新北市主管機關' }" v-on:click="setCategory('新北市主管機關')">新北市專區</button>
                        </div>

                        <div class="d-flex align-items-center gap-2">
                            <button type="button" class="btn btn-primary px-4 font-weight-bold shadow-sm" v-on:click="scrollToResult">
                                <i class="fas fa-search mr-1"></i>
                                <span>即時過濾 ({{ filteredLinks.length }} 筆)</span>
                            </button>
                        </div>
                    </div>
                </div>
            </div>

            <!-- 外部系統列表卡片 (與 Clean_List 一致) -->
            <div class="card-modern" id="resultCard">
                <div class="card-modern-header">
                    <h2 class="card-modern-title">
                        <i class="fas fa-list-ul text-primary"></i>
                        <span>{{ currentCategory === '全部' ? '全部收錄外部系統' : currentCategory }}</span>
                        <span class="badge badge-pill badge-light border text-muted ml-2 font-weight-bold" style="font-size: 12px;">
                            共 {{ filteredLinks.length }} 個系統項目
                        </span>
                    </h2>

                    <!-- 檢視模式切換器 (卡片網格 / 表格清單) -->
                    <div class="d-flex align-items-center gap-2">
                        <div class="btn-group btn-group-sm mr-2" role="group">
                            <button type="button" 
                                    class="btn" 
                                    :class="viewMode === 'grid' ? 'btn-primary' : 'btn-outline-secondary'" 
                                    v-on:click="viewMode = 'grid'" 
                                    title="切換卡片網格視圖">
                                <i class="fas fa-th-large"></i>
                                <span class="d-none d-sm-inline ml-1">卡片網格</span>
                            </button>
                            <button type="button" 
                                    class="btn" 
                                    :class="viewMode === 'table' ? 'btn-primary' : 'btn-outline-secondary'" 
                                    v-on:click="viewMode = 'table'" 
                                    title="切換表格清單視圖">
                                <i class="fas fa-table"></i>
                                <span class="d-none d-sm-inline ml-1">表格清單</span>
                            </button>
                        </div>

                        <button type="button" class="btn btn-sm btn-light border font-weight-bold" v-on:click="resetFilter" title="重新整理">
                            <i class="fas fa-sync-alt"></i>
                        </button>
                    </div>
                </div>

                <div class="p-0">
                    <!-- 查無資料 (Empty State 與 Clean_List 一致) -->
                    <div v-if="filteredLinks.length === 0" class="text-center py-5">
                        <div class="mb-3 text-muted" style="font-size: 3rem;">
                            <i class="far fa-folder-open"></i>
                        </div>
                        <h5 class="font-weight-bold text-secondary">查無符合條件的外部系統</h5>
                        <p class="text-muted small">請嘗試清除關鍵字或切換上方業務分類。</p>
                        <button type="button" class="btn btn-primary font-weight-bold px-4 mt-2" v-on:click="resetFilter">
                            <i class="fas fa-redo-alt mr-1"></i> 重設所有條件
                        </button>
                    </div>

                    <!-- 模式一：卡片網格模式 (Grid View - 自適應全載具排版) -->
                    <div v-else-if="viewMode === 'grid'" class="portal-grid-clean">
                        <div v-for="item in filteredLinks" :key="item.Id" class="portal-card-clean">
                            <div>
                                <!-- 卡片頂部 -->
                                <div class="portal-card-header">
                                    <span class="authority-badge">
                                        <i class="fas fa-shield-alt text-primary"></i>
                                        {{ item.Authority }}
                                    </span>
                                    <span class="tag-pill" :class="item.BadgeClass">
                                        {{ item.BadgeText }}
                                    </span>
                                </div>

                                <!-- 卡片標題與圖示 -->
                                <div class="portal-card-main">
                                    <div class="portal-card-icon" :style="{ backgroundColor: item.IconBgColor }">
                                        <i :class="item.IconClass"></i>
                                    </div>
                                    <div>
                                        <div class="mb-1">
                                            <span class="system-code">{{ item.Code }}</span>
                                        </div>
                                        <h3 class="portal-card-title">{{ item.Title }}</h3>
                                    </div>
                                </div>

                                <!-- 說明與網址 -->
                                <div class="portal-card-desc">
                                    {{ item.Description }}
                                </div>

                                <div class="portal-card-url" :title="item.Url">
                                    <i class="fas fa-link text-muted"></i>
                                    <span>{{ item.Url }}</span>
                                </div>
                            </div>

                            <!-- 底部操作按鈕 -->
                            <div class="portal-card-actions">
                                <a :href="item.Url" 
                                   target="_blank" 
                                   rel="noopener noreferrer" 
                                   class="btn-action btn-primary font-weight-bold shadow-sm">
                                    <i class="fas fa-external-link-alt mr-1"></i> 前往系統
                                </a>
                                <button type="button" 
                                        class="btn-action btn-light border font-weight-bold text-secondary" 
                                        v-on:click="copyUrl(item.Url)">
                                    <i class="fas fa-copy mr-1"></i> 複製
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- 模式二：表格清單模式 (Table View - 桌機表格 + 手機卡片降級) -->
                    <div v-else-if="viewMode === 'table'">
                        <!-- 桌機與平板：現代化表格清單 -->
                        <div class="table-responsive d-none d-md-block">
                            <table class="table-modern">
                                <thead>
                                    <tr>
                                        <th style="width: 70px;" class="text-center">代號</th>
                                        <th style="min-width: 220px;">系統名稱</th>
                                        <th style="width: 140px;">業務分類</th>
                                        <th style="width: 170px;">主管/權責機關</th>
                                        <th style="min-width: 280px;">系統主要功能與管制作業簡述</th>
                                        <th style="min-width: 200px; width: 200px; white-space: nowrap;" class="text-center">操作功能</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr v-for="item in filteredLinks" :key="item.Id">
                                        <!-- 代號與圖示 -->
                                        <td class="text-center">
                                            <div class="d-flex flex-column align-items-center">
                                                <div class="table-icon-avatar mb-1" :style="{ backgroundColor: item.IconBgColor }">
                                                    <i :class="item.IconClass"></i>
                                                </div>
                                                <span class="system-code">{{ item.Code }}</span>
                                            </div>
                                        </td>

                                        <!-- 系統名稱 -->
                                        <td>
                                            <div class="font-weight-bold text-dark" style="font-size: 15px;">{{ item.Title }}</div>
                                            <div class="text-muted small">
                                                <i class="fas fa-link mr-1"></i>{{ item.Url }}
                                            </div>
                                        </td>

                                        <!-- 業務分類與標籤 -->
                                        <td>
                                            <div class="font-weight-bold text-secondary small mb-1">{{ item.Category }}</div>
                                            <span class="tag-pill" :class="item.BadgeClass">{{ item.BadgeText }}</span>
                                        </td>

                                        <!-- 主管機關 -->
                                        <td>
                                            <span class="authority-badge">
                                                <i class="fas fa-shield-alt text-primary"></i>
                                                {{ item.Authority }}
                                            </span>
                                        </td>

                                        <!-- 功能簡述 -->
                                        <td>
                                            <div class="text-muted small" style="line-height: 1.55;">
                                                {{ item.Description }}
                                            </div>
                                        </td>

                                        <!-- 操作功能 (單行排列與 Clean_List 一致) -->
                                        <td class="text-center">
                                            <div class="action-btn-group">
                                                <a :href="item.Url" 
                                                   target="_blank" 
                                                   rel="noopener noreferrer" 
                                                   class="btn-action btn-primary font-weight-bold shadow-sm" 
                                                   :title="'前往 ' + item.Title">
                                                    <i class="fas fa-external-link-alt"></i> 前往系統
                                                </a>
                                                <button type="button" 
                                                        class="btn-action btn-light border font-weight-bold text-secondary" 
                                                        v-on:click="copyUrl(item.Url)" 
                                                        title="複製系統網址">
                                                    <i class="fas fa-copy"></i> 複製
                                                </button>
                                            </div>
                                        </td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>

                        <!-- 手機端：轉為精簡行動卡片 -->
                        <div class="d-md-none p-3">
                            <div v-for="item in filteredLinks" :key="'mob_' + item.Id" class="mobile-card">
                                <div class="mobile-card-header">
                                    <div class="d-flex align-items-center gap-2">
                                        <span class="system-code">{{ item.Code }}</span>
                                        <span class="tag-pill" :class="item.BadgeClass">{{ item.BadgeText }}</span>
                                    </div>
                                    <span class="authority-badge">
                                        {{ item.Authority }}
                                    </span>
                                </div>

                                <div class="d-flex align-items-center gap-3 mb-2">
                                    <div class="table-icon-avatar" :style="{ backgroundColor: item.IconBgColor }">
                                        <i :class="item.IconClass"></i>
                                    </div>
                                    <h3 class="mobile-card-title">{{ item.Title }}</h3>
                                </div>

                                <p class="text-muted small mb-2" style="line-height: 1.5;">
                                    {{ item.Description }}
                                </p>

                                <div class="portal-card-url mb-3">
                                    <i class="fas fa-link text-muted"></i>
                                    <span>{{ item.Url }}</span>
                                </div>

                                <div class="d-flex gap-2">
                                    <a :href="item.Url" 
                                       target="_blank" 
                                       rel="noopener noreferrer" 
                                       class="btn-action btn-primary font-weight-bold flex-fill shadow-sm">
                                        <i class="fas fa-external-link-alt mr-1"></i> 前往系統
                                    </a>
                                    <button type="button" 
                                            class="btn-action btn-light border font-weight-bold text-secondary px-3" 
                                            v-on:click="copyUrl(item.Url)">
                                        <i class="fas fa-copy"></i>
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>

                </div>
            </div>
        </main>

        <!-- 複製成功浮動 Toast 提示 -->
        <div class="toast-bubble" :class="{ show: toast.visible }">
            <i class="fas fa-check-circle text-success"></i>
            <span>{{ toast.message }}</span>
        </div>
    </div>

    <!-- 本地靜態腳本相依 -->
    <script src="Scripts/jquery-3.6.4.min.js"></script>
    <script src="Scripts/bootstrap.bundle.min.js"></script>
    <script src="Scripts/vue.global.prod.js"></script>

    <script>
        const serverLinksData = <%= GetLinksJson() %>;
        const { createApp } = Vue;

        createApp({
            data() {
                return {
                    links: serverLinksData || [],
                    categories: ['全部', '中央申報與許可', '公開資訊與監測', '圖資與查核輔助', '新北市主管機關'],
                    currentCategory: '全部',
                    filterAuthority: '',
                    searchKeyword: '',
                    viewMode: 'grid', // 'grid' 或 'table'
                    toast: {
                        visible: false,
                        message: '',
                        timer: null
                    }
                };
            },
            computed: {
                totalCount() {
                    return this.links.length;
                },
                authorities() {
                    const set = {};
                    this.links.forEach(item => {
                        if (item.Authority) {
                            set[item.Authority] = true;
                        }
                    });
                    return Object.keys(set);
                },
                filteredLinks() {
                    let result = this.links;

                    // 1. 分類過濾
                    if (this.currentCategory && this.currentCategory !== '全部') {
                        result = result.filter(item => item.Category === this.currentCategory);
                    }

                    // 2. 主管機關過濾
                    if (this.filterAuthority) {
                        result = result.filter(item => item.Authority === this.filterAuthority);
                    }

                    // 3. 關鍵字過濾
                    const kw = (this.searchKeyword || '').trim().toLowerCase();
                    if (kw) {
                        result = result.filter(item => {
                            const titleMatch = (item.Title || '').toLowerCase().indexOf(kw) !== -1;
                            const codeMatch = (item.Code || '').toLowerCase().indexOf(kw) !== -1;
                            const authMatch = (item.Authority || '').toLowerCase().indexOf(kw) !== -1;
                            const descMatch = (item.Description || '').toLowerCase().indexOf(kw) !== -1;
                            const urlMatch = (item.Url || '').toLowerCase().indexOf(kw) !== -1;
                            const catMatch = (item.Category || '').toLowerCase().indexOf(kw) !== -1;

                            return titleMatch || codeMatch || authMatch || descMatch || urlMatch || catMatch;
                        });
                    }

                    return result;
                }
            },
            methods: {
                setCategory(cat) {
                    this.currentCategory = cat;
                },
                getCategoryCount(cat) {
                    if (!this.links) return 0;
                    return this.links.filter(item => item.Category === cat).length;
                },
                resetFilter() {
                    this.searchKeyword = '';
                    this.filterAuthority = '';
                    this.currentCategory = '全部';
                },
                scrollToResult() {
                    const el = document.getElementById('resultCard');
                    if (el) {
                        el.scrollIntoView({ behavior: 'smooth' });
                    }
                },
                copyUrl(url) {
                    if (!url) return;

                    const self = this;
                    if (navigator.clipboard && window.isSecureContext) {
                        navigator.clipboard.writeText(url).then(function() {
                            self.showToast('系統連結已複製到剪貼簿！');
                        }).catch(function() {
                            self.fallbackCopy(url);
                        });
                    } else {
                        self.fallbackCopy(url);
                    }
                },
                fallbackCopy(text) {
                    const textArea = document.createElement("textarea");
                    textArea.value = text;
                    textArea.style.position = "fixed";
                    textArea.style.top = "-9999px";
                    textArea.style.left = "-9999px";
                    document.body.appendChild(textArea);
                    textArea.focus();
                    textArea.select();

                    try {
                        const successful = document.execCommand('copy');
                        if (successful) {
                            this.showToast('系統連結已複製到剪貼簿！');
                        } else {
                            this.showToast('無法自動複製，請手動複製網址');
                        }
                    } catch (err) {
                        this.showToast('無法自動複製，請手動複製網址');
                    }

                    document.body.removeChild(textArea);
                },
                showToast(msg) {
                    this.toast.message = msg;
                    this.toast.visible = true;

                    if (this.toast.timer) {
                        clearTimeout(this.toast.timer);
                    }

                    const self = this;
                    this.toast.timer = setTimeout(function() {
                        self.toast.visible = false;
                    }, 2200);
                }
            }
        }).mount('#outLinkApp');
    </script>
</body>
</html>
