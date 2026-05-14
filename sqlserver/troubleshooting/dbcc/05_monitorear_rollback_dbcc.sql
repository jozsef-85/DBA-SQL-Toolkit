/*
================================================================================
Script : 05_monitorear_rollback_dbcc.sql
Objetivo: Monitorear una sesion DBCC que ya quedo en rollback.
Uso     : Definir @session_id con el SPID validado previamente.
Riesgo  : Solo lectura.
================================================================================
*/

SET NOCOUNT ON;

DECLARE @session_id INT = NULL; -- Ejemplo: 177

IF @session_id IS NULL
BEGIN
    RAISERROR('Debe definir @session_id antes de ejecutar.', 16, 1);
    RETURN;
END;

SELECT
    GETDATE() AS fecha_revision,
    r.session_id,
    r.status,
    r.command,
    DB_NAME(r.database_id) AS database_name,
    r.percent_complete,
    r.wait_type,
    r.wait_time,
    r.last_wait_type,
    r.blocking_session_id,
    r.cpu_time,
    r.reads,
    r.writes,
    r.logical_reads,
    r.estimated_completion_time / 1000 / 60 AS estimated_minutes_remaining
FROM sys.dm_exec_requests AS r
WHERE r.session_id = @session_id;
