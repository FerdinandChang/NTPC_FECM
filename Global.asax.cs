using System;
using System.IO;
using System.Text;
using System.Web;
using NTPC_FEC.Services;

namespace NTPC_FEC
{
    public class Global : HttpApplication
    {
        protected void Application_Start(object sender, EventArgs e)
        {
            try
            {
                AuthService.EnsurePasswordColumnCapacity();
            }
            catch
            {
            }
        }

        protected void Application_Error(object sender, EventArgs e)
        {
            Exception ex = Server.GetLastError();
            if (ex is HttpUnhandledException && ex.InnerException != null)
            {
                ex = ex.InnerException;
            }

            if (ex is System.Threading.ThreadAbortException)
            {
                return;
            }

            HttpException httpEx = ex as HttpException;
            if (httpEx != null && httpEx.GetHttpCode() == 404)
            {
                return;
            }

            try
            {
                LogErrorToFile(ex);
            }
            catch
            {
            }

            HttpContext context = HttpContext.Current;
            if (context != null)
            {
                HttpRequest request = context.Request;
                bool isAjax = !string.IsNullOrEmpty(request["action"]) ||
                              string.Equals(request.Headers["X-Requested-With"], "XMLHttpRequest", StringComparison.OrdinalIgnoreCase);

                if (isAjax)
                {
                    Server.ClearError();
                    HttpResponse response = context.Response;
                    response.Clear();
                    response.StatusCode = 500;
                    response.ContentType = "application/json; charset=utf-8";
                    response.Write("{\"success\":false,\"message\":\"系統發生未預期錯誤，已記錄至伺服器日誌。\"}");
                    context.ApplicationInstance.CompleteRequest();
                }
            }
        }

        private void LogErrorToFile(Exception ex)
        {
            string appData = HttpContext.Current != null && HttpContext.Current.Server != null
                ? HttpContext.Current.Server.MapPath("~/App_Data/Logs")
                : Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "App_Data", "Logs");

            if (!Directory.Exists(appData))
            {
                Directory.CreateDirectory(appData);
            }

            string logFile = Path.Combine(appData, "Error_" + DateTime.Now.ToString("yyyyMMdd") + ".log");
            StringBuilder sb = new StringBuilder();
            sb.AppendLine("================================================================================");
            sb.AppendFormat("時間：{0:yyyy-MM-dd HH:mm:ss}\r\n", DateTime.Now);

            if (HttpContext.Current != null && HttpContext.Current.Request != null)
            {
                HttpRequest req = HttpContext.Current.Request;
                string user = HttpContext.Current.Session != null && HttpContext.Current.Session["LoginUser"] != null
                    ? HttpContext.Current.Session["LoginUser"].ToString()
                    : "匿名/未登入";

                sb.AppendFormat("使用者：{0}\r\n", user);
                sb.AppendFormat("來源 IP：{0}\r\n", req.UserHostAddress);
                sb.AppendFormat("HTTP 方法：{0}\r\n", req.HttpMethod);
                sb.AppendFormat("請求網址：{0}\r\n", req.RawUrl);
            }

            if (ex != null)
            {
                sb.AppendFormat("例外類型：{0}\r\n", ex.GetType().FullName);
                sb.AppendFormat("錯誤訊息：{0}\r\n", ex.Message);
                sb.AppendLine("堆疊追蹤 (Stack Trace)：");
                sb.AppendLine(ex.StackTrace);
            }

            sb.AppendLine();

            File.AppendAllText(logFile, sb.ToString(), Encoding.UTF8);
        }
    }
}
