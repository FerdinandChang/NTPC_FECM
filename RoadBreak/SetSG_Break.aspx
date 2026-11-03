<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="SetSG_Break.aspx.cs" Inherits="NTPC_FEC.RoadBreak.SetSG_Break" %>
<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定逸散源管理平台 - 道路髒污破損派工通報與路平編號綁定</title>
    
    <link rel="shortcut icon" href="../favicon.ico" type="image/x-icon" />

    <!-- 本地化樣式依賴 -->
    <link rel="stylesheet" href="../Content/bootstrap.min.css" />
    <link rel="stylesheet" href="../Content/fontawesome/css/all.min.css" />
    <link rel="stylesheet" href="../Content/leaflet/leaflet.css" />

    <style>
        :root {
            --brand-primary: #0099e5;     /* 新北天空青藍 (Navbar/強調) */
            --brand-blue: #0284c7;        /* 科技藍 (按鈕/選中) */
            --brand-dark-blue: #0b1f7d;   /* 海軍深藍 (標題/Tag) */
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

        /* 頂部導覽列 (符合 inspection-ui-standard) */
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
            background: rgba(255, 255, 255, 0.18);
            border: 1px solid rgba(255, 255, 255, 0.3);
            color: #ffffff !important;
            font-size: 0.88rem;
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
            color: #ffffff !important;
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
            flex-wrap: wrap;
            gap: 8px;
        }
        .card-modern-title {
            font-size: 1rem; font-weight: 700; color: var(--brand-navy); margin: 0;
            display: flex; align-items: center; gap: 8px;
        }
        .card-modern-body {
            padding: 16px;
        }

        /* 規格晶片與一鍵複製按鈕 */
        .stat-chip {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 10px 12px;
            margin-bottom: 10px;
            position: relative;
        }
        .stat-chip-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 3px;
        }
        .stat-chip-label {
            font-size: 0.78rem;
            font-weight: 700;
            color: var(--text-muted);
        }
        .stat-chip-val {
            font-size: 0.94rem;
            font-weight: 600;
            color: var(--brand-navy);
            word-break: break-all;
        }
        .btn-copy-mini {
            background: #ffffff;
            border: 1px solid #cbd5e1;
            color: #0284c7;
            font-size: 0.72rem;
            font-weight: 700;
            padding: 1px 7px;
            border-radius: 4px;
            cursor: pointer;
            transition: all 0.15s;
        }
        .btn-copy-mini:hover {
            background: #e0f2fe;
            border-color: #0284c7;
        }

        /* 路平報馬仔綁定專區卡片 */
        .rdm-bind-box {
            background: linear-gradient(180deg, #f0f9ff 0%, #e0f2fe 100%);
            border: 1.5px solid #38bdf8;
            border-radius: 10px;
            padding: 16px;
            margin-bottom: 20px;
        }
        .rdm-bind-title {
            font-size: 1rem;
            font-weight: 800;
            color: #0369a1;
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 10px;
            flex-wrap: wrap;
            gap: 8px;
        }

        /* 地圖容器 */
        #mapContainer {
            width: 100%;
            height: 240px;
            border-radius: 8px;
            z-index: 1;
            border: 1px solid var(--border-color);
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
            height: 115px;
            object-fit: cover;
            display: block;
        }
        .photo-cap {
            font-size: 0.76rem;
            padding: 5px 6px;
            text-align: center;
            background: #ffffff;
            color: #334155;
            font-weight: 600;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        /* 承辦人表格 */
        .user-table td, .user-table th {
            vertical-align: middle;
            font-size: 0.88rem;
            padding: 8px 10px;
        }

        /* 燈箱 */
        .modal-lightbox {
            position: fixed;
            top: 0; left: 0; width: 100%; height: 100%;
            background: rgba(0, 0, 0, 0.88);
            display: flex; align-items: center; justify-content: center;
            z-index: 9999;
            padding: 20px;
        }
        .modal-lightbox img {
            max-width: 92%;
            max-height: 85vh;
            border-radius: 6px;
            box-shadow: 0 5px 25px rgba(0,0,0,0.5);
        }

        /* Toast 複製成功通知 */
        /* 自訂純 Vue 彈窗 (零外部依賴) */
        .modal-backdrop-custom {
            position: fixed;
            top: 0;
            left: 0;
            width: 100vw;
            height: 100vh;
            background: rgba(15, 23, 42, 0.6);
            backdrop-filter: blur(2px);
            z-index: 1050;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 16px;
        }
        .modal-dialog-custom {
            background: #ffffff;
            border-radius: 10px;
            width: 100%;
            max-width: 480px;
            box-shadow: 0 10px 25px rgba(0, 0, 0, 0.2);
            overflow: hidden;
            animation: fadeInScale 0.2s ease;
        }
        .modal-header-custom {
            padding: 12px 18px;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }
        .modal-body-custom {
            padding: 18px;
        }
        .modal-footer-custom {
            padding: 10px 18px;
            background: #f8fafc;
            border-top: 1px solid var(--border-color);
            display: flex;
            align-items: center;
            justify-content: flex-end;
            gap: 10px;
        }
        @keyframes fadeInScale {
            from { opacity: 0; transform: scale(0.95); }
            to { opacity: 1; transform: scale(1); }
        }

        .copy-toast {
            position: fixed;
            bottom: 80px;
            left: 50%;
            transform: translateX(-50%);
            background: rgba(15, 23, 42, 0.92);
            color: #ffffff;
            padding: 8px 18px;
            border-radius: 30px;
            font-size: 0.88rem;
            font-weight: 700;
            z-index: 9999;
            box-shadow: 0 4px 15px rgba(0,0,0,0.25);
        }

        /* 小尺寸手機 RWD */
        @media (max-width: 767.98px) {
            body { padding-bottom: 76px; }
            #mapContainer { height: 190px; }
            .card-modern-body { padding: 12px; }
            .mobile-bottom-bar {
                display: flex !important;
                position: fixed; bottom: 0; left: 0; right: 0; z-index: 1010;
                background: #ffffff; border-top: 1px solid #e2e8f0;
                box-shadow: 0 -4px 16px rgba(0, 0, 0, 0.08);
                padding: 8px 12px;
                padding-bottom: calc(8px + env(safe-area-inset-bottom, 0px));
                gap: 8px;
            }
            .mobile-bottom-bar .btn {
                flex: 1; font-weight: 700; padding: 10px 8px; border-radius: 8px;
                font-size: 14px; display: flex; align-items: center; justify-content: center;
            }
        }
        @media (min-width: 768px) {
            .mobile-bottom-bar { display: none !important; }
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
                    <i class="fas fa-paper-plane mr-1 text-white"></i> 道路髒污破損 - 派工通報與路平編號綁定
                </h1>
            </div>
            <div class="d-flex align-items-center gap-2">
                <a v-if="form.rdmCaseId" :href="'https://rdm.ntpc.gov.tw/ROAD/SatisfySurvey.aspx?id=' + encodeURIComponent(form.rdmCaseId)" target="_blank" class="nav-btn" title="開啟新北市路平報馬仔網頁">
                    <i class="fas fa-external-link-alt"></i>
                    <span class="d-none d-md-inline">路平案件 ({{ form.rdmCaseId }})</span>
                </a>
                <span class="badge badge-light px-2 py-1 font-weight-bold text-dark ml-1">
                    {{ form.useRdmAsShowId && form.rdmCaseId ? form.rdmCaseId : (caseData.Show_ID || '待派工') }}
                </span>
            </div>
        </header>

        <!-- 主體內容區 -->
        <main class="container-fluid py-3 px-md-4">
            <!-- 載入中骨架屏 -->
            <div v-if="loading" class="text-center py-5">
                <i class="fas fa-spinner fa-spin fa-2x text-primary mb-3"></i>
                <div class="text-muted font-weight-bold">正在載入通報案件與單位資料，請稍候...</div>
            </div>

            <!-- 錯誤提示 -->
            <div v-else-if="errorMessage" class="alert alert-danger shadow-sm">
                <i class="fas fa-exclamation-triangle mr-2"></i> {{ errorMessage }}
                <div class="mt-2">
                    <button type="button" class="btn btn-sm btn-outline-danger" v-on:click="loadInitData">重試載入</button>
                    <a :href="'BreakDetail.aspx?id=' + encodeURIComponent(breakId)" class="btn btn-sm btn-secondary ml-2">返回明細</a>
                </div>
            </div>

            <div v-else class="row">
                <!-- 左欄：案件通報項目概況 (附一鍵複製，方便貼至路平報馬仔系統) -->
                <div class="col-12 col-lg-5 col-xl-4 mb-3">
                    <!-- 通報項目卡片 -->
                    <div class="card-modern">
                        <div class="card-modern-header">
                            <h2 class="card-modern-title">
                                <i class="fas fa-clipboard-list text-primary"></i> 通報項目資料 (供轉報複製)
                            </h2>
                            <button type="button" class="btn btn-xs btn-outline-primary btn-sm py-1 px-2 font-weight-bold" v-on:click="copyAllReportSummary" title="複製全部通報資訊">
                                <i class="fas fa-copy mr-1"></i>複製全套摘要
                            </button>
                        </div>
                        <div class="card-modern-body">
                            <div class="row no-gutters">
                                <div class="col-6 pr-1">
                                    <div class="stat-chip">
                                        <div class="stat-chip-header">
                                            <span class="stat-chip-label">路面損壞-類別</span>
                                        </div>
                                        <div class="stat-chip-val text-primary">{{ caseData.Damage_Category || '路面損壞' }}</div>
                                    </div>
                                </div>
                                <div class="col-6 pl-1">
                                    <div class="stat-chip">
                                        <div class="stat-chip-header">
                                            <span class="stat-chip-label">路面損壞-性質</span>
                                        </div>
                                        <div class="stat-chip-val text-danger">
                                            {{ caseData.Damage_Type || '坑洞' }}
                                            <small v-if="caseData.Damage_Length || caseData.Damage_Width" class="text-muted">
                                                ({{ caseData.Damage_Length || 0 }}x{{ caseData.Damage_Width || 0 }}m)
                                            </small>
                                        </div>
                                    </div>
                                </div>

                                <div class="col-4 pr-1">
                                    <div class="stat-chip">
                                        <div class="stat-chip-header">
                                            <span class="stat-chip-label">所屬區</span>
                                        </div>
                                        <div class="stat-chip-val">{{ caseData.TOWN_NA || '未填寫' }}</div>
                                    </div>
                                </div>
                                <div class="col-8 pl-1">
                                    <div class="stat-chip">
                                        <div class="stat-chip-header">
                                            <span class="stat-chip-label">地址、路段或地標</span>
                                            <button type="button" class="btn-copy-mini" v-on:click="copyText(caseData.ROAD_Name, '地址、路段或地標')">
                                                <i class="fas fa-copy"></i> 複製
                                            </button>
                                        </div>
                                        <div class="stat-chip-val">{{ caseData.ROAD_Name || '未填寫' }}</div>
                                    </div>
                                </div>

                                <div class="col-12">
                                    <div class="stat-chip">
                                        <div class="stat-chip-header">
                                            <span class="stat-chip-label">地點描述</span>
                                            <button v-if="caseData.Location_Desc" type="button" class="btn-copy-mini" v-on:click="copyText(caseData.Location_Desc, '地點描述')">
                                                <i class="fas fa-copy"></i> 複製
                                            </button>
                                        </div>
                                        <div class="stat-chip-val">{{ caseData.Location_Desc || '無補充描述' }}</div>
                                    </div>
                                </div>

                                <div class="col-6 pr-1">
                                    <div class="stat-chip">
                                        <div class="stat-chip-header">
                                            <span class="stat-chip-label">坐標X (TWD97)</span>
                                            <button v-if="caseData.S_UTME" type="button" class="btn-copy-mini" v-on:click="copyText(caseData.S_UTME, '坐標X')">
                                                <i class="fas fa-copy"></i> 複製
                                            </button>
                                        </div>
                                        <div class="stat-chip-val">{{ caseData.S_UTME || '-' }}</div>
                                    </div>
                                </div>
                                <div class="col-6 pl-1">
                                    <div class="stat-chip">
                                        <div class="stat-chip-header">
                                            <span class="stat-chip-label">坐標Y (TWD97)</span>
                                            <button v-if="caseData.S_UTMN" type="button" class="btn-copy-mini" v-on:click="copyText(caseData.S_UTMN, '坐標Y')">
                                                <i class="fas fa-copy"></i> 複製
                                            </button>
                                        </div>
                                        <div class="stat-chip-val">{{ caseData.S_UTMN || '-' }}</div>
                                    </div>
                                </div>

                                <div class="col-4 pr-1">
                                    <div class="stat-chip">
                                        <div class="stat-chip-label">車道</div>
                                        <div class="stat-chip-val">{{ caseData.Lane_Info || '全車道' }}</div>
                                    </div>
                                </div>
                                <div class="col-4 px-1">
                                    <div class="stat-chip">
                                        <div class="stat-chip-label">方向</div>
                                        <div class="stat-chip-val">{{ caseData.Direction || '無法判定' }}</div>
                                    </div>
                                </div>
                                <div class="col-4 pl-1">
                                    <div class="stat-chip">
                                        <div class="stat-chip-label">道路型態</div>
                                        <div class="stat-chip-val">{{ caseData.Road_Type || '平面' }}</div>
                                    </div>
                                </div>

                                <div class="col-12" v-if="caseData.Memo">
                                    <div class="stat-chip mb-0">
                                        <div class="stat-chip-header">
                                            <span class="stat-chip-label">其他說明</span>
                                            <button type="button" class="btn-copy-mini" v-on:click="copyText(caseData.Memo, '其他說明')">
                                                <i class="fas fa-copy"></i> 複製
                                            </button>
                                        </div>
                                        <div class="stat-chip-val">{{ caseData.Memo }}</div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- 地理位置地圖卡片 -->
                    <div class="card-modern">
                        <div class="card-modern-header">
                            <h2 class="card-modern-title">
                                <i class="fas fa-map-marked-alt text-success"></i> 現場位置地圖
                            </h2>
                            <div class="d-flex align-items-center gap-1">
                                <button v-if="caseData.Lat && caseData.Lng" type="button" class="btn btn-sm btn-outline-info py-0 px-2 mr-1" v-on:click="copyText(caseData.Lng.toFixed(6) + ', ' + caseData.Lat.toFixed(6), '經緯度坐標')">
                                    <i class="fas fa-copy mr-1"></i>經緯度
                                </button>
                                <button v-if="caseData.Lat && caseData.Lng" type="button" class="btn btn-sm btn-outline-success py-0 px-2" v-on:click="openGoogleMaps" title="以 Google Maps 開啟位置導航">
                                    <i class="fas fa-location-arrow mr-1"></i>導航
                                </button>
                            </div>
                        </div>
                        <div class="card-modern-body p-2">
                            <div id="mapContainer"></div>
                            <div class="text-muted small mt-2 d-flex justify-content-between px-1 flex-wrap">
                                <span>TWD97: {{ caseData.S_UTME }}, {{ caseData.S_UTMN }}</span>
                                <span v-if="caseData.Lat">WGS84: {{ caseData.Lng.toFixed(6) }}, {{ caseData.Lat.toFixed(6) }}</span>
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

                <!-- 右欄：路平報馬仔編號綁定與派工處理作業 -->
                <div class="col-12 col-lg-7 col-xl-8 mb-3">
                    <div class="card-modern">
                        <div class="card-modern-header bg-light">
                            <h2 class="card-modern-title">
                                <i class="fas fa-tasks text-primary"></i> 路平報馬仔編號綁定與派工通報作業
                            </h2>
                            <span class="text-muted small">
                                <i class="fas fa-user-edit mr-1"></i>通報人員：<strong>{{ caseData.S_UserName }}</strong>
                            </span>
                        </div>
                        <div class="card-modern-body">
                            <form v-on:submit.prevent="submitDispatch">
                                <!-- 專區一：新北市路平報馬仔反映編號綁定區 -->
                                <div class="rdm-bind-box">
                                    <div class="rdm-bind-title">
                                        <span>
                                            <i class="fas fa-link mr-1"></i> 綁定「新北市路平報馬仔系統」反映編號 (id)
                                        </span>
                                        <a v-if="form.rdmCaseId" :href="'https://rdm.ntpc.gov.tw/ROAD/SatisfySurvey.aspx?id=' + encodeURIComponent(form.rdmCaseId)" target="_blank" class="btn btn-sm btn-primary font-weight-bold shadow-sm py-1 px-3">
                                            <i class="fas fa-external-link-alt mr-1"></i> 開啟路平報馬仔案件 ({{ form.rdmCaseId }})
                                        </a>
                                        <a v-else href="https://rdm.ntpc.gov.tw/" target="_blank" class="btn btn-sm btn-outline-primary font-weight-bold bg-white py-1 px-3">
                                            <i class="fas fa-external-link-alt mr-1"></i> 前往路平報馬仔系統
                                        </a>
                                    </div>

                                    <div class="row align-items-center">
                                        <div class="col-12 col-md-7 mb-2 mb-md-0">
                                            <div class="input-group">
                                                <div class="input-group-prepend">
                                                    <span class="input-group-text bg-white font-weight-bold text-primary border-info">id =</span>
                                                </div>
                                                <input type="text" v-model.trim="form.rdmCaseId" v-on:input="onRdmInput" class="form-control border-info font-weight-bold" style="font-size: 1rem;" placeholder="輸入反映編號 (如 2078092) 或直接貼上路平網址..." />
                                            </div>
                                        </div>
                                        <div class="col-12 col-md-5">
                                            <div class="custom-control custom-checkbox">
                                                <input type="checkbox" class="custom-control-input" id="chkUseRdmId" v-model="form.useRdmAsShowId" />
                                                <label class="custom-control-label font-weight-bold text-dark" for="chkUseRdmId" style="cursor:pointer;">
                                                    同步設為本系統案件編號 (Show_ID)
                                                </label>
                                            </div>
                                        </div>
                                    </div>
                                    <small class="text-secondary d-block mt-2">
                                        <i class="fas fa-lightbulb text-warning mr-1"></i>
                                        提示：於路平報馬仔完成通報取得核發編號（例如 <code>2078092</code>）後填入此處；後續於「處理回報」頁面即可<strong>一鍵自動抓取工務局回覆文字與完工照片</strong>！
                                    </small>
                                </div>

                                <!-- 專區二：通報單位與權責處理單位 (支援輸入修改與自行填寫) -->
                                <div class="row">
                                    <div class="col-12 col-md-6 mb-3">
                                        <div class="d-flex align-items-center justify-content-between mb-1">
                                            <label class="font-weight-bold text-dark mb-0">
                                                <span class="text-danger">*</span> 通報單位：
                                            </label>
                                            <a href="javascript:void(0);" class="badge badge-light border text-primary" v-on:click="form.sCom = '新北市環保局空噪科(逸散計畫)'" title="點擊帶入預設單位">
                                                <i class="fas fa-magic mr-1"></i>帶入預設單位
                                            </a>
                                        </div>
                                        <input type="text" v-model.trim="form.sCom" class="form-control font-weight-bold" placeholder="請輸入通報單位 (預設: 新北市環保局空噪科(逸散計畫))" required />
                                        <small class="form-text text-muted">發出通報之權責機關或委辦單位，可依實際需求修改</small>
                                    </div>

                                    <div class="col-12 col-md-6 mb-3">
                                        <div class="d-flex align-items-center justify-content-between mb-1">
                                            <label class="font-weight-bold text-dark mb-0">
                                                <span class="text-danger">*</span> 處理單位（本平台派工對象）：
                                            </label>
                                            <a href="javascript:void(0);" class="small font-weight-bold text-primary" v-on:click="toggleCustomGCom">
                                                <i class="fas" :class="isCustomGCom ? 'fa-list-ul mr-1' : 'fa-pen mr-1'"></i>
                                                {{ isCustomGCom ? '切換為清單選取' : '自行填寫處理單位' }}
                                            </a>
                                        </div>

                                        <!-- 模式 A：下拉選單選取 (預設) -->
                                        <div v-if="!isCustomGCom">
                                            <select v-model="form.gCom" v-on:change="onHandleUnitChange" class="form-control font-weight-bold" required>
                                                <option value="">&lt;請選擇處理單位&gt;</option>
                                                <option v-for="u in handleUnits" :key="u.UnitID" :value="u.UnitID">
                                                    {{ u.UnitName }}
                                                </option>
                                                <option value="__CUSTOM__">【＋ 自行填寫其他處理單位...】</option>
                                            </select>
                                        </div>

                                        <!-- 模式 B：自行填寫輸入框 -->
                                        <div v-else class="input-group">
                                            <input type="text" v-model.trim="form.customGComName" class="form-control font-weight-bold" placeholder="請輸入處理單位名稱（例如：交通局、水利局、私人產權機關...）" v-on:input="onCustomGComInput" required />
                                            <div class="input-group-append">
                                                <button type="button" class="btn btn-outline-secondary" v-on:click="cancelCustomGCom" title="返回下拉清單">
                                                    <i class="fas fa-undo mr-1"></i>清單
                                                </button>
                                            </div>
                                        </div>
                                        <small class="form-text text-muted">
                                            受理想改善通報並負責回報之機關單位（支援清單選取或自行填寫）
                                        </small>
                                    </div>
                                </div>

                                <!-- 專區三：對標路平系統之處理單位附加資訊 -->
                                <div class="row bg-light rounded p-2 mb-3 mx-0 border">
                                    <div class="col-12 col-md-4 mb-2 mb-md-0">
                                        <label class="small font-weight-bold text-secondary mb-1">處理單位(公所)：</label>
                                        <input type="text" v-model.trim="form.districtOffice" class="form-control form-control-sm" placeholder="例如：石門區公所" />
                                    </div>
                                    <div class="col-12 col-md-4 mb-2 mb-md-0">
                                        <label class="small font-weight-bold text-secondary mb-1">處理單位(開口廠商/機關)：</label>
                                        <input type="text" v-model.trim="form.handleUnit" class="form-control form-control-sm" placeholder="例如：健利營造有限公司" />
                                    </div>
                                    <div class="col-12 col-md-4">
                                        <label class="small font-weight-bold text-secondary mb-1">處理狀態：</label>
                                        <input type="text" v-model.trim="form.handleStatus" class="form-control form-control-sm" placeholder="例如：機關自行修補" />
                                    </div>
                                </div>

                                <!-- 專區四：處理單位承辦人通訊清單卡片 (含連絡電話與 Email) -->
                                <div class="card border-info mb-3">
                                    <div class="card-header bg-info text-white py-2 d-flex justify-content-between align-items-center">
                                        <span class="font-weight-bold">
                                            <i class="fas fa-address-book mr-1"></i> 處理單位承辦人員通訊資訊 (連絡電話 / 電子信箱)
                                        </span>
                                        <div class="d-flex align-items-center gap-2">
                                            <span v-if="unitUsersLoading" class="badge badge-light mr-2">
                                                <i class="fas fa-spinner fa-spin mr-1"></i>讀取中
                                            </span>
                                            <button type="button" class="btn btn-sm btn-light text-info font-weight-bold py-0 px-2" v-on:click="openAddUserModal" :disabled="!form.gCom">
                                                <i class="fas fa-user-plus mr-1"></i>新增聯絡人
                                            </button>
                                        </div>
                                    </div>
                                    <div class="card-body p-0">
                                        <div v-if="!form.gCom" class="p-3 text-muted text-center small">
                                            <i class="fas fa-info-circle mr-1"></i>請先選取或自行填寫「處理單位」，系統將自動帶出或允許建立該單位承辦人員電話與信箱。
                                        </div>
                                        <div v-else-if="unitUsers.length === 0" class="p-3 bg-light">
                                            <div class="alert alert-warning py-2 px-3 small mb-2 font-weight-bold">
                                                <i class="fas fa-info-circle mr-1"></i>此處理單位目前尚未建立承辦人員名冊。您可直接在下方填寫承辦人聯絡資訊並點擊【儲存新增】：
                                            </div>
                                            <div class="form-row align-items-center">
                                                <div class="col-12 col-md-3 mb-2 mb-md-0">
                                                    <input type="text" v-model.trim="newUser.name" class="form-control form-control-sm" placeholder="* 承辦人姓名 (如: 陳專員)" />
                                                </div>
                                                <div class="col-12 col-md-3 mb-2 mb-md-0">
                                                    <input type="text" v-model.trim="newUser.userTel" class="form-control form-control-sm" placeholder="連絡電話 (如: 02-29603456)" />
                                                </div>
                                                <div class="col-12 col-md-4 mb-2 mb-md-0">
                                                    <input type="email" v-model.trim="newUser.userEmail" class="form-control form-control-sm" placeholder="電子信箱 Email" />
                                                </div>
                                                <div class="col-12 col-md-2">
                                                    <button type="button" class="btn btn-sm btn-info btn-block font-weight-bold" v-on:click="submitNewUser" :disabled="newUserSubmitting">
                                                        <i class="fas" :class="newUserSubmitting ? 'fa-spinner fa-spin mr-1' : 'fa-plus mr-1'"></i>儲存新增
                                                    </button>
                                                </div>
                                            </div>
                                        </div>
                                        <div v-else class="table-responsive mb-0">
                                            <table class="table table-sm table-striped user-table mb-0">
                                                <thead class="thead-light">
                                                    <tr>
                                                        <th style="width: 140px;">承辦人員</th>
                                                        <th style="width: 220px;">
                                                            <i class="fas fa-phone-alt text-secondary mr-1"></i>連絡電話
                                                        </th>
                                                        <th>
                                                            <i class="fas fa-envelope text-secondary mr-1"></i>電子郵件信箱 (Email)
                                                        </th>
                                                        <th style="width: 90px;" class="text-center">操作</th>
                                                    </tr>
                                                </thead>
                                                <tbody>
                                                    <tr v-for="user in unitUsers" :key="user.RunUser">
                                                        <td class="font-weight-bold text-dark align-middle">
                                                            <i class="fas fa-user-circle mr-1 text-secondary"></i>
                                                            {{ user.Name }}
                                                        </td>
                                                        <td class="align-middle">
                                                            <input type="text" v-model.trim="user.UserTel" class="form-control form-control-sm" placeholder="例如: 02-29603456#1234 或 0912-345678" />
                                                        </td>
                                                        <td class="align-middle">
                                                            <input type="email" v-model.trim="user.UserEmail" class="form-control form-control-sm" placeholder="請輸入 Email (例如: user@ntpc.gov.tw)" />
                                                        </td>
                                                        <td class="text-center align-middle">
                                                            <button type="button" class="btn btn-sm btn-outline-primary py-0 px-2" v-on:click="saveUserContact(user)" :disabled="user.saving">
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
                                        <i class="fas fa-info-circle mr-1"></i>送出派工時，系統將自動向清單中設定之電子信箱發送改善通報單（含路平案件連結），並將連絡電話同步保存於派工紀錄中。
                                    </div>
                                </div>

                                <!-- 專區五：養工處分派說明 / 通報補充說明 -->
                                <div class="row">
                                    <div class="col-12 col-md-6 mb-3">
                                        <label class="font-weight-bold text-dark">
                                            <i class="fas fa-building mr-1 text-secondary"></i> 養工處分派說明 (選填)：
                                        </label>
                                        <textarea v-model="form.dispatchMemo" class="form-control" rows="3" placeholder="對標路平系統之【養工處分派說明】欄位..."></textarea>
                                    </div>
                                    <div class="col-12 col-md-6 mb-3">
                                        <label class="font-weight-bold text-dark">
                                            <i class="fas fa-comment-alt mr-1 text-secondary"></i> 其他說明 / 通報補充說明：
                                        </label>
                                        <textarea v-model="form.memo" class="form-control" rows="3" placeholder="請填寫通報補充說明或外勤現況備註..."></textarea>
                                    </div>
                                </div>

                                <!-- 桌面版動作按鈕列 -->
                                <div class="d-none d-md-flex flex-wrap align-items-center justify-content-end border-top pt-3 mt-2">
                                    <a :href="'BreakDetail.aspx?id=' + encodeURIComponent(breakId)" class="btn btn-secondary mr-2 font-weight-bold px-4">
                                        <i class="fas fa-times mr-1"></i> 取消返回
                                    </a>
                                    <button type="submit" class="btn btn-primary font-weight-bold px-5 shadow-sm" :disabled="submitting">
                                        <span v-if="submitting">
                                            <i class="fas fa-spinner fa-spin mr-1"></i> 儲存派工中...
                                        </span>
                                        <span v-else>
                                            <i class="fas fa-paper-plane mr-1"></i> 確認綁定編號並送出派工
                                        </span>
                                    </button>
                                </div>
                            </form>
                        </div>
                    </div>
                </div>
            </div>
        </main>

        <!-- 手機端常駐懸浮操作列 -->
        <nav class="mobile-bottom-bar d-md-none" v-if="!loading && !errorMessage">
            <a :href="'BreakDetail.aspx?id=' + encodeURIComponent(breakId)" class="btn btn-outline-secondary">
                <i class="fas fa-arrow-left mr-1"></i>返回
            </a>
            <button type="button" class="btn btn-primary" style="flex: 2;" :disabled="submitting" v-on:click="submitDispatch">
                <i class="fas fa-paper-plane mr-1" :class="{ 'fa-spin': submitting }"></i>
                {{ submitting ? '儲存中...' : '確認綁定並送出派工' }}
            </button>
        </nav>

        <!-- 複製成功 Toast -->
        <div v-if="copyToastMsg" class="copy-toast">
            <i class="fas fa-check-circle text-success mr-1"></i> {{ copyToastMsg }}
        </div>

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

        <!-- 新增處理單位承辦聯絡人彈窗 (純 Vue 自製，零外部相依) -->
        <div v-if="showAddUserModal" class="modal-backdrop-custom" v-on:click="showAddUserModal = false">
            <div class="modal-dialog-custom" v-on:click.stop>
                <div class="modal-header-custom bg-info text-white">
                    <h5 class="m-0 font-weight-bold" style="font-size: 1.05rem;">
                        <i class="fas fa-user-plus mr-1"></i> 新增承辦人員聯絡資料
                    </h5>
                    <button type="button" class="close text-white" v-on:click="showAddUserModal = false">&times;</button>
                </div>
                <div class="modal-body-custom">
                    <div class="form-group mb-2">
                        <label class="small font-weight-bold text-secondary mb-1">所屬處理單位：</label>
                        <input type="text" :value="currentHandleUnitDisplayName" class="form-control form-control-sm bg-light" readonly />
                    </div>
                    <div class="form-group mb-2">
                        <label class="small font-weight-bold text-dark mb-1">
                            <span class="text-danger">*</span> 承辦人員姓名：
                        </label>
                        <input type="text" v-model.trim="newUser.name" class="form-control form-control-sm" placeholder="請輸入承辦人姓名或職稱 (例如: 陳專員)" />
                    </div>
                    <div class="form-group mb-2">
                        <label class="small font-weight-bold text-dark mb-1">
                            連絡電話：
                        </label>
                        <input type="text" v-model.trim="newUser.userTel" class="form-control form-control-sm" placeholder="例如: 02-29603456 分機 1234 或 0912-345678" />
                    </div>
                    <div class="form-group mb-2">
                        <label class="small font-weight-bold text-dark mb-1">
                            電子信箱 (Email)：
                        </label>
                        <input type="email" v-model.trim="newUser.userEmail" class="form-control form-control-sm" placeholder="例如: contact@ntpc.gov.tw" />
                    </div>
                </div>
                <div class="modal-footer-custom">
                    <button type="button" class="btn btn-sm btn-secondary" v-on:click="showAddUserModal = false">取消</button>
                    <button type="button" class="btn btn-sm btn-info font-weight-bold px-3" v-on:click="submitNewUser" :disabled="newUserSubmitting">
                        <i class="fas" :class="newUserSubmitting ? 'fa-spinner fa-spin mr-1' : 'fa-check mr-1'"></i>
                        {{ newUserSubmitting ? '新增中...' : '確認新增' }}
                    </button>
                </div>
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
                    unitUsersLoading: false,
                    copyToastMsg: '',
                    showAddUserModal: false,
                    isCustomGCom: false,
                    newUser: {
                        name: '',
                        userTel: '',
                        userEmail: ''
                    },
                    newUserSubmitting: false,

                    caseData: {},
                    reportUnits: [],
                    handleUnits: [],
                    photos: [],
                    unitUsers: [],

                    form: {
                        rdmCaseId: '',
                        useRdmAsShowId: true,
                        sCom: '新北市環保局空噪科(逸散計畫)',
                        gCom: '',
                        customGComName: '',
                        districtOffice: '',
                        handleUnit: '',
                        handleStatus: '機關自行修補',
                        dispatchMemo: '',
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
            computed: {
                currentHandleUnitDisplayName() {
                    if (this.isCustomGCom) {
                        return this.form.customGComName || '自訂處理單位';
                    }
                    const found = (this.handleUnits || []).find(u => u.UnitID === this.form.gCom);
                    return found ? found.UnitName : (this.form.gCom || '未選取處理單位');
                }
            },
            mounted() {
                if (!this.breakId) {
                    this.loading = false;
                    this.errorMessage = '缺少案件編號參數 (id)，無法載入派工頁面。';
                    return;
                }
                this.loadInitData();
            },
            methods: {
                loadInitData() {
                    this.loading = true;
                    this.errorMessage = '';

                    axios.get('SetSG_Break.aspx', {
                        params: {
                            action: 'init',
                            id: this.breakId,
                            _t: Date.now()
                        }
                    })
                    .then(res => {
                        this.loading = false;
                        const data = res.data;
                        if (data && data.NeedLogin) {
                            window.location.href = '../Default.aspx';
                            return;
                        }
                        if (!data || !data.Success) {
                            this.errorMessage = (data && data.Message) ? data.Message : '載入案件資料失敗。';
                            return;
                        }

                        this.caseData = data.Case || {};
                        this.reportUnits = data.ReportUnits || [];
                        this.handleUnits = data.HandleUnits || [];
                        this.photos = data.Photos || [];

                        // 帶入預設值 (通報單位預設為新北市環保局空噪科(逸散計畫))
                        this.form.rdmCaseId = this.caseData.RDM_Case_ID || '';
                        this.form.sCom = this.caseData.S_COM || '新北市環保局空噪科(逸散計畫)';
                        this.form.gCom = this.caseData.G_COM || (this.handleUnits.length > 0 ? this.handleUnits[0].UnitID : '');

                        // 若既有 G_COM 不在預設下拉清單中，自動切換至自訂處理單位模式
                        if (this.form.gCom && !this.handleUnits.some(u => u.UnitID === this.form.gCom)) {
                            this.isCustomGCom = true;
                            this.form.customGComName = this.form.gCom;
                        }
                        this.form.districtOffice = this.caseData.District_Office || (this.caseData.TOWN_NA ? this.caseData.TOWN_NA + '公所' : '');
                        this.form.handleUnit = this.caseData.Handle_Unit || '';
                        this.form.handleStatus = this.caseData.Handle_Status || '機關自行修補';
                        this.form.dispatchMemo = this.caseData.Dispatch_Memo || '';
                        this.form.memo = this.caseData.Memo || '';

                        if (this.form.gCom) {
                            this.loadUnitUsers(this.form.gCom);
                        }

                        this.$nextTick(() => {
                            this.initMap();
                        });
                    })
                    .catch(err => {
                        this.loading = false;
                        this.errorMessage = '網路連線異常，無法讀取派工資料：' + (err.message || '');
                    });
                },

                // 當輸入路平報馬仔編號或貼上整串網址時，自動萃取 id 參數
                onRdmInput() {
                    const val = this.form.rdmCaseId || '';
                    if (val.indexOf('id=') >= 0) {
                        const m = val.match(/[?&]id=(\d+)/i);
                        if (m && m[1]) {
                            this.form.rdmCaseId = m[1];
                        }
                    }
                },

                // 一鍵複製單一欄位文字
                copyText(text, label) {
                    if (!text) return;
                    if (navigator.clipboard && navigator.clipboard.writeText) {
                        navigator.clipboard.writeText(String(text)).then(() => {
                            this.showToast('已複製【' + label + '】：' + text);
                        });
                    } else {
                        const ta = document.createElement('textarea');
                        ta.value = String(text);
                        document.body.appendChild(ta);
                        ta.select();
                        document.execCommand('copy');
                        document.body.removeChild(ta);
                        this.showToast('已複製【' + label + '】：' + text);
                    }
                },

                // 複製全套通報摘要
                copyAllReportSummary() {
                    const c = this.caseData;
                    const lines = [
                        '【路面損壞-類別】' + (c.Damage_Category || '路面損壞'),
                        '【路面損壞-性質】' + (c.Damage_Type || '坑洞') + ' (長:' + (c.Damage_Length || 0) + 'm, 寬:' + (c.Damage_Width || 0) + 'm)',
                        '【所屬區】' + (c.TOWN_NA || ''),
                        '【地址、路段或地標】' + (c.ROAD_Name || ''),
                        '【地點描述】' + (c.Location_Desc || ''),
                        '【坐標X/Y】X=' + (c.S_UTME || '') + ', Y=' + (c.S_UTMN || ''),
                        '【車道/方向/型態】' + (c.Lane_Info || '') + ' / ' + (c.Direction || '') + ' / ' + (c.Road_Type || ''),
                        '【其他說明】' + (c.Memo || '')
                    ];
                    this.copyText(lines.join('\r\n'), '全套通報摘要');
                },

                showToast(msg) {
                    this.copyToastMsg = msg;
                    setTimeout(() => {
                        this.copyToastMsg = '';
                    }, 2200);
                },

                toggleCustomGCom() {
                    this.isCustomGCom = !this.isCustomGCom;
                    if (this.isCustomGCom) {
                        if (!this.form.customGComName && this.form.gCom && this.form.gCom !== '__CUSTOM__') {
                            const found = (this.handleUnits || []).find(u => u.UnitID === this.form.gCom);
                            this.form.customGComName = found ? found.UnitName : this.form.gCom;
                        }
                        this.form.gCom = this.form.customGComName || '';
                        if (!this.form.handleUnit) {
                            this.form.handleUnit = this.form.customGComName || '';
                        }
                        this.loadUnitUsers(this.form.gCom);
                    } else {
                        this.form.gCom = this.handleUnits.length > 0 ? this.handleUnits[0].UnitID : '';
                        this.onHandleUnitChange();
                    }
                },

                onCustomGComInput() {
                    this.form.gCom = this.form.customGComName;
                    if (!this.form.handleUnit || this.form.handleUnit === this.form.districtOffice) {
                        this.form.handleUnit = this.form.customGComName;
                    }
                    this.loadUnitUsers(this.form.gCom);
                },

                cancelCustomGCom() {
                    this.isCustomGCom = false;
                    this.form.gCom = this.handleUnits.length > 0 ? this.handleUnits[0].UnitID : '';
                    this.onHandleUnitChange();
                },

                onHandleUnitChange() {
                    if (this.form.gCom === '__CUSTOM__') {
                        this.toggleCustomGCom();
                        return;
                    }
                    // 同步預設處理單位名稱
                    const found = this.handleUnits.find(u => u.UnitID === this.form.gCom);
                    if (found && !this.form.handleUnit) {
                        this.form.handleUnit = found.UnitName;
                    }
                    this.loadUnitUsers(this.form.gCom);
                },

                loadUnitUsers(unitId) {
                    if (!unitId) {
                        this.unitUsers = [];
                        return;
                    }
                    this.unitUsersLoading = true;
                    axios.get('SetSG_Break.aspx', {
                        params: {
                            action: 'getunitusers',
                            unitId: unitId,
                            _t: Date.now()
                        }
                    })
                    .then(res => {
                        this.unitUsersLoading = false;
                        if (res.data && res.data.Success) {
                            this.unitUsers = (res.data.Users || []).map(u => ({
                                ...u,
                                UserTel: u.UserTel || '',
                                saving: false
                            }));
                        }
                    })
                    .catch(() => {
                        this.unitUsersLoading = false;
                    });
                },

                saveUserContact(user) {
                    user.saving = true;
                    axios.post('SetSG_Break.aspx?action=updateusercontact', {
                        UnitID: this.form.gCom,
                        RunUser: user.RunUser,
                        UserEmail: user.UserEmail,
                        UserTel: user.UserTel
                    })
                    .then(res => {
                        user.saving = false;
                        if (res.data && res.data.Success) {
                            this.showToast('已更新 [' + user.Name + '] 的電話與信箱');
                        } else {
                            alert((res.data && res.data.Message) ? res.data.Message : '更新資料失敗。');
                        }
                    })
                    .catch(err => {
                        user.saving = false;
                        alert('儲存發生錯誤：' + (err.message || ''));
                    });
                },

                saveUserEmail(user) {
                    this.saveUserContact(user);
                },

                openAddUserModal() {
                    if (!this.form.gCom && this.form.districtOffice) {
                        this.form.gCom = this.form.districtOffice;
                    }
                    if (!this.form.gCom) {
                        alert('請先選擇或填寫「處理單位」');
                        return;
                    }
                    this.newUser = { name: '', userTel: '', userEmail: '' };
                    this.showAddUserModal = true;
                },

                submitNewUser() {
                    if (!this.newUser.name) {
                        alert('請填寫承辦人員姓名');
                        return;
                    }
                    const currentUnit = this.form.gCom || this.form.districtOffice || this.form.handleUnit;
                    if (!currentUnit) {
                        alert('請先選擇或填寫「處理單位」');
                        return;
                    }
                    this.newUserSubmitting = true;
                    axios.post('SetSG_Break.aspx?action=addunituser&unitId=' + encodeURIComponent(currentUnit), {
                        Name: this.newUser.name,
                        UserTel: this.newUser.userTel,
                        UserEmail: this.newUser.userEmail
                    })
                    .then(res => {
                        this.newUserSubmitting = false;
                        if (res.data && res.data.Success) {
                            this.showAddUserModal = false;
                            this.showToast('已成功新增承辦人員！');
                            this.loadUnitUsers(currentUnit);
                            this.newUser = { name: '', userTel: '', userEmail: '' };
                        } else {
                            alert((res.data && res.data.Message) ? res.data.Message : '新增承辦人員失敗。');
                        }
                    })
                    .catch(err => {
                        this.newUserSubmitting = false;
                        alert('新增發生錯誤：' + (err.message || ''));
                    });
                },

                submitDispatch() {
                    if (!this.form.sCom) {
                        alert('請選擇「通報單位」');
                        return;
                    }
                    if (!this.form.gCom) {
                        alert('請選擇「處理單位」');
                        return;
                    }

                    const confirmText = this.form.rdmCaseId
                        ? '確定要綁定路平反映編號【' + this.form.rdmCaseId + '】並送出派工通報嗎？'
                        : '確定要送出派工通報嗎？（尚未填寫路平報馬仔反映編號，系統將自動產生編號）';

                    if (!confirm(confirmText)) {
                        return;
                    }

                    const primaryUser = (this.unitUsers && this.unitUsers.length > 0) ? this.unitUsers[0] : null;

                    this.submitting = true;
                    axios.post('SetSG_Break.aspx?action=save', {
                        Break_ID: this.breakId,
                        RDM_Case_ID: this.form.rdmCaseId,
                        UseRdmAsShowId: this.form.useRdmAsShowId,
                        S_COM: this.form.sCom,
                        G_COM: this.form.gCom,
                        District_Office: this.form.districtOffice,
                        Handle_Unit: this.form.handleUnit,
                        Handle_Status: this.form.handleStatus,
                        Dispatch_Memo: this.form.dispatchMemo,
                        Memo: this.form.memo,
                        Contact_Phone: primaryUser ? (primaryUser.UserTel || '') : '',
                        Contact_Email: primaryUser ? (primaryUser.UserEmail || '') : '',
                        Contact_Name: primaryUser ? (primaryUser.Name || '') : ''
                    })
                    .then(res => {
                        this.submitting = false;
                        const data = res.data;
                        if (data && data.Success) {
                            let msg = data.Message;
                            if (data.MailStatus) {
                                msg += '\n(' + data.MailStatus + ')';
                            }
                            alert(msg);
                            window.location.href = 'BreakDetail.aspx?id=' + encodeURIComponent(this.breakId);
                        } else {
                            alert((data && data.Message) ? data.Message : '派工通報失敗。');
                        }
                    })
                    .catch(err => {
                        this.submitting = false;
                        alert('送出派工發生網路異常：' + (err.message || ''));
                    });
                },

                initMap() {
                    const container = document.getElementById('mapContainer');
                    if (!container) return;

                    const lat = (this.caseData.Lat && this.caseData.Lat > 0) ? this.caseData.Lat : 25.012;
                    const lng = (this.caseData.Lng && this.caseData.Lng > 0) ? this.caseData.Lng : 121.465;

                    if (this.leafletMap) {
                        this.leafletMap.remove();
                    }

                    this.leafletMap = L.map('mapContainer').setView([lat, lng], 16);

                    L.tileLayer('https://wmts.nlsc.gov.tw/wmts/EMAP/default/GoogleMapsCompatible/{z}/{y}/{x}', {
                        maxZoom: 19,
                        attribution: '&copy; 內政部國土測繪中心'
                    }).addTo(this.leafletMap);

                    if (this.caseData.Lat > 0 && this.caseData.Lng > 0) {
                        this.leafletMarker = L.marker([lat, lng]).addTo(this.leafletMap)
                            .bindPopup('<b>' + (this.caseData.TOWN_NA || '') + ' ' + (this.caseData.ROAD_Name || '') + '</b>')
                            .openPopup();
                    }
                },

                openGoogleMaps() {
                    if (this.caseData.Lat && this.caseData.Lng) {
                        const url = 'https://www.google.com/maps?q=' + this.caseData.Lat + ',' + this.caseData.Lng;
                        window.open(url, '_blank');
                    }
                },

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
