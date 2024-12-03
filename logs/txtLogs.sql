---- First of all below Ole Automation Procedures need to be enabled on your db server for the file methods to work
---- Uncomment below execs and run first
--EXEC sp_configure 'show advanced options', 1;
--RECONFIGURE;
--EXEC sp_configure 'ole automation procedures', 1;
--RECONFIGURE;

-- Create Procedure to Write the txt Log files
CREATE OR ALTER PROC p_Log
(
	@Message		varchar(max)
)

AS

BEGIN

	SET NOCOUNT ON

	DECLARE 
		@Path			varchar(255),
		@HandleFile		int,
		@ObjTextStream	int

	-- Path where the txt file will be saved
	SET @Path = 'C:\Users\<YourUserName>\Logs\Log-' + Convert(varchar, GetDate(), 112) + '.txt'

	-- The actual content of the text file
	SET @Message = 
	'Date: ' + Convert(varchar, GetDate(), 107) + ' ' + Convert(varchar, GetDate(), 108) + ' ' + FORMAT(CAST(GetDate() AS DATETIME), 'tt') 
	+ char(13) + Char(10)
	+ 'Message: ' + @Message + char(13) + Char(10) +
	'------------------------'

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
--Exec p_Log 'Write Message Here'
