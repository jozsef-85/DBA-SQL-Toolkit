SELECT
    s.session_id,
    s.open_transaction_count,
    at.transaction_begin_time,
    at.transaction_type,
    at.transaction_state,
    DATEDIFF(MINUTE, at.transaction_begin_time, GETDATE()) AS minutes_open
FROM sys.dm_exec_sessions s
JOIN sys.dm_tran_session_transactions st
    ON s.session_id = st.session_id
JOIN sys.dm_tran_active_transactions at
    ON st.transaction_id = at.transaction_id
WHERE s.session_id = 228;