using System;
using System.IO;
using System.Web;

namespace NTPC_FEC.Security
{
    /// <summary>
    /// 全域身分驗證與資安過濾模組 (防範未授權存取與 AJAX API 繞過)
    /// </summary>
    public class AuthFilterModule : IHttpModule
    {
        public void Init(HttpApplication context)
        {
            context.PostAcquireRequestState += OnPostAcquireRequestState;
        }

        private void OnPostAcquireRequestState(object sender, EventArgs e)
        {
            HttpContext context = HttpContext.Current;
            if (context == null || context.Session == null)
            {
                return;
            }

            HttpRequest request = context.Request;
            HttpResponse response = context.Response;

            string appRelativePath = request.AppRelativeCurrentExecutionFilePath;
            if (string.IsNullOrEmpty(appRelativePath))
            {
                return;
            }

            string lowerPath = appRelativePath.ToLower();

            // 1. 靜態資源白名單 (不需驗證身分)
            string ext = Path.GetExtension(lowerPath);
            if (ext == ".css" || ext == ".js" || ext == ".png" || ext == ".jpg" || ext == ".jpeg" ||
                ext == ".gif" || ext == ".ico" || ext == ".svg" || ext == ".woff" || ext == ".woff2" ||
                ext == ".ttf" || ext == ".otf" || ext == ".eot" || ext == ".map" || ext == ".pdf")
            {
                return;
            }

            // 2. 公開頁面白名單 (登入、登出、驗證碼、心跳等)
            if (lowerPath.EndsWith("/default.aspx") ||
                lowerPath.EndsWith("/clientlogin.aspx") ||
                lowerPath.EndsWith("/logout.aspx") ||
                lowerPath.EndsWith("/validatecode.ashx") ||
                lowerPath.EndsWith("/keepalive.ashx"))
            {
                return;
            }

            // 3. 檢查登入 Session
            if (context.Session["LoginUser"] == null)
            {
                // 判斷是否為 AJAX 請求或 API 呼叫
                bool isAjax = false;

                if (!string.IsNullOrEmpty(request["action"]))
                {
                    isAjax = true;
                }
                else if (string.Equals(request.Headers["X-Requested-With"], "XMLHttpRequest", StringComparison.OrdinalIgnoreCase))
                {
                    isAjax = true;
                }
                else if (request.AcceptTypes != null)
                {
                    for (int i = 0; i < request.AcceptTypes.Length; i++)
                    {
                        if (request.AcceptTypes[i].IndexOf("application/json", StringComparison.OrdinalIgnoreCase) >= 0)
                        {
                            isAjax = true;
                            break;
                        }
                    }
                }

                if (isAjax)
                {
                    response.Clear();
                    response.StatusCode = 401;
                    response.ContentType = "application/json; charset=utf-8";
                    response.Cache.SetCacheability(HttpCacheability.NoCache);
                    response.Cache.SetNoStore();
                    response.Write("{\"success\":false,\"authenticated\":false,\"message\":\"連線逾時或尚未登入，請重新登入！\"}");
                    context.ApplicationInstance.CompleteRequest();
                    return;
                }
                else
                {
                    // 一般頁面請求強制導向回登入頁，並附帶 timeout 參數
                    string targetUrl = VirtualPathUtility.ToAbsolute("~/Default.aspx?reason=timeout");
                    response.Redirect(targetUrl, false);
                    context.ApplicationInstance.CompleteRequest();
                    return;
                }
            }
        }

        public void Dispose()
        {
        }
    }
}
