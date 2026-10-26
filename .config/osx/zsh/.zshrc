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
    LLAMA_SERVER_MODEL LLAMA_SERVER_ALIAS LLAMA_SERVER_API_KEY_FILE \
    QWEN_IMAGE_MODEL QWEN_IMAGE_TEXT_ENCODER QWEN_IMAGE_VAE \
    MLX_WHISPER_SMALL_MODEL MLX_WHISPER_MEDIUM_MODEL MLX_WHISPER_LARGE_MODEL
fi

mlx-whisper() {
  MLX_WHISPER_SMALL_MODEL="$MLX_WHISPER_SMALL_MODEL" \
  MLX_WHISPER_MEDIUM_MODEL="$MLX_WHISPER_MEDIUM_MODEL" \
  MLX_WHISPER_LARGE_MODEL="$MLX_WHISPER_LARGE_MODEL" \
    python3 "$HOME/dotfiles/.config/osx/zsh/mlx_whisper.py" "$@"
}

qwen3.8-GGUF() {
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
    --ctx-size 0 \
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

qwen2.1-image() {
  local runtime="$HOME/.local/bin/sd-cli"
  if [[ ! -x "$runtime" ]]; then
    echo "Image runtime not found: $runtime"
    return 1
  fi
  if [[ "$#" -eq 0 ]]; then
    echo 'Usage: qwen2.1-image -p "your prompt" -o image.png [sd-cli options]'
    return 2
  fi
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    command "$runtime" --help
    return $?
  fi
  local file
  for file in "${QWEN_IMAGE_MODEL:-}" "${QWEN_IMAGE_TEXT_ENCODER:-}" "${QWEN_IMAGE_VAE:-}"; do
    if [[ ! -r "$file" ]]; then
      echo "Qwen Image model, text encoder, or VAE missing: $file"
      echo "Check QWEN_IMAGE_MODEL, QWEN_IMAGE_TEXT_ENCODER, and QWEN_IMAGE_VAE in $HOME/dotfiles/.env."
      return 1
    fi
  done

  # The INT8 text encoder requires CPU kernels unavailable in the Metal backend.
  command "$runtime" \
    --diffusion-model "$QWEN_IMAGE_MODEL" \
    --llm "$QWEN_IMAGE_TEXT_ENCODER" \
    --vae "$QWEN_IMAGE_VAE" \
    --cfg-scale 6.0 \
    --sampling-method euler \
    --offload-to-cpu \
    --backend te=cpu \
    "$@"
}

list() {
  if [[ "$#" -eq 1 && "$1" == "--models" ]]; then
    printf '%-20s %s\n' \
      "qwen2.1-image" "Qwen Image 2.1 — image generation" \
      "qwen3.8-GGUF" "Qwen 3.8 27B Q8_0 — llama.cpp on :8080" \
      "mlx-whisper-server" "MLX Whisper dictation — F5 while enabled"
    return 0
  fi

  echo "Usage: list --models"
  return 2
}

# Remove retired launchers when this file is sourced in an existing shell.
unfunction qwen-server qwenmlx-server qwen3.6-mlx prism-server \
  llm-server-local _mtplx_server_local _mlx_vlm_primary_local \
  _mlx_vlm_secondary_local _register_private_command 2>/dev/null || true

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
