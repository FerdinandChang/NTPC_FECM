-- ==================================================================================
-- 蝟餌絞?典?雿平蝔賣?亥?鞈?銵?(Sys_AuditLog) DDL ?單
-- 撠?嚗???箏?皞Ｘ皞恣?像??(NTPC_FEC)
-- 隤芣?嚗絞銝閮?蝟餌絞??甇瑞?嚗perator?ction?arget?P??????批捆????批捆??閮鳴?
-- ==================================================================================

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Sys_AuditLog')
BEGIN
    CREATE TABLE [dbo].[Sys_AuditLog] (
        [LogId] BIGINT IDENTITY(1,1) NOT NULL,
        [Operator] NVARCHAR(50) NOT NULL,
        [Action] NVARCHAR(50) NOT NULL,
        [Target] NVARCHAR(100) NULL,
        [IP] VARCHAR(50) NULL,
        [LogTime] DATETIME NOT NULL CONSTRAINT [DF_Sys_AuditLog_LogTime] DEFAULT (GETDATE()),
        [OldValue] NVARCHAR(MAX) NULL,
        [NewValue] NVARCHAR(MAX) NULL,
        [Details] NVARCHAR(MAX) NULL,
        CONSTRAINT [PK_Sys_AuditLog] PRIMARY KEY CLUSTERED ([LogId] ASC)
    );

    -- 撱箇?撣貊?亥岷蝝Ｗ?隞交??里?豢炎蝝Ｘ???    CREATE NONCLUSTERED INDEX [IX_Sys_AuditLog_LogTime] 
        ON [dbo].[Sys_AuditLog] ([LogTime] DESC);

    CREATE NONCLUSTERED INDEX [IX_Sys_AuditLog_Operator] 
        ON [dbo].[Sys_AuditLog] ([Operator] ASC, [LogTime] DESC);

    CREATE NONCLUSTERED INDEX [IX_Sys_AuditLog_Action] 
        ON [dbo].[Sys_AuditLog] ([Action] ASC, [LogTime] DESC);

    CREATE NONCLUSTERED INDEX [IX_Sys_AuditLog_Target] 
        ON [dbo].[Sys_AuditLog] ([Target] ASC, [LogTime] DESC);

    PRINT '?????” [dbo].[Sys_AuditLog] ?揣撘歇?撱箇?嚗?;
END
ELSE
BEGIN
    PRINT '??蝷箝??” [dbo].[Sys_AuditLog] 撌脣??剁?瑼Ｘ?臬?鋆?甈?...';

    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Sys_AuditLog') AND name = 'OldValue')
    BEGIN
        ALTER TABLE [dbo].[Sys_AuditLog] ADD [OldValue] NVARCHAR(MAX) NULL;
        PRINT '  -> 撌脰???雿?[OldValue]';
    END

    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Sys_AuditLog') AND name = 'NewValue')
    BEGIN
        ALTER TABLE [dbo].[Sys_AuditLog] ADD [NewValue] NVARCHAR(MAX) NULL;
        PRINT '  -> 撌脰???雿?[NewValue]';
    END

    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Sys_AuditLog') AND name = 'Details')
    BEGIN
        ALTER TABLE [dbo].[Sys_AuditLog] ADD [Details] NVARCHAR(MAX) NULL;
        PRINT '  -> 撌脰???雿?[Details]';
    END
END
GO

