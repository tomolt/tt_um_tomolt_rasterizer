/* 
 * Copyright (c) 2026 Thomas Oltmann
 * SPDX-License-Identifier: Apache-2.0
 * vim: sts=2 ts=2 sw=2 et
 */

`default_nettype none

// Programmatic Interface to upload geometry & color data
module prog_if (
  input wire clk,
  input wire rst_n,
  input wire cs_n,
  input wire mosi,
  input wire sck,
  output wire [9:0] v1x,
  output wire [9:0] v1y,
  output wire [9:0] v2x,
  output wire [9:0] v2y,
  output wire [9:0] v3x,
  output wire [9:0] v3y,
  output reg [5:0] fcolor,
  output reg [5:0] bcolor
);

  localparam
    STATE_V1X = 3'b000,
    STATE_V1Y = 3'b001,
    STATE_V2X = 3'b010,
    STATE_V2Y = 3'b011,
    STATE_V3X = 3'b100,
    STATE_V3Y = 3'b101,
    STATE_FCO = 3'b110,
    STATE_BCO = 3'b111;
  
  // Coordinate precision in bits
  localparam PREC = 6;

  reg [PREC-1:0] data_v1x;
  reg [PREC-1:0] data_v1y;
  reg [PREC-1:0] data_v2x;
  reg [PREC-1:0] data_v2y;
  reg [PREC-1:0] data_v3x;
  reg [PREC-1:0] data_v3y;

  assign v1x = {1'd0, data_v1x, 3'd0};
  assign v1y = {1'd0, data_v1y, 3'd0};
  assign v2x = {1'd0, data_v2x, 3'd0};
  assign v2y = {1'd0, data_v2y, 3'd0};
  assign v3x = {1'd0, data_v3x, 3'd0};
  assign v3y = {1'd0, data_v3y, 3'd0};

  reg [2:0] if_state;
  reg [3:0] if_count;
  reg sck_prev;

  always @(negedge rst_n or posedge clk) begin
    if (~rst_n) begin
      // Default geometry & color
      data_v1x <= 6'd35;
      data_v1y <= 6'd1;
      data_v2x <= 6'd0;
      data_v2y <= 6'd63;
      data_v3x <= 6'd63;
      data_v3y <= 6'd11;
      fcolor   <= 6'b000011;
      bcolor   <= 6'b111111;

      if_state <= STATE_V1X;
      if_count <= 0;
      sck_prev <= 0;

    end else begin
      sck_prev <= sck;
      
      if (~cs_n) begin

        if (~sck_prev && sck) begin
          case (if_state)
            STATE_V1X: data_v1x <= {data_v1x[PREC-2:0], mosi};
            STATE_V1Y: data_v1y <= {data_v1y[PREC-2:0], mosi};
            STATE_V2X: data_v2x <= {data_v2x[PREC-2:0], mosi};
            STATE_V2Y: data_v2y <= {data_v2y[PREC-2:0], mosi};
            STATE_V3X: data_v3x <= {data_v3x[PREC-2:0], mosi};
            STATE_V3Y: data_v3y <= {data_v3y[PREC-2:0], mosi};
            STATE_FCO: fcolor   <= {fcolor[5-1:0], mosi};
            STATE_BCO: bcolor   <= {bcolor[5-1:0], mosi};
            default:;
          endcase

          // After 8 bits, step over to the next word;
          // If we reached the last word, start again from the first word.
          if (if_count == 8-1) begin
            if (if_state == STATE_BCO) begin
              if_state <= STATE_V1X;
            end else begin
              if_state <= if_state + 1;
            end
            if_count <= 0;
          end else begin
            if_count <= if_count + 1;
          end
        end

      end else begin
        if_state <= STATE_V1X;
        if_count <= 0;
      end
    end
  end

endmodule
