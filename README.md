![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg) ![](../../workflows/fpga/badge.svg)

# Thomas Oltmann's Tiny Triangle Rasterizer

This is a crude ASIC triangle rasterizer that generates VGA signals.
This project imitates a basic fixed-function graphics processor:
It receives geometry from an external device and rasterizes it into an image signal that can be viewed on a computer monitor.
Except whereas even the oldest 3D graphics processors were capable of processing hundreds or thousands of triangles per frame, this humble project only manages one measly triangle per frame [^1].

If you want to try this tile on the TinyTapeout demo-board, you will need to purchase the TinyVGA PMOD adapter (sold in the TinyTapeout shop) or a similar adapter with the same pinout.

Since this is a novice project, developed under severe time constraints, broken functionality and deviations from the documented behaviour should be expected.

[^1]: More than one triangle per frame is possible if the geometry is swapped-out mid-frame,
but only if these triangles are separated vertically.

## Testing / Simulating

The project-wide cocotb test suite is stubbed out and not actually used.
Some submodules are tested separately with cocotb.
These tests can be found under `tests/module_tests`.
Every test has its own directory; Simply navigate there and run `make`.

The whole project can also be uploaded to the Verilog VGA playground hosted at [8bitworkshop.com](https://8bitworkshop.com).
In the playground, the module `playground_adapter` must be selected as your main module.
This module is not present on the ASIC.
