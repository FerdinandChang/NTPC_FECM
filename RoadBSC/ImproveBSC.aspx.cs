using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Net;
using System.Net.Mail;
using System.Text;
using System.Web;
using System.Web.Configuration;
using System.Web.Script.Serialization;
using System.Web.UI;
using NTPC_FEC.Helpers;
using NTPC_FEC.Security;
using NTPC_FEC.Services;

namespace NTPC_FEC.RoadBSC
{
    public partial class ImproveBSC : Page
    {
        private JavaScriptSerializer json;

        public ImproveBSC()
        {
            json = new JavaScriptSerializer();
            json.MaxJsonLength = int.MaxValue;
        }

        protected void Page_Load(object sender, EventArgs e)
        {
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
                    Response.Redirect("~/Default.aspx");
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
                case "init":
                    InitPageData();
                    break;
                case "save":
                    SaveImproveRecord();
                    break;
                default:
                    Response.Write(json.Serialize(new { Success = false, Message = "未知的操作指令：" + action }));
                    break;
            }
        }

        private void InitPageData()
        {
            string bscId = Request["id"];
            if (string.IsNullOrEmpty(bscId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "缺少通報案號參數。" }));
                return;
            }

            string sql = @"SELECT RoadBSC_CaseMain.*, C_TOWN.TOWN_NA,
                (SELECT TOP 1 Name FROM UserAcc WHERE UserAcc.UserID = RoadBSC_CaseMain.Report_User) AS Report_UserName,
                (SELECT TOP 1 Name FROM UserAcc WHERE UserAcc.UserID = RoadBSC_CaseMain.S_User) AS S_UserName,
                (SELECT TOP 1 Name FROM UserAcc WHERE UserAcc.UserID = RoadBSC_CaseMain.G_User) AS G_UserName,
                (SELECT TOP 1 UnitName FROM RoadBSC_Unit WHERE RoadBSC_Unit.UnitID = RoadBSC_CaseMain.S_COM) AS S_COM_NAME,
                (SELECT TOP 1 UnitName FROM RoadBSC_Unit WHERE RoadBSC_Unit.UnitID = RoadBSC_CaseMain.G_COM) AS G_COM_NAME
            FROM RoadBSC_CaseMain
            LEFT JOIN C_TOWN ON RoadBSC_CaseMain.TOWN_CODE = C_TOWN.TOWN_NO
            WHERE BSC_ID = @id";

            DataTable dt = DbHelper.ExecuteDataTable(sql, new SqlParameter("@id", bscId));
            if (dt.Rows.Count == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "找不到該案件資料（代碼：" + bscId + "）" }));
                return;
            }

            DataRow r = dt.Rows[0];

            double utmE = 0;
            double utmN = 0;
            double lat = 0;
            double lon = 0;
            if (r["S_UTME"] != DBNull.Value) double.TryParse(r["S_UTME"].ToString(), out utmE);
            if (r["S_UTMN"] != DBNull.Value) double.TryParse(r["S_UTMN"].ToString(), out utmN);
            if (r.Table.Columns.Contains("Lat") && r["Lat"] != DBNull.Value) double.TryParse(r["Lat"].ToString(), out lat);
            if (r.Table.Columns.Contains("Lon") && r["Lon"] != DBNull.Value) double.TryParse(r["Lon"].ToString(), out lon);
            if ((lat <= 0 || lon <= 0) && utmE > 0 && utmN > 0)
            {
                Twd97ToWgs84(utmE, utmN, out lat, out lon);
            }

            string reportDateStr = "";
            if (r["Report_Date"] != DBNull.Value)
            {
                DateTime dtRep;
                if (DateTime.TryParse(r["Report_Date"].ToString(), out dtRep)) reportDateStr = dtRep.ToString("yyyy-MM-dd HH:mm");
            }

            string setComDateStr = "";
            if (r["SetCOM_Date"] != DBNull.Value)
            {
                DateTime dtSet;
                if (DateTime.TryParse(r["SetCOM_Date"].ToString(), out dtSet)) setComDateStr = dtSet.ToString("yyyy-MM-dd HH:mm");
            }

            string improveDateStr = "";
            if (r["Improve_Date"] != DBNull.Value)
            {
                DateTime dtImp;
                if (DateTime.TryParse(r["Improve_Date"].ToString(), out dtImp)) improveDateStr = dtImp.ToString("yyyy-MM-dd HH:mm");
            }

            string currentLoginUser = Session["LoginUser"] != null ? Session["LoginUser"].ToString() : "";
            string currentLoginUserName = GetUserNameById(currentLoginUser);

            var caseData = new
            {
                BSC_ID = r["BSC_ID"].ToString().Trim(),
                Show_ID = r["Show_ID"] != DBNull.Value ? r["Show_ID"].ToString().Trim() : r["BSC_ID"].ToString().Trim(),
                Report_Date = reportDateStr,
                Report_User = r["Report_User"].ToString(),
                Report_UserName = r["Report_UserName"].ToString(),
                S_COM = r["S_COM"].ToString(),
                S_COM_NAME = r["S_COM_NAME"].ToString(),
                SetCOM_Date = setComDateStr,
                S_User = r["S_User"].ToString(),
                S_UserName = r["S_UserName"].ToString(),
                KIND = "BSC",
                KIND_Name = "人行道/跳空通道落塵整理",
                S_UTME = utmE > 0 ? utmE.ToString("0.00") : "",
                S_UTMN = utmN > 0 ? utmN.ToString("0.00") : "",
                Lat = lat > 0 ? lat : 0,
                Lng = lon > 0 ? lon : 0,
                TOWN_CODE = r["TOWN_CODE"].ToString(),
                TOWN_NA = r["TOWN_NA"].ToString(),
                ROAD_LV = r["ROAD_LV"].ToString(),
                ROAD_Name = r["ROAD_Name"].ToString(),
                Smooth = r["Smooth"].ToString(),
                Memo = r["COMM"] != DBNull.Value ? r["COMM"].ToString() : (r.Table.Columns.Contains("Memo") && r["Memo"] != DBNull.Value ? r["Memo"].ToString() : ""),
                G_COM = r["G_COM"].ToString(),
                G_COM_NAME = r["G_COM_NAME"].ToString(),
                Improve_Date = improveDateStr,
                G_User = currentLoginUser,
                G_UserName = currentLoginUserName,
                G_Memo = r.Table.Columns.Contains("G_Memo") && r["G_Memo"] != DBNull.Value ? r["G_Memo"].ToString() : (r.Table.Columns.Contains("G_MEMO") && r["G_MEMO"] != DBNull.Value ? r["G_MEMO"].ToString() : ""),
                G_Back = r.Table.Columns.Contains("G_Back") && r["G_Back"] != DBNull.Value ? r["G_Back"].ToString().Trim() : ""
            };

            List<PhotoItemDto> evidencePhotos = LoadEvidencePhotos(bscId);
            List<PhotoItemDto> improvePhotos = LoadImprovePhotos(bscId);

            Response.Write(json.Serialize(new
            {
                Success = true,
                Case = caseData,
                EvidencePhotos = evidencePhotos,
                ImprovePhotos = improvePhotos
            }));
        }

        private void SaveImproveRecord()
        {
            string rawJson = "";
            using (StreamReader sr = new StreamReader(Request.InputStream))
            {
                rawJson = sr.ReadToEnd();
            }

            if (string.IsNullOrEmpty(rawJson))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "儲存內容不能為空。" }));
                return;
            }

            ImproveSaveDto input = json.Deserialize<ImproveSaveDto>(rawJson);
            if (input == null)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "無效的儲存資料格式。" }));
                return;
            }

            string bscId = input.BSC_ID != null ? input.BSC_ID.Trim() : "";
            if (string.IsNullOrEmpty(bscId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "案件代碼不得為空。" }));
                return;
            }

            string loginUser = Session["LoginUser"] != null ? Session["LoginUser"].ToString() : "";
            if (string.IsNullOrEmpty(loginUser))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "登入逾時，請重新登入。" }));
                return;
            }

            string checkSql = "SELECT * FROM RoadBSC_CaseMain WHERE BSC_ID = @id";
            DataTable dtCase = DbHelper.ExecuteDataTable(checkSql, new SqlParameter("@id", bscId));
            if (dtCase.Rows.Count == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "查無此落塵通報案件：" + bscId }));
                return;
            }

            DataRow rowCase = dtCase.Rows[0];
            bool isBack = input.IsBack;

            string relDir = "Upload/RoadBSCPIC/" + bscId;
            string physDir = PathHelper.FindDirectory(relDir);
            if (!Directory.Exists(physDir))
            {
                Directory.CreateDirectory(physDir);
            }

            SavePhotos(physDir, input.ImprovePhotos);

            if (isBack)
            {
                string updateSql = @"UPDATE RoadBSC_CaseMain SET
                    G_User = @G_User,
                    Improve_Date = @Improve_Date,
                    G_Memo = @G_Memo,
                    G_Back = 'Y'
                WHERE BSC_ID = @BSC_ID";

                DbHelper.ExecuteNonQuery(updateSql,
                    new SqlParameter("@G_User", loginUser),
                    new SqlParameter("@Improve_Date", DateTime.Now),
                    new SqlParameter("@G_Memo", input.G_Memo != null ? input.G_Memo : "非本單位權責，退回重新派工"),
                    new SqlParameter("@BSC_ID", bscId)
                );

                SendImproveNotificationEmail(bscId, true, input.G_Memo);

                // 寫入 AuditLog 案件退回紀錄
                AuditLogger.Log(
                    operatorUser: loginUser,
                    actionType: "ROAD_BSC_REJECT",
                    targetUser: bscId,
                    clientIp: Request.UserHostAddress,
                    details: string.Format("落塵通報案件退回重派：案號 {0}, 退回說明: {1}", bscId, input.G_Memo != null ? input.G_Memo : "非本單位權責，退回重新派工"),
                    oldValue: null,
                    newValue: null
                );

                Response.Write(json.Serialize(new
                {
                    Success = true,
                    Message = "案件已成功退回，系統已標註退回狀態！",
                    RedirectUrl = "BSCDetail.aspx?id=" + HttpUtility.UrlEncode(bscId)
                }));
            }
            else
            {
                string updateSql = @"UPDATE RoadBSC_CaseMain SET
                    G_User = @G_User,
                    Improve_Date = @Improve_Date,
                    G_Memo = @G_Memo,
                    G_Back = NULL
                WHERE BSC_ID = @BSC_ID";

                DbHelper.ExecuteNonQuery(updateSql,
                    new SqlParameter("@G_User", loginUser),
                    new SqlParameter("@Improve_Date", DateTime.Now),
                    new SqlParameter("@G_Memo", input.G_Memo != null ? input.G_Memo : ""),
                    new SqlParameter("@BSC_ID", bscId)
                );

                SendImproveNotificationEmail(bscId, false, input.G_Memo);

                // 寫入 AuditLog 改善成果回報紀錄
                AuditLogger.Log(
                    operatorUser: loginUser,
                    actionType: "ROAD_BSC_IMPROVE",
                    targetUser: bscId,
                    clientIp: Request.UserHostAddress,
                    details: string.Format("落塵通報改善完成回報：案號 {0}, 說明: {1}", bscId, input.G_Memo != null ? input.G_Memo : ""),
                    oldValue: null,
                    newValue: null
                );

                Response.Write(json.Serialize(new
                {
                    Success = true,
                    Message = "落塵改善成果回報已成功送出！",
                    RedirectUrl = "BSCDetail.aspx?id=" + HttpUtility.UrlEncode(bscId)
                }));
            }
        }

        private void SavePhotos(string physDir, List<PhotoUploadItem> photos)
        {
            if (photos == null || photos.Count == 0) return;

            foreach (var item in photos)
            {
                if (item == null) continue;

                if (item.IsDeleted)
                {
                    if (!string.IsNullOrEmpty(item.FileName))
                    {
                        string safeName = Path.GetFileName(item.FileName);
                        // 僅允許刪除處理單位成果照片 (G_ 開頭)，嚴禁刪除外勤通報原始佐證照片
                        if (safeName.StartsWith("G_", StringComparison.OrdinalIgnoreCase))
                        {
                            string delPath = Path.Combine(physDir, safeName);
                            if (FileSecurityHelper.IsSafePath(physDir, delPath) && File.Exists(delPath))
                            {
                                try { File.Delete(delPath); } catch { }
                            }
                        }
                    }
                    continue;
                }

                if (!string.IsNullOrEmpty(item.Base64Data))
                {
                    string targetFileName = !string.IsNullOrEmpty(item.FileName) 
                        ? Path.GetFileName(item.FileName) 
                        : (item.TargetTitle != null ? Path.GetFileName(item.TargetTitle) : "G_改善後照片_1") + ".jpg";

                    if (!targetFileName.StartsWith("G_", StringComparison.OrdinalIgnoreCase))
                    {
                        targetFileName = "G_" + targetFileName;
                    }

                    if (!targetFileName.EndsWith(".jpg", StringComparison.OrdinalIgnoreCase) && 
                        !targetFileName.EndsWith(".jpeg", StringComparison.OrdinalIgnoreCase) && 
                        !targetFileName.EndsWith(".png", StringComparison.OrdinalIgnoreCase))
                    {
                        targetFileName += ".jpg";
                    }

                    string fullPath = Path.Combine(physDir, targetFileName);
                    if (!FileSecurityHelper.IsSafePath(physDir, fullPath))
                    {
                        continue;
                    }

                    try
                    {
                        string b64 = item.Base64Data;
                        int commaIdx = b64.IndexOf(',');
                        if (commaIdx >= 0)
                        {
                            b64 = b64.Substring(commaIdx + 1);
                        }
                        byte[] bytes = Convert.FromBase64String(b64);
                        if (FileSecurityHelper.HasValidMagicBytes(bytes, "jpg") || FileSecurityHelper.HasValidMagicBytes(bytes, "png"))
                        {
                            File.WriteAllBytes(fullPath, bytes);
                        }
                    }
                    catch
                    {
                    }
                }
            }
        }

        private void SendImproveNotificationEmail(string bscId, bool isBack, string memo)
        {
            try
            {
                string sql = @"SELECT RoadBSC_CaseMain.*, C_TOWN.TOWN_NA,
                    (SELECT TOP 1 UnitName FROM RoadBSC_Unit WHERE RoadBSC_Unit.UnitID = RoadBSC_CaseMain.S_COM) AS ReportUnitName,
                    (SELECT TOP 1 UnitName FROM RoadBSC_Unit WHERE RoadBSC_Unit.UnitID = RoadBSC_CaseMain.G_COM) AS HandleUnitName
                    FROM RoadBSC_CaseMain
                    LEFT JOIN C_TOWN ON RoadBSC_CaseMain.TOWN_CODE = C_TOWN.TOWN_NO
                    WHERE BSC_ID = @id";

                DataTable dt = DbHelper.ExecuteDataTable(sql, new SqlParameter("@id", bscId));
                if (dt.Rows.Count == 0) return;

                DataRow r = dt.Rows[0];
                string sCom = r["S_COM"] != DBNull.Value ? r["S_COM"].ToString() : "";
                string showId = r["Show_ID"] != DBNull.Value ? r["Show_ID"].ToString().Trim() : bscId;
                string townName = r["TOWN_NA"] != DBNull.Value ? r["TOWN_NA"].ToString() : "";
                string roadName = r["ROAD_Name"] != DBNull.Value ? r["ROAD_Name"].ToString() : "";
                string handleUnitName = r["HandleUnitName"] != DBNull.Value ? r["HandleUnitName"].ToString() : "";

                string userSql = "SELECT UserEmail FROM RoadBSC_UnitUser WHERE UnitID = @scom AND UserEmail IS NOT NULL AND LTRIM(RTRIM(UserEmail)) <> ''";
                DataTable dtUsers = DbHelper.ExecuteDataTable(userSql, new SqlParameter("@scom", sCom));

                List<string> emailList = new List<string>();
                foreach (DataRow ur in dtUsers.Rows)
                {
                    string em = ur["UserEmail"].ToString().Trim();
                    if (!string.IsNullOrEmpty(em) && em.Contains("@") && !emailList.Contains(em))
                    {
                        emailList.Add(em);
                    }
                }

                if (emailList.Count == 0) return;

                string host = WebConfigurationManager.AppSettings["MailHost"] ?? "127.0.0.1";
                string fromMail = WebConfigurationManager.AppSettings["MailFrom"] ?? "noreply@ntpc.gov.tw";
                string fromName = "新北市固定逸散源管理平台";

                using (MailMessage mail = new MailMessage())
                {
                    mail.From = new MailAddress(fromMail, fromName, Encoding.UTF8);
                    foreach (string em in emailList) mail.To.Add(em);

                    string typeTitle = isBack ? "【通報案件退回通知】" : "【落塵清理改善回報完成通知】";
                    mail.Subject = string.Format("{0} 案件編號：{1} ({2} {3})", typeTitle, showId, townName, roadName);
                    mail.IsBodyHtml = true;
                    mail.BodyEncoding = Encoding.UTF8;

                    StringBuilder sb = new StringBuilder();
                    sb.Append("<html><body style='font-family:微軟正黑體,Arial; font-size:15px; color:#333; line-height:1.6;'>");
                    sb.Append("<div style='max-width:650px; margin:0 auto; border:1px solid #9B741E; border-radius:8px; overflow:hidden;'>");
                    sb.Append("<div style='background:linear-gradient(135deg, #9B741E, #d97706); color:#fff; padding:16px 20px;'>");
                    sb.AppendFormat("<h3 style='margin:0; font-size:18px;'>新北市固定逸散源管理平台 - {0}</h3>", isBack ? "通報案件退回處理單" : "落塵清理成果回報單");
                    sb.Append("</div>");
                    sb.Append("<div style='padding:20px;'>");
                    sb.AppendFormat("<p>處理單位 <strong>{0}</strong> 已於 {1} 提交本案回報說明：</p>", handleUnitName, DateTime.Now.ToString("yyyy-MM-dd HH:mm"));
                    sb.Append("<table style='width:100%; border-collapse:collapse; margin:16px 0;'>");
                    sb.AppendFormat("<tr><td style='border:1px solid #ddd; padding:8px 12px; background:#f8fafc; width:130px;'><strong>案件代號</strong></td><td style='border:1px solid #ddd; padding:8px 12px;'>{0}</td></tr>", showId);
                    sb.AppendFormat("<tr><td style='border:1px solid #ddd; padding:8px 12px; background:#f8fafc;'><strong>行政區/路段</strong></td><td style='border:1px solid #ddd; padding:8px 12px;'>{0} {1}</td></tr>", townName, roadName);
                    sb.AppendFormat("<tr><td style='border:1px solid #ddd; padding:8px 12px; background:#f8fafc;'><strong>處理說明</strong></td><td style='border:1px solid #ddd; padding:8px 12px;'>{0}</td></tr>", string.IsNullOrEmpty(memo) ? "無" : memo);
                    sb.Append("</table>");
                    sb.Append("</div></div></body></html>");

                    mail.Body = sb.ToString();

                    using (SmtpClient smtp = new SmtpClient(host))
                    {
                        smtp.Send(mail);
                    }
                }
            }
            catch { }
        }

        private List<PhotoItemDto> LoadEvidencePhotos(string bscId)
        {
            List<PhotoItemDto> list = new List<PhotoItemDto>();
            string relDir = "/Upload/RoadBSCPIC/" + bscId + "/";
            string physDir = PathHelper.FindDirectory(relDir);

            if (!Directory.Exists(physDir)) return list;

            DirectoryInfo di = new DirectoryInfo(physDir);
            FileInfo[] files = di.GetFiles("*.*");
            int idx = 1;
            foreach (FileInfo f in files)
            {
                string ext = f.Extension.ToLower();
                if (ext == ".jpg" || ext == ".jpeg" || ext == ".png")
                {
                    if (f.Name.StartsWith("G_", StringComparison.OrdinalIgnoreCase)) continue;

                    PhotoItemDto p = new PhotoItemDto();
                    p.FileName = f.Name;
                    p.Url = PathHelper.ResolveUrl(relDir + f.Name);
                    p.Title = "現場通報照片 #" + idx;
                    list.Add(p);
                    idx++;
                }
            }
            return list;
        }

        private List<PhotoItemDto> LoadImprovePhotos(string bscId)
        {
            List<PhotoItemDto> list = new List<PhotoItemDto>();
            string relDir = "/Upload/RoadBSCPIC/" + bscId + "/";
            string physDir = PathHelper.FindDirectory(relDir);

            if (!Directory.Exists(physDir)) return list;

            DirectoryInfo di = new DirectoryInfo(physDir);
            FileInfo[] files = di.GetFiles("G_*.*");
            int idx = 1;
            foreach (FileInfo f in files)
            {
                string ext = f.Extension.ToLower();
                if (ext == ".jpg" || ext == ".jpeg" || ext == ".png")
                {
                    PhotoItemDto p = new PhotoItemDto();
                    p.FileName = f.Name;
                    p.Url = PathHelper.ResolveUrl(relDir + f.Name);
                    p.Title = "改善後照片 #" + idx;
                    list.Add(p);
                    idx++;
                }
            }
            return list;
        }

        private string GetUserNameById(string uid)
        {
            if (string.IsNullOrEmpty(uid)) return "";
            try
            {
                string sql = "SELECT Name FROM UserAcc WHERE UserID = @id";
                object obj = DbHelper.ExecuteScalar(sql, new SqlParameter("@id", uid));
                if (obj != null && obj != DBNull.Value) return obj.ToString().Trim();
            }
            catch { }
            return uid;
        }

        private static void Twd97ToWgs84(double x, double y, out double lat, out double lon)
        {
            if (x <= 0 || y <= 0) { lat = 0; lon = 0; return; }
            double a = 6378137.0;
            double b = 6356752.314245;
            double dx = 250000;
            double dy = 0;
            double lon0 = 121 * Math.PI / 180;
            double k0 = 0.9999;
            double e = Math.Sqrt(1 - Math.Pow(b / a, 2));
            double e2 = Math.Pow(e, 2) / (1 - Math.Pow(e, 2));

            x -= dx;
            y -= dy;

            double m = y / k0;
            double mu = m / (a * (1 - Math.Pow(e, 2) / 4 - 3 * Math.Pow(e, 4) / 64 - 5 * Math.Pow(e, 6) / 256));
            double e1 = (1 - Math.Sqrt(1 - Math.Pow(e, 2))) / (1 + Math.Sqrt(1 - Math.Pow(e, 2)));

            double j1 = 3 * e1 / 2 - 27 * Math.Pow(e1, 3) / 32;
            double j2 = 21 * Math.Pow(e1, 2) / 16 - 55 * Math.Pow(e1, 4) / 32;
            double j3 = 151 * Math.Pow(e1, 3) / 96;
            double j4 = 1097 * Math.Pow(e1, 4) / 512;

            double fp = mu + j1 * Math.Sin(2 * mu) + j2 * Math.Sin(4 * mu) + j3 * Math.Sin(6 * mu) + j4 * Math.Sin(8 * mu);

            double c1 = e2 * Math.Pow(Math.Cos(fp), 2);
            double t1 = Math.Pow(Math.Tan(fp), 2);
            double r1 = a * (1 - Math.Pow(e, 2)) / Math.Pow(1 - Math.Pow(e, 2) * Math.Pow(Math.Sin(fp), 2), 1.5);
            double n1 = a / Math.Sqrt(1 - Math.Pow(e, 2) * Math.Pow(Math.Sin(fp), 2));

            double d = x / (n1 * k0);

            double q1 = n1 * Math.Tan(fp) / r1;
            double q2 = Math.Pow(d, 2) / 2;
            double q3 = (5 + 3 * t1 + 10 * c1 - 4 * Math.Pow(c1, 2) - 9 * e2) * Math.Pow(d, 4) / 24;
            double q4 = (61 + 90 * t1 + 298 * c1 + 45 * Math.Pow(t1, 2) - 3 * Math.Pow(c1, 2) - 252 * e2) * Math.Pow(d, 6) / 720;
            lat = (fp - q1 * (q2 - q3 + q4)) * 180 / Math.PI;

            double q5 = d;
            double q6 = (1 + 2 * t1 + c1) * Math.Pow(d, 3) / 6;
            double q7 = (5 - 2 * c1 + 28 * t1 - 3 * Math.Pow(c1, 2) + 8 * e2 + 24 * Math.Pow(t1, 2)) * Math.Pow(d, 5) / 120;
            lon = (lon0 + (q5 - q6 + q7) / Math.Cos(fp)) * 180 / Math.PI;
        }

        #region DTO
        public class PhotoItemDto
        {
            public string FileName { get; set; }
            public string Url { get; set; }
            public string Title { get; set; }
        }

        public class PhotoUploadItem
        {
            public string FileName { get; set; }
            public string TargetTitle { get; set; }
            public string Base64Data { get; set; }
            public bool IsDeleted { get; set; }
        }

        public class ImproveSaveDto
        {
            public string BSC_ID { get; set; }
            public string G_Memo { get; set; }
            public bool IsBack { get; set; }
            public List<PhotoUploadItem> ImprovePhotos { get; set; }
        }
        #endregion
    }
}
