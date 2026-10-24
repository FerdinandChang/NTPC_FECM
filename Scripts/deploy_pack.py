# -*- coding: utf-8 -*-
r"""
新北市固定溢散源管理平台 (NTPC_FEC) - 正式機安全發布與自動化防呆打包工具
功能：
1. 讀取專案根目錄 deploy_manifest.json 作為單一打包規範來源。
2. 自動掃描並確保所有 .aspx / .Master / .ashx 具備 UTF-8 with BOM 標頭（防止中文亂碼）且無 @click 語法。
3. 執行 dotnet build (強制 C# 5.0 語法相容驗證) 產製最新 bin\NTPC_FEC.dll。
4. 打包並自動於打包後執行【冒煙自檢 (Post-Pack Verification)】，確保所有必備檔案 100% 存在。
"""

import os
import re
import sys
import json
import zipfile
import subprocess
from datetime import datetime
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
DIST_DIR = PROJECT_ROOT / "dist"
MANIFEST_PATH = PROJECT_ROOT / "deploy_manifest.json"


def load_manifest():
    if not MANIFEST_PATH.exists():
        print(f"[錯誤] 找不到打包清單設定檔：{MANIFEST_PATH}")
        sys.exit(1)
    with open(MANIFEST_PATH, "r", encoding="utf-8-sig") as f:
        return json.load(f)


def preflight_check_and_fix_bom(manifest):
    print("[1/4] 正在執行專案編碼 (UTF-8 BOM) 與 ASPX 語法防呆檢查...")
    exclude_dirs = set(d.lower() for d in manifest.get("exclude_dirs", []))
    fixed_bom_count = 0
    errors = []

    for root, dirs, files in os.walk(PROJECT_ROOT):
        # 過濾排除目錄
        dirs[:] = [d for d in dirs if d.lower() not in exclude_dirs]
        for file in files:
            low = file.lower()
            if low.endswith((".aspx", ".master", ".ashx")):
                full_path = Path(root) / file
                rel_path = full_path.relative_to(PROJECT_ROOT).as_posix()
                raw = full_path.read_bytes()

                # 1. 自動補齊 UTF-8 BOM
                if not raw.startswith(b"\xef\xbb\xbf"):
                    text = raw.decode("utf-8", errors="replace")
                    full_path.write_bytes(b"\xef\xbb\xbf" + text.encode("utf-8"))
                    fixed_bom_count += 1
                    raw = full_path.read_bytes()

                # 2. 檢查是否誤用 Vue @click / @submit / @change
                text = raw.decode("utf-8-sig", errors="replace")
                bad_at = re.findall(r"(@(?:click|submit|change|input|keydown|keyup)\b)", text)
                if bad_at:
                    errors.append(f"  - {rel_path} 發現禁用語法 {set(bad_at)}，請改用 v-on:")

                # 3. 檢查是否於 ASPX 資料繫結/表達式誤用 C# 6.0+ Null 條件運算子 ?. 或 字串插值 $"
                bad_cs6 = re.findall(r"(<%.*?\?\.[\w\(].*?%>|<%.*?\$[\"'].*?%>)", text, re.DOTALL)
                if bad_cs6:
                    errors.append(f"  - {rel_path} 發現禁用之 C# 6.0+ 語法 (? 或 $\"\")，請符合 C# 5.0 規範: {bad_cs6}")

    if fixed_bom_count > 0:
        print(f"      已自動為 {fixed_bom_count} 個檔案補齊 UTF-8 BOM 標頭。")
    if errors:
        print("[錯誤] ASPX 語法防呆檢查未通過：")
        for err in errors:
            print(err)
        sys.exit(1)
    print("      編碼與語法檢查 100% 通過！")


def build_project():
    print("[2/4] 正在執行專案建置 (dotnet build - 強制 C# 5.0 語法驗證)...")
    csproj_path = PROJECT_ROOT / "NTPC_FEC.csproj"
    res = subprocess.run(
        ["dotnet", "build", str(csproj_path), "-c", "Release", "--no-restore", "/p:EnableSourceControlManagerQueries=false"],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="ignore"
    )
    if res.returncode != 0:
        print("[錯誤] 專案建置失敗！\n", res.stderr or res.stdout)
        sys.exit(1)
    print("      專案建置成功！最新 bin\\NTPC_FEC.dll 已生成。")


def create_package(manifest):
    print("[3/4] 正在依據 deploy_manifest.json 打包檔案...")
    DIST_DIR.mkdir(parents=True, exist_ok=True)
    date_str = datetime.now().strftime("%Y%m%d_%H%M%S")
    zip_filename = f"NTPC_FEC_Release_{date_str}.zip"
    zip_path = DIST_DIR / zip_filename

    include_files = manifest.get("root_include_files", [])
    exclude_dirs = set(d.lower() for d in manifest.get("exclude_dirs", []))
    exclude_exts = tuple(e.lower() for e in manifest.get("exclude_extensions", []))
    exclude_specific = set(f.lower() for f in manifest.get("exclude_specific_files", []))

    pack_count = 0
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
        # 1. 加入根目錄核心檔案
        for f in include_files:
            src = PROJECT_ROOT / f
            if src.exists():
                zf.write(src, arcname=f)
                pack_count += 1

        # 2. 加入所有白名單子目錄
        for item in PROJECT_ROOT.iterdir():
            if item.is_dir() and item.name.lower() not in exclude_dirs:
                is_app_code = (item.name.lower() == "app_code")
                for root, dirs, files in os.walk(item):
                    # 巢狀排除目錄 (例如 NDVI/Tiles 為排程產生之資料，不可被發布包覆蓋或刪除)
                    dirs[:] = [d for d in dirs if d.lower() not in exclude_dirs]
                    for file in files:
                        low_file = file.lower()
                        if low_file.endswith(exclude_exts) or low_file in exclude_specific:
                            continue
                        full_path = Path(root) / file
                        rel_path = full_path.relative_to(PROJECT_ROOT).as_posix()
                        if is_app_code and low_file.endswith(".cs"):
                            # App_Code 類別已編譯進 bin\NTPC_FEC.dll，寫入空註解覆蓋清空正式機殘留檔
                            zf.writestr(rel_path, "\ufeff// Precompiled into bin/NTPC_FEC.dll\r\n".encode("utf-8"))
                        else:
                            zf.write(full_path, arcname=rel_path)
                        pack_count += 1

    print(f"      打包完成！共收錄 {pack_count} 個發布檔案。")
    return zip_path


def verify_package(zip_path, manifest):
    print("[4/4] 正在執行打包後完整性自檢 (Post-Pack Verification)...")
    required_list = manifest.get("required_in_zip", [])
    missing = []
    empty_files = []

    with zipfile.ZipFile(zip_path, "r") as zf:
        # 建立忽略大小寫的映射表
        info_map = {info.filename.replace("\\", "/").lower(): info for info in zf.infolist()}

        for req in required_list:
            req_norm = req.replace("\\", "/").lower()
            if req_norm not in info_map:
                missing.append(req)
            elif info_map[req_norm].file_size == 0:
                empty_files.append(req)

    if missing or empty_files:
        print("[嚴重錯誤] 發布包完整性自檢失敗！已中止發布：")
        if missing:
            print("  缺少必備檔案：", missing)
        if empty_files:
            print("  檔案大小為 0：", empty_files)
        zip_path.unlink(missing_ok=True)
        sys.exit(1)

    print(f"      [驗證通過] {len(required_list)} 項關鍵核心與靜態資源 (含 Vue/Axios/Leaflet/DLL) 100% 齊全！")
    print(f"      發布壓縮檔路徑：{zip_path}")
    print(f"      檔案大小：{zip_path.stat().st_size / 1024:.2f} KB")


if __name__ == "__main__":
    manifest_data = load_manifest()
    preflight_check_and_fix_bom(manifest_data)
    build_project()
    out_zip = create_package(manifest_data)
    verify_package(out_zip, manifest_data)
