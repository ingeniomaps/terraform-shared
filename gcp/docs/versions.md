# Verificación de Versiones - Terraform y Providers

## Versiones Actuales

### Terraform

- **Versión actual**: `>= 1.14.2`
- **Estado**: ✅ Versión reciente y estable

### Google Provider

- **Versión actual**: `>= 7.0`
- **Estado**: ✅ Versión reciente y estable

## Verificación Periódica

### Verificación Automática (Recomendado)

Usa el script de verificación automática con Makefile:

```bash
# Verificar versiones más recientes
make check-versions
```

Este script:

- ✅ Busca automáticamente las versiones más recientes de Terraform y el provider Google
- ✅ Compara con las versiones actuales en el proyecto
- ✅ Muestra un resumen de actualizaciones disponibles
- ✅ **NO actualiza nada** - solo informa (decisión del equipo)
- ✅ Muestra enlaces a changelogs para revisar cambios antes de actualizar

**Ejemplo de salida:**

```
Versión más reciente de Terraform: 1.14.3
Versión más reciente del provider Google: 7.14.1

⚠ Actualizaciones disponibles:
  → main.tf (Terraform: 1.14.2 -> 1.14.3)
```

### Verificación Manual

1. **Terraform**:

   ```bash
   # Ver versión instalada
   terraform version

   # Verificar releases en GitHub
   # https://github.com/hashicorp/terraform/releases
   ```

2. **Google Provider**:

   ```bash
   # Ver versión en el registry
   # https://registry.terraform.io/providers/hashicorp/google/latest

   # O verificar en terraform.lock.hcl después de terraform init
   ```

### Recomendaciones

- ✅ Las versiones actuales (`>= 1.14.2` y `>= 7.0`) son recientes y estables
- ⚠️ Verificar periódicamente (cada 3-6 meses) si hay versiones más recientes
- ⚠️ Antes de actualizar, revisar:
  - [Changelog de Terraform](https://github.com/hashicorp/terraform/blob/main/CHANGELOG.md)
  - [Changelog del Provider Google](https://github.com/hashicorp/terraform-provider-google/blob/main/CHANGELOG.md)
  - Breaking changes que puedan afectar el código

### Proceso de Actualización

Si se encuentran versiones más recientes:

1. **Probar en desarrollo primero**

   ```bash
   cd shared-infra/environments/development
   terraform init -upgrade
   terraform plan
   ```

2. **Verificar compatibilidad**

   - Revisar que todos los recursos sigan funcionando
   - Verificar que no haya deprecations

3. **Actualizar versiones en todos los archivos**

   - `shared-infra/environments/development/main.tf`
   - `bootstrap/global`
   - `bootstrap/global`
   - `bootstrap/global/main.tf`

4. **Documentar cambios**
   - Actualizar este archivo con las nuevas versiones
   - Documentar cualquier breaking change encontrado

## Notas

- Las versiones con `>=` permiten actualizaciones menores y parches automáticamente
- Para mayor control, se puede usar `~>` para permitir solo parches
- Ejemplo: `~> 1.14.2` permite `1.14.x` pero no `1.15.x`
