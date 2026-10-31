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
using System.Web.SessionState;
using NPOI.HSSF.UserModel;
using NPOI.SS.UserModel;
using NTPC_FEC.Helpers;
using NTPC_FEC.Security;
using NTPC_FEC.Services;

namespace NTPC_FEC.BufferAnalysis
{
    /// <summary>
    /// 環域分析核心 API 處理常式 (智慧動態欄位適配，符合 C# 5.0 規範與無 CDN 資安原則)
    /// </summary>
    public class BufferHandler : IHttpHandler, IRequiresSessionState
    {
        private JavaScriptSerializer json;

        public BufferHandler()
        {
            json = new JavaScriptSerializer();
            json.MaxJsonLength = int.MaxValue;
        }

        public void ProcessRequest(HttpContext context)
        {
            // 身分驗證：保護內部工廠與學校敏感空間資料，禁止未授權存取
            if (context.Session == null || context.Session["LoginUser"] == null)
            {
                if (string.Equals(context.Request["action"], "exportschooldist", StringComparison.OrdinalIgnoreCase))
                {
                    context.Response.StatusCode = 401;
                    context.Response.ContentType = "text/plain; charset=utf-8";
                    context.Response.Write("未授權存取：請先登入系統後再執行匯出操作。");
                    return;
                }
                context.Response.StatusCode = 401;
                context.Response.ContentType = "application/json; charset=utf-8";
                context.Response.Write(json.Serialize(new { Success = false, Message = "登入逾時或尚未登入，請先登入系統。", NeedLogin = true }));
                return;
            }

            string action = context.Request["action"];
            if (!string.IsNullOrEmpty(action) && action.ToLower() == "exportschooldist")
            {
                ExportSchoolDistExcel(context);
                return;
            }

            context.Response.ContentType = "application/json; charset=utf-8";
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
                else if (act == "getschoollist")
                {
                    GetSchoolList(context);
                }
                else if (act == "nearestschools")
                {
                    GetNearestSchools(context);
                }
                else if (act == "syncschoolsdb")
                {
                    SyncSchoolsToDb(context);
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
            List<SchoolItem> schools = GetSchoolListCache(context);
            context.Response.Write(json.Serialize(new
            {
                Success = true,
                Center = new { Lat = 25.0116, Lng = 121.4658, Zoom = 13 },
                Towns = towns,
                Layers = new string[] { "fac", "bare", "pano", "school" },
                DefaultRadius = 500,
                MonthList = GetCachedMonthList(context),
                SchoolTotalCount = schools != null ? schools.Count : 0
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

            // 3. 搜尋各級學校 (含幼兒園、國小、國中、高中職、大專校院)
            try
            {
                List<SchoolItem> schools = GetSchoolListCache(context);
                if (schools != null)
                {
                    int matchedSchoolCount = 0;
                    foreach (SchoolItem s in schools)
                    {
                        if ((s.Name != null && s.Name.IndexOf(query, StringComparison.OrdinalIgnoreCase) >= 0) ||
                            (s.Alias != null && s.Alias.IndexOf(query, StringComparison.OrdinalIgnoreCase) >= 0) ||
                            (s.Addr != null && s.Addr.IndexOf(query, StringComparison.OrdinalIgnoreCase) >= 0))
                        {
                            var d = new Dictionary<string, object>();
                            d["id"] = s.Id;
                            d["name"] = s.Name;
                            d["cno"] = s.Level;
                            d["type"] = "學校 (" + s.Level + ")";
                            d["addr"] = s.Addr;
                            d["lat"] = s.Lat;
                            d["lng"] = s.Lng;
                            results.Add(d);
                            matchedSchoolCount++;
                            if (matchedSchoolCount >= 15) break;
                        }
                    }
                }
            }
            catch { }

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
            if (string.IsNullOrEmpty(layerFilter)) layerFilter = "fac,bare,pano,school";

            double priorityDist = 300;
            if (!string.IsNullOrEmpty(context.Request["priorityDist"]))
            {
                double.TryParse(context.Request["priorityDist"], out priorityDist);
            }
            if (priorityDist <= 0) priorityDist = 300;

            string schoolLevelsFilter = context.Request["schoolLevels"];

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

            // 取得目前 360 環景與各級學校快取清單
            Dictionary<string, PanoItem> panoCache = GetPanoIndexCache(context);
            List<SchoolItem> schoolCache = GetSchoolListCache(context);

            var items = new List<Dictionary<string, object>>();
            int facCount = 0;
            int bareCount = 0;
            int panoCount = 0;
            int schoolCount = 0;
            int priorityFacCount = 0;
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
                            string panoMonth = "";
                            string panoMonthText = "";
                            List<PanoHistoryVersion> panoHistory = null;
                            PanoItem matchedPano = MatchPano(facName, facId, cNo, panoCache);
                            if (matchedPano != null)
                            {
                                hasPano = true;
                                panoUrl = matchedPano.Url;
                                panoMonth = matchedPano.Month;
                                panoMonthText = matchedPano.MonthText;
                                panoHistory = matchedPano.History;
                                panoCount++;
                            }

                            // 計算距離最近的新北市各級學校 (點到點 TWD97 直線距離)
                            double facTwdX = fx, facTwdY = fy;
                            if (fx <= 10000 || fy <= 10000)
                            {
                                GeoCoordHelper.Wgs84ToTwd97(flat, flng, out facTwdX, out facTwdY);
                            }

                            double nearestSchoolDist = -1;
                            SchoolItem nearestSchool = FindNearestSchool(facTwdX, facTwdY, schoolCache, schoolLevelsFilter, out nearestSchoolDist);
                            bool isPriorityFac = (nearestSchool != null && nearestSchoolDist >= 0 && nearestSchoolDist <= priorityDist);
                            if (isPriorityFac)
                            {
                                priorityFacCount++;
                            }
                            string schoolRiskLevel = "normal";
                            if (nearestSchool != null && nearestSchoolDist >= 0)
                            {
                                if (nearestSchoolDist <= 100) schoolRiskLevel = "danger";
                                else if (nearestSchoolDist <= priorityDist) schoolRiskLevel = "warning";
                                else if (nearestSchoolDist <= 500) schoolRiskLevel = "info";
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
                            d["panoMonth"] = panoMonth;
                            d["panoMonthText"] = panoMonthText;
                            d["panoHistory"] = panoHistory;
                            d["isPriorityFac"] = isPriorityFac;
                            d["schoolRiskLevel"] = schoolRiskLevel;
                            d["nearestSchoolId"] = nearestSchool != null ? nearestSchool.Id : "";
                            d["nearestSchoolName"] = nearestSchool != null ? nearestSchool.Name : "";
                            d["nearestSchoolLevel"] = nearestSchool != null ? (nearestSchool.Level + (nearestSchool.HasKindergarten && nearestSchool.Level != "幼兒園" ? "(含附幼)" : "")) : "";
                            d["nearestSchoolDist"] = nearestSchool != null ? nearestSchoolDist : -1;
                            d["nearestSchoolLat"] = nearestSchool != null ? nearestSchool.Lat : 0;
                            d["nearestSchoolLng"] = nearestSchool != null ? nearestSchool.Lng : 0;
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
                                string panoMonth = "";
                                string panoMonthText = "";
                                List<PanoHistoryVersion> panoHistory = null;
                                PanoItem matchedPano = MatchPano(bName, bId, "", panoCache);
                                if (matchedPano != null)
                                {
                                    hasPano = true;
                                    panoUrl = matchedPano.Url;
                                    panoMonth = matchedPano.Month;
                                    panoMonthText = matchedPano.MonthText;
                                    panoHistory = matchedPano.History;
                                    panoCount++;
                                }

                                double nearestSchoolDist = -1;
                                SchoolItem nearestSchool = FindNearestSchool(bx, by, schoolCache, schoolLevelsFilter, out nearestSchoolDist);

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
                                d["panoMonth"] = panoMonth;
                                d["panoMonthText"] = panoMonthText;
                                d["panoHistory"] = panoHistory;
                                d["isPriorityFac"] = false;
                                d["schoolRiskLevel"] = nearestSchool != null && nearestSchoolDist <= priorityDist ? "warning" : "normal";
                                d["nearestSchoolName"] = nearestSchool != null ? nearestSchool.Name : "";
                                d["nearestSchoolLevel"] = nearestSchool != null ? nearestSchool.Level : "";
                                d["nearestSchoolDist"] = nearestSchool != null ? nearestSchoolDist : -1;
                                d["nearestSchoolLat"] = nearestSchool != null ? nearestSchool.Lat : 0;
                                d["nearestSchoolLng"] = nearestSchool != null ? nearestSchool.Lng : 0;
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
                            d["panoMonth"] = p.Month;
                            d["panoMonthText"] = p.MonthText;
                            d["panoHistory"] = p.History;
                            items.Add(d);
                        }
                    }
                }
            }

            // D. 查詢各級學校 (含幼兒園、國小、國中、高中職、大專校院)
            if (layerFilter.Contains("school") && schoolCache != null)
            {
                foreach (SchoolItem s in schoolCache)
                {
                    if (!MatchSchoolLevelFilter(s, schoolLevelsFilter)) continue;

                    double sdist = Math.Round(Math.Sqrt(Math.Pow(s.X - userX, 2) + Math.Pow(s.Y - userY, 2)), 1);
                    if (sdist <= radius)
                    {
                        schoolCount++;
                        string levelLabel = s.Level + (s.HasKindergarten && s.Level != "幼兒園" ? " (含附幼)" : "");
                        var d = new Dictionary<string, object>();
                        d["id"] = "SCH_" + s.Id;
                        d["schoolId"] = s.Id;
                        d["name"] = s.Name;
                        d["alias"] = s.Alias;
                        d["cno"] = s.PublicPrivate + " · " + levelLabel;
                        d["type"] = s.Level;
                        d["typeKey"] = "school";
                        d["facType"] = levelLabel;
                        d["schoolLevel"] = s.Level;
                        d["hasKindergarten"] = s.HasKindergarten;
                        d["publicPrivate"] = s.PublicPrivate;
                        d["phone"] = s.Phone;
                        d["url"] = s.Url;
                        d["industry"] = "各級學校 — " + s.Level;
                        d["industryCode"] = "SCHOOL_" + s.Level;
                        d["addr"] = s.Addr;
                        d["dist"] = sdist;
                        d["lat"] = s.Lat;
                        d["lng"] = s.Lng;
                        d["hasPano"] = false;
                        d["panoUrl"] = "";
                        items.Add(d);
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
                    PanoCount = panoCount,
                    SchoolCount = schoolCount,
                    PriorityFacCount = priorityFacCount
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
            string filterMonth = context.Request["month"];
            var list = new List<Dictionary<string, object>>();

            foreach (KeyValuePair<string, PanoItem> kv in panoCache)
            {
                PanoItem p = kv.Value;

                // 若前端傳遞特定月份篩選
                if (!string.IsNullOrEmpty(filterMonth))
                {
                    if (p.Month != filterMonth)
                    {
                        // 檢查歷史期程中是否有符合的
                        bool hasHistoryMonth = false;
                        if (p.History != null)
                        {
                            foreach (var h in p.History)
                            {
                                if (h.Month == filterMonth) { hasHistoryMonth = true; break; }
                            }
                        }
                        if (!hasHistoryMonth) continue;
                    }
                }

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
                d["month"] = p.Month;
                d["monthText"] = p.MonthText;
                d["history"] = p.History;
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
                MonthList = GetCachedMonthList(context),
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

            // 3. 360 環景圖資与各級學校圖資
            Dictionary<string, PanoItem> panoCache = GetPanoIndexCache(context);
            info["PanoCount"] = panoCache.Count;
            List<SchoolItem> schoolCache = GetSchoolListCache(context);
            info["SchoolCount"] = schoolCache != null ? schoolCache.Count : 0;

            context.Response.Write(json.Serialize(new
            {
                Success = true,
                Timestamp = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"),
                Info = info
            }));
        }
        #endregion

        #region 6. 360 環景影像實體路徑索引與匹配服務
        public class PanoHistoryVersion
        {
            public string Month { get; set; }
            public string MonthText { get; set; }
            public string Url { get; set; }
            public string ThumbUrl { get; set; }
            public string RelativePath { get; set; }
        }

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
            public string Month { get; set; }
            public string MonthText { get; set; }
            public List<PanoHistoryVersion> History { get; set; }

            public PanoItem()
            {
                History = new List<PanoHistoryVersion>();
            }
        }

        private static string FormatMinguoMonth(string m)
        {
            if (string.IsNullOrEmpty(m)) return "預設期程";
            m = m.Trim();
            int val = 0;
            if (m.Length >= 4 && int.TryParse(m, out val))
            {
                string year = m.Substring(0, m.Length - 2);
                string month = m.Substring(m.Length - 2);
                return year + "年" + month + "月";
            }
            return m;
        }

        private static int CompareMonth(string m1, string m2)
        {
            if (string.IsNullOrEmpty(m1) && string.IsNullOrEmpty(m2)) return 0;
            if (string.IsNullOrEmpty(m1)) return -1;
            if (string.IsNullOrEmpty(m2)) return 1;
            int v1 = 0, v2 = 0;
            if (int.TryParse(m1, out v1) && int.TryParse(m2, out v2))
            {
                return v1.CompareTo(v2);
            }
            return string.Compare(m1, m2, StringComparison.OrdinalIgnoreCase);
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
        private static List<Dictionary<string, object>> _cachedMonthList = null;
        private static DateTime _lastPanoScan = DateTime.MinValue;
        private static readonly object _panoLock = new object();

        private List<Dictionary<string, object>> GetCachedMonthList(HttpContext context)
        {
            if (_cachedPanoIndex == null || (DateTime.Now - _lastPanoScan).TotalMinutes >= 10)
            {
                GetPanoIndexCache(context);
            }
            return _cachedMonthList != null ? _cachedMonthList : new List<Dictionary<string, object>>();
        }

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
                _cachedMonthList = new List<Dictionary<string, object>>();
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
                    // 統計各月份出現頻率
                    Dictionary<string, int> monthCountMap = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);

                    // 搜尋所有含有 index.htm 的目錄
                    string[] htmlFiles = Directory.GetFiles(baseDir, "index.htm", SearchOption.AllDirectories);
                    foreach (string htm in htmlFiles)
                    {
                        string dirName = Path.GetDirectoryName(htm);
                        string rel = htm.Substring(baseDir.Length).TrimStart('\\', '/').Replace('\\', '/');
                        string[] parts = rel.Split('/');

                        string month = "";
                        string folder = "";

                        if (parts.Length >= 2)
                        {
                            // 判斷第 1 層是否為民國月份代碼 (4~6 碼純數字，如 11402, 11504)
                            string firstPart = parts[0].Trim();
                            int parsedVal = 0;
                            if (firstPart.Length >= 4 && firstPart.Length <= 6 && int.TryParse(firstPart, out parsedVal))
                            {
                                month = firstPart;
                                folder = parts[1].Trim();
                            }
                            else
                            {
                                folder = firstPart;
                            }
                        }
                        else
                        {
                            folder = Path.GetFileName(dirName);
                        }

                        if (string.IsNullOrEmpty(folder))
                        {
                            folder = Path.GetFileName(dirName);
                        }

                        string monthText = FormatMinguoMonth(month);
                        string url = "../Surroundview/" + rel;
                        string thumbPath = Path.Combine(dirName, "thumbnail.png");
                        string thumbUrl = File.Exists(thumbPath) ? ("../Surroundview/" + rel.Replace("index.htm", "thumbnail.png")) : "";

                        // 統計月份
                        if (!string.IsNullOrEmpty(month))
                        {
                            if (!monthCountMap.ContainsKey(month)) monthCountMap[month] = 0;
                            monthCountMap[month]++;
                        }

                        // 合併至同一場所
                        if (!_cachedPanoIndex.ContainsKey(folder))
                        {
                            PanoItem item = new PanoItem();
                            item.Id = folder;
                            item.Title = folder;
                            item.FolderName = folder;
                            item.RelativePath = rel;
                            item.Url = url;
                            item.ThumbUrl = thumbUrl;
                            item.Month = month;
                            item.MonthText = monthText;
                            AttachCoordToPano(item);
                            _cachedPanoIndex[folder] = item;
                        }
                        else
                        {
                            PanoItem existing = _cachedPanoIndex[folder];
                            // 比較月份大小：若新掃描的月份更新，原項目降入 History，由新月份擔任預設主版本
                            if (CompareMonth(month, existing.Month) > 0)
                            {
                                if (!string.IsNullOrEmpty(existing.Month) || !string.IsNullOrEmpty(existing.Url))
                                {
                                    PanoHistoryVersion oldVer = new PanoHistoryVersion();
                                    oldVer.Month = existing.Month;
                                    oldVer.MonthText = existing.MonthText;
                                    oldVer.Url = existing.Url;
                                    oldVer.ThumbUrl = existing.ThumbUrl;
                                    oldVer.RelativePath = existing.RelativePath;
                                    existing.History.Add(oldVer);
                                }

                                existing.Month = month;
                                existing.MonthText = monthText;
                                existing.Url = url;
                                existing.ThumbUrl = thumbUrl;
                                existing.RelativePath = rel;
                            }
                            else
                            {
                                // 較舊的期程，直接作為歷史版本加入
                                PanoHistoryVersion oldVer = new PanoHistoryVersion();
                                oldVer.Month = month;
                                oldVer.MonthText = monthText;
                                oldVer.Url = url;
                                oldVer.ThumbUrl = thumbUrl;
                                oldVer.RelativePath = rel;
                                existing.History.Add(oldVer);
                            }
                        }
                    }

                    // 對每個場所的 History 依月份降冪排序 (較新的在前面)
                    foreach (KeyValuePair<string, PanoItem> kv in _cachedPanoIndex)
                    {
                        if (kv.Value.History != null && kv.Value.History.Count > 1)
                        {
                            kv.Value.History.Sort(delegate (PanoHistoryVersion a, PanoHistoryVersion b)
                            {
                                return CompareMonth(b.Month, a.Month);
                            });
                        }
                    }

                    // 彙整並降冪排序月份列表
                    var sortedMonths = new List<string>(monthCountMap.Keys);
                    sortedMonths.Sort(delegate (string a, string b)
                    {
                        return CompareMonth(b, a);
                    });

                    for (int i = 0; i < sortedMonths.Count; i++)
                    {
                        string m = sortedMonths[i];
                        var mDict = new Dictionary<string, object>();
                        mDict["value"] = m;
                        string mText = FormatMinguoMonth(m);
                        if (i == 0) mText += " (最新)";
                        mDict["text"] = mText;
                        mDict["count"] = monthCountMap[m];
                        _cachedMonthList.Add(mDict);
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

        #region 8. 新北市各級學校空間圖資、最近學校距離運算與重點工廠 Excel 匯出
        public class SchoolItem
        {
            public string Id { get; set; }
            public string Name { get; set; }
            public string Alias { get; set; }
            public string Town { get; set; }
            public string Level { get; set; }
            public bool HasKindergarten { get; set; }
            public string PublicPrivate { get; set; }
            public string Types { get; set; }
            public string Phone { get; set; }
            public string Addr { get; set; }
            public string Url { get; set; }
            public double X { get; set; }
            public double Y { get; set; }
            public double Lat { get; set; }
            public double Lng { get; set; }
        }

        private static List<SchoolItem> _cachedSchools = null;
        private static DateTime _lastSchoolLoad = DateTime.MinValue;
        private static readonly object _schoolLock = new object();

        /// <summary>
        /// 取得新北市各級學校空間圖資快取 (雙軌載入：優先讀取 DB School_Main，若無則讀取本地 ntpc_schools.json)
        /// </summary>
        private List<SchoolItem> GetSchoolListCache(HttpContext context)
        {
            lock (_schoolLock)
            {
                if (_cachedSchools != null && _cachedSchools.Count > 0 && (DateTime.Now - _lastSchoolLoad).TotalMinutes < 30)
                {
                    return _cachedSchools;
                }

                List<SchoolItem> list = new List<SchoolItem>();

                // 1. 嘗試從資料庫 School_Main 讀取
                try
                {
                    object tblObj = DbHelper.ExecuteScalar("SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'School_Main'");
                    if (tblObj != null && Convert.ToInt32(tblObj) > 0)
                    {
                        DataTable dt = DbHelper.ExecuteDataTable("SELECT School_ID, School_Name, School_Alias, Town_Name, School_Level, Has_Kindergarten, Public_Private, School_Types, Phone, Addr, Url, TWD97_X, TWD97_Y, WGS84_Lat, WGS84_Lng FROM School_Main WHERE TWD97_X > 0 AND TWD97_Y > 0");
                        if (dt != null && dt.Rows.Count > 0)
                        {
                            foreach (DataRow r in dt.Rows)
                            {
                                SchoolItem s = new SchoolItem();
                                s.Id = r["School_ID"] != DBNull.Value ? r["School_ID"].ToString().Trim() : "";
                                s.Name = r["School_Name"] != DBNull.Value ? r["School_Name"].ToString().Trim() : "";
                                s.Alias = r["School_Alias"] != DBNull.Value ? r["School_Alias"].ToString().Trim() : s.Name;
                                s.Town = r["Town_Name"] != DBNull.Value ? r["Town_Name"].ToString().Trim() : "";
                                s.Level = r["School_Level"] != DBNull.Value ? r["School_Level"].ToString().Trim() : "國小";
                                s.HasKindergarten = r["Has_Kindergarten"] != DBNull.Value && Convert.ToBoolean(r["Has_Kindergarten"]);
                                s.PublicPrivate = r["Public_Private"] != DBNull.Value ? r["Public_Private"].ToString().Trim() : "";
                                s.Types = r["School_Types"] != DBNull.Value ? r["School_Types"].ToString().Trim() : "";
                                s.Phone = r["Phone"] != DBNull.Value ? r["Phone"].ToString().Trim() : "";
                                s.Addr = r["Addr"] != DBNull.Value ? r["Addr"].ToString().Trim() : "";
                                s.Url = r["Url"] != DBNull.Value ? r["Url"].ToString().Trim() : "";
                                s.X = r["TWD97_X"] != DBNull.Value ? Convert.ToDouble(r["TWD97_X"]) : 0;
                                s.Y = r["TWD97_Y"] != DBNull.Value ? Convert.ToDouble(r["TWD97_Y"]) : 0;
                                s.Lat = r["WGS84_Lat"] != DBNull.Value ? Convert.ToDouble(r["WGS84_Lat"]) : 0;
                                s.Lng = r["WGS84_Lng"] != DBNull.Value ? Convert.ToDouble(r["WGS84_Lng"]) : 0;
                                list.Add(s);
                            }
                        }
                    }
                }
                catch
                {
                    // DB 無此表或連線異常時，自動 Fallback 至本地 JSON 圖資檔
                }

                // 2. 若 DB 尚未建立或無資料，讀取本地靜態圖資 ~/BufferAnalysis/Data/ntpc_schools.json
                if (list.Count == 0 && context != null)
                {
                    try
                    {
                        string jsonPath = context.Server.MapPath("~/BufferAnalysis/Data/ntpc_schools.json");
                        if (File.Exists(jsonPath))
                        {
                            string rawJson = File.ReadAllText(jsonPath, Encoding.UTF8);
                            List<SchoolItem> parsed = json.Deserialize<List<SchoolItem>>(rawJson);
                            if (parsed != null)
                            {
                                list = parsed;
                            }
                        }
                    }
                    catch { }
                }

                _cachedSchools = list;
                _lastSchoolLoad = DateTime.Now;
                return _cachedSchools;
            }
        }

        /// <summary>
        /// 判斷學校是否符合前端勾選之學制篩選 (含國小/國中附設幼兒園智慧判定)
        /// </summary>
        private static bool MatchSchoolLevelFilter(SchoolItem s, string levelFilter)
        {
            if (s == null) return false;
            if (string.IsNullOrEmpty(levelFilter)) return true;

            // 若篩選包含該校主學制
            if (levelFilter.IndexOf(s.Level, StringComparison.OrdinalIgnoreCase) >= 0) return true;

            // 若篩選包含「幼兒園」且該校設有附幼 (HasKindergarten = true)
            if (s.HasKindergarten && levelFilter.IndexOf("幼兒園", StringComparison.OrdinalIgnoreCase) >= 0) return true;

            return false;
        }

        /// <summary>
        /// 點到點 TWD97 二度分帶直線距離運算：尋找距離工廠/裸露地最近之學校
        /// </summary>
        private static SchoolItem FindNearestSchool(double x, double y, List<SchoolItem> schools, string levelFilter, out double minDist)
        {
            minDist = -1;
            if (schools == null || schools.Count == 0 || x <= 0 || y <= 0) return null;

            SchoolItem nearest = null;
            double bestDistSq = double.MaxValue;

            for (int i = 0; i < schools.Count; i++)
            {
                SchoolItem s = schools[i];
                if (!MatchSchoolLevelFilter(s, levelFilter)) continue;

                double dx = s.X - x;
                double dy = s.Y - y;
                double distSq = dx * dx + dy * dy;
                if (distSq < bestDistSq)
                {
                    bestDistSq = distSq;
                    nearest = s;
                }
            }

            if (nearest != null)
            {
                minDist = Math.Round(Math.Sqrt(bestDistSq), 1);
            }
            return nearest;
        }

        /// <summary>
        /// 尋找距離工廠最近的前 2 所學校 (供 Excel 報表完整呈現最近與次近學校)
        /// </summary>
        private static void FindTop2NearestSchools(double x, double y, List<SchoolItem> schools, string levelFilter, out SchoolItem firstSchool, out double firstDist, out SchoolItem secondSchool, out double secondDist)
        {
            firstSchool = null;
            firstDist = -1;
            secondSchool = null;
            secondDist = -1;

            if (schools == null || schools.Count == 0 || x <= 0 || y <= 0) return;

            double best1Sq = double.MaxValue;
            double best2Sq = double.MaxValue;

            for (int i = 0; i < schools.Count; i++)
            {
                SchoolItem s = schools[i];
                if (!MatchSchoolLevelFilter(s, levelFilter)) continue;

                double dx = s.X - x;
                double dy = s.Y - y;
                double distSq = dx * dx + dy * dy;

                if (distSq < best1Sq)
                {
                    best2Sq = best1Sq;
                    secondSchool = firstSchool;
                    best1Sq = distSq;
                    firstSchool = s;
                }
                else if (distSq < best2Sq)
                {
                    best2Sq = distSq;
                    secondSchool = s;
                }
            }

            if (firstSchool != null) firstDist = Math.Round(Math.Sqrt(best1Sq), 1);
            if (secondSchool != null) secondDist = Math.Round(Math.Sqrt(best2Sq), 1);
        }

        /// <summary>
        /// 取得新北市各級學校清單與學制統計 (action=getschoollist)
        /// </summary>
        private void GetSchoolList(HttpContext context)
        {
            List<SchoolItem> schools = GetSchoolListCache(context);
            string townFilter = context.Request["town"];
            string levelFilter = context.Request["level"];

            var filtered = new List<SchoolItem>();
            var levelCounts = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
            levelCounts["幼兒園"] = 0;
            levelCounts["國小"] = 0;
            levelCounts["國中"] = 0;
            levelCounts["高中職"] = 0;
            levelCounts["大專校院"] = 0;

            foreach (SchoolItem s in schools)
            {
                if (!string.IsNullOrEmpty(townFilter) && !string.Equals(s.Town, townFilter.Trim(), StringComparison.OrdinalIgnoreCase))
                {
                    continue;
                }

                if (levelCounts.ContainsKey(s.Level))
                {
                    levelCounts[s.Level]++;
                }
                if (s.HasKindergarten && s.Level != "幼兒園")
                {
                    levelCounts["幼兒園"]++;
                }

                if (!MatchSchoolLevelFilter(s, levelFilter)) continue;
                filtered.Add(s);
            }

            context.Response.Write(json.Serialize(new
            {
                Success = true,
                Count = filtered.Count,
                LevelCounts = levelCounts,
                Data = filtered
            }));
        }

        /// <summary>
        /// 查詢指定座標點周邊最近的前 N 所學校 (action=nearestschools)
        /// </summary>
        private void GetNearestSchools(HttpContext context)
        {
            double lat = 25.0123;
            double lng = 121.4657;
            int top = 5;
            double.TryParse(context.Request["lat"], out lat);
            double.TryParse(context.Request["lng"], out lng);
            int.TryParse(context.Request["top"], out top);
            if (top <= 0 || top > 50) top = 5;

            string levelFilter = context.Request["schoolLevels"];

            double targetX, targetY;
            GeoCoordHelper.Wgs84ToTwd97(lat, lng, out targetX, out targetY);

            List<SchoolItem> schools = GetSchoolListCache(context);
            var candidates = new List<Dictionary<string, object>>();

            foreach (SchoolItem s in schools)
            {
                if (!MatchSchoolLevelFilter(s, levelFilter)) continue;
                double dist = Math.Round(Math.Sqrt(Math.Pow(s.X - targetX, 2) + Math.Pow(s.Y - targetY, 2)), 1);
                var d = new Dictionary<string, object>();
                d["id"] = s.Id;
                d["name"] = s.Name;
                d["alias"] = s.Alias;
                d["town"] = s.Town;
                d["level"] = s.Level + (s.HasKindergarten && s.Level != "幼兒園" ? " (含附幼)" : "");
                d["publicPrivate"] = s.PublicPrivate;
                d["addr"] = s.Addr;
                d["phone"] = s.Phone;
                d["lat"] = s.Lat;
                d["lng"] = s.Lng;
                d["dist"] = dist;
                candidates.Add(d);
            }

            candidates.Sort(delegate (Dictionary<string, object> a, Dictionary<string, object> b)
            {
                return Convert.ToDouble(a["dist"]).CompareTo(Convert.ToDouble(b["dist"]));
            });

            if (candidates.Count > top)
            {
                candidates = candidates.GetRange(0, top);
            }

            context.Response.Write(json.Serialize(new
            {
                Success = true,
                Data = candidates
            }));
        }

        /// <summary>
        /// 一鍵將本地 ntpc_schools.json 504 所學校同步建表寫入 SQL Server School_Main 資料表 (action=syncschoolsdb)
        /// </summary>
        private void SyncSchoolsToDb(HttpContext context)
        {
            string jsonPath = context.Server.MapPath("~/BufferAnalysis/Data/ntpc_schools.json");
            if (!File.Exists(jsonPath))
            {
                context.Response.Write(json.Serialize(new { Success = false, Message = "找不到本地學校圖資檔案 (ntpc_schools.json)" }));
                return;
            }

            string rawJson = File.ReadAllText(jsonPath, Encoding.UTF8);
            List<SchoolItem> schools = json.Deserialize<List<SchoolItem>>(rawJson);
            if (schools == null || schools.Count == 0)
            {
                context.Response.Write(json.Serialize(new { Success = false, Message = "解析學校圖資 JSON 失敗或筆數為 0" }));
                return;
            }

            string sqlCreateTable = @"
                IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'School_Main')
                BEGIN
                    CREATE TABLE School_Main (
                        School_ID NVARCHAR(32) NOT NULL PRIMARY KEY,
                        School_Name NVARCHAR(150) NOT NULL,
                        School_Alias NVARCHAR(100) NULL,
                        Town_Name NVARCHAR(30) NULL,
                        School_Level NVARCHAR(30) NULL,
                        Has_Kindergarten BIT NOT NULL DEFAULT 0,
                        Public_Private NVARCHAR(20) NULL,
                        School_Types NVARCHAR(200) NULL,
                        Phone NVARCHAR(60) NULL,
                        Addr NVARCHAR(250) NULL,
                        Url NVARCHAR(300) NULL,
                        TWD97_X FLOAT NOT NULL DEFAULT 0,
                        TWD97_Y FLOAT NOT NULL DEFAULT 0,
                        WGS84_Lat FLOAT NOT NULL DEFAULT 0,
                        WGS84_Lng FLOAT NOT NULL DEFAULT 0,
                        Updated_At DATETIME NOT NULL DEFAULT GETDATE()
                    );
                END";

            // 權責檢查：系統管理員或具備環域圖資維護權責 (FAC_BUFFER_MAP) 皆可同步
            string curUser = context.Session["LoginUser"] != null ? context.Session["LoginUser"].ToString() : "";
            long lic = context.Session["LIC"] != null ? Convert.ToInt64(context.Session["LIC"]) : 0L;
            string role = context.Session["Role"] != null ? context.Session["Role"].ToString().Trim() : "";
            bool isAdmin = curUser.Equals("Admin", StringComparison.OrdinalIgnoreCase) ||
                           string.Equals(role, "Admin", StringComparison.OrdinalIgnoreCase) ||
                           string.Equals(role, "SystemAdmin", StringComparison.OrdinalIgnoreCase);

            bool hasAuth = isAdmin || PermissionService.HasPermission(curUser, lic, "FAC_BUFFER_MAP", 41);
            if (!hasAuth)
            {
                context.Response.StatusCode = 403;
                context.Response.Write(json.Serialize(new { Success = false, Message = "權限不足：您尚未取得學校空間圖資同步維護之權責。" }));
                return;
            }

            DbHelper.ExecuteNonQuery(sqlCreateTable);

            int inserted = 0;
            string sqlInsert = @"
                INSERT INTO School_Main (
                    School_ID, School_Name, School_Alias, Town_Name, School_Level,
                    Has_Kindergarten, Public_Private, School_Types, Phone, Addr, Url,
                    TWD97_X, TWD97_Y, WGS84_Lat, WGS84_Lng, Updated_At
                ) VALUES (
                    @Id, @Name, @Alias, @Town, @Level,
                    @HasK, @PubPriv, @Types, @Phone, @Addr, @Url,
                    @X, @Y, @Lat, @Lng, GETDATE()
                )";

            using (SqlConnection conn = DbHelper.GetOpenConnection())
            using (SqlTransaction trans = conn.BeginTransaction())
            {
                try
                {
                    using (SqlCommand cmdTrunc = new SqlCommand("TRUNCATE TABLE School_Main", conn, trans))
                    {
                        cmdTrunc.ExecuteNonQuery();
                    }

                    foreach (SchoolItem s in schools)
                    {
                        using (SqlCommand cmdIns = new SqlCommand(sqlInsert, conn, trans))
                        {
                            cmdIns.Parameters.Add(new SqlParameter("@Id", s.Id ?? ""));
                            cmdIns.Parameters.Add(new SqlParameter("@Name", s.Name ?? ""));
                            cmdIns.Parameters.Add(new SqlParameter("@Alias", s.Alias ?? ""));
                            cmdIns.Parameters.Add(new SqlParameter("@Town", s.Town ?? ""));
                            cmdIns.Parameters.Add(new SqlParameter("@Level", s.Level ?? ""));
                            cmdIns.Parameters.Add(new SqlParameter("@HasK", s.HasKindergarten));
                            cmdIns.Parameters.Add(new SqlParameter("@PubPriv", s.PublicPrivate ?? ""));
                            cmdIns.Parameters.Add(new SqlParameter("@Types", s.Types ?? ""));
                            cmdIns.Parameters.Add(new SqlParameter("@Phone", s.Phone ?? ""));
                            cmdIns.Parameters.Add(new SqlParameter("@Addr", s.Addr ?? ""));
                            cmdIns.Parameters.Add(new SqlParameter("@Url", s.Url ?? ""));
                            cmdIns.Parameters.Add(new SqlParameter("@X", s.X));
                            cmdIns.Parameters.Add(new SqlParameter("@Y", s.Y));
                            cmdIns.Parameters.Add(new SqlParameter("@Lat", s.Lat));
                            cmdIns.Parameters.Add(new SqlParameter("@Lng", s.Lng));
                            cmdIns.ExecuteNonQuery();
                        }
                        inserted++;
                    }

                    trans.Commit();
                }
                catch
                {
                    trans.Rollback();
                    throw;
                }
            }

            // 寫入 AuditLog 稽核日誌
            AuditLogger.Log(
                operatorUser: curUser,
                actionType: "BUFFER_SCHOOL_SYNC",
                targetUser: "School_Main",
                clientIp: context.Request.UserHostAddress,
                details: string.Format("重新同步全校名冊空間資料庫，共建立與寫入 {0} 所新北市各級學校座標", inserted),
                oldValue: null,
                newValue: inserted.ToString()
            );

            // 重新整理快取
            lock (_schoolLock)
            {
                _cachedSchools = null;
            }

            context.Response.Write(json.Serialize(new
            {
                Success = true,
                Message = string.Format("已成功建立 School_Main 資料表並同步寫入 {0} 所新北市各級學校座標！", inserted),
                Count = inserted
            }));
        }

        /// <summary>
        /// 匯出「固定逸散源距離各級學校分析清冊」Excel 報表 (action=exportschooldist)
        /// 支援：
        ///   mode=buffer : 匯出目前環域範圍內之固定逸散源與最近學校距離清冊
        ///   mode=priority_all : 匯出全新北市(或指定行政區/行業別)距離學校 <= 警戒距離之重點工廠敏感度清冊
        /// </summary>
        private void ExportSchoolDistExcel(HttpContext context)
        {
            DetectSchema();

            string mode = context.Request["mode"];
            if (string.IsNullOrEmpty(mode)) mode = "buffer";
            mode = mode.ToLower();

            double lat = 25.0123;
            double lng = 121.4657;
            double radius = 1000;
            double.TryParse(context.Request["lat"], out lat);
            double.TryParse(context.Request["lng"], out lng);
            double.TryParse(context.Request["radius"], out radius);
            if (radius <= 0) radius = 1000;
            if (radius > 50000) radius = 50000;

            string townFilter = context.Request["town"];
            string indFilter = context.Request["industry"];
            string schoolLevelsFilter = context.Request["schoolLevels"];
            bool onlyPriority = context.Request["onlyPriority"] == "1" || context.Request["onlyPriority"] == "true";

            double priorityThreshold = 300;
            if (!string.IsNullOrEmpty(context.Request["priorityThreshold"]))
            {
                double.TryParse(context.Request["priorityThreshold"], out priorityThreshold);
            }
            if (priorityThreshold <= 0) priorityThreshold = 300;

            double userX, userY;
            GeoCoordHelper.Wgs84ToTwd97(lat, lng, out userX, out userY);

            List<SchoolItem> schoolCache = GetSchoolListCache(context);
            Dictionary<string, string> indMap = GetIndustryMap();

            var rows = new List<Dictionary<string, object>>();

            if (_facTableExists && !string.IsNullOrEmpty(_facXCol) && !string.IsNullOrEmpty(_facYCol))
            {
                var sqlParams = new List<SqlParameter>();
                string whereClause = string.Format("WHERE {0} > 0 AND {1} > 0", _facXCol, _facYCol);

                if (mode == "buffer")
                {
                    whereClause += string.Format(" AND {0} BETWEEN @MinX AND @MaxX AND {1} BETWEEN @MinY AND @MaxY", _facXCol, _facYCol);
                    sqlParams.Add(new SqlParameter("@MinX", userX - radius));
                    sqlParams.Add(new SqlParameter("@MaxX", userX + radius));
                    sqlParams.Add(new SqlParameter("@MinY", userY - radius));
                    sqlParams.Add(new SqlParameter("@MaxY", userY + radius));
                }

                if (!string.IsNullOrEmpty(townFilter))
                {
                    string cleanTown = townFilter.Trim();
                    string shortTown = cleanTown.Replace("區", "");
                    if (_facHasTownCode)
                    {
                        whereClause += string.Format(@" AND (
                            {0} LIKE @Town OR {1} LIKE @Town 
                            OR TOWN_CODE IN (SELECT TOWN_CODE FROM Town_Code WHERE TOWN_NAME = @ExactTown OR TOWN_NAME = @ShortTown)
                        )", _facTownCol, _facAddrCol);
                        sqlParams.Add(new SqlParameter("@ExactTown", cleanTown));
                        sqlParams.Add(new SqlParameter("@ShortTown", shortTown));
                    }
                    else
                    {
                        whereClause += string.Format(" AND ({0} LIKE @Town OR {1} LIKE @Town)", _facTownCol, _facAddrCol);
                    }
                    sqlParams.Add(new SqlParameter("@Town", "%" + shortTown + "%"));
                }

                if (!string.IsNullOrEmpty(indFilter) && !string.IsNullOrEmpty(_facIndCol))
                {
                    whereClause += string.Format(" AND {0} = @IndCode", _facIndCol);
                    sqlParams.Add(new SqlParameter("@IndCode", indFilter.Trim()));
                }

                string indSelect = !string.IsNullOrEmpty(_facIndCol) ? _facIndCol : "''";
                string sqlFac = string.Format(@"
                    SELECT 
                        FAC_ID, FAC_NAME, C_NO,
                        {0} AS ADDR,
                        {1} AS TOWN,
                        {2} AS FAC_Type,
                        {3} AS IND_CODE,
                        {4} AS X,
                        {5} AS Y
                    FROM FAC_Main
                    {6}",
                    _facAddrCol, _facTownCol, _facTypeCol, indSelect, _facXCol, _facYCol, whereClause);

                DataTable dtFac = DbHelper.ExecuteDataTable(sqlFac, sqlParams.ToArray());
                if (dtFac != null)
                {
                    foreach (DataRow r in dtFac.Rows)
                    {
                        double x = 0, y = 0;
                        double.TryParse(r["X"].ToString(), out x);
                        double.TryParse(r["Y"].ToString(), out y);
                        if (x <= 0 || y <= 0) continue;

                        double fLat, fLng;
                        double fX = x, fY = y;
                        ConvertToWgs84(x, y, out fLat, out fLng);
                        if (x <= 180 && y <= 180)
                        {
                            GeoCoordHelper.Wgs84ToTwd97(fLat, fLng, out fX, out fY);
                        }

                        double centerDist = Math.Round(Math.Sqrt(Math.Pow(fX - userX, 2) + Math.Pow(fY - userY, 2)), 1);
                        if (mode == "buffer" && centerDist > radius) continue;

                        SchoolItem s1, s2;
                        double d1, d2;
                        FindTop2NearestSchools(fX, fY, schoolCache, schoolLevelsFilter, out s1, out d1, out s2, out d2);

                        bool isPriority = (d1 >= 0 && d1 <= priorityThreshold);
                        if ((mode == "priority_all" || onlyPriority) && !isPriority) continue;

                        string riskLabel = "一般列管 (> " + priorityThreshold.ToString("0") + "m)";
                        if (d1 >= 0 && d1 <= 100) riskLabel = "極高敏紅燈 (<= 100m)";
                        else if (isPriority) riskLabel = "重點列管橘燈 (<= " + priorityThreshold.ToString("0") + "m)";

                        string indCode = r["IND_CODE"] != DBNull.Value ? r["IND_CODE"].ToString().Trim() : "";
                        string facType = r["FAC_Type"] != DBNull.Value ? r["FAC_Type"].ToString().Trim() : "列管工廠";
                        string indName = (!string.IsNullOrEmpty(indCode) && indMap.ContainsKey(indCode)) ? indMap[indCode] : (!string.IsNullOrEmpty(facType) ? facType : "固定污染源");
                        string addr = r["ADDR"] != DBNull.Value ? r["ADDR"].ToString().Trim() : "";
                        string town = r["TOWN"] != DBNull.Value ? r["TOWN"].ToString().Trim() : "";
                        if (string.IsNullOrEmpty(town)) town = ExtractTownFromName(addr);

                        var row = new Dictionary<string, object>();
                        row["FacId"] = r["FAC_ID"].ToString().Trim();
                        row["CNo"] = r.Table.Columns.Contains("C_NO") && r["C_NO"] != DBNull.Value ? r["C_NO"].ToString().Trim() : "";
                        row["FacName"] = r["FAC_NAME"] != DBNull.Value ? r["FAC_NAME"].ToString().Trim() : "未命名場所";
                        row["Town"] = town;
                        row["Industry"] = indName;
                        row["Addr"] = addr;
                        row["CenterDist"] = centerDist;
                        row["RiskLabel"] = riskLabel;
                        row["School1Name"] = s1 != null ? s1.Name : "-";
                        row["School1Level"] = s1 != null ? (s1.Level + (s1.HasKindergarten && s1.Level != "幼兒園" ? "(含附幼)" : "")) : "-";
                        row["School1PubPriv"] = s1 != null ? s1.PublicPrivate : "-";
                        row["School1Dist"] = d1 >= 0 ? d1 : 999999;
                        row["School1Addr"] = s1 != null ? s1.Addr : "-";
                        row["School2Name"] = s2 != null ? s2.Name : "-";
                        row["School2Dist"] = d2 >= 0 ? d2 : -1;
                        row["Twd97X"] = Math.Round(fX, 1);
                        row["Twd97Y"] = Math.Round(fY, 1);
                        rows.Add(row);
                    }
                }
            }

            // 依距離最近學校升冪排序 (離學校越近排越前面)
            rows.Sort(delegate (Dictionary<string, object> a, Dictionary<string, object> b)
            {
                double da = Convert.ToDouble(a["School1Dist"]);
                double db = Convert.ToDouble(b["School1Dist"]);
                return da.CompareTo(db);
            });

            // 建立 NPOI HSSFWorkbook (.xls)
            HSSFWorkbook wb = new HSSFWorkbook();
            ISheet sheet = wb.CreateSheet("固定源距各級學校距離清冊");

            // 樣式設計
            IFont titleFont = wb.CreateFont();
            titleFont.FontName = "微軟正黑體";
            titleFont.FontHeightInPoints = 13;
            titleFont.IsBold = true;

            ICellStyle titleStyle = wb.CreateCellStyle();
            titleStyle.SetFont(titleFont);

            IFont headerFont = wb.CreateFont();
            headerFont.FontName = "微軟正黑體";
            headerFont.FontHeightInPoints = 10;
            headerFont.IsBold = true;
            headerFont.Color = IndexedColors.White.Index;

            ICellStyle headerStyle = wb.CreateCellStyle();
            headerStyle.SetFont(headerFont);
            headerStyle.FillForegroundColor = IndexedColors.DarkTeal.Index;
            headerStyle.FillPattern = FillPattern.SolidForeground;
            headerStyle.Alignment = HorizontalAlignment.Center;
            headerStyle.VerticalAlignment = VerticalAlignment.Center;
            headerStyle.BorderBottom = BorderStyle.Thin;
            headerStyle.BorderTop = BorderStyle.Thin;
            headerStyle.BorderLeft = BorderStyle.Thin;
            headerStyle.BorderRight = BorderStyle.Thin;

            IFont bodyFont = wb.CreateFont();
            bodyFont.FontName = "微軟正黑體";
            bodyFont.FontHeightInPoints = 10;

            ICellStyle normalStyle = wb.CreateCellStyle();
            normalStyle.SetFont(bodyFont);
            normalStyle.VerticalAlignment = VerticalAlignment.Center;
            normalStyle.BorderBottom = BorderStyle.Thin;
            normalStyle.BorderTop = BorderStyle.Thin;
            normalStyle.BorderLeft = BorderStyle.Thin;
            normalStyle.BorderRight = BorderStyle.Thin;

            // 高敏紅燈樣式 (<= 100m)
            ICellStyle highRiskStyle = wb.CreateCellStyle();
            highRiskStyle.CloneStyleFrom(normalStyle);
            highRiskStyle.FillForegroundColor = IndexedColors.Rose.Index;
            highRiskStyle.FillPattern = FillPattern.SolidForeground;

            // 重點列管橘黃燈樣式 (<= priorityThreshold)
            ICellStyle medRiskStyle = wb.CreateCellStyle();
            medRiskStyle.CloneStyleFrom(normalStyle);
            medRiskStyle.FillForegroundColor = IndexedColors.LightYellow.Index;
            medRiskStyle.FillPattern = FillPattern.SolidForeground;

            // 第 0 列：報表標題與篩選摘要
            IRow titleRow = sheet.CreateRow(0);
            titleRow.HeightInPoints = 26;
            ICell titleCell = titleRow.CreateCell(0);
            string scopeDesc = mode == "priority_all"
                ? string.Format("全區重點列管工廠篩選 (距學校 <= {0:0}m)", priorityThreshold)
                : string.Format("環域查詢範圍 (半徑 {0:0}m)", radius);
            if (!string.IsNullOrEmpty(townFilter)) scopeDesc += " | 行政區：" + townFilter;
            titleCell.SetCellValue(string.Format("新北市固定逸散源距離各級學校空間敏感度分析清冊 — {0} (共 {1} 筆，匯出時間：{2:yyyy/MM/dd HH:mm})", scopeDesc, rows.Count, DateTime.Now));
            titleCell.CellStyle = titleStyle;

            // 第 1 列：欄位表頭
            string[] headers = new string[] {
                "序號",
                "敏感度分級標記",
                "管制編號 (C_NO)",
                "場所代碼",
                "固定逸散源名稱",
                "行政區",
                "行業別分類",
                "工廠地址",
                "最近學校名稱",
                "最近學校學制",
                "公私立",
                "距最近學校直線距離 (m)",
                "最近學校地址",
                "次近學校名稱",
                "距次近學校距離 (m)",
                "距查詢中心距離 (m)",
                "TWD97_X",
                "TWD97_Y"
            };

            IRow headerRow = sheet.CreateRow(1);
            headerRow.HeightInPoints = 22;
            for (int c = 0; c < headers.Length; c++)
            {
                ICell cell = headerRow.CreateCell(c);
                cell.SetCellValue(headers[c]);
                cell.CellStyle = headerStyle;
            }

            // 填入資料列
            for (int i = 0; i < rows.Count; i++)
            {
                var item = rows[i];
                IRow row = sheet.CreateRow(i + 2);
                row.HeightInPoints = 20;

                double s1Dist = Convert.ToDouble(item["School1Dist"]);
                double s2Dist = Convert.ToDouble(item["School2Dist"]);

                ICellStyle rowStyle = normalStyle;
                if (s1Dist >= 0 && s1Dist <= 100) rowStyle = highRiskStyle;
                else if (s1Dist >= 0 && s1Dist <= priorityThreshold) rowStyle = medRiskStyle;

                SetCell(row, 0, (i + 1).ToString(), rowStyle);
                SetCell(row, 1, item["RiskLabel"].ToString(), rowStyle);
                SetCell(row, 2, item["CNo"].ToString(), rowStyle);
                SetCell(row, 3, item["FacId"].ToString(), rowStyle);
                SetCell(row, 4, item["FacName"].ToString(), rowStyle);
                SetCell(row, 5, item["Town"].ToString(), rowStyle);
                SetCell(row, 6, item["Industry"].ToString(), rowStyle);
                SetCell(row, 7, item["Addr"].ToString(), rowStyle);
                SetCell(row, 8, item["School1Name"].ToString(), rowStyle);
                SetCell(row, 9, item["School1Level"].ToString(), rowStyle);
                SetCell(row, 10, item["School1PubPriv"].ToString(), rowStyle);

                ICell dist1Cell = row.CreateCell(11);
                if (s1Dist < 999999) dist1Cell.SetCellValue(s1Dist);
                else dist1Cell.SetCellValue("-");
                dist1Cell.CellStyle = rowStyle;

                SetCell(row, 12, item["School1Addr"].ToString(), rowStyle);
                SetCell(row, 13, item["School2Name"].ToString(), rowStyle);

                ICell dist2Cell = row.CreateCell(14);
                if (s2Dist >= 0) dist2Cell.SetCellValue(s2Dist);
                else dist2Cell.SetCellValue("-");
                dist2Cell.CellStyle = rowStyle;

                ICell cDistCell = row.CreateCell(15);
                cDistCell.SetCellValue(Convert.ToDouble(item["CenterDist"]));
                cDistCell.CellStyle = rowStyle;

                ICell xCell = row.CreateCell(16);
                xCell.SetCellValue(Convert.ToDouble(item["Twd97X"]));
                xCell.CellStyle = rowStyle;

                ICell yCell = row.CreateCell(17);
                yCell.SetCellValue(Convert.ToDouble(item["Twd97Y"]));
                yCell.CellStyle = rowStyle;
            }

            // 設定理想欄寬
            int[] colWidths = new int[] { 8, 24, 16, 14, 32, 10, 22, 38, 28, 16, 10, 22, 36, 26, 18, 18, 14, 14 };
            for (int c = 0; c < colWidths.Length; c++)
            {
                sheet.SetColumnWidth(c, colWidths[c] * 256);
            }

            string exportFileName = string.Format("新北市固定逸散源距學校敏感度清冊_{0:yyyyMMdd_HHmm}.xls", DateTime.Now);
            ExcelExportHelper.ExportToResponse(wb, exportFileName, context.Response);
        }

        private static void SetCell(IRow row, int colIndex, string value, ICellStyle style)
        {
            ICell cell = row.CreateCell(colIndex);
            cell.SetCellValue(value ?? "");
            cell.CellStyle = style;
        }
        #endregion
    }
}
