/*
    Script: 03_log_space_and_reuse.sql
    Proposito:
        Revisa uso actual del transaction log, estado de reutilizacion
        y ultimo backup de log registrado en msdb.

    Cuando usar:
        Tercer paso para entender por que el log no reutiliza espacio
        o por que sigue creciendo.

    Como usar:
        Ejecutar a nivel de instancia.
        Ejecutar antes de decidir backup manual, shrink o ajuste de crecimiento.

    Que revisar:
        recovery_model_desc, log_reuse_wait_desc, last_log_backup
        y minutes_since_last_log_backup.
*/

-- Uso real del log.

DBCC SQLPERF(LOGSPACE);

-- Estado de reutilizacion.

SELECT
    name,
    recovery_model_desc,
    log_reuse_wait_desc
FROM sys.databases
ORDER BY name;

-- Ultimo backup de log ejecutado.

USE master;
GO

SELECT
    d.name AS database_name,
    d.recovery_model_desc,
    d.log_reuse_wait_desc,
    MAX(bs.backup_finish_date) AS last_log_backup,
    DATEDIFF(MINUTE, MAX(bs.backup_finish_date), GETDATE()) AS minutes_since_last_log_backup
FROM sys.databases d
LEFT JOIN msdb.dbo.backupset bs
    ON d.name = bs.database_name
   AND bs.type = 'L'
WHERE d.database_id > 4
GROUP BY
    d.name,
    d.recovery_model_desc,
    d.log_reuse_wait_desc
ORDER BY d.name;
GO
