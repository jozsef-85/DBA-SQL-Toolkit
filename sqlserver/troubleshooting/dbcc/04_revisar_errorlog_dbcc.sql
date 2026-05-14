/*
================================================================================
Script : 04_revisar_errorlog_dbcc.sql
Objetivo: Buscar eventos DBCC/CHECKDB/CHECKTABLE en el errorlog actual.
Uso     : Ejecutar para obtener evidencia antes y despues de cancelar un DBCC.
Riesgo  : Solo lectura.
================================================================================
*/

SET NOCOUNT ON;

EXEC xp_readerrorlog 0, 1, N'DBCC';
EXEC xp_readerrorlog 0, 1, N'CHECKDB';
EXEC xp_readerrorlog 0, 1, N'CHECKTABLE';
EXEC xp_readerrorlog 0, 1, N'MSSQL_DBCC';
