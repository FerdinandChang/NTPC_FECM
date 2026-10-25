using System;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Text;
using System.Web;
using NTPC_FEC.Helpers;

namespace NTPC_FEC.Security
{
    /// <summary>
    /// 蝟餌絞?寞???閬?雿里?豢隤?? (Sys_AuditLog & File Audit Trail)
    /// 閬?嚗絞銝閮? Operator?ction?arget?P?????詨??批捆 (OldValue)???詨??批捆 (NewValue)??閮?    /// ?寞改?
    /// 1. ???脣?嚗??神??SQL Server (Sys_AuditLog) ?璈?獢?(App_Data/Logs/audit_*.log)
    /// 2. ?芸?撱箄” (Auto DDL)嚗?甈∪?怨?炎?乩蒂撱箇? Sys_AuditLog 鞈?銵刻? 4 蝯??蝝Ｗ?
    /// 3. ??摰寥 (Fail-Safe)嚗隤神?亦?遙雿??澈??IO 靘????敹?蝯?銝剜璆剖?銝餅?蝔?    /// 4. ?湔蝚血? C# 5.0 閬? (?∪?銝脫??潦 Null 璇辣??摮?
    /// 5. ?瑕? 90 憭拇隤???雁霅?    /// </summary>
    public static class AuditLogger
    {
        private static readonly object FileAuditLock = new object();
        private static readonly object InitTableLock = new object();
        private static bool s_isTableInitialized = false;
        private static DateTime s_lastCleanDate = DateTime.MinValue;

        #region 1. 撣貊閮??寞? (Log Overloads)

        /// <summary>
        /// 閮??桃??? (?芸????嗅?????
        /// </summary>
        public static void Log(string actionType, string targetUser, string details)
        {
            Log(actionType, targetUser, details, null, null);
        }

        /// <summary>
        /// 閮?霈?? (????敺摰?
        /// </summary>
        public static void Log(string actionType, string targetUser, string details, string oldValue, string newValue)
        {
            string operatorUser = ResolveCurrentOperator();
            string clientIp = ResolveClientIp();

            Log(operatorUser, actionType, targetUser, clientIp, details, oldValue, newValue);
        }

        /// <summary>
        /// 摰閮??? (?舀?????? IP嚗????畾?憓矽??
        /// </summary>
        public static void Log(string operatorUser, string actionType, string targetUser, string clientIp, string details, string oldValue, string newValue)
        {
            string op = string.IsNullOrEmpty(operatorUser) ? "SYSTEM" : operatorUser.Trim();
            string act = string.IsNullOrEmpty(actionType) ? "UNKNOWN" : actionType.Trim();
            string target = string.IsNullOrEmpty(targetUser) ? null : targetUser.Trim();
            string ip = string.IsNullOrEmpty(clientIp) ? "127.0.0.1" : clientIp.Trim();

            // 1. 撖怠 SQL 鞈?摨?(Sys_AuditLog)
            WriteToSql(op, act, target, ip, details, oldValue, newValue);

            // 2. ??撖怠?砍?亥? (App_Data/Logs/audit_*.log)
            WriteToFile(op, act, target, ip, details, oldValue, newValue);
        }

        #endregion

        #region 2. SQL 撖怠??遣銵?(Auto DDL)

        /// <summary>
        /// 蝣箔? Sys_AuditLog 鞈?銵刻?蝝Ｗ?摮
        /// </summary>
        private static void EnsureTableExists()
        {
            if (s_isTableInitialized) return;

            lock (InitTableLock)
            {
                if (s_isTableInitialized) return;

                try
                {
                    string sqlCheckAndCreate = @"
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Sys_AuditLog')
BEGIN
    CREATE TABLE [dbo].[Sys_AuditLog] (
        [LogId] BIGINT IDENTITY(1,1) NOT NULL,
        [Operator] NVARCHAR(50) NOT NULL,
        [Action] NVARCHAR(50) NOT NULL,
        [Target] NVARCHAR(100) NULL,
        [IP] VARCHAR(50) NULL,
        [LogTime] DATETIME NOT NULL CONSTRAINT [DF_Sys_AuditLog_LogTime] DEFAULT (GETDATE()),
        [OldValue] NVARCHAR(MAX) NULL,
        [NewValue] NVARCHAR(MAX) NULL,
        [Details] NVARCHAR(MAX) NULL,
        CONSTRAINT [PK_Sys_AuditLog] PRIMARY KEY CLUSTERED ([LogId] ASC)
    );

    CREATE NONCLUSTERED INDEX [IX_Sys_AuditLog_LogTime] ON [dbo].[Sys_AuditLog] ([LogTime] DESC);
    CREATE NONCLUSTERED INDEX [IX_Sys_AuditLog_Operator] ON [dbo].[Sys_AuditLog] ([Operator] ASC, [LogTime] DESC);
    CREATE NONCLUSTERED INDEX [IX_Sys_AuditLog_Action] ON [dbo].[Sys_AuditLog] ([Action] ASC, [LogTime] DESC);
    CREATE NONCLUSTERED INDEX [IX_Sys_AuditLog_Target] ON [dbo].[Sys_AuditLog] ([Target] ASC, [LogTime] DESC);
END
ELSE
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Sys_AuditLog') AND name = 'OldValue')
    BEGIN
        ALTER TABLE [dbo].[Sys_AuditLog] ADD [OldValue] NVARCHAR(MAX) NULL;
    END

    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Sys_AuditLog') AND name = 'NewValue')
    BEGIN
        ALTER TABLE [dbo].[Sys_AuditLog] ADD [NewValue] NVARCHAR(MAX) NULL;
    END

    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Sys_AuditLog') AND name = 'Details')
    BEGIN
        ALTER TABLE [dbo].[Sys_AuditLog] ADD [Details] NVARCHAR(MAX) NULL;
    END
END";
                    DbHelper.ExecuteNonQuery(sqlCheckAndCreate);
                    s_isTableInitialized = true;
                }
                catch
                {
                    // ?亦甈⊿???啣虜嚗?閮剖? flag嚗?甈∪?怠?岫
                }
            }
        }

        /// <summary>
        /// ??神??SQL Server Sys_AuditLog
        /// </summary>
        private static void WriteToSql(string operatorUser, string actionType, string targetUser, string clientIp, string details, string oldValue, string newValue)
        {
            try
            {
                EnsureTableExists();

                string sqlInsert = @"
INSERT INTO [dbo].[Sys_AuditLog] 
    ([Operator], [Action], [Target], [IP], [LogTime], [OldValue], [NewValue], [Details])
VALUES 
    (@Operator, @Action, @Target, @IP, GETDATE(), @OldValue, @NewValue, @Details)";

                SqlParameter[] parameters = new SqlParameter[]
                {
                    new SqlParameter("@Operator", SqlDbType.NVarChar, 50) { Value = (object)operatorUser ?? DBNull.Value },
                    new SqlParameter("@Action", SqlDbType.NVarChar, 50) { Value = (object)actionType ?? DBNull.Value },
                    new SqlParameter("@Target", SqlDbType.NVarChar, 100) { Value = (object)targetUser ?? DBNull.Value },
                    new SqlParameter("@IP", SqlDbType.VarChar, 50) { Value = (object)clientIp ?? DBNull.Value },
                    new SqlParameter("@OldValue", SqlDbType.NVarChar, -1) { Value = (object)oldValue ?? DBNull.Value },
                    new SqlParameter("@NewValue", SqlDbType.NVarChar, -1) { Value = (object)newValue ?? DBNull.Value },
                    new SqlParameter("@Details", SqlDbType.NVarChar, -1) { Value = (object)details ?? DBNull.Value }
                };

                DbHelper.ExecuteNonQuery(sqlInsert, parameters);
            }
            catch
            {
            }
        }

        #endregion

        #region 3. ?砍?亥?撖怠??????(File Audit Trail)

        /// <summary>
        /// 撖怠?砍 Log 瑼? (App_Data/Logs/audit_yyyyMM.log)
        /// </summary>
        private static void WriteToFile(string operatorUser, string actionType, string targetUser, string clientIp, string details, string oldValue, string newValue)
        {
            try
            {
                string baseDir = AppDomain.CurrentDomain.BaseDirectory;
                string logDir = Path.Combine(baseDir, "App_Data", "Logs");
                if (!Directory.Exists(logDir))
                {
                    Directory.CreateDirectory(logDir);
                }

                // ?芸?皜? 90 憭拐誑銝??亥?
                TryCleanExpiredLogs(logDir);

                string logPath = Path.Combine(logDir, string.Format("audit_{0:yyyyMM}.log", DateTime.Today));
                string timeStr = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");

                StringBuilder sb = new StringBuilder();
                sb.Append(string.Format("[{0}] [OP:{1}] [IP:{2}] [ACTION:{3}] [TARGET:{4}] {5}",
                    timeStr, operatorUser, clientIp, actionType, targetUser ?? "N/A", details ?? ""));

                if (!string.IsNullOrEmpty(oldValue))
                {
                    sb.Append(string.Format(" [OLD:{0}]", oldValue));
                }
                if (!string.IsNullOrEmpty(newValue))
                {
                    sb.Append(string.Format(" [NEW:{0}]", newValue));
                }
                sb.AppendLine();

                lock (FileAuditLock)
                {
                    File.AppendAllText(logPath, sb.ToString(), Encoding.UTF8);
                }
            }
            catch
            {
                // ?砍?亥?撖怠?啣虜摰??
            }
        }

        /// <summary>
        /// ?芸?皜? 90 憭拐誑銝??亥? (瘥?銵?甈?
        /// </summary>
        private static void TryCleanExpiredLogs(string logDir)
        {
            if (s_lastCleanDate == DateTime.Today) return;

            try
            {
                DateTime threshold = DateTime.Today.AddDays(-90);
                string[] logFiles = Directory.GetFiles(logDir, "*.log");
                if (logFiles != null)
                {
                    for (int i = 0; i < logFiles.Length; i++)
                    {
                        FileInfo fi = new FileInfo(logFiles[i]);
                        if (fi.LastWriteTime < threshold)
                        {
                            try
                            {
                                fi.Delete();
                            }
                            catch
                            {
                            }
                        }
                    }
                }
                s_lastCleanDate = DateTime.Today;
            }
            catch
            {
                s_lastCleanDate = DateTime.Today;
            }
        }

        #endregion

        #region 4. ????靘? IP 閫??頛

        /// <summary>
        /// 閫???嗅????董??        /// </summary>
        public static string ResolveCurrentOperator()
        {
            HttpContext ctx = HttpContext.Current;
            if (ctx != null)
            {
                if (ctx.Session != null && ctx.Session["LoginUser"] != null)
                {
                    string sessUser = ctx.Session["LoginUser"].ToString();
                    if (!string.IsNullOrEmpty(sessUser)) return sessUser;
                }

                if (ctx.User != null && ctx.User.Identity != null && !string.IsNullOrEmpty(ctx.User.Identity.Name))
                {
                    return ctx.User.Identity.Name;
                }
            }
            return "SYSTEM";
        }

        /// <summary>
        /// 閫???祕 Client IP 雿? (?舀 Reverse Proxy ??X-Forwarded-For 蝛輸?
        /// </summary>
        public static string ResolveClientIp()
        {
            HttpContext ctx = HttpContext.Current;
            if (ctx == null || ctx.Request == null) return "127.0.0.1";

            try
            {
                string ip = ctx.Request.ServerVariables["HTTP_X_FORWARDED_FOR"];
                if (!string.IsNullOrEmpty(ip))
                {
                    // ?交?憭?IP (頧??嚗?撌血?箏?憪?Client IP
                    string[] parts = ip.Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
                    if (parts.Length > 0)
                    {
                        return parts[0].Trim();
                    }
                }

                ip = ctx.Request.ServerVariables["HTTP_CLIENT_IP"];
                if (!string.IsNullOrEmpty(ip)) return ip.Trim();

                ip = ctx.Request.ServerVariables["REMOTE_ADDR"];
                if (!string.IsNullOrEmpty(ip)) return ip.Trim();

                if (!string.IsNullOrEmpty(ctx.Request.UserHostAddress))
                {
                    return ctx.Request.UserHostAddress.Trim();
                }
            }
            catch
            {
            }

            return "127.0.0.1";
        }

        #endregion

        #region 5. 蝔賣?亥??亥岷 (靘??啁恣??隤輸??

        /// <summary>
        /// ?亥岷 Sys_AuditLog 蝔賣蝝??(??/?蕪)
        /// </summary>
        public static DataTable QueryLogs(string operatorUser, string actionType, string targetUser, DateTime? startDate, DateTime? endDate, int topCount = 500)
        {
            EnsureTableExists();

            StringBuilder sb = new StringBuilder();
            sb.Append(string.Format("SELECT TOP ({0}) [LogId], [Operator], [Action], [Target], [IP], [LogTime], [OldValue], [NewValue], [Details] FROM [Sys_AuditLog] WHERE 1=1", topCount <= 0 ? 500 : topCount));

            var pList = new System.Collections.Generic.List<SqlParameter>();

            if (!string.IsNullOrEmpty(operatorUser))
            {
                sb.Append(" AND [Operator] LIKE @Operator");
                pList.Add(new SqlParameter("@Operator", SqlDbType.NVarChar) { Value = "%" + operatorUser.Trim() + "%" });
            }

            if (!string.IsNullOrEmpty(actionType))
            {
                sb.Append(" AND [Action] = @Action");
                pList.Add(new SqlParameter("@Action", SqlDbType.NVarChar) { Value = actionType.Trim() });
            }

            if (!string.IsNullOrEmpty(targetUser))
            {
                sb.Append(" AND [Target] LIKE @Target");
                pList.Add(new SqlParameter("@Target", SqlDbType.NVarChar) { Value = "%" + targetUser.Trim() + "%" });
            }

            if (startDate.HasValue)
            {
                sb.Append(" AND [LogTime] >= @StartDate");
                pList.Add(new SqlParameter("@StartDate", SqlDbType.DateTime) { Value = startDate.Value });
            }

            if (endDate.HasValue)
            {
                sb.Append(" AND [LogTime] <= @EndDate");
                pList.Add(new SqlParameter("@EndDate", SqlDbType.DateTime) { Value = endDate.Value });
            }

            sb.Append(" ORDER BY [LogTime] DESC");

            return DbHelper.ExecuteDataTable(sb.ToString(), pList.ToArray());
        }

        #endregion
    }
}

