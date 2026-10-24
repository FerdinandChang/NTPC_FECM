<%@ Page Title="帳號與權限管理" Language="C#" MasterPageFile="~/MainPage.Master" AutoEventWireup="true" CodeBehind="AccountManagement.aspx.cs" Inherits="NTPC_FEC.Modules.Manager.AccountManagement" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .admin-card {
            border-radius: 14px;
            border: 1px solid #e2e8f0;
            box-shadow: 0 4px 20px rgba(15, 23, 42, 0.05);
            background: #ffffff;
            margin-bottom: 30px;
        }

        .admin-card-header {
            background: linear-gradient(135deg, #ffffff 0%, #f8fafc 100%);
            border-bottom: 1px solid #e2e8f0;
            padding: 16px 24px;
            border-radius: 14px 14px 0 0;
        }

        /* 篩選與搜尋工具列區塊 */
        .filter-toolbar {
            background-color: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 12px;
            padding: 14px 18px;
            margin-bottom: 18px;
        }

        /* PUnit 單位篩選藥丸列 (Pills) */
        .punit-nav {
            display: flex;
            flex-wrap: wrap;
            gap: 6px;
            align-items: center;
        }

        .punit-pill {
            display: inline-flex;
            align-items: center;
            padding: 5px 14px;
            border-radius: 20px;
            font-size: 0.85rem;
            font-weight: 600;
            text-decoration: none !important;
            transition: all 0.18s ease;
            border: 1px solid #cbd5e1;
            color: #475569;
            background-color: #ffffff;
        }

        .punit-pill:hover {
            background-color: #f1f5f9;
            color: #0f172a;
            border-color: #94a3b8;
        }

        .punit-pill.active {
            background-color: #184b72;
            color: #ffffff;
            border-color: #184b72;
            box-shadow: 0 2px 8px rgba(24, 75, 114, 0.25);
        }

        /* 外層列表表格優化 */
        .acc-table {
            border-collapse: separate;
            border-spacing: 0;
            border: 1px solid #e2e8f0;
            border-radius: 10px;
            overflow: hidden;
            margin-bottom: 0;
            width: 100%;
        }

        .acc-table thead th {
            background-color: #f1f5f9;
            color: #334155;
            font-weight: 700;
            font-size: 0.88rem;
            border-bottom: 2px solid #cbd5e1;
            border-top: none;
            padding: 11px 14px;
            white-space: nowrap;
        }

        .acc-table tbody td {
            padding: 10px 14px;
            vertical-align: middle;
            border-top: 1px solid #e2e8f0;
        }

        .acc-table tbody tr:hover {
            background-color: #f8fafc;
        }

        /* 外層列表：配置權限多欄緊湊網格 */
        .perm-summary-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(215px, 1fr));
            gap: 6px 8px;
        }

        .perm-group-chip {
            background-color: #f8fafc;
            border: 1px solid #e2e8f0;
            border-left: 3px solid #0284c7;
            border-radius: 6px;
            padding: 5px 9px;
            display: flex;
            flex-direction: column;
            justify-content: center;
            transition: border-color 0.15s, background-color 0.15s;
        }

        .perm-group-chip:hover {
            background-color: #f0f9ff;
            border-color: #bae6fd;
            border-left-color: #0369a1;
        }

        .perm-group-title {
            color: #0369a1;
            font-weight: 700;
            font-size: 0.82rem;
            margin-bottom: 3px;
            line-height: 1.25;
            display: flex;
            align-items: center;
        }

        .perm-items-wrap {
            display: flex;
            flex-wrap: wrap;
            gap: 3px 5px;
        }

        .perm-item-text {
            color: #475569;
            font-size: 0.77rem;
            background-color: #ffffff;
            border: 1px solid #cbd5e1;
            border-radius: 4px;
            padding: 1px 6px;
            line-height: 1.35;
            white-space: nowrap;
        }

        /* 外層列表：可瀏覽行政區緊湊排版 */
        .user-town-grid {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 4px;
        }

        .town-mini-badge {
            display: inline-block;
            text-align: center;
            background-color: #f8fafc;
            color: #334155;
            border: 1px solid #cbd5e1;
            border-radius: 5px;
            padding: 2px 4px;
            font-size: 0.78rem;
            font-weight: 500;
            white-space: nowrap;
        }

        .town-all-badge {
            display: inline-flex;
            align-items: center;
            background-color: #ecfdf5;
            color: #047857;
            border: 1px solid #a7f3d0;
            padding: 4px 10px;
            border-radius: 8px;
            font-size: 0.82rem;
            font-weight: 700;
        }

        .town-full29-badge {
            display: inline-flex;
            align-items: center;
            background-color: #eff6ff;
            color: #1d4ed8;
            border: 1px solid #bfdbfe;
            padding: 4px 10px;
            border-radius: 8px;
            font-size: 0.82rem;
            font-weight: 700;
        }

        /* 行動端標籤提示 (預設桌面端隱藏) */
        .mobile-field-label {
            display: none;
        }

        /* ======================================================= */
        /* 全載具自適應核心 (Mobile RWD Table-to-Card 轉換規範)     */
        /* 依據 inspection-ui-standard 規範，小螢幕自動轉為卡片清單 */
        /* ======================================================= */
        @media screen and (max-width: 991.98px) {
            /* 1. 單位篩選藥丸列：手機端支援橫向平滑滑動，不折行占用垂直高度 */
            .punit-nav {
                flex-wrap: nowrap !important;
                overflow-x: auto !important;
                padding-bottom: 8px;
                -webkit-overflow-scrolling: touch;
            }

            .punit-pill {
                flex-shrink: 0;
            }

            /* 2. 移除水平溢出限制，容器改為 100% 流動 */
            .table-responsive {
                overflow-x: visible !important;
                display: block;
            }

            .acc-table {
                border: none !important;
                background: transparent !important;
                display: block !important;
                width: 100% !important;
            }

            /* 3. 隱藏桌面端擠壓破版的表頭 */
            .acc-table thead {
                display: none !important;
            }

            .acc-table tbody {
                display: block !important;
                width: 100% !important;
            }

            /* 4. 每筆帳號轉化為獨立高質感卡片 (Mobile User Card) */
            .acc-table tbody tr {
                display: block !important;
                background: #ffffff !important;
                border: 1px solid #e2e8f0 !important;
                border-radius: 14px !important;
                margin-bottom: 14px !important;
                padding: 14px 16px !important;
                box-shadow: 0 2px 10px rgba(15, 23, 42, 0.05) !important;
                position: relative;
            }

            .acc-table tbody tr:hover {
                box-shadow: 0 4px 14px rgba(15, 23, 42, 0.08) !important;
            }

            .acc-table tbody td {
                display: block !important;
                width: 100% !important;
                padding: 5px 0 !important;
                border-top: none !important;
                min-width: 0 !important;
            }

            /* 第一欄：帳號與啟用狀態 (整合為卡片頂部標題列) */
            .acc-table tbody td.col-user {
                display: flex !important;
                align-items: center;
                justify-content: space-between;
                border-bottom: 1px solid #f1f5f9 !important;
                padding-bottom: 8px !important;
                margin-bottom: 8px !important;
            }

            .acc-table tbody td.col-user .user-id-title {
                font-size: 1.05rem !important;
                color: #0f172a !important;
            }

            /* 第二欄：姓名與管制編號 */
            .acc-table tbody td.col-name {
                padding-bottom: 6px !important;
            }

            /* 第三欄：所屬單位 (在手機端以行內標籤展示) */
            .acc-table tbody td.col-unit {
                display: inline-block !important;
                width: auto !important;
                margin-bottom: 8px !important;
            }

            /* 行動端小標題提示 */
            .mobile-field-label {
                display: block;
                font-size: 0.78rem;
                font-weight: 700;
                color: #64748b;
                margin-bottom: 4px;
                margin-top: 6px;
            }

            /* 權限網格自適應單欄/雙欄 */
            .perm-summary-grid {
                grid-template-columns: 1fr;
            }

            /* 行政區網格自適應 */
            .user-town-grid {
                grid-template-columns: repeat(4, 1fr);
            }

            /* 第六欄：操作按鈕區 (轉為卡片底部並排大觸控按鈕) */
            .acc-table tbody td.col-action {
                border-top: 1px solid #f1f5f9 !important;
                padding-top: 10px !important;
                margin-top: 8px !important;
            }

            .acc-table tbody td.col-action .action-btn-group {
                flex-direction: row !important;
                gap: 8px !important;
            }

            .acc-table tbody td.col-action .action-btn-group .btn {
                flex: 1;
                min-height: 38px;
                display: inline-flex;
                align-items: center;
                justify-content: center;
                font-size: 0.85rem;
            }
        }
            padding: 2px 4px;
            font-size: 0.78rem;
            font-weight: 500;
            white-space: nowrap;
        }

        .town-all-badge {
            display: inline-flex;
            align-items: center;
            background-color: #ecfdf5;
            color: #047857;
            border: 1px solid #a7f3d0;
            padding: 4px 10px;
            border-radius: 8px;
            font-size: 0.82rem;
            font-weight: 700;
        }

        .town-full29-badge {
            display: inline-flex;
            align-items: center;
            background-color: #eff6ff;
            color: #1d4ed8;
            border: 1px solid #bfdbfe;
            padding: 4px 10px;
            border-radius: 8px;
            font-size: 0.82rem;
            font-weight: 700;
        }

        /* 狀態與單位徽章 */
        .user-name-title {
            font-weight: 700;
            color: #1e293b;
            font-size: 0.93rem;
            line-height: 1.4;
            word-break: break-word;
        }

        .fac-id-badge {
            display: inline-flex;
            align-items: center;
            background-color: #f1f5f9;
            color: #475569;
            border: 1px solid #cbd5e1;
            border-radius: 5px;
            padding: 2px 7px;
            font-size: 0.75rem;
            font-weight: 600;
            font-family: Consolas, Monaco, "Courier New", monospace;
            margin-top: 4px;
            white-space: nowrap;
        }

        .badge-active {
            display: inline-block;
            background-color: #dcfce7;
            color: #166534;
            padding: 2px 8px;
            border-radius: 12px;
            font-size: 0.75rem;
            font-weight: 600;
            margin-top: 3px;
        }

        .badge-inactive {
            display: inline-block;
            background-color: #fee2e2;
            color: #991b1b;
            padding: 2px 8px;
            border-radius: 12px;
            font-size: 0.75rem;
            font-weight: 600;
            margin-top: 3px;
        }

        .badge-unit {
            display: inline-block;
            background-color: #e0f2fe;
            color: #0369a1;
            border: 1px solid #bae6fd;
            padding: 4px 10px;
            border-radius: 8px;
            font-size: 0.82rem;
            font-weight: 600;
        }

        .badge-unit-empty {
            display: inline-block;
            background-color: #f1f5f9;
            color: #64748b;
            border: 1px dashed #cbd5e1;
            padding: 4px 10px;
            border-radius: 8px;
            font-size: 0.8rem;
            font-weight: 500;
        }

        /* ========================================== */
        /* 權限設定對話框 (Modal) 緊湊高密度排版       */
        /* ========================================== */
        .modal-user-bar {
            background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%);
            border: 1px solid #cbd5e1;
            border-radius: 10px;
            padding: 12px 16px;
            margin-bottom: 14px;
        }

        .unit-quick-tag {
            display: inline-block;
            padding: 3px 10px;
            font-size: 0.78rem;
            font-weight: 600;
            color: #334155;
            background-color: #ffffff;
            border: 1px solid #cbd5e1;
            border-radius: 14px;
            cursor: pointer;
            transition: all 0.15s;
            user-select: none;
            margin-right: 4px;
            margin-bottom: 4px;
        }

        .unit-quick-tag:hover {
            background-color: #e0f2fe;
            color: #0369a1;
            border-color: #7dd3fc;
        }

        .unit-quick-tag.active-tag {
            background-color: #0284c7;
            color: #ffffff;
            border-color: #0284c7;
        }

        .perm-card-box {
            border: 1px solid #cbd5e1;
            border-radius: 10px;
            padding: 10px 12px;
            background-color: #f8fafc;
            height: 100%;
            transition: box-shadow 0.15s, border-color 0.15s;
        }

        .perm-card-box:hover {
            border-color: #94a3b8;
            box-shadow: 0 2px 8px rgba(15, 23, 42, 0.05);
        }

        .perm-card-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 1px solid #e2e8f0;
            padding-bottom: 6px;
            margin-bottom: 8px;
        }

        /* 業務模組內部核取方塊：橫向彈性多欄排列 (Eliminates vertical stacking) */
        .perm-checkbox-group ul {
            list-style: none;
            padding: 0;
            margin: 0;
            display: flex;
            flex-wrap: wrap;
            gap: 5px 6px;
        }

        .perm-checkbox-group li {
            margin: 0;
            padding: 0;
            flex: 0 1 auto;
        }

        .perm-checkbox-group label {
            display: inline-flex;
            align-items: center;
            margin: 0;
            padding: 3px 8px;
            font-size: 0.81rem;
            color: #334155;
            background-color: #ffffff;
            border: 1px solid #cbd5e1;
            border-radius: 6px;
            cursor: pointer;
            transition: all 0.12s ease;
            user-select: none;
        }

        .perm-checkbox-group label:hover {
            background-color: #f0f9ff;
            border-color: #7dd3fc;
        }

        .perm-checkbox-group input[type="checkbox"] {
            margin-right: 5px;
            cursor: pointer;
        }

        .perm-checkbox-group li.checked-item label {
            background-color: #e0f2fe;
            border-color: #38bdf8;
            color: #0369a1;
            font-weight: 600;
        }

        /* 行政區 29 區橫向多欄網格 (一排 8~10 個，僅需 3 列高，免捲軸) */
        .town-grid-container {
            padding: 12px;
            background: #f8fafc;
            border: 1px solid #cbd5e1;
            border-radius: 10px;
        }

        .town-grid-container ul {
            list-style: none;
            padding: 0;
            margin: 0;
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(95px, 1fr));
            gap: 6px 8px;
        }

        .town-grid-container li {
            margin: 0;
            padding: 0;
        }

        .town-grid-container label {
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0;
            padding: 5px 6px;
            font-size: 0.84rem;
            color: #334155;
            background-color: #ffffff;
            border: 1px solid #cbd5e1;
            border-radius: 7px;
            cursor: pointer;
            transition: all 0.12s ease;
            user-select: none;
            white-space: nowrap;
        }

        .town-grid-container label:hover {
            background-color: #f0fdf4;
            border-color: #86efac;
        }

        .town-grid-container input[type="checkbox"] {
            margin-right: 5px;
            cursor: pointer;
        }

        .town-grid-container li.checked-item label {
            background-color: #dcfce7;
            border-color: #4ade80;
            color: #166534;
            font-weight: 700;
        }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <form id="formMain" runat="server">
        <asp:ScriptManager ID="sm1" runat="server"></asp:ScriptManager>

        <div class="container-fluid px-md-4">
            <!-- 麵包屑導航 -->
            <nav aria-label="breadcrumb">
                <ol class="breadcrumb bg-transparent px-0 mb-2">
                    <li class="breadcrumb-item"><a href="<%= ResolveUrl("~/MainPage.aspx") %>"><i class="fas fa-home mr-1"></i>主控儀表板</a></li>
                    <li class="breadcrumb-item text-muted">系統維運管理</li>
                    <li class="breadcrumb-item active font-weight-bold" aria-current="page">帳號與權限管理</li>
                </ol>
            </nav>

            <!-- 操作訊息提示 -->
            <asp:Panel ID="pnlAlert" runat="server" Visible="false" CssClass="alert alert-success alert-dismissible fade show" role="alert">
                <i class="fas fa-check-circle mr-2"></i><asp:Literal ID="litAlertMsg" runat="server"></asp:Literal>
                <button type="button" class="close" data-dismiss="alert" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </asp:Panel>

            <!-- 主卡片 -->
            <div class="card admin-card">
                <div class="admin-card-header d-flex flex-wrap justify-content-between align-items-center">
                    <div>
                        <h4 class="mb-1 font-weight-bold text-dark">
                            <i class="fas fa-users-cog text-primary mr-2"></i>系統使用者帳號與權限清單
                        </h4>
                        <span class="text-muted small">配置固定溢散源管理平台各業務模組權限、所屬單位分類、稽查初複三審與行政區授權</span>
                    </div>
                    <div class="mt-2 mt-sm-0">
                        <asp:Button ID="btnOpenNewAcc" runat="server" CssClass="btn btn-primary shadow-sm font-weight-bold px-3" Text="+ 新增帳號" OnClick="btnOpenNewAcc_Click" />
                    </div>
                </div>

                <div class="card-body pt-3">
                    <!-- 整合式篩選與搜尋工具列 -->
                    <div class="filter-toolbar">
                        <!-- PUnit 單位分類標籤 (藥丸篩選) -->
                        <div class="punit-nav mb-3">
                            <span class="text-secondary font-weight-bold mr-1 small"><i class="fas fa-filter mr-1"></i>單位分類：</span>
                            <asp:LinkButton ID="btnFilterAll" runat="server" CssClass="punit-pill active" OnClick="FilterPUnit_Click" CommandArgument="ALL">全部帳號</asp:LinkButton>
                            <asp:Repeater ID="repPUnitTabs" runat="server">
                                <ItemTemplate>
                                    <asp:LinkButton ID="btnTab" runat="server" 
                                        CssClass='<%# "punit-pill " + (CurrentPUnit == Convert.ToString(Eval("PUnit")) ? "active" : "") %>'
                                        CommandArgument='<%# Eval("PUnit") %>' 
                                        OnClick="FilterPUnit_Click">
                                        <%# Eval("PUnit") %> <span class="ml-1 opacity-75">(<%# Eval("UserCount") %>)</span>
                                    </asp:LinkButton>
                                </ItemTemplate>
                            </asp:Repeater>
                        </div>

                        <!-- 搜尋列與統計資訊 -->
                        <div class="d-flex flex-wrap justify-content-between align-items-center">
                            <div style="min-width: 320px; max-width: 460px; flex: 1;">
                                <div class="input-group input-group-sm">
                                    <div class="input-group-prepend">
                                        <span class="input-group-text bg-white border-right-0"><i class="fas fa-search text-muted"></i></span>
                                    </div>
                                    <asp:TextBox ID="txtKeyword" runat="server" CssClass="form-control border-left-0" placeholder="搜尋帳號 (UserID)、姓名、所屬單位或管制編號..."></asp:TextBox>
                                    <div class="input-group-append">
                                        <asp:Button ID="btnSearch" runat="server" Text="查詢" CssClass="btn btn-primary px-3 font-weight-bold" OnClick="btnSearch_Click" />
                                    </div>
                                </div>
                            </div>
                            <div class="mt-2 mt-md-0 text-muted small">
                                目前顯示：<span id="spnTotalCount" class="font-weight-bold text-primary"><asp:Literal ID="litTotalCount" runat="server" Text="0"></asp:Literal></span> 筆帳號
                            </div>
                        </div>
                    </div>

                    <!-- 帳號資料表格 -->
                    <div class="table-responsive">
                        <table class="table acc-table table-hover">
                            <thead>
                                <tr>
                                    <th style="width: 125px;">帳號 / 狀態</th>
                                    <th style="min-width: 215px; width: 235px;">名稱 / 管制編號</th>
                                    <th style="width: 105px;">所屬單位</th>
                                    <th>配置權限 (依業務群組)</th>
                                    <th style="width: 220px;">可瀏覽行政區</th>
                                    <th style="width: 128px;" class="text-center">操作功能</th>
                                </tr>
                            </thead>
                            <tbody>
                                <asp:Repeater ID="repUserList" runat="server" OnItemCommand="repUserList_ItemCommand">
                                    <ItemTemplate>
                                        <tr>
                                            <!-- 帳號與啟用狀態 -->
                                            <td class="text-nowrap col-user">
                                                <div class="font-weight-bold text-dark user-id-title" style="font-size: 0.95rem;">
                                                    <i class="fas fa-user-circle text-primary mr-1 opacity-75"></i><%# Eval("UserID") %>
                                                </div>
                                                <span class='<%# Convert.ToString(Eval("Acc_State")) == "OK" ? "badge-active" : "badge-inactive" %>'>
                                                    <%# Convert.ToString(Eval("Acc_State")) == "OK" ? "正常啟用" : "已停用" %>
                                                </span>
                                            </td>

                                            <!-- 姓名 / 單位名稱與管編 -->
                                            <td class="col-name">
                                                <div class="user-name-title"><%# Eval("Name") %></div>
                                                <%# !string.IsNullOrEmpty(Convert.ToString(Eval("FAC_ID"))) ? "<span class='fac-id-badge'><i class='fas fa-industry mr-1 text-secondary'></i>管編: " + Eval("FAC_ID") + "</span>" : "" %>
                                                <%# (Eval("Email") != null && Eval("Email") != DBNull.Value && !string.IsNullOrEmpty(Convert.ToString(Eval("Email")))) ? "<div class='text-muted small mt-1' style='font-size:0.75rem;'><i class='fas fa-envelope mr-1 text-info'></i>" + Eval("Email") + "</div>" : "" %>
                                            </td>

                                            <!-- 單位 PUnit -->
                                            <td class="text-nowrap col-unit">
                                                <span class="mobile-field-label">所屬單位：</span>
                                                <span class='<%# string.IsNullOrEmpty(Convert.ToString(Eval("PUnit"))) ? "badge-unit-empty" : "badge-unit" %>'>
                                                    <%# string.IsNullOrEmpty(Convert.ToString(Eval("PUnit"))) ? "未指定" : Eval("PUnit") %>
                                                </span>
                                            </td>

                                            <!-- 權限結構 (多欄緊湊卡片網格) -->
                                            <td class="col-perm">
                                                <span class="mobile-field-label"><i class="fas fa-shield-alt mr-1"></i>配置業務權限：</span>
                                                <%# RenderUserPermissions(Eval("LIC"), Eval("LIC2")) %>
                                            </td>

                                            <!-- 行政區 (全區智慧折疊 / 3欄緊湊網格) -->
                                            <td class="col-town">
                                                <span class="mobile-field-label"><i class="fas fa-map-marker-alt mr-1"></i>可瀏覽轄區：</span>
                                                <%# RenderUserTowns(Convert.ToString(Eval("UserID"))) %>
                                            </td>

                                            <!-- 功能操作 -->
                                            <td class="text-center col-action">
                                                <div class="d-flex flex-column action-btn-group" style="gap: 5px;">
                                                    <asp:LinkButton ID="btnSetLic" runat="server" CssClass="btn btn-info btn-sm shadow-sm w-100 font-weight-bold"
                                                        CommandName="SetLic" CommandArgument='<%# Eval("UserID") %>'>
                                                        <i class="fas fa-sliders-h mr-1"></i>權限設定
                                                    </asp:LinkButton>

                                                    <asp:LinkButton ID="btnToggleState" runat="server" 
                                                        CssClass='<%# Convert.ToString(Eval("Acc_State")) == "OK" ? "btn btn-outline-danger btn-sm w-100" : "btn btn-outline-success btn-sm w-100" %>'
                                                        CommandName="ToggleState" 
                                                        CommandArgument='<%# Eval("UserID") + "|" + Eval("Acc_State") %>'
                                                        OnClientClick='<%# Convert.ToString(Eval("Acc_State")) == "OK" ? "return confirm(\"確定要停用此帳號嗎？\");" : "return confirm(\"確定要啟用此帳號嗎？\");" %>'>
                                                        <%# Convert.ToString(Eval("Acc_State")) == "OK" ? "停用帳號" : "啟用帳號" %>
                                                    </asp:LinkButton>

                                                    <asp:LinkButton ID="btnOpenResetModal" runat="server" 
                                                        CssClass="btn btn-outline-warning btn-sm w-100 font-weight-bold"
                                                        CommandName="OpenResetModal" 
                                                        CommandArgument='<%# Eval("UserID") + "|" + Eval("Name") + "|" + (Eval("Email") != DBNull.Value ? Eval("Email") : "") %>'>
                                                        <i class="fas fa-paper-plane mr-1"></i>重設並寄發密碼
                                                    </asp:LinkButton>
                                                </div>
                                            </td>
                                        </tr>
                                    </ItemTemplate>
                                </asp:Repeater>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>

        <!-- ========================================== -->
        <!-- 彈窗 1：權限、所屬單位與轄區設定 Modal     -->
        <!-- ========================================== -->
        <asp:Panel ID="pnlSetLicModal" runat="server" Visible="false">
            <div class="modal fade show" id="modalSetLic" tabindex="-1" role="dialog" style="display: block; background: rgba(15, 23, 42, 0.55);" aria-modal="true">
                <div class="modal-dialog modal-xl modal-dialog-scrollable" role="document" style="max-width: 1180px;">
                    <div class="modal-content border-0 shadow-lg" style="border-radius: 14px;">
                        <div class="modal-header bg-primary text-white py-3">
                            <h5 class="modal-title font-weight-bold">
                                <i class="fas fa-user-shield mr-2"></i>設定帳號權限、所屬單位與轄區
                            </h5>
                            <asp:LinkButton ID="btnCloseLicModalX" runat="server" CssClass="close text-white" OnClick="btnCloseModal_Click">&times;</asp:LinkButton>
                        </div>

                        <div class="modal-body p-3 px-md-4">
                            <!-- 當前編輯對象與所屬單位 (PUnit) 設定 -->
                            <div class="modal-user-bar">
                                <div class="row align-items-center">
                                    <div class="col-lg-4 mb-2 mb-lg-0">
                                        <span class="text-muted small font-weight-bold">設定對象：</span>
                                        <span class="h5 font-weight-bold text-primary mb-0 ml-1"><asp:Literal ID="litEditingUserID" runat="server"></asp:Literal></span>
                                        <span class="font-weight-bold text-dark ml-1">(<asp:Literal ID="litEditingName" runat="server"></asp:Literal>)</span>
                                        <asp:Literal ID="litEditingPUnit" runat="server" Visible="false"></asp:Literal>
                                    </div>
                                    <div class="col-lg-8">
                                        <div class="d-flex flex-wrap align-items-center">
                                            <label class="font-weight-bold text-dark small mb-0 mr-2">
                                                <i class="fas fa-building text-info mr-1"></i>所屬單位 (PUnit)：
                                            </label>
                                            <asp:TextBox ID="txtEditingPUnit" runat="server" CssClass="form-control form-control-sm mr-2" style="width: 140px; font-weight: 600;" placeholder="未指定 (可輸入)"></asp:TextBox>
                                            <div class="d-flex flex-wrap align-items-center mt-1 mt-sm-0" id="editUnitQuickTags">
                                                <span class="text-muted small mr-1">快選：</span>
                                                <span class="unit-quick-tag" onclick="setEditPUnit('空噪')">空噪</span>
                                                <span class="unit-quick-tag" onclick="setEditPUnit('空品')">空品</span>
                                                <span class="unit-quick-tag" onclick="setEditPUnit('區公所')">區公所</span>
                                                <span class="unit-quick-tag" onclick="setEditPUnit('康廷')">康廷</span>
                                                <span class="unit-quick-tag" onclick="setEditPUnit('環科')">環科</span>
                                                <span class="unit-quick-tag" onclick="setEditPUnit('市府')">市府</span>
                                                <span class="unit-quick-tag" onclick="setEditPUnit('環衛')">環衛</span>
                                                <span class="unit-quick-tag" onclick="setEditPUnit('環興')">環興</span>
                                                <span class="unit-quick-tag" onclick="setEditPUnit('SIP')">SIP</span>
                                                <span class="unit-quick-tag text-secondary" onclick="setEditPUnit('')">未指定(清空)</span>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- 權限群組清單 (三欄緊湊卡片 + 卡片內橫向膠囊排列) -->
                            <div class="d-flex flex-wrap justify-content-between align-items-center border-bottom pb-2 mb-2">
                                <h6 class="font-weight-bold text-dark mb-0">
                                    <i class="fas fa-layer-group text-info mr-2"></i>業務模組權限配置
                                </h6>
                                <div>
                                    <button type="button" class="btn btn-outline-primary btn-sm py-0 px-2" style="font-size: 0.78rem;" onclick="toggleAllModuleChecks(true)">
                                        <i class="fas fa-check-square mr-1"></i>全模組全選
                                    </button>
                                    <button type="button" class="btn btn-outline-secondary btn-sm py-0 px-2 ml-1" style="font-size: 0.78rem;" onclick="toggleAllModuleChecks(false)">
                                        <i class="far fa-square mr-1"></i>全模組清空
                                    </button>
                                </div>
                            </div>

                            <div class="row" id="permModulesContainer">
                                <asp:Repeater ID="repPermGroups" runat="server" OnItemDataBound="repPermGroups_ItemDataBound">
                                    <ItemTemplate>
                                        <div class="col-md-6 col-lg-4 mb-2">
                                            <div class="perm-card-box">
                                                <div class="perm-card-header">
                                                    <span class="font-weight-bold text-dark" style="font-size: 0.86rem;">
                                                        <i class="fas fa-cube text-primary mr-1 opacity-75"></i><asp:Literal ID="litGroupName" runat="server" Text='<%# Eval("Key") %>'></asp:Literal>
                                                    </span>
                                                    <div>
                                                        <button type="button" class="btn btn-outline-primary btn-xs py-0 px-2" style="font-size: 0.73rem;" onclick="toggleGroupChecks(this, true)">全選</button>
                                                        <button type="button" class="btn btn-outline-secondary btn-xs py-0 px-2" style="font-size: 0.73rem;" onclick="toggleGroupChecks(this, false)">清空</button>
                                                    </div>
                                                </div>

                                                <!-- 該群組所屬的權限項目核取方塊 (UnorderedList 實現橫向多排膠囊) -->
                                                <div class="perm-checkbox-group">
                                                    <asp:CheckBoxList ID="cblGroupItems" runat="server" RepeatLayout="UnorderedList"></asp:CheckBoxList>
                                                </div>
                                            </div>
                                        </div>
                                    </ItemTemplate>
                                </asp:Repeater>
                            </div>

                            <!-- 可瀏覽行政區設定 (橫向 8~10 欄高密度網格) -->
                            <div class="d-flex flex-wrap justify-content-between align-items-center border-bottom pb-2 mt-3 mb-2">
                                <div>
                                    <h6 class="font-weight-bold text-dark mb-0 d-inline-block mr-2">
                                        <i class="fas fa-map-marked-alt text-success mr-2"></i>可瀏覽行政區轄區限制
                                    </h6>
                                    <span class="text-muted small">* 若皆未勾選，系統預設為「不限制（可看全部行政區）」</span>
                                </div>
                                <div class="mt-1 mt-sm-0">
                                    <button type="button" class="btn btn-outline-success btn-sm py-0 px-2" style="font-size: 0.78rem;" onclick="toggleTownChecks(true)">
                                        <i class="fas fa-check-double mr-1"></i>全選新北 29 區
                                    </button>
                                    <button type="button" class="btn btn-outline-secondary btn-sm py-0 px-2 ml-1" style="font-size: 0.78rem;" onclick="toggleTownChecks(false)">
                                        <i class="fas fa-globe-asia mr-1"></i>不限制 (全部清空)
                                    </button>
                                </div>
                            </div>

                            <div class="town-grid-container" id="townGridBox">
                                <asp:CheckBoxList ID="cblTowns" runat="server" RepeatLayout="UnorderedList"></asp:CheckBoxList>
                            </div>
                        </div>

                        <div class="modal-footer bg-light py-2">
                            <asp:Button ID="btnCloseLicModal" runat="server" CssClass="btn btn-secondary btn-sm px-3" Text="取消" OnClick="btnCloseModal_Click" />
                            <asp:Button ID="btnSaveLic" runat="server" CssClass="btn btn-primary btn-sm px-4 font-weight-bold" Text="確認儲存權限與單位設定" OnClick="btnSaveLic_Click" />
                        </div>
                    </div>
                </div>
            </div>
        </asp:Panel>

        <!-- ========================================== -->
        <!-- 彈窗 2：新增帳號 (New Account Modal)        -->
        <!-- ========================================== -->
        <asp:Panel ID="pnlNewAccModal" runat="server" Visible="false">
            <div class="modal fade show" id="modalNewAcc" tabindex="-1" role="dialog" style="display: block; background: rgba(15, 23, 42, 0.55);" aria-modal="true">
                <div class="modal-dialog modal-dialog-centered" role="document">
                    <div class="modal-content border-0 shadow-lg" style="border-radius: 16px;">
                        <div class="modal-header bg-primary text-white">
                            <h5 class="modal-title font-weight-bold">
                                <i class="fas fa-user-plus mr-2"></i>新增使用者帳號
                            </h5>
                            <asp:LinkButton ID="btnCloseNewAccX" runat="server" CssClass="close text-white" OnClick="btnCloseModal_Click">&times;</asp:LinkButton>
                        </div>
                        <div class="modal-body p-4">
                            <div class="form-group mb-3">
                                <label class="font-weight-bold small text-muted">登入帳號 (UserID) <span class="text-danger">*</span></label>
                                <asp:TextBox ID="txtNewUserId" runat="server" CssClass="form-control" placeholder="請輸入帳號 (如: F109020)"></asp:TextBox>
                            </div>
                            <div class="form-group mb-3">
                                <label class="font-weight-bold small text-muted">預設密碼 <span class="text-danger">*</span></label>
                                <div class="input-group">
                                    <asp:TextBox ID="txtNewPassword" runat="server" CssClass="form-control" placeholder="8-20 碼，需含英文大小寫、數字與符號"></asp:TextBox>
                                    <div class="input-group-append">
                                        <button type="button" class="btn btn-outline-secondary btn-sm" onclick="generateRandomStrongPwd();" title="自動產生合規強密碼">
                                            <i class="fas fa-magic mr-1"></i>隨機產生
                                        </button>
                                    </div>
                                </div>
                                <small class="form-text text-muted mt-1" style="font-size: 0.78rem; line-height: 1.4;">
                                    <i class="fas fa-shield-alt text-info mr-1"></i>須符合強密碼原則：長度 <strong>8-20 碼</strong>，且同時包含<strong>英文大寫、英文小寫、數字及特殊符號</strong>。
                                </small>
                            </div>
                            <div class="form-group mb-3">
                                <label class="font-weight-bold small text-muted">使用者姓名 <span class="text-danger">*</span></label>
                                <asp:TextBox ID="txtNewName" runat="server" CssClass="form-control" placeholder="請輸入姓名 (如: 王大明)"></asp:TextBox>
                            </div>
                            <div class="form-group mb-3">
                                <label class="font-weight-bold small text-muted">電子郵件 (Email)</label>
                                <asp:TextBox ID="txtNewEmail" runat="server" CssClass="form-control" placeholder="例如: user@ntpc.gov.tw"></asp:TextBox>
                            </div>
                            <div class="form-group mb-3">
                                <label class="font-weight-bold small text-muted">所屬單位分類 (PUnit)</label>
                                <asp:TextBox ID="txtNewPUnit" runat="server" CssClass="form-control" placeholder="例如: 空噪、區公所、康廷、環科..."></asp:TextBox>
                                <div class="mt-2">
                                    <span class="unit-quick-tag" onclick="setNewPUnit('空噪')">空噪</span>
                                    <span class="unit-quick-tag" onclick="setNewPUnit('空品')">空品</span>
                                    <span class="unit-quick-tag" onclick="setNewPUnit('區公所')">區公所</span>
                                    <span class="unit-quick-tag" onclick="setNewPUnit('康廷')">康廷</span>
                                    <span class="unit-quick-tag" onclick="setNewPUnit('環科')">環科</span>
                                    <span class="unit-quick-tag" onclick="setNewPUnit('市府')">市府</span>
                                    <span class="unit-quick-tag" onclick="setNewPUnit('環衛')">環衛</span>
                                    <span class="unit-quick-tag" onclick="setNewPUnit('環興')">環興</span>
                                    <span class="unit-quick-tag" onclick="setNewPUnit('SIP')">SIP</span>
                                </div>
                            </div>
                        </div>
                        <div class="modal-footer bg-light">
                            <asp:Button ID="btnCancelNewAcc" runat="server" CssClass="btn btn-secondary" Text="取消" OnClick="btnCloseModal_Click" />
                            <asp:Button ID="btnConfirmNewAcc" runat="server" CssClass="btn btn-primary font-weight-bold px-4" Text="確認新增" OnClick="btnConfirmNewAcc_Click" />
                        </div>
                    </div>
                </div>
            </div>
        </asp:Panel>

        <!-- ========================================== -->
        <!-- 彈窗 3：配發臨時密碼並寄送信箱 Modal       -->
        <!-- ========================================== -->
        <asp:Panel ID="pnlResetPwdModal" runat="server" Visible="false">
            <div class="modal fade show" style="display: block; background-color: rgba(15, 23, 42, 0.65); z-index: 1060;" tabindex="-1">
                <div class="modal-dialog modal-dialog-centered" style="max-width: 490px;">
                    <div class="modal-content border-0 shadow-lg" style="border-radius: 14px; overflow: hidden;">
                        <div class="modal-header bg-primary text-white py-3 px-4">
                            <h5 class="modal-title font-weight-bold mb-0">
                                <i class="fas fa-paper-plane mr-2"></i>配發臨時密碼並寄送信箱
                            </h5>
                            <asp:LinkButton ID="btnCloseResetModalX" runat="server" CssClass="close text-white" OnClick="btnCloseResetModal_Click">&times;</asp:LinkButton>
                        </div>
                        <div class="modal-body p-4">
                            <div class="form-group mb-3">
                                <label class="font-weight-bold text-secondary small">目標使用者帳號</label>
                                <div class="p-2 bg-light rounded text-dark font-weight-bold" style="font-size: 1rem; border: 1px solid #e2e8f0;">
                                    <i class="fas fa-user-circle mr-2 text-primary"></i><asp:Literal ID="litResetTargetInfo" runat="server"></asp:Literal>
                                </div>
                                <asp:HiddenField ID="hfResetTargetUserId" runat="server" />
                            </div>

                            <div class="form-group mb-3">
                                <label class="font-weight-bold text-dark small" for="<%= txtResetTargetEmail.ClientID %>">
                                    收件電子信箱 (Email) <span class="text-danger">*</span>
                                </label>
                                <div class="input-group">
                                    <div class="input-group-prepend">
                                        <span class="input-group-text bg-white"><i class="fas fa-envelope text-muted"></i></span>
                                    </div>
                                    <asp:TextBox ID="txtResetTargetEmail" runat="server" CssClass="form-control" placeholder="請輸入收件者信箱 (例如: user@ntpc.gov.tw)"></asp:TextBox>
                                </div>
                                <small class="form-text text-muted mt-1">
                                    <i class="fas fa-info-circle mr-1 text-info"></i>系統產生臨時密碼後將直接寄發至此信箱，並同步更新該帳號之 Email。
                                </small>
                            </div>

                            <div class="alert alert-warning small mb-0 p-3" style="border-radius: 8px; line-height: 1.5;">
                                <strong><i class="fas fa-shield-alt mr-1"></i>資安控管機制：</strong><br/>
                                • 密碼重設後原密碼立即作廢失效。<br/>
                                • 系統會自動將原密碼記入歷史表記錄，防範日後重複使用。<br/>
                                • 使用者持臨時密碼登入後，系統將<strong>強制要求立即修改密碼</strong>方可操作。
                            </div>
                        </div>
                        <div class="modal-footer bg-light py-2 px-4 d-flex justify-content-between">
                            <asp:Button ID="btnCancelResetModal" runat="server" CssClass="btn btn-secondary px-3" Text="取消" OnClick="btnCloseResetModal_Click" />
                            <asp:Button ID="btnConfirmSendTempPwd" runat="server" CssClass="btn btn-primary px-4 font-weight-bold" Text="確認產生並發送信件" OnClick="btnConfirmSendTempPwd_Click" OnClientClick="if(!confirm('確定要產生臨時密碼並發送信件給該使用者嗎？')){return false;} this.disabled=true; this.value='正在寄送郵件中...'; __doPostBack(this.name, '');" UseSubmitBehavior="false" />
                        </div>
                    </div>
                </div>
            </div>
        </asp:Panel>
    </form>
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="ScriptsContent" runat="server">
    <script>
        function syncCheckboxHighlight(containerSelector) {
            $(containerSelector).find('input[type="checkbox"]').each(function () {
                var $li = $(this).closest('li');
                if ($(this).prop('checked')) {
                    $li.addClass('checked-item');
                } else {
                    $li.removeClass('checked-item');
                }
            });
        }

        function toggleGroupChecks(btn, isCheck) {
            var container = $(btn).closest('.perm-card-box').find('.perm-checkbox-group');
            container.find('input[type="checkbox"]').prop('checked', isCheck);
            syncCheckboxHighlight(container);
        }

        function toggleAllModuleChecks(isCheck) {
            var container = $('#permModulesContainer');
            container.find('input[type="checkbox"]').prop('checked', isCheck);
            syncCheckboxHighlight(container);
        }

        function toggleTownChecks(isCheck) {
            var container = $('#townGridBox');
            container.find('input[type="checkbox"]').prop('checked', isCheck);
            syncCheckboxHighlight(container);
        }

        function setNewPUnit(val) {
            $('#<%= txtNewPUnit.ClientID %>').val(val);
        }

        function setEditPUnit(val) {
            var $input = $('#<%= txtEditingPUnit.ClientID %>');
            $input.val(val);
            highlightUnitQuickTag(val);
        }

        function highlightUnitQuickTag(val) {
            $('#editUnitQuickTags .unit-quick-tag').each(function () {
                var tagText = $.trim($(this).text());
                if ((val === '' && tagText.indexOf('未指定') >= 0) || tagText === val) {
                    $(this).addClass('active-tag');
                } else {
                    $(this).removeClass('active-tag');
                }
            });
        }

        $(function () {
            syncCheckboxHighlight('#permModulesContainer');
            syncCheckboxHighlight('#townGridBox');

            $(document).on('change', '#permModulesContainer input[type="checkbox"], #townGridBox input[type="checkbox"]', function () {
                var $li = $(this).closest('li');
                if ($(this).prop('checked')) {
                    $li.addClass('checked-item');
                } else {
                    $li.removeClass('checked-item');
                }
            });

            var $editUnitInput = $('#<%= txtEditingPUnit.ClientID %>');
            if ($editUnitInput.length > 0) {
                highlightUnitQuickTag($.trim($editUnitInput.val()));
                $editUnitInput.on('input change', function () {
                    highlightUnitQuickTag($.trim($(this).val()));
                });
            }

        function generateRandomStrongPwd() {
            var upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
            var lower = 'abcdefghijkmnopqrstuvwxyz';
            var digits = '23456789';
            var specials = '!@#$%*-_+';
            var all = upper + lower + digits + specials;
            var pwd = [
                upper.charAt(Math.floor(Math.random() * upper.length)),
                lower.charAt(Math.floor(Math.random() * lower.length)),
                digits.charAt(Math.floor(Math.random() * digits.length)),
                specials.charAt(Math.floor(Math.random() * specials.length))
            ];
            for (var i = 0; i < 6; i++) {
                pwd.push(all.charAt(Math.floor(Math.random() * all.length)));
            }
            for (var i = pwd.length - 1; i > 0; i--) {
                var j = Math.floor(Math.random() * (i + 1));
                var temp = pwd[i];
                pwd[i] = pwd[j];
                pwd[j] = temp;
            }
            var finalPwd = pwd.join('');
            $('#<%= txtNewPassword.ClientID %>').val(finalPwd);
        }

        $(function () {
            // 即時快速鍵盤過濾 (提供行動端 427 筆即搜即現，免等 PostBack 重新整理)
            var $kwInput = $('#<%= txtKeyword.ClientID %>');
            if ($kwInput.length > 0) {
                $kwInput.on('input', function () {
                    var kw = $.trim($(this).val()).toLowerCase();
                    var count = 0;
                    $('.acc-table tbody tr').each(function () {
                        if (!kw) {
                            $(this).show();
                            count++;
                            return;
                        }
                        var rowText = $(this).text().toLowerCase();
                        if (rowText.indexOf(kw) >= 0) {
                            $(this).show();
                            count++;
                        } else {
                            $(this).hide();
                        }
                    });
                    $('#spnTotalCount').text(count);
                });
            }
        });
    </script>
</asp:Content>
