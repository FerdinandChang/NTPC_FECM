<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="NewBreak.aspx.cs" Inherits="NTPC_FEC.RoadBreak.NewBreak" %>

<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定溢散源管理平台 - 道路破損現場通報</title>

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

        /* 道路級別與狀態晶片組 (Segmented / Score Chips) */
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
            padding: 12px 24px;
            font-size: 1rem;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            transition: all 0.15s ease;
        }

        .btn-action-secondary:hover {
            background: #f1f5f9;
            color: #1e293b;
        }

        /* 手機行動端底部懸浮動作列 */
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
                border-top: 1px solid var(--border-color);
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

        /* 燈箱視窗 (Lightbox) */
        .lightbox-modal {
            position: fixed;
            top: 0; left: 0; right: 0; bottom: 0;
            background: rgba(0, 0, 0, 0.85);
            z-index: 2000;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }

        .lightbox-img {
            max-width: 95vw;
            max-height: 90vh;
            border-radius: 8px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.5);
        }

        .lightbox-close {
            position: absolute;
            top: 20px;
            right: 20px;
            background: rgba(255, 255, 255, 0.25);
            color: #ffffff;
            border: none;
            border-radius: 50%;
            width: 44px;
            height: 44px;
            font-size: 1.5rem;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        /* 地圖標記 Pin */
        .custom-map-marker {
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .marker-pin {
            width: 34px;
            height: 34px;
            border-radius: 50% 50% 50% 0;
            background: #ef4444;
            position: absolute;
            transform: rotate(-45deg);
            left: 50%;
            top: 50%;
            margin: -22px 0 0 -17px;
            box-shadow: 0 3px 8px rgba(0, 0, 0, 0.35);
            border: 2px solid #ffffff;
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
        }
        .marker-icon {
            transform: rotate(45deg);
            color: #ffffff;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div id="breakApp" v-cloak>
            <!-- 頂部導覽列 -->
            <header class="top-navbar">
                <div class="brand-title">
                    <a v-on:click="goBack" class="nav-btn">
                        <i class="fas fa-arrow-left"></i> 返回
                    </a>
                    <span>
                        <i class="fas fa-road"></i> 道路破損現場通報
                    </span>
                    <span class="mode-badge" :class="mode === 'new' ? 'badge-new' : 'badge-edit'">
                        {{ mode === 'new' ? '新增通報' : '案件編輯' }}
                    </span>
                </div>
                <div class="d-none d-md-flex align-items-center gap-2">
                    <button type="button" class="nav-btn" v-on:click="submitForm" :disabled="isSubmitting">
                        <i class="fas fa-paper-plane" :class="{ 'fa-spin': isSubmitting }"></i>
                        {{ isSubmitting ? '儲存中...' : '送出通報' }}
                    </button>
                </div>
            </header>

            <!-- 主作業容器 -->
            <main class="main-container">
                <!-- 提示訊息橫幅 -->
                <div v-if="alertMessage" class="alert alert-dismissible fade show" :class="'alert-' + alertType" role="alert">
                    <i class="fas" :class="alertType === 'success' ? 'fa-check-circle' : 'fa-exclamation-triangle'"></i>
                    <strong class="ml-1">{{ alertMessage }}</strong>
                    <button type="button" class="close" v-on:click="alertMessage = ''">&times;</button>
                </div>

                <div class="row">
                    <!-- 左欄：現場地圖與定位資訊 (桌面固頂) -->
                    <div class="col-12 col-xl-5">
                        <div class="sticky-sidebar">
                            <!-- 地圖卡片 -->
                            <div class="card-modern">
                                <div class="card-modern-header">
                                    <h2 class="card-modern-title">
                                        <i class="fas fa-map-marked-alt text-primary"></i> 現場位置定位
                                    </h2>
                                    <div class="d-flex align-items-center gap-2">
                                        <button type="button" class="btn btn-sm btn-outline-primary" v-on:click="getCurrentLocation" title="取得 GPS 定位">
                                            <i class="fas fa-crosshairs"></i> GPS 定位
                                        </button>
                                        <button type="button" class="btn btn-sm btn-outline-secondary" v-on:click="resetMapView" title="重設地圖全景">
                                            <i class="fas fa-redo-alt"></i>
                                        </button>
                                        <button type="button" class="btn btn-sm btn-outline-info d-xl-none" v-on:click="toggleMapCollapse">
                                            <i class="fas" :class="isMapCollapsed ? 'fa-chevron-down' : 'fa-chevron-up'"></i>
                                        </button>
                                    </div>
                                </div>
                                <div class="card-modern-body p-2">
                                    <!-- Leaflet 容器 -->
                                    <div id="map" :class="{ 'map-collapsed': isMapCollapsed }"></div>

                                    <!-- 坐標晶片列 -->
                                    <div class="coord-chip-row">
                                        <div class="coord-chip-item">
                                            <div class="coord-label">TWD97 X (E)</div>
                                            <div class="coord-value text-primary">{{ form.S_UTME || '尚未定位' }}</div>
                                        </div>
                                        <div class="coord-chip-item">
                                            <div class="coord-label">TWD97 Y (N)</div>
                                            <div class="coord-value text-primary">{{ form.S_UTMN || '尚未定位' }}</div>
                                        </div>
                                        <div class="coord-chip-item" v-if="form.Lat && form.Lon">
                                            <div class="coord-label">WGS84 經緯度</div>
                                            <div class="coord-value text-muted" style="font-size: 0.85rem;">
                                                {{ Number(form.Lat).toFixed(5) }}, {{ Number(form.Lon).toFixed(5) }}
                                            </div>
                                        </div>
                                    </div>
                                    <small class="text-muted d-block mt-2 px-1">
                                        <i class="fas fa-info-circle text-info"></i> 提示：點擊地圖任意位置可快速標記，或拖拉紅色座標釘進行微調。
                                    </small>
                                </div>
                            </div>

                            <!-- 案件基本狀態卡片 -->
                            <div class="card-modern">
                                <div class="card-modern-header">
                                    <h2 class="card-modern-title">
                                        <i class="fas fa-clipboard-check text-info"></i> 通報狀態
                                    </h2>
                                </div>
                                <div class="card-modern-body">
                                    <div class="row">
                                        <div class="col-6 mb-2">
                                            <small class="text-muted d-block font-weight-bold">通報案號</small>
                                            <span class="font-weight-bold text-dark">{{ form.Break_ID || '自動生成' }}</span>
                                        </div>
                                        <div class="col-6 mb-2">
                                            <small class="text-muted d-block font-weight-bold">查核人員</small>
                                            <span class="font-weight-bold text-dark">{{ currentUser }}</span>
                                        </div>
                                        <div class="col-12">
                                            <small class="text-muted d-block font-weight-bold">通報時間</small>
                                            <span class="text-secondary">{{ form.Report_Date || '送出時自動記錄當前時間' }}</span>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- 右欄：通報表單與現場照片作業區 -->
                    <div class="col-12 col-xl-7">
                        <!-- 基本資料卡片 -->
                        <div class="card-modern">
                            <div class="card-modern-header">
                                <h2 class="card-modern-title">
                                    <i class="fas fa-edit text-primary"></i> 道路通報資料
                                </h2>
                            </div>
                            <div class="card-modern-body">
                                <div class="row">
                                    <!-- 行政區 -->
                                    <div class="col-12 col-md-6 mb-3">
                                        <label class="form-label-custom">
                                            行政區 <span class="badge-req">必填</span>
                                        </label>
                                        <select class="form-control-custom" v-model="form.TOWN_CODE">
                                            <option value="">-- 請選擇行政區 --</option>
                                            <option v-for="t in towns" :key="t.TownNo" :value="t.TownNo">
                                                {{ t.TownName }}
                                            </option>
                                        </select>
                                    </div>

                                    <!-- 道路名稱 -->
                                    <div class="col-12 col-md-6 mb-3">
                                        <label class="form-label-custom">
                                            道路名稱 <span class="badge-req">必填</span>
                                        </label>
                                        <input type="text" class="form-control-custom" v-model.trim="form.ROAD_Name" placeholder="例如：文化路一段、中正路等" />
                                    </div>

                                    <!-- 道路級別 -->
                                    <div class="col-12 mb-3">
                                        <label class="form-label-custom">
                                            道路級別 <span class="badge-req">必選</span>
                                        </label>
                                        <div class="chips-group">
                                            <button v-for="lv in roadLvOptions" :key="lv" type="button" class="chip-btn"
                                                    :class="{ 'active-primary': form.ROAD_LV === lv }"
                                                    v-on:click="form.ROAD_LV = lv">
                                                <i class="fas" :class="form.ROAD_LV === lv ? 'fa-check-circle' : 'fa-circle text-muted'" style="font-size: 0.8rem;"></i>
                                                {{ lv }}
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- 破損現況查核卡片 -->
                        <div class="card-modern">
                            <div class="card-modern-header">
                                <h2 class="card-modern-title">
                                    <i class="fas fa-exclamation-circle text-warning"></i> 破損與銜接現況
                                </h2>
                            </div>
                            <div class="card-modern-body">
                                <!-- 道路鋪面平整度 -->
                                <div class="mb-4">
                                    <label class="form-label-custom">
                                        道路鋪面平整度 <span class="badge-req">必選</span>
                                    </label>
                                    <div class="chips-group">
                                        <button v-for="opt in smoothOptions" :key="opt.Code" type="button" class="chip-btn"
                                                :class="getSmoothChipClass(opt.Code)"
                                                v-on:click="form.Smooth = opt.Code">
                                            <i class="fas" :class="getSmoothIcon(opt.Code)"></i>
                                            {{ opt.Val }}
                                        </button>
                                    </div>
                                </div>

                                <!-- 人手孔蓋銜接處狀況 -->
                                <div class="mb-3">
                                    <label class="form-label-custom">
                                        道路鋪面與人手孔蓋銜接處狀況 <span class="badge-req">必選</span>
                                    </label>
                                    <div class="chips-group">
                                        <button v-for="h in holeOptions" :key="h.Code" type="button" class="chip-btn"
                                                :class="getHoleChipClass(h.Code)"
                                                v-on:click="form.Hole_Conn_St = h.Code">
                                            <i class="fas" :class="getHoleIcon(h.Code)"></i>
                                            {{ h.Val }}
                                        </button>
                                    </div>
                                </div>

                                <!-- 補充說明 -->
                                <div class="mt-3">
                                    <label class="form-label-custom">
                                        通報補充說明
                                    </label>
                                    <textarea class="form-control-custom" rows="3" v-model="form.Memo" placeholder="請填寫破損位置特徵、長度深度或特殊注意事項..."></textarea>
                                </div>
                            </div>
                        </div>

                        <!-- 現場佐證照片卡片 -->
                        <div class="card-modern">
                            <div class="card-modern-header">
                                <h2 class="card-modern-title">
                                    <i class="fas fa-camera text-primary"></i> 現場佐證照片
                                    <span class="badge badge-pill badge-light border ml-2">
                                        {{ photos.length }} / 6 張
                                    </span>
                                </h2>
                                <span class="text-muted small">支援手機直接拍照與自動壓縮</span>
                            </div>
                            <div class="card-modern-body">
                                <input type="file" ref="fileInput" accept="image/*" capture="environment" multiple style="display: none;" v-on:change="onFilesSelected" />

                                <div class="photo-grid">
                                    <!-- 既有/已選取照片卡片 -->
                                    <div v-for="(p, idx) in photos" :key="idx" class="photo-card">
                                        <div class="photo-preview-box" v-on:click="openLightbox(p.PreviewUrl || p.Url)">
                                            <img :src="p.PreviewUrl || p.Url" :alt="'佐證照片 ' + (idx + 1)" />
                                            <div class="photo-badge">佐證照片 {{ idx + 1 }}</div>
                                        </div>
                                        <div class="photo-footer">
                                            <span class="photo-title" :title="p.FileName || ('佐證照片_' + (idx + 1))">
                                                {{ p.FileName || ('佐證照片_' + (idx + 1)) }}
                                            </span>
                                            <button type="button" class="btn-del-photo" v-on:click="removePhoto(idx)" title="刪除照片">
                                                <i class="fas fa-trash-alt"></i>
                                            </button>
                                        </div>
                                    </div>

                                    <!-- 新增照片按鈕方塊 (最多 6 張) -->
                                    <div v-if="photos.length < 6" class="photo-add-box" v-on:click="triggerFileSelect">
                                        <i class="fas fa-camera-retro"></i>
                                        <span class="font-weight-bold">拍照 / 上傳照片</span>
                                        <small class="text-muted">點此開啟相機或相簿</small>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- 桌面端表單動作列 -->
                        <div class="d-none d-md-flex align-items-center justify-content-end gap-3 mt-4 mb-5">
                            <button type="button" class="btn-action-secondary" v-on:click="goBack">
                                <i class="fas fa-times"></i> 取消離開
                            </button>
                            <button type="button" class="btn-action-primary" v-on:click="submitForm" :disabled="isSubmitting">
                                <i class="fas fa-paper-plane" :class="{ 'fa-spin': isSubmitting }"></i>
                                {{ isSubmitting ? '儲存中...' : (mode === 'new' ? '確定送出通報' : '更新通報資料') }}
                            </button>
                        </div>
                    </div>
                </div>
            </main>

            <!-- 手機端常駐浮動底部列 -->
            <div class="mobile-bottom-bar d-flex d-md-none">
                <button type="button" class="btn btn-outline-secondary" v-on:click="goBack">
                    取消
                </button>
                <button type="button" class="btn btn-outline-primary" v-on:click="triggerFileSelect" :disabled="photos.length >= 6">
                    <i class="fas fa-camera"></i> 拍照 ({{ photos.length }}/6)
                </button>
                <button type="button" class="btn btn-primary" v-on:click="submitForm" :disabled="isSubmitting">
                    <i class="fas fa-paper-plane" :class="{ 'fa-spin': isSubmitting }"></i>
                    {{ isSubmitting ? '送出中' : '確定送出' }}
                </button>
            </div>

            <!-- 照片燈箱視窗 (Lightbox) -->
            <div v-if="lightboxImg" class="lightbox-modal" v-on:click="lightboxImg = null">
                <button type="button" class="lightbox-close" v-on:click="lightboxImg = null">&times;</button>
                <img :src="lightboxImg" class="lightbox-img" v-on:click.stop alt="放大檢視照片" />
            </div>
        </div>
    </form>

    <!-- 本地化 JS 核心依賴 -->
    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>
    <script src="../Scripts/leaflet/leaflet.js"></script>

    <script type="text/javascript">
        // TWD97 與 WGS84 前端高精度雙向轉換函式
        const Twd97Wgs84Helper = {
            // TWD97 (X, Y) 轉 WGS84 (Lat, Lon)
            twd97ToWgs84: function(x, y) {
                if (!x || !y || x <= 0 || y <= 0) return { lat: 0, lon: 0 };
                const a = 6378137.0;
                const b = 6356752.314245;
                const lon0 = 121.0 * Math.PI / 180.0;
                const k0 = 0.9999;
                const dx = 250000.0;

                const e = Math.sqrt(1.0 - (b * b) / (a * a));
                const e2 = (e * e) / (1.0 - e * e);
                const xShift = x - dx;

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
                const D = xShift / (N1 * k0);

                const latRad = fp - (N1 * Math.tan(fp) / R1) * (Math.pow(D, 2) / 2.0 - (5.0 + 3.0 * T1 + 10.0 * C1 - 4.0 * Math.pow(C1, 2) - 9.0 * e2) * Math.pow(D, 4) / 24.0 + (61.0 + 90.0 * T1 + 298.0 * C1 + 45.0 * Math.pow(T1, 2) - 252.0 * e2 - 3.0 * Math.pow(C1, 2)) * Math.pow(D, 6) / 720.0);
                const lonRad = lon0 + (D - (1.0 + 2.0 * T1 + C1) * Math.pow(D, 3) / 6.0 + (5.0 - 2.0 * C1 + 28.0 * T1 - 3.0 * Math.pow(C1, 2) + 8.0 * e2 + 24.0 * Math.pow(T1, 2)) * Math.pow(D, 5) / 120.0) / Math.cos(fp);

                return {
                    lat: latRad * 180.0 / Math.PI,
                    lon: lonRad * 180.0 / Math.PI
                };
            },

            // WGS84 (Lat, Lon) 轉 TWD97 (X, Y)
            wgs84ToTwd97: function(lat, lon) {
                if (!lat || !lon || lat <= 0 || lon <= 0) return { x: 0, y: 0 };
                const a = 6378137.0;
                const b = 6356752.314245;
                const lon0 = 121.0 * Math.PI / 180.0;
                const k0 = 0.9999;
                const dx = 250000.0;

                const e = Math.sqrt(1.0 - (b * b) / (a * a));
                const e2 = (e * e) / (1.0 - e * e);

                const latRad = lat * Math.PI / 180.0;
                const lonRad = lon * Math.PI / 180.0;

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

                return {
                    x: Math.round(x),
                    y: Math.round(y)
                };
            }
        };

        const { createApp } = Vue;

        createApp({
            data() {
                return {
                    mode: 'new',            // 'new' | 'edit'
                    caseId: '',
                    currentUser: '系統查核員',
                    towns: [],
                    roadLvOptions: ['省道', '市道', '區道', '市區道路', '其他'],
                    smoothOptions: [],
                    holeOptions: [],

                    // 主表單模型
                    form: {
                        Break_ID: '',
                        Show_ID: '',
                        Report_Date: '',
                        TOWN_CODE: '',
                        ROAD_LV: '市區道路',
                        ROAD_Name: '',
                        Smooth: '',
                        Hole_Conn_St: '',
                        Memo: '',
                        S_UTME: '',
                        S_UTMN: '',
                        Lat: '',
                        Lon: ''
                    },

                    // 佐證照片清單 [{ Index, FileName, Url, Base64, PreviewUrl }]
                    photos: [],

                    // UI 狀態
                    isMapCollapsed: false,
                    isSubmitting: false,
                    alertMessage: '',
                    alertType: 'info',
                    lightboxImg: null
                };
            },

            created() {
                // 非響應式屬性隔離 Leaflet 實例 (防止 Vue 3 Proxy 報錯)
                this.leafletMap = null;
                this.marker = null;
            },

            mounted() {
                const urlParams = new URLSearchParams(window.location.search);
                const m = urlParams.get('mode');
                if (m && m.toLowerCase() === 'edit') {
                    this.mode = 'edit';
                    this.caseId = urlParams.get('id') || '';
                } else {
                    this.mode = 'new';
                }

                this.initMap();
                this.loadInitData();
            },

            methods: {
                // 1. 初始化 Leaflet 地圖
                initMap() {
                    const defaultCenter = [25.012363, 121.465715]; // 新北市政府中心
                    this.leafletMap = L.map('map', {
                        center: defaultCenter,
                        zoom: 14,
                        zoomControl: false
                    });

                    // 縮放控制按鈕配置在左下角，避開頂端
                    L.control.zoom({ position: 'bottomright' }).addTo(this.leafletMap);

                    // 圖層宣告
                    const emapLayer = L.tileLayer('https://wmts.nlsc.gov.tw/wmts/EMAP/default/GoogleMapsCompatible/{z}/{y}/{x}', {
                        maxZoom: 19,
                        attribution: '&copy; 內政部國土測繪中心'
                    });

                    const photoLayer = L.tileLayer('https://wmts.nlsc.gov.tw/wmts/PHOTO2/default/GoogleMapsCompatible/{z}/{y}/{x}', {
                        maxZoom: 19,
                        attribution: '&copy; 內政部國土測繪中心'
                    });

                    const osmLayer = L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                        maxZoom: 19,
                        attribution: '&copy; OpenStreetMap'
                    });

                    emapLayer.addTo(this.leafletMap);

                    const baseLayers = {
                        "臺灣通用電子地圖": emapLayer,
                        "正射影像圖": photoLayer,
                        "OpenStreetMap": osmLayer
                    };
                    L.control.layers(baseLayers, null, { position: 'topright' }).addTo(this.leafletMap);

                    // 點擊地圖即時選點
                    this.leafletMap.on('click', (e) => {
                        this.setMarkerPosition(e.latlng.lat, e.latlng.lng, true);
                    });
                },

                // 2. 設定座標標記 Pin (雙向同步 WGS84 與 TWD97)
                setMarkerPosition(lat, lon, panTo) {
                    if (!lat || !lon || isNaN(lat) || isNaN(lon)) return;

                    const twd = Twd97Wgs84Helper.wgs84ToTwd97(lat, lon);
                    this.form.Lat = lat.toFixed(6);
                    this.form.Lon = lon.toFixed(6);
                    this.form.S_UTME = twd.x;
                    this.form.S_UTMN = twd.y;

                    const iconHtml = '<div class="custom-map-marker"><div class="marker-pin"><i class="fas fa-exclamation-triangle marker-icon"></i></div></div>';
                    const customIcon = L.divIcon({
                        className: '',
                        html: iconHtml,
                        iconSize: [34, 34],
                        iconAnchor: [17, 34]
                    });

                    if (this.marker) {
                        this.marker.setLatLng([lat, lon]);
                    } else {
                        this.marker = L.marker([lat, lon], {
                            icon: customIcon,
                            draggable: true
                        }).addTo(this.leafletMap);

                        // 拖拉標記放開後更新座標
                        this.marker.on('dragend', (e) => {
                            const newPos = e.target.getLatLng();
                            this.setMarkerPosition(newPos.lat, newPos.lng, false);
                        });
                    }

                    if (panTo && this.leafletMap) {
                        this.leafletMap.panTo([lat, lon]);
                    }
                },

                // 3. 取得目前 GPS 定位
                getCurrentLocation() {
                    if (!navigator.geolocation) {
                        this.showAlert('您的瀏覽器或設備不支援 GPS 定位功能', 'danger');
                        return;
                    }

                    this.showAlert('正在透過 GPS 定位中，請稍候...', 'info');
                    navigator.geolocation.getCurrentPosition(
                        (position) => {
                            const lat = position.coords.latitude;
                            const lon = position.coords.longitude;
                            this.setMarkerPosition(lat, lon, true);
                            if (this.leafletMap) {
                                this.leafletMap.setView([lat, lon], 17);
                            }
                            this.showAlert('GPS 定位成功！坐標已自動同步', 'success');
                        },
                        (error) => {
                            let msg = '無法取得 GPS 定位';
                            switch (error.code) {
                                case error.PERMISSION_DENIED:
                                    msg = '定位權限被拒絕，請確認瀏覽器已允許位置存取權限';
                                    break;
                                case error.POSITION_UNAVAILABLE:
                                    msg = '無法獲取目前位置資訊';
                                    break;
                                case error.TIMEOUT:
                                    msg = '定位請求逾時，請至收訊良好處重試';
                                    break;
                            }
                            this.showAlert(msg, 'warning');
                        },
                        { enableHighAccuracy: true, timeout: 10000, maximumAge: 0 }
                    );
                },

                // 4. 重設地圖檢視
                resetMapView() {
                    if (this.form.Lat && this.form.Lon && this.leafletMap) {
                        this.leafletMap.setView([this.form.Lat, this.form.Lon], 16);
                    } else if (this.leafletMap) {
                        this.leafletMap.setView([25.012363, 121.465715], 13);
                    }
                },

                // 5. 地圖收合/展開
                toggleMapCollapse() {
                    this.isMapCollapsed = !this.isMapCollapsed;
                    setTimeout(() => {
                        if (this.leafletMap) {
                            this.leafletMap.invalidateSize();
                        }
                    }, 350);
                },

                // 6. 載入初始化選單資料
                loadInitData() {
                    axios.get('NewBreak.aspx?action=getinit')
                        .then(res => {
                            if (res.data && res.data.Success) {
                                const d = res.data.Data;
                                this.towns = d.Towns || [];
                                this.roadLvOptions = d.RoadLvOptions || this.roadLvOptions;
                                this.smoothOptions = d.SmoothOptions || [];
                                this.holeOptions = d.HoleOptions || [];
                                this.currentUser = d.CurrentUser || this.currentUser;

                                if (this.mode === 'new') {
                                    this.form.Break_ID = d.GeneratedCaseId || '';
                                    this.form.Report_Date = d.ReportDate || '';
                                    if (this.smoothOptions.length > 0) this.form.Smooth = this.smoothOptions[0].Code;
                                    if (this.holeOptions.length > 0) this.form.Hole_Conn_St = this.holeOptions[0].Code;
                                    
                                    // 新增時自動嘗試 GPS 定位一次
                                    this.getCurrentLocation();
                                } else {
                                    this.loadCaseData(this.caseId);
                                }
                            } else {
                                this.showAlert(res.data.Message || '載入設定失敗', 'danger');
                            }
                        })
                        .catch(err => {
                            console.error(err);
                            this.showAlert('連線伺服器異常，無法載入初始設定', 'danger');
                        });
                },

                // 7. 載入案件資料 (編輯模式)
                loadCaseData(id) {
                    if (!id) return;
                    axios.get('NewBreak.aspx?action=getcase&id=' + encodeURIComponent(id))
                        .then(res => {
                            if (res.data && res.data.Success) {
                                const c = res.data.Data;
                                this.form.Break_ID = c.Break_ID;
                                this.form.Show_ID = c.Show_ID;
                                this.form.Report_Date = c.Report_Date;
                                this.form.TOWN_CODE = c.TOWN_CODE;
                                this.form.ROAD_LV = c.ROAD_LV || '市區道路';
                                this.form.ROAD_Name = c.ROAD_Name;
                                this.form.Smooth = c.Smooth;
                                this.form.Hole_Conn_St = c.Hole_Conn_St;
                                this.form.Memo = c.Memo;
                                this.form.S_UTME = c.S_UTME;
                                this.form.S_UTMN = c.S_UTMN;
                                this.form.Lat = c.Lat;
                                this.form.Lon = c.Lon;

                                // 既有照片
                                this.photos = (c.Photos || []).map(p => ({
                                    FileName: p.FileName,
                                    Url: p.Url,
                                    PreviewUrl: p.Url,
                                    Base64: null
                                }));

                                // 定位地圖
                                if (c.Lat && c.Lon) {
                                    const lat = parseFloat(c.Lat);
                                    const lon = parseFloat(c.Lon);
                                    this.setMarkerPosition(lat, lon, true);
                                    if (this.leafletMap) {
                                        this.leafletMap.setView([lat, lon], 17);
                                    }
                                }
                            } else {
                                this.showAlert(res.data.Message || '找不到案件資料', 'danger');
                            }
                        })
                        .catch(err => {
                            console.error(err);
                            this.showAlert('讀取案件資料失敗', 'danger');
                        });
                },

                // 8. 樣式與圖標輔助
                getSmoothChipClass(code) {
                    if (this.form.Smooth === code) {
                        if (code === '1') return 'active-success';
                        if (code === '2') return 'active-primary';
                        if (code === '3') return 'active-warning';
                        return 'active-danger';
                    }
                    return '';
                },

                getSmoothIcon(code) {
                    if (code === '1') return 'fa-check text-success';
                    if (code === '2') return 'fa-wave-square text-info';
                    if (code === '3') return 'fa-exclamation text-warning';
                    return 'fa-ban text-danger';
                },

                getHoleChipClass(code) {
                    if (this.form.Hole_Conn_St === code) {
                        if (code === '1') return 'active-success';
                        if (code === '2') return 'active-warning';
                        return 'active-primary';
                    }
                    return '';
                },

                getHoleIcon(code) {
                    if (code === '1') return 'fa-check text-success';
                    if (code === '2') return 'fa-sort-amount-up text-warning';
                    return 'fa-circle text-muted';
                },

                // 9. 圖片選擇與 Canvas 等比例壓縮
                triggerFileSelect() {
                    if (this.$refs.fileInput) {
                        this.$refs.fileInput.click();
                    }
                },

                onFilesSelected(e) {
                    const files = e.target.files;
                    if (!files || files.length === 0) return;

                    const remainSlots = 6 - this.photos.length;
                    if (remainSlots <= 0) {
                        this.showAlert('最多僅能上傳 6 張照片', 'warning');
                        return;
                    }

                    const selectedFiles = Array.from(files).slice(0, remainSlots);
                    selectedFiles.forEach(file => {
                        this.compressAndAddPhoto(file);
                    });

                    // 清空 input 讓重複選取同張檔案仍可觸發
                    e.target.value = '';
                },

                compressAndAddPhoto(file) {
                    const reader = new FileReader();
                    reader.onload = (event) => {
                        const img = new Image();
                        img.onload = () => {
                            const canvas = document.createElement('canvas');
                            const maxDimension = 1920;
                            let width = img.width;
                            let height = img.height;

                            if (width > maxDimension || height > maxDimension) {
                                if (width > height) {
                                    height = Math.round((height * maxDimension) / width);
                                    width = maxDimension;
                                } else {
                                    width = Math.round((width * maxDimension) / height);
                                    height = maxDimension;
                                }
                            }

                            canvas.width = width;
                            canvas.height = height;
                            const ctx = canvas.getContext('2d');
                            ctx.drawImage(img, 0, 0, width, height);

                            const compressedBase64 = canvas.toDataURL('image/jpeg', 0.85);
                            this.photos.push({
                                FileName: file.name,
                                PreviewUrl: compressedBase64,
                                Base64: compressedBase64
                            });
                        };
                        img.src = event.target.result;
                    };
                    reader.readAsDataURL(file);
                },

                removePhoto(idx) {
                    const p = this.photos[idx];
                    if (p.Url && this.mode === 'edit') {
                        // 既有檔案詢問刪除
                        if (!confirm('是否確定刪除此張既有照片？')) return;
                        axios.get('NewBreak.aspx?action=deletephoto&id=' + encodeURIComponent(this.form.Break_ID) + '&filename=' + encodeURIComponent(p.FileName))
                            .then(res => {
                                if (res.data && res.data.Success) {
                                    this.photos.splice(idx, 1);
                                    this.showAlert('照片已刪除', 'success');
                                } else {
                                    this.showAlert(res.data.Message || '刪除失敗', 'danger');
                                }
                            });
                    } else {
                        this.photos.splice(idx, 1);
                    }
                },

                openLightbox(imgSrc) {
                    this.lightboxImg = imgSrc;
                },

                showAlert(msg, type) {
                    this.alertMessage = msg;
                    this.alertType = type || 'info';
                    window.scrollTo({ top: 0, behavior: 'smooth' });
                },

                // 10. 送出表單
                submitForm() {
                    // 表單驗證
                    if (!this.form.S_UTME || !this.form.S_UTMN || this.form.S_UTME < 100000 || this.form.S_UTMN < 100000) {
                        this.showAlert('請先於地圖點擊標記或點選 GPS 定位取得通報坐標！', 'danger');
                        return;
                    }
                    if (!this.form.TOWN_CODE) {
                        this.showAlert('請選擇行政區！', 'danger');
                        return;
                    }
                    if (!this.form.ROAD_Name) {
                        this.showAlert('請填寫道路名稱！', 'danger');
                        return;
                    }
                    if (!this.form.Smooth) {
                        this.showAlert('請點選道路鋪面平整度！', 'danger');
                        return;
                    }
                    if (!this.form.Hole_Conn_St) {
                        this.showAlert('請點選道路鋪面與人手孔蓋銜接處狀況！', 'danger');
                        return;
                    }

                    this.isSubmitting = true;
                    this.showAlert('正在儲存通報單，請稍候...', 'info');

                    const payload = {
                        Mode: this.mode,
                        Break_ID: this.form.Break_ID,
                        TOWN_CODE: this.form.TOWN_CODE,
                        ROAD_LV: this.form.ROAD_LV,
                        ROAD_Name: this.form.ROAD_Name,
                        Smooth: this.form.Smooth,
                        Hole_Conn_St: this.form.Hole_Conn_St,
                        Memo: this.form.Memo,
                        S_UTME: this.form.S_UTME,
                        S_UTMN: this.form.S_UTMN,
                        Lat: this.form.Lat || null,
                        Lon: this.form.Lon || null,
                        Photos: this.photos.map(p => ({
                            FileName: p.FileName,
                            Base64: p.Base64 || null
                        }))
                    };

                    axios.post('NewBreak.aspx?action=save', payload)
                        .then(res => {
                            this.isSubmitting = false;
                            if (res.data && res.data.Success) {
                                alert(res.data.Message || '通報單送出成功！');
                                window.location.href = '../RoadBreak/Break_List.aspx?mode=BreakEdit';
                            } else {
                                this.showAlert(res.data.Message || '儲存失敗', 'danger');
                            }
                        })
                        .catch(err => {
                            this.isSubmitting = false;
                            console.error(err);
                            this.showAlert('伺服器處理錯誤，儲存失敗', 'danger');
                        });
                },

                goBack() {
                    if (confirm('是否確認離開？未儲存的內容將會遺失。')) {
                        if (window.history.length > 1) {
                            window.history.back();
                        } else {
                            window.location.href = '../MainPage.aspx?sub=menu4';
                        }
                    }
                }
            }
        }).mount('#breakApp');
    </script>
</body>
</html>
