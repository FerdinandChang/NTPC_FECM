<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="ImproveBreak.aspx.cs" Inherits="NTPC_FEC.RoadBreak.ImproveBreak" %>
<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定逸散源管理平台 - 道路髒污破損改善回報</title>
    
    <link rel="shortcut icon" href="../favicon.ico" type="image/x-icon" />

    <!-- 本地化樣式依賴 -->
    <link rel="stylesheet" href="../Content/bootstrap.min.css" />
    <link rel="stylesheet" href="../Content/fontawesome/css/all.min.css" />
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
            --status-warn: #f59e0b;
            --status-danger: #ef4444;
            --status-success: #10b981;
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

        .top-navbar {
            background: linear-gradient(135deg, #059669 0%, #0284c7 100%);
            color: #ffffff;
            height: 56px;
            display: flex; align-items: center; justify-content: space-between;
            padding: 0 16px;
            box-shadow: 0 2px 10px rgba(5, 150, 105, 0.25);
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

        .stat-chip {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 10px 12px;
            margin-bottom: 10px;
        }
        .stat-chip-label { font-size: 0.8rem; color: var(--text-muted); margin-bottom: 2px; }
        .stat-chip-val { font-size: 0.95rem; font-weight: 600; color: var(--brand-navy); word-break: break-all; }

        #mapContainer {
            width: 100%;
            height: 220px;
            border-radius: 8px;
            z-index: 1;
        }

        .photo-card {
            border: 1px solid var(--border-color);
            border-radius: 8px;
            overflow: hidden;
            background: #ffffff;
            margin-bottom: 12px;
        }
        .photo-card img {
            width: 100%;
            height: 140px;
            object-fit: cover;
            cursor: pointer;
        }
        .photo-card-footer {
            padding: 6px 10px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            background: #f8fafc;
            font-size: 0.82rem;
        }

        .upload-dropzone {
            border: 2px dashed #0284c7;
            background: #f0f9ff;
            border-radius: 8px;
            padding: 20px;
            text-align: center;
            cursor: pointer;
            transition: background-color 0.2s;
        }
        .upload-dropzone:hover {
            background: #e0f2fe;
        }

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
        }
    </style>
</head>
<body>
    <div id="improveApp" v-cloak>
        <!-- 頂部導覽列 -->
        <header class="top-navbar">
            <div class="d-flex align-items-center">
                <a :href="'BreakDetail.aspx?id=' + encodeURIComponent(breakId)" class="nav-btn mr-2" title="返回案件明細">
                    <i class="fas fa-arrow-left"></i>
                    <span class="d-none d-sm-inline">返回明細</span>
                </a>
                <h1 class="h6 mb-0 font-weight-bold">
                    <i class="fas fa-tools mr-1 text-warning"></i> 道路髒污破損 - 改善回報
                </h1>
            </div>
            <div>
                <span class="badge badge-light px-2 py-1 font-weight-bold text-dark">
                    {{ caseData.Show_ID || '改善回報' }}
                </span>
            </div>
        </header>

        <!-- 主體內容區 -->
        <main class="container-fluid py-3 px-md-4">
            <div v-if="loading" class="text-center py-5">
                <i class="fas fa-spinner fa-spin fa-2x text-success mb-3"></i>
                <div class="text-muted">正在載入案件資料，請稍候...</div>
            </div>

            <div v-else-if="errorMessage" class="alert alert-danger shadow-sm">
                <i class="fas fa-exclamation-triangle mr-2"></i> {{ errorMessage }}
                <div class="mt-2">
                    <button class="btn btn-sm btn-outline-danger" v-on:click="loadInitData">重試載入</button>
                    <a :href="'BreakDetail.aspx?id=' + encodeURIComponent(breakId)" class="btn btn-sm btn-secondary ml-2">返回明細</a>
                </div>
            </div>

            <div v-else class="row">
                <!-- 左欄：案件概況與現場佐證照 -->
                <div class="col-12 col-lg-5 col-xl-4 mb-3">
                    <div class="card-modern">
                        <div class="card-modern-header">
                            <h2 class="card-modern-title">
                                <i class="fas fa-file-alt text-primary"></i> 案件與派工摘要
                            </h2>
                            <span class="badge badge-warning text-dark px-2 py-1">待改善處理</span>
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
                                        <div class="stat-chip-label">通報單位</div>
                                        <div class="stat-chip-val" style="font-size:0.85rem;">{{ caseData.S_COM_NAME || '未指定' }}</div>
                                    </div>
                                </div>
                                <div class="col-6 pl-1">
                                    <div class="stat-chip">
                                        <div class="stat-chip-label">處理單位</div>
                                        <div class="stat-chip-val text-success" style="font-size:0.85rem;">{{ caseData.G_COM_NAME || '未指定' }}</div>
                                    </div>
                                </div>
                                <div class="col-6 pr-1">
                                    <div class="stat-chip">
                                        <div class="stat-chip-label">派工時間</div>
                                        <div class="stat-chip-val text-muted" style="font-size:0.85rem;">{{ caseData.SetCOM_Date || '-' }}</div>
                                    </div>
                                </div>
                                <div class="col-6 pl-1">
                                    <div class="stat-chip">
                                        <div class="stat-chip-label">通報人員</div>
                                        <div class="stat-chip-val">{{ caseData.S_UserName || '-' }}</div>
                                    </div>
                                </div>
                                <div v-if="caseData.Memo" class="col-12">
                                    <div class="stat-chip bg-light">
                                        <div class="stat-chip-label">通報備註</div>
                                        <div class="stat-chip-val small text-muted font-weight-normal">{{ caseData.Memo }}</div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- 現場位置地圖 -->
                    <div class="card-modern">
                        <div class="card-modern-header">
                            <h2 class="card-modern-title">
                                <i class="fas fa-map-marked-alt text-success"></i> 現場位置
                            </h2>
                            <button v-if="caseData.Lat && caseData.Lng" type="button" class="btn btn-sm btn-outline-success py-0 px-2" v-on:click="openGoogleMaps">
                                <i class="fas fa-location-arrow mr-1"></i>導航
                            </button>
                        </div>
                        <div class="card-modern-body p-2">
                            <div id="mapContainer"></div>
                        </div>
                    </div>

                    <!-- 現場佐證照片清單 -->
                    <div class="card-modern">
                        <div class="card-modern-header">
                            <h2 class="card-modern-title">
                                <i class="fas fa-camera text-info"></i> 現場改善前照片
                            </h2>
                            <span class="badge badge-secondary">{{ evidencePhotos.length }} 張</span>
                        </div>
                        <div class="card-modern-body">
                            <div v-if="evidencePhotos.length === 0" class="text-muted text-center py-2 small">
                                無改善前照片
                            </div>
                            <div v-else class="row no-gutters">
                                <div v-for="(p, idx) in evidencePhotos" :key="idx" class="col-6 p-1">
                                    <div class="photo-card mb-0">
                                        <img :src="p.Url" :alt="p.Title" v-on:click="viewLightbox(p.Url, p.Title)" />
                                        <div class="photo-card-footer text-muted small text-truncate">
                                            {{ p.Title }}
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- 右欄：改善回報表單 (核心作業) -->
                <div class="col-12 col-lg-7 col-xl-8 mb-3">
                    <div class="card-modern">
                        <div class="card-modern-header bg-light">
                            <h2 class="card-modern-title">
                                <i class="fas fa-check-circle text-success"></i> 改善成果回報作業
                            </h2>
                            <span class="text-muted small">
                                <i class="fas fa-user-check mr-1"></i>回報人員：<strong>{{ caseData.G_UserName }}</strong>
                            </span>
                        </div>
                        <div class="card-modern-body">
                            <form v-on:submit.prevent="submitImprove">
                                <!-- 退回通報模式勾選 -->
                                <div class="alert alert-warning d-flex align-items-center mb-4">
                                    <div class="custom-control custom-checkbox">
                                        <input type="checkbox" class="custom-control-input" id="chkBack" v-model="form.isBack" />
                                        <label class="custom-control-label font-weight-bold text-danger" for="chkBack">
                                            非本單位權責，退回通報重新派工
                                        </label>
                                        <div class="small text-muted mt-1">
                                            若經現場勘查該道路非屬本單位管轄，請勾選退回並於下方說明退回原因。
                                        </div>
                                    </div>
                                </div>

                                <!-- 改善說明/退回原因 -->
                                <div class="form-group mb-4">
                                    <label class="font-weight-bold text-dark">
                                        <span class="text-danger" v-if="form.isBack">*</span>
                                        {{ form.isBack ? '退回原因詳細說明：' : '改善回報補充說明：' }}
                                    </label>
                                    <textarea v-model="form.gMemo" class="form-control" rows="4" :placeholder="form.isBack ? '請詳述非本單位管轄之原因，以便重新派工...' : '請填寫改善作業情形、派工修復摘要...'" :required="form.isBack"></textarea>
                                </div>

                                <!-- 改善後佐證照片上傳區 (退回時不強制) -->
                                <div v-if="!form.isBack" class="card border-success mb-4">
                                    <div class="card-header bg-success text-white py-2 d-flex justify-content-between align-items-center">
                                        <span class="font-weight-bold">
                                            <i class="fas fa-camera-retro mr-1"></i> 上傳改善後現場照片
                                        </span>
                                        <span class="badge badge-light">{{ uploadedPhotos.length }} 張待上傳/既有</span>
                                    </div>
                                    <div class="card-body">
                                        <!-- 上傳拖放區 -->
                                        <div class="upload-dropzone mb-3" v-on:click="triggerFileInput">
                                            <i class="fas fa-cloud-upload-alt fa-2x text-primary mb-2"></i>
                                            <div class="font-weight-bold text-primary">點擊拍照或選取改善後照片</div>
                                            <div class="small text-muted">支援 JPG / PNG 照片，上傳前將自動智慧壓縮</div>
                                            <input type="file" ref="fileInput" accept="image/*" multiple style="display:none;" v-on:change="handleFiles" />
                                        </div>

                                        <!-- 照片預覽清單 -->
                                        <div v-if="uploadedPhotos.length > 0" class="row">
                                            <div v-for="(p, idx) in uploadedPhotos" :key="idx" class="col-6 col-sm-4 col-md-3 mb-2">
                                                <div class="photo-card mb-0 shadow-sm">
                                                    <img :src="p.previewUrl" :alt="p.title" v-on:click="viewLightbox(p.previewUrl, p.title)" />
                                                    <div class="photo-card-footer">
                                                        <span class="text-truncate mr-1" style="max-width:80px;">{{ p.title }}</span>
                                                        <button type="button" class="btn btn-sm btn-outline-danger py-0 px-1" v-on:click="removePhoto(idx)" title="刪除此照片">
                                                            <i class="fas fa-trash-alt"></i>
                                                        </button>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <!-- 動作按鈕 -->
                                <div class="d-flex flex-wrap align-items-center justify-content-end border-top pt-3">
                                    <a :href="'BreakDetail.aspx?id=' + encodeURIComponent(breakId)" class="btn btn-secondary mr-2 font-weight-bold">
                                        <i class="fas fa-times mr-1"></i> 取消返回
                                    </a>
                                    <button type="submit" :class="form.isBack ? 'btn btn-danger font-weight-bold px-4 shadow-sm' : 'btn btn-success font-weight-bold px-4 shadow-sm'" :disabled="submitting">
                                        <span v-if="submitting">
                                            <i class="fas fa-spinner fa-spin mr-1"></i> 處理中...
                                        </span>
                                        <span v-else>
                                            <i :class="form.isBack ? 'fas fa-undo-alt mr-1' : 'fas fa-check-circle mr-1'"></i>
                                            {{ form.isBack ? '確認送出退回通報' : '確認送出改善回報' }}
                                        </span>
                                    </button>
                                </div>
                            </form>
                        </div>
                    </div>
                </div>
            </div>
        </main>

        <!-- 燈箱 -->
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
                const params = new URLSearchParams(window.location.search);
                const id = params.get('id') || '';

                return {
                    breakId: id,
                    loading: true,
                    errorMessage: '',
                    submitting: false,

                    caseData: {},
                    evidencePhotos: [],
                    uploadedPhotos: [],

                    form: {
                        isBack: false,
                        gMemo: ''
                    },

                    lightbox: {
                        show: false,
                        url: '',
                        title: ''
                    },

                    leafletMap: null
                };
            },
            mounted() {
                if (!this.breakId) {
                    this.errorMessage = '缺少案件代碼 (id 參數)。';
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
                        const res = await axios.get(`ImproveBreak.aspx?action=init&id=${encodeURIComponent(this.breakId)}`);
                        if (!res.data || !res.data.Success) {
                            throw new Error((res.data && res.data.Message) || '載入案件失敗');
                        }

                        const d = res.data;
                        this.caseData = d.Case || {};
                        this.evidencePhotos = d.EvidencePhotos || [];
                        this.form.gMemo = this.caseData.G_Memo || '';
                        this.form.isBack = this.caseData.G_Back === 'Y';

                        // 既有改善照片
                        const impPhotos = d.ImprovePhotos || [];
                        this.uploadedPhotos = impPhotos.map((p, idx) => ({
                            title: p.Title || `改善後照片_${idx + 1}`,
                            fileName: p.FileName,
                            previewUrl: p.Url,
                            base64Data: '',
                            isExisting: true
                        }));

                        this.loading = false;

                        this.$nextTick(() => {
                            this.initMap();
                        });

                    } catch (err) {
                        this.loading = false;
                        this.errorMessage = err.message || '連線異常';
                    }
                },

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
                        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                            maxZoom: 19,
                            attribution: '&copy; OpenStreetMap'
                        }).addTo(this.leafletMap);

                        if (lat && lat > 0 && lng && lng > 0) {
                            L.marker([lat, lng]).addTo(this.leafletMap)
                                .bindPopup(`<strong>${this.caseData.ROAD_Name || '通報位置'}</strong>`)
                                .openPopup();
                        }
                    } catch (e) {
                        console.warn('地圖初始化失敗:', e);
                    }
                },

                openGoogleMaps() {
                    if (this.caseData.Lat && this.caseData.Lng) {
                        window.open(`https://www.google.com/maps/dir/?api=1&destination=${this.caseData.Lat},${this.caseData.Lng}`, '_blank');
                    }
                },

                triggerFileInput() {
                    this.$refs.fileInput.click();
                },

                handleFiles(e) {
                    const files = Array.from(e.target.files);
                    if (!files || files.length === 0) return;

                    files.forEach(file => {
                        const reader = new FileReader();
                        reader.onload = (loadEvent) => {
                            const b64 = loadEvent.target.result;
                            const idx = this.uploadedPhotos.length + 1;
                            this.uploadedPhotos.push({
                                title: `改善後佐證照片_${idx}`,
                                fileName: `改善後佐證照片_${idx}.jpg`,
                                previewUrl: b64,
                                base64Data: b64,
                                isExisting: false
                            });
                        };
                        reader.readAsDataURL(file);
                    });
                    e.target.value = '';
                },

                removePhoto(idx) {
                    this.uploadedPhotos.splice(idx, 1);
                },

                async submitImprove() {
                    if (this.form.isBack && !this.form.gMemo.trim()) {
                        alert('退回通報時請務必填寫退回原因！');
                        return;
                    }

                    const confirmMsg = this.form.isBack
                        ? '是否確定退回此通報案件？\n系統將記錄退回並複製新案件以供重新派工。'
                        : '是否確定送出改善回報？';

                    if (!confirm(confirmMsg)) return;

                    this.submitting = true;
                    try {
                        const payload = {
                            Break_ID: this.breakId,
                            G_Memo: this.form.gMemo,
                            IsBack: this.form.isBack,
                            ImprovePhotos: this.uploadedPhotos.map(p => ({
                                TargetTitle: p.title,
                                FileName: p.fileName,
                                Base64Data: p.base64Data,
                                IsDeleted: false
                            }))
                        };

                        const res = await axios.post('ImproveBreak.aspx?action=save', payload);
                        if (res.data && res.data.Success) {
                            alert(res.data.Message);
                            window.location.href = res.data.RedirectUrl || `BreakDetail.aspx?id=${encodeURIComponent(this.breakId)}`;
                        } else {
                            alert('回報失敗：' + ((res.data && res.data.Message) || '未知錯誤'));
                        }
                    } catch (e) {
                        alert('送出改善回報異常：' + (e.message || e));
                    } finally {
                        this.submitting = false;
                    }
                },

                viewLightbox(url, title) {
                    this.lightbox.url = url;
                    this.lightbox.title = title;
                    this.lightbox.show = true;
                }
            }
        }).mount('#improveApp');
    </script>
</body>
</html>
