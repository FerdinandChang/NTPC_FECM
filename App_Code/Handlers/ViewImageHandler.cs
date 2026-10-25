using System;
using System.IO;
using System.Web;
using NTPC_FEC.Helpers;

namespace NTPC_FEC.Handlers
{
    /// <summary>
    /// 安全圖片串流輸出處理常式
    /// 讀寫全面鎖定當前站台實體目錄 (~/Upload/)，徹底避開 IIS 靜態檔案攔截 (403, 404.11, 500.19)
    /// </summary>
    public class ViewImageHandler : IHttpHandler
    {
        public bool IsReusable
        {
            get { return true; }
        }

        public void ProcessRequest(HttpContext context)
        {
            if (context == null || context.Response == null || context.Request == null) return;

            HttpResponse response = context.Response;
            HttpRequest request = context.Request;

            string rawPath = request["p"];
            if (string.IsNullOrEmpty(rawPath))
            {
                rawPath = request["path"];
            }
            if (string.IsNullOrEmpty(rawPath))
            {
                rawPath = request["file"];
            }

            if (string.IsNullOrEmpty(rawPath))
            {
                response.StatusCode = 400;
                response.ContentType = "text/plain; charset=utf-8";
                response.Write("缺少圖片路徑參數");
                return;
            }

            // 安全防禦：防止目錄遍歷 (Path Traversal)
            rawPath = HttpUtility.UrlDecode(rawPath).Replace('\\', '/').Trim();
            if (rawPath.Contains(".."))
            {
                response.StatusCode = 403;
                response.ContentType = "text/plain; charset=utf-8";
                response.Write("路徑無效 (禁止穿越目錄)");
                return;
            }

            // 尋找實體檔案路徑 (直接對準本站台 ~/Upload 目錄)
            string physicalFile = PathHelper.FindPhysicalFile(rawPath);
            if (string.IsNullOrEmpty(physicalFile) || !File.Exists(physicalFile))
            {
                // 回傳預設無照片圖示
                string noPhoto = context.Server.MapPath("~/images/nophoto.jpg");
                if (File.Exists(noPhoto))
                {
                    response.ContentType = "image/jpeg";
                    response.TransmitFile(noPhoto);
                }
                else
                {
                    response.StatusCode = 404;
                    response.ContentType = "text/plain; charset=utf-8";
                    response.Write("找不到對應之圖片檔案");
                }
                return;
            }

            // 取得副檔名並給予正確 MIME 標頭
            string ext = Path.GetExtension(physicalFile).ToLower();
            string mime = "image/jpeg";
            switch (ext)
            {
                case ".png": mime = "image/png"; break;
                case ".gif": mime = "image/gif"; break;
                case ".webp": mime = "image/webp"; break;
                case ".bmp": mime = "image/bmp"; break;
                case ".pdf": mime = "application/pdf"; break;
                default: mime = "image/jpeg"; break;
            }

            response.ContentType = mime;
            response.BufferOutput = false;

            // 啟用用戶端快取 7 天
            response.Cache.SetCacheability(HttpCacheability.Public);
            response.Cache.SetMaxAge(TimeSpan.FromDays(7));
            response.Cache.SetLastModified(File.GetLastWriteTime(physicalFile));

            response.TransmitFile(physicalFile);
        }
    }
}
