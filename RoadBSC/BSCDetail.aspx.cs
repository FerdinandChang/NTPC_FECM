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
    public partial class BSCDetail : Page
    {
        private JavaScriptSerializer json;

        public BSCDetail()
        {
            json = new JavaScriptSerializer();
            json.MaxJsonLength = int.MaxValue;
        }

        public class PhotoPairModel
        {
            public int PairIndex { get; set; }
            public string Title { get; set; }
            public string BeforeFileName { get; set; }
            public string BeforeUrl { get; set; }
            public bool BeforeExists { get; set; }
            public long BeforeSize { get; set; }
            public string AfterFileName { get; set; }
            public string AfterUrl { get; set; }
            public bool AfterExists { get; set; }
            public long AfterSize { get; set; }
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
            switch (action.ToLower())
            {
                case "getdetail":
                    GetCaseDetail();
                    break;
                default:
                    Response.Write(json.Serialize(new { Success = false, Message = "未知的操作指令：" + action }));
                    break;
            }
        }

        // 取得通報案件之完整詳細資訊
        private void GetCaseDetail()
        {
            string bscId = Request["id"];
            if (bscId != null) bscId = bscId.Trim();

            if (string.IsNullOrEmpty(bscId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "未提供通報案號參數 (?id=)" }));
                return;
            }

            // 安全校驗碼 Token 檢驗 (容許今日與昨日跨午夜容錯)
            string token = Request["chk"];
            if (!string.IsNullOrEmpty(token))
            {
                string todayStr = DateTime.Now.ToString("yyyy-MM-dd");
                string yesterdayStr = DateTime.Now.AddDays(-1).ToString("yyyy-MM-dd");
                string expectedTokenToday = ComputeMd5("DetailBSC_" + bscId + "_" + todayStr);
                string expectedTokenYesterday = ComputeMd5("DetailBSC_" + bscId + "_" + yesterdayStr);

                if (!string.Equals(token, expectedTokenToday, StringComparison.OrdinalIgnoreCase) &&
                    !string.Equals(token, expectedTokenYesterday, StringComparison.OrdinalIgnoreCase))
                {
                    // 若 Session 中已登入有效用戶則允許通行，否則阻擋非授權請求
                    if (Session["LoginUser"] == null && (User == null || User.Identity == null || !User.Identity.IsAuthenticated))
                    {
                        Response.Write(json.Serialize(new { Success = false, Message = "安全校驗碼無效或已過期，請由通報清單重新開啟。" }));
                        return;
                    }
                }
            }

            string sql = @"
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
                    m.S_COM,
                    m.G_COM,
                    uS.UnitName AS S_COM_NAME,
                    uG.UnitName AS G_COM_NAME,
                    m.Improve_Date,
                    m.G_User,
                    m.G_Memo,
                    m.G_Back,
                    uRep.Name AS Report_UserName,
                    uSend.Name AS S_UserName,
                    uGov.Name AS G_UserName
                FROM RoadBSC_CaseMain m
                LEFT JOIN C_TOWN t ON t.TOWN_NO = m.TOWN_CODE
                LEFT JOIN RoadBSC_Unit uS ON uS.UnitID = m.S_COM
                LEFT JOIN RoadBSC_Unit uG ON uG.UnitID = m.G_COM
                LEFT JOIN UserAcc uRep ON uRep.UserID = m.Report_User
                LEFT JOIN UserAcc uSend ON uSend.UserID = m.S_User
                LEFT JOIN UserAcc uGov ON uGov.UserID = m.G_User
                LEFT JOIN Dictionary dSmooth ON dSmooth.CodeType = 'RoadBSC_Smooth' AND dSmooth.Code = m.Smooth
                LEFT JOIN Dictionary dCover ON dCover.CodeType = 'RoadBSC_Cover_Soil' AND dCover.Code = m.Cover_Soil
                WHERE m.BSC_ID = @id";

            DataTable dt = DbHelper.ExecuteDataTable(sql, new SqlParameter("@id", bscId));
            if (dt.Rows.Count == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "查無此人行道與交通島裸露覆土案件：" + bscId }));
                return;
            }

            DataRow row = dt.Rows[0];

            // 1. 日期格式化
            string rptDateStr = "";
            if (row["Report_Date"] != DBNull.Value)
            {
                rptDateStr = Convert.ToDateTime(row["Report_Date"]).ToString("yyyy-MM-dd HH:mm");
            }

            string setComDateStr = "";
            if (row["SetCOM_Date"] != DBNull.Value)
            {
                setComDateStr = Convert.ToDateTime(row["SetCOM_Date"]).ToString("yyyy-MM-dd HH:mm");
            }

            string improveDateStr = "";
            if (row["Improve_Date"] != DBNull.Value)
            {
                improveDateStr = Convert.ToDateTime(row["Improve_Date"]).ToString("yyyy-MM-dd HH:mm");
            }

            // 2. 座標轉換 (TWD97 轉 WGS84)
            double utmE = 0;
            double utmN = 0;
            if (row["S_UTME"] != DBNull.Value) double.TryParse(row["S_UTME"].ToString(), out utmE);
            if (row["S_UTMN"] != DBNull.Value) double.TryParse(row["S_UTMN"].ToString(), out utmN);

            double lat = 0;
            double lon = 0;
            if (utmE > 0 && utmN > 0)
            {
                Twd97ToWgs84(utmE, utmN, out lat, out lon);
            }

            // 3. 計算案件階段狀態與退回標記
            // StatusCode: 1=暫存未派工, 2=已派工待改善, 3=改善完成結案
            int statusCode = 1;
            string statusText = "暫存未派工";
            string statusBadgeClass = "badge-secondary";

            bool isSetCom = (row["SetCOM_Date"] != DBNull.Value);
            bool isImproved = (row["Improve_Date"] != DBNull.Value);

            string gBack = row.Table.Columns.Contains("G_Back") && row["G_Back"] != DBNull.Value ? row["G_Back"].ToString().Trim() : "N";
            bool isBack = (gBack == "Y");

            if (isSetCom)
            {
                if (!isImproved)
                {
                    statusCode = 2;
                    statusText = isBack ? "案件退回待重派" : "待改善回報";
                    statusBadgeClass = isBack ? "badge-danger" : "badge-warning";
                }
                else
                {
                    statusCode = 3;
                    statusText = "改善完成結案";
                    statusBadgeClass = "badge-success";
                }
            }

            // 4. 平整度與覆土中文名稱 Fallback 處理
            string smoothName = row["SmoothName"] != DBNull.Value ? row["SmoothName"].ToString().Trim() : GetFallbackSmoothName(row["Smooth"]);
            string coverSoilName = row["CoverSoilName"] != DBNull.Value ? row["CoverSoilName"].ToString().Trim() : GetFallbackCoverSoilName(row["Cover_Soil"]);

            // 5. 備註清理
            string memo = row["Memo"] != DBNull.Value ? row["Memo"].ToString() : "";
            string gMemo = row["G_Memo"] != DBNull.Value ? row["G_Memo"].ToString() : "";

            // 6. 讀取佐證與改善後照片並配對
            List<PhotoPairModel> photoPairs = GetPhotoPairs(bscId);

            // 7. 計算操作 URL 與 Token
            string todayForUrl = DateTime.Now.ToString("yyyy-MM-dd");
            string editToken = ComputeMd5("EditBSC_" + bscId + "_" + todayForUrl);
            string setSgToken = ComputeMd5("SetSGBSC_" + bscId + "_" + todayForUrl);
            string improveToken = ComputeMd5("ImproveBSC_" + bscId + "_" + todayForUrl);
            string parMode = Request["parmode"];
            if (string.IsNullOrEmpty(parMode)) parMode = "BSCEdit";

            var detail = new
            {
                BSC_ID = bscId,
                Show_ID = row["Show_ID"].ToString().Trim(),
                Report_Date = rptDateStr,
                Report_User = row["Report_User"] != DBNull.Value ? row["Report_User"].ToString().Trim() : "",
                Report_UserName = row["Report_UserName"] != DBNull.Value ? row["Report_UserName"].ToString().Trim() : (row["Report_User"] != DBNull.Value ? row["Report_User"].ToString().Trim() : ""),
                TOWN_CODE = row["TOWN_CODE"] != DBNull.Value ? row["TOWN_CODE"].ToString().Trim() : "",
                TownName = row["TownName"] != DBNull.Value ? row["TownName"].ToString().Trim() : "",
                ROAD_LV = row["ROAD_LV"] != DBNull.Value ? row["ROAD_LV"].ToString().Trim() : "",
                ROAD_Name = row["ROAD_Name"] != DBNull.Value ? row["ROAD_Name"].ToString().Trim() : "",
                Smooth = row["Smooth"] != DBNull.Value ? row["Smooth"].ToString().Trim() : "",
                SmoothName = smoothName,
                Cover_Soil = row["Cover_Soil"] != DBNull.Value ? row["Cover_Soil"].ToString().Trim() : "",
                CoverSoilName = coverSoilName,
                Memo = memo,
                S_UTME = utmE > 0 ? utmE.ToString("0") : "",
                S_UTMN = utmN > 0 ? utmN.ToString("0") : "",
                Lat = lat > 0 ? lat.ToString("F6") : "",
                Lon = lon > 0 ? lon.ToString("F6") : "",
                SetCOM_Date = setComDateStr,
                S_User = row["S_User"] != DBNull.Value ? row["S_User"].ToString().Trim() : "",
                S_UserName = row["S_UserName"] != DBNull.Value ? row["S_UserName"].ToString().Trim() : "",
                S_COM = row["S_COM"] != DBNull.Value ? row["S_COM"].ToString().Trim() : "",
                S_COM_NAME = row["S_COM_NAME"] != DBNull.Value ? row["S_COM_NAME"].ToString().Trim() : "",
                G_COM = row["G_COM"] != DBNull.Value ? row["G_COM"].ToString().Trim() : "",
                G_COM_NAME = row["G_COM_NAME"] != DBNull.Value ? row["G_COM_NAME"].ToString().Trim() : "",
                Improve_Date = improveDateStr,
                G_User = row["G_User"] != DBNull.Value ? row["G_User"].ToString().Trim() : "",
                G_UserName = row["G_UserName"] != DBNull.Value ? row["G_UserName"].ToString().Trim() : "",
                G_Memo = gMemo,
                G_Back = gBack,
                IsBack = isBack,
                StatusCode = statusCode,
                StatusText = statusText,
                StatusBadgeClass = statusBadgeClass,
                PhotoPairs = photoPairs,
                EditUrl = "NewBSC.aspx?id=" + bscId + "&chk=" + editToken + "&mode=edit",
                SetSGUrl = "SetSG_BSC.aspx?id=" + bscId + "&chk=" + setSgToken,
                ImproveUrl = "ImproveBSC.aspx?id=" + bscId + "&chk=" + improveToken,
                BackListUrl = "BSC_List.aspx?mode=" + HttpUtility.UrlEncode(parMode)
            };

            Response.Write(json.Serialize(new
            {
                Success = true,
                Data = detail
            }));
        }

        // 讀取硬碟目錄並成對匹配改善前佐證照片與改善後照片
        private List<PhotoPairModel> GetPhotoPairs(string bscId)
        {
            var pairs = new List<PhotoPairModel>();
            string relDir = "/Upload/RoadBSCPIC/" + bscId + "/";
            string physDir = Server.MapPath("~" + relDir);

            if (!Directory.Exists(physDir))
            {
                return pairs;
            }

            DirectoryInfo di = new DirectoryInfo(physDir);

            // 1. 抓出所有改善前照片 (佐證照片*.*)
            FileInfo[] beforeFiles = di.GetFiles("佐證照片*.*");
            Array.Sort(beforeFiles, delegate(FileInfo a, FileInfo b) { return string.Compare(a.Name, b.Name, StringComparison.OrdinalIgnoreCase); });

            // 2. 抓出所有改善後照片 (改善後佐證照片*.* 或 改善後照片*.*)
            FileInfo[] afterFiles1 = di.GetFiles("改善後佐證照片*.*");
            FileInfo[] afterFiles2 = di.GetFiles("改善後照片*.*");
            List<FileInfo> allAfterFiles = new List<FileInfo>();
            allAfterFiles.AddRange(afterFiles1);
            allAfterFiles.AddRange(afterFiles2);

            HashSet<string> matchedAfterNames = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

            int pairIndex = 1;
            foreach (FileInfo bf in beforeFiles)
            {
                string ext = bf.Extension.ToLower();
                if (ext != ".jpg" && ext != ".jpeg" && ext != ".png" && ext != ".gif") continue;

                var pair = new PhotoPairModel();
                pair.PairIndex = pairIndex;
                pair.Title = "查核點位照片 #" + pairIndex;
                pair.BeforeFileName = bf.Name;
                pair.BeforeUrl = ".." + relDir + bf.Name;
                pair.BeforeExists = true;
                pair.BeforeSize = bf.Length;

                // 嘗試比對改善後照片：
                // 優先比對包含序號者，如 改善後佐證照片_{pairIndex}.* 或 改善後照片_{pairIndex}.*
                FileInfo matchedAfter = null;
                string targetNumPattern = "_" + pairIndex + ".";

                foreach (FileInfo af in allAfterFiles)
                {
                    if (af.Name.IndexOf(targetNumPattern, StringComparison.OrdinalIgnoreCase) >= 0)
                    {
                        matchedAfter = af;
                        break;
                    }
                }

                // 若序號比對無果且同序號索引有檔案
                if (matchedAfter == null && (pairIndex - 1) < allAfterFiles.Count)
                {
                    FileInfo candidate = allAfterFiles[pairIndex - 1];
                    if (!matchedAfterNames.Contains(candidate.Name))
                    {
                        matchedAfter = candidate;
                    }
                }

                if (matchedAfter != null)
                {
                    matchedAfterNames.Add(matchedAfter.Name);
                    pair.AfterFileName = matchedAfter.Name;
                    pair.AfterUrl = ".." + relDir + matchedAfter.Name;
                    pair.AfterExists = true;
                    pair.AfterSize = matchedAfter.Length;
                }
                else
                {
                    pair.AfterFileName = "";
                    pair.AfterUrl = "";
                    pair.AfterExists = false;
                    pair.AfterSize = 0;
                }

                pairs.Add(pair);
                pairIndex++;
            }

            // 若還有未匹配上的多餘改善後照片，亦獨立補充成組
            foreach (FileInfo af in allAfterFiles)
            {
                if (!matchedAfterNames.Contains(af.Name))
                {
                    string ext = af.Extension.ToLower();
                    if (ext != ".jpg" && ext != ".jpeg" && ext != ".png" && ext != ".gif") continue;

                    var extraPair = new PhotoPairModel();
                    extraPair.PairIndex = pairIndex;
                    extraPair.Title = "改善後單獨照片 #" + pairIndex;
                    extraPair.BeforeFileName = "";
                    extraPair.BeforeUrl = "";
                    extraPair.BeforeExists = false;
                    extraPair.BeforeSize = 0;
                    extraPair.AfterFileName = af.Name;
                    extraPair.AfterUrl = ".." + relDir + af.Name;
                    extraPair.AfterExists = true;
                    extraPair.AfterSize = af.Length;

                    pairs.Add(extraPair);
                    pairIndex++;
                }
            }

            return pairs;
        }

        private static string GetFallbackSmoothName(object codeObj)
        {
            if (codeObj == null || codeObj == DBNull.Value) return "";
            string c = codeObj.ToString().Trim();
            if (c == "1") return "平整良好無損";
            if (c == "2") return "輕微破損/不平整";
            if (c == "3") return "磚面鬆動/破損下陷";
            if (c == "4") return "嚴重坑洞/破損";
            if (c == "5") return "其他";
            return c;
        }

        private static string GetFallbackCoverSoilName(object codeObj)
        {
            if (codeObj == null || codeObj == DBNull.Value) return "";
            string c = codeObj.ToString().Trim();
            if (c == "1") return "植生良好無覆土";
            if (c == "2") return "局部覆土裸露 (< 5m²)";
            if (c == "3") return "大面積覆土裸露 (>= 5m²)";
            if (c == "4") return "土石堆置或溢散至車道";
            if (c == "5") return "其他";
            return c;
        }

        // TWD97 二度分帶轉 WGS84 經緯度標準演算法 (完全符合 C# 5.0 語法規範)
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

        private static string ComputeMd5(string input)
        {
            using (MD5 md5 = MD5.Create())
            {
                byte[] bytes = md5.ComputeHash(Encoding.UTF8.GetBytes(input));
                StringBuilder sb = new StringBuilder();
                for (int i = 0; i < bytes.Length; i++)
                {
                    sb.Append(bytes[i].ToString("x2"));
                }
                return sb.ToString();
            }
        }
    }
}