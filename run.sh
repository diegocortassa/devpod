#!/bin/bash
set -e

CONTAINER_RUNTIME=
CONTAINER_NAME=
WORKSPACE_DIR=
RUN_OPTIONS=()
PERSISTENCE_MODE=temporary
PERSISTENCE_STATUS="🗑️ temporary"
INSECURE_MODE=0
COMMAND=()

usage() {
  cat <<'EOF'
Usage: run.sh [--persistent|-p] [--insecure] [--] [command [args...]]

Launch the development container for the current directory.

Options:
  -p, --persistent  Keep the container after it exits
  --insecure        Enable privileged container options
  -h, --help        Show this help message
  --                Stop processing launcher options

With no command a shell is started. Commands and arguments are passed to the
container.
EOF
}

parse_options() {
  RUN_OPTIONS=(--rm)
  PERSISTENCE_MODE=temporary
  PERSISTENCE_STATUS="🗑️ temporary"
  INSECURE_MODE=0

  while (($# > 0)); do
    case "$1" in
      --help|-h)
        usage
        exit 0
        ;;
      --persistent|-p)
        RUN_OPTIONS=()
        PERSISTENCE_MODE=persistent
        PERSISTENCE_STATUS="💾 persistent"
        shift
        ;;
      --insecure)
        INSECURE_MODE=1
        shift
        ;;
      --)
        shift
        break
        ;;
      -*)
        printf 'Error: unknown option: %s\n' "$1" >&2
        usage
        return 2
        ;;
      *)
        break
        ;;
    esac
  done

  if (($# == 0)); then
    set -- /bin/bash
  fi
  COMMAND=("$@")
}

select_container_runtime() {
  if command -v podman >/dev/null 2>&1; then
    CONTAINER_RUNTIME=podman
  elif command -v docker >/dev/null 2>&1; then
    CONTAINER_RUNTIME=docker
  else
    printf 'Error: neither Podman nor Docker is installed.\n' >&2
    return 1
  fi
}

set_container_name() {
  local directory_name

  WORKSPACE_DIR=$(basename -- "$PWD")
  if [[ -z "$WORKSPACE_DIR" || "$WORKSPACE_DIR" == / ]]; then
    WORKSPACE_DIR=workspace
  fi

  directory_name=$(printf '%s' "$WORKSPACE_DIR" | LC_ALL=C sed 's/[^a-zA-Z0-9_.-]/-/g; s/^[^a-zA-Z0-9]*//')
  CONTAINER_NAME="devpod-${directory_name:-agent}"
}

container_exists() {
  "$CONTAINER_RUNTIME" inspect "$CONTAINER_NAME" >/dev/null 2>&1
}

enter_existing_container() {
  local is_running auto_remove

  is_running=$("$CONTAINER_RUNTIME" inspect --format '{{.State.Running}}' "$CONTAINER_NAME")
  auto_remove=$("$CONTAINER_RUNTIME" inspect --format '{{.HostConfig.AutoRemove}}' "$CONTAINER_NAME")
  if [[ "$auto_remove" == true ]]; then
    PERSISTENCE_MODE=temporary
    PERSISTENCE_STATUS="temporary 🗑️"
  else
    PERSISTENCE_MODE=persistent
    PERSISTENCE_STATUS="persistent 💾"
  fi

  if [[ "$is_running" == true ]]; then
    printf 'Entering running 🟢 %s container %s...\n' "$PERSISTENCE_STATUS" "$CONTAINER_NAME"
    exec "$CONTAINER_RUNTIME" exec -it "$CONTAINER_NAME" "${COMMAND[@]}"
  fi

  printf 'Re-Starting %s container %s...\n' "$PERSISTENCE_STATUS" "$CONTAINER_NAME"
  exec "$CONTAINER_RUNTIME" start -ai "$CONTAINER_NAME"
}

prepare_host_directories() {
  mkdir -p \
    "$HOME/.local/share/opencode" \
    "$HOME/.cache/opencode" \
    "$HOME/.config/opencode"
}

create_container() {
  local container_options=(
    --name "$CONTAINER_NAME"
    --hostname "$CONTAINER_NAME"
    -v /tmp/.X11-unix:/tmp/.X11-unix
    -v /dev/dri/card0:/dev/dri/card0
    -v /dev/dri/renderD128:/dev/dri/renderD128
    -v /etc/timezone:/etc/timezone:ro
    --device /dev/dri:/dev/dri
    --device /dev/snd:/dev/snd
    --env "DISPLAY=${DISPLAY:-}"
    --env "DEVPOD_CONTAINER_NAME=$CONTAINER_NAME"
    --env "DEVPOD_PERSISTENCE=$PERSISTENCE_MODE"
    --env "INSECURE=$INSECURE_MODE"
    --env QT_X11_NO_MITSHM=1
    -v "$HOME/.local/share/opencode:/root/.local/share/opencode"
    -v "$HOME/.cache/opencode:/root/.cache/opencode"
    -v "$HOME/.config/opencode:/root/.config/opencode"
    -v "$PWD:/$WORKSPACE_DIR"
    -w "/$WORKSPACE_DIR"
  )

  if ((INSECURE_MODE)); then
    container_options+=(
      --privileged
      --device /dev/fuse:rw
      --security-opt unmask=ALL
      --security-opt seccomp=unconfined
      --security-opt label=disable
    )
  fi

  printf 'Creating new %s container %s...\n' "$PERSISTENCE_STATUS" "$CONTAINER_NAME"

  "$CONTAINER_RUNTIME" run -it "${RUN_OPTIONS[@]}" "${container_options[@]}" \
    devpod "${COMMAND[@]}"
}

main() {
  parse_options "$@"
  select_container_runtime
  set_container_name

  if container_exists; then
    enter_existing_container
  fi

  prepare_host_directories
  create_container
}

main "$@"
