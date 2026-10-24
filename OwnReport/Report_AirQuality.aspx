<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Report_AirQuality.aspx.cs" Inherits="NTPC_FEC.OwnReport.Report_AirQuality" %>
<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定溢散源管理平台 - 空品不良應變回報</title>
    
    <link rel="shortcut icon" href="../favicon.ico" type="image/x-icon" />

    <!-- 本地化樣式依賴 (符合機房資安隔離規範) -->
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

        /* 置頂深青藍導覽列 (全載具自適應 RWD，嚴格杜絕中文字折行直排與按鈕溢出) */
        .top-navbar {
            background: linear-gradient(135deg, #0099e5 0%, #0284c7 100%);
            color: #ffffff;
            height: 56px;
            display: flex; align-items: center; justify-content: space-between;
            padding: 0 12px;
            box-shadow: 0 2px 10px rgba(0, 153, 229, 0.25);
            position: sticky; top: 0; z-index: 1020;
            gap: 8px;
        }
        .nav-btn {
            background: rgba(255, 255, 255, 0.18);
            border: none; color: #ffffff;
            font-size: 0.88rem; font-weight: 600; cursor: pointer;
            height: 34px; border-radius: 8px;
            display: inline-flex; align-items: center; justify-content: center;
            padding: 0 10px; gap: 4px;
            transition: all 0.2s;
            text-decoration: none;
            flex-shrink: 0;
            white-space: nowrap !important;
        }
        .nav-btn:hover { background-color: rgba(255, 255, 255, 0.32); color: #ffffff; text-decoration: none; }
        .top-navbar .brand-title {
            font-size: 1.05rem; font-weight: 700; margin: 0;
            display: flex; align-items: center; gap: 6px;
            min-width: 0;
            flex: 1 1 auto;
            white-space: nowrap !important;
            overflow: hidden;
        }
        .brand-text-truncate {
            white-space: nowrap !important;
            overflow: hidden;
            text-overflow: ellipsis;
            display: inline-block;
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
                overflow-y: auto;
                padding-right: 4px;
            }
        }

        /* 現場環境狀況開關 (Segmented Buttons) */
        .status-toggle-row {
            display: flex; align-items: center; justify-content: space-between;
            background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px;
            padding: 8px 12px; margin-bottom: 12px;
        }
        .segmented-group {
            display: inline-flex;
            background: #e2e8f0;
            padding: 3px;
            border-radius: 8px;
            gap: 2px;
        }
        .segment-btn {
            border: none; background: transparent;
            padding: 6px 14px;
            border-radius: 6px;
            font-size: 13px; font-weight: 600;
            color: #475569; cursor: pointer;
            min-height: 36px;
            display: inline-flex; align-items: center; justify-content: center;
            transition: all 0.15s ease;
        }
        .segment-btn.active-blue {
            background: var(--brand-blue);
            color: #ffffff;
            box-shadow: 0 1px 4px rgba(2, 132, 199, 0.35);
        }
        .segment-btn.active-green {
            background: #10b981;
            color: #ffffff;
            box-shadow: 0 1px 4px rgba(16, 185, 129, 0.35);
        }
        .segment-btn.active-red {
            background: #ef4444;
            color: #ffffff;
            box-shadow: 0 1px 4px rgba(239, 68, 68, 0.35);
        }
        .segment-btn.active-gray {
            background: #64748b;
            color: #ffffff;
            box-shadow: 0 1px 4px rgba(100, 116, 139, 0.35);
        }

        /* 快捷措施晶片標籤 (Subitem Pills) */
        .subitem-pill-group {
            display: flex;
            flex-wrap: wrap;
            gap: 8px;
            margin-top: 8px;
            margin-bottom: 10px;
        }
        .subitem-pill {
            border: 1px solid #cbd5e1;
            background: #f8fafc;
            color: #334155;
            padding: 6px 12px;
            border-radius: 20px;
            font-size: 12.5px;
            font-weight: 600;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            gap: 6px;
            transition: all 0.15s ease;
            user-select: none;
        }
        .subitem-pill:hover {
            border-color: var(--brand-blue);
            background: #f0f9ff;
            color: var(--brand-blue);
        }

        /* 地圖控制與收合 */
        #map {
            width: 100%;
            height: 320px;
            border-radius: 8px;
            z-index: 10;
            transition: height 0.3s ease;
        }
        #map.map-collapsed {
            height: 90px !important;
        }

        /* 地圖座標標記 (Marker Pin) */
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

        /* 污染物削減量輸入卡片 */
        .pollutant-card {
            background: #ffffff;
            border: 1px solid var(--border-color);
            border-radius: 10px;
            padding: 12px;
            transition: border-color 0.2s, box-shadow 0.2s;
        }
        .pollutant-card:focus-within {
            border-color: var(--brand-blue);
            box-shadow: 0 0 0 3px rgba(2, 132, 199, 0.15);
        }
        .pollutant-badge {
            font-size: 0.8rem;
            font-weight: 700;
            padding: 3px 8px;
            border-radius: 6px;
            background: #e0f2fe;
            color: #0369a1;
        }

        /* 規格晶片 Stat Chips */
        .stat-chips {
            display: flex; flex-wrap: wrap; gap: 8px; margin-top: 10px;
        }
        .stat-chip {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 6px;
            padding: 4px 10px;
            font-size: 12px;
            color: #475569;
            display: inline-flex; align-items: center; gap: 6px;
        }

        /* 手機底部懸浮列 */
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
        }

        /* 現代卡片標題列響應式 (解決小尺寸擠壓折字問題) */
        .card-modern-header-responsive {
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-wrap: wrap;
            gap: 10px;
            padding: 12px 16px;
            background: #ffffff;
            border-bottom: 1px solid var(--border-color);
        }
        .header-actions-row {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            flex-shrink: 0;
        }
        .header-actions-row .btn {
            white-space: nowrap !important;
            font-size: 13px;
            font-weight: 600;
            min-height: 36px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            padding: 6px 14px;
        }
        @media screen and (max-width: 576px) {
            .card-modern-header-responsive {
                flex-direction: column;
                align-items: flex-start;
                padding: 12px 14px;
            }
            .card-modern-header-responsive .card-modern-title {
                width: 100%;
                font-size: 0.98rem;
                line-height: 1.45;
                word-break: break-word;
            }
            .card-modern-header-responsive .header-actions-row {
                width: 100%;
                display: flex;
                justify-content: flex-end;
                margin-top: 2px;
            }
        }

        /* 執行時間起訖 RWD 排版 (徹底根治小尺寸截字與被藏問題) */
        .time-picker-wrapper {
            display: flex;
            align-items: center;
            flex-wrap: wrap;
            gap: 10px;
            width: 100%;
        }
        .time-select-item {
            flex: 1 1 180px;
            max-width: 230px;
            min-width: 135px;
        }
        .time-select-item select {
            width: 100%;
            min-height: 42px;
            font-size: 14px;
            border-radius: 8px;
            border: 1px solid #cbd5e1;
            padding: 6px 12px;
        }
        .time-select-item select:focus {
            border-color: var(--brand-blue);
            box-shadow: 0 0 0 3px rgba(2, 132, 199, 0.15);
        }
        .time-separator-text {
            font-weight: 700;
            color: #64748b;
            padding: 0 4px;
            white-space: nowrap;
        }
        .time-hours-chip {
            white-space: nowrap;
        }
        .time-hours-chip .badge {
            font-size: 13px;
            font-weight: 600;
            padding: 8px 12px;
            border-radius: 8px;
            display: inline-flex;
            align-items: center;
            gap: 6px;
        }

        @media screen and (max-width: 767px) {
            .time-select-item {
                max-width: 100%;
            }
        }
        @media screen and (max-width: 576px) {
            .time-picker-wrapper {
                display: flex;
                flex-wrap: wrap;
                align-items: center;
                gap: 8px;
            }
            .time-select-item {
                flex: 1 1 calc(50% - 20px);
                min-width: 125px;
            }
            .time-hours-chip {
                width: 100%;
                margin-top: 4px;
            }
            .time-hours-chip .badge {
                width: 100%;
                justify-content: center;
                display: flex;
            }
        }
        @media screen and (max-width: 360px) {
            .time-select-item {
                flex: 1 1 100%;
                width: 100%;
            }
            .time-separator-text {
                width: 100%;
                text-align: center;
                margin: 2px 0;
            }
        }

        /* 列印樣式 */
        @media print {
            .no-print { display: none !important; }
            body { background: #ffffff !important; color: #000000 !important; }
            .container-fluid-custom { max-width: 100% !important; padding: 0 !important; }
            .card-modern { border: 1px solid #000000 !important; box-shadow: none !important; margin-bottom: 12px !important; break-inside: avoid; }
            .card-modern-header { background: #f0f0f0 !important; border-bottom: 1px solid #000000 !important; }
            .print-table { width: 100%; border-collapse: collapse; margin-top: 10px; }
            .print-table th, .print-table td { border: 1px solid #000; padding: 6px 8px; font-size: 12px; }
            .print-only-header { display: block !important; text-align: center; margin-bottom: 20px; }
        }
        .print-only-header { display: none; }
    </style>
</head>
<body>
    <form id="form1" runat="server">
    <div id="app" v-cloak>
        
        <!-- 1. 置頂深青藍漸層導覽列 (自適應 RWD 最佳化) -->
        <header class="top-navbar no-print">
            <div class="brand-title">
                <a href="AirQuality_List.aspx" class="nav-btn mr-1 mr-sm-2" title="返回清單">
                    <i class="fas fa-arrow-left"></i>
                    <span class="d-none d-sm-inline">返回清單</span>
                </a>
                <i class="fas fa-wind text-white mr-1 d-none d-sm-inline-block"></i>

                <!-- 標題：小尺寸手機簡潔展示，大尺寸完整顯示，嚴格禁止垂直折行直排 -->
                <span class="brand-text-truncate font-weight-bold">
                    <span class="d-none d-md-inline">公私場所空品不良應變回報單</span>
                    <span class="d-inline d-md-none">空品應變回報</span>
                </span>

                <!-- 管制編號 Badge：維持緊湊單行 -->
                <span v-if="reportData.C_NO" class="badge badge-light text-dark font-weight-bold ml-1 ml-sm-2" style="font-size: 0.8rem; white-space: nowrap;">
                    {{ reportData.C_NO }}
                </span>

                <!-- 案件狀態 Badge：小螢幕極簡顯示避免撐破邊界 -->
                <span class="badge ml-1 d-none d-sm-inline-block" :class="mode === 'edit' ? 'badge-warning text-dark' : 'badge-success text-white'" style="font-size: 0.8rem; white-space: nowrap;">
                    {{ mode === 'edit' ? '編輯案件 #' + reportData.pIndex : '新增通報' }}
                </span>
                <span class="badge ml-1 d-inline-block d-sm-none" :class="mode === 'edit' ? 'badge-warning text-dark' : 'badge-success text-white'" style="font-size: 0.75rem; white-space: nowrap;">
                    {{ mode === 'edit' ? '#' + reportData.pIndex : '新增' }}
                </span>
            </div>

            <div class="d-flex align-items-center flex-shrink-0">
                <!-- 列印按鈕：中大螢幕才顯示 (手機螢幕原生通常無印表機驅動，留空間給關鍵元素) -->
                <button type="button" class="nav-btn bg-white text-dark shadow-sm mr-2 d-none d-md-inline-flex" v-on:click="printReport">
                    <i class="fas fa-print"></i>
                    <span>列印案件</span>
                </button>

                <!-- 頂部確定送出按鈕：電腦端完整文字，手機小螢幕緊湊圖示按鈕 (亦可透過底部常駐浮動條送出) -->
                <button type="button" class="btn btn-primary btn-sm font-weight-bold shadow-sm px-2 px-sm-3" v-on:click="submitForm" :disabled="isSaving" style="height: 34px; display: inline-flex; align-items: center; justify-content: center; white-space: nowrap;">
                    <i v-if="isSaving" class="fas fa-spinner fa-spin mr-1"></i>
                    <i v-else class="fas fa-save mr-1"></i>
                    <span class="d-none d-sm-inline">{{ isSaving ? '儲存中...' : '確定送出' }}</span>
                    <span class="d-inline d-sm-none">{{ isSaving ? '存' : '送出' }}</span>
                </button>
            </div>
        </header>

        <!-- 2. 列印專用報表頁首 (螢幕隱藏，列印時顯現) -->
        <div class="print-only-header">
            <h3 style="margin: 0; font-weight: bold;">新北市政府環境保護局</h3>
            <h4 style="margin: 5px 0 0 0;">公私場所空品不良應變落實自主回報單</h4>
            <div style="text-align: right; font-size: 12px; margin-top: 5px;">
                列印日期：{{ todayDateString }} | 管制編號：{{ reportData.C_NO || '-' }}
            </div>
        </div>

        <!-- 3. 主作業容器 -->
        <main class="container-fluid-custom">
            
            <!-- 訊息提示橫條 -->
            <div v-if="alertMessage" class="alert alert-dismissible fade show shadow-sm" :class="'alert-' + alertType" role="alert">
                <i :class="alertType === 'success' ? 'fas fa-check-circle mr-2' : 'fas fa-exclamation-triangle mr-2'"></i>
                {{ alertMessage }}
                <button type="button" class="close" v-on:click="alertMessage = ''">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>

            <!-- 主佈局格網 -->
            <div class="row">
                
                <!-- 左欄 (40% 寬度，Desktop Sticky 浮動) -->
                <div class="col-12 col-xl-5">
                    <div class="sticky-sidebar">
                        
                        <!-- 卡片 1: 工廠基本資訊卡片 -->
                        <div class="card-modern">
                            <div class="card-modern-header-responsive">
                                <h3 class="card-modern-title">
                                    <i class="fas fa-industry text-primary"></i>
                                    <span>管制公私場所基本資料</span>
                                </h3>
                                <div class="header-actions-row">
                                    <span class="badge badge-info">
                                    {{ facInfo.TownName || '新北市' }}
                                </span>
                            </div>
                            </div>
                            <div class="card-modern-body">
                                
                                <!-- 若為主管或多工廠切換 -->
                                <div v-if="isManager && facList.length > 0" class="form-group mb-3 no-print">
                                    <label class="text-muted small font-weight-bold mb-1">
                                        <i class="fas fa-exchange-alt mr-1"></i> 切換申報公私場所：
                                    </label>
                                    <select class="form-control form-control-sm" v-model="selectedFacId" v-on:change="onFacChange">
                                        <option v-for="f in facList" :key="f.FacId" :value="f.FacId">
                                            {{ f.CNo ? '[' + f.CNo + '] ' : '' }}{{ f.FacName }} ({{ f.TownName }})
                                        </option>
                                    </select>
                                </div>

                                <div class="row mb-2">
                                    <div class="col-sm-4 text-muted small font-weight-bold">公私場所名稱：</div>
                                    <div class="col-sm-8 font-weight-bold text-dark">{{ facInfo.FacName || '-' }}</div>
                                </div>
                                <div class="row mb-2">
                                    <div class="col-sm-4 text-muted small font-weight-bold">管制編號：</div>
                                    <div class="col-sm-8 font-weight-bold text-primary">{{ facInfo.CNo || '-' }}</div>
                                </div>
                                <div class="row mb-2">
                                    <div class="col-sm-4 text-muted small font-weight-bold">行政區別：</div>
                                    <div class="col-sm-8 text-dark">{{ facInfo.TownName || '-' }}</div>
                                </div>
                                <div class="row mb-2">
                                    <div class="col-sm-4 text-muted small font-weight-bold">場所地址：</div>
                                    <div class="col-sm-8 text-secondary small">{{ facInfo.Addr || '無地址資料' }}</div>
                                </div>

                                <!-- 規格晶片 -->
                                <div class="stat-chips">
                                    <div class="stat-chip">
                                        <i class="fas fa-calendar-alt text-primary"></i>
                                        <span>應變日：{{ reportData.OverDate || '未指定' }}</span>
                                    </div>
                                    <div class="stat-chip">
                                        <i class="fas fa-bell text-warning"></i>
                                        <span>通知：{{ reportData.ContentType || '電話' }}</span>
                                    </div>
                                    <div class="stat-chip">
                                        <i :class="reportData.Status === '操作中' ? 'fas fa-cogs text-success' : 'fas fa-pause-circle text-muted'"></i>
                                        <span>狀況：{{ reportData.Status || '操作中' }}</span>
                                    </div>
                                    <div class="stat-chip">
                                        <i :class="reportData.Less === '是' ? 'fas fa-leaf text-success' : 'fas fa-times-circle text-danger'"></i>
                                        <span>減排：{{ reportData.Less || '是' }}</span>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- 卡片 2: 廠區智慧地圖 -->
                        <div class="card-modern no-print">
                            <div class="card-modern-header-responsive">
                                <h3 class="card-modern-title">
                                    <i class="fas fa-map-marked-alt text-info"></i>
                                    <span>現場廠區地圖</span>
                                </h3>
                                <div class="header-actions-row">
                                    <button type="button" class="btn btn-xs btn-outline-secondary py-1 px-2 mr-1" v-on:click="locateCurrentPosition" title="GPS 定位當前位置">
                                        <i class="fas fa-crosshairs text-primary"></i>
                                        <span class="d-none d-sm-inline ml-1">GPS</span>
                                    </button>
                                    <button type="button" class="btn btn-xs btn-outline-secondary py-1 px-2 mr-1" v-on:click="resetMapView" title="重設地圖全景">
                                        <i class="fas fa-expand-arrows-alt"></i>
                                        <span class="d-none d-sm-inline ml-1">全景</span>
                                    </button>
                                    <button v-if="facInfo.Lat && facInfo.Lng" type="button" class="btn btn-xs btn-outline-success py-1 px-2 mr-1" v-on:click="openGoogleMaps" title="開啟 Google Maps 導航">
                                        <i class="fas fa-location-arrow"></i>
                                        <span class="d-none d-sm-inline ml-1">導航</span>
                                    </button>
                                    <button type="button" class="btn btn-xs btn-outline-dark py-1 px-2" v-on:click="isMapCollapsed = !isMapCollapsed" :title="isMapCollapsed ? '展開地圖' : '收合地圖'">
                                        <i :class="isMapCollapsed ? 'fas fa-chevron-down' : 'fas fa-chevron-up'"></i>
                                    </button>
                                </div>
                            </div>
                            <div class="card-modern-body p-2">
                                <div id="map" :class="{ 'map-collapsed': isMapCollapsed }"></div>
                                <div class="mt-2 d-flex justify-content-between align-items-center px-1">
                                    <small class="text-muted">
                                        <i class="fas fa-map-pin text-primary mr-1"></i>
                                        座標：{{ facInfo.Lat ? facInfo.Lat + ', ' + facInfo.Lng : '尚無地理座標' }}
                                    </small>
                                    <span v-if="facInfo.Lat && facInfo.Lng" class="badge badge-light border text-success">
                                        <i class="fas fa-check-circle mr-1"></i>座標已定位
                                    </span>
                            </div>
                                </div>
                            </div>
                        </div>

                        <!-- 卡片 3: 填報指引與通報須知 -->
                        <div class="card-modern no-print">
                            <div class="card-modern-header-responsive">
                                <h3 class="card-modern-title">
                                    <i class="fas fa-info-circle text-secondary"></i>
                                    <span>空品應變自主通報說明</span>
                                </h3>
                            </div>
                            <div class="card-modern-body small text-muted">
                                <ul class="pl-3 mb-0" style="line-height: 1.7;">
                                    <li><strong>依據：</strong>新北市公私場所固定污染源空氣品質不良應變防制計畫自主管理落實作業。</li>
                                    <li><strong>通報時效：</strong>接獲環保局通知後，應於當日落實減排措施並完成線上填報回傳。</li>
                                    <li><strong>具體措施：</strong>減排措施為「是」時，請詳述實際採取作為（如減少吹灰、提升防制設備效率等）。</li>
                                    <li><strong>削減量計算：</strong>請填寫應變執行期間各污染物之預估或量測削減公斤數，未產生削減請填 0。</li>
                                </ul>
                            </div>
                        </div>

                    </div>
                </div>

                <!-- 右欄 (60% 寬度，主表單填報作業區) -->
                <div class="col-12 col-xl-7">
                    
                    <!-- 卡片 A: 空品不良應變通知與操作狀況 -->
                    <div class="card-modern">
                        <div class="card-modern-header-responsive">
                            <h3 class="card-modern-title">
                                <i class="fas fa-calendar-check text-primary"></i>
                                <span>一、空品預警與今日操作狀況</span>
                            </h3>
                            <div class="header-actions-row">
                                <span class="badge badge-pill badge-primary">必填</span>
                            </div>
                        </div>
                        <div class="card-modern-body">
                            
                            <!-- 應變日期 -->
                            <div class="form-group row align-items-center mb-3">
                                <label class="col-md-3 col-form-label font-weight-bold text-dark">
                                    <i class="fas fa-calendar-alt text-primary mr-1"></i> 應變通報日期：
                                </label>
                                <div class="col-md-9">
                                    <div class="input-group">
                                        <select class="form-control font-weight-bold" v-model="reportData.OverDate">
                                            <option v-for="d in dateList" :key="d" :value="d">
                                                {{ d }} {{ d === dateList[0] ? ' (最新通報日)' : '' }}
                                            </option>
                                        </select>
                                        <div class="input-group-append no-print">
                                            <button type="button" class="btn btn-outline-secondary" v-on:click="setTodayOverDate" title="切換至今日">
                                                今天
                                            </button>
                                        </div>
                                    </div>
                                    <small class="form-text text-muted">
                                        系統自動同步新北市空氣品質不良預警通報紀錄。
                                    </small>
                                </div>
                            </div>

                            <!-- 環保局通知方式 -->
                            <div class="form-group row align-items-center mb-3">
                                <label class="col-md-3 col-form-label font-weight-bold text-dark">
                                    <i class="fas fa-bell text-warning mr-1"></i> 環保局通知方式：
                                </label>
                                <div class="col-md-9">
                                    <div class="segmented-group w-100">
                                        <button v-for="cType in ['電話', '傳真', '通訊軟體', '電子郵件']" :key="cType" 
                                                type="button" class="segment-btn flex-fill" 
                                                :class="{ 'active-blue': reportData.ContentType === cType }"
                                                v-on:click="reportData.ContentType = cType">
                                            {{ cType }}
                                        </button>
                                    </div>
                                </div>
                            </div>

                            <!-- 今日操作狀況 -->
                            <div class="form-group row align-items-center mb-1">
                                <label class="col-md-3 col-form-label font-weight-bold text-dark">
                                    <i class="fas fa-cogs text-info mr-1"></i> 今日操作狀況：
                                </label>
                                <div class="col-md-9">
                                    <div class="segmented-group w-100">
                                        <button type="button" class="segment-btn flex-fill" 
                                                :class="{ 'active-green': reportData.Status === '操作中' }"
                                                v-on:click="reportData.Status = '操作中'">
                                            <i class="fas fa-play-circle mr-1"></i> 操作中
                                        </button>
                                        <button type="button" class="segment-btn flex-fill" 
                                                :class="{ 'active-gray': reportData.Status === '未操作' }"
                                                v-on:click="reportData.Status = '未操作'">
                                            <i class="fas fa-stop-circle mr-1"></i> 未操作
                                        </button>
                                    </div>
                                </div>
                            </div>

                        </div>
                    </div>

                    <!-- 卡片 B: 減排措施配合與具體作為 -->
                    <div class="card-modern">
                        <div class="card-modern-header-responsive">
                            <h3 class="card-modern-title">
                                <i class="fas fa-leaf text-success"></i>
                                <span>二、配合減排措施與具體執行作為</span>
                            </h3>
                            <div class="header-actions-row">
                                <span class="badge badge-pill" :class="reportData.Less === '是' ? 'badge-success' : 'badge-danger'">
                                {{ reportData.Less === '是' ? '已配合' : '未配合' }}
                            </span>
                            </div>
                        </div>
                        <div class="card-modern-body">
                            
                            <!-- 配合執行減排措施 -->
                            <div class="form-group row align-items-center mb-3">
                                <label class="col-md-3 col-form-label font-weight-bold text-dark">
                                    配合執行減排措施：
                                </label>
                                <div class="col-md-9">
                                    <div class="segmented-group w-100">
                                        <button type="button" class="segment-btn flex-fill" 
                                                :class="{ 'active-green': reportData.Less === '是' }"
                                                v-on:click="reportData.Less = '是'">
                                            <i class="fas fa-check-circle mr-1"></i> 是 (配合執行)
                                        </button>
                                        <button type="button" class="segment-btn flex-fill" 
                                                :class="{ 'active-red': reportData.Less === '否' }"
                                                v-on:click="reportData.Less = '否'">
                                            <i class="fas fa-times-circle mr-1"></i> 否 (未配合)
                                        </button>
                                        <button type="button" class="segment-btn flex-fill" 
                                                :class="{ 'active-gray': reportData.Less === '-' }"
                                                v-on:click="reportData.Less = '-'">
                                            - (不適用)
                                        </button>
                                    </div>
                                </div>
                            </div>

                            <!-- 具體減排措施 (若為 是 展開並必填) -->
                            <div v-if="reportData.Less === '是'" class="mb-3">
                                <label class="font-weight-bold text-dark d-flex justify-content-between align-items-center mb-1">
                                    <span>
                                        <i class="fas fa-clipboard-check text-success mr-1"></i>
                                        具體減排措施說明 <span class="text-danger">*</span>
                                    </span>
                            </div>
                                    <span class="badge badge-light text-muted font-weight-normal">若前項為「是」本項為必填</span>
                                </label>

                                <!-- 快捷點選標籤 -->
                                <div class="no-print">
                                    <small class="text-muted d-block mb-1">
                                        <i class="fas fa-magic text-primary mr-1"></i> 點選常用減排措施快速加入：
                                    </small>
                                    <div class="subitem-pill-group">
                                        <button v-for="tag in commonMeasures" :key="tag" type="button" class="subitem-pill" v-on:click="appendMeasureTag(tag)">
                                            <i class="fas fa-plus-circle text-success"></i> {{ tag }}
                                        </button>
                                    </div>
                                </div>

                                <textarea class="form-control" rows="4" v-model="reportData.LessMe" 
                                          placeholder="請輸入具體減排措施，例如：減少或停止吹灰、配合減產降載、使用清潔燃料、防制設備效率提升、廠區道路加強洗掃灑水逸散抑制等..."></textarea>
                            </div>

                            <!-- 未配合原因說明 (若為 否 展開並必填) -->
                            <div v-if="reportData.Less === '否'" class="mb-3">
                                <label class="font-weight-bold text-danger d-block mb-1">
                                    <i class="fas fa-exclamation-circle mr-1"></i> 未配合原因說明 <span class="text-danger">*</span>
                                </label>
                                <textarea class="form-control border-danger" rows="3" v-model="reportData.NoReason" 
                                          placeholder="請詳實敘明未配合執行減排措施之原因（如停工歲修、製程特性限制、緊急供電等）..."></textarea>
                            </div>

                        </div>
                    </div>

                    <!-- 卡片 C: 執行時間與污染物削減量 -->
                    <div class="card-modern">
                        <div class="card-modern-header-responsive">
                            <h3 class="card-modern-title">
                                <i class="fas fa-chart-line text-info"></i>
                                <span>三、執行時段與污染物削減量 (公斤)</span>
                            </h3>
                            <div class="header-actions-row no-print">
                                <button type="button" class="btn btn-outline-primary" v-on:click="fillAllZeros" title="一鍵全數填入0公斤">
                                    <i class="fas fa-bolt mr-1"></i>一鍵全填 0
                                </button>
                                <button type="button" class="btn btn-outline-secondary" v-on:click="clearAllQuantities" title="清空削減量數值">
                                    <i class="fas fa-eraser mr-1"></i>清空
                                </button>
                            </div>
                        </div>
                        <div class="card-modern-body">
                            
                            <!-- 執行時間起訖 -->
                            <div class="form-group row align-items-center mb-4">
                                <label class="col-md-3 col-form-label font-weight-bold text-dark">
                                    <i class="fas fa-clock text-primary mr-1"></i> 減排執行時間：
                                </label>
                                <div class="col-md-9">
                                    <div class="time-picker-wrapper">
                                        <div class="time-select-item">
                                            <select class="form-control font-weight-bold" v-model="reportData.RunTimeStart" aria-label="執行起始時間">
                                            <option v-for="t in timeOptions" :key="t.val" :value="t.val">
                                                {{ t.text }}
                                            </option>
                                        </select>
                                        </div>
                                        <span class="time-separator-text">至</span>
                                        <div class="time-select-item">
                                            <select class="form-control font-weight-bold" v-model="reportData.RunTimeEnd" aria-label="執行結束時間">
                                            <option v-for="t in timeOptions" :key="t.val" :value="t.val">
                                                {{ t.text }}
                                            </option>
                                        </select>
                                        </div>
                                        <div class="time-hours-chip">
                                            <span class="badge badge-light border text-dark shadow-xs">
                                            <i class="fas fa-hourglass-half text-warning mr-1"></i>
                                            時數：{{ calculatedHours }} 小時
                                            </span>
                                        </div>

                                    </div>
                                </div>
                            </div>

                            <!-- 削減量網格矩陣 (TSP, PM10, PM2.5, SOx, NOx, VOCs) -->
                            <div class="row">
                                
                                <!-- TSP -->
                                <div class="col-6 col-md-4 mb-3">
                                    <div class="pollutant-card">
                                        <div class="d-flex justify-content-between align-items-center mb-2">
                                            <span class="pollutant-badge">TSP</span>
                                            <small class="text-muted">總懸浮微粒</small>
                                        </div>
                                        <div class="input-group">
                                            <input type="number" step="0.01" class="form-control font-weight-bold text-right" 
                                                   v-model="reportData.TSP" placeholder="0" />
                                            <div class="input-group-append">
                                                <span class="input-group-text">kg</span>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <!-- PM10 -->
                                <div class="col-6 col-md-4 mb-3">
                                    <div class="pollutant-card">
                                        <div class="d-flex justify-content-between align-items-center mb-2">
                                            <span class="pollutant-badge">PM10</span>
                                            <small class="text-muted">懸浮微粒</small>
                                        </div>
                                        <div class="input-group">
                                            <input type="number" step="0.01" class="form-control font-weight-bold text-right" 
                                                   v-model="reportData.PM10" placeholder="0" />
                                            <div class="input-group-append">
                                                <span class="input-group-text">kg</span>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <!-- PM2.5 -->
                                <div class="col-6 col-md-4 mb-3">
                                    <div class="pollutant-card">
                                        <div class="d-flex justify-content-between align-items-center mb-2">
                                            <span class="pollutant-badge">PM2.5</span>
                                            <small class="text-muted">細懸浮微粒</small>
                                        </div>
                                        <div class="input-group">
                                            <input type="number" step="0.01" class="form-control font-weight-bold text-right" 
                                                   v-model="reportData.PM25" placeholder="0" />
                                            <div class="input-group-append">
                                                <span class="input-group-text">kg</span>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <!-- SOx -->
                                <div class="col-6 col-md-4 mb-3">
                                    <div class="pollutant-card">
                                        <div class="d-flex justify-content-between align-items-center mb-2">
                                            <span class="pollutant-badge">SOx</span>
                                            <small class="text-muted">硫氧化物</small>
                                        </div>
                                        <div class="input-group">
                                            <input type="number" step="0.01" class="form-control font-weight-bold text-right" 
                                                   v-model="reportData.SOx" placeholder="0" />
                                            <div class="input-group-append">
                                                <span class="input-group-text">kg</span>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <!-- NOx -->
                                <div class="col-6 col-md-4 mb-3">
                                    <div class="pollutant-card">
                                        <div class="d-flex justify-content-between align-items-center mb-2">
                                            <span class="pollutant-badge">NOx</span>
                                            <small class="text-muted">氮氧化物</small>
                                        </div>
                                        <div class="input-group">
                                            <input type="number" step="0.01" class="form-control font-weight-bold text-right" 
                                                   v-model="reportData.NOx" placeholder="0" />
                                            <div class="input-group-append">
                                                <span class="input-group-text">kg</span>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <!-- VOCs -->
                                <div class="col-6 col-md-4 mb-3">
                                    <div class="pollutant-card">
                                        <div class="d-flex justify-content-between align-items-center mb-2">
                                            <span class="pollutant-badge">VOCs</span>
                                            <small class="text-muted">揮發性有機物</small>
                                        </div>
                                        <div class="input-group">
                                            <input type="number" step="0.01" class="form-control font-weight-bold text-right" 
                                                   v-model="reportData.VOCs" placeholder="0" />
                                            <div class="input-group-append">
                                                <span class="input-group-text">kg</span>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                            </div>

                            <small class="form-text text-muted">
                                <i class="fas fa-info-circle mr-1"></i> 若應變期間未產生特定污染物之削減量，請填寫 0 或留空。
                            </small>

                        </div>
                    </div>

                    <!-- 填報人員資訊與動作列 (電腦端底欄) -->
                    <div class="card-modern no-print">
                        <div class="card-modern-body d-flex flex-wrap align-items-center justify-content-between">
                            <div class="text-muted small">
                                <div><i class="fas fa-user-edit mr-1"></i> 填報人員帳號：<strong>{{ reportData.InputUser || currentUser }}</strong></div>
                                <div v-if="reportData.EditDate"><i class="fas fa-history mr-1"></i> 最後更新時間：{{ reportData.EditDate }}</div>
                            </div>
                            <div class="d-flex align-items-center gap-2 mt-2 mt-sm-0">
                                <a href="AirQuality_List.aspx" class="btn btn-outline-secondary font-weight-bold mr-2">
                                    取消
                                </a>
                                <button type="button" class="btn btn-primary font-weight-bold px-4 shadow-sm" 
                                        v-on:click="submitForm" :disabled="isSaving">
                                    <i v-if="isSaving" class="fas fa-spinner fa-spin mr-1"></i>
                                    <i v-else class="fas fa-check-circle mr-1"></i>
                                    <span>{{ isSaving ? '儲存中...' : '確定儲存回報' }}</span>
                                </button>
                            </div>
                        </div>
                    </div>

                </div>

            </div>

        </main>

        <!-- 4. 手機行動端常駐浮動底欄 (Sticky Bottom Bar) -->
        <footer class="mobile-bottom-bar d-xl-none no-print">
            <a href="AirQuality_List.aspx" class="btn btn-outline-secondary">
                <i class="fas fa-times mr-1"></i> 取消
            </a>
            <button type="button" class="btn btn-primary" v-on:click="submitForm" :disabled="isSaving">
                <i v-if="isSaving" class="fas fa-spinner fa-spin mr-1"></i>
                <i v-else class="fas fa-save mr-1"></i>
                <span>{{ isSaving ? '儲存中...' : '儲存回報' }}</span>
            </button>
        </footer>

    </div>
    </form>

    <!-- 本地化 JS 依賴 (嚴禁外部 CDN) -->
    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>
    <script src="../Scripts/leaflet/leaflet.js"></script>

    <script>
        const { createApp, markRaw } = Vue;

        createApp({
            data() {
                return {
                    mode: 'new',
                    isManager: false,
                    canEdit: true,
                    currentUser: '',
                    selectedFacId: '',
                    facInfo: {},
                    dateList: [],
                    facList: [],
                    reportData: {
                        pIndex: 0,
                        FAC_ID: '',
                        County: '',
                        C_NO: '',
                        CNAM: '',
                        OverDate: '',
                        ContentType: '電話',
                        Status: '操作中',
                        Less: '是',
                        LessMe: '',
                        NoReason: '',
                        RunTimeStart: '08:00',
                        RunTimeEnd: '17:00',
                        TSP: '0',
                        PM10: '0',
                        PM25: '0',
                        SOx: '0',
                        NOx: '0',
                        VOCs: '0',
                        InputUser: '',
                        CreateDate: '',
                        EditDate: ''
                    },
                    commonMeasures: [
                        '減少或停止吹灰',
                        '配合降載減產',
                        '使用低硫清潔燃料',
                        '防制設備提升運轉效率',
                        '廠區周邊加強洗掃灑水',
                        '落實原物料覆蓋防止揚塵'
                    ],
                    timeOptions: [],
                    isMapCollapsed: false,
                    isSaving: false,
                    alertMessage: '',
                    alertType: 'success'
                };
            },
            computed: {
                todayDateString() {
                    const d = new Date();
                    return d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0');
                },
                calculatedHours() {
                    if (!this.reportData.RunTimeStart || !this.reportData.RunTimeEnd) return 0;
                    const s = this.reportData.RunTimeStart.split(':').map(Number);
                    const e = this.reportData.RunTimeEnd.split(':').map(Number);
                    const startMin = s[0] * 60 + (s[1] || 0);
                    const endMin = e[0] * 60 + (e[1] || 0);
                    const diff = endMin - startMin;
                    if (diff <= 0) return 0;
                    return (diff / 60).toFixed(1);
                }
            },
            created() {
                this.initTimeOptions();
            },
            mounted() {
                this.loadInitData();
            },
            methods: {
                initTimeOptions() {
                    const opts = [];
                    for (let h = 0; h < 24; h++) {
                        for (let m = 0; m < 60; m += 30) {
                            const hh = String(h).padStart(2, '0');
                            const mm = String(m).padStart(2, '0');
                            const val = hh + ':' + mm;
                            const ampm = h >= 12 ? '下午' : '上午';
                            const displayH = h % 12 === 0 ? 12 : h % 12;
                            opts.push({ val: val, text: val + ' (' + ampm + displayH + ':' + mm + ')' });
                        }
                    }
                    this.timeOptions = opts;
                },

                loadInitData() {
                    const urlParams = new URLSearchParams(window.location.search);
                    const mode = urlParams.get('mode') || 'new';
                    const fac = urlParams.get('fac') || '';
                    const id = urlParams.get('id') || urlParams.get('index') || '';

                    axios.get('Report_AirQuality.aspx', {
                        params: {
                            action: 'getinitdata',
                            mode: mode,
                            fac: fac,
                            id: id,
                            t: new Date().getTime()
                        }
                    })
                    .then(res => {
                        if (res.data && res.data.Success) {
                            const d = res.data.Data;
                            this.mode = d.Mode;
                            this.isManager = d.IsManager;
                            this.canEdit = d.CanEdit;
                            this.currentUser = d.CurrentUser;
                            this.facInfo = d.FacInfo || {};
                            this.dateList = d.DateList || [];
                            this.facList = d.FacList || [];
                            this.reportData = d.ReportData || this.reportData;
                            this.selectedFacId = this.facInfo.FacId || '';

                            this.$nextTick(() => {
                                this.initLeafletMap();
                            });
                        } else {
                            this.showAlert('載入資料失敗：' + (res.data ? res.data.Message : '連線異常'), 'danger');
                        }
                    })
                    .catch(err => {
                        this.showAlert('伺服器連線失敗：' + err.message, 'danger');
                    });
                },

                onFacChange() {
                    if (!this.selectedFacId) return;
                    window.location.href = 'Report_AirQuality.aspx?mode=' + this.mode + '&fac=' + encodeURIComponent(this.selectedFacId);
                },

                setTodayOverDate() {
                    this.reportData.OverDate = this.todayDateString;
                    if (!this.dateList.includes(this.todayDateString)) {
                        this.dateList.unshift(this.todayDateString);
                    }
                },

                appendMeasureTag(tag) {
                    if (!this.reportData.LessMe) {
                        this.reportData.LessMe = tag;
                    } else if (!this.reportData.LessMe.includes(tag)) {
                        this.reportData.LessMe += '、' + tag;
                    }
                },

                fillAllZeros() {
                    this.reportData.TSP = '0';
                    this.reportData.PM10 = '0';
                    this.reportData.PM25 = '0';
                    this.reportData.SOx = '0';
                    this.reportData.NOx = '0';
                    this.reportData.VOCs = '0';
                    this.showAlert('已一鍵全數填入 0 (公斤)', 'success');
                },

                clearAllQuantities() {
                    this.reportData.TSP = '';
                    this.reportData.PM10 = '';
                    this.reportData.PM25 = '';
                    this.reportData.SOx = '';
                    this.reportData.NOx = '';
                    this.reportData.VOCs = '';
                },

                initLeafletMap() {
                    const mapEl = document.getElementById('map');
                    if (!mapEl) return;

                    // 若已存在地圖實例，重設銷毀
                    if (this.leafletMap) {
                        try { this.leafletMap.remove(); } catch(e) {}
                        this.leafletMap = null;
                    }

                    // 預設經緯度 (新北市政府或工廠座標)
                    let centerLat = 25.011629;
                    let centerLng = 121.465878;
                    let hasCoord = false;

                    if (this.facInfo.Lat && this.facInfo.Lng && this.facInfo.Lat > 0 && this.facInfo.Lng > 0) {
                        centerLat = this.facInfo.Lat;
                        centerLng = this.facInfo.Lng;
                        hasCoord = true;
                    }

                    // 建立 Leaflet 地圖實例 (避免 Vue 響應式代理)
                    const mapInstance = L.map('map', {
                        center: [centerLat, centerLng],
                        zoom: hasCoord ? 16 : 12,
                        zoomControl: true
                    });

                    // 國土測繪臺灣通用電子地圖底圖
                    L.tileLayer('https://wmts.nlsc.gov.tw/wmts/EMAP/default/GoogleMapsCompatible/{z}/{y}/{x}', {
                        maxZoom: 19,
                        attribution: '&copy; 內政部國土測繪中心'
                    }).addTo(mapInstance);

                    if (hasCoord) {
                        // 建立標記 Pin
                        const marker = L.marker([centerLat, centerLng]).addTo(mapInstance);
                        marker.bindPopup(
                            '<div style="font-size:13px; line-height:1.5;">' +
                            '<strong>' + (this.facInfo.FacName || '公私場所') + '</strong><br />' +
                            '管制編號：' + (this.facInfo.CNo || '-') + '<br />' +
                            '地址：' + (this.facInfo.Addr || '-') +
                            '</div>'
                        ).openPopup();
                    }

                    this.leafletMap = markRaw(mapInstance);
                },

                resetMapView() {
                    if (!this.leafletMap) return;
                    if (this.facInfo.Lat && this.facInfo.Lng) {
                        this.leafletMap.setView([this.facInfo.Lat, this.facInfo.Lng], 16);
                    } else {
                        this.leafletMap.setView([25.011629, 121.465878], 12);
                    }
                },

                locateCurrentPosition() {
                    if (!navigator.geolocation) {
                        alert('您的瀏覽器不支援 GPS 定位功能');
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
                                    color: '#0284c7',
                                    fillColor: '#38bdf8',
                                    fillOpacity: 0.8
                                }).addTo(this.leafletMap).bindPopup('目前所在位置').openPopup();
                            }
                            this.showAlert('已成功定位至目前位置', 'success');
                        },
                        err => {
                            alert('GPS 定位失敗：' + err.message);
                        },
                        { enableHighAccuracy: true, timeout: 8000 }
                    );
                },

                openGoogleMaps() {
                    if (this.facInfo.Lat && this.facInfo.Lng) {
                        const url = 'https://www.google.com/maps/dir/?api=1&destination=' + this.facInfo.Lat + ',' + this.facInfo.Lng;
                        window.open(url, '_blank');
                    }
                },

                printReport() {
                    window.print();
                },

                showAlert(msg, type = 'success') {
                    this.alertMessage = msg;
                    this.alertType = type;
                    window.scrollTo({ top: 0, behavior: 'smooth' });
                },

                submitForm() {
                    // 表單檢核
                    if (!this.reportData.FAC_ID) {
                        this.showAlert('請先確認或選取申報公私場所', 'danger');
                        return;
                    }
                    if (!this.reportData.OverDate) {
                        this.showAlert('請選取應變通報日期', 'danger');
                        return;
                    }
                    if (this.reportData.Less === '是' && (!this.reportData.LessMe || !this.reportData.LessMe.trim())) {
                        this.showAlert('配合執行減排措施為「是」，請填寫具體減排措施說明', 'danger');
                        return;
                    }
                    if (this.reportData.Less === '否' && (!this.reportData.NoReason || !this.reportData.NoReason.trim())) {
                        this.showAlert('配合執行減排措施為「否」，請填寫未配合原因說明', 'danger');
                        return;
                    }

                    this.isSaving = true;
                    axios.post('Report_AirQuality.aspx?action=save', this.reportData)
                    .then(res => {
                        this.isSaving = false;
                        if (res.data && res.data.Success) {
                            alert(res.data.Message || '空品應變回報單儲存成功！');
                            window.location.href = 'AirQuality_List.aspx';
                        } else {
                            this.showAlert('儲存失敗：' + (res.data ? res.data.Message : '未知錯誤'), 'danger');
                        }
                    })
                    .catch(err => {
                        this.isSaving = false;
                        this.showAlert('送出異常：' + err.message, 'danger');
                    });
                }
            }
        }).mount('#app');
    </script>
</body>
</html>
