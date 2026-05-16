/*
================================================================================
 Script: 03_nodo2_create_master_key_certificate_endpoint.sql
 Categoria: SQL Server Database Mirroring / Workgroup / Certificados
 Objetivo:
   Crear Master Key, certificado local y endpoint DATABASE_MIRRORING en Nodo 2.

 Ejecutar en:
   Nodo 2 / Mirror inicial.

 Resultado esperado:
   - Certificado local: Cert_Mirroring_Nodo2
   - Endpoint: Endpoint_Mirroring
   - Puerto: 5022
   - Autenticacion endpoint: CERTIFICATE
================================================================================
*/

USE master;
GO

/* 1. Crear Master Key si no existe */
IF NOT EXISTS (
    SELECT 1
    FROM sys.symmetric_keys
    WHERE name = '##MS_DatabaseMasterKey##'
)
BEGIN
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'REEMPLAZAR_Clave_Fuerte_MasterKey_Nodo2!';
END
GO

/* 2. Crear certificado local del Nodo 2 */
IF NOT EXISTS (
    SELECT 1
    FROM sys.certificates
    WHERE name = 'Cert_Mirroring_Nodo2'
)
BEGIN
    CREATE CERTIFICATE Cert_Mirroring_Nodo2
    WITH SUBJECT = 'Certificado local para Database Mirroring - Nodo2',
         EXPIRY_DATE = '2030-12-31';
END
GO

/* 3. Crear endpoint de mirroring con autenticacion por certificado */
IF NOT EXISTS (
    SELECT 1
    FROM sys.endpoints
    WHERE type_desc = 'DATABASE_MIRRORING'
)
BEGIN
    CREATE ENDPOINT [Endpoint_Mirroring]
    STATE = STARTED
    AS TCP
    (
        LISTENER_PORT = 5022,
        LISTENER_IP = ALL
    )
    FOR DATABASE_MIRRORING
    (
        AUTHENTICATION = CERTIFICATE Cert_Mirroring_Nodo2,
        ENCRYPTION = REQUIRED ALGORITHM AES,
        ROLE = ALL
    );
END
ELSE
BEGIN
    PRINT 'Ya existe un endpoint DATABASE_MIRRORING en esta instancia. Validar nombre, puerto y autenticacion antes de continuar.';
END
GO

/* 4. Exportar certificado publico del Nodo 2
   Copiar este archivo al Nodo 1.
*/
BACKUP CERTIFICATE Cert_Mirroring_Nodo2
TO FILE = 'C:\Temp\Cert_Mirroring_Nodo2.cer';
GO

/* 5. Validacion */
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
GO

SELECT
    name,
    subject,
    start_date,
    expiry_date
FROM sys.certificates
WHERE name = 'Cert_Mirroring_Nodo2';
GO
