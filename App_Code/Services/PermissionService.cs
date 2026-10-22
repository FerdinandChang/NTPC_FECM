using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using NTPC_FEC.Helpers;

namespace NTPC_FEC.Services
{
    public class AuthItem
    {
        public int LicID { get; set; }
        public string LicName { get; set; }
        public string Group { get; set; }
        public string FieldName { get; set; } // "LIC" 或 "LIC2"
    }

    public class TownItem
    {
        public string TownNo { get; set; }
        public string TownName { get; set; }
    }

    public class PermissionService
    {
        // 取得所有系統權限項目 (資料庫優先，內建標準設定作為穩健備援)
        public static List<AuthItem> GetAuthItems()
        {
            var list = new List<AuthItem>();
            try
            {
                string sql = "SELECT Lic_ID, Lic_Name, [Group], FieldName FROM Auth_List ORDER BY FieldName, Lic_ID";
                DataTable dt = DbHelper.ExecuteDataTable(sql);
                if (dt != null && dt.Rows.Count > 0)
                {
                    foreach (DataRow row in dt.Rows)
                    {
                        int licId = 0;
                        int.TryParse((row["Lic_ID"] != null ? row["Lic_ID"].ToString() : ""), out licId);
                        list.Add(new AuthItem
                        {
                            LicID = licId,
                            LicName = ((row["Lic_Name"] != null && row["Lic_Name"] != DBNull.Value) ? row["Lic_Name"].ToString() : ""),
                            Group = ((row["Group"] != null && row["Group"] != DBNull.Value) ? row["Group"].ToString() : "其他"),
                            FieldName = ((row["FieldName"] != null && row["FieldName"] != DBNull.Value) ? row["FieldName"].ToString() : "LIC")
                        });
                    }
                    return list;
                }
            }
            catch
            {
                // 若資料庫離線，啟用備援權限項目
            }

            // 內建標準清單 (與舊系統截圖架構 100% 一致)
            return GetDefaultAuthItems();
        }

        // 依據使用者 LIC / LIC2 位元碼解析擁有權限的群組化字典
        public static Dictionary<string, List<string>> GetUserPermissionGroups(long lic, long lic2)
        {
            var authItems = GetAuthItems();
            var dict = new Dictionary<string, List<string>>();

            foreach (var item in authItems)
            {
                bool hasPermission = false;
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

                if (hasPermission)
                {
                    if (!dict.ContainsKey(item.Group))
                    {
                        dict[item.Group] = new List<string>();
                    }
                    dict[item.Group].Add(item.LicName);
                }
            }

            return dict;
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

            // 備援新北 29 區清單
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
                if (id >= 0 && id < 63)
                {
                    val |= (1L << id);
                }
            }
            return val;
        }

        private static void AddItem(List<AuthItem> items, int id, string group, string name, string field = "LIC")
        {
            items.Add(new AuthItem { LicID = id, Group = group, LicName = name, FieldName = field });
        }

        // 預設備援標準權限資料
        private static List<AuthItem> GetDefaultAuthItems()
        {
            var items = new List<AuthItem>();



            // 空間資訊整合
            AddItem(items, 41, "空間資訊整合", "空間資訊查詢");

            // 裸露地管理
            AddItem(items, 17, "裸露地管理", "裸露地調查");
            AddItem(items, 18, "裸露地管理", "初審");
            AddItem(items, 19, "裸露地管理", "複審");
            AddItem(items, 20, "裸露地管理", "三審");
            AddItem(items, 44, "裸露地管理", "資料查詢");

            // 機具資料調查審核
            AddItem(items, 1, "機具資料調查審核", "作業機具調查");
            AddItem(items, 6, "機具資料調查審核", "初審");
            AddItem(items, 43, "機具資料調查審核", "資料查詢");

            // 防制設施查核審核
            AddItem(items, 0, "防制設施查核審核", "防制設施查核");
            AddItem(items, 3, "防制設施查核審核", "初審");
            AddItem(items, 4, "防制設施查核審核", "複審");
            AddItem(items, 5, "防制設施查核審核", "三審");
            AddItem(items, 42, "防制設施查核審核", "資料查詢");

            // 固定污染源場所管理
            AddItem(items, 2, "固定污染源場所管理", "基本資料差異維護");
            AddItem(items, 10, "固定污染源場所管理", "許可證登記資料查詢");
            AddItem(items, 11, "固定污染源場所管理", "資料查詢");

            // 道路髒污管理
            AddItem(items, 21, "道路髒污管理", "道路髒污通報");
            AddItem(items, 22, "道路髒污管理", "髒污改善回報指派");
            AddItem(items, 23, "道路髒污管理", "道路髒污改善回報");
            AddItem(items, 24, "道路髒污管理", "統計查詢");

            // 道路破損與人行道
            AddItem(items, 26, "道路破損管理", "道路破損通報");
            AddItem(items, 27, "道路破損管理", "破損改善成果");
            AddItem(items, 28, "人行道與交通島管理", "裸露覆土通報");
            AddItem(items, 29, "人行道與交通島管理", "覆土改善成果");

            // 觀光夜市管理
            AddItem(items, 31, "觀光夜市管理", "觀光夜市調查");
            AddItem(items, 32, "觀光夜市管理", "初審");
            AddItem(items, 33, "觀光夜市管理", "複審");
            AddItem(items, 34, "觀光夜市管理", "三審");
            AddItem(items, 35, "觀光夜市管理", "統計");

            // 自主管理與洗掃
            AddItem(items, 8, "自主回報管理", "自主維護回報");
            AddItem(items, 9, "自主回報管理", "維護紀錄審查");
            AddItem(items, 12, "道路洗掃認養管理", "道路洗掃回報");
            AddItem(items, 13, "道路洗掃認養管理", "洗掃報表回傳");
            AddItem(items, 14, "道路洗掃認養管理", "洗掃紀錄審核");
            AddItem(items, 15, "防制設施缺失改善管理", "缺失改善回報");
            AddItem(items, 16, "防制設施缺失改善管理", "改善紀錄審核");
            AddItem(items, 45, "空品不良應變管理", "空品應變回報與列表");

            // 最高系統管理者旗標
            AddItem(items, 63, "系統維運管理", "全系統最高管理權限", "LIC");

            return items;
        }
    }
}
