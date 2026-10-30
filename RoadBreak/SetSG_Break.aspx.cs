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
    public partial class SetSG_Break : Page
    {
        private JavaScriptSerializer json;

        public SetSG_Break()
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
                case "getunitusers":
                    GetUnitUsers(Request["unitId"]);
                    break;
                case "updateuseremail":
                    UpdateUserEmail();
                    break;
                case "save":
                    SaveDispatchRecord();
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
                Response.Write(json.Serialize(new { Success = false, Message = "案件代碼不得為空。" }));
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

            // 日期時間轉換
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

            string currentLoginUser = Session["LoginUser"] != null ? Session["LoginUser"].ToString() : "";
            string currentLoginUserName = GetUserNameById(currentLoginUser);

            string roadLv = r["ROAD_LV"] != DBNull.Value ? r["ROAD_LV"].ToString() : "";

            var caseData = new
            {
                Break_ID = r["Break_ID"].ToString().Trim(),
                Show_ID = r["Show_ID"] != DBNull.Value ? r["Show_ID"].ToString().Trim() : "【送出通報後自動取得】",
                Report_Date = reportDateStr,
                Report_User = r["Report_User"].ToString(),
                Report_UserName = r["Report_UserName"].ToString(),
                S_COM = r["S_COM"] != DBNull.Value ? r["S_COM"].ToString() : "",
                S_COM_NAME = r["S_COM_NAME"].ToString(),
                SetCOM_Date = setComDateStr,
                S_USER = currentLoginUser,
                S_UserName = currentLoginUserName,
                KIND = "RD",
                KIND_Name = "道路髒污破損(RD)",
                S_UTME = utmE > 0 ? utmE.ToString("0.00") : "",
                S_UTMN = utmN > 0 ? utmN.ToString("0.00") : "",
                Lat = lat > 0 ? lat : 0,
                Lng = lon > 0 ? lon : 0,
                TOWN_CODE = r["TOWN_CODE"].ToString(),
                TOWN_NA = r["TOWN_NA"].ToString(),
                ROAD_LV = roadLv,
                ROAD_Name = r["ROAD_Name"].ToString(),
                Smooth = r["Smooth"].ToString(),
                Smooth_Str = r["Smooth_Str"].ToString(),
                Hole_Conn_St = r["Hole_Conn_St"].ToString(),
                Hole_Conn_St_Str = r["Hole_Conn_St_Str"].ToString(),
                Memo = r["Memo"] != DBNull.Value ? r["Memo"].ToString() : "",
                G_COM = r["G_COM"] != DBNull.Value ? r["G_COM"].ToString() : ""
            };

            // 通報單位清單
            List<UnitItemDto> reportUnits = new List<UnitItemDto>();
            string sqlSCom = "SELECT UnitID, UnitName FROM RoadBreak_Unit WHERE pType = '通報單位' ORDER BY UnitID";
            DataTable dtSCom = DbHelper.ExecuteDataTable(sqlSCom);
            foreach (DataRow dr in dtSCom.Rows)
            {
                UnitItemDto item = new UnitItemDto();
                item.UnitID = dr["UnitID"].ToString();
                item.UnitName = dr["UnitName"].ToString();
                reportUnits.Add(item);
            }

            // 處理單位清單 (優先依據道路級別篩選，若無符合則列出全部處理單位)
            List<UnitItemDto> handleUnits = new List<UnitItemDto>();
            string sqlGCom = "SELECT UnitID, UnitName FROM RoadBreak_Unit WHERE pType = '處理單位'";
            if (!string.IsNullOrEmpty(roadLv))
            {
                sqlGCom += " AND (Road_LV = @kw OR Road_LV LIKE '%|' + @kw + '%' OR Road_LV LIKE '%' + @kw + '|%')";
            }
            sqlGCom += " ORDER BY UnitID";

            DataTable dtGCom = DbHelper.ExecuteDataTable(sqlGCom, new SqlParameter("@kw", roadLv));
            if (dtGCom.Rows.Count == 0 && !string.IsNullOrEmpty(roadLv))
            {
                // 回退列出所有處理單位
                string sqlFallback = "SELECT UnitID, UnitName FROM RoadBreak_Unit WHERE pType = '處理單位' ORDER BY UnitID";
                dtGCom = DbHelper.ExecuteDataTable(sqlFallback);
            }

            foreach (DataRow dr in dtGCom.Rows)
            {
                UnitItemDto item = new UnitItemDto();
                item.UnitID = dr["UnitID"].ToString();
                item.UnitName = dr["UnitName"].ToString();
                handleUnits.Add(item);
            }

            // 現場佐證照片
            List<PhotoItemDto> photos = LoadEvidencePhotos(breakId);

            Response.Write(json.Serialize(new
            {
                Success = true,
                Case = caseData,
                ReportUnits = reportUnits,
                HandleUnits = handleUnits,
                Photos = photos
            }));
        }

        // 讀取指定處理單位的承辦人員與 Email
        private void GetUnitUsers(string unitId)
        {
            if (string.IsNullOrEmpty(unitId))
            {
                Response.Write(json.Serialize(new { Success = true, Users = new List<UnitUserDto>() }));
                return;
            }

            string sql = @"SELECT RoadBreak_UnitUser.RunUser, RoadBreak_UnitUser.UserEmail, UserAcc.Name
                FROM RoadBreak_UnitUser
                LEFT JOIN UserAcc ON RoadBreak_UnitUser.RunUser = UserAcc.UserID
                WHERE RoadBreak_UnitUser.UnitID = @UnitID
                ORDER BY UserAcc.Name";

            DataTable dt = DbHelper.ExecuteDataTable(sql, new SqlParameter("@UnitID", unitId));
            List<UnitUserDto> list = new List<UnitUserDto>();
            foreach (DataRow dr in dt.Rows)
            {
                UnitUserDto u = new UnitUserDto();
                u.RunUser = dr["RunUser"] != DBNull.Value ? dr["RunUser"].ToString() : "";
                u.UserEmail = dr["UserEmail"] != DBNull.Value ? dr["UserEmail"].ToString() : "";
                u.Name = dr["Name"] != DBNull.Value ? dr["Name"].ToString() : u.RunUser;
                list.Add(u);
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                Users = list
            }));
        }

        // 即時更新承辦人 Email
        private void UpdateUserEmail()
        {
            string rawJson = "";
            using (StreamReader sr = new StreamReader(Request.InputStream))
            {
                rawJson = sr.ReadToEnd();
            }

            if (string.IsNullOrEmpty(rawJson))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "請求內容不能為空。" }));
                return;
            }

            EmailUpdateDto input = json.Deserialize<EmailUpdateDto>(rawJson);
            if (input == null || string.IsNullOrEmpty(input.RunUser))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "使用者識別碼不可為空。" }));
                return;
            }

            string sql = "UPDATE RoadBreak_UnitUser SET UserEmail = @email WHERE RunUser = @user";
            if (!string.IsNullOrEmpty(input.UnitID))
            {
                sql += " AND UnitID = @unit";
            }

            List<SqlParameter> paramList = new List<SqlParameter>();
            paramList.Add(new SqlParameter("@email", input.UserEmail != null ? input.UserEmail.Trim() : ""));
            paramList.Add(new SqlParameter("@user", input.RunUser.Trim()));
            if (!string.IsNullOrEmpty(input.UnitID))
            {
                paramList.Add(new SqlParameter("@unit", input.UnitID.Trim()));
            }

            int affected = DbHelper.ExecuteNonQuery(sql, paramList.ToArray());
            Response.Write(json.Serialize(new
            {
                Success = true,
                Message = "承辦人電子信箱已更新完成。"
            }));
        }

        // 儲存派工通報
        private void SaveDispatchRecord()
        {
            string rawJson = "";
            using (StreamReader sr = new StreamReader(Request.InputStream))
            {
                rawJson = sr.ReadToEnd();
            }

            if (string.IsNullOrEmpty(rawJson))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "派工通報資料不可為空。" }));
                return;
            }

            DispatchSaveDto input = json.Deserialize<DispatchSaveDto>(rawJson);
            if (input == null)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "無效的派工通報格式。" }));
                return;
            }

            string breakId = input.Break_ID != null ? input.Break_ID.Trim() : "";
            if (string.IsNullOrEmpty(breakId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "案件代碼不得為空。" }));
                return;
            }

            if (string.IsNullOrEmpty(input.S_COM))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "請選擇通報單位。" }));
                return;
            }

            if (string.IsNullOrEmpty(input.G_COM))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "請選擇處理單位。" }));
                return;
            }

            string loginUser = Session["LoginUser"] != null ? Session["LoginUser"].ToString() : "";
            if (string.IsNullOrEmpty(loginUser))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "登入逾時，請重新登入。" }));
                return;
            }

            // 檢查案件是否存在
            string checkSql = "SELECT * FROM RoadBreak_CaseMain WHERE Break_ID = @id";
            DataTable dtCase = DbHelper.ExecuteDataTable(checkSql, new SqlParameter("@id", breakId));
            if (dtCase.Rows.Count == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "查無此道路破損通報案件：" + breakId }));
                return;
            }

            DataRow rowCase = dtCase.Rows[0];
            string existingShowId = rowCase["Show_ID"] != DBNull.Value ? rowCase["Show_ID"].ToString().Trim() : "";
            DateTime setComDate = DateTime.Now;

            string finalShowId = existingShowId;
            if (string.IsNullOrEmpty(finalShowId))
            {
                // 自動產生通報案號：yyyyMMddRDHHmmss
                finalShowId = setComDate.ToString("yyyyMMdd") + "RD" + setComDate.ToString("HHmmss");
            }

            string memoText = input.Memo != null ? input.Memo.Trim() : "";

            // 更新案件主檔
            string updateSql = @"UPDATE RoadBreak_CaseMain SET
                S_User = @S_User,
                SetCOM_Date = @SetCOM_Date,
                S_COM = @S_COM,
                KIND = 'RD',
                Memo = @Memo,
                G_COM = @G_COM,
                Show_ID = @Show_ID
            WHERE Break_ID = @Break_ID";

            DbHelper.ExecuteNonQuery(updateSql,
                new SqlParameter("@S_User", loginUser),
                new SqlParameter("@SetCOM_Date", setComDate),
                new SqlParameter("@S_COM", input.S_COM),
                new SqlParameter("@Memo", memoText),
                new SqlParameter("@G_COM", input.G_COM),
                new SqlParameter("@Show_ID", finalShowId),
                new SqlParameter("@Break_ID", breakId)
            );

            // 安全寄送派工通知郵件
            string mailMsg = SendDispatchNotificationEmail(breakId, finalShowId, input.S_COM, input.G_COM, memoText, setComDate);

            Response.Write(json.Serialize(new
            {
                Success = true,
                Message = "道路髒污破損案件派工通報成功！通報案號：" + finalShowId,
                Show_ID = finalShowId,
                MailStatus = mailMsg
            }));
        }

        // 安全發送派工通知郵件
        private string SendDispatchNotificationEmail(string breakId, string showId, string sComId, string gComId, string memo, DateTime setComDate)
        {
            try
            {
                // 取處理單位名稱
                string sqlGComName = "SELECT TOP 1 UnitName FROM RoadBreak_Unit WHERE UnitID = @id";
                object objGName = DbHelper.ExecuteScalar(sqlGComName, new SqlParameter("@id", gComId));
                string gComName = objGName != null ? objGName.ToString().Trim() : "權責處理單位";

                // 取通報單位名稱
                string sqlSComName = "SELECT TOP 1 UnitName FROM RoadBreak_Unit WHERE UnitID = @id";
                object objSName = DbHelper.ExecuteScalar(sqlSComName, new SqlParameter("@id", sComId));
                string sComName = objSName != null ? objSName.ToString().Trim() : "通報單位";

                // 取得處理單位承辦人的 Email 清單
                string sqlEmails = "SELECT UserEmail FROM RoadBreak_UnitUser WHERE UnitID = @UnitID AND UserEmail IS NOT NULL AND UserEmail <> ''";
                DataTable dtEmails = DbHelper.ExecuteDataTable(sqlEmails, new SqlParameter("@UnitID", gComId));
                if (dtEmails.Rows.Count == 0)
                {
                    return "無收件人電子信箱，未發送郵件。";
                }

                string host = WebConfigurationManager.AppSettings["SMTPserver"];
                string fromAddr = WebConfigurationManager.AppSettings["EmailAddr"];
                string smtpUser = WebConfigurationManager.AppSettings["SMTP_User"];
                string smtpPass = WebConfigurationManager.AppSettings["SMTP_Password"];

                if (string.IsNullOrEmpty(host) || string.IsNullOrEmpty(fromAddr))
                {
                    return "SMTP 未設定，未發送郵件。";
                }

                string siteUrl = Request.Url.Scheme + "://" + Request.Url.Host + (Request.Url.IsDefaultPort ? "" : ":" + Request.Url.Port) + Request.ApplicationPath;
                string subject = "道路破損通報單【通報案號:" + showId + "】";

                StringBuilder sb = new StringBuilder();
                sb.AppendFormat("<div style='font-family: Arial, \"Microsoft JhengHei\", sans-serif; max-width: 650px; margin: 0 auto; border: 1px solid #cbd5e1; border-radius: 8px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.05);'>");
                sb.AppendFormat("<div style='background: linear-gradient(135deg, #0b1f7d 0%, #0284c7 100%); color: #ffffff; padding: 18px 24px;'>");
                sb.AppendFormat("<h3 style='margin:0; font-size: 1.25rem;'>新北市固定逸散源管理平台 - 道路髒污破損派工通報</h3>");
                sb.AppendFormat("<div style='font-size: 0.85rem; opacity: 0.85; margin-top: 4px;'>通報案號：{0}</div>", showId);
                sb.Append("</div>");
                sb.Append("<div style='padding: 24px; color: #1e293b; line-height: 1.6; background-color: #ffffff;'>");
                sb.AppendFormat("<p><strong>{0}</strong>，您好：</p>", gComName);
                sb.AppendFormat("<p>向您通報 1 件道路髒污破損通報案件【通報案號：<strong>{0}</strong>】，請於七天內至系統完成案件改善回報，謝謝。</p>", showId);
                sb.AppendFormat("<p><a href='{0}' target='_blank' style='display:inline-block; padding: 8px 16px; background-color: #0284c7; color: #ffffff; text-decoration: none; border-radius: 4px; font-weight: bold;'>前往固定逸散源管理平台</a></p>", siteUrl);

                if (!string.IsNullOrEmpty(memo))
                {
                    sb.AppendFormat("<div style='background: #f8fafc; border-left: 4px solid #0284c7; padding: 10px 14px; margin: 15px 0;'><strong>補充說明：</strong>{0}</div>", HttpUtility.HtmlEncode(memo));
                }

                sb.AppendFormat("<p style='text-align: right; margin-top: 20px;'><strong>{0}</strong> 敬上<br/><small style='color: #64748b;'>{1:yyyy-MM-dd HH:mm}</small></p>", sComName, setComDate);
                sb.Append("</div></div>");

                string bodyHtml = sb.ToString();

                SmtpClient client = new SmtpClient(host, 587);
                client.EnableSsl = false;
                client.Timeout = 15000;
                if (!string.IsNullOrEmpty(smtpUser) && !string.IsNullOrEmpty(smtpPass))
                {
                    client.Credentials = new NetworkCredential(smtpUser, smtpPass);
                }

                int sentCount = 0;
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
                        sentCount++;

                        // 記錄發信歷史
                        RecordEmailHistory(targetEmail, subject, bodyHtml, breakId, "道路破損通報");
                    }
                    catch (Exception ex)
                    {
                        // 記錄單一收件人發送錯誤，不阻斷後續收件人
                        RecordEmailHistory(targetEmail, subject, "發信失敗: " + ex.Message, breakId, "道路破損通報");
                    }
                }

                return string.Format("已寄送通知至 {0} 個信箱。", sentCount);
            }
            catch (Exception ex)
            {
                return "郵件通知發送異常：" + ex.Message;
            }
        }

        // 記錄發信紀錄至 Email_History
        private void RecordEmailHistory(string mailAdd, string subject, string content, string caseId, string appName)
        {
            try
            {
                string sql = @"INSERT INTO Email_History (Send_Date, Send_ADDR, pContent, SendAPPname, pSubject, ID)
                               VALUES (@Send_Date, @Send_ADDR, @pContent, @SendAPPname, @pSubject, @ID)";
                DbHelper.ExecuteNonQuery(sql,
                    new SqlParameter("@Send_Date", DateTime.Now),
                    new SqlParameter("@Send_ADDR", mailAdd ?? ""),
                    new SqlParameter("@pContent", content ?? ""),
                    new SqlParameter("@SendAPPname", appName ?? ""),
                    new SqlParameter("@pSubject", subject ?? ""),
                    new SqlParameter("@ID", caseId ?? "")
                );
            }
            catch
            {
                // 日誌記錄容錯處理
            }
        }

        // 讀取現場佐證照片
        private List<PhotoItemDto> LoadEvidencePhotos(string breakId)
        {
            List<PhotoItemDto> list = new List<PhotoItemDto>();
            string relDir = "Upload/RoadBreakPIC/" + breakId;
            string physDir = PathHelper.FindDirectory(relDir);

            if (!Directory.Exists(physDir))
            {
                return list;
            }

            DirectoryInfo dir = new DirectoryInfo(physDir);
            FileInfo[] files = dir.GetFiles();

            var beforeFiles = files
                .Where(new Func<FileInfo, bool>(delegate(FileInfo f) {
                    string name = f.Name;
                    return name.IndexOf("佐證照片") >= 0 && name.IndexOf("改善後") < 0;
                }))
                .OrderBy(new Func<FileInfo, string>(delegate(FileInfo f) { return f.Name; }))
                .ToList();

            foreach (FileInfo f in beforeFiles)
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

        // TWD97 轉 WGS84 標準演算法
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

        // ==================== DTO 類別定義 (相容 C# 5.0，無自動屬性初始化) ====================
        public class UnitItemDto
        {
            public string UnitID { get; set; }
            public string UnitName { get; set; }
        }

        public class UnitUserDto
        {
            public string RunUser { get; set; }
            public string Name { get; set; }
            public string UserEmail { get; set; }
        }

        public class EmailUpdateDto
        {
            public string UnitID { get; set; }
            public string RunUser { get; set; }
            public string UserEmail { get; set; }
        }

        public class DispatchSaveDto
        {
            public string Break_ID { get; set; }
            public string S_COM { get; set; }
            public string G_COM { get; set; }
            public string Memo { get; set; }
        }

        public class PhotoItemDto
        {
            public string FileName { get; set; }
            public string Title { get; set; }
            public string Url { get; set; }
            public long Size { get; set; }
            public string LastModified { get; set; }
        }
    }
}
