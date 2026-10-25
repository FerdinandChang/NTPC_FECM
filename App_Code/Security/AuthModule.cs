using System;
using System.Web;
using NTPC_FEC.Models;
using NTPC_FEC.Services;

namespace NTPC_FEC.Security
{
    public class AuthModule : IHttpModule
    {
        private static readonly object LogLock = new object();

        public void Init(HttpApplication context)
        {
            if (context != null)
            {
                context.PostAcquireRequestState += OnPostAcquireRequestState;
                context.PreSendRequestHeaders += OnPreSendRequestHeaders;
                context.Error += OnApplicationError;
            }
        }

        private void OnPreSendRequestHeaders(object sender, EventArgs e)
        {
            HttpApplication app = sender as HttpApplication;
            if (app == null) return;
            HttpContext context = app.Context;
            if (context == null || context.Response == null) return;

            try
            {
                // 動態注入安全標頭 (若尚未存在才加入，杜絕 IIS 500.19 衝突)
                var headers = context.Response.Headers;
                if (headers != null)
                {
                    if (string.IsNullOrEmpty(headers["X-Frame-Options"]))
                    {
                        headers["X-Frame-Options"] = "SAMEORIGIN";
                    }
                    if (string.IsNullOrEmpty(headers["X-Content-Type-Options"]))
                    {
                        headers["X-Content-Type-Options"] = "nosniff";
                    }
                    if (string.IsNullOrEmpty(headers["X-XSS-Protection"]))
                    {
                        headers["X-XSS-Protection"] = "1; mode=block";
                    }
                    if (string.IsNullOrEmpty(headers["Referrer-Policy"]))
                    {
                        headers["Referrer-Policy"] = "strict-origin-when-cross-origin";
                    }
                }
            }
            catch
            {
            }
        }

        private void OnApplicationError(object sender, EventArgs e)
        {
            HttpApplication app = sender as HttpApplication;
            if (app == null) return;
            HttpContext context = app.Context;
            if (context == null) return;

            Exception ex = context.Server.GetLastError();
            if (ex == null) return;

            if (ex is HttpUnhandledException && ex.InnerException != null)
            {
                ex = ex.InnerException;
            }

            if (ex is System.Threading.ThreadAbortException)
            {
                return;
            }

            try
            {
                string traceId = Guid.NewGuid().ToString("N").Substring(0, 8).ToUpper();
                string logDir = context.Server.MapPath("~/App_Data/Logs");
                if (!System.IO.Directory.Exists(logDir))
                {
                    System.IO.Directory.CreateDirectory(logDir);
                }

                string logFile = System.IO.Path.Combine(logDir, string.Format("error_{0:yyyyMMdd}.log", DateTime.Today));
                string url = (context.Request != null && context.Request.Url != null) ? context.Request.Url.ToString() : "N/A";
                string user = (context.Session != null && context.Session["LoginUser"] != null) ? context.Session["LoginUser"].ToString() : "Anonymous";
                string ip = (context.Request != null) ? context.Request.UserHostAddress : "N/A";

                System.Text.StringBuilder sb = new System.Text.StringBuilder();
                sb.AppendLine("--------------------------------------------------------------------------------");
                sb.AppendLine(string.Format("[{0:yyyy-MM-dd HH:mm:ss}] [TraceId: {1}] [User: {2}] [IP: {3}]", DateTime.Now, traceId, user, ip));
                sb.AppendLine(string.Format("URL: {0}", url));
                sb.AppendLine(string.Format("Exception: {0}: {1}", ex.GetType().FullName, ex.Message));
                sb.AppendLine(string.Format("StackTrace:\r\n{0}", ex.StackTrace));
                if (ex.InnerException != null)
                {
                    sb.AppendLine(string.Format("InnerException: {0}: {1}", ex.InnerException.GetType().FullName, ex.InnerException.Message));
                    sb.AppendLine(string.Format("InnerStackTrace:\r\n{0}", ex.InnerException.StackTrace));
                }

                lock (LogLock)
                {
                    System.IO.File.AppendAllText(logFile, sb.ToString(), System.Text.Encoding.UTF8);
                }

                context.Items["CurrentErrorTraceId"] = traceId;
            }
            catch
            {
            }
        }

        private void OnPostAcquireRequestState(object sender, EventArgs e)
        {
            HttpApplication app = sender as HttpApplication;
            if (app == null) return;

            HttpContext context = app.Context;
            if (context == null || context.Request == null) return;

            string filePath = context.Request.AppRelativeCurrentExecutionFilePath;
            if (string.IsNullOrEmpty(filePath)) return;

            // 僅對 .aspx 頁面進行權限控管與登入攔截
            if (!filePath.EndsWith(".aspx", StringComparison.OrdinalIgnoreCase))
            {
                return;
            }

            // 白名單公開頁面：無需登入即可存取
            string normPath = filePath.Replace("\\", "/").Trim();
            if (normPath.StartsWith("~/"))
            {
                normPath = normPath.Substring(2);
            }
            normPath = normPath.TrimStart('/');

            if (normPath.Equals("Default.aspx", StringComparison.OrdinalIgnoreCase) ||
                normPath.Equals("ClientLogin.aspx", StringComparison.OrdinalIgnoreCase) ||
                normPath.Equals("Logout.aspx", StringComparison.OrdinalIgnoreCase) ||
                normPath.Equals("ForgotPwd.aspx", StringComparison.OrdinalIgnoreCase) ||
                normPath.Equals("Error.aspx", StringComparison.OrdinalIgnoreCase))
            {
                return;
            }

            // 1. 檢核登入狀態
            if (context.Session == null || context.Session["LoginUser"] == null || string.IsNullOrEmpty(context.Session["LoginUser"].ToString()))
            {
                DenyUnauthenticated(context);
                return;
            }

            // 1.1 檢核 Session 防劫持特徵指紋 (Session Hijacking Defense)
            string savedFingerprint = context.Session["AuthFingerprint"] as string;
            if (!string.IsNullOrEmpty(savedFingerprint))
            {
                string currentFingerprint = AuthService.GenerateSessionFingerprint(context);
                if (!string.Equals(savedFingerprint, currentFingerprint, StringComparison.OrdinalIgnoreCase))
                {
                    AuditLogger.Log(
                        "SYSTEM",
                        "SESSION_HIJACK_BLOCKED",
                        context.Session["LoginUser"] != null ? context.Session["LoginUser"].ToString() : "Unknown",
                        context.Request != null ? context.Request.UserHostAddress : "127.0.0.1",
                        "偵測到不同來源載具或 IP 網段試圖盜用登入作業階段！系統已強制註銷連線。",
                        null,
                        null
                    );
                    context.Session.Clear();
                    context.Session.Abandon();
                    DenyUnauthenticated(context);
                    return;
                }
            }

            // 2. 取得當前使用者實體
            UserAccount currentUser = context.Session["UserAccount"] as UserAccount;
            if (currentUser == null)
            {
                currentUser = AuthService.GetCurrentUser(context);
                if (currentUser != null && context.Session != null)
                {
                    context.Session["UserAccount"] = currentUser;
                }
            }

            if (currentUser == null)
            {
                DenyUnauthenticated(context);
                return;
            }

            // 3. 確保核發 Anti-CSRF Cookie (供 Axios 與前端表單讀取)
            EnsureXsrfCookie(context);

            // 4. 對具備狀態變更意圖之 POST AJAX action 執行 CSRF 雙重防禦檢核
            if (string.Equals(context.Request.HttpMethod, "POST", StringComparison.OrdinalIgnoreCase) &&
                !string.IsNullOrEmpty(context.Request["action"]))
            {
                if (!ValidateXsrfToken(context))
                {
                    DenyCsrf(context);
                    return;
                }
            }

            // 5. 檢核模組功能權限 (RBAC)
            string denyReason = "";
            bool allowed = AuthRuleService.CheckUrlAccess(filePath, context.Request, currentUser, out denyReason);
            if (!allowed)
            {
                DenyUnauthorized(context, denyReason);
                return;
            }
        }

        #region Anti-CSRF Token 輔助函式
        private static void EnsureXsrfCookie(HttpContext context)
        {
            if (context == null || context.Response == null || context.Request == null) return;
            HttpCookie existing = context.Request.Cookies["XSRF-TOKEN"];
            if (existing == null || string.IsNullOrEmpty(existing.Value))
            {
                string token = Guid.NewGuid().ToString("N");
                HttpCookie cookie = new HttpCookie("XSRF-TOKEN", token);
                cookie.Path = "/";
                cookie.HttpOnly = false; // 允許 Axios 自動讀取並附加至 X-XSRF-TOKEN Header
                context.Response.Cookies.Add(cookie);
            }
        }

        private static bool ValidateXsrfToken(HttpContext context)
        {
            if (context == null || context.Request == null) return false;

            HttpCookie cookie = context.Request.Cookies["XSRF-TOKEN"];
            string headerToken = context.Request.Headers["X-XSRF-TOKEN"];

            // 1. 優先比對 Axios 預設自動附加之 X-XSRF-TOKEN 標頭
            if (cookie != null && !string.IsNullOrEmpty(cookie.Value) &&
                !string.IsNullOrEmpty(headerToken) &&
                string.Equals(cookie.Value, headerToken, StringComparison.Ordinal))
            {
                return true;
            }

            // 2. 次要比對 Form 欄位傳遞之防偽 Token (__RequestVerificationToken)
            string formToken = context.Request.Form["__RequestVerificationToken"];
            if (cookie != null && !string.IsNullOrEmpty(cookie.Value) &&
                !string.IsNullOrEmpty(formToken) &&
                string.Equals(cookie.Value, formToken, StringComparison.Ordinal))
            {
                return true;
            }

            // 3. 若 Cookie 尚未核發 (例如自舊工作階段剛升級之請求)，給予寬限並於當次補簽發
            if (cookie == null || string.IsNullOrEmpty(cookie.Value))
            {
                EnsureXsrfCookie(context);
                return true;
            }

            return false;
        }

        private void DenyCsrf(HttpContext context)
        {
            context.Response.Clear();
            context.Response.StatusCode = 403;
            context.Response.ContentType = "application/json; charset=utf-8";
            context.Response.Write("{\"Success\":false,\"Message\":\"跨站安全標記 (CSRF Token) 驗證失敗或請求無效，請重新整理頁面後再試！\",\"CsrfError\":true}");
            context.ApplicationInstance.CompleteRequest();
        }
        #endregion

        #region 未授權與未登入阻斷處理
        private void DenyUnauthenticated(HttpContext context)
        {
            bool isAjax = !string.IsNullOrEmpty(context.Request["action"]) ||
                          string.Equals(context.Request.Headers["X-Requested-With"], "XMLHttpRequest", StringComparison.OrdinalIgnoreCase);

            if (isAjax)
            {
                context.Response.Clear();
                context.Response.StatusCode = 401;
                context.Response.ContentType = "application/json; charset=utf-8";
                context.Response.Write("{\"Success\":false,\"Message\":\"登入已逾時或尚未登入，請重新登入！\",\"NeedLogin\":true}");
                context.ApplicationInstance.CompleteRequest();
            }
            else
            {
                string targetUrl = context.Response.ApplyAppPathModifier("~/Default.aspx");
                context.Response.Redirect(targetUrl, false);
                context.ApplicationInstance.CompleteRequest();
            }
        }

        private void DenyUnauthorized(HttpContext context, string denyReason)
        {
            if (string.IsNullOrEmpty(denyReason))
            {
                denyReason = "您無權限存取此功能，請洽系統管理員開通權限！";
            }

            bool isAjax = !string.IsNullOrEmpty(context.Request["action"]) ||
                          string.Equals(context.Request.Headers["X-Requested-With"], "XMLHttpRequest", StringComparison.OrdinalIgnoreCase);

            if (isAjax)
            {
                context.Response.Clear();
                context.Response.StatusCode = 403;
                context.Response.ContentType = "application/json; charset=utf-8";
                string jsonMsg = string.Format("{{\"Success\":false,\"Message\":\"{0}\",\"Unauthorized\":true}}", HttpUtility.JavaScriptStringEncode(denyReason));
                context.Response.Write(jsonMsg);
                context.ApplicationInstance.CompleteRequest();
            }
            else
            {
                context.Response.Clear();
                context.Response.ContentType = "text/html; charset=utf-8";
                string redirectUrl = context.Response.ApplyAppPathModifier("~/MainPage.aspx");
                string html = string.Format("<script>alert('{0}'); window.location.href='{1}';</script>",
                    HttpUtility.JavaScriptStringEncode(denyReason),
                    redirectUrl);
                context.Response.Write(html);
                context.ApplicationInstance.CompleteRequest();
            }
        }
        #endregion

        public void Dispose()
        {
        }
    }
}
