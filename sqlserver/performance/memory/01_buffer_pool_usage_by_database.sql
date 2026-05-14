/*
    Script: 01_buffer_pool_usage_by_database.sql
    Proposito:
        Estimar cuanta memoria del buffer pool esta usando cada base de datos.

    Cuando usar:
        En diagnosticos de presion de memoria o cuando se necesita identificar
        que bases mantienen mas paginas en cache.

    Como usar:
        Ejecutar a nivel de instancia. Requiere VIEW SERVER STATE.

    Que revisar:
        buffer_pool_mb y buffer_pool_pct muestran participacion relativa dentro
        del buffer pool, no consumo total de memoria de SQL Server.

    Eficiencia:
        Consulta sys.dm_os_buffer_descriptors, que puede tener muchas filas
        en instancias grandes. Es solo lectura, pero conviene ejecutarla fuera
        de ventanas muy sensibles si el servidor esta bajo presion extrema.
*/

WITH buffer_by_database AS
(
    SELECT
        database_id,
        COUNT_BIG(*) AS buffer_pages
    FROM sys.dm_os_buffer_descriptors
    GROUP BY database_id
),
total_buffer AS
(
    SELECT SUM(buffer_pages) AS total_pages
    FROM buffer_by_database
)
SELECT
    CASE b.database_id
        WHEN 32767 THEN 'Resource DB'
        ELSE DB_NAME(b.database_id)
    END AS database_name,
    b.buffer_pages,
    CAST(b.buffer_pages / 128.0 AS DECIMAL(18,2)) AS buffer_pool_mb,
    CAST(b.buffer_pages * 100.0 / NULLIF(t.total_pages, 0) AS DECIMAL(6,3)) AS buffer_pool_pct
FROM buffer_by_database b
CROSS JOIN total_buffer t
ORDER BY buffer_pool_mb DESC;
