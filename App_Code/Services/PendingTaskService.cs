using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Text;
using System.Web;
using NTPC_FEC.Helpers;
using NTPC_FEC.Models;

namespace NTPC_FEC.Services
{
    /// <summary>
    /// 首頁待辦事項統計資料模型
    /// </summary>
    public class PendingTaskCounts
    {
        // 1. 巡查任務派遣
        public int CaseDraft { get; set; }          // 查核暫存 (A00a)
        public int CaseBack { get; set; }           // 退件紀錄 (A00b)
        public int CaseInv1 { get; set; }           // 案件初審 (INV1)
        public int CaseInv2 { get; set; }           // 案件複審 (INV2)
        public int CaseInv3 { get; set; }           // 案件三審 (INV3)
        public int CaseMission7Day { get; set; }    // 巡查派遣 (7天內改善)
        public int CaseMission2Times { get; set; }  // 提報稽查 (稽查列管)
        public int CaseProject { get; set; }        // 臺北港專區 (八里區場所數: 24)

        // 2. 作業機具調查
        public int MachineDraft { get; set; }       // 機具暫存
        public int MachineExamine { get; set; }     // 機具審核 (相容舊屬性)
        public int MachineInv1 { get; set; }        // 機具初審 (A00 - MAC1)
        public int MachineInv2 { get; set; }        // 機具複審 (A01 - MAC2)
        public int MachineInv3 { get; set; }        // 機具三審 (A02 - MAC3)

        // 3. 裸露地調查
        public int BareDraft { get; set; }          // 裸露地暫存 (A00a)
        public int BareBack { get; set; }           // 裸露地退件 (A00b)
        public int BareInv1 { get; set; }           // 裸露地初審 (A00)
        public int BareInv2 { get; set; }           // 裸露地複審 (A01)
        public int BareInv3 { get; set; }           // 裸露地三審 (A02)

        // 4. 自主管理回報
        public int OwnReportCount { get; set; }     // 自主維護回報件數
        public int WrongReportCount { get; set; }   // 缺失改善回報件數

        // 5. 道路潔淨巡檢
        public int RoadCleanDraft { get; set; }     // 道路潔淨暫存 (1001, 2201)
        public int RoadCleanBack { get; set; }      // 道路潔淨退回補正 (2301)
        public int RoadCleanExamine { get; set; }   // 道路潔淨待審核 (2001)
        public int RoadDirtyImprove { get; set; }   // 道路髒污待改善
        public int RoadBreakImprove { get; set; }   // 道路破損待改善
        public int RoadBSCImprove { get; set; }     // 覆土管考待改善
    }

    /// <summary>
    /// 首頁待辦統計核心服務 (連線資料庫提供真實統計數據，支援30秒快取與轄區過濾)
    /// </summary>
    public static class PendingTaskService
    {
        private const string CachePrefix = "PENDING_COUNTS_";

        /// <summary>
        /// 清除待辦統計快取 (特定使用者或全體)
        /// </summary>
        public static void ClearPendingCountsCache(string userId = null)
        {
            try
            {
                if (HttpRuntime.Cache == null) return;

                if (string.IsNullOrEmpty(userId))
                {
                    System.Collections.IDictionaryEnumerator enumerator = HttpRuntime.Cache.GetEnumerator();
                    List<string> keysToRemove = new List<string>();
                    while (enumerator.MoveNext())
                    {
                        string key = enumerator.Key.ToString();
                        if (key.StartsWith(CachePrefix))
                        {
                            keysToRemove.Add(key);
                        }
                    }
                    foreach (string k in keysToRemove)
                    {
                        HttpRuntime.Cache.Remove(k);
                    }
                }
                else
                {
                    HttpRuntime.Cache.Remove(CachePrefix + userId.Trim().ToUpper());
                }
            }
            catch { }
        }

        /// <summary>
        /// 取得當前使用者的全模組待辦計數 (含30秒記憶體快取與鄉鎮轄區分流)
        /// </summary>
        public static PendingTaskCounts GetPendingCounts(UserAccount user)
        {
            string userId = (user != null && !string.IsNullOrEmpty(user.UserID)) ? user.UserID.Trim().ToUpper() : "ANON";
            string cacheKey = CachePrefix + userId;

            // 1. 嘗試從快取讀取
            if (HttpRuntime.Cache != null)
            {
                var cached = HttpRuntime.Cache[cacheKey] as PendingTaskCounts;
                if (cached != null)
                {
                    return cached;
                }
            }

            var counts = new PendingTaskCounts();
            string facId = (user != null && !string.IsNullOrEmpty(user.FacID)) ? user.FacID.Trim() : "";

            // 取得轄區過濾代碼與鄉鎮名稱 (若為空清單代表具全市全部權限)
            List<string> townNos = new List<string>();
            List<string> townNames = new List<string>();
            if (user != null && !string.IsNullOrEmpty(user.UserID) && !user.UserID.Equals("admin", StringComparison.OrdinalIgnoreCase))
            {
                townNos = PermissionService.GetUserTownNos(user.UserID);
                townNames = PermissionService.GetUserTowns(user.UserID);
            }

            // 1. 查詢道路潔淨巡檢四大業務表待辦
            QueryRoadCleanCounts(counts, townNos, townNames);

            // 2. 查詢工廠現場稽查與任務派遣待辦 (INV_DATA, INV_Mission)
            QueryCaseCounts(counts, townNos);

            // 3. 查詢作業機具與裸露地待辦 (Machine_Main, Bare_INV)
            QueryMachineAndBareCounts(counts, townNos);

            // 4. 查詢自主管理回報待辦 (INV_Report)
            QueryOwnReportCounts(counts, facId);

            // 5. 存入記憶體快取 (30秒絕對過期)
            if (HttpRuntime.Cache != null)
            {
                HttpRuntime.Cache.Insert(
                    cacheKey,
                    counts,
                    null,
                    DateTime.Now.AddSeconds(30),
                    System.Web.Caching.Cache.NoSlidingExpiration
                );
            }

            return counts;
        }

        // 輔助方法：生成 SQL IN 條件字串
        private static string BuildSqlInList(List<string> items)
        {
            if (items == null || items.Count == 0) return "";
            var escaped = new List<string>();
            foreach (var item in items)
            {
                if (!string.IsNullOrEmpty(item))
                {
                    escaped.Add("'" + item.Replace("'", "''") + "'");
                }
            }
            return string.Join(",", escaped.ToArray());
        }

        // 1. 道路四大巡檢統計 (支援鄉鎮名稱與代號過濾)
        private static void QueryRoadCleanCounts(PendingTaskCounts counts, List<string> townNos, List<string> townNames)
        {
            try
            {
                string inNos = BuildSqlInList(townNos);
                string inNames = BuildSqlInList(townNames);

                string whereRc = "";
                string whereDirty = "";
                string whereBreak = "";
                string whereBsc = "";

                if (!string.IsNullOrEmpty(inNames))
                {
                    whereRc = string.Format(" AND R.TOWN IN ({0})", inNames);
                }

                if (!string.IsNullOrEmpty(inNos))
                {
                    whereDirty = string.Format(" AND TOWN_CODE IN ({0})", inNos);
                    whereBreak = string.Format(" AND TOWN_CODE IN ({0})", inNos);
                    whereBsc = string.Format(" AND TOWN_CODE IN ({0})", inNos);
                }

                string sql = string.Format(@"
                    SELECT 
                        ISNULL((SELECT COUNT(1) FROM RoadClean_ChkRecord_Main M LEFT JOIN RoadClean_CheckPointMain R ON M.ChkRoadID = R.RDID WHERE M.Case_State IN (1001, 2201){0}), 0) AS RoadCleanDraft,
                        ISNULL((SELECT COUNT(1) FROM RoadClean_ChkRecord_Main M LEFT JOIN RoadClean_CheckPointMain R ON M.ChkRoadID = R.RDID WHERE M.Case_State = 2301{0}), 0) AS RoadCleanBack,
                        ISNULL((SELECT COUNT(1) FROM RoadClean_ChkRecord_Main M LEFT JOIN RoadClean_CheckPointMain R ON M.ChkRoadID = R.RDID WHERE M.Case_State = 2001{0}), 0) AS RoadCleanExamine,
                        ISNULL((SELECT COUNT(1) FROM RoadDirty_CaseMain WHERE SetCOM_Date IS NOT NULL AND Improve_Date IS NULL{1}), 0) AS RoadDirtyImprove,
                        ISNULL((SELECT COUNT(1) FROM RoadBreak_CaseMain WHERE SetCOM_Date IS NOT NULL AND Improve_Date IS NULL{2}), 0) AS RoadBreakImprove,
                        ISNULL((SELECT COUNT(1) FROM RoadBSC_CaseMain WHERE SetCOM_Date IS NOT NULL AND Improve_Date IS NULL{3}), 0) AS RoadBSCImprove",
                    whereRc, whereDirty, whereBreak, whereBsc);

                DataTable dt = DbHelper.ExecuteDataTable(sql);
                if (dt != null && dt.Rows.Count > 0)
                {
                    DataRow r = dt.Rows[0];
                    if (r["RoadCleanDraft"] != DBNull.Value) counts.RoadCleanDraft = Convert.ToInt32(r["RoadCleanDraft"]);
                    if (r["RoadCleanBack"] != DBNull.Value) counts.RoadCleanBack = Convert.ToInt32(r["RoadCleanBack"]);
                    if (r["RoadCleanExamine"] != DBNull.Value) counts.RoadCleanExamine = Convert.ToInt32(r["RoadCleanExamine"]);
                    if (r["RoadDirtyImprove"] != DBNull.Value) counts.RoadDirtyImprove = Convert.ToInt32(r["RoadDirtyImprove"]);
                    if (r["RoadBreakImprove"] != DBNull.Value) counts.RoadBreakImprove = Convert.ToInt32(r["RoadBreakImprove"]);
                    if (r["RoadBSCImprove"] != DBNull.Value) counts.RoadBSCImprove = Convert.ToInt32(r["RoadBSCImprove"]);
                }
            }
            catch
            {
                // 容錯防護：資料表異常不中斷首頁載入
            }
        }

        // 2. 工廠巡查任務派遣統計 (支援鄉鎮過濾)
        private static void QueryCaseCounts(PendingTaskCounts counts, List<string> townNos)
        {
            // 查詢工廠巡查待審件數 (與審查平台 Get_Check_INV_FAC_Main_BySearch 100% 同源同標準)
            counts.CaseInv1 = QueryInvCasesBySp("A00", townNos); // 初審待審 (INV1)
            counts.CaseInv2 = QueryInvCasesBySp("A01", townNos); // 複審待審 (INV2)
            counts.CaseInv3 = QueryInvCasesBySp("A02", townNos); // 三審待審 (INV3)

            try
            {
                string inNos = BuildSqlInList(townNos);
                string filterFac = "";
                string filterBali = "";

                if (!string.IsNullOrEmpty(inNos))
                {
                    filterFac = string.Format(" AND f.TOWN_NO IN ({0})", inNos);
                    // 八里區代號為 24
                    if (!townNos.Contains("24"))
                    {
                        filterBali = " AND 1=0"; // 非八里轄區承辦人不計入八里專案
                    }
                }

                string sql = string.Format(@"
                    SELECT 
                        ISNULL((SELECT COUNT(1) FROM INV_DATA d INNER JOIN FAC_Main f ON d.FAC_ID = f.FAC_ID WHERE d.INV_State = 'A00a'{0}), 0) AS CaseDraft,
                        ISNULL((SELECT COUNT(1) FROM INV_DATA d INNER JOIN FAC_Main f ON d.FAC_ID = f.FAC_ID WHERE d.INV_State = 'A00b'{0}), 0) AS CaseBack,
                        ISNULL((SELECT COUNT(1) FROM INV_Mission m INNER JOIN FAC_Main f ON m.FAC_ID = f.FAC_ID WHERE m.Cancel_Date IS NULL AND (m.pReason LIKE '%7天內未完成改善回報%' OR m.pReason LIKE '%7天%'){0}), 0) AS CaseMission7Day,
                        ISNULL((SELECT COUNT(1) FROM INV_Mission m INNER JOIN FAC_Main f ON m.FAC_ID = f.FAC_ID WHERE m.Cancel_Date IS NULL AND m.pReason LIKE '%稽查列管%'{0}), 0) AS CaseMission2Times,
                        ISNULL((SELECT COUNT(1) FROM FAC_Main WHERE (TOWN LIKE '%八里%' OR ADDR LIKE '%八里%'){1}), 0) AS CaseProject",
                    filterFac, filterBali);

                DataTable dt = DbHelper.ExecuteDataTable(sql);
                if (dt != null && dt.Rows.Count > 0)
                {
                    DataRow r = dt.Rows[0];
                    if (r["CaseDraft"] != DBNull.Value) counts.CaseDraft = Convert.ToInt32(r["CaseDraft"]);
                    if (r["CaseBack"] != DBNull.Value) counts.CaseBack = Convert.ToInt32(r["CaseBack"]);
                    if (r["CaseMission7Day"] != DBNull.Value) counts.CaseMission7Day = Convert.ToInt32(r["CaseMission7Day"]);
                    if (r["CaseMission2Times"] != DBNull.Value) counts.CaseMission2Times = Convert.ToInt32(r["CaseMission2Times"]);
                    if (r["CaseProject"] != DBNull.Value) counts.CaseProject = Convert.ToInt32(r["CaseProject"]);
                }
            }
            catch
            {
            }
        }

        // 輔助方法：呼叫與 managerList.aspx 完全一致之預存程序統計有效場所營建巡查待審案件數
        private static int QueryInvCasesBySp(string stateCode, List<string> townNos)
        {
            int totalCases = 0;
            string colName = "初審件數";
            if (stateCode == "A01") colName = "複審件數";
            else if (stateCode == "A02") colName = "三審件數";

            HashSet<string> townSet = (townNos != null && townNos.Count > 0) ? new HashSet<string>(townNos) : null;

            try
            {
                using (SqlConnection conn = DbHelper.GetOpenConnection())
                using (SqlCommand cmd = new SqlCommand("Get_Check_INV_FAC_Main_BySearch", conn))
                {
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.CommandTimeout = 30;
                    cmd.Parameters.Add(new SqlParameter("@Where_FAC_NAME", DBNull.Value));
                    cmd.Parameters.Add(new SqlParameter("@Where_C_NO", DBNull.Value));
                    cmd.Parameters.Add(new SqlParameter("@Where_S_C_ID", DBNull.Value));
                    cmd.Parameters.Add(new SqlParameter("@Where_INV_State", stateCode));
                    cmd.Parameters.Add(new SqlParameter("@CountColName", colName));

                    using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                    {
                        DataTable dt = new DataTable();
                        da.Fill(dt);
                        foreach (DataRow row in dt.Rows)
                        {
                            if (townSet != null && row.Table.Columns.Contains("TOWN_CODE") && row["TOWN_CODE"] != DBNull.Value)
                            {
                                string tcode = row["TOWN_CODE"].ToString().Trim();
                                if (!townSet.Contains(tcode))
                                {
                                    continue;
                                }
                            }

                            int c = 0;
                            if (row.Table.Columns.Contains("Case_Count") && row["Case_Count"] != DBNull.Value)
                            {
                                int.TryParse(row["Case_Count"].ToString(), out c);
                            }
                            else if (row.Table.Columns.Contains(colName) && row[colName] != DBNull.Value)
                            {
                                int.TryParse(row[colName].ToString(), out c);
                            }
                            else if (row.Table.Columns.Contains("件數") && row["件數"] != DBNull.Value)
                            {
                                int.TryParse(row["件數"].ToString(), out c);
                            }
                            totalCases += c;
                        }
                    }
                }
            }
            catch
            {
                try
                {
                    string whereTown = "";
                    if (townSet != null)
                    {
                        string inNos = BuildSqlInList(townNos);
                        if (!string.IsNullOrEmpty(inNos))
                        {
                            whereTown = string.Format(" AND f.TOWN_NO IN ({0})", inNos);
                        }
                    }

                    string sql = string.Format(@"
                        SELECT COUNT(d.INV_NO) 
                        FROM INV_DATA d
                        INNER JOIN FAC_Main f ON d.FAC_ID = f.FAC_ID
                        WHERE d.INV_State = @StateCode{0}", whereTown);
                    object obj = DbHelper.ExecuteScalar(sql, new SqlParameter("@StateCode", stateCode));
                    if (obj != null && obj != DBNull.Value)
                    {
                        totalCases = Convert.ToInt32(obj);
                    }
                }
                catch { }
            }
            return totalCases;
        }

        // 3. 作業機具與裸露地統計 (支援鄉鎮過濾)
        private static void QueryMachineAndBareCounts(PendingTaskCounts counts, List<string> townNos)
        {
            // 查詢施工機具待審件數 (與審查平台 Get_Check_Mac_FAC_Main_BySearch 100% 同源同標準)
            counts.MachineInv1 = QueryMachineCasesBySp("A00", townNos); // 初審待審 (MAC1)
            counts.MachineInv2 = QueryMachineCasesBySp("A01", townNos); // 複審待審 (MAC2)
            counts.MachineInv3 = QueryMachineCasesBySp("A02", townNos); // 三審待審 (MAC3)
            counts.MachineExamine = counts.MachineInv1;

            try
            {
                string inNos = BuildSqlInList(townNos);
                string filterMac = "";
                string filterBare = "";

                if (!string.IsNullOrEmpty(inNos))
                {
                    filterMac = string.Format(" AND f.TOWN_NO IN ({0})", inNos);
                    filterBare = string.Format(" AND TOWN_NO IN ({0})", inNos);
                }

                string sql = string.Format(@"
                    SELECT 
                        ISNULL((SELECT COUNT(1) FROM Machine_Main m INNER JOIN FAC_Main f ON m.FAC_ID = f.FAC_ID WHERE (m.Mac_State IN ('A00a', 'A00b') OR m.Mac_State IS NULL) AND (m.Deleted_mac IS NULL OR m.Deleted_mac <> 'Y'){0}), 0) AS MachineDraft,
                        ISNULL((SELECT COUNT(1) FROM Bare_INV WHERE INV_State = 'A00a'{1}), 0) AS BareDraft,
                        ISNULL((SELECT COUNT(1) FROM Bare_INV WHERE INV_State = 'A00b'{1}), 0) AS BareBack,
                        ISNULL((SELECT COUNT(1) FROM Bare_INV WHERE INV_State = 'A00'{1}), 0) AS BareInv1,
                        ISNULL((SELECT COUNT(1) FROM Bare_INV WHERE INV_State = 'A01'{1}), 0) AS BareInv2,
                        ISNULL((SELECT COUNT(1) FROM Bare_INV WHERE INV_State = 'A02'{1}), 0) AS BareInv3",
                    filterMac, filterBare);

                DataTable dt = DbHelper.ExecuteDataTable(sql);
                if (dt != null && dt.Rows.Count > 0)
                {
                    DataRow r = dt.Rows[0];
                    if (r["MachineDraft"] != DBNull.Value) counts.MachineDraft = Convert.ToInt32(r["MachineDraft"]);
                    if (r["BareDraft"] != DBNull.Value) counts.BareDraft = Convert.ToInt32(r["BareDraft"]);
                    if (r["BareBack"] != DBNull.Value) counts.BareBack = Convert.ToInt32(r["BareBack"]);
                    if (r["BareInv1"] != DBNull.Value) counts.BareInv1 = Convert.ToInt32(r["BareInv1"]);
                    if (r["BareInv2"] != DBNull.Value) counts.BareInv2 = Convert.ToInt32(r["BareInv2"]);
                    if (r["BareInv3"] != DBNull.Value) counts.BareInv3 = Convert.ToInt32(r["BareInv3"]);
                }
            }
            catch
            {
            }
        }

        // 輔助方法：呼叫與 managerList.aspx 完全一致之預存程序統計有效場所待審機具數
        private static int QueryMachineCasesBySp(string stateCode, List<string> townNos)
        {
            int totalCases = 0;
            string colName = "初審件數";
            if (stateCode == "A01") colName = "複審件數";
            else if (stateCode == "A02") colName = "三審件數";

            HashSet<string> townSet = (townNos != null && townNos.Count > 0) ? new HashSet<string>(townNos) : null;

            try
            {
                using (SqlConnection conn = DbHelper.GetOpenConnection())
                using (SqlCommand cmd = new SqlCommand("Get_Check_Mac_FAC_Main_BySearch", conn))
                {
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.CommandTimeout = 30;
                    cmd.Parameters.Add(new SqlParameter("@Where_FAC_NAME", DBNull.Value));
                    cmd.Parameters.Add(new SqlParameter("@Where_C_NO", DBNull.Value));
                    cmd.Parameters.Add(new SqlParameter("@Where_S_C_ID", DBNull.Value));
                    cmd.Parameters.Add(new SqlParameter("@Where_Mac_State", stateCode));
                    cmd.Parameters.Add(new SqlParameter("@CountColName", colName));

                    using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                    {
                        DataTable dt = new DataTable();
                        da.Fill(dt);
                        foreach (DataRow row in dt.Rows)
                        {
                            if (townSet != null && row.Table.Columns.Contains("TOWN_CODE") && row["TOWN_CODE"] != DBNull.Value)
                            {
                                string tcode = row["TOWN_CODE"].ToString().Trim();
                                if (!townSet.Contains(tcode))
                                {
                                    continue;
                                }
                            }

                            int c = 0;
                            if (row.Table.Columns.Contains("Case_Count") && row["Case_Count"] != DBNull.Value)
                            {
                                int.TryParse(row["Case_Count"].ToString(), out c);
                            }
                            else if (row.Table.Columns.Contains(colName) && row[colName] != DBNull.Value)
                            {
                                int.TryParse(row[colName].ToString(), out c);
                            }
                            else if (row.Table.Columns.Contains("件數") && row["件數"] != DBNull.Value)
                            {
                                int.TryParse(row["件數"].ToString(), out c);
                            }
                            totalCases += c;
                        }
                    }
                }
            }
            catch
            {
                try
                {
                    string whereTown = "";
                    if (townSet != null)
                    {
                        string inNos = BuildSqlInList(townNos);
                        if (!string.IsNullOrEmpty(inNos))
                        {
                            whereTown = string.Format(" AND f.TOWN_NO IN ({0})", inNos);
                        }
                    }

                    string sql = string.Format(@"
                        SELECT COUNT(m.mac_ID) 
                        FROM Machine_Main m
                        INNER JOIN FAC_Main f ON m.FAC_ID = f.FAC_ID
                        WHERE m.Mac_State = @StateCode 
                          AND (m.Deleted_mac IS NULL OR m.Deleted_mac <> 'Y'){0}", whereTown);
                    object obj = DbHelper.ExecuteScalar(sql, new SqlParameter("@StateCode", stateCode));
                    if (obj != null && obj != DBNull.Value)
                    {
                        totalCases = Convert.ToInt32(obj);
                    }
                }
                catch { }
            }
            return totalCases;
        }

        // 4. 自主管理回報統計
        private static void QueryOwnReportCounts(PendingTaskCounts counts, string facId)
        {
            try
            {
                DataTable dt = null;
                if (!string.IsNullOrEmpty(facId))
                {
                    // 業者登入：統計該場所近期之自主與缺失改善申報
                    string sql = @"
                        SELECT 
                            ISNULL((SELECT COUNT(1) FROM INV_Report WHERE FAC_ID = @FAC_ID AND Report_Type = '自主回報'), 0) AS OwnCount,
                            ISNULL((SELECT COUNT(1) FROM INV_Report WHERE FAC_ID = @FAC_ID AND Report_Type = '缺失改善'), 0) AS WrongCount";

                    dt = DbHelper.ExecuteDataTable(sql, new SqlParameter("@FAC_ID", facId));
                }
                else
                {
                    // 管理端：統計全站之自主與缺失改善申報總案件數 (與 PIC_Report_List.aspx 100% 同源同標準)
                    string sql = @"
                        SELECT 
                            ISNULL((SELECT COUNT(1) FROM INV_Report WHERE Report_Type = '自主回報'), 0) AS OwnCount,
                            ISNULL((SELECT COUNT(1) FROM INV_Report WHERE Report_Type = '缺失改善'), 0) AS WrongCount";

                    dt = DbHelper.ExecuteDataTable(sql);
                }

                if (dt != null && dt.Rows.Count > 0)
                {
                    DataRow r = dt.Rows[0];
                    if (r["OwnCount"] != DBNull.Value) counts.OwnReportCount = Convert.ToInt32(r["OwnCount"]);
                    if (r["WrongCount"] != DBNull.Value) counts.WrongReportCount = Convert.ToInt32(r["WrongCount"]);
                }
            }
            catch
            {
            }
        }
    }
}
