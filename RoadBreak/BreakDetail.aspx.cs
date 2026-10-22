using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.UI;
using NTPC_FEC.Helpers;

namespace NTPC_FEC.RoadBreak
{
    public partial class BreakDetail : Page
    {
        private JavaScriptSerializer json;

        public BreakDetail()
        {
            json = new JavaScriptSerializer();
            json.MaxJsonLength = int.MaxValue;
        }

        // 照片對比模型
        public class PhotoComparisonItem
        {
            public int Index { get; set; }
            public string Title { get; set; }
            public string BeforeTitle { get; set; }
            public string BeforeFileName { get; set; }
            public string BeforeUrl { get; set; }
            public bool BeforeExists { get; set; }
            public long BeforeSize { get; set; }
            public string BeforeTime { get; set; }

            public string AfterTitle { get; set; }
            public string AfterFileName { get; set; }
            public string AfterUrl { get; set; }
            public bool AfterExists { get; set; }
            public long AfterSize { get; set; }
            public string AfterTime { get; set; }

            public PhotoComparisonItem()
            {
                Title = "";
                BeforeTitle = "";
                BeforeFileName = "";
                BeforeUrl = "";
                BeforeTime = "";
                AfterTitle = "";
                AfterFileName = "";
                AfterUrl = "";
                AfterTime = "";
            }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            // 檢查登入狀態
            if (Session["LoginUser"] == null)
            {
                if (Request["action"] != null)
                {
                    Response.Clear();
                    Response.ContentType = "application/json; charset=utf-8";
                    Response.Write(json.Serialize(new { Success = false, Message = "登入逾時，請重新登入系統。", NeedLogin = true }));
                    Response.End();
                    return;
                }
                else
                {
                    Response.Redirect("../Login.aspx");
                    return;
                }
            }

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
                        Message = "伺服器處理錯誤：" + ex.Message
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
                case "getcasedetail":
                    GetCaseDetail(Request["id"]);
                    break;
                default:
                    Response.Write(json.Serialize(new { Success = false, Message = "未知的操作指令：" + action }));
                    break;
            }
        }

        private void GetCaseDetail(string breakId)
        {
            if (string.IsNullOrEmpty(breakId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "案件代碼不能為空。" }));
                return;
            }

            string sql = @"SELECT RoadBreak_CaseMain.*, C_TOWN.TOWN_NA,
                (SELECT TOP 1 Name FROM UserAcc WHERE UserAcc.UserID = RoadBreak_CaseMain.Report_User) AS Report_UserName,
                (SELECT TOP 1 Name FROM UserAcc WHERE UserAcc.UserID = RoadBreak_CaseMain.S_USER) AS S_UserName,
                (SELECT TOP 1 Name FROM UserAcc WHERE UserAcc.UserID = RoadBreak_CaseMain.G_USER) AS G_UserName,
                (SELECT TOP 1 UnitName FROM RoadBreak_Unit WHERE RoadBreak_Unit.UnitID = RoadBreak_CaseMain.S_COM) AS S_COM_NAME,
                (SELECT TOP 1 UnitName FROM RoadBreak_Unit WHERE RoadBreak_Unit.UnitID = RoadBreak_CaseMain.G_COM) AS G_COM_NAME,
                (SELECT TOP 1 Val FROM Dictionary WHERE Dictionary.CodeType = 'RoadBreak_Smooth' AND Dictionary.Code = RoadBreak_CaseMain.Smooth) AS Smooth_Str,
                (SELECT TOP 1 Val FROM Dictionary WHERE Dictionary.CodeType = 'RoadBreak_Hole_Conn_St' AND Dictionary.Code = RoadBreak_CaseMain.Hole_Conn_St) AS Hole_Conn_St_Str
            FROM RoadBreak_CaseMain
            LEFT JOIN C_TOWN ON RoadBreak_CaseMain.TOWN_CODE = C_TOWN.TOWN_NO
            WHERE Break_ID = @id";

            DataTable dt = DbHelper.ExecuteDataTable(sql, new SqlParameter("@id", breakId));
            if (dt.Rows.Count == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "找不到該案件資料（代碼：" + breakId + "）" }));
                return;
            }

            DataRow r = dt.Rows[0];

            // 坐標轉換 TWD97 -> WGS84
            double utmE = 0;
            double utmN = 0;
            double lat = 0;
            double lon = 0;
            if (r["S_UTME"] != DBNull.Value)
            {
                double.TryParse(r["S_UTME"].ToString(), out utmE);
            }
            if (r["S_UTMN"] != DBNull.Value)
            {
                double.TryParse(r["S_UTMN"].ToString(), out utmN);
            }
            if (r.Table.Columns.Contains("Lat") && r["Lat"] != DBNull.Value) double.TryParse(r["Lat"].ToString(), out lat);
            if (r.Table.Columns.Contains("Lon") && r["Lon"] != DBNull.Value) double.TryParse(r["Lon"].ToString(), out lon);
            if ((lat <= 0 || lon <= 0) && utmE > 0 && utmN > 0)
            {
                Twd97ToWgs84(utmE, utmN, out lat, out lon);
            }

            // 日期時間格式化
            string reportDateStr = "";
            if (r["Report_Date"] != DBNull.Value)
            {
                DateTime dtRep;
                if (DateTime.TryParse(r["Report_Date"].ToString(), out dtRep))
                {
                    reportDateStr = dtRep.ToString("yyyy-MM-dd HH:mm");
                }
            }

            string setComDateStr = "";
            if (r["SetCOM_Date"] != DBNull.Value)
            {
                DateTime dtSet;
                if (DateTime.TryParse(r["SetCOM_Date"].ToString(), out dtSet))
                {
                    setComDateStr = dtSet.ToString("yyyy-MM-dd HH:mm");
                }
            }

            string improveDateStr = "";
            if (r["Improve_Date"] != DBNull.Value)
            {
                DateTime dtImp;
                if (DateTime.TryParse(r["Improve_Date"].ToString(), out dtImp))
                {
                    improveDateStr = dtImp.ToString("yyyy-MM-dd HH:mm");
                }
            }

            // 狀態與階段判定
            string gBack = r["G_Back"] != DBNull.Value ? r["G_Back"].ToString().Trim() : "";
            string gCom = r["G_COM"] != DBNull.Value ? r["G_COM"].ToString().Trim() : "";
            string statusCode = "REPORTED";
            string statusText = "新通報 (待派工)";
            string statusBadgeClass = "badge-primary";

            if (gBack == "Y")
            {
                statusCode = "REJECTED";
                statusText = "非權責單位退回";
                statusBadgeClass = "badge-danger";
            }
            else if (!string.IsNullOrEmpty(improveDateStr))
            {
                statusCode = "IMPROVED";
                statusText = "已改善完成";
                statusBadgeClass = "badge-success";
            }
            else if (!string.IsNullOrEmpty(gCom))
            {
                statusCode = "DISPATCHED";
                statusText = "處理中 (待改善)";
                statusBadgeClass = "badge-warning text-dark";
            }

            // 類別說明
            string kindCode = r["KIND"] != DBNull.Value ? r["KIND"].ToString().Trim() : "";
            string kindName = "道路髒污破損(RD)";
            if (kindCode == "RD")
            {
                kindName = "道路髒污破損(RD)";
            }
            else if (!string.IsNullOrEmpty(kindCode))
            {
                kindName = kindCode;
            }

            var caseData = new
            {
                Break_ID = r["Break_ID"].ToString().Trim(),
                Show_ID = r["Show_ID"] != DBNull.Value ? r["Show_ID"].ToString().Trim() : r["Break_ID"].ToString().Trim(),
                Report_Date = reportDateStr,
                Report_User = r["Report_User"].ToString(),
                Report_UserName = r["Report_UserName"].ToString(),
                S_COM = r["S_COM"].ToString(),
                S_COM_NAME = r["S_COM_NAME"].ToString(),
                SetCOM_Date = setComDateStr,
                S_USER = r["S_USER"].ToString(),
                S_UserName = r["S_UserName"].ToString(),
                KIND = kindCode,
                KIND_Name = kindName,
                S_UTME = utmE > 0 ? utmE.ToString("0.00") : "",
                S_UTMN = utmN > 0 ? utmN.ToString("0.00") : "",
                Lat = lat > 0 ? lat : 0,
                Lng = lon > 0 ? lon : 0,
                TOWN_CODE = r["TOWN_CODE"].ToString(),
                TOWN_NA = r["TOWN_NA"].ToString(),
                ROAD_LV = r["ROAD_LV"].ToString(),
                ROAD_Name = r["ROAD_Name"].ToString(),
                Smooth = r["Smooth"].ToString(),
                Smooth_Str = r["Smooth_Str"].ToString(),
                Hole_Conn_St = r["Hole_Conn_St"].ToString(),
                Hole_Conn_St_Str = r["Hole_Conn_St_Str"].ToString(),
                Memo = r["Memo"].ToString(),
                G_COM = r["G_COM"].ToString(),
                G_COM_NAME = r["G_COM_NAME"].ToString(),
                Improve_Date = improveDateStr,
                G_USER = r["G_USER"].ToString(),
                G_UserName = r["G_UserName"].ToString(),
                G_Memo = r["G_Memo"].ToString(),
                G_Back = gBack,
                StatusCode = statusCode,
                StatusText = statusText,
                StatusBadgeClass = statusBadgeClass
            };

            // 讀取現場佐證照片與改善後照片
            List<PhotoComparisonItem> comparisonList = LoadPhotoComparisonList(breakId);

            // 使用者操作權限
            string loginUser = Session["LoginUser"] != null ? Session["LoginUser"].ToString() : "";
            string userRole = Session["Role"] != null ? Session["Role"].ToString() : "";
            string userUnit = Session["UnitID"] != null ? Session["UnitID"].ToString() : "";

            bool canEdit = (userRole == "Admin" || caseData.Report_User == loginUser || caseData.S_USER == loginUser);
            bool canDispatch = (userRole == "Admin" || userRole == "EPD" || userRole == "Manager");
            bool canImprove = (userRole == "Admin" || (!string.IsNullOrEmpty(caseData.G_COM) && caseData.G_COM == userUnit));

            var userPerms = new
            {
                CanEdit = canEdit,
                CanDispatch = canDispatch,
                CanImprove = canImprove,
                LoginUser = loginUser,
                UserRole = userRole,
                UserUnit = userUnit
            };

            Response.Write(json.Serialize(new
            {
                Success = true,
                Case = caseData,
                Photos = comparisonList,
                UserPerms = userPerms
            }));
        }

        // 讀取與匹配照片對比清單
        private List<PhotoComparisonItem> LoadPhotoComparisonList(string breakId)
        {
            List<PhotoComparisonItem> list = new List<PhotoComparisonItem>();
            string picDir = Server.MapPath("~/Upload/RoadBreakPIC/" + breakId);

            if (!Directory.Exists(picDir))
            {
                return list;
            }

            DirectoryInfo dir = new DirectoryInfo(picDir);
            FileInfo[] allFiles = dir.GetFiles();

            // 篩選佐證照片
            var beforeFiles = allFiles
                .Where(new Func<FileInfo, bool>(delegate(FileInfo f) {
                    string name = f.Name;
                    return name.IndexOf("佐證照片") >= 0 && name.IndexOf("改善後") < 0;
                }))
                .OrderBy(new Func<FileInfo, string>(delegate(FileInfo f) { return f.Name; }))
                .ToList();

            // 篩選改善後佐證照片
            var afterFiles = allFiles
                .Where(new Func<FileInfo, bool>(delegate(FileInfo f) {
                    string name = f.Name;
                    return name.IndexOf("改善後") >= 0;
                }))
                .OrderBy(new Func<FileInfo, string>(delegate(FileInfo f) { return f.Name; }))
                .ToList();

            // 先以佐證照片為基準進行配對
            int index = 1;
            HashSet<string> matchedAfterFiles = new HashSet<string>();

            foreach (FileInfo bf in beforeFiles)
            {
                string baseName = Path.GetFileNameWithoutExtension(bf.Name);
                string numStr = baseName.Replace("佐證照片_", "").Replace("佐證照片", "");

                // 嘗試尋找對應編號的改善照片
                FileInfo matchAfter = null;
                foreach (FileInfo af in afterFiles)
                {
                    string afBase = Path.GetFileNameWithoutExtension(af.Name);
                    if (afBase == "改善後佐證照片_" + numStr || 
                        afBase == "改善後_" + numStr || 
                        afBase == baseName.Replace("佐證照片", "改善後佐證照片"))
                    {
                        matchAfter = af;
                        break;
                    }
                }

                // 若沒精確符合且順序數量一致，嘗試按索引匹配
                if (matchAfter == null && (index - 1) < afterFiles.Count)
                {
                    FileInfo candidate = afterFiles[index - 1];
                    if (!matchedAfterFiles.Contains(candidate.FullName))
                    {
                        matchAfter = candidate;
                    }
                }

                PhotoComparisonItem item = new PhotoComparisonItem();
                item.Index = index;
                item.Title = "查核點位照片 " + index;
                item.BeforeTitle = "現場佐證照片 " + index;
                item.BeforeFileName = bf.Name;
                item.BeforeUrl = "../Upload/RoadBreakPIC/" + breakId + "/" + bf.Name;
                item.BeforeExists = true;
                item.BeforeSize = bf.Length;
                item.BeforeTime = bf.LastWriteTime.ToString("yyyy-MM-dd HH:mm");

                if (matchAfter != null)
                {
                    matchedAfterFiles.Add(matchAfter.FullName);
                    item.AfterTitle = "改善後照片 " + index;
                    item.AfterFileName = matchAfter.Name;
                    item.AfterUrl = "../Upload/RoadBreakPIC/" + breakId + "/" + matchAfter.Name;
                    item.AfterExists = true;
                    item.AfterSize = matchAfter.Length;
                    item.AfterTime = matchAfter.LastWriteTime.ToString("yyyy-MM-dd HH:mm");
                }
                else
                {
                    item.AfterTitle = "改善後照片 " + index;
                    item.AfterFileName = "";
                    item.AfterUrl = "";
                    item.AfterExists = false;
                    item.AfterSize = 0;
                    item.AfterTime = "";
                }

                list.Add(item);
                index++;
            }

            // 處理剩下尚未被配對的改善照片
            foreach (FileInfo af in afterFiles)
            {
                if (!matchedAfterFiles.Contains(af.FullName))
                {
                    PhotoComparisonItem extraItem = new PhotoComparisonItem();
                    extraItem.Index = index;
                    extraItem.Title = "改善成果補充照片 " + index;
                    extraItem.BeforeTitle = "現場佐證照片";
                    extraItem.BeforeFileName = "";
                    extraItem.BeforeUrl = "";
                    extraItem.BeforeExists = false;
                    extraItem.BeforeSize = 0;
                    extraItem.BeforeTime = "";

                    extraItem.AfterTitle = "改善後照片 " + index;
                    extraItem.AfterFileName = af.Name;
                    extraItem.AfterUrl = "../Upload/RoadBreakPIC/" + breakId + "/" + af.Name;
                    extraItem.AfterExists = true;
                    extraItem.AfterSize = af.Length;
                    extraItem.AfterTime = af.LastWriteTime.ToString("yyyy-MM-dd HH:mm");

                    list.Add(extraItem);
                    index++;
                }
            }

            return list;
        }

        // TWD97 轉 WGS84 標準演算法 (二度分帶逆算)
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
    }
}
