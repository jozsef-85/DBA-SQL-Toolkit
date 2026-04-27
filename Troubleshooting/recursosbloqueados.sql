SELECT
    tl.request_session_id,
    tl.resource_type,
    tl.resource_database_id,
    DB_NAME(tl.resource_database_id) AS database_name,
    tl.resource_associated_entity_id,
    tl.request_mode,
    tl.request_status
FROM sys.dm_tran_locks tl
WHERE tl.request_session_id IN (228, 75, 81, 94)
ORDER BY tl.request_session_id;