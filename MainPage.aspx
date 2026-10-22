<%@ Page Title="主控儀表板" Language="C#" MasterPageFile="~/MainPage.Master" AutoEventWireup="true" CodeBehind="MainPage.aspx.cs" Inherits="NTPC_FEC.MainPage" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        /* ======================================================== */
        /* NTPC_FEC 現代化主控台樣式 (支援全尺寸順暢觸控滾動與子功能清單) */
        /* ======================================================== */

        /* Vue 模板防閃爍規範 (防止載入瞬間短暫閃爍黃色警告方塊與未編譯變數) */
        [v-cloak] {
            display: none !important;
        }

        /* 儀表板最外層容器 */
        #mainDashboardApp {
            max-width: 1360px;
            margin: 0 auto 50px auto;
            touch-action: pan-y;
            -webkit-overflow-scrolling: touch;
        }

        /* 頂部搜尋與功能控制工具列 */
        .dashboard-toolbar {
            display: flex;
            align-items: center;
            justify-content: space-between;
            background: #ffffff;
            border-radius: 12px;
            padding: 12px 20px;
            margin-bottom: 22px;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.05);
            border: 1px solid #e2e8f0;
            gap: 16px;
        }

        .search-box-wrapper {
            position: relative;
            flex: 1;
            min-width: 200px;
            width: 100%;
        }

        .search-box-wrapper i {
            position: absolute;
            left: 14px;
            top: 50%;
            transform: translateY(-50%);
            color: #94a3b8;
            font-size: 15px;
        }

        .search-input {
            width: 100%;
            padding: 9px 14px 9px 38px;
            border: 1.5px solid #cbd5e1;
            border-radius: 24px;
            font-size: 0.95rem;
            color: #1e293b;
            background-color: #f8fafc;
            outline: none;
            transition: all 0.2s ease;
        }

        .search-input:focus {
            background-color: #ffffff;
            border-color: #0284c7;
            box-shadow: 0 0 0 3px rgba(2, 132, 199, 0.15);
        }

        .toolbar-btn-group {
            display: flex;
            align-items: center;
            gap: 10px;
            flex-shrink: 0;
        }

        .btn-toolbar-tool {
            background-color: #f1f5f9;
            color: #334155;
            border: 1px solid #cbd5e1;
            border-radius: 20px;
            padding: 6px 14px;
            font-size: 0.88rem;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s;
            display: inline-flex;
            align-items: center;
            gap: 6px;
        }

        .btn-toolbar-tool:hover {
            background-color: #e2e8f0;
            color: #0f172a;
        }

        /* 模組卡片網格 (桌機與平板) */
        .modules-container {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 24px;
            touch-action: pan-y;
        }

        /* 模組卡片外框 */
        .module-card {
            background: #ffffff;
            border-radius: 16px;
            box-shadow: 0 4px 16px rgba(0, 0, 0, 0.08);
            border: 1px solid #e2e8f0;
            overflow: hidden;
            display: flex;
            flex-direction: column;
            transition: transform 0.2s, box-shadow 0.2s;
            touch-action: pan-y;
        }

        .module-card:hover {
            box-shadow: 0 10px 26px rgba(0, 0, 0, 0.12);
        }

        /* 模組卡片標頭 (Header) */
        .module-card-header {
            padding: 20px 22px;
            color: #ffffff;
            position: relative;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: space-between;
            transition: filter 0.2s;
            touch-action: pan-y;
        }

        .module-card-header:hover {
            filter: brightness(1.06);
        }

        .header-content-left {
            display: flex;
            align-items: center;
            gap: 16px;
            flex: 1;
            min-width: 0;
        }

        .module-header-icon {
            width: 48px;
            height: 48px;
            flex-shrink: 0;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .module-header-icon svg {
            width: 100%;
            height: 100%;
            filter: drop-shadow(0 2px 4px rgba(0, 0, 0, 0.25));
        }

        .module-header-text {
            flex: 1;
            min-width: 0;
        }

        .module-main-title {
            font-size: 1.35rem;
            font-weight: 800;
            letter-spacing: 0.8px;
            margin: 0;
            text-shadow: 0 1px 3px rgba(0, 0, 0, 0.25);
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .module-main-subtitle {
            font-size: 0.82rem;
            opacity: 0.9;
            margin-top: 3px;
            margin-bottom: 0;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .header-content-right {
            display: flex;
            align-items: center;
            gap: 10px;
            flex-shrink: 0;
        }

        /* 待辦徽章 */
        .badge-pending {
            background-color: #ef4444;
            color: #ffffff;
            font-size: 0.8rem;
            font-weight: 800;
            padding: 4px 10px;
            border-radius: 12px;
            box-shadow: 0 2px 6px rgba(0, 0, 0, 0.25);
            white-space: nowrap;
        }

        /* 展開指示箭頭 */
        .toggle-arrow {
            font-size: 1.1rem;
            transition: transform 0.25s ease;
            opacity: 0.85;
        }

        .toggle-arrow.rotated {
            transform: rotate(180deg);
        }

        /* 模組卡片子選單區域 (Submenu Body) */
        .module-card-body {
            padding: 16px 18px;
            background-color: #ffffff;
            flex: 1;
            display: flex;
            flex-direction: column;
            gap: 8px;
            touch-action: pan-y;
        }

        /* 業務分類區塊標題 */
        .sub-category-title {
            font-size: 0.82rem;
            font-weight: 700;
            color: #64748b;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-top: 10px;
            margin-bottom: 4px;
            display: flex;
            align-items: center;
            gap: 6px;
        }

        .sub-category-title:first-child {
            margin-top: 0;
        }

        .sub-category-title .pill {
            width: 4px;
            height: 13px;
            border-radius: 2px;
            display: inline-block;
        }

        /* 子功能條列項目連結 */
        .sub-item-link {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 10px 14px;
            border-radius: 8px;
            background-color: #f8fafc;
            color: #334155;
            text-decoration: none !important;
            font-weight: 600;
            font-size: 0.92rem;
            border: 1px solid #e2e8f0;
            transition: all 0.18s ease;
            touch-action: pan-y;
        }

        .sub-item-link:hover {
            background-color: #eff6ff;
            color: #0284c7;
            border-color: #bfdbfe;
            transform: translateX(4px);
        }

        .sub-item-link .sub-badge {
            background-color: #ef4444;
            color: #ffffff;
            font-size: 0.72rem;
            font-weight: 700;
            padding: 2px 7px;
            border-radius: 10px;
            margin-left: 8px;
        }

        .sub-item-link .link-arrow {
            color: #94a3b8;
            font-size: 0.85rem;
            transition: transform 0.15s;
        }

        .sub-item-link:hover .link-arrow {
            color: #0284c7;
            transform: translateX(2px);
        }

        /* 展開更多子項目按鈕 */
        .btn-expand-more {
            background: none;
            border: 1px dashed #cbd5e1;
            border-radius: 8px;
            padding: 8px 12px;
            color: #64748b;
            font-size: 0.85rem;
            font-weight: 600;
            cursor: pointer;
            width: 100%;
            margin-top: 6px;
            text-align: center;
            transition: all 0.2s;
        }

        .btn-expand-more:hover {
            background-color: #f1f5f9;
            color: #1e293b;
            border-color: #94a3b8;
        }

        /* 外部系統連結特殊註記 */
        .external-system-note {
            background-color: #f0fdf4;
            border: 1px solid #bbf7d0;
            color: #166534;
            padding: 12px 16px;
            border-radius: 8px;
            font-size: 0.92rem;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 12px;
        }

        .btn-external-link {
            background-color: #16a34a;
            color: #ffffff !important;
            border-radius: 6px;
            padding: 7px 16px;
            font-size: 0.88rem;
            font-weight: 700;
            white-space: nowrap;
            text-decoration: none !important;
            display: inline-flex;
            align-items: center;
            transition: all 0.2s;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
        }

        .btn-external-link:hover {
            background-color: #15803d;
            transform: translateX(2px);
        }

        /* ======================================================== */
        /* 響應式佈局 (平板與大螢幕手機) */
        /* ======================================================== */
        @media (max-width: 992px) {
            .modules-container {
                grid-template-columns: repeat(2, 1fr);
                gap: 18px;
            }
            .module-main-title {
                font-size: 1.22rem;
            }
        }

        /* ======================================================== */
        /* 手機直向極限自適應 (iPhone / Android)                    */
        /* 採用手風琴展開折疊，徹底解決無法滑動與選項隱匿問題       */
        /* ======================================================== */
        @media (max-width: 768px) {
            .dashboard-toolbar {
                flex-wrap: wrap;
                padding: 10px 14px;
                gap: 12px;
            }

            .search-box-wrapper {
                flex: 1 1 100%;
                width: 100%;
            }

            .toolbar-btn-group {
                width: 100%;
                display: flex;
                align-items: center;
                justify-content: space-between;
                gap: 10px;
            }

            .toolbar-btn-group .btn-toolbar-tool {
                flex: 1;
                justify-content: center;
                padding: 9px 12px;
                font-size: 0.9rem;
            }
        }

        @media (max-width: 576px) {
            #mainDashboardApp {
                padding: 0 4px;
            }

            .dashboard-toolbar {
                margin-bottom: 14px;
            }

            .external-system-note {
                flex-direction: column;
                align-items: stretch;
                text-align: center;
                gap: 10px;
                padding: 14px;
            }

            .btn-external-link {
                justify-content: center;
                padding: 9px 12px;
                width: 100%;
            }

            .modules-container {
                grid-template-columns: 1fr;
                gap: 14px;
            }

            .module-card {
                border-radius: 12px;
            }

            .module-card-header {
                padding: 16px 18px;
            }

            .module-header-icon {
                width: 42px;
                height: 42px;
            }

            .module-main-title {
                font-size: 1.25rem;
            }

            .module-main-subtitle {
                font-size: 0.78rem;
            }

            .module-card-body {
                padding: 12px 14px;
            }

            .sub-item-link {
                padding: 12px 14px;
                font-size: 0.95rem;
            }
        }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div id="mainDashboardApp" v-cloak>
        <!-- 頂部搜尋與展開控制列 -->
        <div class="dashboard-toolbar">
            <div class="search-box-wrapper">
                <i class="fas fa-search"></i>
                <input type="text" class="search-input" 
                       v-model="searchKeyword" 
                       placeholder="快速搜尋子功能... (例如: 道路、審核、工廠、通報)" />
            </div>
            <div class="toolbar-btn-group">
                <button type="button" class="btn-toolbar-tool" v-on:click="toggleAll(true)" title="展開全部模組子功能">
                    <i class="fas fa-angle-double-down"></i> 全部展開
                </button>
                <button type="button" class="btn-toolbar-tool" v-on:click="toggleAll(false)" title="收合全部模組">
                    <i class="fas fa-angle-double-up"></i> 全部收合
                </button>
            </div>
        </div>

        <!-- 搜尋無結果提示 -->
        <div v-if="searchKeyword && searchKeyword.trim() !== '' && filteredModules.length === 0" class="alert alert-warning text-center py-4 rounded-lg">
            <i class="fas fa-info-circle mr-2"></i> 找不到符合「<strong>{{ searchKeyword }}</strong>」的子功能或模組，請嘗試其他關鍵字。
        </div>

        <!-- 模組列表卡片群組 (支援手風琴開展與直接瀏覽子選項) -->
        <div class="modules-container">
            <div v-for="mod in filteredModules" :key="mod.Id" class="module-card">
                
                <!-- 模組標頭 (點擊切換折疊 / 展開) -->
                <div class="module-card-header" 
                     :style="{ backgroundColor: mod.BgColor }"
                     v-on:click="toggleModule(mod.Id)">
                    
                    <div class="header-content-left">
                        <!-- 模組向量 SVG 圖標 -->
                        <div class="module-header-icon" v-html="mod.IconSvg"></div>
                        <div class="module-header-text">
                            <h3 class="module-main-title">{{ mod.Title }}</h3>
                            <p class="module-main-subtitle">{{ mod.SubTitle }}</p>
                        </div>
                    </div>

                    <div class="header-content-right">
                        <!-- 待辦事項標籤 -->
                        <span v-if="mod.BadgeCount > 0" class="badge-pending">
                            {{ mod.BadgeCount }} 件待辦
                        </span>
                        <!-- 展開/收合箭頭 -->
                        <i class="fas fa-chevron-down toggle-arrow" :class="{ 'rotated': isExpanded(mod.Id) }"></i>
                    </div>
                </div>

                <!-- 模組子選項面板 (Body) - 展開時顯示該模組所有分類與子功能 -->
                <div v-show="isExpanded(mod.Id)" class="module-card-body">
                    
                    <!-- 外部獨立專責系統 (如餐飲、油氣) -->
                    <div v-if="mod.IsExternal" class="external-system-note">
                        <div class="d-flex align-items-center">
                            <i class="fas fa-external-link-alt mr-2 text-success"></i>
                            <span class="font-weight-600">本項目為獨立專責業務系統</span>
                        </div>
                        <a :href="mod.Url" class="btn-external-link">
                            前往系統 <i class="fas fa-arrow-right ml-1"></i>
                        </a>
                    </div>

                    <!-- 一般模組：依業務分類呈現子項目列表 -->
                    <template v-else>
                        <div v-for="(items, category) in getGroupedSubItems(mod)" :key="category">
                            <!-- 分類小標題 (有分類才顯示) -->
                            <div v-if="category" class="sub-category-title">
                                <span class="pill" :style="{ backgroundColor: mod.BgColor }"></span>
                                <span>{{ category }}</span>
                            </div>

                            <!-- 子功能項目連結清單 -->
                            <div class="d-flex flex-column gap-2">
                                <a v-for="sub in items" :key="sub.Url" 
                                   :href="sub.Url" 
                                   class="sub-item-link">
                                    <div class="d-flex align-items-center">
                                        <i class="fas fa-angle-right text-muted mr-2"></i>
                                        <span>{{ sub.Title }}</span>
                                        <span v-if="sub.BadgeCount > 0" class="sub-badge">
                                            {{ sub.BadgeCount }} 件
                                        </span>
                                    </div>
                                    <i class="fas fa-arrow-right link-arrow"></i>
                                </a>
                            </div>
                        </div>
                    </template>
                </div>

                <!-- 未展開時的預覽列 (桌機版友善：未展開時提示並展示前兩項) -->
                <div v-show="!isExpanded(mod.Id)" class="module-card-body py-2">
                    <div class="d-flex justify-content-between align-items-center text-muted small px-1 py-1">
                        <span><i class="fas fa-list-ul mr-1"></i> 共 {{ (mod.SubItems || []).length }} 個子功能選項</span>
                        <a href="javascript:void(0)" class="text-primary font-weight-bold" v-on:click="toggleModule(mod.Id)">
                            點擊展開 <i class="fas fa-chevron-down ml-1"></i>
                        </a>
                    </div>
                </div>

            </div>
        </div>
    </div>
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="ScriptsContent" runat="server">
    <script>
        // 從後端接收已計算權限之模組 JSON 資料
        const serverModules = <%= GetModulesJson() %>;

        const { createApp } = Vue;

        createApp({
            data() {
                return {
                    modules: serverModules || [],
                    expandedMap: {}, // 預設全部收合
                    searchKeyword: ''
                };
            },
            computed: {
                // 支援關鍵字搜尋過濾
                filteredModules() {
                    const kw = (this.searchKeyword || '').trim().toLowerCase();
                    if (!kw) {
                        return this.modules;
                    }

                    return this.modules.filter(mod => {
                        // 比對模組主標題
                        if (mod.Title && mod.Title.toLowerCase().indexOf(kw) !== -1) {
                            return true;
                        }
                        // 比對子項目標題
                        if (mod.SubItems && mod.SubItems.some(sub => sub.Title && sub.Title.toLowerCase().indexOf(kw) !== -1)) {
                            return true;
                        }
                        return false;
                    });
                }
            },
            watch: {
                // 當搜尋關鍵字時，自動展開有匹配結果的模組
                searchKeyword(newVal) {
                    if (newVal.trim()) {
                        this.filteredModules.forEach(m => {
                            this.expandedMap[m.Id] = true;
                        });
                    }
                }
            },
            methods: {
                // 切換個別模組展開 / 折疊
                toggleModule(id) {
                    this.expandedMap[id] = !this.expandedMap[id];
                },
                // 檢查是否展開
                isExpanded(id) {
                    return !!this.expandedMap[id];
                },
                // 全部展開 / 全部收合
                toggleAll(expand) {
                    const next = {};
                    this.modules.forEach(m => {
                        next[m.Id] = expand;
                    });
                    this.expandedMap = next;
                },
                // 依分類將子功能分組
                getGroupedSubItems(mod) {
                    if (!mod || !mod.SubItems) return {};
                    const groups = {};
                    const kw = (this.searchKeyword || '').trim().toLowerCase();

                    mod.SubItems.forEach(sub => {
                        // 搜尋時過濾子項目
                        if (kw && sub.Title && sub.Title.toLowerCase().indexOf(kw) === -1 && mod.Title.toLowerCase().indexOf(kw) === -1) {
                            return;
                        }

                        const cat = sub.Category || '';
                        if (!groups[cat]) {
                            groups[cat] = [];
                        }
                        groups[cat].push(sub);
                    });
                    return groups;
                }
            }
        }).mount('#mainDashboardApp');
    </script>
</asp:Content>
