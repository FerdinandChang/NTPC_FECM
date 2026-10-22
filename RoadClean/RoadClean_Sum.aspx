﻿<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="RoadClean_Sum.aspx.cs" Inherits="NTPC_FEC.RoadClean.RoadClean_Sum" %>

<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定溢散源管理平台 - 道路潔淨統計</title>

    <!-- 專屬 Favicon -->
    <link rel="shortcut icon" href="../favicon.ico" type="image/x-icon" />

    <!-- Bootstrap 4 & FontAwesome 本地化樣式 -->
    <link rel="stylesheet" href="../Content/bootstrap.min.css" />
    <link rel="stylesheet" href="../Content/fontawesome/css/all.min.css" />

    <style>
        :root {
            --brand-primary: #0099e5;
            --brand-navy: #0f172a;
            --brand-blue: #0284c7;
            --brand-dark-blue: #0b1f7d;
            --bg-canvas: #f8fafc;
            --surface: #ffffff;
            --border-color: #e2e8f0;
            --text-main: #0f172a;
            --text-muted: #64748b;
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

        /* 頂部品牌導覽列 (對齊 Clean_List.aspx) */
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
            font-size: 1.15rem;
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

        /* 模式切換頁籤 (對齊 Clean_List.aspx) */
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

        /* 現代卡片 */
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
            flex-wrap: wrap;
            gap: 12px;
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

        /* 頂部統計指標卡片 */
        .stat-card {
            background: #ffffff;
            border-radius: 10px;
            border: 1px solid var(--border-color);
            padding: 14px 18px;
            display: flex;
            align-items: center;
            gap: 14px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.03);
            transition: transform 0.15s ease, box-shadow 0.15s ease;
        }

        .stat-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(15, 23, 42, 0.06);
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

        /* 行政區多選展開面板 */
        .town-multi-panel {
            background: #f8fafc;
            border: 1px solid var(--border-color);
            border-radius: 8px;
            padding: 12px;
            margin-top: 8px;
        }

        .town-select-chip {
            display: inline-flex;
            align-items: center;
            padding: 4px 10px;
            margin: 3px;
            border-radius: 6px;
            font-size: 13px;
            font-weight: 600;
            background: #ffffff;
            border: 1px solid #cbd5e1;
            color: #475569;
            cursor: pointer;
            transition: all 0.15s ease;
            user-select: none;
        }

        .town-select-chip:hover {
            border-color: var(--brand-blue);
            color: var(--brand-blue);
        }

        .town-select-chip.selected {
            background: var(--brand-blue);
            border-color: var(--brand-blue);
            color: #ffffff;
        }

        /* 成果檢視切換器 (Segmented Pill Switcher) */
        .view-switcher-bar {
            background: #f8fafc;
            border-bottom: 1px solid var(--border-color);
            padding: 10px 20px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-wrap: wrap;
            gap: 12px;
        }

        .segmented-pills {
            display: inline-flex;
            background: #e2e8f0;
            padding: 3px;
            border-radius: 8px;
            gap: 3px;
            flex-wrap: wrap;
        }

        .segmented-pill-btn {
            border: none;
            background: transparent;
            padding: 6px 14px;
            border-radius: 6px;
            font-size: 13px;
            font-weight: 700;
            color: #475569;
            cursor: pointer;
            transition: all 0.15s ease;
            display: inline-flex;
            align-items: center;
            gap: 6px;
        }

        .segmented-pill-btn:hover {
            color: var(--brand-navy);
        }

        .segmented-pill-btn.active-clean {
            background: #0284c7;
            color: #ffffff;
            box-shadow: 0 1px 3px rgba(2, 132, 199, 0.3);
        }

        .segmented-pill-btn.active-flood {
            background: #0d9488;
            color: #ffffff;
            box-shadow: 0 1px 3px rgba(13, 148, 136, 0.3);
        }

        .segmented-pill-btn.active-both {
            background: #0f172a;
            color: #ffffff;
            box-shadow: 0 1px 3px rgba(15, 23, 42, 0.3);
        }

        /* 現代化穩固表格 (零錯位、抗視窗縮放跑版) */
        .table-scroll-container {
            position: relative;
            max-height: 700px;
            overflow: auto;
            width: 100%;
        }

        .table-modern {
            width: 100%;
            border-collapse: separate;
            border-spacing: 0;
            margin: 0;
        }

        .table-modern th {
            background: #f1f5f9;
            color: #334155;
            font-weight: 700;
            font-size: 13px;
            padding: 11px 12px;
            border-bottom: 2px solid #cbd5e1;
            border-right: 1px solid var(--border-color);
            white-space: nowrap;
            text-align: center;
            position: sticky;
            top: 0;
            z-index: 20;
        }

        .table-modern td {
            padding: 10px 12px;
            vertical-align: middle;
            border-bottom: 1px solid var(--border-color);
            border-right: 1px solid var(--border-color);
            color: var(--text-main);
            font-size: 13.5px;
            background: #ffffff;
            text-align: center;
            white-space: nowrap;
        }

        .table-modern tbody tr:hover td {
            background: #f8fafc;
        }

        /* 單一複合左欄固定 (left: 0 永遠不會因為視窗縮放產生欄間白縫或重疊) */
        .sticky-road-col {
            position: sticky !important;
            left: 0 !important;
            z-index: 15 !important;
            background: #ffffff;
            text-align: left !important;
            min-width: 240px;
            max-width: 280px;
            box-shadow: inset -2px 0 0 #cbd5e1;
        }

        .table-modern thead th.sticky-road-col {
            z-index: 30 !important;
            background: #e2e8f0 !important;
        }

        .table-modern tbody tr:hover td.sticky-road-col {
            background: #f1f5f9 !important;
        }

        /* 行政區分組折疊標題列 */
        .town-group-row td {
            background: #f1f5f9 !important;
            font-weight: 700;
            text-align: left !important;
            padding: 9px 16px !important;
            cursor: pointer;
            color: var(--brand-navy);
            border-bottom: 1px solid #cbd5e1;
            user-select: none;
        }

        .town-group-row:hover td {
            background: #e2e8f0 !important;
        }

        /* 表頭色彩主題 */
        .th-month-clean {
            background: #0284c7 !important;
            color: #ffffff !important;
            border-bottom-color: #0369a1 !important;
        }

        .th-month-flood {
            background: #0d9488 !important;
            color: #ffffff !important;
            border-bottom-color: #0f766e !important;
        }

        .th-month-both {
            background: #1e293b !important;
            color: #ffffff !important;
            border-bottom-color: #0f172a !important;
        }

        .th-bc-col {
            background: #fff1f2 !important;
            color: #be123c !important;
            border-bottom-color: #fda4af !important;
        }

        /* 評分晶片 Badge */
        .score-badge {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 4px;
            padding: 3px 9px;
            border-radius: 6px;
            font-weight: 700;
            font-size: 12.5px;
            white-space: nowrap !important;
            flex-shrink: 0;
            cursor: pointer;
            transition: transform 0.15s ease, box-shadow 0.15s ease;
        }

        .score-badge:hover {
            transform: translateY(-1px);
            box-shadow: 0 2px 5px rgba(0, 0, 0, 0.12);
        }

        .score-a {
            background: #ecfdf5;
            color: #047857;
            border: 1px solid #10b981;
        }

        .score-b {
            background: #fffbeb;
            color: #b45309;
            border: 1px solid #f59e0b;
        }

        .score-c {
            background: #fef2f2;
            color: #b91c1c;
            border: 1px solid #ef4444;
        }

        .score-none {
            background: #f1f5f9;
            color: #64748b;
            border: 1px solid #cbd5e1;
            cursor: default;
        }

        /* 同格雙顯 (潔淨+側溝) 堆疊容器 */
        .dual-score-stack {
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 4px;
        }

        .dual-tag-prefix {
            font-size: 10px;
            font-weight: 800;
            padding: 1px 4px;
            border-radius: 3px;
            background: rgba(0, 0, 0, 0.07);
        }

        /* 行政區與規格微晶片 */
        .town-chip {
            background: #e0f2fe;
            color: #0369a1;
            padding: 2px 7px;
            border-radius: 5px;
            font-size: 12px;
            font-weight: 700;
            display: inline-block;
        }

        .rdlv-chip {
            background: #f1f5f9;
            color: #475569;
            border: 1px solid #cbd5e1;
            padding: 1px 6px;
            border-radius: 4px;
            font-size: 11px;
            font-weight: 600;
        }

        .dis-chip {
            color: #0284c7;
            font-weight: 700;
            font-size: 12px;
        }

        /* 圖表容器 */
        .chart-box {
            width: 100%;
            height: 360px;
        }

        .photo-thumbnail {
            width: 80px;
            height: 60px;
            object-fit: cover;
            border-radius: 6px;
            border: 1px solid #cbd5e1;
            cursor: pointer;
            transition: transform 0.15s ease;
        }

        .photo-thumbnail:hover {
            transform: scale(1.06);
        }
    </style>
</head>
<body>
    <div id="sumApp" v-cloak>
        <!-- 頂部品牌導覽列 (對齊 Clean_List.aspx) -->
        <header class="top-navbar">
            <a href="RoadClean_Sum.aspx" class="navbar-brand-title">
                <i class="fas fa-chart-pie"></i>
                <span>新北市固定溢散源 - 道路潔淨統計</span>
            </a>
            <div class="d-flex align-items-center gap-2">
                <a href="Clean_List.aspx" class="btn btn-warning font-weight-bold text-dark px-3 shadow-sm mr-2" style="border-radius: 8px;">
                    <i class="fas fa-list-ul"></i>
                    <span class="d-none d-sm-inline ml-1">巡檢列表</span>
                </a>
                <a href="../MainPage.aspx?sub=menu4" class="btn btn-outline-light font-weight-bold px-3" style="border-radius: 8px;">
                    <i class="fas fa-chevron-left"></i>
                    <span class="d-none d-sm-inline ml-1">回選單</span>
                </a>
            </div>
        </header>

        <!-- 業務模式分頁切換列 (對齊 Clean_List.aspx) -->
        <nav class="nav-mode-bar">
            <div class="nav-mode-item" :class="{ 'active': currentTab === 'matrix' }" v-on:click="switchTab('matrix')">
                <i class="fas fa-table"></i>
                <span>道路巡檢執行成果總表</span>
                <span class="tab-badge badge badge-primary">{{ filteredRoadList.length }}</span>
            </div>
            <div class="nav-mode-item" :class="{ 'active': currentTab === 'count' }" v-on:click="switchTab('count')">
                <i class="fas fa-chart-bar"></i>
                <span>道路數分析與圖表</span>
                <span class="tab-badge badge badge-success">{{ (sumResult.CountStats || []).length }}月</span>
            </div>
            <div class="nav-mode-item" :class="{ 'active': currentTab === 'length' }" v-on:click="switchTab('length')">
                <i class="fas fa-route"></i>
                <span>道路長度分析與圖表</span>
                <span class="tab-badge badge badge-info">{{ sumResult.TotalDistance || 0 }}km</span>
            </div>
        </nav>

        <main class="container-fluid py-4 px-lg-4">
            <!-- 頂部統計指標卡片 -->
            <div class="row mb-3">
                <div class="col-6 col-lg-3 mb-2 mb-lg-0">
                    <div class="stat-card" v-on:click="switchTab('matrix')" style="cursor: pointer;">
                        <div class="stat-icon bg-primary text-white">
                            <i class="fas fa-road"></i>
                        </div>
                        <div>
                            <div class="stat-val text-primary">{{ sumResult.TotalRoads || 0 }}</div>
                            <div class="stat-label">納管巡檢道路數 (條)</div>
                        </div>
                    </div>
                </div>
                <div class="col-6 col-lg-3 mb-2 mb-lg-0">
                    <div class="stat-card" v-on:click="switchTab('length')" style="cursor: pointer;">
                        <div class="stat-icon bg-info text-white">
                            <i class="fas fa-route"></i>
                        </div>
                        <div>
                            <div class="stat-val text-info">{{ sumResult.TotalDistance || 0 }} <span style="font-size: 13px;">km</span></div>
                            <div class="stat-label">納管道路總長度</div>
                        </div>
                    </div>
                </div>
                <div class="col-6 col-lg-3 mb-2 mb-lg-0">
                    <div class="stat-card" v-on:click="switchTab('count')" style="cursor: pointer;">
                        <div class="stat-icon bg-warning text-dark">
                            <i class="fas fa-clipboard-check"></i>
                        </div>
                        <div>
                            <div class="stat-val text-warning">{{ sumResult.TotalChecks || 0 }}</div>
                            <div class="stat-label">期間累計巡檢次數</div>
                        </div>
                    </div>
                </div>
                <div class="col-6 col-lg-3 mb-2 mb-lg-0">
                    <div class="stat-card" v-on:click="switchTab('count')" style="cursor: pointer;">
                        <div class="stat-icon bg-success text-white">
                            <i class="fas fa-award"></i>
                        </div>
                        <div>
                            <div class="stat-val text-success">{{ sumResult.AvgPassRate || 0 }} <span style="font-size: 13px;">%</span></div>
                            <div class="stat-label">A 級潔淨達標率</div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- 查詢篩選卡片 -->
            <div class="card-modern">
                <div class="card-modern-header">
                    <h2 class="card-modern-title">
                        <i class="fas fa-filter text-primary"></i>
                        <span>統計條件篩選</span>
                    </h2>
                    <div class="d-flex align-items-center gap-2">
                        <button type="button" class="btn btn-sm btn-outline-secondary font-weight-bold" v-on:click="resetFilter">
                            <i class="fas fa-redo-alt mr-1"></i> 重設條件
                        </button>
                    </div>
                </div>
                <div class="card-modern-body">
                    <div class="row">
                        <!-- 行政區篩選 -->
                        <div class="col-12 col-md-3 mb-3">
                            <div class="d-flex align-items-center justify-content-between mb-1">
                                <label class="font-weight-bold text-muted small mb-0">
                                    <i class="fas fa-map-marker-alt text-danger mr-1"></i> 行政區
                                </label>
                                <a href="javascript:void(0);" class="small font-weight-bold text-primary" v-on:click="showMultiTown = !showMultiTown">
                                    <i class="fas" :class="showMultiTown ? 'fa-chevron-up' : 'fa-tasks'"></i>
                                    {{ showMultiTown ? '收合多選' : '多選行政區' }}
                                </a>
                            </div>
                            <select v-if="!showMultiTown" class="form-control" v-model="singleTown" v-on:change="onSingleTownChange" style="font-weight: 600;">
                                <option value="">全部行政區 ({{ townList.length }} 區)</option>
                                <option v-for="t in townList" :key="t.TownNo" :value="t.TownName">
                                    {{ t.TownName }} ({{ t.TownNo }})
                                </option>
                            </select>
                            <div v-else class="form-control d-flex align-items-center justify-content-between bg-light" style="font-weight: 600; cursor: pointer;" v-on:click="showMultiTown = !showMultiTown">
                                <span class="text-truncate">
                                    {{ selectedTowns.length === 0 ? '全部行政區' : '已選取 ' + selectedTowns.length + ' 個行政區' }}
                                </span>
                                <i class="fas fa-caret-up text-muted"></i>
                            </div>
                        </div>

                        <!-- 巡檢道路關鍵字 -->
                        <div class="col-12 col-md-3 mb-3">
                            <label class="font-weight-bold text-muted small mb-1">
                                <i class="fas fa-road text-info mr-1"></i> 巡檢道路名稱
                            </label>
                            <input type="text" class="form-control" v-model="filter.roadName" placeholder="例如：中正路、民權路..." v-on:keyup.enter="loadData" />
                        </div>

                        <!-- 統計起訖日期 -->
                        <div class="col-12 col-md-3 mb-3">
                            <label class="font-weight-bold text-muted small mb-1">
                                <i class="far fa-calendar-alt text-primary mr-1"></i> 統計起訖日期
                            </label>
                            <div class="d-flex align-items-center" style="width: 100%;">
                                <input type="date" class="form-control" style="flex: 1; min-width: 0;" v-model="filter.dateS" />
                                <span class="mx-2 text-muted font-weight-bold">~</span>
                                <input type="date" class="form-control" style="flex: 1; min-width: 0;" v-model="filter.dateE" />
                            </div>
                        </div>

                        <!-- 巡查長度區間 (km) -->
                        <div class="col-12 col-md-3 mb-3">
                            <label class="font-weight-bold text-muted small mb-1">
                                <i class="fas fa-ruler-horizontal text-success mr-1"></i> 巡查長度區間 (km)
                            </label>
                            <div class="d-flex align-items-center" style="width: 100%;">
                                <input type="number" step="0.1" class="form-control" style="flex: 1; min-width: 0;" v-model="filter.disS" placeholder="最小 km" v-on:keyup.enter="loadData" />
                                <span class="mx-2 text-muted font-weight-bold">~</span>
                                <input type="number" step="0.1" class="form-control" style="flex: 1; min-width: 0;" v-model="filter.disE" placeholder="最大 km" v-on:keyup.enter="loadData" />
                            </div>
                        </div>
                    </div>

                    <!-- 多選行政區展開晶片面板 -->
                    <div v-if="showMultiTown" class="town-multi-panel mb-3">
                        <div class="d-flex align-items-center justify-content-between mb-2 pb-1 border-bottom">
                            <span class="small font-weight-bold text-secondary">
                                點選行政區進行複選（已選 {{ selectedTowns.length }} 區）：
                            </span>
                            <div class="btn-group btn-group-sm">
                                <button type="button" class="btn btn-outline-primary py-0 px-2" v-on:click="selectAllTowns">全選</button>
                                <button type="button" class="btn btn-outline-secondary py-0 px-2" v-on:click="clearAllTowns">清除</button>
                            </div>
                        </div>
                        <div>
                            <span v-for="t in townList" :key="'chip_' + t.TownNo"
                                  class="town-select-chip"
                                  :class="{ 'selected': selectedTowns.indexOf(t.TownName) !== -1 }"
                                  v-on:click="toggleTown(t.TownName)">
                                {{ t.TownName }}
                            </span>
                        </div>
                    </div>

                    <!-- 快捷日期按鈕與搜尋列 -->
                    <div class="d-flex flex-wrap align-items-center justify-content-between pt-2 border-top">
                        <div class="btn-group btn-group-sm mb-2 mb-md-0" role="group">
                            <button type="button" class="btn btn-outline-secondary" v-on:click="setDateShortcut('ytd')">今年至今</button>
                            <button type="button" class="btn btn-outline-secondary" v-on:click="setDateShortcut('m3')">近 3 個月</button>
                            <button type="button" class="btn btn-outline-secondary" v-on:click="setDateShortcut('m6')">近 6 個月</button>
                            <button type="button" class="btn btn-outline-secondary" v-on:click="setDateShortcut('y1')">近 1 年</button>
                            <button type="button" class="btn btn-outline-secondary" v-on:click="setDateShortcut('lastyear')">去年全年</button>
                        </div>
                        <button type="button" class="btn btn-primary px-4 font-weight-bold shadow-sm" :disabled="loading" v-on:click="loadData">
                            <i class="fas fa-search mr-1"></i>
                            <span v-if="!loading">統計查詢</span>
                            <span v-else>統計中...</span>
                        </button>
                    </div>
                </div>
            </div>

            <!-- ============================================== -->
            <!-- TAB 1: 道路清淨巡檢執行成果總表 (Matrix)       -->
            <!-- ============================================== -->
            <div v-show="currentTab === 'matrix'">
                <div class="card-modern">
                    <div class="card-modern-header">
                        <h2 class="card-modern-title">
                            <i class="fas fa-table text-primary"></i>
                            <span>道路清淨巡檢執行成果表</span>
                            <span class="badge badge-pill badge-light border text-muted ml-1 font-weight-bold" style="font-size: 12px;">
                                顯示 {{ filteredRoadList.length }} / {{ (sumResult.RoadList || []).length }} 條道路
                            </span>
                        </h2>
                        <div class="d-flex align-items-center flex-wrap gap-2">
                            <button type="button" class="btn btn-sm btn-success font-weight-bold px-3 mr-2" v-on:click="exportData('exportroads')">
                                <i class="fas fa-file-excel mr-1"></i> 匯出成果總表 Excel
                            </button>
                            <button type="button" class="btn btn-sm btn-light border font-weight-bold" v-on:click="loadData" title="重新整理">
                                <i class="fas fa-sync-alt" :class="{ 'fa-spin': loading }"></i>
                            </button>
                        </div>
                    </div>

                    <!-- 成果維度切換與收合控制列 (避免雙表並排過寬與視窗縮放跑版) -->
                    <div class="view-switcher-bar">
                        <div class="d-flex align-items-center flex-wrap gap-2">
                            <span class="small font-weight-bold text-secondary mr-1">
                                <i class="fas fa-eye mr-1"></i>成果檢視項目：
                            </span>
                            <div class="segmented-pills">
                                <button type="button" class="segmented-pill-btn"
                                        :class="{ 'active-clean': matrixMode === 'clean' }"
                                        v-on:click="matrixMode = 'clean'">
                                    <i class="fas fa-broom"></i> 道路潔淨度成果
                                </button>
                                <button type="button" class="segmented-pill-btn"
                                        :class="{ 'active-flood': matrixMode === 'flood' }"
                                        v-on:click="matrixMode = 'flood'">
                                    <i class="fas fa-water"></i> 防汛期側溝成果
                                </button>
                                <button type="button" class="segmented-pill-btn"
                                        :class="{ 'active-both': matrixMode === 'both' }"
                                        v-on:click="matrixMode = 'both'">
                                    <i class="fas fa-layer-group"></i> 同欄對照 (潔淨+側溝)
                                </button>
                            </div>
                        </div>

                        <!-- 輔助過濾與行政區收合開關 -->
                        <div class="d-flex align-items-center flex-wrap" style="gap: 12px;">
                            <div class="custom-control custom-switch">
                                <input type="checkbox" class="custom-control-input" id="swOnlyBc" v-model="onlyShowBcRoads" />
                                <label class="custom-control-label small font-weight-bold text-danger" for="swOnlyBc" style="cursor: pointer;">
                                    僅顯示有 B/C 級道路
                                </label>
                            </div>
                            <div class="custom-control custom-switch">
                                <input type="checkbox" class="custom-control-input" id="swGroupByTown" v-model="groupByTown" />
                                <label class="custom-control-label small font-weight-bold text-secondary" for="swGroupByTown" style="cursor: pointer;">
                                    依行政區分組收合
                                </label>
                            </div>
                            <div v-if="groupByTown" class="btn-group btn-group-sm">
                                <button type="button" class="btn btn-outline-secondary py-0 px-2" v-on:click="expandAllTowns">全展開</button>
                                <button type="button" class="btn btn-outline-secondary py-0 px-2" v-on:click="collapseAllTowns">全收合</button>
                            </div>
                        </div>
                    </div>

                    <div class="p-0">
                        <!-- 載入中骨架 -->
                        <div v-if="loading" class="text-center py-5">
                            <div class="spinner-border text-primary" role="status">
                                <span class="sr-only">載入中...</span>
                            </div>
                            <div class="mt-2 text-muted font-weight-bold">正在彙整成果統計數據，請稍候...</div>
                        </div>

                        <!-- 查無資料 -->
                        <div v-else-if="filteredRoadList.length === 0" class="text-center py-5">
                            <div class="mb-3 text-muted" style="font-size: 3rem;">
                                <i class="far fa-folder-open"></i>
                            </div>
                            <h5 class="font-weight-bold text-secondary">查無符合條件的道路巡檢紀錄</h5>
                            <p class="text-muted small">請嘗試放寬行政區、關閉「僅顯示 B/C 級」或調整統計起訖日期。</p>
                        </div>

                        <!-- 穩固型單維度/同欄對照矩陣表格 (消除多欄固定錯位與雙倍橫向寬度) -->
                        <div v-else class="table-scroll-container">
                            <table class="table-modern">
                                <thead>
                                    <tr>
                                        <th class="sticky-road-col">
                                            <div class="d-flex align-items-center justify-content-between">
                                                <span>行政區 / 道路名稱</span>
                                                <span class="badge badge-light border text-muted">級別 · 長度</span>
                                            </div>
                                        </th>
                                        <th class="th-bc-col" style="width: 90px;">
                                            B級(含以下)<br/>累計次數
                                        </th>
                                        <th v-for="m in sumResult.MonthCols" :key="'mh_' + m.Key"
                                            :class="matrixMode === 'clean' ? 'th-month-clean' : (matrixMode === 'flood' ? 'th-month-flood' : 'th-month-both')">
                                            <div>{{ m.Label }}</div>
                                            <div style="font-size: 11px; font-weight: 500; opacity: 0.9;">
                                                {{ matrixMode === 'clean' ? '道路潔淨' : (matrixMode === 'flood' ? '防汛側溝' : '潔淨 / 側溝') }}
                                            </div>
                                        </th>
                                    </tr>
                                </thead>

                                <!-- 模式 A：依行政區分組收合 -->
                                <tbody v-if="groupByTown">
                                    <template v-for="grp in groupedRoadList" :key="'grp_' + grp.town">
                                        <tr class="town-group-row" v-on:click="toggleTownCollapse(grp.town)">
                                            <td :colspan="2 + (sumResult.MonthCols || []).length">
                                                <div class="d-flex align-items-center justify-content-between">
                                                    <div>
                                                        <i class="fas mr-2 text-primary" :class="collapsedTowns[grp.town] ? 'fa-plus-square' : 'fa-minus-square'"></i>
                                                        <span class="town-chip mr-2">{{ grp.town }}</span>
                                                        <span class="text-secondary small font-weight-bold">共 {{ grp.roads.length }} 條道路</span>
                                                        <span v-if="grp.bcTotal > 0" class="badge badge-danger ml-2">B/C級累計 {{ grp.bcTotal }} 次</span>
                                                    </div>
                                                    <span class="small text-muted">
                                                        {{ collapsedTowns[grp.town] ? '點擊展開' : '點擊收合' }}
                                                    </span>
                                                </div>
                                            </td>
                                        </tr>
                                        <tr v-for="r in grp.roads" :key="r.RDID" v-show="!collapsedTowns[grp.town]">
                                            <td class="sticky-road-col">
                                                <div class="d-flex align-items-center justify-content-between">
                                                    <div>
                                                        <span class="town-chip mr-1">{{ r.Town }}</span>
                                                        <span class="font-weight-bold text-dark">{{ r.RoadName }}</span>
                                                    </div>
                                                    <div class="ml-2">
                                                        <span class="rdlv-chip mr-1">{{ r.RdLv }}</span>
                                                        <span class="dis-chip">{{ r.Dis.toFixed(1) }}k</span>
                                                    </div>
                                                </div>
                                            </td>
                                            <td>
                                                <span class="score-badge" :class="r.BcCount > 0 ? 'score-c' : 'score-none'">
                                                    {{ r.BcCount }} 次
                                                </span>
                                            </td>
                                            <td v-for="m in sumResult.MonthCols" :key="'cell_' + r.RDID + '_' + m.Key">
                                                <!-- 1. 道路潔淨度檢視 -->
                                                <template v-if="matrixMode === 'clean'">
                                                    <span v-if="r.RoadScores[m.Key] && r.RoadScores[m.Key].HasData && r.RoadScores[m.Key].Grade !== '-'"
                                                          class="score-badge"
                                                          :class="'score-' + r.RoadScores[m.Key].Grade.toLowerCase()"
                                                          v-on:click="openChkDetail(r.RoadScores[m.Key].ChkID)"
                                                          :title="'點擊檢視查核單號：' + r.RoadScores[m.Key].ChkID">
                                                        {{ r.RoadScores[m.Key].ShowTxt }}
                                                    </span>
                                                    <span v-else class="text-muted">-</span>
                                                </template>

                                                <!-- 2. 防汛期側溝檢視 -->
                                                <template v-else-if="matrixMode === 'flood'">
                                                    <span v-if="r.FloodScores[m.Key] && r.FloodScores[m.Key].HasData && r.FloodScores[m.Key].Grade !== '-'"
                                                          class="score-badge"
                                                          :class="'score-' + r.FloodScores[m.Key].Grade.toLowerCase()"
                                                          v-on:click="openChkDetail(r.FloodScores[m.Key].ChkID)"
                                                          :title="'點擊檢視查核單號：' + r.FloodScores[m.Key].ChkID">
                                                        {{ r.FloodScores[m.Key].ShowTxt }}
                                                    </span>
                                                    <span v-else class="text-muted">-</span>
                                                </template>

                                                <!-- 3. 同欄上下對照檢視 -->
                                                <template v-else>
                                                    <div class="dual-score-stack">
                                                        <span v-if="r.RoadScores[m.Key] && r.RoadScores[m.Key].HasData && r.RoadScores[m.Key].Grade !== '-'"
                                                              class="score-badge"
                                                              :class="'score-' + r.RoadScores[m.Key].Grade.toLowerCase()"
                                                              v-on:click="openChkDetail(r.RoadScores[m.Key].ChkID)">
                                                            <span class="dual-tag-prefix">潔</span>{{ r.RoadScores[m.Key].ShowTxt }}
                                                        </span>
                                                        <span v-if="r.FloodScores[m.Key] && r.FloodScores[m.Key].HasData && r.FloodScores[m.Key].Grade !== '-'"
                                                              class="score-badge"
                                                              :class="'score-' + r.FloodScores[m.Key].Grade.toLowerCase()"
                                                              v-on:click="openChkDetail(r.FloodScores[m.Key].ChkID)">
                                                            <span class="dual-tag-prefix">溝</span>{{ r.FloodScores[m.Key].ShowTxt }}
                                                        </span>
                                                        <span v-if="(!r.RoadScores[m.Key] || r.RoadScores[m.Key].Grade === '-') && (!r.FloodScores[m.Key] || r.FloodScores[m.Key].Grade === '-')"
                                                              class="text-muted">-</span>
                                                    </div>
                                                </template>
                                            </td>
                                        </tr>
                                    </template>
                                </tbody>

                                <!-- 模式 B：平鋪列表 -->
                                <tbody v-else>
                                    <tr v-for="r in filteredRoadList" :key="r.RDID">
                                        <td class="sticky-road-col">
                                            <div class="d-flex align-items-center justify-content-between">
                                                <div>
                                                    <span class="town-chip mr-1">{{ r.Town }}</span>
                                                    <span class="font-weight-bold text-dark">{{ r.RoadName }}</span>
                                                </div>
                                                <div class="ml-2">
                                                    <span class="rdlv-chip mr-1">{{ r.RdLv }}</span>
                                                    <span class="dis-chip">{{ r.Dis.toFixed(1) }}k</span>
                                                </div>
                                            </div>
                                        </td>
                                        <td>
                                            <span class="score-badge" :class="r.BcCount > 0 ? 'score-c' : 'score-none'">
                                                {{ r.BcCount }} 次
                                            </span>
                                        </td>
                                        <td v-for="m in sumResult.MonthCols" :key="'cell_' + r.RDID + '_' + m.Key">
                                            <!-- 1. 道路潔淨度檢視 -->
                                            <template v-if="matrixMode === 'clean'">
                                                <span v-if="r.RoadScores[m.Key] && r.RoadScores[m.Key].HasData && r.RoadScores[m.Key].Grade !== '-'"
                                                      class="score-badge"
                                                      :class="'score-' + r.RoadScores[m.Key].Grade.toLowerCase()"
                                                      v-on:click="openChkDetail(r.RoadScores[m.Key].ChkID)"
                                                      :title="'點擊檢視查核單號：' + r.RoadScores[m.Key].ChkID">
                                                    {{ r.RoadScores[m.Key].ShowTxt }}
                                                </span>
                                                <span v-else class="text-muted">-</span>
                                            </template>

                                            <!-- 2. 防汛期側溝檢視 -->
                                            <template v-else-if="matrixMode === 'flood'">
                                                <span v-if="r.FloodScores[m.Key] && r.FloodScores[m.Key].HasData && r.FloodScores[m.Key].Grade !== '-'"
                                                      class="score-badge"
                                                      :class="'score-' + r.FloodScores[m.Key].Grade.toLowerCase()"
                                                      v-on:click="openChkDetail(r.FloodScores[m.Key].ChkID)"
                                                      :title="'點擊檢視查核單號：' + r.FloodScores[m.Key].ChkID">
                                                    {{ r.FloodScores[m.Key].ShowTxt }}
                                                </span>
                                                <span v-else class="text-muted">-</span>
                                            </template>

                                            <!-- 3. 同欄上下對照檢視 -->
                                            <template v-else>
                                                <div class="dual-score-stack">
                                                    <span v-if="r.RoadScores[m.Key] && r.RoadScores[m.Key].HasData && r.RoadScores[m.Key].Grade !== '-'"
                                                          class="score-badge"
                                                          :class="'score-' + r.RoadScores[m.Key].Grade.toLowerCase()"
                                                          v-on:click="openChkDetail(r.RoadScores[m.Key].ChkID)">
                                                        <span class="dual-tag-prefix">潔</span>{{ r.RoadScores[m.Key].ShowTxt }}
                                                    </span>
                                                    <span v-if="r.FloodScores[m.Key] && r.FloodScores[m.Key].HasData && r.FloodScores[m.Key].Grade !== '-'"
                                                          class="score-badge"
                                                          :class="'score-' + r.FloodScores[m.Key].Grade.toLowerCase()"
                                                          v-on:click="openChkDetail(r.FloodScores[m.Key].ChkID)">
                                                        <span class="dual-tag-prefix">溝</span>{{ r.FloodScores[m.Key].ShowTxt }}
                                                    </span>
                                                    <span v-if="(!r.RoadScores[m.Key] || r.RoadScores[m.Key].Grade === '-') && (!r.FloodScores[m.Key] || r.FloodScores[m.Key].Grade === '-')"
                                                          class="text-muted">-</span>
                                                </div>
                                            </template>
                                        </td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>

            <!-- ============================================== -->
            <!-- TAB 2: 道路數分析統計與圖表                    -->
            <!-- ============================================== -->
            <div v-show="currentTab === 'count'">
                <div class="row">
                    <div class="col-lg-8 mb-3">
                        <div class="card-modern h-100 mb-0">
                            <div class="card-modern-header">
                                <h2 class="card-modern-title">
                                    <i class="fas fa-chart-bar text-primary"></i>
                                    <span>各月份潔淨等級道路數趨勢 (條)</span>
                                </h2>
                            </div>
                            <div class="card-modern-body">
                                <div id="chartRoadCount" class="chart-box"></div>
                            </div>
                        </div>
                    </div>
                    <div class="col-lg-4 mb-3">
                        <div class="card-modern h-100 mb-0">
                            <div class="card-modern-header">
                                <h2 class="card-modern-title">
                                    <i class="fas fa-chart-pie text-success"></i>
                                    <span>全期各級道路數比例</span>
                                </h2>
                            </div>
                            <div class="card-modern-body">
                                <div id="chartRoadCountPie" class="chart-box"></div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="card-modern">
                    <div class="card-modern-header">
                        <h2 class="card-modern-title">
                            <i class="fas fa-list-ol text-primary"></i>
                            <span>道路潔淨度 道路數分析統計表</span>
                        </h2>
                        <div class="d-flex align-items-center gap-2">
                            <button type="button" class="btn btn-sm btn-success font-weight-bold px-3" v-on:click="exportData('exportcounts')">
                                <i class="fas fa-file-excel mr-1"></i> 匯出 Excel
                            </button>
                        </div>
                    </div>
                    <div class="p-0">
                        <div class="table-responsive">
                            <table class="table-modern">
                                <thead>
                                    <tr>
                                        <th>年份</th>
                                        <th>月份</th>
                                        <th class="text-success">A級道路數 (條)</th>
                                        <th class="text-warning">B級道路數 (條)</th>
                                        <th class="text-danger">C級道路數 (條)</th>
                                        <th>合計條數</th>
                                        <th class="text-success">A級佔比 (%)</th>
                                        <th class="text-warning">B級佔比 (%)</th>
                                        <th class="text-danger">C級佔比 (%)</th>
                                        <th>合計 (%)</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr v-for="row in sumResult.CountStats" :key="'cs_' + row.Year + '_' + row.Month">
                                        <td>{{ row.Year }}</td>
                                        <td class="font-weight-bold">{{ row.Month }}月</td>
                                        <td><span class="score-badge score-a">{{ row.CountA }}</span></td>
                                        <td><span class="score-badge score-b">{{ row.CountB }}</span></td>
                                        <td><span class="score-badge score-c">{{ row.CountC }}</span></td>
                                        <td class="font-weight-bold">{{ row.CountTotal }}</td>
                                        <td class="font-weight-bold text-success">{{ row.PercentA.toFixed(1) }}%</td>
                                        <td class="font-weight-bold text-warning">{{ row.PercentB.toFixed(1) }}%</td>
                                        <td class="font-weight-bold text-danger">{{ row.PercentC.toFixed(1) }}%</td>
                                        <td class="font-weight-bold">100.0%</td>
                                    </tr>
                                    <tr v-if="(sumResult.CountStats || []).length > 0" style="background: #f8fafc; font-weight: 800;">
                                        <td colspan="2" class="font-weight-bold text-primary">全期累計 / 平均</td>
                                        <td class="font-weight-bold text-success">{{ countStatSummary.sumA }}</td>
                                        <td class="font-weight-bold text-warning">{{ countStatSummary.sumB }}</td>
                                        <td class="font-weight-bold text-danger">{{ countStatSummary.sumC }}</td>
                                        <td class="font-weight-bold">{{ countStatSummary.sumTot }}</td>
                                        <td class="font-weight-bold text-success">{{ countStatSummary.pctA.toFixed(1) }}%</td>
                                        <td class="font-weight-bold text-warning">{{ countStatSummary.pctB.toFixed(1) }}%</td>
                                        <td class="font-weight-bold text-danger">{{ countStatSummary.pctC.toFixed(1) }}%</td>
                                        <td class="font-weight-bold">100.0%</td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>

                <!-- 各行政區道路數分佈 -->
                <div class="card-modern">
                    <div class="card-modern-header">
                        <h2 class="card-modern-title">
                            <i class="fas fa-city text-primary"></i>
                            <span>各行政區道路數分佈統計</span>
                        </h2>
                    </div>
                    <div class="p-0">
                        <div class="table-responsive">
                            <table class="table-modern">
                                <thead>
                                    <tr>
                                        <th>行政區</th>
                                        <th>納管道路數 (條)</th>
                                        <th>A級次數</th>
                                        <th>B級次數</th>
                                        <th>C級次數</th>
                                        <th>A級達成率 (%)</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr v-for="t in sumResult.TownStats" :key="'ts_' + t.Town">
                                        <td><span class="town-chip">{{ t.Town }}</span></td>
                                        <td class="font-weight-bold">{{ t.RoadCount }}</td>
                                        <td class="text-success font-weight-bold">{{ t.CountA }}</td>
                                        <td class="text-warning font-weight-bold">{{ t.CountB }}</td>
                                        <td class="text-danger font-weight-bold">{{ t.CountC }}</td>
                                        <td>
                                            <span class="score-badge" :class="(t.CountA + t.CountB + t.CountC) > 0 ? 'score-a' : 'score-none'">
                                                {{ (t.CountA + t.CountB + t.CountC) > 0 ? ((t.CountA / (t.CountA + t.CountB + t.CountC)) * 100).toFixed(1) + '%' : '-' }}
                                            </span>
                                        </td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>

            <!-- ============================================== -->
            <!-- TAB 3: 道路長度分析統計與圖表                  -->
            <!-- ============================================== -->
            <div v-show="currentTab === 'length'">
                <div class="row">
                    <div class="col-lg-8 mb-3">
                        <div class="card-modern h-100 mb-0">
                            <div class="card-modern-header">
                                <h2 class="card-modern-title">
                                    <i class="fas fa-chart-line text-primary"></i>
                                    <span>各月份潔淨等級道路長度趨勢 (公里 km)</span>
                                </h2>
                            </div>
                            <div class="card-modern-body">
                                <div id="chartRoadDis" class="chart-box"></div>
                            </div>
                        </div>
                    </div>
                    <div class="col-lg-4 mb-3">
                        <div class="card-modern h-100 mb-0">
                            <div class="card-modern-header">
                                <h2 class="card-modern-title">
                                    <i class="fas fa-chart-pie text-success"></i>
                                    <span>全期各級道路長度比例</span>
                                </h2>
                            </div>
                            <div class="card-modern-body">
                                <div id="chartRoadDisPie" class="chart-box"></div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="card-modern">
                    <div class="card-modern-header">
                        <h2 class="card-modern-title">
                            <i class="fas fa-ruler text-primary"></i>
                            <span>道路潔淨度 道路長度分析統計表</span>
                        </h2>
                        <div class="d-flex align-items-center gap-2">
                            <button type="button" class="btn btn-sm btn-success font-weight-bold px-3" v-on:click="exportData('exportlengths')">
                                <i class="fas fa-file-excel mr-1"></i> 匯出 Excel
                            </button>
                        </div>
                    </div>
                    <div class="p-0">
                        <div class="table-responsive">
                            <table class="table-modern">
                                <thead>
                                    <tr>
                                        <th>年份</th>
                                        <th>月份</th>
                                        <th class="text-success">A級長度 (km)</th>
                                        <th class="text-warning">B級長度 (km)</th>
                                        <th class="text-danger">C級長度 (km)</th>
                                        <th>合計長度 (km)</th>
                                        <th class="text-success">A級佔比 (%)</th>
                                        <th class="text-warning">B級佔比 (%)</th>
                                        <th class="text-danger">C級佔比 (%)</th>
                                        <th>合計 (%)</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr v-for="row in sumResult.DisStats" :key="'ds_' + row.Year + '_' + row.Month">
                                        <td>{{ row.Year }}</td>
                                        <td class="font-weight-bold">{{ row.Month }}月</td>
                                        <td><span class="score-badge score-a">{{ row.DisA.toFixed(1) }}</span></td>
                                        <td><span class="score-badge score-b">{{ row.DisB.toFixed(1) }}</span></td>
                                        <td><span class="score-badge score-c">{{ row.DisC.toFixed(1) }}</span></td>
                                        <td class="font-weight-bold">{{ row.DisTotal.toFixed(1) }}</td>
                                        <td class="font-weight-bold text-success">{{ row.PercentA.toFixed(1) }}%</td>
                                        <td class="font-weight-bold text-warning">{{ row.PercentB.toFixed(1) }}%</td>
                                        <td class="font-weight-bold text-danger">{{ row.PercentC.toFixed(1) }}%</td>
                                        <td class="font-weight-bold">100.0%</td>
                                    </tr>
                                    <tr v-if="(sumResult.DisStats || []).length > 0" style="background: #f8fafc; font-weight: 800;">
                                        <td colspan="2" class="font-weight-bold text-primary">全期累計 / 平均</td>
                                        <td class="font-weight-bold text-success">{{ disStatSummary.sumA.toFixed(1) }}</td>
                                        <td class="font-weight-bold text-warning">{{ disStatSummary.sumB.toFixed(1) }}</td>
                                        <td class="font-weight-bold text-danger">{{ disStatSummary.sumC.toFixed(1) }}</td>
                                        <td class="font-weight-bold">{{ disStatSummary.sumTot.toFixed(1) }}</td>
                                        <td class="font-weight-bold text-success">{{ disStatSummary.pctA.toFixed(1) }}%</td>
                                        <td class="font-weight-bold text-warning">{{ disStatSummary.pctB.toFixed(1) }}%</td>
                                        <td class="font-weight-bold text-danger">{{ disStatSummary.pctC.toFixed(1) }}%</td>
                                        <td class="font-weight-bold">100.0%</td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>

                <!-- 各行政區巡檢里程統計 -->
                <div class="card-modern">
                    <div class="card-modern-header">
                        <h2 class="card-modern-title">
                            <i class="fas fa-map-marked-alt text-primary"></i>
                            <span>各行政區巡檢里程分佈統計</span>
                        </h2>
                    </div>
                    <div class="p-0">
                        <div class="table-responsive">
                            <table class="table-modern">
                                <thead>
                                    <tr>
                                        <th>行政區</th>
                                        <th>道路總長度 (km)</th>
                                        <th>A級里程 (km)</th>
                                        <th>B級里程 (km)</th>
                                        <th>C級里程 (km)</th>
                                        <th>A級里程佔比 (%)</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr v-for="t in sumResult.TownStats" :key="'tdis_' + t.Town">
                                        <td><span class="town-chip">{{ t.Town }}</span></td>
                                        <td class="font-weight-bold">{{ t.TotalDis.toFixed(1) }}</td>
                                        <td class="text-success font-weight-bold">{{ t.DisA.toFixed(1) }}</td>
                                        <td class="text-warning font-weight-bold">{{ t.DisB.toFixed(1) }}</td>
                                        <td class="text-danger font-weight-bold">{{ t.DisC.toFixed(1) }}</td>
                                        <td>
                                            <span class="score-badge" :class="(t.DisA + t.DisB + t.DisC) > 0 ? 'score-a' : 'score-none'">
                                                {{ (t.DisA + t.DisB + t.DisC) > 0 ? ((t.DisA / (t.DisA + t.DisB + t.DisC)) * 100).toFixed(1) + '%' : '-' }}
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

        <!-- 巡查明細檢視彈窗 (Modal) -->
        <div class="modal fade" id="modalChkDetail" tabindex="-1" role="dialog" aria-hidden="true">
            <div class="modal-dialog modal-lg modal-dialog-scrollable" role="document">
                <div class="modal-content" v-if="chkDetail" style="border-radius: 12px; overflow: hidden;">
                    <div class="modal-header bg-primary text-white">
                        <h5 class="modal-title font-weight-bold" style="font-size: 16px;">
                            <i class="fas fa-info-circle mr-1"></i> 巡查明細檢視 - {{ chkDetail.ChkId }}
                        </h5>
                        <button type="button" class="close text-white" data-dismiss="modal" aria-label="Close">
                            <span aria-hidden="true">&times;</span>
                        </button>
                    </div>

                    <div class="modal-body p-3">
                        <div class="bg-light p-3 rounded mb-3 border">
                            <div class="row">
                                <div class="col-sm-6 mb-2"><strong>巡查單號：</strong>{{ chkDetail.ChkId }}</div>
                                <div class="col-sm-6 mb-2"><strong>巡檢日期：</strong>{{ chkDetail.ChkDate }}</div>
                                <div class="col-sm-6 mb-2"><strong>行政區：</strong><span class="town-chip">{{ chkDetail.Town }}</span></div>
                                <div class="col-sm-6 mb-2"><strong>巡檢道路：</strong>{{ chkDetail.RoadName }} ({{ chkDetail.RdLv }})</div>
                                <div class="col-sm-6 mb-2"><strong>道路長度：</strong>{{ chkDetail.Dis }} km</div>
                                <div class="col-sm-6 mb-2"><strong>巡查人員：</strong>{{ chkDetail.CreateUser }}</div>
                                <div class="col-sm-6 mb-2">
                                    <strong>道路潔淨評分：</strong>
                                    <span class="score-badge" :class="chkDetail.RoadScore >= 85 ? 'score-a' : (chkDetail.RoadScore >= 60 ? 'score-b' : 'score-c')">
                                        {{ chkDetail.RoadScore }} 分
                                    </span>
                                </div>
                                <div class="col-sm-6 mb-2">
                                    <strong>汛期側溝評分：</strong>
                                    <span class="score-badge" :class="chkDetail.FloodScore >= 85 ? 'score-a' : (chkDetail.FloodScore >= 60 ? 'score-b' : (chkDetail.FloodScore >= 0 ? 'score-c' : 'score-none'))">
                                        {{ chkDetail.FloodScore >= 0 ? chkDetail.FloodScore + ' 分' : '未評' }}
                                    </span>
                                </div>
                            </div>
                            <div v-if="chkDetail.Memo" class="mt-2 text-muted">
                                <strong>巡查備註：</strong>{{ chkDetail.Memo }}
                            </div>
                        </div>

                        <h6 class="font-weight-bold text-secondary mb-2">
                            <i class="fas fa-map-pin text-danger mr-1"></i> 檢核點扣分明細
                        </h6>
                        <div v-if="chkDetail.Points && chkDetail.Points.length > 0">
                            <div v-for="(p, pIdx) in chkDetail.Points" :key="p.PointId" class="card mb-2 border" style="border-radius: 8px;">
                                <div class="card-header py-2 px-3 bg-white d-flex align-items-center justify-content-between">
                                    <span class="font-weight-bold">
                                        第 {{ pIdx + 1 }} 點：{{ p.PointName || p.PointId }}
                                    </span>
                                    <div class="d-flex gap-2">
                                        <span class="badge badge-light border mr-1">行道樹: {{ p.STree === 'Y' ? '有' : '無' }}</span>
                                        <span class="badge badge-light border">側溝: {{ p.SDrain === 'Y' ? '有' : '無' }}</span>
                                    </div>
                                </div>
                                <div class="card-body p-3">
                                    <div class="row align-items-center">
                                        <div class="col-md-9">
                                            <div v-if="p.Scores && p.Scores.length > 0">
                                                <ul class="mb-0 pl-3">
                                                    <li v-for="s in p.Scores" :key="s.ChkCode" class="text-danger mb-1">
                                                        <strong>[{{ s.ChkCode }}] {{ s.Reason || '現場環境扣分' }}</strong>
                                                        <span class="badge badge-warning ml-2">實得分數: {{ s.Score }}</span>
                                                    </li>
                                                </ul>
                                            </div>
                                            <div v-else class="text-success font-weight-bold">
                                                <i class="fas fa-check-circle mr-1"></i> 本檢核點各項評分滿分無扣分
                                            </div>
                                        </div>
                                        <div class="col-md-3 text-right" v-if="p.PointImg">
                                            <a :href="'../' + p.PointImg" target="_blank">
                                                <img :src="'../' + p.PointImg" alt="現場照片" class="photo-thumbnail" />
                                            </a>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div v-else class="text-muted text-center py-3">
                            無檢核點位資料
                        </div>
                    </div>

                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary font-weight-bold px-4" data-dismiss="modal">關閉</button>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- 本地端 JavaScript 核心依賴 -->
    <script src="../Scripts/jquery.min.js"></script>
    <script src="../Scripts/bootstrap.bundle.min.js"></script>
    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>
    <script src="../Scripts/highcharts.js"></script>

    <script>
        const { createApp } = Vue;

        createApp({
            data() {
                return {
                    currentTab: 'matrix', // matrix, count, length
                    matrixMode: 'clean',  // clean (道路潔淨度), flood (防汛期側溝), both (同欄對照)
                    onlyShowBcRoads: false,
                    groupByTown: false,
                    collapsedTowns: {},

                    loading: false,
                    showMultiTown: false,
                    singleTown: '',

                    townList: [],
                    selectedTowns: [],

                    filter: {
                        roadName: '',
                        dateS: '',
                        dateE: '',
                        rdLv: '',
                        disS: '',
                        disE: ''
                    },

                    sumResult: {
                        MonthCols: [],
                        RoadList: [],
                        CountStats: [],
                        DisStats: [],
                        TownStats: [],
                        TotalRoads: 0,
                        TotalDistance: 0,
                        TotalChecks: 0,
                        AvgPassRate: 0
                    },

                    chkDetail: null
                };
            },
            computed: {
                filteredRoadList() {
                    const list = this.sumResult.RoadList || [];
                    if (!this.onlyShowBcRoads) return list;
                    return list.filter(r => r.BcCount > 0);
                },
                groupedRoadList() {
                    const map = {};
                    const groups = [];
                    this.filteredRoadList.forEach(r => {
                        const t = r.Town || '未分類';
                        if (!map[t]) {
                            map[t] = { town: t, roads: [], bcTotal: 0 };
                            groups.push(map[t]);
                        }
                        map[t].roads.push(r);
                        map[t].bcTotal += (r.BcCount || 0);
                    });
                    return groups;
                },
                countStatSummary() {
                    let a = 0, b = 0, c = 0, tot = 0;
                    (this.sumResult.CountStats || []).forEach(item => {
                        a += item.CountA;
                        b += item.CountB;
                        c += item.CountC;
                        tot += item.CountTotal;
                    });
                    return {
                        sumA: a, sumB: b, sumC: c, sumTot: tot,
                        pctA: tot > 0 ? (a / tot * 100) : 0,
                        pctB: tot > 0 ? (b / tot * 100) : 0,
                        pctC: tot > 0 ? (c / tot * 100) : 0
                    };
                },
                disStatSummary() {
                    let a = 0, b = 0, c = 0, tot = 0;
                    (this.sumResult.DisStats || []).forEach(item => {
                        a += item.DisA;
                        b += item.DisB;
                        c += item.DisC;
                        tot += item.DisTotal;
                    });
                    return {
                        sumA: a, sumB: b, sumC: c, sumTot: tot,
                        pctA: tot > 0 ? (a / tot * 100) : 0,
                        pctB: tot > 0 ? (b / tot * 100) : 0,
                        pctC: tot > 0 ? (c / tot * 100) : 0
                    };
                }
            },
            mounted() {
                this.setDateShortcut('ytd', false);
                this.loadTowns();
                this.loadData();
            },
            methods: {
                formatDate(d) {
                    const y = d.getFullYear();
                    const m = String(d.getMonth() + 1).padStart(2, '0');
                    const day = String(d.getDate()).padStart(2, '0');
                    return y + '-' + m + '-' + day;
                },
                setDateShortcut(type, autoLoad = true) {
                    const now = new Date();
                    const y = now.getFullYear();
                    if (type === 'ytd') {
                        this.filter.dateS = y + '-01-01';
                        this.filter.dateE = this.formatDate(now);
                    } else if (type === 'm3') {
                        const s = new Date(now.getFullYear(), now.getMonth() - 2, 1);
                        this.filter.dateS = this.formatDate(s);
                        this.filter.dateE = this.formatDate(now);
                    } else if (type === 'm6') {
                        const s = new Date(now.getFullYear(), now.getMonth() - 5, 1);
                        this.filter.dateS = this.formatDate(s);
                        this.filter.dateE = this.formatDate(now);
                    } else if (type === 'y1') {
                        const s = new Date(now.getFullYear() - 1, now.getMonth(), 1);
                        this.filter.dateS = this.formatDate(s);
                        this.filter.dateE = this.formatDate(now);
                    } else if (type === 'lastyear') {
                        this.filter.dateS = (y - 1) + '-01-01';
                        this.filter.dateE = (y - 1) + '-12-31';
                    }
                    if (autoLoad) {
                        this.loadData();
                    }
                },
                switchTab(tab) {
                    this.currentTab = tab;
                    this.$nextTick(() => {
                        if (tab === 'count' || tab === 'length') {
                            this.renderCharts();
                        }
                    });
                },
                toggleTownCollapse(town) {
                    this.collapsedTowns[town] = !this.collapsedTowns[town];
                },
                expandAllTowns() {
                    this.collapsedTowns = {};
                },
                collapseAllTowns() {
                    const map = {};
                    this.groupedRoadList.forEach(g => {
                        map[g.town] = true;
                    });
                    this.collapsedTowns = map;
                },
                loadTowns() {
                    axios.get('RoadClean_Sum.aspx?action=gettowns')
                        .then(res => {
                            if (res.data && res.data.Success) {
                                this.townList = res.data.Data || [];
                            }
                        })
                        .catch(err => {
                            console.error('載入行政區失敗:', err);
                        });
                },
                onSingleTownChange() {
                    if (this.singleTown) {
                        this.selectedTowns = [this.singleTown];
                    } else {
                        this.selectedTowns = [];
                    }
                },
                toggleTown(townName) {
                    const idx = this.selectedTowns.indexOf(townName);
                    if (idx === -1) {
                        this.selectedTowns.push(townName);
                    } else {
                        this.selectedTowns.splice(idx, 1);
                    }
                    this.singleTown = this.selectedTowns.length === 1 ? this.selectedTowns[0] : '';
                },
                selectAllTowns() {
                    this.selectedTowns = this.townList.map(t => t.TownName);
                    this.singleTown = '';
                },
                clearAllTowns() {
                    this.selectedTowns = [];
                    this.singleTown = '';
                },
                resetFilter() {
                    this.selectedTowns = [];
                    this.singleTown = '';
                    this.showMultiTown = false;
                    this.onlyShowBcRoads = false;
                    this.filter.roadName = '';
                    this.filter.rdLv = '';
                    this.filter.disS = '';
                    this.filter.disE = '';
                    this.setDateShortcut('ytd', true);
                },
                loadData() {
                    this.loading = true;
                    const payload = {
                        Towns: this.selectedTowns,
                        RoadName: this.filter.roadName,
                        DateS: this.filter.dateS,
                        DateE: this.filter.dateE,
                        RdLv: this.filter.rdLv,
                        DisS: this.filter.disS ? parseFloat(this.filter.disS) : null,
                        DisE: this.filter.disE ? parseFloat(this.filter.disE) : null
                    };

                    axios.post('RoadClean_Sum.aspx?action=getsumdata', payload)
                        .then(res => {
                            this.loading = false;
                            if (res.data && res.data.Success) {
                                this.sumResult = res.data.Data;
                                this.$nextTick(() => {
                                    this.renderCharts();
                                });
                            } else {
                                alert(res.data && res.data.Message ? res.data.Message : '載入統計資料失敗');
                            }
                        })
                        .catch(err => {
                            this.loading = false;
                            console.error('載入統計資料失敗:', err);
                            alert('連線失敗，請檢查網路或稍後再試');
                        });
                },
                renderCharts() {
                    if (typeof Highcharts === 'undefined') return;

                    const categories = (this.sumResult.CountStats || []).map(item => item.MonthLabel);

                    if (document.getElementById('chartRoadCount')) {
                        const countSeriesA = (this.sumResult.CountStats || []).map(item => item.CountA);
                        const countSeriesB = (this.sumResult.CountStats || []).map(item => item.CountB);
                        const countSeriesC = (this.sumResult.CountStats || []).map(item => item.CountC);

                        Highcharts.chart('chartRoadCount', {
                            chart: { type: 'column' },
                            title: { text: null },
                            xAxis: { categories: categories, crosshair: true },
                            yAxis: { min: 0, title: { text: '道路數 (條)' }, stackLabels: { enabled: true } },
                            tooltip: { shared: true, pointFormat: '<span style="color:{series.color}">{series.name}</span>: <b>{point.y} 條</b><br/>' },
                            plotOptions: {
                                column: {
                                    stacking: 'normal',
                                    dataLabels: { enabled: true, color: 'white' }
                                }
                            },
                            colors: ['#10b981', '#f59e0b', '#ef4444'],
                            series: [
                                { name: 'A級', data: countSeriesA },
                                { name: 'B級', data: countSeriesB },
                                { name: 'C級', data: countSeriesC }
                            ],
                            credits: { enabled: false }
                        });
                    }

                    if (document.getElementById('chartRoadCountPie')) {
                        const s = this.countStatSummary;
                        Highcharts.chart('chartRoadCountPie', {
                            chart: { type: 'pie' },
                            title: { text: null },
                            tooltip: { pointFormat: '{series.name}: <b>{point.y} 條 ({point.percentage:.1f}%)</b>' },
                            plotOptions: {
                                pie: {
                                    allowPointSelect: true,
                                    cursor: 'pointer',
                                    dataLabels: { enabled: true, format: '<b>{point.name}</b>: {point.percentage:.1f} %' }
                                }
                            },
                            colors: ['#10b981', '#f59e0b', '#ef4444'],
                            series: [{
                                name: '道路數',
                                colorByPoint: true,
                                data: [
                                    { name: 'A級', y: s.sumA },
                                    { name: 'B級', y: s.sumB },
                                    { name: 'C級', y: s.sumC }
                                ]
                            }],
                            credits: { enabled: false }
                        });
                    }

                    if (document.getElementById('chartRoadDis')) {
                        const disSeriesA = (this.sumResult.DisStats || []).map(item => item.DisA);
                        const disSeriesB = (this.sumResult.DisStats || []).map(item => item.DisB);
                        const disSeriesC = (this.sumResult.DisStats || []).map(item => item.DisC);

                        Highcharts.chart('chartRoadDis', {
                            chart: { type: 'column' },
                            title: { text: null },
                            xAxis: { categories: categories, crosshair: true },
                            yAxis: { min: 0, title: { text: '里程長度 (公里)' }, stackLabels: { enabled: true } },
                            tooltip: { shared: true, pointFormat: '<span style="color:{series.color}">{series.name}</span>: <b>{point.y:.1f} km</b><br/>' },
                            plotOptions: {
                                column: {
                                    stacking: 'normal',
                                    dataLabels: { enabled: true, color: 'white', format: '{point.y:.1f}' }
                                }
                            },
                            colors: ['#10b981', '#f59e0b', '#ef4444'],
                            series: [
                                { name: 'A級長度', data: disSeriesA },
                                { name: 'B級長度', data: disSeriesB },
                                { name: 'C級長度', data: disSeriesC }
                            ],
                            credits: { enabled: false }
                        });
                    }

                    if (document.getElementById('chartRoadDisPie')) {
                        const sd = this.disStatSummary;
                        Highcharts.chart('chartRoadDisPie', {
                            chart: { type: 'pie' },
                            title: { text: null },
                            tooltip: { pointFormat: '{series.name}: <b>{point.y:.1f} km ({point.percentage:.1f}%)</b>' },
                            plotOptions: {
                                pie: {
                                    allowPointSelect: true,
                                    cursor: 'pointer',
                                    dataLabels: { enabled: true, format: '<b>{point.name}</b>: {point.percentage:.1f} %' }
                                }
                            },
                            colors: ['#10b981', '#f59e0b', '#ef4444'],
                            series: [{
                                name: '道路里程',
                                colorByPoint: true,
                                data: [
                                    { name: 'A級', y: sd.sumA },
                                    { name: 'B級', y: sd.sumB },
                                    { name: 'C級', y: sd.sumC }
                                ]
                            }],
                            credits: { enabled: false }
                        });
                    }
                },
                openChkDetail(chkId) {
                    if (!chkId) return;
                    axios.get('RoadClean_Sum.aspx?action=getchkdetail&chkId=' + encodeURIComponent(chkId))
                        .then(res => {
                            if (res.data && res.data.Success) {
                                this.chkDetail = res.data.Data;
                                $('#modalChkDetail').modal('show');
                            } else {
                                alert(res.data && res.data.Message ? res.data.Message : '查無查核詳細資料');
                            }
                        })
                        .catch(err => {
                            console.error('取得查核詳細資料失敗:', err);
                            alert('無法載入查核明細');
                        });
                },
                exportData(actionName) {
                    const townsParam = this.selectedTowns.join(',');
                    const url = 'RoadClean_Sum.aspx?action=' + actionName +
                        '&towns=' + encodeURIComponent(townsParam) +
                        '&roadName=' + encodeURIComponent(this.filter.roadName) +
                        '&dateS=' + encodeURIComponent(this.filter.dateS) +
                        '&dateE=' + encodeURIComponent(this.filter.dateE) +
                        '&rdLv=' + encodeURIComponent(this.filter.rdLv) +
                        '&disS=' + encodeURIComponent(this.filter.disS) +
                        '&disE=' + encodeURIComponent(this.filter.disE) + '&onlyBc=' + (this.onlyShowBcRoads ? '1' : '0') + '&matrixMode=' + encodeURIComponent(this.matrixMode);

                    window.location.href = url;
                }
            }
        }).mount('#sumApp');
    </script>
</body>
</html>
