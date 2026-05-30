#!/usr/bin/env bash
#
# fetch_specs.sh
# Descarga los 6 openapi.json de los microservicios SWARD y los guarda en
# ./openapi/ para servirlos de forma estatica (S3 / GitHub Pages) sin CORS.
#
# Uso:
#   # Desde servicios locales (puertos 8001..8006) - por defecto:
#   ./fetch_specs.sh
#
#   # Desde el gateway (ALB) ya desplegado:
#   BASE_MODE=gateway GATEWAY_BASE_URL=https://api.sward.example.com ./fetch_specs.sh
#
# Tras ejecutarlo, en index.html cambia cada `url` por su ruta local, ej.:
#   url: './openapi/ms-usuarios.json'
#
set -euo pipefail

OUT_DIR="$(cd "$(dirname "$0")" && pwd)/openapi"
mkdir -p "$OUT_DIR"

BASE_MODE="${BASE_MODE:-local}"
GATEWAY_BASE_URL="${GATEWAY_BASE_URL:-https://api.sward.example.com}"

# nombre|url_local|path_gateway
SERVICES=(
  "ms-usuarios|http://localhost:8001/openapi.json|/auth/openapi.json"
  "ms-integracion-lms|http://localhost:8002/openapi.json|/lms/openapi.json"
  "ms-trazabilidad|http://localhost:8003/openapi.json|/interactions/openapi.json"
  "ms-cursos-recursos|http://localhost:8004/openapi.json|/courses/openapi.json"
  "ms-recomendacion|http://localhost:8005/openapi.json|/recommendations/openapi.json"
  "ms-xai|http://localhost:8006/openapi.json|/xai/openapi.json"
)

echo "Modo: ${BASE_MODE}"
fail=0
for entry in "${SERVICES[@]}"; do
  IFS='|' read -r name local_url gw_path <<< "$entry"
  if [ "$BASE_MODE" = "gateway" ]; then
    url="${GATEWAY_BASE_URL}${gw_path}"
  else
    url="$local_url"
  fi
  echo "Descargando ${name} desde ${url} ..."
  if curl -fsSL "$url" -o "${OUT_DIR}/${name}.json"; then
    echo "  OK -> openapi/${name}.json"
  else
    echo "  ERROR: no se pudo descargar ${name} (${url})"
    fail=1
  fi
done

if [ "$fail" -ne 0 ]; then
  echo "Algunas descargas fallaron. Verifica que los servicios esten corriendo."
  exit 1
fi

echo "Listo. Specs guardados en ${OUT_DIR}"
