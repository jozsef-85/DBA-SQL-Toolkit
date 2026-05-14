/*
    Script: 04_backup_log.sql
    Uso:
        Plantilla para backup manual de transaction log durante incidentes.
        Reemplazar NOMBRE_DB y validar ruta de destino antes de ejecutar.

    Importante:
        Usar solo en bases con recovery model FULL o BULK_LOGGED.
        Confirmar politica de respaldos antes de ejecutar fuera de rutina.
*/

BACKUP LOG [NOMBRE_DB]
TO DISK = 'K:\SQL_BACKUP\MANUAL\NOMBRE_DB.trn'
WITH COMPRESSION, CHECKSUM, STATS = 10;
