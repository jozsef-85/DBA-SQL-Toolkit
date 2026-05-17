/*
SCRIPT 05 - POSTCHECK VALIDACION MIRRORING

Objetivo:
  Validar endpoint, certificados, permisos, estado de mirroring y errorlog
  despues de renovar certificados de Database Mirroring.

Compatibilidad:
  SQL Server 2008 R2 o superior.

Notas:
  - No realiza cambios.
  - Ejecutar conectado a cada instancia involucrada.
  - Guardar resultados como evidencia posterior.
*/

USE master;
GO

SET NOCOUNT ON;
GO

PRINT '============================================================';
PRINT '1. Endpoint y certificado activo posterior';
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
PRINT '2. Certificados nuevos y antiguos relevantes';
PRINT '============================================================';

/* Ajustar nombres segun el ambiente antes de ejecutar. */
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
    USER_NAME(c.principal_id) AS owner_database_principal,
    c.thumbprint
FROM sys.certificates AS c
WHERE c.name NOT LIKE '##%'
ORDER BY c.expiry_date, c.name;
GO

PRINT '============================================================';
PRINT '3. Permisos CONNECT sobre endpoint';
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
PRINT '4. Estado de mirroring';
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

PRINT '============================================================';
PRINT '5. Errorlog - mirroring / certificate / endpoint';
PRINT '============================================================';

EXEC master.dbo.xp_readerrorlog 0, 1, N'mirroring';
GO

EXEC master.dbo.xp_readerrorlog 0, 1, N'certificate';
GO

EXEC master.dbo.xp_readerrorlog 0, 1, N'endpoint';
GO
