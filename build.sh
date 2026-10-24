#!/usr/bin/env bash
# Builds everything: the nvxrt layer and scanner (nvxrt/build), the NGX host (host/build), the harness, and the patched
# vkd3d-proton (vkd3d-proton/out; skip with --no-vkd3d).
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"
make -C nvxrt
host/build.sh
harness/build.sh
[[ "${1:-}" == --no-vkd3d ]] || vkd3d-proton/build.sh vkd3d-proton/out
echo "built; next: tools/dlssg-install <game folder> (see README.md)"
