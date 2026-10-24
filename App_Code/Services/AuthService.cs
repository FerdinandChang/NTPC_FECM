using System;
using System.Data;
using System.Data.SqlClient;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using System.Web;
using NTPC_FEC.Helpers;
using NTPC_FEC.Models;

namespace NTPC_FEC.Services
{
    public class AuthService
    {
        private const string HASH_PREFIX = "$S256$";
        private const int SALT_BYTE_SIZE = 16;
        private static bool s_schemaChecked = false;
        private static readonly object s_schemaLock = new object();

        #region 1. 密碼強度檢核
        /// <summary>
        /// 驗證密碼強度（必須 8-20 碼，包含英文大寫、英文小寫、數字及特殊符號）
        /// </summary>
        public static bool CheckStrongPassword(string pwd, out string errorMsg)
        {
            if (string.IsNullOrEmpty(pwd) || pwd.Length < 8 || pwd.Length > 20)
            {
                errorMsg = "新密碼長度必須介於 8 至 20 個字元之間！";
                return false;
            }

            bool hasUpper = Regex.IsMatch(pwd, @"[A-Z]");
            bool hasLower = Regex.IsMatch(pwd, @"[a-z]");
            bool hasDigit = Regex.IsMatch(pwd, @"[0-9]");
            bool hasSpecial = Regex.IsMatch(pwd, @"[!@#$%^&*()_+\-=\[\]{};':""\\|,.<>\/?~`]");

            if (!hasUpper || !hasLower || !hasDigit || !hasSpecial)
            {
                errorMsg = "新密碼必須同時包含：英文大寫字母、英文小寫字母、數字及特殊符號！";
                return false;
            }

            errorMsg = "";
            return true;
        }
        #endregion

        #region 2. 密碼安全雜湊 (Salted SHA-256) 與相容比對
        /// <summary>
        /// 判斷儲存之密碼是否為安全雜湊格式
        /// </summary>
        public static bool IsHashedPassword(string storedPassword)
        {
            if (string.IsNullOrEmpty(storedPassword)) return false;
            return storedPassword.StartsWith(HASH_PREFIX, StringComparison.OrdinalIgnoreCase);
        }

        /// <summary>
        /// 計算明文密碼之 Salted SHA-256 安全雜湊
        /// 輸出格式: $S256${SaltBase64}${HashBase64} (約 75 字元，相容 VARCHAR(128))
        /// </summary>
        public static string HashPassword(string plainPassword)
        {
            if (string.IsNullOrEmpty(plainPassword)) return "";

            byte[] salt = new byte[SALT_BYTE_SIZE];
            using (RNGCryptoServiceProvider rng = new RNGCryptoServiceProvider())
            {
                rng.GetBytes(salt);
            }

            byte[] hash = ComputeSaltedSha256(plainPassword, salt);
            return string.Format("{0}{1}${2}", HASH_PREFIX, Convert.ToBase64String(salt), Convert.ToBase64String(hash));
        }

        private static byte[] ComputeSaltedSha256(string plainPassword, byte[] salt)
        {
            byte[] pwdBytes = Encoding.UTF8.GetBytes(plainPassword);
            byte[] buffer = new byte[salt.Length + pwdBytes.Length];
            Buffer.BlockCopy(salt, 0, buffer, 0, salt.Length);
            Buffer.BlockCopy(pwdBytes, 0, buffer, salt.Length, pwdBytes.Length);

            using (SHA256 sha = SHA256.Create())
            {
                return sha.ComputeHash(buffer);
            }
        }

        /// <summary>
        /// 安全比對密碼 (同時相容舊版明文與新版 Salted 雜湊)
        /// </summary>
        public static bool VerifyPassword(string inputPassword, string storedPassword)
        {
            if (string.IsNullOrEmpty(inputPassword) || string.IsNullOrEmpty(storedPassword))
            {
                return false;
            }

            if (IsHashedPassword(storedPassword))
            {
                try
                {
                    string payload = storedPassword.Substring(HASH_PREFIX.Length);
                    int splitIdx = payload.IndexOf('$');
                    if (splitIdx <= 0) return false;

                    string saltB64 = payload.Substring(0, splitIdx);
                    string hashB64 = payload.Substring(splitIdx + 1);

                    byte[] salt = Convert.FromBase64String(saltB64);
                    byte[] expectedHash = Convert.FromBase64String(hashB64);
                    byte[] actualHash = ComputeSaltedSha256(inputPassword, salt);

                    return SlowEquals(expectedHash, actualHash);
                }
                catch
                {
                    return false;
                }
            }
            else
            {
                // 歷史明文相容比對
                return string.Equals(storedPassword, inputPassword);
            }
        }

        /// <summary>
        /// 常數時間比對位元組陣列，防範時序攻擊 (Timing Attack)
        /// </summary>
        private static bool SlowEquals(byte[] a, byte[] b)
        {
            if (a == null || b == null || a.Length != b.Length) return false;
            int diff = 0;
            for (int i = 0; i < a.Length; i++)
            {
                diff |= (a[i] ^ b[i]);
            }
            return diff == 0;
        }

        /// <summary>
        /// 自動確保資料庫 Password 欄位長度具備 VARCHAR(128) 儲存雜湊的能力
        /// </summary>
        public static void EnsurePasswordColumnCapacity()
        {
            if (s_schemaChecked) return;
            lock (s_schemaLock)
            {
                if (s_schemaChecked) return;
                try
                {
                    string alterSql = @"
                        IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('UserAcc') AND name = 'Password' AND max_length < 128)
                        BEGIN
                            ALTER TABLE UserAcc ALTER COLUMN Password VARCHAR(128);
                        END
                        IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('UserPwdHistory') AND name = 'Password' AND max_length < 128)
                        BEGIN
                            ALTER TABLE UserPwdHistory ALTER COLUMN Password VARCHAR(128);
                        END";
                    DbHelper.ExecuteNonQuery(alterSql);
                    s_schemaChecked = true;
                }
                catch
                {
                    s_schemaChecked = true;
                }
            }
        }
        #endregion

        #region 3. 連續登入失敗防爆破鎖定機制 (5次鎖定15分鐘)
        private class LoginFailRecord
        {
            public int FailCount { get; set; }
            public DateTime? LockUntil { get; set; }
        }

        private static string GetLockCacheKey(string userId)
        {
            return "LoginLock_" + (userId != null ? userId.Trim().ToUpper() : "");
        }

        public static bool IsAccountLocked(string userId, out int remainingMinutes)
        {
            remainingMinutes = 0;
            if (string.IsNullOrEmpty(userId)) return false;

            string key = GetLockCacheKey(userId);
            LoginFailRecord record = HttpRuntime.Cache != null ? HttpRuntime.Cache[key] as LoginFailRecord : null;
            if (record != null && record.LockUntil.HasValue && record.LockUntil.Value > DateTime.Now)
            {
                remainingMinutes = (int)Math.Ceiling((record.LockUntil.Value - DateTime.Now).TotalMinutes);
                if (remainingMinutes < 1) remainingMinutes = 1;
                return true;
            }
            return false;
        }

        public static string RecordLoginFailure(string userId)
        {
            if (string.IsNullOrEmpty(userId)) return "帳號或密碼錯誤，請重新確認！";

            string key = GetLockCacheKey(userId);
            LoginFailRecord record = HttpRuntime.Cache != null ? HttpRuntime.Cache[key] as LoginFailRecord : null;
            if (record == null)
            {
                record = new LoginFailRecord { FailCount = 1 };
            }
            else
            {
                record.FailCount++;
            }

            if (record.FailCount >= 5)
            {
                record.LockUntil = DateTime.Now.AddMinutes(15);
                if (HttpRuntime.Cache != null)
                {
                    HttpRuntime.Cache.Insert(key, record, null, DateTime.Now.AddMinutes(15), System.Web.Caching.Cache.NoSlidingExpiration);
                }
                return "帳號或密碼錯誤已達 5 次！為維護帳號資訊安全，本帳號已被系統安全鎖定 15 分鐘，請稍後再試或洽系統管理員。";
            }
            else
            {
                int remainingTries = 5 - record.FailCount;
                if (HttpRuntime.Cache != null)
                {
                    HttpRuntime.Cache.Insert(key, record, null, DateTime.Now.AddMinutes(15), System.Web.Caching.Cache.NoSlidingExpiration);
                }
                return string.Format("帳號或密碼錯誤，請重新確認！（已失敗 {0} 次，剩餘 {1} 次嘗試機會）", record.FailCount, remainingTries);
            }
        }

        public static void ClearLoginFailure(string userId)
        {
            if (string.IsNullOrEmpty(userId) || HttpRuntime.Cache == null) return;
            string key = GetLockCacheKey(userId);
            HttpRuntime.Cache.Remove(key);
        }
        #endregion

        #region 4. 登入驗證 (含防爆破阻斷與漸進式雜湊升級)
        public static LoginResult ValidateLogin(string userId, string password, string inputValidateCode, HttpContext context)
        {
            var result = new LoginResult();

            if (string.IsNullOrWhiteSpace(userId) || string.IsNullOrWhiteSpace(password))
            {
                result.Success = false;
                result.Message = "請輸入帳號與密碼！";
                return result;
            }

            string cleanUserId = userId.Trim();

            // 1. 檢查帳號是否正處於連續失敗鎖定中
            int lockMins;
            if (IsAccountLocked(cleanUserId, out lockMins))
            {
                result.Success = false;
                result.Message = string.Format("此帳號因連續登入失敗達 5 次，目前處於安全鎖定狀態！請等待約 {0} 分鐘後再試，或洽管理員解鎖。", lockMins);
                return result;
            }

            // 2. 檢查圖形驗證碼
            var sessionCode = (context != null && context.Session != null) ? context.Session["ValidateCode"] as string : null;
            if (string.IsNullOrEmpty(sessionCode))
            {
                result.Success = false;
                result.Message = "驗證碼已逾時，請點擊驗證碼圖片刷新後重新輸入！";
                return result;
            }

            if (!string.Equals(sessionCode.Trim(), (inputValidateCode != null ? inputValidateCode.Trim() : ""), StringComparison.OrdinalIgnoreCase))
            {
                result.Success = false;
                result.Message = "驗證碼輸入錯誤，請重新確認！";
                return result;
            }

            // 驗證碼使用一次後即清除，防範重送攻擊
            if (context != null && context.Session != null)
            {
                context.Session.Remove("ValidateCode");
            }

            // 3. 查詢資料庫使用者
            string sql = "SELECT UID, UserID, Password, PUnit, Name, Acc_State, LIC, LIC2, FAC_ID, LastLogin, LastPwdChangeDate FROM UserAcc WHERE UserID = @UserID";
            var parameters = new SqlParameter[]
            {
                new SqlParameter("@UserID", SqlDbType.VarChar) { Value = cleanUserId }
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
                result.Message = RecordLoginFailure(cleanUserId);
                return result;
            }

            var row = dt.Rows[0];
            string dbPassword = ((row["Password"] != null && row["Password"] != DBNull.Value) ? row["Password"].ToString() : "");
            string accState = ((row["Acc_State"] != null && row["Acc_State"] != DBNull.Value) ? row["Acc_State"].ToString() : "");
            string userName = ((row["Name"] != null && row["Name"] != DBNull.Value) ? row["Name"].ToString() : cleanUserId);

            // 4. 安全密碼驗證 (同時相容雜湊與舊明文)
            bool isPasswordCorrect = VerifyPassword(password, dbPassword);
            if (!isPasswordCorrect)
            {
                result.Success = false;
                result.Message = RecordLoginFailure(cleanUserId);
                return result;
            }

            // 密碼正確，立即清除連續失敗累計
            ClearLoginFailure(cleanUserId);

            // 5. 漸進式雜湊升級 (Hash-on-Login)
            // 若此帳號目前在資料庫中仍為歷史明文，立即於背景無感升級為 Salted SHA-256 雜湊
            if (!IsHashedPassword(dbPassword))
            {
                try
                {
                    EnsurePasswordColumnCapacity();
                    string upgradedHash = HashPassword(password);
                    string upSql = "UPDATE UserAcc SET Password = @NewHash WHERE UserID = @UserID";
                    var upParams = new SqlParameter[]
                    {
                        new SqlParameter("@NewHash", SqlDbType.VarChar) { Value = upgradedHash },
                        new SqlParameter("@UserID", SqlDbType.VarChar) { Value = cleanUserId }
                    };
                    DbHelper.ExecuteNonQuery(upSql, upParams);
                }
                catch
                {
                    // 升級失敗不影響使用者本次正常登入
                }
            }

            // 6. 檢查帳號狀態
            switch (accState.ToUpper())
            {
                case "OK":
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
                    result.Message = string.Format("帳號狀態異常 ({0})，請洽系統管理員！", accState);
                    return result;
            }

            // 7. 封裝使用者資訊
            long lic = 0, lic2 = 0;
            long.TryParse((row["LIC"] != null ? row["LIC"].ToString() : ""), out lic);
            long.TryParse((row["LIC2"] != null ? row["LIC2"].ToString() : ""), out lic2);
            int uid = 0;
            int.TryParse((row["UID"] != null ? row["UID"].ToString() : ""), out uid);

            DateTime? lastPwdDate = null;
            if (row.Table.Columns.Contains("LastPwdChangeDate") && row["LastPwdChangeDate"] != DBNull.Value)
            {
                lastPwdDate = (DateTime?)Convert.ToDateTime(row["LastPwdChangeDate"]);
            }

            string userEmail = (row.Table.Columns.Contains("Email") && row["Email"] != DBNull.Value) ? row["Email"].ToString() : "";

            var user = new UserAccount
            {
                UID = uid,
                UserID = cleanUserId,
                Name = userName,
                PUnit = ((row["PUnit"] != null && row["PUnit"] != DBNull.Value) ? row["PUnit"].ToString() : ""),
                AccState = accState,
                Lic = lic,
                Lic2 = lic2,
                FacID = ((row["FAC_ID"] != null && row["FAC_ID"] != DBNull.Value) ? row["FAC_ID"].ToString() : ""),
                Email = userEmail,
                LastLogin = row["LastLogin"] != DBNull.Value ? (DateTime?)Convert.ToDateTime(row["LastLogin"]) : null,
                LastPwdChangeDate = lastPwdDate
            };

            // 8. 檢核 90 天更換密碼規範
            bool mustChangePwd = false;
            if (!lastPwdDate.HasValue || (DateTime.Now - lastPwdDate.Value).TotalDays >= 90)
            {
                mustChangePwd = true;
            }

            // 9. 寫入 Session 與更新最後登入時間
            if (context != null && context.Session != null)
            {
                context.Session["LoginUser"] = user.UserID;
                context.Session["UserName"] = user.Name;
                context.Session["UserAccount"] = user;
                context.Session["MustChangePassword"] = mustChangePwd;
            }

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
            }

            result.Success = true;
            result.RequirePwdChange = mustChangePwd;
            result.Message = string.Format("{0} 您好，歡迎登入新北市固定溢散源管理平台！", userName);
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
                if (context.Session != null)
                {
                    context.Session.Clear();
                    context.Session.Abandon();
                }
            }
            catch { }

            // 2. 清除自動登入 Cookie
            if (context.Request.Cookies["FEC_Auto_Login"] != null)
            {
                var autoCookie = new HttpCookie("FEC_Auto_Login", "");
                autoCookie.Expires = DateTime.Now.AddDays(-7);
                autoCookie.Path = "/";
                context.Response.Cookies.Add(autoCookie);
            }

            // 3. 廢除 ASP.NET Session Cookie
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
            if (context == null || context.Session == null) return null;
            return context.Session["UserAccount"] as UserAccount;
        }
        #endregion

        #region 5. 變更密碼 (含雜湊加密與歷史紀錄比對)
        public static OperationResult ChangePassword(string userId, string oldPwd, string newPwd, string confirmPwd)
        {
            var result = new OperationResult();

            if (string.IsNullOrEmpty(userId))
            {
                result.Success = false;
                result.Message = "登入已逾期，請重新登入系統！";
                return result;
            }

            if (string.IsNullOrEmpty(oldPwd) || string.IsNullOrEmpty(newPwd) || string.IsNullOrEmpty(confirmPwd))
            {
                result.Success = false;
                result.Message = "請完整輸入所有密碼欄位！";
                return result;
            }

            if (newPwd != confirmPwd)
            {
                result.Success = false;
                result.Message = "兩次輸入的新密碼不一致，請重新確認！";
                return result;
            }

            // 1. 強密碼驗證
            string pwdError;
            if (!CheckStrongPassword(newPwd, out pwdError))
            {
                result.Success = false;
                result.Message = pwdError;
                return result;
            }

            try
            {
                EnsurePasswordColumnCapacity();

                // 2. 查詢當前密碼與最後修改時間
                string querySql = "SELECT Password, LastPwdChangeDate FROM UserAcc WHERE UserID = @UserID";
                var queryParams = new SqlParameter[]
                {
                    new SqlParameter("@UserID", SqlDbType.VarChar) { Value = userId }
                };

                DataTable dt = DbHelper.ExecuteDataTable(querySql, queryParams);
                if (dt == null || dt.Rows.Count == 0)
                {
                    result.Success = false;
                    result.Message = "找不到使用者帳號資料！";
                    return result;
                }

                DataRow row = dt.Rows[0];
                string currentDbPwd = row["Password"] != null ? row["Password"].ToString() : "";
                DateTime? lastPwdChangeDate = null;
                if (row.Table.Columns.Contains("LastPwdChangeDate") && row["LastPwdChangeDate"] != DBNull.Value)
                {
                    lastPwdChangeDate = (DateTime?)Convert.ToDateTime(row["LastPwdChangeDate"]);
                }

                // 3. 檢查目前舊密碼是否吻合
                if (!VerifyPassword(oldPwd, currentDbPwd))
                {
                    result.Success = false;
                    result.Message = "目前舊密碼輸入錯誤，無法更新！";
                    return result;
                }

                // 4. 新舊密碼不可相同
                if (VerifyPassword(newPwd, currentDbPwd))
                {
                    result.Success = false;
                    result.Message = "新密碼不可與目前使用之舊密碼相同！";
                    return result;
                }

                // 5. 單日只能更換一次密碼
                if (lastPwdChangeDate.HasValue && lastPwdChangeDate.Value.Date == DateTime.Today)
                {
                    result.Success = false;
                    result.Message = "基於資安考量，單日僅限更換密碼一次！您今日已變更過密碼，請於明日再試。";
                    return result;
                }

                // 6. 不得與前三次歷史密碼相同
                string histSql = "SELECT TOP 3 Password FROM UserPwdHistory WHERE UserID = @UserID ORDER BY ChangeDate DESC, HistID DESC";
                var histParams = new SqlParameter[]
                {
                    new SqlParameter("@UserID", SqlDbType.VarChar) { Value = userId }
                };
                DataTable histDt = DbHelper.ExecuteDataTable(histSql, histParams);
                if (histDt != null && histDt.Rows.Count > 0)
                {
                    foreach (DataRow hRow in histDt.Rows)
                    {
                        string histPwd = hRow["Password"] != null ? hRow["Password"].ToString() : "";
                        if (VerifyPassword(newPwd, histPwd))
                        {
                            result.Success = false;
                            result.Message = "新密碼不得與前三次使用過之歷史密碼相同！";
                            return result;
                        }
                    }
                }

                // 7. 將當前密碼寫入歷史記錄表 (若非雜湊則順手轉為雜湊儲存)
                string histToSave = IsHashedPassword(currentDbPwd) ? currentDbPwd : HashPassword(currentDbPwd);
                string insHistSql = "INSERT INTO UserPwdHistory (UserID, Password, ChangeDate) VALUES (@UserID, @Password, GETDATE())";
                var insHistParams = new SqlParameter[]
                {
                    new SqlParameter("@UserID", SqlDbType.VarChar) { Value = userId },
                    new SqlParameter("@Password", SqlDbType.VarChar) { Value = histToSave }
                };
                DbHelper.ExecuteNonQuery(insHistSql, insHistParams);

                // 8. 以安全雜湊格式更新使用者密碼
                string hashedNewPwd = HashPassword(newPwd);
                string updateSql = "UPDATE UserAcc SET Password = @NewPassword, LastPwdChangeDate = GETDATE() WHERE UserID = @UserID";
                var updateParams = new SqlParameter[]
                {
                    new SqlParameter("@NewPassword", SqlDbType.VarChar) { Value = hashedNewPwd },
                    new SqlParameter("@UserID", SqlDbType.VarChar) { Value = userId }
                };
                DbHelper.ExecuteNonQuery(updateSql, updateParams);

                // 9. 更新 Session 狀態
                if (HttpContext.Current != null && HttpContext.Current.Session != null)
                {
                    HttpContext.Current.Session["MustChangePassword"] = false;
                }

                // 清除可能殘留之失敗鎖定狀態
                ClearLoginFailure(userId);

                result.Success = true;
                result.Message = "密碼變更成功！請牢記您的新密碼。";
                return result;
            }
            catch (Exception ex)
            {
                result.Success = false;
                result.Message = "密碼變更失敗，資料庫連線異常：" + ex.Message;
                return result;
            }
        }
        #endregion

        #region 6. 臨時密碼發行與忘記密碼處理
        public static string GenerateSecureTempPassword(int length)
        {
            if (length < 8) length = 8;
            string upper = "ABCDEFGHJKLMNPQRSTUVWXYZ";
            string lower = "abcdefghijkmnopqrstuvwxyz";
            string digits = "23456789";
            string specials = "!@#$%*-_+";

            char[] pwdChars = new char[length];
            byte[] randBytes = new byte[length];
            using (RNGCryptoServiceProvider rng = new RNGCryptoServiceProvider())
            {
                rng.GetBytes(randBytes);
            }

            pwdChars[0] = upper[randBytes[0] % upper.Length];
            pwdChars[1] = lower[randBytes[1] % lower.Length];
            pwdChars[2] = digits[randBytes[2] % digits.Length];
            pwdChars[3] = specials[randBytes[3] % specials.Length];

            string allChars = upper + lower + digits + specials;
            for (int i = 4; i < length; i++)
            {
                pwdChars[i] = allChars[randBytes[i] % allChars.Length];
            }

            for (int i = length - 1; i > 0; i--)
            {
                int swapIdx = randBytes[i] % (i + 1);
                char temp = pwdChars[i];
                pwdChars[i] = pwdChars[swapIdx];
                pwdChars[swapIdx] = temp;
            }

            return new string(pwdChars);
        }

        public static OperationResult ResetUserTempPasswordAndSendEmail(string targetUserId, string targetEmail)
        {
            var result = new OperationResult();

            if (string.IsNullOrEmpty(targetUserId) || string.IsNullOrEmpty(targetEmail))
            {
                result.Success = false;
                result.Message = "目標帳號與收件信箱均不可為空！";
                return result;
            }

            try
            {
                EnsurePasswordColumnCapacity();

                // 1. 查詢目標帳號
                string qSql = "SELECT Name, Password FROM UserAcc WHERE UserID = @UserID";
                var qParams = new SqlParameter[] { new SqlParameter("@UserID", SqlDbType.VarChar) { Value = targetUserId } };
                DataTable dt = DbHelper.ExecuteDataTable(qSql, qParams);
                if (dt == null || dt.Rows.Count == 0)
                {
                    result.Success = false;
                    result.Message = "找不到該使用者帳號！";
                    return result;
                }

                string currentPwd = dt.Rows[0]["Password"] != null ? dt.Rows[0]["Password"].ToString() : "";
                string userName = dt.Rows[0]["Name"] != null ? dt.Rows[0]["Name"].ToString() : targetUserId;

                // 2. 產生 10 碼高強度臨時密碼
                string tempPwd = GenerateSecureTempPassword(10);

                // 3. 先寄出通知信件 (若郵件發送失敗則立即中止，維持原密碼)
                OperationResult mailRes = MailService.SendTempPasswordEmail(targetEmail, targetUserId, userName, tempPwd);
                if (!mailRes.Success)
                {
                    result.Success = false;
                    result.Message = "郵件發送失敗，密碼未更新：" + mailRes.Message;
                    return result;
                }

                // 4. 舊密碼寫入歷史記錄表
                if (!string.IsNullOrEmpty(currentPwd))
                {
                    string histToSave = IsHashedPassword(currentPwd) ? currentPwd : HashPassword(currentPwd);
                    string histSql = "INSERT INTO UserPwdHistory (UserID, Password, ChangeDate) VALUES (@UserID, @Password, GETDATE())";
                    var histParams = new SqlParameter[]
                    {
                        new SqlParameter("@UserID", SqlDbType.VarChar) { Value = targetUserId },
                        new SqlParameter("@Password", SqlDbType.VarChar) { Value = histToSave }
                    };
                    DbHelper.ExecuteNonQuery(histSql, histParams);
                }

                // 5. 更新 UserAcc：更換為臨時密碼之安全雜湊、更新 Email、LastPwdChangeDate 設為 NULL
                string hashedTempPwd = HashPassword(tempPwd);
                string updateSql = "UPDATE UserAcc SET Password = @NewPwd, Email = @Email, LastPwdChangeDate = NULL WHERE UserID = @UserID";
                var updateParams = new SqlParameter[]
                {
                    new SqlParameter("@NewPwd", SqlDbType.VarChar) { Value = hashedTempPwd },
                    new SqlParameter("@Email", SqlDbType.VarChar) { Value = targetEmail.Trim() },
                    new SqlParameter("@UserID", SqlDbType.VarChar) { Value = targetUserId }
                };
                DbHelper.ExecuteNonQuery(updateSql, updateParams);

                // 6. 清除失敗鎖定狀態
                ClearLoginFailure(targetUserId);

                result.Success = true;
                result.Message = string.Format("臨時密碼已成功發行並寄送至信箱 [{0}]！該使用者登入後將強制修改密碼。", targetEmail);
                return result;
            }
            catch (Exception ex)
            {
                result.Success = false;
                result.Message = "處理失敗，資料庫異常：" + ex.Message;
                return result;
            }
        }
        #endregion
    }
}
