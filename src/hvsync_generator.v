/* 
 * Copyright (c) 2026 Thomas Oltmann
 * SPDX-License-Identifier: Apache-2.0
 * vim: sts=2 ts=2 sw=2 et
 */

// Video sync generator, used to drive a VGA monitor.
module hvsync_generator(
  input clk,
  input rst_n,
  output reg hsync,
  output reg vsync,
  output wire display_on,
  output reg [9:0] hpos,
  output reg [9:0] vpos
);

  // declarations for TV-simulator sync parameters
  // horizontal constants
  localparam H_DISPLAY       = 640; // horizontal display width
  localparam H_BACK          =  48; // horizontal left border (back porch)
  localparam H_FRONT         =  16; // horizontal right border (front porch)
  localparam H_SYNC          =  96; // horizontal sync width
  // vertical constants
  localparam V_DISPLAY       = 480; // vertical display height
  localparam V_TOP           =  33; // vertical top border
  localparam V_BOTTOM        =  10; // vertical bottom border
  localparam V_SYNC          =   2; // vertical sync # lines
  // derived constants
  localparam H_SYNC_START    = H_DISPLAY + H_FRONT;
  localparam H_SYNC_END      = H_DISPLAY + H_FRONT + H_SYNC - 1;
  localparam H_MAX           = H_DISPLAY + H_BACK + H_FRONT + H_SYNC - 1;
  localparam V_SYNC_START    = V_DISPLAY + V_BOTTOM;
  localparam V_SYNC_END      = V_DISPLAY + V_BOTTOM + V_SYNC - 1;
  localparam V_MAX           = V_DISPLAY + V_TOP + V_BOTTOM + V_SYNC - 1;

  // horizontal position counter
  always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      hpos <= 0;
    end else begin
      hsync <= (hpos >= H_SYNC_START && hpos <= H_SYNC_END);
      if (hpos == H_MAX) begin
        hpos <= 0;
      end else begin
        hpos <= hpos + 1;
      end
    end
  end

  // vertical position counter
  always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      vpos <= 0;
    end else begin
      vsync <= (vpos >= V_SYNC_START && vpos <= V_SYNC_END);
      if (hpos == H_MAX) begin
        if (vpos == V_MAX) begin
          vpos <= 0;
        end else begin
          vpos <= vpos + 1;
        end
      end
    end
  end
  
  // display_on is set when beam is in "safe" visible frame
  assign display_on = (hpos<H_DISPLAY) && (vpos<V_DISPLAY);

endmodule

