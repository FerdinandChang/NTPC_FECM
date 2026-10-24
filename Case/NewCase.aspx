<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="NewCase.aspx.cs" Inherits="NTPC_FEC.Case.NewCase" %>

<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定溢散源管理平台 - 固定污染源逸散防制設施巡查記錄表</title>

    <!-- 專屬 Favicon -->
    <link rel="shortcut icon" href="../favicon.ico" type="image/x-icon" />

    <!-- Bootstrap 4 & FontAwesome 本地化樣式 -->
    <link rel="stylesheet" href="../Content/bootstrap.min.css" />
    <link rel="stylesheet" href="../Content/fontawesome/css/all.min.css" />

    <!-- Leaflet.js 本地化樣式 -->
    <link rel="stylesheet" href="../Content/leaflet/leaflet.css" />

    <style>
        :root {
            --brand-primary: #0099e5;
            --brand-blue: #0284c7;
            --brand-dark-blue: #0b1f7d;
            --brand-navy: #0f172a;
            --bg-canvas: #f1f5f9;
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
        }

        [v-cloak] {
            display: none !important;
        }

        /* 置頂導覽列 */
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

        .brand-title {
            font-size: 1.05rem;
            font-weight: 700;
            margin: 0;
            display: flex;
            align-items: center;
            gap: 8px;
        }

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
            transition: border-color 0.2s, box-shadow 0.2s;
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
                top: 72px;
                max-height: calc(100vh - 88px);
                overflow-y: auto;
                padding-right: 4px;
            }
        }

        /* 地圖控制與收合 */
        #map {
            width: 100%;
            height: 280px;
            border-radius: 8px;
            z-index: 10;
            transition: height 0.3s ease;
        }

        #map.map-collapsed {
            height: 80px !important;
        }

        /* 記點晶片儀表板 */
        .loss-badge-score {
            font-size: 1.6rem;
            font-weight: 800;
            line-height: 1;
        }

        /* 項目記點切換晶片 (Score Chips) */
        .chip-group {
            display: flex;
            flex-wrap: wrap;
            gap: 8px;
            margin-bottom: 12px;
        }

        .score-chip-btn {
            border: 1px solid #cbd5e1;
            background: #ffffff;
            color: #334155;
            padding: 8px 16px;
            border-radius: 8px;
            font-size: 13px;
            font-weight: 600;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            gap: 6px;
            min-height: 40px;
            transition: all 0.15s ease;
        }

        .score-chip-btn:hover {
            border-color: #94a3b8;
            background-color: #f8fafc;
        }

        .score-chip-btn.active-0 {
            background: #ecfdf5;
            border-color: #10b981;
            color: #047857;
            font-weight: 700;
            box-shadow: 0 0 0 2px rgba(16, 185, 129, 0.2);
        }

        .score-chip-btn.active-4 {
            background: #fffbeb;
            border-color: #f59e0b;
            color: #b45309;
            font-weight: 700;
            box-shadow: 0 0 0 2px rgba(245, 158, 11, 0.2);
        }

        .score-chip-btn.active-10 {
            background: #fef2f2;
            border-color: #ef4444;
            color: #b91c1c;
            font-weight: 700;
            box-shadow: 0 0 0 2px rgba(239, 68, 68, 0.2);
        }

        /* 缺失細項勾選面板 */
        .subitem-box {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 12px 14px;
            margin-bottom: 12px;
        }

        .custom-chk-row {
            display: flex;
            align-items: flex-start;
            gap: 10px;
            padding: 6px 0;
            border-bottom: 1px dashed #e2e8f0;
        }

        .custom-chk-row:last-child {
            border-bottom: none;
        }

        .custom-chk-row input[type="checkbox"] {
            width: 18px;
            height: 18px;
            margin-top: 3px;
            cursor: pointer;
            accent-color: #0284c7;
        }

        .custom-chk-label {
            font-size: 13.5px;
            color: #334155;
            margin: 0;
            cursor: pointer;
            line-height: 1.5;
            flex: 1;
        }

        .child-chk-group {
            padding-left: 28px;
            margin-top: 4px;
        }

        /* 照片上傳卡片與預覽 */
        .photo-upload-section {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
            gap: 12px;
            margin-top: 10px;
        }

        .photo-card {
            background: #ffffff;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 10px;
            display: flex;
            flex-direction: column;
            gap: 6px;
        }

        .photo-card-title {
            font-size: 12.5px;
            font-weight: 700;
            color: #475569;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .photo-thumb-box {
            width: 100%;
            height: 140px;
            border-radius: 6px;
            background: #f1f5f9;
            border: 1px dashed #cbd5e1;
            display: flex;
            align-items: center;
            justify-content: center;
            position: relative;
            overflow: hidden;
            cursor: pointer;
        }

        .photo-thumb-img {
            width: 100%;
            height: 140px;
            object-fit: cover;
            border-radius: 6px;
        }

        .photo-btn-group {
            display: flex;
            gap: 6px;
            margin-top: 4px;
        }

        .photo-btn-group .btn {
            flex: 1;
            font-size: 11px;
            padding: 4px 6px;
        }

        /* 現場狀況開關 (Segmented Yes/No) */
        .status-toggle-row {
            display: flex;
            align-items: center;
            justify-content: space-between;
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 8px 12px;
            margin-bottom: 8px;
        }

        .segmented-group {
            display: inline-flex;
            background: #e2e8f0;
            padding: 3px;
            border-radius: 8px;
            gap: 2px;
        }

        .segment-btn {
            border: none;
            background: transparent;
            padding: 6px 14px;
            border-radius: 6px;
            font-size: 13px;
            font-weight: 600;
            color: #475569;
            cursor: pointer;
            min-height: 32px;
        }

        .segment-btn.active-blue {
            background: #0284c7;
            color: #ffffff;
            box-shadow: 0 1px 4px rgba(2, 132, 199, 0.35);
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

        /* 全螢幕平滑手寫簽名板 */
        .sig-modal-backdrop {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(15, 23, 42, 0.75);
            backdrop-filter: blur(4px);
            z-index: 2000;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 12px;
        }

        .sig-modal-container {
            background: #ffffff;
            border-radius: 12px;
            width: 100%;
            max-width: 640px;
            overflow: hidden;
            box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.3);
            display: flex;
            flex-direction: column;
        }

        .sig-canvas-wrapper {
            background: #f8fafc;
            border: 2px dashed #94a3b8;
            margin: 12px;
            border-radius: 8px;
            height: 260px;
            touch-action: none;
            position: relative;
        }

        #sigCanvas {
            width: 100%;
            height: 100%;
            display: block;
            cursor: crosshair;
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

        /* 模態彈窗 (設備/製程清單) */
        .modal-custom-backdrop {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(15, 23, 42, 0.65);
            z-index: 1999;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 16px;
        }

        .modal-custom-box {
            background: #ffffff;
            border-radius: 12px;
            width: 100%;
            max-width: 800px;
            max-height: 85vh;
            display: flex;
            flex-direction: column;
            overflow: hidden;
            box-shadow: 0 10px 25px rgba(0, 0, 0, 0.2);
        }

        .modal-custom-body {
            padding: 16px;
            overflow-y: auto;
        }

        /* 燈箱大圖預覽 */
        .lightbox-modal {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(0, 0, 0, 0.9);
            z-index: 2500;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 16px;
            cursor: zoom-out;
        }

        .lightbox-img {
            max-width: 95vw;
            max-height: 90vh;
            border-radius: 8px;
            box-shadow: 0 5px 25px rgba(0, 0, 0, 0.5);
        }
    </style>
</head>
<body>
    <div id="newCaseApp" v-cloak>
        <!-- 1. 置頂深青藍漸層導覽列 -->
        <header class="top-navbar no-print">
            <div class="d-flex align-items-center">
                <a href="javascript:void(0)" class="nav-btn mr-2" v-on:click="goBack">
                    <i class="fas fa-arrow-left"></i>
                    <span class="d-none d-sm-inline">返回清單</span>
                </a>
                <h1 class="brand-title">
                    <i class="fas fa-industry text-white"></i>
                    <span>公私場所現場巡查記錄表</span>
                    <span v-if="facInfo.C_NO" class="badge badge-light text-dark font-weight-bold ml-1" style="font-size: 0.82rem;">
                        {{ facInfo.C_NO }}
                    </span>
                    <span class="badge ml-1" :class="mode === 'new_re' ? 'badge-warning' : (mode === 'edit' ? 'badge-info' : 'badge-primary')" style="font-size: 0.78rem;">
                        {{ mode === 'new_re' ? '改善複查' : (mode === 'edit' ? ('編輯查核 #' + invNo) : '例行巡查') }}
                    </span>
                </h1>
            </div>

            <div class="d-flex align-items-center gap-2">
                <button type="button" class="nav-btn d-none d-md-inline-flex" v-on:click="quickPassAll" title="一鍵全部合格">
                    <i class="fas fa-bolt text-warning"></i>
                    <span>一鍵全部合格</span>
                </button>
                <button type="button" class="nav-btn bg-white text-dark shadow-sm" v-on:click="submitData" :disabled="saving">
                    <i class="fas" :class="saving ? 'fa-spinner fa-spin' : 'fa-save'"></i>
                    <span class="font-weight-bold">{{ saving ? '儲存中...' : '儲存巡查' }}</span>
                </button>
            </div>
        </header>

        <!-- 主作業容器 -->
        <main class="container-fluid-custom">
            <!-- 載入中骨架屏遮罩 -->
            <div v-if="loading" class="text-center py-5">
                <div class="spinner-border text-primary" style="width: 3rem; height: 3rem;" role="status"></div>
                <div class="text-muted mt-2 font-weight-bold">正在載入公私場所查核資料，請稍候...</div>
            </div>

            <!-- 錯誤提示 -->
            <div v-if="errorMessage" class="alert alert-danger shadow-sm mb-3">
                <i class="fas fa-exclamation-triangle mr-2"></i> {{ errorMessage }}
            </div>

            <!-- 主雙欄內容 -->
            <div v-if="!loading" class="row">
                <!-- 左欄 (40% 寬度，Sticky 固頂側欄) -->
                <div class="col-xl-5 col-lg-5 col-md-12 mb-3">
                    <div class="sticky-sidebar">
                        <!-- A. 場所基本資料卡片 -->
                        <div class="card-modern">
                            <div class="card-modern-header">
                                <h3 class="card-modern-title">
                                    <i class="fas fa-building text-primary"></i>
                                    <span>{{ facInfo.FAC_NAME || '公私場所資訊' }}</span>
                                </h3>
                                <button type="button" class="btn btn-sm btn-outline-info" v-on:click="openDeviceModal">
                                    <i class="fas fa-cogs mr-1"></i> 申報設備
                                </button>
                            </div>
                            <div class="card-modern-body p-3">
                                <div class="row">
                                    <div class="col-6 mb-2">
                                        <small class="text-muted d-block">管制編號</small>
                                        <strong class="text-dark">{{ facInfo.C_NO || '-' }}</strong>
                                    </div>
                                    <div class="col-6 mb-2">
                                        <small class="text-muted d-block">負責人</small>
                                        <strong class="text-dark">{{ facInfo.BOSS_NAME || '-' }}</strong>
                                    </div>
                                    <div class="col-12 mb-2">
                                        <small class="text-muted d-block">廠址 / 地段號</small>
                                        <span class="text-dark font-weight-bold">{{ facInfo.ADDR || '-' }}</span>
                                        <small v-if="facInfo.Land_no" class="text-muted d-block">({{ facInfo.Land_no }})</small>
                                    </div>
                                    <div class="col-6 mb-1">
                                        <small class="text-muted d-block">聯絡電話</small>
                                        <span class="text-dark">{{ facInfo.TEL || '-' }}</span>
                                    </div>
                                    <div class="col-6 mb-1">
                                        <small class="text-muted d-block">查核人員</small>
                                        <span class="badge badge-secondary">{{ loginUser }}</span>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- B. 智慧現場地圖卡片 (Leaflet.js) -->
                        <div class="card-modern">
                            <div class="card-modern-header">
                                <h3 class="card-modern-title">
                                    <i class="fas fa-map-marked-alt text-info"></i>
                                    <span>現場地圖導航</span>
                                </h3>
                                <div class="d-flex align-items-center gap-1">
                                    <button type="button" class="btn btn-xs btn-outline-secondary py-1 px-2" v-on:click="toggleMapCollapse">
                                        <i class="fas" :class="mapCollapsed ? 'fa-expand-arrows-alt' : 'fa-compress-arrows-alt'"></i>
                                        <span class="d-none d-sm-inline">{{ mapCollapsed ? '展開' : '收合' }}</span>
                                    </button>
                                    <button v-if="facInfo.Lat && facInfo.Lng" type="button" class="btn btn-xs btn-outline-success py-1 px-2" v-on:click="openGoogleNavigation">
                                        <i class="fas fa-location-arrow"></i> 導航
                                    </button>
                                    <button type="button" class="btn btn-xs btn-outline-primary py-1 px-2" v-on:click="locateGPS">
                                        <i class="fas fa-crosshairs"></i> GPS
                                    </button>
                                </div>
                            </div>
                            <div class="card-modern-body p-2">
                                <div id="map" :class="{ 'map-collapsed': mapCollapsed }"></div>
                                <div v-if="userDistance !== null" class="mt-2 text-center">
                                    <small class="text-muted font-weight-bold">
                                        <i class="fas fa-walking text-primary mr-1"></i> 您距離該場所約
                                        <span class="text-primary font-weight-bold">{{ userDistanceText }}</span>
                                    </small>
                                </div>
                            </div>
                        </div>

                        <!-- C. 即時計點儀表板 (Loss Point Dashboard) -->
                        <div class="card-modern border-top-primary">
                            <div class="card-modern-header bg-light">
                                <h3 class="card-modern-title">
                                    <i class="fas fa-clipboard-check text-success"></i>
                                    <span>即時計點儀表板</span>
                                </h3>
                                <button type="button" class="btn btn-xs btn-warning font-weight-bold py-1 px-2" v-on:click="quickPassAll">
                                    <i class="fas fa-bolt mr-1"></i> 全項0點
                                </button>
                            </div>
                            <div class="card-modern-body p-3">
                                <div class="d-flex align-items-center justify-content-between mb-3">
                                    <div>
                                        <span class="text-muted d-block font-weight-bold">目前累計記點</span>
                                        <div class="d-flex align-items-baseline gap-2">
                                            <span class="loss-badge-score" :class="totalLossPoints >= 10 ? 'text-danger' : (totalLossPoints > 0 ? 'text-warning' : 'text-success')">
                                                {{ totalLossPoints }}
                                            </span>
                                            <span class="font-weight-bold text-muted">點</span>
                                        </div>
                                    </div>
                                    <div>
                                        <span v-if="totalLossPoints === 0" class="badge badge-success p-2 font-weight-bold">
                                            <i class="fas fa-check-circle mr-1"></i> 全部符合規定 (0點)
                                        </span>
                                        <span v-else-if="totalLossPoints < 10" class="badge badge-warning p-2 font-weight-bold text-dark">
                                            <i class="fas fa-exclamation-circle mr-1"></i> 記缺失 {{ totalLossPoints }} 點 (未達告發)
                                        </span>
                                        <span v-else class="badge badge-danger p-2 font-weight-bold">
                                            <i class="fas fa-radiation mr-1"></i> 達告發裁處門檻 ({{ totalLossPoints }}點)
                                        </span>
                                    </div>
                                </div>

                                <!-- 各大項記點微縮膠囊 -->
                                <div class="d-flex flex-wrap gap-1">
                                    <div v-for="sec in sectionLossList" :key="sec.id" class="badge p-1 px-2 font-weight-normal border"
                                         :class="sec.loss > 0 ? (sec.loss >= 10 ? 'badge-danger' : 'badge-warning text-dark') : 'badge-light text-muted'">
                                        {{ sec.shortTitle }}: <strong>{{ sec.loss }}點</strong>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- D. 電子簽名板卡片 -->
                        <div class="card-modern">
                            <div class="card-modern-header">
                                <h3 class="card-modern-title">
                                    <i class="fas fa-signature text-secondary"></i>
                                    <span>電子查核簽名</span>
                                </h3>
                                <button type="button" class="btn btn-sm btn-outline-primary" v-on:click="openSignatureModal">
                                    <i class="fas fa-pen-alt mr-1"></i> 觸控手寫簽名
                                </button>
                            </div>
                            <div class="card-modern-body p-3">
                                <div class="row text-center">
                                    <div class="col-6">
                                        <small class="text-muted d-block mb-1 font-weight-bold">稽查員簽章</small>
                                        <div class="border rounded bg-light p-1" style="height: 70px; display: flex; align-items: center; justify-content: center;">
                                            <img v-if="signatures.inspector" :src="signatures.inspector" style="max-height: 60px; max-width: 100%;" />
                                            <span v-else class="text-muted small"><i class="fas fa-pen mr-1"></i> 尚未簽名</span>
                                        </div>
                                    </div>
                                    <div class="col-6">
                                        <small class="text-muted d-block mb-1 font-weight-bold">受訪代表簽名</small>
                                        <div class="border rounded bg-light p-1" style="height: 70px; display: flex; align-items: center; justify-content: center;">
                                            <img v-if="signatures.representative" :src="signatures.representative" style="max-height: 60px; max-width: 100%;" />
                                            <span v-else class="text-muted small"><i class="fas fa-pen mr-1"></i> 現場代表簽名</span>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- 右欄 (60% 寬度，主檢核作業區) -->
                <div class="col-xl-7 col-lg-7 col-md-12">
                    <!-- 1. 查核基本設定卡片 -->
                    <div class="card-modern">
                        <div class="card-modern-header">
                            <h3 class="card-modern-title">
                                <i class="fas fa-calendar-check text-primary"></i>
                                <span>查核基本設定</span>
                            </h3>
                        </div>
                        <div class="card-modern-body p-3">
                            <div class="row">
                                <div class="col-md-6 col-12 mb-3">
                                    <label class="font-weight-bold small text-muted">查核日期及時間</label>
                                    <div class="input-group">
                                        <input type="date" class="form-control" v-model="form.INV_DATE" />
                                        <input type="time" class="form-control" v-model="form.INV_TIME" style="max-width: 140px;" />
                                    </div>
                                </div>
                                <div class="col-md-6 col-12 mb-3">
                                    <label class="font-weight-bold small text-muted">現場天氣狀況</label>
                                    <div class="segmented-group d-flex w-100">
                                        <button v-for="w in ['晴', '陰', '雨']" :key="w" type="button" 
                                                class="segment-btn flex-fill" 
                                                :class="{ 'active-blue': form.weather === w }"
                                                v-on:click="form.weather = w">
                                            {{ w }}
                                        </button>
                                    </div>
                                </div>
                                <div class="col-12 mb-3">
                                    <label class="font-weight-bold small text-muted">公私場所操作狀況</label>
                                    <div class="segmented-group d-flex w-100 mb-2">
                                        <button v-for="ws in ['正常操作', '停工', '歇業']" :key="ws" type="button" 
                                                class="segment-btn flex-fill" 
                                                :class="{ 'active-blue': form.Work_State === ws }"
                                                v-on:click="form.Work_State = ws">
                                            {{ ws }}
                                        </button>
                                    </div>
                                    <textarea class="form-control" rows="2" placeholder="請填寫操作狀況概述說明..." v-model="form.Work_Memo"></textarea>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- 2. 審查意見歷程卡片 (若有退回或審查紀錄) -->
                    <div v-if="reviewList.length > 0" class="card-modern border-warning">
                        <div class="card-modern-header bg-warning text-dark py-2">
                            <h3 class="card-modern-title font-weight-bold" style="font-size: 0.95rem;">
                                <i class="fas fa-history mr-1"></i> 歷次審查紀錄與退回意見
                            </h3>
                        </div>
                        <div class="card-modern-body p-0">
                            <div class="table-responsive mb-0">
                                <table class="table table-sm table-striped mb-0 small">
                                    <thead class="thead-light">
                                        <tr>
                                            <th>審查日期</th>
                                            <th>審查階段</th>
                                            <th>結果</th>
                                            <th>意見備註</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <tr v-for="(rev, idx) in reviewList" :key="idx">
                                            <td>{{ rev.Chk_Date }}</td>
                                            <td><span class="badge badge-secondary">{{ rev.INV_State_Str }}</span></td>
                                            <td><strong :class="rev.Chk_Result === '通過' ? 'text-success' : 'text-danger'">{{ rev.Chk_Result }}</strong></td>
                                            <td>{{ rev.Chk_Memo || '無意見' }}</td>
                                        </tr>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>

                    <!-- 3. 十一大項防制措施卡片清單 -->

                    <!-- 項目一：堆置逸散性粒狀污染物質 (第4條) -->
                    <div class="card-modern" :id="'sec-01'">
                        <div class="card-modern-header">
                            <h3 class="card-modern-title">
                                <i class="fas fa-cubes text-info"></i>
                                <span>一、堆置逸散性粒狀污染物質 (第4條)</span>
                            </h3>
                            <span class="badge" :class="getSectionLoss(1) > 0 ? (getSectionLoss(1) >= 10 ? 'badge-danger' : 'badge-warning') : 'badge-success'">
                                {{ getSectionLoss(1) }} 點
                            </span>
                        </div>
                        <div class="card-modern-body p-3">
                            <div class="chip-group">
                                <button type="button" class="score-chip-btn" :class="{ 'active-0': form.INV_01_02 === 'V' }" v-on:click="setSectionScore(1, 0, 'INV_01_02')">
                                    <i class="fas fa-check-circle"></i> 合規設置 (0點)
                                </button>
                                <button type="button" class="score-chip-btn" :class="{ 'active-0': form.INV_01_01 === 'V' }" v-on:click="setSectionScore(1, 0, 'INV_01_01')">
                                    <i class="fas fa-ban"></i> 無本製程 (0點)
                                </button>
                                <button type="button" class="score-chip-btn" :class="{ 'active-4': getSectionLoss(1) === 4 }" v-on:click="setSectionScore(1, 4)">
                                    <i class="fas fa-exclamation-circle"></i> 規格瑕疵 (4點)
                                </button>
                                <button type="button" class="score-chip-btn" :class="{ 'active-10': getSectionLoss(1) === 10 }" v-on:click="setSectionScore(1, 10)">
                                    <i class="fas fa-times-circle"></i> 未設置防制設施 (10點)
                                </button>
                            </div>

                            <!-- 替代方法說明 (若勾選 01_03) -->
                            <div class="custom-chk-row">
                                <input type="checkbox" id="chk_01_03" v-model="chkForm.INV_01_03" v-on:change="onChkChange('INV_01_03')" />
                                <label for="chk_01_03" class="custom-chk-label">
                                    A2 依環保局核定之替代方法設置或採行防制設施
                                </label>
                            </div>
                            <input v-if="chkForm.INV_01_03" type="text" class="form-control form-control-sm mb-2" placeholder="請輸入核定替代方法說明..." v-model="form.INV_01_03_Memo" />

                            <!-- 10點缺失選項 -->
                            <div v-if="getSectionLoss(1) === 10" class="subitem-box border-danger">
                                <strong class="text-danger small d-block mb-1">重大缺失 (10點)：</strong>
                                <div class="custom-chk-row">
                                    <input type="checkbox" id="chk_01_04" v-model="chkForm.INV_01_04" v-on:change="onChkChange('INV_01_04')" />
                                    <label for="chk_01_04" class="custom-chk-label">B1 未設置或採行第四條規定防制設施之一</label>
                                </div>
                                <div class="custom-chk-row">
                                    <input type="checkbox" id="chk_01_05" v-model="chkForm.INV_01_05" v-on:change="onChkChange('INV_01_05')" />
                                    <label for="chk_01_05" class="custom-chk-label">B2 未依直轄市、主管機關同意後之替代方法執行</label>
                                </div>
                            </div>

                            <!-- 4點缺失選項 -->
                            <div v-if="getSectionLoss(1) === 4" class="subitem-box border-warning">
                                <strong class="text-warning small d-block mb-1">規格缺失原因 (4點)：</strong>
                                <div class="custom-chk-row">
                                    <input type="checkbox" id="chk_01_08" v-model="chkForm.INV_01_08" v-on:change="onChkChange('INV_01_08')" />
                                    <label for="chk_01_08" class="custom-chk-label">C1 採堆置於封閉式建築物內者，未符合第二條第二款規定</label>
                                </div>
                                <div class="custom-chk-row">
                                    <input type="checkbox" id="chk_01_09" v-model="chkForm.INV_01_09" v-on:change="toggleGroup('INV_01_09', ['INV_01_09a', 'INV_01_09b', 'INV_01_09c', 'INV_01_09d'])" />
                                    <label for="chk_01_09" class="custom-chk-label font-weight-bold">C2 四周以防塵網或阻隔牆圍封者，有下列情形：</label>
                                </div>
                                <div v-if="chkForm.INV_01_09" class="child-chk-group">
                                    <div class="custom-chk-row"><input type="checkbox" id="chk_01_09a" v-model="chkForm.INV_01_09a" v-on:change="onSubChk('INV_01_09', 'INV_01_09a')" /><label for="chk_01_09a" class="custom-chk-label">1. 高度未達堆置高度 1.25 倍</label></div>
                                    <div class="custom-chk-row"><input type="checkbox" id="chk_01_09b" v-model="chkForm.INV_01_09b" v-on:change="onSubChk('INV_01_09', 'INV_01_09b')" /><label for="chk_01_09b" class="custom-chk-label">2. 未完全圍封堆置區</label></div>
                                    <div class="custom-chk-row"><input type="checkbox" id="chk_01_09c" v-model="chkForm.INV_01_09c" v-on:change="onSubChk('INV_01_09', 'INV_01_09c')" /><label for="chk_01_09c" class="custom-chk-label">3. 破損面積達百分之十以上</label></div>
                                    <div class="custom-chk-row"><input type="checkbox" id="chk_01_09d" v-model="chkForm.INV_01_09d" v-on:change="onSubChk('INV_01_09', 'INV_01_09d')" /><label for="chk_01_09d" class="custom-chk-label">4. 體積3000立方公尺以上未符規定</label></div>
                                </div>

                                <div class="custom-chk-row">
                                    <input type="checkbox" id="chk_01_10" v-model="chkForm.INV_01_10" v-on:change="toggleGroup('INV_01_10', ['INV_01_10a', 'INV_01_10b'])" />
                                    <label for="chk_01_10" class="custom-chk-label font-weight-bold">C3 採覆蓋防塵布或防塵網者：</label>
                                </div>
                                <div v-if="chkForm.INV_01_10" class="child-chk-group">
                                    <div class="custom-chk-row"><input type="checkbox" id="chk_01_10a" v-model="chkForm.INV_01_10a" v-on:change="onSubChk('INV_01_10', 'INV_01_10a')" /><label for="chk_01_10a" class="custom-chk-label">1. 覆蓋面積未達 80%</label></div>
                                    <div class="custom-chk-row"><input type="checkbox" id="chk_01_10b" v-model="chkForm.INV_01_10b" v-on:change="onSubChk('INV_01_10', 'INV_01_10b')" /><label for="chk_01_10b" class="custom-chk-label">2. 三級防制區未達 90%</label></div>
                                </div>

                                <div class="custom-chk-row">
                                    <input type="checkbox" id="chk_01_11" v-model="chkForm.INV_01_11" v-on:change="toggleGroup('INV_01_11', ['INV_01_11a', 'INV_01_11b', 'INV_01_11c'])" />
                                    <label for="chk_01_11" class="custom-chk-label font-weight-bold">C4 採噴灑化學穩定劑者：</label>
                                </div>
                                <div v-if="chkForm.INV_01_11" class="child-chk-group">
                                    <div class="custom-chk-row"><input type="checkbox" id="chk_01_11a" v-model="chkForm.INV_01_11a" v-on:change="onSubChk('INV_01_11', 'INV_01_11a')" /><label for="chk_01_11a" class="custom-chk-label">1. 噴灑面積未達 80%</label></div>
                                    <div class="custom-chk-row"><input type="checkbox" id="chk_01_11c" v-model="chkForm.INV_01_11c" v-on:change="onSubChk('INV_01_11', 'INV_01_11c')" /><label for="chk_01_11c" class="custom-chk-label">2. 三級防制區未達 90%</label></div>
                                    <div class="custom-chk-row"><input type="checkbox" id="chk_01_11b" v-model="chkForm.INV_01_11b" v-on:change="onSubChk('INV_01_11', 'INV_01_11b')" /><label for="chk_01_11b" class="custom-chk-label">3. 未依第十條記錄施作與保存憑證</label></div>
                                </div>

                                <div class="custom-chk-row">
                                    <input type="checkbox" id="chk_01_12" v-model="chkForm.INV_01_12" v-on:change="toggleGroup('INV_01_12', ['INV_01_12a', 'INV_01_12b', 'INV_01_12c'])" />
                                    <label for="chk_01_12" class="custom-chk-label font-weight-bold">C5 採設置自動灑水設備者：</label>
                                </div>
                                <div v-if="chkForm.INV_01_12" class="child-chk-group">
                                    <div class="custom-chk-row"><input type="checkbox" id="chk_01_12a" v-model="chkForm.INV_01_12a" v-on:change="onSubChk('INV_01_12', 'INV_01_12a')" /><label for="chk_01_12a" class="custom-chk-label">1. 灑水水量及頻率不足保持濕潤</label></div>
                                    <div class="custom-chk-row"><input type="checkbox" id="chk_01_12b" v-model="chkForm.INV_01_12b" v-on:change="onSubChk('INV_01_12', 'INV_01_12b')" /><label for="chk_01_12b" class="custom-chk-label">2. 需人工操作無法自動灑水</label></div>
                                    <div class="custom-chk-row"><input type="checkbox" id="chk_01_12c" v-model="chkForm.INV_01_12c" v-on:change="onSubChk('INV_01_12', 'INV_01_12c')" /><label for="chk_01_12c" class="custom-chk-label">3. 未設水表每日記錄用水量</label></div>
                                </div>

                                <div class="custom-chk-row">
                                    <input type="checkbox" id="chk_01_14" v-model="chkForm.INV_01_14" v-on:change="onChkChange('INV_01_14')" />
                                    <label for="chk_01_14" class="custom-chk-label">C6 效果優於設施但未依同意方式完整執行</label>
                                </div>
                                <div class="custom-chk-row">
                                    <input type="checkbox" id="chk_01_13" v-model="chkForm.INV_01_13" v-on:change="onChkChange('INV_01_13')" />
                                    <label for="chk_01_13" class="custom-chk-label">C7 四周未設置阻隔防溢座或物料掉落溢流至區外</label>
                                </div>
                            </div>

                            <!-- 項目一現場照片拍攝與上傳 -->
                            <div class="photo-upload-section">
                                <photo-box title="堆置逸散照片 1" photo-key="堆罝逸散性粒狀污染物質" memo-key="FileMemo_1" :parent="this"></photo-box>
                                <photo-box title="堆置逸散照片 2" photo-key="堆罝逸散性粒狀污染物質_2" memo-key="FileMemo_1a" :parent="this"></photo-box>
                                <photo-box title="自動灑水水表" photo-key="堆罝逸散性粒狀污染物質_自動灑水水表" memo-key="FileMemo_1b" :parent="this"></photo-box>
                                <photo-box title="上月紀錄表" photo-key="堆罝逸散性粒狀污染物質_上月紀錄表" memo-key="FileMemo_1c" :parent="this"></photo-box>
                                <photo-box title="本月紀錄表" photo-key="堆罝逸散性粒狀污染物質_本月紀錄表" memo-key="FileMemo_1d" :parent="this"></photo-box>
                            </div>
                        </div>
                    </div>

                    <!-- 項目二：輸送逸散性粒狀污染物質 (第5條) -->
                    <div class="card-modern" :id="'sec-02'">
                        <div class="card-modern-header">
                            <h3 class="card-modern-title">
                                <i class="fas fa-dolly-flatbed text-info"></i>
                                <span>二、輸送逸散性粒狀污染物質 (第5條)</span>
                            </h3>
                            <span class="badge" :class="getSectionLoss(2) > 0 ? (getSectionLoss(2) >= 10 ? 'badge-danger' : 'badge-warning') : 'badge-success'">
                                {{ getSectionLoss(2) }} 點
                            </span>
                        </div>
                        <div class="card-modern-body p-3">
                            <div class="chip-group">
                                <button type="button" class="score-chip-btn" :class="{ 'active-0': form.INV_02_03 === 'V' }" v-on:click="setSectionScore(2, 0, 'INV_02_03')">
                                    <i class="fas fa-check-circle"></i> 合規設置 (0點)
                                </button>
                                <button type="button" class="score-chip-btn" :class="{ 'active-0': form.INV_02_01 === 'V' }" v-on:click="setSectionScore(2, 0, 'INV_02_01')">
                                    <i class="fas fa-ban"></i> 無本製程 (0點)
                                </button>
                                <button type="button" class="score-chip-btn" :class="{ 'active-0': form.INV_02_02 === 'V' }" v-on:click="setSectionScore(2, 0, 'INV_02_02')">
                                    <i class="fas fa-tint"></i> 採濕式免設置 (0點)
                                </button>
                                <button type="button" class="score-chip-btn" :class="{ 'active-4': getSectionLoss(2) === 4 }" v-on:click="setSectionScore(2, 4)">
                                    <i class="fas fa-exclamation-circle"></i> 規格瑕疵 (4點)
                                </button>
                                <button type="button" class="score-chip-btn" :class="{ 'active-10': getSectionLoss(2) === 10 }" v-on:click="setSectionScore(2, 10)">
                                    <i class="fas fa-times-circle"></i> 未設置 (10點)
                                </button>
                            </div>

                            <div class="custom-chk-row">
                                <input type="checkbox" id="chk_02_04" v-model="chkForm.INV_02_04" v-on:change="onChkChange('INV_02_04')" />
                                <label for="chk_02_04" class="custom-chk-label">A3 依替代方法設置或採行防制設施</label>
                            </div>
                            <input v-if="chkForm.INV_02_04" type="text" class="form-control form-control-sm mb-2" placeholder="請輸入核定替代方法說明..." v-model="form.INV_02_04_Memo" />

                            <div v-if="getSectionLoss(2) === 10" class="subitem-box border-danger">
                                <div class="custom-chk-row"><input type="checkbox" id="chk_02_05" v-model="chkForm.INV_02_05" v-on:change="onChkChange('INV_02_05')" /><label for="chk_02_05" class="custom-chk-label">B1 未設置防制設施之一</label></div>
                                <div class="custom-chk-row"><input type="checkbox" id="chk_02_06" v-model="chkForm.INV_02_06" v-on:change="onChkChange('INV_02_06')" /><label for="chk_02_06" class="custom-chk-label">B2 未依同意替代方法執行</label></div>
                            </div>

                            <div v-if="getSectionLoss(2) === 4" class="subitem-box border-warning">
                                <div class="custom-chk-row"><input type="checkbox" id="chk_02_07" v-model="chkForm.INV_02_07" v-on:change="onChkChange('INV_02_07')" /><label for="chk_02_07" class="custom-chk-label">C1 於封閉式建築物內操作未符規定</label></div>
                                <div class="custom-chk-row"><input type="checkbox" id="chk_02_08" v-model="chkForm.INV_02_08" v-on:change="onChkChange('INV_02_08')" /><label for="chk_02_08" class="custom-chk-label">C2 密閉式輸送系統未完全密閉或破損</label></div>
                                <div class="custom-chk-row"><input type="checkbox" id="chk_02_09" v-model="chkForm.INV_02_09" v-on:change="toggleGroup('INV_02_09', ['INV_02_09a', 'INV_02_09b'])" /><label for="chk_02_09" class="custom-chk-label font-weight-bold">C3 採局部集氣系統者：</label></div>
                                <div v-if="chkForm.INV_02_09" class="child-chk-group">
                                    <div class="custom-chk-row"><input type="checkbox" id="chk_02_09a" v-model="chkForm.INV_02_09a" v-on:change="onSubChk('INV_02_09', 'INV_02_09a')" /><label for="chk_02_09a" class="custom-chk-label">1. 捕捉速度不足</label></div>
                                    <div class="custom-chk-row"><input type="checkbox" id="chk_02_09b" v-model="chkForm.INV_02_09b" v-on:change="onSubChk('INV_02_09', 'INV_02_09b')" /><label for="chk_02_09b" class="custom-chk-label">2. 未設電表流量計壓差計等監測儀表並記錄</label></div>
                                </div>
                                <div class="custom-chk-row"><input type="checkbox" id="chk_02_10" v-model="chkForm.INV_02_10" v-on:change="toggleGroup('INV_02_10', ['INV_02_10a', 'INV_02_10b', 'INV_02_10c'])" /><label for="chk_02_10" class="custom-chk-label font-weight-bold">C4 採自動灑水設施者：</label></div>
                                <div v-if="chkForm.INV_02_10" class="child-chk-group">
                                    <div class="custom-chk-row"><input type="checkbox" id="chk_02_10a" v-model="chkForm.INV_02_10a" v-on:change="onSubChk('INV_02_10', 'INV_02_10a')" /><label for="chk_02_10a" class="custom-chk-label">1. 水量及頻率不足</label></div>
                                    <div class="custom-chk-row"><input type="checkbox" id="chk_02_10b" v-model="chkForm.INV_02_10b" v-on:change="onSubChk('INV_02_10', 'INV_02_10b')" /><label for="chk_02_10b" class="custom-chk-label">2. 需人工操作無法自動灑水</label></div>
                                    <div class="custom-chk-row"><input type="checkbox" id="chk_02_10c" v-model="chkForm.INV_02_10c" v-on:change="onSubChk('INV_02_10', 'INV_02_10c')" /><label for="chk_02_10c" class="custom-chk-label">3. 未設水表每日記錄用水量</label></div>
                                </div>
                            </div>

                            <div class="photo-upload-section">
                                <photo-box title="輸送逸散照片 1" photo-key="輸送逸散性粒狀污染物質" memo-key="FileMemo_2" :parent="this"></photo-box>
                                <photo-box title="輸送逸散照片 2" photo-key="輸送逸散性粒狀污染物質_2" memo-key="FileMemo_2a" :parent="this"></photo-box>
                            </div>
                        </div>
                    </div>

                    <!-- 項目三：車輛運輸逸散性粒狀污染物質-運輸車輛 (第6條第1款) -->
                    <div class="card-modern" :id="'sec-03'">
                        <div class="card-modern-header">
                            <h3 class="card-modern-title">
                                <i class="fas fa-truck text-info"></i>
                                <span>三、運輸車輛 (第6條第1款)</span>
                            </h3>
                            <span class="badge" :class="getSectionLoss(3) > 0 ? (getSectionLoss(3) >= 10 ? 'badge-danger' : 'badge-warning') : 'badge-success'">
                                {{ getSectionLoss(3) }} 點
                            </span>
                        </div>
                        <div class="card-modern-body p-3">
                            <div class="chip-group">
                                <button type="button" class="score-chip-btn" :class="{ 'active-0': form.INV_03_02 === 'V' }" v-on:click="setSectionScore(3, 0, 'INV_03_02')">
                                    <i class="fas fa-check-circle"></i> 合規設置 (0點)
                                </button>
                                <button type="button" class="score-chip-btn" :class="{ 'active-0': form.INV_03_01 === 'V' }" v-on:click="setSectionScore(3, 0, 'INV_03_01')">
                                    <i class="fas fa-ban"></i> 無本作業 (0點)
                                </button>
                                <button type="button" class="score-chip-btn" :class="{ 'active-4': getSectionLoss(3) === 4 }" v-on:click="setSectionScore(3, 4)">
                                    <i class="fas fa-exclamation-circle"></i> 規格瑕疵 (4點)
                                </button>
                                <button type="button" class="score-chip-btn" :class="{ 'active-10': getSectionLoss(3) === 10 }" v-on:click="setSectionScore(3, 10)">
                                    <i class="fas fa-times-circle"></i> 未設置 (10點)
                                </button>
                            </div>

                            <div class="custom-chk-row">
                                <input type="checkbox" id="chk_03_03" v-model="chkForm.INV_03_03" v-on:change="onChkChange('INV_03_03')" />
                                <label for="chk_03_03" class="custom-chk-label">A2 依替代方法設置或採行防制設施</label>
                            </div>
                            <input v-if="chkForm.INV_03_03" type="text" class="form-control form-control-sm mb-2" placeholder="請輸入替代方法說明..." v-model="form.INV_03_03_Memo" />

                            <div v-if="getSectionLoss(3) === 10" class="subitem-box border-danger">
                                <div class="custom-chk-row"><input type="checkbox" id="chk_03_04" v-model="chkForm.INV_03_04" v-on:change="onChkChange('INV_03_04')" /><label for="chk_03_04" class="custom-chk-label">B1 運輸車輛未使用密閉式貨箱或未緊密覆蓋</label></div>
                                <div class="custom-chk-row"><input type="checkbox" id="chk_03_05" v-model="chkForm.INV_03_05" v-on:change="onChkChange('INV_03_05')" /><label for="chk_03_05" class="custom-chk-label">B2 貨箱未具防滴落污水污泥之功能或設施</label></div>
                                <div class="custom-chk-row"><input type="checkbox" id="chk_03_06" v-model="chkForm.INV_03_06" v-on:change="onChkChange('INV_03_06')" /><label for="chk_03_06" class="custom-chk-label">B3 未依主管機關同意替代方法執行</label></div>
                            </div>

                            <div v-if="getSectionLoss(3) === 4" class="subitem-box border-warning">
                                <div class="custom-chk-row"><input type="checkbox" id="chk_03_07" v-model="chkForm.INV_03_07" v-on:change="onChkChange('INV_03_07')" /><label for="chk_03_07" class="custom-chk-label">C1 封蓋未緊密覆蓋 (邊緣未延伸覆蓋至貨箱上緣15公分以下)</label></div>
                                <div class="custom-chk-row"><input type="checkbox" id="chk_03_08" v-model="chkForm.INV_03_08" v-on:change="onChkChange('INV_03_08')" /><label for="chk_03_08" class="custom-chk-label">C2 具有設施但運輸過程仍滴落污水、污泥或掉落物料於地面</label></div>
                            </div>

                            <div class="photo-upload-section">
                                <photo-box title="運輸車輛照片 1" photo-key="運輸車輛" memo-key="FileMemo_3" :parent="this"></photo-box>
                                <photo-box title="運輸車輛照片 2" photo-key="運輸車輛_2" memo-key="FileMemo_3a" :parent="this"></photo-box>
                            </div>
                        </div>
                    </div>

                    <!-- 項目四：車輛通行路徑及區域 (第6條第2款) -->
                    <div class="card-modern" :id="'sec-04'">
                        <div class="card-modern-header">
                            <h3 class="card-modern-title">
                                <i class="fas fa-road text-info"></i>
                                <span>四、車輛通行路徑及區域 (第6條第2款)</span>
                            </h3>
                            <span class="badge" :class="getSectionLoss(4) > 0 ? (getSectionLoss(4) >= 10 ? 'badge-danger' : 'badge-warning') : 'badge-success'">
                                {{ getSectionLoss(4) }} 點
                            </span>
                        </div>
                        <div class="card-modern-body p-3">
                            <div class="chip-group">
                                <button type="button" class="score-chip-btn" :class="{ 'active-0': form.INV_04_02 === 'V' }" v-on:click="setSectionScore(4, 0, 'INV_04_02')">
                                    <i class="fas fa-check-circle"></i> 合規設置 (0點)
                                </button>
                                <button type="button" class="score-chip-btn" :class="{ 'active-0': form.INV_04_01 === 'V' }" v-on:click="setSectionScore(4, 0, 'INV_04_01')">
                                    <i class="fas fa-ban"></i> 無本作業 (0點)
                                </button>
                                <button type="button" class="score-chip-btn" :class="{ 'active-4': getSectionLoss(4) === 4 }" v-on:click="setSectionScore(4, 4)">
                                    <i class="fas fa-exclamation-circle"></i> 規格瑕疵 (4點)
                                </button>
                                <button type="button" class="score-chip-btn" :class="{ 'active-10': getSectionLoss(4) === 10 }" v-on:click="setSectionScore(4, 10)">
                                    <i class="fas fa-times-circle"></i> 未設置 (10點)
                                </button>
                            </div>

                            <div class="custom-chk-row">
                                <input type="checkbox" id="chk_04_03" v-model="chkForm.INV_04_03" v-on:change="onChkChange('INV_04_03')" />
                                <label for="chk_04_03" class="custom-chk-label">A2 依替代方法設置或採行防制設施</label>
                            </div>
                            <input v-if="chkForm.INV_04_03" type="text" class="form-control form-control-sm mb-2" placeholder="請輸入替代方法說明..." v-model="form.INV_04_03_Memo" />

                            <div v-if="getSectionLoss(4) === 10" class="subitem-box border-danger">
                                <div class="custom-chk-row"><input type="checkbox" id="chk_04_04" v-model="chkForm.INV_04_04" v-on:change="onChkChange('INV_04_04')" /><label for="chk_04_04" class="custom-chk-label">B1 通行路徑及區域未依規定設置防制設施</label></div>
                                <div class="custom-chk-row"><input type="checkbox" id="chk_04_05" v-model="chkForm.INV_04_05" v-on:change="onChkChange('INV_04_05')" /><label for="chk_04_05" class="custom-chk-label">B2 未依同意替代方法執行</label></div>
                            </div>

                            <div v-if="getSectionLoss(4) === 4" class="subitem-box border-warning">
                                <div class="custom-chk-row"><input type="checkbox" id="chk_04_06" v-model="chkForm.INV_04_06" v-on:change="onChkChange('INV_04_06')" /><label for="chk_04_06" class="custom-chk-label">C1 設置或採行防制設施面積不足</label></div>
                                <div class="custom-chk-row"><input type="checkbox" id="chk_04_07" v-model="chkForm.INV_04_07" v-on:change="onChkChange('INV_04_07')" /><label for="chk_04_07" class="custom-chk-label">C2 舖設混凝土瀝青鋼板惟有路面色差</label></div>
                                <div class="custom-chk-row"><input type="checkbox" id="chk_04_08" v-model="chkForm.INV_04_08" v-on:change="onChkChange('INV_04_08')" /><label for="chk_04_08" class="custom-chk-label">C3 粗級配粒料厚度不足或未灑水保持濕潤</label></div>
                            </div>

                            <div class="photo-upload-section">
                                <photo-box title="通行路徑照片 1" photo-key="車輛通行路徑" memo-key="FileMemo_4" :parent="this"></photo-box>
                                <photo-box title="通行路徑照片 2" photo-key="車輛通行路徑_2" memo-key="FileMemo_4a" :parent="this"></photo-box>
                            </div>
                        </div>
                    </div>

                    <!-- 項目五：車輛清洗 (第6條第3款) 與洗車設備規格 -->
                    <div class="card-modern" :id="'sec-05'">
                        <div class="card-modern-header">
                            <h3 class="card-modern-title">
                                <i class="fas fa-shower text-info"></i>
                                <span>五、車輛清洗 (第6條第3款)</span>
                            </h3>
                            <span class="badge" :class="getSectionLoss(5) > 0 ? (getSectionLoss(5) >= 10 ? 'badge-danger' : 'badge-warning') : 'badge-success'">
                                {{ getSectionLoss(5) }} 點
                            </span>
                        </div>
                        <div class="card-modern-body p-3">
                            <div class="chip-group">
                                <button type="button" class="score-chip-btn" :class="{ 'active-0': form.INV_05_02 === 'V' }" v-on:click="setSectionScore(5, 0, 'INV_05_02')">
                                    <i class="fas fa-check-circle"></i> 合規設置 (0點)
                                </button>
                                <button type="button" class="score-chip-btn" :class="{ 'active-0': form.INV_05_01 === 'V' }" v-on:click="setSectionScore(5, 0, 'INV_05_01')">
                                    <i class="fas fa-ban"></i> 無本作業 (0點)
                                </button>
                                <button type="button" class="score-chip-btn" :class="{ 'active-4': getSectionLoss(5) === 4 }" v-on:click="setSectionScore(5, 4)">
                                    <i class="fas fa-exclamation-circle"></i> 規格瑕疵 (4點)
                                </button>
                                <button type="button" class="score-chip-btn" :class="{ 'active-10': getSectionLoss(5) === 10 }" v-on:click="setSectionScore(5, 10)">
                                    <i class="fas fa-times-circle"></i> 未設置 (10點)
                                </button>
                            </div>

                            <div class="custom-chk-row">
                                <input type="checkbox" id="chk_05_03" v-model="chkForm.INV_05_03" v-on:change="onChkChange('INV_05_03')" />
                                <label for="chk_05_03" class="custom-chk-label">A2 依替代方法設置或採行防制設施</label>
                            </div>
                            <input v-if="chkForm.INV_05_03" type="text" class="form-control form-control-sm mb-2" placeholder="請輸入替代方法說明..." v-model="form.INV_05_03_Memo" />

                            <div v-if="getSectionLoss(5) === 10" class="subitem-box border-danger">
                                <div class="custom-chk-row"><input type="checkbox" id="chk_05_04" v-model="chkForm.INV_05_04" v-on:change="onChkChange('INV_05_04')" /><label for="chk_05_04" class="custom-chk-label">B1 未依規定以加壓沖洗設備清洗車體及輪胎</label></div>
                                <div class="custom-chk-row"><input type="checkbox" id="chk_05_06" v-model="chkForm.INV_05_06" v-on:change="onChkChange('INV_05_06')" /><label for="chk_05_06" class="custom-chk-label">B2 未依同意替代方法執行</label></div>
                                <div class="custom-chk-row"><input type="checkbox" id="chk_05_05" v-model="chkForm.INV_05_05" v-on:change="onChkChange('INV_05_05')" /><label for="chk_05_05" class="custom-chk-label">B3 須洗掃鄰接道路並設自動洗車設備而未依規定洗掃或設置</label></div>
                            </div>

                            <div v-if="getSectionLoss(5) === 4" class="subitem-box border-warning">
                                <div class="custom-chk-row"><input type="checkbox" id="chk_05_07" v-model="chkForm.INV_05_07" v-on:change="onChkChange('INV_05_07')" /><label for="chk_05_07" class="custom-chk-label">C1 運輸車輛未清洗乾淨致門口路面有帶出污泥物料</label></div>
                                <div class="custom-chk-row"><input type="checkbox" id="chk_05_08" v-model="chkForm.INV_05_08" v-on:change="onChkChange('INV_05_08')" /><label for="chk_05_08" class="custom-chk-label">C2 洗車設備無加壓沖洗功能</label></div>
                                <div class="custom-chk-row"><input type="checkbox" id="chk_05_09" v-model="chkForm.INV_05_09" v-on:change="onChkChange('INV_05_09')" /><label for="chk_05_09" class="custom-chk-label">C3 自動洗車設備規格未符附表二規定</label></div>
                                <div class="custom-chk-row"><input type="checkbox" id="chk_05_10" v-model="chkForm.INV_05_10" v-on:change="onChkChange('INV_05_10')" /><label for="chk_05_10" class="custom-chk-label">C4 未設水表電表並記錄用水或用電度數</label></div>
                            </div>

                            <!-- 洗車設備規格面板 -->
                            <div class="card bg-light border p-3 mt-3">
                                <h6 class="font-weight-bold text-dark mb-2">
                                    <i class="fas fa-tools text-primary mr-1"></i> 洗車設備規格與查核填報
                                </h6>
                                <div class="row">
                                    <div class="col-md-6 col-12 mb-2">
                                        <label class="small text-muted font-weight-bold">洗車設備類型</label>
                                        <div class="segmented-group d-flex w-100">
                                            <button type="button" class="segment-btn flex-fill" :class="{ 'active-blue': form.WashCar_Type === '加壓沖洗設備' }" v-on:click="form.WashCar_Type = '加壓沖洗設備'">
                                                加壓沖洗設備
                                            </button>
                                            <button type="button" class="segment-btn flex-fill" :class="{ 'active-blue': form.WashCar_Type === '跳動式洗車台' }" v-on:click="form.WashCar_Type = '跳動式洗車台'">
                                                跳動式洗車台
                                            </button>
                                        </div>
                                    </div>

                                    <div class="col-md-3 col-6 mb-2">
                                        <label class="small text-muted font-weight-bold">洗車台長度 (公尺)</label>
                                        <input type="number" step="0.1" class="form-control form-control-sm" v-model="form.WashCar_Length" placeholder="長度" />
                                    </div>
                                    <div class="col-md-3 col-6 mb-2">
                                        <label class="small text-muted font-weight-bold">洗車台寬度 (公尺)</label>
                                        <input type="number" step="0.1" class="form-control form-control-sm" v-model="form.WashCar_Width" placeholder="寬度" />
                                    </div>
                                    <div class="col-md-3 col-6 mb-2">
                                        <label class="small text-muted font-weight-bold">槽體深度 (公分)</label>
                                        <input type="number" step="0.1" class="form-control form-control-sm" v-model="form.SinkDepth" placeholder="深度" />
                                    </div>
                                    <div class="col-md-3 col-6 mb-2">
                                        <label class="small text-muted font-weight-bold">槽內水深 (公分)</label>
                                        <input type="number" step="0.1" class="form-control form-control-sm" v-model="form.SinkWaterDepth" placeholder="水深" />
                                    </div>
                                    <div class="col-md-3 col-6 mb-2">
                                        <label class="small text-muted font-weight-bold">噴水口間距 (公分)</label>
                                        <input type="number" step="0.1" class="form-control form-control-sm" v-model="form.SpoutLen" placeholder="間距" />
                                    </div>
                                    <div class="col-md-3 col-6 mb-2">
                                        <label class="small text-muted font-weight-bold">加壓馬達 (馬力)</label>
                                        <input type="number" step="0.1" class="form-control form-control-sm" v-model="form.MotorHP" placeholder="HP" />
                                    </div>

                                    <div class="col-md-6 col-12 mb-2">
                                        <label class="small text-muted font-weight-bold">提醒駕駛人停等洗車警語</label>
                                        <div class="segmented-group d-flex w-100">
                                            <button type="button" class="segment-btn flex-fill" :class="{ 'active-yes': form.WarningWashCar === '有' }" v-on:click="form.WarningWashCar = '有'">有</button>
                                            <button type="button" class="segment-btn flex-fill" :class="{ 'active-no': form.WarningWashCar === '無' }" v-on:click="form.WarningWashCar = '無'">無</button>
                                        </div>
                                    </div>

                                    <div class="col-md-6 col-12 mb-2">
                                        <label class="small text-muted font-weight-bold">洗車設備操作方式及時間告示</label>
                                        <div class="segmented-group d-flex w-100">
                                            <button type="button" class="segment-btn flex-fill" :class="{ 'active-yes': form.WashCarMemo === '有' }" v-on:click="form.WashCarMemo = '有'">有</button>
                                            <button type="button" class="segment-btn flex-fill" :class="{ 'active-no': form.WashCarMemo === '無' }" v-on:click="form.WashCarMemo = '無'">無</button>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div class="photo-upload-section">
                                <photo-box title="車輛清洗照片 1" photo-key="車輛清洗" memo-key="FileMemo_5" :parent="this"></photo-box>
                                <photo-box title="車輛清洗照片 2" photo-key="車輛清洗_2" memo-key="FileMemo_5a" :parent="this"></photo-box>
                                <photo-box title="自動感應閘門查證" photo-key="車輛清洗_自動感應閘門查證紀錄" memo-key="FileMemo_5b" :parent="this"></photo-box>
                                <photo-box title="水槽查證紀錄" photo-key="車輛清洗_水槽查證紀錄" memo-key="FileMemo_5c" :parent="this"></photo-box>
                                <photo-box title="換水記錄查證" photo-key="車輛清洗_換水記錄查證紀錄" memo-key="FileMemo_5d" :parent="this"></photo-box>
                                <photo-box title="噴水口查證" photo-key="車輛清洗_噴水口查證紀錄" memo-key="FileMemo_5e" :parent="this"></photo-box>
                                <photo-box title="加壓馬達查證" photo-key="車輛清洗_加壓馬達查證紀錄" memo-key="FileMemo_5f" :parent="this"></photo-box>
                                <photo-box title="廢水處理查證" photo-key="車輛清洗_廢水處理設備查證紀錄" memo-key="FileMemo_5g" :parent="this"></photo-box>
                                <photo-box title="告示牌查證" photo-key="車輛清洗_告示牌查證紀錄" memo-key="FileMemo_5h" :parent="this"></photo-box>
                                <photo-box title="水表查證紀錄" photo-key="車輛清洗_水表查證紀錄" memo-key="FileMemo_5i" :parent="this"></photo-box>
                            </div>
                        </div>
                    </div>

                    <!-- 項目六：易致粒狀污染物逸散之製程、操作或裝卸作業 (第7條) -->
                    <div class="card-modern" :id="'sec-06'">
                        <div class="card-modern-header">
                            <h3 class="card-modern-title">
                                <i class="fas fa-smog text-info"></i>
                                <span>六、製程、操作或裝卸作業 (第7條)</span>
                            </h3>
                            <span class="badge" :class="getSectionLoss(6) > 0 ? (getSectionLoss(6) >= 10 ? 'badge-danger' : 'badge-warning') : 'badge-success'">
                                {{ getSectionLoss(6) }} 點
                            </span>
                        </div>
                        <div class="card-modern-body p-3">
                            <div class="chip-group">
                                <button type="button" class="score-chip-btn" :class="{ 'active-0': form.INV_06_03 === 'V' }" v-on:click="setSectionScore(6, 0, 'INV_06_03')">
                                    <i class="fas fa-check-circle"></i> 合規設置 (0點)
                                </button>
                                <button type="button" class="score-chip-btn" :class="{ 'active-0': form.INV_06_01 === 'V' }" v-on:click="setSectionScore(6, 0, 'INV_06_01')">
                                    <i class="fas fa-ban"></i> 無本製程 (0點)
                                </button>
                                <button type="button" class="score-chip-btn" :class="{ 'active-0': form.INV_06_02 === 'V' }" v-on:click="setSectionScore(6, 0, 'INV_06_02')">
                                    <i class="fas fa-tint"></i> 採濕式免設置 (0點)
                                </button>
                                <button type="button" class="score-chip-btn" :class="{ 'active-4': getSectionLoss(6) === 4 }" v-on:click="setSectionScore(6, 4)">
                                    <i class="fas fa-exclamation-circle"></i> 規格瑕疵 (4點)
                                </button>
                                <button type="button" class="score-chip-btn" :class="{ 'active-10': getSectionLoss(6) === 10 }" v-on:click="setSectionScore(6, 10)">
                                    <i class="fas fa-times-circle"></i> 未設置 (10點)
                                </button>
                            </div>

                            <div class="custom-chk-row">
                                <input type="checkbox" id="chk_06_04" v-model="chkForm.INV_06_04" v-on:change="onChkChange('INV_06_04')" />
                                <label for="chk_06_04" class="custom-chk-label">A3 依替代方法設置或採行防制設施</label>
                            </div>
                            <input v-if="chkForm.INV_06_04" type="text" class="form-control form-control-sm mb-2" placeholder="請輸入替代方法說明..." v-model="form.INV_06_04_Memo" />

                            <div v-if="getSectionLoss(6) === 10" class="subitem-box border-danger">
                                <div class="custom-chk-row"><input type="checkbox" id="chk_06_05" v-model="chkForm.INV_06_05" v-on:change="onChkChange('INV_06_05')" /><label for="chk_06_05" class="custom-chk-label">B1 未設置或採行第七條防制設施之一</label></div>
                                <div class="custom-chk-row"><input type="checkbox" id="chk_06_06" v-model="chkForm.INV_06_06" v-on:change="onChkChange('INV_06_06')" /><label for="chk_06_06" class="custom-chk-label">B2 未依同意替代方法執行</label></div>
                            </div>

                            <div v-if="getSectionLoss(6) === 4" class="subitem-box border-warning">
                                <div class="custom-chk-row"><input type="checkbox" id="chk_06_07" v-model="chkForm.INV_06_07" v-on:change="toggleGroup('INV_06_07', ['INV_06_07a', 'INV_06_07b'])" /><label for="chk_06_07" class="custom-chk-label font-weight-bold">C1 圍封式集氣系統：</label></div>
                                <div v-if="chkForm.INV_06_07" class="child-chk-group">
                                    <div class="custom-chk-row"><input type="checkbox" id="chk_06_07a" v-model="chkForm.INV_06_07a" v-on:change="onSubChk('INV_06_07', 'INV_06_07a')" /><label for="chk_06_07a" class="custom-chk-label">1. 未維持負壓操作狀態</label></div>
                                    <div class="custom-chk-row"><input type="checkbox" id="chk_06_07b" v-model="chkForm.INV_06_07b" v-on:change="onSubChk('INV_06_07', 'INV_06_07b')" /><label for="chk_06_07b" class="custom-chk-label">2. 未設電表流量計壓差計等監測儀表並記錄</label></div>
                                </div>
                                <div class="custom-chk-row"><input type="checkbox" id="chk_06_08" v-model="chkForm.INV_06_08" v-on:change="toggleGroup('INV_06_08', ['INV_06_08a', 'INV_06_08b'])" /><label for="chk_06_08" class="custom-chk-label font-weight-bold">C2 局部集氣系統：</label></div>
                                <div v-if="chkForm.INV_06_08" class="child-chk-group">
                                    <div class="custom-chk-row"><input type="checkbox" id="chk_06_08a" v-model="chkForm.INV_06_08a" v-on:change="onSubChk('INV_06_08', 'INV_06_08a')" /><label for="chk_06_08a" class="custom-chk-label">1. 捕捉速度不足</label></div>
                                    <div class="custom-chk-row"><input type="checkbox" id="chk_06_08b" v-model="chkForm.INV_06_08b" v-on:change="onSubChk('INV_06_08', 'INV_06_08b')" /><label for="chk_06_08b" class="custom-chk-label">2. 未設電表監測儀表並記錄</label></div>
                                </div>
                                <div class="custom-chk-row"><input type="checkbox" id="chk_06_09" v-model="chkForm.INV_06_09" v-on:change="onChkChange('INV_06_09')" /><label for="chk_06_09" class="custom-chk-label">C3 密閉式作業未妥善密閉或破損</label></div>
                                <div class="custom-chk-row"><input type="checkbox" id="chk_06_10" v-model="chkForm.INV_06_10" v-on:change="onChkChange('INV_06_10')" /><label for="chk_06_10" class="custom-chk-label">C4 封閉式建築未符合規定</label></div>
                                <div class="custom-chk-row"><input type="checkbox" id="chk_06_11" v-model="chkForm.INV_06_11" v-on:change="onChkChange('INV_06_11')" /><label for="chk_06_11" class="custom-chk-label">C5 灑水設施噴灑範圍水量及頻率不足</label></div>
                            </div>

                            <div class="photo-upload-section">
                                <photo-box title="製程作業照片 1" photo-key="易致粒狀污染物逸散之製程、操作或裝卸作業_1" memo-key="FileMemo_6" :parent="this"></photo-box>
                                <photo-box title="製程作業照片 2" photo-key="易致粒狀污染物逸散之製程、操作或裝卸作業_2" memo-key="FileMemo_6a" :parent="this"></photo-box>
                                <photo-box title="監測儀表照片" photo-key="易致粒狀污染物逸散之製程、操作或裝卸作業_監測儀表" memo-key="FileMemo_6b" :parent="this"></photo-box>
                            </div>
                        </div>
                    </div>

                    <!-- 項目七：公私場所管理之裸露區域 (第8條) -->
                    <div class="card-modern" :id="'sec-07'">
                        <div class="card-modern-header">
                            <h3 class="card-modern-title">
                                <i class="fas fa-mountain text-info"></i>
                                <span>七、公私場所管理之裸露區域 (第8條)</span>
                            </h3>
                            <span class="badge" :class="getSectionLoss(7) > 0 ? (getSectionLoss(7) >= 10 ? 'badge-danger' : 'badge-warning') : 'badge-success'">
                                {{ getSectionLoss(7) }} 點
                            </span>
                        </div>
                        <div class="card-modern-body p-3">
                            <div class="chip-group">
                                <button type="button" class="score-chip-btn" :class="{ 'active-0': form.INV_07_02 === 'V' }" v-on:click="setSectionScore(7, 0, 'INV_07_02')">
                                    <i class="fas fa-check-circle"></i> 合規設置 (0點)
                                </button>
                                <button type="button" class="score-chip-btn" :class="{ 'active-0': form.INV_07_01 === 'V' }" v-on:click="setSectionScore(7, 0, 'INV_07_01')">
                                    <i class="fas fa-ban"></i> 無本區域 (0點)
                                </button>
                                <button type="button" class="score-chip-btn" :class="{ 'active-4': getSectionLoss(7) === 4 }" v-on:click="setSectionScore(7, 4)">
                                    <i class="fas fa-exclamation-circle"></i> 規格瑕疵 (4點)
                                </button>
                                <button type="button" class="score-chip-btn" :class="{ 'active-10': getSectionLoss(7) === 10 }" v-on:click="setSectionScore(7, 10)">
                                    <i class="fas fa-times-circle"></i> 未設置 (10點)
                                </button>
                            </div>

                            <div class="custom-chk-row">
                                <input type="checkbox" id="chk_07_03" v-model="chkForm.INV_07_03" v-on:change="onChkChange('INV_07_03')" />
                                <label for="chk_07_03" class="custom-chk-label">A2 依替代方法設置或採行防制設施</label>
                            </div>
                            <input v-if="chkForm.INV_07_03" type="text" class="form-control form-control-sm mb-2" placeholder="請輸入替代方法說明..." v-model="form.INV_07_03_Memo" />

                            <div v-if="getSectionLoss(7) === 10" class="subitem-box border-danger">
                                <div class="custom-chk-row"><input type="checkbox" id="chk_07_04" v-model="chkForm.INV_07_04" v-on:change="onChkChange('INV_07_04')" /><label for="chk_07_04" class="custom-chk-label">B1 未設置或採行第八條防制設施之一</label></div>
                                <div class="custom-chk-row"><input type="checkbox" id="chk_07_05" v-model="chkForm.INV_07_05" v-on:change="onChkChange('INV_07_05')" /><label for="chk_07_05" class="custom-chk-label">B2 未依同意替代方法執行</label></div>
                            </div>

                            <div v-if="getSectionLoss(7) === 4" class="subitem-box border-warning">
                                <div class="custom-chk-row"><input type="checkbox" id="chk_07_06" v-model="chkForm.INV_07_06" v-on:change="onChkChange('INV_07_06')" /><label for="chk_07_06" class="custom-chk-label">C1 防制設施實施面積未完整涵蓋裸露區域</label></div>
                                <div class="custom-chk-row"><input type="checkbox" id="chk_07_07" v-model="chkForm.INV_07_07" v-on:change="onChkChange('INV_07_07')" /><label for="chk_07_07" class="custom-chk-label">C2 植生綠化覆蓋稻草蓆碎木厚度不足</label></div>
                                <div class="custom-chk-row"><input type="checkbox" id="chk_07_08" v-model="chkForm.INV_07_08" v-on:change="onChkChange('INV_07_08')" /><label for="chk_07_08" class="custom-chk-label">C3 粗級配粒徑厚度不足或未灑水保持濕潤</label></div>
                                <div class="custom-chk-row"><input type="checkbox" id="chk_07_09" v-model="chkForm.INV_07_09" v-on:change="onChkChange('INV_07_09')" /><label for="chk_07_09" class="custom-chk-label">C4 噴灑化學穩定劑或灑水量及頻率不足</label></div>
                                <div class="custom-chk-row"><input type="checkbox" id="chk_07_10" v-model="chkForm.INV_07_10" v-on:change="onChkChange('INV_07_10')" /><label for="chk_07_10" class="custom-chk-label">C5 噴灑穩定劑未記錄保存購買證明</label></div>
                            </div>

                            <div class="photo-upload-section">
                                <photo-box title="裸露區域照片 1" photo-key="公私場所管理之裸露區域" memo-key="FileMemo_7" :parent="this"></photo-box>
                                <photo-box title="裸露區域照片 2" photo-key="公私場所管理之裸露區域_2" memo-key="FileMemo_7a" :parent="this"></photo-box>
                            </div>
                        </div>
                    </div>

                    <!-- 項目八：公私場所管理之道路 (第9條) -->
                    <div class="card-modern" :id="'sec-08'">
                        <div class="card-modern-header">
                            <h3 class="card-modern-title">
                                <i class="fas fa-route text-info"></i>
                                <span>八、場所管理之道路 (第9條)</span>
                            </h3>
                            <span class="badge" :class="getSectionLoss(8) > 0 ? (getSectionLoss(8) >= 10 ? 'badge-danger' : 'badge-warning') : 'badge-success'">
                                {{ getSectionLoss(8) }} 點
                            </span>
                        </div>
                        <div class="card-modern-body p-3">
                            <div class="chip-group">
                                <button type="button" class="score-chip-btn" :class="{ 'active-0': form.INV_08_02 === 'V' }" v-on:click="setSectionScore(8, 0, 'INV_08_02')">
                                    <i class="fas fa-check-circle"></i> 合規設置 (0點)
                                </button>
                                <button type="button" class="score-chip-btn" :class="{ 'active-0': form.INV_08_01 === 'V' }" v-on:click="setSectionScore(8, 0, 'INV_08_01')">
                                    <i class="fas fa-ban"></i> 無本道路 (0點)
                                </button>
                                <button type="button" class="score-chip-btn" :class="{ 'active-4': getSectionLoss(8) === 4 }" v-on:click="setSectionScore(8, 4)">
                                    <i class="fas fa-exclamation-circle"></i> 規格瑕疵 (4點)
                                </button>
                                <button type="button" class="score-chip-btn" :class="{ 'active-10': getSectionLoss(8) === 10 }" v-on:click="setSectionScore(8, 10)">
                                    <i class="fas fa-times-circle"></i> 未設置 (10點)
                                </button>
                            </div>

                            <div class="custom-chk-row">
                                <input type="checkbox" id="chk_08_03" v-model="chkForm.INV_08_03" v-on:change="onChkChange('INV_08_03')" />
                                <label for="chk_08_03" class="custom-chk-label">A2 依替代方法設置或採行防制設施</label>
                            </div>
                            <input v-if="chkForm.INV_08_03" type="text" class="form-control form-control-sm mb-2" placeholder="請輸入替代方法說明..." v-model="form.INV_08_03_Memo" />

                            <div v-if="getSectionLoss(8) === 10" class="subitem-box border-danger">
                                <div class="custom-chk-row"><input type="checkbox" id="chk_08_04" v-model="chkForm.INV_08_04" v-on:change="onChkChange('INV_08_04')" /><label for="chk_08_04" class="custom-chk-label">B1 交通島及人行道裸露區域未設置防制設施之一</label></div>
                                <div class="custom-chk-row"><input type="checkbox" id="chk_08_05" v-model="chkForm.INV_08_05" v-on:change="onChkChange('INV_08_05')" /><label for="chk_08_05" class="custom-chk-label">B2 未依同意替代方法執行</label></div>
                            </div>

                            <div v-if="getSectionLoss(8) === 4" class="subitem-box border-warning">
                                <div class="custom-chk-row"><input type="checkbox" id="chk_08_06" v-model="chkForm.INV_08_06" v-on:change="onChkChange('INV_08_06')" /><label for="chk_08_06" class="custom-chk-label">C1 路面有破損、髒污致路面色差</label></div>
                                <div class="custom-chk-row"><input type="checkbox" id="chk_08_07" v-model="chkForm.INV_08_07" v-on:change="onChkChange('INV_08_07')" /><label for="chk_08_07" class="custom-chk-label">C2 交通島及人行道裸露區域面積或厚度不足</label></div>
                                <div class="custom-chk-row"><input type="checkbox" id="chk_08_08" v-model="chkForm.INV_08_08" v-on:change="onChkChange('INV_08_08')" /><label for="chk_08_08" class="custom-chk-label">C3 植生綠化覆蓋稻草蓆碎木厚度不足</label></div>
                                <div class="custom-chk-row"><input type="checkbox" id="chk_08_09" v-model="chkForm.INV_08_09" v-on:change="onChkChange('INV_08_09')" /><label for="chk_08_09" class="custom-chk-label">C4 舖設粗級配粒徑厚度不足或未灑水</label></div>
                            </div>

                            <div class="photo-upload-section">
                                <photo-box title="管理道路照片 1" photo-key="公私場所管理之道路_1" memo-key="FileMemo_8" :parent="this"></photo-box>
                                <photo-box title="管理道路照片 2" photo-key="公私場所管理之道路_2" memo-key="FileMemo_8a" :parent="this"></photo-box>
                            </div>
                        </div>
                    </div>

                    <!-- 項目九：攝錄影監視系統 (第11條) -->
                    <div class="card-modern" :id="'sec-09'">
                        <div class="card-modern-header">
                            <h3 class="card-modern-title">
                                <i class="fas fa-video text-info"></i>
                                <span>九、攝錄影監視系統 (第11條)</span>
                            </h3>
                            <span class="badge" :class="getSectionLoss(9) > 0 ? (getSectionLoss(9) >= 10 ? 'badge-danger' : 'badge-warning') : 'badge-success'">
                                {{ getSectionLoss(9) }} 點
                            </span>
                        </div>
                        <div class="card-modern-body p-3">
                            <div class="chip-group">
                                <button type="button" class="score-chip-btn" :class="{ 'active-0': form.INV_09_02 === 'V' }" v-on:click="setSectionScore(9, 0, 'INV_09_02')">
                                    <i class="fas fa-check-circle"></i> 合規設置 (0點)
                                </button>
                                <button type="button" class="score-chip-btn" :class="{ 'active-0': form.INV_09_01 === 'V' }" v-on:click="setSectionScore(9, 0, 'INV_09_01')">
                                    <i class="fas fa-ban"></i> 無須設置 (0點)
                                </button>
                                <button type="button" class="score-chip-btn" :class="{ 'active-4': getSectionLoss(9) === 4 }" v-on:click="setSectionScore(9, 4)">
                                    <i class="fas fa-exclamation-circle"></i> 規格瑕疵 (4點)
                                </button>
                                <button type="button" class="score-chip-btn" :class="{ 'active-10': getSectionLoss(9) === 10 }" v-on:click="setSectionScore(9, 10)">
                                    <i class="fas fa-times-circle"></i> 未設置 (10點)
                                </button>
                            </div>

                            <div class="custom-chk-row">
                                <input type="checkbox" id="chk_09_03" v-model="chkForm.INV_09_03" v-on:change="onChkChange('INV_09_03')" />
                                <label for="chk_09_03" class="custom-chk-label">A2 依替代方法設置或採行防制設施</label>
                            </div>
                            <input v-if="chkForm.INV_09_03" type="text" class="form-control form-control-sm mb-2" placeholder="請輸入替代方法說明..." v-model="form.INV_09_03_Memo" />

                            <div v-if="getSectionLoss(9) === 10" class="subitem-box border-danger">
                                <div class="custom-chk-row"><input type="checkbox" id="chk_09_04" v-model="chkForm.INV_09_04" v-on:change="onChkChange('INV_09_04')" /><label for="chk_09_04" class="custom-chk-label">B1 須設置攝錄影監視系統而未設置</label></div>
                                <div class="custom-chk-row"><input type="checkbox" id="chk_09_05" v-model="chkForm.INV_09_05" v-on:change="onChkChange('INV_09_05')" /><label for="chk_09_05" class="custom-chk-label">B2 監視系統故障未於次日起算七日內修復完成</label></div>
                                <div class="custom-chk-row"><input type="checkbox" id="chk_09_06" v-model="chkForm.INV_09_06" v-on:change="onChkChange('INV_09_06')" /><label for="chk_09_06" class="custom-chk-label">B3 未依主管機關同意替代方法執行</label></div>
                            </div>

                            <div v-if="getSectionLoss(9) === 4" class="subitem-box border-warning">
                                <div class="custom-chk-row"><input type="checkbox" id="chk_09_07" v-model="chkForm.INV_09_07" v-on:change="onChkChange('INV_09_07')" /><label for="chk_09_07" class="custom-chk-label">C1 未符合附表四規定或記錄影像資料未保存一個月</label></div>
                                <div class="custom-chk-row"><input type="checkbox" id="chk_09_08" v-model="chkForm.INV_09_08" v-on:change="onChkChange('INV_09_08')" /><label for="chk_09_08" class="custom-chk-label">C2 監視系統故障未即時通報主管機關</label></div>
                            </div>

                            <div class="photo-upload-section">
                                <photo-box title="監視系統照片 1" photo-key="攝錄影監視系統_1" memo-key="FileMemo_9" :parent="this"></photo-box>
                                <photo-box title="監視系統照片 2" photo-key="攝錄影監視系統_2" memo-key="FileMemo_9a" :parent="this"></photo-box>
                            </div>
                        </div>
                    </div>

                    <!-- 項目十：全景照片與其他查核照片 -->
                    <div class="card-modern" :id="'sec-10'">
                        <div class="card-modern-header">
                            <h3 class="card-modern-title">
                                <i class="fas fa-camera text-primary"></i>
                                <span>十、全景照片及其他查核佐證</span>
                            </h3>
                        </div>
                        <div class="card-modern-body p-3">
                            <div class="photo-upload-section">
                                <photo-box title="全景照片" photo-key="全景照片" memo-key="FileMemo_AllView" :parent="this"></photo-box>
                                <photo-box title="工廠正門口照片" photo-key="工廠正門口" memo-key="FileMemo_Entrance" :parent="this"></photo-box>
                                <photo-box title="輔導簽認單 1" photo-key="輔導簽認單_1" memo-key="FileMemo_Counseling1" :parent="this"></photo-box>
                                <photo-box title="輔導簽認單 2" photo-key="輔導簽認單_2" memo-key="FileMemo_Counseling2" :parent="this"></photo-box>
                                <photo-box title="局部集氣評估 1" photo-key="局部集氣效率評估_1" memo-key="FileMemo_CollGasEfficiency1" :parent="this"></photo-box>
                                <photo-box title="局部集氣評估 2" photo-key="局部集氣效率評估_2" memo-key="FileMemo_CollGasEfficiency2" :parent="this"></photo-box>
                                <photo-box title="空品感測數據 1" photo-key="空品感測數據_1" memo-key="FileMemo_AirQualityValue1" :parent="this"></photo-box>
                                <photo-box title="空品感測數據 2" photo-key="空品感測數據_2" memo-key="FileMemo_AirQualityValue2" :parent="this"></photo-box>
                            </div>
                        </div>
                    </div>

                    <!-- 項目十一：環境潛勢調查及許可不符項目 -->
                    <div class="card-modern" :id="'sec-11'">
                        <div class="card-modern-header">
                            <h3 class="card-modern-title">
                                <i class="fas fa-exclamation-circle text-warning"></i>
                                <span>十一、環境潛勢調查及許可不符項目</span>
                            </h3>
                        </div>
                        <div class="card-modern-body p-3">
                            <label class="font-weight-bold small text-muted">調查項目複選</label>
                            <div class="d-flex flex-wrap gap-2 mb-3">
                                <div v-for="envItem in envCheckOptions" :key="envItem" class="custom-control custom-checkbox mr-3">
                                    <input type="checkbox" class="custom-control-input" :id="'env_' + envItem" :value="envItem" v-model="envCheckSelected" />
                                    <label class="custom-control-label" :for="'env_' + envItem">{{ envItem }}</label>
                                </div>
                            </div>
                            <input v-if="envCheckSelected.indexOf('其他') !== -1" type="text" class="form-control form-control-sm mb-3" placeholder="請填寫其他潛勢調查說明..." v-model="form.EnvirCheck_Other" />

                            <div class="row">
                                <div class="col-md-6 col-12 mb-2">
                                    <label class="small text-muted font-weight-bold">狀態</label>
                                    <div class="segmented-group d-flex w-100">
                                        <button type="button" class="segment-btn flex-fill" :class="{ 'active-blue': form.OtherChkAns1 === '記錄其他潛勢' }" v-on:click="form.OtherChkAns1 = '記錄其他潛勢'">記錄其他潛勢</button>
                                        <button type="button" class="segment-btn flex-fill" :class="{ 'active-blue': form.OtherChkAns1 === '無' }" v-on:click="form.OtherChkAns1 = '無'">無</button>
                                    </div>
                                </div>
                                <div v-if="form.OtherChkAns1 !== '無'" class="col-md-6 col-12 mb-2">
                                    <label class="small text-muted font-weight-bold">事項</label>
                                    <select class="form-control form-control-sm" v-model="form.OtherChkAns2">
                                        <option value="設備C:個數差異">設備C:個數差異</option>
                                        <option value="設備C:總量差異">設備C:總量差異</option>
                                        <option value="設備X:個數差異">設備X:個數差異</option>
                                        <option value="設備X:總量差異">設備X:總量差異</option>
                                        <option value="其他">其他</option>
                                    </select>
                                </div>
                                <div class="col-12 mb-2">
                                    <label class="small text-muted font-weight-bold">詳細說明</label>
                                    <textarea class="form-control form-control-sm" rows="2" placeholder="請輸入潛勢調查說明..." v-model="form.OtherChkMemo"></textarea>
                                </div>
                            </div>

                            <div class="photo-upload-section">
                                <photo-box title="潛勢調查照片 1" photo-key="其他潛勢調查照片1" memo-key="FileMemo_10a" :parent="this"></photo-box>
                                <photo-box title="潛勢調查照片 2" photo-key="其他潛勢調查照片2" memo-key="FileMemo_10b" :parent="this"></photo-box>
                            </div>
                        </div>
                    </div>

                    <!-- 項目十二：執行道路髒污抽查 -->
                    <div class="card-modern" :id="'sec-12'">
                        <div class="card-modern-header">
                            <h3 class="card-modern-title">
                                <i class="fas fa-broom text-success"></i>
                                <span>十二、執行道路髒污抽查</span>
                            </h3>
                        </div>
                        <div class="card-modern-body p-3">
                            <div class="row">
                                <div class="col-md-6 col-12 mb-3">
                                    <label class="small text-muted font-weight-bold">是否執行道路髒污抽查</label>
                                    <div class="segmented-group d-flex w-100">
                                        <button type="button" class="segment-btn flex-fill" :class="{ 'active-yes': form.CleanRoad_Ans1 === '是' }" v-on:click="form.CleanRoad_Ans1 = '是'">是</button>
                                        <button type="button" class="segment-btn flex-fill" :class="{ 'active-no': form.CleanRoad_Ans1 === '否' }" v-on:click="form.CleanRoad_Ans1 = '否'">否</button>
                                    </div>
                                </div>
                                <div v-if="form.CleanRoad_Ans1 === '是'" class="col-md-6 col-12 mb-3">
                                    <label class="small text-muted font-weight-bold">抽查道路名稱</label>
                                    <input type="text" class="form-control form-control-sm" placeholder="請輸入道路名稱" v-model="form.CleanRoad_Ans2_RoadName" />
                                </div>
                            </div>

                            <div v-if="form.CleanRoad_Ans1 === '是'" class="card bg-light border p-3 mb-3">
                                <h6 class="font-weight-bold text-dark mb-2">認養道路路段清潔狀況評估</h6>
                                <div class="row">
                                    <div class="col-md-4 col-12 mb-2">
                                        <div class="custom-control custom-checkbox mb-1">
                                            <input type="checkbox" class="custom-control-input" id="chk_clean_a" v-model="chkForm.CleanRoad_Ans2_CleanLV_A" v-on:change="onCleanChkChange('A')" />
                                            <label class="custom-control-label font-weight-bold text-success" for="chk_clean_a">良好 (A級)</label>
                                        </div>
                                        <div class="input-group input-group-sm">
                                            <input type="number" class="form-control" v-model="form.CleanRoad_Ans2_CleanLength_A" placeholder="長度" />
                                            <div class="input-group-append"><span class="input-group-text">公尺</span></div>
                                        </div>
                                    </div>

                                    <div class="col-md-4 col-12 mb-2">
                                        <div class="custom-control custom-checkbox mb-1">
                                            <input type="checkbox" class="custom-control-input" id="chk_clean_b" v-model="chkForm.CleanRoad_Ans2_CleanLV_B" v-on:change="onCleanChkChange('B')" />
                                            <label class="custom-control-label font-weight-bold text-warning" for="chk_clean_b">普通 (B級)</label>
                                        </div>
                                        <div class="input-group input-group-sm">
                                            <input type="number" class="form-control" v-model="form.CleanRoad_Ans2_CleanLength_B" placeholder="長度" />
                                            <div class="input-group-append"><span class="input-group-text">公尺</span></div>
                                        </div>
                                    </div>

                                    <div class="col-md-4 col-12 mb-2">
                                        <div class="custom-control custom-checkbox mb-1">
                                            <input type="checkbox" class="custom-control-input" id="chk_clean_c" v-model="chkForm.CleanRoad_Ans2_CleanLV_C" v-on:change="onCleanChkChange('C')" />
                                            <label class="custom-control-label font-weight-bold text-danger" for="chk_clean_c">待改進 (C級)</label>
                                        </div>
                                        <div class="input-group input-group-sm mb-1">
                                            <input type="text" class="form-control" v-model="form.CleanRoad_Ans2_CleanRoadName" placeholder="待改進路段" />
                                        </div>
                                        <div class="input-group input-group-sm">
                                            <input type="number" class="form-control" v-model="form.CleanRoad_Ans2_CleanLength_C" placeholder="長度" />
                                            <div class="input-group-append"><span class="input-group-text">公尺</span></div>
                                        </div>
                                    </div>

                                    <div class="col-12 mt-2">
                                        <label class="small text-muted font-weight-bold">認養道路旁水溝是否保持暢通</label>
                                        <div class="segmented-group d-flex w-100">
                                            <button type="button" class="segment-btn flex-fill" :class="{ 'active-yes': form.CleanRoad_Ans3 === '是' }" v-on:click="form.CleanRoad_Ans3 = '是'">是</button>
                                            <button type="button" class="segment-btn flex-fill" :class="{ 'active-no': form.CleanRoad_Ans3 === '否' }" v-on:click="form.CleanRoad_Ans3 = '否'">否</button>
                                        </div>
                                    </div>

                                    <div class="col-12 mt-2">
                                        <label class="small text-muted font-weight-bold">說明</label>
                                        <textarea class="form-control form-control-sm" rows="2" placeholder="道路清潔狀況補充說明..." v-model="form.CleanRoad_Ans4"></textarea>
                                    </div>
                                </div>
                            </div>

                            <div class="photo-upload-section">
                                <photo-box title="道路抽查照片 1" photo-key="執行道路髒污抽查照片1" memo-key="FileMemo_11a" :parent="this"></photo-box>
                                <photo-box title="道路抽查照片 2" photo-key="執行道路髒污抽查照片2" memo-key="FileMemo_11b" :parent="this"></photo-box>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </main>

        <!-- 手機端常駐浮動動作列 (Sticky Bottom Bar) -->
        <div class="mobile-bottom-bar d-lg-none no-print">
            <button type="button" class="btn btn-outline-primary" v-on:click="openSignatureModal">
                <i class="fas fa-signature mr-1"></i> 手寫簽名
            </button>
            <button type="button" class="btn btn-primary" v-on:click="submitData" :disabled="saving">
                <i class="fas" :class="saving ? 'fa-spinner fa-spin' : 'fa-save'"></i>
                <span>{{ saving ? '儲存中...' : '儲存巡查' }}</span>
            </button>
        </div>

        <!-- 全螢幕觸控電子簽名 Modal -->
        <div v-if="sigModalOpen" class="sig-modal-backdrop" v-on:click.self="closeSignatureModal">
            <div class="sig-modal-container">
                <div class="card-modern-header">
                    <h4 class="card-modern-title">
                        <i class="fas fa-pen-nib text-primary"></i>
                        <span>外勤電子手寫簽名</span>
                    </h4>
                    <div class="segmented-group">
                        <button type="button" class="segment-btn" :class="{ 'active-blue': currentSigType === 'inspector' }" v-on:click="switchSigType('inspector')">
                            稽查員簽名
                        </button>
                        <button type="button" class="segment-btn" :class="{ 'active-blue': currentSigType === 'representative' }" v-on:click="switchSigType('representative')">
                            受訪代表簽名
                        </button>
                    </div>
                </div>

                <div class="sig-canvas-wrapper">
                    <canvas id="sigCanvas"></canvas>
                </div>

                <div class="p-3 bg-light border-top d-flex justify-content-between align-items-center">
                    <button type="button" class="btn btn-outline-secondary btn-sm" v-on:click="clearCanvas">
                        <i class="fas fa-eraser mr-1"></i> 清除重寫
                    </button>
                    <div>
                        <button type="button" class="btn btn-secondary btn-sm mr-2" v-on:click="closeSignatureModal">取消</button>
                        <button type="button" class="btn btn-primary btn-sm font-weight-bold" v-on:click="saveCanvasSignature">
                            <i class="fas fa-check mr-1"></i> 確定套用
                        </button>
                    </div>
                </div>
            </div>
        </div>

        <!-- 申報設備與製程明細 Modal 視窗 -->
        <div v-if="deviceModalOpen" class="modal-custom-backdrop" v-on:click.self="deviceModalOpen = false">
            <div class="modal-custom-box">
                <div class="card-modern-header">
                    <h4 class="card-modern-title">
                        <i class="fas fa-cogs text-primary"></i>
                        <span>場所申報原物料與製程設備清單</span>
                    </h4>
                    <button type="button" class="close" v-on:click="deviceModalOpen = false">&times;</button>
                </div>
                <div class="modal-custom-body">
                    <!-- 設備統計卡片 -->
                    <h6 class="font-weight-bold text-dark mb-2">各類型設備統計數量</h6>
                    <div class="table-responsive mb-3">
                        <table class="table table-sm table-bordered table-hover small">
                            <thead class="thead-light">
                                <tr>
                                    <th>類型代碼</th>
                                    <th>設備名稱</th>
                                    <th>申報數量</th>
                                    <th>操作</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr v-for="dev in devSummary" :key="dev.pCode + dev.Device_Name">
                                    <td><span class="badge badge-info">{{ dev.pCode }}</span></td>
                                    <td>{{ dev.Device_Name }}</td>
                                    <td class="font-weight-bold">{{ dev.pCount }}</td>
                                    <td>
                                        <button type="button" class="btn btn-xs btn-outline-primary py-0" v-on:click="loadDeviceDetail(dev.pCode, dev.Device_Name)">
                                            查看明細
                                        </button>
                                    </td>
                                </tr>
                                <tr v-if="devSummary.length === 0">
                                    <td colspan="4" class="text-center text-muted">查無申報設備統計資料</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>

                    <!-- 詳細明細 -->
                    <div v-if="devDetailList.length > 0">
                        <h6 class="font-weight-bold text-dark mb-1">設備明細清單 ({{ devDetailList.length }} 筆)</h6>
                        <div class="table-responsive mb-3" style="max-height: 200px;">
                            <table class="table table-sm table-striped small">
                                <thead>
                                    <tr>
                                        <th>設備編號</th>
                                        <th>設備代碼</th>
                                        <th>設備名稱</th>
                                        <th>儲存物料</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr v-for="(d, i) in devDetailList" :key="i">
                                        <td>{{ d.Device_NO }}</td>
                                        <td>{{ d.Device_Code }}</td>
                                        <td>{{ d.Device_Name }}</td>
                                        <td>{{ d.Store_substance || '-' }}</td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>

                    <div v-if="procDetailList.length > 0">
                        <h6 class="font-weight-bold text-dark mb-1">製程明細清單 ({{ procDetailList.length }} 筆)</h6>
                        <div class="table-responsive" style="max-height: 160px;">
                            <table class="table table-sm table-striped small">
                                <thead>
                                    <tr>
                                        <th>製程編號</th>
                                        <th>製程名稱</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr v-for="(p, i) in procDetailList" :key="i">
                                        <td>{{ p.Process_NO }}</td>
                                        <td>{{ p.Process_Name }}</td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
                <div class="p-2 bg-light border-top text-right">
                    <button type="button" class="btn btn-secondary btn-sm" v-on:click="deviceModalOpen = false">關閉</button>
                </div>
            </div>
        </div>

        <!-- 燈箱圖片放大預覽 Modal -->
        <div v-if="previewImageUrl" class="lightbox-modal" v-on:click="previewImageUrl = null">
            <img :src="previewImageUrl" class="lightbox-img" alt="放大預覽" />
        </div>
    </div>

    <!-- 本地核心 JS 依賴 (嚴禁外部 CDN) -->
    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>
    <script src="../Scripts/leaflet/leaflet.js"></script>

    <script type="text/javascript">
        // 照片卡片子元件
        const PhotoBoxComponent = {
            props: ['title', 'photoKey', 'memoKey', 'parent'],
            template: `
                <div class="photo-card">
                    <div class="photo-card-title">
                        <span>{{ title }}</span>
                        <span v-if="hasPhoto" class="badge badge-success" style="font-size: 10px;">已拍照</span>
                        <span v-else class="badge badge-light text-muted" style="font-size: 10px;">未附圖</span>
                    </div>

                    <div class="photo-thumb-box" v-on:click="onThumbClick">
                        <img v-if="hasPhoto" :src="photoUrl" class="photo-thumb-img" alt="照片縮圖" />
                        <div v-else class="text-center text-muted">
                            <i class="fas fa-camera fa-2x mb-1 text-secondary"></i>
                            <div style="font-size: 11px;">點擊拍照或上傳</div>
                        </div>
                    </div>

                    <input type="file" :id="'file_' + photoKey" accept="image/*" capture="environment" style="display: none;" v-on:change="onFileSelected" />

                    <div class="photo-btn-group">
                        <button type="button" class="btn btn-outline-primary" v-on:click="triggerCamera">
                            <i class="fas fa-camera"></i> 拍攝
                        </button>
                        <button v-if="hasPhoto" type="button" class="btn btn-outline-danger" v-on:click="removePhoto">
                            <i class="fas fa-trash-alt"></i> 清除
                        </button>
                    </div>

                    <input type="text" class="form-control form-control-sm mt-1" style="font-size: 11px;" placeholder="照片補充說明..." v-model="parent.form[memoKey]" />
                </div>
            `,
            computed: {
                hasPhoto() {
                    return !!(this.parent.photos[this.photoKey] || this.parent.existingPhotos[this.photoKey]);
                },
                photoUrl() {
                    return this.parent.photos[this.photoKey] || this.parent.existingPhotos[this.photoKey];
                }
            },
            methods: {
                triggerCamera() {
                    const input = document.getElementById('file_' + this.photoKey);
                    if (input) input.click();
                },
                onThumbClick() {
                    if (this.hasPhoto) {
                        this.parent.previewImageUrl = this.photoUrl;
                    } else {
                        this.triggerCamera();
                    }
                },
                onFileSelected(e) {
                    const file = e.target.files[0];
                    if (!file) return;

                    const reader = new FileReader();
                    reader.onload = (uploadEvent) => {
                        const img = new Image();
                        img.onload = () => {
                            // 前端等比例壓縮至長邊最高 1600px，防止圖片過大卡死外勤網路
                            const canvas = document.createElement('canvas');
                            let w = img.width;
                            let h = img.height;
                            const maxDim = 1600;
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

                            this.parent.photos[this.photoKey] = compressedBase64;
                        };
                        img.src = uploadEvent.target.result;
                    };
                    reader.readAsDataURL(file);
                },
                removePhoto() {
                    delete this.parent.photos[this.photoKey];
                    delete this.parent.existingPhotos[this.photoKey];
                    const input = document.getElementById('file_' + this.photoKey);
                    if (input) input.value = '';
                }
            }
        };

        const { createApp, markRaw } = Vue;

        createApp({
            components: {
                'photo-box': PhotoBoxComponent
            },
            data() {
                return {
                    loading: true,
                    saving: false,
                    errorMessage: '',
                    mode: 'new',
                    facId: '',
                    invNo: 0,
                    loginUser: '',
                    facInfo: {},
                    devSummary: [],
                    reviewList: [],
                    existingPhotos: {},
                    photos: {},
                    signatures: {
                        inspector: '',
                        representative: ''
                    },

                    // 查核表主資料模型
                    form: {
                        INV_DATE: '',
                        INV_TIME: '',
                        weather: '晴',
                        Work_State: '正常操作',
                        Work_Memo: '',

                        // 各項0點/文字說明
                        INV_01_01: '', INV_01_02: 'V', INV_01_03: '', INV_01_03_Memo: '',
                        INV_02_01: '', INV_02_02: '', INV_02_03: 'V', INV_02_04: '', INV_02_04_Memo: '',
                        INV_03_01: '', INV_03_02: 'V', INV_03_03: '', INV_03_03_Memo: '',
                        INV_04_01: '', INV_04_02: 'V', INV_04_03: '', INV_04_03_Memo: '',
                        INV_05_01: '', INV_05_02: 'V', INV_05_03: '', INV_05_03_Memo: '',
                        INV_06_01: '', INV_06_02: '', INV_06_03: 'V', INV_06_04: '', INV_06_04_Memo: '',
                        INV_07_01: '', INV_07_02: 'V', INV_07_03: '', INV_07_03_Memo: '',
                        INV_08_01: '', INV_08_02: 'V', INV_08_03: '', INV_08_03_Memo: '',
                        INV_09_01: '', INV_09_02: 'V', INV_09_03: '', INV_09_03_Memo: '',

                        // 洗車台規格
                        WashCar_Type: '加壓沖洗設備',
                        WashCar_Length: '',
                        WashCar_Width: '',
                        SinkDepth: '',
                        SinkWaterDepth: '',
                        SpoutLen: '',
                        MotorHP: '',
                        WarningWashCar: '有',
                        WashCarMemo: '有',

                        // 環境潛勢與道路抽查
                        EnvirCheck_Item: '',
                        EnvirCheck_Other: '',
                        OtherChkAns1: '無',
                        OtherChkAns2: '設備C:個數差異',
                        OtherChkMemo: '',
                        CleanRoad_Ans1: '否',
                        CleanRoad_Ans2_RoadName: '',
                        CleanRoad_Ans2_CleanLV_A: '',
                        CleanRoad_Ans2_CleanLV_B: '',
                        CleanRoad_Ans2_CleanLV_C: '',
                        CleanRoad_Ans2_CleanLength_A: 0,
                        CleanRoad_Ans2_CleanLength_B: 0,
                        CleanRoad_Ans2_CleanLength_C: 0,
                        CleanRoad_Ans2_CleanRoadName: '',
                        CleanRoad_Ans3: '是',
                        CleanRoad_Ans4: '',

                        // 照片說明
                        FileMemo_1: '', FileMemo_1a: '', FileMemo_1b: '', FileMemo_1c: '', FileMemo_1d: '',
                        FileMemo_2: '', FileMemo_2a: '',
                        FileMemo_3: '', FileMemo_3a: '',
                        FileMemo_4: '', FileMemo_4a: '',
                        FileMemo_5: '', FileMemo_5a: '', FileMemo_5b: '', FileMemo_5c: '', FileMemo_5d: '',
                        FileMemo_5e: '', FileMemo_5f: '', FileMemo_5g: '', FileMemo_5h: '', FileMemo_5i: '',
                        FileMemo_6: '', FileMemo_6a: '', FileMemo_6b: '', FileMemo_6c: '', FileMemo_6d: '',
                        FileMemo_7: '', FileMemo_7a: '',
                        FileMemo_8: '', FileMemo_8a: '',
                        FileMemo_9: '', FileMemo_9a: '',
                        FileMemo_AllView: '', FileMemo_Entrance: '',
                        FileMemo_10a: '', FileMemo_10b: '',
                        FileMemo_11a: '', FileMemo_11b: '',
                        FileMemo_Counseling1: '', FileMemo_Counseling2: '',
                        FileMemo_CollGasEfficiency1: '', FileMemo_CollGasEfficiency2: '',
                        FileMemo_CollGasEfficiency3: '', FileMemo_CollGasEfficiency4: '',
                        FileMemo_AirQualityValue1: '', FileMemo_AirQualityValue2: ''
                    },

                    // 勾選暫存物件 (布林響應)
                    chkForm: {},

                    // 環境潛勢選項清單
                    envCheckOptions: ['廠區有明顯異味', '有排放污水', '噪音污染', '排放黑煙', '其他'],
                    envCheckSelected: [],

                    // UI 互動控制
                    mapCollapsed: false,
                    userDistance: null,
                    userDistanceText: '',
                    previewImageUrl: null,
                    deviceModalOpen: false,
                    devDetailList: [],
                    procDetailList: [],

                    // 簽名板狀態
                    sigModalOpen: false,
                    currentSigType: 'inspector',
                    canvasCtx: null
                };
            },
            computed: {
                totalLossPoints() {
                    let total = 0;
                    for (let i = 1; i <= 9; i++) {
                        total += this.getSectionLoss(i);
                    }
                    return total;
                },
                sectionLossList() {
                    const titles = [
                        '一.堆置', '二.輸送', '三.車輛', '四.路徑',
                        '五.清洗', '六.製程', '七.裸露', '八.道路', '九.監控'
                    ];
                    const res = [];
                    for (let i = 1; i <= 9; i++) {
                        res.push({
                            id: i,
                            shortTitle: titles[i - 1],
                            loss: this.getSectionLoss(i)
                        });
                    }
                    return res;
                }
            },
            created() {
                // 初始化全勾選欄位
                const allCheckKeys = [
                    'INV_01_01', 'INV_01_02', 'INV_01_03', 'INV_01_04', 'INV_01_05', 'INV_01_08',
                    'INV_01_09', 'INV_01_09a', 'INV_01_09b', 'INV_01_09c', 'INV_01_09d',
                    'INV_01_10', 'INV_01_10a', 'INV_01_10b',
                    'INV_01_11', 'INV_01_11a', 'INV_01_11b', 'INV_01_11c',
                    'INV_01_12', 'INV_01_12a', 'INV_01_12b', 'INV_01_12c',
                    'INV_01_13', 'INV_01_14',
                    'INV_02_01', 'INV_02_02', 'INV_02_03', 'INV_02_04', 'INV_02_05', 'INV_02_06',
                    'INV_02_07', 'INV_02_08', 'INV_02_09', 'INV_02_09a', 'INV_02_09b',
                    'INV_02_10', 'INV_02_10a', 'INV_02_10b', 'INV_02_10c',
                    'INV_03_01', 'INV_03_02', 'INV_03_03', 'INV_03_04', 'INV_03_05', 'INV_03_06', 'INV_03_07', 'INV_03_08',
                    'INV_04_01', 'INV_04_02', 'INV_04_03', 'INV_04_04', 'INV_04_05', 'INV_04_06', 'INV_04_07', 'INV_04_08',
                    'INV_05_01', 'INV_05_02', 'INV_05_03', 'INV_05_04', 'INV_05_05', 'INV_05_06', 'INV_05_07', 'INV_05_08', 'INV_05_09', 'INV_05_10',
                    'INV_06_01', 'INV_06_02', 'INV_06_03', 'INV_06_04', 'INV_06_05', 'INV_06_06', 'INV_06_07', 'INV_06_07a', 'INV_06_07b',
                    'INV_06_08', 'INV_06_08a', 'INV_06_08b', 'INV_06_09', 'INV_06_10', 'INV_06_11',
                    'INV_07_01', 'INV_07_02', 'INV_07_03', 'INV_07_04', 'INV_07_05', 'INV_07_06', 'INV_07_07', 'INV_07_08', 'INV_07_09', 'INV_07_10',
                    'INV_08_01', 'INV_08_02', 'INV_08_03', 'INV_08_04', 'INV_08_05', 'INV_08_06', 'INV_08_07', 'INV_08_08', 'INV_08_09',
                    'INV_09_01', 'INV_09_02', 'INV_09_03', 'INV_09_04', 'INV_09_05', 'INV_09_06', 'INV_09_07', 'INV_09_08',
                    'CleanRoad_Ans2_CleanLV_A', 'CleanRoad_Ans2_CleanLV_B', 'CleanRoad_Ans2_CleanLV_C'
                ];
                allCheckKeys.forEach(k => {
                    this.chkForm[k] = false;
                });
            },
            mounted() {
                this.loadInitData();
            },
            methods: {
                // 1. 初始化資料載入
                async loadInitData() {
                    this.loading = true;
                    this.errorMessage = '';

                    const urlParams = new URLSearchParams(window.location.search);
                    this.facId = urlParams.get('id') || '';
                    const token = urlParams.get('id1') || '';
                    this.mode = urlParams.get('mode') || 'new';
                    const invNoStr = urlParams.get('id2') || '0';

                    if (!this.facId) {
                        this.errorMessage = '缺少場所管制編號參數 (id)';
                        this.loading = false;
                        return;
                    }

                    try {
                        const res = await axios.get(`NewCase.aspx?action=init&id=${encodeURIComponent(this.facId)}&id1=${encodeURIComponent(token)}&mode=${encodeURIComponent(this.mode)}&id2=${encodeURIComponent(invNoStr)}`);
                        if (res.data && res.data.Success) {
                            this.facInfo = res.data.FacInfo || {};
                            this.devSummary = res.data.DevSummary || [];
                            this.reviewList = res.data.ReviewList || [];
                            this.existingPhotos = res.data.ExistingPhotos || {};
                            this.invNo = res.data.InvNo || 0;
                            this.loginUser = res.data.LoginUser || '外勤查核人員';

                            if (this.mode === 'edit' && res.data.RecordData && Object.keys(res.data.RecordData).length > 0) {
                                this.bindExistingRecord(res.data.RecordData);
                            } else {
                                // 新增模式預設當前日期時間
                                const now = new Date();
                                const yyyy = now.getFullYear();
                                const mm = String(now.getMonth() + 1).padStart(2, '0');
                                const dd = String(now.getDate()).padStart(2, '0');
                                const hh = String(now.getHours()).padStart(2, '0');
                                const min = String(now.getMinutes()).padStart(2, '0');
                                this.form.INV_DATE = `${yyyy}-${mm}-${dd}`;
                                this.form.INV_TIME = `${hh}:${min}`;
                                this.quickPassAll();
                            }

                            // 初始化地圖 (延遲等 DOM 渲染完畢)
                            this.$nextTick(() => {
                                this.initLeafletMap();
                            });
                        } else {
                            this.errorMessage = (res.data && res.data.Message) ? res.data.Message : '資料載入失敗。';
                        }
                    } catch (err) {
                        this.errorMessage = '系統連線異常：' + err.message;
                    } finally {
                        this.loading = false;
                    }
                },

                // 2. 既有紀錄資料綁定 (編輯模式)
                bindExistingRecord(data) {
                    for (const key in data) {
                        if (this.form.hasOwnProperty(key)) {
                            this.form[key] = data[key];
                        }
                        if (this.chkForm.hasOwnProperty(key)) {
                            this.chkForm[key] = (data[key] === 'V' || data[key] === 'Y');
                        }
                    }

                    // 日期時間分離
                    if (data.INV_DATE) {
                        const parts = data.INV_DATE.split(' ');
                        this.form.INV_DATE = parts[0] || '';
                        this.form.INV_TIME = parts[1] || '';
                    }

                    // 環境潛勢複選
                    if (data.EnvirCheck_Item) {
                        this.envCheckSelected = data.EnvirCheck_Item.split('、').filter(Boolean);
                    }
                },

                // 3. Leaflet 地圖初始化 (嚴格 markRaw 隔離宣告，防 Vue 3 響應式崩潰)
                initLeafletMap() {
                    const mapEl = document.getElementById('map');
                    if (!mapEl) return;

                    const lat = (this.facInfo.Lat && this.facInfo.Lat > 0) ? this.facInfo.Lat : 25.0125;
                    const lng = (this.facInfo.Lng && this.facInfo.Lng > 0) ? this.facInfo.Lng : 121.465;

                    try {
                        const map = L.map('map', {
                            center: [lat, lng],
                            zoom: (this.facInfo.Lat > 0) ? 16 : 13,
                            zoomControl: true
                        });

                        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                            maxZoom: 19,
                            attribution: '© OpenStreetMap'
                        }).addTo(map);

                        if (this.facInfo.Lat > 0 && this.facInfo.Lng > 0) {
                            const marker = L.marker([lat, lng]).addTo(map);
                            marker.bindPopup(`<b>${this.facInfo.FAC_NAME}</b><br/>${this.facInfo.ADDR || ''}`).openPopup();
                        }

                        // 物件隔離保存至原生屬性
                        this.leafletMap = markRaw(map);
                    } catch (e) {
                        console.error('Map init error:', e);
                    }
                },

                toggleMapCollapse() {
                    this.mapCollapsed = !this.mapCollapsed;
                    this.$nextTick(() => {
                        if (this.leafletMap) {
                            this.leafletMap.invalidateSize();
                        }
                    });
                },

                locateGPS() {
                    if (!navigator.geolocation) {
                        alert('您的瀏覽器不支援 GPS 定位功能。');
                        return;
                    }

                    navigator.geolocation.getCurrentPosition(
                        (pos) => {
                            const uLat = pos.coords.latitude;
                            const uLng = pos.coords.longitude;

                            if (this.leafletMap) {
                                if (this.userMarker) {
                                    this.leafletMap.removeLayer(this.userMarker);
                                }
                                const userIcon = L.divIcon({
                                    className: 'custom-user-marker',
                                    html: '<div style="background:#0284c7;width:16px;height:16px;border-radius:50%;border:3px solid #fff;box-shadow:0 0 8px rgba(2,132,199,0.8);"></div>'
                                });
                                this.userMarker = markRaw(L.marker([uLat, uLng], { icon: userIcon }).addTo(this.leafletMap));
                                this.userMarker.bindPopup('<b>您的現場目前位置</b>').openPopup();
                                this.leafletMap.setView([uLat, uLng], 16);
                            }

                            // 計算距離
                            if (this.facInfo.Lat > 0 && this.facInfo.Lng > 0) {
                                const distMeters = this.calcDistanceMeters(uLat, uLng, this.facInfo.Lat, this.facInfo.Lng);
                                this.userDistance = distMeters;
                                this.userDistanceText = distMeters >= 1000 ? `${(distMeters / 1000).toFixed(2)} 公里` : `${Math.round(distMeters)} 公尺`;
                            }
                        },
                        (err) => {
                            alert('無法取得您的現場 GPS 定位：' + err.message);
                        },
                        { enableHighAccuracy: true, timeout: 10000 }
                    );
                },

                calcDistanceMeters(lat1, lon1, lat2, lon2) {
                    const R = 6371e3;
                    const p1 = (lat1 * Math.PI) / 180;
                    const p2 = (lat2 * Math.PI) / 180;
                    const dp = ((lat2 - lat1) * Math.PI) / 180;
                    const dl = ((lon2 - lon1) * Math.PI) / 180;
                    const a = Math.sin(dp / 2) * Math.sin(dp / 2) + Math.cos(p1) * Math.cos(p2) * Math.sin(dl / 2) * Math.sin(dl / 2);
                    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
                    return R * c;
                },

                openGoogleNavigation() {
                    if (this.facInfo.Lat && this.facInfo.Lng) {
                        window.open(`https://www.google.com/maps/dir/?api=1&destination=${this.facInfo.Lat},${this.facInfo.Lng}`, '_blank');
                    }
                },

                // 4. 記點計算法 (完全對照 LossPointCalculator 規則)
                getSectionLoss(secNum) {
                    const cf = this.chkForm;
                    if (secNum === 1) {
                        if (cf.INV_01_04 || cf.INV_01_05) return 10;
                        if (cf.INV_01_08 || cf.INV_01_09 || cf.INV_01_09a || cf.INV_01_09b || cf.INV_01_09c || cf.INV_01_09d ||
                            cf.INV_01_10 || cf.INV_01_10a || cf.INV_01_10b || cf.INV_01_11 || cf.INV_01_11a || cf.INV_01_11b ||
                            cf.INV_01_11c || cf.INV_01_12 || cf.INV_01_12a || cf.INV_01_12b || cf.INV_01_12c || cf.INV_01_13 || cf.INV_01_14) return 4;
                        return 0;
                    }
                    if (secNum === 2) {
                        if (cf.INV_02_05 || cf.INV_02_06) return 10;
                        if (cf.INV_02_07 || cf.INV_02_08 || cf.INV_02_09 || cf.INV_02_09a || cf.INV_02_09b ||
                            cf.INV_02_10 || cf.INV_02_10a || cf.INV_02_10b || cf.INV_02_10c) return 4;
                        return 0;
                    }
                    if (secNum === 3) {
                        if (cf.INV_03_04 || cf.INV_03_05 || cf.INV_03_06) return 10;
                        if (cf.INV_03_07 || cf.INV_03_08) return 4;
                        return 0;
                    }
                    if (secNum === 4) {
                        if (cf.INV_04_04 || cf.INV_04_05) return 10;
                        if (cf.INV_04_06 || cf.INV_04_07 || cf.INV_04_08) return 4;
                        return 0;
                    }
                    if (secNum === 5) {
                        if (cf.INV_05_04 || cf.INV_05_05 || cf.INV_05_06) return 10;
                        if (cf.INV_05_07 || cf.INV_05_08 || cf.INV_05_09 || cf.INV_05_10) return 4;
                        return 0;
                    }
                    if (secNum === 6) {
                        if (cf.INV_06_05 || cf.INV_06_06) return 10;
                        if (cf.INV_06_07 || cf.INV_06_07a || cf.INV_06_07b || cf.INV_06_08 || cf.INV_06_08a ||
                            cf.INV_06_08b || cf.INV_06_09 || cf.INV_06_10 || cf.INV_06_11) return 4;
                        return 0;
                    }
                    if (secNum === 7) {
                        if (cf.INV_07_04 || cf.INV_07_05) return 10;
                        if (cf.INV_07_06 || cf.INV_07_07 || cf.INV_07_08 || cf.INV_07_09 || cf.INV_07_10) return 4;
                        return 0;
                    }
                    if (secNum === 8) {
                        if (cf.INV_08_04 || cf.INV_08_05) return 10;
                        if (cf.INV_08_06 || cf.INV_08_07 || cf.INV_08_08 || cf.INV_08_09) return 4;
                        return 0;
                    }
                    if (secNum === 9) {
                        if (cf.INV_09_04 || cf.INV_09_05 || cf.INV_09_06) return 10;
                        if (cf.INV_09_07 || cf.INV_09_08) return 4;
                        return 0;
                    }
                    return 0;
                },

                // 5. 記點晶片一鍵設定 (0, 4, 10 點)
                setSectionScore(secNum, score, zeroKey) {
                    const pad = String(secNum).padStart(2, '0');

                    // 清除該項所有 0/4/10 點勾選
                    for (const k in this.chkForm) {
                        if (k.startsWith(`INV_${pad}_`)) {
                            this.chkForm[k] = false;
                            this.form[k] = '';
                        }
                    }

                    if (score === 0) {
                        const targetKey = zeroKey || `INV_${pad}_02`;
                        this.chkForm[targetKey] = true;
                        this.form[targetKey] = 'V';
                    } else if (score === 10) {
                        const targetKey = `INV_${pad}_04`;
                        this.chkForm[targetKey] = true;
                        this.form[targetKey] = 'V';
                    } else if (score === 4) {
                        // 預設展開第1個4點細項
                        if (secNum === 1) this.chkForm.INV_01_08 = true;
                        else if (secNum === 2) this.chkForm.INV_02_07 = true;
                        else if (secNum === 3) this.chkForm.INV_03_07 = true;
                        else if (secNum === 4) this.chkForm.INV_04_06 = true;
                        else if (secNum === 5) this.chkForm.INV_05_07 = true;
                        else if (secNum === 6) this.chkForm.INV_06_09 = true;
                        else if (secNum === 7) this.chkForm.INV_07_06 = true;
                        else if (secNum === 8) this.chkForm.INV_08_06 = true;
                        else if (secNum === 9) this.chkForm.INV_09_07 = true;
                        this.syncFormFromChk();
                    }
                },

                // 6. 一鍵全部合格 (Quick Pass All)
                quickPassAll() {
                    for (let i = 1; i <= 9; i++) {
                        this.setSectionScore(i, 0);
                    }
                    this.form.weather = '晴';
                    this.form.Work_State = '正常操作';
                    this.form.WarningWashCar = '有';
                    this.form.WashCarMemo = '有';
                    this.form.OtherChkAns1 = '無';
                    this.form.CleanRoad_Ans1 = '否';
                },

                onChkChange(key) {
                    this.form[key] = this.chkForm[key] ? 'V' : '';
                },

                toggleGroup(parentKey, childKeys) {
                    this.form[parentKey] = this.chkForm[parentKey] ? 'V' : '';
                    if (!this.chkForm[parentKey]) {
                        childKeys.forEach(ck => {
                            this.chkForm[ck] = false;
                            this.form[ck] = '';
                        });
                    } else {
                        // 勾選母項時預設勾選第1個子項
                        if (childKeys.length > 0 && !this.chkForm[childKeys[0]]) {
                            this.chkForm[childKeys[0]] = true;
                            this.form[childKeys[0]] = 'V';
                        }
                    }
                },

                onSubChk(parentKey, subKey) {
                    this.form[subKey] = this.chkForm[subKey] ? 'V' : '';
                    if (this.chkForm[subKey]) {
                        this.chkForm[parentKey] = true;
                        this.form[parentKey] = 'V';
                    }
                },

                onCleanChkChange(lv) {
                    const key = 'CleanRoad_Ans2_CleanLV_' + lv;
                    this.form[key] = this.chkForm[key] ? 'Y' : 'N';
                },

                syncFormFromChk() {
                    for (const k in this.chkForm) {
                        this.form[k] = this.chkForm[k] ? 'V' : '';
                    }
                },

                // 7. 電子簽名板邏輯 (PointerEvents API + 二階貝茲曲線防斷筆)
                openSignatureModal() {
                    this.sigModalOpen = true;
                    this.$nextTick(() => {
                        this.initCanvas();
                    });
                },

                closeSignatureModal() {
                    this.sigModalOpen = false;
                },

                switchSigType(type) {
                    this.currentSigType = type;
                    this.clearCanvas();
                },

                initCanvas() {
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

                    let isDrawing = false;
                    let lastX = 0, lastY = 0;

                    const getPos = e => {
                        const r = canvas.getBoundingClientRect();
                        return { x: e.clientX - r.left, y: e.clientY - r.top };
                    };

                    const down = e => {
                        e.preventDefault();
                        try { canvas.setPointerCapture(e.pointerId); } catch (err) {}
                        isDrawing = true;
                        const pos = getPos(e);
                        lastX = pos.x; lastY = pos.y;
                        this.canvasCtx.beginPath();
                        this.canvasCtx.moveTo(lastX, lastY);
                    };

                    const move = e => {
                        if (!isDrawing) return;
                        e.preventDefault();
                        const pos = getPos(e);
                        const midX = (lastX + pos.x) / 2;
                        const midY = (lastY + pos.y) / 2;
                        this.canvasCtx.quadraticCurveTo(lastX, lastY, midX, midY);
                        this.canvasCtx.stroke();
                        lastX = pos.x; lastY = pos.y;
                    };

                    const up = e => {
                        if (!isDrawing) return;
                        isDrawing = false;
                        try { canvas.releasePointerCapture(e.pointerId); } catch (err) {}
                        this.canvasCtx.lineTo(lastX, lastY);
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
                        const dpr = window.devicePixelRatio || 1;
                        this.canvasCtx.clearRect(0, 0, canvas.width / dpr, canvas.height / dpr);
                    }
                },

                saveCanvasSignature() {
                    const canvas = document.getElementById('sigCanvas');
                    if (!canvas) return;

                    const dataUrl = canvas.toDataURL('image/png');
                    if (this.currentSigType === 'inspector') {
                        this.signatures.inspector = dataUrl;
                    } else {
                        this.signatures.representative = dataUrl;
                    }
                    this.sigModalOpen = false;
                },

                // 8. 申報設備詳細資料彈窗
                openDeviceModal() {
                    this.deviceModalOpen = true;
                    if (this.devSummary.length > 0 && this.devDetailList.length === 0) {
                        this.loadDeviceDetail(this.devSummary[0].pCode, this.devSummary[0].Device_Name);
                    }
                },

                async loadDeviceDetail(pCode, devName) {
                    try {
                        const res = await axios.get(`NewCase.aspx?action=getdevices&facId=${encodeURIComponent(this.facId)}&pCode=${encodeURIComponent(pCode)}&devName=${encodeURIComponent(devName)}`);
                        if (res.data && res.data.Success) {
                            this.devDetailList = res.data.Devices || [];
                            this.procDetailList = res.data.Processes || [];
                        }
                    } catch (e) {
                        console.error('loadDeviceDetail error:', e);
                    }
                },

                // 9. 儲存巡查紀錄 (POST 完整資料至後端)
                async submitData() {
                    if (!this.form.INV_DATE) {
                        alert('請填寫查核日期！');
                        return;
                    }

                    this.saving = true;
                    this.syncFormFromChk();

                    // 環境潛勢陣列組裝
                    this.form.EnvirCheck_Item = this.envCheckSelected.join('、');

                    // 簽名圖片組裝
                    const sigPayload = {};
                    if (this.signatures.inspector) {
                        sigPayload['稽查人員簽名'] = this.signatures.inspector;
                    }
                    if (this.signatures.representative) {
                        sigPayload['受訪代表簽名'] = this.signatures.representative;
                    }

                    const payload = {
                        FAC_ID: this.facId,
                        Mode: this.mode,
                        INV_NO: this.invNo,
                        Fields: this.form,
                        Photos: this.photos,
                        Signatures: sigPayload
                    };

                    try {
                        const res = await axios.post('NewCase.aspx?action=save', payload);
                        if (res.data && res.data.Success) {
                            alert(res.data.Message || '巡查紀錄儲存成功！');
                            if (res.data.RedirectUrl) {
                                window.location.href = res.data.RedirectUrl;
                            } else {
                                window.location.reload();
                            }
                        } else {
                            alert('儲存失敗：' + ((res.data && res.data.Message) ? res.data.Message : '未知錯誤'));
                        }
                    } catch (err) {
                        alert('傳輸失敗：' + err.message);
                    } finally {
                        this.saving = false;
                    }
                },

                goBack() {
                    if (confirm('確定要返回清單嗎？未儲存的變更將會遺失。')) {
                        const urlParams = new URLSearchParams(window.location.search);
                        const token = urlParams.get('id1') || '';
                        window.location.href = `CaseList.aspx?defid=${encodeURIComponent(this.facId)}&defid1=${encodeURIComponent(token)}`;
                    }
                }
            }
        }).mount('#newCaseApp');
    </script>
</body>
</html>
