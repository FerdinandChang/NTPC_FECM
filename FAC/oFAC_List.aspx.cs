using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Text;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.UI;
using NPOI.HSSF.UserModel;
using NPOI.SS.UserModel;
using NTPC_FEC.Helpers;
using NTPC_FEC.Services;

namespace NTPC_FEC.FAC
{
    public partial class oFAC_List : Page
    {
        private JavaScriptSerializer json;

        public oFAC_List()
        {
            json = new JavaScriptSerializer();
            json.MaxJsonLength = int.MaxValue;
        }

        public class FilterModel
        {
            public string Mode { get; set; }
            public string CNo { get; set; }
            public string FacName { get; set; }
            public string ProcessName { get; set; }
            public string ProcessLic { get; set; }
            public string StartDateS { get; set; }
            public string StartDateE { get; set; }
            public string ContinueDateS { get; set; }
            public string ContinueDateE { get; set; }
            public string WorkDeadline { get; set; }
            public int PageIndex { get; set; }
            public int PageSize { get; set; }

            public FilterModel()
            {
                Mode = "valid";
                CNo = "";
                FacName = "";
                ProcessName = "";
                ProcessLic = "";
                StartDateS = "";
                StartDateE = "";
                ContinueDateS = "";
                ContinueDateE = "";
                WorkDeadline = "ALL";
                PageIndex = 1;
                PageSize = 20;
            }
        }

        public class SaveProcessModel
        {
            public bool IsEdit { get; set; }
            public string OFacId { get; set; }
            public string CNo { get; set; }
            public string FacName { get; set; }
            public string ProcessId { get; set; }
            public string ProcessName { get; set; }
            public string ProcessType { get; set; }
            public string ProcessLic { get; set; }
            public string StartDate { get; set; }
            public string EndDate { get; set; }
            public string WorkDeadline { get; set; }
            public string ContinueDeadline { get; set; }
            public string PMemo { get; set; }

            public SaveProcessModel()
            {
                IsEdit = false;
                OFacId = "";
                CNo = "";
                FacName = "";
                ProcessId = "";
                ProcessName = "";
                ProcessType = "操作";
                ProcessLic = "";
                StartDate = "";
                EndDate = "";
                WorkDeadline = "";
                ContinueDeadline = "";
                PMemo = "";
            }
        }

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
                if (action == "exportExcel")
                {
                    HandleExportExcel();
                    return;
                }

                Response.ContentType = "application/json; charset=utf-8";
                try
                {
                    HandleAjaxAction(action);
                }
                catch (System.Threading.ThreadAbortException)
                {
                    return;
                }
                catch (Exception ex)
                {
                    Response.Clear();
                    Response.ContentType = "application/json; charset=utf-8";
                    Response.Write(json.Serialize(new
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
                }
            }
        }

        private void HandleAjaxAction(string action)
        {
            switch (action)
            {
                case "getCounts":
                    GetCounts();
                    break;
                case "getList":
                    GetList();
                    break;
                case "checkCNo":
                    CheckCNo();
                    break;
                case "getProcessDetail":
                    GetProcessDetail();
                    break;
                case "saveProcess":
                    SaveProcess();
                    break;
                case "getUploadHistory":
                    GetUploadHistory();
                    break;
                case "uploadLicFile":
                    UploadLicFile();
                    break;
                case "getUnlockDetail":
                    GetUnlockDetail();
                    break;
                case "saveUnlock":
                    SaveUnlock();
                    break;
                default:
                    Response.Write(json.Serialize(new { Success = false, Message = "未知的請求操作：" + action }));
                    break;
            }
        }

        private string GetCurrentUserName()
        {
            try
            {
                var user = AuthService.GetCurrentUser(HttpContext.Current);
                if (user != null && !string.IsNullOrEmpty(user.UserID))
                {
                    return user.UserID;
                }
            }
            catch
            {
            }

            if (Session != null && Session["LoginUser"] != null)
            {
                return Session["LoginUser"].ToString();
            }

            return "System";
        }

        private void EnsureDirectories()
        {
            string licDir = Server.MapPath("~/Upload/LicDoc");
            if (!Directory.Exists(licDir))
            {
                Directory.CreateDirectory(licDir);
            }
            string historyDir = Path.Combine(licDir, "History");
            if (!Directory.Exists(historyDir))
            {
                Directory.CreateDirectory(historyDir);
            }
        }

        private void GetCounts()
        {
            string sqlValid = "SELECT COUNT(*) FROM oFAC_Process WHERE Unlock_DocDate IS NULL AND (End_Date >= CAST(GETDATE() AS DATE) OR End_Date IS NULL)";
            string sqlExpired = "SELECT COUNT(*) FROM oFAC_Process WHERE Unlock_DocDate IS NULL AND End_Date < CAST(GETDATE() AS DATE)";
            string sqlUnlocked = "SELECT COUNT(*) FROM oFAC_Process WHERE Unlock_DocDate IS NOT NULL";
            string sqlTotal = "SELECT COUNT(*) FROM oFAC_Process";

            int validCount = Convert.ToInt32(DbHelper.ExecuteScalar(sqlValid));
            int expiredCount = Convert.ToInt32(DbHelper.ExecuteScalar(sqlExpired));
            int unlockedCount = Convert.ToInt32(DbHelper.ExecuteScalar(sqlUnlocked));
            int totalCount = Convert.ToInt32(DbHelper.ExecuteScalar(sqlTotal));

            Response.Write(json.Serialize(new
            {
                Success = true,
                Counts = new
                {
                    Valid = validCount,
                    Expired = expiredCount,
                    Unlocked = unlockedCount,
                    Total = totalCount
                }
            }));
        }

        private void GetList()
        {
            EnsureDirectories();
            FilterModel filter = ParseFilter();

            List<SqlParameter> pList = new List<SqlParameter>();
            StringBuilder whereSb = new StringBuilder();

            // 模式過濾
            if (filter.Mode == "valid")
            {
                whereSb.Append(" (p.Unlock_DocDate IS NULL AND (p.End_Date >= CAST(GETDATE() AS DATE) OR p.End_Date IS NULL)) ");
            }
            else if (filter.Mode == "expired")
            {
                whereSb.Append(" (p.Unlock_DocDate IS NULL AND p.End_Date < CAST(GETDATE() AS DATE)) ");
            }
            else if (filter.Mode == "unlocked")
            {
                whereSb.Append(" (p.Unlock_DocDate IS NOT NULL) ");
            }
            else
            {
                whereSb.Append(" (1=1) ");
            }

            // 管制編號
            if (!string.IsNullOrEmpty(filter.CNo))
            {
                whereSb.Append(" AND m.C_NO LIKE '%' + @CNo + '%' ");
                pList.Add(new SqlParameter("@CNo", filter.CNo.Trim()));
            }

            // 場所名稱
            if (!string.IsNullOrEmpty(filter.FacName))
            {
                whereSb.Append(" AND m.FAC_NAME LIKE '%' + @FacName + '%' ");
                pList.Add(new SqlParameter("@FacName", filter.FacName.Trim()));
            }

            // 製程名稱
            if (!string.IsNullOrEmpty(filter.ProcessName))
            {
                whereSb.Append(" AND p.Process_Name LIKE '%' + @ProcessName + '%' ");
                pList.Add(new SqlParameter("@ProcessName", filter.ProcessName.Trim()));
            }

            // 許可證字號
            if (!string.IsNullOrEmpty(filter.ProcessLic))
            {
                whereSb.Append(" AND p.Process_Lic LIKE '%' + @ProcessLic + '%' ");
                pList.Add(new SqlParameter("@ProcessLic", filter.ProcessLic.Trim()));
            }

            // 有效期限
            DateTime dtS;
            if (DateTime.TryParse(filter.StartDateS, out dtS))
            {
                whereSb.Append(" AND p.End_Date >= @StartDateS ");
                pList.Add(new SqlParameter("@StartDateS", dtS));
            }
            DateTime dtE;
            if (DateTime.TryParse(filter.StartDateE, out dtE))
            {
                whereSb.Append(" AND p.Start_Date <= @StartDateE ");
                pList.Add(new SqlParameter("@StartDateE", dtE));
            }

            // 展延期限
            DateTime dtCS;
            if (DateTime.TryParse(filter.ContinueDateS, out dtCS))
            {
                whereSb.Append(" AND p.Continue_Deadline >= @ContinueDateS ");
                pList.Add(new SqlParameter("@ContinueDateS", dtCS));
            }
            DateTime dtCE;
            if (DateTime.TryParse(filter.ContinueDateE, out dtCE))
            {
                whereSb.Append(" AND p.Continue_Deadline <= @ContinueDateE ");
                pList.Add(new SqlParameter("@ContinueDateE", dtCE));
            }

            // 工務期限
            if (filter.WorkDeadline == "Y")
            {
                whereSb.Append(" AND p.Work_Deadline IS NOT NULL ");
            }
            else if (filter.WorkDeadline == "N")
            {
                whereSb.Append(" AND p.Work_Deadline IS NULL ");
            }

            // 計算總筆數
            string countSql = "SELECT COUNT(*) FROM oFAC_Process p LEFT JOIN oFAC_Main m ON p.oFAC_ID = m.oFAC_ID WHERE " + whereSb.ToString();
            int total = Convert.ToInt32(DbHelper.ExecuteScalar(countSql, pList.ToArray()));

            // 分頁查詢 (C# 5.0 SQL Server 支援 ROW_NUMBER)
            int pageIndex = filter.PageIndex <= 0 ? 1 : filter.PageIndex;
            int pageSize = filter.PageSize <= 0 ? 20 : filter.PageSize;
            int startRow = (pageIndex - 1) * pageSize + 1;
            int endRow = pageIndex * pageSize;

            string querySql = string.Format(
                "SELECT * FROM ( " +
                "  SELECT p.*, m.FAC_NAME, m.C_NO, " +
                "         ROW_NUMBER() OVER (ORDER BY m.C_NO ASC, p.Process_ID ASC) as RowNum " +
                "  FROM oFAC_Process p LEFT JOIN oFAC_Main m ON p.oFAC_ID = m.oFAC_ID " +
                "  WHERE {0} " +
                ") AS T WHERE T.RowNum BETWEEN {1} AND {2}",
                whereSb.ToString(), startRow, endRow);

            DataTable dt = DbHelper.ExecuteDataTable(querySql, pList.ToArray());

            string licDir = Server.MapPath("~/Upload/LicDoc");
            DirectoryInfo dirInfo = new DirectoryInfo(licDir);

            List<Dictionary<string, object>> items = new List<Dictionary<string, object>>();
            for (int i = 0; i < dt.Rows.Count; i++)
            {
                DataRow r = dt.Rows[i];
                var item = new Dictionary<string, object>();
                string oFacId = r["oFAC_ID"] != DBNull.Value ? r["oFAC_ID"].ToString() : "";
                string processId = r["Process_ID"] != DBNull.Value ? r["Process_ID"].ToString() : "";
                string cNo = r["C_NO"] != DBNull.Value ? r["C_NO"].ToString() : "";
                string facName = r["FAC_NAME"] != DBNull.Value ? r["FAC_NAME"].ToString() : "";
                string processName = r["Process_Name"] != DBNull.Value ? r["Process_Name"].ToString() : "";
                string processType = r["Process_Type"] != DBNull.Value ? r["Process_Type"].ToString() : "";
                string processLic = r["Process_Lic"] != DBNull.Value ? r["Process_Lic"].ToString() : "";

                item["OFacId"] = oFacId;
                item["ProcessId"] = processId;
                item["CNo"] = cNo;
                item["FacName"] = facName;
                item["ProcessName"] = processName;
                item["ProcessType"] = processType;
                item["ProcessLic"] = processLic;

                // 日期格式化
                item["StartDate"] = r["Start_Date"] != DBNull.Value ? string.Format("{0:yyyy-MM-dd}", r["Start_Date"]) : "";
                item["EndDate"] = r["End_Date"] != DBNull.Value ? string.Format("{0:yyyy-MM-dd}", r["End_Date"]) : "";
                item["WorkDeadline"] = r["Work_Deadline"] != DBNull.Value ? string.Format("{0:yyyy-MM-dd}", r["Work_Deadline"]) : "";
                item["ContinueDeadline"] = r["Continue_Deadline"] != DBNull.Value ? string.Format("{0:yyyy-MM-dd}", r["Continue_Deadline"]) : "";
                item["UnlockDocDate"] = r["Unlock_DocDate"] != DBNull.Value ? string.Format("{0:yyyy-MM-dd}", r["Unlock_DocDate"]) : "";
                item["UnlockMemo"] = r["Unlock_memo"] != DBNull.Value ? r["Unlock_memo"].ToString() : "";
                item["PMemo"] = r["pMemo"] != DBNull.Value ? r["pMemo"].ToString() : "";

                // 判斷狀態
                bool isUnlocked = r["Unlock_DocDate"] != DBNull.Value;
                bool isExpired = false;
                if (!isUnlocked && r["End_Date"] != DBNull.Value)
                {
                    DateTime eDate;
                    if (DateTime.TryParse(r["End_Date"].ToString(), out eDate))
                    {
                        if (eDate.Date < DateTime.Today)
                        {
                            isExpired = true;
                        }
                    }
                }
                item["IsUnlocked"] = isUnlocked;
                item["IsExpired"] = isExpired;

                // 展延警示 (若小於今日則標註警示)
                bool continueAlert = false;
                if (r["Continue_Deadline"] != DBNull.Value)
                {
                    DateTime cDate;
                    if (DateTime.TryParse(r["Continue_Deadline"].ToString(), out cDate))
                    {
                        if (cDate.Date <= DateTime.Today)
                        {
                            continueAlert = true;
                        }
                    }
                }
                item["ContinueAlert"] = continueAlert;

                // 尋找實體許可證檔案
                string licFile = "";
                string unlockFile = "";
                if (dirInfo.Exists && !string.IsNullOrEmpty(cNo) && !string.IsNullOrEmpty(processId))
                {
                    try
                    {
                        string licPattern = cNo + "-*-" + processId + "-*.pdf";
                        FileInfo[] licFiles = dirInfo.GetFiles(licPattern);
                        if (licFiles != null && licFiles.Length > 0)
                        {
                            licFile = licFiles[0].Name;
                        }

                        string unlockPattern = "解列" + cNo + "-*-" + processId + "-*.pdf";
                        FileInfo[] unlockFiles = dirInfo.GetFiles(unlockPattern);
                        if (unlockFiles != null && unlockFiles.Length > 0)
                        {
                            unlockFile = unlockFiles[0].Name;
                        }
                    }
                    catch
                    {
                    }
                }
                item["LicFileName"] = licFile;
                item["LicFileUrl"] = !string.IsNullOrEmpty(licFile) ? ("../Upload/LicDoc/" + licFile) : "";
                item["UnlockFileName"] = unlockFile;
                item["UnlockFileUrl"] = !string.IsNullOrEmpty(unlockFile) ? ("../Upload/LicDoc/" + unlockFile) : "";

                items.Add(item);
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                Total = total,
                PageIndex = pageIndex,
                PageSize = pageSize,
                Items = items
            }));
        }

        private FilterModel ParseFilter()
        {
            FilterModel m = new FilterModel();
            if (!string.IsNullOrEmpty(Request["mode"])) m.Mode = Request["mode"].Trim();
            if (!string.IsNullOrEmpty(Request["cNo"])) m.CNo = Request["cNo"].Trim();
            if (!string.IsNullOrEmpty(Request["facName"])) m.FacName = Request["facName"].Trim();
            if (!string.IsNullOrEmpty(Request["processName"])) m.ProcessName = Request["processName"].Trim();
            if (!string.IsNullOrEmpty(Request["processLic"])) m.ProcessLic = Request["processLic"].Trim();
            if (!string.IsNullOrEmpty(Request["startDateS"])) m.StartDateS = Request["startDateS"].Trim();
            if (!string.IsNullOrEmpty(Request["startDateE"])) m.StartDateE = Request["startDateE"].Trim();
            if (!string.IsNullOrEmpty(Request["continueDateS"])) m.ContinueDateS = Request["continueDateS"].Trim();
            if (!string.IsNullOrEmpty(Request["continueDateE"])) m.ContinueDateE = Request["continueDateE"].Trim();
            if (!string.IsNullOrEmpty(Request["workDeadline"])) m.WorkDeadline = Request["workDeadline"].Trim();

            int pIdx;
            if (int.TryParse(Request["pageIndex"], out pIdx)) m.PageIndex = pIdx;
            int pSize;
            if (int.TryParse(Request["pageSize"], out pSize)) m.PageSize = pSize;

            return m;
        }

        private void CheckCNo()
        {
            string cNo = Request["cNo"];
            if (string.IsNullOrEmpty(cNo))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "請提供管制編號" }));
                return;
            }

            string sql = "SELECT * FROM oFAC_Main WHERE C_NO = @CNo";
            DataTable dt = DbHelper.ExecuteDataTable(sql, new SqlParameter("@CNo", cNo.Trim()));
            if (dt.Rows.Count > 0)
            {
                Response.Write(json.Serialize(new
                {
                    Success = true,
                    Found = true,
                    OFacId = dt.Rows[0]["oFAC_ID"].ToString(),
                    FacName = dt.Rows[0]["FAC_NAME"].ToString(),
                    CNo = dt.Rows[0]["C_NO"].ToString()
                }));
            }
            else
            {
                Response.Write(json.Serialize(new
                {
                    Success = true,
                    Found = false
                }));
            }
        }

        private void GetProcessDetail()
        {
            string oFacId = Request["oFacId"];
            string processId = Request["processId"];

            if (string.IsNullOrEmpty(oFacId) || string.IsNullOrEmpty(processId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "缺少必要識別參數" }));
                return;
            }

            string sql = "SELECT p.*, m.FAC_NAME, m.C_NO FROM oFAC_Process p LEFT JOIN oFAC_Main m ON p.oFAC_ID = m.oFAC_ID WHERE p.oFAC_ID = @OFacId AND p.Process_ID = @ProcessId";
            DataTable dt = DbHelper.ExecuteDataTable(sql, new SqlParameter("@OFacId", oFacId), new SqlParameter("@ProcessId", processId));
            if (dt.Rows.Count == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "找不到該製程資料" }));
                return;
            }

            DataRow r = dt.Rows[0];
            var detail = new Dictionary<string, object>();
            detail["OFacId"] = r["oFAC_ID"].ToString();
            detail["ProcessId"] = r["Process_ID"].ToString();
            detail["CNo"] = r["C_NO"] != DBNull.Value ? r["C_NO"].ToString() : "";
            detail["FacName"] = r["FAC_NAME"] != DBNull.Value ? r["FAC_NAME"].ToString() : "";
            detail["ProcessName"] = r["Process_Name"] != DBNull.Value ? r["Process_Name"].ToString() : "";
            detail["ProcessType"] = r["Process_Type"] != DBNull.Value ? r["Process_Type"].ToString() : "操作";
            detail["ProcessLic"] = r["Process_Lic"] != DBNull.Value ? r["Process_Lic"].ToString() : "";
            detail["StartDate"] = r["Start_Date"] != DBNull.Value ? string.Format("{0:yyyy-MM-dd}", r["Start_Date"]) : "";
            detail["EndDate"] = r["End_Date"] != DBNull.Value ? string.Format("{0:yyyy-MM-dd}", r["End_Date"]) : "";
            detail["WorkDeadline"] = r["Work_Deadline"] != DBNull.Value ? string.Format("{0:yyyy-MM-dd}", r["Work_Deadline"]) : "";
            detail["ContinueDeadline"] = r["Continue_Deadline"] != DBNull.Value ? string.Format("{0:yyyy-MM-dd}", r["Continue_Deadline"]) : "";
            detail["PMemo"] = r["pMemo"] != DBNull.Value ? r["pMemo"].ToString() : "";

            Response.Write(json.Serialize(new
            {
                Success = true,
                Detail = detail
            }));
        }

        private void SaveProcess()
        {
            string isEditStr = Request["isEdit"];
            bool isEdit = isEditStr == "true" || isEditStr == "1";
            string oFacId = Request["oFacId"] != null ? Request["oFacId"].Trim() : "";
            string cNo = Request["cNo"] != null ? Request["cNo"].Trim() : "";
            string facName = Request["facName"] != null ? Request["facName"].Trim() : "";
            string processId = Request["processId"] != null ? Request["processId"].Trim() : "";
            string processName = Request["processName"] != null ? Request["processName"].Trim() : "";
            string processType = Request["processType"] != null ? Request["processType"].Trim() : "操作";
            string processLic = Request["processLic"] != null ? Request["processLic"].Trim() : "";
            string startDateStr = Request["startDate"] != null ? Request["startDate"].Trim() : "";
            string endDateStr = Request["endDate"] != null ? Request["endDate"].Trim() : "";
            string workDeadlineStr = Request["workDeadline"] != null ? Request["workDeadline"].Trim() : "";
            string continueDeadlineStr = Request["continueDeadline"] != null ? Request["continueDeadline"].Trim() : "";
            string pMemo = Request["pMemo"] != null ? Request["pMemo"].Trim() : "";

            if (string.IsNullOrEmpty(cNo))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "請輸入管制編號" }));
                return;
            }
            if (string.IsNullOrEmpty(processId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "請輸入製程編號" }));
                return;
            }

            DateTime? dtStart = null;
            DateTime tmpDt;
            if (DateTime.TryParse(startDateStr, out tmpDt)) dtStart = tmpDt;

            DateTime? dtEnd = null;
            if (DateTime.TryParse(endDateStr, out tmpDt)) dtEnd = tmpDt;

            DateTime? dtWork = null;
            if (DateTime.TryParse(workDeadlineStr, out tmpDt)) dtWork = tmpDt;

            DateTime? dtContinue = null;
            if (DateTime.TryParse(continueDeadlineStr, out tmpDt)) dtContinue = tmpDt;

            if (!isEdit)
            {
                // 新增模式
                // 1. 若 oFacId 為空，檢查或建立 oFAC_Main
                if (string.IsNullOrEmpty(oFacId))
                {
                    string checkMainSql = "SELECT oFAC_ID, FAC_NAME FROM oFAC_Main WHERE C_NO = @CNo";
                    DataTable dtMain = DbHelper.ExecuteDataTable(checkMainSql, new SqlParameter("@CNo", cNo));
                    if (dtMain.Rows.Count > 0)
                    {
                        oFacId = dtMain.Rows[0]["oFAC_ID"].ToString();
                    }
                    else
                    {
                        if (string.IsNullOrEmpty(facName))
                        {
                            Response.Write(json.Serialize(new { Success = false, Message = "此為新管制編號，請輸入公私場所名稱" }));
                            return;
                        }

                        string prefix = "FAC" + DateTime.Now.ToString("yyyyMMdd");
                        string maxSql = "SELECT TOP 1 oFAC_ID FROM oFAC_Main WHERE oFAC_ID LIKE @Prefix + '%' ORDER BY oFAC_ID DESC";
                        object maxObj = DbHelper.ExecuteScalar(maxSql, new SqlParameter("@Prefix", prefix));
                        int nextNum = 1;
                        if (maxObj != null && maxObj != DBNull.Value)
                        {
                            string maxStr = maxObj.ToString().Replace(prefix, "");
                            int curNum;
                            if (int.TryParse(maxStr, out curNum))
                            {
                                nextNum = curNum + 1;
                            }
                        }
                        oFacId = prefix + nextNum.ToString("00000");

                        string insertMain = "INSERT INTO oFAC_Main (oFAC_ID, C_NO, FAC_NAME) VALUES (@OFacId, @CNo, @FacName)";
                        DbHelper.ExecuteNonQuery(insertMain,
                            new SqlParameter("@OFacId", oFacId),
                            new SqlParameter("@CNo", cNo),
                            new SqlParameter("@FacName", facName));
                    }
                }

                // 2. 檢查 oFAC_Process 是否已存在相同 oFAC_ID 與 Process_ID
                string checkProc = "SELECT COUNT(*) FROM oFAC_Process WHERE oFAC_ID = @OFacId AND Process_ID = @ProcessId";
                int existProc = Convert.ToInt32(DbHelper.ExecuteScalar(checkProc,
                    new SqlParameter("@OFacId", oFacId),
                    new SqlParameter("@ProcessId", processId)));
                if (existProc > 0)
                {
                    Response.Write(json.Serialize(new { Success = false, Message = "該公私場所已存在相同製程編號：" + processId }));
                    return;
                }

                // 3. 寫入 oFAC_Process
                string insertProc = "INSERT INTO oFAC_Process (oFAC_ID, Process_ID, Process_Name, Process_Type, Process_Lic, Start_Date, End_Date, Continue_Deadline, Work_Deadline, pMemo) " +
                                    "VALUES (@OFacId, @ProcessId, @ProcessName, @ProcessType, @ProcessLic, @StartDate, @EndDate, @ContinueDeadline, @WorkDeadline, @PMemo)";
                DbHelper.ExecuteNonQuery(insertProc,
                    new SqlParameter("@OFacId", oFacId),
                    new SqlParameter("@ProcessId", processId),
                    new SqlParameter("@ProcessName", (object)processName ?? DBNull.Value),
                    new SqlParameter("@ProcessType", (object)processType ?? DBNull.Value),
                    new SqlParameter("@ProcessLic", (object)processLic ?? DBNull.Value),
                    new SqlParameter("@StartDate", (object)dtStart ?? DBNull.Value),
                    new SqlParameter("@EndDate", (object)dtEnd ?? DBNull.Value),
                    new SqlParameter("@ContinueDeadline", (object)dtContinue ?? DBNull.Value),
                    new SqlParameter("@WorkDeadline", (object)dtWork ?? DBNull.Value),
                    new SqlParameter("@PMemo", (object)pMemo ?? DBNull.Value));

                Response.Write(json.Serialize(new { Success = true, Message = "製程資料新增成功！" }));
            }
            else
            {
                // 編輯模式
                if (string.IsNullOrEmpty(oFacId) || string.IsNullOrEmpty(processId))
                {
                    Response.Write(json.Serialize(new { Success = false, Message = "缺少製程識別碼，無法更新" }));
                    return;
                }

                string updateProc = "UPDATE oFAC_Process SET Process_Name = @ProcessName, Process_Type = @ProcessType, Process_Lic = @ProcessLic, " +
                                    "Start_Date = @StartDate, End_Date = @EndDate, Continue_Deadline = @ContinueDeadline, Work_Deadline = @WorkDeadline, pMemo = @PMemo " +
                                    "WHERE oFAC_ID = @OFacId AND Process_ID = @ProcessId";
                DbHelper.ExecuteNonQuery(updateProc,
                    new SqlParameter("@ProcessName", (object)processName ?? DBNull.Value),
                    new SqlParameter("@ProcessType", (object)processType ?? DBNull.Value),
                    new SqlParameter("@ProcessLic", (object)processLic ?? DBNull.Value),
                    new SqlParameter("@StartDate", (object)dtStart ?? DBNull.Value),
                    new SqlParameter("@EndDate", (object)dtEnd ?? DBNull.Value),
                    new SqlParameter("@ContinueDeadline", (object)dtContinue ?? DBNull.Value),
                    new SqlParameter("@WorkDeadline", (object)dtWork ?? DBNull.Value),
                    new SqlParameter("@PMemo", (object)pMemo ?? DBNull.Value),
                    new SqlParameter("@OFacId", oFacId),
                    new SqlParameter("@ProcessId", processId));

                Response.Write(json.Serialize(new { Success = true, Message = "製程資料更新成功！" }));
            }
        }

        private void GetUploadHistory()
        {
            string oFacId = Request["oFacId"];
            string processId = Request["processId"];

            if (string.IsNullOrEmpty(oFacId) || string.IsNullOrEmpty(processId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "缺少必要識別參數" }));
                return;
            }

            string sql = "SELECT f.*, ISNULL(u.Name, f.UploadUser) as UploadUserName " +
                         "FROM oFAC_File f LEFT JOIN UserAcc u ON f.UploadUser = u.UserID " +
                         "WHERE f.oFAC_ID = @OFacId AND f.Process_ID = @ProcessId ORDER BY f.UploadDate DESC";

            DataTable dt = DbHelper.ExecuteDataTable(sql, new SqlParameter("@OFacId", oFacId), new SqlParameter("@ProcessId", processId));
            List<Dictionary<string, object>> list = new List<Dictionary<string, object>>();

            for (int i = 0; i < dt.Rows.Count; i++)
            {
                DataRow r = dt.Rows[i];
                var row = new Dictionary<string, object>();
                string fileName = r["UploadFileName"] != DBNull.Value ? r["UploadFileName"].ToString() : "";
                row["UploadDate"] = r["UploadDate"] != DBNull.Value ? string.Format("{0:yyyy-MM-dd HH:mm}", r["UploadDate"]) : "";
                row["UploadUserName"] = r["UploadUserName"] != DBNull.Value ? r["UploadUserName"].ToString() : "";
                row["UploadFileName"] = fileName;
                row["IsDeleted"] = fileName.StartsWith("刪");
                row["FileUrl"] = fileName.StartsWith("刪") ? ("../Upload/LicDoc/History/" + fileName) : ("../Upload/LicDoc/" + fileName);
                list.Add(row);
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                Items = list
            }));
        }

        private void UploadLicFile()
        {
            EnsureDirectories();
            string oFacId = Request["oFacId"];
            string processId = Request["processId"];

            if (string.IsNullOrEmpty(oFacId) || string.IsNullOrEmpty(processId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "缺少製程識別碼" }));
                return;
            }

            if (Request.Files.Count == 0 || Request.Files[0].ContentLength == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "請選取要上傳的 PDF 檔案" }));
                return;
            }

            HttpPostedFile file = Request.Files[0];
            string ext = Path.GetExtension(file.FileName).ToLower();
            if (ext != ".pdf")
            {
                Response.Write(json.Serialize(new { Success = false, Message = "僅支援 PDF 檔案上傳格式" }));
                return;
            }

            // 查詢詳細資訊
            string sqlProc = "SELECT p.*, m.C_NO, m.FAC_NAME FROM oFAC_Process p LEFT JOIN oFAC_Main m ON p.oFAC_ID = m.oFAC_ID WHERE p.oFAC_ID = @OFacId AND p.Process_ID = @ProcessId";
            DataTable dtProc = DbHelper.ExecuteDataTable(sqlProc, new SqlParameter("@OFacId", oFacId), new SqlParameter("@ProcessId", processId));
            if (dtProc.Rows.Count == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "查無此製程" }));
                return;
            }

            string cNo = dtProc.Rows[0]["C_NO"].ToString();
            string lic = dtProc.Rows[0]["Process_Lic"].ToString();
            lic = lic.Replace("新北市環操證字第", "操").Replace("新北市環設證字第", "設").Replace("號", "");
            string pName = dtProc.Rows[0]["Process_Name"].ToString();
            if (pName.Length > 4)
            {
                pName = pName.Substring(0, pName.Length - 4) + "許可證";
            }
            else
            {
                pName = pName + "許可證";
            }

            string timeStamp = DateTime.Now.ToString("yyyyMMddHHmmss");
            string newFileName = string.Format("{0}-{1}-{2}-{3}-{4}.pdf", cNo, lic, processId, pName, timeStamp);

            string licDir = Server.MapPath("~/Upload/LicDoc");
            string historyDir = Path.Combine(licDir, "History");
            DirectoryInfo dir = new DirectoryInfo(licDir);

            // 搜尋既有檔案並移入 History
            string searchPattern = string.Format("{0}-*-{1}-*.pdf", cNo, processId);
            FileInfo[] oldFiles = dir.GetFiles(searchPattern);
            if (oldFiles != null && oldFiles.Length > 0)
            {
                for (int i = 0; i < oldFiles.Length; i++)
                {
                    FileInfo oldF = oldFiles[i];
                    string backupName = string.Format("刪{0}_{1}", DateTime.Now.ToString("yyyyMMddHHmmss"), oldF.Name);
                    string destPath = Path.Combine(historyDir, backupName);
                    oldF.MoveTo(destPath);

                    string updateSql = "UPDATE oFAC_File SET UploadFileName = @BackupName WHERE UploadFileName = @OldName";
                    DbHelper.ExecuteNonQuery(updateSql, new SqlParameter("@BackupName", backupName), new SqlParameter("@OldName", oldF.Name));
                }
            }

            // 儲存新檔
            string savePath = Path.Combine(licDir, newFileName);
            file.SaveAs(savePath);

            // 寫入 oFAC_File
            string userName = GetCurrentUserName();
            string insertSql = "INSERT INTO oFAC_File (oFAC_ID, Process_ID, UploadDate, UploadFileName, UploadUser) VALUES (@OFacId, @ProcessId, GETDATE(), @FileName, @User)";
            DbHelper.ExecuteNonQuery(insertSql,
                new SqlParameter("@OFacId", oFacId),
                new SqlParameter("@ProcessId", processId),
                new SqlParameter("@FileName", newFileName),
                new SqlParameter("@User", userName));

            Response.Write(json.Serialize(new
            {
                Success = true,
                Message = "許可證檔案上傳成功！",
                FileName = newFileName,
                FileUrl = "../Upload/LicDoc/" + newFileName
            }));
        }

        private void GetUnlockDetail()
        {
            EnsureDirectories();
            string oFacId = Request["oFacId"];
            string processId = Request["processId"];

            if (string.IsNullOrEmpty(oFacId) || string.IsNullOrEmpty(processId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "缺少必要識別參數" }));
                return;
            }

            string sql = "SELECT p.*, m.FAC_NAME, m.C_NO FROM oFAC_Process p LEFT JOIN oFAC_Main m ON p.oFAC_ID = m.oFAC_ID WHERE p.oFAC_ID = @OFacId AND p.Process_ID = @ProcessId";
            DataTable dt = DbHelper.ExecuteDataTable(sql, new SqlParameter("@OFacId", oFacId), new SqlParameter("@ProcessId", processId));
            if (dt.Rows.Count == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "找不到該製程資料" }));
                return;
            }

            DataRow r = dt.Rows[0];
            string cNo = r["C_NO"] != DBNull.Value ? r["C_NO"].ToString() : "";
            string docDate = r["Unlock_DocDate"] != DBNull.Value ? string.Format("{0:yyyy-MM-dd}", r["Unlock_DocDate"]) : "";
            string memo = r["Unlock_memo"] != DBNull.Value ? r["Unlock_memo"].ToString() : "";

            string unlockFile = "";
            string licDir = Server.MapPath("~/Upload/LicDoc");
            DirectoryInfo dir = new DirectoryInfo(licDir);
            if (dir.Exists && !string.IsNullOrEmpty(cNo) && !string.IsNullOrEmpty(processId))
            {
                try
                {
                    string searchPattern = "解列" + cNo + "-*-" + processId + "-*.pdf";
                    FileInfo[] files = dir.GetFiles(searchPattern);
                    if (files != null && files.Length > 0)
                    {
                        unlockFile = files[0].Name;
                    }
                }
                catch
                {
                }
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                CNo = cNo,
                FacName = r["FAC_NAME"] != DBNull.Value ? r["FAC_NAME"].ToString() : "",
                ProcessId = processId,
                ProcessName = r["Process_Name"] != DBNull.Value ? r["Process_Name"].ToString() : "",
                UnlockDocDate = docDate,
                UnlockMemo = memo,
                UnlockFileName = unlockFile,
                UnlockFileUrl = !string.IsNullOrEmpty(unlockFile) ? ("../Upload/LicDoc/" + unlockFile) : ""
            }));
        }

        private void SaveUnlock()
        {
            EnsureDirectories();
            string oFacId = Request["oFacId"];
            string processId = Request["processId"];
            string unlockDocDateStr = Request["unlockDocDate"];
            string unlockMemo = Request["unlockMemo"];

            if (string.IsNullOrEmpty(oFacId) || string.IsNullOrEmpty(processId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "缺少必要識別參數" }));
                return;
            }

            DateTime dtDoc;
            if (!DateTime.TryParse(unlockDocDateStr, out dtDoc))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "請輸入合法的解列公文日期" }));
                return;
            }

            // 更新 oFAC_Process
            string updateSql = "UPDATE oFAC_Process SET Unlock_DocDate = @DocDate, Unlock_memo = @Memo WHERE oFAC_ID = @OFacId AND Process_ID = @ProcessId";
            DbHelper.ExecuteNonQuery(updateSql,
                new SqlParameter("@DocDate", dtDoc),
                new SqlParameter("@Memo", (object)unlockMemo ?? DBNull.Value),
                new SqlParameter("@OFacId", oFacId),
                new SqlParameter("@ProcessId", processId));

            // 若有附加公文檔案
            if (Request.Files.Count > 0 && Request.Files[0].ContentLength > 0)
            {
                HttpPostedFile file = Request.Files[0];
                string ext = Path.GetExtension(file.FileName).ToLower();
                if (ext != ".pdf")
                {
                    Response.Write(json.Serialize(new { Success = false, Message = "解列公文僅支援 PDF 格式" }));
                    return;
                }

                string sqlProc = "SELECT p.*, m.C_NO, m.FAC_NAME FROM oFAC_Process p LEFT JOIN oFAC_Main m ON p.oFAC_ID = m.oFAC_ID WHERE p.oFAC_ID = @OFacId AND p.Process_ID = @ProcessId";
                DataTable dtProc = DbHelper.ExecuteDataTable(sqlProc, new SqlParameter("@OFacId", oFacId), new SqlParameter("@ProcessId", processId));
                if (dtProc.Rows.Count > 0)
                {
                    string cNo = dtProc.Rows[0]["C_NO"].ToString();
                    string lic = dtProc.Rows[0]["Process_Lic"].ToString();
                    lic = lic.Replace("新北市環操證字第", "操").Replace("新北市環設證字第", "設").Replace("號", "");
                    string pName = dtProc.Rows[0]["Process_Name"].ToString();
                    if (pName.Length > 4)
                    {
                        pName = pName.Substring(0, pName.Length - 4) + "許可證";
                    }
                    else
                    {
                        pName = pName + "許可證";
                    }

                    string timeStamp = DateTime.Now.ToString("yyyyMMddHHmmss");
                    string newFileName = string.Format("解列{0}-{1}-{2}-{3}-{4}.pdf", cNo, lic, processId, pName, timeStamp);

                    string licDir = Server.MapPath("~/Upload/LicDoc");
                    string historyDir = Path.Combine(licDir, "History");
                    DirectoryInfo dir = new DirectoryInfo(licDir);

                    string searchPattern = string.Format("解列{0}-*-{1}-*.pdf", cNo, processId);
                    FileInfo[] oldFiles = dir.GetFiles(searchPattern);
                    if (oldFiles != null && oldFiles.Length > 0)
                    {
                        for (int i = 0; i < oldFiles.Length; i++)
                        {
                            FileInfo oldF = oldFiles[i];
                            string backupName = string.Format("刪{0}_{1}", DateTime.Now.ToString("yyyyMMddHHmmss"), oldF.Name);
                            string destPath = Path.Combine(historyDir, backupName);
                            oldF.MoveTo(destPath);

                            string updSql = "UPDATE oFAC_File SET UploadFileName = @BackupName WHERE UploadFileName = @OldName";
                            DbHelper.ExecuteNonQuery(updSql, new SqlParameter("@BackupName", backupName), new SqlParameter("@OldName", oldF.Name));
                        }
                    }

                    string savePath = Path.Combine(licDir, newFileName);
                    file.SaveAs(savePath);

                    string userName = GetCurrentUserName();
                    string insertSql = "INSERT INTO oFAC_File (oFAC_ID, Process_ID, UploadDate, UploadFileName, UploadUser) VALUES (@OFacId, @ProcessId, GETDATE(), @FileName, @User)";
                    DbHelper.ExecuteNonQuery(insertSql,
                        new SqlParameter("@OFacId", oFacId),
                        new SqlParameter("@ProcessId", processId),
                        new SqlParameter("@FileName", newFileName),
                        new SqlParameter("@User", userName));
                }
            }

            Response.Write(json.Serialize(new { Success = true, Message = "解列設定完成！" }));
        }

        private void HandleExportExcel()
        {
            FilterModel filter = ParseFilter();

            List<SqlParameter> pList = new List<SqlParameter>();
            StringBuilder whereSb = new StringBuilder();

            if (filter.Mode == "valid")
            {
                whereSb.Append(" (p.Unlock_DocDate IS NULL AND (p.End_Date >= CAST(GETDATE() AS DATE) OR p.End_Date IS NULL)) ");
            }
            else if (filter.Mode == "expired")
            {
                whereSb.Append(" (p.Unlock_DocDate IS NULL AND p.End_Date < CAST(GETDATE() AS DATE)) ");
            }
            else if (filter.Mode == "unlocked")
            {
                whereSb.Append(" (p.Unlock_DocDate IS NOT NULL) ");
            }
            else
            {
                whereSb.Append(" (1=1) ");
            }

            if (!string.IsNullOrEmpty(filter.CNo))
            {
                whereSb.Append(" AND m.C_NO LIKE '%' + @CNo + '%' ");
                pList.Add(new SqlParameter("@CNo", filter.CNo.Trim()));
            }
            if (!string.IsNullOrEmpty(filter.FacName))
            {
                whereSb.Append(" AND m.FAC_NAME LIKE '%' + @FacName + '%' ");
                pList.Add(new SqlParameter("@FacName", filter.FacName.Trim()));
            }
            if (!string.IsNullOrEmpty(filter.ProcessName))
            {
                whereSb.Append(" AND p.Process_Name LIKE '%' + @ProcessName + '%' ");
                pList.Add(new SqlParameter("@ProcessName", filter.ProcessName.Trim()));
            }
            if (!string.IsNullOrEmpty(filter.ProcessLic))
            {
                whereSb.Append(" AND p.Process_Lic LIKE '%' + @ProcessLic + '%' ");
                pList.Add(new SqlParameter("@ProcessLic", filter.ProcessLic.Trim()));
            }

            DateTime dtS;
            if (DateTime.TryParse(filter.StartDateS, out dtS))
            {
                whereSb.Append(" AND p.End_Date >= @StartDateS ");
                pList.Add(new SqlParameter("@StartDateS", dtS));
            }
            DateTime dtE;
            if (DateTime.TryParse(filter.StartDateE, out dtE))
            {
                whereSb.Append(" AND p.Start_Date <= @StartDateE ");
                pList.Add(new SqlParameter("@StartDateE", dtE));
            }
            DateTime dtCS;
            if (DateTime.TryParse(filter.ContinueDateS, out dtCS))
            {
                whereSb.Append(" AND p.Continue_Deadline >= @ContinueDateS ");
                pList.Add(new SqlParameter("@ContinueDateS", dtCS));
            }
            DateTime dtCE;
            if (DateTime.TryParse(filter.ContinueDateE, out dtCE))
            {
                whereSb.Append(" AND p.Continue_Deadline <= @ContinueDateE ");
                pList.Add(new SqlParameter("@ContinueDateE", dtCE));
            }
            if (filter.WorkDeadline == "Y")
            {
                whereSb.Append(" AND p.Work_Deadline IS NOT NULL ");
            }
            else if (filter.WorkDeadline == "N")
            {
                whereSb.Append(" AND p.Work_Deadline IS NULL ");
            }

            string sql = "SELECT p.*, m.FAC_NAME, m.C_NO FROM oFAC_Process p LEFT JOIN oFAC_Main m ON p.oFAC_ID = m.oFAC_ID WHERE " + whereSb.ToString() + " ORDER BY m.C_NO ASC, p.Process_ID ASC";
            DataTable dt = DbHelper.ExecuteDataTable(sql, pList.ToArray());

            HSSFWorkbook workbook = new HSSFWorkbook();
            ISheet sheet = workbook.CreateSheet("許可證清單");

            // 標題樣式
            ICellStyle headerStyle = workbook.CreateCellStyle();
            IFont headerFont = workbook.CreateFont();
            headerFont.FontName = "微軟正黑體";
            headerFont.FontHeightInPoints = 11.0;
            headerFont.IsBold = true;
            headerStyle.SetFont(headerFont);
            headerStyle.Alignment = HorizontalAlignment.Center;
            headerStyle.VerticalAlignment = VerticalAlignment.Center;
            headerStyle.FillForegroundColor = NPOI.HSSF.Util.HSSFColor.Grey25Percent.Index;
            headerStyle.FillPattern = FillPattern.SolidForeground;
            headerStyle.BorderBottom = NPOI.SS.UserModel.BorderStyle.Thin;
            headerStyle.BorderTop = NPOI.SS.UserModel.BorderStyle.Thin;
            headerStyle.BorderLeft = NPOI.SS.UserModel.BorderStyle.Thin;
            headerStyle.BorderRight = NPOI.SS.UserModel.BorderStyle.Thin;

            // 內文樣式
            ICellStyle dataStyle = workbook.CreateCellStyle();
            IFont dataFont = workbook.CreateFont();
            dataFont.FontName = "微軟正黑體";
            dataFont.FontHeightInPoints = 10.0;
            dataStyle.SetFont(dataFont);
            dataStyle.VerticalAlignment = VerticalAlignment.Center;
            dataStyle.BorderBottom = NPOI.SS.UserModel.BorderStyle.Thin;
            dataStyle.BorderTop = NPOI.SS.UserModel.BorderStyle.Thin;
            dataStyle.BorderLeft = NPOI.SS.UserModel.BorderStyle.Thin;
            dataStyle.BorderRight = NPOI.SS.UserModel.BorderStyle.Thin;

            string[] headers = new string[]
            {
                "管制編號", "公私場所名稱", "製程編號", "製程名稱", "許可證類別",
                "許可證字號", "有效起日", "有效迄日", "工務期限", "展延期限", "解列日期", "備註"
            };

            IRow rowHeader = sheet.CreateRow(0);
            rowHeader.HeightInPoints = 26;
            for (int h = 0; h < headers.Length; h++)
            {
                ICell c = rowHeader.CreateCell(h);
                c.SetCellValue(headers[h]);
                c.CellStyle = headerStyle;
            }

            for (int r = 0; r < dt.Rows.Count; r++)
            {
                DataRow dr = dt.Rows[r];
                IRow row = sheet.CreateRow(r + 1);
                row.HeightInPoints = 20;

                string cNo = dr["C_NO"] != DBNull.Value ? dr["C_NO"].ToString() : "";
                string facName = dr["FAC_NAME"] != DBNull.Value ? dr["FAC_NAME"].ToString() : "";
                string pId = dr["Process_ID"] != DBNull.Value ? dr["Process_ID"].ToString() : "";
                string pName = dr["Process_Name"] != DBNull.Value ? dr["Process_Name"].ToString() : "";
                string pType = dr["Process_Type"] != DBNull.Value ? dr["Process_Type"].ToString() : "";
                string pLic = dr["Process_Lic"] != DBNull.Value ? dr["Process_Lic"].ToString() : "";
                string sDate = dr["Start_Date"] != DBNull.Value ? string.Format("{0:yyyy-MM-dd}", dr["Start_Date"]) : "";
                string eDate = dr["End_Date"] != DBNull.Value ? string.Format("{0:yyyy-MM-dd}", dr["End_Date"]) : "";
                string wDate = dr["Work_Deadline"] != DBNull.Value ? string.Format("{0:yyyy-MM-dd}", dr["Work_Deadline"]) : "";
                string cDate = dr["Continue_Deadline"] != DBNull.Value ? string.Format("{0:yyyy-MM-dd}", dr["Continue_Deadline"]) : "";
                string uDate = dr["Unlock_DocDate"] != DBNull.Value ? string.Format("{0:yyyy-MM-dd}", dr["Unlock_DocDate"]) : "";
                string memo = dr["pMemo"] != DBNull.Value ? dr["pMemo"].ToString() : "";

                string[] values = new string[]
                {
                    cNo, facName, pId, pName, pType, pLic, sDate, eDate, wDate, cDate, uDate, memo
                };

                for (int cIdx = 0; cIdx < values.Length; cIdx++)
                {
                    ICell cell = row.CreateCell(cIdx);
                    cell.SetCellValue(values[cIdx]);
                    cell.CellStyle = dataStyle;
                }
            }

            // 自動適應欄寬 (約值)
            for (int i = 0; i < headers.Length; i++)
            {
                sheet.SetColumnWidth(i, 18 * 256);
            }
            sheet.SetColumnWidth(1, 30 * 256); // 場所名稱放寬
            sheet.SetColumnWidth(3, 24 * 256); // 製程名稱
            sheet.SetColumnWidth(5, 26 * 256); // 許可證字號

            Response.Clear();
            Response.ContentType = "application/vnd.ms-excel";
            string filename = "許可證清單_" + DateTime.Now.ToString("yyyyMMddHHmmss") + ".xls";
            Response.AddHeader("Content-Disposition", "attachment;filename=" + HttpUtility.UrlEncode(filename, Encoding.UTF8));

            using (MemoryStream ms = new MemoryStream())
            {
                workbook.Write(ms);
                Response.BinaryWrite(ms.ToArray());
            }

            try
            {
                Response.End();
            }
            catch (System.Threading.ThreadAbortException)
            {
            }
        }
    }
}
