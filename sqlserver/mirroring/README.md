# SQL Server Database Mirroring en workgroup

Categoria para configurar, validar y solucionar problemas de SQL Server Database Mirroring cuando los nodos no pertenecen a dominio y la autenticacion del endpoint debe realizarse por certificados.

> Nota: Database Mirroring es una tecnologia en desuso para nuevos desarrollos. Para arquitecturas nuevas se recomienda evaluar Always On Availability Groups. Esta categoria se mantiene para soporte, laboratorios, migraciones y escenarios legacy.

## Escenario objetivo

- Dos instancias SQL Server fuera de dominio o en workgroup.
- Comunicacion TCP entre nodos por puerto de endpoint, por ejemplo `5022`.
- Base principal en `FULL recovery model`.
- Base espejo restaurada con `NORECOVERY` y estado `RESTORING`.
- Endpoint `DATABASE_MIRRORING` con `AUTHENTICATION = CERTIFICATE`.
- Sin witness; failover manual.

## Orden de ejecucion

1. `01_prechecks_mirroring_workgroup.sql`  
   Valida version, edicion, recovery model, estado de la base, endpoint, certificados, permisos y metadatos de mirroring.

2. `02_nodo1_create_master_key_certificate_endpoint.sql`  
   Crea master key, certificado local y endpoint de mirroring en Nodo 1.

3. `03_nodo2_create_master_key_certificate_endpoint.sql`  
   Crea master key, certificado local y endpoint de mirroring en Nodo 2.

4. `04_import_remote_certificates_and_grant_connect.sql`  
   Importa certificados publicos cruzados, crea logins/usuarios remotos y otorga `GRANT CONNECT` al endpoint correcto.

5. `05_prepare_database_full_and_restore_norecovery.sql`  
   Cambia la base principal a `FULL`, genera backup y restaura la base en el mirror con `NORECOVERY`.

6. `06_set_partner_validate_and_manual_failover.sql`  
   Ejecuta `ALTER DATABASE ... SET PARTNER`, valida `SYNCHRONIZED` y documenta failover manual.

7. `07_troubleshooting_error_1418_and_handshake.sql`  
   Diagnostica error 1418, problemas de certificados, endpoints, permisos y configuraciones parciales.

## Referencias Microsoft

- Use Certificates for a Database Mirroring Endpoint: https://learn.microsoft.com/en-us/sql/database-engine/database-mirroring/use-certificates-for-a-database-mirroring-endpoint-transact-sql
- Prerequisites, Restrictions, and Recommendations for Database Mirroring: https://learn.microsoft.com/en-us/sql/database-engine/database-mirroring/prerequisites-restrictions-and-recommendations-for-database-mirroring
- Prepare a Mirror Database for Mirroring: https://learn.microsoft.com/en-us/sql/database-engine/database-mirroring/prepare-a-mirror-database-for-mirroring-sql-server
- MSSQLSERVER_1418: https://learn.microsoft.com/en-us/sql/relational-databases/errors-events/mssqlserver-1418-database-engine-error

## Caso base documentado

Ver tambien:

- `docs/runbooks/sqlserver-database-mirroring-workgroup-certificados.md`
- `docs/cases/mirroring/caso-lab-adventureworks2022-workgroup-certificados.md`
