/*
    Script: 05_validate_filegrowth.sql
    Descripción:
        Valida la configuración actual de FILEGROWTH para los archivos de la base actual.

    Uso:
        Ejecutar dentro de la base que se desea revisar.
        Confirmar que is_percent_growth = 0 para evitar crecimiento porcentual.

    Escenario:
        Usado después de normalizar archivos para confirmar crecimiento fijo en MB.
*/

USE [NombreBase];
GO

SELECT
    name AS logical_name,
    physical_name,
    type_desc,
    is_percent_growth,
    growth,
    CASE
        WHEN is_percent_growth = 1
            THEN CAST(growth AS VARCHAR(20)) + ' %'
        ELSE CAST(growth / 128.0 AS VARCHAR(20)) + ' MB'
    END AS growth_setting
FROM sys.database_files
ORDER BY file_id;