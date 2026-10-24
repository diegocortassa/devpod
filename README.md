# DevPod

DevPod builds and launches a Linux development container with OpenCode, Node.js, Go, Rust, Python `uv`, and common command-line tools. The launcher mounts your current directory at `/<folder-name>` and, if `--persistent` is used, reuses a container for that directory.

## Requirements

- Linux with Bash
- Podman or Docker
- X11 and the host device paths `/dev/dri` and `/dev/snd` for the graphics and audio mounts configured by the launcher

The scripts prefer Podman when it is installed; otherwise they use Docker.

## Install

Keep this repository at a stable path, then build the container image:

```bash
cd /path/to/DevPod
bash build.sh
```

For convenient use, add an alias to `~/.bashrc`, replacing the path with the location of this repository:
 
```bash
alias devpod='bash /path/to/DevPod/run.sh'
```

Reload your shell with `source ~/.bashrc`. You can then run `devpod` from any project directory. To rebuild the image after changing the Dockerfile, run `bash /path/to/DevPod/build.sh`.

## Start a Workspace

Run the alias from the project directory you want to open:

```bash
cd /path/to/your/project
devpod
```

With no command specified, the container starts Bash. To run a command instead:

```bash
devpod opencode
devpod npm test
```

Launcher options go before the command. Use `--` to end option parsing explicitly:

```bash
devpod --persistent -- opencode
devpod --insecure -- opencode
```

Unknown launcher options are rejected. Arguments after the command are passed through to it.

## Container Modes

| Mode | Invocation | Behavior |
| --- | --- | --- |
| Temporary (default) | `devpod` | Removes the container when it exits. The workspace and OpenCode directories mounted from the host remain. |
| Persistent | `devpod --persistent` or `devpod -p` | Keeps the container after it exits so it can be started again. |
| Insecure | `devpod --insecure` | Enables privileged mode and additional container capabilities/security options. Use only when required. |

The container name is `devpod-<directory-name>`, derived from the current directory. If that container is already running, the launcher enters it and runs the requested command. If a persistent container exists but is stopped, the launcher starts it attached; in that case, it does not run a new command argument.

Persistence is set when the container is first created. An existing container is reused with its original mode, regardless of whether a different mode is requested on a later launch.

Existing containers keep their original mount configuration. Remove and recreate an older persistent container once to use the folder-name mount path described below.

New containers receive these environment variables:

- `DEVPOD_CONTAINER_NAME`: the container name
- `DEVPOD_PERSISTENCE`: `persistent` or `temporary`
- `INSECURE`: `1` when launched with `--insecure`, otherwise `0`

## Host Data and Devices

The launcher mounts the current directory at `/<folder-name>` and starts the command in that directory. For example, a host folder named `my-project` is available at `/my-project`. It also mounts these host directories for OpenCode data:

- `~/.local/share/opencode`
- `~/.cache/opencode`
- `~/.config/opencode`

It also configures X11, graphics and audio device mounts, and the host timezone. The corresponding host paths must be available for container startup.