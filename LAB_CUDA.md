# Lab CUDA — Simulador GPU sin placa física

> **Para qué es este lab**: aprender a programar para GPUs **sin tener una
> placa NVIDIA**. Empaquetamos un simulador de GPU en Docker que corre en
> cualquier laptop. Es la base para el TP4 y, especialmente, el TP Integrador
> (minero blockchain con CUDA).

---

## ¿Qué es este lab y por qué existe?

Para correr código CUDA tradicionalmente necesitan una placa de video NVIDIA.
No todos la tienen, y el cluster Kubernetes con GPUs físicas para la cátedra
todavía no está disponible. Este lab resuelve el problema usando un
**simulador**.

### El simulador: GPGPU-Sim

[GPGPU-Sim](https://github.com/gpgpu-sim/gpgpu-sim_distribution) es un
simulador *cycle-accurate* de GPUs NVIDIA desarrollado en la University of
British Columbia. Es **el** simulador que se usa en investigación de
arquitectura de GPUs hace más de 15 años (citado en cientos de papers).

Usamos la **versión 4.2.1 (febrero 2025)**, la más reciente. Soporta
arquitecturas modernas: Volta (Tesla V100), Turing (RTX 2060), Pascal
(Titan X). Por defecto simulamos una **Tesla V100**, una GPU de gama alta de
2017 con Tensor Cores.

### Qué hace exactamente

Ustedes escriben código CUDA normal en `.cu`, lo compilan con `nvcc`, y al
ejecutar el binario el simulador **intercepta cada llamada a la API CUDA** y
las ejecuta sobre una GPU virtual ciclo a ciclo.

A cambio reciben **métricas detalladas** que en una GPU real están escondidas
detrás del driver:

- Ciclos totales y instrucciones por ciclo (IPC)
- Ocupancia de los SMs (Streaming Multiprocessors)
- Hits y misses de cache L1/L2 con tasas exactas
- Cantidad de loads/stores a memoria global
- Divergencia de warps en cada kernel

> **Limitación importante**: el simulador es **lento**. Un kernel que en GPU
> real tarda 1ms acá puede tardar varios minutos. Por eso los ejercicios usan
> tamaños chicos (N=1024). No es para entrenar redes ni procesar datasets
> grandes — es para **aprender CUDA y entender la arquitectura GPU**.

### ¿Por qué es pedagógicamente superior a una GPU real?

| GPU real | Simulador |
|----------|-----------|
| El kernel "anda y ya". | Vemos *por qué* anda mejor o peor. |
| Las métricas dependen del hardware concreto. | Todos corren la misma "GPU" — resultados reproducibles. |
| Las features están escondidas en el driver. | Toda la microarquitectura es observable. |
| Necesitan hardware específico. | Cualquier laptop con Docker. |

---

## Repositorio del lab

Todo el código vive acá:

**👉 [`github.com/dpetrocelli/cuda-sim`](https://github.com/dpetrocelli/cuda-sim)**

> *El repo se publica con el commit inicial. Si recién están entrando, hagan
> `git clone` y arranquen.*

### Estructura

```
cuda-sim/
├── Dockerfile              ← Imagen con GPGPU-Sim 4.2.1 + CUDA 11.7
├── docker-compose.yml      ← Servicio listo (un comando y andan)
├── docs/GUIA.md            ← Guía completa del estudiante
├── examples/
│   ├── 01-vector-add/      ← RESUELTO. Léanlo de referencia.
│   ├── 02-saxpy/           ← A COMPLETAR.
│   ├── 03-matrix-mul/      ← A COMPLETAR.
│   └── 04-reduction/       ← A COMPLETAR.
└── README.md
```

---

## Setup

### Requisitos

- Docker + Docker Compose instalado (cualquier OS).
- ~3 GB de disco libre.
- Conexión la primera vez (descarga la imagen base de NVIDIA).

### Primera vez

```bash
git clone https://github.com/dpetrocelli/cuda-sim.git
cd cuda-sim
docker compose build
```

El build tarda **10–15 minutos** la primera vez porque compila GPGPU-Sim
desde fuente. Una vez hecho queda en caché.

### Día a día

```bash
docker compose run --rm cuda-sim
# Adentro del container:
cd 01-vector-add
make run
```

`make run` compila con `nvcc`, copia la config de la GPU simulada, y ejecuta
el binario. La simulación arranca y al final imprime las métricas.

---

## Los 5 ejercicios

| # | Ejercicio | Concepto principal | Estado |
|---|-----------|---------------------|--------|
| **01** | Suma de vectores | Indexado 1D, hello world de CUDA | ✅ Resuelto (referencia) |
| **02** | SAXPY (`Y = aX + Y`) | Pasaje de escalares al kernel | 📝 A completar |
| **03** | Multiplicación de matrices | Grid 2D, coalescing, reuso de datos | 📝 A completar |
| **04** | Reducción paralela | Shared memory, sincronización, divergencia de warps | 📝 A completar |
| **05** | Accel-Sim sobre traza SASS | Simulación trace-driven (versión moderna) | 🔬 Comparativo |

> Los ejercicios 01–04 usan **GPGPU-Sim** (execution-driven: escriben el `.cu`,
> el simulador intercepta cada llamada CUDA). El ejercicio 05 usa **Accel-Sim**
> (trace-driven: NVIDIA NVBit grabó la ejecución sobre una GPU real, el
> simulador consume esa traza). Mismo kernel, dos simuladores — comparen.

Cada ejercicio tiene su `CONSIGNA.md` con:

- Objetivos pedagógicos
- Pasos a seguir
- Tabla de métricas que tienen que reportar
- Pistas para no quedarse trabados
- Bibliografía sugerida

### Progresión pedagógica

Los ejercicios están diseñados para ir agregando un concepto nuevo cada vez:

1. **01 → 02**: del kernel más simple posible a uno con más operaciones por
   thread.
2. **02 → 03**: del indexado 1D al 2D, y aparece el costo del patrón de
   acceso a memoria (coalescing).
3. **03 → 04**: aparece la **shared memory** y la **sincronización entre
   threads de un mismo bloque**. Es el ejercicio más difícil — pero también
   el que les abre la puerta al resto del mundo CUDA.

---

## Cómo se entrega cada ejercicio

Para cada ejercicio resuelto:

- El `.cu` completo y funcionando en su repo del grupo.
- Un `RESULTADOS.md` con:
  - Tabla de métricas extraídas del log de GPGPU-Sim.
  - Capturas de pantalla del log como evidencia.
  - Análisis: por qué ven esos números mirando el código.
- Comparación con el ejercicio anterior (¿más ciclos? ¿peor IPC? ¿por qué?).

La guía completa con detalles de cómo interpretar el log está en
[`docs/GUIA.md`](https://github.com/dpetrocelli/cuda-sim/blob/main/docs/GUIA.md)
del repo.

---

## Migración a GPU real (cuando llegue el cluster)

Cuando tengamos el cluster Kubernetes con GPUs físicas:

1. **El mismo `.cu` corre tal cual**. No cambia ni una línea.
2. En el `docker-compose.yml` descomentamos la sección `deploy.resources`
   para nvidia.
3. El `Dockerfile` se reduce a la base oficial de NVIDIA (sin compilar
   GPGPU-Sim).
4. Comparamos las métricas reales vs. las simuladas. Ahí ven la **precisión
   del simulador** (suele estar dentro del 10–20% para arquitecturas
   soportadas).

---

## Relación con el resto de la cursada

Este lab no es un TP independiente — es **infraestructura compartida**:

- **TP 4 (Programación Paralela)**: el TP4 trabaja con shaders en WebGL, que
  son conceptualmente el primer paso. Este lab es el segundo: del SIMD
  gráfico al **GPGPU** (*General Purpose GPU computing*) con CUDA.
- **TP Integrador (Blockchain + CUDA)**: el integrador les pide implementar
  un minero blockchain con CUDA. Los 4 ejercicios de este lab son la
  **preparación directa** para ese TP — sin haber hecho los 4 no van a saber
  cómo escribir un minero eficiente.

---

## Recursos

### Lectura obligatoria

- **Kirk & Hwu**, *Programming Massively Parallel Processors* (3ra ed.) —
  el libro de cabecera de CUDA.
- Mark Harris, *Optimizing Parallel Reduction in CUDA* (NVIDIA whitepaper) —
  muestra 7 versiones progresivamente optimizadas del kernel del ejercicio
  04. Lectura **obligatoria** antes de hacer el 04.

### Documentación oficial

- [Manual de GPGPU-Sim](http://www.gpgpu-sim.org/manual/index.php/Main_Page)
- [CUDA C Programming Guide](https://docs.nvidia.com/cuda/cuda-c-programming-guide/)
- [Repo GPGPU-Sim](https://github.com/gpgpu-sim/gpgpu-sim_distribution)

### Comunidad

- Stack Overflow tag [`cuda`](https://stackoverflow.com/questions/tagged/cuda)
- [NVIDIA Developer Forum](https://forums.developer.nvidia.com/)

---

## Troubleshooting rápido

| Problema | Solución |
|----------|----------|
| `docker compose build` falla en el `make` de GPGPU-Sim | Verificar Ubuntu 20.04 + CUDA 11.7. Otras combinaciones tienen problemas. |
| El binario "no hace nada" | Olvidaron `gpgpusim.config` en el cwd. `make run` lo copia automáticamente. |
| Lentitud extrema | Reducir `N`. Es esperable que sea lento — son ciclos simulados. |
| `nvcc: command not found` | No están adentro del container. Ejecutar `docker compose run --rm cuda-sim` primero. |
| Cambios al `.cu` no se ven | Verificar el volume mount: `ls /workspace` dentro del container debe listar los archivos. |

---

**Buena suerte 🚀**
