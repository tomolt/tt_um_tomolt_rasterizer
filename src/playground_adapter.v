/* 
 * Copyright (c) 2026 Thomas Oltmann
 * SPDX-License-Identifier: Apache-2.0
 * vim: sts=2 ts=2 sw=2 et
 */

`include "hvsync_generator.v"
`include "triscan.v"
`include "prog_if.v"
`include "rasterizer.v"
`include "serial_muldiv.v"

module playground_adapter (
  input wire clk,
  input wire reset,
  output wire hsync,
  output wire vsync,
  output wire [2:0] rgb
);

  wire rst_n = ~reset;
  wire [7:0] ui_in = 0;
  wire [7:0] uo_out;
  reg [7:0] uio_in;
  wire [7:0] uio_out;
  wire [7:0] uio_oe = 0;
  wire ena = 1;
  
  tt_um_tomolt_rasterizer rasterizer(
    .clk(clk),
    .rst_n(rst_n),
    .ena(ena),
    .ui_in(ui_in),
    .uo_out(uo_out),
    .uio_in(uio_in),
    .uio_out(uio_out),
    .uio_oe(uio_oe)
  );

  assign hsync = uo_out[7];
  assign vsync = uo_out[3];
  assign rgb = uo_out[2:0];
  
  wire [7:0] new_v1x = 8'd31;
  wire [7:0] new_v1y = 8'd10;
  wire [7:0] new_v2x = 8'd0;
  wire [7:0] new_v2y = 8'd56;
  wire [7:0] new_v3x = 8'd63;
  wire [7:0] new_v3y = 8'd24;
  wire [7:0] new_fcolor = 8'b00110011;
  wire [7:0] new_bcolor = 8'b00001100;
  
  reg [2:0] serial_div;
  reg [6:0] serial_cur;
  reg prev_vsync;
  reg serial_cs;
  reg serial_mosi;
  reg serial_clk;
  
  always @(*) begin
    uio_in[0] = serial_cs;
    uio_in[1] = serial_mosi;
    uio_in[2] = 0;
    uio_in[3] = serial_clk;
    uio_in[7:4] = 0;
  end
  
  always @(posedge reset, posedge clk) begin
    if (reset) begin
      serial_div <= 0;
      serial_cur <= 0;
      serial_cs <= 0;
      prev_vsync <= 0;
    end else begin
      prev_vsync <= vsync;
      if (~prev_vsync && vsync) begin
        serial_cur <= 0;
        serial_div <= 0;
        serial_cs <= 0;
      end else if (~vsync) begin
        serial_cs <= 1;
      end
      serial_clk <= (serial_div <= 3'b100);
      if (serial_div == 3'b001) begin
        if (serial_cur < 1*8) begin
          serial_mosi <= new_v1x[7-(serial_cur-0*8)];
        end else if (serial_cur < 2*8) begin
          serial_mosi <= new_v1y[7-(serial_cur-1*8)];
        end else if (serial_cur < 3*8) begin
          serial_mosi <= new_v2x[7-(serial_cur-2*8)];
        end else if (serial_cur < 4*8) begin
          serial_mosi <= new_v2y[7-(serial_cur-3*8)];
        end else if (serial_cur < 5*8) begin
          serial_mosi <= new_v3x[7-(serial_cur-4*8)];
        end else if (serial_cur < 6*8) begin
          serial_mosi <= new_v3y[7-(serial_cur-5*8)];
        end else if (serial_cur < 7*8) begin
          serial_mosi <= new_fcolor[7-(serial_cur-6*8)];
        end else begin
          serial_mosi <= new_bcolor[7-(serial_cur-7*8)];
        end
      end
      if (serial_div == 3'b110) begin
        if (serial_cur < 8*8-1) begin
          serial_cur <= serial_cur + 1;
        end else begin
          serial_cur <= 0;
          serial_div <= 0;
        end
      end
      serial_div <= serial_div + 1;
    end
  end
  
endmodule

