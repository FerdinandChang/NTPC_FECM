-- ====================================================================
-- 新北市固定逸散源管理平台 (NTPC_FEC)
-- 道路破損現場通報與處理回報欄位擴充腳本 (對標路平報馬仔規格 + 保留舊資料向下相容)
-- ====================================================================

-- 1. 路面損壞-類別 (路面損壞 / 交通標線損壞不良)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('RoadBreak_CaseMain') AND name = 'Damage_Category')
BEGIN
    ALTER TABLE RoadBreak_CaseMain ADD Damage_Category nvarchar(50) NULL;
    PRINT 'Added column Damage_Category';
END
GO

-- 2. 路面損壞-性質 (坑洞 / 龜裂 / 凹陷 / 人手孔蓋週邊破損 / 人手孔蓋欠平順 / 補綻(臨補))
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('RoadBreak_CaseMain') AND name = 'Damage_Type')
BEGIN
    ALTER TABLE RoadBreak_CaseMain ADD Damage_Type nvarchar(50) NULL;
    PRINT 'Added column Damage_Type';
END
GO

-- 3. 損壞尺寸 - 長 (公尺 m)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('RoadBreak_CaseMain') AND name = 'Damage_Length')
BEGIN
    ALTER TABLE RoadBreak_CaseMain ADD Damage_Length decimal(8,2) NULL;
    PRINT 'Added column Damage_Length';
END
GO

-- 4. 損壞尺寸 - 寬 (公尺 m)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('RoadBreak_CaseMain') AND name = 'Damage_Width')
BEGIN
    ALTER TABLE RoadBreak_CaseMain ADD Damage_Width decimal(8,2) NULL;
    PRINT 'Added column Damage_Width';
END
GO

-- 5. 地點描述 (例如便利商店前、路燈編號370050前方...)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('RoadBreak_CaseMain') AND name = 'Location_Desc')
BEGIN
    ALTER TABLE RoadBreak_CaseMain ADD Location_Desc nvarchar(255) NULL;
    PRINT 'Added column Location_Desc';
END
GO

-- 6. 車道 (路口、車道1~5、車道交界處、全車道 - 複選逗號串接)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('RoadBreak_CaseMain') AND name = 'Lane_Info')
BEGIN
    ALTER TABLE RoadBreak_CaseMain ADD Lane_Info nvarchar(150) NULL;
    PRINT 'Added column Lane_Info';
END
GO

-- 7. 方向 (單號 / 雙號 / 無法判定)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('RoadBreak_CaseMain') AND name = 'Direction')
BEGIN
    ALTER TABLE RoadBreak_CaseMain ADD Direction nvarchar(50) NULL;
    PRINT 'Added column Direction';
END
GO

-- 8. 道路型態 (平面 / 非平面)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('RoadBreak_CaseMain') AND name = 'Road_Type')
BEGIN
    ALTER TABLE RoadBreak_CaseMain ADD Road_Type nvarchar(50) NULL;
    PRINT 'Added column Road_Type';
END
GO

-- ====================================================================
-- 處理回報擴充欄位 (對標新北市路平報馬仔系統回報與結案回覆)
-- ====================================================================

-- 9. 損壞處數 (預設 1 處)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('RoadBreak_CaseMain') AND name = 'Damage_Count')
BEGIN
    ALTER TABLE RoadBreak_CaseMain ADD Damage_Count nvarchar(50) NULL;
    PRINT 'Added column Damage_Count';
END
GO

-- 10. 後續修復情形 (例如：現況輕微龜裂屬堪用，持續追蹤加強巡查 / 已完成刨鋪改善 / 暫補完成...)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('RoadBreak_CaseMain') AND name = 'G_Fix_Status')
BEGIN
    ALTER TABLE RoadBreak_CaseMain ADD G_Fix_Status nvarchar(100) NULL;
    PRINT 'Added column G_Fix_Status';
END
GO

-- 11. 承辦人聯絡電話
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('RoadBreak_CaseMain') AND name = 'G_Contact_Phone')
BEGIN
    ALTER TABLE RoadBreak_CaseMain ADD G_Contact_Phone nvarchar(50) NULL;
    PRINT 'Added column G_Contact_Phone';
END
GO

-- 12. 完工回報日期時間
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('RoadBreak_CaseMain') AND name = 'G_Report_Date')
BEGIN
    ALTER TABLE RoadBreak_CaseMain ADD G_Report_Date datetime NULL;
    PRINT 'Added column G_Report_Date';
END
GO

-- 13. 延遲原因 (若逾期完工回報時填寫)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('RoadBreak_CaseMain') AND name = 'G_Delay_Reason')
BEGIN
    ALTER TABLE RoadBreak_CaseMain ADD G_Delay_Reason nvarchar(255) NULL;
    PRINT 'Added column G_Delay_Reason';
END
GO

-- 14. 結案回覆方式 (網路回覆 / 電話回覆 / 書面回覆)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('RoadBreak_CaseMain') AND name = 'G_Reply_Type')
BEGIN
    ALTER TABLE RoadBreak_CaseMain ADD G_Reply_Type nvarchar(50) NULL;
    PRINT 'Added column G_Reply_Type';
END
GO

-- 15. 結案回覆說明公文內容
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('RoadBreak_CaseMain') AND name = 'G_Reply_Memo')
BEGIN
    ALTER TABLE RoadBreak_CaseMain ADD G_Reply_Memo nvarchar(max) NULL;
    PRINT 'Added column G_Reply_Memo';
END
GO

-- 16. 結案回覆時間
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('RoadBreak_CaseMain') AND name = 'G_Reply_Date')
BEGIN
    ALTER TABLE RoadBreak_CaseMain ADD G_Reply_Date datetime NULL;
    PRINT 'Added column G_Reply_Date';
END
GO

-- 17. 處理單位(公所) (對標路平系統：例如石門區公所)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('RoadBreak_CaseMain') AND name = 'District_Office')
BEGIN
    ALTER TABLE RoadBreak_CaseMain ADD District_Office nvarchar(100) NULL;
    PRINT 'Added column District_Office';
END
GO

-- 18. 處理單位 (對標路平系統：例如健利營造有限公司或機關自行修補)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('RoadBreak_CaseMain') AND name = 'Handle_Unit')
BEGIN
    ALTER TABLE RoadBreak_CaseMain ADD Handle_Unit nvarchar(100) NULL;
    PRINT 'Added column Handle_Unit';
END
GO

-- 19. 處理狀態 (對標路平系統：例如機關自行修補、已改善完成)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('RoadBreak_CaseMain') AND name = 'Handle_Status')
BEGIN
    ALTER TABLE RoadBreak_CaseMain ADD Handle_Status nvarchar(100) NULL;
    PRINT 'Added column Handle_Status';
END
GO

-- 20. 路平報馬仔系統反映編號 (例如 2078092)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('RoadBreak_CaseMain') AND name = 'RDM_Case_ID')
BEGIN
    ALTER TABLE RoadBreak_CaseMain ADD RDM_Case_ID nvarchar(50) NULL;
    PRINT 'Added column RDM_Case_ID';
END
GO

-- 21. 是否建議持續追蹤列管 ('Y' = 建議持續追蹤, 'N' = 正常結案)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('RoadBreak_CaseMain') AND name = 'Need_Follow')
BEGIN
    ALTER TABLE RoadBreak_CaseMain ADD Need_Follow char(1) NULL;
    PRINT 'Added column Need_Follow';
END
GO

-- 22. 建議持續追蹤事項說明
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('RoadBreak_CaseMain') AND name = 'Follow_Memo')
BEGIN
    ALTER TABLE RoadBreak_CaseMain ADD Follow_Memo nvarchar(500) NULL;
    PRINT 'Added column Follow_Memo';
END
GO

-- 23. 損壞型式(PCI) (例如：線狀裂縫)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('RoadBreak_CaseMain') AND name = 'PCI_Type')
BEGIN
    ALTER TABLE RoadBreak_CaseMain ADD PCI_Type nvarchar(100) NULL;
    PRINT 'Added column PCI_Type';
END
GO

-- 24. 嚴重程度(PCI) (例如：輕、中、重)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('RoadBreak_CaseMain') AND name = 'PCI_Severity')
BEGIN
    ALTER TABLE RoadBreak_CaseMain ADD PCI_Severity nvarchar(50) NULL;
    PRINT 'Added column PCI_Severity';
END
GO

-- 25. 監造建議修補事項 (例如：尚未設定)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('RoadBreak_CaseMain') AND name = 'Supervisor_Suggest')
BEGIN
    ALTER TABLE RoadBreak_CaseMain ADD Supervisor_Suggest nvarchar(255) NULL;
    PRINT 'Added column Supervisor_Suggest';
END
GO

-- 26. 養工處分派說明
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('RoadBreak_CaseMain') AND name = 'Dispatch_Memo')
BEGIN
    ALTER TABLE RoadBreak_CaseMain ADD Dispatch_Memo nvarchar(500) NULL;
    PRINT 'Added column Dispatch_Memo';
END
GO

-- 27. 完工日期(派工) (例如：無派工 或 日期字串)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('RoadBreak_CaseMain') AND name = 'Dispatch_Done_Date')
BEGIN
    ALTER TABLE RoadBreak_CaseMain ADD Dispatch_Done_Date nvarchar(50) NULL;
    PRINT 'Added column Dispatch_Done_Date';
END
GO

-- 28. 完工回報日期(派工) (例如：無派工 或 日期字串)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('RoadBreak_CaseMain') AND name = 'Dispatch_Report_Date')
BEGIN
    ALTER TABLE RoadBreak_CaseMain ADD Dispatch_Report_Date nvarchar(50) NULL;
    PRINT 'Added column Dispatch_Report_Date';
END
GO

PRINT '=======================================================';
PRINT 'RoadBreak_CaseMain 通報與處理回報欄位擴充完畢 (舊欄位 100% 保留)';
PRINT '=======================================================';
