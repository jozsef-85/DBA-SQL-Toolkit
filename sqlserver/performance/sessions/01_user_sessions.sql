/*
    Script: 01_user_sessions.sql
    Proposito:
        Segundo paso para revisar actividad visible de usuarios.
        Lista solicitudes activas de usuarios, excluyendo procesos internos.

    Cuando usar:
        Despues de revisar waits o cuando se sospecha de una sesion de aplicacion.

    Como usar:
        Ejecutar a nivel de instancia. Revisar wait_type, blocking_session_id,
        reads, writes, logical_reads, host_name y program_name.

    Siguiente paso:
        Si hay bloqueo, seguir con sqlserver/blocking/01_blocked_sessions.sql.
        Si hay actividad alta de I/O, seguir con
        sqlserver/performance/io/01_io_file_interval.sql.
*/

SELECT TOP 30
    r.session_id,
    DB_NAME(r.database_id) AS database_name,
    r.status,
    r.command,
    r.wait_type,
    r.blocking_session_id,
    r.cpu_time,
    r.total_elapsed_time / 1000 AS elapsed_sec,
    r.reads,
    r.writes,
    r.logical_reads,
    s.login_name,
    s.host_name,
    s.program_name,
    SUBSTRING(
        t.text,
        (r.statement_start_offset / 2) + 1,
        CASE 
            WHEN r.statement_end_offset = -1 
                THEN LEN(CONVERT(nvarchar(max), t.text))
            ELSE (r.statement_end_offset - r.statement_start_offset) / 2 + 1
        END
    ) AS running_statement,
    t.text AS full_text
FROM sys.dm_exec_requests r
JOIN sys.dm_exec_sessions s
    ON r.session_id = s.session_id
OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) t
WHERE r.session_id <> @@SPID
  AND s.is_user_process = 1
ORDER BY 
    r.writes DESC,
    r.reads DESC,
    r.logical_reads DESC;
