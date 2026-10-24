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

namespace NTPC_FEC.OwnReport
{
    public partial class PIC_Report : Page
    {
        private JavaScriptSerializer json;

        public PIC_Report()
        {
            json = new JavaScriptSerializer();
            json.MaxJsonLength = int.MaxValue;
        }

        #region 資料模型類別 (相容 C# 5.0，無自動屬性初始化)

        public class ResponseModel
        {
            public bool Success { get; set; }
            public string Message { get; set; }
            public object Data { get; set; }
        }

        public class FacInfoModel
        {
            public string FacId { get; set; }
            public string CNo { get; set; }
            public string FacName { get; set; }
            public string Addr { get; set; }
            public string Tel { get; set; }
            public double Twd97X { get; set; }
            public double Twd97Y { get; set; }
            public double Lat { get; set; }
            public double Lng { get; set; }
        }

        public class InvSummaryModel
        {
            public int InvNo { get; set; }
            public string InvDate { get; set; }
            public string Weather { get; set; }
            public string WorkState { get; set; }
            public string WorkMemo { get; set; }
            public string OtherMemo { get; set; }
            public string ImproveDeadline { get; set; }
            public int TotalLossPoint { get; set; }
            public string StatusAlert { get; set; }
            public string StatusLevel { get; set; }
        }

        public class PhotoItemModel
        {
            public string Key { get; set; }
            public string Title { get; set; }
            public string FileName { get; set; }
            public string Url { get; set; }
            public bool Exists { get; set; }
            public string Memo { get; set; }
        }

        public class ItemSectionModel
        {
            public string Code { get; set; }
            public string Title { get; set; }
            public string LawRule { get; set; }
            public int LossPoint { get; set; }
            public bool HasLoss { get; set; }
            public List<string> CheckItems { get; set; }
            public List<PhotoItemModel> AuditPhotos { get; set; }
            public List<PhotoItemModel> ReportPhotos { get; set; }

            public ItemSectionModel()
            {
                CheckItems = new List<string>();
                AuditPhotos = new List<PhotoItemModel>();
                ReportPhotos = new List<PhotoItemModel>();
            }
        }

        public class ReportDataPackage
        {
            public string Mode { get; set; }
            public int ReportNo { get; set; }
            public string ReportDate { get; set; }
            public string ReportType { get; set; }
            public FacInfoModel FacInfo { get; set; }
            public InvSummaryModel InvSummary { get; set; }
            public List<ItemSectionModel> Sections { get; set; }
            public bool CanEdit { get; set; }

            public ReportDataPackage()
            {
                Sections = new List<ItemSectionModel>();
            }
        }

        #endregion

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
                    Response.Write(json.Serialize(new ResponseModel
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
                case "getdata":
                    GetData();
                    break;
                case "save":
                    SaveReport();
                    break;
                default:
                    Response.Write(json.Serialize(new ResponseModel
                    {
                        Success = false,
                        Message = "未知的指令：" + action
                    }));
                    break;
            }
        }

        #region AJAX: 取得案件資料 (GetData)

        private void GetData()
        {
            string mode = Request["mode"];
            if (string.IsNullOrEmpty(mode)) mode = "wrong";
            mode = mode.ToLower().Trim();

            string facId = Request["id"];
            if (facId != null) facId = facId.Trim();

            // 1. 若未帶入 id 或 id 為空字串，自動由當前登入者 Session 提取所屬公私場所 (相容工廠業者登入)
            if (string.IsNullOrEmpty(facId))
            {
                if (Session["UserAccount"] != null)
                {
                    NTPC_FEC.Models.UserAccount u = Session["UserAccount"] as NTPC_FEC.Models.UserAccount;
                    if (u != null && !string.IsNullOrEmpty(u.FacID))
                    {
                        facId = u.FacID.Trim();
                    }
                }
                if (string.IsNullOrEmpty(facId) && Session["LoginUser"] != null)
                {
                    string uId = Session["LoginUser"].ToString();
                    DataTable dtU = DbHelper.ExecuteDataTable("SELECT FAC_ID FROM UserAcc WHERE UserID = @u", new SqlParameter("@u", uId));
                    if (dtU.Rows.Count > 0 && dtU.Rows[0]["FAC_ID"] != DBNull.Value)
                    {
                        facId = dtU.Rows[0]["FAC_ID"].ToString().Trim();
                    }
                }
            }

            // 2. 若仍無 facId (例如環保局端或管考人員登入，帳號本身無綁定單一工廠)
            if (string.IsNullOrEmpty(facId))
            {
                string sqlFacList = @"
                    SELECT TOP 200 m.FAC_ID, m.FAC_NAME, m.C_NO
                    FROM FAC_Main m
                    ORDER BY 
                        CASE WHEN EXISTS (SELECT 1 FROM INV_DATA i WHERE i.FAC_ID = m.FAC_ID) THEN 0 ELSE 1 END,
                        m.FAC_NAME";
                DataTable dtList = DbHelper.ExecuteDataTable(sqlFacList);
                List<object> facOptions = new List<object>();
                for (int i = 0; i < dtList.Rows.Count; i++)
                {
                    facOptions.Add(new
                    {
                        FacId = dtList.Rows[i]["FAC_ID"].ToString(),
                        FacName = dtList.Rows[i]["FAC_NAME"] != DBNull.Value ? dtList.Rows[i]["FAC_NAME"].ToString() : "",
                        CNo = dtList.Rows[i]["C_NO"] != DBNull.Value ? dtList.Rows[i]["C_NO"].ToString() : ""
                    });
                }

                Response.Write(json.Serialize(new
                {
                    Success = true,
                    NeedSelectFac = true,
                    Message = "當前帳號未綁定特定公私場所，請選取欲回報或檢視之場所：",
                    FacOptions = facOptions
                }));
                return;
            }

            // 安全校驗 Token 驗證 (容錯：今日與前後一小時，或登入狀態則通行)
            string token = Request["id1"];
            if (!ValidateSecurityToken(facId, token))
            {
                Response.Write(json.Serialize(new ResponseModel
                {
                    Success = false,
                    Message = "安全校驗碼錯誤或已逾期，請由主選單重新開啟。"
                }));
                return;
            }

            // 1. 查詢場所基本資料
            string sqlFac = "SELECT TOP 1 * FROM FAC_Main WHERE FAC_ID = @FAC_ID";
            DataTable dtFac = DbHelper.ExecuteDataTable(sqlFac, new SqlParameter("@FAC_ID", facId));
            if (dtFac.Rows.Count == 0)
            {
                Response.Write(json.Serialize(new ResponseModel
                {
                    Success = false,
                    Message = "查無此公私場所基本資料：" + facId
                }));
                return;
            }

            DataRow rFac = dtFac.Rows[0];
            FacInfoModel facInfo = new FacInfoModel();
            facInfo.FacId = facId;
            facInfo.CNo = rFac["C_NO"] != DBNull.Value ? rFac["C_NO"].ToString() : "";
            facInfo.FacName = rFac["FAC_NAME"] != DBNull.Value ? rFac["FAC_NAME"].ToString() : "";
            facInfo.Addr = rFac["ADDR"] != DBNull.Value ? rFac["ADDR"].ToString() : "";
            facInfo.Tel = rFac["TEL"] != DBNull.Value ? rFac["TEL"].ToString() : "";

            double twdX = 0;
            double twdY = 0;
            if (rFac.Table.Columns.Contains("TWD97_X") && rFac["TWD97_X"] != DBNull.Value)
            {
                double.TryParse(rFac["TWD97_X"].ToString(), out twdX);
            }
            if (rFac.Table.Columns.Contains("TWD97_Y") && rFac["TWD97_Y"] != DBNull.Value)
            {
                double.TryParse(rFac["TWD97_Y"].ToString(), out twdY);
            }
            facInfo.Twd97X = twdX;
            facInfo.Twd97Y = twdY;

            double lat = 0;
            double lng = 0;
            if (twdX > 0 && twdY > 0)
            {
                Twd97ToWgs84(twdX, twdY, out lat, out lng);
            }
            facInfo.Lat = lat;
            facInfo.Lng = lng;

            // 2. 依模式取得回報與查核紀錄
            int reqInv = 0;
            int reqRep = 0;
            if (!string.IsNullOrEmpty(Request["inv"])) int.TryParse(Request["inv"], out reqInv);
            if (!string.IsNullOrEmpty(Request["rep"])) int.TryParse(Request["rep"], out reqRep);

            DataRow rReport = null;
            DataRow rInv = null;
            string reportType = "";
            string reportDateStr = "";

            if (mode == "read")
            {
                if (reqRep > 0)
                {
                    string sqlRep = "SELECT TOP 1 * FROM INV_Report WHERE FAC_ID = @FAC_ID AND Report_NO = @Report_NO";
                    DataTable dtRep = DbHelper.ExecuteDataTable(sqlRep,
                        new SqlParameter("@FAC_ID", facId),
                        new SqlParameter("@Report_NO", reqRep));
                    if (dtRep.Rows.Count > 0)
                    {
                        rReport = dtRep.Rows[0];
                        reportType = rReport["Report_Type"] != DBNull.Value ? rReport["Report_Type"].ToString() : "";
                        if (rReport["Report_Date"] != DBNull.Value)
                        {
                            reportDateStr = Convert.ToDateTime(rReport["Report_Date"]).ToString("yyyy-MM-dd HH:mm");
                        }
                        if (reqInv == 0 && rReport["INV_NO"] != DBNull.Value)
                        {
                            int.TryParse(rReport["INV_NO"].ToString(), out reqInv);
                        }
                    }
                }
            }

            // 查詢查核資料 INV_DATA
            if (reqInv > 0)
            {
                string sqlInv = "SELECT TOP 1 * FROM INV_DATA WHERE FAC_ID = @FAC_ID AND INV_NO = @INV_NO";
                DataTable dtInv = DbHelper.ExecuteDataTable(sqlInv,
                    new SqlParameter("@FAC_ID", facId),
                    new SqlParameter("@INV_NO", reqInv));
                if (dtInv.Rows.Count > 0) rInv = dtInv.Rows[0];
            }
            else
            {
                // 抓取最新查核資料
                string sqlInv = "SELECT TOP 1 * FROM INV_DATA WHERE FAC_ID = @FAC_ID AND INV_State <> 'Z00' AND INV_State <> 'A00b' ORDER BY INV_DATE DESC";
                DataTable dtInv = DbHelper.ExecuteDataTable(sqlInv, new SqlParameter("@FAC_ID", facId));
                if (dtInv.Rows.Count > 0)
                {
                    rInv = dtInv.Rows[0];
                    if (rInv["INV_NO"] != DBNull.Value)
                    {
                        int.TryParse(rInv["INV_NO"].ToString(), out reqInv);
                    }
                }
            }

            InvSummaryModel invSummary = new InvSummaryModel();
            invSummary.InvNo = reqInv;

            if (rInv != null)
            {
                if (rInv["INV_DATE"] != DBNull.Value)
                {
                    invSummary.InvDate = Convert.ToDateTime(rInv["INV_DATE"]).ToString("yyyy-MM-dd HH:mm");
                }
                invSummary.Weather = rInv["weather"] != DBNull.Value ? rInv["weather"].ToString() : "晴";
                invSummary.WorkState = rInv["Work_State"] != DBNull.Value ? rInv["Work_State"].ToString() : "正常操作";
                invSummary.WorkMemo = rInv["Work_Memo"] != DBNull.Value ? rInv["Work_Memo"].ToString() : "無";
                invSummary.OtherMemo = rInv["Other_Memo"] != DBNull.Value ? rInv["Other_Memo"].ToString() : "無";
                if (rInv["improve_Deadline"] != DBNull.Value)
                {
                    invSummary.ImproveDeadline = Convert.ToDateTime(rInv["improve_Deadline"]).ToString("yyyy-MM-dd");
                }

                // 計算缺失點數
                int totalLoss = CalculateTotalLoss(rInv);
                invSummary.TotalLossPoint = totalLoss;

                if (totalLoss == 0)
                {
                    invSummary.StatusAlert = "查核結果：無缺失情形，防制設施均符合規範。";
                    invSummary.StatusLevel = "success";
                }
                else if (totalLoss < 10)
                {
                    invSummary.StatusAlert = string.Format("查核結果：缺失點數合計 {0} 點（未達10點），限期於 {1} 前完成改善並回報。", totalLoss, invSummary.ImproveDeadline);
                    invSummary.StatusLevel = "warning";
                }
                else
                {
                    invSummary.StatusAlert = string.Format("查核結果：缺失點數合計 {0} 點（達10點以上），屬嚴重缺失依違反本辦法規定處分。", totalLoss);
                    invSummary.StatusLevel = "danger";
                }
            }
            else
            {
                invSummary.StatusAlert = "尚無現場查核紀錄";
                invSummary.StatusLevel = "info";
            }

            // 3. 組合九大項細部內容
            List<ItemSectionModel> sections = BuildNineSections(facId, reqInv, reqRep, rInv, rReport, mode);

            ReportDataPackage package = new ReportDataPackage();
            package.Mode = mode;
            package.ReportNo = reqRep;
            package.ReportDate = reportDateStr;
            package.ReportType = reportType;
            package.FacInfo = facInfo;
            package.InvSummary = invSummary;
            package.Sections = sections;
            package.CanEdit = (mode == "wrong" || mode == "own");

            Response.Write(json.Serialize(new ResponseModel
            {
                Success = true,
                Message = "讀取成功",
                Data = package
            }));
        }

        #endregion

        #region AJAX: 儲存回報 (SaveReport)

        private void SaveReport()
        {
            string facId = Request["FAC_ID"];
            if (facId != null) facId = facId.Trim();
            if (string.IsNullOrEmpty(facId))
            {
                Response.Write(json.Serialize(new ResponseModel { Success = false, Message = "未提供場所管制編號" }));
                return;
            }

            string mode = Request["mode"];
            if (string.IsNullOrEmpty(mode)) mode = "wrong";
            mode = mode.ToLower().Trim();

            int invNo = 0;
            if (!string.IsNullOrEmpty(Request["INV_NO"])) int.TryParse(Request["INV_NO"], out invNo);

            string reportType = (mode == "own") ? "自主回報" : "缺失改善";

            // 計算新的 Report_NO
            string sqlMax = "SELECT ISNULL(MAX(Report_NO), 0) FROM INV_Report WHERE FAC_ID = @FAC_ID";
            object objMax = DbHelper.ExecuteScalar(sqlMax, new SqlParameter("@FAC_ID", facId));
            int newReportNo = 1;
            if (objMax != null && objMax != DBNull.Value)
            {
                newReportNo = Convert.ToInt32(objMax) + 1;
            }

            // 提取各欄位補充說明 (FileMemo_A1~A5, B1~B2, ... I1~I2)
            Dictionary<string, string> memoDict = new Dictionary<string, string>();
            string[] keys = new string[]
            {
                "A1", "A2", "A3", "A4", "A5",
                "B1", "B2",
                "C1", "C2",
                "D1", "D2",
                "E1", "E2",
                "F1", "F2",
                "G1", "G2",
                "H1", "H2",
                "I1", "I2"
            };

            for (int i = 0; i < keys.Length; i++)
            {
                string k = keys[i];
                string val = Request["FileMemo_" + k];
                if (val == null) val = "";
                memoDict["FileMemo_" + k] = val.Trim();
            }

            // 寫入 INV_Report
            string sqlInsert = @"
                INSERT INTO INV_Report (
                    FAC_ID, INV_NO, Report_NO, Report_Date, Report_Type,
                    FileMemo_A1, FileMemo_A2, FileMemo_A3, FileMemo_A4, FileMemo_A5,
                    FileMemo_B1, FileMemo_B2,
                    FileMemo_C1, FileMemo_C2,
                    FileMemo_D1, FileMemo_D2,
                    FileMemo_E1, FileMemo_E2,
                    FileMemo_F1, FileMemo_F2,
                    FileMemo_G1, FileMemo_G2,
                    FileMemo_H1, FileMemo_H2,
                    FileMemo_I1, FileMemo_I2
                ) VALUES (
                    @FAC_ID, @INV_NO, @Report_NO, @Report_Date, @Report_Type,
                    @FileMemo_A1, @FileMemo_A2, @FileMemo_A3, @FileMemo_A4, @FileMemo_A5,
                    @FileMemo_B1, @FileMemo_B2,
                    @FileMemo_C1, @FileMemo_C2,
                    @FileMemo_D1, @FileMemo_D2,
                    @FileMemo_E1, @FileMemo_E2,
                    @FileMemo_F1, @FileMemo_F2,
                    @FileMemo_G1, @FileMemo_G2,
                    @FileMemo_H1, @FileMemo_H2,
                    @FileMemo_I1, @FileMemo_I2
                )";

            List<SqlParameter> pList = new List<SqlParameter>();
            pList.Add(new SqlParameter("@FAC_ID", facId));
            pList.Add(new SqlParameter("@INV_NO", invNo));
            pList.Add(new SqlParameter("@Report_NO", newReportNo));
            pList.Add(new SqlParameter("@Report_Date", DateTime.Now));
            pList.Add(new SqlParameter("@Report_Type", reportType));

            for (int i = 0; i < keys.Length; i++)
            {
                string k = "FileMemo_" + keys[i];
                pList.Add(new SqlParameter("@" + k, memoDict[k]));
            }

            DbHelper.ExecuteNonQuery(sqlInsert, pList.ToArray());

            // 處理照片儲存
            // 建立目錄 Upload/ReportPIC/{FAC_ID}/{Report_NO}/
            string targetFolder = Server.MapPath(string.Format("~/Upload/ReportPIC/{0}/{1}", facId, newReportNo));
            if (!Directory.Exists(targetFolder))
            {
                Directory.CreateDirectory(targetFolder);
            }

            // 接收上傳檔案 (支援傳統 multipart 與 base64 兩種方式)
            // 檔名規格對照表
            Dictionary<string, string> photoNameMap = GetStandardPhotoNames();

            // 方式 1: 直接上傳的檔案 (HttpFileCollection)
            if (Request.Files.Count > 0)
            {
                for (int i = 0; i < Request.Files.Count; i++)
                {
                    HttpPostedFile file = Request.Files[i];
                    if (file != null && file.ContentLength > 0)
                    {
                        string fieldKey = Request.Files.GetKey(i);
                        string fileName = "";
                        if (photoNameMap.ContainsKey(fieldKey))
                        {
                            string ext = Path.GetExtension(file.FileName);
                            if (string.IsNullOrEmpty(ext)) ext = ".jpg";
                            fileName = photoNameMap[fieldKey] + ext;
                        }
                        else
                        {
                            fileName = Path.GetFileName(file.FileName);
                        }

                        string savePath = Path.Combine(targetFolder, fileName);
                        file.SaveAs(savePath);
                    }
                }
            }

            // 方式 2: Base64 上傳 (前端若以 DataURL 傳送)
            for (int i = 0; i < keys.Length; i++)
            {
                string k = keys[i];
                string base64Data = Request["PhotoBase64_" + k];
                if (!string.IsNullOrEmpty(base64Data))
                {
                    SaveBase64Image(base64Data, targetFolder, photoNameMap[k] + ".jpg");
                }
            }

            Response.Write(json.Serialize(new ResponseModel
            {
                Success = true,
                Message = "回報已成功送出！",
                Data = new
                {
                    ReportNo = newReportNo,
                    FacId = facId,
                    ReportType = reportType
                }
            }));
        }

        private void SaveBase64Image(string base64Data, string folderPath, string fileName)
        {
            try
            {
                int commaIdx = base64Data.IndexOf(",");
                if (commaIdx >= 0)
                {
                    base64Data = base64Data.Substring(commaIdx + 1);
                }
                byte[] bytes = Convert.FromBase64String(base64Data);
                string fullPath = Path.Combine(folderPath, fileName);
                File.WriteAllBytes(fullPath, bytes);
            }
            catch
            {
            }
        }

        private Dictionary<string, string> GetStandardPhotoNames()
        {
            Dictionary<string, string> map = new Dictionary<string, string>();
            map["A1"] = "回報_堆罝逸散性粒狀污染物質";
            map["A2"] = "回報_堆罝逸散性粒狀污染物質1";
            map["A3"] = "回報_堆罝逸散性粒狀污染物質2";
            map["A4"] = "回報_堆罝逸散性粒狀污染物質3";
            map["A5"] = "回報_堆罝逸散性粒狀污染物質4";

            map["B1"] = "回報_輸送逸散性粒狀污染物質";
            map["B2"] = "回報_輸送逸散性粒狀污染物質1";

            map["C1"] = "回報_運輸車輛";
            map["C2"] = "回報_運輸車輛1";

            map["D1"] = "回報_車輛通行路徑";
            map["D2"] = "回報_車輛通行路徑1";

            map["E1"] = "回報_車輛清洗";
            map["E2"] = "回報_車輛清洗1";

            map["F1"] = "回報_易致粒狀污染物逸散之製程、操作或裝卸作業";
            map["F2"] = "回報_易致粒狀污染物逸散之製程、操作或裝卸作業1";

            map["G1"] = "回報_公私場所管理之裸露區域";
            map["G2"] = "回報_公私場所管理之裸露區域1";

            map["H1"] = "回報_公私場所管理之道路";
            map["H2"] = "回報_公私場所管理之道路1";

            map["I1"] = "回報_攝錄影監視系統";
            map["I2"] = "回報_攝錄影監視系統1";

            return map;
        }

        #endregion

        #region 九大項細部內容建置 (BuildNineSections)

        private List<ItemSectionModel> BuildNineSections(string facId, int invNo, int repNo, DataRow rInv, DataRow rRep, string mode)
        {
            List<ItemSectionModel> list = new List<ItemSectionModel>();

            // A: 堆置 (第4條)
            list.Add(BuildSectionA(facId, invNo, repNo, rInv, rRep));

            // B: 輸送 (第5條)
            list.Add(BuildSectionB(facId, invNo, repNo, rInv, rRep));

            // C: 運輸車輛 (第6條第1款)
            list.Add(BuildSectionC(facId, invNo, repNo, rInv, rRep));

            // D: 車輛通行路徑 (第6條第2款)
            list.Add(BuildSectionD(facId, invNo, repNo, rInv, rRep));

            // E: 車輛清洗 (第6條第3款)
            list.Add(BuildSectionE(facId, invNo, repNo, rInv, rRep));

            // F: 易致粒狀污染物製程/裝卸 (第7條)
            list.Add(BuildSectionF(facId, invNo, repNo, rInv, rRep));

            // G: 裸露區域 (第8條)
            list.Add(BuildSectionG(facId, invNo, repNo, rInv, rRep));

            // H: 管理之道路 (第9條)
            list.Add(BuildSectionH(facId, invNo, repNo, rInv, rRep));

            // I: 攝錄影監視系統 (第11條)
            list.Add(BuildSectionI(facId, invNo, repNo, rInv, rRep));

            return list;
        }

        private ItemSectionModel BuildSectionA(string facId, int invNo, int repNo, DataRow rInv, DataRow rRep)
        {
            ItemSectionModel sec = new ItemSectionModel();
            sec.Code = "01";
            sec.Title = "一、堆置逸散性粒狀污染物質";
            sec.LawRule = "固定污染源逸散性粒狀污染物空氣污染防制設施管理辦法 第4條";

            if (rInv != null)
            {
                sec.LossPoint = CalLossOne(rInv, "01");
                sec.HasLoss = (sec.LossPoint > 0);

                if (IsCheck(rInv, "INV_01_01")) sec.CheckItems.Add("無本項製程作業。");
                if (IsCheck(rInv, "INV_01_02")) sec.CheckItems.Add("A1 依規定設置或採行空氣污染防制設施。");
                if (IsCheck(rInv, "INV_01_03")) sec.CheckItems.Add("A2 依環保局核定之替代方法設置或採行污染防制設施：" + GetVal(rInv, "INV_01_03_Memo"));
                if (IsCheck(rInv, "INV_01_04")) sec.CheckItems.Add("B1 未設置或採行本辦法第四條第一項第一款至第五款規定防制設施之一。");
                if (IsCheck(rInv, "INV_01_05")) sec.CheckItems.Add("B2 未依直轄市、縣（市）主管機關同意後之替代方法執行。");
                if (IsCheck(rInv, "INV_01_08")) sec.CheckItems.Add("C1 採堆置於封閉式建築物內者，建築物未符合第二條第二款規定。");
                if (IsCheck(rInv, "INV_01_09"))
                {
                    string sub = "C2 採堆置區四周以防塵網或阻隔牆圍封者，有下列情形：";
                    if (IsCheck(rInv, "INV_01_09a")) sub += " 高度未達堆置高度1.25倍；";
                    if (IsCheck(rInv, "INV_01_09b")) sub += " 未完全圍封；";
                    if (IsCheck(rInv, "INV_01_09c")) sub += " 破損達圍封面積10%以上；";
                    if (IsCheck(rInv, "INV_01_09d")) sub += " 體積達3,000m³或年堆置6萬公噸以上未採相應設施；";
                    sec.CheckItems.Add(sub.TrimEnd('；'));
                }
                if (IsCheck(rInv, "INV_01_10"))
                {
                    string sub = "C3 採覆蓋防塵布或防塵網者：";
                    if (IsCheck(rInv, "INV_01_10a")) sub += " 覆蓋面積未達堆置區面積80%；";
                    if (IsCheck(rInv, "INV_01_10b")) sub += " 三級防制區覆蓋面積未達90%；";
                    sec.CheckItems.Add(sub.TrimEnd('；'));
                }
                if (IsCheck(rInv, "INV_01_11"))
                {
                    string sub = "C4 採噴灑化學穩定劑者：";
                    if (IsCheck(rInv, "INV_01_11a")) sub += " 噴灑面積未達80%；";
                    if (IsCheck(rInv, "INV_01_11b")) sub += " 三級防制區未達90%；";
                    if (IsCheck(rInv, "INV_01_11c")) sub += " 未依規定記錄藥劑名稱用量或未保存購買證明；";
                    sec.CheckItems.Add(sub.TrimEnd('；'));
                }
                if (IsCheck(rInv, "INV_01_12"))
                {
                    string sub = "C5 採自動灑水設備者：";
                    if (IsCheck(rInv, "INV_01_12a")) sub += " 灑水範圍水量頻率不足；";
                    if (IsCheck(rInv, "INV_01_12b")) sub += " 需人工操作無法自動灑水；";
                    if (IsCheck(rInv, "INV_01_12c")) sub += " 未設水表或未每日記錄用水量；";
                    sec.CheckItems.Add(sub.TrimEnd('；'));
                }
                if (IsCheck(rInv, "INV_01_14")) sec.CheckItems.Add("C6 替代方法未依核定方式完整執行。");
                if (IsCheck(rInv, "INV_01_13")) sec.CheckItems.Add("C7 堆置區四周未設阻隔設備及防溢座，或物料溢流至堆置區外。");

                // 查核現場照片 (Audit Photos)
                sec.AuditPhotos.Add(FindPic(facId, invNo, "堆罝逸散性粒狀污染物質", "PIC", "現場全景", GetVal(rInv, "FileMemo_1")));
                sec.AuditPhotos.Add(FindPic(facId, invNo, "堆罝逸散性粒狀污染物質_2", "PIC", "現場近景", GetVal(rInv, "FileMemo_1a")));
                sec.AuditPhotos.Add(FindPic(facId, invNo, "堆罝逸散性粒狀污染物質_自動灑水水表", "PIC", "自動灑水水表", GetVal(rInv, "FileMemo_1b")));
                sec.AuditPhotos.Add(FindPic(facId, invNo, "堆罝逸散性粒狀污染物質_上月紀錄表", "PIC", "上月紀錄表", GetVal(rInv, "FileMemo_1c")));
                sec.AuditPhotos.Add(FindPic(facId, invNo, "堆罝逸散性粒狀污染物質_本月紀錄表", "PIC", "本月紀錄表", GetVal(rInv, "FileMemo_1d")));
            }

            // 回報照片 (Report Photos)
            sec.ReportPhotos.Add(FindReportPic(facId, repNo, "A1", "回報_堆罝逸散性粒狀污染物質", "改善回報照片 1", rRep, "FileMemo_A1"));
            sec.ReportPhotos.Add(FindReportPic(facId, repNo, "A2", "回報_堆罝逸散性粒狀污染物質1", "改善回報照片 2", rRep, "FileMemo_A2"));
            sec.ReportPhotos.Add(FindReportPic(facId, repNo, "A3", "回報_堆罝逸散性粒狀污染物質2", "改善回報照片 3", rRep, "FileMemo_A3"));
            sec.ReportPhotos.Add(FindReportPic(facId, repNo, "A4", "回報_堆罝逸散性粒狀污染物質3", "改善回報照片 4", rRep, "FileMemo_A4"));
            sec.ReportPhotos.Add(FindReportPic(facId, repNo, "A5", "回報_堆罝逸散性粒狀污染物質4", "改善回報照片 5", rRep, "FileMemo_A5"));

            return sec;
        }

        private ItemSectionModel BuildSectionB(string facId, int invNo, int repNo, DataRow rInv, DataRow rRep)
        {
            ItemSectionModel sec = new ItemSectionModel();
            sec.Code = "02";
            sec.Title = "二、輸送逸散性粒狀污染物質";
            sec.LawRule = "固定污染源逸散性粒狀污染物空氣污染防制設施管理辦法 第5條";

            if (rInv != null)
            {
                sec.LossPoint = CalLossOne(rInv, "02");
                sec.HasLoss = (sec.LossPoint > 0);

                if (IsCheck(rInv, "INV_02_01")) sec.CheckItems.Add("無本項製程作業。");
                if (IsCheck(rInv, "INV_02_03")) sec.CheckItems.Add("A1 依規定設置或採行空氣污染防制設施。");
                if (IsCheck(rInv, "INV_02_02")) sec.CheckItems.Add("A2 採濕式製程作業者，得免設置防制設施。");
                if (IsCheck(rInv, "INV_02_04")) sec.CheckItems.Add("A3 依環保局核定之替代方法設置防制設施：" + GetVal(rInv, "INV_02_04_Memo"));
                if (IsCheck(rInv, "INV_02_05")) sec.CheckItems.Add("B1 未設置或採行第五條第一款至第三款防制設施之一。");
                if (IsCheck(rInv, "INV_02_06")) sec.CheckItems.Add("B2 未依同意後之替代方法執行。");
                if (IsCheck(rInv, "INV_02_07")) sec.CheckItems.Add("C1 採封閉式建築物操作者，建築物不符規定。");
                if (IsCheck(rInv, "INV_02_08")) sec.CheckItems.Add("C2 採用密閉式輸送系統者，輸送管道未完全密閉或有破損。");
                if (IsCheck(rInv, "INV_02_09"))
                {
                    string sub = "C3 採用局部集氣系統者：";
                    if (IsCheck(rInv, "INV_02_09a")) sub += " 捕捉速度不足；";
                    if (IsCheck(rInv, "INV_02_09b")) sub += " 未設監測儀表或未記錄項目；";
                    sec.CheckItems.Add(sub.TrimEnd('；'));
                }
                if (IsCheck(rInv, "INV_02_10"))
                {
                    string sub = "C4 採用灑水設施者：";
                    if (IsCheck(rInv, "INV_02_10a")) sub += " 噴灑範圍水量頻率不足；";
                    if (IsCheck(rInv, "INV_02_10b")) sub += " 需人工操作無法自動灑水；";
                    if (IsCheck(rInv, "INV_02_10c")) sub += " 未設水表或未每日記錄；";
                    sec.CheckItems.Add(sub.TrimEnd('；'));
                }

                sec.AuditPhotos.Add(FindPic(facId, invNo, "輸送逸散性粒狀污染物質", "PIC", "輸送設備現況", GetVal(rInv, "FileMemo_2")));
                sec.AuditPhotos.Add(FindPic(facId, invNo, "輸送逸散性粒狀污染物質_2", "PIC", "輸送設備細部", GetVal(rInv, "FileMemo_2a")));
            }

            sec.ReportPhotos.Add(FindReportPic(facId, repNo, "B1", "回報_輸送逸散性粒狀污染物質", "改善回報照片 1", rRep, "FileMemo_B1"));
            sec.ReportPhotos.Add(FindReportPic(facId, repNo, "B2", "回報_輸送逸散性粒狀污染物質1", "改善回報照片 2", rRep, "FileMemo_B2"));

            return sec;
        }

        private ItemSectionModel BuildSectionC(string facId, int invNo, int repNo, DataRow rInv, DataRow rRep)
        {
            ItemSectionModel sec = new ItemSectionModel();
            sec.Code = "03";
            sec.Title = "三、運輸車輛";
            sec.LawRule = "固定污染源逸散性粒狀污染物空氣污染防制設施管理辦法 第6條第1款";

            if (rInv != null)
            {
                sec.LossPoint = CalLossOne(rInv, "03");
                sec.HasLoss = (sec.LossPoint > 0);

                if (IsCheck(rInv, "INV_03_01")) sec.CheckItems.Add("無本項製程作業。");
                if (IsCheck(rInv, "INV_03_02")) sec.CheckItems.Add("A1 依規定設置或採行空氣污染防制設施。");
                if (IsCheck(rInv, "INV_03_03")) sec.CheckItems.Add("A2 依替代方法設置防制設施：" + GetVal(rInv, "INV_03_03_Memo"));
                if (IsCheck(rInv, "INV_03_04")) sec.CheckItems.Add("B1 運輸車輛未使用密閉式貨箱，或未緊密覆蓋。");
                if (IsCheck(rInv, "INV_03_05")) sec.CheckItems.Add("B2 貨箱未具備防止滴落污水、污泥之功能或設施。");
                if (IsCheck(rInv, "INV_03_06")) sec.CheckItems.Add("B3 未依同意後之替代方法執行。");
                if (IsCheck(rInv, "INV_03_07")) sec.CheckItems.Add("C1 封蓋未緊密覆蓋貨箱(防塵布網未延伸覆蓋至上緣以下15公分)。");
                if (IsCheck(rInv, "INV_03_08")) sec.CheckItems.Add("C2 運輸過程仍滴落污水、污泥或掉落物料於地面。");

                sec.AuditPhotos.Add(FindPic(facId, invNo, "運輸車輛", "PIC", "運輸車輛現況", GetVal(rInv, "FileMemo_3")));
                sec.AuditPhotos.Add(FindPic(facId, invNo, "運輸車輛_2", "PIC", "車輛覆蓋現況", GetVal(rInv, "FileMemo_3a")));
            }

            sec.ReportPhotos.Add(FindReportPic(facId, repNo, "C1", "回報_運輸車輛", "改善回報照片 1", rRep, "FileMemo_C1"));
            sec.ReportPhotos.Add(FindReportPic(facId, repNo, "C2", "回報_運輸車輛1", "改善回報照片 2", rRep, "FileMemo_C2"));

            return sec;
        }

        private ItemSectionModel BuildSectionD(string facId, int invNo, int repNo, DataRow rInv, DataRow rRep)
        {
            ItemSectionModel sec = new ItemSectionModel();
            sec.Code = "04";
            sec.Title = "四、車輛通行路徑及區域";
            sec.LawRule = "固定污染源逸散性粒狀污染物空氣污染防制設施管理辦法 第6條第2款";

            if (rInv != null)
            {
                sec.LossPoint = CalLossOne(rInv, "04");
                sec.HasLoss = (sec.LossPoint > 0);

                if (IsCheck(rInv, "INV_04_01")) sec.CheckItems.Add("無本項製程作業。");
                if (IsCheck(rInv, "INV_04_02")) sec.CheckItems.Add("A1 依規定設置或採行空氣污染防制設施。");
                if (IsCheck(rInv, "INV_04_03")) sec.CheckItems.Add("A2 依替代方法設置防制設施：" + GetVal(rInv, "INV_04_03_Memo"));
                if (IsCheck(rInv, "INV_04_04")) sec.CheckItems.Add("B1 通行路徑及區域未依規定設置防制設施。");
                if (IsCheck(rInv, "INV_04_05")) sec.CheckItems.Add("B2 未依同意後之替代方法執行。");
                if (IsCheck(rInv, "INV_04_06")) sec.CheckItems.Add("C1 設置或採行防制設施之面積不足。");
                if (IsCheck(rInv, "INV_04_07")) sec.CheckItems.Add("C2 舖設混凝土/瀝青/鋼板，惟有路面色差。");
                if (IsCheck(rInv, "INV_04_08")) sec.CheckItems.Add("C3 舖設粗級配或粒料厚度不足，或未灑水保持濕潤。");
                if (IsCheck(rInv, "INV_04_09")) sec.CheckItems.Add("C9 替代設施未完全符合核定之內容。");

                sec.AuditPhotos.Add(FindPic(facId, invNo, "車輛通行路徑", "PIC", "通行路徑現況", GetVal(rInv, "FileMemo_4")));
                sec.AuditPhotos.Add(FindPic(facId, invNo, "車輛通行路徑_2", "PIC", "通行路徑色差檢視", GetVal(rInv, "FileMemo_4a")));
            }

            sec.ReportPhotos.Add(FindReportPic(facId, repNo, "D1", "回報_車輛通行路徑", "改善回報照片 1", rRep, "FileMemo_D1"));
            sec.ReportPhotos.Add(FindReportPic(facId, repNo, "D2", "回報_車輛通行路徑1", "改善回報照片 2", rRep, "FileMemo_D2"));

            return sec;
        }

        private ItemSectionModel BuildSectionE(string facId, int invNo, int repNo, DataRow rInv, DataRow rRep)
        {
            ItemSectionModel sec = new ItemSectionModel();
            sec.Code = "05";
            sec.Title = "五、車輛清洗";
            sec.LawRule = "固定污染源逸散性粒狀污染物空氣污染防制設施管理辦法 第6條第3款";

            if (rInv != null)
            {
                sec.LossPoint = CalLossOne(rInv, "05");
                sec.HasLoss = (sec.LossPoint > 0);

                if (IsCheck(rInv, "INV_05_01")) sec.CheckItems.Add("無本項製程作業。");
                if (IsCheck(rInv, "INV_05_02")) sec.CheckItems.Add("A1 依規定設置或採行空氣污染防制設施。");
                if (IsCheck(rInv, "INV_05_03")) sec.CheckItems.Add("A2 依替代方法設置防制設施：" + GetVal(rInv, "INV_05_03_Memo"));
                if (IsCheck(rInv, "INV_05_04")) sec.CheckItems.Add("B1 未以加壓沖洗設備清洗車體及輪胎。");
                if (IsCheck(rInv, "INV_05_06")) sec.CheckItems.Add("B2 未依同意後之替代方法執行。");
                if (IsCheck(rInv, "INV_05_05")) sec.CheckItems.Add("B3 須洗掃出入口鄰接道路並設置自動洗車設備者，未依規定執行或設置。");
                if (IsCheck(rInv, "INV_05_07")) sec.CheckItems.Add("C1 車輛未清洗乾淨，致門口及鄰近路面有帶出之粒狀物污染。");
                if (IsCheck(rInv, "INV_05_08")) sec.CheckItems.Add("C2 洗車設備無加壓沖洗功能。");
                if (IsCheck(rInv, "INV_05_09")) sec.CheckItems.Add("C3 自動洗車設備規格未符合附表二規定。");
                if (IsCheck(rInv, "INV_05_10")) sec.CheckItems.Add("C4 未依規定設置水表或電表，或未每日記錄。");

                sec.AuditPhotos.Add(FindPic(facId, invNo, "車輛清洗", "PIC", "洗車台現況", ""));
                sec.AuditPhotos.Add(FindPic(facId, invNo, "車輛清洗_2", "PIC", "洗車設施操作", ""));
            }

            sec.ReportPhotos.Add(FindReportPic(facId, repNo, "E1", "回報_車輛清洗", "改善回報照片 1", rRep, "FileMemo_E1"));
            sec.ReportPhotos.Add(FindReportPic(facId, repNo, "E2", "回報_車輛清洗1", "改善回報照片 2", rRep, "FileMemo_E2"));

            return sec;
        }

        private ItemSectionModel BuildSectionF(string facId, int invNo, int repNo, DataRow rInv, DataRow rRep)
        {
            ItemSectionModel sec = new ItemSectionModel();
            sec.Code = "06";
            sec.Title = "六、易致粒狀污染物逸散之製程、操作或裝卸作業";
            sec.LawRule = "固定污染源逸散性粒狀污染物空氣污染防制設施管理辦法 第7條";

            if (rInv != null)
            {
                sec.LossPoint = CalLossOne(rInv, "06");
                sec.HasLoss = (sec.LossPoint > 0);

                if (IsCheck(rInv, "INV_06_01")) sec.CheckItems.Add("無本項製程作業。");
                if (IsCheck(rInv, "INV_06_03")) sec.CheckItems.Add("A1 依規定設置或採行空氣污染防制設施。");
                if (IsCheck(rInv, "INV_06_02")) sec.CheckItems.Add("A2 採濕式製程作業者免設防制設施。");
                if (IsCheck(rInv, "INV_06_04")) sec.CheckItems.Add("A3 依替代方法設置防制設施：" + GetVal(rInv, "INV_06_04_Memo"));
                if (IsCheck(rInv, "INV_06_05")) sec.CheckItems.Add("B1 未設置或採行第七條第一款至第五款防制設施之一。");
                if (IsCheck(rInv, "INV_06_06")) sec.CheckItems.Add("B2 未依同意後之替代方法執行。");
                if (IsCheck(rInv, "INV_06_07"))
                {
                    string sub = "C1 採用圍封式集氣系統者：";
                    if (IsCheck(rInv, "INV_06_07a")) sub += " 未維持負壓狀態；";
                    if (IsCheck(rInv, "INV_06_07b")) sub += " 未設監測儀表或未記錄項目；";
                    sec.CheckItems.Add(sub.TrimEnd('；'));
                }
                if (IsCheck(rInv, "INV_06_08"))
                {
                    string sub = "C2 採用局部集氣系統者：";
                    if (IsCheck(rInv, "INV_06_08a")) sub += " 捕捉速度不足；";
                    if (IsCheck(rInv, "INV_06_08b")) sub += " 未設監測儀表或未記錄項目；";
                    sec.CheckItems.Add(sub.TrimEnd('；'));
                }
                if (IsCheck(rInv, "INV_06_09")) sec.CheckItems.Add("C3 密閉式作業未妥善密閉或設備管道破損。");
                if (IsCheck(rInv, "INV_06_10")) sec.CheckItems.Add("C4 於封閉式建築物內操作不符規定。");
                if (IsCheck(rInv, "INV_06_11")) sec.CheckItems.Add("C5 採用灑水設施者噴灑範圍水量頻率不足。");

                sec.AuditPhotos.Add(FindPic(facId, invNo, "易致粒狀污染物逸散之製程、操作或裝卸作業", "PIC", "製程操作現況", ""));
                sec.AuditPhotos.Add(FindPic(facId, invNo, "易致粒狀污染物逸散之製程、操作或裝卸作業_2", "PIC", "裝卸設施細部", ""));
            }

            sec.ReportPhotos.Add(FindReportPic(facId, repNo, "F1", "回報_易致粒狀污染物逸散之製程、操作或裝卸作業", "改善回報照片 1", rRep, "FileMemo_F1"));
            sec.ReportPhotos.Add(FindReportPic(facId, repNo, "F2", "回報_易致粒狀污染物逸散之製程、操作或裝卸作業1", "改善回報照片 2", rRep, "FileMemo_F2"));

            return sec;
        }

        private ItemSectionModel BuildSectionG(string facId, int invNo, int repNo, DataRow rInv, DataRow rRep)
        {
            ItemSectionModel sec = new ItemSectionModel();
            sec.Code = "07";
            sec.Title = "七、公私場所管理之裸露區域";
            sec.LawRule = "固定污染源逸散性粒狀污染物空氣污染防制設施管理辦法 第8條";

            if (rInv != null)
            {
                sec.LossPoint = CalLossOne(rInv, "07");
                sec.HasLoss = (sec.LossPoint > 0);

                if (IsCheck(rInv, "INV_07_01")) sec.CheckItems.Add("無本項製程作業。");
                if (IsCheck(rInv, "INV_07_02")) sec.CheckItems.Add("A1 依規定設置或採行空氣污染防制設施。");
                if (IsCheck(rInv, "INV_07_03")) sec.CheckItems.Add("A2 依替代方法設置防制設施：" + GetVal(rInv, "INV_07_03_Memo"));
                if (IsCheck(rInv, "INV_07_04")) sec.CheckItems.Add("B1 未設置或採行第八條第一項第一款至第七款防制設施之一。");
                if (IsCheck(rInv, "INV_07_05")) sec.CheckItems.Add("B2 未依同意後之替代方法執行。");
                if (IsCheck(rInv, "INV_07_06")) sec.CheckItems.Add("C1 防制設施未完整涵蓋裸露區域。");
                if (IsCheck(rInv, "INV_07_07")) sec.CheckItems.Add("C2 採植生綠化或覆蓋稻草蓆/碎木厚度不足。");
                if (IsCheck(rInv, "INV_07_08")) sec.CheckItems.Add("C3 舖設粗級配或粒料粒徑厚度不足，或未灑水保持濕潤。");
                if (IsCheck(rInv, "INV_07_09")) sec.CheckItems.Add("C4 噴灑化學穩定劑或灑水措施噴灑量或頻率不足。");
                if (IsCheck(rInv, "INV_07_10")) sec.CheckItems.Add("C5 噴灑化學穩定劑未依規定記錄藥劑名稱用量或未保存購買證明。");

                sec.AuditPhotos.Add(FindPic(facId, invNo, "公私場所管理之裸露區域", "PIC", "裸露地面現況", ""));
                sec.AuditPhotos.Add(FindPic(facId, invNo, "公私場所管理之裸露區域_2", "PIC", "裸露防塵設施", ""));
            }

            sec.ReportPhotos.Add(FindReportPic(facId, repNo, "G1", "回報_公私場所管理之裸露區域", "改善回報照片 1", rRep, "FileMemo_G1"));
            sec.ReportPhotos.Add(FindReportPic(facId, repNo, "G2", "回報_公私場所管理之裸露區域1", "改善回報照片 2", rRep, "FileMemo_G2"));

            return sec;
        }

        private ItemSectionModel BuildSectionH(string facId, int invNo, int repNo, DataRow rInv, DataRow rRep)
        {
            ItemSectionModel sec = new ItemSectionModel();
            sec.Code = "08";
            sec.Title = "八、公私場所管理之道路";
            sec.LawRule = "固定污染源逸散性粒狀污染物空氣污染防制設施管理辦法 第9條";

            if (rInv != null)
            {
                sec.LossPoint = CalLossOne(rInv, "08");
                sec.HasLoss = (sec.LossPoint > 0);

                if (IsCheck(rInv, "INV_08_01")) sec.CheckItems.Add("無本項製程作業。");
                if (IsCheck(rInv, "INV_08_02")) sec.CheckItems.Add("A1 依規定設置或採行空氣污染防制設施。");
                if (IsCheck(rInv, "INV_08_03")) sec.CheckItems.Add("A2 依替代方法設置防制設施：" + GetVal(rInv, "INV_08_03_Memo"));
                if (IsCheck(rInv, "INV_08_04")) sec.CheckItems.Add("B1 交通島及人行道裸露區域未設置第八條第一款至第五款防制設施。");
                if (IsCheck(rInv, "INV_08_05")) sec.CheckItems.Add("B2 未依同意後之替代方法執行。");
                if (IsCheck(rInv, "INV_08_06")) sec.CheckItems.Add("C1 路面有破損、髒污致路面色差。");
                if (IsCheck(rInv, "INV_08_07")) sec.CheckItems.Add("C2 交通島及人行道裸露區域設施面積或厚度不足。");
                if (IsCheck(rInv, "INV_08_08")) sec.CheckItems.Add("C3 交通島及人行道植生綠化或覆蓋厚度不足。");
                if (IsCheck(rInv, "INV_08_09")) sec.CheckItems.Add("C4 舖設粗級配或粒料粒徑厚度不足，或未灑水濕潤。");

                sec.AuditPhotos.Add(FindPic(facId, invNo, "公私場所管理之道路", "PIC", "管理道路現況", ""));
                sec.AuditPhotos.Add(FindPic(facId, invNo, "公私場所管理之道路_2", "PIC", "道路潔淨度檢視", ""));
            }

            sec.ReportPhotos.Add(FindReportPic(facId, repNo, "H1", "回報_公私場所管理之道路", "改善回報照片 1", rRep, "FileMemo_H1"));
            sec.ReportPhotos.Add(FindReportPic(facId, repNo, "H2", "回報_公私場所管理之道路1", "改善回報照片 2", rRep, "FileMemo_H2"));

            return sec;
        }

        private ItemSectionModel BuildSectionI(string facId, int invNo, int repNo, DataRow rInv, DataRow rRep)
        {
            ItemSectionModel sec = new ItemSectionModel();
            sec.Code = "09";
            sec.Title = "九、攝錄影監視系統";
            sec.LawRule = "固定污染源逸散性粒狀污染物空氣污染防制設施管理辦法 第11條";

            if (rInv != null)
            {
                sec.LossPoint = CalLossOne(rInv, "09");
                sec.HasLoss = (sec.LossPoint > 0);

                if (IsCheck(rInv, "INV_09_01")) sec.CheckItems.Add("無本項製程作業。");
                if (IsCheck(rInv, "INV_09_02")) sec.CheckItems.Add("A1 依規定設置或採行空氣污染防制設施。");
                if (IsCheck(rInv, "INV_09_03")) sec.CheckItems.Add("A2 依替代方法設置防制設施：" + GetVal(rInv, "INV_09_03_Memo"));
                if (IsCheck(rInv, "INV_09_04")) sec.CheckItems.Add("B1 須設置攝錄影監視系統而未設置。");
                if (IsCheck(rInv, "INV_09_05")) sec.CheckItems.Add("B2 系統故障未於7日內或核准期限內修復。");
                if (IsCheck(rInv, "INV_09_06")) sec.CheckItems.Add("B3 未依同意後之替代方法執行。");
                if (IsCheck(rInv, "INV_09_07")) sec.CheckItems.Add("C1 系統不符附表四規定或記錄影像資料未保存一個月。");
                if (IsCheck(rInv, "INV_09_08")) sec.CheckItems.Add("C2 監視系統故障未即時通報主管機關。");

                sec.AuditPhotos.Add(FindPic(facId, invNo, "攝錄影監視系統", "PIC", "監視主機/鏡頭現況", ""));
                sec.AuditPhotos.Add(FindPic(facId, invNo, "攝錄影監視系統_2", "PIC", "畫面錄影記錄", ""));
            }

            sec.ReportPhotos.Add(FindReportPic(facId, repNo, "I1", "回報_攝錄影監視系統", "改善回報照片 1", rRep, "FileMemo_I1"));
            sec.ReportPhotos.Add(FindReportPic(facId, repNo, "I2", "回報_攝錄影監視系統1", "改善回報照片 2", rRep, "FileMemo_I2"));

            return sec;
        }

        #endregion

        #region 輔助函式：照片檢索、法規計算與座標轉換

        private PhotoItemModel FindPic(string facId, int invNo, string findName, string dirName, string title, string memo)
        {
            PhotoItemModel p = new PhotoItemModel();
            p.Key = findName;
            p.Title = title;
            p.Memo = memo;

            if (invNo <= 0 || string.IsNullOrEmpty(facId))
            {
                p.Url = "../images/nophoto.jpg";
                p.Exists = false;
                return p;
            }

            string relativeDir = string.Format("~/Upload/{0}/{1}/{2}", dirName, facId, invNo);
            string folder = Server.MapPath(relativeDir);

            if (Directory.Exists(folder))
            {
                // 相容異體字或底線
                string altName = findName.Replace("堆罝", "堆置");
                FileInfo[] files = new DirectoryInfo(folder).GetFiles(findName + "*.*");
                if (files.Length == 0 && altName != findName)
                {
                    files = new DirectoryInfo(folder).GetFiles(altName + "*.*");
                }

                if (files.Length > 0)
                {
                    p.FileName = files[0].Name;
                    p.Url = string.Format("../Upload/{0}/{1}/{2}/{3}", dirName, facId, invNo, files[0].Name);
                    p.Exists = true;
                    return p;
                }
            }

            p.Url = "../images/nophoto.jpg";
            p.Exists = false;
            return p;
        }

        private PhotoItemModel FindReportPic(string facId, int repNo, string key, string findName, string title, DataRow rRep, string memoCol)
        {
            PhotoItemModel p = new PhotoItemModel();
            p.Key = key;
            p.Title = title;
            p.Memo = "";

            if (rRep != null && rRep.Table.Columns.Contains(memoCol) && rRep[memoCol] != DBNull.Value)
            {
                p.Memo = rRep[memoCol].ToString();
            }

            if (repNo <= 0 || string.IsNullOrEmpty(facId))
            {
                p.Url = "";
                p.Exists = false;
                return p;
            }

            string relativeDir = string.Format("~/Upload/ReportPIC/{0}/{1}", facId, repNo);
            string folder = Server.MapPath(relativeDir);

            if (Directory.Exists(folder))
            {
                string altName = findName.Replace("堆罝", "堆置");
                FileInfo[] files = new DirectoryInfo(folder).GetFiles(findName + "*.*");
                if (files.Length == 0 && altName != findName)
                {
                    files = new DirectoryInfo(folder).GetFiles(altName + "*.*");
                }

                if (files.Length > 0)
                {
                    p.FileName = files[0].Name;
                    p.Url = string.Format("../Upload/ReportPIC/{0}/{1}/{2}", facId, repNo, files[0].Name);
                    p.Exists = true;
                    return p;
                }
            }

            p.Url = "";
            p.Exists = false;
            return p;
        }

        private bool IsCheck(DataRow r, string colName)
        {
            if (r == null || !r.Table.Columns.Contains(colName)) return false;
            return r[colName] != DBNull.Value && r[colName].ToString() == "Y";
        }

        private string GetVal(DataRow r, string colName)
        {
            if (r == null || !r.Table.Columns.Contains(colName)) return "";
            return r[colName] != DBNull.Value ? r[colName].ToString() : "";
        }

        public static int CalLossOne(DataRow pRow, string itemName)
        {
            if (pRow == null) return 0;

            if (itemName == "01")
            {
                if (pRow["INV_01_01"].ToString() == "Y" || pRow["INV_01_02"].ToString() == "Y" || pRow["INV_01_03"].ToString() == "Y") return 0;
                if (pRow["INV_01_04"].ToString() == "Y" || pRow["INV_01_05"].ToString() == "Y") return 10;
                if (pRow["INV_01_08"].ToString() == "Y" || pRow["INV_01_09"].ToString() == "Y" || pRow["INV_01_09a"].ToString() == "Y" ||
                    pRow["INV_01_09b"].ToString() == "Y" || pRow["INV_01_09c"].ToString() == "Y" || pRow["INV_01_09d"].ToString() == "Y" ||
                    pRow["INV_01_10"].ToString() == "Y" || pRow["INV_01_10a"].ToString() == "Y" || pRow["INV_01_10b"].ToString() == "Y" ||
                    pRow["INV_01_11"].ToString() == "Y" || pRow["INV_01_11a"].ToString() == "Y" || pRow["INV_01_11b"].ToString() == "Y" ||
                    pRow["INV_01_11c"].ToString() == "Y" || pRow["INV_01_12"].ToString() == "Y" || pRow["INV_01_12a"].ToString() == "Y" ||
                    pRow["INV_01_12b"].ToString() == "Y" || pRow["INV_01_12c"].ToString() == "Y" || pRow["INV_01_13"].ToString() == "Y" ||
                    pRow["INV_01_14"].ToString() == "Y" || pRow["INV_01_07"].ToString() == "Y") return 4;
            }
            else if (itemName == "02")
            {
                if (pRow["INV_02_01"].ToString() == "Y" || pRow["INV_02_02"].ToString() == "Y" || pRow["INV_02_03"].ToString() == "Y" || pRow["INV_02_04"].ToString() == "Y") return 0;
                if (pRow["INV_02_05"].ToString() == "Y" || pRow["INV_02_06"].ToString() == "Y") return 10;
                if (pRow["INV_02_07"].ToString() == "Y" || pRow["INV_02_08"].ToString() == "Y" || pRow["INV_02_09"].ToString() == "Y" ||
                    pRow["INV_02_09a"].ToString() == "Y" || pRow["INV_02_09b"].ToString() == "Y" || pRow["INV_02_10"].ToString() == "Y" ||
                    pRow["INV_02_10a"].ToString() == "Y" || pRow["INV_02_10b"].ToString() == "Y" || pRow["INV_02_10c"].ToString() == "Y" ||
                    pRow["INV_02_11"].ToString() == "Y") return 4;
            }
            else if (itemName == "03")
            {
                if (pRow["INV_03_01"].ToString() == "Y" || pRow["INV_03_02"].ToString() == "Y" || pRow["INV_03_03"].ToString() == "Y") return 0;
                if (pRow["INV_03_04"].ToString() == "Y" || pRow["INV_03_05"].ToString() == "Y" || pRow["INV_03_06"].ToString() == "Y") return 10;
                if (pRow["INV_03_07"].ToString() == "Y" || pRow["INV_03_08"].ToString() == "Y" || pRow["INV_03_09"].ToString() == "Y") return 4;
            }
            else if (itemName == "04")
            {
                if (pRow["INV_04_01"].ToString() == "Y" || pRow["INV_04_02"].ToString() == "Y" || pRow["INV_04_03"].ToString() == "Y") return 0;
                if (pRow["INV_04_04"].ToString() == "Y" || pRow["INV_04_05"].ToString() == "Y") return 10;
                if (pRow["INV_04_06"].ToString() == "Y" || pRow["INV_04_07"].ToString() == "Y" || pRow["INV_04_08"].ToString() == "Y" || pRow["INV_04_09"].ToString() == "Y") return 4;
            }
            else if (itemName == "05")
            {
                if (pRow["INV_05_01"].ToString() == "Y" || pRow["INV_05_02"].ToString() == "Y" || pRow["INV_05_03"].ToString() == "Y") return 0;
                if (pRow["INV_05_04"].ToString() == "Y" || pRow["INV_05_05"].ToString() == "Y" || pRow["INV_05_06"].ToString() == "Y") return 10;
                if (pRow["INV_05_07"].ToString() == "Y" || pRow["INV_05_08"].ToString() == "Y" || pRow["INV_05_09"].ToString() == "Y" ||
                    pRow["INV_05_10"].ToString() == "Y" || pRow["INV_05_11"].ToString() == "Y") return 4;
            }
            else if (itemName == "06")
            {
                if (pRow["INV_06_01"].ToString() == "Y" || pRow["INV_06_02"].ToString() == "Y" || pRow["INV_06_03"].ToString() == "Y" || pRow["INV_06_04"].ToString() == "Y") return 0;
                if (pRow["INV_06_05"].ToString() == "Y" || pRow["INV_06_06"].ToString() == "Y") return 10;
                if (pRow["INV_06_07"].ToString() == "Y" || pRow["INV_06_07a"].ToString() == "Y" || pRow["INV_06_07b"].ToString() == "Y" ||
                    pRow["INV_06_08"].ToString() == "Y" || pRow["INV_06_08a"].ToString() == "Y" || pRow["INV_06_08b"].ToString() == "Y" ||
                    pRow["INV_06_09"].ToString() == "Y" || pRow["INV_06_10"].ToString() == "Y" || pRow["INV_06_11"].ToString() == "Y" ||
                    pRow["INV_06_12"].ToString() == "Y") return 4;
            }
            else if (itemName == "07")
            {
                if (pRow["INV_07_01"].ToString() == "Y" || pRow["INV_07_02"].ToString() == "Y" || pRow["INV_07_03"].ToString() == "Y") return 0;
                if (pRow["INV_07_04"].ToString() == "Y" || pRow["INV_07_05"].ToString() == "Y") return 10;
                if (pRow["INV_07_06"].ToString() == "Y" || pRow["INV_07_07"].ToString() == "Y" || pRow["INV_07_08"].ToString() == "Y" ||
                    pRow["INV_07_09"].ToString() == "Y" || pRow["INV_07_10"].ToString() == "Y" || pRow["INV_07_11"].ToString() == "Y") return 4;
            }
            else if (itemName == "08")
            {
                if (pRow["INV_08_01"].ToString() == "Y" || pRow["INV_08_02"].ToString() == "Y" || pRow["INV_08_03"].ToString() == "Y") return 0;
                if (pRow["INV_08_04"].ToString() == "Y" || pRow["INV_08_05"].ToString() == "Y") return 10;
                if (pRow["INV_08_06"].ToString() == "Y" || pRow["INV_08_07"].ToString() == "Y" || pRow["INV_08_08"].ToString() == "Y" ||
                    pRow["INV_08_09"].ToString() == "Y" || pRow["INV_08_10"].ToString() == "Y") return 4;
            }
            else if (itemName == "09")
            {
                if (pRow["INV_09_01"].ToString() == "Y" || pRow["INV_09_02"].ToString() == "Y" || pRow["INV_09_03"].ToString() == "Y") return 0;
                if (pRow["INV_09_04"].ToString() == "Y" || pRow["INV_09_05"].ToString() == "Y" || pRow["INV_09_06"].ToString() == "Y") return 10;
                if (pRow["INV_09_07"].ToString() == "Y" || pRow["INV_09_08"].ToString() == "Y") return 4;
            }

            return 0;
        }

        public static int CalculateTotalLoss(DataRow pRow)
        {
            if (pRow == null) return 0;
            int sum = 0;
            string[] items = new string[] { "01", "02", "03", "04", "05", "06", "07", "08", "09" };
            for (int i = 0; i < items.Length; i++)
            {
                sum += CalLossOne(pRow, items[i]);
            }
            return sum;
        }

        private bool ValidateSecurityToken(string facId, string token)
        {
            // 若為已登入使用者，容許直接檢視
            if (Session["LoginUser"] != null) return true;

            if (string.IsNullOrEmpty(token)) return false;

            // 支援今日各整點與前後1小時容錯
            DateTime now = DateTime.Now;
            string tok0 = ComputeMd5("MD5:" + facId + now.ToString("yyyyMMddHH"));
            string tokPrev = ComputeMd5("MD5:" + facId + now.AddHours(-1).ToString("yyyyMMddHH"));
            string tokNext = ComputeMd5("MD5:" + facId + now.AddHours(1).ToString("yyyyMMddHH"));

            if (string.Equals(token, tok0, StringComparison.OrdinalIgnoreCase)) return true;
            if (string.Equals(token, tokPrev, StringComparison.OrdinalIgnoreCase)) return true;
            if (string.Equals(token, tokNext, StringComparison.OrdinalIgnoreCase)) return true;

            return false;
        }

        private static string ComputeMd5(string input)
        {
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

        #endregion
    }
}
