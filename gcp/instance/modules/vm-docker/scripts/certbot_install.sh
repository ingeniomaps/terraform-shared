#!/bin/bash
set -euo pipefail

if command -v certbot &>/dev/null; then
  echo "Certbot ya instalado — skip"
else
  apt-get update -y
  apt-get install -y certbot
  certbot --version
  echo "=== Certbot instalado ==="
fi
