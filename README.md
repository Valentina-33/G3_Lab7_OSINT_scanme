# G3 · Lab 07: Automatización de OSINT con n8n

Pipeline de reconocimiento OSINT (pasivo y activo) totalmente automatizado en **n8n**, orquestado sobre Docker. A partir de un único insumo (un dominio o una IP), el flujo ejecuta en paralelo los módulos de reconocimiento, toma capturas de pantalla de los hosts vivos y consolida todo en un único `reporte.html` reproducible.

- **Asignatura:** Fundamentos de Seguridad de la Información (FDSI)
- **Institución:** Escuela Colombiana de Ingeniería Julio Garavito
- **Instructor:** Santiago Naranjo Melo
- **Grupo:** G3
- **Objetivo auditado:** `scanme.nmap.org` (host público que el proyecto Nmap habilita para pruebas)
## Documento: 
https://pruebacorreoescuelaingeduco-my.sharepoint.com/:w:/g/personal/keyla_serna-i_mail_escuelaing_edu_co/IQDsbNpkImJKR5E0CTaSbndMAeEUprUzVfxHzZfzdL_ftOk?e=3fHPTA
## Equipo

- Keyla Yunuette Serna Illescas
- Paula Valentina Lozano Castañeda

---

## Arquitectura del pipeline

Un solo disparador recibe el objetivo y lo normaliza; a partir de ahí se abren en paralelo las ramas de reconocimiento, y la rama de capturas se ejecuta después porque depende de la lista de hosts vivos.

| Módulo | Qué hace | Herramienta / nodo usado |
|--------|----------|--------------------------|
| **EX·01: Normalización** | Detecta si el insumo es IP o dominio y resuelve el que falte (dominio a IP o IP a dominio) | Form Trigger + IF + HTTP Request (DNS) |
| **EX·02: Subdominios** | Enumeración pasiva combinando dos fuentes | crt.sh + HackerTarget |
| **EX·03: Hosts vivos** | Filtra cuáles subdominios responden (código de estado y título) | HTTP Request + Code |
| **EX·04: Fingerprint** | Stack tecnológico por host | Code (análisis de cabeceras y cuerpo) |
| **EX·05: Puertos** | Puertos abiertos, servicio y versión sobre la IP | Nmap (vía Execute Command) |
| **EX·06: Correos y brechas** | Correos del dominio y si aparecen en brechas | Code + HTTP Request |
| **EX·07: Archivos públicos** | URLs de documentos (PDF, DOCX, XLSX) expuestos | Code |
| **EX·08: Cabeceras** | Calificación de cabeceras HTTP de seguridad | Mozilla HTTP Observatory |
| **EX·09: Capturas** | Una captura PNG por host vivo, sin intervención manual | Servicio propio Playwright + Chromium |
| **EX·11: Reporte** | Consolida todas las ramas en un único `reporte.html` | Merge + Code |

> El módulo **EX·10 (Síntesis con IA)** era opcional (bonus) y no quedó implementado. Ver la sección de limitaciones.

### Servicio de capturas propio

En lugar de un servicio externo, el equipo montó su propio microservicio de capturas (carpeta `screenshot-service/`): un pequeño servidor **Flask + Playwright (Chromium headless)** que expone un endpoint `/capture?url=...`, al que n8n le hace una petición por cada host vivo. Las imágenes se guardan con el formato obligatorio `hostname_YYYYMMDD_HHmm.png`.

---

## Estructura del repositorio

```
.
├── docker-compose.yml        : levanta n8n + el servicio de capturas
├── Dockerfile                : imagen de n8n con Nmap horneado
├── My workflow.json          : el workflow completo de n8n (importable)
├── reporte.html              : reporte final generado por el pipeline
├── screenshot-service/
│   ├── Dockerfile            : imagen Flask + Playwright
│   └── app.py                : servidor de capturas
└── screenshots/              : una imagen PNG por host vivo
```

---

## Requisitos previos

- Docker
- Docker Compose (v2)

El objetivo activo (puertos, capturas, fingerprint) solo debe ejecutarse contra `scanme.nmap.org` o contra un activo propio. No usar el pipeline contra terceros no autorizados.

---

## Despliegue

```bash
# 1. Clonar el repositorio
git clone https://github.com/Valentina-33/G3_Lab7_OSINT_scanme.git
cd G3_Lab7_OSINT_scanme

# 2. Construir y levantar los contenedores (n8n + capturas)
docker compose up -d --build

# 3. Verificar que ambos estén arriba
docker ps
```

Abre n8n en `http://localhost:5678` y crea tu usuario local la primera vez.

> La variable `N8N_ENABLE_EXECUTE_COMMAND=true` (en `docker-compose.yml`) es la que habilita el nodo Execute Command; sin ella, el módulo de puertos no funciona.

### Importar el workflow

1. En n8n: menú **⋮** y luego **Import from File…**
2. Selecciona `My workflow.json`.
3. El flujo aparece completo en el lienzo.

### Ejecutar el pipeline

1. Abre el nodo **On form submission** y copia la URL del formulario de prueba.
2. En el formulario, ingresa el objetivo: `scanme.nmap.org`
3. El flujo corre de principio a fin y deja el resultado en `reporte.html` y las capturas en `screenshots/`.

---

## Entregables generados

- **`reporte.html`**: informe único con la estructura pedida:
  - I. Resumen Ejecutivo
  - II. Objetivo, Alcance y Metodología
  - III. Superficie de Ataque (subdominios y hosts vivos, puertos, correos y brechas, documentos)
  - IV. Postura de Seguridad (cabeceras y tecnologías)
  - V. Recomendaciones
- **`screenshots/`**: una captura PNG por host vivo, nombradas con hostname y timestamp.

---

## Limitaciones y pendientes

- **EX·10: Síntesis con IA (bonus, no completado).** Se intentó agregar el módulo de síntesis con IA (un nodo Basic LLM Chain con Google Gemini que resume cada hallazgo en 2 o 3 frases para el reporte). Durante la implementación se amplió la memoria RAM asignada a la máquina virtual para mejorar el rendimiento, pero por limitaciones de tiempo y de recursos del entorno no se logró dejar el módulo funcionando. El resto del pipeline (EX·01 a EX·09 y EX·11) está completo y es reproducible.

---

## Nota ética

Todas las técnicas de este laboratorio son para aprendizaje defensivo y para el propio pipeline de auditoría. Los módulos activos se ejecutaron únicamente contra `scanme.nmap.org`, objetivo público habilitado para pruebas.
