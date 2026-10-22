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

        public static List<MenuModule> GetUserModules(UserAccount user)
        {
            var list = new List<MenuModule>();
            long lic = user != null ? user.Lic : 0L;
            long lic2 = user != null ? user.Lic2 : 0L;
            int uid = user != null ? user.UID : 0;
            string userId = user != null ? user.UserID : "";

            // 1. 工廠基本資料 (深海軍藍)
            list.Add(new MenuModule
            {
                Id = "FAC",
                Title = "工廠基本資料",
                SubTitle = "列管廠場基本檔、許可證資訊與統計查詢",
                Url = "FAC/FAC_List.aspx?mode=read",
                BgColor = "#24405E",
                BadgeCount = 0,
                IconSvg = @"<svg viewBox='0 0 24 24' width='64' height='64' fill='currentColor'><path d='M4 19h16v2H4zm0-4h2v2H4zm4 0h2v2H8zm4 0h2v2h-2zm4 0h2v2h-2zM4 10h2v2H4zm4 0h2v2H8zm4 0h2v2h-2zm4 0h2v2h-2zM2 22h20V8l-6 4V4l-6 4V2H2v20z'/></svg>",
                SubItems = new List<MenuSubItem>
                {
                    new MenuSubItem { Title = "逸散源列管", Url = "FAC/FAC_List.aspx?mode=read" },
                    new MenuSubItem { Title = "逸散源未列管", Url = "FAC/FAC_List.aspx?mode=edit" },
                    new MenuSubItem { Title = "許可證資訊", Url = "FAC/oFAC_List.aspx" },
                    new MenuSubItem { Title = "其他資料查詢", Url = "OutLink.aspx" },
                    new MenuSubItem { Title = "工廠統計", Url = "FAC/Charts.aspx" },
                    new MenuSubItem { Title = "環域查詢", Url = "Case/CaseList.aspx" }
                }
            });

            // 2. 巡查任務派遣 (青藍灰)
            list.Add(new MenuModule
            {
                Id = "Case",
                Title = "巡查任務派遣",
                SubTitle = "現場稽查任務派工、歷程初複三審與統計",
                Url = "Case/Mission.aspx",
                BgColor = "#497E82",
                BadgeCount = 3,
                IconSvg = @"<svg viewBox='0 0 24 24' width='64' height='64' fill='currentColor'><path d='M17 1.01L7 1c-1.1 0-2 .9-2 2v18c0 1.1.9 2 2 2h10c1.1 0 2-.9 2-2V3c0-1.1-.9-1.99-2-1.99zM17 19H7V5h10v14zm-4.2-7.8l-1.4-1.4-2.1 2.1 4.2 4.2 7.1-7.1-1.4-1.4-5.7 5.7z'/></svg>",
                SubItems = new List<MenuSubItem>
                {
                    new MenuSubItem { Title = "防制設施查核", Url = "Case/NewCase.aspx?mode=new" },
                    new MenuSubItem { Title = "查核紀錄暫存", Url = "Case/CaseList.aspx?mode=reject" },
                    new MenuSubItem { Title = "退件紀錄", Url = "Case/CaseList.aspx?mode=back" },
                    new MenuSubItem { Title = "案件初審", Url = "Manager/managerList.aspx?INV_State=INV1" },
                    new MenuSubItem { Title = "案件複審", Url = "Manager/managerList.aspx?INV_State=INV2" },
                    new MenuSubItem { Title = "案件三審", Url = "Manager/managerList.aspx?INV_State=INV3" },
                    new MenuSubItem { Title = "查核紀錄列表", Url = "Case/CaseList.aspx?mode=search" },
                    new MenuSubItem { Title = "臺北港專區", Url = "Case/CaseList.aspx?mode=project" },
                    new MenuSubItem { Title = "案件派遣設定", Url = "FAC/FAC_List.aspx?mode=mission" },
                    new MenuSubItem { Title = "巡查派遣", Url = "Case/CaseList.aspx?mode=mission7day", BadgeCount = 3 },
                    new MenuSubItem { Title = "提報稽查", Url = "Case/CaseList.aspx?mode=mission2times" },
                    new MenuSubItem { Title = "查核統計", Url = "Case/Case_Sum.aspx" },
                    new MenuSubItem { Title = "管辧狀況統計", Url = "Case/Case_Sum_1.aspx" }
                }
            });

            // 3. 作業機具調查 (紫色)
            list.Add(new MenuModule
            {
                Id = "Machine",
                Title = "作業機具調查",
                SubTitle = "施工機具列管、排煙檢測與審核列表",
                Url = "Machine/macList.aspx",
                BgColor = "#9334AF",
                BadgeCount = 0,
                IconSvg = @"<svg viewBox='0 0 24 24' width='64' height='64' fill='currentColor'><path d='M20 18v-4h-3v1h-2v-1H9v1H7v-1H4v4h16M22 6h-8V4h-4v2H4c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V8c0-1.1-.9-2-2-2m-8 6H4V8h10v4m6 0h-4V8h4v4z'/></svg>",
                SubItems = new List<MenuSubItem>
                {
                    new MenuSubItem { Title = "作業機具調查", Url = "Machine/NewMac.aspx" },
                    new MenuSubItem { Title = "查核紀錄暫存", Url = "Machine/macList.aspx?mode=reject" },
                    new MenuSubItem { Title = "案件審核", Url = "Manager/managerList.aspx?INV_State=MAC1" },
                    new MenuSubItem { Title = "調查成果列表", Url = "Machine/macList.aspx?mode=search" }
                }
            });

            // 4. 裸露地調查 (金黃土褐)
            list.Add(new MenuModule
            {
                Id = "BareGround",
                Title = "裸露地調查",
                SubTitle = "裸露地建檔、衛星巡查與初複三審管考",
                Url = "BareGround/Bare_List.aspx",
                BgColor = "#9B741E",
                BadgeCount = 0,
                IconSvg = @"<svg viewBox='0 0 24 24' width='64' height='64' fill='currentColor'><path d='M12 4.5C7 4.5 2.73 7.61 1 12c1.73 4.39 6 7.5 11 7.5s9.27-3.11 11-7.5c-1.73-4.39-6-7.5-11-7.5zM12 17c-2.76 0-5-2.24-5-5s2.24-5 5-5 5 2.24 5 5-2.24 5-5 5zm0-8c-1.66 0-3 1.34-3 3s1.34 3 3 3 3-1.34 3-3-1.34-3-3-3z'/></svg>",
                SubItems = new List<MenuSubItem>
                {
                    new MenuSubItem { Title = "裸露地調查", Url = "BareGround/NewBare.aspx?mode=new" },
                    new MenuSubItem { Title = "查核紀錄暫存", Url = "BareGround/Bare_List.aspx?mode=reject" },
                    new MenuSubItem { Title = "退件紀錄", Url = "BareGround/Bare_List.aspx?mode=back" },
                    new MenuSubItem { Title = "案件初審", Url = "Manager/managerList_Bare.aspx?mode=INV1" },
                    new MenuSubItem { Title = "案件複審", Url = "Manager/managerList_Bare.aspx?mode=INV2" },
                    new MenuSubItem { Title = "案件三審", Url = "Manager/managerList_Bare.aspx?mode=INV3" },
                    new MenuSubItem { Title = "調查成果列表", Url = "BareGround/Bare_List.aspx?mode=identify" }
                }
            });

            // 5. 自主管理回報 (紅棕色) - 比照舊版系統精確分為 4 大業務分類
            list.Add(new MenuModule
            {
                Id = "OwnReport",
                Title = "自主管理回報",
                SubTitle = "自主巡報、洗車台用水電、缺失改善與空品應變",
                Url = "OwnReport/PIC_Report_List.aspx",
                BgColor = "#733B31",
                BadgeCount = 5,
                IconSvg = @"<svg viewBox='0 0 24 24' width='64' height='64' fill='currentColor'><path d='M12 22c1.1 0 2-.9 2-2h-4c0 1.1.9 2 2 2zm6-6v-5c0-3.07-1.63-5.64-4.5-6.32V4c0-.83-.67-1.5-1.5-1.5s-1.5.67-1.5 1.5v.68C7.64 5.36 6 7.92 6 11v5l-2 2v1h16v-1l-2-2zm-2 1H8v-6c0-2.48 1.51-4.5 4-4.5s4 2.02 4 4.5v6z'/></svg>",
                SubItems = new List<MenuSubItem>
                {
                    // 分類一：自主回報管理
                    new MenuSubItem { Category = "自主回報管理", Title = "自主維護回報", Url = "OwnReport/PIC_Report.aspx?id=" },
                    new MenuSubItem { Category = "自主回報管理", Title = "維護紀錄列表", Url = "OwnReport/PIC_Report_List.aspx?mode=own", BadgeCount = 3 },

                    // 分類二：道路洗掃認養管理
                    new MenuSubItem { Category = "道路洗掃認養管理", Title = "道路洗掃回報", Url = "Wash/DataInput.aspx?id=" },
                    new MenuSubItem { Category = "道路洗掃認養管理", Title = "洗掃報表回傳", Url = "Wash/ReportUpload.aspx" },
                    new MenuSubItem { Category = "道路洗掃認養管理", Title = "洗掃紀錄列表", Url = "Wash/ReportUpload_List.aspx" },

                    // 分類三：防制設施缺失改善管理
                    new MenuSubItem { Category = "防制設施缺失改善管理", Title = "缺失改善回報", Url = "OwnReport/PIC_Report.aspx?id=" },
                    new MenuSubItem { Category = "防制設施缺失改善管理", Title = "改善紀錄列表", Url = "OwnReport/PIC_Report_List.aspx?mode=wrong", BadgeCount = 2 },

                    // 分類四：空品不良應變管理
                    new MenuSubItem { Category = "空品不良應變管理", Title = "LINE即時通報", Url = "LINE/Line.aspx" },
                    new MenuSubItem { Category = "空品不良應變管理", Title = "空品應變回報", Url = "OwnReport/Report_AirQuality.aspx?mode=new" },
                    new MenuSubItem { Category = "空品不良應變管理", Title = "空品應變列表", Url = "OwnReport/AirQuality_List.aspx" }
                }
            });

            // 6. 空間資訊整合 (酒紅色)
            list.Add(new MenuModule
            {
                Id = "Map",
                Title = "空間資訊整合",
                SubTitle = "新北 29 區污染源空間 GIS 與 NDVI 衛星影像",
                Url = "https://pollution.epd.ntpc.gov.tw/ntpcepd/map/map.aspx",
                BgColor = "#771728",
                BadgeCount = 0,
                IconSvg = @"<svg viewBox='0 0 24 24' width='64' height='64' fill='currentColor'><path d='M20.5 3l-.16.03L15 5.1 9 3 3.36 4.9c-.21.07-.36.25-.36.48V20.5c0 .28.22.5.5.5l.16-.03L9 18.9l6 2.1 5.64-1.9c.21-.07.36-.25.36-.48V3.5c0-.28-.22-.5-.5-.5zM15 19l-6-2.11V5l6 2.11V19z'/></svg>",
                SubItems = new List<MenuSubItem>
                {
                    new MenuSubItem { Title = "空間資訊地圖 (GIS)", Url = "https://pollution.epd.ntpc.gov.tw/ntpcepd/map/map.aspx" },
                    new MenuSubItem { Title = "NDVI 植被衛星影像", Url = "NDVI/main.html" }
                }
            });

            // 7. 道路潔淨巡檢 (亮橘色) - 依舊版業務精確分為 4 大分類
            list.Add(new MenuModule
            {
                Id = "RoadClean",
                Title = "道路潔淨巡檢",
                SubTitle = "洗掃查核、道路髒污、路面破損開挖與覆土管考",
                Url = "RoadClean/Clean_List.aspx",
                BgColor = "#CE4F19",
                BadgeCount = 12,
                IconSvg = @"<svg viewBox='0 0 24 24' width='64' height='64' fill='currentColor'><path d='M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-5 14H7v-2h7v2zm3-4H7v-2h10v2zm0-4H7V7h10v2z'/></svg>",
                SubItems = new List<MenuSubItem>
                {
                    // 分類一：道路潔淨巡檢
                    new MenuSubItem { Category = "道路潔淨巡檢", Title = "道路潔淨查核 (新增)", Url = "RoadClean/NewCleanChk.aspx?mode=new" },
                    new MenuSubItem { Category = "道路潔淨巡檢", Title = "查核紀錄暫存", Url = "RoadClean/Clean_List.aspx?mode=apply" },
                    new MenuSubItem { Category = "道路潔淨巡檢", Title = "退回補正案件", Url = "RoadClean/Clean_List.aspx?mode=back" },
                    new MenuSubItem { Category = "道路潔淨巡檢", Title = "案件審核", Url = "RoadClean/Clean_List.aspx?mode=examine", BadgeCount = 12 },
                    new MenuSubItem { Category = "道路潔淨巡檢", Title = "調查成果列表", Url = "RoadClean/Clean_List.aspx?mode=search" },
                    new MenuSubItem { Category = "道路潔淨巡檢", Title = "道路潔淨統計", Url = "RoadClean/RoadClean_Sum.aspx" },

                    // 分類二：道路髒污管理
                    new MenuSubItem { Category = "道路髒污管理", Title = "道路髒污通報", Url = "RoadClean/NewDirty.aspx?mode=new" },
                    new MenuSubItem { Category = "道路髒污管理", Title = "查核紀錄暫存", Url = "RoadClean/Dirty_List.aspx?mode=DirtyEdit" },
                    new MenuSubItem { Category = "道路髒污管理", Title = "路污改善回報", Url = "RoadClean/Dirty_List.aspx?mode=DirtyImprove" },
                    new MenuSubItem { Category = "道路髒污管理", Title = "路污改善成果", Url = "RoadClean/Dirty_List.aspx?mode=Finish" },

                    // 分類三：道路破損管理
                    new MenuSubItem { Category = "道路破損管理", Title = "道路破損通報", Url = "RoadBreak/NewBreak.aspx?mode=new" },
                    new MenuSubItem { Category = "道路破損管理", Title = "查核紀錄暫存", Url = "RoadBreak/Break_List.aspx?mode=BreakEdit" },
                    new MenuSubItem { Category = "道路破損管理", Title = "破損改善回報", Url = "RoadBreak/Break_List.aspx?mode=BreakImprove" },
                    new MenuSubItem { Category = "道路破損管理", Title = "破損改善成果", Url = "RoadBreak/Break_List.aspx?mode=Finish" },

                    // 分類四：人行道與交通島管理
                    new MenuSubItem { Category = "人行道與交通島管理", Title = "裸露覆土通報", Url = "RoadBSC/NewBSC.aspx?mode=new" },
                    new MenuSubItem { Category = "人行道與交通島管理", Title = "查核紀錄暫存", Url = "RoadBSC/BSC_List.aspx?mode=BSCEdit" },
                    new MenuSubItem { Category = "人行道與交通島管理", Title = "覆土改善回報", Url = "RoadBSC/BSC_List.aspx?mode=BSCImprove" },
                    new MenuSubItem { Category = "人行道與交通島管理", Title = "覆土改善成果", Url = "RoadBSC/BSC_List.aspx?mode=Finish" }
                }
            });

            // 8. 餐飲查核輔導 (墨綠色) - 介接 /fd_food
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

            // 9. 油氣設施查核 (深海青藍色) - 介接 /GS_GasStation
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

            // 10. 系統維運管理 (碳素灰調) - 僅具備管理員權限者可見
            bool isAdmin = (userId.ToLower() == "admin")
                           || CheckLicense(lic, 63)
                           || CheckLicense(lic, 41);

            if (isAdmin)
            {
                list.Add(new MenuModule
                {
                    Id = "SystemAdmin",
                    Title = "系統維運管理",
                    SubTitle = "使用者帳號管理、權限角色設定與任務派遣配置",
                    Url = "Modules/Manager/AccountManagement.aspx",
                    BgColor = "#334155",
                    BadgeCount = 0,
                    IconSvg = @"<svg viewBox='0 0 24 24' width='64' height='64' fill='currentColor'><path d='M19.14 12.94c.04-.3.06-.61.06-.94 0-.32-.02-.64-.07-.94l2.03-1.58c.18-.14.23-.41.12-.61l-1.92-3.32c-.12-.22-.37-.29-.59-.22l-2.39.96c-.5-.38-1.03-.7-1.62-.94l-.36-2.54c-.04-.24-.24-.41-.48-.41h-3.84c-.24 0-.43.17-.47.41l-.36 2.54c-.59.24-1.13.57-1.62.94l-2.39-.96c-.22-.08-.47 0-.59.22L2.74 8.87c-.12.21-.08.47.12.61l2.03 1.58c-.05.3-.09.63-.09.94s.02.64.07.94l-2.03 1.58c-.18.14-.23.41-.12.61l1.92 3.32c.12.22.37.29.59.22l2.39-.96c.5.38 1.03.7 1.62.94l.36 2.54c.05.24.24.41.48.41h3.84c.24 0 .44-.17.47-.41l.36-2.54c.59-.24 1.13-.56 1.62-.94l2.39.96c.22.08.47 0 .59-.22l1.92-3.32c.12-.22.07-.47-.12-.61l-2.01-1.58zM12 15.6c-1.98 0-3.6-1.62-3.6-3.6s1.62-3.6 3.6-3.6 3.6 1.62 3.6 3.6-1.62 3.6-3.6 3.6z'/></svg>",
                    SubItems = new List<MenuSubItem>
                    {
                        new MenuSubItem { Title = "帳號權限管理", Url = "Modules/Manager/AccountManagement.aspx" },
                        new MenuSubItem { Title = "巡查派遣設定", Url = "FAC/FAC_List.aspx?mode=mission" },
                        new MenuSubItem { Title = "審核流程管理 (初/複/三審)", Url = "Manager/managerList.aspx?INV_State=INV1" }
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
