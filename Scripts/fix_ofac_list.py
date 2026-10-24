# -*- coding: utf-8 -*-
import os, sys

file_path = r'd:\NTPC_FEC\FAC\oFAC_List.aspx'
with open(file_path, 'r', encoding='utf-8-sig') as fp:
    content = fp.read()

# 1. 替換頂部 Navbar
old_nav = """        <!-- 頂部品牌導覽列 -->
        <header class="top-navbar">
            <a href="oFAC_List.aspx" class="navbar-brand-title">
                <i class="fas fa-industry text-white"></i>
                <span>固定污染源許可證管理</span>
            </a>
            <div class="d-flex align-items-center gap-2">
                <a href="../MainPage.aspx" class="nav-btn mr-2">
                    <i class="fas fa-home"></i>
                    <span class="d-none d-sm-inline">返回主頁</span>
                </a>
                <button type="button" class="nav-btn bg-white text-dark shadow-sm" v-on:click="openAddModal">
                    <i class="fas fa-plus text-primary"></i>
                    <span>新增列管製程</span>
                </button>
            </div>
        </header>"""

new_nav = """        <!-- 頂部品牌導覽列 (全站標準左側導航、右側主操作) -->
        <header class="top-navbar">
            <div class="d-flex align-items-center">
                <a href="../MainPage.aspx" class="nav-btn mr-2" title="返回主選單">
                    <i class="fas fa-home"></i>
                    <span class="d-none d-sm-inline">回首頁</span>
                </a>
                <a href="oFAC_List.aspx" class="navbar-brand-title">
                    <i class="fas fa-industry text-white"></i>
                    <span>固定污染源許可證管理</span>
                    <span class="badge badge-light text-dark font-weight-bold ml-1">
                        {{ counts.Total }} 筆
                    </span>
                </a>
            </div>
            <div class="d-flex align-items-center gap-2">
                <button type="button" class="btn btn-success btn-sm font-weight-bold shadow-sm mr-2" v-on:click="openAddModal">
                    <i class="fas fa-plus-circle mr-1"></i>
                    <span class="d-none d-sm-inline">新增列管製程</span>
                </button>
            </div>
        </header>"""

# 2. 替換篩選面板底部動作區
old_filter_footer = """                    <!-- 按鈕動作區 -->
                    <div class="d-flex justify-content-between align-items-center mt-2 flex-wrap gap-2">
                        <div class="d-flex gap-2">
                            <button type="button" class="btn btn-primary btn-sm px-3" v-on:click="searchData">
                                <i class="fas fa-search mr-1"></i>搜尋資料
                            </button>
                            <button type="button" class="btn btn-outline-secondary btn-sm px-3" v-on:click="resetFilter">
                                <i class="fas fa-undo mr-1"></i>清除重設
                            </button>
                        </div>
                        <div>
                            <button type="button" class="btn btn-outline-success btn-sm px-3" v-on:click="exportExcel">
                                <i class="fas fa-file-excel mr-1"></i>匯出 Excel 報表
                            </button>
                        </div>
                    </div>"""

new_filter_footer = """                    <!-- 底部操作列 (全站標準格式：左側筆數統計、右側重設與查詢) -->
                    <div class="d-flex justify-content-between align-items-center mt-2 pt-2 border-top">
                        <div class="small text-muted">
                            共查詢到 <strong class="text-primary">{{ totalCount }}</strong> 筆製程許可證
                        </div>
                        <div>
                            <button type="button" class="btn btn-outline-secondary btn-sm mr-2" v-on:click="resetFilter">
                                <i class="fas fa-undo mr-1"></i> 重設條件
                            </button>
                            <button type="button" class="btn btn-primary btn-sm px-3" v-on:click="searchData">
                                <i class="fas fa-search mr-1"></i> 立即查詢
                            </button>
                        </div>
                    </div>"""

# 3. 替換清單卡片 Header (大四元標準工具列)
old_list_header = """            <!-- 清單列表卡片 -->
            <div class="card-modern">
                <div class="card-modern-header">
                    <h2 class="card-modern-title">
                        <i class="fas fa-file-alt text-primary"></i>
                        <span>{{ getModeTitle() }}</span>
                        <span class="badge badge-light border text-muted ml-2 font-weight-normal" style="font-size: 13px;">
                            共 {{ totalCount }} 筆製程資料
                        </span>
                    </h2>
                    <div class="d-flex align-items-center gap-2">
                        <button type="button" class="btn btn-sm btn-light border" v-on:click="loadData" title="重新整理">
                            <i class="fas fa-sync-alt" :class="{ 'fa-spin': loading }"></i>
                        </button>
                    </div>
                </div>"""

new_list_header = """            <!-- 清單列表卡片 (標準大四元操作工具列) -->
            <div class="card-modern">
                <div class="card-modern-header">
                    <div class="d-flex align-items-center gap-2">
                        <h2 class="card-modern-title">
                            <i class="fas fa-list-alt text-primary"></i>
                            <span>{{ getModeTitle() }}</span>
                        </h2>
                        <span class="badge badge-light border text-dark font-weight-bold ml-1">
                            共 {{ totalCount }} 筆
                        </span>
                        <span class="badge badge-secondary ml-1 d-none d-sm-inline">
                            頁次 {{ pageIndex }} / {{ totalPages }}
                        </span>
                    </div>

                    <div class="d-flex align-items-center">
                        <!-- 1. 重新整理 -->
                        <button type="button" class="btn btn-sm btn-outline-secondary mr-2" v-on:click="loadData" :disabled="loading" title="重新整理列表">
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

# 4. JS data 增加 exporting
old_js_data = """                return {
                    loading: false,"""
new_js_data = """                return {
                    loading: false,
                    exporting: false,"""

# 5. JS computed 增加 totalPages
old_js_comp = """            computed: {
                totalPages() {"""
# 若已有 totalPages 則不重複新增

# 6. JS methods 增加 changePageSize
old_js_methods = """                searchData() {"""
new_js_methods = """                changePageSize() {
                    this.pageIndex = 1;
                    this.loadData();
                },
                searchData() {"""

norm_c = content.replace('\r\n', '\n')
norm_c = norm_c.replace(old_nav.replace('\r\n', '\n'), new_nav.replace('\r\n', '\n'))
norm_c = norm_c.replace(old_filter_footer.replace('\r\n', '\n'), new_filter_footer.replace('\r\n', '\n'))
norm_c = norm_c.replace(old_list_header.replace('\r\n', '\n'), new_list_header.replace('\r\n', '\n'))
norm_c = norm_c.replace(old_js_data.replace('\r\n', '\n'), new_js_data.replace('\r\n', '\n'))
norm_c = norm_c.replace(old_js_methods.replace('\r\n', '\n'), new_js_methods.replace('\r\n', '\n'))

with open(file_path, 'w', encoding='utf-8-sig', newline='') as fp:
    fp.write(norm_c.replace('\n', '\r\n'))

print('oFAC_List.aspx successfully standardized!')
