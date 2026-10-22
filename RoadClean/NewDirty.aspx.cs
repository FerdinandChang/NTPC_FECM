using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.UI;
using NTPC_FEC.Helpers;

namespace NTPC_FEC.RoadClean
{
    public partial class NewDirty : Page
    {
        private JavaScriptSerializer json = new JavaScriptSerializer { MaxJsonLength = int.MaxValue };

        protected void Page_Load(object sender, EventArgs e)
        {
            // Ajax API 請求處理
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
                case "init":
                    InitPageData();
                    break;
                case "save":
                    SaveDirtyRecord();
                    break;
                case "deletecase":
                    DeleteCaseRecord();
                    break;
                default:
                    Response.Write(json.Serialize(new { Success = false, Message = "未知的操作指令" }));
                    break;
            }
        }

        // 1. 初始化頁面資料 (依據 mode 與 id)
        private void InitPageData()
        {
            string mode = Request["mode"];
            if (string.IsNullOrEmpty(mode)) mode = "new";
            mode = mode.ToLower();

            string dirtyId = Request["id"];
            if (dirtyId != null) dirtyId = dirtyId.Trim();

            // 取得登入使用者資訊
            string loginUser = Session["LoginUser"] != null ? Session["LoginUser"].ToString() : "";
            string loginUserName = Session["UserName"] != null ? Session["UserName"].ToString() : "";

            if (string.IsNullOrEmpty(loginUserName) && !string.IsNullOrEmpty(loginUser))
            {
                loginUserName = GetUserNameById(loginUser);
            }

            if (string.IsNullOrEmpty(loginUser))
            {
                loginUser = "tester";
                loginUserName = "現場巡查員";
            }

            var result = new Dictionary<string, object>();
            result["Mode"] = mode;
            result["CurrentUserId"] = loginUser;
            result["CurrentUserName"] = loginUserName;

            if (mode == "new")
            {
                // 新增模式：預設查核時間與自動編號預覽
                result["DirtyId"] = "自動編號";
                result["ShowId"] = "送出後自動產生";
                result["ReportDate"] = DateTime.Now.ToString("yyyy-MM-ddTHH:mm");
                result["ReportUser"] = loginUser;
                result["ReportUserName"] = loginUserName;
                result["Kind"] = "EF"; // 預設固定逸散
                result["S_UTME"] = 0;
                result["S_UTMN"] = 0;
                result["S_UTME1"] = 0;
                result["S_UTMN1"] = 0;
                result["Comm"] = "";
                result["Photos1"] = new List<object>();
                result["Photos2"] = new List<object>();

                Response.Write(json.Serialize(new { Success = true, Data = result }));
                return;
            }

            // 編輯或檢視模式 (edit / read / chk)
            if (string.IsNullOrEmpty(dirtyId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "缺少通報案號參數" }));
                return;
            }

            string sql = "SELECT * FROM RoadDirty_CaseMain WHERE Dirty_ID = @id";
            DataTable dt = DbHelper.ExecuteDataTable(sql, new SqlParameter("@id", dirtyId));
            if (dt.Rows.Count == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "查無此通報案號紀錄：" + dirtyId }));
                return;
            }

            DataRow row = dt.Rows[0];
            string rptUser = row["Report_User"] != DBNull.Value ? row["Report_User"].ToString().Trim() : "";
            string rptUserName = GetUserNameById(rptUser);

            string showId = row.Table.Columns.Contains("Show_ID") && row["Show_ID"] != DBNull.Value
                ? row["Show_ID"].ToString().Trim()
                : dirtyId;

            DateTime rptDate = DateTime.Now;
            if (row["Report_Date"] != DBNull.Value)
            {
                rptDate = Convert.ToDateTime(row["Report_Date"]);
            }

            double utmE = 0;
            double utmN = 0;
            double utmE1 = 0;
            double utmN1 = 0;

            if (row["S_UTME"] != DBNull.Value) double.TryParse(row["S_UTME"].ToString(), out utmE);
            if (row["S_UTMN"] != DBNull.Value) double.TryParse(row["S_UTMN"].ToString(), out utmN);
            if (row.Table.Columns.Contains("S_UTME1") && row["S_UTME1"] != DBNull.Value) double.TryParse(row["S_UTME1"].ToString(), out utmE1);
            if (row.Table.Columns.Contains("S_UTMN1") && row["S_UTMN1"] != DBNull.Value) double.TryParse(row["S_UTMN1"].ToString(), out utmN1);

            result["DirtyId"] = dirtyId;
            result["ShowId"] = string.IsNullOrEmpty(showId) ? dirtyId : showId;
            result["ReportDate"] = rptDate.ToString("yyyy-MM-ddTHH:mm");
            result["ReportUser"] = rptUser;
            result["ReportUserName"] = !string.IsNullOrEmpty(rptUserName) ? rptUserName : rptUser;
            result["Kind"] = row.Table.Columns.Contains("KIND") && row["KIND"] != DBNull.Value ? row["KIND"].ToString().Trim() : "EF";
            double? lat = null;
            double? lon = null;
            double? lat1 = null;
            double? lon1 = null;

            if (row.Table.Columns.Contains("Lat") && row["Lat"] != DBNull.Value)
            {
                double parsed;
                if (double.TryParse(row["Lat"].ToString(), out parsed) && parsed > 0) lat = parsed;
            }
            if (row.Table.Columns.Contains("Lon") && row["Lon"] != DBNull.Value)
            {
                double parsed;
                if (double.TryParse(row["Lon"].ToString(), out parsed) && parsed > 0) lon = parsed;
            }
            if (row.Table.Columns.Contains("Lat1") && row["Lat1"] != DBNull.Value)
            {
                double parsed;
                if (double.TryParse(row["Lat1"].ToString(), out parsed) && parsed > 0) lat1 = parsed;
            }
            if (row.Table.Columns.Contains("Lon1") && row["Lon1"] != DBNull.Value)
            {
                double parsed;
                if (double.TryParse(row["Lon1"].ToString(), out parsed) && parsed > 0) lon1 = parsed;
            }

            // 若舊資料庫尚未記錄經緯度但有 TWD97，自動反算補全
            if ((!lat.HasValue || !lon.HasValue) && utmE > 0 && utmN > 0)
            {
                double calcLat, calcLon;
                Twd97ToWgs84(utmE, utmN, out calcLat, out calcLon);
                lat = calcLat;
                lon = calcLon;
            }
            if ((!lat1.HasValue || !lon1.HasValue) && utmE1 > 0 && utmN1 > 0)
            {
                double calcLat1, calcLon1;
                Twd97ToWgs84(utmE1, utmN1, out calcLat1, out calcLon1);
                lat1 = calcLat1;
                lon1 = calcLon1;
            }

            result["S_UTME"] = utmE;
            result["S_UTMN"] = utmN;
            result["S_UTME1"] = utmE1;
            result["S_UTMN1"] = utmN1;
            result["Lat"] = lat;
            result["Lon"] = lon;
            result["Lat1"] = lat1;
            result["Lon1"] = lon1;
            result["Comm"] = row.Table.Columns.Contains("COMM") && row["COMM"] != DBNull.Value ? row["COMM"].ToString() : "";

            // 讀取伺服器上已存在的照片
            result["Photos1"] = GetExistingPhotos(dirtyId, "疑似髒污點現場照片");
            result["Photos2"] = GetExistingPhotos(dirtyId, "佐證照片");

            Response.Write(json.Serialize(new { Success = true, Data = result }));
        }

        // 讀取硬碟中的現有照片列表
        private List<object> GetExistingPhotos(string dirtyId, string prefix)
        {
            var list = new List<object>();
            string relDir = "/Upload/RoadDirtyPIC/" + dirtyId + "/";
            string physDir = Server.MapPath("~" + relDir);

            if (!Directory.Exists(physDir))
            {
                return list;
            }

            DirectoryInfo di = new DirectoryInfo(physDir);
            FileInfo[] files = di.GetFiles(prefix + "*.*");
            Array.Sort(files, delegate(FileInfo a, FileInfo b) { return a.Name.CompareTo(b.Name); });

            foreach (FileInfo f in files)
            {
                string ext = f.Extension.ToLower();
                if (ext == ".jpg" || ext == ".jpeg" || ext == ".png" || ext == ".gif")
                {
                    list.Add(new
                    {
                        FileName = f.Name,
                        Url = relDir + f.Name,
                        Size = f.Length,
                        LastModified = f.LastWriteTime.ToString("yyyy-MM-dd HH:mm")
                    });
                }
            }

            return list;
        }

        // 2. 儲存案件紀錄 (新增或更新)
        private void SaveDirtyRecord()
        {
            string rawJson = null;
            using (var reader = new StreamReader(Request.InputStream))
            {
                rawJson = reader.ReadToEnd();
            }

            if (string.IsNullOrEmpty(rawJson))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "儲存內容不能為空" }));
                return;
            }

            DirtySaveModel input = json.Deserialize<DirtySaveModel>(rawJson);
            if (input == null)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "無效的儲存資料格式" }));
                return;
            }

            string mode = input.Mode != null ? input.Mode.ToLower() : "new";
            string dirtyId = input.DirtyId != null ? input.DirtyId.Trim() : "";
            string loginUser = Session["LoginUser"] != null ? Session["LoginUser"].ToString() : (input.ReportUser ?? "Guest");

            // 驗證必要欄位
            if (input.S_UTME <= 0 || input.S_UTMN <= 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "通報坐標 1 為必填項目，且數值必須大於 0" }));
                return;
            }

            DateTime reportDate = DateTime.Now;
            if (!string.IsNullOrEmpty(input.ReportDate))
            {
                DateTime.TryParse(input.ReportDate.Replace("T", " "), out reportDate);
            }

            // 經緯度座標處理 (優先使用前端傳入值，若無則由 TWD97 自動反算)
            double? saveLat = input.Lat;
            double? saveLon = input.Lon;
            if ((!saveLat.HasValue || !saveLon.HasValue || saveLat.Value <= 0 || saveLon.Value <= 0) && input.S_UTME > 0 && input.S_UTMN > 0)
            {
                double calcLat, calcLon;
                Twd97ToWgs84(input.S_UTME, input.S_UTMN, out calcLat, out calcLon);
                saveLat = calcLat;
                saveLon = calcLon;
            }

            double? saveLat1 = input.Lat1;
            double? saveLon1 = input.Lon1;
            if ((!saveLat1.HasValue || !saveLon1.HasValue || saveLat1.Value <= 0 || saveLon1.Value <= 0)
                && input.S_UTME1.HasValue && input.S_UTME1.Value > 0
                && input.S_UTMN1.HasValue && input.S_UTMN1.Value > 0)
            {
                double calcLat1, calcLon1;
                Twd97ToWgs84(input.S_UTME1.Value, input.S_UTMN1.Value, out calcLat1, out calcLon1);
                saveLat1 = calcLat1;
                saveLon1 = calcLon1;
            }

            bool isNew = (mode == "new" || string.IsNullOrEmpty(dirtyId) || dirtyId == "自動編號");

            if (isNew)
            {
                // 產生自動流水號：以當日日期為前綴 (如 20261022001)
                string datePrefix = DateTime.Now.ToString("yyyyMMdd");
                string sqlSeq = "SELECT TOP 1 Dirty_ID FROM RoadDirty_CaseMain WHERE Dirty_ID LIKE @prefix + '%' ORDER BY Dirty_ID DESC";
                object maxObj = DbHelper.ExecuteScalar(sqlSeq, new SqlParameter("@prefix", datePrefix));
                int seq = 1;
                if (maxObj != null && maxObj != DBNull.Value)
                {
                    string maxId = maxObj.ToString().Trim();
                    if (maxId.Length >= 11)
                    {
                        string seqStr = maxId.Substring(8);
                        int parsedSeq = 0;
                        if (int.TryParse(seqStr, out parsedSeq))
                        {
                            seq = parsedSeq + 1;
                        }
                    }
                }
                dirtyId = datePrefix + string.Format("{0:000}", seq);

                string insertSql = "INSERT INTO RoadDirty_CaseMain "
                                 + " (Dirty_ID, Show_ID, Report_Date, Report_User, S_UTME, S_UTMN, S_UTME1, S_UTMN1, Lat, Lon, Lat1, Lon1, COMM, KIND) "
                                 + " VALUES "
                                 + " (@Dirty_ID, @Show_ID, @Report_Date, @Report_User, @S_UTME, @S_UTMN, @S_UTME1, @S_UTMN1, @Lat, @Lon, @Lat1, @Lon1, @COMM, @KIND)";

                DbHelper.ExecuteNonQuery(insertSql,
                    new SqlParameter("@Dirty_ID", dirtyId),
                    new SqlParameter("@Show_ID", dirtyId),
                    new SqlParameter("@Report_Date", reportDate),
                    new SqlParameter("@Report_User", loginUser),
                    new SqlParameter("@S_UTME", input.S_UTME),
                    new SqlParameter("@S_UTMN", input.S_UTMN),
                    new SqlParameter("@S_UTME1", input.S_UTME1.HasValue && input.S_UTME1.Value > 0 ? (object)input.S_UTME1.Value : DBNull.Value),
                    new SqlParameter("@S_UTMN1", input.S_UTMN1.HasValue && input.S_UTMN1.Value > 0 ? (object)input.S_UTMN1.Value : DBNull.Value),
                    new SqlParameter("@Lat", saveLat.HasValue && saveLat.Value > 0 ? (object)saveLat.Value : DBNull.Value),
                    new SqlParameter("@Lon", saveLon.HasValue && saveLon.Value > 0 ? (object)saveLon.Value : DBNull.Value),
                    new SqlParameter("@Lat1", saveLat1.HasValue && saveLat1.Value > 0 ? (object)saveLat1.Value : DBNull.Value),
                    new SqlParameter("@Lon1", saveLon1.HasValue && saveLon1.Value > 0 ? (object)saveLon1.Value : DBNull.Value),
                    new SqlParameter("@COMM", input.Comm ?? ""),
                    new SqlParameter("@KIND", input.Kind ?? "EF")
                );
            }
            else
            {
                // 更新已存在案件
                string updateSql = "UPDATE RoadDirty_CaseMain SET "
                                 + " Report_Date = @Report_Date, "
                                 + " S_UTME = @S_UTME, "
                                 + " S_UTMN = @S_UTMN, "
                                 + " S_UTME1 = @S_UTME1, "
                                 + " S_UTMN1 = @S_UTMN1, "
                                 + " Lat = @Lat, "
                                 + " Lon = @Lon, "
                                 + " Lat1 = @Lat1, "
                                 + " Lon1 = @Lon1, "
                                 + " COMM = @COMM, "
                                 + " KIND = @KIND "
                                 + " WHERE Dirty_ID = @Dirty_ID";

                DbHelper.ExecuteNonQuery(updateSql,
                    new SqlParameter("@Report_Date", reportDate),
                    new SqlParameter("@S_UTME", input.S_UTME),
                    new SqlParameter("@S_UTMN", input.S_UTMN),
                    new SqlParameter("@S_UTME1", input.S_UTME1.HasValue && input.S_UTME1.Value > 0 ? (object)input.S_UTME1.Value : DBNull.Value),
                    new SqlParameter("@S_UTMN1", input.S_UTMN1.HasValue && input.S_UTMN1.Value > 0 ? (object)input.S_UTMN1.Value : DBNull.Value),
                    new SqlParameter("@Lat", saveLat.HasValue && saveLat.Value > 0 ? (object)saveLat.Value : DBNull.Value),
                    new SqlParameter("@Lon", saveLon.HasValue && saveLon.Value > 0 ? (object)saveLon.Value : DBNull.Value),
                    new SqlParameter("@Lat1", saveLat1.HasValue && saveLat1.Value > 0 ? (object)saveLat1.Value : DBNull.Value),
                    new SqlParameter("@Lon1", saveLon1.HasValue && saveLon1.Value > 0 ? (object)saveLon1.Value : DBNull.Value),
                    new SqlParameter("@COMM", input.Comm ?? ""),
                    new SqlParameter("@KIND", input.Kind ?? "EF"),
                    new SqlParameter("@Dirty_ID", dirtyId)
                );
            }

            // 儲存照片實體檔案
            SavePhotosToDisk(dirtyId, input.Photos1, "疑似髒污點現場照片");
            SavePhotosToDisk(dirtyId, input.Photos2, "佐證照片");

            Response.Write(json.Serialize(new
            {
                Success = true,
                Message = isNew ? "道路髒污通報單已成功建立！" : "道路髒污通報單已更新儲存！",
                DirtyId = dirtyId
            }));
        }

        // 儲存與清理磁碟中的照片
        private void SavePhotosToDisk(string dirtyId, List<PhotoUploadItem> photos, string prefix)
        {
            if (photos == null) return;

            string relDir = "/Upload/RoadDirtyPIC/" + dirtyId + "/";
            string physDir = Server.MapPath("~" + relDir);
            if (!Directory.Exists(physDir))
            {
                Directory.CreateDirectory(physDir);
            }

            int index = 1;
            foreach (var item in photos)
            {
                if (item == null) continue;

                // 若標記為刪除
                if (item.IsDeleted)
                {
                    if (!string.IsNullOrEmpty(item.FileName))
                    {
                        string delPath = Path.Combine(physDir, item.FileName);
                        if (File.Exists(delPath))
                        {
                            try { File.Delete(delPath); } catch { }
                        }
                    }
                    continue;
                }

                // 若有新上傳的 Base64 檔案
                if (!string.IsNullOrEmpty(item.Base64Data))
                {
                    string targetFileName = prefix + "_" + index + ".jpg";
                    string fullPath = Path.Combine(physDir, targetFileName);

                    try
                    {
                        string b64 = item.Base64Data;
                        int commaIdx = b64.IndexOf(',');
                        if (commaIdx >= 0)
                        {
                            b64 = b64.Substring(commaIdx + 1);
                        }
                        byte[] fileBytes = Convert.FromBase64String(b64);
                        File.WriteAllBytes(fullPath, fileBytes);
                    }
                    catch { }
                    index++;
                }
                else if (!string.IsNullOrEmpty(item.FileName))
                {
                    // 已存在之既有照片
                    index++;
                }
            }
        }

        // 3. 刪除案件 (軟刪除或物理刪除)
        private void DeleteCaseRecord()
        {
            string dirtyId = Request["id"];
            if (string.IsNullOrEmpty(dirtyId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "缺少欲刪除的通報案號" }));
                return;
            }

            string sql = "DELETE FROM RoadDirty_CaseMain WHERE Dirty_ID = @id";
            DbHelper.ExecuteNonQuery(sql, new SqlParameter("@id", dirtyId));

            // 清理硬碟目錄
            string relDir = "/Upload/RoadDirtyPIC/" + dirtyId + "/";
            string physDir = Server.MapPath("~" + relDir);
            if (Directory.Exists(physDir))
            {
                try { Directory.Delete(physDir, true); } catch { }
            }

            Response.Write(json.Serialize(new { Success = true, Message = "通報案件已成功刪除" }));
        }

        // TWD97 二度分帶轉 WGS84 經緯度演算法 (符合 C# 5.0)
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

        // 輔助函式：取得使用者姓名
        private string GetUserNameById(string userId)
        {
            if (string.IsNullOrEmpty(userId)) return "";
            try
            {
                string sql = "SELECT TOP 1 Name FROM UserAcc WHERE UserID = @u";
                object val = DbHelper.ExecuteScalar(sql, new SqlParameter("@u", userId));
                return val != null && val != DBNull.Value ? val.ToString().Trim() : userId;
            }
            catch
            {
                return userId;
            }
        }

        // 資料傳輸模型定義
        public class DirtySaveModel
        {
            public string Mode { get; set; }
            public string DirtyId { get; set; }
            public string ReportDate { get; set; }
            public string ReportUser { get; set; }
            public string Kind { get; set; }
            public double S_UTME { get; set; }
            public double S_UTMN { get; set; }
            public double? S_UTME1 { get; set; }
            public double? S_UTMN1 { get; set; }
            public double? Lat { get; set; }
            public double? Lon { get; set; }
            public double? Lat1 { get; set; }
            public double? Lon1 { get; set; }
            public string Comm { get; set; }
            public List<PhotoUploadItem> Photos1 { get; set; }
            public List<PhotoUploadItem> Photos2 { get; set; }
        }

        public class PhotoUploadItem
        {
            public string FileName { get; set; }
            public string Base64Data { get; set; }
            public bool IsDeleted { get; set; }
        }
    }
}
