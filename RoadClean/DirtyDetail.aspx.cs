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
    public partial class DirtyDetail : Page
    {
        private JavaScriptSerializer json = new JavaScriptSerializer { MaxJsonLength = int.MaxValue };

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
                case "getdetail":
                    GetCaseDetail();
                    break;
                default:
                    Response.Write(json.Serialize(new { Success = false, Message = "未知的操作指令" }));
                    break;
            }
        }

        // 取得通報案件之完整詳細資訊
        private void GetCaseDetail()
        {
            string dirtyId = Request["id"];
            if (dirtyId != null) dirtyId = dirtyId.Trim();

            if (string.IsNullOrEmpty(dirtyId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "缺少通報案號參數" }));
                return;
            }

            string sql = @"
                SELECT 
                    RoadDirty_CaseMain.*,
                    (SELECT TOP 1 Name FROM UserAcc WHERE UserAcc.UserID = RoadDirty_CaseMain.Report_User) AS Report_UserName,
                    (SELECT TOP 1 Name FROM UserAcc WHERE UserAcc.UserID = RoadDirty_CaseMain.S_User) AS S_UserName,
                    (SELECT TOP 1 Name FROM UserAcc WHERE UserAcc.UserID = RoadDirty_CaseMain.G_User) AS G_UserName,
                    (SELECT TOP 1 UnitName FROM RoadDirty_Unit WHERE RoadDirty_Unit.UnitID = RoadDirty_CaseMain.S_COM) AS S_COM_NAME,
                    (SELECT TOP 1 UnitName FROM RoadDirty_Unit WHERE RoadDirty_Unit.UnitID = RoadDirty_CaseMain.G_COM) AS G_COM_NAME,
                    CASE 
                        WHEN KIND = 'EB' THEN '營建工程道路污染 (EB)' 
                        WHEN KIND = 'EF' THEN '固定逸散道路污染 (EF)' 
                        WHEN KIND = 'ES' THEN '道路砂石堆積污染 (ES)' 
                        WHEN KIND = 'OS' THEN '其他類別-商店 (OS)' 
                        WHEN KIND = 'OR' THEN '其他類別-人行道破損 (OR)' 
                        ELSE '其他逸散源污染' 
                    END AS KIND_Name,
                    CASE 
                        WHEN Show_ID IS NULL OR Show_ID = '' THEN Dirty_ID 
                        ELSE Show_ID 
                    END AS Show_ID_Txt
                FROM RoadDirty_CaseMain 
                WHERE Dirty_ID = @id";

            DataTable dt = DbHelper.ExecuteDataTable(sql, new SqlParameter("@id", dirtyId));
            if (dt.Rows.Count == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "查無此通報案件紀錄：" + dirtyId }));
                return;
            }

            DataRow row = dt.Rows[0];

            // 1. 日期格式轉換
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
            double utmE1 = 0;
            double utmN1 = 0;

            if (row["S_UTME"] != DBNull.Value) double.TryParse(row["S_UTME"].ToString(), out utmE);
            if (row["S_UTMN"] != DBNull.Value) double.TryParse(row["S_UTMN"].ToString(), out utmN);
            if (row.Table.Columns.Contains("S_UTME1") && row["S_UTME1"] != DBNull.Value) double.TryParse(row["S_UTME1"].ToString(), out utmE1);
            if (row.Table.Columns.Contains("S_UTMN1") && row["S_UTMN1"] != DBNull.Value) double.TryParse(row["S_UTMN1"].ToString(), out utmN1);

            double lat0 = 0, lon0 = 0;
            if (row.Table.Columns.Contains("Lat") && row["Lat"] != DBNull.Value) double.TryParse(row["Lat"].ToString(), out lat0);
            if (row.Table.Columns.Contains("Lon") && row["Lon"] != DBNull.Value) double.TryParse(row["Lon"].ToString(), out lon0);
            if ((lat0 <= 0 || lon0 <= 0) && utmE > 0 && utmN > 0)
            {
                Twd97ToWgs84(utmE, utmN, out lat0, out lon0);
            }

            double lat1 = 0, lon1 = 0;
            if (row.Table.Columns.Contains("Lat1") && row["Lat1"] != DBNull.Value) double.TryParse(row["Lat1"].ToString(), out lat1);
            if (row.Table.Columns.Contains("Lon1") && row["Lon1"] != DBNull.Value) double.TryParse(row["Lon1"].ToString(), out lon1);
            if ((lat1 <= 0 || lon1 <= 0) && utmE1 > 0 && utmN1 > 0)
            {
                Twd97ToWgs84(utmE1, utmN1, out lat1, out lon1);
            }

            // 3. 計算案件階段狀態：1=暫存未通報, 2=已通報待改善, 3=改善完成結案
            int statusCode = 1;
            string statusText = "暫存未通報";
            string statusBadgeClass = "badge-secondary";

            if (row["SetCOM_Date"] != DBNull.Value)
            {
                if (row["Improve_Date"] == DBNull.Value)
                {
                    statusCode = 2;
                    statusText = "待改善回報";
                    statusBadgeClass = "badge-warning";
                }
                else
                {
                    statusCode = 3;
                    statusText = "已完成改善";
                    statusBadgeClass = "badge-success";
                }
            }

            // 4. 讀取磁碟照片並組成「改善前 / 改善後」對照清單
            List<PhotoPairModel> sitePhotoPairs = GetPhotoPairs(dirtyId, "疑似髒污點現場照片", "髒污點改善後照片", "改善後照片");
            List<PhotoPairModel> evidencePhotoPairs = GetPhotoPairs(dirtyId, "佐證照片", "改善後佐證照片", "");

            string gBack = row.Table.Columns.Contains("G_Back") && row["G_Back"] != DBNull.Value
                ? row["G_Back"].ToString().Trim()
                : "N";

            string sComName = row.Table.Columns.Contains("S_COM_NAME") && row["S_COM_NAME"] != DBNull.Value
                ? row["S_COM_NAME"].ToString().Trim()
                : "";

            string gComName = row.Table.Columns.Contains("G_COM_NAME") && row["G_COM_NAME"] != DBNull.Value
                ? row["G_COM_NAME"].ToString().Trim()
                : "";

            var detail = new
            {
                DirtyId = row["Dirty_ID"].ToString().Trim(),
                ShowId = row["Show_ID_Txt"].ToString().Trim(),
                Comm = row["COMM"] != DBNull.Value ? row["COMM"].ToString() : "",
                Kind = row["KIND"] != DBNull.Value ? row["KIND"].ToString().Trim() : "",
                KindName = row["KIND_Name"].ToString(),
                ReportDate = rptDateStr,
                ReportUser = row["Report_User"] != DBNull.Value ? row["Report_User"].ToString().Trim() : "",
                ReportUserName = row["Report_UserName"] != DBNull.Value ? row["Report_UserName"].ToString().Trim() : (row["Report_User"] != DBNull.Value ? row["Report_User"].ToString().Trim() : ""),
                SetComDate = setComDateStr,
                S_User = row["S_User"] != DBNull.Value ? row["S_User"].ToString().Trim() : "",
                S_UserName = row["S_UserName"] != DBNull.Value ? row["S_UserName"].ToString().Trim() : "",
                S_ComName = sComName,
                G_Com = row["G_COM"] != DBNull.Value ? row["G_COM"].ToString().Trim() : "",
                G_ComName = gComName,
                ImproveDate = improveDateStr,
                G_User = row["G_User"] != DBNull.Value ? row["G_User"].ToString().Trim() : "",
                G_UserName = row["G_UserName"] != DBNull.Value ? row["G_UserName"].ToString().Trim() : "",
                G_Memo = row.Table.Columns.Contains("G_MEMO") && row["G_MEMO"] != DBNull.Value ? row["G_MEMO"].ToString() : "",
                G_Back = gBack,
                StatusCode = statusCode,
                StatusText = statusText,
                StatusBadgeClass = statusBadgeClass,
                S_UTME = utmE,
                S_UTMN = utmN,
                S_UTME1 = utmE1,
                S_UTMN1 = utmN1,
                Lat = lat0,
                Lon = lon0,
                Lat1 = lat1,
                Lon1 = lon1,
                SitePhotoPairs = sitePhotoPairs,
                EvidencePhotoPairs = evidencePhotoPairs
            };

            Response.Write(json.Serialize(new
            {
                Success = true,
                Data = detail
            }));
        }

        // 讀取硬碟目錄並成對匹配改善前與改善後照片
        private List<PhotoPairModel> GetPhotoPairs(string dirtyId, string beforePrefix, string afterPrefix1, string afterPrefix2)
        {
            var pairs = new List<PhotoPairModel>();
            string relDir = "/Upload/RoadDirtyPIC/" + dirtyId + "/";
            string physDir = Server.MapPath("~" + relDir);

            if (!Directory.Exists(physDir))
            {
                return pairs;
            }

            DirectoryInfo di = new DirectoryInfo(physDir);

            // 1. 抓出所有符合 beforePrefix 的照片
            FileInfo[] beforeFiles = di.GetFiles(beforePrefix + "*.*");
            Array.Sort(beforeFiles, delegate(FileInfo a, FileInfo b) { return a.Name.CompareTo(b.Name); });

            int pairIndex = 1;
            foreach (FileInfo bf in beforeFiles)
            {
                string ext = bf.Extension.ToLower();
                if (ext != ".jpg" && ext != ".jpeg" && ext != ".png" && ext != ".gif") continue;

                var pair = new PhotoPairModel();
                pair.PairIndex = pairIndex;
                pair.Title = beforePrefix + " #" + pairIndex;
                pair.BeforeFileName = bf.Name;
                pair.BeforeUrl = relDir + bf.Name;
                pair.BeforeExists = true;

                // 嘗試尋找對應的改善後照片
                // 優先尋找 afterPrefix1 + "_" + pairIndex + ".*"
                FileInfo matchedAfter = null;
                if (!string.IsNullOrEmpty(afterPrefix1))
                {
                    FileInfo[] afters1 = di.GetFiles(afterPrefix1 + "_" + pairIndex + ".*");
                    if (afters1.Length > 0) matchedAfter = afters1[0];
                }

                if (matchedAfter == null && !string.IsNullOrEmpty(afterPrefix2))
                {
                    FileInfo[] afters2 = di.GetFiles(afterPrefix2 + "_" + pairIndex + ".*");
                    if (afters2.Length > 0) matchedAfter = afters2[0];
                }

                if (matchedAfter != null)
                {
                    pair.AfterFileName = matchedAfter.Name;
                    pair.AfterUrl = relDir + matchedAfter.Name;
                    pair.AfterExists = true;
                }
                else
                {
                    pair.AfterFileName = "";
                    pair.AfterUrl = "";
                    pair.AfterExists = false;
                }

                pairs.Add(pair);
                pairIndex++;
            }

            return pairs;
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

        public class PhotoPairModel
        {
            public int PairIndex { get; set; }
            public string Title { get; set; }
            public string BeforeFileName { get; set; }
            public string BeforeUrl { get; set; }
            public bool BeforeExists { get; set; }
            public string AfterFileName { get; set; }
            public string AfterUrl { get; set; }
            public bool AfterExists { get; set; }
        }
    }
}