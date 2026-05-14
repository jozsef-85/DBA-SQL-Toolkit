/*
================================================================================
Script : 03_validar_snapshots_y_archivos_dbcc.sql
Objetivo: Revisar snapshots visibles y archivos *_MSSQL_DBCC* registrados en la
          metadata de SQL Server.
Uso     : Ejecutar antes de intervenir archivos fisicos en Windows.
Riesgo  : Solo lectura.
================================================================================
*/

SET NOCOUNT ON;

PRINT '1) Snapshots visibles en sys.databases';

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

PRINT '2) Archivos DBCC registrados en sys.master_files';

SELECT
    DB_NAME(database_id) AS database_name,
    name AS logical_name,
    type_desc,
    physical_name,
    size * 8.0 / 1024 AS size_mb
FROM sys.master_files
WHERE physical_name LIKE '%MSSQL_DBCC%'
ORDER BY database_name, physical_name;
