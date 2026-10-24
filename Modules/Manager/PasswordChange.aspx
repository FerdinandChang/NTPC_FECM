<%@ Page Title="變更個人密碼" Language="C#" MasterPageFile="~/MainPage.Master" AutoEventWireup="true" CodeBehind="PasswordChange.aspx.cs" Inherits="NTPC_FEC.Modules.Manager.PasswordChange" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .pwd-card {
            max-width: 520px;
            margin: 30px auto;
            border-radius: 14px;
            border: none;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.08);
            overflow: hidden;
        }

        .pwd-card-header {
            background: linear-gradient(135deg, #184b72 0%, #1e6091 100%);
            color: #ffffff;
            padding: 20px 24px;
        }

        .pwd-card-body {
            padding: 30px;
            background: #ffffff;
        }

        .form-label {
            font-weight: 600;
            color: #374151;
            margin-bottom: 6px;
        }

        .input-group-text {
            background-color: #f8fafc;
            border-right: none;
        }

        .form-control {
            border-left: none;
        }

        .form-control:focus {
            box-shadow: none;
            border-color: #ced4da;
        }

        .btn-submit {
            background: linear-gradient(135deg, #184b72 0%, #1e6091 100%);
            color: white;
            font-weight: 600;
            padding: 10px 24px;
            border-radius: 8px;
            transition: all 0.2s;
        }

        .btn-submit:hover {
            color: white;
            opacity: 0.95;
            box-shadow: 0 4px 12px rgba(24, 75, 114, 0.35);
        }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="container">
        <!-- 導航麵包屑 -->
        <nav aria-label="breadcrumb">
            <ol class="breadcrumb bg-transparent px-0 mb-3">
                <li class="breadcrumb-item"><a href="<%= ResolveUrl("~/MainPage.aspx") %>"><i class="fas fa-home mr-1"></i>主控儀表板</a></li>
                <li class="breadcrumb-item active" aria-current="page">帳號設定</li>
                <li class="breadcrumb-item active" aria-current="page">變更個人密碼</li>
            </ol>
        </nav>

        <div class="card pwd-card">
            <div class="pwd-card-header">
                <h5 class="mb-1 font-weight-bold"><i class="fas fa-key mr-2"></i>變更個人密碼</h5>
                <small class="opacity-75">為保障系統資訊安全，建議定期更換密碼</small>
            </div>
            <div class="pwd-card-body">
                <form id="formPwd" runat="server">
                    <!-- 提示訊息 -->
                    <asp:Panel ID="pnlAlert" runat="server" Visible="false" CssClass="alert alert-dismissible fade show mb-4" role="alert">
                        <asp:Literal ID="litAlertMsg" runat="server"></asp:Literal>
                    </asp:Panel>

                    <!-- 帳號資訊 -->
                    <div class="form-group mb-3">
                        <label class="form-label">登入帳號</label>
                        <asp:TextBox ID="txtUserId" runat="server" CssClass="form-control-plaintext font-weight-bold text-muted px-2" ReadOnly="true"></asp:TextBox>
                    </div>

                    <!-- 原密碼 -->
                    <div class="form-group mb-3">
                        <label class="form-label" for="<%= txtOldPwd.ClientID %>">目前舊密碼 <span class="text-danger">*</span></label>
                        <div class="input-group">
                            <div class="input-group-prepend">
                                <span class="input-group-text"><i class="fas fa-lock text-muted"></i></span>
                            </div>
                            <asp:TextBox ID="txtOldPwd" runat="server" TextMode="Password" CssClass="form-control" placeholder="請輸入目前使用密碼" Required="true"></asp:TextBox>
                        </div>
                    </div>

                    <!-- 新密碼 -->
                    <div class="form-group mb-3">
                        <label class="form-label" for="<%= txtNewPwd.ClientID %>">設定新密碼 <span class="text-danger">*</span></label>
                        <div class="input-group">
                            <div class="input-group-prepend">
                                <span class="input-group-text"><i class="fas fa-shield-alt text-muted"></i></span>
                            </div>
                            <asp:TextBox ID="txtNewPwd" runat="server" TextMode="Password" CssClass="form-control" placeholder="8-20 碼，含英文大小寫、數字與符號" Required="true"></asp:TextBox>
                        </div>
                        <div class="mt-2 p-2 bg-light rounded text-muted" style="font-size: 0.8rem; line-height: 1.5; border: 1px dashed #cbd5e1;">
                            <i class="fas fa-shield-alt text-info mr-1"></i><strong>密碼安全原則：</strong><br/>
                            • 長度介於 8 至 20 碼，同時包含<strong>英文大寫、英文小寫、數字與特殊符號</strong><br/>
                            • 不可與<strong>目前密碼及前三次歷史密碼</strong>相同<br/>
                            • 系統安全控管：<strong>單日僅限變更一次密碼，每 90 天定期更換</strong>
                        </div>
                    </div>

                    <!-- 確認新密碼 -->
                    <div class="form-group mb-4">
                        <label class="form-label" for="<%= txtConfirmPwd.ClientID %>">再次確認新密碼 <span class="text-danger">*</span></label>
                        <div class="input-group">
                            <div class="input-group-prepend">
                                <span class="input-group-text"><i class="fas fa-check-circle text-muted"></i></span>
                            </div>
                            <asp:TextBox ID="txtConfirmPwd" runat="server" TextMode="Password" CssClass="form-control" placeholder="請再次輸入新密碼" Required="true"></asp:TextBox>
                        </div>
                    </div>

                    <!-- 送出按鈕 -->
                    <div class="d-flex justify-content-between align-items-center mt-4">
                        <a href="<%= ResolveUrl("~/MainPage.aspx") %>" class="btn btn-light text-muted">
                            <i class="fas fa-arrow-left mr-1"></i>回儀表板
                        </a>
                        <asp:Button ID="btnSave" runat="server" CssClass="btn btn-submit" Text="確認儲存修改" OnClick="btnSave_Click" />
                    </div>
                </form>
            </div>
        </div>
    </div>
</asp:Content>
