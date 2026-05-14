/*
    Script: 02_blocking_session_detail.sql
    Proposito:
        Segundo paso para identificar origen del bloqueo.
        Muestra informacion de la sesion bloqueante.

    Cuando usar:
        Despues de obtener blocking_session_id desde
        sqlserver/blocking/01_blocked_sessions.sql.

    Como usar:
        Dejar @session_id en NULL para listar bloqueadores activos.
        Definir @session_id para revisar una sesion especifica.

    Siguiente paso:
        Revisar la ultima instruccion con
        sqlserver/blocking/03_blocking_inputbuffer.sql.
*/

DECLARE @session_id INT = NULL; -- Opcional: blocking_session_id a revisar.

SELECT
    s.session_id,
    s.login_name,
    s.host_name,
    s.program_name,
    s.status,
    s.open_transaction_count,
    s.last_request_start_time,
    s.last_request_end_time,
    c.client_net_address
FROM sys.dm_exec_sessions s
LEFT JOIN sys.dm_exec_connections c
    ON s.session_id = c.session_id
WHERE
    (
        @session_id IS NULL
        AND EXISTS
        (
            SELECT 1
            FROM sys.dm_exec_requests r
            WHERE r.blocking_session_id = s.session_id
        )
    )
    OR s.session_id = @session_id
ORDER BY s.session_id;
