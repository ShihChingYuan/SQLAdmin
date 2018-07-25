USE [master]
GO

PRINT N'1. 啟用 sa'
/*
	ALTER LOGIN sa ENABLE
	GO
*/

PRINT N'2. 修改 sa 並預設登入參數'
/*
	ALTER LOGIN [sa] WITH
	PASSWORD = 'SQLServer4MKC!ytsys'
	, DEFAULT_DATABASE = [tempdb]
	, DEFAULT_LANGUAGE = [繁體中文]
	, CHECK_EXPIRATION = OFF
	, CHECK_POLICY = OFF
	GO
*/

PRINT N'3. 確定主機名稱是否有異動'
IF (@@servername <> CONVERT(NVARCHAR(255), SERVERPROPERTY('servername')))
PRINT N'==> 有異動'
ELSE
PRINT N'==> 無異動'

/* 
	--調整主機名稱
	SELECT @@servername AS [主機名稱]
	, 'sp_dropserver ''' + @@servername + ''' --刪除舊主機' AS [SQLScripts]
	UNION ALL
	SELECT CONVERT(NVARCHAR(255), SERVERPROPERTY('servername')) AS [新主機名稱]
	, 'sp_addserver ''' + CONVERT(NVARCHAR(255), SERVERPROPERTY('servername')) + ''', local --加入新主機' AS [SQLScripts]

	--重新加入管理者帳號
	SELECT
	'DROP LOGIN [' + [name] + ']' AS [DROP]
	, 'CREATE LOGIN [' + CONVERT(NVARCHAR(255), SERVERPROPERTY('servername')) + '\Administrator] FROM WINDOWS WITH DEFAULT_DATABASE = [tempdb]' AS [CREATE]
	, 'EXEC master..sp_addsrvrolemember @loginame = N''' + CONVERT(NVARCHAR(255), SERVERPROPERTY('servername')) + '\Administrator'', @rolename = N''sysadmin''' AS [GRANT]
	--, *
	FROM sys.syslogins
	WHERE [name] LIKE '%\Administrator'
*/

/*
	--有可能 db_owner 掛在原 Windows 驗證帳號底下，需先更改擁有者
	USE [ReportServer]
	GO
	EXEC dbo.sp_changedbowner @loginame = N'sa', @map = false
	GO
	USE [ReportServerTempDB]
	GO
	EXEC dbo.sp_changedbowner @loginame = N'sa', @map = false
	GO

	--有可能 SQLAgent 掛在原 Windows 驗證帳號底下，需先更改擁有者
	USE [msdb]
	GO
	EXEC msdb.dbo.sp_update_job @job_id=N'2b7a1d8d-1188-4ef3-ab3e-0993a36110fc', 
		@owner_login_name=N'sa'
	GO
	USE [msdb]
	GO
	EXEC msdb.dbo.sp_update_job @job_id=N'cebd43b0-89b7-4e6e-a680-88c61b811748', 
		@owner_login_name=N'sa'
	GO
*/

PRINT N'4. 啟用遠端查詢'
/*
	EXEC sp_configure 'show advanced options',1
	RECONFIGURE WITH OVERRIDE

	EXEC sp_configure 'Ad Hoc Distributed Queries',1
	RECONFIGURE WITH OVERRIDE
*/

PRINT N'5. 設定維護計畫用指令'
/*
	SELECT 'ALTER DATABASE [' + [name] + '] SET RECOVERY SIMPLE WITH NO_WAIT' AS [SIMPLE]
	FROM SYS.databases
	WHERE [state_desc] IN ('ONLINE') AND [name] NOT IN ('master', 'tempdb')
	ORDER BY [database_id]
*/
USE [master]
GO

/*
	SELECT 'ALTER DATABASE [' + [name] + '] SET RECOVERY FULL WITH NO_WAIT' AS [FULL]
	FROM SYS.databases
	WHERE [state_desc] IN ('ONLINE') AND [name] NOT LIKE '%tempdb%'
	ORDER BY [database_id]
*/
USE [master]
GO


