# SPDX-FileCopyrightText: © 2026 Thomas Oltmann
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

WIDTH = 10

async def check_division(dut, num, den):
    dut._log.info(f"Divide {num} by {den}")

    dut.num.value = num
    dut.den.value = den

    dut.load.value = 1
    await ClockCycles(dut.clk, 1)
    dut.load.value = 0
    await ClockCycles(dut.clk, 3*WIDTH)
    quo = dut.quo.value
    rem = dut.rem.value

    (actual_quo, actual_rem) = divmod(num, den)
    mask = (1 << WIDTH) - 1

    assert (quo, rem) == (actual_quo & mask, actual_rem & mask)

@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    await check_division(dut, 0, 1)
    await check_division(dut, 1, 1)
    await check_division(dut, 3, 2)
    await check_division(dut, 100, 10)
    await check_division(dut, 100, (1 << 10) - 1)
    await check_division(dut, 991, 1)
    await check_division(dut, 991, 2)
    await check_division(dut, 991, 991)
    await check_division(dut, 991, 990)
    await check_division(dut, (1 << 10) - 1, (1 << 10) - 1)
    await check_division(dut, 568 * 319, 237)
    await check_division(dut, 568 * 319, 1)
    await check_division(dut, 568 * 319, (1 << 10) - 1)
    await check_division(dut, (1 << 10) - 1, (1 << 10) - 1)
    await check_division(dut, (1 << 20) - 1, (1 << 10) - 1)
    await check_division(dut, (1 << 20) - 1, 1)
    await check_division(dut, 0, (1 << 10) - 1)
