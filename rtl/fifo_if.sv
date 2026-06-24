////////////////////////////////////////////////////////////////////////////////////////////////////
// INTERFACE

interface fifo_if#(
  parameter WIDTH = 8,
  parameter DEPTH = 16
);

  // DUT inputs
  logic clk;
  logic rst_n;
  logic wr_en;
  logic rd_en;
  logic [WIDTH-1:0] wr_data;

  // DUT outputs
  logic [WIDTH-1:0] rd_data;
  logic full;
  logic empty;

  // Write and read pointers - to be used for coverage
  logic [$clog2(DEPTH)-1:0] wr_ptr;
  logic [$clog2(DEPTH)-1:0] rd_ptr;

endinterface
