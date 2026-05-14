# SQL Server Troubleshooting

Runbook para analisis rapido de lentitud, I/O, bloqueos y transacciones abiertas.

La numeracion indica el orden sugerido de accion durante un incidente. No todos los pasos se ejecutan siempre: se avanza segun lo que muestre el diagnostico anterior.

## Flujo A: lentitud, I/O o carga alta

1. `sqlserver/performance/waits/01_waits_overview.sql`: orienta el diagnostico. Si predominan waits de I/O, WRITELOG o HADR, seguir con sesiones e I/O.
2. `sqlserver/performance/sessions/01_user_sessions.sql`: identifica sesiones activas de usuarios y procesos de aplicacion.
3. `sqlserver/performance/sessions/02_top_active_sessions.sql`: prioriza sesiones por escrituras, lecturas y lecturas logicas.
4. `sqlserver/performance/sessions/03_active_requests_detail.sql`: muestra requests activos con texto SQL y waits.
5. `sqlserver/performance/connections/01_connections_by_database.sql`: revisa concentracion de conexiones por base.
6. `sqlserver/performance/connections/02_connections_by_login.sql`: agrupa sesiones por login o cuenta de aplicacion.
7. `sqlserver/performance/connections/03_connections_by_application.sql`: detecta aplicaciones con exceso de conexiones.
8. `sqlserver/performance/memory/01_buffer_pool_usage_by_database.sql`: estima uso de buffer pool por base.
9. `sqlserver/performance/io/01_io_file_interval.sql`: mide deltas de I/O por archivo durante una ventana corta.

## Flujo B: bloqueo o transacciones

1. `sqlserver/blocking/01_blocked_sessions.sql`: confirma si existen sesiones bloqueadas y entrega `session_id` / `blocking_session_id`.
2. `sqlserver/blocking/02_blocking_session_detail.sql`: muestra login, host, programa y estado de la sesion bloqueante.
3. `sqlserver/blocking/03_blocking_inputbuffer.sql`: muestra la ultima instruccion enviada por un SPID especifico.
4. `sqlserver/blocking/04_locked_resources.sql`: revisa locks de las sesiones involucradas en el bloqueo.
5. `sqlserver/blocking/05_open_transactions.sql`: valida si existe una transaccion abierta sosteniendo el bloqueo.

## Contexto operativo

- Si el incidente es lentitud general, partir por el Flujo A.
- Si los usuarios reportan procesos congelados o timeouts, partir por el Flujo B.
- Si `01_blocked_sessions.sql` devuelve filas, usar el `blocking_session_id` como entrada para los scripts siguientes.
- Los scripts no incluyen SPIDs fijos de revisiones anteriores.
- Los filtros con `@session_id` son opcionales salvo `03_blocking_inputbuffer.sql`, donde DBCC INPUTBUFFER requiere un SPID concreto.
- `sqlserver/performance/io/01_io_file_interval.sql` mide deltas por intervalo; ajustar `@sample_seconds` segun el incidente.
