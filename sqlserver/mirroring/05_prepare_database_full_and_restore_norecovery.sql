/*
================================================================================
 Script: 05_prepare_database_full_and_restore_norecovery.sql
 Categoria: SQL Server Database Mirroring / Workgroup / Certificados
 Objetivo:
   Preparar la base principal y restaurar la base espejo para Database Mirroring.

 Regla clave:
   Database Mirroring requiere recovery model FULL.
   La base mirror debe quedar en RESTORING mediante RESTORE ... WITH NORECOVERY.

 Ajuste importante por caso real:
   Para evitar Msg 1478, no mezclar backups de intentos anteriores.
   El LOG restaurado en el mirror debe pertenecer a la misma cadena del FULL usado
   y debe ser posterior al FULL generado para esta configuracion.

 Caso documentado:
   Base: AdventureWorks2022
   Nodo 1: Principal inicial
   Nodo 2: Mirror inicial
================================================================================
*/

/*===============================================================================
 BLOQUE A - Ejecutar en NODO 1 / PRINCIPAL
===============================================================================*/

USE master;
GO

DECLARE @DatabaseName sysname = N'AdventureWorks2022';
DECLARE @BackupFolder nvarchar(260) = N'C:\Temp\';
DECLARE @FullBackupFile nvarchar(4000) = @BackupFolder + @DatabaseName + N'_Mirror_FULL.bak';
DECLARE @LogBackupFile  nvarchar(4000) = @BackupFolder + @DatabaseName + N'_Mirror_LOG.trn';
DECLARE @sql nvarchar(max);

/* 1. Validar que la base exista y este ONLINE en el principal */
IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = @DatabaseName)
BEGIN
    THROW 50001, 'La base indicada no existe en este nodo.', 1;
END;

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = @DatabaseName AND state_desc <> 'ONLINE')
BEGIN
    THROW 50002, 'La base principal debe estar ONLINE antes de generar backups para mirroring.', 1;
END;

/* 2. Cambiar a FULL si la base esta en SIMPLE.
   Esto se hace en el principal. No se cambia el recovery model desde la base mirror
   mientras esta en RESTORING.
*/
IF EXISTS (
    SELECT 1
    FROM sys.databases
    WHERE name = @DatabaseName
      AND recovery_model_desc <> 'FULL'
)
BEGIN
    SET @sql = N'ALTER DATABASE ' + QUOTENAME(@DatabaseName) + N' SET RECOVERY FULL;';
    EXEC sys.sp_executesql @sql;
END;

SELECT
    name,
    state_desc,
    recovery_model_desc
FROM sys.databases
WHERE name = @DatabaseName;
GO

/*
================================================================================
 3. Limpieza recomendada de archivos antiguos
    Ejecutar en PowerShell del Nodo 1 antes de generar los nuevos backups:

    Remove-Item C:\Temp\AdventureWorks2022_Mirror_FULL.bak -ErrorAction SilentlyContinue
    Remove-Item C:\Temp\AdventureWorks2022_Mirror_LOG.trn  -ErrorAction SilentlyContinue

    Motivo:
      Evita usar accidentalmente archivos .bak/.trn de intentos anteriores.
================================================================================
*/

/* 4. Tomar backup FULL nuevo */
BACKUP DATABASE [AdventureWorks2022]
TO DISK = 'C:\Temp\AdventureWorks2022_Mirror_FULL.bak'
WITH INIT, CHECKSUM, COMPRESSION, STATS = 10;
GO

/* 5. Tomar backup LOG inmediatamente posterior al FULL.
   Este paso NO es opcional para este runbook.
   Motivo:
     Evita Msg 1478 al ejecutar SET PARTNER, especialmente si la base tuvo actividad
     despues del FULL o si se reconstruyo el mirror desde cero.
*/
BACKUP LOG [AdventureWorks2022]
TO DISK = 'C:\Temp\AdventureWorks2022_Mirror_LOG.trn'
WITH INIT, CHECKSUM, COMPRESSION, STATS = 10;
GO

/* 6. Validar los archivos de backup antes de copiarlos al mirror */
RESTORE HEADERONLY
FROM DISK = 'C:\Temp\AdventureWorks2022_Mirror_FULL.bak';
GO

RESTORE HEADERONLY
FROM DISK = 'C:\Temp\AdventureWorks2022_Mirror_LOG.trn';
GO

/*
================================================================================
 Copiar al Nodo 2 exactamente estos dos archivos recien generados:
   C:\Temp\AdventureWorks2022_Mirror_FULL.bak
   C:\Temp\AdventureWorks2022_Mirror_LOG.trn

 No usar archivos .bak/.trn de practicas anteriores.
================================================================================
*/

/*===============================================================================
 BLOQUE B - Ejecutar en NODO 2 / MIRROR
 Copiar previamente al Nodo 2:
   C:\Temp\AdventureWorks2022_Mirror_FULL.bak
   C:\Temp\AdventureWorks2022_Mirror_LOG.trn
===============================================================================*/

/*
USE master;
GO

-- Si existe una preparacion previa incorrecta, eliminar la base mirror.
-- Validar que se esta en el nodo correcto antes de ejecutar DROP DATABASE.
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'AdventureWorks2022')
BEGIN
    DROP DATABASE [AdventureWorks2022];
END
GO

-- Validar headers de los archivos copiados al Nodo 2.
-- Ambos deben corresponder a la misma base y a la misma cadena de backups.
RESTORE HEADERONLY
FROM DISK = 'C:\Temp\AdventureWorks2022_Mirror_FULL.bak';
GO

RESTORE HEADERONLY
FROM DISK = 'C:\Temp\AdventureWorks2022_Mirror_LOG.trn';
GO

RESTORE DATABASE [AdventureWorks2022]
FROM DISK = 'C:\Temp\AdventureWorks2022_Mirror_FULL.bak'
WITH NORECOVERY, REPLACE, STATS = 10;
GO

RESTORE LOG [AdventureWorks2022]
FROM DISK = 'C:\Temp\AdventureWorks2022_Mirror_LOG.trn'
WITH NORECOVERY, STATS = 10;
GO

SELECT
    name,
    state_desc,
    recovery_model_desc
FROM sys.databases
WHERE name = 'AdventureWorks2022';
GO
*/

/* Resultado esperado en Nodo 2:
   AdventureWorks2022 | RESTORING | FULL

 Si al ejecutar SET PARTNER aparece Msg 1478:
   - El mirror no tiene suficiente log restaurado.
   - Se mezclo un FULL nuevo con un LOG viejo, o falta restaurar un LOG posterior.
   - Repetir este script desde el backup FULL nuevo y LOG nuevo, sin reutilizar archivos.
*/
