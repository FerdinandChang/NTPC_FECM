using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Text;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.UI;
using NTPC_FEC.Helpers;
using NPOI.HSSF.UserModel;
using NPOI.HSSF.Util;
using NPOI.SS.UserModel;
using NPOI.XSSF.UserModel;

namespace NTPC_FEC.MoenvEquip
{
    public partial class MoenvEquipment_List : Page
    {
        private JavaScriptSerializer json;

        public MoenvEquipment_List()
        {
            json = new JavaScriptSerializer();
            json.MaxJsonLength = int.MaxValue;
        }

        private static string GetConnStr()
        {
            return MoenvEquipment_Helper.GetConnStr();
        }

        public static string NormalizePhotoVirtualPath(string path)
        {
            if (string.IsNullOrEmpty(path)) return "";
            string p = path.Trim().Replace("\\", "/");
            int idx = p.IndexOf("Uploads/", StringComparison.OrdinalIgnoreCase);
            if (idx >= 0)
            {
                return "/NTPCEPD_New/MoenvEquip/" + p.Substring(idx);
            }
            if (p.StartsWith("/NTPCEPD_New/", StringComparison.OrdinalIgnoreCase))
            {
                return p;
            }
            return "/NTPCEPD_New/MoenvEquip/Uploads/" + p.TrimStart('~', '/');
        }

        public static string GetUploadPhysicalDir(int equipId)
        {
            string hardcodedBase = @"D:\Web\NTPCEPD_New\MoenvEquip\Uploads\";
            if (Directory.Exists(@"D:\Web\NTPCEPD_New\MoenvEquip\Uploads"))
            {
                string target = Path.Combine(hardcodedBase, equipId.ToString());
                if (!Directory.Exists(target))
                {
                    Directory.CreateDirectory(target);
                }
                return target;
            }

            string localBase = HttpContext.Current != null
                ? HttpContext.Current.Server.MapPath("~/MoenvEquip/Uploads/" + equipId + "/")
                : "";
            if (!string.IsNullOrEmpty(localBase) && !Directory.Exists(localBase))
            {
                Directory.CreateDirectory(localBase);
            }
            return localBase;
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
            MoenvEquipment_Helper.EnsureDatabaseSchema();

            string action = Request["action"];
            if (!string.IsNullOrEmpty(action))
            {
                if (action.Equals("export", StringComparison.OrdinalIgnoreCase))
                {
                    ExportExcelAction();
                    return;
                }

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
                    Dictionary<string, object> errObj = new Dictionary<string, object>();
                    errObj["success"] = false;
                    errObj["message"] = "系統執行錯誤：" + ex.Message;
                    SendJsonResponse(errObj);
                }
                return;
            }
        }

        private void HandleAjaxAction(string action)
        {
            string act = action.ToLower();
            if (act == "init")
            {
                GetInitOptions();
            }
            else if (act == "search")
            {
                SearchEquipment();
            }
            else if (act == "detail")
            {
                int id = 0;
                int.TryParse(Request["id"], out id);
                string resJson = GetEquipmentDetails(id);
                Response.Clear();
                Response.ContentType = "application/json; charset=utf-8";
                Response.ContentEncoding = new UTF8Encoding(true);
                Response.Write(resJson);
                AjaxResponseHelper.CompleteRequest(Response, Context);
            }
            else if (act == "update_project_type")
            {
                int id = 0;
                int.TryParse(Request["id"], out id);
                string projectType = Request["projectType"] != null ? Request["projectType"].Trim() : "";
                string resJson = UpdateProjectType(id, projectType);
                Response.Clear();
                Response.ContentType = "application/json; charset=utf-8";
                Response.ContentEncoding = new UTF8Encoding(true);
                Response.Write(resJson);
                AjaxResponseHelper.CompleteRequest(Response, Context);
            }
            else if (act == "upload_photo")
            {
                ProcessPhotoUpload();
            }
            else if (act == "delete_photo")
            {
                int photoId = 0;
                int.TryParse(Request["photoId"], out photoId);
                string resJson = DeletePhoto(photoId);
                Response.Clear();
                Response.ContentType = "application/json; charset=utf-8";
                Response.ContentEncoding = new UTF8Encoding(true);
                Response.Write(resJson);
                AjaxResponseHelper.CompleteRequest(Response, Context);
            }
            else
            {
                Dictionary<string, object> unknown = new Dictionary<string, object>();
                unknown["success"] = false;
                unknown["message"] = "未知的操作指令：" + action;
                SendJsonResponse(unknown);
            }
        }

        private void GetInitOptions()
        {
            List<string> equipTypes = new List<string>();
            List<string> applyTypes = new List<string>();

            try
            {
                using (SqlConnection conn = new SqlConnection(GetConnStr()))
                {
                    conn.Open();

                    string typeSql = "SELECT DISTINCT [EquipType] FROM [MoenvEquipment] WHERE [EquipType] IS NOT NULL AND [EquipType] <> '' ORDER BY [EquipType]";
                    using (SqlCommand cmd = new SqlCommand(typeSql, conn))
                    using (SqlDataReader reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            string t = reader["EquipType"].ToString().Trim();
                            if (!string.IsNullOrEmpty(t))
                            {
                                equipTypes.Add(t);
                            }
                        }
                    }

                    string applySql = "SELECT DISTINCT [ApplyType] FROM [MoenvEquipment] WHERE [ApplyType] IS NOT NULL AND [ApplyType] <> '' ORDER BY [ApplyType]";
                    using (SqlCommand cmd = new SqlCommand(applySql, conn))
                    using (SqlDataReader reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            string a = reader["ApplyType"].ToString().Trim();
                            if (!string.IsNullOrEmpty(a))
                            {
                                applyTypes.Add(a);
                            }
                        }
                    }
                }
            }
            catch
            {
            }

            int currentYear = DateTime.Now.Year;
            Dictionary<string, object> result = new Dictionary<string, object>();
            result["success"] = true;
            result["equipTypes"] = equipTypes;
            result["applyTypes"] = applyTypes;
            result["defaultDateFrom"] = new DateTime(currentYear, 1, 1).ToString("yyyy-MM-dd");
            result["defaultDateTo"] = DateTime.Now.ToString("yyyy-MM-dd");

            SendJsonResponse(result);
        }

        private string BuildWhereClause(
            SqlCommand cmd,
            string dateFrom,
            string dateTo,
            string equipType,
            string applyType,
            string projectType,
            string badgeLevel,
            string qualifiedStatus,
            string keyword,
            bool excludeBadgeAndQualified)
        {
            List<string> conds = new List<string>();

            if (!string.IsNullOrEmpty(dateFrom))
            {
                conds.Add("[TestDate] >= @DateFrom");
                if (!cmd.Parameters.Contains("@DateFrom"))
                {
                    cmd.Parameters.AddWithValue("@DateFrom", dateFrom.Trim().Replace("-", "/"));
                }
            }
            if (!string.IsNullOrEmpty(dateTo))
            {
                conds.Add("[TestDate] <= @DateTo");
                if (!cmd.Parameters.Contains("@DateTo"))
                {
                    cmd.Parameters.AddWithValue("@DateTo", dateTo.Trim().Replace("-", "/") + " 23:59:59");
                }
            }
            if (!string.IsNullOrEmpty(equipType))
            {
                conds.Add("[EquipType] = @EquipType");
                if (!cmd.Parameters.Contains("@EquipType"))
                {
                    cmd.Parameters.AddWithValue("@EquipType", equipType.Trim());
                }
            }
            if (!string.IsNullOrEmpty(applyType))
            {
                conds.Add("[ApplyType] = @ApplyType");
                if (!cmd.Parameters.Contains("@ApplyType"))
                {
                    cmd.Parameters.AddWithValue("@ApplyType", applyType.Trim());
                }
            }
            if (!string.IsNullOrEmpty(projectType))
            {
                conds.Add("[ProjectType] = @ProjectType");
                if (!cmd.Parameters.Contains("@ProjectType"))
                {
                    cmd.Parameters.AddWithValue("@ProjectType", projectType.Trim());
                }
            }
            if (!excludeBadgeAndQualified)
            {
                if (!string.IsNullOrEmpty(badgeLevel) && badgeLevel != "未通過")
                {
                    conds.Add("[BadgeLevel] = @BadgeLevel");
                    if (!cmd.Parameters.Contains("@BadgeLevel"))
                    {
                        cmd.Parameters.AddWithValue("@BadgeLevel", badgeLevel.Trim());
                    }
                }
                if (!string.IsNullOrEmpty(qualifiedStatus))
                {
                    if (qualifiedStatus == "1")
                    {
                        conds.Add("[IsQualified] = 1");
                    }
                    else if (qualifiedStatus == "0")
                    {
                        conds.Add("([IsQualified] = 0 OR [IsQualified] IS NULL)");
                    }
                }
            }
            if (!string.IsNullOrEmpty(keyword))
            {
                conds.Add("([OwnerName] LIKE @Keyword OR [TaxId] LIKE @Keyword OR [Brand] LIKE @Keyword OR [Model] LIKE @Keyword OR [EngineNumber] LIKE @Keyword OR [PlateNumber] LIKE @Keyword OR [BadgeNumber] LIKE @Keyword)");
                if (!cmd.Parameters.Contains("@Keyword"))
                {
                    cmd.Parameters.AddWithValue("@Keyword", "%" + keyword.Trim() + "%");
                }
            }

            if (conds.Count > 0)
            {
                return " WHERE " + string.Join(" AND ", conds.ToArray());
            }
            return "";
        }

        private void SearchEquipment()
        {
            string dateFrom = Request["dateFrom"] != null ? Request["dateFrom"].Trim() : "";
            string dateTo = Request["dateTo"] != null ? Request["dateTo"].Trim() : "";
            string equipType = Request["equipType"] != null ? Request["equipType"].Trim() : "";
            string applyType = Request["applyType"] != null ? Request["applyType"].Trim() : "";
            string projectType = Request["projectType"] != null ? Request["projectType"].Trim() : "";
            string badgeLevel = Request["badgeLevel"] != null ? Request["badgeLevel"].Trim() : "";
            string qualifiedStatus = Request["qualifiedStatus"] != null ? Request["qualifiedStatus"].Trim() : "";
            string keyword = Request["keyword"] != null ? Request["keyword"].Trim() : "";

            int pageIndex = 1;
            int pageSize = 15;
            int.TryParse(Request["pageIndex"], out pageIndex);
            int.TryParse(Request["pageSize"], out pageSize);
            if (pageIndex < 1) pageIndex = 1;
            if (pageSize < 1) pageSize = 15;

            int goldCount = 0;
            int silverCount = 0;
            int bronzeCount = 0;
            int failCount = 0;
            int qualifiedCount = 0;
            int totalMainCount = 0;
            double qualifiedRate = 0.0;

            List<Dictionary<string, object>> pagedItems = new List<Dictionary<string, object>>();
            int totalListCount = 0;

            try
            {
                using (SqlConnection conn = new SqlConnection(GetConnStr()))
                {
                    conn.Open();

                    // 1. 計算儀表板 5 張統計卡片
                    using (SqlCommand statCmd = new SqlCommand())
                    {
                        statCmd.Connection = conn;
                        string whereBase = BuildWhereClause(statCmd, dateFrom, dateTo, equipType, applyType, projectType, badgeLevel, qualifiedStatus, keyword, true);

                        string whereGold = whereBase != "" ? (whereBase + " AND [BadgeLevel] = '金級'") : " WHERE [BadgeLevel] = '金級'";
                        string whereSilver = whereBase != "" ? (whereBase + " AND [BadgeLevel] = '銀級'") : " WHERE [BadgeLevel] = '銀級'";
                        string whereBronze = whereBase != "" ? (whereBase + " AND [BadgeLevel] = '普級'") : " WHERE [BadgeLevel] = '普級'";
                        string whereQualified = whereBase != "" ? (whereBase + " AND [IsQualified] = 1") : " WHERE [IsQualified] = 1";

                        string statSql =
                            "SELECT " +
                            "(SELECT COUNT(*) FROM [MoenvEquipment] " + whereGold + ") AS GoldCount, " +
                            "(SELECT COUNT(*) FROM [MoenvEquipment] " + whereSilver + ") AS SilverCount, " +
                            "(SELECT COUNT(*) FROM [MoenvEquipment] " + whereBronze + ") AS BronzeCount, " +
                            "(SELECT COUNT(*) FROM [MoenvEquipment_Unqualified] " + whereBase + ") AS FailCount, " +
                            "(SELECT COUNT(*) FROM [MoenvEquipment] " + whereQualified + ") AS QualifiedCount, " +
                            "(SELECT COUNT(*) FROM [MoenvEquipment] " + whereBase + ") AS TotalCount";

                        statCmd.CommandText = statSql;
                        using (SqlDataReader reader = statCmd.ExecuteReader())
                        {
                            if (reader.Read())
                            {
                                goldCount = Convert.ToInt32(reader["GoldCount"]);
                                silverCount = Convert.ToInt32(reader["SilverCount"]);
                                bronzeCount = Convert.ToInt32(reader["BronzeCount"]);
                                failCount = Convert.ToInt32(reader["FailCount"]);
                                qualifiedCount = Convert.ToInt32(reader["QualifiedCount"]);
                                totalMainCount = Convert.ToInt32(reader["TotalCount"]);

                                if (totalMainCount > 0)
                                {
                                    qualifiedRate = Math.Round(((double)qualifiedCount / (double)totalMainCount) * 100.0, 0);
                                }
                            }
                        }
                    }

                    // 2. 查詢清單資料
                    string tableName = (badgeLevel == "未通過") ? "MoenvEquipment_Unqualified" : "MoenvEquipment";
                    bool excludeBadge = (badgeLevel == "未通過");

                    using (SqlCommand listCmd = new SqlCommand())
                    {
                        listCmd.Connection = conn;
                        string whereList = BuildWhereClause(listCmd, dateFrom, dateTo, equipType, applyType, projectType, badgeLevel, qualifiedStatus, keyword, excludeBadge);

                        string listSql =
                            "SELECT e.*, " +
                            "(SELECT COUNT(*) FROM [MoenvEquipment_Photo] p WHERE p.[EquipmentId] = e.[Id]) AS [PhotoCount] " +
                            "FROM [" + tableName + "] e" +
                            whereList +
                            " ORDER BY [TestDate] DESC, e.[Id] DESC";

                        listCmd.CommandText = listSql;

                        DataTable dt = new DataTable();
                        using (SqlDataAdapter da = new SqlDataAdapter(listCmd))
                        {
                            da.Fill(dt);
                        }

                        totalListCount = dt.Rows.Count;
                        int startIdx = (pageIndex - 1) * pageSize;
                        int endIdx = Math.Min(startIdx + pageSize, totalListCount);

                        for (int i = startIdx; i < endIdx; i++)
                        {
                            DataRow row = dt.Rows[i];
                            Dictionary<string, object> item = new Dictionary<string, object>();
                            item["Id"] = row["Id"] != DBNull.Value ? Convert.ToInt32(row["Id"]) : 0;
                            item["OwnerName"] = row["OwnerName"] != DBNull.Value ? row["OwnerName"].ToString().Trim() : "";
                            item["TaxId"] = row["TaxId"] != DBNull.Value ? row["TaxId"].ToString().Trim() : "";
                            item["Brand"] = row["Brand"] != DBNull.Value ? row["Brand"].ToString().Trim() : "";
                            item["EquipType"] = row["EquipType"] != DBNull.Value ? row["EquipType"].ToString().Trim() : "";
                            item["Model"] = row["Model"] != DBNull.Value ? row["Model"].ToString().Trim() : "";
                            item["EngineNumber"] = row["EngineNumber"] != DBNull.Value ? row["EngineNumber"].ToString().Trim() : "";
                            item["PlateNumber"] = row["PlateNumber"] != DBNull.Value ? row["PlateNumber"].ToString().Trim() : "";
                            item["BadgeNumber"] = row["BadgeNumber"] != DBNull.Value ? row["BadgeNumber"].ToString().Trim() : "";
                            item["ApplyType"] = row["ApplyType"] != DBNull.Value ? row["ApplyType"].ToString().Trim() : "";
                            item["ProjectType"] = (dt.Columns.Contains("ProjectType") && row["ProjectType"] != DBNull.Value) ? row["ProjectType"].ToString().Trim() : "營建";

                            string testDateStr = "";
                            if (row["TestDate"] != DBNull.Value)
                            {
                                DateTime dtParsed;
                                if (DateTime.TryParse(row["TestDate"].ToString(), out dtParsed))
                                {
                                    testDateStr = dtParsed.ToString("yyyy/MM/dd");
                                }
                                else
                                {
                                    testDateStr = row["TestDate"].ToString().Trim();
                                }
                            }
                            item["TestDate"] = testDateStr;

                            string bLevel = row["BadgeLevel"] != DBNull.Value ? row["BadgeLevel"].ToString().Trim() : "";
                            if (string.IsNullOrEmpty(bLevel) && badgeLevel == "未通過")
                            {
                                bLevel = "未通過";
                            }
                            item["BadgeLevel"] = bLevel;

                            bool isQual = false;
                            if (dt.Columns.Contains("IsQualified") && row["IsQualified"] != DBNull.Value)
                            {
                                isQual = Convert.ToBoolean(row["IsQualified"]);
                            }
                            item["IsQualified"] = isQual;

                            int photoCnt = 0;
                            if (dt.Columns.Contains("PhotoCount") && row["PhotoCount"] != DBNull.Value)
                            {
                                photoCnt = Convert.ToInt32(row["PhotoCount"]);
                            }
                            item["PhotoCount"] = photoCnt;

                            pagedItems.Add(item);
                        }
                    }
                }

                Dictionary<string, object> stats = new Dictionary<string, object>();
                stats["GoldCount"] = goldCount;
                stats["SilverCount"] = silverCount;
                stats["BronzeCount"] = bronzeCount;
                stats["FailCount"] = failCount;
                stats["QualifiedCount"] = qualifiedCount;
                stats["TotalMainCount"] = totalMainCount;
                stats["QualifiedRate"] = qualifiedRate;
                stats["TotalAll"] = totalMainCount + failCount;

                Dictionary<string, object> response = new Dictionary<string, object>();
                response["success"] = true;
                response["stats"] = stats;
                response["items"] = pagedItems;
                response["totalCount"] = totalListCount;
                response["pageIndex"] = pageIndex;
                response["pageSize"] = pageSize;

                SendJsonResponse(response);
            }
            catch (Exception ex)
            {
                Dictionary<string, object> errResponse = new Dictionary<string, object>();
                errResponse["success"] = false;
                errResponse["message"] = "查詢資料失敗：" + ex.Message;
                SendJsonResponse(errResponse);
            }
        }

        public static string GetEquipmentDetails(int id)
        {
            JavaScriptSerializer js = new JavaScriptSerializer();
            Dictionary<string, object> result = new Dictionary<string, object>();
            result["success"] = false;
            result["data"] = null;
            result["photos"] = null;
            result["message"] = "";

            try
            {
                using (SqlConnection conn = new SqlConnection(GetConnStr()))
                {
                    conn.Open();

                    // 自動同步硬碟實體檔案至資料庫記錄 (僅新增未登錄檔案，絕不在唯讀檢視時隨意刪除 DB 紀錄)
                    try
                    {
                        string physicalDir = GetUploadPhysicalDir(id);
                        if (!string.IsNullOrEmpty(physicalDir) && Directory.Exists(physicalDir))
                        {
                            string[] physicalFiles = Directory.GetFiles(physicalDir);
                            List<string> dbPhotos = new List<string>();

                            string checkSql = "SELECT [PhotoPath] FROM [MoenvEquipment_Photo] WHERE [EquipmentId] = @Id";
                            using (SqlCommand cmd = new SqlCommand(checkSql, conn))
                            {
                                cmd.Parameters.AddWithValue("@Id", id);
                                using (SqlDataReader reader = cmd.ExecuteReader())
                                {
                                    while (reader.Read())
                                    {
                                        dbPhotos.Add(NormalizePhotoVirtualPath(reader["PhotoPath"].ToString().Trim()).ToLower());
                                    }
                                }
                            }

                            for (int i = 0; i < physicalFiles.Length; i++)
                            {
                                string filePath = physicalFiles[i];
                                string ext = Path.GetExtension(filePath).ToLower();
                                if (ext == ".jpg" || ext == ".png" || ext == ".jpeg" || ext == ".gif")
                                {
                                    string fileName = Path.GetFileName(filePath);
                                    string virtualPath = "/NTPCEPD_New/MoenvEquip/Uploads/" + id + "/" + fileName;
                                    if (!dbPhotos.Contains(virtualPath.ToLower()))
                                    {
                                        string insertSql = "INSERT INTO [MoenvEquipment_Photo] ([EquipmentId], [PhotoPath]) VALUES (@Id, @PhotoPath)";
                                        using (SqlCommand cmd = new SqlCommand(insertSql, conn))
                                        {
                                            cmd.Parameters.AddWithValue("@Id", id);
                                            cmd.Parameters.AddWithValue("@PhotoPath", virtualPath);
                                            cmd.ExecuteNonQuery();
                                        }
                                    }
                                }
                            }
                        }
                    }
                    catch
                    {
                    }

                    Dictionary<string, string> equipData = new Dictionary<string, string>();
                    string equipSql = "SELECT * FROM [MoenvEquipment] WHERE [Id] = @Id";
                    using (SqlCommand cmd = new SqlCommand(equipSql, conn))
                    {
                        cmd.Parameters.AddWithValue("@Id", id);
                        using (SqlDataReader reader = cmd.ExecuteReader())
                        {
                            if (reader.Read())
                            {
                                ReadAllColumnsToDict(reader, equipData);
                            }
                        }
                    }

                    if (equipData.Count == 0)
                    {
                        string unqualifiedSql = "SELECT * FROM [MoenvEquipment_Unqualified] WHERE [Id] = @Id";
                        using (SqlCommand cmd = new SqlCommand(unqualifiedSql, conn))
                        {
                            cmd.Parameters.AddWithValue("@Id", id);
                            using (SqlDataReader reader = cmd.ExecuteReader())
                            {
                                if (reader.Read())
                                {
                                    ReadAllColumnsToDict(reader, equipData);
                                }
                            }
                        }
                    }

                    if (equipData.Count == 0)
                    {
                        result["message"] = "找不到該筆機具資料";
                        return js.Serialize(result);
                    }

                    string physDir = GetUploadPhysicalDir(id);
                    equipData["PhotoFolderPath"] = physDir;

                    List<Dictionary<string, object>> photos = new List<Dictionary<string, object>>();
                    string photoSql = "SELECT [Id], [PhotoPath] FROM [MoenvEquipment_Photo] WHERE [EquipmentId] = @Id ORDER BY [Id] DESC";
                    using (SqlCommand cmd = new SqlCommand(photoSql, conn))
                    {
                        cmd.Parameters.AddWithValue("@Id", id);
                        using (SqlDataReader reader = cmd.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                Dictionary<string, object> p = new Dictionary<string, object>();
                                p["Id"] = Convert.ToInt32(reader["Id"]);
                                string rawPath = reader["PhotoPath"] != DBNull.Value ? reader["PhotoPath"].ToString().Trim() : "";
                                p["PhotoPath"] = NormalizePhotoVirtualPath(rawPath);
                                photos.Add(p);
                            }
                        }
                    }

                    result["success"] = true;
                    result["data"] = equipData;
                    result["photos"] = photos;
                }
            }
            catch (Exception ex)
            {
                result["message"] = "取得資料失敗：" + ex.Message;
            }

            return js.Serialize(result);
        }

        private static void ReadAllColumnsToDict(SqlDataReader reader, Dictionary<string, string> dict)
        {
            for (int c = 0; c < reader.FieldCount; c++)
            {
                string colName = reader.GetName(c);
                string colVal = "";
                if (!reader.IsDBNull(c))
                {
                    if (reader.GetFieldType(c) == typeof(DateTime))
                    {
                        colVal = Convert.ToDateTime(reader[c]).ToString("yyyy/MM/dd HH:mm:ss");
                    }
                    else
                    {
                        colVal = reader[c].ToString().Trim();
                    }
                }
                dict[colName] = colVal;
            }
        }

        public static string DeletePhoto(int photoId)
        {
            JavaScriptSerializer js = new JavaScriptSerializer();
            Dictionary<string, object> result = new Dictionary<string, object>();
            result["success"] = false;
            result["message"] = "";

            try
            {
                string relativePath = "";
                int equipId = 0;
                using (SqlConnection conn = new SqlConnection(GetConnStr()))
                {
                    conn.Open();

                    using (SqlCommand cmd = new SqlCommand("SELECT [PhotoPath], [EquipmentId] FROM [MoenvEquipment_Photo] WHERE [Id] = @Id", conn))
                    {
                        cmd.Parameters.AddWithValue("@Id", photoId);
                        using (SqlDataReader reader = cmd.ExecuteReader())
                        {
                            if (reader.Read())
                            {
                                relativePath = reader["PhotoPath"] != DBNull.Value ? reader["PhotoPath"].ToString().Trim() : "";
                                equipId = reader["EquipmentId"] != DBNull.Value ? Convert.ToInt32(reader["EquipmentId"]) : 0;
                            }
                        }
                    }

                    if (string.IsNullOrEmpty(relativePath))
                    {
                        result["message"] = "找不到指定的照片紀錄";
                        return js.Serialize(result);
                    }

                    using (SqlCommand cmd = new SqlCommand("DELETE FROM [MoenvEquipment_Photo] WHERE [Id] = @Id", conn))
                    {
                        cmd.Parameters.AddWithValue("@Id", photoId);
                        cmd.ExecuteNonQuery();
                    }
                }

                try
                {
                    string fileName = Path.GetFileName(relativePath.Replace("\\", "/"));
                    if (!string.IsNullOrEmpty(fileName) && equipId > 0)
                    {
                        string dir = GetUploadPhysicalDir(equipId);
                        if (!string.IsNullOrEmpty(dir))
                        {
                            string targetFile = Path.Combine(dir, fileName);
                            if (File.Exists(targetFile))
                            {
                                File.Delete(targetFile);
                            }
                        }
                    }
                }
                catch
                {
                }

                result["success"] = true;
                result["message"] = "照片已成功刪除";
            }
            catch (Exception ex)
            {
                result["message"] = "刪除照片失敗：" + ex.Message;
            }

            return js.Serialize(result);
        }

        public static string UpdateProjectType(int id, string projectType)
        {
            JavaScriptSerializer js = new JavaScriptSerializer();
            Dictionary<string, object> result = new Dictionary<string, object>();
            result["success"] = false;
            result["message"] = "";

            try
            {
                string cleanType = projectType != null ? projectType.Trim() : "營建";
                using (SqlConnection conn = new SqlConnection(GetConnStr()))
                {
                    conn.Open();
                    string sql = "UPDATE [MoenvEquipment] SET [ProjectType] = @ProjectType, [ModifyDate] = GETDATE() WHERE [Id] = @Id";
                    using (SqlCommand cmd = new SqlCommand(sql, conn))
                    {
                        cmd.Parameters.AddWithValue("@ProjectType", cleanType);
                        cmd.Parameters.AddWithValue("@Id", id);
                        int rows = cmd.ExecuteNonQuery();

                        if (rows == 0)
                        {
                            string sqlUnqualified = "UPDATE [MoenvEquipment_Unqualified] SET [ProjectType] = @ProjectType, [ModifyDate] = GETDATE() WHERE [Id] = @Id";
                            using (SqlCommand cmdUnq = new SqlCommand(sqlUnqualified, conn))
                            {
                                cmdUnq.Parameters.AddWithValue("@ProjectType", cleanType);
                                cmdUnq.Parameters.AddWithValue("@Id", id);
                                cmdUnq.ExecuteNonQuery();
                            }
                        }
                    }
                }

                result["success"] = true;
                result["message"] = "計畫類型已更新為：" + cleanType;
            }
            catch (Exception ex)
            {
                result["message"] = "更新計畫類型失敗：" + ex.Message;
            }

            return js.Serialize(result);
        }

        private void ProcessPhotoUpload()
        {
            Dictionary<string, object> result = new Dictionary<string, object>();
            result["success"] = false;
            result["message"] = "";

            try
            {
                string equipIdStr = Request.Form["equipId"];
                int equipId = 0;
                if (!int.TryParse(equipIdStr, out equipId) || equipId <= 0)
                {
                    result["message"] = "無效的機具代碼";
                    SendJsonResponse(result);
                    return;
                }

                if (Request.Files == null || Request.Files.Count == 0)
                {
                    result["message"] = "請選擇要上傳的照片檔案";
                    SendJsonResponse(result);
                    return;
                }

                string physicalDir = GetUploadPhysicalDir(equipId);
                if (!Directory.Exists(physicalDir))
                {
                    Directory.CreateDirectory(physicalDir);
                }

                List<Dictionary<string, object>> uploadedPhotos = new List<Dictionary<string, object>>();

                using (SqlConnection conn = new SqlConnection(GetConnStr()))
                {
                    conn.Open();

                    for (int i = 0; i < Request.Files.Count; i++)
                    {
                        HttpPostedFile file = Request.Files[i];
                        if (file == null || file.ContentLength == 0) continue;

                        string ext = Path.GetExtension(file.FileName).ToLower();
                        if (ext != ".jpg" && ext != ".png" && ext != ".jpeg" && ext != ".gif")
                        {
                            continue;
                        }

                        string newFileName = Guid.NewGuid().ToString("N") + ext;
                        string physicalPath = Path.Combine(physicalDir, newFileName);
                        string virtualPath = "/NTPCEPD_New/MoenvEquip/Uploads/" + equipId + "/" + newFileName;

                        file.SaveAs(physicalPath);

                        string sql = "INSERT INTO [MoenvEquipment_Photo] ([EquipmentId], [PhotoPath]) VALUES (@EquipId, @PhotoPath); SELECT SCOPE_IDENTITY();";
                        int newPhotoId = 0;
                        using (SqlCommand cmd = new SqlCommand(sql, conn))
                        {
                            cmd.Parameters.AddWithValue("@EquipId", equipId);
                            cmd.Parameters.AddWithValue("@PhotoPath", virtualPath);
                            newPhotoId = Convert.ToInt32(cmd.ExecuteScalar());
                        }

                        Dictionary<string, object> pObj = new Dictionary<string, object>();
                        pObj["Id"] = newPhotoId;
                        pObj["PhotoPath"] = virtualPath;
                        uploadedPhotos.Add(pObj);
                    }
                }

                result["success"] = true;
                result["photos"] = uploadedPhotos;
                result["message"] = "照片上傳成功";
            }
            catch (System.Threading.ThreadAbortException)
            {
                return;
            }
            catch (Exception ex)
            {
                result["message"] = "上傳照片失敗：" + ex.Message;
            }

            SendJsonResponse(result);
        }

        private void ExportExcelAction()
        {
            string dateFrom = Request["dateFrom"] != null ? Request["dateFrom"].Trim() : "";
            string dateTo = Request["dateTo"] != null ? Request["dateTo"].Trim() : "";
            string equipType = Request["equipType"] != null ? Request["equipType"].Trim() : "";
            string applyType = Request["applyType"] != null ? Request["applyType"].Trim() : "";
            string projectType = Request["projectType"] != null ? Request["projectType"].Trim() : "";
            string badgeLevel = Request["badgeLevel"] != null ? Request["badgeLevel"].Trim() : "";
            string qualifiedStatus = Request["qualifiedStatus"] != null ? Request["qualifiedStatus"].Trim() : "";
            string keyword = Request["keyword"] != null ? Request["keyword"].Trim() : "";

            try
            {
                using (SqlConnection conn = new SqlConnection(GetConnStr()))
                {
                    conn.Open();

                    string tableName = (badgeLevel == "未通過") ? "MoenvEquipment_Unqualified" : "MoenvEquipment";
                    bool excludeBadge = (badgeLevel == "未通過");

                    using (SqlCommand cmd = new SqlCommand())
                    {
                        cmd.Connection = conn;
                        string whereClause = BuildWhereClause(cmd, dateFrom, dateTo, equipType, applyType, projectType, badgeLevel, qualifiedStatus, keyword, excludeBadge);
                        string sql = "SELECT * FROM [" + tableName + "]" + whereClause + " ORDER BY [TestDate] DESC, [Id] DESC";
                        cmd.CommandText = sql;

                        DataTable dt = new DataTable();
                        using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                        {
                            da.Fill(dt);
                        }

                        HSSFWorkbook wb = new HSSFWorkbook();
                        ISheet ws = wb.CreateSheet("機具清冊資料");

                        ICellStyle hStyle = wb.CreateCellStyle();
                        IFont hFont = wb.CreateFont();
                        hFont.FontName = "微軟正黑體";
                        hFont.FontHeightInPoints = (short)11;
                        hFont.IsBold = true;
                        hFont.Color = HSSFColor.White.Index;
                        hStyle.SetFont(hFont);
                        hStyle.Alignment = HorizontalAlignment.Center;
                        hStyle.VerticalAlignment = VerticalAlignment.Center;
                        hStyle.FillForegroundColor = HSSFColor.DarkBlue.Index;
                        hStyle.FillPattern = FillPattern.SolidForeground;
                        hStyle.BorderBottom = NPOI.SS.UserModel.BorderStyle.Thin;
                        hStyle.BorderTop = NPOI.SS.UserModel.BorderStyle.Thin;
                        hStyle.BorderLeft = NPOI.SS.UserModel.BorderStyle.Thin;
                        hStyle.BorderRight = NPOI.SS.UserModel.BorderStyle.Thin;

                        ICellStyle dStyle = wb.CreateCellStyle();
                        IFont dFont = wb.CreateFont();
                        dFont.FontName = "微軟正黑體";
                        dFont.FontHeightInPoints = (short)10;
                        dStyle.SetFont(dFont);
                        dStyle.VerticalAlignment = VerticalAlignment.Center;
                        dStyle.BorderBottom = NPOI.SS.UserModel.BorderStyle.Thin;
                        dStyle.BorderTop = NPOI.SS.UserModel.BorderStyle.Thin;
                        dStyle.BorderLeft = NPOI.SS.UserModel.BorderStyle.Thin;
                        dStyle.BorderRight = NPOI.SS.UserModel.BorderStyle.Thin;

                        string[] headers = new string[]
                        {
                            "核發單位", "檢測縣市", "所有者名稱", "申請類型", "統一編號",
                            "計畫類型", "機具廠牌", "機具種類", "機械牌號碼", "機具年份",
                            "機具型式", "機具引擎編號", "排氣量(c.c)", "最大額定馬力(hp)", "最大額定功率轉速",
                            "檢測方式", "標章編號", "檢測值(m-1)", "複測值(m-1)", "檢測日期",
                            "核發日期", "標章等級", "標章狀態", "照片目錄ID", "是否完整"
                        };

                        string[] dbCols = new string[]
                        {
                            "IssuingUnit", "TestCounty", "OwnerName", "ApplyType", "TaxId",
                            "ProjectType", "Brand", "EquipType", "PlateNumber", "EquipYear",
                            "Model", "EngineNumber", "Displacement", "MaxHorsePower", "MaxPowerSpeed",
                            "TestMethod", "BadgeNumber", "TestValue", "RetestValue", "TestDate",
                            "IssueDate", "BadgeLevel", "BadgeStatus", "Id", "IsQualified"
                        };

                        IRow hRow = ws.CreateRow(0);
                        hRow.HeightInPoints = 24;
                        for (int c = 0; c < headers.Length; c++)
                        {
                            ICell cell = hRow.CreateCell(c);
                            cell.SetCellValue(headers[c]);
                            cell.CellStyle = hStyle;
                        }

                        for (int r = 0; r < dt.Rows.Count; r++)
                        {
                            IRow row = ws.CreateRow(r + 1);
                            row.HeightInPoints = 20;

                            for (int c = 0; c < dbCols.Length; c++)
                            {
                                string colName = dbCols[c];
                                object val = dt.Columns.Contains(colName) ? dt.Rows[r][colName] : DBNull.Value;
                                ICell cell = row.CreateCell(c);
                                cell.CellStyle = dStyle;

                                if (colName == "IsQualified")
                                {
                                    string rowBadge = (dt.Columns.Contains("BadgeLevel") && dt.Rows[r]["BadgeLevel"] != DBNull.Value)
                                        ? dt.Rows[r]["BadgeLevel"].ToString().Trim()
                                        : "";
                                    if (rowBadge == "未通過" || badgeLevel == "未通過")
                                    {
                                        cell.SetCellValue("");
                                    }
                                    else
                                    {
                                        bool isOk = (val != null && val != DBNull.Value) ? Convert.ToBoolean(val) : false;
                                        cell.SetCellValue(isOk ? "完整" : "不完整");
                                    }
                                }
                                else if (colName == "ProjectType")
                                {
                                    string pType = (val != null && val != DBNull.Value) ? val.ToString().Trim() : "";
                                    if (string.IsNullOrEmpty(pType))
                                    {
                                        pType = "營建";
                                    }
                                    cell.SetCellValue(pType);
                                }
                                else
                                {
                                    if (val != null && val != DBNull.Value)
                                    {
                                        cell.SetCellValue(val.ToString().Trim());
                                    }
                                    else
                                    {
                                        cell.SetCellValue("");
                                    }
                                }
                            }
                        }

                        int[] colWidths = new int[]
                        {
                            14, 12, 28, 14, 14,
                            12, 16, 16, 14, 12,
                            14, 18, 14, 18, 18,
                            14, 18, 14, 14, 14,
                            14, 12, 12, 14, 12
                        };
                        for (int c = 0; c < colWidths.Length; c++)
                        {
                            ws.SetColumnWidth(c, colWidths[c] * 256);
                        }

                        string fileName = string.Format("環境部機具清冊_{0:yyyyMMdd_HHmmss}.xls", DateTime.Now);
                        ExcelExportHelper.ExportToResponse(wb, fileName, Response);
                    }
                }
            }
            catch (System.Threading.ThreadAbortException)
            {
                return;
            }
            catch (Exception ex)
            {
                Response.Clear();
                Response.ContentType = "text/plain; charset=utf-8";
                Response.Write("匯出 Excel 失敗：" + ex.Message);
                if (Context != null && Context.ApplicationInstance != null)
                {
                    Context.ApplicationInstance.CompleteRequest();
                }
            }
        }

        private void SendJsonResponse(object data)
        {
            Response.Clear();
            Response.ContentType = "application/json; charset=utf-8";
            Response.ContentEncoding = new UTF8Encoding(true);
            Response.Write(json.Serialize(data));
            AjaxResponseHelper.CompleteRequest(Response, Context);
        }
    }
}

