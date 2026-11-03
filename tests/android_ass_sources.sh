#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
flags=(-O1 -g -Isrc -ffunction-sections -fdata-sections)
case "$(uname -s)" in Darwin) flags+=(-Wl,-dead_strip);; *) flags+=(-Wl,--gc-sections);; esac
if [ "${SANITIZE:-0}" = 1 ]; then flags+=(-fsanitize=address,undefined -fno-omit-frame-pointer); fi
cc "${flags[@]}" tests/android_ass_sources.c src/stream_parse.c src/faixasmkv.c src/fontefiltro.c \
  src/linguas.c src/js.c src/badges.c -o "$work/test"
"$work/test"
