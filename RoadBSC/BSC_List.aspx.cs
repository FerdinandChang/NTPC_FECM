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

namespace NTPC_FEC.RoadBSC
{
    public partial class BSC_List : Page
    {
        private JavaScriptSerializer json;

        public BSC_List()
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
            public string DateS { get; set; }
            public string DateE { get; set; }
            public int PageIndex { get; set; }
            public int PageSize { get; set; }

            public SearchFilterModel()
            {
                Mode = "BSCEdit";
                SearchId = "";
                TownCode = "";
                RoadName = "";
                UnitId = "";
                DateS = "";
                DateE = "";
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

            // 行政區清單
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

            // 處理單位清單 (RoadBSC_Unit)
            try
            {
                string sqlUnit = "SELECT UnitID, UnitName FROM RoadBSC_Unit WHERE pType = '處理單位' ORDER BY UnitID";
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
                else
                {
                    units.Add(new { UnitId = "U01", UnitName = "新北市政府農業局林務科" });
                    units.Add(new { UnitId = "U02", UnitName = "新北市各區公所農經課" });
                    units.Add(new { UnitId = "U03", UnitName = "新北市政府水利局" });
                }
            }
            catch
            {
                units.Add(new { UnitId = "U01", UnitName = "新北市政府農業局林務科" });
                units.Add(new { UnitId = "U02", UnitName = "新北市各區公所農經課" });
                units.Add(new { UnitId = "U03", UnitName = "新北市政府水利局" });
            }

            // 案件總數統計
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

        // 2. 取得各模式案件計數
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
            result["BSCEdit"] = 0;
            result["BSCImprove"] = 0;
            result["Finish"] = 0;
            result["Total"] = 0;

            try
            {
                string sql = @"
                    SELECT 
                        SUM(CASE WHEN SetCOM_Date IS NULL THEN 1 ELSE 0 END) AS CountEdit,
                        SUM(CASE WHEN SetCOM_Date IS NOT NULL AND Improve_Date IS NULL THEN 1 ELSE 0 END) AS CountImprove,
                        SUM(CASE WHEN SetCOM_Date IS NOT NULL AND Improve_Date IS NOT NULL THEN 1 ELSE 0 END) AS CountFinish,
                        COUNT(*) AS CountTotal
                    FROM RoadBSC_CaseMain";

                DataTable dt = DbHelper.ExecuteDataTable(sql);
                if (dt.Rows.Count > 0)
                {
                    DataRow r = dt.Rows[0];
                    if (r["CountEdit"] != DBNull.Value) result["BSCEdit"] = Convert.ToInt32(r["CountEdit"]);
                    if (r["CountImprove"] != DBNull.Value) result["BSCImprove"] = Convert.ToInt32(r["CountImprove"]);
                    if (r["CountFinish"] != DBNull.Value) result["Finish"] = Convert.ToInt32(r["CountFinish"]);
                    if (r["CountTotal"] != DBNull.Value) result["Total"] = Convert.ToInt32(r["CountTotal"]);
                }
            }
            catch
            {
                // 資料庫離線 fallback
            }

            return result;
        }

        // 3. 取得案件分頁清單 (完整支援 GET 與 POST，防護機房 WAF / 反向代理攔截)
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

            // 若前端使用 GET 查詢或特定欄位在 Body 未提供，從 Request/QueryString 補充讀取
            if (!string.IsNullOrEmpty(Request["mode"])) filter.Mode = Request["mode"];
            if (!string.IsNullOrEmpty(Request["searchId"])) filter.SearchId = Request["searchId"];
            if (!string.IsNullOrEmpty(Request["townCode"])) filter.TownCode = Request["townCode"];
            if (!string.IsNullOrEmpty(Request["roadName"])) filter.RoadName = Request["roadName"];
            if (!string.IsNullOrEmpty(Request["unitId"])) filter.UnitId = Request["unitId"];
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

            // 1. 查詢符合總筆數
            string sqlCount = "SELECT COUNT(*) FROM RoadBSC_CaseMain m " + whereClause;
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

            // 2. 查詢分頁資料 (SQL Server 2012+ OFFSET-FETCH 高效標準語法)
            int offset = (filter.PageIndex - 1) * filter.PageSize;
            int pageSize = filter.PageSize;

            string sortCol = "Report_Date DESC";
            string mode = filter.Mode ?? "BSCEdit";
            if (string.Equals(mode, "BSCImprove", StringComparison.OrdinalIgnoreCase)) sortCol = "SetCOM_Date DESC";
            if (string.Equals(mode, "Finish", StringComparison.OrdinalIgnoreCase)) sortCol = "Improve_Date DESC";

            string sqlList = string.Format(@"
                SELECT 
                    m.BSC_ID,
                    ISNULL(m.Show_ID, m.BSC_ID) AS Show_ID,
                    m.Report_Date,
                    m.Report_User,
                    m.S_UTME,
                    m.S_UTMN,
                    m.TOWN_CODE,
                    t.TOWN_NA AS TownName,
                    m.ROAD_LV,
                    m.ROAD_Name,
                    m.Smooth,
                    dSmooth.Val AS SmoothName,
                    m.Cover_Soil,
                    dCover.Val AS CoverSoilName,
                    m.Memo,
                    m.SetCOM_Date,
                    m.S_User,
                    m.G_COM,
                    u.UnitName AS G_COM_NAME,
                    m.Improve_Date,
                    m.G_User,
                    m.G_Memo,
                    uRep.Name AS Report_UserName,
                    uSend.Name AS S_UserName,
                    uGov.Name AS G_UserName
                FROM RoadBSC_CaseMain m
                LEFT JOIN C_TOWN t ON t.TOWN_NO = m.TOWN_CODE
                LEFT JOIN RoadBSC_Unit u ON u.UnitID = m.G_COM
                LEFT JOIN UserAcc uRep ON uRep.UserID = m.Report_User
                LEFT JOIN UserAcc uSend ON uSend.UserID = m.S_User
                LEFT JOIN UserAcc uGov ON uGov.UserID = m.G_User
                LEFT JOIN Dictionary dSmooth ON dSmooth.CodeType = 'RoadBSC_Smooth' AND dSmooth.Code = m.Smooth
                LEFT JOIN Dictionary dCover ON dCover.CodeType = 'RoadBSC_Cover_Soil' AND dCover.Code = m.Cover_Soil
                {0}
                ORDER BY m.{1}
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

                // 檢查是否有佐證照片與照片數量 (加入完整防呆)
                string bscId = r["BSC_ID"] != DBNull.Value ? r["BSC_ID"].ToString().Trim() : "";
                int photoCount = 0;
                List<string> photoUrls = new List<string>();
                try
                {
                    if (!string.IsNullOrEmpty(bscId) && bscId.IndexOfAny(Path.GetInvalidFileNameChars()) < 0)
                    {
                        string picDir = Server.MapPath("~/Upload/RoadBSCPIC/" + bscId);
                        if (Directory.Exists(picDir))
                        {
                            string[] files = Directory.GetFiles(picDir, "佐證照片*.*");
                            photoCount = files.Length;
                            foreach (string f in files)
                            {
                                photoUrls.Add("../Upload/RoadBSCPIC/" + bscId + "/" + Path.GetFileName(f));
                            }
                        }
                    }
                }
                catch
                {
                    // 檔案系統讀取異常 fallback
                }

                // 計算案件階段狀態
                // 計算案件階段狀態
                DateTime dtTmp;
                bool isSetCom = (r["SetCOM_Date"] != DBNull.Value && DateTime.TryParse(r["SetCOM_Date"].ToString(), out dtTmp));
                bool isImproved = (r["Improve_Date"] != DBNull.Value && DateTime.TryParse(r["Improve_Date"].ToString(), out dtTmp));

                string stateName = "待通報暫存";
                string stateBadge = "badge-secondary";
                if (isImproved)
                {
                    stateName = "改善已完成";
                    stateBadge = "badge-success";
                }
                else if (isSetCom)
                {
                    stateName = "改善處理中";
                    stateBadge = "badge-primary";
                }

                // 產生操作 URL 與 安全校驗碼 Token
                string todayForUrl = DateTime.Now.ToString("yyyy-MM-dd");
                string editToken = ComputeMd5("EditBSC_" + bscId + "_" + todayForUrl);
                string setSgToken = ComputeMd5("SetSGBSC_" + bscId + "_" + todayForUrl);
                string improveToken = ComputeMd5("ImproveBSC_" + bscId + "_" + todayForUrl);
                string detailToken = ComputeMd5("DetailBSC_" + bscId + "_" + todayForUrl);

                string editUrl = "NewBSC.aspx?id=" + bscId + "&chk=" + editToken + "&mode=edit";
                string setSgUrl = "SetSG_BSC.aspx?id=" + bscId + "&chk=" + setSgToken;
                string improveUrl = "ImproveBSC.aspx?id=" + bscId + "&chk=" + improveToken;
                string detailUrl = "BSCDetail.aspx?id=" + bscId + "&chk=" + detailToken + "&parmode=" + HttpUtility.UrlEncode(mode);

                items.Add(new
                {
                    BSC_ID = bscId,
                    Show_ID = r["Show_ID"] != DBNull.Value ? r["Show_ID"].ToString().Trim() : bscId,
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
                    Cover_Soil = r["Cover_Soil"] != DBNull.Value ? r["Cover_Soil"].ToString().Trim() : "",
                    CoverSoilName = r["CoverSoilName"] != DBNull.Value ? r["CoverSoilName"].ToString().Trim() : GetFallbackCoverSoilName(r["Cover_Soil"]),
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
                    PhotoCount = photoCount,
                    PhotoUrls = photoUrls,
                    IsSetCom = isSetCom,
                    IsImproved = isImproved,
                    EditUrl = editUrl,
                    SetSGUrl = setSgUrl,
                    ImproveUrl = improveUrl,
                    DetailUrl = detailUrl,
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

        private static string GetFallbackCoverSoilName(object codeObj)
        {
            if (codeObj == null || codeObj == DBNull.Value) return "";
            string c = codeObj.ToString().Trim();
            if (c == "1") return "植被完全覆蓋 (>=90%)";
            if (c == "2") return "部分植被覆蓋 (50~89%)";
            if (c == "3") return "局部裸露 (20~49%)";
            if (c == "4") return "大面積嚴重裸露 (<20%)";
            return c;
        }

        // 4. 動態組成查詢條件
        private string BuildWhereClause(SearchFilterModel filter, List<SqlParameter> parameters)
        {
            List<string> conditions = new List<string>();

            // 模式條件
            string mode = filter.Mode ?? "BSCEdit";
            if (string.Equals(mode, "BSCEdit", StringComparison.OrdinalIgnoreCase))
            {
                conditions.Add("m.SetCOM_Date IS NULL");
            }
            else if (string.Equals(mode, "BSCImprove", StringComparison.OrdinalIgnoreCase))
            {
                conditions.Add("m.SetCOM_Date IS NOT NULL AND m.Improve_Date IS NULL");
            }
            else if (string.Equals(mode, "Finish", StringComparison.OrdinalIgnoreCase))
            {
                conditions.Add("m.SetCOM_Date IS NOT NULL AND m.Improve_Date IS NOT NULL");
            }
            // 若為 'all' 則不限制案件狀態

            // 案號搜尋
            if (!string.IsNullOrEmpty(filter.SearchId))
            {
                conditions.Add("(m.BSC_ID LIKE '%' + @SearchId + '%' OR m.Show_ID LIKE '%' + @SearchId + '%')");
                parameters.Add(new SqlParameter("@SearchId", filter.SearchId.Trim()));
            }

            // 行政區
            if (!string.IsNullOrEmpty(filter.TownCode))
            {
                conditions.Add("m.TOWN_CODE = @TownCode");
                parameters.Add(new SqlParameter("@TownCode", filter.TownCode.Trim()));
            }

            // 道路名稱
            if (!string.IsNullOrEmpty(filter.RoadName))
            {
                conditions.Add("m.ROAD_Name LIKE '%' + @RoadName + '%'");
                parameters.Add(new SqlParameter("@RoadName", filter.RoadName.Trim()));
            }

            // 處理單位
            if (!string.IsNullOrEmpty(filter.UnitId))
            {
                conditions.Add("m.G_COM = @UnitId");
                parameters.Add(new SqlParameter("@UnitId", filter.UnitId.Trim()));
            }

            // 日期條件 (依據模式判斷對應時間欄位)
            string dateCol = "m.Report_Date";
            if (string.Equals(mode, "BSCImprove", StringComparison.OrdinalIgnoreCase)) dateCol = "m.SetCOM_Date";
            if (string.Equals(mode, "Finish", StringComparison.OrdinalIgnoreCase)) dateCol = "m.Improve_Date";

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

        // 5. 刪除案件
        private void DeleteCase(string bscId)
        {
            if (string.IsNullOrEmpty(bscId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "未提供通報案號" }));
                return;
            }

            string sql = "DELETE FROM RoadBSC_CaseMain WHERE BSC_ID = @id";
            int rows = DbHelper.ExecuteNonQuery(sql, new SqlParameter("@id", bscId));

            // 清理硬碟照片目錄
            try
            {
                if (!string.IsNullOrEmpty(bscId) && bscId.IndexOfAny(Path.GetInvalidFileNameChars()) < 0)
                {
                    string picDir = Server.MapPath("~/Upload/RoadBSCPIC/" + bscId);
                    if (Directory.Exists(picDir))
                    {
                        Directory.Delete(picDir, true);
                    }
                }
            }
            catch { }

            Response.Write(json.Serialize(new
            {
                Success = true,
                Message = "通報單 " + bscId + " 已成功刪除！"
            }));
        }

        // 6. 匯出 CSV
        private void ExportCsv()
        {
            string mode = Request["mode"] ?? "BSCEdit";
            SearchFilterModel filter = new SearchFilterModel();
            filter.Mode = mode;
            filter.SearchId = Request["searchId"] ?? "";
            filter.TownCode = Request["townCode"] ?? "";
            filter.RoadName = Request["roadName"] ?? "";
            filter.UnitId = Request["unitId"] ?? "";
            filter.DateS = Request["dateS"] ?? "";
            filter.DateE = Request["dateE"] ?? "";
            filter.PageIndex = 1;
            filter.PageSize = 5000;

            List<SqlParameter> paramList = new List<SqlParameter>();
            string whereClause = BuildWhereClause(filter, paramList);

            string sql = string.Format(@"
                SELECT 
                    m.BSC_ID,
                    ISNULL(m.Show_ID, m.BSC_ID) AS Show_ID,
                    m.Report_Date,
                    ISNULL(uRep.Name, m.Report_User) AS Report_UserName,
                    m.S_UTME,
                    m.S_UTMN,
                    t.TOWN_NA AS TownName,
                    m.ROAD_LV,
                    m.ROAD_Name,
                    dSmooth.Val AS SmoothName,
                    dCover.Val AS CoverSoilName,
                    m.Memo,
                    m.SetCOM_Date,
                    ISNULL(uSend.Name, m.S_User) AS S_UserName,
                    u.UnitName AS G_COM_NAME,
                    m.Improve_Date,
                    ISNULL(uGov.Name, m.G_User) AS G_UserName,
                    m.G_Memo
                FROM RoadBSC_CaseMain m
                LEFT JOIN C_TOWN t ON t.TOWN_NO = m.TOWN_CODE
                LEFT JOIN RoadBSC_Unit u ON u.UnitID = m.G_COM
                LEFT JOIN UserAcc uRep ON uRep.UserID = m.Report_User
                LEFT JOIN UserAcc uSend ON uSend.UserID = m.S_User
                LEFT JOIN UserAcc uGov ON uGov.UserID = m.G_User
                LEFT JOIN Dictionary dSmooth ON dSmooth.CodeType = 'RoadBSC_Smooth' AND dSmooth.Code = m.Smooth
                LEFT JOIN Dictionary dCover ON dCover.CodeType = 'RoadBSC_Cover_Soil' AND dCover.Code = m.Cover_Soil
                {0}
                ORDER BY m.Report_Date DESC", whereClause);

            DataTable dt = DbHelper.ExecuteDataTable(sql, paramList.ToArray());

            StringBuilder sb = new StringBuilder();
            sb.AppendLine("通報案號,查核時間,查核人員,行政區,道路級別,道路名稱,鋪面平整度,邊坡裸露地狀況,通報坐標X,通報坐標Y,通報時間,通報人員,處理單位,處理時間,處理人員,通報補充,處理備註");

            foreach (DataRow r in dt.Rows)
            {
                string rptDate = r["Report_Date"] != DBNull.Value ? Convert.ToDateTime(r["Report_Date"]).ToString("yyyy-MM-dd HH:mm") : "";
                string setDate = r["SetCOM_Date"] != DBNull.Value ? Convert.ToDateTime(r["SetCOM_Date"]).ToString("yyyy-MM-dd HH:mm") : "";
                string impDate = r["Improve_Date"] != DBNull.Value ? Convert.ToDateTime(r["Improve_Date"]).ToString("yyyy-MM-dd HH:mm") : "";
                string memo = r["Memo"] != DBNull.Value ? r["Memo"].ToString().Replace("\"", "\"\"").Replace("\r\n", " ").Replace("\n", " ") : "";
                string gMemo = r["G_Memo"] != DBNull.Value ? r["G_Memo"].ToString().Replace("\"", "\"\"").Replace("\r\n", " ").Replace("\n", " ") : "";

                sb.AppendFormat("\"{0}\",\"{1}\",\"{2}\",\"{3}\",\"{4}\",\"{5}\",\"{6}\",\"{7}\",\"{8}\",\"{9}\",\"{10}\",\"{11}\",\"{12}\",\"{13}\",\"{14}\",\"{15}\",\"{16}\"\r\n",
                    r["Show_ID"],
                    rptDate,
                    r["Report_UserName"],
                    r["TownName"],
                    r["ROAD_LV"],
                    r["ROAD_Name"],
                    r["SmoothName"],
                    r["CoverSoilName"],
                    r["S_UTME"],
                    r["S_UTMN"],
                    setDate,
                    r["S_UserName"],
                    r["G_COM_NAME"],
                    impDate,
                    r["G_UserName"],
                    memo,
                    gMemo);
            }

            Response.Clear();
            Response.Buffer = true;
            Response.AddHeader("content-disposition", "attachment;filename=RoadBSC_Export_" + DateTime.Now.ToString("yyyyMMdd_HHmmss") + ".csv");
            Response.Charset = "utf-8";
            Response.ContentType = "text/csv; charset=utf-8";

            // 寫入 UTF-8 BOM 避免 Excel 開啟亂碼
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

        private static string ComputeMd5(string input)
        {
            if (string.IsNullOrEmpty(input)) return "";
            using (MD5 md5 = MD5.Create())
            {
                byte[] inputBytes = Encoding.UTF8.GetBytes(input);
                byte[] hashBytes = md5.ComputeHash(inputBytes);
                StringBuilder sb = new StringBuilder();
                for (int i = 0; i < hashBytes.Length; i++)
                {
                    sb.Append(hashBytes[i].ToString("x2"));
                }
                return sb.ToString();
            }
        }
    }
}
