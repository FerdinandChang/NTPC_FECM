using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using NTPC_FEC.Helpers;

namespace NTPC_FEC.Services
{
    public class AuthItem
    {
        public string AuthCode { get; set; }   // 唯一識別代碼 (如 FAC_LIST_READ)
        public int LicID { get; set; }          // 舊版 Bit 索引 (0~63)
        public string LicName { get; set; }     // 功能顯示名稱
        public string Group { get; set; }       // 主模組名稱 (如 工廠基本資料)
        public string SubGroup { get; set; }    // 子區塊名稱 (如 道路髒污清理，無則為空)
        public string FieldName { get; set; }   // "LIC", "LIC2" 或 "NEW"
        public bool IsExternal { get; set; }    // 是否為 8/9 外部介接模組 (維持原樣)
        public int SortOrder { get; set; }
    }

    public class TownItem
    {
        public string TownNo { get; set; }
        public string TownName { get; set; }
    }

    public class PermissionService
    {
        // 確保 UserAuthPermission 資料表與索引存在
        public static void EnsureAuthPermissionTableExists()
        {
            try
            {
                string sql = "IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'UserAuthPermission') " +
                             "BEGIN " +
                             "    CREATE TABLE [dbo].[UserAuthPermission] ( " +
                             "        [UserID]     VARCHAR(50)  NOT NULL, " +
                             "        [AuthCode]   VARCHAR(50)  NOT NULL, " +
                             "        [CreateTime] DATETIME     NOT NULL DEFAULT (GETDATE()), " +
                             "        [CreateUser] VARCHAR(50)  NULL, " +
                             "        CONSTRAINT [PK_UserAuthPermission] PRIMARY KEY CLUSTERED ([UserID] ASC, [AuthCode] ASC) " +
                             "    ); " +
                             "    CREATE NONCLUSTERED INDEX [IX_UserAuthPermission_UserID] ON [dbo].[UserAuthPermission] ([UserID]); " +
                             "END";
                DbHelper.ExecuteNonQuery(sql);
            }
            catch { }
        }

        // 取得所有系統權限項目定義 (包含本系統 1~7 及 10，以及外部介接 8 與 9)
        public static List<AuthItem> GetAuthItems()
        {
            EnsureAuthPermissionTableExists();
            return GetAllDefinedAuthItems();
        }

        // 清除指定使用者之 Request 級別權限快取
        public static void ClearUserAuthCache(string userId)
        {
            if (string.IsNullOrEmpty(userId)) return;
            HttpContext ctx = HttpContext.Current;
            if (ctx != null)
            {
                string cacheKey = "AUTH_CODES_" + userId.ToUpper();
                if (ctx.Items.Contains(cacheKey))
                {
                    ctx.Items.Remove(cacheKey);
                }
            }
        }

        // 取得使用者所有授權代碼 (優先讀取 UserAuthPermission，舊帳號自動由 LIC/LIC2 映射備援)
        public static HashSet<string> GetUserAuthCodes(string userId, long fallbackLic, long fallbackLic2)
        {
            var set = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            if (string.IsNullOrEmpty(userId)) return set;

            // 1. Request 級別快取：單一 HTTP 請求生命週期內不重複查庫
            string cacheKey = "AUTH_CODES_" + userId.ToUpper();
            HttpContext ctx = HttpContext.Current;
            if (ctx != null && ctx.Items.Contains(cacheKey))
            {
                var cached = ctx.Items[cacheKey] as HashSet<string>;
                if (cached != null) return cached;
            }

            EnsureAuthPermissionTableExists();
            bool foundInDb = false;

            try
            {
                string sql = "SELECT AuthCode FROM UserAuthPermission WHERE UserID = @UserID";
                var parameters = new SqlParameter[]
                {
                    new SqlParameter("@UserID", SqlDbType.VarChar) { Value = userId }
                };
                DataTable dt = DbHelper.ExecuteDataTable(sql, parameters);
                if (dt != null && dt.Rows.Count > 0)
                {
                    foundInDb = true;
                    foreach (DataRow row in dt.Rows)
                    {
                        if (row["AuthCode"] != null && row["AuthCode"] != DBNull.Value)
                        {
                            string code = row["AuthCode"].ToString().Trim();
                            if (!string.IsNullOrEmpty(code)) set.Add(code);
                        }
                    }
                }
            }
            catch { }

            // 2. 若 UserAuthPermission 資料表中尚未有該使用者之精確記錄，才由舊版 LIC / LIC2 位元遮罩反向映射 (舊帳號相容)
            if (!foundInDb)
            {
                var allItems = GetAllDefinedAuthItems();
                foreach (var item in allItems)
                {
                    bool hasPerm = false;
                    if (item.FieldName.Equals("LIC2", StringComparison.OrdinalIgnoreCase))
                    {
                        if (item.LicID >= 0 && item.LicID < 64)
                        {
                            hasPerm = (fallbackLic2 & (1L << item.LicID)) != 0;
                        }
                    }
                    else
                    {
                        if (item.LicID >= 0 && item.LicID < 64)
                        {
                            hasPerm = (fallbackLic & (1L << item.LicID)) != 0;
                        }
                    }

                    if (hasPerm && !string.IsNullOrEmpty(item.AuthCode))
                    {
                        set.Add(item.AuthCode);
                    }
                }
            }

            // 存入 Request 級別快取
            if (ctx != null)
            {
                ctx.Items[cacheKey] = set;
            }

            return set;
        }

        // 檢查使用者是否具備指定權限
        public static bool HasPermission(string userId, long fallbackLic, string authCode, int legacyBit)
        {
            if (string.IsNullOrEmpty(userId)) return false;
            if (userId.ToLower() == "admin") return true;

            var userCodes = GetUserAuthCodes(userId, fallbackLic, 0L);
            return userCodes.Contains(authCode);
        }

        // 取得使用者群組化之權限摘要 (供清單顯示)
        public static Dictionary<string, List<string>> GetUserPermissionGroups(string userId, long lic, long lic2)
        {
            var userCodes = GetUserAuthCodes(userId, lic, lic2);
            var allItems = GetAllDefinedAuthItems();
            var dict = new Dictionary<string, List<string>>();

            foreach (var item in allItems)
            {
                bool hasPermission = false;
                if (item.IsExternal)
                {
                    // 外部介接模組 (8/9) 依 LIC / LIC2 位元即時判定
                    if (item.FieldName.Equals("LIC2", StringComparison.OrdinalIgnoreCase))
                    {
                        if (item.LicID >= 0 && item.LicID < 64)
                        {
                            hasPermission = (lic2 & (1L << item.LicID)) != 0;
                        }
                    }
                    else
                    {
                        if (item.LicID >= 0 && item.LicID < 64)
                        {
                            hasPermission = (lic & (1L << item.LicID)) != 0;
                        }
                    }
                }
                else
                {
                    // 本系統業務模組依 AuthCode 判定
                    hasPermission = userCodes.Contains(item.AuthCode);
                }

                if (hasPermission)
                {
                    string groupKey = item.Group;
                    if (!dict.ContainsKey(groupKey))
                    {
                        dict[groupKey] = new List<string>();
                    }
                    if (!dict[groupKey].Contains(item.LicName))
                    {
                        dict[groupKey].Add(item.LicName);
                    }
                }
            }

            return dict;
        }

        // 舊版相容多載
        public static Dictionary<string, List<string>> GetUserPermissionGroups(long lic, long lic2)
        {
            return GetUserPermissionGroups("", lic, lic2);
        }

        // 取得新北 29 行政區清單
        public static List<TownItem> GetTownList()
        {
            var list = new List<TownItem>();
            try
            {
                string sql = "SELECT TOWN_NO, TOWN_NA FROM C_TOWN WHERE COUNTRY = 'F' ORDER BY TOWN_NO";
                DataTable dt = DbHelper.ExecuteDataTable(sql);
                if (dt != null && dt.Rows.Count > 0)
                {
                    foreach (DataRow row in dt.Rows)
                    {
                        list.Add(new TownItem
                        {
                            TownNo = ((row["TOWN_NO"] != null && row["TOWN_NO"] != DBNull.Value) ? row["TOWN_NO"].ToString() : ""),
                            TownName = ((row["TOWN_NA"] != null && row["TOWN_NA"] != DBNull.Value) ? row["TOWN_NA"].ToString() : "")
                        });
                    }
                    return list;
                }
            }
            catch { }

            // 備援清單
            string[] towns = new string[]
            {
                "板橋區", "三重區", "中和區", "永和區", "新莊區", "新店區", "樹林區", "鶯歌區", "三峽區", "淡水區",
                "汐止區", "瑞芳區", "土城區", "蘆洲區", "五股區", "泰山區", "林口區", "深坑區", "石碇區", "坪林區",
                "三芝區", "石門區", "八里區", "平溪區", "雙溪區", "貢寮區", "金山區", "萬里區", "烏來區"
            };

            for (int i = 0; i < towns.Length; i++)
            {
                list.Add(new TownItem { TownNo = (i + 1).ToString("D2"), TownName = towns[i] });
            }

            return list;
        }

        // 取得使用者設定的限定行政區
        public static List<string> GetUserTowns(string userId)
        {
            var list = new List<string>();
            try
            {
                string sql = "SELECT UserFilterTown.TOWN_NO, C_TOWN.TOWN_NA FROM UserFilterTown LEFT JOIN C_TOWN ON UserFilterTown.TOWN_NO = C_TOWN.TOWN_NO WHERE User_ID = @UserID";
                var parameters = new SqlParameter[]
                {
                    new SqlParameter("@UserID", SqlDbType.VarChar) { Value = userId }
                };
                DataTable dt = DbHelper.ExecuteDataTable(sql, parameters);
                if (dt != null)
                {
                    foreach (DataRow row in dt.Rows)
                    {
                        string name = (row["TOWN_NA"] != null && row["TOWN_NA"] != DBNull.Value) ? row["TOWN_NA"].ToString() : "";
                        if (string.IsNullOrEmpty(name)) name = (row["TOWN_NO"] != null && row["TOWN_NO"] != DBNull.Value) ? row["TOWN_NO"].ToString() : "";
                        if (!string.IsNullOrEmpty(name)) list.Add(name);
                    }
                }
            }
            catch { }
            return list;
        }

        // 取得使用者設定的限定行政區代碼清單
        public static List<string> GetUserTownNos(string userId)
        {
            var list = new List<string>();
            try
            {
                string sql = "SELECT TOWN_NO FROM UserFilterTown WHERE User_ID = @UserID";
                var parameters = new SqlParameter[]
                {
                    new SqlParameter("@UserID", SqlDbType.VarChar) { Value = userId }
                };
                DataTable dt = DbHelper.ExecuteDataTable(sql, parameters);
                if (dt != null)
                {
                    foreach (DataRow row in dt.Rows)
                    {
                        string no = (row["TOWN_NO"] != null && row["TOWN_NO"] != DBNull.Value) ? row["TOWN_NO"].ToString() : "";
                        if (!string.IsNullOrEmpty(no)) list.Add(no);
                    }
                }
            }
            catch { }
            return list;
        }

        // 計算勾選之 LicIds 產生的 Long 數值
        public static long CalculateLicValue(IEnumerable<int> licIds)
        {
            long val = 0L;
            if (licIds == null) return val;
            foreach (int id in licIds)
            {
                if (id >= 0 && id < 64)
                {
                    val |= (1L << id);
                }
            }
            return val;
        }

        // 完整系統權限定義清單 (1~7、10 為本系統首頁對齊項目；8、9 為外部介接維持原樣)
        private static List<AuthItem> GetAllDefinedAuthItems()
        {
            var list = new List<AuthItem>();
            int sort = 1;

            // ==========================================
            // 模組 1. 工廠基本資料 (FAC)
            // ==========================================
            AddAuth(list, ref sort, "FAC_LIST_READ", 41, "逸散源列管", "工廠基本資料", "", "LIC", false);
            AddAuth(list, ref sort, "FAC_LIST_EDIT", 2, "逸散源未列管", "工廠基本資料", "", "LIC", false);
            AddAuth(list, ref sort, "FAC_LICENSE_QUERY", 10, "許可證資訊", "工廠基本資料", "", "LIC", false);
            AddAuth(list, ref sort, "FAC_OUTLINK_QUERY", 11, "相關外部系統連結", "工廠基本資料", "", "LIC", false);
            AddAuth(list, ref sort, "FAC_STATS", 41, "公私場所逸散源統計分析", "工廠基本資料", "", "LIC", false);
            AddAuth(list, ref sort, "FAC_BUFFER_MAP", 41, "環域查詢", "工廠基本資料", "", "LIC", false);

            // ==========================================
            // 模組 2. 巡查任務派遣 (CASE)
            // ==========================================
            AddAuth(list, ref sort, "CASE_CHECK_RUN", 0, "防制作業查核", "巡查任務派遣", "", "LIC", false);
            AddAuth(list, ref sort, "CASE_DRAFT_VIEW", 0, "查核紀錄暫存", "巡查任務派遣", "", "LIC", false);
            AddAuth(list, ref sort, "CASE_BACK_LIST", 0, "退件紀錄", "巡查任務派遣", "", "LIC", false);
            AddAuth(list, ref sort, "CASE_INV1", 3, "案件初審", "巡查任務派遣", "", "LIC", false);
            AddAuth(list, ref sort, "CASE_INV2", 4, "案件複審", "巡查任務派遣", "", "LIC", false);
            AddAuth(list, ref sort, "CASE_INV3", 5, "案件三審", "巡查任務派遣", "", "LIC", false);
            AddAuth(list, ref sort, "CASE_SEARCH_LIST", 42, "查核成果列表", "巡查任務派遣", "", "LIC", false);
            AddAuth(list, ref sort, "CASE_PROJECT_ZONE", 42, "臺北港專區", "巡查任務派遣", "", "LIC", false);
            AddAuth(list, ref sort, "CASE_DISPATCH_SET", 0, "稽查派遣管理", "巡查任務派遣", "", "LIC", false);
            AddAuth(list, ref sort, "CASE_MISSION_7DAY", 0, "巡查派遣", "巡查任務派遣", "", "LIC", false);
            AddAuth(list, ref sort, "CASE_MISSION_2TIMES", 0, "提報稽查", "巡查任務派遣", "", "LIC", false);
            AddAuth(list, ref sort, "CASE_SUM_STATS", 42, "查核統計", "巡查任務派遣", "", "LIC", false);
            AddAuth(list, ref sort, "CASE_SUM_MANAGE", 42, "管辦改善歷程追蹤統計", "巡查任務派遣", "", "LIC", false);

            // ==========================================
            // 模組 3. 作業機具調查 (MACHINE)
            // ==========================================
            AddAuth(list, ref sort, "MAC_DRAFT_VIEW", 1, "查核紀錄暫存", "作業機具調查", "作業機具調查", "LIC", false);
            AddAuth(list, ref sort, "MAC_INV1", 6, "案件初審", "作業機具調查", "作業機具調查", "LIC", false);
            AddAuth(list, ref sort, "MAC_INV2", 6, "案件複審", "作業機具調查", "作業機具調查", "LIC", false);
            AddAuth(list, ref sort, "MAC_INV3", 6, "案件三審", "作業機具調查", "作業機具調查", "LIC", false);
            AddAuth(list, ref sort, "MAC_SEARCH_LIST", 43, "調查成果列表", "作業機具調查", "", "LIC", false);
            AddAuth(list, ref sort, "MAC_SURVEY_FORM", 43, "固定污染源施工機具普查", "作業機具調查", "", "LIC", false);
            AddAuth(list, ref sort, "MAC_MOENV_ANALYSIS", 43, "環境部施工機具資料分析", "作業機具調查", "", "LIC", false);

            // ==========================================
            // 模組 4. 裸露地調查 (BARE)
            // ==========================================
            AddAuth(list, ref sort, "BARE_NEW_CHECK", 17, "裸露地調查", "裸露地調查", "", "LIC", false);
            AddAuth(list, ref sort, "BARE_DRAFT_VIEW", 17, "查核紀錄暫存", "裸露地調查", "", "LIC", false);
            AddAuth(list, ref sort, "BARE_BACK_LIST", 17, "退件紀錄", "裸露地調查", "", "LIC", false);
            AddAuth(list, ref sort, "BARE_INV1", 18, "案件初審", "裸露地調查", "", "LIC", false);
            AddAuth(list, ref sort, "BARE_INV2", 19, "案件複審", "裸露地調查", "", "LIC", false);
            AddAuth(list, ref sort, "BARE_INV3", 20, "案件三審", "裸露地調查", "", "LIC", false);
            AddAuth(list, ref sort, "BARE_SEARCH_LIST", 44, "調查成果列表", "裸露地調查", "", "LIC", false);

            // ==========================================
            // 模組 5. 自主管理回報 (OWN)
            // ==========================================
            AddAuth(list, ref sort, "OWN_REPORT_INPUT", 8, "自主維護回報", "自主管理回報", "自主管理控管", "LIC", false);
            AddAuth(list, ref sort, "OWN_REPORT_LIST", 8, "維護紀錄列表", "自主管理回報", "自主管理控管", "LIC", false);

            AddAuth(list, ref sort, "OWN_WASH_INPUT", 12, "車輛洗掃回報", "自主管理回報", "車輛洗掃設備管理", "LIC", false);
            AddAuth(list, ref sort, "OWN_WASH_UPLOAD", 13, "洗掃報表回傳", "自主管理回報", "車輛洗掃設備管理", "LIC", false);
            AddAuth(list, ref sort, "OWN_WASH_LIST", 14, "洗掃紀錄列表", "自主管理回報", "車輛洗掃設備管理", "LIC", false);
            AddAuth(list, ref sort, "OWN_WASH_RECORD_LIST", 14, "洗車水電紀錄列表", "自主管理回報", "車輛洗掃設備管理", "LIC", false);

            AddAuth(list, ref sort, "OWN_DEFECT_INPUT", 15, "缺失改善回報", "自主管理回報", "防制設施缺失改善管理", "LIC", false);
            AddAuth(list, ref sort, "OWN_DEFECT_LIST", 15, "改善紀錄列表", "自主管理回報", "防制設施缺失改善管理", "LIC", false);

            AddAuth(list, ref sort, "OWN_LINE_ALERT", 45, "LINE即時通報", "自主管理回報", "空品不良應變管理", "LIC", false);
            AddAuth(list, ref sort, "OWN_AIR_INPUT", 45, "空品應變回報", "自主管理回報", "空品不良應變管理", "LIC", false);
            AddAuth(list, ref sort, "OWN_AIR_LIST", 45, "空品應變列表", "自主管理回報", "空品不良應變管理", "LIC", false);

            // ==========================================
            // 模組 6. 空間資訊整合 (MAP)
            // ==========================================
            AddAuth(list, ref sort, "MAP_WASH_GIS", 41, "道路洗掃路段與現場查核地圖", "空間資訊整合", "", "LIC", false);
            AddAuth(list, ref sort, "MAP_NDVI_SAT", 41, "NDVI 植被衛星影像", "空間資訊整合", "", "LIC", false);

            // ==========================================
            // 模組 7. 道路潔淨巡檢 (ROAD)
            // ==========================================
            AddAuth(list, ref sort, "ROAD_CLEAN_NEW", 21, "道路潔淨現場查核", "道路潔淨巡檢", "道路潔淨巡檢", "LIC", false);
            AddAuth(list, ref sort, "ROAD_CLEAN_DRAFT", 22, "查核紀錄暫存", "道路潔淨巡檢", "道路潔淨巡檢", "LIC", false);
            AddAuth(list, ref sort, "ROAD_CLEAN_BACK", 22, "返回修正案件", "道路潔淨巡檢", "道路潔淨巡檢", "LIC", false);
            AddAuth(list, ref sort, "ROAD_CLEAN_EXAM", 22, "案件審核", "道路潔淨巡檢", "道路潔淨巡檢", "LIC", false);
            AddAuth(list, ref sort, "ROAD_CLEAN_SEARCH", 24, "調查成果列表", "道路潔淨巡檢", "道路潔淨巡檢", "LIC", false);
            AddAuth(list, ref sort, "ROAD_CLEAN_STATS", 24, "道路潔淨統計", "道路潔淨巡檢", "道路潔淨巡檢", "LIC", false);

            AddAuth(list, ref sort, "ROAD_DIRTY_NEW", 21, "道路髒污通報", "道路潔淨巡檢", "道路髒污清理", "LIC", false);
            AddAuth(list, ref sort, "ROAD_DIRTY_DRAFT", 21, "查核紀錄暫存(路污)", "道路潔淨巡檢", "道路髒污清理", "LIC", false);
            AddAuth(list, ref sort, "ROAD_DIRTY_IMPROVE", 23, "髒污改善回報", "道路潔淨巡檢", "道路髒污清理", "LIC", false);
            AddAuth(list, ref sort, "ROAD_DIRTY_FINISH", 24, "髒污改善成果", "道路潔淨巡檢", "道路髒污清理", "LIC", false);

            AddAuth(list, ref sort, "ROAD_BREAK_NEW", 26, "道路破損通報", "道路潔淨巡檢", "道路破損清理", "LIC", false);
            AddAuth(list, ref sort, "ROAD_BREAK_DRAFT", 26, "查核紀錄暫存(破損)", "道路潔淨巡檢", "道路破損清理", "LIC", false);
            AddAuth(list, ref sort, "ROAD_BREAK_IMPROVE", 27, "破損改善回報", "道路潔淨巡檢", "道路破損清理", "LIC", false);
            AddAuth(list, ref sort, "ROAD_BREAK_FINISH", 27, "破損改善成果", "道路潔淨巡檢", "道路破損清理", "LIC", false);

            AddAuth(list, ref sort, "ROAD_BSC_NEW", 28, "清理落塵通報", "道路潔淨巡檢", "人行道/跳空通道整理", "LIC", false);
            AddAuth(list, ref sort, "ROAD_BSC_DRAFT", 28, "查核紀錄暫存(落塵)", "道路潔淨巡檢", "人行道/跳空通道整理", "LIC", false);
            AddAuth(list, ref sort, "ROAD_BSC_IMPROVE", 29, "落塵改善回報", "道路潔淨巡檢", "人行道/跳空通道整理", "LIC", false);
            AddAuth(list, ref sort, "ROAD_BSC_FINISH", 29, "落塵改善成果", "道路潔淨巡檢", "人行道/跳空通道整理", "LIC", false);

            // ==========================================
            // 模組 10. 系統維運管理 (ADMIN)
            // ==========================================
            AddAuth(list, ref sort, "SYS_ACCOUNT_MANAGE", 63, "帳號權限管理", "系統維運管理", "", "LIC", false);

            // =========================================================================
            // 外部系統介接專區 (8 及 9)：完全維持目前設定，專供外部 API 讀取 LIC / LIC2
            // =========================================================================
            // 8-1. 餐飲業者管理 (寫入 UserAcc.LIC)
            AddAuth(list, ref sort, "EXT_CAT_SURVEY", 25, "餐飲業者調查", "餐飲業者管理", "", "LIC", true);
            AddAuth(list, ref sort, "EXT_CAT_INV1", 36, "初審", "餐飲業者管理", "", "LIC", true);
            AddAuth(list, ref sort, "EXT_CAT_INV2", 37, "複審", "餐飲業者管理", "", "LIC", true);
            AddAuth(list, ref sort, "EXT_CAT_INV3", 38, "三審", "餐飲業者管理", "", "LIC", true);
            AddAuth(list, ref sort, "EXT_CAT_STAT", 39, "統計", "餐飲業者管理", "", "LIC", true);
            AddAuth(list, ref sort, "EXT_CAT_EMISSION", 40, "排放量管理", "餐飲業者管理", "", "LIC", true);

            // 8-2. 觀光夜市管理 (寫入 UserAcc.LIC)
            AddAuth(list, ref sort, "EXT_NM_SURVEY", 31, "觀光夜市調查", "觀光夜市管理", "", "LIC", true);
            AddAuth(list, ref sort, "EXT_NM_INV1", 32, "初審", "觀光夜市管理", "", "LIC", true);
            AddAuth(list, ref sort, "EXT_NM_INV2", 33, "複審", "觀光夜市管理", "", "LIC", true);
            AddAuth(list, ref sort, "EXT_NM_INV3", 34, "三審", "觀光夜市管理", "", "LIC", true);
            AddAuth(list, ref sort, "EXT_NM_STAT", 35, "統計", "觀光夜市管理", "", "LIC", true);
            AddAuth(list, ref sort, "EXT_NM_EMISSION", 30, "排放量管理", "觀光夜市管理", "", "LIC", true);

            // 9. 油氣設施查核 (寫入 UserAcc.LIC2)
            AddAuth(list, ref sort, "EXT_GAS_SURVEY", 0, "油氣設施調查", "油氣設施查核", "", "LIC2", true);
            AddAuth(list, ref sort, "EXT_GAS_INV1", 1, "初審", "油氣設施查核", "", "LIC2", true);
            AddAuth(list, ref sort, "EXT_GAS_INV2", 2, "複審", "油氣設施查核", "", "LIC2", true);
            AddAuth(list, ref sort, "EXT_GAS_INV3", 3, "三審", "油氣設施查核", "", "LIC2", true);
            AddAuth(list, ref sort, "EXT_GAS_STAT", 4, "統計", "油氣設施查核", "", "LIC2", true);
            AddAuth(list, ref sort, "EXT_GAS_EMISSION", 5, "排放量管理", "油氣設施查核", "", "LIC2", true);

            return list;
        }

        private static void AddAuth(List<AuthItem> list, ref int sort, string code, int licId, string name, string group, string subGroup, string field, bool isExternal)
        {
            list.Add(new AuthItem
            {
                AuthCode = code,
                LicID = licId,
                LicName = name,
                Group = group,
                SubGroup = subGroup,
                FieldName = field,
                IsExternal = isExternal,
                SortOrder = sort++
            });
        }
    }
}
