#!/usr/bin/env sh
set -eu

moon build src/examples/linux_smoke --target native
exec ./_build/native/debug/build/examples/linux_smoke/linux_smoke.exe
