#!/usr/bin/env bash
# Hook de pre-commit: rechaza cualquier estado de Terraform en el stage (incluye .tfstate.backup).
set -euo pipefail

if git diff --cached --name-only | grep -E "\.tfstate|\.tfstate\."; then
  echo "Error: No se pueden commitear archivos de estado de Terraform."
  echo "Los archivos .tfstate deben estar solo en el backend remoto (GCS)."
  exit 1
fi
