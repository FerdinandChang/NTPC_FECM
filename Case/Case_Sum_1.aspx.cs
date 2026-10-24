using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Text;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.UI;
using NTPC_FEC.Helpers;

namespace NTPC_FEC.Case
{
    public partial class Case_Sum_1 : Page
    {
        private JavaScriptSerializer json;

        public Case_Sum_1()
        {
            json = new JavaScriptSerializer();
            json.MaxJsonLength = int.MaxValue;
        }

        public class SearchFilterModel
        {
            public string C_NO { get; set; }
            public string FAC_NAME { get; set; }
            public string Industry { get; set; }
            public string Process { get; set; }
            public string DateStart { get; set; }
            public string DateEnd { get; set; }
            public List<string> Towns { get; set; }
            public int? SpecialTimesMin { get; set; }
            public int? SpecialTimesMax { get; set; }
            public string ImproveStatus { get; set; }
            public List<string> SpecialFields { get; set; }

            public SearchFilterModel()
            {
                C_NO = "";
                FAC_NAME = "";
                Industry = "";
                Process = "";
                DateStart = "";
                DateEnd = "";
                Towns = new List<string>();
                SpecialTimesMin = null;
                SpecialTimesMax = null;
                ImproveStatus = "全部";
                SpecialFields = new List<string>();
            }
        }

        public class FacItemModel
        {
            public string FAC_ID { get; set; }
            public string C_NO { get; set; }
            public string FAC_NAME { get; set; }
            public string TOWN_CODE { get; set; }
            public string TOWN_NA { get; set; }
            public string INDUSTRIAL_Name { get; set; }
            public string CheckTime_LV { get; set; }
            public string ProcessList { get; set; }
            public int Special_Times { get; set; }
            public string Improve { get; set; }
            public List<SpecialItemRowModel> ItemRows { get; set; }

            public FacItemModel()
            {
                FAC_ID = "";
                C_NO = "";
                FAC_NAME = "";
                TOWN_CODE = "";
                TOWN_NA = "";
                INDUSTRIAL_Name = "";
                CheckTime_LV = "";
                ProcessList = "";
                Special_Times = 0;
                Improve = "----";
                ItemRows = new List<SpecialItemRowModel>();
            }
        }

        public class SpecialItemRowModel
        {
            public string ItemCode { get; set; }
            public string ItemName { get; set; }
            public Dictionary<string, MonthPointCellModel> MonthPoints { get; set; }
            public int ItemImproveTimes { get; set; }
            public string ItemStatus { get; set; }

            public SpecialItemRowModel()
            {
                ItemCode = "";
                ItemName = "";
                MonthPoints = new Dictionary<string, MonthPointCellModel>();
                ItemImproveTimes = 0;
                ItemStatus = "----";
            }
        }

        public class MonthPointCellModel
        {
            public string Text { get; set; }
            public int Point { get; set; }
            public bool HasData { get; set; }
            public bool IsImproved { get; set; }

            public MonthPointCellModel()
            {
                Text = "----";
                Point = -1;
                HasData = false;
                IsImproved = false;
            }
        }

        public class InitialDataModel
        {
            public List<TownOption> Towns { get; set; }
            public List<FieldOption> SpecialFields { get; set; }
            public string DefaultDateStart { get; set; }
            public string DefaultDateEnd { get; set; }

            public InitialDataModel()
            {
                Towns = new List<TownOption>();
                SpecialFields = new List<FieldOption>();
                DefaultDateStart = "";
                DefaultDateEnd = "";
            }
        }

        public class TownOption
        {
            public string Code { get; set; }
            public string Name { get; set; }
        }

        public class FieldOption
        {
            public string Code { get; set; }
            public string Name { get; set; }
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

        private void HandleAjaxAction(string action)
        {
            switch (action)
            {
                case "getInitialData":
                    GetInitialData();
                    break;
                case "searchData":
                    SearchData();
                    break;
                case "exportExcel":
                    ExportExcel();
                    break;
                default:
                    Response.Write(json.Serialize(new
                    {
                        Success = false,
                        Message = "未知的動作指令：" + action
                    }));
                    break;
            }
        }

        private void GetInitialData()
        {
            InitialDataModel result = new InitialDataModel();

            // 行政區
            string sqlTown = "SELECT TOWN_NO, TOWN_NA FROM C_TOWN WHERE COUNTRY = 'F' ORDER BY TOWN_NO";
            DataTable dtTown = DbHelper.ExecuteDataTable(sqlTown);
            if (dtTown != null)
            {
                foreach (DataRow row in dtTown.Rows)
                {
                    TownOption town = new TownOption();
                    town.Code = row["TOWN_NO"] != null ? row["TOWN_NO"].ToString().Trim() : "";
                    town.Name = row["TOWN_NA"] != null ? row["TOWN_NA"].ToString().Trim() : "";
                    result.Towns.Add(town);
                }
            }

            // 管辦改善項目定義 (01~08)
            result.SpecialFields.Add(new FieldOption { Code = "01", Name = "堆置逸散性粒狀污染物質" });
            result.SpecialFields.Add(new FieldOption { Code = "02", Name = "輸送逸散性粒狀污染物質" });
            result.SpecialFields.Add(new FieldOption { Code = "03", Name = "運輸車輛" });
            result.SpecialFields.Add(new FieldOption { Code = "04", Name = "車輛通行路徑及區域" });
            result.SpecialFields.Add(new FieldOption { Code = "05", Name = "車輛清洗" });
            result.SpecialFields.Add(new FieldOption { Code = "06", Name = "易致粒狀污染物逸散之製程、操作或裝卸作業" });
            result.SpecialFields.Add(new FieldOption { Code = "07", Name = "公私場所管理之裸露區域" });
            result.SpecialFields.Add(new FieldOption { Code = "08", Name = "公私場所管理之道路" });

            // 預設日期區間 (3個月前的年初 至 今日)
            DateTime now = DateTime.Now;
            DateTime startDate = new DateTime(now.AddMonths(-3).Year, 1, 1);
            result.DefaultDateStart = startDate.ToString("yyyy-MM-dd");
            result.DefaultDateEnd = now.ToString("yyyy-MM-dd");

            Response.Write(json.Serialize(new
            {
                Success = true,
                Data = result
            }));
        }

        private void SearchData()
        {
            string requestBody = string.Empty;
            using (StreamReader reader = new StreamReader(Request.InputStream, Encoding.UTF8))
            {
                requestBody = reader.ReadToEnd();
            }

            SearchFilterModel filter = null;
            if (!string.IsNullOrEmpty(requestBody))
            {
                try
                {
                    filter = json.Deserialize<SearchFilterModel>(requestBody);
                }
                catch
                {
                    filter = new SearchFilterModel();
                }
            }
            else
            {
                filter = new SearchFilterModel();
            }

            // 執行統計計算
            List<string> months = new List<string>();
            List<FacItemModel> facList = ExecuteStatistics(filter, out months);

            Response.Write(json.Serialize(new
            {
                Success = true,
                Months = months,
                Data = facList,
                TotalCount = facList.Count
            }));
        }

        private List<FacItemModel> ExecuteStatistics(SearchFilterModel filter, out List<string> months)
        {
            months = new List<string>();

            // 1. 解析日期區間與動態月份清單
            DateTime dtStart;
            if (!DateTime.TryParse(filter.DateStart, out dtStart))
            {
                dtStart = new DateTime(DateTime.Now.AddMonths(-3).Year, 1, 1);
            }
            DateTime dtEnd;
            if (!DateTime.TryParse(filter.DateEnd, out dtEnd))
            {
                dtEnd = DateTime.Now;
            }

            DateTime curMonth = new DateTime(dtStart.Year, dtStart.Month, 1);
            DateTime endMonthLimit = new DateTime(dtEnd.Year, dtEnd.Month, 1);
            while (curMonth <= endMonthLimit)
            {
                string mCode = (curMonth.Year - 1911).ToString("000") + curMonth.Month.ToString("00");
                months.Add(mCode);
                curMonth = curMonth.AddMonths(1);
            }

            // 2. 組裝主公私場所查詢 SQL
            StringBuilder sqlBuilder = new StringBuilder();
            sqlBuilder.Append("SELECT TabA.*, INDUSTRIAL_Data.INDUSTRIAL_Name, C_TOWN.TOWN_NA FROM (");
            sqlBuilder.Append(" SELECT FAC_ID");
            sqlBuilder.Append(" ,COALESCE((SELECT TOP 1 C_NO FROM FAC_EditHis WHERE C_NO IS NOT NULL AND CAST(FAC_EditHis.FAC_ID AS NVARCHAR(50)) = CAST(FAC_Main.FAC_ID AS NVARCHAR(50)) ORDER BY Edit_Date DESC), C_NO) AS C_NO");
            sqlBuilder.Append(" ,COALESCE((SELECT TOP 1 TOWN_CODE FROM FAC_EditHis WHERE TOWN_CODE IS NOT NULL AND CAST(FAC_EditHis.FAC_ID AS NVARCHAR(50)) = CAST(FAC_Main.FAC_ID AS NVARCHAR(50)) ORDER BY Edit_Date DESC), TOWN_CODE) AS TOWN_CODE");
            sqlBuilder.Append(" ,COALESCE((SELECT TOP 1 FAC_NAME FROM FAC_EditHis WHERE FAC_NAME IS NOT NULL AND CAST(FAC_EditHis.FAC_ID AS NVARCHAR(50)) = CAST(FAC_Main.FAC_ID AS NVARCHAR(50)) ORDER BY Edit_Date DESC), FAC_NAME) AS FAC_NAME");
            sqlBuilder.Append(" ,COALESCE((SELECT TOP 1 INDUSTRIAL_Code1 FROM FAC_EditHis WHERE INDUSTRIAL_Code1 IS NOT NULL AND CAST(FAC_EditHis.FAC_ID AS NVARCHAR(50)) = CAST(FAC_Main.FAC_ID AS NVARCHAR(50)) ORDER BY Edit_Date DESC), INDUSTRIAL_Code1) AS INDUSTRIAL_Code1");
            sqlBuilder.Append(" ,CheckTime_LV");
            sqlBuilder.Append(" FROM FAC_Main");
            sqlBuilder.Append(") AS TabA ");
            sqlBuilder.Append("LEFT JOIN INDUSTRIAL_Data ON INDUSTRIAL_Data.INDUSTRIAL_Code = TabA.INDUSTRIAL_Code1 ");
            sqlBuilder.Append("LEFT JOIN C_TOWN ON C_TOWN.COUNTRY = 'F' AND C_TOWN.TOWN_NO = TabA.TOWN_CODE ");

            List<SqlParameter> parameters = new List<SqlParameter>();
            List<string> whereClauses = new List<string>();

            if (!string.IsNullOrEmpty(filter.C_NO))
            {
                whereClauses.Add("TabA.C_NO LIKE '%' + @C_NO + '%'");
                parameters.Add(new SqlParameter("@C_NO", filter.C_NO.Trim()));
            }

            if (!string.IsNullOrEmpty(filter.FAC_NAME))
            {
                whereClauses.Add("TabA.FAC_NAME LIKE '%' + @FAC_NAME + '%'");
                parameters.Add(new SqlParameter("@FAC_NAME", filter.FAC_NAME.Trim()));
            }

            if (!string.IsNullOrEmpty(filter.Industry))
            {
                whereClauses.Add("INDUSTRIAL_Data.INDUSTRIAL_Name LIKE '%' + @Industry + '%'");
                parameters.Add(new SqlParameter("@Industry", filter.Industry.Trim()));
            }

            if (filter.Towns != null && filter.Towns.Count > 0)
            {
                List<string> townParams = new List<string>();
                for (int i = 0; i < filter.Towns.Count; i++)
                {
                    string pName = "@Town_" + i;
                    townParams.Add(pName);
                    parameters.Add(new SqlParameter(pName, filter.Towns[i]));
                }
                whereClauses.Add(string.Format("TabA.TOWN_CODE IN ({0})", string.Join(",", townParams.ToArray())));
            }

            if (whereClauses.Count > 0)
            {
                sqlBuilder.Append(" WHERE " + string.Join(" AND ", whereClauses.ToArray()));
            }

            DataTable dtFac = DbHelper.ExecuteDataTable(sqlBuilder.ToString(), parameters.ToArray());
            List<FacItemModel> facResults = new List<FacItemModel>();
            if (dtFac == null || dtFac.Rows.Count == 0)
            {
                return facResults;
            }

            // 項目定義名稱對照表
            Dictionary<string, string> fieldNameMap = new Dictionary<string, string>();
            fieldNameMap["01"] = "堆置逸散性粒狀污染物質";
            fieldNameMap["02"] = "輸送逸散性粒狀污染物質";
            fieldNameMap["03"] = "運輸車輛";
            fieldNameMap["04"] = "車輛通行路徑及區域";
            fieldNameMap["05"] = "車輛清洗";
            fieldNameMap["06"] = "易致粒狀污染物逸散之製程、操作或裝卸作業";
            fieldNameMap["07"] = "公私場所管理之裸露區域";
            fieldNameMap["08"] = "公私場所管理之道路";

            // 勾選顯示的項目列表 (若前端未傳入則預設全部 01~08)
            List<string> activeFields = (filter.SpecialFields != null && filter.SpecialFields.Count > 0)
                ? filter.SpecialFields
                : new List<string> { "01", "02", "03", "04", "05", "06", "07", "08" };

            // 3. 逐一計算每家公私場所
            foreach (DataRow row in dtFac.Rows)
            {
                string facId = row["FAC_ID"] != null ? row["FAC_ID"].ToString().Trim() : "";
                if (string.IsNullOrEmpty(facId))
                {
                    continue;
                }
                string cNo = row["C_NO"] != null ? row["C_NO"].ToString() : "";
                string facName = row["FAC_NAME"] != null ? row["FAC_NAME"].ToString() : "";
                string townCode = row["TOWN_CODE"] != null ? row["TOWN_CODE"].ToString() : "";
                string townNa = row["TOWN_NA"] != null ? row["TOWN_NA"].ToString() : "";
                string indName = row["INDUSTRIAL_Name"] != null ? row["INDUSTRIAL_Name"].ToString() : "";
                string checkTimeLv = row["CheckTime_LV"] != null ? row["CheckTime_LV"].ToString() : "";

                // 查詢製程資訊
                string sqlProc = "SELECT DISTINCT Process_NO, Process_Name, Process_Type, Process_Lic, Lic_Year FROM INV_Process_Main WHERE FAC_ID = @FAC_ID";
                DataTable dtProc = DbHelper.ExecuteDataTable(sqlProc, new SqlParameter("@FAC_ID", facId));
                List<string> procLines = new List<string>();
                if (dtProc != null)
                {
                    foreach (DataRow pRow in dtProc.Rows)
                    {
                        string pNo = pRow["Process_NO"] != null ? pRow["Process_NO"].ToString() : "";
                        string pType = pRow["Process_Type"] != null ? pRow["Process_Type"].ToString() : "";
                        string pLic = pRow["Process_Lic"] != null ? pRow["Process_Lic"].ToString() : "";
                        if (!string.IsNullOrEmpty(pNo) || !string.IsNullOrEmpty(pType) || !string.IsNullOrEmpty(pLic))
                        {
                            procLines.Add(string.Format("{0}/{1}/{2}", pNo, pType, pLic));
                        }
                    }
                }
                string processList = string.Join("; ", procLines.ToArray());

                // 若有程序別篩選條件，且未命中則跳過
                if (!string.IsNullOrEmpty(filter.Process) && processList.IndexOf(filter.Process, StringComparison.OrdinalIgnoreCase) < 0)
                {
                    continue;
                }

                // 查詢該場所在區間內的巡查紀錄
                string sqlInv = "SELECT * FROM INV_Data WHERE FAC_ID = @FAC_ID AND INV_DATE >= @DateStart AND INV_DATE <= @DateEnd ORDER BY INV_DATE";
                DataTable dtInv = DbHelper.ExecuteDataTable(sqlInv,
                    new SqlParameter("@FAC_ID", facId),
                    new SqlParameter("@DateStart", dtStart.ToString("yyyy-MM-dd 00:00:00")),
                    new SqlParameter("@DateEnd", dtEnd.ToString("yyyy-MM-dd 23:59:59"))
                );

                // 計算每月份、每個項目的最大扣分點數
                // Key: itemCode + "_" + yyyMM
                Dictionary<string, int> monthItemMaxPoints = new Dictionary<string, int>();
                if (dtInv != null)
                {
                    foreach (DataRow invRow in dtInv.Rows)
                    {
                        if (invRow["INV_DATE"] == DBNull.Value || invRow["INV_DATE"] == null)
                        {
                            continue;
                        }
                        DateTime invDate;
                        if (!DateTime.TryParse(invRow["INV_DATE"].ToString(), out invDate))
                        {
                            continue;
                        }

                        string monthCode = (invDate.Year - 1911).ToString("000") + invDate.Month.ToString("00");

                        foreach (string itemCode in activeFields)
                        {
                            int lossPoint = CalOneLossPoint(invRow, itemCode);
                            string dictKey = itemCode + "_" + monthCode;
                            if (monthItemMaxPoints.ContainsKey(dictKey))
                            {
                                if (lossPoint > monthItemMaxPoints[dictKey])
                                {
                                    monthItemMaxPoints[dictKey] = lossPoint;
                                }
                            }
                            else
                            {
                                monthItemMaxPoints[dictKey] = lossPoint;
                            }
                        }
                    }
                }

                // 構建每項管辦項目的月度扣分列與改善判斷
                int facTotalImproveTimes = 0;
                string overallImproveStatus = "----";
                List<SpecialItemRowModel> itemRows = new List<SpecialItemRowModel>();

                foreach (string itemCode in activeFields)
                {
                    SpecialItemRowModel itemRow = new SpecialItemRowModel();
                    itemRow.ItemCode = itemCode;
                    itemRow.ItemName = fieldNameMap.ContainsKey(itemCode) ? fieldNameMap[itemCode] : ("項目" + itemCode);

                    int previousPoint = -1;
                    int itemImproveTimes = 0;
                    int firstPoint = -1;
                    int lastPoint = -1;

                    foreach (string mCode in months)
                    {
                        MonthPointCellModel cell = new MonthPointCellModel();
                        string dictKey = itemCode + "_" + mCode;

                        if (monthItemMaxPoints.ContainsKey(dictKey))
                        {
                            int pt = monthItemMaxPoints[dictKey];
                            cell.Point = pt;
                            cell.Text = pt.ToString();
                            cell.HasData = true;

                            if (firstPoint == -1)
                            {
                                firstPoint = pt;
                            }
                            lastPoint = pt;

                            if (previousPoint != -1)
                            {
                                if (previousPoint > pt)
                                {
                                    cell.IsImproved = true;
                                    itemImproveTimes++;
                                    facTotalImproveTimes++;
                                }
                            }
                            previousPoint = pt;
                        }
                        else
                        {
                            cell.Text = "----";
                            cell.Point = -1;
                            cell.HasData = false;
                        }

                        itemRow.MonthPoints[mCode] = cell;
                    }

                    itemRow.ItemImproveTimes = itemImproveTimes;

                    // 判斷該項目改善狀況
                    if (firstPoint != -1 && lastPoint != -1)
                    {
                        if (firstPoint > lastPoint)
                        {
                            itemRow.ItemStatus = "已改善";
                            overallImproveStatus = "已改善";
                        }
                        else
                        {
                            itemRow.ItemStatus = "無改善";
                            if (overallImproveStatus != "已改善")
                            {
                                overallImproveStatus = "無改善";
                            }
                        }
                    }
                    else
                    {
                        itemRow.ItemStatus = "----";
                    }

                    itemRows.Add(itemRow);
                }

                // 4. 過濾「管辦改善次數」與「改善狀況」
                if (filter.SpecialTimesMin.HasValue && facTotalImproveTimes < filter.SpecialTimesMin.Value)
                {
                    continue;
                }
                if (filter.SpecialTimesMax.HasValue && facTotalImproveTimes > filter.SpecialTimesMax.Value)
                {
                    continue;
                }

                if (!string.IsNullOrEmpty(filter.ImproveStatus) && filter.ImproveStatus != "全部")
                {
                    if (filter.ImproveStatus == "已改善" && overallImproveStatus != "已改善")
                    {
                        continue;
                    }
                    if (filter.ImproveStatus == "無改善" && overallImproveStatus != "無改善")
                    {
                        continue;
                    }
                }

                FacItemModel facItem = new FacItemModel();
                facItem.FAC_ID = facId;
                facItem.C_NO = cNo;
                facItem.FAC_NAME = facName;
                facItem.TOWN_CODE = townCode;
                facItem.TOWN_NA = townNa;
                facItem.INDUSTRIAL_Name = indName;
                facItem.CheckTime_LV = checkTimeLv;
                facItem.ProcessList = processList;
                facItem.Special_Times = facTotalImproveTimes;
                facItem.Improve = overallImproveStatus;
                facItem.ItemRows = itemRows;

                facResults.Add(facItem);
            }

            // 依 FAC_ID 降冪排序
            facResults.Sort(delegate(FacItemModel a, FacItemModel b)
            {
                return string.Compare(b.FAC_ID, a.FAC_ID, StringComparison.OrdinalIgnoreCase);
            });

            return facResults;
        }

        private static int CalOneLossPoint(DataRow row, string itemCode)
        {
            int num1 = 0;
            int num2 = 0;
            int num3 = 0;
            int num4 = 0;
            int num5 = 0;
            int num6 = 0;
            int num7 = 0;
            int num8 = 0;
            int num9 = 0;

            // 01: 堆置逸散性粒狀污染物質
            if (GetVal(row, "INV_01_01") == "Y" || GetVal(row, "INV_01_02") == "Y" || GetVal(row, "INV_01_03") == "Y")
            {
                num1 = 0;
            }
            if (GetVal(row, "INV_01_04") == "Y" || GetVal(row, "INV_01_05") == "Y")
            {
                num1 = 10;
            }
            if (GetVal(row, "INV_01_08") == "Y" || GetVal(row, "INV_01_09") == "Y" || GetVal(row, "INV_01_09a") == "Y" ||
                GetVal(row, "INV_01_09b") == "Y" || GetVal(row, "INV_01_09c") == "Y" || GetVal(row, "INV_01_09d") == "Y" ||
                GetVal(row, "INV_01_10") == "Y" || GetVal(row, "INV_01_10a") == "Y" || GetVal(row, "INV_01_10b") == "Y" ||
                GetVal(row, "INV_01_11") == "Y" || GetVal(row, "INV_01_11a") == "Y" || GetVal(row, "INV_01_11b") == "Y" ||
                GetVal(row, "INV_01_11c") == "Y" || GetVal(row, "INV_01_12") == "Y" || GetVal(row, "INV_01_12a") == "Y" ||
                GetVal(row, "INV_01_12b") == "Y" || GetVal(row, "INV_01_12c") == "Y" || GetVal(row, "INV_01_13") == "Y" ||
                GetVal(row, "INV_01_14") == "Y" || GetVal(row, "INV_01_07") == "Y")
            {
                num1 = 4;
            }

            // 02: 輸送逸散性粒狀污染物質
            if (GetVal(row, "INV_02_01") == "Y" || GetVal(row, "INV_02_02") == "Y" || GetVal(row, "INV_02_03") == "Y" || GetVal(row, "INV_02_04") == "Y")
            {
                num2 = 0;
            }
            if (GetVal(row, "INV_02_05") == "Y" || GetVal(row, "INV_02_06") == "Y")
            {
                num2 = 10;
            }
            if (GetVal(row, "INV_02_07") == "Y" || GetVal(row, "INV_02_08") == "Y" || GetVal(row, "INV_02_09") == "Y" ||
                GetVal(row, "INV_02_09a") == "Y" || GetVal(row, "INV_02_09b") == "Y" || GetVal(row, "INV_02_10") == "Y" ||
                GetVal(row, "INV_02_10a") == "Y" || GetVal(row, "INV_02_10b") == "Y" || GetVal(row, "INV_02_10c") == "Y" ||
                GetVal(row, "INV_02_11") == "Y")
            {
                num2 = 4;
            }

            // 03: 運輸車輛
            if (GetVal(row, "INV_03_01") == "Y" || GetVal(row, "INV_03_02") == "Y" || GetVal(row, "INV_03_03") == "Y")
            {
                num3 = 0;
            }
            if (GetVal(row, "INV_03_04") == "Y" || GetVal(row, "INV_03_05") == "Y" || GetVal(row, "INV_03_06") == "Y")
            {
                num3 = 10;
            }
            if (GetVal(row, "INV_03_07") == "Y" || GetVal(row, "INV_03_08") == "Y" || GetVal(row, "INV_03_09") == "Y")
            {
                num3 = 4;
            }

            // 04: 車輛通行路徑及區域
            if (GetVal(row, "INV_04_01") == "Y" || GetVal(row, "INV_04_02") == "Y" || GetVal(row, "INV_04_03") == "Y")
            {
                num4 = 0;
            }
            if (GetVal(row, "INV_04_04") == "Y" || GetVal(row, "INV_04_05") == "Y")
            {
                num4 = 10;
            }
            if (GetVal(row, "INV_04_06") == "Y" || GetVal(row, "INV_04_07") == "Y" || GetVal(row, "INV_04_08") == "Y" || GetVal(row, "INV_04_09") == "Y")
            {
                num4 = 4;
            }

            // 05: 車輛清洗
            if (GetVal(row, "INV_05_01") == "Y" || GetVal(row, "INV_05_02") == "Y" || GetVal(row, "INV_05_03") == "Y")
            {
                num5 = 0;
            }
            if (GetVal(row, "INV_05_04") == "Y" || GetVal(row, "INV_05_05") == "Y" || GetVal(row, "INV_05_06") == "Y")
            {
                num5 = 10;
            }
            if (GetVal(row, "INV_05_07") == "Y" || GetVal(row, "INV_05_08") == "Y" || GetVal(row, "INV_05_09") == "Y" ||
                GetVal(row, "INV_05_10") == "Y" || GetVal(row, "INV_05_11") == "Y")
            {
                num5 = 4;
            }

            // 06: 易致粒狀污染物逸散之製程、操作或裝卸作業
            if (GetVal(row, "INV_06_01") == "Y" || GetVal(row, "INV_06_02") == "Y" || GetVal(row, "INV_06_03") == "Y" || GetVal(row, "INV_06_04") == "Y")
            {
                num6 = 0;
            }
            if (GetVal(row, "INV_06_05") == "Y" || GetVal(row, "INV_06_06") == "Y")
            {
                num6 = 10;
            }
            if (GetVal(row, "INV_06_07") == "Y" || GetVal(row, "INV_06_07a") == "Y" || GetVal(row, "INV_06_07b") == "Y" ||
                GetVal(row, "INV_06_08") == "Y" || GetVal(row, "INV_06_08a") == "Y" || GetVal(row, "INV_06_08b") == "Y" ||
                GetVal(row, "INV_06_09") == "Y" || GetVal(row, "INV_06_10") == "Y" || GetVal(row, "INV_06_11") == "Y" ||
                GetVal(row, "INV_06_12") == "Y")
            {
                num6 = 4;
            }

            // 07: 公私場所管理之裸露區域
            if (GetVal(row, "INV_07_01") == "Y" || GetVal(row, "INV_07_02") == "Y" || GetVal(row, "INV_07_03") == "Y")
            {
                num7 = 0;
            }
            if (GetVal(row, "INV_07_04") == "Y" || GetVal(row, "INV_07_05") == "Y")
            {
                num7 = 10;
            }
            if (GetVal(row, "INV_07_06") == "Y" || GetVal(row, "INV_07_07") == "Y" || GetVal(row, "INV_07_08") == "Y" ||
                GetVal(row, "INV_07_09") == "Y" || GetVal(row, "INV_07_10") == "Y" || GetVal(row, "INV_07_11") == "Y")
            {
                num7 = 4;
            }

            // 08: 公私場所管理之道路
            if (GetVal(row, "INV_08_01") == "Y" || GetVal(row, "INV_08_02") == "Y" || GetVal(row, "INV_08_03") == "Y")
            {
                num8 = 0;
            }
            if (GetVal(row, "INV_08_04") == "Y" || GetVal(row, "INV_08_05") == "Y")
            {
                num8 = 10;
            }
            if (GetVal(row, "INV_08_06") == "Y" || GetVal(row, "INV_08_07") == "Y" || GetVal(row, "INV_08_08") == "Y" ||
                GetVal(row, "INV_08_09") == "Y" || GetVal(row, "INV_08_10") == "Y")
            {
                num8 = 4;
            }

            // 09: 其他
            if (GetVal(row, "INV_09_01") == "Y" || GetVal(row, "INV_09_02") == "Y" || GetVal(row, "INV_09_03") == "Y")
            {
                num9 = 0;
            }
            if (GetVal(row, "INV_09_04") == "Y" || GetVal(row, "INV_09_05") == "Y" || GetVal(row, "INV_09_06") == "Y")
            {
                num9 = 10;
            }
            if (GetVal(row, "INV_09_07") == "Y" || GetVal(row, "INV_09_08") == "Y")
            {
                num9 = 4;
            }

            switch (itemCode)
            {
                case "01": return num1;
                case "02": return num2;
                case "03": return num3;
                case "04": return num4;
                case "05": return num5;
                case "06": return num6;
                case "07": return num7;
                case "08": return num8;
                case "09": return num9;
                default: return -1;
            }
        }

        private static string GetVal(DataRow row, string colName)
        {
            if (row.Table.Columns.Contains(colName) && row[colName] != DBNull.Value && row[colName] != null)
            {
                return row[colName].ToString().Trim();
            }
            return string.Empty;
        }

        private void ExportExcel()
        {
            string requestBody = string.Empty;
            using (StreamReader reader = new StreamReader(Request.InputStream, Encoding.UTF8))
            {
                requestBody = reader.ReadToEnd();
            }

            SearchFilterModel filter = null;
            if (!string.IsNullOrEmpty(requestBody))
            {
                try
                {
                    filter = json.Deserialize<SearchFilterModel>(requestBody);
                }
                catch
                {
                    filter = new SearchFilterModel();
                }
            }
            else
            {
                filter = new SearchFilterModel();
            }

            List<string> months = new List<string>();
            List<FacItemModel> facList = ExecuteStatistics(filter, out months);

            StringBuilder html = new StringBuilder();
            html.Append("<html xmlns:o='urn:schemas-microsoft-com:office:office' xmlns:x='urn:schemas-microsoft-com:office:excel' xmlns='http://www.w3.org/TR/REC-html40'>");
            html.Append("<head><meta http-equiv='content-type' content='text/html; charset=utf-8'><style>");
            html.Append("table { border-collapse: collapse; font-family: Microsoft JhengHei, Arial; }");
            html.Append("th { background-color: #0099e5; color: #ffffff; border: 1px solid #999; padding: 6px; font-weight: bold; }");
            html.Append("td { border: 1px solid #999; padding: 6px; text-align: center; }");
            html.Append(".fac-header { background-color: #e0f2fe; font-weight: bold; text-align: left; }");
            html.Append(".improved { background-color: #d1fae5; font-weight: bold; color: #047857; }");
            html.Append("</style></head><body>");

            html.Append("<h2>固定污染源管辦改善歷程追蹤統計表</h2>");
            html.Append(string.Format("<p>產表時間：{0} ｜ 查詢區間：{1} ～ {2}</p>", DateTime.Now.ToString("yyyy/MM/dd HH:mm"), filter.DateStart, filter.DateEnd));

            html.Append("<table>");
            html.Append("<thead><tr>");
            html.Append("<th>管制編號</th><th>場所名稱</th><th>行政區</th><th>行業別</th><th>查核頻率</th><th>製程與許可證</th>");
            html.Append("<th>管辦項目</th>");
            foreach (string m in months)
            {
                html.Append("<th>" + m + "</th>");
            }
            html.Append("<th>項目改善次數</th><th>項目改善狀況</th><th>場所總改善次數</th><th>場所改善判定</th>");
            html.Append("</tr></thead><tbody>");

            foreach (FacItemModel fac in facList)
            {
                int rowCount = fac.ItemRows.Count > 0 ? fac.ItemRows.Count : 1;
                for (int i = 0; i < rowCount; i++)
                {
                    SpecialItemRowModel item = (i < fac.ItemRows.Count) ? fac.ItemRows[i] : null;
                    html.Append("<tr>");
                    if (i == 0)
                    {
                        html.Append(string.Format("<td rowspan='{0}' style='text-align:center;'>{1}</td>", rowCount, fac.C_NO));
                        html.Append(string.Format("<td rowspan='{0}' style='text-align:left;'>{1}</td>", rowCount, fac.FAC_NAME));
                        html.Append(string.Format("<td rowspan='{0}' style='text-align:center;'>{1}</td>", rowCount, fac.TOWN_NA));
                        html.Append(string.Format("<td rowspan='{0}' style='text-align:left;'>{1}</td>", rowCount, fac.INDUSTRIAL_Name));
                        html.Append(string.Format("<td rowspan='{0}' style='text-align:center;'>{1}</td>", rowCount, fac.CheckTime_LV));
                        html.Append(string.Format("<td rowspan='{0}' style='text-align:left;'>{1}</td>", rowCount, fac.ProcessList));
                    }

                    if (item != null)
                    {
                        html.Append(string.Format("<td style='text-align:left;'>{0}</td>", item.ItemName));
                        foreach (string m in months)
                        {
                            if (item.MonthPoints.ContainsKey(m))
                            {
                                MonthPointCellModel cell = item.MonthPoints[m];
                                if (cell.IsImproved)
                                {
                                    html.Append(string.Format("<td class='improved'>{0}</td>", cell.Text));
                                }
                                else
                                {
                                    html.Append(string.Format("<td>{0}</td>", cell.Text));
                                }
                            }
                            else
                            {
                                html.Append("<td>----</td>");
                            }
                        }
                        html.Append(string.Format("<td>{0}</td>", item.ItemImproveTimes));
                        html.Append(string.Format("<td>{0}</td>", item.ItemStatus));
                    }
                    else
                    {
                        html.Append("<td>無管辦資料</td>");
                        for (int m = 0; m < months.Count; m++)
                        {
                            html.Append("<td>----</td>");
                        }
                        html.Append("<td>0</td><td>----</td>");
                    }

                    if (i == 0)
                    {
                        html.Append(string.Format("<td rowspan='{0}' style='font-weight:bold;'>{1}</td>", rowCount, fac.Special_Times));
                        html.Append(string.Format("<td rowspan='{0}' style='font-weight:bold;'>{1}</td>", rowCount, fac.Improve));
                    }
                    html.Append("</tr>");
                }
            }

            html.Append("</tbody></table></body></html>");

            byte[] fileBytes = Encoding.UTF8.GetBytes(html.ToString());
            string base64 = Convert.ToBase64String(fileBytes);
            string fileName = string.Format("Case_Sum_1_{0}.xls", DateTime.Now.ToString("yyyyMMdd_HHmmss"));

            Response.Write(json.Serialize(new
            {
                Success = true,
                FileName = fileName,
                Base64 = base64
            }));
        }
    }
}
