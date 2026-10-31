<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="ImproveBSC.aspx.cs" Inherits="NTPC_FEC.RoadBSC.ImproveBSC" %>
<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定逸散源管理平台 - 人行道/跳空通道落塵改善回報</title>
    
    <link rel="shortcut icon" href="../favicon.ico" type="image/x-icon" />

    <!-- 本地化樣式依賴 -->
    <link rel="stylesheet" href="../Content/bootstrap.min.css" />
    <link rel="stylesheet" href="../Content/fontawesome/css/all.min.css" />
    <link rel="stylesheet" href="../Content/leaflet/leaflet.css" />

    <style>
        :root {
            --brand-primary: #9B741E;     /* 金黃土褐 */
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
            height: 240px;
            border-radius: 8px;
            border: 1px solid var(--border-color);
            z-index: 1;
        }

        .photo-card {
            border: 1px solid var(--border-color);
            border-radius: 8px;
            overflow: hidden;
            background: #fff;
            margin-bottom: 12px;
            position: relative;
        }
        .photo-card img {
            width: 100%;
            height: 140px;
            object-fit: cover;
            cursor: pointer;
            display: block;
        }
        .photo-card-footer {
            padding: 6px 8px;
            font-size: 0.8rem;
            background: #f8fafc;
            border-top: 1px solid var(--border-color);
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .upload-dropzone {
            border: 2px dashed #0284c7;
            background: #f0f9ff;
            border-radius: 8px;
            padding: 24px;
            text-align: center;
            cursor: pointer;
            transition: all 0.2s;
        }
        .upload-dropzone:hover {
            background: #e0f2fe;
            border-color: #0369a1;
        }

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
    <div id="improveApp" v-cloak>
        <header class="top-navbar">
            <div class="d-flex align-items-center">
                <a href="BSC_List.aspx?mode=BSCImprove" class="nav-btn mr-2" title="返回待改善清單">
                    <i class="fas fa-arrow-left"></i>
                    <span class="d-none d-sm-inline">回列表</span>
                </a>
                <a href="../MainPage.aspx" class="nav-btn mr-3" title="回首頁">
                    <i class="fas fa-home"></i>
                    <span class="d-none d-sm-inline">首頁</span>
                </a>
                <h1 class="h6 mb-0 font-weight-bold d-flex align-items-center" style="font-size: 1.05rem;">
                    <i class="fas fa-wrench mr-2 text-warning"></i>
                    人行道/跳空通道落塵改善回報作業
                </h1>
            </div>
            <div>
                <span class="badge badge-light px-2 py-1 font-weight-bold" v-if="caseData.Show_ID">
                    {{ caseData.Show_ID }}
                </span>
            </div>
        </header>

        <main class="container-fluid py-3" style="max-width: 1400px;">
            <div v-if="loading" class="text-center py-5">
                <div class="spinner-border text-primary" role="status">
                    <span class="sr-only">載入中...</span>
                </div>
                <p class="text-muted mt-2 font-weight-bold">正在讀取案件通報內容與現場照片，請稍候...</p>
            </div>

            <div v-else-if="errorMessage" class="alert alert-danger shadow-sm my-4">
                <div class="d-flex align-items-center">
                    <i class="fas fa-exclamation-circle fa-2x mr-3 text-danger"></i>
                    <div>
                        <h5 class="mb-1 font-weight-bold">無法載入改善回報單</h5>
                        <p class="mb-0">{{ errorMessage }}</p>
                    </div>
                </div>
                <div class="mt-3">
                    <a href="BSC_List.aspx" class="btn btn-outline-danger btn-sm font-weight-bold">
                        <i class="fas fa-arrow-left mr-1"></i>返回案件清單
                    </a>
                </div>
            </div>

            <div v-else class="row">
                <!-- 左欄：通報基本規格 -->
                <div class="col-12 col-lg-5 col-xl-4 mb-3">
                    <div class="card-modern">
                        <div class="card-modern-header">
                            <h2 class="card-modern-title">
                                <i class="fas fa-info-circle text-primary"></i> 案件基本資料
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
                                        <div class="stat-chip-label">道路路段</div>
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
                        </div>
                        <div class="card-modern-body p-2">
                            <div id="mapContainer"></div>
                        </div>
                    </div>

                    <!-- 現場改善前照片 -->
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

                <!-- 右欄：改善回報表單 -->
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
                                <!-- 退回模式 -->
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

                                <div class="form-group mb-4">
                                    <label class="font-weight-bold text-dark">
                                        <span class="text-danger" v-if="form.isBack">*</span>
                                        {{ form.isBack ? '退回原因詳細說明：' : '改善回報補充說明：' }}
                                    </label>
                                    <textarea v-model="form.gMemo" class="form-control" rows="4" 
                                              :placeholder="form.isBack ? '請詳述非本單位管轄之原因，以便重新派工...' : '請填寫改善作業情形、派工修復摘要...'" 
                                              :required="form.isBack"></textarea>
                                </div>

                                <!-- 照片上傳區 -->
                                <div v-if="!form.isBack" class="card border-success mb-4">
                                    <div class="card-header bg-success text-white py-2 d-flex justify-content-between align-items-center">
                                        <span class="font-weight-bold">
                                            <i class="fas fa-camera-retro mr-1"></i> 上傳改善後現場照片
                                        </span>
                                        <span class="badge badge-light">{{ uploadedPhotos.length }} 張待上傳/既有</span>
                                    </div>
                                    <div class="card-body">
                                        <div class="upload-dropzone mb-3" v-on:click="triggerFileInput">
                                            <i class="fas fa-cloud-upload-alt fa-2x text-primary mb-2"></i>
                                            <div class="font-weight-bold text-primary">點擊拍照或選取改善後照片</div>
                                            <div class="small text-muted">支援 JPG / PNG 照片，上傳前將自動智慧壓縮</div>
                                            <input type="file" ref="fileInput" accept="image/*" multiple style="display:none;" v-on:change="handleFiles" />
                                        </div>

                                        <div class="row">
                                            <div v-for="(p, idx) in uploadedPhotos" :key="idx" class="col-6 col-sm-4 col-md-3">
                                                <div class="photo-card">
                                                    <img :src="p.Url || p.Base64Data" :alt="p.Title" v-on:click="viewLightbox(p.Url || p.Base64Data, p.Title)" />
                                                    <div class="photo-card-footer">
                                                        <span class="small text-truncate" :title="p.Title">{{ p.Title }}</span>
                                                        <button type="button" class="btn btn-xs btn-outline-danger" v-on:click="removePhoto(idx)" title="刪除照片">
                                                            <i class="fas fa-times"></i>
                                                        </button>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <div class="pt-3 border-top d-flex align-items-center justify-content-between">
                                    <a href="BSC_List.aspx?mode=BSCImprove" class="btn btn-outline-secondary font-weight-bold px-3">
                                        <i class="fas fa-arrow-left mr-1"></i>取消返回
                                    </a>
                                    <button type="submit" class="btn font-weight-bold px-4 py-2 shadow" 
                                            :class="form.isBack ? 'btn-danger' : 'btn-success'" 
                                            :disabled="submitting">
                                        <span v-if="submitting">
                                            <i class="fas fa-spinner fa-spin mr-1"></i>處理中...
                                        </span>
                                        <span v-else>
                                            <i class="fas" :class="form.isBack ? 'fa-undo mr-1' : 'fa-check mr-1'"></i>
                                            {{ form.isBack ? '確認退回案件' : '確認送出改善成果' }}
                                        </span>
                                    </button>
                                </div>
                            </form>
                        </div>
                    </div>
                </div>
            </div>
        </main>

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
    <script src="../Scripts/fec-image-compressor.js"></script>

    <script>
        const { createApp } = Vue;

        createApp({
            data() {
                const params = new URLSearchParams(window.location.search);
                const id = params.get('id') || '';

                return {
                    bscId: id,
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

                    leafletMap: null,
                    leafletMarker: null
                };
            },
            mounted() {
                if (!this.bscId) {
                    this.errorMessage = '缺少通報案號參數，無法開啟改善回報作業。';
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
                        const res = await axios.get(`ImproveBSC.aspx?action=init&id=${encodeURIComponent(this.bscId)}`);
                        if (!res.data || !res.data.Success) {
                            throw new Error((res.data && res.data.Message) || '載入失敗');
                        }

                        const d = res.data;
                        this.caseData = d.Case || {};
                        this.evidencePhotos = d.EvidencePhotos || [];
                        const existingImproves = d.ImprovePhotos || [];

                        this.uploadedPhotos = existingImproves.map(p => ({
                            FileName: p.FileName,
                            Url: p.Url,
                            Title: p.Title || p.FileName,
                            Base64Data: '',
                            IsDeleted: false
                        }));

                        this.form.gMemo = this.caseData.G_Memo || '';
                        this.form.isBack = this.caseData.G_Back === 'Y';

                        this.loading = false;

                        this.$nextTick(() => {
                            this.initMap();
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

                triggerFileInput() {
                    if (this.$refs.fileInput) {
                        this.$refs.fileInput.click();
                    }
                },

                async handleFiles(e) {
                    const files = e.target.files;
                    if (!files || files.length === 0) return;

                    for (let i = 0; i < files.length; i++) {
                        const file = files[i];
                        try {
                            let base64 = '';
                            if (window.FecImageCompressor && typeof window.FecImageCompressor.compress === 'function') {
                                base64 = await window.FecImageCompressor.compress(file, { maxWidth: 1600, quality: 0.8 });
                            } else {
                                base64 = await this.readFileAsDataUrl(file);
                            }

                            const idx = this.uploadedPhotos.length + 1;
                            this.uploadedPhotos.push({
                                FileName: `G_改善後佐證照片_${idx}.jpg`,
                                Title: `改善後佐證照片 #${idx}`,
                                Base64Data: base64,
                                IsDeleted: false
                            });
                        } catch (err) {
                            console.error('壓縮圖片失敗:', err);
                        }
                    }
                    e.target.value = '';
                },

                readFileAsDataUrl(file) {
                    return new Promise((resolve, reject) => {
                        const reader = new FileReader();
                        reader.onload = ev => resolve(ev.target.result);
                        reader.onerror = err => reject(err);
                        reader.readAsDataURL(file);
                    });
                },

                removePhoto(idx) {
                    if (confirm('確定要移除此照片嗎？')) {
                        const p = this.uploadedPhotos[idx];
                        if (p.Url) {
                            p.IsDeleted = true;
                        }
                        this.uploadedPhotos.splice(idx, 1);
                    }
                },

                async submitImprove() {
                    if (this.form.isBack) {
                        if (!this.form.gMemo || !this.form.gMemo.trim()) {
                            alert('請填寫退回原因說明！');
                            return;
                        }
                        if (!confirm('確定要退回此案件嗎？系統將通知通報單位重新派工。')) {
                            return;
                        }
                    } else {
                        if (this.uploadedPhotos.length === 0) {
                            if (!confirm('尚未上傳任何改善後現場照片，確定要直接回報送出嗎？')) {
                                return;
                            }
                        }
                    }

                    this.submitting = true;
                    try {
                        const payload = {
                            BSC_ID: this.bscId,
                            IsBack: this.form.isBack,
                            G_Memo: this.form.gMemo,
                            ImprovePhotos: this.uploadedPhotos
                        };

                        const res = await axios.post('ImproveBSC.aspx?action=save', payload);
                        if (res.data && res.data.Success) {
                            alert(res.data.Message || '改善成果已成功回報！');
                            window.location.href = res.data.RedirectUrl || 'BSC_List.aspx?mode=Finish';
                        } else {
                            alert('回報失敗：' + ((res.data && res.data.Message) || '伺服器未回傳'));
                        }
                    } catch (e) {
                        alert('送出過程發生異常：' + e.message);
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
