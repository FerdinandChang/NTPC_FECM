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
                                目前顯示：<span class="font-weight-bold text-primary"><asp:Literal ID="litTotalCount" runat="server" Text="0"></asp:Literal></span> 筆帳號
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
                                            <!-- 帳號 -->
                                            <td class="text-nowrap">
                                                <div class="font-weight-bold text-dark" style="font-size: 0.95rem;"><%# Eval("UserID") %></div>
                                                <span class='<%# Convert.ToString(Eval("Acc_State")) == "OK" ? "badge-active" : "badge-inactive" %>'>
                                                    <%# Convert.ToString(Eval("Acc_State")) == "OK" ? "正常啟用" : "已停用" %>
                                                </span>
                                            </td>

                                            <!-- 姓名 / 單位名稱與管編 -->
                                            <td>
                                                <div class="user-name-title"><%# Eval("Name") %></div>
                                                <%# !string.IsNullOrEmpty(Convert.ToString(Eval("FAC_ID"))) ? "<span class='fac-id-badge'><i class='fas fa-industry mr-1 text-secondary'></i>管編: " + Eval("FAC_ID") + "</span>" : "" %>
                                            </td>

                                            <!-- 單位 PUnit -->
                                            <td class="text-nowrap">
                                                <span class='<%# string.IsNullOrEmpty(Convert.ToString(Eval("PUnit"))) ? "badge-unit-empty" : "badge-unit" %>'>
                                                    <%# string.IsNullOrEmpty(Convert.ToString(Eval("PUnit"))) ? "未指定" : Eval("PUnit") %>
                                                </span>
                                            </td>

                                            <!-- 權限結構 (多欄緊湊卡片網格) -->
                                            <td>
                                                <%# RenderUserPermissions(Eval("LIC"), Eval("LIC2")) %>
                                            </td>

                                            <!-- 行政區 (全區智慧折疊 / 3欄緊湊網格) -->
                                            <td>
                                                <%# RenderUserTowns(Convert.ToString(Eval("UserID"))) %>
                                            </td>

                                            <!-- 功能操作 -->
                                            <td class="text-center">
                                                <div class="d-flex flex-column" style="gap: 5px;">
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
                                <asp:TextBox ID="txtNewPassword" runat="server" CssClass="form-control" placeholder="請設定 6 位數以上初始密碼"></asp:TextBox>
                            </div>
                            <div class="form-group mb-3">
                                <label class="font-weight-bold small text-muted">使用者姓名 <span class="text-danger">*</span></label>
                                <asp:TextBox ID="txtNewName" runat="server" CssClass="form-control" placeholder="請輸入姓名 (如: 王大明)"></asp:TextBox>
                            </div>
                            <div class="form-group mb-3">
                                <label class="font-weight-bold small text-muted">所屬單位分類 (PUnit)</label>
                                <asp:TextBox ID="txtNewPUnit" runat="server" CssClass="form-control" placeholder="例如: 空品、區公所、康廷、環科..."></asp:TextBox>
                                <div class="mt-2">
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
        });
    </script>
</asp:Content>
