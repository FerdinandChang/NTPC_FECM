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

namespace NTPC_FEC.FAC
{
    public partial class FAC_Detail : Page
    {
        private JavaScriptSerializer json;

        public FAC_Detail()
        {
            json = new JavaScriptSerializer();
            json.MaxJsonLength = int.MaxValue;
        }

        public class BasicSaveModel
        {
            public string FacId { get; set; }
            public string FacName { get; set; }
            public string Addr { get; set; }
            public string Tel { get; set; }
            public string ContentName { get; set; }
            public string WorkMemo { get; set; }

            public BasicSaveModel()
            {
                FacId = "";
                FacName = "";
                Addr = "";
                Tel = "";
                ContentName = "";
                WorkMemo = "";
            }
        }

        public class FileItemModel
        {
            public string FileName { get; set; }
            public string FileUrl { get; set; }
            public string FileExt { get; set; }
            public string Category { get; set; }
            public string FileSizeStr { get; set; }
            public bool IsImage { get; set; }
            public bool IsPdf { get; set; }
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
                catch (Exception ex)
                {
                    Response.Write(json.Serialize(new
                    {
                        Success = false,
                        Message = "系統發生錯誤：" + ex.Message
                    }));
                }
                Response.End();
                return;
            }
        }

        private void HandleAjaxAction(string action)
        {
            string act = action.ToLower();
            if (act == "getdetail")
            {
                GetDetail();
            }
            else if (act == "savebasic")
            {
                SaveBasic();
            }
            else
            {
                Response.Write(json.Serialize(new { Success = false, Message = "未知的操作指令：" + action }));
            }
        }

        #region 1. 取得場所詳情資料 (GetDetail)
        private void GetDetail()
        {
            string facId = Request["id1"];
            if (string.IsNullOrEmpty(facId)) facId = Request["id"];
            if (string.IsNullOrEmpty(facId)) facId = Request["facId"];
            if (facId != null) facId = facId.Trim();

            if (string.IsNullOrEmpty(facId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "未提供場所代碼參數 (id1/id/facId)" }));
                return;
            }

            // 安全校驗碼 Token 檢驗 (相容 id2, chk, token)
            string token = Request["id2"];
            if (string.IsNullOrEmpty(token)) token = Request["chk"];
            if (string.IsNullOrEmpty(token)) token = Request["token"];

            if (!string.IsNullOrEmpty(token))
            {
                string todayStr = DateTime.Now.ToString("yyyyMMdd");
                string yesterdayStr = DateTime.Now.AddDays(-1).ToString("yyyyMMdd");
                string expectedToday = GetMd5Hash(facId + todayStr);
                string expectedYesterday = GetMd5Hash(facId + yesterdayStr);

                if (!string.Equals(token, expectedToday, StringComparison.OrdinalIgnoreCase) &&
                    !string.Equals(token, expectedYesterday, StringComparison.OrdinalIgnoreCase))
                {
                    // 若 Session 中已登入有效用戶則允許通行
                    if (Session["LoginUser"] == null && (User == null || User.Identity == null || !User.Identity.IsAuthenticated))
                    {
                        Response.Write(json.Serialize(new { Success = false, Message = "安全校驗碼無效或已過期，請由場所清單重新開啟。" }));
                        return;
                    }
                }
            }

            // 1. 查詢場所基本主檔 (使用 m.* 杜絕特定未定義欄位報錯)
            string sqlMain = @"
                SELECT 
                    m.*,
                    t.TOWN_NA AS TownName,
                    ISNULL(ind.INDUSTRIAL_Name, '') + (CASE WHEN ind.INDUSTRIAL_Code IS NOT NULL THEN '(' + ind.INDUSTRIAL_Code + ')' ELSE '' END) AS IndustrialName
                FROM FAC_Main m
                LEFT JOIN C_TOWN t ON m.TOWN_CODE = t.TOWN_NO
                LEFT JOIN INDUSTRIAL_Data ind ON m.INDUSTRIAL_Code1 = ind.INDUSTRIAL_Code
                WHERE m.FAC_ID = @FAC_ID";

            DataTable dtMain = DbHelper.ExecuteDataTable(sqlMain, new SqlParameter("@FAC_ID", facId));
            if (dtMain == null || dtMain.Rows.Count == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "查無此固定源場所資料 (" + facId + ")" }));
                return;
            }

            DataRow row = dtMain.Rows[0];
            Dictionary<string, object> mainData = new Dictionary<string, object>();
            foreach (DataColumn col in dtMain.Columns)
            {
                mainData[col.ColumnName] = row[col] == DBNull.Value ? "" : row[col].ToString().Trim();
            }

            // 格式化管理辦法適用
            string regNoStr = mainData.ContainsKey("Reg_NO_Str") ? mainData["Reg_NO_Str"].ToString() : "";
            string regNo = mainData.ContainsKey("Reg_NO") ? mainData["Reg_NO"].ToString() : "";
            if (!string.IsNullOrEmpty(regNo))
            {
                mainData["RegDisplay"] = regNoStr + " (" + regNo + ")";
            }
            else
            {
                mainData["RegDisplay"] = regNoStr;
            }

            // 計算 WGS84 經緯度座標供 Leaflet 地圖展示
            double lat = 0.0;
            double lng = 0.0;
            double twdX = 0.0;
            double twdY = 0.0;

            if (row.Table.Columns.Contains("TWD97_X") && row["TWD97_X"] != DBNull.Value && double.TryParse(row["TWD97_X"].ToString(), out twdX) &&
                row.Table.Columns.Contains("TWD97_Y") && row["TWD97_Y"] != DBNull.Value && double.TryParse(row["TWD97_Y"].ToString(), out twdY) &&
                twdX > 100000 && twdY > 100000)
            {
                Twd97ToWgs84(twdX, twdY, out lat, out lng);
            }

            mainData["Lat"] = lat > 0 ? (object)Math.Round(lat, 6) : null;
            mainData["Lng"] = lng > 0 ? (object)Math.Round(lng, 6) : null;
            mainData["CoodDisplay"] = (twdX > 0 && twdY > 0) ? string.Format("{0:F0}, {1:F0}", twdX, twdY) : "無坐標資料";

            // 2. 設備與原物料 (INV_Device)
            List<Dictionary<string, object>> deviceList = new List<Dictionary<string, object>>();
            try
            {
                string sqlDevice = "SELECT * FROM INV_Device WHERE FAC_ID = @FAC_ID ORDER BY Device_NO";
                DataTable dtDevice = DbHelper.ExecuteDataTable(sqlDevice, new SqlParameter("@FAC_ID", facId));
                deviceList = DataTableToList(dtDevice);
            }
            catch { }

            // 3. 設備與製程 (INV_Device_Main JOIN INV_Process_Main)
            List<Dictionary<string, object>> processList = new List<Dictionary<string, object>>();
            try
            {
                string sqlProcess = @"
                    SELECT 
                        d.Device_NO,
                        d.Device_Code,
                        d.Device_Name,
                        d.Device_Type,
                        d.Process_NO,
                        p.Process_Code,
                        p.Process_Name,
                        p.Process_Type,
                        p.Process_Lic,
                        p.Lic_Year
                    FROM INV_Device_Main d
                    LEFT JOIN INV_Process_Main p ON d.FAC_ID = p.FAC_ID AND d.Process_NO = p.Process_NO
                    WHERE d.FAC_ID = @FAC_ID
                    ORDER BY d.Device_NO, d.Process_NO";
                DataTable dtProcess = DbHelper.ExecuteDataTable(sqlProcess, new SqlParameter("@FAC_ID", facId));
                processList = DataTableToList(dtProcess);
            }
            catch { }

            // 4. 防制設施 1 ~ 7
            Dictionary<string, List<Dictionary<string, object>>> prevents = new Dictionary<string, List<Dictionary<string, object>>>();
            for (int i = 1; i <= 7; i++)
            {
                string tblName = "FAC_Prevent_" + i.ToString();
                try
                {
                    string sqlPrev = "SELECT * FROM " + tblName + " WHERE FAC_ID = @FAC_ID";
                    DataTable dtPrev = DbHelper.ExecuteDataTable(sqlPrev, new SqlParameter("@FAC_ID", facId));
                    prevents["Prevent" + i.ToString()] = DataTableToList(dtPrev);
                }
                catch
                {
                    prevents["Prevent" + i.ToString()] = new List<Dictionary<string, object>>();
                }
            }

            // 5. 廠區配置圖與製程流程圖
            string cNo = mainData.ContainsKey("C_NO") ? mainData["C_NO"].ToString() : "";
            List<FileItemModel> fileList = GetFacilityFiles(cNo);

            // 6. 派工歷程 (INV_Mission)
            List<Dictionary<string, object>> missionList = new List<Dictionary<string, object>>();
            try
            {
                string sqlMission = @"
                    SELECT 
                        m.SendDate,
                        m.pReason,
                        m.Finish_INV_NO,
                        m.Cancel_Date
                    FROM INV_Mission m
                    WHERE m.FAC_ID = @FAC_ID
                    ORDER BY m.SendDate DESC";
                DataTable dtMission = DbHelper.ExecuteDataTable(sqlMission, new SqlParameter("@FAC_ID", facId));
                missionList = DataTableToList(dtMission);
            }
            catch { }

            // 7. 異動歷程 (FAC_EditHis)
            List<Dictionary<string, object>> historyList = new List<Dictionary<string, object>>();
            try
            {
                string sqlHistory = @"
                    SELECT 
                        fe.*,
                        ua.Name AS Edit_UserName
                    FROM FAC_EditHis fe
                    LEFT JOIN UserAcc ua ON fe.Edit_User = ua.UserID
                    WHERE fe.FAC_ID = @FAC_ID
                    ORDER BY fe.Edit_Date DESC";
                DataTable dtHistory = DbHelper.ExecuteDataTable(sqlHistory, new SqlParameter("@FAC_ID", facId));
                historyList = DataTableToList(dtHistory);
            }
            catch { }

            // 組合完整 JSON 回應
            Response.Write(json.Serialize(new
            {
                Success = true,
                Main = mainData,
                Devices = deviceList,
                Processes = processList,
                Prevents = prevents,
                Files = fileList,
                Missions = missionList,
                History = historyList
            }));
        }
        #endregion

        #region 2. 儲存基本資料 (SaveBasic)
        private void SaveBasic()
        {
            string body;
            using (var reader = new StreamReader(Request.InputStream, Encoding.UTF8))
            {
                body = reader.ReadToEnd();
            }

            if (string.IsNullOrEmpty(body))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "請求資料為空" }));
                return;
            }

            BasicSaveModel model = json.Deserialize<BasicSaveModel>(body);
            if (model == null || string.IsNullOrEmpty(model.FacId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "未指定場所代碼" }));
                return;
            }

            // 查出 C_NO
            string sqlFindCNo = "SELECT C_NO FROM FAC_Main WHERE FAC_ID = @FAC_ID";
            object cNoObj = DbHelper.ExecuteScalar(sqlFindCNo, new SqlParameter("@FAC_ID", model.FacId.Trim()));
            string currentCNo = cNoObj != null ? cNoObj.ToString().Trim() : "";

            string sqlUpdate = @"
                UPDATE FAC_Main
                SET 
                    FAC_NAME = @FacName,
                    ADDR = @Addr,
                    TEL = @Tel,
                    Content_Name = @ContentName,
                    Work_Memo = @WorkMemo
                WHERE FAC_ID = @FacId";

            int aff = DbHelper.ExecuteNonQuery(sqlUpdate,
                new SqlParameter("@FacName", (model.FacName ?? "").Trim()),
                new SqlParameter("@Addr", (model.Addr ?? "").Trim()),
                new SqlParameter("@Tel", (model.Tel ?? "").Trim()),
                new SqlParameter("@ContentName", (model.ContentName ?? "").Trim()),
                new SqlParameter("@WorkMemo", (model.WorkMemo ?? "").Trim()),
                new SqlParameter("@FacId", model.FacId.Trim()));

            if (aff > 0)
            {
                // 寫入異動歷程 (依據 FAC_EditHis 正確結構寫入)
                string loginUser = "";
                if (Session["LoginUser"] != null) loginUser = Session["LoginUser"].ToString();
                if (string.IsNullOrEmpty(loginUser) && User != null && User.Identity != null) loginUser = User.Identity.Name;
                if (string.IsNullOrEmpty(loginUser)) loginUser = "SYSTEM";

                try
                {
                    string sqlHis = @"
                        INSERT INTO FAC_EditHis (FAC_ID, FAC_NAME, C_NO, ADDR, TEL, Content_Name, Edit_User, Edit_Date)
                        VALUES (@FAC_ID, @FAC_NAME, @C_NO, @ADDR, @TEL, @Content_Name, @Edit_User, GETDATE())";

                    DbHelper.ExecuteNonQuery(sqlHis,
                        new SqlParameter("@FAC_ID", model.FacId.Trim()),
                        new SqlParameter("@FAC_NAME", (model.FacName ?? "").Trim()),
                        new SqlParameter("@C_NO", currentCNo),
                        new SqlParameter("@ADDR", (model.Addr ?? "").Trim()),
                        new SqlParameter("@TEL", (model.Tel ?? "").Trim()),
                        new SqlParameter("@Content_Name", (model.ContentName ?? "").Trim()),
                        new SqlParameter("@Edit_User", loginUser));
                }
                catch
                {
                    // 若歷史表記錄失敗不阻斷主更新成功狀態
                }

                Response.Write(json.Serialize(new { Success = true, Message = "場所基本資料已成功儲存更新！" }));
            }
            else
            {
                Response.Write(json.Serialize(new { Success = false, Message = "更新失敗，查無場所資料。" }));
            }
        }
        #endregion

        #region 3. 掃描伺服器實體圖檔與流程圖
        private List<FileItemModel> GetFacilityFiles(string cNo)
        {
            List<FileItemModel> list = new List<FileItemModel>();
            if (string.IsNullOrEmpty(cNo)) return list;

            try
            {
                string relPath = "~/Upload/FAC/" + cNo;
                string phyPath = HttpContext.Current.Server.MapPath(relPath);

                // 若虛擬路徑不在網站根目錄，相容嘗試 /NTPC_FEC/Upload/FAC/{cNo}
                if (!Directory.Exists(phyPath))
                {
                    string altPath = HttpContext.Current.Server.MapPath("/NTPC_FEC/Upload/FAC/" + cNo);
                    if (Directory.Exists(altPath))
                    {
                        phyPath = altPath;
                    }
                }

                if (Directory.Exists(phyPath))
                {
                    DirectoryInfo dir = new DirectoryInfo(phyPath);
                    FileInfo[] files = dir.GetFiles();
                    foreach (FileInfo fi in files)
                    {
                        FileItemModel item = new FileItemModel();
                        item.FileName = fi.Name;
                        item.FileExt = fi.Extension.ToLower();
                        item.FileSizeStr = FormatFileSize(fi.Length);
                        item.IsImage = (item.FileExt == ".jpg" || item.FileExt == ".jpeg" || item.FileExt == ".png" || item.FileExt == ".gif");
                        item.IsPdf = (item.FileExt == ".pdf");

                        // 判斷分類
                        string lowerName = fi.Name.ToLower();
                        if (lowerName.IndexOf("廠區配置圖") >= 0 || lowerName.IndexOf("配置圖") >= 0)
                        {
                            item.Category = "廠區配置圖";
                        }
                        else if (lowerName.IndexOf("製程流程圖") >= 0 || lowerName.IndexOf("流程圖") >= 0)
                        {
                            item.Category = "製程流程圖";
                        }
                        else
                        {
                            item.Category = "相關附件圖檔";
                        }

                        // 構建 Web 存取 URL
                        string appPath = HttpContext.Current.Request.ApplicationPath;
                        if (appPath == "/") appPath = "";
                        item.FileUrl = string.Format("{0}/Upload/FAC/{1}/{2}", appPath, cNo, HttpUtility.UrlPathEncode(fi.Name));

                        list.Add(item);
                    }
                }
            }
            catch
            {
                // 靜默處理目錄讀取異常，避免中斷整體詳情呈現
            }

            return list;
        }

        private static string FormatFileSize(long bytes)
        {
            if (bytes >= 1048576)
            {
                return string.Format("{0:F1} MB", (double)bytes / 1048576.0);
            }
            if (bytes >= 1024)
            {
                return string.Format("{0:F0} KB", (double)bytes / 1024.0);
            }
            return bytes.ToString() + " B";
        }
        #endregion

        #region 4. 工具函式 (DataTableToList, MD5, Twd97ToWgs84)
        private static List<Dictionary<string, object>> DataTableToList(DataTable dt)
        {
            List<Dictionary<string, object>> list = new List<Dictionary<string, object>>();
            if (dt == null) return list;

            foreach (DataRow row in dt.Rows)
            {
                Dictionary<string, object> dict = new Dictionary<string, object>();
                foreach (DataColumn col in dt.Columns)
                {
                    object val = row[col];
                    if (val == DBNull.Value)
                    {
                        dict[col.ColumnName] = null;
                    }
                    else if (col.DataType == typeof(DateTime))
                    {
                        dict[col.ColumnName] = Convert.ToDateTime(val).ToString("yyyy-MM-dd HH:mm");
                    }
                    else
                    {
                        dict[col.ColumnName] = val.ToString().Trim();
                    }
                }
                list.Add(dict);
            }
            return list;
        }

        private static string GetMd5Hash(string input)
        {
            if (string.IsNullOrEmpty(input)) return "";
            using (MD5 md5 = MD5.Create())
            {
                byte[] data = md5.ComputeHash(Encoding.UTF8.GetBytes(input));
                StringBuilder sb = new StringBuilder();
                for (int i = 0; i < data.Length; i++)
                {
                    sb.Append(data[i].ToString("x2"));
                }
                return sb.ToString();
            }
        }

        // TWD97 二度分帶轉 WGS84 經緯度演算法 (C# 5.0 規範)
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
        #endregion
    }
}
