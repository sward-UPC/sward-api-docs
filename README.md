# sward-api-docs

Portal de documentacion **unificado** de la API del sistema **SWARD**, construido
con [Scalar API Reference](https://github.com/scalar/scalar) en modo
**multi-fuente** (multi-source).

El portal agrega los **6 microservicios** de SWARD bajo un unico gateway
(Application Load Balancer con enrutamiento por path, expuesto detras de
CloudFront) y permite navegar toda la API desde un solo sitio, cambiando entre
servicios con el selector superior.

## Que es

Un **sitio estatico** (un solo `index.html` con HTML + JS, **sin build ni
dependencias instaladas**). La pagina carga el componente
`@scalar/api-reference` desde el CDN de jsDelivr y lo configura con un array
`sources`: una entrada por microservicio, cada una apuntando al `openapi.json`
(generado automaticamente por FastAPI) de su servicio a traves del gateway.

El tema visual (paleta oscura `deepSpace`) esta replicado 1:1 del frontend de
SWARD (`sward-frontend/src/styles/theme.css`) mediante `customCss`.

## Que documenta

Las especificaciones OpenAPI de los 6 microservicios del backend de SWARD. El
backend se accede por un Application Load Balancer unico que enruta por path,
y cada servicio expone su `openapi.json` bajo el prefijo `/api/v1`:

| Servicio              | Dominios de la API                         | Ruta del spec                          | Puerto local |
| --------------------- | ------------------------------------------ | -------------------------------------- | ------------ |
| ms-usuarios           | Auth / Users / Admin                       | `/api/v1/auth/openapi.json`            | 8001         |
| ms-integracion-lms    | LMS (integracion con Moodle)               | `/api/v1/lms/openapi.json`             | 8002         |
| ms-trazabilidad       | Interactions / Students / Dashboard        | `/api/v1/interactions/openapi.json`    | 8003         |
| ms-cursos-recursos    | Courses / Resources                        | `/api/v1/courses/openapi.json`         | 8004         |
| ms-recomendacion      | Recommendations                            | `/api/v1/recommendations/openapi.json` | 8005         |
| ms-xai                | Explainability (XAI)                       | `/api/v1/xai/openapi.json`             | 8006         |

Cada microservicio expone ademas su propio `/scalar` individual; este portal
solo unifica la navegacion de todos en un sitio.

## Como se genera y se sirve

No hay paso de build. La generacion de los specs es responsabilidad de cada
microservicio (FastAPI los emite en `/openapi.json`); este repo solo los
consume.

- **En produccion**, `index.html` apunta a la URL base del gateway, definida en
  la constante `GATEWAY_BASE_URL` al inicio del `<script>`:

  ```js
  const GATEWAY_BASE_URL = 'https://d2z5yyv5sjm9sz.cloudfront.net';
  const API_V1 = GATEWAY_BASE_URL + '/api/v1';
  ```

  Scalar pide cada `openapi.json` en vivo al gateway. Esto requiere que los
  microservicios respondan con cabeceras **CORS** (lo hacen, ya que el portal se
  sirve desde un origen distinto).

- **Deploy automatico via GitHub Pages**: el workflow
  `.github/workflows/pages.yml` publica el contenido del repo en cada push a
  `main` (o manualmente con *workflow_dispatch*). No requiere reemplazar
  placeholders: la URL del gateway ya esta fijada en `index.html`.

- **Validacion en CI**: el workflow `.github/workflows/validate.yml` verifica en
  cada push/PR que `index.html` exista, referencie el CDN de Scalar y declare al
  menos las 6 fuentes `openapi.json`, ademas de un lint HTML.

## Ver en local

```bash
# Sirve la carpeta (cualquier servidor estatico sirve):
python -m http.server 8080
# abre http://localhost:8080
```

Por defecto apuntara al gateway de produccion. Si quieres apuntar a servicios
locales o evitar CORS, descarga los specs estaticos (siguiente seccion).

## Como actualizar

El contenido de la documentacion se actualiza solo: como Scalar lee los
`openapi.json` en vivo, cualquier cambio en los endpoints de un microservicio se
refleja automaticamente al recargar el portal. Solo necesitas tocar este repo si:

1. **Cambia la URL del gateway**: edita la constante `GATEWAY_BASE_URL` en
   `index.html`.
2. **Se agrega/quita/renombra un microservicio**: edita el array `sources` en
   `index.html` (anade o quita una entrada con su `title`, `slug` y `url`), y
   actualiza la lista de servicios en `fetch_specs.sh` si versionas specs
   estaticos.
3. **Cambia el tema visual**: ajusta el bloque `customCss` en `index.html`
   (manteniendo la paridad con `sward-frontend`).

Tras editar, haz push a `main`: GitHub Pages redesplegara automaticamente.

## Servir specs estaticos (sin CORS)

Si prefieres hosting puramente estatico sin depender de CORS en vivo, descarga
los specs y apunta cada `url` a un fichero local en `./openapi/`:

```bash
# Desde servicios locales (puertos 8001..8006), modo por defecto:
./fetch_specs.sh

# O desde el gateway ya desplegado:
BASE_MODE=gateway GATEWAY_BASE_URL=https://d2z5yyv5sjm9sz.cloudfront.net ./fetch_specs.sh
```

Esto guarda `openapi/ms-*.json`. Luego, en `index.html`, cambia cada `url` por
su ruta local, por ejemplo `url: './openapi/ms-usuarios.json'`. Por defecto los
specs descargados **no** se versionan (ver `.gitignore`).

## Estructura

```
sward-api-docs/
  index.html              Portal Scalar con las 6 fuentes (multi-source)
  fetch_specs.sh          Descarga los 6 openapi.json a openapi/ (opcional, anti-CORS)
  openapi/                Specs estaticos (generados por fetch_specs.sh; no versionados)
  .github/workflows/      CI: validate.yml (lint del portal) + pages.yml (deploy a Pages)
  README.md
  .gitignore
```
