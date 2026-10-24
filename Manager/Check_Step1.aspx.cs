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
    public partial class Check_Step1 : Page
    {
        private JavaScriptSerializer json;

        public Check_Step1()
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

        private void HandleAjaxAction(string action)
        {
            switch (action.ToLower())
            {
                case "get_data":
                    GetCaseData();
                    break;
                case "get_device_detail":
                    GetDeviceDetail();
                    break;
                case "submit_review":
                    SubmitReview();
                    break;
                default:
                    Response.Write(json.Serialize(new { Success = false, Message = "未知操作" }));
                    break;
            }
        }

        #region 1. 取得案件查核資料與審查歷史
        private void GetCaseData()
        {
            string facId = (Request["fac"] ?? "").Trim();
            string token = (Request["fac1"] ?? "").Trim();
            string mode = (Request["mode"] ?? "INV1").Trim().ToUpper();
            string invStr = (Request["inv"] ?? "").Trim();

            int invNo = 0;
            int.TryParse(invStr, out invNo);

            if (string.IsNullOrEmpty(facId) || invNo <= 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "缺少場所代碼或查核編號" }));
                return;
            }

            // 安全性驗證 (防篡改憑證校驗)
            bool isReadOnly = mode.StartsWith("READ");
            if (!isReadOnly)
            {
                string expectedToken = ComputeMD5(mode + facId + DateTime.Today.ToString("yyyyMMdd"));
                if (token != expectedToken && Session["LoginUser"] == null)
                {
                    Response.Write(json.Serialize(new { Success = false, Message = "參數檢核錯誤或操作憑證已逾期，請從審核清單重新進入。" }));
                    return;
                }
            }

            // 1. 查詢場所基本資料
            string sqlFac = "SELECT * FROM FAC_Main WHERE FAC_ID = @FAC_ID";
            DataTable dtFac = DbHelper.ExecuteDataTable(sqlFac, new SqlParameter("@FAC_ID", facId));
            if (dtFac == null || dtFac.Rows.Count == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "查無該場所基本資料 (FAC_ID: " + facId + ")" }));
                return;
            }

            DataRow fRow = dtFac.Rows[0];
            Dictionary<string, object> facInfo = new Dictionary<string, object>();
            facInfo["FAC_ID"] = fRow["FAC_ID"].ToString().Trim();
            facInfo["FAC_NAME"] = fRow.Table.Columns.Contains("FAC_NAME") ? fRow["FAC_NAME"].ToString() : "";
            facInfo["C_NO"] = fRow.Table.Columns.Contains("C_NO") ? fRow["C_NO"].ToString() : "";
            facInfo["S_C_ID"] = fRow.Table.Columns.Contains("S_C_ID") ? fRow["S_C_ID"].ToString() : "";
            facInfo["Lic_NO"] = fRow.Table.Columns.Contains("Lic_NO") ? fRow["Lic_NO"].ToString() : "";
            facInfo["BOSS_NAME"] = fRow.Table.Columns.Contains("BOSS_NAME") ? fRow["BOSS_NAME"].ToString() : "";
            facInfo["Content_Name"] = fRow.Table.Columns.Contains("Content_Name") ? fRow["Content_Name"].ToString() : "";
            facInfo["ADDR"] = fRow.Table.Columns.Contains("ADDR") ? fRow["ADDR"].ToString() : "";
            facInfo["TEL"] = fRow.Table.Columns.Contains("TEL") ? fRow["TEL"].ToString() : "";
            facInfo["FAX"] = fRow.Table.Columns.Contains("FAX") ? fRow["FAX"].ToString() : "";
            facInfo["Land_no"] = fRow.Table.Columns.Contains("Land_no") ? fRow["Land_no"].ToString() : "";

            // 行業別名稱查詢
            string indCode = fRow.Table.Columns.Contains("INDUSTRIAL_Code1") ? fRow["INDUSTRIAL_Code1"].ToString() : "";
            string indName = "";
            if (!string.IsNullOrEmpty(indCode))
            {
                string sqlInd = "SELECT INDUSTRIAL_Name FROM INDUSTRIAL_Data WHERE INDUSTRIAL_Code = @Code";
                DataTable dtInd = DbHelper.ExecuteDataTable(sqlInd, new SqlParameter("@Code", indCode));
                if (dtInd != null && dtInd.Rows.Count > 0)
                {
                    indName = dtInd.Rows[0]["INDUSTRIAL_Name"].ToString();
                }
            }
            facInfo["INDUSTRIAL_Name"] = indName;

            // 經緯度座標轉換 (TWD97 轉 WGS84)
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

            // 2. 查詢查核紀錄 INV_DATA
            string sqlInv = "SELECT * FROM INV_DATA WHERE FAC_ID = @FAC_ID AND INV_NO = @INV_NO";
            DataTable dtInv = DbHelper.ExecuteDataTable(sqlInv,
                new SqlParameter("@FAC_ID", facId),
                new SqlParameter("@INV_NO", invNo));

            if (dtInv == null || dtInv.Rows.Count == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "查無該筆查核記錄資料 (INV_NO: " + invNo.ToString() + ")" }));
                return;
            }

            DataRow invRow = dtInv.Rows[0];
            Dictionary<string, object> recordData = new Dictionary<string, object>();
            foreach (DataColumn col in dtInv.Columns)
            {
                if (invRow[col] != DBNull.Value)
                {
                    if (col.DataType == typeof(DateTime))
                    {
                        recordData[col.ColumnName] = Convert.ToDateTime(invRow[col]).ToString("yyyy-MM-dd HH:mm");
                    }
                    else
                    {
                        recordData[col.ColumnName] = invRow[col].ToString();
                    }
                }
                else
                {
                    recordData[col.ColumnName] = "";
                }
            }

            // 缺失點數計算與 9 大類設施詳細檢查分析
            int totalLossPoint = managerList.LossPointCalculator.CalTotalLossPoint(invRow);
            string allLossDetail = managerList.LossPointCalculator.GetAllLossDetail(invRow);
            List<Dictionary<string, object>> sections = BuildSectionDetails(invRow);

            recordData["TotalLossPoint"] = totalLossPoint;
            recordData["LossDetailSummary"] = allLossDetail;

            // 缺失等級評定
            string lossLevel = "QUALIFIED"; // 合格
            string lossWarning = "查核結果：無缺失情形，各項防制設施符合規範。";
            if (totalLossPoint >= 10)
            {
                lossLevel = "MAJOR";
                lossWarning = "查核結果：稽查當次之缺失點數合計 10 點(含)以上，依違反固定污染源逸散性粒狀污染物空氣污染防制設施管理辦法規定處分。";
            }
            else if (totalLossPoint > 0)
            {
                lossLevel = "MINOR";
                lossWarning = "查核結果：缺失點數合計未達 10 點，限期改善，屆期未改善或未完成改善者，依違反本辦法規定處分。";
            }
            recordData["LossLevel"] = lossLevel;
            recordData["LossWarning"] = lossWarning;

            // 改善期限解析
            string improveDeadline = "";
            if (invRow.Table.Columns.Contains("improve_Deadline") && invRow["improve_Deadline"] != DBNull.Value)
            {
                DateTime dtDead;
                if (DateTime.TryParse(invRow["improve_Deadline"].ToString(), out dtDead))
                {
                    improveDeadline = dtDead.ToString("yyyy-MM-dd");
                }
            }
            if (string.IsNullOrEmpty(improveDeadline))
            {
                improveDeadline = DateTime.Today.AddDays(14).ToString("yyyy-MM-dd");
            }
            recordData["ImproveDeadline"] = improveDeadline;

            // 3. 設備統計資料
            List<Dictionary<string, object>> devSummary = new List<Dictionary<string, object>>();
            try
            {
                string sqlDevSum = @"
                    SELECT [FAC_ID], substring([Device_NO],1,1) As pCode, [Device_Name], count(Device_NO) as pCount 
                    FROM (
                        Select Distinct FAC_ID, Device_NO, Device_Name From (
                            Select distinct FAC_ID, Device_NO, Device_Name From INV_Device where FAC_ID = @FAC_ID 
                            union 
                            Select distinct FAC_ID, Device_NO, Device_Name From INV_Device_Main where FAC_ID = @FAC_ID
                        ) as TABA
                    ) As TABB 
                    group by FAC_ID, substring([Device_NO],1,1), Device_Name";

                DataTable dtDevSum = DbHelper.ExecuteDataTable(sqlDevSum, new SqlParameter("@FAC_ID", facId));
                if (dtDevSum != null)
                {
                    foreach (DataRow dr in dtDevSum.Rows)
                    {
                        Dictionary<string, object> item = new Dictionary<string, object>();
                        item["pCode"] = dr["pCode"].ToString();
                        item["Device_Name"] = dr["Device_Name"].ToString();
                        item["pCount"] = Convert.ToInt32(dr["pCount"]);
                        devSummary.Add(item);
                    }
                }
            }
            catch (Exception exDev)
            {
                System.Diagnostics.Trace.WriteLine("查詢設備統計失敗: " + exDev.Message);
            }

            // 4. 現場採證照片清單與三方手寫簽名
            string appPath = HttpContext.Current.Request.ApplicationPath;
            if (appPath == "/") appPath = "";

            Dictionary<string, string> signatures = new Dictionary<string, string>();
            signatures["sig1"] = "";
            signatures["sig2"] = "";
            signatures["sig3"] = "";

            List<Dictionary<string, string>> photoGallery = new List<Dictionary<string, string>>();
            string picDirRel = "~/Upload/PIC/" + facId + "/" + invNo.ToString();
            string picDirPhy = HttpContext.Current.Server.MapPath(picDirRel);

            if (Directory.Exists(picDirPhy))
            {
                string[] files = Directory.GetFiles(picDirPhy);
                foreach (string f in files)
                {
                    string fname = Path.GetFileName(f);
                    string fbase = Path.GetFileNameWithoutExtension(f);
                    string fUrl = appPath + "/Upload/PIC/" + facId + "/" + invNo.ToString() + "/" + HttpUtility.UrlPathEncode(fname);

                    if (fbase.Equals("Sig1", StringComparison.OrdinalIgnoreCase))
                    {
                        signatures["sig1"] = fUrl;
                    }
                    else if (fbase.Equals("Sig2", StringComparison.OrdinalIgnoreCase))
                    {
                        signatures["sig2"] = fUrl;
                    }
                    else if (fbase.Equals("Sig3", StringComparison.OrdinalIgnoreCase))
                    {
                        signatures["sig3"] = fUrl;
                    }
                    else
                    {
                        // 佐證照片
                        Dictionary<string, string> photo = new Dictionary<string, string>();
                        photo["Name"] = fbase;
                        photo["Url"] = fUrl;
                        photo["Memo"] = GetPhotoMemo(fbase, invRow);
                        photoGallery.Add(photo);
                    }
                }
            }

            // 5. 查詢歷次審核紀錄 INV_Chk_Result
            List<Dictionary<string, object>> checkHistory = new List<Dictionary<string, object>>();
            try
            {
                string sqlHis = @"
                    SELECT r.*, u.Name as Chk_UserName, s.State_Name 
                    FROM INV_Chk_Result r 
                    LEFT JOIN UserAcc u ON r.Chk_User = u.UserID 
                    LEFT JOIN INV_State_List s ON r.INV_State = s.State_ID 
                    WHERE r.FAC_ID = @FAC_ID AND r.INV_NO = @INV_NO 
                    ORDER BY r.Chk_Date DESC";

                DataTable dtHis = DbHelper.ExecuteDataTable(sqlHis,
                    new SqlParameter("@FAC_ID", facId),
                    new SqlParameter("@INV_NO", invNo));

                if (dtHis != null)
                {
                    foreach (DataRow hr in dtHis.Rows)
                    {
                        Dictionary<string, object> h = new Dictionary<string, object>();
                        string userName = (hr.Table.Columns.Contains("Chk_UserName") && hr["Chk_UserName"] != DBNull.Value) ? hr["Chk_UserName"].ToString() : "";
                        if (string.IsNullOrEmpty(userName) && hr.Table.Columns.Contains("Chk_User") && hr["Chk_User"] != DBNull.Value)
                        {
                            userName = hr["Chk_User"].ToString();
                        }
                        h["Chk_UserName"] = userName;

                        string dateStr = "";
                        if (hr.Table.Columns.Contains("Chk_Date") && hr["Chk_Date"] != DBNull.Value)
                        {
                            DateTime dtChk;
                            if (DateTime.TryParse(hr["Chk_Date"].ToString(), out dtChk))
                            {
                                dateStr = dtChk.ToString("yyyy/MM/dd HH:mm");
                            }
                        }
                        h["Chk_Date"] = dateStr;

                        string stateName = (hr.Table.Columns.Contains("State_Name") && hr["State_Name"] != DBNull.Value) ? hr["State_Name"].ToString() : "";
                        if (string.IsNullOrEmpty(stateName) && hr.Table.Columns.Contains("INV_State") && hr["INV_State"] != DBNull.Value)
                        {
                            stateName = hr["INV_State"].ToString();
                        }
                        h["State_Name"] = stateName;

                        h["Chk_Result"] = (hr.Table.Columns.Contains("Chk_Result") && hr["Chk_Result"] != DBNull.Value) ? hr["Chk_Result"].ToString() : "";
                        h["Chk_Memo"] = (hr.Table.Columns.Contains("Chk_Memo") && hr["Chk_Memo"] != DBNull.Value) ? hr["Chk_Memo"].ToString() : "";
                        checkHistory.Add(h);
                    }
                }
            }
            catch (Exception exHis)
            {
                System.Diagnostics.Trace.WriteLine("查詢歷次審核紀錄失敗: " + exHis.Message);
            }

            // 6. 審核階段解析
            string stageTitle = "";
            string currentCaseState = invRow["INV_State"].ToString().Trim();
            switch (mode)
            {
                case "INV1":
                    stageTitle = "初審作業";
                    break;
                case "INV2":
                    stageTitle = "複審作業";
                    break;
                case "INV3":
                    stageTitle = "三審作業";
                    break;
                default:
                    stageTitle = "案件審查作業";
                    break;
            }

            // 判定是否可進行當前階段審核
            bool canReview = false;
            if (!isReadOnly)
            {
                if (mode == "INV1" && currentCaseState == "A00") canReview = true;
                if (mode == "INV2" && currentCaseState == "A01") canReview = true;
                if (mode == "INV3" && currentCaseState == "A02") canReview = true;
            }

            // 7. 回傳整合結果
            Response.Write(json.Serialize(new
            {
                Success = true,
                FacInfo = facInfo,
                RecordData = recordData,
                Sections = sections,
                DevSummary = devSummary,
                PhotoGallery = photoGallery,
                Signatures = signatures,
                CheckHistory = checkHistory,
                CurrentStageTitle = stageTitle,
                CurrentCaseState = currentCaseState,
                CanReview = canReview,
                IsReadOnly = isReadOnly,
                Mode = mode,
                LoginUser = GetCurrentUser(),
                TodayDate = DateTime.Today.ToString("yyyy-MM-dd")
            }));
        }

        private string GetPhotoMemo(string photoName, DataRow row)
        {
            if (row == null) return "";
            string col = "";
            switch (photoName)
            {
                case "全景照片": col = "FileMemo_AllView"; break;
                case "工廠正門口": col = "FileMemo_Entrance"; break;
                case "輔導簽認單_1": col = "FileMemo_Counseling1"; break;
                case "輔導簽認單_2": col = "FileMemo_Counseling2"; break;
                case "局部集氣效率評估_1": col = "FileMemo_CollGasEfficiency1"; break;
                case "局部集氣效率評估_2": col = "FileMemo_CollGasEfficiency2"; break;
                case "局部集氣效率評估_3": col = "FileMemo_CollGasEfficiency3"; break;
                case "局部集氣效率評估_4": col = "FileMemo_CollGasEfficiency4"; break;
                case "空品感測數據_1": col = "FileMemo_AirQualityValue1"; break;
                case "空品感測數據_2": col = "FileMemo_AirQualityValue2"; break;
                case "File_1": col = "FileMemo_1"; break;
                case "File_1a": col = "FileMemo_1a"; break;
                case "File_1b": col = "FileMemo_1b"; break;
                case "File_2": col = "FileMemo_2"; break;
                case "File_3": col = "FileMemo_3"; break;
                case "File_4": col = "FileMemo_4"; break;
                case "File_5": col = "FileMemo_5"; break;
                case "File_6": col = "FileMemo_6"; break;
                case "File_7": col = "FileMemo_7"; break;
                case "File_8": col = "FileMemo_8"; break;
                case "File_9": col = "FileMemo_9"; break;
            }

            if (!string.IsNullOrEmpty(col) && row.Table.Columns.Contains(col) && row[col] != DBNull.Value)
            {
                return row[col].ToString();
            }
            return "";
        }
        #endregion

        #region 2. 構建九大項防制設施檢查細節
        private List<Dictionary<string, object>> BuildSectionDetails(DataRow r)
        {
            List<Dictionary<string, object>> list = new List<Dictionary<string, object>>();

            // 1. 堆置
            list.Add(CreateSection(1, "一、堆置逸散性粒狀污染物質", r,
                new string[] { "INV_01_01", "INV_01_02", "INV_01_03" },
                new string[] { "INV_01_04", "INV_01_05" },
                new string[] { "INV_01_07", "INV_01_08", "INV_01_09", "INV_01_09a", "INV_01_09b", "INV_01_09c", "INV_01_09d", "INV_01_10", "INV_01_10a", "INV_01_10b", "INV_01_11", "INV_01_11a", "INV_01_11b", "INV_01_11c", "INV_01_12", "INV_01_12a", "INV_01_12b", "INV_01_12c", "INV_01_13", "INV_01_14" },
                new string[] { "File_1", "File_1a", "File_1b", "File_1c", "File_1d" },
                new string[] { "FileMemo_1", "FileMemo_1a", "FileMemo_1b", "FileMemo_1c", "FileMemo_1d" },
                new string[] { "堆置逸散照片 1", "堆置逸散照片 2", "自動灑水水表", "上月紀錄表", "本月紀錄表" }
            ));

            // 2. 輸送
            list.Add(CreateSection(2, "二、輸送逸散性粒狀污染物質", r,
                new string[] { "INV_02_01", "INV_02_02", "INV_02_03", "INV_02_04" },
                new string[] { "INV_02_05", "INV_02_06" },
                new string[] { "INV_02_07", "INV_02_08", "INV_02_09", "INV_02_09a", "INV_02_09b", "INV_02_10", "INV_02_10a", "INV_02_10b", "INV_02_10c", "INV_02_11" },
                new string[] { "File_2", "File_2a" },
                new string[] { "FileMemo_2", "FileMemo_2a" },
                new string[] { "輸送作業照片 1", "輸送作業照片 2" }
            ));

            // 3. 運輸車輛
            list.Add(CreateSection(3, "三、運輸逸散性粒狀污染物質車輛", r,
                new string[] { "INV_03_01", "INV_03_02", "INV_03_03" },
                new string[] { "INV_03_04", "INV_03_05", "INV_03_06" },
                new string[] { "INV_03_07", "INV_03_08", "INV_03_09" },
                new string[] { "File_3", "File_3a" },
                new string[] { "FileMemo_3", "FileMemo_3a" },
                new string[] { "運輸車輛照片 1", "運輸車輛照片 2" }
            ));

            // 4. 車輛通行路徑
            list.Add(CreateSection(4, "四、公私場所內車輛通行路徑及區域", r,
                new string[] { "INV_04_01", "INV_04_02", "INV_04_03" },
                new string[] { "INV_04_04", "INV_04_05" },
                new string[] { "INV_04_06", "INV_04_07", "INV_04_08", "INV_04_09" },
                new string[] { "File_4", "File_4a" },
                new string[] { "FileMemo_4", "FileMemo_4a" },
                new string[] { "通行路徑照片 1", "通行路徑照片 2" }
            ));

            // 5. 車輛清洗
            list.Add(CreateSection(5, "五、運輸車輛出入口清洗設施", r,
                new string[] { "INV_05_01", "INV_05_02", "INV_05_03" },
                new string[] { "INV_05_04", "INV_05_05", "INV_05_06" },
                new string[] { "INV_05_07", "INV_05_08", "INV_05_09", "INV_05_10", "INV_05_11" },
                new string[] { "File_5", "File_5a", "File_5b", "File_5c", "File_5d", "File_5e", "File_5f", "File_5g", "File_5h", "File_5i" },
                new string[] { "FileMemo_5", "FileMemo_5a", "FileMemo_5b", "FileMemo_5c", "FileMemo_5d", "FileMemo_5e", "FileMemo_5f", "FileMemo_5g", "FileMemo_5h", "FileMemo_5i" },
                new string[] { "洗車台照片 1", "洗車台照片 2", "水槽水深量測", "有效水深", "沖洗長度", "告示牌", "馬達規格", "加壓沖洗", "上月紀錄表", "本月紀錄表" }
            ));

            // 6. 製程裝卸
            list.Add(CreateSection(6, "六、易致粒狀污染物逸散之製程、操作或裝卸作業", r,
                new string[] { "INV_06_01", "INV_06_02", "INV_06_03", "INV_06_04" },
                new string[] { "INV_06_05", "INV_06_06" },
                new string[] { "INV_06_07", "INV_06_07a", "INV_06_07b", "INV_06_08", "INV_06_08a", "INV_06_08b", "INV_06_09", "INV_06_10", "INV_06_11", "INV_06_12" },
                new string[] { "File_6", "File_6a", "File_6b", "File_6c", "File_6d" },
                new string[] { "FileMemo_6", "FileMemo_6a", "FileMemo_6b", "FileMemo_6c", "FileMemo_6d" },
                new string[] { "製程裝卸照片 1", "製程裝卸照片 2", "監測儀表", "上月紀錄表", "本月紀錄表" }
            ));

            // 7. 裸露區域
            list.Add(CreateSection(7, "七、公私場所管理之裸露區域", r,
                new string[] { "INV_07_01", "INV_07_02", "INV_07_03" },
                new string[] { "INV_07_04", "INV_07_05" },
                new string[] { "INV_07_06", "INV_07_07", "INV_07_08", "INV_07_09", "INV_07_10", "INV_07_11" },
                new string[] { "File_7", "File_7a" },
                new string[] { "FileMemo_7", "FileMemo_7a" },
                new string[] { "裸露區域照片 1", "裸露區域照片 2" }
            ));

            // 8. 管理道路
            list.Add(CreateSection(8, "八、公私場所管理之周邊道路", r,
                new string[] { "INV_08_01", "INV_08_02", "INV_08_03" },
                new string[] { "INV_08_04", "INV_08_05" },
                new string[] { "INV_08_06", "INV_08_07", "INV_08_08", "INV_08_09", "INV_08_10" },
                new string[] { "File_8", "File_8a" },
                new string[] { "FileMemo_8", "FileMemo_8a" },
                new string[] { "管理道路照片 1", "管理道路照片 2" }
            ));

            // 9. 監視系統
            list.Add(CreateSection(9, "九、攝錄影監視系統", r,
                new string[] { "INV_09_01", "INV_09_02", "INV_09_03" },
                new string[] { "INV_09_04", "INV_09_05", "INV_09_06" },
                new string[] { "INV_09_07", "INV_09_08" },
                new string[] { "File_9", "File_9a" },
                new string[] { "FileMemo_9", "FileMemo_9a" },
                new string[] { "監視系統照片 1", "監視系統照片 2" }
            ));

            return list;
        }

        private Dictionary<string, object> CreateSection(int id, string title, DataRow r,
            string[] keys0, string[] keys10, string[] keys4,
            string[] photoKeys, string[] memoKeys, string[] photoLabels)
        {
            Dictionary<string, object> sec = new Dictionary<string, object>();
            sec["Id"] = id;
            sec["Title"] = title;

            int loss = 0;
            List<string> violations = new List<string>();
            List<string> compliantItems = new List<string>();

            // 檢查 10 點違規
            foreach (string k in keys10)
            {
                if (r.Table.Columns.Contains(k) && (r[k].ToString() == "Y" || r[k].ToString() == "V"))
                {
                    loss = 10;
                    violations.Add(GetCheckItemTitle(k));
                }
            }

            // 檢查 4 點違規 (若尚未達 10 點)
            foreach (string k in keys4)
            {
                if (r.Table.Columns.Contains(k) && (r[k].ToString() == "Y" || r[k].ToString() == "V"))
                {
                    if (loss < 4) loss = 4;
                    violations.Add(GetCheckItemTitle(k));
                }
            }

            // 檢查合格項
            foreach (string k in keys0)
            {
                if (r.Table.Columns.Contains(k) && (r[k].ToString() == "Y" || r[k].ToString() == "V"))
                {
                    compliantItems.Add(GetCheckItemTitle(k));
                }
            }

            sec["LossPoint"] = loss;
            sec["Violations"] = violations;
            sec["CompliantItems"] = compliantItems;

            return sec;
        }

        private string GetCheckItemTitle(string colName)
        {
            Dictionary<string, string> dict = new Dictionary<string, string>();
            dict["INV_01_01"] = "全阻隔設施符合規定";
            dict["INV_01_02"] = "採非阻隔設施(防塵網覆蓋/灑水)符合規定";
            dict["INV_01_03"] = "經主管機關同意之替代防制設施";
            dict["INV_01_04"] = "未採行第四條規定防制設施之一(記10點)";
            dict["INV_01_05"] = "未依直轄市縣市主管機關核定之替代方法執行(記10點)";
            dict["INV_01_07"] = "堆置高度超過阻隔設施高度(記4點)";
            dict["INV_01_08"] = "採封閉建築物但建築物未符合第二條第二款規定(記4點)";
            dict["INV_01_09"] = "阻隔牆或防塵網圍封規格或高度不足(記4點)";
            dict["INV_01_09a"] = "防塵網或阻隔牆高度未達堆置高度1.25倍";
            dict["INV_01_09b"] = "防塵網或阻隔牆未完全圍封堆置區";
            dict["INV_01_09c"] = "防塵網或阻隔牆破損部分達圍封面積10%以上";
            dict["INV_01_09d"] = "總設計堆置達三千立方公尺未採行規定設施之一";
            dict["INV_01_10"] = "覆蓋防塵布或防塵網覆蓋率不足80%(記4點)";
            dict["INV_01_11"] = "自動灑水設施噴水涵蓋率不足或未定期維護(記4點)";
            dict["INV_01_12"] = "噴灑化學穩定劑未依核定規格操作(記4點)";
            dict["INV_01_13"] = "其他替代防制措施未落實維持濕潤(記4點)";
            dict["INV_01_14"] = "堆置表面乾燥未定期灑水維持濕潤(記4點)";

            dict["INV_02_01"] = "全密閉式輸送作業符合規定";
            dict["INV_02_02"] = "局部密閉並設集氣系統且運作正常";
            dict["INV_02_03"] = "採灑水或化學穩定劑防制符合規定";
            dict["INV_02_04"] = "替代輸送防制措施符合規定";
            dict["INV_02_05"] = "輸送設施未採行任何防制措施(記10點)";
            dict["INV_02_06"] = "未依核定之替代輸送方法執行(記10點)";
            dict["INV_02_07"] = "輸送封閉式設施破損逸散(記4點)";
            dict["INV_02_08"] = "集氣設施或排氣處理設備故障或無效操作(記4點)";
            dict["INV_02_09"] = "落料點未設置集氣或自動灑水設施(記4點)";
            dict["INV_02_10"] = "皮帶輸送機未設清掃器致回帶掉料(記4點)";
            dict["INV_02_11"] = "輸送作業周邊地面散落物料未及時清除(記4點)";

            dict["INV_03_01"] = "進出車輛均採用密閉式車斗貨箱";
            dict["INV_03_02"] = "採防塵布緊密覆蓋符合規定";
            dict["INV_03_03"] = "替代運輸措施符合規定";
            dict["INV_03_04"] = "車輛載運逸散性物質未設覆蓋(記10點)";
            dict["INV_03_05"] = "未依核定之替代運輸方法執行(記10點)";
            dict["INV_03_06"] = "車體外附著粉塵物料未清洗即行駛出場(記10點)";
            dict["INV_03_07"] = "防塵布覆蓋邊緣未牢固捆紮或破損逸散(記4點)";
            dict["INV_03_08"] = "裝載物料超過車斗邊緣防護高度(記4點)";
            dict["INV_03_09"] = "密閉車斗門封密封不良產生滲漏(記4點)";

            dict["INV_04_01"] = "車輛通行路徑全鋪設鋼板或混凝土/瀝青";
            dict["INV_04_02"] = "洗掃作業保持潔淨無路面塵土飛揚";
            dict["INV_04_03"] = "替代路面防制措施符合規定";
            dict["INV_04_04"] = "行車路徑未鋪設路面導致大量揚塵(記10點)";
            dict["INV_04_05"] = "未依核定之行車路徑替代防制方法執行(記10點)";
            dict["INV_04_06"] = "路面破損坑洞或積泥未及時清除(記4點)";
            dict["INV_04_07"] = "洗掃頻率不足致路面大量揚塵(記4點)";
            dict["INV_04_08"] = "未鋪設路面區域未定期灑水(記4點)";
            dict["INV_04_09"] = "通行路徑邊界積土溢散未處理(記4點)";

            dict["INV_05_01"] = "設置自動加壓沖洗設備且運作正常";
            dict["INV_05_02"] = "設置符合規格洗車台且有效清洗";
            dict["INV_05_03"] = "替代洗車措施符合規定";
            dict["INV_05_04"] = "未設置洗車台或加壓沖洗設備(記10點)";
            dict["INV_05_05"] = "洗車設備故障停用未洗車(記10點)";
            dict["INV_05_06"] = "未依核定之替代洗車措施執行(記10點)";
            dict["INV_05_07"] = "洗車台沉砂池積泥未清導致排水阻塞(記4點)";
            dict["INV_05_08"] = "沖洗水壓不足或噴頭堵塞嚴重(記4點)";
            dict["INV_05_09"] = "洗車台沖洗長度不足規定規格(記4點)";
            dict["INV_05_10"] = "洗車台周邊無導水溝致汙水漫流(記4點)";
            dict["INV_05_11"] = "洗車廢水未經處理逕行外流(記4點)";

            dict["INV_06_01"] = "製程於密閉建築物內操作符合規定";
            dict["INV_06_02"] = "裝卸作業設置防溢散設施符合規範";
            dict["INV_06_03"] = "集氣設施收集效率良好";
            dict["INV_06_04"] = "替代製程操作防制符合規定";
            dict["INV_06_05"] = "製程或裝卸作業無任何防制措施致逸散(記10點)";
            dict["INV_06_06"] = "未依核定之替代操作方法執行(記10點)";
            dict["INV_06_07"] = "密閉室出入口未保持關閉致粉塵外洩(記4點)";
            dict["INV_06_08"] = "局部集氣設備排風量不足或風管破損(記4點)";
            dict["INV_06_09"] = "裝卸料點落差過大且未設防塵罩(記4點)";
            dict["INV_06_10"] = "操作區地面粉塵堆積未及時清除(記4點)";
            dict["INV_06_11"] = "未定期檢核集氣設備操作壓降紀錄(記4點)";
            dict["INV_06_12"] = "裝卸作業產生明顯黑煙或高濃度粒狀物(記4點)";

            dict["INV_07_01"] = "裸露地全採植生綠化或硬質鋪面覆蓋";
            dict["INV_07_02"] = "覆蓋防塵網或灑水濕潤符合規定";
            dict["INV_07_03"] = "替代裸露地防制措施符合規定";
            dict["INV_07_04"] = "裸露空地未採任何覆蓋或防塵措施(記10點)";
            dict["INV_07_05"] = "未依核定之替代裸露空地措施執行(記10點)";
            dict["INV_07_06"] = "綠化或覆蓋不完全有明顯塵土(記4點)";
            dict["INV_07_07"] = "防塵網破損達面積10%以上未修補(記4點)";
            dict["INV_07_08"] = "灑水頻率不足導致地表乾燥揚塵(記4點)";
            dict["INV_07_09"] = "表土鬆散未夯實且無壓制措施(記4點)";
            dict["INV_07_10"] = "裸露地邊界未設阻隔設施致泥沙流失(記4點)";
            dict["INV_07_11"] = "化學穩定劑噴灑濃度不足(記4點)";

            dict["INV_08_01"] = "管理道路全鋪設鋼筋混凝土或瀝青並洗掃";
            dict["INV_08_02"] = "洗掃頻率符合規範無塵土飛揚";
            dict["INV_08_03"] = "替代道路防制措施符合規定";
            dict["INV_08_04"] = "管理道路未鋪設致車輛通行揚塵(記10點)";
            dict["INV_08_05"] = "未依核定之替代管理道路措施執行(記10點)";
            dict["INV_08_06"] = "道路路面有明顯泥沙堆積未清(記4點)";
            dict["INV_08_07"] = "未定期洗掃道路致路面乾燥揚塵(記4點)";
            dict["INV_08_08"] = "路面坑洞破損未及時修補(記4點)";
            dict["INV_08_09"] = "周邊排水溝泥沙淤積溢滿(記4點)";
            dict["INV_08_10"] = "洗街車洗掃水量不足(記4點)";

            dict["INV_09_01"] = "全廠監視系統運作正常且連線存檔符合規定";
            dict["INV_09_02"] = "鏡頭角度涵蓋關鍵出入口與洗車台";
            dict["INV_09_03"] = "替代監視措施符合規定";
            dict["INV_09_04"] = "未設置攝錄影監視系統(記10點)";
            dict["INV_09_05"] = "監視系統故障停擺無錄影紀錄(記10點)";
            dict["INV_09_06"] = "未依核定之替代監視措施執行(記10點)";
            dict["INV_09_07"] = "鏡頭角度未涵蓋關鍵出入口或洗車台(記4點)";
            dict["INV_09_08"] = "錄影影像解析度不足或保存天數不足30日(記4點)";

            if (dict.ContainsKey(colName))
            {
                return dict[colName];
            }
            return "檢查項目 (" + colName + ")";
        }
        #endregion

        #region 3. 取得設備與製程詳細資料
        private void GetDeviceDetail()
        {
            string facId = (Request["facId"] ?? "").Trim();
            string pCode = (Request["pCode"] ?? "").Trim();
            string devName = (Request["devName"] ?? "").Trim();

            if (string.IsNullOrEmpty(facId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "缺少場所代碼" }));
                return;
            }

            // 設備清單
            string sqlDev = "SELECT * FROM INV_Device WHERE FAC_ID = @FAC_ID";
            List<SqlParameter> pList = new List<SqlParameter>();
            pList.Add(new SqlParameter("@FAC_ID", facId));

            if (!string.IsNullOrEmpty(pCode))
            {
                sqlDev += " AND substring(Device_NO, 1, 1) = @pCode";
                pList.Add(new SqlParameter("@pCode", pCode));
            }
            if (!string.IsNullOrEmpty(devName))
            {
                sqlDev += " AND Device_Name = @devName";
                pList.Add(new SqlParameter("@devName", devName));
            }

            DataTable dtDev = DbHelper.ExecuteDataTable(sqlDev, pList.ToArray());
            List<Dictionary<string, object>> devList = new List<Dictionary<string, object>>();
            if (dtDev != null)
            {
                foreach (DataRow dr in dtDev.Rows)
                {
                    Dictionary<string, object> d = new Dictionary<string, object>();
                    d["Device_NO"] = dr.Table.Columns.Contains("Device_NO") ? dr["Device_NO"].ToString() : "";
                    d["Device_Code"] = dr.Table.Columns.Contains("Device_Code") ? dr["Device_Code"].ToString() : "";
                    d["Device_Name"] = dr.Table.Columns.Contains("Device_Name") ? dr["Device_Name"].ToString() : "";
                    d["Store_substance"] = dr.Table.Columns.Contains("Store_substance") ? dr["Store_substance"].ToString() : "";
                    devList.Add(d);
                }
            }

            // 製程清單
            string sqlProc = "SELECT * FROM INV_Process_Main WHERE FAC_ID = @FAC_ID";
            DataTable dtProc = DbHelper.ExecuteDataTable(sqlProc, new SqlParameter("@FAC_ID", facId));
            List<Dictionary<string, object>> procList = new List<Dictionary<string, object>>();
            if (dtProc != null)
            {
                foreach (DataRow pr in dtProc.Rows)
                {
                    Dictionary<string, object> p = new Dictionary<string, object>();
                    p["Process_NO"] = pr.Table.Columns.Contains("Process_NO") ? pr["Process_NO"].ToString() : "";
                    p["Process_Name"] = pr.Table.Columns.Contains("Process_Name") ? pr["Process_Name"].ToString() : "";
                    procList.Add(p);
                }
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                Devices = devList,
                Processes = procList
            }));
        }
        #endregion

        #region 4. 提交案件審查作業
        private void SubmitReview()
        {
            string facId = (Request["fac"] ?? "").Trim();
            string mode = (Request["mode"] ?? "").Trim().ToUpper();
            string invStr = (Request["inv"] ?? "").Trim();
            string result = (Request["chkResult"] ?? "").Trim().ToUpper(); // PASS or FAIL
            string memo = (Request["chkMemo"] ?? "").Trim();

            int invNo = 0;
            int.TryParse(invStr, out invNo);

            if (string.IsNullOrEmpty(facId) || invNo <= 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "缺少場所代碼或查核編號" }));
                return;
            }

            if (result != "PASS" && result != "FAIL")
            {
                Response.Write(json.Serialize(new { Success = false, Message = "請選取正確的審核結果（通過或退件）" }));
                return;
            }

            string stateId = "";
            switch (mode)
            {
                case "INV1":
                    stateId = "A00";
                    break;
                case "INV2":
                    stateId = "A01";
                    break;
                case "INV3":
                    stateId = "A02";
                    break;
                default:
                    Response.Write(json.Serialize(new { Success = false, Message = "無效的審核階段模式" }));
                    return;
            }

            string currentUser = GetCurrentUser();
            string resultText = (result == "PASS") ? "通過" : "退件";

            try
            {
                // 1. 寫入歷次審核紀錄 INV_Chk_Result
                string sqlInsertReview = @"
                    INSERT INTO INV_Chk_Result (FAC_ID, INV_NO, Chk_Date, Chk_Result, Chk_Memo, INV_State, Chk_User)
                    VALUES (@FAC_ID, @INV_NO, GETDATE(), @Chk_Result, @Chk_Memo, @INV_State, @Chk_User)";

                DbHelper.ExecuteNonQuery(sqlInsertReview,
                    new SqlParameter("@FAC_ID", facId),
                    new SqlParameter("@INV_NO", invNo),
                    new SqlParameter("@Chk_Result", resultText),
                    new SqlParameter("@Chk_Memo", memo),
                    new SqlParameter("@INV_State", stateId),
                    new SqlParameter("@Chk_User", currentUser));

                // 2. 查詢該階段之 Next_State 與 Back_State
                string sqlState = "SELECT * FROM INV_State_List WHERE State_ID = @State_ID";
                DataTable dtState = DbHelper.ExecuteDataTable(sqlState, new SqlParameter("@State_ID", stateId));

                string nextState = "";
                string backState = "";
                if (dtState != null && dtState.Rows.Count > 0)
                {
                    nextState = dtState.Rows[0]["Next_State"].ToString();
                    backState = dtState.Rows[0]["Back_State"].ToString();
                }

                string targetState = (result == "PASS") ? nextState : backState;

                // 3. 更新 INV_DATA 狀態
                string sqlUpdateInv = "UPDATE INV_DATA SET INV_State = @TargetState WHERE FAC_ID = @FAC_ID AND INV_NO = @INV_NO";
                DbHelper.ExecuteNonQuery(sqlUpdateInv,
                    new SqlParameter("@TargetState", targetState),
                    new SqlParameter("@FAC_ID", facId),
                    new SqlParameter("@INV_NO", invNo));

                // 4. 複審通過 (targetState == "A01") 時與 INV_Mission 任務派遣連動
                if (targetState == "A01")
                {
                    UpdateMissionAfterDoubleReview(facId, invNo);
                }

                Response.Write(json.Serialize(new
                {
                    Success = true,
                    Message = string.Format("【{0}】審查作業完成，結果：{1}！", stateId, resultText),
                    RedirectUrl = "managerList.aspx?INV_State=" + mode
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

        private void UpdateMissionAfterDoubleReview(string facId, int invNo)
        {
            try
            {
                string sqlInv = "SELECT * FROM INV_DATA WHERE FAC_ID = @FAC_ID AND INV_NO = @INV_NO";
                DataTable dtInv = DbHelper.ExecuteDataTable(sqlInv,
                    new SqlParameter("@FAC_ID", facId),
                    new SqlParameter("@INV_NO", invNo));

                string sqlMission = "SELECT * FROM INV_Mission WHERE FAC_ID = @FAC_ID";
                DataTable dtMission = DbHelper.ExecuteDataTable(sqlMission, new SqlParameter("@FAC_ID", facId));

                if (dtInv != null && dtInv.Rows.Count > 0 && dtMission != null && dtMission.Rows.Count > 0)
                {
                    int lossPoint = managerList.LossPointCalculator.CalTotalLossPoint(dtInv.Rows[0]);
                    string curReason = dtMission.Rows[0]["pReason"].ToString();

                    int finishInvNo = 0;
                    if (dtMission.Rows[0]["Finish_INV_NO"] != DBNull.Value)
                    {
                        int.TryParse(dtMission.Rows[0]["Finish_INV_NO"].ToString(), out finishInvNo);
                    }

                    string nextReason = "";
                    switch (curReason)
                    {
                        case "7天內未完成改善回報":
                            if (lossPoint >= 10)
                            {
                                nextReason = (finishInvNo >= invNo) ? "7天內未完成改善回報" : "稽查列管";
                            }
                            else
                            {
                                nextReason = "結案";
                            }
                            break;
                        case "稽查列管":
                            if (lossPoint >= 10)
                            {
                                nextReason = (finishInvNo >= invNo) ? "稽查列管" : "稽查列管注意案件";
                            }
                            else
                            {
                                nextReason = "結案";
                            }
                            break;
                        case "稽查列管注意案件":
                            nextReason = (lossPoint >= 10) ? "稽查列管注意案件" : "結案";
                            break;
                        default:
                            if (lossPoint < 10) nextReason = "結案";
                            break;
                    }

                    if (nextReason == "結案")
                    {
                        string sqlDel = "DELETE FROM INV_Mission WHERE FAC_ID = @FAC_ID";
                        DbHelper.ExecuteNonQuery(sqlDel, new SqlParameter("@FAC_ID", facId));
                    }
                    else if (!string.IsNullOrEmpty(nextReason))
                    {
                        string sqlUpd = "UPDATE INV_Mission SET pReason = @pReason, SendDate = GETDATE(), Finish_INV_NO = @Finish_INV_NO WHERE FAC_ID = @FAC_ID";
                        DbHelper.ExecuteNonQuery(sqlUpd,
                            new SqlParameter("@pReason", nextReason),
                            new SqlParameter("@Finish_INV_NO", invNo),
                            new SqlParameter("@FAC_ID", facId));
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Trace.WriteLine("UpdateMissionAfterDoubleReview 錯誤: " + ex.Message);
            }
        }
        #endregion

        #region 5. 輔助工具方法 (MD5 與 座標轉換)
        private string ComputeMD5(string input)
        {
            if (string.IsNullOrEmpty(input)) return "";
            using (MD5 md5 = MD5.Create())
            {
                byte[] bytes = Encoding.UTF8.GetBytes(input);
                byte[] hash = md5.ComputeHash(bytes);
                StringBuilder sb = new StringBuilder();
                for (int i = 0; i < hash.Length; i++)
                {
                    sb.Append(hash[i].ToString("x2"));
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
