-- VLF analysis (SQL 2019+)

SELECT
    DB_NAME(database_id) AS database_name,
    COUNT(*) AS total_vlf,
    SUM(CASE WHEN vlf_active = 1 THEN 1 ELSE 0 END) AS vlf_activos,
    SUM(CASE WHEN vlf_active = 0 THEN 1 ELSE 0 END) AS vlf_inactivos
FROM sys.dm_db_log_info(NULL)
GROUP BY database_id
ORDER BY total_vlf DESC;