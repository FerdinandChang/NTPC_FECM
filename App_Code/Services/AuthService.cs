using System;
using System.Data;
using System.Data.SqlClient;
using System.Web;
using NTPC_FEC.Helpers;
using NTPC_FEC.Models;

namespace NTPC_FEC.Services
{
    public class AuthService
    {
        public static LoginResult ValidateLogin(string userId, string password, string inputValidateCode, HttpContext context)
        {
            var result = new LoginResult();

            // 1. 檢查圖形驗證碼
            var sessionCode = context.Session["ValidateCode"] as string;
            if (string.IsNullOrEmpty(sessionCode))
            {
                result.Success = false;
                result.Message = "驗證碼已逾時，請點擊驗證碼圖片刷新後重新輸入！";
                return result;
            }

            if (!string.Equals(sessionCode.Trim(), inputValidateCode?.Trim(), StringComparison.OrdinalIgnoreCase))
            {
                result.Success = false;
                result.Message = "驗證碼輸入錯誤，請重新確認！";
                return result;
            }

            // 驗證碼使用一次後即清除，防範重送攻擊
            context.Session.Remove("ValidateCode");

            if (string.IsNullOrWhiteSpace(userId) || string.IsNullOrWhiteSpace(password))
            {
                result.Success = false;
                result.Message = "請輸入帳號與密碼！";
                return result;
            }

            // 2. 查詢資料庫使用者
            string sql = "SELECT UID, UserID, Password, Name, Acc_State, LIC, LIC2, FAC_ID, LastLogin FROM UserAcc WHERE UserID = @UserID";
            var parameters = new SqlParameter[]
            {
                new SqlParameter("@UserID", SqlDbType.VarChar) { Value = userId.Trim() }
            };

            DataTable dt;
            try
            {
                dt = DbHelper.ExecuteDataTable(sql, parameters);
            }
            catch (Exception ex)
            {
                result.Success = false;
                result.Message = "系統資料庫連線異常，請稍後再試或洽管理員：" + ex.Message;
                return result;
            }

            if (dt.Rows.Count == 0)
            {
                result.Success = false;
                result.Message = "無此帳號，請確認後重新輸入！";
                return result;
            }

            var row = dt.Rows[0];
            string dbPassword = row["Password"]?.ToString() ?? "";
            string accState = row["Acc_State"]?.ToString() ?? "";
            string userName = row["Name"]?.ToString() ?? userId;

            // 3. 密碼驗證 (兼顧歷史明文與安全比對)
            bool isPasswordCorrect = string.Equals(dbPassword, password);
            if (!isPasswordCorrect)
            {
                result.Success = false;
                result.Message = "帳號或密碼錯誤，請重新確認！";
                return result;
            }

            // 4. 檢查帳號狀態
            switch (accState.ToUpper())
            {
                case "OK":
                    // 正常啟用
                    break;
                case "GU":
                    result.Success = false;
                    result.Message = "此為管理人員專用介面，請由【新北市環境自主環護管理系統】登入！";
                    return result;
                case "CL":
                    result.Success = false;
                    result.Message = "您的帳號已被管理人員停用，請洽系統管理人員！";
                    return result;
                default:
                    result.Success = false;
                    result.Message = $"帳號狀態異常 ({accState})，請洽系統管理員！";
                    return result;
            }

            // 5. 封裝使用者資訊
            long lic = 0, lic2 = 0;
            long.TryParse(row["LIC"]?.ToString(), out lic);
            long.TryParse(row["LIC2"]?.ToString(), out lic2);
            int uid = 0;
            int.TryParse(row["UID"]?.ToString(), out uid);

            var user = new UserAccount
            {
                UID = uid,
                UserID = userId,
                Name = userName,
                AccState = accState,
                Lic = lic,
                Lic2 = lic2,
                FacID = row["FAC_ID"]?.ToString() ?? "",
                LastLogin = row["LastLogin"] != DBNull.Value ? (DateTime?)Convert.ToDateTime(row["LastLogin"]) : null
            };

            // 6. 寫入 Session 與更新最後登入時間
            context.Session["LoginUser"] = user.UserID;
            context.Session["UserName"] = user.Name;
            context.Session["UserAccount"] = user;

            try
            {
                string updateSql = "UPDATE UserAcc SET LastLogin = @LastLogin WHERE UserID = @UserID";
                var updateParams = new SqlParameter[]
                {
                    new SqlParameter("@LastLogin", SqlDbType.DateTime) { Value = DateTime.Now },
                    new SqlParameter("@UserID", SqlDbType.VarChar) { Value = user.UserID }
                };
                DbHelper.ExecuteNonQuery(updateSql, updateParams);
            }
            catch
            {
                // 更新時間失敗不影響登入
            }

            result.Success = true;
            result.Message = $"{userName} 您好，歡迎登入新北市固定溢散源管理平台！";
            result.RedirectUrl = "MainPage.aspx";
            result.User = user;

            return result;
        }

        public static void Logout(HttpContext context)
        {
            if (context == null) return;

            // 1. 清空 Session
            try
            {
                context.Session.Clear();
                context.Session.Abandon();
            }
            catch { }

            // 2. 清除自動登入 Cookie (FEC_Auto_Login)
            if (context.Request.Cookies["FEC_Auto_Login"] != null)
            {
                var autoCookie = new HttpCookie("FEC_Auto_Login", "");
                autoCookie.Expires = DateTime.Now.AddDays(-7);
                autoCookie.Path = "/";
                context.Response.Cookies.Add(autoCookie);
            }

            // 3. 廢除 ASP.NET Session Cookie (防範 Session 固定攻擊)
            if (context.Request.Cookies["ASP.NET_SessionId"] != null)
            {
                var sessionCookie = new HttpCookie("ASP.NET_SessionId", "");
                sessionCookie.Expires = DateTime.Now.AddDays(-7);
                sessionCookie.Path = "/";
                context.Response.Cookies.Add(sessionCookie);
            }
        }

        public static UserAccount GetCurrentUser(HttpContext context)
        {
            return context.Session["UserAccount"] as UserAccount;
        }
    }
}
