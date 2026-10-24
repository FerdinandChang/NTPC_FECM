using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Net;
using System.Security.Cryptography;
using System.Text;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.UI;
using NTPC_FEC.Helpers;
using NPOI.HSSF.UserModel;
using NPOI.SS.UserModel;

namespace NTPC_FEC.Manager
{
    public partial class managerList : Page
    {
        private JavaScriptSerializer json;

        public managerList()
        {
            json = new JavaScriptSerializer();
            json.MaxJsonLength = int.MaxValue;
        }

        protected override void Render(HtmlTextWriter writer)
        {
            if (!string.IsNullOrEmpty(Request["action"]))
            {
                return;
            }
            base.Render(writer);
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            string action = Request["action"];
            if (!string.IsNullOrEmpty(action))
            {
                Response.Clear();
                if (action.ToLower() == "exportexcel")
                {
                    HandleExportExcel();
                    return;
                }
                Response.ContentType = "application/json; charset=utf-8";
                try
                {
                    HandleAjaxAction(action);
                }
                catch (System.Threading.ThreadAbortException)
                {
                    return;
                }
                catch (Exception ex)
                {
                    Response.Clear();
                    Response.ContentType = "application/json; charset=utf-8";
                    Response.Write(json.Serialize(new
                    {
                        Success = false,
                        Message = "執行錯誤：" + ex.Message
                    }));
                }

                try
                {
                    Response.End();
                }
                catch (System.Threading.ThreadAbortException)
                {
                    return;
                }
                return;
            }
        }

        private string GetCurrentUser()
        {
            if (Session["LoginUser"] != null && !string.IsNullOrEmpty(Session["LoginUser"].ToString()))
            {
                return Session["LoginUser"].ToString();
            }
            if (Session["User_ID"] != null && !string.IsNullOrEmpty(Session["User_ID"].ToString()))
            {
                return Session["User_ID"].ToString();
            }
            return "系統管理員";
        }

        private void HandleAjaxAction(string action)
        {
            switch (action.ToLower())
            {
                case "get_init_data":
                    GetInitData();
                    break;
                case "get_list":
                    GetFacList();
                    break;
                case "get_cases":
                    GetFacCases();
                    break;
                case "get_single_check_url":
                    GetSingleCheckUrl();
                    break;
                case "batch_pass":
                    BatchPass();
                    break;
                case "get_company_info":
                    GetCompanyInfo();
                    break;
                default:
                    Response.Write(json.Serialize(new { Success = false, Message = "未知操作" }));
                    break;
            }
        }

        private void GetInitData()
        {
            string currentUserId = GetCurrentUser();
            DataTable dtTown = null;
            try
            {
                string sqlTown = "SELECT TOWN_NO, TOWN_NA FROM C_TOWN WHERE COUNTRY = 'F' ORDER BY TOWN_NO";
                dtTown = DbHelper.ExecuteDataTable(sqlTown);
            }
            catch (Exception ex)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "載入行政區失敗：" + ex.Message }));
                return;
            }

            List<Dictionary<string, object>> townList = new List<Dictionary<string, object>>();
            List<string> selectedTowns = new List<string>();

            if (dtTown != null)
            {
                foreach (DataRow row in dtTown.Rows)
                {
                    Dictionary<string, object> t = new Dictionary<string, object>();
                    string code = row["TOWN_NO"].ToString();
                    t["Code"] = code;
                    t["Name"] = row["TOWN_NA"].ToString();
                    townList.Add(t);
                }
            }

            try
            {
                string sqlUserTown = "SELECT TOWN_NO FROM UserFilterTown WHERE User_ID = @User_ID";
                DataTable dtUserTown = DbHelper.ExecuteDataTable(sqlUserTown, new SqlParameter("@User_ID", currentUserId));
                if (dtUserTown != null && dtUserTown.Rows.Count > 0)
                {
                    foreach (DataRow r in dtUserTown.Rows)
                    {
                        selectedTowns.Add(r["TOWN_NO"].ToString());
                    }
                }
                else
                {
                    foreach (Dictionary<string, object> t in townList)
                    {
                        selectedTowns.Add(t["Code"].ToString());
                    }
                }
            }
            catch
            {
                foreach (Dictionary<string, object> t in townList)
                {
                    selectedTowns.Add(t["Code"].ToString());
                }
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                CurrentUser = currentUserId,
                TownList = townList,
                SelectedTowns = selectedTowns
            }));
        }

        private void GetFacList()
        {
            string invState = Request["invState"];
            if (string.IsNullOrEmpty(invState))
            {
                invState = "INV1";
            }
            invState = invState.ToUpper();

            string facName = (Request["facName"] ?? "").Trim();
            string cno = (Request["cno"] ?? "").Trim();
            string scid = (Request["scid"] ?? "").Trim();
            string townCodes = (Request["townCodes"] ?? "").Trim();

            string stateCode = "";
            string countColName = "";
            string spName = "";
            bool isInv = true;

            switch (invState)
            {
                case "INV1":
                    stateCode = "A00";
                    countColName = "初審件數";
                    spName = "Get_Check_INV_FAC_Main_BySearch";
                    isInv = true;
                    break;
                case "INV2":
                    stateCode = "A01";
                    countColName = "複審件數";
                    spName = "Get_Check_INV_FAC_Main_BySearch";
                    isInv = true;
                    break;
                case "INV3":
                    stateCode = "A02";
                    countColName = "三審件數";
                    spName = "Get_Check_INV_FAC_Main_BySearch";
                    isInv = true;
                    break;
                case "INVSM1":
                    stateCode = "A02";
                    countColName = "2項缺失以上案件數";
                    spName = "Get_Check_INV_FAC_Main_BySearch";
                    isInv = true;
                    break;
                case "MAC1":
                    stateCode = "A00";
                    countColName = "初審件數";
                    spName = "Get_Check_Mac_FAC_Main_BySearch";
                    isInv = false;
                    break;
                case "MAC2":
                    stateCode = "A01";
                    countColName = "複審件數";
                    spName = "Get_Check_Mac_FAC_Main_BySearch";
                    isInv = false;
                    break;
                case "MAC3":
                    stateCode = "A02";
                    countColName = "三審件數";
                    spName = "Get_Check_Mac_FAC_Main_BySearch";
                    isInv = false;
                    break;
                default:
                    stateCode = "A00";
                    countColName = "初審件數";
                    spName = "Get_Check_INV_FAC_Main_BySearch";
                    isInv = true;
                    break;
            }

            DataTable dtResult = null;
            try
            {
                using (SqlConnection conn = DbHelper.GetOpenConnection())
                using (SqlCommand cmd = new SqlCommand(spName, conn))
                {
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.CommandTimeout = 120;

                    cmd.Parameters.Add(new SqlParameter("@Where_FAC_NAME", string.IsNullOrEmpty(facName) ? (object)DBNull.Value : facName));
                    cmd.Parameters.Add(new SqlParameter("@Where_C_NO", string.IsNullOrEmpty(cno) ? (object)DBNull.Value : cno));
                    cmd.Parameters.Add(new SqlParameter("@Where_S_C_ID", string.IsNullOrEmpty(scid) ? (object)DBNull.Value : scid));
                    if (isInv)
                    {
                        cmd.Parameters.Add(new SqlParameter("@Where_INV_State", stateCode));
                    }
                    else
                    {
                        cmd.Parameters.Add(new SqlParameter("@Where_Mac_State", stateCode));
                    }
                    cmd.Parameters.Add(new SqlParameter("@CountColName", countColName));

                    using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                    {
                        dtResult = new DataTable();
                        da.Fill(dtResult);
                    }
                }
            }
            catch (Exception ex)
            {
                Response.Write(json.Serialize(new
                {
                    Success = false,
                    Message = "查詢執行失敗：" + ex.Message
                }));
                return;
            }

            DataTable dtTown = null;
            try
            {
                dtTown = DbHelper.ExecuteDataTable("SELECT TOWN_NO, TOWN_NA FROM C_TOWN WHERE COUNTRY = 'F'");
            }
            catch { }

            Dictionary<string, string> townDict = new Dictionary<string, string>();
            if (dtTown != null)
            {
                foreach (DataRow r in dtTown.Rows)
                {
                    string tno = r["TOWN_NO"].ToString();
                    if (!townDict.ContainsKey(tno))
                    {
                        townDict.Add(tno, r["TOWN_NA"].ToString());
                    }
                }
            }

            HashSet<string> filterTowns = new HashSet<string>();
            if (!string.IsNullOrEmpty(townCodes))
            {
                string[] parts = townCodes.Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
                foreach (string p in parts)
                {
                    filterTowns.Add(p.Trim());
                }
            }

            List<Dictionary<string, object>> allItems = new List<Dictionary<string, object>>();
            int statTotalFac = 0;
            int statTotalCases = 0;
            int statZeroLoss = 0;
            int statMinorLoss = 0;
            int statMajorLoss = 0;

            if (dtResult != null)
            {
                foreach (DataRow row in dtResult.Rows)
                {
                    string tcode = row.Table.Columns.Contains("TOWN_CODE") ? row["TOWN_CODE"].ToString() : "";
                    if (filterTowns.Count > 0 && !filterTowns.Contains(tcode))
                    {
                        continue;
                    }

                    string facId = row["FAC_ID"].ToString();
                    string cNoVal = row.Table.Columns.Contains("C_NO") ? row["C_NO"].ToString() : "";
                    string facNameVal = row.Table.Columns.Contains("FAC_NAME") ? row["FAC_NAME"].ToString() : "";
                    string scidVal = row.Table.Columns.Contains("S_C_ID") ? row["S_C_ID"].ToString() : "";
                    string townName = townDict.ContainsKey(tcode) ? townDict[tcode] : tcode;

                    int caseCount = 0;
                    if (row.Table.Columns.Contains("Case_Count") && row["Case_Count"] != DBNull.Value)
                    {
                        int.TryParse(row["Case_Count"].ToString(), out caseCount);
                    }

                    int lossPoint = 0;
                    string lossDetail = "";
                    string lossCss = "";

                    if (isInv)
                    {
                        try
                        {
                            string sqlLastInv = "SELECT TOP 1 * FROM INV_DATA WHERE FAC_ID = @FAC_ID AND INV_State = @INV_State ORDER BY INV_NO DESC";
                            DataTable dtLastInv = DbHelper.ExecuteDataTable(sqlLastInv, 
                                new SqlParameter("@FAC_ID", facId),
                                new SqlParameter("@INV_State", stateCode));
                            if (dtLastInv != null && dtLastInv.Rows.Count > 0)
                            {
                                DataRow invRow = dtLastInv.Rows[0];
                                lossPoint = LossPointCalculator.CalTotalLossPoint(invRow);
                                lossDetail = LossPointCalculator.GetAllLossDetail(invRow);
                            }
                        }
                        catch { }

                        if (lossPoint == 0)
                        {
                            lossCss = "loss-zero";
                            statZeroLoss++;
                        }
                        else if (lossPoint > 0 && lossPoint < 10)
                        {
                            lossCss = "loss-minor";
                            statMinorLoss++;
                        }
                        else
                        {
                            lossCss = "loss-major";
                            statMajorLoss++;
                        }
                    }
                    else
                    {
                        statZeroLoss++;
                    }

                    statTotalFac++;
                    statTotalCases += caseCount;

                    bool canBatchSelect = false;
                    if (isInv && (invState == "INV2" || invState == "INV3"))
                    {
                        if (lossPoint == 0)
                        {
                            canBatchSelect = true;
                        }
                    }

                    Dictionary<string, object> item = new Dictionary<string, object>();
                    item["FAC_ID"] = facId;
                    item["C_NO"] = cNoVal;
                    item["FAC_NAME"] = facNameVal;
                    item["S_C_ID"] = scidVal;
                    item["TOWN_CODE"] = tcode;
                    item["TOWN_Name"] = townName;
                    item["Case_Count"] = caseCount;
                    item["Loss_Point"] = lossPoint;
                    item["Loss_Detail"] = lossDetail;
                    item["Loss_CSS"] = lossCss;
                    item["CanBatchSelect"] = canBatchSelect;

                    allItems.Add(item);
                }
            }

            allItems.Sort(delegate(Dictionary<string, object> a, Dictionary<string, object> b)
            {
                int pA = (int)a["Loss_Point"];
                int pB = (int)b["Loss_Point"];
                return pB.CompareTo(pA);
            });

            Response.Write(json.Serialize(new
            {
                Success = true,
                Items = allItems,
                CountColName = countColName,
                Stats = new
                {
                    TotalFac = statTotalFac,
                    TotalCases = statTotalCases,
                    ZeroLoss = statZeroLoss,
                    MinorLoss = statMinorLoss,
                    MajorLoss = statMajorLoss
                }
            }));
        }

        private void GetFacCases()
        {
            string facId = (Request["facId"] ?? "").Trim();
            string invState = (Request["invState"] ?? "INV1").Trim().ToUpper();

            if (string.IsNullOrEmpty(facId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "缺少場所代碼" }));
                return;
            }

            bool isInv = invState.StartsWith("INV");
            List<Dictionary<string, object>> caseList = new List<Dictionary<string, object>>();

            if (isInv)
            {
                string sql = "SELECT INV_DATA.*, INV_State_List.State_Name FROM INV_DATA LEFT JOIN INV_State_List ON INV_DATA.INV_State = INV_State_List.State_ID WHERE FAC_ID = @FAC_ID ORDER BY INV_DATE DESC";
                DataTable dt = DbHelper.ExecuteDataTable(sql, new SqlParameter("@FAC_ID", facId));
                if (dt != null)
                {
                    foreach (DataRow r in dt.Rows)
                    {
                        string currentCaseState = r["INV_State"].ToString();
                        string invNoStr = r["INV_NO"].ToString();
                        int lossPoint = LossPointCalculator.CalTotalLossPoint(r);
                        string lossDetail = LossPointCalculator.GetAllLossDetail(r);
                        string invDateStr = "";
                        if (r["INV_DATE"] != DBNull.Value)
                        {
                            DateTime dtVal;
                            if (DateTime.TryParse(r["INV_DATE"].ToString(), out dtVal))
                            {
                                invDateStr = dtVal.ToString("yyyy/MM/dd HH:mm");
                            }
                        }

                        bool canFirstChk = (invState == "INV1" && currentCaseState == "A00");
                        bool canDoubleChk = (invState == "INV2" && currentCaseState == "A01");
                        bool canTroubleChk = (invState == "INV3" && currentCaseState == "A02");

                        string checkUrl = "";
                        if (canFirstChk)
                        {
                            string token = ComputeMD5("INV1" + facId + DateTime.Today.ToString("yyyyMMdd"));
                            checkUrl = string.Format("Check_Step1.aspx?mode=INV1&fac={0}&fac1={1}&inv={2}", facId, token, invNoStr);
                        }
                        else if (canDoubleChk)
                        {
                            string token = ComputeMD5("INV2" + facId + DateTime.Today.ToString("yyyyMMdd"));
                            checkUrl = string.Format("Check_Step1.aspx?mode=INV2&fac={0}&fac1={1}&inv={2}", facId, token, invNoStr);
                        }
                        else if (canTroubleChk)
                        {
                            string token = ComputeMD5("INV3" + facId + DateTime.Today.ToString("yyyyMMdd"));
                            checkUrl = string.Format("Check_Step1.aspx?mode=INV3&fac={0}&fac1={1}&inv={2}", facId, token, invNoStr);
                        }

                        string viewToken = ComputeMD5("MD5:" + facId + DateTime.Now.ToString("yyyyMMddHH"));
                        string viewUrl = string.Format("../case/CaseResult.aspx?id={0}&id1={1}&id2={2}&back=2&mode=read", facId, viewToken, invNoStr);

                        Dictionary<string, object> c = new Dictionary<string, object>();
                        c["CaseId"] = invNoStr;
                        c["CaseDate"] = invDateStr;
                        c["WorkState"] = r.Table.Columns.Contains("Work_State") ? r["Work_State"].ToString() : "";
                        c["LossPoint"] = lossPoint;
                        c["LossDetail"] = lossDetail;
                        c["StateName"] = r.Table.Columns.Contains("State_Name") ? r["State_Name"].ToString() : currentCaseState;
                        c["CanFirstChk"] = canFirstChk;
                        c["CanDoubleChk"] = canDoubleChk;
                        c["CanTroubleChk"] = canTroubleChk;
                        c["CheckUrl"] = checkUrl;
                        c["ViewUrl"] = viewUrl;

                        caseList.Add(c);
                    }
                }
            }
            else
            {
                string sql = "SELECT Machine_Main.*, mac_State_List.State_Name FROM Machine_Main LEFT JOIN mac_State_List ON Machine_Main.Mac_State = mac_State_List.State_ID WHERE FAC_ID = @FAC_ID ORDER BY Check_date DESC";
                DataTable dt = DbHelper.ExecuteDataTable(sql, new SqlParameter("@FAC_ID", facId));
                if (dt != null)
                {
                    foreach (DataRow r in dt.Rows)
                    {
                        string currentCaseState = r["Mac_State"].ToString();
                        string macIdStr = r["mac_ID"].ToString();
                        string checkDateStr = "";
                        if (r["Check_date"] != DBNull.Value)
                        {
                            DateTime dtVal;
                            if (DateTime.TryParse(r["Check_date"].ToString(), out dtVal))
                            {
                                checkDateStr = dtVal.ToString("yyyy/MM/dd HH:mm");
                            }
                        }

                        bool canFirstChk = (invState == "MAC1" && currentCaseState == "A00");
                        bool canDoubleChk = (invState == "MAC2" && currentCaseState == "A01");
                        bool canTroubleChk = (invState == "MAC3" && currentCaseState == "A02");

                        string checkUrl = "";
                        if (canFirstChk)
                        {
                            string token = ComputeMD5("MAC1" + facId + DateTime.Today.ToString("yyyyMMdd"));
                            checkUrl = string.Format("Check_Step1_Mac.aspx?mode=MAC1&fac={0}&fac1={1}&macid={2}", facId, token, macIdStr);
                        }
                        else if (canDoubleChk)
                        {
                            string token = ComputeMD5("MAC2" + facId + DateTime.Today.ToString("yyyyMMdd"));
                            checkUrl = string.Format("Check_Step1_Mac.aspx?mode=MAC2&fac={0}&fac1={1}&macid={2}", facId, token, macIdStr);
                        }
                        else if (canTroubleChk)
                        {
                            string token = ComputeMD5("MAC3" + facId + DateTime.Today.ToString("yyyyMMdd"));
                            checkUrl = string.Format("Check_Step1_Mac.aspx?mode=MAC3&fac={0}&fac1={1}&macid={2}", facId, token, macIdStr);
                        }

                        string readToken = ComputeMD5("READ" + invState + facId + DateTime.Today.ToString("yyyyMMdd"));
                        string viewUrl = string.Format("../manager/Check_Step1_Mac.aspx?mode=READ{0}&fac={1}&fac1={2}&macid={3}", invState, facId, readToken, macIdStr);

                        Dictionary<string, object> c = new Dictionary<string, object>();
                        c["CaseId"] = macIdStr;
                        c["CaseDate"] = checkDateStr;
                        c["MacType"] = r.Table.Columns.Contains("mac_Type") ? r["mac_Type"].ToString() : "";
                        c["Brand"] = r.Table.Columns.Contains("Brand") ? r["Brand"].ToString() : "";
                        c["Model"] = r.Table.Columns.Contains("model") ? r["model"].ToString() : "";
                        c["StateName"] = r.Table.Columns.Contains("State_Name") ? r["State_Name"].ToString() : currentCaseState;
                        c["CanFirstChk"] = canFirstChk;
                        c["CanDoubleChk"] = canDoubleChk;
                        c["CanTroubleChk"] = canTroubleChk;
                        c["CheckUrl"] = checkUrl;
                        c["ViewUrl"] = viewUrl;

                        caseList.Add(c);
                    }
                }
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                Cases = caseList
            }));
        }

        private void GetSingleCheckUrl()
        {
            string facId = (Request["facId"] ?? "").Trim();
            string invState = (Request["invState"] ?? "INV1").Trim().ToUpper();

            if (string.IsNullOrEmpty(facId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "缺少場所代碼" }));
                return;
            }

            bool isInv = invState.StartsWith("INV");
            string stateCode = "";
            switch (invState)
            {
                case "INV1": stateCode = "A00"; break;
                case "INV2": stateCode = "A01"; break;
                case "INV3": stateCode = "A02"; break;
                case "MAC1": stateCode = "A00"; break;
                case "MAC2": stateCode = "A01"; break;
                case "MAC3": stateCode = "A02"; break;
                default: stateCode = "A00"; break;
            }

            if (isInv)
            {
                string sql = "SELECT TOP 1 INV_NO FROM INV_DATA WHERE FAC_ID = @FAC_ID AND INV_State = @INV_State ORDER BY INV_NO DESC";
                object val = DbHelper.ExecuteScalar(sql, 
                    new SqlParameter("@FAC_ID", facId),
                    new SqlParameter("@INV_State", stateCode));
                if (val == null || val == DBNull.Value)
                {
                    Response.Write(json.Serialize(new { Success = false, Message = "找不到該場所符合審核條件之案件" }));
                    return;
                }
                string invNo = val.ToString();
                string token = ComputeMD5(invState + facId + DateTime.Today.ToString("yyyyMMdd"));
                string url = string.Format("Check_Step1.aspx?mode={0}&fac={1}&fac1={2}&inv={3}", invState, facId, token, invNo);

                Response.Write(json.Serialize(new { Success = true, CheckUrl = url }));
            }
            else
            {
                string sql = "SELECT TOP 1 mac_ID FROM Machine_Main WHERE FAC_ID = @FAC_ID AND Mac_State = @Mac_State ORDER BY mac_ID DESC";
                object val = DbHelper.ExecuteScalar(sql, 
                    new SqlParameter("@FAC_ID", facId),
                    new SqlParameter("@Mac_State", stateCode));
                if (val == null || val == DBNull.Value)
                {
                    Response.Write(json.Serialize(new { Success = false, Message = "找不到該場所符合審核條件之機具" }));
                    return;
                }
                string macId = val.ToString();
                string token = ComputeMD5(invState + facId + DateTime.Today.ToString("yyyyMMdd"));
                string url = string.Format("Check_Step1_Mac.aspx?mode={0}&fac={1}&fac1={2}&macid={3}", invState, facId, token, macId);

                Response.Write(json.Serialize(new { Success = true, CheckUrl = url }));
            }
        }

        private void BatchPass()
        {
            string invState = (Request["invState"] ?? "").Trim().ToUpper();
            string facIdsRaw = (Request["facIds"] ?? "").Trim();

            if (invState != "INV2" && invState != "INV3")
            {
                Response.Write(json.Serialize(new { Success = false, Message = "當前審核階段不支援批次通過功能" }));
                return;
            }

            if (string.IsNullOrEmpty(facIdsRaw))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "請先勾選欲批次通過之場所" }));
                return;
            }

            string[] facIdArr = facIdsRaw.Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
            if (facIdArr.Length == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "未選取任何場所" }));
                return;
            }

            string currentState = (invState == "INV2") ? "A01" : "A02";
            string nextState = "";

            try
            {
                string sqlNext = "SELECT Next_State FROM INV_State_List WHERE State_ID = @State_ID";
                object nsObj = DbHelper.ExecuteScalar(sqlNext, new SqlParameter("@State_ID", currentState));
                if (nsObj != null && nsObj != DBNull.Value)
                {
                    nextState = nsObj.ToString();
                }
            }
            catch { }

            if (string.IsNullOrEmpty(nextState))
            {
                nextState = (currentState == "A01") ? "A02" : "A03";
            }

            string currentUser = GetCurrentUser();
            int passedCount = 0;

            foreach (string facId in facIdArr)
            {
                string fid = facId.Trim();
                if (string.IsNullOrEmpty(fid)) continue;

                string sqlInv = "SELECT * FROM INV_DATA WHERE FAC_ID = @FAC_ID AND INV_State = @INV_State";
                DataTable dtInv = DbHelper.ExecuteDataTable(sqlInv, 
                    new SqlParameter("@FAC_ID", fid),
                    new SqlParameter("@INV_State", currentState));

                if (dtInv != null)
                {
                    foreach (DataRow row in dtInv.Rows)
                    {
                        if (LossPointCalculator.CalTotalLossPoint(row) == 0)
                        {
                            int invNo = Convert.ToInt32(row["INV_NO"]);

                            string sqlInsertResult = "INSERT INTO INV_Chk_Result (FAC_ID, INV_NO, Chk_Date, Chk_Result, Chk_Memo, INV_State, Chk_User) VALUES (@FAC_ID, @INV_NO, @Chk_Date, @Chk_Result, @Chk_Memo, @INV_State, @Chk_User)";
                            DbHelper.ExecuteNonQuery(sqlInsertResult,
                                new SqlParameter("@FAC_ID", fid),
                                new SqlParameter("@INV_NO", invNo),
                                new SqlParameter("@Chk_Date", DateTime.Now),
                                new SqlParameter("@Chk_Result", "通過"),
                                new SqlParameter("@Chk_Memo", "批次通過"),
                                new SqlParameter("@INV_State", currentState),
                                new SqlParameter("@Chk_User", currentUser));

                            string sqlUpdateInv = "UPDATE INV_DATA SET INV_State = @Next_State WHERE FAC_ID = @FAC_ID AND INV_NO = @INV_NO";
                            DbHelper.ExecuteNonQuery(sqlUpdateInv,
                                new SqlParameter("@Next_State", nextState),
                                new SqlParameter("@FAC_ID", fid),
                                new SqlParameter("@INV_NO", invNo));

                            passedCount++;
                        }
                    }
                }
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                Message = string.Format("批次審核成功！共推進 {0} 筆合格案件至下一階段", passedCount),
                PassedCount = passedCount
            }));
        }

        private void GetCompanyInfo()
        {
            string scid = (Request["scid"] ?? "").Trim();
            if (string.IsNullOrEmpty(scid))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "缺少統一編號" }));
                return;
            }

            string apiUrl = "http://data.gcis.nat.gov.tw/od/data/api/5F64D864-61CB-4D0D-8AD9-492047CC1EA6?$format=json&$filter=Business_Accounting_NO%20eq%20" + scid;
            string jsonResp = "";

            try
            {
                HttpWebRequest req = (HttpWebRequest)WebRequest.Create(apiUrl);
                req.Method = "GET";
                req.Timeout = 8000;
                req.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)";

                using (HttpWebResponse resp = (HttpWebResponse)req.GetResponse())
                using (StreamReader sr = new StreamReader(resp.GetResponseStream(), Encoding.UTF8))
                {
                    jsonResp = sr.ReadToEnd();
                }
            }
            catch (Exception ex)
            {
                Response.Write(json.Serialize(new
                {
                    Success = false,
                    Message = "商工資料查詢失敗（連線異常）：" + ex.Message
                }));
                return;
            }

            if (string.IsNullOrEmpty(jsonResp))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "查無此統一編號之商工登記資料" }));
                return;
            }

            try
            {
                object[] arr = json.Deserialize<object[]>(jsonResp);
                if (arr != null && arr.Length > 0)
                {
                    Dictionary<string, object> obj = (Dictionary<string, object>)arr[0];
                    Response.Write(json.Serialize(new
                    {
                        Success = true,
                        SCID = scid,
                        CompanyName = obj.ContainsKey("Company_Name") ? obj["Company_Name"] : "",
                        CompanyStatus = obj.ContainsKey("Company_Status_Desc") ? obj["Company_Status_Desc"] : "",
                        ResponsibleName = obj.ContainsKey("Responsible_Name") ? obj["Responsible_Name"] : "",
                        CompanyLocation = obj.ContainsKey("Company_Location") ? obj["Company_Location"] : ""
                    }));
                }
                else
                {
                    Response.Write(json.Serialize(new { Success = false, Message = "查無此統一編號商工登記記錄" }));
                }
            }
            catch (Exception ex)
            {
                Response.Write(json.Serialize(new
                {
                    Success = false,
                    Message = "解析商工資料失敗：" + ex.Message
                }));
            }
        }

        private static string ComputeMD5(string input)
        {
            if (string.IsNullOrEmpty(input)) return "";
            using (MD5 md5 = MD5.Create())
            {
                byte[] bytes = md5.ComputeHash(Encoding.UTF8.GetBytes(input));
                StringBuilder sb = new StringBuilder();
                for (int i = 0; i < bytes.Length; i++)
                {
                    sb.Append(bytes[i].ToString("x2"));
                }
                return sb.ToString();
            }
        }

        public static class LossPointCalculator
        {
            public static int CalTotalLossPoint(DataRow pRow)
            {
                if (pRow == null) return 0;
                int n1 = 0, n2 = 0, n3 = 0, n4 = 0, n5 = 0, n6 = 0, n7 = 0, n8 = 0, n9 = 0;

                // 1. 堆置
                if (IsY(pRow, "INV_01_04") || IsY(pRow, "INV_01_05"))
                {
                    n1 = 10;
                }
                else if (IsY(pRow, "INV_01_08") || IsY(pRow, "INV_01_09") || IsY(pRow, "INV_01_09a") || IsY(pRow, "INV_01_09b") ||
                         IsY(pRow, "INV_01_09c") || IsY(pRow, "INV_01_09d") || IsY(pRow, "INV_01_10") || IsY(pRow, "INV_01_10a") ||
                         IsY(pRow, "INV_01_10b") || IsY(pRow, "INV_01_11") || IsY(pRow, "INV_01_11a") || IsY(pRow, "INV_01_11b") ||
                         IsY(pRow, "INV_01_11c") || IsY(pRow, "INV_01_12") || IsY(pRow, "INV_01_12a") || IsY(pRow, "INV_01_12b") ||
                         IsY(pRow, "INV_01_12c") || IsY(pRow, "INV_01_13") || IsY(pRow, "INV_01_14") || IsY(pRow, "INV_01_07"))
                {
                    n1 = 4;
                }

                // 2. 輸送
                if (IsY(pRow, "INV_02_05") || IsY(pRow, "INV_02_06"))
                {
                    n2 = 10;
                }
                else if (IsY(pRow, "INV_02_07") || IsY(pRow, "INV_02_08") || IsY(pRow, "INV_02_09") || IsY(pRow, "INV_02_09a") ||
                         IsY(pRow, "INV_02_09b") || IsY(pRow, "INV_02_10") || IsY(pRow, "INV_02_10a") || IsY(pRow, "INV_02_10b") ||
                         IsY(pRow, "INV_02_10c") || IsY(pRow, "INV_02_11"))
                {
                    n2 = 4;
                }

                // 3. 運輸車輛
                if (IsY(pRow, "INV_03_04") || IsY(pRow, "INV_03_05") || IsY(pRow, "INV_03_06"))
                {
                    n3 = 10;
                }
                else if (IsY(pRow, "INV_03_07") || IsY(pRow, "INV_03_08") || IsY(pRow, "INV_03_09"))
                {
                    n3 = 4;
                }

                // 4. 車輛通行路徑
                if (IsY(pRow, "INV_04_04") || IsY(pRow, "INV_04_05"))
                {
                    n4 = 10;
                }
                else if (IsY(pRow, "INV_04_06") || IsY(pRow, "INV_04_07") || IsY(pRow, "INV_04_08") || IsY(pRow, "INV_04_09"))
                {
                    n4 = 4;
                }

                // 5. 車輛清洗
                if (IsY(pRow, "INV_05_04") || IsY(pRow, "INV_05_05") || IsY(pRow, "INV_05_06"))
                {
                    n5 = 10;
                }
                else if (IsY(pRow, "INV_05_07") || IsY(pRow, "INV_05_08") || IsY(pRow, "INV_05_09") || IsY(pRow, "INV_05_10") || IsY(pRow, "INV_05_11"))
                {
                    n5 = 4;
                }

                // 6. 製程逸散
                if (IsY(pRow, "INV_06_05") || IsY(pRow, "INV_06_06"))
                {
                    n6 = 10;
                }
                else if (IsY(pRow, "INV_06_07") || IsY(pRow, "INV_06_07a") || IsY(pRow, "INV_06_07b") || IsY(pRow, "INV_06_08") ||
                         IsY(pRow, "INV_06_08a") || IsY(pRow, "INV_06_08b") || IsY(pRow, "INV_06_09") || IsY(pRow, "INV_06_10") ||
                         IsY(pRow, "INV_06_11") || IsY(pRow, "INV_06_12"))
                {
                    n6 = 4;
                }

                // 7. 裸露區域
                if (IsY(pRow, "INV_07_04") || IsY(pRow, "INV_07_05"))
                {
                    n7 = 10;
                }
                else if (IsY(pRow, "INV_07_06") || IsY(pRow, "INV_07_07") || IsY(pRow, "INV_07_08") || IsY(pRow, "INV_07_09") ||
                         IsY(pRow, "INV_07_10") || IsY(pRow, "INV_07_11"))
                {
                    n7 = 4;
                }

                // 8. 道路
                if (IsY(pRow, "INV_08_04") || IsY(pRow, "INV_08_05"))
                {
                    n8 = 10;
                }
                else if (IsY(pRow, "INV_08_06") || IsY(pRow, "INV_08_07") || IsY(pRow, "INV_08_08") || IsY(pRow, "INV_08_09") || IsY(pRow, "INV_08_10"))
                {
                    n8 = 4;
                }

                // 9. 監視系統
                if (IsY(pRow, "INV_09_04") || IsY(pRow, "INV_09_05") || IsY(pRow, "INV_09_06"))
                {
                    n9 = 10;
                }
                else if (IsY(pRow, "INV_09_07") || IsY(pRow, "INV_09_08"))
                {
                    n9 = 4;
                }

                return n1 + n2 + n3 + n4 + n5 + n6 + n7 + n8 + n9;
            }

            public static string GetAllLossDetail(DataRow pRow)
            {
                if (pRow == null) return "無缺失";

                int n1 = 0, n2 = 0, n3 = 0, n4 = 0, n5 = 0, n6 = 0, n7 = 0, n8 = 0, n9 = 0;

                if (IsY(pRow, "INV_01_04") || IsY(pRow, "INV_01_05")) n1 = 10;
                else if (IsY(pRow, "INV_01_08") || IsY(pRow, "INV_01_09") || IsY(pRow, "INV_01_09a") || IsY(pRow, "INV_01_09b") ||
                         IsY(pRow, "INV_01_09c") || IsY(pRow, "INV_01_09d") || IsY(pRow, "INV_01_10") || IsY(pRow, "INV_01_10a") ||
                         IsY(pRow, "INV_01_10b") || IsY(pRow, "INV_01_11") || IsY(pRow, "INV_01_11a") || IsY(pRow, "INV_01_11b") ||
                         IsY(pRow, "INV_01_11c") || IsY(pRow, "INV_01_12") || IsY(pRow, "INV_01_12a") || IsY(pRow, "INV_01_12b") ||
                         IsY(pRow, "INV_01_12c") || IsY(pRow, "INV_01_13") || IsY(pRow, "INV_01_14") || IsY(pRow, "INV_01_07")) n1 = 4;

                if (IsY(pRow, "INV_02_05") || IsY(pRow, "INV_02_06")) n2 = 10;
                else if (IsY(pRow, "INV_02_07") || IsY(pRow, "INV_02_08") || IsY(pRow, "INV_02_09") || IsY(pRow, "INV_02_09a") ||
                         IsY(pRow, "INV_02_09b") || IsY(pRow, "INV_02_10") || IsY(pRow, "INV_02_10a") || IsY(pRow, "INV_02_10b") ||
                         IsY(pRow, "INV_02_10c") || IsY(pRow, "INV_02_11")) n2 = 4;

                if (IsY(pRow, "INV_03_04") || IsY(pRow, "INV_03_05") || IsY(pRow, "INV_03_06")) n3 = 10;
                else if (IsY(pRow, "INV_03_07") || IsY(pRow, "INV_03_08") || IsY(pRow, "INV_03_09")) n3 = 4;

                if (IsY(pRow, "INV_04_04") || IsY(pRow, "INV_04_05")) n4 = 10;
                else if (IsY(pRow, "INV_04_06") || IsY(pRow, "INV_04_07") || IsY(pRow, "INV_04_08") || IsY(pRow, "INV_04_09")) n4 = 4;

                if (IsY(pRow, "INV_05_04") || IsY(pRow, "INV_05_05") || IsY(pRow, "INV_05_06")) n5 = 10;
                else if (IsY(pRow, "INV_05_07") || IsY(pRow, "INV_05_08") || IsY(pRow, "INV_05_09") || IsY(pRow, "INV_05_10") || IsY(pRow, "INV_05_11")) n5 = 4;

                if (IsY(pRow, "INV_06_05") || IsY(pRow, "INV_06_06")) n6 = 10;
                else if (IsY(pRow, "INV_06_07") || IsY(pRow, "INV_06_07a") || IsY(pRow, "INV_06_07b") || IsY(pRow, "INV_06_08") ||
                         IsY(pRow, "INV_06_08a") || IsY(pRow, "INV_06_08b") || IsY(pRow, "INV_06_09") || IsY(pRow, "INV_06_10") ||
                         IsY(pRow, "INV_06_11") || IsY(pRow, "INV_06_12")) n6 = 4;

                if (IsY(pRow, "INV_07_04") || IsY(pRow, "INV_07_05")) n7 = 10;
                else if (IsY(pRow, "INV_07_06") || IsY(pRow, "INV_07_07") || IsY(pRow, "INV_07_08") || IsY(pRow, "INV_07_09") ||
                         IsY(pRow, "INV_07_10") || IsY(pRow, "INV_07_11")) n7 = 4;

                if (IsY(pRow, "INV_08_04") || IsY(pRow, "INV_08_05")) n8 = 10;
                else if (IsY(pRow, "INV_08_06") || IsY(pRow, "INV_08_07") || IsY(pRow, "INV_08_08") || IsY(pRow, "INV_08_09") || IsY(pRow, "INV_08_10")) n8 = 4;

                if (IsY(pRow, "INV_09_04") || IsY(pRow, "INV_09_05") || IsY(pRow, "INV_09_06")) n9 = 10;
                else if (IsY(pRow, "INV_09_07") || IsY(pRow, "INV_09_08")) n9 = 4;

                StringBuilder sb = new StringBuilder();
                if (n1 > 0) sb.Append(string.Format("一、堆置逸散性粒狀污染物質(記{0}點)；", n1));
                if (n2 > 0) sb.Append(string.Format("二、輸送逸散性粒狀污染物質(記{0}點)；", n2));
                if (n3 > 0) sb.Append(string.Format("三、運輸車輛(記{0}點)；", n3));
                if (n4 > 0) sb.Append(string.Format("四、車輛通行路徑及區域(記{0}點)；", n4));
                if (n5 > 0) sb.Append(string.Format("五、車輛清洗(記{0}點)；", n5));
                if (n6 > 0) sb.Append(string.Format("六、製程/操作/裝卸作業(記{0}點)；", n6));
                if (n7 > 0) sb.Append(string.Format("七、公私場所裸露區域(記{0}點)；", n7));
                if (n8 > 0) sb.Append(string.Format("八、公私場所管理道路(記{0}點)；", n8));
                if (n9 > 0) sb.Append(string.Format("九、攝錄影監視系統(記{0}點)；", n9));

                if (sb.Length == 0) return "無缺失";
                return sb.ToString().TrimEnd('；');
            }

            private static bool IsY(DataRow row, string colName)
            {
                if (!row.Table.Columns.Contains(colName)) return false;
                if (row[colName] == DBNull.Value) return false;
                return row[colName].ToString().Trim() == "Y";
            }
        }
    
        #region 匯出 Excel 報表
        private void HandleExportExcel()
        {
            try
            {
                string mode = Request["mode"] != null ? Request["mode"].Trim() : "INV1";
                string facName = Request["facName"] != null ? Request["facName"].Trim() : "";
                string cno = Request["cno"] != null ? Request["cno"].Trim() : "";
                string scid = Request["scid"] != null ? Request["scid"].Trim() : "";
                string towns = Request["towns"] != null ? Request["towns"].Trim() : "";

                StringBuilder sb = new StringBuilder();
                sb.Append("SELECT m.FAC_ID, m.C_NO, m.FAC_NAME, m.S_C_ID, m.TOWN, m.ADDR, m.Industrial, m.FAC_Type ");
                sb.Append("FROM FAC_Main m WHERE 1=1 ");

                List<SqlParameter> pList = new List<SqlParameter>();

                if (!string.IsNullOrEmpty(cno))
                {
                    sb.Append(" AND m.C_NO LIKE @C_NO ");
                    pList.Add(new SqlParameter("@C_NO", "%" + cno + "%"));
                }
                if (!string.IsNullOrEmpty(facName))
                {
                    sb.Append(" AND m.FAC_NAME LIKE @FAC_NAME ");
                    pList.Add(new SqlParameter("@FAC_NAME", "%" + facName + "%"));
                }
                if (!string.IsNullOrEmpty(scid))
                {
                    sb.Append(" AND m.S_C_ID LIKE @S_C_ID ");
                    pList.Add(new SqlParameter("@S_C_ID", "%" + scid + "%"));
                }
                if (!string.IsNullOrEmpty(towns))
                {
                    string[] townArr = towns.Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
                    if (townArr.Length > 0)
                    {
                        List<string> tParams = new List<string>();
                        for (int i = 0; i < townArr.Length; i++)
                        {
                            string pName = "@Town_" + i;
                            tParams.Add(pName);
                            pList.Add(new SqlParameter(pName, townArr[i]));
                        }
                        sb.Append(" AND m.TOWN IN (SELECT TOWN_NA FROM C_TOWN WHERE TOWN_NO IN (" + string.Join(",", tParams.ToArray()) + ")) ");
                    }
                }

                sb.Append(" ORDER BY m.C_NO ASC, m.FAC_ID ASC");

                DataTable dt = DbHelper.ExecuteDataTable(sb.ToString(), pList.ToArray());

                HSSFWorkbook workbook = new HSSFWorkbook();
                ISheet sheet = workbook.CreateSheet("審查場所清單");

                ICellStyle headerStyle = workbook.CreateCellStyle();
                IFont headerFont = workbook.CreateFont();
                headerFont.FontName = "微軟正黑體";
                headerFont.FontHeightInPoints = 11.0;
                headerFont.IsBold = true;
                headerStyle.SetFont(headerFont);
                headerStyle.Alignment = HorizontalAlignment.Center;
                headerStyle.VerticalAlignment = VerticalAlignment.Center;
                headerStyle.FillForegroundColor = NPOI.HSSF.Util.HSSFColor.Grey25Percent.Index;
                headerStyle.FillPattern = FillPattern.SolidForeground;
                headerStyle.BorderBottom = NPOI.SS.UserModel.BorderStyle.Thin;
                headerStyle.BorderTop = NPOI.SS.UserModel.BorderStyle.Thin;
                headerStyle.BorderLeft = NPOI.SS.UserModel.BorderStyle.Thin;
                headerStyle.BorderRight = NPOI.SS.UserModel.BorderStyle.Thin;

                ICellStyle dataStyle = workbook.CreateCellStyle();
                IFont dataFont = workbook.CreateFont();
                dataFont.FontName = "微軟正黑體";
                dataFont.FontHeightInPoints = 10.0;
                dataStyle.SetFont(dataFont);
                dataStyle.VerticalAlignment = VerticalAlignment.Center;
                dataStyle.BorderBottom = NPOI.SS.UserModel.BorderStyle.Thin;
                dataStyle.BorderTop = NPOI.SS.UserModel.BorderStyle.Thin;
                dataStyle.BorderLeft = NPOI.SS.UserModel.BorderStyle.Thin;
                dataStyle.BorderRight = NPOI.SS.UserModel.BorderStyle.Thin;

                string[] headers = new string[]
                {
                    "序號", "管制編號", "場所內部編號", "公私場所名稱", "統一編號",
                    "行政區", "廠址地址", "行業別", "管制類別", "審查階段"
                };

                IRow rowHeader = sheet.CreateRow(0);
                rowHeader.HeightInPoints = 26;
                for (int h = 0; h < headers.Length; h++)
                {
                    ICell c = rowHeader.CreateCell(h);
                    c.SetCellValue(headers[h]);
                    c.CellStyle = headerStyle;
                }

                if (dt != null && dt.Rows.Count > 0)
                {
                    for (int r = 0; r < dt.Rows.Count; r++)
                    {
                        DataRow dr = dt.Rows[r];
                        IRow row = sheet.CreateRow(r + 1);
                        row.HeightInPoints = 20;

                        string seq = (r + 1).ToString();
                        string cNoVal = dr["C_NO"] != DBNull.Value ? dr["C_NO"].ToString().Trim() : "";
                        string facIdVal = dr["FAC_ID"] != DBNull.Value ? dr["FAC_ID"].ToString().Trim() : "";
                        string nameVal = dr["FAC_NAME"] != DBNull.Value ? dr["FAC_NAME"].ToString().Trim() : "";
                        string scIdVal = dr["S_C_ID"] != DBNull.Value ? dr["S_C_ID"].ToString().Trim() : "";
                        string townVal = dr["TOWN"] != DBNull.Value ? dr["TOWN"].ToString().Trim() : "";
                        string addrVal = dr["ADDR"] != DBNull.Value ? dr["ADDR"].ToString().Trim() : "";
                        string indVal = dr["Industrial"] != DBNull.Value ? dr["Industrial"].ToString().Trim() : "";
                        string typeVal = dr["FAC_Type"] != DBNull.Value ? dr["FAC_Type"].ToString().Trim() : "非列管";

                        string[] vals = new string[]
                        {
                            seq, cNoVal, facIdVal, nameVal, scIdVal,
                            townVal, addrVal, indVal, typeVal, mode
                        };

                        for (int cIdx = 0; cIdx < vals.Length; cIdx++)
                        {
                            ICell cell = row.CreateCell(cIdx);
                            cell.SetCellValue(vals[cIdx]);
                            cell.CellStyle = dataStyle;
                        }
                    }
                }

                for (int i = 0; i < headers.Length; i++)
                {
                    sheet.SetColumnWidth(i, 16 * 256);
                }
                sheet.SetColumnWidth(0, 8 * 256);
                sheet.SetColumnWidth(3, 30 * 256);
                sheet.SetColumnWidth(6, 34 * 256);

                Response.Clear();
                Response.ContentType = "application/vnd.ms-excel";
                string filename = "審查場所清單_" + DateTime.Now.ToString("yyyyMMddHHmmss") + ".xls";
                Response.AddHeader("Content-Disposition", "attachment;filename=" + HttpUtility.UrlEncode(filename, Encoding.UTF8));

                using (MemoryStream ms = new MemoryStream())
                {
                    workbook.Write(ms);
                    Response.BinaryWrite(ms.ToArray());
                }

                try
                {
                    Response.End();
                }
                catch (System.Threading.ThreadAbortException)
                {
                }
            }
            catch (Exception ex)
            {
                Response.Clear();
                Response.ContentType = "text/plain; charset=utf-8";
                Response.Write("匯出 Excel 失敗：" + ex.Message);
            }
        }
        #endregion

}
}
