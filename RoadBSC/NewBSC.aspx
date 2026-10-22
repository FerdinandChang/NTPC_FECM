<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="NewBSC.aspx.cs" Inherits="NTPC_FEC.RoadBSC.NewBSC" %>

<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定溢散源管理平台 - 人行道與交通島裸露覆土現場通報</title>

    <!-- 專屬 Favicon -->
    <link rel="shortcut icon" href="../favicon.ico" type="image/x-icon" />

    <!-- 本地化核心樣式庫 -->
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
            font-size: 1.15rem;
            font-weight: 700;
            letter-spacing: 0.5px;
            margin: 0;
            display: flex;
            align-items: center;
            gap: 10px;
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

        .mode-badge {
            font-size: 0.75rem;
            font-weight: 700;
            padding: 3px 8px;
            border-radius: 6px;
            text-transform: uppercase;
        }
        .mode-badge.badge-new { background-color: #10b981; color: #ffffff; }
        .mode-badge.badge-edit { background-color: #f59e0b; color: #ffffff; }

        /* 主容器佈局 */
        .main-container {
            max-width: 1480px;
            margin: 0 auto;
            padding: 16px;
        }

        /* 現代卡片 */
        .card-modern {
            background: var(--surface);
            border-radius: 12px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04), 0 4px 12px rgba(15, 23, 42, 0.05);
            margin-bottom: 16px;
            border: 1px solid var(--border-color);
            overflow: hidden;
            transition: box-shadow 0.2s ease;
        }

        .card-modern:hover {
            box-shadow: 0 2px 6px rgba(0, 0, 0, 0.06), 0 8px 20px rgba(15, 23, 42, 0.08);
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
            padding: 18px;
        }

        /* 桌面端左欄 Sticky 固頂 */
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
            height: 380px;
            border-radius: 8px;
            z-index: 10;
            transition: height 0.3s ease;
        }

        #map.map-collapsed {
            height: 120px !important;
        }

        /* 座標晶片列 */
        .coord-chip-row {
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
            background: #f8fafc;
            border: 1px solid var(--border-color);
            border-radius: 8px;
            padding: 10px 14px;
            margin-top: 12px;
        }

        .coord-chip-item {
            flex: 1;
            min-width: 140px;
        }

        .coord-label {
            font-size: 0.75rem;
            font-weight: 700;
            color: var(--text-muted);
            text-transform: uppercase;
            margin-bottom: 2px;
        }

        .coord-value {
            font-size: 0.95rem;
            font-weight: 700;
            color: var(--brand-navy);
            font-family: monospace, sans-serif;
        }

        /* 表單輸入項 */
        .form-label-custom {
            font-size: 0.9rem;
            font-weight: 700;
            color: var(--brand-navy);
            margin-bottom: 6px;
            display: flex;
            align-items: center;
            gap: 6px;
        }

        .form-label-custom .badge-req {
            font-size: 0.7rem;
            background: #fee2e2;
            color: #ef4444;
            padding: 2px 6px;
            border-radius: 4px;
            font-weight: 600;
        }

        .form-control-custom {
            border: 1px solid #cbd5e1;
            border-radius: 8px;
            padding: 10px 14px;
            font-size: 0.95rem;
            transition: border-color 0.15s, box-shadow 0.15s;
            width: 100%;
        }

        .form-control-custom:focus {
            outline: none;
            border-color: var(--brand-blue);
            box-shadow: 0 0 0 3px rgba(2, 132, 199, 0.15);
        }

        /* 晶片組按鈕 (Segmented Chips) */
        .chips-group {
            display: flex;
            flex-wrap: wrap;
            gap: 8px;
        }

        .chip-btn {
            border: 1px solid #cbd5e1;
            background: #ffffff;
            color: #334155;
            padding: 8px 16px;
            border-radius: 8px;
            font-size: 0.9rem;
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
            background: #f8fafc;
            border-color: #94a3b8;
        }

        .chip-btn.active-primary {
            background: #f0f9ff;
            border-color: var(--brand-blue);
            color: #0369a1;
            font-weight: 700;
            box-shadow: 0 0 0 2px rgba(2, 132, 199, 0.2);
        }

        .chip-btn.active-success {
            background: #ecfdf5;
            border-color: #10b981;
            color: #047857;
            font-weight: 700;
            box-shadow: 0 0 0 2px rgba(16, 185, 129, 0.2);
        }

        .chip-btn.active-warning {
            background: #fffbeb;
            border-color: #f59e0b;
            color: #b45309;
            font-weight: 700;
            box-shadow: 0 0 0 2px rgba(245, 158, 11, 0.2);
        }

        .chip-btn.active-danger {
            background: #fef2f2;
            border-color: #ef4444;
            color: #b91c1c;
            font-weight: 700;
            box-shadow: 0 0 0 2px rgba(239, 68, 68, 0.2);
        }

        /* 照片上傳與展示網格 */
        .photo-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
            gap: 14px;
            margin-top: 10px;
        }

        .photo-card {
            border: 1px solid var(--border-color);
            border-radius: 10px;
            overflow: hidden;
            background: #ffffff;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
            display: flex;
            flex-direction: column;
            position: relative;
        }

        .photo-preview-box {
            width: 100%;
            height: 140px;
            background: #f8fafc;
            display: flex;
            align-items: center;
            justify-content: center;
            overflow: hidden;
            position: relative;
            cursor: pointer;
        }

        .photo-preview-box img {
            width: 100%;
            height: 100%;
            object-fit: cover;
            transition: transform 0.2s ease;
        }

        .photo-preview-box:hover img {
            transform: scale(1.05);
        }

        .photo-badge {
            position: absolute;
            top: 6px;
            left: 6px;
            background: rgba(15, 23, 42, 0.75);
            color: #ffffff;
            font-size: 0.75rem;
            font-weight: 700;
            padding: 2px 8px;
            border-radius: 4px;
        }

        .photo-footer {
            padding: 8px 10px;
            background: #ffffff;
            display: flex;
            align-items: center;
            justify-content: space-between;
            border-top: 1px solid var(--border-color);
        }

        .photo-title {
            font-size: 0.8rem;
            font-weight: 600;
            color: #475569;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }

        .btn-del-photo {
            border: none;
            background: #fee2e2;
            color: #ef4444;
            border-radius: 6px;
            width: 30px;
            height: 30px;
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            transition: background 0.15s;
        }

        .btn-del-photo:hover {
            background: #fecaca;
        }

        /* 新增照片上傳按鈕方塊 */
        .photo-add-box {
            border: 2px dashed #cbd5e1;
            border-radius: 10px;
            min-height: 180px;
            background: #f8fafc;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            gap: 8px;
            cursor: pointer;
            transition: all 0.2s ease;
            color: #64748b;
            text-align: center;
            padding: 16px;
        }

        .photo-add-box:hover {
            border-color: var(--brand-blue);
            background: #f0f9ff;
            color: var(--brand-blue);
        }

        .photo-add-box i {
            font-size: 2rem;
        }

        /* 動作按鈕群 */
        .btn-action-primary {
            background: linear-gradient(135deg, #0099e5 0%, #0284c7 100%);
            color: #ffffff;
            border: none;
            font-weight: 700;
            border-radius: 8px;
            padding: 12px 28px;
            font-size: 1rem;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            box-shadow: 0 4px 12px rgba(2, 132, 199, 0.25);
            transition: all 0.2s ease;
        }

        .btn-action-primary:hover {
            transform: translateY(-1px);
            box-shadow: 0 6px 16px rgba(2, 132, 199, 0.35);
            color: #ffffff;
        }

        .btn-action-secondary {
            background: #ffffff;
            color: #475569;
            border: 1px solid #cbd5e1;
            font-weight: 600;
            border-radius: 8px;
            padding: 12px 20px;
            font-size: 1rem;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            transition: all 0.2s ease;
            text-decoration: none;
        }

        .btn-action-secondary:hover {
            background: #f8fafc;
            color: #0f172a;
            text-decoration: none;
        }

        /* 手機常駐底部動作列 (Sticky Bottom Bar) */
        .sticky-bottom-bar {
            position: fixed;
            bottom: 0;
            left: 0;
            right: 0;
            background: #ffffff;
            border-top: 1px solid var(--border-color);
            padding: 10px 16px;
            box-shadow: 0 -4px 12px rgba(0, 0, 0, 0.08);
            z-index: 1010;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 12px;
        }

        @media screen and (min-width: 768px) {
            .sticky-bottom-bar {
                display: none !important;
            }
        }

        /* 大圖燈箱預覽 Modal */
        .modal-lightbox {
            position: fixed;
            top: 0; left: 0; right: 0; bottom: 0;
            background: rgba(15, 23, 42, 0.85);
            z-index: 2000;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }

        .modal-lightbox-content {
            max-width: 90vw;
            max-height: 90vh;
            position: relative;
        }

        .modal-lightbox-content img {
            max-width: 100%;
            max-height: 85vh;
            border-radius: 8px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.5);
        }

        .btn-close-modal {
            position: absolute;
            top: -40px;
            right: 0;
            background: transparent;
            border: none;
            color: #ffffff;
            font-size: 1.8rem;
            cursor: pointer;
        }
    </style>
</head>
<body>
    <div id="bscApp" v-cloak>
        <!-- 頂部導覽列 -->
        <header class="top-navbar">
            <div class="brand-title">
                <i class="fas fa-seedling text-warning"></i>
                <span>人行道與交通島裸露覆土現場通報</span>
                <span class="mode-badge" :class="isEditMode ? 'badge-edit' : 'badge-new'">
                    {{ isEditMode ? '編輯案件' : '現場通報' }}
                </span>
            </div>
            <div class="d-flex align-items-center gap-2">
                <a href="BSC_List.aspx?mode=BSCEdit" class="nav-btn">
                    <i class="fas fa-list-ul"></i>
                    <span class="d-none d-sm-inline">通報清單</span>
                </a>
                <a href="../MainPage.aspx?sub=menu4" class="nav-btn">
                    <i class="fas fa-arrow-left"></i>
                    <span class="d-none d-sm-inline">回首頁</span>
                </a>
            </div>
        </header>

        <!-- 主體內容區塊 -->
        <main class="main-container">
            <div class="row">
                <!-- 左欄：基本通報資訊與現場地圖定位 (40% 寬度，Sticky 浮動固頂) -->
                <div class="col-12 col-xl-5">
                    <div class="sticky-sidebar">
                        <!-- 卡片 1：通報基本設定 -->
                        <div class="card-modern">
                            <div class="card-modern-header">
                                <h3 class="card-modern-title">
                                    <i class="fas fa-info-circle text-primary"></i>
                                    通報案件基本資料
                                </h3>
                                <span class="badge badge-light text-muted font-weight-normal">
                                    {{ isEditMode ? '案號：' + form.BSC_ID : '自動取號' }}
                                </span>
                            </div>
                            <div class="card-modern-body">
                                <div class="row">
                                    <div class="col-12 col-sm-6 mb-3">
                                        <label class="form-label-custom">
                                            <span>通報案號</span>
                                        </label>
                                        <input type="text" class="form-control-custom bg-light" :value="form.BSC_ID || '系統送出自動生成'" readonly />
                                    </div>
                                    <div class="col-12 col-sm-6 mb-3">
                                        <label class="form-label-custom">
                                            <span>查核日期時間</span>
                                        </label>
                                        <input type="text" class="form-control-custom bg-light" :value="form.Report_Date || '【依送出時間】'" readonly />
                                    </div>
                                    <div class="col-12 col-sm-6 mb-3">
                                        <label class="form-label-custom">
                                            <span>查核人員</span>
                                        </label>
                                        <input type="text" class="form-control-custom bg-light" :value="currentUser" readonly />
                                    </div>
                                    <div class="col-12 col-sm-6 mb-3">
                                        <label class="form-label-custom">
                                            <span>行政區</span>
                                            <span class="badge-req">必選</span>
                                        </label>
                                        <select class="form-control-custom" v-model="form.TOWN_CODE" v-on:change="onTownChange">
                                            <option value="">-- 請選擇行政區 --</option>
                                            <option v-for="t in towns" :key="t.TownNo" :value="t.TownNo">
                                                {{ t.TownName }}
                                            </option>
                                        </select>
                                    </div>
                                    <div class="col-12 mb-3">
                                        <label class="form-label-custom">
                                            <span>道路級別</span>
                                            <span class="badge-req">必選</span>
                                        </label>
                                        <div class="chips-group">
                                            <button type="button" 
                                                    v-for="lv in roadLvOptions" 
                                                    :key="lv"
                                                    class="chip-btn"
                                                    :class="{ 'active-primary': form.ROAD_LV === lv }"
                                                    v-on:click="form.ROAD_LV = lv">
                                                <i class="fas fa-road text-muted" v-if="form.ROAD_LV !== lv"></i>
                                                <i class="fas fa-check-circle text-primary" v-else></i>
                                                {{ lv }}
                                            </button>
                                        </div>
                                    </div>
                                    <div class="col-12 mb-2">
                                        <label class="form-label-custom">
                                            <span>道路名稱</span>
                                            <span class="badge-req">必填</span>
                                        </label>
                                        <input type="text" 
                                               class="form-control-custom" 
                                               v-model="form.ROAD_Name" 
                                               placeholder="例如：文化路一段、新北大道" />
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- 卡片 2：現場地圖與定位 (Leaflet) -->
                        <div class="card-modern">
                            <div class="card-modern-header">
                                <h3 class="card-modern-title">
                                    <i class="fas fa-map-marker-alt text-danger"></i>
                                    現場座標與定位
                                </h3>
                                <div class="d-flex align-items-center gap-1">
                                    <button type="button" class="btn btn-sm btn-outline-primary" v-on:click="locateGPS" title="取得目前 GPS 定位">
                                        <i class="fas fa-crosshairs mr-1"></i> GPS定位
                                    </button>
                                    <button type="button" class="btn btn-sm btn-outline-secondary" v-on:click="resetMapView" title="全景視角">
                                        <i class="fas fa-expand mr-1"></i> 全景
                                    </button>
                                    <button type="button" class="btn btn-sm btn-outline-secondary d-md-none" v-on:click="toggleMapCollapse">
                                        <i :class="isMapCollapsed ? 'fas fa-chevron-down' : 'fas fa-chevron-up'"></i>
                                        {{ isMapCollapsed ? '展開' : '收合' }}
                                    </button>
                                </div>
                            </div>
                            <div class="card-modern-body p-2">
                                <!-- 地圖本體 -->
                                <div id="map" :class="{ 'map-collapsed': isMapCollapsed }"></div>

                                <!-- 即時座標資訊晶片 -->
                                <div class="coord-chip-row">
                                    <div class="coord-chip-item">
                                        <div class="coord-label">TWD97 X (Easting)</div>
                                        <div class="coord-value text-primary">{{ form.S_UTME || '尚未定位' }}</div>
                                    </div>
                                    <div class="coord-chip-item">
                                        <div class="coord-label">TWD97 Y (Northing)</div>
                                        <div class="coord-value text-primary">{{ form.S_UTMN || '尚未定位' }}</div>
                                    </div>
                                    <div class="coord-chip-item">
                                        <div class="coord-label">WGS84 經度 (Lon)</div>
                                        <div class="coord-value">{{ currentLng ? Number(currentLng).toFixed(5) : '--' }}</div>
                                    </div>
                                    <div class="coord-chip-item">
                                        <div class="coord-label">WGS84 緯度 (Lat)</div>
                                        <div class="coord-value">{{ currentLat ? Number(currentLat).toFixed(5) : '--' }}</div>
                                    </div>
                                </div>
                                <small class="text-muted d-block mt-2 px-1">
                                    <i class="fas fa-info-circle text-info mr-1"></i>
                                    提示：可點擊地圖任意位置或拖曳圖標調整座標，亦可點擊「GPS定位」取得現場當前位置。
                                </small>
                            </div>
                        </div>

                        <!-- 桌面版動作送出面板 (桌面端常駐於左欄底端) -->
                        <div class="card-modern d-none d-md-block">
                            <div class="card-modern-body d-flex flex-column gap-2">
                                <button type="button" 
                                        class="btn-action-primary w-100 justify-content-center" 
                                        :disabled="isSubmitting"
                                        v-on:click="submitCase">
                                    <i class="fas fa-spinner fa-spin mr-1" v-if="isSubmitting"></i>
                                    <i class="fas fa-check-circle mr-1" v-else></i>
                                    {{ isSubmitting ? '正在儲存中...' : (isEditMode ? '儲存案件變更' : '確認送出通報單') }}
                                </button>
                                <a href="BSC_List.aspx?mode=BSCEdit" class="btn-action-secondary w-100 justify-content-center text-center">
                                    <i class="fas fa-times-circle mr-1"></i>
                                    放棄並取消
                                </a>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- 右欄：查核評估項目、補充說明與佐證照片 (60% 寬度) -->
                <div class="col-12 col-xl-7">
                    <!-- 卡片 3：人行道鋪面平整度 -->
                    <div class="card-modern">
                        <div class="card-modern-header">
                            <h3 class="card-modern-title">
                                <i class="fas fa-th-large text-info"></i>
                                人行道鋪面平整度評估
                            </h3>
                            <span class="badge-req">必填</span>
                        </div>
                        <div class="card-modern-body">
                            <div class="chips-group">
                                <button type="button" 
                                        v-for="s in smoothOptions" 
                                        :key="s.Code"
                                        class="chip-btn"
                                        :class="getSmoothChipClass(s.Code)"
                                        v-on:click="form.Smooth = s.Code">
                                    <i :class="getSmoothIcon(s.Code)"></i>
                                    {{ s.Val }}
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- 卡片 4：人行道或交通島覆土狀況 -->
                    <div class="card-modern">
                        <div class="card-modern-header">
                            <h3 class="card-modern-title">
                                <i class="fas fa-mountain text-warning"></i>
                                人行道或交通島覆土狀況評估
                            </h3>
                            <span class="badge-req">必填</span>
                        </div>
                        <div class="card-modern-body">
                            <div class="chips-group">
                                <button type="button" 
                                        v-for="c in coverSoilOptions" 
                                        :key="c.Code"
                                        class="chip-btn"
                                        :class="getCoverSoilChipClass(c.Code)"
                                        v-on:click="form.Cover_Soil = c.Code">
                                    <i :class="getCoverSoilIcon(c.Code)"></i>
                                    {{ c.Val }}
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- 卡片 5：其他補充說明 -->
                    <div class="card-modern">
                        <div class="card-modern-header">
                            <h3 class="card-modern-title">
                                <i class="fas fa-comment-alt text-primary"></i>
                                其他通報補充說明
                            </h3>
                            <span class="text-muted font-size-xs">選填</span>
                        </div>
                        <div class="card-modern-body">
                            <textarea class="form-control-custom" 
                                      rows="3" 
                                      v-model="form.Memo" 
                                      placeholder="請填寫現場特殊狀況、周邊地標、待改善建議或現場特徵說明..."></textarea>
                        </div>
                    </div>

                    <!-- 卡片 6：現場佐證照片 -->
                    <div class="card-modern">
                        <div class="card-modern-header">
                            <h3 class="card-modern-title">
                                <i class="fas fa-camera text-primary"></i>
                                現場佐證照片
                            </h3>
                            <span class="badge badge-info font-weight-normal">
                                {{ photos.length }} / 6 張
                            </span>
                        </div>
                        <div class="card-modern-body">
                            <!-- 照片展示網格 -->
                            <div class="photo-grid">
                                <!-- 已上傳或已拍照照片卡片 -->
                                <div class="photo-card" v-for="(p, index) in photos" :key="index">
                                    <div class="photo-preview-box" v-on:click="openLightbox(p.Url || p.Base64)">
                                        <img :src="p.Url || p.Base64" alt="佐證照片" />
                                        <span class="photo-badge">佐證照片 {{ index + 1 }}</span>
                                    </div>
                                    <div class="photo-footer">
                                        <span class="photo-title" :title="p.FileName || ('佐證照片_' + (index + 1))">
                                            {{ p.FileName || ('佐證照片_' + (index + 1)) }}
                                        </span>
                                        <button type="button" class="btn-del-photo" v-on:click="removePhoto(index)" title="刪除照片">
                                            <i class="fas fa-trash-alt"></i>
                                        </button>
                                    </div>
                                </div>

                                <!-- 新增照片觸發按鈕 (上限 6 張) -->
                                <div class="photo-add-box" v-if="photos.length < 6" v-on:click="triggerFileInput">
                                    <i class="fas fa-camera-retro"></i>
                                    <span class="font-weight-bold">拍照 / 上傳佐證照片</span>
                                    <small class="text-muted">支援手機現場拍照或選取照片 (已壓縮)</small>
                                </div>
                            </div>

                            <!-- 隱藏原生 File Input -->
                            <input type="file" 
                                   ref="fileInput" 
                                   accept="image/*" 
                                   multiple 
                                   class="d-none" 
                                   v-on:change="onFilesSelected" />

                            <small class="text-muted d-block mt-3">
                                <i class="fas fa-shield-alt text-success mr-1"></i>
                                系統自動進行外勤影像最佳化壓縮處理，單張照片最高上限 6 張。
                            </small>
                        </div>
                    </div>
                </div>
            </div>
        </main>

        <!-- 手機端常駐浮動動作列 (Sticky Bottom Bar) -->
        <div class="sticky-bottom-bar">
            <div>
                <small class="text-muted d-block">完成度評估</small>
                <span class="font-weight-bold" :class="isFormComplete ? 'text-success' : 'text-warning'">
                    <i :class="isFormComplete ? 'fas fa-check-circle' : 'fas fa-exclamation-circle'"></i>
                    {{ isFormComplete ? '資料已完備' : '尚有欄位未填' }}
                </span>
            </div>
            <div class="d-flex gap-2">
                <button type="button" 
                        class="btn-action-primary" 
                        :disabled="isSubmitting"
                        v-on:click="submitCase">
                    <i class="fas fa-spinner fa-spin mr-1" v-if="isSubmitting"></i>
                    <i class="fas fa-paper-plane mr-1" v-else></i>
                    {{ isSubmitting ? '儲存中...' : (isEditMode ? '儲存' : '確認送出') }}
                </button>
            </div>
        </div>

        <!-- 大圖燈箱 Modal -->
        <div class="modal-lightbox" v-if="lightboxImg" v-on:click="closeLightbox">
            <div class="modal-lightbox-content" v-on:click.stop>
                <button type="button" class="btn-close-modal" v-on:click="closeLightbox">
                    <i class="fas fa-times"></i>
                </button>
                <img :src="lightboxImg" alt="大圖檢視" />
            </div>
        </div>
    </div>

    <!-- 本地化核心腳本庫 -->
    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>
    <script src="../Scripts/leaflet/leaflet.js"></script>

    <script>
        const { createApp, ref, reactive, onMounted, computed, nextTick } = Vue;

        // 新北市各行政區標準地理中心經緯度 (WGS84)
        const TOWN_COORDS = {
            'F01': [25.0123, 121.4627], // 板橋
            'F02': [25.0628, 121.4981], // 三重
            'F03': [24.9996, 121.4988], // 中和
            'F04': [25.0080, 121.5173], // 永和
            'F05': [25.0359, 121.4444], // 新莊
            'F06': [24.9680, 121.5416], // 新店
            'F07': [24.9912, 121.4247], // 樹林
            'F08': [24.9547, 121.3547], // 鶯歌
            'F09': [24.9338, 121.3689], // 三峽
            'F10': [25.1755, 121.4428], // 淡水
            'F11': [25.0630, 121.6586], // 汐止
            'F12': [25.1086, 121.8062], // 瑞芳
            'F13': [24.9723, 121.4439], // 土城
            'F14': [25.0849, 121.4646], // 蘆洲
            'F15': [25.0827, 121.4385], // 五股
            'F16': [25.0537, 121.4326], // 泰山
            'F17': [25.0775, 121.3644], // 林口
            'F18': [25.0016, 121.6158], // 深坑
            'F19': [24.9897, 121.6587], // 石碇
            'F20': [24.9372, 121.7115], // 坪林
            'F21': [25.2573, 121.5008], // 三芝
            'F22': [25.2905, 121.5683], // 石門
            'F23': [25.1462, 121.3984], // 八里
            'F24': [25.0255, 121.7388], // 平溪
            'F25': [25.0336, 121.8656], // 雙溪
            'F26': [25.0175, 121.9427], // 貢寮
            'F27': [25.2223, 121.6377], // 金山
            'F28': [25.1788, 121.6888], // 萬里
            'F29': [24.8647, 121.5503]  // 烏來
        };

        // 標準經緯度 (WGS84) 轉 TWD97 (TM2) 精確換算演算法
        function latLngToTwd97(lat, lng) {
            const a = 6378137.0;
            const b = 6356752.314245;
            const lon0 = 121.0 * Math.PI / 180;
            const k0 = 0.9999;
            const dx = 250000;
            const e = Math.sqrt(1 - (b * b) / (a * a));
            const e2 = (e * e) / (1 - e * e);

            const phi = lat * Math.PI / 180;
            const lambda = lng * Math.PI / 180;

            const T = Math.tan(phi) * Math.tan(phi);
            const C = e2 * Math.cos(phi) * Math.cos(phi);
            const A = (lambda - lon0) * Math.cos(phi);

            const M = a * ((1 - e * e / 4 - 3 * e * e * e * e / 64 - 5 * Math.pow(e, 6) / 256) * phi
                - (3 * e * e / 8 + 3 * e * e * e * e / 32 + 45 * Math.pow(e, 6) / 1024) * Math.sin(2 * phi)
                + (15 * e * e * e * e / 256 + 45 * Math.pow(e, 6) / 1024) * Math.sin(4 * phi)
                - (35 * Math.pow(e, 6) / 3072) * Math.sin(6 * phi));

            const nu = a / Math.sqrt(1 - e * e * Math.sin(phi) * Math.sin(phi));

            const x = dx + k0 * nu * (A + (1 - T + C) * Math.pow(A, 3) / 6 + (5 - 18 * T + T * T + 72 * C - 58 * e2) * Math.pow(A, 5) / 120);
            const y = k0 * (M + nu * Math.tan(phi) * (A * A / 2 + (5 - T + 9 * C + 4 * C * C) * Math.pow(A, 4) / 24 + (61 - 58 * T + T * T + 600 * C - 330 * e2) * Math.pow(A, 6) / 720));

            return { x: Math.round(x), y: Math.round(y) };
        }

        // TWD97 (TM2) 轉 WGS84 經緯度精確換算演算法
        function twd97ToLatLng(x, y) {
            const a = 6378137.0;
            const b = 6356752.314245;
            const lon0 = 121.0 * Math.PI / 180;
            const k0 = 0.9999;
            const dx = 250000;
            const e = Math.sqrt(1 - (b * b) / (a * a));
            const e2 = (e * e) / (1 - e * e);

            const x1 = x - dx;
            const y1 = y;

            const M = y1 / k0;
            const mu = M / (a * (1 - e * e / 4 - 3 * Math.pow(e, 4) / 64 - 5 * Math.pow(e, 6) / 256));
            const e1 = (1 - Math.sqrt(1 - e * e)) / (1 + Math.sqrt(1 - e * e));

            const J1 = (3 * e1 / 2 - 27 * Math.pow(e1, 3) / 32);
            const J2 = (21 * Math.pow(e1, 2) / 16 - 55 * Math.pow(e1, 4) / 32);
            const J3 = (151 * Math.pow(e1, 3) / 96);
            const J4 = (1097 * Math.pow(e1, 4) / 512);

            const fp = mu + J1 * Math.sin(2 * mu) + J2 * Math.sin(4 * mu) + J3 * Math.sin(6 * mu) + J4 * Math.sin(8 * mu);

            const C1 = e2 * Math.pow(Math.cos(fp), 2);
            const T1 = Math.pow(Math.tan(fp), 2);
            const R1 = a * (1 - e * e) / Math.pow(1 - e * e * Math.pow(Math.sin(fp), 2), 1.5);
            const N1 = a / Math.sqrt(1 - e * e * Math.pow(Math.sin(fp), 2));
            const D = x1 / (N1 * k0);

            const Q1 = N1 * Math.tan(fp) / R1;
            const Q2 = (D * D / 2);
            const Q3 = (5 + 3 * T1 + 10 * C1 - 4 * C1 * C1 - 9 * e2) * Math.pow(D, 4) / 24;
            const Q4 = (61 + 90 * T1 + 298 * C1 + 45 * T1 * T1 - 252 * e2 - 3 * C1 * C1) * Math.pow(D, 6) / 720;
            const phi = fp - Q1 * (Q2 - Q3 + Q4);

            const Q5 = D;
            const Q6 = (1 + 2 * T1 + C1) * Math.pow(D, 3) / 6;
            const Q7 = (5 - 2 * C1 + 28 * T1 - 3 * C1 * C1 + 8 * e2 + 24 * T1 * T1) * Math.pow(D, 5) / 120;
            const lambda = lon0 + (Q5 - Q6 + Q7) / Math.cos(fp);

            return {
                lat: phi * 180 / Math.PI,
                lng: lambda * 180 / Math.PI
            };
        }

        const app = createApp({
            setup() {
                const urlParams = new URLSearchParams(window.location.search);
                const queryMode = (urlParams.get('mode') || 'new').toLowerCase();
                const queryId = urlParams.get('id') || '';

                const isEditMode = ref(queryMode === 'edit' && !!queryId);
                const isSubmitting = ref(false);
                const isMapCollapsed = ref(false);
                const currentUser = ref('系統查核員');

                // 選單資料
                const towns = ref([]);
                const roadLvOptions = ref([]);
                const smoothOptions = ref([]);
                const coverSoilOptions = ref([]);

                // 核心表單資料模型
                const form = reactive({
                    BSC_ID: queryId,
                    Report_Date: '',
                    TOWN_CODE: '',
                    ROAD_LV: '市區道路',
                    ROAD_Name: '',
                    Smooth: '',
                    Cover_Soil: '',
                    Memo: '',
                    S_UTME: '',
                    S_UTMN: ''
                });

                // 照片資料清單
                const photos = ref([]);
                const fileInput = ref(null);
                const lightboxImg = ref(null);

                // Leaflet 相關
                let map = null;
                let marker = null;
                const currentLat = ref(25.0123);
                const currentLng = ref(121.4627);

                // 判定必填欄位完成度
                const isFormComplete = computed(() => {
                    return !!form.TOWN_CODE && 
                           !!form.ROAD_LV && 
                           !!form.ROAD_Name.trim() && 
                           !!form.Smooth && 
                           !!form.Cover_Soil && 
                           Number(form.S_UTME) > 100000 && 
                           Number(form.S_UTMN) > 100000;
                });

                // 初始化地圖
                const initMap = () => {
                    const defaultLatLng = [currentLat.value, currentLng.value];
                    map = L.map('map', {
                        center: defaultLatLng,
                        zoom: 14,
                        zoomControl: true
                    });

                    // 1. 臺灣通用電子地圖 (NLSC WMTS)
                    const emapLayer = L.tileLayer('https://wmts.nlsc.gov.tw/wmts/EMAP/default/GoogleMapsCompatible/{z}/{y}/{x}', {
                        maxZoom: 19,
                        crossOrigin: true,
                        attribution: '&copy; <a href="https://maps.nlsc.gov.tw/" target="_blank">國土測繪圖資</a>'
                    });

                    // 2. OpenStreetMap 備用圖層
                    const osmLayer = L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
                        maxZoom: 19,
                        attribution: '&copy; OpenStreetMap'
                    });

                    emapLayer.addTo(map);

                    // 依規範：圖層切換器放置於右上角，其餘控制鈕置於卡片 Header
                    L.control.layers({
                        '臺灣通用電子地圖': emapLayer,
                        'OpenStreetMap': osmLayer
                    }, null, { position: 'topright' }).addTo(map);

                    // 標記 Pin (可拖曳)
                    marker = L.marker(defaultLatLng, {
                        draggable: true,
                        autoPan: true
                    }).addTo(map);

                    // 拖曳結束更新座標
                    marker.on('dragend', (e) => {
                        const pos = e.target.getLatLng();
                        updateCoordinates(pos.lat, pos.lng);
                    });

                    // 點擊地圖任意處直接定位
                    map.on('click', (e) => {
                        const lat = e.latlng.lat;
                        const lng = e.latlng.lng;
                        marker.setLatLng([lat, lng]);
                        updateCoordinates(lat, lng);
                    });

                    setTimeout(() => {
                        if (map) map.invalidateSize();
                    }, 300);
                };

                // 更新座標與換算 TWD97
                const updateCoordinates = (lat, lng) => {
                    currentLat.value = lat;
                    currentLng.value = lng;
                    const twd = latLngToTwd97(lat, lng);
                    form.S_UTME = twd.x;
                    form.S_UTMN = twd.y;
                };

                // 根據 TWD97 更新地圖位置
                const setLocationFromTwd97 = (x, y) => {
                    const ll = twd97ToLatLng(x, y);
                    currentLat.value = ll.lat;
                    currentLng.value = ll.lng;
                    form.S_UTME = Math.round(x);
                    form.S_UTMN = Math.round(y);
                    if (map && marker) {
                        marker.setLatLng([ll.lat, ll.lng]);
                        map.setView([ll.lat, ll.lng], 16);
                    }
                };

                // GPS 現場定位
                const locateGPS = () => {
                    if (!navigator.geolocation) {
                        alert('您的瀏覽器不支援 GPS 定位功能');
                        return;
                    }
                    navigator.geolocation.getCurrentPosition(
                        (pos) => {
                            const lat = pos.coords.latitude;
                            const lng = pos.coords.longitude;
                            if (map && marker) {
                                marker.setLatLng([lat, lng]);
                                map.setView([lat, lng], 17);
                            }
                            updateCoordinates(lat, lng);
                        },
                        (err) => {
                            alert('無法取得 GPS 定位：' + err.message + '，請確認是否已授權瀏覽器定位權限。');
                        },
                        { enableHighAccuracy: true, timeout: 10000 }
                    );
                };

                // 重設地圖視野
                const resetMapView = () => {
                    if (!map) return;
                    if (form.TOWN_CODE && TOWN_COORDS[form.TOWN_CODE]) {
                        map.setView(TOWN_COORDS[form.TOWN_CODE], 14);
                    } else {
                        map.setView([currentLat.value, currentLng.value], 14);
                    }
                };

                // 行政區切換時平移地圖
                const onTownChange = () => {
                    const code = form.TOWN_CODE;
                    if (code && TOWN_COORDS[code]) {
                        const center = TOWN_COORDS[code];
                        if (map && marker) {
                            marker.setLatLng(center);
                            map.setView(center, 14);
                        }
                        updateCoordinates(center[0], center[1]);
                    }
                };

                // 手機地圖展開 / 收合切換
                const toggleMapCollapse = () => {
                    isMapCollapsed.value = !isMapCollapsed.value;
                    nextTick(() => {
                        if (map) map.invalidateSize();
                    });
                };

                // 取得頁面初始選單資料
                const loadInitData = async () => {
                    try {
                        const res = await axios.get('NewBSC.aspx?action=getinit');
                        if (res.data && res.data.Success) {
                            const d = res.data.Data;
                            currentUser.value = d.CurrentUser;
                            towns.value = d.Towns;
                            roadLvOptions.value = d.RoadLvOptions;
                            smoothOptions.value = d.SmoothOptions;
                            coverSoilOptions.value = d.CoverSoilOptions;

                            if (!isEditMode.value) {
                                form.BSC_ID = d.GeneratedCaseId;
                                form.Report_Date = d.ReportDate;
                                // 預設選擇第一個行政區並定位
                                if (d.Towns.length > 0) {
                                    form.TOWN_CODE = d.Towns[0].TownNo;
                                    onTownChange();
                                }
                            }
                        } else {
                            alert('載入選項資料失敗：' + (res.data ? res.data.Message : ''));
                        }
                    } catch (ex) {
                        console.error('getinit 錯誤', ex);
                    }
                };

                // 編輯模式載入既有案件資料
                const loadCaseData = async () => {
                    if (!isEditMode.value) return;
                    try {
                        const res = await axios.get(`NewBSC.aspx?action=getcase&id=${queryId}`);
                        if (res.data && res.data.Success) {
                            const c = res.data.Data;
                            form.BSC_ID = c.BSC_ID;
                            form.Report_Date = c.Report_Date;
                            form.TOWN_CODE = c.TOWN_CODE;
                            form.ROAD_LV = c.ROAD_LV || '市區道路';
                            form.ROAD_Name = c.ROAD_Name || '';
                            form.Smooth = c.Smooth || '';
                            form.Cover_Soil = c.Cover_Soil || '';
                            form.Memo = c.Memo || '';
                            form.S_UTME = c.S_UTME;
                            form.S_UTMN = c.S_UTMN;

                            // 既有佐證照片
                            if (c.Photos && c.Photos.length > 0) {
                                photos.value = c.Photos.map(p => ({
                                    FileName: p.FileName,
                                    Url: p.Url,
                                    Base64: ''
                                }));
                            }

                            // 移動地圖定位
                            if (Number(c.S_UTME) > 0 && Number(c.S_UTMN) > 0) {
                                setLocationFromTwd97(Number(c.S_UTME), Number(c.S_UTMN));
                            }
                        } else {
                            alert('載入案件失敗：' + (res.data ? res.data.Message : ''));
                        }
                    } catch (ex) {
                        console.error('getcase 錯誤', ex);
                    }
                };

                // 平整度晶片外觀與圖標樣式
                const getSmoothChipClass = (code) => {
                    if (form.Smooth !== code) return '';
                    if (code === '1') return 'active-success';
                    if (code === '2') return 'active-warning';
                    return 'active-danger';
                };

                const getSmoothIcon = (code) => {
                    if (form.Smooth !== code) return 'fas fa-square text-muted';
                    if (code === '1') return 'fas fa-check-circle text-success';
                    if (code === '2') return 'fas fa-exclamation-triangle text-warning';
                    return 'fas fa-times-circle text-danger';
                };

                // 覆土狀況晶片外觀與圖標樣式
                const getCoverSoilChipClass = (code) => {
                    if (form.Cover_Soil !== code) return '';
                    if (code === '1') return 'active-success';
                    if (code === '2') return 'active-warning';
                    return 'active-danger';
                };

                const getCoverSoilIcon = (code) => {
                    if (form.Cover_Soil !== code) return 'fas fa-square text-muted';
                    if (code === '1') return 'fas fa-leaf text-success';
                    if (code === '2') return 'fas fa-mountain text-warning';
                    return 'fas fa-exclamation-circle text-danger';
                };

                // 觸發照片選擇
                const triggerFileInput = () => {
                    if (photos.value.length >= 6) {
                        alert('佐證照片上限為 6 張');
                        return;
                    }
                    if (fileInput.value) {
                        fileInput.value.click();
                    }
                };

                // 照片壓縮處理 (Canvas Resize max 1600x1200 @ 0.85 Quality)
                const compressImage = (file) => {
                    return new Promise((resolve) => {
                        const reader = new FileReader();
                        reader.readAsDataURL(file);
                        reader.onload = (e) => {
                            const img = new Image();
                            img.src = e.target.result;
                            img.onload = () => {
                                const maxWidth = 1600;
                                const maxHeight = 1200;
                                let width = img.width;
                                let height = img.height;

                                if (width > maxWidth || height > maxHeight) {
                                    if (width / height > maxWidth / maxHeight) {
                                        height = Math.round(height * (maxWidth / width));
                                        width = maxWidth;
                                    } else {
                                        width = Math.round(width * (maxHeight / height));
                                        height = maxHeight;
                                    }
                                }

                                const canvas = document.createElement('canvas');
                                canvas.width = width;
                                canvas.height = height;
                                const ctx = canvas.getContext('2d');
                                ctx.drawImage(img, 0, 0, width, height);

                                const compressedDataUrl = canvas.toDataURL('image/jpeg', 0.85);
                                resolve(compressedDataUrl);
                            };
                        };
                    });
                };

                // 選取照片處理
                const onFilesSelected = async (e) => {
                    const files = e.target.files;
                    if (!files || files.length === 0) return;

                    const remainCount = 6 - photos.value.length;
                    const processCount = Math.min(remainCount, files.length);

                    for (let i = 0; i < processCount; i++) {
                        const f = files[i];
                        const base64 = await compressImage(f);
                        photos.value.push({
                            FileName: f.name,
                            Base64: base64,
                            Url: ''
                        });
                    }

                    if (fileInput.value) {
                        fileInput.value.value = '';
                    }
                };

                // 刪除照片
                const removePhoto = async (index) => {
                    const target = photos.value[index];
                    if (!confirm(`確定要刪除這張佐證照片嗎？`)) return;

                    if (isEditMode.value && target.FileName && target.Url) {
                        try {
                            const res = await axios.get(`NewBSC.aspx?action=deletephoto&id=${queryId}&filename=${encodeURIComponent(target.FileName)}`);
                            if (!res.data || !res.data.Success) {
                                alert('伺服器刪除失敗：' + (res.data ? res.data.Message : ''));
                            }
                        } catch (err) {
                            console.error('刪除照片例外', err);
                        }
                    }
                    photos.value.splice(index, 1);
                };

                // 大圖燈箱預覽
                const openLightbox = (imgSrc) => {
                    lightboxImg.value = imgSrc;
                };

                const closeLightbox = () => {
                    lightboxImg.value = null;
                };

                // 送出通報單 (儲存 / 新增)
                const submitCase = async () => {
                    if (!form.TOWN_CODE) {
                        alert('請選擇行政區！');
                        return;
                    }
                    if (!form.ROAD_LV) {
                        alert('請選擇道路級別！');
                        return;
                    }
                    if (!form.ROAD_Name.trim()) {
                        alert('請輸入道路名稱！');
                        return;
                    }
                    if (!form.Smooth) {
                        alert('請評估人行道鋪面平整度！');
                        return;
                    }
                    if (!form.Cover_Soil) {
                        alert('請評估人行道或交通島覆土狀況！');
                        return;
                    }
                    if (Number(form.S_UTME) < 100000 || Number(form.S_UTMN) < 100000) {
                        alert('通報座標尚未取得或座標錯誤，請點選地圖或使用 GPS 定位！');
                        return;
                    }

                    const confirmMsg = isEditMode.value
                        ? '確定要儲存案件修改內容嗎？'
                        : '確定要送出此筆裸露覆土通報單嗎？';
                    if (!confirm(confirmMsg)) return;

                    isSubmitting.value = true;
                    try {
                        const payload = {
                            Mode: isEditMode.value ? 'edit' : 'new',
                            BSC_ID: form.BSC_ID,
                            TOWN_CODE: form.TOWN_CODE,
                            ROAD_LV: form.ROAD_LV,
                            ROAD_Name: form.ROAD_Name.trim(),
                            Smooth: form.Smooth,
                            Cover_Soil: form.Cover_Soil,
                            Memo: form.Memo.trim(),
                            S_UTME: form.S_UTME,
                            S_UTMN: form.S_UTMN,
                            Photos: photos.value.map(p => ({
                                FileName: p.FileName,
                                Base64: p.Base64 || ''
                            }))
                        };

                        const res = await axios.post('NewBSC.aspx?action=save', payload);
                        if (res.data && res.data.Success) {
                            alert(res.data.Message || '通報成功！');
                            window.location.href = 'BSC_List.aspx?mode=BSCEdit';
                        } else {
                            alert('儲存失敗：' + (res.data ? res.data.Message : '未知錯誤'));
                        }
                    } catch (ex) {
                        console.error('送出通報例外', ex);
                        alert('通報發生錯誤：' + ex.message);
                    } finally {
                        isSubmitting.value = false;
                    }
                };

                onMounted(async () => {
                    initMap();
                    await loadInitData();
                    if (isEditMode.value) {
                        await loadCaseData();
                    }
                });

                return {
                    isEditMode,
                    isSubmitting,
                    isMapCollapsed,
                    currentUser,
                    towns,
                    roadLvOptions,
                    smoothOptions,
                    coverSoilOptions,
                    form,
                    photos,
                    fileInput,
                    lightboxImg,
                    currentLat,
                    currentLng,
                    isFormComplete,
                    locateGPS,
                    resetMapView,
                    onTownChange,
                    toggleMapCollapse,
                    getSmoothChipClass,
                    getSmoothIcon,
                    getCoverSoilChipClass,
                    getCoverSoilIcon,
                    triggerFileInput,
                    onFilesSelected,
                    removePhoto,
                    openLightbox,
                    closeLightbox,
                    submitCase
                };
            }
        });

        app.mount('#bscApp');
    </script>
</body>
</html>
