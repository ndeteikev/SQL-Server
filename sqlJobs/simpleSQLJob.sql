-- Create the procedure to be run by the sql job
CREATE OR ALTER PROCEDURE dbo.p_UpdateStatus
AS
BEGIN

	SET NOCOUNT OFF

	UPDATE t_CRUD SET
		StatusCol = 'Active'
	WHERE StatusCol = 'Pending'

	SET NOCOUNT ON

END

-- Create new job
EXEC msdb.dbo.sp_add_job
    @job_name = N'j_UpdateStatus';

-- Add job step
EXEC msdb.dbo.sp_add_jobstep
    @job_name = N'j_UpdateStatus',
    @step_name = N'Run Update Procedure',
    @subsystem = N'TSQL',
    @command = N'EXEC dbo.p_UpdateStatus';

-- Create schedule
-- for different frequency types check codes below
EXEC msdb.dbo.sp_add_schedule
    @schedule_name = N'Every Few Seconds',
    @freq_type = 4,  -- Daily
    @freq_interval = 1,  -- Every day
	@freq_subday_type = 2,	-- Seconds
	@freq_subday_interval = 30,	-- Every 10 Seconds
    @active_start_time = 000000;  -- 12:00 AM

-- Attach job to schedule
EXEC msdb.dbo.sp_attach_schedule
    @job_name = N'j_UpdateStatus',
    @schedule_name = N'Every Few Seconds';

-- Optional: Add job server
EXEC msdb.dbo.sp_add_jobserver
    @job_name = N'j_UpdateStatus';

/********************************************/
/*
	use freq_type for frequencies above a day
	@freq_type = 1   -> Once
	@freq_type = 4	 -> Daily
	@freq_type = 8	 -> Weekly
	@freq_type = 16	 -> Monthly

	use freq_subday_type for frequencies below a day
	@freq_subday_type = 1	-> At specified time
	@freq_subday_type = 2	-> Seconds
	@freq_subday_type = 4	-> Minutes
	@freq_subday_type = 8	-> Hours
*/
