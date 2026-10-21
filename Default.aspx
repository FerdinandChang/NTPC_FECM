<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="NTPC_FEC.Default" %>

<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no" />
    <title>新北市固定溢散源管理平台 - 系統登入</title>
    
    <!-- 專屬 Favicon & 手機主畫面圖標 -->
    <link rel="shortcut icon" href="favicon.ico" type="image/x-icon" />
    <link rel="apple-touch-icon" href="apple-touch-icon.png" />
    
    <!-- 引入 Bootstrap 4 本地樣式 (避開機房 CSP 阻擋外部 CDN) -->
    <link rel="stylesheet" href="Content/bootstrap.min.css" />
    
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, "微軟正黑體", sans-serif;
            background: linear-gradient(135deg, #0c3547 0%, #1d6fa5 50%, #4facfe 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 15px;
            margin: 0;
        }

        .login-card {
            width: 100%;
            max-width: 440px;
            border-radius: 16px;
            box-shadow: 0 15px 35px rgba(0, 0, 0, 0.25);
            background: #ffffff;
            overflow: hidden;
            border: none;
            transition: all 0.3s ease;
        }

        .login-header {
            background: linear-gradient(135deg, #184b72 0%, #1e6091 100%);
            padding: 28px 24px 22px;
            text-align: center;
            color: #ffffff;
        }

        .login-header h1 {
            font-size: 22px;
            font-weight: 700;
            margin: 0 0 6px 0;
            letter-spacing: 0.5px;
        }

        .login-header p {
            font-size: 13px;
            margin: 0;
            opacity: 0.85;
            letter-spacing: 0.2px;
        }

        .login-body {
            padding: 30px 28px 24px;
        }

        .form-label {
            font-weight: 600;
            font-size: 14px;
            color: #374151;
            margin-bottom: 6px;
        }

        .form-control-lg {
            font-size: 15px;
            border-radius: 8px;
            border: 1.5px solid #d1d5db;
            padding: 10px 14px;
            transition: border-color 0.2s, box-shadow 0.2s;
        }

        .form-control-lg:focus {
            border-color: #1e6091;
            box-shadow: 0 0 0 3px rgba(30, 96, 145, 0.15);
        }

        .btn-login {
            background: linear-gradient(135deg, #1e6091 0%, #168aad 100%);
            border: none;
            color: #ffffff;
            font-size: 16px;
            font-weight: 600;
            border-radius: 8px;
            padding: 12px;
            letter-spacing: 1px;
            box-shadow: 0 4px 12px rgba(30, 96, 145, 0.3);
            transition: all 0.2s;
        }

        .btn-login:hover {
            background: linear-gradient(135deg, #184b72 0%, #1e6091 100%);
            color: #fff;
            transform: translateY(-1px);
            box-shadow: 0 6px 16px rgba(30, 96, 145, 0.4);
        }

        .validate-img {
            cursor: pointer;
            border-radius: 8px;
            height: 46px;
            width: 135px;
            min-width: 135px;
            border: 1.5px solid #d1d5db;
            transition: all 0.2s;
            object-fit: cover;
            background-color: #ffffff;
        }

        .validate-img:hover {
            opacity: 0.85;
            border-color: #1e6091;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
        }

        .toggle-password {
            cursor: pointer;
            position: absolute;
            right: 14px;
            top: 50%;
            transform: translateY(-50%);
            color: #6b7280;
            user-select: none;
            font-size: 13px;
            font-weight: 500;
            line-height: 1;
            z-index: 5;
        }

        .alert-custom {
            border-radius: 8px;
            font-size: 14px;
            padding: 10px 14px;
            margin-bottom: 18px;
        }

        .login-footer {
            text-align: center;
            font-size: 12px;
            color: #6b7280;
            padding: 0 28px 24px;
        }
    </style>
</head>
<body>
    <div id="loginApp" class="login-card">
        <div class="login-header">
            <div class="mb-2">
                <!-- 新北市政府風格徽章 SVG -->
                <svg width="42" height="42" viewBox="0 0 24 24" fill="#ffffff">
                    <path d="M12 1L3 5v6c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V5l-9-4zm-2 16l-4-4 1.41-1.41L10 14.17l6.59-6.59L18 9l-8 8z"/>
                </svg>
            </div>
            <h1>新北市固定溢散源管理平台</h1>
        </div>

        <div class="login-body">
            <!-- 錯誤提示 -->
            <div v-if="errorMessage" class="alert alert-danger alert-custom d-flex align-items-center" role="alert">
                <span class="mr-2">⚠️</span>
                <div>{{ errorMessage }}</div>
            </div>

            <form id="formLogin" v-on:submit.prevent="handleLogin">
                <!-- 帳號 -->
                <div class="form-group mb-3">
                    <label class="form-label" for="tbUser">系統帳號</label>
                    <input type="text" id="tbUser" class="form-control form-control-lg" 
                           placeholder="請輸入帳號" v-model="userId" required autofocus autocomplete="username" />
                </div>

                <!-- 密碼 -->
                <div class="form-group mb-3">
                    <label class="form-label" for="tbPassword">安全密碼</label>
                    <div class="position-relative">
                        <input :type="showPassword ? 'text' : 'password'" id="tbPassword" 
                               class="form-control form-control-lg pr-5" 
                               placeholder="請輸入密碼" v-model="password" required autocomplete="current-password" />
                        <span class="toggle-password" v-on:click="showPassword = !showPassword">
                            {{ showPassword ? '隱藏' : '顯示' }}
                        </span>
                    </div>
                </div>

                <!-- 驗證碼 -->
                <div class="form-group mb-3">
                    <label class="form-label" for="tbChkCode">圖形驗證碼</label>
                    <div class="d-flex align-items-center">
                        <input type="text" id="tbChkCode" class="form-control form-control-lg mr-2" 
                               placeholder="不分大小寫" v-model="validateCode" maxlength="5" required />
                        <img :src="captchaSrc" alt="驗證碼" class="validate-img" 
                             title="看不清楚？點擊換一張" v-on:click="refreshCaptcha" />
                    </div>
                    <small class="form-text text-muted">看不清楚？點擊圖片可立即刷新</small>
                </div>

                <!-- 記住帳號 -->
                <div class="form-group mb-4">
                    <div class="custom-control custom-checkbox">
                        <input type="checkbox" class="custom-control-input" id="chkRemember" v-model="rememberMe" />
                        <label class="custom-control-label font-weight-normal text-muted" for="chkRemember">記住帳號</label>
                    </div>
                </div>

                <!-- 登入按鈕 -->
                <button type="submit" class="btn btn-login btn-block btn-lg" :disabled="loading">
                    <span v-if="loading" class="spinner-border spinner-border-sm mr-2" role="status"></span>
                    {{ loading ? '系統驗證中...' : '立即登入' }}
                </button>
            </form>
        </div>

        <div class="login-footer">
            新北市政府環境保護局 版權所有 &copy; 2026<br />
            建議使用 Edge, Chrome 最新版本以獲得最佳體驗
        </div>
    </div>

    <!-- 引用本地 Vue 3 & Axios (徹底避免資安 CSP 外連阻擋) -->
    <script src="Scripts/vue.global.prod.js"></script>
    <script src="Scripts/axios.min.js"></script>
    
    <script>
        const { createApp } = Vue;

        createApp({
            data() {
                return {
                    userId: '',
                    password: '',
                    validateCode: '',
                    rememberMe: false,
                    showPassword: false,
                    loading: false,
                    errorMessage: '',
                    captchaSrc: 'ValidateCode.ashx?t=' + new Date().getTime()
                };
            },
            mounted() {
                // 自動帶入記憶的帳號
                const savedUser = localStorage.getItem('FEC_SAVED_USER');
                if (savedUser) {
                    this.userId = savedUser;
                    this.rememberMe = true;
                }
            },
            methods: {
                refreshCaptcha() {
                    this.captchaSrc = 'ValidateCode.ashx?t=' + new Date().getTime();
                    this.validateCode = '';
                },
                async handleLogin() {
                    this.loading = true;
                    this.errorMessage = '';

                    try {
                        const params = new URLSearchParams();
                        params.append('action', 'login');
                        params.append('userId', this.userId);
                        params.append('password', this.password);
                        params.append('validateCode', this.validateCode);

                        const response = await axios.post('Default.aspx', params);
                        const data = response.data;

                        if (data && data.Success) {
                            if (this.rememberMe) {
                                localStorage.setItem('FEC_SAVED_USER', this.userId);
                            } else {
                                localStorage.removeItem('FEC_SAVED_USER');
                            }
                            window.location.href = data.RedirectUrl || 'MainPage.aspx';
                        } else {
                            this.errorMessage = data ? data.Message : '登入失敗，請確認輸入資訊！';
                            this.refreshCaptcha();
                        }
                    } catch (err) {
                        this.errorMessage = '網路或伺服器通訊異常，請稍後再試！';
                        this.refreshCaptcha();
                    } finally {
                        this.loading = false;
                    }
                }
            }
        }).mount('#loginApp');
    </script>
</body>
</html>
