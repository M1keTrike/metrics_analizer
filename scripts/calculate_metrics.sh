#!/usr/bin/env bash
set -euo pipefail

# Script reutilizable para calcular métricas de un repositorio local.
# Uso:
#   bash scripts/calculate_metrics.sh /ruta/al/repo
# Imprime por stdout un JSON con:
#   pantallas, loc, horas, personas, commits, primer_commit, ultimo_commit, contribuyentes

REPO_DIR="${1:-}"

if [[ -z "$REPO_DIR" || ! -d "$REPO_DIR/.git" ]]; then
  echo "Uso: $0 /ruta/al/repo (debe ser un repo con .git)" >&2
  exit 2
fi

# Exclusiones para cloc (separadas por coma)
CLOC_EXCLUDES="node_modules,vendor,dist,build,.git,target,bin,obj,.next,.nuxt,__pycache__,venv,env,.venv,coverage,out"

# 2) LOC (code) en JSON. cloc ya descuenta blanks y comments del campo "code".
cloc_json="$(
  cloc "$REPO_DIR" \
    --json \
    --quiet \
    --exclude-dir="$CLOC_EXCLUDES"
)"

loc="$(echo "$cloc_json" | jq -r '.SUM.code // 0')"

# 3) Conteo de pantallas (heurística)
pantallas=0

# A) Frontend típicos
fe_count="$(find "$REPO_DIR" -type f \( \
    -name '*.html' -o -name '*.jsx' -o -name '*.tsx' -o -name '*.vue' -o -name '*.svelte' -o -name '*.astro' \
  \) \
  -not -path '*/node_modules/*' -not -path '*/dist/*' -not -path '*/build/*' -not -path '*/.git/*' \
  2>/dev/null | wc -l | tr -d ' ')"

# B) Android XML layouts: /res/layout/*.xml
android_xml_count="$(find "$REPO_DIR" -type f -path '*/res/layout/*.xml' -not -path '*/.git/*' 2>/dev/null | wc -l | tr -d ' ')"

# C) iOS storyboards/xib
ios_count="$(find "$REPO_DIR" -type f \( -name '*.storyboard' -o -name '*.xib' \) -not -path '*/.git/*' 2>/dev/null | wc -l | tr -d ' ')"

# D) XAML / Qt / JavaFX
ui_markup_count="$(find "$REPO_DIR" -type f \( -name '*.xaml' -o -name '*.ui' -o -name '*.fxml' \) -not -path '*/.git/*' 2>/dev/null | wc -l | tr -d ' ')"

# E) Flutter: Dart widgets que terminan en Page/Screen y extienden StatelessWidget/StatefulWidget
flutter_count="$(
  find "$REPO_DIR" -type f -name '*.dart' \
    -not -path '*/.dart_tool/*' -not -path '*/build/*' -not -path '*/.git/*' \
    -print0 2>/dev/null \
  | xargs -0 -r grep -nE 'class[[:space:]]+[A-Za-z0-9_]+(Page|Screen)[[:space:]]+extends[[:space:]]+(StatelessWidget|StatefulWidget)' \
  | cut -d: -f1 \
  | sort -u \
  | wc -l \
  | tr -d ' '
)"

# F) Android Kotlin/Java: Activity o Fragment (heurística simple)
android_code_count="$(
  find "$REPO_DIR" -type f \( -name '*.kt' -o -name '*.java' \) \
    -not -path '*/build/*' -not -path '*/.git/*' \
    -print0 2>/dev/null \
  | xargs -0 -r grep -nE 'class[[:space:]]+[A-Za-z0-9_]+[[:space:]]*:[[:space:]]*.*\b(Activity|Fragment)\b|class[[:space:]]+[A-Za-z0-9_]+[[:space:]]+extends[[:space:]]+.*\b(Activity|Fragment)\b' \
  | cut -d: -f1 \
  | sort -u \
  | wc -l \
  | tr -d ' '
)"

pantallas=$((fe_count + android_xml_count + ios_count + ui_markup_count + flutter_count + android_code_count))

# 4) Horas (heurística git-hours)
horas="$(python3 scripts/git_hours.py "$REPO_DIR")"

# 5) Commits totales
commits="$(git -C "$REPO_DIR" rev-list --all --count)"

# 6) Autores únicos (por email)
personas="$(git -C "$REPO_DIR" log --all --format='%ae' | sort -u | wc -l | tr -d ' ')"

# 7) Primer y último commit (YYYY-MM-DD)
primer_commit="$(git -C "$REPO_DIR" log --all --reverse --format='%ai' | head -1 | cut -d' ' -f1)"
ultimo_commit="$(git -C "$REPO_DIR" log --all --format='%ai' | head -1 | cut -d' ' -f1)"

# Contribuyentes: emails únicos (puedes cambiar a %an si prefieres)
contribuyentes="$(git -C "$REPO_DIR" log --all --format='%ae' | sort -u | jq -R -s -c 'split("\n") | map(select(length>0))')"

# Devolver JSON (sin los campos no/proyecto/repo/lenguajes: esos los agrega el workflow)
jq -n -c \
  --argjson pantallas "$pantallas" \
  --argjson loc "$loc" \
  --argjson horas "$horas" \
  --argjson personas "$personas" \
  --argjson commits "$commits" \
  --arg primer_commit "$primer_commit" \
  --arg ultimo_commit "$ultimo_commit" \
  --argjson contribuyentes "$contribuyentes" \
  '{
    pantallas: $pantallas,
    loc: $loc,
    horas: $horas,
    personas: $personas,
    commits: $commits,
    primer_commit: $primer_commit,
    ultimo_commit: $ultimo_commit,
    contribuyentes: $contribuyentes
  }'