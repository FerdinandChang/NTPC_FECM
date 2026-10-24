using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Text;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.UI;
using NTPC_FEC.Helpers;

namespace NTPC_FEC.Machine
{
    public partial class macList : Page
    {
        private JavaScriptSerializer json;

        public macList()
        {
            json = new JavaScriptSerializer();
            json.MaxJsonLength = int.MaxValue;
        }

        public class SearchFilterModel
        {
            public string Mode { get; set; }
            public string ViewType { get; set; } // "fac" 或 "mac"
            public string FacName { get; set; }
            public string CNo { get; set; }
            public string ScId { get; set; }
            public string Town { get; set; }
            public string MacType { get; set; }
            public string Brand { get; set; }
            public string Model { get; set; }
            public string Pin { get; set; }
            public string EngineNo { get; set; }
            public string DateS { get; set; }
            public string DateE { get; set; }
            public string OutYearS { get; set; }
            public string OutYearE { get; set; }
            public string AvgOpaqueS { get; set; }
            public string AvgOpaqueE { get; set; }
            public double GpsLat { get; set; }
            public double GpsLng { get; set; }
            public int PageIndex { get; set; }
            public int PageSize { get; set; }

            public SearchFilterModel()
            {
                Mode = "";
                ViewType = "fac";
                FacName = "";
                CNo = "";
                ScId = "";
                Town = "";
                MacType = "";
                Brand = "";
                Model = "";
                Pin = "";
                EngineNo = "";
                DateS = "";
                DateE = "";
                OutYearS = "";
                OutYearE = "";
                AvgOpaqueS = "";
                AvgOpaqueE = "";
                GpsLat = 0;
                GpsLng = 0;
                PageIndex = 1;
                PageSize = 20;
            }
        }

        protected override void Render(HtmlTextWriter writer)
        {
            // 若為 AJAX 請求則完全阻斷 ASP.NET Render 流程，避免 HTML 追加於 JSON 後方造成前端解析失敗
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
                    Response.Clear();
                    Response.ContentType = "application/json; charset=utf-8";
                    Response.Write(json.Serialize(new
                    {
                        Success = false,
                        Message = "執行錯誤：" + ex.Message
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

        private string GetCurrentUser()
        {
            if (Session["LoginUser"] != null && !string.IsNullOrEmpty(Session["LoginUser"].ToString()))
            {
                return Session["LoginUser"].ToString().Trim();
            }
            if (User != null && User.Identity != null && !string.IsNullOrEmpty(User.Identity.Name))
            {
                return User.Identity.Name;
            }
            return "系統使用者";
        }

        private void HandleAjaxAction(string action)
        {
            switch (action.ToLower())
            {
                case "getinit":
                    GetInitData();
                    break;
                case "getcounts":
                    GetCounts();
                    break;
                case "getfaclist":
                    GetFacList();
                    break;
                case "getmaclist":
                    GetMacList();
                    break;
                case "getfacdetail":
                    GetFacDetail();
                    break;
                case "submitcheck":
                    SubmitCheck();
                    break;
                case "deletemac":
                    DeleteMac();
                    break;
                case "exportcsv":
                    ExportCsv();
                    break;
                default:
                    Response.Write(json.Serialize(new { Success = false, Message = "未知的指令：" + action }));
                    break;
            }
        }

        // 1. 初始化基礎選單資料
        private void GetInitData()
        {
            var towns = new List<object>();

            try
            {
                string sqlTown = "SELECT TOWN_NO, TOWN_NA FROM C_TOWN WHERE COUNTRY = 'F' ORDER BY TOWN_NO";
                DataTable dtTown = DbHelper.ExecuteDataTable(sqlTown);
                foreach (DataRow row in dtTown.Rows)
                {
                    towns.Add(new
                    {
                        TownNo = row["TOWN_NO"].ToString().Trim(),
                        TownName = row["TOWN_NA"].ToString().Trim()
                    });
                }
            }
            catch
            {
                string[,] defaultTowns = new string[,]
                {
                    {"6500100", "板橋區"}, {"6500200", "三重區"}, {"6500300", "中和區"}, {"6500400", "永和區"},
                    {"6500500", "新莊區"}, {"6500600", "新店區"}, {"6500700", "樹林區"}, {"6500800", "鶯歌區"},
                    {"6500900", "三峽區"}, {"6501000", "淡水區"}, {"6501100", "汐止區"}, {"6501200", "瑞芳區"},
                    {"6501300", "土城區"}, {"6501400", "蘆洲區"}, {"6501500", "五股區"}, {"6501600", "泰山區"},
                    {"6501700", "林口區"}, {"6501800", "深坑區"}, {"6501900", "石碇區"}, {"6502000", "坪林區"},
                    {"6502100", "三芝區"}, {"6502200", "石門區"}, {"6502300", "八里區"}, {"6502400", "平溪區"},
                    {"6502500", "雙溪區"}, {"6502600", "貢寮區"}, {"6502700", "金山區"}, {"6502800", "萬里區"},
                    {"6502900", "烏來區"}
                };
                for (int i = 0; i < defaultTowns.GetLength(0); i++)
                {
                    towns.Add(new { TownNo = defaultTowns[i, 0], TownName = defaultTowns[i, 1] });
                }
            }

            // 常見施工機具種類清單
            var macTypes = new string[] {
                "挖土機", "推土機", "鏟裝機", "壓路機", "起重機", "發電機", "堆高機", "平路機", "鑽孔機", "破碎機", "其他"
            };

            var counts = QueryCounts();

            Response.Write(json.Serialize(new
            {
                Success = true,
                Data = new
                {
                    CurrentUser = GetCurrentUser(),
                    Towns = towns,
                    MacTypes = macTypes,
                    Counts = counts,
                    Mode = Request["mode"] != null ? Request["mode"].ToString().Trim().ToLower() : ""
                }
            }));
        }

        // 2. 取得案件統計計數
        private void GetCounts()
        {
            var counts = QueryCounts();
            Response.Write(json.Serialize(new
            {
                Success = true,
                Data = counts
            }));
        }

        private Dictionary<string, int> QueryCounts()
        {
            var result = new Dictionary<string, int>();
            result["TotalFac"] = 0;
            result["TotalMac"] = 0;
            result["DraftMac"] = 0;
            result["SubmittedMac"] = 0;
            result["SearchFac"] = 0;

            try
            {
                // 統計機具台數
                string sqlMac = @"
                    SELECT 
                        COUNT(*) AS TotalMac,
                        SUM(CASE WHEN Mac_State IN ('A00a', 'A00b') OR Mac_State IS NULL THEN 1 ELSE 0 END) AS DraftMac,
                        SUM(CASE WHEN Mac_State = 'A00' THEN 1 ELSE 0 END) AS SubmittedMac
                    FROM Machine_Main
                    WHERE Deleted_mac IS NULL OR Deleted_mac <> 'Y'";
                DataTable dtMac = DbHelper.ExecuteDataTable(sqlMac);
                if (dtMac.Rows.Count > 0)
                {
                    DataRow r = dtMac.Rows[0];
                    result["TotalMac"] = r["TotalMac"] != DBNull.Value ? Convert.ToInt32(r["TotalMac"]) : 0;
                    result["DraftMac"] = r["DraftMac"] != DBNull.Value ? Convert.ToInt32(r["DraftMac"]) : 0;
                    result["SubmittedMac"] = r["SubmittedMac"] != DBNull.Value ? Convert.ToInt32(r["SubmittedMac"]) : 0;
                }

                // 統計場所數
                string sqlFac = @"
                    SELECT 
                        COUNT(*) AS TotalFac,
                        COUNT(DISTINCT m.FAC_ID) AS SearchFac
                    FROM FAC_Main f
                    LEFT JOIN Machine_Main m ON f.FAC_ID = m.FAC_ID AND (m.Deleted_mac IS NULL OR m.Deleted_mac <> 'Y')";
                DataTable dtFac = DbHelper.ExecuteDataTable(sqlFac);
                if (dtFac.Rows.Count > 0)
                {
                    DataRow r = dtFac.Rows[0];
                    result["TotalFac"] = r["TotalFac"] != DBNull.Value ? Convert.ToInt32(r["TotalFac"]) : 0;
                    result["SearchFac"] = r["SearchFac"] != DBNull.Value ? Convert.ToInt32(r["SearchFac"]) : 0;
                }
            }
            catch
            {
            }

            return result;
        }

        // 3. 取得場所列表 (以場所為聚合單位)
        private void GetFacList()
        {
            SearchFilterModel filter = ParseFilter();
            List<SqlParameter> pars = new List<SqlParameter>();
            StringBuilder whereFac = new StringBuilder(" WHERE 1=1 ");
            StringBuilder whereMac = new StringBuilder(" WHERE (m.Deleted_mac IS NULL OR m.Deleted_mac <> 'Y') ");

            // 模式過濾
            if (filter.Mode == "reject")
            {
                whereMac.Append(" AND (m.Mac_State IN ('A00a', 'A00b') OR m.Mac_State IS NULL) ");
            }

            // 場所條件
            if (!string.IsNullOrEmpty(filter.FacName))
            {
                whereFac.Append(" AND f.FAC_NAME LIKE @facName ");
                pars.Add(new SqlParameter("@facName", "%" + filter.FacName + "%"));
            }
            if (!string.IsNullOrEmpty(filter.CNo))
            {
                whereFac.Append(" AND f.C_NO LIKE @cNo ");
                pars.Add(new SqlParameter("@cNo", "%" + filter.CNo + "%"));
            }
            if (!string.IsNullOrEmpty(filter.ScId))
            {
                whereFac.Append(" AND f.S_C_ID LIKE @scId ");
                pars.Add(new SqlParameter("@scId", "%" + filter.ScId + "%"));
            }
            if (!string.IsNullOrEmpty(filter.Town))
            {
                whereFac.Append(" AND (ct.TOWN_NA LIKE @town OR f.TOWN_CODE = @town) ");
                pars.Add(new SqlParameter("@town", "%" + filter.Town + "%"));
            }

            // 機具條件過濾
            bool hasMacFilter = false;
            if (!string.IsNullOrEmpty(filter.MacType))
            {
                whereMac.Append(" AND m.mac_Type LIKE @macType ");
                pars.Add(new SqlParameter("@macType", "%" + filter.MacType + "%"));
                hasMacFilter = true;
            }
            if (!string.IsNullOrEmpty(filter.Brand))
            {
                whereMac.Append(" AND m.Brand LIKE @brand ");
                pars.Add(new SqlParameter("@brand", "%" + filter.Brand + "%"));
                hasMacFilter = true;
            }
            if (!string.IsNullOrEmpty(filter.Model))
            {
                whereMac.Append(" AND m.model LIKE @model ");
                pars.Add(new SqlParameter("@model", "%" + filter.Model + "%"));
                hasMacFilter = true;
            }
            if (!string.IsNullOrEmpty(filter.Pin))
            {
                whereMac.Append(" AND m.PIN LIKE @pin ");
                pars.Add(new SqlParameter("@pin", "%" + filter.Pin + "%"));
                hasMacFilter = true;
            }
            if (!string.IsNullOrEmpty(filter.EngineNo))
            {
                whereMac.Append(" AND m.Engine_NO LIKE @engineNo ");
                pars.Add(new SqlParameter("@engineNo", "%" + filter.EngineNo + "%"));
                hasMacFilter = true;
            }
            if (!string.IsNullOrEmpty(filter.DateS))
            {
                DateTime dtS;
                if (DateTime.TryParse(filter.DateS, out dtS))
                {
                    whereMac.Append(" AND m.Check_date >= @dateS ");
                    pars.Add(new SqlParameter("@dateS", dtS));
                    hasMacFilter = true;
                }
            }
            if (!string.IsNullOrEmpty(filter.DateE))
            {
                DateTime dtE;
                if (DateTime.TryParse(filter.DateE, out dtE))
                {
                    whereMac.Append(" AND m.Check_date <= @dateE ");
                    pars.Add(new SqlParameter("@dateE", dtE));
                    hasMacFilter = true;
                }
            }
            if (!string.IsNullOrEmpty(filter.OutYearS))
            {
                whereMac.Append(" AND m.OUT_YEAR >= @outYearS ");
                pars.Add(new SqlParameter("@outYearS", filter.OutYearS));
                hasMacFilter = true;
            }
            if (!string.IsNullOrEmpty(filter.OutYearE))
            {
                whereMac.Append(" AND m.OUT_YEAR <= @outYearE ");
                pars.Add(new SqlParameter("@outYearE", filter.OutYearE));
                hasMacFilter = true;
            }
            if (!string.IsNullOrEmpty(filter.AvgOpaqueS))
            {
                whereMac.Append(" AND (ISNULL(m.opaque_Run1, 0) + ISNULL(m.opaque_Run2, 0) + ISNULL(m.opaque_Run3, 0)) / 3.0 >= @avgOpaqueS ");
                pars.Add(new SqlParameter("@avgOpaqueS", Convert.ToDouble(filter.AvgOpaqueS)));
                hasMacFilter = true;
            }
            if (!string.IsNullOrEmpty(filter.AvgOpaqueE))
            {
                whereMac.Append(" AND (ISNULL(m.opaque_Run1, 0) + ISNULL(m.opaque_Run2, 0) + ISNULL(m.opaque_Run3, 0)) / 3.0 <= @avgOpaqueE ");
                pars.Add(new SqlParameter("@avgOpaqueE", Convert.ToDouble(filter.AvgOpaqueE)));
                hasMacFilter = true;
            }

            // 若在 mode == "search" (調查成果) 或有篩選機具條件，則只顯示有機具的場所
            string joinType = (filter.Mode == "search" || filter.Mode == "reject" || hasMacFilter) ? "INNER JOIN" : "LEFT JOIN";

            // 構建統計與分頁查詢 (透過 C_TOWN 取得 TOWN_NA)
            string countSql = string.Format(@"
                SELECT COUNT(DISTINCT f.FAC_ID)
                FROM FAC_Main f
                LEFT JOIN C_TOWN ct ON f.TOWN_CODE = ct.TOWN_NO
                {0} (
                    SELECT FAC_ID FROM Machine_Main m {1}
                ) mc ON f.FAC_ID = mc.FAC_ID
                {2}", joinType, whereMac.ToString(), whereFac.ToString());

            int totalRows = 0;
            try
            {
                object cntObj = DbHelper.ExecuteScalar(countSql, CloneParameters(pars));
                if (cntObj != null && cntObj != DBNull.Value)
                {
                    totalRows = Convert.ToInt32(cntObj);
                }
            }
            catch (Exception ex)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "計算總數失敗：" + ex.Message }));
                return;
            }

            int startRow = (filter.PageIndex - 1) * filter.PageSize + 1;
            int endRow = filter.PageIndex * filter.PageSize;

            string pageSql = string.Format(@"
                WITH FacCTE AS (
                    SELECT 
                        f.FAC_ID,
                        f.C_NO,
                        f.FAC_NAME,
                        ISNULL(ct.TOWN_NA, '-') AS TOWN_NA,
                        ISNULL(ind.INDUSTRIAL_Name, '-') AS Industrial,
                        f.S_C_ID,
                        ISNULL(f.FAC_Type, '-') AS FAC_Type,
                        f.ADDR,
                        ISNULL(macCountTbl.MacCount, 0) AS MacCount,
                        ROW_NUMBER() OVER (ORDER BY ISNULL(macCountTbl.MacCount, 0) DESC, f.FAC_ID DESC) AS RowNum
                    FROM FAC_Main f
                    LEFT JOIN C_TOWN ct ON f.TOWN_CODE = ct.TOWN_NO
                    LEFT JOIN INDUSTRIAL_Data ind ON f.INDUSTRIAL_Code1 = ind.INDUSTRIAL_Code
                    {0} (
                        SELECT FAC_ID, COUNT(*) AS MacCount 
                        FROM Machine_Main m 
                        {1}
                        GROUP BY FAC_ID
                    ) macCountTbl ON f.FAC_ID = macCountTbl.FAC_ID
                    {2}
                )
                SELECT * FROM FacCTE WHERE RowNum BETWEEN @startRow AND @endRow",
                joinType, whereMac.ToString(), whereFac.ToString());

            pars.Add(new SqlParameter("@startRow", startRow));
            pars.Add(new SqlParameter("@endRow", endRow));

            DataTable dt = null;
            try
            {
                dt = DbHelper.ExecuteDataTable(pageSql, pars.ToArray());
            }
            catch (Exception ex)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "查詢清單失敗：" + ex.Message }));
                return;
            }

            var list = new List<object>();
            foreach (DataRow r in dt.Rows)
            {
                list.Add(new
                {
                    FAC_ID = r["FAC_ID"].ToString().Trim(),
                    C_NO = r["C_NO"] != DBNull.Value ? r["C_NO"].ToString().Trim() : "-",
                    FAC_NAME = r["FAC_NAME"] != DBNull.Value ? r["FAC_NAME"].ToString().Trim() : "-",
                    TOWN_NA = r["TOWN_NA"] != DBNull.Value ? r["TOWN_NA"].ToString().Trim() : "-",
                    Industrial = r["Industrial"] != DBNull.Value ? r["Industrial"].ToString().Trim() : "-",
                    S_C_ID = r["S_C_ID"] != DBNull.Value ? r["S_C_ID"].ToString().Trim() : "-",
                    FAC_Type1 = r["FAC_Type"] != DBNull.Value ? r["FAC_Type"].ToString().Trim() : "-",
                    ADDR = r["ADDR"] != DBNull.Value ? r["ADDR"].ToString().Trim() : "-",
                    MacCount = Convert.ToInt32(r["MacCount"])
                });
            }

            int totalPages = (int)Math.Ceiling((double)totalRows / (double)filter.PageSize);

            Response.Write(json.Serialize(new
            {
                Success = true,
                Data = new
                {
                    Items = list,
                    TotalRows = totalRows,
                    TotalPages = totalPages,
                    PageIndex = filter.PageIndex,
                    PageSize = filter.PageSize
                }
            }));
        }

        // 4. 取得機具巡查清單 (以單台機具為展開單位)
        private void GetMacList()
        {
            SearchFilterModel filter = ParseFilter();
            List<SqlParameter> pars = new List<SqlParameter>();
            StringBuilder where = new StringBuilder(" WHERE (m.Deleted_mac IS NULL OR m.Deleted_mac <> 'Y') ");

            // 模式過濾
            if (filter.Mode == "reject")
            {
                where.Append(" AND (m.Mac_State IN ('A00a', 'A00b') OR m.Mac_State IS NULL) ");
            }

            // 條件組合
            if (!string.IsNullOrEmpty(filter.FacName))
            {
                where.Append(" AND f.FAC_NAME LIKE @facName ");
                pars.Add(new SqlParameter("@facName", "%" + filter.FacName + "%"));
            }
            if (!string.IsNullOrEmpty(filter.CNo))
            {
                where.Append(" AND f.C_NO LIKE @cNo ");
                pars.Add(new SqlParameter("@cNo", "%" + filter.CNo + "%"));
            }
            if (!string.IsNullOrEmpty(filter.ScId))
            {
                where.Append(" AND f.S_C_ID LIKE @scId ");
                pars.Add(new SqlParameter("@scId", "%" + filter.ScId + "%"));
            }
            if (!string.IsNullOrEmpty(filter.Town))
            {
                where.Append(" AND (ct.TOWN_NA LIKE @town OR f.TOWN_CODE = @town) ");
                pars.Add(new SqlParameter("@town", "%" + filter.Town + "%"));
            }
            if (!string.IsNullOrEmpty(filter.MacType))
            {
                where.Append(" AND m.mac_Type LIKE @macType ");
                pars.Add(new SqlParameter("@macType", "%" + filter.MacType + "%"));
            }
            if (!string.IsNullOrEmpty(filter.Brand))
            {
                where.Append(" AND m.Brand LIKE @brand ");
                pars.Add(new SqlParameter("@brand", "%" + filter.Brand + "%"));
            }
            if (!string.IsNullOrEmpty(filter.Model))
            {
                where.Append(" AND m.model LIKE @model ");
                pars.Add(new SqlParameter("@model", "%" + filter.Model + "%"));
            }
            if (!string.IsNullOrEmpty(filter.Pin))
            {
                where.Append(" AND m.PIN LIKE @pin ");
                pars.Add(new SqlParameter("@pin", "%" + filter.Pin + "%"));
            }
            if (!string.IsNullOrEmpty(filter.EngineNo))
            {
                where.Append(" AND m.Engine_NO LIKE @engineNo ");
                pars.Add(new SqlParameter("@engineNo", "%" + filter.EngineNo + "%"));
            }
            if (!string.IsNullOrEmpty(filter.DateS))
            {
                DateTime dtS;
                if (DateTime.TryParse(filter.DateS, out dtS))
                {
                    where.Append(" AND m.Check_date >= @dateS ");
                    pars.Add(new SqlParameter("@dateS", dtS));
                }
            }
            if (!string.IsNullOrEmpty(filter.DateE))
            {
                DateTime dtE;
                if (DateTime.TryParse(filter.DateE, out dtE))
                {
                    where.Append(" AND m.Check_date <= @dateE ");
                    pars.Add(new SqlParameter("@dateE", dtE));
                }
            }
            if (!string.IsNullOrEmpty(filter.OutYearS))
            {
                where.Append(" AND m.OUT_YEAR >= @outYearS ");
                pars.Add(new SqlParameter("@outYearS", filter.OutYearS));
            }
            if (!string.IsNullOrEmpty(filter.OutYearE))
            {
                where.Append(" AND m.OUT_YEAR <= @outYearE ");
                pars.Add(new SqlParameter("@outYearE", filter.OutYearE));
            }
            if (!string.IsNullOrEmpty(filter.AvgOpaqueS))
            {
                where.Append(" AND (ISNULL(m.opaque_Run1, 0) + ISNULL(m.opaque_Run2, 0) + ISNULL(m.opaque_Run3, 0)) / 3.0 >= @avgOpaqueS ");
                pars.Add(new SqlParameter("@avgOpaqueS", Convert.ToDouble(filter.AvgOpaqueS)));
            }
            if (!string.IsNullOrEmpty(filter.AvgOpaqueE))
            {
                where.Append(" AND (ISNULL(m.opaque_Run1, 0) + ISNULL(m.opaque_Run2, 0) + ISNULL(m.opaque_Run3, 0)) / 3.0 <= @avgOpaqueE ");
                pars.Add(new SqlParameter("@avgOpaqueE", Convert.ToDouble(filter.AvgOpaqueE)));
            }

            string countSql = @"
                SELECT COUNT(*) 
                FROM Machine_Main m 
                LEFT JOIN FAC_Main f ON m.FAC_ID = f.FAC_ID 
                LEFT JOIN C_TOWN ct ON f.TOWN_CODE = ct.TOWN_NO " + where.ToString();
            int totalRows = 0;
            try
            {
                object cntObj = DbHelper.ExecuteScalar(countSql, CloneParameters(pars));
                if (cntObj != null && cntObj != DBNull.Value)
                {
                    totalRows = Convert.ToInt32(cntObj);
                }
            }
            catch (Exception ex)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "計算總數失敗：" + ex.Message }));
                return;
            }

            int startRow = (filter.PageIndex - 1) * filter.PageSize + 1;
            int endRow = filter.PageIndex * filter.PageSize;

            string pageSql = string.Format(@"
                WITH MacCTE AS (
                    SELECT 
                        m.FAC_ID,
                        m.mac_ID,
                        m.Check_date,
                        m.mac_Type,
                        m.Brand,
                        m.model,
                        m.OUT_YEAR,
                        m.PIN,
                        m.Engine_NO,
                        m.Mac_State,
                        ROUND((ISNULL(m.opaque_Run1, 0) + ISNULL(m.opaque_Run2, 0) + ISNULL(m.opaque_Run3, 0)) / 3.0, 2) AS opaque_Run_AVG,
                        f.FAC_NAME,
                        f.C_NO,
                        ISNULL(ct.TOWN_NA, '-') AS TOWN_NA,
                        ROW_NUMBER() OVER (ORDER BY m.Check_date DESC, m.FAC_ID DESC, m.mac_ID DESC) AS RowNum
                    FROM Machine_Main m
                    LEFT JOIN FAC_Main f ON m.FAC_ID = f.FAC_ID
                    LEFT JOIN C_TOWN ct ON f.TOWN_CODE = ct.TOWN_NO
                    {0}
                )
                SELECT * FROM MacCTE WHERE RowNum BETWEEN @startRow AND @endRow", where.ToString());

            pars.Add(new SqlParameter("@startRow", startRow));
            pars.Add(new SqlParameter("@endRow", endRow));

            DataTable dt = null;
            try
            {
                dt = DbHelper.ExecuteDataTable(pageSql, pars.ToArray());
            }
            catch (Exception ex)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "查詢機具失敗：" + ex.Message }));
                return;
            }

            var list = new List<object>();
            foreach (DataRow r in dt.Rows)
            {
                string checkDateStr = "";
                if (r["Check_date"] != DBNull.Value)
                {
                    checkDateStr = Convert.ToDateTime(r["Check_date"]).ToString("yyyy/MM/dd");
                }

                string macState = r["Mac_State"] != DBNull.Value ? r["Mac_State"].ToString().Trim() : "A00a";

                list.Add(new
                {
                    FAC_ID = r["FAC_ID"].ToString().Trim(),
                    mac_ID = Convert.ToInt32(r["mac_ID"]),
                    Check_date = checkDateStr,
                    mac_Type = r["mac_Type"] != DBNull.Value ? r["mac_Type"].ToString().Trim() : "-",
                    Brand = r["Brand"] != DBNull.Value ? r["Brand"].ToString().Trim() : "-",
                    model = r["model"] != DBNull.Value ? r["model"].ToString().Trim() : "-",
                    OUT_YEAR = r["OUT_YEAR"] != DBNull.Value ? r["OUT_YEAR"].ToString().Trim() : "-",
                    PIN = r["PIN"] != DBNull.Value ? r["PIN"].ToString().Trim() : "-",
                    Engine_NO = r["Engine_NO"] != DBNull.Value ? r["Engine_NO"].ToString().Trim() : "-",
                    Mac_State = macState,
                    Mac_State_Text = GetStateText(macState),
                    opaque_Run_AVG = r["opaque_Run_AVG"] != DBNull.Value ? Convert.ToDecimal(r["opaque_Run_AVG"]).ToString("0.00") : "-",
                    FAC_NAME = r["FAC_NAME"] != DBNull.Value ? r["FAC_NAME"].ToString().Trim() : "-",
                    C_NO = r["C_NO"] != DBNull.Value ? r["C_NO"].ToString().Trim() : "-",
                    TOWN_NA = r["TOWN_NA"] != DBNull.Value ? r["TOWN_NA"].ToString().Trim() : "-"
                });
            }

            int totalPages = (int)Math.Ceiling((double)totalRows / (double)filter.PageSize);

            Response.Write(json.Serialize(new
            {
                Success = true,
                Data = new
                {
                    Items = list,
                    TotalRows = totalRows,
                    TotalPages = totalPages,
                    PageIndex = filter.PageIndex,
                    PageSize = filter.PageSize
                }
            }));
        }

        private static string GetStateText(string state)
        {
            if (string.IsNullOrEmpty(state)) return "暫存待送審";
            switch (state.Trim())
            {
                case "A00a":
                case "A00b":
                    return "暫存/駁回待修";
                case "A00":
                    return "已送出審核";
                case "A01":
                    return "初審核可";
                case "A02":
                    return "複審核可";
                default:
                    return state;
            }
        }

        private static string SafeCol(DataRow r, string colName, string defaultVal)
        {
            if (r == null || !r.Table.Columns.Contains(colName) || r[colName] == DBNull.Value)
            {
                return defaultVal;
            }
            string v = r[colName].ToString().Trim();
            return string.IsNullOrEmpty(v) ? defaultVal : v;
        }

        // 5. 取得特定場所的基本資料與其機具清單
        private void GetFacDetail()
        {
            string facId = Request["facId"];
            if (string.IsNullOrEmpty(facId))
            {
                facId = "";
            }

            object facInfo = null;
            try
            {
                // 使用 f.* 配合 LEFT JOIN，杜絕特定未定義欄位導致 SQL 報錯
                string sqlFac = @"
                    SELECT TOP 1 
                        f.*,
                        ISNULL(ct.TOWN_NA, '-') AS TownName_Join,
                        ISNULL(ind.INDUSTRIAL_Name, '-') AS Industrial_Join
                    FROM FAC_Main f
                    LEFT JOIN C_TOWN ct ON f.TOWN_CODE = ct.TOWN_NO
                    LEFT JOIN INDUSTRIAL_Data ind ON f.INDUSTRIAL_Code1 = ind.INDUSTRIAL_Code
                    WHERE f.FAC_ID = @facId";
                DataTable dtFac = DbHelper.ExecuteDataTable(sqlFac, new SqlParameter("@facId", facId));
                if (dtFac != null && dtFac.Rows.Count > 0)
                {
                    DataRow r = dtFac.Rows[0];
                    string facType = SafeCol(r, "FAC_Type1", SafeCol(r, "FAC_Type", "-"));
                    string townNa = SafeCol(r, "TownName_Join", SafeCol(r, "TOWN_NA", "-"));
                    string indNa = SafeCol(r, "Industrial_Join", SafeCol(r, "INDUSTRIAL_Name", "-"));
                    string landNo = SafeCol(r, "Land_NO", SafeCol(r, "Land_no", "-"));
                    string bossName = SafeCol(r, "BOSS_NAME", SafeCol(r, "Boss_Name", "-"));
                    string contentName = SafeCol(r, "Content_Name", "-");
                    string tel = SafeCol(r, "TEL", "-");
                    string fax = SafeCol(r, "FAX", "-");
                    string scId = SafeCol(r, "S_C_ID", "-");
                    string licNo = SafeCol(r, "Lic_NO", "-");
                    string addr = SafeCol(r, "ADDR", "-");
                    string cNo = SafeCol(r, "C_NO", "-");
                    string facName = SafeCol(r, "FAC_NAME", "-");

                    facInfo = new
                    {
                        FAC_ID = r["FAC_ID"] != DBNull.Value ? r["FAC_ID"].ToString().Trim() : facId,
                        C_NO = cNo,
                        FAC_NAME = facName,
                        ADDR = addr,
                        Land_NO = landNo,
                        FAX = fax,
                        TEL = tel,
                        S_C_ID = scId,
                        Lic_NO = licNo,
                        BOSS_NAME = bossName,
                        Content_Name = contentName,
                        TOWN_NA = townNa,
                        Industrial = indNa,
                        FAC_Type1 = facType
                    };
                }
            }
            catch (Exception)
            {
                // 若場所主檔查詢失敗，記錄但不中斷，轉為 Fallback 模式讓機具仍可被檢視
                facInfo = null;
            }

            // Fallback: 若場所資料庫無主檔或查詢失敗，自動建構預設場所資訊，確保所屬機具依然可被檢視
            if (facInfo == null)
            {
                facInfo = new
                {
                    FAC_ID = facId,
                    C_NO = "-",
                    FAC_NAME = string.IsNullOrEmpty(facId) ? "新增場所" : "公私場所 (" + facId + ")",
                    ADDR = "-",
                    Land_NO = "-",
                    FAX = "-",
                    TEL = "-",
                    S_C_ID = "-",
                    Lic_NO = "-",
                    BOSS_NAME = "-",
                    Content_Name = "-",
                    TOWN_NA = "-",
                    Industrial = "-",
                    FAC_Type1 = "-"
                };
            }

            var macList = new List<object>();
            try
            {
                string sqlMac = @"
                    SELECT 
                        mac_ID,
                        Check_date,
                        mac_Type,
                        Brand,
                        model,
                        OUT_YEAR,
                        PIN,
                        Engine_NO,
                        Mac_State,
                        ROUND((ISNULL(opaque_Run1, 0) + ISNULL(opaque_Run2, 0) + ISNULL(opaque_Run3, 0)) / 3.0, 2) AS opaque_Run_AVG
                    FROM Machine_Main
                    WHERE (FAC_ID = @facId OR (@facId = '' AND (FAC_ID IS NULL OR FAC_ID = '')))
                      AND (Deleted_mac IS NULL OR Deleted_mac <> 'Y')
                    ORDER BY Check_date DESC, mac_ID DESC";
                DataTable dtMac = DbHelper.ExecuteDataTable(sqlMac, new SqlParameter("@facId", facId));
                if (dtMac != null)
                {
                    foreach (DataRow r in dtMac.Rows)
                    {
                        string checkDateStr = "";
                        if (r["Check_date"] != DBNull.Value)
                        {
                            checkDateStr = Convert.ToDateTime(r["Check_date"]).ToString("yyyy/MM/dd");
                        }
                        string state = r["Mac_State"] != DBNull.Value ? r["Mac_State"].ToString().Trim() : "A00a";

                        macList.Add(new
                        {
                            mac_ID = Convert.ToInt32(r["mac_ID"]),
                            Check_date = checkDateStr,
                            mac_Type = r["mac_Type"] != DBNull.Value ? r["mac_Type"].ToString().Trim() : "-",
                            Brand = r["Brand"] != DBNull.Value ? r["Brand"].ToString().Trim() : "-",
                            model = r["model"] != DBNull.Value ? r["model"].ToString().Trim() : "-",
                            OUT_YEAR = r["OUT_YEAR"] != DBNull.Value ? r["OUT_YEAR"].ToString().Trim() : "-",
                            PIN = r["PIN"] != DBNull.Value ? r["PIN"].ToString().Trim() : "-",
                            Engine_NO = r["Engine_NO"] != DBNull.Value ? r["Engine_NO"].ToString().Trim() : "-",
                            Mac_State = state,
                            Mac_State_Text = GetStateText(state),
                            opaque_Run_AVG = r["opaque_Run_AVG"] != DBNull.Value ? Convert.ToDecimal(r["opaque_Run_AVG"]).ToString("0.00") : "-"
                        });
                    }
                }
            }
            catch (Exception ex)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "讀取機具列表失敗：" + ex.Message }));
                return;
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                Data = new
                {
                    Fac = facInfo,
                    Machines = macList
                }
            }));
        }

        // 6. 送出審核 (更新 Mac_State = 'A00')
        private void SubmitCheck()
        {
            string facId = Request["facId"];
            string macId = Request["macId"];

            if (string.IsNullOrEmpty(facId) || string.IsNullOrEmpty(macId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "缺少場所編號或機具序號" }));
                return;
            }

            try
            {
                string sql = "UPDATE Machine_Main SET Mac_State = 'A00', Edit_User = @user, Edit_Date = GETDATE() WHERE FAC_ID = @facId AND mac_ID = @macId";
                int rows = DbHelper.ExecuteNonQuery(sql,
                    new SqlParameter("@user", GetCurrentUser()),
                    new SqlParameter("@facId", facId),
                    new SqlParameter("@macId", macId));

                if (rows > 0)
                {
                    Response.Write(json.Serialize(new { Success = true, Message = "已成功送出審核！" }));
                }
                else
                {
                    Response.Write(json.Serialize(new { Success = false, Message = "查無該筆機具或已被修改" }));
                }
            }
            catch (Exception ex)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "送出審核失敗：" + ex.Message }));
            }
        }

        // 7. 軟刪除機具
        private void DeleteMac()
        {
            string facId = Request["facId"];
            string macId = Request["macId"];

            if (string.IsNullOrEmpty(facId) || string.IsNullOrEmpty(macId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "缺少場所編號或機具序號" }));
                return;
            }

            try
            {
                string sql = @"
                    UPDATE Machine_Main 
                    SET Deleted_mac = 'Y', Deleted_User = @user, Deleted_Date = GETDATE() 
                    WHERE FAC_ID = @facId AND mac_ID = @macId";
                int rows = DbHelper.ExecuteNonQuery(sql,
                    new SqlParameter("@user", GetCurrentUser()),
                    new SqlParameter("@facId", facId),
                    new SqlParameter("@macId", macId));

                if (rows > 0)
                {
                    Response.Write(json.Serialize(new { Success = true, Message = "已成功刪除該筆機具！" }));
                }
                else
                {
                    Response.Write(json.Serialize(new { Success = false, Message = "查無該筆機具或已被刪除" }));
                }
            }
            catch (Exception ex)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "刪除機具失敗：" + ex.Message }));
            }
        }

        // 8. 匯出 CSV 報表
        private void ExportCsv()
        {
            SearchFilterModel filter = ParseFilter();
            List<SqlParameter> pars = new List<SqlParameter>();
            StringBuilder where = new StringBuilder(" WHERE (m.Deleted_mac IS NULL OR m.Deleted_mac <> 'Y') ");

            if (filter.Mode == "reject")
            {
                where.Append(" AND (m.Mac_State IN ('A00a', 'A00b') OR m.Mac_State IS NULL) ");
            }
            if (!string.IsNullOrEmpty(filter.FacName))
            {
                where.Append(" AND f.FAC_NAME LIKE @facName ");
                pars.Add(new SqlParameter("@facName", "%" + filter.FacName + "%"));
            }
            if (!string.IsNullOrEmpty(filter.CNo))
            {
                where.Append(" AND f.C_NO LIKE @cNo ");
                pars.Add(new SqlParameter("@cNo", "%" + filter.CNo + "%"));
            }
            if (!string.IsNullOrEmpty(filter.ScId))
            {
                where.Append(" AND f.S_C_ID LIKE @scId ");
                pars.Add(new SqlParameter("@scId", "%" + filter.ScId + "%"));
            }
            if (!string.IsNullOrEmpty(filter.Town))
            {
                where.Append(" AND (ct.TOWN_NA LIKE @town OR f.TOWN_CODE = @town) ");
                pars.Add(new SqlParameter("@town", "%" + filter.Town + "%"));
            }
            if (!string.IsNullOrEmpty(filter.MacType))
            {
                where.Append(" AND m.mac_Type LIKE @macType ");
                pars.Add(new SqlParameter("@macType", "%" + filter.MacType + "%"));
            }

            string sql = string.Format(@"
                SELECT 
                    m.FAC_ID,
                    f.C_NO,
                    f.FAC_NAME,
                    ISNULL(ct.TOWN_NA, '-') AS TOWN_NA,
                    f.S_C_ID,
                    m.mac_ID,
                    m.Check_date,
                    m.mac_Type,
                    m.Brand,
                    m.model,
                    m.OUT_YEAR,
                    m.PIN,
                    m.Engine_NO,
                    m.Mac_State,
                    ROUND((ISNULL(m.opaque_Run1, 0) + ISNULL(m.opaque_Run2, 0) + ISNULL(m.opaque_Run3, 0)) / 3.0, 2) AS opaque_Run_AVG
                FROM Machine_Main m
                LEFT JOIN FAC_Main f ON m.FAC_ID = f.FAC_ID
                LEFT JOIN C_TOWN ct ON f.TOWN_CODE = ct.TOWN_NO
                {0}
                ORDER BY m.Check_date DESC, m.FAC_ID DESC", where.ToString());

            DataTable dt = DbHelper.ExecuteDataTable(sql, pars.ToArray());

            Response.Clear();
            Response.ContentType = "text/csv; charset=utf-8";
            string filename = "作業機具調查匯出_" + DateTime.Now.ToString("yyyyMMdd_HHmmss") + ".csv";
            Response.AddHeader("Content-Disposition", "attachment;filename=" + HttpUtility.UrlEncode(filename, Encoding.UTF8));

            // 輸出 UTF-8 BOM，防止 Excel 開啟時中文亂碼
            Response.BinaryWrite(new byte[] { 0xEF, 0xBB, 0xBF });

            using (StreamWriter sw = new StreamWriter(Response.OutputStream, Encoding.UTF8))
            {
                sw.WriteLine("管制編號,公私場所名稱,行政區,統一編號,機具序號,巡查時間,機具種類,廠牌,型號,出廠年份,機身號碼,引擎編號,平均不透光率(%),審核狀態");
                foreach (DataRow r in dt.Rows)
                {
                    string dateStr = r["Check_date"] != DBNull.Value ? Convert.ToDateTime(r["Check_date"]).ToString("yyyy/MM/dd") : "";
                    string avgOpaque = r["opaque_Run_AVG"] != DBNull.Value ? Convert.ToDecimal(r["opaque_Run_AVG"]).ToString("0.00") : "";
                    string state = r["Mac_State"] != DBNull.Value ? r["Mac_State"].ToString().Trim() : "A00a";

                    StringBuilder sbLine = new StringBuilder();
                    sbLine.Append("\"").Append(CleanCsv(r["C_NO"])).Append("\",");
                    sbLine.Append("\"").Append(CleanCsv(r["FAC_NAME"])).Append("\",");
                    sbLine.Append("\"").Append(CleanCsv(r["TOWN_NA"])).Append("\",");
                    sbLine.Append("\"").Append(CleanCsv(r["S_C_ID"])).Append("\",");
                    sbLine.Append("\"").Append(CleanCsv(r["mac_ID"])).Append("\",");
                    sbLine.Append("\"").Append(dateStr).Append("\",");
                    sbLine.Append("\"").Append(CleanCsv(r["mac_Type"])).Append("\",");
                    sbLine.Append("\"").Append(CleanCsv(r["Brand"])).Append("\",");
                    sbLine.Append("\"").Append(CleanCsv(r["model"])).Append("\",");
                    sbLine.Append("\"").Append(CleanCsv(r["OUT_YEAR"])).Append("\",");
                    sbLine.Append("\"").Append(CleanCsv(r["PIN"])).Append("\",");
                    sbLine.Append("\"").Append(CleanCsv(r["Engine_NO"])).Append("\",");
                    sbLine.Append("\"").Append(avgOpaque).Append("\",");
                    sbLine.Append("\"").Append(GetStateText(state)).Append("\"");

                    sw.WriteLine(sbLine.ToString());
                }
            }
            Response.End();
        }

        private static string CleanCsv(object val)
        {
            if (val == null || val == DBNull.Value) return "";
            return val.ToString().Trim().Replace("\"", "\"\"");
        }

        private SearchFilterModel ParseFilter()
        {
            SearchFilterModel model = new SearchFilterModel();

            // 若為 POST JSON
            if (Request.HttpMethod == "POST" && Request.InputStream != null && Request.InputStream.Length > 0)
            {
                try
                {
                    Request.InputStream.Position = 0;
                    using (StreamReader sr = new StreamReader(Request.InputStream, Encoding.UTF8))
                    {
                        string body = sr.ReadToEnd();
                        if (!string.IsNullOrEmpty(body))
                        {
                            var parsed = json.Deserialize<SearchFilterModel>(body);
                            if (parsed != null)
                            {
                                model = parsed;
                            }
                        }
                    }
                }
                catch
                {
                }
            }

            // 支援 QueryString 覆蓋
            if (!string.IsNullOrEmpty(Request["mode"])) model.Mode = Request["mode"].Trim().ToLower();
            if (!string.IsNullOrEmpty(Request["viewType"])) model.ViewType = Request["viewType"].Trim().ToLower();
            if (!string.IsNullOrEmpty(Request["facName"])) model.FacName = Request["facName"].Trim();
            if (!string.IsNullOrEmpty(Request["cNo"])) model.CNo = Request["cNo"].Trim();
            if (!string.IsNullOrEmpty(Request["scId"])) model.ScId = Request["scId"].Trim();
            if (!string.IsNullOrEmpty(Request["town"])) model.Town = Request["town"].Trim();
            if (!string.IsNullOrEmpty(Request["macType"])) model.MacType = Request["macType"].Trim();
            if (!string.IsNullOrEmpty(Request["brand"])) model.Brand = Request["brand"].Trim();
            if (!string.IsNullOrEmpty(Request["model"])) model.Model = Request["model"].Trim();
            if (!string.IsNullOrEmpty(Request["pin"])) model.Pin = Request["pin"].Trim();
            if (!string.IsNullOrEmpty(Request["engineNo"])) model.EngineNo = Request["engineNo"].Trim();
            if (!string.IsNullOrEmpty(Request["dateS"])) model.DateS = Request["dateS"].Trim();
            if (!string.IsNullOrEmpty(Request["dateE"])) model.DateE = Request["dateE"].Trim();
            if (!string.IsNullOrEmpty(Request["outYearS"])) model.OutYearS = Request["outYearS"].Trim();
            if (!string.IsNullOrEmpty(Request["outYearE"])) model.OutYearE = Request["outYearE"].Trim();
            if (!string.IsNullOrEmpty(Request["avgOpaqueS"])) model.AvgOpaqueS = Request["avgOpaqueS"].Trim();
            if (!string.IsNullOrEmpty(Request["avgOpaqueE"])) model.AvgOpaqueE = Request["avgOpaqueE"].Trim();

            int pIndex;
            if (int.TryParse(Request["pageIndex"], out pIndex) && pIndex > 0) model.PageIndex = pIndex;
            int pSize;
            if (int.TryParse(Request["pageSize"], out pSize) && pSize > 0) model.PageSize = pSize;

            return model;
        }

        private static SqlParameter[] CloneParameters(List<SqlParameter> pars)
        {
            var list = new List<SqlParameter>();
            foreach (var p in pars)
            {
                list.Add(new SqlParameter(p.ParameterName, p.Value));
            }
            return list.ToArray();
        }
    }
}
