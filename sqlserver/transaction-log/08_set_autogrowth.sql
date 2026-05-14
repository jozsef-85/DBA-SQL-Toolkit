/*
    Script: 08_set_autogrowth.sql
    Proposito:
        Plantilla para normalizar FILEGROWTH del transaction log en MB fijos.

    Cuando usar:
        Despues de diagnosticar crecimiento historico irregular,
        demasiados VLF o configuracion en porcentaje.

    Como usar:
        1. Revisar VLF con sqlserver/transaction-log/04_vlf_analysis.sql.
        2. Reemplazar NOMBRE_DB y NOMBRE_LOGICO_LOG.
        3. Ajustar FILEGROWTH segun carga, tamano y ventana operacional.
        4. Validar con sqlserver/capacity/04_validate_filegrowth.sql.

    Precauciones:
        Ajustar el valor segun tamano, carga y ventana operacional.
*/

ALTER DATABASE [NOMBRE_DB]
MODIFY FILE (
    NAME = N'NOMBRE_LOGICO_LOG',
    FILEGROWTH = 1024MB
);
GO
