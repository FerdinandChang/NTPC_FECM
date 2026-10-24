# -*- coding: utf-8 -*-
import os, sys, re

# ================= 1. Dirty_List.aspx =================
dirty_path = r'd:\NTPC_FEC\RoadClean\Dirty_List.aspx'
with open(dirty_path, 'r', encoding='utf-8-sig', errors='ignore') as fp:
    dirty_txt = fp.read()

new_dirty_nav = """        <!-- 頂部品牌導覽列 (全站標準左側導航、右側主操作) -->
        <header class="top-navbar">
            <div class="d-flex align-items-center">
                <a href="../MainPage.aspx?sub=menu4" class="nav-btn mr-2" title="返回主選單">
                    <i class="fas fa-home"></i>
                    <span class="d-none d-sm-inline">回首頁</span>
                </a>
                <a href="Dirty_List.aspx" class="navbar-brand-title">
                    <i class="fas fa-trash-alt text-white"></i>
                    <span>路面髒污查核與通報管理</span>
                </a>
            </div>
            <div class="d-flex align-items-center gap-2">
                <a href="NewDirty.aspx?mode=new" class="btn btn-success btn-sm font-weight-bold shadow-sm mr-2">
                    <i class="fas fa-plus-circle mr-1"></i>
                    <span class="d-none d-sm-inline">新增髒污通報</span>
                </a>
            </div>
        </header>"""

dirty_txt = re.sub(r'<header class="top-navbar">.*?</header>', new_dirty_nav, dirty_txt, flags=re.DOTALL)
with open(dirty_path, 'w', encoding='utf-8-sig', newline='') as fp:
    fp.write(dirty_txt.replace('\r\n', '\n').replace('\n', '\r\n'))
print('Dirty_List.aspx navbar updated!')

# ================= 2. BSC_List.aspx =================
bsc_path = r'd:\NTPC_FEC\RoadBSC\BSC_List.aspx'
with open(bsc_path, 'r', encoding='utf-8-sig', errors='ignore') as fp:
    bsc_txt = fp.read()

new_bsc_nav = """        <!-- 頂部品牌導覽列 (全站標準左側導航、右側主操作) -->
        <header class="top-navbar">
            <div class="d-flex align-items-center">
                <a href="../MainPage.aspx?sub=menu4" class="nav-btn mr-2" title="返回主選單">
                    <i class="fas fa-home"></i>
                    <span class="d-none d-sm-inline">回首頁</span>
                </a>
                <a href="BSC_List.aspx" class="navbar-brand-title">
                    <i class="fas fa-seedling text-white"></i>
                    <span>車行路段翻轉空污防制管理</span>
                </a>
            </div>
            <div class="d-flex align-items-center gap-2">
                <a href="NewBSC.aspx?mode=new" class="btn btn-success btn-sm font-weight-bold shadow-sm mr-2">
                    <i class="fas fa-plus-circle mr-1"></i>
                    <span class="d-none d-sm-inline">新增路段巡查</span>
                </a>
            </div>
        </header>"""

bsc_txt = re.sub(r'<header class="top-navbar">.*?</header>', new_bsc_nav, bsc_txt, flags=re.DOTALL)
with open(bsc_path, 'w', encoding='utf-8-sig', newline='') as fp:
    fp.write(bsc_txt.replace('\r\n', '\n').replace('\n', '\r\n'))
print('BSC_List.aspx navbar updated!')

# ================= 3. Break_List.aspx =================
break_path = r'd:\NTPC_FEC\RoadBreak\Break_List.aspx'
with open(break_path, 'r', encoding='utf-8-sig', errors='ignore') as fp:
    break_txt = fp.read()

new_break_nav = """        <!-- 頂部品牌導覽列 (全站標準左側導航、右側主操作) -->
        <header class="top-navbar">
            <div class="d-flex align-items-center">
                <a href="../MainPage.aspx?sub=menu4" class="nav-btn mr-2" title="返回主選單">
                    <i class="fas fa-home"></i>
                    <span class="d-none d-sm-inline">回首頁</span>
                </a>
                <a href="Break_List.aspx" class="navbar-brand-title">
                    <i class="fas fa-road text-white"></i>
                    <span>道路破損巡查與通報管理</span>
                </a>
            </div>
            <div class="d-flex align-items-center gap-2">
                <a href="NewBreak.aspx?mode=new" class="btn btn-success btn-sm font-weight-bold shadow-sm mr-2">
                    <i class="fas fa-plus-circle mr-1"></i>
                    <span class="d-none d-sm-inline">新增破損巡查</span>
                </a>
            </div>
        </header>"""

break_txt = re.sub(r'<header class="top-navbar">.*?</header>', new_break_nav, break_txt, flags=re.DOTALL)
with open(break_path, 'w', encoding='utf-8-sig', newline='') as fp:
    fp.write(break_txt.replace('\r\n', '\n').replace('\n', '\r\n'))
print('Break_List.aspx navbar updated!')

# ================= 4. macList.aspx =================
mac_path = r'd:\NTPC_FEC\Machine\macList.aspx'
with open(mac_path, 'r', encoding='utf-8-sig', errors='ignore') as fp:
    mac_txt = fp.read()

new_mac_nav = """        <!-- 頂部品牌導覽列 (全站標準左側導航、右側主操作) -->
        <header class="top-navbar">
            <div class="d-flex align-items-center">
                <a href="../MainPage.aspx" class="nav-btn mr-2" title="返回主選單">
                    <i class="fas fa-home"></i>
                    <span class="d-none d-sm-inline">回首頁</span>
                </a>
                <div class="navbar-brand-title">
                    <i class="fas fa-truck-monster text-white"></i>
                    <span>洗掃作業自主管理與車輛清單</span>
                </div>
            </div>
            <div class="d-flex align-items-center gap-2">
                <a href="NewMac.aspx?mode=new" class="btn btn-success btn-sm font-weight-bold shadow-sm mr-2">
                    <i class="fas fa-plus-circle mr-1"></i>
                    <span class="d-none d-sm-inline">新增車輛機具</span>
                </a>
                <button type="button" class="btn btn-sm btn-outline-light font-weight-bold" v-on:click="refreshData" title="重新整理">
                    <i class="fas fa-sync-alt" :class="{ 'fa-spin': isLoading }"></i>
                    <span class="d-none d-md-inline ml-1">重新整理</span>
                </button>
            </div>
        </header>"""

mac_txt = re.sub(r'<header class="top-navbar">.*?</header>', new_mac_nav, mac_txt, flags=re.DOTALL)
with open(mac_path, 'w', encoding='utf-8-sig', newline='') as fp:
    fp.write(mac_txt.replace('\r\n', '\n').replace('\n', '\r\n'))
print('macList.aspx navbar updated!')
