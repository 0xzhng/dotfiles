#!/bin/bash
# Integration check: requires Finder windows to be closed; only closes test windows.
set -eu
apple() { /usr/bin/osascript -e "tell application \"Finder\" to $1"; }
[ "$(apple 'count Finder windows')" = 0 ] || { echo 'Close Finder windows before running this test.' >&2; exit 1; }
state="$HOME/Library/Caches/skhd-finder-last-folder"
backup=$(mktemp -d)
[ ! -f "$state" ] || cp "$state" "$backup/folder"
ids=""
cleanup() {
    for id in $ids; do apple "close Finder window id $id" >/dev/null 2>&1 || true; done
    sleep 1
    if [ -f "$backup/folder" ]; then cp "$backup/folder" "$state"; else rm -f "$state"; fi
    rm -rf "$backup"
}
trap cleanup EXIT

id=$(apple 'id of (make new Finder window to (path to home folder))')
ids="$id"
apple "set target of Finder window id $id to (path to downloads folder)" >/dev/null
apple 'activate' >/dev/null
expected=$(apple "POSIX path of (target of Finder window id $id as alias)")
for ((i=0; i<30; i++)); do
    [ ! -f "$state" ] || [ "$(<"$state")" != "$expected" ] || break
    sleep 0.1
done
[ -f "$state" ] && [ "$(<"$state")" = "$expected" ]
apple "close Finder window id $id" >/dev/null
[ "$(apple 'count Finder windows')" = 0 ]

for expected_count in 1 2; do
    /opt/homebrew/bin/skhd -k 'alt - e'
    sleep 1
    [ "$(apple 'count Finder windows')" = "$expected_count" ]
    id=$(apple 'id of front Finder window')
    ids="$ids $id"
    [ "$(apple "POSIX path of (target of Finder window id $id as alias)")" = "$expected" ]
done
echo 'PASS: navigation remembered; Alt+E restored the folder after closing all windows; second press opened another matching window.'
