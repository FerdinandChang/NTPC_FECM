# -*- coding: utf-8 -*-
import os, sys

aspx_path = r'd:\NTPC_FEC\Manager\managerList.aspx'
cs_path = r'd:\NTPC_FEC\Manager\managerList.aspx.cs'

# ==================== 1. 更新 Manager/managerList.aspx ====================
with open(aspx_path, 'r', encoding='utf-8-sig') as fp:
    aspx_txt = fp.read()

# 替換頂部 Navbar
old_nav = """        <!-- 頂部導覽列 -->
        <header class="top-navbar">
            <div class="d-flex align-items-center">
                <a href="../MainPage.aspx" class="nav-btn mr-3" title="返回主選單">
                    <i class="fas fa-arrow-left"></i>
                    <span class="d-none d-sm-inline">返回主選單</span>
                </a>
                <div class="navbar-brand-title">
                    <i class="fas fa-tasks text-white"></i>
                    <span>固定溢散源管理審查平台</span>
                    <span class="badge badge-light text-dark font-weight-bold ml-2 d-none d-md-inline" style="font-size: 0.82rem;">案件審查作業</span>
                </div>
            </div>

            <div class="d-flex align-items-center gap-2">
                <span class="badge badge-pill badge-light mr-2 d-none d-sm-inline-block py-2 px-3 text-secondary" style="font-size: 13px;">
                    <i class="fas fa-user-shield mr-1 text-primary"></i> {{ currentUser }}
                </span>
                <button type="button" class="nav-btn" v-on:click="fetchList" :disabled="loading" title="重新整理資料">
                    <i class="fas fa-sync-alt" :class="{ 'fa-spin': loading }"></i>
                    <span class="d-none d-sm-inline">重新整理</span>
                </button>
            </div>
        </header>"""

new_nav = """        <!-- 頂部導覽列 (全站標準左側導航、右側使用者資訊) -->
        <header class="top-navbar">
            <div class="d-flex align-items-center">
                <a href="../MainPage.aspx" class="nav-btn mr-2" title="返回主選單">
                    <i class="fas fa-home"></i>
                    <span class="d-none d-sm-inline">回首頁</span>
                </a>
                <a href="managerList.aspx" class="navbar-brand-title">
                    <i class="fas fa-tasks text-white"></i>
                    <span>固定溢散源管理審查平台</span>
                    <span class="badge badge-light text-dark font-weight-bold ml-1">
                        {{ stats.TotalCases }} 筆待審
                    </span>
                </a>
            </div>

            <div class="d-flex align-items-center gap-2">
                <span class="badge badge-pill badge-light py-2 px-3 text-secondary" style="font-size: 13px;">
                    <i class="fas fa-user-shield mr-1 text-primary"></i> {{ currentUser }}
                </span>
            </div>
        </header>"""

# 替換篩選卡片底部動作列
old_filter_foot = """                    <div class="d-flex align-items-center justify-content-end gap-2 mt-2">
                        <button type="button" class="btn btn-outline-secondary mr-2" v-on:click="resetFilter">
                            <i class="fas fa-undo mr-1"></i> 重設條件
                        </button>
                        <button type="button" class="btn btn-primary px-4 font-weight-bold" v-on:click="fetchList" :disabled="loading">
                            <i class="fas fa-search mr-1"></i> 開始搜尋
                        </button>
                    </div>"""

new_filter_foot = """                    <!-- 底部標準操作列 (左側統計、右側重設與查詢) -->
                    <div class="d-flex justify-content-between align-items-center mt-2 pt-2 border-top">
                        <div class="small text-muted">
                            共查詢到 <strong class="text-primary">{{ items.length }}</strong> 家待審查場所
                        </div>
                        <div>
                            <button type="button" class="btn btn-outline-secondary btn-sm mr-2" v-on:click="resetFilter">
                                <i class="fas fa-undo mr-1"></i> 重設條件
                            </button>
                            <button type="button" class="btn btn-primary btn-sm px-3 font-weight-bold" v-on:click="fetchList" :disabled="loading">
                                <i class="fas fa-search mr-1"></i> 立即查詢
                            </button>
                        </div>
                    </div>"""

# 替換清單卡片 Header (大四元標準操作工具列)
old_list_header = """            <!-- 主資料表格卡片 -->
            <div class="card-modern">
                <div class="card-modern-header">
                    <h2 class="card-modern-title">
                        <i class="fas fa-list-ul text-primary"></i> 審查場所清單
                        <span class="badge badge-light border text-secondary ml-2 font-weight-normal">{{ items.length }} 筆記錄</span>
                    </h2>

                    <div class="d-flex align-items-center">
                        <span v-if="loading" class="text-primary small mr-3">
                            <span class="spinner-border spinner-border-sm mr-1"></span> 資料載入中...
                        </span>
                    </div>
                </div>"""

new_list_header = """            <!-- 主資料表格卡片 (標準清單大四元操作工具列) -->
            <div class="card-modern">
                <div class="card-modern-header">
                    <div class="d-flex align-items-center gap-2">
                        <h2 class="card-modern-title">
                            <i class="fas fa-list-alt text-primary"></i>
                            <span>審查場所清單</span>
                        </h2>
                        <span class="badge badge-light border text-dark font-weight-bold ml-1">
                            共 {{ items.length }} 家場所
                        </span>
                    </div>

                    <div class="d-flex align-items-center">
                        <span v-if="loading" class="text-primary small mr-3">
                            <span class="spinner-border spinner-border-sm mr-1"></span> 資料載入中...
                        </span>

                        <!-- 1. 重新整理 -->
                        <button type="button" class="btn btn-sm btn-outline-secondary mr-2" v-on:click="fetchList" :disabled="loading" title="重新整理待審清單">
                            <i class="fas fa-sync-alt mr-1" :class="{ 'fa-spin': loading }"></i>
                            <span class="d-none d-md-inline">重新整理</span>
                        </button>

                        <!-- 2. 匯出 EXCEL -->
                        <button type="button" class="btn btn-sm btn-outline-success font-weight-bold mr-2" v-on:click="exportExcel" :disabled="exporting || items.length === 0" title="匯出當前待審清單 Excel">
                            <i class="fas fa-file-excel mr-1"></i>
                            <span class="d-none d-md-inline">{{ exporting ? '匯出中...' : '匯出 EXCEL' }}</span>
                        </button>
                    </div>
                </div>"""

# 檢查 JS data 增加 exporting
old_js_data = """                return {
                    currentMode: 'INV1',
                    loading: false,"""

new_js_data = """                return {
                    currentMode: 'INV1',
                    loading: false,
                    exporting: false,"""

# 檢查 JS methods 增加 exportExcel
old_js_methods = """                // 執行清單載入"""

new_js_methods = """                // 匯出 EXCEL 報表
                exportExcel() {
                    if (this.items.length === 0) {
                        alert('目前無待審查資料可供匯出！');
                        return;
                    }
                    this.exporting = true;
                    const params = new URLSearchParams();
                    params.append('action', 'exportExcel');
                    params.append('mode', this.currentMode);
                    params.append('facName', this.filter.facName || '');
                    params.append('cno', this.filter.cno || '');
                    params.append('scid', this.filter.scid || '');
                    params.append('towns', this.selectedTowns.join(','));

                    axios.post('managerList.aspx', params, { responseType: 'blob' })
                        .then(res => {
                            const blob = new Blob([res.data], { type: 'application/vnd.ms-excel' });
                            const link = document.createElement('a');
                            link.href = window.URL.createObjectURL(blob);
                            const now = new Date();
                            const timeStr = now.getFullYear() + ('0' + (now.getMonth() + 1)).slice(-2) + ('0' + now.getDate()).slice(-2);
                            link.download = '審查場所清單_' + timeStr + '.xls';
                            document.body.appendChild(link);
                            link.click();
                            document.body.removeChild(link);
                        })
                        .catch(err => {
                            console.error('匯出 Excel 失敗:', err);
                            alert('匯出 Excel 失敗，請稍後再試');
                        })
                        .finally(() => {
                            this.exporting = false;
                        });
                },

                // 執行清單載入"""

norm_aspx = aspx_txt.replace('\r\n', '\n')
norm_aspx = norm_aspx.replace(old_nav.replace('\r\n', '\n'), new_nav.replace('\r\n', '\n'))
norm_aspx = norm_aspx.replace(old_filter_foot.replace('\r\n', '\n'), new_filter_foot.replace('\r\n', '\n'))
norm_aspx = norm_aspx.replace(old_list_header.replace('\r\n', '\n'), new_list_header.replace('\r\n', '\n'))
norm_aspx = norm_aspx.replace(old_js_data.replace('\r\n', '\n'), new_js_data.replace('\r\n', '\n'))
norm_aspx = norm_aspx.replace(old_js_methods.replace('\r\n', '\n'), new_js_methods.replace('\r\n', '\n'))

with open(aspx_path, 'w', encoding='utf-8-sig', newline='') as fp:
    fp.write(norm_aspx.replace('\n', '\r\n'))

print('managerList.aspx successfully standardized!')

# ==================== 2. 更新 Manager/managerList.aspx.cs ====================
with open(cs_path, 'r', encoding='utf-8-sig') as fp:
    cs_txt = fp.read()

old_cs_usings = """using NTPC_FEC.Helpers;"""
new_cs_usings = """using NTPC_FEC.Helpers;
using NPOI.HSSF.UserModel;
using NPOI.SS.UserModel;"""

old_cs_load = """        protected void Page_Load(object sender, EventArgs e)
        {
            string action = Request["action"];
            if (!string.IsNullOrEmpty(action))
            {
                Response.Clear();"""

new_cs_load = """        protected void Page_Load(object sender, EventArgs e)
        {
            string action = Request["action"];
            if (!string.IsNullOrEmpty(action))
            {
                Response.Clear();
                if (action.ToLower() == "exportexcel")
                {
                    HandleExportExcel();
                    return;
                }"""

export_cs_code = """
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
"""

norm_cs = cs_txt.replace('\r\n', '\n')
norm_cs = norm_cs.replace(old_cs_usings.replace('\r\n', '\n'), new_cs_usings.replace('\r\n', '\n'))
norm_cs = norm_cs.replace(old_cs_load.replace('\r\n', '\n'), new_cs_load.replace('\r\n', '\n'))

pos_end = norm_cs.rfind('}')
pos_class_end = norm_cs.rfind('}', 0, pos_end)
norm_cs = norm_cs[:pos_class_end] + export_cs_code + '\n' + norm_cs[pos_class_end:]

with open(cs_path, 'w', encoding='utf-8-sig', newline='') as fp:
    fp.write(norm_cs.replace('\n', '\r\n'))

print('managerList.aspx.cs successfully updated with exportExcel!')
