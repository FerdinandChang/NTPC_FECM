# -*- coding: utf-8 -*-
import os, sys

# ==================== 1. 更新 Case/CaseList.aspx ====================
case_aspx_path = r'd:\NTPC_FEC\Case\CaseList.aspx'
with open(case_aspx_path, 'r', encoding='utf-8-sig') as fp:
    case_aspx = fp.read()

# 替換 Navbar: 左側加入回首頁, 右側保留使用者
old_case_nav = """        <!-- 頂部深青藍漸層導覽列 -->
        <header class="top-navbar">
            <a href="../MainPage.aspx?sub=menu1" class="navbar-brand-title">
                <i class="fas fa-clipboard-check text-white"></i>
                <span>固定污染源巡查與任務派遣管理</span>
            </a>
            <div class="d-flex align-items-center gap-2">
                <span class="d-none d-md-inline text-white-50 small mr-2">
                    <i class="fas fa-user-circle mr-1"></i>{{ currentUser }}
                </span>
                <a href="../MainPage.aspx?sub=menu1" class="nav-btn-link">
                    <i class="fas fa-arrow-left"></i>
                    <span>返回主選單</span>
                </a>
            </div>
        </header>"""

new_case_nav = """        <!-- 頂部深青藍漸層導覽列 (全站標準左側導航、右側使用者與輔助操作) -->
        <header class="top-navbar">
            <div class="d-flex align-items-center">
                <a href="../MainPage.aspx?sub=menu1" class="nav-btn mr-2" title="返回主選單">
                    <i class="fas fa-home"></i>
                    <span class="d-none d-sm-inline">回首頁</span>
                </a>
                <a href="CaseList.aspx" class="navbar-brand-title">
                    <i class="fas fa-clipboard-check text-white"></i>
                    <span>固定源巡查與派遣管理</span>
                    <span class="badge badge-light text-dark font-weight-bold ml-1">
                        {{ counts.Total }} 筆
                    </span>
                </a>
            </div>
            <div class="d-flex align-items-center gap-2">
                <span class="d-none d-md-inline text-white small mr-2">
                    <i class="fas fa-user-circle mr-1"></i>{{ currentUser }}
                </span>
                <a href="../FAC/FAC_List.aspx" class="btn btn-outline-light btn-sm font-weight-bold">
                    <i class="fas fa-industry mr-1"></i>場所資料庫
                </a>
            </div>
        </header>"""

# 替換清單卡片 Header: 升級為大四元標準工具列
old_case_header = """                <div class="card-modern-header">
                    <div class="card-modern-title">
                        <i class="fas fa-building text-dark"></i>
                        <span>巡查場所列表</span>
                        <span class="badge badge-info ml-2 font-weight-normal" style="font-size:12px;">
                            共 {{ totalCount }} 家場所
                        </span>
                    </div>
                    <div class="text-muted small" v-if="gpsDistanceMessage">
                        <i class="fas fa-location-arrow text-success mr-1"></i>{{ gpsDistanceMessage }}
                    </div>
                </div>"""

new_case_header = """                <div class="card-modern-header">
                    <div class="d-flex align-items-center gap-2">
                        <div class="card-modern-title">
                            <i class="fas fa-list-alt text-primary"></i>
                            <span>巡查場所列表</span>
                        </div>
                        <span class="badge badge-light border text-dark font-weight-bold ml-1">
                            共 {{ totalCount }} 家
                        </span>
                        <span class="badge badge-secondary ml-1 d-none d-sm-inline">
                            頁次 {{ currentPage }} / {{ totalPages }}
                        </span>
                    </div>
                    <div class="d-flex align-items-center">
                        <div class="text-muted small mr-2 d-none d-xl-inline" v-if="gpsDistanceMessage">
                            <i class="fas fa-location-arrow text-success mr-1"></i>{{ gpsDistanceMessage }}
                        </div>

                        <!-- 1. 重新整理 -->
                        <button type="button" class="btn btn-sm btn-outline-secondary mr-2" v-on:click="loadData(currentPage)" :disabled="loading" title="重新整理場所清單">
                            <i class="fas fa-sync-alt mr-1" :class="{ 'fa-spin': loading }"></i>
                            <span class="d-none d-md-inline">重新整理</span>
                        </button>

                        <!-- 2. 匯出 EXCEL -->
                        <button type="button" class="btn btn-sm btn-outline-success font-weight-bold mr-2" v-on:click="exportExcel" :disabled="exporting || totalCount === 0" title="匯出篩選結果為 EXCEL 報表">
                            <i class="fas fa-file-excel mr-1"></i>
                            <span class="d-none d-md-inline">{{ exporting ? '匯出中...' : '匯出 EXCEL' }}</span>
                        </button>

                        <!-- 3. 每頁筆數選擇器 -->
                        <div class="d-inline-flex align-items-center">
                            <span class="small text-muted mr-1 d-none d-lg-inline">每頁：</span>
                            <select class="form-control form-control-sm d-inline-block w-auto" v-model="pageSize" v-on:change="changePageSize">
                                <option :value="15">15 筆</option>
                                <option :value="30">30 筆</option>
                                <option :value="50">50 筆</option>
                            </select>
                        </div>
                    </div>
                </div>"""

# 檢查 JS data() 與 methods
old_case_data = """                    loading: false,
                    isSearchingGps: false,"""

new_case_data = """                    loading: false,
                    exporting: false,
                    isSearchingGps: false,"""

old_case_methods = """                // 3. 讀取清單資料 (依據當前 filter.Mode 與條件)"""

new_case_methods = """                // 匯出 EXCEL 報表
                exportExcel() {
                    if (this.totalCount === 0) {
                        alert('目前無符合條件之場所資料可供匯出！');
                        return;
                    }
                    this.exporting = true;
                    const params = new URLSearchParams();
                    params.append('action', 'exportExcel');
                    params.append('Mode', this.filter.Mode || 'all');
                    params.append('SearchFacName', this.filter.SearchFacName || '');
                    params.append('SearchCNo', this.filter.SearchCNo || '');
                    params.append('SearchAddr', this.filter.SearchAddr || '');
                    params.append('SearchScId', this.filter.SearchScId || '');
                    params.append('SearchTown', this.filter.SearchTown || '');

                    axios.post('CaseList.aspx', params, { responseType: 'blob' })
                        .then(res => {
                            const blob = new Blob([res.data], { type: 'application/vnd.ms-excel' });
                            const link = document.createElement('a');
                            link.href = window.URL.createObjectURL(blob);
                            const now = new Date();
                            const timeStr = now.getFullYear() + ('0' + (now.getMonth() + 1)).slice(-2) + ('0' + now.getDate()).slice(-2);
                            link.download = '巡查場所派遣清單_' + timeStr + '.xls';
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
                changePageSize() {
                    this.loadData(1);
                },

                // 3. 讀取清單資料 (依據當前 filter.Mode 與條件)"""

norm_case_aspx = case_aspx.replace('\r\n', '\n')
norm_case_aspx = norm_case_aspx.replace(old_case_nav.replace('\r\n', '\n'), new_case_nav.replace('\r\n', '\n'))
norm_case_aspx = norm_case_aspx.replace(old_case_header.replace('\r\n', '\n'), new_case_header.replace('\r\n', '\n'))
norm_case_aspx = norm_case_aspx.replace(old_case_data.replace('\r\n', '\n'), new_case_data.replace('\r\n', '\n'))
norm_case_aspx = norm_case_aspx.replace(old_case_methods.replace('\r\n', '\n'), new_case_methods.replace('\r\n', '\n'))

with open(case_aspx_path, 'w', encoding='utf-8-sig', newline='') as fp:
    fp.write(norm_case_aspx.replace('\n', '\r\n'))

print('CaseList.aspx successfully updated with standard UI components!')

# ==================== 2. 更新 Case/CaseList.aspx.cs ====================
case_cs_path = r'd:\NTPC_FEC\Case\CaseList.aspx.cs'
with open(case_cs_path, 'r', encoding='utf-8-sig') as fp:
    case_cs = fp.read()

old_case_cs_usings = """using NTPC_FEC.Helpers;"""
new_case_cs_usings = """using NTPC_FEC.Helpers;
using NPOI.HSSF.UserModel;
using NPOI.SS.UserModel;"""

old_case_cs_load = """        protected void Page_Load(object sender, EventArgs e)
        {
            string action = Request["action"];
            if (!string.IsNullOrEmpty(action))
            {
                Response.Clear();"""

new_case_cs_load = """        protected void Page_Load(object sender, EventArgs e)
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

export_case_cs_code = """
        #region 匯出 Excel 報表
        private void HandleExportExcel()
        {
            try
            {
                string mode = Request["Mode"] != null ? Request["Mode"].Trim().ToLower() : "all";
                string facName = Request["SearchFacName"] != null ? Request["SearchFacName"].Trim() : "";
                string cNo = Request["SearchCNo"] != null ? Request["SearchCNo"].Trim() : "";
                string addr = Request["SearchAddr"] != null ? Request["SearchAddr"].Trim() : "";
                string scId = Request["SearchScId"] != null ? Request["SearchScId"].Trim() : "";
                string town = Request["SearchTown"] != null ? Request["SearchTown"].Trim() : "";

                StringBuilder sb = new StringBuilder();
                sb.Append("SELECT m.FAC_ID, m.C_NO, m.FAC_NAME, m.S_C_ID, m.TOWN, m.ADDR, m.Industrial, m.FAC_Type, m.TEL, m.Lat, m.Lng ");
                sb.Append("FROM FAC_Main m WHERE 1=1 ");

                List<SqlParameter> pList = new List<SqlParameter>();

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
                if (!string.IsNullOrEmpty(addr))
                {
                    sb.Append(" AND m.ADDR LIKE @ADDR ");
                    pList.Add(new SqlParameter("@ADDR", "%" + addr + "%"));
                }

                sb.Append(" ORDER BY m.C_NO ASC, m.FAC_ID ASC");

                DataTable dt = DbHelper.ExecuteDataTable(sb.ToString(), pList.ToArray());

                HSSFWorkbook workbook = new HSSFWorkbook();
                ISheet sheet = workbook.CreateSheet("巡查場所派遣清單");

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
                    "序號", "管制編號", "公私場所名稱", "統一編號",
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
                            seq, cNoVal, nameVal, scIdVal,
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

                for (int i = 0; i < headers.Length; i++)
                {
                    sheet.SetColumnWidth(i, 16 * 256);
                }
                sheet.SetColumnWidth(0, 8 * 256);
                sheet.SetColumnWidth(2, 30 * 256); // 名稱
                sheet.SetColumnWidth(5, 34 * 256); // 地址

                Response.Clear();
                Response.ContentType = "application/vnd.ms-excel";
                string filename = "巡查場所派遣清單_" + DateTime.Now.ToString("yyyyMMddHHmmss") + ".xls";
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

norm_case_cs = case_cs.replace('\r\n', '\n')
norm_case_cs = norm_case_cs.replace(old_case_cs_usings.replace('\r\n', '\n'), new_case_cs_usings.replace('\r\n', '\n'))
norm_case_cs = norm_case_cs.replace(old_case_cs_load.replace('\r\n', '\n'), new_case_cs_load.replace('\r\n', '\n'))

pos_end = norm_case_cs.rfind('}')
pos_class_end = norm_case_cs.rfind('}', 0, pos_end)
norm_case_cs = norm_case_cs[:pos_class_end] + export_case_cs_code + '\n' + norm_case_cs[pos_class_end:]

with open(case_cs_path, 'w', encoding='utf-8-sig', newline='') as fp:
    fp.write(norm_case_cs.replace('\n', '\r\n'))

print('CaseList.aspx.cs successfully updated with exportExcel!')

# ==================== 3. 更新 RoadClean/Clean_List.aspx ====================
clean_aspx_path = r'd:\NTPC_FEC\RoadClean\Clean_List.aspx'
with open(clean_aspx_path, 'r', encoding='utf-8-sig') as fp:
    clean_aspx = fp.read()

# 替換 Navbar: 左側加入標準回首頁
old_clean_nav = """        <!-- 頂部品牌導覽列 -->
        <header class="top-navbar">
            <a href="Clean_List.aspx" class="navbar-brand-title">
                <i class="fas fa-broom"></i>
                <span>新北市固定溢散源 - 道路潔淨巡檢</span>
            </a>
            <div class="d-flex align-items-center gap-2">
                <a :href="'NewCleanChk.aspx?mode=new&listMode=' + currentMode" class="btn btn-warning font-weight-bold text-dark px-3 shadow-sm mr-2" style="border-radius: 8px;">
                    <i class="fas fa-plus-circle"></i>
                    <span class="d-none d-sm-inline ml-1">新增巡檢</span>
                </a>
                <a href="../MainPage.aspx?sub=menu4" class="btn btn-outline-light font-weight-bold px-3" style="border-radius: 8px;">
                    <i class="fas fa-chevron-left"></i>
                    <span class="d-none d-sm-inline ml-1">回選單</span>
                </a>
            </div>
        </header>"""

new_clean_nav = """        <!-- 頂部品牌導覽列 (全站標準左側導航、右側主操作) -->
        <header class="top-navbar">
            <div class="d-flex align-items-center">
                <a href="../MainPage.aspx?sub=menu4" class="nav-btn mr-2" title="返回主選單">
                    <i class="fas fa-home"></i>
                    <span class="d-none d-sm-inline">回首頁</span>
                </a>
                <a href="Clean_List.aspx" class="navbar-brand-title">
                    <i class="fas fa-broom text-white"></i>
                    <span>道路潔淨巡檢管理</span>
                    <span class="badge badge-light text-dark font-weight-bold ml-1">
                        {{ counts.Total }} 筆
                    </span>
                </a>
            </div>
            <div class="d-flex align-items-center gap-2">
                <a :href="'NewCleanChk.aspx?mode=new&listMode=' + currentMode" class="btn btn-success btn-sm font-weight-bold shadow-sm mr-2">
                    <i class="fas fa-plus-circle mr-1"></i>
                    <span class="d-none d-sm-inline">新增巡檢</span>
                </a>
            </div>
        </header>"""

# 替換清單卡片 Header: 大四元標準工具列
old_clean_header = """                <div class="card-modern-header">
                    <h2 class="card-modern-title">
                        <i class="fas fa-list-ul text-primary"></i>
                        <span>{{ getModeTitle() }}</span>
                        <span class="badge badge-pill badge-light border text-muted ml-2 font-weight-bold" style="font-size: 12px;">
                            共 {{ totalCount }} 筆紀錄
                        </span>
                    </h2>
                    <div>
                        <button type="button" class="btn btn-sm btn-light border font-weight-bold" v-on:click="loadList" title="重新整理">
                            <i class="fas fa-sync-alt" :class="{ 'fa-spin': loading }"></i>
                        </button>
                    </div>
                </div>"""

new_clean_header = """                <div class="card-modern-header">
                    <div class="d-flex align-items-center gap-2">
                        <h2 class="card-modern-title">
                            <i class="fas fa-list-alt text-primary"></i>
                            <span>{{ getModeTitle() }}</span>
                        </h2>
                        <span class="badge badge-light border text-dark font-weight-bold ml-1">
                            共 {{ totalCount }} 筆
                        </span>
                        <span class="badge badge-secondary ml-1 d-none d-sm-inline">
                            頁次 {{ currentPage }} / {{ totalPages }}
                        </span>
                    </div>
                    <div class="d-flex align-items-center">
                        <!-- 1. 重新整理 -->
                        <button type="button" class="btn btn-sm btn-outline-secondary mr-2" v-on:click="loadList" :disabled="loading" title="重新整理巡檢紀錄">
                            <i class="fas fa-sync-alt mr-1" :class="{ 'fa-spin': loading }"></i>
                            <span class="d-none d-md-inline">重新整理</span>
                        </button>

                        <!-- 2. 匯出 EXCEL -->
                        <button type="button" class="btn btn-sm btn-outline-success font-weight-bold mr-2" v-on:click="exportExcel" :disabled="exporting || totalCount === 0" title="匯出篩選結果為 EXCEL 報表">
                            <i class="fas fa-file-excel mr-1"></i>
                            <span class="d-none d-md-inline">{{ exporting ? '匯出中...' : '匯出 EXCEL' }}</span>
                        </button>

                        <!-- 3. 每頁筆數選擇器 -->
                        <div class="d-inline-flex align-items-center">
                            <span class="small text-muted mr-1 d-none d-lg-inline">每頁：</span>
                            <select class="form-control form-control-sm d-inline-block w-auto" v-model="pageSize" v-on:change="changePageSize">
                                <option :value="10">10 筆</option>
                                <option :value="15">15 筆</option>
                                <option :value="30">30 筆</option>
                                <option :value="50">50 筆</option>
                            </select>
                        </div>
                    </div>
                </div>"""

# 檢查 JS data() 與 methods
old_clean_data = """                return {
                    loading: false,"""

new_clean_data = """                return {
                    loading: false,
                    exporting: false,"""

old_clean_methods = """                // 3. 取得案件狀態徽章樣式"""

new_clean_methods = """                // 匯出 EXCEL 報表
                exportExcel() {
                    if (this.totalCount === 0) {
                        alert('目前無符合條件之巡檢紀錄可供匯出！');
                        return;
                    }
                    this.exporting = true;
                    const params = new URLSearchParams();
                    params.append('action', 'exportExcel');
                    params.append('mode', this.currentMode || 'apply');
                    params.append('town', this.filters.town || '');
                    params.append('roadName', this.filters.roadName || '');
                    params.append('chkId', this.filters.chkId || '');
                    params.append('chkDateS', this.filters.chkDateS || '');
                    params.append('chkDateE', this.filters.chkDateE || '');

                    axios.post('Clean_List.aspx', params, { responseType: 'blob' })
                        .then(res => {
                            const blob = new Blob([res.data], { type: 'application/vnd.ms-excel' });
                            const link = document.createElement('a');
                            link.href = window.URL.createObjectURL(blob);
                            const now = new Date();
                            const timeStr = now.getFullYear() + ('0' + (now.getMonth() + 1)).slice(-2) + ('0' + now.getDate()).slice(-2);
                            link.download = '道路潔淨巡檢清單_' + timeStr + '.xls';
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
                changePageSize() {
                    this.currentPage = 1;
                    this.loadList();
                },

                // 3. 取得案件狀態徽章樣式"""

norm_clean_aspx = clean_aspx.replace('\r\n', '\n')
norm_clean_aspx = norm_clean_aspx.replace(old_clean_nav.replace('\r\n', '\n'), new_clean_nav.replace('\r\n', '\n'))
norm_clean_aspx = norm_clean_aspx.replace(old_clean_header.replace('\r\n', '\n'), new_clean_header.replace('\r\n', '\n'))
norm_clean_aspx = norm_clean_aspx.replace(old_clean_data.replace('\r\n', '\n'), new_clean_data.replace('\r\n', '\n'))
norm_clean_aspx = norm_clean_aspx.replace(old_clean_methods.replace('\r\n', '\n'), new_clean_methods.replace('\r\n', '\n'))

with open(clean_aspx_path, 'w', encoding='utf-8-sig', newline='') as fp:
    fp.write(norm_clean_aspx.replace('\n', '\r\n'))

print('Clean_List.aspx successfully updated with standard UI components!')

# ==================== 4. 更新 RoadClean/Clean_List.aspx.cs ====================
clean_cs_path = r'd:\NTPC_FEC\RoadClean\Clean_List.aspx.cs'
with open(clean_cs_path, 'r', encoding='utf-8-sig') as fp:
    clean_cs = fp.read()

old_clean_cs_usings = """using NTPC_FEC.Helpers;"""
new_clean_cs_usings = """using NTPC_FEC.Helpers;
using NPOI.HSSF.UserModel;
using NPOI.SS.UserModel;"""

old_clean_cs_load = """        protected void Page_Load(object sender, EventArgs e)
        {
            string action = Request["action"];
            if (!string.IsNullOrEmpty(action))
            {
                Response.Clear();"""

new_clean_cs_load = """        protected void Page_Load(object sender, EventArgs e)
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

export_clean_cs_code = """
        #region 匯出 Excel 報表
        private void HandleExportExcel()
        {
            try
            {
                string mode = Request["mode"] != null ? Request["mode"].Trim().ToLower() : "apply";
                string town = Request["town"] != null ? Request["town"].Trim() : "";
                string roadName = Request["roadName"] != null ? Request["roadName"].Trim() : "";
                string chkId = Request["chkId"] != null ? Request["chkId"].Trim() : "";
                string chkDateS = Request["chkDateS"] != null ? Request["chkDateS"].Trim() : "";
                string chkDateE = Request["chkDateE"] != null ? Request["chkDateE"].Trim() : "";

                StringBuilder sb = new StringBuilder();
                sb.Append("SELECT c.ChkId, c.Town, c.RoadName, c.ChkDate, c.RoadLevel, c.FloodLevel, c.CState, c.CreateUser, c.Score ");
                sb.Append("FROM RoadClean_Main c WHERE 1=1 ");

                List<SqlParameter> pList = new List<SqlParameter>();

                if (mode == "apply")
                {
                    sb.Append(" AND (c.CState = 'A00' OR c.CState IS NULL) ");
                }
                else if (mode == "examine")
                {
                    sb.Append(" AND c.CState = 'A01' ");
                }
                else if (mode == "back")
                {
                    sb.Append(" AND c.CState = 'A00b' ");
                }
                else if (mode == "search")
                {
                    sb.Append(" AND c.CState = 'A02' ");
                }

                if (!string.IsNullOrEmpty(town))
                {
                    sb.Append(" AND c.Town = @Town ");
                    pList.Add(new SqlParameter("@Town", town));
                }
                if (!string.IsNullOrEmpty(roadName))
                {
                    sb.Append(" AND c.RoadName LIKE @RoadName ");
                    pList.Add(new SqlParameter("@RoadName", "%" + roadName + "%"));
                }
                if (!string.IsNullOrEmpty(chkId))
                {
                    sb.Append(" AND c.ChkId LIKE @ChkId ");
                    pList.Add(new SqlParameter("@ChkId", "%" + chkId + "%"));
                }
                DateTime dtS;
                if (DateTime.TryParse(chkDateS, out dtS))
                {
                    sb.Append(" AND c.ChkDate >= @DateS ");
                    pList.Add(new SqlParameter("@DateS", dtS));
                }
                DateTime dtE;
                if (DateTime.TryParse(chkDateE, out dtE))
                {
                    sb.Append(" AND c.ChkDate <= @DateE ");
                    pList.Add(new SqlParameter("@DateE", dtE.AddDays(1).AddSeconds(-1)));
                }

                sb.Append(" ORDER BY c.ChkDate DESC, c.ChkId DESC");

                DataTable dt = DbHelper.ExecuteDataTable(sb.ToString(), pList.ToArray());

                HSSFWorkbook workbook = new HSSFWorkbook();
                ISheet sheet = workbook.CreateSheet("道路潔淨巡檢清單");

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
                    "序號", "巡檢案號", "行政區", "巡檢道路名稱", "巡檢日期",
                    "道路評級", "淹水評級", "案件階段", "填報人員", "總分"
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
                        string chkIdVal = dr["ChkId"] != DBNull.Value ? dr["ChkId"].ToString().Trim() : "";
                        string townVal = dr["Town"] != DBNull.Value ? dr["Town"].ToString().Trim() : "";
                        string roadVal = dr["RoadName"] != DBNull.Value ? dr["RoadName"].ToString().Trim() : "";
                        string dateVal = dr["ChkDate"] != DBNull.Value ? string.Format("{0:yyyy-MM-dd}", dr["ChkDate"]) : "";
                        string rLvl = dr["RoadLevel"] != DBNull.Value ? dr["RoadLevel"].ToString().Trim() : "";
                        string fLvl = dr["FloodLevel"] != DBNull.Value ? dr["FloodLevel"].ToString().Trim() : "";
                        string stateVal = dr["CState"] != DBNull.Value ? dr["CState"].ToString().Trim() : "";
                        string userVal = dr["CreateUser"] != DBNull.Value ? dr["CreateUser"].ToString().Trim() : "";
                        string scoreVal = dr["Score"] != DBNull.Value ? dr["Score"].ToString().Trim() : "";

                        string[] vals = new string[]
                        {
                            seq, chkIdVal, townVal, roadVal, dateVal,
                            rLvl, fLvl, stateVal, userVal, scoreVal
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
                sheet.SetColumnWidth(3, 30 * 256); // 道路名稱放寬

                Response.Clear();
                Response.ContentType = "application/vnd.ms-excel";
                string filename = "道路潔淨巡檢清單_" + DateTime.Now.ToString("yyyyMMddHHmmss") + ".xls";
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

norm_clean_cs = clean_cs.replace('\r\n', '\n')
norm_clean_cs = norm_clean_cs.replace(old_clean_cs_usings.replace('\r\n', '\n'), new_clean_cs_usings.replace('\r\n', '\n'))
norm_clean_cs = norm_clean_cs.replace(old_clean_cs_load.replace('\r\n', '\n'), new_clean_cs_load.replace('\r\n', '\n'))

pos_clean_end = norm_clean_cs.rfind('}')
pos_clean_class_end = norm_clean_cs.rfind('}', 0, pos_clean_end)
norm_clean_cs = norm_clean_cs[:pos_clean_class_end] + export_clean_cs_code + '\n' + norm_clean_cs[pos_clean_class_end:]

with open(clean_cs_path, 'w', encoding='utf-8-sig', newline='') as fp:
    fp.write(norm_clean_cs.replace('\n', '\r\n'))

print('Clean_List.aspx.cs successfully updated with exportExcel!')
