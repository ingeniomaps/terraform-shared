# Guía de Control y Operaciones de Terraform

Este documento describe los comandos comunes y las mejores prácticas para gestionar este proyecto de Terraform, tanto en desarrollo local como en pipelines de CI/CD.

## Flujo de Trabajo Local

### 1. Autenticación con GCP

Para ejecutar Terraform localmente, primero necesitas autenticarte con Google Cloud. El método recomendado es usar `gcloud` para obtener credenciales de usuario temporales.

```sh
gcloud auth application-default login
```

terraform plan -out=tfplan && terraform show -json tfplan > plan.json
Este comando abrirá tu navegador para que inicies sesión con tu cuenta de Google y autorices el acceso a la CLI.

### 2. Planificación y Estimación de Costos

Para previsualizar los cambios y estimar su costo antes de aplicarlos, puedes usar una combinación de Terraform e Infracost.

```sh
# 1. Genera un plan de ejecución binario
terraform plan -out=tfplan

# 2. Convierte el plan a formato JSON para que Infracost pueda leerlo
terraform show -json tfplan > plan.json

# 3. Ejecuta Infracost para obtener un desglose de los costos
infracost breakdown --path plan.json
```

# Artifact

## Autenticación en CI/CD: Workload Identity Federation

#### Workload Identity Federation (más seguro, sin key JSON)

Para entornos automatizados como GitHub Actions o Bitbucket Pipelines, el método más seguro y recomendado para autenticarse con GCP es **Workload Identity Federation**. Este enfoque elimina la necesidad de gestionar y almacenar claves de Service Account (archivos JSON), que son credenciales de larga duración y representan un riesgo de seguridad.

1. Configuras federación de identidades en GCP: le dices a Google que confíe en un proveedor externo (GitHub o Bitbucket).

### ¿Cómo funciona?

2. Creas un Service Account con los permisos que necesites.
1. **Configurar la Confianza en GCP**: Se configura un "Workload Identity Pool" en GCP para que confíe en un proveedor de identidad externo (IdP), como GitHub o Bitbucket. Esto se hace a través del estándar OpenID Connect (OIDC).

1. Configuras un OIDC token en tu pipeline CI/CD:
1. **Crear una Service Account**: Se crea una Service Account en GCP con los permisos IAM mínimos necesarios para que el pipeline de CI/CD pueda gestionar los recursos de Terraform.

- GitHub Actions: permissions: id-token: write y actions/setup-gcloud puede usar workload_identity_provider.
- Bitbucket: también soporta OIDC tokens.

3.  **Vincular la Identidad Externa**: Se establece una política IAM que permite a las identidades del proveedor externo (ej: un repositorio o rama específica de GitHub) suplantar la Service Account creada en el paso anterior.

4.  Cuando el CI corre, Google emite un token temporal para la Service Account, sin usar JSON.
5.  **Configurar el Pipeline de CI/CD**: En el pipeline (ej: GitHub Actions), se configura para que solicite un token OIDC al proveedor.

    - **GitHub Actions**: Se añade la sección `permissions` al workflow para permitir la emisión de un `id-token`. La acción `google-github-actions/auth` se encarga de intercambiar este token por credenciales de GCP.

    ```yaml
    permissions:
      contents: 'read'
      id-token: 'write'
    ```

6.  **Ejecución del Pipeline**: Durante la ejecución, el pipeline obtiene un token OIDC de corta duración, lo presenta a GCP, y GCP le devuelve un token de acceso temporal para la Service Account. Terraform utiliza este token para autenticarse y realizar las operaciones.
