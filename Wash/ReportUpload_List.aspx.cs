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
using NPOI.HSSF.Util;
using NPOI.SS.UserModel;
using NPOI.SS.Util;
using NTPC_FEC.Helpers;
using NTPC_FEC.Models;
using NTPC_FEC.Services;

namespace NTPC_FEC.Wash
{
    public partial class ReportUpload_List : Page
    {
        private JavaScriptSerializer json;

        public ReportUpload_List()
        {
            json = new JavaScriptSerializer();
            json.MaxJsonLength = int.MaxValue;
        }

        public class SearchFilterModel
        {
            public string FacId { get; set; }
            public string Year { get; set; }
            public string Month { get; set; }
            public string Keyword { get; set; }
            public int PageIndex { get; set; }
            public int PageSize { get; set; }

            public SearchFilterModel()
            {
                FacId = "";
                Year = "";
                Month = "";
                Keyword = "";
                PageIndex = 1;
                PageSize = 20;
            }
        }

        public class ReportItemModel
        {
            public int PID { get; set; }
            public string FacId { get; set; }
            public string FacName { get; set; }
            public int UploadYear { get; set; }
            public int UploadMonth { get; set; }
            public string UploadDate { get; set; }
            public string UploadUser { get; set; }
            public string UploadUserName { get; set; }
            public string FileName { get; set; }
            public bool FileExists { get; set; }
            public string FileSizeStr { get; set; }
            public string FileExt { get; set; }
            public string DownloadUrl { get; set; }
        }

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

                if (string.Equals(action, "download", StringComparison.OrdinalIgnoreCase))
                {
                    try
                    {
                        DownloadReport();
                    }
                    catch (System.Threading.ThreadAbortException)
                    {
                    }
                    catch (Exception ex)
                    {
                        Response.ContentType = "text/html; charset=utf-8";
                        Response.Write("<script>alert('檔案下載失敗：" + HttpUtility.JavaScriptStringEncode(ex.Message) + "'); window.close();</script>");
                    }
                    return;
                }

                if (string.Equals(action, "upload", StringComparison.OrdinalIgnoreCase))
                {
                    Response.Clear();
                    Response.ContentType = "application/json; charset=utf-8";
                    try
                    {
                        UploadReport();
                    }
                    catch (Exception ex)
                    {
                        Response.Write(json.Serialize(new { Success = false, Message = ex.Message }));
                    }
                    try
                    {
                        Response.End();
                    }
                    catch (System.Threading.ThreadAbortException)
                    {
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
                    Response.Write(json.Serialize(new { Success = false, Message = ex.Message }));
                }

                try
                {
                    Response.End();
                }
                catch (System.Threading.ThreadAbortException)
                {
                }
                return;
            }

            // 一般頁面存取：檢查是否登入
            string uid = GetCurrentUserId();
            if (string.IsNullOrEmpty(uid))
            {
                Response.Redirect("~/Default.aspx", true);
            }
        }

        private string GetCurrentUserId()
        {
            if (Session["LoginUser"] != null && !string.IsNullOrEmpty(Session["LoginUser"].ToString()))
            {
                return Session["LoginUser"].ToString().Trim();
            }
            if (User != null && User.Identity != null && !string.IsNullOrEmpty(User.Identity.Name))
            {
                return User.Identity.Name.Trim();
            }
            return "";
        }

        private void GetUserAuthInfo(out string userId, out string userName, out bool isAdmin, out string userFacId)
        {
            userId = GetCurrentUserId();
            userName = "";
            isAdmin = false;
            userFacId = "";

            if (string.IsNullOrEmpty(userId))
            {
                return;
            }

            UserAccount acc = Session["UserAccount"] as UserAccount;
            if (acc != null)
            {
                userName = !string.IsNullOrEmpty(acc.Name) ? acc.Name : acc.UserID;
                userFacId = acc.FacID != null ? acc.FacID.Trim() : "";
                isAdmin = MenuService.CheckLicense(acc.Lic, 9);
            }
            else
            {
                string sql = "SELECT UserID, Name, LIC, LIC2, FAC_ID FROM UserAcc WHERE UserID = @UserID";
                SqlParameter[] p = new SqlParameter[]
                {
                    new SqlParameter("@UserID", SqlDbType.VarChar) { Value = userId }
                };
                DataTable dt = DbHelper.ExecuteDataTable(sql, p);
                if (dt.Rows.Count > 0)
                {
                    DataRow r = dt.Rows[0];
                    userName = (r["Name"] != DBNull.Value && !string.IsNullOrEmpty(r["Name"].ToString())) ? r["Name"].ToString().Trim() : userId;
                    userFacId = (r["FAC_ID"] != DBNull.Value) ? r["FAC_ID"].ToString().Trim() : "";
                    long lic = 0;
                    if (r["LIC"] != DBNull.Value)
                    {
                        long.TryParse(r["LIC"].ToString(), out lic);
                    }
                    isAdmin = MenuService.CheckLicense(lic, 9);
                }
            }
        }

        private void HandleAjaxAction(string action)
        {
            switch (action.ToLower())
            {
                case "getinit":
                    GetInitData();
                    break;
                case "getcounts":
                    GetCounts();
                    break;
                case "getlist":
                    GetList();
                    break;
                case "deletereport":
                    DeleteReport();
                    break;
                case "checkexists":
                    CheckExists();
                    break;
                default:
                    Response.Write(json.Serialize(new { Success = false, Message = "未知的操作指令：" + action }));
                    break;
            }
        }

        // 1. 初始化資料 (目前使用者、場所列表、年度列表)
        private void GetInitData()
        {
            string userId, userName, userFacId;
            bool isAdmin;
            GetUserAuthInfo(out userId, out userName, out isAdmin, out userFacId);

            if (string.IsNullOrEmpty(userId))
            {
                Response.Write(json.Serialize(new { Success = false, NeedLogin = true, Message = "尚未登入或登入逾時，請重新登入！" }));
                return;
            }

            var facList = new List<object>();
            if (isAdmin)
            {
                string sqlFac = @"
                    SELECT f.FAC_ID, f.FAC_NAME,
                           (SELECT COUNT(*) FROM RoadWash_UploadHis h WHERE h.FAC_ID = f.FAC_ID) AS HisCount
                    FROM FAC_Main f
                    WHERE f.FAC_ID IS NOT NULL AND LTRIM(RTRIM(f.FAC_ID)) <> ''
                    ORDER BY HisCount DESC, f.FAC_NAME";
                DataTable dtFac = DbHelper.ExecuteDataTable(sqlFac);
                foreach (DataRow row in dtFac.Rows)
                {
                    facList.Add(new
                    {
                        FacId = row["FAC_ID"].ToString().Trim(),
                        FacName = row["FAC_NAME"] != DBNull.Value ? row["FAC_NAME"].ToString().Trim() : row["FAC_ID"].ToString().Trim(),
                        HisCount = Convert.ToInt32(row["HisCount"])
                    });
                }
            }
            else
            {
                string sqlFac = "SELECT FAC_ID, FAC_NAME FROM FAC_Main WHERE FAC_ID = @FAC_ID";
                SqlParameter[] pFac = new SqlParameter[]
                {
                    new SqlParameter("@FAC_ID", SqlDbType.VarChar) { Value = userFacId }
                };
                DataTable dtFac = DbHelper.ExecuteDataTable(sqlFac, pFac);
                if (dtFac.Rows.Count > 0)
                {
                    DataRow row = dtFac.Rows[0];
                    facList.Add(new
                    {
                        FacId = row["FAC_ID"].ToString().Trim(),
                        FacName = row["FAC_NAME"] != DBNull.Value ? row["FAC_NAME"].ToString().Trim() : row["FAC_ID"].ToString().Trim(),
                        HisCount = 0
                    });
                }
                else if (!string.IsNullOrEmpty(userFacId))
                {
                    facList.Add(new
                    {
                        FacId = userFacId,
                        FacName = "本廠 (" + userFacId + ")",
                        HisCount = 0
                    });
                }
            }

            // 年度清單 (民國年：當前年前後延伸)
            var yearList = new List<object>();
            int currentRocYear = DateTime.Now.Year - 1911;
            for (int y = currentRocYear; y >= currentRocYear - 5; y--)
            {
                yearList.Add(new
                {
                    Year = y,
                    Text = string.Format("{0} 年度 (民國 {0} 年)", y)
                });
            }

            // 預設申報月份 (上一個月)
            int defaultMonth = DateTime.Now.Month - 1;
            int defaultYear = currentRocYear;
            if (defaultMonth <= 0)
            {
                defaultMonth = 12;
                defaultYear = currentRocYear - 1;
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                Data = new
                {
                    UserId = userId,
                    UserName = userName,
                    IsAdmin = isAdmin,
                    UserFacId = userFacId,
                    FacList = facList,
                    YearList = yearList,
                    DefaultYear = defaultYear,
                    DefaultMonth = defaultMonth
                }
            }));
        }

        // 2. 統計總覽指標
        private void GetCounts()
        {
            string userId, userName, userFacId;
            bool isAdmin;
            GetUserAuthInfo(out userId, out userName, out isAdmin, out userFacId);

            int currentRocYear = DateTime.Now.Year - 1911;
            int currentMonth = DateTime.Now.Month;

            string sql;
            List<SqlParameter> pList = new List<SqlParameter>();

            if (isAdmin)
            {
                sql = @"
                    SELECT 
                        COUNT(*) AS TotalCount,
                        SUM(CASE WHEN uploadyear = @CurYear THEN 1 ELSE 0 END) AS CurYearCount,
                        SUM(CASE WHEN uploadyear = @CurYear AND uploadmonth = @CurMonth THEN 1 ELSE 0 END) AS CurMonthCount,
                        COUNT(DISTINCT FAC_ID) AS FacCount
                    FROM RoadWash_UploadHis";
            }
            else
            {
                sql = @"
                    SELECT 
                        COUNT(*) AS TotalCount,
                        SUM(CASE WHEN uploadyear = @CurYear THEN 1 ELSE 0 END) AS CurYearCount,
                        SUM(CASE WHEN uploadyear = @CurYear AND uploadmonth = @CurMonth THEN 1 ELSE 0 END) AS CurMonthCount,
                        COUNT(DISTINCT uploadyear) AS FacCount
                    FROM RoadWash_UploadHis
                    WHERE FAC_ID = @FAC_ID";
                pList.Add(new SqlParameter("@FAC_ID", SqlDbType.VarChar) { Value = userFacId });
            }

            pList.Add(new SqlParameter("@CurYear", SqlDbType.Int) { Value = currentRocYear });
            pList.Add(new SqlParameter("@CurMonth", SqlDbType.Int) { Value = currentMonth });

            DataTable dt = DbHelper.ExecuteDataTable(sql, pList.ToArray());
            int totalCount = 0;
            int curYearCount = 0;
            int curMonthCount = 0;
            int facCount = 0;

            if (dt.Rows.Count > 0)
            {
                DataRow r = dt.Rows[0];
                if (r["TotalCount"] != DBNull.Value) totalCount = Convert.ToInt32(r["TotalCount"]);
                if (r["CurYearCount"] != DBNull.Value) curYearCount = Convert.ToInt32(r["CurYearCount"]);
                if (r["CurMonthCount"] != DBNull.Value) curMonthCount = Convert.ToInt32(r["CurMonthCount"]);
                if (r["FacCount"] != DBNull.Value) facCount = Convert.ToInt32(r["FacCount"]);
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                Data = new
                {
                    TotalCount = totalCount,
                    CurYearCount = curYearCount,
                    CurMonthCount = curMonthCount,
                    FacCount = facCount,
                    CurYear = currentRocYear,
                    CurMonth = currentMonth
                }
            }));
        }

        // 3. 取得洗掃月報清單 (支援多條件篩選與分頁)
        private void GetList()
        {
            string userId, userName, userFacId;
            bool isAdmin;
            GetUserAuthInfo(out userId, out userName, out isAdmin, out userFacId);

            SearchFilterModel filter = ParseFilter();

            StringBuilder sbWhere = new StringBuilder(" WHERE 1=1 ");
            List<SqlParameter> pList = new List<SqlParameter>();

            if (!isAdmin)
            {
                sbWhere.Append(" AND h.FAC_ID = @UserFacId ");
                pList.Add(new SqlParameter("@UserFacId", SqlDbType.VarChar) { Value = userFacId });
            }
            else if (!string.IsNullOrEmpty(filter.FacId))
            {
                sbWhere.Append(" AND h.FAC_ID = @FilterFacId ");
                pList.Add(new SqlParameter("@FilterFacId", SqlDbType.VarChar) { Value = filter.FacId.Trim() });
            }

            if (!string.IsNullOrEmpty(filter.Year))
            {
                int y = 0;
                if (int.TryParse(filter.Year, out y))
                {
                    sbWhere.Append(" AND h.uploadyear = @Year ");
                    pList.Add(new SqlParameter("@Year", SqlDbType.Int) { Value = y });
                }
            }

            if (!string.IsNullOrEmpty(filter.Month))
            {
                int m = 0;
                if (int.TryParse(filter.Month, out m))
                {
                    sbWhere.Append(" AND h.uploadmonth = @Month ");
                    pList.Add(new SqlParameter("@Month", SqlDbType.Int) { Value = m });
                }
            }

            if (!string.IsNullOrEmpty(filter.Keyword))
            {
                sbWhere.Append(" AND (u.Name LIKE @Kw OR h.uploaduser LIKE @Kw OR h.FileName LIKE @Kw OR f.FAC_NAME LIKE @Kw) ");
                pList.Add(new SqlParameter("@Kw", SqlDbType.NVarChar) { Value = "%" + filter.Keyword.Trim() + "%" });
            }

            // 總筆數
            string countSql = string.Format(@"
                SELECT COUNT(*) 
                FROM RoadWash_UploadHis h
                LEFT JOIN FAC_Main f ON h.FAC_ID = f.FAC_ID
                LEFT JOIN UserAcc u ON h.uploaduser = u.UserID
                {0}", sbWhere.ToString());

            int totalRows = Convert.ToInt32(DbHelper.ExecuteScalar(countSql, pList.ToArray()));

            // 分頁查詢 (C# 5.0 相容 ROW_NUMBER)
            int pageIndex = filter.PageIndex <= 0 ? 1 : filter.PageIndex;
            int pageSize = filter.PageSize <= 0 ? 20 : filter.PageSize;
            int startRow = (pageIndex - 1) * pageSize + 1;
            int endRow = pageIndex * pageSize;

            string querySql = string.Format(@"
                SELECT * FROM (
                    SELECT 
                        ROW_NUMBER() OVER (ORDER BY h.uploadyear DESC, h.uploadmonth DESC, h.uploaddate DESC) AS RowNum,
                        h.pID,
                        h.FAC_ID,
                        f.FAC_NAME,
                        h.uploadyear,
                        h.uploadmonth,
                        h.uploaddate,
                        h.uploaduser,
                        u.Name AS UploadUserName,
                        h.FileName
                    FROM RoadWash_UploadHis h
                    LEFT JOIN FAC_Main f ON h.FAC_ID = f.FAC_ID
                    LEFT JOIN UserAcc u ON h.uploaduser = u.UserID
                    {0}
                ) T
                WHERE T.RowNum BETWEEN @StartRow AND @EndRow", sbWhere.ToString());

            List<SqlParameter> queryParams = new List<SqlParameter>(pList);
            queryParams.Add(new SqlParameter("@StartRow", SqlDbType.Int) { Value = startRow });
            queryParams.Add(new SqlParameter("@EndRow", SqlDbType.Int) { Value = endRow });

            DataTable dt = DbHelper.ExecuteDataTable(querySql, queryParams.ToArray());

            List<ReportItemModel> items = new List<ReportItemModel>();
            foreach (DataRow r in dt.Rows)
            {
                int pid = Convert.ToInt32(r["pID"]);
                string itemFacId = r["FAC_ID"] != DBNull.Value ? r["FAC_ID"].ToString().Trim() : "";
                string facName = r["FAC_NAME"] != DBNull.Value ? r["FAC_NAME"].ToString().Trim() : itemFacId;
                int upYear = r["uploadyear"] != DBNull.Value ? Convert.ToInt32(r["uploadyear"]) : 0;
                int upMonth = r["uploadmonth"] != DBNull.Value ? Convert.ToInt32(r["uploadmonth"]) : 0;
                string upDateStr = "";
                if (r["uploaddate"] != DBNull.Value)
                {
                    DateTime dtUp = Convert.ToDateTime(r["uploaddate"]);
                    upDateStr = dtUp.ToString("yyyy-MM-dd HH:mm");
                }
                string upUser = r["uploaduser"] != DBNull.Value ? r["uploaduser"].ToString().Trim() : "";
                string upUserName = r["UploadUserName"] != DBNull.Value ? r["UploadUserName"].ToString().Trim() : upUser;
                string fileName = r["FileName"] != DBNull.Value ? r["FileName"].ToString().Trim() : "";

                // 檢查磁碟實體檔案
                bool exists = false;
                string fileSizeStr = "-";
                string fileExt = "";
                string resolvedFileName = fileName;

                string folderPath = Server.MapPath(string.Format("~/Upload/WashPIC/{0}/月報", itemFacId));
                if (Directory.Exists(folderPath))
                {
                    if (!string.IsNullOrEmpty(fileName))
                    {
                        string directPath = Path.Combine(folderPath, fileName);
                        if (File.Exists(directPath))
                        {
                            exists = true;
                            FileInfo fi = new FileInfo(directPath);
                            fileSizeStr = FormatFileSize(fi.Length);
                            fileExt = fi.Extension.ToLower().TrimStart('.');
                        }
                    }

                    if (!exists)
                    {
                        // 嘗試依照 {year}年{month}月.* 搜尋舊版命名
                        string pattern = string.Format("{0}年{1}月.*", upYear, upMonth);
                        string[] matchedFiles = Directory.GetFiles(folderPath, pattern);
                        if (matchedFiles.Length > 0)
                        {
                            exists = true;
                            FileInfo fi = new FileInfo(matchedFiles[0]);
                            resolvedFileName = fi.Name;
                            fileSizeStr = FormatFileSize(fi.Length);
                            fileExt = fi.Extension.ToLower().TrimStart('.');
                        }
                    }
                }

                if (string.IsNullOrEmpty(fileExt) && !string.IsNullOrEmpty(resolvedFileName))
                {
                    fileExt = Path.GetExtension(resolvedFileName).ToLower().TrimStart('.');
                }

                items.Add(new ReportItemModel
                {
                    PID = pid,
                    FacId = itemFacId,
                    FacName = facName,
                    UploadYear = upYear,
                    UploadMonth = upMonth,
                    UploadDate = upDateStr,
                    UploadUser = upUser,
                    UploadUserName = upUserName,
                    FileName = !string.IsNullOrEmpty(resolvedFileName) ? resolvedFileName : "未記錄檔名",
                    FileExists = exists,
                    FileSizeStr = fileSizeStr,
                    FileExt = fileExt,
                    DownloadUrl = string.Format("ReportUpload_List.aspx?action=download&id={0}", pid)
                });
            }

            int totalPages = (int)Math.Ceiling((double)totalRows / pageSize);
            if (totalPages <= 0) totalPages = 1;

            Response.Write(json.Serialize(new
            {
                Success = true,
                Data = new
                {
                    TotalRows = totalRows,
                    TotalPages = totalPages,
                    PageIndex = pageIndex,
                    PageSize = pageSize,
                    Items = items
                }
            }));
        }

        // 4. 上傳月報檔案
        private void UploadReport()
        {
            string userId, userName, userFacId;
            bool isAdmin;
            GetUserAuthInfo(out userId, out userName, out isAdmin, out userFacId);

            if (string.IsNullOrEmpty(userId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "尚未登入或登入逾時，請重新登入！" }));
                return;
            }

            string targetFacId = Request["facId"];
            if (!isAdmin)
            {
                targetFacId = userFacId;
            }
            else if (string.IsNullOrEmpty(targetFacId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "請選擇欲申報的場所工廠！" }));
                return;
            }

            if (string.IsNullOrEmpty(targetFacId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "無效的場所編號！" }));
                return;
            }

            int year = 0;
            if (!int.TryParse(Request["year"], out year) || year <= 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "請指定正確的申報年度！" }));
                return;
            }

            int month = 0;
            if (!int.TryParse(Request["month"], out month) || month < 1 || month > 12)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "請指定正確的申報月份 (1~12)！" }));
                return;
            }

            if (Request.Files.Count == 0 || Request.Files[0] == null || Request.Files[0].ContentLength == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "請選取欲上傳的月報檔案！" }));
                return;
            }

            HttpPostedFile postedFile = Request.Files[0];
            string rawFileName = Path.GetFileName(postedFile.FileName);
            string ext = Path.GetExtension(rawFileName).ToLower();

            // 安全性副檔名白名單驗證
            List<string> allowExts = new List<string>
            {
                ".pdf", ".xls", ".xlsx", ".doc", ".docx", ".odt", ".ods",
                ".zip", ".rar", ".7z", ".jpg", ".jpeg", ".png"
            };

            if (!allowExts.Contains(ext))
            {
                Response.Write(json.Serialize(new
                {
                    Success = false,
                    Message = "檔案格式不符！僅允許上傳 PDF、Excel、Word、壓縮檔或圖片格式。"
                }));
                return;
            }

            // 大小限制：50 MB
            if (postedFile.ContentLength > 50 * 1024 * 1024)
            {
                Response.Write(json.Serialize(new
                {
                    Success = false,
                    Message = "檔案大小超過上限 (50MB)！"
                }));
                return;
            }

            // 目標資料夾：/Upload/WashPIC/{FAC_ID}/月報/
            string folderVirtualPath = string.Format("~/Upload/WashPIC/{0}/月報", targetFacId);
            string folderPhysicalPath = Server.MapPath(folderVirtualPath);
            if (!Directory.Exists(folderPhysicalPath))
            {
                Directory.CreateDirectory(folderPhysicalPath);
            }

            // 檔名規格：保留使用者檔名特徵，前綴標準年月標籤以防重名或衝突
            string sanitizedRawName = Path.GetFileNameWithoutExtension(rawFileName);
            // 移除特殊非法路徑字元
            foreach (char c in Path.GetInvalidFileNameChars())
            {
                sanitizedRawName = sanitizedRawName.Replace(c.ToString(), "");
            }
            if (string.IsNullOrEmpty(sanitizedRawName))
            {
                sanitizedRawName = "洗掃月報";
            }

            string saveFileName = string.Format("{0}年{1}月_{2}{3}", year, month, sanitizedRawName, ext);
            string saveFilePath = Path.Combine(folderPhysicalPath, saveFileName);

            // 覆寫存檔
            postedFile.SaveAs(saveFilePath);

            // 資料庫檢查存在並更新或新增
            string checkSql = "SELECT pID FROM RoadWash_UploadHis WHERE FAC_ID = @FAC_ID AND uploadyear = @year AND uploadmonth = @month";
            SqlParameter[] checkP = new SqlParameter[]
            {
                new SqlParameter("@FAC_ID", SqlDbType.VarChar) { Value = targetFacId },
                new SqlParameter("@year", SqlDbType.Int) { Value = year },
                new SqlParameter("@month", SqlDbType.Int) { Value = month }
            };
            DataTable dtExists = DbHelper.ExecuteDataTable(checkSql, checkP);

            if (dtExists.Rows.Count > 0)
            {
                int existingPid = Convert.ToInt32(dtExists.Rows[0]["pID"]);
                string updateSql = @"
                    UPDATE RoadWash_UploadHis 
                    SET uploaddate = GETDATE(),
                        uploaduser = @user,
                        FileName = @fileName
                    WHERE pID = @pID";
                SqlParameter[] updateP = new SqlParameter[]
                {
                    new SqlParameter("@user", SqlDbType.VarChar) { Value = userId },
                    new SqlParameter("@fileName", SqlDbType.NVarChar) { Value = saveFileName },
                    new SqlParameter("@pID", SqlDbType.Int) { Value = existingPid }
                };
                DbHelper.ExecuteNonQuery(updateSql, updateP);
            }
            else
            {
                string insertSql = @"
                    INSERT INTO RoadWash_UploadHis 
                    (FAC_ID, uploadyear, uploadmonth, uploaddate, uploaduser, FileName)
                    VALUES 
                    (@FAC_ID, @year, @month, GETDATE(), @user, @fileName)";
                SqlParameter[] insertP = new SqlParameter[]
                {
                    new SqlParameter("@FAC_ID", SqlDbType.VarChar) { Value = targetFacId },
                    new SqlParameter("@year", SqlDbType.Int) { Value = year },
                    new SqlParameter("@month", SqlDbType.Int) { Value = month },
                    new SqlParameter("@user", SqlDbType.VarChar) { Value = userId },
                    new SqlParameter("@fileName", SqlDbType.NVarChar) { Value = saveFileName }
                };
                DbHelper.ExecuteNonQuery(insertSql, insertP);
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                Message = string.Format("已成功上傳 {0} 年 {1} 月洗掃作業月報！", year, month),
                FileName = saveFileName
            }));
        }

        // 5. 檢查指定場所年月是否已申報
        private void CheckExists()
        {
            string facId = Request["facId"];
            int year = 0;
            int month = 0;
            int.TryParse(Request["year"], out year);
            int.TryParse(Request["month"], out month);

            if (string.IsNullOrEmpty(facId) || year <= 0 || month <= 0)
            {
                Response.Write(json.Serialize(new { Success = true, Exists = false }));
                return;
            }

            string sql = "SELECT pID, FileName, uploaddate FROM RoadWash_UploadHis WHERE FAC_ID = @FAC_ID AND uploadyear = @year AND uploadmonth = @month";
            SqlParameter[] p = new SqlParameter[]
            {
                new SqlParameter("@FAC_ID", SqlDbType.VarChar) { Value = facId },
                new SqlParameter("@year", SqlDbType.Int) { Value = year },
                new SqlParameter("@month", SqlDbType.Int) { Value = month }
            };
            DataTable dt = DbHelper.ExecuteDataTable(sql, p);
            if (dt.Rows.Count > 0)
            {
                string fn = dt.Rows[0]["FileName"] != DBNull.Value ? dt.Rows[0]["FileName"].ToString() : "";
                string upDate = dt.Rows[0]["uploaddate"] != DBNull.Value ? Convert.ToDateTime(dt.Rows[0]["uploaddate"]).ToString("yyyy-MM-dd HH:mm") : "";
                Response.Write(json.Serialize(new
                {
                    Success = true,
                    Exists = true,
                    FileName = fn,
                    UploadDate = upDate
                }));
            }
            else
            {
                Response.Write(json.Serialize(new { Success = true, Exists = false }));
            }
        }

        // 6. 刪除月報紀錄與實體檔案
        private void DeleteReport()
        {
            string userId, userName, userFacId;
            bool isAdmin;
            GetUserAuthInfo(out userId, out userName, out isAdmin, out userFacId);

            if (string.IsNullOrEmpty(userId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "尚未登入或登入逾時，請重新登入！" }));
                return;
            }

            int pid = 0;
            if (!int.TryParse(Request["id"], out pid) || pid <= 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "未指定刪除之月報紀錄編號！" }));
                return;
            }

            string sqlQuery = "SELECT pID, FAC_ID, uploadyear, uploadmonth, FileName FROM RoadWash_UploadHis WHERE pID = @pID";
            SqlParameter[] pQuery = new SqlParameter[]
            {
                new SqlParameter("@pID", SqlDbType.Int) { Value = pid }
            };
            DataTable dt = DbHelper.ExecuteDataTable(sqlQuery, pQuery);
            if (dt.Rows.Count == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "找不到該筆月報紀錄，可能已被刪除！" }));
                return;
            }

            DataRow r = dt.Rows[0];
            string itemFacId = r["FAC_ID"] != DBNull.Value ? r["FAC_ID"].ToString().Trim() : "";
            int upYear = Convert.ToInt32(r["uploadyear"]);
            int upMonth = Convert.ToInt32(r["uploadmonth"]);
            string fileName = r["FileName"] != DBNull.Value ? r["FileName"].ToString().Trim() : "";

            // 權限判定：非管理員只能刪除自己場所的月報
            if (!isAdmin && !string.Equals(itemFacId, userFacId, StringComparison.OrdinalIgnoreCase))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "您無權限刪除其他場所的申報紀錄！" }));
                return;
            }

            // 刪除磁碟實體檔案
            try
            {
                string folderPath = Server.MapPath(string.Format("~/Upload/WashPIC/{0}/月報", itemFacId));
                if (Directory.Exists(folderPath))
                {
                    if (!string.IsNullOrEmpty(fileName))
                    {
                        string directPath = Path.Combine(folderPath, fileName);
                        if (File.Exists(directPath))
                        {
                            File.Delete(directPath);
                        }
                    }

                    // 同時清除 {year}年{month}月.* 之可能殘存舊檔
                    string pattern = string.Format("{0}年{1}月.*", upYear, upMonth);
                    string[] residual = Directory.GetFiles(folderPath, pattern);
                    foreach (string rf in residual)
                    {
                        try { File.Delete(rf); } catch { }
                    }
                }
            }
            catch (Exception)
            {
                // 實體檔刪除失敗不阻止資料庫刪除，但記錄
            }

            // 刪除資料庫紀錄
            string sqlDel = "DELETE FROM RoadWash_UploadHis WHERE pID = @pID";
            SqlParameter[] pDel = new SqlParameter[]
            {
                new SqlParameter("@pID", SqlDbType.Int) { Value = pid }
            };
            DbHelper.ExecuteNonQuery(sqlDel, pDel);

            Response.Write(json.Serialize(new
            {
                Success = true,
                Message = string.Format("已成功刪除 {0} 年 {1} 月的洗掃作業月報紀錄！", upYear, upMonth)
            }));
        }

        // 7. 下載月報檔案
        private void DownloadReport()
        {
            string userId, userName, userFacId;
            bool isAdmin;
            GetUserAuthInfo(out userId, out userName, out isAdmin, out userFacId);

            if (string.IsNullOrEmpty(userId))
            {
                Response.Write("<script>alert('尚未登入或登入逾時，請重新登入！'); window.close();</script>");
                return;
            }

            int pid = 0;
            if (!int.TryParse(Request["id"], out pid) || pid <= 0)
            {
                Response.Write("<script>alert('無效的檔案編號！'); window.close();</script>");
                return;
            }

            string sql = "SELECT pID, FAC_ID, uploadyear, uploadmonth, FileName FROM RoadWash_UploadHis WHERE pID = @pID";
            SqlParameter[] p = new SqlParameter[]
            {
                new SqlParameter("@pID", SqlDbType.Int) { Value = pid }
            };
            DataTable dt = DbHelper.ExecuteDataTable(sql, p);
            if (dt.Rows.Count == 0)
            {
                Response.Write("<script>alert('找不到該月報紀錄！'); window.close();</script>");
                return;
            }

            DataRow r = dt.Rows[0];
            string itemFacId = r["FAC_ID"] != DBNull.Value ? r["FAC_ID"].ToString().Trim() : "";
            int upYear = Convert.ToInt32(r["uploadyear"]);
            int upMonth = Convert.ToInt32(r["uploadmonth"]);
            string fileName = r["FileName"] != DBNull.Value ? r["FileName"].ToString().Trim() : "";

            if (!isAdmin && !string.Equals(itemFacId, userFacId, StringComparison.OrdinalIgnoreCase))
            {
                Response.Write("<script>alert('您無權限下載其他場所之月報！'); window.close();</script>");
                return;
            }

            string folderPath = Server.MapPath(string.Format("~/Upload/WashPIC/{0}/月報", itemFacId));
            string downloadFilePath = "";

            if (Directory.Exists(folderPath))
            {
                if (!string.IsNullOrEmpty(fileName))
                {
                    string target = Path.Combine(folderPath, fileName);
                    if (File.Exists(target))
                    {
                        downloadFilePath = target;
                    }
                }

                if (string.IsNullOrEmpty(downloadFilePath))
                {
                    string pattern = string.Format("{0}年{1}月.*", upYear, upMonth);
                    string[] matched = Directory.GetFiles(folderPath, pattern);
                    if (matched.Length > 0)
                    {
                        downloadFilePath = matched[0];
                    }
                }
            }

            if (string.IsNullOrEmpty(downloadFilePath) || !File.Exists(downloadFilePath))
            {
                Response.Write("<script>alert('伺服器磁碟上找不到對應實體檔案！'); window.close();</script>");
                return;
            }

            // 確保路徑位於合法的 WashPIC 目錄下 (杜絕 Path Traversal)
            string canonicalFolder = new DirectoryInfo(folderPath).FullName;
            string canonicalFile = new FileInfo(downloadFilePath).FullName;
            if (!canonicalFile.StartsWith(canonicalFolder, StringComparison.OrdinalIgnoreCase))
            {
                Response.Write("<script>alert('非法檔案路徑存取！'); window.close();</script>");
                return;
            }

            FileInfo fi = new FileInfo(downloadFilePath);
            string outputFileName = fi.Name;

            Response.Clear();
            Response.ContentType = "application/octet-stream";
            string encodedName = HttpUtility.UrlEncode(outputFileName, Encoding.UTF8).Replace("+", "%20");
            Response.AddHeader("Content-Disposition", string.Format("attachment; filename=\"{0}\"; filename*=UTF-8''{0}", encodedName));
            Response.AddHeader("Content-Length", fi.Length.ToString());
            Response.TransmitFile(fi.FullName);
            Response.Flush();
            Response.End();
        }

        // 8. 匯出 Excel 清單 (NPOI)
        private void ExportExcel()
        {
            string userId, userName, userFacId;
            bool isAdmin;
            GetUserAuthInfo(out userId, out userName, out isAdmin, out userFacId);

            if (string.IsNullOrEmpty(userId))
            {
                Response.Write("<script>alert('尚未登入，請先登入！'); window.close();</script>");
                return;
            }

            SearchFilterModel filter = ParseFilter();

            StringBuilder sbWhere = new StringBuilder(" WHERE 1=1 ");
            List<SqlParameter> pList = new List<SqlParameter>();

            if (!isAdmin)
            {
                sbWhere.Append(" AND h.FAC_ID = @UserFacId ");
                pList.Add(new SqlParameter("@UserFacId", SqlDbType.VarChar) { Value = userFacId });
            }
            else if (!string.IsNullOrEmpty(filter.FacId))
            {
                sbWhere.Append(" AND h.FAC_ID = @FilterFacId ");
                pList.Add(new SqlParameter("@FilterFacId", SqlDbType.VarChar) { Value = filter.FacId.Trim() });
            }

            if (!string.IsNullOrEmpty(filter.Year))
            {
                int y = 0;
                if (int.TryParse(filter.Year, out y))
                {
                    sbWhere.Append(" AND h.uploadyear = @Year ");
                    pList.Add(new SqlParameter("@Year", SqlDbType.Int) { Value = y });
                }
            }

            if (!string.IsNullOrEmpty(filter.Month))
            {
                int m = 0;
                if (int.TryParse(filter.Month, out m))
                {
                    sbWhere.Append(" AND h.uploadmonth = @Month ");
                    pList.Add(new SqlParameter("@Month", SqlDbType.Int) { Value = m });
                }
            }

            if (!string.IsNullOrEmpty(filter.Keyword))
            {
                sbWhere.Append(" AND (u.Name LIKE @Kw OR h.uploaduser LIKE @Kw OR h.FileName LIKE @Kw OR f.FAC_NAME LIKE @Kw) ");
                pList.Add(new SqlParameter("@Kw", SqlDbType.NVarChar) { Value = "%" + filter.Keyword.Trim() + "%" });
            }

            string sql = string.Format(@"
                SELECT 
                    h.pID,
                    h.FAC_ID,
                    f.FAC_NAME,
                    h.uploadyear,
                    h.uploadmonth,
                    h.uploaddate,
                    h.uploaduser,
                    u.Name AS UploadUserName,
                    h.FileName
                FROM RoadWash_UploadHis h
                LEFT JOIN FAC_Main f ON h.FAC_ID = f.FAC_ID
                LEFT JOIN UserAcc u ON h.uploaduser = u.UserID
                {0}
                ORDER BY h.uploadyear DESC, h.uploadmonth DESC, h.uploaddate DESC", sbWhere.ToString());

            DataTable dt = DbHelper.ExecuteDataTable(sql, pList.ToArray());

            HSSFWorkbook workbook = new HSSFWorkbook();
            ISheet sheet = workbook.CreateSheet("洗掃作業月報清單");

            // 樣式設定
            ICellStyle titleStyle = workbook.CreateCellStyle();
            titleStyle.Alignment = HorizontalAlignment.Center;
            titleStyle.VerticalAlignment = VerticalAlignment.Center;
            IFont titleFont = workbook.CreateFont();
            titleFont.FontHeightInPoints = 16;
            titleFont.IsBold = true;
            titleFont.Color = HSSFColor.DarkBlue.Index;
            titleStyle.SetFont(titleFont);

            ICellStyle headerStyle = workbook.CreateCellStyle();
            headerStyle.Alignment = HorizontalAlignment.Center;
            headerStyle.VerticalAlignment = VerticalAlignment.Center;
            headerStyle.FillForegroundColor = HSSFColor.SkyBlue.Index;
            headerStyle.FillPattern = FillPattern.SolidForeground;
            headerStyle.BorderTop = BorderStyle.Thin;
            headerStyle.BorderBottom = BorderStyle.Thin;
            headerStyle.BorderLeft = BorderStyle.Thin;
            headerStyle.BorderRight = BorderStyle.Thin;
            IFont headerFont = workbook.CreateFont();
            headerFont.FontHeightInPoints = 11;
            headerFont.IsBold = true;
            headerStyle.SetFont(headerFont);

            ICellStyle centerStyle = workbook.CreateCellStyle();
            centerStyle.Alignment = HorizontalAlignment.Center;
            centerStyle.VerticalAlignment = VerticalAlignment.Center;
            centerStyle.BorderTop = BorderStyle.Thin;
            centerStyle.BorderBottom = BorderStyle.Thin;
            centerStyle.BorderLeft = BorderStyle.Thin;
            centerStyle.BorderRight = BorderStyle.Thin;

            ICellStyle leftStyle = workbook.CreateCellStyle();
            leftStyle.Alignment = HorizontalAlignment.Left;
            leftStyle.VerticalAlignment = VerticalAlignment.Center;
            leftStyle.BorderTop = BorderStyle.Thin;
            leftStyle.BorderBottom = BorderStyle.Thin;
            leftStyle.BorderLeft = BorderStyle.Thin;
            leftStyle.BorderRight = BorderStyle.Thin;

            // 標題列
            IRow r0 = sheet.CreateRow(0);
            r0.HeightInPoints = 35;
            ICell cTitle = r0.CreateCell(0);
            cTitle.SetCellValue("新北市固定溢散源管理平台 - 洗掃自主管理月報上傳清單");
            cTitle.CellStyle = titleStyle;
            sheet.AddMergedRegion(new CellRangeAddress(0, 0, 0, 7));

            // 表頭
            string[] headers = new string[]
            {
                "項次", "場所代碼", "場所名稱", "申報年度", "申報月份", "上傳時間", "上傳人員", "檔案名稱"
            };

            IRow r1 = sheet.CreateRow(1);
            r1.HeightInPoints = 25;
            for (int i = 0; i < headers.Length; i++)
            {
                ICell c = r1.CreateCell(i);
                c.SetCellValue(headers[i]);
                c.CellStyle = headerStyle;
            }

            int rowIdx = 2;
            int seq = 1;
            foreach (DataRow dr in dt.Rows)
            {
                IRow r = sheet.CreateRow(rowIdx);
                r.HeightInPoints = 22;

                string facId = dr["FAC_ID"] != DBNull.Value ? dr["FAC_ID"].ToString().Trim() : "";
                string facName = dr["FAC_NAME"] != DBNull.Value ? dr["FAC_NAME"].ToString().Trim() : facId;
                int y = Convert.ToInt32(dr["uploadyear"]);
                int m = Convert.ToInt32(dr["uploadmonth"]);
                string upDate = dr["uploaddate"] != DBNull.Value ? Convert.ToDateTime(dr["uploaddate"]).ToString("yyyy-MM-dd HH:mm") : "";
                string upUser = dr["UploadUserName"] != DBNull.Value ? dr["UploadUserName"].ToString().Trim() : (dr["uploaduser"] != DBNull.Value ? dr["uploaduser"].ToString().Trim() : "");
                string fn = dr["FileName"] != DBNull.Value ? dr["FileName"].ToString().Trim() : "";

                // 0: 項次
                ICell cSeq = r.CreateCell(0);
                cSeq.SetCellValue(seq);
                cSeq.CellStyle = centerStyle;

                // 1: 場所代碼
                ICell cFacId = r.CreateCell(1);
                cFacId.SetCellValue(facId);
                cFacId.CellStyle = centerStyle;

                // 2: 場所名稱
                ICell cFacName = r.CreateCell(2);
                cFacName.SetCellValue(facName);
                cFacName.CellStyle = leftStyle;

                // 3: 申報年度
                ICell cY = r.CreateCell(3);
                cY.SetCellValue(string.Format("{0} 年", y));
                cY.CellStyle = centerStyle;

                // 4: 申報月份
                ICell cM = r.CreateCell(4);
                cM.SetCellValue(string.Format("{0} 月", m));
                cM.CellStyle = centerStyle;

                // 5: 上傳時間
                ICell cDate = r.CreateCell(5);
                cDate.SetCellValue(upDate);
                cDate.CellStyle = centerStyle;

                // 6: 上傳人員
                ICell cUser = r.CreateCell(6);
                cUser.SetCellValue(upUser);
                cUser.CellStyle = centerStyle;

                // 7: 檔案名稱
                ICell cFn = r.CreateCell(7);
                cFn.SetCellValue(fn);
                cFn.CellStyle = leftStyle;

                rowIdx++;
                seq++;
            }

            int[] widths = new int[] { 8, 16, 32, 12, 12, 22, 18, 38 };
            for (int i = 0; i < widths.Length; i++)
            {
                sheet.SetColumnWidth(i, widths[i] * 256);
            }

            Response.Clear();
            Response.ContentType = "application/vnd.ms-excel";
            string exportFileName = string.Format("洗掃作業月報清單_{0:yyyyMMddHHmmss}.xls", DateTime.Now);
            string encodedExport = HttpUtility.UrlEncode(exportFileName, Encoding.UTF8).Replace("+", "%20");
            Response.AddHeader("Content-Disposition", string.Format("attachment; filename=\"{0}\"; filename*=UTF-8''{0}", encodedExport));

            using (MemoryStream ms = new MemoryStream())
            {
                workbook.Write(ms);
                byte[] bytes = ms.ToArray();
                Response.AddHeader("Content-Length", bytes.Length.ToString());
                Response.BinaryWrite(bytes);
            }
            Response.Flush();
            Response.End();
        }

        private SearchFilterModel ParseFilter()
        {
            SearchFilterModel m = new SearchFilterModel();

            if (!string.IsNullOrEmpty(Request["facId"])) m.FacId = Request["facId"].Trim();
            if (!string.IsNullOrEmpty(Request["year"])) m.Year = Request["year"].Trim();
            if (!string.IsNullOrEmpty(Request["month"])) m.Month = Request["month"].Trim();
            if (!string.IsNullOrEmpty(Request["keyword"])) m.Keyword = Request["keyword"].Trim();

            int pi = 1;
            if (int.TryParse(Request["pageIndex"], out pi) && pi > 0) m.PageIndex = pi;

            int ps = 20;
            if (int.TryParse(Request["pageSize"], out ps) && ps > 0) m.PageSize = ps;

            return m;
        }

        private static string FormatFileSize(long bytes)
        {
            if (bytes >= 1024 * 1024)
            {
                return string.Format("{0:0.##} MB", (double)bytes / (1024.0 * 1024.0));
            }
            if (bytes >= 1024)
            {
                return string.Format("{0:0.##} KB", (double)bytes / 1024.0);
            }
            return string.Format("{0} B", bytes);
        }
    }
}
