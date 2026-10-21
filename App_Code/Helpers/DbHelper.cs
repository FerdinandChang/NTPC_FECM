using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;

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
            var setting = ConfigurationManager.ConnectionStrings[name];
            if (setting == null || string.IsNullOrEmpty(setting.ConnectionString))
            {
                throw new InvalidOperationException($"未在 Web.config 中找到有效的資料庫連線字串設定：{name}");
            }
            return setting.ConnectionString;
        }

        public static SqlConnection GetOpenConnection(string connectionName = null)
        {
            var conn = new SqlConnection(GetConnectionString(connectionName));
            conn.Open();
            return conn;
        }

        public static DataTable ExecuteDataTable(string sql, SqlParameter[] parameters = null, string connectionName = null)
        {
            using (var conn = GetOpenConnection(connectionName))
            using (var cmd = new SqlCommand(sql, conn))
            {
                if (parameters != null && parameters.Length > 0)
                {
                    cmd.Parameters.AddRange(parameters);
                }

                using (var da = new SqlDataAdapter(cmd))
                {
                    var dt = new DataTable();
                    da.Fill(dt);
                    return dt;
                }
            }
        }

        public static int ExecuteNonQuery(string sql, SqlParameter[] parameters = null, string connectionName = null)
        {
            using (var conn = GetOpenConnection(connectionName))
            using (var cmd = new SqlCommand(sql, conn))
            {
                if (parameters != null && parameters.Length > 0)
                {
                    cmd.Parameters.AddRange(parameters);
                }
                return cmd.ExecuteNonQuery();
            }
        }

        public static object ExecuteScalar(string sql, SqlParameter[] parameters = null, string connectionName = null)
        {
            using (var conn = GetOpenConnection(connectionName))
            using (var cmd = new SqlCommand(sql, conn))
            {
                if (parameters != null && parameters.Length > 0)
                {
                    cmd.Parameters.AddRange(parameters);
                }
                return cmd.ExecuteScalar();
            }
        }
    }
}
