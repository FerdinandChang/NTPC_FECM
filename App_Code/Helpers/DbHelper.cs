using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Text;
using System.Threading;
using System.Web;
using System.Web.Configuration;
using System.Web.Hosting;

namespace NTPC_FEC.Helpers
{
    /// <summary>
    /// 資料庫存取核心類別 (安全參數化查詢，杜絕 SQL Injection，具備暫態故障自動重試)
    /// </summary>
    public static class DbHelper
    {
        private static string DefaultConnectionStringName = "MainConnectionString";
        private static readonly System.Collections.Concurrent.ConcurrentDictionary<string, string> ConnectionStringCache =
            new System.Collections.Concurrent.ConcurrentDictionary<string, string>(StringComparer.OrdinalIgnoreCase);

        public static string GetConnectionString(string connectionName = null)
        {
            string name = string.IsNullOrEmpty(connectionName) ? DefaultConnectionStringName : connectionName;
            string cachedConnStr;
            if (ConnectionStringCache.TryGetValue(name, out cachedConnStr) && !string.IsNullOrEmpty(cachedConnStr))
            {
                return cachedConnStr;
            }
            string connStr = null;

            // 1. 優先嘗試 WebConfigurationManager (標準 ASP.NET Web 配置管理器)
            try
            {
                ConnectionStringSettings setting = WebConfigurationManager.ConnectionStrings[name];
                if (setting != null && !string.IsNullOrEmpty(setting.ConnectionString))
                {
                    connStr = setting.ConnectionString;
                }
            }
            catch
            {
            }

            // 2. 次要嘗試通用 ConfigurationManager
            if (string.IsNullOrEmpty(connStr))
            {
                try
                {
                    ConnectionStringSettings setting = ConfigurationManager.ConnectionStrings[name];
                    if (setting != null && !string.IsNullOrEmpty(setting.ConnectionString))
                    {
                        connStr = setting.ConnectionString;
                    }
                }
                catch
                {
                }
            }

            // 3. 嘗試以 HostingEnvironment 虛擬路徑明確開啟 WebConfiguration (支援 IIS 虛擬子應用程式環境)
            if (string.IsNullOrEmpty(connStr))
            {
                try
                {
                    string vpath = HostingEnvironment.ApplicationVirtualPath;
                    if (!string.IsNullOrEmpty(vpath))
                    {
                        Configuration config = WebConfigurationManager.OpenWebConfiguration(vpath);
                        if (config != null && config.ConnectionStrings != null && config.ConnectionStrings.ConnectionStrings[name] != null)
                        {
                            connStr = config.ConnectionStrings.ConnectionStrings[name].ConnectionString;
                        }
                    }
                }
                catch
                {
                }
            }

            // 4. 舊版 namSQLconn 相容邏輯：從 HttpContext 當前 Request 提取虛擬子應用程式目錄 (如 /NTPC_FECM)
            if (string.IsNullOrEmpty(connStr))
            {
                try
                {
                    HttpContext ctx = HttpContext.Current;
                    if (ctx != null && ctx.Request != null)
                    {
                        string appPath = ctx.Request.ApplicationPath;
                        if (!string.IsNullOrEmpty(appPath))
                        {
                            Configuration config = WebConfigurationManager.OpenWebConfiguration(appPath);
                            if (config != null && config.ConnectionStrings != null && config.ConnectionStrings.ConnectionStrings[name] != null)
                            {
                                connStr = config.ConnectionStrings.ConnectionStrings[name].ConnectionString;
                            }
                        }

                        if (string.IsNullOrEmpty(connStr) && ctx.Request.Url != null && ctx.Request.Url.Segments != null && ctx.Request.Url.Segments.Length > 1)
                        {
                            string seg = "/" + ctx.Request.Url.Segments[1].Trim('/');
                            Configuration config = WebConfigurationManager.OpenWebConfiguration(seg);
                            if (config != null && config.ConnectionStrings != null && config.ConnectionStrings.ConnectionStrings[name] != null)
                            {
                                connStr = config.ConnectionStrings.ConnectionStrings[name].ConnectionString;
                            }
                        }
                    }
                }
                catch
                {
                }
            }

            if (string.IsNullOrEmpty(connStr))
            {
                StringBuilder sb = new StringBuilder();
                sb.Append(string.Format("未在 Web.config 中找到有效的資料庫連線字串設定：{0}。", name));
                try
                {
                    sb.Append(" [現有 ConnectionStrings: ");
                    if (ConfigurationManager.ConnectionStrings != null && ConfigurationManager.ConnectionStrings.Count > 0)
                    {
                        for (int i = 0; i < ConfigurationManager.ConnectionStrings.Count; i++)
                        {
                            if (i > 0)
                            {
                                sb.Append(", ");
                            }
                            sb.Append(ConfigurationManager.ConnectionStrings[i].Name);
                        }
                    }
                    else
                    {
                        sb.Append("無");
                    }
                    sb.Append("]");

                    if (HttpContext.Current != null && HttpContext.Current.Request != null)
                    {
                        sb.Append(string.Format(" [AppPath: {0}, BaseDir: {1}]", 
                            HttpContext.Current.Request.ApplicationPath, 
                            AppDomain.CurrentDomain.BaseDirectory));
                    }
                }
                catch
                {
                }
                throw new InvalidOperationException(sb.ToString());
            }

            ConnectionStringCache[name] = connStr;
            return connStr;
        }

        public static SqlConnection GetOpenConnection(string connectionName = null)
        {
            var conn = new SqlConnection(GetConnectionString(connectionName));
            conn.Open();
            return conn;
        }

        private static void AttachParameters(SqlCommand cmd, SqlParameter[] parameters)
        {
            if (parameters != null && parameters.Length > 0)
            {
                foreach (SqlParameter p in parameters)
                {
                    if (p != null)
                    {
                        SqlParameter pToAdd = (p is ICloneable)
                            ? (SqlParameter)((ICloneable)p).Clone()
                            : new SqlParameter(p.ParameterName, p.Value);
                        cmd.Parameters.Add(pToAdd);
                    }
                }
            }
        }

        private static bool IsTransientSqlError(SqlException ex)
        {
            if (ex == null) return false;
            // 典型暫態抖動錯誤代碼：-2 逾時, 1205 死鎖, 10054 斷線重置等
            int[] transientNumbers = new int[] { -2, 64, 233, 1205, 10053, 10054, 10060, 40613 };
            for (int i = 0; i < transientNumbers.Length; i++)
            {
                if (ex.Number == transientNumbers[i]) return true;
            }
            return false;
        }

        public static DataTable ExecuteDataTable(string sql, params SqlParameter[] parameters)
        {
            return ExecuteDataTable(sql, parameters, null);
        }

        public static DataTable ExecuteDataTable(string sql, SqlParameter[] parameters, string connectionName)
        {
            int maxRetries = 1;
            for (int attempt = 0; attempt <= maxRetries; attempt++)
            {
                try
                {
                    using (var conn = GetOpenConnection(connectionName))
                    using (var cmd = new SqlCommand(sql, conn))
                    {
                        cmd.CommandTimeout = 120;
                        AttachParameters(cmd, parameters);

                        using (var da = new SqlDataAdapter(cmd))
                        {
                            var dt = new DataTable();
                            da.Fill(dt);
                            return dt;
                        }
                    }
                }
                catch (SqlException ex)
                {
                    if (attempt < maxRetries && IsTransientSqlError(ex))
                    {
                        Thread.Sleep(200); // 暫態抖動微秒級避讓重試
                        continue;
                    }
                    throw;
                }
            }
            return new DataTable();
        }

        public static int ExecuteNonQuery(string sql, params SqlParameter[] parameters)
        {
            return ExecuteNonQuery(sql, parameters, null);
        }

        public static int ExecuteNonQuery(string sql, SqlParameter[] parameters, string connectionName)
        {
            using (var conn = GetOpenConnection(connectionName))
            using (var cmd = new SqlCommand(sql, conn))
            {
                cmd.CommandTimeout = 120;
                AttachParameters(cmd, parameters);
                try
                {
                    return cmd.ExecuteNonQuery();
                }
                finally
                {
                    cmd.Parameters.Clear();
                }
            }
        }

        public static object ExecuteScalar(string sql, params SqlParameter[] parameters)
        {
            return ExecuteScalar(sql, parameters, null);
        }

        public static object ExecuteScalar(string sql, SqlParameter[] parameters, string connectionName)
        {
            int maxRetries = 1;
            for (int attempt = 0; attempt <= maxRetries; attempt++)
            {
                try
                {
                    using (var conn = GetOpenConnection(connectionName))
                    using (var cmd = new SqlCommand(sql, conn))
                    {
                        cmd.CommandTimeout = 120;
                        AttachParameters(cmd, parameters);
                        try
                        {
                            return cmd.ExecuteScalar();
                        }
                        finally
                        {
                            cmd.Parameters.Clear();
                        }
                    }
                }
                catch (SqlException ex)
                {
                    if (attempt < maxRetries && IsTransientSqlError(ex))
                    {
                        Thread.Sleep(200);
                        continue;
                    }
                    throw;
                }
            }
            return null;
        }

        /// <summary>
        /// 安全事務執行器：自動建立連線、開啟 Transaction、呼叫委派，並於發生例外時自動 Rollback
        /// 相容 C# 5.0 規範
        /// </summary>
        public static bool ExecuteTransaction(Func<SqlConnection, SqlTransaction, bool> action, string connectionName)
        {
            if (action == null) return false;

            using (var conn = GetOpenConnection(connectionName))
            {
                using (var trans = conn.BeginTransaction())
                {
                    try
                    {
                        bool success = action(conn, trans);
                        if (success)
                        {
                            trans.Commit();
                            return true;
                        }
                        else
                        {
                            trans.Rollback();
                            return false;
                        }
                    }
                    catch
                    {
                        try
                        {
                            trans.Rollback();
                        }
                        catch
                        {
                        }
                        throw;
                    }
                }
            }
        }

        public static bool ExecuteTransaction(Func<SqlConnection, SqlTransaction, bool> action)
        {
            return ExecuteTransaction(action, null);
        }

        /// <summary>
        /// 標準高效 SQL 分頁查詢器 (消除清單頁面重複手寫 ROW_NUMBER 與總頁數計算)
        /// 相容 C# 5.0 規範
        /// </summary>
        public static DataTable ExecutePagedDataTable(
            string selectFields, 
            string fromClause, 
            string whereClause, 
            string orderBy, 
            int pageIndex, 
            int pageSize, 
            SqlParameter[] parameters, 
            out int totalCount, 
            string connectionName)
        {
            totalCount = 0;
            int page = pageIndex > 0 ? pageIndex : 1;
            int size = pageSize > 0 ? pageSize : 20;
            int startRow = (page - 1) * size + 1;
            int endRow = page * size;

            string cleanWhere = string.IsNullOrWhiteSpace(whereClause) ? "1=1" : whereClause.Trim();
            string cleanOrder = string.IsNullOrWhiteSpace(orderBy) ? "(SELECT 1)" : orderBy.Trim();

            // 1. 查詢總筆數
            string countSql = string.Format("SELECT COUNT(*) FROM {0} WHERE {1}", fromClause, cleanWhere);
            object countObj = ExecuteScalar(countSql, parameters, connectionName);
            if (countObj != null && countObj != DBNull.Value)
            {
                int.TryParse(countObj.ToString(), out totalCount);
            }

            if (totalCount == 0)
            {
                return new DataTable();
            }

            // 2. 查詢分頁資料
            string pagedSql = string.Format(@"
WITH PagedData AS (
    SELECT {0}, ROW_NUMBER() OVER (ORDER BY {1}) AS _RowNum
    FROM {2}
    WHERE {3}
)
SELECT * FROM PagedData
WHERE _RowNum BETWEEN {4} AND {5}
ORDER BY _RowNum ASC", selectFields, cleanOrder, fromClause, cleanWhere, startRow, endRow);

            return ExecuteDataTable(pagedSql, parameters, connectionName);
        }

        public static DataTable ExecutePagedDataTable(
            string selectFields, 
            string fromClause, 
            string whereClause, 
            string orderBy, 
            int pageIndex, 
            int pageSize, 
            SqlParameter[] parameters, 
            out int totalCount)
        {
            return ExecutePagedDataTable(selectFields, fromClause, whereClause, orderBy, pageIndex, pageSize, parameters, out totalCount, null);
        }
    }
}
