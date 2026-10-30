<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="SetSG_Break.aspx.cs" Inherits="NTPC_FEC.RoadBreak.SetSG_Break" %>
<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定逸散源管理平台 - 道路髒污破損派工通報</title>
    
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
            background: linear-gradient(135deg, #0b1f7d 0%, #0284c7 100%);
            color: #ffffff;
            height: 56px;
            display: flex; align-items: center; justify-content: space-between;
            padding: 0 16px;
            box-shadow: 0 2px 10px rgba(11, 31, 125, 0.25);
            position: sticky; top: 0; z-index: 1020;
        }
        .nav-btn {
            background: rgba(255, 255, 255, 0.18);
            border: 1px solid rgba(255, 255, 255, 0.25);
            color: #ffffff !important;
            font-size: 0.9rem;
            font-weight: 600;
            cursor: pointer;
            height: 36px;
            min-width: 36px;
            border-radius: 8px;
            display: inline-flex; align-items: center; justify-content: center; gap: 6px;
            padding: 0 12px;
            text-decoration: none !important;
            transition: all 0.2s ease;
        }
        .nav-btn:hover {
            background: rgba(255, 255, 255, 0.3);
            transform: translateY(-1px);
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
        .card-modern-body {
            padding: 16px;
        }

        /* 規格晶片 */
        .stat-chip {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 10px 12px;
            margin-bottom: 10px;
        }
        .stat-chip-label {
            font-size: 0.8rem;
            color: var(--text-muted);
            margin-bottom: 2px;
        }
        .stat-chip-val {
            font-size: 0.95rem;
            font-weight: 600;
            color: var(--brand-navy);
            word-break: break-all;
        }

        /* 地圖容器 */
        #mapContainer {
            width: 100%;
            height: 240px;
            border-radius: 8px;
            z-index: 1;
        }

        /* 照片縮圖卡 */
        .photo-thumb-card {
            border: 1px solid var(--border-color);
            border-radius: 8px;
            overflow: hidden;
            background: #fafafa;
            cursor: pointer;
            transition: transform 0.2s;
        }
        .photo-thumb-card:hover {
            transform: scale(1.02);
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
        }
        .photo-img {
            width: 100%;
            height: 120px;
            object-fit: cover;
            display: block;
        }
        .photo-cap {
            font-size: 0.78rem;
            padding: 4px 6px;
            text-align: center;
            background: #ffffff;
            color: #334155;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        /* 承辦人表格 */
        .user-table td, .user-table th {
            vertical-align: middle;
            font-size: 0.88rem;
            padding: 8px;
        }

        /* 燈箱 */
        .modal-lightbox {
            position: fixed;
            top: 0; left: 0; width: 100%; height: 100%;
            background: rgba(0, 0, 0, 0.85);
            display: flex; align-items: center; justify-content: center;
            z-index: 9999;
            padding: 20px;
        }
        .modal-lightbox img {
            max-width: 90%;
            max-height: 85vh;
            border-radius: 6px;
            box-shadow: 0 5px 25px rgba(0,0,0,0.5);
        }

        @media (max-width: 767.98px) {
            #mapContainer { height: 180px; }
            .card-modern-body { padding: 12px; }
        }
    </style>
</head>
<body>
    <div id="setSGApp" v-cloak>
        <!-- 頂部導覽列 -->
        <header class="top-navbar">
            <div class="d-flex align-items-center">
                <a :href="'BreakDetail.aspx?id=' + encodeURIComponent(breakId)" class="nav-btn mr-2" title="返回案件明細">
                    <i class="fas fa-arrow-left"></i>
                    <span class="d-none d-sm-inline">返回明細</span>
                </a>
                <h1 class="h6 mb-0 font-weight-bold">
                    <i class="fas fa-paper-plane mr-1 text-warning"></i> 道路髒污破損 - 派工通報
                </h1>
            </div>
            <div>
                <span class="badge badge-light px-2 py-1 font-weight-bold text-dark">
                    {{ caseData.Show_ID || '案件派工' }}
                </span>
            </div>
        </header>

        <!-- 主體內容區 (全載具雙欄/單欄自適應) -->
        <main class="container-fluid py-3 px-md-4">
            <!-- 載入中骨架屏 -->
            <div v-if="loading" class="text-center py-5">
                <i class="fas fa-spinner fa-spin fa-2x text-primary mb-3"></i>
                <div class="text-muted">正在載入通報案件與單位資料，請稍候...</div>
            </div>

            <!-- 錯誤提示 -->
            <div v-else-if="errorMessage" class="alert alert-danger shadow-sm">
                <i class="fas fa-exclamation-triangle mr-2"></i> {{ errorMessage }}
                <div class="mt-2">
                    <button class="btn btn-sm btn-outline-danger" v-on:click="loadInitData">重試載入</button>
                    <a :href="'BreakDetail.aspx?id=' + encodeURIComponent(breakId)" class="btn btn-sm btn-secondary ml-2">返回明細</a>
                </div>
            </div>

            <div v-else class="row">
                <!-- 左欄：案件基本概況、座標地圖與現場佐證照片 -->
                <div class="col-12 col-lg-5 col-xl-4 mb-3">
                    <!-- 案件概況卡片 -->
                    <div class="card-modern">
                        <div class="card-modern-header">
                            <h2 class="card-modern-title">
                                <i class="fas fa-info-circle text-primary"></i> 案件基本資料
                            </h2>
                            <span class="badge badge-primary px-2 py-1">待派工通報</span>
                        </div>
                        <div class="card-modern-body">
                            <div class="row no-gutters">
                                <div class="col-6 pr-1">
                                    <div class="stat-chip">
                                        <div class="stat-chip-label">行政區</div>
                                        <div class="stat-chip-val">{{ caseData.TOWN_NA || '未填寫' }}</div>
                                    </div>
                                </div>
                                <div class="col-6 pl-1">
                                    <div class="stat-chip">
                                        <div class="stat-chip-label">道路級別</div>
                                        <div class="stat-chip-val text-primary">{{ caseData.ROAD_LV || '未指定' }}</div>
                                    </div>
                                </div>
                                <div class="col-12">
                                    <div class="stat-chip">
                                        <div class="stat-chip-label">道路名稱</div>
                                        <div class="stat-chip-val">{{ caseData.ROAD_Name || '未填寫' }}</div>
                                    </div>
                                </div>
                                <div class="col-6 pr-1">
                                    <div class="stat-chip">
                                        <div class="stat-chip-label">鋪面平整度</div>
                                        <div class="stat-chip-val">{{ caseData.Smooth_Str || '未評定' }}</div>
                                    </div>
                                </div>
                                <div class="col-6 pl-1">
                                    <div class="stat-chip">
                                        <div class="stat-chip-label">人手孔蓋銜接</div>
                                        <div class="stat-chip-val">{{ caseData.Hole_Conn_St_Str || '未評定' }}</div>
                                    </div>
                                </div>
                                <div class="col-6 pr-1">
                                    <div class="stat-chip">
                                        <div class="stat-chip-label">查核時間</div>
                                        <div class="stat-chip-val text-muted" style="font-size:0.85rem;">{{ caseData.Report_Date }}</div>
                                    </div>
                                </div>
                                <div class="col-6 pl-1">
                                    <div class="stat-chip">
                                        <div class="stat-chip-label">查核人員</div>
                                        <div class="stat-chip-val">{{ caseData.Report_UserName || '外勤查核人員' }}</div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- 地理位置地圖卡片 -->
                    <div class="card-modern">
                        <div class="card-modern-header">
                            <h2 class="card-modern-title">
                                <i class="fas fa-map-marked-alt text-success"></i> 現場位置
                            </h2>
                            <button v-if="caseData.Lat && caseData.Lng" type="button" class="btn btn-sm btn-outline-success py-0 px-2" v-on:click="openGoogleMaps" title="以 Google Maps 開啟位置導航">
                                <i class="fas fa-location-arrow mr-1"></i>導航
                            </button>
                        </div>
                        <div class="card-modern-body p-2">
                            <div id="mapContainer"></div>
                            <div class="text-muted small mt-2 d-flex justify-content-between px-1">
                                <span>TWD97: {{ caseData.S_UTME }}, {{ caseData.S_UTMN }}</span>
                                <span v-if="caseData.Lat">WGS84: {{ caseData.Lat.toFixed(5) }}, {{ caseData.Lng.toFixed(5) }}</span>
                            </div>
                        </div>
                    </div>

                    <!-- 現場佐證照片卡片 -->
                    <div class="card-modern">
                        <div class="card-modern-header">
                            <h2 class="card-modern-title">
                                <i class="fas fa-camera text-info"></i> 現場佐證照片
                            </h2>
                            <span class="badge badge-secondary">{{ photos.length }} 張</span>
                        </div>
                        <div class="card-modern-body">
                            <div v-if="photos.length === 0" class="text-muted text-center py-3 small">
                                <i class="fas fa-image text-secondary mb-1"></i><br/>無現場佐證照片
                            </div>
                            <div v-else class="row no-gutters">
                                <div v-for="(p, idx) in photos" :key="idx" class="col-6 col-sm-4 col-lg-6 p-1">
                                    <div class="photo-thumb-card" v-on:click="viewLightbox(p.Url, p.Title)">
                                        <img :src="p.Url" :alt="p.Title" class="photo-img" loading="lazy" />
                                        <div class="photo-cap" :title="p.Title">{{ p.Title }}</div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- 右欄：派工設定作業區 (核心表單) -->
                <div class="col-12 col-lg-7 col-xl-8 mb-3">
                    <div class="card-modern">
                        <div class="card-modern-header bg-light">
                            <h2 class="card-modern-title">
                                <i class="fas fa-tasks text-primary"></i> 派工處理作業
                            </h2>
                            <span class="text-muted small">
                                <i class="fas fa-user-edit mr-1"></i>通報人員：<strong>{{ caseData.S_UserName }}</strong>
                            </span>
                        </div>
                        <div class="card-modern-body">
                            <form v-on:submit.prevent="submitDispatch">
                                <!-- 通報單位與處理單位選單 -->
                                <div class="row">
                                    <div class="col-12 col-md-6 mb-3">
                                        <label class="font-weight-bold text-dark">
                                            <span class="text-danger">*</span> 通報單位：
                                        </label>
                                        <select v-model="form.sCom" class="form-control" required>
                                            <option value="">&lt;請選擇通報單位&gt;</option>
                                            <option v-for="u in reportUnits" :key="u.UnitID" :value="u.UnitID">
                                                {{ u.UnitName }}
                                            </option>
                                        </select>
                                        <small class="form-text text-muted">發出通報之權責機關或委辦單位</small>
                                    </div>

                                    <div class="col-12 col-md-6 mb-3">
                                        <label class="font-weight-bold text-dark">
                                            <span class="text-danger">*</span> 處理單位（權責單位）：
                                        </label>
                                        <select v-model="form.gCom" v-on:change="onHandleUnitChange" class="form-control" required>
                                            <option value="">&lt;請選擇處理單位&gt;</option>
                                            <option v-for="u in handleUnits" :key="u.UnitID" :value="u.UnitID">
                                                {{ u.UnitName }}
                                            </option>
                                        </select>
                                        <small class="form-text text-muted">
                                            已依該道路級別 ({{ caseData.ROAD_LV || '未指定' }}) 自動篩選對應權責機關
                                        </small>
                                    </div>
                                </div>

                                <!-- 處理單位承辦人與 Email 通知清單卡片 -->
                                <div class="card border-info mb-3">
                                    <div class="card-header bg-info text-white py-2 d-flex justify-content-between align-items-center">
                                        <span class="font-weight-bold">
                                            <i class="fas fa-envelope mr-1"></i> 處理單位承辦人員通知電子信箱
                                        </span>
                                        <span v-if="unitUsersLoading" class="badge badge-light">
                                            <i class="fas fa-spinner fa-spin mr-1"></i>讀取中
                                        </span>
                                    </div>
                                    <div class="card-body p-0">
                                        <div v-if="!form.gCom" class="p-3 text-muted text-center small">
                                            <i class="fas fa-arrow-up mr-1"></i>請先於上方選取「處理單位」，系統將自動帶出該單位承辦人員信箱。
                                        </div>
                                        <div v-else-if="unitUsers.length === 0" class="p-3 text-muted text-center small">
                                            <i class="fas fa-exclamation-circle mr-1 text-warning"></i>此處理單位尚未建立承辦人員或信箱名冊。
                                        </div>
                                        <div v-else class="table-responsive mb-0">
                                            <table class="table table-sm table-striped user-table mb-0">
                                                <thead class="thead-light">
                                                    <tr>
                                                        <th style="width: 120px;">承辦人員</th>
                                                        <th>電子郵件信箱 (Email)</th>
                                                        <th style="width: 90px;" class="text-center">操作</th>
                                                    </tr>
                                                </thead>
                                                <tbody>
                                                    <tr v-for="(user, uIdx) in unitUsers" :key="user.RunUser">
                                                        <td class="font-weight-bold text-dark">
                                                            <i class="fas fa-user-circle mr-1 text-secondary"></i>
                                                            {{ user.Name }}
                                                        </td>
                                                        <td>
                                                            <input type="email" v-model="user.UserEmail" class="form-control form-control-sm" placeholder="請輸入 Email (例如: user@ntpc.gov.tw)" />
                                                        </td>
                                                        <td class="text-center">
                                                            <button type="button" class="btn btn-sm btn-outline-primary py-0 px-2" v-on:click="saveUserEmail(user)" :disabled="user.saving">
                                                                <span v-if="user.saving"><i class="fas fa-spinner fa-spin"></i></span>
                                                                <span v-else><i class="fas fa-save mr-1"></i>儲存</span>
                                                            </button>
                                                        </td>
                                                    </tr>
                                                </tbody>
                                            </table>
                                        </div>
                                    </div>
                                    <div class="card-footer bg-light py-2 small text-muted">
                                        <i class="fas fa-info-circle mr-1"></i>送出派工時，系統將自動向清單中設定之電子信箱發送改善通報單。
                                    </div>
                                </div>

                                <!-- 派工通報補充說明 -->
                                <div class="form-group mb-4">
                                    <label class="font-weight-bold text-dark">
                                        <i class="fas fa-comment-alt mr-1 text-secondary"></i> 通報補充說明：
                                    </label>
                                    <textarea v-model="form.memo" class="form-control" rows="4" placeholder="請填寫通報補充說明或外勤現況備註..."></textarea>
                                </div>

                                <!-- 動作按鈕列 -->
                                <div class="d-flex flex-wrap align-items-center justify-content-end border-top pt-3">
                                    <a :href="'BreakDetail.aspx?id=' + encodeURIComponent(breakId)" class="btn btn-secondary mr-2 font-weight-bold">
                                        <i class="fas fa-times mr-1"></i> 取消返回
                                    </a>
                                    <button type="submit" class="btn btn-primary font-weight-bold px-4 shadow-sm" :disabled="submitting">
                                        <span v-if="submitting">
                                            <i class="fas fa-spinner fa-spin mr-1"></i> 送出派工中...
                                        </span>
                                        <span v-else>
                                            <i class="fas fa-paper-plane mr-1"></i> 確認送出派工通報
                                        </span>
                                    </button>
                                </div>
                            </form>
                        </div>
                    </div>
                </div>
            </div>
        </main>

        <!-- 燈箱視窗 (Lightbox) -->
        <div v-if="lightbox.show" class="modal-lightbox" v-on:click="lightbox.show = false">
            <div class="text-center" v-on:click.stop>
                <img :src="lightbox.url" :alt="lightbox.title" />
                <div class="text-white mt-2 font-weight-bold">{{ lightbox.title }}</div>
                <button type="button" class="btn btn-sm btn-outline-light mt-2" v-on:click="lightbox.show = false">
                    <i class="fas fa-times mr-1"></i>關閉
                </button>
            </div>
        </div>
    </div>

    <!-- 本地腳本依賴 -->
    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>
    <script src="../Scripts/leaflet/leaflet.js"></script>

    <script>
        const { createApp } = Vue;

        createApp({
            data() {
                // 從網址取得案件 ID
                const params = new URLSearchParams(window.location.search);
                const id = params.get('id') || '';

                return {
                    breakId: id,
                    loading: true,
                    errorMessage: '',
                    submitting: false,
                    unitUsersLoading: false,

                    caseData: {},
                    reportUnits: [],
                    handleUnits: [],
                    photos: [],
                    unitUsers: [],

                    form: {
                        sCom: '',
                        gCom: '',
                        memo: ''
                    },

                    lightbox: {
                        show: false,
                        url: '',
                        title: ''
                    },

                    leafletMap: null,
                    leafletMarker: null
                };
            },
            mounted() {
                if (!this.breakId) {
                    this.errorMessage = '缺少案件識別代碼 (id 參數)，無法進行派工通報。';
                    this.loading = false;
                    return;
                }
                this.loadInitData();
            },
            methods: {
                // 載入初始化案件資料
                async loadInitData() {
                    this.loading = true;
                    this.errorMessage = '';
                    try {
                        const res = await axios.get(`SetSG_Break.aspx?action=init&id=${encodeURIComponent(this.breakId)}`);
                        if (!res.data || !res.data.Success) {
                            throw new Error((res.data && res.data.Message) || '載入失敗');
                        }

                        const d = res.data;
                        this.caseData = d.Case || {};
                        this.reportUnits = d.ReportUnits || [];
                        this.handleUnits = d.HandleUnits || [];
                        this.photos = d.Photos || [];

                        // 表單預設值
                        this.form.sCom = this.caseData.S_COM || (this.reportUnits.length > 0 ? this.reportUnits[0].UnitID : '');
                        this.form.gCom = this.caseData.G_COM || '';
                        this.form.memo = this.caseData.Memo || '';

                        this.loading = false;

                        // 初始化地圖
                        this.$nextTick(() => {
                            this.initMap();
                            if (this.form.gCom) {
                                this.loadUnitUsers(this.form.gCom);
                            }
                        });

                    } catch (err) {
                        this.loading = false;
                        this.errorMessage = err.message || '伺服器連線發生錯誤。';
                    }
                },

                // 初始化 Leaflet 地圖
                initMap() {
                    const el = document.getElementById('mapContainer');
                    if (!el) return;

                    const lat = this.caseData.Lat;
                    const lng = this.caseData.Lng;

                    const defaultLat = (lat && lat > 0) ? lat : 25.0118;
                    const defaultLng = (lng && lng > 0) ? lng : 121.4658;
                    const zoom = (lat && lat > 0) ? 16 : 12;

                    try {
                        if (this.leafletMap) {
                            this.leafletMap.remove();
                            this.leafletMap = null;
                        }

                        this.leafletMap = L.map('mapContainer').setView([defaultLat, defaultLng], zoom);

                        // 本地 OpenStreetMap 圖層
                        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                            maxZoom: 19,
                            attribution: '&copy; OpenStreetMap'
                        }).addTo(this.leafletMap);

                        if (lat && lat > 0 && lng && lng > 0) {
                            this.leafletMarker = L.marker([lat, lng]).addTo(this.leafletMap)
                                .bindPopup(`<strong>${this.caseData.ROAD_Name || '通報位置'}</strong><br/>${this.caseData.TOWN_NA || ''}`)
                                .openPopup();
                        }
                    } catch (e) {
                        console.warn('地圖初始化失敗:', e);
                    }
                },

                // 開啟 Google Maps 路線導航
                openGoogleMaps() {
                    if (this.caseData.Lat && this.caseData.Lng) {
                        const url = `https://www.google.com/maps/dir/?api=1&destination=${this.caseData.Lat},${this.caseData.Lng}`;
                        window.open(url, '_blank');
                    }
                },

                // 處理單位切換事件
                onHandleUnitChange() {
                    if (this.form.gCom) {
                        this.loadUnitUsers(this.form.gCom);
                    } else {
                        this.unitUsers = [];
                    }
                },

                // 讀取指定處理單位承辦人
                async loadUnitUsers(unitId) {
                    this.unitUsersLoading = true;
                    try {
                        const res = await axios.get(`SetSG_Break.aspx?action=getunitusers&unitId=${encodeURIComponent(unitId)}`);
                        if (res.data && res.data.Success) {
                            this.unitUsers = (res.data.Users || []).map(u => ({ ...u, saving: false }));
                        }
                    } catch (e) {
                        console.error('讀取單位承辦人失敗:', e);
                    } finally {
                        this.unitUsersLoading = false;
                    }
                },

                // 儲存個別承辦人 Email
                async saveUserEmail(user) {
                    if (!user.UserEmail) {
                        alert('電子郵件信箱不可為空！');
                        return;
                    }
                    user.saving = true;
                    try {
                        const res = await axios.post('SetSG_Break.aspx?action=updateuseremail', {
                            UnitID: this.form.gCom,
                            RunUser: user.RunUser,
                            UserEmail: user.UserEmail
                        });
                        if (res.data && res.data.Success) {
                            alert(res.data.Message || '電子郵件更新成功！');
                        } else {
                            alert((res.data && res.data.Message) || '更新失敗');
                        }
                    } catch (e) {
                        alert('更新電子郵件發生錯誤：' + e.message);
                    } finally {
                        user.saving = false;
                    }
                },

                // 送出派工通報
                async submitDispatch() {
                    if (!this.form.sCom) {
                        alert('請選擇通報單位！');
                        return;
                    }
                    if (!this.form.gCom) {
                        alert('請選擇處理單位！');
                        return;
                    }

                    if (!confirm('是否確定送出派工通報？\n系統將自動指派權責機關並發送通報電子郵件。')) {
                        return;
                    }

                    this.submitting = true;
                    try {
                        const payload = {
                            Break_ID: this.breakId,
                            S_COM: this.form.sCom,
                            G_COM: this.form.gCom,
                            Memo: this.form.memo
                        };

                        const res = await axios.post('SetSG_Break.aspx?action=save', payload);
                        if (res.data && res.data.Success) {
                            alert(res.data.Message + '\n' + (res.data.MailStatus || ''));
                            // 跳轉回明細頁
                            window.location.href = `BreakDetail.aspx?id=${encodeURIComponent(this.breakId)}`;
                        } else {
                            alert('派工通報失敗：' + ((res.data && res.data.Message) || '未知錯誤'));
                        }
                    } catch (e) {
                        alert('送出派工通報異常：' + (e.message || e));
                    } finally {
                        this.submitting = false;
                    }
                },

                // 燈箱檢視照片
                viewLightbox(url, title) {
                    this.lightbox.url = url;
                    this.lightbox.title = title;
                    this.lightbox.show = true;
                }
            }
        }).mount('#setSGApp');
    </script>
</body>
</html>
