# Caso: SQL Server Mirroring en workgroup con AdventureWorks2022 y certificados

## Resumen ejecutivo

Se configuro SQL Server Database Mirroring entre dos nodos fuera de dominio. La autenticacion del endpoint se implemento con certificados porque los servidores no estaban unidos a dominio. La base usada fue `AdventureWorks2022`.

El resultado final fue exitoso:

```text
AdventureWorks2022 | SYNCHRONIZED | PRINCIPAL | FULL | TCP://10.10.8.6:5022
```

## Ambiente

| Elemento | Valor |
|---|---|
| Nodo 1 | `Win2016-Web\\SERVNODO01` |
| IP Nodo 1 | `10.10.8.5` |
| Nodo 2 | `Win2016Negocio\\SERVNODO2` |
| IP Nodo 2 | `10.10.8.6` |
| SQL Server | 16.0.1000.6 |
| Base | `AdventureWorks2022` |
| Endpoint Nodo 1 | `Mirroring` |
| Endpoint Nodo 2 | `Endpoint_Mirroring` |
| Puerto endpoint | `5022` |
| Puerto instancia SQL | `20000` |
| Dominio | No |
| Autenticacion endpoint | Certificados |
| Witness | No |

## Secuencia aplicada

1. Se confirmo que al no haber dominio no correspondia usar autenticacion Windows para el endpoint.
2. Se crearon master keys en `master`.
3. Se crearon certificados locales:
   - `Cert_Mirroring_Nodo1`
   - `Cert_Mirroring_Nodo2`
4. Se crearon endpoints:
   - Nodo 1: `[Mirroring]`
   - Nodo 2: `[Endpoint_Mirroring]`
5. Se exportaron certificados publicos `.cer`.
6. Se copiaron cruzados:
   - Certificado publico de Nodo 1 hacia Nodo 2.
   - Certificado publico de Nodo 2 hacia Nodo 1.
7. Se crearon logins/usuarios remotos.
8. Se asociaron certificados remotos:
   - Nodo 1: `Cert_Remoto_Nodo2` autorizado a `User_Mirroring_Nodo2`.
   - Nodo 2: `Cert_Remoto_Nodo1` autorizado a `User_Mirroring_Nodo1`.
9. Se otorgo `GRANT CONNECT` al endpoint local correcto.
10. Se cambio `AdventureWorks2022` a `FULL recovery model`.
11. Se genero backup FULL nuevo.
12. Se restauro en Nodo 2 con `NORECOVERY`.
13. Se ejecuto `SET PARTNER` en orden correcto.
14. Se valido estado `SYNCHRONIZED`.

## Hallazgos y errores del laboratorio

### 1. Certificado local inexistente

Error:

```text
Msg 1088
Cannot find the object "Cert_Mirroring_Nodo1" because it does not exist or you do not have permissions.
```

Causa:

Se intento usar o respaldar el certificado antes de crearlo.

Leccion:

El orden correcto es:

```text
MASTER KEY -> CERTIFICATE LOCAL -> ENDPOINT -> BACKUP CERTIFICATE
```

### 2. Consulta incorrecta de puerto

Error:

```text
Msg 207
Invalid column name 'port'
```

Causa:

La columna `port` no esta en `sys.database_mirroring_endpoints`; esta en `sys.tcp_endpoints`.

Leccion:

Para validar endpoint usar join entre:

```text
sys.endpoints
sys.database_mirroring_endpoints
sys.tcp_endpoints
```

### 3. Nombre de endpoint distinto entre nodos

Situacion:

Nodo 1 tenia endpoint `[Mirroring]`; Nodo 2 tenia `[Endpoint_Mirroring]`.

Impacto:

El `GRANT CONNECT ON ENDPOINT::[Endpoint_Mirroring]` fallaba en Nodo 1 porque ahi el endpoint se llamaba `[Mirroring]`.

Leccion:

El nombre interno del endpoint no debe asumirse. Siempre consultar `sys.endpoints`.

### 4. Login remoto equivocado o incompleto

Situacion:

En Nodo 2 aparecia `Login_Mirroring_Nodo2`, pero el login necesario para recibir al Nodo 1 era `Login_Mirroring_Nodo1`.

Estado correcto final:

Nodo 1:

```text
Login_Mirroring_Nodo2 | User_Mirroring_Nodo2 | Cert_Remoto_Nodo2
```

Nodo 2:

```text
Login_Mirroring_Nodo1 | User_Mirroring_Nodo1 | Cert_Remoto_Nodo1
```

Leccion:

Cada nodo debe tener un login que representa al otro nodo, no a si mismo.

### 5. AdventureWorks2022 estaba en SIMPLE

Situacion:

La base mirror aparecia como `SIMPLE / RESTORING`.

Causa:

AdventureWorks2022 venia en `SIMPLE`.

Leccion:

Database Mirroring requiere `FULL recovery model`. Se debe cambiar en el principal, tomar backup nuevo y restaurar con `NORECOVERY` en el mirror.

### 6. Error 1418 con red aparentemente buena

Error:

```text
Msg 1418
The server network address "TCP://10.10.8.6:5022" can not be reached or does not exist.
```

Validacion:

```text
Test-NetConnection 10.10.8.6 -Port 5022
TcpTestSucceeded : True
```

Conclusion:

No era firewall ni conectividad TCP basica. El problema estaba en el handshake SQL de mirroring, generado por certificados/logins/permisos o configuracion parcial.

Leccion:

Cuando el puerto responde pero aparece 1418, revisar:

- Error log de SQL Server.
- Certificados remotos asociados al usuario correcto.
- `GRANT CONNECT` sobre el endpoint correcto.
- Endpoint `STARTED`.
- Base en `FULL` y mirror en `RESTORING`.
- Configuracion parcial de `SET PARTNER`.

## Estado final validado

En Nodo 1:

```text
AdventureWorks2022
SYNCHRONIZED
PRINCIPAL
FULL
TCP://10.10.8.6:5022
```

Interpretacion:

- Mirroring operativo.
- Nodo 1 quedo como principal.
- Nodo 2 quedo como mirror.
- La sincronizacion quedo completa.
- El modo es high safety (`FULL`).
- Sin witness, por lo tanto failover manual.

## Conclusion tecnica

El problema principal no fue la red. La conectividad TCP al endpoint estaba operativa. La causa real fue una combinacion de:

- Base inicialmente en `SIMPLE`.
- Configuracion parcial de mirroring durante pruebas.
- Confusion en nombres de endpoints.
- Validacion inicial del login equivocado en Nodo 2.
- Certificados remotos que debian quedar correctamente cruzados.

Una vez corregido el recovery model, restaurada la base con `NORECOVERY`, validados certificados cruzados y aplicados los `GRANT CONNECT` sobre los endpoints reales, el `SET PARTNER` funciono y la base quedo `SYNCHRONIZED`.

## Archivos relacionados

- `sqlserver/mirroring/README.md`
- `sqlserver/mirroring/01_prechecks_mirroring_workgroup.sql`
- `sqlserver/mirroring/02_nodo1_create_master_key_certificate_endpoint.sql`
- `sqlserver/mirroring/03_nodo2_create_master_key_certificate_endpoint.sql`
- `sqlserver/mirroring/04_import_remote_certificates_and_grant_connect.sql`
- `sqlserver/mirroring/05_prepare_database_full_and_restore_norecovery.sql`
- `sqlserver/mirroring/06_set_partner_validate_and_manual_failover.sql`
- `sqlserver/mirroring/07_troubleshooting_error_1418_and_handshake.sql`
- `docs/runbooks/sqlserver-database-mirroring-workgroup-certificados.md`
