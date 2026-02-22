/*
 * Copyright (c) 2026 Thomas Oltmann
 * SPDX-License-Identifier: Apache-2.0
 * vim: sts=2 ts=2 sw=2 et
 */

`include "hvsync_generator.v"
`include "triscan.v"

module rasterizer(clk, reset, hsync, vsync, rgb);
  input clk, reset;
  output hsync, vsync;
  output reg [2:0] rgb;
  wire display_on;

  wire [9:0] hpos;
  wire [9:0] vpos;

  hvsync_generator hvsync_gen(
    .clk(clk),
    .reset(reset),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(display_on),
    .hpos(hpos),
    .vpos(vpos)
  );

  wire [59:0] geometry_1 = {
    10'd100, 10'd1,
    10'd1, 10'd100,
    10'd200, 10'd200
  };

  wire [59:0] geometry_2 = {
    10'd300, 10'd100,
    10'd250, 10'd300,
    10'd400, 10'd300
  };

  reg [3:0] frame_counter;

  always @(posedge vsync) begin
    frame_counter <= frame_counter + 1;
  end

  wire [59:0] geometry = frame_counter[0] ? geometry_1 : geometry_2;

  wire fill;

  triscan tscan(
    .clk(clk),
    .reset(reset),
    .hsync(hsync),
    .vsync(vsync),
    .hpos(hpos),
    .vpos(vpos),
    .geometry(geometry),
    .fill(fill)
  );

  wire [2:0] value = fill ? (frame_counter[0] ? 3'b001 : ((hpos[0] ^ vpos[0]) ? 3'b001 : 3'b011)) : 3'b000;

  assign rgb = display_on ? value : 0;

endmodule

