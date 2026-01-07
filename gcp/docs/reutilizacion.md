# Guía de Reutilización del Proyecto

Esta guía explica cómo reutilizar este proyecto de Terraform para diferentes proyectos GCP, workspaces y ambientes.

## 🚀 Método Rápido (Recomendado)

### Configuración Automática con .env

El método más fácil es usar el script de configuración automática:

```bash
# 1. Copiar plantilla de .env
cp .env.example .env

# 2. Editar .env con tus valores
nano .env  # o tu editor preferido

# 3. Ver cambios sin aplicarlos (opcional)
make setup-dry-run

# 4. Aplicar configuración
make setup
```

El script automáticamente:

- ✅ Reemplaza `project_id` en todos los archivos
- ✅ Reemplaza `workspace` en todos los archivos
- ✅ Reemplaza `organization_id` y `allowed_domains`
- ✅ Actualiza nombres de buckets y registries
- ✅ Configura backends correctamente

**Ver sección [Configuración Automática](#configuración-automática-con-env) para más detalles.**

---

## 📋 Método Manual

Para reutilizar el proyecto manualmente en un nuevo proyecto/workspace, necesitas modificar:

1. **Variables de contexto** (project_id, workspace, organization_id)
2. **Configuración de backends** (nombres de buckets)
3. **Grupos IAM y dominios** (específicos de tu organización)
4. **Nombres de recursos** (registry, buckets, etc.)

---

## 🎯 Variables Clave por Categoría

### Variables de Contexto (Obligatorias)

Estas variables identifican tu proyecto y workspace:

| Variable     | Descripción               | Archivo                                        | Ejemplo                           |
| ------------ | ------------------------- | ---------------------------------------------- | --------------------------------- |
| `project_id` | ID del proyecto GCP       | `shared-infra/environments/*/terraform.tfvars` | `"mi-proyecto-dev-123456"`        |
| `workspace`  | Nombre del workspace      | `shared-infra/environments/*/terraform.tfvars` | `"platform"`, `"analytics"`, etc. |
| `env`        | Ambiente (dev, stg, prod) | `shared-infra/environments/*/terraform.tfvars` | `"dev"`, `"stg"`, `"prod"`        |
| `region`     | Región de GCP             | `shared-infra/environments/*/terraform.tfvars` | `"us-central1"`                   |

### Variables de Organización (Obligatorias)

Específicas de tu organización GCP:

| Variable          | Descripción                  | Archivo                                        | Ejemplo             |
| ----------------- | ---------------------------- | ---------------------------------------------- | ------------------- |
| `organization_id` | ID de la organización GCP    | `shared-infra/environments/*/terraform.tfvars` | `"123456789012"`    |
| `allowed_domains` | Dominios permitidos para IAM | `shared-infra/environments/*/terraform.tfvars` | `["miempresa.com"]` |
| `admin_groups`    | Grupos de administradores    | `shared-infra/environments/*/terraform.tfvars` | Ver ejemplo abajo   |

### Variables de Recursos (Opcionales pero Recomendadas)

Nombres de recursos que deberías personalizar:

| Variable        | Descripción                    | Archivo                                           | Ejemplo                         |
| --------------- | ------------------------------ | ------------------------------------------------- | ------------------------------- |
| `registry_name` | Nombre del Artifact Registry   | `shared-infra/environments/*/terraform.tfvars`    | `"docker-images-dev"`           |
| `bucket_prefix` | Prefijo para buckets de estado | `terraform-state/environments/*/terraform.tfvars` | `"mi-proyecto-terraform-state"` |

---

## 📁 Archivos a Modificar

### 1. Shared Infrastructure

#### `shared-infra/environments/<env>/main.tf`

**Modificar: Backend configuration**

```hcl
backend "gcs" {
  bucket = "TU-PROYECTO-terraform-state-stg"  # ← Cambiar aquí
  prefix = "dev/shared/terraform"              # ← Opcional: cambiar prefix
}
```

**Valores específicos del proyecto:**

- `bucket`: Nombre del bucket de estado (debe existir o crearse primero)
- `prefix`: Prefijo dentro del bucket (puede incluir workspace: `"${workspace}/shared/terraform"`)

#### `shared-infra/environments/<env>/terraform.tfvars`

**Modificar: Todas las variables de contexto y organización**

```hcl
# Contexto
project_id = "mi-nuevo-proyecto-dev-123456"  # ← Cambiar
workspace   = "mi-workspace"                  # ← Cambiar
region      = "us-central1"                   # ← Cambiar si necesario
env         = "dev"                           # ← Cambiar según ambiente

# Organización
organization_id = "123456789012"              # ← Cambiar
allowed_domains = ["miempresa.com"]           # ← Cambiar

admin_groups = {
  network_admins  = "network-admins@miempresa.com"    # ← Cambiar
  network_viewers = "developers@miempresa.com"         # ← Cambiar
  security_admins = "security-admins@miempresa.com"    # ← Cambiar
  auditors        = "auditors@miempresa.com"            # ← Cambiar
}

# Recursos
registry_name = "docker-images-dev"           # ← Cambiar
```

### 2. Terraform State Buckets

#### `terraform-state/environments/<env>/main.tf`

**Modificar: Nombre del bucket**

```hcl
module "terraform_state_bucket" {
  source      = "../../modules/gcs_bucket"
  bucket_name = "${var.bucket_prefix}-${var.env}"  # ← Se construye desde variables
  # ...
}
```

#### `terraform-state/environments/<env>/terraform.tfvars`

**Modificar: Variables del bucket**

```hcl
project_id   = "mi-proyecto-terraform-123456"  # ← Cambiar
bucket_prefix = "mi-proyecto-terraform-state"  # ← Cambiar
region       = "us-central1"                    # ← Cambiar si necesario
env          = "stg"                            # ← Cambiar según ambiente
```

#### `terraform-state/environments/<env>/backend.tf`

**Modificar: Backend configuration (si aplica)**

```hcl
terraform {
  backend "gcs" {
    bucket = "mi-proyecto-terraform-state"  # ← Cambiar
    prefix = "stg"                          # ← Cambiar según ambiente
  }
}
```

### 3. Global State Bucket

#### `terraform-state/global/main.tf`

**Modificar: Nombre del bucket global**

```hcl
module "terraform_state_bucket" {
  source      = "../../modules/gcs_bucket"
  bucket_name = "${var.bucket_prefix}-global"  # ← Se construye desde variables
  # ...
}
```

#### `terraform-state/global/terraform.tfvars`

**Modificar: Variables del bucket global**

```hcl
project_id   = "mi-proyecto-terraform-123456"  # ← Cambiar
bucket_prefix = "mi-proyecto-terraform-state"  # ← Cambiar
region       = "us-central1"                    # ← Cambiar si necesario
```

---

## 🔄 Proceso de Reutilización Paso a Paso

### Paso 1: Preparar Backends

Antes de usar la infraestructura compartida, crea los buckets de estado:

```bash
# 1. Configurar variables en terraform-state/global/terraform.tfvars
cd terraform-state/global
# Editar terraform.tfvars con tus valores

# 2. Crear bucket global
terraform init
terraform plan
terraform apply

# 3. Repetir para staging/production
cd ../environments/staging
# Editar terraform.tfvars
terraform init
terraform plan
terraform apply
```

### Paso 2: Configurar Shared Infrastructure

```bash
# 1. Copiar ejemplo de variables
cd shared-infra/environments/development
cp tfvars.example terraform.tfvars

# 2. Editar terraform.tfvars con tus valores
# - project_id
# - workspace
# - organization_id
# - allowed_domains
# - admin_groups
# - registry_name

# 3. Actualizar backend en main.tf
# - bucket: nombre del bucket creado en Paso 1
# - prefix: prefijo dentro del bucket

# 4. Inicializar y desplegar
terraform init
terraform plan
terraform apply
```

### Paso 3: Crear Ambientes Adicionales (Opcional)

Si necesitas staging/production:

```bash
# 1. Copiar estructura de development
cp -r shared-infra/environments/development \
      shared-infra/environments/staging
cp -r shared-infra/environments/development \
      shared-infra/environments/production

# 2. Modificar cada ambiente:
# - terraform.tfvars: project_id, env, etc.
# - main.tf: backend bucket y prefix
```

---

## 📝 Ejemplo Completo: Nuevo Proyecto

### Escenario

- **Proyecto**: `analytics-platform`
- **Workspace**: `analytics`
- **Organización**: `987654321098`
- **Dominio**: `analytics.com`

### Configuración

#### `shared-infra/environments/development/main.tf`

```hcl
backend "gcs" {
  bucket = "analytics-terraform-state-stg"
  prefix = "analytics/dev/shared/terraform"
}
```

#### `shared-infra/environments/development/terraform.tfvars`

```hcl
project_id = "analytics-platform-dev-987654"
workspace  = "analytics"
region     = "us-central1"
env        = "dev"

organization_id = "987654321098"
allowed_domains = ["analytics.com"]

admin_groups = {
  network_admins  = "analytics-network-admins@analytics.com"
  network_viewers = "analytics-developers@analytics.com"
  security_admins = "analytics-security@analytics.com"
  auditors        = "analytics-auditors@analytics.com"
}

registry_name = "analytics-docker-images-dev"
enable_dev_reader = true
```

#### `terraform-state/environments/staging/terraform.tfvars`

```hcl
project_id   = "analytics-terraform-987654"
bucket_prefix = "analytics-terraform-state"
region       = "us-central1"
env          = "stg"
```

#### `terraform-state/environments/staging/backend.tf`

```hcl
terraform {
  backend "gcs" {
    bucket = "analytics-terraform-state"
    prefix = "stg"
  }
}
```

---

## 🔍 Checklist de Reutilización

Antes de desplegar, verifica:

### Backends

- [ ] Buckets de estado creados (global, staging, production)
- [ ] Backend configurado en `shared-infra/environments/*/main.tf`
- [ ] Backend configurado en `terraform-state/environments/*/backend.tf` (si aplica)

### Variables de Contexto

- [ ] `project_id` actualizado en todos los `terraform.tfvars`
- [ ] `workspace` actualizado
- [ ] `env` correcto para cada ambiente
- [ ] `region` configurada correctamente

### Variables de Organización

- [ ] `organization_id` actualizado
- [ ] `allowed_domains` con tus dominios
- [ ] `admin_groups` con tus grupos de Google Workspace/Cloud Identity

### Recursos

- [ ] `registry_name` único y descriptivo
- [ ] `bucket_prefix` único y descriptivo
- [ ] Nombres de recursos no colisionan con otros proyectos

### Seguridad

- [ ] Grupos IAM existen en tu organización
- [ ] Dominios permitidos son correctos
- [ ] Configuración de seguridad apropiada para el ambiente

---

## ⚠️ Consideraciones Importantes

### Nombres de Recursos

- Los nombres de buckets deben ser **globalmente únicos** en GCP
- Los nombres de Artifact Registry deben ser **únicos por proyecto**
- Usa prefijos consistentes: `{workspace}-{resource}-{env}`

### Workspaces Múltiples

Si usas múltiples workspaces en el mismo proyecto:

1. **Backend prefix**: Usa el workspace en el prefix

   ```hcl
   prefix = "${workspace}/shared/terraform"
   ```

2. **Nombres de recursos**: Incluye workspace en nombres
   ```hcl
   registry_name = "${workspace}-docker-images-${env}"
   ```

### Organización vs Proyecto

- `organization_id`: Solo necesario si usas VPC Service Controls u Organization Policies
- Si solo trabajas a nivel de proyecto, puedes dejar `organization_id` vacío (pero algunos módulos pueden requerirlo)

### Backends Compartidos vs Separados

**Opción 1: Backend compartido (recomendado para múltiples workspaces)**

```hcl
bucket = "mi-proyecto-terraform-state"
prefix = "${workspace}/${env}/shared/terraform"
```

**Opción 2: Backend separado por workspace**

```hcl
bucket = "mi-proyecto-${workspace}-terraform-state"
prefix = "${env}/shared/terraform"
```

---

## 🆘 Troubleshooting

### Error: Bucket no existe

**Problema**: `Error: Failed to get existing workspaces: storage: bucket doesn't exist`

**Solución**: Crea el bucket primero usando `terraform-state/global` o `terraform-state/environments/*`

### Error: Permisos insuficientes

**Problema**: `Error: Error creating service account: Permission denied`

**Solución**: Verifica que tu cuenta tenga:

- `roles/owner` o `roles/iam.serviceAccountAdmin`
- `roles/resourcemanager.projectIamAdmin`

### Error: Organization ID incorrecto

**Problema**: `Error: Error reading organization`

**Solución**: Verifica el `organization_id` en GCP Console o usa:

```bash
gcloud organizations list
```

---

## 📚 Referencias

- [Configuración de Backends](backends.md) - Detalles sobre backends
- [Gestión de Entornos](environments.md) - Crear ambientes adicionales
- [Gestión de Credenciales](credentials.md) - Configurar autenticación

---

## ⚡ Configuración Automática con .env

### Paso 1: Crear archivo .env

```bash
cp .env.example .env
```

### Paso 2: Editar .env con tus valores

```bash
# .env
PROJECT_ID="mi-nuevo-proyecto-123456"
WORKSPACE="mi-workspace"
ORGANIZATION_ID="987654321098"
ALLOWED_DOMAINS="miempresa.com"
REGISTRY_NAME="docker-images-dev"
BUCKET_PREFIX="mi-proyecto-terraform-state"
REGION="us-central1"

# Grupos IAM (opcional - se configurarán automáticamente si los defines)
NETWORK_ADMINS="network-admins@miempresa.com"
NETWORK_VIEWERS="developers@miempresa.com"
SECURITY_ADMINS="security-admins@miempresa.com"
AUDITORS="auditors@miempresa.com"
```

### Paso 3: Verificar cambios (opcional)

```bash
# Ver qué archivos se modificarán sin aplicar cambios
make setup-dry-run
```

### Paso 4: Aplicar configuración

```bash
# Aplicar cambios automáticamente
make setup

# O con información detallada
make setup-verbose
```

### Paso 5: Configurar grupos IAM (Opcional)

**Opción A: Automático desde .env (Recomendado)**

Si defines los grupos en tu archivo `.env`:

```bash
# .env
NETWORK_ADMINS="network-admins@miempresa.com"
NETWORK_VIEWERS="developers@miempresa.com"
SECURITY_ADMINS="security-admins@miempresa.com"
AUDITORS="auditors@miempresa.com"
```

El script los configurará automáticamente al ejecutar `make setup`.

**Opción B: Manual en terraform.tfvars**

Si prefieres configurarlos manualmente o necesitas valores diferentes por ambiente, edita:

- `shared-infra/environments/development/terraform.tfvars`
- `shared-infra/environments/staging/terraform.tfvars` (si existe)
- `shared-infra/environments/production/terraform.tfvars` (si existe)

```hcl
admin_groups = {
  network_admins  = "network-admins@miempresa.com"
  network_viewers = "developers@miempresa.com"
  security_admins = "security-admins@miempresa.com"
  auditors        = "auditors@miempresa.com"
}
```

**¿Por qué puede ser manual? (Justificación)**

Aunque ahora el script puede configurar `admin_groups` automáticamente desde el `.env`, hay razones válidas para preferir la configuración manual:

1. **Valores diferentes por ambiente**

   - Desarrollo puede usar grupos diferentes a producción
   - Staging puede tener grupos de prueba separados
   - Permite mayor granularidad de control

2. **Configuración específica por ambiente**

   - Algunos ambientes pueden no necesitar todos los grupos
   - Puedes tener estructuras organizacionales diferentes por proyecto

3. **Flexibilidad operativa**

   - Permite ajustar grupos sin modificar el `.env` compartido
   - Útil cuando múltiples personas trabajan en el proyecto

4. **Seguridad y separación de concerns**

   - Puedes mantener grupos sensibles fuera del `.env` si prefieres
   - El `.env` puede estar en un lugar diferente a `terraform.tfvars`

5. **Estructura organizacional compleja**
   - Organizaciones grandes pueden tener múltiples grupos por rol
   - Puede requerir configuración más detallada que variables simples

**Recomendación**:

- ✅ **Usa automático (Opción A)** si: Todos los ambientes usan los mismos grupos y quieres simplicidad
- ✅ **Usa manual (Opción B)** si: Necesitas grupos diferentes por ambiente o mayor control

### Paso 6: Revisar y verificar

```bash
# Ver cambios aplicados
git diff

# Verificar configuración
cd shared-infra/environments/development
terraform init
terraform validate
```

### Variables del archivo .env

| Variable          | Descripción                               | Ejemplo                           | Requerido |
| ----------------- | ----------------------------------------- | --------------------------------- | --------- |
| `PROJECT_ID`      | ID del proyecto GCP                       | `"mi-proyecto-123456"`            | ✅        |
| `WORKSPACE`       | Nombre del workspace                      | `"platform"`                      | ✅        |
| `ORGANIZATION_ID` | ID de la organización                     | `"123456789012"`                  | ✅        |
| `ALLOWED_DOMAINS` | Dominios permitidos (separados por comas) | `"miempresa.com"`                 | ✅        |
| `REGISTRY_NAME`   | Nombre del Artifact Registry              | `"docker-images-dev"`             | ✅        |
| `BUCKET_PREFIX`   | Prefijo para buckets                      | `"mi-proyecto-terraform-state"`   | ✅        |
| `REGION`          | Región de GCP                             | `"us-central1"`                   | ❌        |
| `ENV`             | Ambiente (dev, stg, prod)                 | `"dev"`                           | ❌        |
| `NETWORK_ADMINS`  | Grupo de administradores de red           | `"network-admins@miempresa.com"`  | ❌        |
| `NETWORK_VIEWERS` | Grupo de visualizadores de red            | `"developers@miempresa.com"`      | ❌        |
| `SECURITY_ADMINS` | Grupo de administradores de seguridad     | `"security-admins@miempresa.com"` | ❌        |
| `AUDITORS`        | Grupo de auditores                        | `"auditors@miempresa.com"`        | ❌        |

### Archivos Modificados Automáticamente

El script `setup-project.sh` modifica:

- ✅ `shared-infra/environments/development/main.tf` (backend bucket)
- ✅ `shared-infra/environments/development/terraform.tfvars` (variables)
- ✅ `terraform-state/environments/staging/main.tf` (bucket name)
- ✅ `terraform-state/environments/staging/terraform.tfvars` (variables)
- ✅ `terraform-state/environments/staging/backend.tf` (backend bucket)
- ✅ `terraform-state/environments/production/main.tf` (bucket name)
- ✅ `terraform-state/environments/production/terraform.tfvars` (variables)
- ✅ `terraform-state/environments/production/backend.tf` (backend bucket)
- ✅ `terraform-state/global/main.tf` (bucket name)
- ✅ `terraform-state/global/terraform.tfvars` (variables)

### Opciones del Script

```bash
# Ver ayuda
./scripts/setup-project.sh --help

# Modo dry-run (sin aplicar cambios)
make setup-dry-run
# o
./scripts/setup-project.sh --dry-run

# Modo verbose (con información detallada)
make setup-verbose
# o
./scripts/setup-project.sh --verbose

# Usar archivo .env diferente
./scripts/setup-project.sh --env .env.production
```

### Troubleshooting

**Error: Archivo .env no encontrado**

```bash
cp .env.example .env
# Editar .env con tus valores
```

**Error: Faltan variables requeridas**

- Verifica que todas las variables obligatorias estén en `.env`
- Revisa que no haya espacios alrededor del `=`

**Los cambios no se aplican**

- Usa `--dry-run` primero para ver qué se modificaría
- Verifica permisos de escritura en los archivos
- Revisa que los archivos existan

---

**Última actualización**: 2025
