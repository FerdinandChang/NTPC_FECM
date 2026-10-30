<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="MoenvEquipment_Upload.aspx.cs" Inherits="NTPC_FEC.MoenvEquip.MoenvEquipment_Upload" %>

<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定逸散源管理平台 - 環境部施工機具資料匯入</title>

    <link rel="shortcut icon" href="../favicon.ico" type="image/x-icon" />
    <link rel="stylesheet" href="../Content/bootstrap.min.css" />
    <link rel="stylesheet" href="../Content/fontawesome/css/all.min.css" />

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
            --accent-success: #10b981;
            --accent-warning: #f59e0b;
            --accent-danger: #ef4444;
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
            min-height: 100vh;
        }

        [v-cloak] {
            display: none !important;
        }

        /* 頂部品牌導覽列 */
        .top-navbar {
            background: linear-gradient(135deg, #0099e5 0%, #0284c7 100%);
            color: #ffffff;
            height: 58px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 0 16px;
            box-shadow: 0 2px 10px rgba(0, 153, 229, 0.25);
            position: sticky;
            top: 0;
            z-index: 1020;
        }

        .navbar-brand-title {
            font-size: 1.08rem;
            font-weight: 700;
            display: flex;
            align-items: center;
            gap: 8px;
            color: #ffffff !important;
            text-decoration: none !important;
            white-space: nowrap;
        }

        .nav-btn {
            background: rgba(255, 255, 255, 0.18);
            border: 1px solid rgba(255, 255, 255, 0.3);
            color: #ffffff !important;
            font-size: 0.88rem;
            font-weight: 600;
            cursor: pointer;
            height: 36px;
            border-radius: 8px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            padding: 0 14px;
            gap: 6px;
            transition: all 0.2s ease;
            text-decoration: none !important;
        }
        .nav-btn:hover {
            background-color: rgba(255, 255, 255, 0.32);
            color: #ffffff !important;
        }

        /* 業務模式分頁切換列 */
        .nav-mode-bar {
            background: #ffffff;
            border-bottom: 1px solid var(--border-color);
            padding: 0 16px;
            display: flex;
            gap: 6px;
            overflow-x: auto;
            white-space: nowrap;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.03);
        }

        .nav-mode-item {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 13px 18px;
            font-size: 14px;
            font-weight: 600;
            color: #64748b;
            border-bottom: 3px solid transparent;
            cursor: pointer;
            transition: all 0.2s ease;
            text-decoration: none !important;
        }
        .nav-mode-item:hover {
            color: var(--brand-blue);
            background: #f8fafc;
        }
        .nav-mode-item.active {
            color: var(--brand-blue);
            border-bottom-color: var(--brand-blue);
            font-weight: 700;
            background: rgba(2, 132, 199, 0.04);
        }

        .container-fluid-custom {
            max-width: 960px;
            margin: 24px auto;
            padding: 0 16px;
        }

        /* 現代卡片 */
        .card-modern {
            background: var(--surface);
            border-radius: 12px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05), 0 4px 12px rgba(15, 23, 42, 0.05);
            margin-bottom: 20px;
            border: 1px solid var(--border-color);
            overflow: hidden;
        }
        .card-modern-header {
            padding: 14px 20px;
            background: #ffffff;
            border-bottom: 1px solid var(--border-color);
            display: flex;
            align-items: center;
            justify-content: space-between;
        }
        .card-modern-title {
            font-size: 1.05rem;
            font-weight: 700;
            color: var(--brand-navy);
            margin: 0;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .card-modern-body {
            padding: 24px;
        }

        /* 拖曳上傳區 */
        .upload-dropzone {
            border: 2px dashed #94a3b8;
            background: #f8fafc;
            border-radius: 14px;
            padding: 48px 24px;
            text-align: center;
            cursor: pointer;
            transition: all 0.25s ease;
            position: relative;
        }
        .upload-dropzone:hover,
        .upload-dropzone.dragover {
            border-color: var(--brand-blue);
            background: #f0f9ff;
            box-shadow: 0 0 0 4px rgba(2, 132, 199, 0.1);
        }
        .upload-icon-circle {
            width: 72px;
            height: 72px;
            border-radius: 50%;
            background: #e0f2fe;
            color: var(--brand-blue);
            display: inline-flex;
            align-items: center;
            justify-content: center;
            font-size: 30px;
            margin-bottom: 16px;
            transition: transform 0.25s ease;
        }
        .upload-dropzone:hover .upload-icon-circle {
            transform: translateY(-3px) scale(1.05);
        }

        /* 現場狀況開關 (Segmented Buttons) */
        .status-toggle-row {
            display: flex;
            align-items: center;
            justify-content: space-between;
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 10px;
            padding: 10px 16px;
            margin-bottom: 20px;
            flex-wrap: wrap;
            gap: 10px;
        }
        .segmented-group {
            display: inline-flex;
            background: #e2e8f0;
            padding: 3px;
            border-radius: 8px;
            gap: 2px;
        }
        .segment-btn {
            border: none;
            background: transparent;
            padding: 6px 18px;
            border-radius: 6px;
            font-size: 13.5px;
            font-weight: 600;
            color: #475569;
            cursor: pointer;
            min-height: 36px;
            transition: all 0.15s ease;
        }
        .segment-btn.active-blue {
            background: var(--brand-blue);
            color: #ffffff;
            box-shadow: 0 1px 4px rgba(2, 132, 199, 0.35);
        }

        /* 統計結果小卡 */
        .result-stat-grid {
            display: grid;
            grid-template-columns: repeat(5, 1fr);
            gap: 12px;
            margin: 18px 0;
        }
        @media (max-width: 767.98px) {
            .result-stat-grid {
                grid-template-columns: repeat(2, 1fr);
            }
            .result-stat-item:first-child {
                grid-column: span 2;
            }
        }
        .result-stat-item {
            background: #ffffff;
            border: 1px solid #e2e8f0;
            border-radius: 10px;
            padding: 14px 10px;
            text-align: center;
            box-shadow: 0 1px 2px rgba(0,0,0,0.03);
        }
        .result-stat-val {
            font-size: 1.5rem;
            font-weight: 800;
            line-height: 1.2;
        }
        .result-stat-label {
            font-size: 0.8rem;
            font-weight: 600;
            color: var(--text-muted);
            margin-top: 4px;
        }
    </style>
</head>
<body>
    <div id="app" v-cloak>
        <!-- 1. 置頂深青藍導覽列 -->
        <header class="top-navbar">
            <div class="d-flex align-items-center">
                <a href="MoenvEquipment_List.aspx" class="nav-btn mr-2" title="返回機具分析清冊">
                    <i class="fas fa-arrow-left"></i>
                    <span class="d-none d-sm-inline">返回清單</span>
                </a>
                <a href="../MainPage.aspx" class="nav-btn mr-2" title="返回系統主選單">
                    <i class="fas fa-home"></i>
                    <span class="d-none d-md-inline">回首頁</span>
                </a>
                <span class="navbar-brand-title">
                    <i class="fas fa-file-excel text-white"></i>
                    <span>環境部施工機具資料匯入</span>
                </span>
            </div>
            <div class="d-flex align-items-center">
                <a href="MoenvEquipment_List.aspx" class="btn btn-light btn-sm font-weight-bold text-dark shadow-sm" style="border-radius: 8px; height: 36px; display: inline-flex; align-items: center; padding: 0 12px;">
                    <i class="fas fa-chart-bar text-primary mr-1"></i>
                    <span>資料統計與分析清冊</span>
                </a>
            </div>
        </header>

        <!-- 2. 業務模式分頁切換列 -->
        <nav class="nav-mode-bar">
            <a href="MoenvEquipment_List.aspx" class="nav-mode-item">
                <i class="fas fa-table"></i>
                <span>資料統計與分析清冊</span>
            </a>
            <a href="MoenvEquipment_Upload.aspx" class="nav-mode-item active">
                <i class="fas fa-cloud-upload-alt"></i>
                <span>匯入環境部 Excel 資料</span>
            </a>
        </nav>

        <!-- 3. 主作業容器 -->
        <main class="container-fluid-custom">
            <div class="card-modern">
                <div class="card-modern-header">
                    <h2 class="card-modern-title">
                        <i class="fas fa-file-import text-primary"></i>
                        <span>上傳環境部施工機具檢測清冊 (.xlsx)</span>
                    </h2>
                    <span class="badge badge-info px-2 py-1">自動 Upsert 智慧比對</span>
                </div>
                <div class="card-modern-body">
                    <!-- 說明提示 -->
                    <div class="alert alert-light border mb-3" style="font-size: 0.9rem; color: #334155;">
                        <div class="font-weight-bold text-dark mb-1">
                            <i class="fas fa-info-circle text-primary mr-1"></i>匯入與比對規則說明：
                        </div>
                        <ul class="mb-0 pl-3" style="line-height: 1.7;">
                            <li>請上傳自環境部系統匯出之施工機具檢測清冊（僅支援 <code>.xlsx</code> 格式）。</li>
                            <li><strong>合格機具主表</strong>：以「標章編號 ＋ 檢測日期」自動比對，既有資料有異動時自動覆寫更新，無異動則跳過。</li>
                            <li><strong>未通過機具副表</strong>：若「標章等級為未通過」或「無標章編號」，自動分流至未通過副表，並以「統編、廠牌、型式、引擎編號、牌號 ＋ 檢測日期」比對更新。</li>
                            <li><strong>資料完整性稽核</strong>：系統將自動檢核 7 項規格（廠牌、種類、年份、型式、引擎編號、馬力、轉速至少具備 5 項）及新機具/使用中機具必備證明文件。</li>
                        </ul>
                    </div>

                    <!-- 預設計畫類型切換 (Segmented Buttons) -->
                    <div class="status-toggle-row">
                        <div>
                            <span class="font-weight-bold text-dark">
                                <i class="fas fa-tags text-primary mr-1"></i>預設歸屬計畫類型
                            </span>
                            <small class="text-muted d-block">若上傳的 Excel 未包含「計畫類型」欄位，新增資料將自動套用此設定</small>
                        </div>
                        <div class="segmented-group">
                            <button type="button" class="segment-btn" :class="{ 'active-blue': defaultPlanType === '營建' }" v-on:click="defaultPlanType = '營建'">
                                <i class="fas fa-hard-hat mr-1"></i>營建
                            </button>
                            <button type="button" class="segment-btn" :class="{ 'active-blue': defaultPlanType === '逸散' }" v-on:click="defaultPlanType = '逸散'">
                                <i class="fas fa-wind mr-1"></i>逸散
                            </button>
                        </div>
                    </div>

                    <!-- 拖曳與點擊上傳區 -->
                    <div v-if="!uploading && !result"
                         class="upload-dropzone"
                         :class="{ 'dragover': isDragging }"
                         v-on:click="triggerFileSelect"
                         v-on:dragenter.prevent="isDragging = true"
                         v-on:dragover.prevent="isDragging = true"
                         v-on:dragleave.prevent="isDragging = false"
                         v-on:drop.prevent="handleDrop">
                        <div class="upload-icon-circle">
                            <i class="fas fa-file-excel"></i>
                        </div>
                        <h4 class="font-weight-bold text-dark mb-2" style="font-size: 1.15rem;">
                            拖曳環境部 Excel 檔案至此，或點擊選擇檔案
                        </h4>
                        <p class="text-muted mb-3" style="font-size: 0.9rem;">
                            支援標準 <code>.xlsx</code> 活頁簿格式，選擇檔案後將自動開始解析與匯入
                        </p>
                        <button type="button" class="btn btn-primary font-weight-bold px-4" style="border-radius: 8px;">
                            <i class="fas fa-folder-open mr-1"></i>選擇 Excel 檔案
                        </button>
                        <input type="file" ref="fileInput" accept=".xlsx" style="display: none;" v-on:change="handleFileChange" />
                    </div>

                    <!-- 處理中狀態 -->
                    <div v-if="uploading" class="text-center py-5">
                        <div class="spinner-border text-primary mb-3" role="status" style="width: 3rem; height: 3rem;">
                            <span class="sr-only">載入中...</span>
                        </div>
                        <h5 class="font-weight-bold text-dark mb-1">正在解析 Excel 並同步更新資料庫...</h5>
                        <p class="text-muted small mb-0">檔案：{{ currentFileName }}，請勿關閉視窗</p>
                    </div>

                    <!-- 匯入結果面板 -->
                    <div v-if="result" class="mt-2">
                        <div class="alert" :class="result.success ? 'alert-success' : 'alert-danger'" style="border-radius: 12px; padding: 20px;">
                            <div class="d-flex align-items-center mb-2">
                                <i class="fas fa-2x mr-2" :class="result.success ? 'fa-check-circle text-success' : 'fa-exclamation-triangle text-danger'"></i>
                                <h5 class="font-weight-bold mb-0">
                                    {{ result.success ? '環境部施工機具資料匯入完成！' : '資料匯入失敗' }}
                                </h5>
                            </div>
                            <p class="mb-0" style="white-space: pre-line; font-size: 0.95rem;">{{ result.message }}</p>

                            <!-- 5 大統計指標 -->
                            <div v-if="result.success" class="result-stat-grid">
                                <div class="result-stat-item">
                                    <div class="result-stat-val text-dark">{{ result.total }}</div>
                                    <div class="result-stat-label">總解析筆數</div>
                                </div>
                                <div class="result-stat-item">
                                    <div class="result-stat-val text-success">{{ result.mainInserted }}</div>
                                    <div class="result-stat-label">合格主表新增</div>
                                </div>
                                <div class="result-stat-item">
                                    <div class="result-stat-val text-primary">{{ result.mainUpdated }}</div>
                                    <div class="result-stat-label">合格主表覆寫</div>
                                </div>
                                <div class="result-stat-item">
                                    <div class="result-stat-val text-warning">{{ result.unqInserted }}</div>
                                    <div class="result-stat-label">未通過副表新增</div>
                                </div>
                                <div class="result-stat-item">
                                    <div class="result-stat-val text-danger">{{ result.unqUpdated }}</div>
                                    <div class="result-stat-label">未通過副表覆寫</div>
                                </div>
                            </div>

                            <div class="d-flex justify-content-end mt-3 pt-2 border-top" style="gap: 10px;">
                                <button type="button" class="btn btn-outline-secondary font-weight-bold" v-on:click="resetUpload">
                                    <i class="fas fa-redo mr-1"></i>繼續上傳其他檔案
                                </button>
                                <a href="MoenvEquipment_List.aspx" class="btn btn-primary font-weight-bold">
                                    <i class="fas fa-list-alt mr-1"></i>前往機具分析清冊
                                </a>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </main>
    </div>

    <!-- 本地核心 JS 庫 -->
    <script src="../Scripts/vue.global.prod.js"></script>
    <script src="../Scripts/axios.min.js"></script>
    <script>
        const { createApp } = Vue;

        createApp({
            data: function () {
                return {
                    defaultPlanType: '營建',
                    isDragging: false,
                    uploading: false,
                    currentFileName: '',
                    result: null
                };
            },
            methods: {
                triggerFileSelect: function () {
                    if (this.$refs.fileInput) {
                        this.$refs.fileInput.value = '';
                        this.$refs.fileInput.click();
                    }
                },
                handleFileChange: function (e) {
                    var files = e.target.files;
                    if (files && files.length > 0) {
                        this.uploadFile(files[0]);
                    }
                },
                handleDrop: function (e) {
                    this.isDragging = false;
                    var dt = e.dataTransfer;
                    if (dt && dt.files && dt.files.length > 0) {
                        this.uploadFile(dt.files[0]);
                    }
                },
                uploadFile: function (file) {
                    var self = this;
                    if (!file.name || !file.name.toLowerCase().endsWith('.xlsx')) {
                        this.result = {
                            success: false,
                            message: '檔案格式不符！僅支援副檔名為 .xlsx 之 Excel 檔案。'
                        };
                        return;
                    }

                    this.currentFileName = file.name;
                    this.uploading = true;
                    this.result = null;

                    var formData = new FormData();
                    formData.append('file', file);
                    formData.append('defaultPlanType', this.defaultPlanType);

                    axios.post('MoenvEquipment_Upload.aspx?action=upload', formData, {
                        headers: { 'Content-Type': 'multipart/form-data' }
                    }).then(function (res) {
                        self.uploading = false;
                        var data = res.data;
                        if (data && data.success) {
                            self.result = {
                                success: true,
                                message: data.message || '匯入成功',
                                total: data.total || 0,
                                mainInserted: data.mainInserted || 0,
                                mainUpdated: data.mainUpdated || 0,
                                unqInserted: data.unqInserted || 0,
                                unqUpdated: data.unqUpdated || 0
                            };
                        } else {
                            self.result = {
                                success: false,
                                message: (data && data.message) ? data.message : '解析或匯入失敗，請確認檔案格式。'
                            };
                        }
                    }).catch(function (err) {
                        self.uploading = false;
                        self.result = {
                            success: false,
                            message: '連線伺服器失敗，請確認網路狀態或檔案大小。'
                        };
                    });
                },
                resetUpload: function () {
                    this.result = null;
                    this.currentFileName = '';
                    if (this.$refs.fileInput) {
                        this.$refs.fileInput.value = '';
                    }
                }
            }
        }).mount('#app');
    </script>
</body>
</html>
