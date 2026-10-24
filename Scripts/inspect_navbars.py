# -*- coding: utf-8 -*-
import os, re

files = [
    r'd:\NTPC_FEC\RoadClean\Dirty_List.aspx',
    r'd:\NTPC_FEC\RoadBSC\BSC_List.aspx',
    r'd:\NTPC_FEC\RoadBreak\Break_List.aspx',
    r'd:\NTPC_FEC\Machine\macList.aspx'
]

for f in files:
    with open(f, 'r', encoding='utf-8-sig') as fp:
        t = fp.read()
    m = re.search(r'<header class="top-navbar">.*?</header>', t, re.DOTALL)
    print('=== ' + os.path.basename(f) + ' ===')
    if m:
        print(m.group())
    else:
        print('No top-navbar found')
