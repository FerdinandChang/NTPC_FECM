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

namespace NTPC_FEC.BareGround
{
    public partial class NewBare : Page
    {
        private JavaScriptSerializer json;

        public NewBare()
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
                        Message = "系統發生例外：" + ex.Message
                    }));
                }
                Response.End();
                return;
            }
        }

        private string GetCurrentUser()
        {
            if (Session["LoginUser"] != null && !string.IsNullOrEmpty(Session["LoginUser"].ToString()))
            {
                return Session["LoginUser"].ToString().Trim();
            }
            if (User != null && User.Identity != null && !string.IsNullOrEmpty(User.Identity.Name))
            {
                return User.Identity.Name;
            }
            return "系統查核員";
        }

        private void HandleAjaxAction(string action)
        {
            switch (action.ToLower())
            {
                case "getinit":
                    GetInitData();
                    break;
                case "getbaremain":
                    GetBareMain(Request["bareId"]);
                    break;
                case "getcase":
                    GetCaseData(Request["bareId"], Request["invNo"]);
                    break;
                case "save":
                    SaveCase();
                    break;
                default:
                    Response.Write(json.Serialize(new { Success = false, Message = "未知的操作指令：" + action }));
                    break;
            }
        }

        // 1. 取得頁面初始選單與資料
        private void GetInitData()
        {
            var bareList = new List<object>();

            try
            {
                string sql = "SELECT Bare_ID, BareGroundNo, ADDR, Land_USE, Latitude, Longtitude FROM Bare_Main ORDER BY Bare_ID DESC";
                DataTable dt = DbHelper.ExecuteDataTable(sql);
                foreach (DataRow row in dt.Rows)
                {
                    bareList.Add(new
                    {
                        Bare_ID = row["Bare_ID"].ToString().Trim(),
                        BareGroundNo = row["BareGroundNo"] != DBNull.Value ? row["BareGroundNo"].ToString().Trim() : "",
                        ADDR = row["ADDR"] != DBNull.Value ? row["ADDR"].ToString().Trim() : "",
                        Land_USE = row["Land_USE"] != DBNull.Value ? row["Land_USE"].ToString().Trim() : "",
                        Latitude = row["Latitude"] != DBNull.Value ? row["Latitude"].ToString().Trim() : "",
                        Longtitude = row["Longtitude"] != DBNull.Value ? row["Longtitude"].ToString().Trim() : ""
                    });
                }
            }
            catch (Exception)
            {
                // 資料表讀取容錯
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                CurrentUser = GetCurrentUser(),
                DefaultDate = DateTime.Now.ToString("yyyy-MM-dd"),
                DefaultTime = DateTime.Now.ToString("HH:mm"),
                BareSites = bareList
            }));
        }

        // 2. 取得特定場址基本資料
        private void GetBareMain(string bareId)
        {
            if (string.IsNullOrEmpty(bareId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "未提供場址代碼" }));
                return;
            }

            string sql = "SELECT * FROM Bare_Main WHERE Bare_ID = @Bare_ID";
            DataTable dt = DbHelper.ExecuteDataTable(sql, new SqlParameter("@Bare_ID", bareId.Trim()));
            if (dt.Rows.Count == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "查無此場址基本資料" }));
                return;
            }

            DataRow row = dt.Rows[0];
            Response.Write(json.Serialize(new
            {
                Success = true,
                Data = new
                {
                    Bare_ID = row["Bare_ID"].ToString().Trim(),
                    BareGroundNo = row["BareGroundNo"] != DBNull.Value ? row["BareGroundNo"].ToString().Trim() : "",
                    ADDR = row["ADDR"] != DBNull.Value ? row["ADDR"].ToString().Trim() : "",
                    Land_USE = row["Land_USE"] != DBNull.Value ? row["Land_USE"].ToString().Trim() : "",
                    Latitude = row["Latitude"] != DBNull.Value ? row["Latitude"].ToString().Trim() : "",
                    Longtitude = row["Longtitude"] != DBNull.Value ? row["Longtitude"].ToString().Trim() : ""
                }
            }));
        }

        // 3. 取得既有查核紀錄 (包含主檔、巡查明細、照片、簽名)
        private void GetCaseData(string bareId, string invNoStr)
        {
            if (string.IsNullOrEmpty(bareId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "缺少場址代碼 (Bare_ID)" }));
                return;
            }

            int invNo = 0;
            int.TryParse(invNoStr, out invNo);

            // 1. 讀取場址主檔
            string sqlMain = "SELECT * FROM Bare_Main WHERE Bare_ID = @Bare_ID";
            DataTable dtMain = DbHelper.ExecuteDataTable(sqlMain, new SqlParameter("@Bare_ID", bareId.Trim()));
            if (dtMain.Rows.Count == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "查無此場址資料" }));
                return;
            }

            DataRow rMain = dtMain.Rows[0];

            // 2. 讀取巡查明細
            DataRow rInv = null;
            if (invNo > 0)
            {
                string sqlInv = "SELECT * FROM Bare_INV WHERE Bare_ID = @Bare_ID AND INV_NO = @INV_NO";
                DataTable dtInv = DbHelper.ExecuteDataTable(sqlInv,
                    new SqlParameter("@Bare_ID", bareId.Trim()),
                    new SqlParameter("@INV_NO", invNo));
                if (dtInv.Rows.Count > 0)
                {
                    rInv = dtInv.Rows[0];
                }
            }
            else
            {
                // 若未指定 invNo，自動讀取最新一筆
                string sqlLatest = "SELECT TOP 1 * FROM Bare_INV WHERE Bare_ID = @Bare_ID ORDER BY INV_NO DESC";
                DataTable dtLatest = DbHelper.ExecuteDataTable(sqlLatest, new SqlParameter("@Bare_ID", bareId.Trim()));
                if (dtLatest.Rows.Count > 0)
                {
                    rInv = dtLatest.Rows[0];
                    if (rInv["INV_NO"] != DBNull.Value)
                    {
                        int.TryParse(rInv["INV_NO"].ToString(), out invNo);
                    }
                }
            }

            // 日期時間拆解
            string checkDateStr = DateTime.Now.ToString("yyyy-MM-dd");
            string checkTimeStr = DateTime.Now.ToString("HH:mm");
            string aroundMemo = "";
            string wasteType = "";
            string surroundings = "";
            string pLength = "";
            string pWidth = "";
            string pHeight = "";
            string pVolume = "";
            string pArea = "";
            string inputUser = "";
            string invState = "";

            if (rInv != null)
            {
                if (rInv["Check_Date"] != DBNull.Value)
                {
                    DateTime dtCheck;
                    if (DateTime.TryParse(rInv["Check_Date"].ToString(), out dtCheck))
                    {
                        checkDateStr = dtCheck.ToString("yyyy-MM-dd");
                        checkTimeStr = dtCheck.ToString("HH:mm");
                    }
                }

                aroundMemo = rInv["Around_Memo"] != DBNull.Value ? rInv["Around_Memo"].ToString().Replace("<br />", "\r\n").Replace("<br>", "\r\n") : "";
                wasteType = rInv["Waste_Type"] != DBNull.Value ? rInv["Waste_Type"].ToString().Replace("<br />", "\r\n").Replace("<br>", "\r\n") : "";
                surroundings = rInv["surroundings"] != DBNull.Value ? rInv["surroundings"].ToString().Replace("<br />", "\r\n").Replace("<br>", "\r\n") : "";

                pLength = rInv["pLength"] != DBNull.Value ? rInv["pLength"].ToString() : "";
                pWidth = rInv["pWidth"] != DBNull.Value ? rInv["pWidth"].ToString() : "";
                pHeight = rInv["pHeight"] != DBNull.Value ? rInv["pHeight"].ToString() : "";
                pVolume = rInv["pVolume"] != DBNull.Value ? rInv["pVolume"].ToString() : "";
                pArea = rInv["pArea"] != DBNull.Value ? rInv["pArea"].ToString() : "";
                inputUser = rInv["InputUser"] != DBNull.Value ? rInv["InputUser"].ToString().Trim() : "";
                invState = rInv["INV_State"] != DBNull.Value ? rInv["INV_State"].ToString().Trim() : "";
            }

            // 讀取現場照片 (一) ~ (四)
            var photos = new List<object>();
            string targetDir = Server.MapPath(string.Format("~/Upload/BareGround/{0}/{1}", bareId.Trim(), invNo));
            string[] photoTitles = new string[] { "裸露地現場照片(一)", "裸露地現場照片(二)", "裸露地現場照片(三)", "裸露地現場照片(四)" };

            for (int i = 0; i < 4; i++)
            {
                string title = photoTitles[i];
                string fileUrl = "";
                bool hasFile = false;

                if (Directory.Exists(targetDir))
                {
                    string[] matched = Directory.GetFiles(targetDir, title + ".*");
                    if (matched.Length > 0 && File.Exists(matched[0]))
                    {
                        FileInfo fi = new FileInfo(matched[0]);
                        fileUrl = string.Format("../Upload/BareGround/{0}/{1}/{2}?t={3}",
                            bareId.Trim(), invNo, fi.Name, fi.LastWriteTime.Ticks);
                        hasFile = true;
                    }
                }

                photos.Add(new
                {
                    Index = i + 1,
                    Title = title,
                    HasFile = hasFile,
                    Url = fileUrl
                });
            }

            // 讀取稽查人員簽名
            string sigUrl = "";
            string sigBase64 = "";
            if (Directory.Exists(targetDir))
            {
                string sigPath = Path.Combine(targetDir, "Sig1.png");
                if (File.Exists(sigPath))
                {
                    try
                    {
                        byte[] bytes = File.ReadAllBytes(sigPath);
                        sigBase64 = "data:image/png;base64," + Convert.ToBase64String(bytes);
                        sigUrl = string.Format("../Upload/BareGround/{0}/{1}/Sig1.png?t={2}",
                            bareId.Trim(), invNo, File.GetLastWriteTime(sigPath).Ticks);
                    }
                    catch
                    {
                    }
                }
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                Data = new
                {
                    Bare_ID = rMain["Bare_ID"].ToString().Trim(),
                    BareGroundNo = rMain["BareGroundNo"] != DBNull.Value ? rMain["BareGroundNo"].ToString().Trim() : "",
                    ADDR = rMain["ADDR"] != DBNull.Value ? rMain["ADDR"].ToString().Trim() : "",
                    Land_USE = rMain["Land_USE"] != DBNull.Value ? rMain["Land_USE"].ToString().Trim() : "",
                    Latitude = rMain["Latitude"] != DBNull.Value ? rMain["Latitude"].ToString().Trim() : "",
                    Longtitude = rMain["Longtitude"] != DBNull.Value ? rMain["Longtitude"].ToString().Trim() : "",
                    INV_NO = invNo,
                    Check_Date = checkDateStr,
                    Check_Time = checkTimeStr,
                    Around_Memo = aroundMemo,
                    Waste_Type = wasteType,
                    pLength = pLength,
                    pWidth = pWidth,
                    pHeight = pHeight,
                    pVolume = pVolume,
                    pArea = pArea,
                    surroundings = surroundings,
                    InputUser = inputUser,
                    INV_State = invState,
                    Photos = photos,
                    SignatureUrl = sigUrl,
                    SignatureBase64 = sigBase64
                }
            }));
        }

        // 4. 儲存巡查紀錄 (新增場址/巡查紀錄，或編輯既有資料)
        private void SaveCase()
        {
            string body;
            using (var reader = new StreamReader(Request.InputStream))
            {
                body = reader.ReadToEnd();
            }

            if (string.IsNullOrEmpty(body))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "送出資料不可為空" }));
                return;
            }

            Dictionary<string, object> req = json.Deserialize<Dictionary<string, object>>(body);
            if (req == null)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "資料格式解析失敗" }));
                return;
            }

            string mode = req.ContainsKey("Mode") && req["Mode"] != null ? req["Mode"].ToString().Trim().ToLower() : "new";
            bool isNewSite = req.ContainsKey("IsNewSite") && req["IsNewSite"] != null && Convert.ToBoolean(req["IsNewSite"]);
            string bareId = req.ContainsKey("Bare_ID") && req["Bare_ID"] != null ? req["Bare_ID"].ToString().Trim() : "";
            string bareGroundNo = req.ContainsKey("BareGroundNo") && req["BareGroundNo"] != null ? req["BareGroundNo"].ToString().Trim() : "";
            string addr = req.ContainsKey("ADDR") && req["ADDR"] != null ? req["ADDR"].ToString().Trim() : "";
            string landUse = req.ContainsKey("Land_USE") && req["Land_USE"] != null ? req["Land_USE"].ToString().Trim() : "";
            string latStr = req.ContainsKey("Latitude") && req["Latitude"] != null ? req["Latitude"].ToString().Trim() : "";
            string lonStr = req.ContainsKey("Longtitude") && req["Longtitude"] != null ? req["Longtitude"].ToString().Trim() : "";
            string checkDateStr = req.ContainsKey("Check_Date") && req["Check_Date"] != null ? req["Check_Date"].ToString().Trim() : "";
            string checkTimeStr = req.ContainsKey("Check_Time") && req["Check_Time"] != null ? req["Check_Time"].ToString().Trim() : "";
            string aroundMemo = req.ContainsKey("Around_Memo") && req["Around_Memo"] != null ? req["Around_Memo"].ToString().Trim() : "";
            string wasteType = req.ContainsKey("Waste_Type") && req["Waste_Type"] != null ? req["Waste_Type"].ToString().Trim() : "";
            string surroundings = req.ContainsKey("surroundings") && req["surroundings"] != null ? req["surroundings"].ToString().Trim() : "";
            string sigBase64 = req.ContainsKey("Signature") && req["Signature"] != null ? req["Signature"].ToString().Trim() : "";

            // 數值解析
            float pLength = 0f;
            float pWidth = 0f;
            float pHeight = 0f;
            float pVolume = 0f;
            float pArea = 0f;
            float lat = 0f;
            float lon = 0f;

            float.TryParse(latStr, out lat);
            float.TryParse(lonStr, out lon);

            if (req.ContainsKey("pLength") && req["pLength"] != null) float.TryParse(req["pLength"].ToString(), out pLength);
            if (req.ContainsKey("pWidth") && req["pWidth"] != null) float.TryParse(req["pWidth"].ToString(), out pWidth);
            if (req.ContainsKey("pHeight") && req["pHeight"] != null) float.TryParse(req["pHeight"].ToString(), out pHeight);
            if (req.ContainsKey("pVolume") && req["pVolume"] != null) float.TryParse(req["pVolume"].ToString(), out pVolume);
            if (req.ContainsKey("pArea") && req["pArea"] != null) float.TryParse(req["pArea"].ToString(), out pArea);

            int invNo = 0;
            if (req.ContainsKey("INV_NO") && req["INV_NO"] != null)
            {
                int.TryParse(req["INV_NO"].ToString(), out invNo);
            }

            // 欄位檢核
            if (isNewSite && string.IsNullOrEmpty(bareGroundNo))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "請填寫新場址編號！" }));
                return;
            }

            if (!isNewSite && string.IsNullOrEmpty(bareId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "請選取裸露地場址！" }));
                return;
            }

            if (string.IsNullOrEmpty(checkDateStr))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "請輸入查核日期！" }));
                return;
            }

            // 組合完整查核日期時間
            DateTime checkDateTime = DateTime.Now;
            string fullDateTimeStr = string.Format("{0} {1}", checkDateStr, string.IsNullOrEmpty(checkTimeStr) ? "00:00" : checkTimeStr);
            if (!DateTime.TryParse(fullDateTimeStr, out checkDateTime))
            {
                checkDateTime = DateTime.Now;
            }

            string formattedAround = aroundMemo.Replace("\r\n", "<br />").Replace("\n", "<br />").Replace("\r", "<br />");
            string formattedWaste = wasteType.Replace("\r\n", "<br />").Replace("\n", "<br />").Replace("\r", "<br />");
            string formattedSurround = surroundings.Replace("\r\n", "<br />").Replace("\n", "<br />").Replace("\r", "<br />");
            string currentUser = GetCurrentUser();

            // A. 處理場址主檔 Bare_Main
            if (isNewSite)
            {
                // 自動取號 Bare + yyyyMMdd + 4位流水號
                string dayPrefix = "Bare" + DateTime.Now.ToString("yyyyMMdd");
                int maxSeq = 0;
                string sqlSeq = "SELECT MAX(SUBSTRING(Bare_ID, 13, 4)) FROM Bare_Main WHERE Bare_ID LIKE @prefix + '%'";
                object scalarSeq = DbHelper.ExecuteScalar(sqlSeq, new SqlParameter("@prefix", dayPrefix));
                if (scalarSeq != null && scalarSeq != DBNull.Value)
                {
                    int.TryParse(scalarSeq.ToString(), out maxSeq);
                }
                maxSeq++;
                bareId = dayPrefix + maxSeq.ToString("0000");

                string sqlInsertMain = @"INSERT INTO Bare_Main 
                    (Bare_ID, BareGroundNo, ADDR, Land_USE, Latitude, Longtitude) 
                    VALUES 
                    (@Bare_ID, @BareGroundNo, @ADDR, @Land_USE, @Latitude, @Longtitude)";

                DbHelper.ExecuteNonQuery(sqlInsertMain,
                    new SqlParameter("@Bare_ID", bareId),
                    new SqlParameter("@BareGroundNo", bareGroundNo),
                    new SqlParameter("@ADDR", addr),
                    new SqlParameter("@Land_USE", landUse),
                    new SqlParameter("@Latitude", lat > 0 ? (object)lat : DBNull.Value),
                    new SqlParameter("@Longtitude", lon > 0 ? (object)lon : DBNull.Value));
            }
            else
            {
                // 更新既有場址資訊
                string sqlUpdateMain = @"UPDATE Bare_Main SET 
                    ADDR = @ADDR,
                    Land_USE = @Land_USE,
                    Latitude = @Latitude,
                    Longtitude = @Longtitude
                    WHERE Bare_ID = @Bare_ID";

                DbHelper.ExecuteNonQuery(sqlUpdateMain,
                    new SqlParameter("@ADDR", addr),
                    new SqlParameter("@Land_USE", landUse),
                    new SqlParameter("@Latitude", lat > 0 ? (object)lat : DBNull.Value),
                    new SqlParameter("@Longtitude", lon > 0 ? (object)lon : DBNull.Value),
                    new SqlParameter("@Bare_ID", bareId));
            }

            // B. 處理查核紀錄 Bare_INV
            if (mode == "new" || invNo <= 0)
            {
                // 取最新序號
                string sqlMaxInv = "SELECT ISNULL(MAX(INV_NO), 0) FROM Bare_INV WHERE Bare_ID = @Bare_ID";
                int maxInv = Convert.ToInt32(DbHelper.ExecuteScalar(sqlMaxInv, new SqlParameter("@Bare_ID", bareId)));
                invNo = maxInv + 1;

                string sqlInsertInv = @"INSERT INTO Bare_INV 
                    (Bare_ID, INV_NO, Around_Memo, Waste_Type, pLength, pWidth, pHeight, pVolume, pArea, surroundings, Check_Date, InputUser, Create_Date, Edit_Date, INV_State)
                    VALUES 
                    (@Bare_ID, @INV_NO, @Around_Memo, @Waste_Type, @pLength, @pWidth, @pHeight, @pVolume, @pArea, @surroundings, @Check_Date, @InputUser, GETDATE(), GETDATE(), 'A00a')";

                DbHelper.ExecuteNonQuery(sqlInsertInv,
                    new SqlParameter("@Bare_ID", bareId),
                    new SqlParameter("@INV_NO", invNo),
                    new SqlParameter("@Around_Memo", formattedAround),
                    new SqlParameter("@Waste_Type", formattedWaste),
                    new SqlParameter("@pLength", pLength),
                    new SqlParameter("@pWidth", pWidth),
                    new SqlParameter("@pHeight", pHeight),
                    new SqlParameter("@pVolume", pVolume),
                    new SqlParameter("@pArea", pArea),
                    new SqlParameter("@surroundings", formattedSurround),
                    new SqlParameter("@Check_Date", checkDateTime),
                    new SqlParameter("@InputUser", currentUser));
            }
            else
            {
                // 編輯更新紀錄
                string sqlUpdateInv = @"UPDATE Bare_INV SET 
                    Around_Memo = @Around_Memo,
                    Waste_Type = @Waste_Type,
                    pLength = @pLength,
                    pWidth = @pWidth,
                    pHeight = @pHeight,
                    pVolume = @pVolume,
                    pArea = @pArea,
                    surroundings = @surroundings,
                    Check_Date = @Check_Date,
                    Edit_Date = GETDATE()
                    WHERE Bare_ID = @Bare_ID AND INV_NO = @INV_NO";

                DbHelper.ExecuteNonQuery(sqlUpdateInv,
                    new SqlParameter("@Around_Memo", formattedAround),
                    new SqlParameter("@Waste_Type", formattedWaste),
                    new SqlParameter("@pLength", pLength),
                    new SqlParameter("@pWidth", pWidth),
                    new SqlParameter("@pHeight", pHeight),
                    new SqlParameter("@pVolume", pVolume),
                    new SqlParameter("@pArea", pArea),
                    new SqlParameter("@surroundings", formattedSurround),
                    new SqlParameter("@Check_Date", checkDateTime),
                    new SqlParameter("@Bare_ID", bareId),
                    new SqlParameter("@INV_NO", invNo));
            }

            // C. 儲存照片與簽名檔 (實體路徑相容 Upload/BareGround/{Bare_ID}/{INV_NO})
            try
            {
                string targetDir = Server.MapPath(string.Format("~/Upload/BareGround/{0}/{1}", bareId, invNo));
                if (!Directory.Exists(targetDir))
                {
                    Directory.CreateDirectory(targetDir);
                }

                // 處理四張照片
                string[] photoTitles = new string[] { "裸露地現場照片(一)", "裸露地現場照片(二)", "裸露地現場照片(三)", "裸露地現場照片(四)" };
                if (req.ContainsKey("Photos") && req["Photos"] is System.Collections.ArrayList)
                {
                    var photoList = (System.Collections.ArrayList)req["Photos"];
                    for (int i = 0; i < photoList.Count && i < 4; i++)
                    {
                        var pItem = photoList[i] as Dictionary<string, object>;
                        if (pItem != null && pItem.ContainsKey("Base64") && pItem["Base64"] != null)
                        {
                            string rawB64 = pItem["Base64"].ToString();
                            if (!string.IsNullOrEmpty(rawB64))
                            {
                                string cleanB64 = Regex.Replace(rawB64, @"^data:image\/[a-zA-Z]+;base64,", "");
                                byte[] imgBytes = Convert.FromBase64String(cleanB64);
                                string filePath = Path.Combine(targetDir, photoTitles[i] + ".jpg");
                                File.WriteAllBytes(filePath, imgBytes);
                            }
                        }
                    }
                }

                // 處理簽名
                if (!string.IsNullOrEmpty(sigBase64))
                {
                    string cleanSigB64 = Regex.Replace(sigBase64, @"^data:image\/[a-zA-Z]+;base64,", "");
                    byte[] sigBytes = Convert.FromBase64String(cleanSigB64);
                    string sigPath = Path.Combine(targetDir, "Sig1.png");
                    File.WriteAllBytes(sigPath, sigBytes);
                }
            }
            catch (Exception)
            {
                // 照片與簽名儲存容錯
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                Message = (mode == "new" ? "裸露地巡檢紀錄建立成功！" : "裸露地巡檢紀錄儲存成功！"),
                Bare_ID = bareId,
                INV_NO = invNo
            }));
        }
    }
}
