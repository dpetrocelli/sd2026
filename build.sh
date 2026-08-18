#!/usr/bin/env bash
# Build UNLu-branded HTML pages from markdown sources.
#
# Source markdown files use Microsoft-style reference images:
#     ![alt text][imageN]
# with definitions at the end of the file:
#     [imageN]: <data:image/png;base64,...>
#
# We pre-process each source to swap reference images for inline links
# pointing to assets/images/<file>.png, then run pandoc with our template.

set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

TEMPLATE="$DIR/template.html"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

# Substitute [imageN] reference uses with inline links.
# Args: $1=source.md  $2=output.md  $3...$n=ref:filename pairs (image1:tp3_hit0_mq.png)
preprocess() {
  local src="$1"; shift
  local out="$1"; shift
  cp "$src" "$out"
  for pair in "$@"; do
    local ref="${pair%%:*}"
    local file="${pair#*:}"
    # Replace ![alt][refN] with ![alt](assets/images/file)
    # Use # as sed delimiter (filenames don't contain #).
    sed -i -E "s#\\]\\[${ref}\\]#](assets/images/${file})#g" "$out"
  done
}

# Rewrite "img/foo.png" inline image paths to "assets/images/foo.png".
# Used for sources that reference images via the original /tps/md/img/ folder.
rewrite_inline_imgs() {
  local src="$1"
  local out="$2"
  sed -E 's#\(img/([^)]+)\)#(assets/images/\1)#g' "$src" > "$out"
}

render() {
  local src="$1"
  local out="$2"
  local title="$3"
  local banner="${4:-}"

  echo "→ $src"
  echo "   $out"

  pandoc "$src" \
    --from=gfm+smart \
    --to=html5 \
    --standalone \
    --template="$TEMPLATE" \
    --toc \
    --toc-depth=3 \
    --highlight-style=tango \
    --metadata title="$title" \
    --metadata banner-num="$banner" \
    --metadata pagetitle="$title — UNLu DCB" \
    --output "$out"
}

# ============ Render targets ============

# --- TP 0 — Prerrequisitos (k3s) ---
TMP0="$TMPDIR/tp0.md"
rewrite_inline_imgs "TP0.md" "$TMP0"
render "$TMP0" \
  "practica-0.html" \
  "Práctica III · Parte 0 — Bootstrap del cluster (k3s / k3d)" \
  "TP 3 · Parte 0"

# --- TP 3 · Parte 1 ---
SRC1="2026 - FINAL Práctica III - Parte 1 - Kubernetes _ RabbitMQ.docx.md"
TMP1="$TMPDIR/parte1.md"
preprocess "$SRC1" "$TMP1" \
  "image1:tp3_hit0_mq.png" \
  "image2:tp3_hit0_pubsub.png" \
  "image3:tp3_hit0_dlq.png" \
  "image4:tp3_hit0_retry.png" \
  "image5:tp3_hit1.png"
render "$TMP1" \
  "practica-3-parte-1.html" \
  "Práctica III · Parte 1 — Kubernetes / RabbitMQ" \
  "TP 3 · Parte 1"

# --- TP 3 · Parte 2 ---
SRC2="FINAL Práctica III (Parte 2) - Cloud Computing (Kubernetes _ RabbitMQ).docx.md"
TMP2="$TMPDIR/parte2.md"
preprocess "$SRC2" "$TMP2" \
  "image1:tp3_hit2.png" \
  "image2:tp3_hit3.png"
render "$TMP2" \
  "practica-3-parte-2.html" \
  "Práctica III · Parte 2 — Cloud Computing (Kubernetes / RabbitMQ)" \
  "TP 3 · Parte 2"

# --- TP 1 — Conceptos básicos de SD ---
TMP_TP1="$TMPDIR/tp1.md"
rewrite_inline_imgs "TP1.md" "$TMP_TP1"
render "$TMP_TP1" \
  "practica-1.html" \
  "Práctica I — Conceptos básicos para la construcción de Sistemas Distribuidos" \
  "TP 1"

# --- TP 2 — SD y Concurrencia ---
TMP_TP2="$TMPDIR/tp2.md"
rewrite_inline_imgs "TP2.md" "$TMP_TP2"
render "$TMP_TP2" \
  "practica-2.html" \
  "Práctica II — Sistemas Distribuidos y Concurrencia" \
  "TP 2"

# --- TP 4 — Programación Paralela (Shaders) ---
TMP4="$TMPDIR/tp4.md"
rewrite_inline_imgs "TP4.md" "$TMP4"
render "$TMP4" \
  "practica-4.html" \
  "Práctica IV — Programación Paralela (Shaders)" \
  "TP 4"

# --- Cluster K3s con GPU — infraestructura compartida ---
TMP_K3S="$TMPDIR/cluster_k3s.md"
rewrite_inline_imgs "CLUSTER_K3S.md" "$TMP_K3S"
render "$TMP_K3S" \
  "cluster-k3s.html" \
  "Cluster K3s con GPU — Infraestructura compartida" \
  "CLUSTER K3S"

# --- Lab CUDA — Simulador GPU ---
TMP_LAB="$TMPDIR/lab_cuda.md"
rewrite_inline_imgs "LAB_CUDA.md" "$TMP_LAB"
render "$TMP_LAB" \
  "lab-cuda.html" \
  "Lab CUDA — Simulador GPU sin placa física" \
  "LAB CUDA"

# --- Autograder — Guía para alumnos ---
TMP_AG="$TMPDIR/autograder.md"
rewrite_inline_imgs "Autograder.md" "$TMP_AG"
render "$TMP_AG" \
  "autograder.html" \
  "Autograder — Guía para alumnos" \
  "AUTOGRADER"

# --- TP Integrador ---
TMPI="$TMPDIR/tpi.md"
rewrite_inline_imgs "TP_Integrador.md" "$TMPI"
render "$TMPI" \
  "tp-integrador.html" \
  "TP Integrador — Blockchain Distribuida y CUDA" \
  "TP INTEGRADOR"

# --- Semana 1 — Antes del viernes (Mercedes 2C 2026) ---
TMP_S1="$TMPDIR/semana1.md"
rewrite_inline_imgs "SEMANA1.md" "$TMP_S1"
render "$TMP_S1" \
  "semana-1.html" \
  "Semana 1 — Setup, lectura y foro (Mercedes 2C 2026)" \
  "SEMANA 1"

echo ""
echo "Done. Open with:"
echo "  xdg-open $DIR/index.html"
