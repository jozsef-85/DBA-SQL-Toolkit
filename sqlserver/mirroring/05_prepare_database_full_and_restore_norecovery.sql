/*
================================================================================
 Script: 05_prepare_database_full_and_restore_norecovery.sql
 Categoria: SQL Server Database Mirroring / Workgroup / Certificados
 Objetivo:
   Preparar la base principal y restaurar la base espejo para Database Mirroring.

 Regla clave:
   Database Mirroring requiere recovery model FULL.
   La base mirror debe quedar en RESTORING mediante RESTORE ... WITH NORECOVERY.

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

/* 1. Cambiar a FULL si la base esta en SIMPLE.
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
    EXEC(N'ALTER DATABASE ' + QUOTENAME(@DatabaseName) + N' SET RECOVERY FULL;');
END

SELECT
    name,
    state_desc,
    recovery_model_desc
FROM sys.databases
WHERE name = @DatabaseName;
GO

/* 2. Tomar backup FULL nuevo despues de cambiar a FULL */
BACKUP DATABASE [AdventureWorks2022]
TO DISK = 'C:\Temp\AdventureWorks2022_Mirror_FULL.bak'
WITH INIT, CHECKSUM, COMPRESSION, STATS = 10;
GO

/* 3. Opcional: tomar backup de LOG.
   Para laboratorios con AdventureWorks y sin actividad puede no ser necesario si el
   FULL se tomo inmediatamente despues de cambiar a FULL. En ambientes reales se
   recomienda tomar y restaurar al menos un backup de log posterior al full.
*/
BACKUP LOG [AdventureWorks2022]
TO DISK = 'C:\Temp\AdventureWorks2022_Mirror_LOG.trn'
WITH INIT, CHECKSUM, COMPRESSION, STATS = 10;
GO

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
*/
