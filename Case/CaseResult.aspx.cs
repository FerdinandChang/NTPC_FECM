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
                Response.End();
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
                string curHour = DateTime.Now.ToString("yyyyMMddHH");
                string prevHour = DateTime.Now.AddHours(-1).ToString("yyyyMMddHH");
                string token1 = ("MD5:" + facId + curHour).ToMD5();
                string token2 = ("MD5:" + facId + prevHour).ToMD5();

                bool tokenValid = (token == token1 || token == token2);
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

            // 6. 讀取現有上傳照片與三方簽名圖片
            string appPath = HttpContext.Current.Request.ApplicationPath;
            if (appPath == "/") appPath = "";

            Dictionary<string, string> existingPhotos = new Dictionary<string, string>();
            Dictionary<string, string> signatures = new Dictionary<string, string>();
            signatures["sig1"] = "";
            signatures["sig2"] = "";
            signatures["sig3"] = "";

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
                        existingPhotos[fbase] = fUrl;
                    }
                }
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

        private string GetCheckItemTitle(string colName)
        {
            // 常見檢查欄位代號之中文名稱映射
            Dictionary<string, string> dict = new Dictionary<string, string>();
            dict["INV_01_01"] = "全阻隔設施符合規定";
            dict["INV_01_02"] = "採非阻隔設施(防塵網覆蓋/灑水)符合規定";
            dict["INV_01_03"] = "經主管機關同意之其他防制設施";
            dict["INV_01_04"] = "未採行防制設施";
            dict["INV_01_05"] = "阻隔設施面積不足/未符合規定";
            dict["INV_01_07"] = "堆置高度超過阻隔設施高度";
            dict["INV_01_08"] = "防塵布或防塵網未完全覆蓋(未達80%)";
            dict["INV_01_09"] = "未設置自動灑水設備或灑水頻率不足";
            dict["INV_01_10"] = "灑水水量不足以維持堆置表面濕潤";

            dict["INV_02_01"] = "全密閉式輸送作業";
            dict["INV_02_02"] = "局部密閉並設集氣系統";
            dict["INV_02_03"] = "採灑水或化學穩定劑防制符合規定";
            dict["INV_02_05"] = "輸送設施未採行任何防制措施";
            dict["INV_02_06"] = "集氣設施或排氣處理設備故障無效";
            dict["INV_02_07"] = "輸送管線破損逸散";
            dict["INV_02_08"] = "落料點未設置集氣或灑水設施";

            dict["INV_03_01"] = "進出車輛均採用密閉式貨箱";
            dict["INV_03_02"] = "採防塵布緊密覆蓋符合規定";
            dict["INV_03_04"] = "車輛載運逸散性物質未設覆蓋";
            dict["INV_03_05"] = "車斗未清洗即行駛出廠";
            dict["INV_03_07"] = "覆蓋防塵布邊緣未牢固捆紮";

            dict["INV_04_01"] = "路面全鋪設鋼板或混凝土/瀝青";
            dict["INV_04_02"] = "洗掃保持潔淨無路面塵土飛揚";
            dict["INV_04_04"] = "行車路徑未鋪設路面導致大量揚塵";
            dict["INV_04_06"] = "路面破損或積泥未及時清除";

            dict["INV_05_01"] = "設置自動加壓沖洗設備且運作正常";
            dict["INV_05_02"] = "設置符合規格洗車台且有效清洗";
            dict["INV_05_04"] = "未設置洗車台或沖洗設備";
            dict["INV_05_05"] = "洗車設備故障未使用";
            dict["INV_05_07"] = "洗車台沉砂池積泥未清";
            dict["INV_05_08"] = "沖洗水壓不足或噴頭堵塞";

            dict["INV_06_01"] = "製程於密閉建築物內操作";
            dict["INV_06_02"] = "裝卸作業設置防溢散設施符合規範";
            dict["INV_06_05"] = "製程或裝卸作業無任何防制措施致逸散";
            dict["INV_06_07"] = "密閉室出入口未保持關閉";

            dict["INV_07_01"] = "裸露地全採植生綠化或硬質鋪面覆蓋";
            dict["INV_07_04"] = "裸露空地未採任何覆蓋或防塵措施";
            dict["INV_07_06"] = "綠化或覆蓋不完全有明顯塵土";

            dict["INV_08_01"] = "管理道路全鋪設鋼筋混凝土或瀝青並洗掃";
            dict["INV_08_04"] = "管理道路未鋪設致車輛通行揚塵";
            dict["INV_08_06"] = "道路路面有明顯泥沙堆積";

            dict["INV_09_01"] = "全廠監視系統運作正常且連線存檔";
            dict["INV_09_04"] = "未設置攝錄影監視系統";
            dict["INV_09_05"] = "監視系統故障停擺無錄影紀錄";
            dict["INV_09_07"] = "鏡頭角度未涵蓋關鍵出入口或洗車台";

            if (dict.ContainsKey(colName))
            {
                return dict[colName];
            }
            return "檢查項目代號: " + colName;
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

            // 1. 確保圖檔儲存目錄存在
            string targetDir = Server.MapPath("~/Upload/PIC/" + facId + "/" + invNo.ToString());
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
