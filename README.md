# DBA-SQL-Toolkit

Repositorio personal de scripts T-SQL para diagnostico, troubleshooting y operacion en SQL Server.

## Objetivo

- Tener scripts reutilizables para analisis rapido.
- Ordenar runbooks DBA por dominio operativo.
- Evitar acciones riesgosas sin diagnostico previo.
- Documentar casos reales sin exponer nombres de clientes o bases productivas.

## Estructura

```text
sqlserver/
  capacity/          Inventario de tamanos, espacio usado, volumenes y FILEGROWTH.
  transaction-log/   Diagnostico y operacion del transaction log.
  performance/       Waits, sesiones activas e I/O por intervalo.
  blocking/          Bloqueos, bloqueadores, locks y transacciones abiertas.
  alwayson/          Validaciones Always On Availability Groups.
  maintenance/       Acciones operativas controladas.

docs/
  runbooks/          Guias de uso y orden de accion.
  cases/             Casos documentados por tema.
```

## Orden de accion

Los scripts numerados representan el orden sugerido dentro de cada categoria. La idea es partir por diagnostico amplio, confirmar el origen del problema y recien despues ejecutar acciones operativas.

### Capacidad

1. `sqlserver/capacity/01_database_size_gb.sql`
2. `sqlserver/capacity/02_file_space_used_gb.sql`
3. `sqlserver/capacity/03_volume_free_space.sql`
4. `sqlserver/capacity/04_validate_filegrowth.sql`

### Transaction Log

1. `sqlserver/transaction-log/01_inventory_db_log_sizes.sql`
2. `sqlserver/transaction-log/02_log_status_gb.sql`
3. `sqlserver/transaction-log/03_log_space_and_reuse.sql`
4. `sqlserver/transaction-log/04_vlf_analysis.sql`
5. `sqlserver/transaction-log/05_monitor_log.sql`
6. `sqlserver/transaction-log/06_backup_log_manual.sql`
7. `sqlserver/transaction-log/07_shrink_log_controlled.sql`
8. `sqlserver/transaction-log/08_set_autogrowth.sql`

### Performance

1. `sqlserver/performance/waits/01_waits_overview.sql`
2. `sqlserver/performance/sessions/01_user_sessions.sql`
3. `sqlserver/performance/sessions/02_top_active_sessions.sql`
4. `sqlserver/performance/io/01_io_file_interval.sql`

### Blocking

1. `sqlserver/blocking/01_blocked_sessions.sql`
2. `sqlserver/blocking/02_blocking_session_detail.sql`
3. `sqlserver/blocking/03_blocking_inputbuffer.sql`
4. `sqlserver/blocking/04_locked_resources.sql`
5. `sqlserver/blocking/05_open_transactions.sql`

## Documentacion

- `docs/runbooks/sqlserver-troubleshooting.md`: guia para incidentes de lentitud, I/O, bloqueo y transacciones.
- `docs/cases/capacity-log/`: casos de capacidad y transaction log.
- `docs/cases/alwayson/`: casos Always On / WSFC.

## Criterio de ejecucion

- Scripts de diagnostico: solo lectura, pensados para correr durante analisis.
- Scripts operativos: pueden ejecutar `BACKUP LOG`, `ALTER DATABASE` o `DBCC SHRINKFILE`; revisar placeholders antes de correr.
- Scripts con `@session_id`: dejar `NULL` para revisar el escenario activo cuando aplique, o definir un SPID obtenido desde el diagnostico previo.

## Advertencia

No usar shrink como mantenimiento rutinario.
Validar siempre recovery model, backups, espacio libre, rol PRIMARY en AG y ventana operacional antes de ejecutar acciones.
