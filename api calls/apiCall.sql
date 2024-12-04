CREATE OR ALTER PROC p_APICall
(
	@URL		nVarchar(max),	--	The Endpoint to be called
	@Request	nVarchar(max) = ''	-- The parameters needed by the endpoint if any
)
AS 

BEGIN

	SET NOCOUNT ON

	DECLARE 
		@Object		int,
		@Response	varchar(8000)	-- The response returned

	BEGIN TRY

		IF ISNULL(@Request, '') = ''
			SET @Request = '{}'
			
		-- The actual api call
		EXEC sp_OACreate 'MSXML2.XMLHTTP', @Object OUT;
		EXEC sp_OAMethod @Object, 'open', NULL, 'post', @URL, 'false'
		EXEC sp_OAMethod @Object, 'setRequestHeader', null, 'Content-Type', 'application/json'
		EXEC sp_OAMethod @Object, 'send', null, @Request
		EXEC sp_OAMethod @Object, 'responseText', @Response OUTPUT
		EXEC sp_OADestroy @Object
	
		-- Return the value 
		Select @Response Response

	END TRY
	BEGIN CATCH
		SELECT ERROR_NUMBER(), ERROR_MESSAGE()
	END CATCH

	SET NOCOUNT OFF

END

--Go
--Begin Tran
--EXEC p_APICall 'http://<IP_ADDRESS>:<PORT>/api/<CONTROLLER>','{"param1":"value1","param2":"value2"}'
--Rollback Tran

