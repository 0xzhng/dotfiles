# A collection of my dotfiles

- Managed using [GNU stow](https://github.com/aspiers/stow/) ~ i highly recommend it for symlinking a collection of dotfiles.
- arch w/ hyprland and osx w/ yabai and SKHD

## Configuration layout

- `.config/arch/` contains Linux desktop configuration, including Hyprland and the Arch Ghostty configuration.
- `.config/shared/` contains shared tools such as tmux, Neovim, Git, and Oh My Posh.
- `.config/osx/` contains macOS configuration.

## Pi links and Gondolin

```sh
git submodule update --init --recursive
npm install --prefix "$HOME/dotfiles/.config/shared/pi/agent/pi-gondolin"
mkdir -p "$HOME/.pi/agent"
# Only create these links when the destinations do not already exist.
ln -s ../../dotfiles/.config/shared/pi/agent/SYSTEM.md "$HOME/.pi/agent/SYSTEM.md"
ln -s ../../dotfiles/.config/shared/pi/agent/pi-gondolin "$HOME/.pi/agent/pi-gondolin"
```

Gondolin is opt-in: run `pi -e ~/.pi/agent/pi-gondolin/index.ts` from a project directory. Requires QEMU (`brew install qemu` on macOS). The launch directory is mounted writable; MCP and other host tools are not sandboxed by this extension.
