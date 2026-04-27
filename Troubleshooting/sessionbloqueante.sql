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
WHERE s.session_id = 228;