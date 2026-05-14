/*
    Script: 07_shrink_log_controlled.sql
    Proposito:
        Plantilla para shrink controlado del archivo de log.

    Cuando usar:
        Solo despues de confirmar que el log ya reutiliza espacio y que existe
        espacio libre interno significativo.

    Como usar:
        1. Validar uso y reutilizacion con sqlserver/transaction-log/03_log_space_and_reuse.sql.
        2. Validar seguimiento con sqlserver/transaction-log/05_monitor_log.sql.
        3. Reemplazar NOMBRE_DB, NOMBRE_LOGICO_LOG y tamano objetivo en MB.
        4. Ejecutar por etapas y validar despues de cada ejecucion.

    Precauciones:
        Ejecutar solo despues de validar log_reuse_wait_desc, backup de log
        y uso real del log. No usar como mantenimiento recurrente.
*/

USE [NOMBRE_DB];
GO

DBCC SHRINKFILE (N'NOMBRE_LOGICO_LOG', 20480); -- tamaño en MB
GO
