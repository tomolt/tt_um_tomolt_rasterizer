/* 
 * Copyright (c) 2026 Thomas Oltmann
 * SPDX-License-Identifier: Apache-2.0
 * vim: sts=2 ts=2 sw=2 et
 */

`default_nettype none

module tt_um_tomolt_rasterizer(
  input  wire [7:0] ui_in,    // Dedicated inputs
  output wire [7:0] uo_out,   // Dedicated outputs
  input  wire [7:0] uio_in,   // IOs: Input path
  output wire [7:0] uio_out,  // IOs: Output path
  output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
  input  wire       ena,      // always 1 when the design is powered, so you can ignore it
  input  wire       clk,      // clock
  input  wire       rst_n     // reset_n - low to reset
);

  wire hsync;
  wire vsync;
  wire reset;
  wire [2:0] rgb;

  assign reset = !rst_n;

  // TinyVGA PMOD
  assign uo_out = {hsync, rgb[2], rgb[1], rgb[0], vsync, rgb[2], rgb[1], rgb[0]};

  // Unused outputs assigned to 0.
  assign uio_out = 0;
  assign uio_oe  = 0;

  // Suppress unused signals warning
  wire _unused_ok = &{ena, ui_in, uio_in};

  rasterizer raster(
    .clk(clk),
    .reset(reset),
    .hsync(hsync),
    .vsync(vsync),
    .rgb(rgb)
  );
endmodule
