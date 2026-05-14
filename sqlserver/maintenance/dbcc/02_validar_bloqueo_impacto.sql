/*
================================================================================
Script : 02_validar_bloqueo_impacto.sql
Objetivo: Confirmar si un SPID DBCC activo o en KILLED/ROLLBACK esta bloqueando
          sesiones de aplicacion.
Uso     : Reemplazar @session_id por el SPID detectado en el script 01.
Riesgo  : Solo lectura.
================================================================================
*/

SET NOCOUNT ON;

DECLARE @session_id INT = NULL; -- Ejemplo: 177. Si queda NULL, busca DBCC/KILLED activos.

;WITH dbcc_spids AS
(
    SELECT r.session_id
    FROM sys.dm_exec_requests AS r
    OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) AS t
    WHERE
           (@session_id IS NOT NULL AND r.session_id = @session_id)
        OR (@session_id IS NULL AND (
               r.command LIKE '%DBCC%'
            OR r.command = 'KILLED/ROLLBACK'
            OR t.text LIKE '%CHECKDB%'
            OR t.text LIKE '%CHECKTABLE%'
        ))
)
SELECT
    GETDATE() AS fecha_revision,
    r.session_id,
    DB_NAME(r.database_id) AS database_name,
    r.status,
    r.command,
    r.wait_type,
    r.wait_time,
    r.blocking_session_id,
    s.login_name,
    s.host_name,
    s.program_name,
    t.text AS sql_text
FROM sys.dm_exec_requests AS r
JOIN sys.dm_exec_sessions AS s
    ON s.session_id = r.session_id
OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) AS t
WHERE r.blocking_session_id IN (SELECT session_id FROM dbcc_spids)
ORDER BY
    r.wait_time DESC,
    r.session_id;
