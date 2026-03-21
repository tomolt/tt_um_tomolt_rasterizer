/* 
 * Copyright (c) 2026 Thomas Oltmann
 * SPDX-License-Identifier: Apache-2.0
 * vim: sts=2 ts=2 sw=2 et
 */

`default_nettype none

module tt_um_tomolt_rasterizer (
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
  wire display_on;
  wire [9:0] hpos;
  wire [9:0] vpos;

  hvsync_generator hvsync_gen(
    .clk(clk),
    .rst_n(rst_n),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(display_on),
    .hpos(hpos),
    .vpos(vpos)
  );

  wire cs_n = uio_in[0];
  wire mosi = uio_in[1];
  wire sck  = uio_in[3];
  wire [9:0] v1x;
  wire [9:0] v1y;
  wire [9:0] v2x;
  wire [9:0] v2y;
  wire [9:0] v3x;
  wire [9:0] v3y;
  wire [5:0] fcolor;
  wire [5:0] bcolor;

  prog_if pif(
    .clk(clk),
    .rst_n(rst_n),
    .cs_n(cs_n),
    .mosi(mosi),
    .sck(sck),
    .v1x(v1x),
    .v1y(v1y),
    .v2x(v2x),
    .v2y(v2y),
    .v3x(v3x),
    .v3y(v3y),
    .fcolor(fcolor),
    .bcolor(bcolor)
  );

  localparam BLACKBAR = 64;

  wire fill;

  triscan #(.XOFFSET(BLACKBAR)) tscan(
    .clk(clk),
    .rst_n(rst_n),
    .hpos(hpos),
    .vpos(vpos),
    .v1x(v1x),
    .v1y(v1y),
    .v2x(v2x),
    .v2y(v2y),
    .v3x(v3x),
    .v3y(v3y),
    .fill(fill)
  );

  wire [5:0] pixel = (display_on && hpos >= BLACKBAR && hpos < 640 - BLACKBAR) ?
    (fill ? fcolor : bcolor) : 6'b000000;

  // TinyVGA PMOD
  assign uo_out[0] = pixel[1];
  assign uo_out[1] = pixel[3];
  assign uo_out[2] = pixel[5];
  assign uo_out[3] = vsync;
  assign uo_out[4] = pixel[0];
  assign uo_out[5] = pixel[2];
  assign uo_out[6] = pixel[4];
  assign uo_out[7] = hsync;

  // Serial Pins
  assign uio_oe[3:0] = 0;

  // Event Indicator Pins
  assign uio_oe[4] = 1;
  assign uio_oe[5] = 1;
  assign uio_out[4] = vsync;
  assign uio_out[5] = hsync;

  // Suppress unused signals warning
  wire _unused_ok = &{ena, ui_in, uio_in};
  // Configure unused UIO pins as inputs.
  assign uio_oe[7:6] = 0;
  // Unused outputs assigned to 0.
  assign uio_out[3:0] = 0;
  assign uio_out[7:6] = 0;

endmodule

