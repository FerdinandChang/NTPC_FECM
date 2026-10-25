using System;
using System.IO;
using System.Text;
using System.Web;

namespace NTPC_FEC.Security
{
    /// <summary>
    /// 系統特權管理與重要操作稽核日誌 (Audit Trail)
    /// 相容 C# 5.0 規範
    /// </summary>
    public static class AuditLogger
    {
        private static readonly object AuditLock = new object();

        /// <summary>
        /// 記錄特權管理操作 (如：帳號開通/停用、權限變更、重設臨時密碼等)
        /// </summary>
        public static void Log(string actionType, string targetUser, string details)
        {
            try
            {
                HttpContext ctx = HttpContext.Current;
                string operatorUser = "SYSTEM";
                string clientIp = "N/A";

                if (ctx != null)
                {
                    if (ctx.Session != null && ctx.Session["LoginUser"] != null)
                    {
                        operatorUser = ctx.Session["LoginUser"].ToString();
                    }
                    if (ctx.Request != null)
                    {
                        clientIp = ctx.Request.UserHostAddress ?? "N/A";
                    }
                }

                string baseDir = AppDomain.CurrentDomain.BaseDirectory;
                string logDir = Path.Combine(baseDir, "App_Data", "Logs");
                if (!Directory.Exists(logDir))
                {
                    Directory.CreateDirectory(logDir);
                }

                string logPath = Path.Combine(logDir, string.Format("audit_{0:yyyyMM}.log", DateTime.Today));
                string timeStr = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");

                StringBuilder sb = new StringBuilder();
                sb.Append(string.Format("[{0}] [OP:{1}] [IP:{2}] [ACTION:{3}] [TARGET:{4}] {5}\r\n",
                    timeStr, operatorUser, clientIp, actionType, targetUser ?? "N/A", details ?? ""));

                lock (AuditLock)
                {
                    File.AppendAllText(logPath, sb.ToString(), Encoding.UTF8);
                }
            }
            catch
            {
                // 稽核寫入異常不阻斷業務流程
            }
        }
    }
}
