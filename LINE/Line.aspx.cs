using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Text;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.UI;
using Newtonsoft.Json;
using NTPC_FEC.Helpers;
using NTPC_FEC.Models;
using NTPC_FEC.Services;

namespace NTPC_FEC.LINE
{
    public partial class Line : Page
    {
        private JavaScriptSerializer jsonSerializer;

        public Line()
        {
            jsonSerializer = new JavaScriptSerializer();
            jsonSerializer.MaxJsonLength = int.MaxValue;
        }

        #region 資料傳輸模型 (遵循 C# 5.0，無自動屬性初始化)

        public class ResponseModel
        {
            public bool Success { get; set; }
            public string Message { get; set; }
            public object Data { get; set; }
        }

        public class PushMsgModel
        {
            public int Msg_ID { get; set; }
            public string Msg_Type { get; set; }
            public string Msg_Type_Str { get; set; }
            public string Severity { get; set; }
            public string Title { get; set; }
            public string Send_Txt { get; set; }
            public string Target_Role { get; set; }
            public bool Is_Pinned { get; set; }
            public string Action_Url { get; set; }
            public string Send_Date { get; set; }
            public string RelativeTime { get; set; }
            public string Create_User { get; set; }
        }

        public class StatSummaryModel
        {
            public int TotalCount { get; set; }
            public int WarnCount { get; set; }
            public int ActionCount { get; set; }
            public int ClearCount { get; set; }
            public int InfoCount { get; set; }
        }

        public class OfficialAccountModel
        {
            public string AccountName { get; set; }
            public string LineId { get; set; }
            public string LineJoinUrl { get; set; }
            public string QrCodeUrl { get; set; }
            public string LogoUrl { get; set; }
            public string ServiceHours { get; set; }
            public string Description { get; set; }
        }

        public class InitDataPackage
        {
            public bool IsManager { get; set; }
            public bool CanPost { get; set; }
            public string CurrentUser { get; set; }
            public string UserFacId { get; set; }
            public string UserFacName { get; set; }
            public OfficialAccountModel OfficialAccount { get; set; }
            public StatSummaryModel Stats { get; set; }
            public List<string> RecentAlertDates { get; set; }

            public InitDataPackage()
            {
                OfficialAccount = new OfficialAccountModel();
                Stats = new StatSummaryModel();
                RecentAlertDates = new List<string>();
            }
        }

        public class ListResultPackage
        {
            public int TotalCount { get; set; }
            public int PageIndex { get; set; }
            public int PageSize { get; set; }
            public int TotalPages { get; set; }
            public List<PushMsgModel> Items { get; set; }
            public StatSummaryModel Stats { get; set; }

            public ListResultPackage()
            {
                Items = new List<PushMsgModel>();
                Stats = new StatSummaryModel();
            }
        }

        public class NewMsgInputModel
        {
            public string MsgType { get; set; }
            public string MsgTypeStr { get; set; }
            public string Severity { get; set; }
            public string Title { get; set; }
            public string SendTxt { get; set; }
            public string TargetRole { get; set; }
            public bool IsPinned { get; set; }
            public string ActionUrl { get; set; }
        }

        #endregion

        protected override void Render(HtmlTextWriter writer)
        {
            if (!string.IsNullOrEmpty(Request["action"]))
            {
                return;
            }
            base.Render(writer);
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
                    HandleAjaxAction(action.ToLower().Trim());
                }
                catch (System.Threading.ThreadAbortException)
                {
                    return;
                }
                catch (Exception ex)
                {
                    Response.Write(jsonSerializer.Serialize(new ResponseModel
                    {
                        Success = false,
                        Message = "系統處理失敗：" + ex.Message
                    }));
                }

                try
                {
                    Response.End();
                }
                catch (System.Threading.ThreadAbortException)
                {
                    return;
                }
                return;
            }

            EnsureTableAndDefaultData();
        }

        private void HandleAjaxAction(string action)
        {
            switch (action)
            {
                case "getinitdata":
                    GetInitData();
                    break;
                case "getmessages":
                    GetMessages();
                    break;
                case "sendmessage":
                    SendMessage();
                    break;
                case "deletemessage":
                    DeleteMessage();
                    break;
                case "cleardefaultsamples":
                    ClearDefaultSamples();
                    break;
                default:
                    Response.Write(jsonSerializer.Serialize(new ResponseModel
                    {
                        Success = false,
                        Message = "未知的 API 動作：" + action
                    }));
                    break;
            }
        }

        #region 使用者角色與權限判定

        private bool CheckIsManager(out string currentUser, out string userFacId, out string userFacName)
        {
            currentUser = Session["LoginUser"] != null ? Session["LoginUser"].ToString().Trim() : "";
            userFacId = "";
            userFacName = "";
            bool isManager = false;

            try
            {
                UserAccount uAcc = AuthService.GetCurrentUser(Context);
                if (uAcc != null)
                {
                    if (string.IsNullOrEmpty(currentUser) && !string.IsNullOrEmpty(uAcc.UserID))
                    {
                        currentUser = uAcc.UserID.Trim();
                    }

                    if ((uAcc.Lic & (1L << 16)) != 0 || (uAcc.Lic & (1L << 63)) != 0 || string.IsNullOrEmpty(uAcc.FacID))
                    {
                        isManager = true;
                    }
                    if (!string.IsNullOrEmpty(uAcc.FacID))
                    {
                        userFacId = uAcc.FacID.Trim();
                    }
                }
            }
            catch
            {
            }

            if (!string.IsNullOrEmpty(currentUser) && string.IsNullOrEmpty(userFacId))
            {
                try
                {
                    string sql = "SELECT TOP 1 LIC, FAC_ID FROM UserAcc WHERE UserID = @UserID";
                    SqlParameter[] p = new SqlParameter[]
                    {
                        new SqlParameter("@UserID", SqlDbType.VarChar) { Value = currentUser }
                    };
                    DataTable dt = DbHelper.ExecuteDataTable(sql, p);
                    if (dt != null && dt.Rows.Count > 0)
                    {
                        DataRow r = dt.Rows[0];
                        long licVal = 0;
                        if (r["LIC"] != DBNull.Value) long.TryParse(r["LIC"].ToString(), out licVal);
                        if ((licVal & (1L << 16)) != 0 || (licVal & (1L << 63)) != 0)
                        {
                            isManager = true;
                        }
                        if (r["FAC_ID"] != DBNull.Value)
                        {
                            userFacId = r["FAC_ID"].ToString().Trim();
                        }
                    }
                }
                catch
                {
                }
            }

            if (!string.IsNullOrEmpty(userFacId))
            {
                try
                {
                    string fSql = "SELECT TOP 1 FAC_NAME FROM FAC_Main WHERE FAC_ID = @FAC_ID";
                    SqlParameter[] fp = new SqlParameter[]
                    {
                        new SqlParameter("@FAC_ID", SqlDbType.VarChar) { Value = userFacId }
                    };
                    object fnObj = DbHelper.ExecuteScalar(fSql, fp);
                    if (fnObj != null && fnObj != DBNull.Value)
                    {
                        userFacName = fnObj.ToString().Trim();
                    }
                }
                catch
                {
                }
            }

            return isManager;
        }

        #endregion

        #region 資料表自動檢測與初始化範例資料

        private void EnsureTableAndDefaultData()
        {
            try
            {
                string ddl = @"
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'LINE_PushMsg')
BEGIN
    CREATE TABLE [dbo].[LINE_PushMsg] (
        [Msg_ID] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [Msg_Type] VARCHAR(20) NOT NULL,
        [Msg_Type_Str] NVARCHAR(50) NOT NULL,
        [Severity] VARCHAR(20) NOT NULL DEFAULT ('info'),
        [Title] NVARCHAR(200) NOT NULL,
        [Send_Txt] NVARCHAR(MAX) NOT NULL,
        [Target_Role] NVARCHAR(100) NOT NULL,
        [Is_Pinned] BIT NOT NULL DEFAULT (0),
        [Action_Url] NVARCHAR(500) NULL,
        [Send_Date] DATETIME NOT NULL DEFAULT (GETDATE()),
        [Create_User] NVARCHAR(50) NULL,
        [Create_Date] DATETIME NOT NULL DEFAULT (GETDATE())
    );
END";
                DbHelper.ExecuteNonQuery(ddl);

                string checkSql = "SELECT COUNT(1) FROM LINE_PushMsg";
                object cObj = DbHelper.ExecuteScalar(checkSql);
                int count = 0;
                if (cObj != null && cObj != DBNull.Value)
                {
                    int.TryParse(cObj.ToString(), out count);
                }

                if (count == 0)
                {
                    string insertSamples = @"
INSERT INTO [dbo].[LINE_PushMsg] 
([Msg_Type], [Msg_Type_Str], [Severity], [Title], [Send_Txt], [Target_Role], [Is_Pinned], [Action_Url], [Send_Date], [Create_User], [Create_Date])
VALUES
('WARN', N'空品不良預警', 'warning', N'【空品不良預警】新北局部測站達橘色提醒，請啟動自主減量', 
 N'依據環境部最新空氣品質監測資料，因東北季風風場偏東且擴散條件轉差，八里、林口及三重測站AQI已達110～135（橘色提醒等級），指標污染物為PM2.5。請新北市列管公私場所及營建工地加強各項空氣污染防制設備運作，落實廠區灑水抑塵、運輸車輛加蓋防塵網與輪胎沖洗，以共同維護清新好空氣。', 
 N'新北市全體列管公私場所及營建工地', 1, 'OwnReport/Report_AirQuality.aspx?mode=new', DATEADD(MINUTE, -25, GETDATE()), 'SYSTEM', GETDATE()),

('ACTION', N'應變措施啟動', 'danger', N'【應變作為通知】新北市啟動固定源第一階段應變，請於期限內申報', 
 N'新北市環保局通報：今日啟動空品不良第一階段自主減量應變措施。請各列管廠場落實以下作為：1. 查核並確保防制設施正常操作。2. 增加廠區周邊及出入口灑水車巡迴次數。3. 依規於今日下午 17:00 前至系統完成空品應變自主申報回報。', 
 N'第一、二批空品不良應變列管廠場', 1, 'OwnReport/Report_AirQuality.aspx?mode=new', DATEADD(HOUR, -2, GETDATE()), 'EPD_ADMIN', GETDATE()),

('INFO', N'防制設施指引', 'info', N'【自主維護指引】洗車設備沉澱池巡檢與濾袋壓差檢視注意事項', 
 N'親愛的專責人員您好：近期天候乾燥易造成路面揚塵溢散，提醒公私場所特別注意：1. 洗車台循環水池沉砂泥量是否已超過槽深二分之一，請適時清淤。2. 自動灑水噴霧管線之噴嘴有無堵塞或水壓不足。3. 若有缺失請即刻排查並於自主管理平台完成改善紀錄。', 
 N'列管固定污染源自主申報人員', 0, 'OwnReport/PIC_Report_List.aspx?mode=own', DATEADD(DAY, -1, GETDATE()), 'EPD_TECH', GETDATE()),

('ACTION', N'道路洗掃通報', 'info', N'【加強洗掃作業】主要幹道洗掃街車輛已全數出動加強清掃', 
 N'為降低道路揚塵累積，新北市環保局已調派 18 輛高壓洗街車與清掃車輛，針對省道台15線、台64線聯絡道、新北大道及八里台北港周邊熱區道路，展開全面高壓沖洗作業。請行經車輛注意減速慢行，並感謝用路人配合。', 
 N'全體關注市民與用路單位', 0, 'RoadClean/Clean_List.aspx?mode=search', DATEADD(DAY, -2, GETDATE()), 'EPD_CLEAN', GETDATE()),

('CLEAR', N'應變作為解除', 'success', N'【應變作為解除】擴散條件顯著好轉，解除本日空品不良應變', 
 N'新北市環保局快報：午後海風擴散增強，各區測站空氣品質指標（AQI）均已順利回降至 65～80 良好與普通等級。宣布自即時起解除本日固定源第一階段自主應變作為，各事業單位可恢復常態維護操作。感謝各公私場所與稽查同仁的齊心配合！', 
 N'新北市全體列管公私場所', 0, 'OwnReport/AirQuality_List.aspx', DATEADD(DAY, -3, GETDATE()), 'SYSTEM', GETDATE());";
                    DbHelper.ExecuteNonQuery(insertSamples);
                }
            }
            catch
            {
            }
        }

        #endregion

        #region AJAX 業務邏輯

        private void GetInitData()
        {
            string currentUser = "";
            string userFacId = "";
            string userFacName = "";
            bool isMgr = CheckIsManager(out currentUser, out userFacId, out userFacName);

            InitDataPackage pkg = new InitDataPackage();
            pkg.IsManager = isMgr;
            pkg.CanPost = isMgr;
            pkg.CurrentUser = currentUser;
            pkg.UserFacId = userFacId;
            pkg.UserFacName = userFacName;

            pkg.OfficialAccount.AccountName = "【新北空品不良應變通報】Line官方帳號";
            pkg.OfficialAccount.LineId = "@ntpc_air";
            pkg.OfficialAccount.LineJoinUrl = "https://lin.ee/tI5cnOa";
            pkg.OfficialAccount.QrCodeUrl = "../images/LINE_QR.png";
            pkg.OfficialAccount.LogoUrl = "../images/LINEACC_LOGO.png";
            pkg.OfficialAccount.ServiceHours = "24 小時即時通報與空品預警推播";
            pkg.OfficialAccount.Description = "加入官方帳號可第一時間獲取新北市最新空氣品質預警、各階段應變啟動通報，並提供固定污染源自主申報線上直達功能。";

            pkg.Stats = FetchStatsSummary();
            pkg.RecentAlertDates = FetchRecentAlertDates();

            Response.Write(jsonSerializer.Serialize(new ResponseModel
            {
                Success = true,
                Data = pkg
            }));
        }

        private StatSummaryModel FetchStatsSummary()
        {
            StatSummaryModel stats = new StatSummaryModel();
            try
            {
                string sql = @"
SELECT 
    COUNT(1) AS TotalCount,
    SUM(CASE WHEN Msg_Type = 'WARN' THEN 1 ELSE 0 END) AS WarnCount,
    SUM(CASE WHEN Msg_Type = 'ACTION' THEN 1 ELSE 0 END) AS ActionCount,
    SUM(CASE WHEN Msg_Type = 'CLEAR' THEN 1 ELSE 0 END) AS ClearCount,
    SUM(CASE WHEN Msg_Type = 'INFO' THEN 1 ELSE 0 END) AS InfoCount
FROM LINE_PushMsg";
                DataTable dt = DbHelper.ExecuteDataTable(sql);
                if (dt != null && dt.Rows.Count > 0)
                {
                    DataRow r = dt.Rows[0];
                    if (r["TotalCount"] != DBNull.Value) stats.TotalCount = Convert.ToInt32(r["TotalCount"]);
                    if (r["WarnCount"] != DBNull.Value) stats.WarnCount = Convert.ToInt32(r["WarnCount"]);
                    if (r["ActionCount"] != DBNull.Value) stats.ActionCount = Convert.ToInt32(r["ActionCount"]);
                    if (r["ClearCount"] != DBNull.Value) stats.ClearCount = Convert.ToInt32(r["ClearCount"]);
                    if (r["InfoCount"] != DBNull.Value) stats.InfoCount = Convert.ToInt32(r["InfoCount"]);
                }
            }
            catch
            {
            }
            return stats;
        }

        private List<string> FetchRecentAlertDates()
        {
            List<string> dates = new List<string>();
            try
            {
                string sql = "SELECT DISTINCT TOP 5 CONVERT(varchar(10), Send_Date, 120) AS SendDate FROM LINE_PushMsg ORDER BY SendDate DESC";
                DataTable dt = DbHelper.ExecuteDataTable(sql);
                if (dt != null)
                {
                    foreach (DataRow r in dt.Rows)
                    {
                        if (r["SendDate"] != DBNull.Value)
                        {
                            string d = r["SendDate"].ToString().Trim();
                            if (!string.IsNullOrEmpty(d) && !dates.Contains(d))
                            {
                                dates.Add(d);
                            }
                        }
                    }
                }

                if (dates.Count < 3)
                {
                    string oSql = "SELECT DISTINCT TOP 5 CONVERT(varchar(10), OverDate, 120) AS OverDate FROM OverReport_TypeA_1 WHERE OverDate IS NOT NULL ORDER BY OverDate DESC";
                    DataTable dtO = DbHelper.ExecuteDataTable(oSql);
                    if (dtO != null)
                    {
                        foreach (DataRow r in dtO.Rows)
                        {
                            if (r["OverDate"] != DBNull.Value)
                            {
                                string d = r["OverDate"].ToString().Trim();
                                if (!string.IsNullOrEmpty(d) && !dates.Contains(d))
                                {
                                    dates.Add(d);
                                }
                            }
                        }
                    }
                }
            }
            catch
            {
            }
            return dates;
        }

        private void GetMessages()
        {
            string keyword = Request["keyword"] != null ? Request["keyword"].Trim() : "";
            string msgType = Request["msgType"] != null ? Request["msgType"].Trim() : "ALL";
            string dateStart = Request["dateStart"] != null ? Request["dateStart"].Trim() : "";
            string dateEnd = Request["dateEnd"] != null ? Request["dateEnd"].Trim() : "";

            int pageIndex = 1;
            int pageSize = 10;
            if (!string.IsNullOrEmpty(Request["pageIndex"])) int.TryParse(Request["pageIndex"], out pageIndex);
            if (!string.IsNullOrEmpty(Request["pageSize"])) int.TryParse(Request["pageSize"], out pageSize);
            if (pageIndex < 1) pageIndex = 1;
            if (pageSize < 5) pageSize = 5;
            if (pageSize > 100) pageSize = 100;

            StringBuilder whereSb = new StringBuilder(" WHERE 1=1 ");
            List<SqlParameter> pList = new List<SqlParameter>();

            if (!string.IsNullOrEmpty(keyword))
            {
                whereSb.Append(" AND (Title LIKE @Keyword OR Send_Txt LIKE @Keyword OR Target_Role LIKE @Keyword) ");
                pList.Add(new SqlParameter("@Keyword", SqlDbType.NVarChar) { Value = "%" + keyword + "%" });
            }

            if (!string.IsNullOrEmpty(msgType) && !string.Equals(msgType, "ALL", StringComparison.OrdinalIgnoreCase))
            {
                whereSb.Append(" AND Msg_Type = @MsgType ");
                pList.Add(new SqlParameter("@MsgType", SqlDbType.VarChar) { Value = msgType });
            }

            if (!string.IsNullOrEmpty(dateStart))
            {
                DateTime dtS;
                if (DateTime.TryParse(dateStart, out dtS))
                {
                    whereSb.Append(" AND Send_Date >= @DateStart ");
                    pList.Add(new SqlParameter("@DateStart", SqlDbType.DateTime) { Value = dtS.Date });
                }
            }

            if (!string.IsNullOrEmpty(dateEnd))
            {
                DateTime dtE;
                if (DateTime.TryParse(dateEnd, out dtE))
                {
                    whereSb.Append(" AND Send_Date <= @DateEnd ");
                    pList.Add(new SqlParameter("@DateEnd", SqlDbType.DateTime) { Value = dtE.Date.AddDays(1).AddSeconds(-1) });
                }
            }

            string countSql = "SELECT COUNT(1) FROM LINE_PushMsg " + whereSb.ToString();
            object totalObj = DbHelper.ExecuteScalar(countSql, pList.ToArray());
            int totalCount = 0;
            if (totalObj != null && totalObj != DBNull.Value)
            {
                int.TryParse(totalObj.ToString(), out totalCount);
            }

            int totalPages = (int)Math.Ceiling((double)totalCount / pageSize);
            if (totalPages < 1) totalPages = 1;
            if (pageIndex > totalPages) pageIndex = totalPages;

            int offset = (pageIndex - 1) * pageSize;

            string pageSql = string.Format(@"
SELECT * FROM (
    SELECT 
        Msg_ID, Msg_Type, Msg_Type_Str, Severity, Title, Send_Txt, Target_Role, Is_Pinned, Action_Url, Send_Date, Create_User,
        ROW_NUMBER() OVER (ORDER BY Is_Pinned DESC, Send_Date DESC, Msg_ID DESC) AS RowNum
    FROM LINE_PushMsg
    {0}
) AS T
WHERE RowNum > {1} AND RowNum <= {2}
ORDER BY RowNum", whereSb.ToString(), offset, offset + pageSize);

            DataTable dtList = DbHelper.ExecuteDataTable(pageSql, pList.ToArray());
            List<PushMsgModel> items = new List<PushMsgModel>();

            if (dtList != null)
            {
                DateTime now = DateTime.Now;
                foreach (DataRow r in dtList.Rows)
                {
                    PushMsgModel m = new PushMsgModel();
                    m.Msg_ID = Convert.ToInt32(r["Msg_ID"]);
                    m.Msg_Type = r["Msg_Type"] != DBNull.Value ? r["Msg_Type"].ToString() : "INFO";
                    m.Msg_Type_Str = r["Msg_Type_Str"] != DBNull.Value ? r["Msg_Type_Str"].ToString() : "訊息通報";
                    m.Severity = r["Severity"] != DBNull.Value ? r["Severity"].ToString() : "info";
                    m.Title = r["Title"] != DBNull.Value ? r["Title"].ToString() : "";
                    m.Send_Txt = r["Send_Txt"] != DBNull.Value ? r["Send_Txt"].ToString() : "";
                    m.Target_Role = r["Target_Role"] != DBNull.Value ? r["Target_Role"].ToString() : "全體列管業者";
                    m.Is_Pinned = r["Is_Pinned"] != DBNull.Value && Convert.ToBoolean(r["Is_Pinned"]);
                    m.Action_Url = r["Action_Url"] != DBNull.Value ? r["Action_Url"].ToString() : "";
                    m.Create_User = r["Create_User"] != DBNull.Value ? r["Create_User"].ToString() : "";

                    if (r["Send_Date"] != DBNull.Value)
                    {
                        DateTime sDate = Convert.ToDateTime(r["Send_Date"]);
                        m.Send_Date = sDate.ToString("yyyy-MM-dd HH:mm");
                        m.RelativeTime = CalculateRelativeTime(sDate, now);
                    }
                    else
                    {
                        m.Send_Date = "";
                        m.RelativeTime = "";
                    }

                    items.Add(m);
                }
            }

            ListResultPackage result = new ListResultPackage();
            result.TotalCount = totalCount;
            result.PageIndex = pageIndex;
            result.PageSize = pageSize;
            result.TotalPages = totalPages;
            result.Items = items;
            result.Stats = FetchStatsSummary();

            Response.Write(jsonSerializer.Serialize(new ResponseModel
            {
                Success = true,
                Data = result
            }));
        }

        private static string CalculateRelativeTime(DateTime dt, DateTime now)
        {
            TimeSpan span = now - dt;
            if (span.TotalMinutes < 1)
            {
                return "剛剛";
            }
            if (span.TotalMinutes < 60)
            {
                return string.Format("{0} 分鐘前", Math.Max(1, (int)span.TotalMinutes));
            }
            if (span.TotalHours < 24 && dt.Date == now.Date)
            {
                return string.Format("{0} 小時前", (int)span.TotalHours);
            }
            if (span.TotalDays < 2 && dt.Date == now.Date.AddDays(-1))
            {
                return "昨天 " + dt.ToString("HH:mm");
            }
            if (span.TotalDays < 7)
            {
                return string.Format("{0} 天前", (int)span.TotalDays);
            }
            return dt.ToString("yyyy-MM-dd");
        }

        private void SendMessage()
        {
            string currentUser = "";
            string userFacId = "";
            string userFacName = "";
            bool isMgr = CheckIsManager(out currentUser, out userFacId, out userFacName);

            if (!isMgr)
            {
                Response.Write(jsonSerializer.Serialize(new ResponseModel
                {
                    Success = false,
                    Message = "無發布推播訊息之管理員權限！"
                }));
                return;
            }

            string payload = "";
            using (StreamReader reader = new StreamReader(Request.InputStream, Encoding.UTF8))
            {
                payload = reader.ReadToEnd();
            }

            if (string.IsNullOrEmpty(payload))
            {
                Response.Write(jsonSerializer.Serialize(new ResponseModel
                {
                    Success = false,
                    Message = "未收到發布推播之請求資料！"
                }));
                return;
            }

            NewMsgInputModel input = JsonConvert.DeserializeObject<NewMsgInputModel>(payload);
            if (input == null)
            {
                Response.Write(jsonSerializer.Serialize(new ResponseModel
                {
                    Success = false,
                    Message = "資料解析失敗！"
                }));
                return;
            }

            if (string.IsNullOrEmpty(input.Title) || string.IsNullOrEmpty(input.Title.Trim()))
            {
                Response.Write(jsonSerializer.Serialize(new ResponseModel
                {
                    Success = false,
                    Message = "推播標題不可為空！"
                }));
                return;
            }

            if (string.IsNullOrEmpty(input.SendTxt) || string.IsNullOrEmpty(input.SendTxt.Trim()))
            {
                Response.Write(jsonSerializer.Serialize(new ResponseModel
                {
                    Success = false,
                    Message = "推播內文不可為空！"
                }));
                return;
            }

            string msgType = string.IsNullOrEmpty(input.MsgType) ? "INFO" : input.MsgType.Trim().ToUpper();
            string msgTypeStr = string.IsNullOrEmpty(input.MsgTypeStr) ? "訊息通報" : input.MsgTypeStr.Trim();
            string severity = string.IsNullOrEmpty(input.Severity) ? "info" : input.Severity.Trim().ToLower();
            string targetRole = string.IsNullOrEmpty(input.TargetRole) ? "新北市全體列管公私場所" : input.TargetRole.Trim();
            string actionUrl = input.ActionUrl != null ? input.ActionUrl.Trim() : "";

            string insertSql = @"
INSERT INTO [dbo].[LINE_PushMsg] 
([Msg_Type], [Msg_Type_Str], [Severity], [Title], [Send_Txt], [Target_Role], [Is_Pinned], [Action_Url], [Send_Date], [Create_User], [Create_Date])
VALUES
(@Msg_Type, @Msg_Type_Str, @Severity, @Title, @Send_Txt, @Target_Role, @Is_Pinned, @Action_Url, GETDATE(), @Create_User, GETDATE());
SELECT SCOPE_IDENTITY();";

            SqlParameter[] pList = new SqlParameter[]
            {
                new SqlParameter("@Msg_Type", SqlDbType.VarChar) { Value = msgType },
                new SqlParameter("@Msg_Type_Str", SqlDbType.NVarChar) { Value = msgTypeStr },
                new SqlParameter("@Severity", SqlDbType.VarChar) { Value = severity },
                new SqlParameter("@Title", SqlDbType.NVarChar) { Value = input.Title.Trim() },
                new SqlParameter("@Send_Txt", SqlDbType.NVarChar) { Value = input.SendTxt.Trim() },
                new SqlParameter("@Target_Role", SqlDbType.NVarChar) { Value = targetRole },
                new SqlParameter("@Is_Pinned", SqlDbType.Bit) { Value = input.IsPinned },
                new SqlParameter("@Action_Url", SqlDbType.NVarChar) { Value = (object)actionUrl ?? DBNull.Value },
                new SqlParameter("@Create_User", SqlDbType.NVarChar) { Value = currentUser }
            };

            object newIdObj = DbHelper.ExecuteScalar(insertSql, pList);
            int newId = 0;
            if (newIdObj != null && newIdObj != DBNull.Value)
            {
                int.TryParse(newIdObj.ToString(), out newId);
            }

            Response.Write(jsonSerializer.Serialize(new ResponseModel
            {
                Success = true,
                Message = "LINE 推播訊息發布成功！",
                Data = new { Msg_ID = newId }
            }));
        }

        private void DeleteMessage()
        {
            string currentUser = "";
            string userFacId = "";
            string userFacName = "";
            bool isMgr = CheckIsManager(out currentUser, out userFacId, out userFacName);

            if (!isMgr)
            {
                Response.Write(jsonSerializer.Serialize(new ResponseModel
                {
                    Success = false,
                    Message = "無刪除推播訊息之權限！"
                }));
                return;
            }

            int msgId = 0;
            if (!string.IsNullOrEmpty(Request["id"])) int.TryParse(Request["id"], out msgId);
            if (msgId <= 0)
            {
                Response.Write(jsonSerializer.Serialize(new ResponseModel
                {
                    Success = false,
                    Message = "無效的訊息編號！"
                }));
                return;
            }

            string delSql = "DELETE FROM LINE_PushMsg WHERE Msg_ID = @Msg_ID";
            SqlParameter[] p = new SqlParameter[]
            {
                new SqlParameter("@Msg_ID", SqlDbType.Int) { Value = msgId }
            };
            int aff = DbHelper.ExecuteNonQuery(delSql, p);

            Response.Write(jsonSerializer.Serialize(new ResponseModel
            {
                Success = aff > 0,
                Message = aff > 0 ? "訊息已成功刪除！" : "找不到欲刪除的訊息或已被刪除。"
            }));
        }

        private void ClearDefaultSamples()
        {
            string currentUser = "";
            string userFacId = "";
            string userFacName = "";
            bool isMgr = CheckIsManager(out currentUser, out userFacId, out userFacName);

            if (!isMgr)
            {
                Response.Write(jsonSerializer.Serialize(new ResponseModel
                {
                    Success = false,
                    Message = "無管理員權限！"
                }));
                return;
            }

            string delSql = "DELETE FROM LINE_PushMsg WHERE Create_User IN ('SYSTEM', 'EPD_ADMIN', 'EPD_TECH', 'EPD_CLEAN')";
            int aff = DbHelper.ExecuteNonQuery(delSql);

            Response.Write(jsonSerializer.Serialize(new ResponseModel
            {
                Success = true,
                Message = string.Format("已清除 {0} 筆預載範例推播！", aff)
            }));
        }

        #endregion
    }
}



