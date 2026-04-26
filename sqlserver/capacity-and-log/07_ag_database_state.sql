/*
    Script: 07_ag_database_state.sql
    Descripción:
        Valida el estado local de bases en Always On Availability Groups.

    Uso:
        Ejecutar en cada réplica antes de tareas de mantenimiento.
        Confirmar si la base local es PRIMARY o SECONDARY.

    Escenario:
        Usado para evitar ejecutar tareas de mantenimiento sobre una réplica equivocada.
*/

SELECT
    @@SERVERNAME AS server_name,
    DB_NAME(drs.database_id) AS database_name,
    ars.role_desc AS local_replica_role,
    drs.is_local,
    drs.synchronization_state_desc,
    drs.is_commit_participant,
    CASE
        WHEN sys.fn_hadr_is_primary_replica(DB_NAME(drs.database_id)) = 1 THEN 'PRIMARY'
        ELSE 'SECONDARY'
    END AS database_role_check
FROM sys.dm_hadr_database_replica_states drs
JOIN sys.availability_replicas ar
    ON drs.replica_id = ar.replica_id
JOIN sys.dm_hadr_availability_replica_states ars
    ON ar.replica_id = ars.replica_id
WHERE drs.is_local = 1
ORDER BY DB_NAME(drs.database_id);