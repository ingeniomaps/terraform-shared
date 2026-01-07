# Módulo Network

Este módulo gestiona la infraestructura de red compartida para el proyecto, incluyendo VPC, subnets, Cloud NAT, y reglas de firewall.

## 📋 Descripción

El módulo `network` crea y configura:

- **VPC**: Red virtual privada con nombre basado en workspace y ambiente
- **Subnets**:
  - Subnet para VMs (`vm_subnet_cidr`)
  - Subnet para GKE (opcional, si `enable_gke = true`)
- **Cloud NAT**: Para permitir acceso saliente a Internet desde VMs sin IP pública
- **Cloud Router**: Router asociado al Cloud NAT
- **Firewall Rules**: Reglas de firewall gestionadas por el submódulo `firewall/`

## 🔧 Variables Principales

| Variable | Tipo | Descripción | Default | Requerido |
|----------|------|-------------|---------|-----------|
| `project_id` | `string` | ID del proyecto GCP | - | ✅ |
| `workspace` | `string` | Nombre del workspace (ej: "platform") | - | ✅ |
| `env` | `string` | Ambiente (dev, stg, pre, prod) | - | ✅ |
| `region` | `string` | Región principal | - | ✅ |
| `vm_subnet_cidr` | `string` | CIDR de la subred para VMs | `"10.0.0.0/24"` | ❌ |
| `vm_service_account_email` | `string` | Service Account usado por las VMs | - | ✅ |
| `enable_public_http` | `bool` | Habilitar acceso HTTP/HTTPS público | `true` | ❌ |
| `enable_restricted_http` | `bool` | HTTP/HTTPS solo desde IPs corporativas | `false` | ❌ |
| `corporate_ip_ranges` | `list(string)` | Rangos IP corporativos | `[]` | ❌ |
| `enable_vpc_peering` | `bool` | Habilitar VPC peering | `false` | ❌ |
| `enable_gke` | `bool` | Habilitar subnet y firewall para GKE | `false` | ❌ |
| `gke_subnet_cidr` | `string` | CIDR para nodes de GKE | `"10.0.10.0/24"` | ❌ |
| `gke_pods_cidr` | `string` | CIDR para pods de GKE | `"10.1.0.0/16"` | ❌ |
| `gke_services_cidr` | `string` | CIDR para services de GKE | `"10.2.0.0/16"` | ❌ |
| `gke_master_cidr` | `string` | CIDR para control plane (/28) | `"172.16.0.0/28"` | ❌ |

## 📤 Outputs

| Output | Descripción |
|--------|-------------|
| `vpc_id` | ID de la VPC creada |
| `vpc_name` | Nombre de la VPC |
| `vpc_self_link` | Self link de la VPC |
| `vm_subnet_id` | ID de la subnet para VMs |
| `vm_subnet_name` | Nombre de la subnet para VMs |
| `vm_subnet_cidr` | CIDR de la subnet para VMs |
| `gke_subnet_id` | ID de la subnet GKE (null si no habilitado) |
| `gke_subnet_name` | Nombre de la subnet GKE |
| `gke_pods_range_name` | Nombre del secondary range para pods |
| `gke_services_range_name` | Nombre del secondary range para services |
| `cloud_nat_name` | Nombre del Cloud NAT |
| `cloud_router_name` | Nombre del Cloud Router |
| `network_tags` | Network tags que deben usarse en recursos |

## 📝 Ejemplo de Uso

```hcl
module "network" {
  source = "./modules/network"

  project_id                = "my-project-id"
  workspace                 = "platform"
  env                       = "dev"
  region                    = "us-central1"
  vm_subnet_cidr            = "10.0.0.0/24"
  vm_service_account_email  = "vm-reader@my-project.iam.gserviceaccount.com"
  enable_public_http        = true
  enable_restricted_http    = false
  enable_gke                = false
}
```

### Ejemplo con GKE habilitado

```hcl
module "network" {
  source = "./modules/network"

  project_id                = "my-project-id"
  workspace                 = "platform"
  env                       = "prod"
  region                    = "us-central1"
  vm_subnet_cidr            = "10.0.0.0/24"
  vm_service_account_email  = "vm-reader@my-project.iam.gserviceaccount.com"
  enable_public_http        = true
  enable_gke                = true
  gke_subnet_cidr           = "10.0.10.0/24"
  gke_pods_cidr             = "10.1.0.0/16"
  gke_services_cidr         = "10.2.0.0/16"
  gke_master_cidr           = "172.16.0.0/28"
}
```

### Ejemplo con HTTP restringido

```hcl
module "network" {
  source = "./modules/network"

  project_id                = "my-project-id"
  workspace                 = "platform"
  env                       = "prod"
  region                    = "us-central1"
  vm_subnet_cidr            = "10.0.0.0/24"
  vm_service_account_email  = "vm-reader@my-project.iam.gserviceaccount.com"
  enable_public_http        = false
  enable_restricted_http    = true
  corporate_ip_ranges        = ["203.0.113.0/24", "198.51.100.0/24"]
}
```

## 🔗 Dependencias

Este módulo no tiene dependencias de otros módulos del proyecto. Sin embargo:

- Requiere que el proyecto GCP esté creado
- Requiere que el Service Account `vm_service_account_email` exista (normalmente creado por el módulo `security`)
- Si se usa VPC peering, requiere que la VPC peer exista en el proyecto especificado

## 📚 Estructura Interna

El módulo está organizado en:

- `main.tf`: Configuración principal y llamada al submódulo firewall
- `vpc.tf`: Creación de la VPC
- `subnet.tf`: Creación de subnets (VM y GKE)
- `cloud.tf`: Cloud NAT y Cloud Router
- `data.tf`: Data sources para obtener información del proyecto
- `validations.tf`: Validaciones adicionales usando check blocks
- `variables.tf`: Definición de variables
- `outputs.tf`: Outputs del módulo
- `firewall/`: Submódulo que gestiona todas las reglas de firewall

## ⚠️ Notas Importantes

1. **CIDR Ranges**: Asegúrate de que los CIDR ranges no se solapen entre diferentes subnets
2. **Firewall Rules**: Las reglas de firewall son gestionadas por el submódulo `firewall/` y se crean automáticamente
3. **Cloud NAT**: Se crea automáticamente para permitir acceso saliente desde VMs sin IP pública
4. **GKE**: Si `enable_gke = true`, se crean subnets adicionales y secondary ranges para pods y services
5. **Validaciones**: El módulo incluye validaciones automáticas para formato CIDR, emails, y rangos IP corporativos

---

**Última actualización**: 2025-01-07
