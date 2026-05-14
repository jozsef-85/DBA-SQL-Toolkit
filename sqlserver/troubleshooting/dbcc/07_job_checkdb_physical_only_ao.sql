/*
================================================================================
Script : 07_job_checkdb_physical_only_ao.sql
Objetivo: Plantilla segura para ejecutar DBCC CHECKDB PHYSICAL_ONLY con MAXDOP
          controlado y validacion de rol PRIMARY en Always On.
Uso     : Reemplazar @database_name y ajustar @maxdop segun ventana/capacidad.
Riesgo  : Operativo. Consume I/O y CPU.
================================================================================
*/

SET NOCOUNT ON;

DECLARE @database_name SYSNAME = N'<BASE_DATOS>';
DECLARE @maxdop INT = 4;
DECLARE @sql NVARCHAR(MAX);

IF DB_ID(@database_name) IS NULL
BEGIN
    RAISERROR('La base indicada no existe en esta instancia.', 16, 1);
    RETURN;
END;

IF SERVERPROPERTY('IsHadrEnabled') = 1
BEGIN
    IF sys.fn_hadr_is_primary_replica(@database_name) <> 1
    BEGIN
        RAISERROR('Esta replica no es PRIMARY para la base indicada. No se ejecuta DBCC.', 10, 1);
        RETURN;
    END;
END;

SET @sql = N'DBCC CHECKDB(' + QUOTENAME(@database_name,'''') + N') WITH PHYSICAL_ONLY, NO_INFOMSGS, MAXDOP = ' + CONVERT(NVARCHAR(10), @maxdop) + N';';

PRINT @sql;
EXEC sys.sp_executesql @sql;
