#!/bin/sh
echo -ne '\033c\033]0;Soccer\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/soccer_train.x86_64" "$@"
