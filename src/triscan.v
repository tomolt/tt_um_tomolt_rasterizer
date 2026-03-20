/* 
 * Copyright (c) 2026 Thomas Oltmann
 * SPDX-License-Identifier: Apache-2.0
 * vim: sts=2 ts=2 sw=2 et
 */

`default_nettype none

module triscan(
  input wire clk,
  input wire rst_n,
  input wire [9:0] hpos,
  input wire [9:0] vpos,
  input wire [59:0] geometry,
  output wire fill
);

  wire [9:0] vtx_1_x = geometry[59:50];
  wire [9:0] vtx_1_y = geometry[49:40];
  wire [9:0] vtx_2_x = geometry[39:30];
  wire [9:0] vtx_2_y = geometry[29:20];
  wire [9:0] vtx_3_x = geometry[19:10];
  wire [9:0] vtx_3_y = geometry[ 9: 0];
  
  wire [9:0] edge_12_dx = vtx_2_x - vtx_1_x;
  wire [9:0] edge_12_dy = vtx_2_y - vtx_1_y;
  wire [9:0] edge_13_dx = vtx_3_x - vtx_1_x;
  wire [9:0] edge_13_dy = vtx_3_y - vtx_1_y;
  wire [9:0] edge_23_dx = vtx_3_x - vtx_2_x;
  wire [9:0] edge_23_dy = vtx_3_y - vtx_2_y;
  
  reg [9:0] left_dx;
  reg [9:0] left_dy;
  reg [9:0] left_x;
  reg [9:0] left_err;
  
  reg [9:0] right_dx;
  reg [9:0] right_dy;
  reg [9:0] right_x;
  reg [9:0] right_err;

  // The state of the triangle scanline rasterizer is determined
  // by which vertices of the triangle we have already scanned over vertically.
  localparam
    STATE_V1    = 2'b00,
    STATE_V1_V2 = 2'b01,
    STATE_V1_V3 = 2'b10,
    STATE_CLEAR = 2'b11;

  reg [1:0] state;
  
  function [9:0] abs;
    input [9:0] x;
    begin
      abs = x[9] ? -x : x;
    end
  endfunction
  
  function [9:0] sign;
    input [9:0] x;
    begin
      sign = x[9] ? -1 : 1;
    end
  endfunction
  
  always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      state <= STATE_CLEAR;
      
    end else if (hpos == 641) begin
      // During the H-Blank (between rows), we advance both edges to the next row.
      // We also accumulate the amount of horizontal position error that this causes.
      // If we hit one of the vertices of the triangle, we have to change state.
      case (state)
        STATE_CLEAR:
          if (vpos+1 == vtx_1_y) begin
            left_x    <= vtx_1_x;
            right_x   <= vtx_1_x;

            if (vtx_1_y == vtx_2_y) begin
              state <= STATE_V1_V2;
              left_err  <= edge_23_dy >> 1;
              right_err <= edge_13_dy >> 1;
              left_dx   <= edge_23_dx;
              left_dy   <= edge_23_dy;
              right_dx  <= edge_13_dx;
              right_dy  <= edge_13_dy;
            end else begin
              state <= STATE_V1;
              left_err  <= edge_12_dy >> 1;
              right_err <= edge_13_dy >> 1;
              left_dx   <= edge_12_dx;
              left_dy   <= edge_12_dy;
              right_dx  <= edge_13_dx;
              right_dy  <= edge_13_dy;
            end
          end
        STATE_V1:
          if (vpos+1 == vtx_2_y) begin
            state     <= (vtx_2_y == vtx_3_y) ? STATE_CLEAR : STATE_V1_V2;
            left_x    <= vtx_2_x;
            left_err  <= edge_23_dy >> 1;
            left_dx   <= edge_23_dx;
            left_dy   <= edge_23_dy;
          end else if (vpos+1 == vtx_3_y) begin
            state     <= STATE_V1_V3;
            right_x   <= vtx_3_x;
            right_err <= -edge_23_dy >> 1;
            right_dx  <= edge_23_dx;
            right_dy  <= edge_23_dy;
          end else begin
            left_err  <= left_err  - abs(left_dx);
            right_err <= right_err - abs(right_dx);
          end
        STATE_V1_V2:
          if (vpos+1 == vtx_3_y) begin
            state     <= STATE_CLEAR;
          end else begin
            left_err  <= left_err  - abs(left_dx);
            right_err <= right_err - abs(right_dx);
          end
        STATE_V1_V3:
          if (vpos+1 == vtx_2_y) begin
            state     <= STATE_CLEAR;
          end else begin
            left_err  <= left_err  - abs(left_dx);
            right_err <= right_err - abs(right_dx);
          end
      endcase

    end else if (state != STATE_CLEAR) begin
      // If the position error of the left edge is above the threshold,
      // make a step along the X axis and reduce the error accordingly.
      if (left_err[9]) begin
        left_x <= left_x + sign(left_dx);
        left_err <= left_err + left_dy;
      end

      // If the position error of the right edge is above the threshold,
      // make a step along the X axis and reduce the error accordingly.
      if (right_err[9]) begin
          right_x <= right_x + sign(right_dx);
          right_err <= right_err - right_dy;
      end
    end
  end
  
  assign fill = (state != STATE_CLEAR && hpos >= left_x && hpos < right_x);
endmodule

