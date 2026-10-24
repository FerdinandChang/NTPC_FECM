<#
.SYNOPSIS
    新北市固定溢散源管理平台 (NTPC_FEC) - 正式機安全發布與自動化防呆打包工具 (PowerShell 繁體中文標準版)
#>

[CmdletBinding()]
param(
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $projectRoot "deploy_manifest.json"
$distDir = Join-Path $projectRoot "dist"

if (-not (Test-Path $manifestPath)) {
    Write-Host "【錯誤】找不到打包清單設定檔：$manifestPath" -ForegroundColor Red
    exit 1
}

$manifestJson = Get-Content -Path $manifestPath -Raw -Encoding UTF8
$manifest = $manifestJson | ConvertFrom-Json

# [1/4] 編碼 (UTF-8 BOM) 與語法防呆檢查
Write-Host "【1/4】正在執行專案編碼 (UTF-8 BOM) 與 ASPX 語法防呆檢查..." -ForegroundColor Cyan
$excludeDirs = @($manifest.exclude_dirs | ForEach-Object { $_.ToLower() })
$errors = @()
$fixedBomCount = 0

$allFiles = Get-ChildItem -Path $projectRoot -Recurse -File | Where-Object {
    $itemPath = $_.FullName
    $skip = $false
    foreach ($d in $excludeDirs) {
        if ($itemPath -like "*\$d\*") { $skip = $true; break }
    }
    -not $skip
}

foreach ($f in $allFiles) {
    $ext = $f.Extension.ToLower()
    if ($ext -in @('.aspx', '.master', '.ashx', '.cs')) {
        $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
        if ($bytes.Length -lt 3 -or $bytes[0] -ne 0xEF -or $bytes[1] -ne 0xBB -or $bytes[2] -ne 0xBF) {
            $bom = [byte[]]@(0xEF, 0xBB, 0xBF)
            [System.IO.File]::WriteAllBytes($f.FullName, ($bom + $bytes))
            $fixedBomCount++
        }

        # 檢查 ASPX / Master 禁用之 Vue @ 語法
        if ($ext -in @('.aspx', '.master')) {
            $text = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
            if ($text -match '(@(?:click|submit|change|input|keydown|keyup)\b)') {
                $rel = $f.FullName.Replace($projectRoot, '').TrimStart('\')
                $errors += "  - $rel 發現禁用語法 @click/@submit 等，請改用 v-on:"
            }
        }
    }
}

if ($fixedBomCount -gt 0) {
    Write-Host "      已自動為 $fixedBomCount 個檔案補齊 UTF-8 BOM 標頭。" -ForegroundColor Yellow
}
if ($errors.Count -gt 0) {
    Write-Host "【錯誤】ASPX 語法防呆檢查未通過：" -ForegroundColor Red
    foreach ($err in $errors) {
        Write-Host $err -ForegroundColor Red
    }
    exit 1
}
Write-Host "      編碼與語法檢查 100% 通過！" -ForegroundColor Green

# [2/4] 專案建置
Write-Host "【2/4】正在執行專案建置 (dotnet build - 強制 C# 5.0 語法驗證)..." -ForegroundColor Cyan
$csprojPath = Join-Path $projectRoot "NTPC_FEC.csproj"
$buildOutput = & dotnet build $csprojPath -c Release --no-restore /p:EnableSourceControlManagerQueries=false 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "【錯誤】專案建置失敗！" -ForegroundColor Red
    Write-Host ($buildOutput -join "`n") -ForegroundColor Red
    exit 1
}
Write-Host "      專案建置成功！最新 bin\NTPC_FEC.dll 已生成。" -ForegroundColor Green

if ($DryRun) {
    Write-Host "【Dry-Run】模擬檢查完成，跳過建立 ZIP 封裝包。" -ForegroundColor Magenta
    exit 0
}

# [3/4] 依據 deploy_manifest.json 打包檔案
Write-Host "【3/4】正在依據 deploy_manifest.json 打包檔案..." -ForegroundColor Cyan
if (-not (Test-Path $distDir)) {
    New-Item -ItemType Directory -Path $distDir | Out-Null
}

$dateStr = Get-Date -Format "yyyyMMdd_HHmmss"
$zipFileName = "NTPC_FEC_Release_$dateStr.zip"
$zipPath = Join-Path $distDir $zipFileName

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zipFileStream = [System.IO.File]::Create($zipPath)
$archive = New-Object System.IO.Compression.ZipArchive($zipFileStream, [System.IO.Compression.ZipArchiveMode]::Create)

$includeFiles = @($manifest.root_include_files)
$excludeExts = @($manifest.exclude_extensions | ForEach-Object { $_.ToLower() })
$excludeSpecific = @($manifest.exclude_specific_files | ForEach-Object { $_.ToLower() })
$packCount = 0

try {
    # 1. 寫入根目錄指定之重要設定與進入點檔案
    foreach ($f in $includeFiles) {
        $src = Join-Path $projectRoot $f
        if (Test-Path $src -PathType Leaf) {
            [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $src, $f, [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null
            $packCount++
        }
    }

    # 2. 加入各白名單子目錄
    $rootDirs = Get-ChildItem -Path $projectRoot -Directory | Where-Object {
        $_.Name.ToLower() -notin $excludeDirs
    }

    foreach ($subDir in $rootDirs) {
        $isAppCode = ($subDir.Name.ToLower() -eq 'app_code')
        $subFiles = Get-ChildItem -Path $subDir.FullName -Recurse -File | Where-Object {
            $itemPath = $_.FullName
            $skip = $false
            foreach ($d in $excludeDirs) {
                if ($itemPath -like "*\$d\*") { $skip = $true; break }
            }
            -not $skip
        }

        foreach ($file in $subFiles) {
            $lowName = $file.Name.ToLower()
            $lowExt = $file.Extension.ToLower()

            if ($lowExt -in $excludeExts -or $lowName -in $excludeSpecific) {
                continue
            }

            $rel = $file.FullName.Substring($projectRoot.Length).TrimStart('\', '/').Replace('\', '/')

            if ($isAppCode -and $lowExt -eq '.cs') {
                $entry = $archive.CreateEntry($rel, [System.IO.Compression.CompressionLevel]::Optimal)
                $entryStream = $entry.Open()
                $commentBytes = [System.Text.Encoding]::UTF8.GetBytes("// Precompiled into bin/NTPC_FEC.dll`r`n")
                $entryStream.Write($commentBytes, 0, $commentBytes.Length)
                $entryStream.Dispose()
            } else {
                [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $file.FullName, $rel, [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null
            }
            $packCount++
        }
    }
} finally {
    $archive.Dispose()
    $zipFileStream.Dispose()
}

Write-Host "      打包完成！共收錄 $packCount 個發布檔案。" -ForegroundColor Green

# [4/4] 打包後完整性冒煙自檢 (Post-Pack Verification)
Write-Host "【4/4】正在執行打包後完整性自檢 (Post-Pack Verification)..." -ForegroundColor Cyan
$requiredList = @($manifest.required_in_zip)
$missing = @()
$emptyFiles = @()

$verifyStream = [System.IO.File]::OpenRead($zipPath)
$verifyArchive = New-Object System.IO.Compression.ZipArchive($verifyStream, [System.IO.Compression.ZipArchiveMode]::Read)

$entryMap = @{}
foreach ($entry in $verifyArchive.Entries) {
    $entryMap[$entry.FullName.ToLower()] = $entry
}

foreach ($req in $requiredList) {
    $reqNorm = $req.Replace('\', '/').ToLower()
    if (-not $entryMap.ContainsKey($reqNorm)) {
        $missing += $req
    } elseif ($entryMap[$reqNorm].Length -eq 0) {
        $emptyFiles += $req
    }
}

$verifyArchive.Dispose()
$verifyStream.Dispose()

if ($missing.Count -gt 0 -or $emptyFiles.Count -gt 0) {
    Write-Host "【嚴重錯誤】發布包完整性自檢失敗！已中止發布：" -ForegroundColor Red
    if ($missing.Count -gt 0) {
        Write-Host "  缺少必備檔案：" -ForegroundColor Red
        foreach ($m in $missing) {
            Write-Host "    - $m" -ForegroundColor Red
        }
    }
    if ($emptyFiles.Count -gt 0) {
        Write-Host "  檔案大小為 0：" -ForegroundColor Red
        foreach ($emp in $emptyFiles) {
            Write-Host "    - $emp" -ForegroundColor Red
        }
    }
    Remove-Item -Path $zipPath -Force -ErrorAction SilentlyContinue
    exit 1
}

$zipFileInfo = Get-Item $zipPath
$sizeKb = [Math]::Round($zipFileInfo.Length / 1KB, 2)
Write-Host ('      [驗證通過] ' + $requiredList.Count + ' 項關鍵核心與靜態資源 100% 齊全！') -ForegroundColor Green
Write-Host ('      發布壓縮檔路徑：' + $zipPath) -ForegroundColor Green
Write-Host ('      檔案大小：' + $sizeKb + ' KB') -ForegroundColor Green
