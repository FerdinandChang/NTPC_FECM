using System;
using System.Web;
using NTPC_FEC.Models;
using NTPC_FEC.Services;

namespace NTPC_FEC.Security
{
    public class AuthRuleService
    {
        public static bool CheckUrlAccess(string appRelativePath, HttpRequest request, UserAccount user, out string denyReason)
        {
            denyReason = "";

            if (user == null)
            {
                denyReason = "登入已逾時或尚未登入，請重新登入！";
                return false;
            }

            // 1. 最高系統管理員 (admin 或 LIC 63) 具備全系統無限制存取權
            string userId = (user.UserID != null ? user.UserID.Trim().ToLower() : "");
            if (userId == "admin" || MenuService.CheckLicense(user.Lic, 63))
            {
                return true;
            }

            string normPath = (appRelativePath != null ? appRelativePath.Replace("\\", "/").Trim() : "");
            if (normPath.StartsWith("~/"))
            {
                normPath = normPath.Substring(2);
            }
            normPath = normPath.TrimStart('/');

            // 2. 系統共用/公開頁面白名單 (登入即可造訪)
            if (normPath.Equals("MainPage.aspx", StringComparison.OrdinalIgnoreCase) ||
                normPath.Equals("OutLink.aspx", StringComparison.OrdinalIgnoreCase) ||
                normPath.Equals("ChangePassword.aspx", StringComparison.OrdinalIgnoreCase) ||
                normPath.Equals("Default.aspx", StringComparison.OrdinalIgnoreCase) ||
                normPath.Equals("ClientLogin.aspx", StringComparison.OrdinalIgnoreCase) ||
                normPath.Equals("Logout.aspx", StringComparison.OrdinalIgnoreCase))
            {
                return true;
            }

            long lic = user.Lic;
            long lic2 = user.Lic2;

            // 3. 系統維運管理
            if (normPath.StartsWith("Modules/Manager/AccountManagement.aspx", StringComparison.OrdinalIgnoreCase))
            {
                if (MenuService.CheckLicense(lic, 63) || MenuService.CheckLicense(lic, 41))
                {
                    return true;
                }
                denyReason = "您無權限存取【帳號權限管理】頁面！";
                return false;
            }

            // 4. 案件審核 (初審、複審、三審、機具審核)
            if (normPath.StartsWith("Manager/managerList.aspx", StringComparison.OrdinalIgnoreCase) ||
                normPath.StartsWith("Manager/Check_Step1.aspx", StringComparison.OrdinalIgnoreCase) ||
                normPath.StartsWith("Manager/Check_Step1_Mac.aspx", StringComparison.OrdinalIgnoreCase))
            {
                string invState = (request != null && request["INV_State"] != null ? request["INV_State"].ToString().ToUpper() : "");
                if (invState == "INV1")
                {
                    if (MenuService.CheckLicense(lic, 3)) return true;
                    denyReason = "您無權限存取【案件初審】功能！";
                    return false;
                }
                if (invState == "INV2")
                {
                    if (MenuService.CheckLicense(lic, 4)) return true;
                    denyReason = "您無權限存取【案件複審】功能！";
                    return false;
                }
                if (invState == "INV3")
                {
                    if (MenuService.CheckLicense(lic, 5)) return true;
                    denyReason = "您無權限存取【案件三審】功能！";
                    return false;
                }
                if (invState == "MAC1" || invState == "MAC2" || invState == "MAC3")
                {
                    if (MenuService.CheckLicense(lic, 6) || MenuService.CheckLicense(lic, 43)) return true;
                    denyReason = "您無權限存取【作業機具調查審核】功能！";
                    return false;
                }

                // 未帶參數時，只要有初審、複審、三審或機具審核任一權限即可存取
                if (MenuService.CheckLicense(lic, 3) || MenuService.CheckLicense(lic, 4) || MenuService.CheckLicense(lic, 5) ||
                    MenuService.CheckLicense(lic, 6) || MenuService.CheckLicense(lic, 0) || MenuService.CheckLicense(lic, 42))
                {
                    return true;
                }
                denyReason = "您無權限存取案件審核功能！";
                return false;
            }

            // 5. 裸露地案件審核
            if (normPath.StartsWith("Manager/managerList_Bare.aspx", StringComparison.OrdinalIgnoreCase) ||
                normPath.StartsWith("Manager/Check_Step1_Bare.aspx", StringComparison.OrdinalIgnoreCase))
            {
                string mode = (request != null && request["mode"] != null ? request["mode"].ToString().ToUpper() : "");
                if (mode == "INV1")
                {
                    if (MenuService.CheckLicense(lic, 18)) return true;
                    denyReason = "您無權限存取裸露地【案件初審】功能！";
                    return false;
                }
                if (mode == "INV2")
                {
                    if (MenuService.CheckLicense(lic, 19)) return true;
                    denyReason = "您無權限存取裸露地【案件複審】功能！";
                    return false;
                }
                if (mode == "INV3")
                {
                    if (MenuService.CheckLicense(lic, 20)) return true;
                    denyReason = "您無權限存取裸露地【案件三審】功能！";
                    return false;
                }

                if (MenuService.CheckLicense(lic, 18) || MenuService.CheckLicense(lic, 19) || MenuService.CheckLicense(lic, 20) ||
                    MenuService.CheckLicense(lic, 17) || MenuService.CheckLicense(lic, 44))
                {
                    return true;
                }
                denyReason = "您無權限存取裸露地審核功能！";
                return false;
            }

            // 6. 巡查任務派遣 (防制設施查核)
            if (normPath.StartsWith("Case/", StringComparison.OrdinalIgnoreCase))
            {
                string mode = (request != null && request["mode"] != null ? request["mode"].ToString().ToLower() : "");
                if (normPath.IndexOf("Case_Sum", StringComparison.OrdinalIgnoreCase) >= 0 || mode == "search" || mode == "project")
                {
                    if (MenuService.CheckLicense(lic, 42)) return true;
                    denyReason = "您無權限存取查核列表或統計查詢功能！";
                    return false;
                }
                if (MenuService.CheckLicense(lic, 0) || MenuService.CheckLicense(lic, 42) ||
                    MenuService.CheckLicense(lic, 3) || MenuService.CheckLicense(lic, 4) || MenuService.CheckLicense(lic, 5))
                {
                    return true;
                }
                denyReason = "您無權限存取防制設施查核功能！";
                return false;
            }

            // 7. 作業機具調查
            if (normPath.StartsWith("Machine/", StringComparison.OrdinalIgnoreCase))
            {
                string mode = (request != null && request["mode"] != null ? request["mode"].ToString().ToLower() : "");
                if (normPath.IndexOf("NewMac.aspx", StringComparison.OrdinalIgnoreCase) >= 0 || mode == "reject")
                {
                    if (MenuService.CheckLicense(lic, 1)) return true;
                    denyReason = "您無權限存取【作業機具調查】功能！";
                    return false;
                }
                if (mode == "search")
                {
                    if (MenuService.CheckLicense(lic, 43)) return true;
                    denyReason = "您無權限存取作業機具【調查成果列表】！";
                    return false;
                }
                if (MenuService.CheckLicense(lic, 1) || MenuService.CheckLicense(lic, 43) || MenuService.CheckLicense(lic, 6))
                {
                    return true;
                }
                denyReason = "您無權限存取作業機具調查模組！";
                return false;
            }

            // 8. 裸露地調查
            if (normPath.StartsWith("BareGround/", StringComparison.OrdinalIgnoreCase))
            {
                string mode = (request != null && request["mode"] != null ? request["mode"].ToString().ToLower() : "");
                if (normPath.IndexOf("NewBare.aspx", StringComparison.OrdinalIgnoreCase) >= 0 || mode == "new" || mode == "reject" || mode == "back")
                {
                    if (MenuService.CheckLicense(lic, 17)) return true;
                    denyReason = "您無權限存取【裸露地調查】功能！";
                    return false;
                }
                if (mode == "identify" || mode == "search")
                {
                    if (MenuService.CheckLicense(lic, 44)) return true;
                    denyReason = "您無權限存取裸露地【調查成果列表】！";
                    return false;
                }
                if (MenuService.CheckLicense(lic, 17) || MenuService.CheckLicense(lic, 44) ||
                    MenuService.CheckLicense(lic, 18) || MenuService.CheckLicense(lic, 19) || MenuService.CheckLicense(lic, 20))
                {
                    return true;
                }
                denyReason = "您無權限存取裸露地模組！";
                return false;
            }

            // 9. 工廠基本資料
            if (normPath.StartsWith("FAC/", StringComparison.OrdinalIgnoreCase))
            {
                string mode = (request != null && request["mode"] != null ? request["mode"].ToString().ToLower() : "");
                if (mode == "edit")
                {
                    if (MenuService.CheckLicense(lic, 2)) return true;
                    denyReason = "您無權限維護逸散源未列管基本資料！";
                    return false;
                }
                if (mode == "mission")
                {
                    if (MenuService.CheckLicense(lic, 0) || MenuService.CheckLicense(lic, 10)) return true;
                    denyReason = "您無權限進行案件派遣設定！";
                    return false;
                }
                if (normPath.IndexOf("oFAC_List.aspx", StringComparison.OrdinalIgnoreCase) >= 0)
                {
                    if (MenuService.CheckLicense(lic, 10) || MenuService.CheckLicense(lic, 41)) return true;
                    denyReason = "您無權限查詢許可證資訊！";
                    return false;
                }
                if (MenuService.CheckLicense(lic, 41) || MenuService.CheckLicense(lic, 2) || MenuService.CheckLicense(lic, 10))
                {
                    return true;
                }
                denyReason = "您無權限存取工廠基本資料功能！";
                return false;
            }

            // 10. 道路潔淨巡檢、道路髒污、破損、覆土
            if (normPath.StartsWith("RoadClean/", StringComparison.OrdinalIgnoreCase))
            {
                string mode = (request != null && request["mode"] != null ? request["mode"].ToString().ToLower() : "");
                if (normPath.IndexOf("Dirty", StringComparison.OrdinalIgnoreCase) >= 0)
                {
                    if (mode.IndexOf("improve", StringComparison.OrdinalIgnoreCase) >= 0)
                    {
                        if (MenuService.CheckLicense(lic, 23)) return true;
                        denyReason = "您無權限存取【路污改善回報】！";
                        return false;
                    }
                    if (mode.IndexOf("finish", StringComparison.OrdinalIgnoreCase) >= 0)
                    {
                        if (MenuService.CheckLicense(lic, 24)) return true;
                        denyReason = "您無權限存取【路污改善成果】！";
                        return false;
                    }
                    if (MenuService.CheckLicense(lic, 21) || MenuService.CheckLicense(lic, 23) || MenuService.CheckLicense(lic, 24)) return true;
                    denyReason = "您無權限存取【道路髒污管理】！";
                    return false;
                }
                // 道路潔淨
                if (normPath.IndexOf("RoadClean_Sum", StringComparison.OrdinalIgnoreCase) >= 0 || mode == "search")
                {
                    if (MenuService.CheckLicense(lic, 24) || MenuService.CheckLicense(lic, 22)) return true;
                    denyReason = "您無權限存取道路潔淨成果或統計！";
                    return false;
                }
                if (MenuService.CheckLicense(lic, 21) || MenuService.CheckLicense(lic, 22) || MenuService.CheckLicense(lic, 24)) return true;
                denyReason = "您無權限存取道路潔淨查核！";
                return false;
            }

            if (normPath.StartsWith("RoadBreak/", StringComparison.OrdinalIgnoreCase))
            {
                string mode = (request != null && request["mode"] != null ? request["mode"].ToString().ToLower() : "");
                if (mode.IndexOf("improve", StringComparison.OrdinalIgnoreCase) >= 0 || mode.IndexOf("finish", StringComparison.OrdinalIgnoreCase) >= 0)
                {
                    if (MenuService.CheckLicense(lic, 27)) return true;
                    denyReason = "您無權限存取【破損改善成果】！";
                    return false;
                }
                if (MenuService.CheckLicense(lic, 26) || MenuService.CheckLicense(lic, 27)) return true;
                denyReason = "您無權限存取【道路破損通報】！";
                return false;
            }

            if (normPath.StartsWith("RoadBSC/", StringComparison.OrdinalIgnoreCase))
            {
                string mode = (request != null && request["mode"] != null ? request["mode"].ToString().ToLower() : "");
                if (mode.IndexOf("improve", StringComparison.OrdinalIgnoreCase) >= 0 || mode.IndexOf("finish", StringComparison.OrdinalIgnoreCase) >= 0)
                {
                    if (MenuService.CheckLicense(lic, 29)) return true;
                    denyReason = "您無權限存取【覆土改善成果】！";
                    return false;
                }
                if (MenuService.CheckLicense(lic, 28) || MenuService.CheckLicense(lic, 29)) return true;
                denyReason = "您無權限存取【裸露覆土通報】！";
                return false;
            }

            // 11. 自主管理回報、洗掃、空品不良
            if (normPath.StartsWith("OwnReport/", StringComparison.OrdinalIgnoreCase))
            {
                string mode = (request != null && request["mode"] != null ? request["mode"].ToString().ToLower() : "");
                if (normPath.IndexOf("AirQuality", StringComparison.OrdinalIgnoreCase) >= 0)
                {
                    if (MenuService.CheckLicense(lic, 45)) return true;
                    denyReason = "您無權限存取【空品應變】功能！";
                    return false;
                }
                if (mode == "wrong")
                {
                    if (MenuService.CheckLicense(lic, 15) || MenuService.CheckLicense(lic, 16)) return true;
                    denyReason = "您無權限存取【缺失改善】功能！";
                    return false;
                }
                if (mode == "own")
                {
                    if (MenuService.CheckLicense(lic, 8) || MenuService.CheckLicense(lic, 9)) return true;
                    denyReason = "您無權限存取【自主維護】功能！";
                    return false;
                }
                if (MenuService.CheckLicense(lic, 8) || MenuService.CheckLicense(lic, 9) ||
                    MenuService.CheckLicense(lic, 15) || MenuService.CheckLicense(lic, 16) || MenuService.CheckLicense(lic, 45))
                {
                    return true;
                }
                denyReason = "您無權限存取自主回報功能！";
                return false;
            }

            if (normPath.StartsWith("Wash/", StringComparison.OrdinalIgnoreCase))
            {
                if (MenuService.CheckLicense(lic, 12) || MenuService.CheckLicense(lic, 13) || MenuService.CheckLicense(lic, 14)) return true;
                denyReason = "您無權限存取道路洗掃認養功能！";
                return false;
            }

            if (normPath.StartsWith("LINE/", StringComparison.OrdinalIgnoreCase))
            {
                if (MenuService.CheckLicense(lic, 45)) return true;
                denyReason = "您無權限存取 LINE 通報設定！";
                return false;
            }

            // 12. NDVI 植被衛星影像
            if (normPath.StartsWith("NDVI/", StringComparison.OrdinalIgnoreCase))
            {
                if (MenuService.CheckLicense(lic, 41)) return true;
                denyReason = "您無權限存取 NDVI 植被衛星影像！";
                return false;
            }

            // 其他未明確列入規則之頁面預設放行
            return true;
        }
    }
}



