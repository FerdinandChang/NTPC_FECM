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
    public partial class Check_Step1_Mac : Page
    {
        private JavaScriptSerializer json;

        public Check_Step1_Mac()
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

        private bool ValidateSecurityHash(string mode, string facId, string inputHash)
        {
            // 若已具備登入管理者身分則直接容許通行
            if (Session["LoginUser"] != null || Session["User_ID"] != null)
            {
                return true;
            }

            if (string.IsNullOrEmpty(inputHash))
            {
                return false;
            }

            DateTime today = DateTime.Today;
            string curDay = today.ToString("yyyyMMdd");
            string prevDay = today.AddDays(-1).ToString("yyyyMMdd");

            // 1. (mode + facId + yyyyMMdd).ToMD5()
            string expectedCur1 = ComputeMD5(mode + facId + curDay);
            string expectedPrev1 = ComputeMD5(mode + facId + prevDay);
            if (string.Equals(inputHash, expectedCur1, StringComparison.OrdinalIgnoreCase) ||
                string.Equals(inputHash, expectedPrev1, StringComparison.OrdinalIgnoreCase))
            {
                return true;
            }

            // 2. (facId + yyyyMMdd).ToMD5()
            string expectedCur2 = ComputeMD5(facId + curDay);
            string expectedPrev2 = ComputeMD5(facId + prevDay);
            if (string.Equals(inputHash, expectedCur2, StringComparison.OrdinalIgnoreCase) ||
                string.Equals(inputHash, expectedPrev2, StringComparison.OrdinalIgnoreCase))
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
            else if (act == "submit_review")
            {
                SubmitReview();
            }
            else
            {
                Response.Write(json.Serialize(new { Success = false, Message = "未知的操作指令：" + action }));
            }
        }

        private void GetCaseDetail()
        {
            string mode = (Request["mode"] ?? "MAC1").Trim().ToUpper();
            string facId = (Request["fac"] ?? "").Trim();
            string hash = (Request["fac1"] ?? "").Trim();
            int macId = 0;
            int.TryParse(Request["macid"] ?? "0", out macId);

            if (string.IsNullOrEmpty(facId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "未提供場所管制編號 (?fac=)" }));
                return;
            }

            if (macId <= 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "未提供機具編號 (?macid=)" }));
                return;
            }

            if (!ValidateSecurityHash(mode, facId, hash))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "安全驗證碼已過期或不符，請由管理清單重新進入。" }));
                return;
            }

            // 1. 查詢場所基本資料
            Dictionary<string, object> facInfo = new Dictionary<string, object>();
            string sqlFac = "SELECT * FROM FAC_Main WHERE FAC_ID = @FAC_ID";
            DataTable dtFac = DbHelper.ExecuteDataTable(sqlFac, new SqlParameter("@FAC_ID", facId));

            if (dtFac != null && dtFac.Rows.Count > 0)
            {
                DataRow fRow = dtFac.Rows[0];
                foreach (DataColumn col in dtFac.Columns)
                {
                    facInfo[col.ColumnName] = (fRow[col] != DBNull.Value) ? fRow[col].ToString().Trim() : "";
                }

                // 行業別名稱補充
                string indCode = fRow.Table.Columns.Contains("INDUSTRIAL_Code1") ? fRow["INDUSTRIAL_Code1"].ToString() : "";
                if (!string.IsNullOrEmpty(indCode) && (!facInfo.ContainsKey("Industrial") || string.IsNullOrEmpty(facInfo["Industrial"].ToString())))
                {
                    try
                    {
                        string sqlInd = "SELECT INDUSTRIAL_Name FROM INDUSTRIAL_Data WHERE INDUSTRIAL_Code = @Code";
                        DataTable dtInd = DbHelper.ExecuteDataTable(sqlInd, new SqlParameter("@Code", indCode));
                        if (dtInd != null && dtInd.Rows.Count > 0)
                        {
                            facInfo["Industrial"] = dtInd.Rows[0]["INDUSTRIAL_Name"].ToString();
                        }
                    }
                    catch
                    {
                    }
                }

                // TWD97 轉 WGS84 座標轉換
                double twdX = 0;
                double twdY = 0;
                if (fRow.Table.Columns.Contains("TWD97_X") && fRow["TWD97_X"] != DBNull.Value)
                {
                    double.TryParse(fRow["TWD97_X"].ToString(), out twdX);
                }
                if (twdX == 0 && fRow.Table.Columns.Contains("X") && fRow["X"] != DBNull.Value)
                {
                    double.TryParse(fRow["X"].ToString(), out twdX);
                }

                if (fRow.Table.Columns.Contains("TWD97_Y") && fRow["TWD97_Y"] != DBNull.Value)
                {
                    double.TryParse(fRow["TWD97_Y"].ToString(), out twdY);
                }
                if (twdY == 0 && fRow.Table.Columns.Contains("Y") && fRow["Y"] != DBNull.Value)
                {
                    double.TryParse(fRow["Y"].ToString(), out twdY);
                }

                double lat = 0;
                double lon = 0;
                if (twdX > 0 && twdY > 0)
                {
                    Twd97ToWgs84(twdX, twdY, out lat, out lon);
                }
                facInfo["Lat"] = lat;
                facInfo["Lng"] = lon;
            }
            else
            {
                facInfo["FAC_ID"] = facId;
                facInfo["FAC_NAME"] = "場所 " + facId;
                facInfo["ADDR"] = "";
                facInfo["Lat"] = 0;
                facInfo["Lng"] = 0;
            }

            // 2. 查詢施工機具主檔資料 Machine_Main
            string sqlMac = "SELECT Machine_Main.*, mac_State_List.State_Name FROM Machine_Main LEFT JOIN mac_State_List ON Machine_Main.Mac_State = mac_State_List.State_ID WHERE FAC_ID = @FAC_ID AND mac_ID = @mac_ID";
            DataTable dtMac = DbHelper.ExecuteDataTable(sqlMac,
                new SqlParameter("@FAC_ID", facId),
                new SqlParameter("@mac_ID", macId));

            if (dtMac == null || dtMac.Rows.Count == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "查無該筆施工機具資料 (mac_ID: " + macId.ToString() + ")" }));
                return;
            }

            DataRow macRow = dtMac.Rows[0];
            Dictionary<string, object> macData = new Dictionary<string, object>();
            foreach (DataColumn col in dtMac.Columns)
            {
                if (macRow[col] != DBNull.Value)
                {
                    if (col.DataType == typeof(DateTime))
                    {
                        macData[col.ColumnName] = Convert.ToDateTime(macRow[col]).ToString("yyyy-MM-dd");
                    }
                    else
                    {
                        macData[col.ColumnName] = macRow[col].ToString().Trim();
                    }
                }
                else
                {
                    macData[col.ColumnName] = "";
                }
            }

            // 格式化日期與數值平均運算
            DateTime checkDate;
            if (DateTime.TryParse(macRow["Check_date"].ToString(), out checkDate))
            {
                macData["Check_date_format"] = checkDate.ToString("yyyy-MM-dd");
            }
            else
            {
                macData["Check_date_format"] = "-";
            }

            DateTime markDeadline;
            if (DateTime.TryParse(macRow["Mark_Deadline"].ToString(), out markDeadline))
            {
                macData["Mark_Deadline_format"] = markDeadline.ToString("yyyy-MM-dd");
                macData["IsExpired"] = (markDeadline < DateTime.Today);
            }
            else
            {
                macData["Mark_Deadline_format"] = "-";
                macData["IsExpired"] = false;
            }

            // 啟動值不透光率平均
            float countStart = 0f;
            float valStart1 = 0f, valStart2 = 0f, valStart3 = 0f;
            float.TryParse(macRow["opaque_Start1"].ToString(), out valStart1);
            if (valStart1 > 0f) countStart++;
            float.TryParse(macRow["opaque_Start2"].ToString(), out valStart2);
            if (valStart2 > 0f) countStart++;
            float.TryParse(macRow["opaque_Start3"].ToString(), out valStart3);
            if (valStart3 > 0f) countStart++;
            float avgStart = (countStart > 0f) ? (valStart1 + valStart2 + valStart3) / countStart : 0f;
            macData["opaque_Start_Avg"] = (countStart > 0f) ? avgStart.ToString("0.00") : "-";
            macData["opaque_Start_Pass"] = (avgStart <= 1.0f); // 啟動不透光率標準

            // 運行值不透光率平均
            float countRun = 0f;
            float valRun1 = 0f, valRun2 = 0f, valRun3 = 0f;
            float.TryParse(macRow["opaque_Run1"].ToString(), out valRun1);
            if (valRun1 > 0f) countRun++;
            float.TryParse(macRow["opaque_Run2"].ToString(), out valRun2);
            if (valRun2 > 0f) countRun++;
            float.TryParse(macRow["opaque_Run3"].ToString(), out valRun3);
            if (valRun3 > 0f) countRun++;
            float avgRun = (countRun > 0f) ? (valRun1 + valRun2 + valRun3) / countRun : 0f;
            macData["opaque_Run_Avg"] = (countRun > 0f) ? avgRun.ToString("0.00") : "-";
            macData["opaque_Run_Pass"] = (avgRun <= 1.0f); // 運行不透光率標準

            // 3. 附件照片與證明文件列表
            List<Dictionary<string, object>> photoList = GetMacPhotos(facId, macId);

            // 4. 歷史審核歷程 Mac_Chk_Result
            string sqlHistory = @"
                SELECT Mac_Chk_Result.*, UserAcc.Name, mac_State_List.State_Name 
                FROM Mac_Chk_Result 
                LEFT JOIN UserAcc ON Mac_Chk_Result.Chk_User = UserAcc.UserID 
                LEFT JOIN mac_State_List ON Mac_Chk_Result.Mac_State = mac_State_List.State_ID 
                WHERE Mac_Chk_Result.FAC_ID = @FAC_ID AND Mac_Chk_Result.mac_ID = @mac_ID 
                ORDER BY Mac_Chk_Result.Chk_Date DESC";

            DataTable dtHist = DbHelper.ExecuteDataTable(sqlHistory,
                new SqlParameter("@FAC_ID", facId),
                new SqlParameter("@mac_ID", macId));

            List<Dictionary<string, object>> historyList = new List<Dictionary<string, object>>();
            if (dtHist != null)
            {
                foreach (DataRow hr in dtHist.Rows)
                {
                    Dictionary<string, object> h = new Dictionary<string, object>();
                    h["Name"] = (hr["Name"] != DBNull.Value && !string.IsNullOrEmpty(hr["Name"].ToString())) ? hr["Name"].ToString() : (hr["Chk_User"] != DBNull.Value ? hr["Chk_User"].ToString() : "審核員");
                    h["Chk_Date"] = (hr["Chk_Date"] != DBNull.Value) ? Convert.ToDateTime(hr["Chk_Date"]).ToString("yyyy-MM-dd HH:mm") : "-";
                    h["State_Name"] = (hr["State_Name"] != DBNull.Value && !string.IsNullOrEmpty(hr["State_Name"].ToString())) ? hr["State_Name"].ToString() : (hr["Mac_State"] != DBNull.Value ? hr["Mac_State"].ToString() : "審查階段");
                    h["Chk_Result"] = (hr["Chk_Result"] != DBNull.Value) ? hr["Chk_Result"].ToString() : "";
                    h["Chk_Memo"] = (hr["Chk_Memo"] != DBNull.Value) ? hr["Chk_Memo"].ToString() : "";
                    historyList.Add(h);
                }
            }

            // 審查模式狀態判斷
            bool isReviewMode = (mode == "MAC1" || mode == "MAC2" || mode == "MAC3" || mode == "INV1" || mode == "INV2" || mode == "INV3");
            string reviewStageTitle = "審查作業";
            if (mode == "MAC1" || mode == "INV1") reviewStageTitle = "初審作業";
            else if (mode == "MAC2" || mode == "INV2") reviewStageTitle = "複審作業";
            else if (mode == "MAC3" || mode == "INV3") reviewStageTitle = "三審作業";

            Response.Write(json.Serialize(new
            {
                Success = true,
                Mode = mode,
                IsReviewMode = isReviewMode,
                ReviewStageTitle = reviewStageTitle,
                FacInfo = facInfo,
                MacData = macData,
                PhotoList = photoList,
                HistoryList = historyList
            }));
        }

        private List<Dictionary<string, object>> GetMacPhotos(string facId, int macId)
        {
            List<Dictionary<string, object>> list = new List<Dictionary<string, object>>();

            // 預期 8 項標準佐證照片分類
            string[] standardTitles = new string[]
            {
                "出廠證明",
                "海關證明",
                "檢測結果",
                "檢測過程",
                "機具全貌",
                "機身編號、引擎編號",
                "核發標章",
                "其他佐證"
            };

            string relDir = "/Upload/MAC/" + facId + "/" + macId.ToString() + "/";
            string absDir = Server.MapPath("~" + relDir);

            DirectoryInfo dir = new DirectoryInfo(absDir);
            HashSet<string> matchedFiles = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

            for (int i = 0; i < standardTitles.Length; i++)
            {
                string title = standardTitles[i];
                Dictionary<string, object> p = new Dictionary<string, object>();
                p["Title"] = title;
                p["Exists"] = false;
                p["Url"] = "";
                p["FileName"] = "";

                if (dir.Exists)
                {
                    // 搜尋該標題開頭之圖檔
                    FileInfo[] files = dir.GetFiles(title + ".*");
                    if (files.Length == 0 && title.Contains("、"))
                    {
                        // 容錯支援逗號分開的檔名（如 "機身編號"、"引擎編號"）
                        string[] parts = title.Split(new char[] { '、', ',', ' ' }, StringSplitOptions.RemoveEmptyEntries);
                        foreach (string pt in parts)
                        {
                            files = dir.GetFiles("*" + pt + "*.*");
                            if (files.Length > 0) break;
                        }
                    }

                    if (files.Length > 0)
                    {
                        p["Exists"] = true;
                        p["Url"] = relDir + files[0].Name;
                        p["FileName"] = files[0].Name;
                        matchedFiles.Add(files[0].FullName);
                    }
                }

                list.Add(p);
            }

            // 若目錄中還有其他額外上傳的照片，一併列入「其他附件」
            if (dir.Exists)
            {
                FileInfo[] allFiles = dir.GetFiles("*.*");
                foreach (FileInfo f in allFiles)
                {
                    if (f.Extension.Equals(".jpg", StringComparison.OrdinalIgnoreCase) ||
                        f.Extension.Equals(".jpeg", StringComparison.OrdinalIgnoreCase) ||
                        f.Extension.Equals(".png", StringComparison.OrdinalIgnoreCase) ||
                        f.Extension.Equals(".gif", StringComparison.OrdinalIgnoreCase) ||
                        f.Extension.Equals(".webp", StringComparison.OrdinalIgnoreCase) ||
                        f.Extension.Equals(".pdf", StringComparison.OrdinalIgnoreCase))
                    {
                        if (!matchedFiles.Contains(f.FullName))
                        {
                            Dictionary<string, object> extra = new Dictionary<string, object>();
                            extra["Title"] = Path.GetFileNameWithoutExtension(f.Name);
                            extra["Exists"] = true;
                            extra["Url"] = relDir + f.Name;
                            extra["FileName"] = f.Name;
                            list.Add(extra);
                        }
                    }
                }
            }

            return list;
        }

        private void SubmitReview()
        {
            string facId = (Request["fac"] ?? "").Trim();
            string mode = (Request["mode"] ?? "").Trim().ToUpper();
            int macId = 0;
            int.TryParse(Request["macid"] ?? "0", out macId);

            string result = (Request["chkResult"] ?? "").Trim().ToUpper(); // PASS or FAIL
            string memo = (Request["chkMemo"] ?? "").Trim();

            if (string.IsNullOrEmpty(facId) || macId <= 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "缺少場所代碼或機具代碼" }));
                return;
            }

            if (result != "PASS" && result != "FAIL")
            {
                Response.Write(json.Serialize(new { Success = false, Message = "請選取審核結果（通過或退件）" }));
                return;
            }

            string stateId = "";
            switch (mode)
            {
                case "MAC1":
                case "INV1":
                    stateId = "A00"; // 初審
                    break;
                case "MAC2":
                case "INV2":
                    stateId = "A01"; // 複審
                    break;
                case "MAC3":
                case "INV3":
                    stateId = "A02"; // 三審 / 爭議
                    break;
                default:
                    Response.Write(json.Serialize(new { Success = false, Message = "非有效審查階段模式：" + mode }));
                    return;
            }

            string currentUser = GetCurrentUser();
            string resultText = (result == "PASS") ? "通過" : "退件";

            try
            {
                // 1. 寫入歷次審查紀錄 Mac_Chk_Result
                string sqlInsertReview = @"
                    INSERT INTO Mac_Chk_Result (FAC_ID, mac_ID, Chk_Date, Chk_Result, Chk_Memo, Mac_State, Chk_User)
                    VALUES (@FAC_ID, @mac_ID, GETDATE(), @Chk_Result, @Chk_Memo, @Mac_State, @Chk_User)";

                DbHelper.ExecuteNonQuery(sqlInsertReview,
                    new SqlParameter("@FAC_ID", facId),
                    new SqlParameter("@mac_ID", macId),
                    new SqlParameter("@Chk_Result", resultText),
                    new SqlParameter("@Chk_Memo", memo),
                    new SqlParameter("@Mac_State", stateId),
                    new SqlParameter("@Chk_User", currentUser));

                // 2. 查詢 mac_State_List 取得 Next_State 與 Back_State
                string sqlState = "SELECT * FROM mac_State_List WHERE State_ID = @State_ID";
                DataTable dtState = DbHelper.ExecuteDataTable(sqlState, new SqlParameter("@State_ID", stateId));

                string nextState = "";
                string backState = "";
                if (dtState != null && dtState.Rows.Count > 0)
                {
                    nextState = dtState.Rows[0]["Next_State"].ToString().Trim();
                    backState = dtState.Rows[0]["Back_State"].ToString().Trim();
                }

                string targetState = (result == "PASS") ? nextState : backState;

                // 3. 更新 Machine_Main 之 Mac_State 狀態
                string sqlUpdateMac = "UPDATE Machine_Main SET Mac_State = @TargetState WHERE FAC_ID = @FAC_ID AND mac_ID = @mac_ID";
                DbHelper.ExecuteNonQuery(sqlUpdateMac,
                    new SqlParameter("@TargetState", targetState),
                    new SqlParameter("@FAC_ID", facId),
                    new SqlParameter("@mac_ID", macId));

                // 4. 計算返回跳轉網址
                string redirectUrl = "managerList.aspx?INV_State=" + mode;
                if (mode == "READ") redirectUrl = "../Machine/macList.aspx";
                else if (mode == "READ1") redirectUrl = "../Machine/macList.aspx?mode=reject";
                else if (mode == "READ2") redirectUrl = "../Machine/macList.aspx?mode=search";
                else if (mode == "READMAC1") redirectUrl = "managerList.aspx?INV_State=MAC1";
                else if (mode == "READMAC2") redirectUrl = "managerList.aspx?INV_State=MAC2";

                Response.Write(json.Serialize(new
                {
                    Success = true,
                    Message = string.Format("【{0}】審查作業完成，結果：{1}！", stateId, resultText),
                    RedirectUrl = redirectUrl
                }));
            }
            catch (Exception ex)
            {
                Response.Write(json.Serialize(new
                {
                    Success = false,
                    Message = "審查送出失敗：" + ex.Message
                }));
            }
        }

        #region TWD97 轉 WGS84 座標轉換標準演算法
        private static void Twd97ToWgs84(double x, double y, out double lat, out double lon)
        {
            if (x <= 0 || y <= 0)
            {
                lat = 0;
                lon = 0;
                return;
            }

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
        #endregion
    }
}
