# Gestión de Outputs en Terraform

## 📋 Diferencia Importante

Hay una diferencia crucial entre:

1. **`outputs.tf`** - Archivos de **definición** de outputs (código fuente)
2. **`plan.out` / `plan.json`** - Archivos **generados** por `terraform plan` (binarios)

## ✅ Archivos que SÍ deben estar en el repositorio

### `outputs.tf` - Definiciones de Outputs

Los archivos `outputs.tf` **SÍ deben estar en el repositorio** porque:

- ✅ Son **código fuente** (definiciones de qué outputs exponer)
- ✅ Son **parte de la infraestructura como código**
- ✅ Permiten que otros módulos/proyectos consuman estos outputs
- ✅ Son necesarios para que Terraform funcione correctamente

**Ejemplo**:
```hcl
# shared-infra/modules/network/outputs.tf
output "vpc_id" {
  description = "ID de la VPC creada"
  value       = google_compute_network.vpc.id
}
```

Este archivo **debe estar en el repo** porque define qué información se expone.

## ❌ Archivos que NO deben estar en el repositorio

### `plan.out` / `plan.json` - Planes Generados

Los archivos de plan **NO deben estar en el repositorio** porque:

- ❌ Son **archivos binarios** generados por `terraform plan`
- ❌ Contienen **información sensible** (valores de variables, IDs de recursos)
- ❌ Son **específicos del ambiente** (dev/stg/prod)
- ❌ Son **temporales** (se regeneran cada vez que ejecutas `terraform plan`)
- ❌ Pueden contener **credenciales o secretos** en texto plano
- ❌ Son **grandes** y no aportan valor al control de versiones

**Ejemplo de lo que contiene un plan**:
- Valores de todas las variables (incluyendo secretos)
- IDs de recursos existentes
- Estado actual de la infraestructura
- Diferencias propuestas

### `*.tfstate` - Estado de Terraform

Los archivos de estado también están en `.gitignore` porque:

- ❌ Contienen **información sensible** (valores de outputs, IDs de recursos)
- ❌ Son **específicos del ambiente**
- ❌ Deben almacenarse en **backend remoto** (GCS en este proyecto)
- ❌ Pueden contener **secretos** en texto plano

## 📁 Archivos en `.gitignore` relacionados con Outputs

```gitignore
# Plan files (generados por terraform plan)
*.tfplan
plan.out
plan.json

# Estado de Terraform (contiene valores de outputs)
*.tfstate
*.tfstate.*
```

## 🔍 Verificación

### ¿Qué archivos de outputs están en el repo?

```bash
# Buscar archivos outputs.tf (deben estar en el repo)
find . -name "outputs.tf" -type f

# Verificar que NO están en .gitignore
grep -r "outputs.tf" .gitignore
# (No debería encontrar nada)
```

### ¿Qué archivos de plan están ignorados?

```bash
# Verificar que plan.out está en .gitignore
grep "plan.out" .gitignore
# Debería mostrar: plan.out
```

## 💡 Mejores Prácticas

### 1. Outputs como Código (outputs.tf)

✅ **SÍ incluir en el repo**:
- Definiciones de outputs en `outputs.tf`
- Documentación de qué outputs están disponibles
- Ejemplos de uso de outputs

### 2. Planes Generados

❌ **NO incluir en el repo**:
- `plan.out` (archivo binario del plan)
- `plan.json` (versión JSON del plan)
- Cualquier archivo generado por `terraform plan -out=...`

### 3. Valores de Outputs

❌ **NO incluir en el repo**:
- Valores reales de outputs (están en el estado)
- Archivos con valores hardcodeados de outputs

✅ **SÍ documentar**:
- Qué outputs están disponibles
- Cómo usar los outputs
- Ejemplos de consumo de outputs

## 🎯 Resumen

| Tipo de Archivo | ¿En el Repo? | Razón |
|-----------------|--------------|-------|
| `outputs.tf` | ✅ **SÍ** | Código fuente, definiciones |
| `plan.out` | ❌ **NO** | Binario generado, información sensible |
| `plan.json` | ❌ **NO** | JSON generado, información sensible |
| `*.tfstate` | ❌ **NO** | Estado remoto, información sensible |
| Documentación de outputs | ✅ **SÍ** | Ayuda a otros desarrolladores |

## 📚 Referencias

- [Terraform Outputs Documentation](https://www.terraform.io/docs/language/values/outputs.html)
- [Terraform State Management](https://www.terraform.io/docs/language/state/index.html)
- [Terraform Plan Files](https://www.terraform.io/docs/cli/commands/plan.html#saving-a-plan-file)

---

**Conclusión**: Los archivos `outputs.tf` (definiciones) **SÍ deben estar en el repo**, pero los archivos `plan.out` (planes generados) **NO deben estar** porque contienen información sensible y son temporales.

