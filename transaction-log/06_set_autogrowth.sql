/*
    Script: 06_set_autogrowth.sql
    Uso:
        Plantilla para normalizar FILEGROWTH del transaction log en MB fijos.
        Reemplazar NOMBRE_DB y NOMBRE_LOGICO_LOG antes de ejecutar.

    Nota:
        Ajustar el valor segun tamano, carga y ventana operacional.
*/

ALTER DATABASE [NOMBRE_DB]
MODIFY FILE (
    NAME = N'NOMBRE_LOGICO_LOG',
    FILEGROWTH = 1024MB
);
GO
