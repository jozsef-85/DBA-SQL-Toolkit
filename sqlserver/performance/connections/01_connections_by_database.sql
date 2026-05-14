/*
    Script: 01_connections_by_database.sql
    Proposito:
        Contar conexiones/sesiones actuales agrupadas por base de datos.

    Cuando usar:
        Primer paso para revisar concentracion de conexiones por base durante
        incidentes de saturacion, timeouts o uso excesivo de sesiones.

    Como usar:
        Ejecutar a nivel de instancia. Usa DMVs modernas en lugar de sys.sysprocesses.

    Que revisar:
        total_sessions, running_sessions, sleeping_sessions y last_request_start_time.

    Eficiencia:
        Liviana. Lee sys.dm_exec_sessions y no ejecuta CROSS APPLY ni texto SQL.
*/

SELECT
    DB_NAME(s.database_id) AS database_name,
    COUNT(*) AS total_sessions,
    SUM(CASE WHEN s.status = 'running' THEN 1 ELSE 0 END) AS running_sessions,
    SUM(CASE WHEN s.status = 'sleeping' THEN 1 ELSE 0 END) AS sleeping_sessions,
    MAX(s.last_request_start_time) AS last_request_start_time
FROM sys.dm_exec_sessions s
WHERE s.is_user_process = 1
GROUP BY DB_NAME(s.database_id)
ORDER BY total_sessions DESC, database_name;
