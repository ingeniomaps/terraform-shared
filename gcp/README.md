# Terraform GCP - Infraestructura Compartida

Este proyecto gestiona la infraestructura compartida en Google Cloud Platform (GCP) usando Terraform. Incluye la configuración de redes, seguridad, logging, y gestión del estado remoto de Terraform.

## 📋 Tabla de Contenidos

- [Propósito](#propósito)
- [Estructura del Proyecto](#estructura-del-proyecto)
- [Requisitos Previos](#requisitos-previos)
- [Configuración Inicial](#configuración-inicial)
- [Uso](#uso)
- [Módulos](#módulos)
- [Variables Principales](#variables-principales)
- [Ambientes](#ambientes)
- [Seguridad](#seguridad)

## 🎯 Propósito

Este proyecto proporciona:

- **Gestión de Estado Remoto**: Buckets de GCS para almacenar el estado de Terraform
- **Infraestructura Compartida**: Redes (VPC, subnets, firewall), seguridad (IAM, Service Accounts), logging y alertas
- **Artifact Registry**: Repositorio Docker para imágenes de contenedores
- **Soporte Multi-ambiente**: Configuración separada para desarrollo, staging y producción
- **Preparado para GKE**: Configuración opcional para Google Kubernetes Engine

## 📁 Estructura del Proyecto

```
.
├── docs/                          # Documentación del proyecto
│   ├── credentials.md             # Gestión de credenciales
│   ├── backends.md                # Configuración de backends
│   ├── versions.md                # Gestión de versiones
│   ├── validation.md               # Validación y testing
│   └── environments.md            # Gestión de entornos
├── keys/                          # Credenciales (NO incluir en repo)
├── shared-infra/                  # Infraestructura compartida
│   ├── environments/
│   │   └── development/           # Configuración del ambiente de desarrollo
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       ├── terraform.tfvars   # Valores reales (NO incluir en repo)
│   │       └── tfvars.example     # Ejemplo de configuración
│   └── modules/
│       ├── network/               # Módulo de red (VPC, subnets, firewall)
│       ├── security/              # Módulo de seguridad (IAM, Service Accounts, logging)
│       └── artifact_registry/     # Módulo de Artifact Registry
└── terraform-state/               # Gestión del estado remoto
    ├── environments/
    │   ├── production/            # Bucket de estado para producción
    │   └── staging/               # Bucket de estado para staging
    ├── global/                    # Bucket de estado global
    └── modules/
        └── gcs_bucket/            # Módulo para crear buckets de estado
```

## 🔧 Requisitos Previos

### Software Requerido

- **Terraform** >= 1.14.2
- **Google Cloud SDK** (gcloud) instalado y configurado
- **Git** para clonar el repositorio
- **Make** (opcional, para usar comandos del Makefile)

### Permisos GCP

Necesitas los siguientes permisos en GCP:

- `roles/owner` o permisos equivalentes para crear recursos
- Acceso al proyecto de GCP donde se desplegará la infraestructura
- Permisos para crear Service Accounts y asignar roles IAM

### Autenticación

1. **Opción 1: Service Account Key (Recomendado para CI/CD)**

   ```bash
   export GOOGLE_APPLICATION_CREDENTIALS="/path/to/account_service_dev.json"
   ```

2. **Opción 2: gcloud CLI**

   ```bash
   gcloud auth application-default login
   ```

3. **Opción 3: Google Secret Manager**
   - Configura las credenciales en Secret Manager
   - Usa el secreto en tu pipeline CI/CD

Ver [docs/credentials.md](docs/credentials.md) para más detalles.

## 🚀 Configuración Inicial

### 1. Clonar el Repositorio

```bash
git clone <repository-url>
cd terraform/gcp
```

### 2. Configurar Credenciales

Sigue las instrucciones en [docs/credentials.md](docs/credentials.md) para obtener y configurar las credenciales de GCP.

### 3. Crear Buckets de Estado (Primera vez)

Antes de usar la infraestructura compartida, necesitas crear los buckets de estado. Ver [docs/backends.md](docs/backends.md) para detalles completos.

```bash
cd terraform-state/global
terraform init
terraform plan
terraform apply
```

Repite para `terraform-state/environments/production` y `terraform-state/environments/staging` si es necesario.

### 4. Configurar Variables

Copia el archivo de ejemplo y edítalo con tus valores:

```bash
cd shared-infra/environments/development
cp tfvars.example terraform.tfvars
# Edita terraform.tfvars con tus valores
```

**⚠️ IMPORTANTE**: El archivo `terraform.tfvars` contiene información sensible y está excluido del repositorio por `.gitignore`.

## 📖 Uso

### Desplegar Infraestructura Compartida

```bash
cd shared-infra/environments/development

# Inicializar Terraform
terraform init

# Revisar el plan
terraform plan

# Aplicar cambios
terraform apply
```

### Destruir Infraestructura

```bash
terraform destroy
```

**⚠️ ADVERTENCIA**: En producción, los buckets de estado tienen `prevent_destroy = true` para evitar destrucciones accidentales.

### Ver Outputs

```bash
terraform output
```

## 🧩 Módulos

### Módulo Network

Gestiona la red VPC, subnets, firewall rules y Cloud NAT.

**Recursos principales:**

- VPC con routing global
- Subnet para VMs tradicionales
- Subnet para GKE (opcional) con secondary ranges para pods y services
- Firewall rules para tráfico interno, HTTP/HTTPS, health checks, SSH vía IAP
- Cloud NAT para acceso a internet desde instancias privadas

**Outputs:**

- `vpc_id`, `vpc_name`, `vpc_self_link`
- `vm_subnet_id`, `vm_subnet_cidr`, `vm_subnet_name`
- `gke_subnet_id`, `gke_subnet_name` (si GKE está habilitado)
- `gke_pods_range_name`, `gke_services_range_name`

### Módulo Security

Gestiona IAM, Service Accounts, logging y alertas.

**Service Accounts creadas:**

- `ci-cd-writer`: Para pipelines CI/CD (push de imágenes Docker)
- `vm-reader`: Para VMs (pull de imágenes Docker)
- `dev-reader`: Para desarrolladores (opcional, solo lectura)
- `break-glass`: Cuenta de emergencia con permisos temporales

**Recursos:**

- IAM bindings para grupos administrativos
- Logging sinks y buckets
- Alert policies
- VPC Service Controls (opcional)
- Organization policies

**Outputs:**

- `ci_cd_writer_email`
- `vm_reader_email`
- `dev_reader_email` (si está habilitado)
- `break_glass_email`

### Módulo Artifact Registry

Crea un repositorio Docker en Artifact Registry.

**Características:**

- Tags inmutables habilitados
- IAM configurado para readers y writers
- Políticas de limpieza opcionales

## 🔑 Variables Principales

### Variables de Contexto

- `project_id`: ID del proyecto en GCP
- `workspace`: Nombre del workspace (ej: "roax")
- `region`: Región principal (default: "us-central1")
- `env`: Ambiente (dev, stg, pre, prod)

### Variables de Red

- `vm_subnet_cidr`: CIDR de la subnet para VMs (default: "10.0.0.0/24")
- `enable_gke`: Habilitar recursos para GKE (default: false)
- `gke_subnet_cidr`: CIDR para nodes de GKE (default: "10.0.10.0/24")
- `gke_pods_cidr`: CIDR para pods (default: "10.1.0.0/16")
- `gke_services_cidr`: CIDR para services (default: "10.2.0.0/16")
- `enable_public_http`: Permitir HTTP/HTTPS público (default: true)
- `enable_restricted_http`: HTTP/HTTPS solo desde IPs corporativas (default: false)
- `enable_vpc_peering`: Habilitar VPC peering (default: false)

### Variables de Seguridad

- `organization_id`: ID de la organización de GCP
- `allowed_domains`: Lista de dominios permitidos para IAM
- `admin_groups`: Objeto con grupos de administradores por rol
- `enable_dev_reader`: Crear Service Account para desarrolladores (default: false)
- `enable_vpc_service_controls`: Habilitar VPC Service Controls (default: false)
- `break_glass_max_session_duration`: Duración máxima de sesión break-glass en segundos (default: 3600)

### Variables de Artifact Registry

- `registry_name`: Nombre del repositorio Docker

Ver `shared-infra/environments/development/tfvars.example` para un ejemplo completo.

## 🌍 Ambientes

El proyecto soporta múltiples ambientes:

- **development**: Ambiente de desarrollo
- **staging**: Ambiente de staging/pre-producción
- **production**: Ambiente de producción

Cada ambiente tiene su propia configuración en `shared-infra/environments/<env>/`.

### Configuración por Ambiente

| Variable                      | Dev   | Staging | Prod  |
| ----------------------------- | ----- | ------- | ----- |
| `enable_vpc_service_controls` | false | false   | true  |
| `prevent_destroy` (buckets)   | false | true    | true  |
| `enable_dev_reader`           | true  | false   | false |

## 🔒 Seguridad

### Buenas Prácticas Implementadas

- ✅ Credenciales excluidas del repositorio (`.gitignore`)
- ✅ SSH solo vía Identity-Aware Proxy (IAP)
- ✅ Service Accounts con principio de menor privilegio
- ✅ Break-glass account para emergencias
- ✅ Logging y alertas configurados
- ✅ VPC Service Controls opcional para producción
- ✅ Organization policies aplicadas

### Gestión de Credenciales

**NUNCA:**

- Subas credenciales al repositorio
- Compartas credenciales por email o chat
- Uses credenciales con permisos excesivos

**SIEMPRE:**

- Rota las credenciales periódicamente
- Usa Service Accounts específicas por propósito
- Revisa los permisos regularmente

## 📝 Ejemplos

### Desplegar Infraestructura de Desarrollo

```bash
cd shared-infra/environments/development
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

### Habilitar GKE

Edita `terraform.tfvars`:

```hcl
enable_gke = true
gke_subnet_cidr = "10.0.10.0/24"
gke_pods_cidr = "10.1.0.0/16"
gke_services_cidr = "10.2.0.0/16"
gke_master_cidr = "172.16.0.0/28"
```

### Habilitar VPC Peering

```hcl
enable_vpc_peering = true
peer_project_id = "otro-proyecto-id"
peer_vpc_name = "otra-vpc-name"
```

## 🛠️ Comandos Útiles (Makefile)

El proyecto incluye un `Makefile` con comandos útiles:

```bash
# Ver ayuda de comandos disponibles
make help

# Configurar proyecto para nuevo workspace/proyecto (requiere .env)
make setup

# Ver cambios sin aplicarlos (dry-run)
make setup-dry-run

# Verificar versiones más recientes de Terraform y providers
make check-versions

# Formatear código Terraform
make fmt

# Verificar formato sin modificar
make fmt-check

# Validar sintaxis (requiere terraform init)
make validate

# Limpiar archivos temporales
make clean
```

### ⚡ Configuración Rápida para Nuevo Proyecto

Para reutilizar el proyecto en un nuevo workspace/proyecto:

```bash
# 1. Copiar plantilla de configuración
cp .env.example .env

# 2. Editar .env con tus valores
nano .env

# 3. Ver cambios sin aplicarlos (opcional)
make setup-dry-run

# 4. Aplicar configuración automáticamente
make setup
```

Ver [Guía de Reutilización](docs/reutilizacion.md) para más detalles.

### 🎯 Casos de Uso

El proyecto soporta múltiples casos de uso documentados. Ver [Casos de Uso](docs/casos-de-uso.md) para ejemplos completos de configuración para diferentes escenarios (VMs, GKE, seguridad, conectividad).

## 🐛 Troubleshooting

### Error: Backend configuration changed

Si cambias la configuración del backend, necesitas migrar el estado:

```bash
terraform init -migrate-state
```

### Error: Credentials not found

Verifica que `GOOGLE_APPLICATION_CREDENTIALS` esté configurado o que hayas hecho login con `gcloud auth application-default login`.

### Error: Permission denied

Verifica que tu cuenta o Service Account tenga los permisos necesarios en GCP.

### Verificar versiones disponibles

Usa el script de verificación automática:

```bash
make check-versions
```

### Recuperar Estado Perdido del Módulo Global

Si has perdido el archivo `.tfstate` del módulo global, puedes recuperarlo desde GCP:

```bash
# Requiere archivo .env con PROJECT_ID, BUCKET_NAME (o BUCKET_PREFIX), y REGION
make recover-global
```

El comando verifica si el bucket existe en GCP y lo importa automáticamente. Si no existe, muestra un mensaje claro indicando que no existe.

Ver [Recuperación de Estado](docs/state-recovery.md) para más detalles.

## 📚 Documentación Adicional

- [Gestión de Credenciales](docs/credentials.md) - Cómo obtener y configurar credenciales
- [Configuración de Backends](docs/backends.md) - Detalles sobre backends de Terraform
- [Gestión de Versiones](docs/versions.md) - Verificación y actualización de versiones
- [Validación y Testing](docs/validation.md) - Comandos y checklist de validación
- [Testing Automatizado](docs/testing.md) - Suite completa de tests (formato, validación, linting, seguridad)
- [Gestión de Entornos](docs/environments.md) - Crear y gestionar entornos adicionales
- [Guía de Reutilización](docs/reutilizacion.md) - Cómo reutilizar el proyecto para diferentes proyectos/workspaces
- [Casos de Uso](docs/casos-de-uso.md) - Todos los casos de uso posibles del proyecto con ejemplos
- [Recuperación de Estado](docs/state-recovery.md) - Cómo recuperar el estado de Terraform

## 🔗 Recursos Externos

- [Documentación de Terraform](https://www.terraform.io/docs)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Google Cloud Platform](https://cloud.google.com/docs)

## 🧪 Testing

El proyecto incluye una suite completa de tests automatizados:

```bash
# Ejecutar todos los tests
make test

# Tests individuales
make test-format      # Verificar formato
make test-validate    # Validar sintaxis
make test-lint        # Linting (requiere tflint)
make test-security    # Seguridad (requiere checkov/tfsec)

# Tests con output detallado
make test-verbose
```

Ver [docs/testing.md](docs/testing.md) para más detalles sobre los tests disponibles y cómo instalarlos.

## 🔒 Pre-commit Hooks

El proyecto incluye pre-commit hooks para asegurar la calidad del código:

```bash
# Instalar pre-commit
pip install pre-commit

# Instalar hooks en el repositorio
pre-commit install

# Ejecutar manualmente
pre-commit run --all-files
```

Los hooks incluyen:
- Formato automático de Terraform
- Validación de sintaxis
- Prevención de commits de archivos sensibles
- Detección de secretos
- Verificación de archivos de estado

Ver [docs/pre-commit.md](docs/pre-commit.md) para más detalles.

## 🤝 Contribución

1. Crea una rama para tu cambio
2. Realiza tus modificaciones
3. Ejecuta los tests: `make test`
4. Verifica con `terraform fmt` y `terraform validate`
5. Crea un Pull Request

## 📄 Licencia

[Especificar licencia si aplica]

---

**Última actualización**: 2025
