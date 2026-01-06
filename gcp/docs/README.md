# Documentación del Proyecto

Esta carpeta contiene la documentación técnica del proyecto Terraform GCP.

## Índice

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
  - Recuperación manual del módulo global
  - Diferencia entre módulos con/sin backend
  - Ejemplos prácticos y mejores prácticas

## Documentación Principal

Para información general del proyecto, ver [README.md](../README.md) en la raíz del proyecto.
