#!/usr/bin/env sh

set_mode() {
  mode="$1"
  case "$mode" in
    low)
      pm_powermode=1
      ;;
    auto)
      pm_powermode=0
      ;;
    high)
      pm_powermode=2
      ;;
    *)
      exit 0
      ;;
  esac

  if ! sudo -n /usr/bin/pmset -a powermode "$pm_powermode" >/dev/null 2>&1; then
    return 1
  fi
  return 0
}

setup_sudoers() {
  user_name=$(id -un)
  cmd="echo '${user_name} ALL=(root) NOPASSWD: /usr/bin/pmset -a powermode 0, /usr/bin/pmset -a powermode 1, /usr/bin/pmset -a powermode 2' | sudo tee /private/etc/sudoers.d/sketchybar-pmset >/dev/null && sudo chmod 440 /private/etc/sudoers.d/sketchybar-pmset && echo 'Done. You can close this window.'"
  osascript -e "tell application \"Terminal\" to do script \"$cmd\"" >/dev/null 2>&1
  osascript -e 'tell application "Terminal" to activate' >/dev/null 2>&1
}

update_status() {
  PRIMARY_COLOR="${PRIMARY:-0xffb0c6ff}"
  TEXT_COLOR="${ON_BACKGROUND:-0xffe2e2e9}"

  if pmset -g batt | grep -q 'AC Power'; then
    section='AC Power:'
  else
    section='Battery Power:'
  fi

  current=$(pmset -g custom 2>/dev/null | awk -v s="$section" '
    $0 ~ s {in_section=1; next}
    /^[A-Za-z].*Power:/ && $0 !~ s {in_section=0}
    in_section && /powermode/ {print $2; exit}
  ')
  [ -z "$current" ] && current=$(pmset -g custom 2>/dev/null | awk '/powermode/ {print $2; exit}')

  low_label="Low Power"
  auto_label="Automatic"
  high_label="High Power"
  low_color="$TEXT_COLOR"
  auto_color="$TEXT_COLOR"
  high_color="$TEXT_COLOR"

  case "$current" in
    0) auto_label="● Automatic"; auto_color="$PRIMARY_COLOR" ;;
    1) low_label="● Low Power"; low_color="$PRIMARY_COLOR" ;;
    2) high_label="● High Power"; high_color="$PRIMARY_COLOR" ;;
  esac

  sketchybar --set battery.mode.low label="$low_label" label.color="$low_color"
  sketchybar --set battery.mode.auto label="$auto_label" label.color="$auto_color"
  sketchybar --set battery.mode.high label="$high_label" label.color="$high_color"
  sketchybar --set battery.mode.hint label="" label.drawing=off
}

case "$1" in
  set)
    if set_mode "$2"; then
      sleep 0.3
      update_status
      NAME=battery "$HOME/.config/sketchybar/plugins/battery.sh" >/dev/null 2>&1
    else
      sketchybar --set battery.mode.low label="Low Power"
      sketchybar --set battery.mode.auto label="Automatic"
      sketchybar --set battery.mode.high label="High Power"
      sketchybar --set battery.mode.hint label="Click Enable Mode Control" label.drawing=on
    fi
    ;;
  setup)
    setup_sudoers
    sketchybar --set battery.mode.hint label="Complete setup in Terminal, then click battery again" label.drawing=on
    ;;
  status|*)
    update_status
    ;;
esac
