/*
SCRIPT 07 - LIMPIEZA POSTERIOR OPCIONAL DE CERTIFICADOS ANTIGUOS

Objetivo:
  Retirar certificados antiguos que ya no son usados por endpoints ni relaciones
  activas de mirroring, despues de una ventana de observacion.

Compatibilidad:
  SQL Server 2008 R2 o superior.

IMPORTANTE:
  - NO ejecutar durante la ventana principal de renovacion.
  - Ejecutar solo como actividad posterior aprobada.
  - Validar que el certificado antiguo no este usado por ningun endpoint.
  - Validar estabilidad de mirroring durante 24 a 72 horas, o segun politica interna.
  - Mantener evidencia y respaldo documental del cambio.

Placeholders obligatorios:
  <CERTIFICADO_ANTIGUO_1>
  <CERTIFICADO_ANTIGUO_2>
*/

USE master;
GO

PRINT '============================================================';
PRINT '1. Validar si certificados antiguos aun son usados por endpoint';
PRINT '============================================================';

SELECT
    @@SERVERNAME AS instancia,
    e.name AS endpoint_name,
    c.name AS certificado_usado_por_endpoint,
    c.expiry_date
FROM sys.endpoints AS e
INNER JOIN sys.database_mirroring_endpoints AS dme
    ON e.endpoint_id = dme.endpoint_id
INNER JOIN sys.certificates AS c
    ON dme.certificate_id = c.certificate_id
WHERE e.type_desc = 'DATABASE_MIRRORING'
  AND c.name IN ('<CERTIFICADO_ANTIGUO_1>', '<CERTIFICADO_ANTIGUO_2>');
GO

PRINT 'Si la consulta anterior devuelve filas, NO ejecutar DROP CERTIFICATE.';
GO

PRINT '============================================================';
PRINT '2. Validar existencia de certificados antiguos';
PRINT '============================================================';

SELECT
    @@SERVERNAME AS instancia,
    name AS certificado,
    expiry_date,
    pvt_key_encryption_type_desc,
    USER_NAME(principal_id) AS owner_database_principal
FROM sys.certificates
WHERE name IN ('<CERTIFICADO_ANTIGUO_1>', '<CERTIFICADO_ANTIGUO_2>')
ORDER BY name;
GO

/*
Descomentar solo si:
  - La validacion del punto 1 no devuelve filas.
  - Existe aprobacion para limpieza posterior.
  - Ya no se requiere reversa al certificado anterior.

DROP CERTIFICATE [<CERTIFICADO_ANTIGUO_1>];
GO

DROP CERTIFICATE [<CERTIFICADO_ANTIGUO_2>];
GO
*/
