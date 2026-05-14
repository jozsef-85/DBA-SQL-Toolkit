/*
    Script: 04_validate_filegrowth.sql
    Proposito:
        Valida la configuración actual de FILEGROWTH para los archivos de la base actual.

    Cuando usar:
        Cuarto paso en revisiones de capacidad.
        Usar antes o despues de normalizar crecimiento de archivos.

    Como usar:
        Reemplazar [NombreBase] y ejecutar dentro de la base a revisar.

    Que revisar:
        Confirmar que is_percent_growth = 0 y que growth_setting este en MB.
        Evitar crecimiento porcentual salvo que exista una razon operacional clara.
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
