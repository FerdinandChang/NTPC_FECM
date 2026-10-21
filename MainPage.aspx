<%@ Page Title="主控儀表板" Language="C#" MasterPageFile="~/MainPage.Master" AutoEventWireup="true" CodeBehind="MainPage.aspx.cs" Inherits="NTPC_FEC.MainPage" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        /* 模組磚塊容器 */
        .tile-grid {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 22px;
            max-width: 1200px;
            margin: 10px auto 40px auto;
        }

        /* 模組卡片樣式 */
        .module-tile {
            position: relative;
            height: 220px;
            border-radius: 14px;
            padding: 24px 20px;
            color: #ffffff;
            cursor: pointer;
            box-shadow: 0 8px 20px rgba(0, 0, 0, 0.12);
            transition: all 0.25s cubic-bezier(0.165, 0.84, 0.44, 1);
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            align-items: center;
            text-align: center;
            text-decoration: none !important;
            user-select: none;
            overflow: hidden;
        }

        .module-tile:hover {
            transform: translateY(-6px);
            box-shadow: 0 14px 28px rgba(0, 0, 0, 0.22);
            filter: brightness(1.08);
            color: #ffffff;
        }

        .module-tile:active {
            transform: translateY(-2px);
        }

        /* 卡片光影裝飾 */
        .tile-overlay {
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: linear-gradient(180deg, rgba(255, 255, 255, 0.08) 0%, rgba(0, 0, 0, 0.18) 100%);
            pointer-events: none;
        }

        /* SVG 圖標容器 */
        .tile-icon {
            margin-top: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: transform 0.25s;
        }

        .module-tile:hover .tile-icon {
            transform: scale(1.1);
        }

        .tile-title {
            font-size: 1.35rem;
            font-weight: 700;
            letter-spacing: 1px;
            margin-bottom: 4px;
            z-index: 2;
        }

        /* 待辦徽章 (Badge) */
        .tile-badge {
            position: absolute;
            top: 14px;
            right: 14px;
            background-color: #ef4444;
            color: #ffffff;
            font-size: 0.8rem;
            font-weight: 700;
            padding: 4px 10px;
            border-radius: 12px;
            box-shadow: 0 2px 6px rgba(0, 0, 0, 0.25);
            z-index: 3;
            animation: pulse-badge 2s infinite;
        }

        @keyframes pulse-badge {
            0% { transform: scale(1); }
            50% { transform: scale(1.08); }
            100% { transform: scale(1); }
        }

        /* 次選單對話框樣式 */
        .modal-custom .modal-content {
            border-radius: 16px;
            border: none;
            overflow: hidden;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.2);
        }

        .sub-menu-list a {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 14px 18px;
            border-radius: 10px;
            color: #374151;
            text-decoration: none;
            font-weight: 600;
            margin-bottom: 8px;
            background-color: #f9fafb;
            transition: all 0.2s;
        }

        .sub-menu-list a:hover {
            background-color: #e0f2fe;
            color: #0369a1;
            transform: translateX(4px);
        }



        /* 手機自適應 (RWD) */
        @media (max-width: 900px) {
            .tile-grid {
                grid-template-columns: repeat(2, 1fr);
                gap: 15px;
            }
            .module-tile {
                height: 190px;
                padding: 18px 14px;
            }
            .tile-title {
                font-size: 1.15rem;
            }
        }

        @media (max-width: 480px) {
            .tile-grid {
                grid-template-columns: 1fr;
            }
            .module-tile {
                height: 130px;
                flex-direction: row;
                justify-content: flex-start;
                text-align: left;
                padding: 15px 20px;
            }
            .tile-icon {
                margin-top: 0;
                margin-right: 18px;
            }
            .tile-icon svg {
                width: 48px;
                height: 48px;
            }
            .tile-title {
                font-size: 1.25rem;
                margin-bottom: 0;
            }
        }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div id="mainDashboardApp">
        <!-- 現代化九宮格磚牆 -->
        <div class="tile-grid">
            <div v-for="item in modules" :key="item.Id" 
                 class="module-tile" 
                 :style="{ backgroundColor: item.BgColor }"
                 v-on:click="handleTileClick(item)">
                
                <div class="tile-overlay"></div>

                <!-- 待辦數量標記 -->
                <div v-if="item.BadgeCount > 0" class="tile-badge">
                    {{ item.BadgeCount }} 件待辦
                </div>

                <!-- SVG 向量圖標 -->
                <div class="tile-icon" v-html="item.IconSvg"></div>

                <!-- 模組標題 -->
                <div class="tile-title">{{ item.Title }}</div>
            </div>
        </div>



        <!-- 次選單彈出視窗 (Modal) -->
        <div class="modal fade modal-custom" id="subMenuModal" tabindex="-1" role="dialog" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered" role="document">
                <div class="modal-content" v-if="activeModule">
                    <div class="modal-header text-white" :style="{ backgroundColor: activeModule.BgColor }">
                        <h5 class="modal-title font-weight-bold">
                            {{ activeModule.Title }}
                        </h5>
                        <button type="button" class="close text-white" data-dismiss="modal" aria-label="Close">
                            <span aria-hidden="true">&times;</span>
                        </button>
                    </div>
                    <div class="modal-body p-3">
                        <p class="text-muted small mb-3">{{ activeModule.SubTitle }}</p>
                        <div class="sub-menu-list">
                            <a v-for="sub in activeModule.SubItems" :key="sub.Url" :href="sub.Url">
                                <span>{{ sub.Title }}</span>
                                <span v-if="sub.BadgeCount > 0" class="badge badge-danger">
                                    {{ sub.BadgeCount }} 件
                                </span>
                                <span v-else class="text-muted">&rarr;</span>
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="ScriptsContent" runat="server">
    <script>
        // 從後端接收已計算權限的模組資料 JSON
        const serverModules = <%= GetModulesJson() %>;

        const { createApp } = Vue;

        createApp({
            data() {
                return {
                    modules: serverModules,
                    activeModule: null
                };
            },
            methods: {
                handleTileClick(item) {
                    if (item.IsExternal) {
                        window.open(item.Url, '_blank');
                        return;
                    }

                    // 若只有一個子項目或直接跳轉
                    if (!item.SubItems || item.SubItems.length === 0) {
                        window.location.href = item.Url;
                        return;
                    }

                    // 若有多個子選單，開啟 Modal 抽屜供使用者選擇
                    this.activeModule = item;
                    $('#subMenuModal').modal('show');
                }
            }
        }).mount('#mainDashboardApp');
    </script>
</asp:Content>
