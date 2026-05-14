/*
    Script: 04_io_file_interval.sql
    Uso:
        Cuarto paso cuando los waits o sesiones apuntan a I/O.
        Mide actividad de I/O por archivo en un intervalo corto.
        Ajustar @sample_seconds segun la ventana que se quiera observar.
        Ejecutar durante el incidente para ver deltas de lecturas, escrituras
        y latencia promedio del intervalo.
*/

DECLARE @sample_seconds INT = 60;
DECLARE @delay CHAR(8) = CONVERT(CHAR(8), DATEADD(SECOND, @sample_seconds, 0), 108);

IF OBJECT_ID('tempdb..#io_start') IS NOT NULL 
    DROP TABLE #io_start;

SELECT 
    GETDATE() AS capture_time,
    vfs.database_id,
    vfs.file_id,
    DB_NAME(vfs.database_id) AS database_name,
    mf.name AS logical_name,
    mf.type_desc,
    mf.physical_name,
    LEFT(mf.physical_name, 2) AS drive,
    vfs.num_of_reads,
    vfs.io_stall_read_ms,
    vfs.num_of_writes,
    vfs.io_stall_write_ms,
    vfs.num_of_bytes_read,
    vfs.num_of_bytes_written
INTO #io_start
FROM sys.dm_io_virtual_file_stats(NULL, NULL) vfs
JOIN sys.master_files mf
    ON vfs.database_id = mf.database_id
   AND vfs.file_id = mf.file_id;

WAITFOR DELAY @delay;

SELECT 
    DB_NAME(vfs.database_id) AS database_name,
    mf.name AS logical_name,
    mf.type_desc,
    LEFT(mf.physical_name, 2) AS drive,
    mf.physical_name,

    vfs.num_of_reads - s.num_of_reads AS reads_delta,
    CAST((vfs.num_of_bytes_read - s.num_of_bytes_read) / 1024.0 / 1024.0 AS decimal(18,2)) AS read_mb_delta,
    CASE 
        WHEN vfs.num_of_reads - s.num_of_reads = 0 THEN 0
        ELSE CAST((vfs.io_stall_read_ms - s.io_stall_read_ms) * 1.0 
             / NULLIF(vfs.num_of_reads - s.num_of_reads, 0) AS decimal(18,2))
    END AS avg_read_ms_interval,

    vfs.num_of_writes - s.num_of_writes AS writes_delta,
    CAST((vfs.num_of_bytes_written - s.num_of_bytes_written) / 1024.0 / 1024.0 AS decimal(18,2)) AS write_mb_delta,
    CASE 
        WHEN vfs.num_of_writes - s.num_of_writes = 0 THEN 0
        ELSE CAST((vfs.io_stall_write_ms - s.io_stall_write_ms) * 1.0 
             / NULLIF(vfs.num_of_writes - s.num_of_writes, 0) AS decimal(18,2))
    END AS avg_write_ms_interval,

    DATEDIFF(SECOND, s.capture_time, GETDATE()) AS sample_seconds
FROM sys.dm_io_virtual_file_stats(NULL, NULL) vfs
JOIN sys.master_files mf
    ON vfs.database_id = mf.database_id
   AND vfs.file_id = mf.file_id
JOIN #io_start s
    ON vfs.database_id = s.database_id
   AND vfs.file_id = s.file_id
ORDER BY 
    avg_write_ms_interval DESC,
    avg_read_ms_interval DESC;
