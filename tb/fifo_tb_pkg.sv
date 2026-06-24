////////////////////////////////////////////////////////////////////////////////////////////////////
// TESTBENCH PACKAGE

package fifo_tb_pkg;

  // Import UVM package and include UVM macros
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Define parameters
  localparam int WIDTH = 8;
  localparam int DEPTH = 16;
  localparam int TEST_SIZE = 2000;

  // Include all testbench files
  `include "fifo_sequence_item.sv"
  `include "fifo_sequence.sv"
  `include "fifo_sequencer.sv"
  `include "fifo_driver.sv"
  `include "fifo_monitor.sv"
  `include "fifo_agent.sv"
  `include "fifo_scoreboard.sv"
  `include "fifo_coverage.sv"
  `include "fifo_env.sv"
  `include "fifo_test.sv"

endpackage
