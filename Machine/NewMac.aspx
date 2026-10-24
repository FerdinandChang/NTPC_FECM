<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="NewMac.aspx.cs" Inherits="NTPC_FEC.Machine.NewMac" %>

<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定溢散源管理平台 - 施工機具自主管理與檢測表</title>

    <!-- 專屬 Favicon -->
    <link rel="shortcut icon" href="../favicon.ico" type="image/x-icon" />

    <!-- 本地化核心樣式庫 (無外部 CDN) -->
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
            --accent-success: #10b981;    /* 綠色成功/合格 */
            --accent-warning: #f59e0b;    /* 黃橘色注意 */
            --accent-danger: #ef4444;     /* 紅色缺失/危險 */
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
        }

        [v-cloak] {
            display: none !important;
        }

        /* 頂部導覽列 */
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
            white-space: nowrap;
            min-width: 0;
        }

        .brand-text {
            white-space: nowrap;
            font-weight: 700;
        }

        .brand-badge {
            font-size: 0.82rem;
            white-space: nowrap;
        }

        /* 小尺寸螢幕頂部標題防換行與自適應字體縮小 */
        @media screen and (max-width: 767px) {
            .top-navbar {
                padding: 0 12px;
                height: 52px;
            }

            .top-navbar .brand-title {
                font-size: 0.95rem;
                gap: 6px;
            }

            .nav-btn {
                padding: 5px 10px;
                font-size: 0.85rem;
            }
        }

        @media screen and (max-width: 575px) {
            .top-navbar {
                padding: 0 8px;
                height: 48px;
            }

            .top-navbar .brand-title {
                font-size: 0.86rem;
                gap: 4px;
            }

            .brand-text {
                font-size: 0.86rem;
                letter-spacing: -0.2px;
            }

            .nav-btn {
                padding: 4px 8px;
                margin-right: 6px !important;
            }

            .brand-badge {
                font-size: 0.72rem !important;
                padding: 2px 6px !important;
                margin-left: 4px !important;
            }
        }

        @media screen and (max-width: 390px) {
            .top-navbar .brand-title {
                font-size: 0.78rem;
            }

            .brand-text {
                font-size: 0.78rem;
                letter-spacing: -0.4px;
            }

            .brand-badge {
                font-size: 0.68rem !important;
                padding: 1px 4px !important;
            }
        }

        .nav-btn {
            background: rgba(255, 255, 255, 0.18);
            border: 1px solid rgba(255, 255, 255, 0.3);
            color: #ffffff;
            border-radius: 8px;
            padding: 6px 14px;
            font-size: 0.9rem;
            font-weight: 600;
            transition: all 0.2s ease;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 6px;
            cursor: pointer;
        }

        .nav-btn:hover {
            background: rgba(255, 255, 255, 0.28);
            color: #ffffff;
            text-decoration: none;
        }

        /* 主容器 */
        .main-container {
            max-width: 1400px;
            margin: 0 auto;
            padding: 16px;
        }

        /* 現代卡片 */
        .card-modern {
            background: var(--surface);
            border-radius: 12px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05), 0 4px 12px rgba(15, 23, 42, 0.05);
            margin-bottom: 20px;
            border: 1px solid var(--border-color);
            overflow: hidden;
            transition: box-shadow 0.2s ease;
        }

        .card-modern:hover {
            box-shadow: 0 2px 6px rgba(0, 0, 0, 0.08), 0 8px 20px rgba(15, 23, 42, 0.07);
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
            font-size: 1.05rem;
            font-weight: 700;
            color: var(--brand-navy);
            margin: 0;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .card-modern-body {
            padding: 18px;
        }

        /* 欄位表單組件 */
        .form-label-custom {
            font-size: 0.88rem;
            font-weight: 700;
            color: #334155;
            margin-bottom: 6px;
            display: flex;
            align-items: center;
            gap: 6px;
        }

        .form-label-custom .badge-req {
            background-color: #fee2e2;
            color: #ef4444;
            font-size: 0.72rem;
            padding: 2px 6px;
            border-radius: 4px;
        }

        .form-control-modern {
            width: 100%;
            height: 40px;
            border: 1px solid var(--border-color);
            border-radius: 8px;
            padding: 8px 12px;
            font-size: 0.95rem;
            color: var(--text-main);
            background-color: #ffffff;
            transition: border-color 0.15s ease, box-shadow 0.15s ease;
        }

        .form-control-modern:focus {
            border-color: var(--brand-blue);
            outline: none;
            box-shadow: 0 0 0 3px rgba(2, 132, 199, 0.15);
        }

        /* 可搜尋下拉選單 (Searchable Select Dropdown) */
        .searchable-dropdown-wrapper {
            position: relative;
            width: 100%;
        }

        .dropdown-trigger {
            width: 100%;
            min-height: 42px;
            background: #ffffff;
            border: 1px solid var(--border-color);
            border-radius: 8px;
            padding: 8px 14px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            cursor: pointer;
            transition: all 0.2s ease;
            user-select: none;
        }

        .dropdown-trigger:hover {
            border-color: #94a3b8;
            background-color: #f8fafc;
        }

        .dropdown-trigger.is-open {
            border-color: var(--brand-blue);
            box-shadow: 0 0 0 3px rgba(2, 132, 199, 0.15);
            background-color: #ffffff;
        }

        .dropdown-trigger .trigger-label {
            font-size: 0.95rem;
            color: var(--text-main);
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }

        .dropdown-trigger .trigger-arrow {
            color: #64748b;
            font-size: 0.85rem;
            transition: transform 0.2s ease;
            margin-left: 8px;
        }

        .dropdown-trigger .trigger-arrow.rotate-180 {
            transform: rotate(180deg);
            color: var(--brand-blue);
        }

        .dropdown-panel {
            position: absolute;
            top: calc(100% + 4px);
            left: 0;
            right: 0;
            background: #ffffff;
            border: 1px solid #cbd5e1;
            border-radius: 10px;
            box-shadow: 0 10px 25px rgba(0, 0, 0, 0.12);
            z-index: 1050;
            overflow: hidden;
            animation: dropdownFadeIn 0.15s ease-out;
        }

        @keyframes dropdownFadeIn {
            from { opacity: 0; transform: translateY(-6px); }
            to { opacity: 1; transform: translateY(0); }
        }

        .dropdown-search-box {
            display: flex;
            align-items: center;
            padding: 10px 12px;
            border-bottom: 1px solid var(--border-color);
            background-color: #f8fafc;
        }

        .dropdown-search-input {
            border: none;
            background: transparent;
            width: 100%;
            font-size: 0.92rem;
            color: var(--text-main);
            outline: none;
        }

        .dropdown-options-list {
            max-height: 240px;
            overflow-y: auto;
            padding: 4px 0;
        }

        .dropdown-option-item {
            padding: 10px 14px;
            font-size: 0.92rem;
            font-weight: 500;
            color: #334155;
            display: flex;
            align-items: center;
            justify-content: space-between;
            cursor: pointer;
            transition: background-color 0.12s ease;
        }

        .dropdown-option-item:hover {
            background-color: #f1f5f9;
            color: var(--brand-blue);
        }

        .dropdown-option-item.is-selected {
            background-color: #e0f2fe;
            color: #0369a1;
            font-weight: 700;
        }

        /* 晶片選擇項 (Chip Selector) */
        .chips-group {
            display: flex;
            flex-wrap: wrap;
            gap: 8px;
        }

        .chip-btn {
            border: 1px solid #cbd5e1;
            background: #ffffff;
            color: #334155;
            padding: 7px 14px;
            border-radius: 8px;
            font-size: 0.88rem;
            font-weight: 600;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            gap: 6px;
            min-height: 42px;
            transition: all 0.15s ease;
            user-select: none;
        }

        .chip-btn:hover {
            border-color: #94a3b8;
            background: #f8fafc;
        }

        .chip-btn.active {
            background: #e0f2fe;
            border-color: var(--brand-blue);
            color: #0369a1;
            font-weight: 700;
            box-shadow: 0 0 0 2px rgba(2, 132, 199, 0.2);
        }

        /* 狀態切換開關 (Segmented Buttons) */
        .segmented-group {
            display: inline-flex;
            background: #e2e8f0;
            padding: 3px;
            border-radius: 8px;
            gap: 3px;
        }

        .segment-btn {
            border: none;
            background: transparent;
            padding: 6px 18px;
            border-radius: 6px;
            font-size: 0.9rem;
            font-weight: 600;
            color: #475569;
            cursor: pointer;
            min-height: 38px;
            transition: all 0.15s ease;
        }

        .segment-btn.active-yes {
            background: #10b981;
            color: #ffffff;
            box-shadow: 0 1px 4px rgba(16, 185, 129, 0.35);
        }

        .segment-btn.active-no {
            background: #64748b;
            color: #ffffff;
            box-shadow: 0 1px 4px rgba(100, 116, 139, 0.35);
        }

        .segment-btn.active-blue {
            background: var(--brand-blue);
            color: #ffffff;
            box-shadow: 0 1px 4px rgba(2, 132, 199, 0.35);
        }

        /* 防斷行一體化輸入組件 (Zero-break Input Group with Unit) */
        .input-group-unit {
            display: flex;
            align-items: stretch;
            width: 100%;
            border: 1px solid var(--border-color);
            border-radius: 8px;
            background-color: #ffffff;
            overflow: hidden;
            transition: border-color 0.15s ease, box-shadow 0.15s ease;
        }

        .input-group-unit:focus-within {
            border-color: var(--brand-blue);
            box-shadow: 0 0 0 3px rgba(2, 132, 199, 0.15);
        }

        .input-group-unit .unit-input {
            flex: 1 1 auto;
            width: 1%;
            min-width: 0;
            border: none;
            padding: 8px 12px;
            font-size: 0.95rem;
            color: var(--text-main);
            outline: none;
            background: transparent;
            height: 40px;
        }

        .input-group-unit .unit-prefix,
        .input-group-unit .unit-suffix {
            display: flex;
            align-items: center;
            padding: 0 14px;
            background-color: #f8fafc;
            color: #64748b;
            font-size: 0.88rem;
            font-weight: 600;
            white-space: nowrap;
            user-select: none;
        }

        .input-group-unit .unit-prefix {
            border-right: 1px solid var(--border-color);
        }

        .input-group-unit .unit-suffix {
            border-left: 1px solid var(--border-color);
        }

        .input-group-unit .unit-select {
            border: none;
            border-left: 1px solid var(--border-color);
            background-color: #f8fafc;
            color: #334155;
            font-size: 0.88rem;
            font-weight: 600;
            padding: 0 12px;
            outline: none;
            cursor: pointer;
            height: 40px;
        }

        /* 儀表板狀態小卡 */
        .status-indicator-card {
            background: #ffffff;
            border: 1px solid var(--border-color);
            border-radius: 10px;
            padding: 10px 14px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
            height: 100%;
            min-height: 52px;
        }

        .status-indicator-title {
            font-size: 0.92rem;
            font-weight: 700;
            color: var(--brand-navy);
            display: flex;
            align-items: center;
            gap: 8px;
        }

        /* 保養維護作業規格專用網格佈局 */
        .maintenance-box {
            background-color: #f8fafc;
            border: 1px solid var(--border-color);
            border-radius: 12px;
        }

        .chips-grid-2 {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 8px;
        }

        .chips-grid-3 {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 8px;
        }

        .chip-btn-block {
            width: 100%;
            justify-content: center;
            padding: 8px 10px;
            font-size: 0.85rem;
            text-align: center;
        }

        .maint-checkbox-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 8px;
        }

        @media (max-width: 768px) {
            .chips-grid-3 {
                grid-template-columns: repeat(2, 1fr);
            }
        }

        @media (max-width: 576px) {
            .chips-grid-2,
            .chips-grid-3,
            .maint-checkbox-grid {
                grid-template-columns: 1fr;
            }
        }

        .chip-btn-maint {
            width: 100%;
            justify-content: flex-start;
            padding: 8px 12px;
            font-size: 0.88rem;
        }

        /* 點檢項目清單 */
        .check-item-row {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 10px 14px;
            background: #f8fafc;
            border: 1px solid var(--border-color);
            border-radius: 8px;
            margin-bottom: 8px;
            transition: background-color 0.15s ease;
        }

        .check-item-row:hover {
            background: #f1f5f9;
        }

        .check-item-label {
            font-size: 0.92rem;
            font-weight: 600;
            color: #1e293b;
            flex: 1;
            padding-right: 12px;
        }

        /* 照片上傳卡片 */
        .photo-card {
            background: #ffffff;
            border: 1px solid var(--border-color);
            border-radius: 10px;
            padding: 12px;
            text-align: center;
            height: 100%;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
        }

        .photo-preview-box {
            width: 100%;
            height: 160px;
            border-radius: 8px;
            background: #f8fafc;
            border: 2px dashed #cbd5e1;
            display: flex;
            align-items: center;
            justify-content: center;
            overflow: hidden;
            position: relative;
            margin-bottom: 10px;
            cursor: pointer;
        }

        .photo-preview-box img {
            width: 100%;
            height: 100%;
            object-fit: cover;
        }

        .photo-preview-box .placeholder-icon {
            color: #94a3b8;
            font-size: 2.2rem;
        }

        /* 統計或平均數值晶片 */
        .avg-chip {
            background: #f0fdf4;
            border: 1px solid #86efac;
            color: #15803d;
            font-weight: 700;
            padding: 8px 14px;
            border-radius: 8px;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            font-size: 0.95rem;
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
                min-height: 44px;
            }
        }

        @media screen and (min-width: 992px) {
            .mobile-bottom-bar {
                display: none;
            }
        }

        /* 模態彈窗 (Modal) */
        .modal-lightbox {
            position: fixed;
            top: 0; left: 0; right: 0; bottom: 0;
            background: rgba(0, 0, 0, 0.85);
            z-index: 2000;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }

        .modal-lightbox img {
            max-width: 95%;
            max-height: 90vh;
            border-radius: 8px;
            box-shadow: 0 8px 30px rgba(0,0,0,0.5);
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">
    <div id="macApp" v-cloak>
        <!-- 頂部置頂導覽列 -->
        <header class="top-navbar">
            <div class="d-flex align-items-center overflow-hidden">
                <a href="javascript:history.back();" class="nav-btn mr-3">
                    <i class="fas fa-arrow-left"></i>
                    <span class="d-none d-sm-inline">返回清單</span>
                </a>
                <div class="brand-title">
                    <i class="fas fa-truck-monster text-white mr-1 flex-shrink-0"></i>
                    <span class="brand-text">施工機具自主管理與排煙檢測表</span>
                    <span class="badge badge-light text-dark font-weight-bold ml-2 brand-badge flex-shrink-0">
                        {{ mode === 'new' ? '新增機具申報' : '機具編號 #' + macId }}
                    </span>
                </div>
            </div>
            <div class="d-flex align-items-center gap-2">
                <button type="button" class="btn btn-warning btn-sm font-weight-bold d-none d-md-inline-flex align-items-center mr-2"
                        v-on:click="quickPassAllCheckItems" style="border-radius: 8px; height: 36px;">
                    <i class="fas fa-bolt mr-1"></i> 點檢全無異狀
                </button>
                <button type="button" class="btn btn-primary btn-sm font-weight-bold d-none d-md-inline-flex align-items-center shadow-sm"
                        v-on:click="submitData" :disabled="isSaving" style="border-radius: 8px; height: 36px; padding: 0 16px;">
                    <i class="fas fa-save mr-1"></i> {{ isSaving ? '儲存中...' : '儲存申報表' }}
                </button>
            </div>
        </header>

        <!-- 主體內容區塊 -->
        <main class="main-container">
            <!-- 警示訊息 (若有) -->
            <div v-if="alertMessage" class="alert shadow-sm alert-dismissible fade show" :class="'alert-' + alertType" role="alert">
                <i class="fas fa-info-circle mr-2"></i> {{ alertMessage }}
                <button type="button" class="close" v-on:click="alertMessage = ''">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>

            <!-- 區塊一：公私場所基本資料 -->
            <div class="card-modern">
                <div class="card-modern-header">
                    <h5 class="card-modern-title">
                        <i class="fas fa-building text-primary"></i> 一、公私場所基本資料
                    </h5>
                    <span class="text-muted small">管制編號：<strong>{{ facInfo.C_NO || '無' }}</strong></span>
                </div>
                <div class="card-modern-body">
                    <div class="row">
                        <div class="col-md-4 mb-3">
                            <label class="form-label-custom">
                                調查日期 <span class="badge-req">必填</span>
                            </label>
                            <input type="date" class="form-control-modern" v-model="mac.Check_date" />
                        </div>
                        <div class="col-md-8 mb-3">
                            <label class="form-label-custom">公私場所名稱</label>
                            <input type="text" class="form-control-modern font-weight-bold bg-light" :value="facInfo.FAC_NAME" readonly />
                        </div>
                    </div>

                    <!-- 場所性質 (可搜尋下拉選單) -->
                    <div class="mb-3">
                        <label class="form-label-custom">場所性質</label>
                        <div class="searchable-dropdown-wrapper">
                            <div class="dropdown-trigger" :class="{ 'is-open': dropdowns.facType.open }"
                                 v-on:click.stop="toggleDropdown('facType')">
                                <span class="trigger-label font-weight-bold" :class="{ 'text-muted': !mac.FAC_Type1 }">
                                    <i class="fas fa-layer-group text-primary mr-1"></i>
                                    {{ mac.FAC_Type1 || '請選擇場所性質 (支援打字搜尋)...' }}
                                </span>
                                <i class="fas fa-chevron-down trigger-arrow" :class="{ 'rotate-180': dropdowns.facType.open }"></i>
                            </div>

                            <div v-if="dropdowns.facType.open" class="dropdown-panel shadow-lg" v-on:click.stop>
                                <div class="dropdown-search-box">
                                    <i class="fas fa-search text-muted mr-2"></i>
                                    <input type="text" id="facTypeSearchInput" class="dropdown-search-input"
                                           v-model="dropdowns.facType.search"
                                           placeholder="輸入關鍵字過濾場所性質 (例: 工地, 砂石場)..." />
                                    <button v-if="dropdowns.facType.search" type="button" class="btn btn-link btn-sm text-muted p-0"
                                            v-on:click="dropdowns.facType.search = ''">
                                        <i class="fas fa-times-circle"></i>
                                    </button>
                                </div>
                                <div class="dropdown-options-list">
                                    <div v-for="t in filteredFacTypes" :key="t"
                                         class="dropdown-option-item"
                                         :class="{ 'is-selected': mac.FAC_Type1 === t }"
                                         v-on:click="selectDropdownItem('FAC_Type1', t, 'facType')">
                                        <span>{{ t }}</span>
                                        <i v-if="mac.FAC_Type1 === t" class="fas fa-check text-primary"></i>
                                    </div>
                                    <div class="dropdown-option-item"
                                         :class="{ 'is-selected': isFacTypeOther }"
                                         v-on:click="selectDropdownItem('FAC_Type1', '其他', 'facType')">
                                        <span>其他 (自填)</span>
                                        <i v-if="isFacTypeOther" class="fas fa-check text-primary"></i>
                                    </div>
                                    <div v-if="filteredFacTypes.length === 0" class="p-3 text-center text-muted small">
                                        查無相符項目，可選下方「其他 (自填)」
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div v-if="isFacTypeOther" class="mt-2">
                            <input type="text" id="facTypeOtherInput" class="form-control-modern" v-model="facTypeOtherText" placeholder="請自填場所性質名稱" />
                        </div>
                    </div>

                    <!-- 作業用地總面積 -->
                    <div class="row">
                        <div class="col-md-6 mb-3">
                            <label class="form-label-custom">作業用地總面積</label>
                            <div class="input-group-unit">
                                <input type="number" step="any" class="unit-input" v-model="mac.Use_Area" placeholder="請輸入作業面積數值" />
                                <select class="unit-select" v-model="mac.Use_Area_Unit">
                                    <option value="平方公尺">平方公尺(㎡)</option>
                                    <option value="公頃">公頃</option>
                                </select>
                            </div>
                        </div>

                        <!-- 機具產權 -->
                        <div class="col-md-6 mb-3">
                            <label class="form-label-custom">機具產權</label>
                            <div class="chips-grid-3 mb-2">
                                <button v-for="b in macBossOptions" :key="b.Val" type="button" class="chip-btn chip-btn-block"
                                        :class="{ 'active': mac.mac_boss1 === b.Val }"
                                        v-on:click="mac.mac_boss1 = b.Val">
                                    {{ b.Text }}
                                </button>
                            </div>
                            <div v-if="needBossDetail" class="row mt-2">
                                <div class="col-sm-6 mb-2">
                                    <input type="text" class="form-control-modern" v-model="mac.mac_boss2" placeholder="詳細名稱 (個人/外包/租賃)" />
                                </div>
                                <div class="col-sm-6 mb-2">
                                    <input type="text" class="form-control-modern" v-model="mac.mac_boss_tel" placeholder="所有者聯絡電話" />
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- 駕駛資料 -->
                    <div class="row">
                        <div class="col-md-6 mb-2">
                            <label class="form-label-custom">機具駕駛姓名</label>
                            <input type="text" class="form-control-modern" v-model="mac.Driver_Name" placeholder="填寫機具駕駛姓名" />
                        </div>
                        <div class="col-md-6 mb-2">
                            <label class="form-label-custom">駕駛聯絡電話</label>
                            <input type="text" class="form-control-modern" v-model="mac.Driver_Tel" placeholder="填寫駕駛聯絡電話" />
                        </div>
                    </div>
                </div>
            </div>

            <!-- 區塊二：施工機具基本資料 -->
            <div class="card-modern">
                <div class="card-modern-header flex-column align-items-start py-2">
                    <h5 class="card-modern-title mb-1">
                        <i class="fas fa-cogs text-info"></i> 二、施工機具基本規格資料
                    </h5>
                    <span class="text-muted small" style="padding-left: 26px;">
                        支援下拉選單打字搜尋，提高現場錄案速度
                    </span>
                </div>
                <div class="card-modern-body">
                    <!-- 施工機具種類型式 與 機具廠牌 (可搜尋下拉選單) -->
                    <div class="row">
                        <!-- 種類型式 (可搜尋下拉選單) -->
                        <div class="col-md-6 mb-4">
                            <label class="form-label-custom">
                                施工機具種類型式 <span class="badge-req">必填</span>
                            </label>
                            <div class="searchable-dropdown-wrapper">
                                <div class="dropdown-trigger" :class="{ 'is-open': dropdowns.macType.open }"
                                     v-on:click.stop="toggleDropdown('macType')">
                                    <span class="trigger-label font-weight-bold" :class="{ 'text-muted': !mac.mac_Type }">
                                        <i class="fas fa-tractor text-info mr-1"></i>
                                        {{ mac.mac_Type || '請選擇機具種類型式 (支援打字搜尋)...' }}
                                    </span>
                                    <i class="fas fa-chevron-down trigger-arrow" :class="{ 'rotate-180': dropdowns.macType.open }"></i>
                                </div>

                                <div v-if="dropdowns.macType.open" class="dropdown-panel shadow-lg" v-on:click.stop>
                                    <div class="dropdown-search-box">
                                        <i class="fas fa-search text-muted mr-2"></i>
                                        <input type="text" id="macTypeSearchInput" class="dropdown-search-input"
                                               v-model="dropdowns.macType.search"
                                               placeholder="輸入關鍵字過濾種類 (例: 挖土機, 發電機, 推土機)..." />
                                        <button v-if="dropdowns.macType.search" type="button" class="btn btn-link btn-sm text-muted p-0"
                                                v-on:click="dropdowns.macType.search = ''">
                                            <i class="fas fa-times-circle"></i>
                                        </button>
                                    </div>
                                    <div class="dropdown-options-list">
                                        <div v-for="t in filteredMacTypes" :key="t"
                                             class="dropdown-option-item"
                                             :class="{ 'is-selected': mac.mac_Type === t }"
                                             v-on:click="selectDropdownItem('mac_Type', t, 'macType')">
                                            <span>{{ t }}</span>
                                            <i v-if="mac.mac_Type === t" class="fas fa-check text-primary"></i>
                                        </div>
                                        <div class="dropdown-option-item"
                                             :class="{ 'is-selected': isMacTypeOther }"
                                             v-on:click="selectDropdownItem('mac_Type', '21.其他', 'macType')">
                                            <span>21.其他 (自填)</span>
                                            <i v-if="isMacTypeOther" class="fas fa-check text-primary"></i>
                                        </div>
                                        <div v-if="filteredMacTypes.length === 0" class="p-3 text-center text-muted small">
                                            查無相符種類，可選下方「21.其他 (自填)」
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div v-if="isMacTypeOther" class="mt-2">
                                <input type="text" id="macTypeOtherInput" class="form-control-modern" v-model="macTypeOtherText" placeholder="請自填其他機具種類名稱" />
                            </div>
                        </div>

                        <!-- 機具廠牌 (可搜尋下拉選單) -->
                        <div class="col-md-6 mb-4">
                            <label class="form-label-custom">
                                機具廠牌 <span class="badge-req">必填</span>
                            </label>
                            <div class="searchable-dropdown-wrapper">
                                <div class="dropdown-trigger" :class="{ 'is-open': dropdowns.brand.open }"
                                     v-on:click.stop="toggleDropdown('brand')">
                                    <span class="trigger-label font-weight-bold" :class="{ 'text-muted': !mac.Brand }">
                                        <i class="fas fa-tag text-warning mr-1"></i>
                                        {{ mac.Brand || '請選擇機具廠牌 (支援打字搜尋)...' }}
                                    </span>
                                    <i class="fas fa-chevron-down trigger-arrow" :class="{ 'rotate-180': dropdowns.brand.open }"></i>
                                </div>

                                <div v-if="dropdowns.brand.open" class="dropdown-panel shadow-lg" v-on:click.stop>
                                    <div class="dropdown-search-box">
                                        <i class="fas fa-search text-muted mr-2"></i>
                                        <input type="text" id="brandSearchInput" class="dropdown-search-input"
                                               v-model="dropdowns.brand.search"
                                               placeholder="輸入關鍵字過濾廠牌 (例: KOMATSU, 日立, CAT)..." />
                                        <button v-if="dropdowns.brand.search" type="button" class="btn btn-link btn-sm text-muted p-0"
                                                v-on:click="dropdowns.brand.search = ''">
                                            <i class="fas fa-times-circle"></i>
                                        </button>
                                    </div>
                                    <div class="dropdown-options-list">
                                        <div v-for="b in filteredBrands" :key="b"
                                             class="dropdown-option-item"
                                             :class="{ 'is-selected': mac.Brand === b }"
                                             v-on:click="selectDropdownItem('Brand', b, 'brand')">
                                            <span>{{ b }}</span>
                                            <i v-if="mac.Brand === b" class="fas fa-check text-primary"></i>
                                        </div>
                                        <div class="dropdown-option-item"
                                             :class="{ 'is-selected': isBrandOther }"
                                             v-on:click="selectDropdownItem('Brand', '49.其他', 'brand')">
                                            <span>49.其他 (自填)</span>
                                            <i v-if="isBrandOther" class="fas fa-check text-primary"></i>
                                        </div>
                                        <div v-if="filteredBrands.length === 0" class="p-3 text-center text-muted small">
                                            查無相符廠牌，可選下方「49.其他 (自填)」
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div v-if="isBrandOther" class="mt-2">
                                <input type="text" id="brandOtherInput" class="form-control-modern" v-model="brandOtherText" placeholder="請自填廠牌名稱" />
                            </div>
                        </div>
                    </div>

                    <!-- 型號、機身、引擎、年份 -->
                    <div class="row">
                        <div class="col-md-3 col-sm-6 mb-3">
                            <label class="form-label-custom">機具型號</label>
                            <input type="text" class="form-control-modern" v-model="mac.model" placeholder="例：PC200-8" />
                        </div>
                        <div class="col-md-3 col-sm-6 mb-3">
                            <label class="form-label-custom">機身號碼 (PIN)</label>
                            <input type="text" class="form-control-modern" v-model="mac.PIN" placeholder="填寫機身序號" />
                        </div>
                        <div class="col-md-3 col-sm-6 mb-3">
                            <label class="form-label-custom">引擎編號</label>
                            <input type="text" class="form-control-modern" v-model="mac.Engine_NO" placeholder="填寫引擎序號" />
                        </div>
                        <div class="col-md-3 col-sm-6 mb-3">
                            <label class="form-label-custom">出產年份 (民國年)</label>
                            <select class="form-control-modern" v-model="mac.OUT_YEAR">
                                <option v-for="y in yearList" :key="y" :value="y">{{ y }}</option>
                            </select>
                        </div>
                    </div>

                    <!-- 規格參數 (重量、費用、馬力、轉速、排氣量) -->
                    <div class="row">
                        <div class="col-md-3 col-sm-6 mb-3">
                            <label class="form-label-custom">總重量</label>
                            <div class="input-group-unit">
                                <input type="number" step="any" class="unit-input" v-model="mac.Weight" placeholder="0" />
                                <span class="unit-suffix">噸</span>
                            </div>
                        </div>
                        <div class="col-md-3 col-sm-6 mb-3">
                            <label class="form-label-custom">排氣量</label>
                            <div class="input-group-unit">
                                <input type="number" step="any" class="unit-input" v-model="mac.Exhaust_volume" placeholder="0" />
                                <span class="unit-suffix">C.C</span>
                            </div>
                        </div>
                        <div class="col-md-3 col-sm-6 mb-3">
                            <label class="form-label-custom">額定馬力</label>
                            <div class="input-group-unit">
                                <input type="number" step="any" class="unit-input" v-model="mac.Power" placeholder="0" />
                                <select class="unit-select" v-model="mac.Power_Unit">
                                    <option value="HP">HP</option>
                                    <option value="kW">kW</option>
                                    <option value="PS">PS</option>
                                </select>
                            </div>
                        </div>
                        <div class="col-md-3 col-sm-6 mb-3">
                            <label class="form-label-custom">額定轉速</label>
                            <div class="input-group-unit">
                                <input type="number" step="any" class="unit-input" v-model="mac.Rotating_speed" placeholder="0" />
                                <span class="unit-suffix">rpm</span>
                            </div>
                        </div>
                    </div>

                    <!-- 排氣管位置與油門型式 -->
                    <div class="row">
                        <div class="col-md-6 mb-3">
                            <label class="form-label-custom">排氣管位置</label>
                            <div class="chips-group">
                                <button v-for="opt in exhaustSideOptions" :key="opt" type="button" class="chip-btn"
                                        :class="{ 'active': mac.Exhaust_Side === opt }"
                                        v-on:click="mac.Exhaust_Side = opt">
                                    {{ opt }}
                                </button>
                            </div>
                        </div>
                        <div class="col-md-6 mb-3">
                            <label class="form-label-custom">油門型式</label>
                            <div class="chips-group">
                                <button v-for="opt in acceleratorOptions" :key="opt" type="button" class="chip-btn"
                                        :class="{ 'active': mac.accelerator === opt }"
                                        v-on:click="mac.accelerator = opt">
                                    {{ opt }}
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- 使用狀況與運輸方式 -->
                    <div class="row">
                        <div class="col-md-6 mb-3">
                            <label class="form-label-custom">使用狀況</label>
                            <div class="chips-group mb-2">
                                <button type="button" class="chip-btn" :class="{ 'active': mac.Always_Here_Mode === '常駐' }"
                                        v-on:click="mac.Always_Here_Mode = '常駐'">
                                    常駐本場所
                                </button>
                                <button type="button" class="chip-btn" :class="{ 'active': mac.Always_Here_Mode === '非常駐' }"
                                        v-on:click="mac.Always_Here_Mode = '非常駐'">
                                    非常駐、不定期至其他場所
                                </button>
                            </div>
                            <div v-if="mac.Always_Here_Mode === '非常駐'">
                                <input type="text" class="form-control-modern" v-model="mac.Always_Here_Other" placeholder="填寫出入頻率或說明" />
                            </div>
                        </div>

                        <div class="col-md-6 mb-3">
                            <label class="form-label-custom">機具運輸方式</label>
                            <div class="chips-group">
                                <button v-for="m in moveModeOptions" :key="m" type="button" class="chip-btn"
                                        :class="{ 'active': mac.Move_Mode === m }"
                                        v-on:click="mac.Move_Mode = m">
                                    {{ m }}
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- 油品來源、使用時機、運作習慣 -->
                    <div class="row">
                        <div class="col-md-4 mb-3">
                            <label class="form-label-custom">燃料油品來源</label>
                            <div class="chips-group">
                                <button v-for="o in oilFromOptions" :key="o" type="button" class="chip-btn"
                                        :class="{ 'active': mac.Oil_From === o }"
                                        v-on:click="mac.Oil_From = o">
                                    {{ o }}
                                </button>
                            </div>
                        </div>
                        <div class="col-md-8 mb-3">
                            <label class="form-label-custom">機具使用時機</label>
                            <input type="text" class="form-control-modern" v-model="mac.When_To_Use" placeholder="例：基礎開挖時、整地回填時" />
                        </div>
                    </div>

                    <!-- 3 個是/否 狀態開關 (儀表板規格對齊卡片) -->
                    <div class="row mb-3">
                        <div class="col-md-4 mb-3">
                            <div class="status-indicator-card">
                                <span class="status-indicator-title">
                                    <i class="fas fa-user-check text-primary"></i> 同一人操作
                                </span>
                                <div class="segmented-group">
                                    <button type="button" class="segment-btn" :class="{ 'active-yes': mac.one_Driver === '是' }"
                                            v-on:click="mac.one_Driver = '是'">是</button>
                                    <button type="button" class="segment-btn" :class="{ 'active-no': mac.one_Driver === '否' }"
                                            v-on:click="mac.one_Driver = '否'">否</button>
                                </div>
                            </div>
                        </div>

                        <div class="col-md-4 mb-3">
                            <div class="status-indicator-card">
                                <span class="status-indicator-title">
                                    <i class="fas fa-smog text-danger"></i> 發現黑煙行為
                                </span>
                                <div class="segmented-group">
                                    <button type="button" class="segment-btn" :class="{ 'active-yes': mac.Black_Smoke === '是' }"
                                            v-on:click="mac.Black_Smoke = '是'">是</button>
                                    <button type="button" class="segment-btn" :class="{ 'active-no': mac.Black_Smoke === '否' }"
                                            v-on:click="mac.Black_Smoke = '否'">否</button>
                                </div>
                            </div>
                        </div>

                        <div class="col-md-4 mb-3">
                            <div class="status-indicator-card">
                                <span class="status-indicator-title">
                                    <i class="fas fa-bullhorn text-warning"></i> 曾遭民眾陳情
                                </span>
                                <div class="segmented-group">
                                    <button type="button" class="segment-btn" :class="{ 'active-yes': mac.Report_Black_Smoke === '是' }"
                                            v-on:click="mac.Report_Black_Smoke = '是'">是</button>
                                    <button type="button" class="segment-btn" :class="{ 'active-no': mac.Report_Black_Smoke === '否' }"
                                            v-on:click="mac.Report_Black_Smoke = '否'">否</button>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- 保養資訊 (整齊網格化與無斷行輸入組件) -->
                    <div class="maintenance-box p-3 mb-3">
                        <div class="mb-3 border-bottom pb-2">
                            <h6 class="font-weight-bold text-dark mb-1">
                                <i class="fas fa-wrench text-secondary mr-2"></i>保養維護作業規格
                            </h6>
                            <div class="text-muted small" style="padding-left: 24px;">
                                落實定期保養可有效維持引擎最佳燃燒效能
                            </div>
                        </div>

                        <div class="row">
                            <!-- 保養地點 -->
                            <div class="col-lg-4 mb-3">
                                <label class="form-label-custom">保養地點</label>
                                <div class="chips-grid-2 mb-2">
                                    <button v-for="p in maintenancePlaceOptions" :key="p" type="button" class="chip-btn chip-btn-block"
                                            :class="{ 'active': mac.Maintenance_Place === p }"
                                            v-on:click="mac.Maintenance_Place = p">
                                        {{ p }}
                                    </button>
                                </div>
                                <div v-if="mac.Maintenance_Place !== '自行保養'" class="mt-2">
                                    <input type="text" class="form-control-modern" v-model="mac.Maintenance_PlaceName" placeholder="填寫指定保養廠名稱" />
                                </div>
                            </div>

                            <!-- 保養頻率與年維護費用 -->
                            <div class="col-lg-4 mb-3">
                                <div class="mb-3">
                                    <label class="form-label-custom">保養頻率</label>
                                    <div class="input-group-unit">
                                        <span class="unit-prefix">每</span>
                                        <input type="number" class="unit-input" v-model="mac.Maintenance_Frequency" placeholder="數值" />
                                        <select class="unit-select" v-model="mac.Maintenance_Frequency_Unit">
                                            <option value="月">月</option>
                                            <option value="公里">公里</option>
                                        </select>
                                    </div>
                                </div>

                                <div>
                                    <label class="form-label-custom">年平均維修保養費用</label>
                                    <div class="input-group-unit">
                                        <input type="number" class="unit-input" v-model="mac.Maintenance_Price" placeholder="輸入金額" />
                                        <span class="unit-suffix">元</span>
                                    </div>
                                </div>
                            </div>

                            <!-- 平常保養方式 -->
                            <div class="col-lg-4 mb-3">
                                <label class="form-label-custom">平常保養方式 (可複選)</label>
                                <div class="maint-checkbox-grid">
                                    <button v-for="t in maintenanceTypes" :key="t" type="button" class="chip-btn chip-btn-maint"
                                            :class="{ 'active': isMaintTypeChecked(t) }"
                                            v-on:click="toggleMaintType(t)">
                                        <i class="fas" :class="isMaintTypeChecked(t) ? 'fa-check-square text-success' : 'fa-square text-muted'"></i>
                                        <span>{{ t }}</span>
                                    </button>
                                </div>
                            </div>
                        </div>

                        <!-- 加裝防制設備區塊 (整齊子卡片) -->
                        <div class="mt-2 pt-3 border-top">
                            <div class="row align-items-center">
                                <div class="col-md-4 mb-2 mb-md-0">
                                    <label class="form-label-custom mb-1">是否已加裝排煙防制設備</label>
                                    <div class="segmented-group">
                                        <button type="button" class="segment-btn" :class="{ 'active-yes': mac.Has_Control === '是' }"
                                                v-on:click="mac.Has_Control = '是'">
                                            <i class="fas fa-check-circle mr-1"></i> 已加裝
                                        </button>
                                        <button type="button" class="segment-btn" :class="{ 'active-no': mac.Has_Control === '否' }"
                                                v-on:click="mac.Has_Control = '否'">
                                            <i class="fas fa-times-circle mr-1"></i> 否 / 不清楚
                                        </button>
                                    </div>
                                </div>
                                <div class="col-md-8">
                                    <div v-if="mac.Has_Control === '是'">
                                        <label class="form-label-custom text-primary mb-1">已加裝防制設備類型 (可複選)：</label>
                                        <div class="chips-group">
                                            <button v-for="eq in controlEquipOptions" :key="eq" type="button" class="chip-btn"
                                                    :class="{ 'active': isControlEquipChecked(eq) }"
                                                    v-on:click="toggleControlEquip(eq)">
                                                <i class="fas" :class="isControlEquipChecked(eq) ? 'fa-check-square text-success' : 'fa-square text-muted'"></i>
                                                {{ eq }}
                                            </button>
                                        </div>
                                    </div>
                                    <div v-else class="text-muted small">
                                        <i class="fas fa-info-circle mr-1"></i> 該機具未加裝濾煙器 (DPF)、EGR 或 SCR 尿素還原設備。
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- 區塊三：施工機具排煙狀況目視判別 -->
            <div class="card-modern">
                <div class="card-modern-header">
                    <h5 class="card-modern-title">
                        <i class="fas fa-eye text-warning"></i> 三、施工機具排煙狀況目視判別
                    </h5>
                </div>
                <div class="card-modern-body">
                    <div class="row">
                        <!-- 啟動瞬間 -->
                        <div class="col-md-4 mb-3">
                            <label class="form-label-custom">1. 啟動瞬間</label>
                            <div class="chips-grid-2">
                                <button v-for="s in smokeOptions" :key="s" type="button" class="chip-btn chip-btn-block"
                                        :class="{ 'active': mac.Smoke_Start === s }"
                                        v-on:click="mac.Smoke_Start = s">
                                    {{ s }}
                                </button>
                            </div>
                        </div>

                        <!-- 暖機階段 -->
                        <div class="col-md-4 mb-3">
                            <label class="form-label-custom">2. 暖機階段</label>
                            <div class="chips-grid-2">
                                <button v-for="s in smokeOptions" :key="s" type="button" class="chip-btn chip-btn-block"
                                        :class="{ 'active': mac.Smoke_Warn === s }"
                                        v-on:click="mac.Smoke_Warn = s">
                                    {{ s }}
                                </button>
                            </div>
                        </div>

                        <!-- 檢測階段 -->
                        <div class="col-md-4 mb-3">
                            <label class="form-label-custom">3. 檢測階段</label>
                            <div class="chips-grid-2">
                                <button v-for="s in smokeOptions" :key="s" type="button" class="chip-btn chip-btn-block"
                                        :class="{ 'active': mac.Smoke_Test === s }"
                                        v-on:click="mac.Smoke_Test = s">
                                    {{ s }}
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- 區塊四：不透光率檢測點檢程序 (檢測前必填 8 項) -->
            <div class="card-modern">
                <div class="card-modern-header flex-column align-items-stretch py-2">
                    <!-- 第一行：主標題與桌機版快捷按鈕 -->
                    <div class="d-flex align-items-center justify-content-between">
                        <h5 class="card-modern-title mb-0">
                            <i class="fas fa-tasks text-success mr-1"></i> 四、不透光率檢測點檢程序
                        </h5>
                        <button type="button" class="btn btn-outline-success btn-sm font-weight-bold d-none d-sm-inline-block text-nowrap" v-on:click="quickPassAllCheckItems">
                            <i class="fas fa-bolt mr-1"></i> 一鍵全部無異狀
                        </button>
                    </div>
                    <!-- 第二行：副標說明與手機版快捷按鈕 -->
                    <div class="d-flex align-items-center justify-content-between mt-1">
                        <span class="text-muted small" style="padding-left: 24px;">
                            (檢測執行前必填)
                        </span>
                        <button type="button" class="btn btn-outline-success btn-sm font-weight-bold d-sm-none text-nowrap py-1 px-2" v-on:click="quickPassAllCheckItems">
                            <i class="fas fa-bolt mr-1"></i> 一鍵全部無異狀
                        </button>
                    </div>
                </div>
                <div class="card-modern-body">
                    <div class="row">
                        <div v-for="(item, idx) in checkItemsList" :key="item.key" class="col-lg-6 mb-2">
                            <div class="check-item-row">
                                <span class="check-item-label">{{ idx + 1 }}. {{ item.title }}</span>
                                <div class="segmented-group">
                                    <button type="button" class="segment-btn" :class="{ 'active-yes': mac[item.key] === '無' }"
                                            v-on:click="mac[item.key] = '無'">無</button>
                                    <button type="button" class="segment-btn" :class="{ 'active-no': mac[item.key] === '有' }"
                                            v-on:click="mac[item.key] = '有'">有</button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- 區塊五：施工機具 不透光率排煙檢測結果 -->
            <div class="card-modern">
                <div class="card-modern-header">
                    <h5 class="card-modern-title">
                        <i class="fas fa-tachometer-alt text-danger"></i> 五、施工機具 不透光率排煙檢測結果
                    </h5>
                    <span class="text-muted small">系統即時自動計算 3 次平均值</span>
                </div>
                <div class="card-modern-body">
                    <div class="row">
                        <!-- 啟動值 -->
                        <div class="col-md-6 mb-4">
                            <div class="p-3 border rounded-lg bg-white h-100">
                                <div class="d-flex align-items-center justify-content-between mb-3 border-bottom pb-2">
                                    <h6 class="font-weight-bold text-dark mb-0"><i class="fas fa-play-circle text-primary mr-1"></i> 啟動值檢測</h6>
                                    <div class="avg-chip">
                                        平均：<strong>{{ computedStartAvg }}</strong> m⁻¹
                                    </div>
                                </div>

                                <div class="mb-3">
                                    <label class="form-label-custom">檢測前溫度</label>
                                    <div class="input-group-unit">
                                        <input type="number" step="any" class="unit-input" v-model="mac.Tempeture_Start" placeholder="0" />
                                        <span class="unit-suffix">℃</span>
                                    </div>
                                </div>

                                <div class="row">
                                    <div class="col-4 mb-2">
                                        <label class="form-label-custom small">第一次</label>
                                        <div class="input-group-unit">
                                            <input type="number" step="any" class="unit-input" v-model="mac.opaque_Start1" placeholder="0" />
                                            <span class="unit-suffix">m⁻¹</span>
                                        </div>
                                    </div>
                                    <div class="col-4 mb-2">
                                        <label class="form-label-custom small">第二次</label>
                                        <div class="input-group-unit">
                                            <input type="number" step="any" class="unit-input" v-model="mac.opaque_Start2" placeholder="0" />
                                            <span class="unit-suffix">m⁻¹</span>
                                        </div>
                                    </div>
                                    <div class="col-4 mb-2">
                                        <label class="form-label-custom small">第三次</label>
                                        <div class="input-group-unit">
                                            <input type="number" step="any" class="unit-input" v-model="mac.opaque_Start3" placeholder="0" />
                                            <span class="unit-suffix">m⁻¹</span>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- 運行值 -->
                        <div class="col-md-6 mb-4">
                            <div class="p-3 border rounded-lg bg-white h-100">
                                <div class="d-flex align-items-center justify-content-between mb-3 border-bottom pb-2">
                                    <h6 class="font-weight-bold text-dark mb-0"><i class="fas fa-sync-alt text-success mr-1"></i> 運行值檢測</h6>
                                    <div class="avg-chip">
                                        平均：<strong>{{ computedRunAvg }}</strong> m⁻¹
                                    </div>
                                </div>

                                <div class="mb-3">
                                    <label class="form-label-custom">檢測前溫度</label>
                                    <div class="input-group-unit">
                                        <input type="number" step="any" class="unit-input" v-model="mac.Tempeture_Run" placeholder="0" />
                                        <span class="unit-suffix">℃</span>
                                    </div>
                                </div>

                                <div class="row">
                                    <div class="col-4 mb-2">
                                        <label class="form-label-custom small">第一次</label>
                                        <div class="input-group-unit">
                                            <input type="number" step="any" class="unit-input" v-model="mac.opaque_Run1" placeholder="0" />
                                            <span class="unit-suffix">m⁻¹</span>
                                        </div>
                                    </div>
                                    <div class="col-4 mb-2">
                                        <label class="form-label-custom small">第二次</label>
                                        <div class="input-group-unit">
                                            <input type="number" step="any" class="unit-input" v-model="mac.opaque_Run2" placeholder="0" />
                                            <span class="unit-suffix">m⁻¹</span>
                                        </div>
                                    </div>
                                    <div class="col-4 mb-2">
                                        <label class="form-label-custom small">第三次</label>
                                        <div class="input-group-unit">
                                            <input type="number" step="any" class="unit-input" v-model="mac.opaque_Run3" placeholder="0" />
                                            <span class="unit-suffix">m⁻¹</span>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- 區塊六：核發標章資料 -->
            <div class="card-modern">
                <div class="card-modern-header">
                    <h5 class="card-modern-title">
                        <i class="fas fa-stamp text-info"></i> 六、施工機具 核發標章資料
                    </h5>
                </div>
                <div class="card-modern-body">
                    <div class="row">
                        <div class="col-md-6 mb-3">
                            <label class="form-label-custom">標章編號</label>
                            <input type="text" class="form-control-modern" v-model="mac.Mark_NO" placeholder="填寫檢驗核發標章號碼" />
                        </div>
                        <div class="col-md-6 mb-3">
                            <label class="form-label-custom">標章期限</label>
                            <input type="date" class="form-control-modern" v-model="mac.Mark_Deadline" />
                        </div>
                    </div>
                </div>
            </div>

            <!-- 區塊七：檢測照片上傳 (6 大類) -->
            <div class="card-modern">
                <div class="card-modern-header">
                    <h5 class="card-modern-title">
                        <i class="fas fa-camera text-primary"></i> 七、檢測與機具佐證照片 (共 6 類)
                    </h5>
                    <span class="text-muted small">點擊照片卡片可上傳或更換</span>
                </div>
                <div class="card-modern-body">
                    <div class="row">
                        <div v-for="cat in photoCategories" :key="cat" class="col-lg-4 col-sm-6 mb-3">
                            <div class="photo-card shadow-sm">
                                <div class="d-flex align-items-center justify-content-between mb-2">
                                    <strong class="text-dark small"><i class="fas fa-image text-muted mr-1"></i> {{ cat }}</strong>
                                    <button v-if="hasPhoto(cat)" type="button" class="btn btn-outline-danger btn-sm p-1"
                                            v-on:click="removePhoto(cat)" title="刪除照片">
                                        <i class="fas fa-trash-alt"></i>
                                    </button>
                                </div>

                                <div class="photo-preview-box" v-on:click="triggerUpload(cat)">
                                    <img v-if="hasPhoto(cat)" :src="getPhotoUrl(cat)" alt="佐證照片" />
                                    <div v-else class="text-center">
                                        <i class="fas fa-cloud-upload-alt placeholder-icon"></i>
                                        <div class="small text-muted mt-1">點擊上傳 / 拍照</div>
                                    </div>
                                </div>

                                <input type="file" :id="'file_' + cat" accept="image/*" class="d-none"
                                       v-on:change="onFileSelected($event, cat)" />

                                <div class="d-flex align-items-center justify-content-between mt-2">
                                    <button type="button" class="btn btn-outline-secondary btn-sm btn-block" v-on:click="triggerUpload(cat)">
                                        <i class="fas fa-upload mr-1"></i> {{ hasPhoto(cat) ? '更換照片' : '選擇照片' }}
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- 桌面端儲存按鈕列 -->
            <div class="text-center my-4 d-none d-md-block">
                <button type="button" class="btn btn-primary btn-lg font-weight-bold px-5 mr-3 shadow"
                        v-on:click="submitData" :disabled="isSaving">
                    <i class="fas fa-save mr-2"></i> {{ isSaving ? '儲存中...' : '儲存送出申報表' }}
                </button>
                <a href="javascript:history.back();" class="btn btn-secondary btn-lg font-weight-bold px-4">
                    取消返回
                </a>
            </div>
        </main>

        <!-- 手機端常駐浮動動作列 (Sticky Bottom Bar) -->
        <div class="mobile-bottom-bar">
            <a href="javascript:history.back();" class="btn btn-secondary">
                <i class="fas fa-arrow-left mr-1"></i> 返回
            </a>
            <button type="button" class="btn btn-warning" v-on:click="quickPassAllCheckItems">
                <i class="fas fa-bolt mr-1"></i> 全無異狀
            </button>
            <button type="button" class="btn btn-primary" v-on:click="submitData" :disabled="isSaving">
                <i class="fas fa-save mr-1"></i> {{ isSaving ? '儲存中' : '儲存送出' }}
            </button>
        </div>

        <!-- 圖片放大預覽燈箱 (Lightbox Modal) -->
        <div v-if="previewModalUrl" class="modal-lightbox" v-on:click="previewModalUrl = ''">
            <img :src="previewModalUrl" alt="放大預覽" />
        </div>
    </div>
    </form>

    <!-- 本地化核心腳本庫 (無外部 CDN) -->
    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>

    <script>
        const { createApp } = Vue;

        createApp({
            data() {
                return {
                    mode: 'new',
                    facId: '',
                    macId: '',
                    isSaving: false,
                    alertMessage: '',
                    alertType: 'info',
                    previewModalUrl: '',

                    facInfo: {
                        FAC_ID: '',
                        C_NO: '',
                        FAC_NAME: '',
                        FAC_Type1: '',
                        Use_Area: '',
                        Use_Area_Unit: '平方公尺'
                    },

                    // 施工機具表單模型
                    mac: {
                        Check_date: '',
                        FAC_Type1: '',
                        Use_Area: '',
                        Use_Area_Unit: '平方公尺',
                        mac_boss1: '1.營造廠',
                        mac_boss2: '',
                        mac_boss_tel: '',
                        Driver_Name: '',
                        Driver_Tel: '',

                        mac_Type: '01.挖土機',
                        Brand: '01.KOMATSU 小松',
                        model: '',
                        PIN: '',
                        OUT_YEAR: '無資料',
                        Engine_NO: '',
                        Weight: '',
                        MachinePrice: '',
                        Power: '',
                        Power_Unit: 'HP',
                        Rotating_speed: '',
                        Exhaust_volume: '',
                        Exhaust_Side: '機具側邊',
                        accelerator: '傳統腳踏式油門',
                        Always_Here_Mode: '常駐',
                        Always_Here_Other: '',
                        Move_Mode: '拖運',
                        When_To_Use: '',
                        Oil_From: '中油',
                        one_Driver: '是',
                        Black_Smoke: '否',
                        Report_Black_Smoke: '否',

                        Maintenance_Place: '原廠(即機具代理商授權之保養廠)',
                        Maintenance_PlaceName: '',
                        Maintenance_Frequency: '1',
                        Maintenance_Frequency_Unit: '月',
                        Maintenance_Type: '更換機油、更換空氣濾芯',
                        Maintenance_Price: '',
                        Has_Control: '否',
                        Control_equipment: '',

                        Smoke_Start: '無可見煙',
                        Smoke_Warn: '無可見煙',
                        Smoke_Test: '無可見煙',

                        Light_Item1: '無',
                        Light_Item2: '無',
                        Light_Item3: '無',
                        Light_Item4: '無',
                        Light_Item5: '無',
                        Light_Item6: '無',
                        Light_Item7: '無',
                        Light_Item8: '無',

                        opaque_Start1: '0',
                        opaque_Start2: '0',
                        opaque_Start3: '0',
                        opaque_Run1: '0',
                        opaque_Run2: '0',
                        opaque_Run3: '0',
                        Tempeture_Start: '0',
                        Tempeture_Run: '0',

                        Mark_NO: '',
                        Mark_Deadline: ''
                    },

                    facTypeOtherText: '',
                    macTypeOtherText: '',
                    brandOtherText: '',

                    // 可搜尋下拉選單狀態管理
                    dropdowns: {
                        facType: { open: false, search: '' },
                        macType: { open: false, search: '' },
                        brand: { open: false, search: '' }
                    },

                    yearList: [],

                    // 照片上傳狀態
                    photoCategories: ['檢測結果', '檢測過程', '機具全貌', '機身編號、引擎編號', '核發標章', '其他佐證'],
                    photos: {}, // { cat: { Exists: bool, Url: string, Base64: string } }

                    // 選項常數庫
                    facTypeOptions: ['營建工地', '工廠', '預拌混凝土製造廠', '土石堆置場', '砂石場', '掩埋場', '港區', '煉鋼廠', '營建混合物處理廠', '瀝青廠', '社區大樓', '機具租賃業', '機具販售業'],
                    macBossOptions: [
                        { Val: '1.營造廠', Text: '1. 營造廠' },
                        { Val: '2.個人', Text: '2. 個人' },
                        { Val: '3.公私場所', Text: '3. 公私場所' },
                        { Val: '4.專業外包公司', Text: '4. 專業外包公司' },
                        { Val: '5.租賃業者', Text: '5. 租賃業者' },
                        { Val: '6.其他', Text: '6. 其他' }
                    ],
                    macTypeOptions: [
                        '01.挖土機', '02.推土機', '03.鏟裝機', '04.碎石機', '05.砸道機/壓路機',
                        '06.門式起重機', '07.輪式履帶式起重機', '08.跨載機', '09.高空作業車', '10.堆高機',
                        '11.發電機', '12.平路機', '13.平土機、整平機', '14.刮運機', '15.打椿機、起椿機',
                        '16.鏟雪機', '17.鬆土機、除草機', '18.肥散佈機、施肥機', '19.耕耘機', '20.割草機'
                    ],
                    brandOptions: [
                        '01.KOMATSU 小松', '02.HITACHI 日立', '03.KOBELCO神戸製鋼', '04.TOYOTA 國都豐田', '05.SUMITOMO住友商事',
                        '06.AIRMAN北越工業', '07.YANMAR洋馬', '08.TADANO', '09.DENYO', '10.LIEBHERR 利勃海爾',
                        '11.KATO 加藤製作所', '12.NIPPON SHARYO', '13.TCM 東洋載波', '14.SAKAI', '15.Caterpillar開拓重工',
                        '16.AICHI', '17.GENIE', '18.BOBCAT', '19.DEMAG 德馬格', '20.Mitsubishi 三菱重工',
                        '21.KUBOTA 久保田', '22.IHI 株式会社', '23.VOLVO 富豪', '24.HYUNDAI 現代', '25.SHINDAIWA 新大和',
                        '26.Tailift 台勵福', '27.AINSCOUGH', '28.DEUTZ 道依茨', '29.DOOSAN 斗山集團', '30.KITAKAMI 株式会社',
                        '31.BOMAG', '32.CASE 佳士', '33.HYSTER 海斯特', '34.MARATHON 馬拉松', '35.NEW HOLLAN新荷蘭',
                        '36.SEE ONE 西灣', '37.TAI HUEI 台輝', '38.XCMG 徐工集團', '39.NUL 長野工業', '40.MARATHON 馬拉松',
                        '41.DYNAPAC', '42.Ryoki 菱輝金型工業', '43.HAMM', '44.DATAKOM', '45.SANWAKIZAI三和機材',
                        '46.NORMET', '47.厦工機械', '48.Atlas Copco'
                    ],
                    exhaustSideOptions: ['機具上方', '機具側邊', '機具底盤下方', '其他'],
                    acceleratorOptions: ['傳統腳踏式油門', '手動旋鈕式油門', '拉桿型式油門', '其他'],
                    moveModeOptions: ['拖運', '可於路上行駛', '其他方式'],
                    oilFromOptions: ['中油', '台塑', '其他'],
                    maintenancePlaceOptions: ['原廠(即機具代理商授權之保養廠)', '自行保養', '一般保養廠', '其他'],
                    maintenanceTypes: ['更換機油', '更換空氣濾芯', '調整汽門間隙', '調校噴射泵浦', '調校噴油正時', '調校/更換噴油嘴'],
                    controlEquipOptions: ['濾煙器', '廢氣再循環系統(EGR)', '選擇性氧化還原系統(SCR，即尿素)'],
                    smokeOptions: ['無可見煙', '有可見煙(黑)', '有可見煙(白)', '有可見煙(藍)'],

                    checkItemsList: [
                        { key: 'Light_Item1', title: '循序漸進增加油門開度，以逐漸增加引擎轉速，觀察有無異音' },
                        { key: 'Light_Item2', title: '排氣管有無破洞、漏氣' },
                        { key: 'Light_Item3', title: '引擎運轉時溫度是否無偏高情形' },
                        { key: 'Light_Item4', title: '潤滑機油是否足夠 (本項應於暖車前檢查)' },
                        { key: 'Light_Item5', title: '引擎本體有無漏油現象' },
                        { key: 'Light_Item6', title: '循序漸進增加油門開度，以逐漸增加引擎轉速，觀察機具本體有無明顯搖晃' },
                        { key: 'Light_Item7', title: '機具外觀有無嚴重損壞' },
                        { key: 'Light_Item8', title: '引擎運轉時排氣管或引擎本體附近有無明顯排放白煙' }
                    ]
                };
            },
            computed: {
                filteredFacTypes() {
                    if (!this.dropdowns.facType.search.trim()) return this.facTypeOptions;
                    const k = this.dropdowns.facType.search.trim().toLowerCase();
                    return this.facTypeOptions.filter(t => t.toLowerCase().indexOf(k) >= 0);
                },
                filteredMacTypes() {
                    if (!this.dropdowns.macType.search.trim()) return this.macTypeOptions;
                    const k = this.dropdowns.macType.search.trim().toLowerCase();
                    return this.macTypeOptions.filter(t => t.toLowerCase().indexOf(k) >= 0);
                },
                filteredBrands() {
                    if (!this.dropdowns.brand.search.trim()) return this.brandOptions;
                    const k = this.dropdowns.brand.search.trim().toLowerCase();
                    return this.brandOptions.filter(b => b.toLowerCase().indexOf(k) >= 0);
                },
                isFacTypeOther() {
                    return this.mac.FAC_Type1 === '其他' || (this.mac.FAC_Type1 && !this.facTypeOptions.includes(this.mac.FAC_Type1));
                },
                isMacTypeOther() {
                    return this.mac.mac_Type === '21.其他' || (this.mac.mac_Type && !this.macTypeOptions.includes(this.mac.mac_Type));
                },
                isBrandOther() {
                    return this.mac.Brand === '49.其他' || (this.mac.Brand && !this.brandOptions.includes(this.mac.Brand));
                },
                needBossDetail() {
                    return ['2.個人', '4.專業外包公司', '5.租賃業者', '6.其他'].includes(this.mac.mac_boss1);
                },
                computedStartAvg() {
                    const vals = [parseFloat(this.mac.opaque_Start1), parseFloat(this.mac.opaque_Start2), parseFloat(this.mac.opaque_Start3)].filter(v => v > 0);
                    if (vals.length === 0) return '0.00000';
                    const sum = vals.reduce((a, b) => a + b, 0);
                    return (sum / vals.length).toFixed(5);
                },
                computedRunAvg() {
                    const vals = [parseFloat(this.mac.opaque_Run1), parseFloat(this.mac.opaque_Run2), parseFloat(this.mac.opaque_Run3)].filter(v => v > 0);
                    if (vals.length === 0) return '0.00000';
                    const sum = vals.reduce((a, b) => a + b, 0);
                    return (sum / vals.length).toFixed(5);
                }
            },
            mounted() {
                const params = new URLSearchParams(window.location.search);
                this.mode = (params.get('mode') || 'new').toLowerCase();
                this.facId = params.get('id') || '';
                this.macId = params.get('id2') || '';
                this.loadInitData();

                // 點擊空白處自動收起已展開的下拉選單
                this.onDocumentClick = (e) => {
                    if (!e.target.closest('.searchable-dropdown-wrapper')) {
                        this.closeAllDropdowns();
                    }
                };
                document.addEventListener('click', this.onDocumentClick);
            },
            beforeUnmount() {
                if (this.onDocumentClick) {
                    document.removeEventListener('click', this.onDocumentClick);
                }
            },
            methods: {
                toggleDropdown(name) {
                    const currentState = this.dropdowns[name].open;
                    this.closeAllDropdowns();
                    this.dropdowns[name].open = !currentState;
                    if (this.dropdowns[name].open) {
                        this.dropdowns[name].search = '';
                        this.$nextTick(() => {
                            const input = document.getElementById(name + 'SearchInput');
                            if (input) input.focus();
                        });
                    }
                },
                closeAllDropdowns() {
                    Object.keys(this.dropdowns).forEach(k => {
                        this.dropdowns[k].open = false;
                    });
                },
                selectDropdownItem(field, val, name) {
                    this.mac[field] = val;
                    this.dropdowns[name].open = false;
                    if (val.indexOf('其他') >= 0) {
                        this.$nextTick(() => {
                            const otherInput = document.getElementById(name + 'OtherInput');
                            if (otherInput) otherInput.focus();
                        });
                    }
                },
                loadInitData() {
                    axios.get('NewMac.aspx?action=getinit&id=' + encodeURIComponent(this.facId) + '&mode=' + encodeURIComponent(this.mode))
                        .then(res => {
                            if (res.data && res.data.Success) {
                                const d = res.data.Data;
                                this.facInfo = d.FacInfo;
                                this.yearList = d.YearList;
                                if (this.mode === 'new') {
                                    this.mac.Check_date = d.DefaultCheckDate;
                                    this.mac.Mark_Deadline = d.DefaultDeadline;
                                    this.mac.FAC_Type1 = this.facInfo.FAC_Type1;
                                    this.mac.Use_Area = this.facInfo.Use_Area;
                                    this.mac.Use_Area_Unit = this.facInfo.Use_Area_Unit || '平方公尺';
                                } else {
                                    this.loadMacData();
                                }
                            }
                        })
                        .catch(err => {
                            this.showAlert('載入初始化資料失敗：' + err.message, 'danger');
                        });
                },

                loadMacData() {
                    axios.get('NewMac.aspx?action=getmac&id=' + encodeURIComponent(this.facId) + '&id2=' + encodeURIComponent(this.macId))
                        .then(res => {
                            if (res.data && res.data.Success) {
                                const m = res.data.Data;
                                Object.keys(m).forEach(k => {
                                    if (m[k] !== null && m[k] !== undefined && this.mac[k] !== undefined) {
                                        this.mac[k] = m[k];
                                    }
                                });

                                // 特殊欄位拆解還原
                                if (m.Always_Here) {
                                    if (m.Always_Here.indexOf('常駐') >= 0) {
                                        this.mac.Always_Here_Mode = '常駐';
                                    } else {
                                        this.mac.Always_Here_Mode = '非常駐';
                                        this.mac.Always_Here_Other = m.Always_Here.replace('非常駐、不定期至其他場所', '');
                                    }
                                }

                                if (m.Control_equipment) {
                                    if (m.Control_equipment.startsWith('是')) {
                                        this.mac.Has_Control = '是';
                                    } else {
                                        this.mac.Has_Control = '否';
                                    }
                                }

                                // 讀取現有照片
                                this.photos = res.data.Photos || {};
                            } else {
                                this.showAlert(res.data ? res.data.Message : '查無機具資料', 'warning');
                            }
                        })
                        .catch(err => {
                            this.showAlert('載入機具資料失敗：' + err.message, 'danger');
                        });
                },

                // 快捷點檢全合格
                quickPassAllCheckItems() {
                    this.checkItemsList.forEach(item => {
                        this.mac[item.key] = '無';
                    });
                    this.showAlert('已將檢測前點檢程序 8 項全部設為「無異狀」合格！', 'success');
                },

                // 保養方式多選輔助
                isMaintTypeChecked(type) {
                    if (!this.mac.Maintenance_Type) return false;
                    return this.mac.Maintenance_Type.split('、').includes(type);
                },
                toggleMaintType(type) {
                    let arr = this.mac.Maintenance_Type ? this.mac.Maintenance_Type.split('、').filter(x => x.trim()) : [];
                    if (arr.includes(type)) {
                        arr = arr.filter(x => x !== type);
                    } else {
                        arr.push(type);
                    }
                    this.mac.Maintenance_Type = arr.join('、');
                },

                // 防制設備多選輔助
                isControlEquipChecked(eq) {
                    if (!this.mac.Control_equipment) return false;
                    return this.mac.Control_equipment.indexOf(eq) >= 0;
                },
                toggleControlEquip(eq) {
                    let clean = this.mac.Control_equipment.replace(/^是\{?/, '').replace(/\}$/, '');
                    let arr = clean ? clean.split('、').filter(x => x.trim()) : [];
                    if (arr.includes(eq)) {
                        arr = arr.filter(x => x !== eq);
                    } else {
                        arr.push(eq);
                    }
                    if (arr.length > 0) {
                        this.mac.Control_equipment = '是{' + arr.join('、') + '}';
                    } else {
                        this.mac.Control_equipment = '是';
                    }
                },

                // 照片上傳處理
                triggerUpload(cat) {
                    const el = document.getElementById('file_' + cat);
                    if (el) el.click();
                },
                onFileSelected(event, cat) {
                    const file = event.target.files[0];
                    if (!file) return;

                    const reader = new FileReader();
                    reader.onload = e => {
                        this.photos[cat] = {
                            Exists: true,
                            Base64: e.target.result,
                            Url: e.target.result
                        };
                    };
                    reader.readAsDataURL(file);
                },
                hasPhoto(cat) {
                    return this.photos[cat] && this.photos[cat].Exists && (this.photos[cat].Url || this.photos[cat].Base64);
                },
                getPhotoUrl(cat) {
                    if (!this.photos[cat]) return '';
                    return this.photos[cat].Base64 || this.photos[cat].Url;
                },
                removePhoto(cat) {
                    if (confirm('確定要刪除「' + cat + '」這張照片嗎？')) {
                        if (this.mode === 'edit' && this.photos[cat] && !this.photos[cat].Base64) {
                            axios.post('NewMac.aspx?action=deletephoto&id=' + encodeURIComponent(this.facId) + '&id2=' + encodeURIComponent(this.macId) + '&cat=' + encodeURIComponent(cat))
                                .then(res => {
                                    this.photos[cat] = { Exists: false, Url: '', Base64: '' };
                                });
                        } else {
                            this.photos[cat] = { Exists: false, Url: '', Base64: '' };
                        }
                    }
                },

                // 儲存資料
                submitData() {
                    if (!this.mac.Check_date) {
                        this.showAlert('請選擇調查日期！', 'warning');
                        return;
                    }
                    if (!this.mac.mac_Type) {
                        this.showAlert('請選擇施工機具種類型式！', 'warning');
                        return;
                    }
                    if (!this.mac.Brand) {
                        this.showAlert('請選擇機具廠牌！', 'warning');
                        return;
                    }

                    // 彙整其他填寫項
                    const payload = Object.assign({}, this.mac);
                    payload.Mode = this.mode;
                    payload.FAC_ID = this.facId;
                    payload.mac_ID = this.macId;

                    if (this.isFacTypeOther && this.facTypeOtherText) {
                        payload.FAC_Type1 = this.facTypeOtherText;
                    }
                    if (this.isMacTypeOther && this.macTypeOtherText) {
                        payload.mac_Type = this.macTypeOtherText;
                    }
                    if (this.isBrandOther && this.brandOtherText) {
                        payload.Brand = this.brandOtherText;
                    }

                    if (this.mac.Always_Here_Mode === '常駐') {
                        payload.Always_Here = '常駐本場所';
                    } else {
                        payload.Always_Here = '非常駐、不定期至其他場所' + (this.mac.Always_Here_Other || '');
                    }

                    if (this.mac.Has_Control === '否') {
                        payload.Control_equipment = '否，不清楚';
                    }

                    // 包含新選取的 Base64 照片
                    payload.Photos = {};
                    this.photoCategories.forEach(cat => {
                        if (this.photos[cat] && this.photos[cat].Base64) {
                            payload.Photos[cat] = {
                                Base64: this.photos[cat].Base64
                            };
                        }
                    });

                    this.isSaving = true;
                    this.showAlert('資料儲存處理中，請稍候...', 'info');

                    axios.post('NewMac.aspx?action=save', payload)
                        .then(res => {
                            this.isSaving = false;
                            if (res.data && res.data.Success) {
                                alert(res.data.Message || '儲存成功！');
                                window.location.href = 'macList.aspx?mode=reject';
                            } else {
                                this.showAlert(res.data ? res.data.Message : '儲存失敗', 'danger');
                            }
                        })
                        .catch(err => {
                            this.isSaving = false;
                            this.showAlert('連線錯誤或系統異常：' + err.message, 'danger');
                        });
                },

                showAlert(msg, type) {
                    this.alertMessage = msg;
                    this.alertType = type || 'info';
                    window.scrollTo({ top: 0, behavior: 'smooth' });
                }
            }
        }).mount('#macApp');
    </script>
</body>
</html>
