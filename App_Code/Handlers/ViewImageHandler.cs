using System;
using System.Collections.Generic;
using System.IO;
using System.Web;
using NTPC_FEC.Helpers;

namespace NTPC_FEC.Handlers
{
    /// <summary>
    /// 安全圖片串流輸出處理常式
    /// 具備路徑沙箱隔離與副檔名嚴格白名單，讀寫全面鎖定當前站台實體目錄 (~/Upload/, ~/images/)，徹底避開 IIS 靜態檔案攔截與未授權系統檔案洩漏
    /// </summary>
    public class ViewImageHandler : IHttpHandler
    {
        private static readonly HashSet<string> AllowedExtensions = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            ".jpg", ".jpeg", ".png", ".gif", ".webp", ".bmp", ".pdf"
        };

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

            // 1. 安全防禦：防止目錄遍歷 (Path Traversal) 與 Null Byte 注入
            rawPath = HttpUtility.UrlDecode(rawPath).Replace('\\', '/').Trim();
            int qIdx = rawPath.IndexOf('?');
            if (qIdx >= 0)
            {
                rawPath = rawPath.Substring(0, qIdx).Trim();
            }
            if (rawPath.IndexOf('\0') >= 0 || rawPath.Contains(".."))
            {
                response.StatusCode = 403;
                response.ContentType = "text/plain; charset=utf-8";
                response.Write("路徑無效 (禁止穿越目錄)");
                return;
            }

            // 2. 副檔名白名單強制驗證 (嚴防讀取 Web.config, dll, cs 等敏感檔案)
            string rawExt = Path.GetExtension(rawPath);
            if (string.IsNullOrEmpty(rawExt) || !AllowedExtensions.Contains(rawExt))
            {
                response.StatusCode = 403;
                response.ContentType = "text/plain; charset=utf-8";
                response.Write("禁止讀取非允許之檔案格式");
                return;
            }

            // 3. 尋找實體檔案路徑
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

            // 4. 沙箱邊界驗證 (必須嚴格落在 Upload, images, Content 目錄之下)
            try
            {
                string fullTarget = Path.GetFullPath(physicalFile);
                string uploadRoot = Path.GetFullPath(context.Server.MapPath("~/Upload/"));
                string imagesRoot = Path.GetFullPath(context.Server.MapPath("~/images/"));
                string contentRoot = Path.GetFullPath(context.Server.MapPath("~/Content/"));

                bool inSandbox = fullTarget.StartsWith(uploadRoot, StringComparison.OrdinalIgnoreCase) ||
                                 fullTarget.StartsWith(imagesRoot, StringComparison.OrdinalIgnoreCase) ||
                                 fullTarget.StartsWith(contentRoot, StringComparison.OrdinalIgnoreCase);

                if (!inSandbox)
                {
                    response.StatusCode = 403;
                    response.ContentType = "text/plain; charset=utf-8";
                    response.Write("存取受限 (檔案超出允許之公開目錄邊界)");
                    return;
                }
            }
            catch
            {
                response.StatusCode = 403;
                response.ContentType = "text/plain; charset=utf-8";
                response.Write("路徑解析異常");
                return;
            }

            // 5. 取得副檔名並給予正確 MIME 標頭
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
