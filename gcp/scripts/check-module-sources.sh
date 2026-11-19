#!/usr/bin/env bash
# Verifica de dónde salen los módulos de Terraform del repo.
#
# Reglas:
#   1. Un `source` remoto (git/https) tiene que fijar un tag semver: `?ref=vX.Y.Z`.
#      Nada de rama (`ref=main`), commit suelto ni `source` sin `ref`.
#   2. Ningún `source` lleva credenciales en la URL (`https://<token>@...`).
#   3. Un `source` local tiene que existir dentro del repo.
#   4. Los módulos de PINNED_SOURCES tienen que salir exactamente de donde se indica.
#   5. No se versionan archivos `*override.tf`: cambian el `source` sin tocar main.tf.
#
# Uso: gcp/scripts/check-module-sources.sh   (desde cualquier lugar del repo)

set -euo pipefail

# archivo|módulo|source esperado. El VM de topology sale de este repo, no de terraform-machine.
PINNED_SOURCES=(
  "gcp/topology/main.tf|vm|../instance/modules/vm-docker"
)

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

errors=0
fail() {
  echo "✗ $1" >&2
  errors=$((errors + 1))
}

# Lista "archivo<TAB>línea<TAB>módulo<TAB>source" de cada bloque module versionado.
module_sources() {
  git ls-files -z -- '*.tf' | xargs -0 -r awk '
    FNR == 1 { mod = "" }
    /^[[:space:]]*module[[:space:]]+"/ {
      match($0, /"[^"]+"/); mod = substr($0, RSTART + 1, RLENGTH - 2); next
    }
    mod != "" && /^[[:space:]]*source[[:space:]]*=/ {
      match($0, /"[^"]*"/); print FILENAME "\t" FNR "\t" mod "\t" substr($0, RSTART + 1, RLENGTH - 2); mod = ""
    }
  '
}

declare -A seen
while IFS=$'\t' read -r file line mod src; do
  seen["$file|$mod"]="$src"
  where="$file:$line (module \"$mod\")"

  if [[ "$src" == ./* || "$src" == ../* ]]; then
    [[ -d "$(dirname "$file")/$src" ]] || fail "$where: el source local no existe: $src"
    continue
  fi

  if [[ "$src" =~ ://[^/@]+@ ]]; then
    fail "$where: el source lleva credenciales en la URL; usar el helper de credenciales de git"
    continue
  fi

  if [[ "$src" == git::* || "$src" == http* || "$src" == github.com/* || "$src" == git@* ]]; then
    if [[ ! "$src" =~ [?\&]ref=v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      fail "$where: source remoto sin tag fijo (?ref=vX.Y.Z): $src"
    fi
  fi
done < <(module_sources)

for entry in "${PINNED_SOURCES[@]}"; do
  IFS='|' read -r file mod want <<<"$entry"
  got="${seen["$file|$mod"]:-}"
  if [[ -z "$got" ]]; then
    fail "$file: no se encontró module \"$mod\" (actualizar PINNED_SOURCES si se movió)"
  elif [[ "$got" != "$want" ]]; then
    fail "$file (module \"$mod\"): source \"$got\", se esperaba \"$want\""
  fi
done

while IFS= read -r f; do
  fail "$f: los override no se versionan (están en .gitignore para pruebas locales)"
done < <(git ls-files -- '*override.tf' '*override.tf.json')

if ((errors > 0)); then
  echo "check-module-sources: $errors error(es)" >&2
  exit 1
fi
echo "check-module-sources: ok"
