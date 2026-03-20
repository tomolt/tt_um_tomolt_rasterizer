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
  
  wire [9:0] left_x1 = (state == STATE_V1 || state == STATE_V1_V3) ? vtx_1_x : vtx_2_x;
  wire [9:0] left_y1 = (state == STATE_V1 || state == STATE_V1_V3) ? vtx_1_y : vtx_2_y;
  wire [9:0] left_x2 = (state == STATE_V1 || state == STATE_V1_V3) ? vtx_2_x : vtx_3_x;
  wire [9:0] left_y2 = (state == STATE_V1 || state == STATE_V1_V3) ? vtx_2_y : vtx_3_y;
  
  wire [9:0] right_x1 = (state == STATE_V1 || state == STATE_V1_V2) ? vtx_1_x : vtx_3_x;
  wire [9:0] right_y1 = (state == STATE_V1 || state == STATE_V1_V2) ? vtx_1_y : vtx_3_y;
  wire [9:0] right_x2 = (state == STATE_V1 || state == STATE_V1_V2) ? vtx_3_x : vtx_2_x;
  wire [9:0] right_y2 = (state == STATE_V1 || state == STATE_V1_V2) ? vtx_3_y : vtx_2_y;
  
  wire [9:0] edge_dx = hpos < 640 + 49 ? (left_x2 - left_x1) : (right_x2 - right_x1);
  wire [9:0] edge_dy = hpos < 640 + 49 ? (left_y2 - left_y1) : (right_y2 - right_y1);
  wire [9:0] edge_dx_abs = abs(edge_dx);
  wire [9:0] edge_dy_abs = abs(edge_dy);
  wire [9:0] edge_dist = hpos < 640 + 49 ? (vpos+10'd1) - left_y1 : (vpos+10'd1) - (right_y1);
  
  wire md_load = (hpos == 640 + 10) || (hpos == 640 + 50);
  
  wire [9:0] md_quo;
  wire [9:0] md_rem;
  
  reg [9:0] left_x;
  reg [9:0] right_x;
  
  serial_muldiv muldiv(
    .clk(clk),
    .load(md_load),
    .mu1(edge_dx_abs),
    .mu2(edge_dist),
    .den(edge_dy_abs),
    .quo(md_quo),
    .rem(md_rem)
  );

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
      
    end else if (hpos == 640 + 5) begin
      // During the H-Blank (between rows), we advance both edges to the next row.
      // We also accumulate the amount of horizontal position error that this causes.
      // If we hit one of the vertices of the triangle, we have to change state.
      case (state)
        STATE_CLEAR:
          if (vpos+1 == vtx_1_y) begin
            if (vtx_1_y == vtx_2_y) begin
              state <= STATE_V1_V2;
            end else begin
              state <= STATE_V1;
            end
          end
        STATE_V1:
          if (vpos+1 == vtx_2_y) begin
            state     <= (vtx_2_y == vtx_3_y) ? STATE_CLEAR : STATE_V1_V2;
          end else if (vpos+1 == vtx_3_y) begin
            state     <= STATE_V1_V3;
          end
        STATE_V1_V2:
          if (vpos+1 == vtx_3_y) begin
            state     <= STATE_CLEAR;
          end
        STATE_V1_V3:
          if (vpos+1 == vtx_2_y) begin
            state     <= STATE_CLEAR;
          end
      endcase
      
    end else if (hpos == 640 + 45) begin
      left_x <= (edge_dx[9] ^ edge_dy[9] ? -md_quo : md_quo) + left_x1;
    end else if (hpos == 640 + 85) begin
      right_x <= (edge_dx[9] ^ edge_dy[9] ? -md_quo : md_quo) + right_x1;
    end
  end
  
  assign fill = (state != STATE_CLEAR && hpos >= left_x && hpos < right_x);
endmodule

