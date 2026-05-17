# Database Mirroring - Renovacion de certificados

Categoria para diagnosticar, preparar y ejecutar la renovacion controlada de certificados usados por `DATABASE_MIRRORING ENDPOINT` en SQL Server.

## Objetivo

- Validar que certificado usa actualmente el endpoint de mirroring.
- Identificar certificados locales con llave privada y certificados publicos remotos.
- Preparar nuevos certificados sin modificar el endpoint antes de la ventana.
- Cambiar el endpoint al certificado nuevo de forma controlada.
- Validar estado posterior de mirroring.
- Mantener reversa temporal y dejar la limpieza como actividad posterior.

## Alcance

Aplica a ambientes SQL Server con Database Mirroring y autenticacion por certificado:

```text
AUTHENTICATION = CERTIFICATE
ENCRYPTION = REQUIRED ALGORITHM AES
```

Tambien aplica a servidores witness/partner que no cambian su certificado local, pero que deben tener importados los certificados publicos nuevos de los servidores que si se renuevan.

## Orden sugerido

1. `01_precheck_consolidado_certificados_mirroring.sql`
2. `02_create_and_export_local_certificates.sql`
3. `03_import_remote_public_certificates.sql`
4. `04_switch_endpoint_to_new_certificate.sql`
5. `05_postcheck_validate_mirroring.sql`
6. `06_rollback_endpoint_previous_certificate.sql`
7. `07_optional_cleanup_old_certificates.sql`

## Reglas de seguridad operacional

- No cambiar a `AUTHENTICATION = WINDOWS NEGOTIATE` si el ambiente opera con certificados.
- No ejecutar `DROP CERTIFICATE` durante la ventana principal de renovacion.
- No modificar el endpoint de un witness/partner cuyo certificado local aun esta vigente y no forma parte del cambio.
- Ejecutar `ALTER ENDPOINT` por instancia, no de forma masiva.
- Mantener certificados antiguos hasta validar estabilidad.

## Evidencias recomendadas

- Certificado usado por endpoint antes y despues.
- Certificados existentes en `master` antes y despues.
- Permisos `CONNECT` sobre endpoint.
- Estado de mirroring antes y despues.
- Errorlog sin errores de `certificate`, `endpoint` o `mirroring`.
