
CREATE OR ALTER PROC p_WriteLogs
(
	@EndPoint		varchar(max),
	@Type			varchar(30),	--REQUEST/RESPONSE
	@Content		varchar(max)
)

AS

BEGIN

	SET NOCOUNT ON

	DECLARE 
		@Path			varchar(255),
		@Message		varchar(max),
		@HandleFile		int,
		@ObjTextStream	int

	SET @Path = 'C:\BRExceptionLog\AutoCredLogs-' + Convert(varchar, GetDate(), 112) + '.txt'

	IF @Type = 'REQUEST'
	BEGIN
		SET @Message = 
		'Method: ' + @EndPoint + char(13) + Char(10) +
		'Request' + char(13) + Char(10) +
		'Params: ' + @Content + char(13) + Char(10) +
		'Date: ' + Convert(varchar, GetDate(), 107) + ' ' + Convert(varchar, GetDate(), 108) + ' ' + FORMAT(CAST(GetDate() AS DATETIME), 'tt') 
		/*As [MMM DD, YYYY HH:MM:SS]*/ + char(13) + Char(10) +
		'------------------------'
	END

	IF @Type = 'RESPONSE'
	BEGIN
		SET @Message = 
		'Method: ' + @EndPoint + char(13) + Char(10) +
		'Response' + char(13) + Char(10) +
		'Message: ' + @Content + char(13) + Char(10) +
		'Date: ' + Convert(varchar, GetDate(), 107) + ' ' + Convert(varchar, GetDate(), 108) + ' ' + FORMAT(CAST(GetDate() AS DATETIME), 'tt') 
		/*As [MMM DD, YYYY HH:MM:SS]*/ + char(13) + Char(10) +
		'------------------------'
	END

	-- Attempt to open the file for writing
	EXEC sp_OACreate 'Scripting.FileSystemObject', @HandleFile OUTPUT;

	-- Attempt to write to the file
	EXEC sp_OAMethod @HandleFile, 'OpenTextFile', @ObjTextStream OUTPUT, @Path, 8, 1;	
	EXEC sp_OAMethod @ObjTextStream, 'WriteLine', NULL, @Message;

	-- Attempt to close the file
	EXEC sp_OADestroy @ObjTextStream
	EXEC sp_OADestroy @HandleFile;

	SET NOCOUNT OFF

END

--GO
--Exec p_WriteFile '/api/Login/', 'REQUEST', '{json body here}'
