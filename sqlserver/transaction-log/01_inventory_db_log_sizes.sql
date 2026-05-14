/*
    Script: 01_inventory_db_log_sizes.sql
    Proposito:
        Inventario rapido de tamanos DATA vs LOG por base de usuario.

    Cuando usar:
        Primer paso para detectar logs sobredimensionados, bases con mayor
        consumo total o diferencias relevantes entre data y log.

    Como usar:
        Ejecutar a nivel de instancia para detectar logs sobredimensionados
        o bases con crecimiento relevante.

    Siguiente paso:
        Ejecutar sqlserver/transaction-log/02_log_status_gb.sql para revisar
        porcentaje usado del log.
*/

SELECT
    @@SERVERNAME AS instance_name,
    d.name AS database_name,
    CAST(SUM(CASE WHEN mf.type_desc = 'ROWS' THEN mf.size END) / 128.0 / 1024 AS DECIMAL(18,2)) AS data_size_gb,
    CAST(SUM(CASE WHEN mf.type_desc = 'LOG' THEN mf.size END) / 128.0 / 1024 AS DECIMAL(18,2)) AS log_size_gb,
    CAST(SUM(mf.size) / 128.0 / 1024 AS DECIMAL(18,2)) AS total_size_gb,
    d.recovery_model_desc,
    d.log_reuse_wait_desc
FROM sys.databases d
JOIN sys.master_files mf ON d.database_id = mf.database_id
WHERE d.database_id > 4
GROUP BY d.name, d.recovery_model_desc, d.log_reuse_wait_desc
ORDER BY total_size_gb DESC;
