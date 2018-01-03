/*
    查詢資料庫主機資訊
*/
--:CONNECT dbtest.ytdt.sys    --Microsoft SQL Server  2000 - 8.00.2055 (Intel X86)   Dec 16 2008 19:46:53   Copyright (c) 1988-2003 Microsoft Corporation  Enterprise Edition on Windows NT 5.2 (Build 3790: Service Pack 2) 
--:CONNECT dbpro2.ytdt.sys    --Windows NT 6.0 <X64> (Build 6002: Service Pack 2) 
--:CONNECT 192.168.2.104\SQLExpressR2 --Windows NT 6.1 <X86> (Build 7601: Service Pack 1) 
--:CONNECT dbmoss.ytdt.sys\SHAREPOINT --Windows NT 6.1 <X64> (Build 7601: Service Pack 1) (Hypervisor) 
SELECT
    @@servername AS [伺服器名稱] 
    , RIGHT(@@VERSION, LEN(@@VERSION)- 3 - charindex(' ON ', @@VERSION)) AS [Windows 伺服器]
    , [cpu_count] AS [邏輯 CPU 數]
    , [cpu_count]/[hyperthread_ratio] AS [實體 CPU 數]
    , [physical_memory_in_bytes]/ 1024 / 1024 AS [實體 Memory 數量(MB)]
    , SERVERPROPERTY('ProductVersion') AS [執行個體的版本]
    , SERVERPROPERTY('ProductLevel') AS [執行個體的版本層級]
    , SERVERPROPERTY('Edition') AS [產品版本]
    , (
        CASE
            ISNULL(SERVERPROPERTY('InstanceName'),'')
            WHEN '' THEN N'預設執行個體'
            ELSE SERVERPROPERTY('InstanceName')
        END
    ) AS [執行個體名稱]
    , (
        CASE SERVERPROPERTY('IsClustered')
            WHEN 1 THEN N'叢集'
            WHEN 0 THEN N'非叢集'
            ELSE N'輸入無效，或發生錯誤'
        END
    ) AS [容錯移轉叢集]
    , 
    (
        CASE SERVERPROPERTY('LicenseType') 
            WHEN 'PER_SEAT' THEN N'每一基座模式'
            WHEN 'PER_PROCESSOR' THEN N'每一處理器模式'
            WHEN 'DISABLED' THEN N'停用授權'
            ELSE N'輸入無效，或發生錯誤'
        END
    ) AS [執行個體的模式]        
    , SERVERPROPERTY('NumLicenses') AS [授權數目]
    , SERVERPROPERTY('Collation') AS [伺服器預設定序]
FROM sys.dm_os_sys_info;
GO

SELECT
    [TBA].[name] AS [資料庫名稱]
    , [TBA].[compatibility_level] AS [相容性層級]
    , [TBA].[collation_name] AS [資料庫預設定序]
    , [TBA].[is_auto_close_on] AS [自動關閉]
    , [TBA].[is_auto_shrink_on] AS [自動壓縮]
    , [TBA].[recovery_model_desc] AS [復原模式]
FROM sys.databases AS [TBA]
WHERE UPPER([TBA].[name]) LIKE '%WEBFOLIO%' OR UPPER([TBA].[name]) LIKE '%WEBACKBONE%' OR UPPER([TBA].[name]) LIKE '%ALUMNUS%' OR UPPER([TBA].[name]) LIKE '%SURVEY%' OR UPPER([TBA].[name]) LIKE '%SSIDC%' OR UPPER([TBA].[name]) LIKE '%SCHOOL%' 
ORDER BY [TBA].[name]
GO

SELECT [name]
    , 'SELECT ''' + [name] + ''' AS [name], SUM([size])*8.0/1024 AS [資料庫大小(MB)] FROM ' + [name] + '.sys.database_files'
    , 'BACKUP DATABASE [' + [name] + '] TO  DISK = N''C:\TESTIO.bak'' WITH NOFORMAT, NOINIT,  NAME = N'''+[name]+'-完整 資料庫 備份'', SKIP, NOREWIND, NOUNLOAD,  STATS = 10'
FROM sys.databases
WHERE state_desc = 'ONLINE'
GO


/*
查詢資料庫線上使用狀況
*/
sp_who2

USE [master]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_who3]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[usp_who3]
GO

CREATE PROC [dbo].[usp_who3]
AS
BEGIN
	DECLARE @Table TABLE(
			[SPID] INT
			, [Status] VARCHAR(MAX)
			, [LOGIN] VARCHAR(MAX)
			, [HostName] VARCHAR(MAX)
			, [BlkBy] VARCHAR(MAX)
			, [DBName] VARCHAR(MAX)
			, [Command] VARCHAR(MAX)
			, [CPUTime] INT
			, [DiskIO] INT
			, [LastBatch] VARCHAR(MAX)
			, [ProgramName] VARCHAR(MAX)
			, [SPID_1] INT
			, [REQUESTID] INT
	)
	INSERT INTO @Table EXEC sp_who2

	SELECT
		'KILL ' + CAST(Sub.[SPID] AS VARCHAR(32)) 
		+ '	--' + Sub.[HostName] + '.(' + RTRIM(LTRIM(Sub.[ProgramName])) + ') == ' + Sub.[LOGIN] + ' ==> [' + Sub.[DBName] + '] BLOCKED!' AS BLOCKED
	FROM @Table AS Main
	LEFT JOIN @Table AS Sub
		ON Main.[SPID] = Sub.[SPID]
	WHERE Main.[BlkBy] <> '  .'

	----------------------------------------

	SELECT TOP 3
		[DBName]
		, COUNT(*) AS DBConnections
		, ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS ROWSORT
	FROM @Table
	GROUP BY [DBName]
	ORDER BY COUNT(*) DESC

	SELECT TOP 3
		[DBName], [HostName]
		, COUNT(*) AS DBConnections
		, ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS ROWSORT
	FROM @Table
	GROUP BY [DBName], [HostName]
	ORDER BY COUNT(*) DESC

	----------------------------------------

	SELECT TOP 3
		[HostName]
		, COUNT(*) AS DBConnections
		, ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS ROWSORT
	FROM @Table
	GROUP BY [HostName]
	ORDER BY COUNT(*) DESC

	SELECT TOP 3
		[HostName], [DBName]
		, COUNT(*) AS DBConnections
		, ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS ROWSORT
	FROM @Table
	GROUP BY [HostName], [DBName]
	ORDER BY COUNT(*) DESC
END
GO

EXEC [master].[dbo].[usp_who3]
GO


/*
列表資料庫
*/
USE master
SELECT 'USE '+name, * FROM sysdatabases
WHERE name like 'Webfolio%' OR name like 'Alumnus%' OR name = 'MDN_ERP' or name like 'Web%' or name like 'Survey%'
order by name

SELECT * FROM sysobjects

/*
列表資料表
*/
--Tables
USE mdn_erp
SELECT *
FROM INFORMATION_SCHEMA.TABLES

SELECT * FROM SYSVIEWS
--Views
USE mdn_erp
SELECT *
FROM INFORMATION_SCHEMA.VIEWS

--Columns
USE mdn_erp
SELECT *
FROM INFORMATION_SCHEMA.COLUMNS

--Function, Stored Procedure
USE mdn_erp
SELECT *
FROM INFORMATION_SCHEMA.ROUTINES 
WHERE ROUTINE_TYPE = 'PROCEDURE'

/*
偵測伺服器版本資訊
*/

SELECT
SERVERPROPERTY('ProductVersion') AS ProductVersion
, SERVERPROPERTY('Edition') AS Edition
, SERVERPROPERTY('ProductLevel') AS ProductLevel
, SERVERPROPERTY('EditionID') AS EditionID
, SERVERPROPERTY('EngineEdition') AS EngineEdition

--附加資料庫
USE [master]
GO
CREATE DATABASE [Webfolio_SSIDC_CGU] ON 
( FILENAME = N'D:\Microsoft SQL Server\MSSQL10.MSSQLSERVER\MSSQL\DATA\Webfolio_DB\Webfolio_SSIDC_CGU.mdf' ),
( FILENAME = N'D:\Microsoft SQL Server\MSSQL10.MSSQLSERVER\MSSQL\DATA\Webfolio_DB\Webfolio_SSIDC_CGU_1.ldf' )
 FOR ATTACH
GO
if exists (select name from master.sys.databases sd where name = N'Webfolio_SSIDC_CGU' and SUSER_SNAME(sd.owner_sid) = SUSER_SNAME() ) 
    EXEC [Webfolio_SSIDC_CGU].dbo.sp_changedbowner @loginame=N'sa', @map=false
GO

--卸載資料庫
USE [master]
GO
ALTER DATABASE [Webfolio_SSIDC_CGU] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
USE [master]
GO
EXEC master.dbo.sp_detach_db @dbname = N'Webfolio_SSIDC_CGU', @skipchecks = 'false'
GO



--全資料庫搜尋/取代特定字串
DECLARE @KeyWord NVARCHAR(4000)
SET @KeyWord = N'mkc'
DECLARE @ReplaceWord NVARCHAR(4000)
SET @ReplaceWord = N'mcut'

SELECT
	'IF EXISTS(SELECT * FROM [' + S.[name] + '].[' + T.[name] + '] WHERE [' + C.[name] + '] like ''%' + @KeyWord + '%'') 
	PRINT ''SELECT [' + C.[name] + '] AS [KEYWORD], ''''<-- FOUND!'''' , * FROM [' + S.[name] + '].[' + T.[name] + '] WHERE [' + C.[name] + '] like ''''%' + @KeyWord + '%'''' ''' AS [Key_SELECT]
	, 'IF EXISTS(SELECT * FROM [' + S.[name] + '].[' + T.[name] + '] WHERE [' + C.[name] + '] like ''%' + @KeyWord + '%'') 
	PRINT ''UPDATE [' + S.[name] + '].[' + T.[name] + '] SET [' + C.[name] + '] = REPLACE([' + C.[name] + '], N''''' + @KeyWord + ''''', N'''''+ @ReplaceWord + ''''') WHERE [' + C.[name] + '] like ''''%' + @KeyWord + '%'''' ''' AS [Key_UPDATE]
FROM sys.columns AS C
INNER JOIN sys.tables AS T
	ON C.[object_id] = T.[object_id]
INNER JOIN sys.schemas AS S
	ON T.[schema_id] = S.[schema_id]
INNER JOIN sys.types AS P
	ON C.[system_type_id] = P.[system_type_id]
	AND C.[user_type_id] = P.[user_type_id]
	AND P.[name] IN (
		'varchar', 'char', 'nvarchar', 'nchar'
	)
ORDER BY S.[schema_id], T.[name], C.[column_id]





--全資料庫搜尋特定字串
DROP PROC USP_SEARCHSTRING
GO

CREATE PROC USP_SEARCHSTRING
	@TableName VARCHAR(400)
AS
	DECLARE @S VARCHAR(8000)
	SET @S = ''
	SELECT @S = @S + TSQLScripts + ' UNION ALL ' 
	FROM
	(
		SELECT TABLE_NAME
			, 'SELECT * FROM [' + TABLE_SCHEMA + '].[' + TABLE_NAME + ']'
			+ ' WHERE ' + COLUMN_NAME + ' LIKE ''%台北%'' OR ' + COLUMN_NAME + ' LIKE''%台中%''' AS TSQLScripts	//可自行組合搜尋字串
		FROM INFORMATION_SCHEMA.COLUMNS
		WHERE DATA_TYPE IN ('nvarchar', 'nchar', 'varchar', 'char')
		AND CHARACTER_MAXIMUM_LENGTH > 1
		GROUP BY TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME
	) AS TBA
	WHERE TABLE_NAME = @TableName	
	SELECT SUBSTRING(@S, 0, Len(@s)-9) AS TSQLScripts
GO


SELECT 'EXEC USP_SEARCHSTRING ''' + TABLE_NAME + ''''
FROM INFORMATION_SCHEMA.COLUMNS
WHERE DATA_TYPE IN ('nvarchar', 'nchar', 'varchar', 'char')
AND CHARACTER_MAXIMUM_LENGTH > 1
GROUP BY TABLE_NAME


EXEC USP_SEARCHSTRING 'vSSStockRestructurePactReport'
EXEC USP_SEARCHSTRING 'vSSStockRestructureVaryReport'
EXEC USP_SEARCHSTRING 'vSSStockScrapPactReport'
EXEC USP_SEARCHSTRING 'vSSStockScrapVaryReport'

/*
搜尋全伺服器特定表格的特定欄位最長長度多少
*/
SELECT 'if EXISTS( SELECT * FROM '+name+'.sys.columns AS TBA left join '+name+'.sys.objects AS TBB on TBA.object_id = TBB.object_id WHERE TBA.name = ''re_position'' and TBB.name = ''Res_Exp'') '
+ 'begin SELECT '''+name+''' as name, max(len(RE_POSITION)) FROM ['+name+'].[dbo].[Res_Exp] end' FROM sys.databases
WHERE state_desc = 'ONLINE'

/*
搜尋全伺服器特定表格的特定欄位型態多少
*/
SELECT 'if EXISTS( SELECT * FROM '+name+'.sys.columns AS TBA left join '+name+'.sys.objects AS TBB on TBA.object_id = TBB.object_id WHERE TBA.name = ''re_position'' and TBB.name = ''Res_Exp'') '
+ 'begin  SELECT '''+name+''' as DatabaseName, TBB.name as TableName, TBA.name as ColumnName, USEr_type_id, max_length FROM '+name+'.sys.columns AS TBA left join '+name+'.sys.objects AS TBB on TBA.object_id = TBB.object_id WHERE TBA.name = ''re_position'' and TBB.name = ''Res_Exp'' end' FROM sys.databases
WHERE state_desc = 'ONLINE'



/*
設定資料庫復原模式
*/
Alter Database 	Webfolio_TEST	Set Recovery FULL

/*
	調整資料庫空間－切割資料庫＆搬家
	步驟 1. 先加入檔案
	步驟 2. 透過以下指令「擠壓」原本資料庫檔案，並平均分散至步驟一加入的檔案中
*/
DBCC SHOWFILESTATS
GO
DBCC SHRINKFILE('OrdHist2',EMPTYFILE)
GO


/*
壓縮資料庫紀錄檔至指定大小（Mb）
*/
EXEC sp_helpdb 'Webfolio_TEST'					--觀察資料庫屬性
DBCC SHRINKFILE ('Webfolio_TEST_log', 50);
/*
壓縮資料庫
*/
DBCC SHRINKDATABASE(N'Webfolio_TEST' )

--系統資料庫
SELECT 
    'ALTER DATABASE [' + [name] + '] SET RECOVERY SIMPLE WITH NO_WAIT' 
    , 'DBCC SHRINKDATABASE(''' + [name] + ''')'
    , 'ALTER DATABASE [' + [name] + '] SET RECOVERY FULL WITH NO_WAIT' 
FROM SYS.databases
WHERE 
    (
        [name] IN ('master', 'tempdb', 'model', 'msdb')
        OR [name] LIKE 'ReportServer%'
    )
    AND [name] NOT LIKE '%tempdb%'
    AND [state_desc] IN ('ONLINE')    
ORDER BY [database_id]

--使用者資料庫
SELECT 
    'ALTER DATABASE [' + [name] + '] SET RECOVERY SIMPLE WITH NO_WAIT;' 
    , 'DBCC SHRINKDATABASE(''' + [name] + ''');'
    , 'ALTER DATABASE [' + [name] + '] SET RECOVERY FULL WITH NO_WAIT;'
	, [database_id]
FROM SYS.databases
WHERE [name] NOT IN ('master', 'tempdb', 'model', 'msdb')
    AND [name] NOT LIKE 'ReportServer%'
    AND [state_desc] IN ('ONLINE')
ORDER BY [name]
--ORDER BY [database_id]


/*
修改資料庫邏輯檔案名稱
*/

/*
USE [Webfolio4_TZUHUI]
GO
ALTER DATABASE [Webfolio4_TZUHUI] MODIFY FILE (NAME=N'Webfolio4_TIT_data', NEWNAME=N'Webfolio4_TZUHUI_data')
GO
USE [Webfolio4_TZUHUI]
GO
ALTER DATABASE [Webfolio4_TZUHUI] MODIFY FILE (NAME=N'Webfolio4_TIT_log', NEWNAME=N'Webfolio4_TZUHUI_log')
GO
*/

/*
啟用、設定、修改 sa 帳密
*/

USE [master]
GO

ALTER LOGIN sa ENABLE
GO

ALTER LOGIN [sa] WITH
PASSWORD = 'saas'
, DEFAULT_DATABASE = [tempdb]
, DEFAULT_LANGUAGE = [繁體中文]
, CHECK_EXPIRATION = OFF
, CHECK_POLICY = OFF
GO

/*
USE [master]
GO

    SELECT 'ALTER DATABASE [' + [name] + '] SET RECOVERY SIMPLE WITH NO_WAIT' FROM SYS.databases
	WHERE [name] NOT IN ('master', 'tempdb', 'model', 'msdb')
        AND [name] NOT LIKE 'ReportServer%'
        AND [state_desc] IN ('ONLINE')
    ORDER BY [database_id]
*/

    SELECT 'ALTER DATABASE [' + [name] + '] SET RECOVERY SIMPLE WITH NO_WAIT' 
        , 'DBCC SHRINKDATABASE(N''' + [name] + ''')'
        , 'ALTER DATABASE [' + [name] + '] SET RECOVERY FULL WITH NO_WAIT' 
    FROM SYS.databases
	WHERE [name] NOT IN ('master', 'tempdb', 'model', 'msdb')
        AND [name] NOT LIKE 'ReportServer%'
        AND [state_desc] IN ('ONLINE')
    ORDER BY [name]


--------------------------------------------------------------------------------
--處理 msdb 備份太久，紀錄檔留太多
--------------------------------------------------------------------------------
USE [master]
GO

SELECT 
    YEAR([start_time]), MONTH([start_time]), COUNT(*) AS CC
FROM [msdb].[dbo].[sysmaintplan_log]
GROUP BY YEAR([start_time]), MONTH([start_time])
ORDER BY YEAR([start_time]), MONTH([start_time])

SELECT 
    YEAR([start_time]), MONTH([start_time]), COUNT(*) AS CC
FROM [msdb].[dbo].[sysmaintplan_logdetail]
GROUP BY YEAR([start_time]), MONTH([start_time])
ORDER BY YEAR([start_time]), MONTH([start_time])

SELECT 
    YEAR([backup_start_date]), MONTH([backup_start_date]), COUNT(*) AS CC
FROM [msdb].[dbo].[backupset]
GROUP BY YEAR([backup_start_date]), MONTH([backup_start_date])
ORDER BY YEAR([backup_start_date]), MONTH([backup_start_date])


ALTER DATABASE [msdb] SET RECOVERY SIMPLE WITH NO_WAIT

EXECUTE [msdb].[dbo].[usp_SpaceUsed_Table] @dbName = 'msdb';

DECLARE @iExists			BIT = 'TRUE';
DECLARE @dtBefore			DATE = '2017-01-01';
DECLARE @iPercent			NUMERIC(5,2) = 25;
DECLARE @iCountsLog			INT = 0;
DECLARE @iCountsLogDetail	INT = 0;

WHILE (@iExists = 'TRUE')
BEGIN	
	SET @iCountsLog = (SELECT COUNT(*) FROM [msdb].[dbo].[sysmaintplan_log] WHERE [start_time] < @dtBefore);
	SET @iCountsLogDetail = (SELECT COUNT(*) FROM [msdb].[dbo].[sysmaintplan_logdetail] WHERE [start_time] < @dtBefore);

	PRINT N'[' + CONVERT(VARCHAR(32), GETDATE(), 121) + '] DELETE [msdb].[dbo].[sysmaintplan_log] TOP ' + CAST(@iPercent AS VARCHAR) + ' % in ' + CAST(@iCountsLog AS VARCHAR) + ' rows ...'	;
	DELETE TOP (@iPercent) PERCENT
	FROM [msdb].[dbo].[sysmaintplan_log]
	WHERE [start_time] < @dtBefore;
	PRINT N'[' + CONVERT(VARCHAR(32), GETDATE(), 121) + '] DELETE [msdb].[dbo].[sysmaintplan_logdetail] TOP ' + CAST(@iPercent AS VARCHAR) + ' % in ' + CAST(@iCountsLogDetail AS VARCHAR) + ' rows ...'	;
	DELETE TOP (@iPercent) PERCENT
	FROM [msdb].[dbo].[sysmaintplan_logdetail]
	WHERE [start_time] < @dtBefore;

	SET @iExists = (
					CASE
						WHEN (SELECT COUNT(*) FROM [msdb].[dbo].[sysmaintplan_log] WHERE [start_time] < @dtBefore) > 0 
							OR (SELECT COUNT(*) FROM [msdb].[dbo].[sysmaintplan_logdetail] WHERE [start_time] < @dtBefore) > 0 
						THEN 'TRUE'
						ELSE 'FALSE'
					END	
				);
END
GO

EXEC [msdb].[dbo].sp_delete_backuphistory @oldest_date = '2017-01-01';

DBCC SHRINKDATABASE('msdb');

ALTER DATABASE [msdb] SET RECOVERY FULL WITH NO_WAIT

SELECT * FROM [msdb].[dbo].[backupset] WHERE [database_name] = 'msdb'
SELECT * FROM [msdb].[dbo].[backupfile] WHERE [logical_name] = 'MSDBData'

/*
	偽裝已備份，才可清除交易紀錄
*/
BACKUP DATABASE AdventureWorks2012
TO DISK='NULL'
WITH INIT
GO

/*
	暴力清除交易紀錄檔 & 壓縮資料庫
*/
select
	'ALTER DATABASE [' + name+ '] SET RECOVERY SIMPLE WITH NO_WAIT'
	, 'BACKUP DATABASE [' + name + '] TO DISK=''NULL'' WITH INIT'
	, 'DBCC SHRINKDATABASE(''' + name + ''') '
	, *
FROM sys.databases
where [database_id] > 4
AND [state_desc] = 'ONLINE'
order by [name]

/*
產生壓縮資料庫備份檔用
*/

--dbpro2 本機版
USE [master]
GO
DECLARE @ARCHIVEMONTH  CHAR(8) = '.2017.11'
DECLARE @nvarMKDIR NVARCHAR(MAX) = '';
SET @nvarMKDIR = '
IF EXISTS (SELECT * FROM sys.databases WHERE [name] = ''?'' AND [state_desc] = ''ONLINE'')
	PRINT ''mkdir dbpro2.ytdt.sys\?\?' + @ARCHIVEMONTH +''';
	PRINT ''move dbpro2.ytdt.sys\?\*' + REPLACE(@ARCHIVEMONTH, '.', '_') + '* dbpro2.ytdt.sys\?\?' + @ARCHIVEMONTH + ''';	
	PRINT ''"C:\Program Files\7-Zip\7z.exe" a dbpro2.ytdt.sys\?\?' + @ARCHIVEMONTH  + '.7z dbpro2.ytdt.sys\?\?' + @ARCHIVEMONTH + ' -mx=9''
	PRINT ''rmdir dbpro2.ytdt.sys\?\?' + @ARCHIVEMONTH + ' /s /q''
	PRINT ''''
';
EXEC sp_msforeachdb @nvarMKDIR;

--nas unc 遠端版
USE [master]
GO
DECLARE @ARCHIVEMONTH  CHAR(8) = '.2017.10'
DECLARE @nvarMKDIR NVARCHAR(MAX) = '';
SET @nvarMKDIR = '
IF EXISTS (SELECT * FROM sys.databases WHERE [name] = ''?'' AND [state_desc] = ''ONLINE'')
	PRINT ''mkdir \\192.168.1.199\Backup\backup.db\dbpro2.ytdt.sys\?\?' + @ARCHIVEMONTH +''';
	PRINT ''move \\192.168.1.199\Backup\backup.db\dbpro2.ytdt.sys\?\*' + REPLACE(@ARCHIVEMONTH, '.', '_') + '* \\192.168.1.199\Backup\backup.db\dbpro2.ytdt.sys\?\?' + @ARCHIVEMONTH + ''';	
	PRINT ''"C:\Program Files\7-Zip\7z.exe" a \\192.168.1.199\Backup\backup.db\dbpro2.ytdt.sys\?\?' + @ARCHIVEMONTH  + '.7z \\192.168.1.199\Backup\backup.db\dbpro2.ytdt.sys\?\?' + @ARCHIVEMONTH + ' -mx=9''
	PRINT ''rmdir \\192.168.1.199\Backup\backup.db\dbpro2.ytdt.sys\?\?' + @ARCHIVEMONTH + ' /s /q''
	PRINT ''''
';
EXEC sp_msforeachdb @nvarMKDIR;


--mkdir Activity\Activity.2011.02
--move Activity\*201102* Activity\Activity.2011.02
--"C:\Program Files\7-Zip\7z.exe" a  Activity\Activity.2011.02.7z Activity\Activity.2011.02 -mx=9
--"C:\Program Files\7-Zip\7z.exe" a Alumnus_FOTECH\Alumnus_FOTECH.2011.04.7z Alumnus_FOTECH\Alumnus_FOTECH.2011.04 -mx=9
:CONNECT dbpro2.ytdt.sys
USE master
GO
DECLARE @ARCHIVEMONTH  CHAR(8)
SET @ARCHIVEMONTH = '.2017.05'
--1. 建目錄
SELECT 'REM dbpro2.ytdt.sys ' AS COMMANDTEXT
UNION ALL SELECT 'mkdir dbpro2.ytdt.sys\' + name + '\' + name + @ARCHIVEMONTH AS COMMANDTEXT FROM SYSDATABASES WHERE VERSION <> 0
--2. 搬移檔案進目錄
UNION ALL SELECT 'move dbpro2.ytdt.sys\' + name + '\*' + REPLACE(@ARCHIVEMONTH, '.', '_') + '* dbpro2.ytdt.sys\' + name + '\' + name + @ARCHIVEMONTH AS COMMANDTEXT FROM SYSDATABASES WHERE VERSION <> 0
--3. 壓縮備份目錄
UNION ALL SELECT '"C:\Program Files\7-Zip\7z.exe" a dbpro2.ytdt.sys\' + name + '\' + name + @ARCHIVEMONTH  + '.7z dbpro2.ytdt.sys\' + name + '\' + name + @ARCHIVEMONTH + ' -mx=9' AS COMMANDTEXT FROM SYSDATABASES WHERE VERSION <> 0
--4. 刪除備份目錄
UNION ALL SELECT 'rmdir dbpro2.ytdt.sys\' + name + '\' + name + @ARCHIVEMONTH + ' /s /q' AS COMMANDTEXT FROM SYSDATABASES WHERE VERSION <> 0

:CONNECT dbtest.ytdt.sys
--跨主機, 要重下 dbtest 的 script
USE master
GO
DECLARE @ARCHIVEMONTH  CHAR(8)
SET @ARCHIVEMONTH = '.2017.05'
SELECT 'REM dbtest.ytdt.sys ' AS COMMANDTEXT
UNION ALL SELECT 'mkdir dbtest.ytdt.sys\' + name + '\' + name + @ARCHIVEMONTH AS COMMANDTEXT FROM SYSDATABASES WHERE VERSION <> 0
--2. 搬移檔案進目錄
UNION ALL SELECT 'move dbtest.ytdt.sys\' + name + '\*' + REPLACE(@ARCHIVEMONTH, '.', '') + '* dbtest.ytdt.sys\' + name + '\' + name + @ARCHIVEMONTH AS COMMANDTEXT FROM SYSDATABASES WHERE VERSION <> 0
--3. 壓縮備份目錄
UNION ALL SELECT '"C:\Program Files\7-Zip\7z.exe" a dbtest.ytdt.sys\' + name + '\' + name + @ARCHIVEMONTH  + '.7z dbtest.ytdt.sys\' + name + '\' + name + @ARCHIVEMONTH + ' -mx=9' AS COMMANDTEXT FROM SYSDATABASES WHERE VERSION <> 0
--4. 刪除備份目錄
UNION ALL SELECT 'rmdir dbtest.ytdt.sys\' + name + '\' + name + @ARCHIVEMONTH + ' /s /q' AS COMMANDTEXT FROM SYSDATABASES WHERE VERSION <> 0


:CONNECT dbmoss.ytdt.sys\SHAREPOINT
--跨主機, 要重下 dbmoss\SHAREPOINT 的 script
USE master
GO
DECLARE @ARCHIVEMONTH  CHAR(8)
SET @ARCHIVEMONTH = '.2015.10'
--1. 建目錄
SELECT 'REM dbmoss.ytdt.sys ' AS COMMANDTEXT
UNION ALL SELECT 'mkdir dbmoss.ytdt.sys\' + name + '\' + name + @ARCHIVEMONTH AS COMMANDTEXT FROM SYSDATABASES WHERE VERSION <> 0 AND ([name] LIKE 'WSS_Content%' OR [name] = 'WSS_Logging' OR  [name] LIKE 'SharePoint_%' OR [dbid]  < 5)
--2. 搬移檔案進目錄
UNION ALL SELECT 'move dbmoss.ytdt.sys\' + name + '\*' + REPLACE(@ARCHIVEMONTH, '.', '_') + '* dbmoss.ytdt.sys\' + name + '\' + name + @ARCHIVEMONTH AS COMMANDTEXT FROM SYSDATABASES WHERE VERSION <> 0 AND ([name] LIKE 'WSS_Content%' OR [name] = 'WSS_Logging' OR  [name] LIKE 'SharePoint_%' OR [dbid]  < 5)
--3. 壓縮備份目錄
UNION ALL SELECT '"C:\Program Files\7-Zip\7z.exe" a dbmoss.ytdt.sys\' + name + '\' + name + @ARCHIVEMONTH  + '.7z dbmoss.ytdt.sys\' + name + '\' + name + @ARCHIVEMONTH + ' -mx=9' AS COMMANDTEXT FROM SYSDATABASES WHERE VERSION <> 0 AND ([name] LIKE 'WSS_Content%' OR [name] = 'WSS_Logging' OR  [name] LIKE 'SharePoint_%' OR [dbid]  < 5)
--4. 刪除備份目錄
UNION ALL SELECT 'rmdir dbmoss.ytdt.sys\' + name + '\' + name + @ARCHIVEMONTH + ' /s /q' AS COMMANDTEXT FROM SYSDATABASES WHERE VERSION <> 0 AND ([name] LIKE 'WSS_Content%' OR [name] = 'WSS_Logging' OR  [name] LIKE 'SharePoint_%' OR [dbid]  < 5)


--授予 SP 權限給某帳號
GRANT EXECUTE ON [dbo].[usp_pager] TO [foliob]

/*
解決無法遠端查詢指令設定
*/
exec sp_configure 'show advanced options',1
reconfigure
exec sp_configure 'Ad Hoc Distributed Queries',1
reconfigure

/*
查詢遠端資料
*/
SELECT *
FROM opendatasource('SQLOLEDB','Data Source=dbpro2.ytdt.sys;USEr ID=foliof;PassWord=frontfolio@2509').Webfolio_TEST.dbo.Dept

SELECT * 
FROM OPENROWSET('SQLOLEDB', 'dbpro2.ytdt.sys'; 'foliof'; 'frontfolio@2509', 'SELECT * FROM Webfolio_TEST.dbo.Dept') AS derivedtbl_2

/*
查詢執行計畫快取
*/
SELECT cp.USEcounts as '使用次數',objtype as '快取類型',st.text	
FROM sys.dm_exec_cached_plans cp
CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS st
WHERE st.text not like '%sys%' and objtype  <> 'Proc'

/*
改 db 主機名稱
*/
:CONNECT 192.168.2.104\SQLExpressR2
USE [master]
GO

DECLARE @SVRNAME_OLD NVARCHAR(255)
DECLARE @SVRNAME_NEW NVARCHAR(255)
SET @SVRNAME_OLD = (SELECT @@SERVERNAME)
SET @SVRNAME_NEW = (SELECT HOST_NAME())

SELECT 'OLD NAME : ' AS [STATUS], @SVRNAME_OLD AS [SERVERNAME]
UNION ALL 
SELECT 'NEW NAME : ' AS [STATUS], @SVRNAME_NEW AS [SERVERNAME]
GO

--EXEC sp_dropserver @SVRNAME_OLD
--EXEC sp_addserver @SVRNAME_NEW, local


/*
啟用識別插入
*/
SET IDENTITY_INSERT [dbo].[dept] ON

/*
檢查識別碼
*/
DBCC CHECKIDENT (system_lang)
--重設識別碼
DBCC CHECKIDENT (Course, reseed, 30848)

/*
授予資料庫權限
*/

資料庫層級角色
db_owner
db_datawriter
db_datareader
ref : http://msdn.microsoft.com/zh-tw/library/ms189121.aspx
ref : http://msdn.microsoft.com/zh-tw/library/ms187965.aspx



--*權限測試指令*
--以 foliofXXXXXX 登入測試，正常關閉權限後會被拒絕掉
SELECT a.name,b.name FROM sysobjects a,syscolumns b 
WHERE a.id=b.id and a.xtype='u' and (b.xtype=99 or b.xtype=35 or b.xtype=231 or b.xtype=167)

--GRANT 物件權限 (Transact-SQL)
--授與資料表、檢視表、資料表值函式、預存程序、擴充預存程序、純量函數、彙總函式、服務佇列或同義字的權限
--REVOKE 物件權限 (Transact-SQL)
--撤銷資料表、檢視表、資料表值函式、預存程序、擴充預存程序、純量函數、彙總函式、服務佇列或同義字的權限
--DENY 物件權限 (Transact-SQL)
--為安全性實體之 OBJECT 類別的成員定義權限。OBJECT 類別的成員包括：資料表、檢視表、資料表值函式、預存程序、擴充預存程序、純量函數、彙總函式、服務佇列和同義字

--*關閉權限指令*
--XXXXXX 改為學校 db 名稱
USE [Webackbone_MOEA]
DENY SELECT ON sys.sysobjects to foliof
DENY SELECT ON sys.syscolumns to foliof
DENY SELECT ON sys.sysobjects to foliob
DENY SELECT ON sys.syscolumns to foliob
--DENY SELECT ON sys.tables to foliob
--DENY SELECT ON sys.columns to foliob
--DENY SELECT ON sys.databases to foliob

SELECT 'USE [' + [name] + ']'  FROM SYS.databases
WHERE name LIKE '%_FY%'

USE [BIRSS_FY]
USE [Tportfolio_FY]
USE [Webfolio4_FY]

USE AffairsInform_MKC_20120220
USE AAS_MCUT 
GO


USE [master]

IF EXISTS(SELECT * FROM sys.databases WHERE name = 'Webfolio4_TCMT_20131009')
BEGIN
	DROP DATABASE [Webfolio4_MKC_20131029]
	EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = N'Webfolio4_TCMT_20131009'
END
GO

IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = 'Webfolio4_TCMT_20131009')
BEGIN 
	RESTORE DATABASE [Webfolio4_MKC_20131029] 
	FROM  DISK = N'D:\WEbfolio4-TCMT_20131009.bak' 
	WITH  FILE = 1
		,  MOVE N'Webfolio4_TCMT_data' TO N'D:\local_SQLExpressR2_DBs\Webfolio4_TCMT_20131009.mdf'
		,  MOVE N'Webfolio4_TCMT_log' TO N'D:\local_SQLExpressR2_DBs\Webfolio4_TCMT_20131009_log.ldf'
	,  NOUNLOAD,  STATS = 5
END
GO


/*

	SELECT 'USE [' + [name] + ']'
	FROM sys.databases
	WHERE [name] LIKE '%20160129%'

*/

USE [AAS_NTSU_20160129]

--移除使用者
EXEC dbo.sp_dropuser N'foliob';
EXEC dbo.sp_dropuser N'foliof';
--EXEC dbo.sp_dropuser N'folioi';
--加入後台 foliob
EXEC dbo.sp_grantdbaccess @loginame = N'foliob', @name_in_db = N'foliob';
EXEC dbo.sp_addrolemember 'db_owner', 'foliob';
ALTER USER [foliob] WITH DEFAULT_SCHEMA=[dbo]
--加入前台 foliof
EXEC dbo.sp_grantdbaccess @loginame = N'foliof', @name_in_db = N'foliof'
EXEC dbo.sp_addrolemember 'db_datareader', 'foliof'
EXEC dbo.sp_addrolemember 'db_datawriter', 'foliof'
ALTER USER [foliof] WITH DEFAULT_SCHEMA=[dbo]
----加入匯入 folioi （暫時設定成 dbo 做匯入用）
--EXEC dbo.sp_grantdbaccess @loginame = N'folioi', @name_in_db = N'folioi'
--EXEC dbo.sp_addrolemember 'db_datareader', 'folioi'
--EXEC dbo.sp_addrolemember 'db_datawriter', 'folioi'
--ALTER USER [folioi] WITH DEFAULT_SCHEMA=[dbo]

IF EXISTS(SELECT * FROM sys.procedures WHERE [name] = 'usp_pager')
BEGIN
    GRANT EXECUTE ON [dbo].[usp_pager] TO [foliof];
    GRANT EXECUTE ON [dbo].[usp_pager] TO [foliob];
    PRINT '[dbo].[usp_pager] EXISTS'
END
ELSE
BEGIN
    PRINT '[dbo].[usp_pager] NOT EXISTS~~~~~'
END

UPDATE [system_profile_ext]
SET [se_KeyValue] = 0
WHERE [se_KeyName] = 'SingleSignOnFlag'


ALTER AUTHORIZATION ON SCHEMA::[foliob] TO [dbo];
ALTER AUTHORIZATION ON SCHEMA::[foliof] TO [dbo];



--加入檢視
--加入匯入
EXEC dbo.sp_grantdbaccess @loginame = N'folioi', @name_in_db = N'folioi'
GRANT ALL ON Absent TO folioi
GRANT ALL ON Account TO folioi
GRANT ALL ON Chk TO folioi
GRANT ALL ON ClassMember TO folioi
GRANT ALL ON ClassRoom TO folioi
GRANT ALL ON Course TO folioi
GRANT ALL ON dept TO folioi
GRANT ALL ON DeptMapping TO folioi
GRANT ALL ON History_Score1 TO folioi
GRANT ALL ON MyStudent TO folioi
GRANT ALL ON Res_AboutMe TO folioi
GRANT ALL ON Res_Association TO folioi
GRANT ALL ON Res_Contest TO folioi
GRANT ALL ON Res_Edu TO folioi
GRANT ALL ON Res_Exp TO folioi
GRANT ALL ON Res_ExtrActive TO folioi
GRANT ALL ON Res_Introducer TO folioi
GRANT ALL ON Res_JobPlan TO folioi
GRANT ALL ON Res_Lan TO folioi
GRANT ALL ON Res_License TO folioi
GRANT ALL ON Res_Main TO folioi
GRANT ALL ON Res_Profile TO folioi
GRANT ALL ON Res_Reward TO folioi
GRANT ALL ON Res_SchoolWorkExp TO folioi
GRANT ALL ON Res_Service TO folioi
GRANT ALL ON Reward TO folioi

/*
關閉權限指令
*/
SQL2005 & 2008適用：
--以 foliofXXXXXX 登入測試，正常關閉權限後會被拒絕掉
SELECT a.name,b.name FROM sysobjects a,syscolumns b WHERE a.id=b.id and a.xtype='u' and (b.xtype=99 or b.xtype=35 or b.xtype=231 or b.xtype=167)
--XXXXXX 改為學校 db 名稱
USE [Webfolio_XXXXXX]
DENY SELECT ON sys.sysobjects to foliofXXXXXX
DENY SELECT ON sys.syscolumns to foliofXXXXXX

--變更物件擁有者
EXEC dbo.sp_changeobjectowner 'USEr.ObjectName','dbo'
EXEC dbo.sp_changeobjectowner 'foliob.vw_LR1','dbo'
EXEC dbo.sp_changeobjectowner 'foliob.vw_LR2','dbo'
EXEC dbo.sp_changeobjectowner 'foliob.vw_LR3','dbo'
EXEC dbo.sp_changeobjectowner 'foliob.vw_LR4','dbo'
EXEC dbo.sp_changeobjectowner 'foliob.vw_LR5','dbo'
EXEC dbo.sp_changeobjectowner 'foliob.vw_LR6','dbo'
EXEC dbo.sp_changeobjectowner 'foliob.vw_LR7','dbo'
EXEC dbo.sp_changeobjectowner 'foliob.vw_LR8','dbo'
EXEC dbo.sp_changeobjectowner 'foliob.vw_LR9','dbo'

ALTER SCHEMA dbo TRANSFER [foliob].[DW_RPT_VW_補助名冊資料匯出改良];
GO

EXEC dbo.sp_changeobjectowner 'foliob.DW_RPT_VW_補助名冊資料匯出改良','dbo'

/*
檢查資料庫
修復資料庫
*/
DBCC CHECKDB ('Webfolio_Test')
ALTER DATABASE Webfolio_Test SET SINGLE_USER WITH NO_WAIT
DBCC CHECKDB ('Webfolio_Test', REPAIR_REBUILD)
ALTER DATABASE Webfolio_Test SET MULTI_USER WITH NO_WAIT
DBCC UPDATEUSAGE('Webfolio_Test')

/*
修改資料庫成多使用者
修改資料庫成單一使用者
*/

ALTER DATABASE Webfolio_Test SET MULTI_USER WITH NO_WAIT
ALTER DATABASE Webfolio_Test SET SINGLE_USER WITH NO_WAIT



/*
清潔資料庫
*/

--Check SingleSignOn Flag
SELECT * FROM [Alumnus_YTDT].[dbo].[system_profile_ext]     WHERE se_KeyName = 'SingleSignOnFlag' and se_KeyValue = 1
SELECT * FROM [Webfolio_CHU].[dbo].[system_profile_ext]     WHERE se_KeyName = 'SingleSignOnFlag' and se_KeyValue = 1
SELECT * FROM [Webfolio_CSU].[dbo].[system_profile_ext]     WHERE se_KeyName = 'SingleSignOnFlag' and se_KeyValue = 1
SELECT * FROM [Webfolio_DYU].[dbo].[system_profile_ext]     WHERE se_KeyName = 'SingleSignOnFlag' and se_KeyValue = 1
SELECT * FROM [Webfolio_FOTECH].[dbo].[system_profile_ext]  WHERE se_KeyName = 'SingleSignOnFlag' and se_KeyValue = 1
SELECT * FROM [Webfolio_HWAI].[dbo].[system_profile_ext]    WHERE se_KeyName = 'SingleSignOnFlag' and se_KeyValue = 1
SELECT * FROM [Webfolio_MEIHO].[dbo].[system_profile_ext]   WHERE se_KeyName = 'SingleSignOnFlag' and se_KeyValue = 1
SELECT * FROM [Webfolio_NCUT].[dbo].[system_profile_ext]    WHERE se_KeyName = 'SingleSignOnFlag' and se_KeyValue = 1
SELECT * FROM [Webfolio_NTCNC].[dbo].[system_profile_ext]   WHERE se_KeyName = 'SingleSignOnFlag' and se_KeyValue = 1
SELECT * FROM [Webfolio_NTCU].[dbo].[system_profile_ext]    WHERE se_KeyName = 'SingleSignOnFlag' and se_KeyValue = 1
SELECT * FROM [Webfolio_YTDT_G0].[dbo].[system_profile_ext] WHERE se_KeyName = 'SingleSignOnFlag' and se_KeyValue = 1
SELECT * FROM [Webfolio_YTDT_G1].[dbo].[system_profile_ext] WHERE se_KeyName = 'SingleSignOnFlag' and se_KeyValue = 1
SELECT * FROM [Webfolio_YTDT_G2].[dbo].[system_profile_ext] WHERE se_KeyName = 'SingleSignOnFlag' and se_KeyValue = 1
SELECT * FROM [Webfolio_YTDT_G3].[dbo].[system_profile_ext] WHERE se_KeyName = 'SingleSignOnFlag' and se_KeyValue = 1
SELECT * FROM [Webfolio_YUDA].[dbo].[system_profile_ext]    WHERE se_KeyName = 'SingleSignOnFlag' and se_KeyValue = 1
SELECT * FROM [Webfolio_KMVS].[dbo].[system_profile_ext]    WHERE se_KeyName = 'SingleSignOnFlag' and se_KeyValue = 1	--學校沒開, 我們沒開 (2010/08/31 check)
SELECT * FROM [Webfolio_LIT].[dbo].[system_profile_ext]     WHERE se_KeyName = 'SingleSignOnFlag' and se_KeyValue = 1	--學校沒開, 我們沒開 (2010/08/31 check)
SELECT * FROM [Webfolio_LTU].[dbo].[system_profile_ext]     WHERE se_KeyName = 'SingleSignOnFlag' and se_KeyValue = 1	--學校沒開, 我們沒開 (2010/08/31 check)
SELECT * FROM [Webfolio_TIT].[dbo].[system_profile_ext]     WHERE se_KeyName = 'SingleSignOnFlag' and se_KeyValue = 1	--學校沒開, 我們沒開 (2010/08/31 check)
SELECT * FROM [Webfolio_NTHU].[dbo].[system_profile_ext]    WHERE se_KeyName = 'SingleSignOnFlag' and se_KeyValue = 1	--清大有開, 我們沒開 (2010/08/31 check)
SELECT * FROM [Webfolio_MCUT].[dbo].[system_profile_ext]    WHERE se_KeyName = 'SingleSignOnFlag' and se_KeyValue = 1	--明志有開, 我們沒開 (2010/09/01 check)
SELECT * FROM [Webfolio_SZMC].[dbo].[system_profile_ext]    WHERE se_KeyName = 'SingleSignOnFlag' and se_KeyValue = 1	--樹人有開, 我們沒開 (2010/09/01 check)
SELECT * FROM [Webfolio_THIT].[dbo].[system_profile_ext]    WHERE se_KeyName = 'SingleSignOnFlag' and se_KeyValue = 1	--大華有開, 我們沒開 (2010/09/01 check)
SELECT * FROM [Webfolio_NTIT].[dbo].[system_profile_ext]    WHERE se_KeyName = 'SingleSignOnFlag' and se_KeyValue = 1	--中技有開, 我們沒開 (2010/09/01 check)
SELECT * FROM [Webfolio_YUHING].[dbo].[system_profile_ext]  WHERE se_KeyName = 'SingleSignOnFlag' and se_KeyValue = 1	--育英租用, 我們有開 (2010/08/31 check)

--FixIt!
UPDATE [Webfolio_NTHU].[dbo].[system_profile_ext] SET se_KeyValue = 0 WHERE se_KeyName = 'SingleSignOnFlag' and se_KeyValue = 1

--Check SingleSignOn DBConnection
SELECT * FROM [Alumnus_YTDT].[dbo].[system_profile_ext]     WHERE se_KeyName = 'SingleSignConn' and (se_KeyValue like '%192.168.1.7%' or se_KeyValue like 'sa'  or se_KeyValue like '%ytdtytdt%')
SELECT * FROM [Webfolio_CHU].[dbo].[system_profile_ext]     WHERE se_KeyName = 'SingleSignConn' and (se_KeyValue like '%192.168.1.7%' or se_KeyValue like 'sa'  or se_KeyValue like '%ytdtytdt%')
SELECT * FROM [Webfolio_CSU].[dbo].[system_profile_ext]     WHERE se_KeyName = 'SingleSignConn' and (se_KeyValue like '%192.168.1.7%' or se_KeyValue like 'sa'  or se_KeyValue like '%ytdtytdt%')
SELECT * FROM [Webfolio_DYU].[dbo].[system_profile_ext]     WHERE se_KeyName = 'SingleSignConn' and (se_KeyValue like '%192.168.1.7%' or se_KeyValue like 'sa'  or se_KeyValue like '%ytdtytdt%')
SELECT * FROM [Webfolio_FOTECH].[dbo].[system_profile_ext]  WHERE se_KeyName = 'SingleSignConn' and (se_KeyValue like '%192.168.1.7%' or se_KeyValue like 'sa'  or se_KeyValue like '%ytdtytdt%')
SELECT * FROM [Webfolio_HWAI].[dbo].[system_profile_ext]    WHERE se_KeyName = 'SingleSignConn' and (se_KeyValue like '%192.168.1.7%' or se_KeyValue like 'sa'  or se_KeyValue like '%ytdtytdt%')
SELECT * FROM [Webfolio_MEIHO].[dbo].[system_profile_ext]   WHERE se_KeyName = 'SingleSignConn' and (se_KeyValue like '%192.168.1.7%' or se_KeyValue like 'sa'  or se_KeyValue like '%ytdtytdt%')
SELECT * FROM [Webfolio_NCUT].[dbo].[system_profile_ext]    WHERE se_KeyName = 'SingleSignConn' and (se_KeyValue like '%192.168.1.7%' or se_KeyValue like 'sa'  or se_KeyValue like '%ytdtytdt%')
SELECT * FROM [Webfolio_NTCNC].[dbo].[system_profile_ext]   WHERE se_KeyName = 'SingleSignConn' and (se_KeyValue like '%192.168.1.7%' or se_KeyValue like 'sa'  or se_KeyValue like '%ytdtytdt%')
SELECT * FROM [Webfolio_NTCU].[dbo].[system_profile_ext]    WHERE se_KeyName = 'SingleSignConn' and (se_KeyValue like '%192.168.1.7%' or se_KeyValue like 'sa'  or se_KeyValue like '%ytdtytdt%')
SELECT * FROM [Webfolio_YTDT_G0].[dbo].[system_profile_ext] WHERE se_KeyName = 'SingleSignConn' and (se_KeyValue like '%192.168.1.7%' or se_KeyValue like 'sa'  or se_KeyValue like '%ytdtytdt%')
SELECT * FROM [Webfolio_YTDT_G1].[dbo].[system_profile_ext] WHERE se_KeyName = 'SingleSignConn' and (se_KeyValue like '%192.168.1.7%' or se_KeyValue like 'sa'  or se_KeyValue like '%ytdtytdt%')
SELECT * FROM [Webfolio_YTDT_G2].[dbo].[system_profile_ext] WHERE se_KeyName = 'SingleSignConn' and (se_KeyValue like '%192.168.1.7%' or se_KeyValue like 'sa'  or se_KeyValue like '%ytdtytdt%')
SELECT * FROM [Webfolio_YTDT_G3].[dbo].[system_profile_ext] WHERE se_KeyName = 'SingleSignConn' and (se_KeyValue like '%192.168.1.7%' or se_KeyValue like 'sa'  or se_KeyValue like '%ytdtytdt%')
SELECT * FROM [Webfolio_YUDA].[dbo].[system_profile_ext]    WHERE se_KeyName = 'SingleSignConn' and (se_KeyValue like '%192.168.1.7%' or se_KeyValue like 'sa'  or se_KeyValue like '%ytdtytdt%')
SELECT * FROM [Webfolio_KMVS].[dbo].[system_profile_ext]    WHERE se_KeyName = 'SingleSignConn' and (se_KeyValue like '%192.168.1.7%' or se_KeyValue like 'sa'  or se_KeyValue like '%ytdtytdt%')
SELECT * FROM [Webfolio_LIT].[dbo].[system_profile_ext]     WHERE se_KeyName = 'SingleSignConn' and (se_KeyValue like '%192.168.1.7%' or se_KeyValue like 'sa'  or se_KeyValue like '%ytdtytdt%')
SELECT * FROM [Webfolio_LTU].[dbo].[system_profile_ext]     WHERE se_KeyName = 'SingleSignConn' and (se_KeyValue like '%192.168.1.7%' or se_KeyValue like 'sa'  or se_KeyValue like '%ytdtytdt%')
SELECT * FROM [Webfolio_TIT].[dbo].[system_profile_ext]     WHERE se_KeyName = 'SingleSignConn' and (se_KeyValue like '%192.168.1.7%' or se_KeyValue like 'sa'  or se_KeyValue like '%ytdtytdt%')
SELECT * FROM [Webfolio_NTHU].[dbo].[system_profile_ext]    WHERE se_KeyName = 'SingleSignConn' and (se_KeyValue like '%192.168.1.7%' or se_KeyValue like 'sa'  or se_KeyValue like '%ytdtytdt%')
SELECT * FROM [Webfolio_MCUT].[dbo].[system_profile_ext]    WHERE se_KeyName = 'SingleSignConn' and (se_KeyValue like '%192.168.1.7%' or se_KeyValue like 'sa'  or se_KeyValue like '%ytdtytdt%')
SELECT * FROM [Webfolio_SZMC].[dbo].[system_profile_ext]    WHERE se_KeyName = 'SingleSignConn' and (se_KeyValue like '%192.168.1.7%' or se_KeyValue like 'sa'  or se_KeyValue like '%ytdtytdt%')
SELECT * FROM [Webfolio_THIT].[dbo].[system_profile_ext]    WHERE se_KeyName = 'SingleSignConn' and (se_KeyValue like '%192.168.1.7%' or se_KeyValue like 'sa'  or se_KeyValue like '%ytdtytdt%')
SELECT * FROM [Webfolio_YUHING].[dbo].[system_profile_ext]  WHERE se_KeyName = 'SingleSignConn' and (se_KeyValue like '%192.168.1.7%' or se_KeyValue like 'sa'  or se_KeyValue like '%ytdtytdt%')
SELECT * FROM [Webfolio_NTIT].[dbo].[system_profile_ext]    WHERE se_KeyName = 'SingleSignConn' and (se_KeyValue like '%192.168.1.7%' or se_KeyValue like 'sa'  or se_KeyValue like '%ytdtytdt%')

--FixIt!
UPDATE [Webfolio_MEIHO].[dbo].[system_profile_ext]	set se_KeyValue = 'server=;UID=;Password=;database=;'	WHERE se_KeyName = 'SingleSignConn'

--Check 紀錄跟記錄
SELECT * FROM USErmenu
SELECT * FROM system_lang
USE Webfolio_CSU
SELECT replace(sl_LanValue, N'記錄', N'紀錄'),* FROM system_lang WHERE sl_LanValue like N'%記錄%'
SELECT replace(um_name, N'記錄', N'紀錄'),* FROM USErmenu WHERE um_name like N'%記錄%' 
SELECT replace(um_parentname, N'記錄', N'紀錄'),* FROM USErmenu WHERE um_parentname like N'%記錄%' 
SELECT replace(sl_LanValue, N'记录', N'纪录'),* FROM system_lang WHERE sl_LanValue like N'%记录%'
SELECT replace(um_name, N'记录', N'纪录'),* FROM USErmenu WHERE um_name like N'%记录%' 
SELECT replace(um_parentname, N'记录', N'纪录'),* FROM USErmenu WHERE um_parentname like N'%记录%' 

--FixIt!
USE Webfolio_YUHING
UPDATE system_lang SET sl_LanValue = replace(sl_LanValue, N'記錄', N'紀錄') WHERE sl_LanValue like N'%記錄%'
UPDATE USErmenu SET um_name = replace(um_name, N'記錄', N'紀錄') WHERE um_name like N'%記錄%' 
UPDATE USErmenu SET um_parentname = replace(um_parentname, N'記錄', N'紀錄') WHERE um_parentname like N'%記錄%' 
UPDATE system_lang SET sl_LanValue = replace(sl_LanValue, N'记录', N'纪录') WHERE sl_LanValue like N'%记录%'
UPDATE USErmenu SET um_name = replace(um_name, N'记录', N'纪录') WHERE um_name like N'%记录%' 
UPDATE USErmenu SET um_parentname = replace(um_parentname, N'记录', N'纪录') WHERE um_parentname like N'%记录%' 

--System_Lang 內有 ? 處理
USE Webfolio_CHU
SELECT * FROM System_lang WHERE sl_LanName IN (SELECT sl_LanName FROM System_lang WHERE sl_LanValue like '%?%') and sl_Lang = 'zh-cn'
--FixIt!
USE Webfolio_YTDT_G3
UPDATE System_lang SET sl_LanValue = N'工读实习' WHERE sl_LanName = 'MYSK_SchoolWorkExp' and sl_lang = 'zh-cn'
UPDATE System_lang SET sl_LanValue = N'工读实习' WHERE sl_LanName = 'WorkExpMenu_4' and sl_lang = 'zh-cn'
UPDATE System_lang SET sl_LanValue = N'新增工读实习' WHERE sl_LanName = 'PG2_4_ADD_WorkExp' and sl_lang = 'zh-cn'

USE Webfolio_THIT  
UPDATE System_lang SET sl_LanValue = N'「此数据」只有会员(同学/老师/校友)可浏览，请登入会员!' WHERE sl_LanName = 'LoginFirst' and sl_lang = 'zh-cn'

USE Webfolio_NTCNC 
UPDATE System_lang SET sl_LanValue = N'在学学历' WHERE sl_LanName = 'MIMajorDegree' and sl_lang = 'zh-cn'
UPDATE System_lang SET sl_LanValue = N'工读实习' WHERE sl_LanName = 'MYSK_SchoolWorkExp' and sl_lang = 'zh-cn'
UPDATE System_lang SET sl_LanValue = N'工读实习' WHERE sl_LanName = 'WorkExpMenu_4' and sl_lang = 'zh-cn'
UPDATE System_lang SET sl_LanValue = N'新增工读实习' WHERE sl_LanName = 'PG2_4_ADD_WorkExp' and sl_lang = 'zh-cn'

USE Webfolio_LIT
UPDATE System_lang SET sl_LanValue = N'校外实习' WHERE sl_LanName = 'WorkExpMenu_4' and sl_lang = 'zh-cn'
UPDATE System_lang SET sl_LanValue = N'新增校外实习' WHERE sl_LanName = 'PG2_4_ADD_WorkExp' and sl_lang = 'zh-cn'

USE Webfolio_FOTECH
UPDATE System_lang SET sl_LanValue = N'在学学历' WHERE sl_LanName = 'MIMajorDegree' and sl_lang = 'zh-cn'
UPDATE System_lang SET sl_LanValue = N'工读实习' WHERE sl_LanName = 'MYSK_SchoolWorkExp' and sl_lang = 'zh-cn'
UPDATE System_lang SET sl_LanValue = N'工读实习' WHERE sl_LanName = 'WorkExpMenu_4' and sl_lang = 'zh-cn'
UPDATE System_lang SET sl_LanValue = N'新增工读实习' WHERE sl_LanName = 'PG2_4_ADD_WorkExp' and sl_lang = 'zh-cn'

USE Webfolio_CHU
UPDATE System_lang SET sl_LanValue = N'工读实习' WHERE sl_LanName = 'MYSK_SchoolWorkExp' and sl_lang = 'zh-cn'
UPDATE System_lang SET sl_LanValue = N'工读实习' WHERE sl_LanName = 'WorkExpMenu_4' and sl_lang = 'zh-cn'
UPDATE System_lang SET sl_LanValue = N'新增工读实习' WHERE sl_LanName = 'PG2_4_ADD_WorkExp' and sl_lang = 'zh-cn'

--透過 profiler 統計 system_lang
USE Webfolio_Performance
--1. 修改 profiler 錄出來的 table schema
ALTER TABLE system_lang ALTER COLUMN TextData nvarchar (max) NULL
--2. 統計區分語系後的查詢次數
SELECT SUBSTRING(textdata, 62,2) as Lang,REPLACE(SUBSTRING(textdata,87,len(textdata)),'''','') as Keyword, COUNT(*) as cc FROM System_Lang
group by SUBSTRING(textdata, 62,2), REPLACE(SUBSTRING(textdata,87,len(textdata)),'''','')
order by cc desc
--3. 統計不分語系的查詢次數
SELECT REPLACE(SUBSTRING(textdata,87,len(textdata)),'''','') as Keyword, COUNT(*) as cc FROM System_Lang
group by REPLACE(SUBSTRING(textdata,87,len(textdata)),'''','')
order by cc desc

--4. 統計資料表使用量

SELECT TextData
--replace( TextData, '  ', ' '),
--,LOWER(SUBSTRING(replace( TextData, '  ', ' '), CHARINDEX('FROM',replace( TextData, '  ', ' '))+5, 25))
--,charindex(' ', LOWER(SUBSTRING(replace( TextData, '  ', ' '), CHARINDEX('FROM',replace( TextData, '  ', ' '))+5, 25)))
,LEFT(LOWER(SUBSTRING(replace( TextData, '  ', ' '), CHARINDEX('FROM',replace( TextData, '  ', ' '))+5, 25)), charindex(' ', LOWER(SUBSTRING(replace( TextData, '  ', ' '), CHARINDEX('FROM',replace( TextData, '  ', ' '))+5, 25))))
FROM [Webfolio_Performance].[dbo].[profiler_ALL]


SELECT COUNT(*) FROM [Webfolio_Performance].[dbo].[profiler_ALL]
SELECT LEFT(LOWER(SUBSTRING(replace( TextData, '  ', ' '), CHARINDEX('FROM',replace( TextData, '  ', ' '))+5, 25)), charindex(' ', LOWER(SUBSTRING(replace( TextData, '  ', ' '), CHARINDEX('FROM',replace( TextData, '  ', ' '))+5, 25)))) as TableName
,COUNT(*) as cc
FROM [Webfolio_Performance].[dbo].[profiler_ALL]
group by LEFT(LOWER(SUBSTRING(replace( TextData, '  ', ' '), CHARINDEX('FROM',replace( TextData, '  ', ' '))+5, 25)), charindex(' ', LOWER(SUBSTRING(replace( TextData, '  ', ' '), CHARINDEX('FROM',replace( TextData, '  ', ' '))+5, 25))))
order by cc desc



--清除 GetFROM
USE Alumnus_NTIT
UPDATE res_main SET R_GETFROM = 'Webfolio' 
USE Alumnus_SZMC
UPDATE res_main SET R_GETFROM = 'Webfolio' 
USE Webfolio_CHU
UPDATE res_main SET R_GETFROM = 'Webfolio' 
USE Webfolio_CSU
UPDATE res_main SET R_GETFROM = 'Webfolio' 
USE Webfolio_DYU
UPDATE res_main SET R_GETFROM = 'Webfolio' 
USE Webfolio_FOTECH
UPDATE res_main SET R_GETFROM = 'Webfolio' 
USE Webfolio_HWAI
UPDATE res_main SET R_GETFROM = 'Webfolio' 
USE Webfolio_KMVS
UPDATE res_main SET R_GETFROM = 'Webfolio' 
USE Webfolio_LIT
UPDATE res_main SET R_GETFROM = 'Webfolio' 
USE Webfolio_LTU
UPDATE res_main SET R_GETFROM = 'Webfolio' 
USE Webfolio_MCUT
UPDATE res_main SET R_GETFROM = 'Webfolio' 
USE Webfolio_MEIHO
UPDATE res_main SET R_GETFROM = 'Webfolio' 
USE Webfolio_NCUT
UPDATE res_main SET R_GETFROM = 'Webfolio' 
USE Webfolio_NIU
UPDATE res_main SET R_GETFROM = 'Webfolio' 
USE Webfolio_NTCNC
UPDATE res_main SET R_GETFROM = 'Webfolio' 
USE Webfolio_NTCU
UPDATE res_main SET R_GETFROM = 'Webfolio' 
USE Webfolio_NTHU
UPDATE res_main SET R_GETFROM = 'Webfolio' 
USE Webfolio_NTIT
UPDATE res_main SET R_GETFROM = 'Webfolio' 
USE Webfolio_SZMC
UPDATE res_main SET R_GETFROM = 'Webfolio' 
USE Webfolio_TEST
UPDATE res_main SET R_GETFROM = 'Webfolio' 
USE Webfolio_THIT
UPDATE res_main SET R_GETFROM = 'Webfolio' 
USE Webfolio_TIT
UPDATE res_main SET R_GETFROM = 'Webfolio' 
USE Webfolio_YTDT_G0
UPDATE res_main SET R_GETFROM = 'Webfolio' 
USE Webfolio_YTDT_G1
UPDATE res_main SET R_GETFROM = 'Webfolio' 
USE Webfolio_YTDT_G2
UPDATE res_main SET R_GETFROM = 'Webfolio' 
USE Webfolio_YTDT_G3
UPDATE res_main SET R_GETFROM = 'Webfolio' 
USE Webfolio_YUDA
UPDATE res_main SET R_GETFROM = 'Webfolio' 
USE Webfolio_YUHING
UPDATE res_main SET R_GETFROM = 'Webfolio' 




/*
Webfolio FixIt!

*/
--選單位置不正確，要檢查以下三個表示否有重覆資料
--Res_AboutMe
	SELECT * FROM res_aboutme WHERE ra_no IN (
		SELECT ra_no FROM res_aboutme
		group by ra_no
		having count(*) > 1
	)
	order by ra_id, ra_no
--Res_Teacher
	SELECT * FROM Res_Teacher WHERE rt_no IN (
		SELECT rt_no FROM Res_Teacher
		group by rt_no
		having count(*) > 1
	)
	order by rt_id, rt_no
--Res_Status
	SELECT * FROM Res_Status WHERE rs_no IN (
		SELECT rs_no FROM Res_Status
		group by rs_no
		having count(*) > 1
	)
	order by rs_id, rs_no
--Delete
--DELETE res_aboutme WHERE RA_AUTOID = 'xxx'



/* --------------------------------------------------
	SingleSignOn（SSO）驗證用
-------------------------------------------------- */
--建立驗證用資料檢視表

USE [Webfolio_MKC]
GO

--學生用驗證資料檢視表
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[SSO_STUDENT]'))
DROP VIEW [dbo].[SSO_STUDENT]
GO

Create View [dbo].[SSO_STUDENT] as 
	SELECT 
		dbo.Res_Main.R_School_NO as SSOAccount
		, dbo.Account.A_PASSWORD as SSOPassword
		, dbo.Res_Main.R_NO, dbo.Res_Main.R_ID, dbo.Res_Main.R_School_NO, dbo.Res_Main.R_NAME
		, dbo.Account.A_GROUP, dbo.Account.A_SchoolLevel, dbo.Account.A_PASSWORD
	FROM dbo.Res_Main
	left join dbo.Account on dbo.Res_Main.R_NO = dbo.Account.A_MAP_NO
	WHERE dbo.Account.A_GROUP = 'C' AND dbo.Account.A_SchoolLevel = 'S'
GO

--老師用驗證資料檢視表
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[SSO_TEACHER]'))
DROP VIEW [dbo].[SSO_TEACHER]
GO

Create View [dbo].[SSO_TEACHER] as 
	SELECT 
		dbo.Res_Main.R_School_NO as SSOAccount
		, dbo.Account.A_PASSWORD as SSOPassword
		, dbo.Res_Main.R_NO, dbo.Res_Main.R_ID, dbo.Res_Main.R_School_NO, dbo.Res_Main.R_NAME
		, dbo.Account.A_GROUP, dbo.Account.A_SchoolLevel, dbo.Account.A_PASSWORD
	FROM dbo.Res_Main
	left join dbo.Account on dbo.Res_Main.R_NO = dbo.Account.A_MAP_NO
	WHERE dbo.Account.A_GROUP = 'C' AND dbo.Account.A_SchoolLevel = 'T'
GO

/*
    SELECT * FROM [dbo].[SSO_STUDENT]
    SELECT * FROM [dbo].[SSO_TEACHER]
*/

--修改 system_profile_ext
USE Webfolio_MCUT_20110616
SELECT * FROM system_profile_ext
WHERE se_KeyName IN
( 
    'SingleSignOnFlag'
    , 'SingleSignConn'
    , 'SingleSignTable'
    , 'SingleTeacherTable'
    , 'SingleSignID'
    , 'SingleSignPWD'
    , 'SingleSignPID'
)
ORDER BY SE_KEYNAME

USE Webfolio_MKC
--清除 SingleSignOn
UPDATE system_profile_ext SET se_KeyValue = '0'				WHERE se_KeyName = 'SingleSignOnFlag'
--清除來源資料庫
UPDATE system_profile_ext SET se_KeyValue = 'server=;UID=;Password=;database=;' WHERE se_KeyName = 'SingleSignConn'

USE Webfolio_MKC
--開啟 SingleSignOn
UPDATE system_profile_ext SET se_KeyValue = '1'				WHERE se_KeyName = 'SingleSignOnFlag'
--設定來源資料庫
UPDATE system_profile_ext SET se_KeyValue = 'server=dbpro2.ytdt.sys;UID=foliof;Password=frontfolio@2509;database=Webfolio_MKC;' WHERE se_KeyName = 'SingleSignConn'
--學生驗證用資料檢視表
UPDATE system_profile_ext SET se_KeyValue = 'SSO_STUDENT'	WHERE se_KeyName = 'SingleSignTable'
--老師驗證用資料檢視表
UPDATE system_profile_ext SET se_KeyValue = 'SSO_TEACHER'	WHERE se_KeyName = 'SingleTeacherTable'
--登入帳號
UPDATE system_profile_ext SET se_KeyValue = 'SSOAccount'	WHERE se_KeyName = 'SingleSignID'
--登入密碼
UPDATE system_profile_ext SET se_KeyValue = 'SSOPassword'	WHERE se_KeyName = 'SingleSignPWD'
--對應 Account.USEr_id（對應到 Res_Main.R_ID） ==> 找出 R_NO 是否存在系統
UPDATE system_profile_ext SET se_KeyValue = 'R_ID'			WHERE se_KeyName = 'SingleSignPID'


/*
資料表結構修改
*/
--1. 網誌分類 //修正 vchar 相容 Unicode 多國語系的問題
USE Webfolio_CHU
ALTER TABLE USErClass ALTER COLUMN UC_NAME nvarchar (80) NOT NULL

--高醫修改來源 Webfolio_SSISDC_KMU 的檢視表格式
USE Webfolio_SSISDC_KMU
ALTER TABLE DW_EXT_V_INNERWORK ADD OID nvarchar(10) NULL
ALTER TABLE DW_EXT_V_INNERWORK ADD MANAGERNUM nvarchar(10) NULL
ALTER TABLE DW_EXT_V_OUTWORK ADD OID nvarchar(10) NULL
ALTER TABLE DW_EXT_V_STUDENT ADD DEGREE nvarchar(10) NULL
ALTER TABLE DW_EXT_V_STUDENT ADD EDU_TYPE nvarchar(10) NULL
EXEC sp_rename 'DW_EXT_V_SCHTUTEE.STU_SNO', 'S_ID', 'COLUMN'
EXEC sp_rename 'DW_EXT_V_SCHTUTEE.TEA_SNO', 'T_ID', 'COLUMN'
ALTER TABLE DW_EXT_V_RECORD ADD OID nvarchar(10) NULL

--2. 修正會員相關資料
/*2010.12.20 修正 dbtest, dbpro2*/
--修正會員地址欄位過短，由 varchar(80) 改為 nvarchar(250)
--修正會員姓名欄位 Unicode，由 varchar(30) 改為 nvarchar(60)
--修正電話欄位過短，由 varchar(15),varchar(20) 改為 varchar(30)
--修正密碼欄位過短，由 varchar(12) 改為 varchar(30)
--修正密碼備忘欄位過短，由 varchar(60) 改為 nvarchar(120)
USE Webfolio_TEST
ALTER TABLE Res_Main ALTER COLUMN R_ADDRESS nvarchar (250) NULL
ALTER TABLE Res_Main ALTER COLUMN R_NAME nvarchar (250) NOT NULL
ALTER TABLE Res_Main ALTER COLUMN R_TEL_O varchar (30) NULL
ALTER TABLE Res_Main ALTER COLUMN R_TEL_H varchar (30) NULL
ALTER TABLE Account ALTER COLUMN A_PASSWORD varchar (30) NOT NULL
ALTER TABLE Account ALTER COLUMN A_USERNAME nvarchar (60) NOT NULL
ALTER TABLE Account ALTER COLUMN A_PASS_REMIND nvarchar (120) NULL

ALTER TABLE Res_Main ADD R_DEGREE INt NULL
ALTER TABLE Res_Main ADD R_EDU_TYPE varchar (2) NULL

/*
國語日報
*/
--0. 重新設定使用者密碼
--TQuarker
--Rekrauqt
--------------------------------------------------------------------------------
-- MDN_ERP
--------------------------------------------------------------------------------
--1. 還原資料庫 MDN_ERP
RESTORE DATABASE [MDN_ERP] FROM  DISK = N'F:\MDN_ERP.bak' 
WITH  FILE = 1
,  MOVE N'Mdn_ERP_backup_Data' TO N'F:\MDNKids.DB\MDN_ERP.MDF'
,  MOVE N'Mdn_ERP_backup_Log' TO N'F:\MDNKids.DB\MDN_ERP_1.LDF'
,  NOUNLOAD
,  STATS = 10
GO
--2. 砍掉舊使用者	TQuarker
USE [MDN_ERP]
GO
EXEC dbo.sp_dropuser N'TQuarker';
--3. 允許使用者使用資料庫 MDN_ERP
USE [MDN_ERP]
GO
EXEC dbo.sp_grantdbaccess @loginame = N'TQuarker', @name_in_db = N'TQuarker';
EXEC dbo.sp_addrolemember 'db_owner', 'TQuarker';
--4. 修改登入用 admin 密碼
USE [MDN_ERP]
GO
UPDATE [_Login] SET i_password = '8709' WHERE i_Name = 'Admin'
--5. 維護資料庫 MDN_ERP
DBCC CHECKDB ('MDN_ERP')
ALTER DATABASE MDN_ERP SET SINGLE_USER WITH NO_WAIT
DBCC CHECKDB ('MDN_ERP', REPAIR_REBUILD)
ALTER DATABASE MDN_ERP SET MULTI_USER WITH NO_WAIT
DBCC UPDATEUSAGE('MDN_ERP')
DBCC SHRINKDATABASE('MDN_ERP')

--------------------------------------------------------------------------------
-- MDN_ERP_TEST
--------------------------------------------------------------------------------
--1. 還原資料庫 MDN_ERP_TEST
RESTORE DATABASE [MDN_ERP_TEST] FROM  DISK = N'd:\mdn_erp_test-100-9-30' 
WITH  FILE = 1
,  MOVE N'Mdn_ERP_backup_Data' TO N'F:\MDNKids.DB\MDN_ERP_TEST.MDF'
,  MOVE N'Mdn_ERP_backup_Log' TO N'F:\MDNKids.DB\MDN_ERP_TEST_1.LDF'
,  NOUNLOAD
,  STATS = 10
GO
--2. 砍掉舊使用者	TQuarker
USE [MDN_ERP_TEST]
GO
EXEC dbo.sp_dropuser N'TQuarker';
--3. 允許使用者使用資料庫 MDN_ERP
USE [MDN_ERP_TEST]
GO
EXEC dbo.sp_grantdbaccess @loginame = N'TQuarker', @name_in_db = N'TQuarker';
EXEC dbo.sp_addrolemember 'db_owner', 'TQuarker';
--4. 修改登入用 admin 密碼
USE [MDN_ERP_TEST]
GO
UPDATE [_Login] SET i_password = '8709' WHERE i_Name = 'Admin'
--5. 維護資料庫 MDN_ERP_TEST
ALTER DATABASE [MDN_ERP_TEST] SET RECOVERY SIMPLE WITH NO_WAIT
DBCC CHECKDB ('MDN_ERP_TEST')
ALTER DATABASE MDN_ERP_TEST SET SINGLE_USER WITH NO_WAIT
DBCC CHECKDB ('MDN_ERP_TEST', REPAIR_REBUILD)
ALTER DATABASE MDN_ERP_TEST SET MULTI_USER WITH NO_WAIT
DBCC UPDATEUSAGE('MDN_ERP_TEST')
DBCC SHRINKDATABASE('MDN_ERP_TEST')


/*----------------------------------------
    效能相關
----------------------------------------*/
--1.0 查詢連接數量
--SELECT * FROM SYS.DM_EXEC_CONNECTIONS
--1.1 查詢連接數量、讀寫數量
SELECT client_net_address
    , COUNT(*) AS 'CONNECTIONS'
    , SUM(num_reads) AS 'READ'
    , SUM(num_writes) AS 'WRITE'
FROM SYS.DM_EXEC_CONNECTIONS
GROUP BY client_net_address
ORDER BY client_net_address

--2.0 查詢工作階段
--SELECT * FROM sys.dm_exec_sessions
--2.1 查詢工作階段數量、讀寫數量
SELECT 
    host_name
    , login_name
    , program_name
    , COUNT(*) AS 'SESSIONS'
    , SUM(cpu_time) AS 'CPU'
    , SUM(memory_usage) AS 'MEM'
    , SUM(reads) AS 'READ'
    , SUM(writes) AS 'WRITE'
FROM sys.dm_exec_sessions
WHERE program_name NOT LIKE '%Microsoft SQL Server Management Studio%' 
    AND program_name NOT LIKE '%dbForge SQL Complete Express%'
    AND program_name NOT LIKE '%SQLAgent%'
    AND program_name NOT LIKE '%SQL Server Profiler%'
    AND program_name NOT LIKE '%Report Server%'
    AND program_name NOT LIKE '%Internet Information Services%'    
GROUP BY host_name, login_name, program_name
ORDER BY host_name, login_name, program_name

--3.0 查詢要求
--SELECT * FROM sys.dm_exec_requests
--3.1 查詢工作階段數量、讀寫數量
SELECT 
    TBA.database_id
    , TBB.name
    , TBA.status
    , COUNT(*) AS 'REQUESTS'
    , SUM(cpu_time) AS 'CPU'
    , SUM(reads) AS 'READ'
    , SUM(writes) AS 'WRITE'
FROM sys.dm_exec_requests AS TBA
JOIN sys.databases AS TBB
    ON TBA.database_id = TBB.database_id
GROUP BY TBA.database_id, TBB.name, status
ORDER BY TBA.database_id, TBB.name, status

--4.0 查詢要求
--SELECT * FROM sys.dm_exec_query_stats
--4.1 查詢工作階段數量、讀寫數量
SELECT 
    cp.usecounts as '使用次數'
    , objtype as '快取類型'
    --, cp.dbid
    , st.text
FROM sys.dm_exec_cached_plans cp
CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS st
WHERE st.text not like '%sys%' and objtype = 'Adhoc'
and st.text like '%top%' and st.text not like '%declare%'
ORDER BY cp.usecounts DESC




USE [SRP]
GO

WITH TList AS 
(
	SELECT DISTINCT
		'T' + RIGHT('00000' + CAST(ROW_NUMBER() OVER (ORDER BY S.[name], T.[name]) AS VARCHAR), 4) AS [Sid]
		, T.[object_id] AS [ObjectId]
		, '[' + S.[name] + '].[' + T.[name] + ']' AS [ObjectName]
		, 0 AS [ColumnId]
		, ISNULL([0-資料表描述], N'') AS [ColumnName]
		, ISNULL([1-用途說明], N'') AS [ColumnType]
		, N'' AS [ColumnDesc]
	FROM sys.tables AS T
	INNER JOIN sys.schemas AS S
		ON T.[schema_id] = S.[schema_id]
	LEFT JOIN (
		SELECT [major_id], [0-資料表描述], [1-用途說明]
		FROM sys.extended_properties
		PIVOT (
			MAX([value])
			FOR [name] IN ([0-資料表描述], [1-用途說明])
		) AS P
		WHERE [minor_id] = 0
	) AS EXTP
		ON T.[object_id] = EXTP.[major_id]
)
, CList AS
(
	SELECT
		'C' + RIGHT('00000' + CAST(ROW_NUMBER() OVER (ORDER BY S.[name], T.[name], C.[column_id]) AS VARCHAR), 4) AS [Sid]
		, T.[object_id] AS [ObjectId]
		, '[' + S.[name] + '].[' + T.[name] + ']' AS [ObjectName]
		, C.[column_id] AS [ColumnId]
		, C.[name] AS [ColumnName]
		, TP.[name] 
			+ (
				CASE
					WHEN TP.[name] IN ('varchar', 'nvarchar') AND C.[max_length] = -1 THEN ' (max)'
					WHEN TP.[name] IN ('char', 'varchar') THEN ' (' + CAST(C.[max_length] AS VARCHAR) + ')'
					WHEN TP.[name] IN ('nchar', 'nvarchar') THEN ' (' + CAST(C.[max_length]/2 AS VARCHAR) + ')'
					WHEN TP.[name] IN ('decimal') THEN ' (' + CAST(C.[precision] AS VARCHAR) + ',' + CAST(C.[scale] AS VARCHAR) + ')'
					ELSE ''
				END
			) AS [ColumnType]
		, (
			CASE
				WHEN C.[name] IN ('SchoolGUID', 'SystemGUID', 'TimeStamp') THEN N'--免填--'
				ELSE ISNULL(EXTP.[value], '')				
			END
		) AS [ColumnDesc]
	FROM sys.tables AS T
	INNER JOIN sys.columns AS C
		ON T.[object_id] = C.[object_id]
	INNER JOIN sys.schemas AS S
		ON T.[schema_id] = S.[schema_id]
	INNER JOIN sys.types AS TP
		ON C.[system_type_id] = TP.[system_type_id]
		AND C.[user_type_id] = TP.[user_type_id]	
	LEFT JOIN sys.extended_properties AS EXTP
		ON T.[object_id] = EXTP.[major_id]
		AND C.[column_id] = EXTP.[minor_id]
)
SELECT *
FROM
(
	SELECT * FROM TList
	UNION
	SELECT * FROM CList
) AS TCList
ORDER BY [ObjectName], [ColumnId]
