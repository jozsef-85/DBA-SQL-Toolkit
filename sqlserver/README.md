# SQL Server Scripts

Scripts T-SQL organizados por dominio operativo DBA.

## Categorias

- `capacity/`: tamanos de base, espacio usado real, espacio por volumen y FILEGROWTH.
- `transaction-log/`: uso del log, reutilizacion, VLF, backups manuales, shrink controlado y autogrowth.
- `performance/`: waits, sesiones activas, conexiones, memoria e I/O por intervalo.
- `blocking/`: sesiones bloqueadas, bloqueadores, locks y transacciones abiertas.
- `alwayson/`: validaciones de Availability Groups.
- `maintenance/`: acciones operativas controladas que requieren validacion previa.
- `maintenance/dbcc/`: diagnostico, monitoreo y operacion CHECKDB/DBCC.

## Regla practica

Primero diagnosticar, luego confirmar alcance, despues operar. Los scripts numerados mantienen ese orden dentro de cada categoria.
