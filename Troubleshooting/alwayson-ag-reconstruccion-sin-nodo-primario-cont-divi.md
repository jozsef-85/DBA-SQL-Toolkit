# Troubleshooting Always On - Reconstrucción de AG sin nodo primario

## Caso

Durante la reconstrucción de un Availability Group de SQL Server Always On, las bases quedaron en estado `RESTORING` en las instancias secundarias y no existe un nodo primario activo ni un AG registrado.

Ambiente de referencia:

```text
Instancia: CONT_DIVI
AG:        LSQLCONTDIVI22
Bases:     Divisas_BcoDavivienda
           Divisas_BcoDavivienda_LOG
WSFC:      Windows Server Failover Cluster
```

---

## Síntoma

En SQL Server Management Studio, las bases aparecen como:

```text
Divisas_BcoDavivienda       (Restoring...)
Divisas_BcoDavivienda_LOG   (Restoring...)
```

No existe réplica primaria registrada porque el Availability Group no está creado o no está disponible.

En este escenario no sirve consultar el rol de Always On para saber cuál era el primario, ya que no hay un AG activo que informe ese estado.

---

## Objetivo

Identificar qué copia de la base está más avanzada y consistente para usarla como nueva primaria al reconstruir el Availability Group.

El criterio principal es comparar el historial de restores y los LSN (`last_lsn`) de cada base en cada nodo.

---

## Validar si existe rol huérfano en WSFC

Antes de recuperar una base, validar si existe el rol del AG en el clúster:

```powershell
Get-ClusterGroup | Where-Object {$_.Name -eq "LSQLCONTDIVI22"}

Get-ClusterResource | Where-Object {$_.OwnerGroup -eq "LSQLCONTDIVI22"} |
Select-Object Name, ResourceType, State, OwnerGroup
```

Resultado observado:

```text
Sin salida
```

Esto confirma que no existe un rol huérfano `LSQLCONTDIVI22` en WSFC.

---

## Revisar historial de restores

Ejecutar en cada nodo `CONT_DIVI`:

```sql
SELECT 
    @@SERVERNAME AS instancia,
    rh.destination_database_name AS database_name,
    rh.restore_date,
    rh.restore_type,
    CASE rh.restore_type
        WHEN 'D' THEN 'Database full'
        WHEN 'I' THEN 'Differential'
        WHEN 'L' THEN 'Log'
        ELSE rh.restore_type
    END AS restore_type_desc,
    bs.database_name AS backup_database_name,
    bs.backup_start_date,
    bs.backup_finish_date,
    bs.type AS backup_type,
    bs.first_lsn,
    bs.last_lsn,
    bs.checkpoint_lsn,
    bs.database_backup_lsn,
    bmf.physical_device_name
FROM msdb.dbo.restorehistory rh
LEFT JOIN msdb.dbo.backupset bs
    ON rh.backup_set_id = bs.backup_set_id
LEFT JOIN msdb.dbo.backupmediafamily bmf
    ON bs.media_set_id = bmf.media_set_id
WHERE rh.destination_database_name IN 
(
    'Divisas_BcoDavivienda',
    'Divisas_BcoDavivienda_LOG'
)
ORDER BY 
    rh.destination_database_name,
    rh.restore_date DESC;
GO
```

---

## Evidencia de LSN

### Nodo 3

```text
Instancia: CLAZLABDBPEMP3\CONT_DIVI
Restore:   2026-04-07
Backup:    2026-04-01

Divisas_BcoDavivienda      last_lsn = 186000056347200001
Divisas_BcoDavivienda_LOG  last_lsn = 225000016590400001
```

### Nodo 2

```text
Instancia: CLAZLABDBPEMP2\CONT_DIVI
Restore:   2026-05-09

Divisas_BcoDavivienda      last_lsn = 186000065384000001
Divisas_BcoDavivienda_LOG  last_lsn = 266000013772000001
```

### Nodo 1

```text
Instancia: CLAZLABDBPEMP1\CONT_DIVI
Restore:   2026-05-09

Divisas_BcoDavivienda      last_lsn = 186000065384000001
Divisas_BcoDavivienda_LOG  last_lsn = 266000013772000001
```

---

## Diagnóstico

El nodo 3 está atrasado respecto a nodo 1 y nodo 2.

Nodo 1 y nodo 2 están alineados por `last_lsn` en ambas bases:

```text
Divisas_BcoDavivienda      last_lsn = 186000065384000001
Divisas_BcoDavivienda_LOG  last_lsn = 266000013772000001
```

Por lo tanto, cualquiera de los dos puede ser candidato a nueva primaria.

Criterio operativo definido:

```text
Nueva primaria sugerida: CLAZLABDBPEMP2\CONT_DIVI
```

Motivo:

- Tiene restore reciente del 2026-05-09.
- Está alineado por LSN con nodo 1.
- Nodo 3 está atrasado y debe resembrarse.

---

## Validar estado actual de las bases

Ejecutar en cada nodo:

```sql
SELECT 
    @@SERVERNAME AS instancia,
    name,
    state_desc,
    user_access_desc,
    is_read_only,
    recovery_model_desc
FROM sys.databases
WHERE name IN 
(
    'Divisas_BcoDavivienda',
    'Divisas_BcoDavivienda_LOG'
);
GO
```

Si las bases están en `RESTORING` en nodo 1 y nodo 2, recuperar solamente el nodo elegido como nueva primaria.

---

## Recuperar la nueva primaria

Ejecutar solo en `CLAZLABDBPEMP2\CONT_DIVI`:

```sql
RESTORE DATABASE [Divisas_BcoDavivienda] WITH RECOVERY;
GO

RESTORE DATABASE [Divisas_BcoDavivienda_LOG] WITH RECOVERY;
GO
```

Validar que quedaron online:

```sql
SELECT 
    @@SERVERNAME AS instancia,
    name,
    state_desc,
    user_access_desc,
    is_read_only,
    recovery_model_desc
FROM sys.databases
WHERE name IN 
(
    'Divisas_BcoDavivienda',
    'Divisas_BcoDavivienda_LOG'
);
GO
```

Resultado esperado:

```text
ONLINE | MULTI_USER | READ_WRITE
```

---

## Crear nuevamente el Availability Group

Crear nuevamente el AG desde `CLAZLABDBPEMP2\CONT_DIVI` con:

```text
AG:       LSQLCONTDIVI22
Listener: VSQL22CONTDIVI
IP:       10.229.163.78
Probe:    45555
```

Los otros nodos deben quedar como secundarias con las bases en `NORECOVERY`.

---

## Reseed de secundarias

Después de recuperar nodo 2 como nueva primaria, tomar backups nuevos desde nodo 2 y restaurarlos en nodo 1 y nodo 3 con `NORECOVERY`.

Ejemplo desde la nueva primaria:

```sql
BACKUP DATABASE [Divisas_BcoDavivienda]
TO DISK = N'K:\SQL_BACKUP\Divisas_BcoDavivienda_full.bak'
WITH INIT, COMPRESSION, CHECKSUM, STATS = 10;
GO

BACKUP LOG [Divisas_BcoDavivienda]
TO DISK = N'K:\SQL_BACKUP\Divisas_BcoDavivienda_log.trn'
WITH INIT, COMPRESSION, CHECKSUM, STATS = 10;
GO

BACKUP DATABASE [Divisas_BcoDavivienda_LOG]
TO DISK = N'K:\SQL_BACKUP\Divisas_BcoDavivienda_LOG_full.bak'
WITH INIT, COMPRESSION, CHECKSUM, STATS = 10;
GO

BACKUP LOG [Divisas_BcoDavivienda_LOG]
TO DISK = N'K:\SQL_BACKUP\Divisas_BcoDavivienda_LOG_log.trn'
WITH INIT, COMPRESSION, CHECKSUM, STATS = 10;
GO
```

En cada secundaria:

```sql
RESTORE DATABASE [Divisas_BcoDavivienda]
FROM DISK = N'K:\SQL_BACKUP\Divisas_BcoDavivienda_full.bak'
WITH NORECOVERY, REPLACE, STATS = 10;
GO

RESTORE LOG [Divisas_BcoDavivienda]
FROM DISK = N'K:\SQL_BACKUP\Divisas_BcoDavivienda_log.trn'
WITH NORECOVERY, STATS = 10;
GO

RESTORE DATABASE [Divisas_BcoDavivienda_LOG]
FROM DISK = N'K:\SQL_BACKUP\Divisas_BcoDavivienda_LOG_full.bak'
WITH NORECOVERY, REPLACE, STATS = 10;
GO

RESTORE LOG [Divisas_BcoDavivienda_LOG]
FROM DISK = N'K:\SQL_BACKUP\Divisas_BcoDavivienda_LOG_log.trn'
WITH NORECOVERY, STATS = 10;
GO
```

Luego unir las bases al AG desde cada secundaria:

```sql
ALTER DATABASE [Divisas_BcoDavivienda]
SET HADR AVAILABILITY GROUP = [LSQLCONTDIVI22];
GO

ALTER DATABASE [Divisas_BcoDavivienda_LOG]
SET HADR AVAILABILITY GROUP = [LSQLCONTDIVI22];
GO
```

---

## Precauciones

- No ejecutar `WITH RECOVERY` en más de un nodo.
- No recuperar nodo 1 ni nodo 3 si serán secundarias.
- Nodo 3 debe resembrarse porque está atrasado por LSN.
- Antes de crear el AG, confirmar que no existe el rol `LSQLCONTDIVI22` en WSFC.
- Usar rutas de backup accesibles desde las secundarias o copiar manualmente los archivos antes de restaurar.
- Confirmar que los endpoints HADR estén `STARTED` y usando el puerto esperado.

---

## Validaciones posteriores

Validar réplicas y estado del AG:

```sql
SELECT 
    ag.name AS availability_group_name,
    ar.replica_server_name,
    ars.role_desc,
    ars.connected_state_desc,
    ars.synchronization_health_desc
FROM sys.availability_groups ag
INNER JOIN sys.availability_replicas ar
    ON ag.group_id = ar.group_id
INNER JOIN sys.dm_hadr_availability_replica_states ars
    ON ar.replica_id = ars.replica_id;
GO
```

Validar bases dentro del AG:

```sql
SELECT 
    DB_NAME(drs.database_id) AS database_name,
    drs.synchronization_state_desc,
    drs.synchronization_health_desc,
    drs.database_state_desc,
    drs.is_suspended,
    drs.suspend_reason_desc
FROM sys.dm_hadr_database_replica_states drs
WHERE DB_NAME(drs.database_id) IN
(
    'Divisas_BcoDavivienda',
    'Divisas_BcoDavivienda_LOG'
);
GO
```

Validar roles del clúster:

```powershell
Get-ClusterGroup | Where-Object {$_.Name -like "LSQLCONT*"}

Get-ClusterResource | Where-Object {$_.OwnerGroup -like "LSQLCONT*"} |
Select-Object Name, ResourceType, State, OwnerGroup
```

---

## Referencias Microsoft

- Always On Availability Groups: https://learn.microsoft.com/sql/database-engine/availability-groups/windows/overview-of-always-on-availability-groups-sql-server
- Preparar manualmente una base secundaria: https://learn.microsoft.com/sql/database-engine/availability-groups/windows/manually-prepare-a-secondary-database-for-an-availability-group-sql-server
- Failover clustering y Always On AG: https://learn.microsoft.com/sql/database-engine/availability-groups/windows/failover-clustering-and-always-on-availability-groups-sql-server
- DMV `sys.dm_hadr_database_replica_states`: https://learn.microsoft.com/sql/relational-databases/system-dynamic-management-views/sys-dm-hadr-database-replica-states-transact-sql
