/*
================================================================================
 Script: 06_set_partner_validate_and_manual_failover.sql
 Categoria: SQL Server Database Mirroring / Workgroup / Certificados
 Objetivo:
   Configurar SET PARTNER, validar sincronizacion y probar failover manual.

 Caso documentado:
   Nodo 1 / Principal inicial: 10.10.8.5 / Win2016-Web\SERVNODO01
   Nodo 2 / Mirror inicial:    10.10.8.6 / Win2016Negocio\SERVNODO2
   Base:                       AdventureWorks2022
   Puerto endpoint:            5022

 Orden obligatorio:
   1. Ejecutar SET PARTNER en el mirror apuntando al principal.
   2. Ejecutar SET PARTNER en el principal apuntando al mirror.
================================================================================
*/

/*===============================================================================
 BLOQUE A - Ejecutar en NODO 2 / MIRROR
 La base debe estar en RESTORING y FULL.
===============================================================================*/

/*
USE master;
GO

ALTER DATABASE [AdventureWorks2022]
SET PARTNER = 'TCP://10.10.8.5:5022';
GO
*/

/*===============================================================================
 BLOQUE B - Ejecutar en NODO 1 / PRINCIPAL
 La base debe estar ONLINE y FULL.
===============================================================================*/

/*
USE master;
GO

ALTER DATABASE [AdventureWorks2022]
SET PARTNER = 'TCP://10.10.8.6:5022';
GO
*/

/*===============================================================================
 BLOQUE C - Validar en ambos nodos
===============================================================================*/

USE master;
GO

SELECT
    DB_NAME(database_id) AS database_name,
    mirroring_guid,
    mirroring_state_desc,
    mirroring_role_desc,
    mirroring_safety_level_desc,
    mirroring_partner_name,
    mirroring_partner_instance,
    mirroring_witness_name
FROM sys.database_mirroring
WHERE database_id = DB_ID('AdventureWorks2022');
GO

/* Resultado esperado:
   Nodo 1: SYNCHRONIZED | PRINCIPAL | FULL | TCP://10.10.8.6:5022
   Nodo 2: SYNCHRONIZED | MIRROR    | FULL | TCP://10.10.8.5:5022
*/

/*===============================================================================
 BLOQUE D - Confirmar modo seguro sin witness
===============================================================================*/

/* Ejecutar en el principal actual */
/*
USE master;
GO

ALTER DATABASE [AdventureWorks2022]
SET SAFETY FULL;
GO
*/

/*===============================================================================
 BLOQUE E - Failover manual controlado
 Requisitos:
   - mirroring_state_desc = SYNCHRONIZED
   - mirroring_safety_level_desc = FULL
   - Ejecutar desde el PRINCIPAL actual.
===============================================================================*/

/*
USE master;
GO

ALTER DATABASE [AdventureWorks2022]
SET PARTNER FAILOVER;
GO
*/

/* Validar nuevamente en ambos nodos despues del failover */
SELECT
    DB_NAME(database_id) AS database_name,
    mirroring_state_desc,
    mirroring_role_desc,
    mirroring_safety_level_desc,
    mirroring_partner_name,
    mirroring_partner_instance
FROM sys.database_mirroring
WHERE database_id = DB_ID('AdventureWorks2022');
GO
