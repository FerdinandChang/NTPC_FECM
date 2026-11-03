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
using NTPC_FEC.Security;
using NPOI.HSSF.UserModel;
using NPOI.SS.UserModel;
using NTPC_FEC.Manager;
using NTPC_FEC.Services;
using NTPC_FEC.Models;

namespace NTPC_FEC.Case
{
    public partial class CaseList : Page
    {
        private JavaScriptSerializer json;

        public CaseList()
        {
            json = new JavaScriptSerializer();
            json.MaxJsonLength = int.MaxValue;
        }

        public class SearchFilterModel
        {
            public string Mode { get; set; }
            public string FacName { get; set; }
            public string CNo { get; set; }
            public string ScId { get; set; }
            public List<string> Towns { get; set; }
            public string SortBy { get; set; }
            public int PageIndex { get; set; }
            public int PageSize { get; set; }

            public SearchFilterModel()
            {
                Mode = "all";
                FacName = "";
                CNo = "";
                ScId = "";
                Towns = new List<string>();
                SortBy = "loss_desc";
                PageIndex = 1;
                PageSize = 15;
            }
        }

        public class NearbyModel
        {
            public double Lat { get; set; }
            public double Lng { get; set; }
            public double RadiusMeters { get; set; }

            public NearbyModel()
            {
                Lat = 0;
                Lng = 0;
                RadiusMeters = 3000;
            }
        }

        public class SaveFacEditModel
        {
            public string FacId { get; set; }
            public string FacName { get; set; }
            public string CNo { get; set; }
            public string Addr { get; set; }
            public string LandNo { get; set; }
            public string Fax { get; set; }
            public string Tel { get; set; }
            public string ScId { get; set; }
            public string LicNo { get; set; }
            public string BossName { get; set; }
            public string ContentName { get; set; }

            public SaveFacEditModel()
            {
                FacId = "";
                FacName = "";
                CNo = "";
                Addr = "";
                LandNo = "";
                Fax = "";
                Tel = "";
                ScId = "";
                LicNo = "";
                BossName = "";
                ContentName = "";
            }
        }

        public class CancelMissionModel
        {
            public string FacId { get; set; }
            public int FinishInvNo { get; set; }
            public string CancelReason { get; set; }

            public CancelMissionModel()
            {
                FacId = "";
                FinishInvNo = 0;
                CancelReason = "";
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
                        Message = "系統處理失敗：" + ex.Message
                    }));
                }

                try
                {
                    AjaxResponseHelper.CompleteRequest(Response, Context);
                }
                catch (System.Threading.ThreadAbortException)
                {
                    return;
                }
                return;
            }
        }

        private bool IsManagerUser()
        {
            string uid = (Session != null && Session["LoginUser"] != null) ? Session["LoginUser"].ToString().Trim() : "";
            if (string.IsNullOrEmpty(uid) && User != null && User.Identity != null) uid = User.Identity.Name;
            if (string.IsNullOrEmpty(uid) || uid == "系統使用者") return false;

            UserAccount acc = AuthService.GetCurrentUser(Context);
            if (acc != null)
            {
                string fId = !string.IsNullOrEmpty(acc.FacID) ? acc.FacID.Trim() : "";
                if ((acc.Lic & (1L << 9)) != 0 || (acc.Lic & (1L << 13)) != 0 || 
                    (acc.Lic & (1L << 14)) != 0 || (acc.Lic & (1L << 63)) != 0 || 
                    string.IsNullOrEmpty(fId))
                {
                    return true;
                }
            }
            else
            {
                string queryUserSql = "SELECT FAC_ID, LIC FROM UserAcc WHERE UserID = @UserID";
                var pList = new System.Data.SqlClient.SqlParameter[] { new System.Data.SqlClient.SqlParameter("@UserID", System.Data.SqlDbType.VarChar) { Value = uid } };
                System.Data.DataTable userDt = DbHelper.ExecuteDataTable(queryUserSql, pList);
                if (userDt != null && userDt.Rows.Count > 0)
                {
                    System.Data.DataRow uRow = userDt.Rows[0];
                    string fId = uRow["FAC_ID"] != DBNull.Value ? uRow["FAC_ID"].ToString().Trim() : "";
                    long licVal = 0L;
                    if (uRow["LIC"] != DBNull.Value) long.TryParse(uRow["LIC"].ToString(), out licVal);
                    if ((licVal & (1L << 9)) != 0 || (licVal & (1L << 13)) != 0 || 
                        (licVal & (1L << 14)) != 0 || (licVal & (1L << 63)) != 0 || 
                        string.IsNullOrEmpty(fId))
                    {
                        return true;
                    }
                }
            }
            return false;
        }

        private string GetCurrentUser()
        {
            if (Session != null && Session["LoginUser"] != null && !string.IsNullOrEmpty(Session["LoginUser"].ToString()))
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
                case "getcounts":
                    GetCounts();
                    break;
                case "gettowns":
                    GetTowns();
                    break;
                case "getlist":
                    GetList();
                    break;
                case "getnearby":
                    GetNearby();
                    break;
                case "getfachistory":
                    GetFacHistory();
                    break;
                case "savefacedit":
                    SaveFacEdit();
                    break;
                case "uploadcheck":
                    UploadCheck();
                    break;
                case "delinv":
                    DeleteInv();
                    break;
                case "cancelmission":
                    CancelMission();
                    break;
                case "gettoken":
                    GetToken();
                    break;
                case "compareinvs":
                    CompareInvs();
                    break;
                default:
                    Response.Write(json.Serialize(new { Success = false, Message = "未知的操作指令：" + action }));
                    break;
            }
        }

        #region 1. 取得各業務模式案件指標統計 (KPI 統計)
        private void GetCounts()
        {
            int countDraft = 0;
            int countBack = 0;
            int countMission7Day = 0;
            int countMission2Times = 0;
            int countProject = 0;
            int countInvMonth = 0;
            int countTotal = 0;

            try
            {
                // 草稿數 (A00a)
                string sqlDraft = "SELECT COUNT(1) FROM INV_DATA WHERE INV_State = 'A00a'";
                object objDraft = DbHelper.ExecuteScalar(sqlDraft);
                if (objDraft != null && objDraft != DBNull.Value) countDraft = Convert.ToInt32(objDraft);

                // 退件數 (A00b)
                string sqlBack = "SELECT COUNT(1) FROM INV_DATA WHERE INV_State = 'A00b'";
                object objBack = DbHelper.ExecuteScalar(sqlBack);
                if (objBack != null && objBack != DBNull.Value) countBack = Convert.ToInt32(objBack);

                // 7天未完成改善派遣
                string sqlMis7 = "SELECT COUNT(1) FROM INV_Mission WHERE Cancel_Date IS NULL AND (pReason LIKE '%7天內未完成改善回報%' OR pReason LIKE '%7天%')";
                object objMis7 = DbHelper.ExecuteScalar(sqlMis7);
                if (objMis7 != null && objMis7 != DBNull.Value) countMission7Day = Convert.ToInt32(objMis7);

                // 提報稽查列管
                string sqlMis2 = "SELECT COUNT(1) FROM INV_Mission WHERE Cancel_Date IS NULL AND pReason LIKE '%稽查列管%'";
                object objMis2 = DbHelper.ExecuteScalar(sqlMis2);
                if (objMis2 != null && objMis2 != DBNull.Value) countMission2Times = Convert.ToInt32(objMis2);

                // 臺北港專區 (八里區場所)
                string sqlProj = "SELECT COUNT(1) FROM FAC_Main WHERE TOWN LIKE '%八里%' OR ADDR LIKE '%八里%'";
                object objProj = DbHelper.ExecuteScalar(sqlProj);
                if (objProj != null && objProj != DBNull.Value) countProject = Convert.ToInt32(objProj);

                // 本月查核總場次
                string sqlMonth = @"
                    SELECT COUNT(1) 
                    FROM INV_DATA 
                    WHERE INV_DATE >= DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0)
                      AND INV_State <> 'Z00'";
                object objMonth = DbHelper.ExecuteScalar(sqlMonth);
                if (objMonth != null && objMonth != DBNull.Value) countInvMonth = Convert.ToInt32(objMonth);

                // 總場所數
                string sqlTotal = "SELECT COUNT(1) FROM FAC_Main";
                object objTotal = DbHelper.ExecuteScalar(sqlTotal);
                if (objTotal != null && objTotal != DBNull.Value) countTotal = Convert.ToInt32(objTotal);
            }
            catch
            {
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                Counts = new
                {
                    Draft = countDraft,
                    Back = countBack,
                    Mission7Day = countMission7Day,
                    Mission2Times = countMission2Times,
                    Project = countProject,
                    InvMonth = countInvMonth,
                    Total = countTotal
                }
            }));
        }
        #endregion

        #region 2. 取得新北市行政區列表
        private void GetTowns()
        {
            var list = new List<Dictionary<string, string>>();
            try
            {
                string sql = "SELECT TOWN_NO, TOWN_NA FROM C_TOWN WHERE COUNTRY = 'F' ORDER BY TOWN_NO";
                DataTable dt = DbHelper.ExecuteDataTable(sql);
                if (dt != null)
                {
                    foreach (DataRow r in dt.Rows)
                    {
                        var d = new Dictionary<string, string>();
                        d["TOWN_NO"] = r["TOWN_NO"].ToString().Trim();
                        d["TOWN_NA"] = r["TOWN_NA"].ToString().Trim();
                        list.Add(d);
                    }
                }
            }
            catch
            {
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                Towns = list
            }));
        }
        #endregion

        #region 3. 複合條件清單查詢與分頁
        private void GetList()
        {
            string reqJson = "";
            using (var reader = new StreamReader(Request.InputStream, Encoding.UTF8))
            {
                reqJson = reader.ReadToEnd();
            }

            SearchFilterModel filter = null;
            if (!string.IsNullOrEmpty(reqJson))
            {
                filter = json.Deserialize<SearchFilterModel>(reqJson);
            }
            if (filter == null)
            {
                filter = new SearchFilterModel();
            }

            string mode = string.IsNullOrEmpty(filter.Mode) ? "all" : filter.Mode.ToLower();
            var sbSql = new StringBuilder();
            var pList = new List<SqlParameter>();

            sbSql.Append("SELECT f.* FROM FAC_Main f WHERE 1=1 ");

            // 模式過濾
            if (mode == "reject")
            {
                sbSql.Append(" AND EXISTS (SELECT 1 FROM INV_DATA d WHERE d.FAC_ID = f.FAC_ID AND d.INV_State = 'A00a') ");
            }
            else if (mode == "back")
            {
                sbSql.Append(" AND EXISTS (SELECT 1 FROM INV_DATA d WHERE d.FAC_ID = f.FAC_ID AND d.INV_State = 'A00b') ");
            }
            else if (mode == "mission7day")
            {
                sbSql.Append(" AND EXISTS (SELECT 1 FROM INV_Mission m WHERE m.FAC_ID = f.FAC_ID AND m.Cancel_Date IS NULL AND (m.pReason LIKE '%7天內未完成改善回報%' OR m.pReason LIKE '%7天%')) ");
            }
            else if (mode == "mission2times")
            {
                sbSql.Append(" AND EXISTS (SELECT 1 FROM INV_Mission m WHERE m.FAC_ID = f.FAC_ID AND m.Cancel_Date IS NULL AND m.pReason LIKE '%稽查列管%') ");
            }
            else if (mode == "mission")
            {
                sbSql.Append(" AND EXISTS (SELECT 1 FROM INV_Mission m WHERE m.FAC_ID = f.FAC_ID AND m.Cancel_Date IS NULL) ");
            }
            else if (mode == "project")
            {
                sbSql.Append(" AND (f.TOWN LIKE '%八里%' OR f.ADDR LIKE '%八里%') ");
            }

            // 關鍵字搜尋
            if (!string.IsNullOrEmpty(filter.FacName))
            {
                sbSql.Append(" AND f.FAC_NAME LIKE @FAC_NAME ");
                pList.Add(new SqlParameter("@FAC_NAME", "%" + filter.FacName.Trim() + "%"));
            }
            if (!string.IsNullOrEmpty(filter.CNo))
            {
                sbSql.Append(" AND f.C_NO LIKE @C_NO ");
                pList.Add(new SqlParameter("@C_NO", "%" + filter.CNo.Trim() + "%"));
            }
            if (!string.IsNullOrEmpty(filter.ScId))
            {
                sbSql.Append(" AND f.S_C_ID LIKE @S_C_ID ");
                pList.Add(new SqlParameter("@S_C_ID", "%" + filter.ScId.Trim() + "%"));
            }

            // 行政區過濾
            if (filter.Towns != null && filter.Towns.Count > 0)
            {
                var townClause = new StringBuilder();
                townClause.Append(" AND (");
                for (int t = 0; t < filter.Towns.Count; t++)
                {
                    if (t > 0) townClause.Append(" OR ");
                    string pName = "@Town_" + t.ToString();
                    townClause.Append(string.Format("(f.TOWN LIKE {0} OR f.ADDR LIKE {0})", pName));
                    pList.Add(new SqlParameter(pName, "%" + filter.Towns[t].Trim() + "%"));
                }
                townClause.Append(") ");
                sbSql.Append(townClause.ToString());
            }

            DataTable dt = null;
            try
            {
                dt = DbHelper.ExecuteDataTable(sbSql.ToString(), pList.ToArray());
            }
            catch (Exception ex)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "資料庫查詢失敗：" + ex.Message }));
                return;
            }

            // 補充行業別 (INDUSTRIAL_Data)
            AttachIndustrialData(ref dt);

            // 補充製程摘要
            AttachProcessData(ref dt);

            // 補充派遣紀錄
            AttachMissionData(ref dt);

            // 補充最新查核缺失記點與缺失說明 (調用 managerList.LossPointCalculator)
            AttachLatestLossPoint(ref dt);

            int totalRows = (dt != null) ? dt.Rows.Count : 0;

            // 排序處理
            if (dt != null && dt.Rows.Count > 1)
            {
                DataView dv = dt.DefaultView;
                string sortExp = "FAC_ID DESC";
                if (filter.SortBy == "loss_desc")
                {
                    sortExp = "Loss_Point DESC, FAC_ID DESC";
                }
                else if (filter.SortBy == "loss_asc")
                {
                    sortExp = "Loss_Point ASC, FAC_ID DESC";
                }
                else if (filter.SortBy == "name_asc")
                {
                    sortExp = "FAC_NAME ASC";
                }
                else if (filter.SortBy == "date_desc")
                {
                    sortExp = "LastInvDate DESC, FAC_ID DESC";
                }
                dv.Sort = sortExp;
                dt = dv.ToTable();
            }

            int pageIndex = filter.PageIndex <= 0 ? 1 : filter.PageIndex;
            int pageSize = filter.PageSize <= 0 ? 15 : filter.PageSize;
            int startRow = (pageIndex - 1) * pageSize;

            var items = new List<Dictionary<string, object>>();

            if (dt != null && totalRows > 0)
            {
                int endRow = Math.Min(startRow + pageSize, totalRows);
                for (int i = startRow; i < endRow; i++)
                {
                    DataRow r = dt.Rows[i];
                    var item = new Dictionary<string, object>();

                    string facId = r["FAC_ID"].ToString().Trim();
                    item["FAC_ID"] = facId;
                    item["FAC_NAME"] = r.Table.Columns.Contains("FAC_NAME") ? r["FAC_NAME"].ToString() : "";
                    item["C_NO"] = r.Table.Columns.Contains("C_NO") ? r["C_NO"].ToString() : "";
                    item["S_C_ID"] = r.Table.Columns.Contains("S_C_ID") ? r["S_C_ID"].ToString() : "";
                    item["TOWN"] = r.Table.Columns.Contains("TOWN") ? r["TOWN"].ToString() : "";
                    item["ADDR"] = r.Table.Columns.Contains("ADDR") ? r["ADDR"].ToString() : "";
                    item["FAC_Type"] = r.Table.Columns.Contains("FAC_Type") ? r["FAC_Type"].ToString() : "";
                    item["Industrial"] = r.Table.Columns.Contains("Industrial") ? r["Industrial"].ToString() : "-";
                    item["ProcessSummary"] = r.Table.Columns.Contains("ProcessSummary") ? r["ProcessSummary"].ToString() : "無登記製程";

                    // 派遣狀態
                    string mission = r.Table.Columns.Contains("Mission") ? r["Mission"].ToString() : "";
                    string missionDeadline = r.Table.Columns.Contains("MissionDeadline_Str") ? r["MissionDeadline_Str"].ToString() : "";
                    int lastInvNo = 0;
                    if (r.Table.Columns.Contains("Last_INV_NO") && r["Last_INV_NO"] != DBNull.Value)
                    {
                        int.TryParse(r["Last_INV_NO"].ToString(), out lastInvNo);
                    }
                    item["Mission"] = mission;
                    item["MissionDeadline"] = missionDeadline;
                    item["Last_INV_NO"] = lastInvNo;
                    item["HasActiveMission"] = !string.IsNullOrEmpty(mission);

                    // 缺失記點
                    int lossPoint = 0;
                    if (r.Table.Columns.Contains("Loss_Point") && r["Loss_Point"] != DBNull.Value)
                    {
                        int.TryParse(r["Loss_Point"].ToString(), out lossPoint);
                    }
                    item["Loss_Point"] = lossPoint;
                    item["Loss_Detail"] = r.Table.Columns.Contains("Loss_Detail") ? r["Loss_Detail"].ToString() : "無缺失";
                    item["LastInvDate"] = r.Table.Columns.Contains("LastInvDate_Str") ? r["LastInvDate_Str"].ToString() : "無紀錄";

                    // 缺失標籤樣式
                    if (lossPoint == 0)
                    {
                        item["Loss_CSS"] = "loss-zero";
                    }
                    else if (lossPoint > 0 && lossPoint < 10)
                    {
                        item["Loss_CSS"] = "loss-minor";
                    }
                    else
                    {
                        item["Loss_CSS"] = "loss-major";
                    }

                    // 經緯度座標轉換
                    double x = 0, y = 0, lat = 0, lng = 0;
                    if (r.Table.Columns.Contains("TWD97_X") && double.TryParse(r["TWD97_X"].ToString(), out x) &&
                        r.Table.Columns.Contains("TWD97_Y") && double.TryParse(r["TWD97_Y"].ToString(), out y))
                    {
                        Twd97ToWgs84(x, y, out lat, out lng);
                    }
                    else if (r.Table.Columns.Contains("X") && double.TryParse(r["X"].ToString(), out x) &&
                             r.Table.Columns.Contains("Y") && double.TryParse(r["Y"].ToString(), out y))
                    {
                        Twd97ToWgs84(x, y, out lat, out lng);
                    }
                    item["Lat"] = lat;
                    item["Lng"] = lng;

                    // 安全 MD5 Token 計算: ("MD5:" + facId + yyyyMMddHH).ToMD5()
                    string token = ("MD5:" + facId + DateTime.Now.ToString("yyyyMMddHH")).ToMD5();
                    item["Md5Token"] = token;

                    items.Add(item);
                }
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                Total = totalRows,
                PageIndex = pageIndex,
                PageSize = pageSize,
                Items = items
            }));
        }
        #endregion

        #region 4. 外勤 GPS 環域定位搜尋周邊場所
        private void GetNearby()
        {
            string reqJson = "";
            using (var reader = new StreamReader(Request.InputStream, Encoding.UTF8))
            {
                reqJson = reader.ReadToEnd();
            }

            NearbyModel model = null;
            if (!string.IsNullOrEmpty(reqJson))
            {
                model = json.Deserialize<NearbyModel>(reqJson);
            }
            if (model == null || model.Lat == 0 || model.Lng == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "未提供有效之 GPS 座標" }));
                return;
            }

            double userX = 0, userY = 0;
            Wgs84ToTwd97(model.Lat, model.Lng, out userX, out userY);

            DataTable dt = null;
            try
            {
                string sqlNearby = @"
                    SELECT TOP 40 *, 
                        SQRT(SQUARE(ISNULL(TWD97_X, X) - @UserX) + SQUARE(ISNULL(TWD97_Y, Y) - @UserY)) AS DistMeters
                    FROM FAC_Main 
                    WHERE (TWD97_X > 0 OR X > 0)
                    ORDER BY DistMeters ASC";

                dt = DbHelper.ExecuteDataTable(sqlNearby,
                    new SqlParameter("@UserX", userX),
                    new SqlParameter("@UserY", userY));
            }
            catch (Exception ex)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "周邊場所計算失敗：" + ex.Message }));
                return;
            }

            AttachIndustrialData(ref dt);
            AttachProcessData(ref dt);
            AttachMissionData(ref dt);
            AttachLatestLossPoint(ref dt);

            var items = new List<Dictionary<string, object>>();
            if (dt != null)
            {
                foreach (DataRow r in dt.Rows)
                {
                    double dist = 0;
                    if (r["DistMeters"] != DBNull.Value)
                    {
                        double.TryParse(r["DistMeters"].ToString(), out dist);
                    }
                    if (model.RadiusMeters > 0 && dist > model.RadiusMeters)
                    {
                        continue;
                    }

                    var item = new Dictionary<string, object>();
                    string facId = r["FAC_ID"].ToString().Trim();
                    item["FAC_ID"] = facId;
                    item["FAC_NAME"] = r.Table.Columns.Contains("FAC_NAME") ? r["FAC_NAME"].ToString() : "";
                    item["C_NO"] = r.Table.Columns.Contains("C_NO") ? r["C_NO"].ToString() : "";
                    item["TOWN"] = r.Table.Columns.Contains("TOWN") ? r["TOWN"].ToString() : "";
                    item["ADDR"] = r.Table.Columns.Contains("ADDR") ? r["ADDR"].ToString() : "";
                    item["Industrial"] = r.Table.Columns.Contains("Industrial") ? r["Industrial"].ToString() : "-";
                    item["DistMeters"] = Math.Round(dist);

                    int lossPoint = 0;
                    if (r.Table.Columns.Contains("Loss_Point") && r["Loss_Point"] != DBNull.Value)
                    {
                        int.TryParse(r["Loss_Point"].ToString(), out lossPoint);
                    }
                    item["Loss_Point"] = lossPoint;
                    item["Loss_Detail"] = r.Table.Columns.Contains("Loss_Detail") ? r["Loss_Detail"].ToString() : "無缺失";

                    double x = 0, y = 0, lat = 0, lng = 0;
                    if (r.Table.Columns.Contains("TWD97_X") && double.TryParse(r["TWD97_X"].ToString(), out x) &&
                        r.Table.Columns.Contains("TWD97_Y") && double.TryParse(r["TWD97_Y"].ToString(), out y))
                    {
                        Twd97ToWgs84(x, y, out lat, out lng);
                    }
                    else if (r.Table.Columns.Contains("X") && double.TryParse(r["X"].ToString(), out x) &&
                             r.Table.Columns.Contains("Y") && double.TryParse(r["Y"].ToString(), out y))
                    {
                        Twd97ToWgs84(x, y, out lat, out lng);
                    }
                    item["Lat"] = lat;
                    item["Lng"] = lng;
                    item["Md5Token"] = ("MD5:" + facId + DateTime.Now.ToString("yyyyMMddHH")).ToMD5();

                    items.Add(item);
                }
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                Items = items
            }));
        }
        #endregion

        #region 5. 取得單一場所詳情、圖檔與歷次查核記錄 (抽屜面板資料)
        private void GetFacHistory()
        {
            string facId = Request["facId"];
            if (string.IsNullOrEmpty(facId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "缺少場所代碼" }));
                return;
            }

            // 1. 查詢場所基本資料
            string sqlFac = "SELECT * FROM FAC_Main WHERE FAC_ID = @FAC_ID";
            DataTable dtFac = DbHelper.ExecuteDataTable(sqlFac, new SqlParameter("@FAC_ID", facId));
            if (dtFac == null || dtFac.Rows.Count == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "找不到指定之公私場所" }));
                return;
            }

            DataRow fRow = dtFac.Rows[0];
            var facInfo = new Dictionary<string, object>();
            facInfo["FAC_ID"] = fRow["FAC_ID"].ToString().Trim();
            facInfo["FAC_NAME"] = fRow.Table.Columns.Contains("FAC_NAME") ? fRow["FAC_NAME"].ToString() : "";
            facInfo["C_NO"] = fRow.Table.Columns.Contains("C_NO") ? fRow["C_NO"].ToString() : "";
            facInfo["ADDR"] = fRow.Table.Columns.Contains("ADDR") ? fRow["ADDR"].ToString() : "";
            facInfo["Land_no"] = fRow.Table.Columns.Contains("Land_no") ? fRow["Land_no"].ToString() : "";
            facInfo["FAX"] = fRow.Table.Columns.Contains("FAX") ? fRow["FAX"].ToString() : "";
            facInfo["TEL"] = fRow.Table.Columns.Contains("TEL") ? fRow["TEL"].ToString() : "";
            facInfo["S_C_ID"] = fRow.Table.Columns.Contains("S_C_ID") ? fRow["S_C_ID"].ToString() : "";
            facInfo["Lic_NO"] = fRow.Table.Columns.Contains("Lic_NO") ? fRow["Lic_NO"].ToString() : "";
            facInfo["BOSS_NAME"] = fRow.Table.Columns.Contains("BOSS_NAME") ? fRow["BOSS_NAME"].ToString() : "";
            facInfo["Content_Name"] = fRow.Table.Columns.Contains("Content_Name") ? fRow["Content_Name"].ToString() : "";

            // 2. 判斷是否具備基本資料編輯權限 (僅尚未有已審查紀錄或首次巡查可修改)
            bool canEdit = false;
            try
            {
                string sqlCheckHis = "SELECT COUNT(1) FROM FAC_EditHis WHERE FAC_ID = @FAC_ID AND FAC_TYPE IS NULL";
                string sqlCheckInv = "SELECT COUNT(1) FROM INV_DATA WHERE FAC_ID = @FAC_ID AND INV_State NOT IN ('A00a','A00b','Z00')";
                int hisCount = Convert.ToInt32(DbHelper.ExecuteScalar(sqlCheckHis, new SqlParameter("@FAC_ID", facId)));
                int invCount = Convert.ToInt32(DbHelper.ExecuteScalar(sqlCheckInv, new SqlParameter("@FAC_ID", facId)));
                canEdit = (hisCount == 0 && invCount == 0);
            }
            catch
            {
                canEdit = false;
            }
            facInfo["CanEdit"] = canEdit;

            // 3. 圖檔配置查詢 (廠區配置圖、製程流程圖)
            string cNo = facInfo["C_NO"].ToString().Trim();
            var picList = GetDiagramFiles(cNo);

            // 4. 歷次巡查查核記錄查詢 (INV_DATA)
            string sqlInvs = @"
                SELECT i.*, s.State_Name 
                FROM INV_DATA i 
                LEFT JOIN INV_State_List s ON i.INV_State = s.State_ID 
                WHERE i.FAC_ID = @FAC_ID AND i.INV_State <> 'Z00' 
                ORDER BY i.INV_NO DESC";

            DataTable dtInvs = DbHelper.ExecuteDataTable(sqlInvs, new SqlParameter("@FAC_ID", facId));
            var invList = new List<Dictionary<string, object>>();

            if (dtInvs != null)
            {
                foreach (DataRow ir in dtInvs.Rows)
                {
                    var invItem = new Dictionary<string, object>();
                    int invNo = 0;
                    int.TryParse(ir["INV_NO"].ToString(), out invNo);
                    invItem["INV_NO"] = invNo;

                    DateTime invDate;
                    if (DateTime.TryParse(ir["INV_DATE"].ToString(), out invDate))
                    {
                        invItem["INV_DATE"] = invDate.ToString("yyyy/MM/dd HH:mm");
                    }
                    else
                    {
                        invItem["INV_DATE"] = ir["INV_DATE"].ToString();
                    }

                    invItem["INV_TYPE"] = ir.Table.Columns.Contains("INV_TYPE") ? ir["INV_TYPE"].ToString() : "定期巡查";
                    invItem["Work_State"] = ir.Table.Columns.Contains("Work_State") ? ir["Work_State"].ToString() : "正常運作";

                    string stateCode = ir["INV_State"].ToString().Trim();
                    string stateName = ir.Table.Columns.Contains("State_Name") ? ir["State_Name"].ToString() : stateCode;
                    invItem["INV_State"] = stateCode;
                    invItem["State_Name"] = stateName;

                    // 使用 managerList.LossPointCalculator 計算缺失總分與項目
                    int ptLoss = managerList.LossPointCalculator.CalTotalLossPoint(ir);
                    string detailLoss = managerList.LossPointCalculator.GetAllLossDetail(ir);
                    invItem["Total_Loss_Point"] = ptLoss;
                    invItem["Loss_Detail"] = detailLoss;

                    // 權限判斷：草稿 (A00a) 或退回 (A00b) 才能修改、送審、簽名、刪除
                    bool isDraftOrBack = (stateCode == "A00a" || stateCode == "A00b");
                    invItem["CanEdit"] = isDraftOrBack;
                    invItem["CanSubmit"] = isDraftOrBack;
                    invItem["CanDelete"] = isDraftOrBack;
                    invItem["CanSign"] = isDraftOrBack;

                    invList.Add(invItem);
                }
            }

            string md5 = ("MD5:" + facId + DateTime.Now.ToString("yyyyMMddHH")).ToMD5();

            Response.Write(json.Serialize(new
            {
                Success = true,
                FacInfo = facInfo,
                Diagrams = picList,
                Invs = invList,
                Md5Token = md5
            }));
        }

        private List<Dictionary<string, string>> GetDiagramFiles(string cNo)
        {
            var list = new List<Dictionary<string, string>>();
            if (string.IsNullOrEmpty(cNo)) return list;

            try
            {
                string relDir = "~/Upload/FAC/" + cNo;
                string absDir = Server.MapPath(relDir);
                if (!Directory.Exists(absDir))
                {
                    string altDir = Server.MapPath("/NTPC_FEC/Upload/FAC/" + cNo);
                    if (Directory.Exists(altDir)) absDir = altDir;
                }

                if (Directory.Exists(absDir))
                {
                    DirectoryInfo di = new DirectoryInfo(absDir);
                    FileInfo[] files = di.GetFiles(cNo + "*.*");

                    string appPath = Request.ApplicationPath;
                    if (appPath == "/") appPath = "";

                    foreach (FileInfo fi in files)
                    {
                        string ext = fi.Extension.ToLower();
                        if (ext == ".pdf" || ext == ".jpg" || ext == ".png" || ext == ".jpeg")
                        {
                            var d = new Dictionary<string, string>();
                            d["FileName"] = fi.Name;
                            d["FileType"] = fi.Name.Contains("配置圖") ? "廠區配置圖" : (fi.Name.Contains("流程圖") ? "製程流程圖" : "相關圖檔");
                            d["FileUrl"] = string.Format("{0}/Upload/FAC/{1}/{2}", appPath, cNo, HttpUtility.UrlPathEncode(fi.Name));
                            d["IsPdf"] = (ext == ".pdf") ? "true" : "false";
                            list.Add(d);
                        }
                    }
                }
            }
            catch
            {
            }
            return list;
        }
        #endregion

        #region 6. 儲存場所基本資料異動 (寫入 FAC_EditHis)
        private void SaveFacEdit()
        {
            string reqJson = "";
            using (var reader = new StreamReader(Request.InputStream, Encoding.UTF8))
            {
                reqJson = reader.ReadToEnd();
            }

            SaveFacEditModel model = null;
            if (!string.IsNullOrEmpty(reqJson))
            {
                model = json.Deserialize<SaveFacEditModel>(reqJson);
            }
            if (model == null || string.IsNullOrEmpty(model.FacId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "缺少場所代碼" }));
                return;
            }

            try
            {
                string sqlInsert = @"
                    INSERT INTO FAC_EditHis (
                        FAC_ID, FAC_NAME, C_NO, ADDR, Land_no, FAX, TEL, 
                        S_C_ID, Lic_NO, BOSS_NAME, Content_Name, Edit_User, Edit_Date
                    ) VALUES (
                        @FAC_ID, @FAC_NAME, @C_NO, @ADDR, @Land_no, @FAX, @TEL, 
                        @S_C_ID, @Lic_NO, @BOSS_NAME, @Content_Name, @Edit_User, GETDATE()
                    )";

                DbHelper.ExecuteNonQuery(sqlInsert,
                    new SqlParameter("@FAC_ID", model.FacId),
                    new SqlParameter("@FAC_NAME", model.FacName ?? ""),
                    new SqlParameter("@C_NO", model.CNo ?? ""),
                    new SqlParameter("@ADDR", model.Addr ?? ""),
                    new SqlParameter("@Land_no", model.LandNo ?? ""),
                    new SqlParameter("@FAX", model.Fax ?? ""),
                    new SqlParameter("@TEL", model.Tel ?? ""),
                    new SqlParameter("@S_C_ID", model.ScId ?? ""),
                    new SqlParameter("@Lic_NO", model.LicNo ?? ""),
                    new SqlParameter("@BOSS_NAME", model.BossName ?? ""),
                    new SqlParameter("@Content_Name", model.ContentName ?? ""),
                    new SqlParameter("@Edit_User", GetCurrentUser()));

                // 寫入 AuditLog 雙軌稽核日誌
                AuditLogger.Log(
                    operatorUser: GetCurrentUser(),
                    actionType: "CASE_FAC_EDIT_SAVE",
                    targetUser: model.FacId,
                    clientIp: Request.UserHostAddress,
                    details: string.Format("外勤巡查儲存場所基本資料變更，場所代碼：{0}，名稱：{1}，管編：{2}，地址：{3}",
                        model.FacId, model.FacName, model.CNo, model.Addr),
                    oldValue: null,
                    newValue: null
                );

                Response.Write(json.Serialize(new { Success = true, Message = "場所基本資料異動已成功登記！" }));
            }
            catch (Exception ex)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "儲存失敗：" + ex.Message }));
            }
        }
        #endregion

        #region 7. 送出審核 (INV_State 改為 A00 並更新派遣任務)
        private void UploadCheck()
        {
            string facId = Request["facId"];
            string invNoStr = Request["invNo"];
            int invNo = 0;
            if (string.IsNullOrEmpty(facId) || !int.TryParse(invNoStr, out invNo))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "參數不正確" }));
                return;
            }

            try
            {
                // 1. 將 INV_DATA 狀態更新為 A00 (送出審查中)
                string sqlUpdInv = "UPDATE INV_DATA SET INV_State = 'A00' WHERE FAC_ID = @FAC_ID AND INV_NO = @INV_NO";
                DbHelper.ExecuteNonQuery(sqlUpdInv,
                    new SqlParameter("@FAC_ID", facId),
                    new SqlParameter("@INV_NO", invNo));

                // 2. 將尚未結案的派遣任務 Finish_INV_NO 填入此次查核號碼
                string sqlUpdMis = "UPDATE INV_Mission SET Finish_INV_NO = @Finish_INV_NO WHERE FAC_ID = @FAC_ID AND Finish_INV_NO IS NULL";
                DbHelper.ExecuteNonQuery(sqlUpdMis,
                    new SqlParameter("@Finish_INV_NO", invNo),
                    new SqlParameter("@FAC_ID", facId));

                // 寫入 AuditLog 雙軌稽核日誌
                AuditLogger.Log(
                    operatorUser: GetCurrentUser(),
                    actionType: "CASE_UPLOAD_CHECK",
                    targetUser: facId,
                    clientIp: Request.UserHostAddress,
                    details: string.Format("外勤查核紀錄送出審核，場所代碼：{0}，查核編號：{1}，狀態推進為 A00", facId, invNo),
                    oldValue: "Draft",
                    newValue: "A00"
                );

                Response.Write(json.Serialize(new { Success = true, Message = "查核紀錄已成功送出審核！" }));
            }
            catch (Exception ex)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "送出失敗：" + ex.Message }));
            }
        }
        #endregion

        #region 8. 刪除查核紀錄 (軟刪除，狀態改為 Z00)
        private void DeleteInv()
        {
            string facId = Request["facId"];
            string invNoStr = Request["invNo"];
            int invNo = 0;
            if (string.IsNullOrEmpty(facId) || !int.TryParse(invNoStr, out invNo))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "參數不正確" }));
                return;
            }

            try
            {
                string sqlDel = "UPDATE INV_DATA SET INV_State = 'Z00' WHERE FAC_ID = @FAC_ID AND INV_NO = @INV_NO";
                DbHelper.ExecuteNonQuery(sqlDel,
                    new SqlParameter("@FAC_ID", facId),
                    new SqlParameter("@INV_NO", invNo));

                // 寫入 AuditLog 雙軌稽核日誌
                AuditLogger.Log(
                    operatorUser: GetCurrentUser(),
                    actionType: "CASE_INV_DELETE",
                    targetUser: facId,
                    clientIp: Request.UserHostAddress,
                    details: string.Format("外勤巡查刪除查核紀錄 (軟刪除)，場所代碼：{0}，查核編號：{1}，狀態標記為 Z00", facId, invNo),
                    oldValue: "Active",
                    newValue: "Z00"
                );

                Response.Write(json.Serialize(new { Success = true, Message = "查核紀錄已順利刪除！" }));
            }
            catch (Exception ex)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "刪除失敗：" + ex.Message }));
            }
        }
        #endregion

        #region 9. 移除/取消派遣任務 (填寫 Cancel_Reason 並更新 Cancel_Date)
        private void CancelMission()
        {
            if (!IsManagerUser())
            {
                Response.Write(json.Serialize(new { Success = false, Message = "僅有管理者或審查員具備取消派遣任務權限！" }));
                return;
            }
            string reqJson = "";
            using (var reader = new StreamReader(Request.InputStream, Encoding.UTF8))
            {
                reqJson = reader.ReadToEnd();
            }

            CancelMissionModel model = null;
            if (!string.IsNullOrEmpty(reqJson))
            {
                model = json.Deserialize<CancelMissionModel>(reqJson);
            }
            if (model == null || string.IsNullOrEmpty(model.FacId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "缺少場所代碼" }));
                return;
            }

            try
            {
                string sqlCancel = @"
                    UPDATE INV_Mission 
                    SET Cancel_Reason = @Cancel_Reason, Cancel_Date = GETDATE() 
                    WHERE FAC_ID = @FAC_ID 
                      AND Cancel_Date IS NULL";

                DbHelper.ExecuteNonQuery(sqlCancel,
                    new SqlParameter("@FAC_ID", model.FacId),
                    new SqlParameter("@Cancel_Reason", model.CancelReason ?? "使用者手動移除派遣"));

                // 寫入 AuditLog 雙軌稽核日誌
                AuditLogger.Log(
                    operatorUser: GetCurrentUser(),
                    actionType: "CASE_MISSION_CANCEL",
                    targetUser: model.FacId,
                    clientIp: Request.UserHostAddress,
                    details: string.Format("取消/移除外勤派遣任務，場所代碼：{0}，原因：{1}",
                        model.FacId, model.CancelReason ?? "手動移除派遣"),
                    oldValue: "Active",
                    newValue: "Cancelled"
                );

                Response.Write(json.Serialize(new { Success = true, Message = "派遣任務已順利移除！" }));
            }
            catch (Exception ex)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "移除派遣失敗：" + ex.Message }));
            }
        }
        #endregion

        #region 10. 產生安全導航 MD5 Token
        private void GetToken()
        {
            string facId = Request["facId"];
            if (string.IsNullOrEmpty(facId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "缺少場所代碼" }));
                return;
            }

            string token = ("MD5:" + facId + DateTime.Now.ToString("yyyyMMddHH")).ToMD5();
            Response.Write(json.Serialize(new { Success = true, Token = token }));
        }
        #endregion

        #region 內部共用輔助函式 (行業別、製程、派遣、缺失分數掛載)
        private void AttachIndustrialData(ref DataTable dt)
        {
            if (dt == null) return;
            if (!dt.Columns.Contains("Industrial")) dt.Columns.Add("Industrial", typeof(string));

            try
            {
                string sqlInd = "SELECT INDUSTRIAL_Code, INDUSTRIAL_Name FROM INDUSTRIAL_Data";
                DataTable dtInd = DbHelper.ExecuteDataTable(sqlInd);
                if (dtInd != null)
                {
                    var dict = new Dictionary<string, string>();
                    foreach (DataRow r in dtInd.Rows)
                    {
                        string code = r["INDUSTRIAL_Code"].ToString().Trim();
                        string name = r["INDUSTRIAL_Name"].ToString().Trim();
                        if (!dict.ContainsKey(code)) dict.Add(code, name);
                    }

                    foreach (DataRow r in dt.Rows)
                    {
                        string code = r.Table.Columns.Contains("INDUSTRIAL_Code1") ? r["INDUSTRIAL_Code1"].ToString().Trim() : "";
                        if (!string.IsNullOrEmpty(code) && dict.ContainsKey(code))
                        {
                            r["Industrial"] = string.Format("({0}) {1}", code, dict[code]);
                        }
                        else
                        {
                            r["Industrial"] = string.IsNullOrEmpty(code) ? "-" : code;
                        }
                    }
                }
            }
            catch { }
        }

        private void AttachProcessData(ref DataTable dt)
        {
            if (dt == null) return;
            if (!dt.Columns.Contains("ProcessSummary")) dt.Columns.Add("ProcessSummary", typeof(string));

            try
            {
                string sqlProc = "SELECT DISTINCT FAC_ID, Process_NO, Process_Name, Process_Lic FROM INV_Process_Main";
                DataTable dtProc = DbHelper.ExecuteDataTable(sqlProc);

                if (dtProc != null && dtProc.Rows.Count > 0)
                {
                    var map = new Dictionary<string, List<string>>();
                    foreach (DataRow pr in dtProc.Rows)
                    {
                        string fid = pr["FAC_ID"].ToString().Trim();
                        if (!map.ContainsKey(fid)) map.Add(fid, new List<string>());

                        string pNo = pr["Process_NO"].ToString().Trim();
                        string pName = pr["Process_Name"].ToString().Trim();
                        string pLic = pr["Process_Lic"].ToString().Trim();
                        map[fid].Add(string.Format("[{0}] {1} ({2})", pNo, pName, pLic));
                    }

                    foreach (DataRow r in dt.Rows)
                    {
                        string fid = r["FAC_ID"].ToString().Trim();
                        if (map.ContainsKey(fid))
                        {
                            r["ProcessSummary"] = string.Join(" | ", map[fid].ToArray());
                        }
                        else
                        {
                            r["ProcessSummary"] = "無登記製程";
                        }
                    }
                }
            }
            catch { }
        }

        private void AttachMissionData(ref DataTable dt)
        {
            if (dt == null) return;
            if (!dt.Columns.Contains("Mission")) dt.Columns.Add("Mission", typeof(string));
            if (!dt.Columns.Contains("MissionDeadline_Str")) dt.Columns.Add("MissionDeadline_Str", typeof(string));
            if (!dt.Columns.Contains("Last_INV_NO")) dt.Columns.Add("Last_INV_NO", typeof(int));

            try
            {
                string sqlMis = "SELECT FAC_ID, SendDate, pReason, Finish_INV_NO FROM INV_Mission WHERE Cancel_Date IS NULL ORDER BY SendDate DESC";
                DataTable dtMis = DbHelper.ExecuteDataTable(sqlMis);

                if (dtMis != null && dtMis.Rows.Count > 0)
                {
                    var misMap = new Dictionary<string, DataRow>();
                    foreach (DataRow mr in dtMis.Rows)
                    {
                        string fid = mr["FAC_ID"].ToString().Trim();
                        if (!misMap.ContainsKey(fid)) misMap.Add(fid, mr);
                    }

                    foreach (DataRow r in dt.Rows)
                    {
                        string fid = r["FAC_ID"].ToString().Trim();
                        if (misMap.ContainsKey(fid))
                        {
                            DataRow mr = misMap[fid];
                            DateTime sDate;
                            if (DateTime.TryParse(mr["SendDate"].ToString(), out sDate))
                            {
                                string pReason = mr["pReason"].ToString();
                                r["Mission"] = string.Format("派遣案件({0:yyyy-MM-dd})，原因: {1}", sDate, pReason);
                                if (pReason.IndexOf("7天內未完成改善") >= 0 || pReason.IndexOf("稽查列管") >= 0)
                                {
                                    r["MissionDeadline_Str"] = string.Format("巡查期限: {0:yyyy-MM-dd}", sDate.AddDays(30.0));
                                }
                            }
                            if (mr["Finish_INV_NO"] != DBNull.Value)
                            {
                                int fNo = 0;
                                int.TryParse(mr["Finish_INV_NO"].ToString(), out fNo);
                                r["Last_INV_NO"] = fNo;
                            }
                        }
                    }
                }
            }
            catch { }
        }

        private void AttachLatestLossPoint(ref DataTable dt)
        {
            if (dt == null) return;
            if (!dt.Columns.Contains("Loss_Point")) dt.Columns.Add("Loss_Point", typeof(int));
            if (!dt.Columns.Contains("Loss_Detail")) dt.Columns.Add("Loss_Detail", typeof(string));
            if (!dt.Columns.Contains("LastInvDate")) dt.Columns.Add("LastInvDate", typeof(DateTime));
            if (!dt.Columns.Contains("LastInvDate_Str")) dt.Columns.Add("LastInvDate_Str", typeof(string));

            try
            {
                // 取每個場所最新一筆查核紀錄 (INV_State <> 'Z00')
                string sqlLatest = @"
                    SELECT t.* 
                    FROM INV_DATA t
                    INNER JOIN (
                        SELECT FAC_ID, MAX(INV_NO) AS MaxInvNo
                        FROM INV_DATA
                        WHERE INV_State <> 'Z00'
                        GROUP BY FAC_ID
                    ) m ON t.FAC_ID = m.FAC_ID AND t.INV_NO = m.MaxInvNo";

                DataTable dtLatest = DbHelper.ExecuteDataTable(sqlLatest);
                if (dtLatest != null && dtLatest.Rows.Count > 0)
                {
                    var invMap = new Dictionary<string, DataRow>();
                    foreach (DataRow row in dtLatest.Rows)
                    {
                        string fid = row["FAC_ID"].ToString().Trim();
                        if (!invMap.ContainsKey(fid)) invMap.Add(fid, row);
                    }

                    foreach (DataRow r in dt.Rows)
                    {
                        string fid = r["FAC_ID"].ToString().Trim();
                        if (invMap.ContainsKey(fid))
                        {
                            DataRow lRow = invMap[fid];
                            int pt = managerList.LossPointCalculator.CalTotalLossPoint(lRow);
                            string det = managerList.LossPointCalculator.GetAllLossDetail(lRow);
                            r["Loss_Point"] = pt;
                            r["Loss_Detail"] = det;

                            DateTime idate;
                            if (DateTime.TryParse(lRow["INV_DATE"].ToString(), out idate))
                            {
                                r["LastInvDate"] = idate;
                                r["LastInvDate_Str"] = idate.ToString("yyyy/MM/dd");
                            }
                        }
                        else
                        {
                            r["Loss_Point"] = 0;
                            r["Loss_Detail"] = "無查核紀錄";
                            r["LastInvDate_Str"] = "-";
                        }
                    }
                }
            }
            catch { }
        }
        #endregion

        #region 高精度 TWD97 與 WGS84 座標互相轉換 (符合 C# 5.0 鐵律)
        private static void Twd97ToWgs84(double x, double y, out double lat, out double lon)
        {
            GeoCoordHelper.Twd97ToWgs84(x, y, out lat, out lon);
        }

        private static void Wgs84ToTwd97(double lat, double lon, out double x, out double y)
        {
            GeoCoordHelper.Wgs84ToTwd97(lat, lon, out x, out y);
        }
        #endregion
    
        #region 歷次查核雙向比對 (CompareInvs)
        private void CompareInvs()
        {
            string facId = Request["facId"] != null ? Request["facId"].Trim() : "";
            string invNoAStr = Request["invNoA"] != null ? Request["invNoA"].Trim() : "";
            string invNoBStr = Request["invNoB"] != null ? Request["invNoB"].Trim() : "";

            if (string.IsNullOrEmpty(facId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "缺少場所編號 (facId)" }));
                return;
            }

            // 1. 取得場所名稱與基本資訊
            string sqlFac = "SELECT FAC_ID, C_NO, FAC_NAME, TOWN, ADDR FROM FAC_Main WHERE FAC_ID = @FAC_ID";
            DataTable dtFac = DbHelper.ExecuteDataTable(sqlFac, new SqlParameter("@FAC_ID", facId));
            if (dtFac == null || dtFac.Rows.Count == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "查無此場所資料" }));
                return;
            }
            DataRow facRow = dtFac.Rows[0];
            string facName = facRow["FAC_NAME"] != null ? facRow["FAC_NAME"].ToString().Trim() : "";
            string cNo = facRow["C_NO"] != null ? facRow["C_NO"].ToString().Trim() : "";

            int invNoA = 0;
            int invNoB = 0;
            int.TryParse(invNoAStr, out invNoA);
            int.TryParse(invNoBStr, out invNoB);

            // 若未指定 invNoA 或 invNoB，預設抓該場所最新的 2 筆紀錄
            if (invNoA <= 0 || invNoB <= 0)
            {
                string sqlTop2 = "SELECT TOP 2 INV_NO FROM INV_DATA WHERE FAC_ID = @FAC_ID AND INV_State <> 'Z00' ORDER BY INV_NO DESC";
                DataTable dtTop2 = DbHelper.ExecuteDataTable(sqlTop2, new SqlParameter("@FAC_ID", facId));
                if (dtTop2 == null || dtTop2.Rows.Count < 2)
                {
                    Response.Write(json.Serialize(new { Success = false, Message = "該場所有效查核紀錄不足 2 筆，無法進行歷程比對！" }));
                    return;
                }
                invNoA = Convert.ToInt32(dtTop2.Rows[0]["INV_NO"]);
                invNoB = Convert.ToInt32(dtTop2.Rows[1]["INV_NO"]);
            }

            // 2. 取得兩次查核之 INV_DATA (含狀態名稱)
            string sqlInvA = "SELECT i.*, s.State_Name FROM INV_DATA i LEFT JOIN INV_State_List s ON i.INV_State = s.State_ID WHERE i.FAC_ID = @FAC_ID AND i.INV_NO = @INV_NO";
            DataTable dtInvA = DbHelper.ExecuteDataTable(sqlInvA, new SqlParameter("@FAC_ID", facId), new SqlParameter("@INV_NO", invNoA));

            string sqlInvB = "SELECT i.*, s.State_Name FROM INV_DATA i LEFT JOIN INV_State_List s ON i.INV_State = s.State_ID WHERE i.FAC_ID = @FAC_ID AND i.INV_NO = @INV_NO";
            DataTable dtInvB = DbHelper.ExecuteDataTable(sqlInvB, new SqlParameter("@FAC_ID", facId), new SqlParameter("@INV_NO", invNoB));

            if (dtInvA == null || dtInvA.Rows.Count == 0 || dtInvB == null || dtInvB.Rows.Count == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "查無指定的查核紀錄資料" }));
                return;
            }

            DataRow rowA = dtInvA.Rows[0];
            DataRow rowB = dtInvB.Rows[0];

            // 3. 取得兩筆查核各自的照片字典 (key: fbase, value: web url，支援正式機 NTPC_FECM/Upload/PIC)
            DateTime dateA = DateTime.MinValue;
            DateTime dateB = DateTime.MinValue;
            if (rowA["INV_DATE"] != DBNull.Value) DateTime.TryParse(rowA["INV_DATE"].ToString(), out dateA);
            if (rowB["INV_DATE"] != DBNull.Value) DateTime.TryParse(rowB["INV_DATE"].ToString(), out dateB);
            Dictionary<string, string> photosA = GetInvPhotos(facId, invNoA, cNo, dateA);
            Dictionary<string, string> photosB = GetInvPhotos(facId, invNoB, cNo, dateB);

            // 4. 解析兩次查核之九大防制設施 (含違規/合格清單與照片清單)
            List<Dictionary<string, object>> sectionsA = BuildCompareSections(rowA, photosA);
            List<Dictionary<string, object>> sectionsB = BuildCompareSections(rowB, photosB);

            // 5. 兩筆查核的基本摘要資訊
            Dictionary<string, object> infoA = BuildInvSummary(rowA);
            Dictionary<string, object> infoB = BuildInvSummary(rowB);

            // 6. 整合計算九大防制設施雙向比對差額 (Diff List)
            List<Dictionary<string, object>> diffSections = new List<Dictionary<string, object>>();
            int improvedCount = 0;
            int worsenedCount = 0;
            int continuedCount = 0;
            int normalCount = 0;
            int infoChangedCount = 0;

            for (int i = 0; i < sectionsA.Count; i++)
            {
                Dictionary<string, object> secA = sectionsA[i];
                Dictionary<string, object> secB = (i < sectionsB.Count) ? sectionsB[i] : null;

                bool isInfo = secA.ContainsKey("IsInfo") && (bool)secA["IsInfo"];
                if (isInfo)
                {
                    bool changed = IsInfoSectionChanged(secA, secB);
                    if (changed) infoChangedCount++;

                    Dictionary<string, object> infoDiff = new Dictionary<string, object>();
                    infoDiff["Id"] = secA["Id"];
                    infoDiff["Title"] = secA["Title"];
                    infoDiff["DiffStatus"] = changed ? "changed" : "same";
                    infoDiff["DiffBadge"] = changed ? "填報內容有差異" : "填報內容相同";
                    infoDiff["DiffClass"] = changed ? "badge-info" : "badge-light text-muted border";
                    infoDiff["HasDifference"] = changed;
                    infoDiff["SectionA"] = secA;
                    infoDiff["SectionB"] = secB;
                    diffSections.Add(infoDiff);
                    continue;
                }

                int lossA = secA.ContainsKey("LossPoint") ? Convert.ToInt32(secA["LossPoint"]) : 0;
                int lossB = (secB != null && secB.ContainsKey("LossPoint")) ? Convert.ToInt32(secB["LossPoint"]) : 0;

                string diffStatus = "normal";
                string diffBadge = "均合規正常";
                string diffClass = "badge-light text-muted border";

                if (lossA == 0 && lossB > 0)
                {
                    diffStatus = "improved";
                    diffBadge = string.Format("已改善解除 (-{0}點)", lossB);
                    diffClass = "badge-success";
                    improvedCount++;
                }
                else if (lossA > 0 && lossB == 0)
                {
                    diffStatus = "worsened";
                    diffBadge = string.Format("新發生缺失 (+{0}點)", lossA);
                    diffClass = "badge-danger";
                    worsenedCount++;
                }
                else if (lossA > 0 && lossB > 0)
                {
                    diffStatus = "continued";
                    diffBadge = string.Format("持續未改善 ({0}點)", lossA);
                    diffClass = "badge-warning text-dark";
                    continuedCount++;
                }
                else
                {
                    normalCount++;
                }

                Dictionary<string, object> diffItem = new Dictionary<string, object>();
                diffItem["Id"] = secA["Id"];
                diffItem["Title"] = secA["Title"];
                diffItem["DiffStatus"] = diffStatus;
                diffItem["DiffBadge"] = diffBadge;
                diffItem["DiffClass"] = diffClass;
                diffItem["HasDifference"] = (diffStatus != "normal" || lossA > 0 || lossB > 0);
                diffItem["SectionA"] = secA;
                diffItem["SectionB"] = secB;

                diffSections.Add(diffItem);
            }

            int lossPointA = Convert.ToInt32(infoA["TotalLossPoint"]);
            int lossPointB = Convert.ToInt32(infoB["TotalLossPoint"]);
            int deltaLoss = lossPointA - lossPointB;

            string deltaText = "缺失點數相同";
            string deltaClass = "text-secondary";
            string deltaIcon = "fa-equals";

            if (deltaLoss < 0)
            {
                deltaText = string.Format("改善減少 {0} 點", Math.Abs(deltaLoss));
                deltaClass = "text-success";
                deltaIcon = "fa-arrow-down";
            }
            else if (deltaLoss > 0)
            {
                deltaText = string.Format("缺失惡化增加 {0} 點", deltaLoss);
                deltaClass = "text-danger";
                deltaIcon = "fa-arrow-up";
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                FacName = facName,
                CNo = cNo,
                InvA = infoA,
                InvB = infoB,
                DiffSummary = new
                {
                    LossDelta = deltaLoss,
                    DeltaText = deltaText,
                    DeltaClass = deltaClass,
                    DeltaIcon = deltaIcon,
                    ImprovedCount = improvedCount,
                    WorsenedCount = worsenedCount,
                    ContinuedCount = continuedCount,
                    NormalCount = normalCount,
                    InfoChangedCount = infoChangedCount
                },
                DiffSections = diffSections
            }));
        }

        private Dictionary<string, string> GetInvPhotos(string facId, int invNo, string cNo, DateTime invDate)
        {
            string appPath = HttpContext.Current.Request.ApplicationPath;
            if (string.IsNullOrEmpty(appPath) || appPath == "/")
            {
                appPath = "";
            }
            else
            {
                appPath = appPath.TrimEnd('/');
            }

            Dictionary<string, string> existingPhotos = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);

            // 與 CaseResult.aspx 共用 InvPhotoHelper：只取該筆巡查專屬目錄，不跨目錄合併
            string urlPrefix;
            string[] files = NTPC_FEC.Helpers.InvPhotoHelper.GetPhotoFiles(facId, invNo, cNo, invDate, out urlPrefix);

            foreach (string f in files)
            {
                string fname = Path.GetFileName(f);
                string fbase = Path.GetFileNameWithoutExtension(f);
                string fUrl = appPath + urlPrefix + HttpUtility.UrlPathEncode(fname);

                if (!existingPhotos.ContainsKey(fbase))
                {
                    existingPhotos[fbase] = fUrl;
                }
                MapLegacyPhotoKey(fbase, fUrl, existingPhotos);
            }

            return existingPhotos;
        }

        private void MapLegacyPhotoKey(string fbase, string fUrl, Dictionary<string, string> photos)
        {
            // 1. 堆置逸散 (堆罝 / 堆置)
            if (fbase.Contains("堆罝") || fbase.Contains("堆置"))
            {
                if (fbase.Contains("2") || fbase.Contains("_2")) AssignIfEmpty(photos, "File_1a", fUrl);
                else if (fbase.Contains("水表") || fbase.Contains("自動灑水")) AssignIfEmpty(photos, "File_1b", fUrl);
                else if (fbase.Contains("上月")) AssignIfEmpty(photos, "File_1c", fUrl);
                else if (fbase.Contains("本月")) AssignIfEmpty(photos, "File_1d", fUrl);
                else AssignIfEmpty(photos, "File_1", fUrl);
            }
            // 2. 輸送逸散
            else if (fbase.Contains("輸送"))
            {
                if (fbase.Contains("2") || fbase.Contains("_2")) AssignIfEmpty(photos, "File_2a", fUrl);
                else AssignIfEmpty(photos, "File_2", fUrl);
            }
            // 3. 運輸車輛
            else if (fbase.Contains("運輸車輛"))
            {
                if (fbase.Contains("2") || fbase.Contains("_2")) AssignIfEmpty(photos, "File_3a", fUrl);
                else AssignIfEmpty(photos, "File_3", fUrl);
            }
            // 4. 車輛通行路徑
            else if (fbase.Contains("通行路徑") || fbase.Contains("車輛通行"))
            {
                if (fbase.Contains("2") || fbase.Contains("_2")) AssignIfEmpty(photos, "File_4a", fUrl);
                else AssignIfEmpty(photos, "File_4", fUrl);
            }
            // 5. 車輛清洗
            else if (fbase.Contains("車輛清洗") || fbase.Contains("洗車"))
            {
                if (fbase.Contains("2") || fbase.Contains("_2")) AssignIfEmpty(photos, "File_5a", fUrl);
                else if (fbase.Contains("水槽") || fbase.Contains("水深")) AssignIfEmpty(photos, "File_5b", fUrl);
                else if (fbase.Contains("有效水深") || fbase.Contains("換水")) AssignIfEmpty(photos, "File_5c", fUrl);
                else if (fbase.Contains("噴水") || fbase.Contains("沖洗長度")) AssignIfEmpty(photos, "File_5d", fUrl);
                else if (fbase.Contains("告示牌") || fbase.Contains("閘門")) AssignIfEmpty(photos, "File_5e", fUrl);
                else if (fbase.Contains("馬達")) AssignIfEmpty(photos, "File_5f", fUrl);
                else if (fbase.Contains("廢水") || fbase.Contains("加壓")) AssignIfEmpty(photos, "File_5g", fUrl);
                else if (fbase.Contains("上月")) AssignIfEmpty(photos, "File_5h", fUrl);
                else if (fbase.Contains("本月")) AssignIfEmpty(photos, "File_5i", fUrl);
                else AssignIfEmpty(photos, "File_5", fUrl);
            }
            // 6. 製程、操作或裝卸作業
            else if (fbase.Contains("製程") || fbase.Contains("操作") || fbase.Contains("裝卸"))
            {
                if (fbase.Contains("2") || fbase.Contains("_2")) AssignIfEmpty(photos, "File_6a", fUrl);
                else if (fbase.Contains("儀表") || fbase.Contains("監測")) AssignIfEmpty(photos, "File_6b", fUrl);
                else if (fbase.Contains("上月")) AssignIfEmpty(photos, "File_6c", fUrl);
                else if (fbase.Contains("本月")) AssignIfEmpty(photos, "File_6d", fUrl);
                else AssignIfEmpty(photos, "File_6", fUrl);
            }
            // 7. 裸露區域
            else if (fbase.Contains("裸露"))
            {
                if (fbase.Contains("2") || fbase.Contains("_2")) AssignIfEmpty(photos, "File_7a", fUrl);
                else AssignIfEmpty(photos, "File_7", fUrl);
            }
            // 8. 管理之道路
            else if (fbase.Contains("管理之道路") || fbase.Contains("管理道路"))
            {
                if (fbase.Contains("2") || fbase.Contains("_2")) AssignIfEmpty(photos, "File_8a", fUrl);
                else AssignIfEmpty(photos, "File_8", fUrl);
            }
            // 9. 監視系統
            else if (fbase.Contains("監視系統") || fbase.Contains("攝錄影") || fbase.Contains("監視"))
            {
                if (fbase.Contains("2") || fbase.Contains("_2")) AssignIfEmpty(photos, "File_9a", fUrl);
                else AssignIfEmpty(photos, "File_9", fUrl);
            }
            // 10. 許可不符
            else if (fbase.Contains("許可不符") || fbase.Contains("10a"))
            {
                AssignIfEmpty(photos, "File_10a", fUrl);
            }
            else if (fbase.Contains("10b"))
            {
                AssignIfEmpty(photos, "File_10b", fUrl);
            }
            // 11. 道路抽查
            else if (fbase.Contains("道路抽查") || fbase.Contains("認養道路") || fbase.Contains("11a"))
            {
                AssignIfEmpty(photos, "File_11a", fUrl);
            }
            else if (fbase.Contains("11b"))
            {
                AssignIfEmpty(photos, "File_11b", fUrl);
            }
            // 全景照片與工廠正門口
            else if (fbase.Contains("全景"))
            {
                AssignIfEmpty(photos, "File_AllView", fUrl);
                AssignIfEmpty(photos, "全景照片", fUrl);
            }
            else if (fbase.Contains("正門口") || fbase.Contains("門口"))
            {
                AssignIfEmpty(photos, "File_Entrance", fUrl);
                AssignIfEmpty(photos, "工廠正門口", fUrl);
            }

            // 雙向映射：若為英文 File_* 檔名，亦補足中文 Key
            if (fbase.Equals("File_1", StringComparison.OrdinalIgnoreCase)) AssignIfEmpty(photos, "堆罝逸散性粒狀污染物質", fUrl);
            else if (fbase.Equals("File_1a", StringComparison.OrdinalIgnoreCase)) AssignIfEmpty(photos, "堆罝逸散性粒狀污染物質_2", fUrl);
            else if (fbase.Equals("File_2", StringComparison.OrdinalIgnoreCase)) AssignIfEmpty(photos, "輸送逸散性粒狀污染物質", fUrl);
            else if (fbase.Equals("File_3", StringComparison.OrdinalIgnoreCase)) AssignIfEmpty(photos, "運輸車輛", fUrl);
            else if (fbase.Equals("File_4", StringComparison.OrdinalIgnoreCase)) AssignIfEmpty(photos, "車輛通行路徑", fUrl);
            else if (fbase.Equals("File_5", StringComparison.OrdinalIgnoreCase)) AssignIfEmpty(photos, "車輛清洗", fUrl);
            else if (fbase.Equals("File_6", StringComparison.OrdinalIgnoreCase)) AssignIfEmpty(photos, "易致粒狀污染物逸散之製程、操作或裝卸作業_1", fUrl);
            else if (fbase.Equals("File_7", StringComparison.OrdinalIgnoreCase)) AssignIfEmpty(photos, "公私場所管理之裸露區域", fUrl);
            else if (fbase.Equals("File_8", StringComparison.OrdinalIgnoreCase)) AssignIfEmpty(photos, "公私場所管理之道路_1", fUrl);
            else if (fbase.Equals("File_9", StringComparison.OrdinalIgnoreCase)) AssignIfEmpty(photos, "攝錄影監視系統_1", fUrl);
            else if (fbase.Equals("File_10a", StringComparison.OrdinalIgnoreCase)) AssignIfEmpty(photos, "其他潛勢調查照片1", fUrl);
            else if (fbase.Equals("File_10b", StringComparison.OrdinalIgnoreCase)) AssignIfEmpty(photos, "其他潛勢調查照片2", fUrl);
            else if (fbase.Equals("File_11a", StringComparison.OrdinalIgnoreCase)) AssignIfEmpty(photos, "執行道路髒污抽查照片1", fUrl);
            else if (fbase.Equals("File_11b", StringComparison.OrdinalIgnoreCase)) AssignIfEmpty(photos, "執行道路髒污抽查照片2", fUrl);
            else if (fbase.Equals("File_AllView", StringComparison.OrdinalIgnoreCase)) AssignIfEmpty(photos, "全景照片", fUrl);
            else if (fbase.Equals("File_Entrance", StringComparison.OrdinalIgnoreCase)) AssignIfEmpty(photos, "工廠正門口", fUrl);
        }

        private void AssignIfEmpty(Dictionary<string, string> dict, string key, string value)
        {
            if (!dict.ContainsKey(key) || string.IsNullOrEmpty(dict[key]))
            {
                dict[key] = value;
            }
        }

        private Dictionary<string, object> BuildInvSummary(DataRow r)
        {
            var d = new Dictionary<string, object>();
            d["InvNo"] = r["INV_NO"];
            DateTime invDate;
            if (DateTime.TryParse(r["INV_DATE"].ToString(), out invDate))
            {
                d["InvDate"] = invDate.ToString("yyyy/MM/dd HH:mm");
            }
            else
            {
                d["InvDate"] = r["INV_DATE"].ToString();
            }

            d["InvType"] = r.Table.Columns.Contains("INV_TYPE") ? r["INV_TYPE"].ToString() : "定期巡查";
            d["WorkState"] = r.Table.Columns.Contains("Work_State") ? r["Work_State"].ToString() : "正常運作";
            d["StateName"] = r.Table.Columns.Contains("State_Name") ? r["State_Name"].ToString() : (r["INV_State"] != null ? r["INV_State"].ToString() : "");
            d["Inspector"] = r.Table.Columns.Contains("INV_User") && r["INV_User"] != DBNull.Value ? r["INV_User"].ToString() : (r.Table.Columns.Contains("Up_User") && r["Up_User"] != DBNull.Value ? r["Up_User"].ToString() : "查核員");

            int ptLoss = managerList.LossPointCalculator.CalTotalLossPoint(r);
            string detailLoss = managerList.LossPointCalculator.GetAllLossDetail(r);
            d["TotalLossPoint"] = ptLoss;
            d["LossDetail"] = detailLoss;
            return d;
        }

        private List<Dictionary<string, object>> BuildCompareSections(DataRow r, Dictionary<string, string> photos)
        {
            List<Dictionary<string, object>> list = new List<Dictionary<string, object>>();

            // 1. 堆置
            list.Add(CreateCompareSection(1, "堆置逸散性粒狀污染物質", r, photos,
                new string[] { "INV_01_01", "INV_01_02", "INV_01_03" },
                new string[] { "INV_01_04", "INV_01_05" },
                new string[] { "INV_01_07", "INV_01_08", "INV_01_09", "INV_01_09a", "INV_01_09b", "INV_01_09c", "INV_01_09d", "INV_01_10", "INV_01_10a", "INV_01_10b", "INV_01_11", "INV_01_11a", "INV_01_11b", "INV_01_11c", "INV_01_12", "INV_01_12a", "INV_01_12b", "INV_01_12c", "INV_01_13", "INV_01_14" },
                new string[] { "File_1", "File_1a", "File_1b", "File_1c", "File_1d" },
                new string[] { "FileMemo_1", "FileMemo_1a", "FileMemo_1b", "FileMemo_1c", "FileMemo_1d" },
                new string[] { "堆置逸散照片 1", "堆置逸散照片 2", "自動灑水水表", "上月紀錄表", "本月紀錄表" }
            ));

            // 2. 輸送
            list.Add(CreateCompareSection(2, "輸送逸散性粒狀污染物質", r, photos,
                new string[] { "INV_02_01", "INV_02_02", "INV_02_03", "INV_02_04" },
                new string[] { "INV_02_05", "INV_02_06" },
                new string[] { "INV_02_07", "INV_02_08", "INV_02_09", "INV_02_09a", "INV_02_09b", "INV_02_10", "INV_02_10a", "INV_02_10b", "INV_02_10c", "INV_02_11" },
                new string[] { "File_2", "File_2a" },
                new string[] { "FileMemo_2", "FileMemo_2a" },
                new string[] { "輸送作業照片 1", "輸送作業照片 2" }
            ));

            // 3. 運輸車輛
            list.Add(CreateCompareSection(3, "運輸車輛", r, photos,
                new string[] { "INV_03_01", "INV_03_02", "INV_03_03" },
                new string[] { "INV_03_04", "INV_03_05", "INV_03_06" },
                new string[] { "INV_03_07", "INV_03_08", "INV_03_09" },
                new string[] { "File_3", "File_3a" },
                new string[] { "FileMemo_3", "FileMemo_3a" },
                new string[] { "運輸車輛照片 1", "運輸車輛照片 2" }
            ));

            // 4. 車輛通行路徑
            list.Add(CreateCompareSection(4, "車輛通行路徑", r, photos,
                new string[] { "INV_04_01", "INV_04_02", "INV_04_03" },
                new string[] { "INV_04_04", "INV_04_05" },
                new string[] { "INV_04_06", "INV_04_07", "INV_04_08", "INV_04_09" },
                new string[] { "File_4", "File_4a" },
                new string[] { "FileMemo_4", "FileMemo_4a" },
                new string[] { "通行路徑照片 1", "通行路徑照片 2" }
            ));

            // 5. 車輛清洗
            list.Add(CreateCompareSection(5, "車輛清洗", r, photos,
                new string[] { "INV_05_01", "INV_05_02", "INV_05_03" },
                new string[] { "INV_05_04", "INV_05_05", "INV_05_06" },
                new string[] { "INV_05_07", "INV_05_08", "INV_05_09", "INV_05_10", "INV_05_11" },
                new string[] { "File_5", "File_5a", "File_5b", "File_5c", "File_5d", "File_5e", "File_5f", "File_5g", "File_5h", "File_5i" },
                new string[] { "FileMemo_5", "FileMemo_5a", "FileMemo_5b", "FileMemo_5c", "FileMemo_5d", "FileMemo_5e", "FileMemo_5f", "FileMemo_5g", "FileMemo_5h", "FileMemo_5i" },
                new string[] { "洗車台照片 1", "洗車台照片 2", "水槽水深量測", "有效水深", "沖洗長度", "告示牌", "馬達規格", "加壓沖洗", "上月紀錄表", "本月紀錄表" }
            ));

            // 6. 易致粒狀污染物逸散之製程裝卸作業
            list.Add(CreateCompareSection(6, "易致粒狀污染物逸散之製程裝卸作業", r, photos,
                new string[] { "INV_06_01", "INV_06_02", "INV_06_03", "INV_06_04" },
                new string[] { "INV_06_05", "INV_06_06" },
                new string[] { "INV_06_07", "INV_06_07a", "INV_06_07b", "INV_06_08", "INV_06_08a", "INV_06_08b", "INV_06_09", "INV_06_10", "INV_06_11", "INV_06_12" },
                new string[] { "File_6", "File_6a", "File_6b", "File_6c", "File_6d" },
                new string[] { "FileMemo_6", "FileMemo_6a", "FileMemo_6b", "FileMemo_6c", "FileMemo_6d" },
                new string[] { "製程裝卸照片 1", "製程裝卸照片 2", "監測儀表", "上月紀錄表", "本月紀錄表" }
            ));

            // 7. 公私場所管理之裸露區域
            list.Add(CreateCompareSection(7, "公私場所管理之裸露區域", r, photos,
                new string[] { "INV_07_01", "INV_07_02", "INV_07_03" },
                new string[] { "INV_07_04", "INV_07_05" },
                new string[] { "INV_07_06", "INV_07_07", "INV_07_08", "INV_07_09", "INV_07_10", "INV_07_11" },
                new string[] { "File_7", "File_7a" },
                new string[] { "FileMemo_7", "FileMemo_7a" },
                new string[] { "裸露區域照片 1", "裸露區域照片 2" }
            ));

            // 8. 公私場所管理之道路
            list.Add(CreateCompareSection(8, "公私場所管理之道路", r, photos,
                new string[] { "INV_08_01", "INV_08_02", "INV_08_03" },
                new string[] { "INV_08_04", "INV_08_05" },
                new string[] { "INV_08_06", "INV_08_07", "INV_08_08", "INV_08_09", "INV_08_10" },
                new string[] { "File_8", "File_8a" },
                new string[] { "FileMemo_8", "FileMemo_8a" },
                new string[] { "管理道路照片 1", "管理道路照片 2" }
            ));

            // 9. 攝錄影監視系統
            list.Add(CreateCompareSection(9, "攝錄影監視系統", r, photos,
                new string[] { "INV_09_01", "INV_09_02", "INV_09_03" },
                new string[] { "INV_09_04", "INV_09_05", "INV_09_06" },
                new string[] { "INV_09_07", "INV_09_08" },
                new string[] { "File_9", "File_9a" },
                new string[] { "FileMemo_9", "FileMemo_9a" },
                new string[] { "監視系統照片 1", "監視系統照片 2" }
            ));

            // 10. 全景照片及其他查核佐證 (僅照片，無文字欄位)
            list.Add(CreateInfoSection(10, "全景照片及其他查核佐證", r, photos,
                new List<Dictionary<string, string>>(),
                new string[][] {
                    new string[] { "全景照片", "FileMemo_AllView", "全景照片", "File_AllView" },
                    new string[] { "工廠正門口照片", "FileMemo_Entrance", "工廠正門口", "File_Entrance" },
                    new string[] { "輔導簽認單 1", "FileMemo_Counseling1", "輔導簽認單_1", "File_Counseling1" },
                    new string[] { "輔導簽認單 2", "FileMemo_Counseling2", "輔導簽認單_2", "File_Counseling2" },
                    new string[] { "局部集氣評估 1", "FileMemo_CollGasEfficiency1", "局部集氣效率評估_1", "File_CollGasEfficiency1" },
                    new string[] { "局部集氣評估 2", "FileMemo_CollGasEfficiency2", "局部集氣效率評估_2", "File_CollGasEfficiency2" },
                    new string[] { "空品感測數據 1", "FileMemo_AirQualityValue1", "空品感測數據_1", "File_AirQualityValue1" },
                    new string[] { "空品感測數據 2", "FileMemo_AirQualityValue2", "空品感測數據_2", "File_AirQualityValue2" }
                }
            ));

            // 11. 環境潛勢調查及許可不符項目
            list.Add(CreateInfoSection(11, "環境潛勢調查及許可不符項目", r, photos,
                BuildEnvDetails(r),
                new string[][] {
                    new string[] { "潛勢調查照片 1", "FileMemo_10a", "其他潛勢調查照片1", "File_10a" },
                    new string[] { "潛勢調查照片 2", "FileMemo_10b", "其他潛勢調查照片2", "File_10b" }
                }
            ));

            // 12. 執行道路髒污抽查
            list.Add(CreateInfoSection(12, "執行道路髒污抽查", r, photos,
                BuildCleanRoadDetails(r),
                new string[][] {
                    new string[] { "道路抽查照片 1", "FileMemo_11a", "執行道路髒污抽查照片1", "File_11a" },
                    new string[] { "道路抽查照片 2", "FileMemo_11b", "執行道路髒污抽查照片2", "File_11b" }
                }
            ));

            return list;
        }

        private Dictionary<string, object> CreateCompareSection(int id, string title, DataRow r, Dictionary<string, string> photos,
            string[] keys0, string[] keys10, string[] keys4,
            string[] photoKeys, string[] memoKeys, string[] photoLabels)
        {
            Dictionary<string, object> sec = new Dictionary<string, object>();
            sec["Id"] = id;
            sec["Title"] = title;

            int loss = 0;
            List<string> violations = new List<string>();
            List<string> compliantItems = new List<string>();

            // 檢查 10 點違規
            foreach (string k in keys10)
            {
                if (r.Table.Columns.Contains(k) && (r[k].ToString() == "Y" || r[k].ToString() == "V"))
                {
                    loss = 10;
                    violations.Add(GetCheckItemName(k));
                }
            }

            // 檢查 4 點違規
            foreach (string k in keys4)
            {
                if (r.Table.Columns.Contains(k) && (r[k].ToString() == "Y" || r[k].ToString() == "V"))
                {
                    if (loss < 4) loss = 4;
                    violations.Add(GetCheckItemName(k));
                }
            }

            // 檢查合格項
            foreach (string k in keys0)
            {
                if (r.Table.Columns.Contains(k) && (r[k].ToString() == "Y" || r[k].ToString() == "V"))
                {
                    compliantItems.Add(GetCheckItemName(k));
                }
            }

            sec["LossPoint"] = loss;
            sec["Violations"] = violations;
            sec["CompliantItems"] = compliantItems;

            // 附加照片 (支援代號 File_*、中文標籤 photoLabels 雙重比對)
            List<Dictionary<string, string>> photoList = new List<Dictionary<string, string>>();
            for (int i = 0; i < photoKeys.Length; i++)
            {
                string pKey = photoKeys[i];
                string pLabel = i < photoLabels.Length ? photoLabels[i] : pKey;
                string memoCol = i < memoKeys.Length ? memoKeys[i] : "";
                string memoVal = (r.Table.Columns.Contains(memoCol) && r[memoCol] != DBNull.Value) ? r[memoCol].ToString().Trim() : "";

                // 優先從 photos 字典以 pKey 查詢 (如 File_1, File_1a)
                string pUrl = "";
                if (photos.ContainsKey(pKey) && !string.IsNullOrEmpty(photos[pKey]))
                {
                    pUrl = photos[pKey];
                }
                else if (photos.ContainsKey(pLabel) && !string.IsNullOrEmpty(photos[pLabel]))
                {
                    pUrl = photos[pLabel];
                }

                if (!string.IsNullOrEmpty(pUrl) || !string.IsNullOrEmpty(memoVal))
                {
                    Dictionary<string, string> p = new Dictionary<string, string>();
                    p["Key"] = pKey;
                    p["Label"] = pLabel;
                    p["Memo"] = memoVal;
                    p["Url"] = pUrl;
                    photoList.Add(p);
                }
            }
            sec["Photos"] = photoList;

            return sec;
        }

        private string GetStr(DataRow r, string col)
        {
            if (r == null || string.IsNullOrEmpty(col) || !r.Table.Columns.Contains(col) || r[col] == DBNull.Value) return "";
            return r[col].ToString().Trim();
        }

        private void AddDetail(List<Dictionary<string, string>> list, string label, string value)
        {
            if (string.IsNullOrEmpty(value)) return;
            Dictionary<string, string> d = new Dictionary<string, string>();
            d["Label"] = label;
            d["Value"] = value;
            list.Add(d);
        }

        private List<Dictionary<string, string>> BuildEnvDetails(DataRow r)
        {
            List<Dictionary<string, string>> list = new List<Dictionary<string, string>>();
            AddDetail(list, "調查項目", GetStr(r, "EnvirCheck_Item"));
            AddDetail(list, "其他調查說明", GetStr(r, "EnvirCheck_Other"));
            string ans1 = GetStr(r, "OtherChkAns1");
            AddDetail(list, "狀態", ans1);
            if (ans1 != "無")
            {
                AddDetail(list, "事項", GetStr(r, "OtherChkAns2"));
            }
            AddDetail(list, "詳細說明", GetStr(r, "OtherChkMemo"));
            return list;
        }

        private string CleanLevelText(DataRow r, string lv, string extraName)
        {
            string flag = GetStr(r, "CleanRoad_Ans2_CleanLV_" + lv);
            if (flag != "Y" && flag != "V") return "";
            string len = GetStr(r, "CleanRoad_Ans2_CleanLength_" + lv);
            string txt = "";
            if (!string.IsNullOrEmpty(extraName)) txt = extraName + " ";
            txt += (string.IsNullOrEmpty(len) ? "0" : len) + " 公尺";
            return txt;
        }

        private List<Dictionary<string, string>> BuildCleanRoadDetails(DataRow r)
        {
            List<Dictionary<string, string>> list = new List<Dictionary<string, string>>();
            string ans1 = GetStr(r, "CleanRoad_Ans1");
            AddDetail(list, "是否執行道路髒污抽查", ans1);
            if (ans1 == "是")
            {
                AddDetail(list, "抽查道路名稱", GetStr(r, "CleanRoad_Ans2_RoadName"));
                AddDetail(list, "良好 (A級)", CleanLevelText(r, "A", ""));
                AddDetail(list, "普通 (B級)", CleanLevelText(r, "B", ""));
                AddDetail(list, "待改進 (C級)", CleanLevelText(r, "C", GetStr(r, "CleanRoad_Ans2_CleanRoadName")));
                AddDetail(list, "認養道路旁水溝是否暢通", GetStr(r, "CleanRoad_Ans3"));
                AddDetail(list, "說明", GetStr(r, "CleanRoad_Ans4"));
            }
            return list;
        }

        private Dictionary<string, object> CreateInfoSection(int id, string title, DataRow r, Dictionary<string, string> photos,
            List<Dictionary<string, string>> details, string[][] photoDefs)
        {
            Dictionary<string, object> sec = new Dictionary<string, object>();
            sec["Id"] = id;
            sec["Title"] = title;
            sec["IsInfo"] = true;
            sec["LossPoint"] = 0;
            sec["Violations"] = new List<string>();
            sec["CompliantItems"] = new List<string>();
            sec["Details"] = details;

            List<Dictionary<string, string>> photoList = new List<Dictionary<string, string>>();
            foreach (string[] def in photoDefs)
            {
                string pUrl = "";
                for (int k = 2; k < def.Length; k++)
                {
                    if (photos.ContainsKey(def[k]) && !string.IsNullOrEmpty(photos[def[k]]))
                    {
                        pUrl = photos[def[k]];
                        break;
                    }
                }
                string memoVal = GetStr(r, def[1]);

                if (!string.IsNullOrEmpty(pUrl) || !string.IsNullOrEmpty(memoVal))
                {
                    Dictionary<string, string> p = new Dictionary<string, string>();
                    p["Key"] = def[2];
                    p["Label"] = def[0];
                    p["Memo"] = memoVal;
                    p["Url"] = pUrl;
                    photoList.Add(p);
                }
            }
            sec["Photos"] = photoList;
            return sec;
        }

        private bool IsInfoSectionChanged(Dictionary<string, object> a, Dictionary<string, object> b)
        {
            if (b == null) return true;

            List<Dictionary<string, string>> da = a["Details"] as List<Dictionary<string, string>>;
            List<Dictionary<string, string>> db = b["Details"] as List<Dictionary<string, string>>;
            StringBuilder sa = new StringBuilder();
            StringBuilder sb2 = new StringBuilder();
            if (da != null) foreach (Dictionary<string, string> d in da) sa.Append(d["Label"]).Append("=").Append(d["Value"]).Append("|");
            if (db != null) foreach (Dictionary<string, string> d in db) sb2.Append(d["Label"]).Append("=").Append(d["Value"]).Append("|");
            if (sa.ToString() != sb2.ToString()) return true;

            // 照片：比較「有哪些欄位有照片」(不比內容，兩次巡查照片本來就不同)
            List<Dictionary<string, string>> pa = a["Photos"] as List<Dictionary<string, string>>;
            List<Dictionary<string, string>> pb = b["Photos"] as List<Dictionary<string, string>>;
            StringBuilder ka = new StringBuilder();
            StringBuilder kb = new StringBuilder();
            if (pa != null) foreach (Dictionary<string, string> p in pa) ka.Append(p["Key"]).Append(string.IsNullOrEmpty(p["Url"]) ? "0" : "1").Append("|");
            if (pb != null) foreach (Dictionary<string, string> p in pb) kb.Append(p["Key"]).Append(string.IsNullOrEmpty(p["Url"]) ? "0" : "1").Append("|");
            return ka.ToString() != kb.ToString();
        }

                private static readonly Dictionary<string, string> CheckItemNames = InitCheckItemNames();

        private static Dictionary<string, string> InitCheckItemNames()
        {
            Dictionary<string, string> dict = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            dict["INV_01_01"] = "無本製程";
            dict["INV_01_02"] = "全項符合防制規範";
            dict["INV_01_03"] = "依核准替代方法設置或採行防制設施";
            dict["INV_01_04"] = "未設置或採行第四條規定防制設施之一 (記10點)";
            dict["INV_01_05"] = "未依直轄市、主管機關同意後之替代方法執行 (記10點)";
            dict["INV_01_07"] = "堆置高度超過阻隔設施高度 (記4點)";
            dict["INV_01_08"] = "採堆置於封閉式建築物內者，未符合第二條第二款規定 (記4點)";
            dict["INV_01_09"] = "堆置區周界阻隔設施未符規定 (記4點)";
            dict["INV_01_09a"] = "阻隔設施高度未達堆置高度 1.25 倍";
            dict["INV_01_09b"] = "未完全圍封堆置區";
            dict["INV_01_09c"] = "阻隔設施破損面積達百分之十以上";
            dict["INV_01_09d"] = "堆置體積3000立方公尺以上未符規定";
            dict["INV_01_10"] = "覆蓋防塵布或防塵網未符規定 (記4點)";
            dict["INV_01_10a"] = "覆蓋面積未達 80%";
            dict["INV_01_10b"] = "三級防制區覆蓋未達 90%";
            dict["INV_01_11"] = "噴灑化學穩定劑未符規定 (記4點)";
            dict["INV_01_11a"] = "噴灑面積未達 80%";
            dict["INV_01_11b"] = "未依第十條記錄施作與保存憑證";
            dict["INV_01_11c"] = "三級防制區噴灑未達 90%";
            dict["INV_01_12"] = "設置自動灑水設備未符規定 (記4點)";
            dict["INV_01_12a"] = "灑水水量及頻率不足保持濕潤";
            dict["INV_01_12b"] = "需人工操作無法自動灑水";
            dict["INV_01_12c"] = "未設水表每日記錄用水量";
            dict["INV_01_13"] = "四周未設置阻隔防溢座或物料掉落溢流至區外 (記4點)";
            dict["INV_01_14"] = "效果優於設施但未依同意方式完整執行 (記4點)";
            dict["INV_02_01"] = "無本製程";
            dict["INV_02_02"] = "採濕式作業免設置";
            dict["INV_02_03"] = "全項符合防制規範";
            dict["INV_02_04"] = "依核准替代方法設置或採行防制設施";
            dict["INV_02_05"] = "未設置防制設施之一 (記10點)";
            dict["INV_02_06"] = "未依主管機關同意替代方法執行 (記10點)";
            dict["INV_02_07"] = "於封閉式建築物內操作未符規定 (記4點)";
            dict["INV_02_08"] = "密閉式輸送系統未完全密閉或破損 (記4點)";
            dict["INV_02_09"] = "採集氣系統未符規定 (記4點)";
            dict["INV_02_09a"] = "集氣系統捕捉速度不足";
            dict["INV_02_09b"] = "未設電表、流量計、壓差計等監測儀表並記錄";
            dict["INV_02_10"] = "採自動灑水設施未符規定 (記4點)";
            dict["INV_02_10a"] = "灑水水量及頻率不足保持濕潤";
            dict["INV_02_10b"] = "需人工操作無法自動灑水";
            dict["INV_02_10c"] = "未設水表每日記錄用水量";
            dict["INV_02_11"] = "效果優於設施但未依同意方式完整執行 (記4點)";
            dict["INV_03_01"] = "無本作業";
            dict["INV_03_02"] = "全項符合防制規範";
            dict["INV_03_03"] = "依核准替代方法設置或採行防制設施";
            dict["INV_03_04"] = "運輸車輛未使用密閉式貨箱或未緊密覆蓋 (記10點)";
            dict["INV_03_05"] = "貨箱未具防滴落污水污泥之功能或設施 (記10點)";
            dict["INV_03_06"] = "未依主管機關同意替代方法執行 (記10點)";
            dict["INV_03_07"] = "封蓋未緊密覆蓋 (邊緣未延伸覆蓋至貨箱上緣15公分以下) (記4點)";
            dict["INV_03_08"] = "具有設施但運輸過程仍滴落污水、污泥或掉落物料於地面 (記4點)";
            dict["INV_03_09"] = "效果優於設施但未依同意方式完整執行 (記4點)";
            dict["INV_04_01"] = "無本作業";
            dict["INV_04_02"] = "全項符合防制規範";
            dict["INV_04_03"] = "依核准替代方法設置或採行防制設施";
            dict["INV_04_04"] = "車輛通行路徑及區域未依規定設置防制設施 (記10點)";
            dict["INV_04_05"] = "未依主管機關同意替代方法執行 (記10點)";
            dict["INV_04_06"] = "設置或採行防制設施面積不足 (記4點)";
            dict["INV_04_07"] = "舖設混凝土、瀝青混凝土或鋼板惟有路面色差 (記4點)";
            dict["INV_04_08"] = "舖設粗級配粒料厚度不足或未灑水保持濕潤 (記4點)";
            dict["INV_04_09"] = "效果優於設施但未依同意方式完整執行 (記4點)";
            dict["INV_05_01"] = "無本作業";
            dict["INV_05_02"] = "全項符合防制規範";
            dict["INV_05_03"] = "依核准替代方法設置或採行防制設施";
            dict["INV_05_04"] = "未依規定以加壓沖洗設備清洗車體及輪胎 (記10點)";
            dict["INV_05_05"] = "須洗掃鄰接道路並設自動洗車設備而未依規定洗掃或設置 (記10點)";
            dict["INV_05_06"] = "未依主管機關同意替代方法執行 (記10點)";
            dict["INV_05_07"] = "運輸車輛未清洗乾淨致門口路面有帶出污泥物料 (記4點)";
            dict["INV_05_08"] = "洗車設備無加壓沖洗功能 (記4點)";
            dict["INV_05_09"] = "自動洗車設備規格未符附表二規定 (記4點)";
            dict["INV_05_10"] = "未設水表電表並記錄用水或用電度數 (記4點)";
            dict["INV_05_11"] = "效果優於設施但未依同意方式完整執行 (記4點)";
            dict["INV_06_01"] = "無本製程";
            dict["INV_06_02"] = "採濕式作業免設置";
            dict["INV_06_03"] = "全項符合防制規範";
            dict["INV_06_04"] = "依核准替代方法設置或採行防制設施";
            dict["INV_06_05"] = "未設置或採行第七條防制設施之一 (記10點)";
            dict["INV_06_06"] = "未依主管機關同意替代方法執行 (記10點)";
            dict["INV_06_07"] = "採負壓操作之密閉式作業未符規定 (記4點)";
            dict["INV_06_07a"] = "未維持負壓操作狀態";
            dict["INV_06_07b"] = "未設電表、流量計、壓差計等監測儀表並記錄";
            dict["INV_06_08"] = "採集氣系統未符規定 (記4點)";
            dict["INV_06_08a"] = "捕捉速度不足";
            dict["INV_06_08b"] = "未設電表等監測儀表並記錄";
            dict["INV_06_09"] = "密閉式作業未妥善密閉或破損 (記4點)";
            dict["INV_06_10"] = "封閉式建築未符合規定 (記4點)";
            dict["INV_06_11"] = "灑水設施噴灑範圍、水量及頻率不足 (記4點)";
            dict["INV_06_12"] = "效果優於設施但未依同意方式完整執行 (記4點)";
            dict["INV_07_01"] = "無本區域";
            dict["INV_07_02"] = "全項符合防制規範";
            dict["INV_07_03"] = "依核准替代方法設置或採行防制設施";
            dict["INV_07_04"] = "未設置或採行第八條防制設施之一 (記10點)";
            dict["INV_07_05"] = "未依主管機關同意替代方法執行 (記10點)";
            dict["INV_07_06"] = "防制設施實施面積未完整涵蓋裸露區域 (記4點)";
            dict["INV_07_07"] = "植生綠化覆蓋稻草蓆碎木厚度不足 (記4點)";
            dict["INV_07_08"] = "舖設粗級配粒料粒徑厚度不足或未灑水保持濕潤 (記4點)";
            dict["INV_07_09"] = "噴灑化學穩定劑或灑水量及頻率不足 (記4點)";
            dict["INV_07_10"] = "噴灑穩定劑未記錄保存購買證明 (記4點)";
            dict["INV_07_11"] = "效果優於設施但未依同意方式完整執行 (記4點)";
            dict["INV_08_01"] = "無本道路";
            dict["INV_08_02"] = "全項符合防制規範";
            dict["INV_08_03"] = "依核准替代方法設置或採行防制設施";
            dict["INV_08_04"] = "交通島及人行道裸露區域未設置防制設施之一 (記10點)";
            dict["INV_08_05"] = "未依主管機關同意替代方法執行 (記10點)";
            dict["INV_08_06"] = "路面有破損、髒污致路面色差 (記4點)";
            dict["INV_08_07"] = "交通島及人行道裸露區域防制面積不足 (記4點)";
            dict["INV_08_08"] = "植生綠化覆蓋稻草蓆碎木厚度不足 (記4點)";
            dict["INV_08_09"] = "舖設粗級配粒料粒徑厚度不足或未灑水 (記4點)";
            dict["INV_08_10"] = "效果優於設施但未依同意方式完整執行 (記4點)";
            dict["INV_09_01"] = "無須設置";
            dict["INV_09_02"] = "全項符合防制規範";
            dict["INV_09_03"] = "依核准替代方法設置或採行防制設施";
            dict["INV_09_04"] = "須設置攝錄影監視系統而未設置 (記10點)";
            dict["INV_09_05"] = "監視系統故障未於次日起算七日內修復完成 (記10點)";
            dict["INV_09_06"] = "未依主管機關同意替代方法執行 (記10點)";
            dict["INV_09_07"] = "未符合附表四規定或記錄影像資料未保存一個月 (記4點)";
            dict["INV_09_08"] = "監視系統故障未即時通報主管機關 (記4點)";
            dict["INV_09_09"] = "效果優於設施但未依同意方式完整執行 (記4點)";
            return dict;
        }

        private string GetCheckItemName(string colName)
        {
            if (string.IsNullOrEmpty(colName)) return "";
            if (CheckItemNames.ContainsKey(colName))
            {
                return CheckItemNames[colName];
            }
            // 後備大項辨識，避免顯示孤立英文代號
            if (colName.StartsWith("INV_01_")) return "一、堆置逸散防制缺失項目";
            if (colName.StartsWith("INV_02_")) return "二、輸送逸散防制缺失項目";
            if (colName.StartsWith("INV_03_")) return "三、運輸車輛防制缺失項目";
            if (colName.StartsWith("INV_04_")) return "四、車輛通行路徑防制缺失項目";
            if (colName.StartsWith("INV_05_")) return "五、洗車設施防制缺失項目";
            if (colName.StartsWith("INV_06_")) return "六、製程防制缺失項目";
            if (colName.StartsWith("INV_07_")) return "七、裸露區域防制缺失項目";
            if (colName.StartsWith("INV_08_")) return "八、管轄道路防制缺失項目";
            if (colName.StartsWith("INV_09_")) return "九、監視系統防制缺失項目";
            return colName;
        }
        #endregion

        #region 匯出 Excel 報表
        private void HandleExportExcel()
        {
            try
            {
                string mode = Request["Mode"] != null ? Request["Mode"].Trim().ToLower() : "all";
                string facName = Request["FacName"] != null ? Request["FacName"].Trim() : (Request["SearchFacName"] != null ? Request["SearchFacName"].Trim() : "");
                string cNo = Request["CNo"] != null ? Request["CNo"].Trim() : (Request["SearchCNo"] != null ? Request["SearchCNo"].Trim() : "");
                string scId = Request["ScId"] != null ? Request["ScId"].Trim() : (Request["SearchScId"] != null ? Request["SearchScId"].Trim() : "");
                string townsParam = Request["Towns"] != null ? Request["Towns"].Trim() : (Request["SearchTown"] != null ? Request["SearchTown"].Trim() : "");
                string sortBy = Request["SortBy"] != null ? Request["SortBy"].Trim() : "loss_desc";

                var sbSql = new StringBuilder();
                var pList = new List<SqlParameter>();

                sbSql.Append("SELECT f.* FROM FAC_Main f WHERE 1=1 ");

                // 模式過濾
                if (mode == "reject")
                {
                    sbSql.Append(" AND EXISTS (SELECT 1 FROM INV_DATA d WHERE d.FAC_ID = f.FAC_ID AND d.INV_State = 'A00a') ");
                }
                else if (mode == "back")
                {
                    sbSql.Append(" AND EXISTS (SELECT 1 FROM INV_DATA d WHERE d.FAC_ID = f.FAC_ID AND d.INV_State = 'A00b') ");
                }
                else if (mode == "mission7day")
                {
                    sbSql.Append(" AND EXISTS (SELECT 1 FROM INV_Mission m WHERE m.FAC_ID = f.FAC_ID AND m.Cancel_Date IS NULL AND (m.pReason LIKE '%7天內未完成改善回報%' OR m.pReason LIKE '%7天%')) ");
                }
                else if (mode == "mission2times")
                {
                    sbSql.Append(" AND EXISTS (SELECT 1 FROM INV_Mission m WHERE m.FAC_ID = f.FAC_ID AND m.Cancel_Date IS NULL AND m.pReason LIKE '%稽查列管%') ");
                }
                else if (mode == "mission")
                {
                    sbSql.Append(" AND EXISTS (SELECT 1 FROM INV_Mission m WHERE m.FAC_ID = f.FAC_ID AND m.Cancel_Date IS NULL) ");
                }
                else if (mode == "project")
                {
                    sbSql.Append(" AND (f.TOWN LIKE '%八里%' OR f.ADDR LIKE '%八里%') ");
                }

                // 關鍵字搜尋
                if (!string.IsNullOrEmpty(facName))
                {
                    sbSql.Append(" AND f.FAC_NAME LIKE @FAC_NAME ");
                    pList.Add(new SqlParameter("@FAC_NAME", "%" + facName + "%"));
                }
                if (!string.IsNullOrEmpty(cNo))
                {
                    sbSql.Append(" AND f.C_NO LIKE @C_NO ");
                    pList.Add(new SqlParameter("@C_NO", "%" + cNo + "%"));
                }
                if (!string.IsNullOrEmpty(scId))
                {
                    sbSql.Append(" AND f.S_C_ID LIKE @S_C_ID ");
                    pList.Add(new SqlParameter("@S_C_ID", "%" + scId + "%"));
                }

                // 行政區過濾
                if (!string.IsNullOrEmpty(townsParam))
                {
                    string[] townArr = townsParam.Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
                    if (townArr.Length > 0)
                    {
                        var townClause = new StringBuilder();
                        townClause.Append(" AND (");
                        for (int t = 0; t < townArr.Length; t++)
                        {
                            if (t > 0) townClause.Append(" OR ");
                            string pName = "@Town_" + t.ToString();
                            townClause.Append(string.Format("(f.TOWN LIKE {0} OR f.ADDR LIKE {0})", pName));
                            pList.Add(new SqlParameter(pName, "%" + townArr[t].Trim() + "%"));
                        }
                        townClause.Append(") ");
                        sbSql.Append(townClause.ToString());
                    }
                }

                DataTable dt = DbHelper.ExecuteDataTable(sbSql.ToString(), pList.ToArray());

                // 補充派遣與最新缺失記點
                AttachMissionData(ref dt);
                AttachLatestLossPoint(ref dt);

                // 排序處理
                if (dt != null && dt.Rows.Count > 1)
                {
                    DataView dv = dt.DefaultView;
                    string sortExp = "FAC_ID DESC";
                    if (sortBy == "loss_desc") sortExp = "Loss_Point DESC, FAC_ID DESC";
                    else if (sortBy == "loss_asc") sortExp = "Loss_Point ASC, FAC_ID DESC";
                    else if (sortBy == "name_asc") sortExp = "FAC_NAME ASC";
                    else if (sortBy == "date_desc") sortExp = "LastInvDate DESC, FAC_ID DESC";
                    dv.Sort = sortExp;
                    dt = dv.ToTable();
                }

                HSSFWorkbook workbook = new HSSFWorkbook();
                ISheet sheet = workbook.CreateSheet("巡查場所清單");

                // 標題樣式
                ICellStyle headerStyle = workbook.CreateCellStyle();
                IFont headerFont = workbook.CreateFont();
                headerFont.FontName = "微軟正黑體";
                headerFont.FontHeightInPoints = 11.0;
                headerFont.IsBold = true;
                headerStyle.SetFont(headerFont);
                headerStyle.Alignment = HorizontalAlignment.Center;
                headerStyle.VerticalAlignment = VerticalAlignment.Center;
                headerStyle.FillForegroundColor = NPOI.HSSF.Util.HSSFColor.Grey25Percent.Index;
                headerStyle.FillPattern = FillPattern.SolidForeground;
                headerStyle.BorderBottom = NPOI.SS.UserModel.BorderStyle.Thin;
                headerStyle.BorderTop = NPOI.SS.UserModel.BorderStyle.Thin;
                headerStyle.BorderLeft = NPOI.SS.UserModel.BorderStyle.Thin;
                headerStyle.BorderRight = NPOI.SS.UserModel.BorderStyle.Thin;

                // 內容樣式
                ICellStyle dataStyle = workbook.CreateCellStyle();
                IFont dataFont = workbook.CreateFont();
                dataFont.FontName = "微軟正黑體";
                dataFont.FontHeightInPoints = 10.0;
                dataStyle.SetFont(dataFont);
                dataStyle.VerticalAlignment = VerticalAlignment.Center;
                dataStyle.BorderBottom = NPOI.SS.UserModel.BorderStyle.Thin;
                dataStyle.BorderTop = NPOI.SS.UserModel.BorderStyle.Thin;
                dataStyle.BorderLeft = NPOI.SS.UserModel.BorderStyle.Thin;
                dataStyle.BorderRight = NPOI.SS.UserModel.BorderStyle.Thin;

                string[] headers = new string[]
                {
                    "序號", "管制編號", "公私場所名稱", "統一編號",
                    "行政區", "廠址地址", "行業別", "派遣/列管警示", "缺失記點", "最新查核說明", "最新查核日", "緯度 (Lat)", "經度 (Lng)"
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
                        string cNoVal = dr["C_NO"] != DBNull.Value ? dr["C_NO"].ToString().Trim() : "";
                        string nameVal = dr["FAC_NAME"] != DBNull.Value ? dr["FAC_NAME"].ToString().Trim() : "";
                        string scIdVal = dr["S_C_ID"] != DBNull.Value ? dr["S_C_ID"].ToString().Trim() : "";
                        string townVal = dr["TOWN"] != DBNull.Value ? dr["TOWN"].ToString().Trim() : "";
                        string addrVal = dr["ADDR"] != DBNull.Value ? dr["ADDR"].ToString().Trim() : "";
                        string indVal = dr.Table.Columns.Contains("Industrial") && dr["Industrial"] != DBNull.Value ? dr["Industrial"].ToString().Trim() : "-";
                        string missionVal = dr.Table.Columns.Contains("Mission") && dr["Mission"] != DBNull.Value ? dr["Mission"].ToString().Trim() : "";
                        string lossPtVal = dr.Table.Columns.Contains("Loss_Point") && dr["Loss_Point"] != DBNull.Value ? dr["Loss_Point"].ToString().Trim() : "0";
                        string lossDescVal = dr.Table.Columns.Contains("Loss_Desc") && dr["Loss_Desc"] != DBNull.Value ? dr["Loss_Desc"].ToString().Trim() : "無缺失";
                        string lastDateVal = dr.Table.Columns.Contains("LastInvDate_Str") && dr["LastInvDate_Str"] != DBNull.Value ? dr["LastInvDate_Str"].ToString().Trim() : "";
                        string latVal = dr.Table.Columns.Contains("Lat") && dr["Lat"] != DBNull.Value ? dr["Lat"].ToString().Trim() : "";
                        string lngVal = dr.Table.Columns.Contains("Lng") && dr["Lng"] != DBNull.Value ? dr["Lng"].ToString().Trim() : "";

                        string[] vals = new string[]
                        {
                            seq, cNoVal, nameVal, scIdVal,
                            townVal, addrVal, indVal, missionVal, lossPtVal, lossDescVal, lastDateVal, latVal, lngVal
                        };

                        for (int cIdx = 0; cIdx < vals.Length; cIdx++)
                        {
                            ICell cell = row.CreateCell(cIdx);
                            cell.SetCellValue(vals[cIdx]);
                            cell.CellStyle = dataStyle;
                        }
                    }
                }

                for (int i = 0; i < headers.Length; i++)
                {
                    sheet.SetColumnWidth(i, 16 * 256);
                }
                sheet.SetColumnWidth(0, 8 * 256);
                sheet.SetColumnWidth(2, 32 * 256); // 名稱
                sheet.SetColumnWidth(5, 36 * 256); // 地址
                sheet.SetColumnWidth(9, 36 * 256); // 缺失說明

                Response.Clear();
                Response.ContentType = "application/vnd.ms-excel";
                string filename = "巡查場所派遣清單_" + DateTime.Now.ToString("yyyyMMddHHmmss") + ".xls";

                // 寫入 AuditLog 雙軌稽核日誌
                AuditLogger.Log(
                    operatorUser: GetCurrentUser(),
                    actionType: "CASE_EXPORT_EXCEL",
                    targetUser: "FAC_Main",
                    clientIp: Request.UserHostAddress,
                    details: string.Format("匯出巡查場所派遣清單 Excel，模式：{0}，管制編號：{1}，名稱：{2}，共匯出 {3} 筆",
                        mode, cNo, facName, dt != null ? dt.Rows.Count : 0),
                    oldValue: null,
                    newValue: null
                );

                ExcelExportHelper.ExportToResponse(workbook, filename, Response);
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

