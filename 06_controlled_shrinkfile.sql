/*
    Script: 06_controlled_shrinkfile.sql
    Descripción:
        Plantilla para ejecutar DBCC SHRINKFILE de forma controlada,
        por archivo lógico y por etapas.

    Uso:
        1. Confirmar primero espacio usado real con 03_file_space_used_gb.sql.
        2. Confirmar que la base esté ONLINE.
        3. En Always On AG, ejecutar solo sobre la réplica PRIMARY.
        4. Definir target en MB.
        5. Ejecutar por etapas, no de forma agresiva.
        6. Validar después de cada ejecución.

    Importante:
        No usar DBCC SHRINKDATABASE.
        No usar shrink como mantenimiento rutinario.
*/

USE [NombreBase];
GO

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

-- 2. Ejecutar shrink por archivo lógico.
-- Reemplazar NombreLogicoArchivo y TargetMB.
-- Ejemplo: DBCC SHRINKFILE (N'Archivo_Data_01', 150000);

DBCC SHRINKFILE (N'NombreLogicoArchivo', TargetMB);

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