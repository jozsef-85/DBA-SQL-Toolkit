/*
    Script: 01_blocked_sessions.sql
    Proposito:
        Primer paso ante sospecha de bloqueo.
        Lista sesiones actualmente bloqueadas.

    Cuando usar:
        Cuando usuarios reportan procesos congelados, timeouts o esperas por locks.

    Como usar:
        Ejecutar a nivel de instancia.
        Usar session_id para revisar la sesion afectada.
        Usar blocking_session_id para revisar la sesion bloqueante.

    Siguiente paso:
        Usar blocking_session_id en sqlserver/blocking/02_blocking_session_detail.sql.
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
