using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Security.Cryptography;
using System.Text;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.UI;
using NTPC_FEC.Helpers;
using NPOI.HSSF.UserModel;
using NPOI.SS.UserModel;

namespace NTPC_FEC.OwnReport
{
    public partial class PIC_Report_List : Page
    {
        private JavaScriptSerializer json;

        public PIC_Report_List()
        {
            json = new JavaScriptSerializer();
            json.MaxJsonLength = int.MaxValue;
        }

        public class SearchFilterModel
        {
            public string Mode { get; set; }
            public string FacId { get; set; }
            public string DateS { get; set; }
            public string DateE { get; set; }
            public string Keyword { get; set; }
            public int PageIndex { get; set; }
            public int PageSize { get; set; }

            public SearchFilterModel()
            {
                Mode = "all";
                FacId = "ALL";
                DateS = "";
                DateE = "";
                Keyword = "";
                PageIndex = 1;
                PageSize = 20;
            }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            string action = Request["action"];
            if (!string.IsNullOrEmpty(action))
            {
                if (string.Equals(action, "export", StringComparison.OrdinalIgnoreCase))
                {
                    try
                    {
                        ExportExcel();
                    }
                    catch (System.Threading.ThreadAbortException)
                    {
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
                case "getuserinfo":
                    GetUserInfo();
                    break;
                case "getcounts":
                    GetCounts();
                    break;
                case "getfacs":
                    GetFacs();
                    break;
                case "getlist":
                    GetList();
                    break;
                case "getpreview":
                    GetPreview();
                    break;
                default:
                    Response.Write(json.Serialize(new { Success = false, Message = "未知的操作指令" }));
                    break;
            }
        }

        private string GetCurrentUserId()
        {
            if (Session["LoginUser"] != null && !string.IsNullOrEmpty(Session["LoginUser"].ToString()))
            {
                return Session["LoginUser"].ToString().Trim();
            }
            return "";
        }

        private string GetUserFacId(string userId)
        {
            if (string.IsNullOrEmpty(userId)) return "";
            try
            {
                string sql = "SELECT TOP 1 FAC_ID FROM UserAcc WHERE UserID = @UserID";
                SqlParameter[] paras = new SqlParameter[]
                {
                    new SqlParameter("@UserID", SqlDbType.VarChar) { Value = userId }
                };
                DataTable dt = DbHelper.ExecuteDataTable(sql, paras);
                if (dt != null && dt.Rows.Count > 0 && dt.Rows[0]["FAC_ID"] != DBNull.Value)
                {
                    return dt.Rows[0]["FAC_ID"].ToString().Trim();
                }
            }
            catch
            {
            }
            return "";
        }

        private bool IsAdminUser(string userId)
        {
            if (string.IsNullOrEmpty(userId)) return true; // 開發測試預設放行
            try
            {
                string sql = "SELECT TOP 1 LIC, LIC2, FAC_ID FROM UserAcc WHERE UserID = @UserID";
                SqlParameter[] paras = new SqlParameter[]
                {
                    new SqlParameter("@UserID", SqlDbType.VarChar) { Value = userId }
                };
                DataTable dt = DbHelper.ExecuteDataTable(sql, paras);
                if (dt != null && dt.Rows.Count > 0)
                {
                    DataRow r = dt.Rows[0];
                    string facId = r["FAC_ID"] != DBNull.Value ? r["FAC_ID"].ToString().Trim() : "";
                    if (string.IsNullOrEmpty(facId)) return true;

                    long lic = 0L;
                    if (r["LIC"] != DBNull.Value) long.TryParse(r["LIC"].ToString(), out lic);
                    // 若擁有管理者權限位元 (如 15 或 63 或 9)
                    if ((lic & (1L << 15)) != 0 || (lic & (1L << 63)) != 0 || (lic & (1L << 9)) != 0)
                    {
                        return true;
                    }
                    return false;
                }
            }
            catch
            {
            }
            return true;
        }

        private void GetUserInfo()
        {
            string uid = GetCurrentUserId();
            string facId = GetUserFacId(uid);
            bool isAdmin = IsAdminUser(uid);
            string facName = "";

            if (!string.IsNullOrEmpty(facId))
            {
                try
                {
                    string sql = "SELECT TOP 1 FAC_NAME FROM FAC_Main WHERE FAC_ID = @FAC_ID";
                    SqlParameter[] paras = new SqlParameter[]
                    {
                        new SqlParameter("@FAC_ID", SqlDbType.VarChar) { Value = facId }
                    };
                    DataTable dt = DbHelper.ExecuteDataTable(sql, paras);
                    if (dt != null && dt.Rows.Count > 0 && dt.Rows[0]["FAC_NAME"] != DBNull.Value)
                    {
                        facName = dt.Rows[0]["FAC_NAME"].ToString().Trim();
                    }
                }
                catch { }
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                Data = new
                {
                    UserId = uid,
                    FacId = facId,
                    FacName = facName,
                    IsAdmin = isAdmin
                }
            }));
        }

        private void GetCounts()
        {
            string uid = GetCurrentUserId();
            string userFacId = GetUserFacId(uid);
            bool isAdmin = IsAdminUser(uid);

            List<SqlParameter> paras = new List<SqlParameter>();
            string facFilter = "";
            if (!isAdmin && !string.IsNullOrEmpty(userFacId))
            {
                facFilter = " WHERE FAC_ID = @User_FAC_ID ";
                paras.Add(new SqlParameter("@User_FAC_ID", SqlDbType.VarChar) { Value = userFacId });
            }

            string sql = @"
                SELECT 
                    COUNT(*) AS TotalCount,
                    SUM(CASE WHEN Report_Type = '自主回報' THEN 1 ELSE 0 END) AS OwnCount,
                    SUM(CASE WHEN Report_Type = '缺失改善' THEN 1 ELSE 0 END) AS WrongCount,
                    SUM(CASE WHEN Report_Date >= DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0) THEN 1 ELSE 0 END) AS MonthCount
                FROM INV_Report " + facFilter;

            DataTable dt = null;
            try
            {
                dt = DbHelper.ExecuteDataTable(sql, paras.ToArray());
            }
            catch
            {
            }

            int total = 0, own = 0, wrong = 0, month = 0;
            if (dt != null && dt.Rows.Count > 0)
            {
                DataRow r = dt.Rows[0];
                if (r["TotalCount"] != DBNull.Value) total = Convert.ToInt32(r["TotalCount"]);
                if (r["OwnCount"] != DBNull.Value) own = Convert.ToInt32(r["OwnCount"]);
                if (r["WrongCount"] != DBNull.Value) wrong = Convert.ToInt32(r["WrongCount"]);
                if (r["MonthCount"] != DBNull.Value) month = Convert.ToInt32(r["MonthCount"]);
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                Data = new
                {
                    TotalCount = total,
                    OwnCount = own,
                    WrongCount = wrong,
                    MonthCount = month
                }
            }));
        }

        private void GetFacs()
        {
            string uid = GetCurrentUserId();
            string userFacId = GetUserFacId(uid);
            bool isAdmin = IsAdminUser(uid);

            var list = new List<object>();

            if (!isAdmin && !string.IsNullOrEmpty(userFacId))
            {
                string sql = "SELECT FAC_ID, FAC_NAME, C_NO, ADDR FROM FAC_Main WHERE FAC_ID = @FAC_ID";
                SqlParameter[] paras = new SqlParameter[]
                {
                    new SqlParameter("@FAC_ID", SqlDbType.VarChar) { Value = userFacId }
                };
                DataTable dt = DbHelper.ExecuteDataTable(sql, paras);
                if (dt != null && dt.Rows.Count > 0)
                {
                    DataRow r = dt.Rows[0];
                    string town = ExtractTown(r);
                    list.Add(new
                    {
                        FacId = r["FAC_ID"].ToString().Trim(),
                        FacName = (r["FAC_NAME"] != DBNull.Value ? r["FAC_NAME"].ToString().Trim() : ""),
                        CNo = (r.Table.Columns.Contains("C_NO") && r["C_NO"] != DBNull.Value ? r["C_NO"].ToString().Trim() : ""),
                        Town = town
                    });
                }
            }
            else
            {
                string sql = @"
                    SELECT DISTINCT F.FAC_ID, F.FAC_NAME, F.C_NO, F.ADDR 
                    FROM FAC_Main F
                    INNER JOIN INV_Report R ON F.FAC_ID = R.FAC_ID
                    ORDER BY F.FAC_NAME";
                DataTable dt = null;
                try
                {
                    dt = DbHelper.ExecuteDataTable(sql);
                }
                catch
                {
                }

                if (dt == null || dt.Rows.Count == 0)
                {
                    // 若尚未有回報關聯，備援撈取前 100 筆
                    try
                    {
                        dt = DbHelper.ExecuteDataTable("SELECT TOP 100 FAC_ID, FAC_NAME, C_NO, ADDR FROM FAC_Main ORDER BY FAC_NAME");
                    }
                    catch { }
                }

                if (dt != null)
                {
                    foreach (DataRow r in dt.Rows)
                    {
                        string town = ExtractTown(r);
                        list.Add(new
                        {
                            FacId = r["FAC_ID"].ToString().Trim(),
                            FacName = (r["FAC_NAME"] != DBNull.Value ? r["FAC_NAME"].ToString().Trim() : ""),
                            CNo = (r.Table.Columns.Contains("C_NO") && r["C_NO"] != DBNull.Value ? r["C_NO"].ToString().Trim() : ""),
                            Town = town
                        });
                    }
                }
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                Data = list
            }));
        }

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
                if (!string.IsNullOrEmpty(Request["facId"])) filter.FacId = Request["facId"];
                if (!string.IsNullOrEmpty(Request["dateS"])) filter.DateS = Request["dateS"];
                if (!string.IsNullOrEmpty(Request["dateE"])) filter.DateE = Request["dateE"];
                if (!string.IsNullOrEmpty(Request["keyword"])) filter.Keyword = Request["keyword"];
                int pIndex = 1, pSize = 20;
                if (int.TryParse(Request["pageIndex"], out pIndex)) filter.PageIndex = pIndex;
                if (int.TryParse(Request["pageSize"], out pSize)) filter.PageSize = pSize;
            }

            return filter;
        }

        private string BuildWhere(SearchFilterModel filter, List<SqlParameter> paras)
        {
            StringBuilder sb = new StringBuilder(" WHERE 1=1 ");

            // 1. 權限防護：業者只能查自己所屬場所
            string uid = GetCurrentUserId();
            string userFacId = GetUserFacId(uid);
            bool isAdmin = IsAdminUser(uid);
            if (!isAdmin && !string.IsNullOrEmpty(userFacId))
            {
                sb.Append(" AND INV_Report.FAC_ID = @User_FAC_ID ");
                paras.Add(new SqlParameter("@User_FAC_ID", SqlDbType.VarChar) { Value = userFacId });
            }
            else if (!string.IsNullOrEmpty(filter.FacId) && !string.Equals(filter.FacId, "ALL", StringComparison.OrdinalIgnoreCase))
            {
                sb.Append(" AND INV_Report.FAC_ID = @Filter_FAC_ID ");
                paras.Add(new SqlParameter("@Filter_FAC_ID", SqlDbType.VarChar) { Value = filter.FacId.Trim() });
            }

            // 2. 回報類型 (mode: all / own / wrong)
            if (string.Equals(filter.Mode, "own", StringComparison.OrdinalIgnoreCase))
            {
                sb.Append(" AND INV_Report.Report_Type = @Report_Type ");
                paras.Add(new SqlParameter("@Report_Type", SqlDbType.NVarChar) { Value = "自主回報" });
            }
            else if (string.Equals(filter.Mode, "wrong", StringComparison.OrdinalIgnoreCase))
            {
                sb.Append(" AND INV_Report.Report_Type = @Report_Type ");
                paras.Add(new SqlParameter("@Report_Type", SqlDbType.NVarChar) { Value = "缺失改善" });
            }

            // 3. 日期起訖
            if (!string.IsNullOrEmpty(filter.DateS))
            {
                DateTime dtS;
                if (DateTime.TryParse(filter.DateS, out dtS))
                {
                    sb.Append(" AND INV_Report.Report_Date >= @DateS ");
                    paras.Add(new SqlParameter("@DateS", SqlDbType.DateTime) { Value = dtS.Date });
                }
            }
            if (!string.IsNullOrEmpty(filter.DateE))
            {
                DateTime dtE;
                if (DateTime.TryParse(filter.DateE, out dtE))
                {
                    sb.Append(" AND INV_Report.Report_Date <= @DateE ");
                    paras.Add(new SqlParameter("@DateE", SqlDbType.DateTime) { Value = dtE.Date.AddDays(1).AddSeconds(-1) });
                }
            }

            // 4. 關鍵字搜尋 (公私場所名稱、管制編號、回報單號)
            if (!string.IsNullOrEmpty(filter.Keyword))
            {
                string kw = "%" + filter.Keyword.Trim() + "%";
                sb.Append(" AND (FAC_Main.FAC_NAME LIKE @Keyword OR FAC_Main.C_NO LIKE @Keyword OR CAST(INV_Report.Report_NO AS NVARCHAR) LIKE @Keyword) ");
                paras.Add(new SqlParameter("@Keyword", SqlDbType.NVarChar) { Value = kw });
            }

            return sb.ToString();
        }

        private void GetList()
        {
            SearchFilterModel filter = ParseFilter();
            List<SqlParameter> countParas = new List<SqlParameter>();
            string whereSql = BuildWhere(filter, countParas);

            // 計算總筆數
            string countSql = @"
                SELECT COUNT(*) 
                FROM INV_Report 
                LEFT JOIN FAC_Main ON INV_Report.FAC_ID = FAC_Main.FAC_ID " + whereSql;

            int totalCount = 0;
            try
            {
                object obj = DbHelper.ExecuteScalar(countSql, countParas.ToArray());
                if (obj != null && obj != DBNull.Value)
                {
                    totalCount = Convert.ToInt32(obj);
                }
            }
            catch (Exception ex)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "查詢失敗：" + ex.Message }));
                return;
            }

            int pageIndex = filter.PageIndex > 0 ? filter.PageIndex : 1;
            int pageSize = filter.PageSize > 0 ? filter.PageSize : 20;
            int offset = (pageIndex - 1) * pageSize;

            List<SqlParameter> listParas = new List<SqlParameter>();
            string listWhereSql = BuildWhere(filter, listParas);

            // 僅查詢確定存在之欄位 (FAC_NAME, C_NO, ADDR)，杜絕無效資料行錯誤
            string querySql = @"
                SELECT 
                    INV_Report.pID,
                    INV_Report.Report_NO,
                    INV_Report.INV_NO,
                    INV_Report.FAC_ID,
                    INV_Report.Report_Type,
                    INV_Report.Report_Date,
                    FAC_Main.FAC_NAME,
                    FAC_Main.C_NO,
                    FAC_Main.ADDR
                FROM INV_Report
                LEFT JOIN FAC_Main ON INV_Report.FAC_ID = FAC_Main.FAC_ID "
                + listWhereSql + @"
                ORDER BY INV_Report.Report_Date DESC, INV_Report.Report_NO DESC
                OFFSET " + offset + " ROWS FETCH NEXT " + pageSize + " ROWS ONLY";

            DataTable dt = null;
            try
            {
                dt = DbHelper.ExecuteDataTable(querySql, listParas.ToArray());
            }
            catch (Exception ex)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "載入列表失敗：" + ex.Message }));
                return;
            }

            var items = new List<object>();
            if (dt != null)
            {
                foreach (DataRow r in dt.Rows)
                {
                    string facId = r["FAC_ID"] != DBNull.Value ? r["FAC_ID"].ToString().Trim() : "";
                    int invNo = 0, repNo = 0;
                    if (r["INV_NO"] != DBNull.Value) int.TryParse(r["INV_NO"].ToString(), out invNo);
                    if (r["Report_NO"] != DBNull.Value) int.TryParse(r["Report_NO"].ToString(), out repNo);

                    // 安全 MD5 Token 計算: ("MD5:" + facId + yyyyMMddHH).ToMD5()
                    string md5Token = ComputeMd5("MD5:" + facId + DateTime.Now.ToString("yyyyMMddHH"));
                    string detailUrl = string.Format("PIC_Report.aspx?mode=read&id={0}&id1={1}&inv={2}&rep={3}",
                        HttpUtility.UrlEncode(facId),
                        md5Token,
                        invNo,
                        repNo);

                    string rptDateStr = "";
                    if (r["Report_Date"] != DBNull.Value)
                    {
                        DateTime d = Convert.ToDateTime(r["Report_Date"]);
                        rptDateStr = d.ToString("yyyy-MM-dd HH:mm");
                    }

                    string town = ExtractTown(r);

                    items.Add(new
                    {
                        pID = r.Table.Columns.Contains("pID") && r["pID"] != DBNull.Value ? Convert.ToInt32(r["pID"]) : repNo,
                        Report_NO = repNo,
                        INV_NO = invNo,
                        FAC_ID = facId,
                        FAC_NAME = r["FAC_NAME"] != DBNull.Value ? r["FAC_NAME"].ToString().Trim() : "未知場所",
                        C_NO = (r.Table.Columns.Contains("C_NO") && r["C_NO"] != DBNull.Value) ? r["C_NO"].ToString().Trim() : "-",
                        ADDR_TOWN = town,
                        TOWN = town,
                        Report_Type = r["Report_Type"] != DBNull.Value ? r["Report_Type"].ToString().Trim() : "自主回報",
                        Report_Date = rptDateStr,
                        DetailUrl = detailUrl
                    });
                }
            }

            int totalPages = (int)Math.Ceiling((double)totalCount / pageSize);

            Response.Write(json.Serialize(new
            {
                Success = true,
                Data = new
                {
                    Items = items,
                    TotalCount = totalCount,
                    PageIndex = pageIndex,
                    PageSize = pageSize,
                    TotalPages = totalPages
                }
            }));
        }

        private void GetPreview()
        {
            string facId = Request["id"];
            int repNo = 0;
            int.TryParse(Request["rep"], out repNo);

            if (string.IsNullOrEmpty(facId) || repNo <= 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "缺少必要參數" }));
                return;
            }

            string sql = @"
                SELECT TOP 1
                    INV_Report.*,
                    FAC_Main.FAC_NAME,
                    FAC_Main.C_NO,
                    FAC_Main.ADDR
                FROM INV_Report
                LEFT JOIN FAC_Main ON INV_Report.FAC_ID = FAC_Main.FAC_ID
                WHERE INV_Report.FAC_ID = @FAC_ID AND INV_Report.Report_NO = @Report_NO";

            SqlParameter[] paras = new SqlParameter[]
            {
                new SqlParameter("@FAC_ID", SqlDbType.VarChar) { Value = facId },
                new SqlParameter("@Report_NO", SqlDbType.Int) { Value = repNo }
            };

            DataTable dt = DbHelper.ExecuteDataTable(sql, paras);
            if (dt == null || dt.Rows.Count == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "找不到該筆回報單" }));
                return;
            }

            DataRow r = dt.Rows[0];
            int invNo = 0;
            if (r["INV_NO"] != DBNull.Value) int.TryParse(r["INV_NO"].ToString(), out invNo);
            string md5Token = ComputeMd5("MD5:" + facId + DateTime.Now.ToString("yyyyMMddHH"));
            string detailUrl = string.Format("PIC_Report.aspx?mode=read&id={0}&id1={1}&inv={2}&rep={3}",
                HttpUtility.UrlEncode(facId),
                md5Token,
                invNo,
                repNo);

            string town = ExtractTown(r);

            Response.Write(json.Serialize(new
            {
                Success = true,
                Data = new
                {
                    Report_NO = repNo,
                    INV_NO = invNo,
                    FAC_ID = facId,
                    FAC_NAME = r["FAC_NAME"] != DBNull.Value ? r["FAC_NAME"].ToString().Trim() : "",
                    C_NO = (r.Table.Columns.Contains("C_NO") && r["C_NO"] != DBNull.Value) ? r["C_NO"].ToString().Trim() : "",
                    ADDR_TOWN = town,
                    TOWN = town,
                    ADDR = (r.Table.Columns.Contains("ADDR") && r["ADDR"] != DBNull.Value) ? r["ADDR"].ToString().Trim() : "",
                    Report_Type = r["Report_Type"] != DBNull.Value ? r["Report_Type"].ToString().Trim() : "",
                    Report_Date = r["Report_Date"] != DBNull.Value ? Convert.ToDateTime(r["Report_Date"]).ToString("yyyy-MM-dd HH:mm") : "",
                    DetailUrl = detailUrl
                }
            }));
        }

        private void ExportExcel()
        {
            SearchFilterModel filter = ParseFilter();
            List<SqlParameter> paras = new List<SqlParameter>();
            string whereSql = BuildWhere(filter, paras);

            string sql = @"
                SELECT 
                    INV_Report.Report_NO,
                    INV_Report.INV_NO,
                    INV_Report.FAC_ID,
                    INV_Report.Report_Type,
                    INV_Report.Report_Date,
                    FAC_Main.FAC_NAME,
                    FAC_Main.C_NO,
                    FAC_Main.ADDR
                FROM INV_Report
                LEFT JOIN FAC_Main ON INV_Report.FAC_ID = FAC_Main.FAC_ID "
                + whereSql + @"
                ORDER BY INV_Report.Report_Date DESC, INV_Report.Report_NO DESC";

            DataTable dt = DbHelper.ExecuteDataTable(sql, paras.ToArray());

            HSSFWorkbook wb = new HSSFWorkbook();
            ISheet sheet = wb.CreateSheet("固定污染源自主與改善回報清單");
            sheet.CreateFreezePane(0, 1);

            ICellStyle headerStyle = CreateHeaderStyle(wb);
            ICellStyle centerStyle = CreateDataStyle(wb, HorizontalAlignment.Center);
            ICellStyle leftStyle = CreateDataStyle(wb, HorizontalAlignment.Left);

            string[] headers = new string[]
            {
                "項次",
                "回報單號",
                "管制編號",
                "公私場所代碼",
                "公私場所名稱",
                "行政區",
                "回報類型",
                "查核單號",
                "回報日期時間"
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
            if (dt != null)
            {
                foreach (DataRow r in dt.Rows)
                {
                    IRow row = sheet.CreateRow(rowIndex);
                    row.HeightInPoints = 20;

                    string rptDateStr = "";
                    if (r["Report_Date"] != DBNull.Value)
                    {
                        rptDateStr = Convert.ToDateTime(r["Report_Date"]).ToString("yyyy-MM-dd HH:mm");
                    }

                    string townStr = ExtractTown(r);

                    // 0: 項次
                    ICell c0 = row.CreateCell(0);
                    c0.SetCellValue(rowIndex);
                    c0.CellStyle = centerStyle;

                    // 1: 回報單號
                    ICell c1 = row.CreateCell(1);
                    c1.SetCellValue(r["Report_NO"] != DBNull.Value ? r["Report_NO"].ToString() : "");
                    c1.CellStyle = centerStyle;

                    // 2: 管制編號
                    ICell c2 = row.CreateCell(2);
                    c2.SetCellValue((r.Table.Columns.Contains("C_NO") && r["C_NO"] != DBNull.Value) ? r["C_NO"].ToString().Trim() : "");
                    c2.CellStyle = centerStyle;

                    // 3: 公私場所代碼
                    ICell c3 = row.CreateCell(3);
                    c3.SetCellValue(r["FAC_ID"] != DBNull.Value ? r["FAC_ID"].ToString().Trim() : "");
                    c3.CellStyle = centerStyle;

                    // 4: 公私場所名稱
                    ICell c4 = row.CreateCell(4);
                    c4.SetCellValue(r["FAC_NAME"] != DBNull.Value ? r["FAC_NAME"].ToString().Trim() : "");
                    c4.CellStyle = leftStyle;

                    // 5: 行政區
                    ICell c5 = row.CreateCell(5);
                    c5.SetCellValue(townStr);
                    c5.CellStyle = centerStyle;

                    // 6: 回報類型
                    ICell c6 = row.CreateCell(6);
                    c6.SetCellValue(r["Report_Type"] != DBNull.Value ? r["Report_Type"].ToString().Trim() : "");
                    c6.CellStyle = centerStyle;

                    // 7: 查核單號
                    ICell c7 = row.CreateCell(7);
                    c7.SetCellValue(r["INV_NO"] != DBNull.Value ? r["INV_NO"].ToString() : "");
                    c7.CellStyle = centerStyle;

                    // 8: 回報日期時間
                    ICell c8 = row.CreateCell(8);
                    c8.SetCellValue(rptDateStr);
                    c8.CellStyle = centerStyle;

                    rowIndex++;
                }
            }

            int[] colWidths = new int[] { 8, 14, 16, 16, 32, 12, 16, 14, 22 };
            for (int i = 0; i < colWidths.Length; i++)
            {
                sheet.SetColumnWidth(i, colWidths[i] * 256);
            }

            string filename = "固定污染源自主與改善回報清單_" + DateTime.Now.ToString("yyyyMMdd_HHmm") + ".xls";
            Response.Clear();
            Response.Buffer = true;
            Response.ContentType = "application/vnd.ms-excel";
            Response.AddHeader("Content-Disposition", "attachment;filename=" + HttpUtility.UrlEncode(filename, Encoding.UTF8));
            Response.ContentEncoding = Encoding.UTF8;

            using (MemoryStream ms = new MemoryStream())
            {
                wb.Write(ms);
                byte[] bytes = ms.ToArray();
                Response.BinaryWrite(bytes);
            }
            Response.Flush();
            Response.End();
        }

        private static string ExtractTown(DataRow r)
        {
            if (r == null) return "-";
            if (r.Table.Columns.Contains("TOWN") && r["TOWN"] != DBNull.Value)
            {
                string t = r["TOWN"].ToString().Trim();
                if (!string.IsNullOrEmpty(t)) return t;
            }
            if (r.Table.Columns.Contains("ADDR") && r["ADDR"] != DBNull.Value)
            {
                string addr = r["ADDR"].ToString().Trim();
                string[] towns = new string[]
                {
                    "板橋區", "三重區", "中和區", "永和區", "新莊區", "新店區", "樹林區", "鶯歌區", "三峽區", "淡水區",
                    "汐止區", "瑞芳區", "土城區", "蘆洲區", "五股區", "泰山區", "林口區", "深坑區", "石碇區", "坪林區",
                    "三芝區", "石門區", "八里區", "平溪區", "雙溪區", "貢寮區", "金山區", "萬里區", "烏來區",
                    "板橋", "三重", "中和", "永和", "新莊", "新店", "樹林", "鶯歌", "三峽", "淡水",
                    "汐止", "瑞芳", "土城", "蘆洲", "五股", "泰山", "林口", "深坑", "石碇", "坪林",
                    "三芝", "石門", "八里", "平溪", "雙溪", "貢寮", "金山", "萬里", "烏來"
                };
                for (int i = 0; i < towns.Length; i++)
                {
                    if (addr.IndexOf(towns[i], StringComparison.OrdinalIgnoreCase) >= 0)
                    {
                        return towns[i].EndsWith("區") ? towns[i] : (towns[i] + "區");
                    }
                }
            }
            return "-";
        }

        private static ICellStyle CreateHeaderStyle(IWorkbook wb)
        {
            ICellStyle style = wb.CreateCellStyle();
            style.Alignment = HorizontalAlignment.Center;
            style.VerticalAlignment = VerticalAlignment.Center;
            style.FillForegroundColor = NPOI.HSSF.Util.HSSFColor.Grey25Percent.Index;
            style.FillPattern = FillPattern.SolidForeground;
            style.BorderTop = BorderStyle.Thin;
            style.BorderBottom = BorderStyle.Thin;
            style.BorderLeft = BorderStyle.Thin;
            style.BorderRight = BorderStyle.Thin;

            IFont font = wb.CreateFont();
            font.FontName = "微軟正黑體";
            font.FontHeightInPoints = 11;
            font.IsBold = true;
            style.SetFont(font);
            return style;
        }

        private static ICellStyle CreateDataStyle(IWorkbook wb, HorizontalAlignment align)
        {
            ICellStyle style = wb.CreateCellStyle();
            style.Alignment = align;
            style.VerticalAlignment = VerticalAlignment.Center;
            style.BorderTop = BorderStyle.Thin;
            style.BorderBottom = BorderStyle.Thin;
            style.BorderLeft = BorderStyle.Thin;
            style.BorderRight = BorderStyle.Thin;

            IFont font = wb.CreateFont();
            font.FontName = "微軟正黑體";
            font.FontHeightInPoints = 10;
            style.SetFont(font);
            return style;
        }

        private static string ComputeMd5(string input)
        {
            if (string.IsNullOrEmpty(input)) return "";
            using (MD5 md5 = MD5.Create())
            {
                byte[] bytes = Encoding.UTF8.GetBytes(input);
                byte[] hash = md5.ComputeHash(bytes);
                StringBuilder sb = new StringBuilder();
                for (int i = 0; i < hash.Length; i++)
                {
                    sb.Append(hash[i].ToString("X2"));
                }
                return sb.ToString();
            }
        }
    }
}
