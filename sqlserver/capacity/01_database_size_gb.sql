/*
    Script: 01_database_size_gb.sql
    Proposito:
        Muestra el tamaño total de cada base de datos en GB,
        separado entre archivos de datos y archivos de log.

    Cuando usar:
        Primer paso en revisiones de capacidad o crecimiento.
        Sirve para identificar bases con mayor consumo total o logs grandes.

    Como usar:
        Ejecutar a nivel de instancia, preferentemente en master.

    Siguiente paso:
        Si una base requiere detalle por archivo, ejecutar
        sqlserver/capacity/02_file_space_used_gb.sql dentro de esa base.
*/

SELECT
    DB_NAME(mf.database_id) AS database_name,
    CAST(SUM(CASE WHEN mf.type_desc = 'ROWS' THEN mf.size ELSE 0 END) * 8.0 / 1024 / 1024 AS DECIMAL(18,2)) AS data_size_gb,
    CAST(SUM(CASE WHEN mf.type_desc = 'LOG'  THEN mf.size ELSE 0 END) * 8.0 / 1024 / 1024 AS DECIMAL(18,2)) AS log_size_gb,
    CAST(SUM(mf.size) * 8.0 / 1024 / 1024 AS DECIMAL(18,2)) AS total_size_gb
FROM sys.master_files mf
GROUP BY mf.database_id
ORDER BY total_size_gb DESC;
