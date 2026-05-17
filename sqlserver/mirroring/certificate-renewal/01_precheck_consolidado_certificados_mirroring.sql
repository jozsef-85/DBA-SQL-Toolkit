/*
SCRIPT 01 - PRECHECK CONSOLIDADO CERTIFICADOS MIRRORING

Objetivo:
  Validar certificados, endpoint, permisos y estado de Database Mirroring
  antes de una renovacion de certificados.

Compatibilidad:
  SQL Server 2008 R2 o superior.

Notas:
  - No realiza cambios.
  - Ejecutar conectado a cada instancia involucrada.
  - Guardar resultados como evidencia previa.
*/

USE master;
GO

SET NOCOUNT ON;
GO

PRINT '============================================================';
PRINT '1. Certificado usado por endpoint';
PRINT '============================================================';

SELECT
    @@SERVERNAME AS instancia,
    e.name AS endpoint_name,
    e.endpoint_id,
    e.state_desc,
    e.type_desc,
    dme.role_desc,
    dme.connection_auth_desc,
    dme.encryption_algorithm_desc,
    dme.is_encryption_enabled,
    te.port AS listener_port,
    te.ip_address,
    dme.certificate_id,
    c.name AS certificado_usado_por_endpoint,
    c.subject,
    c.start_date,
    c.expiry_date,
    DATEDIFF(DAY, GETDATE(), c.expiry_date) AS dias_para_expirar,
    c.pvt_key_encryption_type_desc
FROM sys.endpoints AS e
INNER JOIN sys.database_mirroring_endpoints AS dme
    ON e.endpoint_id = dme.endpoint_id
LEFT JOIN sys.tcp_endpoints AS te
    ON e.endpoint_id = te.endpoint_id
LEFT JOIN sys.certificates AS c
    ON dme.certificate_id = c.certificate_id
WHERE e.type_desc = 'DATABASE_MIRRORING'
ORDER BY e.name;
GO

PRINT '============================================================';
PRINT '2. Certificados de master';
PRINT '============================================================';

SELECT
    @@SERVERNAME AS instancia,
    c.name AS certificado,
    c.subject,
    c.start_date,
    c.expiry_date,
    DATEDIFF(DAY, GETDATE(), c.expiry_date) AS dias_para_expirar,
    CASE
        WHEN c.expiry_date < GETDATE() THEN 'VENCIDO'
        WHEN DATEDIFF(DAY, GETDATE(), c.expiry_date) <= 30 THEN 'CRITICO'
        WHEN DATEDIFF(DAY, GETDATE(), c.expiry_date) <= 90 THEN 'ADVERTENCIA'
        ELSE 'OK'
    END AS estado_vigencia,
    c.pvt_key_encryption_type_desc,
    dp.name AS owner_database_principal,
    dp.type_desc AS owner_type,
    c.thumbprint
FROM sys.certificates AS c
LEFT JOIN sys.database_principals AS dp
    ON c.principal_id = dp.principal_id
WHERE c.name NOT LIKE '##%'
ORDER BY c.expiry_date, c.name;
GO

PRINT '============================================================';
PRINT '3. Login y usuario de mirroring';
PRINT '============================================================';

DECLARE @MirroringPrincipal sysname;
SET @MirroringPrincipal = N'mirror_user';

SELECT
    @@SERVERNAME AS instancia,
    sp.name AS login_name,
    sp.type_desc,
    sp.create_date,
    sp.modify_date,
    sp.is_disabled
FROM sys.server_principals AS sp
WHERE sp.name = @MirroringPrincipal;

SELECT
    @@SERVERNAME AS instancia,
    dp.name AS database_user,
    dp.type_desc,
    dp.create_date,
    dp.modify_date
FROM sys.database_principals AS dp
WHERE dp.name = @MirroringPrincipal;
GO

PRINT '============================================================';
PRINT '4. Permisos CONNECT sobre endpoint';
PRINT '============================================================';

SELECT
    @@SERVERNAME AS instancia,
    ep.name AS endpoint_name,
    sp.name AS principal,
    sp.type_desc AS tipo_principal,
    perm.permission_name,
    perm.state_desc
FROM sys.server_permissions AS perm
INNER JOIN sys.endpoints AS ep
    ON perm.major_id = ep.endpoint_id
INNER JOIN sys.server_principals AS sp
    ON perm.grantee_principal_id = sp.principal_id
WHERE ep.type_desc = 'DATABASE_MIRRORING'
ORDER BY ep.name, sp.name;
GO

PRINT '============================================================';
PRINT '5. Estado de mirroring';
PRINT '============================================================';

SELECT
    @@SERVERNAME AS instancia,
    DB_NAME(database_id) AS database_name,
    mirroring_state_desc,
    mirroring_role_desc,
    mirroring_safety_level_desc,
    mirroring_partner_name,
    mirroring_partner_instance,
    mirroring_witness_name,
    mirroring_witness_state_desc,
    mirroring_connection_timeout
FROM sys.database_mirroring
WHERE mirroring_guid IS NOT NULL
ORDER BY DB_NAME(database_id);
GO
