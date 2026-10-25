<%@ Page Title="霈?犖撖Ⅳ" Language="C#" MasterPageFile="~/MainPage.Master" AutoEventWireup="true" CodeBehind="PasswordChange.aspx.cs" Inherits="NTPC_FEC.Modules.Manager.PasswordChange" %>

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

        .rule-item {
            transition: all 0.2s ease;
        }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="container">
        <!-- 撠暻萄?撅?-->
        <nav aria-label="breadcrumb">
            <ol class="breadcrumb bg-transparent px-0 mb-3">
                <li class="breadcrumb-item"><a href="<%= ResolveUrl("~/MainPage.aspx") %>"><i class="fas fa-home mr-1"></i>銝餅?銵冽</a></li>
                <li class="breadcrumb-item active" aria-current="page">撣唾?閮剖?</li>
                <li class="breadcrumb-item active" aria-current="page">霈?犖撖Ⅳ</li>
            </ol>
        </nav>

        <div class="card pwd-card">
            <div class="pwd-card-header">
                <h5 class="mb-1 font-weight-bold"><i class="fas fa-key mr-2"></i>霈?犖撖Ⅳ</h5>
                <small class="opacity-75">?箔??頂蝯梯?閮??剁?撱箄降摰??湔?撖Ⅳ</small>
            </div>
            <div class="pwd-card-body">
                <form id="formPwd" runat="server">
                    <!-- ?內閮 -->
                    <asp:Panel ID="pnlAlert" runat="server" Visible="false" CssClass="alert alert-dismissible fade show mb-4" role="alert">
                        <asp:Literal ID="litAlertMsg" runat="server"></asp:Literal>
                    </asp:Panel>

                    <!-- 撣唾?鞈? -->
                    <div class="form-group mb-3">
                        <label class="form-label">?餃撣唾?</label>
                        <asp:TextBox ID="txtUserId" runat="server" CssClass="form-control-plaintext font-weight-bold text-muted px-2" ReadOnly="true"></asp:TextBox>
                    </div>

                    <!-- ??蝣?-->
                    <div class="form-group mb-3">
                        <label class="form-label" for="<%= txtOldPwd.ClientID %>">?桀???蝣?<span class="text-danger">*</span></label>
                        <div class="input-group">
                            <div class="input-group-prepend">
                                <span class="input-group-text"><i class="fas fa-lock text-muted"></i></span>
                            </div>
                            <asp:TextBox ID="txtOldPwd" runat="server" TextMode="Password" CssClass="form-control" placeholder="隢撓?亦?蝙?典?蝣? Required="true"></asp:TextBox>
                        </div>
                    </div>

                    <!-- ?啣?蝣?-->
                    <div class="form-group mb-3">
                        <label class="form-label" for="<%= txtNewPwd.ClientID %>">閮剖??啣?蝣?<span class="text-danger">*</span></label>
                        <div class="input-group">
                            <div class="input-group-prepend">
                                <span class="input-group-text"><i class="fas fa-shield-alt text-muted"></i></span>
                            </div>
                            <asp:TextBox ID="txtNewPwd" runat="server" TextMode="Password" CssClass="form-control" placeholder="8-20 蝣潘??怨?之撠神?摮?蝚西?" Required="true"></asp:TextBox>
                        </div>

                        <!-- ?單?撖Ⅳ撘瑕漲?內??-->
                        <div class="mt-2" id="pwdStrengthBox" style="display:none;">
                            <div class="d-flex justify-content-between align-items-center mb-1">
                                <span class="small font-weight-bold" style="font-size:0.8rem; color:#475569;">撖Ⅳ銴?摨佗?</span>
                                <span class="badge" id="pwdStrengthBadge" style="font-size:0.75rem;">撠??</span>
                            </div>
                            <div class="progress" style="height: 6px; border-radius: 3px; background-color: #e2e8f0;">
                                <div id="pwdStrengthBar" class="progress-bar transition-all" role="progressbar" style="width: 0%;" aria-valuenow="0" aria-valuemin="0" aria-valuemax="100"></div>
                            </div>
                            <div class="mt-2 p-2 bg-light rounded" style="font-size: 0.78rem; line-height: 1.6; border: 1px solid #e2e8f0;">
                                <div id="rule-len" class="rule-item text-muted"><i class="fas fa-times-circle text-secondary mr-1"></i>?瑕漲?喳? 8 ??20 蝣?/div>
                                <div id="rule-upper" class="rule-item text-muted"><i class="fas fa-times-circle text-secondary mr-1"></i>??望?憭批神摮? (A-Z)</div>
                                <div id="rule-lower" class="rule-item text-muted"><i class="fas fa-times-circle text-secondary mr-1"></i>??望?撠神摮? (a-z)</div>
                                <div id="rule-num" class="rule-item text-muted"><i class="fas fa-times-circle text-secondary mr-1"></i>??詨? (0-9)</div>
                                <div id="rule-sym" class="rule-item text-muted"><i class="fas fa-times-circle text-secondary mr-1"></i>??寞?蝚西? (!@#$%^&* 蝑?</div>
                            </div>
                        </div>

                        <div class="mt-2 p-2 bg-light rounded text-muted" style="font-size: 0.8rem; line-height: 1.5; border: 1px dashed #cbd5e1;">
                            <i class="fas fa-shield-alt text-info mr-1"></i><strong>撖Ⅳ摰??嚗?/strong><br/>
                            ??銝??strong>?桀?撖Ⅳ??銝活甇瑕撖Ⅳ</strong>?詨?<br/>
                            ??蝟餌絞摰?抒恣嚗?strong>?格??霈銝甈∪?蝣潘?瘥?90 憭拙????/strong>
                        </div>
                    </div>

                    <!-- 蝣箄??啣?蝣?-->
                    <div class="form-group mb-4">
                        <label class="form-label" for="<%= txtConfirmPwd.ClientID %>">?活蝣箄??啣?蝣?<span class="text-danger">*</span></label>
                        <div class="input-group">
                            <div class="input-group-prepend">
                                <span class="input-group-text"><i class="fas fa-check-circle text-muted"></i></span>
                            </div>
                            <asp:TextBox ID="txtConfirmPwd" runat="server" TextMode="Password" CssClass="form-control" placeholder="隢?甈∟撓?交撖Ⅳ" Required="true"></asp:TextBox>
                        </div>
                        <div id="pwdMatchMsg" class="small mt-1" style="font-size:0.8rem; display:none;"></div>
                    </div>

                    <!-- ??? -->
                    <div class="d-flex justify-content-between align-items-center mt-4">
                        <a href="<%= ResolveUrl("~/MainPage.aspx") %>" class="btn btn-light text-muted">
                            <i class="fas fa-arrow-left mr-1"></i>??銵冽
                        </a>
                        <asp:Button ID="btnSave" runat="server" CssClass="btn btn-submit" Text="蝣箄??脣?靽格" OnClick="btnSave_Click" />
                    </div>
                </form>
            </div>
        </div>
    </div>

    <script>
        document.addEventListener('DOMContentLoaded', function () {
            var txtNew = document.getElementById('<%= txtNewPwd.ClientID %>');
            var txtConfirm = document.getElementById('<%= txtConfirmPwd.ClientID %>');
            var box = document.getElementById('pwdStrengthBox');
            var bar = document.getElementById('pwdStrengthBar');
            var badge = document.getElementById('pwdStrengthBadge');
            var matchMsg = document.getElementById('pwdMatchMsg');

            function checkStrength() {
                var val = txtNew ? (txtNew.value || '') : '';
                if (!val) {
                    if (box) box.style.display = 'none';
                    return;
                }
                if (box) box.style.display = 'block';

                var lenOk = val.length >= 8 && val.length <= 20;
                var upperOk = /[A-Z]/.test(val);
                var lowerOk = /[a-z]/.test(val);
                var numOk = /[0-9]/.test(val);
                var symOk = /[^A-Za-z0-9]/.test(val);

                var elLen = document.getElementById('rule-len');
                if (elLen) {
                    elLen.innerHTML = lenOk ? '<i class="fas fa-check-circle text-success mr-1"></i>?瑕漲蝚血? (8-20 蝣?' : '<i class="fas fa-times-circle text-secondary mr-1"></i>?瑕漲?喳? 8 ??20 蝣?;
                    elLen.className = lenOk ? 'rule-item text-success font-weight-bold' : 'rule-item text-muted';
                }

                var elUpper = document.getElementById('rule-upper');
                if (elUpper) {
                    elUpper.innerHTML = upperOk ? '<i class="fas fa-check-circle text-success mr-1"></i>撌脣??怨?之撖?(A-Z)' : '<i class="fas fa-times-circle text-secondary mr-1"></i>??望?憭批神摮? (A-Z)';
                    elUpper.className = upperOk ? 'rule-item text-success font-weight-bold' : 'rule-item text-muted';
                }

                var elLower = document.getElementById('rule-lower');
                if (elLower) {
                    elLower.innerHTML = lowerOk ? '<i class="fas fa-check-circle text-success mr-1"></i>撌脣??怨??撖?(a-z)' : '<i class="fas fa-times-circle text-secondary mr-1"></i>??望?撠神摮? (a-z)';
                    elLower.className = lowerOk ? 'rule-item text-success font-weight-bold' : 'rule-item text-muted';
                }

                var elNum = document.getElementById('rule-num');
                if (elNum) {
                    elNum.innerHTML = numOk ? '<i class="fas fa-check-circle text-success mr-1"></i>撌脣??急摮?(0-9)' : '<i class="fas fa-times-circle text-secondary mr-1"></i>??詨? (0-9)';
                    elNum.className = numOk ? 'rule-item text-success font-weight-bold' : 'rule-item text-muted';
                }

                var elSym = document.getElementById('rule-sym');
                if (elSym) {
                    elSym.innerHTML = symOk ? '<i class="fas fa-check-circle text-success mr-1"></i>撌脣??怎畾泵??(!@#$%^&* 蝑?' : '<i class="fas fa-times-circle text-secondary mr-1"></i>??寞?蝚西? (!@#$%^&* 蝑?';
                    elSym.className = symOk ? 'rule-item text-success font-weight-bold' : 'rule-item text-muted';
                }

                var score = (lenOk ? 1 : 0) + (upperOk ? 1 : 0) + (lowerOk ? 1 : 0) + (numOk ? 1 : 0) + (symOk ? 1 : 0);
                var pct = score * 20;
                if (bar) bar.style.width = pct + '%';

                if (badge && bar) {
                    if (score <= 2) {
                        bar.className = 'progress-bar bg-danger';
                        badge.className = 'badge badge-danger';
                        badge.innerText = '撘瑕漲?摹 (?芰泵??皞?';
                    } else if (score <= 4) {
                        bar.className = 'progress-bar bg-warning';
                        badge.className = 'badge badge-warning text-dark';
                        badge.innerText = '撘瑕漲銝剔? (?喳???)';
                    } else {
                        bar.className = 'progress-bar bg-success';
                        badge.className = 'badge badge-success';
                        badge.innerText = '摰撘瑕漲擃?(蝚血?鞈?璅?)';
                    }
                }

                checkMatch();
            }

            function checkMatch() {
                var v1 = txtNew ? (txtNew.value || '') : '';
                var v2 = txtConfirm ? (txtConfirm.value || '') : '';
                if (!matchMsg) return;
                if (!v2) {
                    matchMsg.style.display = 'none';
                    return;
                }
                matchMsg.style.display = 'block';
                if (v1 === v2) {
                    matchMsg.className = 'small mt-1 text-success font-weight-bold';
                    matchMsg.innerHTML = '<i class="fas fa-check-circle mr-1"></i>?拇活撖Ⅳ頛詨?貊泵';
                } else {
                    matchMsg.className = 'small mt-1 text-danger font-weight-bold';
                    matchMsg.innerHTML = '<i class="fas fa-times-circle mr-1"></i>?拇活撖Ⅳ頛詨銝??湛?隢?甈∠Ⅱ隤?;
                }
            }

            if (txtNew) {
                txtNew.addEventListener('input', checkStrength);
            }
            if (txtConfirm) {
                txtConfirm.addEventListener('input', checkMatch);
            }
        });
    </script>
</asp:Content>

