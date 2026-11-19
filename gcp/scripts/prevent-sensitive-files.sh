#!/usr/bin/env bash
# Hook de pre-commit: rechaza estado, planes, tfvars reales y credenciales.
# Recibe los archivos a commitear como argumentos.
set -euo pipefail

for file in "$@"; do
  if [[ "$file" =~ \.(tfstate|tfstate\.|tfplan|plan\.json|\.json)$ ]] && [[ ! "$file" =~ \.(example|tfvars\.example)$ ]]; then
    echo "Error: No se pueden commitear archivos sensibles: $file"
    echo "Estos archivos están en .gitignore y no deben estar en el repositorio."
    exit 1
  fi
  if [[ "$file" =~ /(terraform\.tfvars|\.env)$ ]] && [[ ! "$file" =~ \.(example|tfvars\.example|tfvars\.dev|tfvars\.qa|tfvars\.stg|tfvars\.prod)$ ]]; then
    echo "Error: No se pueden commitear archivos de configuración sensibles: $file"
    echo "Usa archivos .example o .tfvars.* por ambiente."
    exit 1
  fi
  if [[ "$file" =~ /keys/ ]] || [[ "$file" =~ \.(pem|key)$ ]]; then
    echo "Error: No se pueden commitear credenciales: $file"
    exit 1
  fi
done
