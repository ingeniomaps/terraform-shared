# Configuración de Backends de Terraform

Este documento describe la configuración de backends de Terraform en el proyecto.

## 📋 Estructura de Backends

Cada ambiente tiene su propio backend configurado en `main.tf` o `backend.tf`:

### Shared Infrastructure

- **Development**: `shared-infra/environments/development/main.tf`
- **QA**: `shared-infra/environments/qa/main.tf`
- **Staging**: `shared-infra/environments/staging/main.tf`
- **Production**: `shared-infra/environments/production/main.tf`

### Terraform State Buckets

- **Development**: `terraform-state/environments/development/`
- **QA**: `terraform-state/environments/qa/`
- **Staging**: `terraform-state/environments/staging/`
- **Production**: `terraform-state/environments/production/`

## 🔧 Configuración Típica

Cada backend sigue este patrón:

```hcl
terraform {
  backend "gcs" {
    bucket = "TU-PROYECTO-terraform-state-{env}"
    prefix = "{env}/shared/terraform"  # Para shared-infra
    # o
    prefix = "{env}"  # Para terraform-state
  }
}
```

**Nota**: Los nombres de buckets y prefijos son específicos de cada proyecto. Revisa los archivos `main.tf` de cada ambiente para ver la configuración exacta.

### Crear Buckets si no Existen

Si los buckets no existen, créalos usando el módulo `terraform-state/global`:

```bash
cd terraform-state/global
terraform init
terraform plan
terraform apply
```

Luego crea los buckets específicos para cada ambiente si es necesario.

## 🔄 Recuperación Automática del Estado

**IMPORTANTE**: Cuando un módulo tiene backend configurado, Terraform **recupera automáticamente** el estado al ejecutar `terraform init`.

### Proceso Automático

```bash
cd shared-infra/environments/development

# Si pierdes el .tfstate local, simplemente ejecuta:
terraform init

# ✅ Terraform automáticamente descarga el estado desde el bucket GCS configurado
```

Esto aplica a todos los módulos con backend configurado. Ver [state-recovery.md](state-recovery.md) para más detalles sobre recuperación de estado.

## ⚠️ Notas Importantes

- Los buckets deben existir **ANTES** de configurar el backend
- Si cambias la configuración del backend, necesitarás migrar el estado:
  ```bash
  terraform init -migrate-state
  ```
- Los buckets de producción tienen `prevent_destroy = true` para evitar destrucciones accidentales
- Los buckets de producción tienen `retention_policy` configurada (90 días, bloqueada)

## 📝 Orden de Creación

1. Crear bucket global (si aplica)
2. Crear buckets de estado para cada ambiente
3. Configurar backends en los archivos correspondientes
4. Ejecutar `terraform init` en cada directorio

## 🔍 Verificar Backends Configurados

Para ver qué backends están configurados en tu proyecto:

```bash
# Buscar configuraciones de backend
grep -r "backend \"gcs\"" shared-infra/environments/ terraform-state/environments/
```

Esto mostrará todos los backends configurados con sus buckets y prefijos específicos.
