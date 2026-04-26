-- Uso real del log

DBCC SQLPERF(LOGSPACE);

-- Estado de reutilización

SELECT
    name,
    recovery_model_desc,
    log_reuse_wait_desc
FROM sys.databases
ORDER BY name;