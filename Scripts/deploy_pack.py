# -*- coding: utf-8 -*-
r"""
新北市固定溢散源管理平台 (NTPC_FEC) - 正式機安全發布打包工具
功能：
1. 自動建置專案並產製最新 bin\NTPC_FEC.dll。
2. 嚴格排除 Backup、obj、.git 等暫存與舊檔。
3. 自動打包成乾淨的 zip 發布包，可直接丟上正式機 IIS 解壓縮覆蓋。
"""

import os
import sys
import zipfile
import subprocess
from datetime import datetime
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
DIST_DIR = PROJECT_ROOT / "dist"

# 發布時必須包含的根目錄檔案
INCLUDE_FILES = [
    "Default.aspx",
    "Default.aspx.cs",
    "ClientLogin.aspx",
    "ClientLogin.aspx.cs",
    "MainPage.aspx",
    "MainPage.aspx.cs",
    "MainPage.Master",
    "MainPage.Master.cs",
    "ValidateCode.ashx",
    "Logout.aspx",
    "Web.config",
    "自主管理平台操作手冊R8.pdf",
    "favicon.ico",
    "apple-touch-icon.png"
]

# 發布時必須包含的子目錄
INCLUDE_DIRS = [
    "bin",
    "images",
    "Content",
    "Scripts",
    "Modules"
]

def build_project():
    print("[1/3] 正在執行專案建置 (dotnet build)...")
    csproj_path = PROJECT_ROOT / "NTPC_FEC.csproj"
    res = subprocess.run(["dotnet", "build", str(csproj_path), "-c", "Release"], capture_output=True, text=True, encoding="utf-8", errors="ignore")
    if res.returncode != 0:
        print("[錯誤] 專案建置失敗！\n", res.stderr or res.stdout)
        sys.exit(1)
    print("      專案建置成功！最新 NTPC_FEC.dll 已生成。")

def create_package():
    print("[2/3] 正在準備安全打包清單...")
    DIST_DIR.mkdir(parents=True, exist_ok=True)
    date_str = datetime.now().strftime("%Y%m%d_%H%M%S")
    zip_filename = f"NTPC_FEC_Release_{date_str}.zip"
    zip_path = DIST_DIR / zip_filename

    pack_count = 0
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
        # 1. 加入根目錄核心頁面
        for f in INCLUDE_FILES:
            src = PROJECT_ROOT / f
            if src.exists():
                zf.write(src, arcname=f)
                pack_count += 1

        # 2. 加入指定子目錄 (排除 pdb, obj, 暫存)
        for d in INCLUDE_DIRS:
            dir_path = PROJECT_ROOT / d
            if not dir_path.exists():
                continue
            for root, _, files in os.walk(dir_path):
                for file in files:
                    # 排除偵錯符號與臨時檔
                    if file.lower().endswith((".pdb", ".user", ".suo", ".tmp")):
                        continue
                    full_path = Path(root) / file
                    rel_path = full_path.relative_to(PROJECT_ROOT)
                    zf.write(full_path, arcname=str(rel_path))
                    pack_count += 1

    print(f"[3/3] 打包完成！共收錄 {pack_count} 個必要發布檔案。")
    print(f"      發布壓縮檔路徑：{zip_path}")
    print(f"      檔案大小：{zip_path.stat().st_size / 1024:.2f} KB")

if __name__ == "__main__":
    build_project()
    create_package()
