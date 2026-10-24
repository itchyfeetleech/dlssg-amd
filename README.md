# dlssg-amd

NVIDIA DLSS Frame Generation (`nvngx_dlssg.dll`, 2x/3x/4x) on RDNA4 Radeon GPUs under Proton. The game's own DLSS-G
DLL runs unmodified; its CUDA kernels are translated to SPIR-V and run through a Vulkan layer that provides
`VK_NVX_binary_import` on RADV.

```
game - Streamline - OptiScaler 0.9.4 (NvngxPath) - NGX host - nvngx_dlssg.dll
                                                            - next NGX core (d4r) or none
nvngx_dlssg.dll - vkd3d-proton (cubin launches) - nvxrt layer - RADV
```

- `host/`: NGX core for feature 11 (frame generation). Reports Blackwell to DLSS-G so multi-frame generation and the
  PTX kernels are used, and forwards everything else to the next core.
- `nvxrt/`: Vulkan layer implementing `VK_NVX_binary_import` and `VK_NVX_image_view_handle`.
- `translator/`: PTX to SPIR-V, run once per DLL on your machine into `~/.cache/nvxrt`.
- `t1/`: hand-written RDNA4 kernels for the network layers, bit-identical to the translated ones.
- `vkd3d-proton/`: vkd3d-proton 22307558 with d4r's patches 0001-0003 and a fix for cubin launches (end the render
  pass first, re-emit state after). One `d3d12.dll` serves both d4r and DLSS-G.

No NVIDIA code or data is in this repository.

## Requirements

- RDNA4 GPU (RX 9070 XT/9070/9070 GRE, RX 9060 XT/9060, Radeon AI PRO R9700)
- Mesa 26.2.5 or newer (26.2.2 miscompiles the convolution kernels)
- GE-Proton 11
- A D3D12 game using Streamline with DLSS-G 310.x, and OptiScaler 0.9.4 in its folder (included in d4r releases;
  d4r keeps DLSS SR/RR working alongside)
- To build: g++, make, mingw-w64, meson, ninja, glslang, python3

## Build

```sh
./build.sh
```

## Install

```sh
tools/dlssg-install "<folder with the game exe>"
```

Then set the game's launch options to `/path/to/dlssg-amd/tools/dlssg-run %command%` and enable DLSS Frame
Generation in the game.

`--status` shows the setup, `--uninstall` restores everything that was replaced. Options:

- `--exact`: bit-exact kernels. The default uses hardware texture filtering, fp32 accumulation and RGBA8 storage for
  two intermediate images (about 10% less GPU time, PSNR ~55 dB against exact).
- `--lite`: FG Lite (DLSS-G 310.9.16+), much cheaper generated frames.
- `--dll PATH`: use another DLSS-G DLL, e.g. a 310.x DLL for a game that ships 3.x. DLSS-G 3.x is not supported: most
  of its PTX is encrypted.

`DLSSG_OFF=1` starts the game without the wrapper's changes.

## Notes

- `dlssg-install` enables OptiScaler's `SpoofHAGS` and `dlssg-run` sets `HwSchMode=2` in the Proton prefix
  (`DLSSG_HAGS=0` to skip). Some games only offer DLSS-G with hardware GPU scheduling, which Wine reports as off.
- Some games disable DLSS-G under Wine. The Witcher 3 needs an exe patch, which is not included.
- In The Witcher 3 with DLSS-G on, Streamline creates Ray Reconstruction before the game's first camera constants, so
  the parameters have no `WorldToViewMatrix`/`ViewToClipMatrix` yet. d4r then keeps Ray Reconstruction on its CUDA
  backend for the whole session (about 10 ms more per frame). The host puts identity placeholders in the parameters at
  creation; the game's own matrices replace them once it sets them. `RrCreateMatrices=0` in `dlssg_host.ini` turns this
  off.
- Don't use this in online games with anti-cheat.

The Witcher 3, RX 9070, 2560x1440, RT on:

| | real fps | shown fps | DLSS-G ms per real frame |
|---|---|---|---|
| off | 108.8 | 108.8 | |
| 2x | 84.5 | 169.0 | 2.16 |
| 4x | 70.8 | 283.3 | 4.69 |
| 4x Lite | 84.7 | 339.2 | 2.01 |

`harness/run.sh` runs a DLSS-G DLL on a synthetic scene without a game (`VKD3D_DIR=vkd3d-proton/out harness/run.sh
nvngx_dlssg.dll outdir --mfc 3`).

## License

GPL-3.0-only. The vkd3d-proton patches are LGPL-2.1, like vkd3d-proton. The translated kernel cache is derived from
NVIDIA's DLL and must not be redistributed. See NOTICE.
