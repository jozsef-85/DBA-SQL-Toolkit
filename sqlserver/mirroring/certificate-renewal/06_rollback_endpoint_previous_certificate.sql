/*
SCRIPT 06 - ROLLBACK ENDPOINT A CERTIFICADO ANTERIOR

Objetivo:
  Volver el DATABASE_MIRRORING ENDPOINT al certificado anterior en caso
  de falla durante la ventana de renovacion.

Compatibilidad:
  SQL Server 2008 R2 o superior.

Notas de seguridad operacional:
  - Ejecutar solo si el cambio al certificado nuevo genera falla.
  - Requiere que el certificado anterior NO haya sido eliminado.
  - Ejecutar por instancia afectada.
  - No cambia puertos ni elimina objetos.

Placeholders obligatorios:
  <NOMBRE_ENDPOINT_MIRRORING>
  <CERTIFICADO_LOCAL_ANTERIOR>
*/

USE master;
GO

ALTER ENDPOINT [<NOMBRE_ENDPOINT_MIRRORING>]
FOR DATABASE_MIRRORING
(
    AUTHENTICATION = CERTIFICATE [<CERTIFICADO_LOCAL_ANTERIOR>],
    ENCRYPTION = REQUIRED ALGORITHM AES,
    ROLE = ALL
);
GO

SELECT
    @@SERVERNAME AS instancia,
    e.name AS endpoint_name,
    e.state_desc,
    dme.connection_auth_desc,
    dme.encryption_algorithm_desc,
    c.name AS certificado_usado_por_endpoint,
    c.expiry_date
FROM sys.endpoints AS e
INNER JOIN sys.database_mirroring_endpoints AS dme
    ON e.endpoint_id = dme.endpoint_id
LEFT JOIN sys.certificates AS c
    ON dme.certificate_id = c.certificate_id
WHERE e.name = '<NOMBRE_ENDPOINT_MIRRORING>';
GO

SELECT
    @@SERVERNAME AS instancia,
    DB_NAME(database_id) AS database_name,
    mirroring_state_desc,
    mirroring_role_desc,
    mirroring_partner_name,
    mirroring_witness_name,
    mirroring_witness_state_desc
FROM sys.database_mirroring
WHERE mirroring_guid IS NOT NULL
ORDER BY DB_NAME(database_id);
GO
