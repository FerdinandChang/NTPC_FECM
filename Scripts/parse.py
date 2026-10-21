# -*- coding: utf-8 -*-
import re

with open(r'd:\NTPC_FEC_Source\NTPC_FEC\MainPage1.cs', 'r', encoding='utf-8') as f:
    text = f.read()

# 找出所有的子模組區塊與其按鈕定義
# 規則：BT_Name = "名稱"; ... window.location.href='/" + SysRootPath2 + "/路徑'
pattern = re.compile(r'BT_Name\s*=\s*"([^"]+)";.*?(?:window\.location\.href|location\.href|window\.open)\s*=\s*[\'"](?:\/"\s*\+\s*SysRootPath2\s*\+\s*"\/)?([^\'"]+)[\'"]', re.DOTALL)

with open(r'D:\NTPC_FEC\scripts\menu_detailed.txt', 'w', encoding='utf-8') as out:
    for m in pattern.finditer(text):
        name = m.group(1)
        url = m.group(2)
        out.write(f"{name} -> {url}\n")
