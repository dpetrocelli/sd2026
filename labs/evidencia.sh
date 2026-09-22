#!/usr/bin/env bash
# evidencia.sh — SD2026 · TP3 Parte 0 · Misión k3s
#
# Junta la evidencia real de la misión y arma el informe que se entrega.
#
#   curl -sfL https://dpetrocelli.github.io/sd2026/labs/evidencia.sh | bash -s -- <legajo> <código>
#
# El script no corrige ni pone nota: copia lo que kubectl devuelve, marca qué encontró
# y qué no, y firma el resultado. La nota la ponen el corrector y el docente.
#
# Se corre con el cluster ARRIBA y con los pods hola y roto ya creados. Al final pregunta
# si desinstala k3s y recién ahí cierra el informe.

set -uo pipefail

LAB="SD1"
CLAVE="k3s-mercedes-2026"
VERSION_FORMATO="sd2026-tp3p0/1"
MARCA_FIRMA="<!-- FIRMA sd2026-tp3p0 -->"
MARCA_RESPUESTAS="<!-- RESPUESTAS -->"
ESTADO="${HOME}/.sd2026-mision"

# ── salida por pantalla ───────────────────────────────────────────────────────
if [ -t 2 ]; then V=$'\e[32m'; R=$'\e[31m'; A=$'\e[33m'; N=$'\e[0m'; B=$'\e[1m'
else V=""; R=""; A=""; N=""; B=""; fi
paso()  { printf '%s\n' "${B}==>${N} $*" >&2; }
ok()    { printf '    %sok%s   %s\n' "$V" "$N" "$*" >&2; }
falta() { printf '    %sfalta%s %s\n' "$R" "$N" "$*" >&2; }
aviso() { printf '    %s!%s    %s\n' "$A" "$N" "$*" >&2; }
morir() { printf '\n%serror:%s %s\n\n' "$R" "$N" "$*" >&2; exit 1; }
hay()   { command -v "$1" >/dev/null 2>&1; }

# Preguntas y respuestas van por la terminal, no por stdin: cuando esto corre como
# `curl | bash`, stdin es el propio script.
if (exec 3</dev/tty) 2>/dev/null; then TTY=/dev/tty; else TTY=""; fi

# ── criptografía de bolsillo ──────────────────────────────────────────────────
# La clave está en el script, que es público: la firma no es un secreto, es un
# precinto. Sirve para que un informe editado a mano o copiado de otro se note.
sha256_hex() {
  if hay openssl; then openssl dgst -sha256 -r 2>/dev/null | awk '{print $1}'
  elif hay sha256sum; then sha256sum | awk '{print $1}'
  elif hay shasum; then shasum -a 256 | awk '{print $1}'
  else printf 'sin-sha256\n'; fi
}
hmac_hex() { # $1 = clave, dato por stdin
  if hay openssl; then openssl dgst -sha256 -hmac "$1" -r 2>/dev/null | awk '{print $1}'
  elif hay python3; then python3 -c 'import sys,hmac,hashlib
print(hmac.new(sys.argv[1].encode(),sys.stdin.buffer.read(),hashlib.sha256).hexdigest())' "$1"
  else printf 'sin-hmac\n'; fi
}
# Mismo checksum que lab/verificar.py, para validar el código del lab sin salir de bash.
checksum_codigo() { # $1 = cuerpo del código (LAB-legajo-fecha-bits)
  local h=7 i c n s="" cuerpo="$1$CLAVE" alfabeto="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  for ((i = 0; i < ${#cuerpo}; i++)); do
    c=${cuerpo:i:1}
    printf -v n '%d' "'$c"
    h=$(((h * 31 + n) & 0xFFFFFFFF))
  done
  n=$h
  while [ "$n" -gt 0 ]; do
    s="${alfabeto:$((n % 36)):1}$s"
    n=$((n / 36))
  done
  s="0000$s"
  printf '%s\n' "${s: -4}"
}

# ── argumentos ────────────────────────────────────────────────────────────────
CIERRE_SOLO=0
ARGS=()
for a in "$@"; do
  case "$a" in
    --cierre) CIERRE_SOLO=1 ;;
    -h | --help)
      sed -n '2,/^$/p' "$0" 2>/dev/null | sed 's/^# \{0,1\}//' >&2 || true
      exit 0 ;;
    *) ARGS+=("$a") ;;
  esac
done
LEGAJO="${ARGS[0]:-}"
CODIGO="${ARGS[1]:-}"

[ -n "$LEGAJO" ] && [ -n "$CODIGO" ] || morir "faltan datos.
   uso: curl -sfL .../evidencia.sh | bash -s -- <legajo> <código del lab>
   ejemplo: ... | bash -s -- 12345 SD1-12345-260921-1F-A3K9"

case "$LEGAJO" in
  '' | *[!0-9]*) morir "el legajo tiene que ser un número: recibí '$LEGAJO'" ;;
esac

hay openssl || hay python3 || morir "necesito openssl (o python3) para firmar el informe.
   Instalalo con:  sudo apt-get install -y openssl"

CODIGO=$(printf '%s' "$CODIGO" | tr '[:lower:]' '[:upper:]' | tr -d '[:space:]')
IFS='-' read -r c_lab c_legajo c_fecha c_bits c_chk <<< "$CODIGO"
[ "${c_chk:-}" != "" ] || morir "el código del lab tiene que tener cinco partes separadas por guiones.
   recibí: $CODIGO"
[ "$c_lab" = "$LAB" ] || morir "el código no es del lab 1 (esperaba que empezara con $LAB): $CODIGO"
ESPERADO=$(checksum_codigo "$c_lab-$c_legajo-$c_fecha-$c_bits")
[ "$ESPERADO" = "$c_chk" ] || morir "el código del lab no valida: ¿está bien copiado?
   $CODIGO"
[ "$c_legajo" = "$LEGAJO" ] || morir "el código es del legajo $c_legajo y me pasaste $LEGAJO.
   Tienen que ser el mismo."

SALIDA="$(pwd)/mision-k3s-${LEGAJO}.md"

# ── huella de la máquina ──────────────────────────────────────────────────────
huella() {
  local mid=""
  for f in /etc/machine-id /var/lib/dbus/machine-id; do
    [ -r "$f" ] && { mid=$(cat "$f"); break; }
  done
  [ -n "$mid" ] || mid="$(hostname)-sin-machine-id"
  printf '%s' "$mid" | sha256_hex | cut -c1-12
}
HUELLA=$(huella)
QUIEN="${USER:-$(id -un 2>/dev/null || echo desconocido)}"
MAQUINA="$(hostname 2>/dev/null || echo desconocida)"
KERNEL="$(uname -srm 2>/dev/null || echo desconocido)"

# ── captura ───────────────────────────────────────────────────────────────────
# Cada bloque guarda el comando tal cual, el código de salida y la salida cruda.
CUERPO=""
agregar() { CUERPO="${CUERPO}$1"$'\n'; }

ULTIMA_SALIDA=""
ULTIMO_RC=0
bloque() { # $1 = comando, $2 = máximo de líneas (0 = todo)
  local cmd="$1" max="${2:-0}" out rc lineas recorte=""
  out=$(eval "$cmd" 2>&1); rc=$?
  ULTIMA_SALIDA="$out"; ULTIMO_RC=$rc
  lineas=$(printf '%s\n' "$out" | wc -l)
  if [ "$max" -gt 0 ] && [ "$lineas" -gt "$max" ]; then
    recorte="… (recortado: $lineas líneas en total)"
    out=$(printf '%s\n' "$out" | head -n "$max")
  fi
  agregar ""
  agregar "\`\$ $cmd\`"
  agregar '```text'
  agregar "$out"
  [ -n "$recorte" ] && agregar "$recorte"
  agregar '```'
  agregar "salida: $rc · $(date -u +%Y-%m-%dT%H:%M:%SZ) · huella $HUELLA"
  return $rc
}
# Igual que bloque pero sin dejar rastro en el informe: para averiguar cosas.
mirar() { ULTIMA_SALIDA=$(eval "$1" 2>&1); ULTIMO_RC=$?; printf '%s' "$ULTIMA_SALIDA"; }

# ── chequeos ──────────────────────────────────────────────────────────────────
CHEQUEOS=""
chequeo() { # $1 = qué, $2 = 0/1, $3 = qué se encontró
  if [ "$2" -eq 0 ]; then ok "$1"; CHEQUEOS="${CHEQUEOS}| $1 | sí | $3 |"$'\n'
  else falta "$1"; CHEQUEOS="${CHEQUEOS}| $1 | **no** | $3 |"$'\n'; fi
}
tiene() { printf '%s' "$1" | grep -qiE "$2"; }

# ── fase A: el cluster todavía está arriba ────────────────────────────────────
fase_a() {
  paso "Buscando tu cluster"
  KUBECTL=""
  for k in "kubectl" "sudo -n k3s kubectl" "sudo k3s kubectl" "k3d kubectl"; do
    if eval "$k get nodes" >/dev/null 2>&1; then KUBECTL="$k"; break; fi
  done
  [ -n "$KUBECTL" ] || morir "no puedo hablar con ningún cluster.
   Probá 'kubectl get nodes' a mano. Si no anda, el cluster no está levantado
   y la evidencia hay que sacarla con el cluster arriba."
  ok "kubectl: $KUBECTL"

  MOTOR="otro"
  hay k3s && MOTOR="k3s"
  [ "$MOTOR" = "otro" ] && hay k3d && MOTOR="k3d"
  ok "motor: $MOTOR"

  paso "Revisando que esté hecha la misión"
  eval "$KUBECTL get pod hola" >/dev/null 2>&1 ||
    morir "no encuentro el pod 'hola'. Crealo con:
   kubectl run hola --image=nginx:1.27-alpine"
  eval "$KUBECTL get pod roto" >/dev/null 2>&1 ||
    morir "no encuentro el pod 'roto'. La misión pide romper uno a propósito:
   kubectl run roto --image=nginx:no-existe"
  ok "los dos pods están"

  agregar "## 1. La máquina"
  agregar ""
  agregar "| | |"
  agregar "|---|---|"
  agregar "| usuario | \`$QUIEN\` |"
  agregar "| hostname | \`$MAQUINA\` |"
  agregar "| huella de máquina | \`$HUELLA\` |"
  agregar "| kernel | \`$KERNEL\` |"
  agregar "| motor | \`$MOTOR\` |"
  agregar "| kubectl | \`$KUBECTL\` |"
  agregar "| capturado | \`$(date -u +%Y-%m-%dT%H:%M:%SZ)\` (UTC) |"
  bloque "head -n 2 /etc/os-release" 4
  bloque "uptime" 2

  paso "Marca de instalación"
  agregar ""
  agregar "## 2. Cuándo se instaló k3s"
  if [ "$MOTOR" = "k3s" ]; then
    bloque "journalctl -u k3s --no-pager --output=short-iso 2>/dev/null | head -n 3" 3
    bloque "stat -c '%n instalado %y' /usr/local/bin/k3s 2>/dev/null" 2
    T_INSTALL=$(stat -c %Y /usr/local/bin/k3s 2>/dev/null || echo 0)
  else
    bloque "$KUBECTL get nodes -o jsonpath='{.items[0].metadata.creationTimestamp}'" 2
    T_INSTALL=0
  fi
  ok "instalación: $(fecha_de "$T_INSTALL")"

  paso "Nodo"
  agregar ""
  agregar "## 3. El nodo"
  bloque "$KUBECTL get nodes -o wide" 6
  NODOS="$ULTIMA_SALIDA"
  bloque "$KUBECTL version" 5
  bloque "$KUBECTL get node -o jsonpath='{range .items[*]}{.metadata.name} uid={.metadata.uid} creado={.metadata.creationTimestamp} version={.status.nodeInfo.kubeletVersion}{\"\\n\"}{end}'" 6
  NODO_ID="$ULTIMA_SALIDA"

  if tiene "$NODOS" '(^|[[:space:]])Ready([[:space:]]|,|$)'; then
    chequeo "Hay un nodo en estado Ready" 0 "$(printf '%s' "$NODOS" | sed -n '2p' | awk '{print $1, $2}')"
  else
    chequeo "Hay un nodo en estado Ready" 1 "ningún nodo aparece Ready"
  fi
  if tiene "$NODOS" 'v1\.[0-9]+\.[0-9]+\+k3s'; then
    chequeo "La versión del nodo es de k3s" 0 "$(printf '%s' "$NODOS" | grep -oE 'v1\.[0-9]+\.[0-9]+\+k3s[0-9]*' | head -n 1)"
  else
    chequeo "La versión del nodo es de k3s" 1 "$(printf '%s' "$NODOS" | grep -oE 'v1\.[0-9.]+[^ ]*' | head -n 1)"
  fi
  if tiene "$NODO_ID" "$MAQUINA"; then
    chequeo "El nodo se llama como la máquina" 0 "$MAQUINA"
  else
    chequeo "El nodo se llama como la máquina" 1 "nodo y hostname no coinciden"
  fi

  paso "Qué trae el cluster"
  agregar ""
  agregar "## 4. Qué está corriendo"
  bloque "$KUBECTL get pods -A" 15
  bloque "$KUBECTL get svc -A" 10

  paso "Pod hola"
  agregar ""
  agregar "## 5. El pod hola"
  bloque "$KUBECTL get pod hola -o wide" 4
  bloque "$KUBECTL get pod hola -o jsonpath='{.metadata.name} pod{\"\\n\"}uid: {.metadata.uid}{\"\\n\"}resourceVersion: {.metadata.resourceVersion}{\"\\n\"}creationTimestamp: {.metadata.creationTimestamp}{\"\\n\"}image: {.spec.containers[0].image}{\"\\n\"}imageID: {.status.containerStatuses[0].imageID}{\"\\n\"}phase: {.status.phase}{\"\\n\"}state: {.status.containerStatuses[0].state}{\"\\n\"}'" 12
  HOLA_JSON="$ULTIMA_SALIDA"
  bloque "$KUBECTL get events --field-selector involvedObject.name=hola --sort-by=.lastTimestamp" 15
  HOLA_EV="$ULTIMA_SALIDA"
  bloque "$KUBECTL exec hola -- wget -qO- localhost" 12
  HOLA_EXEC="$ULTIMA_SALIDA"
  T_HOLA=$(epoch_de "$(printf '%s' "$HOLA_JSON" | grep -m1 '^creationTimestamp:' | grep -oE '[0-9-]{10}T[0-9:]{8}Z')")

  if tiene "$HOLA_JSON" '^image: nginx:1\.27-alpine$'; then
    chequeo "El pod hola usa la imagen nginx:1.27-alpine" 0 "nginx:1.27-alpine"
  else
    chequeo "El pod hola usa la imagen nginx:1.27-alpine" 1 "$(printf '%s' "$HOLA_JSON" | grep -m1 '^image:' | cut -d' ' -f2-)"
  fi
  if tiene "$HOLA_JSON" '^phase: Running$'; then
    chequeo "El pod hola está Running" 0 "Running"
  else
    chequeo "El pod hola está Running" 1 "$(printf '%s' "$HOLA_JSON" | grep -m1 '^phase:' | cut -d' ' -f2-)"
  fi
  if tiene "$HOLA_EV" 'Pulled' && tiene "$HOLA_EV" 'Started'; then
    chequeo "Los eventos de hola muestran Pulled y Started" 0 "Pulled y Started"
  else
    chequeo "Los eventos de hola muestran Pulled y Started" 1 "faltan eventos (¿pasó más de una hora? se borran solos)"
  fi
  if tiene "$HOLA_EXEC" 'Welcome to nginx'; then
    chequeo "El exec a hola devuelve la página de nginx" 0 "Welcome to nginx"
  else
    chequeo "El exec a hola devuelve la página de nginx" 1 "el exec no devolvió la bienvenida de nginx"
  fi

  paso "Pod roto"
  agregar ""
  agregar "## 6. El pod roto"
  bloque "$KUBECTL get pod roto -o wide" 4
  bloque "$KUBECTL get pod roto -o jsonpath='{.metadata.name} pod{\"\\n\"}uid: {.metadata.uid}{\"\\n\"}resourceVersion: {.metadata.resourceVersion}{\"\\n\"}creationTimestamp: {.metadata.creationTimestamp}{\"\\n\"}image: {.spec.containers[0].image}{\"\\n\"}imageID: {.status.containerStatuses[0].imageID}{\"\\n\"}phase: {.status.phase}{\"\\n\"}state: {.status.containerStatuses[0].state}{\"\\n\"}'" 12
  ROTO_JSON="$ULTIMA_SALIDA"
  bloque "$KUBECTL get events --field-selector involvedObject.name=roto --sort-by=.lastTimestamp" 15
  ROTO_EV="$ULTIMA_SALIDA"
  bloque "$KUBECTL describe pod roto | tail -n 14" 14
  ROTO_DESC="$ULTIMA_SALIDA"
  T_ROTO=$(epoch_de "$(printf '%s' "$ROTO_JSON" | grep -m1 '^creationTimestamp:' | grep -oE '[0-9-]{10}T[0-9:]{8}Z')")

  if tiene "$ROTO_JSON" '^image: nginx:no-existe$'; then
    chequeo "El pod roto usa la imagen nginx:no-existe" 0 "nginx:no-existe"
  else
    chequeo "El pod roto usa la imagen nginx:no-existe" 1 "$(printf '%s' "$ROTO_JSON" | grep -m1 '^image:' | cut -d' ' -f2-)"
  fi
  if tiene "$ROTO_JSON$ROTO_DESC" 'ImagePullBackOff|ErrImagePull'; then
    chequeo "El pod roto quedó en ImagePullBackOff" 0 "$(printf '%s' "$ROTO_JSON$ROTO_DESC" | grep -oE 'ImagePullBackOff|ErrImagePull' | head -n 1)"
  else
    chequeo "El pod roto quedó en ImagePullBackOff" 1 "no aparece ImagePullBackOff ni ErrImagePull"
  fi
  if tiene "$ROTO_EV$ROTO_DESC" 'Failed to pull|failed to pull|pull access denied|not found'; then
    chequeo "Hay un evento que dice que no pudo bajar la imagen" 0 "$(printf '%s' "$ROTO_EV$ROTO_DESC" | grep -oiE 'failed to pull[^"]{0,40}' | head -n 1)"
  else
    chequeo "Hay un evento que dice que no pudo bajar la imagen" 1 "no encontré el evento de fallo"
  fi

  guardar_estado
}

fecha_de() { [ "${1:-0}" -gt 0 ] 2>/dev/null && date -u -d "@$1" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || printf 'desconocida\n'; }
epoch_de() { [ -n "${1:-}" ] && date -u -d "$1" +%s 2>/dev/null || printf '0\n'; }

guardar_estado() {
  T_CAPTURA=$(date -u +%s)
  mkdir -p "$ESTADO"
  printf '%s' "$CUERPO" > "$ESTADO/cuerpo-a.md"
  printf '%s' "$CHEQUEOS" > "$ESTADO/chequeos-a.md"
  {
    printf 'LEGAJO=%q\nCODIGO=%q\nHUELLA=%q\nMOTOR=%q\nKUBECTL=%q\n' "$LEGAJO" "$CODIGO" "$HUELLA" "$MOTOR" "$KUBECTL"
    printf 'T_INSTALL=%q\nT_HOLA=%q\nT_ROTO=%q\nT_CAPTURA=%q\n' "$T_INSTALL" "$T_HOLA" "$T_ROTO" "$T_CAPTURA"
  } > "$ESTADO/datos-a.sh"
}

leer_estado() {
  [ -r "$ESTADO/datos-a.sh" ] || morir "no hay una captura previa en $ESTADO.
   Corré el script con el cluster arriba antes de usar --cierre."
  # shellcheck disable=SC1090
  . "$ESTADO/datos-a.sh"
  CUERPO=$(cat "$ESTADO/cuerpo-a.md")$'\n'
  CHEQUEOS=$(cat "$ESTADO/chequeos-a.md")$'\n'
  [ "$LEGAJO" = "${ARGS[0]}" ] || morir "la captura guardada es del legajo $LEGAJO y vos sos ${ARGS[0]}."
}

# ── desinstalación ────────────────────────────────────────────────────────────
# Sin terminal no se puede preguntar, y desinstalar sin preguntar no se hace.
sin_terminal() {
  printf '\n  No tengo terminal para preguntarte, así que no toco nada.\n' >&2
  printf '  La evidencia del cluster ya está guardada en %s\n\n' "$ESTADO" >&2
  printf '  Desinstalá vos con:\n    %s\n\n  y después cerrá el informe con:\n' "${1:-<el desinstalador de tu motor>}" >&2
  printf '    curl -sfL https://dpetrocelli.github.io/sd2026/labs/evidencia.sh | bash -s -- %s %s --cierre\n\n' "$LEGAJO" "$CODIGO" >&2
  exit 0
}

desinstalar() {
  paso "Desinstalar k3s"
  local cmd=""
  if [ "$MOTOR" = "k3s" ] && [ -x /usr/local/bin/k3s-uninstall.sh ]; then
    cmd="sudo /usr/local/bin/k3s-uninstall.sh"
  elif [ "$MOTOR" = "k3d" ]; then
    cmd="k3d cluster delete --all"
  fi

  [ -n "$TTY" ] || sin_terminal "$cmd"

  printf '\n  La evidencia del cluster ya está guardada. Falta el último paso de la misión:\n' >&2
  printf '  %sdesinstalar k3s%s. Esto borra el cluster, los pods y los datos. Se reinstala en dos minutos.\n\n' "$B" "$N" >&2
  printf '  ¿Lo desinstalo yo con «%s»? [s/N] ' "${cmd:-no sé cómo}" >&2
  local resp=""
  read -r resp < "$TTY" || { aviso "no pude leer tu respuesta"; sin_terminal "$cmd"; }
  case "$resp" in
    s | S | si | Si | SI | sí | Sí)
      [ -n "$cmd" ] || morir "no sé cómo desinstalar tu motor: hacelo a mano y volvé con --cierre"
      paso "Desinstalando"
      eval "$cmd" >/dev/null 2>&1
      ok "desinstalado"
      ;;
    *)
      printf '\n  Bien. Desinstalá vos, en otra terminal, con:\n    %s\n' "${cmd:-<el desinstalador de tu motor>}" >&2
      printf '  Cuando termines, apretá Enter acá para cerrar el informe. ' >&2
      read -r _ < "$TTY" || true
      ;;
  esac
}

# ── fase B: después de desinstalar ────────────────────────────────────────────
fase_b() {
  paso "Cerrando: revisando que no haya quedado nada"
  T_CIERRE=$(date -u +%s)
  agregar ""
  agregar "## 7. Después de desinstalar"
  agregar ""
  agregar "Cierre: \`$(date -u +%Y-%m-%dT%H:%M:%SZ)\` (UTC) · huella \`$HUELLA\` · usuario \`$QUIEN\` · hostname \`$MAQUINA\`"
  bloque "command -v k3s kubectl k3d || echo 'no quedó ninguno de los tres'" 6
  RESTOS="$ULTIMA_SALIDA"
  bloque "ls /usr/local/bin/k3s* 2>/dev/null || echo 'no quedan los scripts de k3s'" 6
  bloque "systemctl is-active k3s 2>/dev/null || echo 'el servicio k3s no existe'" 3
  SERVICIO="$ULTIMA_SALIDA"
  bloque "ls /etc/rancher /var/lib/rancher 2>/dev/null || echo 'no quedan directorios de rancher'" 8

  if tiene "$RESTOS" 'no quedó ninguno' || ! printf '%s' "$RESTOS" | grep -qE '/k3s$'; then
    if tiene "$SERVICIO" 'active' && ! tiene "$SERVICIO" 'inactive|no existe'; then
      chequeo "k3s ya no está en la máquina" 1 "el servicio k3s sigue activo"
    else
      chequeo "k3s ya no está en la máquina" 0 "no quedó el binario ni el servicio"
    fi
  else
    chequeo "k3s ya no está en la máquina" 1 "todavía está el binario de k3s"
  fi

  agregar ""
  agregar "## 8. Línea de tiempo"
  agregar ""
  agregar "| momento | UTC | epoch |"
  agregar "|---|---|---|"
  agregar "| instalación de k3s | $(fecha_de "$T_INSTALL") | $T_INSTALL |"
  agregar "| creación del pod hola | $(fecha_de "$T_HOLA") | $T_HOLA |"
  agregar "| creación del pod roto | $(fecha_de "$T_ROTO") | $T_ROTO |"
  agregar "| captura de la evidencia | $(fecha_de "$T_CAPTURA") | $T_CAPTURA |"
  agregar "| desinstalación | $(fecha_de "$T_CIERRE") | $T_CIERRE |"

  local coherente=0 detalle="instalación → pods → captura → desinstalación"
  [ "$T_INSTALL" -gt 0 ] && [ "$T_HOLA" -gt 0 ] && [ "$T_INSTALL" -gt "$T_HOLA" ] && { coherente=1; detalle="la instalación figura después del pod"; }
  [ "$T_HOLA" -gt 0 ] && [ "$T_HOLA" -gt "$T_CAPTURA" ] && { coherente=1; detalle="el pod figura después de la captura"; }
  [ "$T_CIERRE" -lt "$T_CAPTURA" ] && { coherente=1; detalle="la desinstalación figura antes de la captura"; }
  chequeo "Los tiempos van en orden" "$coherente" "$detalle"
  chequeo "La huella de máquina es la misma de punta a punta" 0 "$HUELLA"
}

# ── informe ───────────────────────────────────────────────────────────────────
escribir_informe() {
  paso "Escribiendo el informe"
  local tmp cuerpo firma hoy
  tmp=$(mktemp)
  hoy=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  {
    printf '# Misión k3s · TP3 Parte 0 — legajo %s\n\n' "$LEGAJO"
    printf 'Sistemas Distribuidos y Programación Paralela · 2026 · sede Mercedes\n\n'
    printf '| | |\n|---|---|\n'
    printf '| legajo | **%s** |\n' "$LEGAJO"
    printf '| código del lab guiado | `%s` |\n' "$CODIGO"
    printf '| huella de máquina | `%s` |\n' "$HUELLA"
    printf '| informe generado | `%s` (UTC) |\n' "$hoy"
    printf '| formato | `%s` |\n\n' "$VERSION_FORMATO"
    printf 'Este informe lo armó `evidencia.sh` con la salida real de `kubectl` en la máquina\n'
    printf 'del alumno. Las secciones 1 a 8 no se editan: están firmadas al pie. Lo único que\n'
    printf 'escribe el alumno son las tres respuestas del final.\n\n'
    printf -- '---\n\n'
    printf '%s\n' "$CUERPO"
    printf -- '---\n\n'
    printf '## 9. Lo que el script encontró\n\n'
    printf 'El script no pone nota: solo dice qué vio y qué no. La corrección se hace mirando\n'
    printf 'la evidencia de arriba.\n\n'
    printf '| qué se buscaba | ¿está? | qué se encontró |\n|---|---|---|\n'
    printf '%s\n' "$CHEQUEOS"
  } > "$tmp"

  cuerpo=$(cat "$tmp")
  firma=$(printf '%s' "$cuerpo" | hmac_hex "$CLAVE:$LEGAJO:$CODIGO" | cut -c1-32)
  local sha
  sha=$(printf '%s' "$cuerpo" | sha256_hex | cut -c1-16)

  {
    cat "$tmp"
    printf '%s\n' "$MARCA_FIRMA"
    printf 'FIRMA %s legajo=%s codigo=%s huella=%s ts=%s sha=%s mac=%s\n\n' \
      "$VERSION_FORMATO" "$LEGAJO" "$CODIGO" "$HUELLA" "$hoy" "$sha" "$firma"
    printf -- '---\n\n'
    printf '%s\n' "$MARCA_RESPUESTAS"
    printf '## 10. Reflexión — esto lo escribís vos\n\n'
    printf 'Tres a cinco renglones cada una, con tus palabras, citando lo que viste más arriba.\n\n'
    printf '### 1. ¿Por qué el pod `roto` es un error de la imagen y no de tu máquina?\n\n'
    printf 'Justificá con lo que viste en `describe` y en los eventos.\n\n'
    printf '_Respuesta:_\n\n\n\n'
    printf '### 2. ¿Qué diferencia hay entre control-plane y worker, y por qué acá la misma máquina hace los dos papeles?\n\n'
    printf '_Respuesta:_\n\n\n\n'
    printf '### 3. ¿Qué pasó con el pod y con los datos al desinstalar? ¿Por qué no hay que tenerle miedo a romper el cluster local?\n\n'
    printf '_Respuesta:_\n\n\n\n'
  } > "$SALIDA"
  rm -f "$tmp"
  rm -rf "$ESTADO"
}

# ── principal ─────────────────────────────────────────────────────────────────
printf '\n%sMisión k3s · TP3 Parte 0%s · legajo %s\n\n' "$B" "$N" "$LEGAJO" >&2

if [ "$CIERRE_SOLO" -eq 1 ]; then
  leer_estado
  fase_b
else
  fase_a
  desinstalar
  fase_b
fi
escribir_informe

FALTAN=$(printf '%s' "$CHEQUEOS" | grep -c '| \*\*no\*\* |' || true)
printf '\n%s==>%s informe: %s%s%s\n' "$B" "$N" "$B" "$SALIDA" "$N" >&2
if [ "$FALTAN" -gt 0 ]; then
  printf '    %s%s cosas no las encontré%s. Están marcadas en la tabla del final.\n' "$A" "$FALTAN" "$N" >&2
  printf '    Podés rehacer la misión y volver a correr el script, o entregarlo así y explicar qué pasó.\n' >&2
else
  printf '    %sestá todo%s\n' "$V" "$N" >&2
fi
printf '\n  Falta lo tuyo: abrí el archivo y respondé las tres preguntas del final (sección 10).\n' >&2
printf '  Después subilo a LidIA. No toques nada arriba de la firma.\n\n' >&2
