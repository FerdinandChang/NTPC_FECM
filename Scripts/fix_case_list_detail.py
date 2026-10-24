# -*- coding: utf-8 -*-
import os, sys

file_path = r'd:\NTPC_FEC\Case\CaseList.aspx'
with open(file_path, 'r', encoding='utf-8-sig') as fp:
    content = fp.read()

# 1. Navbar 右側加上標準綠色「新增巡查」
old_nav_r = """            <div class="d-flex align-items-center gap-2">
                <span class="d-none d-md-inline text-white small mr-2">
                    <i class="fas fa-user-circle mr-1"></i>{{ currentUser }}
                </span>
                <a href="../FAC/FAC_List.aspx" class="btn btn-outline-light btn-sm font-weight-bold">
                    <i class="fas fa-industry mr-1"></i>場所資料庫
                </a>
            </div>"""

new_nav_r = """            <div class="d-flex align-items-center gap-2">
                <a href="NewCase.aspx?mode=new" class="btn btn-success btn-sm font-weight-bold shadow-sm mr-2">
                    <i class="fas fa-plus-circle mr-1"></i>
                    <span class="d-none d-sm-inline">新增巡查</span>
                </a>
                <span class="d-none d-md-inline text-white small mr-2">
                    <i class="fas fa-user-circle mr-1"></i>{{ currentUser }}
                </span>
                <a href="../FAC/FAC_List.aspx" class="btn btn-outline-light btn-sm font-weight-bold">
                    <i class="fas fa-industry mr-1"></i>場所資料庫
                </a>
            </div>"""

# 2. 篩選卡片加上折疊與標準底部操作列
old_filter_h = """            <!-- 3. 複合條件搜尋與外勤 GPS 定位卡片 -->
            <div class="card-modern">
                <div class="card-modern-header">
                    <div class="card-modern-title">
                        <i class="fas fa-filter text-info"></i>
                        <span>查詢與篩選設定</span>
                    </div>
                    <div class="d-flex align-items-center gap-2">
                        <button type="button" class="btn btn-sm btn-outline-success" v-on:click="searchNearbyGps">
                            <i class="fas fa-street-view mr-1"></i> 搜尋附近場所 (環域 3km)
                        </button>
                    </div>
                </div>
                <div class="card-modern-body">"""

new_filter_h = """            <!-- 3. 複合條件搜尋與外勤 GPS 定位卡片 (全站標準折疊與操作列) -->
            <div class="card-modern">
                <div class="card-modern-header" style="cursor: pointer;" v-on:click="filterCollapsed = !filterCollapsed">
                    <div class="card-modern-title">
                        <i class="fas fa-filter text-primary"></i>
                        <span>查詢與篩選設定</span>
                    </div>
                    <div class="d-flex align-items-center gap-2">
                        <button type="button" class="btn btn-sm btn-outline-success" v-on:click.stop="searchNearbyGps">
                            <i class="fas fa-street-view mr-1"></i> 搜尋附近場所 (環域 3km)
                        </button>
                        <button type="button" class="btn btn-link btn-sm text-muted p-0 ml-2">
                            <i class="fas" :class="filterCollapsed ? 'fa-chevron-down' : 'fa-chevron-up'"></i>
                        </button>
                    </div>
                </div>
                <div class="card-modern-body" v-show="!filterCollapsed">"""

old_filter_b = """                    <div class="d-flex justify-content-end gap-2 mt-3 pt-2 border-top">
                        <button type="button" class="btn btn-secondary btn-sm px-3" v-on:click="resetFilter">
                            <i class="fas fa-undo mr-1"></i> 重設
                        </button>
                        <button type="button" class="btn btn-primary btn-sm px-4 font-weight-bold" v-on:click="loadData(1)">
                            <i class="fas fa-search mr-1"></i> 開始搜尋
                        </button>
                    </div>"""

new_filter_b = """                    <div class="d-flex justify-content-between align-items-center mt-3 pt-2 border-top">
                        <div class="small text-muted">
                            共查詢到 <strong class="text-primary">{{ totalCount }}</strong> 家巡查場所
                        </div>
                        <div>
                            <button type="button" class="btn btn-outline-secondary btn-sm mr-2" v-on:click="resetFilter">
                                <i class="fas fa-undo mr-1"></i> 重設條件
                            </button>
                            <button type="button" class="btn btn-primary btn-sm px-3 font-weight-bold" v-on:click="loadData(1)">
                                <i class="fas fa-search mr-1"></i> 立即查詢
                            </button>
                        </div>
                    </div>"""

# 3. JS data 增加 filterCollapsed
old_js_data = """                return {
                    loading: false,"""
new_js_data = """                return {
                    filterCollapsed: false,
                    loading: false,"""

norm = content.replace('\r\n', '\n')
norm = norm.replace(old_nav_r.replace('\r\n', '\n'), new_nav_r.replace('\r\n', '\n'))
norm = norm.replace(old_filter_h.replace('\r\n', '\n'), new_filter_h.replace('\r\n', '\n'))
norm = norm.replace(old_filter_b.replace('\r\n', '\n'), new_filter_b.replace('\r\n', '\n'))
norm = norm.replace(old_js_data.replace('\r\n', '\n'), new_js_data.replace('\r\n', '\n'))

with open(file_path, 'w', encoding='utf-8-sig', newline='') as fp:
    fp.write(norm.replace('\n', '\r\n'))

print('CaseList.aspx fine-tuning successfully completed!')
