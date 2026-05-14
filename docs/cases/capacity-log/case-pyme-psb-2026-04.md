# Caso: Sobredimensionamiento y gestión de Transaction Log

## Contexto
Ambiente SQL Server 2022 con migración desde SQL Server 2014.

## Problemas detectados

- Jobs de backup FULL y TLOG detenidos
- Estado LOG_BACKUP en múltiples bases
- Transaction logs sobredimensionados
- Uso real < 2% en logs grandes
- VLF elevados por crecimiento histórico
- Autogrowth inconsistente (%, 50MB, 100MB)

## Diagnóstico

- El crecimiento del log no correspondía a carga real
- Se debía a falta de truncamiento (backup log)
- Uso de shrink como práctica incorrecta

## Acciones realizadas

1. Reactivación de jobs de backup
2. Validación de truncamiento (`NOTHING`)
3. Backup manual de log en incidentes
4. Shrink controlado de logs sobredimensionados
5. Ajuste de autogrowth a valores fijos (MB)
6. Eliminación de shrink recurrente

## Resultado

- Logs estables
- Truncamiento funcionando
- Reducción de tamaño (ej: 49GB → 20GB)
- Mejora en estructura de VLF
- Ambiente sin riesgo operativo

## Lección clave

El tamaño del transaction log es un problema de **operación**, no de negocio.