<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="managerList.aspx.cs" Inherits="NTPC_FEC.Manager.managerList" %>

<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定溢散源管理審查平台 - 案件審查作業</title>

    <!-- 專屬 Favicon -->
    <link rel="shortcut icon" href="../favicon.ico" type="image/x-icon" />

    <!-- 本地化樣式依賴 -->
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

        /* 頂部導覽列 */
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
            color: #ffffff !important;
            font-size: 0.88rem;
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

        /* 模式切換分頁列 */
        .nav-mode-bar {
            background: #ffffff;
            border-bottom: 1px solid var(--border-color);
            padding: 0 20px;
            display: flex;
            gap: 6px;
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
            padding: 13px 18px;
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

        .mode-section-divider {
            width: 1px;
            height: 24px;
            background: var(--border-color);
            margin: auto 6px;
        }

        .tab-badge {
            font-size: 11px;
            padding: 2px 7px;
            border-radius: 12px;
            font-weight: 700;
        }

        /* 統計指標卡片 */
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
            gap: 12px;
            margin-bottom: 16px;
        }

        .stat-card {
            background: #ffffff;
            border-radius: 10px;
            border: 1px solid var(--border-color);
            padding: 14px 16px;
            display: flex;
            align-items: center;
            gap: 14px;
            box-shadow: 0 1px 3px rgba(15, 23, 42, 0.03);
            transition: transform 0.2s, box-shadow 0.2s;
        }

        .stat-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 10px rgba(15, 23, 42, 0.06);
        }

        .stat-icon-wrapper {
            width: 44px;
            height: 44px;
            border-radius: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.25rem;
            flex-shrink: 0;
        }

        .stat-val {
            font-size: 1.45rem;
            font-weight: 700;
            line-height: 1.2;
            color: var(--brand-navy);
        }

        .stat-lbl {
            font-size: 12px;
            color: var(--text-muted);
            margin-top: 2px;
        }

        /* 現代卡片 */
        .card-modern {
            background: var(--surface);
            border-radius: 12px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05), 0 4px 12px rgba(15, 23, 42, 0.04);
            margin-bottom: 16px;
            border: 1px solid var(--border-color);
            overflow: hidden;
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
            padding: 16px;
        }

        /* 行政區晶片群組 */
        .town-chips-wrapper {
            display: flex;
            flex-wrap: wrap;
            gap: 6px;
            max-height: 130px;
            overflow-y: auto;
            padding: 6px;
            background: #f8fafc;
            border: 1px solid var(--border-color);
            border-radius: 8px;
        }

        .town-chip {
            border: 1px solid #cbd5e1;
            background: #ffffff;
            color: #475569;
            padding: 4px 10px;
            border-radius: 6px;
            font-size: 12px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.15s ease;
            user-select: none;
        }

        .town-chip:hover {
            border-color: var(--brand-blue);
            color: var(--brand-blue);
        }

        .town-chip.active {
            background: #0284c7;
            border-color: #0284c7;
            color: #ffffff;
            box-shadow: 0 1px 3px rgba(2, 132, 199, 0.3);
        }

        /* 批次操作提示列 */
        .batch-bar {
            background: linear-gradient(135deg, #eff6ff 0%, #dbeafe 100%);
            border: 1px solid #bfdbfe;
            border-radius: 10px;
            padding: 12px 16px;
            margin-bottom: 16px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-wrap: wrap;
            gap: 10px;
        }

        /* 表格樣式 */
        .modern-table {
            width: 100%;
            border-collapse: separate;
            border-spacing: 0;
        }

        .modern-table th {
            background: #f8fafc;
            color: #475569;
            font-weight: 700;
            font-size: 13px;
            padding: 12px 14px;
            border-bottom: 2px solid var(--border-color);
            white-space: nowrap;
        }

        .modern-table td {
            padding: 12px 14px;
            border-bottom: 1px solid #f1f5f9;
            font-size: 13px;
            vertical-align: middle;
            color: var(--text-main);
        }

        /* 欄位寬度與對齊控制 (防止場所名稱過度佔位，釋放操作區寬度) */
        .col-batch { width: 50px; min-width: 50px; text-align: center; }
        .col-cno { width: 120px; min-width: 120px; text-align: center; }
        .col-facname { max-width: 320px; min-width: 180px; word-break: break-word; line-height: 1.45; }
        .col-town { width: 100px; min-width: 100px; text-align: center; }
        .col-scid { width: 130px; min-width: 130px; text-align: center; }
        .col-count { width: 110px; min-width: 110px; text-align: center; }
        .col-point { width: 120px; min-width: 120px; text-align: center; }
        .col-detail { min-width: 220px; word-break: break-word; }
        .col-actions { width: 230px; min-width: 230px; text-align: center; white-space: nowrap; }

        /* 審查功能按鈕群組 (防折行、維持舒適間距) */
        .action-btn-group {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            white-space: nowrap;
        }

        .action-btn-group .btn {
            white-space: nowrap !important;
            padding: 6px 12px;
            font-size: 13px;
            font-weight: 700;
            border-radius: 6px !important;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 5px;
            line-height: 1.4;
            transition: all 0.15s ease;
        }

        .action-btn-group .btn-warning {
            background-color: #f59e0b;
            border-color: #d97706;
            color: #ffffff;
        }

        .action-btn-group .btn-warning:hover {
            background-color: #d97706;
            border-color: #b45309;
            color: #ffffff;
        }

        .action-btn-group .btn-outline-info {
            color: #0284c7;
            border-color: #0284c7;
            background-color: #ffffff;
        }

        .action-btn-group .btn-outline-info:hover {
            background-color: #f0f9ff;
            color: #0369a1;
            border-color: #0369a1;
        }

        .modern-table tbody tr {
            transition: background-color 0.15s ease;
        }

        .modern-table tbody tr:hover {
            background-color: #f8fafc;
        }

        /* 缺失標籤 */
        .badge-loss-zero {
            background-color: #ecfdf5;
            color: #047857;
            border: 1px solid #a7f3d0;
            font-weight: 700;
            padding: 4px 8px;
            border-radius: 6px;
            display: inline-flex;
            align-items: center;
            gap: 4px;
        }

        .badge-loss-minor {
            background-color: #fffbeb;
            color: #b45309;
            border: 1px solid #fde68a;
            font-weight: 700;
            padding: 4px 8px;
            border-radius: 6px;
            display: inline-flex;
            align-items: center;
            gap: 4px;
        }

        .badge-loss-major {
            background-color: #fef2f2;
            color: #b91c1c;
            border: 1px solid #fecaca;
            font-weight: 700;
            padding: 4px 8px;
            border-radius: 6px;
            display: inline-flex;
            align-items: center;
            gap: 4px;
        }

        /* 側邊抽屜式面板 (Drawer / Offcanvas) */
        .drawer-overlay {
            position: fixed;
            top: 0; left: 0; right: 0; bottom: 0;
            background: rgba(15, 23, 42, 0.45);
            z-index: 1050;
            backdrop-filter: blur(2px);
            opacity: 0;
            visibility: hidden;
            transition: all 0.25s ease;
        }

        .drawer-overlay.active {
            opacity: 1;
            visibility: visible;
        }

        .drawer-panel {
            position: fixed;
            top: 0; right: 0; bottom: 0;
            width: 720px;
            max-width: 95vw;
            background: #ffffff;
            z-index: 1060;
            box-shadow: -4px 0 24px rgba(0, 0, 0, 0.15);
            transform: translateX(100%);
            transition: transform 0.3s cubic-bezier(0.16, 1, 0.3, 1);
            display: flex;
            flex-direction: column;
        }

        .drawer-panel.active {
            transform: translateX(0);
        }

        .drawer-header {
            padding: 16px 20px;
            border-bottom: 1px solid var(--border-color);
            display: flex;
            align-items: center;
            justify-content: space-between;
            background: #f8fafc;
        }

        .drawer-body {
            padding: 20px;
            overflow-y: auto;
            flex: 1;
        }

        /* 案件卡片時間軸 */
        .case-item-card {
            background: #ffffff;
            border: 1px solid var(--border-color);
            border-radius: 10px;
            padding: 14px 16px;
            margin-bottom: 12px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.03);
            transition: all 0.2s ease;
        }

        .case-item-card:hover {
            border-color: #cbd5e1;
            box-shadow: 0 3px 8px rgba(0,0,0,0.06);
        }

        /* 手機端自適應卡片 */
        @media screen and (max-width: 991px) {
            .table-desktop-view {
                display: none !important;
            }

            .mobile-card-list {
                display: block !important;
            }

            .mobile-fac-card {
                background: #ffffff;
                border: 1px solid var(--border-color);
                border-radius: 12px;
                padding: 16px;
                margin-bottom: 12px;
                box-shadow: 0 2px 6px rgba(15, 23, 42, 0.04);
            }
        }

        @media screen and (min-width: 992px) {
            .table-desktop-view {
                display: table !important;
            }

            .mobile-card-list {
                display: none !important;
            }
        }

        /* 快速載入遮罩 */
        .loading-spinner {
            display: inline-block;
            width: 1.5rem;
            height: 1.5rem;
            border: 3px solid rgba(2, 132, 199, 0.2);
            border-top-color: #0284c7;
            border-radius: 50%;
            animation: spin 0.8s linear infinite;
        }

        @keyframes spin {
            to { transform: rotate(360deg); }
        }
    </style>
</head>
<body>
    <div id="managerApp" v-cloak>
        <!-- 頂部導覽列 (全站標準左側導航、右側使用者資訊) -->
        <header class="top-navbar">
            <div class="d-flex align-items-center">
                <a href="../MainPage.aspx" class="nav-btn mr-2" title="返回主選單">
                    <i class="fas fa-home"></i>
                    <span class="d-none d-sm-inline">回首頁</span>
                </a>
                <a href="managerList.aspx" class="navbar-brand-title">
                    <i class="fas fa-tasks text-white"></i>
                    <span>固定溢散源管理審查平台</span>
                    <span class="badge badge-light text-dark font-weight-bold ml-1">
                        {{ stats.TotalCases }} 筆待審
                    </span>
                </a>
            </div>

            <div class="d-flex align-items-center gap-2">
                <span class="badge badge-pill badge-light py-2 px-3 text-secondary" style="font-size: 13px;">
                    <i class="fas fa-user-shield mr-1 text-primary"></i> {{ currentUser }}
                </span>
            </div>
        </header>

        <!-- 審查模式分頁列 -->
        <nav class="nav-mode-bar">
            <!-- 現場巡查審核 (INV) -->
            <div class="nav-mode-item" :class="{ active: currentMode === 'INV1' }" v-on:click="switchMode('INV1')">
                <i class="fas fa-file-signature"></i>
                <span>巡查初審</span>
                <span v-if="currentMode === 'INV1'" class="tab-badge badge badge-primary">{{ stats.TotalFac }}</span>
            </div>
            <div class="nav-mode-item" :class="{ active: currentMode === 'INV2' }" v-on:click="switchMode('INV2')">
                <i class="fas fa-check-double"></i>
                <span>巡查複審</span>
                <span v-if="currentMode === 'INV2'" class="tab-badge badge badge-primary">{{ stats.TotalFac }}</span>
            </div>
            <div class="nav-mode-item" :class="{ active: currentMode === 'INV3' }" v-on:click="switchMode('INV3')">
                <i class="fas fa-stamp"></i>
                <span>巡查三審</span>
                <span v-if="currentMode === 'INV3'" class="tab-badge badge badge-primary">{{ stats.TotalFac }}</span>
            </div>
            <div class="nav-mode-item" :class="{ active: currentMode === 'INVSM1' }" v-on:click="switchMode('INVSM1')">
                <i class="fas fa-exclamation-triangle text-danger"></i>
                <span>二項缺失以上</span>
                <span v-if="currentMode === 'INVSM1'" class="tab-badge badge badge-danger">{{ stats.TotalFac }}</span>
            </div>

            <div class="mode-section-divider"></div>

            <!-- 機具調查審核 (MAC) -->
            <div class="nav-mode-item" :class="{ active: currentMode === 'MAC1' }" v-on:click="switchMode('MAC1')">
                <i class="fas fa-truck-monster"></i>
                <span>機具初審</span>
                <span v-if="currentMode === 'MAC1'" class="tab-badge badge badge-info">{{ stats.TotalFac }}</span>
            </div>
            <div class="nav-mode-item" :class="{ active: currentMode === 'MAC2' }" v-on:click="switchMode('MAC2')">
                <i class="fas fa-truck-pickup"></i>
                <span>機具複審</span>
                <span v-if="currentMode === 'MAC2'" class="tab-badge badge badge-info">{{ stats.TotalFac }}</span>
            </div>
            <div class="nav-mode-item" :class="{ active: currentMode === 'MAC3' }" v-on:click="switchMode('MAC3')">
                <i class="fas fa-tools"></i>
                <span>機具三審</span>
                <span v-if="currentMode === 'MAC3'" class="tab-badge badge badge-info">{{ stats.TotalFac }}</span>
            </div>
        </nav>

        <!-- 主體內容區塊 -->
        <main class="container-fluid py-3 px-3 px-md-4">
            <!-- 統計指標卡片 -->
            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-icon-wrapper bg-light text-primary">
                        <i class="fas fa-building"></i>
                    </div>
                    <div>
                        <div class="stat-val">{{ stats.TotalFac }}</div>
                        <div class="stat-lbl">待審場所總數</div>
                    </div>
                </div>

                <div class="stat-card">
                    <div class="stat-icon-wrapper bg-light text-info">
                        <i class="fas fa-clipboard-list"></i>
                    </div>
                    <div>
                        <div class="stat-val">{{ stats.TotalCases }}</div>
                        <div class="stat-lbl">待審案件筆數 ({{ countColName }})</div>
                    </div>
                </div>

                <div class="stat-card" v-if="isInvMode">
                    <div class="stat-icon-wrapper" style="background: #ecfdf5; color: #059669;">
                        <i class="fas fa-check-circle"></i>
                    </div>
                    <div>
                        <div class="stat-val text-success">{{ stats.ZeroLoss }}</div>
                        <div class="stat-lbl">合格零缺失場所</div>
                    </div>
                </div>

                <div class="stat-card" v-if="isInvMode">
                    <div class="stat-icon-wrapper" style="background: #fffbeb; color: #d97706;">
                        <i class="fas fa-exclamation-circle"></i>
                    </div>
                    <div>
                        <div class="stat-val text-warning">{{ stats.MinorLoss }}</div>
                        <div class="stat-lbl">記點 1~9 點場所</div>
                    </div>
                </div>

                <div class="stat-card" v-if="isInvMode">
                    <div class="stat-icon-wrapper" style="background: #fef2f2; color: #dc2626;">
                        <i class="fas fa-times-circle"></i>
                    </div>
                    <div>
                        <div class="stat-val text-danger">{{ stats.MajorLoss }}</div>
                        <div class="stat-lbl">記點 10 點以上 點場所</div>
                    </div>
                </div>
            </div>

            <!-- 查詢篩選卡片 -->
            <div class="card-modern">
                <div class="card-modern-header">
                    <h2 class="card-modern-title">
                        <i class="fas fa-filter text-primary"></i> 條件篩選與行政區設定
                    </h2>
                    <button type="button" class="btn btn-sm btn-link text-muted" v-on:click="toggleFilterCollapse">
                        <i class="fas" :class="isFilterCollapsed ? 'fa-chevron-down' : 'fa-chevron-up'"></i>
                        <span class="d-none d-sm-inline">{{ isFilterCollapsed ? '展開篩選' : '收合篩選' }}</span>
                    </button>
                </div>

                <div class="card-modern-body" v-show="!isFilterCollapsed">
                    <div class="row">
                        <div class="col-12 col-md-4 mb-3">
                            <label class="font-weight-bold text-secondary small mb-1">公私場所名稱</label>
                            <div class="input-group">
                                <div class="input-group-prepend">
                                    <span class="input-group-text bg-white"><i class="fas fa-industry text-muted"></i></span>
                                </div>
                                <input type="text" class="form-control" v-model.trim="filter.facName" placeholder="輸入場所關鍵字" v-on:keyup.enter="fetchList" />
                            </div>
                        </div>

                        <div class="col-12 col-sm-6 col-md-4 mb-3">
                            <label class="font-weight-bold text-secondary small mb-1">管制編號</label>
                            <div class="input-group">
                                <div class="input-group-prepend">
                                    <span class="input-group-text bg-white"><i class="fas fa-barcode text-muted"></i></span>
                                </div>
                                <input type="text" class="form-control" v-model.trim="filter.cno" placeholder="如 F1234567" v-on:keyup.enter="fetchList" />
                            </div>
                        </div>

                        <div class="col-12 col-sm-6 col-md-4 mb-3">
                            <label class="font-weight-bold text-secondary small mb-1">統一編號</label>
                            <div class="input-group">
                                <div class="input-group-prepend">
                                    <span class="input-group-text bg-white"><i class="fas fa-id-card text-muted"></i></span>
                                </div>
                                <input type="text" class="form-control" v-model.trim="filter.scid" placeholder="8 位統一編號" v-on:keyup.enter="fetchList" />
                            </div>
                        </div>

                        <!-- 行政區晶片選擇列 -->
                        <div class="col-12 mb-3">
                            <div class="d-flex align-items-center justify-content-between mb-2">
                                <label class="font-weight-bold text-secondary small mb-0">
                                    行政區範圍 (已選 {{ selectedTowns.length }} / {{ townList.length }})
                                </label>
                                <div>
                                    <button type="button" class="btn btn-xs btn-outline-primary py-0 px-2 mr-1" v-on:click="selectAllTowns">
                                        <i class="fas fa-check-square"></i> 全選
                                    </button>
                                    <button type="button" class="btn btn-xs btn-outline-secondary py-0 px-2" v-on:click="clearAllTowns">
                                        <i class="fas fa-square"></i> 清除
                                    </button>
                                </div>
                            </div>
                            <div class="town-chips-wrapper">
                                <button v-for="t in townList" :key="t.Code" type="button" 
                                        class="town-chip" :class="{ active: isTownSelected(t.Code) }"
                                        v-on:click="toggleTown(t.Code)">
                                    {{ t.Name }}
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- 底部標準操作列 (左側統計、右側重設與查詢) -->
                    <div class="d-flex justify-content-between align-items-center mt-2 pt-2 border-top">
                        <div class="small text-muted">
                            共查詢到 <strong class="text-primary">{{ items.length }}</strong> 家待審查場所
                        </div>
                        <div>
                            <button type="button" class="btn btn-outline-secondary btn-sm mr-2" v-on:click="resetFilter">
                                <i class="fas fa-undo mr-1"></i> 重設條件
                            </button>
                            <button type="button" class="btn btn-primary btn-sm px-3 font-weight-bold" v-on:click="fetchList" :disabled="loading">
                                <i class="fas fa-search mr-1"></i> 立即查詢
                            </button>
                        </div>
                    </div>
                </div>
            </div>

            <!-- 批次通過操作列 (限 INV2 與 INV3 模式) -->
            <div v-if="canShowBatchBar" class="batch-bar">
                <div class="d-flex align-items-center">
                    <span class="badge badge-primary mr-2 p-2">批次審查</span>
                    <span class="text-primary font-weight-bold mr-3">
                        已選取 {{ batchSelectedFacIds.length }} 筆合格場所
                    </span>
                    <small class="text-muted d-none d-md-inline">
                        ※ 僅零缺失 (合格) 案件支援一鍵批次審核通過並自動推進至下一審查階段
                    </small>
                </div>
                <div class="d-flex align-items-center gap-2">
                    <button type="button" class="btn btn-sm btn-outline-primary mr-2" v-on:click="selectAllBatchable">
                        <i class="fas fa-check-double mr-1"></i> 選取全部合格場所
                    </button>
                    <button type="button" class="btn btn-sm btn-outline-secondary mr-2" v-on:click="clearBatchSelection" :disabled="batchSelectedFacIds.length === 0">
                        <i class="fas fa-times mr-1"></i> 取消選取
                    </button>
                    <button type="button" class="btn btn-sm btn-success font-weight-bold px-3 shadow-sm" 
                            v-on:click="executeBatchPass" :disabled="batchSelectedFacIds.length === 0 || batchProcessing">
                        <i class="fas fa-bolt mr-1"></i>
                        <span>{{ batchProcessing ? '處理中...' : '一鍵批次審核通過' }}</span>
                    </button>
                </div>
            </div>

            <!-- 主資料表格卡片 (標準清單大四元操作工具列) -->
            <div class="card-modern">
                <div class="card-modern-header">
                    <div class="d-flex align-items-center gap-2">
                        <h2 class="card-modern-title">
                            <i class="fas fa-list-alt text-primary"></i>
                            <span>審查場所清單</span>
                        </h2>
                        <span class="badge badge-light border text-dark font-weight-bold ml-1">
                            共 {{ items.length }} 家場所
                        </span>
                    </div>

                    <div class="d-flex align-items-center">
                        <span v-if="loading" class="text-primary small mr-3">
                            <span class="spinner-border spinner-border-sm mr-1"></span> 資料載入中...
                        </span>

                        <!-- 1. 重新整理 -->
                        <button type="button" class="btn btn-sm btn-outline-secondary mr-2" v-on:click="fetchList" :disabled="loading" title="重新整理待審清單">
                            <i class="fas fa-sync-alt mr-1" :class="{ 'fa-spin': loading }"></i>
                            <span class="d-none d-md-inline">重新整理</span>
                        </button>

                        <!-- 2. 匯出 EXCEL -->
                        <button type="button" class="btn btn-sm btn-outline-success font-weight-bold mr-2" v-on:click="exportExcel" :disabled="exporting || items.length === 0" title="匯出當前待審清單 Excel">
                            <i class="fas fa-file-excel mr-1"></i>
                            <span class="d-none d-md-inline">{{ exporting ? '匯出中...' : '匯出 EXCEL' }}</span>
                        </button>
                    </div>
                </div>

                <div class="card-modern-body p-0">
                    <!-- 電腦版表格 (Desktop Table) -->
                    <div class="table-responsive table-desktop-view">
                        <table class="modern-table">
                            <thead>
                                <tr>
                                    <th v-if="canShowBatchBar" class="col-batch">選取</th>
                                    <th class="col-cno">管制編號</th>
                                    <th class="col-facname">場所名稱</th>
                                    <th class="col-town">行政區</th>
                                    <th class="col-scid">統一編號</th>
                                    <th class="col-count">{{ countColName }}</th>
                                    <th v-if="isInvMode" class="col-point">缺失記點</th>
                                    <th v-if="isInvMode" class="col-detail">最新缺失內容</th>
                                    <th class="col-actions">審查功能</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr v-if="items.length === 0">
                                    <td :colspan="isInvMode ? (canShowBatchBar ? 9 : 8) : (canShowBatchBar ? 7 : 6)" class="text-center py-5 text-muted">
                                        <i class="fas fa-inbox fa-3x mb-3 text-secondary opacity-50 d-block"></i>
                                        <p class="mb-0 font-weight-bold">目前條件下無待審查案件</p>
                                    </td>
                                </tr>

                                <tr v-for="item in items" :key="item.FAC_ID">
                                    <!-- 批次勾選框 -->
                                    <td v-if="canShowBatchBar" class="col-batch">
                                        <input type="checkbox" :value="item.FAC_ID" v-model="batchSelectedFacIds" 
                                               :disabled="!item.CanBatchSelect" :title="item.CanBatchSelect ? '勾選進行批次審核' : '僅合格案件可批次通過'" />
                                    </td>

                                    <!-- 管制編號 -->
                                    <td class="col-cno">
                                        <span class="font-weight-bold text-dark font-monospace">{{ item.C_NO || '-' }}</span>
                                    </td>

                                    <!-- 場所名稱 -->
                                    <td class="col-facname">
                                        <span class="font-weight-bold text-primary">{{ item.FAC_NAME }}</span>
                                    </td>

                                    <!-- 行政區 -->
                                    <td class="col-town">
                                        <span class="badge badge-light border text-secondary font-weight-bold">{{ item.TOWN_Name }}</span>
                                    </td>

                                    <!-- 統一編號 -->
                                    <td class="col-scid">
                                        <button v-if="item.S_C_ID" type="button" class="btn btn-link btn-sm p-0 font-weight-bold font-monospace" 
                                                v-on:click="openCompanyModal(item.S_C_ID)" title="點擊查詢商工登記資料">
                                            <i class="fas fa-search-plus mr-1 small"></i>{{ item.S_C_ID }}
                                        </button>
                                        <span v-else class="text-muted">-</span>
                                    </td>

                                    <!-- 待審件數 -->
                                    <td class="col-count">
                                        <span class="badge badge-pill badge-primary px-2 py-1 font-weight-bold" style="font-size: 13px;">
                                            {{ item.Case_Count }} 筆
                                        </span>
                                    </td>

                                    <!-- 缺失記點 (INV 專用) -->
                                    <td v-if="isInvMode" class="col-point">
                                        <span v-if="item.Loss_Point === 0" class="badge-loss-zero">
                                            <i class="fas fa-check"></i> 0 點 (合格)
                                        </span>
                                        <span v-else-if="item.Loss_Point > 0 && item.Loss_Point < 10" class="badge-loss-minor">
                                            <i class="fas fa-exclamation"></i> {{ item.Loss_Point }} 點
                                        </span>
                                        <span v-else class="badge-loss-major">
                                            <i class="fas fa-radiation"></i> {{ item.Loss_Point }} 點
                                        </span>
                                    </td>

                                    <!-- 最新缺失詳細 (INV 專用) -->
                                    <td v-if="isInvMode" class="col-detail">
                                        <div class="small" :title="item.Loss_Detail">
                                            <span v-if="item.Loss_Point === 0" class="text-success font-weight-bold">無缺失項目</span>
                                            <span v-else class="text-danger">{{ item.Loss_Detail }}</span>
                                        </div>
                                    </td>

                                    <!-- 操作功能 (寬度充裕、絕不折行) -->
                                    <td class="col-actions">
                                        <div class="action-btn-group">
                                            <button type="button" class="btn btn-warning font-weight-bold shadow-sm" v-on:click="handleRunCheck(item)" title="進行本案審查">
                                                <i class="fas fa-pen-fancy"></i>
                                                <span>進行審查</span>
                                            </button>
                                            <button type="button" class="btn btn-outline-info font-weight-bold" v-on:click="openCaseDrawer(item)" title="檢視所有歷次查核紀錄">
                                                <i class="fas fa-history"></i>
                                                <span>歷次案件</span>
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>

                    <!-- 行動版卡片列表 (Mobile Card Stack) -->
                    <div class="mobile-card-list p-3">
                        <div v-if="items.length === 0" class="text-center py-5 text-muted">
                            <i class="fas fa-inbox fa-3x mb-3 text-secondary opacity-50 d-block"></i>
                            <p class="mb-0 font-weight-bold">目前條件下無待審查案件</p>
                        </div>

                        <div v-for="item in items" :key="item.FAC_ID" class="mobile-fac-card">
                            <div class="d-flex align-items-center justify-content-between mb-2">
                                <span class="badge badge-light border text-secondary font-weight-bold">{{ item.TOWN_Name }}</span>
                                <span class="badge badge-pill badge-primary font-weight-bold">{{ item.Case_Count }} 筆待審</span>
                            </div>

                            <h3 class="h6 font-weight-bold text-primary mb-1">{{ item.FAC_NAME }}</h3>
                            <div class="small text-muted mb-2">
                                管制編號：<span class="font-monospace text-dark font-weight-bold">{{ item.C_NO || '-' }}</span>
                                <span class="mx-2">|</span>
                                統編：
                                <button v-if="item.S_C_ID" type="button" class="btn btn-link btn-sm p-0 font-weight-bold" v-on:click="openCompanyModal(item.S_C_ID)">
                                    {{ item.S_C_ID }}
                                </button>
                                <span v-else>-</span>
                            </div>

                            <!-- 缺失摘要 -->
                            <div v-if="isInvMode" class="mb-3 p-2 rounded" :style="getMobileLossBoxStyle(item.Loss_Point)">
                                <div class="d-flex align-items-center justify-content-between mb-1">
                                    <span class="small font-weight-bold">缺失記點：</span>
                                    <span v-if="item.Loss_Point === 0" class="badge-loss-zero"><i class="fas fa-check"></i> 0 點 (合格)</span>
                                    <span v-else-if="item.Loss_Point < 10" class="badge-loss-minor"><i class="fas fa-exclamation"></i> {{ item.Loss_Point }} 點</span>
                                    <span v-else class="badge-loss-major"><i class="fas fa-radiation"></i> {{ item.Loss_Point }} 點</span>
                                </div>
                                <div class="small text-truncate" :title="item.Loss_Detail">
                                    <span v-if="item.Loss_Point === 0" class="text-success">無缺失項目</span>
                                    <span v-else class="text-danger">{{ item.Loss_Detail }}</span>
                                </div>
                            </div>

                            <!-- 批次勾選 (若可批次) -->
                            <div v-if="canShowBatchBar && item.CanBatchSelect" class="form-check mb-2">
                                <input class="form-check-input" type="checkbox" :value="item.FAC_ID" v-model="batchSelectedFacIds" :id="'mChk_' + item.FAC_ID">
                                <label class="form-check-label small text-secondary font-weight-bold" :for="'mChk_' + item.FAC_ID">
                                    選取此合格場所進行批次通過
                                </label>
                            </div>

                            <!-- 功能按鈕群組 (手機全寬) -->
                            <div class="d-flex gap-2 mt-2">
                                <button type="button" class="btn btn-warning font-weight-bold flex-fill py-2" v-on:click="handleRunCheck(item)">
                                    <i class="fas fa-pen-fancy mr-1"></i>進行審查
                                </button>
                                <button type="button" class="btn btn-outline-info font-weight-bold flex-fill py-2" v-on:click="openCaseDrawer(item)">
                                    <i class="fas fa-history mr-1"></i>歷次案件
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </main>

        <!-- 歷次案件抽屜 (Case Drawer Panel) -->
        <div class="drawer-overlay" :class="{ active: isDrawerOpen }" v-on:click="closeCaseDrawer"></div>
        <div class="drawer-panel" :class="{ active: isDrawerOpen }">
            <div class="drawer-header">
                <div>
                    <h3 class="h6 font-weight-bold text-primary mb-1">
                        <i class="fas fa-history mr-1"></i> 歷次案件審查明細
                    </h3>
                    <div class="small text-muted">
                        {{ selectedFac ? selectedFac.FAC_NAME : '' }} ({{ selectedFac ? selectedFac.C_NO : '' }})
                    </div>
                </div>
                <button type="button" class="btn btn-sm btn-light rounded-circle" v-on:click="closeCaseDrawer" style="width: 32px; height: 32px;">
                    <i class="fas fa-times"></i>
                </button>
            </div>

            <div class="drawer-body">
                <div v-if="drawerLoading" class="text-center py-5 text-muted">
                    <div class="loading-spinner mb-2"></div>
                    <p class="small mb-0">載入案件資料中...</p>
                </div>

                <div v-else-if="drawerCases.length === 0" class="text-center py-5 text-muted">
                    <i class="fas fa-folder-open fa-2x mb-2 text-secondary opacity-50"></i>
                    <p class="font-weight-bold mb-0">此場所目前無歷次查核案件記錄</p>
                </div>

                <div v-else>
                    <!-- 巡查類案件列表 -->
                    <div v-if="isInvMode">
                        <div v-for="c in drawerCases" :key="c.CaseId" class="case-item-card">
                            <div class="d-flex align-items-center justify-content-between mb-2">
                                <span class="font-weight-bold text-dark">
                                    <i class="far fa-calendar-alt text-primary mr-1"></i> {{ c.CaseDate || '查核時間未載' }}
                                </span>
                                <span class="badge badge-light border text-secondary">{{ c.StateName }}</span>
                            </div>

                            <div class="mb-2 small">
                                <span class="text-secondary font-weight-bold">現場作業狀況：</span>
                                <span>{{ c.WorkState || '-' }}</span>
                            </div>

                            <div class="mb-2">
                                <div class="d-flex align-items-center justify-content-between mb-1">
                                    <span class="small font-weight-bold text-secondary">缺失記點：</span>
                                    <span v-if="c.LossPoint === 0" class="badge-loss-zero"><i class="fas fa-check"></i> 0 點 (合格)</span>
                                    <span v-else-if="c.LossPoint < 10" class="badge-loss-minor"><i class="fas fa-exclamation"></i> {{ c.LossPoint }} 點</span>
                                    <span v-else class="badge-loss-major"><i class="fas fa-radiation"></i> {{ c.LossPoint }} 點</span>
                                </div>
                                <div class="small bg-light p-2 rounded text-secondary" style="line-height: 1.5;">
                                    {{ c.LossDetail }}
                                </div>
                            </div>

                            <div class="d-flex align-items-center justify-content-end gap-2 mt-3 pt-2 border-top">
                                <a v-if="c.CheckUrl" :href="c.CheckUrl" class="btn btn-sm btn-primary font-weight-bold mr-2">
                                    <i class="fas fa-edit mr-1"></i> 進行{{ getCheckBtnText() }}
                                </a>
                                <a :href="c.ViewUrl" target="_blank" class="btn btn-sm btn-outline-secondary">
                                    <i class="fas fa-eye mr-1"></i> 檢視巡查紀錄
                                </a>
                            </div>
                        </div>
                    </div>

                    <!-- 機具類案件列表 -->
                    <div v-else>
                        <div v-for="c in drawerCases" :key="c.CaseId" class="case-item-card">
                            <div class="d-flex align-items-center justify-content-between mb-2">
                                <span class="font-weight-bold text-dark">
                                    <i class="far fa-calendar-alt text-info mr-1"></i> {{ c.CaseDate || '調查時間未載' }}
                                </span>
                                <span class="badge badge-light border text-secondary">{{ c.StateName }}</span>
                            </div>

                            <div class="row small mb-2">
                                <div class="col-6 mb-1">
                                    <span class="text-secondary font-weight-bold">機具種類：</span>{{ c.MacType }}
                                </div>
                                <div class="col-6 mb-1">
                                    <span class="text-secondary font-weight-bold">廠牌：</span>{{ c.Brand }}
                                </div>
                                <div class="col-12">
                                    <span class="text-secondary font-weight-bold">型號：</span>{{ c.Model }}
                                </div>
                            </div>

                            <div class="d-flex align-items-center justify-content-end gap-2 mt-3 pt-2 border-top">
                                <a v-if="c.CheckUrl" :href="c.CheckUrl" class="btn btn-sm btn-info text-white font-weight-bold mr-2">
                                    <i class="fas fa-edit mr-1"></i> 進行機具{{ getCheckBtnText() }}
                                </a>
                                <a :href="c.ViewUrl" class="btn btn-sm btn-outline-secondary">
                                    <i class="fas fa-eye mr-1"></i> 檢視機具資料
                                </a>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- 商工登記資料 Modal -->
        <div class="modal fade" id="companyModal" tabindex="-1" role="dialog" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered" role="document">
                <div class="modal-content shadow-lg border-0" style="border-radius: 12px; overflow: hidden;">
                    <div class="modal-header bg-primary text-white">
                        <h4 class="modal-title font-weight-bold h6 mb-0">
                            <i class="fas fa-building mr-2"></i> 經濟部商工登記公開資訊
                        </h4>
                        <button type="button" class="close text-white" data-dismiss="modal" aria-label="Close">
                            <span aria-hidden="true">&times;</span>
                        </button>
                    </div>

                    <div class="modal-body p-4">
                        <div v-if="companyModalLoading" class="text-center py-4">
                            <div class="loading-spinner mb-2"></div>
                            <p class="small text-muted mb-0">連線經濟部商工登記公開 API 查詢中...</p>
                        </div>

                        <div v-else-if="companyInfo">
                            <table class="table table-bordered mb-0 small">
                                <tbody>
                                    <tr>
                                        <th class="bg-light text-secondary" style="width: 30%;">統一編號</th>
                                        <td class="font-weight-bold font-monospace text-primary">{{ companyInfo.SCID }}</td>
                                    </tr>
                                    <tr>
                                        <th class="bg-light text-secondary">公司行號名稱</th>
                                        <td class="font-weight-bold">{{ companyInfo.CompanyName }}</td>
                                    </tr>
                                    <tr>
                                        <th class="bg-light text-secondary">登記狀態</th>
                                        <td>
                                            <span class="badge badge-success">{{ companyInfo.CompanyStatus || '營業中' }}</span>
                                        </td>
                                    </tr>
                                    <tr>
                                        <th class="bg-light text-secondary">負責人姓名</th>
                                        <td>{{ companyInfo.ResponsibleName }}</td>
                                    </tr>
                                    <tr>
                                        <th class="bg-light text-secondary">登記地址</th>
                                        <td>{{ companyInfo.CompanyLocation }}</td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>

                        <div v-else class="text-center py-4 text-muted">
                            <i class="fas fa-exclamation-triangle fa-2x mb-2 text-warning"></i>
                            <p class="font-weight-bold mb-0">查無此統一編號之商工登記資料</p>
                        </div>
                    </div>

                    <div class="modal-footer bg-light py-2">
                        <a v-if="companyInfo && companyInfo.SCID" :href="'https://findbiz.nat.gov.tw/fts/query/QueryBar/queryInside.do?banNo=' + companyInfo.SCID" 
                           target="_blank" class="btn btn-sm btn-outline-primary mr-auto">
                            <i class="fas fa-external-link-alt mr-1"></i> 前往商工登記公示網
                        </a>
                        <button type="button" class="btn btn-sm btn-secondary" data-dismiss="modal">關閉</button>
                    </div>
                </div>
            </div>
        </div>

    </div>

    <!-- 本地化依賴腳本 -->
    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>
    <script src="../Scripts/jquery.min.js"></script>
    <script src="../Scripts/bootstrap.bundle.min.js"></script>

    <script>
        const { createApp } = Vue;

        createApp({
            data() {
                return {
                    loading: false,
                    currentUser: '系統管理員',
                    currentMode: 'INV1',
                    isFilterCollapsed: false,

                    // 行政區
                    townList: [],
                    selectedTowns: [],

                    // 篩選條件
                    filter: {
                        facName: '',
                        cno: '',
                        scid: ''
                    },

                    // 統計數值
                    countColName: '初審件數',
                    stats: {
                        TotalFac: 0,
                        TotalCases: 0,
                        ZeroLoss: 0,
                        MinorLoss: 0,
                        MajorLoss: 0
                    },

                    // 主列表
                    items: [],

                    // 批次審核
                    batchSelectedFacIds: [],
                    batchProcessing: false,

                    // 側邊抽屜歷次案件
                    isDrawerOpen: false,
                    drawerLoading: false,
                    selectedFac: null,
                    drawerCases: [],

                    // 公司商工資料 Modal
                    companyModalLoading: false,
                    companyInfo: null
                };
            },
            computed: {
                isInvMode() {
                    return this.currentMode.startsWith('INV');
                },
                canShowBatchBar() {
                    return this.isInvMode && (this.currentMode === 'INV2' || this.currentMode === 'INV3');
                }
            },
            mounted() {
                // 檢查網址列參數（如 ?INV_State=INV2）
                const urlParams = new URLSearchParams(window.location.search);
                const pState = urlParams.get('INV_State') || urlParams.get('mode');
                if (pState) {
                    const validModes = ['INV1', 'INV2', 'INV3', 'INVSM1', 'MAC1', 'MAC2', 'MAC3'];
                    const upState = pState.toUpperCase();
                    if (validModes.indexOf(upState) !== -1) {
                        this.currentMode = upState;
                    }
                }

                this.initData();
            },
            methods: {
                // 初始化行政區與使用者預設
                initData() {
                    this.loading = true;
                    axios.get('managerList.aspx?action=get_init_data')
                        .then(resp => {
                            if (resp.data.Success) {
                                this.currentUser = resp.data.CurrentUser || '系統管理員';
                                this.townList = resp.data.TownList || [];
                                this.selectedTowns = resp.data.SelectedTowns || [];
                                this.fetchList();
                            } else {
                                alert(resp.data.Message || '初始化失敗');
                            }
                        })
                        .catch(err => {
                            console.error(err);
                            alert('連線失敗，請稍後再試');
                        })
                        .finally(() => {
                            this.loading = false;
                        });
                },

                // 切換審查模式分頁
                switchMode(mode) {
                    if (this.currentMode === mode) return;
                    this.currentMode = mode;
                    this.batchSelectedFacIds = [];
                    this.fetchList();
                },

                // 取得場所主清單
                fetchList() {
                    this.loading = true;
                    this.batchSelectedFacIds = [];

                    const params = new URLSearchParams();
                    params.append('action', 'get_list');
                    params.append('invState', this.currentMode);
                    params.append('facName', this.filter.facName);
                    params.append('cno', this.filter.cno);
                    params.append('scid', this.filter.scid);
                    params.append('townCodes', this.selectedTowns.join(','));

                    axios.post('managerList.aspx', params)
                        .then(resp => {
                            if (resp.data.Success) {
                                this.items = resp.data.Items || [];
                                this.countColName = resp.data.CountColName || '待審件數';
                                if (resp.data.Stats) {
                                    this.stats = resp.data.Stats;
                                }
                            } else {
                                alert(resp.data.Message || '資料取得失敗');
                            }
                        })
                        .catch(err => {
                            console.error(err);
                            alert('網路連線逾時，請重試');
                        })
                        .finally(() => {
                            this.loading = false;
                        });
                },

                // 行政區勾選相關
                isTownSelected(code) {
                    return this.selectedTowns.indexOf(code) !== -1;
                },
                toggleTown(code) {
                    const idx = this.selectedTowns.indexOf(code);
                    if (idx === -1) {
                        this.selectedTowns.push(code);
                    } else {
                        this.selectedTowns.splice(idx, 1);
                    }
                },
                selectAllTowns() {
                    this.selectedTowns = this.townList.map(t => t.Code);
                },
                clearAllTowns() {
                    this.selectedTowns = [];
                },

                // 篩選折疊
                toggleFilterCollapse() {
                    this.isFilterCollapsed = !this.isFilterCollapsed;
                },
                resetFilter() {
                    this.filter.facName = '';
                    this.filter.cno = '';
                    this.filter.scid = '';
                    this.selectAllTowns();
                    this.fetchList();
                },

                // 行動版樣式輔助
                getMobileLossBoxStyle(lossPoint) {
                    if (lossPoint === 0) return { background: '#ecfdf5', border: '1px solid #a7f3d0' };
                    if (lossPoint < 10) return { background: '#fffbeb', border: '1px solid #fde68a' };
                    return { background: '#fef2f2', border: '1px solid #fecaca' };
                },

                // 點擊「進行審查」
                handleRunCheck(item) {
                    if (item.Case_Count === 1) {
                        // 單筆直接查出並跳轉
                        const params = new URLSearchParams();
                        params.append('action', 'get_single_check_url');
                        params.append('facId', item.FAC_ID);
                        params.append('invState', this.currentMode);

                        axios.post('managerList.aspx', params)
                            .then(resp => {
                                if (resp.data.Success && resp.data.CheckUrl) {
                                    window.location.href = resp.data.CheckUrl;
                                } else {
                                    this.openCaseDrawer(item);
                                }
                            })
                            .catch(() => {
                                this.openCaseDrawer(item);
                            });
                    } else {
                        // 多筆案件展開抽屜明細
                        this.openCaseDrawer(item);
                    }
                },

                // 開啟歷次案件抽屜
                openCaseDrawer(item) {
                    this.selectedFac = item;
                    this.isDrawerOpen = true;
                    this.drawerLoading = true;
                    this.drawerCases = [];

                    const params = new URLSearchParams();
                    params.append('action', 'get_cases');
                    params.append('facId', item.FAC_ID);
                    params.append('invState', this.currentMode);

                    axios.post('managerList.aspx', params)
                        .then(resp => {
                            if (resp.data.Success) {
                                this.drawerCases = resp.data.Cases || [];
                            } else {
                                alert(resp.data.Message || '載入案件失敗');
                            }
                        })
                        .catch(err => {
                            console.error(err);
                            alert('載入歷次案件失敗');
                        })
                        .finally(() => {
                            this.drawerLoading = false;
                        });
                },
                closeCaseDrawer() {
                    this.isDrawerOpen = false;
                },
                getCheckBtnText() {
                    if (this.currentMode === 'INV1' || this.currentMode === 'MAC1') return '初審';
                    if (this.currentMode === 'INV2' || this.currentMode === 'MAC2') return '複審';
                    if (this.currentMode === 'INV3' || this.currentMode === 'MAC3') return '三審';
                    return '審查';
                },

                // 批次通過功能
                selectAllBatchable() {
                    const ids = [];
                    this.items.forEach(it => {
                        if (it.CanBatchSelect) {
                            ids.push(it.FAC_ID);
                        }
                    });
                    this.batchSelectedFacIds = ids;
                },
                clearBatchSelection() {
                    this.batchSelectedFacIds = [];
                },
                executeBatchPass() {
                    if (this.batchSelectedFacIds.length === 0) return;
                    const count = this.batchSelectedFacIds.length;
                    if (!confirm('是否確定對已選取的 ' + count + ' 筆合格場所執行批次審核通過？')) {
                        return;
                    }

                    this.batchProcessing = true;
                    const params = new URLSearchParams();
                    params.append('action', 'batch_pass');
                    params.append('invState', this.currentMode);
                    params.append('facIds', this.batchSelectedFacIds.join(','));

                    axios.post('managerList.aspx', params)
                        .then(resp => {
                            if (resp.data.Success) {
                                alert(resp.data.Message || '批次審核執行成功！');
                                this.fetchList();
                            } else {
                                alert(resp.data.Message || '批次審核失敗');
                            }
                        })
                        .catch(err => {
                            console.error(err);
                            alert('批次審核請求發生異常');
                        })
                        .finally(() => {
                            this.batchProcessing = false;
                        });
                },

                // 開啟商工登記 Modal
                openCompanyModal(scid) {
                    if (!scid) return;
                    this.companyInfo = null;
                    this.companyModalLoading = true;
                    $('#companyModal').modal('show');

                    const params = new URLSearchParams();
                    params.append('action', 'get_company_info');
                    params.append('scid', scid);

                    axios.post('managerList.aspx', params)
                        .then(resp => {
                            if (resp.data.Success) {
                                this.companyInfo = resp.data;
                            } else {
                                this.companyInfo = null;
                            }
                        })
                        .catch(() => {
                            this.companyInfo = null;
                        })
                        .finally(() => {
                            this.companyModalLoading = false;
                        });
                }
            }
        }).mount('#managerApp');
    </script>
</body>
</html>
