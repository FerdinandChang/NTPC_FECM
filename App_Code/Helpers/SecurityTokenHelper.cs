using System;
using System.Security.Cryptography;
using System.Text;

namespace NTPC_FEC.Helpers
{
    /// <summary>
    /// ?典?獢?URL ????脩砥??Token 撽???(瘨? 15+ ??銴?撌?MD5 瘥?)
    /// ?詨捆 C# 5.0 閬?
    /// </summary>
    public static class SecurityTokenHelper
    {
        /// <summary>
        /// 閮?摮葡??MD5 ????(32 蝣澆?撖怠??剝脖?)
        /// </summary>
        public static string ComputeMd5(string input)
        {
            if (string.IsNullOrEmpty(input)) return string.Empty;

            using (MD5 md5 = MD5.Create())
            {
                byte[] bytes = md5.ComputeHash(Encoding.UTF8.GetBytes(input));
                StringBuilder sb = new StringBuilder();
                for (int i = 0; i < bytes.Length; i++)
                {
                    sb.Append(bytes[i].ToString("x2"));
                }
                return sb.ToString();
            }
        }

        /// <summary>
        /// ?Ｙ??嗅?撠?銋?皞??蝭⊥ Token
        /// </summary>
        public static string GenerateHourToken(string key, string prefix)
        {
            if (string.IsNullOrEmpty(key)) return string.Empty;
            string pfx = prefix != null ? prefix : "MD5:";
            string raw = pfx + key.Trim() + DateTime.Now.ToString("yyyyMMddHH");
            return ComputeMd5(raw);
        }

        public static string GenerateHourToken(string key)
        {
            return GenerateHourToken(key, "MD5:");
        }

        /// <summary>
        /// ?Ｙ??嗆銋蝭⊥ Token (隞交?箏雿?
        /// </summary>
        public static string GenerateDayToken(string key, string prefix)
        {
            if (string.IsNullOrEmpty(key)) return string.Empty;
            string pfx = prefix != null ? prefix : "NTPC_FEC_";
            string raw = pfx + key.Trim() + DateTime.Now.ToString("yyyyMMdd");
            return ComputeMd5(raw);
        }

        /// <summary>
        /// 撽?撠?蝝??蝭⊥ Token (?身?迂?嗅?撠??? 1 撠?銋??捆??
        /// </summary>
        public static bool ValidateHourToken(string inputToken, string key, string prefix, int validHours)
        {
            if (string.IsNullOrEmpty(inputToken) || string.IsNullOrEmpty(key)) return false;

            string pfx = prefix != null ? prefix : "MD5:";
            string cleanKey = key.Trim();
            int hours = validHours > 0 ? validHours : 2;

            DateTime now = DateTime.Now;
            for (int i = 0; i < hours; i++)
            {
                string hourStr = now.AddHours(-i).ToString("yyyyMMddHH");
                string expected = ComputeMd5(pfx + cleanKey + hourStr);
                if (string.Equals(inputToken.Trim(), expected, StringComparison.OrdinalIgnoreCase))
                {
                    return true;
                }
            }

            return false;
        }

        public static bool ValidateHourToken(string inputToken, string key, string prefix)
        {
            return ValidateHourToken(inputToken, key, prefix, 2);
        }

        public static bool ValidateHourToken(string inputToken, string key)
        {
            return ValidateHourToken(inputToken, key, "MD5:", 2);
        }

        /// <summary>
        /// 撽??嗆蝝蝭⊥ Token
        /// </summary>
        public static bool ValidateDayToken(string inputToken, string key, string prefix)
        {
            if (string.IsNullOrEmpty(inputToken) || string.IsNullOrEmpty(key)) return false;

            string pfx = prefix != null ? prefix : "NTPC_FEC_";
            string cleanKey = key.Trim();

            for (int i = 0; i < 2; i++)
            {
                string dayStr = DateTime.Now.AddDays(-i).ToString("yyyyMMdd");
                string expected = ComputeMd5(pfx + cleanKey + dayStr);
                if (string.Equals(inputToken.Trim(), expected, StringComparison.OrdinalIgnoreCase))
                {
                    return true;
                }
            }

            return false;
        }
    }
}

