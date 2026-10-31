<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="SetSG_Dirty.aspx.cs" Inherits="NTPC_FEC.RoadClean.SetSG_Dirty" %>
<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定逸散源管理平台 - 道路髒污通報派工</title>
    
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
        .stat-chip-label { font-size: 0.8rem; color: var(--text-muted); margin-bottom: 2px; }
        .stat-chip-val { font-size: 0.95rem; font-weight: 600; color: var(--brand-navy); word-break: break-all; }

        /* 地圖容器 */
        #mapContainer {
            width: 100%;
            height: 280px;
            border-radius: 8px;
            border: 1px solid var(--border-color);
            z-index: 1;
        }

        /* 佐證照片縮圖 */
        .photo-card {
            border: 1px solid var(--border-color);
            border-radius: 8px;
            overflow: hidden;
            background: #fff;
            transition: all 0.2s;
        }
        .photo-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
        }
        .photo-thumb {
            width: 100%;
            height: 140px;
            object-fit: cover;
            cursor: pointer;
            display: block;
        }
        .photo-caption {
            font-size: 0.8rem;
            color: var(--text-muted);
            padding: 6px 8px;
            text-align: center;
            background: #f8fafc;
            border-top: 1px solid var(--border-color);
        }

        /* 處理單位人員清單 Table */
        .user-table {
            font-size: 0.9rem;
            margin-bottom: 0;
        }
        .user-table th {
            background: #f8fafc;
            color: var(--text-muted);
            font-weight: 600;
            border-top: none;
        }

        /* 燈箱 Modal */
        .lightbox-modal {
            position: fixed;
            top: 0; left: 0; width: 100vw; height: 100vh;
            background: rgba(0, 0, 0, 0.85);
            display: flex; align-items: center; justify-content: center;
            z-index: 2000;
            padding: 20px;
        }
        .lightbox-img {
            max-width: 90vw;
            max-height: 85vh;
            border-radius: 8px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.5);
        }
    </style>
</head>
<body>
    <div id="dispatchApp" v-cloak>
        <!-- 頂部導覽列 -->
        <header class="top-navbar">
            <div class="d-flex align-items-center">
                <a href="Dirty_List.aspx?mode=DirtyEdit" class="nav-btn mr-2" title="返回髒污案件列表">
                    <i class="fas fa-arrow-left"></i>
                    <span class="d-none d-sm-inline">回列表</span>
                </a>
                <a href="../MainPage.aspx" class="nav-btn mr-3" title="返回首頁">
                    <i class="fas fa-home"></i>
                    <span class="d-none d-sm-inline">首頁</span>
                </a>
                <h1 class="h6 mb-0 font-weight-bold d-flex align-items-center" style="font-size: 1.05rem;">
                    <i class="fas fa-paper-plane mr-2 text-warning"></i>
                    道路髒污現場通報派工單
                </h1>
            </div>
            <div>
                <span class="badge badge-light px-2 py-1 font-weight-bold" v-if="caseData.Show_ID">
                    {{ caseData.Show_ID }}
                </span>
            </div>
        </header>

        <!-- 主體內容 -->
        <main class="container-fluid py-3" style="max-width: 1400px;">
            <!-- 載入中骨架 -->
            <div v-if="loading" class="text-center py-5">
                <div class="spinner-border text-primary" role="status">
                    <span class="sr-only">讀取中...</span>
                </div>
                <p class="text-muted mt-2 font-weight-bold">正在讀取道路髒污案件資料與權責派工單位，請稍候...</p>
            </div>

            <!-- 錯誤提示 -->
            <div v-else-if="errorMessage" class="alert alert-danger shadow-sm my-4">
                <div class="d-flex align-items-center">
                    <i class="fas fa-exclamation-circle fa-2x mr-3 text-danger"></i>
                    <div>
                        <h5 class="mb-1 font-weight-bold">無法載入派工單</h5>
                        <p class="mb-0">{{ errorMessage }}</p>
                    </div>
                </div>
                <div class="mt-3">
                    <a href="Dirty_List.aspx" class="btn btn-outline-danger btn-sm font-weight-bold">
                        <i class="fas fa-arrow-left mr-1"></i>返回案件清單
                    </a>
                </div>
            </div>

            <!-- 雙欄排版作業區 -->
            <div v-else class="row">
                <!-- 左欄：通報基本規格與現場資訊 -->
                <div class="col-12 col-xl-5">
                    <div class="card-modern">
                        <div class="card-modern-header">
                            <h2 class="card-modern-title">
                                <i class="fas fa-info-circle text-primary"></i>通報案件基本規格
                            </h2>
                            <span class="badge badge-primary px-2 py-1">
                                {{ caseData.KIND_Name || '道路髒污' }}
                            </span>
                        </div>
                        <div class="card-modern-body">
                            <div class="row">
                                <div class="col-sm-6">
                                    <div class="stat-chip">
                                        <div class="stat-chip-label">通報案號</div>
                                        <div class="stat-chip-val text-primary font-weight-bold">{{ caseData.Show_ID }}</div>
                                    </div>
                                </div>
                                <div class="col-sm-6">
                                    <div class="stat-chip">
                                        <div class="stat-chip-label">通報日期時間</div>
                                        <div class="stat-chip-val">{{ caseData.Report_Date || '未記錄' }}</div>
                                    </div>
                                </div>
                                <div class="col-sm-6">
                                    <div class="stat-chip">
                                        <div class="stat-chip-label">查核巡查員</div>
                                        <div class="stat-chip-val">{{ caseData.Report_UserName || caseData.Report_User }}</div>
                                    </div>
                                </div>
                                <div class="col-sm-6">
                                    <div class="stat-chip">
                                        <div class="stat-chip-label">行政區</div>
                                        <div class="stat-chip-val">{{ caseData.TOWN_NA || '新北市' }}</div>
                                    </div>
                                </div>
                                <div class="col-12">
                                    <div class="stat-chip">
                                        <div class="stat-chip-label">路段名稱 / 污染位置</div>
                                        <div class="stat-chip-val font-weight-bold text-dark">{{ caseData.ROAD_Name || '未指定路段' }}</div>
                                    </div>
                                </div>
                                <div class="col-12" v-if="caseData.Memo">
                                    <div class="stat-chip">
                                        <div class="stat-chip-label">現場巡查狀況描述</div>
                                        <div class="stat-chip-val" style="white-space: pre-wrap;">{{ caseData.Memo }}</div>
                                    </div>
                                </div>
                            </div>

                            <!-- 地圖坐標顯示 -->
                            <div class="mt-3">
                                <div class="d-flex align-items-center justify-content-between mb-2">
                                    <span class="font-weight-bold" style="font-size: 0.9rem;">
                                        <i class="fas fa-map-marker-alt text-danger mr-1"></i>現場地理坐標
                                    </span>
                                    <small class="text-muted" v-if="caseData.S_UTME && caseData.S_UTMN">
                                        TWD97: E:{{ caseData.S_UTME }} / N:{{ caseData.S_UTMN }}
                                    </small>
                                </div>
                                <div id="mapContainer"></div>
                            </div>
                        </div>
                    </div>

                    <!-- 現場佐證照片卡片 -->
                    <div class="card-modern">
                        <div class="card-modern-header">
                            <h2 class="card-modern-title">
                                <i class="fas fa-camera text-info"></i>現場通報佐證照片 ({{ photos.length }}張)
                            </h2>
                        </div>
                        <div class="card-modern-body">
                            <div v-if="photos.length === 0" class="text-center py-4 text-muted">
                                <i class="far fa-images fa-2x mb-2 d-block"></i>
                                本案件無現場通報照片
                            </div>
                            <div v-else class="row">
                                <div class="col-6 col-md-4 mb-3" v-for="(p, idx) in photos" :key="idx">
                                    <div class="photo-card shadow-sm">
                                        <img :src="p.Url" :alt="p.Title" class="photo-thumb" v-on:click="openLightbox(p.Url, p.Title)" />
                                        <div class="photo-caption text-truncate" :title="p.Title">{{ p.Title }}</div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- 右欄：權責單位指派與派工操作 -->
                <div class="col-12 col-xl-7">
                    <div class="card-modern">
                        <div class="card-modern-header">
                            <h2 class="card-modern-title">
                                <i class="fas fa-share-square text-success"></i>指派通報與處理權責單位
                            </h2>
                            <span class="badge badge-success px-2 py-1 font-weight-bold" v-if="caseData.SetCOM_Date">
                                已於 {{ caseData.SetCOM_Date }} 派工
                            </span>
                        </div>
                        <div class="card-modern-body">
                            <form v-on:submit.prevent="submitDispatch">
                                <!-- 通報單位選擇 -->
                                <div class="form-group mb-3">
                                    <label class="font-weight-bold">
                                        <i class="fas fa-building text-muted mr-1"></i>通報單位（發送方）<span class="text-danger">*</span>
                                    </label>
                                    <select class="form-control" v-model="form.sCom" required>
                                        <option value="">-- 請選擇通報單位 --</option>
                                        <option v-for="u in reportUnits" :key="u.UnitID" :value="u.UnitID">
                                            {{ u.UnitName }}
                                        </option>
                                    </select>
                                    <small class="form-text text-muted">指定巡查通報所屬的發送單位或小組。</small>
                                </div>

                                <!-- 權責處理單位選擇 -->
                                <div class="form-group mb-4">
                                    <label class="font-weight-bold">
                                        <i class="fas fa-tools text-primary mr-1"></i>權責處理單位（接辦改善方）<span class="text-danger">*</span>
                                    </label>
                                    <select class="form-control form-control-lg font-weight-bold border-primary" 
                                            v-model="form.gCom" 
                                            v-on:change="onHandleUnitChange" 
                                            required>
                                        <option value="">-- 請選取接案處理之權責單位 (清潔隊 / 工務單位) --</option>
                                        <option v-for="u in handleUnits" :key="u.UnitID" :value="u.UnitID">
                                            {{ u.UnitName }}
                                        </option>
                                    </select>
                                    <small class="form-text text-muted">選取後系統將自動抓取該單位承辦人員之電子信箱，並於送出後發送派工改善通知信。</small>
                                </div>

                                <!-- 權責單位聯絡人 Email 清單 -->
                                <div class="border rounded p-3 mb-4 bg-light" v-if="form.gCom">
                                    <div class="d-flex align-items-center justify-content-between mb-2">
                                        <h6 class="font-weight-bold text-dark mb-0">
                                            <i class="fas fa-envelope-open-text text-primary mr-1"></i>
                                            此單位接案聯絡人員電子信箱
                                        </h6>
                                        <span class="badge badge-secondary" v-if="unitUsers.length > 0">
                                            共 {{ unitUsers.length }} 位人員
                                        </span>
                                    </div>

                                    <div v-if="unitUsersLoading" class="text-center py-3 text-muted">
                                        <div class="spinner-border spinner-border-sm text-primary mr-1"></div>
                                        正在讀取承辦人名單...
                                    </div>
                                    <div v-else-if="unitUsers.length === 0" class="text-muted small py-2">
                                        <i class="fas fa-exclamation-triangle text-warning mr-1"></i>
                                        此單位尚未配置聯絡人 Email，送出後將僅更新派工狀態。
                                    </div>
                                    <div v-else class="table-responsive">
                                        <table class="table table-sm table-bordered user-table bg-white">
                                            <thead>
                                                <tr>
                                                    <th style="width: 140px;">承辦人員姓名</th>
                                                    <th>電子郵件信箱 (可直接編輯校正)</th>
                                                    <th style="width: 80px;" class="text-center">操作</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                <tr v-for="u in unitUsers" :key="u.RunUser">
                                                    <td class="align-middle font-weight-bold text-dark">
                                                        <i class="fas fa-user-circle text-muted mr-1"></i>{{ u.Name || u.RunUser }}
                                                    </td>
                                                    <td>
                                                        <input type="email" class="form-control form-control-sm" v-model="u.UserEmail" placeholder="請輸入 Email" />
                                                    </td>
                                                    <td class="text-center align-middle">
                                                        <button type="button" class="btn btn-xs btn-outline-primary" v-on:click="saveUserEmail(u)" title="儲存此電子信箱">
                                                            儲存
                                                        </button>
                                                    </td>
                                                </tr>
                                            </tbody>
                                        </table>
                                    </div>
                                </div>

                                <!-- 派工操作按鈕列 -->
                                <div class="pt-3 border-top d-flex align-items-center justify-content-between">
                                    <a href="Dirty_List.aspx?mode=DirtyEdit" class="btn btn-outline-secondary font-weight-bold px-3">
                                        <i class="fas fa-arrow-left mr-1"></i>放棄並返回列表
                                    </a>
                                    <button type="submit" class="btn btn-primary font-weight-bold px-4 py-2 shadow" :disabled="submitting">
                                        <span v-if="submitting">
                                            <i class="fas fa-spinner fa-spin mr-1"></i>正在送出派工...
                                        </span>
                                        <span v-else>
                                            <i class="fas fa-paper-plane mr-1"></i>確定送出通報派工
                                        </span>
                                    </button>
                                </div>
                            </form>
                        </div>
                    </div>
                </div>
            </div>
        </main>

        <!-- 燈箱預覽 Modal -->
        <div class="lightbox-modal" v-if="lightbox.show" v-on:click.self="lightbox.show = false">
            <div class="text-center">
                <img :src="lightbox.url" :alt="lightbox.title" class="lightbox-img" />
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
                const params = new URLSearchParams(window.location.search);
                const id = params.get('id') || '';

                return {
                    dirtyId: id,
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
                        gCom: ''
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
                if (!this.dirtyId) {
                    this.errorMessage = '缺少通報案件識別代碼 (id 參數)，無法進行派工通報。';
                    this.loading = false;
                    return;
                }
                this.loadInitData();
            },
            methods: {
                async loadInitData() {
                    this.loading = true;
                    this.errorMessage = '';
                    try {
                        const res = await axios.get(`SetSG_Dirty.aspx?action=init&id=${encodeURIComponent(this.dirtyId)}`);
                        if (!res.data || !res.data.Success) {
                            throw new Error((res.data && res.data.Message) || '載入失敗');
                        }

                        const d = res.data;
                        this.caseData = d.Case || {};
                        this.reportUnits = d.ReportUnits || [];
                        this.handleUnits = d.HandleUnits || [];
                        this.photos = d.Photos || [];

                        this.form.sCom = this.caseData.S_COM || (this.reportUnits.length > 0 ? this.reportUnits[0].UnitID : '');
                        this.form.gCom = this.caseData.G_COM || '';

                        this.loading = false;

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

                initMap() {
                    const el = document.getElementById('mapContainer');
                    if (!el) return;

                    let lat = parseFloat(this.caseData.Lat) || 25.0123;
                    let lng = parseFloat(this.caseData.Lng) || 121.4657;

                    if (this.leafletMap) {
                        this.leafletMap.remove();
                        this.leafletMap = null;
                    }

                    this.leafletMap = L.map('mapContainer', {
                        center: [lat, lng],
                        zoom: (lat === 25.0123 && lng === 121.4657) ? 12 : 16,
                        attributionControl: false
                    });

                    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                        maxZoom: 19
                    }).addTo(this.leafletMap);

                    if (this.caseData.Lat > 0 && this.caseData.Lng > 0) {
                        this.leafletMarker = L.marker([lat, lng]).addTo(this.leafletMap)
                            .bindPopup(`<b>${this.caseData.ROAD_Name || '通報點位'}</b><br>${this.caseData.TOWN_NA || ''}`)
                            .openPopup();
                    }
                },

                async onHandleUnitChange() {
                    if (!this.form.gCom) {
                        this.unitUsers = [];
                        return;
                    }
                    await this.loadUnitUsers(this.form.gCom);
                },

                async loadUnitUsers(unitId) {
                    this.unitUsersLoading = true;
                    try {
                        const res = await axios.get(`SetSG_Dirty.aspx?action=getunitusers&unitId=${encodeURIComponent(unitId)}`);
                        if (res.data && res.data.Success) {
                            this.unitUsers = res.data.Users || [];
                        } else {
                            this.unitUsers = [];
                        }
                    } catch (e) {
                        this.unitUsers = [];
                    } finally {
                        this.unitUsersLoading = false;
                    }
                },

                async saveUserEmail(user) {
                    if (!user || !user.RunUser) return;
                    try {
                        const res = await axios.post('SetSG_Dirty.aspx?action=updateuseremail', {
                            RunUser: user.RunUser,
                            UserEmail: user.UserEmail,
                            UnitID: this.form.gCom
                        });
                        if (res.data && res.data.Success) {
                            alert('電子郵件信箱已儲存成功！');
                        } else {
                            alert('儲存失敗：' + ((res.data && res.data.Message) || '伺服器異常'));
                        }
                    } catch (e) {
                        alert('儲存發生錯誤：' + e.message);
                    }
                },

                async submitDispatch() {
                    if (!this.form.sCom) {
                        alert('請選擇通報單位！');
                        return;
                    }
                    if (!this.form.gCom) {
                        alert('請選擇權責處理單位！');
                        return;
                    }

                    if (!confirm(`確定要將案件【${this.caseData.Show_ID}】派工至指定的權責處理單位嗎？\n送出後系統將更新派工狀態並寄發通報信件。`)) {
                        return;
                    }

                    this.submitting = true;
                    try {
                        const payload = {
                            Dirty_ID: this.dirtyId,
                            S_COM: this.form.sCom,
                            G_COM: this.form.gCom
                        };

                        const res = await axios.post('SetSG_Dirty.aspx?action=save', payload);
                        if (res.data && res.data.Success) {
                            alert('派工通報成功！' + (res.data.EmailResult ? '\n(' + res.data.EmailResult + ')' : ''));
                            window.location.href = 'Dirty_List.aspx?mode=DirtyEdit';
                        } else {
                            alert('派工失敗：' + ((res.data && res.data.Message) || '伺服器未回傳'));
                        }
                    } catch (e) {
                        alert('派工提交發生錯誤：' + e.message);
                    } finally {
                        this.submitting = false;
                    }
                },

                openLightbox(url, title) {
                    this.lightbox.url = url;
                    this.lightbox.title = title;
                    this.lightbox.show = true;
                }
            }
        }).mount('#dispatchApp');
    </script>
</body>
</html>
