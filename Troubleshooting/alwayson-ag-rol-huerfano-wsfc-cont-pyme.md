# Troubleshooting Always On - Rol huérfano de Availability Group en WSFC

## Caso

Durante la creación de un Availability Group de SQL Server Always On, el asistente falla en el paso de creación del AG, aunque SQL Server no muestra el grupo creado en las vistas de Always On.

Ambiente de referencia:

```text
Instancia: CONT_PYME
AG:        LSQLCONTPYME22
WSFC:      Windows Server Failover Cluster
```

---

## Síntoma

En el wizard de Always On aparece error en el paso:

```text
Creating availability group 'LSQLCONTPYME22' = Error
```

Los pasos posteriores quedan omitidos:

```text
Waiting for availability group to come online
Joining secondaries to availability group
Creating full backup
Restoring database
Joining database to availability group
```

En Failover Cluster Manager se observa un rol activo:

```text
LSQLCONTPYME22   Running
```

Sin embargo, al consultar desde SQL Server, el AG no aparece en `sys.availability_groups`.

---

## Validaciones en SQL Server

Ejecutar en cada instancia `CONT_PYME`:

```sql
SELECT 
    @@SERVERNAME AS instancia,
    SERVERPROPERTY('IsHadrEnabled') AS IsHadrEnabled,
    SERVERPROPERTY('MachineName') AS MachineName,
    SERVERPROPERTY('InstanceName') AS InstanceName;
GO

SELECT 
    @@SERVERNAME AS instancia,
    name AS availability_group_name,
    group_id,
    cluster_type_desc,
    sequence_number
FROM sys.availability_groups
WHERE name = 'LSQLCONTPYME22';
GO

SELECT 
    ag.name AS availability_group_name,
    ar.replica_server_name,
    ar.endpoint_url,
    ar.availability_mode_desc,
    ar.failover_mode_desc,
    ar.seeding_mode_desc
FROM sys.availability_groups ag
INNER JOIN sys.availability_replicas ar
    ON ag.group_id = ar.group_id
WHERE ag.name = 'LSQLCONTPYME22';
GO
```

Resultado esperado para este problema:

```text
IsHadrEnabled = 1
sys.availability_groups = sin filas para LSQLCONTPYME22
sys.availability_replicas = sin filas para LSQLCONTPYME22
```

Validar endpoint HADR:

```sql
SELECT 
    @@SERVERNAME AS instancia,
    e.name,
    e.state_desc,
    e.type_desc,
    t.port,
    t.ip_address
FROM sys.database_mirroring_endpoints e
INNER JOIN sys.tcp_endpoints t
    ON e.endpoint_id = t.endpoint_id;
GO
```

Resultado observado:

```text
Endpoint: Hadr_endpoint
Estado:   STARTED
Puerto:   5031
```

---

## Validaciones en WSFC

Desde PowerShell en un nodo del clúster:

```powershell
Get-ClusterGroup -Name "LSQLCONTPYME22"

Get-ClusterResource | Where-Object {$_.OwnerGroup -eq "LSQLCONTPYME22"} |
Select-Object Name, ResourceType, State, OwnerGroup
```

Evidencia encontrada:

```text
Name         : LSQLCONTPYME22
ResourceType : SQL Server Availability Group
State        : Online
OwnerGroup   : LSQLCONTPYME22

Name         : LSQLCONTPYME22_10.229.163.78
ResourceType : IP Address
State        : Online
OwnerGroup   : LSQLCONTPYME22

Name         : LSQLCONTPYME22_VSQL22CONTDIVI
ResourceType : Network Name
State        : Online
OwnerGroup   : LSQLCONTPYME22
```

---

## Diagnóstico

El Availability Group `LSQLCONTPYME22` no existe en SQL Server, pero quedó creado un rol/recurso huérfano en WSFC con el mismo nombre.

Además, el rol contenía recursos de listener/IP que no correspondían a PYME:

```text
Listener incorrecto: VSQL22CONTDIVI
IP incorrecta:       10.229.163.78
```

Para `CONT_PYME`, la configuración esperada era:

```text
AG:       LSQLCONTPYME22
Listener: VSQL22CONTPYME
IP:       10.229.163.76
Probe:    49999
```

La falla ocurre porque el wizard intenta crear el AG, pero WSFC ya tiene un rol con ese nombre.

---

## Resolución

Como SQL Server no registra el AG, no corresponde ejecutar `DROP AVAILABILITY GROUP`, porque SQL no conoce ese objeto.

Primero confirmar que SQL Server no ve el AG:

```sql
SELECT 
    @@SERVERNAME AS instancia,
    name
FROM sys.availability_groups
WHERE name = 'LSQLCONTPYME22';
GO
```

Luego validar los recursos del clúster:

```powershell
Get-ClusterGroup -Name "LSQLCONTPYME22"

Get-ClusterResource | Where-Object {$_.OwnerGroup -eq "LSQLCONTPYME22"} |
Select-Object Name, ResourceType, State, OwnerGroup
```

Eliminar solo el rol huérfano:

```powershell
Remove-ClusterGroup -Name "LSQLCONTPYME22" -RemoveResources -Force
```

Validar que fue eliminado:

```powershell
Get-ClusterGroup | Where-Object {$_.Name -eq "LSQLCONTPYME22"}

Get-ClusterResource | Where-Object {$_.OwnerGroup -eq "LSQLCONTPYME22"}
```

Resultado esperado:

```text
Sin salida
```

Después recrear el AG usando los valores correctos:

```text
AG:       LSQLCONTPYME22
Listener: VSQL22CONTPYME
IP:       10.229.163.76
Probe:    49999
```

---

## Precauciones

- No eliminar roles sanos del clúster.
- No manipular desde Failover Cluster Manager recursos de AG válidos que sí existan en SQL Server.
- Antes de eliminar, confirmar que `sys.availability_groups` no devuelve filas para el AG afectado.
- Confirmar que listener/IP no correspondan a otro ambiente.
- Si SQL Server sí ve el AG, preferir `DROP AVAILABILITY GROUP` desde T-SQL antes que eliminar el recurso directamente desde WSFC.

---

## Referencias Microsoft

- Always On Availability Groups: https://learn.microsoft.com/sql/database-engine/availability-groups/windows/overview-of-always-on-availability-groups-sql-server
- Failover clustering y Always On AG: https://learn.microsoft.com/sql/database-engine/availability-groups/windows/failover-clustering-and-always-on-availability-groups-sql-server
