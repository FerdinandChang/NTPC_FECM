<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="NewBare.aspx.cs" Inherits="NTPC_FEC.BareGround.NewBare" %>

<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定溢散源管理平台 - 裸露地現場巡查作業</title>

    <!-- 專屬 Favicon -->
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
        .top-navbar .brand-title {
            font-size: 1.05rem; font-weight: 700; margin: 0;
            display: flex; align-items: center; gap: 6px;
            white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
        }
        @media screen and (max-width: 576px) {
            .top-navbar { padding: 0 10px; height: 50px; }
            .top-navbar .brand-title { font-size: 0.95rem; }
        }

        .nav-btn {
            background: rgba(255, 255, 255, 0.18);
            border: none; color: #ffffff;
            font-size: 0.92rem; font-weight: 600; cursor: pointer;
            height: 36px; border-radius: 8px;
            display: inline-flex; align-items: center; justify-content: center;
            padding: 0 14px; gap: 6px;
            transition: all 0.2s; text-decoration: none;
        }
        .nav-btn:hover { background-color: rgba(255, 255, 255, 0.32); color: #ffffff; text-decoration: none; }

        /* 主容器佈局 */
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
            padding: 10px 16px;
            background: #ffffff;
            border-bottom: 1px solid var(--border-color);
            display: flex; align-items: center; justify-content: space-between;
            gap: 8px;
            flex-wrap: nowrap;
        }
        .card-modern-title {
            font-size: 1rem; font-weight: 700; color: var(--brand-navy); margin: 0;
            display: flex; align-items: center; gap: 8px;
            white-space: nowrap;
            flex-shrink: 1;
            min-width: 0;
        }
        .card-modern-title span {
            white-space: nowrap;
        }
        .header-actions {
            display: inline-flex;
            align-items: center;
            gap: 4px;
            flex-shrink: 0;
            white-space: nowrap;
        }
        .header-actions .btn {
            white-space: nowrap;
        }
        @media screen and (max-width: 576px) {
            .card-modern-header { padding: 8px 12px; }
            .card-modern-title { font-size: 0.95rem; }
            .header-actions .btn { padding: 4px 8px; min-height: 32px; font-size: 12px; }
            .segment-btn { padding: 4px 10px; font-size: 12px; min-height: 32px; white-space: nowrap; }
        }
        .card-modern-body { padding: 16px; }

        /* 桌面端左欄固頂 */
        @media screen and (min-width: 1200px) {
            .sticky-sidebar {
                position: sticky; top: 72px;
                max-height: calc(100vh - 88px);
                overflow-y: auto; padding-right: 4px;
            }
        }

        /* 規格晶片列 (Stat Chips) */
        .stat-chip-group {
            display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 12px;
        }
        .stat-chip {
            background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px;
            padding: 6px 12px; font-size: 13px; font-weight: 600; color: #475569;
            display: inline-flex; align-items: center; gap: 6px;
        }
        .stat-chip strong { color: var(--brand-navy); font-weight: 700; }

        /* 智慧現場地圖 */
        #map {
            width: 100%; height: 380px; border-radius: 8px; z-index: 10;
            transition: height 0.3s ease;
        }
        #map.map-collapsed { height: 120px !important; }

        /* 地圖標記 Pin */
        .custom-map-marker { display: flex; align-items: center; justify-content: center; }
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
        .marker-icon-inner { transform: rotate(45deg); color: #ffffff; font-size: 13px; }

        /* 切換標籤群組 */
        .segmented-group {
            display: inline-flex; background: #e2e8f0; padding: 3px; border-radius: 8px; gap: 2px;
        }
        .segment-btn {
            border: none; background: transparent; padding: 6px 16px;
            border-radius: 6px; font-size: 13px; font-weight: 600; color: #475569;
            cursor: pointer; min-height: 36px; transition: all 0.15s ease;
        }
        .segment-btn.active-primary {
            background: var(--brand-blue); color: #ffffff;
            box-shadow: 0 1px 4px rgba(2, 132, 199, 0.35);
        }

        /* 常用片語快捷按鈕 */
        .phrase-pill-group {
            display: flex; flex-wrap: wrap; gap: 6px; margin-top: 8px;
        }
        .phrase-pill {
            border: 1px solid #cbd5e1; background: #f8fafc; color: #475569;
            padding: 4px 10px; border-radius: 16px; font-size: 12px; font-weight: 600;
            cursor: pointer; transition: all 0.15s;
        }
        .phrase-pill:hover {
            background: #e0f2fe; border-color: #0284c7; color: #0369a1;
        }

        /* 四格照片區塊 */
        .photo-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 12px;
        }
        @media screen and (max-width: 576px) {
            .photo-grid { grid-template-columns: 1fr; }
        }
        .photo-slot {
            background: #f8fafc; border: 2px dashed #cbd5e1; border-radius: 10px;
            padding: 12px; text-align: center; position: relative;
            min-height: 200px; display: flex; flex-direction: column;
            align-items: center; justify-content: center; transition: all 0.2s;
        }
        .photo-slot.has-image {
            border-style: solid; border-color: #94a3b8; background: #000000;
            padding: 0; overflow: hidden;
        }
        .photo-slot-img {
            width: 100%; height: 190px; object-fit: cover; display: block;
        }
        .photo-slot-title {
            font-size: 13px; font-weight: 700; color: #334155; margin-bottom: 8px;
        }
        .photo-slot-desc {
            font-size: 11px; color: #64748b; margin-bottom: 12px;
        }
        .photo-overlay-actions {
            position: absolute; bottom: 8px; left: 8px; right: 8px;
            display: flex; justify-content: space-between; gap: 6px;
            background: rgba(15, 23, 42, 0.75); padding: 6px 10px; border-radius: 6px;
        }

        /* 簽名預覽區 */
        .sig-preview-box {
            background: #ffffff; border: 2px dashed #cbd5e1; border-radius: 8px;
            padding: 12px; text-align: center; cursor: pointer;
            transition: all 0.2s; min-height: 120px;
            display: flex; flex-direction: column; align-items: center; justify-content: center;
        }
        .sig-preview-box:hover {
            border-color: var(--brand-blue); background: #f0f9ff;
        }
        .sig-preview-img {
            max-width: 100%; max-height: 110px; object-fit: contain;
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

        /* 全螢幕觸控簽名 Modal */
        .fullscreen-sig-modal {
            position: fixed; top: 0; left: 0; width: 100vw; height: 100vh;
            background: #ffffff; z-index: 2000;
            display: flex; flex-direction: column;
        }
        .sig-canvas-wrap {
            flex: 1; position: relative; background: #ffffff; touch-action: none;
        }
        #sigCanvas {
            width: 100%; height: 100%; display: block; cursor: crosshair; touch-action: none;
        }
        .sig-modal-header {
            padding: 12px 16px; background: #f8fafc; border-bottom: 1px solid #e2e8f0;
            display: flex; align-items: center; justify-content: space-between;
        }
        .sig-modal-footer {
            padding: 12px 16px; background: #f8fafc; border-top: 1px solid #e2e8f0;
            display: flex; align-items: center; justify-content: flex-end; gap: 10px;
        }

        /* 快捷輔助計算按鈕 */
        .calc-chip {
            background: #e0f2fe; border: 1px solid #bae6fd; color: #0369a1;
            padding: 3px 8px; border-radius: 4px; font-size: 11px; font-weight: 700;
            cursor: pointer; margin-right: 4px; display: inline-block;
        }
        .calc-chip:hover { background: #0284c7; color: #ffffff; }

        /* 快速提示 Alert */
        .toast-banner {
            position: fixed; top: 68px; right: 20px; z-index: 2050; min-width: 300px;
            box-shadow: 0 4px 16px rgba(0,0,0,0.15); border-radius: 8px;
        }
    </style>
</head>
<body>
    <div id="app" v-cloak>
        <!-- 頂部置頂導覽列 -->
        <header class="top-navbar no-print">
            <div class="brand-title">
                <button type="button" class="nav-btn mr-2" v-on:click="goBack">
                    <i class="fas fa-arrow-left"></i>
                    <span class="d-none d-sm-inline">返回清單</span>
                </button>
                <i class="fas fa-mountain text-white"></i>
                <span>裸露地現場巡查作業</span>
                <span class="badge badge-light text-dark font-weight-bold ml-2" style="font-size: 0.85rem;">
                    {{ mode === 'new' ? (form.IsNewSite ? '新增場址' : '新巡查案') : (mode === 'edit' ? '編輯案件' : '檢視案件') }}
                </span>
                <span v-if="form.Bare_ID" class="badge badge-dark ml-2 d-none d-md-inline" style="font-size: 0.82rem;">
                    {{ form.BareGroundNo || form.Bare_ID }}
                </span>
            </div>

            <div class="d-flex align-items-center gap-2">
                <button v-if="mode !== 'read'" type="button" class="nav-btn bg-white text-dark shadow-sm d-none d-md-inline-flex" v-on:click="openSignatureModal">
                    <i class="fas fa-signature text-primary"></i>
                    <span>手寫簽名</span>
                </button>
                <button v-if="mode !== 'read'" type="button" class="nav-btn btn-primary font-weight-bold shadow-sm d-none d-md-inline-flex ml-2" v-on:click="submitForm">
                    <i class="fas fa-check-circle"></i>
                    <span>確定送出</span>
                </button>
                <button v-if="mode === 'read'" type="button" class="nav-btn bg-white text-dark shadow-sm ml-2" v-on:click="printCase">
                    <i class="fas fa-print"></i>
                    <span class="d-none d-md-inline">列印案件</span>
                </button>
            </div>
        </header>

        <!-- 提示 Toast 橫幅 -->
        <div v-if="alertMessage" class="alert toast-banner" :class="'alert-' + alertType" role="alert">
            <div class="d-flex align-items-center justify-content-between">
                <div>
                    <i :class="alertType === 'success' ? 'fas fa-check-circle mr-2' : 'fas fa-exclamation-triangle mr-2'"></i>
                    <span>{{ alertMessage }}</span>
                </div>
                <button type="button" class="close ml-3" v-on:click="alertMessage = ''">&times;</button>
            </div>
        </div>

        <!-- 主內容容器 (Desktop 雙欄，Mobile 單欄) -->
        <main class="container-fluid-custom">
            <div class="row">
                <!-- 左欄：基本設定、地圖定位、簽章面板 (Desktop 40%, Sticky) -->
                <div class="col-12 col-xl-5">
                    <div class="sticky-sidebar">
                        <!-- 卡片 1：場址基本設定 -->
                        <div class="card-modern">
                            <div class="card-modern-header">
                                <h2 class="card-modern-title">
                                    <i class="fas fa-map-marked-alt text-primary"></i>
                                    <span>裸露地場址設定</span>
                                </h2>
                                <!-- 模式切換：既有場址 / 建立新場址 -->
                                <div v-if="mode !== 'read'" class="segmented-group">
                                    <button type="button" class="segment-btn" :class="{ 'active-primary': !form.IsNewSite }" v-on:click="switchSiteMode(false)">
                                        既有場址
                                    </button>
                                    <button type="button" class="segment-btn" :class="{ 'active-primary': form.IsNewSite }" v-on:click="switchSiteMode(true)">
                                        建立新場址
                                    </button>
                                </div>
                            </div>

                            <div class="card-modern-body">
                                <!-- 規格晶片列 (Stat Chips) -->
                                <div class="stat-chip-group">
                                    <div class="stat-chip">
                                        <i class="fas fa-hashtag text-secondary"></i>
                                        場址編號：<strong>{{ form.BareGroundNo || (form.IsNewSite ? '系統自動取號' : '未選擇') }}</strong>
                                    </div>
                                    <div class="stat-chip">
                                        <i class="fas fa-layer-group text-secondary"></i>
                                        地目：<strong>{{ form.Land_USE || '未填寫' }}</strong>
                                    </div>
                                    <div class="stat-chip">
                                        <i class="fas fa-crosshairs text-secondary"></i>
                                        GPS：<strong>{{ formatCoordinates() }}</strong>
                                    </div>
                                </div>

                                <!-- A. 選擇既有場址 -->
                                <div v-if="!form.IsNewSite" class="form-group mb-3">
                                    <label class="font-weight-bold text-dark">
                                        選取裸露地場址
                                        <span class="text-danger">*</span>
                                    </label>
                                    <div class="input-group mb-2">
                                        <input type="text" class="form-control" placeholder="輸入關鍵字過濾編號或地址..." v-model="siteFilterKeyword" :disabled="mode === 'read'" />
                                        <div class="input-group-append">
                                            <span class="input-group-text"><i class="fas fa-search"></i></span>
                                        </div>
                                    </div>
                                    <select class="form-control font-weight-bold" v-model="form.Bare_ID" v-on:change="onSiteSelected" :disabled="mode === 'read'">
                                        <option value="">-- 請選取裸露地場址 (共 {{ filteredSites.length }} 處) --</option>
                                        <option v-for="site in filteredSites" :key="site.Bare_ID" :value="site.Bare_ID">
                                            [{{ site.BareGroundNo || site.Bare_ID }}] {{ site.ADDR || '無地址資訊' }}
                                        </option>
                                    </select>
                                </div>

                                <!-- B. 建立新場址欄位 -->
                                <div v-if="form.IsNewSite" class="form-group mb-3">
                                    <label class="font-weight-bold text-dark">
                                        新場址自訂編號
                                        <span class="text-danger">*</span>
                                    </label>
                                    <input type="text" class="form-control" placeholder="例：新北裸露地-林口01號" v-model="form.BareGroundNo" :disabled="mode === 'read'" />
                                </div>

                                <!-- 場址地址 -->
                                <div class="form-group mb-3">
                                    <label class="font-weight-bold text-dark">
                                        場址地址 / 相關位置
                                    </label>
                                    <input type="text" class="form-control" placeholder="例：新北市八里區中山路三段..." v-model="form.ADDR" :disabled="mode === 'read'" />
                                </div>

                                <!-- 地目與常見快捷片語 -->
                                <div class="form-group mb-2">
                                    <label class="font-weight-bold text-dark">
                                        土地使用分區 / 地目
                                    </label>
                                    <input type="text" class="form-control" placeholder="例：農牧用地、特定農業區、建地..." v-model="form.Land_USE" :disabled="mode === 'read'" />
                                    <div v-if="mode !== 'read'" class="phrase-pill-group">
                                        <span class="phrase-pill" v-on:click="form.Land_USE = '農牧用地'">農牧用地</span>
                                        <span class="phrase-pill" v-on:click="form.Land_USE = '特定目的事業用地'">特定目的事業</span>
                                        <span class="phrase-pill" v-on:click="form.Land_USE = '乙種工業用地'">乙種工業區</span>
                                        <span class="phrase-pill" v-on:click="form.Land_USE = '都市計畫農業區'">都市計畫農業區</span>
                                        <span class="phrase-pill" v-on:click="form.Land_USE = '住宅區空地'">住宅區空地</span>
                                        <span class="phrase-pill" v-on:click="form.Land_USE = '公有未開闢土地'">公有未開闢地</span>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- 卡片 2：智慧現場地圖 (Leaflet) -->
                        <div class="card-modern" id="mapContainer">
                            <div class="card-modern-header">
                                <h2 class="card-modern-title">
                                    <i class="fas fa-map text-primary"></i>
                                    <span>現場智慧定位地圖</span>
                                </h2>
                                <!-- 地圖快捷操作按鈕 (零遮擋 Header 配置) -->
                                <div class="header-actions">
                                    <button type="button" class="btn btn-sm btn-outline-secondary d-md-none text-nowrap" v-on:click="toggleMapCollapse" :title="isMapCollapsed ? '展開地圖' : '收合地圖'">
                                        <i :class="isMapCollapsed ? 'fas fa-expand-alt' : 'fas fa-compress-alt'"></i>
                                        <span class="d-none d-sm-inline ml-1">{{ isMapCollapsed ? '展開地圖' : '收合地圖' }}</span>
                                    </button>
                                    <button v-if="mode !== 'read'" type="button" class="btn btn-sm btn-outline-primary text-nowrap" v-on:click="getCurrentLocation" title="取得當前手機GPS位置">
                                        <i class="fas fa-crosshairs text-success"></i>
                                        <span class="d-none d-sm-inline ml-1">GPS 定位</span>
                                    </button>
                                    <button type="button" class="btn btn-sm btn-outline-secondary text-nowrap" v-on:click="resetMapView" title="重設視圖中心">
                                        <i class="fas fa-sync-alt"></i>
                                        <span class="d-none d-sm-inline ml-1">重設</span>
                                    </button>
                                </div>
                            </div>

                            <div class="card-modern-body p-2">
                                <div id="map" :class="{ 'map-collapsed': isMapCollapsed }"></div>
                                <div class="d-flex justify-content-between align-items-center mt-2 px-1 text-muted" style="font-size: 11px;">
                                    <span>
                                        <i class="fas fa-info-circle text-info"></i>
                                        {{ mode !== 'read' ? '提示：在地圖任意處點擊或拖曳標記，即可更新查核經緯度。' : '目前為檢視模式。' }}
                                    </span>
                                    <span v-if="form.Latitude && form.Longtitude" class="font-weight-bold text-dark">
                                        WGS84: {{ Number(form.Latitude).toFixed(5) }}, {{ Number(form.Longtitude).toFixed(5) }}
                                    </span>
                                </div>
                            </div>
                        </div>

                        <!-- 卡片 3：稽查人員簽章面板 (Desktop 端) -->
                        <div class="card-modern d-none d-xl-block">
                            <div class="card-modern-header">
                                <h2 class="card-modern-title">
                                    <i class="fas fa-signature text-primary"></i>
                                    <span>稽查人員簽名</span>
                                </h2>
                                <button v-if="mode !== 'read' && (signatureUrl || signatureBase64)" type="button" class="btn btn-sm btn-outline-danger" v-on:click="clearSignature">
                                    <i class="fas fa-eraser"></i> 清除重簽
                                </button>
                            </div>
                            <div class="card-modern-body">
                                <div class="sig-preview-box" v-on:click="mode !== 'read' && openSignatureModal()">
                                    <img v-if="signatureBase64 || signatureUrl" :src="signatureBase64 || signatureUrl" class="sig-preview-img" alt="稽查人員簽名" />
                                    <div v-else class="text-muted">
                                        <i class="fas fa-pen-nib fa-2x mb-2 text-primary"></i>
                                        <p class="mb-0 font-weight-bold" style="font-size: 13px;">點此開啟全螢幕手寫簽名板</p>
                                        <small class="text-secondary">外勤觸控手寫支援</small>
                                    </div>
                                </div>

                                <div v-if="mode !== 'read'" class="d-flex gap-2 mt-3">
                                    <button type="button" class="btn btn-primary btn-block font-weight-bold py-2" v-on:click="submitForm">
                                        <i class="fas fa-check-circle mr-1"></i> 確定送出巡檢紀錄
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- 右欄：主檢核作業區 (Desktop 60%) -->
                <div class="col-12 col-xl-7">
                    <!-- 卡片 A：查核基本資訊 -->
                    <div class="card-modern">
                        <div class="card-modern-header">
                            <h2 class="card-modern-title">
                                <i class="fas fa-calendar-check text-primary"></i>
                                <span>查核時程與巡查人員</span>
                            </h2>
                            <span class="badge badge-primary">現況第 {{ form.INV_NO || 1 }} 次巡查</span>
                        </div>
                        <div class="card-modern-body">
                            <div class="form-row">
                                <div class="col-12 col-md-5 mb-3">
                                    <label class="font-weight-bold text-dark">查核日期 <span class="text-danger">*</span></label>
                                    <input type="date" class="form-control font-weight-bold" v-model="form.Check_Date" :disabled="mode === 'read'" />
                                </div>
                                <div class="col-12 col-md-4 mb-3">
                                    <label class="font-weight-bold text-dark">查核時間</label>
                                    <input type="time" class="form-control font-weight-bold" v-model="form.Check_Time" :disabled="mode === 'read'" />
                                </div>
                                <div class="col-12 col-md-3 mb-3">
                                    <label class="font-weight-bold text-dark">巡查填報員</label>
                                    <input type="text" class="form-control bg-light" v-model="form.InputUser" readonly />
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- 卡片 B：堆置規模與面積估算 -->
                    <div class="card-modern">
                        <div class="card-modern-header">
                            <h2 class="card-modern-title">
                                <i class="fas fa-cubes text-primary"></i>
                                <span>現場堆置規模與面積估算</span>
                            </h2>
                            <small class="text-muted">支援點擊公式快速推算</small>
                        </div>
                        <div class="card-modern-body">
                            <div class="form-row">
                                <div class="col-6 col-md-4 mb-3">
                                    <label class="font-weight-bold text-dark">長度 (m)</label>
                                    <div class="input-group">
                                        <input type="number" step="0.1" class="form-control" v-model="form.pLength" v-on:input="autoEstimateVolume" :disabled="mode === 'read'" placeholder="0.0" />
                                        <div class="input-group-append"><span class="input-group-text">公尺</span></div>
                                    </div>
                                </div>
                                <div class="col-6 col-md-4 mb-3">
                                    <label class="font-weight-bold text-dark">寬度 (m)</label>
                                    <div class="input-group">
                                        <input type="number" step="0.1" class="form-control" v-model="form.pWidth" v-on:input="autoEstimateVolume" :disabled="mode === 'read'" placeholder="0.0" />
                                        <div class="input-group-append"><span class="input-group-text">公尺</span></div>
                                    </div>
                                </div>
                                <div class="col-12 col-md-4 mb-3">
                                    <label class="font-weight-bold text-dark">高度 (m)</label>
                                    <div class="input-group">
                                        <input type="number" step="0.1" class="form-control" v-model="form.pHeight" v-on:input="autoEstimateVolume" :disabled="mode === 'read'" placeholder="0.0" />
                                        <div class="input-group-append"><span class="input-group-text">公尺</span></div>
                                    </div>
                                </div>
                            </div>

                            <div class="form-row mt-1">
                                <div class="col-12 col-md-6 mb-3">
                                    <div class="d-flex justify-content-between align-items-center mb-1">
                                        <label class="font-weight-bold text-dark mb-0">堆置總量 (m³)</label>
                                        <div v-if="mode !== 'read'">
                                            <span class="calc-chip" v-on:click="calcVolume('cube')">長方體 (1.0)</span>
                                            <span class="calc-chip" v-on:click="calcVolume('slope')">斜坡台 (0.6)</span>
                                            <span class="calc-chip" v-on:click="calcVolume('cone')">圓錐體 (0.33)</span>
                                        </div>
                                    </div>
                                    <div class="input-group">
                                        <input type="number" step="0.1" class="form-control font-weight-bold" v-model="form.pVolume" :disabled="mode === 'read'" placeholder="0.0" />
                                        <div class="input-group-append"><span class="input-group-text">立方公尺</span></div>
                                    </div>
                                </div>

                                <div class="col-12 col-md-6 mb-3">
                                    <div class="d-flex justify-content-between align-items-center mb-1">
                                        <label class="font-weight-bold text-dark mb-0">場址面積 (m²)</label>
                                        <div v-if="mode !== 'read'">
                                            <span class="calc-chip" v-on:click="calcArea">長×寬自動計算</span>
                                        </div>
                                    </div>
                                    <div class="input-group">
                                        <input type="number" step="0.1" class="form-control font-weight-bold" v-model="form.pArea" :disabled="mode === 'read'" placeholder="0.0" />
                                        <div class="input-group-append"><span class="input-group-text">平方公尺</span></div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- 卡片 C：現場概況與周界說明 -->
                    <div class="card-modern">
                        <div class="card-modern-header">
                            <h2 class="card-modern-title">
                                <i class="fas fa-clipboard-list text-primary"></i>
                                <span>現場概況與周界說明</span>
                            </h2>
                        </div>
                        <div class="card-modern-body">
                            <!-- 1. 周界概況 -->
                            <div class="form-group mb-4">
                                <label class="font-weight-bold text-dark">
                                    場址周界概況
                                </label>
                                <textarea class="form-control" rows="3" placeholder="描述場址四周環境、相鄰道路或阻隔狀況..." v-model="form.Around_Memo" :disabled="mode === 'read'"></textarea>
                                <div v-if="mode !== 'read'" class="phrase-pill-group">
                                    <span class="phrase-pill" v-on:click="insertPhrase('Around_Memo', '周界設有完整防溢座與阻隔圍籬')">周界設有完整圍籬</span>
                                    <span class="phrase-pill" v-on:click="insertPhrase('Around_Memo', '場址周界未設有效圍籬或防塵網')">未設有效圍籬防塵網</span>
                                    <span class="phrase-pill" v-on:click="insertPhrase('Around_Memo', '鄰近主要車行幹道，車流量大')">鄰近主要幹道</span>
                                    <span class="phrase-pill" v-on:click="insertPhrase('Around_Memo', '緊鄰農地及綠帶，邊界有雜草防護')">緊鄰農地綠帶</span>
                                    <span class="phrase-pill" v-on:click="insertPhrase('Around_Memo', '現場設有鐵皮圍籬，出入口常時封閉')">鐵皮圍籬常閉</span>
                                </div>
                            </div>

                            <!-- 2. 廢棄物種類、外觀 -->
                            <div class="form-group mb-4">
                                <label class="font-weight-bold text-dark">
                                    廢棄物種類、外觀
                                </label>
                                <textarea class="form-control" rows="3" placeholder="描述堆置物性質，如營建剩餘土石方、泥沙、磚瓦、混合廢棄物..." v-model="form.Waste_Type" :disabled="mode === 'read'"></textarea>
                                <div v-if="mode !== 'read'" class="phrase-pill-group">
                                    <span class="phrase-pill" v-on:click="insertPhrase('Waste_Type', '主要為營建剩餘土石方，土質乾燥鬆散')">營建剩餘土石方</span>
                                    <span class="phrase-pill" v-on:click="insertPhrase('Waste_Type', '夾雜廢磚塊、混凝土塊與零星木材')">夾雜磚瓦混凝土塊</span>
                                    <span class="phrase-pill" v-on:click="insertPhrase('Waste_Type', '現場堆置瀝青刨除料與級配粒料')">瀝青刨除料/級配</span>
                                    <span class="phrase-pill" v-on:click="insertPhrase('Waste_Type', '未發現有害事業廢棄物或明顯廢棄物')">未發現有害廢棄物</span>
                                    <span class="phrase-pill" v-on:click="insertPhrase('Waste_Type', '堆置物表面乾燥，覆蓋防塵網局部破損')">防塵網局部破損</span>
                                </div>
                            </div>

                            <!-- 3. 現場環境概況說明 -->
                            <div class="form-group mb-2">
                                <label class="font-weight-bold text-dark">
                                    現場環境概況說明
                                </label>
                                <textarea class="form-control" rows="3" placeholder="描述空氣品質、是否有明顯揚塵逸散、出入口防制設施運作狀況..." v-model="form.surroundings" :disabled="mode === 'read'"></textarea>
                                <div v-if="mode !== 'read'" class="phrase-pill-group">
                                    <span class="phrase-pill" v-on:click="insertPhrase('surroundings', '現場無明顯揚塵溢散，空氣品質尚屬良好')">無明顯揚塵溢散</span>
                                    <span class="phrase-pill" v-on:click="insertPhrase('surroundings', '遇強風時局部易有揚塵逸散現象')">遇強風易揚塵</span>
                                    <span class="phrase-pill" v-on:click="insertPhrase('surroundings', '出入口未設洗車設施，車輛行經易夾帶泥沙')">出入口無洗車設施</span>
                                    <span class="phrase-pill" v-on:click="insertPhrase('surroundings', '出入口已設自動洗車台，路面維持濕潤潔淨')">出入口洗車台運作良好</span>
                                    <span class="phrase-pill" v-on:click="insertPhrase('surroundings', '場內通道已鋪設鋼板並定時灑水抑塵')">鋪設鋼板定時灑水</span>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- 卡片 D：現場佐證照片 (四格照片標準規範) -->
                    <div class="card-modern">
                        <div class="card-modern-header">
                            <h2 class="card-modern-title">
                                <i class="fas fa-camera text-primary"></i>
                                <span>現場照片佐證 (四格照片標準)</span>
                            </h2>
                            <small class="text-muted">支援外勤相機直拍與自動壓縮上傳</small>
                        </div>
                        <div class="card-modern-body">
                            <div class="photo-grid">
                                <!-- 照片 1 -->
                                <div class="photo-slot" :class="{ 'has-image': photos[0].PreviewUrl }">
                                    <template v-if="photos[0].PreviewUrl">
                                        <img :src="photos[0].PreviewUrl" class="photo-slot-img" alt="裸露地現場照片(一)" />
                                        <div class="photo-overlay-actions">
                                            <span class="text-white small font-weight-bold">一、場址全景</span>
                                            <div>
                                                <button type="button" class="btn btn-sm btn-light py-0 px-2 mr-1" v-on:click="previewBigPhoto(photos[0].PreviewUrl, '裸露地現場照片(一)')" title="放大預覽">
                                                    <i class="fas fa-search-plus"></i>
                                                </button>
                                                <button v-if="mode !== 'read'" type="button" class="btn btn-sm btn-danger py-0 px-2" v-on:click="removePhoto(0)" title="移除此照片">
                                                    <i class="fas fa-trash-alt"></i>
                                                </button>
                                            </div>
                                        </div>
                                    </template>
                                    <template v-else>
                                        <div class="photo-slot-title">裸露地現場照片 (一)</div>
                                        <div class="photo-slot-desc">建議拍攝：場址全貌與整體空曠視野</div>
                                        <input type="file" accept="image/*" class="d-none" id="photoInput0" v-on:change="onPhotoSelected($event, 0)" :disabled="mode === 'read'" />
                                        <button v-if="mode !== 'read'" type="button" class="btn btn-sm btn-outline-primary font-weight-bold" v-on:click="triggerPhotoUpload(0)">
                                            <i class="fas fa-camera mr-1"></i> 拍照 / 上傳照片
                                        </button>
                                    </template>
                                </div>

                                <!-- 照片 2 -->
                                <div class="photo-slot" :class="{ 'has-image': photos[1].PreviewUrl }">
                                    <template v-if="photos[1].PreviewUrl">
                                        <img :src="photos[1].PreviewUrl" class="photo-slot-img" alt="裸露地現場照片(二)" />
                                        <div class="photo-overlay-actions">
                                            <span class="text-white small font-weight-bold">二、堆置物特寫</span>
                                            <div>
                                                <button type="button" class="btn btn-sm btn-light py-0 px-2 mr-1" v-on:click="previewBigPhoto(photos[1].PreviewUrl, '裸露地現場照片(二)')" title="放大預覽">
                                                    <i class="fas fa-search-plus"></i>
                                                </button>
                                                <button v-if="mode !== 'read'" type="button" class="btn btn-sm btn-danger py-0 px-2" v-on:click="removePhoto(1)" title="移除此照片">
                                                    <i class="fas fa-trash-alt"></i>
                                                </button>
                                            </div>
                                        </div>
                                    </template>
                                    <template v-else>
                                        <div class="photo-slot-title">裸露地現場照片 (二)</div>
                                        <div class="photo-slot-desc">建議拍攝：堆置物外觀、土石高度與覆蓋特寫</div>
                                        <input type="file" accept="image/*" class="d-none" id="photoInput1" v-on:change="onPhotoSelected($event, 1)" :disabled="mode === 'read'" />
                                        <button v-if="mode !== 'read'" type="button" class="btn btn-sm btn-outline-primary font-weight-bold" v-on:click="triggerPhotoUpload(1)">
                                            <i class="fas fa-camera mr-1"></i> 拍照 / 上傳照片
                                        </button>
                                    </template>
                                </div>

                                <!-- 照片 3 -->
                                <div class="photo-slot" :class="{ 'has-image': photos[2].PreviewUrl }">
                                    <template v-if="photos[2].PreviewUrl">
                                        <img :src="photos[2].PreviewUrl" class="photo-slot-img" alt="裸露地現場照片(三)" />
                                        <div class="photo-overlay-actions">
                                            <span class="text-white small font-weight-bold">三、周界防制設施</span>
                                            <div>
                                                <button type="button" class="btn btn-sm btn-light py-0 px-2 mr-1" v-on:click="previewBigPhoto(photos[2].PreviewUrl, '裸露地現場照片(三)')" title="放大預覽">
                                                    <i class="fas fa-search-plus"></i>
                                                </button>
                                                <button v-if="mode !== 'read'" type="button" class="btn btn-sm btn-danger py-0 px-2" v-on:click="removePhoto(2)" title="移除此照片">
                                                    <i class="fas fa-trash-alt"></i>
                                                </button>
                                            </div>
                                        </div>
                                    </template>
                                    <template v-else>
                                        <div class="photo-slot-title">裸露地現場照片 (三)</div>
                                        <div class="photo-slot-desc">建議拍攝：圍籬、阻隔設施或防塵覆蓋網現況</div>
                                        <input type="file" accept="image/*" class="d-none" id="photoInput2" v-on:change="onPhotoSelected($event, 2)" :disabled="mode === 'read'" />
                                        <button v-if="mode !== 'read'" type="button" class="btn btn-sm btn-outline-primary font-weight-bold" v-on:click="triggerPhotoUpload(2)">
                                            <i class="fas fa-camera mr-1"></i> 拍照 / 上傳照片
                                        </button>
                                    </template>
                                </div>

                                <!-- 照片 4 -->
                                <div class="photo-slot" :class="{ 'has-image': photos[3].PreviewUrl }">
                                    <template v-if="photos[3].PreviewUrl">
                                        <img :src="photos[3].PreviewUrl" class="photo-slot-img" alt="裸露地現場照片(四)" />
                                        <div class="photo-overlay-actions">
                                            <span class="text-white small font-weight-bold">四、出入口與周邊道路</span>
                                            <div>
                                                <button type="button" class="btn btn-sm btn-light py-0 px-2 mr-1" v-on:click="previewBigPhoto(photos[3].PreviewUrl, '裸露地現場照片(四)')" title="放大預覽">
                                                    <i class="fas fa-search-plus"></i>
                                                </button>
                                                <button v-if="mode !== 'read'" type="button" class="btn btn-sm btn-danger py-0 px-2" v-on:click="removePhoto(3)" title="移除此照片">
                                                    <i class="fas fa-trash-alt"></i>
                                                </button>
                                            </div>
                                        </div>
                                    </template>
                                    <template v-else>
                                        <div class="photo-slot-title">裸露地現場照片 (四)</div>
                                        <div class="photo-slot-desc">建議拍攝：車輛出入口、洗車設施與鄰近路面</div>
                                        <input type="file" accept="image/*" class="d-none" id="photoInput3" v-on:change="onPhotoSelected($event, 3)" :disabled="mode === 'read'" />
                                        <button v-if="mode !== 'read'" type="button" class="btn btn-sm btn-outline-primary font-weight-bold" v-on:click="triggerPhotoUpload(3)">
                                            <i class="fas fa-camera mr-1"></i> 拍照 / 上傳照片
                                        </button>
                                    </template>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </main>

        <!-- 手機端常駐浮動動作列 (Sticky Bottom Bar) -->
        <div v-if="mode !== 'read'" class="mobile-bottom-bar d-xl-none no-print">
            <button type="button" class="btn btn-outline-primary font-weight-bold" v-on:click="openSignatureModal">
                <i class="fas fa-signature mr-1"></i> 手寫簽名
            </button>
            <button type="button" class="btn btn-primary font-weight-bold" v-on:click="submitForm">
                <i class="fas fa-check-circle mr-1"></i> 確定送出
            </button>
        </div>

        <!-- 全螢幕觸控平滑手寫簽名板 Modal -->
        <div v-if="showSigModal" class="fullscreen-sig-modal no-print">
            <div class="sig-modal-header">
                <div class="font-weight-bold text-dark" style="font-size: 1.05rem;">
                    <i class="fas fa-pen-nib text-primary mr-2"></i> 稽查人員手寫簽名
                </div>
                <button type="button" class="btn btn-sm btn-outline-secondary" v-on:click="closeSignatureModal">
                    <i class="fas fa-times"></i>
                </button>
            </div>

            <div class="sig-canvas-wrap">
                <canvas id="sigCanvas"></canvas>
            </div>

            <div class="sig-modal-footer">
                <button type="button" class="btn btn-outline-danger font-weight-bold px-3" v-on:click="clearCanvas">
                    <i class="fas fa-eraser mr-1"></i> 清除
                </button>
                <button type="button" class="btn btn-primary font-weight-bold px-4" v-on:click="saveSignature">
                    <i class="fas fa-check mr-1"></i> 完成簽署
                </button>
            </div>
        </div>

        <!-- 照片放大預覽 Modal -->
        <div v-if="bigPhotoUrl" class="modal fade show d-block" style="background: rgba(0,0,0,0.85); z-index: 2100;" v-on:click.self="bigPhotoUrl = ''">
            <div class="modal-dialog modal-dialog-centered modal-lg">
                <div class="modal-content bg-transparent border-0">
                    <div class="modal-header border-0 text-white">
                        <h5 class="modal-title font-weight-bold">{{ bigPhotoTitle }}</h5>
                        <button type="button" class="close text-white" v-on:click="bigPhotoUrl = ''">&times;</button>
                    </div>
                    <div class="modal-body text-center p-0">
                        <img :src="bigPhotoUrl" class="img-fluid rounded shadow" style="max-height: 80vh;" />
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- 本地化 JS 依賴 (避開機房資安 CSP 阻擋) -->
    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>
    <script src="../Scripts/leaflet/leaflet.js"></script>

    <script>
        const { createApp, markRaw } = Vue;

        createApp({
            data() {
                return {
                    mode: 'new',
                    alertMessage: '',
                    alertType: 'info',
                    isMapCollapsed: false,
                    siteFilterKeyword: '',
                    allSites: [],
                    showSigModal: false,
                    signatureUrl: '',
                    signatureBase64: '',
                    bigPhotoUrl: '',
                    bigPhotoTitle: '',
                    canvasCtx: null,
                    isDrawing: false,
                    lastX: 0,
                    lastY: 0,
                    hasDrawn: false,

                    form: {
                        Mode: 'new',
                        IsNewSite: false,
                        Bare_ID: '',
                        BareGroundNo: '',
                        ADDR: '',
                        Land_USE: '',
                        Latitude: '',
                        Longtitude: '',
                        INV_NO: 1,
                        Check_Date: '',
                        Check_Time: '',
                        InputUser: '',
                        Around_Memo: '',
                        Waste_Type: '',
                        pLength: '',
                        pWidth: '',
                        pHeight: '',
                        pVolume: '',
                        pArea: '',
                        surroundings: ''
                    },

                    // 四張照片容器
                    photos: [
                        { Index: 1, Title: '裸露地現場照片(一)', HasFile: false, PreviewUrl: '', Base64: '' },
                        { Index: 2, Title: '裸露地現場照片(二)', HasFile: false, PreviewUrl: '', Base64: '' },
                        { Index: 3, Title: '裸露地現場照片(三)', HasFile: false, PreviewUrl: '', Base64: '' },
                        { Index: 4, Title: '裸露地現場照片(四)', HasFile: false, PreviewUrl: '', Base64: '' }
                    ]
                };
            },
            computed: {
                filteredSites() {
                    if (!this.siteFilterKeyword.trim()) {
                        return this.allSites;
                    }
                    const kw = this.siteFilterKeyword.trim().toLowerCase();
                    return this.allSites.filter(s => {
                        const no = (s.BareGroundNo || '').toLowerCase();
                        const id = (s.Bare_ID || '').toLowerCase();
                        const addr = (s.ADDR || '').toLowerCase();
                        return no.includes(kw) || id.includes(kw) || addr.includes(kw);
                    });
                }
            },
            mounted() {
                // 解析 URL 參數
                const urlParams = new URLSearchParams(window.location.search);
                const reqMode = urlParams.get('mode') || 'new';
                this.mode = reqMode.toLowerCase();
                this.form.Mode = this.mode;

                const bareId = urlParams.get('id') || urlParams.get('bareId') || '';
                const invNo = urlParams.get('id2') || urlParams.get('invNo') || '';

                this.initMap();
                this.loadInitData(bareId, invNo);
            },
            methods: {
                // 初始化智慧地圖 (Leaflet)
                initMap() {
                    const defaultLat = 25.0169;
                    const defaultLng = 121.4627; // 新北市政府中心

                    // 臺灣通用電子地圖與正射影像
                    const emap = L.tileLayer('https://wmts.nlsc.gov.tw/wmts/EMAP/default/GoogleMapsCompatible/{z}/{y}/{x}', {
                        maxZoom: 20,
                        attribution: '&copy; 內政部國土測繪中心'
                    });

                    const photo2 = L.tileLayer('https://wmts.nlsc.gov.tw/wmts/PHOTO2/default/GoogleMapsCompatible/{z}/{y}/{x}', {
                        maxZoom: 20,
                        attribution: '&copy; 內政部國土測繪中心'
                    });

                    const osm = L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                        maxZoom: 19,
                        attribution: '&copy; OpenStreetMap'
                    });

                    const map = L.map('map', {
                        center: [defaultLat, defaultLng],
                        zoom: 13,
                        layers: [emap]
                    });

                    const baseLayers = {
                        "臺灣通用電子地圖": emap,
                        "衛星正射影像": photo2,
                        "OpenStreetMap": osm
                    };

                    L.control.layers(baseLayers, null, { position: 'topright' }).addTo(map);

                    // 隔離 Leaflet 原生實例，嚴禁進入 Vue 響應式系統 (防 project 崩潰)
                    this.leafletMap = markRaw(map);

                    // 地圖點擊事件更新坐標
                    map.on('click', (e) => {
                        if (this.mode === 'read') return;
                        this.setMarker(e.latlng.lat, e.latlng.lng);
                    });
                },

                // 設置地圖 Pin 標記
                setMarker(lat, lng) {
                    this.form.Latitude = Number(lat).toFixed(6);
                    this.form.Longtitude = Number(lng).toFixed(6);

                    if (this.leafletMarker) {
                        this.leafletMarker.setLatLng([lat, lng]);
                    } else {
                        const customIcon = L.divIcon({
                            className: 'custom-map-marker',
                            html: '<div class="marker-pin"><i class="fas fa-mountain marker-icon-inner"></i></div>',
                            iconSize: [32, 32],
                            iconAnchor: [16, 32]
                        });

                        const marker = L.marker([lat, lng], {
                            icon: customIcon,
                            draggable: this.mode !== 'read'
                        }).addTo(this.leafletMap);

                        marker.on('dragend', (ev) => {
                            const pos = ev.target.getLatLng();
                            this.form.Latitude = Number(pos.lat).toFixed(6);
                            this.form.Longtitude = Number(pos.lng).toFixed(6);
                        });

                        this.leafletMarker = markRaw(marker);
                    }

                    this.leafletMap.panTo([lat, lng]);
                },

                // 載入初始清單與既有資料
                loadInitData(bareId, invNo) {
                    axios.get('NewBare.aspx?action=getinit')
                        .then(res => {
                            if (res.data.Success) {
                                this.allSites = res.data.BareSites || [];
                                this.form.Check_Date = res.data.DefaultDate;
                                this.form.Check_Time = res.data.DefaultTime;
                                this.form.InputUser = res.data.CurrentUser || '系統查核員';

                                if (this.mode === 'new') {
                                    if (bareId) {
                                        this.form.Bare_ID = bareId;
                                        this.onSiteSelected();
                                    }
                                } else {
                                    // 讀取特定查核案件
                                    this.loadCaseData(bareId, invNo);
                                }
                            } else {
                                this.showAlert(res.data.Message, 'danger');
                            }
                        })
                        .catch(err => {
                            this.showAlert('載入基礎資料失敗：' + err.message, 'danger');
                        });
                },

                // 讀取既有案件資料 (edit / read)
                loadCaseData(bareId, invNo) {
                    axios.get(`NewBare.aspx?action=getcase&bareId=${encodeURIComponent(bareId)}&invNo=${encodeURIComponent(invNo)}`)
                        .then(res => {
                            if (res.data.Success) {
                                const d = res.data.Data;
                                this.form.Bare_ID = d.Bare_ID || '';
                                this.form.BareGroundNo = d.BareGroundNo || '';
                                this.form.ADDR = d.ADDR || '';
                                this.form.Land_USE = d.Land_USE || '';
                                this.form.Latitude = d.Latitude || '';
                                this.form.Longtitude = d.Longtitude || '';
                                this.form.INV_NO = d.INV_NO || 1;
                                this.form.Check_Date = d.Check_Date || '';
                                this.form.Check_Time = d.Check_Time || '';
                                this.form.InputUser = d.InputUser || '';
                                this.form.Around_Memo = d.Around_Memo || '';
                                this.form.Waste_Type = d.Waste_Type || '';
                                this.form.pLength = d.pLength || '';
                                this.form.pWidth = d.pWidth || '';
                                this.form.pHeight = d.pHeight || '';
                                this.form.pVolume = d.pVolume || '';
                                this.form.pArea = d.pArea || '';
                                this.form.surroundings = d.surroundings || '';

                                // 照片填入
                                if (d.Photos && d.Photos.length > 0) {
                                    d.Photos.forEach((p, idx) => {
                                        if (idx < 4) {
                                            this.photos[idx].HasFile = p.HasFile;
                                            this.photos[idx].PreviewUrl = p.Url;
                                        }
                                    });
                                }

                                // 簽名填入
                                this.signatureUrl = d.SignatureUrl || '';
                                this.signatureBase64 = d.SignatureBase64 || '';

                                // 地圖定位
                                if (d.Latitude && d.Longtitude) {
                                    const lat = parseFloat(d.Latitude);
                                    const lng = parseFloat(d.Longtitude);
                                    if (lat > 0 && lng > 0) {
                                        this.setMarker(lat, lng);
                                        this.leafletMap.setView([lat, lng], 16);
                                    }
                                }
                            } else {
                                this.showAlert(res.data.Message, 'danger');
                            }
                        })
                        .catch(err => {
                            this.showAlert('讀取案件失敗：' + err.message, 'danger');
                        });
                },

                // 選取既有場址時自動帶入資訊與地圖跳轉
                onSiteSelected() {
                    if (!this.form.Bare_ID) return;
                    const site = this.allSites.find(s => s.Bare_ID === this.form.Bare_ID);
                    if (site) {
                        this.form.BareGroundNo = site.BareGroundNo || '';
                        this.form.ADDR = site.ADDR || '';
                        this.form.Land_USE = site.Land_USE || '';
                        if (site.Latitude && site.Longtitude) {
                            const lat = parseFloat(site.Latitude);
                            const lng = parseFloat(site.Longtitude);
                            if (lat > 0 && lng > 0) {
                                this.setMarker(lat, lng);
                                this.leafletMap.setView([lat, lng], 16);
                            }
                        }
                    }
                },

                // 場址模式切換 (既有 vs 新建)
                switchSiteMode(isNew) {
                    this.form.IsNewSite = isNew;
                    if (isNew) {
                        this.form.Bare_ID = '';
                        this.form.BareGroundNo = '';
                        this.form.ADDR = '';
                        this.form.Land_USE = '';
                    }
                },

                // 常用片語插入
                insertPhrase(fieldName, phrase) {
                    if (this.mode === 'read') return;
                    let current = this.form[fieldName] || '';
                    if (current && !current.endsWith('\n') && !current.endsWith('；') && !current.endsWith('，')) {
                        current += '；';
                    }
                    this.form[fieldName] = current + phrase;
                },

                // 體積快速計算公式
                calcVolume(type) {
                    const l = parseFloat(this.form.pLength) || 0;
                    const w = parseFloat(this.form.pWidth) || 0;
                    const h = parseFloat(this.form.pHeight) || 0;
                    if (l <= 0 || w <= 0 || h <= 0) {
                        this.showAlert('請先填寫長、寬、高尺寸！', 'warning');
                        return;
                    }
                    let vol = 0;
                    if (type === 'cube') vol = l * w * h;
                    else if (type === 'slope') vol = l * w * h * 0.6;
                    else if (type === 'cone') vol = l * w * h * 0.33;
                    this.form.pVolume = Number(vol.toFixed(1));
                    this.showAlert(`已套用${type === 'cube' ? '長方體' : (type === 'slope' ? '斜坡台' : '圓錐體')}公式估算堆置量！`, 'success');
                },

                // 面積快速計算
                calcArea() {
                    const l = parseFloat(this.form.pLength) || 0;
                    const w = parseFloat(this.form.pWidth) || 0;
                    if (l <= 0 || w <= 0) {
                        this.showAlert('請先填寫長度與寬度尺寸！', 'warning');
                        return;
                    }
                    this.form.pArea = Number((l * w).toFixed(1));
                    this.showAlert('已自動計算場址面積 (長×寬)！', 'success');
                },

                autoEstimateVolume() {
                    // 若使用者尚未輸入體積，可即時推算矩形
                    const l = parseFloat(this.form.pLength) || 0;
                    const w = parseFloat(this.form.pWidth) || 0;
                    const h = parseFloat(this.form.pHeight) || 0;
                    if (l > 0 && w > 0 && !this.form.pArea) {
                        this.form.pArea = Number((l * w).toFixed(1));
                    }
                    if (l > 0 && w > 0 && h > 0 && !this.form.pVolume) {
                        this.form.pVolume = Number((l * w * h).toFixed(1));
                    }
                },

                // 手機 GPS 定位
                getCurrentLocation() {
                    if (!("geolocation" in navigator)) {
                        this.showAlert('此裝置或瀏覽器不支援 GPS 定位！', 'danger');
                        return;
                    }
                    this.showAlert('正在連線 GPS 衛星定位中...', 'info');
                    navigator.geolocation.getCurrentPosition(
                        pos => {
                            const lat = pos.coords.latitude;
                            const lng = pos.coords.longitude;
                            this.setMarker(lat, lng);
                            this.leafletMap.setView([lat, lng], 17);
                            this.showAlert('GPS 定位成功！已更新查核點位坐標。', 'success');
                        },
                        err => {
                            this.showAlert('定位失敗：' + err.message + '，請確認已授權定位權限。', 'warning');
                        },
                        { enableHighAccuracy: true, timeout: 10000 }
                    );
                },

                // 重設地圖全景
                resetMapView() {
                    if (this.form.Latitude && this.form.Longtitude) {
                        this.leafletMap.setView([this.form.Latitude, this.form.Longtitude], 16);
                    } else {
                        this.leafletMap.setView([25.0169, 121.4627], 13);
                    }
                },

                // 手機版地圖收合/展開
                toggleMapCollapse() {
                    this.isMapCollapsed = !this.isMapCollapsed;
                    setTimeout(() => {
                        if (this.leafletMap) this.leafletMap.invalidateSize();
                    }, 320);
                },

                formatCoordinates() {
                    if (this.form.Latitude && this.form.Longtitude) {
                        return `${Number(this.form.Latitude).toFixed(4)}, ${Number(this.form.Longtitude).toFixed(4)}`;
                    }
                    return '未定位';
                },

                // 照片觸發上傳
                triggerPhotoUpload(idx) {
                    const input = document.getElementById('photoInput' + idx);
                    if (input) input.click();
                },

                // 照片選取並前端 Canvas 壓縮
                onPhotoSelected(event, idx) {
                    const file = event.target.files[0];
                    if (!file) return;

                    const reader = new FileReader();
                    reader.onload = (e) => {
                        const img = new Image();
                        img.onload = () => {
                            const canvas = document.createElement('canvas');
                            const maxDim = 1600;
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

                            // 輸出高品質 JPEG Base64
                            const compressedBase64 = canvas.toDataURL('image/jpeg', 0.82);
                            this.photos[idx].PreviewUrl = compressedBase64;
                            this.photos[idx].Base64 = compressedBase64;
                            this.photos[idx].HasFile = true;
                            this.showAlert(`已載入【${this.photos[idx].Title}】，前端自動壓縮完成！`, 'success');
                        };
                        img.src = e.target.result;
                    };
                    reader.readAsDataURL(file);
                },

                // 移除照片
                removePhoto(idx) {
                    this.photos[idx].PreviewUrl = '';
                    this.photos[idx].Base64 = '';
                    this.photos[idx].HasFile = false;
                    const input = document.getElementById('photoInput' + idx);
                    if (input) input.value = '';
                },

                previewBigPhoto(url, title) {
                    this.bigPhotoUrl = url;
                    this.bigPhotoTitle = title;
                },

                // 簽名板開關與邏輯 (PointerEvents + 貝茲平滑)
                openSignatureModal() {
                    this.showSigModal = true;
                    this.$nextTick(() => {
                        this.initSigCanvas();
                    });
                },

                closeSignatureModal() {
                    this.showSigModal = false;
                },

                initSigCanvas() {
                    const canvas = document.getElementById('sigCanvas');
                    if (!canvas) return;
                    const container = canvas.parentElement;
                    const rect = container.getBoundingClientRect();
                    const dpr = window.devicePixelRatio || 1;

                    canvas.width = Math.round(rect.width * dpr);
                    canvas.height = Math.round(rect.height * dpr);
                    canvas.style.width = rect.width + 'px';
                    canvas.style.height = rect.height + 'px';

                    this.canvasCtx = canvas.getContext('2d');
                    this.canvasCtx.scale(dpr, dpr);
                    this.canvasCtx.strokeStyle = '#0f172a';
                    this.canvasCtx.lineWidth = 3.5;
                    this.canvasCtx.lineCap = 'round';
                    this.canvasCtx.lineJoin = 'round';
                    this.hasDrawn = false;

                    const getPos = e => {
                        const r = canvas.getBoundingClientRect();
                        return { x: e.clientX - r.left, y: e.clientY - r.top };
                    };

                    const down = e => {
                        e.preventDefault();
                        try { canvas.setPointerCapture(e.pointerId); } catch (err) {}
                        this.isDrawing = true;
                        this.hasDrawn = true;
                        const pos = getPos(e);
                        this.lastX = pos.x;
                        this.lastY = pos.y;
                        this.canvasCtx.beginPath();
                        this.canvasCtx.moveTo(this.lastX, this.lastY);
                    };

                    const move = e => {
                        if (!this.isDrawing) return;
                        e.preventDefault();
                        const pos = getPos(e);
                        const midX = (this.lastX + pos.x) / 2;
                        const midY = (this.lastY + pos.y) / 2;
                        this.canvasCtx.quadraticCurveTo(this.lastX, this.lastY, midX, midY);
                        this.canvasCtx.stroke();
                        this.lastX = pos.x;
                        this.lastY = pos.y;
                    };

                    const up = e => {
                        if (!this.isDrawing) return;
                        this.isDrawing = false;
                        try { canvas.releasePointerCapture(e.pointerId); } catch (err) {}
                        this.canvasCtx.lineTo(this.lastX, this.lastY);
                        this.canvasCtx.stroke();
                        this.canvasCtx.closePath();
                    };

                    canvas.addEventListener('pointerdown', down, { passive: false });
                    canvas.addEventListener('pointermove', move, { passive: false });
                    canvas.addEventListener('pointerup', up, { passive: false });
                    canvas.addEventListener('pointercancel', up, { passive: false });
                },

                clearCanvas() {
                    const canvas = document.getElementById('sigCanvas');
                    if (canvas && this.canvasCtx) {
                        this.canvasCtx.clearRect(0, 0, canvas.width, canvas.height);
                        this.hasDrawn = false;
                    }
                },

                saveSignature() {
                    const canvas = document.getElementById('sigCanvas');
                    if (!this.hasDrawn) {
                        this.showAlert('請先在畫布上手寫簽名！', 'warning');
                        return;
                    }
                    this.signatureBase64 = canvas.toDataURL('image/png');
                    this.showSigModal = false;
                    this.showAlert('稽查人員簽名完成！', 'success');
                },

                clearSignature() {
                    this.signatureBase64 = '';
                    this.signatureUrl = '';
                },

                // 表單送出
                submitForm() {
                    if (this.form.IsNewSite && !this.form.BareGroundNo.trim()) {
                        this.showAlert('請輸入新場址編號！', 'danger');
                        return;
                    }
                    if (!this.form.IsNewSite && !this.form.Bare_ID) {
                        this.showAlert('請選取裸露地場址！', 'danger');
                        return;
                    }
                    if (!this.form.Check_Date) {
                        this.showAlert('請填寫查核日期！', 'danger');
                        return;
                    }
                    if (!this.signatureBase64 && !this.signatureUrl) {
                        this.showAlert('請先完成稽查人員手寫簽名！', 'warning');
                        this.openSignatureModal();
                        return;
                    }

                    const payload = {
                        ...this.form,
                        Signature: this.signatureBase64,
                        Photos: this.photos.map(p => ({
                            Index: p.Index,
                            Title: p.Title,
                            Base64: p.Base64
                        }))
                    };

                    this.showAlert('正在儲存巡查紀錄，請稍候...', 'info');

                    axios.post('NewBare.aspx?action=save', payload)
                        .then(res => {
                            if (res.data.Success) {
                                alert(res.data.Message || '儲存成功！');
                                window.location.href = 'Bare_List.aspx?mode=reject';
                            } else {
                                this.showAlert(res.data.Message || '儲存失敗', 'danger');
                            }
                        })
                        .catch(err => {
                            this.showAlert('送出異常：' + err.message, 'danger');
                        });
                },

                printCase() {
                    window.print();
                },

                goBack() {
                    if (window.history.length > 1) {
                        window.history.back();
                    } else {
                        window.location.href = 'Bare_List.aspx?mode=reject';
                    }
                },

                showAlert(msg, type = 'info') {
                    this.alertMessage = msg;
                    this.alertType = type;
                    setTimeout(() => {
                        if (this.alertMessage === msg) {
                            this.alertMessage = '';
                        }
                    }, 4000);
                }
            }
        }).mount('#app');
    </script>
</body>
</html>
