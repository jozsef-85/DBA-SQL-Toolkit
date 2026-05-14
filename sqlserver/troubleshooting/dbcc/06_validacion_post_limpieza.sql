/*
================================================================================
Script : 06_validacion_post_limpieza.sql
Objetivo: Validar que el SPID DBCC ya desaparecio y que SQL Server no mantiene
          metadata asociada a archivos internos DBCC.
Uso     : Ejecutar despues de que el SPID ya no aparezca en rollback.
Riesgo  : Solo lectura.
================================================================================
*/

SET NOCOUNT ON;

DECLARE @session_id INT = NULL; -- Ejemplo: 177. Opcional.

PRINT '1) Validar si el SPID aun existe';

SELECT
    GETDATE() AS fecha_revision,
    r.session_id,
    r.status,
    r.command,
    DB_NAME(r.database_id) AS database_name,
    r.percent_complete,
    r.wait_type,
    r.blocking_session_id
FROM sys.dm_exec_requests AS r
WHERE @session_id IS NOT NULL
  AND r.session_id = @session_id;

PRINT '2) Validar archivos DBCC registrados por SQL Server';

SELECT
    DB_NAME(database_id) AS database_name,
    name AS logical_name,
    type_desc,
    physical_name,
    size * 8.0 / 1024 AS size_mb
FROM sys.master_files
WHERE physical_name LIKE '%MSSQL_DBCC%'
ORDER BY database_name, physical_name;

PRINT '3) Validar snapshots visibles';

SELECT
    name,
    database_id,
    source_database_id,
    DB_NAME(source_database_id) AS source_database_name,
    create_date,
    state_desc
FROM sys.databases
WHERE source_database_id IS NOT NULL
ORDER BY create_date DESC;
