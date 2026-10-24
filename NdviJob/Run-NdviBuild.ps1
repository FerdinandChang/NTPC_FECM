# NTPC_FEC NDVI 月報排程執行包裝 (Windows PowerShell 5.1+)
# 功用: 單一實例鎖 -> 執行 ndvi_build.py -> 失敗自動重試 -> 寫入記錄與 Windows 事件檢視器
# 用法: powershell -NoProfile -ExecutionPolicy Bypass -File D:\NdviJob\Run-NdviBuild.ps1 [-Month 2026-09]
# 結束代碼: 0 成功 / 1 失敗(舊圖磚不受影響) / 2 已有另一個實例在執行

param(
    [string]$Month = '',
    [string]$Root = 'D:\NdviJob',
    [string]$Out = 'D:\Web\NTPC_FECM\NDVI\Tiles',
    [int]$Retries = 3,
    [int]$RetryDelayMin = 30
)

$ErrorActionPreference = 'Continue'
$py = Join-Path $Root 'venv\Scripts\python.exe'
$script = Join-Path $Root 'ndvi_build.py'
$work = Join-Path $Root 'work'
$logDir = Join-Path $work 'logs'
$lock = Join-Path $work 'run.lock'

New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$runLog = Join-Path $logDir ('run_{0}.log' -f (Get-Date -Format 'yyyyMMdd_HHmmss'))

function Write-Log([string]$msg) {
    $line = '{0}  {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $msg
    Write-Host $line
    Add-Content -Path $runLog -Value $line -Encoding UTF8
}

function Write-EventSafe([string]$type, [int]$id, [string]$msg) {
    try {
        Write-EventLog -LogName Application -Source 'NdviJob' -EntryType $type -EventId $id -Message $msg -ErrorAction Stop
    } catch { }
}

if (-not (Test-Path $py)) { Write-Log "找不到 Python: $py"; exit 1 }
if (-not (Test-Path $script)) { Write-Log "找不到腳本: $script"; exit 1 }

# 單一實例鎖: 6 小時內視為仍在執行
if (Test-Path $lock) {
    $age = (Get-Date) - (Get-Item $lock).LastWriteTime
    if ($age.TotalHours -lt 6) {
        Write-Log "已有另一個實例執行中 (鎖定檔 $([int]$age.TotalMinutes) 分鐘前建立)，本次略過"
        exit 2
    }
    Write-Log "發現過期鎖定檔 (>6h)，視為前次異常中斷，繼續執行"
}
Set-Content -Path $lock -Value (Get-Date -Format 's') -Encoding ASCII

$exit = 1
try {
    $args2 = @($script, '--out', $Out, '--work', $work)
    if ($Month -ne '') { $args2 += @('--month', $Month) }

    for ($i = 1; $i -le $Retries; $i++) {
        Write-Log ("=== 第 {0}/{1} 次執行: python {2}" -f $i, $Retries, ($args2 -join ' '))
        & $py @args2 2>&1 | ForEach-Object { Add-Content -Path $runLog -Value $_.ToString() -Encoding UTF8 }
        $exit = $LASTEXITCODE
        if ($exit -eq 0) { break }
        Write-Log "執行失敗 (結束代碼 $exit)"
        if ($i -lt $Retries) {
            Write-Log "等待 $RetryDelayMin 分鐘後重試"
            Start-Sleep -Seconds ($RetryDelayMin * 60)
        }
    }

    if ($exit -eq 0) {
        Write-Log 'NDVI 更新完成'
        Write-EventSafe 'Information' 1000 "NDVI 月報更新完成。記錄: $runLog"
    } else {
        Write-Log 'NDVI 更新失敗，舊資料保持不變'
        Write-EventSafe 'Error' 1001 "NDVI 月報更新失敗 (已重試 $Retries 次)，舊資料保持不變。記錄: $runLog"
        Set-Content -Path (Join-Path $logDir 'LAST_FAILED.txt') -Value ("{0}`r`n{1}" -f (Get-Date -Format 's'), $runLog) -Encoding UTF8
    }
}
finally {
    Remove-Item -Path $lock -Force -ErrorAction SilentlyContinue
    # 清理 180 天前的執行記錄
    Get-ChildItem -Path $logDir -Filter '*.log' -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-180) } |
        Remove-Item -Force -ErrorAction SilentlyContinue
}
exit $exit
