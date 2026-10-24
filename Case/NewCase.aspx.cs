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
    public partial class NewCase : Page
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
            switch (action.ToLower())
            {
                case "init":
                    InitPageData();
                    break;
                case "getdevices":
                    GetDeviceDetail();
                    break;
                case "save":
                    SaveCaseData();
                    break;
                default:
                    Response.Write(json.Serialize(new { Success = false, Message = "未知的操作指令" }));
                    break;
            }
        }

        #region 1. 頁面初始化資料取得 (場所基本資料、坐標、設備統計、歷史審查、舊資料)
        private void InitPageData()
        {
            string facId = Request["id"];
            string token = Request["id1"];
            string mode = Request["mode"];
            string invNoStr = Request["id2"];

            if (string.IsNullOrEmpty(facId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "缺少場所管制編號參數 (id)" }));
                return;
            }

            if (string.IsNullOrEmpty(mode))
            {
                mode = "new";
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
            var facInfo = new Dictionary<string, object>();
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

            // 2. 查詢場所申報防制設備統計
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
            var devSummary = new List<Dictionary<string, object>>();
            if (dtDevSum != null)
            {
                foreach (DataRow dr in dtDevSum.Rows)
                {
                    var item = new Dictionary<string, object>();
                    item["pCode"] = dr["pCode"].ToString();
                    item["Device_Name"] = dr["Device_Name"].ToString();
                    item["pCount"] = Convert.ToInt32(dr["pCount"]);
                    devSummary.Add(item);
                }
            }

            // 3. 處理編輯模式 (mode == 'edit')
            var recordData = new Dictionary<string, object>();
            var reviewList = new List<Dictionary<string, object>>();
            var existingPhotos = new Dictionary<string, string>();
            int invNo = 0;
            int.TryParse(invNoStr, out invNo);

            if (mode == "edit" && invNo > 0)
            {
                // 3.1 查詢 INV_DATA
                string sqlInv = "SELECT * FROM INV_DATA WHERE FAC_ID = @FAC_ID AND INV_NO = @INV_NO";
                DataTable dtInv = DbHelper.ExecuteDataTable(sqlInv, 
                    new SqlParameter("@FAC_ID", facId), 
                    new SqlParameter("@INV_NO", invNo));

                if (dtInv != null && dtInv.Rows.Count > 0)
                {
                    DataRow ir = dtInv.Rows[0];
                    foreach (DataColumn col in dtInv.Columns)
                    {
                        if (ir[col] != DBNull.Value)
                        {
                            if (col.DataType == typeof(DateTime))
                            {
                                recordData[col.ColumnName] = Convert.ToDateTime(ir[col]).ToString("yyyy-MM-dd HH:mm");
                            }
                            else
                            {
                                recordData[col.ColumnName] = ir[col].ToString();
                            }
                        }
                        else
                        {
                            recordData[col.ColumnName] = "";
                        }
                    }
                }

                // 3.2 查詢歷次審查意見 (INV_Chk_Result)
                string sqlRev = "SELECT * FROM INV_Chk_Result WHERE FAC_ID = @FAC_ID AND INV_NO = @INV_NO ORDER BY Chk_Date DESC";
                DataTable dtRev = DbHelper.ExecuteDataTable(sqlRev, 
                    new SqlParameter("@FAC_ID", facId), 
                    new SqlParameter("@INV_NO", invNo));

                if (dtRev != null)
                {
                    foreach (DataRow rr in dtRev.Rows)
                    {
                        var rItem = new Dictionary<string, object>();
                        if (rr["Chk_Date"] != DBNull.Value)
                        {
                            rItem["Chk_Date"] = Convert.ToDateTime(rr["Chk_Date"]).ToString("yyyy/MM/dd");
                        }
                        else
                        {
                            rItem["Chk_Date"] = "";
                        }

                        rItem["Chk_Result"] = rr["Chk_Result"].ToString();
                        string st = rr["INV_State"].ToString();
                        if (st == "A00") rItem["INV_State_Str"] = "初審";
                        else if (st == "A01") rItem["INV_State_Str"] = "複審";
                        else if (st == "A02") rItem["INV_State_Str"] = "三審";
                        else rItem["INV_State_Str"] = st;

                        rItem["Chk_Memo"] = rr["Chk_Memo"].ToString();
                        reviewList.Add(rItem);
                    }
                }

                // 3.3 取得現有已上傳圖檔清單
                string appPath = HttpContext.Current.Request.ApplicationPath;
                if (appPath == "/") appPath = "";

                string picDirRel = "~/Upload/PIC/" + facId + "/" + invNo;
                string picDirPhy = HttpContext.Current.Server.MapPath(picDirRel);
                if (Directory.Exists(picDirPhy))
                {
                    string[] files = Directory.GetFiles(picDirPhy);
                    foreach (string f in files)
                    {
                        string fname = Path.GetFileName(f);
                        string fbase = Path.GetFileNameWithoutExtension(f);
                        string fUrl = appPath + "/Upload/PIC/" + facId + "/" + invNo + "/" + HttpUtility.UrlPathEncode(fname);
                        existingPhotos[fbase] = fUrl;
                    }
                }
            }

            var result = new Dictionary<string, object>();
            result["Success"] = true;
            result["FacInfo"] = facInfo;
            result["DevSummary"] = devSummary;
            result["Mode"] = mode;
            result["InvNo"] = invNo;
            result["RecordData"] = recordData;
            result["ReviewList"] = reviewList;
            result["ExistingPhotos"] = existingPhotos;
            result["CurrentTime"] = DateTime.Now.ToString("yyyy-MM-dd HH:mm");
            result["LoginUser"] = Session["LoginUser"] != null ? Session["LoginUser"].ToString() : "外勤查核人員";

            Response.Write(json.Serialize(result));
        }
        #endregion

        #region 2. 取得詳細設備與製程資料
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
            var pList = new List<SqlParameter>();
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
            var devList = new List<Dictionary<string, object>>();
            if (dtDev != null)
            {
                foreach (DataRow dr in dtDev.Rows)
                {
                    var d = new Dictionary<string, object>();
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
            var procList = new List<Dictionary<string, object>>();
            if (dtProc != null)
            {
                foreach (DataRow pr in dtProc.Rows)
                {
                    var p = new Dictionary<string, object>();
                    p["Process_NO"] = pr.Table.Columns.Contains("Process_NO") ? pr["Process_NO"].ToString() : "";
                    p["Process_Name"] = pr.Table.Columns.Contains("Process_Name") ? pr["Process_Name"].ToString() : "";
                    procList.Add(p);
                }
            }

            Response.Write(json.Serialize(new { Success = true, Devices = devList, Processes = procList }));
        }
        #endregion

        #region 3. 儲存巡查紀錄 (新增 / 編輯、照片存檔、電子簽名)
        private void SaveCaseData()
        {
            string reqJson = "";
            using (var reader = new StreamReader(Request.InputStream, Encoding.UTF8))
            {
                reqJson = reader.ReadToEnd();
            }

            if (string.IsNullOrEmpty(reqJson))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "未接收到任何儲存資料。" }));
                return;
            }

            var postData = json.Deserialize<Dictionary<string, object>>(reqJson);
            if (postData == null)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "資料格式解析失敗。" }));
                return;
            }

            string facId = postData.ContainsKey("FAC_ID") ? postData["FAC_ID"].ToString().Trim() : "";
            string mode = postData.ContainsKey("Mode") ? postData["Mode"].ToString().Trim() : "new";
            int invNo = 0;
            if (postData.ContainsKey("INV_NO"))
            {
                int.TryParse(postData["INV_NO"].ToString(), out invNo);
            }

            if (string.IsNullOrEmpty(facId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "公私場所編號不得為空。" }));
                return;
            }

            // 提取勾選與文字欄位集合
            Dictionary<string, object> fields = null;
            if (postData.ContainsKey("Fields"))
            {
                fields = postData["Fields"] as Dictionary<string, object>;
            }
            if (fields == null)
            {
                fields = new Dictionary<string, object>();
            }

            // 1. 若為新增巡查 (new 或 new_re)，取得最新流水號
            if (mode == "new" || mode == "new_re" || invNo <= 0)
            {
                string sqlMax = "SELECT ISNULL(MAX(INV_NO), 0) FROM INV_DATA WHERE FAC_ID = @FAC_ID";
                object objMax = DbHelper.ExecuteScalar(sqlMax, new SqlParameter("@FAC_ID", facId));
                int maxNo = 0;
                if (objMax != null && objMax != DBNull.Value)
                {
                    int.TryParse(objMax.ToString(), out maxNo);
                }
                invNo = maxNo + 1;

                string invType = (mode == "new_re") ? "改善複查" : "例行巡查";
                string loginUser = Session["LoginUser"] != null ? Session["LoginUser"].ToString() : "外勤查核人員";

                // 組合 INSERT 欄位
                var colNames = new List<string>();
                var colValues = new List<string>();
                var sqlParams = new List<SqlParameter>();

                colNames.Add("FAC_ID");
                colValues.Add("@FAC_ID");
                sqlParams.Add(new SqlParameter("@FAC_ID", facId));

                colNames.Add("INV_NO");
                colValues.Add("@INV_NO");
                sqlParams.Add(new SqlParameter("@INV_NO", invNo));

                colNames.Add("INV_TYPE");
                colValues.Add("@INV_TYPE");
                sqlParams.Add(new SqlParameter("@INV_TYPE", invType));

                colNames.Add("INV_State");
                colValues.Add("@INV_State");
                sqlParams.Add(new SqlParameter("@INV_State", "A00a")); // 初步草稿

                colNames.Add("Create_User");
                colValues.Add("@Create_User");
                sqlParams.Add(new SqlParameter("@Create_User", loginUser));

                colNames.Add("Create_Date");
                colValues.Add("@Create_Date");
                sqlParams.Add(new SqlParameter("@Create_Date", DateTime.Now));

                // 填入所有自訂欄位
                foreach (var kvp in fields)
                {
                    string colName = kvp.Key;
                    object val = kvp.Value;
                    string pName = "@p_" + colName;

                    colNames.Add(colName);
                    colValues.Add(pName);

                    if (val == null)
                    {
                        sqlParams.Add(new SqlParameter(pName, DBNull.Value));
                    }
                    else if (colName == "INV_DATE")
                    {
                        DateTime dt;
                        if (DateTime.TryParse(val.ToString(), out dt))
                        {
                            sqlParams.Add(new SqlParameter(pName, dt));
                        }
                        else
                        {
                            sqlParams.Add(new SqlParameter(pName, DateTime.Now));
                        }
                    }
                    else if (colName.StartsWith("CleanRoad_Ans2_CleanLength_") || colName == "WashCar_Length" || colName == "WashCar_Width" || colName == "SinkDepth" || colName == "SinkWaterDepth" || colName == "SpoutLen" || colName == "MotorHP")
                    {
                        double numVal;
                        if (double.TryParse(val.ToString(), out numVal))
                        {
                            sqlParams.Add(new SqlParameter(pName, numVal));
                        }
                        else
                        {
                            sqlParams.Add(new SqlParameter(pName, DBNull.Value));
                        }
                    }
                    else
                    {
                        sqlParams.Add(new SqlParameter(pName, val.ToString()));
                    }
                }

                string sqlInsert = "INSERT INTO INV_DATA (" + string.Join(", ", colNames.ToArray()) + ") VALUES (" + string.Join(", ", colValues.ToArray()) + ")";
                DbHelper.ExecuteNonQuery(sqlInsert, sqlParams.ToArray());
            }
            else
            {
                // 2. 編輯更新既有紀錄
                var setClauses = new List<string>();
                var sqlParams = new List<SqlParameter>();

                foreach (var kvp in fields)
                {
                    string colName = kvp.Key;
                    object val = kvp.Value;
                    string pName = "@p_" + colName;

                    setClauses.Add(colName + " = " + pName);

                    if (val == null)
                    {
                        sqlParams.Add(new SqlParameter(pName, DBNull.Value));
                    }
                    else if (colName == "INV_DATE")
                    {
                        DateTime dt;
                        if (DateTime.TryParse(val.ToString(), out dt))
                        {
                            sqlParams.Add(new SqlParameter(pName, dt));
                        }
                        else
                        {
                            sqlParams.Add(new SqlParameter(pName, DateTime.Now));
                        }
                    }
                    else if (colName.StartsWith("CleanRoad_Ans2_CleanLength_") || colName == "WashCar_Length" || colName == "WashCar_Width" || colName == "SinkDepth" || colName == "SinkWaterDepth" || colName == "SpoutLen" || colName == "MotorHP")
                    {
                        double numVal;
                        if (double.TryParse(val.ToString(), out numVal))
                        {
                            sqlParams.Add(new SqlParameter(pName, numVal));
                        }
                        else
                        {
                            sqlParams.Add(new SqlParameter(pName, DBNull.Value));
                        }
                    }
                    else
                    {
                        sqlParams.Add(new SqlParameter(pName, val.ToString()));
                    }
                }

                sqlParams.Add(new SqlParameter("@FAC_ID", facId));
                sqlParams.Add(new SqlParameter("@INV_NO", invNo));

                string sqlUpdate = "UPDATE INV_DATA SET " + string.Join(", ", setClauses.ToArray()) + " WHERE FAC_ID = @FAC_ID AND INV_NO = @INV_NO";
                DbHelper.ExecuteNonQuery(sqlUpdate, sqlParams.ToArray());
            }

            // 3. 處理照片實體圖檔儲存
            if (postData.ContainsKey("Photos"))
            {
                var photos = postData["Photos"] as Dictionary<string, object>;
                if (photos != null && photos.Count > 0)
                {
                    string picDirRel = "~/Upload/PIC/" + facId + "/" + invNo;
                    string picDirPhy = HttpContext.Current.Server.MapPath(picDirRel);
                    if (!Directory.Exists(picDirPhy))
                    {
                        Directory.CreateDirectory(picDirPhy);
                    }

                    foreach (var pKvp in photos)
                    {
                        string photoKey = pKvp.Key;
                        string base64Str = pKvp.Value != null ? pKvp.Value.ToString() : "";
                        if (string.IsNullOrEmpty(base64Str) || !base64Str.Contains("base64,"))
                        {
                            continue;
                        }

                        try
                        {
                            string rawBase64 = base64Str.Substring(base64Str.IndexOf("base64,") + 7);
                            byte[] imgBytes = Convert.FromBase64String(rawBase64);
                            string savePath = Path.Combine(picDirPhy, photoKey + ".jpg");
                            File.WriteAllBytes(savePath, imgBytes);
                        }
                        catch
                        {
                        }
                    }
                }
            }

            // 4. 處理電子手寫簽名檔儲存
            if (postData.ContainsKey("Signatures"))
            {
                var sigs = postData["Signatures"] as Dictionary<string, object>;
                if (sigs != null && sigs.Count > 0)
                {
                    string picDirRel = "~/Upload/PIC/" + facId + "/" + invNo;
                    string picDirPhy = HttpContext.Current.Server.MapPath(picDirRel);
                    if (!Directory.Exists(picDirPhy))
                    {
                        Directory.CreateDirectory(picDirPhy);
                    }

                    foreach (var sKvp in sigs)
                    {
                        string sigName = sKvp.Key;
                        string base64Str = sKvp.Value != null ? sKvp.Value.ToString() : "";
                        if (string.IsNullOrEmpty(base64Str) || !base64Str.Contains("base64,"))
                        {
                            continue;
                        }

                        try
                        {
                            string rawBase64 = base64Str.Substring(base64Str.IndexOf("base64,") + 7);
                            byte[] imgBytes = Convert.FromBase64String(rawBase64);
                            string savePath = Path.Combine(picDirPhy, sigName + ".png");
                            File.WriteAllBytes(savePath, imgBytes);
                        }
                        catch
                        {
                        }
                    }
                }
            }

            string token = ("MD5:" + facId + DateTime.Now.ToString("yyyyMMddHH")).ToMD5();
            string redirectUrl = "CaseList.aspx?defid=" + facId + "&defid1=" + token;

            Response.Write(json.Serialize(new
            {
                Success = true,
                Message = "巡查查核紀錄已成功儲存！",
                InvNo = invNo,
                FacId = facId,
                RedirectUrl = redirectUrl
            }));
        }
        #endregion

        #region 4. TWD97 轉 WGS84 座標轉換演算法
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
