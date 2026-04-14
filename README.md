# metrics-collector

Repositorio con un **GitHub Action** para calcular métricas de producción de una lista de repositorios y subir los resultados como **artifact**.

## ¿Qué calcula?

Para cada repositorio:

- **LOC (code)**: líneas de código sin blancos ni comentarios (usando `cloc` en JSON).
- **Pantallas**: heurística basada en extensiones/patrones (HTML/React/Vue/etc., Android, Flutter, iOS, XAML, etc.).
- **Horas**: heurística tipo *git-hours* basada en diferencias de tiempo entre commits por autor.
- **Commits**: total (`git rev-list --all --count`).
- **Personas**: autores únicos (por email).
- **Primer / último commit**.
- **Lenguajes**: porcentajes desde la API de GitHub (`/languages`).

El resultado final se guarda como `metricas.json` y se publica como artifact.

---

## 1) Ejecutar el workflow manualmente

1. Ve a la pestaña **Actions** del repositorio.
2. Selecciona el workflow **Collect production metrics**.
3. Haz clic en **Run workflow**.
4. Pega el JSON en el input **repos_json**.
5. Ejecuta.

---

## 2) Formato del input (lista de repos)

Debes pasar un **JSON válido** con este formato (array de objetos):

```json
[
  {"owner": "M1keTrike", "repo": "Voltio_CHMMA_microservices", "nombre": "Voltio CHMMA"},
  {"owner": "M1keTrike", "repo": "AccesGate_CHM-M", "nombre": "AccesGate"}
]
```

- `owner`: dueño del repo.
- `repo`: nombre del repositorio.
- `nombre`: nombre visible para el reporte.

---

## 3) Descargar el artifact

Cuando termine la ejecución:

1. Entra al run del workflow.
2. Baja hasta la sección **Artifacts**.
3. Descarga **metricas**.
4. Dentro encontrarás `metricas.json`.

---

## 4) Acceso a repos privados y/o de otras cuentas (METRICS_PAT)

Por defecto el workflow usa `secrets.GITHUB_TOKEN`. Esto suele servir para repos del mismo owner/org con permisos adecuados.

Si necesitas analizar repos privados a los que el `GITHUB_TOKEN` no tenga acceso (por ejemplo, repos privados en otra cuenta/organización), crea un **Personal Access Token** y guárdalo como secret:

- Nombre del secret: `METRICS_PAT`
- Permisos recomendados:
  - `repo` (para clonar repos privados)
  - `read:user` (opcional; útil para ciertos escenarios de lectura)

Luego, en el repo:
**Settings → Secrets and variables → Actions → New repository secret**, agrega `METRICS_PAT`.

El workflow usará automáticamente `METRICS_PAT` si está definido; si no, usará `GITHUB_TOKEN`.

---

## Notas

- `scripts/calculate_metrics.sh` calcula métricas locales (LOC, pantallas, horas, commits, autores, fechas y contribuyentes).
- `scripts/git_hours.py` implementa la heurística de horas en Python puro.