/*
SCRIPT 02 - CREAR Y EXPORTAR CERTIFICADO LOCAL NUEVO

Objetivo:
  Crear un certificado local nuevo para Database Mirroring y exportar
  su certificado publico (.cer) para importarlo en los demas servidores.

Compatibilidad:
  SQL Server 2008 R2 o superior.

Notas:
  - Ejecutar conectado a la instancia cuyo certificado local sera renovado.
  - No modifica el endpoint.
  - No elimina certificados antiguos.
  - La ruta indicada corresponde al servidor SQL donde corre la instancia,
    no al equipo desde donde se abre SSMS.

Placeholders obligatorios:
  <CERTIFICADO_LOCAL_NUEVO>
  <USUARIO_MIRRORING>
  <SUBJECT_CERTIFICADO>
  <START_DATE_YYYYMMDD>
  <EXPIRY_DATE_YYYYMMDD>
  <RUTA_CERTIFICADO_PUBLICO>
*/

USE master;
GO

/* Validar fecha/hora real de la instancia antes de definir START_DATE. */
SELECT
    @@SERVERNAME AS instancia,
    GETDATE() AS fecha_hora_sql;
GO

/* Crear certificado local nuevo. */
CREATE CERTIFICATE [<CERTIFICADO_LOCAL_NUEVO>]
AUTHORIZATION [<USUARIO_MIRRORING>]
WITH
    SUBJECT = '<SUBJECT_CERTIFICADO>',
    START_DATE = '<START_DATE_YYYYMMDD>',
    EXPIRY_DATE = '<EXPIRY_DATE_YYYYMMDD>';
GO

/* Exportar certificado publico. */
BACKUP CERTIFICATE [<CERTIFICADO_LOCAL_NUEVO>]
TO FILE = '<RUTA_CERTIFICADO_PUBLICO>';
GO

/* Validar que el certificado local nuevo existe y tiene llave privada. */
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
WHERE name = '<CERTIFICADO_LOCAL_NUEVO>';
GO
