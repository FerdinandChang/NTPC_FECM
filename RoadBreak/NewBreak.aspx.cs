using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.UI;
using NTPC_FEC.Helpers;

namespace NTPC_FEC.RoadBreak
{
    public partial class NewBreak : Page
    {
        private JavaScriptSerializer json;

        public NewBreak()
        {
            json = new JavaScriptSerializer();
            json.MaxJsonLength = int.MaxValue;
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
                        Message = "執行錯誤：" + ex.Message
                    }));
                }
                Response.End();
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
            return "系統查核員";
        }

        private void HandleAjaxAction(string action)
        {
            switch (action.ToLower())
            {
                case "getinit":
                    GetInitData();
                    break;
                case "getcase":
                    GetCaseData(Request["id"]);
                    break;
                case "save":
                    SaveCase();
                    break;
                case "deletephoto":
                    DeletePhoto(Request["id"], Request["filename"]);
                    break;
                default:
                    Response.Write(json.Serialize(new { Success = false, Message = "未知的指令：" + action }));
                    break;
            }
        }

        // 1. 取得頁面初始選單與資料
        private void GetInitData()
        {
            var towns = new List<object>();
            var smoothOptions = new List<object>();
            var holeOptions = new List<object>();
            var roadLvOptions = new List<string> { "省道", "市道", "區道", "市區道路", "其他" };

            // 1. 行政區
            try
            {
                string sqlTown = "SELECT TOWN_NO, TOWN_NA FROM C_TOWN ORDER BY TOWN_NO";
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

            // 2. 道路鋪面平整度選項
            try
            {
                string sqlSmooth = "SELECT Code, Val FROM Dictionary WHERE CodeType = 'RoadBreak_Smooth' ORDER BY Code";
                DataTable dtSmooth = DbHelper.ExecuteDataTable(sqlSmooth);
                if (dtSmooth.Rows.Count > 0)
                {
                    foreach (DataRow row in dtSmooth.Rows)
                    {
                        smoothOptions.Add(new
                        {
                            Code = row["Code"].ToString().Trim(),
                            Val = row["Val"].ToString().Trim()
                        });
                    }
                }
                else
                {
                    smoothOptions.Add(new { Code = "1", Val = "平整良好" });
                    smoothOptions.Add(new { Code = "2", Val = "輕微龜裂/破損" });
                    smoothOptions.Add(new { Code = "3", Val = "中度凹陷/波浪" });
                    smoothOptions.Add(new { Code = "4", Val = "嚴重坑洞/破損" });
                }
            }
            catch
            {
                smoothOptions.Add(new { Code = "1", Val = "平整良好" });
                smoothOptions.Add(new { Code = "2", Val = "輕微龜裂/破損" });
                smoothOptions.Add(new { Code = "3", Val = "中度凹陷/波浪" });
                smoothOptions.Add(new { Code = "4", Val = "嚴重坑洞/破損" });
            }

            // 3. 道路鋪面與孔蓋銜接狀況選項
            try
            {
                string sqlHole = "SELECT Code, Val FROM Dictionary WHERE CodeType = 'RoadBreak_Hole_Conn_St' ORDER BY Code";
                DataTable dtHole = DbHelper.ExecuteDataTable(sqlHole);
                if (dtHole.Rows.Count > 0)
                {
                    foreach (DataRow row in dtHole.Rows)
                    {
                        holeOptions.Add(new
                        {
                            Code = row["Code"].ToString().Trim(),
                            Val = row["Val"].ToString().Trim()
                        });
                    }
                }
                else
                {
                    holeOptions.Add(new { Code = "1", Val = "平順密合" });
                    holeOptions.Add(new { Code = "2", Val = "高低落差 (>1cm)" });
                    holeOptions.Add(new { Code = "3", Val = "孔蓋周邊瀝青龜裂破損" });
                    holeOptions.Add(new { Code = "4", Val = "孔蓋鬆動或異音" });
                    holeOptions.Add(new { Code = "5", Val = "其他" });
                }
            }
            catch
            {
                holeOptions.Add(new { Code = "1", Val = "平順密合" });
                holeOptions.Add(new { Code = "2", Val = "高低落差 (>1cm)" });
                holeOptions.Add(new { Code = "3", Val = "孔蓋周邊瀝青龜裂破損" });
                holeOptions.Add(new { Code = "4", Val = "孔蓋鬆動或異音" });
                holeOptions.Add(new { Code = "5", Val = "其他" });
            }

            // 4. 自動預生新增案號
            string newCaseId = DateTime.Now.ToString("yyyyMMddHHmmss") + "001";
            try
            {
                string prefix = DateTime.Now.ToString("yyyyMMddHHmmss");
                string sqlId = "SELECT TOP 1 Break_ID FROM RoadBreak_CaseMain WHERE Break_ID LIKE @prefix + '%' ORDER BY Break_ID DESC";
                object scalar = DbHelper.ExecuteScalar(sqlId, new SqlParameter("@prefix", prefix));
                if (scalar != null && scalar != DBNull.Value)
                {
                    string maxId = scalar.ToString().Trim();
                    if (maxId.Length >= 17)
                    {
                        int seq = 0;
                        int.TryParse(maxId.Substring(14, 3), out seq);
                        seq++;
                        newCaseId = prefix + seq.ToString("000");
                    }
                }
            }
            catch
            {
                // 資料庫離線時直接使用預生案號
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                Data = new
                {
                    CurrentUser = GetCurrentUser(),
                    Towns = towns,
                    RoadLvOptions = roadLvOptions,
                    SmoothOptions = smoothOptions,
                    HoleOptions = holeOptions,
                    GeneratedCaseId = newCaseId,
                    ReportDate = DateTime.Now.ToString("yyyy-MM-dd HH:mm")
                }
            }));
        }

        // 2. 取得指定案件資料 (編輯模式)
        private void GetCaseData(string breakId)
        {
            if (string.IsNullOrEmpty(breakId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "未提供通報案號" }));
                return;
            }

            string sql = "SELECT * FROM RoadBreak_CaseMain WHERE Break_ID = @id";
            DataTable dt = DbHelper.ExecuteDataTable(sql, new SqlParameter("@id", breakId));
            if (dt.Rows.Count == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "查無此通報案件：" + breakId }));
                return;
            }

            DataRow row = dt.Rows[0];
            double utmE = 0;
            double utmN = 0;
            if (row["S_UTME"] != DBNull.Value)
            {
                double.TryParse(row["S_UTME"].ToString(), out utmE);
            }
            if (row["S_UTMN"] != DBNull.Value)
            {
                double.TryParse(row["S_UTMN"].ToString(), out utmN);
            }

            // 經緯度處理 (優先取資料庫，若無則由 TWD97 自動反算)
            double lat = 0;
            double lon = 0;
            if (row.Table.Columns.Contains("Lat") && row["Lat"] != DBNull.Value)
            {
                double.TryParse(row["Lat"].ToString(), out lat);
            }
            if (row.Table.Columns.Contains("Lon") && row["Lon"] != DBNull.Value)
            {
                double.TryParse(row["Lon"].ToString(), out lon);
            }
            if ((lat <= 0 || lon <= 0) && utmE > 0 && utmN > 0)
            {
                Twd97ToWgs84(utmE, utmN, out lat, out lon);
            }

            string reportDateStr = "";
            if (row["Report_Date"] != DBNull.Value)
            {
                DateTime dtRep;
                if (DateTime.TryParse(row["Report_Date"].ToString(), out dtRep))
                {
                    reportDateStr = dtRep.ToString("yyyy-MM-dd HH:mm");
                }
            }

            string memo = row["Memo"] != DBNull.Value ? row["Memo"].ToString() : "";
            memo = memo.Replace("<br />", "\r\n").Replace("<br>", "\r\n");

            // 讀取既有佐證照片
            var photos = new List<object>();
            string picDir = Server.MapPath("~/Upload/RoadBreakPIC/" + breakId);
            if (Directory.Exists(picDir))
            {
                DirectoryInfo dir = new DirectoryInfo(picDir);
                FileInfo[] files = dir.GetFiles("佐證照片*.*");
                Array.Sort(files, delegate(FileInfo a, FileInfo b) { return string.Compare(a.Name, b.Name, StringComparison.OrdinalIgnoreCase); });
                int idx = 1;
                foreach (FileInfo f in files)
                {
                    photos.Add(new
                    {
                        Index = idx,
                        FileName = f.Name,
                        Url = "../Upload/RoadBreakPIC/" + breakId + "/" + f.Name,
                        Size = f.Length
                    });
                    idx++;
                }
            }

            var caseData = new
            {
                Break_ID = row["Break_ID"].ToString().Trim(),
                Show_ID = row.Table.Columns.Contains("Show_ID") && row["Show_ID"] != DBNull.Value ? row["Show_ID"].ToString().Trim() : row["Break_ID"].ToString().Trim(),
                Report_Date = reportDateStr,
                Report_User = row["Report_User"] != DBNull.Value ? row["Report_User"].ToString().Trim() : "",
                S_UTME = utmE > 0 ? utmE.ToString("0") : "",
                S_UTMN = utmN > 0 ? utmN.ToString("0") : "",
                Lat = lat > 0 ? lat.ToString("F6") : "",
                Lon = lon > 0 ? lon.ToString("F6") : "",
                TOWN_CODE = row["TOWN_CODE"] != DBNull.Value ? row["TOWN_CODE"].ToString().Trim() : "",
                ROAD_LV = row["ROAD_LV"] != DBNull.Value ? row["ROAD_LV"].ToString().Trim() : "市區道路",
                ROAD_Name = row["ROAD_Name"] != DBNull.Value ? row["ROAD_Name"].ToString().Trim() : "",
                Smooth = row["Smooth"] != DBNull.Value ? row["Smooth"].ToString().Trim() : "",
                Hole_Conn_St = row["Hole_Conn_St"] != DBNull.Value ? row["Hole_Conn_St"].ToString().Trim() : "",
                Memo = memo,
                Photos = photos
            };

            Response.Write(json.Serialize(new
            {
                Success = true,
                Data = caseData
            }));
        }

        // 3. 儲存通報單 (新增 / 編輯)
        private void SaveCase()
        {
            string body;
            using (var reader = new StreamReader(Request.InputStream))
            {
                body = reader.ReadToEnd();
            }

            if (string.IsNullOrEmpty(body))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "送出資料不可為空" }));
                return;
            }

            Dictionary<string, object> req = json.Deserialize<Dictionary<string, object>>(body);
            string mode = req.ContainsKey("Mode") && req["Mode"] != null ? req["Mode"].ToString().Trim().ToLower() : "new";
            string breakId = req.ContainsKey("Break_ID") && req["Break_ID"] != null ? req["Break_ID"].ToString().Trim() : "";
            string townCode = req.ContainsKey("TOWN_CODE") && req["TOWN_CODE"] != null ? req["TOWN_CODE"].ToString().Trim() : "";
            string roadLv = req.ContainsKey("ROAD_LV") && req["ROAD_LV"] != null ? req["ROAD_LV"].ToString().Trim() : "";
            string roadName = req.ContainsKey("ROAD_Name") && req["ROAD_Name"] != null ? req["ROAD_Name"].ToString().Trim() : "";
            string smooth = req.ContainsKey("Smooth") && req["Smooth"] != null ? req["Smooth"].ToString().Trim() : "";
            string holeSt = req.ContainsKey("Hole_Conn_St") && req["Hole_Conn_St"] != null ? req["Hole_Conn_St"].ToString().Trim() : "";
            string memo = req.ContainsKey("Memo") && req["Memo"] != null ? req["Memo"].ToString().Trim() : "";
            string utmEStr = req.ContainsKey("S_UTME") && req["S_UTME"] != null ? req["S_UTME"].ToString().Trim() : "0";
            string utmNStr = req.ContainsKey("S_UTMN") && req["S_UTMN"] != null ? req["S_UTMN"].ToString().Trim() : "0";

            double utmE = 0;
            double utmN = 0;
            double.TryParse(utmEStr, out utmE);
            double.TryParse(utmNStr, out utmN);

            if (utmE < 100000 || utmN < 100000)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "通報座標不正確，請確認已點擊地圖或定位" }));
                return;
            }

            if (string.IsNullOrEmpty(townCode))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "請選擇行政區" }));
                return;
            }

            if (string.IsNullOrEmpty(roadName))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "請輸入道路名稱" }));
                return;
            }

            string latStr = req.ContainsKey("Lat") && req["Lat"] != null ? req["Lat"].ToString().Trim() : "";
            string lonStr = req.ContainsKey("Lon") && req["Lon"] != null ? req["Lon"].ToString().Trim() : "";
            double lat = 0;
            double lon = 0;
            double.TryParse(latStr, out lat);
            double.TryParse(lonStr, out lon);

            // 經緯度座標處理 (優先取前端傳入值，若無則由 TWD97 自動反算補齊)
            if ((lat <= 0 || lon <= 0) && utmE > 0 && utmN > 0)
            {
                Twd97ToWgs84(utmE, utmN, out lat, out lon);
            }

            string currentUser = GetCurrentUser();
            string memoFormatted = memo.Replace("\r\n", "<br />").Replace("\n", "<br />").Replace("\r", "<br />");

            if (mode == "new")
            {
                // 自動生成新案號
                string prefix = DateTime.Now.ToString("yyyyMMddHHmmss");
                int seq = 1;
                try
                {
                    string sqlId = "SELECT TOP 1 Break_ID FROM RoadBreak_CaseMain WHERE Break_ID LIKE @prefix + '%' ORDER BY Break_ID DESC";
                    object scalar = DbHelper.ExecuteScalar(sqlId, new SqlParameter("@prefix", prefix));
                    if (scalar != null && scalar != DBNull.Value)
                    {
                        string maxId = scalar.ToString().Trim();
                        if (maxId.Length >= 17)
                        {
                            int parsedSeq = 0;
                            if (int.TryParse(maxId.Substring(14, 3), out parsedSeq))
                            {
                                seq = parsedSeq + 1;
                            }
                        }
                    }
                }
                catch
                {
                    // 若查詢失敗使用當前序號 1
                }
                breakId = prefix + seq.ToString("000");

                string sqlInsert = @"INSERT INTO RoadBreak_CaseMain 
                    (Break_ID, Show_ID, Report_Date, Report_User, S_UTME, S_UTMN, Lat, Lon, TOWN_CODE, ROAD_LV, ROAD_Name, Smooth, Hole_Conn_St, Memo)
                    VALUES
                    (@Break_ID, @Show_ID, @Report_Date, @Report_User, @S_UTME, @S_UTMN, @Lat, @Lon, @TOWN_CODE, @ROAD_LV, @ROAD_Name, @Smooth, @Hole_Conn_St, @Memo)";

                SqlParameter[] pars = new SqlParameter[]
                {
                    new SqlParameter("@Break_ID", breakId),
                    new SqlParameter("@Show_ID", breakId),
                    new SqlParameter("@Report_Date", DateTime.Now),
                    new SqlParameter("@Report_User", currentUser),
                    new SqlParameter("@S_UTME", utmE),
                    new SqlParameter("@S_UTMN", utmN),
                    new SqlParameter("@Lat", lat > 0 ? (object)lat : DBNull.Value),
                    new SqlParameter("@Lon", lon > 0 ? (object)lon : DBNull.Value),
                    new SqlParameter("@TOWN_CODE", townCode),
                    new SqlParameter("@ROAD_LV", roadLv),
                    new SqlParameter("@ROAD_Name", roadName),
                    new SqlParameter("@Smooth", smooth),
                    new SqlParameter("@Hole_Conn_St", holeSt),
                    new SqlParameter("@Memo", memoFormatted)
                };

                DbHelper.ExecuteNonQuery(sqlInsert, pars);
            }
            else
            {
                // 編輯更新
                if (string.IsNullOrEmpty(breakId))
                {
                    Response.Write(json.Serialize(new { Success = false, Message = "編輯模式缺少通報案號" }));
                    return;
                }

                string sqlUpdate = @"UPDATE RoadBreak_CaseMain SET 
                    Report_User = @Report_User,
                    S_UTME = @S_UTME,
                    S_UTMN = @S_UTMN,
                    Lat = @Lat,
                    Lon = @Lon,
                    TOWN_CODE = @TOWN_CODE,
                    ROAD_LV = @ROAD_LV,
                    ROAD_Name = @ROAD_Name,
                    Smooth = @Smooth,
                    Hole_Conn_St = @Hole_Conn_St,
                    Memo = @Memo
                    WHERE Break_ID = @Break_ID";

                SqlParameter[] pars = new SqlParameter[]
                {
                    new SqlParameter("@Break_ID", breakId),
                    new SqlParameter("@Report_User", currentUser),
                    new SqlParameter("@S_UTME", utmE),
                    new SqlParameter("@S_UTMN", utmN),
                    new SqlParameter("@Lat", lat > 0 ? (object)lat : DBNull.Value),
                    new SqlParameter("@Lon", lon > 0 ? (object)lon : DBNull.Value),
                    new SqlParameter("@TOWN_CODE", townCode),
                    new SqlParameter("@ROAD_LV", roadLv),
                    new SqlParameter("@ROAD_Name", roadName),
                    new SqlParameter("@Smooth", smooth),
                    new SqlParameter("@Hole_Conn_St", holeSt),
                    new SqlParameter("@Memo", memoFormatted)
                };

                DbHelper.ExecuteNonQuery(sqlUpdate, pars);
            }

            // 處理上傳照片 (Base64 清單)
            if (req.ContainsKey("Photos") && req["Photos"] is System.Collections.ArrayList)
            {
                var photosList = (System.Collections.ArrayList)req["Photos"];
                string targetDir = Server.MapPath("~/Upload/RoadBreakPIC/" + breakId);
                if (!Directory.Exists(targetDir))
                {
                    Directory.CreateDirectory(targetDir);
                }

                int pIndex = 1;
                foreach (object pItem in photosList)
                {
                    if (pItem is Dictionary<string, object>)
                    {
                        var pDict = (Dictionary<string, object>)pItem;
                        if (pDict.ContainsKey("Base64") && pDict["Base64"] != null)
                        {
                            string rawBase64 = pDict["Base64"].ToString();
                            if (!string.IsNullOrEmpty(rawBase64))
                            {
                                // 清洗 Data URI 標頭
                                string cleanBase64 = Regex.Replace(rawBase64, @"^data:image\/[a-zA-Z]+;base64,", "");
                                byte[] imgBytes = Convert.FromBase64String(cleanBase64);
                                string targetFileName = string.Format("佐證照片_{0}.jpg", pIndex);
                                string filePath = Path.Combine(targetDir, targetFileName);
                                File.WriteAllBytes(filePath, imgBytes);
                            }
                        }
                    }
                    pIndex++;
                }
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                Message = (mode == "new" ? "通報單新增成功！" : "通報單更新成功！"),
                Break_ID = breakId
            }));
        }

        // 4. 刪除指定照片
        private void DeletePhoto(string breakId, string fileName)
        {
            if (string.IsNullOrEmpty(breakId) || string.IsNullOrEmpty(fileName))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "參數不完整" }));
                return;
            }

            // 防止路徑遍歷
            string safeFileName = Path.GetFileName(fileName);
            string targetDir = Server.MapPath("~/Upload/RoadBreakPIC/" + breakId);
            string filePath = Path.Combine(targetDir, safeFileName);

            if (File.Exists(filePath))
            {
                File.Delete(filePath);
                Response.Write(json.Serialize(new { Success = true, Message = "照片已刪除" }));
            }
            else
            {
                Response.Write(json.Serialize(new { Success = false, Message = "檔案不存在" }));
            }
        }

        // 5. TWD97 轉 WGS84 標準演算法 (二度分帶逆算)
        public static void Twd97ToWgs84(double x, double y, out double lat, out double lon)
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

        // 6. WGS84 轉 TWD97 標準演算法 (二度分帶正算)
        public static void Wgs84ToTwd97(double lat, double lon, out double x, out double y)
        {
            if (lat <= 0 || lon <= 0) { x = 0; y = 0; return; }

            double a = 6378137.0;
            double b = 6356752.314245;
            double lon0 = 121.0 * Math.PI / 180.0;
            double k0 = 0.9999;
            double dx = 250000.0;

            double e = Math.Sqrt(1.0 - (b * b) / (a * a));
            double e2 = e * e / (1.0 - e * e);

            double latRad = lat * Math.PI / 180.0;
            double lonRad = lon * Math.PI / 180.0;

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
    }
}
