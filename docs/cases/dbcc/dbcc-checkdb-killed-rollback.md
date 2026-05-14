# Caso DBA: DBCC CHECKDB PHYSICAL_ONLY en KILLED/ROLLBACK

## Resumen

Caso documentado para SQL Server donde un `DBCC CHECKDB ... WITH PHYSICAL_ONLY` quedo durante muchas horas sin avance visible, con espera `EXECSYNC`, sin bloqueador externo y con archivos fisicos internos tipo `_MSSQL_DBCC...` en el volumen de datos.

Este runbook ordena las validaciones futuras para evitar borrar archivos internos mientras SQL Server aun los utiliza.

## Sintomas

- Archivos en disco con sufijo `_MSSQL_DBCC...`.
- Sesion con comando `DBCC TABLE CHECK` o texto `DBCC CHECKDB`.
- Estado `suspended` o `KILLED/ROLLBACK`.
- Espera `EXECSYNC`.
- `blocking_session_id = 0`.
- `percent_complete` sin avance por largo tiempo.

## Interpretacion

Los archivos `_MSSQL_DBCC...` son archivos internos asociados a la snapshot usada por DBCC. No deben moverse ni eliminarse mientras exista una sesion DBCC activa o en rollback.

La espera `EXECSYNC` puede corresponder a sincronizacion interna de workers paralelos. Si el proceso no avanza por horas o dias, debe tratarse como incidente operacional y evaluarse cancelacion controlada en ventana baja.

## Orden de validacion

1. Detectar la sesion DBCC activa o en rollback.
2. Confirmar si hay sesiones bloqueadas por el SPID afectado.
3. Revisar snapshots y archivos DBCC registrados por SQL Server.
4. Revisar errorlog buscando DBCC, CHECKDB y CHECKTABLE.
5. Si se decide cancelar, hacerlo una sola vez y monitorear rollback.
6. No tocar archivos `_MSSQL_DBCC...` mientras el SPID siga visible.
7. Cuando el SPID desaparezca, confirmar que SQL Server no registre esos archivos.
8. Si quedan archivos fisicos residuales, mover primero a cuarentena y eliminar solo despues de validacion.

## Scripts relacionados

- `sqlserver/maintenance/dbcc/01_detectar_dbcc_activo.sql`
- `sqlserver/maintenance/dbcc/02_validar_bloqueo_impacto.sql`
- `sqlserver/maintenance/dbcc/03_validar_snapshots_y_archivos_dbcc.sql`
- `sqlserver/maintenance/dbcc/04_revisar_errorlog_dbcc.sql`
- `sqlserver/maintenance/dbcc/05_monitorear_rollback_dbcc.sql`
- `sqlserver/maintenance/dbcc/06_validacion_post_limpieza.sql`
- `sqlserver/maintenance/dbcc/07_job_checkdb_physical_only_ao.sql`

## Recomendacion de mantenimiento

Para bases grandes en produccion:

- Ejecutar `PHYSICAL_ONLY` semanal en ventana baja.
- Ejecutar CHECKDB completo mensual o segun criticidad, idealmente en backup restaurado o replica secundaria.
- Evitar CHECKDB completo diario sobre primario productivo.
- Usar MAXDOP controlado.
- En Always On, validar rol PRIMARY antes de ejecutar si corresponde.

## Cierre del caso

El caso se considera cerrado cuando el SPID desaparece, no hay sesiones bloqueadas por el SPID, no hay snapshots activas asociadas y SQL Server no registra archivos `_MSSQL_DBCC...` en metadata.
