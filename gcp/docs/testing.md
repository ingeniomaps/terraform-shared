# Testing del Proyecto Terraform

Este documento describe el sistema de testing implementado para el proyecto Terraform GCP.

## 📋 Tests Disponibles

El proyecto incluye una suite completa de tests que verifica:

1. **Formato** (`test-format`): Verifica que todos los archivos `.tf` estén correctamente formateados
2. **Validación** (`test-validate`): Valida la sintaxis de Terraform en todos los módulos
3. **Linting** (`test-lint`): Ejecuta `tflint` para detectar problemas de estilo y mejores prácticas
4. **Seguridad** (`test-security`): Ejecuta `checkov` y `tfsec` para detectar problemas de seguridad

## 🚀 Uso Rápido

### Ejecutar Todos los Tests

```bash
make test
```

Este comando ejecuta todos los tests en secuencia y muestra un resumen al final.

### Ejecutar Tests con Output Detallado

```bash
make test-verbose
```

Muestra el output completo de cada test, útil para debugging.

### Ejecutar Tests Individuales

```bash
# Solo formato
make test-format

# Solo validación
make test-validate

# Solo linting (requiere tflint)
make test-lint

# Solo seguridad (requiere checkov o tfsec)
make test-security
```

## 📦 Requisitos

### Requeridos

- **Terraform** >= 1.14.2 (ya requerido por el proyecto)
- **Make** (para usar `make test`)

### Opcionales (pero recomendados)

- **tflint**: Para linting avanzado
  ```bash
  # macOS
  brew install tflint

  # Linux
  wget https://github.com/terraform-linters/tflint/releases/latest/download/tflint_linux_amd64.zip
  unzip tflint_linux_amd64.zip
  sudo mv tflint /usr/local/bin/

  # O usando go
  go install github.com/terraform-linters/tflint@latest
  ```

- **checkov**: Para análisis de seguridad
  ```bash
  pip install checkov
  ```

- **tfsec**: Para análisis de seguridad alternativo
  ```bash
  # macOS
  brew install tfsec

  # Linux
  wget https://github.com/aquasecurity/tfsec/releases/latest/download/tfsec-linux-amd64
  chmod +x tfsec-linux-amd64
  sudo mv tfsec-linux-amd64 /usr/local/bin/tfsec
  ```

## 🔍 Detalles de Cada Test

### 1. Test de Formato

**Comando**: `make test-format`
**Script**: `terraform fmt -check -recursive .`

Verifica que todos los archivos `.tf` estén correctamente formateados según las convenciones de Terraform.

**Si falla**: Ejecuta `make fmt` para corregir automáticamente el formato.

### 2. Test de Validación

**Comando**: `make test-validate`
**Script**: `terraform validate` en cada módulo

Valida la sintaxis y configuración de Terraform en todos los módulos. Ejecuta `terraform init -backend=false` y luego `terraform validate` en cada directorio.

**Nota**: Este test no requiere credenciales de GCP, solo valida la sintaxis.

### 3. Test de Linting

**Comando**: `make test-lint`
**Herramienta**: `tflint`

Ejecuta `tflint` en todos los módulos para detectar:
- Problemas de estilo
- Mejores prácticas no seguidas
- Configuraciones potencialmente problemáticas

**Si no está instalado**: El test se omite con un mensaje informativo.

### 4. Test de Seguridad

**Comando**: `make test-security`
**Herramientas**: `checkov` y `tfsec`

Ejecuta análisis de seguridad en el código Terraform para detectar:
- Configuraciones inseguras
- Exposición de secretos
- Permisos excesivos
- Mejores prácticas de seguridad

**Si no están instalados**: Los tests se omiten con mensajes informativos.

## 📊 Interpretación de Resultados

### Salida Exitosa

```
========================================
Terraform Testing Suite
========================================

========================================
1. Testing Format (terraform fmt)
========================================
✓ Todos los archivos tienen formato correcto

========================================
2. Testing Validation (terraform validate)
========================================
✓ Validación en shared-infra/environments/development
✓ Validación en shared-infra/environments/qa
...

========================================
Resumen de Tests
========================================
✓ Passed: 25
✗ Failed: 0
⊘ Skipped: 3

========================================
✓ Todos los tests pasaron
========================================
```

### Salida con Errores

```
========================================
Resumen de Tests
========================================
✓ Passed: 20
✗ Failed: 5
⊘ Skipped: 3

========================================
✗ Algunos tests fallaron
========================================
💡 Ejecuta con VERBOSE=true para ver detalles
```

## 🔧 Integración en CI/CD

### Ejemplo para GitHub Actions

```yaml
name: Terraform Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.14.2

      - name: Install tflint
        run: |
          wget https://github.com/terraform-linters/tflint/releases/latest/download/tflint_linux_amd64.zip
          unzip tflint_linux_amd64.zip
          sudo mv tflint /usr/local/bin/

      - name: Install checkov
        run: pip install checkov

      - name: Run tests
        run: make test
```

### Ejemplo para Bitbucket Pipelines

```yaml
image: hashicorp/terraform:1.14.2

pipelines:
  default:
    - step:
        name: Run Tests
        script:
          - apk add --no-cache make python3 py3-pip
          - pip3 install checkov
          - wget -O tflint.zip https://github.com/terraform-linters/tflint/releases/latest/download/tflint_linux_amd64.zip
          - unzip tflint.zip && chmod +x tflint && mv tflint /usr/local/bin/
          - make test
```

## 🐛 Troubleshooting

### Test de Formato Falla

**Problema**: `make test-format` reporta archivos con formato incorrecto.

**Solución**:
```bash
make fmt
```

Esto formateará automáticamente todos los archivos.

### Test de Validación Falla

**Problema**: `make test-validate` reporta errores de validación.

**Solución**:
1. Revisa el error específico en el output
2. Verifica que las variables requeridas estén definidas
3. Verifica que los módulos referenciados existan
4. Ejecuta `terraform init` manualmente en el directorio problemático

### tflint No Encuentra Problemas pero el Test Falla

**Problema**: `tflint` puede retornar código de salida != 0 incluso si no hay errores críticos.

**Solución**: Revisa el output de `tflint` para ver si hay warnings que debas corregir.

### checkov o tfsec No Están Instalados

**Problema**: Los tests de seguridad se omiten.

**Solución**: Instala las herramientas siguiendo las instrucciones en la sección "Requisitos" arriba.

## 📚 Referencias

- [Terraform fmt](https://www.terraform.io/docs/cli/commands/fmt.html)
- [Terraform validate](https://www.terraform.io/docs/cli/commands/validate.html)
- [tflint](https://github.com/terraform-linters/tflint)
- [checkov](https://www.checkov.io/)
- [tfsec](https://github.com/aquasecurity/tfsec)

---

**Última actualización**: 2025-01-07
