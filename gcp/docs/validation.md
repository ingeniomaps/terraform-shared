# Validación y Testing

## Comandos de Validación

### Formato de Código

```bash
# Verificar formato (sin modificar)
make fmt-check

# Formatear código
make fmt
```

### Validación de Sintaxis

```bash
# Validar todos los módulos
make validate
```

**Nota**: Requiere `terraform init` y credenciales de GCP configuradas.

### Plan de Ejecución

```bash
# Plan interactivo: selecciona un directorio
make plan

# Apply interactivo: selecciona un directorio
make apply
```

**Nota**: Requiere:
- Backend configurado y accesible
- Credenciales de GCP válidas
- Variables definidas en `terraform.tfvars`

## Checklist de Validación

### Pre-commit

- [ ] `make fmt-check` pasa sin errores
- [ ] No hay archivos `.tf` sin formatear
- [ ] `make validate` pasa en todos los módulos

### Pre-deploy

- [ ] `terraform plan` no muestra errores
- [ ] No hay warnings críticos en el plan
- [ ] Variables requeridas están definidas

### Post-deploy

- [ ] `terraform apply` se ejecuta sin errores
- [ ] Recursos se crean correctamente en GCP
- [ ] Outputs son correctos

## Mejoras Futuras

- [ ] Configurar pre-commit hooks para validación automática
- [ ] Integrar validación en CI/CD pipeline
- [ ] Agregar tests automatizados con Terratest o similar
