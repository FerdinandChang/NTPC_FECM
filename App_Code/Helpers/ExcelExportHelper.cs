using System;
using System.IO;
using System.Text;
using System.Web;
using NPOI.SS.UserModel;

namespace NTPC_FEC.Helpers
{
    /// <summary>
    /// 安全 Excel 匯出輔助類別 (杜絕 ThreadAbortException，原生支援 RFC 5987 檔名規範與 DDE 公式注入防禦)
    /// 相容 C# 5.0 規範
    /// </summary>
    public static class ExcelExportHelper
    {
        /// <summary>
        /// 將 NPOI 工作簿安全輸出至 HTTP 回應並關閉串流 (自動防禦 CSV / DDE 公式注入)
        /// </summary>
        public static void ExportToResponse(IWorkbook workbook, string fileName, HttpResponse response)
        {
            if (workbook == null || response == null) return;

            // 1. 安全 DDE / CSV 公式注入消毒防護
            SanitizeWorkbook(workbook);

            string safeFileName = string.IsNullOrEmpty(fileName) 
                ? string.Format("Export_{0:yyyyMMdd_HHmmss}.xls", DateTime.Now) 
                : fileName;

            if (!safeFileName.EndsWith(".xls", StringComparison.OrdinalIgnoreCase) && 
                !safeFileName.EndsWith(".xlsx", StringComparison.OrdinalIgnoreCase))
            {
                safeFileName += ".xls";
            }

            using (MemoryStream ms = new MemoryStream())
            {
                workbook.Write(ms);
                byte[] bytes = ms.ToArray();

                response.Clear();
                response.ClearHeaders();
                response.Buffer = true;

                if (safeFileName.EndsWith(".xlsx", StringComparison.OrdinalIgnoreCase))
                {
                    response.ContentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
                }
                else
                {
                    response.ContentType = "application/vnd.ms-excel";
                }

                // 支援多編碼檔名 Content-Disposition (兼顧 iOS/Safari、Edge、Chrome 與傳統 IE)
                string rawEncoded = HttpUtility.UrlEncode(safeFileName, Encoding.UTF8).Replace("+", "%20");
                response.AddHeader("Content-Disposition", string.Format("attachment; filename=\"{0}\"; filename*=UTF-8''{0}", rawEncoded));
                response.AddHeader("Content-Length", bytes.Length.ToString());

                response.BinaryWrite(bytes);
                response.Flush();
                response.SuppressContent = true;

                if (HttpContext.Current != null)
                {
                    HttpContext.Current.ApplicationInstance.CompleteRequest();
                }
            }
        }

        /// <summary>
        /// 深度公式注入防禦：在匯出前自動掃描並消毒所有單元格字串，阻絕 DDE 惡意公式執行 (OWASP 漏洞防禦)
        /// </summary>
        public static void SanitizeWorkbook(IWorkbook workbook)
        {
            if (workbook == null) return;

            for (int i = 0; i < workbook.NumberOfSheets; i++)
            {
                ISheet sheet = workbook.GetSheetAt(i);
                if (sheet == null) continue;

                for (int r = sheet.FirstRowNum; r <= sheet.LastRowNum; r++)
                {
                    IRow row = sheet.GetRow(r);
                    if (row == null) continue;

                    for (int c = row.FirstCellNum; c < row.LastCellNum; c++)
                    {
                        if (c < 0) continue;
                        ICell cell = row.GetCell(c);
                        if (cell != null && cell.CellType == CellType.String)
                        {
                            string val = cell.StringCellValue;
                            if (IsFormulaInjectionRisk(val))
                            {
                                cell.SetCellValue("'" + val);
                            }
                        }
                    }
                }
            }
        }

        /// <summary>
        /// 判斷字串是否具有 Excel / CSV 公式注入風險 (=, +, -, @, \t, \r)
        /// </summary>
        public static bool IsFormulaInjectionRisk(string val)
        {
            if (string.IsNullOrEmpty(val)) return false;
            string trimmed = val.TrimStart();
            if (trimmed.Length == 0) return false;

            char first = trimmed[0];
            return first == '=' || first == '+' || first == '-' || first == '@' || first == '\t' || first == '\r';
        }
    }
}
