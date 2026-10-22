<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="NewDirty.aspx.cs" Inherits="NTPC_FEC.RoadClean.NewDirty" %>
<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定溢散源管理平台 - 道路髒污通報單</title>
    
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
        .nav-btn {
            background: rgba(255, 255, 255, 0.15);
            border: none; color: #ffffff;
            font-size: 1.1rem; cursor: pointer;
            width: 38px; height: 38px; border-radius: 8px;
            display: flex; align-items: center; justify-content: center;
            transition: all 0.2s;
        }
        .nav-btn:hover { background-color: rgba(255, 255, 255, 0.3); }
        .top-navbar .brand-title {
            font-size: 1.1rem; font-weight: 700; margin: 0;
            display: flex; align-items: center; gap: 8px;
        }

        /* 容器佈局 */
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

        /* 桌面端左欄固頂 */
        @media screen and (min-width: 1200px) {
            .sticky-sidebar {
                position: sticky; top: 72px;
                max-height: calc(100vh - 88px);
                overflow-y: auto; padding-right: 4px;
            }
        }

        /* 資訊清單項目 (Info Item) */
        .info-row {
            display: flex; align-items: center; justify-content: space-between;
            padding: 8px 0; border-bottom: 1px dashed #e2e8f0;
            font-size: 0.92rem;
        }
        .info-row:last-child { border-bottom: none; }
        .info-label { color: var(--text-muted); font-weight: 600; display: flex; align-items: center; gap: 6px; }
        .info-value { font-weight: 700; color: var(--brand-navy); }

        /* 地圖控制與容器 */
        #map {
            width: 100%; height: 320px;
            border-radius: 8px; z-index: 10;
            transition: height 0.3s ease;
        }
        #map.map-collapsed { height: 100px !important; }

        /* 地圖座標標記 Pin */
        .custom-map-marker { display: flex; align-items: center; justify-content: center; }
        .marker-pin-dirty {
            width: 32px; height: 32px;
            border-radius: 50% 50% 50% 0;
            background: #ef4444;
            position: absolute; transform: rotate(-45deg);
            left: 50%; top: 50%; margin: -20px 0 0 -16px;
            box-shadow: 0 3px 8px rgba(0, 0, 0, 0.35);
            border: 2px solid #ffffff;
            display: flex; align-items: center; justify-content: center;
            cursor: pointer;
        }
        .marker-pin-dirty.pin-secondary { background: #f59e0b; }
        .marker-num { transform: rotate(45deg); color: #ffffff; font-weight: 800; font-size: 13px; }

        /* 坐標資訊晶片卡 (Coord Stat Card) */
        .coord-card {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 10px;
            padding: 12px;
            margin-bottom: 10px;
        }
        .coord-card.active-coord {
            border-color: var(--brand-blue);
            background: #f0f9ff;
            box-shadow: 0 0 0 2px rgba(2, 132, 199, 0.15);
        }
        .coord-header {
            display: flex; align-items: center; justify-content: space-between;
            margin-bottom: 8px;
        }
        .coord-title { font-weight: 700; font-size: 0.95rem; color: var(--brand-navy); display: flex; align-items: center; gap: 6px; }

        /* 快捷詞晶片按鈕 (Quick Chip) */
        .quick-phrase-group { display: flex; flex-wrap: wrap; gap: 6px; margin-top: 8px; }
        .quick-phrase-chip {
            background: #f1f5f9; border: 1px solid #cbd5e1;
            color: #334155; font-size: 12px; font-weight: 600;
            padding: 4px 10px; border-radius: 20px;
            cursor: pointer; transition: all 0.15s ease;
        }
        .quick-phrase-chip:hover {
            background: #e0f2fe; border-color: #0284c7; color: #0284c7;
        }

        /* 照片上傳與網格 (Photo Grid) */
        .photo-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
            gap: 14px;
            margin-top: 12px;
        }
        .photo-card {
            position: relative;
            background: #ffffff;
            border: 1px solid #e2e8f0;
            border-radius: 10px;
            overflow: hidden;
            box-shadow: 0 2px 6px rgba(0, 0, 0, 0.04);
            display: flex; flex-direction: column;
            transition: transform 0.15s, box-shadow 0.15s;
        }
        .photo-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
        }
        .photo-img-wrap {
            width: 100%; height: 140px;
            background: #0f172a;
            position: relative;
            cursor: pointer;
            display: flex; align-items: center; justify-content: center;
            overflow: hidden;
        }
        .photo-img-wrap img {
            width: 100%; height: 100%;
            object-fit: cover;
            transition: transform 0.3s ease;
        }
        .photo-img-wrap:hover img {
            transform: scale(1.05);
        }
        .photo-badge-num {
            position: absolute; top: 6px; left: 6px;
            background: rgba(15, 23, 42, 0.75); color: #ffffff;
            font-size: 11px; font-weight: 700;
            padding: 2px 8px; border-radius: 6px;
            backdrop-filter: blur(4px);
        }
        .photo-meta {
            padding: 8px 10px;
            display: flex; align-items: center; justify-content: space-between;
            background: #ffffff;
        }
        .photo-name {
            font-size: 12px; font-weight: 600; color: #334155;
            white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
            max-width: 110px;
        }
        .photo-del-btn {
            background: #fee2e2; border: none; color: #dc2626;
            width: 28px; height: 28px; border-radius: 6px;
            display: flex; align-items: center; justify-content: center;
            cursor: pointer; font-size: 12px; transition: background 0.15s;
        }
        .photo-del-btn:hover { background: #fecaca; }

        /* 上傳框 (Upload Dropzone) */
        .upload-dropzone {
            border: 2px dashed #94a3b8;
            border-radius: 10px;
            padding: 20px;
            text-align: center;
            background: #f8fafc;
            cursor: pointer;
            transition: all 0.2s;
            margin-bottom: 12px;
        }
        .upload-dropzone:hover {
            border-color: var(--brand-blue);
            background: #f0f9ff;
        }
        .upload-dropzone i { font-size: 2rem; color: var(--brand-blue); margin-bottom: 6px; }
        .upload-dropzone .title { font-weight: 700; color: #334155; font-size: 0.95rem; }
        .upload-dropzone .sub { font-size: 12px; color: #64748b; }

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

        /* 燈箱 Modal */
        .lightbox-overlay {
            position: fixed; top: 0; left: 0; right: 0; bottom: 0;
            background: rgba(15, 23, 42, 0.92);
            z-index: 2000;
            display: flex; align-items: center; justify-content: center;
            padding: 20px;
            backdrop-filter: blur(8px);
        }
        .lightbox-content {
            max-width: 90vw; max-height: 85vh;
            display: flex; flex-direction: column; align-items: center;
        }
        .lightbox-img {
            max-width: 100%; max-height: 80vh;
            border-radius: 8px; box-shadow: 0 8px 32px rgba(0,0,0,0.5);
            object-fit: contain;
        }
        .lightbox-close-btn {
            position: absolute; top: 20px; right: 20px;
            background: rgba(255, 255, 255, 0.2);
            color: #ffffff; border: none;
            width: 44px; height: 44px; border-radius: 50%;
            font-size: 1.4rem; cursor: pointer;
            display: flex; align-items: center; justify-content: center;
            transition: background 0.2s;
        }
        .lightbox-close-btn:hover { background: rgba(255, 255, 255, 0.4); }

        /* Alert 提示 Toast */
        .toast-notify {
            position: fixed; top: 68px; right: 20px; z-index: 1050;
            min-width: 280px; max-width: 420px;
            box-shadow: 0 4px 16px rgba(0, 0, 0, 0.15);
            border-radius: 8px; overflow: hidden;
            animation: slideInRight 0.3s ease;
        }
        @keyframes slideInRight {
            from { transform: translateX(100%); opacity: 0; }
            to { transform: translateX(0); opacity: 1; }
        }
    </style>
</head>
<body>
    <div id="dirtyApp" v-cloak>
        <!-- 頂部導覽列 -->
        <header class="top-navbar">
            <div class="d-flex align-items-center">
                <button type="button" class="nav-btn mr-3" v-on:click="goBack" title="返回上一頁">
                    <i class="fas fa-arrow-left"></i>
                </button>
                <h1 class="brand-title">
                    <i class="fas fa-exclamation-triangle text-warning"></i>
                    <span>道路髒污通報單</span>
                </h1>
            </div>

            <div class="d-flex align-items-center">
                <span class="badge badge-light px-3 py-2 mr-2 font-weight-bold" style="font-size: 13px;">
                    <i class="fas" :class="modeBadgeIcon"></i> {{ modeText }}
                </span>
                <button v-if="mode !== 'read'" type="button" class="btn btn-warning btn-sm font-weight-bold px-3 d-none d-md-inline-block" 
                        v-on:click="submitRecord" :disabled="isSubmitting">
                    <i class="fas fa-save mr-1"></i> {{ isSubmitting ? '儲存中...' : '確定送出' }}
                </button>
            </div>
        </header>

        <!-- 浮動通知提示 -->
        <div v-if="alertMessage" class="toast-notify alert" :class="'alert-' + alertType" role="alert">
            <div class="d-flex align-items-center justify-content-between">
                <span>
                    <i class="fas" :class="alertType === 'success' ? 'fa-check-circle' : 'fa-exclamation-circle'"></i>
                    {{ alertMessage }}
                </span>
                <button type="button" class="close ml-2" v-on:click="alertMessage = ''">&times;</button>
            </div>
        </div>

        <!-- 主體內容區塊 -->
        <main class="container-fluid-custom">
            <div class="row">
                <!-- 左欄：基本資訊、地圖、坐標定位 (40% 寬度，Desktop Sticky) -->
                <div class="col-12 col-xl-5">
                    <div class="sticky-sidebar">
                        <!-- 基本案件資訊卡片 -->
                        <div class="card-modern">
                            <div class="card-modern-header">
                                <h2 class="card-modern-title">
                                    <i class="fas fa-file-alt text-primary"></i>
                                    <span>通報案件基本資料</span>
                                </h2>
                                <span class="badge badge-primary px-2 py-1 font-weight-bold">
                                    {{ formData.DirtyId }}
                                </span>
                            </div>
                            <div class="card-modern-body">
                                <div class="info-row">
                                    <span class="info-label"><i class="fas fa-hashtag"></i> 顯示案號</span>
                                    <span class="info-value text-primary font-weight-bold">{{ formData.ShowId }}</span>
                                </div>
                                <div class="info-row">
                                    <span class="info-label"><i class="fas fa-clock"></i> 查核時間</span>
                                    <div v-if="mode !== 'read'">
                                        <input type="datetime-local" class="form-control form-control-sm font-weight-bold" 
                                               v-model="formData.ReportDate" style="width: 190px;" />
                                    </div>
                                    <span v-else class="info-value">{{ formatDisplayTime(formData.ReportDate) }}</span>
                                </div>
                                <div class="info-row">
                                    <span class="info-label"><i class="fas fa-user-check"></i> 查核人員</span>
                                    <span class="info-value">{{ formData.ReportUserName }} ({{ formData.ReportUser }})</span>
                                </div>
                                <div class="info-row">
                                    <span class="info-label"><i class="fas fa-tags"></i> 污染類別</span>
                                    <div v-if="mode !== 'read'">
                                        <select class="form-control form-control-sm font-weight-bold" v-model="formData.Kind" style="width: 190px;">
                                            <option value="EB">營建工程道路污染 (EB)</option>
                                            <option value="EF">固定逸散道路污染 (EF)</option>
                                            <option value="ES">道路砂石堆積污染 (ES)</option>
                                            <option value="OT">其他道路髒污通報</option>
                                        </select>
                                    </div>
                                    <span v-else class="info-value">{{ getKindName(formData.Kind) }}</span>
                                </div>
                            </div>
                        </div>

                        <!-- 現場互動地圖卡片 -->
                        <div class="card-modern">
                            <div class="card-modern-header">
                                <h2 class="card-modern-title">
                                    <i class="fas fa-map-marked-alt text-primary"></i>
                                    <span>現場地理位置標記</span>
                                </h2>
                                <div class="d-flex align-items-center gap-2">
                                    <button type="button" class="btn btn-outline-primary btn-sm py-1 px-2" 
                                            v-on:click="getCurrentGps(1)" title="以 GPS 定位通報坐標 1">
                                        <i class="fas fa-crosshairs text-danger"></i> GPS 坐標1
                                    </button>
                                    <button type="button" class="btn btn-outline-secondary btn-sm py-1 px-2" 
                                            v-on:click="resetMapView" title="全景重設">
                                        <i class="fas fa-compress-arrows-alt"></i>
                                    </button>
                                    <button type="button" class="btn btn-outline-secondary btn-sm py-1 px-2 d-xl-none" 
                                            v-on:click="toggleMapCollapse" :title="isMapCollapsed ? '展開地圖' : '收合地圖'">
                                        <i class="fas" :class="isMapCollapsed ? 'fa-chevron-down' : 'fa-chevron-up'"></i>
                                    </button>
                                </div>
                            </div>
                            <div class="card-modern-body p-2">
                                <div id="map" :class="{ 'map-collapsed': isMapCollapsed }"></div>
                                <small class="text-muted d-block mt-2 px-1">
                                    <i class="fas fa-info-circle text-info"></i>
                                    外勤作業提示：在地圖任意位置點擊可直接放置或更新坐標標記，亦可直接點擊「GPS 坐標」獲取手機定位。
                                </small>
                            </div>
                        </div>

                        <!-- 坐標設定與微調晶片卡 -->
                        <div class="card-modern">
                            <div class="card-modern-header">
                                <h2 class="card-modern-title">
                                    <i class="fas fa-location-arrow text-danger"></i>
                                    <span>通報坐標資訊 (TWD97)</span>
                                </h2>
                            </div>
                            <div class="card-modern-body">
                                <!-- 坐標 1 (必填) -->
                                <div class="coord-card" :class="{ 'active-coord': activeCoordIndex === 1 }">
                                    <div class="coord-header">
                                        <span class="coord-title text-danger">
                                            <i class="fas fa-map-marker-alt"></i> 通報坐標 1 (主要污染點 / 起點)
                                            <span class="badge badge-danger">必填</span>
                                        </span>
                                        <div class="d-flex align-items-center">
                                            <button v-if="mode !== 'read'" type="button" class="btn btn-sm btn-outline-danger py-0 px-2 mr-1"
                                                    v-on:click="getCurrentGps(1)">
                                                <i class="fas fa-crosshairs"></i> GPS定位
                                            </button>
                                            <button v-if="mode !== 'read'" type="button" class="btn btn-sm py-0 px-2"
                                                    :class="activeCoordIndex === 1 ? 'btn-danger' : 'btn-outline-secondary'"
                                                    v-on:click="activeCoordIndex = 1">
                                                {{ activeCoordIndex === 1 ? '點圖拾取中' : '地圖拾取' }}
                                            </button>
                                        </div>
                                    </div>
                                    <div class="row no-gutters">
                                        <div class="col-6 pr-1">
                                            <div class="input-group input-group-sm">
                                                <div class="input-group-prepend"><span class="input-group-text font-weight-bold">X (E)</span></div>
                                                <input type="number" class="form-control font-weight-bold" v-model.number="formData.S_UTME" 
                                                       v-on:change="onManualCoordChange(1)" :readonly="mode === 'read'" placeholder="例如 298123" />
                                            </div>
                                        </div>
                                        <div class="col-6 pl-1">
                                            <div class="input-group input-group-sm">
                                                <div class="input-group-prepend"><span class="input-group-text font-weight-bold">Y (N)</span></div>
                                                <input type="number" class="form-control font-weight-bold" v-model.number="formData.S_UTMN" 
                                                       v-on:change="onManualCoordChange(1)" :readonly="mode === 'read'" placeholder="例如 2767456" />
                                            </div>
                                        </div>
                                    </div>
                                    <small v-if="wgsCoords.pt1" class="text-muted d-block mt-1">
                                        經緯度：{{ wgsCoords.pt1.lat.toFixed(6) }}, {{ wgsCoords.pt1.lon.toFixed(6) }}
                                    </small>
                                </div>

                                <!-- 坐標 2 (選填) -->
                                <div class="coord-card" :class="{ 'active-coord': activeCoordIndex === 2 }">
                                    <div class="coord-header">
                                        <span class="coord-title text-warning">
                                            <i class="fas fa-map-marker-alt"></i> 通報坐標 2 (路段終點 / 影響範圍)
                                            <span class="badge badge-secondary">選填</span>
                                        </span>
                                        <div class="d-flex align-items-center">
                                            <button v-if="mode !== 'read'" type="button" class="btn btn-sm btn-outline-warning py-0 px-2 mr-1"
                                                    v-on:click="getCurrentGps(2)">
                                                <i class="fas fa-crosshairs"></i> GPS定位
                                            </button>
                                            <button v-if="mode !== 'read'" type="button" class="btn btn-sm py-0 px-2 mr-1"
                                                    :class="activeCoordIndex === 2 ? 'btn-warning text-dark font-weight-bold' : 'btn-outline-secondary'"
                                                    v-on:click="activeCoordIndex = 2">
                                                {{ activeCoordIndex === 2 ? '點圖拾取中' : '地圖拾取' }}
                                            </button>
                                            <button v-if="mode !== 'read' && (formData.S_UTME1 || formData.S_UTMN1)" type="button" 
                                                    class="btn btn-sm btn-outline-danger py-0 px-1" v-on:click="clearCoord2" title="清除坐標2">
                                                <i class="fas fa-times"></i>
                                            </button>
                                        </div>
                                    </div>
                                    <div class="row no-gutters">
                                        <div class="col-6 pr-1">
                                            <div class="input-group input-group-sm">
                                                <div class="input-group-prepend"><span class="input-group-text font-weight-bold">X (E)</span></div>
                                                <input type="number" class="form-control font-weight-bold" v-model.number="formData.S_UTME1" 
                                                       v-on:change="onManualCoordChange(2)" :readonly="mode === 'read'" placeholder="例如 298234" />
                                            </div>
                                        </div>
                                        <div class="col-6 pl-1">
                                            <div class="input-group input-group-sm">
                                                <div class="input-group-prepend"><span class="input-group-text font-weight-bold">Y (N)</span></div>
                                                <input type="number" class="form-control font-weight-bold" v-model.number="formData.S_UTMN1" 
                                                       v-on:change="onManualCoordChange(2)" :readonly="mode === 'read'" placeholder="例如 2767567" />
                                            </div>
                                        </div>
                                    </div>
                                    <small v-if="wgsCoords.pt2" class="text-muted d-block mt-1">
                                        經緯度：{{ wgsCoords.pt2.lat.toFixed(6) }}, {{ wgsCoords.pt2.lon.toFixed(6) }}
                                    </small>
                                </div>
                            </div>
                        </div>

                        <!-- 桌面端動作按鈕 -->
                        <div class="d-none d-xl-block mb-4">
                            <div class="card-modern p-3">
                                <button v-if="mode !== 'read'" type="button" class="btn btn-warning btn-block font-weight-bold py-2 mb-2"
                                        v-on:click="submitRecord" :disabled="isSubmitting">
                                    <i class="fas fa-check-circle mr-1"></i> {{ isSubmitting ? '正在寫入資料庫...' : '確定送出通報單' }}
                                </button>
                                <button type="button" class="btn btn-outline-secondary btn-block font-weight-bold" v-on:click="goBack">
                                    <i class="fas fa-undo mr-1"></i> 取消並返回
                                </button>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- 右欄：通報補充說明、照片上傳清單 (60% 寬度) -->
                <div class="col-12 col-xl-7">
                    <!-- 通報補充說明卡片 -->
                    <div class="card-modern">
                        <div class="card-modern-header">
                            <h2 class="card-modern-title">
                                <i class="fas fa-comment-dots text-primary"></i>
                                <span>通報補充說明與路況描述</span>
                            </h2>
                            <small class="text-muted">外勤備註</small>
                        </div>
                        <div class="card-modern-body">
                            <textarea class="form-control" rows="3" v-model="formData.Comm" :readonly="mode === 'read'"
                                      placeholder="請輸入詳細污染情形、路段特徵、可能污染源車輛或工區名稱..."></textarea>
                            
                            <!-- 常用快捷短語 (點擊帶入) -->
                            <div v-if="mode !== 'read'">
                                <div class="quick-phrase-group">
                                    <span class="text-muted small align-self-center mr-1">常用快捷短語：</span>
                                    <button v-for="phrase in quickPhrases" :key="phrase" type="button" class="quick-phrase-chip"
                                            v-on:click="appendQuickPhrase(phrase)">
                                        + {{ phrase }}
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- 疑似髒污點現場照片卡片 -->
                    <div class="card-modern">
                        <div class="card-modern-header">
                            <h2 class="card-modern-title">
                                <i class="fas fa-camera text-danger"></i>
                                <span>疑似髒污點現場照片</span>
                                <span class="badge badge-pill badge-danger ml-2">{{ photos1.length }} 張</span>
                            </h2>
                            <span class="badge badge-light text-muted">最多支援 6 張現場照片</span>
                        </div>
                        <div class="card-modern-body">
                            <!-- 上傳拖放區 (唯讀模式隱藏) -->
                            <div v-if="mode !== 'read' && photos1.length < 6" class="upload-dropzone" 
                                 v-on:click="triggerFileInput('fileInput1')">
                                <i class="fas fa-cloud-upload-alt"></i>
                                <div class="title">點此拍照或選取照片上傳 (疑似髒污點)</div>
                                <div class="sub">外勤手機將自動進行無失真壓縮 (約 250KB) 加速上傳</div>
                                <input type="file" id="fileInput1" ref="fileInput1" accept="image/*" capture="environment" 
                                       style="display: none;" v-on:change="handleFileSelect($event, 1)" multiple />
                            </div>

                            <!-- 照片網格清單 -->
                            <div v-if="photos1.length > 0" class="photo-grid">
                                <div v-for="(p, idx) in photos1" :key="idx" class="photo-card">
                                    <div class="photo-img-wrap" v-on:click="openLightbox(p.Url || p.Base64Data, '疑似髒污點照片 #' + (idx + 1))">
                                        <img :src="p.Url || p.Base64Data" alt="現場照片" />
                                        <span class="photo-badge-num">照片 {{ idx + 1 }}</span>
                                    </div>
                                    <div class="photo-meta">
                                        <span class="photo-name" :title="p.FileName">{{ p.FileName || ('新拍攝照片_' + (idx + 1)) }}</span>
                                        <button v-if="mode !== 'read'" type="button" class="photo-del-btn" 
                                                v-on:click="removePhoto(1, idx)" title="刪除此照片">
                                            <i class="fas fa-trash-alt"></i>
                                        </button>
                                    </div>
                                </div>
                            </div>
                            <div v-else class="text-center text-muted py-4">
                                <i class="fas fa-images fa-2x mb-2 text-secondary"></i>
                                <div>尚無上傳的疑似髒污點照片</div>
                            </div>
                        </div>
                    </div>

                    <!-- 佐證照片卡片 -->
                    <div class="card-modern">
                        <div class="card-modern-header">
                            <h2 class="card-modern-title">
                                <i class="fas fa-clipboard-check text-info"></i>
                                <span>佐證照片 (路標、周邊特徵或車牌)</span>
                                <span class="badge badge-pill badge-info ml-2">{{ photos2.length }} 張</span>
                            </h2>
                            <span class="badge badge-light text-muted">最多支援 6 張佐證照片</span>
                        </div>
                        <div class="card-modern-body">
                            <!-- 上傳拖放區 -->
                            <div v-if="mode !== 'read' && photos2.length < 6" class="upload-dropzone" 
                                 v-on:click="triggerFileInput('fileInput2')">
                                <i class="fas fa-camera text-info"></i>
                                <div class="title">點此拍照或選取佐證照片 (路牌/門牌/車輛)</div>
                                <div class="sub">支援智慧壓縮傳輸</div>
                                <input type="file" id="fileInput2" ref="fileInput2" accept="image/*" capture="environment" 
                                       style="display: none;" v-on:change="handleFileSelect($event, 2)" multiple />
                            </div>

                            <!-- 照片網格清單 -->
                            <div v-if="photos2.length > 0" class="photo-grid">
                                <div v-for="(p, idx) in photos2" :key="idx" class="photo-card">
                                    <div class="photo-img-wrap" v-on:click="openLightbox(p.Url || p.Base64Data, '佐證照片 #' + (idx + 1))">
                                        <img :src="p.Url || p.Base64Data" alt="佐證照片" />
                                        <span class="photo-badge-num">佐證 {{ idx + 1 }}</span>
                                    </div>
                                    <div class="photo-meta">
                                        <span class="photo-name" :title="p.FileName">{{ p.FileName || ('佐證照片_' + (idx + 1)) }}</span>
                                        <button v-if="mode !== 'read'" type="button" class="photo-del-btn" 
                                                v-on:click="removePhoto(2, idx)" title="刪除此照片">
                                            <i class="fas fa-trash-alt"></i>
                                        </button>
                                    </div>
                                </div>
                            </div>
                            <div v-else class="text-center text-muted py-4">
                                <i class="fas fa-image fa-2x mb-2 text-secondary"></i>
                                <div>尚無上傳的佐證照片</div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </main>

        <!-- 手機專屬常駐底部浮動列 (Mobile Sticky Bottom Bar) -->
        <div class="mobile-bottom-bar d-xl-none">
            <button type="button" class="btn btn-outline-secondary font-weight-bold" v-on:click="goBack">
                <i class="fas fa-arrow-left"></i> 返回
            </button>
            <button v-if="mode !== 'read'" type="button" class="btn btn-warning font-weight-bold shadow-sm" 
                    v-on:click="submitRecord" :disabled="isSubmitting">
                <i class="fas fa-check-circle"></i> {{ isSubmitting ? '送出中...' : '確定送出' }}
            </button>
        </div>

        <!-- 燈箱瀏覽 Modal (Lightbox) -->
        <div v-if="activeLightboxUrl" class="lightbox-overlay" v-on:click.self="activeLightboxUrl = null">
            <button type="button" class="lightbox-close-btn" v-on:click="activeLightboxUrl = null">&times;</button>
            <div class="lightbox-content">
                <img :src="activeLightboxUrl" class="lightbox-img" alt="放大預覽" />
                <div class="text-white font-weight-bold mt-2" style="font-size: 14px;">{{ activeLightboxTitle }}</div>
            </div>
        </div>
    </div>

    <!-- 本地核心腳本依賴 -->
    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>
    <script src="../Scripts/leaflet/leaflet.js"></script>

    <script>
        const { createApp } = Vue;

        createApp({
            data() {
                return {
                    mode: 'new',           // 'new', 'edit', 'read'
                    isSubmitting: false,
                    alertMessage: '',
                    alertType: 'success',
                    isMapCollapsed: false,
                    activeCoordIndex: 1,   // 目前地圖點擊要更新的坐標點 (1 或 2)
                    activeLightboxUrl: null,
                    activeLightboxTitle: '',

                    // 表單主體資料
                    formData: {
                        DirtyId: '自動編號',
                        ShowId: '送出後自動產生',
                        ReportDate: '',
                        ReportUser: '',
                        ReportUserName: '',
                        Kind: 'EF',
                        S_UTME: 0,
                        S_UTMN: 0,
                        S_UTME1: 0,
                        S_UTMN1: 0,
                        Comm: ''
                    },

                    // 轉換後的 WGS84 經緯度
                    wgsCoords: {
                        pt1: null,
                        pt2: null
                    },

                    // 照片清單
                    photos1: [], // 疑似髒污點現場照片
                    photos2: [], // 佐證照片

                    // 常用快捷短語
                    quickPhrases: [
                        '路面大面積泥沙積淤',
                        '營建工區周邊車輛帶泥污染',
                        '砂石車沿路散落砂石',
                        '車輛出入口未妥善清洗輪胎',
                        '側溝格柵周邊泥砂積塞'
                    ]
                };
            },
            computed: {
                modeText() {
                    if (this.mode === 'new') return '新增道路髒污通報';
                    if (this.mode === 'edit') return '編輯通報案件';
                    return '通報案件檢視';
                },
                modeBadgeIcon() {
                    if (this.mode === 'new') return 'fa-plus-circle text-success';
                    if (this.mode === 'edit') return 'fa-edit text-warning';
                    return 'fa-eye text-info';
                }
            },
            mounted() {
                this.initPage();
            },
            methods: {
                // 1. 初始化頁面
                initPage() {
                    const urlParams = new URLSearchParams(window.location.search);
                    const qMode = urlParams.get('mode');
                    const qId = urlParams.get('id');

                    if (qMode) {
                        this.mode = qMode.toLowerCase();
                    }

                    // 初始化 Leaflet 地圖 (注意：不將 Leaflet 實例放進 Vue data()，避免 reactive 代理破壞)
                    this.initLeafletMap();

                    // 向後端請求初始化資料
                    const apiUrl = 'NewDirty.aspx?action=init&mode=' + encodeURIComponent(this.mode) + 
                                   (qId ? '&id=' + encodeURIComponent(qId) : '');
                    
                    axios.get(apiUrl).then(res => {
                        if (res.data && res.data.Success) {
                            const d = res.data.Data;
                            this.formData.DirtyId = d.DirtyId || '自動編號';
                            this.formData.ShowId = d.ShowId || '送出後自動產生';
                            this.formData.ReportDate = d.ReportDate || '';
                            this.formData.ReportUser = d.ReportUser || d.CurrentUserId;
                            this.formData.ReportUserName = d.ReportUserName || d.CurrentUserName;
                            this.formData.Kind = d.Kind || 'EF';
                            this.formData.S_UTME = d.S_UTME || 0;
                            this.formData.S_UTMN = d.S_UTMN || 0;
                            this.formData.S_UTME1 = d.S_UTME1 || 0;
                            this.formData.S_UTMN1 = d.S_UTMN1 || 0;
                            this.formData.Comm = d.Comm || '';

                            // 照片資料
                            this.photos1 = (d.Photos1 || []).map(p => ({ ...p, IsDeleted: false }));
                            this.photos2 = (d.Photos2 || []).map(p => ({ ...p, IsDeleted: false }));

                            if (d.Lat && d.Lon && d.Lat > 0 && d.Lon > 0) {
                                this.wgsCoords.pt1 = { lat: d.Lat, lon: d.Lon };
                            }
                            if (d.Lat1 && d.Lon1 && d.Lat1 > 0 && d.Lon1 > 0) {
                                this.wgsCoords.pt2 = { lat: d.Lat1, lon: d.Lon1 };
                            }

                            // 若已有坐標，則轉換並在地圖上繪製標記
                            this.syncMapWithCoords();
                        } else {
                            this.showAlert(res.data ? res.data.Message : '載入資料失敗', 'danger');
                        }
                    }).catch(err => {
                        this.showAlert('無法連線後端服務：' + err.message, 'danger');
                    });
                },

                // 2. 初始化 Leaflet 本地化地圖
                initLeafletMap() {
                    const mapEl = document.getElementById('map');
                    if (!mapEl) return;

                    // 預設中心為新北市政府 (經緯度: 25.0118, 121.4658)
                    this.leafletMap = L.map('map', {
                        center: [25.0118, 121.4658],
                        zoom: 13,
                        attributionControl: false
                    });

                    // 使用開放台灣電子地圖 (WMTS) 或標準 OSM 圖磚
                    L.tileLayer('https://wmts.nlsc.gov.tw/wmts/EMAP/default/GoogleMapsCompatible/{z}/{y}/{x}', {
                        maxZoom: 19,
                        minZoom: 8,
                        errorTileUrl: ''
                    }).addTo(this.leafletMap);

                    // 比例尺
                    L.control.scale({ imperial: false }).addTo(this.leafletMap);

                    // 地圖點擊事件：依 activeCoordIndex 更新坐標 1 或坐標 2
                    this.leafletMap.on('click', e => {
                        if (this.mode === 'read') return;
                        const lat = e.latlng.lat;
                        const lon = e.latlng.lng;
                        const twd = this.wgs84ToTwd97(lat, lon);

                        if (this.activeCoordIndex === 1) {
                            this.formData.S_UTME = Math.round(twd.x);
                            this.formData.S_UTMN = Math.round(twd.y);
                            this.wgsCoords.pt1 = { lat, lon };
                            this.updateMarker(1, lat, lon);
                            // 若坐標 2 還沒設定，自動提示切換至坐標 2
                            if (!this.formData.S_UTME1 || this.formData.S_UTME1 <= 0) {
                                this.activeCoordIndex = 2;
                            }
                        } else {
                            this.formData.S_UTME1 = Math.round(twd.x);
                            this.formData.S_UTMN1 = Math.round(twd.y);
                            this.wgsCoords.pt2 = { lat, lon };
                            this.updateMarker(2, lat, lon);
                        }
                        this.updateMapPolyline();
                    });
                },

                // 3. 坐標與地圖圖層標記同步
                syncMapWithCoords() {
                    if (!this.leafletMap) return;

                    const bounds = [];

                    // 處理坐標 1
                    if (this.formData.S_UTME > 100000 && this.formData.S_UTMN > 100000) {
                        const pt1 = this.twd97ToWgs84(this.formData.S_UTME, this.formData.S_UTMN);
                        this.wgsCoords.pt1 = pt1;
                        this.updateMarker(1, pt1.lat, pt1.lon);
                        bounds.push([pt1.lat, pt1.lon]);
                    }

                    // 處理坐標 2
                    if (this.formData.S_UTME1 > 100000 && this.formData.S_UTMN1 > 100000) {
                        const pt2 = this.twd97ToWgs84(this.formData.S_UTME1, this.formData.S_UTMN1);
                        this.wgsCoords.pt2 = pt2;
                        this.updateMarker(2, pt2.lat, pt2.lon);
                        bounds.push([pt2.lat, pt2.lon]);
                    }

                    this.updateMapPolyline();

                    if (bounds.length === 1) {
                        this.leafletMap.setView(bounds[0], 16);
                    } else if (bounds.length >= 2) {
                        this.leafletMap.fitBounds(bounds, { padding: [40, 40] });
                    }
                },

                // 4. 更新 Marker 圖示
                updateMarker(index, lat, lon) {
                    if (!this.leafletMap) return;
                    if (!this.markers) this.markers = {};

                    if (this.markers[index]) {
                        this.markers[index].setLatLng([lat, lon]);
                    } else {
                        const isMain = (index === 1);
                        const markerHtml = '<div class="custom-map-marker">' +
                            '<div class="marker-pin-dirty ' + (isMain ? '' : 'pin-secondary') + '">' +
                            '<span class="marker-num">' + index + '</span>' +
                            '</div></div>';

                        const icon = L.divIcon({
                            className: '',
                            html: markerHtml,
                            iconSize: [32, 32],
                            iconAnchor: [16, 32]
                        });

                        const marker = L.marker([lat, lon], {
                            icon: icon,
                            draggable: (this.mode !== 'read')
                        }).addTo(this.leafletMap);

                        marker.bindPopup('<b>通報坐標 ' + index + '</b><br/>TWD97: ' + 
                            (index === 1 ? this.formData.S_UTME : this.formData.S_UTME1) + ', ' +
                            (index === 1 ? this.formData.S_UTMN : this.formData.S_UTMN1));

                        // 拖曳結束更新座標
                        marker.on('dragend', e => {
                            const pos = e.target.getLatLng();
                            const twd = this.wgs84ToTwd97(pos.lat, pos.lng);
                            if (index === 1) {
                                this.formData.S_UTME = Math.round(twd.x);
                                this.formData.S_UTMN = Math.round(twd.y);
                                this.wgsCoords.pt1 = { lat: pos.lat, lon: pos.lng };
                            } else {
                                this.formData.S_UTME1 = Math.round(twd.x);
                                this.formData.S_UTMN1 = Math.round(twd.y);
                                this.wgsCoords.pt2 = { lat: pos.lat, lon: pos.lng };
                            }
                            this.updateMapPolyline();
                        });

                        this.markers[index] = marker;
                    }
                },

                // 5. 更新兩點間連線 (Polyline)
                updateMapPolyline() {
                    if (!this.leafletMap) return;
                    if (this.polylineLayer) {
                        this.leafletMap.removeLayer(this.polylineLayer);
                        this.polylineLayer = null;
                    }

                    if (this.wgsCoords.pt1 && this.wgsCoords.pt2 && this.formData.S_UTME1 > 0) {
                        this.polylineLayer = L.polyline([
                            [this.wgsCoords.pt1.lat, this.wgsCoords.pt1.lon],
                            [this.wgsCoords.pt2.lat, this.wgsCoords.pt2.lon]
                        ], {
                            color: '#ef4444',
                            dashArray: '6, 6',
                            weight: 3,
                            opacity: 0.8
                        }).addTo(this.leafletMap);
                    }
                },

                // 6. 清除坐標 2
                clearCoord2() {
                    this.formData.S_UTME1 = 0;
                    this.formData.S_UTMN1 = 0;
                    this.wgsCoords.pt2 = null;
                    if (this.markers && this.markers[2]) {
                        this.leafletMap.removeLayer(this.markers[2]);
                        delete this.markers[2];
                    }
                    if (this.polylineLayer) {
                        this.leafletMap.removeLayer(this.polylineLayer);
                        this.polylineLayer = null;
                    }
                    this.activeCoordIndex = 2;
                },

                // 7. 手動修改輸入框坐標時同步地圖
                onManualCoordChange(index) {
                    const e = (index === 1) ? this.formData.S_UTME : this.formData.S_UTME1;
                    const n = (index === 1) ? this.formData.S_UTMN : this.formData.S_UTMN1;

                    if (e > 100000 && n > 100000) {
                        const pt = this.twd97ToWgs84(e, n);
                        if (index === 1) {
                            this.wgsCoords.pt1 = pt;
                        } else {
                            this.wgsCoords.pt2 = pt;
                        }
                        this.updateMarker(index, pt.lat, pt.lon);
                        this.updateMapPolyline();
                        this.leafletMap.panTo([pt.lat, pt.lon]);
                    }
                },

                // 8. 取得手機目前 GPS 位置
                getCurrentGps(targetIndex) {
                    if (!('geolocation' in navigator)) {
                        this.showAlert('此裝置或瀏覽器不支援 GPS 定位服務', 'danger');
                        return;
                    }

                    this.showAlert('正在向衛星取得目前 GPS 定位中，請稍候...', 'info');

                    navigator.geolocation.getCurrentPosition(pos => {
                        const lat = pos.coords.latitude;
                        const lon = pos.coords.longitude;
                        const twd = this.wgs84ToTwd97(lat, lon);

                        if (targetIndex === 1) {
                            this.formData.S_UTME = Math.round(twd.x);
                            this.formData.S_UTMN = Math.round(twd.y);
                            this.wgsCoords.pt1 = { lat, lon };
                            this.updateMarker(1, lat, lon);
                        } else {
                            this.formData.S_UTME1 = Math.round(twd.x);
                            this.formData.S_UTMN1 = Math.round(twd.y);
                            this.wgsCoords.pt2 = { lat, lon };
                            this.updateMarker(2, lat, lon);
                        }

                        this.updateMapPolyline();
                        this.leafletMap.setView([lat, lon], 17);
                        this.showAlert('GPS 定位成功！已更新至通報坐標 ' + targetIndex, 'success');
                    }, err => {
                        let errMsg = '無法取得定位資訊';
                        if (err.code === 1) errMsg = '定位授權遭拒，請至瀏覽器設定允許使用 GPS 位置';
                        else if (err.code === 2) errMsg = '無法取得衛星訊號，請至開闊處重試';
                        else if (err.code === 3) errMsg = '定位逾時，請再試一次';
                        this.showAlert(errMsg, 'danger');
                    }, {
                        enableHighAccuracy: true,
                        timeout: 10000,
                        maximumAge: 0
                    });
                },

                // 9. 地圖收合控制與全景重設
                toggleMapCollapse() {
                    this.isMapCollapsed = !this.isMapCollapsed;
                    setTimeout(() => {
                        if (this.leafletMap) this.leafletMap.invalidateSize();
                    }, 350);
                },
                resetMapView() {
                    if (!this.leafletMap) return;
                    if (this.wgsCoords.pt1) {
                        this.leafletMap.setView([this.wgsCoords.pt1.lat, this.wgsCoords.pt1.lon], 16);
                    } else {
                        this.leafletMap.setView([25.0118, 121.4658], 13);
                    }
                },

                // 10. 照片選擇、縮圖壓縮與加入清單
                triggerFileInput(refName) {
                    const input = this.$refs[refName];
                    if (input) input.click();
                },
                handleFileSelect(event, type) {
                    const files = event.target.files;
                    if (!files || files.length === 0) return;

                    const targetList = (type === 1) ? this.photos1 : this.photos2;
                    const maxAllowed = 6 - targetList.length;

                    if (files.length > maxAllowed) {
                        this.showAlert('最多僅能再上傳 ' + maxAllowed + ' 張照片', 'warning');
                    }

                    const numToProcess = Math.min(files.length, maxAllowed);
                    for (let i = 0; i < numToProcess; i++) {
                        this.compressAndAddPhoto(files[i], type);
                    }

                    // 重設 input 避免連續選同一張無反應
                    event.target.value = '';
                },
                compressAndAddPhoto(file, type) {
                    const reader = new FileReader();
                    reader.onload = e => {
                        const img = new Image();
                        img.onload = () => {
                            const canvas = document.createElement('canvas');
                            const maxDimension = 1600; // 最長邊壓縮至 1600px
                            let width = img.width;
                            let height = img.height;

                            if (width > height && width > maxDimension) {
                                height = Math.round((height * maxDimension) / width);
                                width = maxDimension;
                            } else if (height > maxDimension) {
                                width = Math.round((width * maxDimension) / height);
                                height = maxDimension;
                            }

                            canvas.width = width;
                            canvas.height = height;
                            const ctx = canvas.getContext('2d');
                            ctx.drawImage(img, 0, 0, width, height);

                            // 導出高品質 JPEG Base64
                            const compressedBase64 = canvas.toDataURL('image/jpeg', 0.85);

                            const photoObj = {
                                FileName: file.name,
                                Base64Data: compressedBase64,
                                IsDeleted: false
                            };

                            if (type === 1) {
                                this.photos1.push(photoObj);
                            } else {
                                this.photos2.push(photoObj);
                            }
                        };
                        img.src = e.target.result;
                    };
                    reader.readAsDataURL(file);
                },
                removePhoto(type, index) {
                    if (!confirm('確定要刪除這張照片嗎？')) return;
                    if (type === 1) {
                        this.photos1[index].IsDeleted = true;
                        this.photos1.splice(index, 1);
                    } else {
                        this.photos2[index].IsDeleted = true;
                        this.photos2.splice(index, 1);
                    }
                },

                // 11. 快捷短語追加
                appendQuickPhrase(phrase) {
                    if (!this.formData.Comm) {
                        this.formData.Comm = phrase;
                    } else {
                        this.formData.Comm += '，' + phrase;
                    }
                },

                // 12. 確定送出儲存通報單
                submitRecord() {
                    if (this.isSubmitting) return;

                    // 表單驗證
                    if (!this.formData.S_UTME || !this.formData.S_UTMN || 
                        this.formData.S_UTME <= 100000 || this.formData.S_UTMN <= 100000) {
                        this.showAlert('請標記或填寫正確的通報坐標 1 (TWD97 坐標數值需大於 100000)', 'danger');
                        return;
                    }

                    this.isSubmitting = true;
                    this.showAlert('正在上傳照片並儲存通報單，請稍候...', 'info');

                    const payload = {
                        Mode: this.mode,
                        DirtyId: this.formData.DirtyId,
                        ReportDate: this.formData.ReportDate,
                        ReportUser: this.formData.ReportUser,
                        Kind: this.formData.Kind,
                        S_UTME: this.formData.S_UTME,
                        S_UTMN: this.formData.S_UTMN,
                        S_UTME1: this.formData.S_UTME1 || null,
                        S_UTMN1: this.formData.S_UTMN1 || null,
                        Lat: this.wgsCoords.pt1 ? this.wgsCoords.pt1.lat : null,
                        Lon: this.wgsCoords.pt1 ? this.wgsCoords.pt1.lon : null,
                        Lat1: this.wgsCoords.pt2 ? this.wgsCoords.pt2.lat : null,
                        Lon1: this.wgsCoords.pt2 ? this.wgsCoords.pt2.lon : null,
                        Comm: this.formData.Comm,
                        Photos1: this.photos1,
                        Photos2: this.photos2
                    };

                    axios.post('NewDirty.aspx?action=save', payload).then(res => {
                        this.isSubmitting = false;
                        if (res.data && res.data.Success) {
                            alert(res.data.Message + '\n通報案號：' + res.data.DirtyId);
                            // 跳轉至查核紀錄暫存列表
                            window.location.href = 'Dirty_List.aspx?mode=DirtyEdit';
                        } else {
                            this.showAlert(res.data ? res.data.Message : '儲存失敗', 'danger');
                        }
                    }).catch(err => {
                        this.isSubmitting = false;
                        this.showAlert('送出通報單時發生錯誤：' + err.message, 'danger');
                    });
                },

                // 13. 返回上一頁
                goBack() {
                    if (document.referrer && document.referrer.indexOf('Dirty') >= 0) {
                        window.history.back();
                    } else {
                        window.location.href = 'Dirty_List.aspx?mode=DirtyEdit';
                    }
                },

                // 14. 燈箱瀏覽
                openLightbox(url, title) {
                    this.activeLightboxUrl = url;
                    this.activeLightboxTitle = title || '';
                },

                // 15. Alert 提示
                showAlert(msg, type) {
                    this.alertMessage = msg;
                    this.alertType = type || 'info';
                    setTimeout(() => {
                        if (this.alertMessage === msg) {
                            this.alertMessage = '';
                        }
                    }, 4500);
                },

                // 16. 格式化工具
                formatDisplayTime(isoStr) {
                    if (!isoStr) return '--';
                    return isoStr.replace('T', ' ');
                },
                getKindName(kind) {
                    if (kind === 'EB') return '營建工程道路污染 (EB)';
                    if (kind === 'EF') return '固定逸散道路污染 (EF)';
                    if (kind === 'ES') return '道路砂石堆積污染 (ES)';
                    return '其他道路髒污通報';
                },

                // 17. 座標轉換演算法 (TWD97 <-> WGS84)
                twd97ToWgs84(x, y) {
                    const a = 6378137.0;
                    const b = 6356752.314245;
                    const lon0 = 121.0 * Math.PI / 180.0;
                    const k0 = 0.9999;
                    const dx = 250000.0;

                    const e = Math.sqrt(1.0 - (b * b) / (a * a));
                    const e2 = (e * e) / (1.0 - e * e);
                    x -= dx;

                    const M = y / k0;
                    const mu = M / (a * (1.0 - Math.pow(e, 2) / 4.0 - 3.0 * Math.pow(e, 4) / 64.0 - 5.0 * Math.pow(e, 6) / 256.0));
                    const e1 = (1.0 - Math.sqrt(1.0 - Math.pow(e, 2))) / (1.0 + Math.sqrt(1.0 - Math.pow(e, 2)));

                    const J1 = (3.0 * e1 / 2.0 - 27.0 * Math.pow(e1, 3) / 32.0);
                    const J2 = (21.0 * Math.pow(e1, 2) / 16.0 - 55.0 * Math.pow(e1, 4) / 32.0);
                    const J3 = (151.0 * Math.pow(e1, 3) / 96.0);
                    const J4 = (1097.0 * Math.pow(e1, 4) / 512.0);

                    const fp = mu + J1 * Math.sin(2.0 * mu) + J2 * Math.sin(4.0 * mu) + J3 * Math.sin(6.0 * mu) + J4 * Math.sin(8.0 * mu);

                    const C1 = e2 * Math.pow(Math.cos(fp), 2);
                    const T1 = Math.pow(Math.tan(fp), 2);
                    const R1 = a * (1.0 - Math.pow(e, 2)) / Math.pow(1.0 - Math.pow(e, 2) * Math.pow(Math.sin(fp), 2), 1.5);
                    const N1 = a / Math.sqrt(1.0 - Math.pow(e, 2) * Math.pow(Math.sin(fp), 2));
                    const D = x / (N1 * k0);

                    const latRad = fp - (N1 * Math.tan(fp) / R1) * (Math.pow(D, 2) / 2.0 - (5.0 + 3.0 * T1 + 10.0 * C1 - 4.0 * Math.pow(C1, 2) - 9.0 * e2) * Math.pow(D, 4) / 24.0 + (61.0 + 90.0 * T1 + 298.0 * C1 + 45.0 * Math.pow(T1, 2) - 252.0 * e2 - 3.0 * Math.pow(C1, 2)) * Math.pow(D, 6) / 720.0);
                    const lonRad = lon0 + (D - (1.0 + 2.0 * T1 + C1) * Math.pow(D, 3) / 6.0 + (5.0 - 2.0 * C1 + 28.0 * T1 - 3.0 * Math.pow(C1, 2) + 8.0 * e2 + 24.0 * Math.pow(T1, 2)) * Math.pow(D, 5) / 120.0) / Math.cos(fp);

                    return {
                        lat: latRad * 180.0 / Math.PI,
                        lon: lonRad * 180.0 / Math.PI
                    };
                },
                wgs84ToTwd97(lat, lon) {
                    const a = 6378137.0;
                    const b = 6356752.314245;
                    const lon0 = 121.0 * Math.PI / 180.0;
                    const k0 = 0.9999;
                    const dx = 250000.0;

                    const latRad = lat * Math.PI / 180.0;
                    const lonRad = lon * Math.PI / 180.0;

                    const e = Math.sqrt(1.0 - (b * b) / (a * a));
                    const e2 = (e * e) / (1.0 - e * e);

                    const T = Math.pow(Math.tan(latRad), 2);
                    const C = e2 * Math.pow(Math.cos(latRad), 2);
                    const A = (lonRad - lon0) * Math.cos(latRad);

                    const M = a * ((1.0 - Math.pow(e, 2) / 4.0 - 3.0 * Math.pow(e, 4) / 64.0 - 5.0 * Math.pow(e, 6) / 256.0) * latRad
                        - (3.0 * Math.pow(e, 2) / 8.0 + 3.0 * Math.pow(e, 4) / 32.0 + 45.0 * Math.pow(e, 6) / 1024.0) * Math.sin(2.0 * latRad)
                        + (15.0 * Math.pow(e, 4) / 256.0 + 45.0 * Math.pow(e, 6) / 1024.0) * Math.sin(4.0 * latRad)
                        - (35.0 * Math.pow(e, 6) / 3072.0) * Math.sin(6.0 * latRad));

                    const N = a / Math.sqrt(1.0 - Math.pow(e, 2) * Math.pow(Math.sin(latRad), 2));

                    const x = dx + k0 * N * (A + (1.0 - T + C) * Math.pow(A, 3) / 6.0 + (5.0 - 18.0 * T + Math.pow(T, 2) + 72.0 * C - 58.0 * e2) * Math.pow(A, 5) / 120.0);
                    const y = k0 * (M + N * Math.tan(latRad) * (Math.pow(A, 2) / 2.0 + (5.0 - T + 9.0 * C + 4.0 * Math.pow(C, 2)) * Math.pow(A, 4) / 24.0 + (61.0 - 58.0 * T + Math.pow(T, 2) + 600.0 * C - 330.0 * e2) * Math.pow(A, 6) / 720.0));

                    return { x, y };
                }
            }
        }).mount('#dirtyApp');
    </script>
</body>
</html>
