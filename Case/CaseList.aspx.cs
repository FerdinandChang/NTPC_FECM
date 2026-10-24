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
using NTPC_FEC.Manager;
using NTPC_FEC.Services;

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
                string relDir = "/Upload/FAC/" + cNo;
                string absDir = Server.MapPath("~" + relDir);
                if (Directory.Exists(absDir))
                {
                    DirectoryInfo di = new DirectoryInfo(absDir);
                    FileInfo[] files = di.GetFiles(cNo + "*.*");
                    foreach (FileInfo fi in files)
                    {
                        string ext = fi.Extension.ToLower();
                        if (ext == ".pdf" || ext == ".jpg" || ext == ".png" || ext == ".jpeg")
                        {
                            var d = new Dictionary<string, string>();
                            d["FileName"] = fi.Name;
                            d["FileType"] = fi.Name.Contains("配置圖") ? "廠區配置圖" : (fi.Name.Contains("流程圖") ? "製程流程圖" : "相關圖檔");
                            d["FileUrl"] = relDir + "/" + fi.Name;
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

        private static void Wgs84ToTwd97(double lat, double lon, out double x, out double y)
        {
            double a = 6378137.0;
            double b = 6356752.314245;
            double lon0 = 121.0 * Math.PI / 180.0;
            double k0 = 0.9999;
            double dx = 250000.0;

            double latRad = lat * Math.PI / 180.0;
            double lonRad = lon * Math.PI / 180.0;

            double e = Math.Sqrt(1.0 - (b * b) / (a * a));
            double e2 = e * e / (1.0 - e * e);

            double T = Math.Pow(Math.Tan(latRad), 2);
            double C = e2 * Math.Pow(Math.Cos(latRad), 2);
            double A = (lonRad - lon0) * Math.Cos(latRad);

            double M = a * ((1.0 - Math.Pow(e, 2) / 4.0 - 3.0 * Math.Pow(e, 4) / 64.0 - 5.0 * Math.Pow(e, 6) / 256.0) * latRad
                - (3.0 * Math.Pow(e, 2) / 8.0 + 3.0 * Math.Pow(e, 4) / 32.0 + 45.0 * Math.Pow(e, 6) / 1024.0) * Math.Sin(2.0 * latRad)
                + (15.0 * Math.Pow(e, 4) / 256.0 + 45.0 * Math.Pow(e, 6) / 1024.0) * Math.Sin(4.0 * latRad)
                - (35.0 * Math.Pow(e, 6) / 3072.0) * Math.Sin(6.0 * latRad));

            double N = a / Math.Sqrt(1.0 - Math.Pow(e, 2) * Math.Pow(Math.Sin(latRad), 2));

            x = dx + k0 * N * (A + (1.0 - T + C) * Math.Pow(A, 3) / 6.0 + (5.0 - 18.0 * T + Math.Pow(T, 2) + 72.0 * C - 58.0 * e2) * Math.Pow(A, 5) / 120.0);
            y = k0 * (M + N * Math.Tan(latRad) * (Math.Pow(A, 2) / 2.0 + (5.0 - T + 9.0 * C + 4.0 * Math.Pow(C, 2)) * Math.Pow(A, 4) / 24.0 + (61.0 - 58.0 * T + Math.Pow(T, 2) + 600.0 * C - 330.0 * e2) * Math.Pow(A, 6) / 720.0));
        }
        #endregion
    
        #region 匯出 Excel 報表
        private void HandleExportExcel()
        {
            try
            {
                string mode = Request["Mode"] != null ? Request["Mode"].Trim().ToLower() : "all";
                string facName = Request["SearchFacName"] != null ? Request["SearchFacName"].Trim() : "";
                string cNo = Request["SearchCNo"] != null ? Request["SearchCNo"].Trim() : "";
                string addr = Request["SearchAddr"] != null ? Request["SearchAddr"].Trim() : "";
                string scId = Request["SearchScId"] != null ? Request["SearchScId"].Trim() : "";
                string town = Request["SearchTown"] != null ? Request["SearchTown"].Trim() : "";

                StringBuilder sb = new StringBuilder();
                sb.Append("SELECT m.FAC_ID, m.C_NO, m.FAC_NAME, m.S_C_ID, m.TOWN, m.ADDR, m.Industrial, m.FAC_Type, m.TEL, m.Lat, m.Lng ");
                sb.Append("FROM FAC_Main m WHERE 1=1 ");

                List<SqlParameter> pList = new List<SqlParameter>();

                if (!string.IsNullOrEmpty(cNo))
                {
                    sb.Append(" AND m.C_NO LIKE @C_NO ");
                    pList.Add(new SqlParameter("@C_NO", "%" + cNo + "%"));
                }
                if (!string.IsNullOrEmpty(facName))
                {
                    sb.Append(" AND m.FAC_NAME LIKE @FAC_NAME ");
                    pList.Add(new SqlParameter("@FAC_NAME", "%" + facName + "%"));
                }
                if (!string.IsNullOrEmpty(scId))
                {
                    sb.Append(" AND m.S_C_ID LIKE @S_C_ID ");
                    pList.Add(new SqlParameter("@S_C_ID", "%" + scId + "%"));
                }
                if (!string.IsNullOrEmpty(town))
                {
                    sb.Append(" AND m.TOWN = @TOWN ");
                    pList.Add(new SqlParameter("@TOWN", town));
                }
                if (!string.IsNullOrEmpty(addr))
                {
                    sb.Append(" AND m.ADDR LIKE @ADDR ");
                    pList.Add(new SqlParameter("@ADDR", "%" + addr + "%"));
                }

                sb.Append(" ORDER BY m.C_NO ASC, m.FAC_ID ASC");

                DataTable dt = DbHelper.ExecuteDataTable(sb.ToString(), pList.ToArray());

                HSSFWorkbook workbook = new HSSFWorkbook();
                ISheet sheet = workbook.CreateSheet("巡查場所派遣清單");

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
                    "行政區", "廠址地址", "行業別", "管制狀態", "聯絡電話", "緯度 (Lat)", "經度 (Lng)"
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
                        string indVal = dr["Industrial"] != DBNull.Value ? dr["Industrial"].ToString().Trim() : "";
                        string typeVal = dr["FAC_Type"] != DBNull.Value ? dr["FAC_Type"].ToString().Trim() : "非列管";
                        string telVal = dr["TEL"] != DBNull.Value ? dr["TEL"].ToString().Trim() : "";
                        string latVal = dr["Lat"] != DBNull.Value ? dr["Lat"].ToString().Trim() : "";
                        string lngVal = dr["Lng"] != DBNull.Value ? dr["Lng"].ToString().Trim() : "";

                        string[] vals = new string[]
                        {
                            seq, cNoVal, nameVal, scIdVal,
                            townVal, addrVal, indVal, typeVal, telVal, latVal, lngVal
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
                sheet.SetColumnWidth(2, 30 * 256); // 名稱
                sheet.SetColumnWidth(5, 34 * 256); // 地址

                Response.Clear();
                Response.ContentType = "application/vnd.ms-excel";
                string filename = "巡查場所派遣清單_" + DateTime.Now.ToString("yyyyMMddHHmmss") + ".xls";
                Response.AddHeader("Content-Disposition", "attachment;filename=" + HttpUtility.UrlEncode(filename, Encoding.UTF8));

                using (MemoryStream ms = new MemoryStream())
                {
                    workbook.Write(ms);
                    Response.BinaryWrite(ms.ToArray());
                }

                try
                {
                    Response.End();
                }
                catch (System.Threading.ThreadAbortException)
                {
                }
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
