/*
================================================================================
 Script: 01_prechecks_mirroring_workgroup.sql
 Categoria: SQL Server Database Mirroring / Workgroup / Certificados
 Objetivo:
   Validar prerequisitos antes de configurar Database Mirroring entre dos nodos
   que no pertenecen a dominio.

 Uso:
   Ejecutar en ambos nodos.
   Ajustar @DatabaseName y @ExpectedEndpointPort.

 Notas:
   - En workgroup no usar autenticacion Windows para el endpoint de mirroring.
   - El endpoint debe usar AUTHENTICATION = CERTIFICATE.
   - La base principal debe estar ONLINE y en FULL.
   - La base mirror debe estar RESTORING y en FULL.
================================================================================
*/

USE master;
GO

DECLARE @DatabaseName sysname = N'AdventureWorks2022';
DECLARE @ExpectedEndpointPort int = 5022;

PRINT '1. Identidad de instancia';
SELECT
    @@SERVERNAME AS server_name,
    SERVERPROPERTY('MachineName') AS machine_name,
    SERVERPROPERTY('InstanceName') AS instance_name,
    SERVERPROPERTY('Edition') AS edition,
    SERVERPROPERTY('ProductVersion') AS product_version,
    SERVERPROPERTY('ProductLevel') AS product_level;

PRINT '2. Estado de la base';
SELECT
    name,
    state_desc,
    recovery_model_desc,
    user_access_desc,
    is_read_only
FROM sys.databases
WHERE name = @DatabaseName;

PRINT '3. Endpoint DATABASE_MIRRORING';
SELECT
    e.name AS endpoint_name,
    e.type_desc,
    e.state_desc,
    dme.role_desc,
    dme.connection_auth_desc,
    dme.encryption_algorithm_desc,
    te.port,
    te.ip_address
FROM sys.endpoints e
INNER JOIN sys.database_mirroring_endpoints dme
    ON e.endpoint_id = dme.endpoint_id
INNER JOIN sys.tcp_endpoints te
    ON e.endpoint_id = te.endpoint_id;

PRINT '4. Validacion rapida del puerto esperado';
SELECT
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM sys.endpoints e
            INNER JOIN sys.database_mirroring_endpoints dme
                ON e.endpoint_id = dme.endpoint_id
            INNER JOIN sys.tcp_endpoints te
                ON e.endpoint_id = te.endpoint_id
            WHERE te.port = @ExpectedEndpointPort
              AND e.state_desc = 'STARTED'
        ) THEN 'OK - Endpoint iniciado en puerto esperado'
        ELSE 'REVISAR - No hay endpoint STARTED en el puerto esperado'
    END AS endpoint_port_check;

PRINT '5. Master Key en master';
SELECT
    name,
    symmetric_key_id,
    key_length,
    algorithm_desc
FROM sys.symmetric_keys
WHERE name = '##MS_DatabaseMasterKey##';

PRINT '6. Certificados en master';
SELECT
    name,
    subject,
    start_date,
    expiry_date,
    pvt_key_encryption_type_desc,
    issuer_name
FROM sys.certificates
WHERE name NOT LIKE '##%'
ORDER BY name;

PRINT '7. Permisos CONNECT sobre endpoints de mirroring';
SELECT
    pr.name AS principal_name,
    pe.permission_name,
    pe.state_desc,
    ep.name AS endpoint_name
FROM sys.server_permissions pe
INNER JOIN sys.server_principals pr
    ON pe.grantee_principal_id = pr.principal_id
INNER JOIN sys.endpoints ep
    ON pe.major_id = ep.endpoint_id
WHERE ep.type_desc = 'DATABASE_MIRRORING'
ORDER BY ep.name, pr.name;

PRINT '8. Estado actual de mirroring para la base';
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
WHERE database_id = DB_ID(@DatabaseName);
GO
