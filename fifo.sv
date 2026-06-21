// =================================================================================================
// PARAMETRIZED SYNCHRONOUS FIFO
//
// INCLUSIONS:
// - fifo
// - fifo_if
// =================================================================================================




////////////////////////////////////////////////////////////////////////////////////////////////////
// RTL DESIGN

module fifo #(
  parameter int WIDTH = 8,
  parameter int DEPTH = 16
) (
  input  logic             clk,
  input  logic             rst_n,
  input  logic             wr_en,
  input  logic             rd_en,
  input  logic [WIDTH-1:0] wr_data,
  output logic [WIDTH-1:0] rd_data,
  output logic             full,
  output logic             empty
);

  // Local parameter for address width
  localparam int ADDR_WIDTH = $clog2 (DEPTH);

  // FIFO array
  logic [WIDTH-1:0] fifo_mem [0:DEPTH-1];

  // Write and read pointers
  logic [ADDR_WIDTH-1:0] wr_ptr;
  logic [ADDR_WIDTH-1:0] rd_ptr;

  // FIFO occupancy count - has one extra bit to avoid overflow
  logic [ADDR_WIDTH:0] count;

  // Valid flags to check for space to write or data to read
  logic  wr_valid;
  logic  rd_valid;
  assign wr_valid = (wr_en && !full);
  assign rd_valid = (rd_en && !empty);

  // Status flags
  assign full  = (count == DEPTH);
  assign empty = (count == 0);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // MAIN FIFO LOGIC

  always_ff @(posedge clk)
    if (!rst_n) begin
      wr_ptr  <= 0;
      rd_ptr  <= 0;
      rd_data <= 0;
      count   <= 0;
    end else begin

      //////////////////////////////////////////////////////////////////////////////////////////////
      // WRITE TO FIFO

      if (wr_valid) begin
        fifo_mem [wr_ptr] <= wr_data;
        if (wr_ptr == DEPTH - 1)
          wr_ptr <= 0;
        else
          wr_ptr <= wr_ptr + 1;
      end

      //////////////////////////////////////////////////////////////////////////////////////////////
      // READ FROM FIFO

      if (rd_valid) begin
        rd_data  <= fifo_mem [rd_ptr];
        if (rd_ptr == DEPTH - 1)
          rd_ptr <= 0;
        else
          rd_ptr <= rd_ptr + 1;
      end

      //////////////////////////////////////////////////////////////////////////////////////////////
      // UPDATE FIFO COUNT

      case ({wr_valid, rd_valid})
        2'b10  : count <= count + 1;
        2'b01  : count <= count - 1;
        default: ;
      endcase

    end

endmodule




////////////////////////////////////////////////////////////////////////////////////////////////////
// INTERFACE

interface fifo_if #(
  parameter int WIDTH = 8,
  parameter int DEPTH = 16
);

  // DUT inputs
  logic             clk;
  logic             rst_n;
  logic             wr_en;
  logic             rd_en;
  logic [WIDTH-1:0] wr_data;

  // DUT outputs
  logic [WIDTH-1:0] rd_data;
  logic             full;
  logic             empty;

  // Write and read pointers - only used for coverage purposes
  logic [$clog2(DEPTH)-1:0] wr_ptr;
  logic [$clog2(DEPTH)-1:0] rd_ptr;

endinterface
