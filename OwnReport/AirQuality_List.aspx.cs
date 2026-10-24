using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Text;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.UI;
using Newtonsoft.Json;
using NPOI.HSSF.UserModel;
using NPOI.HSSF.Util;
using NPOI.SS.UserModel;
using NTPC_FEC.Helpers;
using NTPC_FEC.Models;
using NTPC_FEC.Services;

namespace NTPC_FEC.OwnReport
{
    public partial class AirQuality_List : Page
    {
        private JavaScriptSerializer jsonSerializer;

        public AirQuality_List()
        {
            jsonSerializer = new JavaScriptSerializer();
            jsonSerializer.MaxJsonLength = int.MaxValue;
        }

        #region 資料模型 (遵循 C# 5.0，無自動屬性初始化)

        public class ResponseModel
        {
            public bool Success { get; set; }
            public string Message { get; set; }
            public object Data { get; set; }
        }

        public class FacOptionModel
        {
            public string FacId { get; set; }
            public string CNo { get; set; }
            public string FacName { get; set; }
            public string TownName { get; set; }
        }

        public class AirQualityItemModel
        {
            public int pIndex { get; set; }
            public string FAC_ID { get; set; }
            public string County { get; set; }
            public string C_NO { get; set; }
            public string CNAM { get; set; }
            public string OverDate { get; set; }
            public string ContentType { get; set; }
            public string Status { get; set; }
            public string Less { get; set; }
            public string LessMe { get; set; }
            public string NoReason { get; set; }
            public string RunTimeStart { get; set; }
            public string RunTimeEnd { get; set; }
            public string TSP { get; set; }
            public string PM10 { get; set; }
            public string PM25 { get; set; }
            public string SOx { get; set; }
            public string NOx { get; set; }
            public string VOCs { get; set; }
            public string InputUser { get; set; }
            public string CreateDate { get; set; }
            public string EditDate { get; set; }
            public bool CanEdit { get; set; }
            public bool CanDelete { get; set; }
        }

        public class StatsSummaryModel
        {
            public int TotalCount { get; set; }
            public int LessYesCount { get; set; }
            public int LessNoCount { get; set; }
            public double ComplianceRate { get; set; }
            public double TotalTSP { get; set; }
            public double TotalPM10 { get; set; }
            public double TotalPM25 { get; set; }
            public double TotalSOx { get; set; }
            public double TotalNOx { get; set; }
            public double TotalVOCs { get; set; }
        }

        public class InitDataPackage
        {
            public bool IsManager { get; set; }
            public string CurrentUser { get; set; }
            public string UserFacId { get; set; }
            public string UserFacName { get; set; }
            public string DefaultDateStart { get; set; }
            public string DefaultDateEnd { get; set; }
            public List<FacOptionModel> FacList { get; set; }

            public InitDataPackage()
            {
                FacList = new List<FacOptionModel>();
            }
        }

        public class ListResultPackage
        {
            public int TotalCount { get; set; }
            public int PageIndex { get; set; }
            public int PageSize { get; set; }
            public int TotalPages { get; set; }
            public List<AirQualityItemModel> Items { get; set; }
            public StatsSummaryModel Stats { get; set; }

            public ListResultPackage()
            {
                Items = new List<AirQualityItemModel>();
                Stats = new StatsSummaryModel();
            }
        }

        public class SearchFilterCriteria
        {
            public string FacId { get; set; }
            public string DateStart { get; set; }
            public string DateEnd { get; set; }
            public string ContentType { get; set; }
            public string Status { get; set; }
            public string Less { get; set; }
            public string Keyword { get; set; }
            public int PageIndex { get; set; }
            public int PageSize { get; set; }

            public SearchFilterCriteria()
            {
                FacId = "ALL";
                DateStart = "";
                DateEnd = "";
                ContentType = "ALL";
                Status = "ALL";
                Less = "ALL";
                Keyword = "";
                PageIndex = 1;
                PageSize = 20;
            }
        }

        #endregion

        protected override void Render(HtmlTextWriter writer)
        {
            // 若為 AJAX API 或 Excel 匯出請求，阻斷頁面 HTML Render 輸出
            if (!string.IsNullOrEmpty(Request["action"]))
            {
                return;
            }
            base.Render(writer);
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            string action = Request["action"];
            if (!string.IsNullOrEmpty(action))
            {
                action = action.ToLower().Trim();

                if (string.Equals(action, "exportexcel", StringComparison.OrdinalIgnoreCase))
                {
                    try
                    {
                        ExportExcel();
                    }
                    catch (System.Threading.ThreadAbortException)
                    {
                        return;
                    }
                    catch (Exception ex)
                    {
                        Response.Clear();
                        Response.ContentType = "text/html; charset=utf-8";
                        Response.Write("<script>alert('匯出 Excel 失敗：" + HttpUtility.JavaScriptStringEncode(ex.Message) + "'); window.close();</script>");
                    }
                    try
                    {
                        Response.End();
                    }
                    catch (System.Threading.ThreadAbortException)
                    {
                        return;
                    }
                    return;
                }

                Response.Clear();
                Response.ContentType = "application/json; charset=utf-8";
                try
                {
                    HandleAjaxAction(action);
                }
                catch (System.Threading.ThreadAbortException)
                {
                    return;
                }
                catch (Exception ex)
                {
                    Response.Write(jsonSerializer.Serialize(new ResponseModel
                    {
                        Success = false,
                        Message = "系統處理失敗：" + ex.Message
                    }));
                }

                try
                {
                    Response.End();
                }
                catch (System.Threading.ThreadAbortException)
                {
                    return;
                }
                return;
            }
        }

        private void HandleAjaxAction(string action)
        {
            switch (action)
            {
                case "getinitdata":
                    GetInitData();
                    break;
                case "getlist":
                    GetList();
                    break;
                case "getdetail":
                    GetDetail();
                    break;
                case "delete":
                    DeleteReport();
                    break;
                default:
                    Response.Write(jsonSerializer.Serialize(new ResponseModel
                    {
                        Success = false,
                        Message = "未知的 API 操作指令：" + action
                    }));
                    break;
            }
        }

        #region 使用者角色與權限判斷

        private bool CheckIsManager(out string currentUser, out string userFacId, out string userFacName)
        {
            currentUser = Session["LoginUser"] != null ? Session["LoginUser"].ToString().Trim() : "";
            userFacId = "";
            userFacName = "";

            bool isManager = false;

            try
            {
                UserAccount uAcc = AuthService.GetCurrentUser(Context);
                if (uAcc != null)
                {
                    if (string.IsNullOrEmpty(currentUser) && !string.IsNullOrEmpty(uAcc.UserID))
                    {
                        currentUser = uAcc.UserID.Trim();
                    }

                    if ((uAcc.Lic & (1L << 16)) != 0 || (uAcc.Lic & (1L << 63)) != 0 || string.IsNullOrEmpty(uAcc.FacID))
                    {
                        isManager = true;
                    }
                    if (!string.IsNullOrEmpty(uAcc.FacID))
                    {
                        userFacId = uAcc.FacID.Trim();
                    }
                }
            }
            catch
            {
            }

            if (!string.IsNullOrEmpty(currentUser) && string.IsNullOrEmpty(userFacId))
            {
                try
                {
                    string sql = "SELECT TOP 1 LIC, FAC_ID FROM UserAcc WHERE UserID = @UserID";
                    SqlParameter[] p = new SqlParameter[]
                    {
                        new SqlParameter("@UserID", SqlDbType.VarChar) { Value = currentUser }
                    };
                    DataTable dt = DbHelper.ExecuteDataTable(sql, p);
                    if (dt != null && dt.Rows.Count > 0)
                    {
                        DataRow r = dt.Rows[0];
                        long licVal = 0;
                        if (r["LIC"] != DBNull.Value) long.TryParse(r["LIC"].ToString(), out licVal);
                        if ((licVal & (1L << 16)) != 0 || (licVal & (1L << 63)) != 0)
                        {
                            isManager = true;
                        }

                        if (r["FAC_ID"] != DBNull.Value && !string.IsNullOrEmpty(r["FAC_ID"].ToString().Trim()))
                        {
                            userFacId = r["FAC_ID"].ToString().Trim();
                        }
                    }
                }
                catch
                {
                }
            }

            if (string.IsNullOrEmpty(userFacId) && Session["User_FAC_ID"] != null)
            {
                userFacId = Session["User_FAC_ID"].ToString().Trim();
            }

            // 若為廠商業者，查詢工廠名稱
            if (!string.IsNullOrEmpty(userFacId))
            {
                try
                {
                    string sql = "SELECT TOP 1 FAC_NAME FROM FAC_Main WHERE FAC_ID = @FAC_ID";
                    SqlParameter[] p = new SqlParameter[]
                    {
                        new SqlParameter("@FAC_ID", SqlDbType.VarChar) { Value = userFacId }
                    };
                    DataTable dt = DbHelper.ExecuteDataTable(sql, p);
                    if (dt != null && dt.Rows.Count > 0 && dt.Rows[0]["FAC_NAME"] != DBNull.Value)
                    {
                        userFacName = dt.Rows[0]["FAC_NAME"].ToString().Trim();
                    }
                }
                catch
                {
                }
            }

            return isManager;
        }

        #endregion

        #region AJAX: 初始化取得基礎資料 (GetInitData)

        private void GetInitData()
        {
            string currentUser, userFacId, userFacName;
            bool isManager = CheckIsManager(out currentUser, out userFacId, out userFacName);

            InitDataPackage pkg = new InitDataPackage();
            pkg.IsManager = isManager;
            pkg.CurrentUser = currentUser;
            pkg.UserFacId = userFacId;
            pkg.UserFacName = userFacName;
            pkg.DefaultDateStart = DateTime.Today.AddMonths(-1).ToString("yyyy-MM-dd");
            pkg.DefaultDateEnd = DateTime.Today.ToString("yyyy-MM-dd");

            try
            {
                if (isManager)
                {
                    // 管理員可檢視全部場所
                    FacOptionModel allOpt = new FacOptionModel();
                    allOpt.FacId = "ALL";
                    allOpt.CNo = "";
                    allOpt.FacName = "< 全部公私場所 >";
                    allOpt.TownName = "";
                    pkg.FacList.Add(allOpt);

                    string sql = @"
                        SELECT f.FAC_ID, f.C_NO, f.FAC_NAME, t.TOWN_NA 
                        FROM FAC_Main f 
                        LEFT JOIN C_TOWN t ON f.TOWN_CODE = t.TOWN_NO 
                        WHERE f.FAC_ID IS NOT NULL AND f.FAC_NAME IS NOT NULL
                        ORDER BY f.FAC_NAME";
                    DataTable dt = DbHelper.ExecuteDataTable(sql);
                    if (dt != null)
                    {
                        foreach (DataRow r in dt.Rows)
                        {
                            FacOptionModel item = new FacOptionModel();
                            item.FacId = r["FAC_ID"] != DBNull.Value ? r["FAC_ID"].ToString().Trim() : "";
                            item.CNo = r["C_NO"] != DBNull.Value ? r["C_NO"].ToString().Trim() : "";
                            item.FacName = r["FAC_NAME"] != DBNull.Value ? r["FAC_NAME"].ToString().Trim() : "";
                            item.TownName = r["TOWN_NA"] != DBNull.Value ? r["TOWN_NA"].ToString().Trim() : "";
                            pkg.FacList.Add(item);
                        }
                    }
                }
                else
                {
                    // 業者帳號僅能查詢自身工廠
                    if (!string.IsNullOrEmpty(userFacId))
                    {
                        FacOptionModel item = new FacOptionModel();
                        item.FacId = userFacId;
                        item.CNo = "";
                        item.FacName = !string.IsNullOrEmpty(userFacName) ? userFacName : userFacId;
                        item.TownName = "";

                        string sql = @"
                            SELECT TOP 1 f.FAC_ID, f.C_NO, f.FAC_NAME, t.TOWN_NA 
                            FROM FAC_Main f 
                            LEFT JOIN C_TOWN t ON f.TOWN_CODE = t.TOWN_NO 
                            WHERE f.FAC_ID = @FAC_ID";
                        SqlParameter[] p = new SqlParameter[]
                        {
                            new SqlParameter("@FAC_ID", SqlDbType.VarChar) { Value = userFacId }
                        };
                        DataTable dt = DbHelper.ExecuteDataTable(sql, p);
                        if (dt != null && dt.Rows.Count > 0)
                        {
                            DataRow r = dt.Rows[0];
                            item.CNo = r["C_NO"] != DBNull.Value ? r["C_NO"].ToString().Trim() : "";
                            item.FacName = r["FAC_NAME"] != DBNull.Value ? r["FAC_NAME"].ToString().Trim() : item.FacName;
                            item.TownName = r["TOWN_NA"] != DBNull.Value ? r["TOWN_NA"].ToString().Trim() : "";
                        }
                        pkg.FacList.Add(item);
                    }
                }
            }
            catch (Exception ex)
            {
                Response.Write(jsonSerializer.Serialize(new ResponseModel
                {
                    Success = false,
                    Message = "載入工廠列表失敗：" + ex.Message
                }));
                return;
            }

            Response.Write(jsonSerializer.Serialize(new ResponseModel
            {
                Success = true,
                Message = "OK",
                Data = pkg
            }));
        }

        #endregion

        #region 查詢條件解析與 SQL 構建

        private SearchFilterCriteria ParseCriteria()
        {
            SearchFilterCriteria c = new SearchFilterCriteria();

            string fac = Request["facId"];
            if (!string.IsNullOrEmpty(fac)) c.FacId = fac.Trim();

            string ds = Request["dateStart"];
            if (!string.IsNullOrEmpty(ds)) c.DateStart = ds.Trim();

            string de = Request["dateEnd"];
            if (!string.IsNullOrEmpty(de)) c.DateEnd = de.Trim();

            string ct = Request["contentType"];
            if (!string.IsNullOrEmpty(ct)) c.ContentType = ct.Trim();

            string st = Request["status"];
            if (!string.IsNullOrEmpty(st)) c.Status = st.Trim();

            string less = Request["less"];
            if (!string.IsNullOrEmpty(less)) c.Less = less.Trim();

            string kw = Request["keyword"];
            if (!string.IsNullOrEmpty(kw)) c.Keyword = kw.Trim();

            int pIdx;
            if (int.TryParse(Request["pageIndex"], out pIdx) && pIdx > 0) c.PageIndex = pIdx;

            int pSize;
            if (int.TryParse(Request["pageSize"], out pSize) && pSize > 0) c.PageSize = pSize;

            return c;
        }

        private string BuildWhereClause(SearchFilterCriteria c, bool isManager, string userFacId, List<SqlParameter> paramList)
        {
            StringBuilder sb = new StringBuilder(" 1=1 ");

            // 權限限制：非管理員強制鎖定自身工廠
            if (!isManager)
            {
                sb.Append(" AND r.FAC_ID = @UserFacId ");
                paramList.Add(new SqlParameter("@UserFacId", SqlDbType.VarChar) { Value = userFacId });
            }
            else
            {
                // 管理員選取特定場所
                if (!string.IsNullOrEmpty(c.FacId) && c.FacId != "ALL")
                {
                    sb.Append(" AND r.FAC_ID = @FilterFacId ");
                    paramList.Add(new SqlParameter("@FilterFacId", SqlDbType.VarChar) { Value = c.FacId });
                }
            }

            // 應變日期起
            if (!string.IsNullOrEmpty(c.DateStart))
            {
                DateTime dtStart;
                if (DateTime.TryParse(c.DateStart, out dtStart))
                {
                    sb.Append(" AND r.OverDate >= @DateStart ");
                    paramList.Add(new SqlParameter("@DateStart", SqlDbType.Date) { Value = dtStart.Date });
                }
            }

            // 應變日期訖
            if (!string.IsNullOrEmpty(c.DateEnd))
            {
                DateTime dtEnd;
                if (DateTime.TryParse(c.DateEnd, out dtEnd))
                {
                    sb.Append(" AND r.OverDate <= @DateEnd ");
                    paramList.Add(new SqlParameter("@DateEnd", SqlDbType.Date) { Value = dtEnd.Date });
                }
            }

            // 通知方式
            if (!string.IsNullOrEmpty(c.ContentType) && c.ContentType != "ALL")
            {
                sb.Append(" AND r.ContentType = @ContentType ");
                paramList.Add(new SqlParameter("@ContentType", SqlDbType.NVarChar, 50) { Value = c.ContentType });
            }

            // 操作狀況
            if (!string.IsNullOrEmpty(c.Status) && c.Status != "ALL")
            {
                sb.Append(" AND r.Status = @Status ");
                paramList.Add(new SqlParameter("@Status", SqlDbType.NVarChar, 50) { Value = c.Status });
            }

            // 配合執行減排
            if (!string.IsNullOrEmpty(c.Less) && c.Less != "ALL")
            {
                if (c.Less == "是" || c.Less == "Y")
                {
                    sb.Append(" AND (r.Less = '是' OR r.Less = 'Y') ");
                }
                else
                {
                    sb.Append(" AND (r.Less = '否' OR r.Less = 'N' OR r.Less IS NULL) ");
                }
            }

            // 關鍵字搜尋 (場所名稱、管制編號、具體措施、未配合原因)
            if (!string.IsNullOrEmpty(c.Keyword))
            {
                sb.Append(" AND (r.CNAM LIKE @Kw OR r.C_NO LIKE @Kw OR r.LessMe LIKE @Kw OR r.NoReason LIKE @Kw) ");
                paramList.Add(new SqlParameter("@Kw", SqlDbType.NVarChar, 100) { Value = "%" + c.Keyword + "%" });
            }

            return sb.ToString();
        }

        #endregion

        #region AJAX: 分頁查詢清單與統計 (GetList)

        private void GetList()
        {
            string currentUser, userFacId, userFacName;
            bool isManager = CheckIsManager(out currentUser, out userFacId, out userFacName);

            SearchFilterCriteria criteria = ParseCriteria();
            List<SqlParameter> paramList = new List<SqlParameter>();
            string whereSql = BuildWhereClause(criteria, isManager, userFacId, paramList);

            ListResultPackage result = new ListResultPackage();
            result.PageIndex = criteria.PageIndex;
            result.PageSize = criteria.PageSize;

            try
            {
                // 1. 查詢符合筆數與削減量 KPI 統計 (採用相容所有 SQL Server 版本的 ISNUMERIC 轉換)
                string statsSql = @"
                    SELECT 
                        COUNT(1) AS TotalCount,
                        SUM(CASE WHEN r.Less = '是' OR r.Less = 'Y' THEN 1 ELSE 0 END) AS LessYesCount,
                        SUM(CASE WHEN r.Less = '否' OR r.Less = 'N' THEN 1 ELSE 0 END) AS LessNoCount,
                        SUM(CASE WHEN ISNUMERIC(r.TSP) = 1 THEN CAST(r.TSP AS float) ELSE 0 END) AS SumTSP,
                        SUM(CASE WHEN ISNUMERIC(r.PM10) = 1 THEN CAST(r.PM10 AS float) ELSE 0 END) AS SumPM10,
                        SUM(CASE WHEN ISNUMERIC(r.PM25) = 1 THEN CAST(r.PM25 AS float) ELSE 0 END) AS SumPM25,
                        SUM(CASE WHEN ISNUMERIC(r.SOx) = 1 THEN CAST(r.SOx AS float) ELSE 0 END) AS SumSOx,
                        SUM(CASE WHEN ISNUMERIC(r.NOx) = 1 THEN CAST(r.NOx AS float) ELSE 0 END) AS SumNOx,
                        SUM(CASE WHEN ISNUMERIC(r.VOCs) = 1 THEN CAST(r.VOCs AS float) ELSE 0 END) AS SumVOCs
                    FROM OverReport_TypeA_1 r
                    WHERE " + whereSql;

                DataTable dtStats = DbHelper.ExecuteDataTable(statsSql, paramList.ToArray());
                if (dtStats != null && dtStats.Rows.Count > 0)
                {
                    DataRow sr = dtStats.Rows[0];
                    result.TotalCount = sr["TotalCount"] != DBNull.Value ? Convert.ToInt32(sr["TotalCount"]) : 0;

                    StatsSummaryModel s = new StatsSummaryModel();
                    s.TotalCount = result.TotalCount;
                    s.LessYesCount = sr["LessYesCount"] != DBNull.Value ? Convert.ToInt32(sr["LessYesCount"]) : 0;
                    s.LessNoCount = sr["LessNoCount"] != DBNull.Value ? Convert.ToInt32(sr["LessNoCount"]) : 0;
                    s.ComplianceRate = s.TotalCount > 0 ? Math.Round((double)s.LessYesCount * 100.0 / (double)s.TotalCount, 1) : 0;
                    s.TotalTSP = sr["SumTSP"] != DBNull.Value ? Math.Round(Convert.ToDouble(sr["SumTSP"]), 2) : 0;
                    s.TotalPM10 = sr["SumPM10"] != DBNull.Value ? Math.Round(Convert.ToDouble(sr["SumPM10"]), 2) : 0;
                    s.TotalPM25 = sr["SumPM25"] != DBNull.Value ? Math.Round(Convert.ToDouble(sr["SumPM25"]), 2) : 0;
                    s.TotalSOx = sr["SumSOx"] != DBNull.Value ? Math.Round(Convert.ToDouble(sr["SumSOx"]), 2) : 0;
                    s.TotalNOx = sr["SumNOx"] != DBNull.Value ? Math.Round(Convert.ToDouble(sr["SumNOx"]), 2) : 0;
                    s.TotalVOCs = sr["SumVOCs"] != DBNull.Value ? Math.Round(Convert.ToDouble(sr["SumVOCs"]), 2) : 0;
                    result.Stats = s;
                }

                result.TotalPages = result.TotalCount > 0 ? (int)Math.Ceiling((double)result.TotalCount / (double)criteria.PageSize) : 0;

                // 2. 分頁資料查詢 (OFFSET-FETCH)
                int offset = (criteria.PageIndex - 1) * criteria.PageSize;
                string querySql = @"
                    SELECT 
                        r.pIndex,
                        r.FAC_ID,
                        r.County,
                        r.C_NO,
                        r.CNAM,
                        r.OverDate,
                        r.ContentType,
                        r.Status,
                        r.Less,
                        r.LessMe,
                        r.NoReason,
                        r.S_DATE,
                        r.E_DATE,
                        r.TSP,
                        r.PM10,
                        r.PM25,
                        r.SOx,
                        r.NOx,
                        r.VOCs,
                        r.InputUser,
                        r.CreateDate,
                        r.EditDate
                    FROM OverReport_TypeA_1 r
                    WHERE " + whereSql + @"
                    ORDER BY r.OverDate DESC, r.pIndex DESC
                    OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY";

                List<SqlParameter> pageParams = new List<SqlParameter>(paramList);
                pageParams.Add(new SqlParameter("@Offset", SqlDbType.Int) { Value = offset });
                pageParams.Add(new SqlParameter("@PageSize", SqlDbType.Int) { Value = criteria.PageSize });

                DataTable dtList = DbHelper.ExecuteDataTable(querySql, pageParams.ToArray());
                if (dtList != null)
                {
                    foreach (DataRow row in dtList.Rows)
                    {
                        AirQualityItemModel item = FormatItemFromRow(row, isManager, userFacId);
                        result.Items.Add(item);
                    }
                }
            }
            catch (Exception ex)
            {
                Response.Write(jsonSerializer.Serialize(new ResponseModel
                {
                    Success = false,
                    Message = "查詢資料失敗：" + ex.Message
                }));
                return;
            }

            Response.Write(jsonSerializer.Serialize(new ResponseModel
            {
                Success = true,
                Message = "OK",
                Data = result
            }));
        }

        private AirQualityItemModel FormatItemFromRow(DataRow row, bool isManager, string userFacId)
        {
            AirQualityItemModel item = new AirQualityItemModel();
            item.pIndex = row["pIndex"] != DBNull.Value ? Convert.ToInt32(row["pIndex"]) : 0;
            item.FAC_ID = row["FAC_ID"] != DBNull.Value ? row["FAC_ID"].ToString().Trim() : "";
            item.County = row["County"] != DBNull.Value ? row["County"].ToString().Trim() : "";
            item.C_NO = row["C_NO"] != DBNull.Value ? row["C_NO"].ToString().Trim() : "";
            item.CNAM = row["CNAM"] != DBNull.Value ? row["CNAM"].ToString().Trim() : "";

            if (row["OverDate"] != DBNull.Value)
            {
                DateTime dt;
                if (DateTime.TryParse(row["OverDate"].ToString(), out dt))
                {
                    item.OverDate = dt.ToString("yyyy-MM-dd");
                }
            }
            if (string.IsNullOrEmpty(item.OverDate)) item.OverDate = "--";

            item.ContentType = row["ContentType"] != DBNull.Value ? row["ContentType"].ToString().Trim() : "";
            item.Status = row["Status"] != DBNull.Value ? row["Status"].ToString().Trim() : "";
            item.Less = row["Less"] != DBNull.Value ? row["Less"].ToString().Trim() : "";
            item.LessMe = row["LessMe"] != DBNull.Value ? row["LessMe"].ToString().Replace("<br />", "\r\n").Trim() : "";
            item.NoReason = row["NoReason"] != DBNull.Value ? row["NoReason"].ToString().Trim() : "";

            if (row["S_DATE"] != DBNull.Value)
            {
                DateTime dtS;
                if (DateTime.TryParse(row["S_DATE"].ToString(), out dtS)) item.RunTimeStart = dtS.ToString("HH:mm");
            }
            if (string.IsNullOrEmpty(item.RunTimeStart)) item.RunTimeStart = "--:--";

            if (row["E_DATE"] != DBNull.Value)
            {
                DateTime dtE;
                if (DateTime.TryParse(row["E_DATE"].ToString(), out dtE)) item.RunTimeEnd = dtE.ToString("HH:mm");
            }
            if (string.IsNullOrEmpty(item.RunTimeEnd)) item.RunTimeEnd = "--:--";

            item.TSP = FormatDoubleString(row["TSP"]);
            item.PM10 = FormatDoubleString(row["PM10"]);
            item.PM25 = FormatDoubleString(row["PM25"]);
            item.SOx = FormatDoubleString(row["SOx"]);
            item.NOx = FormatDoubleString(row["NOx"]);
            item.VOCs = FormatDoubleString(row["VOCs"]);

            item.InputUser = row["InputUser"] != DBNull.Value ? row["InputUser"].ToString().Trim() : "";

            if (row["CreateDate"] != DBNull.Value)
            {
                DateTime dtC;
                if (DateTime.TryParse(row["CreateDate"].ToString(), out dtC)) item.CreateDate = dtC.ToString("yyyy-MM-dd HH:mm");
            }
            if (row["EditDate"] != DBNull.Value)
            {
                DateTime dtEd;
                if (DateTime.TryParse(row["EditDate"].ToString(), out dtEd)) item.EditDate = dtEd.ToString("yyyy-MM-dd HH:mm");
            }

            // 權限：管理員或該工廠自身資料皆可編輯、刪除
            item.CanEdit = isManager || (!string.IsNullOrEmpty(userFacId) && userFacId == item.FAC_ID);
            item.CanDelete = isManager || (!string.IsNullOrEmpty(userFacId) && userFacId == item.FAC_ID);

            return item;
        }

        private static string FormatDoubleString(object obj)
        {
            if (obj == null || obj == DBNull.Value) return "0";
            double val;
            if (double.TryParse(obj.ToString(), out val))
            {
                return val.ToString("0.##");
            }
            return "0";
        }

        #endregion

        #region AJAX: 取得案件詳細資料 (GetDetail)

        private void GetDetail()
        {
            int pIndex;
            if (!int.TryParse(Request["id"], out pIndex) || pIndex <= 0)
            {
                Response.Write(jsonSerializer.Serialize(new ResponseModel
                {
                    Success = false,
                    Message = "無效的案件編號"
                }));
                return;
            }

            string currentUser, userFacId, userFacName;
            bool isManager = CheckIsManager(out currentUser, out userFacId, out userFacName);

            try
            {
                string sql = @"
                    SELECT TOP 1 
                        r.*,
                        f.ADDR,
                        t.TOWN_NA
                    FROM OverReport_TypeA_1 r
                    LEFT JOIN FAC_Main f ON r.FAC_ID = f.FAC_ID
                    LEFT JOIN C_TOWN t ON f.TOWN_CODE = t.TOWN_NO
                    WHERE r.pIndex = @pIndex";

                SqlParameter[] p = new SqlParameter[]
                {
                    new SqlParameter("@pIndex", SqlDbType.Int) { Value = pIndex }
                };

                DataTable dt = DbHelper.ExecuteDataTable(sql, p);
                if (dt == null || dt.Rows.Count == 0)
                {
                    Response.Write(jsonSerializer.Serialize(new ResponseModel
                    {
                        Success = false,
                        Message = "查無此應變回報單資料"
                    }));
                    return;
                }

                DataRow r = dt.Rows[0];
                AirQualityItemModel item = FormatItemFromRow(r, isManager, userFacId);

                // 權限檢核：非管理員且非自身工廠案件禁止檢視
                if (!isManager && !string.IsNullOrEmpty(userFacId) && item.FAC_ID != userFacId)
                {
                    Response.Write(jsonSerializer.Serialize(new ResponseModel
                    {
                        Success = false,
                        Message = "您沒有檢視此案件的權限！"
                    }));
                    return;
                }

                string addr = (r.Table.Columns.Contains("ADDR") && r["ADDR"] != DBNull.Value) ? r["ADDR"].ToString().Trim() : ((r.Table.Columns.Contains("FAC_ADDR") && r["FAC_ADDR"] != DBNull.Value) ? r["FAC_ADDR"].ToString().Trim() : "");
                string town = r["TOWN_NA"] != DBNull.Value ? r["TOWN_NA"].ToString().Trim() : item.County;

                var detailPkg = new
                {
                    Item = item,
                    Address = addr,
                    TownName = town
                };

                Response.Write(jsonSerializer.Serialize(new ResponseModel
                {
                    Success = true,
                    Message = "OK",
                    Data = detailPkg
                }));
            }
            catch (Exception ex)
            {
                Response.Write(jsonSerializer.Serialize(new ResponseModel
                {
                    Success = false,
                    Message = "取得案件明細失敗：" + ex.Message
                }));
            }
        }

        #endregion

        #region AJAX: 刪除案件 (DeleteReport)

        private void DeleteReport()
        {
            int pIndex;
            if (!int.TryParse(Request["id"], out pIndex) || pIndex <= 0)
            {
                Response.Write(jsonSerializer.Serialize(new ResponseModel
                {
                    Success = false,
                    Message = "未指定欲刪除的案件編號"
                }));
                return;
            }

            string currentUser, userFacId, userFacName;
            bool isManager = CheckIsManager(out currentUser, out userFacId, out userFacName);

            try
            {
                string checkSql = "SELECT TOP 1 FAC_ID, CNAM, OverDate FROM OverReport_TypeA_1 WHERE pIndex = @pIndex";
                SqlParameter[] checkP = new SqlParameter[]
                {
                    new SqlParameter("@pIndex", SqlDbType.Int) { Value = pIndex }
                };
                DataTable dtCheck = DbHelper.ExecuteDataTable(checkSql, checkP);
                if (dtCheck == null || dtCheck.Rows.Count == 0)
                {
                    Response.Write(jsonSerializer.Serialize(new ResponseModel
                    {
                        Success = false,
                        Message = "欲刪除的案件不存在或已被移除"
                    }));
                    return;
                }

                string facId = dtCheck.Rows[0]["FAC_ID"] != DBNull.Value ? dtCheck.Rows[0]["FAC_ID"].ToString().Trim() : "";

                // 權限檢查
                if (!isManager && !string.IsNullOrEmpty(userFacId) && facId != userFacId)
                {
                    Response.Write(jsonSerializer.Serialize(new ResponseModel
                    {
                        Success = false,
                        Message = "您無權刪除其他公私場所之回報單！"
                    }));
                    return;
                }

                string delSql = "DELETE FROM OverReport_TypeA_1 WHERE pIndex = @pIndex";
                SqlParameter[] delP = new SqlParameter[]
                {
                    new SqlParameter("@pIndex", SqlDbType.Int) { Value = pIndex }
                };
                int affected = DbHelper.ExecuteNonQuery(delSql, delP);

                if (affected > 0)
                {
                    Response.Write(jsonSerializer.Serialize(new ResponseModel
                    {
                        Success = true,
                        Message = "應變回報單已成功刪除！"
                    }));
                }
                else
                {
                    Response.Write(jsonSerializer.Serialize(new ResponseModel
                    {
                        Success = false,
                        Message = "刪除失敗，該筆記錄可能已異動"
                    }));
                }
            }
            catch (Exception ex)
            {
                Response.Write(jsonSerializer.Serialize(new ResponseModel
                {
                    Success = false,
                    Message = "執行刪除時發生錯誤：" + ex.Message
                }));
            }
        }

        #endregion

        #region 原生 NPOI Excel (.xls) 匯出功能

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
            string currentUser, userFacId, userFacName;
            bool isManager = CheckIsManager(out currentUser, out userFacId, out userFacName);

            SearchFilterCriteria criteria = ParseCriteria();
            List<SqlParameter> paramList = new List<SqlParameter>();
            string whereSql = BuildWhereClause(criteria, isManager, userFacId, paramList);

            string sql = @"
                SELECT 
                    r.pIndex,
                    r.FAC_ID,
                    r.County,
                    r.C_NO,
                    r.CNAM,
                    r.OverDate,
                    r.ContentType,
                    r.Status,
                    r.Less,
                    r.LessMe,
                    r.NoReason,
                    r.S_DATE,
                    r.E_DATE,
                    r.TSP,
                    r.PM10,
                    r.PM25,
                    r.SOx,
                    r.NOx,
                    r.VOCs,
                    r.InputUser,
                    r.CreateDate,
                    r.EditDate
                FROM OverReport_TypeA_1 r
                WHERE " + whereSql + @"
                ORDER BY r.OverDate DESC, r.pIndex DESC";

            DataTable dt = DbHelper.ExecuteDataTable(sql, paramList.ToArray());

            HSSFWorkbook wb = new HSSFWorkbook();
            ISheet sheet = wb.CreateSheet("空品不良應變回報清單");

            ICellStyle headerStyle = CreateHeaderStyle(wb);
            ICellStyle centerStyle = CreateDataStyle(wb, HorizontalAlignment.Center);
            ICellStyle leftStyle = CreateDataStyle(wb, HorizontalAlignment.Left);
            ICellStyle rightStyle = CreateDataStyle(wb, HorizontalAlignment.Right);

            string[] headers = new string[]
            {
                "項次",
                "應變日期",
                "管制編號",
                "公私場所名稱",
                "行政區",
                "通知方式",
                "操作狀況",
                "配合減排",
                "具體減排措施 / 未配合原因",
                "執行起訖時間",
                "TSP (kg)",
                "PM10 (kg)",
                "PM2.5 (kg)",
                "SOx (kg)",
                "NOx (kg)",
                "VOCs (kg)",
                "填報人員",
                "建立時間",
                "修改時間"
            };

            IRow hRow = sheet.CreateRow(0);
            hRow.HeightInPoints = 26;
            for (int i = 0; i < headers.Length; i++)
            {
                ICell c = hRow.CreateCell(i);
                c.SetCellValue(headers[i]);
                c.CellStyle = headerStyle;
            }

            int rowIdx = 1;
            if (dt != null)
            {
                foreach (DataRow r in dt.Rows)
                {
                    IRow row = sheet.CreateRow(rowIdx);
                    row.HeightInPoints = 22;

                    AirQualityItemModel item = FormatItemFromRow(r, isManager, userFacId);

                    string reasonOrMeasure = item.Less == "是" ? item.LessMe : item.NoReason;
                    string runTime = item.RunTimeStart + " ~ " + item.RunTimeEnd;

                    // 0: 項次
                    ICell c0 = row.CreateCell(0); c0.SetCellValue(rowIdx); c0.CellStyle = centerStyle;
                    // 1: 應變日期
                    ICell c1 = row.CreateCell(1); c1.SetCellValue(item.OverDate); c1.CellStyle = centerStyle;
                    // 2: 管制編號
                    ICell c2 = row.CreateCell(2); c2.SetCellValue(item.C_NO); c2.CellStyle = centerStyle;
                    // 3: 公私場所名稱
                    ICell c3 = row.CreateCell(3); c3.SetCellValue(item.CNAM); c3.CellStyle = leftStyle;
                    // 4: 行政區
                    ICell c4 = row.CreateCell(4); c4.SetCellValue(item.County); c4.CellStyle = centerStyle;
                    // 5: 通知方式
                    ICell c5 = row.CreateCell(5); c5.SetCellValue(item.ContentType); c5.CellStyle = centerStyle;
                    // 6: 操作狀況
                    ICell c6 = row.CreateCell(6); c6.SetCellValue(item.Status); c6.CellStyle = centerStyle;
                    // 7: 配合減排
                    ICell c7 = row.CreateCell(7); c7.SetCellValue(item.Less); c7.CellStyle = centerStyle;
                    // 8: 措施/原因
                    ICell c8 = row.CreateCell(8); c8.SetCellValue(reasonOrMeasure); c8.CellStyle = leftStyle;
                    // 9: 執行時間
                    ICell c9 = row.CreateCell(9); c9.SetCellValue(runTime); c9.CellStyle = centerStyle;
                    // 10: TSP
                    ICell c10 = row.CreateCell(10); c10.SetCellValue(item.TSP); c10.CellStyle = rightStyle;
                    // 11: PM10
                    ICell c11 = row.CreateCell(11); c11.SetCellValue(item.PM10); c11.CellStyle = rightStyle;
                    // 12: PM2.5
                    ICell c12 = row.CreateCell(12); c12.SetCellValue(item.PM25); c12.CellStyle = rightStyle;
                    // 13: SOx
                    ICell c13 = row.CreateCell(13); c13.SetCellValue(item.SOx); c13.CellStyle = rightStyle;
                    // 14: NOx
                    ICell c14 = row.CreateCell(14); c14.SetCellValue(item.NOx); c14.CellStyle = rightStyle;
                    // 15: VOCs
                    ICell c15 = row.CreateCell(15); c15.SetCellValue(item.VOCs); c15.CellStyle = rightStyle;
                    // 16: 填報人員
                    ICell c16 = row.CreateCell(16); c16.SetCellValue(item.InputUser); c16.CellStyle = centerStyle;
                    // 17: 建立時間
                    ICell c17 = row.CreateCell(17); c17.SetCellValue(item.CreateDate ?? ""); c17.CellStyle = centerStyle;
                    // 18: 修改時間
                    ICell c18 = row.CreateCell(18); c18.SetCellValue(item.EditDate ?? ""); c18.CellStyle = centerStyle;

                    rowIdx++;
                }
            }

            // 自動欄寬與安全最小寬度
            for (int i = 0; i < headers.Length; i++)
            {
                sheet.AutoSizeColumn(i);
                int curWidth = sheet.GetColumnWidth(i);
                if (curWidth < 12 * 256) sheet.SetColumnWidth(i, 12 * 256);
                if (curWidth > 45 * 256) sheet.SetColumnWidth(i, 45 * 256);
            }

            string fileName = "AirQuality_Report_List_" + DateTime.Now.ToString("yyyyMMddHHmmss") + ".xls";
            Response.Clear();
            Response.Buffer = true;
            Response.ContentType = "application/vnd.ms-excel";
            Response.AddHeader("Content-Disposition", "attachment;filename=" + HttpUtility.UrlEncode(fileName, Encoding.UTF8));

            using (MemoryStream ms = new MemoryStream())
            {
                wb.Write(ms);
                Response.BinaryWrite(ms.ToArray());
            }

            Response.Flush();
            Response.End();
        }

        #endregion
    }
}
