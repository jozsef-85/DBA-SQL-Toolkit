/*
SCRIPT 04 - CAMBIAR ENDPOINT AL CERTIFICADO NUEVO

Objetivo:
  Actualizar el DATABASE_MIRRORING ENDPOINT para usar el certificado local nuevo.

Compatibilidad:
  SQL Server 2008 R2 o superior.

Notas de seguridad operacional:
  - Ejecutar solo dentro de ventana aprobada.
  - Ejecutar por instancia, no de forma masiva.
  - No usar AUTHENTICATION = WINDOWS NEGOTIATE si el ambiente opera con certificados.
  - No ejecutar en un witness/partner cuyo certificado local de endpoint no se renueva.
  - No eliminar certificados antiguos en esta ventana.

Placeholders obligatorios:
  <NOMBRE_ENDPOINT_MIRRORING>
  <CERTIFICADO_LOCAL_NUEVO>
*/

USE master;
GO

/* Prevalidar certificado actualmente usado por el endpoint. */
SELECT
    @@SERVERNAME AS instancia,
    e.name AS endpoint_name,
    e.state_desc,
    dme.connection_auth_desc,
    c.name AS certificado_actual_endpoint,
    c.expiry_date
FROM sys.endpoints AS e
INNER JOIN sys.database_mirroring_endpoints AS dme
    ON e.endpoint_id = dme.endpoint_id
LEFT JOIN sys.certificates AS c
    ON dme.certificate_id = c.certificate_id
WHERE e.name = '<NOMBRE_ENDPOINT_MIRRORING>';
GO

/* Cambio efectivo del endpoint. */
ALTER ENDPOINT [<NOMBRE_ENDPOINT_MIRRORING>]
FOR DATABASE_MIRRORING
(
    AUTHENTICATION = CERTIFICATE [<CERTIFICADO_LOCAL_NUEVO>],
    ENCRYPTION = REQUIRED ALGORITHM AES,
    ROLE = ALL
);
GO

/* Validar que el endpoint quedo usando el certificado nuevo. */
SELECT
    @@SERVERNAME AS instancia,
    e.name AS endpoint_name,
    e.state_desc,
    dme.connection_auth_desc,
    dme.encryption_algorithm_desc,
    dme.is_encryption_enabled,
    c.name AS certificado_usado_por_endpoint,
    c.start_date,
    c.expiry_date,
    DATEDIFF(DAY, GETDATE(), c.expiry_date) AS dias_para_expirar
FROM sys.endpoints AS e
INNER JOIN sys.database_mirroring_endpoints AS dme
    ON e.endpoint_id = dme.endpoint_id
LEFT JOIN sys.certificates AS c
    ON dme.certificate_id = c.certificate_id
WHERE e.name = '<NOMBRE_ENDPOINT_MIRRORING>';
GO
