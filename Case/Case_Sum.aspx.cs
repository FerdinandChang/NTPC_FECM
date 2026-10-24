using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Text;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.UI;
using NPOI.HSSF.UserModel;
using NPOI.HSSF.Util;
using NPOI.SS.UserModel;
using NPOI.SS.Util;
using NTPC_FEC.Helpers;

namespace NTPC_FEC.Case
{
    public partial class Case_Sum : Page
    {
        private JavaScriptSerializer jsonSerializer;

        public Case_Sum()
        {
            jsonSerializer = new JavaScriptSerializer();
            jsonSerializer.MaxJsonLength = int.MaxValue;
        }

        #region 資料模型定義 (相容 C# 5.0)

        public class SumFilterRequest
        {
            public string CNo { get; set; }
            public string FacName { get; set; }
            public string Industry { get; set; }
            public string Process { get; set; }
            public string DateStart { get; set; }
            public string DateEnd { get; set; }
            public List<string> Towns { get; set; }
            public List<string> LossLevels { get; set; }
            public int PageIndex { get; set; }
            public int PageSize { get; set; }
            public string SortField { get; set; }
            public string SortDir { get; set; }
            public List<string> ShowFields { get; set; }

            public SumFilterRequest()
            {
                CNo = "";
                FacName = "";
                Industry = "";
                Process = "";
                DateStart = "";
                DateEnd = "";
                Towns = new List<string>();
                LossLevels = new List<string>();
                PageIndex = 1;
                PageSize = 25;
                SortField = "INV_DATE";
                SortDir = "desc";
                ShowFields = new List<string>();
            }
        }

        public class CaseRowItem
        {
            public string FacId { get; set; }
            public string CNo { get; set; }
            public string FacName { get; set; }
            public string TownCode { get; set; }
            public string TownName { get; set; }
            public string IndustrialCode { get; set; }
            public string IndustrialName { get; set; }
            public string ProcessList { get; set; }
            public string CheckTimeLv { get; set; }
            public string InvDate { get; set; }
            public string InvType { get; set; }
            public int LossPoint { get; set; }
            public string LossLv { get; set; }
            public string LossDetail { get; set; }
            public List<LossItemScore> ItemScores { get; set; }

            public CaseRowItem()
            {
                FacId = "";
                CNo = "";
                FacName = "";
                TownCode = "";
                TownName = "";
                IndustrialCode = "";
                IndustrialName = "";
                ProcessList = "";
                CheckTimeLv = "";
                InvDate = "";
                InvType = "";
                LossPoint = 0;
                LossLv = "無缺失";
                LossDetail = "";
                ItemScores = new List<LossItemScore>();
            }
        }

        public class LossItemScore
        {
            public int ItemNo { get; set; }
            public string Title { get; set; }
            public int Point { get; set; }
            public string StatusText { get; set; }

            public LossItemScore()
            {
                ItemNo = 1;
                Title = "";
                Point = 0;
                StatusText = "";
            }
        }

        public class TownStatItem
        {
            public string TownCode { get; set; }
            public string TownName { get; set; }
            public int TotalCount { get; set; }
            public int ZeroLossCount { get; set; }
            public int MinorLossCount { get; set; }
            public int SevereLossCount { get; set; }

            public TownStatItem()
            {
                TownCode = "";
                TownName = "";
                TotalCount = 0;
                ZeroLossCount = 0;
                MinorLossCount = 0;
                SevereLossCount = 0;
            }
        }

        public class SumResultResponse
        {
            public bool Success { get; set; }
            public string Message { get; set; }
            public int TotalRecords { get; set; }
            public int TotalFacs { get; set; }
            public int ZeroLossCount { get; set; }
            public double ZeroLossPercent { get; set; }
            public int MinorLossCount { get; set; }
            public double MinorLossPercent { get; set; }
            public int SevereLossCount { get; set; }
            public double SevereLossPercent { get; set; }
            public List<CaseRowItem> Rows { get; set; }
            public List<TownStatItem> TownStats { get; set; }

            public SumResultResponse()
            {
                Success = true;
                Message = "";
                TotalRecords = 0;
                TotalFacs = 0;
                ZeroLossCount = 0;
                ZeroLossPercent = 0.0;
                MinorLossCount = 0;
                MinorLossPercent = 0.0;
                SevereLossCount = 0;
                SevereLossPercent = 0.0;
                Rows = new List<CaseRowItem>();
                TownStats = new List<TownStatItem>();
            }
        }

        #endregion

        protected void Page_Load(object sender, EventArgs e)
        {
            string action = Request["action"];
            if (!string.IsNullOrEmpty(action))
            {
                action = action.ToLower();
                switch (action)
                {
                    case "gettowns":
                        HandleGetTowns();
                        break;
                    case "getsumdata":
                        HandleGetSumData();
                        break;
                    case "exportexcel":
                        HandleExportExcel();
                        break;
                    default:
                        Response.ContentType = "application/json; charset=utf-8";
                        Response.Write(jsonSerializer.Serialize(new { Success = false, Message = "未知指令: " + action }));
                        Response.End();
                        break;
                }
            }
        }

        #region API 處理方法

        private void HandleGetTowns()
        {
            try
            {
                string sql = "SELECT TOWN_NO, TOWN_NA FROM C_TOWN WHERE COUNTRY = 'F' ORDER BY TOWN_NO";
                DataTable dt = DbHelper.ExecuteDataTable(sql);
                List<object> list = new List<object>();
                if (dt != null)
                {
                    foreach (DataRow row in dt.Rows)
                    {
                        list.Add(new
                        {
                            TownNo = row["TOWN_NO"] != null ? row["TOWN_NO"].ToString().Trim() : "",
                            TownName = row["TOWN_NA"] != null ? row["TOWN_NA"].ToString().Trim() : ""
                        });
                    }
                }
                Response.ContentType = "application/json; charset=utf-8";
                Response.Write(jsonSerializer.Serialize(new { Success = true, Towns = list }));
            }
            catch (Exception ex)
            {
                Response.ContentType = "application/json; charset=utf-8";
                Response.Write(jsonSerializer.Serialize(new { Success = false, Message = ex.Message }));
            }
            Response.End();
        }

        private void HandleGetSumData()
        {
            Response.ContentType = "application/json; charset=utf-8";
            SumResultResponse response = new SumResultResponse();

            try
            {
                SumFilterRequest filter = ParseFilterFromRequest();
                List<CaseRowItem> allList = QueryCaseData(filter);

                // 計算彙總指標
                response.TotalRecords = allList.Count;
                HashSet<string> facSet = new HashSet<string>();
                Dictionary<string, TownStatItem> townMap = new Dictionary<string, TownStatItem>();

                for (int i = 0; i < allList.Count; i++)
                {
                    CaseRowItem item = allList[i];
                    if (!string.IsNullOrEmpty(item.FacId) && !facSet.Contains(item.FacId))
                    {
                        facSet.Add(item.FacId);
                    }

                    if (item.LossPoint == 0)
                    {
                        response.ZeroLossCount++;
                    }
                    else if (item.LossPoint >= 1 && item.LossPoint <= 9)
                    {
                        response.MinorLossCount++;
                    }
                    else if (item.LossPoint >= 10)
                    {
                        response.SevereLossCount++;
                    }

                    // 行政區統計
                    string tCode = item.TownCode;
                    if (!townMap.ContainsKey(tCode))
                    {
                        TownStatItem tStat = new TownStatItem();
                        tStat.TownCode = tCode;
                        tStat.TownName = item.TownName;
                        townMap.Add(tCode, tStat);
                    }
                    townMap[tCode].TotalCount++;
                    if (item.LossPoint == 0)
                    {
                        townMap[tCode].ZeroLossCount++;
                    }
                    else if (item.LossPoint >= 1 && item.LossPoint <= 9)
                    {
                        townMap[tCode].MinorLossCount++;
                    }
                    else
                    {
                        townMap[tCode].SevereLossCount++;
                    }
                }

                response.TotalFacs = facSet.Count;
                if (response.TotalRecords > 0)
                {
                    response.ZeroLossPercent = Math.Round((double)response.ZeroLossCount * 100.0 / (double)response.TotalRecords, 1);
                    response.MinorLossPercent = Math.Round((double)response.MinorLossCount * 100.0 / (double)response.TotalRecords, 1);
                    response.SevereLossPercent = Math.Round((double)response.SevereLossCount * 100.0 / (double)response.TotalRecords, 1);
                }

                // 行政區統計列表
                foreach (KeyValuePair<string, TownStatItem> kv in townMap)
                {
                    response.TownStats.Add(kv.Value);
                }

                // 分頁切片
                int pageSize = filter.PageSize > 0 ? filter.PageSize : 25;
                int pageIndex = filter.PageIndex > 0 ? filter.PageIndex : 1;
                int startIndex = (pageIndex - 1) * pageSize;

                if (startIndex < allList.Count)
                {
                    int takeCount = Math.Min(pageSize, allList.Count - startIndex);
                    response.Rows = allList.GetRange(startIndex, takeCount);
                }
                else
                {
                    response.Rows = new List<CaseRowItem>();
                }

                response.Success = true;
            }
            catch (Exception ex)
            {
                response.Success = false;
                response.Message = "查詢失敗: " + ex.Message;
            }

            Response.Write(jsonSerializer.Serialize(response));
            Response.End();
        }

        private void HandleExportExcel()
        {
            try
            {
                SumFilterRequest filter = ParseFilterFromRequest();
                filter.PageSize = int.MaxValue;
                filter.PageIndex = 1;
                List<CaseRowItem> allList = QueryCaseData(filter);

                HSSFWorkbook workbook = new HSSFWorkbook();
                ISheet sheet = workbook.CreateSheet("公私場所巡查統計");
                sheet.IsPrintGridlines = true;
                sheet.DisplayGridlines = true;

                // 標題字型與樣式
                IFont fontTitle = workbook.CreateFont();
                fontTitle.FontName = "微軟正黑體";
                fontTitle.FontHeightInPoints = 14;
                fontTitle.IsBold = true;
                fontTitle.Color = HSSFColor.White.Index;

                ICellStyle styleTitle = workbook.CreateCellStyle();
                styleTitle.SetFont(fontTitle);
                styleTitle.Alignment = HorizontalAlignment.Center;
                styleTitle.VerticalAlignment = VerticalAlignment.Center;
                styleTitle.FillForegroundColor = HSSFColor.LightBlue.Index;
                styleTitle.FillPattern = FillPattern.SolidForeground;

                // 欄位標頭字型與樣式
                IFont fontHeader = workbook.CreateFont();
                fontHeader.FontName = "微軟正黑體";
                fontHeader.FontHeightInPoints = 11;
                fontHeader.IsBold = true;

                ICellStyle styleHeader = workbook.CreateCellStyle();
                styleHeader.SetFont(fontHeader);
                styleHeader.Alignment = HorizontalAlignment.Center;
                styleHeader.VerticalAlignment = VerticalAlignment.Center;
                styleHeader.FillForegroundColor = HSSFColor.Grey25Percent.Index;
                styleHeader.FillPattern = FillPattern.SolidForeground;
                styleHeader.BorderTop = BorderStyle.Thin;
                styleHeader.BorderBottom = BorderStyle.Thin;
                styleHeader.BorderLeft = BorderStyle.Thin;
                styleHeader.BorderRight = BorderStyle.Thin;

                // 內文字型與樣式
                IFont fontBody = workbook.CreateFont();
                fontBody.FontName = "微軟正黑體";
                fontBody.FontHeightInPoints = 10;

                ICellStyle styleBody = workbook.CreateCellStyle();
                styleBody.SetFont(fontBody);
                styleBody.VerticalAlignment = VerticalAlignment.Center;
                styleBody.BorderTop = BorderStyle.Thin;
                styleBody.BorderBottom = BorderStyle.Thin;
                styleBody.BorderLeft = BorderStyle.Thin;
                styleBody.BorderRight = BorderStyle.Thin;
                styleBody.WrapText = true;

                ICellStyle styleBodyCenter = workbook.CreateCellStyle();
                styleBodyCenter.CloneStyleFrom(styleBody);
                styleBodyCenter.Alignment = HorizontalAlignment.Center;

                // 依使用者選取的欄位決定匯出清單
                List<string> showFields = filter.ShowFields;
                if (showFields == null || showFields.Count == 0)
                {
                    showFields = new List<string> { "C_NO", "FAC_NAME", "TOWN_NA", "INDUSTRIAL_Name", "ProcessList", "CheckTime_LV", "INV_DATE", "INV_TYPE", "Loss_LV", "Loss_Point", "Loss_Detail" };
                }

                // 欄位名稱對照表
                Dictionary<string, string> colNames = new Dictionary<string, string>();
                colNames.Add("C_NO", "管制編號");
                colNames.Add("FAC_NAME", "場所名稱");
                colNames.Add("TOWN_NA", "行政區");
                colNames.Add("INDUSTRIAL_Name", "行業別");
                colNames.Add("ProcessList", "製程編號/名稱/狀態/許可證字號");
                colNames.Add("CheckTime_LV", "查核頻率分級");
                colNames.Add("INV_DATE", "巡查日期");
                colNames.Add("INV_TYPE", "查核屬性");
                colNames.Add("Loss_LV", "缺失分級");
                colNames.Add("Loss_Point", "缺失點數");
                colNames.Add("Loss_Detail", "缺失項目");

                List<string> activeCols = new List<string>();
                for (int i = 0; i < showFields.Count; i++)
                {
                    if (colNames.ContainsKey(showFields[i]))
                    {
                        activeCols.Add(showFields[i]);
                    }
                }
                if (activeCols.Count == 0)
                {
                    activeCols.AddRange(new string[] { "C_NO", "FAC_NAME", "TOWN_NA", "INDUSTRIAL_Name", "ProcessList", "CheckTime_LV", "INV_DATE", "INV_TYPE", "Loss_LV", "Loss_Point", "Loss_Detail" });
                }

                int rowIndex = 0;

                // 報表大標題
                IRow rowTitle = sheet.CreateRow(rowIndex);
                rowTitle.HeightInPoints = 32;
                ICell cellTitle = rowTitle.CreateCell(0);
                cellTitle.SetCellValue("新北市固定溢散源管理平台 - 公私場所巡查案件統計報表");
                cellTitle.CellStyle = styleTitle;
                sheet.AddMergedRegion(new CellRangeAddress(0, 0, 0, activeCols.Count - 1));
                rowIndex++;

                // 欄位標頭
                IRow rowHeader = sheet.CreateRow(rowIndex);
                rowHeader.HeightInPoints = 26;
                for (int c = 0; c < activeCols.Count; c++)
                {
                    ICell cell = rowHeader.CreateCell(c);
                    cell.SetCellValue(colNames[activeCols[c]]);
                    cell.CellStyle = styleHeader;
                }
                rowIndex++;

                // 填入資料列
                for (int i = 0; i < allList.Count; i++)
                {
                    CaseRowItem item = allList[i];
                    IRow row = sheet.CreateRow(rowIndex);
                    row.HeightInPoints = 22;

                    for (int c = 0; c < activeCols.Count; c++)
                    {
                        string colKey = activeCols[c];
                        ICell cell = row.CreateCell(c);

                        switch (colKey)
                        {
                            case "C_NO":
                                cell.SetCellValue(item.CNo);
                                cell.CellStyle = styleBodyCenter;
                                break;
                            case "FAC_NAME":
                                cell.SetCellValue(item.FacName);
                                cell.CellStyle = styleBody;
                                break;
                            case "TOWN_NA":
                                cell.SetCellValue(item.TownName);
                                cell.CellStyle = styleBodyCenter;
                                break;
                            case "INDUSTRIAL_Name":
                                cell.SetCellValue(item.IndustrialName);
                                cell.CellStyle = styleBody;
                                break;
                            case "ProcessList":
                                cell.SetCellValue(item.ProcessList.Replace("<br />", "\r\n").Replace("<br>", "\r\n"));
                                cell.CellStyle = styleBody;
                                break;
                            case "CheckTime_LV":
                                cell.SetCellValue(item.CheckTimeLv);
                                cell.CellStyle = styleBodyCenter;
                                break;
                            case "INV_DATE":
                                cell.SetCellValue(item.InvDate);
                                cell.CellStyle = styleBodyCenter;
                                break;
                            case "INV_TYPE":
                                cell.SetCellValue(item.InvType);
                                cell.CellStyle = styleBodyCenter;
                                break;
                            case "Loss_LV":
                                cell.SetCellValue(item.LossLv);
                                cell.CellStyle = styleBodyCenter;
                                break;
                            case "Loss_Point":
                                cell.SetCellValue(item.LossPoint);
                                cell.CellStyle = styleBodyCenter;
                                break;
                            case "Loss_Detail":
                                string plainDetail = item.LossDetail.Replace("<br />", "\r\n").Replace("<br>", "\r\n");
                                plainDetail = System.Text.RegularExpressions.Regex.Replace(plainDetail, "<[^>]+>", "");
                                cell.SetCellValue(plainDetail);
                                cell.CellStyle = styleBody;
                                break;
                            default:
                                cell.SetCellValue("");
                                cell.CellStyle = styleBody;
                                break;
                        }
                    }
                    rowIndex++;
                }

                // 自動調整欄寬
                for (int c = 0; c < activeCols.Count; c++)
                {
                    sheet.AutoSizeColumn(c);
                    int currentWidth = sheet.GetColumnWidth(c);
                    if (currentWidth < 3000)
                    {
                        sheet.SetColumnWidth(c, 3000);
                    }
                    else if (currentWidth > 15000)
                    {
                        sheet.SetColumnWidth(c, 15000);
                    }
                }

                string fileName = string.Format("公私場所巡查案件統計_{0}.xls", DateTime.Now.ToString("yyyyMMddHHmmss"));
                Response.Clear();
                Response.Buffer = true;
                Response.ContentType = "application/vnd.ms-excel";
                Response.AddHeader("Content-Disposition", string.Format("attachment;filename={0}", HttpUtility.UrlEncode(fileName, Encoding.UTF8)));

                using (MemoryStream ms = new MemoryStream())
                {
                    workbook.Write(ms);
                    Response.BinaryWrite(ms.ToArray());
                }
                Response.Flush();
            }
            catch (Exception ex)
            {
                Response.Clear();
                Response.ContentType = "text/html; charset=utf-8";
                Response.Write("<script>alert('匯出失敗: " + HttpUtility.JavaScriptStringEncode(ex.Message) + "'); window.close();</script>");
            }
            Response.End();
        }

        #endregion

        #region 資料庫查詢核心邏輯

        private SumFilterRequest ParseFilterFromRequest()
        {
            SumFilterRequest filter = new SumFilterRequest();

            // 若為 POST 傳遞 JSON 格式
            if (Request.HttpMethod.Equals("POST", StringComparison.OrdinalIgnoreCase))
            {
                try
                {
                    Request.InputStream.Position = 0;
                    using (StreamReader reader = new StreamReader(Request.InputStream, Encoding.UTF8))
                    {
                        string body = reader.ReadToEnd();
                        if (!string.IsNullOrEmpty(body))
                        {
                            SumFilterRequest parsed = jsonSerializer.Deserialize<SumFilterRequest>(body);
                            if (parsed != null)
                            {
                                return parsed;
                            }
                        }
                    }
                }
                catch
                {
                }
            }

            // 否則從 QueryString / Form 讀取
            filter.CNo = Request["cNo"] != null ? Request["cNo"].Trim() : "";
            filter.FacName = Request["facName"] != null ? Request["facName"].Trim() : "";
            filter.Industry = Request["industry"] != null ? Request["industry"].Trim() : "";
            filter.Process = Request["process"] != null ? Request["process"].Trim() : "";
            filter.DateStart = Request["dateStart"] != null ? Request["dateStart"].Trim() : "";
            filter.DateEnd = Request["dateEnd"] != null ? Request["dateEnd"].Trim() : "";
            filter.SortField = !string.IsNullOrEmpty(Request["sortField"]) ? Request["sortField"].Trim() : "INV_DATE";
            filter.SortDir = !string.IsNullOrEmpty(Request["sortDir"]) ? Request["sortDir"].Trim() : "desc";

            int pIdx = 1;
            if (int.TryParse(Request["pageIndex"], out pIdx) && pIdx > 0)
            {
                filter.PageIndex = pIdx;
            }

            int pSize = 25;
            if (int.TryParse(Request["pageSize"], out pSize) && pSize > 0)
            {
                filter.PageSize = pSize;
            }

            string townsParam = Request["towns"];
            if (!string.IsNullOrEmpty(townsParam))
            {
                string[] parts = townsParam.Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
                for (int i = 0; i < parts.Length; i++)
                {
                    filter.Towns.Add(parts[i].Trim());
                }
            }

            string lossParam = Request["lossLevels"];
            if (!string.IsNullOrEmpty(lossParam))
            {
                string[] parts = lossParam.Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
                for (int i = 0; i < parts.Length; i++)
                {
                    filter.LossLevels.Add(parts[i].Trim());
                }
            }

            string showFieldsParam = Request["showFields"];
            if (!string.IsNullOrEmpty(showFieldsParam))
            {
                string[] parts = showFieldsParam.Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
                for (int i = 0; i < parts.Length; i++)
                {
                    filter.ShowFields.Add(parts[i].Trim());
                }
            }

            return filter;
        }

        private List<CaseRowItem> QueryCaseData(SumFilterRequest filter)
        {
            List<CaseRowItem> resultList = new List<CaseRowItem>();
            List<SqlParameter> paramList = new List<SqlParameter>();
            List<string> whereList = new List<string>();

            // 1. 組合場所與行業主查詢
            StringBuilder sbSql = new StringBuilder();
            sbSql.Append("SELECT TabA.*, INDUSTRIAL_Data.INDUSTRIAL_Name, C_TOWN.TOWN_NA FROM (");
            sbSql.Append("  SELECT FAC_ID");
            sbSql.Append("  , CASE WHEN (SELECT TOP 1 C_NO FROM FAC_EditHis WHERE C_NO IS NOT NULL AND FAC_EditHis.FAC_ID = FAC_Main.FAC_ID ORDER BY Edit_Date DESC) IS NOT NULL ");
            sbSql.Append("         THEN (SELECT TOP 1 C_NO FROM FAC_EditHis WHERE C_NO IS NOT NULL AND FAC_EditHis.FAC_ID = FAC_Main.FAC_ID ORDER BY Edit_Date DESC) ");
            sbSql.Append("         ELSE C_NO END AS C_NO");
            sbSql.Append("  , CASE WHEN (SELECT TOP 1 TOWN_CODE FROM FAC_EditHis WHERE TOWN_CODE IS NOT NULL AND FAC_EditHis.FAC_ID = FAC_Main.FAC_ID ORDER BY Edit_Date DESC) IS NOT NULL ");
            sbSql.Append("         THEN (SELECT TOP 1 TOWN_CODE FROM FAC_EditHis WHERE TOWN_CODE IS NOT NULL AND FAC_EditHis.FAC_ID = FAC_Main.FAC_ID ORDER BY Edit_Date DESC) ");
            sbSql.Append("         ELSE TOWN_CODE END AS TOWN_CODE");
            sbSql.Append("  , CASE WHEN (SELECT TOP 1 FAC_NAME FROM FAC_EditHis WHERE FAC_NAME IS NOT NULL AND FAC_EditHis.FAC_ID = FAC_Main.FAC_ID ORDER BY Edit_Date DESC) IS NOT NULL ");
            sbSql.Append("         THEN (SELECT TOP 1 FAC_NAME FROM FAC_EditHis WHERE FAC_NAME IS NOT NULL AND FAC_EditHis.FAC_ID = FAC_Main.FAC_ID ORDER BY Edit_Date DESC) ");
            sbSql.Append("         ELSE FAC_NAME END AS FAC_NAME");
            sbSql.Append("  , CASE WHEN (SELECT TOP 1 INDUSTRIAL_Code1 FROM FAC_EditHis WHERE INDUSTRIAL_Code1 IS NOT NULL AND FAC_EditHis.FAC_ID = FAC_Main.FAC_ID ORDER BY Edit_Date DESC) IS NOT NULL ");
            sbSql.Append("         THEN (SELECT TOP 1 INDUSTRIAL_Code1 FROM FAC_EditHis WHERE INDUSTRIAL_Code1 IS NOT NULL AND FAC_EditHis.FAC_ID = FAC_Main.FAC_ID ORDER BY Edit_Date DESC) ");
            sbSql.Append("         ELSE INDUSTRIAL_Code1 END AS INDUSTRIAL_Code1");
            sbSql.Append("  , CheckTime_LV");
            sbSql.Append("  FROM FAC_Main");
            sbSql.Append(") AS TabA ");
            sbSql.Append("LEFT JOIN INDUSTRIAL_Data ON INDUSTRIAL_Data.INDUSTRIAL_Code = TabA.INDUSTRIAL_Code1 ");
            sbSql.Append("LEFT JOIN C_TOWN ON C_TOWN.COUNTRY = 'F' AND C_TOWN.TOWN_NO = TabA.TOWN_CODE ");

            // 管制編號過濾
            if (!string.IsNullOrEmpty(filter.CNo))
            {
                whereList.Add("TabA.C_NO LIKE '%' + @C_NO + '%'");
                paramList.Add(new SqlParameter("@C_NO", filter.CNo));
            }

            // 場所名稱過濾
            if (!string.IsNullOrEmpty(filter.FacName))
            {
                whereList.Add("TabA.FAC_NAME LIKE '%' + @FAC_NAME + '%'");
                paramList.Add(new SqlParameter("@FAC_NAME", filter.FacName));
            }

            // 行業別過濾
            if (!string.IsNullOrEmpty(filter.Industry))
            {
                whereList.Add("INDUSTRIAL_Data.INDUSTRIAL_Name LIKE '%' + @INDUSTRIAL_Name + '%'");
                paramList.Add(new SqlParameter("@INDUSTRIAL_Name", filter.Industry));
            }

            // 行政區過濾
            if (filter.Towns != null && filter.Towns.Count > 0)
            {
                List<string> townParamList = new List<string>();
                for (int i = 0; i < filter.Towns.Count; i++)
                {
                    string pName = "@Town_" + i;
                    townParamList.Add(pName);
                    paramList.Add(new SqlParameter(pName, filter.Towns[i]));
                }
                whereList.Add(string.Format("TabA.TOWN_CODE IN ({0})", string.Join(",", townParamList.ToArray())));
            }

            if (whereList.Count > 0)
            {
                sbSql.Append(" WHERE ");
                sbSql.Append(string.Join(" AND ", whereList.ToArray()));
            }

            DataTable dtFacs = DbHelper.ExecuteDataTable(sbSql.ToString(), paramList.ToArray());
            if (dtFacs == null || dtFacs.Rows.Count == 0)
            {
                return resultList;
            }

            // 缺失分級選取集合
            bool filterLoss0 = true;
            bool filterLoss1 = true;
            bool filterLoss10 = true;

            if (filter.LossLevels != null && filter.LossLevels.Count > 0)
            {
                filterLoss0 = filter.LossLevels.Contains("無缺失");
                filterLoss1 = filter.LossLevels.Contains("輕微缺失");
                filterLoss10 = filter.LossLevels.Contains("嚴重缺失");
            }

            // 針對查出之所有場所，遍歷其巡查案件
            for (int f = 0; f < dtFacs.Rows.Count; f++)
            {
                DataRow facRow = dtFacs.Rows[f];
                string facId = facRow["FAC_ID"] != null ? facRow["FAC_ID"].ToString() : "";
                if (string.IsNullOrEmpty(facId))
                {
                    continue;
                }

                // 取得製程字串
                string sqlProc = "SELECT DISTINCT Process_NO, Process_Name, Process_Type, Process_Lic, Lic_Year FROM INV_Process_Main WHERE FAC_ID = @FAC_ID";
                DataTable dtProc = DbHelper.ExecuteDataTable(sqlProc, new SqlParameter("@FAC_ID", facId));
                StringBuilder sbProc = new StringBuilder();

                if (dtProc != null && dtProc.Rows.Count > 0)
                {
                    for (int p = 0; p < dtProc.Rows.Count; p++)
                    {
                        DataRow pr = dtProc.Rows[p];
                        string pNo = pr["Process_NO"] != null ? pr["Process_NO"].ToString() : "";
                        string pType = pr["Process_Type"] != null ? pr["Process_Type"].ToString() : "";
                        string pLic = pr["Process_Lic"] != null ? pr["Process_Lic"].ToString() : "";
                        if (p > 0)
                        {
                            sbProc.Append("<br />");
                        }
                        sbProc.Append(string.Format("{0}/{1}/{2}", pNo, pType, pLic));
                    }
                }
                string processListStr = sbProc.ToString();

                // 檢查程序別過濾
                if (!string.IsNullOrEmpty(filter.Process))
                {
                    if (processListStr.IndexOf(filter.Process, StringComparison.OrdinalIgnoreCase) < 0)
                    {
                        continue;
                    }
                }

                // 查詢該場所在指定日期區間之巡查資料
                StringBuilder sbInvSql = new StringBuilder();
                List<SqlParameter> invParams = new List<SqlParameter>();
                sbInvSql.Append("SELECT * FROM INV_Data WHERE FAC_ID = @FAC_ID");
                invParams.Add(new SqlParameter("@FAC_ID", facId));

                if (!string.IsNullOrEmpty(filter.DateStart))
                {
                    DateTime dStart;
                    if (DateTime.TryParse(filter.DateStart, out dStart))
                    {
                        sbInvSql.Append(" AND INV_DATE >= @INV_DATE_Start");
                        invParams.Add(new SqlParameter("@INV_DATE_Start", dStart.ToString("yyyy-MM-dd 00:00:00")));
                    }
                }

                if (!string.IsNullOrEmpty(filter.DateEnd))
                {
                    DateTime dEnd;
                    if (DateTime.TryParse(filter.DateEnd, out dEnd))
                    {
                        sbInvSql.Append(" AND INV_DATE <= @INV_DATE_End");
                        invParams.Add(new SqlParameter("@INV_DATE_End", dEnd.ToString("yyyy-MM-dd 23:59:59")));
                    }
                }

                sbInvSql.Append(" ORDER BY INV_DATE DESC");
                DataTable dtInv = DbHelper.ExecuteDataTable(sbInvSql.ToString(), invParams.ToArray());

                if (dtInv == null || dtInv.Rows.Count == 0)
                {
                    continue;
                }

                for (int i = 0; i < dtInv.Rows.Count; i++)
                {
                    DataRow invRow = dtInv.Rows[i];

                    // 計算缺失各項點數與總點數
                    List<LossItemScore> itemScores = new List<LossItemScore>();
                    int totalLossPoint = CalculateLossPoints(invRow, out itemScores);

                    string lossLv = "無缺失";
                    bool isMatchLoss = false;

                    if (totalLossPoint == 0)
                    {
                        lossLv = "無缺失";
                        if (filterLoss0) { isMatchLoss = true; }
                    }
                    else if (totalLossPoint >= 1 && totalLossPoint <= 9)
                    {
                        lossLv = "輕微缺失";
                        if (filterLoss1) { isMatchLoss = true; }
                    }
                    else if (totalLossPoint >= 10)
                    {
                        lossLv = "嚴重缺失";
                        if (filterLoss10) { isMatchLoss = true; }
                    }

                    if (!isMatchLoss)
                    {
                        continue;
                    }

                    CaseRowItem item = new CaseRowItem();
                    item.FacId = facId;
                    item.CNo = facRow["C_NO"] != null ? facRow["C_NO"].ToString().Trim() : "";
                    item.FacName = facRow["FAC_NAME"] != null ? facRow["FAC_NAME"].ToString().Trim() : "";
                    item.TownCode = facRow["TOWN_CODE"] != null ? facRow["TOWN_CODE"].ToString().Trim() : "";
                    item.TownName = facRow["TOWN_NA"] != null ? facRow["TOWN_NA"].ToString().Trim() : "";
                    item.IndustrialCode = facRow["INDUSTRIAL_Code1"] != null ? facRow["INDUSTRIAL_Code1"].ToString().Trim() : "";
                    item.IndustrialName = facRow["INDUSTRIAL_Name"] != null ? facRow["INDUSTRIAL_Name"].ToString().Trim() : "";
                    item.CheckTimeLv = facRow["CheckTime_LV"] != null ? facRow["CheckTime_LV"].ToString().Trim() : "";
                    item.ProcessList = processListStr;

                    if (invRow["INV_DATE"] != null && invRow["INV_DATE"] != DBNull.Value)
                    {
                        DateTime dtVal;
                        if (DateTime.TryParse(invRow["INV_DATE"].ToString(), out dtVal))
                        {
                            item.InvDate = dtVal.ToString("yyyy-MM-dd");
                        }
                        else
                        {
                            item.InvDate = invRow["INV_DATE"].ToString();
                        }
                    }

                    item.InvType = invRow["INV_TYPE"] != null ? invRow["INV_TYPE"].ToString().Trim() : "";
                    item.LossPoint = totalLossPoint;
                    item.LossLv = lossLv;
                    item.ItemScores = itemScores;
                    item.LossDetail = BuildLossDetailHtml(itemScores);

                    resultList.Add(item);
                }
            }

            // 排序處理
            string sortField = !string.IsNullOrEmpty(filter.SortField) ? filter.SortField : "INV_DATE";
            bool isDesc = "desc".Equals(filter.SortDir, StringComparison.OrdinalIgnoreCase);

            resultList.Sort(delegate(CaseRowItem a, CaseRowItem b)
            {
                int cmp = 0;
                switch (sortField)
                {
                    case "C_NO":
                        cmp = string.Compare(a.CNo, b.CNo, StringComparison.OrdinalIgnoreCase);
                        break;
                    case "FAC_NAME":
                        cmp = string.Compare(a.FacName, b.FacName, StringComparison.OrdinalIgnoreCase);
                        break;
                    case "TOWN_NA":
                        cmp = string.Compare(a.TownName, b.TownName, StringComparison.OrdinalIgnoreCase);
                        break;
                    case "INDUSTRIAL_Name":
                        cmp = string.Compare(a.IndustrialName, b.IndustrialName, StringComparison.OrdinalIgnoreCase);
                        break;
                    case "Loss_Point":
                        cmp = a.LossPoint.CompareTo(b.LossPoint);
                        break;
                    case "Loss_LV":
                        cmp = string.Compare(a.LossLv, b.LossLv, StringComparison.OrdinalIgnoreCase);
                        break;
                    case "INV_DATE":
                    default:
                        cmp = string.Compare(a.InvDate, b.InvDate, StringComparison.OrdinalIgnoreCase);
                        break;
                }
                return isDesc ? -cmp : cmp;
            });

            return resultList;
        }

        #endregion

        #region 9大管制項目缺失演算法

        private static bool IsY(DataRow row, string colName)
        {
            if (row == null || !row.Table.Columns.Contains(colName))
            {
                return false;
            }
            object val = row[colName];
            return val != null && "Y".Equals(val.ToString().Trim(), StringComparison.OrdinalIgnoreCase);
        }

        public static int CalculateLossPoints(DataRow pRow, out List<LossItemScore> scores)
        {
            scores = new List<LossItemScore>();

            // 1. 堆置逸散性粒狀污染物質
            int pt1 = 0;
            if (IsY(pRow, "INV_01_01") || IsY(pRow, "INV_01_02") || IsY(pRow, "INV_01_03"))
            {
                pt1 = 0;
            }
            if (IsY(pRow, "INV_01_04") || IsY(pRow, "INV_01_05"))
            {
                pt1 = 10;
            }
            if (IsY(pRow, "INV_01_08") || IsY(pRow, "INV_01_09") || IsY(pRow, "INV_01_09a") || IsY(pRow, "INV_01_09b") ||
                IsY(pRow, "INV_01_09c") || IsY(pRow, "INV_01_09d") || IsY(pRow, "INV_01_10") || IsY(pRow, "INV_01_10a") ||
                IsY(pRow, "INV_01_10b") || IsY(pRow, "INV_01_11") || IsY(pRow, "INV_01_11a") || IsY(pRow, "INV_01_11b") ||
                IsY(pRow, "INV_01_11c") || IsY(pRow, "INV_01_12") || IsY(pRow, "INV_01_12a") || IsY(pRow, "INV_01_12b") ||
                IsY(pRow, "INV_01_12c") || IsY(pRow, "INV_01_13") || IsY(pRow, "INV_01_14") || IsY(pRow, "INV_01_07"))
            {
                pt1 = 4;
            }

            // 2. 輸送逸散性粒狀污染物質
            int pt2 = 0;
            if (IsY(pRow, "INV_02_01") || IsY(pRow, "INV_02_02") || IsY(pRow, "INV_02_03") || IsY(pRow, "INV_02_04"))
            {
                pt2 = 0;
            }
            if (IsY(pRow, "INV_02_05") || IsY(pRow, "INV_02_06"))
            {
                pt2 = 10;
            }
            if (IsY(pRow, "INV_02_07") || IsY(pRow, "INV_02_08") || IsY(pRow, "INV_02_09") || IsY(pRow, "INV_02_09a") ||
                IsY(pRow, "INV_02_09b") || IsY(pRow, "INV_02_10") || IsY(pRow, "INV_02_10a") || IsY(pRow, "INV_02_10b") ||
                IsY(pRow, "INV_02_10c") || IsY(pRow, "INV_02_11"))
            {
                pt2 = 4;
            }

            // 3. 運輸車輛
            int pt3 = 0;
            if (IsY(pRow, "INV_03_01") || IsY(pRow, "INV_03_02") || IsY(pRow, "INV_03_03"))
            {
                pt3 = 0;
            }
            if (IsY(pRow, "INV_03_04") || IsY(pRow, "INV_03_05") || IsY(pRow, "INV_03_06"))
            {
                pt3 = 10;
            }
            if (IsY(pRow, "INV_03_07") || IsY(pRow, "INV_03_08") || IsY(pRow, "INV_03_09"))
            {
                pt3 = 4;
            }

            // 4. 車輛通行路徑及區域
            int pt4 = 0;
            if (IsY(pRow, "INV_04_01") || IsY(pRow, "INV_04_02") || IsY(pRow, "INV_04_03"))
            {
                pt4 = 0;
            }
            if (IsY(pRow, "INV_04_04") || IsY(pRow, "INV_04_05"))
            {
                pt4 = 10;
            }
            if (IsY(pRow, "INV_04_06") || IsY(pRow, "INV_04_07") || IsY(pRow, "INV_04_08") || IsY(pRow, "INV_04_09"))
            {
                pt4 = 4;
            }

            // 5. 車輛清洗
            int pt5 = 0;
            if (IsY(pRow, "INV_05_01") || IsY(pRow, "INV_05_02") || IsY(pRow, "INV_05_03"))
            {
                pt5 = 0;
            }
            if (IsY(pRow, "INV_05_04") || IsY(pRow, "INV_05_05") || IsY(pRow, "INV_05_06"))
            {
                pt5 = 10;
            }
            if (IsY(pRow, "INV_05_07") || IsY(pRow, "INV_05_08") || IsY(pRow, "INV_05_09") || IsY(pRow, "INV_05_10") || IsY(pRow, "INV_05_11"))
            {
                pt5 = 4;
            }

            // 6. 易致粒狀污染物逸散之製程、操作或裝卸作業
            int pt6 = 0;
            if (IsY(pRow, "INV_06_01") || IsY(pRow, "INV_06_02") || IsY(pRow, "INV_06_03") || IsY(pRow, "INV_06_04"))
            {
                pt6 = 0;
            }
            if (IsY(pRow, "INV_06_05") || IsY(pRow, "INV_06_06"))
            {
                pt6 = 10;
            }
            if (IsY(pRow, "INV_06_07") || IsY(pRow, "INV_06_07a") || IsY(pRow, "INV_06_07b") || IsY(pRow, "INV_06_08") ||
                IsY(pRow, "INV_06_08a") || IsY(pRow, "INV_06_08b") || IsY(pRow, "INV_06_09") || IsY(pRow, "INV_06_10") ||
                IsY(pRow, "INV_06_11") || IsY(pRow, "INV_06_12"))
            {
                pt6 = 4;
            }

            // 7. 公私場所管理之裸露區域
            int pt7 = 0;
            if (IsY(pRow, "INV_07_01") || IsY(pRow, "INV_07_02") || IsY(pRow, "INV_07_03"))
            {
                pt7 = 0;
            }
            if (IsY(pRow, "INV_07_04") || IsY(pRow, "INV_07_05"))
            {
                pt7 = 10;
            }
            if (IsY(pRow, "INV_07_06") || IsY(pRow, "INV_07_07") || IsY(pRow, "INV_07_08") || IsY(pRow, "INV_07_09") ||
                IsY(pRow, "INV_07_10") || IsY(pRow, "INV_07_11"))
            {
                pt7 = 4;
            }

            // 8. 公私場所管理之道路
            int pt8 = 0;
            if (IsY(pRow, "INV_08_01") || IsY(pRow, "INV_08_02") || IsY(pRow, "INV_08_03"))
            {
                pt8 = 0;
            }
            if (IsY(pRow, "INV_08_04") || IsY(pRow, "INV_08_05"))
            {
                pt8 = 10;
            }
            if (IsY(pRow, "INV_08_06") || IsY(pRow, "INV_08_07") || IsY(pRow, "INV_08_08") || IsY(pRow, "INV_08_09") || IsY(pRow, "INV_08_10"))
            {
                pt8 = 4;
            }

            // 9. 攝錄影監視系統
            int pt9 = 0;
            if (IsY(pRow, "INV_09_01") || IsY(pRow, "INV_09_02") || IsY(pRow, "INV_09_03"))
            {
                pt9 = 0;
            }
            if (IsY(pRow, "INV_09_04") || IsY(pRow, "INV_09_05") || IsY(pRow, "INV_09_06"))
            {
                pt9 = 10;
            }
            if (IsY(pRow, "INV_09_07") || IsY(pRow, "INV_09_08"))
            {
                pt9 = 4;
            }

            scores.Add(CreateScoreItem(1, "堆置逸散性粒狀污染物質", pt1));
            scores.Add(CreateScoreItem(2, "輸送逸散性粒狀污染物質", pt2));
            scores.Add(CreateScoreItem(3, "運輸車輛", pt3));
            scores.Add(CreateScoreItem(4, "車輛通行路徑及區域", pt4));
            scores.Add(CreateScoreItem(5, "車輛清洗", pt5));
            scores.Add(CreateScoreItem(6, "易致粒狀污染物逸散之製程、操作或裝卸作業", pt6));
            scores.Add(CreateScoreItem(7, "公私場所管理之裸露區域", pt7));
            scores.Add(CreateScoreItem(8, "公私場所管理之道路", pt8));
            scores.Add(CreateScoreItem(9, "攝錄影監視系統", pt9));

            return pt1 + pt2 + pt3 + pt4 + pt5 + pt6 + pt7 + pt8 + pt9;
        }

        private static LossItemScore CreateScoreItem(int no, string title, int pt)
        {
            LossItemScore item = new LossItemScore();
            item.ItemNo = no;
            item.Title = title;
            item.Point = pt;
            if (pt == 0)
            {
                item.StatusText = "合格 (0點)";
            }
            else if (pt >= 10)
            {
                item.StatusText = string.Format("嚴重缺失 ({0}點)", pt);
            }
            else
            {
                item.StatusText = string.Format("缺失 ({0}點)", pt);
            }
            return item;
        }

        private static string BuildLossDetailHtml(List<LossItemScore> scores)
        {
            if (scores == null || scores.Count == 0)
            {
                return "無缺失資料";
            }
            StringBuilder sb = new StringBuilder();
            string[] chineseNums = new string[] { "", "一", "二", "三", "四", "五", "六", "七", "八", "九" };

            for (int i = 0; i < scores.Count; i++)
            {
                LossItemScore s = scores[i];
                string cNum = (s.ItemNo >= 1 && s.ItemNo <= 9) ? chineseNums[s.ItemNo] : s.ItemNo.ToString();
                string colorStyle = "color: #10b981; font-weight: 600;"; // 綠色
                if (s.Point >= 10)
                {
                    colorStyle = "color: #ef4444; font-weight: 700;"; // 紅色
                }
                else if (s.Point > 0)
                {
                    colorStyle = "color: #f59e0b; font-weight: 700;"; // 橙色
                }

                if (i > 0)
                {
                    sb.Append("<br />");
                }
                sb.Append(string.Format("{0}、{1}<span style='{2}'> (記{3}點)</span>", cNum, s.Title, colorStyle, s.Point));
            }

            return sb.ToString();
        }

        #endregion
    }
}
