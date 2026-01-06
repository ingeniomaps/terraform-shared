# Verificación de Backends de Terraform

Este documento describe la configuración de backends de Terraform en el proyecto.

## Backends Configurados

### 1. Shared Infrastructure - Development
**Archivo**: `shared-infra/environments/development/main.tf`

```hcl
backend "gcs" {
  bucket = "roax-terraform-state-stg"
  prefix = "dev/shared/terraform"
}
```

**Estado**: ✅ Configurado
**Bucket**: `roax-terraform-state-stg`
**Prefijo**: `dev/shared/terraform`

### 2. Terraform State - Development
**Archivo**: `terraform-state/environments/development/backend.tf`

```hcl
backend "gcs" {
  bucket = "roax-terraform-state"
  prefix = "dev"
}
```

**Estado**: ✅ Configurado
**Bucket**: `roax-terraform-state`
**Prefijo**: `dev`

### 3. Terraform State - QA
**Archivo**: `terraform-state/environments/qa/backend.tf`

```hcl
backend "gcs" {
  bucket = "roax-terraform-state"
  prefix = "qa"
}
```

**Estado**: ✅ Configurado
**Bucket**: `roax-terraform-state`
**Prefijo**: `qa`

### 4. Terraform State - Staging
**Archivo**: `terraform-state/environments/staging/backend.tf`

```hcl
backend "gcs" {
  bucket = "roax-terraform-state"
  prefix = "stg"
}
```

**Estado**: ✅ Configurado
**Bucket**: `roax-terraform-state`
**Prefijo**: `stg`

### 5. Terraform State - Production
**Archivo**: `terraform-state/environments/production/backend.tf`

```hcl
backend "gcs" {
  bucket = "roax-terraform-state"
  prefix = "prod"
}
```

**Estado**: ✅ Configurado
**Bucket**: `roax-terraform-state`
**Prefijo**: `prod`

## Verificación de Buckets

Antes de usar estos backends, asegúrate de que los buckets existan:

### Buckets Requeridos

1. **`roax-terraform-state-stg`**
   - Usado por: `shared-infra/environments/development`
   - Debe existir antes de ejecutar `terraform init` en development

2. **`roax-terraform-state`**
   - Usado por: `terraform-state/environments/development`, `terraform-state/environments/qa`, `terraform-state/environments/staging` y `terraform-state/environments/production`
   - Debe existir antes de usar los backends de development, qa, staging y production

### Crear Buckets si no Existen

Si los buckets no existen, créalos usando el módulo `terraform-state/global`:

```bash
cd terraform-state/global
terraform init
terraform plan
terraform apply
```

Luego crea los buckets específicos para staging y production si es necesario.

## 🔄 Recuperación Automática del Estado

**IMPORTANTE**: Cuando un módulo tiene backend configurado, Terraform **recupera automáticamente** el estado al ejecutar `terraform init`.

### Proceso Automático

```bash
cd terraform-state/environments/staging

# Si pierdes el .tfstate local, simplemente ejecuta:
terraform init

# ✅ Terraform automáticamente descarga el estado desde:
# gs://roax-terraform-state/stg/default.tfstate
```

Esto aplica a todos los módulos con backend configurado:
- ✅ `shared-infra/environments/development`
- ✅ `terraform-state/environments/development`
- ✅ `terraform-state/environments/qa`
- ✅ `terraform-state/environments/staging`
- ✅ `terraform-state/environments/production`

**⚠️ EXCEPCIÓN**: El módulo `terraform-state/global` NO tiene backend. Si pierdes su estado, usa `make recover-global`. Ver [state-recovery.md](state-recovery.md) para más detalles.

## Notas Importantes

⚠️ **IMPORTANTE**:
- Los buckets deben existir ANTES de configurar el backend
- Si cambias la configuración del backend, necesitarás migrar el estado:
  ```bash
  terraform init -migrate-state
  ```
- Los buckets de producción tienen `prevent_destroy = true` para evitar destrucciones accidentales
- Los buckets de producción tienen `retention_policy` configurada (90 días, bloqueada)

## Orden de Creación

1. Crear bucket global (si aplica)
2. Crear buckets de estado para development/staging/production
3. Configurar backends en los archivos correspondientes
4. Ejecutar `terraform init` en cada directorio

## Configuración por Ambiente

| Ambiente | Bucket | Prefijo Backend | `prevent_destroy` | `retention_period_days` | `retention_locked` |
|----------|--------|-----------------|-------------------|-------------------------|-------------------|
| **Development** | `${bucket_prefix}-dev` | `dev` | `false` | 7 días | `false` |
| **QA** | `${bucket_prefix}-qa` | `qa` | `false` | 7 días | `false` |
| **Staging** | `${bucket_prefix}-stg` | `stg` | `false` | 30 días | `false` |
| **Production** | `${bucket_prefix}-prod` | `prod` | `true` | 90 días | `true` |

**Nota**: Development y QA tienen la configuración más permisiva (pueden ser destruidos, menor retención) mientras que Production tiene la máxima protección. QA es similar a Development y se usa principalmente para pruebas automatizadas.
