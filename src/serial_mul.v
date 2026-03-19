/*
* Copyright (c) 2026 Thomas Oltmann
* SPDX-License-Identifier: Apache-2.0
* vim: sts=2 ts=2 sw=2 et
*/

module serial_mul #(parameter WIDTH = 10) (
  input wire clk,
  input wire load,
  input wire [WIDTH-1:0] n1,
  input wire [WIDTH-1:0] n2,
  output reg [WIDTH-1:0] product);

  reg [3:0] state;
  reg [WIDTH-1:0] window;

  always @(posedge clk) begin
    if (load) begin
      window <= n1;
      product <= 0;
      state <= 0;
    end else begin
      if (state < WIDTH) begin
        if (window[WIDTH-1]) begin
          product = {product[WIDTH-2:0], 1'b0} + n2;
        end else begin
          product = {product[WIDTH-2:0], 1'b0};
        end
        window = {window[WIDTH-2:0], 1'b0};
        state <= state + 1;
      end
    end
  end

endmodule

