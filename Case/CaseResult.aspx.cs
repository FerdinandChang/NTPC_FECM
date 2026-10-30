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
using NTPC_FEC.Services;

namespace NTPC_FEC.Case
{
    public partial class CaseResult : Page
    {
        private JavaScriptSerializer json = new JavaScriptSerializer { MaxJsonLength = int.MaxValue };

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
                    Response.Write(json.Serialize(new { Success = false, Message = ex.Message }));
                }
                AjaxResponseHelper.CompleteRequest(Response, Context);
                return;
            }
        }

        private void HandleAjaxAction(string action)
        {
            string act = action.ToLower();
            if (act == "init")
            {
                InitPageData();
            }
            else if (act == "getdevices")
            {
                GetDeviceDetail();
            }
            else if (act == "save")
            {
                SaveCaseResult();
            }
            else
            {
                Response.Write(json.Serialize(new { Success = false, Message = "未知的操作指令" }));
            }
        }

        #region 1. 頁面初始化資料取得
        private void InitPageData()
        {
            string facId = Request["id"];
            string token = Request["id1"];
            string invNoStr = Request["id2"];
            string mode = Request["mode"];
            string back = Request["back"];

            if (string.IsNullOrEmpty(facId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "缺少場所管制編號參數 (id)" }));
                return;
            }

            int invNo = 0;
            int.TryParse(invNoStr, out invNo);
            if (invNo <= 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "缺少有效之查核編號參數 (id2)" }));
                return;
            }

            if (string.IsNullOrEmpty(mode))
            {
                mode = "edit";
            }

            // 安全 Token 檢查 (若有帶 token 則比對前後1小時，若 Session 已登入則寬容通過)
            if (!string.IsNullOrEmpty(token))
            {
                bool tokenValid = SecurityTokenHelper.ValidateHourToken(token, facId);
                if (!tokenValid && Session["LoginUser"] == null)
                {
                    Response.Write(json.Serialize(new { Success = false, Message = "安全憑證已過期或無效，請由案件清單重新進入。" }));
                    return;
                }
            }

            // 1. 查詢場所基本資料
            string sqlFac = "SELECT * FROM FAC_Main WHERE FAC_ID = @FAC_ID";
            DataTable dtFac = DbHelper.ExecuteDataTable(sqlFac, new SqlParameter("@FAC_ID", facId));
            if (dtFac == null || dtFac.Rows.Count == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "查無指定之公私場所資料 (FAC_ID: " + facId + ")" }));
                return;
            }

            DataRow fRow = dtFac.Rows[0];
            Dictionary<string, object> facInfo = new Dictionary<string, object>();
            facInfo["FAC_ID"] = fRow["FAC_ID"].ToString().Trim();
            facInfo["FAC_NAME"] = fRow.Table.Columns.Contains("FAC_NAME") ? fRow["FAC_NAME"].ToString() : "";
            facInfo["C_NO"] = fRow.Table.Columns.Contains("C_NO") ? fRow["C_NO"].ToString() : "";
            facInfo["BOSS_NAME"] = fRow.Table.Columns.Contains("BOSS_NAME") ? fRow["BOSS_NAME"].ToString() : "";
            facInfo["ADDR"] = fRow.Table.Columns.Contains("ADDR") ? fRow["ADDR"].ToString() : "";
            facInfo["TEL"] = fRow.Table.Columns.Contains("TEL") ? fRow["TEL"].ToString() : "";
            facInfo["Land_no"] = fRow.Table.Columns.Contains("Land_no") ? fRow["Land_no"].ToString() : "";

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
            facInfo["TwdX"] = twdX;
            facInfo["TwdY"] = twdY;
            facInfo["Lat"] = lat;
            facInfo["Lng"] = lon;

            // 2. 查詢 INV_DATA
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

            // 3. 解析九大防制設施之檢查細節與記點項目
            List<Dictionary<string, object>> sections = BuildSectionDetails(invRow);

            // 計算各項缺失與總點數
            int totalLossPoint = 0;
            foreach (Dictionary<string, object> sec in sections)
            {
                if (sec.ContainsKey("LossPoint"))
                {
                    totalLossPoint += Convert.ToInt32(sec["LossPoint"]);
                }
            }
            recordData["TotalLossPoint"] = totalLossPoint;

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

            // 5. 查詢設備統計數量
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
            List<Dictionary<string, object>> devSummary = new List<Dictionary<string, object>>();
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

            // 6. 讀取現有上傳照片與三方簽名圖片 (多候選路徑與中文檔名相容探測)
            string appPath = HttpContext.Current.Request.ApplicationPath;
            if (appPath == "/") appPath = "";

            Dictionary<string, string> existingPhotos = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            Dictionary<string, string> signatures = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            signatures["sig1"] = "";
            signatures["sig2"] = "";
            signatures["sig3"] = "";

            string cNo = facInfo.ContainsKey("C_NO") && facInfo["C_NO"] != null ? facInfo["C_NO"].ToString().Trim() : "";

            // 照片定位：INV_NO 為「各場所各自累加」，僅取該筆巡查專屬目錄，絕不跨目錄合併
            // (舊邏輯會把 facId 根目錄 / 其他子資料夾 / 他場所同編號資料夾的照片補進空欄位 → 讀到 2024 舊照片)
            DateTime invDateVal = DateTime.MinValue;
            if (invRow.Table.Columns.Contains("INV_DATE") && invRow["INV_DATE"] != DBNull.Value)
            {
                DateTime.TryParse(invRow["INV_DATE"].ToString(), out invDateVal);
            }

            string photoUrlPrefix;
            string[] photoFiles = InvPhotoHelper.GetPhotoFiles(facId, invNo, cNo, invDateVal, out photoUrlPrefix);

            foreach (string f in photoFiles)
            {
                string fname = Path.GetFileName(f);
                string fbase = Path.GetFileNameWithoutExtension(f);
                string fUrl = appPath + photoUrlPrefix + HttpUtility.UrlPathEncode(fname);

                // 儲存原始檔名
                if (!existingPhotos.ContainsKey(fbase))
                {
                    existingPhotos[fbase] = fUrl;
                }

                // 簽名圖片識別
                if (fbase.IndexOf("sig1", StringComparison.OrdinalIgnoreCase) >= 0 || fbase.Contains("簽名1") || fbase.Contains("稽查人員"))
                {
                    if (string.IsNullOrEmpty(signatures["sig1"])) signatures["sig1"] = fUrl;
                }
                else if (fbase.IndexOf("sig2", StringComparison.OrdinalIgnoreCase) >= 0 || fbase.Contains("簽名2") || fbase.Contains("會同人員"))
                {
                    if (string.IsNullOrEmpty(signatures["sig2"])) signatures["sig2"] = fUrl;
                }
                else if (fbase.IndexOf("sig3", StringComparison.OrdinalIgnoreCase) >= 0 || fbase.Contains("簽名3") || fbase.Contains("廠方代表"))
                {
                    if (string.IsNullOrEmpty(signatures["sig3"])) signatures["sig3"] = fUrl;
                }

                // 中文檔名映射為標準代號 (相容舊系統上傳的中文名稱)
                MapLegacyPhotoKey(fbase, fUrl, existingPhotos);
            }

            // 7. 組合結果
            Dictionary<string, object> result = new Dictionary<string, object>();
            result["Success"] = true;
            result["FacInfo"] = facInfo;
            result["RecordData"] = recordData;
            result["Sections"] = sections;
            result["DevSummary"] = devSummary;
            result["ExistingPhotos"] = existingPhotos;
            result["Signatures"] = signatures;
            result["Mode"] = mode;
            result["Back"] = string.IsNullOrEmpty(back) ? "0" : back;
            result["LoginUser"] = Session["LoginUser"] != null ? Session["LoginUser"].ToString() : "外勤查核人員";
            result["CurrentTime"] = DateTime.Now.ToString("yyyy-MM-dd HH:mm");

            Response.Write(json.Serialize(result));
        }
        #endregion

        #region 2. 構建九大項查核結果清單
        private List<Dictionary<string, object>> BuildSectionDetails(DataRow r)
        {
            List<Dictionary<string, object>> list = new List<Dictionary<string, object>>();

            // 1. 堆置
            list.Add(CreateSection(1, "堆置逸散性粒狀污染物質", r,
                new string[] { "INV_01_01", "INV_01_02", "INV_01_03" },
                new string[] { "INV_01_04", "INV_01_05" },
                new string[] { "INV_01_07", "INV_01_08", "INV_01_09", "INV_01_09a", "INV_01_09b", "INV_01_09c", "INV_01_09d", "INV_01_10", "INV_01_10a", "INV_01_10b", "INV_01_11", "INV_01_11a", "INV_01_11b", "INV_01_11c", "INV_01_12", "INV_01_12a", "INV_01_12b", "INV_01_12c", "INV_01_13", "INV_01_14" },
                new string[] { "File_1", "File_1a", "File_1b", "File_1c", "File_1d" },
                new string[] { "FileMemo_1", "FileMemo_1a", "FileMemo_1b", "FileMemo_1c", "FileMemo_1d" },
                new string[] { "堆置逸散照片 1", "堆置逸散照片 2", "自動灑水水表", "上月紀錄表", "本月紀錄表" }
            ));

            // 2. 輸送
            list.Add(CreateSection(2, "輸送逸散性粒狀污染物質", r,
                new string[] { "INV_02_01", "INV_02_02", "INV_02_03", "INV_02_04" },
                new string[] { "INV_02_05", "INV_02_06" },
                new string[] { "INV_02_07", "INV_02_08", "INV_02_09", "INV_02_09a", "INV_02_09b", "INV_02_10", "INV_02_10a", "INV_02_10b", "INV_02_10c", "INV_02_11" },
                new string[] { "File_2", "File_2a" },
                new string[] { "FileMemo_2", "FileMemo_2a" },
                new string[] { "輸送作業照片 1", "輸送作業照片 2" }
            ));

            // 3. 運輸車輛
            list.Add(CreateSection(3, "運輸車輛", r,
                new string[] { "INV_03_01", "INV_03_02", "INV_03_03" },
                new string[] { "INV_03_04", "INV_03_05", "INV_03_06" },
                new string[] { "INV_03_07", "INV_03_08", "INV_03_09" },
                new string[] { "File_3", "File_3a" },
                new string[] { "FileMemo_3", "FileMemo_3a" },
                new string[] { "運輸車輛照片 1", "運輸車輛照片 2" }
            ));

            // 4. 車輛通行路徑
            list.Add(CreateSection(4, "車輛通行路徑", r,
                new string[] { "INV_04_01", "INV_04_02", "INV_04_03" },
                new string[] { "INV_04_04", "INV_04_05" },
                new string[] { "INV_04_06", "INV_04_07", "INV_04_08", "INV_04_09" },
                new string[] { "File_4", "File_4a" },
                new string[] { "FileMemo_4", "FileMemo_4a" },
                new string[] { "通行路徑照片 1", "通行路徑照片 2" }
            ));

            // 5. 車輛清洗
            list.Add(CreateSection(5, "車輛清洗", r,
                new string[] { "INV_05_01", "INV_05_02", "INV_05_03" },
                new string[] { "INV_05_04", "INV_05_05", "INV_05_06" },
                new string[] { "INV_05_07", "INV_05_08", "INV_05_09", "INV_05_10", "INV_05_11" },
                new string[] { "File_5", "File_5a", "File_5b", "File_5c", "File_5d", "File_5e", "File_5f", "File_5g", "File_5h", "File_5i" },
                new string[] { "FileMemo_5", "FileMemo_5a", "FileMemo_5b", "FileMemo_5c", "FileMemo_5d", "FileMemo_5e", "FileMemo_5f", "FileMemo_5g", "FileMemo_5h", "FileMemo_5i" },
                new string[] { "洗車台照片 1", "洗車台照片 2", "水槽水深量測", "有效水深", "沖洗長度", "告示牌", "馬達規格", "加壓沖洗", "上月紀錄表", "本月紀錄表" }
            ));

            // 6. 易致粒狀污染物逸散之製程、操作或裝卸作業
            list.Add(CreateSection(6, "易致粒狀污染物逸散之製程裝卸作業", r,
                new string[] { "INV_06_01", "INV_06_02", "INV_06_03", "INV_06_04" },
                new string[] { "INV_06_05", "INV_06_06" },
                new string[] { "INV_06_07", "INV_06_07a", "INV_06_07b", "INV_06_08", "INV_06_08a", "INV_06_08b", "INV_06_09", "INV_06_10", "INV_06_11", "INV_06_12" },
                new string[] { "File_6", "File_6a", "File_6b", "File_6c", "File_6d" },
                new string[] { "FileMemo_6", "FileMemo_6a", "FileMemo_6b", "FileMemo_6c", "FileMemo_6d" },
                new string[] { "製程裝卸照片 1", "製程裝卸照片 2", "監測儀表", "上月紀錄表", "本月紀錄表" }
            ));

            // 7. 公私場所管理之裸露區域
            list.Add(CreateSection(7, "公私場所管理之裸露區域", r,
                new string[] { "INV_07_01", "INV_07_02", "INV_07_03" },
                new string[] { "INV_07_04", "INV_07_05" },
                new string[] { "INV_07_06", "INV_07_07", "INV_07_08", "INV_07_09", "INV_07_10", "INV_07_11" },
                new string[] { "File_7", "File_7a" },
                new string[] { "FileMemo_7", "FileMemo_7a" },
                new string[] { "裸露區域照片 1", "裸露區域照片 2" }
            ));

            // 8. 公私場所管理之道路
            list.Add(CreateSection(8, "公私場所管理之道路", r,
                new string[] { "INV_08_01", "INV_08_02", "INV_08_03" },
                new string[] { "INV_08_04", "INV_08_05" },
                new string[] { "INV_08_06", "INV_08_07", "INV_08_08", "INV_08_09", "INV_08_10" },
                new string[] { "File_8", "File_8a" },
                new string[] { "FileMemo_8", "FileMemo_8a" },
                new string[] { "管理道路照片 1", "管理道路照片 2" }
            ));

            // 9. 攝錄影監視系統
            list.Add(CreateSection(9, "攝錄影監視系統", r,
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

            // 附加照片清單
            List<Dictionary<string, string>> photoList = new List<Dictionary<string, string>>();
            for (int i = 0; i < photoKeys.Length; i++)
            {
                Dictionary<string, string> p = new Dictionary<string, string>();
                p["Key"] = photoKeys[i];
                p["Label"] = i < photoLabels.Length ? photoLabels[i] : photoKeys[i];
                string memoCol = i < memoKeys.Length ? memoKeys[i] : "";
                p["Memo"] = (r.Table.Columns.Contains(memoCol) && r[memoCol] != DBNull.Value) ? r[memoCol].ToString() : "";
                photoList.Add(p);
            }
            sec["Photos"] = photoList;

            return sec;
        }

                private static readonly Dictionary<string, string> CheckItemNames = InitCheckItemNames();

        private static Dictionary<string, string> InitCheckItemNames()
        {
            Dictionary<string, string> dict = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            dict["INV_01_01"] = "無本製程";
            dict["INV_01_02"] = "全項符合防制規範";
            dict["INV_01_03"] = "依核准替代方法設置或採行防制設施";
            dict["INV_01_04"] = "未設置或採行第四條規定防制設施之一 (記10點)";
            dict["INV_01_05"] = "未依直轄市、主管機關同意後之替代方法執行 (記10點)";
            dict["INV_01_07"] = "堆置高度超過阻隔設施高度 (記4點)";
            dict["INV_01_08"] = "採堆置於封閉式建築物內者，未符合第二條第二款規定 (記4點)";
            dict["INV_01_09"] = "堆置區周界阻隔設施未符規定 (記4點)";
            dict["INV_01_09a"] = "阻隔設施高度未達堆置高度 1.25 倍";
            dict["INV_01_09b"] = "未完全圍封堆置區";
            dict["INV_01_09c"] = "阻隔設施破損面積達百分之十以上";
            dict["INV_01_09d"] = "堆置體積3000立方公尺以上未符規定";
            dict["INV_01_10"] = "覆蓋防塵布或防塵網未符規定 (記4點)";
            dict["INV_01_10a"] = "覆蓋面積未達 80%";
            dict["INV_01_10b"] = "三級防制區覆蓋未達 90%";
            dict["INV_01_11"] = "噴灑化學穩定劑未符規定 (記4點)";
            dict["INV_01_11a"] = "噴灑面積未達 80%";
            dict["INV_01_11b"] = "未依第十條記錄施作與保存憑證";
            dict["INV_01_11c"] = "三級防制區噴灑未達 90%";
            dict["INV_01_12"] = "設置自動灑水設備未符規定 (記4點)";
            dict["INV_01_12a"] = "灑水水量及頻率不足保持濕潤";
            dict["INV_01_12b"] = "需人工操作無法自動灑水";
            dict["INV_01_12c"] = "未設水表每日記錄用水量";
            dict["INV_01_13"] = "四周未設置阻隔防溢座或物料掉落溢流至區外 (記4點)";
            dict["INV_01_14"] = "效果優於設施但未依同意方式完整執行 (記4點)";
            dict["INV_02_01"] = "無本製程";
            dict["INV_02_02"] = "採濕式作業免設置";
            dict["INV_02_03"] = "全項符合防制規範";
            dict["INV_02_04"] = "依核准替代方法設置或採行防制設施";
            dict["INV_02_05"] = "未設置防制設施之一 (記10點)";
            dict["INV_02_06"] = "未依主管機關同意替代方法執行 (記10點)";
            dict["INV_02_07"] = "於封閉式建築物內操作未符規定 (記4點)";
            dict["INV_02_08"] = "密閉式輸送系統未完全密閉或破損 (記4點)";
            dict["INV_02_09"] = "採集氣系統未符規定 (記4點)";
            dict["INV_02_09a"] = "集氣系統捕捉速度不足";
            dict["INV_02_09b"] = "未設電表、流量計、壓差計等監測儀表並記錄";
            dict["INV_02_10"] = "採自動灑水設施未符規定 (記4點)";
            dict["INV_02_10a"] = "灑水水量及頻率不足保持濕潤";
            dict["INV_02_10b"] = "需人工操作無法自動灑水";
            dict["INV_02_10c"] = "未設水表每日記錄用水量";
            dict["INV_02_11"] = "效果優於設施但未依同意方式完整執行 (記4點)";
            dict["INV_03_01"] = "無本作業";
            dict["INV_03_02"] = "全項符合防制規範";
            dict["INV_03_03"] = "依核准替代方法設置或採行防制設施";
            dict["INV_03_04"] = "運輸車輛未使用密閉式貨箱或未緊密覆蓋 (記10點)";
            dict["INV_03_05"] = "貨箱未具防滴落污水污泥之功能或設施 (記10點)";
            dict["INV_03_06"] = "未依主管機關同意替代方法執行 (記10點)";
            dict["INV_03_07"] = "封蓋未緊密覆蓋 (邊緣未延伸覆蓋至貨箱上緣15公分以下) (記4點)";
            dict["INV_03_08"] = "具有設施但運輸過程仍滴落污水、污泥或掉落物料於地面 (記4點)";
            dict["INV_03_09"] = "效果優於設施但未依同意方式完整執行 (記4點)";
            dict["INV_04_01"] = "無本作業";
            dict["INV_04_02"] = "全項符合防制規範";
            dict["INV_04_03"] = "依核准替代方法設置或採行防制設施";
            dict["INV_04_04"] = "車輛通行路徑及區域未依規定設置防制設施 (記10點)";
            dict["INV_04_05"] = "未依主管機關同意替代方法執行 (記10點)";
            dict["INV_04_06"] = "設置或採行防制設施面積不足 (記4點)";
            dict["INV_04_07"] = "舖設混凝土、瀝青混凝土或鋼板惟有路面色差 (記4點)";
            dict["INV_04_08"] = "舖設粗級配粒料厚度不足或未灑水保持濕潤 (記4點)";
            dict["INV_04_09"] = "效果優於設施但未依同意方式完整執行 (記4點)";
            dict["INV_05_01"] = "無本作業";
            dict["INV_05_02"] = "全項符合防制規範";
            dict["INV_05_03"] = "依核准替代方法設置或採行防制設施";
            dict["INV_05_04"] = "未依規定以加壓沖洗設備清洗車體及輪胎 (記10點)";
            dict["INV_05_05"] = "須洗掃鄰接道路並設自動洗車設備而未依規定洗掃或設置 (記10點)";
            dict["INV_05_06"] = "未依主管機關同意替代方法執行 (記10點)";
            dict["INV_05_07"] = "運輸車輛未清洗乾淨致門口路面有帶出污泥物料 (記4點)";
            dict["INV_05_08"] = "洗車設備無加壓沖洗功能 (記4點)";
            dict["INV_05_09"] = "自動洗車設備規格未符附表二規定 (記4點)";
            dict["INV_05_10"] = "未設水表電表並記錄用水或用電度數 (記4點)";
            dict["INV_05_11"] = "效果優於設施但未依同意方式完整執行 (記4點)";
            dict["INV_06_01"] = "無本製程";
            dict["INV_06_02"] = "採濕式作業免設置";
            dict["INV_06_03"] = "全項符合防制規範";
            dict["INV_06_04"] = "依核准替代方法設置或採行防制設施";
            dict["INV_06_05"] = "未設置或採行第七條防制設施之一 (記10點)";
            dict["INV_06_06"] = "未依主管機關同意替代方法執行 (記10點)";
            dict["INV_06_07"] = "採負壓操作之密閉式作業未符規定 (記4點)";
            dict["INV_06_07a"] = "未維持負壓操作狀態";
            dict["INV_06_07b"] = "未設電表、流量計、壓差計等監測儀表並記錄";
            dict["INV_06_08"] = "採集氣系統未符規定 (記4點)";
            dict["INV_06_08a"] = "捕捉速度不足";
            dict["INV_06_08b"] = "未設電表等監測儀表並記錄";
            dict["INV_06_09"] = "密閉式作業未妥善密閉或破損 (記4點)";
            dict["INV_06_10"] = "封閉式建築未符合規定 (記4點)";
            dict["INV_06_11"] = "灑水設施噴灑範圍、水量及頻率不足 (記4點)";
            dict["INV_06_12"] = "效果優於設施但未依同意方式完整執行 (記4點)";
            dict["INV_07_01"] = "無本區域";
            dict["INV_07_02"] = "全項符合防制規範";
            dict["INV_07_03"] = "依核准替代方法設置或採行防制設施";
            dict["INV_07_04"] = "未設置或採行第八條防制設施之一 (記10點)";
            dict["INV_07_05"] = "未依主管機關同意替代方法執行 (記10點)";
            dict["INV_07_06"] = "防制設施實施面積未完整涵蓋裸露區域 (記4點)";
            dict["INV_07_07"] = "植生綠化覆蓋稻草蓆碎木厚度不足 (記4點)";
            dict["INV_07_08"] = "舖設粗級配粒料粒徑厚度不足或未灑水保持濕潤 (記4點)";
            dict["INV_07_09"] = "噴灑化學穩定劑或灑水量及頻率不足 (記4點)";
            dict["INV_07_10"] = "噴灑穩定劑未記錄保存購買證明 (記4點)";
            dict["INV_07_11"] = "效果優於設施但未依同意方式完整執行 (記4點)";
            dict["INV_08_01"] = "無本道路";
            dict["INV_08_02"] = "全項符合防制規範";
            dict["INV_08_03"] = "依核准替代方法設置或採行防制設施";
            dict["INV_08_04"] = "交通島及人行道裸露區域未設置防制設施之一 (記10點)";
            dict["INV_08_05"] = "未依主管機關同意替代方法執行 (記10點)";
            dict["INV_08_06"] = "路面有破損、髒污致路面色差 (記4點)";
            dict["INV_08_07"] = "交通島及人行道裸露區域防制面積不足 (記4點)";
            dict["INV_08_08"] = "植生綠化覆蓋稻草蓆碎木厚度不足 (記4點)";
            dict["INV_08_09"] = "舖設粗級配粒料粒徑厚度不足或未灑水 (記4點)";
            dict["INV_08_10"] = "效果優於設施但未依同意方式完整執行 (記4點)";
            dict["INV_09_01"] = "無須設置";
            dict["INV_09_02"] = "全項符合防制規範";
            dict["INV_09_03"] = "依核准替代方法設置或採行防制設施";
            dict["INV_09_04"] = "須設置攝錄影監視系統而未設置 (記10點)";
            dict["INV_09_05"] = "監視系統故障未於次日起算七日內修復完成 (記10點)";
            dict["INV_09_06"] = "未依主管機關同意替代方法執行 (記10點)";
            dict["INV_09_07"] = "未符合附表四規定或記錄影像資料未保存一個月 (記4點)";
            dict["INV_09_08"] = "監視系統故障未即時通報主管機關 (記4點)";
            dict["INV_09_09"] = "效果優於設施但未依同意方式完整執行 (記4點)";
            return dict;
        }

        private string GetCheckItemTitle(string colName)
        {
            if (string.IsNullOrEmpty(colName)) return "";
            if (CheckItemNames.ContainsKey(colName))
            {
                return CheckItemNames[colName];
            }
            // 後備大項辨識，避免顯示孤立英文代號
            if (colName.StartsWith("INV_01_")) return "一、堆置逸散防制缺失項目";
            if (colName.StartsWith("INV_02_")) return "二、輸送逸散防制缺失項目";
            if (colName.StartsWith("INV_03_")) return "三、運輸車輛防制缺失項目";
            if (colName.StartsWith("INV_04_")) return "四、車輛通行路徑防制缺失項目";
            if (colName.StartsWith("INV_05_")) return "五、洗車設施防制缺失項目";
            if (colName.StartsWith("INV_06_")) return "六、製程防制缺失項目";
            if (colName.StartsWith("INV_07_")) return "七、裸露區域防制缺失項目";
            if (colName.StartsWith("INV_08_")) return "八、管轄道路防制缺失項目";
            if (colName.StartsWith("INV_09_")) return "九、監視系統防制缺失項目";
            return colName;
        }
        #endregion

        #region 3. 取得設備與製程詳細資料
        private void GetDeviceDetail()
        {
            string facId = Request["facId"];
            string pCode = Request["pCode"];
            string devName = Request["devName"];

            if (string.IsNullOrEmpty(facId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "缺少場所編號" }));
                return;
            }

            // 1. 查詢設備清單
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

            // 2. 查詢製程清單
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

            Response.Write(json.Serialize(new { Success = true, Devices = devList, Processes = procList }));
        }
        #endregion

        #region 4. 儲存查核結果與三方簽名
        private void SaveCaseResult()
        {
            string reqJson = "";
            using (StreamReader reader = new StreamReader(Request.InputStream, Encoding.UTF8))
            {
                reqJson = reader.ReadToEnd();
            }

            if (string.IsNullOrEmpty(reqJson))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "未接收到任何儲存資料。" }));
                return;
            }

            Dictionary<string, object> req = json.Deserialize<Dictionary<string, object>>(reqJson);
            if (req == null)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "資料格式解析失敗。" }));
                return;
            }

            string facId = req.ContainsKey("facId") ? req["facId"].ToString() : "";
            int invNo = req.ContainsKey("invNo") ? Convert.ToInt32(req["invNo"]) : 0;
            string improveDeadline = req.ContainsKey("improveDeadline") ? req["improveDeadline"].ToString() : "";

            if (string.IsNullOrEmpty(facId) || invNo <= 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "缺少場所編號或查核編號。" }));
                return;
            }

            // 1. 確保圖檔儲存目錄存在 (優先使用現存資料夾，若無則建立標準 ~/Upload/PIC/{facId}/{invNo})
            string targetDir = Server.MapPath("~/Upload/PIC/" + facId + "/" + invNo.ToString());
            string altDir = Server.MapPath("~/Upload/PIC/" + invNo.ToString());
            if (!Directory.Exists(targetDir) && Directory.Exists(altDir))
            {
                targetDir = altDir;
            }
            if (!Directory.Exists(targetDir))
            {
                Directory.CreateDirectory(targetDir);
            }

            // 2. 儲存三方簽名 (Sig1: 稽查人員, Sig2: 會同人員, Sig3: 廠方代表)
            string sig1 = req.ContainsKey("sig1") ? req["sig1"].ToString() : "";
            string sig2 = req.ContainsKey("sig2") ? req["sig2"].ToString() : "";
            string sig3 = req.ContainsKey("sig3") ? req["sig3"].ToString() : "";

            SaveBase64Image(sig1, Path.Combine(targetDir, "Sig1.png"));
            SaveBase64Image(sig2, Path.Combine(targetDir, "Sig2.png"));
            SaveBase64Image(sig3, Path.Combine(targetDir, "Sig3.png"));

            // 3. 更新 INV_DATA 之改善期限 improve_Deadline
            DateTime dtDead;
            object valDead = DBNull.Value;
            if (DateTime.TryParse(improveDeadline, out dtDead))
            {
                valDead = dtDead;
            }

            string sqlUpd = "UPDATE INV_DATA SET improve_Deadline = @improve_Deadline WHERE FAC_ID = @FAC_ID AND INV_NO = @INV_NO";
            int rows = DbHelper.ExecuteNonQuery(sqlUpd,
                new SqlParameter("@improve_Deadline", valDead),
                new SqlParameter("@FAC_ID", facId),
                new SqlParameter("@INV_NO", invNo));

            Response.Write(json.Serialize(new { 
                Success = true, 
                Message = "查核結果與簽章確認已成功儲存！",
                Rows = rows 
            }));
        }

        private void SaveBase64Image(string base64Str, string filePath)
        {
            if (string.IsNullOrEmpty(base64Str)) return;
            try
            {
                int commaIdx = base64Str.IndexOf(',');
                string raw = commaIdx >= 0 ? base64Str.Substring(commaIdx + 1) : base64Str;
                byte[] bytes = Convert.FromBase64String(raw);
                File.WriteAllBytes(filePath, bytes);
            }
            catch (Exception ex)
            {
                // 記錄錯誤但不阻斷全部存檔
                System.Diagnostics.Trace.WriteLine("儲存簽名圖片失敗: " + ex.Message);
            }
        }

        private void MapLegacyPhotoKey(string fbase, string fUrl, Dictionary<string, string> photos)
        {
            // 1. 堆置逸散 (堆罝 / 堆置)
            if (fbase.Contains("堆罝") || fbase.Contains("堆置"))
            {
                if (fbase.Contains("2") || fbase.Contains("_2")) AssignIfEmpty(photos, "File_1a", fUrl);
                else if (fbase.Contains("水表") || fbase.Contains("自動灑水")) AssignIfEmpty(photos, "File_1b", fUrl);
                else if (fbase.Contains("上月")) AssignIfEmpty(photos, "File_1c", fUrl);
                else if (fbase.Contains("本月")) AssignIfEmpty(photos, "File_1d", fUrl);
                else AssignIfEmpty(photos, "File_1", fUrl);
            }
            // 2. 輸送逸散
            else if (fbase.Contains("輸送"))
            {
                if (fbase.Contains("2") || fbase.Contains("_2")) AssignIfEmpty(photos, "File_2a", fUrl);
                else AssignIfEmpty(photos, "File_2", fUrl);
            }
            // 3. 運輸車輛
            else if (fbase.Contains("運輸車輛"))
            {
                if (fbase.Contains("2") || fbase.Contains("_2")) AssignIfEmpty(photos, "File_3a", fUrl);
                else AssignIfEmpty(photos, "File_3", fUrl);
            }
            // 4. 車輛通行路徑
            else if (fbase.Contains("通行路徑") || fbase.Contains("車輛通行"))
            {
                if (fbase.Contains("2") || fbase.Contains("_2")) AssignIfEmpty(photos, "File_4a", fUrl);
                else AssignIfEmpty(photos, "File_4", fUrl);
            }
            // 5. 車輛清洗
            else if (fbase.Contains("車輛清洗") || fbase.Contains("洗車"))
            {
                if (fbase.Contains("2") || fbase.Contains("_2")) AssignIfEmpty(photos, "File_5a", fUrl);
                else if (fbase.Contains("水槽") || fbase.Contains("水深")) AssignIfEmpty(photos, "File_5b", fUrl);
                else if (fbase.Contains("有效水深") || fbase.Contains("換水")) AssignIfEmpty(photos, "File_5c", fUrl);
                else if (fbase.Contains("噴水") || fbase.Contains("沖洗長度")) AssignIfEmpty(photos, "File_5d", fUrl);
                else if (fbase.Contains("告示牌") || fbase.Contains("閘門")) AssignIfEmpty(photos, "File_5e", fUrl);
                else if (fbase.Contains("馬達")) AssignIfEmpty(photos, "File_5f", fUrl);
                else if (fbase.Contains("廢水") || fbase.Contains("加壓")) AssignIfEmpty(photos, "File_5g", fUrl);
                else if (fbase.Contains("上月")) AssignIfEmpty(photos, "File_5h", fUrl);
                else if (fbase.Contains("本月")) AssignIfEmpty(photos, "File_5i", fUrl);
                else AssignIfEmpty(photos, "File_5", fUrl);
            }
            // 6. 製程、操作或裝卸作業
            else if (fbase.Contains("製程") || fbase.Contains("操作") || fbase.Contains("裝卸"))
            {
                if (fbase.Contains("2") || fbase.Contains("_2")) AssignIfEmpty(photos, "File_6a", fUrl);
                else if (fbase.Contains("儀表") || fbase.Contains("監測")) AssignIfEmpty(photos, "File_6b", fUrl);
                else if (fbase.Contains("上月")) AssignIfEmpty(photos, "File_6c", fUrl);
                else if (fbase.Contains("本月")) AssignIfEmpty(photos, "File_6d", fUrl);
                else AssignIfEmpty(photos, "File_6", fUrl);
            }
            // 7. 裸露區域
            else if (fbase.Contains("裸露"))
            {
                if (fbase.Contains("2") || fbase.Contains("_2")) AssignIfEmpty(photos, "File_7a", fUrl);
                else AssignIfEmpty(photos, "File_7", fUrl);
            }
            // 8. 管理之道路
            else if (fbase.Contains("管理之道路") || fbase.Contains("管理道路"))
            {
                if (fbase.Contains("2") || fbase.Contains("_2")) AssignIfEmpty(photos, "File_8a", fUrl);
                else AssignIfEmpty(photos, "File_8", fUrl);
            }
            // 9. 監視系統
            else if (fbase.Contains("監視系統") || fbase.Contains("攝錄影") || fbase.Contains("監視"))
            {
                if (fbase.Contains("2") || fbase.Contains("_2")) AssignIfEmpty(photos, "File_9a", fUrl);
                else AssignIfEmpty(photos, "File_9", fUrl);
            }
            // 10. 許可不符
            else if (fbase.Contains("許可不符") || fbase.Contains("10a"))
            {
                AssignIfEmpty(photos, "File_10a", fUrl);
            }
            else if (fbase.Contains("10b"))
            {
                AssignIfEmpty(photos, "File_10b", fUrl);
            }
            // 11. 道路抽查
            else if (fbase.Contains("道路抽查") || fbase.Contains("認養道路") || fbase.Contains("11a"))
            {
                AssignIfEmpty(photos, "File_11a", fUrl);
            }
            else if (fbase.Contains("11b"))
            {
                AssignIfEmpty(photos, "File_11b", fUrl);
            }
            // 全景照片與工廠正門口
            else if (fbase.Contains("全景"))
            {
                AssignIfEmpty(photos, "File_AllView", fUrl);
                AssignIfEmpty(photos, "全景照片", fUrl);
            }
            else if (fbase.Contains("正門口") || fbase.Contains("門口"))
            {
                AssignIfEmpty(photos, "File_Entrance", fUrl);
                AssignIfEmpty(photos, "工廠正門口", fUrl);
            }
            else if (fbase.Contains("輔導簽認"))
            {
                if (fbase.Contains("2") || fbase.Contains("_2")) AssignIfEmpty(photos, "File_Counseling2", fUrl);
                else AssignIfEmpty(photos, "File_Counseling1", fUrl);
            }
            else if (fbase.Contains("集氣效率") || fbase.Contains("集氣評估"))
            {
                if (fbase.Contains("2") || fbase.Contains("_2")) AssignIfEmpty(photos, "File_CollGasEfficiency2", fUrl);
                else if (fbase.Contains("3") || fbase.Contains("_3")) AssignIfEmpty(photos, "File_CollGasEfficiency3", fUrl);
                else if (fbase.Contains("4") || fbase.Contains("_4")) AssignIfEmpty(photos, "File_CollGasEfficiency4", fUrl);
                else AssignIfEmpty(photos, "File_CollGasEfficiency1", fUrl);
            }
            else if (fbase.Contains("空品感測") || fbase.Contains("空品數據"))
            {
                if (fbase.Contains("2") || fbase.Contains("_2")) AssignIfEmpty(photos, "File_AirQualityValue2", fUrl);
                else AssignIfEmpty(photos, "File_AirQualityValue1", fUrl);
            }

            // 雙向映射：若為英文 File_* 檔名，亦補足中文 Key
            if (fbase.Equals("File_1", StringComparison.OrdinalIgnoreCase)) AssignIfEmpty(photos, "堆罝逸散性粒狀污染物質", fUrl);
            else if (fbase.Equals("File_1a", StringComparison.OrdinalIgnoreCase)) AssignIfEmpty(photos, "堆罝逸散性粒狀污染物質_2", fUrl);
            else if (fbase.Equals("File_2", StringComparison.OrdinalIgnoreCase)) AssignIfEmpty(photos, "輸送逸散性粒狀污染物質", fUrl);
            else if (fbase.Equals("File_3", StringComparison.OrdinalIgnoreCase)) AssignIfEmpty(photos, "運輸車輛", fUrl);
            else if (fbase.Equals("File_4", StringComparison.OrdinalIgnoreCase)) AssignIfEmpty(photos, "車輛通行路徑", fUrl);
            else if (fbase.Equals("File_5", StringComparison.OrdinalIgnoreCase)) AssignIfEmpty(photos, "車輛清洗", fUrl);
            else if (fbase.Equals("File_6", StringComparison.OrdinalIgnoreCase)) AssignIfEmpty(photos, "易致粒狀污染物逸散之製程、操作或裝卸作業_1", fUrl);
            else if (fbase.Equals("File_7", StringComparison.OrdinalIgnoreCase)) AssignIfEmpty(photos, "公私場所管理之裸露區域", fUrl);
            else if (fbase.Equals("File_8", StringComparison.OrdinalIgnoreCase)) AssignIfEmpty(photos, "公私場所管理之道路_1", fUrl);
            else if (fbase.Equals("File_9", StringComparison.OrdinalIgnoreCase)) AssignIfEmpty(photos, "攝錄影監視系統_1", fUrl);
            else if (fbase.Equals("File_10a", StringComparison.OrdinalIgnoreCase)) AssignIfEmpty(photos, "其他潛勢調查照片1", fUrl);
            else if (fbase.Equals("File_10b", StringComparison.OrdinalIgnoreCase)) AssignIfEmpty(photos, "其他潛勢調查照片2", fUrl);
            else if (fbase.Equals("File_11a", StringComparison.OrdinalIgnoreCase)) AssignIfEmpty(photos, "執行道路髒污抽查照片1", fUrl);
            else if (fbase.Equals("File_11b", StringComparison.OrdinalIgnoreCase)) AssignIfEmpty(photos, "執行道路髒污抽查照片2", fUrl);
            else if (fbase.Equals("File_AllView", StringComparison.OrdinalIgnoreCase)) AssignIfEmpty(photos, "全景照片", fUrl);
            else if (fbase.Equals("File_Entrance", StringComparison.OrdinalIgnoreCase)) AssignIfEmpty(photos, "工廠正門口", fUrl);
        }

        private void AssignIfEmpty(Dictionary<string, string> dict, string key, string value)
        {
            if (!dict.ContainsKey(key) || string.IsNullOrEmpty(dict[key]))
            {
                dict[key] = value;
            }
        }
        #endregion

        #region 5. 二度分帶座標轉換演算法 (TWD97 轉 WGS84)
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
