/*
    Script: 02_log_status_gb.sql
    Descripción:
        Muestra el tamaño actual del transaction log,
        porcentaje usado, GB usados y GB libres por base.

    Uso:
        Ejecutar a nivel de instancia.
        Útil para revisar estado actual del TLOG.

    Referencia:
        DBCC SQLPERF(LOGSPACE) entrega estadísticas de uso del transaction log
        para todas las bases. Microsoft lo recomienda para monitorear espacio usado
        en logs. 
*/

IF OBJECT_ID('tempdb..#logspace') IS NOT NULL
    DROP TABLE #logspace;

CREATE TABLE #logspace
(
    DatabaseName sysname,
    LogSizeMB DECIMAL(18,2),
    LogSpaceUsedPct DECIMAL(18,2),
    Status INT
);

INSERT INTO #logspace
EXEC ('DBCC SQLPERF(LOGSPACE)');

SELECT
    DatabaseName,
    CAST(LogSizeMB / 1024.0 AS DECIMAL(18,2)) AS log_size_gb,
    LogSpaceUsedPct,
    CAST((LogSizeMB * LogSpaceUsedPct / 100.0) / 1024.0 AS DECIMAL(18,2)) AS log_used_gb,
    CAST((LogSizeMB * (100.0 - LogSpaceUsedPct) / 100.0) / 1024.0 AS DECIMAL(18,2)) AS log_free_gb,
    Status
FROM #logspace
ORDER BY log_size_gb DESC;