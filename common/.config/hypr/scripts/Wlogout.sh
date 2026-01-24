#!/usr/bin/env bash

# Toggle the wlogout layer when pressing the bound key again.
if pgrep -x wlogout >/dev/null; then
    pkill -x wlogout
else
    # nohup keeps wlogout alive after this helper exits.
    nohup wlogout >/dev/null 2>&1 &
fi
