# Módulo Artifact Registry

Este módulo crea y configura un repositorio Docker en Google Artifact Registry con tags inmutables y políticas de limpieza opcionales.

## 📋 Descripción

El módulo `artifact_registry` crea:

- **Repositorio Docker**: Repositorio en Artifact Registry para almacenar imágenes Docker
- **Tags Inmutables**: Habilitados por defecto para prevenir sobrescritura de imágenes
- **IAM**: Permisos de lectura, escritura y administración configurados mediante variables
- **Cleanup Policies**: Políticas opcionales para limpieza automática de imágenes antiguas

## 🔧 Variables Principales

| Variable | Tipo | Descripción | Default | Requerido |
|----------|------|-------------|---------|-----------|
| `region` | `string` | Región de GCP donde se creará el registry | - | ✅ |
| `repository_id` | `string` | ID del repositorio (nombre único) | - | ✅ |
| `description` | `string` | Descripción del repositorio | `""` | ❌ |
| `labels` | `map(string)` | Labels para el repositorio | `{}` | ❌ |
| `readers` | `list(string)` | Service accounts con permiso de lectura | `[]` | ❌ |
| `writers` | `list(string)` | Service accounts con permiso de escritura | `[]` | ❌ |
| `admins` | `list(string)` | Service accounts con permisos de administración | `[]` | ❌ |
| `cleanup_policies` | `list(object)` | Políticas de limpieza automática | `[]` | ❌ |
| `enable_cleanup_policies` | `bool` | Habilitar cleanup policies | `false` | ❌ |

### Estructura de `cleanup_policies`

```hcl
cleanup_policies = [
  {
    id     = "delete-old-images"
    action = "DELETE"
    condition = {
      tag_state    = "UNTAGGED"
      older_than   = "30d"
    }
  },
  {
    id     = "keep-recent-versions"
    action = "KEEP"
    most_recent_versions = {
      keep_count = 10
    }
  }
]
```

## 📤 Outputs

| Output | Descripción |
|--------|-------------|
| `repository_name` | Nombre completo del repositorio (resource name) |
| `repository_url` | URL completa del repositorio para Docker pull/push |

El `repository_url` tiene el formato:
```
{REGION}-docker.pkg.dev/{PROJECT_ID}/{REPOSITORY_ID}
```

## 📝 Ejemplo de Uso

### Configuración Básica

```hcl
module "artifact_registry" {
  source = "./modules/artifact_registry"

  region       = "us-central1"
  repository_id = "docker-images"
  description  = "Repositorio Docker para imágenes de aplicación"

  labels = {
    env     = "dev"
    project = "my-app"
  }
}
```

### Con IAM Configurado

```hcl
module "artifact_registry" {
  source = "./modules/artifact_registry"

  region       = "us-central1"
  repository_id = "docker-images"

  readers = [
    "serviceAccount:vm-reader@my-project.iam.gserviceaccount.com"
  ]

  writers = [
    "serviceAccount:ci-cd-writer@my-project.iam.gserviceaccount.com"
  ]

  admins = [
    "serviceAccount:admin@my-project.iam.gserviceaccount.com"
  ]
}
```

### Con Cleanup Policies

```hcl
module "artifact_registry" {
  source = "./modules/artifact_registry"

  region        = "us-central1"
  repository_id = "docker-images"

  enable_cleanup_policies = true

  cleanup_policies = [
    {
      id     = "delete-untagged-older-than-30d"
      action = "DELETE"
      condition = {
        tag_state  = "UNTAGGED"
        older_than = "30d"
      }
    },
    {
      id     = "keep-latest-10-versions"
      action = "KEEP"
      most_recent_versions = {
        keep_count = 10
      }
    }
  ]
}
```

## 🔗 Dependencias

Este módulo no tiene dependencias de otros módulos del proyecto. Sin embargo:

- Requiere que el proyecto GCP esté creado
- Requiere que la API `artifactregistry.googleapis.com` esté habilitada
- Las Service Accounts en `readers`, `writers`, y `admins` deben existir (normalmente creadas por el módulo `security`)

## 📚 Uso con Docker

Una vez creado el repositorio, puedes usarlo con Docker:

```bash
# Autenticarse
gcloud auth configure-docker us-central1-docker.pkg.dev

# Tag de imagen
docker tag my-image:latest us-central1-docker.pkg.dev/my-project/docker-images/my-image:1.0.0

# Push
docker push us-central1-docker.pkg.dev/my-project/docker-images/my-image:1.0.0

# Pull
docker pull us-central1-docker.pkg.dev/my-project/docker-images/my-image:1.0.0
```

## ⚠️ Notas Importantes

1. **Tags Inmutables**: Habilitados por defecto. Una vez que una imagen tiene un tag, no puede ser modificada. Para actualizar, usa un nuevo tag.
2. **IAM**: Los permisos se configuran a nivel de repositorio. Usa Service Accounts para acceso programático.
3. **Cleanup Policies**: Solo se aplican si `enable_cleanup_policies = true` y se proporcionan políticas válidas.
4. **Región**: Elige una región cercana a tus recursos para reducir latencia y costos de transferencia.
5. **Repository ID**: Debe ser único dentro de la región y proyecto. Solo puede contener letras minúsculas, números y guiones.

## 🔒 Seguridad

- Tags inmutables previenen sobrescritura accidental de imágenes
- IAM permite control granular de acceso (lectura, escritura, administración)
- Cleanup policies ayudan a mantener el repositorio limpio y reducir costos

---

**Última actualización**: 2025-01-07
