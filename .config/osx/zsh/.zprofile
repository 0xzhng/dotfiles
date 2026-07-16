eval "$(/opt/homebrew/bin/brew shellenv)"

if command -v oh-my-posh >/dev/null 2>&1; then
  eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/ghostty-diamond.omp.json)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"
