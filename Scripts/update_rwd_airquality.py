# -*- coding: utf-8 -*-
import os

with open('OwnReport/Report_AirQuality.aspx', 'r', encoding='utf-8-sig') as f:
    content = f.read()

# 1. 更新 CSS 中 top-navbar 與 brand-title 相關樣式
old_css_navbar = '''        /* 置頂深青藍導覽列 */
        .top-navbar {
            background: linear-gradient(135deg, #0099e5 0%, #0284c7 100%);
            color: #ffffff;
            height: 56px;
            display: flex; align-items: center; justify-content: space-between;
            padding: 0 16px;
            box-shadow: 0 2px 10px rgba(0, 153, 229, 0.25);
            position: sticky; top: 0; z-index: 1020;
        }
        .nav-btn {
            background: rgba(255, 255, 255, 0.18);
            border: none; color: #ffffff;
            font-size: 0.92rem; font-weight: 600; cursor: pointer;
            height: 36px; border-radius: 8px;
            display: inline-flex; align-items: center; justify-content: center;
            padding: 0 14px; gap: 6px;
            transition: all 0.2s;
            text-decoration: none;
        }
        .nav-btn:hover { background-color: rgba(255, 255, 255, 0.32); color: #ffffff; text-decoration: none; }
        .top-navbar .brand-title {
            font-size: 1.08rem; font-weight: 700; margin: 0;
            display: flex; align-items: center; gap: 8px;
        }'''

new_css_navbar = '''        /* 置頂深青藍導覽列 (全載具自適應，嚴禁中文字垂直斷行折行) */
        .top-navbar {
            background: linear-gradient(135deg, #0099e5 0%, #0284c7 100%);
            color: #ffffff;
            height: 56px;
            display: flex; align-items: center; justify-content: space-between;
            padding: 0 12px;
            box-shadow: 0 2px 10px rgba(0, 153, 229, 0.25);
            position: sticky; top: 0; z-index: 1020;
            gap: 8px;
        }
        .nav-btn {
            background: rgba(255, 255, 255, 0.18);
            border: none; color: #ffffff;
            font-size: 0.88rem; font-weight: 600; cursor: pointer;
            height: 34px; border-radius: 8px;
            display: inline-flex; align-items: center; justify-content: center;
            padding: 0 10px; gap: 4px;
            transition: all 0.2s;
            text-decoration: none;
            flex-shrink: 0;
            white-space: nowrap !important;
        }
        .nav-btn:hover { background-color: rgba(255, 255, 255, 0.32); color: #ffffff; text-decoration: none; }
        .top-navbar .brand-title {
            font-size: 1.05rem; font-weight: 700; margin: 0;
            display: flex; align-items: center; gap: 6px;
            min-width: 0;
            flex: 1 1 auto;
            white-space: nowrap !important;
            overflow: hidden;
        }
        .brand-text-truncate {
            white-space: nowrap !important;
            overflow: hidden;
            text-overflow: ellipsis;
            display: inline-block;
        }'''

# 2. 更新頂部導覽列 HTML
old_html_navbar = '''        <!-- 1. 置頂深青藍漸層導覽列 -->
        <header class="top-navbar no-print">
            <div class="brand-title">
                <a href="AirQuality_List.aspx" class="nav-btn mr-2">
                    <i class="fas fa-arrow-left"></i>
                    <span class="d-none d-sm-inline">返回清單</span>
                </a>
                <i class="fas fa-wind text-white mr-1"></i>
                <span>公私場所空品不良應變回報單</span>
                <span v-if="reportData.C_NO" class="badge badge-light text-dark font-weight-bold ml-2" style="font-size: 0.85rem;">
                    {{ reportData.C_NO }}
                </span>
                <span class="badge ml-1" :class="mode === 'edit' ? 'badge-warning text-dark' : 'badge-success text-white'" style="font-size: 0.82rem;">
                    {{ mode === 'edit' ? '編輯案件 #' + reportData.pIndex : '新增通報' }}
                </span>
            </div>

            <div class="d-flex align-items-center gap-2">
                <button type="button" class="nav-btn bg-white text-dark shadow-sm mr-2" v-on:click="printReport">
                    <i class="fas fa-print"></i>
                    <span class="d-none d-md-inline">列印案件</span>
                </button>
                <button type="button" class="btn btn-primary font-weight-bold shadow-sm" v-on:click="submitForm" :disabled="isSaving">
                    <i v-if="isSaving" class="fas fa-spinner fa-spin mr-1"></i>
                    <i v-else class="fas fa-save mr-1"></i>
                    <span>{{ isSaving ? '儲存中...' : '確定送出' }}</span>
                </button>
            </div>
        </header>'''

new_html_navbar = '''        <!-- 1. 置頂深青藍漸層導覽列 (自適應 RWD 最佳化) -->
        <header class="top-navbar no-print">
            <div class="brand-title">
                <a href="AirQuality_List.aspx" class="nav-btn mr-1 mr-sm-2" title="返回清單">
                    <i class="fas fa-arrow-left"></i>
                    <span class="d-none d-sm-inline">返回清單</span>
                </a>
                <i class="fas fa-wind text-white mr-1 d-none d-sm-inline-block"></i>

                <!-- 標題：小尺寸手機簡潔展示，大尺寸完整顯示，嚴格禁止垂直折行直排 -->
                <span class="brand-text-truncate font-weight-bold">
                    <span class="d-none d-md-inline">公私場所空品不良應變回報單</span>
                    <span class="d-inline d-md-none">空品應變回報</span>
                </span>

                <!-- 管制編號 Badge：維持緊湊單行 -->
                <span v-if="reportData.C_NO" class="badge badge-light text-dark font-weight-bold ml-1 ml-sm-2" style="font-size: 0.8rem; white-space: nowrap;">
                    {{ reportData.C_NO }}
                </span>

                <!-- 案件狀態 Badge：小螢幕極簡顯示避免撐破邊界 -->
                <span class="badge ml-1 d-none d-sm-inline-block" :class="mode === 'edit' ? 'badge-warning text-dark' : 'badge-success text-white'" style="font-size: 0.8rem; white-space: nowrap;">
                    {{ mode === 'edit' ? '編輯案件 #' + reportData.pIndex : '新增通報' }}
                </span>
                <span class="badge ml-1 d-inline-block d-sm-none" :class="mode === 'edit' ? 'badge-warning text-dark' : 'badge-success text-white'" style="font-size: 0.75rem; white-space: nowrap;">
                    {{ mode === 'edit' ? '#' + reportData.pIndex : '新增' }}
                </span>
            </div>

            <div class="d-flex align-items-center flex-shrink-0">
                <!-- 列印按鈕：中大螢幕才顯示 (手機螢幕原生通常無印表機驅動，留空間給關鍵元素) -->
                <button type="button" class="nav-btn bg-white text-dark shadow-sm mr-2 d-none d-md-inline-flex" v-on:click="printReport">
                    <i class="fas fa-print"></i>
                    <span>列印案件</span>
                </button>

                <!-- 頂部確定送出按鈕：電腦端完整文字，手機小螢幕緊湊圖示按鈕 (亦可透過底部常駐浮動條送出) -->
                <button type="button" class="btn btn-primary btn-sm font-weight-bold shadow-sm px-2 px-sm-3" v-on:click="submitForm" :disabled="isSaving" style="height: 34px; display: inline-flex; align-items: center; justify-content: center; white-space: nowrap;">
                    <i v-if="isSaving" class="fas fa-spinner fa-spin mr-1"></i>
                    <i v-else class="fas fa-save mr-1"></i>
                    <span class="d-none d-sm-inline">{{ isSaving ? '儲存中...' : '確定送出' }}</span>
                    <span class="d-inline d-sm-none">{{ isSaving ? '存' : '送出' }}</span>
                </button>
            </div>
        </header>'''

# 3. 更新現場廠區地圖 Header 右側按鈕，加入自適應防截斷
old_html_map_header = '''                                <div class="d-flex align-items-center gap-1">
                                    <button type="button" class="btn btn-xs btn-outline-secondary py-1 px-2 mr-1" v-on:click="locateCurrentPosition" title="GPS 定位當前位置">
                                        <i class="fas fa-crosshairs text-primary"></i> GPS
                                    </button>
                                    <button type="button" class="btn btn-xs btn-outline-secondary py-1 px-2 mr-1" v-on:click="resetMapView" title="重設地圖全景">
                                        <i class="fas fa-expand-arrows-alt"></i> 重設
                                    </button>
                                    <button v-if="facInfo.Lat && facInfo.Lng" type="button" class="btn btn-xs btn-outline-success py-1 px-2 mr-1" v-on:click="openGoogleMaps" title="開啟 Google Maps 導航">
                                        <i class="fas fa-location-arrow"></i> 導航
                                    </button>
                                    <button type="button" class="btn btn-xs btn-outline-dark py-1 px-2" v-on:click="isMapCollapsed = !isMapCollapsed">
                                        <i :class="isMapCollapsed ? 'fas fa-chevron-down' : 'fas fa-chevron-up'"></i>
                                    </button>
                                </div>'''

new_html_map_header = '''                                <div class="d-flex align-items-center flex-shrink-0">
                                    <button type="button" class="btn btn-xs btn-outline-secondary py-1 px-2 mr-1" v-on:click="locateCurrentPosition" title="GPS 定位當前位置">
                                        <i class="fas fa-crosshairs text-primary"></i>
                                        <span class="d-none d-sm-inline ml-1">GPS</span>
                                    </button>
                                    <button type="button" class="btn btn-xs btn-outline-secondary py-1 px-2 mr-1" v-on:click="resetMapView" title="重設地圖全景">
                                        <i class="fas fa-expand-arrows-alt"></i>
                                        <span class="d-none d-sm-inline ml-1">全景</span>
                                    </button>
                                    <button v-if="facInfo.Lat && facInfo.Lng" type="button" class="btn btn-xs btn-outline-success py-1 px-2 mr-1" v-on:click="openGoogleMaps" title="開啟 Google Maps 導航">
                                        <i class="fas fa-location-arrow"></i>
                                        <span class="d-none d-sm-inline ml-1">導航</span>
                                    </button>
                                    <button type="button" class="btn btn-xs btn-outline-dark py-1 px-2" v-on:click="isMapCollapsed = !isMapCollapsed" :title="isMapCollapsed ? '展開地圖' : '收合地圖'">
                                        <i :class="isMapCollapsed ? 'fas fa-chevron-down' : 'fas fa-chevron-up'"></i>
                                    </button>
                                </div>'''

# 4. 污染物削減量卡片由 col-md-4 col-sm-6 mb-3 改為 col-6 col-md-4 mb-3 (手機端雙欄並排，不縱向長拉)
old_pollutant_col = '<div class="col-md-4 col-sm-6 mb-3">'
new_pollutant_col = '<div class="col-6 col-md-4 mb-3">'

# 執行替換
matched_all = True
if old_css_navbar in content:
    content = content.replace(old_css_navbar, new_css_navbar)
    print('[OK] CSS Navbar updated')
else:
    print('[FAIL] old_css_navbar not found')
    matched_all = False

if old_html_navbar in content:
    content = content.replace(old_html_navbar, new_html_navbar)
    print('[OK] HTML Navbar updated')
else:
    print('[FAIL] old_html_navbar not found')
    matched_all = False

if old_html_map_header in content:
    content = content.replace(old_html_map_header, new_html_map_header)
    print('[OK] HTML Map Header updated')
else:
    print('[FAIL] old_html_map_header not found')
    matched_all = False

count_pollutant = content.count(old_pollutant_col)
if count_pollutant > 0:
    content = content.replace(old_pollutant_col, new_pollutant_col)
    print(f'[OK] Replaced {count_pollutant} pollutant columns to col-6 col-md-4')
else:
    print('[FAIL] old_pollutant_col not found')

with open('OwnReport/Report_AirQuality.aspx', 'w', encoding='utf-8-sig') as f:
    f.write(content)

print('Update OwnReport/Report_AirQuality.aspx completed!')
