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

  // Wire up the inputs and outputs:
  reg clk;
  reg rst_n;
  reg cs_n;
  reg mosi;
  reg sck;
  wire [9:0] v1x;
  wire [9:0] v1y;
  wire [9:0] v2x;
  wire [9:0] v2y;
  wire [9:0] v3x;
  wire [9:0] v3y;
  wire [5:0] fcolor;
  wire [5:0] bcolor;

  prog_if pif(
    .clk(clk),
    .rst_n(rst_n),
    .cs_n(cs_n),
    .mosi(mosi),
    .sck(sck),
    .v1x(v1x),
    .v1y(v1y),
    .v2x(v2x),
    .v2y(v2y),
    .v3x(v3x),
    .v3y(v3y),
    .fcolor(fcolor),
    .bcolor(bcolor)
  );

endmodule
