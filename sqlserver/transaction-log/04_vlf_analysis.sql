/*
    Script: 04_vlf_analysis.sql
    Proposito:
        Cuenta VLF activos e inactivos por base.

    Cuando usar:
        Util despues de corregir crecimiento historico del log.
        Tambien sirve antes de normalizar autogrowth para conocer el estado actual.

    Como usar:
        Ejecutar a nivel de instancia.

    Requisito:
        sys.dm_db_log_info esta disponible desde SQL Server 2016 SP2.

    Siguiente paso:
        Si hay muchos VLF o crecimiento irregular, revisar autogrowth con
        sqlserver/transaction-log/08_set_autogrowth.sql como plantilla.
*/

SELECT
    DB_NAME(database_id) AS database_name,
    COUNT(*) AS total_vlf,
    SUM(CASE WHEN vlf_active = 1 THEN 1 ELSE 0 END) AS vlf_activos,
    SUM(CASE WHEN vlf_active = 0 THEN 1 ELSE 0 END) AS vlf_inactivos
FROM sys.dm_db_log_info(NULL)
GROUP BY database_id
ORDER BY total_vlf DESC;
