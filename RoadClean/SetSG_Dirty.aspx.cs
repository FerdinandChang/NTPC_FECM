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

namespace NTPC_FEC.RoadClean
{
    public partial class SetSG_Dirty : Page
    {
        private JavaScriptSerializer json;

        public SetSG_Dirty()
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
            string dirtyId = Request["id"];
            if (string.IsNullOrEmpty(dirtyId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "案件代碼不得為空。" }));
                return;
            }

            string sql = @"SELECT RoadDirty_CaseMain.*, C_TOWN.TOWN_NA,
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
                END AS KIND_Name
            FROM RoadDirty_CaseMain
            LEFT JOIN C_TOWN ON RoadDirty_CaseMain.TOWN_CODE = C_TOWN.TOWN_NO
            WHERE Dirty_ID = @id";

            DataTable dt = DbHelper.ExecuteDataTable(sql, new SqlParameter("@id", dirtyId));
            if (dt.Rows.Count == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "找不到該案件資料（代碼：" + dirtyId + "）" }));
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

            var caseData = new
            {
                Dirty_ID = r["Dirty_ID"].ToString().Trim(),
                Show_ID = (r["Show_ID"] != DBNull.Value && !string.IsNullOrEmpty(r["Show_ID"].ToString().Trim())) ? r["Show_ID"].ToString().Trim() : r["Dirty_ID"].ToString().Trim(),
                Report_Date = reportDateStr,
                Report_User = r["Report_User"].ToString(),
                Report_UserName = r["Report_UserName"] != DBNull.Value ? r["Report_UserName"].ToString() : r["Report_User"].ToString(),
                S_COM = r["S_COM"] != DBNull.Value ? r["S_COM"].ToString() : "",
                S_COM_NAME = r["S_COM_NAME"] != DBNull.Value ? r["S_COM_NAME"].ToString() : "",
                SetCOM_Date = setComDateStr,
                S_User = currentLoginUser,
                S_UserName = currentLoginUserName,
                KIND = r["KIND"] != DBNull.Value ? r["KIND"].ToString() : "",
                KIND_Name = r["KIND_Name"] != DBNull.Value ? r["KIND_Name"].ToString() : "",
                S_UTME = utmE > 0 ? utmE.ToString("0.00") : "",
                S_UTMN = utmN > 0 ? utmN.ToString("0.00") : "",
                Lat = lat > 0 ? lat : 0,
                Lng = lon > 0 ? lon : 0,
                TOWN_CODE = r["TOWN_CODE"] != DBNull.Value ? r["TOWN_CODE"].ToString() : "",
                TOWN_NA = r["TOWN_NA"] != DBNull.Value ? r["TOWN_NA"].ToString() : "",
                ROAD_Name = r["ROAD_Name"] != DBNull.Value ? r["ROAD_Name"].ToString() : "",
                Memo = r["COMM"] != DBNull.Value ? r["COMM"].ToString() : (r.Table.Columns.Contains("Memo") && r["Memo"] != DBNull.Value ? r["Memo"].ToString() : ""),
                G_COM = r["G_COM"] != DBNull.Value ? r["G_COM"].ToString() : ""
            };

            // 通報單位清單
            List<UnitItemDto> reportUnits = new List<UnitItemDto>();
            string sqlSCom = "SELECT UnitID, UnitName FROM RoadDirty_Unit WHERE pType = '通報單位' ORDER BY UnitID";
            DataTable dtSCom = DbHelper.ExecuteDataTable(sqlSCom);
            foreach (DataRow dr in dtSCom.Rows)
            {
                UnitItemDto item = new UnitItemDto();
                item.UnitID = dr["UnitID"].ToString();
                item.UnitName = dr["UnitName"].ToString();
                reportUnits.Add(item);
            }

            // 處理單位清單
            List<UnitItemDto> handleUnits = new List<UnitItemDto>();
            string sqlGCom = "SELECT UnitID, UnitName FROM RoadDirty_Unit WHERE pType = '處理單位' ORDER BY UnitID";
            DataTable dtGCom = DbHelper.ExecuteDataTable(sqlGCom);
            foreach (DataRow dr in dtGCom.Rows)
            {
                UnitItemDto item = new UnitItemDto();
                item.UnitID = dr["UnitID"].ToString();
                item.UnitName = dr["UnitName"].ToString();
                handleUnits.Add(item);
            }

            // 現場佐證照片
            List<PhotoItemDto> photos = LoadEvidencePhotos(dirtyId);

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

            string sql = @"SELECT RoadDirty_UnitUser.RunUser, RoadDirty_UnitUser.UserEmail, UserAcc.Name
                FROM RoadDirty_UnitUser
                LEFT JOIN UserAcc ON RoadDirty_UnitUser.RunUser = UserAcc.UserID
                WHERE RoadDirty_UnitUser.UnitID = @UnitID
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

            string currentUserId = Session["UserID"] != null ? Session["UserID"].ToString().Trim() : "";
            if (string.IsNullOrEmpty(currentUserId) && Session["LoginUser"] != null) currentUserId = Session["LoginUser"].ToString().Trim();
            long lic = Session["LIC"] != null ? Convert.ToInt64(Session["LIC"]) : 0L;
            string currentRole = Session["Role"] != null ? Session["Role"].ToString().Trim() : "";
            bool isAdmin = string.Equals(currentRole, "Admin", StringComparison.OrdinalIgnoreCase) ||
                           string.Equals(currentRole, "SystemAdmin", StringComparison.OrdinalIgnoreCase);

            // 權責檢核：管理員、本人、或具備道路髒污通報維護權限者 (ROAD_DIRTY_NEW / 27)
            bool hasAuth = isAdmin || string.Equals(currentUserId, input.RunUser.Trim(), StringComparison.OrdinalIgnoreCase)
                                   || PermissionService.HasPermission(currentUserId, lic, "ROAD_DIRTY_NEW", 27);

            if (!hasAuth)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "權限不足：您未具備維護該單位承辦人通訊信箱之權限。" }));
                return;
            }

            string email = input.UserEmail != null ? input.UserEmail.Trim() : "";
            if (!string.IsNullOrEmpty(email) && (!email.Contains("@") || !email.Contains(".")))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "電子信箱格式無效。" }));
                return;
            }

            // 查詢舊 Email 供 AuditLog 比對
            string sqlOld = "SELECT TOP 1 UserEmail FROM RoadDirty_UnitUser WHERE RunUser = @user";
            object objOld = DbHelper.ExecuteScalar(sqlOld, new SqlParameter("@user", input.RunUser.Trim()));
            string oldEmail = objOld != null && objOld != DBNull.Value ? objOld.ToString().Trim() : "";

            string sql = "UPDATE RoadDirty_UnitUser SET UserEmail = @email WHERE RunUser = @user";
            if (!string.IsNullOrEmpty(input.UnitID))
            {
                sql += " AND UnitID = @unitId";
            }

            List<SqlParameter> pList = new List<SqlParameter>();
            pList.Add(new SqlParameter("@email", email));
            pList.Add(new SqlParameter("@user", input.RunUser.Trim()));
            if (!string.IsNullOrEmpty(input.UnitID))
            {
                pList.Add(new SqlParameter("@unitId", input.UnitID.Trim()));
            }

            int affected = DbHelper.ExecuteNonQuery(sql, pList.ToArray());

            // 寫入 AuditLog 稽核日誌
            AuditLogger.Log(
                operatorUser: currentUserId,
                actionType: "DISPATCH_EMAIL_UPDATE",
                targetUser: input.RunUser.Trim(),
                clientIp: Request.UserHostAddress,
                details: string.Format("更新道路髒污處理單位承辦人信箱 (UnitID: {0})", input.UnitID),
                oldValue: oldEmail,
                newValue: email
            );

            Response.Write(json.Serialize(new
            {
                Success = true,
                Message = "電子信箱已更新成功！",
                Affected = affected
            }));
        }

        // 儲存派工資料並寄送通知信
        private void SaveDispatchRecord()
        {
            string rawJson = "";
            using (StreamReader sr = new StreamReader(Request.InputStream))
            {
                rawJson = sr.ReadToEnd();
            }

            if (string.IsNullOrEmpty(rawJson))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "未接收到派工資料。" }));
                return;
            }

            DispatchSubmitDto data = json.Deserialize<DispatchSubmitDto>(rawJson);
            if (data == null || string.IsNullOrEmpty(data.Dirty_ID))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "案件代碼不得為空。" }));
                return;
            }

            if (string.IsNullOrEmpty(data.S_COM))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "請選擇通報單位。" }));
                return;
            }

            if (string.IsNullOrEmpty(data.G_COM))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "請選擇權責處理單位。" }));
                return;
            }

            string currentLoginUser = Session["LoginUser"] != null ? Session["LoginUser"].ToString() : "";

            // 更新通報與處理單位資訊
            string updateSql = @"UPDATE RoadDirty_CaseMain 
                SET S_COM = @scom,
                    G_COM = @gcom,
                    S_User = @suser,
                    SetCOM_Date = GETDATE()
                WHERE Dirty_ID = @id";

            var updateParams = new SqlParameter[]
            {
                new SqlParameter("@scom", data.S_COM),
                new SqlParameter("@gcom", data.G_COM),
                new SqlParameter("@suser", currentLoginUser),
                new SqlParameter("@id", data.Dirty_ID)
            };

            DbHelper.ExecuteNonQuery(updateSql, updateParams);

            // 寫入 AuditLog 派工紀錄
            AuditLogger.Log(
                operatorUser: currentLoginUser,
                actionType: "DISPATCH_ASSIGN",
                targetUser: data.G_COM,
                clientIp: Request.UserHostAddress,
                details: string.Format("道路髒污案件派工：案號 {0}, 通報單位 {1}, 權責單位 {2}", data.Dirty_ID, data.S_COM, data.G_COM),
                oldValue: null,
                newValue: null
            );

            // 寄送派工通報 Email
            string emailStatus = "未寄送郵件";
            try
            {
                emailStatus = SendDispatchEmail(data);
            }
            catch (Exception ex)
            {
                emailStatus = "寄送郵件發生錯誤：" + ex.Message;
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                Message = "派工通知已成功送出！",
                EmailResult = emailStatus
            }));
        }

        private string SendDispatchEmail(DispatchSubmitDto data)
        {
            // 讀取案件資訊與處理單位資訊
            string sql = @"SELECT RoadDirty_CaseMain.*, C_TOWN.TOWN_NA,
                (SELECT TOP 1 UnitName FROM RoadDirty_Unit WHERE RoadDirty_Unit.UnitID = @gcom) AS TargetUnitName
                FROM RoadDirty_CaseMain
                LEFT JOIN C_TOWN ON RoadDirty_CaseMain.TOWN_CODE = C_TOWN.TOWN_NO
                WHERE Dirty_ID = @id";

            DataTable dt = DbHelper.ExecuteDataTable(sql, new SqlParameter[]
            {
                new SqlParameter("@id", data.Dirty_ID),
                new SqlParameter("@gcom", data.G_COM)
            });

            if (dt.Rows.Count == 0) return "找不到案件";

            DataRow r = dt.Rows[0];
            string unitName = r["TargetUnitName"] != DBNull.Value ? r["TargetUnitName"].ToString() : "權責單位";
            string townName = r["TOWN_NA"] != DBNull.Value ? r["TOWN_NA"].ToString() : "";
            string roadName = r["ROAD_Name"] != DBNull.Value ? r["ROAD_Name"].ToString() : "";
            string showId = (r["Show_ID"] != DBNull.Value && !string.IsNullOrEmpty(r["Show_ID"].ToString().Trim())) ? r["Show_ID"].ToString().Trim() : data.Dirty_ID;
            string memo = r["COMM"] != DBNull.Value ? r["COMM"].ToString() : "";

            // 取得處理單位所有有填寫 Email 之收件人
            string userSql = "SELECT UserEmail, RunUser FROM RoadDirty_UnitUser WHERE UnitID = @gcom AND UserEmail IS NOT NULL AND LTRIM(RTRIM(UserEmail)) <> ''";
            DataTable dtUsers = DbHelper.ExecuteDataTable(userSql, new SqlParameter("@gcom", data.G_COM));

            List<string> emailList = new List<string>();
            foreach (DataRow ur in dtUsers.Rows)
            {
                string em = ur["UserEmail"].ToString().Trim();
                if (!string.IsNullOrEmpty(em) && em.Contains("@") && !emailList.Contains(em))
                {
                    emailList.Add(em);
                }
            }

            if (emailList.Count == 0)
            {
                return "該處理單位尚未設定聯絡人電子郵件，僅完成資料庫派工更新。";
            }

            string host = WebConfigurationManager.AppSettings["MailHost"] ?? "127.0.0.1";
            string fromMail = WebConfigurationManager.AppSettings["MailFrom"] ?? "noreply@ntpc.gov.tw";
            string fromName = "新北市固定逸散源管理平台";

            using (MailMessage mail = new MailMessage())
            {
                mail.From = new MailAddress(fromMail, fromName, Encoding.UTF8);
                foreach (string em in emailList)
                {
                    mail.To.Add(em);
                }

                mail.Subject = string.Format("【道路髒污通報派工通知】案件編號：{0} ({1} {2})", showId, townName, roadName);
                mail.IsBodyHtml = true;
                mail.BodyEncoding = Encoding.UTF8;

                StringBuilder sb = new StringBuilder();
                sb.Append("<html><body style='font-family:微軟正黑體,Arial; font-size:15px; color:#333; line-height:1.6;'>");
                sb.Append("<div style='max-width:650px; margin:0 auto; border:1px solid #0284c7; border-radius:8px; overflow:hidden;'>");
                sb.Append("<div style='background:linear-gradient(135deg, #0b1f7d, #0284c7); color:#fff; padding:16px 20px;'>");
                sb.Append("<h3 style='margin:0; font-size:18px;'>新北市固定逸散源管理平台 - 道路髒污現場通報派工單</h3>");
                sb.Append("</div>");
                sb.Append("<div style='padding:20px;'>");
                sb.AppendFormat("<p><strong>致 {0} 權責主管與承辦人員：</strong></p>", unitName);
                sb.Append("<p>本府外勤查核小組於巡檢作業中發現道路髒污情事，已指派交辦貴單位進行現場清理與改善作業，詳細資訊如下：</p>");
                sb.Append("<table style='width:100%; border-collapse:collapse; margin:16px 0;'>");
                sb.AppendFormat("<tr><td style='border:1px solid #ddd; padding:8px 12px; background:#f8fafc; width:130px;'><strong>案件代號</strong></td><td style='border:1px solid #ddd; padding:8px 12px;'>{0}</td></tr>", showId);
                sb.AppendFormat("<tr><td style='border:1px solid #ddd; padding:8px 12px; background:#f8fafc;'><strong>行政區/路段</strong></td><td style='border:1px solid #ddd; padding:8px 12px;'>{0} {1}</td></tr>", townName, roadName);
                sb.AppendFormat("<tr><td style='border:1px solid #ddd; padding:8px 12px; background:#f8fafc;'><strong>派工時間</strong></td><td style='border:1px solid #ddd; padding:8px 12px;'>{0}</td></tr>", DateTime.Now.ToString("yyyy-MM-dd HH:mm"));
                sb.AppendFormat("<tr><td style='border:1px solid #ddd; padding:8px 12px; background:#f8fafc;'><strong>現場巡查備註</strong></td><td style='border:1px solid #ddd; padding:8px 12px;'>{0}</td></tr>", string.IsNullOrEmpty(memo) ? "無" : memo);
                sb.Append("</table>");
                sb.Append("<p style='color:#0b1f7d;'>請貴單位儘速派員前往現場確認並清除污染，完成改善後請至管理平台填報成果照片以利結案銷案。</p>");
                sb.Append("<hr style='border:none; border-top:1px dashed #ccc; margin:20px 0;' />");
                sb.Append("<p style='font-size:12px; color:#888;'>此信件為系統自動發送，請勿直接回覆此郵件。</p>");
                sb.Append("</div></div></body></html>");

                mail.Body = sb.ToString();

                using (SmtpClient smtp = new SmtpClient(host))
                {
                    smtp.Send(mail);
                }
            }

            return string.Format("已發送至 {0} 個電子郵件地址", emailList.Count);
        }

        // 讀取現場佐證照片
        private List<PhotoItemDto> LoadEvidencePhotos(string dirtyId)
        {
            List<PhotoItemDto> list = new List<PhotoItemDto>();
            string relDir = "/Upload/RoadDirtyPIC/" + dirtyId + "/";
            string physDir = PathHelper.FindDirectory(relDir);

            if (!Directory.Exists(physDir))
            {
                return list;
            }

            DirectoryInfo di = new DirectoryInfo(physDir);
            FileInfo[] files = di.GetFiles("*.*");
            int idx = 1;
            foreach (FileInfo f in files)
            {
                string ext = f.Extension.ToLower();
                if (ext == ".jpg" || ext == ".jpeg" || ext == ".png")
                {
                    // 排除改善後照片 (G_ 開頭)
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

        // TWD97 -> WGS84 坐標轉換
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

        #region DTO 傳輸類別 (完全符合 C# 5.0)
        public class UnitItemDto
        {
            public string UnitID { get; set; }
            public string UnitName { get; set; }
        }

        public class UnitUserDto
        {
            public string RunUser { get; set; }
            public string UserEmail { get; set; }
            public string Name { get; set; }
        }

        public class PhotoItemDto
        {
            public string FileName { get; set; }
            public string Url { get; set; }
            public string Title { get; set; }
        }

        public class EmailUpdateDto
        {
            public string RunUser { get; set; }
            public string UserEmail { get; set; }
            public string UnitID { get; set; }
        }

        public class DispatchSubmitDto
        {
            public string Dirty_ID { get; set; }
            public string S_COM { get; set; }
            public string G_COM { get; set; }
        }
        #endregion
    }
}
