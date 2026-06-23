// =================================================================================================
// PARAMETRIZED SYNCHRONOUS FIFO
//
// Inclusions:
// - fifo
// - fifo_if
// =================================================================================================




////////////////////////////////////////////////////////////////////////////////////////////////////
// RTL DESIGN
//
// Features:
// - Parametrized FIFO data width (WIDTH) and FIFO depth (DEPTH)
// - Single clock for both write and read operations
// - Support for simultaneous write and read operations
// - Synchronous active-low reset

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

  localparam int ADDR_WIDTH = $clog2(DEPTH);

  logic [     WIDTH-1:0] fifo_mem [0:DEPTH-1];  // Memory array
  logic [ADDR_WIDTH-1:0] wr_ptr;                // Write pointer
  logic [ADDR_WIDTH-1:0] rd_ptr;                // Read pointer
  logic [ADDR_WIDTH  :0] count;                 // Occupancy count - has one extra bit
  logic                  wr_valid;              // Write valid signal
  logic                  rd_valid;              // Read valid signal

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // MAIN FIFO LOGIC

  assign wr_valid = (wr_en && !full);
  assign rd_valid = (rd_en && !empty);
  assign full     = (count == DEPTH);
  assign empty    = (count == 0);

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      wr_ptr  <= 0;
      rd_ptr  <= 0;
      rd_data <= 0;
      count   <= 0;
    end else begin

      // Write from FIFO if valid
      if (wr_valid) begin
        fifo_mem[wr_ptr] <= wr_data;
        wr_ptr           <= (wr_ptr == DEPTH - 1) ? 0 : (wr_ptr + 1);
      end

      // Read from FIFO if valid
      if (rd_valid) begin
        rd_data <= fifo_mem[rd_ptr];
        rd_ptr  <= (rd_ptr == DEPTH - 1) ? 0 : (rd_ptr + 1);
      end

      // Update occupancy count
      case ({wr_valid, rd_valid})
        2'b10  : count <= count + 1;
        2'b01  : count <= count - 1;
        default: ;
      endcase

    end
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
