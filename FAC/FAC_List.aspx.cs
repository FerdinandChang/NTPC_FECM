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

namespace NTPC_FEC.FAC
{
    public partial class FAC_List : Page
    {
        private JavaScriptSerializer json;

        public FAC_List()
        {
            json = new JavaScriptSerializer();
            json.MaxJsonLength = int.MaxValue;
        }

        public class SearchFilterModel
        {
            public string Mode { get; set; }
            public string CNo { get; set; }
            public string FacName { get; set; }
            public string ScId { get; set; }
            public string Town { get; set; }
            public string Industrial { get; set; }
            public string FacGroup { get; set; }
            public string ProcessName { get; set; }
            public string ProcessLic { get; set; }
            public string FacType { get; set; }
            public int PageIndex { get; set; }
            public int PageSize { get; set; }

            public SearchFilterModel()
            {
                Mode = "read";
                CNo = "";
                FacName = "";
                ScId = "";
                Town = "";
                Industrial = "";
                FacGroup = "";
                ProcessName = "";
                ProcessLic = "";
                FacType = "";
                PageIndex = 1;
                PageSize = 15;
            }
        }

        public class SaveEditModel
        {
            public string FacId { get; set; }
            public string FacName { get; set; }
            public string CNo { get; set; }
            public string Addr { get; set; }
            public string Tel { get; set; }
            public string ScId { get; set; }
            public string ContentName { get; set; }

            public SaveEditModel()
            {
                FacId = "";
                FacName = "";
                CNo = "";
                Addr = "";
                Tel = "";
                ScId = "";
                ContentName = "";
            }
        }

        public class DispatchModel
        {
            public string Reason { get; set; }
            public List<string> FacIds { get; set; }

            public DispatchModel()
            {
                Reason = "";
                FacIds = new List<string>();
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

        protected override void Render(HtmlTextWriter writer)
        {
            // 若為 AJAX 請求則阻斷 Render 避免多餘 HTML 混入 JSON
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
                case "getlist":
                    GetList();
                    break;
                case "getnearby":
                    GetNearby();
                    break;
                case "getprocesses":
                    GetProcesses();
                    break;
                case "getfiles":
                    GetFiles();
                    break;
                case "uploadfile":
                    UploadFile();
                    break;
                case "delfile":
                    DeleteFile();
                    break;
                case "gethistory":
                    GetHistory();
                    break;
                case "saveedit":
                    SaveEdit();
                    break;
                case "addfac":
                    AddFac();
                    break;
                case "dispatchmission":
                    DispatchMission();
                    break;
                default:
                    Response.Write(json.Serialize(new { Success = false, Message = "未知的操作指令：" + action }));
                    break;
            }
        }

        #region 1. 取得各模式案件統計指標
        private void GetCounts()
        {
            int countTotal = 0;
            int countRegulated = 0;
            int countUnregulated = 0;
            int countDispatched = 0;
            int countUpdatedThisMonth = 0;

            try
            {
                // 計算總場所與列管/非列管數
                string sqlCounts = @"
                    SELECT 
                        COUNT(1) AS TotalCount,
                        ISNULL(SUM(CASE WHEN RTRIM(LTRIM(ISNULL(FAC_Type,''))) = '列管' THEN 1 ELSE 0 END), 0) AS RegulatedCount,
                        ISNULL(SUM(CASE WHEN RTRIM(LTRIM(ISNULL(FAC_Type,''))) <> '列管' THEN 1 ELSE 0 END), 0) AS UnregulatedCount
                    FROM FAC_Main";

                DataTable dtCounts = DbHelper.ExecuteDataTable(sqlCounts);
                if (dtCounts != null && dtCounts.Rows.Count > 0)
                {
                    countTotal = Convert.ToInt32(dtCounts.Rows[0]["TotalCount"]);
                    countRegulated = Convert.ToInt32(dtCounts.Rows[0]["RegulatedCount"]);
                    countUnregulated = Convert.ToInt32(dtCounts.Rows[0]["UnregulatedCount"]);
                }

                // 計算有效派遣數
                string sqlMission = "SELECT COUNT(1) FROM INV_Mission WHERE Cancel_Date IS NULL";
                object missionObj = DbHelper.ExecuteScalar(sqlMission);
                if (missionObj != null && missionObj != DBNull.Value)
                {
                    countDispatched = Convert.ToInt32(missionObj);
                }

                // 計算本月異動紀錄數
                string sqlHisMonth = @"
                    SELECT COUNT(1) 
                    FROM FAC_EditHis 
                    WHERE Edit_Date >= DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0)";
                object hisObj = DbHelper.ExecuteScalar(sqlHisMonth);
                if (hisObj != null && hisObj != DBNull.Value)
                {
                    countUpdatedThisMonth = Convert.ToInt32(hisObj);
                }
            }
            catch
            {
                // 容錯防禦
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                Counts = new
                {
                    Total = countTotal,
                    Regulated = countRegulated,
                    Unregulated = countUnregulated,
                    Dispatched = countDispatched,
                    UpdatedThisMonth = countUpdatedThisMonth
                }
            }));
        }
        #endregion

        #region 2. 複合多條件篩選與分頁查詢
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

            DataTable dt = null;
            bool spExecuted = false;

            // 優先嘗試預存程序 Get_New_FAC_Main_BySearch
            try
            {
                using (var conn = DbHelper.GetOpenConnection())
                using (var cmd = new SqlCommand("Get_New_FAC_Main_BySearch", conn))
                {
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.CommandTimeout = 120;

                    cmd.Parameters.AddWithValue("@Where_FAC_NAME", string.IsNullOrEmpty(filter.FacName) ? (object)DBNull.Value : filter.FacName);
                    cmd.Parameters.AddWithValue("@Where_C_NO", string.IsNullOrEmpty(filter.CNo) ? (object)DBNull.Value : filter.CNo);
                    cmd.Parameters.AddWithValue("@Where_S_C_ID", string.IsNullOrEmpty(filter.ScId) ? (object)DBNull.Value : filter.ScId);
                    cmd.Parameters.AddWithValue("@Where_Mac_State", DBNull.Value);
                    cmd.Parameters.AddWithValue("@Where_INV_State", DBNull.Value);
                    cmd.Parameters.AddWithValue("@Where_Show_IN_INV", DBNull.Value);
                    cmd.Parameters.AddWithValue("@Where_Reg_NO_Str", DBNull.Value);
                    cmd.Parameters.AddWithValue("@Where_TOWN", string.IsNullOrEmpty(filter.Town) ? (object)DBNull.Value : filter.Town);
                    cmd.Parameters.AddWithValue("@Where_FAC_Group", string.IsNullOrEmpty(filter.FacGroup) ? (object)DBNull.Value : filter.FacGroup);

                    using (var da = new SqlDataAdapter(cmd))
                    {
                        dt = new DataTable();
                        da.Fill(dt);
                        spExecuted = true;
                    }
                }
            }
            catch
            {
                spExecuted = false;
            }

            // 若預存程序失敗，改採安全參數化直接查詢
            if (!spExecuted || dt == null)
            {
                var sbSql = new StringBuilder();
                sbSql.Append("SELECT * FROM FAC_Main WHERE 1=1 ");
                var pList = new List<SqlParameter>();

                if (!string.IsNullOrEmpty(filter.CNo))
                {
                    sbSql.Append(" AND C_NO LIKE @C_NO ");
                    pList.Add(new SqlParameter("@C_NO", "%" + filter.CNo + "%"));
                }
                if (!string.IsNullOrEmpty(filter.FacName))
                {
                    sbSql.Append(" AND FAC_NAME LIKE @FAC_NAME ");
                    pList.Add(new SqlParameter("@FAC_NAME", "%" + filter.FacName + "%"));
                }
                if (!string.IsNullOrEmpty(filter.ScId))
                {
                    sbSql.Append(" AND S_C_ID LIKE @S_C_ID ");
                    pList.Add(new SqlParameter("@S_C_ID", "%" + filter.ScId + "%"));
                }
                if (!string.IsNullOrEmpty(filter.Town))
                {
                    sbSql.Append(" AND (TOWN LIKE @TOWN OR ADDR LIKE @TOWN) ");
                    pList.Add(new SqlParameter("@TOWN", "%" + filter.Town + "%"));
                }
                if (!string.IsNullOrEmpty(filter.FacGroup))
                {
                    sbSql.Append(" AND FAC_Group LIKE @FAC_Group ");
                    pList.Add(new SqlParameter("@FAC_Group", "%" + filter.FacGroup + "%"));
                }

                dt = DbHelper.ExecuteDataTable(sbSql.ToString(), pList.ToArray());
            }

            // 補充行業別 (INDUSTRIAL_Data)
            AttachIndustrialData(ref dt);

            // 行業別過濾 (若使用者在搜尋框指定)
            if (!string.IsNullOrEmpty(filter.Industrial) && dt != null && dt.Rows.Count > 0)
            {
                DataRow[] filteredRows = dt.Select(string.Format("Industrial LIKE '%{0}%'", filter.Industrial.Replace("'", "")));
                dt = RowsToDataTable(dt, filteredRows);
            }

            // 補充製程與許可證
            AttachProcessData(ref dt);

            // 製程名稱與許可證過濾
            if (!string.IsNullOrEmpty(filter.ProcessName) && dt != null && dt.Rows.Count > 0)
            {
                DataRow[] pRows = dt.Select(string.Format("Process_Name_List LIKE '%{0}%'", filter.ProcessName.Replace("'", "")));
                dt = RowsToDataTable(dt, pRows);
            }
            if (!string.IsNullOrEmpty(filter.ProcessLic) && dt != null && dt.Rows.Count > 0)
            {
                DataRow[] licRows = dt.Select(string.Format("Process_Lic_List LIKE '%{0}%'", filter.ProcessLic.Replace("'", "")));
                dt = RowsToDataTable(dt, licRows);
            }

            // 案件狀態過濾
            if (!string.IsNullOrEmpty(filter.FacType) && dt != null && dt.Rows.Count > 0 && dt.Columns.Contains("FAC_Type"))
            {
                DataRow[] typeRows = dt.Select(string.Format("FAC_Type LIKE '%{0}%'", filter.FacType.Replace("'", "")));
                dt = RowsToDataTable(dt, typeRows);
            }

            // 補充派遣紀錄 (INV_Mission)
            AttachMissionData(ref dt);

            // 根據模式過濾
            string mode = string.IsNullOrEmpty(filter.Mode) ? "read" : filter.Mode.ToLower();
            if (dt != null && dt.Rows.Count > 0)
            {
                if (mode == "read")
                {
                    // 列管場所
                    for (int i = dt.Rows.Count - 1; i >= 0; i--)
                    {
                        string fType = dt.Columns.Contains("FAC_Type") ? dt.Rows[i]["FAC_Type"].ToString().Trim() : "";
                        if (fType != "列管")
                        {
                            dt.Rows.RemoveAt(i);
                        }
                    }
                }
                else if (mode == "edit")
                {
                    // 非列管場所或待維護
                    for (int i = dt.Rows.Count - 1; i >= 0; i--)
                    {
                        string fType = dt.Columns.Contains("FAC_Type") ? dt.Rows[i]["FAC_Type"].ToString().Trim() : "";
                        if (fType == "列管")
                        {
                            dt.Rows.RemoveAt(i);
                        }
                    }
                }
            }

            int totalRows = (dt != null) ? dt.Rows.Count : 0;
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

                    string facId = r["FAC_ID"].ToString();
                    item["FAC_ID"] = facId;
                    item["FAC_NAME"] = r.Table.Columns.Contains("FAC_NAME") ? r["FAC_NAME"].ToString() : "";
                    item["C_NO"] = r.Table.Columns.Contains("C_NO") ? r["C_NO"].ToString() : "";
                    item["S_C_ID"] = r.Table.Columns.Contains("S_C_ID") ? r["S_C_ID"].ToString() : "";
                    item["TOWN"] = r.Table.Columns.Contains("TOWN") ? r["TOWN"].ToString() : "";
                    item["ADDR"] = r.Table.Columns.Contains("ADDR") ? r["ADDR"].ToString() : "";
                    item["TEL"] = r.Table.Columns.Contains("TEL") ? r["TEL"].ToString() : "";
                    item["Content_Name"] = r.Table.Columns.Contains("Content_Name") ? r["Content_Name"].ToString() : "";
                    item["FAC_Group"] = r.Table.Columns.Contains("FAC_Group") ? r["FAC_Group"].ToString() : "";
                    item["FAC_Type"] = r.Table.Columns.Contains("FAC_Type") ? r["FAC_Type"].ToString() : "";
                    item["Industrial"] = r.Table.Columns.Contains("Industrial") ? r["Industrial"].ToString() : "-";
                    item["Mission"] = r.Table.Columns.Contains("Mission") ? r["Mission"].ToString() : "";
                    item["MissionDeadline"] = r.Table.Columns.Contains("MissionDeadline_Str") ? r["MissionDeadline_Str"].ToString() : "";
                    item["ProcessCount"] = r.Table.Columns.Contains("ProcessCount") ? r["ProcessCount"] : 0;
                    item["ProcessSummary"] = r.Table.Columns.Contains("ProcessSummary") ? r["ProcessSummary"].ToString() : "";
                    item["Process_Name_List"] = r.Table.Columns.Contains("Process_Name_List") ? r["Process_Name_List"].ToString() : "";
                    item["Process_Lic_List"] = r.Table.Columns.Contains("Process_Lic_List") ? r["Process_Lic_List"].ToString() : "";

                    // 經緯度座標轉換 (TWD97 -> WGS84)
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

                    item["X"] = x;
                    item["Y"] = y;
                    item["Lat"] = lat;
                    item["Lng"] = lng;

                    // 安全 MD5 簽名供前往 FAC_Detail.aspx
                    string md5 = GetMd5Hash(facId + DateTime.Today.ToString("yyyyMMdd"));
                    item["DetailUrl"] = string.Format("FAC_Detail.aspx?id1={0}&id2={1}", facId, md5);

                    // 開放資料連結
                    string cNoStr = item["C_NO"].ToString().Trim();
                    item["OpenDataUrl"] = string.IsNullOrEmpty(cNoStr) ? "" : "https://aodmis.moenv.gov.tw/opendata/#/lv/" + cNoStr + "/1";

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

        #region 3. 外勤 GPS 定位搜尋周邊場所
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
            bool spExecuted = false;

            try
            {
                using (var conn = DbHelper.GetOpenConnection())
                using (var cmd = new SqlCommand("Get_New_FAC_Main_ByCood", conn))
                {
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.CommandTimeout = 120;
                    cmd.Parameters.AddWithValue("@Where_X", (float)userX);
                    cmd.Parameters.AddWithValue("@Where_Y", (float)userY);
                    cmd.Parameters.AddWithValue("@Where_Show_IN_INV", DBNull.Value);

                    using (var da = new SqlDataAdapter(cmd))
                    {
                        dt = new DataTable();
                        da.Fill(dt);
                        spExecuted = true;
                    }
                }
            }
            catch
            {
                spExecuted = false;
            }

            if (!spExecuted || dt == null || dt.Rows.Count == 0)
            {
                // 回退直接以空間距離查詢半徑內場所
                string sqlFallback = @"
                    SELECT TOP 50 *, 
                        SQRT(SQUARE(ISNULL(TWD97_X, X) - @UserX) + SQUARE(ISNULL(TWD97_Y, Y) - @UserY)) AS DistMeters
                    FROM FAC_Main 
                    WHERE (TWD97_X > 0 OR X > 0)
                    ORDER BY DistMeters ASC";

                dt = DbHelper.ExecuteDataTable(sqlFallback, 
                    new SqlParameter("@UserX", userX),
                    new SqlParameter("@UserY", userY));
            }

            AttachIndustrialData(ref dt);
            AttachProcessData(ref dt);

            var items = new List<Dictionary<string, object>>();
            if (dt != null)
            {
                int count = Math.Min(dt.Rows.Count, 30);
                for (int i = 0; i < count; i++)
                {
                    DataRow r = dt.Rows[i];
                    var item = new Dictionary<string, object>();
                    string facId = r["FAC_ID"].ToString();
                    item["FAC_ID"] = facId;
                    item["FAC_NAME"] = r.Table.Columns.Contains("FAC_NAME") ? r["FAC_NAME"].ToString() : "";
                    item["C_NO"] = r.Table.Columns.Contains("C_NO") ? r["C_NO"].ToString() : "";
                    item["TOWN"] = r.Table.Columns.Contains("TOWN") ? r["TOWN"].ToString() : "";
                    item["ADDR"] = r.Table.Columns.Contains("ADDR") ? r["ADDR"].ToString() : "";
                    item["Industrial"] = r.Table.Columns.Contains("Industrial") ? r["Industrial"].ToString() : "-";

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

                    // 計算與使用者距離 (公尺)
                    double dist = Math.Sqrt(Math.Pow(x - userX, 2) + Math.Pow(y - userY, 2));
                    item["DistanceMeters"] = Math.Round(dist);

                    string md5 = GetMd5Hash(facId + DateTime.Today.ToString("yyyyMMdd"));
                    item["DetailUrl"] = string.Format("FAC_Detail.aspx?id1={0}&id2={1}", facId, md5);

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

        #region 4. 取得指定場所製程清單
        private void GetProcesses()
        {
            string facId = Request["facId"];
            if (string.IsNullOrEmpty(facId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "未提供場所編號" }));
                return;
            }

            string sql = @"
                SELECT DISTINCT 
                    Process_NO, Process_Name, Process_Type, Process_Lic, Lic_Year
                FROM INV_Process_Main
                WHERE FAC_ID = @FAC_ID
                ORDER BY Process_NO";

            DataTable dt = DbHelper.ExecuteDataTable(sql, new SqlParameter("@FAC_ID", facId));
            var list = new List<Dictionary<string, object>>();
            if (dt != null)
            {
                foreach (DataRow r in dt.Rows)
                {
                    var item = new Dictionary<string, object>();
                    item["Process_NO"] = r["Process_NO"].ToString();
                    item["Process_Name"] = r["Process_Name"].ToString();
                    item["Process_Type"] = r["Process_Type"].ToString();
                    item["Process_Lic"] = r["Process_Lic"].ToString();
                    item["Lic_Year"] = r["Lic_Year"].ToString();
                    list.Add(item);
                }
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                Processes = list
            }));
        }
        #endregion

        #region 5. 取得場所圖資檔案清單
        private void GetFiles()
        {
            string facId = Request["facId"];
            if (string.IsNullOrEmpty(facId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "未提供場所編號" }));
                return;
            }

            // 查出 C_NO
            string sqlFac = "SELECT C_NO, FAC_NAME FROM FAC_Main WHERE FAC_ID = @FAC_ID";
            DataTable dtFac = DbHelper.ExecuteDataTable(sqlFac, new SqlParameter("@FAC_ID", facId));
            if (dtFac == null || dtFac.Rows.Count == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "查無此場所資料" }));
                return;
            }

            string cNo = dtFac.Rows[0]["C_NO"].ToString().Trim();
            string facName = dtFac.Rows[0]["FAC_NAME"].ToString().Trim();

            // 取得該場所在 FAC_File 的記錄
            string sqlFiles = @"
                SELECT ff.*, ua.Name AS UploadUserName
                FROM FAC_File ff
                LEFT JOIN UserAcc ua ON ff.UploadUser = ua.UserID
                WHERE ff.FAC_ID = @FAC_ID AND (ff.isDel IS NULL OR ff.isDel <> 'Y')
                ORDER BY ff.UploadDate DESC";

            DataTable dtFiles = DbHelper.ExecuteDataTable(sqlFiles, new SqlParameter("@FAC_ID", facId));
            var fileList = new List<Dictionary<string, object>>();

            if (dtFiles != null)
            {
                foreach (DataRow r in dtFiles.Rows)
                {
                    var item = new Dictionary<string, object>();
                    string fName = r["File_Name"].ToString();
                    item["FileName"] = fName;
                    item["Process_NO"] = r.Table.Columns.Contains("Process_NO") ? r["Process_NO"].ToString() : "";
                    item["File_Type"] = r.Table.Columns.Contains("File_Type") ? r["File_Type"].ToString() : "";
                    item["UploadDate"] = (r["UploadDate"] != DBNull.Value) ? Convert.ToDateTime(r["UploadDate"]).ToString("yyyy-MM-dd HH:mm") : "";
                    item["UploadUserName"] = r["UploadUserName"].ToString();
                    item["FileUrl"] = string.Format("../Upload/FAC/{0}/{1}", cNo, fName);
                    fileList.Add(item);
                }
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                C_NO = cNo,
                FAC_NAME = facName,
                Files = fileList
            }));
        }
        #endregion

        #region 6. 圖資檔案上傳
        private void UploadFile()
        {
            string facId = Request["facId"];
            string processNo = Request["processNo"];
            string fileType = Request["fileType"];

            if (string.IsNullOrEmpty(facId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "未提供場所編號" }));
                return;
            }

            if (Request.Files.Count == 0 || Request.Files[0].ContentLength == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "請選擇要上傳的圖資檔案" }));
                return;
            }

            HttpPostedFile postedFile = Request.Files[0];
            string origExt = Path.GetExtension(postedFile.FileName).ToLower();
            string[] allowedExts = new string[] { ".jpg", ".jpeg", ".png", ".pdf", ".dwg", ".bmp" };
            bool isAllowed = false;
            foreach (string ext in allowedExts)
            {
                if (ext == origExt) { isAllowed = true; break; }
            }
            if (!isAllowed)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "僅支援 JPG, PNG, PDF, DWG 等圖資格式檔案！" }));
                return;
            }

            string sqlFac = "SELECT C_NO, FAC_NAME FROM FAC_Main WHERE FAC_ID = @FAC_ID";
            DataTable dtFac = DbHelper.ExecuteDataTable(sqlFac, new SqlParameter("@FAC_ID", facId));
            if (dtFac == null || dtFac.Rows.Count == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "查無場所資料" }));
                return;
            }

            string cNo = dtFac.Rows[0]["C_NO"].ToString().Trim();
            string saveDir = Server.MapPath("~/Upload/FAC/" + cNo);
            if (!Directory.Exists(saveDir))
            {
                Directory.CreateDirectory(saveDir);
            }

            string cleanProc = string.IsNullOrEmpty(processNo) ? "全廠" : processNo.Trim();
            string cleanType = string.IsNullOrEmpty(fileType) ? "廠區配置圖" : fileType.Trim();
            string newFileName = string.Format("{0}-{1}-{2}{3}", cNo, cleanProc, cleanType, origExt);
            string fullPath = Path.Combine(saveDir, newFileName);

            // 若已有同名舊檔，自動備份轉存並標記
            if (File.Exists(fullPath))
            {
                string bakName = string.Format("舊{0:yyyyMMddHHmmss}_{1}", DateTime.Now, newFileName);
                string bakPath = Path.Combine(saveDir, bakName);
                File.Move(fullPath, bakPath);
            }

            postedFile.SaveAs(fullPath);

            // 寫入 FAC_File
            string sqlInsertFile = @"
                INSERT INTO FAC_File(FAC_ID, Process_NO, File_Type, File_Name, UploadDate, UploadUser, isDel)
                VALUES(@FAC_ID, @Process_NO, @File_Type, @File_Name, GETDATE(), @UploadUser, 'N')";

            DbHelper.ExecuteNonQuery(sqlInsertFile,
                new SqlParameter("@FAC_ID", facId),
                new SqlParameter("@Process_NO", cleanProc),
                new SqlParameter("@File_Type", cleanType),
                new SqlParameter("@File_Name", newFileName),
                new SqlParameter("@UploadUser", GetCurrentUser()));

            Response.Write(json.Serialize(new
            {
                Success = true,
                Message = "圖資檔案上傳成功！",
                FileName = newFileName
            }));
        }
        #endregion

        #region 7. 圖資檔案刪除 (安全邏輯刪除)
        private void DeleteFile()
        {
            string facId = Request["facId"];
            string fileName = Request["fileName"];

            if (string.IsNullOrEmpty(facId) || string.IsNullOrEmpty(fileName))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "參數不完整" }));
                return;
            }

            string sqlFac = "SELECT C_NO FROM FAC_Main WHERE FAC_ID = @FAC_ID";
            object cNoObj = DbHelper.ExecuteScalar(sqlFac, new SqlParameter("@FAC_ID", facId));
            if (cNoObj == null)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "查無場所資料" }));
                return;
            }

            string cNo = cNoObj.ToString().Trim();
            string dirPath = Server.MapPath("~/Upload/FAC/" + cNo);
            string filePath = Path.Combine(dirPath, fileName);

            string delNewName = string.Format("刪{0:yyyyMMddHHmmss}_{1}", DateTime.Now, fileName);
            if (File.Exists(filePath))
            {
                string delPath = Path.Combine(dirPath, delNewName);
                File.Move(filePath, delPath);
            }

            string sqlUpdate = @"
                UPDATE FAC_File 
                SET isDel = 'Y', DelDate = GETDATE(), DelUser = @DelUser, File_Name = @DelNewName
                WHERE FAC_ID = @FAC_ID AND File_Name = @FileName";

            DbHelper.ExecuteNonQuery(sqlUpdate,
                new SqlParameter("@DelUser", GetCurrentUser()),
                new SqlParameter("@DelNewName", delNewName),
                new SqlParameter("@FAC_ID", facId),
                new SqlParameter("@FileName", fileName));

            Response.Write(json.Serialize(new
            {
                Success = true,
                Message = "檔案已成功刪除！"
            }));
        }
        #endregion

        #region 8. 取得場所異動歷程
        private void GetHistory()
        {
            string facId = Request["facId"];
            if (string.IsNullOrEmpty(facId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "未提供場所編號" }));
                return;
            }

            string sql = @"
                SELECT 
                    ROW_NUMBER() OVER(ORDER BY fe.Edit_Date DESC) AS Row_Index,
                    fe.*, 
                    ua.Name AS Edit_UserName 
                FROM FAC_EditHis fe
                LEFT JOIN UserAcc ua ON fe.Edit_User = ua.UserID
                WHERE fe.FAC_ID = @FAC_ID
                ORDER BY fe.Edit_Date DESC";

            DataTable dt = DbHelper.ExecuteDataTable(sql, new SqlParameter("@FAC_ID", facId));
            var historyList = new List<Dictionary<string, object>>();

            if (dt != null)
            {
                for (int i = 0; i < dt.Rows.Count; i++)
                {
                    DataRow r = dt.Rows[i];
                    var item = new Dictionary<string, object>();
                    item["Row_Index"] = i + 1;
                    item["Edit_Date"] = (r["Edit_Date"] != DBNull.Value) ? Convert.ToDateTime(r["Edit_Date"]).ToString("yyyy-MM-dd HH:mm") : "";
                    item["Edit_User"] = r["Edit_UserName"].ToString();
                    if (string.IsNullOrEmpty(item["Edit_User"].ToString()))
                    {
                        item["Edit_User"] = r["Edit_User"].ToString();
                    }

                    // 整理變更內容明細
                    var changes = new List<Dictionary<string, string>>();
                    string[] colNames = new string[] { "FAC_NAME", "C_NO", "ADDR", "TEL", "S_C_ID", "Content_Name" };
                    string[] colLabels = new string[] { "場所名稱", "管制編號", "地址", "電話", "統一編號", "聯絡人" };

                    for (int c = 0; c < colNames.Length; c++)
                    {
                        string cName = colNames[c];
                        if (dt.Columns.Contains(cName) && r[cName] != DBNull.Value && !string.IsNullOrEmpty(r[cName].ToString()))
                        {
                            string newVal = r[cName].ToString();
                            string oldVal = "-";

                            // 從下一筆 (較舊紀錄) 取得舊值
                            if (i < dt.Rows.Count - 1 && dt.Rows[i + 1].Table.Columns.Contains(cName) && dt.Rows[i + 1][cName] != DBNull.Value)
                            {
                                oldVal = dt.Rows[i + 1][cName].ToString();
                            }

                            var changeItem = new Dictionary<string, string>();
                            changeItem["Field"] = colLabels[c];
                            changeItem["OldValue"] = oldVal;
                            changeItem["NewValue"] = newVal;
                            changes.Add(changeItem);
                        }
                    }

                    item["Changes"] = changes;
                    historyList.Add(item);
                }
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                History = historyList
            }));
        }
        #endregion

        #region 9. 儲存場所基本資料異動
        private void SaveEdit()
        {
            string reqJson = "";
            using (var reader = new StreamReader(Request.InputStream, Encoding.UTF8))
            {
                reqJson = reader.ReadToEnd();
            }

            SaveEditModel model = null;
            if (!string.IsNullOrEmpty(reqJson))
            {
                model = json.Deserialize<SaveEditModel>(reqJson);
            }

            if (model == null || string.IsNullOrEmpty(model.FacId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "未提供有效異動資料" }));
                return;
            }

            // 更新 FAC_Main
            string sqlUpdate = @"
                UPDATE FAC_Main
                SET 
                    FAC_NAME = @FAC_NAME,
                    C_NO = @C_NO,
                    ADDR = @ADDR,
                    TEL = @TEL,
                    S_C_ID = @S_C_ID,
                    Content_Name = @Content_Name
                WHERE FAC_ID = @FAC_ID";

            DbHelper.ExecuteNonQuery(sqlUpdate,
                new SqlParameter("@FAC_NAME", model.FacName ?? ""),
                new SqlParameter("@C_NO", model.CNo ?? ""),
                new SqlParameter("@ADDR", model.Addr ?? ""),
                new SqlParameter("@TEL", model.Tel ?? ""),
                new SqlParameter("@S_C_ID", model.ScId ?? ""),
                new SqlParameter("@Content_Name", model.ContentName ?? ""),
                new SqlParameter("@FAC_ID", model.FacId));

            // 寫入 FAC_EditHis
            string sqlInsertHis = @"
                INSERT INTO FAC_EditHis(FAC_ID, FAC_NAME, C_NO, ADDR, TEL, S_C_ID, Content_Name, Edit_User, Edit_Date)
                VALUES(@FAC_ID, @FAC_NAME, @C_NO, @ADDR, @TEL, @S_C_ID, @Content_Name, @Edit_User, GETDATE())";

            DbHelper.ExecuteNonQuery(sqlInsertHis,
                new SqlParameter("@FAC_ID", model.FacId),
                new SqlParameter("@FAC_NAME", model.FacName ?? ""),
                new SqlParameter("@C_NO", model.CNo ?? ""),
                new SqlParameter("@ADDR", model.Addr ?? ""),
                new SqlParameter("@TEL", model.Tel ?? ""),
                new SqlParameter("@S_C_ID", model.ScId ?? ""),
                new SqlParameter("@Content_Name", model.ContentName ?? ""),
                new SqlParameter("@Edit_User", GetCurrentUser()));

            Response.Write(json.Serialize(new
            {
                Success = true,
                Message = "場所資料異動已儲存成功！"
            }));
        }
        #endregion

        #region 10. 新增場所
        private void AddFac()
        {
            string prefix = "F" + DateTime.Today.ToString("yyyyMMdd");
            string sqlMax = "SELECT TOP 1 FAC_ID FROM FAC_Main WHERE FAC_ID LIKE @Prefix + '%' ORDER BY FAC_ID DESC";
            object maxObj = DbHelper.ExecuteScalar(sqlMax, new SqlParameter("@Prefix", prefix));

            int nextNum = 1;
            if (maxObj != null && !string.IsNullOrEmpty(maxObj.ToString()))
            {
                string maxStr = maxObj.ToString();
                if (maxStr.Length > 9)
                {
                    int.TryParse(maxStr.Substring(9), out nextNum);
                    nextNum++;
                }
            }

            string newFacId = prefix + nextNum.ToString("00000");
            string currentUser = GetCurrentUser();

            // 插入 FAC_Main
            string sqlInsertFac = @"
                INSERT INTO FAC_Main(FAC_ID, FAC_NAME, FAC_Type)
                VALUES(@FAC_ID, '新增場所', '非列管')";
            DbHelper.ExecuteNonQuery(sqlInsertFac, new SqlParameter("@FAC_ID", newFacId));

            // 插入 FAC_EditHis
            string sqlInsertHis = @"
                INSERT INTO FAC_EditHis(FAC_ID, FAC_NAME, Edit_User, Edit_Date)
                VALUES(@FAC_ID, '新增場所', @Edit_User, GETDATE())";
            DbHelper.ExecuteNonQuery(sqlInsertHis, 
                new SqlParameter("@FAC_ID", newFacId),
                new SqlParameter("@Edit_User", currentUser));

            Response.Write(json.Serialize(new
            {
                Success = true,
                Message = "新場所已成功建立！",
                FacId = newFacId
            }));
        }
        #endregion

        #region 11. 批次指派案件至 INV_Mission
        private void DispatchMission()
        {
            string reqJson = "";
            using (var reader = new StreamReader(Request.InputStream, Encoding.UTF8))
            {
                reqJson = reader.ReadToEnd();
            }

            DispatchModel model = null;
            if (!string.IsNullOrEmpty(reqJson))
            {
                model = json.Deserialize<DispatchModel>(reqJson);
            }

            if (model == null || model.FacIds == null || model.FacIds.Count == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "未勾選任何待派遣場所" }));
                return;
            }

            string reason = string.IsNullOrEmpty(model.Reason) ? "一般派遣" : model.Reason;
            string user = GetCurrentUser();
            int countSuccess = 0;

            string sqlInsert = @"
                INSERT INTO INV_Mission(FAC_ID, SendDate, SendUser, pReason)
                VALUES(@FAC_ID, GETDATE(), @SendUser, @pReason)";

            foreach (string fid in model.FacIds)
            {
                if (!string.IsNullOrEmpty(fid))
                {
                    DbHelper.ExecuteNonQuery(sqlInsert,
                        new SqlParameter("@FAC_ID", fid),
                        new SqlParameter("@SendUser", user),
                        new SqlParameter("@pReason", reason));
                    countSuccess++;
                }
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                Message = string.Format("成功為 {0} 個場所完成派遣指派！", countSuccess)
            }));
        }
        #endregion

        #region 輔助函式：行業別、製程與派遣關聯補充
        private static DataTable RowsToDataTable(DataTable sourceTable, DataRow[] rows)
        {
            DataTable dt = sourceTable.Clone();
            if (rows != null && rows.Length > 0)
            {
                for (int i = 0; i < rows.Length; i++)
                {
                    dt.ImportRow(rows[i]);
                }
            }
            return dt;
        }

        private void AttachIndustrialData(ref DataTable dt)
        {
            if (dt == null) return;
            if (!dt.Columns.Contains("Industrial"))
            {
                dt.Columns.Add("Industrial", typeof(string));
            }

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
                        if (!dict.ContainsKey(code))
                        {
                            dict.Add(code, name);
                        }
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
            catch
            {
            }
        }

        private void AttachProcessData(ref DataTable dt)
        {
            if (dt == null) return;
            if (!dt.Columns.Contains("ProcessCount")) dt.Columns.Add("ProcessCount", typeof(int));
            if (!dt.Columns.Contains("ProcessSummary")) dt.Columns.Add("ProcessSummary", typeof(string));
            if (!dt.Columns.Contains("Process_Name_List")) dt.Columns.Add("Process_Name_List", typeof(string));
            if (!dt.Columns.Contains("Process_Lic_List")) dt.Columns.Add("Process_Lic_List", typeof(string));

            try
            {
                string sqlProc = "SELECT DISTINCT FAC_ID, Process_NO, Process_Name, Process_Type, Process_Lic, Lic_Year FROM INV_Process_Main";
                DataTable dtProc = DbHelper.ExecuteDataTable(sqlProc);

                if (dtProc != null && dtProc.Rows.Count > 0)
                {
                    var facProcMap = new Dictionary<string, List<DataRow>>();
                    foreach (DataRow pr in dtProc.Rows)
                    {
                        string fid = pr["FAC_ID"].ToString().Trim();
                        if (!facProcMap.ContainsKey(fid))
                        {
                            facProcMap.Add(fid, new List<DataRow>());
                        }
                        facProcMap[fid].Add(pr);
                    }

                    foreach (DataRow r in dt.Rows)
                    {
                        string fid = r["FAC_ID"].ToString().Trim();
                        if (facProcMap.ContainsKey(fid))
                        {
                            List<DataRow> procs = facProcMap[fid];
                            r["ProcessCount"] = procs.Count;

                            var names = new StringBuilder();
                            var lics = new StringBuilder();
                            var summary = new StringBuilder();

                            for (int p = 0; p < procs.Count; p++)
                            {
                                string pNo = procs[p]["Process_NO"].ToString();
                                string pName = procs[p]["Process_Name"].ToString();
                                string pType = procs[p]["Process_Type"].ToString();
                                string pLic = procs[p]["Process_Lic"].ToString();

                                if (p > 0)
                                {
                                    names.Append("; ");
                                    lics.Append("; ");
                                    summary.Append(" | ");
                                }
                                names.Append(pName);
                                lics.Append(pLic);
                                summary.Append(string.Format("[{0}] {1} ({2})", pNo, pName, pLic));
                            }

                            r["Process_Name_List"] = names.ToString();
                            r["Process_Lic_List"] = lics.ToString();
                            r["ProcessSummary"] = summary.ToString();
                        }
                        else
                        {
                            r["ProcessCount"] = 0;
                            r["ProcessSummary"] = "無登記製程";
                            r["Process_Name_List"] = "";
                            r["Process_Lic_List"] = "";
                        }
                    }
                }
            }
            catch
            {
            }
        }

        private void AttachMissionData(ref DataTable dt)
        {
            if (dt == null) return;
            if (!dt.Columns.Contains("Mission")) dt.Columns.Add("Mission", typeof(string));
            if (!dt.Columns.Contains("MissionDeadline_Str")) dt.Columns.Add("MissionDeadline_Str", typeof(string));

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
                        if (!misMap.ContainsKey(fid))
                        {
                            misMap.Add(fid, mr);
                        }
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
                                if (pReason == "7天內未完成改善回報" || pReason == "稽查列管" || pReason == "稽查列管注意案件")
                                {
                                    r["MissionDeadline_Str"] = string.Format("巡(稽)查期限: {0:yyyy-MM-dd}", sDate.AddDays(30.0));
                                }
                            }
                        }
                    }
                }
            }
            catch
            {
            }
        }
        #endregion

        #region 高精度 TWD97 與 WGS84 座標互相轉換 (C# 5.0 演算法規範)
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

        private static string GetMd5Hash(string input)
        {
            if (string.IsNullOrEmpty(input)) return "";
            using (MD5 md5 = MD5.Create())
            {
                byte[] data = md5.ComputeHash(Encoding.UTF8.GetBytes(input));
                var sBuilder = new StringBuilder();
                for (int i = 0; i < data.Length; i++)
                {
                    sBuilder.Append(data[i].ToString("x2"));
                }
                return sBuilder.ToString();
            }
        }
        #endregion

        #region 匯出 Excel 報表
        private void HandleExportExcel()
        {
            try
            {
                string mode = Request["mode"] != null ? Request["mode"].Trim().ToLower() : "read";
                string cNo = Request["cNo"] != null ? Request["cNo"].Trim() : "";
                string facName = Request["facName"] != null ? Request["facName"].Trim() : "";
                string scId = Request["scId"] != null ? Request["scId"].Trim() : "";
                string town = Request["town"] != null ? Request["town"].Trim() : "";
                string industrial = Request["industrial"] != null ? Request["industrial"].Trim() : "";
                string facType = Request["facType"] != null ? Request["facType"].Trim() : "";

                StringBuilder sb = new StringBuilder();
                sb.Append("SELECT m.FAC_ID, m.C_NO, m.FAC_NAME, m.S_C_ID, m.TOWN, m.ADDR, m.Industrial, m.FAC_Type, m.TEL, m.Lat, m.Lng ");
                sb.Append("FROM FAC_Main m WHERE 1=1 ");

                List<SqlParameter> pList = new List<SqlParameter>();

                if (mode == "edit")
                {
                    sb.Append(" AND (m.FAC_Type IS NULL OR RTRIM(LTRIM(m.FAC_Type)) <> '列管') ");
                }

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
                if (!string.IsNullOrEmpty(industrial))
                {
                    sb.Append(" AND m.Industrial LIKE @Industrial ");
                    pList.Add(new SqlParameter("@Industrial", "%" + industrial + "%"));
                }
                if (!string.IsNullOrEmpty(facType))
                {
                    sb.Append(" AND m.FAC_Type LIKE @FAC_Type ");
                    pList.Add(new SqlParameter("@FAC_Type", "%" + facType + "%"));
                }

                sb.Append(" ORDER BY m.C_NO ASC, m.FAC_ID ASC");

                DataTable dt = DbHelper.ExecuteDataTable(sb.ToString(), pList.ToArray());

                HSSFWorkbook workbook = new HSSFWorkbook();
                ISheet sheet = workbook.CreateSheet("固定源場所清單");

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
                    "序號", "管制編號", "場所內部編號", "公私場所名稱", "統一編號",
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
                        string facIdVal = dr["FAC_ID"] != DBNull.Value ? dr["FAC_ID"].ToString().Trim() : "";
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
                            seq, cNoVal, facIdVal, nameVal, scIdVal,
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

                sheet.SetColumnWidth(0, 8 * 256);
                sheet.SetColumnWidth(1, 16 * 256);
                sheet.SetColumnWidth(2, 16 * 256);
                sheet.SetColumnWidth(3, 30 * 256);
                sheet.SetColumnWidth(4, 14 * 256);
                sheet.SetColumnWidth(5, 12 * 256);
                sheet.SetColumnWidth(6, 36 * 256);
                sheet.SetColumnWidth(7, 24 * 256);
                sheet.SetColumnWidth(8, 12 * 256);
                sheet.SetColumnWidth(9, 16 * 256);
                sheet.SetColumnWidth(10, 14 * 256);
                sheet.SetColumnWidth(11, 14 * 256);

                Response.Clear();
                Response.ContentType = "application/vnd.ms-excel";
                string filename = "固定源場所清單_" + DateTime.Now.ToString("yyyyMMddHHmmss") + ".xls";
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
