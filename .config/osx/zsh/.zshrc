export PATH="$PATH:$HOME/.spicetify"
export PATH="$(brew --prefix)/opt/openjdk@21/bin:$PATH"
export JAVA_HOME=$(/usr/libexec/java_home -v 21)

export CLICOLOR=1
alias ls='ls -G'
alias ll='ls -lahG'
alias mcp-reactbits='mcp reactbits'
alias mcp-kill-reactbits='mcp-kill reactbits'

export GGML_METAL_TENSOR_DISABLE=1

zen() {
  command open -a "/Applications/Zen.app" -- "$@"
}
export PATH="$HOME/.local/bin:$PATH"

export PATH="$PATH:$HOME/.lmstudio/bin"

# OpenCode remote vLLM endpoint.
export VLLM_BASE_URL="http://127.0.0.1:8000/v1"
export VLLM_API_KEY="dummy"

# Load machine-specific secrets from the ignored dotfiles environment file.
if [[ -r "$HOME/dotfiles/.env" ]]; then
  source "$HOME/dotfiles/.env"
fi

llm-server-local() {
  local model="${LLAMA_SERVER_MODEL:-}"
  local api_key="${LOCAL_LLM_API_KEY:-}"
  if [[ -z "$model" || -z "$api_key" ]]; then
    echo "Set LLAMA_SERVER_MODEL and LOCAL_LLM_API_KEY in $HOME/dotfiles/.env."
    return 1
  fi

  command llama-server \
    --hf-repo "$model" \
    --alias "$model" \
    --host 127.0.0.1 \
    --port 8080 \
    --api-key "$api_key" \
    --reasoning off \
    --chat-template-kwargs '{"enable_thinking":true,"preserve_thinking":false}' \
    "$@"
}

mlx-server-local() {
  local model="${MLX_SERVER_MODEL:-}"
  if [[ -z "$model" ]]; then
    echo "Set MLX_SERVER_MODEL in $HOME/dotfiles/.env."
    return 1
  fi

  command mlx_lm.server \
    --model "$model" \
    --host 127.0.0.1 \
    --port 8080 \
    "$@"
}


mcplist() {
  python3 "$HOME/dotfiles/.config/osx/zsh/mcplist.py"
}

llm-cli-local() {
  local model="${LLAMA_CLI_MODEL_PATH:-}"
  if [[ -z "$model" ]]; then
    echo "Set LLAMA_CLI_MODEL_PATH in $HOME/dotfiles/.env."
    return 1
  fi
  command llama-cli \
    -m "$model" \
    "$@"
}

# Register private command names from .env without publishing them.
_register_private_command() {
  local name="$1"
  local target="$2"
  case "$name" in
    ""|[!A-Za-z_]*|*[!A-Za-z0-9_-]*) return ;;
  esac
  eval "${name}() { ${target} \"\$@\"; }"
}
_register_private_command "${LLAMA_SERVER_COMMAND:-}" llm-server-local
_register_private_command "${MLX_SERVER_COMMAND:-}" mlx-server-local
_register_private_command "${LLAMA_CLI_COMMAND:-}" llm-cli-local
unfunction _register_private_command

pi() {
  NVIDIA_API_KEY="$(security find-generic-password -a "$USER" -s nvidia-nim -w)" command pi "$@"
}

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
eval "$(zoxide init zsh)"

# CloakBrowser — stealth Chromium with Decodo proxy
cloak() {
  local BINARY="$HOME/.cloakbrowser/chromium-145.0.7632.109.2/Chromium.app/Contents/MacOS/Chromium"
  if [[ ! -f "$BINARY" ]]; then
    echo "CloakBrowser binary not found. Run: pip install cloakbrowser"
    return 1
  fi

  local URL="${1:-about:blank}"
  local proxy_url="${DECODO_PROXY_URL:-}"
  if [[ -z "$proxy_url" ]]; then
    echo "Set DECODO_PROXY_URL in $HOME/dotfiles/.env."
    return 1
  fi

  open -a "Chromium" \\
    --args \\
    --proxy-server="$proxy_url" \\
    --fingerprint-platform=macos \\
    --no-sandbox \\
    --ignore-gpu-blocklist \\
    --user-data-dir="$HOME/.cloakbrowser/profile" \\
    "$URL"
}
