# Gruvbox SketchyBar

Adapted from https://github.com/Aejkatappaja/dotfiles (SketchyBar Lua config, WTFPL).
Reference clone: `~/.cache/sketchybar-reference-aejkatappaja`.

- Left: native Apple menu logo, occupied spaces/app icons, then OpenAI logo + Codex quota percentage, Waller’s icon while running, and text-only CPU temperature immediately after the last visible tab. Empty spaces (including their borders/gaps) disappear and return when a window opens there. Workspace pills are display-only: clicking does nothing. No separate active-app name or Spaces/Mission Control indicator. All open-app icons, including Ghostty, remain visible inside their workspace pills.
- Right: CPU/GPU utilization, allocated/free RAM, battery percentage, stacked Wi-Fi upload/download speeds (no symbol or arrows), stock-style date/time.
- The Apple logo opens macOS's original Apple menu via its menu-bar owner, including About This Mac, System Settings, Sleep, Restart, and Shut Down. No replacement power-action menu is used.
- Volume, music, and notification widgets are not loaded. Apple, Codex, and temperature have no pill borders/backgrounds. CPU, GPU, RAM, and battery retain their rounded Gruvbox borders.
- Waller appears beside Codex only while its process is running (checked every 3 seconds and on app switches). Clicking opens its original Live Wallpaper menu without launching it if closed.
- Warm Gruvbox colors (cream/ochre/yellow/orange; no blue/pink): `colors.lua`. CPU/GPU/RAM use centered icons instead of text; GPU's naturally short glyph is scaled separately to balance the digits. Layout: `bar.lua`, `items/init.lua`, `items/widgets/init.lua`.
- Wi-Fi uses this Mac's `en0`; GPU uses Apple Silicon's `AGXAccelerator` counter.
- RAM: allocated GB above, available/free GB below. Allocation = (active + inactive + speculative + wired + physical compressor − purgeable − file-backed pages) × page size; available = installed − allocated. This excludes reclaimable file cache, rather than showing only raw zeroed pages as free.
- Wi-Fi: upload above, download below, sampled every 2 seconds in B/s, KB/s, or MB/s (1024-based). The first sample after a reset shows `--` until a rate can be measured.
- Codex shows only the lowest remaining percentage across available quota windows, refreshed every 120 seconds via CodexBar's OAuth CLI source. Failures show `--`, not a made-up zero.
- Temperature is the actual average of this M5 Pro's CPU super/performance-core SMC sensors, read via Stats' bundled `smc list -t` every 10 seconds. It is not the legacy battery/load-based estimate. Stats.app must remain installed; failures show `--`.
- Clicking Codex presses the running CodexBar application's actual status menu using Accessibility. It does not recreate the dropdown or launch CodexBar if closed.
- CPU/GPU/RAM clicks press the corresponding original Stats status widget, identified by its Accessibility help text, not its changing numeric label or menu index. Stats must be running with that module's menu-bar widget enabled.
- Battery icon and percentage follow the **active power source's energy mode**, not its charge level: Low Power yellow (`#fabd2f`), Automatic white (`#ffffff`), High Power green (`#b8bb26`). Mode is read from `pmset` every 5 seconds; no power settings are modified.

## Run / check

Requires SketchyBar, Lua 5.5, SF Pro, sketchybar-app-font, and SbarLua in `~/.local/share/sketchybar_lua/sketchybar.so` (installed on this Mac).

```sh
sketchybar --reload
cd ~/.config/sketchybar && lua tests/smoke.lua
```

SketchyBar starts at GUI login and automatically relaunches if it exits, via the per-user `local.sketchybar` LaunchAgent (no sudo/Homebrew tap trust change).
`~/Library/LaunchAgents/local.sketchybar.plist` links to `~/dotfiles/.config/osx/launchagents/local.sketchybar.plist`.
Runtime log: `~/.local/state/sketchybar/sketchybar.log`.

## Backup / native menu bar

Previous config: `~/.local/state/sketchybar/backups/20261016-034627/config`.
The `~/.config/sketchybar` symlink still points to `~/dotfiles/.config/osx/sketchybar`.

At the user's request the native menu bar is set to auto-hide (Always):
`NSGlobalDomain._HIHideMenuBar=true`, `AppleMenuBarVisibleInFullscreen=false`,
`com.apple.controlcenter.AutoHideMenuBarOption=0`.
Previously these were `false`, `true`, and `3` (Never), respectively.
A distributed `AppleInterfaceMenuBarHidingChangedNotification` applies the setting live.

The Hammerspoon top-edge guard is disabled and is not loaded at startup, at the user’s request. Native menu-bar access is allowed. The unused guard module/test remain available for reference.
Hammerspoon init backup: `~/.hammerspoon/init.lua.before-menubar-guard-20261016`.
