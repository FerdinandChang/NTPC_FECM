using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Text;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.UI;
using NPOI.HSSF.UserModel;
using NPOI.HSSF.Util;
using NPOI.SS.UserModel;
using NPOI.SS.Util;
using NTPC_FEC.Helpers;

namespace NTPC_FEC.FAC
{
    public partial class Charts : Page
    {
        private JavaScriptSerializer json;

        public Charts()
        {
            json = new JavaScriptSerializer();
            json.MaxJsonLength = int.MaxValue;
        }

        public class KpiModel
        {
            public int TotalFac { get; set; }
            public int RegFac { get; set; }
            public int TotalProcess { get; set; }
            public int TotalTowns { get; set; }

            public KpiModel()
            {
                TotalFac = 0;
                RegFac = 0;
                TotalProcess = 0;
                TotalTowns = 0;
            }
        }

        public class ChartItemModel
        {
            public string Name { get; set; }
            public int Count { get; set; }
            public double Percent { get; set; }

            public ChartItemModel()
            {
                Name = "";
                Count = 0;
                Percent = 0.0;
            }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            string action = Request["action"];
            if (!string.IsNullOrEmpty(action))
            {
                Response.Clear();
                string act = action.ToLower();
                if (act == "exportexcel")
                {
                    try
                    {
                        ExportDetailExcel();
                    }
                    catch (Exception ex)
                    {
                        Response.ContentType = "text/plain; charset=utf-8";
                        Response.Write("匯出 Excel 失敗：" + ex.Message);
                    }
                    Response.End();
                    return;
                }

                Response.ContentType = "application/json; charset=utf-8";
                try
                {
                    HandleAjaxAction(act);
                }
                catch (Exception ex)
                {
                    Response.Write(json.Serialize(new { Success = false, Message = ex.Message }));
                }
                Response.End();
                return;
            }
        }

        private void HandleAjaxAction(string action)
        {
            switch (action)
            {
                case "getkpis":
                    GetKpis();
                    break;
                case "getchartdata":
                    GetChartData();
                    break;
                case "getdetail":
                    GetDetailList();
                    break;
                case "getfacinfo":
                    GetFacInfo();
                    break;
                default:
                    Response.Write(json.Serialize(new { Success = false, Message = "未知的操作指令" }));
                    break;
            }
        }

        /// <summary>
        /// 取得頂部四大 KPI 指標數據
        /// </summary>
        private void GetKpis()
        {
            KpiModel kpi = new KpiModel();

            // 1. 公私場所總數
            string sqlTotal = "SELECT COUNT(*) FROM FAC_Main";
            object objTotal = DbHelper.ExecuteScalar(sqlTotal);
            if (objTotal != null && objTotal != DBNull.Value)
            {
                kpi.TotalFac = Convert.ToInt32(objTotal);
            }

            // 2. 列管場所數
            string sqlReg = "SELECT COUNT(*) FROM FAC_Main WHERE FAC_Type = '列管'";
            object objReg = DbHelper.ExecuteScalar(sqlReg);
            if (objReg != null && objReg != DBNull.Value)
            {
                kpi.RegFac = Convert.ToInt32(objReg);
            }

            // 3. 列管製程總數
            string sqlProc = "SELECT COUNT(DISTINCT Process_NO) FROM INV_Process_Main INNER JOIN FAC_Main ON INV_Process_Main.FAC_ID = FAC_Main.FAC_ID WHERE FAC_Main.FAC_Type = '列管'";
            object objProc = DbHelper.ExecuteScalar(sqlProc);
            if (objProc != null && objProc != DBNull.Value)
            {
                kpi.TotalProcess = Convert.ToInt32(objProc);
            }

            // 4. 涵蓋行政區數
            string sqlTown = "SELECT COUNT(DISTINCT TOWN) FROM FAC_Main WHERE FAC_Type = '列管' AND TOWN IS NOT NULL AND RTRIM(LTRIM(TOWN)) <> ''";
            object objTown = DbHelper.ExecuteScalar(sqlTown);
            if (objTown != null && objTown != DBNull.Value)
            {
                kpi.TotalTowns = Convert.ToInt32(objTown);
            }

            Response.Write(json.Serialize(new { Success = true, Data = kpi }));
        }

        /// <summary>
        /// 取得指定統計維度的圖表匯總數據
        /// </summary>
        private void GetChartData()
        {
            string dim = Request["dim"];
            if (string.IsNullOrEmpty(dim))
            {
                dim = "factype";
            }
            dim = dim.ToLower();

            string sql = "";
            switch (dim)
            {
                case "factype":
                    sql = "SELECT COUNT(*) AS pCount, ISNULL(NULLIF(RTRIM(LTRIM(FAC_Type)), ''), '無資料') AS ItemName FROM FAC_Main GROUP BY FAC_Type ORDER BY pCount DESC";
                    break;
                case "process":
                    sql = "SELECT COUNT(*) AS pCount, ISNULL(NULLIF(RTRIM(LTRIM(Process_Name)), ''), '無資料') AS ItemName FROM (SELECT DISTINCT Process_NO, Process_Name, FAC_Main.C_NO, FAC_Main.FAC_ID FROM INV_Process_Main LEFT JOIN FAC_Main ON INV_Process_Main.FAC_ID = FAC_Main.FAC_ID WHERE FAC_Main.FAC_Type = '列管') AS Taba GROUP BY Process_Name ORDER BY pCount DESC";
                    break;
                case "licyear":
                    sql = "SELECT COUNT(*) AS pCount, CASE WHEN ISNUMERIC(Lic_Year) = 1 THEN RTRIM(LTRIM(Lic_Year)) + '年' WHEN Lic_Year IS NOT NULL AND RTRIM(LTRIM(Lic_Year)) <> '' THEN RTRIM(LTRIM(Lic_Year)) ELSE '未知' END AS ItemName, CASE WHEN ISNUMERIC(Lic_Year) = 1 THEN CAST(Lic_Year AS INT) ELSE 0 END AS SortYear FROM (SELECT DISTINCT Process_NO, Lic_Year, FAC_Main.C_NO, FAC_Main.FAC_ID FROM INV_Process_Main LEFT JOIN FAC_Main ON INV_Process_Main.FAC_ID = FAC_Main.FAC_ID WHERE FAC_Main.FAC_Type = '列管') AS Taba GROUP BY Lic_Year ORDER BY SortYear DESC";
                    break;
                case "town":
                    sql = "SELECT COUNT(*) AS pCount, ISNULL(NULLIF(RTRIM(LTRIM(TOWN)), ''), '無資料') AS ItemName FROM FAC_Main WHERE FAC_Type = '列管' GROUP BY TOWN ORDER BY pCount DESC";
                    break;
                case "industrial":
                    sql = "SELECT COUNT(*) AS pCount, ISNULL(NULLIF(RTRIM(LTRIM(INDUSTRIAL_Name)), ''), '無資料') AS ItemName FROM FAC_Main LEFT JOIN INDUSTRIAL_Data ON INDUSTRIAL_Code1 = INDUSTRIAL_Code WHERE FAC_Type = '列管' GROUP BY INDUSTRIAL_Name ORDER BY pCount DESC";
                    break;
                case "group":
                    sql = "SELECT COUNT(*) AS pCount, ISNULL(NULLIF(RTRIM(LTRIM(FAC_Group)), ''), '無資料') AS ItemName FROM FAC_Main WHERE FAC_Type = '列管' GROUP BY FAC_Group ORDER BY pCount DESC";
                    break;
                default:
                    Response.Write(json.Serialize(new { Success = false, Message = "未知的統計維度" }));
                    return;
            }

            DataTable dt = DbHelper.ExecuteDataTable(sql);
            List<ChartItemModel> items = new List<ChartItemModel>();
            int grandTotal = 0;

            foreach (DataRow row in dt.Rows)
            {
                int cnt = Convert.ToInt32(row["pCount"]);
                grandTotal += cnt;
            }

            foreach (DataRow row in dt.Rows)
            {
                ChartItemModel item = new ChartItemModel();
                item.Name = row["ItemName"].ToString();
                item.Count = Convert.ToInt32(row["pCount"]);
                if (grandTotal > 0)
                {
                    item.Percent = Math.Round((double)item.Count * 100.0 / grandTotal, 1);
                }
                items.Add(item);
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                Dimension = dim,
                TotalCount = grandTotal,
                Data = items
            }));
        }

        /// <summary>
        /// 取得下鑽明細公私場所清單
        /// </summary>
        private void GetDetailList()
        {
            string dim = Request["dim"];
            if (string.IsNullOrEmpty(dim)) dim = "factype";
            dim = dim.ToLower();

            string filter = Request["filter"];
            if (filter == null) filter = "ALL";
            filter = filter.Trim();

            DataTable dt = FetchDetailDataTable(dim, filter);

            List<Dictionary<string, object>> list = new List<Dictionary<string, object>>();
            foreach (DataRow row in dt.Rows)
            {
                Dictionary<string, object> dict = new Dictionary<string, object>();
                foreach (DataColumn col in dt.Columns)
                {
                    dict[col.ColumnName] = row[col] == DBNull.Value ? "" : row[col].ToString();
                }
                list.Add(dict);
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                Dimension = dim,
                Filter = filter,
                Total = list.Count,
                Data = list
            }));
        }

        /// <summary>
        /// 取得單一公私場所完整詳細資訊 (供彈窗檢視)
        /// </summary>
        private void GetFacInfo()
        {
            string facId = Request["facid"];
            if (string.IsNullOrEmpty(facId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "缺少公私場所代碼" }));
                return;
            }

            string sqlFac = "SELECT TOP 1 F.*, ISNULL(I.INDUSTRIAL_Name, '') AS IndustryName " +
                            "FROM FAC_Main F " +
                            "LEFT JOIN INDUSTRIAL_Data I ON F.INDUSTRIAL_Code1 = I.INDUSTRIAL_Code " +
                            "WHERE F.FAC_ID = @FAC_ID";

            SqlParameter[] pFac = new SqlParameter[]
            {
                new SqlParameter("@FAC_ID", facId)
            };
            DataTable dtFac = DbHelper.ExecuteDataTable(sqlFac, pFac);
            if (dtFac.Rows.Count == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "查無該公私場所資料" }));
                return;
            }

            DataRow r = dtFac.Rows[0];
            Dictionary<string, object> facInfo = new Dictionary<string, object>();
            foreach (DataColumn col in dtFac.Columns)
            {
                facInfo[col.ColumnName] = r[col] == DBNull.Value ? "" : r[col].ToString();
            }

            // 查詢製程清單
            string sqlProc = "SELECT DISTINCT Process_NO, Process_Code, Process_Name, Process_Type, Process_Lic, Lic_Year " +
                             "FROM INV_Process_Main " +
                             "WHERE FAC_ID = @FAC_ID " +
                             "ORDER BY Process_NO";
            SqlParameter[] pProc = new SqlParameter[]
            {
                new SqlParameter("@FAC_ID", facId)
            };
            DataTable dtProc = DbHelper.ExecuteDataTable(sqlProc, pProc);
            List<Dictionary<string, object>> procList = new List<Dictionary<string, object>>();
            foreach (DataRow pr in dtProc.Rows)
            {
                Dictionary<string, object> pDict = new Dictionary<string, object>();
                foreach (DataColumn col in dtProc.Columns)
                {
                    pDict[col.ColumnName] = pr[col] == DBNull.Value ? "" : pr[col].ToString();
                }
                procList.Add(pDict);
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                Fac = facInfo,
                Processes = procList
            }));
        }

        /// <summary>
        /// 核心資料庫查詢邏輯：依維度與篩選值提取明細清單 DataTable
        /// </summary>
        private DataTable FetchDetailDataTable(string dim, string filter)
        {
            string sql = "";
            List<SqlParameter> paramList = new List<SqlParameter>();

            if (dim == "factype")
            {
                sql = "SELECT FAC_ID, C_NO AS 管制編號, FAC_NAME AS 場所名稱, TOWN AS 行政區, ADDR AS 地址, FAC_TYPE AS 列管狀況, FAC_Group AS 分級組別 " +
                      "FROM FAC_Main ";
                if (filter != "ALL")
                {
                    if (filter == "無資料")
                    {
                        sql += "WHERE (FAC_TYPE = '' OR FAC_TYPE IS NULL) ";
                    }
                    else
                    {
                        sql += "WHERE FAC_TYPE = @Filter ";
                        paramList.Add(new SqlParameter("@Filter", filter));
                    }
                }
                sql += "ORDER BY C_NO";
            }
            else if (dim == "process")
            {
                sql = "SELECT DISTINCT Taba.C_NO AS 管制編號, Taba.FAC_NAME AS 場所名稱, Taba.TOWN AS 行政區, Taba.Process_NO AS 製程編號, " +
                      "Taba.Process_Name AS 製程名稱, Taba.Lic_Year AS 核發年度, Taba.Process_Lic AS 許可證號, Taba.FAC_ID " +
                      "FROM ( " +
                      "  SELECT P.Process_NO, P.Process_Code, P.Process_Name, P.Process_Type, P.Process_Lic, P.Lic_Year, " +
                      "         F.C_NO, F.FAC_ID, F.FAC_NAME, F.TOWN " +
                      "  FROM INV_Process_Main P " +
                      "  LEFT JOIN FAC_Main F ON P.FAC_ID = F.FAC_ID " +
                      "  WHERE F.FAC_TYPE = '列管' " +
                      ") AS Taba ";
                if (filter != "ALL")
                {
                    if (filter == "無資料")
                    {
                        sql += "WHERE (Taba.Process_Name = '' OR Taba.Process_Name IS NULL) ";
                    }
                    else
                    {
                        sql += "WHERE Taba.Process_Name = @Filter ";
                        paramList.Add(new SqlParameter("@Filter", filter));
                    }
                }
                sql += "ORDER BY Taba.C_NO, Taba.Process_NO";
            }
            else if (dim == "licyear")
            {
                string rawYear = filter.Replace("年", "").Trim();
                sql = "SELECT DISTINCT Taba.C_NO AS 管制編號, Taba.FAC_NAME AS 場所名稱, Taba.TOWN AS 行政區, Taba.Process_NO AS 製程編號, " +
                      "Taba.Process_Name AS 製程名稱, Taba.Lic_Year AS 核發年度, Taba.Process_Lic AS 許可證號, Taba.FAC_ID " +
                      "FROM ( " +
                      "  SELECT P.Process_NO, P.Process_Code, P.Process_Name, P.Process_Type, P.Process_Lic, P.Lic_Year, " +
                      "         F.C_NO, F.FAC_ID, F.FAC_NAME, F.TOWN " +
                      "  FROM INV_Process_Main P " +
                      "  LEFT JOIN FAC_Main F ON P.FAC_ID = F.FAC_ID " +
                      "  WHERE F.FAC_TYPE = '列管' " +
                      ") AS Taba ";
                if (filter != "ALL")
                {
                    if (filter == "未知")
                    {
                        sql += "WHERE (Taba.Lic_Year = '' OR Taba.Lic_Year IS NULL) ";
                    }
                    else
                    {
                        sql += "WHERE (Taba.Lic_Year = @RawYear OR Taba.Lic_Year = @Filter) ";
                        paramList.Add(new SqlParameter("@RawYear", rawYear));
                        paramList.Add(new SqlParameter("@Filter", filter));
                    }
                }
                sql += "ORDER BY Taba.C_NO, Taba.Process_NO";
            }
            else if (dim == "town")
            {
                sql = "SELECT FAC_ID, C_NO AS 管制編號, FAC_NAME AS 場所名稱, TOWN AS 行政區, ADDR AS 地址, FAC_Group AS 分級組別 " +
                      "FROM FAC_Main " +
                      "WHERE FAC_TYPE = '列管' ";
                if (filter != "ALL")
                {
                    if (filter == "無資料")
                    {
                        sql += "AND (TOWN = '' OR TOWN IS NULL) ";
                    }
                    else
                    {
                        sql += "AND TOWN = @Filter ";
                        paramList.Add(new SqlParameter("@Filter", filter));
                    }
                }
                sql += "ORDER BY C_NO";
            }
            else if (dim == "industrial")
            {
                sql = "SELECT F.FAC_ID, F.C_NO AS 管制編號, F.FAC_NAME AS 場所名稱, F.TOWN AS 行政區, " +
                      "ISNULL(I.INDUSTRIAL_Name, '無資料') AS 行業別, F.INDUSTRIAL_Code1 AS 行業代碼, F.ADDR AS 地址 " +
                      "FROM FAC_Main F " +
                      "LEFT JOIN INDUSTRIAL_Data I ON F.INDUSTRIAL_Code1 = I.INDUSTRIAL_Code " +
                      "WHERE F.FAC_TYPE = '列管' ";
                if (filter != "ALL")
                {
                    if (filter == "無資料")
                    {
                        sql += "AND (I.INDUSTRIAL_Name = '' OR I.INDUSTRIAL_Name IS NULL) ";
                    }
                    else
                    {
                        sql += "AND I.INDUSTRIAL_Name = @Filter ";
                        paramList.Add(new SqlParameter("@Filter", filter));
                    }
                }
                sql += "ORDER BY F.C_NO";
            }
            else if (dim == "group")
            {
                sql = "SELECT FAC_ID, C_NO AS 管制編號, FAC_NAME AS 場所名稱, TOWN AS 行政區, FAC_Group AS 分級組別, ADDR AS 地址 " +
                      "FROM FAC_Main " +
                      "WHERE FAC_TYPE = '列管' ";
                if (filter != "ALL")
                {
                    if (filter == "無資料")
                    {
                        sql += "AND (FAC_Group = '' OR FAC_Group IS NULL) ";
                    }
                    else
                    {
                        sql += "AND FAC_Group = @Filter ";
                        paramList.Add(new SqlParameter("@Filter", filter));
                    }
                }
                sql += "ORDER BY C_NO";
            }

            return DbHelper.ExecuteDataTable(sql, paramList.ToArray());
        }

        /// <summary>
        /// 匯出明細清單為 Excel 檔案
        /// </summary>
        private void ExportDetailExcel()
        {
            string dim = Request["dim"];
            if (string.IsNullOrEmpty(dim)) dim = "factype";
            dim = dim.ToLower();

            string filter = Request["filter"];
            if (filter == null) filter = "ALL";
            filter = filter.Trim();

            DataTable dt = FetchDetailDataTable(dim, filter);

            string dimTitle = GetDimTitle(dim);
            string sheetName = dimTitle + "明細清單";

            HSSFWorkbook wb = new HSSFWorkbook();
            HSSFPalette palette = wb.GetCustomPalette();
            palette.SetColorAtIndex(HSSFColor.RoyalBlue.Index, 0, 153, 229); // #0099e5

            ISheet sheet = wb.CreateSheet(sheetName);

            // 標題樣式
            ICellStyle titleStyle = wb.CreateCellStyle();
            IFont titleFont = wb.CreateFont();
            titleFont.FontName = "微軟正黑體";
            titleFont.FontHeightInPoints = 14;
            titleFont.IsBold = true;
            titleFont.Color = HSSFColor.White.Index;
            titleStyle.SetFont(titleFont);
            titleStyle.FillForegroundColor = HSSFColor.RoyalBlue.Index;
            titleStyle.FillPattern = FillPattern.SolidForeground;
            titleStyle.Alignment = HorizontalAlignment.Center;
            titleStyle.VerticalAlignment = VerticalAlignment.Center;

            // 表頭樣式
            ICellStyle headerStyle = wb.CreateCellStyle();
            IFont headerFont = wb.CreateFont();
            headerFont.FontName = "微軟正黑體";
            headerFont.FontHeightInPoints = 10;
            headerFont.IsBold = true;
            headerStyle.SetFont(headerFont);
            headerStyle.FillForegroundColor = HSSFColor.Grey25Percent.Index;
            headerStyle.FillPattern = FillPattern.SolidForeground;
            headerStyle.Alignment = HorizontalAlignment.Center;
            headerStyle.VerticalAlignment = VerticalAlignment.Center;
            headerStyle.BorderBottom = BorderStyle.Thin;
            headerStyle.BorderTop = BorderStyle.Thin;
            headerStyle.BorderLeft = BorderStyle.Thin;
            headerStyle.BorderRight = BorderStyle.Thin;

            // 資料單元格樣式
            ICellStyle dataStyle = wb.CreateCellStyle();
            IFont dataFont = wb.CreateFont();
            dataFont.FontName = "微軟正黑體";
            dataFont.FontHeightInPoints = 10;
            dataStyle.SetFont(dataFont);
            dataStyle.VerticalAlignment = VerticalAlignment.Center;
            dataStyle.BorderBottom = BorderStyle.Thin;
            dataStyle.BorderTop = BorderStyle.Thin;
            dataStyle.BorderLeft = BorderStyle.Thin;
            dataStyle.BorderRight = BorderStyle.Thin;

            // 1. 建立報表主標題列
            List<DataColumn> exportCols = new List<DataColumn>();
            foreach (DataColumn c in dt.Columns)
            {
                if (c.ColumnName.ToUpper() != "FAC_ID")
                {
                    exportCols.Add(c);
                }
            }

            IRow titleRow = sheet.CreateRow(0);
            titleRow.HeightInPoints = 32;
            ICell titleCell = titleRow.CreateCell(0);
            string filterText = filter == "ALL" ? "全部" : filter;
            titleCell.SetCellValue(string.Format("新北市固定溢散源統計 - {0}（篩選條件：{1}，共 {2} 筆）", dimTitle, filterText, dt.Rows.Count));
            titleCell.CellStyle = titleStyle;

            if (exportCols.Count > 1)
            {
                sheet.AddMergedRegion(new CellRangeAddress(0, 0, 0, exportCols.Count - 1));
            }

            // 2. 建立表頭列
            IRow headerRow = sheet.CreateRow(1);
            headerRow.HeightInPoints = 24;
            for (int i = 0; i < exportCols.Count; i++)
            {
                ICell c = headerRow.CreateCell(i);
                c.SetCellValue(exportCols[i].ColumnName);
                c.CellStyle = headerStyle;
            }

            // 3. 填入資料列
            int rowIndex = 2;
            foreach (DataRow dr in dt.Rows)
            {
                IRow row = sheet.CreateRow(rowIndex);
                row.HeightInPoints = 20;
                for (int i = 0; i < exportCols.Count; i++)
                {
                    ICell cell = row.CreateCell(i);
                    cell.SetCellValue(dr[exportCols[i]] == DBNull.Value ? "" : dr[exportCols[i]].ToString());
                    cell.CellStyle = dataStyle;
                }
                rowIndex++;
            }

            // 自動欄寬
            for (int i = 0; i < exportCols.Count; i++)
            {
                sheet.AutoSizeColumn(i);
                int currentWidth = sheet.GetColumnWidth(i);
                if (currentWidth < 3000)
                {
                    sheet.SetColumnWidth(i, 3500);
                }
                else if (currentWidth > 18000)
                {
                    sheet.SetColumnWidth(i, 18000);
                }
            }

            string fileName = string.Format("工廠統計_{0}_{1}_{2}.xls", dimTitle, filterText, DateTime.Now.ToString("yyyyMMdd_HHmmss"));
            string encodedFileName = HttpUtility.UrlEncode(fileName, Encoding.UTF8);

            Response.Clear();
            Response.Buffer = true;
            Response.Charset = "utf-8";
            Response.ContentType = "application/vnd.ms-excel";
            Response.AddHeader("Content-Disposition", "attachment;filename=" + encodedFileName + ";filename*=UTF-8''" + encodedFileName);

            using (MemoryStream ms = new MemoryStream())
            {
                wb.Write(ms);
                byte[] bytes = ms.ToArray();
                Response.BinaryWrite(bytes);
            }
        }

        private string GetDimTitle(string dim)
        {
            switch (dim)
            {
                case "factype": return "列管狀況";
                case "process": return "製程名稱";
                case "licyear": return "核發年度";
                case "town": return "行政區分佈";
                case "industrial": return "行業別";
                case "group": return "分級組別";
                default: return "公私場所統計";
            }
        }
    }
}
