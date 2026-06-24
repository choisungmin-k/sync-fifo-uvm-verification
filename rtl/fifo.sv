////////////////////////////////////////////////////////////////////////////////////////////////////
// RTL DESIGN
//
// This is a parametrized synchronous FIFO design with the following features:
// - Parametrized FIFO data width (WIDTH) and FIFO depth (DEPTH)
// - Single clock for both write and read operations
// - Support for simultaneous write and read operations
// - Synchronous active-low reset

`include "fifo_if.sv"

module fifo#(
  parameter WIDTH = 8,
  parameter DEPTH = 16
)(
  input logic clk,
  input logic rst_n,
  input logic wr_en,
  input logic rd_en,
  input logic [WIDTH-1:0] wr_data,
  output logic [WIDTH-1:0] rd_data,
  output logic full,
  output logic empty
);

  logic [WIDTH-1:0] mem[0:DEPTH-1];  // Memory array
  logic [$clog2(DEPTH)-1:0] wr_ptr;  // Write pointer
  logic [$clog2(DEPTH)-1:0] rd_ptr;  // Read pointer
  logic [$clog2(DEPTH):0] count;     // Occupancy count - has one extra bit to avoid overflow
  logic wr_valid;                    // Write valid signal
  logic rd_valid;                    // Read valid signal

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // FIFO CONTROL LOGIC

  assign full = (count == DEPTH);
  assign empty = (count == 0);
  assign wr_valid = (wr_en && !full);
  assign rd_valid = (rd_en && !empty);

  always_ff @(posedge clk)
    if (!rst_n) begin
      rd_data <= 0;
      wr_ptr <= 0;
      rd_ptr <= 0;
      count <= 0;
    end else begin

      // Write to FIFO if valid
      if (wr_valid) begin
        mem[wr_ptr] <= wr_data;
        wr_ptr <= (wr_ptr == DEPTH - 1) ? 0 : wr_ptr + 1;
      end

      // Read from FIFO if valid
      if (rd_valid) begin
        rd_data <= mem[rd_ptr];
        rd_ptr <= (rd_ptr == DEPTH - 1) ? 0 : rd_ptr + 1;
      end

      // Update Occupancy count
      case ({wr_valid, rd_valid})
        2'b10: count <= count + 1;
        2'b01: count <= count - 1;
        default: ;
      endcase

    end

endmodule
