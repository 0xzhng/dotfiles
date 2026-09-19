export PATH="$PATH:$HOME/.spicetify"
export PATH="$(brew --prefix)/opt/openjdk@21/bin:$PATH"
export JAVA_HOME=$(/usr/libexec/java_home -v 21)

export CLICOLOR=1
alias ls='ls -G'
alias ll='ls -lahG'
alias mcp-reactbits='mcp reactbits'
alias mcp-kill-reactbits='mcp-kill reactbits'
alias gcc='gcc-16'
alias g++='g++-16'

export GGML_METAL_TENSOR_DISABLE=1

zen() {
  command open -a "/Applications/Zen.app" -- "$@"
}
export PATH="$HOME/.local/bin:$PATH"

export PATH="$PATH:$HOME/.lmstudio/bin"

# OpenCode remote vLLM endpoint.
export VLLM_BASE_URL="http://127.0.0.1:8000/v1"
export VLLM_API_KEY="dummy"

# Load machine-specific values, but do not expose them to every child process.
if [[ -r "$HOME/dotfiles/.env" ]]; then
  source "$HOME/dotfiles/.env"
  typeset +x LOCAL_LLM_API_KEY DECODO_PROXY_URL \
    LLAMA_SERVER_MODEL LLAMA_SERVER_ALIAS LLAMA_SERVER_API_KEY_FILE LLAMA_SERVER_COMMAND \
    MTPLX_MODEL MTPLX_MODEL_ID MTPLX_SERVER_COMMAND \
    MLX_VLM_PRIMARY_MODEL MLX_VLM_PRIMARY_MODEL_CACHE MLX_VLM_PRIMARY_COMMAND \
    MLX_VLM_SECONDARY_MODEL MLX_VLM_SECONDARY_MODEL_CACHE MLX_VLM_SECONDARY_COMMAND \
    MLX_WHISPER_SMALL_MODEL MLX_WHISPER_MEDIUM_MODEL MLX_WHISPER_LARGE_MODEL
fi

mlx-whisper() {
  MLX_WHISPER_SMALL_MODEL="$MLX_WHISPER_SMALL_MODEL" \
  MLX_WHISPER_MEDIUM_MODEL="$MLX_WHISPER_MEDIUM_MODEL" \
  MLX_WHISPER_LARGE_MODEL="$MLX_WHISPER_LARGE_MODEL" \
    python3 "$HOME/dotfiles/.config/osx/zsh/mlx_whisper.py" "$@"
}

llm-server-local() {
  local model="${LLAMA_SERVER_MODEL:-}"
  local model_alias="${LLAMA_SERVER_ALIAS:-}"
  local api_key_file="${LLAMA_SERVER_API_KEY_FILE:-}"
  if [[ -z "$model" || -z "$model_alias" || -z "$api_key_file" ]]; then
    echo "Set LLAMA_SERVER_MODEL, LLAMA_SERVER_ALIAS, and LLAMA_SERVER_API_KEY_FILE in $HOME/dotfiles/.env."
    return 1
  fi
  if [[ ! -f "$model" ]]; then
    echo "GGUF model not found: $model"
    return 1
  fi
  if [[ ! -r "$api_key_file" ]]; then
    echo "llama.cpp API key file not readable: $api_key_file"
    return 1
  fi

  command llama-server \
    --model "$model" \
    --alias "$model_alias" \
    --host 0.0.0.0 \
    --port 8080 \
    --api-key-file "$api_key_file" \
    --ctx-size 262144 \
    --n-gpu-layers 99 \
    --flash-attn on \
    --cache-type-k q8_0 \
    --cache-type-v q8_0 \
    --reasoning auto \
    --reasoning-format deepseek \
    --chat-template-kwargs '{"reasoning_effort":"medium","preserve_thinking":false}' \
    --n-predict 16384 \
    --temp 1.0 \
    --top-p 0.95 \
    --top-k 20 \
    "$@"
}

_mtplx_server_local() {
  local model="${MTPLX_MODEL:-}"
  local model_id="${MTPLX_MODEL_ID:-}"
  local server="$HOME/.local/bin/mtplx"
  local api_key_file="${LLAMA_SERVER_API_KEY_FILE:-}"

  if [[ -z "$model" || -z "$model_id" || -z "$api_key_file" ]]; then
    echo "Set MTPLX_MODEL, MTPLX_MODEL_ID, and LLAMA_SERVER_API_KEY_FILE in $HOME/dotfiles/.env."
    return 1
  fi
  if [[ ! -x "$server" ]]; then
    echo "MTPLX server not found: $server"
    return 1
  fi
  if [[ ! -d "$model" ]]; then
    echo "MTPLX model is not cached: $model"
    return 1
  fi
  if [[ ! -r "$api_key_file" ]]; then
    echo "MTPLX API key file not readable: $api_key_file"
    return 1
  fi

  command "$server" serve \
    --model "$model" \
    --model-id "$model_id" \
    --host 0.0.0.0 \
    --port 8089 \
    --api-key-file "$api_key_file" \
    --max-tokens 16384 \
    --reasoning auto \
    --reasoning-effort medium \
    --preserve-thinking auto \
    --tool-prompt-mode native \
    --no-stats-footer \
    "$@"
}

_mlx_vlm_secondary_local() {
  local model="${MLX_VLM_SECONDARY_MODEL:-}"
  local model_cache="${MLX_VLM_SECONDARY_MODEL_CACHE:-}"
  local server="$HOME/.local/bin/mlx_vlm.server"

  if [[ -z "$model" || -z "$model_cache" ]]; then
    echo "Set MLX_VLM_SECONDARY_MODEL and MLX_VLM_SECONDARY_MODEL_CACHE in $HOME/dotfiles/.env."
    return 1
  fi
  if [[ ! -x "$server" ]]; then
    echo "MLX-VLM server not found: $server"
    return 1
  fi
  if [[ ! -d "$model_cache/snapshots" ]]; then
    echo "Prism model is not cached: $model_cache"
    return 1
  fi

  command "$server" \
    --model "$model" \
    --host 0.0.0.0 \
    --port 8089 \
    --max-tokens 16384 \
    --enable-thinking \
    --kv-bits 4 \
    --kv-quant-scheme uniform \
    --kv-group-size 64 \
    --max-kv-size 262144 \
    "$@"
}

_mlx_vlm_primary_local() {
  local model="${MLX_VLM_PRIMARY_MODEL:-}"
  local model_cache="${MLX_VLM_PRIMARY_MODEL_CACHE:-}"
  local server="$HOME/.local/bin/mlx_vlm.server"

  if [[ -z "$model" || -z "$model_cache" ]]; then
    echo "Set MLX_VLM_PRIMARY_MODEL and MLX_VLM_PRIMARY_MODEL_CACHE in $HOME/dotfiles/.env."
    return 1
  fi
  if [[ ! -x "$server" ]]; then
    echo "MLX-VLM server not found: $server"
    return 1
  fi
  if [[ ! -d "$model_cache/snapshots" ]]; then
    echo "MLX model is not cached: $model_cache"
    return 1
  fi

  command "$server" \
    --model "$model" \
    --host 0.0.0.0 \
    --port 8089 \
    --max-tokens 16384 \
    --enable-thinking \
    --kv-bits 4 \
    --kv-quant-scheme uniform \
    --kv-group-size 64 \
    --max-kv-size 262144 \
    "$@"
}

list() {
  if [[ "$#" -eq 1 && "$1" == "--models" ]]; then
    printf '%-16s %s\n' \
      "${LLAMA_SERVER_COMMAND:-llm-server-local}" "llama.cpp on :8080" \
      "${MTPLX_SERVER_COMMAND:-mtplx-server-local}" "MTPLX on :8089" \
      "${MLX_VLM_PRIMARY_COMMAND:-mlx-vlm-primary}" "MLX-VLM on :8089" \
      "${MLX_VLM_SECONDARY_COMMAND:-mlx-vlm-secondary}" "MLX-VLM on :8089" \
      "mlx-whisper-server" "MLX Whisper dictation — F5 while enabled"
    return 0
  fi

  echo "Usage: list --models"
  return 2
}

# Register private command names from .env without publishing them.
_register_private_command() {
  local name="$1"
  local target="$2"
  case "$name" in
    ""|[!A-Za-z_]*|*[!A-Za-z0-9_.-]*) return ;;
  esac
  eval "${name}() { ${target} \"\$@\"; }"
}
_register_private_command "${LLAMA_SERVER_COMMAND:-}" llm-server-local
_register_private_command "${MTPLX_SERVER_COMMAND:-}" _mtplx_server_local
_register_private_command "${MLX_VLM_PRIMARY_COMMAND:-}" _mlx_vlm_primary_local
_register_private_command "${MLX_VLM_SECONDARY_COMMAND:-}" _mlx_vlm_secondary_local

unfunction _register_private_command

# AWS credentials for Pi (amazon-bedrock provider)
export AWS_PROFILE=default
export AWS_REGION=us-east-1

pi() {
  LOCAL_LLM_API_KEY="$LOCAL_LLM_API_KEY" \
  NVIDIA_API_KEY="$(security find-generic-password -a "$USER" -s nvidia-nim -w)" \
    command pi "$@"
}

opencode() {
  LOCAL_LLM_API_KEY="$LOCAL_LLM_API_KEY" command opencode "$@"
}

# AIChat via NVIDIA NIM (API key remains in macOS Keychain)
aichat() {
  local nvidia_api_key
  nvidia_api_key="$(security find-generic-password -a "$USER" -s nvidia-nim -w)" || {
    echo "Unable to read the NVIDIA API key from macOS Keychain." >&2
    return 1
  }
  NVIDIA_API_KEY="$nvidia_api_key" command aichat "$@"
}
alias ai='aichat'

[[ -r "$HOME/.config/aichat/integration.zsh" ]] && source "$HOME/.config/aichat/integration.zsh"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
eval "$(zoxide init zsh)"

# Center Markdown with native margins; never pipe the interactive screen.
# Use `command glow` for the unmodified CLI.
glow() {
  if [[ ! -t 1 ]]; then
    command glow "$@"
    return
  fi

  # ponytail: margins are set on launch; reopen Glow after resizing.
  local columns=${COLUMNS:-80}
  local padding=$(( columns > 100 ? (columns - 92 + 1) / 2 : columns > 8 ? 4 : 0 ))
  command glow --width "$columns" --style =(jq --argjson margin "$padding" \
    '.document.margin = $margin' "$HOME/.config/glow/dark.json") "$@"
}

# CloakBrowser — stealth Chromium with Decodo proxy
cloak() {
  local URL="${1:-about:blank}"
  local PROFILE="$HOME/.cloakbrowser/profile"
  mkdir -p "$PROFILE"
  local proxy_url="${DECODO_PROXY_URL:-}"
  if [[ -z "$proxy_url" ]]; then
    echo "Set DECODO_PROXY_URL in $HOME/dotfiles/.env."
    return 1
  fi

  open -a "Chromium" --args \
    --proxy-server="$proxy_url" \
    --fingerprint-platform=macos \
    --no-sandbox \
    --ignore-gpu-blocklist \
    --user-data-dir="$PROFILE" \
    "$URL"
}
setopt extended_glob
