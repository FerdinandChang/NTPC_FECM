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
using NTPC_FEC.Helpers;
using NTPC_FEC.Models;
using NTPC_FEC.Services;

namespace NTPC_FEC.Wash
{
    public partial class DataInput : Page
    {
        private JavaScriptSerializer json;

        public DataInput()
        {
            json = new JavaScriptSerializer();
            json.MaxJsonLength = int.MaxValue;
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
                case "getinitialdata":
                    GetInitialData();
                    break;
                case "save":
                    SaveData();
                    break;
                default:
                    Response.Write(json.Serialize(new { Success = false, Message = "未知的操作指令：" + action }));
                    break;
            }
        }

        // 檢查 MD5 安全驗證碼 (容許當前小時與前一小時容錯；若已登入 Session 亦允許通行)
        private bool VerifySecurityToken(string facId, string token)
        {
            if (Session["LoginUser"] != null || (User != null && User.Identity != null && User.Identity.IsAuthenticated))
            {
                return true;
            }

            if (string.IsNullOrEmpty(token) || string.IsNullOrEmpty(facId))
            {
                return false;
            }

            string expectedCurrent = ComputeMd5("MD5:" + facId + DateTime.Now.ToString("yyyyMMddHH"));
            string expectedPrev = ComputeMd5("MD5:" + facId + DateTime.Now.AddHours(-1).ToString("yyyyMMddHH"));

            return string.Equals(token, expectedCurrent, StringComparison.OrdinalIgnoreCase) ||
                   string.Equals(token, expectedPrev, StringComparison.OrdinalIgnoreCase);
        }

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

        // 取得初始化資訊 (認養單位清單、當前填報設定、歷史紀錄)
        private void GetInitialData()
        {
            string facId = Request["id"];
            if (facId != null) facId = facId.Trim();
            string token = Request["id1"];
            string pIndexStr = Request["id2"];
            string mode = Request["mode"];
            if (string.IsNullOrEmpty(mode)) mode = "new";
            mode = mode.ToLower();

            int pIndex = 0;
            if (!string.IsNullOrEmpty(pIndexStr))
            {
                int.TryParse(pIndexStr, out pIndex);
            }

            // 1. 權限檢查與取得當前使用者身分
            UserAccount currentUser = Session["UserAccount"] as UserAccount;
            string loginUserId = Session["LoginUser"] as string;
            bool isManager = false;
            string userFacId = string.Empty;
            string defaultUserName = string.Empty;

            if (currentUser != null)
            {
                isManager = MenuService.CheckLicense(currentUser.Lic, 9);
                userFacId = currentUser.FacID != null ? currentUser.FacID.Trim() : string.Empty;
                defaultUserName = currentUser.Name != null ? currentUser.Name.Trim() : string.Empty;
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
                    defaultUserName = r["Name"] != DBNull.Value ? r["Name"].ToString().Trim() : string.Empty;
                }
            }

            // 若非管理員且帳號已綁定工廠，強制鎖定其事業管制編號
            if (!isManager && !string.IsNullOrEmpty(userFacId))
            {
                facId = userFacId;
            }

            // 若尚未指定 facId，先從清單取第一筆或使用者所屬的工廠
            if (string.IsNullOrEmpty(facId))
            {
                if (!string.IsNullOrEmpty(userFacId))
                {
                    facId = userFacId;
                }
            }

            // 2. 載入所有認養事業單位清單
            string sqlFac = "SELECT FAC_ID, FAC_NAME FROM FAC_Main ORDER BY FAC_NAME";
            DataTable dtFac = DbHelper.ExecuteDataTable(sqlFac);
            List<object> facList = new List<object>();
            string currentFacName = string.Empty;

            foreach (DataRow row in dtFac.Rows)
            {
                string fId = row["FAC_ID"].ToString().Trim();
                string fName = row["FAC_NAME"].ToString().Trim();
                if (string.IsNullOrEmpty(facId))
                {
                    facId = fId;
                }
                if (string.Equals(fId, facId, StringComparison.OrdinalIgnoreCase))
                {
                    currentFacName = fName;
                }
                facList.Add(new
                {
                    FacId = fId,
                    FacName = fName
                });
            }

            // 3. 安全驗證 Token (若有傳入則檢驗)
            if (!string.IsNullOrEmpty(token) && !VerifySecurityToken(facId, token))
            {
                Response.Write(json.Serialize(new
                {
                    Success = false,
                    Message = "安全校驗碼無效或已逾期，請由洗掃清單重新進入。"
                }));
                return;
            }

            // 4. 裝載表單初始資料模型
            object recordData = null;
            object beforePhoto = null;
            object afterPhoto = null;

            if (mode == "edit" && pIndex > 0)
            {
                string sqlRecord = @"SELECT [pID], [FAC_ID], [pIndex], [WashDate], 
                                     CONVERT(VARCHAR(5), [WashTime_Start], 108) AS WashTime_Start, 
                                     CONVERT(VARCHAR(5), [WashTime_End], 108) AS WashTime_End, 
                                     [WashType], [Length1], [Length2], [PPL] 
                                     FROM RoadWash_Data 
                                     WHERE FAC_ID = @FAC_ID AND pIndex = @pIndex";
                DataTable dtRec = DbHelper.ExecuteDataTable(sqlRecord,
                    new SqlParameter("@FAC_ID", facId),
                    new SqlParameter("@pIndex", pIndex));

                if (dtRec.Rows.Count > 0)
                {
                    DataRow r = dtRec.Rows[0];
                    string washDateStr = string.Empty;
                    if (r["WashDate"] != DBNull.Value)
                    {
                        DateTime wd;
                        if (DateTime.TryParse(r["WashDate"].ToString(), out wd))
                        {
                            washDateStr = wd.ToString("yyyy-MM-dd");
                        }
                    }

                    int len1 = 0, len2 = 0;
                    if (r["Length1"] != DBNull.Value) int.TryParse(r["Length1"].ToString(), out len1);
                    if (r["Length2"] != DBNull.Value) int.TryParse(r["Length2"].ToString(), out len2);

                    recordData = new
                    {
                        PID = r["pID"] != DBNull.Value ? Convert.ToInt32(r["pID"]) : 0,
                        FAC_ID = facId,
                        PIndex = pIndex,
                        WashDate = washDateStr,
                        WashTime_Start = r["WashTime_Start"] != DBNull.Value ? r["WashTime_Start"].ToString().Trim() : string.Empty,
                        WashTime_End = r["WashTime_End"] != DBNull.Value ? r["WashTime_End"].ToString().Trim() : string.Empty,
                        WashType = r["WashType"] != DBNull.Value ? r["WashType"].ToString().Trim() : "洗",
                        Length1 = len1,
                        Length2 = len2,
                        PPL = r["PPL"] != DBNull.Value ? r["PPL"].ToString().Trim() : string.Empty
                    };

                    // 檢查伺服器儲存的現場照片
                    string picDirVirtual = "/NTPC_FEC/Upload/WashPIC/" + facId + "/" + pIndex;
                    string picDirPhysical = Server.MapPath(picDirVirtual);
                    if (Directory.Exists(picDirPhysical))
                    {
                        DirectoryInfo di = new DirectoryInfo(picDirPhysical);
                        FileInfo[] beforeFiles = di.GetFiles("洗掃前照片.*");
                        if (beforeFiles.Length > 0)
                        {
                            beforePhoto = new
                            {
                                Exists = true,
                                FileName = beforeFiles[0].Name,
                                Url = picDirVirtual + "/" + beforeFiles[0].Name + "?t=" + beforeFiles[0].LastWriteTime.Ticks,
                                Size = beforeFiles[0].Length
                            };
                        }

                        FileInfo[] afterFiles = di.GetFiles("洗掃後照片.*");
                        if (afterFiles.Length > 0)
                        {
                            afterPhoto = new
                            {
                                Exists = true,
                                FileName = afterFiles[0].Name,
                                Url = picDirVirtual + "/" + afterFiles[0].Name + "?t=" + afterFiles[0].LastWriteTime.Ticks,
                                Size = afterFiles[0].Length
                            };
                        }
                    }
                }
            }

            // 預設為全新填報狀態
            if (recordData == null)
            {
                recordData = new
                {
                    PID = 0,
                    FAC_ID = facId,
                    PIndex = 0,
                    WashDate = DateTime.Now.ToString("yyyy-MM-dd"),
                    WashTime_Start = "08:30",
                    WashTime_End = "12:00",
                    WashType = "洗",
                    Length1 = 0,
                    Length2 = 0,
                    PPL = defaultUserName
                };
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                IsManager = isManager,
                UserFacId = userFacId,
                CurrentFacId = facId,
                CurrentFacName = currentFacName,
                FacList = facList,
                Record = recordData,
                BeforePhoto = beforePhoto,
                AfterPhoto = afterPhoto,
                Mode = mode
            }));
        }

        // 儲存日誌紀錄 (支援全新新增與修改，並同步處理 Base64 照片存檔)
        private void SaveData()
        {
            string rawBody = string.Empty;
            using (StreamReader sr = new StreamReader(Request.InputStream, Encoding.UTF8))
            {
                rawBody = sr.ReadToEnd();
            }

            if (string.IsNullOrEmpty(rawBody))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "未接收到儲存內容。" }));
                return;
            }

            Dictionary<string, object> data = json.Deserialize<Dictionary<string, object>>(rawBody);
            if (data == null)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "無法解析資料格式。" }));
                return;
            }

            string mode = data.ContainsKey("mode") && data["mode"] != null ? data["mode"].ToString().ToLower() : "new";
            string facId = data.ContainsKey("facId") && data["facId"] != null ? data["facId"].ToString().Trim() : string.Empty;
            string washDateStr = data.ContainsKey("washDate") && data["washDate"] != null ? data["washDate"].ToString().Trim() : string.Empty;
            string washTimeStart = data.ContainsKey("washTimeStart") && data["washTimeStart"] != null ? data["washTimeStart"].ToString().Trim() : string.Empty;
            string washTimeEnd = data.ContainsKey("washTimeEnd") && data["washTimeEnd"] != null ? data["washTimeEnd"].ToString().Trim() : string.Empty;
            string washType = data.ContainsKey("washType") && data["washType"] != null ? data["washType"].ToString().Trim() : "洗";
            string ppl = data.ContainsKey("ppl") && data["ppl"] != null ? data["ppl"].ToString().Trim() : string.Empty;

            int pIndex = 0;
            if (data.ContainsKey("pIndex") && data["pIndex"] != null)
            {
                int.TryParse(data["pIndex"].ToString(), out pIndex);
            }

            int length1 = 0, length2 = 0;
            if (data.ContainsKey("length1") && data["length1"] != null)
            {
                int.TryParse(data["length1"].ToString(), out length1);
            }
            if (data.ContainsKey("length2") && data["length2"] != null)
            {
                int.TryParse(data["length2"].ToString(), out length2);
            }

            // 欄位基礎驗證
            if (string.IsNullOrEmpty(facId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "請選擇認養事業單位！" }));
                return;
            }

            DateTime washDate;
            if (!DateTime.TryParse(washDateStr, out washDate))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "請輸入有效的洗掃日期！" }));
                return;
            }

            if (length1 < 0 || length2 < 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "洗掃街長度不可為負數！" }));
                return;
            }

            // 權限防護：非管理者嚴禁竄改非所屬工廠之資料
            UserAccount currentUser = Session["UserAccount"] as UserAccount;
            if (currentUser != null && !MenuService.CheckLicense(currentUser.Lic, 9))
            {
                if (!string.IsNullOrEmpty(currentUser.FacID) && !string.Equals(currentUser.FacID.Trim(), facId, StringComparison.OrdinalIgnoreCase))
                {
                    Response.Write(json.Serialize(new { Success = false, Message = "權限不足：您只能填報自身列管廠場之洗掃紀錄！" }));
                    return;
                }
            }

            if (mode == "new")
            {
                // 取得目前該事業單位的最大 pIndex 序號
                string sqlMax = "SELECT ISNULL(MAX(pIndex), 0) FROM RoadWash_Data WHERE FAC_ID = @FAC_ID";
                int maxIndex = Convert.ToInt32(DbHelper.ExecuteScalar(sqlMax, new SqlParameter("@FAC_ID", facId)));
                pIndex = maxIndex + 1;

                string sqlInsert = @"INSERT INTO RoadWash_Data 
                                     (FAC_ID, pIndex, WashDate, WashType, PPL, Length1, Length2, WashTime_Start, WashTime_End) 
                                     VALUES 
                                     (@FAC_ID, @pIndex, @WashDate, @WashType, @PPL, @Length1, @Length2, @WashTime_Start, @WashTime_End)";

                List<SqlParameter> pList = new List<SqlParameter>();
                pList.Add(new SqlParameter("@FAC_ID", facId));
                pList.Add(new SqlParameter("@pIndex", pIndex));
                pList.Add(new SqlParameter("@WashDate", washDate));
                pList.Add(new SqlParameter("@WashType", washType));
                pList.Add(new SqlParameter("@PPL", (object)ppl ?? DBNull.Value));
                pList.Add(new SqlParameter("@Length1", length1));
                pList.Add(new SqlParameter("@Length2", length2));

                if (!string.IsNullOrEmpty(washTimeStart))
                    pList.Add(new SqlParameter("@WashTime_Start", washTimeStart));
                else
                    pList.Add(new SqlParameter("@WashTime_Start", DBNull.Value));

                if (!string.IsNullOrEmpty(washTimeEnd))
                    pList.Add(new SqlParameter("@WashTime_End", washTimeEnd));
                else
                    pList.Add(new SqlParameter("@WashTime_End", DBNull.Value));

                DbHelper.ExecuteNonQuery(sqlInsert, pList.ToArray());
            }
            else
            {
                // 編輯更新既有紀錄
                if (pIndex <= 0)
                {
                    Response.Write(json.Serialize(new { Success = false, Message = "無效的紀錄序號 (pIndex)！" }));
                    return;
                }

                string sqlUpdate = @"UPDATE RoadWash_Data 
                                     SET WashDate = @WashDate, 
                                         WashType = @WashType, 
                                         PPL = @PPL, 
                                         Length1 = @Length1, 
                                         Length2 = @Length2, 
                                         WashTime_Start = @WashTime_Start, 
                                         WashTime_End = @WashTime_End 
                                     WHERE FAC_ID = @FAC_ID AND pIndex = @pIndex";

                List<SqlParameter> pList = new List<SqlParameter>();
                pList.Add(new SqlParameter("@WashDate", washDate));
                pList.Add(new SqlParameter("@WashType", washType));
                pList.Add(new SqlParameter("@PPL", (object)ppl ?? DBNull.Value));
                pList.Add(new SqlParameter("@Length1", length1));
                pList.Add(new SqlParameter("@Length2", length2));

                if (!string.IsNullOrEmpty(washTimeStart))
                    pList.Add(new SqlParameter("@WashTime_Start", washTimeStart));
                else
                    pList.Add(new SqlParameter("@WashTime_Start", DBNull.Value));

                if (!string.IsNullOrEmpty(washTimeEnd))
                    pList.Add(new SqlParameter("@WashTime_End", washTimeEnd));
                else
                    pList.Add(new SqlParameter("@WashTime_End", DBNull.Value));

                pList.Add(new SqlParameter("@FAC_ID", facId));
                pList.Add(new SqlParameter("@pIndex", pIndex));

                DbHelper.ExecuteNonQuery(sqlUpdate, pList.ToArray());
            }

            // 處理照片儲存與刪除
            string targetDirVirtual = "/NTPC_FEC/Upload/WashPIC/" + facId + "/" + pIndex;
            string targetDirPhysical = Server.MapPath(targetDirVirtual);
            if (!Directory.Exists(targetDirPhysical))
            {
                Directory.CreateDirectory(targetDirPhysical);
            }

            // 1. 洗掃前照片
            bool delBefore = data.ContainsKey("deleteBeforePhoto") && Convert.ToBoolean(data["deleteBeforePhoto"]);
            string beforeBase64 = data.ContainsKey("beforePhotoBase64") && data["beforePhotoBase64"] != null ? data["beforePhotoBase64"].ToString() : string.Empty;
            string beforeExt = data.ContainsKey("beforePhotoExt") && data["beforePhotoExt"] != null ? data["beforePhotoExt"].ToString().Trim() : "jpg";

            if (delBefore || !string.IsNullOrEmpty(beforeBase64))
            {
                DeleteExistingPhotos(targetDirPhysical, "洗掃前照片");
            }
            if (!string.IsNullOrEmpty(beforeBase64))
            {
                SaveBase64Image(beforeBase64, Path.Combine(targetDirPhysical, "洗掃前照片." + beforeExt.TrimStart('.')));
            }

            // 2. 洗掃後照片
            bool delAfter = data.ContainsKey("deleteAfterPhoto") && Convert.ToBoolean(data["deleteAfterPhoto"]);
            string afterBase64 = data.ContainsKey("afterPhotoBase64") && data["afterPhotoBase64"] != null ? data["afterPhotoBase64"].ToString() : string.Empty;
            string afterExt = data.ContainsKey("afterPhotoExt") && data["afterPhotoExt"] != null ? data["afterPhotoExt"].ToString().Trim() : "jpg";

            if (delAfter || !string.IsNullOrEmpty(afterBase64))
            {
                DeleteExistingPhotos(targetDirPhysical, "洗掃後照片");
            }
            if (!string.IsNullOrEmpty(afterBase64))
            {
                SaveBase64Image(afterBase64, Path.Combine(targetDirPhysical, "洗掃後照片." + afterExt.TrimStart('.')));
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                Message = mode == "new" ? "洗掃街日誌紀錄已成功新增！" : "洗掃街日誌紀錄已成功更新！",
                FacId = facId,
                PIndex = pIndex
            }));
        }

        private void DeleteExistingPhotos(string dirPhysical, string prefix)
        {
            try
            {
                if (!Directory.Exists(dirPhysical)) return;
                DirectoryInfo di = new DirectoryInfo(dirPhysical);
                FileInfo[] files = di.GetFiles(prefix + ".*");
                for (int i = 0; i < files.Length; i++)
                {
                    files[i].Delete();
                }
            }
            catch
            {
            }
        }

        private void SaveBase64Image(string base64Data, string targetFilePath)
        {
            try
            {
                if (string.IsNullOrEmpty(base64Data)) return;

                // 若包含 data:image/...;base64, 標頭則剝除
                int commaIndex = base64Data.IndexOf(',');
                if (commaIndex >= 0)
                {
                    base64Data = base64Data.Substring(commaIndex + 1);
                }

                byte[] bytes = Convert.FromBase64String(base64Data);
                File.WriteAllBytes(targetFilePath, bytes);
            }
            catch (Exception ex)
            {
                throw new Exception("儲存照片檔案失敗：" + ex.Message);
            }
        }
    }
}
