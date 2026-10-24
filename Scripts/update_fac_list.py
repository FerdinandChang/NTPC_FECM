# -*- coding: utf-8 -*-
import os, sys

file_path = r'd:\NTPC_FEC\FAC\FAC_List.aspx'
with open(file_path, 'r', encoding='utf-8-sig') as fp:
    content = fp.read()

# 1. 替換清單卡片 Header (大四元工具列)
old_header = """            <!-- 6. 資料列表清單卡片 -->
            <div class="card-modern">
                <div class="card-modern-header">
                    <h2 class="card-modern-title">
                        <i class="fas fa-list-alt text-primary"></i>
                        <span>場所清單列表</span>
                        <span class="badge badge-secondary ml-2">頁次 {{ pageIndex }} / {{ totalPages }}</span>
                    </h2>
                    <div class="d-flex align-items-center">
                        <span class="small text-muted mr-2 d-none d-sm-inline">每頁筆數：</span>
                        <select class="form-control form-control-sm d-inline-block w-auto mr-2" v-model="pageSize" v-on:change="changePageSize">
                            <option :value="10">10 筆</option>
                            <option :value="15">15 筆</option>
                            <option :value="30">30 筆</option>
                            <option :value="50">50 筆</option>
                        </select>
                    </div>
                </div>"""

new_header = """            <!-- 6. 資料列表清單卡片 (標準大四元操作工具列) -->
            <div class="card-modern">
                <div class="card-modern-header">
                    <div class="d-flex align-items-center gap-2">
                        <h2 class="card-modern-title">
                            <i class="fas fa-list-alt text-primary"></i>
                            <span>場所清單列表</span>
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
                        <button type="button" class="btn btn-sm btn-outline-secondary mr-2" v-on:click="doSearch" :disabled="loading" title="重新整理場所列表">
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

# 2. 補充 exporting 到 data()
old_data = """                    loading: false,
                    locatingNearby: false,"""

new_data = """                    loading: false,
                    exporting: false,
                    locatingNearby: false,"""

# 3. 補充 exportExcel() 到 methods
old_methods = """                // 4. 複合查詢場所清單"""

new_methods = """                // 匯出 EXCEL 報表
                exportExcel() {
                    if (this.totalCount === 0) {
                        alert('目前無符合條件之場所資料可供匯出！');
                        return;
                    }
                    this.exporting = true;
                    const params = new URLSearchParams();
                    params.append('action', 'exportExcel');
                    params.append('mode', this.currentMode || 'read');
                    for (const key in this.filter) {
                        if (this.filter[key]) {
                            params.append(key, this.filter[key]);
                        }
                    }

                    axios.post('FAC_List.aspx', params, { responseType: 'blob' })
                        .then(res => {
                            const blob = new Blob([res.data], { type: 'application/vnd.ms-excel' });
                            const link = document.createElement('a');
                            link.href = window.URL.createObjectURL(blob);
                            const now = new Date();
                            const timeStr = now.getFullYear() + ('0' + (now.getMonth() + 1)).slice(-2) + ('0' + now.getDate()).slice(-2);
                            link.download = '固定源場所清單_' + timeStr + '.xls';
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

                // 4. 複合查詢場所清單"""

# 執行替換 (考慮 CRLF)
norm_content = content.replace('\r\n', '\n')
norm_old_header = old_header.replace('\r\n', '\n')
norm_new_header = new_header.replace('\r\n', '\n')
norm_old_data = old_data.replace('\r\n', '\n')
norm_new_data = new_data.replace('\r\n', '\n')
norm_old_methods = old_methods.replace('\r\n', '\n')
norm_new_methods = new_methods.replace('\r\n', '\n')

if norm_old_header not in norm_content:
    print('Error: old_header not found in FAC_List.aspx')
    sys.exit(1)
if norm_old_data not in norm_content:
    print('Error: old_data not found in FAC_List.aspx')
    sys.exit(1)
if norm_old_methods not in norm_content:
    print('Error: old_methods not found in FAC_List.aspx')
    sys.exit(1)

norm_content = norm_content.replace(norm_old_header, norm_new_header)
norm_content = norm_content.replace(norm_old_data, norm_new_data)
norm_content = norm_content.replace(norm_old_methods, norm_new_methods)

# 轉回 CRLF 並以 UTF-8 with BOM 儲存
final_content = norm_content.replace('\n', '\r\n')
with open(file_path, 'w', encoding='utf-8-sig', newline='') as fp:
    fp.write(final_content)

print('Successfully updated FAC_List.aspx with UTF-8 with BOM!')
