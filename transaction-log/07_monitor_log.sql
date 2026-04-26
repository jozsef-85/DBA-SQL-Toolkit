-- Monitoreo rápido de logs

SELECT
    d.name,
    ls.total_log_size_mb,
    ls.active_log_size_mb,
    CAST((ls.active_log_size_mb * 100.0 / ls.total_log_size_mb) AS DECIMAL(10,2)) AS used_pct,
    ls.total_vlf_count,
    ls.active_vlf_count,
    ls.log_backup_time,
    d.log_reuse_wait_desc
FROM sys.databases d
CROSS APPLY sys.dm_db_log_stats(d.database_id) ls
WHERE d.database_id > 4
ORDER BY used_pct DESC;