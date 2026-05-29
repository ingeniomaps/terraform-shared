# Documentación del Proyecto

Esta carpeta contiene la documentación técnica del proyecto Terraform GCP.

## Índice

- [**seguridad-pendientes.md**](seguridad-pendientes.md) - Backlog de seguridad

  - Hardening ya aplicado y pendientes que requieren decisión/datos del equipo
  - Postura de prod (org-policies/VPC-SC), egress, alertas, supply chain, CI gate
  - Notas de migración de estado para consumidores ya aplicados

- [**credentials.md**](credentials.md) - Gestión de credenciales de GCP

  - Cómo obtener credenciales (Service Account, Secret Manager, gcloud)
  - Configuración de variables de entorno
  - Buenas prácticas de seguridad

- [**backends.md**](backends.md) - Configuración de backends de Terraform

  - Backends configurados por ambiente
  - Buckets requeridos
  - Orden de creación
  - Migración de estado

- [**versions.md**](versions.md) - Gestión de versiones

  - Versiones actuales de Terraform y providers
  - Verificación automática con `make check-versions`
  - Proceso de actualización
  - Recomendaciones de versionado

- [**validation.md**](validation.md) - Validación y testing

  - Comandos de validación
  - Checklist pre-commit y pre-deploy
  - Mejoras futuras

- [**environments.md**](environments.md) - Gestión de entornos

  - Entornos existentes
  - Crear entornos adicionales
  - Diferencias entre entornos
  - Estructura recomendada

- [**reutilizacion.md**](reutilizacion.md) - Guía de reutilización del proyecto

  - Variables clave por categoría
  - Archivos a modificar
  - Proceso paso a paso
  - Ejemplos completos
  - Checklist de reutilización

- [**casos-de-uso.md**](casos-de-uso.md) - Todos los casos de uso del proyecto

  - Casos por tipo de infraestructura (VMs, GKE)
  - Casos por seguridad (público, restringido, VPC Service Controls)
  - Casos por conectividad (VPC Peering)
  - Casos por ambiente (dev, staging, prod)
  - Casos combinados y especiales
  - Matriz de casos de uso
  - Guía rápida de selección

- [**outputs.md**](outputs.md) - Gestión de outputs

  - Diferencia entre outputs.tf y plan.out
  - Qué incluir en el repositorio
  - Mejores prácticas

- [**state-recovery.md**](state-recovery.md) - Recuperación del estado de Terraform

  - Recuperación automática con backend configurado

- [**testing.md**](testing.md) - Testing y validación automatizada

  - Suite completa de tests (formato, validación, linting, seguridad)
  - Comandos `make test*` disponibles
  - Integración en CI/CD
  - Troubleshooting

- [**pre-commit.md**](pre-commit.md) - Pre-commit hooks para calidad de código

  - Configuración de hooks automáticos
  - Prevención de commits de archivos sensibles
  - Formato y validación automática
  - Detección de secretos

## Documentación Principal

Para información general del proyecto, ver [README.md](../README.md) en la raíz del proyecto.
