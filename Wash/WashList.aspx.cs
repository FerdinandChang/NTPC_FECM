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
using NPOI.HSSF.UserModel;
using NPOI.HSSF.Util;
using NPOI.SS.UserModel;
using NPOI.SS.Util;
using NTPC_FEC.Helpers;
using NTPC_FEC.Models;
using NTPC_FEC.Services;

namespace NTPC_FEC.Wash
{
    public partial class WashList : Page
    {
        private JavaScriptSerializer json;

        public WashList()
        {
            json = new JavaScriptSerializer();
            json.MaxJsonLength = int.MaxValue;
        }

        #region 資料傳輸與視圖模型 (符合 C# 5.0)

        public class SearchFilterModel
        {
            public string FacId { get; set; }
            public int Year { get; set; }
            public int Month { get; set; }
            public string WashType { get; set; }
            public string Keyword { get; set; }

            public SearchFilterModel()
            {
                FacId = "";
                Year = DateTime.Now.Year - 1911;
                Month = DateTime.Now.Month;
                WashType = "";
                Keyword = "";
            }
        }

        public class PhotoInfoModel
        {
            public bool Exists { get; set; }
            public string FileName { get; set; }
            public string Url { get; set; }
            public long FileSize { get; set; }

            public PhotoInfoModel()
            {
                Exists = false;
                FileName = "";
                Url = "";
                FileSize = 0;
            }
        }

        public class WashRecordModel
        {
            public int PID { get; set; }
            public string FacId { get; set; }
            public string FacName { get; set; }
            public int PIndex { get; set; }
            public string WashDate { get; set; }
            public int WashDay { get; set; }
            public string DayOfWeekStr { get; set; }
            public bool IsWeekend { get; set; }
            public string WashTime_Start { get; set; }
            public string WashTime_End { get; set; }
            public string WashTimeRange { get; set; }
            public string WashType { get; set; }
            public int Length1 { get; set; }
            public int Length2 { get; set; }
            public int TotalLength { get; set; }
            public string PPL { get; set; }
            public PhotoInfoModel BeforePhoto { get; set; }
            public PhotoInfoModel AfterPhoto { get; set; }
            public string EditUrl { get; set; }

            public WashRecordModel()
            {
                PID = 0;
                FacId = "";
                FacName = "";
                PIndex = 0;
                WashDate = "";
                WashDay = 0;
                DayOfWeekStr = "";
                IsWeekend = false;
                WashTime_Start = "";
                WashTime_End = "";
                WashTimeRange = "";
                WashType = "洗";
                Length1 = 0;
                Length2 = 0;
                TotalLength = 0;
                PPL = "";
                BeforePhoto = new PhotoInfoModel();
                AfterPhoto = new PhotoInfoModel();
                EditUrl = "";
            }
        }

        public class DailySummaryModel
        {
            public string DateStr { get; set; }
            public int DayNum { get; set; }
            public string DayOfWeekStr { get; set; }
            public bool IsWeekend { get; set; }
            public bool IsToday { get; set; }
            public bool HasRecords { get; set; }
            public int RecordCount { get; set; }
            public int TotalLength { get; set; }
            public List<WashRecordModel> Records { get; set; }

            public DailySummaryModel()
            {
                DateStr = "";
                DayNum = 0;
                DayOfWeekStr = "";
                IsWeekend = false;
                IsToday = false;
                HasRecords = false;
                RecordCount = 0;
                TotalLength = 0;
                Records = new List<WashRecordModel>();
            }
        }

        public class MonthlyKpiModel
        {
            public int TotalCount { get; set; }
            public int ActiveDays { get; set; }
            public int WashCount { get; set; }
            public int SweepCount { get; set; }
            public int BothCount { get; set; }
            public int WashLength { get; set; }
            public int SweepLength { get; set; }
            public int TotalLength { get; set; }
            public double TotalLengthKm { get; set; }
            public int BeforePhotoCount { get; set; }
            public int AfterPhotoCount { get; set; }
            public int TotalPhotoCount { get; set; }

            public MonthlyKpiModel()
            {
                TotalCount = 0;
                ActiveDays = 0;
                WashCount = 0;
                SweepCount = 0;
                BothCount = 0;
                WashLength = 0;
                SweepLength = 0;
                TotalLength = 0;
                TotalLengthKm = 0.0;
                BeforePhotoCount = 0;
                AfterPhotoCount = 0;
                TotalPhotoCount = 0;
            }
        }

        #endregion

        protected void Page_Load(object sender, EventArgs e)
        {
            string action = Request["action"];
            if (!string.IsNullOrEmpty(action))
            {
                if (string.Equals(action, "export", StringComparison.OrdinalIgnoreCase) ||
                    string.Equals(action, "exportexcel", StringComparison.OrdinalIgnoreCase))
                {
                    try
                    {
                        ExportExcel();
                    }
                    catch (System.Threading.ThreadAbortException)
                    {
                    }
                    catch (Exception ex)
                    {
                        Response.ContentType = "text/html; charset=utf-8";
                        Response.Write("<script>alert('匯出 Excel 失敗：" + HttpUtility.JavaScriptStringEncode(ex.Message) + "'); window.close();</script>");
                    }
                    return;
                }

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
                        Message = "系統處理失敗：" + ex.Message
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
                case "getinitdata":
                    GetInitData();
                    break;
                case "getlist":
                    GetWashList();
                    break;
                case "deletedata":
                    DeleteWashData();
                    break;
                default:
                    Response.Write(json.Serialize(new { Success = false, Message = "未知的操作指令：" + action }));
                    break;
            }
        }

        #region MD5 安全校驗碼計算

        private string ComputeMd5(string input)
        {
            if (string.IsNullOrEmpty(input)) return string.Empty;
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

        private string GenerateToken(string facId)
        {
            if (string.IsNullOrEmpty(facId)) return string.Empty;
            return ComputeMd5("MD5:" + facId + DateTime.Now.ToString("yyyyMMddHH"));
        }

        #endregion

        #region 初始化資訊讀取 (工廠選單、年份、當前身分)

        private void GetInitData()
        {
            UserAccount currentUser = Session["UserAccount"] as UserAccount;
            string loginUserId = Session["LoginUser"] as string;
            bool isManager = false;
            string userFacId = string.Empty;
            string userFacName = string.Empty;
            string userName = string.Empty;

            if (currentUser != null)
            {
                isManager = MenuService.CheckLicense(currentUser.Lic, 9);
                userFacId = currentUser.FacID != null ? currentUser.FacID.Trim() : string.Empty;
                userName = currentUser.Name != null ? currentUser.Name.Trim() : string.Empty;
            }
            else if (!string.IsNullOrEmpty(loginUserId))
            {
                DataTable dtUser = DbHelper.ExecuteDataTable("SELECT UserID, Name, Lic, FAC_ID FROM UserAcc WHERE UserID = @UserID",
                    new SqlParameter("@UserID", loginUserId));
                if (dtUser.Rows.Count > 0)
                {
                    DataRow r = dtUser.Rows[0];
                    long lic = 0L;
                    if (r["Lic"] != DBNull.Value) long.TryParse(r["Lic"].ToString(), out lic);
                    isManager = MenuService.CheckLicense(lic, 9);
                    userFacId = r["FAC_ID"] != DBNull.Value ? r["FAC_ID"].ToString().Trim() : string.Empty;
                    userName = r["Name"] != DBNull.Value ? r["Name"].ToString().Trim() : string.Empty;
                }
            }

            // 取得所選廠場代碼 (若有傳入 id 且具有權限)
            string reqFacId = Request["id"];
            if (reqFacId != null) reqFacId = reqFacId.Trim();

            string defaultFacId = string.Empty;
            if (!isManager && !string.IsNullOrEmpty(userFacId))
            {
                defaultFacId = userFacId;
            }
            else if (!string.IsNullOrEmpty(reqFacId))
            {
                defaultFacId = reqFacId;
            }
            else if (!string.IsNullOrEmpty(userFacId))
            {
                defaultFacId = userFacId;
            }

            // 載入所有認養公私場所
            string sqlFac = "SELECT FAC_ID, FAC_NAME FROM FAC_Main ORDER BY FAC_NAME";
            DataTable dtFac = DbHelper.ExecuteDataTable(sqlFac);
            List<object> facList = new List<object>();

            foreach (DataRow row in dtFac.Rows)
            {
                string fId = row["FAC_ID"] != null ? row["FAC_ID"].ToString().Trim() : string.Empty;
                string fName = row["FAC_NAME"] != null ? row["FAC_NAME"].ToString().Trim() : string.Empty;
                if (string.IsNullOrEmpty(defaultFacId))
                {
                    defaultFacId = fId;
                }
                if (string.Equals(fId, defaultFacId, StringComparison.OrdinalIgnoreCase))
                {
                    userFacName = fName;
                }
                facList.Add(new
                {
                    FacId = fId,
                    FacName = fName
                });
            }

            // 年份清單 (民國年：當前年前後範圍)
            int currentYear = DateTime.Now.Year - 1911;
            int currentMonth = DateTime.Now.Month;
            List<int> yearList = new List<int>();
            for (int y = currentYear - 3; y <= currentYear + 1; y++)
            {
                yearList.Add(y);
            }

            string token = GenerateToken(defaultFacId);

            Response.Write(json.Serialize(new
            {
                Success = true,
                IsManager = isManager,
                UserFacId = userFacId,
                UserName = userName,
                CurrentFacId = defaultFacId,
                CurrentFacName = userFacName,
                YearList = yearList,
                CurrentYear = currentYear,
                CurrentMonth = currentMonth,
                FacList = facList,
                Token = token
            }));
        }

        #endregion

        #region 查詢洗掃日誌清單與統計數據

        private void GetWashList()
        {
            string facId = Request["facId"];
            if (facId != null) facId = facId.Trim();

            string yearStr = Request["year"];
            string monthStr = Request["month"];
            string washTypeFilter = Request["washType"];
            if (washTypeFilter != null) washTypeFilter = washTypeFilter.Trim();
            string keyword = Request["keyword"];
            if (keyword != null) keyword = keyword.Trim();

            // 權限檢查
            UserAccount currentUser = Session["UserAccount"] as UserAccount;
            if (currentUser != null && !MenuService.CheckLicense(currentUser.Lic, 9))
            {
                if (!string.IsNullOrEmpty(currentUser.FacID))
                {
                    facId = currentUser.FacID.Trim();
                }
            }

            if (string.IsNullOrEmpty(facId))
            {
                Response.Write(json.Serialize(new
                {
                    Success = false,
                    Message = "請指定認養公私場所！"
                }));
                return;
            }

            int rocYear = DateTime.Now.Year - 1911;
            if (!string.IsNullOrEmpty(yearStr)) int.TryParse(yearStr, out rocYear);

            int month = DateTime.Now.Month;
            if (!string.IsNullOrEmpty(monthStr)) int.TryParse(monthStr, out month);
            if (month < 1) month = 1;
            if (month > 12) month = 12;

            int westYear = rocYear + 1911;
            int daysInMonth = DateTime.DaysInMonth(westYear, month);
            DateTime startDate = new DateTime(westYear, month, 1);
            DateTime endDate = new DateTime(westYear, month, daysInMonth);

            // 取得場所名稱
            string facName = string.Empty;
            DataTable dtFac = DbHelper.ExecuteDataTable("SELECT FAC_NAME FROM FAC_Main WHERE FAC_ID = @FAC_ID",
                new SqlParameter("@FAC_ID", facId));
            if (dtFac.Rows.Count > 0 && dtFac.Rows[0]["FAC_NAME"] != DBNull.Value)
            {
                facName = dtFac.Rows[0]["FAC_NAME"].ToString().Trim();
            }

            // 查詢當月洗掃紀錄
            string sql = @"SELECT [pID], [FAC_ID], [pIndex], [WashDate], 
                                  CONVERT(VARCHAR(5), [WashTime_Start], 108) AS WashTime_Start, 
                                  CONVERT(VARCHAR(5), [WashTime_End], 108) AS WashTime_End, 
                                  [WashType], [Length1], [Length2], [PPL] 
                           FROM RoadWash_Data 
                           WHERE FAC_ID = @FAC_ID 
                             AND WashDate >= @StartDate AND WashDate <= @EndDate ";

            List<SqlParameter> paramList = new List<SqlParameter>();
            paramList.Add(new SqlParameter("@FAC_ID", facId));
            paramList.Add(new SqlParameter("@StartDate", startDate));
            paramList.Add(new SqlParameter("@EndDate", endDate));

            if (!string.IsNullOrEmpty(washTypeFilter))
            {
                sql += " AND WashType = @WashType ";
                paramList.Add(new SqlParameter("@WashType", washTypeFilter));
            }

            if (!string.IsNullOrEmpty(keyword))
            {
                sql += " AND (PPL LIKE @Keyword OR CAST(pIndex AS VARCHAR) LIKE @Keyword) ";
                paramList.Add(new SqlParameter("@Keyword", "%" + keyword + "%"));
            }

            sql += " ORDER BY WashDate ASC, WashTime_Start ASC, pIndex ASC";

            DataTable dtRecords = DbHelper.ExecuteDataTable(sql, paramList.ToArray());

            string token = GenerateToken(facId);

            List<WashRecordModel> recordList = new List<WashRecordModel>();
            MonthlyKpiModel kpi = new MonthlyKpiModel();
            Dictionary<int, List<WashRecordModel>> dayRecordMap = new Dictionary<int, List<WashRecordModel>>();
            HashSet<int> activeDaysSet = new HashSet<int>();

            for (int d = 1; d <= daysInMonth; d++)
            {
                dayRecordMap[d] = new List<WashRecordModel>();
            }

            foreach (DataRow row in dtRecords.Rows)
            {
                int pIndex = 0;
                if (row["pIndex"] != DBNull.Value) int.TryParse(row["pIndex"].ToString(), out pIndex);

                int pid = 0;
                if (row["pID"] != DBNull.Value) int.TryParse(row["pID"].ToString(), out pid);

                DateTime wDate = startDate;
                if (row["WashDate"] != DBNull.Value) DateTime.TryParse(row["WashDate"].ToString(), out wDate);

                int wDay = wDate.Day;
                activeDaysSet.Add(wDay);

                string tStart = row["WashTime_Start"] != DBNull.Value ? row["WashTime_Start"].ToString().Trim() : "";
                string tEnd = row["WashTime_End"] != DBNull.Value ? row["WashTime_End"].ToString().Trim() : "";
                string timeRange = "";
                if (!string.IsNullOrEmpty(tStart) && !string.IsNullOrEmpty(tEnd))
                    timeRange = tStart + " ~ " + tEnd;
                else if (!string.IsNullOrEmpty(tStart))
                    timeRange = tStart;
                else
                    timeRange = "--";

                string wType = row["WashType"] != DBNull.Value ? row["WashType"].ToString().Trim() : "洗";
                int len1 = 0, len2 = 0;
                if (row["Length1"] != DBNull.Value) int.TryParse(row["Length1"].ToString(), out len1);
                if (row["Length2"] != DBNull.Value) int.TryParse(row["Length2"].ToString(), out len2);
                int totalLen = len1 + len2;

                string ppl = row["PPL"] != DBNull.Value ? row["PPL"].ToString().Trim() : "";

                // 檢查相片
                PhotoInfoModel beforePic = new PhotoInfoModel();
                PhotoInfoModel afterPic = new PhotoInfoModel();

                string picVirtualDir = "/NTPC_FEC/Upload/WashPIC/" + facId + "/" + pIndex;
                string picPhysicalDir = Server.MapPath(picVirtualDir);
                if (Directory.Exists(picPhysicalDir))
                {
                    DirectoryInfo di = new DirectoryInfo(picPhysicalDir);
                    FileInfo[] bFiles = di.GetFiles("洗掃前照片.*");
                    if (bFiles.Length > 0)
                    {
                        beforePic.Exists = true;
                        beforePic.FileName = bFiles[0].Name;
                        beforePic.Url = picVirtualDir + "/" + bFiles[0].Name + "?t=" + bFiles[0].LastWriteTime.Ticks;
                        beforePic.FileSize = bFiles[0].Length;
                        kpi.BeforePhotoCount++;
                    }

                    FileInfo[] aFiles = di.GetFiles("洗掃後照片.*");
                    if (aFiles.Length > 0)
                    {
                        afterPic.Exists = true;
                        afterPic.FileName = aFiles[0].Name;
                        afterPic.Url = picVirtualDir + "/" + aFiles[0].Name + "?t=" + aFiles[0].LastWriteTime.Ticks;
                        afterPic.FileSize = aFiles[0].Length;
                        kpi.AfterPhotoCount++;
                    }
                }

                // 編輯跳轉連結
                string editUrl = string.Format("DataInput.aspx?id={0}&id1={1}&id2={2}&mode=edit",
                    HttpUtility.UrlEncode(facId),
                    HttpUtility.UrlEncode(token),
                    pIndex);

                bool isWeekend = (wDate.DayOfWeek == DayOfWeek.Saturday || wDate.DayOfWeek == DayOfWeek.Sunday);

                WashRecordModel rec = new WashRecordModel
                {
                    PID = pid,
                    FacId = facId,
                    FacName = facName,
                    PIndex = pIndex,
                    WashDate = wDate.ToString("yyyy-MM-dd"),
                    WashDay = wDay,
                    DayOfWeekStr = GetDayOfWeekChinese(wDate.DayOfWeek),
                    IsWeekend = isWeekend,
                    WashTime_Start = tStart,
                    WashTime_End = tEnd,
                    WashTimeRange = timeRange,
                    WashType = wType,
                    Length1 = len1,
                    Length2 = len2,
                    TotalLength = totalLen,
                    PPL = ppl,
                    BeforePhoto = beforePic,
                    AfterPhoto = afterPic,
                    EditUrl = editUrl
                };

                recordList.Add(rec);
                if (dayRecordMap.ContainsKey(wDay))
                {
                    dayRecordMap[wDay].Add(rec);
                }

                // 累計 KPI
                kpi.TotalCount++;
                kpi.TotalLength += totalLen;

                if (wType.IndexOf("洗") >= 0 && wType.IndexOf("掃") >= 0)
                {
                    kpi.BothCount++;
                    kpi.WashLength += len1;
                    kpi.SweepLength += len2;
                }
                else if (wType.IndexOf("掃") >= 0)
                {
                    kpi.SweepCount++;
                    kpi.SweepLength += totalLen;
                }
                else
                {
                    kpi.WashCount++;
                    kpi.WashLength += totalLen;
                }
            }

            kpi.ActiveDays = activeDaysSet.Count;
            kpi.TotalLengthKm = Math.Round((double)kpi.TotalLength / 1000.0, 2);
            kpi.TotalPhotoCount = kpi.BeforePhotoCount + kpi.AfterPhotoCount;

            // 產生 1 ~ daysInMonth 之月曆摘要
            DateTime today = DateTime.Today;
            List<DailySummaryModel> dailySummaries = new List<DailySummaryModel>();
            for (int day = 1; day <= daysInMonth; day++)
            {
                DateTime dtCurrent = new DateTime(westYear, month, day);
                List<WashRecordModel> dayRecs = dayRecordMap.ContainsKey(day) ? dayRecordMap[day] : new List<WashRecordModel>();
                int sumLen = 0;
                for (int i = 0; i < dayRecs.Count; i++)
                {
                    sumLen += dayRecs[i].TotalLength;
                }

                bool isWk = (dtCurrent.DayOfWeek == DayOfWeek.Saturday || dtCurrent.DayOfWeek == DayOfWeek.Sunday);
                bool isTod = (dtCurrent == today);

                dailySummaries.Add(new DailySummaryModel
                {
                    DateStr = dtCurrent.ToString("yyyy-MM-dd"),
                    DayNum = day,
                    DayOfWeekStr = GetDayOfWeekChinese(dtCurrent.DayOfWeek),
                    IsWeekend = isWk,
                    IsToday = isTod,
                    HasRecords = dayRecs.Count > 0,
                    RecordCount = dayRecs.Count,
                    TotalLength = sumLen,
                    Records = dayRecs
                });
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                FacId = facId,
                FacName = facName,
                Year = rocYear,
                Month = month,
                DaysInMonth = daysInMonth,
                TotalRecords = recordList.Count,
                Records = recordList,
                DailySummaries = dailySummaries,
                KPI = kpi,
                Token = token,
                NewRecordUrl = string.Format("DataInput.aspx?id={0}&id1={1}&mode=new",
                    HttpUtility.UrlEncode(facId),
                    HttpUtility.UrlEncode(token))
            }));
        }

        private string GetDayOfWeekChinese(DayOfWeek dow)
        {
            switch (dow)
            {
                case DayOfWeek.Monday: return "週一";
                case DayOfWeek.Tuesday: return "週二";
                case DayOfWeek.Wednesday: return "週三";
                case DayOfWeek.Thursday: return "週四";
                case DayOfWeek.Friday: return "週五";
                case DayOfWeek.Saturday: return "週六";
                case DayOfWeek.Sunday: return "週日";
                default: return "";
            }
        }

        #endregion

        #region 刪除洗掃日誌與實體照片

        private void DeleteWashData()
        {
            string rawBody = string.Empty;
            using (StreamReader sr = new StreamReader(Request.InputStream, Encoding.UTF8))
            {
                rawBody = sr.ReadToEnd();
            }

            string facId = string.Empty;
            int pIndex = 0;

            if (!string.IsNullOrEmpty(rawBody))
            {
                Dictionary<string, object> reqData = json.Deserialize<Dictionary<string, object>>(rawBody);
                if (reqData != null)
                {
                    if (reqData.ContainsKey("facId") && reqData["facId"] != null)
                        facId = reqData["facId"].ToString().Trim();
                    if (reqData.ContainsKey("pIndex") && reqData["pIndex"] != null)
                        int.TryParse(reqData["pIndex"].ToString(), out pIndex);
                }
            }

            if (string.IsNullOrEmpty(facId))
            {
                facId = Request["facId"];
                if (facId != null) facId = facId.Trim();
            }
            if (pIndex <= 0)
            {
                int.TryParse(Request["pIndex"], out pIndex);
            }

            if (string.IsNullOrEmpty(facId) || pIndex <= 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "無效的刪除參數！" }));
                return;
            }

            // 權限檢查：一般業者禁止刪除其他廠場資料
            UserAccount currentUser = Session["UserAccount"] as UserAccount;
            if (currentUser != null && !MenuService.CheckLicense(currentUser.Lic, 9))
            {
                if (!string.IsNullOrEmpty(currentUser.FacID) &&
                    !string.Equals(currentUser.FacID.Trim(), facId, StringComparison.OrdinalIgnoreCase))
                {
                    Response.Write(json.Serialize(new { Success = false, Message = "權限不足：您只能刪除自身列管廠場之洗掃紀錄！" }));
                    return;
                }
            }

            // 1. 刪除資料庫紀錄
            string sqlDel = "DELETE FROM RoadWash_Data WHERE FAC_ID = @FAC_ID AND pIndex = @pIndex";
            int affected = DbHelper.ExecuteNonQuery(sqlDel,
                new SqlParameter("@FAC_ID", facId),
                new SqlParameter("@pIndex", pIndex));

            // 2. 刪除實體檔案資料夾
            try
            {
                string targetDirVirtual = "/NTPC_FEC/Upload/WashPIC/" + facId + "/" + pIndex;
                string targetDirPhysical = Server.MapPath(targetDirVirtual);
                if (Directory.Exists(targetDirPhysical))
                {
                    Directory.Delete(targetDirPhysical, true);
                }
            }
            catch (Exception ex)
            {
                // 照片檔案刪除若遇鎖定不阻擋主紀錄刪除
                System.Diagnostics.Trace.WriteLine("刪除洗掃照片實體檔案時發生錯誤：" + ex.Message);
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                Message = "洗掃日誌紀錄 (序號: " + pIndex + ") 已成功刪除！",
                FacId = facId,
                PIndex = pIndex,
                Affected = affected
            }));
        }

        #endregion

        #region 匯出 Excel 報表 (採用 NPOI 標準格式)

        private void ExportExcel()
        {
            string facId = Request["facId"];
            if (facId != null) facId = facId.Trim();

            string yearStr = Request["year"];
            string monthStr = Request["month"];

            // 權限檢查
            UserAccount currentUser = Session["UserAccount"] as UserAccount;
            if (currentUser != null && !MenuService.CheckLicense(currentUser.Lic, 9))
            {
                if (!string.IsNullOrEmpty(currentUser.FacID))
                {
                    facId = currentUser.FacID.Trim();
                }
            }

            if (string.IsNullOrEmpty(facId))
            {
                Response.ContentType = "text/html; charset=utf-8";
                Response.Write("<script>alert('請先指定欲匯出的公私場所！'); window.close();</script>");
                return;
            }

            int rocYear = DateTime.Now.Year - 1911;
            if (!string.IsNullOrEmpty(yearStr)) int.TryParse(yearStr, out rocYear);

            int month = DateTime.Now.Month;
            if (!string.IsNullOrEmpty(monthStr)) int.TryParse(monthStr, out month);
            if (month < 1) month = 1;
            if (month > 12) month = 12;

            int westYear = rocYear + 1911;
            int daysInMonth = DateTime.DaysInMonth(westYear, month);
            DateTime startDate = new DateTime(westYear, month, 1);
            DateTime endDate = new DateTime(westYear, month, daysInMonth);

            // 取得場所名稱
            string facName = string.Empty;
            DataTable dtFac = DbHelper.ExecuteDataTable("SELECT FAC_NAME FROM FAC_Main WHERE FAC_ID = @FAC_ID",
                new SqlParameter("@FAC_ID", facId));
            if (dtFac.Rows.Count > 0 && dtFac.Rows[0]["FAC_NAME"] != DBNull.Value)
            {
                facName = dtFac.Rows[0]["FAC_NAME"].ToString().Trim();
            }

            // 查詢紀錄
            string sql = @"SELECT [pIndex], [WashDate], 
                                  CONVERT(VARCHAR(5), [WashTime_Start], 108) AS WashTime_Start, 
                                  CONVERT(VARCHAR(5), [WashTime_End], 108) AS WashTime_End, 
                                  [WashType], [Length1], [Length2], [PPL] 
                           FROM RoadWash_Data 
                           WHERE FAC_ID = @FAC_ID 
                             AND WashDate >= @StartDate AND WashDate <= @EndDate 
                           ORDER BY WashDate ASC, WashTime_Start ASC, pIndex ASC";

            DataTable dtRecords = DbHelper.ExecuteDataTable(sql,
                new SqlParameter("@FAC_ID", facId),
                new SqlParameter("@StartDate", startDate),
                new SqlParameter("@EndDate", endDate));

            // 建立 NPOI Workbook
            HSSFWorkbook workbook = new HSSFWorkbook();
            ISheet sheet = workbook.CreateSheet("洗掃里程日誌");
            sheet.IsPrintGridlines = true;

            // 樣式設定
            // 1. 大標題樣式
            ICellStyle titleStyle = workbook.CreateCellStyle();
            titleStyle.Alignment = HorizontalAlignment.Center;
            titleStyle.VerticalAlignment = VerticalAlignment.Center;
            IFont titleFont = workbook.CreateFont();
            titleFont.FontName = "微軟正黑體";
            titleFont.FontHeightInPoints = 16;
            titleFont.IsBold = true;
            titleFont.Color = HSSFColor.DarkBlue.Index;
            titleStyle.SetFont(titleFont);

            // 2. 資訊標題樣式
            ICellStyle infoStyle = workbook.CreateCellStyle();
            infoStyle.Alignment = HorizontalAlignment.Left;
            infoStyle.VerticalAlignment = VerticalAlignment.Center;
            IFont infoFont = workbook.CreateFont();
            infoFont.FontName = "微軟正黑體";
            infoFont.FontHeightInPoints = 11;
            infoStyle.SetFont(infoFont);

            // 3. 表頭樣式 (新北科技藍底白字)
            ICellStyle headerStyle = workbook.CreateCellStyle();
            headerStyle.Alignment = HorizontalAlignment.Center;
            headerStyle.VerticalAlignment = VerticalAlignment.Center;
            headerStyle.FillForegroundColor = HSSFColor.SkyBlue.Index;
            headerStyle.FillPattern = FillPattern.SolidForeground;
            headerStyle.BorderTop = BorderStyle.Thin;
            headerStyle.BorderBottom = BorderStyle.Medium;
            headerStyle.BorderLeft = BorderStyle.Thin;
            headerStyle.BorderRight = BorderStyle.Thin;
            IFont headerFont = workbook.CreateFont();
            headerFont.FontName = "微軟正黑體";
            headerFont.FontHeightInPoints = 11;
            headerFont.IsBold = true;
            headerFont.Color = HSSFColor.DarkBlue.Index;
            headerStyle.SetFont(headerFont);

            // 4. 資料儲存格樣式 (置中與置左)
            ICellStyle cellCenter = workbook.CreateCellStyle();
            cellCenter.Alignment = HorizontalAlignment.Center;
            cellCenter.VerticalAlignment = VerticalAlignment.Center;
            cellCenter.BorderTop = BorderStyle.Thin;
            cellCenter.BorderBottom = BorderStyle.Thin;
            cellCenter.BorderLeft = BorderStyle.Thin;
            cellCenter.BorderRight = BorderStyle.Thin;
            IFont bodyFont = workbook.CreateFont();
            bodyFont.FontName = "微軟正黑體";
            bodyFont.FontHeightInPoints = 10;
            cellCenter.SetFont(bodyFont);

            ICellStyle cellRight = workbook.CreateCellStyle();
            cellRight.Alignment = HorizontalAlignment.Right;
            cellRight.VerticalAlignment = VerticalAlignment.Center;
            cellRight.BorderTop = BorderStyle.Thin;
            cellRight.BorderBottom = BorderStyle.Thin;
            cellRight.BorderLeft = BorderStyle.Thin;
            cellRight.BorderRight = BorderStyle.Thin;
            cellRight.SetFont(bodyFont);

            // 5. 合計列樣式
            ICellStyle totalStyle = workbook.CreateCellStyle();
            totalStyle.Alignment = HorizontalAlignment.Center;
            totalStyle.VerticalAlignment = VerticalAlignment.Center;
            totalStyle.FillForegroundColor = HSSFColor.Grey25Percent.Index;
            totalStyle.FillPattern = FillPattern.SolidForeground;
            totalStyle.BorderTop = BorderStyle.Medium;
            totalStyle.BorderBottom = BorderStyle.Double;
            totalStyle.BorderLeft = BorderStyle.Thin;
            totalStyle.BorderRight = BorderStyle.Thin;
            IFont totalFont = workbook.CreateFont();
            totalFont.FontName = "微軟正黑體";
            totalFont.FontHeightInPoints = 11;
            totalFont.IsBold = true;
            totalStyle.SetFont(totalFont);

            ICellStyle totalStyleRight = workbook.CreateCellStyle();
            totalStyleRight.Alignment = HorizontalAlignment.Right;
            totalStyleRight.VerticalAlignment = VerticalAlignment.Center;
            totalStyleRight.FillForegroundColor = HSSFColor.Grey25Percent.Index;
            totalStyleRight.FillPattern = FillPattern.SolidForeground;
            totalStyleRight.BorderTop = BorderStyle.Medium;
            totalStyleRight.BorderBottom = BorderStyle.Double;
            totalStyleRight.BorderLeft = BorderStyle.Thin;
            totalStyleRight.BorderRight = BorderStyle.Thin;
            totalStyleRight.SetFont(totalFont);

            // 繪製標題與資訊
            int rowIndex = 0;

            // Row 0: 系統主標題
            IRow r0 = sheet.CreateRow(rowIndex++);
            r0.HeightInPoints = 32;
            ICell c0 = r0.CreateCell(0);
            c0.SetCellValue("新北市固定溢散源管制平台 - 道路認養洗/掃街里程日誌");
            c0.CellStyle = titleStyle;
            sheet.AddMergedRegion(new CellRangeAddress(0, 0, 0, 9));

            // Row 1: 機構資訊
            IRow r1 = sheet.CreateRow(rowIndex++);
            r1.HeightInPoints = 22;
            ICell c1 = r1.CreateCell(0);
            c1.SetCellValue(string.Format("申報單位：{0} ({1})    申報年月：民國 {2} 年 {3} 月    列印日期：{4:yyyy-MM-dd HH:mm}",
                facName, facId, rocYear, month, DateTime.Now));
            c1.CellStyle = infoStyle;
            sheet.AddMergedRegion(new CellRangeAddress(1, 1, 0, 9));

            // Row 2: 空行
            rowIndex++;

            // Row 3: 表格欄位標題
            IRow rHead = sheet.CreateRow(rowIndex++);
            rHead.HeightInPoints = 26;
            string[] headers = new string[] {
                "項次", "洗掃日期", "星期", "洗掃時段", "執行方式", 
                "左側長度 (m)", "右側長度 (m)", "合計長度 (m)", "洗掃人員", "照片檢核"
            };
            for (int h = 0; h < headers.Length; h++)
            {
                ICell c = rHead.CreateCell(h);
                c.SetCellValue(headers[h]);
                c.CellStyle = headerStyle;
            }

            int sumLen1 = 0;
            int sumLen2 = 0;
            int sumTotal = 0;
            int photoCount = 0;

            // 填充資料
            for (int i = 0; i < dtRecords.Rows.Count; i++)
            {
                DataRow dr = dtRecords.Rows[i];
                int pIndex = 0;
                if (dr["pIndex"] != DBNull.Value) int.TryParse(dr["pIndex"].ToString(), out pIndex);

                DateTime wDate = startDate;
                if (dr["WashDate"] != DBNull.Value) DateTime.TryParse(dr["WashDate"].ToString(), out wDate);

                string tStart = dr["WashTime_Start"] != DBNull.Value ? dr["WashTime_Start"].ToString().Trim() : "";
                string tEnd = dr["WashTime_End"] != DBNull.Value ? dr["WashTime_End"].ToString().Trim() : "";
                string timeRange = (!string.IsNullOrEmpty(tStart) && !string.IsNullOrEmpty(tEnd)) ? (tStart + " ~ " + tEnd) : (tStart);

                string wType = dr["WashType"] != DBNull.Value ? dr["WashType"].ToString().Trim() : "洗";
                int len1 = 0, len2 = 0;
                if (dr["Length1"] != DBNull.Value) int.TryParse(dr["Length1"].ToString(), out len1);
                if (dr["Length2"] != DBNull.Value) int.TryParse(dr["Length2"].ToString(), out len2);
                int rowTot = len1 + len2;

                sumLen1 += len1;
                sumLen2 += len2;
                sumTotal += rowTot;

                string ppl = dr["PPL"] != DBNull.Value ? dr["PPL"].ToString().Trim() : "";

                // 檢查相片
                string photoStatus = "無照片";
                string picVirtualDir = "/NTPC_FEC/Upload/WashPIC/" + facId + "/" + pIndex;
                string picPhysicalDir = Server.MapPath(picVirtualDir);
                if (Directory.Exists(picPhysicalDir))
                {
                    DirectoryInfo di = new DirectoryInfo(picPhysicalDir);
                    bool bExists = di.GetFiles("洗掃前照片.*").Length > 0;
                    bool aExists = di.GetFiles("洗掃後照片.*").Length > 0;
                    if (bExists && aExists)
                    {
                        photoStatus = "前/後照片齊全";
                        photoCount += 2;
                    }
                    else if (bExists)
                    {
                        photoStatus = "僅洗掃前照片";
                        photoCount += 1;
                    }
                    else if (aExists)
                    {
                        photoStatus = "僅洗掃後照片";
                        photoCount += 1;
                    }
                }

                IRow row = sheet.CreateRow(rowIndex++);
                row.HeightInPoints = 22;

                ICell cell0 = row.CreateCell(0); cell0.SetCellValue(i + 1); cell0.CellStyle = cellCenter;
                ICell cell1 = row.CreateCell(1); cell1.SetCellValue(wDate.ToString("yyyy-MM-dd")); cell1.CellStyle = cellCenter;
                ICell cell2 = row.CreateCell(2); cell2.SetCellValue(GetDayOfWeekChinese(wDate.DayOfWeek)); cell2.CellStyle = cellCenter;
                ICell cell3 = row.CreateCell(3); cell3.SetCellValue(timeRange); cell3.CellStyle = cellCenter;
                ICell cell4 = row.CreateCell(4); cell4.SetCellValue(wType); cell4.CellStyle = cellCenter;
                ICell cell5 = row.CreateCell(5); cell5.SetCellValue(len1); cell5.CellStyle = cellRight;
                ICell cell6 = row.CreateCell(6); cell6.SetCellValue(len2); cell6.CellStyle = cellRight;
                ICell cell7 = row.CreateCell(7); cell7.SetCellValue(rowTot); cell7.CellStyle = cellRight;
                ICell cell8 = row.CreateCell(8); cell8.SetCellValue(ppl); cell8.CellStyle = cellCenter;
                ICell cell9 = row.CreateCell(9); cell9.SetCellValue(photoStatus); cell9.CellStyle = cellCenter;
            }

            // 合計列
            IRow rTot = sheet.CreateRow(rowIndex++);
            rTot.HeightInPoints = 24;

            ICell totC0 = rTot.CreateCell(0);
            totC0.SetCellValue("月累計統計");
            totC0.CellStyle = totalStyle;
            sheet.AddMergedRegion(new CellRangeAddress(rowIndex - 1, rowIndex - 1, 0, 4));

            for (int k = 1; k <= 4; k++)
            {
                ICell blankC = rTot.CreateCell(k);
                blankC.CellStyle = totalStyle;
            }

            ICell totC5 = rTot.CreateCell(5); totC5.SetCellValue(sumLen1); totC5.CellStyle = totalStyleRight;
            ICell totC6 = rTot.CreateCell(6); totC6.SetCellValue(sumLen2); totC6.CellStyle = totalStyleRight;
            ICell totC7 = rTot.CreateCell(7); totC7.SetCellValue(sumTotal); totC7.CellStyle = totalStyleRight;
            ICell totC8 = rTot.CreateCell(8); totC8.SetCellValue(string.Format("總次數: {0}次", dtRecords.Rows.Count)); totC8.CellStyle = totalStyle;
            ICell totC9 = rTot.CreateCell(9); totC9.SetCellValue(string.Format("照片: {0}張", photoCount)); totC9.CellStyle = totalStyle;

            // 調整欄寬
            sheet.SetColumnWidth(0, 8 * 256);
            sheet.SetColumnWidth(1, 14 * 256);
            sheet.SetColumnWidth(2, 9 * 256);
            sheet.SetColumnWidth(3, 16 * 256);
            sheet.SetColumnWidth(4, 11 * 256);
            sheet.SetColumnWidth(5, 14 * 256);
            sheet.SetColumnWidth(6, 14 * 256);
            sheet.SetColumnWidth(7, 15 * 256);
            sheet.SetColumnWidth(8, 14 * 256);
            sheet.SetColumnWidth(9, 18 * 256);

            // 輸出串流
            string fileName = string.Format("洗掃里程日誌_{0}_{1}年{2:00}月.xls", facId, rocYear, month);
            string encodedName = HttpUtility.UrlEncode(fileName, Encoding.UTF8);

            Response.Clear();
            Response.Buffer = true;
            Response.ContentType = "application/vnd.ms-excel";
            Response.AddHeader("Content-Disposition", "attachment;filename=" + encodedName + ";filename*=UTF-8''" + encodedName);

            using (MemoryStream ms = new MemoryStream())
            {
                workbook.Write(ms);
                Response.BinaryWrite(ms.ToArray());
            }

            Response.Flush();
            Response.End();
        }

        #endregion
    }
}
