////////////////////////////////////////////////////////////////////////////////////////////////////
// TESTBENCH TOP
//
// The testbench parameters (WIDTH, DEPTH, and TEST_SIZE) are defined in fifo_tb_pkg.sv.

`include "fifo_tb_pkg.sv"

module fifo_tb_top;

  // Import UVM and testbench packages
  import uvm_pkg::*;
  import fifo_tb_pkg::*;

  // Instantiate interface
  fifo_if#(
    .WIDTH(WIDTH),
    .DEPTH(DEPTH)
  ) vif(
  );

  // Instantiate DUT
  fifo#(
    .WIDTH(WIDTH),
    .DEPTH(DEPTH)
  ) dut(
    .clk(vif.clk),
    .rst_n(vif.rst_n),
    .wr_en(vif.wr_en),
    .rd_en(vif.rd_en),
    .wr_data(vif.wr_data),
    .rd_data(vif.rd_data),
    .full(vif.full),
    .empty(vif.empty)
  );

  // Connect DUT internal signals
  assign vif.wr_ptr = dut.wr_ptr;
  assign vif.rd_ptr = dut.rd_ptr;

  // Generate clock
  always #5 vif.clk = ~vif.clk;

  // Dump VCD file for waveform viewing
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, fifo_tb_top);
  end

  // Run test
  initial begin
    vif.clk = 0;
    vif.rst_n = 0;
    uvm_config_db#(virtual fifo_if#(WIDTH, DEPTH))::set(null, "*", "vif", vif);
    run_test("fifo_test");
  end

endmodule
