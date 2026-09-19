#!/bin/bash
# Alt+E opens the current Finder folder, or the last folder saved by yabai.
set -eu
state="$HOME/Library/Caches/skhd-finder-last-folder"

case "${1:-open}" in
remember)
    case "${YABAI_WINDOW_ID:-}" in ''|*[!0-9]*) exit 0 ;; esac
    folder=$(/usr/bin/osascript - "$YABAI_WINDOW_ID" <<'APPLESCRIPT'
on run argv
    if application "Finder" is not running then return ""
    tell application "Finder"
        try
            set sourceWindow to Finder window id (item 1 of argv as integer)
            if index of sourceWindow is not 1 then return ""
            return POSIX path of (target of sourceWindow as alias)
        on error
            return ""
        end try
    end tell
end run
APPLESCRIPT
    )
    # Virtual views (Computer, Recents, searches) must not erase a real folder.
    [ -n "$folder" ] && [ -d "$folder" ] || exit 0
    tmp=$(mktemp "$state.XXXXXX")
    trap 'rm -f "$tmp"' EXIT
    printf '%s' "$folder" > "$tmp"
    mv -f "$tmp" "$state"
    ;;
open)
    /usr/bin/osascript - "$state" <<'APPLESCRIPT'
on run argv
    set previousFolder to missing value
    tell application "Finder"
        try
            set previousFolder to target of front Finder window as alias
        end try
    end tell
    if previousFolder is missing value then
        try
            set savedPath to read (POSIX file (item 1 of argv)) as «class utf8»
            set previousFolder to (POSIX file savedPath) as alias
        end try
    end if
    tell application "Finder"
        if previousFolder is missing value then
            set newWindow to make new Finder window
        else
            set newWindow to make new Finder window to previousFolder
        end if
        activate
        return id of newWindow
    end tell
end run
APPLESCRIPT
    ;;
*) printf 'Usage: %s [open|remember]\n' "$0" >&2; exit 2 ;;
esac
