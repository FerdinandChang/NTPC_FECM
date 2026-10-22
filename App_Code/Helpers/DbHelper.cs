using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Text;
using System.Web;
using System.Web.Configuration;
using System.Web.Hosting;

namespace NTPC_FEC.Helpers
{
    /// <summary>
    /// 資料庫存取核心類別 (安全參數化查詢，杜絕 SQL Injection)
    /// </summary>
    public static class DbHelper
    {
        private static string DefaultConnectionStringName = "MainConnectionString";

        public static string GetConnectionString(string connectionName = null)
        {
            string name = string.IsNullOrEmpty(connectionName) ? DefaultConnectionStringName : connectionName;
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

        public static DataTable ExecuteDataTable(string sql, params SqlParameter[] parameters)
        {
            return ExecuteDataTable(sql, parameters, null);
        }

        public static DataTable ExecuteDataTable(string sql, SqlParameter[] parameters, string connectionName)
        {
            using (var conn = GetOpenConnection(connectionName))
            using (var cmd = new SqlCommand(sql, conn))
            {
                cmd.CommandTimeout = 120;
                AttachParameters(cmd, parameters);

                try
                {
                    using (var da = new SqlDataAdapter(cmd))
                    {
                        var dt = new DataTable();
                        da.Fill(dt);
                        return dt;
                    }
                }
                finally
                {
                    cmd.Parameters.Clear();
                }
            }
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
    }
}
