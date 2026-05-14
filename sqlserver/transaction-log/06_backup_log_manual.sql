/*
    Script: 06_backup_log_manual.sql
    Proposito:
        Plantilla para backup manual de transaction log durante incidentes.

    Cuando usar:
        Solo si el recovery model es FULL o BULK_LOGGED y el incidente
        requiere truncar log mediante backup fuera de la rutina normal.

    Como usar:
        1. Confirmar recovery_model_desc y log_reuse_wait_desc con
           sqlserver/transaction-log/03_log_space_and_reuse.sql.
        2. Reemplazar NOMBRE_DB.
        3. Validar ruta de destino y espacio disponible.
        4. Ejecutar y validar resultado con sqlserver/transaction-log/05_monitor_log.sql.

    Precauciones:
        Usar solo en bases con recovery model FULL o BULK_LOGGED.
        Confirmar politica de respaldos antes de ejecutar fuera de rutina.
*/

BACKUP LOG [NOMBRE_DB]
TO DISK = 'K:\SQL_BACKUP\MANUAL\NOMBRE_DB.trn'
WITH COMPRESSION, CHECKSUM, STATS = 10;
