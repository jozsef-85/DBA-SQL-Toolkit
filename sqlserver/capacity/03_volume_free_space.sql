/*
    Script: 03_volume_free_space.sql
    Proposito:
        Muestra espacio total y libre por volumen donde existen archivos SQL Server.

    Cuando usar:
        Tercer paso en revisiones de capacidad.
        Sirve para validar riesgo de llenado de discos antes de crecer,
        mover, respaldar o reducir archivos.

    Como usar:
        Ejecutar a nivel de instancia. Requiere permisos para consultar
        sys.dm_os_volume_stats.

    Referencia:
        sys.dm_os_volume_stats devuelve información del volumen del sistema operativo
        donde están almacenados los archivos de base de datos, incluyendo espacio disponible.
*/

SELECT DISTINCT
    vs.volume_mount_point,
    vs.logical_volume_name,
    CAST(vs.total_bytes / 1024.0 / 1024 / 1024 AS DECIMAL(18,2)) AS total_gb,
    CAST(vs.available_bytes / 1024.0 / 1024 / 1024 AS DECIMAL(18,2)) AS free_gb,
    CAST((vs.available_bytes * 100.0) / NULLIF(vs.total_bytes, 0) AS DECIMAL(18,2)) AS free_pct
FROM sys.master_files mf
CROSS APPLY sys.dm_os_volume_stats(mf.database_id, mf.file_id) vs
ORDER BY vs.volume_mount_point;
