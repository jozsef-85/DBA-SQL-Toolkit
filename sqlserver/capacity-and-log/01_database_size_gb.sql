/*
    Script: 01_database_size_gb.sql
    Descripción:
        Muestra el tamaño total de cada base de datos en GB,
        separado entre archivos de datos y archivos de log.

    Uso:
        Ejecutar a nivel de instancia.
        Útil para identificar qué bases consumen más espacio.

    Escenario:
        Usado para detectar bases con archivos sobredimensionados.
*/

SELECT
    DB_NAME(mf.database_id) AS database_name,
    CAST(SUM(CASE WHEN mf.type_desc = 'ROWS' THEN mf.size ELSE 0 END) * 8.0 / 1024 / 1024 AS DECIMAL(18,2)) AS data_size_gb,
    CAST(SUM(CASE WHEN mf.type_desc = 'LOG'  THEN mf.size ELSE 0 END) * 8.0 / 1024 / 1024 AS DECIMAL(18,2)) AS log_size_gb,
    CAST(SUM(mf.size) * 8.0 / 1024 / 1024 AS DECIMAL(18,2)) AS total_size_gb
FROM sys.master_files mf
GROUP BY mf.database_id
ORDER BY total_size_gb DESC;