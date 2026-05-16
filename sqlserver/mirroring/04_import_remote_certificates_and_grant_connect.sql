/*
================================================================================
 Script: 04_import_remote_certificates_and_grant_connect.sql
 Categoria: SQL Server Database Mirroring / Workgroup / Certificados
 Objetivo:
   Configurar la confianza cruzada entre los nodos mediante certificados publicos.

 Idea central:
   - En Nodo 1 se importa el certificado publico del Nodo 2.
   - En Nodo 2 se importa el certificado publico del Nodo 1.
   - En cada nodo se crea un LOGIN que representa al partner remoto.
   - El certificado remoto se asocia a un USER en master.
   - Se otorga CONNECT al endpoint local.

 Archivos requeridos:
   Nodo 1 debe tener: C:\Temp\Cert_Mirroring_Nodo2.cer
   Nodo 2 debe tener: C:\Temp\Cert_Mirroring_Nodo1.cer

 Importante:
   No ejecutar ambos bloques en el mismo nodo.
================================================================================
*/

/*===============================================================================
 BLOQUE A - Ejecutar en NODO 1
 Endpoint local del caso documentado: [Mirroring]
 Importa certificado publico del Nodo 2.
===============================================================================*/

USE master;
GO

/* Ejecutar este bloque solo en Nodo 1 */
/*
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'Login_Mirroring_Nodo2')
BEGIN
    CREATE LOGIN Login_Mirroring_Nodo2
    WITH PASSWORD = 'REEMPLAZAR_Clave_Fuerte_Login_Nodo2!';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'User_Mirroring_Nodo2')
BEGIN
    CREATE USER User_Mirroring_Nodo2
    FOR LOGIN Login_Mirroring_Nodo2;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.certificates WHERE name = 'Cert_Remoto_Nodo2')
BEGIN
    CREATE CERTIFICATE Cert_Remoto_Nodo2
    AUTHORIZATION User_Mirroring_Nodo2
    FROM FILE = 'C:\Temp\Cert_Mirroring_Nodo2.cer';
END
GO

GRANT CONNECT ON ENDPOINT::[Mirroring]
TO Login_Mirroring_Nodo2;
GO
*/

/*===============================================================================
 BLOQUE B - Ejecutar en NODO 2
 Endpoint local del caso documentado: [Endpoint_Mirroring]
 Importa certificado publico del Nodo 1.
===============================================================================*/

USE master;
GO

/* Ejecutar este bloque solo en Nodo 2 */
/*
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'Login_Mirroring_Nodo1')
BEGIN
    CREATE LOGIN Login_Mirroring_Nodo1
    WITH PASSWORD = 'REEMPLAZAR_Clave_Fuerte_Login_Nodo1!';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'User_Mirroring_Nodo1')
BEGIN
    CREATE USER User_Mirroring_Nodo1
    FOR LOGIN Login_Mirroring_Nodo1;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.certificates WHERE name = 'Cert_Remoto_Nodo1')
BEGIN
    CREATE CERTIFICATE Cert_Remoto_Nodo1
    AUTHORIZATION User_Mirroring_Nodo1
    FROM FILE = 'C:\Temp\Cert_Mirroring_Nodo1.cer';
END
GO

GRANT CONNECT ON ENDPOINT::[Endpoint_Mirroring]
TO Login_Mirroring_Nodo1;
GO
*/

/*===============================================================================
 Validaciones - ejecutar en ambos nodos
===============================================================================*/

PRINT 'Validacion de permisos CONNECT sobre endpoint DATABASE_MIRRORING';
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
GO

PRINT 'Validacion de login, usuario y certificado remoto';
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
WHERE sp.name IN ('Login_Mirroring_Nodo1', 'Login_Mirroring_Nodo2')
ORDER BY sp.name;
GO
