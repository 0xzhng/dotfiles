#!/bin/zsh
grim -g "$(slurp -b 00000080 -s 00000000 -c 00000000 -w 0)" - | wl-copy
