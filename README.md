# A collection of my dotfiles

- Managed using [GNU stow](https://github.com/aspiers/stow/) ~ i highly recommend it for symlinking a collection of dotfiles.
- arch w/ hyprland and osx w/ yabai and SKHD

## Configuration layout

- `.config/arch/` contains Linux desktop configuration, including Hyprland and the Arch Ghostty configuration.
- `.config/shared/` contains shared tools such as tmux, Neovim, Git, and Oh My Posh.
- `.config/osx/` contains macOS configuration. The existing shared Ghostty configuration remains available for macOS.
- On this Arch machine, `~/.config/<app>` links to the corresponding `arch/<app>` or `shared/<app>` directory. `~/.tmux.conf` links to `~/.config/tmux/tmux.conf`.
- Git identity and machine-specific credential helpers are loaded from `~/.gitconfig.local`, outside this repository.
- Tmux plugins, the PulseAudio cookie, and generated lock-screen images remain machine-local ignored files.
