<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="DataInput.aspx.cs" Inherits="NTPC_FEC.Wash.DataInput" %>

<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定溢散源管理平台 - 道路認養洗/掃街里程日誌</title>

    <!-- 專屬 Favicon & 手機主畫面圖標 -->
    <link rel="shortcut icon" href="../favicon.ico" type="image/x-icon" />

    <!-- Bootstrap 4 & FontAwesome 本地化樣式依賴 -->
    <link rel="stylesheet" href="../Content/bootstrap.min.css" />
    <link rel="stylesheet" href="../Content/fontawesome/css/all.min.css" />

    <style>
        :root {
            --brand-primary: #0099e5;     /* 新北天空青藍 */
            --brand-blue: #0284c7;        /* 科技藍 */
            --brand-dark-blue: #0b1f7d;   /* 海軍深藍 */
            --brand-navy: #0f172a;        /* 標題深色 */
            --bg-canvas: #f1f5f9;         /* 頁面底色 */
            --surface: #ffffff;           /* 卡片純白底色 */
            --border-color: #e2e8f0;      /* 邊框線條 */
            --text-main: #0f172a;         /* 主要文字 */
            --text-muted: #64748b;        /* 次要說明 */
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

        /* 頂部導覽列 (新北青藍現代漸層，全載具自適應) */
        .top-navbar {
            background: linear-gradient(135deg, #0099e5 0%, #0284c7 100%);
            color: #ffffff;
            min-height: 54px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 8px 16px;
            box-shadow: 0 2px 10px rgba(0, 153, 229, 0.25);
            position: sticky;
            top: 0;
            z-index: 1020;
        }

        .top-navbar .brand-title {
            font-size: 1.05rem;
            font-weight: 700;
            margin: 0;
            display: flex;
            align-items: center;
            gap: 8px;
            line-height: 1.3;
        }

        .nav-btn {
            background: rgba(255, 255, 255, 0.18);
            border: none;
            color: #ffffff;
            font-size: 0.9rem;
            font-weight: 600;
            cursor: pointer;
            height: 34px;
            border-radius: 8px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            padding: 0 12px;
            gap: 6px;
            transition: all 0.2s;
            text-decoration: none;
            white-space: nowrap;
        }

        .nav-btn:hover {
            background-color: rgba(255, 255, 255, 0.32);
            color: #ffffff;
            text-decoration: none;
        }

        /* 針對小螢幕頂部列優化，防折行破版 */
        @media screen and (max-width: 576px) {
            .top-navbar {
                padding: 6px 10px;
                min-height: 50px;
            }
            .top-navbar .brand-title {
                font-size: 0.95rem;
                gap: 6px;
            }
            .nav-btn {
                height: 32px;
                padding: 0 8px;
                font-size: 0.82rem;
            }
            .badge-mode {
                font-size: 0.72rem !important;
                padding: 2px 6px;
            }
        }

        /* 主容器 (最大寬度 1560px 居中) */
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
            transition: border-color 0.2s;
        }

        .card-modern:hover {
            border-color: #cbd5e1;
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

        /* 桌面端左欄 Sticky 浮動 */
        @media screen and (min-width: 1200px) {
            .sticky-sidebar {
                position: sticky;
                top: 72px;
                max-height: calc(100vh - 88px);
                overflow-y: auto;
                padding-right: 4px;
            }
        }

        /* 表單標籤與快捷按鈕流動列 (避免手機版字元被擠壓折斷) */
        .form-label-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 6px;
            margin-bottom: 6px;
        }

        .form-label-row .field-title {
            margin-bottom: 0;
            font-weight: 700;
            color: var(--brand-navy);
            white-space: nowrap;
            font-size: 0.95rem;
        }

        .quick-chip-group {
            display: flex;
            flex-wrap: wrap;
            align-items: center;
            gap: 4px;
        }

        /* 快捷晶片按鈕 (加強熱區與自適應) */
        .quick-chip {
            border: 1px solid #cbd5e1;
            background: #ffffff;
            color: #334155;
            padding: 3px 10px;
            border-radius: 14px;
            font-size: 0.78rem;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.15s ease;
            display: inline-flex;
            align-items: center;
            gap: 4px;
            line-height: 1.4;
            min-height: 28px;
        }

        .quick-chip:hover {
            background: #0284c7;
            color: #ffffff;
            border-color: #0284c7;
        }

        /* 認養單位資訊晶片 */
        .fac-chip {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 10px 14px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 12px;
        }

        .fac-badge {
            background: #0284c7;
            color: #ffffff;
            font-size: 0.8rem;
            font-weight: 700;
            padding: 3px 8px;
            border-radius: 6px;
            flex-shrink: 0;
        }

        /* 下拉選單長字省略 */
        select.form-control {
            text-overflow: ellipsis;
            white-space: nowrap;
            overflow: hidden;
        }

        /* 執行方式大按鈕 (Segmented Toggle) */
        .wash-type-group {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 12px;
            margin-bottom: 16px;
        }

        .wash-type-card {
            border: 2px solid #e2e8f0;
            background: #ffffff;
            border-radius: 12px;
            padding: 14px 16px;
            text-align: center;
            cursor: pointer;
            transition: all 0.2s ease;
            position: relative;
            overflow: hidden;
        }

        .wash-type-card:hover {
            border-color: #0284c7;
            background: #f0f9ff;
        }

        .wash-type-card.active {
            border-color: #0284c7;
            background: #f0f9ff;
            box-shadow: 0 4px 14px rgba(2, 132, 199, 0.2);
        }

        .wash-type-card.active::after {
            content: "\f00c";
            font-family: "Font Awesome 5 Free";
            font-weight: 900;
            position: absolute;
            top: 6px;
            right: 8px;
            font-size: 14px;
            color: #0284c7;
        }

        .wash-type-icon {
            font-size: 2rem;
            margin-bottom: 6px;
            display: block;
        }

        .wash-type-title {
            font-size: 1.05rem;
            font-weight: 800;
            color: var(--brand-navy);
            margin: 0;
        }

        .wash-type-sub {
            font-size: 0.82rem;
            color: var(--text-muted);
            margin-top: 2px;
        }

        /* 里程統計資訊看版 (Stat Board) */
        .stat-board {
            background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
            color: #ffffff;
            border-radius: 12px;
            padding: 16px;
            margin-bottom: 16px;
            box-shadow: 0 4px 12px rgba(15, 23, 42, 0.15);
        }

        .stat-label {
            font-size: 0.85rem;
            color: #94a3b8;
            font-weight: 600;
            margin-bottom: 4px;
        }

        .stat-number {
            font-size: 2.1rem;
            font-weight: 800;
            color: #38bdf8;
            line-height: 1.1;
        }

        .stat-unit {
            font-size: 0.95rem;
            color: #cbd5e1;
            font-weight: 600;
            margin-left: 4px;
        }

        .stat-detail-row {
            display: flex;
            justify-content: space-between;
            margin-top: 12px;
            padding-top: 10px;
            border-top: 1px solid rgba(255, 255, 255, 0.12);
            font-size: 0.88rem;
        }

        /* 照片上傳與對照卡片 */
        .photo-card {
            border: 2px dashed #cbd5e1;
            border-radius: 12px;
            background: #fafafa;
            padding: 16px;
            text-align: center;
            transition: all 0.2s ease;
            position: relative;
            min-height: 250px;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
        }

        .photo-card.has-photo {
            border-style: solid;
            border-color: #e2e8f0;
            background: #ffffff;
            padding: 12px;
        }

        .photo-preview-wrap {
            width: 100%;
            height: 220px;
            border-radius: 8px;
            overflow: hidden;
            position: relative;
            cursor: pointer;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
            background: #000000;
        }

        .photo-preview-img {
            width: 100%;
            height: 100%;
            object-fit: cover;
            transition: transform 0.3s ease;
        }

        .photo-preview-wrap:hover .photo-preview-img {
            transform: scale(1.03);
        }

        .photo-badge-status {
            position: absolute;
            top: 8px;
            left: 8px;
            font-size: 0.78rem;
            font-weight: 700;
            padding: 4px 10px;
            border-radius: 6px;
            box-shadow: 0 2px 6px rgba(0,0,0,0.3);
        }

        .photo-overlay-zoom {
            position: absolute;
            bottom: 8px;
            right: 8px;
            background: rgba(0, 0, 0, 0.65);
            color: #ffffff;
            border-radius: 6px;
            padding: 4px 8px;
            font-size: 0.8rem;
        }

        .photo-meta {
            margin-top: 8px;
            width: 100%;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .photo-meta-text {
            font-size: 0.8rem;
            color: var(--text-muted);
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
            max-width: 60%;
            text-align: left;
        }

        /* 自適應上傳觸控熱區 */
        .upload-touch-zone {
            cursor: pointer;
            width: 100%;
            height: 100%;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }

        .upload-icon {
            font-size: 2.8rem;
            color: #94a3b8;
            margin-bottom: 12px;
        }

        .upload-touch-zone:hover .upload-icon {
            color: #0284c7;
        }

        /* 手機底部常駐動作列與邊距防遮擋 (徹底解決 Bottom Bar Overlap) */
        @media screen and (max-width: 991px) {
            body {
                padding-bottom: calc(96px + env(safe-area-inset-bottom, 24px)) !important;
            }

            .container-fluid-custom {
                padding-bottom: calc(96px + env(safe-area-inset-bottom, 24px)) !important;
            }

            .mobile-bottom-bar {
                display: flex;
                position: fixed;
                bottom: 0;
                left: 0;
                right: 0;
                z-index: 1010;
                background: #ffffff;
                border-top: 1px solid #cbd5e1;
                box-shadow: 0 -4px 20px rgba(0, 0, 0, 0.12);
                padding: 10px 16px;
                padding-bottom: calc(10px + env(safe-area-inset-bottom, 0px));
                gap: 12px;
            }

            .mobile-bottom-bar .btn {
                flex: 1;
                font-weight: 700;
                padding: 11px;
                border-radius: 8px;
                min-height: 46px;
                font-size: 0.98rem;
                display: flex;
                align-items: center;
                justify-content: center;
            }
        }

        /* 照片全螢幕燈箱 */
        .lightbox-modal {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(15, 23, 42, 0.92);
            z-index: 2050;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 16px;
        }

        .lightbox-content {
            max-width: 92vw;
            max-height: 90vh;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.5);
        }

        .lightbox-img {
            max-width: 100%;
            max-height: 85vh;
            object-fit: contain;
            display: block;
        }

        .lightbox-close {
            position: absolute;
            top: 16px;
            right: 20px;
            color: #ffffff;
            font-size: 1.8rem;
            background: none;
            border: none;
            cursor: pointer;
            padding: 8px;
        }
    </style>
</head>
<body>
    <div id="washApp" v-cloak>
        <!-- 頂部置頂導覽列 -->
        <header class="top-navbar">
            <div class="d-flex align-items-center flex-grow-1 overflow-hidden pr-2">
                <a href="WashList.aspx" class="nav-btn mr-2 flex-shrink-0" title="返回洗掃紀錄清單">
                    <i class="fas fa-arrow-left"></i>
                    <span class="d-none d-sm-inline">返回清單</span>
                </a>
                <div class="brand-title text-truncate">
                    <i class="fas fa-broom text-white mr-1"></i>
                    <span>道路洗掃里程日誌</span>
                    <span class="badge badge-light text-dark font-weight-bold ml-1 badge-mode">
                        {{ mode === 'edit' ? '編輯 #' + form.pIndex : '全新填報' }}
                    </span>
                </div>
            </div>

            <div class="d-flex align-items-center flex-shrink-0">
                <button type="button" class="btn btn-primary font-weight-bold d-none d-md-inline-flex align-items-center px-3" 
                        v-on:click="submitData" :disabled="saving">
                    <i v-if="saving" class="fas fa-spinner fa-spin mr-1"></i>
                    <i v-else class="fas fa-check-circle mr-1"></i>
                    <span>{{ saving ? '儲存中...' : '儲存紀錄' }}</span>
                </button>
            </div>
        </header>

        <!-- 主作業容器 -->
        <main class="container-fluid-custom">
            <!-- 提示橫幅 -->
            <div v-if="alertMessage" :class="'alert alert-' + alertType + ' alert-dismissible fade show shadow-sm'" role="alert">
                <i :class="alertType === 'success' ? 'fas fa-check-circle mr-1' : 'fas fa-exclamation-triangle mr-1'"></i>
                <strong>{{ alertMessage }}</strong>
                <button type="button" class="close" v-on:click="alertMessage = ''">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>

            <!-- 載入中骨架 -->
            <div v-if="loading" class="text-center py-5">
                <div class="spinner-border text-primary" role="status" style="width: 3rem; height: 3rem;">
                    <span class="sr-only">讀取中...</span>
                </div>
                <p class="text-muted mt-3 font-weight-bold">正在載入洗掃紀錄設定，請稍候...</p>
            </div>

            <!-- 主表單區域 -->
            <div v-else class="row">
                <!-- 左欄 40%：基本資訊與里程統計 -->
                <div class="col-12 col-xl-5">
                    <div class="sticky-sidebar">
                        <!-- 卡片 1：認養單位與基本設定 -->
                        <div class="card-modern">
                            <div class="card-modern-header">
                                <h2 class="card-modern-title">
                                    <i class="fas fa-building text-primary"></i>
                                    認養事業單位資訊
                                </h2>
                                <span class="badge badge-info" v-if="isManager">管理員模式</span>
                            </div>
                            <div class="card-modern-body">
                                <!-- 事業單位選單 (管理者可切換 / 一般用戶顯示固定晶片) -->
                                <div class="form-group" v-if="isManager">
                                    <label class="font-weight-bold text-dark mb-1">
                                        選擇認養事業單位 <span class="text-danger">*</span>
                                    </label>
                                    <select class="form-control" v-model="form.facId" v-on:change="onFacChange">
                                        <option v-for="fac in facList" :key="fac.FacId" :value="fac.FacId">
                                            {{ fac.FacName }} ({{ fac.FacId }})
                                        </option>
                                    </select>
                                </div>
                                <div class="fac-chip" v-else>
                                    <div class="pr-2 text-truncate">
                                        <div class="font-weight-bold text-dark text-truncate" style="font-size: 1.02rem;">
                                            {{ currentFacName || '未指定認養單位' }}
                                        </div>
                                        <small class="text-muted d-block mt-1">事業管制編號：{{ form.facId }}</small>
                                    </div>
                                    <span class="fac-badge">列管廠場</span>
                                </div>

                                <!-- 洗掃作業日期 -->
                                <div class="form-group">
                                    <div class="form-label-row">
                                        <label class="field-title">
                                            洗掃作業日期 <span class="text-danger">*</span>
                                        </label>
                                        <div class="quick-chip-group">
                                            <button type="button" class="quick-chip" v-on:click="setDateToday">
                                                <i class="fas fa-calendar-day"></i> 今天
                                            </button>
                                            <button type="button" class="quick-chip" v-on:click="setDateYesterday">
                                                <i class="fas fa-history"></i> 昨天
                                            </button>
                                        </div>
                                    </div>
                                    <input type="date" class="form-control" v-model="form.washDate" required />
                                </div>

                                <!-- 洗掃執行時間區間 -->
                                <div class="form-group">
                                    <div class="form-label-row">
                                        <label class="field-title">
                                            洗掃執行時間
                                        </label>
                                        <div class="quick-chip-group">
                                            <button type="button" class="quick-chip" v-on:click="setShift('morning')">
                                                早班 (08:30~12:00)
                                            </button>
                                            <button type="button" class="quick-chip" v-on:click="setShift('afternoon')">
                                                午班 (13:30~17:00)
                                            </button>
                                        </div>
                                    </div>
                                    <div class="row no-gutters align-items-center">
                                        <div class="col">
                                            <input type="time" class="form-control" v-model="form.washTimeStart" placeholder="開始時間" />
                                        </div>
                                        <div class="col-auto px-2 font-weight-bold text-muted">至</div>
                                        <div class="col">
                                            <input type="time" class="form-control" v-model="form.washTimeEnd" placeholder="結束時間" />
                                        </div>
                                    </div>
                                </div>

                                <!-- 洗掃街執行人員 -->
                                <div class="form-group mb-0">
                                    <label class="font-weight-bold text-dark mb-1">
                                        洗掃街執行人員
                                    </label>
                                    <div class="input-group">
                                        <div class="input-group-prepend">
                                            <span class="input-group-text bg-white"><i class="fas fa-user-check text-muted"></i></span>
                                        </div>
                                        <input type="text" class="form-control" v-model="form.ppl" placeholder="請輸入作業人員姓名" />
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- 卡片 2：里程統計與規格晶片 -->
                        <div class="card-modern">
                            <div class="card-modern-header">
                                <h2 class="card-modern-title">
                                    <i class="fas fa-route text-success"></i>
                                    洗掃總長度與即時里程統計
                                </h2>
                            </div>
                            <div class="card-modern-body">
                                <!-- 即時里程看版 -->
                                <div class="stat-board">
                                    <div class="stat-label">雙向洗掃總里程合計</div>
                                    <div class="d-flex align-items-baseline">
                                        <span class="stat-number">{{ totalMeters.toLocaleString() }}</span>
                                        <span class="stat-unit">公尺 ({{ totalKilometers }} 公里)</span>
                                    </div>
                                    <div class="stat-detail-row">
                                        <span>左側：<strong>{{ form.length1 || 0 }}</strong> m</span>
                                        <span>右側：<strong>{{ form.length2 || 0 }}</strong> m</span>
                                    </div>
                                </div>

                                <!-- 左側長度輸入 -->
                                <div class="form-group">
                                    <div class="form-label-row">
                                        <label class="field-title">左側洗掃長度 (公尺)</label>
                                        <div class="quick-chip-group">
                                            <button type="button" class="quick-chip" v-on:click="addLength(1, 100)">+100m</button>
                                            <button type="button" class="quick-chip" v-on:click="addLength(1, 500)">+500m</button>
                                            <button type="button" class="quick-chip" v-on:click="form.length1 = 0">歸零</button>
                                        </div>
                                    </div>
                                    <div class="input-group">
                                        <input type="number" min="0" step="1" class="form-control" v-model.number="form.length1" placeholder="請輸入左側公尺數" />
                                        <div class="input-group-append">
                                            <span class="input-group-text bg-light font-weight-bold">m</span>
                                        </div>
                                    </div>
                                </div>

                                <!-- 右側長度輸入 -->
                                <div class="form-group mb-0">
                                    <div class="form-label-row">
                                        <label class="field-title">右側洗掃長度 (公尺)</label>
                                        <div class="quick-chip-group">
                                            <button type="button" class="quick-chip" v-on:click="addLength(2, 100)">+100m</button>
                                            <button type="button" class="quick-chip" v-on:click="addLength(2, 500)">+500m</button>
                                            <button type="button" class="quick-chip" v-on:click="form.length2 = 0">歸零</button>
                                        </div>
                                    </div>
                                    <div class="input-group">
                                        <input type="number" min="0" step="1" class="form-control" v-model.number="form.length2" placeholder="請輸入右側公尺數" />
                                        <div class="input-group-append">
                                            <span class="input-group-text bg-light font-weight-bold">m</span>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- 右欄 60%：執行方式與照片對照成果 -->
                <div class="col-12 col-xl-7">
                    <!-- 卡片 3：執行方式切換 -->
                    <div class="card-modern">
                        <div class="card-modern-header">
                            <h2 class="card-modern-title">
                                <i class="fas fa-truck-monster text-primary"></i>
                                執行方式切換 (洗街 / 掃街)
                            </h2>
                        </div>
                        <div class="card-modern-body">
                            <div class="wash-type-group">
                                <div class="wash-type-card" :class="{ 'active': form.washType === '洗' }" 
                                     v-on:click="form.washType = '洗'">
                                    <span class="wash-type-icon text-primary">💧</span>
                                    <h3 class="wash-type-title">洗街作業</h3>
                                    <div class="wash-type-sub">使用高壓沖洗或洗街水車抑塵</div>
                                </div>

                                <div class="wash-type-card" :class="{ 'active': form.washType === '掃' }" 
                                     v-on:click="form.washType = '掃'">
                                    <span class="wash-type-icon text-warning">🧹</span>
                                    <h3 class="wash-type-title">掃街作業</h3>
                                    <div class="wash-type-sub">使用清掃車或人力清除路面砂石</div>
                                </div>
                            </div>
                            <small class="text-muted d-block">
                                <i class="fas fa-info-circle mr-1"></i>
                                請依據現場實際出動車輛或人力作業種類選定執行方式。
                            </small>
                        </div>
                    </div>

                    <!-- 卡片 4：現場照片對照成果 -->
                    <div class="card-modern">
                        <div class="card-modern-header">
                            <h2 class="card-modern-title">
                                <i class="fas fa-camera-retro text-info"></i>
                                現場作業照片對照成果 (洗掃前 / 洗掃後)
                            </h2>
                            <small class="text-muted">支援手機直接拍照或選圖</small>
                        </div>
                        <div class="card-modern-body">
                            <div class="row">
                                <!-- 洗掃前照片 -->
                                <div class="col-12 col-md-6 mb-3 mb-md-0">
                                    <h4 class="font-weight-bold text-dark mb-2" style="font-size: 0.95rem;">
                                        <i class="fas fa-image text-danger mr-1"></i> 洗掃前現場照片
                                    </h4>

                                    <!-- 隱藏的 File Input -->
                                    <input type="file" ref="beforeFileInput" accept="image/*" class="d-none" 
                                           v-on:change="handleFileSelected($event, 'before')" />

                                    <!-- 已有照片卡片 -->
                                    <div v-if="photos.before.previewUrl" class="photo-card has-photo">
                                        <div class="photo-preview-wrap" v-on:click="openLightbox(photos.before.previewUrl, '洗掃前照片')">
                                            <img :src="photos.before.previewUrl" class="photo-preview-img" alt="洗掃前照片" />
                                            <span class="badge badge-success photo-badge-status" v-if="photos.before.isNew">
                                                待上傳 (已選取)
                                            </span>
                                            <span class="badge badge-primary photo-badge-status" v-else>
                                                已儲存於系統
                                            </span>
                                            <span class="photo-overlay-zoom">
                                                <i class="fas fa-search-plus"></i> 點擊放大
                                            </span>
                                        </div>
                                        <div class="photo-meta">
                                            <span class="photo-meta-text">{{ photos.before.fileName || '洗掃前照片.jpg' }}</span>
                                            <div>
                                                <button type="button" class="btn btn-sm btn-outline-primary mr-1" 
                                                        v-on:click="$refs.beforeFileInput.click()">
                                                    <i class="fas fa-sync-alt"></i> 更換
                                                </button>
                                                <button type="button" class="btn btn-sm btn-outline-danger" 
                                                        v-on:click="removePhoto('before')">
                                                    <i class="fas fa-trash-alt"></i> 刪除
                                                </button>
                                            </div>
                                        </div>
                                    </div>

                                    <!-- 未選照片上傳區 -->
                                    <div v-else class="photo-card" v-on:click="$refs.beforeFileInput.click()">
                                        <div class="upload-touch-zone">
                                            <i class="fas fa-camera upload-icon"></i>
                                            <div class="font-weight-bold text-dark">點擊拍照或上傳洗掃前照片</div>
                                            <small class="text-muted mt-1">支援 JPG, PNG, BMP 檔案</small>
                                        </div>
                                    </div>
                                </div>

                                <!-- 洗掃後照片 -->
                                <div class="col-12 col-md-6">
                                    <h4 class="font-weight-bold text-dark mb-2" style="font-size: 0.95rem;">
                                        <i class="fas fa-check-circle text-success mr-1"></i> 洗掃後現場照片
                                    </h4>

                                    <!-- 隱藏的 File Input -->
                                    <input type="file" ref="afterFileInput" accept="image/*" class="d-none" 
                                           v-on:change="handleFileSelected($event, 'after')" />

                                    <!-- 已有照片卡片 -->
                                    <div v-if="photos.after.previewUrl" class="photo-card has-photo">
                                        <div class="photo-preview-wrap" v-on:click="openLightbox(photos.after.previewUrl, '洗掃後照片')">
                                            <img :src="photos.after.previewUrl" class="photo-preview-img" alt="洗掃後照片" />
                                            <span class="badge badge-success photo-badge-status" v-if="photos.after.isNew">
                                                待上傳 (已選取)
                                            </span>
                                            <span class="badge badge-primary photo-badge-status" v-else>
                                                已儲存於系統
                                            </span>
                                            <span class="photo-overlay-zoom">
                                                <i class="fas fa-search-plus"></i> 點擊放大
                                            </span>
                                        </div>
                                        <div class="photo-meta">
                                            <span class="photo-meta-text">{{ photos.after.fileName || '洗掃後照片.jpg' }}</span>
                                            <div>
                                                <button type="button" class="btn btn-sm btn-outline-primary mr-1" 
                                                        v-on:click="$refs.afterFileInput.click()">
                                                    <i class="fas fa-sync-alt"></i> 更換
                                                </button>
                                                <button type="button" class="btn btn-sm btn-outline-danger" 
                                                        v-on:click="removePhoto('after')">
                                                    <i class="fas fa-trash-alt"></i> 刪除
                                                </button>
                                            </div>
                                        </div>
                                    </div>

                                    <!-- 未選照片上傳區 -->
                                    <div v-else class="photo-card" v-on:click="$refs.afterFileInput.click()">
                                        <div class="upload-touch-zone">
                                            <i class="fas fa-camera upload-icon"></i>
                                            <div class="font-weight-bold text-dark">點擊拍照或上傳洗掃後照片</div>
                                            <small class="text-muted mt-1">支援 JPG, PNG, BMP 檔案</small>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- 卡片 5：送出操作區 (Desktop) -->
                    <div class="card-modern d-none d-md-block">
                        <div class="card-modern-body d-flex justify-content-between align-items-center">
                            <a href="WashList.aspx" class="btn btn-outline-secondary px-4 py-2 font-weight-bold">
                                <i class="fas fa-arrow-left mr-1"></i> 放棄並返回清單
                            </a>
                            <div class="d-flex align-items-center">
                                <button type="button" class="btn btn-outline-dark px-4 py-2 font-weight-bold mr-2 shadow-sm" 
                                        style="font-size: 1.02rem;" v-on:click="printLog">
                                    <i class="fas fa-print mr-1"></i> 列印日誌
                                </button>
                                <button type="button" class="btn btn-primary px-5 py-2 font-weight-bold shadow-sm" 
                                        style="font-size: 1.05rem;" v-on:click="submitData" :disabled="saving">
                                    <i v-if="saving" class="fas fa-spinner fa-spin mr-1"></i>
                                    <i v-else class="fas fa-save mr-1"></i>
                                    <span>{{ saving ? '儲存中...' : (mode === 'edit' ? '更新洗掃日誌紀錄' : '確定送出洗掃日誌') }}</span>
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </main>

        <!-- 手機端常駐浮動動作列 (Sticky Bottom Bar) -->
        <div class="mobile-bottom-bar d-md-none">
            <a href="WashList.aspx" class="btn btn-outline-secondary" style="flex: 0 0 76px;">
                <i class="fas fa-arrow-left mr-1"></i> 返回
            </a>
            <button type="button" class="btn btn-outline-dark" v-on:click="printLog">
                <i class="fas fa-print mr-1"></i> 列印
            </button>
            <button type="button" class="btn btn-primary" v-on:click="submitData" :disabled="saving" style="flex: 1.5;">
                <i v-if="saving" class="fas fa-spinner fa-spin mr-1"></i>
                <i v-else class="fas fa-check-circle mr-1"></i>
                <span>{{ saving ? '儲存中...' : '確定送出' }}</span>
            </button>
        </div>

        <!-- 全螢幕照片燈箱 Modal -->
        <div v-if="lightbox.show" class="lightbox-modal" v-on:click.self="lightbox.show = false">
            <button type="button" class="lightbox-close" v-on:click="lightbox.show = false" title="關閉">
                <i class="fas fa-times"></i>
            </button>
            <div class="lightbox-content text-center">
                <img :src="lightbox.url" class="lightbox-img" :alt="lightbox.title" />
                <div class="text-white mt-2 font-weight-bold">{{ lightbox.title }}</div>
            </div>
        </div>
    </div>

    <!-- 本地端核心前端腳本庫 (依序引入 jQuery -> Bootstrap Bundle -> Vue 3 -> Axios) -->
    <script src="../Scripts/jquery-3.6.4.min.js"></script>
    <script src="../Scripts/bootstrap.bundle.min.js"></script>
    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>

    <script>
        const { createApp } = Vue;

        createApp({
            data() {
                return {
                    loading: true,
                    saving: false,
                    alertMessage: '',
                    alertType: 'success',
                    mode: 'new',
                    isManager: false,
                    facList: [],
                    currentFacName: '',
                    form: {
                        pIndex: 0,
                        facId: '',
                        washDate: '',
                        washTimeStart: '',
                        washTimeEnd: '',
                        washType: '洗',
                        length1: 0,
                        length2: 0,
                        ppl: ''
                    },
                    photos: {
                        before: {
                            previewUrl: '',
                            fileName: '',
                            base64: '',
                            ext: 'jpg',
                            isNew: false,
                            isDeleted: false
                        },
                        after: {
                            previewUrl: '',
                            fileName: '',
                            base64: '',
                            ext: 'jpg',
                            isNew: false,
                            isDeleted: false
                        }
                    },
                    lightbox: {
                        show: false,
                        url: '',
                        title: ''
                    }
                };
            },
            computed: {
                totalMeters() {
                    const l1 = parseInt(this.form.length1, 10) || 0;
                    const l2 = parseInt(this.form.length2, 10) || 0;
                    return l1 + l2;
                },
                totalKilometers() {
                    return (this.totalMeters / 1000).toFixed(2);
                }
            },
            mounted() {
                this.loadInitialData();
            },
            methods: {
                // 解析 URL 參數
                getUrlParams() {
                    const params = {};
                    const search = window.location.search.substring(1);
                    if (!search) return params;
                    const pairs = search.split('&');
                    for (let i = 0; i < pairs.length; i++) {
                        const pair = pairs[i].split('=');
                        params[decodeURIComponent(pair[0])] = decodeURIComponent(pair[1] || '');
                    }
                    return params;
                },

                // 載入初始化資料
                loadInitialData() {
                    this.loading = true;
                    this.alertMessage = '';
                    const params = this.getUrlParams();

                    const queryParams = new URLSearchParams();
                    queryParams.append('action', 'getinitialdata');
                    if (params.id) queryParams.append('id', params.id);
                    if (params.id1) queryParams.append('id1', params.id1);
                    if (params.id2) queryParams.append('id2', params.id2);
                    if (params.mode) queryParams.append('mode', params.mode);

                    axios.get('DataInput.aspx?' + queryParams.toString())
                        .then(response => {
                            const res = response.data;
                            if (res.Success) {
                                this.mode = res.Mode || 'new';
                                this.isManager = !!res.IsManager;
                                this.facList = res.FacList || [];
                                this.currentFacName = res.CurrentFacName || '';

                                if (res.Record) {
                                    this.form.pIndex = res.Record.PIndex || 0;
                                    this.form.facId = res.Record.FAC_ID || res.CurrentFacId || '';
                                    this.form.washDate = res.Record.WashDate || '';
                                    this.form.washTimeStart = res.Record.WashTime_Start || '';
                                    this.form.washTimeEnd = res.Record.WashTime_End || '';
                                    this.form.washType = res.Record.WashType || '洗';
                                    this.form.length1 = res.Record.Length1 || 0;
                                    this.form.length2 = res.Record.Length2 || 0;
                                    this.form.ppl = res.Record.PPL || '';
                                }

                                // 綁定既有照片
                                if (res.BeforePhoto && res.BeforePhoto.Exists) {
                                    this.photos.before.previewUrl = res.BeforePhoto.Url;
                                    this.photos.before.fileName = res.BeforePhoto.FileName;
                                    this.photos.before.isNew = false;
                                }
                                if (res.AfterPhoto && res.AfterPhoto.Exists) {
                                    this.photos.after.previewUrl = res.AfterPhoto.Url;
                                    this.photos.after.fileName = res.AfterPhoto.FileName;
                                    this.photos.after.isNew = false;
                                }
                            } else {
                                this.alertType = 'danger';
                                this.alertMessage = res.Message || '載入資料失敗！';
                            }
                        })
                        .catch(err => {
                            this.alertType = 'danger';
                            this.alertMessage = '通訊異常：' + (err.message || '無法連線至伺服器');
                        })
                        .finally(() => {
                            this.loading = false;
                        });
                },

                // 管理員切換認養單位
                onFacChange() {
                    const selected = this.facList.find(f => f.FacId === this.form.facId);
                    this.currentFacName = selected ? selected.FacName : '';
                },

                // 快捷日期設定
                setDateToday() {
                    const today = new Date();
                    this.form.washDate = this.formatDate(today);
                },
                setDateYesterday() {
                    const d = new Date();
                    d.setDate(d.getDate() - 1);
                    this.form.washDate = this.formatDate(d);
                },
                formatDate(d) {
                    const year = d.getFullYear();
                    const month = String(d.getMonth() + 1).padStart(2, '0');
                    const day = String(d.getDate()).padStart(2, '0');
                    return year + '-' + month + '-' + day;
                },

                // 快捷時段設定
                setShift(type) {
                    if (type === 'morning') {
                        this.form.washTimeStart = '08:30';
                        this.form.washTimeEnd = '12:00';
                    } else if (type === 'afternoon') {
                        this.form.washTimeStart = '13:30';
                        this.form.washTimeEnd = '17:00';
                    }
                },

                // 快捷里程增加
                addLength(side, meters) {
                    if (side === 1) {
                        this.form.length1 = (parseInt(this.form.length1, 10) || 0) + meters;
                    } else {
                        this.form.length2 = (parseInt(this.form.length2, 10) || 0) + meters;
                    }
                },

                // 圖片選擇與前端壓縮處理
                handleFileSelected(event, type) {
                    const file = event.target.files[0];
                    if (!file) return;

                    const fileName = file.name;
                    const ext = fileName.split('.').pop().toLowerCase();

                    const reader = new FileReader();
                    reader.onload = (e) => {
                        const img = new Image();
                        img.onload = () => {
                            const canvas = document.createElement('canvas');
                            const maxDimension = 1600;
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

                            this.photos[type].previewUrl = compressedBase64;
                            this.photos[type].base64 = compressedBase64;
                            this.photos[type].fileName = fileName;
                            this.photos[type].ext = ext === 'png' ? 'png' : 'jpg';
                            this.photos[type].isNew = true;
                            this.photos[type].isDeleted = false;
                        };
                        img.src = e.target.result;
                    };
                    reader.readAsDataURL(file);

                    event.target.value = '';
                },

                // 刪除照片
                removePhoto(type) {
                    if (confirm('確定要移除此照片嗎？')) {
                        this.photos[type].previewUrl = '';
                        this.photos[type].base64 = '';
                        this.photos[type].fileName = '';
                        this.photos[type].isNew = false;
                        this.photos[type].isDeleted = true;
                    }
                },

                // 燈箱放大檢視
                openLightbox(url, title) {
                    this.lightbox.url = url;
                    this.lightbox.title = title;
                    this.lightbox.show = true;
                },

                // 表單驗證與資料儲存
                submitData() {
                    this.alertMessage = '';

                    if (!this.form.facId) {
                        this.alertType = 'warning';
                        this.alertMessage = '請選擇或指定認養事業單位！';
                        window.scrollTo({ top: 0, behavior: 'smooth' });
                        return;
                    }
                    if (!this.form.washDate) {
                        this.alertType = 'warning';
                        this.alertMessage = '請輸入洗掃作業日期！';
                        window.scrollTo({ top: 0, behavior: 'smooth' });
                        return;
                    }
                    if ((this.form.length1 || 0) < 0 || (this.form.length2 || 0) < 0) {
                        this.alertType = 'warning';
                        this.alertMessage = '洗掃長度不可為負數！';
                        return;
                    }

                    this.saving = true;

                    const payload = {
                        mode: this.mode,
                        pIndex: this.form.pIndex,
                        facId: this.form.facId,
                        washDate: this.form.washDate,
                        washTimeStart: this.form.washTimeStart,
                        washTimeEnd: this.form.washTimeEnd,
                        washType: this.form.washType,
                        length1: this.form.length1 || 0,
                        length2: this.form.length2 || 0,
                        ppl: this.form.ppl || '',
                        deleteBeforePhoto: this.photos.before.isDeleted,
                        beforePhotoBase64: this.photos.before.isNew ? this.photos.before.base64 : '',
                        beforePhotoExt: this.photos.before.ext,
                        deleteAfterPhoto: this.photos.after.isDeleted,
                        afterPhotoBase64: this.photos.after.isNew ? this.photos.after.base64 : '',
                        afterPhotoExt: this.photos.after.ext
                    };

                    axios.post('DataInput.aspx?action=save', payload)
                        .then(response => {
                            const res = response.data;
                            if (res.Success) {
                                this.alertType = 'success';
                                this.alertMessage = res.Message || '儲存成功！';
                                window.scrollTo({ top: 0, behavior: 'smooth' });

                                if (this.mode === 'new') {
                                    this.mode = 'edit';
                                    this.form.pIndex = res.PIndex;
                                }
                                this.photos.before.isNew = false;
                                this.photos.before.isDeleted = false;
                                this.photos.after.isNew = false;
                                this.photos.after.isDeleted = false;

                                setTimeout(() => {
                                    if (confirm('洗掃日誌已儲存成功！是否返回洗掃紀錄清單？')) {
                                        window.location.href = 'WashList.aspx';
                                    }
                                }, 600);
                            } else {
                                this.alertType = 'danger';
                                this.alertMessage = res.Message || '儲存失敗，請檢查輸入項目！';
                                window.scrollTo({ top: 0, behavior: 'smooth' });
                            }
                        })
                        .catch(err => {
                            this.alertType = 'danger';
                            this.alertMessage = '儲存失敗：' + (err.message || '伺服器無回應');
                            window.scrollTo({ top: 0, behavior: 'smooth' });
                        })
                        .finally(() => {
                            this.saving = false;
                        });
                },

                // 列印
                printLog() {
                    window.print();
                }
            }
        }).mount('#washApp');
    </script>
</body>
</html>
