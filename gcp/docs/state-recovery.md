# Recuperación del Estado de Terraform

Este documento explica cómo recuperar el estado de Terraform cuando se pierde o cuando necesitas trabajar en un nuevo entorno.

## 🔄 Recuperación Automática (Módulos con Backend)

### ¿Qué es un Backend?

Un backend es la configuración que le dice a Terraform dónde almacenar el estado. En este proyecto, la mayoría de módulos usan **GCS (Google Cloud Storage)** como backend.

### Proceso Automático

**Cuando ejecutas `terraform init` en un módulo con backend:**

1. Terraform lee la configuración del backend (ej: `backend.tf`)
2. Se conecta al bucket de GCS especificado
3. **Descarga automáticamente el estado remoto** desde el bucket
4. Lo guarda en caché local (`.terraform/terraform.tfstate`)

**Ejemplo:**

```bash
cd terraform-state/environments/staging

# Si perdiste el .tfstate local, simplemente ejecuta:
terraform init

# ✅ Terraform automáticamente descarga el estado desde:
# gs://[bucket_name]/stg/default.tfstate
```

### Módulos con Backend en este Proyecto

| Módulo                                     | Backend Configurado | Recuperación  |
| ------------------------------------------ | ------------------- | ------------- |
| `shared-infra/environments/development`    | ✅ Sí               | ✅ Automática |
| `shared-infra/environments/qa`             | ✅ Sí               | ✅ Automática |
| `shared-infra/environments/staging`        | ✅ Sí               | ✅ Automática |
| `shared-infra/environments/production`     | ✅ Sí               | ✅ Automática |
| `terraform-state/environments/development` | ✅ Sí               | ✅ Automática |
| `terraform-state/environments/qa`          | ✅ Sí               | ✅ Automática |
| `terraform-state/environments/staging`     | ✅ Sí               | ✅ Automática |
| `terraform-state/environments/production`  | ✅ Sí               | ✅ Automática |

**Nota**: Los buckets y prefijos específicos están configurados en el `main.tf` o `backend.tf` de cada módulo. Revisa esos archivos para ver la configuración exacta.

**Todos estos módulos recuperan automáticamente el estado al hacer `terraform init`.**

---

## ❌ Módulo Sin Backend (global)

### El Problema

El módulo `terraform-state/global` es especial:

- ❌ **NO tiene backend configurado** (porque crea el bucket que otros usan)
- ❌ Si pierdes el `.tfstate` local, **NO se recupera automáticamente**
- ⚠️ Necesitas importar manualmente los recursos desde GCP

### Solución: `make recover-global`

Usa el comando `make recover-global` para importar el recurso desde GCP:

```bash
# Asegúrate de tener un archivo .env con:
# - PROJECT_ID
# - BUCKET_NAME (o BUCKET_PREFIX)
# - REGION (opcional, default: us-central1)

make recover-global
```

Este comando:

1. ✅ Carga las variables del archivo `.env`
2. ✅ Verifica si el bucket existe en GCP
3. ✅ Si existe, importa el recurso al estado
4. ✅ Si no existe, muestra un mensaje claro indicando que no existe

### Método Manual

Si prefieres hacerlo manualmente:

```bash
cd terraform-state/global

# 1. Verificar que el bucket existe (reemplaza BUCKET-NAME con el nombre real)
gcloud storage buckets describe gs://BUCKET-NAME \
  --project=TU-PROYECTO-ID

# 2. Inicializar Terraform (sin backend)
terraform init -backend=false

# 3. Importar el recurso existente (reemplaza BUCKET-NAME con el nombre real)
terraform import \
  'module.terraform_state_bucket.google_storage_bucket.bucket_protected[0]' \
  BUCKET-NAME

# 4. Verificar el estado
terraform state list
terraform plan
```

---

## 🔍 Comparación

| Aspecto                      | Con Backend                      | Sin Backend (global)            |
| ---------------------------- | -------------------------------- | ------------------------------- |
| **Recuperación automática**  | ✅ Sí (`terraform init`)         | ❌ No                           |
| **Dónde está el estado**     | Bucket GCS remoto                | Solo local (`.tfstate`)         |
| **Si pierdes el `.tfstate`** | Se recupera con `terraform init` | Necesitas `make recover-global` |
| **Comando de recuperación**  | `terraform init`                 | `make recover-global`           |

---

## 📝 Ejemplos Prácticos

### Caso 1: Recuperar Estado con Backend

```bash
# Escenario: Perdiste el .tfstate local

cd shared-infra/environments/development

# 1. Simplemente ejecuta terraform init
terraform init

# ✅ Terraform automáticamente descarga el estado desde el bucket GCS configurado

# 2. Verifica que el estado se recuperó
terraform state list

# 3. Ya puedes usar terraform plan/apply normalmente
terraform plan
```

### Caso 2: Recuperar Estado SIN Backend (global)

```bash
# Escenario: Perdiste el .tfstate local de global

cd terraform-state/global

# ❌ terraform init NO recupera el estado (no hay backend)
terraform init  # Esto solo inicializa, no descarga estado

# ✅ Usa el comando make para importar desde GCP
cd ../..
make recover-global

# O manualmente (reemplaza BUCKET-NAME con el nombre real):
cd terraform-state/global
terraform init -backend=false
terraform import \
  'module.terraform_state_bucket.google_storage_bucket.bucket_protected[0]' \
  BUCKET-NAME
```

---

## 🔒 Prevención: Configurar Backend para Global

Aunque `global` es la raíz, **recomendamos configurar un backend** para evitar perder el estado:

### Opción 1: Usar un Bucket Separado (Recomendado)

Crea un bucket manualmente en GCP para el estado de `global`:

```bash
# Crear bucket manualmente (reemplaza con tus valores)
gsutil mb -p TU-PROYECTO-ID -l us-central1 gs://TU-PROYECTO-terraform-state-global
```

Luego configura el backend en `terraform-state/global/backend.tf`:

```hcl
terraform {
  backend "gcs" {
    bucket = "TU-PROYECTO-terraform-state-global"
    prefix = "global"
  }
}
```

### Opción 2: Usar el Mismo Bucket con Prefijo Diferente

Si ya tienes un bucket de estado, puedes usarlo con un prefijo diferente:

```hcl
terraform {
  backend "gcs" {
    bucket = "TU-PROYECTO-terraform-state"
    prefix = "global-state"  # Prefijo diferente a otros ambientes
  }
}
```

**⚠️ IMPORTANTE**: Para esta opción, el bucket debe existir ANTES de configurar el backend. Si es el mismo bucket que crea `global`, tendrás un problema de dependencia circular.

---

## 🎯 Mejores Prácticas

1. **Usa backend siempre que sea posible**

   - ✅ Protege contra pérdida de estado
   - ✅ Permite trabajo en equipo
   - ✅ Historial de cambios

2. **Para el módulo `global`:**

   - ✅ **Corto plazo**: Usa `make recover-global` si pierdes el estado
   - ✅ **Largo plazo**: Configura un backend usando un bucket separado

3. **Backup adicional:**
   - Considera habilitar versioning en los buckets de estado
   - Mantén backups periódicos del estado (especialmente para producción)

---

## 📚 Referencias

- [Terraform Backends](https://www.terraform.io/docs/language/settings/backends/index.html)
- [GCS Backend Configuration](https://www.terraform.io/docs/language/settings/backends/gcs.html)
- [Terraform Import](https://www.terraform.io/docs/cli/import/index.html)
