using System;
using System.IO;
using System.Web;

namespace NTPC_FEC.Helpers
{
    /// <summary>
    /// 提供站台虛擬路徑與檔案 URL 的自適應解析輔助工具
    /// 讀寫全面鎖定當前站台實體目錄 (~/Upload/)，確保測試站台與正式站台資料完全獨立隔離
    /// </summary>
    public static class PathHelper
    {
        /// <summary>
        /// 取得當前應用程式虛擬根目錄 (根站台時為空字串 ""，子站台時如 "/NTPC_FECM")
        /// </summary>
        public static string AppVirtualPath
        {
            get
            {
                string path = HttpRuntime.AppDomainAppVirtualPath;
                if (string.IsNullOrEmpty(path) || path == "/")
                {
                    return "";
                }
                return path.TrimEnd('/');
            }
        }

        /// <summary>
        /// 將圖片路徑轉換為安全穩健之串流載入 URL (透過 ViewImage.ashx 輸出，徹底避開 IIS 靜態檔案攔截與路徑缺失)
        /// </summary>
        public static string ResolveUrl(string virtualPath)
        {
            if (string.IsNullOrEmpty(virtualPath))
            {
                return "";
            }

            string clean = virtualPath.Trim().Replace('\\', '/');
            string querySuffix = "";
            int qIdx = clean.IndexOf('?');
            if (qIdx >= 0)
            {
                string rawQuery = clean.Substring(qIdx + 1).TrimStart('?', '&');
                if (!string.IsNullOrEmpty(rawQuery))
                {
                    querySuffix = "&" + rawQuery;
                }
                clean = clean.Substring(0, qIdx);
            }

            if (clean.StartsWith("~"))
            {
                clean = clean.Substring(1);
            }

            if (clean.StartsWith("/NTPC_FECM/", StringComparison.OrdinalIgnoreCase))
            {
                clean = clean.Substring(10);
            }
            else if (clean.StartsWith("/NTPC_FEC/", StringComparison.OrdinalIgnoreCase))
            {
                clean = clean.Substring(9);
            }

            clean = clean.TrimStart('/');

            // 統一透過 ViewImage.ashx 安全串流輸出，杜絕任何 IIS 靜態檔案 403 / 404 / 500.19 阻斷
            return string.Format("{0}/ViewImage.ashx?p={1}{2}", AppVirtualPath, HttpUtility.UrlEncode(clean), querySuffix);
        }

        /// <summary>
        /// 取得當前站台 Upload 目錄下之實體資料夾 (以本站台 ~/Upload 為準，獨立隔離)
        /// </summary>
        public static string FindDirectory(string virtualDir)
        {
            if (string.IsNullOrEmpty(virtualDir))
            {
                return "";
            }

            string clean = virtualDir.Trim().Replace('\\', '/');
            if (clean.StartsWith("~")) clean = clean.Substring(1);
            if (clean.StartsWith("/NTPC_FECM/", StringComparison.OrdinalIgnoreCase)) clean = clean.Substring(10);
            if (clean.StartsWith("/NTPC_FEC/", StringComparison.OrdinalIgnoreCase)) clean = clean.Substring(9);
            clean = clean.TrimStart('/');

            HttpContext ctx = HttpContext.Current;
            if (ctx != null)
            {
                string p = ctx.Server.MapPath("~/" + clean);
                if (Directory.Exists(p)) return p;
            }

            string baseDir = AppDomain.CurrentDomain.BaseDirectory;
            string localDir = Path.Combine(baseDir, clean.Replace('/', '\\'));
            if (Directory.Exists(localDir)) return localDir;

            return ctx != null
                ? ctx.Server.MapPath("~/" + clean)
                : localDir;
        }

        /// <summary>
        /// 取得當前站台 Upload 目錄下之實體檔案路徑 (以本站台 ~/Upload 為準，獨立隔離)
        /// </summary>
        public static string FindPhysicalFile(string virtualFilePath)
        {
            if (string.IsNullOrEmpty(virtualFilePath))
            {
                return null;
            }

            string clean = virtualFilePath.Trim().Replace('\\', '/');
            // 去除 URL 尾綴查詢參數 (例如 ?t=123)
            int qIdx = clean.IndexOf('?');
            if (qIdx >= 0)
            {
                clean = clean.Substring(0, qIdx);
            }

            if (clean.StartsWith("~")) clean = clean.Substring(1);
            if (clean.StartsWith("/NTPC_FECM/", StringComparison.OrdinalIgnoreCase)) clean = clean.Substring(10);
            if (clean.StartsWith("/NTPC_FEC/", StringComparison.OrdinalIgnoreCase)) clean = clean.Substring(9);
            clean = clean.TrimStart('/');

            HttpContext ctx = HttpContext.Current;
            string localPath = ctx != null
                ? ctx.Server.MapPath("~/" + clean)
                : Path.Combine(AppDomain.CurrentDomain.BaseDirectory, clean.Replace('/', '\\'));

            if (File.Exists(localPath))
            {
                return localPath;
            }

            // 容錯支援 URL 解碼後檔名比對 (防止某些瀏覽器傳送未解碼之中文字)
            string decodedClean = HttpUtility.UrlDecode(clean);
            if (decodedClean != clean)
            {
                string decodedLocal = ctx != null
                    ? ctx.Server.MapPath("~/" + decodedClean)
                    : Path.Combine(AppDomain.CurrentDomain.BaseDirectory, decodedClean.Replace('/', '\\'));
                if (File.Exists(decodedLocal))
                {
                    return decodedLocal;
                }
            }

            return localPath;
        }

        /// <summary>
        /// 將虛擬路徑轉換為伺服器實體磁碟路徑
        /// </summary>
        public static string MapPath(string virtualPath)
        {
            return FindDirectory(virtualPath);
        }
    }
}
