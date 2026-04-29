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

### El segundo simulador: Accel-Sim

Además de GPGPU-Sim, este lab incluye **Accel-Sim 1.3.0** (febrero 2025),
desarrollado por el mismo grupo de investigación (Khairy, Shen, Aamodt y
Rogers, Purdue + UBC). Accel-Sim es la **evolución moderna** de GPGPU-Sim y
fue presentado en el paper de referencia:

> **Khairy, M., Shen, Z., Aamodt, T. M., & Rogers, T. G.** (2020).
> *Accel-Sim: An Extensible Simulation Framework for Validated GPU Modeling.*
> En *47th ACM/IEEE International Symposium on Computer Architecture (ISCA
> 2020)*, Valencia, España, pp. 473–486.
> [PDF](https://mkhairy.github.io/Docs/Accel-Sim.pdf)
> · [Sitio oficial](https://accel-sim.github.io/)
> · [Repo](https://github.com/accel-sim/accel-sim-framework)

#### En qué se diferencia de GPGPU-Sim

| Eje | GPGPU-Sim (ej. 01–04) | Accel-Sim (ej. 05) |
|-----|------------------------|----------------------|
| **Modo de simulación** | *Execution-driven* | *Trace-driven* |
| **Qué consume** | El binario CUDA + PTX (ISA virtual) | Una traza SASS (ISA real de NVIDIA) |
| **Cómo se obtiene la traza** | No aplica — ejecuta el binario | NVIDIA NVBit la captura ejecutando el binario sobre una GPU real |
| **Velocidad** | Lento (simula cada instrucción ciclo a ciclo) | **Mucho más rápido** (ya tiene la traza, solo modela la microarquitectura) |
| **Arquitecturas modeladas** | Hasta Volta con buen soporte | Volta, Turing, **Ampere** validadas |
| **Escribir su propio kernel** | Sí — el flujo natural | Solo si tienen acceso a una GPU real para grabar la traza |
| **Validación contra silicio** | Histórica (pre-2017) | Validada en ISCA 2020 sobre Tesla V100 con error medio ~14% |

#### Por qué incluimos los dos

Pedagógicamente cada uno aporta algo distinto:

- **GPGPU-Sim** los obliga a pensar en CUDA: escriben el kernel, eligen el
  grid, debuggean la lógica paralela. Es donde aprenden a *programar* GPU.
- **Accel-Sim** los expone al flujo profesional moderno: trazas reales,
  arquitecturas nuevas, simulación rápida. Es donde aprenden a *evaluar*
  decisiones arquitectónicas como en la industria.

El ejercicio 05 simula el **mismo `vectoradd` que el ejercicio 01** pero por
el camino trace-driven. Comparar las métricas de ambos contra la misma V100
es el cierre conceptual del lab.

#### Imagen Docker oficial

Para Accel-Sim no compilamos nada: usamos directamente la imagen oficial
del proyecto (CUDA 12.8 + Ubuntu 24.04):

```
ghcr.io/accel-sim/accel-sim-framework:ubuntu-24.04-cuda-12.8
```

Está declarada como segundo servicio en `docker-compose.yml`. Pull una sola
vez y andan.

---

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

## Tercer entorno: cluster K3s con GPU real

Además de los dos simuladores, la cátedra pone a disposición un **cluster
K3s con GPUs NVIDIA físicas** para que cada alumno pueda probar sus kernels
en hardware real. Esto cierra el ciclo: simulan en GPGPU-Sim → simulan en
Accel-Sim → ejecutan en GPU de verdad y comparan.

> **El cluster es un recurso compartido**. Cada alumno recibe su propio
> namespace y kubeconfig con cuota acotada. Úsenlo con respeto: kernels
> chicos, sesiones cortas, y cleanup de pods al terminar.

### Acceso — paso a paso

1. **Abrir la planilla de alumnos** (link compartido por la cátedra en
   Discord / aula virtual): `[PLANILLA — pendiente de publicar]`.
2. Buscar su fila por legajo y descargar el archivo `kubeconfig-<usuario>.yaml`
   asociado.
3. Guardarlo en `~/.kube/sd2026.yaml` y exportar la variable de entorno:
   ```bash
   export KUBECONFIG=~/.kube/sd2026.yaml
   ```
4. Verificar la conexión y que la GPU está disponible:
   ```bash
   kubectl get nodes -L nvidia.com/gpu.product
   kubectl describe node | grep -A2 "nvidia.com/gpu"
   ```
5. Probar con un Pod de prueba que ejecuta `nvidia-smi`:
   ```bash
   kubectl run gpu-test --rm -it --restart=Never \
     --image=nvidia/cuda:12.4.0-base-ubuntu22.04 \
     --overrides='{"spec":{"containers":[{"name":"gpu-test","image":"nvidia/cuda:12.4.0-base-ubuntu22.04","command":["nvidia-smi"],"resources":{"limits":{"nvidia.com/gpu":1}}}]}}'
   ```
   Si ven la tarjeta listada con su modelo, memoria y driver — están
   adentro.

### Cómo correr sus ejercicios contra la GPU real

El **mismo `.cu` corre tal cual**: no cambia ni una línea de código. Cambia
sólo el entorno donde se compila y ejecuta. Hay dos caminos:

**Opción A — modificar el `docker-compose` local (más rápido para iterar).**
Si su laptop tiene GPU NVIDIA: descomenten la sección `deploy.resources` del
`docker-compose.yml` y cambien la base del `Dockerfile` a
`nvidia/cuda:12.4.0-devel-ubuntu22.04` sin compilar GPGPU-Sim. El binario
ahora usa la `libcudart` real del driver.

**Opción B — Job de Kubernetes (lo que les pedimos para la entrega).**
Empaquetan su kernel como imagen Docker, la suben a un registry, y crean un
Job en su namespace del cluster:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: vector-add-real-gpu
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: cuda
          image: <su-registry>/<su-imagen>:<tag>
          command: ["./vector_add"]
          resources:
            limits:
              nvidia.com/gpu: 1
```

Aplican con `kubectl apply -f job.yaml` y siguen los logs con
`kubectl logs -f job/vector-add-real-gpu`.

### Comparación obligatoria para el informe

Para los ejercicios 01–04, el informe debe incluir **3 columnas de
métricas** del mismo kernel:

| Métrica | GPGPU-Sim (ej. 01–04) | Accel-Sim (ej. 05) | GPU real (cluster K3s) |
|---------|------------------------|----------------------|--------------------------|
| Wall-clock total | (lento, segundos a minutos) | (medio) | (ms) |
| Throughput (GFLOPS o GB/s) | sim | sim | medido con `nvprof` o Nsight |
| Cache miss rate L1 | sim | sim | medido con Nsight |
| Discrepancia vs. GPU real | (calcular %) | (calcular %) | baseline |

Esto les da material concreto para discutir **la precisión de cada
simulador** vs. el silicio real — exactamente la conversación que tienen
los papers de arquitectura GPU.

### Reglas de uso del cluster

- **Cuota:** 1 GPU por Pod, máximo 30 minutos de wall-time por Job.
- **Limpieza:** borrar Jobs y Pods al terminar (`kubectl delete job <nombre>`).
- **Sin batch nocturno:** no dejar Jobs corriendo durante la noche.
- **Sin entrenamiento de modelos pesados:** este cluster es para los
  ejercicios del lab y el TP Integrador, no para entrenar redes propias.
- **Reportar problemas:** si el cluster se cae o un nodo no responde,
  avisar en Discord — no abusar de retries.

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

- **Kirk, D. B., & Hwu, W. W.** (2016). *Programming Massively Parallel
  Processors: A Hands-on Approach* (3ra ed.). Morgan Kaufmann. El libro de
  cabecera de CUDA.
- **Harris, M.** *Optimizing Parallel Reduction in CUDA* (NVIDIA
  whitepaper). Muestra 7 versiones progresivamente optimizadas del kernel
  del ejercicio 04. Lectura **obligatoria** antes de hacer el 04.

### Papers académicos de los simuladores

- **Bakhoda, A., Yuan, G. L., Fung, W. W. L., Wong, H., & Aamodt, T. M.**
  (2009). *Analyzing CUDA Workloads Using a Detailed GPU Simulator.* En
  *IEEE International Symposium on Performance Analysis of Systems and
  Software (ISPASS 2009)*, pp. 163–174. — Paper original de **GPGPU-Sim**
  (ejercicios 01–04). [IEEE Xplore](https://ieeexplore.ieee.org/document/4919648)
- **Khairy, M., Shen, Z., Aamodt, T. M., & Rogers, T. G.** (2020).
  *Accel-Sim: An Extensible Simulation Framework for Validated GPU
  Modeling.* En *47th ACM/IEEE International Symposium on Computer
  Architecture (ISCA 2020)*, Valencia, España, pp. 473–486. — Paper de
  referencia de **Accel-Sim** (ejercicio 05).
  [PDF](https://mkhairy.github.io/Docs/Accel-Sim.pdf)

### Documentación oficial

- [Manual de GPGPU-Sim](http://www.gpgpu-sim.org/manual/index.php/Main_Page)
- [Repo GPGPU-Sim](https://github.com/gpgpu-sim/gpgpu-sim_distribution)
- [Sitio de Accel-Sim](https://accel-sim.github.io/)
- [Repo de Accel-Sim](https://github.com/accel-sim/accel-sim-framework)
- [CUDA C Programming Guide](https://docs.nvidia.com/cuda/cuda-c-programming-guide/)
- [NVIDIA NVBit](https://github.com/NVlabs/NVBit) — el tracer que captura
  las trazas SASS que consume Accel-Sim.

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
