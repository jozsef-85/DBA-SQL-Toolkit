/*
    Script: 02_connections_by_login.sql
    Proposito:
        Agrupar sesiones de usuario por login y resumir consumo acumulado.

    Cuando usar:
        Despues de revisar conexiones por base, para identificar usuarios
        o cuentas de aplicacion con muchas sesiones o actividad acumulada.

    Como usar:
        Ejecutar a nivel de instancia.

    Que revisar:
        total_sessions, cpu_time_ms, reads, writes y logical_reads.

    Eficiencia:
        Liviana. Evita sys.sysprocesses y usa sys.dm_exec_sessions.
*/

SELECT
    s.original_login_name AS login_name,
    COUNT(*) AS total_sessions,
    SUM(s.cpu_time) AS cpu_time_ms,
    SUM(s.total_scheduled_time) AS scheduled_time_ms,
    SUM(s.total_elapsed_time) AS elapsed_time_ms,
    SUM(s.reads) AS reads,
    SUM(s.writes) AS writes,
    SUM(s.logical_reads) AS logical_reads,
    MAX(s.last_request_start_time) AS last_request_start_time
FROM sys.dm_exec_sessions s
WHERE s.is_user_process = 1
GROUP BY s.original_login_name
ORDER BY total_sessions DESC, cpu_time_ms DESC;
