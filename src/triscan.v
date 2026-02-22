/* 
 * Copyright (c) 2026 Thomas Oltmann
 * SPDX-License-Identifier: Apache-2.0
 * vim: sts=2 ts=2 sw=2 et
 */

`default_nettype none

module triscan(
  input wire clk,
  input wire reset,
  input wire hsync,
  input wire vsync,
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
  reg [9:0] left_x;
  reg [9:0] left_err;
  
  reg [9:0] right_dx;
  reg [9:0] right_x;
  reg [9:0] right_err;

  parameter
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
  
  always @(posedge clk, posedge reset) begin
    if (reset) begin
      state <= STATE_CLEAR;
    end else if (hpos == 640) begin
      case (state)
        STATE_CLEAR:
          if (vpos+1 == vtx_1_y) begin
            state     <= (vtx_1_y == vtx_2_y) ? STATE_V1_V2 : STATE_V1;
            left_x    <= vtx_1_x;
            right_x   <= vtx_1_x;
            left_err  <= edge_12_dy >> 1;
            right_err <= edge_13_dy >> 1;
          end
        STATE_V1:
          if (vpos+1 == vtx_2_y) begin
            state     <= (vtx_2_y == vtx_3_y) ? STATE_CLEAR : STATE_V1_V2;
            left_x    <= vtx_2_x;
            left_err  <= edge_23_dy >> 1;
          end else if (vpos+1 == vtx_3_y) begin
            state     <= STATE_V1_V3;
            right_x   <= vtx_3_x;
            right_err <= -edge_23_dy >> 1;
          end else begin
            left_err  <= left_err  - abs(edge_12_dx);
            right_err <= right_err - abs(edge_13_dx);
          end
        STATE_V1_V2:
          if (vpos+1 == vtx_3_y) begin
            state     <= STATE_CLEAR;
          end else begin
            left_err  <= left_err  - abs(edge_23_dx);
            right_err <= right_err - abs(edge_13_dx);
          end
        STATE_V1_V3:
          if (vpos+1 == vtx_2_y) begin
            state     <= STATE_CLEAR;
          end else begin
            left_err  <= left_err  - abs(edge_12_dx);
            right_err <= right_err - abs(edge_23_dx);
          end
      endcase
    end else begin
      if (left_err[9]) begin
        case (state)
          STATE_CLEAR:;
          STATE_V1: begin
            left_x <= left_x + sign(edge_12_dx);
            left_err <= left_err + edge_12_dy;
          end
          STATE_V1_V2: begin
            left_x <= left_x + sign(edge_23_dx);
            left_err <= left_err + edge_23_dy;
          end
          STATE_V1_V3: begin
            left_x <= left_x + sign(edge_12_dx);
            left_err <= left_err + edge_12_dy;
          end
        endcase
      end
      if (right_err[9]) begin
        case (state)
          STATE_CLEAR:;
          STATE_V1: begin
            right_x <= right_x + sign(edge_13_dx);
            right_err <= right_err + edge_13_dy;
          end
          STATE_V1_V2: begin
            right_x <= right_x + sign(edge_13_dx);
            right_err <= right_err + edge_13_dy;
          end
          STATE_V1_V3: begin
            right_x <= right_x - sign(edge_23_dx);
            right_err <= right_err - edge_23_dy;
          end
        endcase
      end
    end
  end
  
  assign fill = (state != STATE_CLEAR && hpos >= left_x && hpos < right_x);
endmodule

