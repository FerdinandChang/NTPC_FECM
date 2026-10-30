using System;
using System.Collections;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.SessionState;
using System.Web.UI;
using NPOI.HSSF.UserModel;
using NPOI.SS.UserModel;
using NPOI.XSSF.UserModel;
using NTPC_FEC.Helpers;
using NTPC_FEC.Models;
using NTPC_FEC.Services;

namespace NTPC_FEC.Wash
{
    /// <summary>
    /// 新北市道路洗掃路段與現場查核空間地圖頁面 (CodeBehind)
    /// 符合 C# 5.0 語法規範
    /// </summary>
    public partial class WashMap : Page
    {
        public string CurrentUserName { get; set; }
        public string CurrentUserId { get; set; }

        protected void Page_Load(object sender, EventArgs e)
        {
            UserAccount user = Session["LoginUser"] as UserAccount;
            if (user == null)
            {
                user = AuthService.GetCurrentUser(Context);
            }

            if (user != null)
            {
                CurrentUserName = user.Name ?? "";
                CurrentUserId = user.UserID ?? "";
            }
            else
            {
                CurrentUserName = "訪客";
                CurrentUserId = "";
            }
        }
    }

    /// <summary>
    /// 道路洗掃路段與查核地圖核心 API 處理常式
    /// 採用 SQL Server 正規化三表儲存架構：
    /// 1. dbo.WashMap_Factory      (列管工廠、認養分級與道路幾何主檔)
    /// 2. dbo.WashMap_MonthlyLog   (各月份洗掃日誌公里數與出勤天數表)
    /// 3. dbo.WashMap_MonthlyAudit (各月份現場抽查結果紀錄表)
    /// 支援「增量寫入模式 (onlyNewMonths)」：已存在於 SQL 的歷史舊月份自動略過不重讀，僅針對新月份寫入 SQL！
    /// 符合 C# 5.0 語法規範與無外部 CDN 資安原則
    /// </summary>
    public class WashMapHandler : IHttpHandler, IRequiresSessionState
    {
        private JavaScriptSerializer json;
        private static bool _dbInitialized = false;
        private static readonly object _dbInitLock = new object();

        public WashMapHandler()
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
                string act = action.Trim().ToLower();
                if (act == "getinit")
                {
                    GetInitData(context);
                }
                else if (act == "uploadexcel")
                {
                    UploadExcelData(context);
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

        private string GetJsonFilePath(HttpContext context)
        {
            return context.Server.MapPath("~/Wash/Data/wash_map_data.json");
        }

        #region SQL Server 正規化三表建立、自動初始化 (Seed) 與讀取

        private bool EnsureRelationalTablesAndSeed(HttpContext context)
        {
            try
            {
                if (!_dbInitialized)
                {
                    lock (_dbInitLock)
                    {
                        if (!_dbInitialized)
                        {
                            string createSql = @"
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[WashMap_Factory]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[WashMap_Factory] (
        [FacId] NVARCHAR(30) NOT NULL PRIMARY KEY,
        [FacName] NVARCHAR(150) NULL,
        [OldName] NVARCHAR(150) NULL,
        [Dist] NVARCHAR(30) NULL,
        [Addr] NVARCHAR(250) NULL,
        [Industry] NVARCHAR(150) NULL,
        [ProcessName] NVARCHAR(150) NULL,
        [IndustryGroup] NVARCHAR(50) NULL,
        [IsHighRisk] BIT NOT NULL DEFAULT(0),
        [Lat] FLOAT NOT NULL DEFAULT(0),
        [Lng] FLOAT NOT NULL DEFAULT(0),
        [CoordSrc] NVARCHAR(50) NULL,
        [WashStatus] NVARCHAR(20) NULL,
        [In183List] BIT NOT NULL DEFAULT(1),
        [AdoptLevel] NVARCHAR(20) NULL,
        [WashMethod] NVARCHAR(30) NULL,
        [WashFreq] NVARCHAR(50) NULL,
        [DirtGrade] NVARCHAR(10) NULL,
        [RoadsJson] NVARCHAR(MAX) NULL,
        [GeomJson] NVARCHAR(MAX) NULL,
        [UpdatedAt] DATETIME NOT NULL DEFAULT(GETDATE())
    );
END

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[WashMap_MonthlyLog]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[WashMap_MonthlyLog] (
        [FacId] NVARCHAR(30) NOT NULL,
        [RocYear] INT NOT NULL,
        [MonthNum] INT NOT NULL,
        [YearMonth] NVARCHAR(15) NOT NULL,
        [WashKm] FLOAT NOT NULL DEFAULT(0),
        [SweepKm] FLOAT NOT NULL DEFAULT(0),
        [WashDays] INT NOT NULL DEFAULT(0),
        [SweepDays] INT NOT NULL DEFAULT(0),
        [UpdatedAt] DATETIME NOT NULL DEFAULT(GETDATE()),
        CONSTRAINT [PK_WashMap_MonthlyLog] PRIMARY KEY CLUSTERED ([FacId] ASC, [RocYear] ASC, [MonthNum] ASC)
    );
END

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[WashMap_MonthlyAudit]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[WashMap_MonthlyAudit] (
        [FacId] NVARCHAR(30) NOT NULL,
        [RocYear] INT NOT NULL,
        [MonthNum] INT NOT NULL,
        [YearMonth] NVARCHAR(15) NOT NULL,
        [AuditDate] NVARCHAR(20) NULL,
        [HasLog] NVARCHAR(20) NULL,
        [IsQualified] NVARCHAR(20) NULL,
        [IsSelfUploaded] NVARCHAR(20) NULL,
        [UpdatedAt] DATETIME NOT NULL DEFAULT(GETDATE()),
        CONSTRAINT [PK_WashMap_MonthlyAudit] PRIMARY KEY CLUSTERED ([FacId] ASC, [RocYear] ASC, [MonthNum] ASC)
    );
END";
                            DbHelper.ExecuteNonQuery(createSql);
                            _dbInitialized = true;
                        }
                    }
                }

                // 檢查 WashMap_Factory 是否已有資料，若為 0 筆則自動從 wash_map_data.json 匯入初始種子資料
                object cntObj = DbHelper.ExecuteScalar("SELECT COUNT(1) FROM WashMap_Factory");
                int facCount = cntObj != null && cntObj != DBNull.Value ? Convert.ToInt32(cntObj) : 0;
                if (facCount == 0)
                {
                    SeedDatabaseFromJsonFile(context);
                }
                return true;
            }
            catch
            {
                return false;
            }
        }

        private void SeedDatabaseFromJsonFile(HttpContext context)
        {
            string filePath = GetJsonFilePath(context);
            if (!File.Exists(filePath)) return;

            string rawJson = File.ReadAllText(filePath, Encoding.UTF8);
            if (string.IsNullOrEmpty(rawJson)) return;

            Dictionary<string, object> root = json.Deserialize<Dictionary<string, object>>(rawJson);
            if (root == null || !root.ContainsKey("F")) return;

            ArrayList facList = root["F"] as ArrayList;
            if (facList == null) return;

            int nm = GetInt(root, "NM", 9);

            for (int i = 0; i < facList.Count; i++)
            {
                Dictionary<string, object> f = facList[i] as Dictionary<string, object>;
                if (f == null) continue;

                string facId = GetStr(f, "id").Trim().ToUpper();
                if (string.IsNullOrEmpty(facId)) continue;

                UpsertFactoryToSql(f);

                // 寫入 1~nm 月洗掃日誌
                List<double> wArr = GetDoubleList(f, "w", nm);
                List<double> sArr = GetDoubleList(f, "s", nm);
                List<int> wdArr = GetIntList(f, "wd", nm);
                List<int> sdArr = GetIntList(f, "sd", nm);

                for (int m = 0; m < nm; m++)
                {
                    double wKm = wArr[m];
                    double sKm = sArr[m];
                    int wDays = wdArr[m];
                    int sDays = sdArr[m];
                    if (wKm > 0 || sKm > 0 || wDays > 0 || sDays > 0)
                    {
                        UpsertMonthlyLogToSql(facId, 115, m + 1, wKm, sKm, wDays, sDays);
                    }
                }

                // 寫入各月份現場抽查紀錄
                List<Dictionary<string, object>> audList = GetDictList(f, "aud");
                for (int a = 0; a < audList.Count; a++)
                {
                    Dictionary<string, object> ar = audList[a];
                    string ym = GetStr(ar, "m");
                    int ry = 0, mo = 0;
                    ParseYm(ym, out ry, out mo);
                    if (ry > 0 && mo >= 1 && mo <= 12)
                    {
                        UpsertMonthlyAuditToSql(
                            facId,
                            ry,
                            mo,
                            GetStr(ar, "dt"),
                            GetStr(ar, "log"),
                            GetStr(ar, "ok"),
                            GetStr(ar, "up"));
                    }
                }
            }
        }

        private void UpsertFactoryToSql(Dictionary<string, object> f)
        {
            string facId = GetStr(f, "id").Trim().ToUpper();
            if (string.IsNullOrEmpty(facId)) return;

            Dictionary<string, object> info = GetDict(f, "info");
            string lv = info != null ? GetStr(info, "lv") : "";
            string how = info != null ? GetStr(info, "how") : "";
            string freq = info != null ? GetStr(info, "freq") : "";
            string dirt = info != null ? GetStr(info, "dirt") : "";

            string roadsJson = f.ContainsKey("r") && f["r"] != null ? json.Serialize(f["r"]) : "[]";
            string geomJson = f.ContainsKey("g") && f["g"] != null ? json.Serialize(f["g"]) : "null";

            bool hi = false;
            if (f.ContainsKey("hi") && f["hi"] != null) bool.TryParse(f["hi"].ToString(), out hi);

            bool ls = true;
            if (f.ContainsKey("ls") && f["ls"] != null) bool.TryParse(f["ls"].ToString(), out ls);

            double lat = 0.0, lng = 0.0;
            if (f.ContainsKey("la") && f["la"] != null) double.TryParse(f["la"].ToString(), NumberStyles.Any, CultureInfo.InvariantCulture, out lat);
            if (f.ContainsKey("lo") && f["lo"] != null) double.TryParse(f["lo"].ToString(), NumberStyles.Any, CultureInfo.InvariantCulture, out lng);

            string sql = @"
IF EXISTS (SELECT 1 FROM WashMap_Factory WHERE FacId = @FacId)
BEGIN
    UPDATE WashMap_Factory SET
        FacName = @FacName,
        OldName = @OldName,
        Dist = @Dist,
        Addr = @Addr,
        Industry = @Industry,
        ProcessName = @ProcessName,
        IndustryGroup = @IndustryGroup,
        IsHighRisk = @IsHighRisk,
        Lat = @Lat,
        Lng = @Lng,
        CoordSrc = @CoordSrc,
        WashStatus = @WashStatus,
        In183List = @In183List,
        AdoptLevel = @AdoptLevel,
        WashMethod = @WashMethod,
        WashFreq = @WashFreq,
        DirtGrade = @DirtGrade,
        RoadsJson = @RoadsJson,
        GeomJson = @GeomJson,
        UpdatedAt = GETDATE()
    WHERE FacId = @FacId;
END
ELSE
BEGIN
    INSERT INTO WashMap_Factory (
        FacId, FacName, OldName, Dist, Addr, Industry, ProcessName, IndustryGroup, IsHighRisk,
        Lat, Lng, CoordSrc, WashStatus, In183List, AdoptLevel, WashMethod, WashFreq, DirtGrade,
        RoadsJson, GeomJson, UpdatedAt
    ) VALUES (
        @FacId, @FacName, @OldName, @Dist, @Addr, @Industry, @ProcessName, @IndustryGroup, @IsHighRisk,
        @Lat, @Lng, @CoordSrc, @WashStatus, @In183List, @AdoptLevel, @WashMethod, @WashFreq, @DirtGrade,
        @RoadsJson, @GeomJson, GETDATE()
    );
END";
            SqlParameter[] p = new SqlParameter[]
            {
                new SqlParameter("@FacId", facId),
                new SqlParameter("@FacName", GetStr(f, "n")),
                new SqlParameter("@OldName", GetStr(f, "oldn")),
                new SqlParameter("@Dist", GetStr(f, "d")),
                new SqlParameter("@Addr", GetStr(f, "a")),
                new SqlParameter("@Industry", GetStr(f, "i")),
                new SqlParameter("@ProcessName", GetStr(f, "p")),
                new SqlParameter("@IndustryGroup", GetStr(f, "grp")),
                new SqlParameter("@IsHighRisk", hi),
                new SqlParameter("@Lat", lat),
                new SqlParameter("@Lng", lng),
                new SqlParameter("@CoordSrc", GetStr(f, "csrc")),
                new SqlParameter("@WashStatus", GetStr(f, "st")),
                new SqlParameter("@In183List", ls),
                new SqlParameter("@AdoptLevel", lv),
                new SqlParameter("@WashMethod", how),
                new SqlParameter("@WashFreq", freq),
                new SqlParameter("@DirtGrade", dirt),
                new SqlParameter("@RoadsJson", roadsJson),
                new SqlParameter("@GeomJson", geomJson)
            };
            DbHelper.ExecuteNonQuery(sql, p);
        }

        private void UpsertMonthlyLogToSql(string facId, int rocYear, int monthNum, double washKm, double sweepKm, int washDays, int sweepDays)
        {
            string ym = string.Format("{0}/{1:00}", rocYear, monthNum);
            string sql = @"
IF EXISTS (SELECT 1 FROM WashMap_MonthlyLog WHERE FacId = @FacId AND RocYear = @RocYear AND MonthNum = @MonthNum)
BEGIN
    UPDATE WashMap_MonthlyLog SET
        YearMonth = @YearMonth,
        WashKm = @WashKm,
        SweepKm = @SweepKm,
        WashDays = @WashDays,
        SweepDays = @SweepDays,
        UpdatedAt = GETDATE()
    WHERE FacId = @FacId AND RocYear = @RocYear AND MonthNum = @MonthNum;
END
ELSE
BEGIN
    INSERT INTO WashMap_MonthlyLog (FacId, RocYear, MonthNum, YearMonth, WashKm, SweepKm, WashDays, SweepDays, UpdatedAt)
    VALUES (@FacId, @RocYear, @MonthNum, @YearMonth, @WashKm, @SweepKm, @WashDays, @SweepDays, GETDATE());
END";
            SqlParameter[] p = new SqlParameter[]
            {
                new SqlParameter("@FacId", facId),
                new SqlParameter("@RocYear", rocYear),
                new SqlParameter("@MonthNum", monthNum),
                new SqlParameter("@YearMonth", ym),
                new SqlParameter("@WashKm", washKm),
                new SqlParameter("@SweepKm", sweepKm),
                new SqlParameter("@WashDays", washDays),
                new SqlParameter("@SweepDays", sweepDays)
            };
            DbHelper.ExecuteNonQuery(sql, p);
        }

        private void UpsertMonthlyAuditToSql(string facId, int rocYear, int monthNum, string auditDate, string hasLog, string isQualified, string isSelfUploaded)
        {
            string ym = string.Format("{0}/{1:00}", rocYear, monthNum);
            string sql = @"
IF EXISTS (SELECT 1 FROM WashMap_MonthlyAudit WHERE FacId = @FacId AND RocYear = @RocYear AND MonthNum = @MonthNum)
BEGIN
    UPDATE WashMap_MonthlyAudit SET
        YearMonth = @YearMonth,
        AuditDate = @AuditDate,
        HasLog = @HasLog,
        IsQualified = @IsQualified,
        IsSelfUploaded = @IsSelfUploaded,
        UpdatedAt = GETDATE()
    WHERE FacId = @FacId AND RocYear = @RocYear AND MonthNum = @MonthNum;
END
ELSE
BEGIN
    INSERT INTO WashMap_MonthlyAudit (FacId, RocYear, MonthNum, YearMonth, AuditDate, HasLog, IsQualified, IsSelfUploaded, UpdatedAt)
    VALUES (@FacId, @RocYear, @MonthNum, @YearMonth, @AuditDate, @HasLog, @IsQualified, @IsSelfUploaded, GETDATE());
END";
            SqlParameter[] p = new SqlParameter[]
            {
                new SqlParameter("@FacId", facId),
                new SqlParameter("@RocYear", rocYear),
                new SqlParameter("@MonthNum", monthNum),
                new SqlParameter("@YearMonth", ym),
                new SqlParameter("@AuditDate", auditDate ?? ""),
                new SqlParameter("@HasLog", hasLog ?? ""),
                new SqlParameter("@IsQualified", isQualified ?? ""),
                new SqlParameter("@IsSelfUploaded", isSelfUploaded ?? "")
            };
            DbHelper.ExecuteNonQuery(sql, p);
        }

        /// <summary>
        /// 從 SQL Server 三張正規化表查詢並組裝為前端圖台結構
        /// </summary>
        private Dictionary<string, object> LoadDatasetFromSql(HttpContext context)
        {
            DataTable dtFac = DbHelper.ExecuteDataTable("SELECT * FROM WashMap_Factory ORDER BY FacId");
            if (dtFac == null || dtFac.Rows.Count == 0) return null;

            DataTable dtLog = DbHelper.ExecuteDataTable("SELECT * FROM WashMap_MonthlyLog ORDER BY RocYear, MonthNum");
            DataTable dtAud = DbHelper.ExecuteDataTable("SELECT * FROM WashMap_MonthlyAudit ORDER BY RocYear, MonthNum");

            int maxMonth = 9;
            if (dtLog != null)
            {
                foreach (DataRow lr in dtLog.Rows)
                {
                    int m = lr["MonthNum"] != DBNull.Value ? Convert.ToInt32(lr["MonthNum"]) : 0;
                    if (m > maxMonth && m <= 12) maxMonth = m;
                }
            }

            // 建立 FacId -> Log 與 Audit 映射
            Dictionary<string, List<DataRow>> logByFac = new Dictionary<string, List<DataRow>>(StringComparer.OrdinalIgnoreCase);
            if (dtLog != null)
            {
                foreach (DataRow lr in dtLog.Rows)
                {
                    string fid = lr["FacId"].ToString().Trim();
                    List<DataRow> list;
                    if (!logByFac.TryGetValue(fid, out list))
                    {
                        list = new List<DataRow>();
                        logByFac[fid] = list;
                    }
                    list.Add(lr);
                }
            }

            Dictionary<string, List<DataRow>> audByFac = new Dictionary<string, List<DataRow>>(StringComparer.OrdinalIgnoreCase);
            if (dtAud != null)
            {
                foreach (DataRow ar in dtAud.Rows)
                {
                    string fid = ar["FacId"].ToString().Trim();
                    List<DataRow> list;
                    if (!audByFac.TryGetValue(fid, out list))
                    {
                        list = new List<DataRow>();
                        audByFac[fid] = list;
                    }
                    list.Add(ar);
                }
            }

            List<Dictionary<string, object>> facObjects = new List<Dictionary<string, object>>();
            DateTime latestUpdate = DateTime.MinValue;

            foreach (DataRow r in dtFac.Rows)
            {
                string fid = r["FacId"].ToString().Trim();
                DateTime uTime = r["UpdatedAt"] != DBNull.Value ? Convert.ToDateTime(r["UpdatedAt"]) : DateTime.MinValue;
                if (uTime > latestUpdate) latestUpdate = uTime;

                Dictionary<string, object> f = new Dictionary<string, object>();
                f["id"] = fid;
                f["n"] = r["FacName"] != DBNull.Value ? r["FacName"].ToString() : "";
                string oldn = r["OldName"] != DBNull.Value ? r["OldName"].ToString() : "";
                if (!string.IsNullOrEmpty(oldn)) f["oldn"] = oldn;

                f["d"] = r["Dist"] != DBNull.Value ? r["Dist"].ToString() : "";
                f["a"] = r["Addr"] != DBNull.Value ? r["Addr"].ToString() : "";
                f["i"] = r["Industry"] != DBNull.Value ? r["Industry"].ToString() : "";
                f["p"] = r["ProcessName"] != DBNull.Value ? r["ProcessName"].ToString() : "";
                f["grp"] = r["IndustryGroup"] != DBNull.Value ? r["IndustryGroup"].ToString() : "其他";
                f["hi"] = r["IsHighRisk"] != DBNull.Value && Convert.ToBoolean(r["IsHighRisk"]);
                f["la"] = r["Lat"] != DBNull.Value ? Convert.ToDouble(r["Lat"]) : 0.0;
                f["lo"] = r["Lng"] != DBNull.Value ? Convert.ToDouble(r["Lng"]) : 0.0;
                f["csrc"] = r["CoordSrc"] != DBNull.Value ? r["CoordSrc"].ToString() : "";
                f["st"] = r["WashStatus"] != DBNull.Value ? r["WashStatus"].ToString() : "";
                f["ls"] = r["In183List"] == DBNull.Value || Convert.ToBoolean(r["In183List"]);

                string lv = r["AdoptLevel"] != DBNull.Value ? r["AdoptLevel"].ToString() : "";
                string how = r["WashMethod"] != DBNull.Value ? r["WashMethod"].ToString() : "";
                string freq = r["WashFreq"] != DBNull.Value ? r["WashFreq"].ToString() : "";
                string dirt = r["DirtGrade"] != DBNull.Value ? r["DirtGrade"].ToString() : "";
                if (!string.IsNullOrEmpty(lv) || !string.IsNullOrEmpty(how) || !string.IsNullOrEmpty(freq) || !string.IsNullOrEmpty(dirt))
                {
                    Dictionary<string, object> info = new Dictionary<string, object>();
                    info["lv"] = lv;
                    info["how"] = how;
                    info["freq"] = freq;
                    info["dirt"] = dirt;
                    f["info"] = info;
                }

                string rJson = r["RoadsJson"] != DBNull.Value ? r["RoadsJson"].ToString() : "[]";
                string gJson = r["GeomJson"] != DBNull.Value ? r["GeomJson"].ToString() : "null";
                try { f["r"] = !string.IsNullOrEmpty(rJson) ? json.DeserializeObject(rJson) : new ArrayList(); }
                catch { f["r"] = new ArrayList(); }

                try
                {
                    if (!string.IsNullOrEmpty(gJson) && gJson != "null")
                    {
                        f["g"] = json.DeserializeObject(gJson);
                    }
                }
                catch { }

                double[] wArr = new double[maxMonth];
                double[] sArr = new double[maxMonth];
                int[] wdArr = new int[maxMonth];
                int[] sdArr = new int[maxMonth];

                List<DataRow> logs;
                if (logByFac.TryGetValue(fid, out logs))
                {
                    for (int i = 0; i < logs.Count; i++)
                    {
                        DataRow lr = logs[i];
                        int mNum = lr["MonthNum"] != DBNull.Value ? Convert.ToInt32(lr["MonthNum"]) : 0;
                        if (mNum >= 1 && mNum <= maxMonth)
                        {
                            wArr[mNum - 1] = lr["WashKm"] != DBNull.Value ? Math.Round(Convert.ToDouble(lr["WashKm"]), 2) : 0.0;
                            sArr[mNum - 1] = lr["SweepKm"] != DBNull.Value ? Math.Round(Convert.ToDouble(lr["SweepKm"]), 2) : 0.0;
                            wdArr[mNum - 1] = lr["WashDays"] != DBNull.Value ? Convert.ToInt32(lr["WashDays"]) : 0;
                            sdArr[mNum - 1] = lr["SweepDays"] != DBNull.Value ? Convert.ToInt32(lr["SweepDays"]) : 0;
                        }
                    }
                }
                f["w"] = wArr;
                f["s"] = sArr;
                f["wd"] = wdArr;
                f["sd"] = sdArr;

                List<Dictionary<string, object>> audList = new List<Dictionary<string, object>>();
                List<DataRow> auds;
                if (audByFac.TryGetValue(fid, out auds))
                {
                    for (int i = 0; i < auds.Count; i++)
                    {
                        DataRow ar = auds[i];
                        Dictionary<string, object> aObj = new Dictionary<string, object>();
                        aObj["m"] = ar["YearMonth"] != DBNull.Value ? ar["YearMonth"].ToString() : "";
                        aObj["dt"] = ar["AuditDate"] != DBNull.Value ? ar["AuditDate"].ToString() : "";
                        aObj["log"] = ar["HasLog"] != DBNull.Value ? ar["HasLog"].ToString() : "";
                        aObj["ok"] = ar["IsQualified"] != DBNull.Value ? ar["IsQualified"].ToString() : "";
                        aObj["up"] = ar["IsSelfUploaded"] != DBNull.Value ? ar["IsSelfUploaded"].ToString() : "";
                        audList.Add(aObj);
                    }
                }
                f["aud"] = audList;
                facObjects.Add(f);
            }

            // 取得目前已存於 SQL 的月份清單供前端展示
            List<string> sqlLogMonths = GetExistingMonthsFromSql("WashMap_MonthlyLog");
            List<string> sqlAuditMonths = GetExistingMonthsFromSql("WashMap_MonthlyAudit");

            Dictionary<string, object> root = new Dictionary<string, object>();
            root["NM"] = maxMonth;
            root["UPDATED_AT"] = latestUpdate > DateTime.MinValue ? latestUpdate.ToString("yyyy-MM-dd HH:mm") : DateTime.Now.ToString("yyyy-MM-dd");
            root["SQL_LOG_MONTHS"] = sqlLogMonths;
            root["SQL_AUDIT_MONTHS"] = sqlAuditMonths;
            root["NOTE"] = new Dictionary<string, string>
            {
                { "factory_source", "新北市列管固定逸散污染源清冊（183家，含 TWD97 二度分帶座標轉換為 WGS84），並整合道路洗掃認養與推動名單，已結構化存入 SQL Server (WashMap_Factory)。" },
                { "wash_source", "各月份洗掃日誌與現場抽查紀錄已獨立儲存於 SQL Server 資料表 (WashMap_MonthlyLog、WashMap_MonthlyAudit)。每月匯入新表單時僅需針對新增月份寫入，無須重讀歷史舊月份。" },
                { "road_geom", "洗掃路段幾何來自 NLSC 國土測繪中心 / OpenStreetMap 新北市道路中心線；當廠方申報具體路名時，截取廠址周邊最接近申報長度的該道路線段（實線）；當未填具體路名時，自動以廠址最近的主次要道路繪製推估示意線段（虛線）。" }
            };
            root["F"] = facObjects;
            return root;
        }

        private List<string> GetExistingMonthsFromSql(string tableName)
        {
            List<string> list = new List<string>();
            try
            {
                string sql = string.Format("SELECT DISTINCT RocYear, MonthNum, YearMonth FROM {0} ORDER BY RocYear, MonthNum", tableName);
                DataTable dt = DbHelper.ExecuteDataTable(sql);
                if (dt != null)
                {
                    foreach (DataRow r in dt.Rows)
                    {
                        string ym = r["YearMonth"] != DBNull.Value ? r["YearMonth"].ToString().Trim() : "";
                        if (!string.IsNullOrEmpty(ym) && !list.Contains(ym))
                        {
                            list.Add(ym);
                        }
                    }
                }
            }
            catch { }
            return list;
        }

        #endregion

        private void GetInitData(HttpContext context)
        {
            bool sqlOk = EnsureRelationalTablesAndSeed(context);
            string outputJson = "";

            if (sqlOk)
            {
                Dictionary<string, object> sqlData = LoadDatasetFromSql(context);
                if (sqlData != null)
                {
                    outputJson = json.Serialize(sqlData);
                }
            }

            if (string.IsNullOrEmpty(outputJson))
            {
                string filePath = GetJsonFilePath(context);
                if (File.Exists(filePath))
                {
                    outputJson = File.ReadAllText(filePath, Encoding.UTF8);
                }
            }

            if (string.IsNullOrEmpty(outputJson))
            {
                context.Response.Write(json.Serialize(new { Success = false, Message = "找不到洗掃路段資料 (SQL 與本地檔案皆為空)" }));
                return;
            }

            UserAccount user = null;
            if (context.Session != null) user = context.Session["LoginUser"] as UserAccount;
            if (user == null) user = AuthService.GetCurrentUser(context);
            string userName = user != null ? (user.Name ?? user.UserID ?? "管理員") : "管理員";

            StringBuilder sb = new StringBuilder(outputJson.Length + 256);
            sb.Append("{\"Success\":true,\"StorageMode\":");
            sb.Append(json.Serialize(sqlOk ? "SQL_SERVER" : "JSON_FILE"));
            sb.Append(",\"UserName\":");
            sb.Append(json.Serialize(userName));
            sb.Append(",\"Data\":");
            sb.Append(outputJson);
            sb.Append("}");
            context.Response.Write(sb.ToString());
        }

        #region Excel 每月增量寫入 SQL 邏輯

        private void UploadExcelData(HttpContext context)
        {
            if (context.Request.Files == null || context.Request.Files.Count == 0)
            {
                context.Response.Write(json.Serialize(new { Success = false, Message = "請選擇至少一個 Excel (.xlsx / .xls) 檔案上傳！" }));
                return;
            }

            // 是否啟用「僅寫入新月份 (增量模式)」：預設 true
            string onlyNewParam = context.Request["onlyNewMonths"];
            bool onlyNewMonths = true;
            if (!string.IsNullOrEmpty(onlyNewParam) && (onlyNewParam.ToLower() == "false" || onlyNewParam == "0"))
            {
                onlyNewMonths = false;
            }

            bool sqlReady = EnsureRelationalTablesAndSeed(context);

            // 讀取目前已存在於 SQL 的歷史月份集合
            HashSet<string> existingLogMonths = new HashSet<string>(GetExistingMonthsFromSql("WashMap_MonthlyLog"), StringComparer.OrdinalIgnoreCase);
            HashSet<string> existingAuditMonths = new HashSet<string>(GetExistingMonthsFromSql("WashMap_MonthlyAudit"), StringComparer.OrdinalIgnoreCase);

            // 載入目前主檔供比對管制編號與廠名
            Dictionary<string, object> root = null;
            if (sqlReady)
            {
                root = LoadDatasetFromSql(context);
            }
            if (root == null)
            {
                string fp = GetJsonFilePath(context);
                if (File.Exists(fp))
                {
                    root = json.Deserialize<Dictionary<string, object>>(File.ReadAllText(fp, Encoding.UTF8));
                }
            }
            if (root == null || !root.ContainsKey("F"))
            {
                context.Response.Write(json.Serialize(new { Success = false, Message = "無法載入工廠主檔進行比對。" }));
                return;
            }

            List<Dictionary<string, object>> factories = GetDictList(root, "F");
            Dictionary<string, Dictionary<string, object>> idMap = new Dictionary<string, Dictionary<string, object>>(StringComparer.OrdinalIgnoreCase);
            Dictionary<string, Dictionary<string, object>> nameMap = new Dictionary<string, Dictionary<string, object>>(StringComparer.OrdinalIgnoreCase);

            for (int i = 0; i < factories.Count; i++)
            {
                Dictionary<string, object> f = factories[i];
                string fid = GetStr(f, "id").Trim().ToUpper();
                if (!string.IsNullOrEmpty(fid) && !idMap.ContainsKey(fid)) idMap[fid] = f;

                string fn = NormalizeFacName(GetStr(f, "n"));
                if (!string.IsNullOrEmpty(fn) && !nameMap.ContainsKey(fn)) nameMap[fn] = f;

                string foldn = NormalizeFacName(GetStr(f, "oldn"));
                if (!string.IsNullOrEmpty(foldn) && !nameMap.ContainsKey(foldn)) nameMap[foldn] = f;
            }

            List<string> processedFiles = new List<string>();
            List<string> writtenAuditMonths = new List<string>();
            List<string> skippedAuditMonths = new List<string>();
            List<string> writtenLogMonths = new List<string>();
            List<string> skippedLogMonths = new List<string>();
            HashSet<string> updatedFacIds = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            List<string> unmatchedItems = new List<string>();
            int addedNewFacCount = 0;
            int updatedInfoCount = 0;
            int updatedAuditRecordCount = 0;
            int updatedLogRecordCount = 0;

            for (int fIdx = 0; fIdx < context.Request.Files.Count; fIdx++)
            {
                HttpPostedFile file = context.Request.Files[fIdx];
                if (file == null || file.ContentLength <= 0 || string.IsNullOrEmpty(file.FileName)) continue;

                string fileName = Path.GetFileName(file.FileName);
                string ext = Path.GetExtension(fileName).ToLower();
                if (ext != ".xlsx" && ext != ".xls") continue;

                IWorkbook wb = null;
                using (MemoryStream ms = new MemoryStream())
                {
                    file.InputStream.CopyTo(ms);
                    ms.Position = 0;
                    if (ext == ".xlsx") wb = new XSSFWorkbook(ms);
                    else wb = new HSSFWorkbook(ms);
                }

                if (wb == null) continue;
                processedFiles.Add(fileName);

                // 1. 若含「199列管數」，補充新廠座標並寫入 SQL WashMap_Factory
                ISheet sheet199 = FindSheetExact(wb, "199列管數");
                if (sheet199 != null)
                {
                    addedNewFacCount += ParseSheet199List(sheet199, factories, idMap, nameMap, sqlReady);
                }

                // 2. 若含「All」分頁，更新分級/方式/頻率/髒污分級並寫入 SQL WashMap_Factory
                ISheet sheetAll = FindSheetExact(wb, "All");
                if (sheetAll != null)
                {
                    updatedInfoCount += ParseSheetAllInfo(sheetAll, factories, idMap, nameMap, updatedFacIds, unmatchedItems, ref addedNewFacCount, sqlReady);
                }

                // 3. 掃描所有《查核紀錄YYY MM》分頁
                Regex rxAudit = new Regex(@"^查核紀錄\s*(\d{2,3})\s*(\d{1,2})\s*$");
                List<AuditSheetMeta> auditSheets = new List<AuditSheetMeta>();
                for (int sIdx = 0; sIdx < wb.NumberOfSheets; sIdx++)
                {
                    string sName = wb.GetSheetName(sIdx);
                    if (string.IsNullOrEmpty(sName)) continue;
                    Match m = rxAudit.Match(sName.Trim());
                    if (m.Success)
                    {
                        AuditSheetMeta meta = new AuditSheetMeta();
                        meta.RocYear = int.Parse(m.Groups[1].Value);
                        meta.MonthNum = int.Parse(m.Groups[2].Value);
                        meta.YmKey = string.Format("{0}/{1:00}", meta.RocYear, meta.MonthNum);
                        meta.Sheet = wb.GetSheetAt(sIdx);
                        auditSheets.Add(meta);
                    }
                }

                // 找出此檔案中最新的一個查核月份 (即使增量模式下，最新一個月也會強制更新以確保當月補登資料同步)
                string latestAuditYmInFile = "";
                for (int i = 0; i < auditSheets.Count; i++)
                {
                    if (string.IsNullOrEmpty(latestAuditYmInFile) || CompareYmString(auditSheets[i].YmKey, latestAuditYmInFile) > 0)
                    {
                        latestAuditYmInFile = auditSheets[i].YmKey;
                    }
                }

                for (int i = 0; i < auditSheets.Count; i++)
                {
                    AuditSheetMeta meta = auditSheets[i];
                    // 增量模式：若該月份已存在於 SQL，且不是檔案中最新的一個月，直接跳過不重讀！
                    if (onlyNewMonths && existingAuditMonths.Contains(meta.YmKey) && meta.YmKey != latestAuditYmInFile)
                    {
                        if (!skippedAuditMonths.Contains(meta.YmKey)) skippedAuditMonths.Add(meta.YmKey);
                        continue;
                    }

                    int audCnt = ParseAuditMonthSheet(meta.Sheet, meta.RocYear, meta.MonthNum, meta.YmKey, idMap, nameMap, updatedFacIds, unmatchedItems, sqlReady);
                    updatedAuditRecordCount += audCnt;
                    if (!writtenAuditMonths.Contains(meta.YmKey)) writtenAuditMonths.Add(meta.YmKey);
                }

                // 4. 掃描所有《道路洗掃日誌》月份分頁 (例如 "115 01" .. "115 12")
                Regex rxLogMonth = new Regex(@"^(\d{2,3})\s+(\d{1,2})\s*$");
                List<AuditSheetMeta> logSheets = new List<AuditSheetMeta>();
                int maxMo = GetInt(root, "NM", 9);

                for (int sIdx = 0; sIdx < wb.NumberOfSheets; sIdx++)
                {
                    string sName = wb.GetSheetName(sIdx);
                    if (string.IsNullOrEmpty(sName)) continue;
                    Match m = rxLogMonth.Match(sName.Trim());
                    if (m.Success)
                    {
                        int yr = int.Parse(m.Groups[1].Value);
                        int mo = int.Parse(m.Groups[2].Value);
                        if (mo >= 1 && mo <= 12)
                        {
                            if (mo > maxMo) maxMo = mo;
                            AuditSheetMeta meta = new AuditSheetMeta();
                            meta.RocYear = yr;
                            meta.MonthNum = mo;
                            meta.YmKey = string.Format("{0}/{1:00}", yr, mo);
                            meta.Sheet = wb.GetSheetAt(sIdx);
                            logSheets.Add(meta);
                        }
                    }
                }

                if (logSheets.Count > 0)
                {
                    root["NM"] = maxMo;
                    EnsureMonthlyArraysLength(factories, maxMo);

                    string latestLogYmInFile = "";
                    for (int i = 0; i < logSheets.Count; i++)
                    {
                        if (string.IsNullOrEmpty(latestLogYmInFile) || CompareYmString(logSheets[i].YmKey, latestLogYmInFile) > 0)
                        {
                            latestLogYmInFile = logSheets[i].YmKey;
                        }
                    }

                    for (int i = 0; i < logSheets.Count; i++)
                    {
                        AuditSheetMeta meta = logSheets[i];
                        // 增量模式：若該月份已存在於 SQL，且不是檔案中最新的一個月，直接跳過不重讀！
                        if (onlyNewMonths && existingLogMonths.Contains(meta.YmKey) && meta.YmKey != latestLogYmInFile)
                        {
                            if (!skippedLogMonths.Contains(meta.YmKey)) skippedLogMonths.Add(meta.YmKey);
                            continue;
                        }

                        int logCnt = ParseWashLogMonthSheet(meta.Sheet, meta.RocYear, meta.MonthNum, meta.MonthNum - 1, maxMo, idMap, nameMap, updatedFacIds, unmatchedItems, sqlReady);
                        updatedLogRecordCount += logCnt;
                        if (!writtenLogMonths.Contains(meta.YmKey)) writtenLogMonths.Add(meta.YmKey);
                    }
                }
            }

            if (processedFiles.Count == 0)
            {
                context.Response.Write(json.Serialize(new { Success = false, Message = "未偵測到有效的 .xlsx 或 .xls 檔案！" }));
                return;
            }

            // 重新從 SQL 載入最新完整結構，並同步備份至本地 wash_map_data.json
            Dictionary<string, object> finalDataset = sqlReady ? LoadDatasetFromSql(context) : null;
            if (finalDataset == null)
            {
                SortAllFactoryAudits(factories);
                root["UPDATED_AT"] = DateTime.Now.ToString("yyyy-MM-dd HH:mm");
                root["F"] = factories;
                finalDataset = root;
            }

            string updatedJson = json.Serialize(finalDataset);
            try
            {
                string filePath = GetJsonFilePath(context);
                string dir = Path.GetDirectoryName(filePath);
                if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);
                File.WriteAllText(filePath, updatedJson, new UTF8Encoding(false));
            }
            catch { }

            writtenAuditMonths.Sort();
            skippedAuditMonths.Sort();
            writtenLogMonths.Sort();
            skippedLogMonths.Sort();

            List<string> distinctUnmatched = new List<string>();
            HashSet<string> seenUnmatched = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            for (int i = 0; i < unmatchedItems.Count; i++)
            {
                if (seenUnmatched.Add(unmatchedItems[i]) && distinctUnmatched.Count < 25)
                {
                    distinctUnmatched.Add(unmatchedItems[i]);
                }
            }

            StringBuilder respSb = new StringBuilder(updatedJson.Length + 2048);
            respSb.Append("{\"Success\":true,");
            respSb.Append("\"Message\":");
            respSb.Append(json.Serialize(string.Format("已將新增與異動數據寫入 SQL 資料庫（共更新 {0} 家工廠）！", updatedFacIds.Count)));
            respSb.Append(",\"Summary\":");
            respSb.Append(json.Serialize(new
            {
                StorageMode = sqlReady ? "SQL Server 正規化資料表 (WashMap_Factory / WashMap_MonthlyLog / WashMap_MonthlyAudit)" : "本地 JSON 檔案",
                IncrementalMode = onlyNewMonths,
                ProcessedFiles = processedFiles,
                UpdatedFactoryCount = updatedFacIds.Count,
                AddedNewFactoryCount = addedNewFacCount,
                UpdatedInfoCount = updatedInfoCount,
                UpdatedAuditRecordCount = updatedAuditRecordCount,
                UpdatedLogRecordCount = updatedLogRecordCount,
                AuditMonths = writtenAuditMonths,
                SkippedAuditMonths = skippedAuditMonths,
                LogMonths = writtenLogMonths,
                SkippedLogMonths = skippedLogMonths,
                UnmatchedItems = distinctUnmatched,
                UpdatedAt = DateTime.Now.ToString("yyyy-MM-dd HH:mm")
            }));
            respSb.Append(",\"Data\":");
            respSb.Append(updatedJson);
            respSb.Append("}");

            context.Response.Write(respSb.ToString());
        }

        private class AuditSheetMeta
        {
            public int RocYear { get; set; }
            public int MonthNum { get; set; }
            public string YmKey { get; set; }
            public ISheet Sheet { get; set; }
        }

        private ISheet FindSheetExact(IWorkbook wb, string targetName)
        {
            for (int i = 0; i < wb.NumberOfSheets; i++)
            {
                string name = wb.GetSheetName(i);
                if (!string.IsNullOrEmpty(name) && name.Trim().Equals(targetName, StringComparison.OrdinalIgnoreCase))
                {
                    return wb.GetSheetAt(i);
                }
            }
            return null;
        }

        private int ParseSheet199List(
            ISheet sheet,
            List<Dictionary<string, object>> factories,
            Dictionary<string, Dictionary<string, object>> idMap,
            Dictionary<string, Dictionary<string, object>> nameMap,
            bool sqlReady)
        {
            int added = 0;
            for (int r = 1; r <= sheet.LastRowNum; r++)
            {
                IRow row = sheet.GetRow(r);
                if (row == null) continue;

                string facId = GetCellString(row, 0).Trim().ToUpper();
                string facName = GetCellString(row, 1).Trim();
                if (string.IsNullOrEmpty(facId) || !Regex.IsMatch(facId, @"^[A-Z]\d")) continue;

                if (idMap.ContainsKey(facId)) continue;

                string dist = NormalizeDist(GetCellString(row, 2));
                string addr = GetCellString(row, 3).Trim();
                string ind = GetCellString(row, 6).Trim();
                string proc = GetCellString(row, 7).Trim();
                double tm2X = GetCellDouble(row, 9);
                double tm2Y = GetCellDouble(row, 10);

                double lat = 0;
                double lng = 0;
                if (tm2X > 100000 && tm2Y > 2000000)
                {
                    double[] wgs = Twd97ToWgs84(tm2X, tm2Y);
                    lat = Math.Round(wgs[0], 6);
                    lng = Math.Round(wgs[1], 6);
                }
                else
                {
                    double[] dbWgs = TryLookupCoordsFromDb(facId);
                    if (dbWgs != null)
                    {
                        lat = dbWgs[0];
                        lng = dbWgs[1];
                    }
                }

                if (lat <= 20 || lng <= 118) continue;

                string grp = ClassifyIndustryGroup(ind, proc);
                bool hi = IsHighRiskGroup(grp);

                Dictionary<string, object> newFac = BuildNewFactoryEntry(facId, facName, dist, addr, ind, proc, grp, hi, lat, lng, true);
                factories.Add(newFac);
                idMap[facId] = newFac;
                string normName = NormalizeFacName(facName);
                if (!string.IsNullOrEmpty(normName) && !nameMap.ContainsKey(normName))
                {
                    nameMap[normName] = newFac;
                }
                if (sqlReady)
                {
                    UpsertFactoryToSql(newFac);
                }
                added++;
            }
            return added;
        }

        private int ParseSheetAllInfo(
            ISheet sheet,
            List<Dictionary<string, object>> factories,
            Dictionary<string, Dictionary<string, object>> idMap,
            Dictionary<string, Dictionary<string, object>> nameMap,
            HashSet<string> updatedFacIds,
            List<string> unmatchedItems,
            ref int addedNewFacCount,
            bool sqlReady)
        {
            int count = 0;
            for (int r = 1; r <= sheet.LastRowNum; r++)
            {
                IRow row = sheet.GetRow(r);
                if (row == null) continue;

                string facId = GetCellString(row, 1).Trim().ToUpper();
                string facName = GetCellString(row, 2).Trim();
                if (string.IsNullOrEmpty(facId) && string.IsNullOrEmpty(facName)) continue;
                if (facId == "管制編號" || facName == "公私場所名稱") continue;

                Dictionary<string, object> fac = FindFactory(facId, facName, idMap, nameMap);
                if (fac == null && !string.IsNullOrEmpty(facId) && Regex.IsMatch(facId, @"^[A-Z]\d"))
                {
                    double[] dbWgs = TryLookupCoordsFromDb(facId);
                    if (dbWgs != null)
                    {
                        string dist = NormalizeDist(GetCellString(row, 6));
                        string addr = GetCellString(row, 3).Trim();
                        string ind = GetCellString(row, 5).Trim();
                        string grp = ClassifyIndustryGroup(ind, "");
                        bool hi = IsHighRiskGroup(grp);
                        fac = BuildNewFactoryEntry(facId, facName, dist, addr, ind, "", grp, hi, dbWgs[0], dbWgs[1], false);
                        factories.Add(fac);
                        idMap[facId] = fac;
                        string normN = NormalizeFacName(facName);
                        if (!string.IsNullOrEmpty(normN) && !nameMap.ContainsKey(normN)) nameMap[normN] = fac;
                        addedNewFacCount++;
                    }
                }

                if (fac == null)
                {
                    unmatchedItems.Add(string.Format("{0} ({1})", facId, facName));
                    continue;
                }

                string lv = GetCellString(row, 4).Trim();
                string indText = GetCellString(row, 5).Trim();
                string distText = NormalizeDist(GetCellString(row, 6));
                string how = GetCellString(row, 7).Trim();
                string freq = GetCellString(row, 8).Trim();
                double adoptLenM = GetCellDouble(row, 9);
                string dirt = GetCellString(row, 10).Trim().ToUpper();

                if (string.IsNullOrEmpty(GetStr(fac, "d")) && !string.IsNullOrEmpty(distText))
                {
                    fac["d"] = distText;
                }
                if (string.IsNullOrEmpty(GetStr(fac, "i")) && !string.IsNullOrEmpty(indText))
                {
                    fac["i"] = indText;
                    string grp = ClassifyIndustryGroup(indText, GetStr(fac, "p"));
                    fac["grp"] = grp;
                    fac["hi"] = IsHighRiskGroup(grp);
                }

                Dictionary<string, object> info = GetDict(fac, "info");
                if (info == null) info = new Dictionary<string, object>();
                if (!string.IsNullOrEmpty(lv)) info["lv"] = lv;
                if (!string.IsNullOrEmpty(how)) info["how"] = how;
                if (!string.IsNullOrEmpty(freq)) info["freq"] = freq;
                if (!string.IsNullOrEmpty(dirt)) info["dirt"] = dirt;
                fac["info"] = info;

                if (adoptLenM > 0)
                {
                    ArrayList rList = fac.ContainsKey("r") ? (fac["r"] as ArrayList) : null;
                    if (rList == null || rList.Count == 0)
                    {
                        ArrayList newR = new ArrayList();
                        Dictionary<string, object> rItem = new Dictionary<string, object>();
                        rItem["road"] = "周邊認養道路";
                        rItem["lanes"] = "";
                        rItem["cls"] = "";
                        rItem["km"] = Math.Round(adoptLenM / 1000.0, 3);
                        newR.Add(rItem);
                        fac["r"] = newR;
                    }
                }

                if (string.IsNullOrEmpty(GetStr(fac, "st")))
                {
                    fac["st"] = "wash";
                }

                if (sqlReady)
                {
                    UpsertFactoryToSql(fac);
                }

                updatedFacIds.Add(GetStr(fac, "id"));
                count++;
            }
            return count;
        }

        private int ParseAuditMonthSheet(
            ISheet sheet,
            int rocYear,
            int monthNum,
            string ymKey,
            Dictionary<string, Dictionary<string, object>> idMap,
            Dictionary<string, Dictionary<string, object>> nameMap,
            HashSet<string> updatedFacIds,
            List<string> unmatchedItems,
            bool sqlReady)
        {
            int count = 0;
            for (int r = 1; r <= sheet.LastRowNum; r++)
            {
                IRow row = sheet.GetRow(r);
                if (row == null) continue;

                string facId = GetCellString(row, 0).Trim().ToUpper();
                string facName = GetCellString(row, 1).Trim();
                if (string.IsNullOrEmpty(facId) && string.IsNullOrEmpty(facName)) continue;
                if (facId == "管制編號" || facName == "公私場所名稱") continue;
                if (facId.StartsWith("#")) continue;

                Dictionary<string, object> fac = FindFactory(facId, facName, idMap, nameMap);
                if (fac == null)
                {
                    unmatchedItems.Add(string.Format("{0} ({1})", facId, facName));
                    continue;
                }

                string logStr = GetCellString(row, 5).Trim();
                string dtStr = GetCellDateString(row, 6);
                string okStr = GetCellString(row, 7).Trim();
                string upStr = GetCellString(row, 8).Trim();

                if (string.IsNullOrEmpty(logStr) && string.IsNullOrEmpty(dtStr) && string.IsNullOrEmpty(okStr) && string.IsNullOrEmpty(upStr))
                {
                    continue;
                }

                string targetFacId = GetStr(fac, "id");
                if (sqlReady)
                {
                    UpsertMonthlyAuditToSql(targetFacId, rocYear, monthNum, dtStr, logStr, okStr, upStr);
                }

                List<Dictionary<string, object>> audList = GetDictList(fac, "aud");
                Dictionary<string, object> targetAud = null;
                for (int i = 0; i < audList.Count; i++)
                {
                    if (GetStr(audList[i], "m") == ymKey)
                    {
                        targetAud = audList[i];
                        break;
                    }
                }

                if (targetAud == null)
                {
                    targetAud = new Dictionary<string, object>();
                    targetAud["m"] = ymKey;
                    audList.Add(targetAud);
                }

                targetAud["dt"] = dtStr;
                targetAud["log"] = logStr;
                targetAud["ok"] = okStr;
                targetAud["up"] = upStr;

                fac["aud"] = audList;
                updatedFacIds.Add(targetFacId);
                count++;
            }
            return count;
        }

        private int ParseWashLogMonthSheet(
            ISheet sheet,
            int rocYear,
            int monthNum,
            int monthIdx,
            int totalMonths,
            Dictionary<string, Dictionary<string, object>> idMap,
            Dictionary<string, Dictionary<string, object>> nameMap,
            HashSet<string> updatedFacIds,
            List<string> unmatchedItems,
            bool sqlReady)
        {
            int count = 0;
            string currentFacId = "";
            string currentFacName = "";
            HashSet<string> touchedFacIdsInSheet = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

            for (int r = 1; r <= sheet.LastRowNum; r++)
            {
                IRow row = sheet.GetRow(r);
                if (row == null) continue;

                string cellId = GetCellString(row, 0).Trim().ToUpper();
                string cellName = GetCellString(row, 1).Trim();
                string mode = GetCellString(row, 2).Trim();

                if (cellId == "管制編號" || mode == "洗掃/日期") continue;

                if (!string.IsNullOrEmpty(cellId)) currentFacId = cellId;
                if (!string.IsNullOrEmpty(cellName)) currentFacName = cellName;

                if (mode != "洗街" && mode != "掃街") continue;
                if (string.IsNullOrEmpty(currentFacId) && string.IsNullOrEmpty(currentFacName)) continue;

                Dictionary<string, object> fac = FindFactory(currentFacId, currentFacName, idMap, nameMap);
                if (fac == null)
                {
                    unmatchedItems.Add(string.Format("{0} ({1})", currentFacId, currentFacName));
                    continue;
                }

                double sumKm = 0.0;
                int activeDays = 0;
                for (int c = 3; c <= 33; c++)
                {
                    double val = GetCellDouble(row, c);
                    if (val > 0)
                    {
                        sumKm += val;
                        activeDays++;
                    }
                }

                if (sumKm <= 0)
                {
                    double colTotal = GetCellDouble(row, 34);
                    if (colTotal > 0) sumKm = colTotal;
                }

                sumKm = Math.Round(sumKm, 2);

                List<double> wArr = GetDoubleList(fac, "w", totalMonths);
                List<double> sArr = GetDoubleList(fac, "s", totalMonths);
                List<int> wdArr = GetIntList(fac, "wd", totalMonths);
                List<int> sdArr = GetIntList(fac, "sd", totalMonths);

                if (mode == "洗街")
                {
                    wArr[monthIdx] = sumKm;
                    wdArr[monthIdx] = activeDays;
                }
                else if (mode == "掃街")
                {
                    sArr[monthIdx] = sumKm;
                    sdArr[monthIdx] = activeDays;
                }

                fac["w"] = wArr;
                fac["s"] = sArr;
                fac["wd"] = wdArr;
                fac["sd"] = sdArr;
                fac["st"] = "wash";

                string targetFacId = GetStr(fac, "id");
                touchedFacIdsInSheet.Add(targetFacId);
                updatedFacIds.Add(targetFacId);
                count++;
            }

            // 批次將此月份有更新的工廠洗街+掃街紀錄寫入 SQL WashMap_MonthlyLog
            if (sqlReady)
            {
                foreach (string fid in touchedFacIdsInSheet)
                {
                    Dictionary<string, object> f = idMap[fid];
                    List<double> wArr = GetDoubleList(f, "w", totalMonths);
                    List<double> sArr = GetDoubleList(f, "s", totalMonths);
                    List<int> wdArr = GetIntList(f, "wd", totalMonths);
                    List<int> sdArr = GetIntList(f, "sd", totalMonths);
                    UpsertMonthlyLogToSql(fid, rocYear, monthNum, wArr[monthIdx], sArr[monthIdx], wdArr[monthIdx], sdArr[monthIdx]);
                }
            }

            return count;
        }

        private void EnsureMonthlyArraysLength(List<Dictionary<string, object>> factories, int targetNm)
        {
            for (int i = 0; i < factories.Count; i++)
            {
                Dictionary<string, object> f = factories[i];
                f["w"] = GetDoubleList(f, "w", targetNm);
                f["s"] = GetDoubleList(f, "s", targetNm);
                f["wd"] = GetIntList(f, "wd", targetNm);
                f["sd"] = GetIntList(f, "sd", targetNm);
            }
        }

        private void SortAllFactoryAudits(List<Dictionary<string, object>> factories)
        {
            for (int i = 0; i < factories.Count; i++)
            {
                Dictionary<string, object> f = factories[i];
                List<Dictionary<string, object>> audList = GetDictList(f, "aud");
                if (audList.Count > 1)
                {
                    audList.Sort(delegate(Dictionary<string, object> a, Dictionary<string, object> b)
                    {
                        string ma = GetStr(a, "m");
                        string mb = GetStr(b, "m");
                        return CompareYmString(ma, mb);
                    });
                    f["aud"] = audList;
                }
            }
        }

        private int CompareYmString(string a, string b)
        {
            int ya = 0, ma = 0, yb = 0, mb = 0;
            ParseYm(a, out ya, out ma);
            ParseYm(b, out yb, out mb);
            if (ya != yb) return ya.CompareTo(yb);
            return ma.CompareTo(mb);
        }

        private void ParseYm(string s, out int y, out int m)
        {
            y = 0;
            m = 0;
            if (string.IsNullOrEmpty(s)) return;
            string[] parts = s.Split('/');
            if (parts.Length >= 2)
            {
                int.TryParse(parts[0].Trim(), out y);
                int.TryParse(parts[1].Trim(), out m);
            }
        }

        private Dictionary<string, object> FindFactory(
            string facId,
            string facName,
            Dictionary<string, Dictionary<string, object>> idMap,
            Dictionary<string, Dictionary<string, object>> nameMap)
        {
            if (!string.IsNullOrEmpty(facId))
            {
                Dictionary<string, object> byId;
                if (idMap.TryGetValue(facId.Trim().ToUpper(), out byId))
                {
                    return byId;
                }
            }

            if (!string.IsNullOrEmpty(facName))
            {
                string norm = NormalizeFacName(facName);
                Dictionary<string, object> byName;
                if (!string.IsNullOrEmpty(norm) && nameMap.TryGetValue(norm, out byName))
                {
                    return byName;
                }
            }

            return null;
        }

        private string NormalizeFacName(string name)
        {
            if (string.IsNullOrEmpty(name)) return "";
            string s = name.Trim();
            s = s.Replace("　", "").Replace(" ", "").Replace("(", "（").Replace(")", "）");
            return s;
        }

        private string NormalizeDist(string dist)
        {
            if (string.IsNullOrEmpty(dist)) return "";
            string s = dist.Trim();
            if (s.Length == 2 && !s.EndsWith("區"))
            {
                return s + "區";
            }
            return s;
        }

        private string ClassifyIndustryGroup(string ind, string proc)
        {
            string combined = (ind ?? "") + " " + (proc ?? "");
            if (combined.IndexOf("瀝青", StringComparison.OrdinalIgnoreCase) >= 0) return "瀝青拌合";
            if (combined.IndexOf("水泥", StringComparison.OrdinalIgnoreCase) >= 0 || combined.IndexOf("混凝土", StringComparison.OrdinalIgnoreCase) >= 0) return "水泥及混凝土";
            if (combined.IndexOf("鋼鐵", StringComparison.OrdinalIgnoreCase) >= 0 || combined.IndexOf("金屬", StringComparison.OrdinalIgnoreCase) >= 0 || combined.IndexOf("鑄造", StringComparison.OrdinalIgnoreCase) >= 0 || combined.IndexOf("煉鋼", StringComparison.OrdinalIgnoreCase) >= 0) return "鋼鐵及金屬鑄造";
            if (combined.IndexOf("石化", StringComparison.OrdinalIgnoreCase) >= 0 || combined.IndexOf("化學", StringComparison.OrdinalIgnoreCase) >= 0 || combined.IndexOf("樹脂", StringComparison.OrdinalIgnoreCase) >= 0 || combined.IndexOf("鍋爐", StringComparison.OrdinalIgnoreCase) >= 0 || combined.IndexOf("塑膠", StringComparison.OrdinalIgnoreCase) >= 0) return "石化、化學及鍋爐";
            if (combined.IndexOf("堆置", StringComparison.OrdinalIgnoreCase) >= 0 || combined.IndexOf("砂石", StringComparison.OrdinalIgnoreCase) >= 0 || combined.IndexOf("石材", StringComparison.OrdinalIgnoreCase) >= 0 || combined.IndexOf("土石", StringComparison.OrdinalIgnoreCase) >= 0) return "堆置場及砂石";
            if (combined.IndexOf("窯", StringComparison.OrdinalIgnoreCase) >= 0 || combined.IndexOf("陶", StringComparison.OrdinalIgnoreCase) >= 0 || combined.IndexOf("耐火", StringComparison.OrdinalIgnoreCase) >= 0 || combined.IndexOf("玻璃", StringComparison.OrdinalIgnoreCase) >= 0 || combined.IndexOf("石膏", StringComparison.OrdinalIgnoreCase) >= 0 || combined.IndexOf("非金屬礦物", StringComparison.OrdinalIgnoreCase) >= 0) return "窯業、耐火及玻璃";
            return "其他";
        }

        private bool IsHighRiskGroup(string grp)
        {
            return grp == "瀝青拌合" || grp == "水泥及混凝土" || grp == "鋼鐵及金屬鑄造" || grp == "石化、化學及鍋爐";
        }

        private Dictionary<string, object> BuildNewFactoryEntry(
            string id, string name, string dist, string addr, string ind, string proc, string grp, bool hi, double lat, double lng, bool inList)
        {
            Dictionary<string, object> d = new Dictionary<string, object>();
            d["id"] = id;
            d["n"] = name;
            d["d"] = dist;
            d["a"] = addr;
            d["i"] = ind;
            d["p"] = proc;
            d["grp"] = grp;
            d["hi"] = hi;
            d["la"] = lat;
            d["lo"] = lng;
            d["csrc"] = "TM2座標轉換";
            d["st"] = "wash";
            d["ls"] = inList;
            d["r"] = new ArrayList();
            d["w"] = new double[9];
            d["s"] = new double[9];
            d["wd"] = new int[9];
            d["sd"] = new int[9];
            d["aud"] = new ArrayList();
            return d;
        }

        private double[] TryLookupCoordsFromDb(string facId)
        {
            try
            {
                string sql = "SELECT TOP 1 * FROM FAC_Main WHERE C_NO = @id";
                SqlParameter[] p = new SqlParameter[] { new SqlParameter("@id", facId) };
                DataTable dt = DbHelper.ExecuteDataTable(sql, p);
                if (dt != null && dt.Rows.Count > 0)
                {
                    DataRow r = dt.Rows[0];
                    double x = 0, y = 0;
                    string[] xCols = new string[] { "TWD97_X", "X", "COORD_X", "PX" };
                    string[] yCols = new string[] { "TWD97_Y", "Y", "COORD_Y", "PY" };
                    for (int i = 0; i < xCols.Length; i++)
                    {
                        if (dt.Columns.Contains(xCols[i]) && r[xCols[i]] != DBNull.Value)
                        {
                            double.TryParse(r[xCols[i]].ToString(), out x);
                            if (x > 0) break;
                        }
                    }
                    for (int i = 0; i < yCols.Length; i++)
                    {
                        if (dt.Columns.Contains(yCols[i]) && r[yCols[i]] != DBNull.Value)
                        {
                            double.TryParse(r[yCols[i]].ToString(), out y);
                            if (y > 0) break;
                        }
                    }
                    if (x > 100000 && y > 2000000)
                    {
                        double[] wgs = Twd97ToWgs84(x, y);
                        return new double[] { Math.Round(wgs[0], 6), Math.Round(wgs[1], 6) };
                    }
                }
            }
            catch { }
            return null;
        }

        private double[] Twd97ToWgs84(double x, double y)
        {
            double a = 6378137.0;
            double b = 6356752.314245;
            double lon0 = 121.0 * Math.PI / 180.0;
            double k0 = 0.9999;
            int dx = 250000;

            double e = Math.Sqrt(1.0 - Math.Pow(b / a, 2));
            x -= dx;
            double M = y / k0;
            double mu = M / (a * (1.0 - Math.Pow(e, 2) / 4.0 - 3.0 * Math.Pow(e, 4) / 64.0 - 5.0 * Math.Pow(e, 6) / 256.0));
            double e1 = (1.0 - Math.Sqrt(1.0 - Math.Pow(e, 2))) / (1.0 + Math.Sqrt(1.0 - Math.Pow(e, 2)));

            double J1 = 3.0 * e1 / 2.0 - 27.0 * Math.Pow(e1, 3) / 32.0;
            double J2 = 21.0 * Math.Pow(e1, 2) / 16.0 - 55.0 * Math.Pow(e1, 4) / 32.0;
            double J3 = 151.0 * Math.Pow(e1, 3) / 96.0;
            double J4 = 1097.0 * Math.Pow(e1, 4) / 512.0;

            double fp = mu + J1 * Math.Sin(2.0 * mu) + J2 * Math.Sin(4.0 * mu) + J3 * Math.Sin(6.0 * mu) + J4 * Math.Sin(8.0 * mu);
            double e2 = Math.Pow(e * a / b, 2);
            double C1 = e2 * Math.Pow(Math.Cos(fp), 2);
            double T1 = Math.Pow(Math.Tan(fp), 2);
            double R1 = a * (1.0 - Math.Pow(e, 2)) / Math.Pow(1.0 - Math.Pow(e, 2) * Math.Pow(Math.Sin(fp), 2), 1.5);
            double N1 = a / Math.Sqrt(1.0 - Math.Pow(e, 2) * Math.Pow(Math.Sin(fp), 2));
            double D = x / (N1 * k0);

            double Q1 = N1 * Math.Tan(fp) / R1;
            double Q2 = Math.Pow(D, 2) / 2.0;
            double Q3 = (5.0 + 3.0 * T1 + 10.0 * C1 - 4.0 * Math.Pow(C1, 2) - 9.0 * e2) * Math.Pow(D, 4) / 24.0;
            double Q4 = (61.0 + 90.0 * T1 + 298.0 * C1 + 45.0 * Math.Pow(T1, 2) - 3.0 * Math.Pow(C1, 2) - 252.0 * e2) * Math.Pow(D, 6) / 720.0;
            double lat = fp - Q1 * (Q2 - Q3 + Q4);

            double Q5 = D;
            double Q6 = (1.0 + 2.0 * T1 + C1) * Math.Pow(D, 3) / 6.0;
            double Q7 = (5.0 - 2.0 * C1 + 28.0 * T1 - 3.0 * Math.Pow(C1, 2) + 8.0 * e2 + 24.0 * Math.Pow(T1, 2)) * Math.Pow(D, 5) / 120.0;
            double lon = lon0 + (Q5 - Q6 + Q7) / Math.Cos(fp);

            return new double[] { lat * 180.0 / Math.PI, lon * 180.0 / Math.PI };
        }

        private string GetCellString(IRow row, int colIdx)
        {
            if (row == null) return "";
            ICell cell = row.GetCell(colIdx);
            if (cell == null) return "";

            CellType cType = cell.CellType;
            if (cType == CellType.Formula)
            {
                cType = cell.CachedFormulaResultType;
            }

            if (cType == CellType.String)
            {
                return cell.StringCellValue != null ? cell.StringCellValue.Trim() : "";
            }
            if (cType == CellType.Numeric)
            {
                if (DateUtil.IsCellDateFormatted(cell))
                {
                    try
                    {
                        return cell.DateCellValue.ToString("yyyy-MM-dd");
                    }
                    catch { }
                }
                return cell.NumericCellValue.ToString(CultureInfo.InvariantCulture);
            }
            if (cType == CellType.Boolean)
            {
                return cell.BooleanCellValue ? "是" : "否";
            }
            return "";
        }

        private string GetCellDateString(IRow row, int colIdx)
        {
            if (row == null) return "";
            ICell cell = row.GetCell(colIdx);
            if (cell == null) return "";

            CellType cType = cell.CellType;
            if (cType == CellType.Formula)
            {
                cType = cell.CachedFormulaResultType;
            }

            if (cType == CellType.Numeric)
            {
                try
                {
                    double num = cell.NumericCellValue;
                    if (num > 30000 && num < 80000)
                    {
                        DateTime dt = DateTime.FromOADate(num);
                        return dt.ToString("yyyy-MM-dd");
                    }
                }
                catch { }
            }

            string s = GetCellString(row, colIdx).Trim();
            if (string.IsNullOrEmpty(s) || s == "-" || s == "無" || s.StartsWith("#")) return "";

            DateTime parsed;
            if (DateTime.TryParse(s, out parsed))
            {
                return parsed.ToString("yyyy-MM-dd");
            }
            return s;
        }

        private double GetCellDouble(IRow row, int colIdx)
        {
            if (row == null) return 0.0;
            ICell cell = row.GetCell(colIdx);
            if (cell == null) return 0.0;

            CellType cType = cell.CellType;
            if (cType == CellType.Formula)
            {
                cType = cell.CachedFormulaResultType;
            }

            if (cType == CellType.Numeric)
            {
                return cell.NumericCellValue;
            }
            if (cType == CellType.String)
            {
                double v = 0.0;
                if (double.TryParse(cell.StringCellValue.Trim(), NumberStyles.Any, CultureInfo.InvariantCulture, out v))
                {
                    return v;
                }
            }
            return 0.0;
        }

        private string GetStr(Dictionary<string, object> dict, string key)
        {
            if (dict == null || !dict.ContainsKey(key) || dict[key] == null) return "";
            return dict[key].ToString();
        }

        private int GetInt(Dictionary<string, object> dict, string key, int defVal)
        {
            if (dict == null || !dict.ContainsKey(key) || dict[key] == null) return defVal;
            int v;
            if (int.TryParse(dict[key].ToString(), out v)) return v;
            return defVal;
        }

        private Dictionary<string, object> GetDict(Dictionary<string, object> dict, string key)
        {
            if (dict == null || !dict.ContainsKey(key) || dict[key] == null) return null;
            return dict[key] as Dictionary<string, object>;
        }

        private List<Dictionary<string, object>> GetDictList(Dictionary<string, object> dict, string key)
        {
            List<Dictionary<string, object>> res = new List<Dictionary<string, object>>();
            if (dict == null || !dict.ContainsKey(key) || dict[key] == null) return res;

            ArrayList al = dict[key] as ArrayList;
            if (al != null)
            {
                for (int i = 0; i < al.Count; i++)
                {
                    Dictionary<string, object> item = al[i] as Dictionary<string, object>;
                    if (item != null) res.Add(item);
                }
                return res;
            }

            List<Dictionary<string, object>> dl = dict[key] as List<Dictionary<string, object>>;
            if (dl != null) return dl;

            return res;
        }

        private List<double> GetDoubleList(Dictionary<string, object> dict, string key, int targetLen)
        {
            List<double> res = new List<double>();
            if (dict != null && dict.ContainsKey(key) && dict[key] != null)
            {
                IEnumerable en = dict[key] as IEnumerable;
                if (en != null)
                {
                    foreach (object o in en)
                    {
                        double v = 0.0;
                        if (o != null) double.TryParse(o.ToString(), NumberStyles.Any, CultureInfo.InvariantCulture, out v);
                        res.Add(v);
                    }
                }
            }
            while (res.Count < targetLen) res.Add(0.0);
            return res;
        }

        private List<int> GetIntList(Dictionary<string, object> dict, string key, int targetLen)
        {
            List<int> res = new List<int>();
            if (dict != null && dict.ContainsKey(key) && dict[key] != null)
            {
                IEnumerable en = dict[key] as IEnumerable;
                if (en != null)
                {
                    foreach (object o in en)
                    {
                        int v = 0;
                        if (o != null) int.TryParse(o.ToString(), out v);
                        res.Add(v);
                    }
                }
            }
            while (res.Count < targetLen) res.Add(0);
            return res;
        }

        #endregion

        public bool IsReusable
        {
            get { return false; }
        }
    }
}
