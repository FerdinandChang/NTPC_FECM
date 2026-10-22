using System;
using System.Collections;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.UI;
using NTPC_FEC.Helpers;

namespace NTPC_FEC.RoadBSC
{
    public partial class NewBSC : Page
    {
        private JavaScriptSerializer json;

        public NewBSC()
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
            var coverSoilOptions = new List<object>();
            var roadLvOptions = new List<string> { "省道", "市道", "區道", "市區道路", "其他" };

            // (1) 行政區
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
                // Fallback 新北市 29 個行政區
                string[,] defaultTowns = new string[,]
                {
                    {"F01", "板橋區"}, {"F02", "三重區"}, {"F03", "中和區"}, {"F04", "永和區"},
                    {"F05", "新莊區"}, {"F06", "新店區"}, {"F07", "樹林區"}, {"F08", "鶯歌區"},
                    {"F09", "三峽區"}, {"F10", "淡水區"}, {"F11", "汐止區"}, {"F12", "瑞芳區"},
                    {"F13", "土城區"}, {"F14", "蘆洲區"}, {"F15", "五股區"}, {"F16", "泰山區"},
                    {"F17", "林口區"}, {"F18", "深坑區"}, {"F19", "石碇區"}, {"F20", "坪林區"},
                    {"F21", "三芝區"}, {"F22", "石門區"}, {"F23", "八里區"}, {"F24", "平溪區"},
                    {"F25", "雙溪區"}, {"F26", "貢寮區"}, {"F27", "金山區"}, {"F28", "萬里區"},
                    {"F29", "烏來區"}
                };
                for (int i = 0; i < defaultTowns.GetLength(0); i++)
                {
                    towns.Add(new { TownNo = defaultTowns[i, 0], TownName = defaultTowns[i, 1] });
                }
            }

            // (2) 人行道鋪面平整度選項
            try
            {
                string sqlSmooth = "SELECT Code, Val FROM Dictionary WHERE CodeType = 'RoadBSC_Smooth' ORDER BY Code";
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
                    smoothOptions.Add(new { Code = "1", Val = "平整良好無損" });
                    smoothOptions.Add(new { Code = "2", Val = "輕微破損/不平整" });
                    smoothOptions.Add(new { Code = "3", Val = "磚面鬆動/破損下陷" });
                    smoothOptions.Add(new { Code = "4", Val = "嚴重坑洞/破損" });
                    smoothOptions.Add(new { Code = "5", Val = "其他" });
                }
            }
            catch
            {
                smoothOptions.Add(new { Code = "1", Val = "平整良好無損" });
                smoothOptions.Add(new { Code = "2", Val = "輕微破損/不平整" });
                smoothOptions.Add(new { Code = "3", Val = "磚面鬆動/破損下陷" });
                smoothOptions.Add(new { Code = "4", Val = "嚴重坑洞/破損" });
                smoothOptions.Add(new { Code = "5", Val = "其他" });
            }

            // (3) 人行道或交通島覆土狀況選項
            try
            {
                string sqlCover = "SELECT Code, Val FROM Dictionary WHERE CodeType = 'RoadBSC_Cover_Soil' ORDER BY Code";
                DataTable dtCover = DbHelper.ExecuteDataTable(sqlCover);
                if (dtCover.Rows.Count > 0)
                {
                    foreach (DataRow row in dtCover.Rows)
                    {
                        coverSoilOptions.Add(new
                        {
                            Code = row["Code"].ToString().Trim(),
                            Val = row["Val"].ToString().Trim()
                        });
                    }
                }
                else
                {
                    coverSoilOptions.Add(new { Code = "1", Val = "植生良好無覆土" });
                    coverSoilOptions.Add(new { Code = "2", Val = "局部覆土裸露 (< 5m²)" });
                    coverSoilOptions.Add(new { Code = "3", Val = "大面積覆土裸露 (>= 5m²)" });
                    coverSoilOptions.Add(new { Code = "4", Val = "土石堆置或溢散至車道" });
                    coverSoilOptions.Add(new { Code = "5", Val = "其他" });
                }
            }
            catch
            {
                coverSoilOptions.Add(new { Code = "1", Val = "植生良好無覆土" });
                coverSoilOptions.Add(new { Code = "2", Val = "局部覆土裸露 (< 5m²)" });
                coverSoilOptions.Add(new { Code = "3", Val = "大面積覆土裸露 (>= 5m²)" });
                coverSoilOptions.Add(new { Code = "4", Val = "土石堆置或溢散至車道" });
                coverSoilOptions.Add(new { Code = "5", Val = "其他" });
            }

            // (4) 自動預生新增案號 (格式: yyyyMMddHHmmss{seq:000})
            string newCaseId = DateTime.Now.ToString("yyyyMMddHHmmss") + "001";
            try
            {
                string prefix = DateTime.Now.ToString("yyyyMMddHHmmss");
                string sqlId = "SELECT TOP 1 BSC_ID FROM RoadBSC_CaseMain WHERE BSC_ID LIKE @prefix + '%' ORDER BY BSC_ID DESC";
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
                // 資料庫離線或例外時直接使用預生案號
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
                    CoverSoilOptions = coverSoilOptions,
                    GeneratedCaseId = newCaseId,
                    ReportDate = DateTime.Now.ToString("yyyy-MM-dd HH:mm")
                }
            }));
        }

        // 2. 取得指定案件資料 (編輯模式)
        private void GetCaseData(string bscId)
        {
            if (string.IsNullOrEmpty(bscId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "未提供通報案號" }));
                return;
            }

            string sql = "SELECT * FROM RoadBSC_CaseMain WHERE BSC_ID = @id";
            DataTable dt = DbHelper.ExecuteDataTable(sql, new SqlParameter("@id", bscId));
            if (dt.Rows.Count == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "查無此通報案件：" + bscId }));
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

            // 換算經緯度回傳給地圖
            double lat = 0;
            double lon = 0;
            if (utmE > 0 && utmN > 0)
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
            string picDir = Server.MapPath("~/Upload/RoadBSCPIC/" + bscId);
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
                        Url = "../Upload/RoadBSCPIC/" + bscId + "/" + f.Name,
                        Size = f.Length
                    });
                    idx++;
                }
            }

            var caseData = new
            {
                BSC_ID = row["BSC_ID"].ToString().Trim(),
                Show_ID = row.Table.Columns.Contains("Show_ID") && row["Show_ID"] != DBNull.Value ? row["Show_ID"].ToString().Trim() : row["BSC_ID"].ToString().Trim(),
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
                Cover_Soil = row["Cover_Soil"] != DBNull.Value ? row["Cover_Soil"].ToString().Trim() : "",
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
            string bscId = req.ContainsKey("BSC_ID") && req["BSC_ID"] != null ? req["BSC_ID"].ToString().Trim() : "";
            string townCode = req.ContainsKey("TOWN_CODE") && req["TOWN_CODE"] != null ? req["TOWN_CODE"].ToString().Trim() : "";
            string roadLv = req.ContainsKey("ROAD_LV") && req["ROAD_LV"] != null ? req["ROAD_LV"].ToString().Trim() : "";
            string roadName = req.ContainsKey("ROAD_Name") && req["ROAD_Name"] != null ? req["ROAD_Name"].ToString().Trim() : "";
            string smooth = req.ContainsKey("Smooth") && req["Smooth"] != null ? req["Smooth"].ToString().Trim() : "";
            string coverSoil = req.ContainsKey("Cover_Soil") && req["Cover_Soil"] != null ? req["Cover_Soil"].ToString().Trim() : "";
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

            string currentUser = GetCurrentUser();
            string memoFormatted = memo.Replace("\r\n", "<br />").Replace("\n", "<br />").Replace("\r", "<br />");

            if (mode == "new")
            {
                // 自動生成新案號 (防並行重號)
                string prefix = DateTime.Now.ToString("yyyyMMddHHmmss");
                int seq = 1;
                try
                {
                    string sqlId = "SELECT TOP 1 BSC_ID FROM RoadBSC_CaseMain WHERE BSC_ID LIKE @prefix + '%' ORDER BY BSC_ID DESC";
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
                bscId = prefix + seq.ToString("000");

                string sqlInsert = @"INSERT INTO RoadBSC_CaseMain 
                    (BSC_ID, Show_ID, Report_Date, Report_User, S_UTME, S_UTMN, TOWN_CODE, ROAD_LV, ROAD_Name, Smooth, Cover_Soil, Memo)
                    VALUES
                    (@BSC_ID, @Show_ID, @Report_Date, @Report_User, @S_UTME, @S_UTMN, @TOWN_CODE, @ROAD_LV, @ROAD_Name, @Smooth, @Cover_Soil, @Memo)";

                SqlParameter[] pars = new SqlParameter[]
                {
                    new SqlParameter("@BSC_ID", bscId),
                    new SqlParameter("@Show_ID", bscId),
                    new SqlParameter("@Report_Date", DateTime.Now),
                    new SqlParameter("@Report_User", currentUser),
                    new SqlParameter("@S_UTME", utmE),
                    new SqlParameter("@S_UTMN", utmN),
                    new SqlParameter("@TOWN_CODE", townCode),
                    new SqlParameter("@ROAD_LV", roadLv),
                    new SqlParameter("@ROAD_Name", roadName),
                    new SqlParameter("@Smooth", smooth),
                    new SqlParameter("@Cover_Soil", coverSoil),
                    new SqlParameter("@Memo", memoFormatted)
                };

                DbHelper.ExecuteNonQuery(sqlInsert, pars);
            }
            else
            {
                // 編輯更新
                if (string.IsNullOrEmpty(bscId))
                {
                    Response.Write(json.Serialize(new { Success = false, Message = "編輯模式缺少通報案號" }));
                    return;
                }

                string sqlUpdate = @"UPDATE RoadBSC_CaseMain SET 
                    Report_User = @Report_User,
                    S_UTME = @S_UTME,
                    S_UTMN = @S_UTMN,
                    TOWN_CODE = @TOWN_CODE,
                    ROAD_LV = @ROAD_LV,
                    ROAD_Name = @ROAD_Name,
                    Smooth = @Smooth,
                    Cover_Soil = @Cover_Soil,
                    Memo = @Memo
                    WHERE BSC_ID = @BSC_ID";

                SqlParameter[] pars = new SqlParameter[]
                {
                    new SqlParameter("@BSC_ID", bscId),
                    new SqlParameter("@Report_User", currentUser),
                    new SqlParameter("@S_UTME", utmE),
                    new SqlParameter("@S_UTMN", utmN),
                    new SqlParameter("@TOWN_CODE", townCode),
                    new SqlParameter("@ROAD_LV", roadLv),
                    new SqlParameter("@ROAD_Name", roadName),
                    new SqlParameter("@Smooth", smooth),
                    new SqlParameter("@Cover_Soil", coverSoil),
                    new SqlParameter("@Memo", memoFormatted)
                };

                DbHelper.ExecuteNonQuery(sqlUpdate, pars);
            }

            // 處理上傳照片 (Base64 清單)
            if (req.ContainsKey("Photos") && req["Photos"] is ArrayList)
            {
                var photosList = (ArrayList)req["Photos"];
                string targetDir = Server.MapPath("~/Upload/RoadBSCPIC/" + bscId);
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
                Message = (mode == "new" ? "裸露覆土通報單新增成功！" : "裸露覆土通報單更新成功！"),
                BSC_ID = bscId
            }));
        }

        // 4. 刪除指定照片
        private void DeletePhoto(string bscId, string fileName)
        {
            if (string.IsNullOrEmpty(bscId) || string.IsNullOrEmpty(fileName))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "參數不完整" }));
                return;
            }

            // 防止路徑遍歷
            string safeFileName = Path.GetFileName(fileName);
            string targetDir = Server.MapPath("~/Upload/RoadBSCPIC/" + bscId);
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
            double e2 = (e * e) / (1.0 - e * e);

            double x1 = x - dx;
            double y1 = y;

            double M = y1 / k0;
            double mu = M / (a * (1.0 - (e * e) / 4.0 - 3.0 * Math.Pow(e, 4) / 64.0 - 5.0 * Math.Pow(e, 6) / 256.0));
            double e1 = (1.0 - Math.Sqrt(1.0 - e * e)) / (1.0 + Math.Sqrt(1.0 - e * e));

            double J1 = (3.0 * e1 / 2.0 - 27.0 * Math.Pow(e1, 3) / 32.0);
            double J2 = (21.0 * Math.Pow(e1, 2) / 16.0 - 55.0 * Math.Pow(e1, 4) / 32.0);
            double J3 = (151.0 * Math.Pow(e1, 3) / 96.0);
            double J4 = (1097.0 * Math.Pow(e1, 4) / 512.0);

            double fp = mu + J1 * Math.Sin(2.0 * mu) + J2 * Math.Sin(4.0 * mu) + J3 * Math.Sin(6.0 * mu) + J4 * Math.Sin(8.0 * mu);

            double C1 = e2 * Math.Pow(Math.Cos(fp), 2);
            double T1 = Math.Pow(Math.Tan(fp), 2);
            double R1 = a * (1.0 - e * e) / Math.Pow(1.0 - e * e * Math.Pow(Math.Sin(fp), 2), 1.5);
            double N1 = a / Math.Sqrt(1.0 - e * e * Math.Pow(Math.Sin(fp), 2));
            double D = x1 / (N1 * k0);

            double Q1 = N1 * Math.Tan(fp) / R1;
            double Q2 = (D * D / 2.0);
            double Q3 = (5.0 + 3.0 * T1 + 10.0 * C1 - 4.0 * C1 * C1 - 9.0 * e2) * Math.Pow(D, 4) / 24.0;
            double Q4 = (61.0 + 90.0 * T1 + 298.0 * C1 + 45.0 * T1 * T1 - 252.0 * e2 - 3.0 * C1 * C1) * Math.Pow(D, 6) / 720.0;
            double phi = fp - Q1 * (Q2 - Q3 + Q4);

            double Q5 = D;
            double Q6 = (1.0 + 2.0 * T1 + C1) * Math.Pow(D, 3) / 6.0;
            double Q7 = (5.0 - 2.0 * C1 + 28.0 * T1 - 3.0 * C1 * C1 + 8.0 * e2 + 24.0 * T1 * T1) * Math.Pow(D, 5) / 120.0;
            double lambda = lon0 + (Q5 - Q6 + Q7) / Math.Cos(fp);

            lat = phi * 180.0 / Math.PI;
            lon = lambda * 180.0 / Math.PI;
        }

        private static string ComputeMd5(string input)
        {
            using (MD5 md5 = MD5.Create())
            {
                byte[] bytes = Encoding.UTF8.GetBytes(input);
                byte[] hash = md5.ComputeHash(bytes);
                return BitConverter.ToString(hash).Replace("-", string.Empty).ToUpper();
            }
        }
    }
}
