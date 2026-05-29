#!/usr/bin/env bash
# Valida el mensaje de commit segun la politica del repo:
#   1. Subject en formato Conventional Commits
#      (feat|fix|docs|style|refactor|test|chore|perf|ci|build|revert)
#   2. Subject <= 72 chars (V4 del /commit skill)
#   3. Sin trailers Co-authored-by de AI/bots (V8 del /commit skill)
# Bypass: commits Merge y Revert generados por Git.
# Uso: commit-msg.sh <ruta_archivo_mensaje>
set -e

msgfile="${1:?usage: commit-msg.sh <ruta_archivo_mensaje>}"
if [[ ! -f $msgfile ]]; then
	echo "commit-msg: archivo no encontrado: $msgfile"
	exit 1
fi

first_line=$(head -n1 "$msgfile")
body=$(cat "$msgfile")

# Merge / Revert auto-generados por Git: aceptados sin validar.
if [[ $first_line =~ ^(Merge\ |Revert\ ) ]]; then
	exit 0
fi

errors=()

# Validacion 1: Conventional Commits format
cnv_re='^(feat|fix|docs|style|refactor|test|chore|perf|ci|build|revert)(\([a-zA-Z0-9_/.-]+\))?!?:\ .+'
if [[ ! $first_line =~ $cnv_re ]]; then
	errors+=("Subject debe seguir Conventional Commits: tipo(scope)?: descripcion")
	errors+=("  Tipos: feat, fix, docs, style, refactor, test, chore, perf, ci, build, revert")
fi

# Validacion 2: Subject <= 72 chars
if ((${#first_line} > 72)); then
	errors+=("Subject de ${#first_line} chars (max 72). Acortalo o move detalle al body.")
fi

# Validacion 3: Sin trailers Co-authored-by de AI/bots.
# Match case-insensitive por nombres conocidos y dominios/emails de AI/bots.
ai_re='Co-authored-by:.*(\b(claude|copilot|chatgpt|gpt-?[345]|gemini|cursor|codex|aider|anthropic|openai|bard)\b|@anthropic\.com|@openai\.com|@cursor\.|@aider\.chat|noreply@anthropic|\+copilot@users\.noreply\.github\.com)'
if echo "$body" | grep -qiE "$ai_re"; then
	errors+=("Trailer Co-authored-by de AI/bot prohibido (V8).")
	errors+=("  Removelo del mensaje: ni Claude, ni Copilot, ni ChatGPT, etc.")
fi

if ((${#errors[@]} > 0)); then
	echo "commit-msg: validacion fallo"
	for e in "${errors[@]}"; do
		echo "  - $e"
	done
	echo ""
	echo "Subject actual: $first_line"
	exit 1
fi
