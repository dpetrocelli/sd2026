# Autograder — Cronograma de actividades

> **Corrección automática por ejercicio.** Cada lunes, una (o dos) actividades nuevas con corrección instantánea. Forkeás → codeás → pusheás → en ~1 min recibís ✅/❌ con el detalle. **Cierre del programa: lunes 15/06/2026.**

---

## Cómo funciona — en 30 segundos

```
Vos pusheás → Grader corre tests ocultos → ✅/❌ comentario en tu commit
                                          → Planilla de Google + Discord + email si fallás
```

Cada ejercicio es un **repo de GitHub** que vos forkeás. Implementás siguiendo el `README.md` del repo, pusheás, y un sistema externo corre tests ocultos sobre tu código y te devuelve feedback automático.

### Dónde ver tus resultados

| Canal | Link | Qué encontrás |
|---|---|---|
| 🏆 **Leaderboard público** | <https://unlu-sd2026.github.io/grader/> | Ranking del curso, puntaje acumulado, ejercicios resueltos |
| 💬 **Comentario en tu commit** | tu fork → último commit | Detalle del último submit: qué tests pasaron, cuáles no, por qué |
| 📊 **Planilla de Google** | (link en `#grading`) | Histórico completo de submissions, deadline tracking |
| 🔔 **Discord** | canal `#grading` | Notificación en tiempo real de cada corrección |

> El **leaderboard** se actualiza automáticamente después de cada submit (workflow `leaderboard.yml` corre y publica a GitHub Pages). Si no ves tu nombre, esperá ~2 minutos.

### Reglas mínimas

- **No tocar** `tests/` ni `.github/` — solo `src/`, `Dockerfile`, `docker-compose.yml`, `.env.example`.
- **Probá local antes de pushear** — máximo 5 submissions por ejercicio.
- **Nunca commitees `.env`** — usá `.env.example` y agregá `.env` al `.gitignore`.
- **Inglés** en código, comentarios y commits.
- **Tarde:** período de gracia 3 días, marcado como `LATE`. Después se rechaza.

<details>
<summary><strong>Workflow completo (paso a paso)</strong></summary>

1. **Fork** del repo del ejercicio (`https://github.com/unlu-sd2026/exercise-XX-...`).
2. **Clonar** tu fork: `git clone https://github.com/TU_USUARIO/exercise-XX-...`
3. **Leer el `README.md`** — la spec completa está ahí.
4. **Implementar** reemplazando los `TODO` en `src/`, `Dockerfile`, `docker-compose.yml`.
5. **Probar local:**
   ```bash
   docker compose up --build -d
   curl http://localhost:8080/health
   pytest tests/ -v
   docker compose down -v
   ```
6. **Push:** `git add -A && git commit -m "Implement solution" && git push`
7. **Esperar el feedback** (~1 min). El grader postea un comentario ✅/❌ en tu último commit con detalle de qué tests pasaron y cuáles no.

Para ver tu nota: comentario en el commit del fork · planilla de Google · leaderboard en <https://unlu-sd2026.github.io/grader/>.

</details>

<details>
<summary><strong>Preguntas frecuentes</strong></summary>

**¿Cuántas veces puedo entregar?** Hasta 5 submissions por ejercicio. Cada push cuenta. Probá local antes.

**¿Puedo volver a pushear si fallé?** Sí, mientras no pasaste el límite.

**Los tests locales pasan pero el grader dice que fallé.** El grader corre tests ocultos adicionales (más casos borde + buenas prácticas Docker). Leé el comentario del commit.

**¿Puedo ver los tests ocultos?** No, están en repo privado. El comentario del commit te dice qué falló y por qué.

**¿Y si pusheo después del deadline?** Período de gracia de 3 días marcado como `LATE`. Después, rechazo.

**No tengo Docker.** Instalá Docker Desktop (<https://www.docker.com/products/docker-desktop/>). Gratis para uso educativo.

**Cualquier duda → canal `#grading` en Discord.**

</details>

---

## Cronograma — 9 actividades, 6 semanas

> Cada actividad **refuerza el TP** que están viendo esa semana. No es carga extra — es práctica con corrección automática del concepto que ya están dando.

### Clase 1 — Lunes 05/05/2026

#### `01-node-registry` — Registro de nodos por sockets

Servicio que registra nodos remotos vía sockets/HTTP, con health-check y persistencia simple. Calentamiento — refuerza lo de **TP 1** (registro de contactos + cliente/servidor) ahora con corrección automática.

- **Refuerza:** TP 1 — Conceptos básicos de SD
- **Entrega:** Lun **05/05/2026**
- **Repo:** [unlu-sd2026/exercise-01-node-registry](https://github.com/unlu-sd2026/exercise-01-node-registry)

---

### Clase 2 — Lunes 12/05/2026 · semana doble

#### `02-dashboard` — Dashboard de estado de nodos

API + UI mínima que muestra qué nodos están vivos, latencia, último heartbeat. Sirve de base para observabilidad.

- **Refuerza:** TP 2 — SD y Concurrencia
- **Repo:** [unlu-sd2026/exercise-02-dashboard](https://github.com/unlu-sd2026/exercise-02-dashboard)

#### `03-rabbitmq` — Patrones con RabbitMQ

Implementar producer/consumer, DLQ, retry con backoff. **Es exactamente el Hit #0 del TP 3** con corrección automática.

- **Refuerza:** TP 3 · Parte 1 (Hit #0)
- **Repo:** [unlu-sd2026/exercise-03-rabbitmq](https://github.com/unlu-sd2026/exercise-03-rabbitmq)

- **Entrega ambos:** Lun **12/05/2026**

---

### Clase 3 — Lunes 19/05/2026 · semana doble

#### `05-observability` — Prometheus + Grafana sidecar

Instrumentar un servicio con `/metrics`, scraping de Prometheus, dashboard de Grafana versionado en repo.

- **Refuerza:** TP 3 · Parte 2 (Hit #4 — observabilidad)
- **Repo:** [unlu-sd2026/exercise-05-observability](https://github.com/unlu-sd2026/exercise-05-observability)

#### `06-cicd` — Pipeline GitHub Actions + ghcr.io

Workflow que buildea, testea y pushea imagen Docker a `ghcr.io` con tags por SHA y `latest`. Gate de gitleaks obligatorio.

- **Refuerza:** Requisitos de CI/CD del TP 3
- **Repo:** [unlu-sd2026/exercise-06-cicd](https://github.com/unlu-sd2026/exercise-06-cicd)

- **Entrega ambos:** Lun **19/05/2026**

---

### Clase 4 — Lunes 26/05/2026 · semana doble

#### `07-hpa` — Horizontal Pod Autoscaler

Configurar HPA contra una métrica custom (CPU, RPS o queue depth), demostrar que escala bajo carga sintética.

- **Refuerza:** TP 3 · Parte 2 (Hit #3 — escalado)
- **Repo:** [unlu-sd2026/exercise-07-hpa](https://github.com/unlu-sd2026/exercise-07-hpa)

#### `08-grpc` — Servicio gRPC + Protobuf

Definir un `.proto`, generar stubs, exponer un servicio gRPC con health-check y reflection.

- **Refuerza:** TP 1 · Parte 2 (gRPC + Protobuf)
- **Repo:** [unlu-sd2026/exercise-08-grpc](https://github.com/unlu-sd2026/exercise-08-grpc)

- **Entrega ambos:** Lun **26/05/2026**

---

### Clase 5 — Lunes 02/06/2026

#### `09-leader-election` — Algoritmo de Bully

Implementar elección de líder Bully en N nodos, simular caída del líder y recuperación.

- **Refuerza:** TP 2 — Bully
- **Entrega:** Lun **02/06/2026**
- **Repo:** [unlu-sd2026/exercise-09-leader-election](https://github.com/unlu-sd2026/exercise-09-leader-election)

---

### Clase 6 — Lunes 09/06/2026 · cierre

#### `10-gke` — Deploy a Google Kubernetes Engine

Provisión de GKE con Terraform, deploy del Sobel distribuido del TP 3, health checks públicos. **Cierre del programa de autograder.**

- **Refuerza:** TP 3 · Parte 2 (Hit #2 — cloud)
- **Entrega final:** Domingo **15/06/2026**
- **Repo:** [unlu-sd2026/exercise-10-gke](https://github.com/unlu-sd2026/exercise-10-gke)

---

## Resumen del cronograma

| Clase | Fecha | Ejercicios | Refuerza |
|:---:|:---:|---|---|
| 1 | **Lun 05/05** | `01-node-registry` | TP 1 |
| 2 | **Lun 12/05** | `02-dashboard` · `03-rabbitmq` | TP 2 · TP 3 P1 Hit #0 |
| 3 | **Lun 19/05** | `05-observability` · `06-cicd` | TP 3 P2 Hit #4 · CI/CD |
| 4 | **Lun 26/05** | `07-hpa` · `08-grpc` | TP 3 P2 Hit #3 · TP 1 P2 |
| 5 | **Lun 02/06** | `09-leader-election` | TP 2 |
| 6 | **Lun 09/06** | `10-gke` | TP 3 P2 Hit #2 |
| — | **Dom 15/06** | **Cierre del programa** | — |

> **Nota:** sacamos `04-kubernetes` del listado original — es redundante con [TP 3 · Parte 0](practica-0.html) (bootstrap del cluster) + Hit #1 (Sobel sobre k8s), que ya cubren ese contenido.

---

## Arquitectura (para los curiosos)

```
┌────────────────────┐   push    ┌─────────────────────┐  POST   ┌──────────────────┐
│  Tu fork           │─────────→│  Sanity Workflow     │────────→│  Cloudflare      │
│  TU_USUARIO/       │          │  (GitHub Actions)    │         │  Worker          │
│  exercise-XX-...   │          │  corre tests visibles│         │  (webhook)       │
└────────────────────┘          └─────────────────────┘         └────────┬─────────┘
                                                                         │ dispara
                                                                         ▼
┌────────────────────┐          ┌─────────────────────┐         ┌──────────────────┐
│  Planilla Google   │◀─────────│  Grader             │────────→│  Discord         │
│  (resultados)      │  reporta │  (GitHub Actions)   │ avisa   │  (#grading)      │
└────────────────────┘          │                     │         └──────────────────┘
                                │  1. Clona tu fork   │
┌────────────────────┐          │  2. Clona tests     │         ┌──────────────────┐
│  Comment commit    │◀─────────│  3. Corre pytest    │         │  Email           │
│  ✅ 24/24 (100%)   │  comenta │  4. Reporta         │         │  (si ❌)         │
└────────────────────┘          └─────────────────────┘         └──────────────────┘
```
