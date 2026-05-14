/*
    Script: 03_blocking_inputbuffer.sql
    Proposito:
        Tercer paso para ver la ultima instruccion enviada por el bloqueador.
        Muestra la ultima instruccion enviada por una sesion especifica.

    Cuando usar:
        Cuando ya se identifico el SPID bloqueante y se necesita ver
        rapidamente la ultima instruccion enviada.

    Como usar:
        1. Ejecutar primero sqlserver/blocking/01_blocked_sessions.sql
           para identificar session_id o blocking_session_id.
        2. Asignar el valor encontrado a @session_id.
        3. Ejecutar este script.

    Precauciones:
        DBCC INPUTBUFFER requiere un session_id concreto.
        La instruccion puede no representar todo el batch ni el plan completo.
*/

DECLARE @session_id SMALLINT = NULL; -- Reemplazar por el SPID a revisar.

IF @session_id IS NULL
BEGIN
    THROW 50000, 'Debe definir @session_id antes de ejecutar DBCC INPUTBUFFER.', 1;
END;

DBCC INPUTBUFFER (@session_id) WITH NO_INFOMSGS;
