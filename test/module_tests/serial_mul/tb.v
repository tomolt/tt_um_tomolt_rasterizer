`default_nettype none
`timescale 1ns / 1ps

/* This testbench just instantiates the module and makes some convenient wires
   that can be driven / tested by the cocotb test.py.
*/
module tb ();

  // Dump the signals to a FST file. You can view it with gtkwave or surfer.
  initial begin
    $dumpfile("tb.fst");
    $dumpvars(0, tb);
    #1;
  end

  localparam WIDTH = 10;

  // Wire up the inputs and outputs:
  reg clk;
  reg load;
  reg [WIDTH-1:0] n1;
  reg [WIDTH-1:0] n2;
  wire [2*WIDTH-1:0] product;

  serial_mul #(.WIDTH(WIDTH)) serial_mul (
	  .clk(clk),
	  .load(load),
	  .n1(n1),
	  .n2(n2),
	  .product(product)
  );

endmodule
