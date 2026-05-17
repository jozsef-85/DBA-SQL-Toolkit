/*
SCRIPT 03 - IMPORTAR CERTIFICADOS PUBLICOS REMOTOS

Objetivo:
  Importar en master el certificado publico de otro servidor de mirroring.

Compatibilidad:
  SQL Server 2008 R2 o superior.

Notas:
  - Ejecutar conectado a la instancia destino.
  - El archivo .cer debe existir en una ruta local accesible por el servicio SQL Server
    de la instancia destino.
  - El certificado importado debe quedar como NO_PRIVATE_KEY.
  - Este paso no modifica el endpoint.

Casos de uso:
  - En Nodo A: importar certificado publico nuevo de Nodo B.
  - En Nodo B: importar certificado publico nuevo de Nodo A.
  - En witness/partner vigente: importar certificados publicos nuevos de los nodos renovados,
    sin cambiar el endpoint local.

Placeholders obligatorios:
  <CERTIFICADO_REMOTO_NUEVO>
  <USUARIO_MIRRORING>
  <RUTA_CERTIFICADO_PUBLICO_REMOTO>
*/

USE master;
GO

CREATE CERTIFICATE [<CERTIFICADO_REMOTO_NUEVO>]
AUTHORIZATION [<USUARIO_MIRRORING>]
FROM FILE = '<RUTA_CERTIFICADO_PUBLICO_REMOTO>';
GO

/* Validar que el certificado remoto nuevo existe y quedo sin llave privada. */
SELECT
    @@SERVERNAME AS instancia,
    name AS certificado,
    subject,
    start_date,
    expiry_date,
    DATEDIFF(DAY, GETDATE(), expiry_date) AS dias_para_expirar,
    pvt_key_encryption_type_desc,
    USER_NAME(principal_id) AS owner_database_principal
FROM sys.certificates
WHERE name = '<CERTIFICADO_REMOTO_NUEVO>';
GO
