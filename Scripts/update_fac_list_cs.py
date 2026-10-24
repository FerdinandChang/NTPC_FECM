# -*- coding: utf-8 -*-
import os, sys

file_path = r'd:\NTPC_FEC\FAC\FAC_List.aspx.cs'
with open(file_path, 'r', encoding='utf-8-sig') as fp:
    content = fp.read()

# 移除誤插在 class 外的 HandleExportExcel 代碼
export_region_marker = '#region 匯出 Excel 報表'
idx = content.find(export_region_marker)
if idx != -1:
    content = content[:idx].rstrip() + '\n    }\n}\n'

# 現在 content 恢復成正常的類別結構，最後兩行是:
#     }
# }
# 我們把 HandleExportExcel 插入在倒數第二個 } 之前（即 class 內部）
pos_class_end = content.rfind('}')
pos_class_end = content.rfind('}', 0, pos_class_end)

export_code = """
        #region 匯出 Excel 報表
        private void HandleExportExcel()
        {
            try
            {
                string mode = Request["mode"] != null ? Request["mode"].Trim().ToLower() : "read";
                string cNo = Request["cNo"] != null ? Request["cNo"].Trim() : "";
                string facName = Request["facName"] != null ? Request["facName"].Trim() : "";
                string scId = Request["scId"] != null ? Request["scId"].Trim() : "";
                string town = Request["town"] != null ? Request["town"].Trim() : "";
                string industrial = Request["industrial"] != null ? Request["industrial"].Trim() : "";
                string facType = Request["facType"] != null ? Request["facType"].Trim() : "";

                StringBuilder sb = new StringBuilder();
                sb.Append("SELECT m.FAC_ID, m.C_NO, m.FAC_NAME, m.S_C_ID, m.TOWN, m.ADDR, m.Industrial, m.FAC_Type, m.TEL, m.Lat, m.Lng ");
                sb.Append("FROM FAC_Main m WHERE 1=1 ");

                List<SqlParameter> pList = new List<SqlParameter>();

                if (mode == "edit")
                {
                    sb.Append(" AND (m.FAC_Type IS NULL OR RTRIM(LTRIM(m.FAC_Type)) <> '列管') ");
                }

                if (!string.IsNullOrEmpty(cNo))
                {
                    sb.Append(" AND m.C_NO LIKE @C_NO ");
                    pList.Add(new SqlParameter("@C_NO", "%" + cNo + "%"));
                }
                if (!string.IsNullOrEmpty(facName))
                {
                    sb.Append(" AND m.FAC_NAME LIKE @FAC_NAME ");
                    pList.Add(new SqlParameter("@FAC_NAME", "%" + facName + "%"));
                }
                if (!string.IsNullOrEmpty(scId))
                {
                    sb.Append(" AND m.S_C_ID LIKE @S_C_ID ");
                    pList.Add(new SqlParameter("@S_C_ID", "%" + scId + "%"));
                }
                if (!string.IsNullOrEmpty(town))
                {
                    sb.Append(" AND m.TOWN = @TOWN ");
                    pList.Add(new SqlParameter("@TOWN", town));
                }
                if (!string.IsNullOrEmpty(industrial))
                {
                    sb.Append(" AND m.Industrial LIKE @Industrial ");
                    pList.Add(new SqlParameter("@Industrial", "%" + industrial + "%"));
                }
                if (!string.IsNullOrEmpty(facType))
                {
                    sb.Append(" AND m.FAC_Type LIKE @FAC_Type ");
                    pList.Add(new SqlParameter("@FAC_Type", "%" + facType + "%"));
                }

                sb.Append(" ORDER BY m.C_NO ASC, m.FAC_ID ASC");

                DataTable dt = DbHelper.ExecuteDataTable(sb.ToString(), pList.ToArray());

                HSSFWorkbook workbook = new HSSFWorkbook();
                ISheet sheet = workbook.CreateSheet("固定源場所清單");

                // 標題樣式
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

                // 內容樣式
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
                    "行政區", "廠址地址", "行業別", "管制狀態", "聯絡電話", "緯度 (Lat)", "經度 (Lng)"
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
                        string telVal = dr["TEL"] != DBNull.Value ? dr["TEL"].ToString().Trim() : "";
                        string latVal = dr["Lat"] != DBNull.Value ? dr["Lat"].ToString().Trim() : "";
                        string lngVal = dr["Lng"] != DBNull.Value ? dr["Lng"].ToString().Trim() : "";

                        string[] vals = new string[]
                        {
                            seq, cNoVal, facIdVal, nameVal, scIdVal,
                            townVal, addrVal, indVal, typeVal, telVal, latVal, lngVal
                        };

                        for (int cIdx = 0; cIdx < vals.Length; cIdx++)
                        {
                            ICell cell = row.CreateCell(cIdx);
                            cell.SetCellValue(vals[cIdx]);
                            cell.CellStyle = dataStyle;
                        }
                    }
                }

                sheet.SetColumnWidth(0, 8 * 256);
                sheet.SetColumnWidth(1, 16 * 256);
                sheet.SetColumnWidth(2, 16 * 256);
                sheet.SetColumnWidth(3, 30 * 256);
                sheet.SetColumnWidth(4, 14 * 256);
                sheet.SetColumnWidth(5, 12 * 256);
                sheet.SetColumnWidth(6, 36 * 256);
                sheet.SetColumnWidth(7, 24 * 256);
                sheet.SetColumnWidth(8, 12 * 256);
                sheet.SetColumnWidth(9, 16 * 256);
                sheet.SetColumnWidth(10, 14 * 256);
                sheet.SetColumnWidth(11, 14 * 256);

                Response.Clear();
                Response.ContentType = "application/vnd.ms-excel";
                string filename = "固定源場所清單_" + DateTime.Now.ToString("yyyyMMddHHmmss") + ".xls";
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
"""

content = content[:pos_class_end] + export_code + '\n    }\n}\n'

with open(file_path, 'w', encoding='utf-8-sig', newline='') as fp:
    fp.write(content)

print('Correctly inserted HandleExportExcel into class scope!')
