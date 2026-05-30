# sward-api-docs

Portal de documentacion **unificado** de la API del sistema **SWARD**, construido con
[Scalar API Reference](https://github.com/scalar/scalar) en modo **multi-fuente**.

El portal agrega los **6 microservicios** del sistema bajo el gateway unico
(Application Load Balancer con enrutamiento por path) y permite navegar toda la
API desde un solo sitio, cambiando entre servicios con el selector superior.

## Que es

Un sitio estatico (HTML + JS, sin build) que carga el componente
`@scalar/api-reference` via CDN y lo configura con un array `sources`: una
entrada por microservicio, cada una apuntando al `openapi.json` (FastAPI) de su
servicio a traves del gateway.

## Microservicios y routing del gateway (ALB)

El backend se accede por un Application Load Balancer unico que enruta por path:

| Prefijos de path                              | Microservicio          | Puerto local |
| --------------------------------------------- | ---------------------- | ------------ |
| `/auth*` `/users*` `/admin*`                  | ms-usuarios            | 8001         |
| `/lms*`                                        | ms-integracion-lms     | 8002         |
| `/interactions*` `/students*` `/dashboard*`   | ms-trazabilidad        | 8003         |
| `/courses*` `/resources*`                     | ms-cursos-recursos     | 8004         |
| `/recommendations*`                            | ms-recomendacion       | 8005         |
| `/xai*`                                         | ms-xai                 | 8006         |

Cada microservicio expone su `openapi.json` (FastAPI) y su `/scalar`.

## Placeholder de deploy

`index.html` usa el placeholder **`__GATEWAY_BASE_URL__`** como URL base de
todos los `openapi.json`. En el deploy se reemplaza por el dominio real del ALB
(sin barra final), por ejemplo:

```bash
sed -i '' 's#__GATEWAY_BASE_URL__#https://api.sward.example.com#g' index.html   # macOS
sed -i    's#__GATEWAY_BASE_URL__#https://api.sward.example.com#g' index.html   # Linux
```

## Ver en local

```bash
# 1) (opcional) reemplaza el placeholder por un dominio que sirva los specs,
#    o usa fetch_specs.sh para servirlos estaticos (ver abajo).
# 2) sirve la carpeta:
python -m http.server 8080
# abre http://localhost:8080
```

> Nota CORS: si el portal apunta a `openapi.json` servidos en vivo (gateway o
> localhost de cada servicio), el navegador exige cabeceras CORS en esos
> servicios. Para evitarlo en hosting estatico, descarga los specs (siguiente
> seccion) y apunta las `url` a `./openapi/*.json`.

## Servir specs estaticos (sin CORS)

```bash
# Desde servicios locales (puertos 8001..8006):
./fetch_specs.sh

# O desde el gateway ya desplegado:
BASE_MODE=gateway GATEWAY_BASE_URL=https://api.sward.example.com ./fetch_specs.sh
```

Esto guarda `openapi/ms-*.json`. Luego, en `index.html`, cambia cada `url` por
su ruta local, por ejemplo `url: './openapi/ms-usuarios.json'`.

## Deploy

### Opcion A - S3 + CloudFront

```bash
sed -i 's#__GATEWAY_BASE_URL__#https://api.sward.example.com#g' index.html
aws s3 sync . s3://sward-api-docs --exclude ".git/*" --exclude ".github/*"
aws cloudfront create-invalidation --distribution-id <ID> --paths "/*"
```

### Opcion B - GitHub Pages

1. Reemplaza el placeholder `__GATEWAY_BASE_URL__` (en CI o antes de publicar).
2. Activa Pages en `Settings > Pages` apuntando a la rama `main` (raiz).
3. Recomendado: descargar los specs con `fetch_specs.sh` y versionarlos para
   evitar problemas de CORS, ya que GitHub Pages sirve solo estatico.

## Estructura

```
sward-api-docs/
  index.html              Portal Scalar con las 6 fuentes (multi-source)
  fetch_specs.sh          Descarga los 6 openapi.json a openapi/
  openapi/                Specs estaticos (generados por fetch_specs.sh)
  .github/workflows/      Validacion basica del portal
  README.md
  .gitignore
```
