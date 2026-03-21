/* 
 * Copyright (c) 2026 Thomas Oltmann
 * SPDX-License-Identifier: Apache-2.0
 * vim: sts=2 ts=2 sw=2 et
 */

`default_nettype none

module triscan #(XOFFSET=0) (
  input wire clk,
  input wire rst_n,
  input wire [9:0] hpos,
  input wire [9:0] vpos,
  input wire [9:0] v1x,
  input wire [9:0] v1y,
  input wire [9:0] v2x,
  input wire [9:0] v2y,
  input wire [9:0] v3x,
  input wire [9:0] v3y,
  output wire fill
);

  localparam H_DISPLAY = 640;
  localparam V_DISPLAY = 480;

  wire [9:0] next_vpos = vpos < V_DISPLAY ? vpos + 10'd1 : 0;

  wire [9:0] left_x1 = (state == STATE_V1 || state == STATE_V1_V3) ? v1x : v2x;
  wire [9:0] left_y1 = (state == STATE_V1 || state == STATE_V1_V3) ? v1y : v2y;
  wire [9:0] left_x2 = (state == STATE_V1 || state == STATE_V1_V3) ? v2x : v3x;
  wire [9:0] left_y2 = (state == STATE_V1 || state == STATE_V1_V3) ? v2y : v3y;
  wire left_sign = left_x1 > left_x2;
  
  wire [9:0] right_x1 = (state == STATE_V1 || state == STATE_V1_V2) ? v1x : v3x;
  wire [9:0] right_y1 = (state == STATE_V1 || state == STATE_V1_V2) ? v1y : v3y;
  wire [9:0] right_x2 = (state == STATE_V1 || state == STATE_V1_V2) ? v3x : v2x;
  wire [9:0] right_y2 = (state == STATE_V1 || state == STATE_V1_V2) ? v3y : v2y;
  wire right_sign = right_x1 > right_x2;

  wire wired_to_left = hpos < H_DISPLAY + 49;
  wire [9:0] edge_x1 = wired_to_left ? left_x1 : right_x1;
  wire [9:0] edge_y1 = wired_to_left ? left_y1 : right_y1;
  wire [9:0] edge_x2 = wired_to_left ? left_x2 : right_x2;
  wire [9:0] edge_y2 = wired_to_left ? left_y2 : right_y2;
  wire edge_sign = wired_to_left ? left_sign : right_sign;

  wire [9:0] edge_dx_abs = ~edge_sign ? edge_x2 - edge_x1 : edge_x1 - edge_x2;
  wire [9:0] edge_dy = edge_y2 - edge_y1;
  wire [9:0] edge_dist = next_vpos - edge_y1;

  wire md_load = ~rst_n || (hpos == H_DISPLAY + 10) || (hpos == H_DISPLAY + 50);
  wire [9:0] md_quo;
  wire [9:0] md_rem;
  
  serial_muldiv muldiv(
    .clk(clk),
    .load(md_load),
    .mu1(edge_dx_abs),
    .mu2(edge_dist),
    .den(edge_dy),
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
  reg [9:0] left_x;
  
  wire [9:0] xoffset = XOFFSET;
  
  always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      state <= STATE_CLEAR;
      left_x <= 0;
      
    end else if (hpos == H_DISPLAY + 5) begin
      // During the H-Blank (between rows), we advance both edges to the next row.
      // We also accumulate the amount of horizontal position error that this causes.
      // If we hit one of the vertices of the triangle, we have to change state.
      case (state)
        STATE_CLEAR:
          if (next_vpos == v1y) begin
            if (v1y == v2y) begin
              state <= STATE_V1_V2;
            end else begin
              state <= STATE_V1;
            end
          end
        STATE_V1:
          if (next_vpos == v2y) begin
            state <= (v2y == v3y) ? STATE_CLEAR : STATE_V1_V2;
          end else if (next_vpos == v3y) begin
            state <= STATE_V1_V3;
          end
        STATE_V1_V2:
          if (next_vpos == v3y) begin
            state <= STATE_CLEAR;
          end
        STATE_V1_V3:
          if (next_vpos == v2y) begin
            state <= STATE_CLEAR;
          end
      endcase
      
    // Wait until the multiply-divide unit is done, then update the edge
    // position.
    end else if (hpos == H_DISPLAY + 45) begin
      if (~left_sign) begin
        left_x <= xoffset + left_x1 + md_quo;
      end else begin
        left_x <= xoffset + left_x1 - md_quo;
      end
    end
  end

  wire [9:0] right_x = ~right_sign ?
    xoffset + right_x1 + md_quo :
    xoffset + right_x1 - md_quo;
  
  assign fill = (state != STATE_CLEAR && hpos >= left_x && hpos < right_x);
endmodule

