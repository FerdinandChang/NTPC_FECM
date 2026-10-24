@echo off
chcp 65001 >nul
title NTPC_FEC NDVI Monthly Builder
cd /d D:\NdviJob
echo === 開始產出 NDVI 月報圖磚 ===
D:\NdviJob\venv\Scripts\python.exe ndvi_build.py --out D:\Web\NTPC_FECM\NDVI\Tiles --work D:\NdviJob\work
set EXIT_CODE=%ERRORLEVEL%
if %EXIT_CODE% equ 0 (
    echo === 產出成功，設定 IIS 存取權限 ===
    icacls "D:\Web\NTPC_FECM\NDVI\Tiles" /grant "IIS_IUSRS:(OI)(CI)RX" /grant "IUSR:(OI)(CI)RX" /T >nul
    echo === 全部完成 ===
) else (
    echo === 執行失敗，結束代碼: %EXIT_CODE% ===
)
exit /b %EXIT_CODE%
