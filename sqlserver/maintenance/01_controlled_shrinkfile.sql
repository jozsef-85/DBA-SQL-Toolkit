/*
    Script: 01_controlled_shrinkfile.sql
    Proposito:
        Plantilla para ejecutar DBCC SHRINKFILE de forma controlada,
        por archivo logico y por etapas.

    Cuando usar:
        Solo cuando se confirme espacio libre interno significativo y exista
        una razon operacional para reducir el archivo.

    Como usar:
        1. Confirmar primero espacio usado real con sqlserver/capacity/02_file_space_used_gb.sql.
        2. Confirmar espacio libre del volumen con sqlserver/capacity/03_volume_free_space.sql.
        3. Confirmar que la base este ONLINE.
        4. En Always On AG, validar PRIMARY con sqlserver/alwayson/01_ag_database_state.sql.
        5. Reemplazar [NombreBase], @logical_file_name y @target_size_mb.
        6. Ejecutar por etapas, no de forma agresiva.
        7. Validar despues de cada ejecucion.

    Precauciones:
        No usar DBCC SHRINKDATABASE.
        No usar shrink como mantenimiento rutinario.
        El shrink puede generar fragmentacion y consumo intenso de I/O.
*/

USE [NombreBase];
GO

DECLARE @logical_file_name sysname = N'NombreLogicoArchivo';
DECLARE @target_size_mb INT = 150000;

-- 1. Validar archivos antes del shrink
SELECT
    DB_NAME() AS database_name,
    name AS logical_name,
    physical_name,
    type_desc,
    CAST(size / 128.0 AS DECIMAL(18,2)) AS size_mb,
    CAST(FILEPROPERTY(name, 'SpaceUsed') / 128.0 AS DECIMAL(18,2)) AS used_mb,
    CAST((size - FILEPROPERTY(name, 'SpaceUsed')) / 128.0 AS DECIMAL(18,2)) AS free_inside_file_mb
FROM sys.database_files
ORDER BY size_mb DESC;

-- 2. Ejecutar shrink por archivo logico.
-- Reemplazar @logical_file_name y @target_size_mb antes de ejecutar.
-- Ejemplo: @logical_file_name = N'Archivo_Data_01', @target_size_mb = 150000.

DBCC SHRINKFILE (@logical_file_name, @target_size_mb);

-- 3. Validar resultado después del shrink
SELECT
    DB_NAME() AS database_name,
    name AS logical_name,
    physical_name,
    type_desc,
    CAST(size / 128.0 AS DECIMAL(18,2)) AS size_mb,
    CAST(FILEPROPERTY(name, 'SpaceUsed') / 128.0 AS DECIMAL(18,2)) AS used_mb,
    CAST((size - FILEPROPERTY(name, 'SpaceUsed')) / 128.0 AS DECIMAL(18,2)) AS free_inside_file_mb
FROM sys.database_files
ORDER BY size_mb DESC;
