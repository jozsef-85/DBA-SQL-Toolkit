/*
    Script: 01_waits_overview.sql
    Proposito:
        Primer paso para orientar el diagnostico de lentitud.
        Revisa waits acumulados asociados normalmente a presion de I/O y HADR.

    Cuando usar:
        Al inicio de un incidente de lentitud general, timeouts o sospecha de I/O.

    Como usar:
        Ejecutar a nivel de instancia durante el incidente o compararlo con una linea base.

    Siguiente paso:
        Si aparecen waits de I/O o WRITELOG, revisar sesiones con
        sqlserver/performance/sessions/01_user_sessions.sql y luego I/O con
        sqlserver/performance/io/01_io_file_interval.sql.

    Nota:
        sys.dm_os_wait_stats es acumulado desde el ultimo reinicio del servicio
        o desde la ultima limpieza manual de waits.
*/

SELECT TOP 30
    wait_type,
    waiting_tasks_count,
    CAST(wait_time_ms / 1000.0 AS decimal(18,2)) AS wait_time_sec,
    CAST(signal_wait_time_ms / 1000.0 AS decimal(18,2)) AS signal_wait_sec,
    CAST((wait_time_ms - signal_wait_time_ms) / 1000.0 AS decimal(18,2)) AS resource_wait_sec,
    CAST(
        CASE 
            WHEN waiting_tasks_count = 0 THEN 0
            ELSE wait_time_ms * 1.0 / waiting_tasks_count 
        END AS decimal(18,2)
    ) AS avg_wait_ms
FROM sys.dm_os_wait_stats
WHERE wait_type IN
(
    'PAGEIOLATCH_SH',
    'PAGEIOLATCH_EX',
    'PAGEIOLATCH_UP',
    'WRITELOG',
    'WRITE_COMPLETION',
    'ASYNC_IO_COMPLETION',
    'IO_COMPLETION',
    'HADR_SYNC_COMMIT'
)
ORDER BY wait_time_ms DESC;
