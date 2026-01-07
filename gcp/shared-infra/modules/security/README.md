# Módulo Security

Este módulo gestiona todos los aspectos de seguridad del proyecto, incluyendo Service Accounts, IAM, logging, alertas, y políticas de seguridad.

## 📋 Descripción

El módulo `security` es un módulo compuesto que gestiona:

- **Service Accounts**: Cuentas de servicio para CI/CD, VMs, desarrolladores, y break-glass
- **IAM**: Asignación de roles IAM a grupos y service accounts
- **Logging**: Sinks de logging, buckets de logs, y políticas de alertas
- **Security Policies**: VPC Service Controls y Organization Policies
- **GKE Security**: Service Accounts y Workload Identity para GKE

El módulo está organizado en submódulos:
- `iam/`: Gestión de IAM y Service Accounts
- `logging/`: Logging sinks, buckets, y alertas
- `security/`: VPC Service Controls y Organization Policies
- `gke/`: Service Accounts específicos para GKE

## 🔧 Variables Principales

| Variable | Tipo | Descripción | Default | Requerido |
|----------|------|-------------|---------|-----------|
| `project_id` | `string` | ID del proyecto GCP | - | ✅ |
| `workspace` | `string` | Nombre del workspace | - | ✅ |
| `env` | `string` | Ambiente (dev, stg, pre, prod) | - | ✅ |
| `organization_id` | `string` | ID de la organización de GCP | - | ✅ |
| `registry_name` | `string` | Nombre del Artifact Registry | - | ✅ |
| `registry_location` | `string` | Ubicación del Artifact Registry | - | ✅ |
| `allowed_domains` | `list(string)` | Dominios permitidos para IAM | - | ✅ |
| `admin_groups` | `object` | Grupos de administradores por rol | - | ✅ |
| `enable_dev_reader` | `bool` | Crear Service Account para desarrolladores | `false` | ❌ |
| `enable_vpc_service_controls` | `bool` | Habilitar VPC Service Controls | `false` | ❌ |
| `enable_org_policies` | `bool` | Habilitar Organization Policies | `false` | ❌ |
| `enable_group_iam` | `bool` | Habilitar IAM para grupos de Google Workspace | `false` | ❌ |
| `create_admin_sa` | `bool` | Crear Service Accounts de administración para GKE | `false` | ❌ |
| `break_glass_max_session_duration` | `number` | Duración máxima de sesión break-glass (segundos) | `3600` | ❌ |
| `alert_notification_channels` | `list(string)` | IDs de canales de notificación | `[]` | ❌ |
| `log_bucket_suffix` | `string` | Sufijo para nombres de buckets de logging | `""` | ❌ |

### Estructura de `admin_groups`

```hcl
admin_groups = {
  network_admins  = "network-admins@example.com"
  network_viewers = "network-viewers@example.com"
  security_admins = "security-admins@example.com"
  auditors        = "auditors@example.com"
}
```

## 📤 Outputs

| Output | Descripción |
|--------|-------------|
| `ci_cd_writer_email` | Email de la Service Account CI/CD |
| `vm_reader_email` | Email de la Service Account VM reader |
| `dev_reader_email` | Email de la Service Account de desarrolladores (null si deshabilitado) |
| `break_glass_email` | Email de la Service Account Break Glass (sensitive) |
| `environment` | Ambiente actual |
| `is_production` | Indica si es ambiente de producción |

## 📝 Ejemplo de Uso

### Configuración Básica

```hcl
module "security" {
  source = "./modules/security"

  project_id       = "my-project-id"
  workspace        = "platform"
  env              = "dev"
  organization_id  = "123456789012"
  registry_name    = "docker-images"
  registry_location = "us-central1"

  allowed_domains = ["example.com"]

  admin_groups = {
    network_admins  = "network-admins@example.com"
    network_viewers = "network-viewers@example.com"
    security_admins = "security-admins@example.com"
    auditors        = "auditors@example.com"
  }
}
```

### Configuración para Producción

```hcl
module "security" {
  source = "./modules/security"

  project_id                  = "my-project-id"
  workspace                   = "platform"
  env                         = "prod"
  organization_id             = "123456789012"
  registry_name               = "docker-images"
  registry_location           = "us-central1"

  allowed_domains             = ["example.com"]
  enable_vpc_service_controls = true
  enable_org_policies         = true
  enable_group_iam            = true
  create_admin_sa             = true

  admin_groups = {
    network_admins  = "network-admins@example.com"
    network_viewers = "network-viewers@example.com"
    security_admins = "security-admins@example.com"
    auditors        = "auditors@example.com"
  }

  alert_notification_channels = [
    "projects/my-project/notificationChannels/123456789"
  ]

  break_glass_max_session_duration = 7200 # 2 horas
}
```

## 🔗 Dependencias

Este módulo no tiene dependencias de otros módulos del proyecto. Sin embargo:

- Requiere que el proyecto GCP esté creado
- Requiere que la organización de GCP esté configurada (para VPC Service Controls y Organization Policies)
- Si `enable_group_iam = true`, requiere que los grupos de Google Workspace existan
- Si `enable_org_policies = true`, requiere que la API `orgpolicy.googleapis.com` esté habilitada

## 📚 Estructura Interna

El módulo está organizado en submódulos:

- **`iam/`**:
  - Service Accounts (ci-cd-writer, vm-reader, dev-reader, break-glass)
  - IAM bindings para grupos administrativos
  - IAM bindings con condiciones temporales para break-glass
  - Audit logging

- **`logging/`**:
  - Logging sinks (IAM, Security, Network)
  - Log buckets con retención configurable
  - Alert policies para eventos de seguridad

- **`security/`**:
  - VPC Service Controls (opcional)
  - Organization Policies (opcional)

- **`gke/`**:
  - Service Account de administración de GKE
  - Workload Identity Pool para GKE

## ⚠️ Notas Importantes

1. **Service Accounts**: Se crean automáticamente con nombres basados en `workspace` y `env`
2. **Break Glass**: La cuenta break-glass tiene permisos temporales con expiración automática
3. **Logging**: Los buckets de logging tienen retención diferente según el ambiente (90 días dev, 365 días prod)
4. **VPC Service Controls**: Requiere configuración adicional y puede afectar el acceso a APIs
5. **Organization Policies**: Requiere permisos a nivel de organización
6. **Grupos IAM**: Si `enable_group_iam = true`, los grupos deben existir en Google Workspace antes de aplicar

## 🔒 Seguridad

- Las Service Accounts siguen el principio de menor privilegio
- Break-glass tiene permisos temporales con expiración automática
- Los logs de auditoría se almacenan en buckets separados con retención configurable
- Las alertas se configuran para eventos críticos de seguridad

---

**Última actualización**: 2025-01-07
