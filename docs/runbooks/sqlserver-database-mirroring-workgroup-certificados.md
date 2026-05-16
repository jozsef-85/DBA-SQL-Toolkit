# Runbook: SQL Server Database Mirroring en workgroup con certificados

## Objetivo

Configurar SQL Server Database Mirroring entre dos instancias que no pertenecen a dominio, usando autenticacion por certificados en el endpoint `DATABASE_MIRRORING`.

Este runbook esta basado en un laboratorio real con dos nodos, base `AdventureWorks2022`, puerto de endpoint `5022` y conectividad entre servidores fuera de dominio.

## Alcance

Aplica cuando:

- Los servidores SQL Server estan en workgroup o no tienen relacion de confianza de dominio.
- No se debe usar `AUTHENTICATION = WINDOWS` en el endpoint de mirroring.
- La autenticacion del endpoint se realizara por certificados.
- El failover sera manual porque no se configura witness.

No aplica como recomendacion para nuevas arquitecturas productivas. Para nuevos disenos se debe evaluar Always On Availability Groups. Database Mirroring se mantiene para soporte de escenarios existentes, laboratorios o compatibilidad.

## Topologia del caso documentado

| Componente | Valor del laboratorio |
|---|---|
| Nodo 1 inicial | `Win2016-Web\\SERVNODO01` |
| IP Nodo 1 | `10.10.8.5` |
| Nodo 2 inicial | `Win2016Negocio\\SERVNODO2` |
| IP Nodo 2 | `10.10.8.6` |
| Base de datos | `AdventureWorks2022` |
| Puerto endpoint | `5022` |
| Puerto instancia SQL usado en SSMS | `20000` |
| Autenticacion endpoint | `CERTIFICATE` |
| Witness | No |
| Failover | Manual |

## Principios importantes

1. En workgroup, la autenticacion Windows para el endpoint no es el camino correcto. Se deben usar certificados.
2. Cada instancia solo puede tener un endpoint `DATABASE_MIRRORING`.
3. El nombre interno del endpoint puede ser distinto entre nodos. Lo importante es el puerto, estado, autenticacion y permisos.
4. `SET PARTNER` usa la direccion TCP del partner y el puerto del endpoint, no el puerto de la instancia SQL.
5. La base principal debe estar en `FULL recovery model`.
6. La base mirror debe estar restaurada con `NORECOVERY` y quedar en `RESTORING`.
7. Si el puerto responde por `Test-NetConnection`, pero aparece `Msg 1418`, se debe revisar handshake SQL: certificados, logins, permisos o configuracion parcial.

## Flujo de configuracion sin saltar pasos

### 1. Validaciones previas en ambos nodos

Ejecutar:

```text
sqlserver/mirroring/01_prechecks_mirroring_workgroup.sql
```

Validar:

- Nombre real de instancia.
- Estado de la base.
- Recovery model.
- Endpoint existente.
- Puerto `5022`.
- Certificados locales/remotos.
- Permisos `CONNECT` sobre endpoint.
- Estado actual en `sys.database_mirroring`.

### 2. Crear certificado y endpoint en Nodo 1

Ejecutar en Nodo 1:

```text
sqlserver/mirroring/02_nodo1_create_master_key_certificate_endpoint.sql
```

Resultado esperado:

```text
Cert_Mirroring_Nodo1
Endpoint: Mirroring
Puerto: 5022
AUTHENTICATION: CERTIFICATE
STATE: STARTED
```

Exportar certificado publico:

```text
C:\Temp\Cert_Mirroring_Nodo1.cer
```

Ese archivo se copia al Nodo 2.

### 3. Crear certificado y endpoint en Nodo 2

Ejecutar en Nodo 2:

```text
sqlserver/mirroring/03_nodo2_create_master_key_certificate_endpoint.sql
```

Resultado esperado:

```text
Cert_Mirroring_Nodo2
Endpoint: Endpoint_Mirroring
Puerto: 5022
AUTHENTICATION: CERTIFICATE
STATE: STARTED
```

Exportar certificado publico:

```text
C:\Temp\Cert_Mirroring_Nodo2.cer
```

Ese archivo se copia al Nodo 1.

### 4. Importar certificados publicos cruzados

Ejecutar el bloque correspondiente de:

```text
sqlserver/mirroring/04_import_remote_certificates_and_grant_connect.sql
```

En Nodo 1 debe quedar:

```text
Login_Mirroring_Nodo2
User_Mirroring_Nodo2
Cert_Remoto_Nodo2
GRANT CONNECT ON ENDPOINT::[Mirroring]
```

En Nodo 2 debe quedar:

```text
Login_Mirroring_Nodo1
User_Mirroring_Nodo1
Cert_Remoto_Nodo1
GRANT CONNECT ON ENDPOINT::[Endpoint_Mirroring]
```

### 5. Preparar base de datos

Ejecutar:

```text
sqlserver/mirroring/05_prepare_database_full_and_restore_norecovery.sql
```

En Nodo 1:

- Cambiar base a `FULL` si esta en `SIMPLE`.
- Tomar backup FULL nuevo.
- Tomar backup LOG posterior, recomendado para ambientes reales.

En Nodo 2:

- Restaurar FULL con `NORECOVERY`.
- Restaurar LOG con `NORECOVERY`.
- Validar que quede:

```text
AdventureWorks2022 | RESTORING | FULL
```

### 6. Configurar partner

Ejecutar:

```text
sqlserver/mirroring/06_set_partner_validate_and_manual_failover.sql
```

Orden correcto:

En Nodo 2, mirror inicial:

```sql
ALTER DATABASE [AdventureWorks2022]
SET PARTNER = 'TCP://10.10.8.5:5022';
```

En Nodo 1, principal inicial:

```sql
ALTER DATABASE [AdventureWorks2022]
SET PARTNER = 'TCP://10.10.8.6:5022';
```

Validacion esperada:

Nodo 1:

```text
AdventureWorks2022 | SYNCHRONIZED | PRINCIPAL | FULL | TCP://10.10.8.6:5022
```

Nodo 2:

```text
AdventureWorks2022 | SYNCHRONIZED | MIRROR | FULL | TCP://10.10.8.5:5022
```

### 7. Failover manual

Solo ejecutar si:

- `mirroring_state_desc = SYNCHRONIZED`
- `mirroring_safety_level_desc = FULL`
- Se ejecuta desde el principal actual.

```sql
ALTER DATABASE [AdventureWorks2022]
SET PARTNER FAILOVER;
```

## Errores vistos en el laboratorio

### Msg 1088 - Certificado no existe

Causa:

Se intento usar `Cert_Mirroring_Nodo1` antes de crearlo o se estaba en la instancia incorrecta.

Correccion:

Crear primero la master key, luego el certificado local y recien despues el endpoint o el `BACKUP CERTIFICATE`.

### Msg 207 - Invalid column name 'port'

Causa:

Se consulto `port` desde `sys.database_mirroring_endpoints`, pero el puerto esta en `sys.tcp_endpoints`.

Correccion:

Unir `sys.endpoints`, `sys.database_mirroring_endpoints` y `sys.tcp_endpoints`.

### Msg 15151 - Cannot find endpoint

Causa:

El endpoint tenia otro nombre. En Nodo 1 se llamaba `[Mirroring]`, no `[Endpoint_Mirroring]`.

Correccion:

Consultar `sys.endpoints` y usar el nombre real del endpoint local.

### Msg 15151 - Cannot find login

Causa:

Se intento otorgar `GRANT CONNECT` a un login que no existia en ese nodo.

Correccion:

Crear login remoto, user en master, certificado remoto autorizado al user y luego `GRANT CONNECT`.

### Base mirror en SIMPLE / RESTORING

Causa:

AdventureWorks2022 venia en `SIMPLE`.

Correccion:

Cambiar a `FULL` en el principal, tomar backup nuevo y restaurar en el mirror con `NORECOVERY`.

### Msg 1418

Causa aparente:

El mensaje indicaba que la direccion TCP no se podia alcanzar.

Diagnostico real:

`Test-NetConnection` al puerto `5022` devolvia `True`, por lo tanto red basica y firewall estaban correctos. El problema estaba en handshake SQL por certificados/logins/permisos y configuracion parcial de partner.

Correccion:

- Validar certificados cruzados.
- Validar permisos `CONNECT`.
- Revisar error log.
- Limpiar configuracion parcial si aplica.
- Repetir `SET PARTNER` en orden.

## Referencias Microsoft

- Use Certificates for a Database Mirroring Endpoint: https://learn.microsoft.com/en-us/sql/database-engine/database-mirroring/use-certificates-for-a-database-mirroring-endpoint-transact-sql
- Prerequisites, Restrictions, and Recommendations for Database Mirroring: https://learn.microsoft.com/en-us/sql/database-engine/database-mirroring/prerequisites-restrictions-and-recommendations-for-database-mirroring
- Prepare a Mirror Database for Mirroring: https://learn.microsoft.com/en-us/sql/database-engine/database-mirroring/prepare-a-mirror-database-for-mirroring-sql-server
- MSSQLSERVER_1418: https://learn.microsoft.com/en-us/sql/relational-databases/errors-events/mssqlserver-1418-database-engine-error
