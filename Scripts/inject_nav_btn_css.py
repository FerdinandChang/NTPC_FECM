# -*- coding: utf-8 -*-
import os, sys, re

nav_btn_css = """        .nav-btn {
            background: rgba(255, 255, 255, 0.18);
            border: 1px solid rgba(255, 255, 255, 0.3);
            color: #ffffff !important;
            font-size: 0.88rem;
            font-weight: 600;
            cursor: pointer;
            height: 36px;
            border-radius: 8px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            padding: 0 14px;
            gap: 6px;
            transition: all 0.2s ease;
            text-decoration: none !important;
        }
        .nav-btn:hover {
            background-color: rgba(255, 255, 255, 0.32);
            color: #ffffff !important;
            text-decoration: none !important;
        }
"""

all_pages = [
    r'd:\NTPC_FEC\Case\CaseList.aspx',
    r'd:\NTPC_FEC\BareGround\Bare_List.aspx',
    r'd:\NTPC_FEC\RoadClean\Clean_List.aspx',
    r'd:\NTPC_FEC\RoadClean\Dirty_List.aspx',
    r'd:\NTPC_FEC\RoadBSC\BSC_List.aspx',
    r'd:\NTPC_FEC\RoadBreak\Break_List.aspx',
    r'd:\NTPC_FEC\Machine\macList.aspx',
    r'd:\NTPC_FEC\OutLink.aspx',
    r'd:\NTPC_FEC\Manager\managerList.aspx',
    r'd:\NTPC_FEC\Case\Case_Sum.aspx',
    r'd:\NTPC_FEC\Case\Case_Sum_1.aspx',
    r'd:\NTPC_FEC\FAC\oFAC_List.aspx',
    r'd:\NTPC_FEC\FAC\FAC_List.aspx'
]

for p in all_pages:
    if not os.path.exists(p):
        print(f'File not found: {p}')
        continue
    
    with open(p, 'r', encoding='utf-8-sig', errors='ignore') as fp:
        txt = fp.read()
    
    norm = txt.replace('\r\n', '\n')
    
    # 檢查是否已有 .nav-btn
    if re.search(r'\.nav-btn\s*\{', norm):
        # 確保有 color: #ffffff !important
        # 替換既有的 .nav-btn 區塊為最新標準
        norm = re.sub(r'\.nav-btn\s*\{[^}]*\}', """.nav-btn {
            background: rgba(255, 255, 255, 0.18);
            border: 1px solid rgba(255, 255, 255, 0.3);
            color: #ffffff !important;
            font-size: 0.88rem;
            font-weight: 600;
            cursor: pointer;
            height: 36px;
            border-radius: 8px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            padding: 0 14px;
            gap: 6px;
            transition: all 0.2s ease;
            text-decoration: none !important;
        }""", norm)
        
        # 替換 hover
        if re.search(r'\.nav-btn:hover\s*\{', norm):
            norm = re.sub(r'\.nav-btn:hover\s*\{[^}]*\}', """.nav-btn:hover {
            background-color: rgba(255, 255, 255, 0.32);
            color: #ffffff !important;
            text-decoration: none !important;
        }""", norm)
        print(f'Updated existing .nav-btn in {os.path.basename(p)}')
    else:
        # 沒有 .nav-btn，插入在 .top-navbar 之後或 navbar-brand-title 之後
        m = re.search(r'(\.top-navbar\s*\{[^}]*\})', norm)
        if m:
            insert_pos = m.end()
            norm = norm[:insert_pos] + '\n\n' + nav_btn_css.strip() + '\n' + norm[insert_pos:]
            print(f'Injected .nav-btn after .top-navbar in {os.path.basename(p)}')
        else:
            # 插入在 </style> 前
            style_end = norm.find('</style>')
            if style_end != -1:
                norm = norm[:style_end] + '\n' + nav_btn_css + '\n' + norm[style_end:]
                print(f'Injected .nav-btn before </style> in {os.path.basename(p)}')
            else:
                print(f'Warning: No <style> found in {os.path.basename(p)}')
    
    with open(p, 'w', encoding='utf-8-sig', newline='') as fp:
        fp.write(norm.replace('\n', '\r\n'))

print('All pages successfully processed with standard .nav-btn CSS!')
