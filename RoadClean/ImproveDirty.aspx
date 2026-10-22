<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="ImproveDirty.aspx.cs" Inherits="NTPC_FEC.RoadClean.ImproveDirty" %>
<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定溢散源管理平台 - 道路污染改善回報</title>
    
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

        /* 資訊列項目 (Info Item) */
        .info-row {
            display: flex; align-items: center; justify-content: space-between;
            padding: 8px 0; border-bottom: 1px dashed #e2e8f0;
            font-size: 0.92rem;
        }
        .info-row:last-child { border-bottom: none; }
        .info-label { color: var(--text-muted); font-weight: 600; display: flex; align-items: center; gap: 6px; }
        .info-value { font-weight: 700; color: var(--brand-navy); text-align: right; }

        /* 地圖控制與容器 */
        #map {
            width: 100%; height: 320px;
            border-radius: 8px; z-index: 10;
            transition: height 0.3s ease;
        }
        #map.map-collapsed { height: 100px !important; }

        /* 地圖座標標記 (Marker Pin) */
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
        }
        .marker-pin-sub {
            width: 30px; height: 30px;
            border-radius: 50% 50% 50% 0;
            background: #0284c7;
            position: absolute; transform: rotate(-45deg);
            left: 50%; top: 50%; margin: -18px 0 0 -15px;
            box-shadow: 0 3px 8px rgba(0, 0, 0, 0.35);
            border: 2px solid #ffffff;
            display: flex; align-items: center; justify-content: center;
        }
        .marker-icon-inner { transform: rotate(45deg); color: #ffffff; font-size: 13px; }

        /* 成果橫幅 (Success Banner) */
        .banner-finished {
            background: linear-gradient(135deg, #ecfdf5 0%, #d1fae5 100%);
            border: 1px solid #10b981;
            border-radius: 12px;
            padding: 16px 20px;
            margin-bottom: 16px;
            display: flex; align-items: center; justify-content: space-between;
        }

        /* 退回通報警示面板 */
        .back-toggle-card {
            border: 2px dashed #f59e0b;
            background: #fffbeb;
            border-radius: 12px;
            padding: 14px 18px;
            margin-bottom: 16px;
            transition: all 0.2s ease;
        }
        .back-toggle-card.active-back {
            border-color: #ef4444;
            background: #fef2f2;
        }

        /* 片語標籤晶片 */
        .phrase-chips-container {
            display: flex; flex-wrap: wrap; gap: 8px;
            margin-top: 8px;
        }
        .phrase-chip {
            background: #f1f5f9;
            border: 1px solid #cbd5e1;
            color: #334155;
            padding: 4px 10px;
            border-radius: 20px;
            font-size: 0.82rem;
            cursor: pointer;
            transition: all 0.15s ease;
            user-select: none;
        }
        .phrase-chip:hover {
            background: #e2e8f0;
            border-color: #94a3b8;
            color: #0f172a;
        }

        /* 前後對比卡片 (Comparison Card) */
        .comparison-card {
            border: 1px solid #e2e8f0;
            border-radius: 12px;
            background: #ffffff;
            margin-bottom: 16px;
            overflow: hidden;
            box-shadow: 0 1px 3px rgba(0,0,0,0.03);
        }
        .comparison-header {
            background: #f8fafc;
            border-bottom: 1px solid #e2e8f0;
            padding: 10px 16px;
            font-weight: 700;
            font-size: 0.92rem;
            color: #334155;
            display: flex; align-items: center; justify-content: space-between;
        }
        .comparison-body {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 16px;
            padding: 16px;
        }
        @media screen and (max-width: 767px) {
            .comparison-body { grid-template-columns: 1fr; gap: 14px; }
        }

        /* 改善前照片展示區 */
        .photo-before-panel {
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 12px;
            background: #f8fafc;
            text-align: center;
        }
        .photo-panel-title {
            font-size: 0.88rem;
            font-weight: 700;
            color: #475569;
            margin-bottom: 8px;
            display: flex; align-items: center; justify-content: space-between;
        }
        .photo-img-box {
            position: relative;
            width: 100%;
            height: 200px;
            border-radius: 6px;
            overflow: hidden;
            background: #e2e8f0;
            display: flex; align-items: center; justify-content: center;
        }
        .photo-img-box img {
            width: 100%; height: 100%;
            object-fit: cover;
            cursor: pointer;
            transition: transform 0.2s ease;
        }
        .photo-img-box img:hover { transform: scale(1.03); }

        /* 改善後照片上傳/展示區 */
        .photo-after-panel {
            border: 1px solid #cbd5e1;
            border-radius: 8px;
            padding: 12px;
            background: #ffffff;
            text-align: center;
        }
        .upload-dropzone {
            height: 200px;
            border: 2px dashed #0284c7;
            border-radius: 8px;
            background: #f0f9ff;
            display: flex; flex-direction: column; align-items: center; justify-content: center;
            cursor: pointer;
            transition: all 0.2s ease;
            padding: 16px;
        }
        .upload-dropzone:hover {
            background: #e0f2fe;
            border-color: #0369a1;
        }
        .upload-dropzone i { font-size: 2.2rem; color: #0284c7; margin-bottom: 8px; }
        .upload-dropzone .upload-hint { font-size: 0.88rem; font-weight: 700; color: #0369a1; margin: 0; }
        .upload-dropzone .upload-sub { font-size: 0.78rem; color: #64748b; margin-top: 4px; }

        /* 手機底部固定懸浮動作列 */
        @media screen and (max-width: 991px) {
            body { padding-bottom: 80px; }
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
        .lightbox-modal {
            position: fixed; top: 0; left: 0; width: 100vw; height: 100vh;
            background: rgba(15, 23, 42, 0.92);
            z-index: 2000;
            display: flex; flex-direction: column; align-items: center; justify-content: center;
            padding: 20px;
        }
        .lightbox-img {
            max-width: 90vw; max-height: 80vh;
            border-radius: 8px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.5);
            transition: transform 0.2s ease;
        }
        .lightbox-controls {
            margin-top: 16px;
            display: flex; gap: 12px;
        }

        /* 載入中遮罩 */
        .loading-overlay {
            position: fixed; top: 0; left: 0; width: 100vw; height: 100vh;
            background: rgba(255, 255, 255, 0.85);
            z-index: 3000;
            display: flex; flex-direction: column; align-items: center; justify-content: center;
        }
    </style>
</head>
<body>
    <div id="app" v-cloak>
        <!-- 頂部現代導覽列 -->
        <header class="top-navbar">
            <div class="d-flex align-items-center">
                <a href="Dirty_List.aspx?mode=DirtyImprove" class="nav-btn mr-3" title="返回案件清單">
                    <i class="fas fa-arrow-left"></i>
                </a>
                <h1 class="brand-title">
                    <i class="fas fa-broom"></i>
                    <span>道路污染改善回報</span>
                    <span v-if="caseData.ShowId" class="badge badge-light text-primary font-weight-bold ml-2">
                        {{ caseData.ShowId }}
                    </span>
                </h1>
            </div>
            <div class="d-flex align-items-center">
                <span class="badge badge-pill badge-light font-weight-bold d-none d-sm-inline-block mr-2">
                    <i class="fas fa-user-circle mr-1"></i> {{ caseData.CurrentUserName }}
                </span>
                <span class="badge badge-pill" :class="caseData.StatusBadgeClass">
                    {{ caseData.StatusText }}
                </span>
            </div>
        </header>

        <!-- 主體內容容器 -->
        <main class="container-fluid-custom">
            <!-- 載入中骨架提示 -->
            <div v-if="isLoading" class="text-center py-5">
                <div class="spinner-border text-primary" style="width: 3rem; height: 3rem;" role="status"></div>
                <h5 class="mt-3 font-weight-bold text-muted">載入案件資料中，請稍候...</h5>
            </div>

            <!-- 錯誤提示 -->
            <div v-else-if="loadError" class="alert alert-danger shadow-sm my-4">
                <div class="d-flex align-items-center">
                    <i class="fas fa-exclamation-triangle fa-2x mr-3"></i>
                    <div>
                        <h5 class="alert-heading font-weight-bold mb-1">資料載入失敗</h5>
                        <p class="mb-0">{{ loadError }}</p>
                    </div>
                </div>
                <div class="mt-3">
                    <a href="Dirty_List.aspx?mode=DirtyImprove" class="btn btn-outline-danger font-weight-bold">
                        <i class="fas fa-arrow-left mr-1"></i> 返回改善清單
                    </a>
                </div>
            </div>

            <!-- 主作業區 -->
            <div v-else class="row">
                <!-- ==================== 左欄：通報基本設定與智慧現場地圖 (40%) ==================== -->
                <div class="col-12 col-xl-5">
                    <div class="sticky-sidebar">
                        <!-- 成果已結案橫幅 -->
                        <div v-if="caseData.IsReadOnly && caseData.StatusCode === 3" class="banner-finished">
                            <div>
                                <h6 class="font-weight-bold text-success mb-1">
                                    <i class="fas fa-check-circle mr-1"></i> 本案件已完成改善回報
                                </h6>
                                <small class="text-muted d-block">
                                    改善時間：{{ caseData.ImproveDate || '無紀錄' }}
                                </small>
                                <small class="text-muted d-block">
                                    處理人員：{{ caseData.G_UserName || caseData.G_User || '無紀錄' }}
                                </small>
                            </div>
                            <span class="badge badge-success px-3 py-2 font-weight-bold">
                                改善成果已存檔
                            </span>
                        </div>

                        <!-- 案件基本通報資訊卡片 -->
                        <div class="card-modern">
                            <div class="card-modern-header">
                                <h3 class="card-modern-title">
                                    <i class="fas fa-file-alt text-primary"></i> 通報基本資訊
                                </h3>
                                <button type="button" class="btn btn-sm btn-outline-secondary" v-on:click="copyShowId" title="複製通報案號">
                                    <i class="fas fa-copy"></i> 複製案號
                                </button>
                            </div>
                            <div class="card-modern-body">
                                <div class="info-row">
                                    <span class="info-label"><i class="fas fa-hashtag"></i> 通報案號</span>
                                    <span class="info-value text-primary font-weight-bold">{{ caseData.ShowId }}</span>
                                </div>
                                <div class="info-row">
                                    <span class="info-label"><i class="fas fa-calendar-check"></i> 查核時間</span>
                                    <span class="info-value">{{ caseData.ReportDate || '—' }}</span>
                                </div>
                                <div class="info-row">
                                    <span class="info-label"><i class="fas fa-user-shield"></i> 查核人員</span>
                                    <span class="info-value">{{ caseData.ReportUserName || '—' }}</span>
                                </div>
                                <div class="info-row">
                                    <span class="info-label"><i class="fas fa-building"></i> 通報單位</span>
                                    <span class="info-value">{{ caseData.S_ComName || '—' }}</span>
                                </div>
                                <div class="info-row">
                                    <span class="info-label"><i class="fas fa-paper-plane"></i> 通報時間</span>
                                    <span class="info-value">{{ caseData.SetComDate || '—' }}</span>
                                </div>
                                <div class="info-row">
                                    <span class="info-label"><i class="fas fa-user-edit"></i> 通報人員</span>
                                    <span class="info-value">{{ caseData.S_UserName || '—' }}</span>
                                </div>
                                <div class="info-row">
                                    <span class="info-label"><i class="fas fa-tags"></i> 污染類別</span>
                                    <span class="badge badge-info font-weight-bold">{{ caseData.KindName }}</span>
                                </div>
                                <div class="info-row">
                                    <span class="info-label"><i class="fas fa-tools"></i> 處理單位</span>
                                    <span class="info-value text-success font-weight-bold">{{ caseData.G_ComName || '尚未指定' }}</span>
                                </div>
                                <div class="info-row">
                                    <span class="info-label"><i class="fas fa-map-marker-alt"></i> 通報坐標 1</span>
                                    <span class="info-value font-monospace">
                                        {{ caseData.S_UTME ? Math.round(caseData.S_UTME) : '—' }}, {{ caseData.S_UTMN ? Math.round(caseData.S_UTMN) : '—' }}
                                    </span>
                                </div>
                                <div v-if="caseData.S_UTME1 > 0" class="info-row">
                                    <span class="info-label"><i class="fas fa-map-marker-alt"></i> 通報坐標 2</span>
                                    <span class="info-value font-monospace">
                                        {{ Math.round(caseData.S_UTME1) }}, {{ Math.round(caseData.S_UTMN1) }}
                                    </span>
                                </div>
                                <div v-if="caseData.Comm" class="mt-3 pt-2 border-top">
                                    <small class="text-muted font-weight-bold d-block mb-1">
                                        <i class="fas fa-comment-dots"></i> 通報補充說明：
                                    </small>
                                    <div class="p-2 bg-light rounded text-dark" style="font-size: 0.9rem; line-height: 1.5;">
                                        {{ caseData.Comm }}
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- 現場地理位置地圖 (Leaflet 1.9.4) -->
                        <div class="card-modern">
                            <div class="card-modern-header">
                                <h3 class="card-modern-title">
                                    <i class="fas fa-map-marked-alt text-success"></i> 現場位置地圖
                                </h3>
                                <div class="btn-group btn-group-sm">
                                    <button type="button" class="btn btn-outline-primary" v-on:click="locateUser" title="GPS 定位我目前位置">
                                        <i class="fas fa-crosshairs"></i> GPS
                                    </button>
                                    <button type="button" class="btn btn-outline-secondary" v-on:click="resetMapView" title="重設地圖全景檢視">
                                        <i class="fas fa-compress-arrows-alt"></i> 全景
                                    </button>
                                    <button type="button" class="btn btn-outline-secondary" v-on:click="toggleMapCollapse" :title="isMapCollapsed ? '展開地圖' : '收合地圖'">
                                        <i :class="isMapCollapsed ? 'fas fa-chevron-down' : 'fas fa-chevron-up'"></i>
                                    </button>
                                </div>
                            </div>
                            <div class="card-modern-body p-2">
                                <div id="map" :class="{ 'map-collapsed': isMapCollapsed }"></div>
                                <div class="d-flex justify-content-between align-items-center mt-2 px-1" style="font-size: 0.8rem; color: #64748b;">
                                    <span>
                                        <i class="fas fa-map-pin text-danger mr-1"></i> 髒污通報起點
                                        <span v-if="caseData.Lat2 > 0" class="ml-2">
                                            <i class="fas fa-map-pin text-primary mr-1"></i> 污染迄點
                                        </span>
                                    </span>
                                    <span>經緯度 WGS84 座標轉換</span>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- ==================== 右欄：改善回報主作業區 (60%) ==================== -->
                <div class="col-12 col-xl-7">
                    <!-- 退回通報開關 (僅在未結案時可切換) -->
                    <div v-if="!caseData.IsReadOnly" class="back-toggle-card" :class="{ 'active-back': form.IsBack }">
                        <div class="custom-control custom-switch">
                            <input type="checkbox" class="custom-control-input" id="switchBack" v-model="form.IsBack" />
                            <label class="custom-control-label font-weight-bold" for="switchBack" :class="form.IsBack ? 'text-danger' : 'text-dark'">
                                <i :class="form.IsBack ? 'fas fa-undo-alt mr-1 text-danger' : 'fas fa-exclamation-circle mr-1 text-warning'"></i>
                                非本單位權責案件，申請退回通報
                            </label>
                        </div>
                        <div v-if="form.IsBack" class="mt-2 pt-2 border-top border-danger" style="font-size: 0.88rem; color: #b91c1c;">
                            <i class="fas fa-info-circle mr-1"></i>
                            勾選退回後，本案件將轉回通報單位重新確認並分派權責單位。請務必於下方「處理單位備註」詳述退回原因。
                        </div>
                    </div>

                    <!-- 處理單位改善說明備註卡片 -->
                    <div class="card-modern">
                        <div class="card-modern-header">
                            <h3 class="card-modern-title">
                                <i class="fas fa-edit text-primary"></i>
                                <span>{{ form.IsBack ? '退回原因說明' : '改善措施說明 (處理單位備註)' }}</span>
                            </h3>
                            <span v-if="!caseData.IsReadOnly" class="badge badge-light text-muted">
                                {{ form.G_Memo.length }} 字
                            </span>
                        </div>
                        <div class="card-modern-body">
                            <div v-if="caseData.IsReadOnly">
                                <div class="p-3 bg-light rounded text-dark font-weight-bold" style="min-height: 60px; line-height: 1.6;">
                                    {{ caseData.G_Memo || '無處理備註' }}
                                </div>
                            </div>
                            <div v-else>
                                <textarea class="form-control" rows="3" v-model="form.G_Memo" 
                                          :placeholder="form.IsBack ? '請詳細說明非本單位權責之原因 (例如：該路段屬公路總局管轄、非本區隊責任範疇等)...' : '請說明現場改善作業內容 (例如：已調派洗掃街車沖洗完成、砂石已清理完畢等)...'"></textarea>
                                
                                <!-- 快捷常用片語 -->
                                <div class="phrase-chips-container">
                                    <span class="phrase-chip" v-for="p in (form.IsBack ? backPhrases : improvePhrases)" :key="p" v-on:click="appendPhrase(p)">
                                        <i class="fas fa-plus-circle text-primary mr-1"></i> {{ p }}
                                    </span>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- 疑似髒污點現場照片 vs 改善後成果對照卡片 -->
                    <div class="card-modern">
                        <div class="card-modern-header">
                            <h3 class="card-modern-title">
                                <i class="fas fa-images text-primary"></i>
                                <span>疑似髒污點現場照片 vs 改善後照片對照</span>
                            </h3>
                            <span class="badge badge-pill badge-primary font-weight-bold">
                                共 {{ form.PhotoPairs.length }} 組對照
                            </span>
                        </div>
                        <div class="card-modern-body p-3">
                            <div v-if="form.PhotoPairs.length === 0" class="text-center py-4 text-muted">
                                <i class="fas fa-camera fa-2x mb-2 d-block"></i>
                                <span>查核稽查時未上傳疑似髒污點照片</span>
                            </div>

                            <!-- 逐筆對照區塊 -->
                            <div v-for="(pair, idx) in form.PhotoPairs" :key="idx" class="comparison-card">
                                <div class="comparison-header">
                                    <span>
                                        <i class="fas fa-layer-group text-primary mr-1"></i>
                                        <span>髒污點檢核項目 #{{ pair.Index }}</span>
                                    </span>
                                    <span v-if="pair.After && pair.After.Url" class="badge badge-success font-weight-bold">
                                        <i class="fas fa-check mr-1"></i> 已回報改善照
                                    </span>
                                    <span v-else class="badge badge-warning text-dark font-weight-bold">
                                        <i class="fas fa-clock mr-1"></i> 待拍攝改善照
                                    </span>
                                </div>
                                <div class="comparison-body">
                                    <!-- 左：改善前 (稽查通報照) -->
                                    <div class="photo-before-panel">
                                        <div class="photo-panel-title">
                                            <span><i class="fas fa-history text-danger mr-1"></i> 改善前 (通報照片)</span>
                                            <span v-if="pair.Before" class="badge badge-light">{{ pair.Before.FileName }}</span>
                                        </div>
                                        <div class="photo-img-box">
                                            <template v-if="pair.Before && pair.Before.Url">
                                                <img :src="pair.Before.Url" alt="改善前現場照片" v-on:click="openLightbox(pair.Before.Url, '改善前現場照片 #' + pair.Index)" />
                                            </template>
                                            <template v-else>
                                                <span class="text-muted font-weight-bold">未檢附通報照片</span>
                                            </template>
                                        </div>
                                        <div v-if="pair.Before && pair.Before.Url" class="mt-2 text-right">
                                            <button type="button" class="btn btn-sm btn-outline-secondary" v-on:click="openLightbox(pair.Before.Url, '改善前現場照片 #' + pair.Index)">
                                                <i class="fas fa-search-plus mr-1"></i> 放大檢視
                                            </button>
                                        </div>
                                    </div>

                                    <!-- 右：改善後 (現場成果照) -->
                                    <div class="photo-after-panel">
                                        <div class="photo-panel-title">
                                            <span><i class="fas fa-check-circle text-success mr-1"></i> 改善後 (成果照片)</span>
                                            <span v-if="pair.After && pair.After.FileName" class="badge badge-light">{{ pair.After.FileName }}</span>
                                        </div>

                                        <!-- 已有改善後照片展示 -->
                                        <template v-if="pair.After && pair.After.Url">
                                            <div class="photo-img-box">
                                                <img :src="pair.After.Url" alt="改善後成果照片" v-on:click="openLightbox(pair.After.Url, '改善後成果照片 #' + pair.Index)" />
                                            </div>
                                            <div v-if="!caseData.IsReadOnly" class="mt-2 d-flex justify-content-between align-items-center">
                                                <button type="button" class="btn btn-sm btn-outline-danger" v-on:click="removePairAfterPhoto(pair)">
                                                    <i class="fas fa-trash-alt mr-1"></i> 刪除照片
                                                </button>
                                                <label class="btn btn-sm btn-outline-primary mb-0">
                                                    <i class="fas fa-camera mr-1"></i> 重拍/更換
                                                    <input type="file" accept="image/*" capture="environment" style="display: none;" v-on:change="onFileChange($event, pair, 'improve')" />
                                                </label>
                                            </div>
                                            <div v-else class="mt-2 text-right">
                                                <button type="button" class="btn btn-sm btn-outline-secondary" v-on:click="openLightbox(pair.After.Url, '改善後成果照片 #' + pair.Index)">
                                                    <i class="fas fa-search-plus mr-1"></i> 放大檢視
                                                </button>
                                            </div>
                                        </template>

                                        <!-- 尚未上傳改善照片之拍照/選取熱區 (唯讀模式下顯示未上傳) -->
                                        <template v-else>
                                            <div v-if="!caseData.IsReadOnly">
                                                <label class="upload-dropzone w-100 mb-0">
                                                    <i class="fas fa-camera"></i>
                                                    <p class="upload-hint">點擊拍照或選取改善照片</p>
                                                    <span class="upload-sub">支援手機拍照與相簿選取 (自動壓縮)</span>
                                                    <input type="file" accept="image/*" capture="environment" style="display: none;" v-on:change="onFileChange($event, pair, 'improve')" />
                                                </label>
                                            </div>
                                            <div v-else class="photo-img-box">
                                                <span class="text-muted">處理單位未上傳改善照片</span>
                                            </div>
                                        </template>
                                    </div>
                                </div>
                            </div>

                            <!-- 補充上傳更多改善照片按鈕 -->
                            <div v-if="!caseData.IsReadOnly" class="text-center mt-3">
                                <button type="button" class="btn btn-outline-primary font-weight-bold" v-on:click="addNewImprovePair">
                                    <i class="fas fa-plus-circle mr-1"></i> ＋ 新增補充改善後現場照片
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- 佐證照片改善對照卡片 (若案件有佐證照片或使用者主動新增時顯示) -->
                    <div v-if="form.EvidencePairs.length > 0" class="card-modern">
                        <div class="card-modern-header">
                            <h3 class="card-modern-title">
                                <i class="fas fa-photo-video text-info"></i>
                                <span>佐證照片改善對照</span>
                            </h3>
                            <span class="badge badge-pill badge-info font-weight-bold">
                                共 {{ form.EvidencePairs.length }} 組佐證
                            </span>
                        </div>
                        <div class="card-modern-body p-3">
                            <div v-for="(pair, idx) in form.EvidencePairs" :key="idx" class="comparison-card">
                                <div class="comparison-header">
                                    <span>
                                        <i class="fas fa-paperclip text-info mr-1"></i>
                                        <span>佐證檢核項目 #{{ pair.Index }}</span>
                                    </span>
                                    <span v-if="pair.After && pair.After.Url" class="badge badge-success font-weight-bold">
                                        <i class="fas fa-check mr-1"></i> 已回報佐證照
                                    </span>
                                    <span v-else class="badge badge-secondary font-weight-bold">
                                        可選填佐證
                                    </span>
                                </div>
                                <div class="comparison-body">
                                    <!-- 改善前佐證照 -->
                                    <div class="photo-before-panel">
                                        <div class="photo-panel-title">
                                            <span><i class="fas fa-file-image text-muted mr-1"></i> 改善前 (佐證照片)</span>
                                            <span v-if="pair.Before" class="badge badge-light">{{ pair.Before.FileName }}</span>
                                        </div>
                                        <div class="photo-img-box">
                                            <template v-if="pair.Before && pair.Before.Url">
                                                <img :src="pair.Before.Url" alt="改善前佐證照片" v-on:click="openLightbox(pair.Before.Url, '改善前佐證照片 #' + pair.Index)" />
                                            </template>
                                            <template v-else>
                                                <span class="text-muted">未檢附原始佐證</span>
                                            </template>
                                        </div>
                                        <div v-if="pair.Before && pair.Before.Url" class="mt-2 text-right">
                                            <button type="button" class="btn btn-sm btn-outline-secondary" v-on:click="openLightbox(pair.Before.Url, '改善前佐證照片 #' + pair.Index)">
                                                <i class="fas fa-search-plus mr-1"></i> 放大檢視
                                            </button>
                                        </div>
                                    </div>

                                    <!-- 改善後佐證照 -->
                                    <div class="photo-after-panel">
                                        <div class="photo-panel-title">
                                            <span><i class="fas fa-check text-success mr-1"></i> 改善後 (佐證照片)</span>
                                            <span v-if="pair.After && pair.After.FileName" class="badge badge-light">{{ pair.After.FileName }}</span>
                                        </div>
                                        <template v-if="pair.After && pair.After.Url">
                                            <div class="photo-img-box">
                                                <img :src="pair.After.Url" alt="改善後佐證照片" v-on:click="openLightbox(pair.After.Url, '改善後佐證照片 #' + pair.Index)" />
                                            </div>
                                            <div v-if="!caseData.IsReadOnly" class="mt-2 d-flex justify-content-between align-items-center">
                                                <button type="button" class="btn btn-sm btn-outline-danger" v-on:click="removePairAfterPhoto(pair)">
                                                    <i class="fas fa-trash-alt mr-1"></i> 刪除
                                                </button>
                                                <label class="btn btn-sm btn-outline-info mb-0">
                                                    <i class="fas fa-camera mr-1"></i> 重拍/更換
                                                    <input type="file" accept="image/*" capture="environment" style="display: none;" v-on:change="onFileChange($event, pair, 'evidence')" />
                                                </label>
                                            </div>
                                            <div v-else class="mt-2 text-right">
                                                <button type="button" class="btn btn-sm btn-outline-secondary" v-on:click="openLightbox(pair.After.Url, '改善後佐證照片 #' + pair.Index)">
                                                    <i class="fas fa-search-plus mr-1"></i> 放大檢視
                                                </button>
                                            </div>
                                        </template>
                                        <template v-else>
                                            <div v-if="!caseData.IsReadOnly">
                                                <label class="upload-dropzone w-100 mb-0">
                                                    <i class="fas fa-camera text-info"></i>
                                                    <p class="upload-hint text-info">上傳改善後佐證照片</p>
                                                    <span class="upload-sub">點擊拍照或從相簿選擇</span>
                                                    <input type="file" accept="image/*" capture="environment" style="display: none;" v-on:change="onFileChange($event, pair, 'evidence')" />
                                                </label>
                                            </div>
                                            <div v-else class="photo-img-box">
                                                <span class="text-muted">未上傳改善佐證</span>
                                            </div>
                                        </template>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- 桌面端下方操作動作按鈕區 (在大螢幕顯示) -->
                    <div class="card-modern d-none d-lg-block">
                        <div class="card-modern-body d-flex justify-content-between align-items-center">
                            <a href="Dirty_List.aspx?mode=DirtyImprove" class="btn btn-secondary font-weight-bold px-4">
                                <i class="fas fa-arrow-left mr-1"></i> 返回改善清單
                            </a>
                            <div v-if="!caseData.IsReadOnly" class="d-flex gap-2">
                                <button type="button" class="btn btn-outline-primary font-weight-bold px-3" v-on:click="saveDraft">
                                    <i class="fas fa-save mr-1"></i> 儲存草稿
                                </button>
                                <button type="button" class="btn font-weight-bold px-5 shadow-sm text-white" 
                                        :class="form.IsBack ? 'btn-danger' : 'btn-success'"
                                        v-on:click="openSubmitConfirmModal">
                                    <i :class="form.IsBack ? 'fas fa-undo mr-1' : 'fas fa-paper-plane mr-1'"></i>
                                    {{ form.IsBack ? '確定退回通報' : '送出改善回報' }}
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </main>

        <!-- 手機端常駐浮動動作列 (Sticky Bottom Bar) -->
        <nav class="mobile-bottom-bar d-lg-none">
            <a href="Dirty_List.aspx?mode=DirtyImprove" class="btn btn-secondary">
                <i class="fas fa-arrow-left mr-1"></i> 返回清單
            </a>
            <button v-if="!caseData.IsReadOnly" type="button" class="btn text-white shadow-sm" 
                    :class="form.IsBack ? 'btn-danger' : 'btn-success'"
                    v-on:click="openSubmitConfirmModal">
                <i :class="form.IsBack ? 'fas fa-undo mr-1' : 'fas fa-paper-plane mr-1'"></i>
                {{ form.IsBack ? '確定退回通報' : '送出改善回報' }}
            </button>
        </nav>

        <!-- ==================== 燈箱照片放大檢視 (Lightbox) ==================== -->
        <div v-if="lightbox.show" class="lightbox-modal" v-on:click.self="closeLightbox">
            <img :src="lightbox.url" class="lightbox-img" :style="{ transform: 'rotate(' + lightbox.rotate + 'deg)' }" />
            <div class="text-white font-weight-bold mt-2">{{ lightbox.title }}</div>
            <div class="lightbox-controls">
                <button type="button" class="btn btn-light btn-sm" v-on:click="rotateLightbox">
                    <i class="fas fa-redo mr-1"></i> 旋轉 90°
                </button>
                <a :href="lightbox.url" target="_blank" download class="btn btn-light btn-sm">
                    <i class="fas fa-download mr-1"></i> 下載原圖
                </a>
                <button type="button" class="btn btn-danger btn-sm" v-on:click="closeLightbox">
                    <i class="fas fa-times mr-1"></i> 關閉預覽
                </button>
            </div>
        </div>

        <!-- ==================== 二次送出確認 Modal ==================== -->
        <div class="modal fade" id="confirmModal" tabindex="-1" role="dialog" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered" role="document">
                <div class="modal-content">
                    <div class="modal-header" :class="form.IsBack ? 'bg-danger text-white' : 'bg-primary text-white'">
                        <h5 class="modal-title font-weight-bold">
                            <i :class="form.IsBack ? 'fas fa-exclamation-triangle mr-2' : 'fas fa-clipboard-check mr-2'"></i>
                            {{ form.IsBack ? '確認退回案件通報' : '確認送出道路改善成果' }}
                        </h5>
                        <button type="button" class="close text-white" data-dismiss="modal" aria-label="Close">
                            <span aria-hidden="true">&times;</span>
                        </button>
                    </div>
                    <div class="modal-body">
                        <p class="mb-2">您即將送出案件【<strong>{{ caseData.ShowId }}</strong>】的{{ form.IsBack ? '退回' : '改善回報' }}資料：</p>
                        <ul class="list-group mb-3">
                            <li class="list-group-item d-flex justify-content-between align-items-center py-2">
                                <span>作業類型</span>
                                <span class="font-weight-bold" :class="form.IsBack ? 'text-danger' : 'text-success'">
                                    {{ form.IsBack ? '非權責退回通報' : '改善完成回報' }}
                                </span>
                            </li>
                            <li class="list-group-item d-flex justify-content-between align-items-center py-2">
                                <span>改善照片數量</span>
                                <span class="badge badge-pill badge-primary">{{ countUploadedPhotos() }} 張</span>
                            </li>
                            <li class="list-group-item py-2">
                                <div><small class="text-muted font-weight-bold">處理備註內容：</small></div>
                                <div class="p-2 bg-light rounded text-dark font-weight-bold mt-1" style="font-size: 0.9rem;">
                                    {{ form.G_Memo || '(未填寫備註)' }}
                                </div>
                            </li>
                        </ul>
                        <div class="alert" :class="form.IsBack ? 'alert-danger' : 'alert-info'" style="font-size: 0.88rem;">
                            <i class="fas fa-info-circle mr-1"></i>
                            {{ form.IsBack ? '退回後將發送通知信給通報單位承辦人重新派工，請再次確認。' : '送出後案件狀態將更新為「已改善完成」並通知通報單位，送出後將無法隨意刪改。' }}
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-dismiss="modal">取消返回</button>
                        <button type="button" class="btn font-weight-bold px-4 text-white" 
                                :class="form.IsBack ? 'btn-danger' : 'btn-success'"
                                v-on:click="executeSubmit">
                            <i class="fas fa-check mr-1"></i> 確認無誤送出
                        </button>
                    </div>
                </div>
            </div>
        </div>

        <!-- 儲存中遮罩 -->
        <div v-if="isSubmitting" class="loading-overlay">
            <div class="spinner-border text-primary" style="width: 3.5rem; height: 3.5rem;" role="status"></div>
            <h5 class="mt-3 font-weight-bold text-dark">正在儲存改善成果並發送通知信，請稍候...</h5>
        </div>
    </div>

    <!-- 本地腳本依賴 -->
    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>
    <script src="../Scripts/bootstrap.bundle.min.js"></script>
    <script src="../Scripts/leaflet/leaflet.js"></script>

    <script>
        const { createApp, markRaw } = Vue;

        createApp({
            data() {
                return {
                    isLoading: true,
                    isSubmitting: false,
                    loadError: '',
                    isMapCollapsed: false,
                    caseData: {
                        DirtyId: '',
                        ShowId: '',
                        ReportDate: '',
                        ReportUserName: '',
                        S_ComName: '',
                        SetComDate: '',
                        S_UserName: '',
                        G_ComName: '',
                        KindName: '',
                        Comm: '',
                        StatusCode: 1,
                        StatusText: '',
                        StatusBadgeClass: 'badge-secondary',
                        IsReadOnly: false,
                        CurrentUserName: '',
                        S_UTME: 0,
                        S_UTMN: 0,
                        Lat1: 0,
                        Lon1: 0,
                        S_UTME1: 0,
                        S_UTMN1: 0,
                        Lat2: 0,
                        Lon2: 0
                    },
                    form: {
                        IsBack: false,
                        G_Memo: '',
                        PhotoPairs: [],
                        EvidencePairs: []
                    },
                    improvePhrases: [
                        '已調派高壓沖洗車完成路面沖洗作業',
                        '現場砂石雜物已全數清除完畢，恢復路面整潔',
                        '已派工灑水並清理現場，抑制揚塵逸散',
                        '經派員現場勘查，已無道路污染情事'
                    ],
                    backPhrases: [
                        '該路段非本區隊責任管轄範疇，請轉派公路總局辦理',
                        '經查污染源屬營建工程私有地範圍，非公有道路',
                        '現場地址有誤，查無此路段污染，請重新查核確認'
                    ],
                    lightbox: {
                        show: false,
                        url: '',
                        title: '',
                        rotate: 0
                    }
                };
            },
            created() {
                this.leafletMap = null;
                this.marker1 = null;
                this.marker2 = null;
                this.linePath = null;
            },
            mounted() {
                this.fetchData();
            },
            methods: {
                getUrlParam(param) {
                    const params = new URLSearchParams(window.location.search);
                    return params.get(param);
                },
                fetchData() {
                    const id = this.getUrlParam('id');
                    const mode = this.getUrlParam('mode') || 'edit';

                    if (!id) {
                        this.isLoading = false;
                        this.loadError = '網址參數缺少通報案號 (id)';
                        return;
                    }

                    this.isLoading = true;
                    this.loadError = '';

                    axios.get('ImproveDirty.aspx?action=init&id=' + encodeURIComponent(id) + '&mode=' + encodeURIComponent(mode))
                        .then(res => {
                            this.isLoading = false;
                            if (res.data && res.data.Success) {
                                const data = res.data.Data;
                                this.caseData = data;
                                this.form.G_Memo = data.G_Memo || '';
                                this.form.IsBack = !!data.IsBack;

                                // 初始化照片對照組合
                                this.form.PhotoPairs = (data.PhotoPairs || []).map(p => ({
                                    Index: p.Index,
                                    TargetTitle: p.TargetTitle,
                                    Before: p.Before,
                                    After: p.After,
                                    NewBase64: '',
                                    IsDeleted: false
                                }));

                                this.form.EvidencePairs = (data.EvidencePairs || []).map(p => ({
                                    Index: p.Index,
                                    TargetTitle: p.TargetTitle,
                                    Before: p.Before,
                                    After: p.After,
                                    NewBase64: '',
                                    IsDeleted: false
                                }));

                                // 若無任何髒污點對照，預設給予 1 組空槽
                                if (this.form.PhotoPairs.length === 0 && !this.caseData.IsReadOnly) {
                                    this.addNewImprovePair();
                                }

                                this.$nextTick(() => {
                                    this.initMap();
                                });
                            } else {
                                this.loadError = (res.data && res.data.Message) || '載入案件失敗';
                            }
                        })
                        .catch(err => {
                            this.isLoading = false;
                            this.loadError = '網路連線異常：' + (err.message || err);
                        });
                },

                // 初始化 Leaflet 地圖 (依據 inspection-ui-standard 隔離響應式)
                initMap() {
                    const mapEl = document.getElementById('map');
                    if (!mapEl) return;

                    let centerLat = this.caseData.Lat1;
                    let centerLon = this.caseData.Lon1;

                    // 若無有效座標，預設新北市府
                    if (!centerLat || centerLat <= 0 || !centerLon || centerLon <= 0) {
                        centerLat = 25.0123;
                        centerLon = 121.4657;
                    }

                    if (!this.leafletMap) {
                        const lMap = L.map('map', {
                            center: [centerLat, centerLon],
                            zoom: 16,
                            zoomControl: true
                        });

                        L.tileLayer('https://wmts.nlsc.gov.tw/wmts/EMAP/default/GoogleMapsCompatible/{z}/{y}/{x}', {
                            maxZoom: 19,
                            attribution: '&copy; 國土測繪圖資'
                        }).addTo(lMap);

                        this.leafletMap = markRaw(lMap);
                    } else {
                        this.leafletMap.setView([centerLat, centerLon], 16);
                        this.leafletMap.invalidateSize();
                    }

                    // 繪製通報點 1 Marker
                    if (this.caseData.Lat1 > 0 && this.caseData.Lon1 > 0) {
                        const icon1 = L.divIcon({
                            className: 'custom-map-marker',
                            html: '<div class="marker-pin-dirty"><i class="fas fa-exclamation-triangle marker-icon-inner"></i></div>',
                            iconSize: [32, 32],
                            iconAnchor: [16, 32]
                        });

                        if (this.marker1) this.marker1.remove();
                        this.marker1 = markRaw(
                            L.marker([this.caseData.Lat1, this.caseData.Lon1], { icon: icon1 })
                             .addTo(this.leafletMap)
                             .bindPopup('<b>通報起點/污染點</b><br>案號：' + this.caseData.ShowId)
                        );
                    }

                    // 繪製通報點 2 Marker (若有)
                    if (this.caseData.Lat2 > 0 && this.caseData.Lon2 > 0) {
                        const icon2 = L.divIcon({
                            className: 'custom-map-marker',
                            html: '<div class="marker-pin-sub"><i class="fas fa-flag-checkered marker-icon-inner"></i></div>',
                            iconSize: [30, 30],
                            iconAnchor: [15, 30]
                        });

                        if (this.marker2) this.marker2.remove();
                        this.marker2 = markRaw(
                            L.marker([this.caseData.Lat2, this.caseData.Lon2], { icon: icon2 })
                             .addTo(this.leafletMap)
                             .bindPopup('<b>通報迄點</b>')
                        );

                        // 繪製連線
                        if (this.linePath) this.linePath.remove();
                        this.linePath = markRaw(
                            L.polyline([
                                [this.caseData.Lat1, this.caseData.Lon1],
                                [this.caseData.Lat2, this.caseData.Lon2]
                            ], { color: '#0284c7', weight: 4, dashArray: '6, 6' }).addTo(this.leafletMap)
                        );

                        // 自動包含兩點縮放
                        const group = L.featureGroup([this.marker1, this.marker2]);
                        this.leafletMap.fitBounds(group.getBounds().pad(0.3));
                    }
                },

                resetMapView() {
                    if (!this.leafletMap) return;
                    if (this.marker1 && this.marker2) {
                        const group = L.featureGroup([this.marker1, this.marker2]);
                        this.leafletMap.fitBounds(group.getBounds().pad(0.3));
                    } else if (this.marker1) {
                        this.leafletMap.setView(this.marker1.getLatLng(), 16);
                    }
                },

                locateUser() {
                    if (!navigator.geolocation) {
                        alert('您的瀏覽器不支援 GPS 定位功能');
                        return;
                    }
                    navigator.geolocation.getCurrentPosition(pos => {
                        const lat = pos.coords.latitude;
                        const lon = pos.coords.longitude;
                        if (this.leafletMap) {
                            this.leafletMap.setView([lat, lon], 17);
                            L.circleMarker([lat, lon], {
                                radius: 8,
                                fillColor: '#3b82f6',
                                color: '#ffffff',
                                weight: 2,
                                fillOpacity: 0.9
                            }).addTo(this.leafletMap).bindPopup('<b>目前您的 GPS 位置</b>').openPopup();
                        }
                    }, err => {
                        alert('無法取得您的位置：' + err.message);
                    }, { enableHighAccuracy: true, timeout: 10000 });
                },

                toggleMapCollapse() {
                    this.isMapCollapsed = !this.isMapCollapsed;
                    setTimeout(() => {
                        if (this.leafletMap) this.leafletMap.invalidateSize();
                    }, 350);
                },

                copyShowId() {
                    if (!this.caseData.ShowId) return;
                    navigator.clipboard.writeText(this.caseData.ShowId)
                        .then(() => alert('通報案號已複製到剪貼簿：' + this.caseData.ShowId))
                        .catch(() => alert('案號為：' + this.caseData.ShowId));
                },

                appendPhrase(text) {
                    if (!this.form.G_Memo) {
                        this.form.G_Memo = text;
                    } else {
                        if (this.form.G_Memo.endsWith('。') || this.form.G_Memo.endsWith('\n')) {
                            this.form.G_Memo += text;
                        } else {
                            this.form.G_Memo += '，' + text;
                        }
                    }
                },

                addNewImprovePair() {
                    const newIdx = this.form.PhotoPairs.length + 1;
                    this.form.PhotoPairs.push({
                        Index: newIdx,
                        TargetTitle: '髒污點改善後照片_' + newIdx,
                        Before: null,
                        After: null,
                        NewBase64: '',
                        IsDeleted: false
                    });
                },

                // 照片選取與壓縮
                onFileChange(event, pair, type) {
                    const files = event.target.files;
                    if (!files || files.length === 0) return;
                    const file = files[0];

                    this.compressImage(file, 1600, 0.82, (base64) => {
                        const previewUrl = base64;
                        const fileName = (pair.TargetTitle || ('改善照片_' + pair.Index)) + '.jpg';
                        
                        pair.After = {
                            FileName: fileName,
                            Url: previewUrl,
                            Title: pair.TargetTitle
                        };
                        pair.NewBase64 = base64;
                        pair.IsDeleted = false;
                    });

                    event.target.value = '';
                },

                // 前端 Canvas 照片等比例壓縮
                compressImage(file, maxDimension, quality, callback) {
                    const reader = new FileReader();
                    reader.onload = e => {
                        const img = new Image();
                        img.onload = () => {
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

                            const canvas = document.createElement('canvas');
                            canvas.width = width;
                            canvas.height = height;
                            const ctx = canvas.getContext('2d');
                            ctx.drawImage(img, 0, 0, width, height);

                            const compressedBase64 = canvas.toDataURL('image/jpeg', quality);
                            callback(compressedBase64);
                        };
                        img.src = e.target.result;
                    };
                    reader.readAsDataURL(file);
                },

                removePairAfterPhoto(pair) {
                    if (!confirm('是否確定移除此張改善照片？')) return;
                    pair.After = null;
                    pair.NewBase64 = '';
                    pair.IsDeleted = true;
                },

                countUploadedPhotos() {
                    let c = 0;
                    this.form.PhotoPairs.forEach(p => {
                        if (p.After && p.After.Url && !p.IsDeleted) c++;
                    });
                    this.form.EvidencePairs.forEach(p => {
                        if (p.After && p.After.Url && !p.IsDeleted) c++;
                    });
                    return c;
                },

                openSubmitConfirmModal() {
                    // 防呆驗證
                    if (this.form.IsBack) {
                        if (!this.form.G_Memo || this.form.G_Memo.trim().length === 0) {
                            alert('請填寫退回原因說明 (處理單位備註)，以利通報單位重新派工處理！');
                            return;
                        }
                    } else {
                        const photoCount = this.countUploadedPhotos();
                        if (photoCount === 0) {
                            if (!confirm('提醒：您尚未上傳任何「改善後成果照片」。是否確定直接送出回報？')) {
                                return;
                            }
                        }
                    }

                    // 呼叫 Bootstrap Modal
                    $('#confirmModal').modal('show');
                },

                saveDraft() {
                    alert('草稿資料已暫存於瀏覽器頁面中。若確認完成請點選「送出改善回報」進行正式儲存！');
                },

                executeSubmit() {
                    $('#confirmModal').modal('hide');
                    this.isSubmitting = true;

                    // 整理改善照片 DTO
                    const improvePhotos = this.form.PhotoPairs.map(p => ({
                        TargetTitle: p.TargetTitle,
                        FileName: p.After ? p.After.FileName : '',
                        Base64Data: p.NewBase64 || '',
                        IsDeleted: !!p.IsDeleted
                    }));

                    const evidencePhotos = this.form.EvidencePairs.map(p => ({
                        TargetTitle: p.TargetTitle,
                        FileName: p.After ? p.After.FileName : '',
                        Base64Data: p.NewBase64 || '',
                        IsDeleted: !!p.IsDeleted
                    }));

                    const payload = {
                        DirtyId: this.caseData.DirtyId,
                        G_Memo: this.form.G_Memo,
                        IsBack: !!this.form.IsBack,
                        ImprovePhotos: improvePhotos,
                        EvidencePhotos: evidencePhotos
                    };

                    axios.post('ImproveDirty.aspx?action=save', payload)
                        .then(res => {
                            this.isSubmitting = false;
                            if (res.data && res.data.Success) {
                                alert(res.data.Message || '改善回報送出成功！');
                                window.location.href = res.data.RedirectUrl || 'Dirty_List.aspx?mode=DirtyImprove';
                            } else {
                                alert('儲存失敗：' + ((res.data && res.data.Message) || '伺服器發生未預期錯誤'));
                            }
                        })
                        .catch(err => {
                            this.isSubmitting = false;
                            alert('網路連線失敗：' + (err.message || err));
                        });
                },

                // 燈箱控制
                openLightbox(url, title) {
                    this.lightbox.url = url;
                    this.lightbox.title = title || '';
                    this.lightbox.rotate = 0;
                    this.lightbox.show = true;
                },
                closeLightbox() {
                    this.lightbox.show = false;
                },
                rotateLightbox() {
                    this.lightbox.rotate = (this.lightbox.rotate + 90) % 360;
                }
            }
        }).mount('#app');
    </script>
</body>
</html>