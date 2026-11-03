using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Mail;
using System.Text;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.Configuration;
using System.Web.Script.Serialization;
using System.Web.UI;
using NTPC_FEC.Helpers;
using NTPC_FEC.Security;

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
                case "fetch_rdm":
                    FetchFromRdmSystem(Request["rdmId"]);
                    break;
                case "save":
                    SaveImproveRecord();
                    break;
                default:
                    Response.Write(json.Serialize(new { Success = false, Message = "未知的操作指令：" + action }));
                    break;
            }
        }

        // 自動檢查並補齊資料表新欄位 (確保免手動跑 SQL 也能運作)
        private void EnsureRoadBreakColumns()
        {
            try
            {
                string alterSql = @"
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.RoadBreak_CaseMain') AND name = 'G_Report_Date')
    ALTER TABLE dbo.RoadBreak_CaseMain ADD G_Report_Date DATETIME NULL;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.RoadBreak_CaseMain') AND name = 'G_Fix_Status')
    ALTER TABLE dbo.RoadBreak_CaseMain ADD G_Fix_Status NVARCHAR(200) NULL;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.RoadBreak_CaseMain') AND name = 'G_Contact_Phone')
    ALTER TABLE dbo.RoadBreak_CaseMain ADD G_Contact_Phone NVARCHAR(50) NULL;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.RoadBreak_CaseMain') AND name = 'G_Delay_Reason')
    ALTER TABLE dbo.RoadBreak_CaseMain ADD G_Delay_Reason NVARCHAR(300) NULL;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.RoadBreak_CaseMain') AND name = 'G_Reply_Type')
    ALTER TABLE dbo.RoadBreak_CaseMain ADD G_Reply_Type NVARCHAR(50) NULL;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.RoadBreak_CaseMain') AND name = 'G_Reply_Memo')
    ALTER TABLE dbo.RoadBreak_CaseMain ADD G_Reply_Memo NVARCHAR(1500) NULL;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.RoadBreak_CaseMain') AND name = 'G_Reply_Date')
    ALTER TABLE dbo.RoadBreak_CaseMain ADD G_Reply_Date DATETIME NULL;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.RoadBreak_CaseMain') AND name = 'Damage_Count')
    ALTER TABLE dbo.RoadBreak_CaseMain ADD Damage_Count NVARCHAR(20) NULL;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.RoadBreak_CaseMain') AND name = 'District_Office')
    ALTER TABLE dbo.RoadBreak_CaseMain ADD District_Office NVARCHAR(100) NULL;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.RoadBreak_CaseMain') AND name = 'Handle_Unit')
    ALTER TABLE dbo.RoadBreak_CaseMain ADD Handle_Unit NVARCHAR(150) NULL;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.RoadBreak_CaseMain') AND name = 'Handle_Status')
    ALTER TABLE dbo.RoadBreak_CaseMain ADD Handle_Status NVARCHAR(100) NULL;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.RoadBreak_CaseMain') AND name = 'RDM_Case_ID')
    ALTER TABLE dbo.RoadBreak_CaseMain ADD RDM_Case_ID NVARCHAR(50) NULL;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.RoadBreak_CaseMain') AND name = 'Need_Follow')
    ALTER TABLE dbo.RoadBreak_CaseMain ADD Need_Follow CHAR(1) NULL;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.RoadBreak_CaseMain') AND name = 'Follow_Memo')
    ALTER TABLE dbo.RoadBreak_CaseMain ADD Follow_Memo NVARCHAR(500) NULL;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.RoadBreak_CaseMain') AND name = 'PCI_Type')
    ALTER TABLE dbo.RoadBreak_CaseMain ADD PCI_Type NVARCHAR(100) NULL;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.RoadBreak_CaseMain') AND name = 'PCI_Severity')
    ALTER TABLE dbo.RoadBreak_CaseMain ADD PCI_Severity NVARCHAR(20) NULL;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.RoadBreak_CaseMain') AND name = 'Supervisor_Suggest')
    ALTER TABLE dbo.RoadBreak_CaseMain ADD Supervisor_Suggest NVARCHAR(300) NULL;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.RoadBreak_CaseMain') AND name = 'Dispatch_Memo')
    ALTER TABLE dbo.RoadBreak_CaseMain ADD Dispatch_Memo NVARCHAR(500) NULL;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.RoadBreak_CaseMain') AND name = 'Dispatch_Done_Date')
    ALTER TABLE dbo.RoadBreak_CaseMain ADD Dispatch_Done_Date NVARCHAR(50) NULL;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.RoadBreak_CaseMain') AND name = 'Dispatch_Report_Date')
    ALTER TABLE dbo.RoadBreak_CaseMain ADD Dispatch_Report_Date NVARCHAR(50) NULL;
";
                DbHelper.ExecuteNonQuery(alterSql);
            }
            catch { }
        }

        // 初始化頁面資料 (完整對標路平報馬仔通報與處理回報)
        private void InitPageData()
        {
            string breakId = Request["id"];
            if (string.IsNullOrEmpty(breakId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "缺少通報案號參數。" }));
                return;
            }

            EnsureRoadBreakColumns();

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
                if (DateTime.TryParse(r["Report_Date"].ToString(), out dtRep)) reportDateStr = dtRep.ToString("yyyy/MM/dd HH:mm");
            }

            string setComDateStr = "";
            if (r["SetCOM_Date"] != DBNull.Value)
            {
                DateTime dtSet;
                if (DateTime.TryParse(r["SetCOM_Date"].ToString(), out dtSet)) setComDateStr = dtSet.ToString("yyyy/MM/dd HH:mm");
            }

            string improveDateStr = "";
            if (r["Improve_Date"] != DBNull.Value)
            {
                DateTime dtImp;
                if (DateTime.TryParse(r["Improve_Date"].ToString(), out dtImp) && dtImp.Year > 1911)
                {
                    improveDateStr = dtImp.ToString("yyyy/MM/dd HH:mm");
                }
            }

            string reportBackDateStr = "";
            if (r.Table.Columns.Contains("G_Report_Date") && r["G_Report_Date"] != DBNull.Value)
            {
                DateTime dtRepBack;
                if (DateTime.TryParse(r["G_Report_Date"].ToString(), out dtRepBack) && dtRepBack.Year > 1911)
                {
                    reportBackDateStr = dtRepBack.ToString("yyyy/MM/dd HH:mm");
                }
            }

            string replyDateStr = "";
            if (r.Table.Columns.Contains("G_Reply_Date") && r["G_Reply_Date"] != DBNull.Value)
            {
                DateTime dtRepDate;
                if (DateTime.TryParse(r["G_Reply_Date"].ToString(), out dtRepDate) && dtRepDate.Year > 1911)
                {
                    replyDateStr = dtRepDate.ToString("yyyy/MM/dd HH:mm");
                }
            }

            // 讀取新對標通報欄位
            string damageCat = r.Table.Columns.Contains("Damage_Category") && r["Damage_Category"] != DBNull.Value ? r["Damage_Category"].ToString().Trim() : "路面損壞";
            string damageType = r.Table.Columns.Contains("Damage_Type") && r["Damage_Type"] != DBNull.Value ? r["Damage_Type"].ToString().Trim() : "";
            string damageLen = r.Table.Columns.Contains("Damage_Length") && r["Damage_Length"] != DBNull.Value ? r["Damage_Length"].ToString().Trim() : "";
            string damageWid = r.Table.Columns.Contains("Damage_Width") && r["Damage_Width"] != DBNull.Value ? r["Damage_Width"].ToString().Trim() : "";
            string damageCount = r.Table.Columns.Contains("Damage_Count") && r["Damage_Count"] != DBNull.Value ? r["Damage_Count"].ToString().Trim() : "1";
            string locationDesc = r.Table.Columns.Contains("Location_Desc") && r["Location_Desc"] != DBNull.Value ? r["Location_Desc"].ToString().Trim() : "";
            string laneInfo = r.Table.Columns.Contains("Lane_Info") && r["Lane_Info"] != DBNull.Value ? r["Lane_Info"].ToString().Trim() : "全車道";
            string direction = r.Table.Columns.Contains("Direction") && r["Direction"] != DBNull.Value ? r["Direction"].ToString().Trim() : "無法判定";
            string roadType = r.Table.Columns.Contains("Road_Type") && r["Road_Type"] != DBNull.Value ? r["Road_Type"].ToString().Trim() : "平面";

            // 歷史案件兼容映射
            if (string.IsNullOrEmpty(damageType))
            {
                string oldHole = r["Hole_Conn_St"] != DBNull.Value ? r["Hole_Conn_St"].ToString().Trim() : "";
                string oldSmooth = r["Smooth"] != DBNull.Value ? r["Smooth"].ToString().Trim() : "";
                if (oldHole == "3" || oldHole == "4") damageType = "人手孔蓋週邊破損";
                else if (oldHole == "2") damageType = "人手孔蓋欠平順";
                else if (oldSmooth == "4") damageType = "坑洞";
                else if (oldSmooth == "2") damageType = "龜裂";
                else if (oldSmooth == "3") damageType = "凹陷";
                else damageType = "路面破損";
            }

            // 讀取路平報馬仔對標進階欄位
            string rdmCaseId = r.Table.Columns.Contains("RDM_Case_ID") && r["RDM_Case_ID"] != DBNull.Value ? r["RDM_Case_ID"].ToString().Trim() : "";
            string needFollow = r.Table.Columns.Contains("Need_Follow") && r["Need_Follow"] != DBNull.Value ? r["Need_Follow"].ToString().Trim() : "N";
            string followMemo = r.Table.Columns.Contains("Follow_Memo") && r["Follow_Memo"] != DBNull.Value ? r["Follow_Memo"].ToString().Trim() : "";
            string pciType = r.Table.Columns.Contains("PCI_Type") && r["PCI_Type"] != DBNull.Value ? r["PCI_Type"].ToString().Trim() : damageType;
            string pciSeverity = r.Table.Columns.Contains("PCI_Severity") && r["PCI_Severity"] != DBNull.Value ? r["PCI_Severity"].ToString().Trim() : "輕";
            string supervisorSuggest = r.Table.Columns.Contains("Supervisor_Suggest") && r["Supervisor_Suggest"] != DBNull.Value ? r["Supervisor_Suggest"].ToString().Trim() : "尚未設定";
            string dispatchMemo = r.Table.Columns.Contains("Dispatch_Memo") && r["Dispatch_Memo"] != DBNull.Value ? r["Dispatch_Memo"].ToString().Trim() : "";
            string dispatchDoneDate = r.Table.Columns.Contains("Dispatch_Done_Date") && r["Dispatch_Done_Date"] != DBNull.Value ? r["Dispatch_Done_Date"].ToString().Trim() : "無派工";
            string dispatchReportDate = r.Table.Columns.Contains("Dispatch_Report_Date") && r["Dispatch_Report_Date"] != DBNull.Value ? r["Dispatch_Report_Date"].ToString().Trim() : "無派工";

            // 讀取處理回報欄位 (不預設強制帶入範本或帳號名稱)
            string fixStatus = r.Table.Columns.Contains("G_Fix_Status") && r["G_Fix_Status"] != DBNull.Value ? r["G_Fix_Status"].ToString().Trim() : "";
            string contactPhone = r.Table.Columns.Contains("G_Contact_Phone") && r["G_Contact_Phone"] != DBNull.Value ? r["G_Contact_Phone"].ToString().Trim() : "";
            string delayReason = r.Table.Columns.Contains("G_Delay_Reason") && r["G_Delay_Reason"] != DBNull.Value ? r["G_Delay_Reason"].ToString().Trim() : "";
            string replyType = r.Table.Columns.Contains("G_Reply_Type") && r["G_Reply_Type"] != DBNull.Value ? r["G_Reply_Type"].ToString().Trim() : "";
            string gMemo = r["G_Memo"] != DBNull.Value ? r["G_Memo"].ToString().Trim() : "";

            string dbGUser = r["G_USER"] != DBNull.Value ? r["G_USER"].ToString().Trim() : "";
            string dbGUserName = r["G_UserName"] != DBNull.Value ? r["G_UserName"].ToString().Trim() : "";
            string displayGUser = !string.IsNullOrEmpty(dbGUserName) ? dbGUserName : dbGUser;

            string replyMemo = r.Table.Columns.Contains("G_Reply_Memo") && r["G_Reply_Memo"] != DBNull.Value ? r["G_Reply_Memo"].ToString().Trim() : "";

            var caseData = new
            {
                Break_ID = r["Break_ID"].ToString().Trim(),
                Show_ID = r["Show_ID"] != DBNull.Value ? r["Show_ID"].ToString().Trim() : r["Break_ID"].ToString().Trim(),
                RDM_Case_ID = rdmCaseId,
                Need_Follow = needFollow,
                Follow_Memo = followMemo,
                PCI_Type = pciType,
                PCI_Severity = pciSeverity,
                Supervisor_Suggest = supervisorSuggest,
                Dispatch_Memo = dispatchMemo,
                Dispatch_Done_Date = dispatchDoneDate,
                Dispatch_Report_Date = dispatchReportDate,
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
                Damage_Category = damageCat,
                Damage_Type = damageType,
                Damage_Length = damageLen,
                Damage_Width = damageWid,
                Damage_Count = damageCount,
                Location_Desc = locationDesc,
                Lane_Info = laneInfo,
                Direction = direction,
                District_Office = (r.Table.Columns.Contains("District_Office") && r["District_Office"] != DBNull.Value && !string.IsNullOrEmpty(r["District_Office"].ToString()) ? r["District_Office"].ToString().Trim() : (r["TOWN_NA"] != DBNull.Value && !string.IsNullOrEmpty(r["TOWN_NA"].ToString()) ? r["TOWN_NA"].ToString().Trim() + "公所" : "")),
                Handle_Unit = (r.Table.Columns.Contains("Handle_Unit") && r["Handle_Unit"] != DBNull.Value && !string.IsNullOrEmpty(r["Handle_Unit"].ToString()) ? r["Handle_Unit"].ToString().Trim() : (r["G_COM_NAME"] != DBNull.Value && !string.IsNullOrEmpty(r["G_COM_NAME"].ToString()) ? r["G_COM_NAME"].ToString().Trim() : "健利營造有限公司")),
                Handle_Status = (r.Table.Columns.Contains("Handle_Status") && r["Handle_Status"] != DBNull.Value && !string.IsNullOrEmpty(r["Handle_Status"].ToString()) ? r["Handle_Status"].ToString().Trim() : "機關自行修補"),
                Road_Type = roadType,
                Smooth = r["Smooth"].ToString(),
                Smooth_Str = r["Smooth_Str"].ToString(),
                Hole_Conn_St = r["Hole_Conn_St"].ToString(),
                Hole_Conn_St_Str = r["Hole_Conn_St_Str"].ToString(),
                Memo = r["Memo"] != DBNull.Value ? r["Memo"].ToString() : "",
                G_COM = r["G_COM"].ToString(),
                G_COM_NAME = r["G_COM_NAME"].ToString(),
                Improve_Date = improveDateStr,
                G_Report_Date = reportBackDateStr,
                G_Fix_Status = fixStatus,
                G_Contact_Phone = contactPhone,
                G_Delay_Reason = delayReason,
                G_Reply_Type = replyType,
                G_Reply_Memo = replyMemo,
                G_Reply_Date = replyDateStr,
                G_USER = displayGUser,
                G_UserName = displayGUser,
                G_Memo = gMemo,
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

        // ==================== 新北市路平報馬仔系統自動爬蟲與完工照片下載 ====================
        private void FetchFromRdmSystem(string rawRdmInput)
        {
            if (string.IsNullOrEmpty(rawRdmInput))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "請先輸入新北市路平報馬仔反映編號 (例如 2078092) 或案件網址。" }));
                return;
            }

            // 支援直接貼網址或純編號，自動萃取 id
            string cleanRdmId = rawRdmInput.Trim();
            Match mUrlId = Regex.Match(cleanRdmId, @"[?&]id=(\d+)", RegexOptions.IgnoreCase);
            if (mUrlId.Success)
            {
                cleanRdmId = mUrlId.Groups[1].Value;
            }
            else
            {
                Match mDigits = Regex.Match(cleanRdmId, @"(\d{5,12})");
                if (mDigits.Success)
                {
                    cleanRdmId = mDigits.Groups[1].Value;
                }
            }

            string targetUrl = "https://rdm.ntpc.gov.tw/ROAD/SatisfySurvey.aspx?id=" + HttpUtility.UrlEncode(cleanRdmId);

            try
            {
                // 啟用 TLS 1.1 / TLS 1.2
                ServicePointManager.SecurityProtocol |= (SecurityProtocolType)3072 | (SecurityProtocolType)768;

                HttpWebRequest req = (HttpWebRequest)WebRequest.Create(targetUrl);
                req.Method = "GET";
                req.Timeout = 15000;
                req.ReadWriteTimeout = 15000;
                req.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36";
                req.Accept = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8";

                string htmlContent = "";
                using (HttpWebResponse resp = (HttpWebResponse)req.GetResponse())
                using (StreamReader reader = new StreamReader(resp.GetResponseStream(), Encoding.UTF8))
                {
                    htmlContent = reader.ReadToEnd();
                }

                if (string.IsNullOrEmpty(htmlContent) || htmlContent.IndexOf("處理回報") < 0)
                {
                    Response.Write(json.Serialize(new
                    {
                        Success = false,
                        NeedClipboardFallback = true,
                        Message = "連線成功但未讀取到路平報馬仔案件表格（可能編號不存在或網頁已改版），請改用「貼上網頁文字智慧解析」或點選右側直連開啟網頁。"
                    }));
                    return;
                }

                // 解析 HTML Table 結構
                Uri baseUri = new Uri(targetUrl);
                RdmParsedResultDto parsed = ParseRdmHtmlTable(htmlContent, baseUri, cleanRdmId);

                Response.Write(json.Serialize(new
                {
                    Success = true,
                    Message = "已成功從新北市路平報馬仔系統自動同步案件（編號 " + cleanRdmId + "）之處理回報、結案回覆與完工照片！",
                    Data = parsed
                }));
            }
            catch (Exception ex)
            {
                Response.Write(json.Serialize(new
                {
                    Success = false,
                    NeedClipboardFallback = true,
                    Message = "自動連線路平報馬仔系統受阻（" + ex.Message + "）。若機房防火牆限制外網連線，請點選「↗ 開啟路平網頁」複製全文後，使用「📋 貼上網頁文字智慧解析」一鍵帶入！"
                }));
            }
        }

        private RdmParsedResultDto ParseRdmHtmlTable(string html, Uri baseUri, string defaultRdmId)
        {
            RdmParsedResultDto res = new RdmParsedResultDto();
            res.RDM_Case_ID = defaultRdmId;
            res.DownloadedPhotos = new List<PhotoUploadItem>();
            res.MatchedKeywords = new List<string>();

            // 移除 script 與 style
            string cleanHtml = Regex.Replace(html, @"<(script|style)[^>]*>[\s\S]*?</\1>", "", RegexOptions.IgnoreCase);

            // 狀態機：0=通報項目, 1=處理回報, 2=結案回覆, 3=滿意度調查(停止)
            int sectionState = 0;

            MatchCollection rowMatches = Regex.Matches(cleanHtml, @"<tr[^>]*>([\s\S]*?)</tr>", RegexOptions.IgnoreCase);
            foreach (Match rowMatch in rowMatches)
            {
                string rowInner = rowMatch.Groups[1].Value;
                string rowPlainText = CleanHtmlText(rowInner);

                if (rowPlainText.IndexOf("滿意度調查") >= 0 || rowPlainText.IndexOf("滿意程度") >= 0)
                {
                    sectionState = 3;
                    break;
                }
                if (rowPlainText == "處理回報" || (rowPlainText.IndexOf("處理回報") >= 0 && rowPlainText.Length <= 10))
                {
                    sectionState = 1;
                    continue;
                }
                if (rowPlainText == "結案回覆" || (rowPlainText.IndexOf("結案回覆") >= 0 && rowPlainText.Length <= 10))
                {
                    sectionState = 2;
                    continue;
                }

                MatchCollection cellMatches = Regex.Matches(rowInner, @"<t[dh][^>]*>([\s\S]*?)</t[dh]>", RegexOptions.IgnoreCase);
                if (cellMatches.Count < 2) continue;

                for (int i = 0; i < cellMatches.Count - 1; i++)
                {
                    string rawLabel = CleanHtmlText(cellMatches[i].Groups[1].Value);
                    string rawValHtml = cellMatches[i + 1].Groups[1].Value;
                    string rawValText = CleanHtmlText(rawValHtml);

                    if (string.IsNullOrEmpty(rawLabel)) continue;

                    if (sectionState == 0)
                    {
                        // 通報項目區段
                        if (rawLabel == "反映編號" && !string.IsNullOrEmpty(rawValText))
                        {
                            res.RDM_Case_ID = rawValText;
                            i++;
                        }
                        else if (rawLabel == "反映日期" && !string.IsNullOrEmpty(rawValText))
                        {
                            res.Report_Date = rawValText;
                            i++;
                        }
                        else if (rawLabel == "損壞型式(PCI)")
                        {
                            res.PCI_Type = rawValText;
                            i++;
                        }
                        else if (rawLabel == "嚴重程度(PCI)")
                        {
                            res.PCI_Severity = rawValText;
                            i++;
                        }
                        else if (rawLabel == "監造建議修補事項")
                        {
                            res.Supervisor_Suggest = rawValText;
                            i++;
                        }
                        else if (rawLabel == "處理單位(公所)")
                        {
                            res.District_Office = rawValText;
                            i++;
                        }
                        else if (rawLabel == "處理單位")
                        {
                            res.Handle_Unit = rawValText;
                            i++;
                        }
                        else if (rawLabel == "處理狀態")
                        {
                            res.Handle_Status = rawValText;
                            i++;
                        }
                        else if (rawLabel == "養工處分派說明")
                        {
                            res.Dispatch_Memo = rawValText;
                            i++;
                        }
                    }
                    else if (sectionState == 1)
                    {
                        // 處理回報區段
                        if (rawLabel == "完工日期(派工)")
                        {
                            res.Dispatch_Done_Date = rawValText;
                            i++;
                        }
                        else if (rawLabel == "完工回報日期(派工)")
                        {
                            res.Dispatch_Report_Date = rawValText;
                            i++;
                        }
                        else if (rawLabel == "完工日期")
                        {
                            res.Improve_Date = rawValText;
                            i++;
                        }
                        else if (rawLabel == "完工回報日期")
                        {
                            res.G_Report_Date = rawValText;
                            i++;
                        }
                        else if (rawLabel.IndexOf("路面損壞-性質") >= 0)
                        {
                            ParseDamagePropertyText(rawValText, res);
                            i++;
                        }
                        else if (rawLabel == "後續修復情形")
                        {
                            res.G_Fix_Status = rawValText;
                            i++;
                        }
                        else if (rawLabel == "所屬道路")
                        {
                            res.Road_Name = rawValText;
                            i++;
                        }
                        else if (rawLabel == "承辦人")
                        {
                            res.G_User = rawValText;
                            i++;
                        }
                        else if (rawLabel == "聯絡電話")
                        {
                            res.G_Contact_Phone = rawValText;
                            i++;
                        }
                        else if (rawLabel == "處理說明")
                        {
                            res.G_Memo = rawValText;
                            i++;
                        }
                        else if (rawLabel == "完工照片")
                        {
                            ExtractAndDownloadImprovePhotos(rawValHtml, baseUri, res.DownloadedPhotos);
                            i++;
                        }
                        else if (rawLabel == "延遲原因")
                        {
                            res.G_Delay_Reason = rawValText;
                            i++;
                        }
                    }
                    else if (sectionState == 2)
                    {
                        // 結案回覆區段
                        if (rawLabel == "回覆時間")
                        {
                            res.G_Reply_Date = rawValText;
                            i++;
                        }
                        else if (rawLabel == "回覆方式")
                        {
                            res.G_Reply_Type = rawValText;
                            i++;
                        }
                        else if (rawLabel == "回覆說明")
                        {
                            res.G_Reply_Memo = rawValText;
                            i++;
                        }
                    }
                }
            }

            // 智慧判讀是否建議持續追蹤
            string combinedCheckText = (res.G_Fix_Status ?? "") + " " + (res.G_Memo ?? "") + " " + (res.G_Reply_Memo ?? "");
            string[] followKeywords = new string[] { "持續追蹤", "加強巡查", "堪用", "觀察", "錄案", "暫補", "臨補", "擇期", "開口契約", "預計" };
            foreach (string kw in followKeywords)
            {
                if (combinedCheckText.IndexOf(kw) >= 0 && !res.MatchedKeywords.Contains(kw))
                {
                    res.MatchedKeywords.Add(kw);
                }
            }

            res.SuggestedNeedFollow = res.MatchedKeywords.Count > 0 ? "Y" : "N";
            if (res.SuggestedNeedFollow == "Y")
            {
                res.SuggestedFollowMemo = "路平報馬仔回報為「" + (!string.IsNullOrEmpty(res.G_Memo) ? res.G_Memo : res.G_Fix_Status) + "」，尚未永久刨鋪修復，建議機關持續追蹤巡查。";
            }

            return res;
        }

        private void ParseDamagePropertyText(string text, RdmParsedResultDto res)
        {
            if (string.IsNullOrEmpty(text)) return;

            // 例如: "龜裂 長：3m 寬：0.1m 共1處"
            Match mLen = Regex.Match(text, @"長[：:]\s*([0-9.]+)", RegexOptions.IgnoreCase);
            if (mLen.Success) res.Damage_Length = mLen.Groups[1].Value;

            Match mWid = Regex.Match(text, @"寬[：:]\s*([0-9.]+)", RegexOptions.IgnoreCase);
            if (mWid.Success) res.Damage_Width = mWid.Groups[1].Value;

            Match mCnt = Regex.Match(text, @"共\s*([0-9]+)\s*處", RegexOptions.IgnoreCase);
            if (mCnt.Success) res.Damage_Count = mCnt.Groups[1].Value;

            string mainType = text;
            int idxLen = mainType.IndexOf("長：");
            if (idxLen < 0) idxLen = mainType.IndexOf("長:");
            if (idxLen > 0) mainType = mainType.Substring(0, idxLen).Trim();
            if (!string.IsNullOrEmpty(mainType))
            {
                res.Damage_Type = mainType;
            }
        }

        private void ExtractAndDownloadImprovePhotos(string cellHtml, Uri baseUri, List<PhotoUploadItem> targetList)
        {
            if (string.IsNullOrEmpty(cellHtml)) return;

            List<string> candidateUrls = new List<string>();

            // 擷取 <a href="...">
            MatchCollection aMatches = Regex.Matches(cellHtml, @"<a[^>]+href=[""']([^""']+)[""'][^>]*>", RegexOptions.IgnoreCase);
            foreach (Match m in aMatches)
            {
                string href = HttpUtility.HtmlDecode(m.Groups[1].Value).Trim();
                if (!string.IsNullOrEmpty(href) && !href.StartsWith("javascript:", StringComparison.OrdinalIgnoreCase) && !href.StartsWith("#"))
                {
                    if (!candidateUrls.Contains(href)) candidateUrls.Add(href);
                }
            }

            // 擷取 onclick="...window.open('...')..."
            MatchCollection ocMatches = Regex.Matches(cellHtml, @"window\.open\s*\(\s*[""']([^""']+)[""']", RegexOptions.IgnoreCase);
            foreach (Match m in ocMatches)
            {
                string ocUrl = HttpUtility.HtmlDecode(m.Groups[1].Value).Trim();
                if (!string.IsNullOrEmpty(ocUrl) && !candidateUrls.Contains(ocUrl))
                {
                    candidateUrls.Add(ocUrl);
                }
            }

            // 擷取 <img src="...">
            MatchCollection imgMatches = Regex.Matches(cellHtml, @"<img[^>]+src=[""']([^""']+)[""'][^>]*>", RegexOptions.IgnoreCase);
            foreach (Match m in imgMatches)
            {
                string src = HttpUtility.HtmlDecode(m.Groups[1].Value).Trim();
                if (!string.IsNullOrEmpty(src) && !src.StartsWith("data:", StringComparison.OrdinalIgnoreCase))
                {
                    if (!candidateUrls.Contains(src)) candidateUrls.Add(src);
                }
            }

            int seq = 1;
            foreach (string relOrAbsUrl in candidateUrls)
            {
                if (seq > 6) break;
                try
                {
                    Uri fullUri = new Uri(baseUri, relOrAbsUrl);
                    string b64 = TryDownloadImageAsBase64(fullUri, baseUri.AbsoluteUri, 0);
                    if (!string.IsNullOrEmpty(b64))
                    {
                        targetList.Add(new PhotoUploadItem
                        {
                            TargetTitle = "完工照片 " + seq,
                            FileName = string.Format("改善後佐證照片_{0}.jpg", seq),
                            Base64Data = b64,
                            IsDeleted = false
                        });
                        seq++;
                    }
                }
                catch { }
            }
        }

        private string TryDownloadImageAsBase64(Uri targetUri, string refererUrl, int depth)
        {
            if (depth > 1 || targetUri == null) return null;
            try
            {
                HttpWebRequest imgReq = (HttpWebRequest)WebRequest.Create(targetUri);
                imgReq.Method = "GET";
                imgReq.Timeout = 10000;
                imgReq.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36";
                if (!string.IsNullOrEmpty(refererUrl)) imgReq.Referer = refererUrl;

                using (HttpWebResponse imgResp = (HttpWebResponse)imgReq.GetResponse())
                {
                    string contentType = imgResp.ContentType != null ? imgResp.ContentType.ToLower() : "";
                    using (MemoryStream ms = new MemoryStream())
                    {
                        Stream respStream = imgResp.GetResponseStream();
                        byte[] buffer = new byte[8192];
                        int read;
                        while ((read = respStream.Read(buffer, 0, buffer.Length)) > 0)
                        {
                            ms.Write(buffer, 0, read);
                        }

                        byte[] rawBytes = ms.ToArray();
                        if (rawBytes.Length < 100) return null;

                        // 若該連結回傳的是 HTML 網頁 (例如 ShowPic.aspx)，二次擷取網頁內部的 <img src="...">
                        if (contentType.IndexOf("text/html") >= 0 || (rawBytes[0] == '<' || (rawBytes.Length > 10 && Encoding.UTF8.GetString(rawBytes, 0, Math.Min(256, rawBytes.Length)).IndexOf("<html", StringComparison.OrdinalIgnoreCase) >= 0)))
                        {
                            string innerHtml = Encoding.UTF8.GetString(rawBytes);
                            Match mInnerImg = Regex.Match(innerHtml, @"<img[^>]+src=[""']([^""']+)[""'][^>]*>", RegexOptions.IgnoreCase);
                            if (mInnerImg.Success)
                            {
                                string innerSrc = HttpUtility.HtmlDecode(mInnerImg.Groups[1].Value).Trim();
                                if (innerSrc.StartsWith("data:image/", StringComparison.OrdinalIgnoreCase))
                                {
                                    return innerSrc;
                                }
                                Uri innerUri = new Uri(targetUri, innerSrc);
                                return TryDownloadImageAsBase64(innerUri, targetUri.AbsoluteUri, depth + 1);
                            }
                            return null;
                        }

                        string mime = "image/jpeg";
                        if (contentType.IndexOf("png") >= 0 || (rawBytes.Length > 4 && rawBytes[0] == 0x89 && rawBytes[1] == 0x50))
                        {
                            mime = "image/png";
                        }
                        else if (contentType.IndexOf("gif") >= 0 || (rawBytes.Length > 4 && rawBytes[0] == 0x47 && rawBytes[1] == 0x49))
                        {
                            mime = "image/gif";
                        }

                        return "data:" + mime + ";base64," + Convert.ToBase64String(rawBytes);
                    }
                }
            }
            catch
            {
                return null;
            }
        }

        private string CleanHtmlText(string inputHtml)
        {
            if (string.IsNullOrEmpty(inputHtml)) return "";
            string s = Regex.Replace(inputHtml, @"<br\s*/?>", "\r\n", RegexOptions.IgnoreCase);
            s = Regex.Replace(s, @"<[^>]+>", "");
            s = HttpUtility.HtmlDecode(s);
            return s.Trim();
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

            EnsureRoadBreakColumns();

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
                // 退回時僅標記 G_Back = 'Y' 與退回原因，Improve_Date 保持 NULL (絕不可寫入完工時間，亦不可複製新案號)
                string updateSql = @"UPDATE RoadBreak_CaseMain SET
                    G_User = @G_User,
                    Improve_Date = NULL,
                    G_Memo = @G_Memo,
                    G_Back = 'Y'
                WHERE Break_ID = @Break_ID";

                DbHelper.ExecuteNonQuery(updateSql,
                    new SqlParameter("@G_User", loginUser),
                    new SqlParameter("@G_Memo", input.G_Memo != null ? input.G_Memo : "非本單位權責，退回重新派工"),
                    new SqlParameter("@Break_ID", breakId)
                );

                // 發送退回通知信
                SendImproveNotificationEmail(breakId, true, input.G_Memo, "N", "");

                // 記錄雙軌 AuditLog
                AuditLogger.Log("ROAD_BREAK_IMPROVE_BACK", breakId, string.Format("道路破損案件退回重新派工 (案號:{0}, 原因:{1})", breakId, input.G_Memo ?? ""));

                Response.Write(json.Serialize(new
                {
                    Success = true,
                    Message = "案件已成功退回，請由通報端重新指派權責單位！",
                    RedirectUrl = "BreakDetail.aspx?id=" + HttpUtility.UrlEncode(breakId)
                }));
            }
            else
            {
                // ==================== 改善完成回報 / 建議持續追蹤模式 ====================
                DateTime improveDate = DateTime.Now;
                if (!string.IsNullOrEmpty(input.Improve_Date))
                {
                    DateTime parsedDate;
                    if (DateTime.TryParse(input.Improve_Date.Replace("/", "-"), out parsedDate))
                    {
                        improveDate = parsedDate;
                    }
                }

                DateTime reportDate = DateTime.Now;
                if (!string.IsNullOrEmpty(input.G_Report_Date))
                {
                    DateTime parsedRep;
                    if (DateTime.TryParse(input.G_Report_Date.Replace("/", "-"), out parsedRep))
                    {
                        reportDate = parsedRep;
                    }
                }

                DateTime replyDate = DateTime.Now;
                if (!string.IsNullOrEmpty(input.G_Reply_Date))
                {
                    DateTime parsedReply;
                    if (DateTime.TryParse(input.G_Reply_Date.Replace("/", "-"), out parsedReply))
                    {
                        replyDate = parsedReply;
                    }
                }

                string gUserToSave = !string.IsNullOrEmpty(input.G_User) ? input.G_User.Trim() : "";
                if (gUserToSave.Length > 20) gUserToSave = gUserToSave.Substring(0, 20);

                string gMemo = input.G_Memo != null ? input.G_Memo.Trim() : "";
                string fixStatus = input.G_Fix_Status != null ? input.G_Fix_Status.Trim() : "";
                string contactPhone = input.G_Contact_Phone != null ? input.G_Contact_Phone.Trim() : "";
                string delayReason = input.G_Delay_Reason != null ? input.G_Delay_Reason.Trim() : "";
                string replyType = input.G_Reply_Type != null ? input.G_Reply_Type.Trim() : "";
                string replyMemo = input.G_Reply_Memo != null ? input.G_Reply_Memo.Trim() : "";
                string damageType = input.Damage_Type != null ? input.Damage_Type.Trim() : "";
                string damageLen = input.Damage_Length != null ? input.Damage_Length.Trim() : "";
                string damageWid = input.Damage_Width != null ? input.Damage_Width.Trim() : "";
                string damageCount = input.Damage_Count != null ? input.Damage_Count.Trim() : "1";

                string rdmCaseId = input.RDM_Case_ID != null ? input.RDM_Case_ID.Trim() : "";
                string needFollow = (input.Need_Follow != null && input.Need_Follow.Trim().ToUpper() == "Y") ? "Y" : "N";
                string followMemo = input.Follow_Memo != null ? input.Follow_Memo.Trim() : "";
                string pciType = input.PCI_Type != null ? input.PCI_Type.Trim() : damageType;
                string pciSeverity = input.PCI_Severity != null ? input.PCI_Severity.Trim() : "輕";
                string supervisorSuggest = input.Supervisor_Suggest != null ? input.Supervisor_Suggest.Trim() : "尚未設定";
                string districtOffice = input.District_Office != null ? input.District_Office.Trim() : "";
                string handleUnit = input.Handle_Unit != null ? input.Handle_Unit.Trim() : "";
                string handleStatus = input.Handle_Status != null ? input.Handle_Status.Trim() : "";
                string dispatchMemo = input.Dispatch_Memo != null ? input.Dispatch_Memo.Trim() : "";
                string dispatchDoneDate = input.Dispatch_Done_Date != null ? input.Dispatch_Done_Date.Trim() : "無派工";
                string dispatchReportDate = input.Dispatch_Report_Date != null ? input.Dispatch_Report_Date.Trim() : "無派工";

                bool hasNewCols = CheckIfImproveColumnsExist();

                if (hasNewCols)
                {
                    string updateSql = @"UPDATE RoadBreak_CaseMain SET
                        G_User = @G_User,
                        Improve_Date = @Improve_Date,
                        G_Memo = @G_Memo,
                        G_Back = NULL,
                        G_Report_Date = @G_Report_Date,
                        G_Fix_Status = @G_Fix_Status,
                        G_Contact_Phone = @G_Contact_Phone,
                        G_Delay_Reason = @G_Delay_Reason,
                        G_Reply_Type = @G_Reply_Type,
                        G_Reply_Memo = @G_Reply_Memo,
                        G_Reply_Date = @G_Reply_Date,
                        Damage_Type = CASE WHEN @Damage_Type <> '' THEN @Damage_Type ELSE Damage_Type END,
                        Damage_Length = CASE WHEN @Damage_Length <> '' THEN @Damage_Length ELSE Damage_Length END,
                        Damage_Width = CASE WHEN @Damage_Width <> '' THEN @Damage_Width ELSE Damage_Width END,
                        Damage_Count = @Damage_Count,
                        RDM_Case_ID = CASE WHEN @RDM_Case_ID <> '' THEN @RDM_Case_ID ELSE RDM_Case_ID END,
                        Need_Follow = @Need_Follow,
                        Follow_Memo = @Follow_Memo,
                        PCI_Type = CASE WHEN @PCI_Type <> '' THEN @PCI_Type ELSE PCI_Type END,
                        PCI_Severity = CASE WHEN @PCI_Severity <> '' THEN @PCI_Severity ELSE PCI_Severity END,
                        Supervisor_Suggest = CASE WHEN @Supervisor_Suggest <> '' THEN @Supervisor_Suggest ELSE Supervisor_Suggest END,
                        District_Office = CASE WHEN @District_Office <> '' THEN @District_Office ELSE District_Office END,
                        Handle_Unit = CASE WHEN @Handle_Unit <> '' THEN @Handle_Unit ELSE Handle_Unit END,
                        Handle_Status = CASE WHEN @Handle_Status <> '' THEN @Handle_Status ELSE Handle_Status END,
                        Dispatch_Memo = CASE WHEN @Dispatch_Memo <> '' THEN @Dispatch_Memo ELSE Dispatch_Memo END,
                        Dispatch_Done_Date = CASE WHEN @Dispatch_Done_Date <> '' THEN @Dispatch_Done_Date ELSE Dispatch_Done_Date END,
                        Dispatch_Report_Date = CASE WHEN @Dispatch_Report_Date <> '' THEN @Dispatch_Report_Date ELSE Dispatch_Report_Date END
                    WHERE Break_ID = @Break_ID";

                    DbHelper.ExecuteNonQuery(updateSql,
                        new SqlParameter("@G_User", gUserToSave),
                        new SqlParameter("@Improve_Date", improveDate),
                        new SqlParameter("@G_Memo", gMemo),
                        new SqlParameter("@G_Report_Date", reportDate),
                        new SqlParameter("@G_Fix_Status", fixStatus),
                        new SqlParameter("@G_Contact_Phone", contactPhone),
                        new SqlParameter("@G_Delay_Reason", delayReason),
                        new SqlParameter("@G_Reply_Type", replyType),
                        new SqlParameter("@G_Reply_Memo", replyMemo),
                        new SqlParameter("@G_Reply_Date", replyDate),
                        new SqlParameter("@Damage_Type", damageType),
                        new SqlParameter("@Damage_Length", damageLen),
                        new SqlParameter("@Damage_Width", damageWid),
                        new SqlParameter("@Damage_Count", damageCount),
                        new SqlParameter("@RDM_Case_ID", rdmCaseId),
                        new SqlParameter("@Need_Follow", needFollow),
                        new SqlParameter("@Follow_Memo", followMemo),
                        new SqlParameter("@PCI_Type", pciType),
                        new SqlParameter("@PCI_Severity", pciSeverity),
                        new SqlParameter("@Supervisor_Suggest", supervisorSuggest),
                        new SqlParameter("@District_Office", districtOffice),
                        new SqlParameter("@Handle_Unit", handleUnit),
                        new SqlParameter("@Handle_Status", handleStatus),
                        new SqlParameter("@Dispatch_Memo", dispatchMemo),
                        new SqlParameter("@Dispatch_Done_Date", dispatchDoneDate),
                        new SqlParameter("@Dispatch_Report_Date", dispatchReportDate),
                        new SqlParameter("@Break_ID", breakId)
                    );
                }
                else
                {
                    // 若尚未擴充 DDL，備援整合於 G_Memo 確保零錯誤
                    string memoWithProps = string.Format("{0}\r\n【處理回報】修復情形:{1} | 承辦電話:{2} | 延遲原因:{3} | 回覆方式:{4} | 持續追蹤:{5}",
                        gMemo, fixStatus, contactPhone, delayReason, replyType, needFollow);

                    string updateSql = @"UPDATE RoadBreak_CaseMain SET
                        G_User = @G_User,
                        Improve_Date = @Improve_Date,
                        G_Memo = @G_Memo,
                        G_Back = NULL
                    WHERE Break_ID = @Break_ID";

                    DbHelper.ExecuteNonQuery(updateSql,
                        new SqlParameter("@G_User", gUserToSave),
                        new SqlParameter("@Improve_Date", improveDate),
                        new SqlParameter("@G_Memo", memoWithProps),
                        new SqlParameter("@Break_ID", breakId)
                    );
                }

                // 發送改善完成或建議持續追蹤通知信
                SendImproveNotificationEmail(breakId, false, gMemo, needFollow, followMemo);

                // 記錄雙軌 AuditLog
                AuditLogger.Log("ROAD_BREAK_IMPROVE_FINISH", breakId, string.Format("道路破損改善完成回報 (案號:{0}, 修復情形:{1}, 持續追蹤:{2})", breakId, fixStatus, needFollow));

                string successMsg = needFollow == "Y"
                    ? "處理回報已儲存，並已將本案標記為【🔍 建議持續追蹤】提醒機關列管！"
                    : "道路破損改善處理與結案回覆已成功儲存（正式結案）！";

                Response.Write(json.Serialize(new
                {
                    Success = true,
                    Message = successMsg,
                    RedirectUrl = "BreakDetail.aspx?id=" + HttpUtility.UrlEncode(breakId)
                }));
            }
        }

        private static bool CheckIfImproveColumnsExist()
        {
            try
            {
                string sqlCheck = "SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'RoadBreak_CaseMain' AND COLUMN_NAME = 'G_Fix_Status'";
                object obj = DbHelper.ExecuteScalar(sqlCheck);
                return obj != null && obj != DBNull.Value;
            }
            catch
            {
                return false;
            }
        }

        // 退回通報時產生新案號並複製現場照片
        private string CreateNewBreakIdFromBack(string originBreakId, DataRow originRow, string originPhysDir)
        {
            string datePrefix = DateTime.Now.ToString("yyyyMMdd");
            string timePrefix = DateTime.Now.ToString("HHmmss");
            string fullPrefix = datePrefix + timePrefix;
            string newBreakId = "";
            bool inserted = false;
            int maxRetry = 5;

            for (int retry = 0; retry < maxRetry; retry++)
            {
                if (retry > 0)
                {
                    System.Threading.Thread.Sleep(50 * retry + new Random().Next(10, 50));
                    fullPrefix = DateTime.Now.ToString("yyyyMMddHHmmss");
                }

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

                newBreakId = fullPrefix + string.Format("{0:000}", seq);

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

                string insertSql = "INSERT INTO RoadBreak_CaseMain " +
                    "(Break_ID, Report_Date, S_UTME, S_UTMN, ROAD_Name, ROAD_LV, TOWN_CODE, Smooth, Hole_Conn_St, Memo, Report_User, FromBack_ID) " +
                    "VALUES " +
                    "(@Break_ID, @Report_Date, @S_UTME, @S_UTMN, @ROAD_Name, @ROAD_LV, @TOWN_CODE, @Smooth, @Hole_Conn_St, @Memo, @Report_User, @FromBack_ID)";

                try
                {
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
                    inserted = true;
                    break;
                }
                catch (SqlException ex)
                {
                    if (ex.Number == 2627 || ex.Number == 2601)
                    {
                        continue;
                    }
                    throw;
                }
            }

            if (!inserted)
            {
                throw new InvalidOperationException("產生破損案件編號併發衝突，請稍後再試。");
            }

            // 複製佐證照片到新目錄
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
                        string safeName = Path.GetFileName(f.Name);
                        string destPath = Path.Combine(newPhysDir, safeName);
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

            string canonBaseDir = Path.GetFullPath(physDir).TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar) + Path.DirectorySeparatorChar;

            // 1. 先處理標記刪除的既有照片
            foreach (var item in photos)
            {
                if (item == null || !item.IsDeleted) continue;
                if (!string.IsNullOrEmpty(item.FileName))
                {
                    string safeName = Path.GetFileName(item.FileName);
                    if (safeName.IndexOf("改善後", StringComparison.OrdinalIgnoreCase) < 0)
                    {
                        continue;
                    }
                    string delPath = Path.Combine(physDir, safeName);
                    string canonDel = Path.GetFullPath(delPath);
                    if (canonDel.StartsWith(canonBaseDir, StringComparison.OrdinalIgnoreCase) && File.Exists(canonDel))
                    {
                        try { File.Delete(canonDel); } catch { }
                    }
                }
            }

            // 2. 再儲存新上傳或路平抓取之 Base64 照片
            int photoSeq = 1;
            foreach (var item in photos)
            {
                if (item == null || item.IsDeleted) continue;

                if (!string.IsNullOrEmpty(item.Base64Data))
                {
                    string targetName = "";
                    while (photoSeq <= 50)
                    {
                        string candidate = string.Format("改善後佐證照片_{0}.jpg", photoSeq);
                        photoSeq++;
                        if (!File.Exists(Path.Combine(physDir, candidate)))
                        {
                            targetName = candidate;
                            break;
                        }
                    }
                    if (string.IsNullOrEmpty(targetName))
                    {
                        targetName = string.Format("改善後佐證照片_{0}.jpg", DateTime.Now.Ticks);
                    }

                    string safeFileName = Path.GetFileName(targetName);
                    string fullPath = Path.Combine(physDir, safeFileName);
                    string canonFull = Path.GetFullPath(fullPath);

                    if (!canonFull.StartsWith(canonBaseDir, StringComparison.OrdinalIgnoreCase))
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
                        byte[] fileBytes = Convert.FromBase64String(b64);
                        if (fileBytes != null && fileBytes.Length >= 4)
                        {
                            bool isPng = (fileBytes[0] == 0x89 && fileBytes[1] == 0x50 && fileBytes[2] == 0x4E && fileBytes[3] == 0x47);
                            bool isJpg = (fileBytes[0] == 0xFF && fileBytes[1] == 0xD8 && fileBytes[2] == 0xFF);
                            if (isPng || isJpg)
                            {
                                File.WriteAllBytes(canonFull, fileBytes);
                            }
                        }
                    }
                    catch { }
                }
            }
        }

        // 發送通知郵件 (支援退回、正式結案、建議持續追蹤)
        private void SendImproveNotificationEmail(string breakId, bool isBack, string gMemo, string needFollow, string followMemo)
        {
            try
            {
                string sqlCase = "SELECT Show_ID, RDM_Case_ID, S_COM, S_User, Report_User FROM RoadBreak_CaseMain WHERE Break_ID = @id";
                DataTable dtCase = DbHelper.ExecuteDataTable(sqlCase, new SqlParameter("@id", breakId));
                if (dtCase.Rows.Count == 0) return;

                DataRow r = dtCase.Rows[0];
                string showId = r["Show_ID"] != DBNull.Value ? r["Show_ID"].ToString().Trim() : breakId;
                string rdmId = r.Table.Columns.Contains("RDM_Case_ID") && r["RDM_Case_ID"] != DBNull.Value ? r["RDM_Case_ID"].ToString().Trim() : "";
                string sCom = r["S_COM"] != DBNull.Value ? r["S_COM"].ToString().Trim() : "";

                // 取得通報單位承辦人信箱
                string sqlEmails = "SELECT UserEmail FROM RoadBreak_UnitUser WHERE UnitID = @UnitID AND UserEmail IS NOT NULL AND UserEmail <> ''";
                DataTable dtEmails = DbHelper.ExecuteDataTable(sqlEmails, new SqlParameter("@UnitID", sCom));

                string host = WebConfigurationManager.AppSettings["SMTPserver"];
                string fromAddr = WebConfigurationManager.AppSettings["EmailAddr"];
                string smtpUser = WebConfigurationManager.AppSettings["SMTP_User"];
                string smtpPass = WebConfigurationManager.AppSettings["SMTP_Password"];

                if (string.IsNullOrEmpty(host) || string.IsNullOrEmpty(fromAddr) || dtEmails.Rows.Count == 0) return;

                bool isFollow = (needFollow == "Y");
                string subject = isBack
                    ? "道路破損通報單【通報案號:" + showId + "】權責機關退回通知"
                    : (isFollow
                        ? "【建議持續追蹤】道路破損通報單【通報案號:" + showId + "】處理回報與後續追蹤提醒"
                        : "道路破損通報單【通報案號:" + showId + "】改善完成結案通知");

                string bannerColor = isBack ? "#dc2626" : (isFollow ? "#0284c7" : "#059669");
                string bannerTitle = isBack ? "非權責單位退回通知" : (isFollow ? "處理回報 - 建議機關持續追蹤" : "改善完成正式結案");

                StringBuilder sb = new StringBuilder();
                sb.AppendFormat("<div style='font-family: Arial, \"Microsoft JhengHei\", sans-serif; max-width: 650px; margin: 0 auto; border: 1px solid #cbd5e1; border-radius: 8px; overflow: hidden;'>");
                sb.AppendFormat("<div style='background: {0}; color: #ffffff; padding: 18px 24px;'>", bannerColor);
                sb.AppendFormat("<h3 style='margin:0; font-size: 1.25rem;'>新北市固定逸散源管理平台 - {0}</h3>", bannerTitle);
                sb.AppendFormat("<div style='font-size: 0.85rem; opacity: 0.85; margin-top: 4px;'>通報案號：{0}{1}</div>",
                    showId,
                    !string.IsNullOrEmpty(rdmId) ? " (路平報馬仔編號：" + rdmId + ")" : "");
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
                    sb.AppendFormat("<p>案件【通報案號：<strong>{0}</strong>】已完成處理回報：</p>", showId);
                    if (!string.IsNullOrEmpty(gMemo))
                    {
                        sb.AppendFormat("<div style='background: #f0fdf4; border-left: 4px solid #10b981; padding: 12px 16px; margin: 15px 0; color: #065f46;'><strong>處理說明：</strong>{0}</div>", HttpUtility.HtmlEncode(gMemo));
                    }
                    if (isFollow)
                    {
                        sb.AppendFormat("<div style='background: #eff6ff; border-left: 4px solid #0284c7; padding: 12px 16px; margin: 15px 0; color: #1e40af;'><strong>🔍 建議持續追蹤提醒：</strong>{0}</div>",
                            HttpUtility.HtmlEncode(!string.IsNullOrEmpty(followMemo) ? followMemo : "本案處置屬於持續追蹤或加強巡查性質，請機關持續追蹤後續改善情形。"));
                    }
                    if (!string.IsNullOrEmpty(rdmId))
                    {
                        string rdmUrl = "https://rdm.ntpc.gov.tw/ROAD/SatisfySurvey.aspx?id=" + HttpUtility.UrlEncode(rdmId);
                        sb.AppendFormat("<p style='margin-top:12px;'>新北市路平報馬仔系統連結：<a href='{0}' target='_blank'>{0}</a></p>", rdmUrl);
                    }
                }
                sb.Append("</div></div>");

                MailMessage msg = new MailMessage();
                msg.From = new MailAddress(fromAddr, "新北市固定逸散源管理平台");
                foreach (DataRow row in dtEmails.Rows)
                {
                    string toEmail = row["UserEmail"].ToString().Trim();
                    if (!string.IsNullOrEmpty(toEmail))
                    {
                        msg.To.Add(toEmail);
                    }
                }

                if (msg.To.Count > 0)
                {
                    msg.Subject = subject;
                    msg.Body = sb.ToString();
                    msg.IsBodyHtml = true;

                    SmtpClient client = new SmtpClient(host);
                    if (!string.IsNullOrEmpty(smtpUser))
                    {
                        client.Credentials = new NetworkCredential(smtpUser, smtpPass);
                    }
                    client.Send(msg);
                }
            }
            catch { }
        }

        private static bool IsImageExtension(string fileName)
        {
            if (string.IsNullOrEmpty(fileName)) return false;
            string ext = Path.GetExtension(fileName).ToLower();
            return ext == ".jpg" || ext == ".jpeg" || ext == ".png" || ext == ".gif" || ext == ".webp" || ext == ".bmp";
        }

        private static bool IsAfterPhotoFileName(string fileName)
        {
            if (string.IsNullOrEmpty(fileName)) return false;
            return fileName.IndexOf("改善後", StringComparison.OrdinalIgnoreCase) >= 0 ||
                   fileName.IndexOf("完工", StringComparison.OrdinalIgnoreCase) >= 0 ||
                   fileName.IndexOf("after", StringComparison.OrdinalIgnoreCase) >= 0;
        }

        // 讀取改善前佐證照片
        private List<PhotoItemDto> LoadEvidencePhotos(string breakId)
        {
            List<PhotoItemDto> list = new List<PhotoItemDto>();
            string picDir = PathHelper.FindDirectory("Upload/RoadBreakPIC/" + breakId);
            if (!Directory.Exists(picDir)) return list;

            DirectoryInfo dir = new DirectoryInfo(picDir);
            FileInfo[] files = dir.GetFiles();
            var beforeFiles = files
                .Where(new Func<FileInfo, bool>(delegate (FileInfo f) {
                    return IsImageExtension(f.Name) && !IsAfterPhotoFileName(f.Name);
                }))
                .OrderBy(new Func<FileInfo, string>(delegate (FileInfo f) { return f.Name; }))
                .ToList();

            int idx = 1;
            foreach (FileInfo f in beforeFiles)
            {
                list.Add(new PhotoItemDto
                {
                    FileName = f.Name,
                    Title = string.Format("佐證照片 {0}", idx),
                    Url = PathHelper.ResolveUrl(string.Format("~/Upload/RoadBreakPIC/{0}/{1}?v={2}", breakId, f.Name, f.LastWriteTime.Ticks)),
                    Size = f.Length,
                    LastModified = f.LastWriteTime.ToString("yyyy/MM/dd HH:mm")
                });
                idx++;
            }
            return list;
        }

        // 讀取既有改善後照片
        private List<PhotoItemDto> LoadImprovePhotos(string breakId)
        {
            List<PhotoItemDto> list = new List<PhotoItemDto>();
            string picDir = PathHelper.FindDirectory("Upload/RoadBreakPIC/" + breakId);
            if (!Directory.Exists(picDir)) return list;

            DirectoryInfo dir = new DirectoryInfo(picDir);
            FileInfo[] files = dir.GetFiles();
            var afterFiles = files
                .Where(new Func<FileInfo, bool>(delegate (FileInfo f) {
                    return IsImageExtension(f.Name) && IsAfterPhotoFileName(f.Name);
                }))
                .OrderBy(new Func<FileInfo, string>(delegate (FileInfo f) { return f.Name; }))
                .ToList();

            int idx = 1;
            foreach (FileInfo f in afterFiles)
            {
                list.Add(new PhotoItemDto
                {
                    FileName = f.Name,
                    Title = string.Format("完工照片 {0}", idx),
                    Url = PathHelper.ResolveUrl(string.Format("~/Upload/RoadBreakPIC/{0}/{1}?v={2}", breakId, f.Name, f.LastWriteTime.Ticks)),
                    Size = f.Length,
                    LastModified = f.LastWriteTime.ToString("yyyy/MM/dd HH:mm")
                });
                idx++;
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
        public class RdmParsedResultDto
        {
            public string RDM_Case_ID { get; set; }
            public string Report_Date { get; set; }
            public string PCI_Type { get; set; }
            public string PCI_Severity { get; set; }
            public string Supervisor_Suggest { get; set; }
            public string District_Office { get; set; }
            public string Handle_Unit { get; set; }
            public string Handle_Status { get; set; }
            public string Dispatch_Memo { get; set; }
            public string Dispatch_Done_Date { get; set; }
            public string Dispatch_Report_Date { get; set; }
            public string Improve_Date { get; set; }
            public string G_Report_Date { get; set; }
            public string Damage_Type { get; set; }
            public string Damage_Length { get; set; }
            public string Damage_Width { get; set; }
            public string Damage_Count { get; set; }
            public string G_Fix_Status { get; set; }
            public string Road_Name { get; set; }
            public string G_User { get; set; }
            public string G_Contact_Phone { get; set; }
            public string G_Memo { get; set; }
            public string G_Delay_Reason { get; set; }
            public string G_Reply_Date { get; set; }
            public string G_Reply_Type { get; set; }
            public string G_Reply_Memo { get; set; }
            public string SuggestedNeedFollow { get; set; }
            public string SuggestedFollowMemo { get; set; }
            public List<string> MatchedKeywords { get; set; }
            public List<PhotoUploadItem> DownloadedPhotos { get; set; }
        }

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
            public string RDM_Case_ID { get; set; }
            public string Need_Follow { get; set; }
            public string Follow_Memo { get; set; }
            public string PCI_Type { get; set; }
            public string PCI_Severity { get; set; }
            public string Supervisor_Suggest { get; set; }
            public string District_Office { get; set; }
            public string Handle_Unit { get; set; }
            public string Handle_Status { get; set; }
            public string Dispatch_Memo { get; set; }
            public string Dispatch_Done_Date { get; set; }
            public string Dispatch_Report_Date { get; set; }
            public string Improve_Date { get; set; }
            public string G_Report_Date { get; set; }
            public string Damage_Type { get; set; }
            public string Damage_Length { get; set; }
            public string Damage_Width { get; set; }
            public string Damage_Count { get; set; }
            public string G_Fix_Status { get; set; }
            public string G_User { get; set; }
            public string G_Contact_Phone { get; set; }
            public string G_Memo { get; set; }
            public string G_Delay_Reason { get; set; }
            public string G_Reply_Type { get; set; }
            public string G_Reply_Memo { get; set; }
            public string G_Reply_Date { get; set; }
            public bool IsBack { get; set; }
            public List<PhotoUploadItem> ImprovePhotos { get; set; }
        }
    }
}
