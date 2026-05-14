/*
================================================================================
Script : 01_detectar_dbcc_activo.sql
Objetivo: Detectar sesiones DBCC activas o en rollback.
Uso     : Ejecutar primero ante presencia de archivos *_MSSQL_DBCC* o sospecha de
          CHECKDB/CHECKTABLE detenido.
Riesgo  : Solo lectura.
================================================================================
*/

SET NOCOUNT ON;

SELECT
    GETDATE() AS fecha_revision,
    r.session_id,
    s.login_name,
    s.host_name,
    s.program_name,
    r.status,
    r.command,
    DB_NAME(r.database_id) AS database_name,
    r.percent_complete,
    r.start_time,
    DATEDIFF(MINUTE, r.start_time, GETDATE()) AS elapsed_minutes,
    r.wait_type,
    r.wait_time,
    r.last_wait_type,
    r.blocking_session_id,
    r.cpu_time,
    r.reads,
    r.writes,
    r.logical_reads,
    r.estimated_completion_time / 1000 / 60 AS estimated_minutes_remaining,
    t.text AS sql_text
FROM sys.dm_exec_requests AS r
JOIN sys.dm_exec_sessions AS s
    ON s.session_id = r.session_id
OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) AS t
WHERE
       r.command LIKE '%DBCC%'
    OR r.command = 'KILLED/ROLLBACK'
    OR t.text LIKE '%CHECKDB%'
    OR t.text LIKE '%CHECKTABLE%'
ORDER BY
    r.start_time ASC;
