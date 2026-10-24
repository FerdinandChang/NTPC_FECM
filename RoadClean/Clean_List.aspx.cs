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
using NPOI.HSSF.UserModel;
using NPOI.SS.UserModel;

namespace NTPC_FEC.RoadClean
{
    public partial class Clean_List : Page
    {
        private JavaScriptSerializer json;

        public Clean_List()
        {
            json = new JavaScriptSerializer();
            json.MaxJsonLength = int.MaxValue;
        }

        public class SearchFilterModel
        {
            public string Mode { get; set; }
            public List<string> Towns { get; set; }
            public string RoadName { get; set; }
            public string DateS { get; set; }
            public string DateE { get; set; }
            public List<int> States { get; set; }
            public int PageIndex { get; set; }
            public int PageSize { get; set; }

            public SearchFilterModel()
            {
                Towns = new List<string>();
                States = new List<int>();
                PageIndex = 1;
                PageSize = 20;
            }
        }

        public class ExamineRequestModel
        {
            public string ChkId { get; set; }
            public int Result { get; set; }
            public string Memo { get; set; }
        }

        public class BatchExamineRequestModel
        {
            public List<string> ChkIds { get; set; }
            public string Memo { get; set; }

            public BatchExamineRequestModel()
            {
                ChkIds = new List<string>();
            }
        }

        public class ActionIdModel
        {
            public string ChkId { get; set; }
        }

        public class CaseValidationResult
        {
            public bool IsValid { get; set; }
            public string ChkId { get; set; }
            public string RoadName { get; set; }
            public List<string> Errors { get; set; }

            public CaseValidationResult()
            {
                Errors = new List<string>();
                IsValid = true;
            }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            string action = Request["action"];
            if (!string.IsNullOrEmpty(action))
            {
                Response.Clear();
                if (action.ToLower() == "exportexcel")
                {
                    HandleExportExcel();
                    return;
                }
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
                case "gettowns":
                    GetTowns();
                    break;
                case "getcounts":
                    GetCounts();
                    break;
                case "getlist":
                    GetList();
                    break;
                case "getpointdetail":
                    GetPointDetail(Request["chkId"]);
                    break;
                case "validatecase":
                    ValidateCaseAction();
                    break;
                case "putcheck":
                    PutCheck();
                    break;
                case "batchputcheck":
                case "multiputcheck":
                    BatchPutCheck();
                    break;
                case "examine":
                    ExamineCase();
                    break;
                case "multiexamine":
                    MultiExamine();
                    break;
                case "delete":
                    DeleteRecord();
                    break;
                default:
                    Response.Write(json.Serialize(new { Success = false, Message = "未知的操作指令" }));
                    break;
            }
        }

        // 1. 取得新北市行政區列表
        private void GetTowns()
        {
            string sql = "SELECT TOWN_NO, TOWN_NA FROM C_TOWN WHERE COUNTRY = 'F' ORDER BY TOWN_NO";
            DataTable dt = DbHelper.ExecuteDataTable(sql);
            List<object> list = new List<object>();
            foreach (DataRow row in dt.Rows)
            {
                list.Add(new
                {
                    TownNo = row["TOWN_NO"].ToString().Trim(),
                    TownName = row["TOWN_NA"].ToString().Trim()
                });
            }
            Response.Write(json.Serialize(new { Success = true, Data = list }));
        }

        // 2. 取得各業務分頁案件統計數量 (全表輕量彙總)
        private void GetCounts()
        {
            string sql = @"
                SELECT 
                    SUM(CASE WHEN Case_State IN (1001, 2201) THEN 1 ELSE 0 END) AS ApplyCount,
                    SUM(CASE WHEN Case_State = 2301 THEN 1 ELSE 0 END) AS BackCount,
                    SUM(CASE WHEN Case_State = 2001 THEN 1 ELSE 0 END) AS ExamineCount,
                    SUM(CASE WHEN Case_State = 2101 THEN 1 ELSE 0 END) AS SearchCount,
                    COUNT(*) AS TotalCount
                FROM RoadClean_ChkRecord_Main";

            DataTable dt = DbHelper.ExecuteDataTable(sql);
            int applyCount = 0;
            int backCount = 0;
            int examineCount = 0;
            int searchCount = 0;
            int totalCount = 0;

            if (dt.Rows.Count > 0)
            {
                DataRow r = dt.Rows[0];
                if (r["ApplyCount"] != DBNull.Value) applyCount = Convert.ToInt32(r["ApplyCount"]);
                if (r["BackCount"] != DBNull.Value) backCount = Convert.ToInt32(r["BackCount"]);
                if (r["ExamineCount"] != DBNull.Value) examineCount = Convert.ToInt32(r["ExamineCount"]);
                if (r["SearchCount"] != DBNull.Value) searchCount = Convert.ToInt32(r["SearchCount"]);
                if (r["TotalCount"] != DBNull.Value) totalCount = Convert.ToInt32(r["TotalCount"]);
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                Apply = applyCount,
                Back = backCount,
                Examine = examineCount,
                Search = searchCount,
                Total = totalCount
            }));
        }

        // 3. 高效能伺服器端分頁查詢 (CTE + OFFSET-FETCH，消除全表巢狀子查詢瓶頸)
        private void GetList()
        {
            string jsonBody = "";
            using (StreamReader reader = new StreamReader(Request.InputStream))
            {
                jsonBody = reader.ReadToEnd();
            }

            SearchFilterModel filter = null;
            if (!string.IsNullOrEmpty(jsonBody))
            {
                filter = json.Deserialize<SearchFilterModel>(jsonBody);
            }
            if (filter == null)
            {
                filter = new SearchFilterModel();
                filter.Mode = Request["mode"] != null ? Request["mode"].ToString() : "apply";
                filter.RoadName = Request["roadName"] != null ? Request["roadName"].ToString() : "";
                filter.DateS = Request["dateS"] != null ? Request["dateS"].ToString() : "";
                filter.DateE = Request["dateE"] != null ? Request["dateE"].ToString() : "";
            }

            StringBuilder where = new StringBuilder(" WHERE 1=1 ");
            List<SqlParameter> paramList = new List<SqlParameter>();

            // 行政區過濾
            if (filter.Towns != null && filter.Towns.Count > 0)
            {
                List<string> townParams = new List<string>();
                for (int i = 0; i < filter.Towns.Count; i++)
                {
                    string pName = "@town_" + i;
                    townParams.Add(pName);
                    paramList.Add(new SqlParameter(pName, filter.Towns[i]));
                }
                where.Append(" AND R.TOWN IN (" + string.Join(",", townParams.ToArray()) + ") ");
            }

            // 道路名稱過濾
            if (!string.IsNullOrEmpty(filter.RoadName))
            {
                where.Append(" AND R.RoadName LIKE @roadName ");
                paramList.Add(new SqlParameter("@roadName", "%" + filter.RoadName.Trim() + "%"));
            }

            // 巡查日期區間 (若有傳入則依日期篩選，無傳入則不限日期以提升彈性)
            if (!string.IsNullOrEmpty(filter.DateS))
            {
                DateTime dtS;
                if (DateTime.TryParse(filter.DateS, out dtS))
                {
                    where.Append(" AND M.ChkDate >= @dateS ");
                    paramList.Add(new SqlParameter("@dateS", dtS.ToString("yyyy-MM-dd 00:00:00")));
                }
            }
            if (!string.IsNullOrEmpty(filter.DateE))
            {
                DateTime dtE;
                if (DateTime.TryParse(filter.DateE, out dtE))
                {
                    where.Append(" AND M.ChkDate <= @dateE ");
                    paramList.Add(new SqlParameter("@dateE", dtE.ToString("yyyy-MM-dd 23:59:59")));
                }
            }

            // 案件狀態過濾
            if (filter.States != null && filter.States.Count > 0)
            {
                List<string> stateParams = new List<string>();
                for (int i = 0; i < filter.States.Count; i++)
                {
                    string pName = "@state_" + i;
                    stateParams.Add(pName);
                    paramList.Add(new SqlParameter(pName, filter.States[i]));
                }
                where.Append(" AND M.Case_State IN (" + string.Join(",", stateParams.ToArray()) + ") ");
            }
            else if (!string.IsNullOrEmpty(filter.Mode))
            {
                switch (filter.Mode.ToLower())
                {
                    case "apply":
                        where.Append(" AND M.Case_State IN (1001, 2201) ");
                        break;
                    case "back":
                        where.Append(" AND M.Case_State = 2301 ");
                        break;
                    case "examine":
                        where.Append(" AND M.Case_State = 2001 ");
                        break;
                    case "search":
                        where.Append(" AND M.Case_State = 2101 ");
                        break;
                    case "all":
                    default:
                        break;
                }
            }

            // 1. 計算符合條件的總筆數 (極速純計數)
            string countSql = "SELECT COUNT(*) FROM RoadClean_ChkRecord_Main M LEFT JOIN RoadClean_CheckPointMain R ON M.ChkRoadID = R.RDID " + where.ToString();
            List<SqlParameter> countParams = new List<SqlParameter>();
            foreach (SqlParameter p in paramList)
            {
                countParams.Add(new SqlParameter(p.ParameterName, p.Value));
            }
            int totalCount = Convert.ToInt32(DbHelper.ExecuteScalar(countSql, countParams.ToArray()));

            // 計算分頁參數
            int pageIndex = filter.PageIndex > 0 ? filter.PageIndex : 1;
            int pageSize = filter.PageSize > 0 ? filter.PageSize : 20;
            int skip = (pageIndex - 1) * pageSize;
            int totalPages = (int)Math.Ceiling((double)totalCount / pageSize);

            // 2. 使用 CTE 分頁：僅對當前分頁的 20 筆資料進行評分與明細子查詢
            string sql = @"
                WITH PagedMain AS (
                    SELECT 
                        M.ChkID, 
                        M.ChkRoadID, 
                        M.ChkDate, 
                        M.Case_State, 
                        M.Create_User,
                        R.TOWN, 
                        R.RoadName, 
                        R.dis, 
                        R.wid
                    FROM RoadClean_ChkRecord_Main M
                    LEFT JOIN RoadClean_CheckPointMain R ON M.ChkRoadID = R.RDID "
                    + where.ToString() + @"
                    ORDER BY M.ChkDate DESC, M.ChkID DESC
                    OFFSET @skip ROWS FETCH NEXT @take ROWS ONLY
                )
                SELECT 
                    P.ChkID, 
                    P.ChkRoadID, 
                    P.ChkDate, 
                    P.Case_State, 
                    P.Create_User,
                    P.TOWN, 
                    P.RoadName, 
                    P.dis, 
                    P.wid,
                    (SELECT COUNT(*) FROM RoadClean_ChkRecord_PointMain PM WHERE PM.ChkID = P.ChkID) AS PointCount,
                    (SELECT AVG(Score) FROM RoadClean_ChkRecord_PointScore PS WHERE PS.ChkID = P.ChkID AND PS.Chk_Code LIKE 'RCC%') AS RoadScore,
                    (SELECT SUM(Score) FROM RoadClean_ChkRecord_PointScore PS WHERE PS.ChkID = P.ChkID AND PS.Chk_Code LIKE 'FLD%') 
                        / NULLIF((SELECT COUNT(*) FROM RoadClean_ChkRecord_PointMain PM WHERE PM.ChkID = P.ChkID), 0) AS FloodScore,
                    (SELECT TOP 1 ExamineMemo FROM RoadClean_ExamineData ED WHERE ED.ChkID = P.ChkID ORDER BY ExamineDate DESC) AS ExamineMemo
                FROM PagedMain P
                ORDER BY P.ChkDate DESC, P.ChkID DESC";

            paramList.Add(new SqlParameter("@skip", SqlDbType.Int) { Value = skip });
            paramList.Add(new SqlParameter("@take", SqlDbType.Int) { Value = pageSize });

            DataTable dt = DbHelper.ExecuteDataTable(sql, paramList.ToArray());
            List<object> resultList = new List<object>();

            foreach (DataRow row in dt.Rows)
            {
                string chkId = row["ChkID"].ToString().Trim();
                string town = row["TOWN"] != DBNull.Value ? row["TOWN"].ToString().Trim() : "";
                string roadName = row["RoadName"] != DBNull.Value ? row["RoadName"].ToString().Trim() : "";
                string chkDateStr = row["ChkDate"] != DBNull.Value ? Convert.ToDateTime(row["ChkDate"]).ToString("yyyy-MM-dd HH:mm") : "";
                int caseState = row["Case_State"] != DBNull.Value ? Convert.ToInt32(row["Case_State"]) : 1001;
                string createUser = row["Create_User"] != DBNull.Value ? row["Create_User"].ToString().Trim() : "";
                string examineMemo = row["ExamineMemo"] != DBNull.Value ? row["ExamineMemo"].ToString().Trim() : "";
                int pointCount = row["PointCount"] != DBNull.Value ? Convert.ToInt32(row["PointCount"]) : 0;

                // 道路潔淨評級
                int roadScore = -1;
                if (row["RoadScore"] != DBNull.Value)
                {
                    roadScore = Convert.ToInt32(Math.Round(Convert.ToDouble(row["RoadScore"])));
                }

                string roadScoreLv = "未調查";
                if (roadScore >= 85) roadScoreLv = "A級";
                else if (roadScore >= 60) roadScoreLv = "B級";
                else if (roadScore >= 0) roadScoreLv = "C級";

                // 淹水潛勢評級
                int floodScore = -1;
                if (row["FloodScore"] != DBNull.Value)
                {
                    floodScore = Convert.ToInt32(Math.Round(Convert.ToDouble(row["FloodScore"])));
                }

                string floodScoreLv = "未調查";
                if (floodScore >= 85) floodScoreLv = "A級";
                else if (floodScore >= 60) floodScoreLv = "B級";
                else if (floodScore >= 0) floodScoreLv = "C級";

                // 狀態名稱與徽章
                string stateName = "審查未送出";
                string stateBadge = "badge-secondary";
                switch (caseState)
                {
                    case 1001:
                        stateName = "審查未送出";
                        stateBadge = "badge-secondary";
                        break;
                    case 2001:
                        stateName = "審查中";
                        stateBadge = "badge-primary";
                        break;
                    case 2101:
                        stateName = "審查通過";
                        stateBadge = "badge-success";
                        break;
                    case 2201:
                        stateName = "駁回";
                        stateBadge = "badge-danger";
                        break;
                    case 2301:
                        stateName = "退回補正";
                        stateBadge = "badge-warning text-dark";
                        break;
                    case 9001:
                        stateName = "案件取消";
                        stateBadge = "badge-dark";
                        break;
                }

                resultList.Add(new
                {
                    ChkId = chkId,
                    Town = town,
                    RoadName = roadName,
                    ChkDate = chkDateStr,
                    CaseState = caseState,
                    StateName = stateName,
                    StateBadge = stateBadge,
                    CreateUser = createUser,
                    RoadScore = roadScore,
                    RoadScoreLv = roadScoreLv,
                    FloodScore = floodScore,
                    FloodScoreLv = floodScoreLv,
                    ExamineMemo = examineMemo,
                    PointCount = pointCount
                });
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                Data = resultList,
                Total = totalCount,
                PageIndex = pageIndex,
                PageSize = pageSize,
                TotalPages = totalPages
            }));
        }

        // 4. 按需載入單一巡檢案的檢核點明細 (點擊彈窗時即時獲取，不拖慢清單速度)
        private void GetPointDetail(string chkId)
        {
            if (string.IsNullOrEmpty(chkId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "無效的單號" }));
                return;
            }

            string sql = @"
                SELECT 
                    PM.Point_ID,
                    PM.pIndex,
                    PM.P_LV,
                    CP.PointPlace,
                    (SELECT AVG(Score) FROM RoadClean_ChkRecord_PointScore PS WHERE PS.ChkID = PM.ChkID AND PS.Point_ID = PM.Point_ID AND PS.Chk_Code LIKE 'RCC%') AS Score
                FROM RoadClean_ChkRecord_PointMain PM
                LEFT JOIN RoadClean_CheckPointList CP ON PM.Point_ID = CP.Point_ID
                WHERE PM.ChkID = @chkId
                ORDER BY PM.pIndex ASC";

            DataTable dt = DbHelper.ExecuteDataTable(sql, new SqlParameter("@chkId", chkId));
            List<object> list = new List<object>();
            foreach (DataRow r in dt.Rows)
            {
                int sc = r["Score"] != DBNull.Value ? Convert.ToInt32(Math.Round(Convert.ToDouble(r["Score"]))) : 0;
                string lv = r["P_LV"] != DBNull.Value && !string.IsNullOrEmpty(r["P_LV"].ToString())
                    ? r["P_LV"].ToString().Trim()
                    : (sc >= 85 ? "A級" : (sc >= 60 ? "B級" : (sc > 0 ? "C級" : "未調查")));

                list.Add(new
                {
                    PointId = r["Point_ID"].ToString().Trim(),
                    PIndex = r["pIndex"] != DBNull.Value ? Convert.ToInt32(r["pIndex"]) : 1,
                    Place = r["PointPlace"] != DBNull.Value ? r["PointPlace"].ToString().Trim() : "檢核點",
                    Score = sc,
                    ScoreLv = lv
                });
            }

            Response.Write(json.Serialize(new { Success = true, Data = list }));
        }

        // 4.5 驗證案件表單填寫與照片完整度 (提供單筆預檢或防呆)
        private void ValidateCaseAction()
        {
            string jsonBody = "";
            using (StreamReader reader = new StreamReader(Request.InputStream))
            {
                jsonBody = reader.ReadToEnd();
            }

            ActionIdModel model = null;
            if (!string.IsNullOrEmpty(jsonBody))
            {
                try { model = json.Deserialize<ActionIdModel>(jsonBody); } catch { }
            }

            string chkId = model != null && !string.IsNullOrEmpty(model.ChkId) ? model.ChkId : Request["chkId"];
            if (string.IsNullOrEmpty(chkId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "未提供查核單號" }));
                return;
            }

            CaseValidationResult result = ValidateCaseCompleteness(chkId);
            Response.Write(json.Serialize(new
            {
                Success = true,
                IsValid = result.IsValid,
                ChkId = result.ChkId,
                RoadName = result.RoadName,
                Errors = result.Errors
            }));
        }

        // 核心檢核邏輯：防呆驗證表單欄位與照片 (現場照片至少2張、道路淹水潛勢照片至少1張)
        private CaseValidationResult ValidateCaseCompleteness(string chkId)
        {
            CaseValidationResult result = new CaseValidationResult();
            result.ChkId = chkId;
            result.IsValid = true;

            if (string.IsNullOrEmpty(chkId))
            {
                result.IsValid = false;
                result.Errors.Add("查核單號不可為空");
                return result;
            }

            // 1. 查詢主檔與道路基本資訊
            string sqlMain = @"SELECT M.ChkID, M.ChkRoadID, M.ChkDate, M.Case_State, R.RoadName, R.TOWN 
                               FROM RoadClean_ChkRecord_Main M 
                               LEFT JOIN RoadClean_CheckPointMain R ON M.ChkRoadID = R.RDID 
                               WHERE M.ChkID = @chkId";
            DataTable dtMain = DbHelper.ExecuteDataTable(sqlMain, new SqlParameter("@chkId", chkId));
            if (dtMain.Rows.Count == 0)
            {
                result.IsValid = false;
                result.Errors.Add("查無此查核紀錄單號 (" + chkId + ")");
                return result;
            }

            DataRow mainRow = dtMain.Rows[0];
            result.RoadName = mainRow["RoadName"] != DBNull.Value ? mainRow["RoadName"].ToString().Trim() : "未知道路";

            if (mainRow["ChkRoadID"] == DBNull.Value || string.IsNullOrEmpty(mainRow["ChkRoadID"].ToString().Trim()))
            {
                result.Errors.Add("巡檢道路尚未設定或基本資料遺失");
            }

            if (mainRow["ChkDate"] == DBNull.Value)
            {
                result.Errors.Add("未填寫巡檢日期時間");
            }

            // 2. 查詢檢核點位資料
            string sqlPoints = @"SELECT P.Point_ID, P.pIndex, P.S_Tree, P.S_island, P.Civil_Side, 
                                        ISNULL(L.PointPlace, '第' + CAST(P.pIndex AS varchar) + '檢核點') AS PointPlace 
                                 FROM RoadClean_ChkRecord_PointMain P 
                                 LEFT JOIN RoadClean_CheckPointList L ON P.Point_ID = L.Point_ID 
                                 WHERE P.ChkID = @chkId 
                                 ORDER BY P.pIndex ASC";
            DataTable dtPoints = DbHelper.ExecuteDataTable(sqlPoints, new SqlParameter("@chkId", chkId));
            if (dtPoints.Rows.Count == 0)
            {
                result.Errors.Add("該案件尚未建立任何巡檢點位資料");
            }

            // 3. 查詢評分項目資料
            string sqlScores = @"SELECT Point_ID, Chk_Code, Score 
                                 FROM RoadClean_ChkRecord_PointScore 
                                 WHERE ChkID = @chkId";
            DataTable dtScores = DbHelper.ExecuteDataTable(sqlScores, new SqlParameter("@chkId", chkId));

            // 逐點位檢查評分是否齊全 (含特殊題跳過規則)
            foreach (DataRow pt in dtPoints.Rows)
            {
                string ptId = pt["Point_ID"] != DBNull.Value ? pt["Point_ID"].ToString().Trim() : "";
                string ptPlace = pt["PointPlace"] != DBNull.Value ? pt["PointPlace"].ToString().Trim() : "檢核點";
                string sTree = pt["S_Tree"] != DBNull.Value ? pt["S_Tree"].ToString().Trim() : "N";
                string sIsland = pt["S_island"] != DBNull.Value ? pt["S_island"].ToString().Trim() : "N";
                string civilSide = pt["Civil_Side"] != DBNull.Value ? pt["Civil_Side"].ToString().Trim() : "N";

                DataRow[] ptScores = dtScores.Select(string.Format("Point_ID = '{0}'", ptId.Replace("'", "''")));
                if (ptScores.Length == 0)
                {
                    result.Errors.Add(string.Format("點位「{0}」尚未填寫潔淨度與淹水潛勢評估項目", ptPlace));
                }
                else
                {
                    int unratedCount = 0;
                    for (int i = 0; i < ptScores.Length; i++)
                    {
                        string code = ptScores[i]["Chk_Code"] != DBNull.Value ? ptScores[i]["Chk_Code"].ToString().Trim() : "";
                        bool isScoreNull = ptScores[i]["Score"] == DBNull.Value;

                        // 特殊題目豁免判斷 (無設置則免評)
                        if (code == "RCC004" && sIsland != "Y") continue;
                        if (code == "RCC005" && sTree != "Y") continue;
                        if (code == "RCC006" && civilSide != "Y") continue;

                        if (isScoreNull)
                        {
                            unratedCount++;
                        }
                    }

                    if (unratedCount > 0)
                    {
                        result.Errors.Add(string.Format("點位「{0}」尚有 {1} 項評核指標未完成評分", ptPlace, unratedCount));
                    }
                }
            }

            // 4. 照片完整性檢核：現場照片至少 2 張、道路淹水潛勢照片至少 1 張
            string uploadDir = Server.MapPath("~/Upload/RoadCleanPIC/" + chkId);
            if (!Directory.Exists(uploadDir))
            {
                string altDir = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "Upload", "RoadCleanPIC", chkId);
                if (Directory.Exists(altDir))
                {
                    uploadDir = altDir;
                }
            }

            if (!Directory.Exists(uploadDir))
            {
                result.Errors.Add("尚未上傳任何現場照片與淹水照片（伺服器無照片目錄）");
            }
            else
            {
                DirectoryInfo dirInfo = new DirectoryInfo(uploadDir);

                if (dtPoints.Rows.Count > 0)
                {
                    foreach (DataRow pt in dtPoints.Rows)
                    {
                        string ptId = pt["Point_ID"] != DBNull.Value ? pt["Point_ID"].ToString().Trim() : "";
                        string ptPlace = pt["PointPlace"] != DBNull.Value ? pt["PointPlace"].ToString().Trim() : "檢核點";

                        // (A) 現場照片檢核：至少 2 張
                        int siteCount = 0;
                        FileInfo[] site1 = dirInfo.GetFiles(ptId + "_現場照片.*");
                        if (site1.Length > 0 && site1[0].Length > 0) siteCount++;

                        FileInfo[] site2 = dirInfo.GetFiles(ptId + "_現場照片1.*");
                        if (site2.Length > 0 && site2[0].Length > 0) siteCount++;

                        // 容錯支援 {Point_ID}_現場照片*.* 形式
                        if (siteCount < 2)
                        {
                            FileInfo[] allSite = dirInfo.GetFiles(ptId + "_現場照片*.*");
                            int validFiles = 0;
                            for (int f = 0; f < allSite.Length; f++)
                            {
                                if (allSite[f].Length > 0) validFiles++;
                            }
                            if (validFiles > siteCount) siteCount = validFiles;
                        }

                        if (siteCount < 2)
                        {
                            result.Errors.Add(string.Format("點位「{0}」現場照片缺漏（規定至少 2 張，目前僅上傳 {1} 張）", ptPlace, siteCount));
                        }

                        // (B) 淹水潛勢照片檢核：至少 1 張
                        int floodCount = 0;
                        FileInfo[] flood1 = dirInfo.GetFiles(ptId + "_淹水潛勢照片.*");
                        if (flood1.Length > 0 && flood1[0].Length > 0) floodCount++;

                        FileInfo[] flood2 = dirInfo.GetFiles(ptId + "_淹水潛勢照片1.*");
                        if (flood2.Length > 0 && flood2[0].Length > 0) floodCount++;

                        if (floodCount == 0)
                        {
                            FileInfo[] allFlood = dirInfo.GetFiles(ptId + "_淹水潛勢照片*.*");
                            for (int f = 0; f < allFlood.Length; f++)
                            {
                                if (allFlood[f].Length > 0) { floodCount++; break; }
                            }
                        }

                        if (floodCount < 1)
                        {
                            result.Errors.Add(string.Format("點位「{0}」缺少道路淹水潛勢照片（至少需上傳 1 張）", ptPlace));
                        }
                    }
                }
                else
                {
                    // 無點位記錄時以全域檔案計
                    FileInfo[] allSite = dirInfo.GetFiles("*現場照片*.*");
                    int validSite = 0;
                    for (int f = 0; f < allSite.Length; f++) { if (allSite[f].Length > 0) validSite++; }

                    FileInfo[] allFlood = dirInfo.GetFiles("*淹水*.*");
                    int validFlood = 0;
                    for (int f = 0; f < allFlood.Length; f++) { if (allFlood[f].Length > 0) validFlood++; }

                    if (validSite < 2)
                    {
                        result.Errors.Add(string.Format("現場照片缺漏（規定至少 2 張，目前僅上傳 {0} 張）", validSite));
                    }
                    if (validFlood < 1)
                    {
                        result.Errors.Add("缺少道路淹水潛勢照片（至少需上傳 1 張）");
                    }
                }
            }

            if (result.Errors.Count > 0)
            {
                result.IsValid = false;
            }

            return result;
        }

        // 5. 送出審查 (Case_State 1001 / 2301 -> 2001) 含嚴格防呆阻擋
        private void PutCheck()
        {
            string jsonBody = "";
            using (StreamReader reader = new StreamReader(Request.InputStream))
            {
                jsonBody = reader.ReadToEnd();
            }

            ActionIdModel model = json.Deserialize<ActionIdModel>(jsonBody);
            string chkId = model != null ? model.ChkId : Request["chkId"];

            if (string.IsNullOrEmpty(chkId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "無效的巡檢單號" }));
                return;
            }

            // 執行完整性與照片檢核防呆
            CaseValidationResult valResult = ValidateCaseCompleteness(chkId);
            if (!valResult.IsValid)
            {
                Response.Write(json.Serialize(new
                {
                    Success = false,
                    Message = "送審檢核未通過：表單填寫不完整或照片有缺漏，無法送審！",
                    Errors = valResult.Errors
                }));
                return;
            }

            string loginUser = Session["LoginUser"] != null ? Session["LoginUser"].ToString() : "System";
            string sql = @"UPDATE RoadClean_ChkRecord_Main 
                           SET Case_State = 2001, Update_Date = GETDATE(), Update_User = @user 
                           WHERE ChkID = @chkId";

            int affected = DbHelper.ExecuteNonQuery(sql,
                new SqlParameter("@user", loginUser),
                new SqlParameter("@chkId", chkId));

            if (affected > 0)
            {
                Response.Write(json.Serialize(new { Success = true, Message = "已成功送出審查！" }));
            }
            else
            {
                Response.Write(json.Serialize(new { Success = false, Message = "更新失敗，查無此案件" }));
            }
        }

        // 批次送出審查 (批次送件: Case_State 1001, 2301, 2201 -> 2001) 含逐筆防呆檢核過濾
        private void BatchPutCheck()
        {
            string jsonBody = "";
            using (StreamReader reader = new StreamReader(Request.InputStream))
            {
                jsonBody = reader.ReadToEnd();
            }

            BatchExamineRequestModel model = json.Deserialize<BatchExamineRequestModel>(jsonBody);
            if (model == null || model.ChkIds == null || model.ChkIds.Count == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "請至少勾選一筆送審案件" }));
                return;
            }

            string loginUser = Session["LoginUser"] != null ? Session["LoginUser"].ToString() : "System";
            List<string> passedIds = new List<string>();
            List<object> failedCases = new List<object>();

            // 逐筆進行表單與照片檢核
            foreach (string chkId in model.ChkIds)
            {
                if (string.IsNullOrEmpty(chkId)) continue;

                CaseValidationResult val = ValidateCaseCompleteness(chkId);
                if (val.IsValid)
                {
                    passedIds.Add(chkId);
                }
                else
                {
                    failedCases.Add(new
                    {
                        ChkId = chkId,
                        RoadName = val.RoadName,
                        Errors = val.Errors
                    });
                }
            }

            // 僅對合格案件執行送審更新
            int successCount = 0;
            if (passedIds.Count > 0)
            {
                foreach (string passId in passedIds)
                {
                    string sqlUpdate = @"UPDATE RoadClean_ChkRecord_Main 
                                         SET Case_State = 2001, Update_Date = GETDATE(), Update_User = @user 
                                         WHERE ChkID = @chkId AND Case_State IN (1001, 2301, 2201)";
                    int rows = DbHelper.ExecuteNonQuery(sqlUpdate,
                        new SqlParameter("@user", loginUser),
                        new SqlParameter("@chkId", passId));

                    if (rows > 0) successCount++;
                }
            }

            string message = "";
            if (failedCases.Count == 0)
            {
                message = string.Format("全數檢核合格！已成功批次送出審查 {0} 筆案件！", successCount);
            }
            else if (successCount > 0)
            {
                message = string.Format("已成功送出 {0} 筆案件，另有 {1} 筆因表單未齊或缺照片已自動攔截未送出。", successCount, failedCases.Count);
            }
            else
            {
                message = string.Format("勾選之 {0} 筆案件均未通過完整性或照片檢核，已全數攔截阻擋！", failedCases.Count);
            }

            Response.Write(json.Serialize(new
            {
                Success = successCount > 0 || (passedIds.Count == 0 && failedCases.Count > 0),
                PassedCount = successCount,
                FailedCount = failedCases.Count,
                FailedCases = failedCases,
                Message = message
            }));
        }

        // 6. 單筆案件審核 (通過 2101 / 退回修正 2301 / 駁回 2201)
        private void ExamineCase()
        {
            string jsonBody = "";
            using (StreamReader reader = new StreamReader(Request.InputStream))
            {
                jsonBody = reader.ReadToEnd();
            }

            ExamineRequestModel model = json.Deserialize<ExamineRequestModel>(jsonBody);
            if (model == null || string.IsNullOrEmpty(model.ChkId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "審核參數無效" }));
                return;
            }

            string loginUser = Session["LoginUser"] != null ? Session["LoginUser"].ToString() : "Admin";
            int resultState = model.Result;
            string resultText = "通過";
            if (resultState == 2301) resultText = "退回修正";
            else if (resultState == 2201) resultText = "駁回";

            string memo = !string.IsNullOrEmpty(model.Memo) ? model.Memo.Trim() : (resultState == 2101 ? "審核通過" : "");

            // 取得當前最大 pIndex
            string sqlMax = "SELECT ISNULL(MAX(pIndex), 0) FROM RoadClean_ExamineData WHERE ChkID = @chkId";
            object maxObj = DbHelper.ExecuteScalar(sqlMax, new SqlParameter("@chkId", model.ChkId));
            int nextPIndex = 1;
            if (maxObj != null && maxObj != DBNull.Value)
            {
                nextPIndex = Convert.ToInt32(maxObj) + 1;
            }

            // 寫入審核歷程
            string sqlInsertExamine = @"INSERT INTO RoadClean_ExamineData 
                                       (ChkID, pIndex, ExamineResult, ExamineMemo, ExamineUser, ExamineDate) 
                                       VALUES (@chkId, @pIndex, @resultText, @memo, @user, GETDATE())";

            DbHelper.ExecuteNonQuery(sqlInsertExamine,
                new SqlParameter("@chkId", model.ChkId),
                new SqlParameter("@pIndex", nextPIndex),
                new SqlParameter("@resultText", resultText),
                new SqlParameter("@memo", memo),
                new SqlParameter("@user", loginUser));

            // 更新主檔狀態
            string sqlUpdateMain = @"UPDATE RoadClean_ChkRecord_Main 
                                    SET Case_State = @state, Update_Date = GETDATE(), Update_User = @user 
                                    WHERE ChkID = @chkId";

            DbHelper.ExecuteNonQuery(sqlUpdateMain,
                new SqlParameter("@state", resultState),
                new SqlParameter("@user", loginUser),
                new SqlParameter("@chkId", model.ChkId));

            Response.Write(json.Serialize(new
            {
                Success = true,
                Message = string.Format("巡檢單 {0} 審核完成 ({1})！", model.ChkId, resultText)
            }));
        }

        // 7. 批次快速審核通過
        private void MultiExamine()
        {
            string jsonBody = "";
            using (StreamReader reader = new StreamReader(Request.InputStream))
            {
                jsonBody = reader.ReadToEnd();
            }

            BatchExamineRequestModel model = json.Deserialize<BatchExamineRequestModel>(jsonBody);
            if (model == null || model.ChkIds == null || model.ChkIds.Count == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "請至少勾選一筆審查案件" }));
                return;
            }

            string loginUser = Session["LoginUser"] != null ? Session["LoginUser"].ToString() : "Admin";
            string memo = !string.IsNullOrEmpty(model.Memo) ? model.Memo.Trim() : "快速審查通過";
            int successCount = 0;

            foreach (string chkId in model.ChkIds)
            {
                if (string.IsNullOrEmpty(chkId)) continue;

                string sqlMax = "SELECT ISNULL(MAX(pIndex), 0) FROM RoadClean_ExamineData WHERE ChkID = @chkId";
                object maxObj = DbHelper.ExecuteScalar(sqlMax, new SqlParameter("@chkId", chkId));
                int nextPIndex = 1;
                if (maxObj != null && maxObj != DBNull.Value)
                {
                    nextPIndex = Convert.ToInt32(maxObj) + 1;
                }

                string sqlInsert = @"INSERT INTO RoadClean_ExamineData 
                                    (ChkID, pIndex, ExamineResult, ExamineMemo, ExamineUser, ExamineDate) 
                                    VALUES (@chkId, @pIndex, @resultText, @memo, @user, GETDATE())";
                DbHelper.ExecuteNonQuery(sqlInsert,
                    new SqlParameter("@chkId", chkId),
                    new SqlParameter("@pIndex", nextPIndex),
                    new SqlParameter("@resultText", "通過"),
                    new SqlParameter("@memo", memo),
                    new SqlParameter("@user", loginUser));

                string sqlUpdate = @"UPDATE RoadClean_ChkRecord_Main 
                                    SET Case_State = 2101, Update_Date = GETDATE(), Update_User = @user 
                                    WHERE ChkID = @chkId";
                int rows = DbHelper.ExecuteNonQuery(sqlUpdate,
                    new SqlParameter("@user", loginUser),
                    new SqlParameter("@chkId", chkId));

                if (rows > 0) successCount++;
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                Message = string.Format("已成功快速審核通過 {0} 筆案件！", successCount),
                Count = successCount
            }));
        }

        // 8. 刪除草稿紀錄 (只限 1001 審查未送出)
        private void DeleteRecord()
        {
            string jsonBody = "";
            using (StreamReader reader = new StreamReader(Request.InputStream))
            {
                jsonBody = reader.ReadToEnd();
            }

            ActionIdModel model = json.Deserialize<ActionIdModel>(jsonBody);
            string chkId = model != null ? model.ChkId : Request["chkId"];

            if (string.IsNullOrEmpty(chkId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "無效的巡檢單號" }));
                return;
            }

            string sqlCheck = "SELECT Case_State FROM RoadClean_ChkRecord_Main WHERE ChkID = @chkId";
            object stateObj = DbHelper.ExecuteScalar(sqlCheck, new SqlParameter("@chkId", chkId));
            if (stateObj == null || stateObj == DBNull.Value)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "查無此查核紀錄" }));
                return;
            }

            int state = Convert.ToInt32(stateObj);
            if (state != 1001)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "非暫存草稿案件不可刪除！" }));
                return;
            }

            DbHelper.ExecuteNonQuery("DELETE FROM RoadClean_ChkRecord_PointScore WHERE ChkID = @chkId", new SqlParameter("@chkId", chkId));
            DbHelper.ExecuteNonQuery("DELETE FROM RoadClean_ChkRecord_PointMain WHERE ChkID = @chkId", new SqlParameter("@chkId", chkId));
            DbHelper.ExecuteNonQuery("DELETE FROM RoadClean_ExamineData WHERE ChkID = @chkId", new SqlParameter("@chkId", chkId));
            DbHelper.ExecuteNonQuery("DELETE FROM RoadClean_ChkRecord_Main WHERE ChkID = @chkId", new SqlParameter("@chkId", chkId));

            try
            {
                string targetDir = Server.MapPath("~/Upload/RoadCleanPIC/" + chkId);
                if (Directory.Exists(targetDir))
                {
                    Directory.Delete(targetDir, true);
                }
            }
            catch
            {
                // 忽略檔案清理異常
            }

            Response.Write(json.Serialize(new { Success = true, Message = "巡檢草稿紀錄已成功刪除！" }));
        }
    
                #region 匯出 Excel 報表
        private void HandleExportExcel()
        {
            try
            {
                string mode = Request["mode"] != null ? Request["mode"].Trim().ToLower() : "apply";
                string town = Request["town"] != null ? Request["town"].Trim() : "";
                string roadName = Request["roadName"] != null ? Request["roadName"].Trim() : "";
                string chkId = Request["chkId"] != null ? Request["chkId"].Trim() : "";
                string chkDateS = Request["chkDateS"] != null ? Request["chkDateS"].Trim() : "";
                string chkDateE = Request["chkDateE"] != null ? Request["chkDateE"].Trim() : "";

                StringBuilder where = new StringBuilder(" WHERE 1=1 ");
                List<SqlParameter> pList = new List<SqlParameter>();

                if (!string.IsNullOrEmpty(town))
                {
                    where.Append(" AND R.TOWN = @Town ");
                    pList.Add(new SqlParameter("@Town", town));
                }
                if (!string.IsNullOrEmpty(roadName))
                {
                    where.Append(" AND R.RoadName LIKE @RoadName ");
                    pList.Add(new SqlParameter("@RoadName", "%" + roadName + "%"));
                }
                if (!string.IsNullOrEmpty(chkId))
                {
                    where.Append(" AND M.ChkID LIKE @ChkId ");
                    pList.Add(new SqlParameter("@ChkId", "%" + chkId + "%"));
                }
                DateTime dtS;
                if (DateTime.TryParse(chkDateS, out dtS))
                {
                    where.Append(" AND M.ChkDate >= @dateS ");
                    pList.Add(new SqlParameter("@dateS", dtS.ToString("yyyy-MM-dd 00:00:00")));
                }
                DateTime dtE;
                if (DateTime.TryParse(chkDateE, out dtE))
                {
                    where.Append(" AND M.ChkDate <= @dateE ");
                    pList.Add(new SqlParameter("@dateE", dtE.ToString("yyyy-MM-dd 23:59:59")));
                }

                switch (mode)
                {
                    case "apply":
                        where.Append(" AND M.Case_State IN (1001, 2201) ");
                        break;
                    case "back":
                        where.Append(" AND M.Case_State = 2301 ");
                        break;
                    case "examine":
                        where.Append(" AND M.Case_State = 2001 ");
                        break;
                    case "search":
                        where.Append(" AND M.Case_State = 2101 ");
                        break;
                    case "all":
                    default:
                        break;
                }

                string sql = @"
                    SELECT 
                        M.ChkID, 
                        M.ChkRoadID, 
                        M.ChkDate, 
                        M.Case_State, 
                        M.Create_User,
                        R.TOWN, 
                        R.RoadName, 
                        R.RDLV,
                        ISNULL(R.dis, 0) AS Dis, 
                        ISNULL(R.wid, 0) AS Wid,
                        (SELECT COUNT(*) FROM RoadClean_ChkRecord_PointMain PM WHERE PM.ChkID = M.ChkID) AS PointCount,
                        (SELECT AVG(Score) FROM RoadClean_ChkRecord_PointScore PS WHERE PS.ChkID = M.ChkID AND PS.Chk_Code LIKE 'RCC%') AS RoadScore,
                        (SELECT SUM(Score) FROM RoadClean_ChkRecord_PointScore PS WHERE PS.ChkID = M.ChkID AND PS.Chk_Code LIKE 'FLD%') 
                            / NULLIF((SELECT COUNT(*) FROM RoadClean_ChkRecord_PointMain PM WHERE PM.ChkID = M.ChkID), 0) AS FloodScore
                    FROM RoadClean_ChkRecord_Main M
                    LEFT JOIN RoadClean_CheckPointMain R ON M.ChkRoadID = R.RDID "
                    + where.ToString() + @"
                    ORDER BY M.ChkDate DESC, M.ChkID DESC";

                DataTable dt = DbHelper.ExecuteDataTable(sql, pList.ToArray());

                HSSFWorkbook workbook = new HSSFWorkbook();
                ISheet sheet = workbook.CreateSheet("道路潔淨巡檢清單");

                // 標題樣式 (深藍底白字)
                ICellStyle headerStyle = workbook.CreateCellStyle();
                IFont headerFont = workbook.CreateFont();
                headerFont.FontName = "微軟正黑體";
                headerFont.FontHeightInPoints = 10;
                headerFont.IsBold = true;
                headerFont.Color = NPOI.HSSF.Util.HSSFColor.White.Index;
                headerStyle.SetFont(headerFont);
                headerStyle.Alignment = HorizontalAlignment.Center;
                headerStyle.VerticalAlignment = VerticalAlignment.Center;
                headerStyle.FillForegroundColor = NPOI.HSSF.Util.HSSFColor.RoyalBlue.Index;
                headerStyle.FillPattern = FillPattern.SolidForeground;
                headerStyle.BorderBottom = BorderStyle.Thin;
                headerStyle.BorderTop = BorderStyle.Thin;
                headerStyle.BorderLeft = BorderStyle.Thin;
                headerStyle.BorderRight = BorderStyle.Thin;

                // 內容文字樣式 (置中)
                ICellStyle centerStyle = workbook.CreateCellStyle();
                IFont dataFont = workbook.CreateFont();
                dataFont.FontName = "微軟正黑體";
                dataFont.FontHeightInPoints = 9.5;
                centerStyle.SetFont(dataFont);
                centerStyle.Alignment = HorizontalAlignment.Center;
                centerStyle.VerticalAlignment = VerticalAlignment.Center;
                centerStyle.BorderBottom = BorderStyle.Thin;
                centerStyle.BorderTop = BorderStyle.Thin;
                centerStyle.BorderLeft = BorderStyle.Thin;
                centerStyle.BorderRight = BorderStyle.Thin;

                // 內容文字樣式 (靠左)
                ICellStyle leftStyle = workbook.CreateCellStyle();
                leftStyle.SetFont(dataFont);
                leftStyle.Alignment = HorizontalAlignment.Left;
                leftStyle.VerticalAlignment = VerticalAlignment.Center;
                leftStyle.BorderBottom = BorderStyle.Thin;
                leftStyle.BorderTop = BorderStyle.Thin;
                leftStyle.BorderLeft = BorderStyle.Thin;
                leftStyle.BorderRight = BorderStyle.Thin;

                string[] headers = new string[]
                {
                    "序號", "巡檢編號", "行政區", "巡檢道路名稱", "道路等級", "巡檢日期",
                    "檢核點數", "道路潔淨得分", "道路潔淨評級", "淹水潛勢得分", "淹水潛勢評級",
                    "案件階段狀態", "填報人員"
                };

                IRow rowHeader = sheet.CreateRow(0);
                rowHeader.HeightInPoints = 26;
                for (int h = 0; h < headers.Length; h++)
                {
                    ICell c = rowHeader.CreateCell(h);
                    c.SetCellValue(headers[h]);
                    c.CellStyle = headerStyle;
                }

                if (dt != null && dt.Rows.Count > 0)
                {
                    for (int r = 0; r < dt.Rows.Count; r++)
                    {
                        DataRow dr = dt.Rows[r];
                        IRow row = sheet.CreateRow(r + 1);
                        row.HeightInPoints = 20;

                        string seq = (r + 1).ToString();
                        string chkIdVal = dr["ChkID"] != DBNull.Value ? dr["ChkID"].ToString().Trim() : "";
                        string townVal = dr["TOWN"] != DBNull.Value ? dr["TOWN"].ToString().Trim() : "";
                        string roadVal = dr["RoadName"] != DBNull.Value ? dr["RoadName"].ToString().Trim() : "";
                        string rLvVal = dr["RDLV"] != DBNull.Value ? dr["RDLV"].ToString().Trim() : "";
                        string dateVal = dr["ChkDate"] != DBNull.Value ? Convert.ToDateTime(dr["ChkDate"]).ToString("yyyy-MM-dd HH:mm") : "";
                        string ptCountVal = dr["PointCount"] != DBNull.Value ? dr["PointCount"].ToString().Trim() + " 個" : "0 個";

                        int roadScore = -1;
                        if (dr["RoadScore"] != DBNull.Value)
                        {
                            roadScore = Convert.ToInt32(Math.Round(Convert.ToDouble(dr["RoadScore"])));
                        }
                        string roadScoreStr = roadScore >= 0 ? roadScore.ToString() + " 分" : "未評";
                        string roadScoreLv = "未調查";
                        if (roadScore >= 85) roadScoreLv = "A級";
                        else if (roadScore >= 60) roadScoreLv = "B級";
                        else if (roadScore >= 0) roadScoreLv = "C級";

                        int floodScore = -1;
                        if (dr["FloodScore"] != DBNull.Value)
                        {
                            floodScore = Convert.ToInt32(Math.Round(Convert.ToDouble(dr["FloodScore"])));
                        }
                        string floodScoreStr = floodScore >= 0 ? floodScore.ToString() + " 分" : "未評";
                        string floodScoreLv = "未調查";
                        if (floodScore >= 85) floodScoreLv = "A級";
                        else if (floodScore >= 60) floodScoreLv = "B級";
                        else if (floodScore >= 0) floodScoreLv = "C級";

                        int caseState = dr["Case_State"] != DBNull.Value ? Convert.ToInt32(dr["Case_State"]) : 1001;
                        string stateName = "審查未送出";
                        switch (caseState)
                        {
                            case 1001: stateName = "審查未送出"; break;
                            case 2001: stateName = "審查中"; break;
                            case 2101: stateName = "審查通過"; break;
                            case 2201: stateName = "駁回"; break;
                            case 2301: stateName = "退回補正"; break;
                            case 9001: stateName = "案件取消"; break;
                        }

                        string userVal = dr["Create_User"] != DBNull.Value ? dr["Create_User"].ToString().Trim() : "";

                        string[] vals = new string[]
                        {
                            seq, chkIdVal, townVal, roadVal, rLvVal, dateVal,
                            ptCountVal, roadScoreStr, roadScoreLv, floodScoreStr, floodScoreLv,
                            stateName, userVal
                        };

                        for (int cIdx = 0; cIdx < vals.Length; cIdx++)
                        {
                            ICell cell = row.CreateCell(cIdx);
                            cell.SetCellValue(vals[cIdx]);
                            cell.CellStyle = (cIdx == 3) ? leftStyle : centerStyle;
                        }
                    }
                }

                sheet.SetColumnWidth(0, 7 * 256);
                sheet.SetColumnWidth(1, 18 * 256);
                sheet.SetColumnWidth(2, 12 * 256);
                sheet.SetColumnWidth(3, 28 * 256);
                sheet.SetColumnWidth(4, 11 * 256);
                sheet.SetColumnWidth(5, 18 * 256);
                sheet.SetColumnWidth(6, 11 * 256);
                sheet.SetColumnWidth(7, 14 * 256);
                sheet.SetColumnWidth(8, 14 * 256);
                sheet.SetColumnWidth(9, 14 * 256);
                sheet.SetColumnWidth(10, 14 * 256);
                sheet.SetColumnWidth(11, 14 * 256);
                sheet.SetColumnWidth(12, 14 * 256);

                using (MemoryStream ms = new MemoryStream())
                {
                    workbook.Write(ms);
                    byte[] bytes = ms.ToArray();

                    Response.Clear();
                    Response.ClearHeaders();
                    Response.Buffer = true;
                    Response.ContentType = "application/vnd.ms-excel";
                    string filename = string.Format("道路潔淨巡檢清單_{0}.xls", DateTime.Now.ToString("yyyyMMddHHmmss"));
                    string encodedFilename = HttpUtility.UrlEncode(filename, Encoding.UTF8).Replace("+", "%20");
                    Response.AddHeader("Content-Disposition", "attachment; filename=" + encodedFilename);
                    Response.AddHeader("Content-Length", bytes.Length.ToString());
                    Response.BinaryWrite(bytes);
                    Response.Flush();
                    Response.SuppressContent = true;
                    HttpContext.Current.ApplicationInstance.CompleteRequest();
                }
            }
            catch (System.Threading.ThreadAbortException)
            {
            }
            catch (Exception ex)
            {
                Response.Clear();
                Response.ContentType = "text/plain; charset=utf-8";
                Response.Write("匯出 Excel 失敗：" + ex.Message);
            }
        }
        #endregion

}
}
