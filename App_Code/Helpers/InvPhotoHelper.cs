using System;
using System.Collections.Generic;
using System.IO;
using System.Web;

namespace NTPC_FEC.Helpers
{
    /// <summary>
    /// 巡查紀錄照片定位工具。
    /// INV_NO 為「每個場所各自累加」，因此絕不可跨目錄合併照片，
    /// 否則缺漏的欄位會被其他場所 / 其他次巡查 (如 2024 年) 的舊照片補上。
    /// 規則：只取「第一個存在圖檔的目錄」，不合併。
    /// </summary>
    public static class InvPhotoHelper
    {
        private static readonly string[] ImgExts = new string[] { ".jpg", ".jpeg", ".png", ".bmp", ".gif" };

        /// <summary>
        /// 取得該筆巡查專屬照片檔案清單。
        /// 1. 精準目錄 (可信)：~/Upload/PIC/{FAC_ID}/{INV_NO}、~/Upload/PIC/{C_NO}/{INV_NO}
        /// 2. 舊版目錄 (僅在精準目錄皆無圖時)：~/Upload/PIC/{INV_NO}、~/Upload/PIC/{FAC_ID} 根目錄(不含子資料夾)，
        ///    且檔案時間須落在巡查日 ±3 天內，避免誤抓其他次/其他場所照片。
        /// </summary>
        /// <param name="urlPrefix">回傳不含站台虛擬目錄的 URL 前綴，如 /Upload/PIC/123/5/</param>
        public static string[] GetPhotoFiles(string facId, int invNo, string cNo, DateTime invDate, out string urlPrefix)
        {
            urlPrefix = "";
            HttpContext ctx = HttpContext.Current;
            if (ctx == null || string.IsNullOrEmpty(facId) || invNo <= 0)
            {
                return new string[0];
            }

            string inv = invNo.ToString();

            // 1. 精準目錄
            List<string[]> exact = new List<string[]>();
            exact.Add(new string[] { "/Upload/PIC/" + facId + "/" + inv + "/" });
            if (!string.IsNullOrEmpty(cNo) && !cNo.Equals(facId, StringComparison.OrdinalIgnoreCase))
            {
                exact.Add(new string[] { "/Upload/PIC/" + cNo + "/" + inv + "/" });
            }

            foreach (string[] item in exact)
            {
                string[] files = ListImages(ctx.Server.MapPath("~" + item[0]), DateTime.MinValue);
                if (files.Length > 0)
                {
                    urlPrefix = item[0];
                    return files;
                }
            }

            // 2. 舊版目錄 (需日期護欄)
            if (invDate == DateTime.MinValue)
            {
                return new string[0];
            }

            List<string[]> legacy = new List<string[]>();
            legacy.Add(new string[] { "/Upload/PIC/" + inv + "/" });
            legacy.Add(new string[] { "/Upload/PIC/" + facId + "/" });

            foreach (string[] item in legacy)
            {
                string[] files = ListImages(ctx.Server.MapPath("~" + item[0]), invDate);
                if (files.Length > 0)
                {
                    urlPrefix = item[0];
                    return files;
                }
            }

            return new string[0];
        }

        private static string[] ListImages(string dir, DateTime invDate)
        {
            List<string> result = new List<string>();
            try
            {
                if (!Directory.Exists(dir)) return result.ToArray();

                foreach (string f in Directory.GetFiles(dir))
                {
                    string ext = Path.GetExtension(f).ToLower();
                    if (Array.IndexOf(ImgExts, ext) < 0) continue;

                    if (invDate != DateTime.MinValue)
                    {
                        DateTime t = File.GetLastWriteTime(f);
                        if (Math.Abs((t - invDate).TotalDays) > 3.0) continue;
                    }
                    result.Add(f);
                }
            }
            catch
            {
            }
            return result.ToArray();
        }
    }
}
