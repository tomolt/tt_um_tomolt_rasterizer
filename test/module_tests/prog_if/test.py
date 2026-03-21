# SPDX-FileCopyrightText: © 2026 Thomas Oltmann
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

async def send_word(dut, word):
    dut._log.info(f"Sending word {word}")

    for i in range(0, 8):
        dut.sck.value = 0
        dut.mosi.value = (word & 0x80) >> 7
        word = (word << 1) & 0xFF
        await ClockCycles(dut.clk, 2)
        dut.sck.value = 1
        await ClockCycles(dut.clk, 2)

@cocotb.test()
async def test_prog_if(dut):
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 1)
    dut.rst_n.value = 1

    dut.cs_n.value = 0
    dut.sck.value = 0
    await ClockCycles(dut.clk, 1)

    dut._log.info("Send one full set of words")

    word = 53
    await send_word(dut, word)
    assert dut.v1x.value == word << 3

    word = 1
    await send_word(dut, word)
    assert dut.v1y.value == word << 3

    word = 63
    await send_word(dut, word)
    assert dut.v2x.value == word << 3

    word = 0
    await send_word(dut, word)
    assert dut.v2y.value == word << 3

    word = 11
    await send_word(dut, word)
    assert dut.v3x.value == word << 3

    word = 62
    await send_word(dut, word)
    assert dut.v3y.value == word << 3

    word = 0b110011
    await send_word(dut, word)
    assert dut.fcolor.value == word

    word = 0b001100
    await send_word(dut, word)
    assert dut.bcolor.value == word

    dut._log.info("Make sure we automatically start from the front again")

    word = 29
    await send_word(dut, word)
    assert dut.v1x.value == word << 3

    dut._log.info("Make sure we can reset the position by taking ~CS high, then low again")

    dut.cs_n.value = 1
    dut.sck.value = 0 # shouldn't matter
    await ClockCycles(dut.clk, 1)

    dut.cs_n.value = 0
    await ClockCycles(dut.clk, 1)

    word = 4
    await send_word(dut, word)
    assert dut.v1x.value == word << 3
    
