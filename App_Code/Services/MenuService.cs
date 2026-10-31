using System;
using System.Collections.Generic;
using NTPC_FEC.Models;

namespace NTPC_FEC.Services
{
    public class MenuService
    {
        public static bool CheckLicense(long userLic, int licIndex)
        {
            if (licIndex < 0 || licIndex >= 64) return false;
            return (userLic & (1L << licIndex)) != 0;
        }

        private static void AddSubItemIfAllowed(List<MenuSubItem> items, bool isAllowed, string title, string url, int badgeCount = 0, bool showZero = false, string category = "")
        {
            if (isAllowed)
            {
                items.Add(new MenuSubItem
                {
                    Title = title,
                    Url = url,
                    BadgeCount = badgeCount,
                    ShowZero = showZero,
                    Category = category
                });
            }
        }

        public static List<MenuModule> GetUserModules(UserAccount user)
        {
            var list = new List<MenuModule>();
            long lic = user != null ? user.Lic : 0L;
            long lic2 = user != null ? user.Lic2 : 0L;
            int uid = user != null ? user.UID : 0;
            string userId = user != null ? (user.UserID ?? "") : "";

            bool isAdmin = (userId.ToLower() == "admin") || CheckLicense(lic, 63);

            // 取得各業務模組待辦真實統計數量
            PendingTaskCounts pending = PendingTaskService.GetPendingCounts(user);

            // 1. 工廠基本資料 (深海軍藍)
            var facItems = new List<MenuSubItem>();
            AddSubItemIfAllowed(facItems, isAdmin || PermissionService.HasPermission(userId, lic, "FAC_LIST_READ", 41) || PermissionService.HasPermission(userId, lic, "FAC_LIST_READ", 2), "逸散源列管", "FAC/FAC_List.aspx?mode=read");
            AddSubItemIfAllowed(facItems, isAdmin || PermissionService.HasPermission(userId, lic, "FAC_LIST_EDIT", 2), "逸散源未列管", "FAC/FAC_List.aspx?mode=edit");
            AddSubItemIfAllowed(facItems, isAdmin || PermissionService.HasPermission(userId, lic, "FAC_LICENSE_QUERY", 10) || PermissionService.HasPermission(userId, lic, "FAC_LICENSE_QUERY", 41), "許可證資訊", "FAC/oFAC_List.aspx");
            AddSubItemIfAllowed(facItems, isAdmin || PermissionService.HasPermission(userId, lic, "FAC_OUTLINK_QUERY", 11) || PermissionService.HasPermission(userId, lic, "FAC_OUTLINK_QUERY", 41), "相關外部系統連結", "OutLink.aspx");
            AddSubItemIfAllowed(facItems, isAdmin || PermissionService.HasPermission(userId, lic, "FAC_STATS", 41), "公私場所逸散源統計分析", "FAC/Charts.aspx");
            AddSubItemIfAllowed(facItems, isAdmin || PermissionService.HasPermission(userId, lic, "FAC_BUFFER_MAP", 41), "環域查詢", "BufferAnalysis/BufferMap.aspx");

            if (facItems.Count > 0)
            {
                list.Add(new MenuModule
                {
                    Id = "FAC",
                    Title = "工廠基本資料",
                    SubTitle = "列管廠場基本檔、許可證資訊與統計查詢",
                    Url = facItems[0].Url,
                    BgColor = "#24405E",
                    BadgeCount = 0,
                    IconSvg = @"<svg viewBox='0 0 24 24' width='64' height='64' fill='currentColor'><path d='M4 19h16v2H4zm0-4h2v2H4zm4 0h2v2H8zm4 0h2v2h-2zm4 0h2v2h-2zM4 10h2v2H4zm4 0h2v2H8zm4 0h2v2h-2zm4 0h2v2h-2zM2 22h20V8l-6 4V4l-6 4V2H2v20z'/></svg>",
                    SubItems = facItems
                });
            }

            // 2. 巡查任務派遣 (青藍灰)
            var caseItems = new List<MenuSubItem>();
            AddSubItemIfAllowed(caseItems, isAdmin || PermissionService.HasPermission(userId, lic, "CASE_CHECK_RUN", 0), "防制作業查核", "Case/CaseList.aspx");
            AddSubItemIfAllowed(caseItems, isAdmin || PermissionService.HasPermission(userId, lic, "CASE_DRAFT_VIEW", 0), "查核紀錄暫存", "Case/CaseList.aspx?mode=reject", pending.CaseDraft);
            AddSubItemIfAllowed(caseItems, isAdmin || PermissionService.HasPermission(userId, lic, "CASE_BACK_LIST", 0), "退件紀錄", "Case/CaseList.aspx?mode=back", pending.CaseBack, true);
            AddSubItemIfAllowed(caseItems, isAdmin || PermissionService.HasPermission(userId, lic, "CASE_INV1", 3), "案件初審", "Manager/managerList.aspx?INV_State=INV1", pending.CaseInv1, true);
            AddSubItemIfAllowed(caseItems, isAdmin || PermissionService.HasPermission(userId, lic, "CASE_INV2", 4), "案件複審", "Manager/managerList.aspx?INV_State=INV2", pending.CaseInv2, true);
            AddSubItemIfAllowed(caseItems, isAdmin || PermissionService.HasPermission(userId, lic, "CASE_INV3", 5), "案件三審", "Manager/managerList.aspx?INV_State=INV3", pending.CaseInv3, true);
            AddSubItemIfAllowed(caseItems, isAdmin || PermissionService.HasPermission(userId, lic, "CASE_SEARCH_LIST", 42), "查核成果列表", "Case/CaseList.aspx?mode=search");
            AddSubItemIfAllowed(caseItems, isAdmin || PermissionService.HasPermission(userId, lic, "CASE_PROJECT_ZONE", 42), "臺北港專區", "Case/CaseList.aspx?mode=project", pending.CaseProject);
            AddSubItemIfAllowed(caseItems, isAdmin || PermissionService.HasPermission(userId, lic, "CASE_DISPATCH_SET", 0) || CheckLicense(lic, 10), "稽查派遣管理", "FAC/FAC_List.aspx?mode=mission");
            AddSubItemIfAllowed(caseItems, isAdmin || PermissionService.HasPermission(userId, lic, "CASE_MISSION_7DAY", 0), "巡查派遣", "Case/CaseList.aspx?mode=mission7day", pending.CaseMission7Day);
            AddSubItemIfAllowed(caseItems, isAdmin || PermissionService.HasPermission(userId, lic, "CASE_MISSION_2TIMES", 0), "提報稽查", "Case/CaseList.aspx?mode=mission2times", pending.CaseMission2Times, true);
            AddSubItemIfAllowed(caseItems, isAdmin || PermissionService.HasPermission(userId, lic, "CASE_SUM_STATS", 42), "查核統計", "Case/Case_Sum.aspx");
            AddSubItemIfAllowed(caseItems, isAdmin || PermissionService.HasPermission(userId, lic, "CASE_SUM_MANAGE", 42), "管辦改善歷程追蹤統計", "Case/Case_Sum_1.aspx");

            if (caseItems.Count > 0)
            {
                int caseTotalBadge = 0;
                foreach (var ci in caseItems)
                {
                    caseTotalBadge += ci.BadgeCount;
                }

                list.Add(new MenuModule
                {
                    Id = "Case",
                    Title = "巡查任務派遣",
                    SubTitle = "現場稽查任務派工、歷程初複三審與統計",
                    Url = caseItems[0].Url,
                    BgColor = "#497E82",
                    BadgeCount = caseTotalBadge,
                    IconSvg = @"<svg viewBox='0 0 24 24' width='64' height='64' fill='currentColor'><path d='M17 1.01L7 1c-1.1 0-2 .9-2 2v18c0 1.1.9 2 2 2h10c1.1 0 2-.9 2-2V3c0-1.1-.9-1.99-2-1.99zM17 19H7V5h10v14zm-4.2-7.8l-1.4-1.4-2.1 2.1 4.2 4.2 7.1-7.1-1.4-1.4-5.7 5.7z'/></svg>",
                    SubItems = caseItems
                });
            }

            // 3. 作業機具調查 (紫色)
            var machineItems = new List<MenuSubItem>();
            // 分類一：作業機具調查
            AddSubItemIfAllowed(machineItems, isAdmin || PermissionService.HasPermission(userId, lic, "MAC_DRAFT_VIEW", 1), "查核紀錄暫存", "Machine/macList.aspx?mode=reject", pending.MachineDraft, false, "作業機具調查");
            AddSubItemIfAllowed(machineItems, isAdmin || PermissionService.HasPermission(userId, lic, "MAC_INV1", 6), "案件初審", "Manager/managerList.aspx?INV_State=MAC1", pending.MachineInv1, true, "作業機具調查");
            AddSubItemIfAllowed(machineItems, isAdmin || PermissionService.HasPermission(userId, lic, "MAC_INV2", 6), "案件複審", "Manager/managerList.aspx?INV_State=MAC2", pending.MachineInv2, true, "作業機具調查");
            AddSubItemIfAllowed(machineItems, isAdmin || PermissionService.HasPermission(userId, lic, "MAC_INV3", 6), "案件三審", "Manager/managerList.aspx?INV_State=MAC3", pending.MachineInv3, true, "作業機具調查");

            // 分類二：調查成果列表
            AddSubItemIfAllowed(machineItems, isAdmin || PermissionService.HasPermission(userId, lic, "MAC_SEARCH_LIST", 43), "調查成果列表", "Machine/macList.aspx?mode=search", 0, false, "");
            AddSubItemIfAllowed(machineItems, isAdmin || PermissionService.HasPermission(userId, lic, "MAC_SURVEY_FORM", 43), "固定污染源施工機具普查", "https://pollution.epd.ntpc.gov.tw/NTPCEPD_NEW/Questionnaire/EquipSurvey.aspx", 0, false, "");
            AddSubItemIfAllowed(machineItems, isAdmin || PermissionService.HasPermission(userId, lic, "MAC_MOENV_ANALYSIS", 43) || CheckLicense(lic, 59), "環境部施工機具資料分析", "MoenvEquip/MoenvEquipment_List.aspx", 0, false, "");

            if (machineItems.Count > 0)
            {
                int machineTotalBadge = 0;
                foreach (var mi in machineItems)
                {
                    machineTotalBadge += mi.BadgeCount;
                }

                list.Add(new MenuModule
                {
                    Id = "Machine",
                    Title = "作業機具調查",
                    SubTitle = "施工機具列管、排煙檢測與審核列表",
                    Url = machineItems[0].Url,
                    BgColor = "#9334AF",
                    BadgeCount = machineTotalBadge,
                    IconSvg = @"<svg viewBox='0 0 24 24' width='64' height='64' fill='currentColor'><path d='M20 18v-4h-3v1h-2v-1H9v1H7v-1H4v4h16M22 6h-8V4h-4v2H4c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V8c0-1.1-.9-2-2-2m-8 6H4V8h10v4m6 0h-4V8h4v4z'/></svg>",
                    SubItems = machineItems
                });
            }

            // 4. 裸露地調查 (金黃土褐)
            var bareItems = new List<MenuSubItem>();
            AddSubItemIfAllowed(bareItems, isAdmin || PermissionService.HasPermission(userId, lic, "BARE_NEW_CHECK", 17), "裸露地調查", "BareGround/NewBare.aspx?mode=new");
            AddSubItemIfAllowed(bareItems, isAdmin || PermissionService.HasPermission(userId, lic, "BARE_DRAFT_VIEW", 17), "查核紀錄暫存", "BareGround/Bare_List.aspx?mode=reject", pending.BareDraft, true);
            AddSubItemIfAllowed(bareItems, isAdmin || PermissionService.HasPermission(userId, lic, "BARE_BACK_LIST", 17), "退件紀錄", "BareGround/Bare_List.aspx?mode=back", pending.BareBack, true);
            AddSubItemIfAllowed(bareItems, isAdmin || PermissionService.HasPermission(userId, lic, "BARE_INV1", 18), "案件初審", "Manager/managerList_Bare.aspx?mode=INV1", pending.BareInv1, true);
            AddSubItemIfAllowed(bareItems, isAdmin || PermissionService.HasPermission(userId, lic, "BARE_INV2", 19), "案件複審", "Manager/managerList_Bare.aspx?mode=INV2", pending.BareInv2, true);
            AddSubItemIfAllowed(bareItems, isAdmin || PermissionService.HasPermission(userId, lic, "BARE_INV3", 20), "案件三審", "Manager/managerList_Bare.aspx?mode=INV3", pending.BareInv3, true);
            AddSubItemIfAllowed(bareItems, isAdmin || PermissionService.HasPermission(userId, lic, "BARE_SEARCH_LIST", 44), "調查成果列表", "BareGround/Bare_List.aspx?mode=identify");

            if (bareItems.Count > 0)
            {
                int bareTotalBadge = 0;
                foreach (var bi in bareItems)
                {
                    bareTotalBadge += bi.BadgeCount;
                }

                list.Add(new MenuModule
                {
                    Id = "BareGround",
                    Title = "裸露地調查",
                    SubTitle = "裸露地建檔、衛星巡查與初複三審管考",
                    Url = bareItems[0].Url,
                    BgColor = "#9B741E",
                    BadgeCount = bareTotalBadge,
                    IconSvg = @"<svg viewBox='0 0 24 24' width='64' height='64' fill='currentColor'><path d='M12 4.5C7 4.5 2.73 7.61 1 12c1.73 4.39 6 7.5 11 7.5s9.27-3.11 11-7.5c-1.73-4.39-6-7.5-11-7.5zM12 17c-2.76 0-5-2.24-5-5s2.24-5 5-5 5 2.24 5 5-2.24 5-5 5zm0-8c-1.66 0-3 1.34-3 3s1.34 3 3 3 3-1.34 3-3-1.34-3-3-3z'/></svg>",
                    SubItems = bareItems
                });
            }

            // 5. 自主管理回報 (紅棕色)
            string userFacId = (user != null && !string.IsNullOrEmpty(user.FacID)) ? user.FacID.Trim() : "";
            string facToken = !string.IsNullOrEmpty(userFacId) ? ("MD5:" + userFacId + DateTime.Now.ToString("yyyyMMddHH")).ToMD5() : "";
            string ownReportUrl = !string.IsNullOrEmpty(userFacId)
                ? string.Format("OwnReport/PIC_Report.aspx?id={0}&id1={1}&mode=own", userFacId, facToken)
                : "OwnReport/PIC_Report.aspx?mode=own";
            string wrongReportUrl = !string.IsNullOrEmpty(userFacId)
                ? string.Format("OwnReport/PIC_Report.aspx?id={0}&id1={1}&mode=wrong", userFacId, facToken)
                : "OwnReport/PIC_Report.aspx?mode=wrong";
            string washInputUrl = !string.IsNullOrEmpty(userFacId)
                ? string.Format("Wash/DataInput.aspx?id={0}&id1={1}", userFacId, facToken)
                : "Wash/DataInput.aspx";

            var ownItems = new List<MenuSubItem>();
            // 分類一：自主管理控管
            AddSubItemIfAllowed(ownItems, isAdmin || PermissionService.HasPermission(userId, lic, "OWN_REPORT_INPUT", 8), "自主維護回報", ownReportUrl, 0, false, "自主管理控管");
            AddSubItemIfAllowed(ownItems, isAdmin || PermissionService.HasPermission(userId, lic, "OWN_REPORT_LIST", 8) || CheckLicense(lic, 9), "維護紀錄列表", "OwnReport/PIC_Report_List.aspx?mode=own", pending.OwnReportCount, false, "自主管理控管");

            // 分類二：車輛洗掃設備管理
            AddSubItemIfAllowed(ownItems, isAdmin || PermissionService.HasPermission(userId, lic, "OWN_WASH_INPUT", 12), "車輛洗掃回報", washInputUrl, 0, false, "車輛洗掃設備管理");
            AddSubItemIfAllowed(ownItems, isAdmin || PermissionService.HasPermission(userId, lic, "OWN_WASH_RECORD_LIST", 14), "洗車水電紀錄列表", "Wash/WashList.aspx", 0, false, "車輛洗掃設備管理");
            AddSubItemIfAllowed(ownItems, isAdmin || PermissionService.HasPermission(userId, lic, "OWN_WASH_UPLOAD", 13), "洗掃報表回傳", "Wash/ReportUpload.aspx", 0, false, "車輛洗掃設備管理");
            AddSubItemIfAllowed(ownItems, isAdmin || PermissionService.HasPermission(userId, lic, "OWN_WASH_LIST", 14), "洗掃紀錄列表", "Wash/ReportUpload_List.aspx", 0, false, "車輛洗掃設備管理");

            // 分類三：防制設施缺失改善管理
            AddSubItemIfAllowed(ownItems, isAdmin || PermissionService.HasPermission(userId, lic, "OWN_DEFECT_INPUT", 15), "缺失改善回報", wrongReportUrl, 0, false, "防制設施缺失改善管理");
            AddSubItemIfAllowed(ownItems, isAdmin || PermissionService.HasPermission(userId, lic, "OWN_DEFECT_LIST", 15) || CheckLicense(lic, 16), "改善紀錄列表", "OwnReport/PIC_Report_List.aspx?mode=wrong", pending.WrongReportCount, false, "防制設施缺失改善管理");

            // 分類四：空品不良應變管理
            AddSubItemIfAllowed(ownItems, isAdmin || PermissionService.HasPermission(userId, lic, "OWN_LINE_ALERT", 45), "LINE即時通報", "LINE/Line.aspx", 0, false, "空品不良應變管理");
            AddSubItemIfAllowed(ownItems, isAdmin || PermissionService.HasPermission(userId, lic, "OWN_AIR_INPUT", 45), "空品應變回報", "OwnReport/Report_AirQuality.aspx?mode=new", 0, false, "空品不良應變管理");
            AddSubItemIfAllowed(ownItems, isAdmin || PermissionService.HasPermission(userId, lic, "OWN_AIR_LIST", 45), "空品應變列表", "OwnReport/AirQuality_List.aspx", 0, false, "空品不良應變管理");

            if (ownItems.Count > 0)
            {
                int ownTotalBadge = 0;
                foreach (var oi in ownItems)
                {
                    ownTotalBadge += oi.BadgeCount;
                }

                list.Add(new MenuModule
                {
                    Id = "OwnReport",
                    Title = "自主管理回報",
                    SubTitle = "自主巡報、洗車台用水電、缺失改善與空品應變",
                    Url = ownItems[0].Url,
                    BgColor = "#733B31",
                    BadgeCount = ownTotalBadge,
                    IconSvg = @"<svg viewBox='0 0 24 24' width='64' height='64' fill='currentColor'><path d='M12 22c1.1 0 2-.9 2-2h-4c0 1.1.9 2 2 2zm6-6v-5c0-3.07-1.63-5.64-4.5-6.32V4c0-.83-.67-1.5-1.5-1.5s-1.5.67-1.5 1.5v.68C7.64 5.36 6 7.92 6 11v5l-2 2v1h16v-1l-2-2zm-2 1H8v-6c0-2.48 1.51-4.5 4-4.5s4 2.02 4 4.5v6z'/></svg>",
                    SubItems = ownItems
                });
            }

            // 6. 空間資訊整合 (酒紅色)
            var mapItems = new List<MenuSubItem>();
            AddSubItemIfAllowed(mapItems, isAdmin || PermissionService.HasPermission(userId, lic, "MAP_WASH_GIS", 41) || CheckLicense(lic, 12) || CheckLicense(lic, 14), "道路洗掃路段與現場查核地圖", "Wash/WashMap.aspx");
            AddSubItemIfAllowed(mapItems, isAdmin || PermissionService.HasPermission(userId, lic, "MAP_NDVI_SAT", 41), "NDVI 植被衛星影像", "NDVI/NdviMap.aspx");

            if (mapItems.Count > 0)
            {
                list.Add(new MenuModule
                {
                    Id = "Map",
                    Title = "空間資訊整合",
                    SubTitle = "列管工廠洗掃路段查核地圖與 NDVI 衛星影像",
                    Url = mapItems[0].Url,
                    BgColor = "#771728",
                    BadgeCount = 0,
                    IconSvg = @"<svg viewBox='0 0 24 24' width='64' height='64' fill='currentColor'><path d='M20.5 3l-.16.03L15 5.1 9 3 3.36 4.9c-.21.07-.36.25-.36.48V20.5c0 .28.22.5.5.5l.16-.03L9 18.9l6 2.1 5.64-1.9c.21-.07.36-.25.36-.48V3.5c0-.28-.22-.5-.5-.5zM15 19l-6-2.11V5l6 2.11V19z'/></svg>",
                    SubItems = mapItems
                });
            }

            // 7. 道路潔淨巡檢 (亮橘色)
            var roadItems = new List<MenuSubItem>();
            // 分類一：道路潔淨巡檢
            AddSubItemIfAllowed(roadItems, isAdmin || PermissionService.HasPermission(userId, lic, "ROAD_CLEAN_NEW", 21) || CheckLicense(lic, 22), "道路潔淨現場查核", "RoadClean/NewCleanChk.aspx?mode=new", 0, false, "道路潔淨巡檢");
            AddSubItemIfAllowed(roadItems, isAdmin || PermissionService.HasPermission(userId, lic, "ROAD_CLEAN_DRAFT", 22), "查核紀錄暫存", "RoadClean/Clean_List.aspx?mode=apply", pending.RoadCleanDraft, false, "道路潔淨巡檢");
            AddSubItemIfAllowed(roadItems, isAdmin || PermissionService.HasPermission(userId, lic, "ROAD_CLEAN_BACK", 22), "返回修正案件", "RoadClean/Clean_List.aspx?mode=back", pending.RoadCleanBack, true, "道路潔淨巡檢");
            AddSubItemIfAllowed(roadItems, isAdmin || PermissionService.HasPermission(userId, lic, "ROAD_CLEAN_EXAM", 22), "案件審核", "RoadClean/Clean_List.aspx?mode=examine", pending.RoadCleanExamine, false, "道路潔淨巡檢");
            AddSubItemIfAllowed(roadItems, isAdmin || PermissionService.HasPermission(userId, lic, "ROAD_CLEAN_SEARCH", 24) || CheckLicense(lic, 22), "調查成果列表", "RoadClean/Clean_List.aspx?mode=search", 0, false, "道路潔淨巡檢");
            AddSubItemIfAllowed(roadItems, isAdmin || PermissionService.HasPermission(userId, lic, "ROAD_CLEAN_STATS", 24), "道路潔淨統計", "RoadClean/RoadClean_Sum.aspx", 0, false, "道路潔淨巡檢");

            // 分類二：道路髒污清理
            AddSubItemIfAllowed(roadItems, isAdmin || PermissionService.HasPermission(userId, lic, "ROAD_DIRTY_NEW", 21), "道路髒污通報", "RoadClean/NewDirty.aspx?mode=new", 0, false, "道路髒污清理");
            AddSubItemIfAllowed(roadItems, isAdmin || PermissionService.HasPermission(userId, lic, "ROAD_DIRTY_DRAFT", 21), "查核紀錄暫存", "RoadClean/Dirty_List.aspx?mode=DirtyEdit", 0, false, "道路髒污清理");
            AddSubItemIfAllowed(roadItems, isAdmin || PermissionService.HasPermission(userId, lic, "ROAD_DIRTY_IMPROVE", 23), "髒污改善回報", "RoadClean/Dirty_List.aspx?mode=DirtyImprove", pending.RoadDirtyImprove, false, "道路髒污清理");
            AddSubItemIfAllowed(roadItems, isAdmin || PermissionService.HasPermission(userId, lic, "ROAD_DIRTY_FINISH", 24), "髒污改善成果", "RoadClean/Dirty_List.aspx?mode=Finish", 0, false, "道路髒污清理");

            // 分類三：道路破損清理
            AddSubItemIfAllowed(roadItems, isAdmin || PermissionService.HasPermission(userId, lic, "ROAD_BREAK_NEW", 26), "道路破損通報", "RoadBreak/NewBreak.aspx?mode=new", 0, false, "道路破損清理");
            AddSubItemIfAllowed(roadItems, isAdmin || PermissionService.HasPermission(userId, lic, "ROAD_BREAK_DRAFT", 26), "查核紀錄暫存", "RoadBreak/Break_List.aspx?mode=BreakEdit", 0, false, "道路破損清理");
            AddSubItemIfAllowed(roadItems, isAdmin || PermissionService.HasPermission(userId, lic, "ROAD_BREAK_IMPROVE", 27), "破損改善回報", "RoadBreak/Break_List.aspx?mode=BreakImprove", pending.RoadBreakImprove, false, "道路破損清理");
            AddSubItemIfAllowed(roadItems, isAdmin || PermissionService.HasPermission(userId, lic, "ROAD_BREAK_FINISH", 27), "破損改善成果", "RoadBreak/Break_List.aspx?mode=Finish", 0, false, "道路破損清理");

            // 分類四：人行道/跳空通道整理
            AddSubItemIfAllowed(roadItems, isAdmin || PermissionService.HasPermission(userId, lic, "ROAD_BSC_NEW", 28), "清理落塵通報", "RoadBSC/NewBSC.aspx?mode=new", 0, false, "人行道/跳空通道整理");
            AddSubItemIfAllowed(roadItems, isAdmin || PermissionService.HasPermission(userId, lic, "ROAD_BSC_DRAFT", 28), "查核紀錄暫存", "RoadBSC/BSC_List.aspx?mode=BSCEdit", 0, false, "人行道/跳空通道整理");
            AddSubItemIfAllowed(roadItems, isAdmin || PermissionService.HasPermission(userId, lic, "ROAD_BSC_IMPROVE", 29), "落塵改善回報", "RoadBSC/BSC_List.aspx?mode=BSCImprove", pending.RoadBSCImprove, true, "人行道/跳空通道整理");
            AddSubItemIfAllowed(roadItems, isAdmin || PermissionService.HasPermission(userId, lic, "ROAD_BSC_FINISH", 29), "落塵改善成果", "RoadBSC/BSC_List.aspx?mode=Finish", 0, false, "人行道/跳空通道整理");

            if (roadItems.Count > 0)
            {
                int roadTotalBadge = 0;
                foreach (var ri in roadItems)
                {
                    roadTotalBadge += ri.BadgeCount;
                }

                list.Add(new MenuModule
                {
                    Id = "RoadClean",
                    Title = "道路潔淨巡檢",
                    SubTitle = "洗掃查核、道路髒污、路面破損開挖與覆土管考",
                    Url = roadItems[0].Url,
                    BgColor = "#CE4F19",
                    BadgeCount = roadTotalBadge,
                    IconSvg = @"<svg viewBox='0 0 24 24' width='64' height='64' fill='currentColor'><path d='M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-5 14H7v-2h7v2zm3-4H7v-2h10v2zm0-4H7V7h10v2z'/></svg>",
                    SubItems = roadItems
                });
            }

            // =========================================================================
            // 8. 餐飲查核輔導 (墨綠色) - 維持目前設定，外部介接 /fd_food (須具備 Bit 25~36)
            // =========================================================================
            bool hasFoodLic = false;
            for (int fi = 25; fi <= 36; fi++)
            {
                if (CheckLicense(lic, fi))
                {
                    hasFoodLic = true;
                    break;
                }
            }

            if (isAdmin || hasFoodLic)
            {
                string foodVerify = ("NTPC_FEC_" + DateTime.Now.ToString("yyyyMMdd") + uid + userId + lic).ToMD5();
                string foodUrl = string.Format("/fd_food/Home/loginfd?uid={0}&userid={1}&lic={2}&verify={3}", uid, userId, lic, foodVerify);
                list.Add(new MenuModule
                {
                    Id = "Catering",
                    Title = "餐飲查核輔導",
                    SubTitle = "餐飲業油煙防制設施普查、初複三審與輔導系統",
                    Url = foodUrl,
                    BgColor = "#30431B",
                    IsExternal = true,
                    BadgeCount = 0,
                    IconSvg = @"<svg viewBox='0 0 24 24' width='64' height='64' fill='currentColor'><path d='M18.06 22.99h1.66c.84 0 1.53-.64 1.63-1.46L23 5.05h-5V1h-1.97v4.05h-4.97l.3 2.34c1.71.47 3.31 1.32 4.27 2.26 1.44 1.42 2.43 2.89 2.43 5.29v8.05zM1 21.99V21h15.03v.99c0 .55-.45 1-1 1H2c-.55 0-1-.45-1-1zm14.03-2.99H1v-5.01c0-1.1.9-2 2-2h1.55c.78-1.92 2.49-3.4 4.54-3.84L9 7.02c-3.86.42-7 3.51-7 7.47v4.51h13.03z'/></svg>",
                    SubItems = new List<MenuSubItem>
                    {
                        new MenuSubItem { Title = "前往新北市餐飲查核輔導系統", Url = foodUrl }
                    }
                });
            }

            // =========================================================================
            // 9. 油氣設施查核 (深海青藍色) - 維持目前設定，外部介接 /GS_GasStation (須具備 LIC2 Bit 0~5)
            // =========================================================================
            bool hasGasLic = false;
            for (int gi = 0; gi <= 5; gi++)
            {
                if (CheckLicense(lic2, gi))
                {
                    hasGasLic = true;
                    break;
                }
            }

            if (isAdmin || hasGasLic)
            {
                string gasVerify = ("NTPC_FEC_" + DateTime.Now.ToString("yyyyMMdd") + uid + userId + lic2).ToMD5();
                string gasUrl = string.Format("/GS_GasStation/Home/LoginFd?uid={0}&userid={1}&lic={2}&verify={3}", uid, userId, lic2, gasVerify);
                list.Add(new MenuModule
                {
                    Id = "GasStation",
                    Title = "油氣設施查核",
                    SubTitle = "加油站油氣回收設施查核、氣油比檢測與管考系統",
                    Url = gasUrl,
                    BgColor = "#154860",
                    IsExternal = true,
                    BadgeCount = 0,
                    IconSvg = @"<svg viewBox='0 0 24 24' width='64' height='64' fill='currentColor'><path d='M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.42 0-8-3.58-8-8s3.58-8 8-8 8 3.58 8 8-3.58 8-8 8zm1-13h-2v5.27l4.5 2.67.75-1.23-3.75-2.22V7z'/></svg>",
                    SubItems = new List<MenuSubItem>
                    {
                        new MenuSubItem { Title = "前往新北市加油站油氣設施查核系統", Url = gasUrl }
                    }
                });
            }

            // 10. 系統維運管理 (碳素灰調) - 僅具備管理員權限者可見
            if (isAdmin || PermissionService.HasPermission(userId, lic, "SYS_ACCOUNT_MANAGE", 63))
            {
                list.Add(new MenuModule
                {
                    Id = "SystemAdmin",
                    Title = "系統維運管理",
                    SubTitle = "使用者帳號管理與權限角色維護",
                    Url = "Modules/Manager/AccountManagement.aspx",
                    BgColor = "#334155",
                    BadgeCount = 0,
                    IconSvg = @"<svg viewBox='0 0 24 24' width='64' height='64' fill='currentColor'><path d='M19.14 12.94c.04-.3.06-.61.06-.94 0-.32-.02-.64-.07-.94l2.03-1.58c.18-.14.23-.41.12-.61l-1.92-3.32c-.12-.22-.37-.29-.59-.22l-2.39.96c-.5-.38-1.03-.7-1.62-.94l-.36-2.54c-.04-.24-.24-.41-.48-.41h-3.84c-.24 0-.43.17-.47.41l-.36 2.54c-.59.24-1.13.57-1.62.94l-2.39-.96c-.22-.08-.47 0-.59.22L2.74 8.87c-.12.21-.08.47.12.61l2.03 1.58c-.05.3-.09.63-.09.94s.02.64.07.94l-2.03 1.58c-.18.14-.23.41-.12.61l1.92 3.32c.12.22.37.29.59.22l2.39-.96c.5.38 1.03.7 1.62.94l.36 2.54c.05.24.24.41.48.41h3.84c.24 0 .44-.17.47-.41l.36-2.54c.59-.24 1.13-.56 1.62-.94l2.39.96c.22.08.47 0 .59-.22l1.92-3.32c.12-.22.07-.47-.12-.61l-2.01-1.58zM12 15.6c-1.98 0-3.6-1.62-3.6-3.6s1.62-3.6 3.6-3.6 3.6 1.62 3.6 3.6-1.62 3.6-3.6 3.6z'/></svg>",
                    SubItems = new List<MenuSubItem>
                    {
                        new MenuSubItem { Title = "帳號權限管理", Url = "Modules/Manager/AccountManagement.aspx" }
                    }
                });
            }

            return list;
        }

        // 輔助 MD5 計算
        private static string CalculateMD5(string input)
        {
            using (var md5 = System.Security.Cryptography.MD5.Create())
            {
                byte[] inputBytes = System.Text.Encoding.UTF8.GetBytes(input);
                byte[] hashBytes = md5.ComputeHash(inputBytes);
                var sb = new System.Text.StringBuilder();
                for (int i = 0; i < hashBytes.Length; i++)
                {
                    sb.Append(hashBytes[i].ToString("X2"));
                }
                return sb.ToString();
            }
        }
    }

    public static class StringExtension
    {
        public static string ToMD5(this string str)
        {
            using (var md5 = System.Security.Cryptography.MD5.Create())
            {
                byte[] inputBytes = System.Text.Encoding.UTF8.GetBytes(str);
                byte[] hashBytes = md5.ComputeHash(inputBytes);
                var sb = new System.Text.StringBuilder();
                for (int i = 0; i < hashBytes.Length; i++)
                {
                    sb.Append(hashBytes[i].ToString("X2"));
                }
                return sb.ToString();
            }
        }
    }
}
