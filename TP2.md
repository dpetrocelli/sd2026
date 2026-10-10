# Trabajo Práctico Nº 2

## Sistemas Distribuidos y Concurrencia

**Fecha de entrega:** 05/10/2026

---

## Requisitos, consideraciones y formato de entrega

- **Integrar herramientas de IA en su ciclo de vida de desarrollo** (Cursor, ChatGPT/Codex, Claude, GitHub Copilot, etc.). Se espera que las utilicen como asistentes para codificar, depurar y documentar. En el informe, mencionen qué herramientas usaron y cómo les ayudaron.
- **Se puede implementar con cualquier lenguaje dentro de los que se mencionaron en clase (node, python, java).**
- **Deben incluir una grabación video** que se debe subir al repositorio donde se expliquen los servicios, componentes y configuraciones que tomaron en cuenta. Esto debe mostrar que comprenden cada punto y su desarrollo.
- **Pruebas Unitarias y de Integración:** Incluir un conjunto mínimo de pruebas automatizadas que cubren las funcionalidades críticas del proyecto.
- Generar un **informe detallado** que incluya respuestas a consultas, métricas y tiempos de evaluación, gráficas, diagramas de arquitectura y conclusiones.
- Mantener un **repositorio público** en un servicio de control de versiones como GitHub, Bitbucket o GitLab. Cada ejercicio (HIT #) debe contar con una carpeta y un README.md explicativo.
  - El README.md de cada Hit debe incluir como mínimo: instrucciones para ejecutar el proyecto, diagrama de arquitectura, y decisiones de diseño tomadas.
- Compilar la aplicación para ejecución desde la terminal, con recursos preparados para ser desplegados directamente sin necesidad de abrir un IDE.
- Implementar un **pipeline de CI/CD** que automatice la compilación y el despliegue de la aplicación con cada nueva versión de código (GitHub Actions).
- Desplegar el servicio en un **entorno público** accesible desde Internet para su evaluación en producción (Despliegue en la nube).
- Proporcionar un **endpoint público** para cada servicio que permita verificar el estado de los principales servicios. No requiere GUI, puede devolver un JSON (Key=Servicio, value=Status). Ejemplos: <https://status.lemon.me/>, <https://health.aws.amazon.com/health/status>.
- Gestionar y mantener **registros de actividades (logs)** en memoria y disco.
- **Seguridad:**
  - No commitear `.env`, credenciales ni secrets al repositorio. Configurar `.gitignore` apropiado desde el inicio.
  - Gestionar credenciales por ambiente de forma segura (GitHub Secrets, Secret Manager / Parameter Store). **Zero static keys**: autenticarse contra cloud providers vía Workload Identity / OIDC.
  - Para registros Docker: usar image pull secrets o Workload Identity en lugar de enviar credenciales en payloads.
  - Incluir **gitleaks** [GITLEAKS] en el pipeline de CI — si detecta un secret hardcodeado, el pipeline debe fallar.
  - Si expusieron un secret accidentalmente, revóquenlo de inmediato y generen uno nuevo: queda en el historial de Git aunque después lo eliminen.

---

## Contenidos del programa relacionados

- **U1.6** Comunicación Cliente-Servidor (HTTP, JSON).
- **U2.1** Sincronización de relojes: relojes lógicos de Lamport.
- **U2.2** Exclusión mutua: algoritmos centralizado, distribuido, Token Ring.
- **U2.3** Bloqueos en Sistemas Distribuidos: detección y prevención.
- **U2.4** Hilos (Threads): empleo y diseño de paquetes de hilos.
- **U4.3** Contenedores Docker: imágenes, Dockerfile, Docker Hub.

---

## Requisitos obligatorios nuevos (aplican a todos los Hits)

> **Nuevo obligatorio.** Estos puntos no son opcionales ni "deseables". Que la demo funcione no alcanza: si falta alguno de los entregables de esta sección, el TP vuelve **a rehacer**.

### R1 - Imágenes privadas y credenciales

- Las imágenes del "servicio tarea" se publican en un **registry privado del equipo** (Docker Hub privado, GHCR, Artifact Registry, etc.). No se aceptan imágenes públicas.
- El servidor se autentica contra el registry **sin recibir credenciales en el request** (ver "Importante (Seguridad)" del Hit #1).
- **Evidencia obligatoria:** un pull de la imagen privada **sin** credencial que falla y el mismo pull **con** la credencial configurada en el servidor que funciona (comandos y salida en el README).

### R2 - Imágenes válidas por parámetro (detección dinámica)

- La imagen a ejecutar llega **por parámetro** en el request. No puede estar fija en el código del servidor.
- El servidor **valida la imagen antes de ejecutarla**: lista de imágenes/registries permitidos (configurable, no fija en el código), verificación de que la imagen existe y, como deseable, que coincida con un digest (`@sha256:...`).
- Una imagen inexistente, no permitida o mal formada devuelve un **error claro** (código HTTP y mensaje). No puede terminar en un 500 genérico ni en un contenedor colgado.

### R3 - Contrato de ida y vuelta

Entregar `contrato.md` u `openapi.yaml` con:

1. **Request:** todos los campos, tipos, cuáles son obligatorios y valores por defecto.
2. **Response OK:** resultado y metadata mínima: `task_id`, imagen y digest ejecutados, worker/contenedor que la atendió, tiempos (en cola, ejecución, total), timestamp de Lamport (Hit #2).
3. **Errores:** tabla con cada código HTTP posible (400, 401, 403, 404, 408/504, 409, 429, 500, 503), cuándo ocurre y el cuerpo que devuelve.
4. **Lo que falta:** una sección "datos que no devolvemos y podríamos devolver" (logs del contenedor, uso de CPU y memoria, intentos, posición en la cola, etc.), con la justificación de por qué quedan afuera.

### R4 - Servidor stateless con autenticación por request (admin/stats)

El servidor conoce el contexto de cada petición mientras la atiende, pero **no guarda sesión**. Por eso la identidad y el rol tienen que **viajar en cada request** (token, API key o hash firmado) y validarse en cada llamada.

- Al menos dos roles: **usuario** (ejecuta tareas) y **admin** (accede a `/stats` y a operaciones de administración).
- Endpoint `/stats` (o equivalente) con, como mínimo: tareas ejecutadas, tareas fallidas, tareas por imagen, latencia promedio y p95, tareas en cola y workers ocupados.
- Las credenciales de usuario y admin **no se commitean** (variables de entorno o secret manager).
- **Evidencia obligatoria** (script o colección reproducible):
  - sin token → `401`
  - token de usuario en `/stats` → `403`
  - token de admin en `/stats` → `200`
  - token inválido o vencido → `401`

### R5 - Pruebas con tareas diversas y matriz de parámetros

- Al menos **3 imágenes/tareas distintas** (por ejemplo: una CPU-bound, una que procese archivos de entrada y una que falle a propósito o exceda el timeout).
- Cada tarea se prueba con **varias combinaciones de parámetros**: valores válidos, límite e inválidos.
- **Matriz obligatoria.** Variables a combinar:

| Variable | Valores mínimos |
|---|---|
| V1 - Cantidad de archivos de entrada | 1, 10, 100 |
| V2 - Cantidad de acciones sobre esa entrada | 1, 3, N (definido por el equipo) |
| V3 - Usuarios/bots concurrentes haciendo peticiones | 1, 10, 50 |

  La combinatoria V1 × V2 × V3 se presenta en una tabla. En cada celda: latencia p50/p95, throughput (tareas/min), tasa de error y observaciones (cuello de botella detectado). Si alguna combinación no se corre, se justifica por qué.
- La carga se genera con un **script reproducible** incluido en el repo (k6, Locust, `hey` o un script propio con concurrencia real). No se aceptan pruebas manuales con Postman como evidencia de concurrencia.
- Las corridas con usuarios concurrentes se hacen **autenticadas** (R4): mezclar usuarios y al menos un bot sin token, y reportar cuántas peticiones rechazó el servidor.

### Entregables de esta sección (checklist)

- [ ] Imagen en registry privado y evidencia del pull con y sin credencial (R1)
- [ ] Validación de la imagen por parámetro, con sus casos de error documentados (R2)
- [ ] `contrato.md` / `openapi.yaml` con request, response, tabla de errores y "lo que falta" (R3)
- [ ] Roles usuario/admin, `/stats` y script de evidencia 401/403/200 (R4)
- [ ] 3+ tareas distintas, matriz V1 × V2 × V3 completa y script de carga (R5)
- [ ] En el video: mostrar R2, R4 y una corrida de R5 en vivo

---

## Práctica

### Hit #1 — Tareas remotas en contenedores

Implementen un servidor que resuelva "tareas arbitrarias" empaquetadas como contenedores **Docker** [DOCKER, MER14]. Conjunto de acciones de diseño y arquitectura que deben respetarse:

#### Servidor

- Desarrollar el servidor utilizando tecnología HTTP.
- El servidor debe estar contenerizado y alojado en un host con Docker instalado.
- Debe permanecer receptivo a nuevas solicitudes del cliente, exponiendo métodos para interactuar.
- Debe incluir un método `ejecutarTareaRemota()` asociado a un endpoint (`getRemoteTask()`) que procese las tareas enviadas por el cliente.
- Los parámetros de las tareas se reciben vía HTTP **POST** con cuerpo JSON.
- Durante la ejecución, el servidor levanta temporalmente un "servicio tarea" como contenedor Docker.
- Una vez en funcionamiento, se comunica con el "servicio tarea" para ejecutar la lógica con los parámetros proporcionados.
- Espera los resultados de la tarea y los devuelve al cliente.

#### Servicio tarea

- Establecer un servicio de escucha vía HTTP.
- Implementar la tarea de procesamiento `ejecutarTarea()`.
- Configurar el servicio para recibir los parámetros de entrada en formato JSON.
- Empaquetar la solución como imagen Docker para facilitar la distribución y el despliegue.
- Publicar la solución en **Docker Hub** [DHUB], pública o privada.

#### Cliente

- Hacer una solicitud HTTP POST contra el servidor.
- Enviar los parámetros necesarios en formato JSON, incluyendo:
  - El cálculo a realizar.
  - Los parámetros específicos requeridos por la tarea.
  - Datos adicionales necesarios para el procesamiento.
  - La imagen Docker que contiene la solución de la tarea.

> **Importante (Seguridad):** Las credenciales de acceso al registro Docker **NO deben enviarse en el payload del request**. Como parte de este hit, investigue e implemente una forma segura de autenticar al servidor contra el registro Docker sin exponer credenciales en tránsito (por ejemplo: *image pull secrets*, tokens de acceso de corta duración, OIDC federation, o configuración previa en el host). Documente la solución elegida y justifique por qué es más segura que enviar usuario y contraseña en el JSON.

![Hit #1 - Arquitectura Cliente/Servidor con Tareas Docker](img/tp2_hit1.png)

---

### Hit #2 — Concurrencia y exclusión mutua

Modifiquen el servidor del Hit #1 para que acepte múltiples tareas concurrentes. Para ello:

1. **Pool de workers:** implementar un pool con un límite configurable (por ejemplo, N workers máximos). Cada worker ejecuta una tarea en un contenedor Docker independiente.
2. **Exclusión mutua:** cuando llegan más tareas que workers disponibles, las tareas deben encolarse. Implementen la cola con exclusión mutua para garantizar que no haya *race conditions* al asignar tareas. Pueden usar un mutex distribuido o implementar el algoritmo de Ricart-Agrawala [RIC81] para el acceso a la cola compartida.
3. **Relojes lógicos:** implementen *timestamps* lógicos (relojes de Lamport) [LAM78] en los mensajes entre cliente y servidor para ordenar las solicitudes de manera consistente.
4. **Medición de throughput:** midan y documenten el throughput del sistema (tareas completadas por minuto) variando la cantidad de workers: 1, 2, 4 y 8. Presenten los resultados en una tabla y grafiquen la curva de escalabilidad. Analicen si el *speedup* es lineal o si hay un cuello de botella — la **ley de Amdahl** [AMD67] es la herramienta teórica para razonar este límite. Considerando que todo corre en un solo equipo: ¿cuáles son los recursos compartidos que podrían convertirse en cuello de botella (CPU, memoria, I/O de disco, red de Docker, daemon de Docker)? ¿Cómo los identificarían y medirían?

![Hit #2 - Pool de Workers con Exclusión Mutua](img/tp2_hit2.png)

---

### Hit #3 — Coordinación y tolerancia a fallos

Desplieguen 2 o más instancias del servidor del Hit #1 detrás de un balanceador de carga (pueden usar **nginx** [NGINX], HAProxy o un load balancer en la nube).

Implementen un mecanismo de **elección de líder** utilizando el **algoritmo Bully** [GAR82] para que uno de los nodos actúe como coordinador del sistema. El coordinador será responsable de:

- Asignar tareas entrantes a los nodos workers disponibles.
- Mantener el registro de estado de cada nodo.
- Si el líder/coordinador se cae (simúlenlo matando el proceso), otro nodo debe detectar la caída y tomar el control automáticamente mediante una nueva elección.

Documenten en el informe: el diagrama de secuencia de una elección de líder, el tiempo de recuperación ante una caída del coordinador, y cómo se redistribuyen las tareas pendientes.

![Hit #3 - Elección de Líder (Algoritmo Bully)](img/tp2_hit3.png)

---

## Referencias y Bibliografía

- **[AMD67]** Amdahl, G. M. (1967). "Validity of the Single Processor Approach to Achieving Large Scale Computing Capabilities". *AFIPS Conference Proceedings*, 30, 483–485.
- **[DHUB]** Docker Hub — Container Image Library. <https://hub.docker.com/>
- **[DOCKER]** Docker Documentation. <https://docs.docker.com/>
- **[GAR82]** Garcia-Molina, H. (1982). "Elections in a Distributed Computing System". *IEEE Transactions on Computers*, C-31(1), 48–59.
- **[GITLEAKS]** gitleaks — Protect and discover secrets using Gitleaks. <https://github.com/gitleaks/gitleaks>
- **[LAM78]** Lamport, L. (1978). "Time, Clocks, and the Ordering of Events in a Distributed System". *Communications of the ACM*, 21(7), 558–565.
- **[MER14]** Merkel, D. (2014). "Docker: Lightweight Linux Containers for Consistent Development and Deployment". *Linux Journal*, 2014(239).
- **[NGINX]** nginx Documentation — Load Balancing. <https://nginx.org/en/docs/http/load_balancing.html>
- **[RIC81]** Ricart, G. & Agrawala, A. K. (1981). "An Optimal Algorithm for Mutual Exclusion in Computer Networks". *Communications of the ACM*, 24(1), 9–17.
- **[TAN17]** Tanenbaum, A. S. & Van Steen, M. (2017). *Distributed Systems: Principles and Paradigms* (3rd ed.). Pearson. — Cap. 6: Sincronización.

