<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="NTPC_FEC.Default" %>

<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover" />
    <title>新北市固定溢散源管理平台 - 系統登入</title>
    
    <!-- 專屬 Favicon & 手機主畫面圖標 -->
    <link rel="shortcut icon" href="favicon.ico" type="image/x-icon" />
    <link rel="apple-touch-icon" href="apple-touch-icon.png" />
    
    <!-- 引入 Bootstrap 4 本地樣式 (避開機房 CSP 阻擋外部 CDN) -->
    <link rel="stylesheet" href="Content/bootstrap.min.css" />
    <link rel="stylesheet" href="Content/fontawesome/css/all.min.css" />
    
    <style>
        * {
            box-sizing: border-box;
        }
        [v-cloak] {
            display: none !important;
        }

        html, body {
            margin: 0;
            padding: 0;
            min-height: 100vh;
            min-height: 100dvh;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, "微軟正黑體", sans-serif;
            background-color: #cffffe;
        }

        body {
            background-image: url('images/background1.png');
            background-repeat: no-repeat;
            background-position: center bottom;
            background-size: cover;
            background-attachment: fixed;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
        }

        #loginApp {
            min-height: 100vh;
            min-height: 100dvh;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
        }

        .login-wrap {
            flex: 1;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            padding: 20px 15px 25px;
        }

        .title-img-box {
            text-align: center;
            margin-bottom: 22px;
            max-width: 460px;
            width: 88%;
        }

        .title-img-box img {
            width: 100%;
            height: auto;
            filter: drop-shadow(0 4px 10px rgba(0, 0, 0, 0.12));
        }

        /* 融合現代質感的居中登入卡片 */
        .login-card {
            width: 100%;
            max-width: 350px;
            background: rgba(255, 255, 255, 0.96);
            border-radius: 16px;
            box-shadow: 0 16px 36px rgba(0, 0, 0, 0.22), 0 0 0 1px rgba(255, 255, 255, 0.7);
            overflow: hidden;
            backdrop-filter: blur(8px);
            transition: all 0.3s ease;
        }

        .login-card-header {
            background: linear-gradient(135deg, #4b5563 0%, #374151 100%);
            color: #ffffff;
            text-align: center;
            padding: 11px;
            font-size: 1.15rem;
            font-weight: 700;
            letter-spacing: 2px;
        }

        .login-card-body {
            padding: 22px 22px 18px;
        }

        .input-icon-group {
            position: relative;
            margin-bottom: 14px;
        }

        .input-icon-group i.icon-left {
            position: absolute;
            left: 14px;
            top: 50%;
            transform: translateY(-50%);
            color: #9ca3af;
            font-size: 15px;
            z-index: 4;
        }

        .form-control-pill {
            border-radius: 24px;
            border: 1.5px solid #d1d5db;
            padding: 8px 14px 8px 38px;
            font-size: 14px;
            transition: all 0.2s;
            background-color: #ffffff;
            height: 42px;
        }

        .form-control-pill:focus {
            border-color: #2563eb;
            box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.15);
            background-color: #f0f9ff;
        }

        .toggle-pwd {
            position: absolute;
            right: 14px;
            top: 50%;
            transform: translateY(-50%);
            cursor: pointer;
            color: #6b7280;
            font-size: 13px;
            user-select: none;
            z-index: 5;
            line-height: 1;
        }

        .captcha-row {
            display: flex;
            align-items: center;
            margin-bottom: 14px;
        }

        .captcha-img {
            height: 42px;
            width: 125px;
            min-width: 125px;
            border-radius: 8px;
            border: 1.5px solid #d1d5db;
            cursor: pointer;
            margin-left: 8px;
            background-color: #ffffff;
            transition: opacity 0.2s;
        }

        .captcha-img:hover {
            opacity: 0.85;
        }

        /* 經典溫暖橘黃色登入按鈕 */
        .btn-custom-login {
            background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
            border: none;
            color: #ffffff;
            font-size: 15px;
            font-weight: 700;
            border-radius: 24px;
            padding: 9px;
            letter-spacing: 2px;
            box-shadow: 0 4px 12px rgba(217, 119, 6, 0.35);
            transition: all 0.2s;
        }

        .btn-custom-login:hover {
            background: linear-gradient(135deg, #d97706 0%, #b45309 100%);
            color: #ffffff;
            transform: translateY(-1px);
            box-shadow: 0 6px 16px rgba(217, 119, 6, 0.45);
        }

        .alert-custom {
            border-radius: 8px;
            font-size: 13px;
            padding: 8px 12px;
            margin-bottom: 14px;
        }

        /* 底部版權與政策宣導 (大尺寸桌機深底跳亮白高對比；小尺寸淺底跳深海藍) */
        .footer-links {
            text-align: center;
            font-size: 13px;
            padding-bottom: 14px;
            z-index: 10;
        }

        .footer-links-box {
            display: inline-flex;
            align-items: center;
            padding: 4px 16px;
            border-radius: 20px;
            background: rgba(15, 23, 42, 0.38);
            backdrop-filter: blur(4px);
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
            transition: all 0.2s ease;
        }

        .footer-links-box a {
            color: #ffffff;
            font-weight: 600;
            text-decoration: none;
            margin: 0 8px;
            cursor: pointer;
            text-shadow: 0 1px 3px rgba(0, 0, 0, 0.7);
            transition: color 0.2s ease;
        }

        .footer-links-box a:hover {
            color: #fde047; /* 醒目亮黃跳色，呼應登入鈕 */
            text-decoration: underline;
        }

        .footer-links-box .divider {
            color: rgba(255, 255, 255, 0.5);
            user-select: none;
        }

        /* 政策宣告遮罩彈窗樣式 */
        .policy-modal-overlay {
            position: fixed;
            top: 0;
            left: 0;
            width: 100vw;
            height: 100vh;
            background-color: rgba(15, 23, 42, 0.65);
            backdrop-filter: blur(4px);
            z-index: 9999;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
            animation: modalFadeIn 0.2s ease-out;
        }

        .policy-modal-dialog {
            background-color: #ffffff;
            width: 100%;
            max-width: 780px;
            max-height: 85vh;
            border-radius: 14px;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.35);
            display: flex;
            flex-direction: column;
            overflow: hidden;
            animation: modalScaleIn 0.25s cubic-bezier(0.165, 0.84, 0.44, 1);
        }

        .policy-modal-header {
            background: linear-gradient(135deg, #184b72 0%, #1e6091 100%);
            color: #ffffff;
            padding: 16px 22px;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .policy-modal-title {
            margin: 0;
            font-size: 1.15rem;
            font-weight: 700;
            display: flex;
            align-items: center;
            color: #ffffff;
        }

        .policy-modal-header .close-btn {
            background: rgba(255, 255, 255, 0.15);
            border: none;
            color: #ffffff;
            width: 32px;
            height: 32px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            transition: all 0.2s;
            font-size: 14px;
        }

        .policy-modal-header .close-btn:hover {
            background: rgba(255, 255, 255, 0.3);
            transform: scale(1.08);
        }

        .policy-modal-body {
            padding: 24px 26px;
            overflow-y: auto;
            color: #374151;
            font-size: 0.92rem;
            line-height: 1.75;
            text-align: left;
        }

        .policy-modal-body h6 {
            color: #184b72;
            font-weight: 700;
            font-size: 1.05rem;
            margin-top: 18px;
            margin-bottom: 8px;
            padding-bottom: 4px;
            border-bottom: 1px solid #e5e7eb;
        }

        .policy-modal-body h6:first-of-type {
            margin-top: 0;
        }

        .policy-modal-body .sub-text {
            color: #4b5563;
            margin-bottom: 12px;
            padding-left: 12px;
        }

        .policy-modal-body .sub-text p {
            margin-bottom: 6px;
        }

        .policy-modal-body .intro-alert {
            background-color: #f0f7ff;
            border-left: 4px solid #1e6091;
            padding: 12px 14px;
            border-radius: 4px;
            margin-bottom: 16px;
            color: #1e3a5f;
            font-size: 0.92rem;
        }

        .policy-modal-footer {
            padding: 12px 22px;
            border-top: 1px solid #e5e7eb;
            background-color: #f9fafb;
            text-align: right;
        }

        @keyframes modalFadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }

        @keyframes modalScaleIn {
            from { transform: scale(0.95); opacity: 0; }
            to { transform: scale(1); opacity: 1; }
        }

        /* ======================================================== */
        /* 行動載具 & 手機平板 (Mobile & Tablet RWD 完美適配)       */
        /* ======================================================== */
        @media screen and (max-width: 768px) {
            body {
                /* 雙層背景：上層柔和漸層遮罩防止工人人物與標題文字打架，下層保留經典插畫 */
                background-image: 
                    linear-gradient(to bottom, rgba(207, 255, 254, 0.94) 0%, rgba(207, 255, 254, 0.65) 40%, rgba(207, 255, 254, 0.92) 100%),
                    url('images/background1.png');
                background-repeat: no-repeat, no-repeat;
                background-position: center top, center bottom;
                background-size: 100% 100%, cover;
                background-attachment: scroll, scroll;
            }

            .login-wrap {
                padding: 14px 12px 18px;
            }

            /* 標題圖適度縮小，絕不壓在插畫工人臉上，畫面和諧透氣 */
            .title-img-box {
                max-width: 275px;
                width: 80%;
                margin-top: 8px;
                margin-bottom: 15px;
            }

            /* 登入卡片在手機上滿幅適應 (寬度 90% ~ 92%，最大 330px) */
            .login-card {
                max-width: 330px;
                width: 92%;
                border-radius: 14px;
                box-shadow: 0 12px 28px rgba(0, 0, 0, 0.16), 0 0 0 1px rgba(255, 255, 255, 0.8);
            }

            .login-card-header {
                padding: 9px;
                font-size: 1.1rem;
                letter-spacing: 1.5px;
            }

            .login-card-body {
                padding: 18px 18px 14px;
            }

            .input-icon-group {
                margin-bottom: 12px;
            }

            .form-control-pill {
                height: 40px;
                font-size: 14px;
                padding: 6px 14px 6px 36px;
            }

            /* 驗證碼在手機窄螢幕自適應 */
            .captcha-row {
                margin-bottom: 12px;
            }

            .captcha-img {
                height: 40px;
                width: 108px;
                min-width: 108px;
                margin-left: 6px;
            }

            .btn-custom-login {
                padding: 8px;
                font-size: 15px;
            }

            .footer-links {
                font-size: 12px;
                padding-bottom: 10px;
            }

            .footer-links-box {
                background: rgba(255, 255, 255, 0.75);
                backdrop-filter: blur(4px);
                box-shadow: 0 1px 4px rgba(0, 0, 0, 0.08);
            }

            .footer-links-box a {
                color: #0369a1;
                font-weight: 600;
                text-shadow: none;
            }

            .footer-links-box a:hover {
                color: #d97706;
            }

            .footer-links-box .divider {
                color: #94a3b8;
                text-shadow: none;
            }

            /* 手機版彈窗全螢幕優化 */
            .policy-modal-dialog {
                width: 95%;
                max-height: 86vh;
            }

            .policy-modal-body {
                padding: 16px 18px;
                font-size: 0.88rem;
            }
        }

        /* 極小螢幕手機 (如 iPhone SE 或寬度 <= 360px) */
        @media screen and (max-width: 360px) {
            .title-img-box {
                max-width: 240px;
            }
            .login-card {
                width: 96%;
            }
            .login-card-body {
                padding: 14px 12px;
            }
            .captcha-img {
                width: 95px;
                min-width: 95px;
            }
        }

        /* 行動載具橫向模式 (Landscape mode, height <= 580px) */
        @media screen and (max-height: 580px) {
            .login-wrap {
                padding: 8px 10px;
                justify-content: flex-start;
            }
            .title-img-box {
                max-width: 210px;
                margin-top: 4px;
                margin-bottom: 8px;
            }
            .login-card-body {
                padding: 12px 16px;
            }
            .input-icon-group {
                margin-bottom: 8px;
            }
        }
    </style>
</head>
<body>
    <div id="loginApp" v-cloak>
        <div class="login-wrap">
            <!-- 頂部經典大標題圖 (新北環保局 + 固定溢散源管理平台) -->
            <div class="title-img-box">
                <img src="images/First_picture.png" alt="新北市政府環境保護局 固定溢散源管理平台" />
            </div>

            <!-- 中間現代化登入卡片 (完美置中在兩位工人插畫中間) -->
            <div class="login-card">
                <div class="login-card-header">登入</div>
                <div class="login-card-body">
                    <!-- 錯誤提示 -->
                    <div v-if="errorMessage" class="alert alert-danger alert-custom d-flex align-items-center" role="alert">
                        <span class="mr-2">⚠️</span>
                        <div>{{ errorMessage }}</div>
                    </div>

                    <form id="formLogin" v-on:submit.prevent="handleLogin">
                        <!-- 帳號 -->
                        <div class="input-icon-group">
                            <i class="fas fa-user icon-left"></i>
                            <input type="text" id="tbUser" class="form-control form-control-pill" 
                                   placeholder="請輸入使用者名稱" v-model="userId" required autofocus autocomplete="username" />
                        </div>

                        <!-- 密碼 -->
                        <div class="input-icon-group">
                            <i class="fas fa-lock icon-left"></i>
                            <input :type="showPassword ? 'text' : 'password'" id="tbPassword" 
                                   class="form-control form-control-pill pr-5" 
                                   placeholder="請輸入密碼" v-model="password" required autocomplete="current-password" />
                            <span class="toggle-pwd" v-on:click="showPassword = !showPassword">
                                {{ showPassword ? '隱藏' : '顯示' }}
                            </span>
                        </div>

                        <!-- 驗證碼 -->
                        <div class="captcha-row">
                            <div class="input-icon-group mb-0 flex-grow-1">
                                <i class="fas fa-shield-alt icon-left"></i>
                                <input type="text" id="tbChkCode" class="form-control form-control-pill" 
                                       placeholder="輸入驗證碼" v-model="validateCode" maxlength="5" required />
                            </div>
                            <img :src="captchaSrc" alt="驗證碼" class="captcha-img" 
                                 title="看不清楚？點擊換一張" v-on:click="refreshCaptcha" />
                        </div>

                        <!-- 記住帳號 -->
                        <div class="custom-control custom-checkbox mb-3 text-center">
                            <input type="checkbox" class="custom-control-input" id="chkRemember" v-model="rememberMe" />
                            <label class="custom-control-label text-muted small" for="chkRemember">自動登入 (記住帳號)</label>
                        </div>

                        <!-- 登入按鈕 -->
                        <button type="submit" class="btn btn-custom-login btn-block" :disabled="loading">
                            <span v-if="loading" class="spinner-border spinner-border-sm mr-2" role="status"></span>
                            {{ loading ? '系統驗證中...' : '登 入' }}
                        </button>
                    </form>
                </div>
            </div>
        </div>

        <!-- 底部版權與政策宣導 (跳色自適應) -->
        <div class="footer-links">
            <div class="footer-links-box">
                <a href="javascript:void(0)" v-on:click="openModal('site')">網站政策及宣告</a>
                <span class="divider">|</span>
                <a href="javascript:void(0)" v-on:click="openModal('privacy')">隱私權保護政策</a>
            </div>
        </div>

        <!-- 政策宣告遮罩彈窗 (Modal Overlay) -->
        <div v-if="activeModal" class="policy-modal-overlay" v-on:click.self="closeModal">
            <div class="policy-modal-dialog">
                <div class="policy-modal-header">
                    <h5 class="policy-modal-title">
                        <i :class="activeModal === 'site' ? 'fas fa-file-contract mr-2' : 'fas fa-user-shield mr-2'"></i>
                        {{ activeModal === 'site' ? '網站政策及宣告' : '隱私權保護政策' }}
                    </h5>
                    <button type="button" class="close-btn" v-on:click="closeModal" aria-label="關閉">
                        <i class="fas fa-times"></i>
                    </button>
                </div>
                <div class="policy-modal-body">
                    <!-- 網站政策及宣告內容 -->
                    <div v-if="activeModal === 'site'">
                        <h6>一、授權方式及範圍</h6>
                        <div class="sub-text">
                            為利各界廣為利用網站資料，新北市政府環境保護局網站上刊載之所有資料與素材，其得受著作權保護之範圍，以無償、非專屬，得再授權之方式提供公眾使用，使用者得不限時間及地域，重製、改作、編輯、公開傳輸或為其他方式之利用，開發各種產品或服務（簡稱加值衍生物），此一授權行為不會嗣後撤回，使用者亦無須取得本機關之書面或其他方式授權；然使用時，應註明出處。
                        </div>

                        <h6>二、除外事項說明</h6>
                        <div class="sub-text">
                            <p>(一) 本授權範圍僅及於著作權保護之範圍，不及於其他智慧財產權利，包括但不限於專利、商標、及機關標誌之提供。</p>
                            <p>(二) 當事人自行公開或依法令公開之個人資料是否得被蒐集、處理，及利用，使用者須自行依照個人資料保護法之相關規定，規劃並執行法律要求之相應措施。</p>
                            <p>(三) 部分的影音、圖像、樂譜、專人專案撰文，因機關網站依約僅具公開發表之地位，故經機關特別聲明須經同意方可使用的素材，不在本授權範圍之內。</p>
                            <p>(四) 使用本授權提供之資料與素材，不得惡意變更其相關資訊，若編輯、改作後所展示之資訊與原不符，使用者須自負民事、刑事上之法律責任。</p>
                        </div>

                        <h6>三、著作人格權保障</h6>
                        <div class="sub-text">
                            應注意不得侵害第三人之著作人格權（包括姓名表示權及禁止不當變更權）。
                        </div>

                        <h6>四、資訊真實性要求</h6>
                        <div class="sub-text">
                            使用本授權提供之資料與素材，不得惡意變更其相關資訊，若利用後所展示之資訊與原資料素材不符，使用者須自負民事、刑事上之法律責任。
                        </div>

                        <h6>五、機關代表性說明</h6>
                        <div class="sub-text">
                            本網站之授權，並不授予使用者代表本機關建議、認可或贊同其加值衍生物之地位。
                        </div>

                        <h6>六、免責聲明</h6>
                        <div class="sub-text">
                            本網站所提供相關連結網站之網頁或資料，均為被連結網站所提供，相關權利為該等網站或合法權利人所有，不擔保其正確性、即時性或完整性。
                        </div>
                    </div>

                    <!-- 隱私權保護政策內容 -->
                    <div v-if="activeModal === 'privacy'">
                        <div class="intro-alert">
                            非常歡迎您光臨「新北市固定溢散源管理平台」（以下簡稱本網站），為了讓您能夠安心的使用本網站的各項服務與資訊，特此向您說明本網站的隱私權保護政策，以保障您的權益，請您詳閱下列內容：
                        </div>

                        <h6>一、隱私權保護政策的適用範圍</h6>
                        <div class="sub-text">
                            隱私權保護政策內容，包括本網站如何處理在您使用網站服務時收集到的個人識別資料。隱私權保護政策不適用於本網站以外的相關連結網站，亦不適用於非本網站所委託或參與管理的人員。
                        </div>

                        <h6>二、個人資料的蒐集、處理及利用方式</h6>
                        <div class="sub-text">
                            <p>• 當您造訪本網站或使用本網站所提供之功能服務時，我們將視該服務功能性質，請您提供必要的個人資料，並在該特定目的範圍內處理及利用您的個人資料；非經您書面同意，本網站不會將個人資料用於其他用途。</p>
                            <p>• 本網站在您使用服務信箱、問卷調查等互動性功能時，會保留您所提供的姓名、電子郵件地址、聯絡方式及使用時間等。</p>
                            <p>• 於一般瀏覽時，伺服器會自行記錄相關行徑，包括您使用連線設備的 IP 位址、使用時間、使用的瀏覽器、瀏覽及點選資料記錄等，做為我們增進網站服務的參考依據，此記錄為內部應用，決不對外公佈。</p>
                            <p>• 為提供精確的服務，我們會將收集的問卷調查內容進行統計與分析，分析結果之統計數據或說明文字呈現，除供內部研究外，我們會視需要公佈統計數據及說明文字，但不涉及特定個人之資料。</p>
                        </div>

                        <h6>三、資料之保護</h6>
                        <div class="sub-text">
                            <p>• 本網站主機均設有防火牆、防毒系統等相關的各項資訊安全設備及必要的安全防護措施，加以保護網站及您的個人資料採用嚴格的保護措施，只由經過授權的人員才能接觸您的個人資料，相關處理人員皆簽有保密合約，如有違反保密義務者，將會受到相關的法律處分。</p>
                            <p>• 如因業務需要有必要委託其他單位提供服務時，本網站亦會嚴格要求其遵守保密義務，並且採取必要檢查程序以確定其將確實遵守。</p>
                        </div>

                        <h6>四、網站對外的相關連結</h6>
                        <div class="sub-text">
                            本網站的網頁提供其他網站的網路連結，您也可經由本網站所提供的連結，點選進入其他網站。但該連結網站不適用本網站的隱私權保護政策，您必須參考該連結網站中的隱私權保護政策。
                        </div>

                        <h6>五、與第三人共用個人資料之政策</h6>
                        <div class="sub-text">
                            本網站絕不會提供、交換、出租或出售任何您的個人資料給其他個人、團體、私人企業或公務機關，但有法律依據或合約義務者，不在此限。
                        </div>

                        <h6>六、Cookie 之使用</h6>
                        <div class="sub-text">
                            為了提供您最佳的服務，本網站會在您的電腦中放置並取用我們的 Cookie，若您不願接受 Cookie 的寫入，您可在您使用的瀏覽器功能項中設定隱私權等級為高，即可拒絕 Cookie 的寫入，但可能會導致網站某些功能無法正常執行。
                        </div>

                        <h6>七、隱私權保護政策之修正</h6>
                        <div class="sub-text">
                            本網站隱私權保護政策將因應需求隨時進行修正，修正後的條款將刊登於網站上。
                        </div>
                    </div>
                </div>
                <div class="policy-modal-footer">
                    <button type="button" class="btn btn-secondary btn-sm px-4" v-on:click="closeModal">關閉視窗</button>
                </div>
            </div>
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
                    captchaSrc: 'ValidateCode.ashx?t=' + new Date().getTime(),
                    activeModal: null // 'site' | 'privacy' | null
                };
            },
            mounted() {
                const savedUser = localStorage.getItem('FEC_SAVED_USER');
                if (savedUser) {
                    this.userId = savedUser;
                    this.rememberMe = true;
                }
                // ESC 鍵關閉彈窗
                window.addEventListener('keydown', (e) => {
                    if (e.key === 'Escape' && this.activeModal) {
                        this.closeModal();
                    }
                });
            },
            methods: {
                openModal(type) {
                    this.activeModal = type;
                    document.body.style.overflow = 'hidden';
                },
                closeModal() {
                    this.activeModal = null;
                    document.body.style.overflow = '';
                },
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
