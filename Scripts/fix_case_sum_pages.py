# -*- coding: utf-8 -*-
import os, sys

sum_path = r'd:\NTPC_FEC\Case\Case_Sum.aspx'
sum1_path = r'd:\NTPC_FEC\Case\Case_Sum_1.aspx'

# ==================== 1. 更新 Case/Case_Sum.aspx ====================
with open(sum_path, 'r', encoding='utf-8-sig') as fp:
    sum_txt = fp.read()

# 替換 Navbar: 左側標準回首頁 + 徽章
old_sum_nav = """        <!-- 頂部品牌導覽列 -->
        <header class="top-navbar no-print">
            <div class="d-flex align-items-center">
                <a href="../MainPage.aspx" class="nav-btn mr-3" title="返回系統主選單">
                    <i class="fas fa-chevron-left"></i>
                    <span class="d-none d-sm-inline">返回主選單</span>
                </a>
                <div class="navbar-brand-title">
                    <i class="fas fa-building text-white"></i>
                    <span>公私場所巡查案件統計</span>
                    <span class="badge badge-light text-primary d-none d-md-inline" style="font-size: 0.8rem;">固定溢散源</span>
                </div>
            </div>

            <div class="d-flex align-items-center gap-2">
                <button type="button" class="nav-btn" v-on:click="doSearch" :disabled="loading" title="重新查詢">
                    <i class="fas fa-sync-alt" :class="{ 'fa-spin': loading }"></i>
                    <span class="d-none d-md-inline">重新查詢</span>
                </button>
                <button type="button" class="nav-btn bg-white text-dark shadow-sm ml-2" v-on:click="exportExcel" :disabled="loading || totalRecords === 0" title="匯出 Excel 報表">
                    <i class="fas fa-file-excel text-success"></i>
                    <span class="d-none d-md-inline">匯出 Excel</span>
                </button>
            </div>
        </header>"""

new_sum_nav = """        <!-- 頂部品牌導覽列 (全站標準左側導航、右側輔助操作) -->
        <header class="top-navbar no-print">
            <div class="d-flex align-items-center">
                <a href="../MainPage.aspx" class="nav-btn mr-2" title="返回主選單">
                    <i class="fas fa-home"></i>
                    <span class="d-none d-sm-inline">回首頁</span>
                </a>
                <a href="Case_Sum.aspx" class="navbar-brand-title">
                    <i class="fas fa-chart-pie text-white"></i>
                    <span>公私場所巡查案件統計</span>
                    <span class="badge badge-light text-dark font-weight-bold ml-1">
                        {{ formatNumber(totalRecords) }} 筆案件
                    </span>
                </a>
            </div>

            <div class="d-flex align-items-center gap-2">
                <a href="../FAC/FAC_List.aspx" class="btn btn-outline-light btn-sm font-weight-bold">
                    <i class="fas fa-industry mr-1"></i>場所資料庫
                </a>
            </div>
        </header>"""

# 替換篩選卡片底部操作列
old_sum_filter_foot = """                    <!-- 搜尋動作列 -->
                    <div class="d-flex align-items-center justify-content-end gap-2">
                        <button type="button" class="btn btn-primary px-4 py-2 font-weight-bold shadow-sm" v-on:click="doSearch" :disabled="loading">
                            <i class="fas fa-search mr-1"></i> 立即查詢
                        </button>
                        <button type="button" class="btn btn-light border px-3 py-2 font-weight-bold text-secondary ml-2" v-on:click="resetFilters">
                            <i class="fas fa-redo mr-1"></i> 重設
                        </button>
                    </div>"""

new_sum_filter_foot = """                    <!-- 底部標準操作列 (左側統計、右側重設與查詢) -->
                    <div class="d-flex justify-content-between align-items-center mt-3 pt-3 border-top">
                        <div class="small text-muted">
                            共查詢到 <strong class="text-primary">{{ formatNumber(totalRecords) }}</strong> 筆巡查案件 (涵蓋 {{ totalFacs }} 家場所)
                        </div>
                        <div>
                            <button type="button" class="btn btn-outline-secondary btn-sm mr-2" v-on:click="resetFilters">
                                <i class="fas fa-undo mr-1"></i> 重設條件
                            </button>
                            <button type="button" class="btn btn-primary btn-sm px-4 font-weight-bold" v-on:click="doSearch" :disabled="loading">
                                <i class="fas fa-search mr-1"></i> 立即查詢
                            </button>
                        </div>
                    </div>"""

# 替換清單卡片 Header (大四元標準操作工具列)
old_sum_list_h = """            <!-- 3. 資料清單作業區 -->
            <section class="card-modern">
                <div class="card-modern-header">
                    <div class="card-modern-title">
                        <i class="fas fa-list-alt text-primary"></i>
                        <span>統計查詢結果</span>
                        <span class="badge badge-primary ml-2">{{ totalRecords }} 筆</span>
                    </div>

                    <div class="d-flex align-items-center gap-3">
                        <!-- 每頁筆數 -->
                        <div class="d-flex align-items-center">
                            <small class="text-muted mr-1 font-weight-bold">每頁</small>
                            <select class="form-control form-control-sm" style="width: 80px;" v-model.number="pageSize" v-on:change="onPageSizeChange">
                                <option :value="10">10</option>
                                <option :value="25">25</option>
                                <option :value="50">50</option>
                                <option :value="100">100</option>
                            </select>
                            <small class="text-muted ml-1 font-weight-bold">筆</small>
                        </div>
                    </div>
                </div>"""

new_sum_list_h = """            <!-- 3. 資料清單作業區 (標準大四元操作工具列) -->
            <section class="card-modern">
                <div class="card-modern-header">
                    <div class="d-flex align-items-center gap-2">
                        <div class="card-modern-title">
                            <i class="fas fa-list-alt text-primary"></i>
                            <span>統計查詢結果</span>
                        </div>
                        <span class="badge badge-light border text-dark font-weight-bold ml-1">
                            共 {{ totalRecords }} 筆
                        </span>
                        <span class="badge badge-secondary ml-1 d-none d-sm-inline">
                            頁次 {{ currentPage }} / {{ totalPages }}
                        </span>
                    </div>

                    <div class="d-flex align-items-center">
                        <!-- 1. 重新整理 -->
                        <button type="button" class="btn btn-sm btn-outline-secondary mr-2" v-on:click="doSearch" :disabled="loading" title="重新整理查詢">
                            <i class="fas fa-sync-alt mr-1" :class="{ 'fa-spin': loading }"></i>
                            <span class="d-none d-md-inline">重新整理</span>
                        </button>

                        <!-- 2. 匯出 EXCEL -->
                        <button type="button" class="btn btn-sm btn-outline-success font-weight-bold mr-2" v-on:click="exportExcel" :disabled="loading || totalRecords === 0" title="匯出篩選結果為 EXCEL 報表">
                            <i class="fas fa-file-excel mr-1"></i>
                            <span class="d-none d-md-inline">匯出 EXCEL</span>
                        </button>

                        <!-- 3. 每頁筆數選擇器 -->
                        <div class="d-inline-flex align-items-center">
                            <span class="small text-muted mr-1 d-none d-lg-inline">每頁：</span>
                            <select class="form-control form-control-sm d-inline-block w-auto" v-model.number="pageSize" v-on:change="onPageSizeChange">
                                <option :value="10">10 筆</option>
                                <option :value="25">25 筆</option>
                                <option :value="50">50 筆</option>
                                <option :value="100">100 筆</option>
                            </select>
                        </div>
                    </div>
                </div>"""

norm_sum = sum_txt.replace('\r\n', '\n')
norm_sum = norm_sum.replace(old_sum_nav.replace('\r\n', '\n'), new_sum_nav.replace('\r\n', '\n'))
norm_sum = norm_sum.replace(old_sum_filter_foot.replace('\r\n', '\n'), new_sum_filter_foot.replace('\r\n', '\n'))
norm_sum = norm_sum.replace(old_sum_list_h.replace('\r\n', '\n'), new_sum_list_h.replace('\r\n', '\n'))

with open(sum_path, 'w', encoding='utf-8-sig', newline='') as fp:
    fp.write(norm_sum.replace('\n', '\r\n'))

print('Case_Sum.aspx successfully standardized!')

# ==================== 2. 更新 Case/Case_Sum_1.aspx ====================
with open(sum1_path, 'r', encoding='utf-8-sig') as fp:
    sum1_txt = fp.read()

# 替換 Navbar: 左側標準回首頁 + 徽章
old_sum1_nav = """            <!-- 1. 置頂導覽列 -->
            <header class="top-navbar no-print">
                <div class="d-flex align-items-center">
                    <a href="../MainPage.aspx?sub=menu4" class="nav-btn mr-3">
                        <i class="fas fa-arrow-left"></i>
                        <span class="d-none d-sm-inline">返回選單</span>
                    </a>
                    <a href="javascript:void(0)" class="brand-title">
                        <i class="fas fa-chart-line text-white"></i>
                        <span>固定污染源管辦改善歷程追蹤統計</span>
                    </a>
                </div>
                <div class="d-flex align-items-center gap-2">
                    <button type="button" class="nav-btn bg-white text-dark shadow-sm mr-2" v-on:click="exportExcel" :disabled="loading || facList.length === 0">
                        <i class="fas fa-file-excel text-success"></i>
                        <span class="d-none d-md-inline">匯出 Excel</span>
                    </button>
                    <button type="button" class="nav-btn bg-white text-dark shadow-sm" v-on:click="printReport">
                        <i class="fas fa-print"></i>
                        <span class="d-none d-md-inline">列印報表</span>
                    </button>
                </div>
            </header>"""

new_sum1_nav = """            <!-- 1. 置頂導覽列 (全站標準左側導航、右側主操作) -->
            <header class="top-navbar no-print">
                <div class="d-flex align-items-center">
                    <a href="../MainPage.aspx?sub=menu4" class="nav-btn mr-2" title="返回主選單">
                        <i class="fas fa-home"></i>
                        <span class="d-none d-sm-inline">回首頁</span>
                    </a>
                    <a href="Case_Sum_1.aspx" class="navbar-brand-title">
                        <i class="fas fa-chart-line text-white"></i>
                        <span>管辦改善歷程追蹤統計</span>
                        <span class="badge badge-light text-dark font-weight-bold ml-1" v-if="facList.length > 0">
                            {{ facList.length }} 家場所
                        </span>
                    </a>
                </div>
                <div class="d-flex align-items-center gap-2">
                    <button type="button" class="btn btn-outline-light btn-sm font-weight-bold" v-on:click="printReport">
                        <i class="fas fa-print mr-1"></i>
                        <span class="d-none d-md-inline">列印報表</span>
                    </button>
                </div>
            </header>"""

# 替換篩選卡片底部操作列
old_sum1_filter_foot = """                        <!-- 動作按鈕列 -->
                        <div class="action-bar">
                            <button type="button" class="btn btn-light btn-sm px-3" v-on:click="resetFilter" :disabled="loading">
                                <i class="fas fa-undo mr-1"></i> 重設條件
                            </button>
                            <button type="button" class="btn btn-primary btn-sm px-4 font-weight-bold" v-on:click="searchData" :disabled="loading">
                                <i class="fas fa-search mr-1" v-if="!loading"></i>
                                <span class="spinner-border spinner-border-sm mr-1" v-if="loading"></span>
                                {{ loading ? '資料統計分析中...' : '開始統計分析' }}
                            </button>
                        </div>"""

new_sum1_filter_foot = """                        <!-- 底部標準操作列 (左側統計、右側重設與查詢) -->
                        <div class="d-flex justify-content-between align-items-center mt-3 pt-3 border-top">
                            <div class="small text-muted">
                                共統計出 <strong class="text-primary">{{ facList.length }}</strong> 家管辦改善場所
                            </div>
                            <div>
                                <button type="button" class="btn btn-outline-secondary btn-sm mr-2" v-on:click="resetFilter" :disabled="loading">
                                    <i class="fas fa-undo mr-1"></i> 重設條件
                                </button>
                                <button type="button" class="btn btn-primary btn-sm px-4 font-weight-bold" v-on:click="searchData" :disabled="loading">
                                    <i class="fas fa-search mr-1" v-if="!loading"></i>
                                    <span class="spinner-border spinner-border-sm mr-1" v-if="loading"></span>
                                    {{ loading ? '資料統計分析中...' : '立即統計分析' }}
                                </button>
                            </div>
                        </div>"""

# 替換統計卡片與清單 Header 工具列
old_sum1_result_banner = """                <!-- D. 資料卡片清單 (每家場所一張現代卡片) -->
                <div v-else>"""

new_sum1_result_banner = """                <!-- D. 資料卡片清單 (標準操作工具列) -->
                <div v-else>
                    <div class="card-modern mb-3 no-print">
                        <div class="card-modern-header">
                            <div class="d-flex align-items-center gap-2">
                                <h2 class="card-modern-title">
                                    <i class="fas fa-list-alt text-primary"></i>
                                    <span>管辦歷程場所明細卡</span>
                                </h2>
                                <span class="badge badge-light border text-dark font-weight-bold ml-1">
                                    共 {{ facList.length }} 家場所
                                </span>
                            </div>
                            <div class="d-flex align-items-center">
                                <!-- 1. 重新整理 -->
                                <button type="button" class="btn btn-sm btn-outline-secondary mr-2" v-on:click="searchData" :disabled="loading" title="重新整理統計">
                                    <i class="fas fa-sync-alt mr-1" :class="{ 'fa-spin': loading }"></i>
                                    <span class="d-none d-md-inline">重新整理</span>
                                </button>

                                <!-- 2. 匯出 EXCEL -->
                                <button type="button" class="btn btn-sm btn-outline-success font-weight-bold" v-on:click="exportExcel" :disabled="loading || facList.length === 0" title="匯出統計 Excel 報表">
                                    <i class="fas fa-file-excel mr-1"></i>
                                    <span class="d-none d-md-inline">匯出 EXCEL</span>
                                </button>
                            </div>
                        </div>
                    </div>"""

norm_sum1 = sum1_txt.replace('\r\n', '\n')
norm_sum1 = norm_sum1.replace(old_sum1_nav.replace('\r\n', '\n'), new_sum1_nav.replace('\r\n', '\n'))
norm_sum1 = norm_sum1.replace(old_sum1_filter_foot.replace('\r\n', '\n'), new_sum1_filter_foot.replace('\r\n', '\n'))
norm_sum1 = norm_sum1.replace(old_sum1_result_banner.replace('\r\n', '\n'), new_sum1_result_banner.replace('\r\n', '\n'))

with open(sum1_path, 'w', encoding='utf-8-sig', newline='') as fp:
    fp.write(norm_sum1.replace('\n', '\r\n'))

print('Case_Sum_1.aspx successfully standardized!')
