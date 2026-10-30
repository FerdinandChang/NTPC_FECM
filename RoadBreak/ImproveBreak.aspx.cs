using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Mail;
using System.Text;
using System.Web;
using System.Web.Configuration;
using System.Web.Script.Serialization;
using System.Web.UI;
using NTPC_FEC.Helpers;

namespace NTPC_FEC.RoadBreak
{
    public partial class ImproveBreak : Page
    {
        private JavaScriptSerializer json;

        public ImproveBreak()
        {
            json = new JavaScriptSerializer();
            json.MaxJsonLength = int.MaxValue;
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

        // 初始化頁面資料
        private void InitPageData()
        {
            string breakId = Request["id"];
            if (string.IsNullOrEmpty(breakId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "缺少通報案號參數。" }));
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
            if (r["S_UTME"] != DBNull.Value) double.TryParse(r["S_UTME"].ToString(), out utmE);
            if (r["S_UTMN"] != DBNull.Value) double.TryParse(r["S_UTMN"].ToString(), out utmN);
            if (r.Table.Columns.Contains("Lat") && r["Lat"] != DBNull.Value) double.TryParse(r["Lat"].ToString(), out lat);
            if (r.Table.Columns.Contains("Lon") && r["Lon"] != DBNull.Value) double.TryParse(r["Lon"].ToString(), out lon);
            if ((lat <= 0 || lon <= 0) && utmE > 0 && utmN > 0)
            {
                Twd97ToWgs84(utmE, utmN, out lat, out lon);
            }

            // 格式化日期
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
                KIND = "RD",
                KIND_Name = "道路髒污破損(RD)",
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
                Memo = r["Memo"] != DBNull.Value ? r["Memo"].ToString() : "",
                G_COM = r["G_COM"].ToString(),
                G_COM_NAME = r["G_COM_NAME"].ToString(),
                Improve_Date = improveDateStr,
                G_USER = currentLoginUser,
                G_UserName = currentLoginUserName,
                G_Memo = r["G_Memo"] != DBNull.Value ? r["G_Memo"].ToString() : "",
                G_Back = r["G_Back"] != DBNull.Value ? r["G_Back"].ToString().Trim() : ""
            };

            // 現場佐證照片
            List<PhotoItemDto> evidencePhotos = LoadEvidencePhotos(breakId);

            // 既有改善後照片
            List<PhotoItemDto> improvePhotos = LoadImprovePhotos(breakId);

            Response.Write(json.Serialize(new
            {
                Success = true,
                Case = caseData,
                EvidencePhotos = evidencePhotos,
                ImprovePhotos = improvePhotos
            }));
        }

        // 儲存改善回報 (或退回通報)
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

            string breakId = input.Break_ID != null ? input.Break_ID.Trim() : "";
            if (string.IsNullOrEmpty(breakId))
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

            string checkSql = "SELECT * FROM RoadBreak_CaseMain WHERE Break_ID = @id";
            DataTable dtCase = DbHelper.ExecuteDataTable(checkSql, new SqlParameter("@id", breakId));
            if (dtCase.Rows.Count == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "查無此道路破損案件：" + breakId }));
                return;
            }

            DataRow rowCase = dtCase.Rows[0];
            bool isBack = input.IsBack;

            // 實體照片儲存目錄
            string relDir = "Upload/RoadBreakPIC/" + breakId;
            string physDir = PathHelper.FindDirectory(relDir);
            if (!Directory.Exists(physDir))
            {
                Directory.CreateDirectory(physDir);
            }

            // 儲存/刪除改善後照片
            SavePhotos(physDir, input.ImprovePhotos);

            if (isBack)
            {
                // ==================== 退回通報模式 ====================
                string updateSql = @"UPDATE RoadBreak_CaseMain SET
                    G_User = @G_User,
                    Improve_Date = @Improve_Date,
                    G_Memo = @G_Memo,
                    G_Back = 'Y'
                WHERE Break_ID = @Break_ID";

                DbHelper.ExecuteNonQuery(updateSql,
                    new SqlParameter("@G_User", loginUser),
                    new SqlParameter("@Improve_Date", DateTime.Now),
                    new SqlParameter("@G_Memo", input.G_Memo != null ? input.G_Memo : "非本單位權責，退回重新派工"),
                    new SqlParameter("@Break_ID", breakId)
                );

                // 複製原案資訊產生重新派工之新案件
                string newBreakId = CreateNewBreakIdFromBack(breakId, rowCase, physDir);

                // 發送退回通知信
                SendImproveNotificationEmail(breakId, true, input.G_Memo);

                Response.Write(json.Serialize(new
                {
                    Success = true,
                    Message = "案件已成功退回，系統已重新複製新案供通報單位重新派工！",
                    RedirectUrl = "BreakDetail.aspx?id=" + HttpUtility.UrlEncode(breakId)
                }));
            }
            else
            {
                // ==================== 改善完成回報模式 ====================
                string updateSql = @"UPDATE RoadBreak_CaseMain SET
                    G_User = @G_User,
                    Improve_Date = @Improve_Date,
                    G_Memo = @G_Memo,
                    G_Back = NULL
                WHERE Break_ID = @Break_ID";

                DbHelper.ExecuteNonQuery(updateSql,
                    new SqlParameter("@G_User", loginUser),
                    new SqlParameter("@Improve_Date", DateTime.Now),
                    new SqlParameter("@G_Memo", input.G_Memo != null ? input.G_Memo : ""),
                    new SqlParameter("@Break_ID", breakId)
                );

                // 發送改善完成通知信
                SendImproveNotificationEmail(breakId, false, input.G_Memo);

                Response.Write(json.Serialize(new
                {
                    Success = true,
                    Message = "道路髒污破損改善回報已成功送出！",
                    RedirectUrl = "BreakDetail.aspx?id=" + HttpUtility.UrlEncode(breakId)
                }));
            }
        }

        // 退回通報時產生新案號並複製現場照片
        private string CreateNewBreakIdFromBack(string originBreakId, DataRow originRow, string originPhysDir)
        {
            string datePrefix = DateTime.Now.ToString("yyyyMMdd");
            string timePrefix = DateTime.Now.ToString("HHmmss");
            string fullPrefix = datePrefix + timePrefix;

            string seqSql = "SELECT TOP 1 Break_ID FROM RoadBreak_CaseMain WHERE Break_ID LIKE @prefix + '%' ORDER BY Break_ID DESC";
            object maxObj = DbHelper.ExecuteScalar(seqSql, new SqlParameter("@prefix", fullPrefix));
            int seq = 1;
            if (maxObj != null && maxObj != DBNull.Value)
            {
                string maxId = maxObj.ToString().Trim();
                if (maxId.Length >= 17)
                {
                    string seqStr = maxId.Substring(14, 3);
                    int.TryParse(seqStr, out seq);
                    seq++;
                }
            }

            string newBreakId = fullPrefix + string.Format("{0:000}", seq);

            DateTime rptDate = DateTime.Now;
            if (originRow["Report_Date"] != DBNull.Value) rptDate = Convert.ToDateTime(originRow["Report_Date"]);

            double utmE = 0, utmN = 0;
            if (originRow["S_UTME"] != DBNull.Value) double.TryParse(originRow["S_UTME"].ToString(), out utmE);
            if (originRow["S_UTMN"] != DBNull.Value) double.TryParse(originRow["S_UTMN"].ToString(), out utmN);

            string roadName = originRow["ROAD_Name"] != DBNull.Value ? originRow["ROAD_Name"].ToString() : "";
            string roadLv = originRow["ROAD_LV"] != DBNull.Value ? originRow["ROAD_LV"].ToString() : "";
            string townCode = originRow["TOWN_CODE"] != DBNull.Value ? originRow["TOWN_CODE"].ToString() : "";
            string smooth = originRow["Smooth"] != DBNull.Value ? originRow["Smooth"].ToString() : "";
            string hole = originRow["Hole_Conn_St"] != DBNull.Value ? originRow["Hole_Conn_St"].ToString() : "";
            string memo = originRow["Memo"] != DBNull.Value ? originRow["Memo"].ToString() : "";
            string rptUser = originRow["Report_User"] != DBNull.Value ? originRow["Report_User"].ToString().Trim() : "";

            string insertSql = @"INSERT INTO RoadBreak_CaseMain 
                (Break_ID, Report_Date, S_UTME, S_UTMN, ROAD_Name, ROAD_LV, TOWN_CODE, Smooth, Hole_Conn_St, Memo, Report_User, FromBack_ID)
                VALUES 
                (@Break_ID, @Report_Date, @S_UTME, @S_UTMN, @ROAD_Name, @ROAD_LV, @TOWN_CODE, @Smooth, @Hole_Conn_St, @Memo, @Report_User, @FromBack_ID)";

            DbHelper.ExecuteNonQuery(insertSql,
                new SqlParameter("@Break_ID", newBreakId),
                new SqlParameter("@Report_Date", rptDate),
                new SqlParameter("@S_UTME", utmE),
                new SqlParameter("@S_UTMN", utmN),
                new SqlParameter("@ROAD_Name", roadName),
                new SqlParameter("@ROAD_LV", roadLv),
                new SqlParameter("@TOWN_CODE", townCode),
                new SqlParameter("@Smooth", smooth),
                new SqlParameter("@Hole_Conn_St", hole),
                new SqlParameter("@Memo", memo),
                new SqlParameter("@Report_User", rptUser),
                new SqlParameter("@FromBack_ID", originBreakId)
            );

            // 複製照片到新目錄
            string newRelDir = "Upload/RoadBreakPIC/" + newBreakId;
            string newPhysDir = PathHelper.FindDirectory(newRelDir);
            if (!Directory.Exists(newPhysDir))
            {
                Directory.CreateDirectory(newPhysDir);
            }

            if (Directory.Exists(originPhysDir))
            {
                DirectoryInfo dir = new DirectoryInfo(originPhysDir);
                foreach (FileInfo f in dir.GetFiles())
                {
                    if (f.Name.IndexOf("佐證照片") >= 0 && f.Name.IndexOf("改善後") < 0)
                    {
                        string destPath = Path.Combine(newPhysDir, f.Name);
                        try { f.CopyTo(destPath, true); } catch { }
                    }
                }
            }

            return newBreakId;
        }

        // 儲存改善照片
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
                        string delPath = Path.Combine(physDir, item.FileName);
                        if (File.Exists(delPath))
                        {
                            try { File.Delete(delPath); } catch { }
                        }
                    }
                    continue;
                }

                if (!string.IsNullOrEmpty(item.Base64Data))
                {
                    string targetFileName = !string.IsNullOrEmpty(item.FileName) 
                        ? item.FileName 
                        : (item.TargetTitle ?? "改善後佐證照片_1") + ".jpg";

                    if (!targetFileName.EndsWith(".jpg", StringComparison.OrdinalIgnoreCase) && 
                        !targetFileName.EndsWith(".jpeg", StringComparison.OrdinalIgnoreCase) && 
                        !targetFileName.EndsWith(".png", StringComparison.OrdinalIgnoreCase))
                    {
                        targetFileName += ".jpg";
                    }

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
                }
            }
        }

        // 發送通知郵件
        private void SendImproveNotificationEmail(string breakId, bool isBack, string gMemo)
        {
            try
            {
                string sqlCase = "SELECT Show_ID, S_COM, S_User, Report_User FROM RoadBreak_CaseMain WHERE Break_ID = @id";
                DataTable dtCase = DbHelper.ExecuteDataTable(sqlCase, new SqlParameter("@id", breakId));
                if (dtCase.Rows.Count == 0) return;

                DataRow r = dtCase.Rows[0];
                string showId = r["Show_ID"] != DBNull.Value ? r["Show_ID"].ToString().Trim() : breakId;
                string sCom = r["S_COM"] != DBNull.Value ? r["S_COM"].ToString().Trim() : "";

                // 取得通報單位承辦人信箱
                string sqlEmails = "SELECT UserEmail FROM RoadBreak_UnitUser WHERE UnitID = @UnitID AND UserEmail IS NOT NULL AND UserEmail <> ''";
                DataTable dtEmails = DbHelper.ExecuteDataTable(sqlEmails, new SqlParameter("@UnitID", sCom));

                string host = WebConfigurationManager.AppSettings["SMTPserver"];
                string fromAddr = WebConfigurationManager.AppSettings["EmailAddr"];
                string smtpUser = WebConfigurationManager.AppSettings["SMTP_User"];
                string smtpPass = WebConfigurationManager.AppSettings["SMTP_Password"];

                if (string.IsNullOrEmpty(host) || string.IsNullOrEmpty(fromAddr) || dtEmails.Rows.Count == 0) return;

                string subject = isBack 
                    ? "道路破損通報單【通報案號:" + showId + "】權責機關退回通知"
                    : "道路破損通報單【通報案號:" + showId + "】改善完成回報通知";

                string siteUrl = Request.Url.Scheme + "://" + Request.Url.Host + (Request.Url.IsDefaultPort ? "" : ":" + Request.Url.Port) + Request.ApplicationPath;

                StringBuilder sb = new StringBuilder();
                sb.AppendFormat("<div style='font-family: Arial, \"Microsoft JhengHei\", sans-serif; max-width: 650px; margin: 0 auto; border: 1px solid #cbd5e1; border-radius: 8px; overflow: hidden;'>");
                sb.AppendFormat("<div style='background: {0}; color: #ffffff; padding: 18px 24px;'>", isBack ? "#dc2626" : "#059669");
                sb.AppendFormat("<h3 style='margin:0; font-size: 1.25rem;'>新北市固定逸散源管理平台 - {0}</h3>", isBack ? "非權責單位退回通知" : "改善完成回報");
                sb.AppendFormat("<div style='font-size: 0.85rem; opacity: 0.85; margin-top: 4px;'>通報案號：{0}</div>", showId);
                sb.Append("</div>");
                sb.Append("<div style='padding: 24px; color: #1e293b; line-height: 1.6; background-color: #ffffff;'>");
                if (isBack)
                {
                    sb.AppendFormat("<p>案件【通報案號：<strong>{0}</strong>】已被處理單位退回，原因說明：</p>", showId);
                    sb.AppendFormat("<div style='background: #fef2f2; border-left: 4px solid #ef4444; padding: 12px 16px; margin: 15px 0; color: #991b1b;'>{0}</div>", HttpUtility.HtmlEncode(gMemo));
                    sb.Append("<p>系統已自動複製該案件以利您重新進行權責派工作業。</p>");
                }
                else
                {
                    sb.AppendFormat("<p>案件【通報案號：<strong>{0}</strong>】已由處理單位回報改善完成！</p>", showId);
                    if (!string.IsNullOrEmpty(gMemo))
                    {
                        sb.AppendFormat("<div style='background: #f0fdf4; border-left: 4px solid #10b981; padding: 12px 16px; margin: 15px 0; color: #065f46;'><strong>改善說明：</strong>{0}</div>", HttpUtility.HtmlEncode(gMemo));
                    }
                }
                sb.AppendFormat("<p><a href='{0}' target='_blank' style='display:inline-block; padding: 8px 16px; background-color: #0284c7; color: #ffffff; text-decoration: none; border-radius: 4px; font-weight: bold;'>前往固定逸散源管理平台</a></p>", siteUrl);
                sb.Append("</div></div>");

                string bodyHtml = sb.ToString();

                SmtpClient client = new SmtpClient(host, 587);
                client.EnableSsl = false;
                client.Timeout = 15000;
                if (!string.IsNullOrEmpty(smtpUser) && !string.IsNullOrEmpty(smtpPass)) client.Credentials = new NetworkCredential(smtpUser, smtpPass);

                foreach (DataRow uRow in dtEmails.Rows)
                {
                    string targetEmail = uRow["UserEmail"].ToString().Trim();
                    if (string.IsNullOrEmpty(targetEmail)) continue;

                    try
                    {
                        MailMessage msg = new MailMessage();
                        msg.From = new MailAddress(fromAddr, "新北市固定逸散源管理平台", Encoding.UTF8);
                        msg.To.Add(new MailAddress(targetEmail));
                        msg.Subject = subject;
                        msg.IsBodyHtml = true;
                        msg.BodyEncoding = Encoding.UTF8;
                        msg.Body = bodyHtml;

                        client.Send(msg);
                    }
                    catch { }
                }
            }
            catch { }
        }

        // 讀取現場佐證照片
        private List<PhotoItemDto> LoadEvidencePhotos(string breakId)
        {
            List<PhotoItemDto> list = new List<PhotoItemDto>();
            string relDir = "Upload/RoadBreakPIC/" + breakId;
            string physDir = PathHelper.FindDirectory(relDir);
            if (!Directory.Exists(physDir)) return list;

            DirectoryInfo dir = new DirectoryInfo(physDir);
            var files = dir.GetFiles()
                .Where(new Func<FileInfo, bool>(delegate(FileInfo f) {
                    string name = f.Name;
                    return name.IndexOf("佐證照片") >= 0 && name.IndexOf("改善後") < 0;
                }))
                .OrderBy(new Func<FileInfo, string>(delegate(FileInfo f) { return f.Name; }))
                .ToList();

            foreach (FileInfo f in files)
            {
                PhotoItemDto item = new PhotoItemDto();
                item.FileName = f.Name;
                item.Title = Path.GetFileNameWithoutExtension(f.Name);
                item.Url = "../" + relDir + "/" + f.Name;
                item.Size = f.Length;
                item.LastModified = f.LastWriteTime.ToString("yyyy-MM-dd HH:mm");
                list.Add(item);
            }
            return list;
        }

        // 讀取既有改善後照片
        private List<PhotoItemDto> LoadImprovePhotos(string breakId)
        {
            List<PhotoItemDto> list = new List<PhotoItemDto>();
            string relDir = "Upload/RoadBreakPIC/" + breakId;
            string physDir = PathHelper.FindDirectory(relDir);
            if (!Directory.Exists(physDir)) return list;

            DirectoryInfo dir = new DirectoryInfo(physDir);
            var files = dir.GetFiles()
                .Where(new Func<FileInfo, bool>(delegate(FileInfo f) {
                    return f.Name.IndexOf("改善後") >= 0;
                }))
                .OrderBy(new Func<FileInfo, string>(delegate(FileInfo f) { return f.Name; }))
                .ToList();

            foreach (FileInfo f in files)
            {
                PhotoItemDto item = new PhotoItemDto();
                item.FileName = f.Name;
                item.Title = Path.GetFileNameWithoutExtension(f.Name);
                item.Url = "../" + relDir + "/" + f.Name;
                item.Size = f.Length;
                item.LastModified = f.LastWriteTime.ToString("yyyy-MM-dd HH:mm");
                list.Add(item);
            }
            return list;
        }

        private string GetUserNameById(string userId)
        {
            if (string.IsNullOrEmpty(userId)) return "";
            string sql = "SELECT TOP 1 Name FROM UserAcc WHERE UserID = @id";
            object obj = DbHelper.ExecuteScalar(sql, new SqlParameter("@id", userId));
            return obj != null && obj != DBNull.Value ? obj.ToString().Trim() : userId;
        }

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

        // ==================== DTO 定義 (C# 5.0) ====================
        public class PhotoItemDto
        {
            public string FileName { get; set; }
            public string Title { get; set; }
            public string Url { get; set; }
            public long Size { get; set; }
            public string LastModified { get; set; }
        }

        public class PhotoUploadItem
        {
            public string TargetTitle { get; set; }
            public string FileName { get; set; }
            public string Base64Data { get; set; }
            public bool IsDeleted { get; set; }
        }

        public class ImproveSaveDto
        {
            public string Break_ID { get; set; }
            public string G_Memo { get; set; }
            public bool IsBack { get; set; }
            public List<PhotoUploadItem> ImprovePhotos { get; set; }
        }
    }
}
