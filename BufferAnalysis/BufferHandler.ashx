<%@ WebHandler Language="C#" Class="NTPC_FEC.BufferAnalysis.BufferHandler" %>
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Text;
using System.Web;
using System.Web.Script.Serialization;
using NTPC_FEC.Helpers;

namespace NTPC_FEC.BufferAnalysis
{
    /// <summary>
    /// 環域分析核心 API 處理常式 (智慧動態欄位適配，符合 C# 5.0 規範與無 CDN 資安原則)
    /// </summary>
    public class BufferHandler : IHttpHandler
    {
        private JavaScriptSerializer json;

        public BufferHandler()
        {
            json = new JavaScriptSerializer();
            json.MaxJsonLength = int.MaxValue;
        }

        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json; charset=utf-8";
            string action = context.Request["action"];
            if (string.IsNullOrEmpty(action))
            {
                context.Response.Write(json.Serialize(new { Success = false, Message = "未提供操作指令 (action)" }));
                return;
            }

            try
            {
                string act = action.ToLower();
                if (act == "getinit")
                {
                    GetInitData(context);
                }
                else if (act == "searchtarget")
                {
                    SearchTarget(context);
                }
                else if (act == "querybuffer")
                {
                    QueryBuffer(context);
                }
                else if (act == "getpanolist")
                {
                    GetPanoList(context);
                }
                else if (act == "debug")
                {
                    GetDebugInfo(context);
                }
                else if (act == "getfacprofile")
                {
                    GetFacProfile(context);
                }
                else
                {
                    context.Response.Write(json.Serialize(new { Success = false, Message = "未知的操作指令：" + action }));
                }
            }
            catch (Exception ex)
            {
                context.Response.Write(json.Serialize(new 
                { 
                    Success = false, 
                    Message = "系統處理異常：" + ex.Message,
                    Detail = ex.ToString()
                }));
            }
        }

        #region 資料表結構動態探測 (Schema Auto-Detection)
        private static bool _schemaDetected = false;
        private static readonly object _schemaLock = new object();

        // FAC_Main 欄位對應
        private static bool _facTableExists = false;
        private static string _facXCol = "";
        private static string _facYCol = "";
        private static string _facAddrCol = "ADDR";
        private static string _facTownCol = "TOWN";
        private static string _facTypeCol = "FAC_Type";
        private static string _facIndCol = "";
        private static bool _facHasTownCode = false;

        // 行業主檔快取 (INDUSTRIAL_Data)
        private static Dictionary<string, string> _indMapCache = null;
        private static DateTime _lastIndLoad = DateTime.MinValue;
        private static readonly object _indLock = new object();

        private static Dictionary<string, string> GetIndustryMap()
        {
            lock (_indLock)
            {
                if (_indMapCache != null && (DateTime.Now - _lastIndLoad).TotalMinutes < 30)
                {
                    return _indMapCache;
                }

                var map = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
                try
                {
                    string sql = "SELECT INDUSTRIAL_Code, INDUSTRIAL_Name FROM INDUSTRIAL_Data";
                    DataTable dt = DbHelper.ExecuteDataTable(sql);
                    if (dt != null)
                    {
                        foreach (DataRow r in dt.Rows)
                        {
                            string code = r["INDUSTRIAL_Code"] != DBNull.Value ? r["INDUSTRIAL_Code"].ToString().Trim() : "";
                            string name = r["INDUSTRIAL_Name"] != DBNull.Value ? r["INDUSTRIAL_Name"].ToString().Trim() : "";
                            if (!string.IsNullOrEmpty(code) && !map.ContainsKey(code))
                            {
                                map[code] = name;
                            }
                        }
                    }
                }
                catch { }

                _indMapCache = map;
                _lastIndLoad = DateTime.Now;
                return _indMapCache;
            }
        }

        // Bare_Main 欄位對應
        private static bool _bareTableExists = false;
        private static string _bareLatCol = "";
        private static string _bareLngCol = "";
        private static string _bareNoCol = "BareGroundNo";
        private static string _bareAddrCol = "ADDR";
        private static string _bareLandUseCol = "Land_USE";

        private static void DetectSchema()
        {
            if (_schemaDetected) return;
            lock (_schemaLock)
            {
                if (_schemaDetected) return;

                // 1. 探測 FAC_Main
                try
                {
                    string sqlFacCols = "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'FAC_Main'";
                    DataTable dtFac = DbHelper.ExecuteDataTable(sqlFacCols);
                    if (dtFac != null && dtFac.Rows.Count > 0)
                    {
                        _facTableExists = true;
                        var colSet = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                        foreach (DataRow r in dtFac.Rows)
                        {
                            colSet.Add(r["COLUMN_NAME"].ToString().Trim());
                        }

                        // X 座標欄位優先序
                        if (colSet.Contains("TWD97_X")) _facXCol = "TWD97_X";
                        else if (colSet.Contains("X")) _facXCol = "X";
                        else if (colSet.Contains("COORD_X")) _facXCol = "COORD_X";
                        else if (colSet.Contains("PX")) _facXCol = "PX";

                        // Y 座標欄位優先序
                        if (colSet.Contains("TWD97_Y")) _facYCol = "TWD97_Y";
                        else if (colSet.Contains("Y")) _facYCol = "Y";
                        else if (colSet.Contains("COORD_Y")) _facYCol = "COORD_Y";
                        else if (colSet.Contains("PY")) _facYCol = "PY";

                        // 地址欄位
                        if (colSet.Contains("ADDR")) _facAddrCol = "ADDR";
                        else if (colSet.Contains("FAC_ADDR")) _facAddrCol = "FAC_ADDR";
                        else if (colSet.Contains("FAC_ADDRESS")) _facAddrCol = "FAC_ADDRESS";

                        // 鄉鎮欄位
                        if (colSet.Contains("TOWN")) _facTownCol = "TOWN";
                        else if (colSet.Contains("TOWN_NAME")) _facTownCol = "TOWN_NAME";
                        _facHasTownCode = colSet.Contains("TOWN_CODE");

                        // 類型欄位
                        if (colSet.Contains("FAC_Type")) _facTypeCol = "FAC_Type";
                        else if (colSet.Contains("FAC_TYPE")) _facTypeCol = "FAC_TYPE";

                        // 行業別代碼欄位
                        if (colSet.Contains("INDUSTRIAL_Code1")) _facIndCol = "INDUSTRIAL_Code1";
                        else if (colSet.Contains("INDUSTRIAL_Code")) _facIndCol = "INDUSTRIAL_Code";
                        else if (colSet.Contains("IND_NO")) _facIndCol = "IND_NO";
                    }
                }
                catch { }

                // 2. 探測 Bare_Main
                try
                {
                    string sqlBareCols = "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Bare_Main'";
                    DataTable dtBare = DbHelper.ExecuteDataTable(sqlBareCols);
                    if (dtBare != null && dtBare.Rows.Count > 0)
                    {
                        _bareTableExists = true;
                        var bcolSet = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                        foreach (DataRow r in dtBare.Rows)
                        {
                            bcolSet.Add(r["COLUMN_NAME"].ToString().Trim());
                        }

                        if (bcolSet.Contains("Latitude")) _bareLatCol = "Latitude";
                        else if (bcolSet.Contains("LAT")) _bareLatCol = "LAT";

                        if (bcolSet.Contains("Longtitude")) _bareLngCol = "Longtitude";
                        else if (bcolSet.Contains("Longitude")) _bareLngCol = "Longitude";
                        else if (bcolSet.Contains("LNG")) _bareLngCol = "LNG";

                        if (bcolSet.Contains("BareGroundNo")) _bareNoCol = "BareGroundNo";
                        else if (bcolSet.Contains("BARE_NO")) _bareNoCol = "BARE_NO";

                        if (bcolSet.Contains("ADDR")) _bareAddrCol = "ADDR";
                        else if (bcolSet.Contains("Bare_ADDR")) _bareAddrCol = "Bare_ADDR";

                        if (bcolSet.Contains("Land_USE")) _bareLandUseCol = "Land_USE";
                        else if (bcolSet.Contains("LAND_USE")) _bareLandUseCol = "LAND_USE";
                    }
                }
                catch { }

                _schemaDetected = true;
            }
        }
        #endregion

        #region 1. 取得初始化資料 (行政區列表與預設配置)
        private void GetInitData(HttpContext context)
        {
            List<Dictionary<string, object>> towns = GetTownList();
            context.Response.Write(json.Serialize(new
            {
                Success = true,
                Center = new { Lat = 25.0116, Lng = 121.4658, Zoom = 13 },
                Towns = towns,
                Layers = new string[] { "fac", "bare", "pano" },
                DefaultRadius = 500
            }));
        }

        private List<Dictionary<string, object>> GetTownList()
        {
            var list = new List<Dictionary<string, object>>();
            // 嚴格鎖定新北市行政區 (新北市 COUNTRY = 'F')
            string sql = "SELECT TOWN_NO, TOWN_NA FROM C_TOWN WHERE COUNTRY = 'F' ORDER BY TOWN_NO";
            try
            {
                DataTable dt = DbHelper.ExecuteDataTable(sql);
                if (dt != null && dt.Rows.Count > 0)
                {
                    foreach (DataRow r in dt.Rows)
                    {
                        string no = r["TOWN_NO"].ToString().Trim();
                        string name = r["TOWN_NA"].ToString().Trim();
                        double lat, lng;
                        GetTownCenterCoord(name, out lat, out lng);
                        var d = new Dictionary<string, object>();
                        d["no"] = no;
                        d["name"] = name;
                        d["lat"] = lat;
                        d["lng"] = lng;
                        list.Add(d);
                    }
                }
            }
            catch
            {
                list = GetFallbackTowns();
            }
            if (list.Count == 0) list = GetFallbackTowns();
            return list;
        }

        private void GetTownCenterCoord(string townName, out double lat, out double lng)
        {
            lat = 25.0116; lng = 121.4658;
            if (string.IsNullOrEmpty(townName)) return;
            if (townName.Contains("板橋")) { lat = 25.0116; lng = 121.4658; }
            else if (townName.Contains("三重")) { lat = 25.0685; lng = 121.4937; }
            else if (townName.Contains("中和")) { lat = 24.9989; lng = 121.5002; }
            else if (townName.Contains("永和")) { lat = 25.0104; lng = 121.5165; }
            else if (townName.Contains("新莊")) { lat = 25.0360; lng = 121.4502; }
            else if (townName.Contains("新店")) { lat = 24.9681; lng = 121.5417; }
            else if (townName.Contains("土城")) { lat = 24.9723; lng = 121.4437; }
            else if (townName.Contains("蘆洲")) { lat = 25.0849; lng = 121.4728; }
            else if (townName.Contains("樹林")) { lat = 24.9912; lng = 121.4243; }
            else if (townName.Contains("汐止")) { lat = 25.0630; lng = 121.6425; }
            else if (townName.Contains("鶯歌")) { lat = 24.9547; lng = 121.3547; }
            else if (townName.Contains("三峽")) { lat = 24.9342; lng = 121.3712; }
            else if (townName.Contains("淡水")) { lat = 25.1755; lng = 121.4428; }
            else if (townName.Contains("瑞芳")) { lat = 25.1089; lng = 121.8105; }
            else if (townName.Contains("五股")) { lat = 25.0829; lng = 121.4385; }
            else if (townName.Contains("泰山")) { lat = 25.0592; lng = 121.4284; }
            else if (townName.Contains("林口")) { lat = 25.0782; lng = 121.3917; }
            else if (townName.Contains("深坑")) { lat = 25.0016; lng = 121.6158; }
            else if (townName.Contains("石碇")) { lat = 24.9919; lng = 121.6582; }
            else if (townName.Contains("坪林")) { lat = 24.9378; lng = 121.7115; }
            else if (townName.Contains("三芝")) { lat = 25.2582; lng = 121.5009; }
            else if (townName.Contains("石門")) { lat = 25.2905; lng = 121.5684; }
            else if (townName.Contains("八里")) { lat = 25.1472; lng = 121.3982; }
            else if (townName.Contains("平溪")) { lat = 25.0256; lng = 121.7387; }
            else if (townName.Contains("雙溪")) { lat = 25.0347; lng = 121.8654; }
            else if (townName.Contains("貢寮")) { lat = 25.0222; lng = 121.9085; }
            else if (townName.Contains("金山")) { lat = 25.2217; lng = 121.6402; }
            else if (townName.Contains("萬里")) { lat = 25.1784; lng = 121.6889; }
            else if (townName.Contains("烏來")) { lat = 24.8654; lng = 121.5508; }
        }

        private List<Dictionary<string, object>> GetFallbackTowns()
        {
            var list = new List<Dictionary<string, object>>();
            string[] names = new string[] { "板橋區", "三重區", "中和區", "永和區", "新莊區", "新店區", "土城區", "蘆洲區", "樹林區", "汐止區", "鶯歌區", "三峽區", "淡水區", "瑞芳區", "五股區", "泰山區", "林口區", "深坑區", "石碇區", "坪林區", "三芝區", "石門區", "八里區", "平溪區", "雙溪區", "貢寮區", "金山區", "萬里區", "烏來區" };
            for (int i = 0; i < names.Length; i++)
            {
                double lat, lng;
                GetTownCenterCoord(names[i], out lat, out lng);
                var d = new Dictionary<string, object>();
                d["no"] = (i + 1).ToString();
                d["name"] = names[i];
                d["lat"] = lat;
                d["lng"] = lng;
                list.Add(d);
            }
            return list;
        }
        #endregion

        #region 2. 搜尋中心點目標 (關鍵字模糊反查)
        private void SearchTarget(HttpContext context)
        {
            DetectSchema();
            string query = context.Request["q"];
            if (string.IsNullOrEmpty(query))
            {
                context.Response.Write(json.Serialize(new { Success = false, Message = "請輸入搜尋關鍵字" }));
                return;
            }
            query = query.Trim();

            var results = new List<Dictionary<string, object>>();

            // 1. 搜尋固定源工廠
            if (_facTableExists && !string.IsNullOrEmpty(_facXCol) && !string.IsNullOrEmpty(_facYCol))
            {
                try
                {
                    string sqlFac = string.Format(@"
                        SELECT TOP 20 
                            FAC_ID, FAC_NAME, C_NO, 
                            {0} AS ADDR, 
                            {1} AS X, 
                            {2} AS Y
                        FROM FAC_Main
                        WHERE (FAC_NAME LIKE @Q OR C_NO LIKE @Q OR {0} LIKE @Q)
                          AND ({1} > 0 AND {2} > 0)
                        ORDER BY FAC_ID ASC",
                        _facAddrCol, _facXCol, _facYCol);

                    DataTable dtFac = DbHelper.ExecuteDataTable(sqlFac, new SqlParameter("@Q", "%" + query + "%"));
                    if (dtFac != null)
                    {
                        foreach (DataRow r in dtFac.Rows)
                        {
                            double x = Convert.ToDouble(r["X"]);
                            double y = Convert.ToDouble(r["Y"]);
                            double lat = 0, lng = 0;
                            ConvertToWgs84(x, y, out lat, out lng);

                            if (lat > 0 && lng > 0)
                            {
                                var d = new Dictionary<string, object>();
                                d["id"] = r["FAC_ID"].ToString().Trim();
                                d["name"] = r["FAC_NAME"].ToString().Trim();
                                d["cno"] = r["C_NO"].ToString().Trim();
                                d["type"] = "工廠場所";
                                d["addr"] = r["ADDR"] != DBNull.Value ? r["ADDR"].ToString().Trim() : "";
                                d["lat"] = Math.Round(lat, 6);
                                d["lng"] = Math.Round(lng, 6);
                                results.Add(d);
                            }
                        }
                    }
                }
                catch { }
            }

            // 2. 搜尋裸露地
            if (_bareTableExists && !string.IsNullOrEmpty(_bareLatCol) && !string.IsNullOrEmpty(_bareLngCol))
            {
                try
                {
                    string sqlBare = string.Format(@"
                        SELECT TOP 10 Bare_ID, {0} AS BareGroundNo, {1} AS ADDR, {2} AS Latitude, {3} AS Longtitude
                        FROM Bare_Main
                        WHERE ({0} LIKE @Q OR {1} LIKE @Q)
                          AND {2} > 0 AND {3} > 0
                        ORDER BY Bare_ID DESC",
                        _bareNoCol, _bareAddrCol, _bareLatCol, _bareLngCol);

                    DataTable dtBare = DbHelper.ExecuteDataTable(sqlBare, new SqlParameter("@Q", "%" + query + "%"));
                    if (dtBare != null)
                    {
                        foreach (DataRow r in dtBare.Rows)
                        {
                            double lat = Convert.ToDouble(r["Latitude"]);
                            double lng = Convert.ToDouble(r["Longtitude"]);
                            GeoCoordHelper.NormalizeWgs84(ref lat, ref lng);
                            var d = new Dictionary<string, object>();
                            d["id"] = r["Bare_ID"].ToString().Trim();
                            d["name"] = "裸露地 " + r["BareGroundNo"].ToString().Trim();
                            d["cno"] = "";
                            d["type"] = "裸露地";
                            d["addr"] = r["ADDR"] != DBNull.Value ? r["ADDR"].ToString().Trim() : "";
                            d["lat"] = Math.Round(lat, 6);
                            d["lng"] = Math.Round(lng, 6);
                            results.Add(d);
                        }
                    }
                }
                catch { }
            }

            context.Response.Write(json.Serialize(new
            {
                Success = true,
                Count = results.Count,
                Data = results
            }));
        }
        #endregion

        #region 3. 核心環域空間分析運算 (QueryBuffer)
        private void QueryBuffer(HttpContext context)
        {
            DetectSchema();

            double lat = 0, lng = 0, radius = 500;
            double.TryParse(context.Request["lat"], out lat);
            double.TryParse(context.Request["lng"], out lng);
            double.TryParse(context.Request["radius"], out radius);
            string layerFilter = context.Request["layers"];
            if (string.IsNullOrEmpty(layerFilter)) layerFilter = "fac,bare,pano";

            if (lat <= 0 || lng <= 0)
            {
                context.Response.Write(json.Serialize(new { Success = false, Message = "無效的中心點經緯度坐標" }));
                return;
            }
            if (radius <= 0) radius = 500;
            if (radius > 10000) radius = 10000;

            // 換算中心點為 TWD97 米制坐標
            double userX = 0, userY = 0;
            GeoCoordHelper.Wgs84ToTwd97(lat, lng, out userX, out userY);

            // 取得目前 360 環景快取清單
            Dictionary<string, PanoItem> panoCache = GetPanoIndexCache(context);

            var items = new List<Dictionary<string, object>>();
            int facCount = 0;
            int bareCount = 0;
            int panoCount = 0;
            string facErrMsg = "";
            string bareErrMsg = "";

            // 取得行業別主檔對應字典 (INDUSTRIAL_Data)
            Dictionary<string, string> indMap = GetIndustryMap();

            // A. 查詢工廠 (固定源)
            if (layerFilter.Contains("fac") && _facTableExists && !string.IsNullOrEmpty(_facXCol) && !string.IsNullOrEmpty(_facYCol))
            {
                try
                {
                    DataTable dtFac = null;
                    bool spExecuted = false;

                    // 1. 優先嘗試系統內建 SP (Get_New_FAC_Main_ByCood)
                    try
                    {
                        using (var conn = DbHelper.GetOpenConnection())
                        using (var cmd = new SqlCommand("Get_New_FAC_Main_ByCood", conn))
                        {
                            cmd.CommandType = CommandType.StoredProcedure;
                            cmd.CommandTimeout = 30;
                            cmd.Parameters.AddWithValue("@Where_X", (float)userX);
                            cmd.Parameters.AddWithValue("@Where_Y", (float)userY);
                            cmd.Parameters.AddWithValue("@Where_Show_IN_INV", DBNull.Value);

                            using (var da = new SqlDataAdapter(cmd))
                            {
                                dtFac = new DataTable();
                                da.Fill(dtFac);
                                spExecuted = true;
                            }
                        }
                    }
                    catch
                    {
                        spExecuted = false;
                    }

                    // 2. 若 SP 未執行或無回傳，則使用動態欄位適配的直角坐標範圍運算
                    if (!spExecuted || dtFac == null || dtFac.Rows.Count == 0)
                    {
                        string indColSql = !string.IsNullOrEmpty(_facIndCol) ? _facIndCol : "''";
                        string sqlFac = string.Format(@"
                            SELECT TOP 500 
                                FAC_ID, FAC_NAME, C_NO, 
                                {0} AS ADDR, 
                                {1} AS FAC_Type,
                                {2} AS X, 
                                {3} AS Y,
                                {4} AS IndCode,
                                ROUND(SQRT(SQUARE({2} - @UserX) + SQUARE({3} - @UserY)), 1) AS DistMeters
                            FROM FAC_Main
                            WHERE ({2} BETWEEN (@UserX - @Radius) AND (@UserX + @Radius))
                              AND ({3} BETWEEN (@UserY - @Radius) AND (@UserY + @Radius))
                              AND (SQUARE({2} - @UserX) + SQUARE({3} - @UserY)) <= SQUARE(@Radius)
                            ORDER BY DistMeters ASC",
                            _facAddrCol, _facTypeCol, _facXCol, _facYCol, indColSql);

                        SqlParameter[] paras = new SqlParameter[]
                        {
                            new SqlParameter("@UserX", userX),
                            new SqlParameter("@UserY", userY),
                            new SqlParameter("@Radius", radius)
                        };

                        dtFac = DbHelper.ExecuteDataTable(sqlFac, paras);
                    }

                    if (dtFac != null)
                    {
                        foreach (DataRow r in dtFac.Rows)
                        {
                            double fx = 0, fy = 0;
                            if (r.Table.Columns.Contains("X") && r["X"] != DBNull.Value)
                            {
                                double.TryParse(r["X"].ToString(), out fx);
                            }
                            else if (r.Table.Columns.Contains(_facXCol) && r[_facXCol] != DBNull.Value)
                            {
                                double.TryParse(r[_facXCol].ToString(), out fx);
                            }

                            if (r.Table.Columns.Contains("Y") && r["Y"] != DBNull.Value)
                            {
                                double.TryParse(r["Y"].ToString(), out fy);
                            }
                            else if (r.Table.Columns.Contains(_facYCol) && r[_facYCol] != DBNull.Value)
                            {
                                double.TryParse(r[_facYCol].ToString(), out fy);
                            }

                            if (fx <= 0 || fy <= 0) continue;

                            // 計算距離
                            double dist = 0;
                            if (r.Table.Columns.Contains("DistMeters") && r["DistMeters"] != DBNull.Value)
                            {
                                dist = Convert.ToDouble(r["DistMeters"]);
                            }
                            else
                            {
                                dist = Math.Round(Math.Sqrt(Math.Pow(fx - userX, 2) + Math.Pow(fy - userY, 2)), 1);
                            }

                            // 若超過半徑則略過
                            if (dist > radius) continue;

                            double flat = 0, flng = 0;
                            ConvertToWgs84(fx, fy, out flat, out flng);

                            string facName = r.Table.Columns.Contains("FAC_NAME") ? r["FAC_NAME"].ToString().Trim() : "";
                            string facId = r.Table.Columns.Contains("FAC_ID") ? r["FAC_ID"].ToString().Trim() : "";
                            string cNo = r.Table.Columns.Contains("C_NO") ? r["C_NO"].ToString().Trim() : "";
                            string addr = r.Table.Columns.Contains("ADDR") ? r["ADDR"].ToString().Trim() : "";
                            string fType = r.Table.Columns.Contains("FAC_Type") ? r["FAC_Type"].ToString().Trim() : "列管";

                            // 行業別名稱判讀
                            string indCode = "";
                            if (r.Table.Columns.Contains("IndCode") && r["IndCode"] != DBNull.Value) indCode = r["IndCode"].ToString().Trim();
                            else if (r.Table.Columns.Contains("INDUSTRIAL_Code1") && r["INDUSTRIAL_Code1"] != DBNull.Value) indCode = r["INDUSTRIAL_Code1"].ToString().Trim();

                            string indName = "";
                            if (!string.IsNullOrEmpty(indCode) && indMap.ContainsKey(indCode))
                            {
                                indName = indMap[indCode];
                            }
                            else if (!string.IsNullOrEmpty(fType) && fType != "列管" && fType != "工廠")
                            {
                                indName = fType;
                            }
                            else
                            {
                                indName = "其他未分類工廠";
                            }

                            facCount++;

                            // 匹配 360 環景
                            bool hasPano = false;
                            string panoUrl = "";
                            PanoItem matchedPano = MatchPano(facName, facId, cNo, panoCache);
                            if (matchedPano != null)
                            {
                                hasPano = true;
                                panoUrl = matchedPano.Url;
                                panoCount++;
                            }

                            var d = new Dictionary<string, object>();
                            d["id"] = facId;
                            d["name"] = facName;
                            d["cno"] = cNo;
                            d["type"] = "工廠場所";
                            d["typeKey"] = "fac";
                            d["facType"] = fType;
                            d["industry"] = indName;
                            d["industryCode"] = indCode;
                            d["addr"] = addr;
                            d["dist"] = dist;
                            d["lat"] = Math.Round(flat, 6);
                            d["lng"] = Math.Round(flng, 6);
                            d["hasPano"] = hasPano;
                            d["panoUrl"] = panoUrl;
                            items.Add(d);
                        }
                    }
                }
                catch (Exception ex)
                {
                    facErrMsg = ex.Message;
                }
            }

            // B. 查詢裸露地
            if (layerFilter.Contains("bare") && _bareTableExists && !string.IsNullOrEmpty(_bareLatCol) && !string.IsNullOrEmpty(_bareLngCol))
            {
                try
                {
                    double degBuffer = (radius * 1.3) / 100000.0;
                    string sqlBare = string.Format(@"
                        SELECT TOP 100 
                            Bare_ID, 
                            {0} AS BareGroundNo, 
                            {1} AS ADDR, 
                            {2} AS Land_USE, 
                            {3} AS Latitude, 
                            {4} AS Longtitude
                        FROM Bare_Main
                        WHERE {3} BETWEEN (@Lat - @Deg) AND (@Lat + @Deg)
                          AND {4} BETWEEN (@Lng - @Deg) AND (@Lng + @Deg)
                          AND {3} > 0 AND {4} > 0",
                        _bareNoCol, _bareAddrCol, _bareLandUseCol, _bareLatCol, _bareLngCol);

                    SqlParameter[] parasBare = new SqlParameter[]
                    {
                        new SqlParameter("@Lat", lat),
                        new SqlParameter("@Lng", lng),
                        new SqlParameter("@Deg", degBuffer)
                    };

                    DataTable dtBare = DbHelper.ExecuteDataTable(sqlBare, parasBare);
                    if (dtBare != null)
                    {
                        foreach (DataRow r in dtBare.Rows)
                        {
                            double blat = Convert.ToDouble(r["Latitude"]);
                            double blng = Convert.ToDouble(r["Longtitude"]);
                            GeoCoordHelper.NormalizeWgs84(ref blat, ref blng);

                            double bx = 0, by = 0;
                            GeoCoordHelper.Wgs84ToTwd97(blat, blng, out bx, out by);
                            double dist = Math.Round(Math.Sqrt(Math.Pow(bx - userX, 2) + Math.Pow(by - userY, 2)), 1);

                            if (dist <= radius)
                            {
                                bareCount++;
                                string bName = "裸露地 " + r["BareGroundNo"].ToString().Trim();
                                string bId = r["Bare_ID"].ToString().Trim();
                                string bAddr = r["ADDR"] != DBNull.Value ? r["ADDR"].ToString().Trim() : "";
                                string bLandUse = r["Land_USE"] != DBNull.Value ? r["Land_USE"].ToString().Trim() : "";

                                bool hasPano = false;
                                string panoUrl = "";
                                PanoItem matchedPano = MatchPano(bName, bId, "", panoCache);
                                if (matchedPano != null)
                                {
                                    hasPano = true;
                                    panoUrl = matchedPano.Url;
                                    panoCount++;
                                }

                                var d = new Dictionary<string, object>();
                                d["id"] = bId;
                                d["name"] = bName;
                                d["cno"] = "";
                                d["type"] = "裸露地";
                                d["typeKey"] = "bare";
                                d["facType"] = bLandUse;
                                d["industry"] = "裸露地" + (!string.IsNullOrEmpty(bLandUse) ? " (" + bLandUse + ")" : "");
                                d["industryCode"] = "BARE";
                                d["addr"] = bAddr;
                                d["dist"] = dist;
                                d["lat"] = Math.Round(blat, 6);
                                d["lng"] = Math.Round(blng, 6);
                                d["hasPano"] = hasPano;
                                d["panoUrl"] = panoUrl;
                                items.Add(d);
                            }
                        }
                    }
                }
                catch (Exception ex)
                {
                    bareErrMsg = ex.Message;
                }
            }

            // C. 查詢 360 環景點位 (若勾選 pano，納入半徑內的所有 360 環景場所)
            if (layerFilter.Contains("pano"))
            {
                foreach (KeyValuePair<string, PanoItem> kv in panoCache)
                {
                    PanoItem p = kv.Value;
                    if (p.Lat <= 0 || p.Lng <= 0) continue;

                    // 計算與中心點之直線距離 (公尺)
                    double px = 0, py = 0;
                    GeoCoordHelper.Wgs84ToTwd97(p.Lat, p.Lng, out px, out py);
                    double pdist = Math.Round(Math.Sqrt(Math.Pow(px - userX, 2) + Math.Pow(py - userY, 2)), 1);

                    if (pdist <= radius)
                    {
                        // 檢查是否已在清單中
                        bool alreadyInList = false;
                        foreach (var it in items)
                        {
                            if (it.ContainsKey("name") && (it["name"].ToString().IndexOf(p.Title, StringComparison.OrdinalIgnoreCase) >= 0 || p.Title.IndexOf(it["name"].ToString(), StringComparison.OrdinalIgnoreCase) >= 0))
                            {
                                alreadyInList = true;
                                break;
                            }
                        }

                        if (!alreadyInList)
                        {
                            panoCount++;
                            var d = new Dictionary<string, object>();
                            d["id"] = p.Id;
                            d["name"] = p.Title;
                            d["cno"] = "";
                            d["type"] = "360實景";
                            d["typeKey"] = "pano";
                            d["facType"] = "3DVista實景";
                            d["industry"] = "360° 實景導覽";
                            d["industryCode"] = "PANO";
                            d["addr"] = !string.IsNullOrEmpty(p.Addr) ? p.Addr : (p.Town ?? "新北市");
                            d["dist"] = pdist;
                            d["lat"] = p.Lat;
                            d["lng"] = p.Lng;
                            d["hasPano"] = true;
                            d["panoUrl"] = p.Url;
                            items.Add(d);
                        }
                    }
                }
            }

            // 按距離升冪排序
            items.Sort(delegate (Dictionary<string, object> a, Dictionary<string, object> b)
            {
                double da = Convert.ToDouble(a["dist"]);
                double db = Convert.ToDouble(b["dist"]);
                return da.CompareTo(db);
            });

            // 統計各行業別分類筆數 (Industry Breakdown)
            var indGroupMap = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
            foreach (var it in items)
            {
                string ind = it.ContainsKey("industry") && it["industry"] != null ? it["industry"].ToString() : "其他";
                if (!indGroupMap.ContainsKey(ind)) indGroupMap[ind] = 0;
                indGroupMap[ind]++;
            }

            var indSummary = new List<Dictionary<string, object>>();
            foreach (var kv in indGroupMap)
            {
                var indObj = new Dictionary<string, object>();
                indObj["name"] = kv.Key;
                indObj["count"] = kv.Value;
                indSummary.Add(indObj);
            }
            indSummary.Sort(delegate (Dictionary<string, object> a, Dictionary<string, object> b)
            {
                int ca = Convert.ToInt32(a["count"]);
                int cb = Convert.ToInt32(b["count"]);
                return cb.CompareTo(ca);
            });

            // 回傳 JSON
            context.Response.Write(json.Serialize(new
            {
                Success = true,
                Center = new { Lat = lat, Lng = lng, Radius = radius },
                Summary = new
                {
                    Total = items.Count,
                    FacCount = facCount,
                    BareCount = bareCount,
                    PanoCount = panoCount
                },
                IndustrySummary = indSummary,
                SchemaInfo = new
                {
                    FacTable = _facTableExists,
                    FacX = _facXCol,
                    FacY = _facYCol,
                    BareTable = _bareTableExists,
                    FacError = facErrMsg,
                    BareError = bareErrMsg
                },
                Data = items
            }));
        }

        private static void ConvertToWgs84(double x, double y, out double lat, out double lng)
        {
            lat = 0; lng = 0;
            if (x <= 0 || y <= 0) return;

            // 若數值大於 10000 判定為 TWD97 投影坐標
            if (x > 10000 && y > 10000)
            {
                GeoCoordHelper.Twd97ToWgs84(x, y, out lat, out lng);
            }
            else if (x <= 180 && y <= 90)
            {
                // 若本身為 WGS84 經緯度 (X=Lng, Y=Lat)
                lng = x;
                lat = y;
            }
            else if (y <= 180 && x <= 90)
            {
                // 反向 (X=Lat, Y=Lng)
                lat = x;
                lng = y;
            }
        }
        #endregion

        #region 4. 取得所有 360 環景清單 (GetPanoList)
        private void GetPanoList(HttpContext context)
        {
            Dictionary<string, PanoItem> panoCache = GetPanoIndexCache(context);
            var list = new List<Dictionary<string, object>>();

            foreach (KeyValuePair<string, PanoItem> kv in panoCache)
            {
                PanoItem p = kv.Value;
                var d = new Dictionary<string, object>();
                d["id"] = p.Id;
                d["title"] = p.Title;
                d["folder"] = p.FolderName;
                d["url"] = p.Url;
                d["thumbUrl"] = p.ThumbUrl;
                d["town"] = !string.IsNullOrEmpty(p.Town) ? p.Town : ExtractTownFromName(p.Title);
                d["addr"] = p.Addr ?? "";
                d["lat"] = p.Lat;
                d["lng"] = p.Lng;
                list.Add(d);
            }

            // 按名稱排序
            list.Sort(delegate (Dictionary<string, object> a, Dictionary<string, object> b)
            {
                return string.Compare(a["title"].ToString(), b["title"].ToString(), StringComparison.CurrentCulture);
            });

            context.Response.Write(json.Serialize(new
            {
                Success = true,
                Count = list.Count,
                Data = list
            }));
        }
        #endregion

        #region 5. 系統與資料庫診斷端點 (Debug)
        private void GetDebugInfo(HttpContext context)
        {
            DetectSchema();
            var info = new Dictionary<string, object>();

            // 1. 資料庫連線測試
            bool dbConnected = false;
            string dbMsg = "OK";
            int totalFacCount = 0;
            int facWithCoordCount = 0;
            var sampleFacs = new List<Dictionary<string, object>>();

            try
            {
                object cntObj = DbHelper.ExecuteScalar("SELECT COUNT(*) FROM FAC_Main");
                totalFacCount = Convert.ToInt32(cntObj);
                dbConnected = true;

                if (!string.IsNullOrEmpty(_facXCol) && !string.IsNullOrEmpty(_facYCol))
                {
                    string sqlCoordCount = string.Format("SELECT COUNT(*) FROM FAC_Main WHERE {0} > 0 AND {1} > 0", _facXCol, _facYCol);
                    facWithCoordCount = Convert.ToInt32(DbHelper.ExecuteScalar(sqlCoordCount));

                    string sqlSample = string.Format("SELECT TOP 3 FAC_ID, FAC_NAME, C_NO, {0} AS ADDR, {1} AS X, {2} AS Y FROM FAC_Main WHERE {1} > 0 AND {2} > 0 ORDER BY FAC_ID ASC", _facAddrCol, _facXCol, _facYCol);
                    DataTable dtSample = DbHelper.ExecuteDataTable(sqlSample);
                    if (dtSample != null)
                    {
                        foreach (DataRow r in dtSample.Rows)
                        {
                            double x = Convert.ToDouble(r["X"]);
                            double y = Convert.ToDouble(r["Y"]);
                            double lat, lng;
                            ConvertToWgs84(x, y, out lat, out lng);

                            var s = new Dictionary<string, object>();
                            s["Id"] = r["FAC_ID"].ToString();
                            s["Name"] = r["FAC_NAME"].ToString();
                            s["RawX"] = x;
                            s["RawY"] = y;
                            s["Wgs84Lat"] = Math.Round(lat, 6);
                            s["Wgs84Lng"] = Math.Round(lng, 6);
                            sampleFacs.Add(s);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                dbConnected = false;
                dbMsg = ex.Message;
            }

            info["DbConnected"] = dbConnected;
            info["DbMessage"] = dbMsg;
            info["TotalFacCount"] = totalFacCount;
            info["FacWithCoordCount"] = facWithCoordCount;
            info["SampleFacs"] = sampleFacs;

            // 2. 欄位結構探測成果
            info["DetectedSchema"] = new
            {
                FacTableExists = _facTableExists,
                FacXCol = _facXCol,
                FacYCol = _facYCol,
                FacAddrCol = _facAddrCol,
                FacTownCol = _facTownCol,
                FacTypeCol = _facTypeCol,
                BareTableExists = _bareTableExists,
                BareLatCol = _bareLatCol,
                BareLngCol = _bareLngCol
            };

            // 3. 360 環景圖資
            Dictionary<string, PanoItem> panoCache = GetPanoIndexCache(context);
            info["PanoCount"] = panoCache.Count;

            context.Response.Write(json.Serialize(new
            {
                Success = true,
                Timestamp = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"),
                Info = info
            }));
        }
        #endregion

        #region 6. 360 環景影像實體路徑索引與匹配服務
        public class PanoItem
        {
            public string Id { get; set; }
            public string Title { get; set; }
            public string FolderName { get; set; }
            public string RelativePath { get; set; }
            public string Url { get; set; }
            public string ThumbUrl { get; set; }
            public string Town { get; set; }
            public string Addr { get; set; }
            public double Lat { get; set; }
            public double Lng { get; set; }
        }

        private static string ExtractTownFromName(string name)
        {
            if (string.IsNullOrEmpty(name)) return "";
            string[] towns = new string[] { "板橋", "三重", "中和", "永和", "新莊", "新店", "土城", "蘆洲", "樹林", "汐止", "鶯歌", "三峽", "淡水", "瑞芳", "五股", "泰山", "林口", "深坑", "石碇", "坪林", "三芝", "石門", "八里", "平溪", "雙溪", "貢寮", "金山", "萬里", "烏來" };
            foreach (string t in towns)
            {
                if (name.Contains(t)) return t + "區";
            }
            return "";
        }

        private static Dictionary<string, PanoItem> _cachedPanoIndex = null;
        private static DateTime _lastPanoScan = DateTime.MinValue;
        private static readonly object _panoLock = new object();

        private Dictionary<string, PanoItem> GetPanoIndexCache(HttpContext context)
        {
            lock (_panoLock)
            {
                // 快取 10 分鐘
                if (_cachedPanoIndex != null && (DateTime.Now - _lastPanoScan).TotalMinutes < 10)
                {
                    return _cachedPanoIndex;
                }

                _cachedPanoIndex = new Dictionary<string, PanoItem>(StringComparer.OrdinalIgnoreCase);
                _lastPanoScan = DateTime.Now;

                // 搜尋優先級：1. D:\WebData\Surroundview 2. ~/Surroundview
                string baseDir = ConfigurationManager.AppSettings["SurroundviewPhysicalPath"];
                if (string.IsNullOrEmpty(baseDir)) baseDir = @"D:\WebData\Surroundview";

                if (!Directory.Exists(baseDir))
                {
                    string localDir = context.Server.MapPath("~/Surroundview");
                    if (Directory.Exists(localDir)) baseDir = localDir;
                }

                if (!Directory.Exists(baseDir))
                {
                    return _cachedPanoIndex;
                }

                try
                {
                    // 搜尋所有含有 index.htm 的目錄
                    string[] htmlFiles = Directory.GetFiles(baseDir, "index.htm", SearchOption.AllDirectories);
                    foreach (string htm in htmlFiles)
                    {
                        string dirName = Path.GetDirectoryName(htm);
                        string folder = Path.GetFileName(dirName);
                        string rel = htm.Substring(baseDir.Length).TrimStart('\\', '/').Replace('\\', '/');

                        PanoItem item = new PanoItem();
                        item.Id = folder;
                        item.Title = folder;
                        item.FolderName = folder;
                        item.RelativePath = rel;
                        // 統一指向 IIS 虛擬目錄 /Surroundview/
                        item.Url = "../Surroundview/" + rel;
                        string thumbPath = Path.Combine(dirName, "thumbnail.png");
                        item.ThumbUrl = File.Exists(thumbPath) ? ("../Surroundview/" + rel.Replace("index.htm", "thumbnail.png")) : "";

                        // 嘗試反查座標
                        AttachCoordToPano(item);

                        _cachedPanoIndex[folder] = item;
                    }
                }
                catch
                {
                    // 靜默捕捉磁碟存取例外
                }

                return _cachedPanoIndex;
            }
        }

        private void AttachCoordToPano(PanoItem item)
        {
            if (!_facTableExists || string.IsNullOrEmpty(_facXCol) || string.IsNullOrEmpty(_facYCol)) return;
            try
            {
                string sql = string.Format(@"
                    SELECT TOP 1 
                        {0} AS X, 
                        {1} AS Y,
                        {2} AS ADDR,
                        {3} AS TOWN
                    FROM FAC_Main 
                    WHERE FAC_NAME LIKE @Name AND {0} > 0 AND {1} > 0", 
                    _facXCol, _facYCol, _facAddrCol, _facTownCol);
                DataTable dt = DbHelper.ExecuteDataTable(sql, new SqlParameter("@Name", "%" + item.Title + "%"));
                if (dt != null && dt.Rows.Count > 0)
                {
                    double x = Convert.ToDouble(dt.Rows[0]["X"]);
                    double y = Convert.ToDouble(dt.Rows[0]["Y"]);
                    double lat, lng;
                    ConvertToWgs84(x, y, out lat, out lng);
                    item.Lat = Math.Round(lat, 6);
                    item.Lng = Math.Round(lng, 6);
                    item.Addr = dt.Rows[0]["ADDR"] != DBNull.Value ? dt.Rows[0]["ADDR"].ToString().Trim() : "";
                    item.Town = dt.Rows[0]["TOWN"] != DBNull.Value ? dt.Rows[0]["TOWN"].ToString().Trim() : "";
                }
            }
            catch { }
        }

        private PanoItem MatchPano(string name, string id, string cno, Dictionary<string, PanoItem> cache)
        {
            if (cache == null || cache.Count == 0) return null;
            if (cache.ContainsKey(name)) return cache[name];
            if (!string.IsNullOrEmpty(id) && cache.ContainsKey(id)) return cache[id];
            if (!string.IsNullOrEmpty(cno) && cache.ContainsKey(cno)) return cache[cno];

            // 模糊包含比對
            foreach (KeyValuePair<string, PanoItem> kv in cache)
            {
                if (!string.IsNullOrEmpty(name) && (name.Contains(kv.Key) || kv.Key.Contains(name)))
                {
                    return kv.Value;
                }
            }
            return null;
        }
        #endregion

        public bool IsReusable
        {
            get { return true; }
        }

        #region 7. 工商廠場許可證與巡查履歷查詢 (GetFacProfile)
        private void GetFacProfile(HttpContext context)
        {
            DetectSchema();
            string facId = context.Request["facId"];
            if (string.IsNullOrEmpty(facId))
            {
                context.Response.Write(json.Serialize(new { Success = false, Message = "未提供場所代碼 (facId)" }));
                return;
            }
            facId = facId.Trim();

            var basic = new Dictionary<string, object>();
            var licenses = new List<Dictionary<string, object>>();
            var inspections = new List<Dictionary<string, object>>();

            string todayStr = DateTime.Now.ToString("yyyyMMdd");
            string token = GetMd5Hash(facId + todayStr);
            string detailUrl = string.Format("../FAC/FAC_Detail.aspx?id1={0}&id2={1}", facId, token);

            // 1. 查詢場所基本主檔
            string cNo = "";
            try
            {
                string sqlFac = string.Format(@"
                    SELECT TOP 1 
                        FAC_ID, FAC_NAME, C_NO, 
                        {0} AS ADDR, 
                        {1} AS FAC_Type,
                        TEL, BOSS_NAME, Reg_NO, Reg_NO_Str
                    FROM FAC_Main 
                    WHERE FAC_ID = @FAC_ID", _facAddrCol, _facTypeCol);

                DataTable dtFac = DbHelper.ExecuteDataTable(sqlFac, new SqlParameter("@FAC_ID", facId));
                if (dtFac != null && dtFac.Rows.Count > 0)
                {
                    DataRow r = dtFac.Rows[0];
                    basic["FacId"] = r["FAC_ID"].ToString().Trim();
                    basic["FacName"] = r["FAC_NAME"].ToString().Trim();
                    basic["CNo"] = r.Table.Columns.Contains("C_NO") ? r["C_NO"].ToString().Trim() : "";
                    cNo = basic["CNo"].ToString();
                    basic["Addr"] = r["ADDR"] != DBNull.Value ? r["ADDR"].ToString().Trim() : "";
                    basic["Tel"] = r.Table.Columns.Contains("TEL") && r["TEL"] != DBNull.Value ? r["TEL"].ToString().Trim() : "";
                    basic["BossName"] = r.Table.Columns.Contains("BOSS_NAME") && r["BOSS_NAME"] != DBNull.Value ? r["BOSS_NAME"].ToString().Trim() : "";
                    basic["FacType"] = r["FAC_Type"] != DBNull.Value ? r["FAC_Type"].ToString().Trim() : "列管";
                    basic["RegNo"] = r.Table.Columns.Contains("Reg_NO") && r["Reg_NO"] != DBNull.Value ? r["Reg_NO"].ToString().Trim() : "";
                    basic["RegNoStr"] = r.Table.Columns.Contains("Reg_NO_Str") && r["Reg_NO_Str"] != DBNull.Value ? r["Reg_NO_Str"].ToString().Trim() : "";
                    basic["DetailUrl"] = detailUrl;
                }
            }
            catch (Exception ex)
            {
                basic["Error"] = ex.Message;
            }

            // 2. 查詢許可證資料 (先查 oFAC_Process，再輔以 INV_Process_Main)
            try
            {
                if (!string.IsNullOrEmpty(cNo))
                {
                    string sqlOfac = @"
                        SELECT 
                            p.Process_ID, p.Process_Name, p.Process_Type, p.Process_Lic, 
                            p.Start_Date, p.End_Date, p.Continue_Deadline, p.Work_Deadline
                        FROM oFAC_Process p
                        INNER JOIN oFAC_Main m ON p.oFAC_ID = m.oFAC_ID
                        WHERE m.C_NO = @C_NO AND p.Unlock_DocDate IS NULL
                        ORDER BY p.End_Date DESC";

                    DataTable dtOfac = DbHelper.ExecuteDataTable(sqlOfac, new SqlParameter("@C_NO", cNo));
                    if (dtOfac != null && dtOfac.Rows.Count > 0)
                    {
                        foreach (DataRow pr in dtOfac.Rows)
                        {
                            var lic = new Dictionary<string, object>();
                            lic["ProcessId"] = pr["Process_ID"] != DBNull.Value ? pr["Process_ID"].ToString().Trim() : "";
                            lic["ProcessName"] = pr["Process_Name"] != DBNull.Value ? pr["Process_Name"].ToString().Trim() : "未載明製程";
                            lic["ProcessType"] = pr["Process_Type"] != DBNull.Value ? pr["Process_Type"].ToString().Trim() : "操作許可";
                            lic["ProcessLic"] = pr["Process_Lic"] != DBNull.Value ? pr["Process_Lic"].ToString().Trim() : "-";

                            DateTime dtStart, dtEnd, dtContinue;
                            lic["StartDate"] = DateTime.TryParse(pr["Start_Date"].ToString(), out dtStart) ? dtStart.ToString("yyyy/MM/dd") : "-";
                            lic["EndDate"] = DateTime.TryParse(pr["End_Date"].ToString(), out dtEnd) ? dtEnd.ToString("yyyy/MM/dd") : "-";
                            lic["ContinueDeadline"] = DateTime.TryParse(pr["Continue_Deadline"].ToString(), out dtContinue) ? dtContinue.ToString("yyyy/MM/dd") : "-";

                            string status = "有效";
                            if (dtEnd > DateTime.MinValue)
                            {
                                if (dtEnd < DateTime.Today) status = "已逾期";
                                else if (dtEnd <= DateTime.Today.AddMonths(6)) status = "即將到期";
                            }
                            lic["Status"] = status;
                            licenses.Add(lic);
                        }
                    }
                }

                // 若 oFAC 無資料，嘗試從 INV_Process_Main 取得許可證號
                if (licenses.Count == 0)
                {
                    string sqlInvProc = @"
                        SELECT Process_NO, Process_Code, Process_Name, Process_Type, Process_Lic, Lic_Year
                        FROM INV_Process_Main
                        WHERE FAC_ID = @FAC_ID
                        ORDER BY Process_NO";

                    DataTable dtInvProc = DbHelper.ExecuteDataTable(sqlInvProc, new SqlParameter("@FAC_ID", facId));
                    if (dtInvProc != null)
                    {
                        foreach (DataRow ipr in dtInvProc.Rows)
                        {
                            var lic = new Dictionary<string, object>();
                            lic["ProcessId"] = ipr["Process_NO"] != DBNull.Value ? ipr["Process_NO"].ToString().Trim() : "";
                            lic["ProcessName"] = ipr["Process_Name"] != DBNull.Value ? ipr["Process_Name"].ToString().Trim() : "廠區製程";
                            lic["ProcessType"] = ipr["Process_Type"] != DBNull.Value ? ipr["Process_Type"].ToString().Trim() : "固定源製程";
                            lic["ProcessLic"] = ipr["Process_Lic"] != DBNull.Value ? ipr["Process_Lic"].ToString().Trim() : "-";
                            lic["StartDate"] = "-";
                            lic["EndDate"] = "-";
                            lic["ContinueDeadline"] = "-";
                            lic["Status"] = "列管中";
                            licenses.Add(lic);
                        }
                    }
                }
            }
            catch { }

            // 3. 查詢歷次現場查核紀錄 (INV_DATA)
            try
            {
                string sqlInvs = @"
                    SELECT TOP 30 
                        i.INV_NO, i.FAC_ID, i.INV_DATE, i.INV_MEMO, i.INV_State,
                        ISNULL(s.State_Name, i.INV_State) AS State_Name
                    FROM INV_DATA i 
                    LEFT JOIN INV_State_List s ON i.INV_State = s.State_ID 
                    WHERE i.FAC_ID = @FAC_ID AND i.INV_State <> 'Z00' 
                    ORDER BY i.INV_DATE DESC, i.INV_NO DESC";

                DataTable dtInvs = DbHelper.ExecuteDataTable(sqlInvs, new SqlParameter("@FAC_ID", facId));
                if (dtInvs != null)
                {
                    foreach (DataRow ir in dtInvs.Rows)
                    {
                        var invItem = new Dictionary<string, object>();
                        int invNo = 0;
                        int.TryParse(ir["INV_NO"].ToString(), out invNo);
                        invItem["InvNo"] = invNo;

                        DateTime invDate;
                        invItem["InvDate"] = DateTime.TryParse(ir["INV_DATE"].ToString(), out invDate) ? invDate.ToString("yyyy/MM/dd HH:mm") : ir["INV_DATE"].ToString();
                        invItem["StateName"] = ir["State_Name"] != DBNull.Value ? ir["State_Name"].ToString().Trim() : "已查核";
                        invItem["Memo"] = ir["INV_MEMO"] != DBNull.Value ? ir["INV_MEMO"].ToString().Trim() : "無特別備註";

                        string state = ir["INV_State"] != DBNull.Value ? ir["INV_State"].ToString().Trim() : "";
                        string badgeClass = "badge-success";
                        string resultText = "符合規範";
                        if (state == "A00a" || state == "A00b")
                        {
                            badgeClass = "badge-warning";
                            resultText = "暫存/退件";
                        }
                        else if (state.Contains("D") || ir["INV_MEMO"].ToString().Contains("缺失") || ir["INV_MEMO"].ToString().Contains("改善"))
                        {
                            badgeClass = "badge-danger";
                            resultText = "列管/待改善";
                        }
                        invItem["BadgeClass"] = badgeClass;
                        invItem["ResultText"] = resultText;

                        // 查核詳細報告連結 (帶安全 Token)
                        invItem["ReportUrl"] = string.Format("../Case/CaseResult.aspx?id1={0}&id2={1}&invno={2}", facId, token, invNo);

                        inspections.Add(invItem);
                    }
                }
            }
            catch { }

            context.Response.Write(json.Serialize(new
            {
                Success = true,
                Basic = basic,
                Licenses = licenses,
                Inspections = inspections
            }));
        }

        private static string GetMd5Hash(string input)
        {
            if (string.IsNullOrEmpty(input)) return "";
            using (System.Security.Cryptography.MD5 md5 = System.Security.Cryptography.MD5.Create())
            {
                byte[] data = md5.ComputeHash(Encoding.UTF8.GetBytes(input));
                StringBuilder sb = new StringBuilder();
                for (int i = 0; i < data.Length; i++)
                {
                    sb.Append(data[i].ToString("x2"));
                }
                return sb.ToString();
            }
        }
        #endregion
    }
}
