# SPDX-FileCopyrightText: © 2026 Thomas Oltmann
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

WIDTH = 10
MASK  = (1 << WIDTH) - 1
MASK2 = (1 << 2*WIDTH) - 1

async def check_muldiv(dut, mu1, mu2, den):
    mu1 &= MASK
    mu2 &= MASK
    den &= MASK

    dut._log.info(f"Multiply {mu1} by {mu2} then divide by {den}")

    dut.mu1.value = mu1
    dut.mu2.value = mu2
    dut.den.value = den

    dut.load.value = 1
    await ClockCycles(dut.clk, 1)
    dut.load.value = 0
    await ClockCycles(dut.clk, 4*WIDTH)
    quo = dut.quo.value
    rem = dut.rem.value

    (actual_quo, actual_rem) = divmod(mu1 * mu2, den)

    assert (quo, rem) == (actual_quo & MASK, actual_rem & MASK)

@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    await check_muldiv(dut, 0, 0, 1)
    await check_muldiv(dut, 0, 1, 1)
    await check_muldiv(dut, 1, 3, 2)
    await check_muldiv(dut, 10, 10, 10)
    await check_muldiv(dut, 10, 10, MASK)
    await check_muldiv(dut, 81, 9, 1)
    await check_muldiv(dut, 81, 9, 2)
    await check_muldiv(dut, 81, 9, 81 * 9)
    await check_muldiv(dut, 1, 991, 990)
    await check_muldiv(dut, 1, MASK, MASK)
    await check_muldiv(dut, 0, 0, MASK)
    await check_muldiv(dut, MASK, MASK, MASK)
    await check_muldiv(dut, 568, 319, 237)
    await check_muldiv(dut, 568, 319, 1)
    await check_muldiv(dut, 568, 319, MASK)
