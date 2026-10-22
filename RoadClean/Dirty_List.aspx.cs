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

namespace NTPC_FEC.RoadClean
{
    public partial class Dirty_List : Page
    {
        private JavaScriptSerializer json;

        public Dirty_List()
        {
            json = new JavaScriptSerializer();
            json.MaxJsonLength = int.MaxValue;
        }

        public class SearchFilterModel
        {
            public string Mode { get; set; }           // 'DirtyEdit', 'DirtyImprove', 'Finish', 'All'
            public string ShowId { get; set; }
            public List<string> Kinds { get; set; }
            public List<string> Units { get; set; }
            public string ReportDateS { get; set; }
            public string ReportDateE { get; set; }
            public string SetComDateS { get; set; }
            public string SetComDateE { get; set; }
            public string ImproveDateS { get; set; }
            public string ImproveDateE { get; set; }
            public int PageIndex { get; set; }
            public int PageSize { get; set; }

            public SearchFilterModel()
            {
                Kinds = new List<string>();
                Units = new List<string>();
                PageIndex = 1;
                PageSize = 20;
            }
        }

        public class ActionIdModel
        {
            public string DirtyId { get; set; }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            string action = Request["action"];
            if (!string.IsNullOrEmpty(action))
            {
                if (string.Equals(action, "export", StringComparison.OrdinalIgnoreCase) ||
                    string.Equals(action, "exportexcel", StringComparison.OrdinalIgnoreCase))
                {
                    try
                    {
                        ExportExcel();
                    }
                    catch (System.Threading.ThreadAbortException)
                    {
                        // Response.End() 正常中止，不拋出錯誤
                    }
                    catch (Exception ex)
                    {
                        Response.ContentType = "text/html; charset=utf-8";
                        Response.Write("<script>alert('匯出 Excel 失敗：" + HttpUtility.JavaScriptStringEncode(ex.Message) + "'); window.close();</script>");
                    }
                    return;
                }

                Response.Clear();
                Response.ContentType = "application/json; charset=utf-8";
                try
                {
                    HandleAjaxAction(action);
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
            switch (action.ToLower())
            {
                case "getcounts":
                    GetCounts();
                    break;
                case "getunits":
                    GetUnits();
                    break;
                case "getlist":
                    GetList();
                    break;
                case "getcasepreview":
                    GetCasePreview(Request["id"]);
                    break;
                case "delete":
                    DeleteCase();
                    break;
                default:
                    Response.Write(json.Serialize(new { Success = false, Message = "未知的操作指令" }));
                    break;
            }
        }

        // 1. 取得各案件狀態統計數量
        private void GetCounts()
        {
            string sql = @"
                SELECT 
                    SUM(CASE WHEN SetCOM_Date IS NULL THEN 1 ELSE 0 END) AS EditCount,
                    SUM(CASE WHEN SetCOM_Date IS NOT NULL AND Improve_Date IS NULL THEN 1 ELSE 0 END) AS ImproveCount,
                    SUM(CASE WHEN SetCOM_Date IS NOT NULL AND Improve_Date IS NOT NULL THEN 1 ELSE 0 END) AS FinishCount,
                    COUNT(*) AS TotalCount
                FROM RoadDirty_CaseMain";

            DataTable dt = DbHelper.ExecuteDataTable(sql);
            int editCount = 0;
            int improveCount = 0;
            int finishCount = 0;
            int totalCount = 0;

            if (dt.Rows.Count > 0)
            {
                DataRow r = dt.Rows[0];
                if (r["EditCount"] != DBNull.Value) editCount = Convert.ToInt32(r["EditCount"]);
                if (r["ImproveCount"] != DBNull.Value) improveCount = Convert.ToInt32(r["ImproveCount"]);
                if (r["FinishCount"] != DBNull.Value) finishCount = Convert.ToInt32(r["FinishCount"]);
                if (r["TotalCount"] != DBNull.Value) totalCount = Convert.ToInt32(r["TotalCount"]);
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                Data = new
                {
                    EditCount = editCount,
                    ImproveCount = improveCount,
                    FinishCount = finishCount,
                    TotalCount = totalCount
                }
            }));
        }

        // 2. 取得處理單位清單 (RoadDirty_Unit)
        private void GetUnits()
        {
            string sql = "SELECT UnitID, UnitName FROM RoadDirty_Unit WHERE pType = '處理單位' ORDER BY UnitID";
            DataTable dt = DbHelper.ExecuteDataTable(sql);
            List<object> list = new List<object>();
            foreach (DataRow row in dt.Rows)
            {
                list.Add(new
                {
                    UnitId = row["UnitID"].ToString().Trim(),
                    UnitName = row["UnitName"].ToString().Trim()
                });
            }
            Response.Write(json.Serialize(new { Success = true, Data = list }));
        }

        // 解析前端篩選條件（支援 Form POST filterJson、Request.InputStream 或 GET 參數）
        private SearchFilterModel ParseFilter()
        {
            SearchFilterModel filter = null;
            string rawJson = Request["filterJson"];

            if (string.IsNullOrEmpty(rawJson))
            {
                try
                {
                    using (var reader = new StreamReader(Request.InputStream))
                    {
                        rawJson = reader.ReadToEnd();
                    }
                }
                catch { }
            }

            if (!string.IsNullOrEmpty(rawJson))
            {
                try
                {
                    filter = json.Deserialize<SearchFilterModel>(rawJson);
                }
                catch { }
            }

            if (filter == null)
            {
                filter = new SearchFilterModel();
                if (!string.IsNullOrEmpty(Request["mode"])) filter.Mode = Request["mode"];
                if (!string.IsNullOrEmpty(Request["showId"])) filter.ShowId = Request["showId"];
                if (!string.IsNullOrEmpty(Request["reportDateS"])) filter.ReportDateS = Request["reportDateS"];
                if (!string.IsNullOrEmpty(Request["reportDateE"])) filter.ReportDateE = Request["reportDateE"];
                if (!string.IsNullOrEmpty(Request["setComDateS"])) filter.SetComDateS = Request["setComDateS"];
                if (!string.IsNullOrEmpty(Request["setComDateE"])) filter.SetComDateE = Request["setComDateE"];
                if (!string.IsNullOrEmpty(Request["improveDateS"])) filter.ImproveDateS = Request["improveDateS"];
                if (!string.IsNullOrEmpty(Request["improveDateE"])) filter.ImproveDateE = Request["improveDateE"];
                if (!string.IsNullOrEmpty(Request["kinds"]))
                {
                    string[] ks = Request["kinds"].Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
                    for (int i = 0; i < ks.Length; i++)
                    {
                        filter.Kinds.Add(ks[i].Trim());
                    }
                }
                if (!string.IsNullOrEmpty(Request["units"]))
                {
                    string[] us = Request["units"].Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
                    for (int i = 0; i < us.Length; i++)
                    {
                        filter.Units.Add(us[i].Trim());
                    }
                }
            }

            return filter;
        }

        // 統一構建 SQL WHERE 篩選條件
        private string BuildWhere(SearchFilterModel filter, List<SqlParameter> parameters)
        {
            StringBuilder where = new StringBuilder(" WHERE 1=1 ");

            // 案件階段篩選 (依據 Mode)
            string mode = filter.Mode != null ? filter.Mode.Trim() : "DirtyEdit";
            if (string.Equals(mode, "DirtyEdit", StringComparison.OrdinalIgnoreCase))
            {
                where.Append(" AND SetCOM_Date IS NULL ");
            }
            else if (string.Equals(mode, "DirtyImprove", StringComparison.OrdinalIgnoreCase))
            {
                where.Append(" AND SetCOM_Date IS NOT NULL AND Improve_Date IS NULL ");
            }
            else if (string.Equals(mode, "Finish", StringComparison.OrdinalIgnoreCase))
            {
                where.Append(" AND SetCOM_Date IS NOT NULL AND Improve_Date IS NOT NULL ");
            }
            // 若為 'All' 則不增加案件狀態過濾

            // 通報案號篩選
            if (!string.IsNullOrEmpty(filter.ShowId))
            {
                where.Append(" AND (RoadDirty_CaseMain.Show_ID LIKE @showId OR RoadDirty_CaseMain.Dirty_ID LIKE @showId) ");
                parameters.Add(new SqlParameter("@showId", "%" + filter.ShowId.Trim() + "%"));
            }

            // 通報類別多選篩選
            if (filter.Kinds != null && filter.Kinds.Count > 0)
            {
                List<string> kindParams = new List<string>();
                for (int i = 0; i < filter.Kinds.Count; i++)
                {
                    string pName = "@kind_" + i;
                    kindParams.Add(pName);
                    parameters.Add(new SqlParameter(pName, filter.Kinds[i]));
                }
                where.Append(" AND RoadDirty_CaseMain.KIND IN (" + string.Join(",", kindParams.ToArray()) + ") ");
            }

            // 處理單位多選篩選
            if (filter.Units != null && filter.Units.Count > 0)
            {
                List<string> unitParams = new List<string>();
                for (int i = 0; i < filter.Units.Count; i++)
                {
                    string pName = "@unit_" + i;
                    unitParams.Add(pName);
                    parameters.Add(new SqlParameter(pName, filter.Units[i]));
                }
                where.Append(" AND RoadDirty_CaseMain.G_COM IN (" + string.Join(",", unitParams.ToArray()) + ") ");
            }

            // 查核日期區間
            if (!string.IsNullOrEmpty(filter.ReportDateS))
            {
                where.Append(" AND RoadDirty_CaseMain.Report_Date >= @rptS ");
                parameters.Add(new SqlParameter("@rptS", Convert.ToDateTime(filter.ReportDateS)));
            }
            if (!string.IsNullOrEmpty(filter.ReportDateE))
            {
                where.Append(" AND RoadDirty_CaseMain.Report_Date <= @rptE ");
                parameters.Add(new SqlParameter("@rptE", Convert.ToDateTime(filter.ReportDateE + " 23:59:59")));
            }

            // 通報日期區間
            if (!string.IsNullOrEmpty(filter.SetComDateS))
            {
                where.Append(" AND RoadDirty_CaseMain.SetCOM_Date >= @setS ");
                parameters.Add(new SqlParameter("@setS", Convert.ToDateTime(filter.SetComDateS)));
            }
            if (!string.IsNullOrEmpty(filter.SetComDateE))
            {
                where.Append(" AND RoadDirty_CaseMain.SetCOM_Date <= @setE ");
                parameters.Add(new SqlParameter("@setE", Convert.ToDateTime(filter.SetComDateE + " 23:59:59")));
            }

            // 改善日期區間
            if (!string.IsNullOrEmpty(filter.ImproveDateS))
            {
                where.Append(" AND RoadDirty_CaseMain.Improve_Date >= @impS ");
                parameters.Add(new SqlParameter("@impS", Convert.ToDateTime(filter.ImproveDateS)));
            }
            if (!string.IsNullOrEmpty(filter.ImproveDateE))
            {
                where.Append(" AND RoadDirty_CaseMain.Improve_Date <= @impE ");
                parameters.Add(new SqlParameter("@impE", Convert.ToDateTime(filter.ImproveDateE + " 23:59:59")));
            }

            return where.ToString();
        }

        // 3. 取得案件分頁清單
        private void GetList()
        {
            SearchFilterModel filter = ParseFilter();
            List<SqlParameter> parameters = new List<SqlParameter>();
            string whereClause = BuildWhere(filter, parameters);

            // 統計總筆數
            string countSql = "SELECT COUNT(*) FROM RoadDirty_CaseMain " + whereClause;
            int totalCount = Convert.ToInt32(DbHelper.ExecuteScalar(countSql, parameters.ToArray()));

            // 分頁查詢
            int pageIndex = filter.PageIndex > 0 ? filter.PageIndex : 1;
            int pageSize = filter.PageSize > 0 ? filter.PageSize : 20;
            int offset = (pageIndex - 1) * pageSize;

            string querySql = @"
                SELECT 
                    RoadDirty_CaseMain.*,
                    (SELECT TOP 1 Name FROM UserAcc WHERE UserAcc.UserID = RoadDirty_CaseMain.Report_User) AS Report_UserName,
                    (SELECT TOP 1 Name FROM UserAcc WHERE UserAcc.UserID = RoadDirty_CaseMain.S_User) AS S_UserName,
                    (SELECT TOP 1 Name FROM UserAcc WHERE UserAcc.UserID = RoadDirty_CaseMain.G_User) AS G_UserName,
                    (SELECT TOP 1 UnitName FROM RoadDirty_Unit WHERE RoadDirty_Unit.UnitID = RoadDirty_CaseMain.G_COM) AS G_COM_NAME,
                    CASE 
                        WHEN KIND = 'EB' THEN '營建工程道路污染 (EB)' 
                        WHEN KIND = 'EF' THEN '固定逸散道路污染 (EF)' 
                        WHEN KIND = 'ES' THEN '道路砂石堆積污染 (ES)' 
                        ELSE '未回報類型' 
                    END AS KIND_Name,
                    CASE 
                        WHEN Show_ID IS NULL OR Show_ID = '' THEN Dirty_ID 
                        ELSE Show_ID 
                    END AS Show_ID_Txt
                FROM RoadDirty_CaseMain "
                + whereClause
                + " ORDER BY Report_Date DESC, Dirty_ID DESC "
                + " OFFSET @offset ROWS FETCH NEXT @pageSize ROWS ONLY";

            List<SqlParameter> queryParams = new List<SqlParameter>(parameters);
            queryParams.Add(new SqlParameter("@offset", offset));
            queryParams.Add(new SqlParameter("@pageSize", pageSize));

            DataTable dt = DbHelper.ExecuteDataTable(querySql, queryParams.ToArray());
            List<object> items = new List<object>();

            foreach (DataRow row in dt.Rows)
            {
                string rptDateStr = "";
                if (row["Report_Date"] != DBNull.Value)
                {
                    rptDateStr = Convert.ToDateTime(row["Report_Date"]).ToString("yyyy-MM-dd HH:mm");
                }

                string setComDateStr = "";
                if (row["SetCOM_Date"] != DBNull.Value)
                {
                    setComDateStr = Convert.ToDateTime(row["SetCOM_Date"]).ToString("yyyy-MM-dd HH:mm");
                }

                string improveDateStr = "";
                if (row["Improve_Date"] != DBNull.Value)
                {
                    improveDateStr = Convert.ToDateTime(row["Improve_Date"]).ToString("yyyy-MM-dd HH:mm");
                }

                double utmE = 0;
                double utmN = 0;
                if (row["S_UTME"] != DBNull.Value) double.TryParse(row["S_UTME"].ToString(), out utmE);
                if (row["S_UTMN"] != DBNull.Value) double.TryParse(row["S_UTMN"].ToString(), out utmN);

                // 計算案件目前狀態代碼：1=未通報暫存中, 2=已派工待改善, 3=改善結案
                int statusCode = 1;
                string statusText = "暫存未通報";
                string statusBadgeClass = "badge-secondary";

                if (row["SetCOM_Date"] != DBNull.Value)
                {
                    if (row["Improve_Date"] == DBNull.Value)
                    {
                        statusCode = 2;
                        statusText = "待改善回報";
                        statusBadgeClass = "badge-warning";
                    }
                    else
                    {
                        statusCode = 3;
                        statusText = "已完成改善";
                        statusBadgeClass = "badge-success";
                    }
                }

                items.Add(new
                {
                    DirtyId = row["Dirty_ID"].ToString().Trim(),
                    ShowId = row["Show_ID_Txt"].ToString().Trim(),
                    Comm = row["COMM"] != DBNull.Value ? row["COMM"].ToString() : "",
                    Kind = row["KIND"] != DBNull.Value ? row["KIND"].ToString().Trim() : "",
                    KindName = row["KIND_Name"].ToString(),
                    ReportDate = rptDateStr,
                    ReportUser = row["Report_User"] != DBNull.Value ? row["Report_User"].ToString().Trim() : "",
                    ReportUserName = row["Report_UserName"] != DBNull.Value ? row["Report_UserName"].ToString().Trim() : (row["Report_User"] != DBNull.Value ? row["Report_User"].ToString().Trim() : ""),
                    SetComDate = setComDateStr,
                    S_User = row["S_User"] != DBNull.Value ? row["S_User"].ToString().Trim() : "",
                    S_UserName = row["S_UserName"] != DBNull.Value ? row["S_UserName"].ToString().Trim() : "",
                    G_Com = row["G_COM"] != DBNull.Value ? row["G_COM"].ToString().Trim() : "",
                    G_ComName = row["G_COM_NAME"] != DBNull.Value ? row["G_COM_NAME"].ToString().Trim() : "",
                    ImproveDate = improveDateStr,
                    G_User = row["G_User"] != DBNull.Value ? row["G_User"].ToString().Trim() : "",
                    G_UserName = row["G_UserName"] != DBNull.Value ? row["G_UserName"].ToString().Trim() : "",
                    S_UTME = utmE,
                    S_UTMN = utmN,
                    StatusCode = statusCode,
                    StatusText = statusText,
                    StatusBadgeClass = statusBadgeClass
                });
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                TotalCount = totalCount,
                PageIndex = pageIndex,
                PageSize = pageSize,
                Items = items
            }));
        }

        // =========================================================================
        // 原生 NPOI Excel (.xls) 匯出核心功能 (含 TWD97 與 WGS84 經緯度雙坐標系)
        // =========================================================================

        // TWD97 二度分帶轉 WGS84 經緯度演算法 (符合 C# 5.0 語法規範)
        private static void Twd97ToWgs84(double x, double y, out double lat, out double lon)
        {
            if (x <= 0 || y <= 0) { lat = 0; lon = 0; return; }

            double a = 6378137.0;
            double b = 6356752.314245;
            double lon0 = 121.0 * Math.PI / 180.0;
            double k0 = 0.9999;
            double dx = 250000.0;

            double e = Math.Sqrt(1.0 - (b * b) / (a * a));
            double e2 = e * e / (1.0 - e * e);
            x -= dx;

            double M = y / k0;
            double mu = M / (a * (1.0 - Math.Pow(e, 2) / 4.0 - 3.0 * Math.Pow(e, 4) / 64.0 - 5.0 * Math.Pow(e, 6) / 256.0));
            double e1 = (1.0 - Math.Sqrt(1.0 - Math.Pow(e, 2))) / (1.0 + Math.Sqrt(1.0 - Math.Pow(e, 2)));

            double J1 = (3.0 * e1 / 2.0 - 27.0 * Math.Pow(e1, 3) / 32.0);
            double J2 = (21.0 * Math.Pow(e1, 2) / 16.0 - 55.0 * Math.Pow(e1, 4) / 32.0);
            double J3 = (151.0 * Math.Pow(e1, 3) / 96.0);
            double J4 = (1097.0 * Math.Pow(e1, 4) / 512.0);

            double fp = mu + J1 * Math.Sin(2.0 * mu) + J2 * Math.Sin(4.0 * mu) + J3 * Math.Sin(6.0 * mu) + J4 * Math.Sin(8.0 * mu);

            double C1 = e2 * Math.Pow(Math.Cos(fp), 2);
            double T1 = Math.Pow(Math.Tan(fp), 2);
            double R1 = a * (1.0 - Math.Pow(e, 2)) / Math.Pow(1.0 - Math.Pow(e, 2) * Math.Pow(Math.Sin(fp), 2), 1.5);
            double N1 = a / Math.Sqrt(1.0 - Math.Pow(e, 2) * Math.Pow(Math.Sin(fp), 2));
            double D = x / (N1 * k0);

            double latRad = fp - (N1 * Math.Tan(fp) / R1) * (Math.Pow(D, 2) / 2.0 - (5.0 + 3.0 * T1 + 10.0 * C1 - 4.0 * Math.Pow(C1, 2) - 9.0 * e2) * Math.Pow(D, 4) / 24.0 + (61.0 + 90.0 * T1 + 298.0 * C1 + 45.0 * Math.Pow(T1, 2) - 252.0 * e2 - 3.0 * Math.Pow(C1, 2)) * Math.Pow(D, 6) / 720.0);
            double lonRad = lon0 + (D - (1.0 + 2.0 * T1 + C1) * Math.Pow(D, 3) / 6.0 + (5.0 - 2.0 * C1 + 28.0 * T1 - 3.0 * Math.Pow(C1, 2) + 8.0 * e2 + 24.0 * Math.Pow(T1, 2)) * Math.Pow(D, 5) / 120.0) / Math.Cos(fp);

            lat = latRad * 180.0 / Math.PI;
            lon = lonRad * 180.0 / Math.PI;
        }

        private ICellStyle CreateHeaderStyle(HSSFWorkbook wb)
        {
            IFont font = wb.CreateFont();
            font.FontName = "微軟正黑體";
            font.FontHeightInPoints = 10;
            font.IsBold = true;
            font.Color = HSSFColor.White.Index;

            ICellStyle style = wb.CreateCellStyle();
            style.Alignment = HorizontalAlignment.Center;
            style.VerticalAlignment = VerticalAlignment.Center;
            style.FillForegroundColor = HSSFColor.RoyalBlue.Index;
            style.FillPattern = FillPattern.SolidForeground;
            style.BorderTop = BorderStyle.Thin;
            style.BorderBottom = BorderStyle.Thin;
            style.BorderLeft = BorderStyle.Thin;
            style.BorderRight = BorderStyle.Thin;
            style.WrapText = false;
            style.SetFont(font);
            return style;
        }

        private ICellStyle CreateDataStyle(HSSFWorkbook wb, HorizontalAlignment align)
        {
            IFont font = wb.CreateFont();
            font.FontName = "微軟正黑體";
            font.FontHeightInPoints = 10;

            ICellStyle style = wb.CreateCellStyle();
            style.Alignment = align;
            style.VerticalAlignment = VerticalAlignment.Center;
            style.BorderTop = BorderStyle.Thin;
            style.BorderBottom = BorderStyle.Thin;
            style.BorderLeft = BorderStyle.Thin;
            style.BorderRight = BorderStyle.Thin;
            style.SetFont(font);
            return style;
        }

        private void ExportExcel()
        {
            SearchFilterModel filter = ParseFilter();
            List<SqlParameter> parameters = new List<SqlParameter>();
            string whereClause = BuildWhere(filter, parameters);

            string querySql = @"
                SELECT 
                    RoadDirty_CaseMain.*,
                    (SELECT TOP 1 Name FROM UserAcc WHERE UserAcc.UserID = RoadDirty_CaseMain.Report_User) AS Report_UserName,
                    (SELECT TOP 1 Name FROM UserAcc WHERE UserAcc.UserID = RoadDirty_CaseMain.S_User) AS S_UserName,
                    (SELECT TOP 1 Name FROM UserAcc WHERE UserAcc.UserID = RoadDirty_CaseMain.G_User) AS G_UserName,
                    (SELECT TOP 1 UnitName FROM RoadDirty_Unit WHERE RoadDirty_Unit.UnitID = RoadDirty_CaseMain.G_COM) AS G_COM_NAME,
                    CASE 
                        WHEN KIND = 'EB' THEN '營建工程道路污染 (EB)' 
                        WHEN KIND = 'EF' THEN '固定逸散道路污染 (EF)' 
                        WHEN KIND = 'ES' THEN '道路砂石堆積污染 (ES)' 
                        ELSE '未回報類型' 
                    END AS KIND_Name,
                    CASE 
                        WHEN Show_ID IS NULL OR Show_ID = '' THEN Dirty_ID 
                        ELSE Show_ID 
                    END AS Show_ID_Txt
                FROM RoadDirty_CaseMain "
                + whereClause
                + " ORDER BY Report_Date DESC, Dirty_ID DESC";

            DataTable dt = DbHelper.ExecuteDataTable(querySql, parameters.ToArray());

            HSSFWorkbook wb = new HSSFWorkbook();
            ISheet sheet = wb.CreateSheet("道路髒污案件清單");
            sheet.CreateFreezePane(0, 1); // 凍結首行表頭

            ICellStyle headerStyle = CreateHeaderStyle(wb);
            ICellStyle centerStyle = CreateDataStyle(wb, HorizontalAlignment.Center);
            ICellStyle leftStyle = CreateDataStyle(wb, HorizontalAlignment.Left);
            ICellStyle rightStyle = CreateDataStyle(wb, HorizontalAlignment.Right);

            string[] headers = new string[]
            {
                "項次",
                "通報案號",
                "系統案號",
                "案件狀態",
                "污染類型",
                "查核時間",
                "查核人員",
                "通報派工時間",
                "通報人員",
                "處理權責單位",
                "改善回報時間",
                "改善回報人員",
                "現場坐標1(X)",
                "現場坐標1(Y)",
                "現場經度1(Lon)",
                "現場緯度1(Lat)",
                "現場坐標2(X)",
                "現場坐標2(Y)",
                "現場經度2(Lon)",
                "現場緯度2(Lat)",
                "通報補充說明與路況特徵",
                "處理改善說明備註"
            };

            IRow headerRow = sheet.CreateRow(0);
            headerRow.HeightInPoints = 26;
            for (int i = 0; i < headers.Length; i++)
            {
                ICell cell = headerRow.CreateCell(i);
                cell.SetCellValue(headers[i]);
                cell.CellStyle = headerStyle;
            }

            int rowIndex = 1;
            foreach (DataRow row in dt.Rows)
            {
                IRow dataRow = sheet.CreateRow(rowIndex);
                dataRow.HeightInPoints = 20;

                string rptDateStr = "";
                if (row["Report_Date"] != DBNull.Value)
                {
                    rptDateStr = Convert.ToDateTime(row["Report_Date"]).ToString("yyyy-MM-dd HH:mm");
                }

                string setComDateStr = "";
                if (row["SetCOM_Date"] != DBNull.Value)
                {
                    setComDateStr = Convert.ToDateTime(row["SetCOM_Date"]).ToString("yyyy-MM-dd HH:mm");
                }

                string improveDateStr = "";
                if (row["Improve_Date"] != DBNull.Value)
                {
                    improveDateStr = Convert.ToDateTime(row["Improve_Date"]).ToString("yyyy-MM-dd HH:mm");
                }

                // 案件狀態
                string statusText = "暫存未通報";
                if (row["SetCOM_Date"] != DBNull.Value)
                {
                    if (row["Improve_Date"] == DBNull.Value)
                    {
                        statusText = "待改善回報";
                    }
                    else
                    {
                        statusText = "已完成改善";
                    }
                }

                double utmE = 0, utmN = 0, utmE1 = 0, utmN1 = 0;
                if (row["S_UTME"] != DBNull.Value) double.TryParse(row["S_UTME"].ToString(), out utmE);
                if (row["S_UTMN"] != DBNull.Value) double.TryParse(row["S_UTMN"].ToString(), out utmN);
                if (row.Table.Columns.Contains("S_UTME1") && row["S_UTME1"] != DBNull.Value) double.TryParse(row["S_UTME1"].ToString(), out utmE1);
                if (row.Table.Columns.Contains("S_UTMN1") && row["S_UTMN1"] != DBNull.Value) double.TryParse(row["S_UTMN1"].ToString(), out utmN1);

                // 計算或讀取現場坐標 1 經緯度 (WGS84)
                double lon1 = 0, lat1 = 0;
                if (row.Table.Columns.Contains("S_LON") && row["S_LON"] != DBNull.Value) double.TryParse(row["S_LON"].ToString(), out lon1);
                if (row.Table.Columns.Contains("S_LAT") && row["S_LAT"] != DBNull.Value) double.TryParse(row["S_LAT"].ToString(), out lat1);
                if (lon1 <= 0 || lat1 <= 0)
                {
                    if (utmE > 0 && utmN > 0)
                    {
                        Twd97ToWgs84(utmE, utmN, out lat1, out lon1);
                    }
                }

                // 計算或讀取現場坐標 2 經緯度 (WGS84)
                double lon2 = 0, lat2 = 0;
                if (row.Table.Columns.Contains("S_LON1") && row["S_LON1"] != DBNull.Value) double.TryParse(row["S_LON1"].ToString(), out lon2);
                if (row.Table.Columns.Contains("S_LAT1") && row["S_LAT1"] != DBNull.Value) double.TryParse(row["S_LAT1"].ToString(), out lat2);
                if (lon2 <= 0 || lat2 <= 0)
                {
                    if (utmE1 > 0 && utmN1 > 0)
                    {
                        Twd97ToWgs84(utmE1, utmN1, out lat2, out lon2);
                    }
                }

                string comm = row["COMM"] != DBNull.Value ? row["COMM"].ToString().Trim() : "";
                string gMemo = (row.Table.Columns.Contains("G_MEMO") && row["G_MEMO"] != DBNull.Value) ? row["G_MEMO"].ToString().Trim() : "";

                // 0: 項次
                ICell c0 = dataRow.CreateCell(0);
                c0.SetCellValue(rowIndex);
                c0.CellStyle = centerStyle;

                // 1: 通報案號
                ICell c1 = dataRow.CreateCell(1);
                c1.SetCellValue(row["Show_ID_Txt"].ToString().Trim());
                c1.CellStyle = centerStyle;

                // 2: 系統案號
                ICell c2 = dataRow.CreateCell(2);
                c2.SetCellValue(row["Dirty_ID"].ToString().Trim());
                c2.CellStyle = centerStyle;

                // 3: 案件狀態
                ICell c3 = dataRow.CreateCell(3);
                c3.SetCellValue(statusText);
                c3.CellStyle = centerStyle;

                // 4: 污染類型
                ICell c4 = dataRow.CreateCell(4);
                c4.SetCellValue(row["KIND_Name"].ToString().Trim());
                c4.CellStyle = leftStyle;

                // 5: 查核時間
                ICell c5 = dataRow.CreateCell(5);
                c5.SetCellValue(rptDateStr);
                c5.CellStyle = centerStyle;

                // 6: 查核人員
                ICell c6 = dataRow.CreateCell(6);
                string rptUser = row["Report_UserName"] != DBNull.Value ? row["Report_UserName"].ToString().Trim() : (row["Report_User"] != DBNull.Value ? row["Report_User"].ToString().Trim() : "");
                c6.SetCellValue(rptUser);
                c6.CellStyle = centerStyle;

                // 7: 通報派工時間
                ICell c7 = dataRow.CreateCell(7);
                c7.SetCellValue(setComDateStr);
                c7.CellStyle = centerStyle;

                // 8: 通報人員
                ICell c8 = dataRow.CreateCell(8);
                string sUser = row["S_UserName"] != DBNull.Value ? row["S_UserName"].ToString().Trim() : (row["S_User"] != DBNull.Value ? row["S_User"].ToString().Trim() : "");
                c8.SetCellValue(sUser);
                c8.CellStyle = centerStyle;

                // 9: 處理權責單位
                ICell c9 = dataRow.CreateCell(9);
                c9.SetCellValue(row["G_COM_NAME"] != DBNull.Value ? row["G_COM_NAME"].ToString().Trim() : "");
                c9.CellStyle = leftStyle;

                // 10: 改善回報時間
                ICell c10 = dataRow.CreateCell(10);
                c10.SetCellValue(improveDateStr);
                c10.CellStyle = centerStyle;

                // 11: 改善回報人員
                ICell c11 = dataRow.CreateCell(11);
                string gUser = row["G_UserName"] != DBNull.Value ? row["G_UserName"].ToString().Trim() : (row["G_User"] != DBNull.Value ? row["G_User"].ToString().Trim() : "");
                c11.SetCellValue(gUser);
                c11.CellStyle = centerStyle;

                // 12: 現場坐標1(X) - TWD97
                ICell c12 = dataRow.CreateCell(12);
                if (utmE > 0) c12.SetCellValue(Math.Round(utmE, 2));
                else c12.SetCellValue("");
                c12.CellStyle = rightStyle;

                // 13: 現場坐標1(Y) - TWD97
                ICell c13 = dataRow.CreateCell(13);
                if (utmN > 0) c13.SetCellValue(Math.Round(utmN, 2));
                else c13.SetCellValue("");
                c13.CellStyle = rightStyle;

                // 14: 現場經度1(Lon) - WGS84
                ICell c14 = dataRow.CreateCell(14);
                if (lon1 > 0) c14.SetCellValue(Math.Round(lon1, 6));
                else c14.SetCellValue("");
                c14.CellStyle = rightStyle;

                // 15: 現場緯度1(Lat) - WGS84
                ICell c15 = dataRow.CreateCell(15);
                if (lat1 > 0) c15.SetCellValue(Math.Round(lat1, 6));
                else c15.SetCellValue("");
                c15.CellStyle = rightStyle;

                // 16: 現場坐標2(X) - TWD97
                ICell c16 = dataRow.CreateCell(16);
                if (utmE1 > 0) c16.SetCellValue(Math.Round(utmE1, 2));
                else c16.SetCellValue("");
                c16.CellStyle = rightStyle;

                // 17: 現場坐標2(Y) - TWD97
                ICell c17 = dataRow.CreateCell(17);
                if (utmN1 > 0) c17.SetCellValue(Math.Round(utmN1, 2));
                else c17.SetCellValue("");
                c17.CellStyle = rightStyle;

                // 18: 現場經度2(Lon) - WGS84
                ICell c18 = dataRow.CreateCell(18);
                if (lon2 > 0) c18.SetCellValue(Math.Round(lon2, 6));
                else c18.SetCellValue("");
                c18.CellStyle = rightStyle;

                // 19: 現場緯度2(Lat) - WGS84
                ICell c19 = dataRow.CreateCell(19);
                if (lat2 > 0) c19.SetCellValue(Math.Round(lat2, 6));
                else c19.SetCellValue("");
                c19.CellStyle = rightStyle;

                // 20: 通報補充說明與路況特徵
                ICell c20 = dataRow.CreateCell(20);
                c20.SetCellValue(comm);
                c20.CellStyle = leftStyle;

                // 21: 處理改善說明備註
                ICell c21 = dataRow.CreateCell(21);
                c21.SetCellValue(gMemo);
                c21.CellStyle = leftStyle;

                rowIndex++;
            }

            // 設定適當欄寬
            int[] colWidths = new int[]
            {
                8,   // 0: 項次
                18,  // 1: 通報案號
                18,  // 2: 系統案號
                14,  // 3: 案件狀態
                25,  // 4: 污染類型
                18,  // 5: 查核時間
                12,  // 6: 查核人員
                18,  // 7: 通報派工時間
                12,  // 8: 通報人員
                22,  // 9: 處理權責單位
                18,  // 10: 改善回報時間
                14,  // 11: 改善回報人員
                14,  // 12: 坐標1(X)
                14,  // 13: 坐標1(Y)
                16,  // 14: 經度1(Lon)
                16,  // 15: 緯度1(Lat)
                14,  // 16: 坐標2(X)
                14,  // 17: 坐標2(Y)
                16,  // 18: 經度2(Lon)
                16,  // 19: 緯度2(Lat)
                35,  // 20: 通報補充
                30   // 21: 改善備註
            };
            for (int i = 0; i < colWidths.Length; i++)
            {
                sheet.SetColumnWidth(i, colWidths[i] * 256);
            }

            string fileName = "道路髒污管理清單_" + DateTime.Now.ToString("yyyyMMdd_HHmmss") + ".xls";
            using (MemoryStream ms = new MemoryStream())
            {
                wb.Write(ms);
                byte[] bytes = ms.ToArray();

                Response.Clear();
                Response.ClearHeaders();
                Response.Buffer = true;
                Response.ContentType = "application/vnd.ms-excel";
                string encodedName = HttpUtility.UrlEncode(fileName, Encoding.UTF8).Replace("+", "%20");
                Response.AddHeader("Content-Disposition", "attachment; filename=" + encodedName);
                Response.AddHeader("Content-Length", bytes.Length.ToString());
                Response.BinaryWrite(bytes);
                Response.Flush();
                Response.End();
            }
        }

        // 4. 取得單筆案件的快速預覽詳情 (含照片與坐標)
        private void GetCasePreview(string dirtyId)
        {
            if (string.IsNullOrEmpty(dirtyId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "缺少案號參數" }));
                return;
            }

            string sql = @"
                SELECT 
                    RoadDirty_CaseMain.*,
                    (SELECT TOP 1 Name FROM UserAcc WHERE UserAcc.UserID = RoadDirty_CaseMain.Report_User) AS Report_UserName,
                    (SELECT TOP 1 Name FROM UserAcc WHERE UserAcc.UserID = RoadDirty_CaseMain.S_User) AS S_UserName,
                    (SELECT TOP 1 Name FROM UserAcc WHERE UserAcc.UserID = RoadDirty_CaseMain.G_User) AS G_UserName,
                    (SELECT TOP 1 UnitName FROM RoadDirty_Unit WHERE RoadDirty_Unit.UnitID = RoadDirty_CaseMain.G_COM) AS G_COM_NAME,
                    CASE 
                        WHEN KIND = 'EB' THEN '營建工程道路污染 (EB)' 
                        WHEN KIND = 'EF' THEN '固定逸散道路污染 (EF)' 
                        WHEN KIND = 'ES' THEN '道路砂石堆積污染 (ES)' 
                        ELSE '未回報類型' 
                    END AS KIND_Name,
                    CASE 
                        WHEN Show_ID IS NULL OR Show_ID = '' THEN Dirty_ID 
                        ELSE Show_ID 
                    END AS Show_ID_Txt
                FROM RoadDirty_CaseMain 
                WHERE Dirty_ID = @id";

            DataTable dt = DbHelper.ExecuteDataTable(sql, new SqlParameter("@id", dirtyId));
            if (dt.Rows.Count == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "查無此案件紀錄" }));
                return;
            }

            DataRow row = dt.Rows[0];
            double utmE = 0, utmN = 0, utmE1 = 0, utmN1 = 0;
            if (row["S_UTME"] != DBNull.Value) double.TryParse(row["S_UTME"].ToString(), out utmE);
            if (row["S_UTMN"] != DBNull.Value) double.TryParse(row["S_UTMN"].ToString(), out utmN);
            if (row.Table.Columns.Contains("S_UTME1") && row["S_UTME1"] != DBNull.Value) double.TryParse(row["S_UTME1"].ToString(), out utmE1);
            if (row.Table.Columns.Contains("S_UTMN1") && row["S_UTMN1"] != DBNull.Value) double.TryParse(row["S_UTMN1"].ToString(), out utmN1);

            // 讀取硬碟照片
            List<object> photos1 = GetExistingPhotos(dirtyId, "疑似髒污點現場照片");
            List<object> photos2 = GetExistingPhotos(dirtyId, "佐證照片");
            List<object> improvePhotos = GetExistingPhotos(dirtyId, "改善後照片");

            var detail = new
            {
                DirtyId = row["Dirty_ID"].ToString().Trim(),
                ShowId = row["Show_ID_Txt"].ToString().Trim(),
                Comm = row["COMM"] != DBNull.Value ? row["COMM"].ToString() : "",
                Kind = row["KIND"] != DBNull.Value ? row["KIND"].ToString().Trim() : "",
                KindName = row["KIND_Name"].ToString(),
                ReportDate = row["Report_Date"] != DBNull.Value ? Convert.ToDateTime(row["Report_Date"]).ToString("yyyy-MM-dd HH:mm") : "",
                ReportUserName = row["Report_UserName"] != DBNull.Value ? row["Report_UserName"].ToString().Trim() : (row["Report_User"] != DBNull.Value ? row["Report_User"].ToString().Trim() : ""),
                SetComDate = row["SetCOM_Date"] != DBNull.Value ? Convert.ToDateTime(row["SetCOM_Date"]).ToString("yyyy-MM-dd HH:mm") : "",
                S_UserName = row["S_UserName"] != DBNull.Value ? row["S_UserName"].ToString().Trim() : "",
                G_ComName = row["G_COM_NAME"] != DBNull.Value ? row["G_COM_NAME"].ToString().Trim() : "",
                ImproveDate = row["Improve_Date"] != DBNull.Value ? Convert.ToDateTime(row["Improve_Date"]).ToString("yyyy-MM-dd HH:mm") : "",
                G_UserName = row["G_UserName"] != DBNull.Value ? row["G_UserName"].ToString().Trim() : "",
                G_Memo = row.Table.Columns.Contains("G_MEMO") && row["G_MEMO"] != DBNull.Value ? row["G_MEMO"].ToString() : "",
                S_UTME = utmE,
                S_UTMN = utmN,
                S_UTME1 = utmE1,
                S_UTMN1 = utmN1,
                Photos1 = photos1,
                Photos2 = photos2,
                ImprovePhotos = improvePhotos
            };

            Response.Write(json.Serialize(new { Success = true, Data = detail }));
        }

        // 讀取硬碟中的現有照片列表
        private List<object> GetExistingPhotos(string dirtyId, string prefix)
        {
            var list = new List<object>();
            string relDir = "/Upload/RoadDirtyPIC/" + dirtyId + "/";
            string physDir = Server.MapPath("~" + relDir);

            if (!Directory.Exists(physDir))
            {
                return list;
            }

            DirectoryInfo di = new DirectoryInfo(physDir);
            FileInfo[] files = di.GetFiles(prefix + "*.*");
            Array.Sort(files, delegate(FileInfo a, FileInfo b) { return a.Name.CompareTo(b.Name); });

            foreach (FileInfo f in files)
            {
                string ext = f.Extension.ToLower();
                if (ext == ".jpg" || ext == ".jpeg" || ext == ".png" || ext == ".gif")
                {
                    list.Add(new
                    {
                        FileName = f.Name,
                        Url = relDir + f.Name,
                        Size = f.Length,
                        LastModified = f.LastWriteTime.ToString("yyyy-MM-dd HH:mm")
                    });
                }
            }

            return list;
        }

        // 5. 刪除案件
        private void DeleteCase()
        {
            string rawJson = null;
            using (var reader = new StreamReader(Request.InputStream))
            {
                rawJson = reader.ReadToEnd();
            }

            if (string.IsNullOrEmpty(rawJson))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "請求內容不能為空" }));
                return;
            }

            ActionIdModel req = json.Deserialize<ActionIdModel>(rawJson);
            if (req == null || string.IsNullOrEmpty(req.DirtyId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "缺少通報案號" }));
                return;
            }

            string sql = "DELETE FROM RoadDirty_CaseMain WHERE Dirty_ID = @id";
            DbHelper.ExecuteNonQuery(sql, new SqlParameter("@id", req.DirtyId));

            // 清理硬碟目錄
            string relDir = "/Upload/RoadDirtyPIC/" + req.DirtyId + "/";
            string physDir = Server.MapPath("~" + relDir);
            if (Directory.Exists(physDir))
            {
                try { Directory.Delete(physDir, true); } catch { }
            }

            Response.Write(json.Serialize(new { Success = true, Message = "案件已成功刪除" }));
        }
    }
}
