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

mlx-whisper() {
  python3 "$HOME/dotfiles/.config/osx/zsh/mlx_whisper.py" "$@"
}

llm-server-local() {
  local model="${LLAMA_SERVER_MODEL:-}"
  local model_alias="${LLAMA_SERVER_ALIAS:-qwen3.8-27b-heretic-q4_k_m}"
  local api_key_file="${LLAMA_SERVER_API_KEY_FILE:-$HOME/.config/llama.cpp/api-key}"
  if [[ -z "$model" ]]; then
    echo "Set LLAMA_SERVER_MODEL in $HOME/dotfiles/.env."
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

prism-server() {
  local model="prism-ml/Ternary-Bonsai-27B-mlx-2bit"
  local model_cache="$HOME/.cache/huggingface/hub/models--prism-ml--Ternary-Bonsai-27B-mlx-2bit"
  local server="$HOME/.local/bin/mlx_vlm.server"

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

list() {
  if [[ "$#" -eq 1 && "$1" == "--models" ]]; then
    printf '%-16s %s\n' \
      "${LLAMA_SERVER_COMMAND:-qwen-server}" "Qwen 3.8 27B Heretic Q4_K_M — llama.cpp on :8080" \
      "prism-server" "Ternary Bonsai 27B MLX 2-bit — MLX-VLM on :8089" \
      "mlx-whisper-server" "Large-v3 Turbo 4-bit dictation — F5 while enabled"
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
    ""|[!A-Za-z_]*|*[!A-Za-z0-9_-]*) return ;;
  esac
  eval "${name}() { ${target} \"\$@\"; }"
}
_register_private_command "${LLAMA_SERVER_COMMAND:-}" llm-server-local

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
