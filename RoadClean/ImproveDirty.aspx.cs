using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Net;
using System.Net.Mail;
using System.Web;
using System.Web.Configuration;
using System.Web.Script.Serialization;
using System.Web.UI;
using NTPC_FEC.Helpers;

namespace NTPC_FEC.RoadClean
{
    public partial class ImproveDirty : Page
    {
        private JavaScriptSerializer json = new JavaScriptSerializer();

        public ImproveDirty()
        {
            this.json.MaxJsonLength = int.MaxValue;
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            // Ajax API 請求處理
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
                    Response.Write(json.Serialize(new { Success = false, Message = ex.Message }));
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
                    Response.Write(json.Serialize(new { Success = false, Message = "未知的操作指令" }));
                    break;
            }
        }

        // 1. 初始化頁面資料 (讀取案件詳情、通報資料、現場照片、既有改善照片)
        private void InitPageData()
        {
            string dirtyId = Request["id"];
            if (dirtyId != null) dirtyId = dirtyId.Trim();

            if (string.IsNullOrEmpty(dirtyId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "缺少通報案號參數" }));
                return;
            }

            string mode = Request["mode"];
            if (mode != null) mode = mode.ToLower();
            else mode = "edit";

            // 取得登入使用者資訊
            string loginUser = Session["LoginUser"] != null ? Session["LoginUser"].ToString() : "";
            string loginUserName = Session["UserName"] != null ? Session["UserName"].ToString() : "";

            if (string.IsNullOrEmpty(loginUserName) && !string.IsNullOrEmpty(loginUser))
            {
                loginUserName = GetUserNameById(loginUser);
            }

            if (string.IsNullOrEmpty(loginUser))
            {
                loginUser = "tester";
                loginUserName = "現場處理員";
            }

            string sql = @"
                SELECT 
                    RoadDirty_CaseMain.*,
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
                        ELSE '未回報類型' 
                    END AS KIND_Name,
                    CASE 
                        WHEN Show_ID IS NULL OR Show_ID = '' THEN Dirty_ID 
                        ELSE Show_ID 
                    END AS Show_ID_Txt
                FROM RoadDirty_CaseMain 
                WHERE Dirty_ID = @id";

            DataTable dt = DbHelper.ExecuteDataTable(sql, new SqlParameter("@id", dirtyId));
            if (dt.Rows.Count == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "查無此案件紀錄：" + dirtyId }));
                return;
            }

            DataRow row = dt.Rows[0];

            // 案件狀態判定
            int statusCode = 1; // 待通報派工
            string statusText = "待通報派工";
            string statusBadgeClass = "badge-secondary";

            if (row["SetCOM_Date"] != DBNull.Value)
            {
                if (row["Improve_Date"] == DBNull.Value)
                {
                    statusCode = 2; // 待改善回報
                    statusText = "待改善回報";
                    statusBadgeClass = "badge-warning";
                }
                else
                {
                    statusCode = 3; // 已完成改善
                    statusText = "已完成改善";
                    statusBadgeClass = "badge-success";
                }
            }

            bool isBack = false;
            if (row.Table.Columns.Contains("G_Back") && row["G_Back"] != DBNull.Value && row["G_Back"].ToString().Trim().ToUpper() == "Y")
            {
                isBack = true;
                statusText = "已退回通報";
                statusBadgeClass = "badge-danger";
            }

            // 是否已完工進入唯讀狀態
            bool isReadOnly = (mode == "read" || (statusCode == 3 && mode != "force_edit"));

            // 坐標轉換 (TWD97 轉 WGS84)
            double utmE = 0, utmN = 0, utmE1 = 0, utmN1 = 0;
            if (row["S_UTME"] != DBNull.Value) double.TryParse(row["S_UTME"].ToString(), out utmE);
            if (row["S_UTMN"] != DBNull.Value) double.TryParse(row["S_UTMN"].ToString(), out utmN);
            if (row.Table.Columns.Contains("S_UTME1") && row["S_UTME1"] != DBNull.Value) double.TryParse(row["S_UTME1"].ToString(), out utmE1);
            if (row.Table.Columns.Contains("S_UTMN1") && row["S_UTMN1"] != DBNull.Value) double.TryParse(row["S_UTMN1"].ToString(), out utmN1);

            double lat1 = 0, lon1 = 0, lat2 = 0, lon2 = 0;
            if (row.Table.Columns.Contains("Lat") && row["Lat"] != DBNull.Value) double.TryParse(row["Lat"].ToString(), out lat1);
            if (row.Table.Columns.Contains("Lon") && row["Lon"] != DBNull.Value) double.TryParse(row["Lon"].ToString(), out lon1);
            if ((lat1 <= 0 || lon1 <= 0) && utmE > 0 && utmN > 0) Twd97ToWgs84(utmE, utmN, out lat1, out lon1);

            if (row.Table.Columns.Contains("Lat1") && row["Lat1"] != DBNull.Value) double.TryParse(row["Lat1"].ToString(), out lat2);
            if (row.Table.Columns.Contains("Lon1") && row["Lon1"] != DBNull.Value) double.TryParse(row["Lon1"].ToString(), out lon2);
            if ((lat2 <= 0 || lon2 <= 0) && utmE1 > 0 && utmN1 > 0) Twd97ToWgs84(utmE1, utmN1, out lat2, out lon2);

            // 讀取硬碟中的現場照片與改善照片
            List<PhotoItemDto> dirtyPhotos = GetPhotosByPrefix(dirtyId, "疑似髒污點現場照片");
            List<PhotoItemDto> evidencePhotos = GetPhotosByPrefix(dirtyId, "佐證照片");
            List<PhotoItemDto> improvePhotos = GetPhotosByPrefix(dirtyId, "髒污點改善後照片");
            if (improvePhotos.Count == 0)
            {
                // 相容舊版名稱 "改善後照片"
                improvePhotos = GetPhotosByPrefix(dirtyId, "改善後照片");
            }
            List<PhotoItemDto> improveEvidencePhotos = GetPhotosByPrefix(dirtyId, "改善後佐證照片");

            // 建立疑似髒污點與改善後照片的配對結構 (Pair List)
            List<object> photoPairs = BuildPhotoPairs(dirtyPhotos, improvePhotos, "髒污點改善後照片");
            List<object> evidencePairs = BuildPhotoPairs(evidencePhotos, improveEvidencePhotos, "改善後佐證照片");

            string rptUser = row["Report_User"] != DBNull.Value ? row["Report_User"].ToString().Trim() : "";
            string rptUserName = row["Report_UserName"] != DBNull.Value ? row["Report_UserName"].ToString().Trim() : rptUser;

            string sUser = row["S_User"] != DBNull.Value ? row["S_User"].ToString().Trim() : "";
            string sUserName = row["S_UserName"] != DBNull.Value ? row["S_UserName"].ToString().Trim() : sUser;

            string gUser = row["G_User"] != DBNull.Value ? row["G_User"].ToString().Trim() : "";
            string gUserName = row["G_UserName"] != DBNull.Value ? row["G_UserName"].ToString().Trim() : gUser;

            string gMemo = row.Table.Columns.Contains("G_Memo") && row["G_Memo"] != DBNull.Value ? row["G_Memo"].ToString() : "";

            var result = new Dictionary<string, object>();
            result["DirtyId"] = dirtyId;
            result["ShowId"] = row["Show_ID_Txt"].ToString().Trim();
            result["ReportDate"] = row["Report_Date"] != DBNull.Value ? Convert.ToDateTime(row["Report_Date"]).ToString("yyyy-MM-dd HH:mm") : "";
            result["ReportUser"] = rptUser;
            result["ReportUserName"] = rptUserName;
            result["SetComDate"] = row["SetCOM_Date"] != DBNull.Value ? Convert.ToDateTime(row["SetCOM_Date"]).ToString("yyyy-MM-dd HH:mm") : "";
            result["S_User"] = sUser;
            result["S_UserName"] = sUserName;
            result["S_ComName"] = row["S_COM_NAME"] != DBNull.Value ? row["S_COM_NAME"].ToString().Trim() : "";
            result["G_ComName"] = row["G_COM_NAME"] != DBNull.Value ? row["G_COM_NAME"].ToString().Trim() : "";
            result["Kind"] = row["KIND"] != DBNull.Value ? row["KIND"].ToString().Trim() : "";
            result["KindName"] = row["KIND_Name"].ToString();
            result["Comm"] = row["COMM"] != DBNull.Value ? row["COMM"].ToString() : "";
            result["ImproveDate"] = row["Improve_Date"] != DBNull.Value ? Convert.ToDateTime(row["Improve_Date"]).ToString("yyyy-MM-dd HH:mm") : "";
            result["G_User"] = gUser;
            result["G_UserName"] = gUserName;
            result["G_Memo"] = gMemo;
            result["IsBack"] = isBack;
            result["StatusCode"] = statusCode;
            result["StatusText"] = statusText;
            result["StatusBadgeClass"] = statusBadgeClass;
            result["IsReadOnly"] = isReadOnly;
            result["CurrentUserId"] = loginUser;
            result["CurrentUserName"] = loginUserName;

            // 坐標資訊
            result["S_UTME"] = utmE;
            result["S_UTMN"] = utmN;
            result["Lat1"] = lat1;
            result["Lon1"] = lon1;
            result["S_UTME1"] = utmE1;
            result["S_UTMN1"] = utmN1;
            result["Lat2"] = lat2;
            result["Lon2"] = lon2;

            // 照片對照組合
            result["PhotoPairs"] = photoPairs;
            result["EvidencePairs"] = evidencePairs;

            Response.Write(json.Serialize(new { Success = true, Data = result }));
        }

        // 建立改善前與改善後的配對清單
        private List<object> BuildPhotoPairs(List<PhotoItemDto> beforePhotos, List<PhotoItemDto> afterPhotos, string defaultAfterPrefix)
        {
            var pairs = new List<object>();
            int maxCount = Math.Max(beforePhotos.Count, afterPhotos.Count);
            if (maxCount == 0 && beforePhotos.Count == 0)
            {
                return pairs;
            }

            for (int i = 0; i < maxCount; i++)
            {
                PhotoItemDto before = i < beforePhotos.Count ? beforePhotos[i] : null;
                PhotoItemDto after = null;

                // 優先依照檔名尾數編號匹配
                if (before != null)
                {
                    int seq = ExtractSequence(before.FileName);
                    if (seq > 0)
                    {
                        foreach (var af in afterPhotos)
                        {
                            if (ExtractSequence(af.FileName) == seq)
                            {
                                after = af;
                                break;
                            }
                        }
                    }
                }

                // 若未按編號配到，且尚未被使用，則按順序配對
                if (after == null && i < afterPhotos.Count)
                {
                    after = afterPhotos[i];
                }

                int currentSeq = i + 1;
                string afterTitle = defaultAfterPrefix + "_" + currentSeq;

                pairs.Add(new
                {
                    Index = currentSeq,
                    TargetTitle = afterTitle,
                    Before = before != null ? new { FileName = before.FileName, Url = before.Url, Title = before.Title } : null,
                    After = after != null ? new { FileName = after.FileName, Url = after.Url, Title = after.Title } : null
                });
            }

            return pairs;
        }

        private int ExtractSequence(string fileName)
        {
            if (string.IsNullOrEmpty(fileName)) return 0;
            string nameWithoutExt = Path.GetFileNameWithoutExtension(fileName);
            int lastUnderline = nameWithoutExt.LastIndexOf('_');
            if (lastUnderline >= 0 && lastUnderline < nameWithoutExt.Length - 1)
            {
                string numPart = nameWithoutExt.Substring(lastUnderline + 1);
                int seq = 0;
                if (int.TryParse(numPart, out seq))
                {
                    return seq;
                }
            }
            return 0;
        }

        // 讀取特定前綴的照片
        private List<PhotoItemDto> GetPhotosByPrefix(string dirtyId, string prefix)
        {
            var list = new List<PhotoItemDto>();
            string relDir = "/Upload/RoadDirtyPIC/" + dirtyId + "/";
            string physDir = Server.MapPath("~" + relDir);

            if (!Directory.Exists(physDir))
            {
                return list;
            }

            DirectoryInfo di = new DirectoryInfo(physDir);
            FileInfo[] files = di.GetFiles(prefix + "*.*");
            Array.Sort(files, delegate(FileInfo a, FileInfo b) { return a.Name.CompareTo(b.Name); });

            foreach (FileInfo f in files)
            {
                string ext = f.Extension.ToLower();
                if (ext == ".jpg" || ext == ".jpeg" || ext == ".png" || ext == ".gif")
                {
                    PhotoItemDto item = new PhotoItemDto();
                    item.FileName = f.Name;
                    item.Title = Path.GetFileNameWithoutExtension(f.Name);
                    item.Url = relDir + f.Name;
                    item.Size = f.Length;
                    item.LastModified = f.LastWriteTime.ToString("yyyy-MM-dd HH:mm");
                    list.Add(item);
                }
            }

            return list;
        }

        // 2. 儲存改善回報 (或退回通報)
        private void SaveImproveRecord()
        {
            string rawJson = null;
            using (var reader = new StreamReader(Request.InputStream))
            {
                rawJson = reader.ReadToEnd();
            }

            if (string.IsNullOrEmpty(rawJson))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "儲存內容不能為空" }));
                return;
            }

            ImproveSaveModel input = json.Deserialize<ImproveSaveModel>(rawJson);
            if (input == null)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "無效的儲存資料格式" }));
                return;
            }

            string dirtyId = input.DirtyId != null ? input.DirtyId.Trim() : "";
            if (string.IsNullOrEmpty(dirtyId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "通報案號不得為空" }));
                return;
            }

            string loginUser = Session["LoginUser"] != null ? Session["LoginUser"].ToString() : "tester";
            string loginUserName = Session["UserName"] != null ? Session["UserName"].ToString() : "";
            if (string.IsNullOrEmpty(loginUserName))
            {
                loginUserName = GetUserNameById(loginUser);
            }

            // 檢查案件是否存在
            string checkSql = "SELECT * FROM RoadDirty_CaseMain WHERE Dirty_ID = @id";
            DataTable dtCase = DbHelper.ExecuteDataTable(checkSql, new SqlParameter("@id", dirtyId));
            if (dtCase.Rows.Count == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "查無此通報案件：" + dirtyId }));
                return;
            }

            DataRow rowCase = dtCase.Rows[0];
            bool isBack = input.IsBack;

            // 實體照片儲存目錄
            string relDir = "/Upload/RoadDirtyPIC/" + dirtyId + "/";
            string physDir = Server.MapPath("~" + relDir);
            if (!Directory.Exists(physDir))
            {
                Directory.CreateDirectory(physDir);
            }

            // 儲存/刪除改善照片
            SavePhotos(physDir, input.ImprovePhotos);
            SavePhotos(physDir, input.EvidencePhotos);

            if (isBack)
            {
                // ==================== 退回通報模式 ====================
                string updateSql = @"
                    UPDATE RoadDirty_CaseMain SET 
                        G_User = @G_User,
                        Improve_Date = @Improve_Date,
                        G_Memo = @G_Memo,
                        G_Back = 'Y'
                    WHERE Dirty_ID = @Dirty_ID";

                DbHelper.ExecuteNonQuery(updateSql,
                    new SqlParameter("@G_User", loginUser),
                    new SqlParameter("@Improve_Date", DateTime.Now),
                    new SqlParameter("@G_Memo", input.G_Memo ?? "非本單位權責，退回通報"),
                    new SqlParameter("@Dirty_ID", dirtyId)
                );

                // 複製案件以供通報單位重新派工 (維持原系統商務邏輯)
                string newSeqId = CreateNewDirtyIdFromBack(dirtyId, rowCase, physDir);

                // 發送退回通報通知信
                SendNotificationEmail(dirtyId, true, input.G_Memo);

                Response.Write(json.Serialize(new
                {
                    Success = true,
                    Message = "案件已成功退回給通報單位重新派工處理！",
                    RedirectUrl = "Dirty_List.aspx?mode=DirtyImprove"
                }));
            }
            else
            {
                // ==================== 改善完成回報模式 ====================
                string updateSql = @"
                    UPDATE RoadDirty_CaseMain SET 
                        G_User = @G_User,
                        Improve_Date = @Improve_Date,
                        G_Memo = @G_Memo,
                        G_Back = NULL
                    WHERE Dirty_ID = @Dirty_ID";

                DbHelper.ExecuteNonQuery(updateSql,
                    new SqlParameter("@G_User", loginUser),
                    new SqlParameter("@Improve_Date", DateTime.Now),
                    new SqlParameter("@G_Memo", input.G_Memo ?? ""),
                    new SqlParameter("@Dirty_ID", dirtyId)
                );

                // 發送改善完成通知信
                SendNotificationEmail(dirtyId, false, input.G_Memo);

                Response.Write(json.Serialize(new
                {
                    Success = true,
                    Message = "道路污染改善回報已順利送出成功！",
                    RedirectUrl = "Dirty_List.aspx?mode=DirtyImprove"
                }));
            }
        }

        // 儲存或刪除照片檔案
        private void SavePhotos(string physDir, List<PhotoUploadItem> photos)
        {
            if (photos == null || photos.Count == 0) return;

            foreach (var item in photos)
            {
                if (item == null) continue;

                // 若標記為刪除
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

                // 若有新上傳的 Base64 檔案
                if (!string.IsNullOrEmpty(item.Base64Data))
                {
                    string targetFileName = !string.IsNullOrEmpty(item.FileName) 
                        ? item.FileName 
                        : (item.TargetTitle ?? "髒污點改善後照片_1") + ".jpg";

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

        // 退回通報時產生新案號並複製現場照片 (遵循原系統邏輯)
        private string CreateNewDirtyIdFromBack(string originDirtyId, DataRow originRow, string originPhysDir)
        {
            string datePrefix = DateTime.Now.ToString("yyyyMMdd");
            string timePrefix = DateTime.Now.ToString("HHmmss");
            string fullPrefix = datePrefix + timePrefix;

            string seqSql = "SELECT TOP 1 Dirty_ID FROM RoadDirty_CaseMain WHERE Dirty_ID LIKE @prefix + '%' ORDER BY Dirty_ID DESC";
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

            string newDirtyId = fullPrefix + string.Format("{0:000}", seq);

            DateTime rptDate = DateTime.Now;
            if (originRow["Report_Date"] != DBNull.Value) rptDate = Convert.ToDateTime(originRow["Report_Date"]);

            double utmE = 0, utmN = 0;
            if (originRow["S_UTME"] != DBNull.Value) double.TryParse(originRow["S_UTME"].ToString(), out utmE);
            if (originRow["S_UTMN"] != DBNull.Value) double.TryParse(originRow["S_UTMN"].ToString(), out utmN);

            string comm = originRow["COMM"] != DBNull.Value ? originRow["COMM"].ToString() : "";
            string rptUser = originRow["Report_User"] != DBNull.Value ? originRow["Report_User"].ToString().Trim() : "";

            double? originLat = null, originLon = null;
            if (originRow.Table.Columns.Contains("Lat") && originRow["Lat"] != DBNull.Value)
            {
                double p;
                if (double.TryParse(originRow["Lat"].ToString(), out p) && p > 0) originLat = p;
            }
            if (originRow.Table.Columns.Contains("Lon") && originRow["Lon"] != DBNull.Value)
            {
                double p;
                if (double.TryParse(originRow["Lon"].ToString(), out p) && p > 0) originLon = p;
            }
            if ((!originLat.HasValue || !originLon.HasValue) && utmE > 0 && utmN > 0)
            {
                double clat, clon;
                Twd97ToWgs84(utmE, utmN, out clat, out clon);
                originLat = clat;
                originLon = clon;
            }

            string insertSql = @"
                INSERT INTO RoadDirty_CaseMain 
                    (Dirty_ID, Show_ID, Report_Date, S_UTME, S_UTMN, Lat, Lon, COMM, Report_User, FromBack_ID) 
                VALUES 
                    (@Dirty_ID, @Show_ID, @Report_Date, @S_UTME, @S_UTMN, @Lat, @Lon, @COMM, @Report_User, @FromBack_ID)";

            DbHelper.ExecuteNonQuery(insertSql,
                new SqlParameter("@Dirty_ID", newDirtyId),
                new SqlParameter("@Show_ID", newDirtyId),
                new SqlParameter("@Report_Date", rptDate),
                new SqlParameter("@S_UTME", utmE),
                new SqlParameter("@S_UTMN", utmN),
                new SqlParameter("@Lat", originLat.HasValue ? (object)originLat.Value : DBNull.Value),
                new SqlParameter("@Lon", originLon.HasValue ? (object)originLon.Value : DBNull.Value),
                new SqlParameter("@COMM", comm),
                new SqlParameter("@Report_User", rptUser),
                new SqlParameter("@FromBack_ID", originDirtyId)
            );

            // 複製照片到新目錄
            string newRelDir = "/Upload/RoadDirtyPIC/" + newDirtyId + "/";
            string newPhysDir = Server.MapPath("~" + newRelDir);
            if (!Directory.Exists(newPhysDir))
            {
                Directory.CreateDirectory(newPhysDir);
            }

            if (Directory.Exists(originPhysDir))
            {
                DirectoryInfo di = new DirectoryInfo(originPhysDir);
                FileInfo[] files = di.GetFiles("疑似髒污點現場照片*.*");
                foreach (FileInfo f in files)
                {
                    try { f.CopyTo(Path.Combine(newPhysDir, f.Name), true); } catch { }
                }
            }

            return newDirtyId;
        }

        // 發送通知 Email (以安全 try-catch 包覆，不因網路中斷阻斷系統主要流程)
        private void SendNotificationEmail(string dirtyId, bool isBack, string gMemo)
        {
            try
            {
                string sql = @"
                    SELECT 
                        RoadDirty_CaseMain.*,
                        (SELECT TOP 1 Name FROM UserAcc WHERE UserAcc.UserID = RoadDirty_CaseMain.Report_User) AS Report_UserName,
                        (SELECT TOP 1 Name FROM UserAcc WHERE UserAcc.UserID = RoadDirty_CaseMain.S_User) AS S_UserName,
                        (SELECT TOP 1 UnitName FROM RoadDirty_Unit WHERE RoadDirty_Unit.UnitID = RoadDirty_CaseMain.S_COM) AS S_COM_NAME,
                        (SELECT TOP 1 UnitName FROM RoadDirty_Unit WHERE RoadDirty_Unit.UnitID = RoadDirty_CaseMain.G_COM) AS G_COM_NAME,
                        CASE 
                            WHEN KIND = 'EB' THEN '營建工程道路污染 (EB)' 
                            WHEN KIND = 'EF' THEN '固定逸散道路污染 (EF)' 
                            WHEN KIND = 'ES' THEN '道路砂石堆積污染 (ES)' 
                            ELSE '未回報類型' 
                        END AS KIND_Name,
                        CASE WHEN Show_ID IS NULL OR Show_ID = '' THEN Dirty_ID ELSE Show_ID END AS Show_ID_Txt
                    FROM RoadDirty_CaseMain 
                    WHERE Dirty_ID = @Dirty_ID";

                DataTable dt = DbHelper.ExecuteDataTable(sql, new SqlParameter("@Dirty_ID", dirtyId));
                if (dt.Rows.Count == 0) return;

                DataRow row = dt.Rows[0];
                string showId = row["Show_ID_Txt"].ToString();
                string sComName = row["S_COM_NAME"].ToString();
                string sComId = row["S_COM"] != DBNull.Value ? row["S_COM"].ToString().Trim() : "";
                string gComName = row["G_COM_NAME"].ToString();

                string subject = isBack
                    ? string.Format("道路污染通報單-非權責退回通知【通報案號:{0}】", showId)
                    : string.Format("道路污染通報單-改善完成通知【通報案號:{0}】", showId);

                string body = string.Format("{0}，您好：<br /><br />", sComName);
                if (isBack)
                {
                    body += string.Format("編號【{0}】的道路污染通報案件已被處理單位【{1}】判定非權責退回，煩請重新確認派工，謝謝。<br /><br />", showId, gComName);
                }
                else
                {
                    body += string.Format("編號【{0}】的道路污染通報案件已完成改善回報，煩請確認，謝謝。<br /><br />", showId);
                }

                string cellSty = " style='border:1px solid #cbd5e1; padding: 6px 10px;'";
                body += "<table style='border-collapse: collapse; font-size: 14px;'><tr><th colspan='2' style='background:#f1f5f9; padding:8px;'>詳細資料</th></tr>";
                body += string.Format("<tr><td{0}>通報案號</td><td{0}>{1}</td></tr>", cellSty, showId);
                body += string.Format("<tr><td{0}>查核時間</td><td{0}>{1}</td></tr>", cellSty, row["Report_Date"]);
                body += string.Format("<tr><td{0}>查核人員</td><td{0}>{1}</td></tr>", cellSty, row["Report_UserName"]);
                body += string.Format("<tr><td{0}>通報單位</td><td{0}>{1}</td></tr>", cellSty, sComName);
                body += string.Format("<tr><td{0}>通報人員</td><td{0}>{1}</td></tr>", cellSty, row["S_UserName"]);
                body += string.Format("<tr><td{0}>通報類別</td><td{0}>{1}</td></tr>", cellSty, row["KIND_Name"]);
                body += string.Format("<tr><td{0}>處理單位</td><td{0}>{1}</td></tr>", cellSty, gComName);
                body += string.Format("<tr><td{0}>處理備註</td><td{0}>{1}</td></tr>", cellSty, gMemo);

                if (isBack)
                {
                    body += string.Format("<tr><td{0}>狀態</td><td{0} style='color:red; font-weight:bold;'>非處理單位權責案件，已退回</td></tr>", cellSty);
                }
                body += "</table>";
                body += string.Format("<br /><br />{0} 敬上", gComName);

                if (string.IsNullOrEmpty(sComId)) return;

                // 查詢通報單位人員信箱
                string userSql = @"
                    SELECT RoadDirty_UnitUser.UserEmail 
                    FROM RoadDirty_UnitUser 
                    WHERE RoadDirty_UnitUser.UnitID = @UnitID AND RoadDirty_UnitUser.UserEmail IS NOT NULL AND RoadDirty_UnitUser.UserEmail <> ''";

                DataTable dtUsers = DbHelper.ExecuteDataTable(userSql, new SqlParameter("@UnitID", sComId));
                if (dtUsers.Rows.Count == 0) return;

                string host = WebConfigurationManager.AppSettings["SMTPserver"];
                string fromAddr = WebConfigurationManager.AppSettings["EmailAddr"];
                string user = WebConfigurationManager.AppSettings["SMTP_User"];
                string pass = WebConfigurationManager.AppSettings["SMTP_Password"];

                if (string.IsNullOrEmpty(host) || string.IsNullOrEmpty(fromAddr)) return;

                SmtpClient client = new SmtpClient(host, 587);
                if (!string.IsNullOrEmpty(user) && !string.IsNullOrEmpty(pass))
                {
                    client.Credentials = new NetworkCredential(user, pass);
                }

                foreach (DataRow uRow in dtUsers.Rows)
                {
                    string targetEmail = uRow["UserEmail"].ToString().Trim();
                    if (string.IsNullOrEmpty(targetEmail)) continue;

                    try
                    {
                        MailMessage msg = new MailMessage();
                        msg.From = new MailAddress(fromAddr);
                        msg.To.Add(new MailAddress(targetEmail));
                        msg.Subject = subject;
                        msg.Body = body;
                        msg.IsBodyHtml = true;
                        client.Send(msg);
                    }
                    catch { }
                }
            }
            catch { }
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

        // ==================== DTO 類別定義 (符合 C# 5.0，無自動屬性初始化) ====================
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

        public class ImproveSaveModel
        {
            public string DirtyId { get; set; }
            public string G_Memo { get; set; }
            public bool IsBack { get; set; }
            public List<PhotoUploadItem> ImprovePhotos { get; set; }
            public List<PhotoUploadItem> EvidencePhotos { get; set; }

            public ImproveSaveModel()
            {
                this.ImprovePhotos = new List<PhotoUploadItem>();
                this.EvidencePhotos = new List<PhotoUploadItem>();
            }
        }
    }
}
