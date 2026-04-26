/*
    Script: 03_file_space_used_gb.sql
    Descripción:
        Muestra tamaño actual, espacio usado real y espacio libre interno
        de los archivos de la base actual.

    Uso:
        Cambiar el contexto con USE [NombreBase].
        Ejecutar dentro de la base que se desea analizar.

    Escenario:
        Usado para confirmar si un archivo MDF/NDF/LDF estaba realmente lleno
        o si solo estaba sobredimensionado.
*/

USE [NombreBase];
GO

SELECT
    DB_NAME() AS database_name,
    name AS logical_name,
    physical_name,
    type_desc,
    CAST(size / 128.0 / 1024 AS DECIMAL(18,2)) AS size_gb,
    CAST(FILEPROPERTY(name, 'SpaceUsed') / 128.0 / 1024 AS DECIMAL(18,2)) AS used_gb,
    CAST((size - FILEPROPERTY(name, 'SpaceUsed')) / 128.0 / 1024 AS DECIMAL(18,2)) AS free_inside_file_gb
FROM sys.database_files
ORDER BY size_gb DESC;