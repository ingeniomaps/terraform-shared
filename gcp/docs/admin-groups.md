# Creación de Grupos Admin para Shared-Infra

Este documento explica cómo crear los grupos de administradores (`admin_groups`) que se utilizan en `shared-infra` para gestionar permisos IAM.

## 📋 ¿Qué son los admin_groups?

Los `admin_groups` son **grupos de Google Workspace o Cloud Identity** que deben existir **antes** de aplicar Terraform. Terraform NO crea estos grupos, solo asigna roles IAM a grupos existentes.

### Diferencia con Service Accounts

- **Service Accounts** (como `ci-cd-writer`, `vm-reader`): Se crean automáticamente por Terraform
- **Admin Groups**: Deben existir previamente, creados manualmente en Google Workspace/Cloud Identity

## 🎯 Grupos Requeridos

Según la configuración en `shared-infra/environments/*/terraform.tfvars`, necesitas crear estos 4 grupos:

1. **`network-admins@roaxai.com`** - Administradores de red (control total sobre redes, subredes, firewalls)
2. **`developers@roaxai.com`** - Desarrolladores (acceso de solo lectura a recursos de red)
3. **`security-admins@roaxai.com`** - Administradores de seguridad (gestión de políticas de seguridad y IAM)
4. **`auditors@roaxai.com`** - Auditores (acceso de solo lectura para auditoría y compliance)

## 🚀 Opción 1: Google Workspace Admin Console (Recomendado)

Si tienes Google Workspace:

### Paso 1: Acceder a Admin Console

1. Ve a [Google Admin Console](https://admin.google.com)
2. Inicia sesión con una cuenta de administrador

### Paso 2: Navegar a Grupos

1. En el menú lateral, ve a **Directorio** → **Grupos**
2. O accede directamente: https://admin.google.com/ac/groups

### Paso 3: Crear Grupo

Para cada grupo necesario:

1. Haz clic en **"Crear grupo"** o **"Add group"**
2. Completa la información:
   - **Nombre del grupo**: `network-admins` (o el nombre correspondiente)
   - **Email del grupo**: `network-admins@roaxai.com` (debe usar tu dominio)
   - **Descripción**: Opcional (ej: "Administradores de red")
   - **Tipo de grupo**:
     - **"Grupo de correo"** - Si quieres que reciba emails
     - **"Grupo de seguridad"** - Si solo es para permisos (recomendado)
3. Haz clic en **"Crear grupo"** o **"Create group"**

### Paso 4: Agregar Miembros

Para cada grupo creado:

1. Abre el grupo haciendo clic en su nombre
2. Haz clic en **"Agregar miembros"** o **"Add members"**
3. Ingresa los emails de los usuarios que deben pertenecer al grupo
4. Haz clic en **"Agregar al grupo"** o **"Add to group"**

## 🔐 Opción 2: Cloud Identity (Sin Google Workspace)

Si solo usas Cloud Identity (sin Google Workspace):

### Paso 1: Acceder a Cloud Console

1. Ve a [Google Cloud Console](https://console.cloud.google.com)
2. Selecciona tu organización en el selector de proyectos

### Paso 2: Navegar a Identity

1. En el menú lateral, ve a **IAM & Admin** → **Identity**
2. O accede directamente: https://console.cloud.google.com/iam-admin/identity

### Paso 3: Crear Grupo

1. Haz clic en la pestaña **"Groups"**
2. Haz clic en **"Create Group"**
3. Completa la información:
   - **Group name**: `network-admins`
   - **Group email**: `network-admins@roaxai.com`
   - **Description**: Opcional
4. Haz clic en **"Create"**

### Paso 4: Agregar Miembros

1. Abre el grupo creado
2. Haz clic en **"Add members"**
3. Ingresa los emails de los usuarios
4. Haz clic en **"Add"**

## 💻 Opción 3: gcloud CLI

Si prefieres usar la línea de comandos:

### Crear Grupo

```bash
# Crear grupo network-admins
gcloud identity groups create network-admins@roaxai.com \
  --organization=391074161229 \
  --display-name="Network Admins" \
  --description="Administradores de red"

# Crear grupo developers
gcloud identity groups create developers@roaxai.com \
  --organization=391074161229 \
  --display-name="Developers" \
  --description="Desarrolladores - acceso de solo lectura"

# Crear grupo security-admins
gcloud identity groups create security-admins@roaxai.com \
  --organization=391074161229 \
  --display-name="Security Admins" \
  --description="Administradores de seguridad"

# Crear grupo auditors
gcloud identity groups create auditors@roaxai.com \
  --organization=391074161229 \
  --display-name="Auditors" \
  --description="Auditores - acceso de solo lectura para auditoría"
```

### Agregar Miembros

```bash
# Agregar usuario a network-admins
gcloud identity groups memberships add \
  --group-email=network-admins@roaxai.com \
  --member-email=usuario1@roaxai.com

# Agregar múltiples usuarios
gcloud identity groups memberships add \
  --group-email=developers@roaxai.com \
  --member-email=dev1@roaxai.com

gcloud identity groups memberships add \
  --group-email=developers@roaxai.com \
  --member-email=dev2@roaxai.com
```

## ✅ Verificación

Después de crear los grupos, verifica que existan:

### Desde gcloud CLI

```bash
# Listar todos los grupos
gcloud identity groups list --organization=391074161229

# Ver miembros de un grupo específico
gcloud identity groups memberships list \
  --group-email=network-admins@roaxai.com
```

### Desde la Consola

1. Ve a **IAM & Admin** → **Identity** → **Groups**
2. Verifica que los 4 grupos aparezcan en la lista
3. Abre cada grupo para verificar que tenga los miembros correctos

## ⚠️ Notas Importantes

### Permisos Requeridos

- Necesitas ser **Super Admin** de Google Workspace/Cloud Identity
- O tener permisos de **"Group Admin"** o **"User Management Admin"**

### Dominio

- El email del grupo **debe usar tu dominio** (`@roaxai.com` en tu caso)
- No puedes crear grupos con dominios que no controlas

### Tiempo de Propagación

- Los grupos pueden tardar **1-5 minutos** en estar disponibles para IAM
- Espera unos minutos después de crear los grupos antes de aplicar Terraform

### Verificación Pre-Terraform

**IMPORTANTE**: Antes de aplicar Terraform, verifica que los grupos existan. Si Terraform intenta asignar roles a grupos que no existen, fallará con un error como:

```
Error: Error creating IAM member: group:network-admins@roaxai.com not found
```

## 📝 Orden de Ejecución Recomendado

1. ✅ **Crear los 4 grupos** en Google Workspace/Cloud Identity
2. ✅ **Agregar usuarios** a cada grupo según corresponda
3. ✅ **Verificar** que los grupos existan (usando `gcloud` o la consola)
4. ✅ **Esperar 1-5 minutos** para propagación
5. ✅ **Aplicar Terraform** (asignará los roles IAM a esos grupos)

## 🔍 Troubleshooting

### Error: "Group not found"

**Causa**: El grupo no existe o el email es incorrecto.

**Solución**:
1. Verifica que el grupo exista: `gcloud identity groups list`
2. Verifica que el email en `terraform.tfvars` coincida exactamente
3. Espera unos minutos si acabas de crear el grupo

### Error: "Permission denied"

**Causa**: No tienes permisos para crear grupos.

**Solución**:
1. Contacta al administrador de Google Workspace/Cloud Identity
2. Solicita permisos de "Group Admin" o "User Management Admin"

### Los grupos existen pero Terraform falla

**Causa**: El grupo existe pero no está disponible aún para IAM.

**Solución**:
1. Espera 5-10 minutos después de crear el grupo
2. Verifica con: `gcloud identity groups describe network-admins@roaxai.com`
3. Intenta aplicar Terraform nuevamente

## 📚 Referencias

- [Google Workspace Admin Help - Crear grupos](https://support.google.com/a/answer/33343)
- [Cloud Identity Groups](https://cloud.google.com/identity/docs/groups)
- [gcloud identity groups](https://cloud.google.com/sdk/gcloud/reference/identity/groups)
