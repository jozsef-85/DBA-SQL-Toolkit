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
    connections/     Conexiones por base, login y aplicacion.
    memory/          Uso de buffer pool por base de datos.
  blocking/          Bloqueos, bloqueadores, locks y transacciones abiertas.
  alwayson/          Validaciones Always On Availability Groups.
  mirroring/         Database Mirroring en workgroup con certificados.
    certificate-renewal/ Renovacion controlada de certificados de mirroring.
  maintenance/       Acciones operativas controladas.
    dbcc/            Diagnostico y operacion CHECKDB/DBCC.

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
4. `sqlserver/performance/sessions/03_active_requests_detail.sql`
5. `sqlserver/performance/connections/01_connections_by_database.sql`
6. `sqlserver/performance/connections/02_connections_by_login.sql`
7. `sqlserver/performance/connections/03_connections_by_application.sql`
8. `sqlserver/performance/memory/01_buffer_pool_usage_by_database.sql`
9. `sqlserver/performance/io/01_io_file_interval.sql`

### Blocking

1. `sqlserver/blocking/01_blocked_sessions.sql`
2. `sqlserver/blocking/02_blocking_session_detail.sql`
3. `sqlserver/blocking/03_blocking_inputbuffer.sql`
4. `sqlserver/blocking/04_locked_resources.sql`
5. `sqlserver/blocking/05_open_transactions.sql`

### Database Mirroring / Workgroup con certificados

1. `sqlserver/mirroring/01_prechecks_mirroring_workgroup.sql`
2. `sqlserver/mirroring/02_nodo1_create_master_key_certificate_endpoint.sql`
3. `sqlserver/mirroring/03_nodo2_create_master_key_certificate_endpoint.sql`
4. `sqlserver/mirroring/04_import_remote_certificates_and_grant_connect.sql`
5. `sqlserver/mirroring/05_prepare_database_full_and_restore_norecovery.sql`
6. `sqlserver/mirroring/06_set_partner_validate_and_manual_failover.sql`
7. `sqlserver/mirroring/07_troubleshooting_error_1418_and_handshake.sql`

### Database Mirroring / Renovacion de certificados

1. `sqlserver/mirroring/certificate-renewal/01_precheck_consolidado_certificados_mirroring.sql`
2. `sqlserver/mirroring/certificate-renewal/02_create_and_export_local_certificates.sql`
3. `sqlserver/mirroring/certificate-renewal/03_import_remote_public_certificates.sql`
4. `sqlserver/mirroring/certificate-renewal/04_switch_endpoint_to_new_certificate.sql`
5. `sqlserver/mirroring/certificate-renewal/05_postcheck_validate_mirroring.sql`
6. `sqlserver/mirroring/certificate-renewal/06_rollback_endpoint_previous_certificate.sql`
7. `sqlserver/mirroring/certificate-renewal/07_optional_cleanup_old_certificates.sql`

### DBCC / CHECKDB

1. `sqlserver/maintenance/dbcc/01_detectar_dbcc_activo.sql`
2. `sqlserver/maintenance/dbcc/02_validar_bloqueo_impacto.sql`
3. `sqlserver/maintenance/dbcc/03_validar_snapshots_y_archivos_dbcc.sql`
4. `sqlserver/maintenance/dbcc/04_revisar_errorlog_dbcc.sql`
5. `sqlserver/maintenance/dbcc/05_monitorear_rollback_dbcc.sql`
6. `sqlserver/maintenance/dbcc/06_validacion_post_limpieza.sql`
7. `sqlserver/maintenance/dbcc/07_job_checkdb_physical_only_ao.sql`

## Documentacion

- `docs/runbooks/sqlserver-troubleshooting.md`: guia para incidentes de lentitud, I/O, bloqueo y transacciones.
- `docs/runbooks/sqlserver-database-mirroring-workgroup-certificados.md`: guia completa para mirroring fuera de dominio con certificados.
- `docs/cases/capacity-log/`: casos de capacidad y transaction log.
- `docs/cases/alwayson/`: casos Always On / WSFC.
- `docs/cases/dbcc/`: casos DBCC / CHECKDB.
- `docs/cases/mirroring/`: casos Database Mirroring.

## Criterio de ejecucion

- Scripts de diagnostico: solo lectura, pensados para correr durante analisis.
- Scripts operativos: pueden ejecutar `BACKUP LOG`, `ALTER DATABASE`, `RESTORE`, `CREATE ENDPOINT`, `CREATE CERTIFICATE` o `DBCC SHRINKFILE`; revisar placeholders antes de correr.
- Scripts con `@session_id`: dejar `NULL` para revisar el escenario activo cuando aplique, o definir un SPID obtenido desde el diagnostico previo.

## Advertencia

No usar shrink como mantenimiento rutinario.
Validar siempre recovery model, backups, espacio libre, rol PRIMARY en AG y ventana operacional antes de ejecutar acciones.
Para Database Mirroring en workgroup, validar certificados, endpoints, permisos `CONNECT`, puerto de mirroring y estado `RESTORING` antes de ejecutar `SET PARTNER`.
Para renovacion de certificados de Database Mirroring, no ejecutar `DROP CERTIFICATE` durante la ventana principal, no cambiar a `WINDOWS NEGOTIATE` si el endpoint opera con certificados y mantener certificados antiguos hasta validar estabilidad.
