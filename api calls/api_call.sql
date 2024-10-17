CREATE OR ALTER PROC p_GetCreditScore
(
	@ClientID		ClientID,
	@Score			nVarchar(5) Output
)
AS 

BEGIN

	SET NOCOUNT ON

	DECLARE 
		@Object				int,
		@TokenURL			nVarchar(max),
		@TokenRequest		varchar(max),
		@TokenResponse		varchar(8000),
		@CustomerURL		nVarchar(max),
		@CustomerRequest	varchar(8000),
		@CustomerResponse	varchar(8000),
		@ScoreURL			nVarchar(max),
		@ScoreRequest		varchar(8000),
		@ScoreResponse		varchar(8000),
		@SessionCode		nVarchar(max),
		@CustomerRegistryID	nVarchar(40),
		--@Score				nVarchar(5),
		@BVN				nVarchar(50)
		

	Create Table #ScoreRequest
	(
		SessionCode				nVarchar(50),
		CustomerRegistryIDList	nVarchar(50),
		EnquiryReason			nVarchar(40)
	)

	SET @TokenURL = 'https://api.creditregistry.com/nigeria/AutoCred/Test/v8/api/Login'

	SET @CustomerURL = 'https://api.creditregistry.com/nigeria/AutoCred/Test/v8/api/FindDetail'

	SET @ScoreURL = 'https://api.creditregistry.com/nigeria/AutoCred/Test/v8/api/GetReport202'

	--first part is get session code
	SET @TokenRequest = '{"EmailAddress": "samuel.ukpebor@fcmb.com","SubscriberID": "736428735653634598","Password": "CSAdmin@1"}'

	Exec p_WriteLogs '/api/Login/', 'REQUEST', @TokenRequest
	
	EXEC sp_OACreate 'MSXML2.XMLHTTP', @Object OUT;
	EXEC sp_OAMethod @Object, 'open', NULL, 'post', @TokenURL, 'false'
	EXEC sp_OAMethod @Object, 'setRequestHeader', null, 'Content-Type', 'application/json'
	EXEC sp_OAMethod @Object, 'send', null, @TokenRequest
	EXEC sp_OAMethod @Object, 'responseText', @TokenResponse OUTPUT
	EXEC sp_OADestroy @Object

	Exec p_WriteLogs '/api/Login/', 'RESPONSE', @TokenResponse
	
	Select 
		@SessionCode = SessionCode
	From OpenJson(@TokenResponse)
	With(
		SessionCode varchar(20) '$.SessionCode '
	)

	--next get CustomerRegistryID
	Create Table #CustomerRequest
	(
		SessionCode			nVarchar(50),
		CustomerQuery		nVarchar(50),
		GetNoMatchReport	nVarchar(40),
		MinRelevance		int,
		MaxRecords			int,
		EnquiryReason		nVarchar(40)
	)

	SELECT @BVN = Fax From t_Client WHERE ClientID = @ClientID
	
	Insert Into #CustomerRequest	
	Select 
		@SessionCode, @BVN, 'IfNoMatch', 0, 0, 'KYCCheck'

	SET @CustomerRequest = (SELECT * FROM #CustomerRequest FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
	
	Exec p_WriteLogs '/api/FindDetail/', 'REQUEST', @CustomerRequest

	EXEC sp_OACreate 'MSXML2.XMLHTTP', @Object OUT;
	EXEC sp_OAMethod @Object, 'open', NULL, 'post', @CustomerURL, 'false'
	EXEC sp_OAMethod @Object, 'setRequestHeader', null, 'Content-Type', 'application/json'
	EXEC sp_OAMethod @Object, 'send', null, @CustomerRequest
	EXEC sp_OAMethod @Object, 'responseText', @CustomerResponse OUTPUT
	EXEC sp_OADestroy @Object

	Exec p_WriteLogs '/api/FindDetail/', 'RESPONSE', @CustomerResponse

	Select 
		@CustomerRegistryID = RegistryID
	From OpenJson(@CustomerResponse, '$.SearchResult')
	With(
		RegistryID varchar(40) '$.RegistryID'
	)

	--then get the score with the CustomerRegistryID returned above
	SET @ScoreRequest = (SELECT * FROM #ScoreRequest FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)

	SET @ScoreRequest = '{' +
		'"SessionCode": "' + @SessionCode + '",' +
		'"CustomerRegistryIDList": ["' + @CustomerRegistryID + '"],' +
		'"EnquiryReason": "KYCCheck"' +
	'}'

	Exec p_WriteLogs '/api/GetReport202/', 'REQUEST', @ScoreRequest

	EXEC sp_OACreate 'MSXML2.XMLHTTP', @Object OUT;
	EXEC sp_OAMethod @Object, 'open', NULL, 'post', @ScoreURL, 'false'
	EXEC sp_OAMethod @Object, 'setRequestHeader', null, 'Content-Type', 'application/json'
	EXEC sp_OAMethod @Object, 'send', null, @ScoreRequest
	EXEC sp_OAMethod @Object, 'responseText', @ScoreResponse OUTPUT
	EXEC sp_OADestroy @Object

	Exec p_WriteLogs '/api/GetReport202/', 'RESPONSE', @ScoreResponse

	Select 
		@Score = GenericScore
	From OpenJson(@ScoreResponse, '$.SMARTScores')
	With(
		GenericScore varchar(20) '$.GenericScore'
	)

	--Select @Score Score

	SET NOCOUNT OFF

END

--Go
--EXEC p_GetCreditScore @ClientID='000070006'
