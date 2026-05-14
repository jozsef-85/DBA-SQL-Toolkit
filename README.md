# DBA-SQL-Toolkit

Repositorio personal de scripts T-SQL para diagnóstico, troubleshooting y operación en SQL Server.

## Escenario de uso

Scripts utilizados en un caso de análisis de capacidad en entorno controlado (preproductivo), enfocado en:

- Sobredimensionamiento de archivos MDF/NDF
- Validación de uso real de espacio
- Análisis de Transaction Log (TLOG)
- Revisión de espacio por volumen
- Ajuste de FILEGROWTH
- Ejecución controlada de shrink
- Validación de rol en Always On AG

> No se incluyen nombres reales de bases de datos ni clientes.

## Objetivo

- Tener scripts reutilizables para análisis rápido
- Evitar crecimiento descontrolado de archivos
- Mejorar prácticas operativas DBA

## Uso

1. Ejecutar primero scripts de diagnostico.
2. Analizar resultados y confirmar base, archivo, replica o sesion afectada.
3. Ejecutar acciones operativas solo si aplica.
4. Validar resultados despues de cada cambio.

## Estructura

- `sqlserver/capacity-and-log/`: diagnostico de capacidad, archivos, volumenes, FILEGROWTH, shrink controlado y Always On AG.
- `sqlserver/troubleshooting/input/`: waits, sesiones activas e I/O por intervalo.
- `sqlserver/troubleshooting/transactions/`: bloqueo, locks, sesiones bloqueantes y transacciones abiertas.
- `transaction-log/`: plantillas rapidas para inventario, monitoreo y operacion del transaction log.
- `docs/`: casos y notas operativas.

Los scripts numerados representan el orden sugerido de accion dentro de cada carpeta. La idea es partir por diagnostico amplio, confirmar el origen del problema y recien despues ejecutar acciones operativas.

## Runbooks principales

- Capacidad y log: `sqlserver/capacity-and-log/01_*` a `07_*`.
- Transaction log operativo: `transaction-log/01_*` a `07_*`.
- Lentitud, I/O o carga alta: `sqlserver/troubleshooting/input/01_*` a `04_*`.
- Bloqueos y transacciones: `sqlserver/troubleshooting/transactions/01_*` a `05_*`.

## Criterio de ejecucion

- Scripts de diagnostico: solo lectura, pensados para correr durante analisis.
- Scripts operativos: pueden ejecutar `BACKUP LOG`, `ALTER DATABASE` o `DBCC SHRINKFILE`; revisar placeholders antes de correr.
- Scripts con `@session_id`: dejar `NULL` para revisar el escenario activo cuando aplique, o definir un SPID obtenido desde `sesionesbloqueadas.sql`.

## Advertencia

No usar shrink como mantenimiento rutinario.
Validar siempre recovery model, backups, espacio libre, rol PRIMARY en AG y ventana operacional antes de ejecutar acciones.
