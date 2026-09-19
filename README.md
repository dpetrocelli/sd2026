# Sistemas Distribuidos y Programación Paralela — UNLu DCB · 2026

Material de cursada (trabajos prácticos) de la materia **Sistemas Distribuidos y Programación Paralela** —
Universidad Nacional de Luján, Departamento de Ciencias Básicas. Cátedra **Dr. David Petrocelli**.

Sitio público:
**[dpetrocelli.github.io/sd2026](https://dpetrocelli.github.io/sd2026/)**

## Contenido

| TP | Tema | Entrega |
|----|------|---------|
| 1 | Conceptos básicos de SD (sockets TCP, JSON, gRPC) | 04/09/2026 |
| 2 | SD y Concurrencia (Docker, mutex, Bully) | 05/10/2026 |
| 3 · Parte 0 | Bootstrap del cluster (k3s / k3d) — prerrequisito | antes del 23/10/2026 |
| 3 · Parte 1 | Patrones RabbitMQ + Sobel distribuido | 23/10/2026 |
| 3 · Parte 2 | Cloud Computing — Kubernetes / GKE | 23/10/2026 |
| 4 | Programación paralela (shaders / GPU) | 06/11/2026 |
| Integrador | Blockchain distribuida + CUDA | 04/12/2026 |

## Estructura

```
.
├── index.html              # landing
├── practica-1..4.html      # TPs renderizados
├── practica-3-parte-1.html
├── practica-3-parte-2.html
├── tp-integrador.html
├── *.md                    # fuentes en markdown
├── assets/
│   ├── style.css
│   ├── unlu_escudo.png
│   ├── logo_dcb.png
│   └── images/             # diagramas de cada TP
├── template.html           # template pandoc
└── build.sh                # regenera todo el HTML
```

## Cómo regenerar

Requiere `pandoc` en el PATH.

```bash
./build.sh
```

Re-genera todos los `*.html` desde los `*.md` aplicando el template UNLu.

## Branding

Paleta y logos alineados con el skill `pptx-unlu` (mismo estilo institucional
para presentaciones y documentos web).
