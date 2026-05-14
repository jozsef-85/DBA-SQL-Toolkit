/*
    Script: 04_locked_resources.sql
    Uso:
        Cuarto paso para entender que recursos estan bloqueados.
        Lista locks asociados a sesiones bloqueadas y bloqueantes activas.
        Dejar @session_id en NULL para revisar todo el bloqueo actual.
        Definir @session_id para enfocar el analisis en una sesion puntual.
*/

DECLARE @session_id INT = NULL; -- Opcional: session_id bloqueada o bloqueante.

WITH blocking_sessions AS
(
    SELECT DISTINCT r.session_id
    FROM sys.dm_exec_requests r
    WHERE r.blocking_session_id <> 0

    UNION

    SELECT DISTINCT r.blocking_session_id
    FROM sys.dm_exec_requests r
    WHERE r.blocking_session_id <> 0
)
SELECT
    tl.request_session_id,
    tl.resource_type,
    tl.resource_database_id,
    DB_NAME(tl.resource_database_id) AS database_name,
    tl.resource_associated_entity_id,
    tl.request_mode,
    tl.request_status
FROM sys.dm_tran_locks tl
WHERE
    (
        @session_id IS NULL
        AND tl.request_session_id IN (SELECT session_id FROM blocking_sessions)
    )
    OR tl.request_session_id = @session_id
ORDER BY tl.request_session_id;
