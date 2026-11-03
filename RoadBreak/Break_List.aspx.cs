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
using NTPC_FEC.Security;
using NTPC_FEC.Services;

namespace NTPC_FEC.RoadBreak
{
    public partial class Break_List : Page
    {
        private JavaScriptSerializer json;

        public Break_List()
        {
            json = new JavaScriptSerializer();
            json.MaxJsonLength = int.MaxValue;
        }

        public class SearchFilterModel
        {
            public string Mode { get; set; }
            public string SearchId { get; set; }
            public string TownCode { get; set; }
            public string RoadName { get; set; }
            public string UnitId { get; set; }
            public string DamageType { get; set; }
            public string DateS { get; set; }
            public string DateE { get; set; }
            public int PageIndex { get; set; }
            public int PageSize { get; set; }

            public SearchFilterModel()
            {
                Mode = "BreakEdit";
                SearchId = "";
                TownCode = "";
                RoadName = "";
                UnitId = "";
                DamageType = "";
                DateS = "";
                DateE = "";
                PageIndex = 1;
                PageSize = 20;
            }
        }

        protected override void Render(HtmlTextWriter writer)
        {
            if (!string.IsNullOrEmpty(Request["action"]))
            {
                return;
            }
            base.Render(writer);
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["LoginUser"] == null && Session["User"] == null)
            {
                string action0 = Request["action"];
                if (!string.IsNullOrEmpty(action0))
                {
                    Response.Clear();
                    Response.StatusCode = 401;
                    Response.ContentType = "application/json; charset=utf-8";
                    Response.Write(json.Serialize(new { Success = false, Message = "登入已逾時或尚未登入，請重新登入系統！", NeedLogin = true }));
                    try { Response.End(); } catch (System.Threading.ThreadAbortException) { }
                    return;
                }
                Response.Redirect("~/Default.aspx", true);
                return;
            }

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

        private void EnsureRoadBreakColumns()
        {
            try
            {
                string alterSql = @"
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.RoadBreak_CaseMain') AND name = 'Damage_Category')
    ALTER TABLE dbo.RoadBreak_CaseMain ADD Damage_Category NVARCHAR(50) NULL;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.RoadBreak_CaseMain') AND name = 'Damage_Type')
    ALTER TABLE dbo.RoadBreak_CaseMain ADD Damage_Type NVARCHAR(50) NULL;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.RoadBreak_CaseMain') AND name = 'Damage_Length')
    ALTER TABLE dbo.RoadBreak_CaseMain ADD Damage_Length NVARCHAR(30) NULL;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.RoadBreak_CaseMain') AND name = 'Damage_Width')
    ALTER TABLE dbo.RoadBreak_CaseMain ADD Damage_Width NVARCHAR(30) NULL;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.RoadBreak_CaseMain') AND name = 'Damage_Count')
    ALTER TABLE dbo.RoadBreak_CaseMain ADD Damage_Count NVARCHAR(20) NULL;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.RoadBreak_CaseMain') AND name = 'Location_Desc')
    ALTER TABLE dbo.RoadBreak_CaseMain ADD Location_Desc NVARCHAR(200) NULL;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.RoadBreak_CaseMain') AND name = 'Lane_Info')
    ALTER TABLE dbo.RoadBreak_CaseMain ADD Lane_Info NVARCHAR(100) NULL;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.RoadBreak_CaseMain') AND name = 'Direction')
    ALTER TABLE dbo.RoadBreak_CaseMain ADD Direction NVARCHAR(50) NULL;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.RoadBreak_CaseMain') AND name = 'Road_Type')
    ALTER TABLE dbo.RoadBreak_CaseMain ADD Road_Type NVARCHAR(50) NULL;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.RoadBreak_CaseMain') AND name = 'RDM_Case_ID')
    ALTER TABLE dbo.RoadBreak_CaseMain ADD RDM_Case_ID NVARCHAR(50) NULL;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.RoadBreak_CaseMain') AND name = 'Need_Follow')
    ALTER TABLE dbo.RoadBreak_CaseMain ADD Need_Follow CHAR(1) NULL;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.RoadBreak_CaseMain') AND name = 'Follow_Memo')
    ALTER TABLE dbo.RoadBreak_CaseMain ADD Follow_Memo NVARCHAR(500) NULL;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.RoadBreak_CaseMain') AND name = 'G_Fix_Status')
    ALTER TABLE dbo.RoadBreak_CaseMain ADD G_Fix_Status NVARCHAR(200) NULL;
";
                DbHelper.ExecuteNonQuery(alterSql);
            }
            catch { }
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
            EnsureRoadBreakColumns();

            switch (action.ToLower())
            {
                case "getinit":
                    GetInitData();
                    break;
                case "getcounts":
                    GetCounts();
                    break;
                case "getlist":
                    GetList();
                    break;
                case "delete":
                    DeleteCase(Request["id"]);
                    break;
                case "export":
                    ExportCsv();
                    break;
                default:
                    Response.Write(json.Serialize(new { Success = false, Message = "未知的指令：" + action }));
                    break;
            }
        }

        // 1. 初始化選單、處理單位與計數
        private void GetInitData()
        {
            var towns = new List<object>();
            var units = new List<object>();

            try
            {
                string sqlTown = "SELECT TOWN_NO, TOWN_NA FROM C_TOWN WHERE COUNTRY = 'F' OR TOWN_NO LIKE '65%' ORDER BY TOWN_NO";
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
            catch { }

            if (towns.Count == 0)
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

            try
            {
                string sqlUnit = "SELECT UnitID, UnitName FROM RoadBreak_Unit WHERE pType = '處理單位' ORDER BY UnitID";
                DataTable dtUnit = DbHelper.ExecuteDataTable(sqlUnit);
                if (dtUnit.Rows.Count > 0)
                {
                    foreach (DataRow r in dtUnit.Rows)
                    {
                        units.Add(new
                        {
                            UnitId = r["UnitID"].ToString().Trim(),
                            UnitName = r["UnitName"].ToString().Trim()
                        });
                    }
                }
            }
            catch { }

            if (units.Count == 0)
            {
                units.Add(new { UnitId = "U01", UnitName = "新北市政府工務局養護工程處" });
                units.Add(new { UnitId = "U02", UnitName = "新北市各區公所工務課" });
                units.Add(new { UnitId = "U03", UnitName = "交通部公路局第一區養護工程處" });
            }

            var counts = QueryCounts();

            Response.Write(json.Serialize(new
            {
                Success = true,
                Data = new
                {
                    CurrentUser = GetCurrentUser(),
                    Towns = towns,
                    Units = units,
                    Counts = counts,
                    DefaultDateS = DateTime.Now.AddMonths(-1).ToString("yyyy-MM-dd"),
                    DefaultDateE = DateTime.Now.ToString("yyyy-MM-dd")
                }
            }));
        }

        // 2. 取得各模式案件計數 (含建議持續追蹤 Follow)
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
            result["BreakEdit"] = 0;
            result["BreakImprove"] = 0;
            result["Follow"] = 0;
            result["Finish"] = 0;
            result["Total"] = 0;

            try
            {
                string sql = @"
                    SELECT 
                        SUM(CASE WHEN SetCOM_Date IS NULL THEN 1 ELSE 0 END) AS CountEdit,
                        SUM(CASE WHEN SetCOM_Date IS NOT NULL AND Improve_Date IS NULL THEN 1 ELSE 0 END) AS CountImprove,
                        SUM(CASE WHEN Need_Follow = 'Y' THEN 1 ELSE 0 END) AS CountFollow,
                        SUM(CASE WHEN SetCOM_Date IS NOT NULL AND Improve_Date IS NOT NULL AND ISNULL(Need_Follow, 'N') <> 'Y' AND ISNULL(G_Back, 'N') <> 'Y' THEN 1 ELSE 0 END) AS CountFinish,
                        COUNT(*) AS CountTotal
                    FROM RoadBreak_CaseMain";

                DataTable dt = DbHelper.ExecuteDataTable(sql);
                if (dt.Rows.Count > 0)
                {
                    DataRow r = dt.Rows[0];
                    if (r["CountEdit"] != DBNull.Value) result["BreakEdit"] = Convert.ToInt32(r["CountEdit"]);
                    if (r["CountImprove"] != DBNull.Value) result["BreakImprove"] = Convert.ToInt32(r["CountImprove"]);
                    if (r["CountFollow"] != DBNull.Value) result["Follow"] = Convert.ToInt32(r["CountFollow"]);
                    if (r["CountFinish"] != DBNull.Value) result["Finish"] = Convert.ToInt32(r["CountFinish"]);
                    if (r["CountTotal"] != DBNull.Value) result["Total"] = Convert.ToInt32(r["CountTotal"]);
                }
            }
            catch { }

            return result;
        }

        // 3. 取得案件分頁清單
        private void GetList()
        {
            SearchFilterModel filter = new SearchFilterModel();
            string body = "";
            try
            {
                if (Request.InputStream != null && Request.InputStream.Length > 0)
                {
                    using (var reader = new StreamReader(Request.InputStream, Encoding.UTF8))
                    {
                        body = reader.ReadToEnd();
                    }
                }
            }
            catch { }

            if (!string.IsNullOrEmpty(body))
            {
                try
                {
                    filter = json.Deserialize<SearchFilterModel>(body);
                }
                catch { }
            }

            if (filter == null) filter = new SearchFilterModel();

            if (!string.IsNullOrEmpty(Request["mode"])) filter.Mode = Request["mode"];
            if (!string.IsNullOrEmpty(Request["searchId"])) filter.SearchId = Request["searchId"];
            if (!string.IsNullOrEmpty(Request["townCode"])) filter.TownCode = Request["townCode"];
            if (!string.IsNullOrEmpty(Request["roadName"])) filter.RoadName = Request["roadName"];
            if (!string.IsNullOrEmpty(Request["unitId"])) filter.UnitId = Request["unitId"];
            if (!string.IsNullOrEmpty(Request["damageType"])) filter.DamageType = Request["damageType"];
            if (!string.IsNullOrEmpty(Request["dateS"])) filter.DateS = Request["dateS"];
            if (!string.IsNullOrEmpty(Request["dateE"])) filter.DateE = Request["dateE"];

            int pIndex = 0;
            if (int.TryParse(Request["pageIndex"], out pIndex) && pIndex > 0) filter.PageIndex = pIndex;
            int pSize = 0;
            if (int.TryParse(Request["pageSize"], out pSize) && pSize > 0) filter.PageSize = pSize;

            if (filter.PageIndex <= 0) filter.PageIndex = 1;
            if (filter.PageSize <= 0) filter.PageSize = 20;

            List<SqlParameter> paramList = new List<SqlParameter>();
            string whereClause = BuildWhereClause(filter, paramList);

            string sqlCount = "SELECT COUNT(*) FROM RoadBreak_CaseMain m " + whereClause;
            int totalRecords = 0;
            try
            {
                List<SqlParameter> countParams = new List<SqlParameter>();
                foreach (SqlParameter p in paramList)
                {
                    countParams.Add(new SqlParameter(p.ParameterName, p.Value));
                }
                object countObj = DbHelper.ExecuteScalar(sqlCount, countParams.ToArray());
                if (countObj != null && countObj != DBNull.Value)
                {
                    totalRecords = Convert.ToInt32(countObj);
                }
            }
            catch (Exception ex)
            {
                Response.Write(json.Serialize(new
                {
                    Success = false,
                    Message = "查詢總筆數失敗：" + ex.Message
                }));
                return;
            }

            int offset = (filter.PageIndex - 1) * filter.PageSize;
            int pageSize = filter.PageSize;

            string sortCol = "m.Report_Date DESC, m.Break_ID DESC";
            string mode = filter.Mode ?? "BreakEdit";
            if (string.Equals(mode, "BreakImprove", StringComparison.OrdinalIgnoreCase)) sortCol = "m.SetCOM_Date DESC, m.Break_ID DESC";
            if (string.Equals(mode, "Follow", StringComparison.OrdinalIgnoreCase) || string.Equals(mode, "Finish", StringComparison.OrdinalIgnoreCase)) sortCol = "m.Improve_Date DESC, m.Break_ID DESC";

            string sqlList = string.Format(@"
                SELECT 
                    m.Break_ID,
                    ISNULL(m.Show_ID, m.Break_ID) AS Show_ID,
                    m.RDM_Case_ID,
                    m.Need_Follow,
                    m.Follow_Memo,
                    m.G_Back,
                    m.Report_Date,
                    m.Report_User,
                    m.S_UTME,
                    m.S_UTMN,
                    m.TOWN_CODE,
                    t.TOWN_NA AS TownName,
                    m.ROAD_LV,
                    m.ROAD_Name,
                    m.Damage_Category,
                    m.Damage_Type,
                    m.Damage_Length,
                    m.Damage_Width,
                    m.Damage_Count,
                    m.Location_Desc,
                    m.Lane_Info,
                    m.Smooth,
                    dSmooth.Val AS SmoothName,
                    m.Hole_Conn_St,
                    dHole.Val AS HoleName,
                    m.Memo,
                    m.SetCOM_Date,
                    m.S_User,
                    m.G_COM,
                    u.UnitName AS G_COM_NAME,
                    m.Improve_Date,
                    m.G_User,
                    m.G_Memo,
                    m.G_Fix_Status,
                    uRep.Name AS Report_UserName,
                    uSend.Name AS S_UserName,
                    uGov.Name AS G_UserName
                FROM RoadBreak_CaseMain m
                LEFT JOIN C_TOWN t ON t.TOWN_NO = m.TOWN_CODE
                LEFT JOIN RoadBreak_Unit u ON u.UnitID = m.G_COM
                LEFT JOIN UserAcc uRep ON uRep.UserID = m.Report_User
                LEFT JOIN UserAcc uSend ON uSend.UserID = m.S_User
                LEFT JOIN UserAcc uGov ON uGov.UserID = m.G_User
                LEFT JOIN Dictionary dSmooth ON dSmooth.CodeType = 'RoadBreak_Smooth' AND CONVERT(varchar(50), dSmooth.Code) = CONVERT(varchar(50), m.Smooth)
                LEFT JOIN Dictionary dHole ON dHole.CodeType = 'RoadBreak_Hole_Conn_St' AND CONVERT(varchar(50), dHole.Code) = CONVERT(varchar(50), m.Hole_Conn_St)
                {0}
                ORDER BY {1}
                OFFSET @offset ROWS FETCH NEXT @pageSize ROWS ONLY", whereClause, sortCol);

            List<SqlParameter> listParams = new List<SqlParameter>();
            foreach (SqlParameter p in paramList)
            {
                listParams.Add(new SqlParameter(p.ParameterName, p.Value));
            }
            listParams.Add(new SqlParameter("@offset", offset));
            listParams.Add(new SqlParameter("@pageSize", pageSize));

            DataTable dtList;
            try
            {
                dtList = DbHelper.ExecuteDataTable(sqlList, listParams.ToArray());
            }
            catch (Exception ex)
            {
                Response.Write(json.Serialize(new
                {
                    Success = false,
                    Message = "查詢分頁清單失敗：" + ex.Message
                }));
                return;
            }

            var items = new List<object>();

            foreach (DataRow r in dtList.Rows)
            {
                string rptDate = r["Report_Date"] != DBNull.Value ? Convert.ToDateTime(r["Report_Date"]).ToString("yyyy-MM-dd HH:mm") : "";
                string setDate = r["SetCOM_Date"] != DBNull.Value ? Convert.ToDateTime(r["SetCOM_Date"]).ToString("yyyy-MM-dd HH:mm") : "";
                string impDate = r["Improve_Date"] != DBNull.Value ? Convert.ToDateTime(r["Improve_Date"]).ToString("yyyy-MM-dd HH:mm") : "";

                double utmE = 0;
                double utmN = 0;
                if (r["S_UTME"] != DBNull.Value) double.TryParse(r["S_UTME"].ToString(), out utmE);
                if (r["S_UTMN"] != DBNull.Value) double.TryParse(r["S_UTMN"].ToString(), out utmN);

                string breakId = r["Break_ID"] != DBNull.Value ? r["Break_ID"].ToString().Trim() : "";
                int photoCount = 0;
                List<string> photoUrls = new List<string>();
                try
                {
                    if (!string.IsNullOrEmpty(breakId) && breakId.IndexOfAny(Path.GetInvalidFileNameChars()) < 0)
                    {
                        string picDir = PathHelper.FindDirectory("Upload/RoadBreakPIC/" + breakId);
                        if (Directory.Exists(picDir))
                        {
                            string[] files = Directory.GetFiles(picDir, "*佐證照片*.*");
                            photoCount = files.Length;
                            foreach (string f in files)
                            {
                                photoUrls.Add(PathHelper.ResolveUrl(string.Format("~/Upload/RoadBreakPIC/{0}/{1}", breakId, Path.GetFileName(f))));
                            }
                        }
                    }
                }
                catch { }

                string needFollow = r.Table.Columns.Contains("Need_Follow") && r["Need_Follow"] != DBNull.Value ? r["Need_Follow"].ToString().Trim() : "N";
                string followMemo = r.Table.Columns.Contains("Follow_Memo") && r["Follow_Memo"] != DBNull.Value ? r["Follow_Memo"].ToString().Trim() : "";
                string rdmCaseId = r.Table.Columns.Contains("RDM_Case_ID") && r["RDM_Case_ID"] != DBNull.Value ? r["RDM_Case_ID"].ToString().Trim() : "";

                string gBack = r.Table.Columns.Contains("G_Back") && r["G_Back"] != DBNull.Value ? r["G_Back"].ToString().Trim() : "N";

                // 計算案件階段狀態
                string stateName = "待通報暫存";
                string stateBadge = "badge-secondary";
                if (gBack == "Y")
                {
                    stateName = "非權責退回";
                    stateBadge = "badge-danger";
                }
                else if (needFollow == "Y")
                {
                    stateName = "建議持續追蹤";
                    stateBadge = "badge-info";
                }
                else if (r["Improve_Date"] != DBNull.Value)
                {
                    stateName = "已改善結案";
                    stateBadge = "badge-success";
                }
                else if (r["SetCOM_Date"] != DBNull.Value)
                {
                    stateName = "改善處理中";
                    stateBadge = "badge-primary";
                }

                items.Add(new
                {
                    Break_ID = breakId,
                    Show_ID = r["Show_ID"] != DBNull.Value ? r["Show_ID"].ToString().Trim() : breakId,
                    RDM_Case_ID = rdmCaseId,
                    Need_Follow = needFollow,
                    Follow_Memo = followMemo,
                    Report_Date = rptDate,
                    Report_User = r["Report_User"] != DBNull.Value ? r["Report_User"].ToString().Trim() : "",
                    Report_UserName = r["Report_UserName"] != DBNull.Value ? r["Report_UserName"].ToString().Trim() : (r["Report_User"] != DBNull.Value ? r["Report_User"].ToString().Trim() : ""),
                    S_UTME = utmE > 0 ? utmE.ToString("0") : "",
                    S_UTMN = utmN > 0 ? utmN.ToString("0") : "",
                    TOWN_CODE = r["TOWN_CODE"] != DBNull.Value ? r["TOWN_CODE"].ToString().Trim() : "",
                    TownName = r["TownName"] != DBNull.Value ? r["TownName"].ToString().Trim() : "",
                    ROAD_LV = r["ROAD_LV"] != DBNull.Value ? r["ROAD_LV"].ToString().Trim() : "",
                    ROAD_Name = r["ROAD_Name"] != DBNull.Value ? r["ROAD_Name"].ToString().Trim() : "",
                    Smooth = r["Smooth"] != DBNull.Value ? r["Smooth"].ToString().Trim() : "",
                    SmoothName = r["SmoothName"] != DBNull.Value ? r["SmoothName"].ToString().Trim() : GetFallbackSmoothName(r["Smooth"]),
                    Hole_Conn_St = r["Hole_Conn_St"] != DBNull.Value ? r["Hole_Conn_St"].ToString().Trim() : "",
                    HoleName = r["HoleName"] != DBNull.Value ? r["HoleName"].ToString().Trim() : GetFallbackHoleName(r["Hole_Conn_St"]),
                    Damage_Category = r.Table.Columns.Contains("Damage_Category") && r["Damage_Category"] != DBNull.Value ? r["Damage_Category"].ToString().Trim() : "路面損壞",
                    Damage_Type = GetDamageTypeDisplay(r),
                    Damage_Length = r.Table.Columns.Contains("Damage_Length") && r["Damage_Length"] != DBNull.Value ? r["Damage_Length"].ToString().Trim() : "",
                    Damage_Width = r.Table.Columns.Contains("Damage_Width") && r["Damage_Width"] != DBNull.Value ? r["Damage_Width"].ToString().Trim() : "",
                    Damage_Count = r.Table.Columns.Contains("Damage_Count") && r["Damage_Count"] != DBNull.Value ? r["Damage_Count"].ToString().Trim() : "",
                    Location_Desc = r.Table.Columns.Contains("Location_Desc") && r["Location_Desc"] != DBNull.Value ? r["Location_Desc"].ToString().Trim() : "",
                    Lane_Info = r.Table.Columns.Contains("Lane_Info") && r["Lane_Info"] != DBNull.Value ? r["Lane_Info"].ToString().Trim() : "全車道",
                    Memo = r["Memo"] != DBNull.Value ? r["Memo"].ToString().Replace("<br />", " ").Replace("<br>", " ") : "",
                    SetCOM_Date = setDate,
                    S_User = r["S_User"] != DBNull.Value ? r["S_User"].ToString().Trim() : "",
                    S_UserName = r["S_UserName"] != DBNull.Value ? r["S_UserName"].ToString().Trim() : "",
                    G_COM = r["G_COM"] != DBNull.Value ? r["G_COM"].ToString().Trim() : "",
                    G_COM_NAME = r["G_COM_NAME"] != DBNull.Value ? r["G_COM_NAME"].ToString().Trim() : "",
                    Improve_Date = impDate,
                    G_User = r["G_User"] != DBNull.Value ? r["G_User"].ToString().Trim() : "",
                    G_UserName = r["G_UserName"] != DBNull.Value ? r["G_UserName"].ToString().Trim() : "",
                    G_Memo = r["G_Memo"] != DBNull.Value ? r["G_Memo"].ToString().Replace("<br />", " ") : "",
                    G_Fix_Status = r.Table.Columns.Contains("G_Fix_Status") && r["G_Fix_Status"] != DBNull.Value ? r["G_Fix_Status"].ToString().Trim() : "",
                    PhotoCount = photoCount,
                    PhotoUrls = photoUrls,
                    G_Back = gBack,
                    StateName = stateName,
                    StateBadge = stateBadge
                });
            }

            int totalPages = (int)Math.Ceiling((double)totalRecords / filter.PageSize);
            if (totalPages == 0) totalPages = 1;

            Response.Write(json.Serialize(new
            {
                Success = true,
                Data = new
                {
                    Items = items,
                    TotalRecords = totalRecords,
                    TotalPages = totalPages,
                    PageIndex = filter.PageIndex,
                    PageSize = filter.PageSize
                }
            }));
        }

        private static string GetFallbackSmoothName(object codeObj)
        {
            if (codeObj == null || codeObj == DBNull.Value) return "";
            string c = codeObj.ToString().Trim();
            if (c == "1") return "平整良好";
            if (c == "2") return "輕微龜裂/破損";
            if (c == "3") return "中度凹陷/波浪";
            if (c == "4") return "嚴重坑洞/破損";
            return c;
        }

        private static string GetFallbackHoleName(object codeObj)
        {
            if (codeObj == null || codeObj == DBNull.Value) return "";
            string c = codeObj.ToString().Trim();
            if (c == "1") return "平順密合";
            if (c == "2") return "高低落差 (>1cm)";
            if (c == "3") return "孔蓋周邊瀝青破損";
            if (c == "4") return "孔蓋鬆動或異音";
            if (c == "5") return "其他";
            return c;
        }

        // 4. 動態組成查詢條件
        private string BuildWhereClause(SearchFilterModel filter, List<SqlParameter> parameters)
        {
            List<string> conditions = new List<string>();

            string mode = filter.Mode ?? "BreakEdit";
            if (string.Equals(mode, "BreakEdit", StringComparison.OrdinalIgnoreCase))
            {
                conditions.Add("m.SetCOM_Date IS NULL");
            }
            else if (string.Equals(mode, "BreakImprove", StringComparison.OrdinalIgnoreCase))
            {
                conditions.Add("m.SetCOM_Date IS NOT NULL AND m.Improve_Date IS NULL");
            }
            else if (string.Equals(mode, "Follow", StringComparison.OrdinalIgnoreCase))
            {
                conditions.Add("m.Need_Follow = 'Y'");
            }
            else if (string.Equals(mode, "Finish", StringComparison.OrdinalIgnoreCase))
            {
                conditions.Add("m.SetCOM_Date IS NOT NULL AND m.Improve_Date IS NOT NULL AND ISNULL(m.Need_Follow, 'N') <> 'Y' AND ISNULL(m.G_Back, 'N') <> 'Y'");
            }

            string keyword = "";
            if (!string.IsNullOrEmpty(filter.RoadName)) keyword = filter.RoadName.Trim();
            else if (!string.IsNullOrEmpty(filter.SearchId)) keyword = filter.SearchId.Trim();

            if (!string.IsNullOrEmpty(keyword))
            {
                conditions.Add("(m.Break_ID LIKE '%' + @Keyword + '%' OR m.Show_ID LIKE '%' + @Keyword + '%' OR m.RDM_Case_ID LIKE '%' + @Keyword + '%' OR m.ROAD_Name LIKE '%' + @Keyword + '%' OR m.Memo LIKE '%' + @Keyword + '%')");
                parameters.Add(new SqlParameter("@Keyword", keyword));
            }

            if (!string.IsNullOrEmpty(filter.TownCode))
            {
                conditions.Add("m.TOWN_CODE = @TownCode");
                parameters.Add(new SqlParameter("@TownCode", filter.TownCode.Trim()));
            }

            if (!string.IsNullOrEmpty(filter.UnitId))
            {
                conditions.Add("m.G_COM = @UnitId");
                parameters.Add(new SqlParameter("@UnitId", filter.UnitId.Trim()));
            }

            if (!string.IsNullOrEmpty(filter.DamageType))
            {
                conditions.Add("m.Damage_Type LIKE '%' + @DamageType + '%'");
                parameters.Add(new SqlParameter("@DamageType", filter.DamageType.Trim()));
            }

            string dateCol = "m.Report_Date";
            if (string.Equals(mode, "BreakImprove", StringComparison.OrdinalIgnoreCase)) dateCol = "m.SetCOM_Date";
            if (string.Equals(mode, "Follow", StringComparison.OrdinalIgnoreCase) || string.Equals(mode, "Finish", StringComparison.OrdinalIgnoreCase)) dateCol = "m.Improve_Date";

            if (!string.IsNullOrEmpty(filter.DateS))
            {
                DateTime dtS;
                if (DateTime.TryParse(filter.DateS, out dtS))
                {
                    conditions.Add(dateCol + " >= @DateS");
                    parameters.Add(new SqlParameter("@DateS", dtS.Date));
                }
            }

            if (!string.IsNullOrEmpty(filter.DateE))
            {
                DateTime dtE;
                if (DateTime.TryParse(filter.DateE, out dtE))
                {
                    conditions.Add(dateCol + " <= @DateE");
                    parameters.Add(new SqlParameter("@DateE", dtE.Date.AddDays(1).AddSeconds(-1)));
                }
            }

            if (conditions.Count == 0) return "";
            return " WHERE " + string.Join(" AND ", conditions.ToArray());
        }

        // 5. 刪除案件 (放寬限制，完整留存 AuditLog 稽核歷程與案件全欄位快照)
        private void DeleteCase(string breakId)
        {
            if (string.IsNullOrEmpty(breakId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "未提供通報案號" }));
                return;
            }

            string checkSql = "SELECT * FROM RoadBreak_CaseMain WHERE Break_ID = @id";
            DataTable dtCase = DbHelper.ExecuteDataTable(checkSql, new SqlParameter("@id", breakId));
            if (dtCase == null || dtCase.Rows.Count == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "查無此通報案件！" }));
                return;
            }

            DataRow rCase = dtCase.Rows[0];
            string reportU = rCase["Report_User"] != DBNull.Value ? rCase["Report_User"].ToString().Trim() : "";
            string curU = GetCurrentUser();
            long lic = Session["LIC"] != null ? Convert.ToInt64(Session["LIC"]) : 0L;
            string currentRole = Session["Role"] != null ? Session["Role"].ToString().Trim() : "";

            bool isAdmin = string.Equals(curU, "Admin", StringComparison.OrdinalIgnoreCase) ||
                           string.Equals(currentRole, "Admin", StringComparison.OrdinalIgnoreCase) ||
                           string.Equals(currentRole, "SystemAdmin", StringComparison.OrdinalIgnoreCase) ||
                           PermissionService.HasPermission(curU, lic, "ROAD_BREAK_EDIT", 26) ||
                           PermissionService.HasPermission(curU, lic, "ROAD_BREAK_MANAGE", 26);

            if (!isAdmin && !string.Equals(reportU, curU, StringComparison.OrdinalIgnoreCase))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "權限不足：僅本通報建立者或系統管理員方可刪除此紀錄！" }));
                return;
            }

            // 1. 將整筆案件主檔轉成快照字典，準備寫入稽核 Log
            Dictionary<string, object> snapshot = new Dictionary<string, object>();
            foreach (DataColumn col in dtCase.Columns)
            {
                snapshot[col.ColumnName] = rCase[col] != DBNull.Value ? rCase[col].ToString() : null;
            }
            string snapshotJson = json.Serialize(snapshot);

            string showId = rCase["Show_ID"] != DBNull.Value ? rCase["Show_ID"].ToString().Trim() : breakId;
            string roadName = rCase["ROAD_Name"] != DBNull.Value ? rCase["ROAD_Name"].ToString().Trim() : "";
            string setComStr = rCase["SetCOM_Date"] != DBNull.Value ? rCase["SetCOM_Date"].ToString() : "未派工";
            string improveStr = rCase["Improve_Date"] != DBNull.Value ? rCase["Improve_Date"].ToString() : "未結案";

            // 2. 寫入雙軌 AuditLog (留存刪除歷程與案件全欄位快照)
            AuditLogger.Log(
                operatorUser: curU,
                actionType: "ROAD_BREAK_CASE_DELETE",
                targetUser: breakId,
                clientIp: Request.UserHostAddress,
                details: string.Format("刪除道路破損案件 [{0}] (顯示案號:{1}, 路段:{2}, 派工狀態:{3}, 改善狀態:{4})",
                    breakId, showId, roadName, setComStr, improveStr),
                oldValue: snapshotJson,
                newValue: null
            );

            // 3. 執行刪除
            string sql = "DELETE FROM RoadBreak_CaseMain WHERE Break_ID = @id";
            int rows = DbHelper.ExecuteNonQuery(sql, new SqlParameter("@id", breakId));

            try
            {
                if (!string.IsNullOrEmpty(breakId) && breakId.IndexOfAny(Path.GetInvalidFileNameChars()) < 0)
                {
                    string picDir = PathHelper.FindDirectory("Upload/RoadBreakPIC/" + breakId);
                    if (Directory.Exists(picDir))
                    {
                        string[] filesToDel = Directory.GetFiles(picDir, "*", SearchOption.AllDirectories);
                        for (int i = 0; i < filesToDel.Length; i++) { try { File.Delete(filesToDel[i]); } catch { } }
                    }
                }
            }
            catch { }

            Response.Write(json.Serialize(new
            {
                Success = true,
                Message = "通報單 " + showId + " 已成功刪除，系統已保存完整操作稽核歷程！"
            }));
        }

        // 6. 匯出 CSV (完整包含路平報馬仔編號與持續追蹤狀態)
        private void ExportCsv()
        {
            string mode = Request["mode"] ?? "BreakEdit";
            SearchFilterModel filter = new SearchFilterModel();
            filter.Mode = mode;
            filter.SearchId = Request["searchId"] ?? "";
            filter.TownCode = Request["townCode"] ?? "";
            filter.RoadName = Request["roadName"] ?? "";
            filter.UnitId = Request["unitId"] ?? "";
            filter.DamageType = Request["damageType"] ?? "";
            filter.DateS = Request["dateS"] ?? "";
            filter.DateE = Request["dateE"] ?? "";
            filter.PageIndex = 1;
            filter.PageSize = 5000;

            List<SqlParameter> paramList = new List<SqlParameter>();
            string whereClause = BuildWhereClause(filter, paramList);

            string sql = string.Format(@"
                SELECT 
                    m.Break_ID,
                    ISNULL(m.Show_ID, m.Break_ID) AS Show_ID,
                    m.RDM_Case_ID,
                    m.Need_Follow,
                    m.Follow_Memo,
                    m.G_Back,
                    m.Report_Date,
                    ISNULL(uRep.Name, m.Report_User) AS Report_UserName,
                    m.S_UTME,
                    m.S_UTMN,
                    t.TOWN_NA AS TownName,
                    m.ROAD_LV,
                    m.ROAD_Name,
                    m.Damage_Category,
                    m.Damage_Type,
                    m.Damage_Length,
                    m.Damage_Width,
                    m.Damage_Count,
                    m.Location_Desc,
                    m.Lane_Info,
                    m.Direction,
                    m.Road_Type,
                    m.Smooth,
                    dSmooth.Val AS SmoothName,
                    m.Hole_Conn_St,
                    dHole.Val AS HoleName,
                    m.Memo,
                    m.SetCOM_Date,
                    ISNULL(uSend.Name, m.S_User) AS S_UserName,
                    u.UnitName AS G_COM_NAME,
                    m.Improve_Date,
                    ISNULL(uGov.Name, m.G_User) AS G_UserName,
                    m.G_Fix_Status,
                    m.G_Contact_Phone,
                    m.G_Delay_Reason,
                    m.G_Reply_Type,
                    m.G_Reply_Memo,
                    m.G_Reply_Date,
                    m.G_Report_Date,
                    m.G_Memo
                FROM RoadBreak_CaseMain m
                LEFT JOIN C_TOWN t ON t.TOWN_NO = m.TOWN_CODE
                LEFT JOIN RoadBreak_Unit u ON u.UnitID = m.G_COM
                LEFT JOIN UserAcc uRep ON uRep.UserID = m.Report_User
                LEFT JOIN UserAcc uSend ON uSend.UserID = m.S_User
                LEFT JOIN UserAcc uGov ON uGov.UserID = m.G_User
                LEFT JOIN Dictionary dSmooth ON dSmooth.CodeType = 'RoadBreak_Smooth' AND CONVERT(varchar(50), dSmooth.Code) = CONVERT(varchar(50), m.Smooth)
                LEFT JOIN Dictionary dHole ON dHole.CodeType = 'RoadBreak_Hole_Conn_St' AND CONVERT(varchar(50), dHole.Code) = CONVERT(varchar(50), m.Hole_Conn_St)
                {0}
                ORDER BY m.Report_Date DESC", whereClause);

            DataTable dt = DbHelper.ExecuteDataTable(sql, paramList.ToArray());

            StringBuilder sb = new StringBuilder();
            sb.AppendLine("通報案號,路平報馬仔編號,是否建議持續追蹤,持續追蹤說明,反映日期,查核人員,行政區,道路名稱,地點描述,損壞類別,損壞性質,長度(m),寬度(m),處數,車道,方向,道路型態,通報坐標X,通報坐標Y,權責處理單位,完工日期,完工回報日期,修復情形,聯絡電話,延遲原因,結案回覆方式,結案回覆說明,結案回覆時間,派工時間,派工人員,通報補充,備註說明");

            foreach (DataRow r in dt.Rows)
            {
                string rptDate = r["Report_Date"] != DBNull.Value ? Convert.ToDateTime(r["Report_Date"]).ToString("yyyy-MM-dd HH:mm") : "";
                string setDate = r["SetCOM_Date"] != DBNull.Value ? Convert.ToDateTime(r["SetCOM_Date"]).ToString("yyyy-MM-dd HH:mm") : "";
                string impDate = r["Improve_Date"] != DBNull.Value ? Convert.ToDateTime(r["Improve_Date"]).ToString("yyyy-MM-dd HH:mm") : "";
                string gRptDate = r.Table.Columns.Contains("G_Report_Date") && r["G_Report_Date"] != DBNull.Value ? Convert.ToDateTime(r["G_Report_Date"]).ToString("yyyy-MM-dd HH:mm") : "";
                string gRpyDate = r.Table.Columns.Contains("G_Reply_Date") && r["G_Reply_Date"] != DBNull.Value ? Convert.ToDateTime(r["G_Reply_Date"]).ToString("yyyy-MM-dd HH:mm") : "";

                string rdmId = r.Table.Columns.Contains("RDM_Case_ID") && r["RDM_Case_ID"] != DBNull.Value ? r["RDM_Case_ID"].ToString().Trim() : "";
                string needFollow = r.Table.Columns.Contains("Need_Follow") && r["Need_Follow"] != DBNull.Value && r["Need_Follow"].ToString().Trim() == "Y" ? "建議持續追蹤" : "否";
                string followMemo = r.Table.Columns.Contains("Follow_Memo") && r["Follow_Memo"] != DBNull.Value ? r["Follow_Memo"].ToString().Replace("\"", "\"\"").Replace("\r\n", " ").Replace("\n", " ") : "";

                string damageType = GetDamageTypeDisplay(r);
                string damageCat = r.Table.Columns.Contains("Damage_Category") && r["Damage_Category"] != DBNull.Value ? r["Damage_Category"].ToString().Trim() : "路面損壞";
                string damageLen = r.Table.Columns.Contains("Damage_Length") && r["Damage_Length"] != DBNull.Value ? r["Damage_Length"].ToString().Trim() : "";
                string damageWid = r.Table.Columns.Contains("Damage_Width") && r["Damage_Width"] != DBNull.Value ? r["Damage_Width"].ToString().Trim() : "";
                string damageCnt = r.Table.Columns.Contains("Damage_Count") && r["Damage_Count"] != DBNull.Value ? r["Damage_Count"].ToString().Trim() : "1";
                string locDesc = r.Table.Columns.Contains("Location_Desc") && r["Location_Desc"] != DBNull.Value ? r["Location_Desc"].ToString().Trim() : "";
                string lane = r.Table.Columns.Contains("Lane_Info") && r["Lane_Info"] != DBNull.Value ? r["Lane_Info"].ToString().Trim() : "全車道";
                string dir = r.Table.Columns.Contains("Direction") && r["Direction"] != DBNull.Value ? r["Direction"].ToString().Trim() : "無法判定";
                string rdType = r.Table.Columns.Contains("Road_Type") && r["Road_Type"] != DBNull.Value ? r["Road_Type"].ToString().Trim() : "平面";
                string fixStatus = r.Table.Columns.Contains("G_Fix_Status") && r["G_Fix_Status"] != DBNull.Value ? r["G_Fix_Status"].ToString().Trim() : "";
                string phone = r.Table.Columns.Contains("G_Contact_Phone") && r["G_Contact_Phone"] != DBNull.Value ? r["G_Contact_Phone"].ToString().Trim() : "";
                string delay = r.Table.Columns.Contains("G_Delay_Reason") && r["G_Delay_Reason"] != DBNull.Value ? r["G_Delay_Reason"].ToString().Trim() : "";
                string rpyType = r.Table.Columns.Contains("G_Reply_Type") && r["G_Reply_Type"] != DBNull.Value ? r["G_Reply_Type"].ToString().Trim() : "網路回覆";
                string rpyMemo = r.Table.Columns.Contains("G_Reply_Memo") && r["G_Reply_Memo"] != DBNull.Value ? r["G_Reply_Memo"].ToString().Replace("\"", "\"\"").Replace("\r\n", " ").Replace("\n", " ") : "";

                string memo = r["Memo"] != DBNull.Value ? r["Memo"].ToString().Replace("\"", "\"\"").Replace("\r\n", " ").Replace("\n", " ") : "";
                string gMemo = r["G_Memo"] != DBNull.Value ? r["G_Memo"].ToString().Replace("\"", "\"\"").Replace("\r\n", " ").Replace("\n", " ") : "";

                sb.AppendFormat("\"{0}\",\"{1}\",\"{2}\",\"{3}\",\"{4}\",\"{5}\",\"{6}\",\"{7}\",\"{8}\",\"{9}\",\"{10}\",\"{11}\",\"{12}\",\"{13}\",\"{14}\",\"{15}\",\"{16}\",\"{17}\",\"{18}\",\"{19}\",\"{20}\",\"{21}\",\"{22}\",\"{23}\",\"{24}\",\"{25}\",\"{26}\",\"{27}\",\"{28}\",\"{29}\",\"{30}\",\"{31}\"\r\n",
                    r["Show_ID"],
                    rdmId,
                    needFollow,
                    followMemo,
                    rptDate,
                    r["Report_UserName"],
                    r["TownName"],
                    r["ROAD_Name"],
                    locDesc,
                    damageCat,
                    damageType,
                    damageLen,
                    damageWid,
                    damageCnt,
                    lane,
                    dir,
                    rdType,
                    r["S_UTME"],
                    r["S_UTMN"],
                    r["G_COM_NAME"],
                    impDate,
                    gRptDate,
                    fixStatus,
                    phone,
                    delay,
                    rpyType,
                    rpyMemo,
                    gRpyDate,
                    setDate,
                    r["S_UserName"],
                    memo,
                    gMemo);
            }

            Response.Clear();
            Response.Buffer = true;
            Response.AddHeader("content-disposition", "attachment;filename=RoadBreak_Export_" + DateTime.Now.ToString("yyyyMMdd_HHmmss") + ".csv");
            Response.Charset = "utf-8";
            Response.ContentType = "text/csv; charset=utf-8";

            byte[] bom = Encoding.UTF8.GetPreamble();
            Response.BinaryWrite(bom);
            byte[] data = Encoding.UTF8.GetBytes(sb.ToString());
            Response.BinaryWrite(data);
            try
            {
                Response.End();
            }
            catch (System.Threading.ThreadAbortException)
            {
                return;
            }
        }

        private static string GetDamageTypeDisplay(DataRow r)
        {
            if (r == null || r.Table == null) return "路面破損";
            if (r.Table.Columns.Contains("Damage_Type") && r["Damage_Type"] != DBNull.Value)
            {
                string dt = r["Damage_Type"].ToString().Trim();
                if (!string.IsNullOrEmpty(dt)) return dt;
            }
            string oldHole = r.Table.Columns.Contains("Hole_Conn_St") && r["Hole_Conn_St"] != DBNull.Value ? r["Hole_Conn_St"].ToString().Trim() : "";
            string oldSmooth = r.Table.Columns.Contains("Smooth") && r["Smooth"] != DBNull.Value ? r["Smooth"].ToString().Trim() : "";
            if (oldHole == "3" || oldHole == "4") return "人手孔蓋週邊破損";
            if (oldHole == "2") return "人手孔蓋欠平順";
            if (oldSmooth == "4") return "坑洞";
            if (oldSmooth == "2") return "龜裂";
            if (oldSmooth == "3") return "凹陷";
            return "路面破損";
        }
    }
}
