#!/usr/bin/env sh
set -eu

moon build src/examples/moonview_linux --target native
exec ./_build/native/debug/build/examples/moonview_linux/moonview_linux.exe
