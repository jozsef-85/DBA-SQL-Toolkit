/*
    Script: 02_file_space_used_gb.sql
    Proposito:
        Muestra tamaño actual, espacio usado real y espacio libre interno
        de los archivos de la base actual.

    Cuando usar:
        Segundo paso en analisis de capacidad.
        Permite confirmar si un MDF/NDF/LDF esta realmente usado
        o si el archivo esta sobredimensionado.

    Como usar:
        Reemplazar [NombreBase] y ejecutar dentro de la base a revisar.

    Siguiente paso:
        Revisar espacio disponible en volumen con
        sqlserver/capacity/03_volume_free_space.sql.
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
