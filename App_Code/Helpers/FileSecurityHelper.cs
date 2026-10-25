using System;
using System.IO;
using System.Text.RegularExpressions;

namespace NTPC_FEC.Helpers
{
    /// <summary>
    /// 檔案處理與路徑安全性輔助類別 (杜絕 Path Traversal 與任意檔案上傳)
    /// 相容 C# 5.0 規範
    /// </summary>
    public static class FileSecurityHelper
    {
        private static readonly char[] InvalidFileNameChars = Path.GetInvalidFileNameChars();

        /// <summary>
        /// 檔名消毒：去除目錄結構 (如 ../ 或 ..\) 及無效字元，僅保留乾淨檔名
        /// </summary>
        public static string SanitizeFileName(string fileName)
        {
            if (string.IsNullOrEmpty(fileName))
            {
                return string.Empty;
            }

            // 1. 去除完整路徑只取檔名
            string clean = Path.GetFileName(fileName);

            // 2. 移除所有無效字元
            for (int i = 0; i < InvalidFileNameChars.Length; i++)
            {
                clean = clean.Replace(InvalidFileNameChars[i].ToString(), string.Empty);
            }

            // 3. 移除多重點與斜線組合
            clean = clean.Replace("..", string.Empty)
                         .Replace("/", string.Empty)
                         .Replace("\\", string.Empty);

            return clean.Trim();
        }

        /// <summary>
        /// 嚴格副檔名檢核 (精準比對，防止包含子字串誤判)
        /// </summary>
        public static bool IsAllowedExtension(string fileName, string[] allowedExtensions)
        {
            if (string.IsNullOrEmpty(fileName) || allowedExtensions == null || allowedExtensions.Length == 0)
            {
                return false;
            }

            string ext = Path.GetExtension(fileName);
            if (string.IsNullOrEmpty(ext))
            {
                return false;
            }

            for (int i = 0; i < allowedExtensions.Length; i++)
            {
                string allowed = allowedExtensions[i];
                if (!string.IsNullOrEmpty(allowed))
                {
                    if (!allowed.StartsWith("."))
                    {
                        allowed = "." + allowed;
                    }
                    if (string.Equals(ext, allowed, StringComparison.OrdinalIgnoreCase))
                    {
                        return true;
                    }
                }
            }

            return false;
        }

        /// <summary>
        /// 目錄邊界防禦：校驗目標檔案之完整路徑是否合法位於指定安全基準目錄之內 (杜絕 Path Traversal)
        /// </summary>
        public static bool IsSafePath(string baseDirectory, string targetFilePath)
        {
            if (string.IsNullOrEmpty(baseDirectory) || string.IsNullOrEmpty(targetFilePath))
            {
                return false;
            }

            try
            {
                string fullBaseDir = Path.GetFullPath(baseDirectory);
                if (!fullBaseDir.EndsWith(Path.DirectorySeparatorChar.ToString()))
                {
                    fullBaseDir += Path.DirectorySeparatorChar;
                }

                string fullTarget = Path.GetFullPath(targetFilePath);
                return fullTarget.StartsWith(fullBaseDir, StringComparison.OrdinalIgnoreCase);
            }
            catch
            {
                return false;
            }
        }

        /// <summary>
        /// 檢查檔案頭部 Magic Bytes 是否符合安全檔案格式 (防止惡意指令檔偽裝副檔名)
        /// </summary>
        public static bool HasValidMagicBytes(byte[] headerBytes, string extension)
        {
            if (headerBytes == null || headerBytes.Length < 4 || string.IsNullOrEmpty(extension))
            {
                return false;
            }

            string ext = extension.ToLower().TrimStart('.');

            // JPEG: FF D8 FF
            if (ext == "jpg" || ext == "jpeg")
            {
                return headerBytes.Length >= 3 && headerBytes[0] == 0xFF && headerBytes[1] == 0xD8 && headerBytes[2] == 0xFF;
            }

            // PNG: 89 50 4E 47
            if (ext == "png")
            {
                return headerBytes.Length >= 4 && headerBytes[0] == 0x89 && headerBytes[1] == 0x50 && headerBytes[2] == 0x4E && headerBytes[3] == 0x47;
            }

            // PDF: 25 50 44 46 (%PDF)
            if (ext == "pdf")
            {
                return headerBytes.Length >= 4 && headerBytes[0] == 0x25 && headerBytes[1] == 0x50 && headerBytes[2] == 0x44 && headerBytes[3] == 0x46;
            }

            // ZIP / Office OpenXML (.docx, .xlsx): 50 4B 03 04 (PK..)
            if (ext == "zip" || ext == "docx" || ext == "xlsx")
            {
                return headerBytes.Length >= 4 && headerBytes[0] == 0x50 && headerBytes[1] == 0x4B && headerBytes[2] == 0x03 && headerBytes[3] == 0x04;
            }

            // 若為其他未定義格式，則預設通過副檔名檢核
            return true;
        }
    }
}
