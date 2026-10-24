# 註冊 / 移除 NDVI 月報排程 (Windows PowerShell 5.1+, 請以「系統管理員」執行)
# 預設: 每月 2 日 03:00 以 SYSTEM 執行 Run-NdviBuild.ps1 (取上個月影像; 2 日是因為月底影像在 STAC 約有 1~2 天延遲)
# 用法:
#   註冊: powershell -ExecutionPolicy Bypass -File D:\NdviJob\Register-NdviTask.ps1
#   移除: powershell -ExecutionPolicy Bypass -File D:\NdviJob\Register-NdviTask.ps1 -Remove
#   立即測試一次: schtasks /Run /TN NTPC_FEC_NDVI_Monthly

param(
    [string]$Root = 'D:\NdviJob',
    [int]$Day = 2,
    [string]$Time = '03:00',
    [string]$TaskName = 'NTPC_FEC_NDVI_Monthly',
    [switch]$Remove
)

if ($Remove) {
    schtasks.exe /Delete /TN $TaskName /F
    exit $LASTEXITCODE
}

$runner = Join-Path $Root 'Run-NdviBuild.ps1'
if (-not (Test-Path $runner)) { Write-Host "找不到 $runner" -ForegroundColor Red; exit 1 }

# 事件檢視器來源 (Application 記錄檔)
try {
    if (-not [System.Diagnostics.EventLog]::SourceExists('NdviJob')) {
        New-EventLog -LogName Application -Source 'NdviJob'
    }
} catch { Write-Host "建立事件來源失敗 (可忽略): $($_.Exception.Message)" -ForegroundColor Yellow }

$start = (Get-Date).ToString('yyyy-MM-dd') + 'T' + $Time + ':00'
$xml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Description>NTPC_FEC 新北市 NDVI 月報圖磚自動更新 (Sentinel-2)，保留最近 6 期</Description>
  </RegistrationInfo>
  <Triggers>
    <CalendarTrigger>
      <StartBoundary>$start</StartBoundary>
      <Enabled>true</Enabled>
      <ScheduleByMonth>
        <DaysOfMonth><Day>$Day</Day></DaysOfMonth>
        <Months>
          <January/><February/><March/><April/><May/><June/><July/><August/><September/><October/><November/><December/>
        </Months>
      </ScheduleByMonth>
    </CalendarTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>S-1-5-18</UserId>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <StartWhenAvailable>true</StartWhenAvailable>
    <ExecutionTimeLimit>PT6H</ExecutionTimeLimit>
    <Enabled>true</Enabled>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>powershell.exe</Command>
      <Arguments>-NoProfile -ExecutionPolicy Bypass -File "$runner"</Arguments>
      <WorkingDirectory>$Root</WorkingDirectory>
    </Exec>
  </Actions>
</Task>
"@

$tmp = Join-Path $env:TEMP 'ntpc_ndvi_task.xml'
Set-Content -Path $tmp -Value $xml -Encoding Unicode
schtasks.exe /Create /TN $TaskName /XML $tmp /F
$code = $LASTEXITCODE
Remove-Item $tmp -Force -ErrorAction SilentlyContinue
if ($code -eq 0) {
    Write-Host "`n已註冊排程 $TaskName (每月 $Day 日 $Time，SYSTEM)。" -ForegroundColor Green
    Write-Host "立即測試: schtasks /Run /TN $TaskName   查看: schtasks /Query /TN $TaskName /V /FO LIST" -ForegroundColor Cyan
}
exit $code
