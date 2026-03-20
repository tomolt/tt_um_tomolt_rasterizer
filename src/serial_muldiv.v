/*
* Copyright (c) 2026 Thomas Oltmann
* SPDX-License-Identifier: Apache-2.0
* vim: sts=2 ts=2 sw=2 et
*/

module serial_muldiv #(parameter WIDTH = 10) (
  input wire clk,
  input wire load,
  input wire [WIDTH-1:0] mu1,
  input wire [WIDTH-1:0] mu2,
  input wire [WIDTH-1:0] den,
  output reg [WIDTH-1:0] quo,
  output reg [WIDTH-1:0] rem);

  reg [4:0] state;
  reg [4*WIDTH-1:0] accum;

  assign quo = accum[WIDTH-1:0];
  assign rem = accum[3*WIDTH-1:2*WIDTH];

  always @(posedge clk) begin
    if (load) begin
      accum[4*WIDTH-1:3*WIDTH] <= mu1;
      accum[3*WIDTH-1:0] <= 0;
      state <= 0;
    end else begin
      if (state < WIDTH) begin
        if (accum[4*WIDTH-1]) begin
          accum[2*WIDTH-1:0] <= {accum[2*WIDTH-2:0], 1'b0} + {{WIDTH{1'b0}}, mu2};
        end else begin
          accum[2*WIDTH-1:0] <= {accum[2*WIDTH-2:0], 1'b0};
        end
        accum[4*WIDTH-1:3*WIDTH] <= {accum[4*WIDTH-2:3*WIDTH], 1'b0};
        state <= state + 1;
      end else if (state < 3*WIDTH) begin
        if (accum[4*WIDTH-2:2*WIDTH-1] >= {{WIDTH{1'b0}}, den}) begin
          accum <= {accum[4*WIDTH-2:2*WIDTH-1] - {{WIDTH{1'b0}}, den}, accum[2*WIDTH-2:0], 1'b1};
        end else begin
          accum <= {accum[4*WIDTH-2:0], 1'b0};
        end
        state <= state + 1;
      end
    end
  end

endmodule

