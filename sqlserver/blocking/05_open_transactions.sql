/*
    Script: 05_open_transactions.sql
    Proposito:
        Quinto paso cuando se sospecha que una transaccion larga sostiene el bloqueo.
        Revisa transacciones abiertas por sesion.

    Cuando usar:
        Cuando el bloqueo persiste, open_transaction_count es alto
        o se sospecha una transaccion sin commit/rollback.

    Como usar:
        Dejar @session_id en NULL para listar todas las transacciones abiertas.
        Definir @session_id para enfocar el analisis en una sesion puntual.

    Que revisar:
        transaction_begin_time y minutes_open para priorizar transacciones antiguas.
*/

DECLARE @session_id INT = NULL; -- Opcional: session_id a revisar.

SELECT
    s.session_id,
    s.login_name,
    s.host_name,
    s.program_name,
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
WHERE @session_id IS NULL
   OR s.session_id = @session_id
ORDER BY at.transaction_begin_time;
