<#
.SYNOPSIS
    新北市固定溢散源管理平台 (NTPC_FEC)
    道路髒污案件 (RoadDirty_CaseMain) - TWD97 坐標批次轉換 WGS84 經緯度工具
#>

[CmdletBinding()]
param(
    [string]$Server = "",
    [string]$Database = "NTPC_FEC",
    [string]$User = "epd",
    [string]$Password = "epd123"
)

# 1. 載入高精度 TWD97 轉 WGS84 C# 核心計算函式庫
$csharpCode = @"
using System;

public static class CoordConverter
{
    public static void Twd97ToWgs84(double x, double y, out double lat, out double lon)
    {
        if (x <= 0 || y <= 0) { lat = 0; lon = 0; return; }

        double a = 6378137.0;
        double b = 6356752.314245;
        double lon0 = 121.0 * Math.PI / 180.0;
        double k0 = 0.9999;
        double dx = 250000.0;

        double e = Math.Sqrt(1.0 - (b * b) / (a * a));
        double e2 = e * e / (1.0 - e * e);
        x -= dx;

        double M = y / k0;
        double mu = M / (a * (1.0 - Math.Pow(e, 2) / 4.0 - 3.0 * Math.Pow(e, 4) / 64.0 - 5.0 * Math.Pow(e, 6) / 256.0));
        double e1 = (1.0 - Math.Sqrt(1.0 - Math.Pow(e, 2))) / (1.0 + Math.Sqrt(1.0 - Math.Pow(e, 2)));

        double J1 = (3.0 * e1 / 2.0 - 27.0 * Math.Pow(e1, 3) / 32.0);
        double J2 = (21.0 * Math.Pow(e1, 2) / 16.0 - 55.0 * Math.Pow(e1, 4) / 32.0);
        double J3 = (151.0 * Math.Pow(e1, 3) / 96.0);
        double J4 = (1097.0 * Math.Pow(e1, 4) / 512.0);

        double fp = mu + J1 * Math.Sin(2.0 * mu) + J2 * Math.Sin(4.0 * mu) + J3 * Math.Sin(6.0 * mu) + J4 * Math.Sin(8.0 * mu);

        double C1 = e2 * Math.Pow(Math.Cos(fp), 2);
        double T1 = Math.Pow(Math.Tan(fp), 2);
        double R1 = a * (1.0 - Math.Pow(e, 2)) / Math.Pow(1.0 - Math.Pow(e, 2) * Math.Pow(Math.Sin(fp), 2), 1.5);
        double N1 = a / Math.Sqrt(1.0 - Math.Pow(e, 2) * Math.Pow(Math.Sin(fp), 2));
        double D = x / (N1 * k0);

        double latRad = fp - (N1 * Math.Tan(fp) / R1) * (Math.Pow(D, 2) / 2.0 - (5.0 + 3.0 * T1 + 10.0 * C1 - 4.0 * Math.Pow(C1, 2) - 9.0 * e2) * Math.Pow(D, 4) / 24.0 + (61.0 + 90.0 * T1 + 298.0 * C1 + 45.0 * Math.Pow(T1, 2) - 252.0 * e2 - 3.0 * Math.Pow(C1, 2)) * Math.Pow(D, 6) / 720.0);
        double lonRad = lon0 + (D - (1.0 + 2.0 * T1 + C1) * Math.Pow(D, 3) / 6.0 + (5.0 - 2.0 * C1 + 28.0 * T1 - 3.0 * Math.Pow(C1, 2) + 8.0 * e2 + 24.0 * Math.Pow(T1, 2)) * Math.Pow(D, 5) / 120.0) / Math.Cos(fp);

        lat = Math.Round(latRad * 180.0 / Math.PI, 6);
        lon = Math.Round(lonRad * 180.0 / Math.PI, 6);
    }
}
"@

if (-not ([System.Management.Automation.PSTypeName]'CoordConverter').Type) {
    Add-Type -TypeDefinition $csharpCode
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  新北市固定溢散源 - 道路髒污坐標批次轉換 WGS84 工具" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan

# 2. 自動嘗試連線候選伺服器
$candidates = @()
if ($Server -ne "") {
    $candidates += $Server
} else {
    $candidates += "EPB-AIR-WEB1\SQLEXPRESS2017"
    $candidates += ".\SQLEXPRESS2017"
    $candidates += "localhost\SQLEXPRESS2017"
    $candidates += "127.0.0.1\SQLEXPRESS2017"
    $candidates += "."
    $candidates += "localhost"
}

$conn = $null
$connectedServer = ""

foreach ($cand in $candidates) {
    $connStr = "Data Source=$cand;Initial Catalog=$Database;User ID=$User;Password=$Password;Connect Timeout=3"
    $testConn = New-Object System.Data.SqlClient.SqlConnection($connStr)
    try {
        Write-Host "正在嘗試連線到 [$cand]..." -NoNewline
        $testConn.Open()
        Write-Host " [連線成功!]" -ForegroundColor Green
        $conn = $testConn
        $connectedServer = $cand
        break
    }
    catch {
        Write-Host " [連線逾時或無法訪問]" -ForegroundColor DarkGray
        $testConn.Dispose()
    }
}

if ($conn -eq $null) {
    Write-Host "`n[錯誤] 無法連線至 SQL Server，請確認 SQL Server 服務已啟動或以 -Server 參數指定正確主機名稱。" -ForegroundColor Red
    Write-Host "範例: .\Convert_Dirty_Coordinates.ps1 -Server '您的資料庫主機名稱或IP'" -ForegroundColor Yellow
    exit 1
}

try {
    # 3. 確保 RoadDirty_CaseMain 具備 S_LON, S_LAT, S_LON1, S_LAT1 欄位
    Write-Host "`n[1/3] 檢查並補齊經緯度欄位 (S_LON, S_LAT, S_LON1, S_LAT1)..." -NoNewline
    $alterSql = @"
        IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('RoadDirty_CaseMain') AND name = 'S_LON')
            ALTER TABLE RoadDirty_CaseMain ADD S_LON float NULL;
        IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('RoadDirty_CaseMain') AND name = 'S_LAT')
            ALTER TABLE RoadDirty_CaseMain ADD S_LAT float NULL;
        IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('RoadDirty_CaseMain') AND name = 'S_LON1')
            ALTER TABLE RoadDirty_CaseMain ADD S_LON1 float NULL;
        IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('RoadDirty_CaseMain') AND name = 'S_LAT1')
            ALTER TABLE RoadDirty_CaseMain ADD S_LAT1 float NULL;
"@
    $alterCmd = $conn.CreateCommand()
    $alterCmd.CommandText = $alterSql
    $alterCmd.ExecuteNonQuery() | Out-Null
    Write-Host " [完成]" -ForegroundColor Green

    # 4. 讀取需轉換之資料
    Write-Host "[2/3] 撈取具備 TWD97 坐標之案件紀錄..." -NoNewline
    $selectSql = @"
        SELECT Dirty_ID, S_UTME, S_UTMN, 
               CASE WHEN COL_LENGTH('RoadDirty_CaseMain', 'S_UTME1') IS NOT NULL THEN S_UTME1 ELSE NULL END AS S_UTME1,
               CASE WHEN COL_LENGTH('RoadDirty_CaseMain', 'S_UTMN1') IS NOT NULL THEN S_UTMN1 ELSE NULL END AS S_UTMN1
        FROM RoadDirty_CaseMain
        WHERE (S_UTME > 0 AND S_UTMN > 0)
"@
    $cmd = $conn.CreateCommand()
    $cmd.CommandText = $selectSql
    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter($cmd)
    $dt = New-Object System.Data.DataTable
    $adapter.Fill($dt) | Out-Null
    Write-Host " [共 $($dt.Rows.Count) 筆]" -ForegroundColor Yellow

    if ($dt.Rows.Count -eq 0) {
        Write-Host "目前沒有需要轉換的案件紀錄。" -ForegroundColor Cyan
        return
    }

    # 5. 批次計算並更新
    Write-Host "[3/3] 正在逐筆轉換並更新經緯度至資料庫..." -ForegroundColor Cyan

    $tran = $conn.BeginTransaction()
    $updateCmd = $conn.CreateCommand()
    $updateCmd.Transaction = $tran
    $updateCmd.CommandText = @"
        UPDATE RoadDirty_CaseMain 
        SET S_LON = @lon, S_LAT = @lat, S_LON1 = @lon1, S_LAT1 = @lat1
        WHERE Dirty_ID = @id
"@
    $pId = $updateCmd.Parameters.Add("@id", [System.Data.SqlDbType]::VarChar, 50)
    $pLon = $updateCmd.Parameters.Add("@lon", [System.Data.SqlDbType]::Float)
    $pLat = $updateCmd.Parameters.Add("@lat", [System.Data.SqlDbType]::Float)
    $pLon1 = $updateCmd.Parameters.Add("@lon1", [System.Data.SqlDbType]::Float)
    $pLat1 = $updateCmd.Parameters.Add("@lat1", [System.Data.SqlDbType]::Float)

    $count = 0
    $total = $dt.Rows.Count

    foreach ($row in $dt.Rows) {
        $dirtyId = $row["Dirty_ID"].ToString()
        $utmE = [double]$row["S_UTME"]
        $utmN = [double]$row["S_UTMN"]

        $lat = 0.0; $lon = 0.0
        [CoordConverter]::Twd97ToWgs84($utmE, $utmN, [ref]$lat, [ref]$lon)

        $lat1 = 0.0; $lon1 = 0.0
        if ($row["S_UTME1"] -ne [DBNull]::Value -and $row["S_UTMN1"] -ne [DBNull]::Value) {
            $utmE1 = [double]$row["S_UTME1"]
            $utmN1 = [double]$row["S_UTMN1"]
            if ($utmE1 -gt 0 -and $utmN1 -gt 0) {
                [CoordConverter]::Twd97ToWgs84($utmE1, $utmN1, [ref]$lat1, [ref]$lon1)
            }
        }

        $pId.Value = $dirtyId
        $pLon.Value = if ($lon -gt 0) { $lon } else { [DBNull]::Value }
        $pLat.Value = if ($lat -gt 0) { $lat } else { [DBNull]::Value }
        $pLon1.Value = if ($lon1 -gt 0) { $lon1 } else { [DBNull]::Value }
        $pLat1.Value = if ($lat1 -gt 0) { $lat1 } else { [DBNull]::Value }

        $updateCmd.ExecuteNonQuery() | Out-Null
        $count++

        if ($count % 50 -eq 0 -or $count -eq $total) {
            $pct = [math]::Round(($count / $total) * 100, 1)
            Write-Progress -Activity "轉換經緯度坐標並更新至資料庫" -Status "$count / $total ($pct%)" -PercentComplete $pct
        }
    }

    $tran.Commit()
    Write-Host "`n[成功完成] 已全數將 $count 筆案件之經緯度 (S_LON, S_LAT) 更新至資料庫！" -ForegroundColor Green
    Write-Host "==========================================================" -ForegroundColor Cyan
}
catch {
    if ($tran -ne $null) { $tran.Rollback() }
    Write-Host "`n[執行發生錯誤] $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    $conn.Close()
}
