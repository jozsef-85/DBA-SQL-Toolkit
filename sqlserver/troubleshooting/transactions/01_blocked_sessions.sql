/*
    Script: 01_blocked_sessions.sql
    Uso:
        Primer paso ante sospecha de bloqueo.
        Lista sesiones actualmente bloqueadas.
        Usar session_id para revisar la sesion afectada.
        Usar blocking_session_id para revisar la sesion bloqueante.
*/

SELECT
    r.session_id,
    r.blocking_session_id,
    DB_NAME(r.database_id) AS database_name,
    r.status,
    r.command,
    r.wait_type,
    r.wait_time / 1000 AS wait_seconds,
    r.cpu_time,
    r.reads,
    r.writes,
    r.logical_reads,
    r.start_time
FROM sys.dm_exec_requests r
WHERE r.blocking_session_id <> 0
ORDER BY r.wait_time DESC;
