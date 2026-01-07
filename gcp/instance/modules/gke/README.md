# Módulo GKE

Este módulo crea un cluster de Google Kubernetes Engine (GKE) con configuración para producción, incluyendo node pools, autoscaling, y Workload Identity.

## 📋 Descripción

El módulo `gke` crea:

- **Cluster GKE**: Cluster privado de Kubernetes con control plane privado
- **Node Pool**: Pool de nodos con autoscaling configurable
- **Workload Identity**: Configuración de Workload Identity para pods
- **Network Policy**: Política de red opcional para aislar pods
- **Maintenance Windows**: Ventanas de mantenimiento configurables
- **Deletion Protection**: Protección contra eliminación accidental

## 🔧 Variables Principales

| Variable | Tipo | Descripción | Default | Requerido |
|----------|------|-------------|---------|-----------|
| `project_id` | `string` | ID del proyecto GCP | - | ✅ |
| `region` | `string` | Región donde se creará el cluster | `"us-central1"` | ❌ |
| `cluster_name` | `string` | Nombre del cluster GKE | - | ✅ |
| `gke_subnet_name` | `string` | Nombre de la subnet GKE | - | ✅ |
| `gke_pods_range_name` | `string` | Nombre del secondary range para pods | - | ✅ |
| `gke_services_range_name` | `string` | Nombre del secondary range para services | - | ✅ |
| `gke_master_cidr` | `string` | CIDR para control plane (/28) | - | ✅ |
| `node_pool_name` | `string` | Nombre del node pool | `"default-pool"` | ❌ |
| `node_machine_type` | `string` | Tipo de máquina de los nodos | `"e2-medium"` | ❌ |
| `node_disk_size` | `number` | Tamaño del disco de nodos (GB) | `100` | ❌ |
| `node_disk_type` | `string` | Tipo de disco (pd-standard, pd-ssd) | `"pd-standard"` | ❌ |
| `initial_node_count` | `number` | Número inicial de nodos | `1` | ❌ |
| `enable_autoscaling` | `bool` | Habilitar autoscaling | `true` | ❌ |
| `min_node_count` | `number` | Número mínimo de nodos | `1` | ❌ |
| `max_node_count` | `number` | Número máximo de nodos | `3` | ❌ |
| `enable_network_policy` | `bool` | Habilitar Network Policy | `false` | ❌ |
| `service_account_email` | `string` | Service Account para nodos | `null` | ❌ |
| `maintenance_window_start_time` | `string` | Hora de inicio de mantenimiento (HH:MM) | `"02:00"` | ❌ |
| `maintenance_window_day` | `string` | Día de mantenimiento (SUNDAY-SATURDAY) | `"SUNDAY"` | ❌ |
| `deletion_protection` | `bool` | Protección contra eliminación | `true` | ❌ |
| `workload_identity_pool` | `string` | Workload Identity Pool | `""` | ❌ |

## 📤 Outputs

| Output | Descripción |
|--------|-------------|
| `cluster_id` | ID del cluster GKE |
| `cluster_name` | Nombre del cluster |
| `cluster_location` | Ubicación del cluster |
| `cluster_endpoint` | Endpoint del control plane (sensitive) |
| `kubectl_command` | Comando para configurar kubectl |
| `node_pool_id` | ID del node pool |
| `node_pool_name` | Nombre del node pool |
| `workload_identity_pool` | Workload Identity Pool configurado |
| `autoscaling_min_nodes` | Número mínimo de nodos (null si deshabilitado) |
| `autoscaling_max_nodes` | Número máximo de nodos (null si deshabilitado) |
| `current_node_count` | Número actual de nodos |
| `cluster_ca_certificate` | CA certificate del cluster (sensitive) |

## 📝 Ejemplo de Uso

### Configuración Básica

```hcl
module "gke_cluster" {
  source = "../../modules/gke"

  project_id              = "my-project-id"
  region                  = "us-central1"
  cluster_name            = "my-gke-cluster"
  gke_subnet_name         = "roax-prod-vpc-gke-subnet"
  gke_pods_range_name     = "roax-prod-vpc-pods"
  gke_services_range_name = "roax-prod-vpc-services"
  gke_master_cidr         = "172.16.0.0/28"

  node_machine_type = "e2-medium"
  initial_node_count = 2
  enable_autoscaling = true
  min_node_count = 2
  max_node_count = 5
}
```

### Configuración para Producción

```hcl
module "gke_cluster" {
  source = "../../modules/gke"

  project_id              = "my-project-id"
  region                  = "us-central1"
  cluster_name            = "prod-gke-cluster"
  gke_subnet_name         = "roax-prod-vpc-gke-subnet"
  gke_pods_range_name     = "roax-prod-vpc-pods"
  gke_services_range_name = "roax-prod-vpc-services"
  gke_master_cidr         = "172.16.0.0/28"

  node_machine_type       = "e2-standard-4"
  node_disk_size          = 200
  node_disk_type          = "pd-ssd"
  initial_node_count      = 3
  enable_autoscaling      = true
  min_node_count          = 3
  max_node_count          = 10

  enable_network_policy   = true
  deletion_protection     = true

  maintenance_window_start_time = "02:00"
  maintenance_window_day        = "SUNDAY"

  service_account_email = "gke-nodes@my-project.iam.gserviceaccount.com"
}
```

### Con Workload Identity

```hcl
module "gke_cluster" {
  source = "../../modules/gke"

  project_id              = "my-project-id"
  region                  = "us-central1"
  cluster_name            = "my-gke-cluster"
  gke_subnet_name         = "roax-prod-vpc-gke-subnet"
  gke_pods_range_name     = "roax-prod-vpc-pods"
  gke_services_range_name = "roax-prod-vpc-services"
  gke_master_cidr         = "172.16.0.0/28"

  workload_identity_pool = "projects/123456789/locations/global/workloadIdentityPools/my-pool"

  node_machine_type = "e2-medium"
  initial_node_count = 2
  enable_autoscaling = true
  min_node_count = 2
  max_node_count = 5
}
```

## 🔗 Dependencias

Este módulo requiere:

- **Subnet GKE**: La subnet especificada en `gke_subnet_name` debe existir con secondary ranges para pods y services (normalmente creada por el módulo `network` de `shared-infra` con `enable_gke = true`)
- **Service Account** (opcional): Si se especifica `service_account_email`, debe existir (normalmente creado por el módulo `security/gke` de `shared-infra`)
- **Workload Identity Pool** (opcional): Si se especifica, debe existir y estar configurado

## 📚 Uso con kubectl

Una vez creado el cluster, configura kubectl:

```bash
# Usar el comando del output
gcloud container clusters get-credentials my-gke-cluster \
  --region=us-central1 \
  --project=my-project-id

# O usar el output de Terraform
terraform output -raw kubectl_command | bash

# Verificar conexión
kubectl get nodes
```

## ⚠️ Notas Importantes

1. **Cluster Privado**: El cluster es privado por defecto (control plane y nodos sin IPs públicas)
2. **Autoscaling**: Si está habilitado, el número de nodos puede variar entre `min_node_count` y `max_node_count`
3. **Maintenance Windows**: La ventana de mantenimiento es diaria (FREQ=DAILY) con duración de 4 horas
4. **Deletion Protection**: Por defecto está habilitado. Para eliminar el cluster, establece `deletion_protection = false`
5. **Network Policy**: Si está habilitada, los pods deben tener políticas de red explícitas para comunicarse
6. **Workload Identity**: Permite que los pods usen Service Accounts de GCP sin almacenar credenciales

## 🔒 Seguridad

- Cluster privado con control plane sin IP pública
- Workload Identity para autenticación segura de pods
- Network Policy opcional para aislar pods
- Service Account con permisos mínimos para nodos

## 🔄 Escalado

El autoscaling ajusta automáticamente el número de nodos según la demanda:

- **Escalado hacia arriba**: Cuando los pods no pueden programarse por falta de recursos
- **Escalado hacia abajo**: Cuando hay nodos subutilizados (después de un período de estabilidad)

Para escalar manualmente:

```bash
# Ver estado actual
kubectl get nodes

# El autoscaling gestiona automáticamente, pero puedes forzar un cambio temporal
gcloud container clusters resize my-gke-cluster \
  --num-nodes=5 \
  --region=us-central1
```

---

**Última actualización**: 2025-01-07
