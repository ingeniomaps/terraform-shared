# Gestión de Credenciales de GCP

## ⚠️ IMPORTANTE

Las credenciales **NO deben ser incluidas en el repositorio**. El directorio `keys/` está excluido por `.gitignore`.

## Métodos de Autenticación

### Opción 1: gcloud CLI (Recomendado para Desarrollo Local)

**Ventajas**:

- ✅ No requiere archivos JSON
- ✅ Más seguro (no hay archivos de credenciales en disco)
- ✅ Fácil de rotar
- ✅ Funciona automáticamente con Terraform

**Configuración**:

```bash
# Autenticar con tu cuenta de usuario
gcloud auth login

# Configurar credenciales por defecto para aplicaciones
gcloud auth application-default login

# Verificar autenticación
gcloud auth list
```

**Uso**: Una vez configurado, Terraform usará automáticamente estas credenciales. No necesitas configurar nada más.

**Nota**: Este método funciona automáticamente si no defines `credentials_file` en `terraform.tfvars`. El provider de Google usará las credenciales de gcloud cuando `credentials` sea `null`.

---

### Opción 2: Service Account Key en Terraform (Recomendado)

**Cuándo usar**:

- ✅ No necesitas configurar variables de entorno
- ✅ Credenciales específicas por ambiente
- ✅ Más simple y directo
- ✅ Funciona bien en desarrollo local y CI/CD

**Cómo obtener**:

1. Ve a **IAM & Admin > Service Accounts** en Google Cloud Console
2. Selecciona o crea la cuenta de servicio correspondiente
3. Ve a la pestaña **"Keys"**
4. Crea una nueva key (tipo **JSON**)
5. Descarga el archivo JSON y guárdalo en `keys/`

**Estructura recomendada en `keys/`**:

```
keys/
├── account_service_dev.json    # Credenciales para desarrollo
├── account_service_qa.json     # Credenciales para QA (opcional)
├── account_service_stg.json    # Credenciales para staging
└── account_service_prod.json  # Credenciales para producción
```

**Configuración en Terraform**:

Agrega la variable `credentials_file` en tu archivo `terraform.tfvars`:

```hcl
# shared-infra/environments/development/terraform.tfvars
project_id = "mi-proyecto-dev-123456"
region     = "us-central1"
env        = "dev"
workspace  = "platform"

# Especificar el archivo de credenciales (ruta relativa desde la raíz del proyecto)
credentials_file = "keys/account_service_dev.json"
```

**Uso**:

```bash
# No necesitas configurar variables de entorno
cd shared-infra/environments/development
terraform init
terraform plan
terraform apply
```

**Ventajas**:

- ✅ No necesitas `export GOOGLE_APPLICATION_CREDENTIALS`
- ✅ La configuración está en el código (terraform.tfvars)
- ✅ Fácil de cambiar entre ambientes
- ✅ Funciona automáticamente

**⚠️ IMPORTANTE - Coexistencia de Métodos**:

Ambos métodos coexisten perfectamente:

- **Si defines `credentials_file`** en `terraform.tfvars`: Usa el archivo JSON especificado
- **Si NO defines `credentials_file`** (o lo dejas como `null`): El provider usa el orden de precedencia estándar:
  1. Variable de entorno `GOOGLE_APPLICATION_CREDENTIALS` (si está configurada)
  2. Credenciales de gcloud (`gcloud auth application-default login`)
  3. Metadata service (si estás corriendo en GCP)

**Ejemplo de coexistencia**:

```hcl
# terraform.tfvars
# Opción A: Sin credentials_file - usa gcloud auth
project_id = "mi-proyecto-dev-123456"
# credentials_file no está definido → usa gcloud auth automáticamente

# Opción B: Con credentials_file - usa el archivo JSON
project_id      = "mi-proyecto-dev-123456"
credentials_file = "keys/account_service_dev.json"
```

En ambos casos, Terraform funcionará correctamente.

---

### Opción 2b: Service Account Key con Variable de Entorno (Alternativa)

**Cuándo usar**:

- ✅ Cuando prefieres no incluir la ruta en `terraform.tfvars`
- ✅ Cuando necesitas cambiar credenciales sin modificar archivos
- ✅ Para CI/CD donde las credenciales vienen de secretos

**Configuración**:

```bash
# Opción A: Variable de entorno (recomendado)
export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/keys/account_service_dev.json"

# Opción B: Ruta absoluta
export GOOGLE_APPLICATION_CREDENTIALS="/ruta/completa/keys/account_service_dev.json"

# Verificar que funciona
gcloud auth activate-service-account --key-file="$GOOGLE_APPLICATION_CREDENTIALS"
```

**Uso con Terraform**:

```bash
# Configurar antes de ejecutar Terraform
export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/keys/account_service_dev.json"

# Ahora puedes ejecutar Terraform normalmente
cd shared-infra/environments/development
terraform init
terraform plan
```

**Nota**: Si usas `credentials_file` en `terraform.tfvars`, esta variable de entorno será ignorada. El provider usará el archivo especificado en `terraform.tfvars`.

**Prioridad de credenciales**:

1. **`credentials_file` en `terraform.tfvars`** (más alta prioridad)
2. Variable de entorno `GOOGLE_APPLICATION_CREDENTIALS`
3. Credenciales de gcloud (`gcloud auth application-default login`)
4. Metadata service (si estás en GCP)

---

### Opción 3: Google Secret Manager (Recomendado para Producción)

**Cuándo usar**:

- ✅ Producción
- ✅ Cuando necesitas rotación automática de credenciales
- ✅ Cuando quieres centralizar la gestión de secretos

**Configuración**:

1. Sube el Service Account Key a Secret Manager:

   ```bash
   gcloud secrets create service-account-key-dev \
     --data-file=keys/account_service_dev.json \
     --project=tu-proyecto
   ```

2. Accede al secreto en tu pipeline o aplicación:

   ```bash
   gcloud secrets versions access latest \
     --secret=service-account-key-dev \
     --project=tu-proyecto > /tmp/key.json

   export GOOGLE_APPLICATION_CREDENTIALS=/tmp/key.json
   ```

---

## Seguridad

### Buenas Prácticas

- ✅ **NUNCA** subas archivos de credenciales al repositorio
- ✅ **NUNCA** compartas credenciales por email, chat o mensajes
- ✅ **Rota las credenciales periódicamente** (cada 90 días recomendado)
- ✅ **Usa el principio de menor privilegio**: Solo los permisos necesarios
- ✅ **Usa Service Accounts específicas por ambiente** cuando sea posible
- ✅ **Elimina credenciales antiguas** cuando ya no las necesites

### Permisos Recomendados

Para Terraform, la Service Account necesita:

- `roles/owner` o `roles/editor` (para crear recursos)
- `roles/storage.admin` (para gestionar buckets de estado)
- `roles/iam.serviceAccountAdmin` (para crear Service Accounts)
- `roles/compute.admin` (para crear VPCs, subnets, etc.)

**Nota**: En producción, considera usar permisos más granulares según tus necesidades.

### Rotación de Credenciales

1. **Crear nueva key**:

   ```bash
   # En GCP Console o con gcloud
   gcloud iam service-accounts keys create nueva-key.json \
     --iam-account=nombre@proyecto.iam.gserviceaccount.com
   ```

2. **Actualizar en uso**:

   - Reemplazar el archivo en `keys/`
   - Actualizar variable de entorno
   - Verificar que funciona

3. **Eliminar key antigua**:
   ```bash
   gcloud iam service-accounts keys delete KEY_ID \
     --iam-account=nombre@proyecto.iam.gserviceaccount.com
   ```

---

## Troubleshooting

### Error: "Could not find default credentials"

**Causa**: No hay credenciales configuradas.

**Solución**:

```bash
# Opción 1: Usar gcloud
gcloud auth application-default login

# Opción 2: Configurar variable de entorno
export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/keys/account_service_dev.json"
```

### Error: "Permission denied"

**Causa**: La Service Account no tiene los permisos necesarios.

**Solución**: Verificar permisos en IAM & Admin > Service Accounts.

### Error: "Invalid credentials"

**Causa**: La key ha expirado o fue revocada.

**Solución**: Generar una nueva key y actualizar la configuración.

---

## Referencias

- [Google Cloud Authentication](https://cloud.google.com/docs/authentication)
- [Service Accounts Best Practices](https://cloud.google.com/iam/docs/best-practices-service-accounts)
- [Terraform GCP Provider Authentication](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/getting_started)
