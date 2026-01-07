# Pre-commit Hooks

Este documento describe la configuración de pre-commit hooks para el proyecto Terraform GCP.

## 📋 Descripción

Los pre-commit hooks son scripts que se ejecutan automáticamente antes de cada commit para asegurar la calidad del código y prevenir errores comunes.

## 🚀 Instalación

### Requisitos

- Python 3.6+ (para instalar `pre-commit`)
- Terraform (ya requerido por el proyecto)

### Pasos de Instalación

1. **Instalar pre-commit**:

```bash
# macOS
brew install pre-commit

# Linux (usando pip)
pip install pre-commit

# O usando pipx (recomendado)
pipx install pre-commit
```

2. **Instalar los hooks en el repositorio**:

```bash
pre-commit install
```

Esto creará un hook de Git que ejecutará los checks antes de cada commit.

3. **Instalar hooks adicionales** (opcional, para detect-secrets):

```bash
pip install detect-secrets
```

## 🔧 Hooks Configurados

### 1. Pre-commit Hooks Estándar

- **trailing-whitespace**: Elimina espacios en blanco al final de las líneas
- **end-of-file-fixer**: Asegura que los archivos terminen con una nueva línea
- **check-yaml**: Valida sintaxis de archivos YAML
- **check-json**: Valida sintaxis de archivos JSON
- **check-added-large-files**: Previene commits de archivos grandes (>1MB)
- **check-merge-conflict**: Detecta marcadores de conflictos de merge
- **detect-private-key**: Detecta claves privadas en el código
- **no-commit-to-branch**: Previene commits directos a `main` o `master`

### 2. Hooks Personalizados

#### prevent-sensitive-files

Previene commits de archivos sensibles:
- Archivos de estado de Terraform (`.tfstate`, `.tfstate.*`, `.tfplan`, `plan.json`)
- Archivos de configuración sensibles (`terraform.tfvars`, `.env`) que no sean `.example` o `.tfvars.*`
- Credenciales (`keys/`, `.pem`, `.key`)

#### check-terraform-state

Verifica que no se intenten commitear archivos de estado de Terraform. Los archivos `.tfstate` deben estar solo en el backend remoto (GCS).

### 3. Hooks de Terraform

- **terraform_fmt**: Formatea automáticamente archivos `.tf`
- **terraform_validate**: Valida sintaxis de Terraform
- **terraform_tflint**: Ejecuta `tflint` para detectar problemas
- **terraform_docs**: Genera/actualiza documentación automáticamente

### 4. Detección de Secretos

- **detect-secrets**: Detecta secretos y credenciales en el código usando `detect-secrets`

## 📝 Uso

### Ejecutar Hooks Manualmente

```bash
# Ejecutar en todos los archivos
pre-commit run --all-files

# Ejecutar solo en archivos staged
pre-commit run

# Ejecutar un hook específico
pre-commit run terraform_fmt --all-files
```

### Saltar Hooks (No Recomendado)

Si necesitas saltar los hooks en un commit específico (no recomendado):

```bash
git commit --no-verify -m "mensaje"
```

**⚠️ Advertencia**: Solo haz esto si es absolutamente necesario. Los hooks están ahí para protegerte.

### Actualizar Hooks

```bash
pre-commit autoupdate
```

Esto actualizará las versiones de los hooks a las más recientes.

## 🔍 Troubleshooting

### Error: "pre-commit: command not found"

**Solución**: Instala pre-commit siguiendo los pasos en "Instalación".

### Error: "terraform_fmt hook failed"

**Solución**: Los archivos necesitan formateo. Ejecuta:

```bash
terraform fmt -recursive .
```

O deja que el hook lo haga automáticamente (si está configurado para modificar archivos).

### Error: "prevent-sensitive-files hook failed"

**Solución**: Estás intentando commitear un archivo sensible. Verifica:

1. ¿Es un archivo de estado? → No debe estar en el repositorio
2. ¿Es un `terraform.tfvars`? → Usa `.tfvars.example` o `.tfvars.dev/qa/stg/prod`
3. ¿Es una credencial? → No debe estar en el repositorio

### Error: "detect-secrets hook failed"

**Solución**: Se detectó un posible secreto. Revisa el archivo y:

1. Si es un secreto real, muévelo fuera del repositorio o usa variables de entorno
2. Si es un falso positivo, agrégalo al baseline:

```bash
detect-secrets scan --baseline .secrets.baseline
```

### Los Hooks No Se Ejecutan

**Solución**: Verifica que los hooks estén instalados:

```bash
pre-commit install
```

Y verifica que el hook esté en `.git/hooks/pre-commit`:

```bash
ls -la .git/hooks/pre-commit
```

## 📚 Configuración

El archivo de configuración es `.pre-commit-config.yaml` en la raíz del proyecto.

### Personalizar Hooks

Puedes modificar `.pre-commit-config.yaml` para:

- Agregar nuevos hooks
- Deshabilitar hooks específicos
- Cambiar la configuración de hooks existentes

### Excluir Archivos

Para excluir archivos de ciertos hooks, agrega `exclude:` en la configuración del hook:

```yaml
- id: trailing-whitespace
  exclude: '\.md$'  # Excluir archivos Markdown
```

## 🎯 Mejores Prácticas

1. **Ejecuta hooks antes de commitear**: Usa `pre-commit run --all-files` antes de hacer push
2. **No saltes hooks**: Los hooks están ahí para protegerte de errores
3. **Mantén hooks actualizados**: Ejecuta `pre-commit autoupdate` periódicamente
4. **Revisa falsos positivos**: Si detect-secrets marca algo incorrectamente, actualiza el baseline
5. **Formatea automáticamente**: Deja que `terraform_fmt` formatee tu código automáticamente

## 🔗 Referencias

- [Pre-commit Documentation](https://pre-commit.com/)
- [Terraform Pre-commit Hooks](https://github.com/antonbabenko/pre-commit-terraform)
- [Detect Secrets](https://github.com/Yelp/detect-secrets)

---

**Última actualización**: 2025-01-07
