# SPDX-FileCopyrightText: © 2026 Thomas Oltmann
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

import os
from PIL import Image, ImageChops

async def do_start(dut):
    dut._log.info("Start")

    # 25.175MHz clock
    clock = Clock(dut.clk, 39.722, unit="ns")
    cocotb.start_soon(clock.start())

    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)

    # Reset
    dut._log.info("Reset")
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 2)

    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 1)

    assert dut.uio_oe.value == 0b00110000

H_DISPLAY = 640
H_BACK    = 48
H_FRONT   = 16
H_SYNC    = 96

V_DISPLAY = 480
V_TOP     = 33
V_BOTTOM  = 10
V_SYNC    = 2

# Based on code from Michael Bell
# See: https://github.com/MichaelBell/tt08-canon/blob/main/test/test.py
async def frame_dump(dut, name):
    await do_start(dut)
    await ClockCycles(dut.clk, 1)

    dut._log.info(f"Generating image {name}")

    out_filename = f"generated_images/{name}"
    os.makedirs(os.path.dirname(out_filename), exist_ok=True)
    image = Image.new("RGB", (H_DISPLAY, V_DISPLAY))

    for i in range(V_DISPLAY + V_BOTTOM + V_SYNC + V_TOP):
        vsync = (i >= V_DISPLAY + V_BOTTOM) and (i < V_DISPLAY + V_BOTTOM + V_SYNC)
        # Display Area
        for j in range(H_DISPLAY):
            assert dut.vsync.value == vsync
            assert dut.hsync.value == 0
            if i < V_DISPLAY:
                rgb   = dut.rgb.value.to_unsigned()
                red   = 85 * ((rgb >> 0) & 3)
                green = 85 * ((rgb >> 2) & 3)
                blue  = 85 * ((rgb >> 4) & 3)
                image.putpixel((j, i), (red, green, blue))
            await ClockCycles(dut.clk, 1)
        # Horizontal front porch
        for j in range(H_FRONT):
            assert dut.vsync.value == vsync
            assert dut.hsync.value == 0
            assert dut.rgb.value == 0
            await ClockCycles(dut.clk, 1)
        # Horizontal sync pulse
        for j in range(H_SYNC):
            assert dut.vsync.value == vsync
            assert dut.hsync.value == 1
            assert dut.rgb.value == 0
            await ClockCycles(dut.clk, 1)
        # Horizontal back porch
        for j in range(H_BACK):
            assert dut.vsync.value == vsync
            assert dut.hsync.value == 0
            assert dut.rgb.value == 0
            await ClockCycles(dut.clk, 1)
    
    image.save(out_filename)

    in_filename = f"expected_images/{name}"
    if not os.path.isfile(in_filename):
        dut._log.info(f"No expected output for image {out_filename} to compare to")
        return

    dut._log.info(f"Comparing {out_filename} to {in_filename}")

    expected = Image.open(in_filename)
    assert ImageChops.difference(expected, image).getbbox() == None

@cocotb.test()
async def test_vga_output(dut):
    await frame_dump(dut, "generated_images/frame_0.png")
