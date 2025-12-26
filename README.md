# Proyecto de Infraestructura con Terraform

Este repositorio contiene el código de Terraform para definir, aprovisionar y gestionar nuestra infraestructura en Google Cloud Platform (GCP).

## Requisitos Previos

Antes de comenzar, asegúrate de tener instaladas las siguientes herramientas:

- [Terraform](https://www.terraform.io/downloads.html) (versión X.Y.Z o superior)
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) (CLI de `gcloud`)
- Infracost (Opcional, para estimación de costos)

---

## 🚀 Flujo de Trabajo Local

Sigue estos pasos para realizar cambios en la infraestructura desde tu máquina local.

### 1. Autenticación

Primero, autentícate con Google Cloud usando la CLI de `gcloud`. Esto generará credenciales de usuario temporales que Terraform usará automáticamente.

```sh
gcloud auth application-default login
```

### 2. Inicialización

Navega al directorio del proyecto y ejecuta `terraform init`. Este comando descargará los proveedores necesarios y configurará el backend para el estado remoto.

```sh
terraform init
```

### 3. Configuración de Variables

Crea un archivo `terraform.tfvars` para definir los valores de las variables específicas de tu entorno. **Este archivo no debe ser subido al repositorio**.

Puedes usar `terraform.tfvars.example` (si existe) como plantilla.

### 4. Planificación y Revisión

Para previsualizar los cambios que se aplicarán, ejecuta `terraform plan`.

```sh
terraform plan
```

#### Estimación de Costos (Opcional)

Puedes obtener un desglose detallado del impacto en costos de tus cambios usando Infracost.

```sh
# 1. Genera un plan binario y conviértelo a JSON
terraform plan -out=tfplan
terraform show -json tfplan > plan.json

# 2. Analiza el plan con Infracost
infracost breakdown --path plan.json
```

### 5. Aplicación de Cambios

Una vez que hayas revisado el plan y estés de acuerdo con los cambios, aplícalos.

```sh
terraform apply
```

---

## 🤖 CI/CD - Automatización

Para los despliegues automatizados a través de pipelines (ej. GitHub Actions, Bitbucket Pipelines), utilizamos **Workload Identity Federation**.

Este es el método de autenticación más seguro con GCP, ya que evita el uso de claves de Service Account de larga duración (archivos JSON). El pipeline obtiene un token de identidad de corta duración (OIDC token) que se intercambia por credenciales de acceso temporales de GCP.

Para más detalles sobre la implementación, consulta la Guía de Control y Operaciones.

---

## 📦 Gestión del Estado (State Management)

**¡Importante!** El estado de Terraform (`.tfstate`) **no se almacena localmente**. Utilizamos un backend remoto (como un bucket de Google Cloud Storage) para almacenar el estado de forma segura y centralizada.

Esto ofrece dos ventajas clave:

1.  **Seguridad**: Evita que información sensible (como contraseñas o IPs) se guarde en archivos locales o se suba a Git.
2.  **Colaboración**: Permite que múltiples miembros del equipo trabajen en la misma infraestructura y proporciona bloqueo de estado para prevenir conflictos (`state locking`).

El archivo `.gitignore` está configurado para ignorar explícitamente cualquier archivo de estado (`.tfstate`, `.tfstate.backup`) que se pueda generar localmente por error.
