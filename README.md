![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg) ![](../../workflows/fpga/badge.svg)

# Thomas Oltmann's Tiny Triangle Rasterizer

This is a crude ASIC triangle rasterizer that generates VGA signals.
It imitates the functionality of a basic fixed-function graphics processor:
It receives geometry from an external device and rasterizes it into an image signal that can be viewed on a computer monitor.
Except whereas even the oldest 3D graphics processors were capable of processing hundreds or thousands of triangles per frame,
this humble project only manages one measly triangle per frame.

If you want to try this tile on the TinyTapeout demo-board,
you will need to purchase the TinyVGA PMOD adapter (sold in the TinyTapeout shop) or a similar adapter with the same pinout.

Since this is a novice project, developed under severe time constraints, broken functionality and deviations from the documented behaviour should be expected.

## Testing / Simulating

cocotb is used to compare the simulated output of the design with a known-good image.
In addition, some submodules are tested separately with cocotb.

The whole project can be uploaded to the Verilog VGA playground hosted at [8bitworkshop.com](https://8bitworkshop.com).
In the playground, the module `playground_adapter` must be selected as your main module.
This module is not present on the ASIC.

The design has not been tested on an FPGA because of time constraints.
