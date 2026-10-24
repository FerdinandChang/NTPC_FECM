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

namespace NTPC_FEC.Manager
{
    public partial class Check_Step1_Bare : Page
    {
        private JavaScriptSerializer json;

        public Check_Step1_Bare()
        {
            json = new JavaScriptSerializer();
            json.MaxJsonLength = int.MaxValue;
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
                        Message = "執行錯誤：" + ex.Message
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
        }

        private string GetCurrentUser()
        {
            if (Session["LoginUser"] != null && !string.IsNullOrEmpty(Session["LoginUser"].ToString()))
            {
                return Session["LoginUser"].ToString();
            }
            if (Session["User_ID"] != null && !string.IsNullOrEmpty(Session["User_ID"].ToString()))
            {
                return Session["User_ID"].ToString();
            }
            return "系統管理員";
        }

        private string ComputeMD5(string input)
        {
            using (MD5 md5 = MD5.Create())
            {
                byte[] bytes = md5.ComputeHash(Encoding.UTF8.GetBytes(input ?? ""));
                StringBuilder sb = new StringBuilder();
                for (int i = 0; i < bytes.Length; i++)
                {
                    sb.Append(bytes[i].ToString("x2"));
                }
                return sb.ToString();
            }
        }

        private bool ValidateSecurityHash(string mode, string bareId, string inputHash)
        {
            if (string.IsNullOrEmpty(inputHash))
            {
                // 若已有正式登入者 Session 則允許容錯
                return Session["LoginUser"] != null || Session["User_ID"] != null;
            }

            DateTime now = DateTime.Now;
            string curHour = now.ToString("yyyyMMddHH");
            string prevHour = now.AddHours(-1).ToString("yyyyMMddHH");

            // 1. 審核模式 MD5 演算法：(mode + bareId + yyyyMMddHH).ToMD5()
            string expectedCur1 = ComputeMD5(mode + bareId + curHour);
            string expectedPrev1 = ComputeMD5(mode + bareId + prevHour);
            if (string.Equals(inputHash, expectedCur1, StringComparison.OrdinalIgnoreCase) ||
                string.Equals(inputHash, expectedPrev1, StringComparison.OrdinalIgnoreCase))
            {
                return true;
            }

            // 2. 檢視模式 MD5 演算法：("MD5:" + bareId + yyyyMMddHH).ToMD5()
            string expectedCur2 = ComputeMD5("MD5:" + bareId + curHour);
            string expectedPrev2 = ComputeMD5("MD5:" + bareId + prevHour);
            if (string.Equals(inputHash, expectedCur2, StringComparison.OrdinalIgnoreCase) ||
                string.Equals(inputHash, expectedPrev2, StringComparison.OrdinalIgnoreCase))
            {
                return true;
            }

            // 3. 裸露地一般校驗碼容錯
            string expectedCur3 = ComputeMD5(bareId + curHour);
            if (string.Equals(inputHash, expectedCur3, StringComparison.OrdinalIgnoreCase))
            {
                return true;
            }

            // 4. 若有登入管理者身分仍可容許通行
            if (Session["LoginUser"] != null || Session["User_ID"] != null)
            {
                return true;
            }

            return false;
        }

        private void HandleAjaxAction(string action)
        {
            string act = action.ToLower();
            if (act == "get_data")
            {
                GetCaseDetail();
            }
            else if (act == "submit_check")
            {
                SubmitCheck();
            }
            else
            {
                Response.Write(json.Serialize(new { Success = false, Message = "未知的操作指令：" + action }));
            }
        }

        private void GetCaseDetail()
        {
            string mode = (Request["mode"] ?? "INV1").Trim();
            string bareId = (Request["id"] ?? "").Trim();
            string hash = (Request["id1"] ?? "").Trim();
            int invNo = 0;
            int.TryParse(Request["id2"] ?? "0", out invNo);

            if (string.IsNullOrEmpty(bareId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "未提供場址編號 (?id=)" }));
                return;
            }

            if (!ValidateSecurityHash(mode, bareId, hash))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "安全校驗碼已過期或不符，請由審查清單重新進入。" }));
                return;
            }

            // 1. 讀取場址基本資料 Bare_Main
            Dictionary<string, object> mainData = new Dictionary<string, object>();
            string sqlMain = @"
                SELECT 
                    bm.Bare_ID,
                    bm.BareGroundNo,
                    bm.ADDR,
                    bm.Land_USE,
                    bm.Latitude,
                    bm.Longtitude,
                    bm.TOWN_ID,
                    t.TOWN_NA AS TownName
                FROM Bare_Main bm
                LEFT JOIN Town_List t ON bm.TOWN_ID = t.TOWN_ID
                WHERE bm.Bare_ID = @Bare_ID";

            DataTable dtMain = DbHelper.ExecuteDataTable(sqlMain, new SqlParameter("@Bare_ID", bareId));
            if (dtMain != null && dtMain.Rows.Count > 0)
            {
                DataRow r = dtMain.Rows[0];
                mainData["Bare_ID"] = r["Bare_ID"] != DBNull.Value ? r["Bare_ID"].ToString() : "";
                mainData["BareGroundNo"] = r["BareGroundNo"] != DBNull.Value ? r["BareGroundNo"].ToString() : "";
                mainData["ADDR"] = r["ADDR"] != DBNull.Value ? r["ADDR"].ToString() : "";
                mainData["Land_USE"] = r["Land_USE"] != DBNull.Value ? r["Land_USE"].ToString() : "";
                mainData["Latitude"] = r["Latitude"] != DBNull.Value ? r["Latitude"].ToString() : "";
                mainData["Longtitude"] = r["Longtitude"] != DBNull.Value ? r["Longtitude"].ToString() : "";
                mainData["TownName"] = r["TownName"] != DBNull.Value ? r["TownName"].ToString() : "";
            }
            else
            {
                Response.Write(json.Serialize(new { Success = false, Message = "查無此裸露地基本資料 (" + bareId + ")" }));
                return;
            }

            // 2. 讀取巡查概況與量測數據 Bare_INV (若未提供 invNo 則預設取得最新一筆)
            Dictionary<string, object> invData = new Dictionary<string, object>();
            string sqlInv = @"
                SELECT TOP 1
                    bi.*,
                    bsl.State_Name,
                    bsl.Next_State,
                    bsl.Back_State,
                    ua.Name AS ChkUserName
                FROM Bare_INV bi
                LEFT JOIN Bare_State_List bsl ON bi.INV_State = bsl.State_ID
                LEFT JOIN UserAcc ua ON bi.Chk_User = ua.UserID
                WHERE bi.Bare_ID = @Bare_ID " + (invNo > 0 ? " AND bi.INV_NO = @INV_NO " : "") +
                " ORDER BY bi.INV_NO DESC";

            List<SqlParameter> pList = new List<SqlParameter>();
            pList.Add(new SqlParameter("@Bare_ID", bareId));
            if (invNo > 0)
            {
                pList.Add(new SqlParameter("@INV_NO", invNo));
            }

            DataTable dtInv = DbHelper.ExecuteDataTable(sqlInv, pList.ToArray());
            if (dtInv != null && dtInv.Rows.Count > 0)
            {
                DataRow r = dtInv.Rows[0];
                invNo = Convert.ToInt32(r["INV_NO"]);
                invData["Bare_ID"] = bareId;
                invData["INV_NO"] = invNo;

                string chkDateStr = "--";
                if (r["Check_Date"] != DBNull.Value)
                {
                    DateTime dtC;
                    if (DateTime.TryParse(r["Check_Date"].ToString(), out dtC))
                    {
                        chkDateStr = dtC.ToString("yyyy-MM-dd HH:mm");
                    }
                }
                invData["Check_Date"] = chkDateStr;

                float pLen = 0f, pWid = 0f, pHei = 0f, pVol = 0f, pAre = 0f;
                if (r["pLength"] != DBNull.Value) float.TryParse(r["pLength"].ToString(), out pLen);
                if (r["pWidth"] != DBNull.Value) float.TryParse(r["pWidth"].ToString(), out pWid);
                if (r["pHeight"] != DBNull.Value) float.TryParse(r["pHeight"].ToString(), out pHei);
                if (r["pVolume"] != DBNull.Value) float.TryParse(r["pVolume"].ToString(), out pVol);
                if (r["pArea"] != DBNull.Value) float.TryParse(r["pArea"].ToString(), out pAre);

                invData["pLength"] = pLen;
                invData["pWidth"] = pWid;
                invData["pHeight"] = pHei;
                invData["pVolume"] = pVol;
                invData["pArea"] = pAre;

                string aroundMemo = r["Around_Memo"] != DBNull.Value ? r["Around_Memo"].ToString().Replace("<br />", "\r\n").Trim() : "";
                string wasteType = r["Waste_Type"] != DBNull.Value ? r["Waste_Type"].ToString().Replace("<br />", "\r\n").Trim() : "";
                string surroundings = r["surroundings"] != DBNull.Value ? r["surroundings"].ToString().Replace("<br />", "\r\n").Trim() : "";

                invData["Around_Memo"] = aroundMemo;
                invData["Waste_Type"] = wasteType;
                invData["Surroundings"] = surroundings;

                string invState = r["INV_State"] != DBNull.Value ? r["INV_State"].ToString() : "";
                string stateName = r["State_Name"] != DBNull.Value ? r["State_Name"].ToString() : invState;

                invData["INV_State"] = invState;
                invData["State_Name"] = stateName;
                invData["Next_State"] = r["Next_State"] != DBNull.Value ? r["Next_State"].ToString() : "";
                invData["Back_State"] = r["Back_State"] != DBNull.Value ? r["Back_State"].ToString() : "";
                invData["Chk_User"] = r["Chk_User"] != DBNull.Value ? r["Chk_User"].ToString() : "";
                invData["ChkUserName"] = r["ChkUserName"] != DBNull.Value ? r["ChkUserName"].ToString() : "";
            }
            else
            {
                invData["Bare_ID"] = bareId;
                invData["INV_NO"] = invNo;
                invData["Check_Date"] = "--";
                invData["pLength"] = 0;
                invData["pWidth"] = 0;
                invData["pHeight"] = 0;
                invData["pVolume"] = 0;
                invData["pArea"] = 0;
                invData["Around_Memo"] = "";
                invData["Waste_Type"] = "";
                invData["Surroundings"] = "";
                invData["INV_State"] = "";
                invData["State_Name"] = "無巡查資料";
            }

            // 3. 讀取現場照片 (四張標準照片)
            List<Dictionary<string, object>> photoList = GetCasePhotos(bareId, invNo);

            // 4. 讀取簽名檔 (Sig1, Sig2)
            Dictionary<string, string> sigData = GetCaseSignatures(bareId, invNo);

            // 5. 讀取審核歷史歷程 Bare_Chk_Result
            List<Dictionary<string, object>> historyList = GetCaseHistories(bareId, invNo);

            // 6. 審查狀態名稱與權限判定
            string reviewStateTitle = "";
            string requiredStateCode = "";
            switch (mode.ToUpper())
            {
                case "INV1":
                    reviewStateTitle = "初審作業";
                    requiredStateCode = "A00";
                    break;
                case "INV2":
                    reviewStateTitle = "複審作業";
                    requiredStateCode = "A01";
                    break;
                case "INV3":
                    reviewStateTitle = "三審作業";
                    requiredStateCode = "A02";
                    break;
                case "READ":
                    reviewStateTitle = "案件檢視";
                    break;
                default:
                    reviewStateTitle = "案件審查";
                    break;
            }

            string currentInvState = invData.ContainsKey("INV_State") ? invData["INV_State"].ToString() : "";
            bool canReview = (mode.ToUpper() != "READ") &&
                             (!string.IsNullOrEmpty(requiredStateCode) ? (currentInvState == requiredStateCode) : true);

            Response.Write(json.Serialize(new
            {
                Success = true,
                Mode = mode,
                CurrentUser = GetCurrentUser(),
                ReviewStateTitle = reviewStateTitle,
                RequiredStateCode = requiredStateCode,
                CanReview = canReview,
                Main = mainData,
                Inv = invData,
                Photos = photoList,
                Signatures = sigData,
                Histories = historyList
            }));
        }

        private List<Dictionary<string, object>> GetCasePhotos(string bareId, int invNo)
        {
            List<Dictionary<string, object>> list = new List<Dictionary<string, object>>();
            string[] titles = new string[] { "現場照片(一)", "現場照片(二)", "現場照片(三)", "現場照片(四)" };
            string relBase = "/Upload/BareGround/" + bareId + "/" + invNo;
            string dirPath = HttpContext.Current.Server.MapPath("~" + relBase);

            for (int i = 0; i < titles.Length; i++)
            {
                Dictionary<string, object> p = new Dictionary<string, object>();
                p["Index"] = i + 1;
                p["Title"] = titles[i];
                p["HasFile"] = false;
                p["Url"] = "";

                if (Directory.Exists(dirPath))
                {
                    DirectoryInfo di = new DirectoryInfo(dirPath);
                    FileInfo[] files = di.GetFiles("*" + titles[i] + "*.*");
                    if (files.Length == 0)
                    {
                        // 嘗試尋找 Photo1, Photo2 等
                        files = di.GetFiles(string.Format("Photo{0}.*", i + 1));
                    }

                    if (files.Length > 0)
                    {
                        p["HasFile"] = true;
                        p["Url"] = string.Format("..{0}/{1}?t={2}", relBase, files[0].Name, files[0].LastWriteTime.Ticks);
                    }
                }

                list.Add(p);
            }

            return list;
        }

        private Dictionary<string, string> GetCaseSignatures(string bareId, int invNo)
        {
            Dictionary<string, string> dict = new Dictionary<string, string>();
            dict["Sig1Url"] = "";
            dict["Sig1Base64"] = "";
            dict["Sig2Url"] = "";
            dict["Sig2Base64"] = "";

            try
            {
                string relBase = "/Upload/BareGround/" + bareId + "/" + invNo;
                string dirPath = HttpContext.Current.Server.MapPath("~" + relBase);
                if (Directory.Exists(dirPath))
                {
                    string sig1Path = Path.Combine(dirPath, "Sig1.png");
                    if (File.Exists(sig1Path))
                    {
                        byte[] bytes1 = File.ReadAllBytes(sig1Path);
                        dict["Sig1Base64"] = "data:image/png;base64," + Convert.ToBase64String(bytes1);
                        dict["Sig1Url"] = string.Format("..{0}/Sig1.png?t={1}", relBase, File.GetLastWriteTime(sig1Path).Ticks);
                    }

                    string sig2Path = Path.Combine(dirPath, "Sig2.png");
                    if (File.Exists(sig2Path))
                    {
                        byte[] bytes2 = File.ReadAllBytes(sig2Path);
                        dict["Sig2Base64"] = "data:image/png;base64," + Convert.ToBase64String(bytes2);
                        dict["Sig2Url"] = string.Format("..{0}/Sig2.png?t={1}", relBase, File.GetLastWriteTime(sig2Path).Ticks);
                    }
                }
            }
            catch
            {
            }

            return dict;
        }

        private List<Dictionary<string, object>> GetCaseHistories(string bareId, int invNo)
        {
            List<Dictionary<string, object>> list = new List<Dictionary<string, object>>();
            try
            {
                string sql = @"
                    SELECT 
                        bcr.*,
                        ua.Name AS UserName,
                        bsl.State_Name 
                    FROM Bare_Chk_Result bcr
                    LEFT JOIN UserAcc ua ON bcr.Chk_User = ua.UserID  
                    LEFT JOIN Bare_State_List bsl ON bcr.INV_State = bsl.State_ID 
                    WHERE bcr.Bare_ID = @Bare_ID AND bcr.INV_NO = @INV_NO
                    ORDER BY bcr.Chk_Date DESC";

                DataTable dt = DbHelper.ExecuteDataTable(sql,
                    new SqlParameter("@Bare_ID", bareId),
                    new SqlParameter("@INV_NO", invNo));

                if (dt != null)
                {
                    foreach (DataRow r in dt.Rows)
                    {
                        Dictionary<string, object> h = new Dictionary<string, object>();
                        string chkDateStr = "--";
                        if (r["Chk_Date"] != DBNull.Value)
                        {
                            DateTime dtC;
                            if (DateTime.TryParse(r["Chk_Date"].ToString(), out dtC))
                            {
                                chkDateStr = dtC.ToString("yyyy-MM-dd HH:mm");
                            }
                        }
                        h["Chk_Date"] = chkDateStr;
                        h["Chk_Result"] = r["Chk_Result"] != DBNull.Value ? r["Chk_Result"].ToString() : "";
                        h["Chk_Memo"] = r["Chk_Memo"] != DBNull.Value ? r["Chk_Memo"].ToString() : "";
                        h["State_Name"] = r["State_Name"] != DBNull.Value ? r["State_Name"].ToString() : "";
                        string uName = r["UserName"] != DBNull.Value && !string.IsNullOrEmpty(r["UserName"].ToString())
                            ? r["UserName"].ToString()
                            : (r["Chk_User"] != DBNull.Value ? r["Chk_User"].ToString() : "");
                        h["Chk_User"] = uName;
                        list.Add(h);
                    }
                }
            }
            catch
            {
            }
            return list;
        }

        private void SubmitCheck()
        {
            string mode = (Request["mode"] ?? "INV1").Trim();
            string bareId = (Request["id"] ?? "").Trim();
            string hash = (Request["id1"] ?? "").Trim();
            int invNo = 0;
            int.TryParse(Request["id2"] ?? "0", out invNo);

            string resultType = (Request["result"] ?? "").Trim().ToUpper(); // PASS or FAIL
            string memo = (Request["memo"] ?? "").Trim();

            if (string.IsNullOrEmpty(bareId) || invNo <= 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "缺少必要的場址編號或巡查次數參數" }));
                return;
            }

            if (!ValidateSecurityHash(mode, bareId, hash))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "安全驗證未通過或作業已逾期，請返回清單重新操作。" }));
                return;
            }

            if (resultType != "PASS" && resultType != "FAIL")
            {
                Response.Write(json.Serialize(new { Success = false, Message = "請明確選擇審核結果（通過或退件）" }));
                return;
            }

            string stateCode = "";
            string chkResultText = (resultType == "PASS") ? "通過" : "退件";

            switch (mode.ToUpper())
            {
                case "INV1":
                    stateCode = "A00";
                    break;
                case "INV2":
                    stateCode = "A01";
                    break;
                case "INV3":
                    stateCode = "A02";
                    break;
                default:
                    stateCode = "A00";
                    break;
            }

            string currentUser = GetCurrentUser();

            try
            {
                // 1. 寫入審查紀錄 Bare_Chk_Result
                string sqlInsertResult = @"
                    INSERT INTO Bare_Chk_Result 
                    (Bare_ID, INV_NO, Chk_Date, Chk_Result, Chk_Memo, INV_State, Chk_User)
                    VALUES 
                    (@Bare_ID, @INV_NO, @Chk_Date, @Chk_Result, @Chk_Memo, @INV_State, @Chk_User)";

                DbHelper.ExecuteNonQuery(sqlInsertResult,
                    new SqlParameter("@Bare_ID", bareId),
                    new SqlParameter("@INV_NO", invNo),
                    new SqlParameter("@Chk_Date", DateTime.Now),
                    new SqlParameter("@Chk_Result", chkResultText),
                    new SqlParameter("@Chk_Memo", memo),
                    new SqlParameter("@INV_State", stateCode),
                    new SqlParameter("@Chk_User", currentUser));

                // 2. 查詢該審核階段之下一階段與退回狀態
                string nextState = "";
                string backState = "";

                string sqlQueryState = "SELECT Next_State, Back_State FROM Bare_State_List WHERE State_ID = @State_ID";
                DataTable dtState = DbHelper.ExecuteDataTable(sqlQueryState, new SqlParameter("@State_ID", stateCode));
                if (dtState != null && dtState.Rows.Count > 0)
                {
                    nextState = dtState.Rows[0]["Next_State"] != DBNull.Value ? dtState.Rows[0]["Next_State"].ToString() : "";
                    backState = dtState.Rows[0]["Back_State"] != DBNull.Value ? dtState.Rows[0]["Back_State"].ToString() : "";
                }

                // 預防性 fallback
                if (string.IsNullOrEmpty(nextState))
                {
                    if (stateCode == "A00") nextState = "A01";
                    else if (stateCode == "A01") nextState = "A02";
                    else nextState = "A03";
                }
                if (string.IsNullOrEmpty(backState))
                {
                    backState = "00";
                }

                string targetState = (resultType == "PASS") ? nextState : backState;

                // 3. 更新 Bare_INV 之狀態
                string sqlUpdateInv = "UPDATE Bare_INV SET INV_State = @INV_State WHERE Bare_ID = @Bare_ID AND INV_NO = @INV_NO";
                DbHelper.ExecuteNonQuery(sqlUpdateInv,
                    new SqlParameter("@INV_State", targetState),
                    new SqlParameter("@Bare_ID", bareId),
                    new SqlParameter("@INV_NO", invNo));

                Response.Write(json.Serialize(new
                {
                    Success = true,
                    Message = string.Format("審核完成！結果：{0}，案件狀態已更新。", chkResultText),
                    NextUrl = "managerList_Bare.aspx?mode=" + mode
                }));
            }
            catch (Exception ex)
            {
                Response.Write(json.Serialize(new
                {
                    Success = false,
                    Message = "儲存審核結果失敗：" + ex.Message
                }));
            }
        }
    }
}
