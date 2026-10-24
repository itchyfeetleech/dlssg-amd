#!/usr/bin/env bash
# Builds vkd3d-proton 22307558 with patches/ applied into OUT_DIR:
#   0001  d4r's vkd3d-proton patches 0001-0003 (countervolts/d4r) ported to this base, so d4r (DLSS SR/RR) works with the
#         same d3d12.dll; a game folder can hold only one
#   0002  cubin launches end the render pass first and re-emit vkd3d's state after (DLSS-G needs it)
# Base 22307558 (vkd3d-proton master 2026-10-06) rather than d4r's 3dfc6f07: the older base crashes creating ray
# tracing pipelines in The Witcher 3.
# usage: build.sh OUT_DIR
# Env: VKD3D_PROTON_SRC (clone, default ~/.cache/dlssg-amd-vkd3d-proton), VKD3D_PROTON_COMMIT (default 22307558)
set -euo pipefail
if [[ $# -ne 1 ]]; then
  printf 'usage: %s OUT_DIR\n' "$0" >&2
  exit 2
fi
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="$(realpath -m "$1")"
SRC="${VKD3D_PROTON_SRC:-$HOME/.cache/dlssg-amd-vkd3d-proton}"
COMMIT="${VKD3D_PROTON_COMMIT:-22307558}"
BUILD="$SRC-build"
[[ -d "$SRC/.git" ]] || git clone https://github.com/HansKristian-Work/vkd3d-proton.git "$SRC"
# -f: the clone is a build cache; the patches are reapplied below
git -C "$SRC" checkout -q -f -B dlssg-amd "$COMMIT"
git -C "$SRC" submodule update --init --recursive -q
git -C "$SRC" apply "$HERE"/patches/0*.patch
[[ -d "$BUILD" ]] || meson setup --cross-file "$SRC/build-win64.txt" --buildtype release -Denable_tests=false "$BUILD" "$SRC"
ninja -C "$BUILD"
mkdir -p "$OUT"
x86_64-w64-mingw32-strip -o "$OUT/d3d12.dll" "$BUILD/libs/d3d12/d3d12.dll"
x86_64-w64-mingw32-strip -o "$OUT/d3d12core.dll" "$BUILD/libs/d3d12core/d3d12core.dll"
printf 'Built %s/d3d12.dll and d3d12core.dll\n' "$OUT"
