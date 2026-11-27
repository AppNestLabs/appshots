#!/bin/bash
# Renderiza una o varias configuraciones de screenshot-config/ con el servidor MCP.
#
# Uso: ./render-config.sh <config> [<config>...]
#   <config> es el nombre del JSON sin extensión, relativo a screenshot-config/
#   (admite subcarpetas: waifu2x/ios-iphone-en-US waifu2x/play-es-ES).
#
# Las imágenes de entrada y la carpeta de salida (outDir) se resuelven dentro de FS_ROOT.
# Variables opcionales: APPSHOTS_FS_ROOT (por defecto /Users/alcaamado/Desarrollo/AppShots), APPSHOTS_PORT (3579).
set -euo pipefail
cd "$(dirname "$0")"

if [ $# -eq 0 ]; then
  echo "Error: indica al menos una configuración JSON de screenshot-config/" >&2
  echo "" >&2
  echo "Uso: $0 <config> [<config>...]" >&2
  echo "Ejemplos:" >&2
  echo "  $0 lottery" >&2
  echo "  $0 waifu2x/ios-iphone-en-US waifu2x/play-es-ES" >&2
  exit 1
fi

MCP_SERVER_PORT="${APPSHOTS_PORT:-3579}"
FS_ROOT="${APPSHOTS_FS_ROOT:-/Users/alcaamado/Desarrollo/AppShots}"

# Resuelve y valida todas las configuraciones antes de arrancar nada.
configs=()
for name in "$@"; do
  name="${name%.json}"
  name="${name#screenshot-config/}"
  file="screenshot-config/$name.json"
  [ -f "$file" ] || { echo "Error: el archivo de configuración no existe: $file" >&2; exit 1; }
  jq empty "$file" 2>/dev/null || { echo "Error: el archivo no es un JSON válido: $file" >&2; exit 1; }
  configs+=("$file")
done

[ -f mcp/dist/index.js ] || { echo "Error: falta mcp/dist/index.js (ejecuta bun run mcp:setup)" >&2; exit 1; }

echo "Iniciando MCP server en el puerto $MCP_SERVER_PORT (fs-root $FS_ROOT)..."
node mcp/dist/index.js --http "$MCP_SERVER_PORT" --fs-root "$FS_ROOT" &
MCP_PID=$!
trap 'kill $MCP_PID 2>/dev/null || true' EXIT

# Espera a que el servidor acepte conexiones (máximo 30 s) en lugar de un tiempo fijo.
for _ in $(seq 1 60); do
  if curl -s -o /dev/null "http://127.0.0.1:$MCP_SERVER_PORT/mcp" 2>/dev/null; then break; fi
  kill -0 "$MCP_PID" 2>/dev/null || { echo "Error: el MCP server se ha detenido al arrancar" >&2; exit 1; }
  sleep 0.5
done

failed=0
for file in "${configs[@]}"; do
  echo ""
  echo "Renderizando $file..."
  payload=$(jq -c '{jsonrpc: "2.0", id: 1, method: "tools/call", params: {name: "render_screenshots", arguments: .}}' "$file")
  response=$(curl -sS -X POST "http://127.0.0.1:$MCP_SERVER_PORT/mcp" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json, text/event-stream" \
    --data-binary "$payload")
  # La respuesta puede llegar como JSON o como evento SSE ("data: {...}").
  json=$(printf '%s\n' "$response" | sed -n 's/^data: //p' | tail -1)
  [ -n "$json" ] || json="$response"
  text=$(printf '%s' "$json" | jq -r '.result.content[0].text // .error.message // empty' 2>/dev/null || true)
  if [ "$(printf '%s' "$json" | jq -r '.result.isError // false' 2>/dev/null)" = "true" ] || [ -z "$text" ]; then
    echo "Error en $file:" >&2
    printf '%s\n' "${text:-$response}" >&2
    failed=1
    continue
  fi
  # Resumen: archivos generados y avisos (fuentes que no cargaron, imágenes ilegibles...).
  printf '%s' "$text" | jq -r '"  \(.files | length) capturas en \(.outDir)", (.warnings[]? | "  aviso: \(.)")' 2>/dev/null ||
    printf '%s\n' "$text"
done

echo ""
if [ "$failed" -ne 0 ]; then
  echo "Renderizado terminado con errores" >&2
  exit 1
fi
echo "Renderizado completado"
