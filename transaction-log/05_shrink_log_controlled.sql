-- Shrink controlado (solo si aplica)

USE [NOMBRE_DB];
GO

DBCC SHRINKFILE (N'NOMBRE_LOGICO_LOG', 20480); -- tamaño en MB
GO