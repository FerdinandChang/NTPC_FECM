using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.UI;
using NTPC_FEC.Helpers;
using NTPC_FEC.Models;
using NTPC_FEC.Services;

namespace NTPC_FEC.Wash
{
    public partial class ReportUpload : Page
    {
        public class FacOptionItem
        {
            public string FacId { get; set; }
            public string FacName { get; set; }
        }

        private JavaScriptSerializer jsonSerializer = new JavaScriptSerializer();

        protected void Page_Load(object sender, EventArgs e)
        {
            jsonSerializer.MaxJsonLength = int.MaxValue;

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
                    Response.Write(jsonSerializer.Serialize(new
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
                case "init":
                    GetInitData();
                    break;
                case "checkexists":
                    CheckRecordExists();
                    break;
                case "gethistory":
                    GetHistoryRecords();
                    break;
                case "upload":
                    UploadReportFile();
                    break;
                case "delete":
                    DeleteRecord();
                    break;
                case "download":
                    DownloadReportFile();
                    break;
                default:
                    Response.Write(jsonSerializer.Serialize(new
                    {
                        Success = false,
                        Message = "未知的作業指令：" + action
                    }));
                    break;
            }
        }

        // 1. 取得初始化資料：使用者身分、場所清單、年度與月份
        private void GetInitData()
        {
            string userId = Session["LoginUser"] != null ? Session["LoginUser"].ToString() : "";
            if (string.IsNullOrEmpty(userId))
            {
                Response.Write(jsonSerializer.Serialize(new
                {
                    Success = false,
                    NeedLogin = true,
                    Message = "登入已逾時，請重新登入系統！"
                }));
                return;
            }

            UserAccount user = AuthService.GetCurrentUser(Context);
            bool isManager = false;
            string userFacId = "";
            string userFacName = "";
            string userName = userId;

            if (user != null)
            {
                userName = !string.IsNullOrEmpty(user.Name) ? user.Name : userId;
                userFacId = !string.IsNullOrEmpty(user.FacID) ? user.FacID.Trim() : "";

                // 檢查是否具有管理者或審查權限 (Lic 包含 9, 13, 14, 63 或無 FacID)
                if ((user.Lic & (1L << 9)) != 0 || (user.Lic & (1L << 13)) != 0 || 
                    (user.Lic & (1L << 14)) != 0 || (user.Lic & (1L << 63)) != 0 || 
                    string.IsNullOrEmpty(userFacId))
                {
                    isManager = true;
                }
            }
            else
            {
                // 從資料庫查尋備援
                string queryUserSql = "SELECT Name, FAC_ID, LIC FROM UserAcc WHERE UserID = @UserID";
                var pList = new SqlParameter[] { new SqlParameter("@UserID", SqlDbType.VarChar) { Value = userId } };
                DataTable userDt = DbHelper.ExecuteDataTable(queryUserSql, pList);
                if (userDt != null && userDt.Rows.Count > 0)
                {
                    DataRow uRow = userDt.Rows[0];
                    userName = uRow["Name"] != DBNull.Value ? uRow["Name"].ToString() : userId;
                    userFacId = uRow["FAC_ID"] != DBNull.Value ? uRow["FAC_ID"].ToString().Trim() : "";
                    long licVal = 0L;
                    if (uRow["LIC"] != DBNull.Value)
                    {
                        long.TryParse(uRow["LIC"].ToString(), out licVal);
                    }
                    if ((licVal & (1L << 9)) != 0 || (licVal & (1L << 13)) != 0 || 
                        (licVal & (1L << 14)) != 0 || (licVal & (1L << 63)) != 0 || 
                        string.IsNullOrEmpty(userFacId))
                    {
                        isManager = true;
                    }
                }
            }

            // 取得場所清單
            var facList = new List<FacOptionItem>();
            if (isManager)
            {
                // 主管可查看所有有洗掃認養紀錄或主要列管之場所
                string facSql = "SELECT DISTINCT f.FAC_ID, f.FAC_NAME FROM FAC_Main f WHERE f.FAC_ID IS NOT NULL AND f.FAC_NAME IS NOT NULL ORDER BY f.FAC_NAME";
                try
                {
                    DataTable facDt = DbHelper.ExecuteDataTable(facSql);
                    if (facDt != null)
                    {
                        foreach (DataRow row in facDt.Rows)
                        {
                            string fId = row["FAC_ID"] != DBNull.Value ? row["FAC_ID"].ToString().Trim() : "";
                            string fName = row["FAC_NAME"] != DBNull.Value ? row["FAC_NAME"].ToString().Trim() : "";
                            if (!string.IsNullOrEmpty(fId))
                            {
                                facList.Add(new FacOptionItem { FacId = fId, FacName = fName });
                            }
                        }
                    }
                }
                catch
                {
                    // 若資料過多，只抓歷史記錄中出現過的場所
                    string subFacSql = "SELECT DISTINCT h.FAC_ID, f.FAC_NAME FROM RoadWash_UploadHis h LEFT JOIN FAC_Main f ON h.FAC_ID = f.FAC_ID ORDER BY f.FAC_NAME";
                    DataTable subDt = DbHelper.ExecuteDataTable(subFacSql);
                    if (subDt != null)
                    {
                        foreach (DataRow row in subDt.Rows)
                        {
                            string fId = row["FAC_ID"] != DBNull.Value ? row["FAC_ID"].ToString().Trim() : "";
                            string fName = row["FAC_NAME"] != DBNull.Value ? row["FAC_NAME"].ToString().Trim() : fId;
                            if (!string.IsNullOrEmpty(fId))
                            {
                                facList.Add(new FacOptionItem { FacId = fId, FacName = fName });
                            }
                        }
                    }
                }

                if (string.IsNullOrEmpty(userFacId) && facList.Count > 0)
                {
                    // 若管理員無預設工廠，預設選取第一家
                    var first = facList[0];
                    userFacId = first.FacId;
                    userFacName = first.FacName;
                }
            }
            else
            {
                // 一般工廠使用者僅取得所屬工廠
                if (!string.IsNullOrEmpty(userFacId))
                {
                    string facNameSql = "SELECT TOP 1 FAC_NAME FROM FAC_Main WHERE FAC_ID = @FAC_ID";
                    var facParam = new SqlParameter[] { new SqlParameter("@FAC_ID", SqlDbType.VarChar) { Value = userFacId } };
                    DataTable fnDt = DbHelper.ExecuteDataTable(facNameSql, facParam);
                    if (fnDt != null && fnDt.Rows.Count > 0 && fnDt.Rows[0]["FAC_NAME"] != DBNull.Value)
                    {
                        userFacName = fnDt.Rows[0]["FAC_NAME"].ToString().Trim();
                    }
                    else
                    {
                        userFacName = userFacId;
                    }
                    FacOptionItem userFacItem = new FacOptionItem();
                    userFacItem.FacId = userFacId;
                    userFacItem.FacName = userFacName;
                    facList.Add(userFacItem);
                }
            }

            // 年度清單 (民國年：今年度前後共 5 年)
            int currentYear = DateTime.Today.Year;
            var yearList = new List<object>();
            for (int y = currentYear - 4; y <= currentYear + 1; y++)
            {
                int rocYear = y - 1911;
                yearList.Add(new
                {
                    Year = rocYear,
                    AdYear = y,
                    Text = string.Format("{0} 年 ({1})", rocYear, y)
                });
            }

            // 預設月份 (預設為上個月，若為 1 月則為前年 12 月)
            int defaultYear = currentYear - 1911;
            int defaultMonth = DateTime.Today.Month - 1;
            if (defaultMonth < 1)
            {
                defaultMonth = 12;
                defaultYear = defaultYear - 1;
            }

            Response.Write(jsonSerializer.Serialize(new
            {
                Success = true,
                User = new
                {
                    UserId = userId,
                    UserName = userName,
                    IsManager = isManager,
                    FacId = userFacId,
                    FacName = userFacName
                },
                FacList = facList,
                Years = yearList,
                DefaultYear = defaultYear,
                DefaultMonth = defaultMonth
            }));
        }

        // 2. 檢查指定場所與年月是否已有上傳紀錄
        private void CheckRecordExists()
        {
            string facId = Request["facId"];
            string yearStr = Request["year"];
            string monthStr = Request["month"];

            int year = 0, month = 0;
            int.TryParse(yearStr, out year);
            int.TryParse(monthStr, out month);

            if (string.IsNullOrEmpty(facId) || year <= 0 || month <= 0)
            {
                Response.Write(jsonSerializer.Serialize(new
                {
                    Success = false,
                    Message = "請提供完整的場所與年月參數！"
                }));
                return;
            }

            string sql = "SELECT TOP 1 h.pID, h.FAC_ID, h.uploadyear, h.uploadmonth, h.uploaddate, h.uploaduser, u.Name as UploadUserName, h.FileName FROM RoadWash_UploadHis h LEFT JOIN UserAcc u ON h.uploaduser = u.UserID WHERE h.FAC_ID = @FAC_ID AND h.uploadyear = @Year AND h.uploadmonth = @Month";
            var parameters = new SqlParameter[]
            {
                new SqlParameter("@FAC_ID", SqlDbType.VarChar) { Value = facId },
                new SqlParameter("@Year", SqlDbType.Int) { Value = year },
                new SqlParameter("@Month", SqlDbType.Int) { Value = month }
            };

            DataTable dt = DbHelper.ExecuteDataTable(sql, parameters);
            bool exists = false;
            object recordData = null;

            if (dt != null && dt.Rows.Count > 0)
            {
                exists = true;
                DataRow r = dt.Rows[0];
                string fName = r["FileName"] != DBNull.Value ? r["FileName"].ToString() : "";
                DateTime uploadDate = Convert.ToDateTime(r["uploaddate"]);

                // 檢查磁碟檔案
                bool fileOnDisk = false;
                long fileSizeBytes = 0;
                string dirPath = Server.MapPath(string.Format("~/Upload/WashPIC/{0}/月報", facId));
                if (Directory.Exists(dirPath))
                {
                    string searchPattern = string.Format("{0}年{1}月.*", year, month);
                    string[] files = Directory.GetFiles(dirPath, searchPattern);
                    if (files.Length > 0)
                    {
                        fileOnDisk = true;
                        FileInfo fi = new FileInfo(files[0]);
                        fileSizeBytes = fi.Length;
                    }
                }

                recordData = new
                {
                    Pid = r["pID"],
                    FacId = r["FAC_ID"],
                    Year = r["uploadyear"],
                    Month = r["uploadmonth"],
                    UploadDate = uploadDate.ToString("yyyy-MM-dd HH:mm:ss"),
                    UploadUser = r["uploaduser"],
                    UploadUserName = r["UploadUserName"] != DBNull.Value ? r["UploadUserName"].ToString() : r["uploaduser"],
                    FileName = fName,
                    FileExists = fileOnDisk,
                    FileSizeFormatted = FormatFileSize(fileSizeBytes)
                };
            }

            Response.Write(jsonSerializer.Serialize(new
            {
                Success = true,
                Exists = exists,
                Record = recordData
            }));
        }

        // 3. 取得歷史報表清單
        private void GetHistoryRecords()
        {
            string facId = Request["facId"];
            string yearStr = Request["year"];

            if (string.IsNullOrEmpty(facId))
            {
                Response.Write(jsonSerializer.Serialize(new
                {
                    Success = false,
                    Message = "請先選擇公私場所！"
                }));
                return;
            }

            int filterYear = 0;
            if (!string.IsNullOrEmpty(yearStr))
            {
                int.TryParse(yearStr, out filterYear);
            }

            string sql = "SELECT h.pID, h.FAC_ID, f.FAC_NAME, h.uploadyear, h.uploadmonth, h.uploaddate, h.uploaduser, u.Name as UploadUserName, h.FileName FROM RoadWash_UploadHis h LEFT JOIN FAC_Main f ON h.FAC_ID = f.FAC_ID LEFT JOIN UserAcc u ON h.uploaduser = u.UserID WHERE h.FAC_ID = @FAC_ID";

            var paramList = new List<SqlParameter>();
            paramList.Add(new SqlParameter("@FAC_ID", SqlDbType.VarChar) { Value = facId });

            if (filterYear > 0)
            {
                sql += " AND h.uploadyear = @Year";
                paramList.Add(new SqlParameter("@Year", SqlDbType.Int) { Value = filterYear });
            }

            sql += " ORDER BY h.uploadyear DESC, h.uploadmonth DESC, h.uploaddate DESC";

            DataTable dt = DbHelper.ExecuteDataTable(sql, paramList.ToArray());
            var records = new List<object>();

            string dirPath = Server.MapPath(string.Format("~/Upload/WashPIC/{0}/月報", facId));
            bool dirExists = Directory.Exists(dirPath);

            if (dt != null)
            {
                foreach (DataRow r in dt.Rows)
                {
                    int y = Convert.ToInt32(r["uploadyear"]);
                    int m = Convert.ToInt32(r["uploadmonth"]);
                    string fName = r["FileName"] != DBNull.Value ? r["FileName"].ToString() : "";
                    DateTime uploadDate = Convert.ToDateTime(r["uploaddate"]);

                    bool fileOnDisk = false;
                    long fileSizeBytes = 0;
                    string diskFileName = "";

                    if (dirExists)
                    {
                        string searchPattern = string.Format("{0}年{1}月.*", y, m);
                        string[] files = Directory.GetFiles(dirPath, searchPattern);
                        if (files.Length > 0)
                        {
                            fileOnDisk = true;
                            FileInfo fi = new FileInfo(files[0]);
                            fileSizeBytes = fi.Length;
                            diskFileName = fi.Name;
                        }
                    }

                    records.Add(new
                    {
                        Pid = r["pID"],
                        FacId = r["FAC_ID"],
                        FacName = r["FAC_NAME"] != DBNull.Value ? r["FAC_NAME"].ToString() : "",
                        Year = y,
                        Month = m,
                        UploadDate = uploadDate.ToString("yyyy-MM-dd HH:mm"),
                        UploadDateFull = uploadDate.ToString("yyyy-MM-dd HH:mm:ss"),
                        UploadUser = r["uploaduser"],
                        UploadUserName = r["UploadUserName"] != DBNull.Value ? r["UploadUserName"].ToString() : r["uploaduser"],
                        FileName = fName,
                        DiskFileName = diskFileName,
                        FileExists = fileOnDisk,
                        FileSizeFormatted = FormatFileSize(fileSizeBytes),
                        FileExt = GetFileExtension(diskFileName.Length > 0 ? diskFileName : fName)
                    });
                }
            }

            Response.Write(jsonSerializer.Serialize(new
            {
                Success = true,
                TotalCount = records.Count,
                Records = records
            }));
        }

        // 4. 執行上傳作業
        private void UploadReportFile()
        {
            string userId = Session["LoginUser"] != null ? Session["LoginUser"].ToString() : "";
            if (string.IsNullOrEmpty(userId))
            {
                Response.Write(jsonSerializer.Serialize(new
                {
                    Success = false,
                    Message = "登入已逾期，請重新登入！"
                }));
                return;
            }

            if (Request.Files.Count == 0 || Request.Files[0] == null || Request.Files[0].ContentLength == 0)
            {
                Response.Write(jsonSerializer.Serialize(new
                {
                    Success = false,
                    Message = "請選取要上傳的月報表檔案！"
                }));
                return;
            }

            string facId = Request["facId"];
            string yearStr = Request["year"];
            string monthStr = Request["month"];

            int year = 0, month = 0;
            int.TryParse(yearStr, out year);
            int.TryParse(monthStr, out month);

            if (string.IsNullOrEmpty(facId) || year <= 0 || month <= 0 || month > 12)
            {
                Response.Write(jsonSerializer.Serialize(new
                {
                    Success = false,
                    Message = "請確實指定場所代碼與回報年月 (1~12月)！"
                }));
                return;
            }

            HttpPostedFile file = Request.Files[0];

            // 限制檔案大小 (上限 25MB)
            if (file.ContentLength > 25 * 1024 * 1024)
            {
                Response.Write(jsonSerializer.Serialize(new
                {
                    Success = false,
                    Message = "上傳檔案過大，單一檔案上限為 25 MB！"
                }));
                return;
            }

            // 檢查副檔名安全
            string originalFileName = Path.GetFileName(file.FileName);
            string ext = Path.GetExtension(originalFileName).ToLower();
            string allowedExts = ".pdf|.doc|.docx|.xls|.xlsx|.jpg|.jpeg|.png|.zip|.rar|.7z|.csv";
            if (string.IsNullOrEmpty(ext) || !allowedExts.Contains(ext))
            {
                Response.Write(jsonSerializer.Serialize(new
                {
                    Success = false,
                    Message = "不支援的檔案格式！僅允許 PDF、Word、Excel、JPG/PNG 圖片或 ZIP 壓縮檔。"
                }));
                return;
            }

            // 目標儲存路徑：~/Upload/WashPIC/{facId}/月報/
            string targetFolder = Server.MapPath(string.Format("~/Upload/WashPIC/{0}/月報", facId));
            if (!Directory.Exists(targetFolder))
            {
                Directory.CreateDirectory(targetFolder);
            }

            // 檔名標準格式：{year}年{month}月.{ext} (相容舊系統與舊清單)
            string targetFileName = string.Format("{0}年{1}月{2}", year, month, ext);
            string fullSavePath = Path.Combine(targetFolder, targetFileName);

            // 清理同年月其他副檔名的舊檔，避免存在多個版本衝突
            try
            {
                string searchPattern = string.Format("{0}年{1}月.*", year, month);
                string[] oldFiles = Directory.GetFiles(targetFolder, searchPattern);
                foreach (string oldF in oldFiles)
                {
                    try { File.Delete(oldF); } catch { }
                }
            }
            catch { }

            // 儲存檔案
            file.SaveAs(fullSavePath);

            // 寫入/更新資料庫紀錄
            string checkSql = "SELECT COUNT(*) FROM RoadWash_UploadHis WHERE FAC_ID = @FAC_ID AND uploadyear = @Year AND uploadmonth = @Month";
            var checkParams = new SqlParameter[]
            {
                new SqlParameter("@FAC_ID", SqlDbType.VarChar) { Value = facId },
                new SqlParameter("@Year", SqlDbType.Int) { Value = year },
                new SqlParameter("@Month", SqlDbType.Int) { Value = month }
            };

            int count = Convert.ToInt32(DbHelper.ExecuteScalar(checkSql, checkParams));
            if (count > 0)
            {
                // 更新現有紀錄
                string updateSql = "UPDATE RoadWash_UploadHis SET uploaddate = GETDATE(), uploaduser = @UploadUser, FileName = @FileName WHERE FAC_ID = @FAC_ID AND uploadyear = @Year AND uploadmonth = @Month";
                var updateParams = new SqlParameter[]
                {
                    new SqlParameter("@UploadUser", SqlDbType.VarChar) { Value = userId },
                    new SqlParameter("@FileName", SqlDbType.NVarChar) { Value = originalFileName },
                    new SqlParameter("@FAC_ID", SqlDbType.VarChar) { Value = facId },
                    new SqlParameter("@Year", SqlDbType.Int) { Value = year },
                    new SqlParameter("@Month", SqlDbType.Int) { Value = month }
                };
                DbHelper.ExecuteNonQuery(updateSql, updateParams);
            }
            else
            {
                // 新增紀錄
                string insertSql = "INSERT INTO RoadWash_UploadHis (FAC_ID, uploadyear, uploadmonth, uploaddate, uploaduser, FileName) VALUES (@FAC_ID, @Year, @Month, GETDATE(), @UploadUser, @FileName)";
                var insertParams = new SqlParameter[]
                {
                    new SqlParameter("@FAC_ID", SqlDbType.VarChar) { Value = facId },
                    new SqlParameter("@Year", SqlDbType.Int) { Value = year },
                    new SqlParameter("@Month", SqlDbType.Int) { Value = month },
                    new SqlParameter("@UploadUser", SqlDbType.VarChar) { Value = userId },
                    new SqlParameter("@FileName", SqlDbType.NVarChar) { Value = originalFileName }
                };
                DbHelper.ExecuteNonQuery(insertSql, insertParams);
            }

            Response.Write(jsonSerializer.Serialize(new
            {
                Success = true,
                Message = string.Format("【{0}年{1}月】月報表已成功上傳儲存！", year, month),
                FileName = targetFileName,
                OriginalName = originalFileName
            }));
        }

        // 5. 刪除上傳紀錄與檔案
        private void DeleteRecord()
        {
            string userId = Session["LoginUser"] != null ? Session["LoginUser"].ToString() : "";
            if (string.IsNullOrEmpty(userId))
            {
                Response.Write(jsonSerializer.Serialize(new
                {
                    Success = false,
                    Message = "登入已逾期，請重新登入！"
                }));
                return;
            }

            string pidStr = Request["pid"];
            int pid = 0;
            int.TryParse(pidStr, out pid);

            if (pid <= 0)
            {
                Response.Write(jsonSerializer.Serialize(new
                {
                    Success = false,
                    Message = "缺少欲刪除的報表記錄識別碼！"
                }));
                return;
            }

            // 查詢記錄
            string querySql = "SELECT FAC_ID, uploadyear, uploadmonth, uploaduser, FileName FROM RoadWash_UploadHis WHERE pID = @PID";
            var qParams = new SqlParameter[] { new SqlParameter("@PID", SqlDbType.Int) { Value = pid } };
            DataTable dt = DbHelper.ExecuteDataTable(querySql, qParams);

            if (dt == null || dt.Rows.Count == 0)
            {
                Response.Write(jsonSerializer.Serialize(new
                {
                    Success = false,
                    Message = "找不到該筆報表記錄，可能已被刪除！"
                }));
                return;
            }

            DataRow row = dt.Rows[0];
            string facId = row["FAC_ID"].ToString();
            int year = Convert.ToInt32(row["uploadyear"]);
            int month = Convert.ToInt32(row["uploadmonth"]);

            // 刪除實體檔案
            string dirPath = Server.MapPath(string.Format("~/Upload/WashPIC/{0}/月報", facId));
            if (Directory.Exists(dirPath))
            {
                string searchPattern = string.Format("{0}年{1}月.*", year, month);
                string[] files = Directory.GetFiles(dirPath, searchPattern);
                foreach (string f in files)
                {
                    try { File.Delete(f); } catch { }
                }
            }

            // 刪除資料庫記錄
            string delSql = "DELETE FROM RoadWash_UploadHis WHERE pID = @PID";
            var dParams = new SqlParameter[] { new SqlParameter("@PID", SqlDbType.Int) { Value = pid } };
            DbHelper.ExecuteNonQuery(delSql, dParams);

            Response.Write(jsonSerializer.Serialize(new
            {
                Success = true,
                Message = string.Format("【{0}年{1}月】月報表已成功刪除！", year, month)
            }));
        }

        // 6. 下載報表檔案
        private void DownloadReportFile()
        {
            string facId = Request["facId"];
            string yearStr = Request["year"];
            string monthStr = Request["month"];

            int year = 0, month = 0;
            int.TryParse(yearStr, out year);
            int.TryParse(monthStr, out month);

            if (string.IsNullOrEmpty(facId) || year <= 0 || month <= 0)
            {
                Response.Clear();
                Response.StatusCode = 400;
                Response.Write("參數不完整！");
                Response.End();
                return;
            }

            string dirPath = Server.MapPath(string.Format("~/Upload/WashPIC/{0}/月報", facId));
            if (!Directory.Exists(dirPath))
            {
                Response.Clear();
                Response.StatusCode = 404;
                Response.Write("查無該場所之報表目錄！");
                Response.End();
                return;
            }

            string searchPattern = string.Format("{0}年{1}月.*", year, month);
            string[] files = Directory.GetFiles(dirPath, searchPattern);
            if (files.Length == 0)
            {
                Response.Clear();
                Response.StatusCode = 404;
                Response.Write("報表實體檔案不存在或已被移除！");
                Response.End();
                return;
            }

            string filePath = files[0];
            string downloadName = Path.GetFileName(filePath);

            Response.Clear();
            Response.ContentType = "application/octet-stream";
            Response.AddHeader("Content-Disposition", "attachment; filename=" + HttpUtility.UrlEncode(downloadName));
            Response.TransmitFile(filePath);
            Response.End();
        }

        // 格式化檔案大小
        private static string FormatFileSize(long bytes)
        {
            if (bytes <= 0) return "0 B";
            if (bytes < 1024) return bytes + " B";
            if (bytes < 1024 * 1024) return (bytes / 1024.0).ToString("F1") + " KB";
            return (bytes / (1024.0 * 1024.0)).ToString("F2") + " MB";
        }

        // 取得副檔名純文字標籤
        private static string GetFileExtension(string fileName)
        {
            if (string.IsNullOrEmpty(fileName)) return "";
            string ext = Path.GetExtension(fileName);
            return string.IsNullOrEmpty(ext) ? "" : ext.TrimStart('.').ToUpper();
        }
    }
}
