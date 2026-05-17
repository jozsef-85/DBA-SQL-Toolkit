# Nota operativa: Error 1478 en SQL Server Database Mirroring

## Resumen

El error 1478 durante `SET PARTNER` indica que la base mirror no tiene restaurado el log transaccional suficiente para conservar la cadena de log del principal.

No corresponde diagnosticar primero certificados, endpoints ni firewall si esos elementos ya fueron validados. La causa esta en la preparacion de la base mirror.

## Regla de correccion

Usar siempre una cadena limpia:

```text
FULL nuevo
LOG nuevo posterior al FULL
Restaurar FULL con NORECOVERY
Restaurar LOG con NORECOVERY
Ejecutar SET PARTNER primero en el mirror
Ejecutar SET PARTNER despues en el principal
```

## Reglas para evitar repetir el problema

- No reutilizar archivos de backup de intentos anteriores.
- No mezclar un FULL nuevo con un TRN viejo.
- No ejecutar SET PARTNER si el mirror no esta en RESTORING.
- No ejecutar PARTNER OFF si `sys.database_mirroring` ya aparece sin configuracion.

## Archivo relacionado

El procedimiento endurecido queda en:

```text
sqlserver/mirroring/05_prepare_database_full_and_restore_norecovery.sql
```
