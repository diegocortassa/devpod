alias ll='ls -lah --color'
alias la='ls -A'
alias l='ls -CF'

# Prompt
parse_git_branch() {
    git branch 2>/dev/null | grep "*" | sed "s/* //"
}
export PS1="\u@\h:\w\$ "
export PS1="\u@\h:\w$(parse_git_branch)\$ "
export PS1="\[\e[1;32m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ "
PATH="/home/${USER_NAME}/.local/bin:$PATH"
# --- starship prompt ---
eval "$(starship init bash)"
# disable starship
alias nostarship="PROMPT_COMMAND=;PS1='\u@\h:\w\$ '"

# --- Dev container banner ---
show_dev_banner() {
  echo ""
  echo "=================================================="
  echo "  🧰 DevPod container: $DEVPOD_CONTAINER_NAME"
  echo "=================================================="
  echo "  User: $(whoami)"
  echo "  Workspace: $(pwd)"
  echo ""

  if command -v opencode >/dev/null 2>&1; then
    echo "  opencode: $(opencode --version)"
  fi

  if command -v node >/dev/null 2>&1; then
    echo "  Node: $(node --version)"
  fi

  if command -v go >/dev/null 2>&1; then
    echo "  Go: $(go version | awk '{print $3}')"
  fi

  if command -v rustc >/dev/null 2>&1; then
    echo "  Rust: $(rustc --version)"
  fi

  if command -v python3 >/dev/null 2>&1; then
    echo "  Python: $(python3 --version | awk '{print $2}')"
  fi

  if command -v uv >/dev/null 2>&1; then
    echo "  uv: $(uv --version | awk '{print $2}')"
  fi

  echo "=================================================="
  echo ""
  if [[ ${INSECURE:-0} == 1 ]]; then
    echo "***************************************************"
    echo "  ⚠️ WARNING: This container has extensive privileges on the host."
    echo "***************************************************"
    echo ""
  fi
}

# run only in interactive shells
if [[ $- == *i* ]]; then
  show_dev_banner
fi
