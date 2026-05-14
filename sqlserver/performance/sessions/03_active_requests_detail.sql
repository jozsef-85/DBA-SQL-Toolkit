/*
    Script: 03_active_requests_detail.sql
    Proposito:
        Listar requests activos con informacion de sesion, espera y texto SQL.

    Cuando usar:
        Cuando se necesita ver que consultas estan corriendo ahora mismo,
        especialmente despues de identificar waits o muchas conexiones.

    Como usar:
        Ejecutar a nivel de instancia. Requiere VIEW SERVER STATE para ver
        sesiones de otros usuarios y texto SQL completo.

    Que revisar:
        elapsed_seconds, wait_type, blocking_session_id, reads, writes,
        logical_reads y running_statement.

    Eficiencia:
        Moderada y segura. Consulta requests activos y obtiene texto con
        sys.dm_exec_sql_text solo para requests en ejecucion. Evita
        master.dbo.sysprocesses, que es vista de compatibilidad antigua.
*/

SELECT
    r.session_id,
    DB_NAME(r.database_id) AS database_name,
    s.login_name,
    s.host_name,
    s.program_name,
    r.status,
    r.command,
    r.start_time,
    DATEDIFF(SECOND, r.start_time, GETDATE()) AS elapsed_seconds,
    r.cpu_time,
    r.reads,
    r.writes,
    r.logical_reads,
    r.wait_type,
    r.wait_time,
    r.blocking_session_id,
    SUBSTRING(
        t.text,
        (r.statement_start_offset / 2) + 1,
        CASE
            WHEN r.statement_end_offset = -1
                THEN LEN(CONVERT(NVARCHAR(MAX), t.text))
            ELSE (r.statement_end_offset - r.statement_start_offset) / 2 + 1
        END
    ) AS running_statement,
    t.text AS full_text
FROM sys.dm_exec_requests r
JOIN sys.dm_exec_sessions s
    ON s.session_id = r.session_id
OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) t
WHERE r.session_id <> @@SPID
  AND s.is_user_process = 1
ORDER BY r.start_time ASC;
