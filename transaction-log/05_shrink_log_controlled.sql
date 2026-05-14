/*
    Script: 05_shrink_log_controlled.sql
    Uso:
        Plantilla para shrink controlado del archivo de log.
        Reemplazar NOMBRE_DB, NOMBRE_LOGICO_LOG y tamano objetivo en MB.

    Importante:
        Ejecutar solo despues de validar log_reuse_wait_desc, backup de log
        y uso real del log. No usar como mantenimiento recurrente.
*/

USE [NOMBRE_DB];
GO

DBCC SHRINKFILE (N'NOMBRE_LOGICO_LOG', 20480); -- tamaño en MB
GO
