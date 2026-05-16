/*
================================================================================
 Script: 07_troubleshooting_error_1418_and_handshake.sql
 Categoria: SQL Server Database Mirroring / Workgroup / Certificados
 Objetivo:
   Diagnosticar error 1418 y fallas de handshake en Database Mirroring con
   certificados.

 Sintomas frecuentes:
   - Msg 1418: The server network address ... can not be reached or does not exist.
   - Database Mirroring login attempt failed with error...
   - Database mirroring connection error '4'.
   - The database is already enabled for database mirroring.

 Lectura operacional:
   Si Test-NetConnection al puerto 5022 es True, la red basica esta bien.
   El problema suele estar en certificados, logins, permisos CONNECT, endpoint
   incorrecto o configuracion parcial de SET PARTNER.
================================================================================
*/

USE master;
GO

DECLARE @DatabaseName sysname = N'AdventureWorks2022';

PRINT '1. Estado de la base y mirroring';
SELECT
    d.name,
    d.state_desc,
    d.recovery_model_desc,
    dm.mirroring_guid,
    dm.mirroring_state_desc,
    dm.mirroring_role_desc,
    dm.mirroring_safety_level_desc,
    dm.mirroring_partner_name,
    dm.mirroring_partner_instance,
    dm.mirroring_witness_name
FROM sys.databases d
LEFT JOIN sys.database_mirroring dm
    ON d.database_id = dm.database_id
WHERE d.name = @DatabaseName;

PRINT '2. Endpoint DATABASE_MIRRORING';
SELECT
    e.name AS endpoint_name,
    e.state_desc,
    dme.role_desc,
    dme.connection_auth_desc,
    dme.encryption_algorithm_desc,
    te.port,
    te.ip_address
FROM sys.endpoints e
JOIN sys.database_mirroring_endpoints dme
    ON e.endpoint_id = dme.endpoint_id
JOIN sys.tcp_endpoints te
    ON e.endpoint_id = te.endpoint_id;

PRINT '3. Permisos CONNECT sobre endpoint';
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

PRINT '4. Relacion login - user - certificate';
SELECT
    sp.name AS login_name,
    dp.name AS user_name,
    c.name AS certificate_name,
    c.subject,
    c.start_date,
    c.expiry_date
FROM sys.server_principals sp
LEFT JOIN sys.database_principals dp
    ON dp.sid = sp.sid
LEFT JOIN sys.certificates c
    ON c.principal_id = dp.principal_id
WHERE sp.name LIKE 'Login_Mirroring_%'
ORDER BY sp.name;

PRINT '5. Error log - mirroring';
EXEC xp_readerrorlog 0, 1, N'mirroring';

PRINT '6. Error log - Database Mirroring login attempt failed';
EXEC xp_readerrorlog 0, 1, N'Database Mirroring login attempt failed';

PRINT '7. Error log - certificate';
EXEC xp_readerrorlog 0, 1, N'certificate';

PRINT '8. Error log - endpoint';
EXEC xp_readerrorlog 0, 1, N'endpoint';
GO

/*
================================================================================
 Comandos PowerShell utiles fuera de SQL Server
================================================================================

Desde Nodo 1 hacia Nodo 2:
  Test-NetConnection 10.10.8.6 -Port 5022

Desde Nodo 2 hacia Nodo 1:
  Test-NetConnection 10.10.8.5 -Port 5022

En cada nodo, validar escucha local:
  netstat -ano | findstr :5022

================================================================================
 Reinicio controlado de endpoint
================================================================================

-- Nodo 1, si el endpoint se llama Mirroring:
-- ALTER ENDPOINT [Mirroring] STATE = STOPPED;
-- ALTER ENDPOINT [Mirroring] STATE = STARTED;

-- Nodo 2, si el endpoint se llama Endpoint_Mirroring:
-- ALTER ENDPOINT [Endpoint_Mirroring] STATE = STOPPED;
-- ALTER ENDPOINT [Endpoint_Mirroring] STATE = STARTED;

================================================================================
 Limpieza de configuracion parcial
================================================================================

-- Ejecutar con cuidado, preferentemente en el mirror si quedo parcialmente habilitado.
-- Puede requerir restaurar nuevamente la base con NORECOVERY.
-- ALTER DATABASE [AdventureWorks2022] SET PARTNER OFF;

================================================================================
*/
