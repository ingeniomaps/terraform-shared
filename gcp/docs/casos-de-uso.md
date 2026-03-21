# Casos de Uso del Proyecto

Esta documentación describe todos los casos de uso posibles del proyecto Terraform GCP, con ejemplos de configuración para cada escenario.

## 📋 Tabla de Contenidos

- [Aplicar Casos de Uso](#-aplicar-casos-de-uso)
- [Casos de Uso por Tipo de Infraestructura](#casos-de-uso-por-tipo-de-infraestructura)
- [Casos de Uso por Seguridad](#casos-de-uso-por-seguridad)
- [Casos de Uso por Conectividad](#casos-de-uso-por-conectividad)
- [Casos de Uso por Ambiente](#casos-de-uso-por-ambiente)
- [Casos de Uso Combinados](#casos-de-uso-combinados)
- [Casos de Uso Especiales](#casos-de-uso-especiales)

---

## 🏗️ Casos de Uso por Tipo de Infraestructura

### Caso 1: Infraestructura Básica (Solo VMs)

**Descripción**: Configuración mínima para desplegar VMs tradicionales sin GKE.

**Características**:

- ✅ VPC con routing global
- ✅ Subnet para VMs
- ✅ Firewall rules básicas
- ✅ Cloud NAT para acceso a internet
- ✅ Artifact Registry para imágenes Docker
- ✅ Service Accounts para VMs

**Configuración**:

```hcl
# terraform.tfvars
project_id = "mi-proyecto-dev-123456"
workspace  = "platform"
env        = "dev"
region     = "us-central1"

# Network
vm_subnet_cidr = "10.0.0.0/24"
enable_gke     = false

# HTTP Access
enable_public_http     = true
enable_restricted_http = false

# VPC Peering
enable_vpc_peering = false

# Security
enable_dev_reader           = true
enable_vpc_service_controls = false
```

**Recursos Creados**:

- 1 VPC
- 1 Subnet para VMs (10.0.0.0/24)
- Firewall rules (interno, HTTP/HTTPS público, SSH vía IAP, health checks)
- Cloud NAT
- Artifact Registry
- Service Accounts (ci-cd-writer, vm-reader, dev-reader)

**Cuándo Usar**:

- Aplicaciones tradicionales en VMs
- Microservicios sin orquestación
- Entornos de desarrollo simples
- Cargas de trabajo que no requieren Kubernetes

---

### Caso 2: Infraestructura con GKE

**Descripción**: Configuración completa para Google Kubernetes Engine con subnets dedicadas.

**Características**:

- ✅ Todo lo del Caso 1
- ✅ Subnet dedicada para GKE nodes
- ✅ Secondary ranges para pods y services
- ✅ Firewall rules específicas para GKE
- ✅ Service Accounts para GKE (opcional)

**Configuración**:

```hcl
# terraform.tfvars
project_id = "mi-proyecto-prod-123456"
workspace  = "platform"
env        = "prod"
region     = "us-central1"

# Network - VMs
vm_subnet_cidr = "10.0.0.0/24"

# Network - GKE
enable_gke         = true
gke_subnet_cidr    = "10.0.10.0/24"  # 256 IPs para nodes
gke_pods_cidr      = "10.1.0.0/16"   # 65k pods
gke_services_cidr  = "10.2.0.0/16"   # 65k services
gke_master_cidr    = "172.16.0.0/28" # Control plane (16 IPs)

# HTTP Access
enable_public_http     = true
enable_restricted_http = false

# VPC Peering
enable_vpc_peering = false

# Security
enable_dev_reader           = false
enable_vpc_service_controls = true
```

**Recursos Adicionales Creados**:

- 1 Subnet para GKE nodes (10.0.10.0/24)
- 2 Secondary IP ranges (pods y services)
- Firewall rules para GKE (nodes, pods, services, master)
- Service Accounts para GKE (si `create_admin_sa = true`)

**Cuándo Usar**:

- Aplicaciones containerizadas
- Microservicios con orquestación
- Escalado automático
- CI/CD con Kubernetes
- Producción con alta disponibilidad

**⚠️ Importante**: Los rangos CIDR NO deben solaparse:

- VMs: `10.0.0.0/24`
- GKE nodes: `10.0.10.0/24`
- GKE pods: `10.1.0.0/16`
- GKE services: `10.2.0.0/16`
- GKE master: `172.16.0.0/28`

---

## 🔒 Casos de Uso por Seguridad

### Caso 3: Acceso HTTP/HTTPS Público

**Descripción**: Aplicaciones accesibles desde internet (load balancers, APIs públicas).

**Características**:

- ✅ Firewall rules permiten tráfico HTTP/HTTPS desde cualquier IP
- ✅ Ideal para aplicaciones públicas
- ✅ Compatible con Cloud Load Balancer

**Configuración**:

```hcl
# terraform.tfvars
enable_public_http     = true
enable_restricted_http = false
# corporate_ip_ranges no es necesario
```

**Firewall Rules Creadas**:

- `allow-http-https-public`: Permite tráfico en puertos 80 y 443 desde `0.0.0.0/0`

**Cuándo Usar**:

- APIs públicas
- Aplicaciones web públicas
- Load balancers con IPs públicas
- Producción con acceso público

---

### Caso 4: Acceso HTTP/HTTPS Restringido

**Descripción**: Aplicaciones accesibles solo desde IPs corporativas (oficina, VPN).

**Características**:

- ✅ Firewall rules restringen tráfico a IPs específicas
- ✅ Mayor seguridad para aplicaciones internas
- ✅ Compatible con VPN corporativa

**Configuración**:

```hcl
# terraform.tfvars
enable_public_http     = false
enable_restricted_http = true
corporate_ip_ranges = [
  "203.0.113.0/24",  # Oficina principal
  "198.51.100.0/24", # VPN corporativa
  "192.0.2.0/24"     # Otra ubicación
]
```

**Firewall Rules Creadas**:

- `allow-http-https-restricted`: Permite tráfico en puertos 80 y 443 solo desde `corporate_ip_ranges`

**Cuándo Usar**:

- Aplicaciones internas
- APIs privadas
- Desarrollo con acceso controlado
- Staging con restricciones de acceso

**⚠️ Importante**: `enable_public_http` y `enable_restricted_http` son mutuamente excluyentes.

---

### Caso 5: VPC Service Controls

**Descripción**: Protección adicional para producción usando VPC Service Controls.

**Características**:

- ✅ Perímetro de seguridad alrededor de recursos
- ✅ Previene exfiltración de datos
- ✅ Controla acceso a servicios de GCP
- ✅ Requiere organización de GCP

**Configuración**:

```hcl
# terraform.tfvars
organization_id = "123456789012"
enable_vpc_service_controls = true
```

**Recursos Adicionales Creados**:

- VPC Service Controls perimeter
- Access levels (si se configuran)
- Service restrictions

**Cuándo Usar**:

- Producción con datos sensibles
- Cumplimiento regulatorio (HIPAA, PCI-DSS, etc.)
- Prevención de exfiltración de datos
- Organizaciones con políticas estrictas

**⚠️ Requisitos**:

- Debe tener una organización de GCP
- Requiere permisos de organización
- Puede afectar acceso a servicios externos

---

### Caso 6: Break-Glass Account

**Descripción**: Cuenta de emergencia con permisos temporales para acceso de emergencia.

**Características**:

- ✅ Service Account con permisos elevados
- ✅ Sesión con duración limitada
- ✅ Para uso en emergencias

**Configuración**:

```hcl
# terraform.tfvars
break_glass_max_session_duration = 3600  # 1 hora en segundos
```

**Recursos Creados**:

- Service Account `break-glass`
- IAM bindings temporales (configurar manualmente cuando sea necesario)

**Cuándo Usar**:

- Acceso de emergencia
- Recuperación de desastres
- Mantenimiento de emergencia
- Troubleshooting crítico

---

## 🌐 Casos de Uso por Conectividad

### Caso 7: VPC Peering

**Descripción**: Conectar esta VPC con otra VPC en un proyecto diferente.

**Características**:

- ✅ Conectividad privada entre proyectos
- ✅ Sin pasar por internet público
- ✅ Bajo costo (sin egress charges)
- ✅ Baja latencia

**Configuración**:

```hcl
# terraform.tfvars
enable_vpc_peering = true
peer_project_id    = "mi-proyecto-b-789012"
peer_vpc_name      = "shared-services-vpc"
```

**Recursos Creados**:

- VPC Peering connection
- Routes para el peering

**Cuándo Usar**:

- Compartir servicios entre proyectos
- Conectar con VPC compartida (Shared VPC)
- Acceso a bases de datos en otro proyecto
- Arquitectura multi-proyecto

**⚠️ Requisitos**:

- El proyecto peer debe existir
- La VPC peer debe existir
- Rangos CIDR no deben solaparse
- Se requiere configuración en ambos lados del peering

---

### Caso 8: Multi-Región (Futuro)

**Descripción**: Desplegar infraestructura en múltiples regiones.

**Características**:

- ⚠️ Actualmente el proyecto soporta una región por ambiente
- 💡 Para multi-región, crear múltiples instancias del ambiente

**Configuración**:

```bash
# Crear ambientes por región
shared-infra/environments/
├── development/
│   └── terraform.tfvars  # region = "us-central1"
├── development-eu/
│   └── terraform.tfvars  # region = "europe-west1"
└── development-asia/
    └── terraform.tfvars   # region = "asia-east1"
```

**Cuándo Usar**:

- Alta disponibilidad global
- Baja latencia por región
- Cumplimiento de residencia de datos
- Disaster recovery multi-región

---

## 🌍 Casos de Uso por Ambiente

### Caso 9: Desarrollo (Development)

**Descripción**: Configuración optimizada para desarrollo con acceso flexible.

**Características**:

- ✅ Acceso de desarrolladores habilitado
- ✅ VPC Service Controls deshabilitado
- ✅ Retención de logs reducida
- ✅ Acceso HTTP puede ser restringido o público

**Configuración**:

```hcl
# terraform.tfvars
project_id = "mi-proyecto-dev-123456"
workspace  = "platform"
env        = "dev"
region     = "us-central1"

# Security
enable_dev_reader           = true
enable_vpc_service_controls = false
break_glass_max_session_duration = 7200  # 2 horas

# Network
vm_subnet_cidr = "10.0.0.0/24"
enable_gke     = false

# HTTP Access - Opción 1: Restringido
enable_public_http     = false
enable_restricted_http = true
corporate_ip_ranges = [
  "203.0.113.0/24"  # VPN de desarrollo
]

# HTTP Access - Opción 2: Público (para testing)
# enable_public_http     = true
# enable_restricted_http = false
```

**Cuándo Usar**:

- Desarrollo activo
- Testing de nuevas features
- Experimentación
- Onboarding de desarrolladores

---

### Caso 10: Staging

**Descripción**: Configuración similar a producción pero con menos restricciones.

**Características**:

- ✅ Sin acceso de desarrolladores
- ✅ VPC Service Controls opcional
- ✅ Configuración intermedia de seguridad
- ✅ Testing de configuración de producción

**Configuración**:

```hcl
# terraform.tfvars
project_id = "mi-proyecto-stg-123456"
workspace  = "platform"
env        = "stg"
region     = "us-central1"

# Security
enable_dev_reader           = false
enable_vpc_service_controls = false  # Opcional: true para testing
break_glass_max_session_duration = 3600

# Network
vm_subnet_cidr = "10.0.0.0/24"
enable_gke     = true  # Si se usa en producción

# HTTP Access
enable_public_http     = true
enable_restricted_http = false
```

**Cuándo Usar**:

- Pre-producción
- Testing de integración
- Validación de cambios
- Staging de releases

---

### Caso 11: Producción

**Descripción**: Configuración con máxima seguridad y disponibilidad.

**Características**:

- ✅ VPC Service Controls habilitado
- ✅ Sin acceso de desarrolladores
- ✅ Retención de logs extendida
- ✅ Prevención de destrucción de recursos
- ✅ Políticas de retención bloqueadas

**Configuración**:

```hcl
# terraform.tfvars
project_id = "mi-proyecto-prod-123456"
workspace  = "platform"
env        = "prod"
region     = "us-central1"

# Security
enable_dev_reader           = false
enable_vpc_service_controls = true
break_glass_max_session_duration = 3600  # 1 hora

# Network
vm_subnet_cidr = "10.0.0.0/24"
enable_gke     = true

gke_subnet_cidr    = "10.0.10.0/24"
gke_pods_cidr      = "10.1.0.0/16"
gke_services_cidr  = "10.2.0.0/16"
gke_master_cidr    = "172.16.0.0/28"

# HTTP Access
enable_public_http     = true
enable_restricted_http = false

# VPC Peering (si aplica)
enable_vpc_peering = true
peer_project_id    = "shared-services-123456"
peer_vpc_name      = "shared-vpc"
```

**Configuración de Buckets (bootstrap/global/terraform.tfvars)**:

```hcl
prevent_destroy       = true
retention_period_days = 90
retention_locked      = true
```

**Cuándo Usar**:

- Carga de trabajo de producción
- Datos sensibles
- Alta disponibilidad requerida
- Cumplimiento regulatorio

---

## 🔀 Casos de Uso Combinados

### Caso 12: Producción Completa (GKE + VPC Peering + VPC Service Controls)

**Descripción**: Configuración completa para producción con todas las características.

**Características**:

- ✅ GKE habilitado
- ✅ VPC Peering a servicios compartidos
- ✅ VPC Service Controls
- ✅ Acceso HTTP público
- ✅ Máxima seguridad

**Configuración**:

```hcl
# terraform.tfvars
project_id = "mi-proyecto-prod-123456"
workspace  = "platform"
env        = "prod"
region     = "us-central1"

organization_id = "123456789012"
allowed_domains = ["miempresa.com"]

admin_groups = {
  network_admins  = "network-admins@miempresa.com"
  network_viewers = "developers@miempresa.com"
  security_admins = "security-admins@miempresa.com"
  auditors        = "auditors@miempresa.com"
}

# Security
enable_dev_reader           = false
enable_vpc_service_controls = true
break_glass_max_session_duration = 3600

# Network - VMs
vm_subnet_cidr = "10.0.0.0/24"

# Network - GKE
enable_gke         = true
gke_subnet_cidr    = "10.0.10.0/24"
gke_pods_cidr      = "10.1.0.0/16"
gke_services_cidr  = "10.2.0.0/16"
gke_master_cidr    = "172.16.0.0/28"

# HTTP Access
enable_public_http     = true
enable_restricted_http = false

# VPC Peering
enable_vpc_peering = true
peer_project_id    = "shared-services-123456"
peer_vpc_name      = "shared-vpc"

# Artifact Registry
registry_name = "docker-images-prod"

# Alerting
alert_notification_channels = [
  "projects/mi-proyecto-prod-123456/notificationChannels/xxx"
]
```

**Recursos Creados**:

- VPC con routing global
- 2 Subnets (VMs y GKE)
- Secondary ranges para GKE
- VPC Peering connection
- VPC Service Controls perimeter
- Artifact Registry
- Service Accounts (ci-cd-writer, vm-reader, break-glass)
- Logging sinks y buckets
- Alert policies
- Organization policies

**Cuándo Usar**:

- Producción enterprise
- Aplicaciones críticas
- Cumplimiento estricto
- Arquitectura multi-proyecto

---

### Caso 13: Desarrollo con GKE y Acceso Restringido

**Descripción**: Desarrollo con Kubernetes pero con acceso HTTP restringido.

**Características**:

- ✅ GKE habilitado
- ✅ Acceso HTTP solo desde VPN/oficina
- ✅ Acceso de desarrolladores
- ✅ Sin VPC Service Controls

**Configuración**:

```hcl
# terraform.tfvars
project_id = "mi-proyecto-dev-123456"
workspace  = "platform"
env        = "dev"
region     = "us-central1"

# Security
enable_dev_reader           = true
enable_vpc_service_controls = false

# Network - VMs
vm_subnet_cidr = "10.0.0.0/24"

# Network - GKE
enable_gke         = true
gke_subnet_cidr    = "10.0.10.0/24"
gke_pods_cidr      = "10.1.0.0/16"
gke_services_cidr  = "10.2.0.0/16"
gke_master_cidr    = "172.16.0.0/28"

# HTTP Access - Restringido
enable_public_http     = false
enable_restricted_http = true
corporate_ip_ranges = [
  "203.0.113.0/24",  # VPN de desarrollo
  "198.51.100.0/24"  # Oficina
]

# VPC Peering
enable_vpc_peering = false
```

**Cuándo Usar**:

- Desarrollo de aplicaciones Kubernetes
- Testing de GKE en desarrollo
- Desarrollo con acceso controlado
- Entornos de desarrollo seguros

---

## 🎯 Casos de Uso Especiales

### Caso 14: Multi-Workspace

**Descripción**: Usar el mismo proyecto para múltiples workspaces (plataformas diferentes).

**Características**:

- ✅ Múltiples workspaces en el mismo proyecto GCP
- ✅ Backend compartido con prefixes diferentes
- ✅ Recursos etiquetados por workspace

**Configuración**:

**Workspace 1: Platform**

```hcl
# shared-infra/environments/development/main.tf
backend "gcs" {
  bucket = "mi-proyecto-terraform-state"
  prefix = "platform/dev/shared/terraform"
}

# shared-infra/environments/development/terraform.tfvars
workspace = "platform"
registry_name = "platform-docker-images-dev"
```

**Workspace 2: Analytics**

```hcl
# shared-infra/environments/analytics-dev/main.tf
backend "gcs" {
  bucket = "mi-proyecto-terraform-state"
  prefix = "analytics/dev/shared/terraform"
}

# shared-infra/environments/analytics-dev/terraform.tfvars
workspace = "analytics"
registry_name = "analytics-docker-images-dev"
```

**Cuándo Usar**:

- Múltiples plataformas en el mismo proyecto
- Separación lógica de recursos
- Compartir infraestructura base
- Organización por dominio de negocio

---

### Caso 15: Solo Artifact Registry

**Descripción**: Usar solo el módulo de Artifact Registry sin red ni seguridad completa.

**Nota**: Actualmente el proyecto está diseñado para desplegar todo junto. Para usar solo Artifact Registry, necesitarías:

1. Comentar los módulos `network` y `security` en `main.tf`
2. Ajustar las dependencias en `artifact_registry`

**Cuándo Usar**:

- Solo necesitas repositorio Docker
- Ya tienes red y seguridad configuradas
- Migración gradual

---

### Caso 16: Solo Red (Network)

**Descripción**: Usar solo el módulo de red sin Artifact Registry ni seguridad completa.

**Nota**: Similar al caso anterior, requeriría ajustes en `main.tf`.

**Cuándo Usar**:

- Solo necesitas VPC y subnets
- Ya tienes Artifact Registry
- Infraestructura de red independiente

---

## 📊 Matriz de Casos de Uso

| Caso                        | GKE | HTTP Público | HTTP Restringido | VPC Peering | VPC Service Controls | Ambiente   |
| --------------------------- | --- | ------------ | ---------------- | ----------- | -------------------- | ---------- |
| 1. Básico (VMs)             | ❌  | ✅           | ❌               | ❌          | ❌                   | Dev/Stg    |
| 2. Con GKE                  | ✅  | ✅           | ❌               | ❌          | ❌                   | Stg/Prod   |
| 3. HTTP Público             | ⚙️  | ✅           | ❌               | ⚙️          | ⚙️                   | Cualquiera |
| 4. HTTP Restringido         | ⚙️  | ❌           | ✅               | ⚙️          | ⚙️                   | Dev/Stg    |
| 5. VPC Service Controls     | ⚙️  | ⚙️           | ⚙️               | ⚙️          | ✅                   | Prod       |
| 6. Break-Glass              | ⚙️  | ⚙️           | ⚙️               | ⚙️          | ⚙️                   | Todos      |
| 7. VPC Peering              | ⚙️  | ⚙️           | ⚙️               | ✅          | ⚙️                   | Stg/Prod   |
| 9. Desarrollo               | ❌  | ⚙️           | ⚙️               | ❌          | ❌                   | Dev        |
| 10. Staging                 | ⚙️  | ✅           | ❌               | ⚙️          | ❌                   | Stg        |
| 11. Producción              | ✅  | ✅           | ❌               | ⚙️          | ✅                   | Prod       |
| 12. Producción Completa     | ✅  | ✅           | ❌               | ✅          | ✅                   | Prod       |
| 13. Dev con GKE Restringido | ✅  | ❌           | ✅               | ❌          | ❌                   | Dev        |
| 14. Multi-Workspace         | ⚙️  | ⚙️           | ⚙️               | ⚙️          | ⚙️                   | Todos      |

**Leyenda**:

- ✅ Habilitado
- ❌ Deshabilitado
- ⚙️ Opcional/Configurable

---

## 🚀 Guía Rápida de Selección

### ¿Qué caso de uso elegir?

1. **¿Necesitas Kubernetes?**

   - ✅ Sí → Caso 2, 12, o 13
   - ❌ No → Caso 1

2. **¿Es producción?**

   - ✅ Sí → Caso 11 o 12
   - ❌ No → Caso 9 o 10

3. **¿Necesitas acceso público?**

   - ✅ Sí → Caso 3
   - ❌ No → Caso 4

4. **¿Tienes datos sensibles?**

   - ✅ Sí → Caso 5 (VPC Service Controls)
   - ❌ No → Sin VPC Service Controls

5. **¿Conectas con otros proyectos?**
   - ✅ Sí → Caso 7 (VPC Peering)
   - ❌ No → Sin peering

---

## 📝 Notas Finales

- Los casos de uso son **combinables** (excepto HTTP público/restringido)
- Puedes **empezar simple** y agregar características gradualmente
- **Siempre prueba en desarrollo** antes de producción
- Revisa la [Guía de Reutilización](reutilizacion.md) para adaptar a tu proyecto

---

## 🚀 Aplicar Casos de Uso

Para aplicar estos casos de uso, edita manualmente los archivos `terraform.tfvars` en el ambiente correspondiente según las configuraciones mostradas arriba, y luego usa los comandos de despliegue:

```bash
make deploy-dev    # Desplegar ambiente development
make deploy-qa     # Desplegar ambiente QA
make deploy-stg     # Desplegar ambiente staging (pregunta por GKE)
make deploy-prod    # Desplegar ambiente production (pregunta por GKE)
```

### Proceso Manual

1. **Selecciona el caso de uso** que deseas aplicar de la documentación arriba
2. **Copia la configuración** del caso de uso al archivo `terraform.tfvars` del ambiente correspondiente
3. **Ajusta los valores** según tu proyecto (project_id, workspace, etc.)
4. **Ejecuta el despliegue** usando `make deploy-*` correspondiente

### Ejemplo

```bash
# 1. Editar terraform.tfvars con la configuración del caso de uso deseado
cd shared-infra/environments/development
cp tfvars.example terraform.tfvars
# Editar terraform.tfvars con los valores del caso de uso

# 2. Desplegar el ambiente
cd ../..
make deploy-dev
```

### Requisitos

- **Terraform** instalado (>= 1.14.2)
- **Credenciales de GCP** configuradas
- **Backend configurado**: Los buckets de estado deben existir antes del despliegue
- **Archivo `terraform.tfvars`** en el ambiente correspondiente
- **Variables de contexto** configuradas (project_id, workspace, etc.)

### Notas Importantes

- ⚠️ **Configuración manual**: Debes editar `terraform.tfvars` manualmente según el caso de uso
- ⚠️ **Usa `make setup`**: Para configurar automáticamente variables comunes desde `.env`
- ⚠️ **Credenciales**: `terraform plan` requiere credenciales válidas de GCP configuradas
- ⚠️ **Backend**: Los buckets de estado deben existir antes del despliegue
- ⚠️ **Variables requeridas**: Asegúrate de tener todas las variables requeridas configuradas en `terraform.tfvars`

---

**Última actualización**: 2025
