﻿﻿using System;
using System.Data;
using System.Data.SqlClient;
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
    /// 首頁待辦統計核心服務 (連線資料庫提供真實統計數據)
    /// </summary>
    public static class PendingTaskService
    {
        /// <summary>
        /// 取得當前使用者的全模組待辦計數
        /// </summary>
        public static PendingTaskCounts GetPendingCounts(UserAccount user)
        {
            var counts = new PendingTaskCounts();
            string facId = (user != null && !string.IsNullOrEmpty(user.FacID)) ? user.FacID.Trim() : "";

            // 1. 查詢道路潔淨巡檢四大業務表待辦 (單一彙總 SQL，毫秒級響應)
            QueryRoadCleanCounts(counts);

            // 2. 查詢工廠現場稽查與任務派遣待辦 (INV_DATA, INV_Mission)
            QueryCaseCounts(counts);

            // 3. 查詢作業機具與裸露地待辦 (Machine_Main, Bare_INV)
            QueryMachineAndBareCounts(counts);

            // 4. 查詢自主管理回報待辦 (INV_Report)
            QueryOwnReportCounts(counts, facId);

            return counts;
        }

        // 1. 道路四大巡檢統計
        private static void QueryRoadCleanCounts(PendingTaskCounts counts)
        {
            try
            {
                string sql = @"
                    SELECT 
                        ISNULL((SELECT COUNT(1) FROM RoadClean_ChkRecord_Main WHERE Case_State IN (1001, 2201)), 0) AS RoadCleanDraft,
                        ISNULL((SELECT COUNT(1) FROM RoadClean_ChkRecord_Main WHERE Case_State = 2301), 0) AS RoadCleanBack,
                        ISNULL((SELECT COUNT(1) FROM RoadClean_ChkRecord_Main WHERE Case_State = 2001), 0) AS RoadCleanExamine,
                        ISNULL((SELECT COUNT(1) FROM RoadDirty_CaseMain WHERE SetCOM_Date IS NOT NULL AND Improve_Date IS NULL), 0) AS RoadDirtyImprove,
                        ISNULL((SELECT COUNT(1) FROM RoadBreak_CaseMain WHERE SetCOM_Date IS NOT NULL AND Improve_Date IS NULL), 0) AS RoadBreakImprove,
                        ISNULL((SELECT COUNT(1) FROM RoadBSC_CaseMain WHERE SetCOM_Date IS NOT NULL AND Improve_Date IS NULL), 0) AS RoadBSCImprove";

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

        // 2. 工廠巡查任務派遣統計
        private static void QueryCaseCounts(PendingTaskCounts counts)
        {
            try
            {
                string sql = @"
                    SELECT 
                        ISNULL((SELECT COUNT(1) FROM INV_DATA WHERE INV_State = 'A00a'), 0) AS CaseDraft,
                        ISNULL((SELECT COUNT(1) FROM INV_DATA WHERE INV_State = 'A00b' OR INV_State LIKE '%b%'), 0) AS CaseBack,
                        ISNULL((SELECT COUNT(1) FROM INV_DATA WHERE INV_State = 'A00'), 0) AS CaseInv1,
                        ISNULL((SELECT COUNT(1) FROM INV_DATA WHERE INV_State = 'A01'), 0) AS CaseInv2,
                        ISNULL((SELECT COUNT(1) FROM INV_DATA WHERE INV_State = 'A02'), 0) AS CaseInv3,
                        ISNULL((SELECT COUNT(1) FROM INV_Mission WHERE Cancel_Date IS NULL AND (pReason LIKE '%7天內未完成改善回報%' OR pReason LIKE '%7天%')), 0) AS CaseMission7Day,
                        ISNULL((SELECT COUNT(1) FROM INV_Mission WHERE Cancel_Date IS NULL AND pReason LIKE '%稽查列管%'), 0) AS CaseMission2Times";

                DataTable dt = DbHelper.ExecuteDataTable(sql);
                if (dt != null && dt.Rows.Count > 0)
                {
                    DataRow r = dt.Rows[0];
                    if (r["CaseDraft"] != DBNull.Value) counts.CaseDraft = Convert.ToInt32(r["CaseDraft"]);
                    if (r["CaseBack"] != DBNull.Value) counts.CaseBack = Convert.ToInt32(r["CaseBack"]);
                    if (r["CaseInv1"] != DBNull.Value) counts.CaseInv1 = Convert.ToInt32(r["CaseInv1"]);
                    if (r["CaseInv2"] != DBNull.Value) counts.CaseInv2 = Convert.ToInt32(r["CaseInv2"]);
                    if (r["CaseInv3"] != DBNull.Value) counts.CaseInv3 = Convert.ToInt32(r["CaseInv3"]);
                    if (r["CaseMission7Day"] != DBNull.Value) counts.CaseMission7Day = Convert.ToInt32(r["CaseMission7Day"]);
                    if (r["CaseMission2Times"] != DBNull.Value) counts.CaseMission2Times = Convert.ToInt32(r["CaseMission2Times"]);
                }
            }
            catch
            {
            }
        }

        // 3. 作業機具與裸露地統計
        private static void QueryMachineAndBareCounts(PendingTaskCounts counts)
        {
            try
            {
                string sql = @"
                    SELECT 
                        ISNULL((SELECT COUNT(1) FROM Machine_Main WHERE (Mac_State IN ('A00a', 'A00b') OR Mac_State IS NULL) AND (Deleted_mac IS NULL OR Deleted_mac <> 'Y')), 0) AS MachineDraft,
                        ISNULL((SELECT COUNT(1) FROM Machine_Main WHERE Mac_State = 'A00' AND (Deleted_mac IS NULL OR Deleted_mac <> 'Y')), 0) AS MachineInv1,
                        ISNULL((SELECT COUNT(1) FROM Machine_Main WHERE Mac_State = 'A01' AND (Deleted_mac IS NULL OR Deleted_mac <> 'Y')), 0) AS MachineInv2,
                        ISNULL((SELECT COUNT(1) FROM Machine_Main WHERE Mac_State = 'A02' AND (Deleted_mac IS NULL OR Deleted_mac <> 'Y')), 0) AS MachineInv3,
                        ISNULL((SELECT COUNT(1) FROM Bare_INV WHERE INV_State = 'A00a'), 0) AS BareDraft,
                        ISNULL((SELECT COUNT(1) FROM Bare_INV WHERE INV_State = 'A00b'), 0) AS BareBack,
                        ISNULL((SELECT COUNT(1) FROM Bare_INV WHERE INV_State = 'A00'), 0) AS BareInv1,
                        ISNULL((SELECT COUNT(1) FROM Bare_INV WHERE INV_State = 'A01'), 0) AS BareInv2,
                        ISNULL((SELECT COUNT(1) FROM Bare_INV WHERE INV_State = 'A02'), 0) AS BareInv3";

                DataTable dt = DbHelper.ExecuteDataTable(sql);
                if (dt != null && dt.Rows.Count > 0)
                {
                    DataRow r = dt.Rows[0];
                    if (r["MachineDraft"] != DBNull.Value) counts.MachineDraft = Convert.ToInt32(r["MachineDraft"]);
                    if (r["MachineInv1"] != DBNull.Value) counts.MachineInv1 = Convert.ToInt32(r["MachineInv1"]);
                    if (r["MachineInv2"] != DBNull.Value) counts.MachineInv2 = Convert.ToInt32(r["MachineInv2"]);
                    if (r["MachineInv3"] != DBNull.Value) counts.MachineInv3 = Convert.ToInt32(r["MachineInv3"]);
                    counts.MachineExamine = counts.MachineInv1;
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
                    // 管理端：統計近 30 天內提報案件
                    string sql = @"
                        SELECT 
                            ISNULL((SELECT COUNT(1) FROM INV_Report WHERE Report_Type = '自主回報' AND Report_Date >= DATEADD(day, -30, GETDATE())), 0) AS OwnCount,
                            ISNULL((SELECT COUNT(1) FROM INV_Report WHERE Report_Type = '缺失改善' AND Report_Date >= DATEADD(day, -30, GETDATE())), 0) AS WrongCount";

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
