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
    public partial class managerList_Bare : Page
    {
        private JavaScriptSerializer json;

        public managerList_Bare()
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
            string act = action.ToLower();
            if (act == "get_init_data")
            {
                GetInitData();
            }
            else if (act == "get_list")
            {
                GetBareList();
            }
            else if (act == "get_cases")
            {
                GetBareCases();
            }
            else if (act == "get_check_url")
            {
                GetCheckUrl();
            }
            else if (act == "batch_pass")
            {
                BatchPass();
            }
            else
            {
                Response.Write(json.Serialize(new { Success = false, Message = "未知操作" }));
            }
        }

        private void GetInitData()
        {
            string currentUserId = GetCurrentUser();
            string reqMode = (Request["mode"] ?? "").Trim().ToUpper();
            if (string.IsNullOrEmpty(reqMode))
            {
                reqMode = "INV1";
            }

            // 統計各審查階段待審查場址數與查核案件數
            int countInv1Sites = 0, countInv1Cases = 0;
            int countInv2Sites = 0, countInv2Cases = 0;
            int countInv3Sites = 0, countInv3Cases = 0;
            int countTotalSites = 0;

            try
            {
                string sqlStat = @"
                    SELECT 
                        ISNULL((SELECT COUNT(DISTINCT Bare_ID) FROM Bare_INV WHERE INV_State = 'A00'), 0) AS Cnt_Inv1_Sites,
                        ISNULL((SELECT COUNT(DISTINCT Bare_ID) FROM Bare_INV WHERE INV_State = 'A01'), 0) AS Cnt_Inv2_Sites,
                        ISNULL((SELECT COUNT(DISTINCT Bare_ID) FROM Bare_INV WHERE INV_State = 'A02'), 0) AS Cnt_Inv3_Sites,
                        ISNULL((SELECT COUNT(1) FROM Bare_INV WHERE INV_State = 'A00'), 0) AS Cnt_Inv1_Cases,
                        ISNULL((SELECT COUNT(1) FROM Bare_INV WHERE INV_State = 'A01'), 0) AS Cnt_Inv2_Cases,
                        ISNULL((SELECT COUNT(1) FROM Bare_INV WHERE INV_State = 'A02'), 0) AS Cnt_Inv3_Cases,
                        ISNULL((SELECT COUNT(1) FROM Bare_Main), 0) AS Cnt_Total_Sites";

                DataTable dtStat = DbHelper.ExecuteDataTable(sqlStat);
                if (dtStat != null && dtStat.Rows.Count > 0)
                {
                    DataRow r = dtStat.Rows[0];
                    countInv1Sites = Convert.ToInt32(r["Cnt_Inv1_Sites"]);
                    countInv2Sites = Convert.ToInt32(r["Cnt_Inv2_Sites"]);
                    countInv3Sites = Convert.ToInt32(r["Cnt_Inv3_Sites"]);
                    countInv1Cases = Convert.ToInt32(r["Cnt_Inv1_Cases"]);
                    countInv2Cases = Convert.ToInt32(r["Cnt_Inv2_Cases"]);
                    countInv3Cases = Convert.ToInt32(r["Cnt_Inv3_Cases"]);
                    countTotalSites = Convert.ToInt32(r["Cnt_Total_Sites"]);
                }
            }
            catch
            {
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                CurrentUser = currentUserId,
                InitialMode = reqMode,
                Stats = new
                {
                    CountInv1 = countInv1Sites,
                    CountInv2 = countInv2Sites,
                    CountInv3 = countInv3Sites,
                    CountInv1Cases = countInv1Cases,
                    CountInv2Cases = countInv2Cases,
                    CountInv3Cases = countInv3Cases,
                    CountTotal = countTotalSites
                }
            }));
        }

        private void GetBareList()
        {
            string mode = (Request["mode"] ?? "INV1").Trim().ToUpper();
            string bareGroundNo = (Request["bareGroundNo"] ?? "").Trim();
            string addr = (Request["addr"] ?? "").Trim();
            string landUse = (Request["landUse"] ?? "").Trim();
            string dateStart = (Request["dateStart"] ?? "").Trim();
            string dateEnd = (Request["dateEnd"] ?? "").Trim();

            string stateCode = "";
            if (mode == "INV1")
            {
                stateCode = "A00";
            }
            else if (mode == "INV2")
            {
                stateCode = "A01";
            }
            else if (mode == "INV3")
            {
                stateCode = "A02";
            }

            List<SqlParameter> paramList = new List<SqlParameter>();
            StringBuilder whereSb = new StringBuilder();

            if (!string.IsNullOrEmpty(stateCode))
            {
                whereSb.Append(" AND TabA.Last_INV_State = @StateCode ");
                paramList.Add(new SqlParameter("@StateCode", stateCode));
            }

            if (!string.IsNullOrEmpty(bareGroundNo))
            {
                whereSb.Append(" AND TabA.BareGroundNo LIKE '%' + @BareGroundNo + '%' ");
                paramList.Add(new SqlParameter("@BareGroundNo", bareGroundNo));
            }

            if (!string.IsNullOrEmpty(addr))
            {
                whereSb.Append(" AND TabA.ADDR LIKE '%' + @ADDR + '%' ");
                paramList.Add(new SqlParameter("@ADDR", addr));
            }

            if (!string.IsNullOrEmpty(landUse))
            {
                whereSb.Append(" AND TabA.LAND_USE LIKE '%' + @LAND_USE + '%' ");
                paramList.Add(new SqlParameter("@LAND_USE", landUse));
            }

            if (!string.IsNullOrEmpty(dateStart))
            {
                DateTime dtS;
                if (DateTime.TryParse(dateStart, out dtS))
                {
                    whereSb.Append(" AND TabA.Last_Check_Date >= @DateStart ");
                    paramList.Add(new SqlParameter("@DateStart", dtS.ToString("yyyy-MM-dd 00:00:00")));
                }
            }

            if (!string.IsNullOrEmpty(dateEnd))
            {
                DateTime dtE;
                if (DateTime.TryParse(dateEnd, out dtE))
                {
                    whereSb.Append(" AND TabA.Last_Check_Date <= @DateEnd ");
                    paramList.Add(new SqlParameter("@DateEnd", dtE.ToString("yyyy-MM-dd 23:59:59")));
                }
            }

            string innerSelectStateOrder = "";
            if (!string.IsNullOrEmpty(stateCode))
            {
                innerSelectStateOrder = " AND INV_State = @StateCode ";
            }

            string sql = @"
                SELECT * FROM 
                (
                    SELECT 
                        Bare_Main.Bare_ID,
                        CASE WHEN Bare_Main.BareGroundNo IS NULL OR Bare_Main.BareGroundNo = '' THEN '--' ELSE Bare_Main.BareGroundNo END AS BareGroundNo,
                        CASE WHEN Bare_Main.ADDR IS NULL OR Bare_Main.ADDR = '' THEN '--' ELSE Bare_Main.ADDR END AS ADDR,
                        CASE WHEN Bare_Main.LAND_USE IS NULL OR Bare_Main.LAND_USE = '' THEN '--' ELSE Bare_Main.LAND_USE END AS LAND_USE,
                        CONVERT(NVARCHAR(20), Bare_Main.latitude) AS LatStr,
                        CONVERT(NVARCHAR(20), Bare_Main.longtitude) AS LngStr,
                        (SELECT TOP 1 Check_Date FROM Bare_INV WHERE Bare_INV.Bare_ID = Bare_Main.Bare_ID " + innerSelectStateOrder + @" ORDER BY Check_Date DESC) AS Last_Check_Date,
                        (SELECT TOP 1 INV_State FROM Bare_INV WHERE Bare_INV.Bare_ID = Bare_Main.Bare_ID " + innerSelectStateOrder + @" ORDER BY Check_Date DESC) AS Last_INV_State,
                        (SELECT TOP 1 Bare_State_List.State_Name FROM Bare_INV LEFT JOIN Bare_State_List ON Bare_State_List.State_ID = Bare_INV.INV_State WHERE Bare_INV.Bare_ID = Bare_Main.Bare_ID " + innerSelectStateOrder + @" ORDER BY Bare_INV.Check_Date DESC) AS Last_State_Name,
                        (SELECT COUNT(1) FROM Bare_INV WHERE Bare_INV.Bare_ID = Bare_Main.Bare_ID " + innerSelectStateOrder + @") AS Case_Count
                    FROM Bare_Main
                ) AS TabA
                WHERE 1 = 1 " + whereSb.ToString() + @"
                ORDER BY TabA.Last_Check_Date DESC, TabA.Bare_ID DESC";

            DataTable dt = null;
            try
            {
                dt = DbHelper.ExecuteDataTable(sql, paramList.ToArray());
            }
            catch (Exception ex)
            {
                Response.Write(json.Serialize(new
                {
                    Success = false,
                    Message = "查詢場址失敗：" + ex.Message
                }));
                return;
            }

            List<Dictionary<string, object>> items = new List<Dictionary<string, object>>();
            int statTotalCases = 0;

            if (dt != null)
            {
                foreach (DataRow row in dt.Rows)
                {
                    Dictionary<string, object> it = new Dictionary<string, object>();
                    string bareId = row["Bare_ID"].ToString();
                    it["Bare_ID"] = bareId;
                    it["BareGroundNo"] = row["BareGroundNo"].ToString();
                    it["ADDR"] = row["ADDR"].ToString();
                    it["LAND_USE"] = row["LAND_USE"].ToString();

                    double lat = 0;
                    double lng = 0;
                    if (row["LatStr"] != DBNull.Value && !string.IsNullOrEmpty(row["LatStr"].ToString()))
                    {
                        double.TryParse(row["LatStr"].ToString(), out lat);
                    }
                    if (row["LngStr"] != DBNull.Value && !string.IsNullOrEmpty(row["LngStr"].ToString()))
                    {
                        double.TryParse(row["LngStr"].ToString(), out lng);
                    }

                    // 若座標為 TWD97 (約 X=200000~350000, Y=2600000~2800000)，轉換為 WGS84 經緯度
                    if (lat > 1000 && lng > 1000)
                    {
                        double wgsLat, wgsLng;
                        Twd97ToWgs84(lng, lat, out wgsLat, out wgsLng);
                        lat = wgsLat;
                        lng = wgsLng;
                    }

                    it["Latitude"] = lat;
                    it["Longitude"] = lng;
                    it["CoordText"] = (lat > 0 && lng > 0) ? string.Format("{0:0.00000}, {1:0.00000}", lat, lng) : "--";

                    string checkDateStr = "--";
                    if (row["Last_Check_Date"] != DBNull.Value)
                    {
                        DateTime cdt;
                        if (DateTime.TryParse(row["Last_Check_Date"].ToString(), out cdt))
                        {
                            checkDateStr = cdt.ToString("yyyy/MM/dd HH:mm");
                        }
                    }
                    it["Last_Check_Date"] = checkDateStr;

                    it["Last_INV_State"] = row["Last_INV_State"].ToString();
                    it["Last_State_Name"] = row["Last_State_Name"] != DBNull.Value ? row["Last_State_Name"].ToString() : "--";

                    int cCount = 0;
                    if (row["Case_Count"] != DBNull.Value)
                    {
                        int.TryParse(row["Case_Count"].ToString(), out cCount);
                    }
                    it["Case_Count"] = cCount;
                    statTotalCases += cCount;

                    items.Add(it);
                }
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                Items = items,
                TotalCount = items.Count,
                TotalCases = statTotalCases
            }));
        }

        private void GetBareCases()
        {
            string bareId = (Request["bareId"] ?? "").Trim();
            string mode = (Request["mode"] ?? "").Trim().ToUpper();

            if (string.IsNullOrEmpty(bareId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "缺少場址編號 (bareId)" }));
                return;
            }

            string stateCode = "";
            if (mode == "INV1")
            {
                stateCode = "A00";
            }
            else if (mode == "INV2")
            {
                stateCode = "A01";
            }
            else if (mode == "INV3")
            {
                stateCode = "A02";
            }

            // 1. 查詢場址基本資料
            string sqlMain = "SELECT * FROM Bare_Main WHERE Bare_ID = @Bare_ID";
            DataTable dtMain = DbHelper.ExecuteDataTable(sqlMain, new SqlParameter("@Bare_ID", bareId));
            if (dtMain == null || dtMain.Rows.Count == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "找不到該裸露地場址資料" }));
                return;
            }

            DataRow rMain = dtMain.Rows[0];
            Dictionary<string, object> facInfo = new Dictionary<string, object>();
            facInfo["Bare_ID"] = bareId;
            facInfo["BareGroundNo"] = rMain["BareGroundNo"].ToString();
            facInfo["ADDR"] = rMain["ADDR"].ToString();
            facInfo["LAND_USE"] = rMain["LAND_USE"].ToString();

            double lat = 0, lng = 0;
            if (rMain["latitude"] != DBNull.Value) double.TryParse(rMain["latitude"].ToString(), out lat);
            if (rMain["longtitude"] != DBNull.Value) double.TryParse(rMain["longtitude"].ToString(), out lng);
            if (lat > 1000 && lng > 1000)
            {
                double wLat, wLng;
                Twd97ToWgs84(lng, lat, out wLat, out wLng);
                lat = wLat;
                lng = wLng;
            }
            facInfo["Latitude"] = lat;
            facInfo["Longitude"] = lng;

            // 2. 查詢查核紀錄清單
            List<SqlParameter> pList = new List<SqlParameter>();
            pList.Add(new SqlParameter("@Bare_ID", bareId));

            string sqlCases = @"
                SELECT 
                    Bare_INV.*,
                    Bare_State_List.State_Name,
                    Bare_State_List.Next_State,
                    Bare_State_List.Back_State
                FROM Bare_INV 
                LEFT JOIN Bare_State_List ON Bare_State_List.State_ID = Bare_INV.INV_State 
                WHERE Bare_ID = @Bare_ID ";

            if (!string.IsNullOrEmpty(stateCode))
            {
                sqlCases += " AND Bare_INV.INV_State = @INV_State ";
                pList.Add(new SqlParameter("@INV_State", stateCode));
            }

            sqlCases += " ORDER BY Bare_INV.Check_Date DESC, Bare_INV.INV_NO DESC";

            DataTable dtCases = DbHelper.ExecuteDataTable(sqlCases, pList.ToArray());
            List<Dictionary<string, object>> caseList = new List<Dictionary<string, object>>();

            if (dtCases != null)
            {
                foreach (DataRow row in dtCases.Rows)
                {
                    Dictionary<string, object> c = new Dictionary<string, object>();
                    int invNo = Convert.ToInt32(row["INV_NO"]);
                    c["INV_NO"] = invNo;
                    c["Bare_ID"] = bareId;

                    string cDateStr = "--";
                    if (row["Check_Date"] != DBNull.Value)
                    {
                        DateTime cdt;
                        if (DateTime.TryParse(row["Check_Date"].ToString(), out cdt))
                        {
                            cDateStr = cdt.ToString("yyyy/MM/dd HH:mm");
                        }
                    }
                    c["Check_Date"] = cDateStr;

                    string aroundMemo = row["Around_Memo"] != DBNull.Value ? row["Around_Memo"].ToString().Replace("<br />", " ").Trim() : "--";
                    string wasteType = row["Waste_Type"] != DBNull.Value ? row["Waste_Type"].ToString().Replace("<br />", " ").Trim() : "--";
                    string surroundings = row["surroundings"] != DBNull.Value ? row["surroundings"].ToString().Replace("<br />", " ").Trim() : "--";

                    c["Around_Memo"] = string.IsNullOrEmpty(aroundMemo) ? "--" : aroundMemo;
                    c["Waste_Type"] = string.IsNullOrEmpty(wasteType) ? "--" : wasteType;
                    c["Surroundings"] = string.IsNullOrEmpty(surroundings) ? "--" : surroundings;

                    float pLen = 0, pWid = 0, pHei = 0, pVol = 0, pAre = 0;
                    if (row["pLength"] != DBNull.Value) float.TryParse(row["pLength"].ToString(), out pLen);
                    if (row["pWidth"] != DBNull.Value) float.TryParse(row["pWidth"].ToString(), out pWid);
                    if (row["pHeight"] != DBNull.Value) float.TryParse(row["pHeight"].ToString(), out pHei);
                    if (row["pVolume"] != DBNull.Value) float.TryParse(row["pVolume"].ToString(), out pVol);
                    if (row["pArea"] != DBNull.Value) float.TryParse(row["pArea"].ToString(), out pAre);

                    c["pLength"] = pLen;
                    c["pWidth"] = pWid;
                    c["pHeight"] = pHei;
                    c["pVolume"] = pVol;
                    c["pArea"] = pAre;
                    c["AreaSpec"] = string.Format("長:{0:0.0}m 寬:{1:0.0}m 高:{2:0.0}m | 面積:{3:0.0}m² 體積:{4:0.0}m³", pLen, pWid, pHei, pAre, pVol);

                    string invState = row["INV_State"] != DBNull.Value ? row["INV_State"].ToString() : "";
                    string stateName = row["State_Name"] != DBNull.Value ? row["State_Name"].ToString() : invState;

                    c["INV_State"] = invState;
                    c["State_Name"] = stateName;
                    c["Next_State"] = row["Next_State"] != DBNull.Value ? row["Next_State"].ToString() : "";
                    c["Back_State"] = row["Back_State"] != DBNull.Value ? row["Back_State"].ToString() : "";

                    // 照片偵測
                    List<string> photos = GetCasePhotos(bareId, invNo);
                    c["Photos"] = photos;

                    // 審查歷程歷史
                    List<Dictionary<string, object>> histories = GetCaseHistories(bareId, invNo);
                    c["Histories"] = histories;

                    // 動作按鈕可用性
                    c["CanFirstChk"] = (invState == "A00");
                    c["CanDoubleChk"] = (invState == "A01");
                    c["CanTroubleChk"] = (invState == "A02");

                    // 產生各動作安全連結
                    c["UrlFirstChk"] = BuildCheckUrl("INV1", bareId, invNo);
                    c["UrlDoubleChk"] = BuildCheckUrl("INV2", bareId, invNo);
                    c["UrlTroubleChk"] = BuildCheckUrl("INV3", bareId, invNo);
                    c["UrlView"] = BuildViewUrl(bareId, invNo);

                    caseList.Add(c);
                }
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                FacInfo = facInfo,
                Cases = caseList
            }));
        }

        private List<string> GetCasePhotos(string bareId, int invNo)
        {
            List<string> photos = new List<string>();
            try
            {
                // 優先探測可能的實體目錄路徑 (相容本機與正式機子站台 NTPC_FEC / NTPC_FECM)
                string[] candidateDirs = new string[]
                {
                    HttpContext.Current.Server.MapPath("~/Upload/BareGround/" + bareId + "/" + invNo),
                    HttpContext.Current.Server.MapPath("/NTPC_FEC/Upload/BareGround/" + bareId + "/" + invNo),
                    HttpContext.Current.Server.MapPath("/NTPC_FECM/Upload/BareGround/" + bareId + "/" + invNo),
                    HttpContext.Current.Server.MapPath("/Upload/BareGround/" + bareId + "/" + invNo)
                };

                DirectoryInfo di = null;
                for (int i = 0; i < candidateDirs.Length; i++)
                {
                    if (Directory.Exists(candidateDirs[i]))
                    {
                        di = new DirectoryInfo(candidateDirs[i]);
                        break;
                    }
                }

                if (di != null)
                {
                    // 支援「現場照片」與「裸露地現場照片」等多種命名規則
                    string[][] patternGroups = new string[][]
                    {
                        new string[] { "*現場照片(一)*", "*裸露地現場照片(一)*", "*現場照片1*", "*photo1*" },
                        new string[] { "*現場照片(二)*", "*裸露地現場照片(二)*", "*現場照片2*", "*photo2*" },
                        new string[] { "*現場照片(三)*", "*裸露地現場照片(三)*", "*現場照片3*", "*photo3*" },
                        new string[] { "*現場照片(四)*", "*裸露地現場照片(四)*", "*現場照片4*", "*photo4*" }
                    };

                    HashSet<string> addedFiles = new HashSet<string>();

                    for (int g = 0; g < patternGroups.Length; g++)
                    {
                        string[] patterns = patternGroups[g];
                        FileInfo targetFi = null;
                        for (int p = 0; p < patterns.Length; p++)
                        {
                            FileInfo[] files = di.GetFiles(patterns[p] + ".*");
                            if (files.Length > 0)
                            {
                                targetFi = files[0];
                                break;
                            }
                        }

                        if (targetFi != null && !addedFiles.Contains(targetFi.Name))
                        {
                            addedFiles.Add(targetFi.Name);
                            // 重要：使用相對路徑 ../Upload/BareGround/...，相對於 /Manager/ 頁面能完美適應站台子目錄 (/NTPC_FECM 或 /NTPC_FEC)
                            photos.Add("../Upload/BareGround/" + bareId + "/" + invNo + "/" + targetFi.Name);
                        }
                    }

                    // 若特定檔名未配對到，則將資料夾中所有圖片 (排除簽名檔 Sig) 納入
                    if (photos.Count == 0)
                    {
                        FileInfo[] allFiles = di.GetFiles("*.*");
                        for (int f = 0; f < allFiles.Length; f++)
                        {
                            FileInfo fi = allFiles[f];
                            string ext = fi.Extension.ToLower();
                            if ((ext == ".jpg" || ext == ".jpeg" || ext == ".png" || ext == ".gif") && !fi.Name.ToLower().StartsWith("sig"))
                            {
                                if (!addedFiles.Contains(fi.Name))
                                {
                                    addedFiles.Add(fi.Name);
                                    photos.Add("../Upload/BareGround/" + bareId + "/" + invNo + "/" + fi.Name);
                                }
                            }
                        }
                    }
                }
            }
            catch
            {
            }
            return photos;
        }

        private List<Dictionary<string, object>> GetCaseHistories(string bareId, int invNo)
        {
            List<Dictionary<string, object>> list = new List<Dictionary<string, object>>();
            try
            {
                string sql = @"
                    SELECT 
                        Bare_Chk_Result.*,
                        UserAcc.Name AS UserName,
                        Bare_State_List.State_Name 
                    FROM Bare_Chk_Result  
                    LEFT JOIN UserAcc ON Bare_Chk_Result.Chk_User = UserAcc.UserID  
                    LEFT JOIN Bare_State_List ON Bare_Chk_Result.INV_State = Bare_State_List.State_ID 
                    WHERE Bare_Chk_Result.Bare_ID = @Bare_ID AND Bare_Chk_Result.INV_NO = @INV_NO
                    ORDER BY Bare_Chk_Result.Chk_Date DESC";

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
                                chkDateStr = dtC.ToString("yyyy/MM/dd HH:mm");
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

        private void GetCheckUrl()
        {
            string mode = (Request["mode"] ?? "").Trim();
            string bareId = (Request["bareId"] ?? "").Trim();
            int invNo = 0;
            int.TryParse(Request["invNo"] ?? "0", out invNo);

            if (string.IsNullOrEmpty(mode) || string.IsNullOrEmpty(bareId) || invNo <= 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "參數不完整" }));
                return;
            }

            string url = "";
            if (mode == "read")
            {
                url = BuildViewUrl(bareId, invNo);
            }
            else
            {
                url = BuildCheckUrl(mode, bareId, invNo);
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                Url = url
            }));
        }

        private string BuildCheckUrl(string mode, string bareId, int invNo)
        {
            // MD5 演算法：(mode + bareId + yyyyMMddHH).ToMD5()
            string raw = mode + bareId + DateTime.Now.ToString("yyyyMMddHH");
            string hash = ComputeMD5(raw);
            return string.Format("Check_Step1_Bare.aspx?mode={0}&id={1}&id1={2}&id2={3}", mode, bareId, hash, invNo);
        }

        private string BuildViewUrl(string bareId, int invNo)
        {
            // MD5 演算法：("MD5:" + bareId + yyyyMMddHH).ToMD5()
            string raw = "MD5:" + bareId + DateTime.Now.ToString("yyyyMMddHH");
            string hash = ComputeMD5(raw);
            return string.Format("../BareGround/BareResult.aspx?id={0}&id1={1}&id2={2}&back=2&mode=read", bareId, hash, invNo);
        }

        private void BatchPass()
        {
            string mode = (Request["mode"] ?? "INV1").Trim().ToUpper();
            string memo = (Request["memo"] ?? "審核合格，符合規定").Trim();
            string itemsRaw = (Request["items"] ?? "").Trim();

            if (string.IsNullOrEmpty(itemsRaw))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "請先勾選欲審核通過的案件" }));
                return;
            }

            string stateCode = "";
            string chkResultText = "審核合格";

            if (mode == "INV1")
            {
                stateCode = "A00";
            }
            else if (mode == "INV2")
            {
                stateCode = "A01";
            }
            else if (mode == "INV3")
            {
                stateCode = "A02";
            }
            else
            {
                Response.Write(json.Serialize(new { Success = false, Message = "當前模式不支援批次審核操作" }));
                return;
            }

            // 取得此狀態合格時對應的 Next_State
            string sqlState = "SELECT Next_State, Back_State FROM Bare_State_List WHERE State_ID = @State_ID";
            DataTable dtState = DbHelper.ExecuteDataTable(sqlState, new SqlParameter("@State_ID", stateCode));
            if (dtState == null || dtState.Rows.Count == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "無法取得對應審查狀態定義 (State_ID: " + stateCode + ")" }));
                return;
            }

            string nextState = dtState.Rows[0]["Next_State"].ToString();
            string currentUser = GetCurrentUser();

            // 解析項目，格式: bareId:invNo,bareId:invNo
            string[] pairs = itemsRaw.Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
            int successCount = 0;
            List<string> errList = new List<string>();

            using (SqlConnection conn = DbHelper.GetOpenConnection())
            using (SqlTransaction trans = conn.BeginTransaction())
            {
                try
                {
                    foreach (string pair in pairs)
                    {
                        string[] tokens = pair.Split(new char[] { ':' }, StringSplitOptions.RemoveEmptyEntries);
                        if (tokens.Length < 2) continue;

                        string bId = tokens[0].Trim();
                        int invNum = 0;
                        if (!int.TryParse(tokens[1].Trim(), out invNum)) continue;

                        List<int> targetInvNos = new List<int>();
                        if (invNum > 0)
                        {
                            targetInvNos.Add(invNum);
                        }
                        else
                        {
                            string sqlFindInvs = "SELECT INV_NO FROM Bare_INV WHERE Bare_ID = @Bare_ID AND INV_State = @INV_State";
                            using (SqlCommand cmdFind = new SqlCommand(sqlFindInvs, conn, trans))
                            {
                                cmdFind.Parameters.Add(new SqlParameter("@Bare_ID", bId));
                                cmdFind.Parameters.Add(new SqlParameter("@INV_State", stateCode));
                                using (SqlDataReader rdr = cmdFind.ExecuteReader())
                                {
                                    while (rdr.Read())
                                    {
                                        targetInvNos.Add(Convert.ToInt32(rdr["INV_NO"]));
                                    }
                                }
                            }
                        }

                        foreach (int singleInvNo in targetInvNos)
                        {
                            // 1. 寫入審查歷程 Bare_Chk_Result
                            string sqlInsertResult = @"
                                INSERT INTO Bare_Chk_Result (Bare_ID, INV_NO, Chk_Date, Chk_Result, Chk_Memo, INV_State, Chk_User)
                                VALUES (@Bare_ID, @INV_NO, @Chk_Date, @Chk_Result, @Chk_Memo, @INV_State, @Chk_User)";

                            using (SqlCommand cmd = new SqlCommand(sqlInsertResult, conn, trans))
                            {
                                cmd.Parameters.Add(new SqlParameter("@Bare_ID", bId));
                                cmd.Parameters.Add(new SqlParameter("@INV_NO", singleInvNo));
                                cmd.Parameters.Add(new SqlParameter("@Chk_Date", DateTime.Now));
                                cmd.Parameters.Add(new SqlParameter("@Chk_Result", chkResultText));
                                cmd.Parameters.Add(new SqlParameter("@Chk_Memo", memo));
                                cmd.Parameters.Add(new SqlParameter("@INV_State", stateCode));
                                cmd.Parameters.Add(new SqlParameter("@Chk_User", currentUser));
                                cmd.ExecuteNonQuery();
                            }

                            // 2. 更新 Bare_INV 之 INV_State 為 Next_State
                            string sqlUpdateInv = @"
                                UPDATE Bare_INV 
                                SET INV_State = @Next_State 
                                WHERE Bare_ID = @Bare_ID AND INV_NO = @INV_NO";

                            using (SqlCommand cmd = new SqlCommand(sqlUpdateInv, conn, trans))
                            {
                                cmd.Parameters.Add(new SqlParameter("@Next_State", nextState));
                                cmd.Parameters.Add(new SqlParameter("@Bare_ID", bId));
                                cmd.Parameters.Add(new SqlParameter("@INV_NO", singleInvNo));
                                cmd.ExecuteNonQuery();
                            }

                            successCount++;
                        }
                    }

                    trans.Commit();
                }
                catch (Exception ex)
                {
                    trans.Rollback();
                    Response.Write(json.Serialize(new
                    {
                        Success = false,
                        Message = "批次審核交易失敗，已復原變更：" + ex.Message
                    }));
                    return;
                }
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                Message = string.Format("已成功將 {0} 筆案件批次審核通過！", successCount),
                SuccessCount = successCount
            }));
        }

        private static string ComputeMD5(string input)
        {
            using (MD5 md5 = MD5.Create())
            {
                byte[] bytes = md5.ComputeHash(Encoding.UTF8.GetBytes(input));
                StringBuilder sb = new StringBuilder();
                for (int i = 0; i < bytes.Length; i++)
                {
                    sb.Append(bytes[i].ToString("X2"));
                }
                return sb.ToString();
            }
        }

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
    }
}
