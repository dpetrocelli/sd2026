# Autograder — Guía para alumnos

> Sistema de **corrección automática** de ejercicios. Hacés un fork, codeás, pusheás, y en menos de un minuto recibís el resultado con el detalle de qué pasó y qué falló.

---

## Cómo funciona (vista rápida)

```
Vos pusheás → Webhook → Grader corre tests ocultos → ✅/❌ comentario en tu commit
                                                    → Planilla de Google actualizada
                                                    → Notificación en Discord
                                                    → Email automático si fallás
```

Cada ejercicio es un repositorio de GitHub que vos **forkeás**, implementás y **pusheás**. Un sistema externo corre **tests ocultos** sobre tu código y te devuelve feedback automático.

---

## Paso a paso

### 1. Forkear el ejercicio

Entrá al link del ejercicio que te pasamos (por ejemplo `https://github.com/unlu-sd2026/exercise-01-node-registry`) y hacé click en **"Fork"** arriba a la derecha.

### 2. Clonar tu fork

```bash
git clone https://github.com/TU_USUARIO/exercise-01-node-registry.git
cd exercise-01-node-registry
```

### 3. Leer el README

El `README.md` del ejercicio contiene la **especificación completa**: qué hay que construir, qué endpoints implementar, qué requisitos tiene el `Dockerfile` y qué evalúa el grader. **Leelo con atención** — todo lo que el grader testea está documentado ahí.

### 4. Implementar la solución

Abrí los archivos en `src/` y reemplazá los `TODO` con tu código. Implementá el `Dockerfile`, el `docker-compose.yml` y el `.dockerignore` según las consignas.

### 5. Probar localmente

Antes de pushear, probá que tu solución levanta y pasa los tests visibles:

```bash
# Levantar el stack
docker compose up --build -d

# Verificar que responde
curl http://localhost:8080/health

# Correr los tests visibles (sanity)
pip install pytest requests
pytest tests/ -v

# Bajar el stack cuando termines
docker compose down -v
```

### 6. Push

```bash
git add -A
git commit -m "Implement solution"
git push
```

### 7. Esperar el feedback (~1 min)

Después del push, el grader automáticamente:

1. Corre los **tests ocultos** sobre tu código (más exhaustivos que los visibles).
2. Postea un **comentario ✅ o ❌ en tu último commit** con el puntaje y el detalle.
3. Actualiza la **planilla de Google** del curso.
4. Manda una notificación a **Discord**.
5. Si fallaste, te llega un **email** con el detalle.

Para verlo: andá a tu fork en GitHub → click en el último commit → vas a ver el comentario del grader.

---

## Reglas importantes

- **NO modifiques** las carpetas `tests/` ni `.github/` de tu fork — solo tocá `src/`, `Dockerfile`, `docker-compose.yml`, `.dockerignore` y `.env.example`.
- **NO commitees** tu archivo `.env` — contiene credenciales. Usá `.env.example` como plantilla y agregá `.env` al `.gitignore`.
- **Probá localmente** antes de pushear — tenés un número limitado de submissions.
- **Leé el comentario del commit** cuando te dé ❌ — te dice exactamente qué tests fallaron y por qué.
- Todo el código, comentarios y commits van en **inglés**.

---

## Preguntas frecuentes

**¿Cuántas veces puedo entregar?**
Cada ejercicio tiene un máximo de submissions (normalmente **5**). Cada push cuenta como una submission. Hacelas valer — probá local antes.

**¿Puedo volver a pushear si fallé?**
Sí, mientras no hayas llegado al límite. Corregís y pusheás de nuevo, el grader vuelve a evaluar.

**Los tests locales pasan pero el grader dice que fallé. ¿Por qué?**
El grader corre tests **ocultos adicionales** que cubren más casos borde, buenas prácticas de Docker e integración. Leé el detalle del error en el comentario del commit.

**¿Puedo ver los tests ocultos?**
No. Están en un repositorio privado. Pero el comentario del commit te muestra **qué test falló y por qué**.

**¿Y si pusheo después del deadline?**
Las entregas tardías se aceptan durante un **período de gracia** (normalmente 3 días) pero quedan marcadas como **LATE** en los resultados. Después del período de gracia, se rechazan.

**No tengo cuenta de GitHub.**
Creala gratis en <https://github.com/signup>.

**No tengo Docker instalado.**
Instalá Docker Desktop desde <https://www.docker.com/products/docker-desktop/>. Es gratis para uso educativo.

**¿Dónde veo mi nota?**
En tres lugares:

1. El **comentario en el commit** de tu fork (el más detallado).
2. La **planilla de Google** del curso (te pasamos el link).
3. El **leaderboard** en <https://unlu-sd2026.github.io/grader/>.

---

## Arquitectura (para los curiosos)

```
┌────────────────────┐   push    ┌─────────────────────┐  POST   ┌──────────────────┐
│  Tu fork           │─────────→│  Sanity Workflow     │────────→│  Cloudflare      │
│  TU_USUARIO/       │          │  (GitHub Actions)    │         │  Worker          │
│  exercise-01-...   │          │  corre tests visibles│         │  (webhook)       │
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

---

## Resumen de un vistazo

| Acción | Dónde |
|--------|-------|
| Forkear ejercicio | GitHub → botón **Fork** |
| Clonar | `git clone https://github.com/TU_USUARIO/exercise-XX-...` |
| Probar local | `docker compose up --build -d` + `pytest tests/ -v` |
| Entregar | `git push` |
| Ver resultado | Comentario en el commit (~1 min) |
| Ver nota acumulada | Planilla Google + leaderboard |

**Cualquier duda → canal `#grading` en Discord.**
