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

1. Ejecutar scripts de diagnóstico
2. Analizar resultados
3. Validar estado de la base
4. Ejecutar acciones (shrink solo si aplica)
5. Validar resultados

## Advertencia

No usar shrink como mantenimiento rutinario.