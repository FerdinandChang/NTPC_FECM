# -*- coding: utf-8 -*-
import os, sys, re

file_path = r'd:\NTPC_FEC\OutLink.aspx'
with open(file_path, 'r', encoding='utf-8-sig') as fp:
    content = fp.read()

# 1. 替換頂部 Navbar
old_nav = """        <!-- 頂部品牌導覽列 (與 Clean_List 一致) -->
        <header class="top-navbar">
            <a href="OutLink.aspx" class="navbar-brand-title">
                <i class="fas fa-network-wired"></i>
                <span>新北市固定溢散源 - 相關外部系統連結</span>
            </a>
            <div class="d-flex align-items-center gap-2">
                <a href="MainPage.aspx" class="btn btn-outline-light font-weight-bold px-3" style="border-radius: 8px;">
                    <i class="fas fa-chevron-left"></i>
                    <span class="d-none d-sm-inline ml-1">回主選單</span>
                </a>
            </div>
        </header>"""

new_nav = """        <!-- 頂部品牌導覽列 (全站標準左側導航、右側主操作) -->
        <header class="top-navbar">
            <div class="d-flex align-items-center">
                <a href="MainPage.aspx" class="nav-btn mr-2" title="返回主選單">
                    <i class="fas fa-home"></i>
                    <span class="d-none d-sm-inline">回首頁</span>
                </a>
                <a href="OutLink.aspx" class="navbar-brand-title">
                    <i class="fas fa-network-wired text-white"></i>
                    <span>相關外部系統連結</span>
                    <span class="badge badge-light text-dark font-weight-bold ml-1">
                        {{ totalCount }} 個系統
                    </span>
                </a>
            </div>
            <div class="d-flex align-items-center gap-2">
                <button type="button" class="btn btn-sm btn-outline-light font-weight-bold" v-on:click="resetFilter" title="重新整理">
                    <i class="fas fa-sync-alt mr-1"></i>
                    <span class="d-none d-md-inline">重新整理</span>
                </button>
            </div>
        </header>"""

# 2. 替換篩選卡片
old_filter = """            <!-- 系統查詢篩選卡片 (與 Clean_List 一致) -->
            <div class="card-modern">
                <div class="card-modern-header">
                    <h2 class="card-modern-title">
                        <i class="fas fa-filter text-primary"></i>
                        <span>系統條件篩選</span>
                    </h2>
                    <div class="d-flex align-items-center gap-2">
                        <button type="button" class="btn btn-sm btn-outline-secondary font-weight-bold" v-on:click="resetFilter">
                            <i class="fas fa-redo-alt mr-1"></i> 重設條件
                        </button>
                    </div>
                </div>"""

new_filter = """            <!-- 系統查詢篩選卡片 (全站標準折疊與操作列) -->
            <div class="card-modern">
                <div class="card-modern-header" style="cursor: pointer;" v-on:click="filterCollapsed = !filterCollapsed">
                    <h2 class="card-modern-title">
                        <i class="fas fa-filter text-primary"></i>
                        <span>系統條件篩選</span>
                    </h2>
                    <button type="button" class="btn btn-link btn-sm text-muted p-0">
                        <i class="fas" :class="filterCollapsed ? 'fa-chevron-down' : 'fa-chevron-up'"></i>
                    </button>
                </div>"""

# 3. 篩選卡片 body 加上 v-show="!filterCollapsed"，底部動作列標準化
old_filter_body = """                <div class="card-modern-body">"""
new_filter_body = """                <div class="card-modern-body" v-show="!filterCollapsed">"""

old_filter_footer = """                    <!-- 快捷分類標籤與動作列 (與 Clean_List 一致) -->
                    <div class="d-flex flex-wrap align-items-center justify-content-between pt-2 border-top">
                        <div class="btn-group btn-group-sm mb-2 mb-md-0" role="group">
                            <button type="button" class="btn btn-outline-secondary" :class="{ 'active font-weight-bold': currentCategory === '全部' }" v-on:click="setCategory('全部')">全部</button>
                            <button type="button" class="btn btn-outline-secondary" :class="{ 'active font-weight-bold': currentCategory === '中央申報與許可' }" v-on:click="setCategory('中央申報與許可')">中央申報許可</button>
                            <button type="button" class="btn btn-outline-secondary" :class="{ 'active font-weight-bold': currentCategory === '公開資訊與監測' }" v-on:click="setCategory('公開資訊與監測')">公開數據監測</button>
                            <button type="button" class="btn btn-outline-secondary" :class="{ 'active font-weight-bold': currentCategory === '圖資與查核輔助' }" v-on:click="setCategory('圖資與查核輔助')">空間圖資工具</button>
                            <button type="button" class="btn btn-outline-secondary" :class="{ 'active font-weight-bold': currentCategory === '新北市主管機關' }" v-on:click="setCategory('新北市主管機關')">新北市專區</button>
                        </div>

                        <div class="d-flex align-items-center gap-2">
                            <button type="button" class="btn btn-primary px-4 font-weight-bold shadow-sm" v-on:click="scrollToResult">
                                <i class="fas fa-search mr-1"></i>
                                <span>即時過濾 ({{ filteredLinks.length }} 筆)</span>
                            </button>
                        </div>
                    </div>"""

new_filter_footer = """                    <!-- 底部標準操作列 (左側統計、右側重設與查詢) -->
                    <div class="d-flex flex-wrap align-items-center justify-content-between pt-2 border-top">
                        <div class="small text-muted mb-2 mb-md-0">
                            共過濾出 <strong class="text-primary">{{ filteredLinks.length }}</strong> 個系統項目
                        </div>
                        <div class="d-flex align-items-center gap-2">
                            <button type="button" class="btn btn-outline-secondary btn-sm mr-2" v-on:click="resetFilter">
                                <i class="fas fa-undo mr-1"></i> 重設條件
                            </button>
                            <button type="button" class="btn btn-primary btn-sm px-3" v-on:click="scrollToResult">
                                <i class="fas fa-search mr-1"></i> 立即查詢
                            </button>
                        </div>
                    </div>"""

# 4. JS data 增加 filterCollapsed
old_js_data = """                return {
                    viewMode: 'grid',"""
new_js_data = """                return {
                    filterCollapsed: false,
                    viewMode: 'grid',"""

norm = content.replace('\r\n', '\n')
norm = norm.replace(old_nav.replace('\r\n', '\n'), new_nav.replace('\r\n', '\n'))
norm = norm.replace(old_filter.replace('\r\n', '\n'), new_filter.replace('\r\n', '\n'))
norm = norm.replace(old_filter_body.replace('\r\n', '\n'), new_filter_body.replace('\r\n', '\n'))
norm = norm.replace(old_filter_footer.replace('\r\n', '\n'), new_filter_footer.replace('\r\n', '\n'))
norm = norm.replace(old_js_data.replace('\r\n', '\n'), new_js_data.replace('\r\n', '\n'))

with open(file_path, 'w', encoding='utf-8-sig', newline='') as fp:
    fp.write(norm.replace('\n', '\r\n'))

print('OutLink.aspx successfully standardized!')
