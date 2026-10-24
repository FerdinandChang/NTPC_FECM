# -*- coding: utf-8 -*-
import os, sys

aspx_path = r'd:\NTPC_FEC\BareGround\Bare_List.aspx'
cs_path = r'd:\NTPC_FEC\BareGround\Bare_List.aspx.cs'

# ==================== 1. 更新 Bare_List.aspx ====================
with open(aspx_path, 'r', encoding='utf-8-sig') as fp:
    aspx_content = fp.read()

# 替換頂部 Navbar
old_nav = """        <!-- 頂部品牌導覽列 -->
        <header class="top-navbar">
            <a href="Bare_List.aspx" class="navbar-brand-title">
                <i class="fas fa-mountain text-warning"></i>
                <span>新北市固定溢散源 - 裸露地調查管理</span>
            </a>
            <div class="d-flex align-items-center gap-2">
                <a href="NewBare.aspx?mode=new" class="btn btn-warning font-weight-bold text-dark px-3 shadow-sm mr-2" style="border-radius: 8px;">
                    <i class="fas fa-plus-circle"></i>
                    <span class="d-none d-sm-inline ml-1">新增調查</span>
                </a>
                <a href="../MainPage.aspx" class="btn btn-outline-light font-weight-bold px-3" style="border-radius: 8px;">
                    <i class="fas fa-home"></i>
                    <span class="d-none d-sm-inline ml-1">回首頁</span>
                </a>
            </div>
        </header>"""

new_nav = """        <!-- 頂部品牌導覽列 (全站統一標準：左側導航、右側主操作) -->
        <header class="top-navbar">
            <div class="d-flex align-items-center">
                <a href="../MainPage.aspx" class="nav-btn mr-2" title="返回主選單">
                    <i class="fas fa-home"></i>
                    <span class="d-none d-sm-inline">回首頁</span>
                </a>
                <a href="Bare_List.aspx" class="navbar-brand-title">
                    <i class="fas fa-mountain text-warning"></i>
                    <span>裸露地調查管理</span>
                    <span class="badge badge-light text-dark font-weight-bold ml-1">
                        {{ counts.Sites }} 處場址
                    </span>
                </a>
            </div>
            <div class="d-flex align-items-center gap-2">
                <a href="NewBare.aspx?mode=new" class="btn btn-success btn-sm font-weight-bold shadow-sm mr-2">
                    <i class="fas fa-plus-circle mr-1"></i>
                    <span class="d-none d-sm-inline">新增調查</span>
                </a>
                <button type="button" class="nav-btn" v-on:click="toggleMap" :title="showMap ? '收合地圖' : '展開地圖'">
                    <i class="fas" :class="showMap ? 'fa-compress-arrows-alt' : 'fa-map-marked-alt'"></i>
                    <span class="d-none d-lg-inline">{{ showMap ? '收合地圖' : '展開地圖' }}</span>
                </button>
            </div>
        </header>"""

# 替換篩選卡片
old_filter = """            <!-- 查詢篩選卡片 -->
            <div class="card-modern">
                <div class="card-modern-header">
                    <h2 class="card-modern-title">
                        <i class="fas fa-filter text-primary"></i>
                        <span>場址與查核條件篩選</span>
                    </h2>
                    <div class="d-flex align-items-center gap-2">
                        <button type="button" class="btn btn-sm btn-outline-info font-weight-bold mr-2" v-on:click="toggleMap">
                            <i class="fas fa-map-marked-alt mr-1"></i>
                            <span>{{ showMap ? '收合地圖' : '展開地圖' }}</span>
                        </button>
                        <button type="button" class="btn btn-sm btn-outline-secondary font-weight-bold" v-on:click="resetFilter">
                            <i class="fas fa-redo-alt mr-1"></i> 重設條件
                        </button>
                    </div>
                </div>
                <div class="card-modern-body">
                    <div class="row">
                        <!-- 編號關鍵字 -->
                        <div class="col-12 col-md-3 mb-3">
                            <label class="font-weight-bold text-muted small mb-1">
                                <i class="fas fa-hashtag text-secondary mr-1"></i> 裸露地編號
                            </label>
                            <input type="text" class="form-control" v-model="filter.bareGroundNo" placeholder="請輸入編號關鍵字..." v-on:keyup.enter="handleSearch" />
                        </div>

                        <!-- 地址關鍵字 -->
                        <div class="col-12 col-md-3 mb-3">
                            <label class="font-weight-bold text-muted small mb-1">
                                <i class="fas fa-map-pin text-danger mr-1"></i> 場址地址
                            </label>
                            <input type="text" class="form-control" v-model="filter.addr" placeholder="請輸入地址關鍵字..." v-on:keyup.enter="handleSearch" />
                        </div>

                        <!-- 地目 -->
                        <div class="col-12 col-md-2 mb-3">
                            <label class="font-weight-bold text-muted small mb-1">
                                <i class="fas fa-layer-group text-warning mr-1"></i> 地目
                            </label>
                            <input type="text" class="form-control" v-model="filter.landUse" placeholder="例如：林、田、建..." v-on:keyup.enter="handleSearch" />
                        </div>

                        <!-- 查核日期區間 -->
                        <div class="col-12 col-md-4 mb-3">
                            <label class="font-weight-bold text-muted small mb-1">
                                <i class="far fa-calendar-alt text-info mr-1"></i> 最近查核日期區間
                            </label>
                            <div class="d-flex align-items-center gap-2">
                                <input type="date" class="form-control" v-model="filter.dateS" />
                                <span class="text-muted px-1">至</span>
                                <input type="date" class="form-control" v-model="filter.dateE" />
                            </div>
                        </div>
                    </div>

                    <div class="d-flex justify-content-end align-items-center mt-2">
                        <button type="button" class="btn btn-primary font-weight-bold px-4 shadow-sm" v-on:click="handleSearch">
                            <i class="fas fa-search mr-1"></i> 開始查詢
                        </button>
                    </div>
                </div>
            </div>"""

new_filter = """            <!-- 複合多條件篩選卡片 (標準折疊與操作列) -->
            <div class="card-modern">
                <div class="card-modern-header" style="cursor: pointer;" v-on:click="filterCollapsed = !filterCollapsed">
                    <h2 class="card-modern-title">
                        <i class="fas fa-filter text-primary"></i>
                        <span>場址與查核條件篩選</span>
                        <small class="text-muted font-weight-normal ml-2" v-if="hasActiveFilter">
                            (已套用自訂篩選)
                        </small>
                    </h2>
                    <button type="button" class="btn btn-link btn-sm text-muted p-0">
                        <i class="fas" :class="filterCollapsed ? 'fa-chevron-down' : 'fa-chevron-up'"></i>
                    </button>
                </div>
                <div class="card-modern-body" v-show="!filterCollapsed">
                    <div class="row">
                        <!-- 編號關鍵字 -->
                        <div class="col-12 col-md-3 mb-2">
                            <label class="font-weight-bold text-muted small mb-1">裸露地編號</label>
                            <input type="text" class="form-control form-control-sm" v-model="filter.bareGroundNo" placeholder="請輸入編號關鍵字..." v-on:keyup.enter="handleSearch" />
                        </div>

                        <!-- 地址關鍵字 -->
                        <div class="col-12 col-md-3 mb-2">
                            <label class="font-weight-bold text-muted small mb-1">場址地址</label>
                            <input type="text" class="form-control form-control-sm" v-model="filter.addr" placeholder="請輸入地址關鍵字..." v-on:keyup.enter="handleSearch" />
                        </div>

                        <!-- 地目 -->
                        <div class="col-12 col-md-2 mb-2">
                            <label class="font-weight-bold text-muted small mb-1">地目</label>
                            <input type="text" class="form-control form-control-sm" v-model="filter.landUse" placeholder="例如：林、田、建..." v-on:keyup.enter="handleSearch" />
                        </div>

                        <!-- 查核日期區間 -->
                        <div class="col-12 col-md-4 mb-2">
                            <label class="font-weight-bold text-muted small mb-1">最近查核日期區間</label>
                            <div class="d-flex align-items-center gap-2">
                                <input type="date" class="form-control form-control-sm" v-model="filter.dateS" />
                                <span class="text-muted px-1">至</span>
                                <input type="date" class="form-control form-control-sm" v-model="filter.dateE" />
                            </div>
                        </div>
                    </div>

                    <div class="d-flex justify-content-between align-items-center mt-2 pt-2 border-top">
                        <div class="small text-muted">
                            共查詢到 <strong class="text-primary">{{ pagination.totalCount }}</strong> 筆場址資料
                        </div>
                        <div>
                            <button type="button" class="btn btn-outline-secondary btn-sm mr-2" v-on:click="resetFilter">
                                <i class="fas fa-undo mr-1"></i> 重設條件
                            </button>
                            <button type="button" class="btn btn-primary btn-sm px-3" v-on:click="handleSearch">
                                <i class="fas fa-search mr-1"></i> 立即查詢
                            </button>
                        </div>
                    </div>
                </div>
            </div>"""

# 替換清單卡片 Header
old_list_header = """            <!-- 裸露地主清單卡片 -->
            <div class="card-modern">
                <div class="card-modern-header">
                    <div class="d-flex align-items-center gap-3">
                        <h2 class="card-modern-title">
                            <i class="fas fa-list text-primary"></i>
                            <span>{{ getModeTitle() }}</span>
                        </h2>
                        <span class="badge badge-light border text-muted px-2 py-1 font-weight-bold">
                            共 {{ pagination.totalCount }} 筆
                        </span>
                    </div>

                    <div class="d-flex align-items-center gap-2">
                        <button type="button" class="btn btn-sm btn-outline-secondary" v-on:click="fetchList">
                            <i class="fas fa-sync-alt" :class="{ 'fa-spin': loading }"></i>
                            <span class="d-none d-md-inline ml-1">重新整理</span>
                        </button>
                    </div>
                </div>"""

new_list_header = """            <!-- 裸露地主清單卡片 (標準清單大四元操作工具列) -->
            <div class="card-modern">
                <div class="card-modern-header">
                    <div class="d-flex align-items-center gap-2">
                        <h2 class="card-modern-title">
                            <i class="fas fa-list-alt text-primary"></i>
                            <span>{{ getModeTitle() }}</span>
                        </h2>
                        <span class="badge badge-light border text-dark font-weight-bold ml-1">
                            共 {{ pagination.totalCount }} 筆
                        </span>
                        <span class="badge badge-secondary ml-1 d-none d-sm-inline">
                            頁次 {{ pagination.pageIndex }} / {{ totalPages }}
                        </span>
                    </div>

                    <div class="d-flex align-items-center">
                        <!-- 1. 重新整理 -->
                        <button type="button" class="btn btn-sm btn-outline-secondary mr-2" v-on:click="fetchList" :disabled="loading" title="重新整理資料">
                            <i class="fas fa-sync-alt mr-1" :class="{ 'fa-spin': loading }"></i>
                            <span class="d-none d-md-inline">重新整理</span>
                        </button>

                        <!-- 2. 匯出 EXCEL -->
                        <button type="button" class="btn btn-sm btn-outline-success font-weight-bold mr-2" v-on:click="exportExcel" :disabled="exporting || pagination.totalCount === 0" title="匯出篩選結果為 EXCEL 報表">
                            <i class="fas fa-file-excel mr-1"></i>
                            <span class="d-none d-md-inline">{{ exporting ? '匯出中...' : '匯出 EXCEL' }}</span>
                        </button>

                        <!-- 3. 每頁筆數選擇器 -->
                        <div class="d-inline-flex align-items-center">
                            <span class="small text-muted mr-1 d-none d-lg-inline">每頁：</span>
                            <select class="form-control form-control-sm d-inline-block w-auto" v-model="pagination.pageSize" v-on:change="changePageSize">
                                <option :value="10">10 筆</option>
                                <option :value="15">15 筆</option>
                                <option :value="30">30 筆</option>
                                <option :value="50">50 筆</option>
                            </select>
                        </div>
                    </div>
                </div>"""

# 檢查 JS data() 和 methods
old_js_data = """                return {
                    loading: false,"""

new_js_data = """                return {
                    loading: false,
                    exporting: false,
                    filterCollapsed: false,"""

old_js_computed = """            computed: {
                // 分頁頁碼陣列計算"""

new_js_computed = """            computed: {
                totalPages() {
                    return Math.max(1, Math.ceil(this.pagination.totalCount / this.pagination.pageSize));
                },
                hasActiveFilter() {
                    return this.filter.bareGroundNo || this.filter.addr || this.filter.landUse || this.filter.dateS || this.filter.dateE;
                },
                // 分頁頁碼陣列計算"""

old_js_methods = """                // 3. 切換業務模式"""

new_js_methods = """                // 匯出 EXCEL 報表
                exportExcel() {
                    if (this.pagination.totalCount === 0) {
                        alert('目前無符合條件之場址資料可供匯出！');
                        return;
                    }
                    this.exporting = true;
                    const params = new URLSearchParams();
                    params.append('action', 'exportExcel');
                    params.append('mode', this.currentMode || 'all');
                    params.append('bareGroundNo', this.filter.bareGroundNo || '');
                    params.append('addr', this.filter.addr || '');
                    params.append('landUse', this.filter.landUse || '');
                    params.append('dateS', this.filter.dateS || '');
                    params.append('dateE', this.filter.dateE || '');

                    axios.post('Bare_List.aspx', params, { responseType: 'blob' })
                        .then(res => {
                            const blob = new Blob([res.data], { type: 'application/vnd.ms-excel' });
                            const link = document.createElement('a');
                            link.href = window.URL.createObjectURL(blob);
                            const now = new Date();
                            const timeStr = now.getFullYear() + ('0' + (now.getMonth() + 1)).slice(-2) + ('0' + now.getDate()).slice(-2);
                            link.download = '裸露地清單匯出_' + timeStr + '.xls';
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
                    this.pagination.pageIndex = 1;
                    this.fetchList();
                },

                // 3. 切換業務模式"""

norm_aspx = aspx_content.replace('\r\n', '\n')
norm_aspx = norm_aspx.replace(old_nav.replace('\r\n', '\n'), new_nav.replace('\r\n', '\n'))
norm_aspx = norm_aspx.replace(old_filter.replace('\r\n', '\n'), new_filter.replace('\r\n', '\n'))
norm_aspx = norm_aspx.replace(old_list_header.replace('\r\n', '\n'), new_list_header.replace('\r\n', '\n'))
norm_aspx = norm_aspx.replace(old_js_data.replace('\r\n', '\n'), new_js_data.replace('\r\n', '\n'))
norm_aspx = norm_aspx.replace(old_js_computed.replace('\r\n', '\n'), new_js_computed.replace('\r\n', '\n'))
norm_aspx = norm_aspx.replace(old_js_methods.replace('\r\n', '\n'), new_js_methods.replace('\r\n', '\n'))

with open(aspx_path, 'w', encoding='utf-8-sig', newline='') as fp:
    fp.write(norm_aspx.replace('\n', '\r\n'))

print('Bare_List.aspx successfully updated with standard components!')

# ==================== 2. 更新 Bare_List.aspx.cs ====================
with open(cs_path, 'r', encoding='utf-8-sig') as fp:
    cs_content = fp.read()

# 補充 NPOI using
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
                string mode = Request["mode"] != null ? Request["mode"].Trim().ToLower() : "all";
                string bareNo = Request["bareGroundNo"] != null ? Request["bareGroundNo"].Trim() : "";
                string addr = Request["addr"] != null ? Request["addr"].Trim() : "";
                string landUse = Request["landUse"] != null ? Request["landUse"].Trim() : "";
                string dateS = Request["dateS"] != null ? Request["dateS"].Trim() : "";
                string dateE = Request["dateE"] != null ? Request["dateE"].Trim() : "";

                StringBuilder sb = new StringBuilder();
                sb.Append("SELECT bi.INV_NO, bi.BareGround_NO, bi.INV_State, bi.INV_Date, bi.INV_Unit, bi.TOWN, bi.ADDR, bi.Land_Use, bm.BareGround_Type, bm.Lat, bm.Lng ");
                sb.Append("FROM Bare_INV bi LEFT JOIN Bare_Main bm ON bi.BareGround_NO = bm.BareGround_NO ");
                sb.Append("WHERE bi.INV_State != 'Z00' ");

                List<SqlParameter> pList = new List<SqlParameter>();

                if (mode == "reject")
                {
                    sb.Append(" AND bi.INV_State = 'A00a' ");
                }
                else if (mode == "back")
                {
                    sb.Append(" AND bi.INV_State = 'A00b' ");
                }
                else if (mode == "examine")
                {
                    sb.Append(" AND bi.INV_State IN ('A00', 'A01', 'A02') ");
                }
                else if (mode == "identify" || mode == "search")
                {
                    sb.Append(" AND bi.INV_State NOT IN ('A00a', 'A00b', 'Z00', 'A00', 'A01', 'A02') ");
                }

                if (!string.IsNullOrEmpty(bareNo))
                {
                    sb.Append(" AND bi.BareGround_NO LIKE @BareNo ");
                    pList.Add(new SqlParameter("@BareNo", "%" + bareNo + "%"));
                }
                if (!string.IsNullOrEmpty(addr))
                {
                    sb.Append(" AND bi.ADDR LIKE @Addr ");
                    pList.Add(new SqlParameter("@Addr", "%" + addr + "%"));
                }
                if (!string.IsNullOrEmpty(landUse))
                {
                    sb.Append(" AND bi.Land_Use LIKE @LandUse ");
                    pList.Add(new SqlParameter("@LandUse", "%" + landUse + "%"));
                }
                DateTime dtS;
                if (DateTime.TryParse(dateS, out dtS))
                {
                    sb.Append(" AND bi.INV_Date >= @DateS ");
                    pList.Add(new SqlParameter("@DateS", dtS));
                }
                DateTime dtE;
                if (DateTime.TryParse(dateE, out dtE))
                {
                    sb.Append(" AND bi.INV_Date <= @DateE ");
                    pList.Add(new SqlParameter("@DateE", dtE.AddDays(1).AddSeconds(-1)));
                }

                sb.Append(" ORDER BY bi.INV_Date DESC, bi.INV_NO DESC");

                DataTable dt = DbHelper.ExecuteDataTable(sb.ToString(), pList.ToArray());

                HSSFWorkbook workbook = new HSSFWorkbook();
                ISheet sheet = workbook.CreateSheet("裸露地查核清單");

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
                    "序號", "查核案號", "裸露地編號", "案件狀態", "查核日期",
                    "查核單位", "行政區", "場址地址", "地目", "類型", "緯度 (Lat)", "經度 (Lng)"
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
                        string invNo = dr["INV_NO"] != DBNull.Value ? dr["INV_NO"].ToString().Trim() : "";
                        string bareNoVal = dr["BareGround_NO"] != DBNull.Value ? dr["BareGround_NO"].ToString().Trim() : "";
                        string stateVal = dr["INV_State"] != DBNull.Value ? dr["INV_State"].ToString().Trim() : "";
                        string dateVal = dr["INV_Date"] != DBNull.Value ? string.Format("{0:yyyy-MM-dd}", dr["INV_Date"]) : "";
                        string unitVal = dr["INV_Unit"] != DBNull.Value ? dr["INV_Unit"].ToString().Trim() : "";
                        string townVal = dr["TOWN"] != DBNull.Value ? dr["TOWN"].ToString().Trim() : "";
                        string addrVal = dr["ADDR"] != DBNull.Value ? dr["ADDR"].ToString().Trim() : "";
                        string landVal = dr["Land_Use"] != DBNull.Value ? dr["Land_Use"].ToString().Trim() : "";
                        string typeVal = dr["BareGround_Type"] != DBNull.Value ? dr["BareGround_Type"].ToString().Trim() : "";
                        string latVal = dr["Lat"] != DBNull.Value ? dr["Lat"].ToString().Trim() : "";
                        string lngVal = dr["Lng"] != DBNull.Value ? dr["Lng"].ToString().Trim() : "";

                        string[] vals = new string[]
                        {
                            seq, invNo, bareNoVal, stateVal, dateVal,
                            unitVal, townVal, addrVal, landVal, typeVal, latVal, lngVal
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
                sheet.SetColumnWidth(7, 34 * 256); // 地址

                Response.Clear();
                Response.ContentType = "application/vnd.ms-excel";
                string filename = "裸露地清單_" + DateTime.Now.ToString("yyyyMMddHHmmss") + ".xls";
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

norm_cs = cs_content.replace('\r\n', '\n')
norm_cs = norm_cs.replace(old_cs_usings.replace('\r\n', '\n'), new_cs_usings.replace('\r\n', '\n'))
norm_cs = norm_cs.replace(old_cs_load.replace('\r\n', '\n'), new_cs_load.replace('\r\n', '\n'))

# 找到 class 的倒數第二個 } 前面插入
pos_end = norm_cs.rfind('}')
pos_class_end = norm_cs.rfind('}', 0, pos_end)
norm_cs = norm_cs[:pos_class_end] + export_cs_code + '\n' + norm_cs[pos_class_end:]

with open(cs_path, 'w', encoding='utf-8-sig', newline='') as fp:
    fp.write(norm_cs.replace('\n', '\r\n'))

print('Bare_List.aspx.cs successfully updated with exportExcel!')
