# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

WIDTH = 10

async def check_multiplication(dut, n1, n2):
    dut._log.info(f"Multiply {n1} with {n2}")

    dut.n1.value = n1
    dut.n2.value = n2

    dut.load.value = 1
    await ClockCycles(dut.clk, 1)
    dut.load.value = 0
    await ClockCycles(dut.clk, 2*WIDTH)
    product = dut.product.value

    assert product == ((n1 * n2) & ((1 << 2*WIDTH) - 1))

@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    await check_multiplication(dut, 0, 1)
    await check_multiplication(dut, 1, 1)
    await check_multiplication(dut, 3, 2)
    await check_multiplication(dut, 100, 10)
    await check_multiplication(dut, 100, (1 << 10) - 1)
    await check_multiplication(dut, 991, 1)
    await check_multiplication(dut, 991, 2)
    await check_multiplication(dut, 991, 991)
    await check_multiplication(dut, 991, 990)
    await check_multiplication(dut, (1 << 10) - 1, (1 << 10) - 1)
