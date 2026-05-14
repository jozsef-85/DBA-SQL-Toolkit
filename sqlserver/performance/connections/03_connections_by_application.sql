/*
    Script: 03_connections_by_application.sql
    Proposito:
        Agrupar sesiones por nombre de aplicacion y estado.

    Cuando usar:
        Para detectar aplicaciones con exceso de conexiones, pooling mal
        configurado o muchas sesiones sleeping.

    Como usar:
        Ejecutar a nivel de instancia.

    Que revisar:
        program_name, status, total_sessions y ultimas solicitudes.

    Eficiencia:
        Liviana. Usa sys.dm_exec_sessions y no recupera texto SQL.
*/

SELECT
    COALESCE(NULLIF(s.program_name, ''), '(sin program_name)') AS program_name,
    s.status,
    COUNT(*) AS total_sessions,
    SUM(s.cpu_time) AS cpu_time_ms,
    SUM(s.total_elapsed_time) AS elapsed_time_ms,
    SUM(s.reads) AS reads,
    SUM(s.writes) AS writes,
    SUM(s.logical_reads) AS logical_reads,
    MAX(s.last_request_start_time) AS last_request_start_time
FROM sys.dm_exec_sessions s
WHERE s.is_user_process = 1
GROUP BY COALESCE(NULLIF(s.program_name, ''), '(sin program_name)'), s.status
ORDER BY total_sessions DESC, cpu_time_ms DESC;
