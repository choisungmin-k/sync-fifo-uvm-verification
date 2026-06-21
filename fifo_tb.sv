// =================================================================================================
// UVM TESTBENCH FOR PARAMETERIZED SYNCHRONOUS FIFO
//
// INCLUSIONS:
// - fifo_sequence_item
// - fifo_sequence
// - fifo_sequencer
// - fifo_driver
// - fifo_monitor
// - fifo_agent
// - fifo_scoreboard
// - fifo_coverage
// - fifo_env
// - fifo_test
// - fifo_tb_top
// =================================================================================================




`timescale 1ns / 1ns

import uvm_pkg::*;
`include "uvm_macros.svh"

// Use these to adjust FIFO parameters and test size
`define WIDTH     8
`define DEPTH     16
`define TEST_SIZE 2000




////////////////////////////////////////////////////////////////////////////////////////////////////
// SEQUENCE ITEM
//
// Two constraints are applied to DUT inputs for desired FIFO behavior:
// - Resets will occur infrequently
// - Writes and simultaneous write-reads will occur frequently

class fifo_sequence_item extends uvm_sequence_item;

  `uvm_object_utils (fifo_sequence_item)

  // DUT inputs
  rand bit              rst_n;
  rand bit              wr_en;
  rand bit              rd_en;
  rand bit [`WIDTH-1:0] wr_data;

  // DUT outputs
  bit [`WIDTH-1:0] rd_data;
  bit              full;
  bit              empty;

  // Write and read pointers
  bit [$clog2(`DEPTH)-1:0] wr_ptr;
  bit [$clog2(`DEPTH)-1:0] rd_ptr;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // CONSTRUCTOR

  function new (string name = "fifo_sequence_item");
    super.new (name);
  endfunction

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // CONSTRAINTS

  constraint c_rst_n {
    rst_n dist {
      1 := 97,
      0 := 3
    };
  }

  constraint c_en {
    {wr_en, rd_en} dist {
      2'b00 := 10,
      2'b01 := 10,
      2'b10 := 40,
      2'b11 := 40
    };
  }

endclass




////////////////////////////////////////////////////////////////////////////////////////////////////
// SEQUENCE
//
// Test size is currently 2,000

class fifo_sequence extends uvm_sequence #(fifo_sequence_item);

  `uvm_object_utils (fifo_sequence)

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // CONSTRUCTOR

  function new (string name = "fifo_sequence");
    super.new (name);
  endfunction

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // MAIN TASK

  virtual task body ();
    fifo_sequence_item tx;
    for (int i = 0; i < `TEST_SIZE; i++) begin
      tx = fifo_sequence_item::type_id::create ("tx");
      start_item (tx);   // Wait for sequencer grant
      if (!tx.randomize ()) `uvm_fatal ("RAND_FAIL", "RANDOMIZATION FAILED");
      `uvm_info (
        "SEQ",
        $sformatf (
          "TRANSACTION #%0d CREATED | rst_n = %0d, wr_en = %0d, rd_en = %0d, wr_data = %0h",
          i + 1,
          tx.rst_n,
          tx.wr_en,
          tx.rd_en,
          tx.wr_data
        ),
        UVM_NONE
      );
      finish_item (tx);  // Send item to driver and wait for completion
    end
  endtask

endclass




////////////////////////////////////////////////////////////////////////////////////////////////////
// SEQUENCER

class fifo_sequencer extends uvm_sequencer #(fifo_sequence_item);

  `uvm_component_utils (fifo_sequencer)

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // CONSTRUCTOR

  function new (string name = "fifo_sequencer", uvm_component parent = null);
    super.new (name, parent);
  endfunction

endclass




////////////////////////////////////////////////////////////////////////////////////////////////////
// DRIVER

class fifo_driver extends uvm_driver #(fifo_sequence_item);

  `uvm_component_utils (fifo_driver)

  virtual fifo_if #(`WIDTH, `DEPTH) vif;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // CONSTRUCTOR

  function new (string name = "fifo_driver", uvm_component parent = null);
    super.new (name, parent);
  endfunction

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // BUILD PHASE

  function void build_phase (uvm_phase phase);
    super.build_phase (phase);
    if (!uvm_config_db #(virtual fifo_if #(`WIDTH, `DEPTH))::get (this, "", "vif", vif))
      `uvm_fatal ("VIF_FAIL", "VIRTUAL INTERFACE NOT FOUND");
  endfunction

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // RUN PHASE

  task run_phase (uvm_phase phase);
    forever begin
      seq_item_port.get_next_item (req);  // Get next item from sequencer
      drive_transaction (req);            // Drive transaction to DUT
      seq_item_port.item_done ();         // Notify sequencer of transaction completion
    end
  endtask

  task drive_transaction (fifo_sequence_item tx);
    @(posedge vif.clk);
    vif.rst_n   <= tx.rst_n;
    vif.wr_en   <= tx.wr_en;
    vif.rd_en   <= tx.rd_en;
    vif.wr_data <= tx.wr_data;
  endtask

endclass




////////////////////////////////////////////////////////////////////////////////////////////////////
// MONITOR

class fifo_monitor extends uvm_monitor;

  `uvm_component_utils (fifo_monitor)

  virtual fifo_if #(`WIDTH, `DEPTH) vif;
  fifo_sequence_item                rx;

  // Analysis port - used to send transactions to scoreboard and coverage
  uvm_analysis_port #(fifo_sequence_item) analysis_port;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // CONSTRUCTOR

  function new (string name = "fifo_monitor", uvm_component parent = null);
    super.new (name, parent);
    analysis_port = new ("analysis_port", this);
  endfunction

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // BUILD PHASE

  function void build_phase (uvm_phase phase);
    super.build_phase (phase);
    if (!uvm_config_db #(virtual fifo_if #(`WIDTH, `DEPTH))::get (this, "", "vif", vif))
      `uvm_fatal ("VIF_FAIL", "VIRTUAL INTERFACE NOT FOUND");
  endfunction

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // RUN PHASE

  task run_phase (uvm_phase phase);
    forever begin
      @(posedge vif.clk);
      rx         = fifo_sequence_item::type_id::create ("rx");
      rx.rst_n   = vif.rst_n;
      rx.wr_en   = vif.wr_en;
      rx.rd_en   = vif.rd_en;
      rx.wr_data = vif.wr_data;
      rx.rd_data = vif.rd_data;
      rx.full    = vif.full;
      rx.empty   = vif.empty;
      rx.wr_ptr  = vif.wr_ptr;   // Only for coverage purposes
      rx.rd_ptr  = vif.rd_ptr;   // Only for coverage purposes
      analysis_port.write (rx);  // Send transaction to scoreboard and coverage
    end
  endtask

endclass




////////////////////////////////////////////////////////////////////////////////////////////////////
// AGENT

class fifo_agent extends uvm_agent;

  `uvm_component_utils (fifo_agent)

  // Three components created by agent
  fifo_driver    driver;
  fifo_monitor   monitor;
  fifo_sequencer sequencer;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // CONSTRUCTOR

  function new (string name = "fifo_agent", uvm_component parent = null);
    super.new (name, parent);
  endfunction

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // BUILD PHASE

  function void build_phase (uvm_phase phase);
    super.build_phase (phase);
    driver    = fifo_driver   ::type_id::create ("driver",    this);
    monitor   = fifo_monitor  ::type_id::create ("monitor",   this);
    sequencer = fifo_sequencer::type_id::create ("sequencer", this);
  endfunction

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // CONNECT PHASE

  function void connect_phase (uvm_phase phase);
    super.connect_phase (phase);
    driver.seq_item_port.connect (sequencer.seq_item_export);  // Connect driver to sequencer
  endfunction

endclass




////////////////////////////////////////////////////////////////////////////////////////////////////
// SCOREBOARD
//
// Due to timing, monitor samples new DUT inputs along with previous DUT outputs
// To handle this mismatch, scoreboard uses extra variables to store DUT inputs to match them with
// correct DUT outputs later

class fifo_scoreboard extends uvm_scoreboard;

  `uvm_component_utils (fifo_scoreboard)

  // Reference queue and variables used to store expected outputs
  bit [`WIDTH-1:0] ref_q [$];
  bit [`WIDTH-1:0] ref_rd_data;
  bit              ref_full;
  bit              ref_empty;

  // Variables used to store DUT inputs to match them with correct DUT outputs later
  bit              prev_valid;
  bit              prev_rst_n;
  bit              prev_wr_en;
  bit              prev_rd_en;
  bit [`WIDTH-1:0] prev_wr_data;

  // Variables used to store correct DUT signals for evaluation
  bit              final_rst_n;
  bit              final_wr_en;
  bit              final_rd_en;
  bit [`WIDTH-1:0] final_wr_data; 
  bit [`WIDTH-1:0] final_rd_data;
  bit              final_full;
  bit              final_empty;

  // Variables used to calculate test score
  int total   = 0;
  int correct = 0;

  // Analysis port - used to receive transactions from monitor
  uvm_analysis_imp #(fifo_sequence_item, fifo_scoreboard) analysis_imp;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // CONSTRUCTOR

  function new (string name = "fifo_scoreboard", uvm_component parent = null);
    super.new (name, parent);
    analysis_imp = new ("analysis_imp", this);
  endfunction

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // VERIFICATION WITH REFERENCE MODEL

  function void write (fifo_sequence_item t);

    // Use previous inputs if they exist
    if (prev_valid) begin
      final_rst_n   = prev_rst_n;
      final_wr_en   = prev_wr_en;
      final_rd_en   = prev_rd_en;
      final_wr_data = prev_wr_data;

      // Reset - delete reference queue content
      if (!final_rst_n) begin
        ref_q.delete ();
        ref_rd_data = 0;
      end

      // Write - push wr_data to back of reference queue
      if (final_rst_n && final_wr_en && !ref_full)
        ref_q.push_back (final_wr_data);

      // Read - pop front element of reference queue
      if (final_rst_n && final_rd_en && !ref_empty)
        ref_rd_data = ref_q.pop_front ();

      // Reference status flags - check size of reference queue
      ref_full  = (ref_q.size () == `DEPTH);
      ref_empty = (ref_q.size () == 0);
    end

    // Store current inputs for next cycle and use current outputs
    prev_valid    = 1;
    prev_rst_n    = t.rst_n;
    prev_wr_en    = t.wr_en;
    prev_rd_en    = t.rd_en;
    prev_wr_data  = t.wr_data;
    final_rd_data = t.rd_data;
    final_full    = t.full;
    final_empty   = t.empty;

    // Check actual output against reference output
    if (final_rd_data == ref_rd_data && final_full == ref_full && final_empty == ref_empty) begin
      `uvm_info (
        "PASS",
        $sformatf (
          "TRANSACTION #%0d CORRECT",
          (total > 0) ? total : 'x
        ),
        UVM_NONE
      );
      correct++;
      total++;
    end else begin
      `uvm_error (
        "FAIL",
        $sformatf (
          "TRANSACTION #%0d INCORRECT | ACTIVITY: rst_n = %0d, wr_en = %0d, rd_en = %0d, wr_data = %0h | EXPECTED: rd_data = %0h, full = %0d, empty = %0d | ACTUAL: rd_data = %0h, full = %0d, empty = %0d\n",
          (total > 0) ? total : 'x,
          final_rst_n,
          final_wr_en,
          final_rd_en,
          final_wr_data,
          ref_rd_data,
          ref_full,
          ref_empty,
          final_rd_data,
          final_full,
          final_empty
        )
      );
      total++;
    end

  endfunction

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // REPORT PHASE

  function void report_phase (uvm_phase phase);
    super.report_phase (phase);
    `uvm_info ("SCB",            "================================================",                                                                   UVM_NONE);
    `uvm_info ("SCB",            "SCOREBOARD REPORT",                                                                                                  UVM_NONE);
    `uvm_info ("SCB",            "================================================",                                                                   UVM_NONE);
    `uvm_info ("SCB", $sformatf ("TOTAL NUMBER OF TRANSACTIONS EVALUATED | %0d",     total - 1),                                                       UVM_NONE);
    `uvm_info ("SCB", $sformatf ("TOTAL NUMBER OF CORRECT TRANSACTIONS   | %0d",     correct - 1),                                                     UVM_NONE);
    `uvm_info ("SCB", $sformatf ("OVERALL TEST SCORE                     | %6.2f%%", (total - 1 > 0.0) ? ((correct - 1) * 100.0 / (total - 1)) : 0.0), UVM_NONE);
  endfunction

endclass




////////////////////////////////////////////////////////////////////////////////////////////////////
// COVERAGE
//
// Following corner cases are covered:
// - Reset when FIFO is full
// - Reset when FIFO is empty
// - Write when FIFO is full
// - Write when FIFO is empty
// - Read when FIFO is full
// - Read when FIFO is empty
// - Write last element to make FIFO full
// - Read last element to make FIFO empty
// - Write and read simultaneously when FIFO is full
// - Write and read simultaneously when FIFO is empty
// - Reset, write, and read simultaneously
// - Write pointer wraparound
// - Read pointer wraparound
// - Illegal state (both full and empty)

class fifo_coverage extends uvm_subscriber #(fifo_sequence_item);

  `uvm_component_utils (fifo_coverage)

  fifo_sequence_item rx;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // COVERGROUP FOR CORNER CASES

  covergroup corner_case_cg;
    reset_when_full_cp      : coverpoint {rx.rst_n, rx.wr_en, rx.rd_en, rx.full, rx.empty} {
      wildcard bins reset_when_full       = (5'b0??10 => 5'b???01);
    }
    reset_when_empty_cp     : coverpoint {rx.rst_n, rx.wr_en, rx.rd_en, rx.full, rx.empty} {
      wildcard bins reset_when_empty      = (5'b0??01 => 5'b???01);
    }
    write_when_full_cp      : coverpoint {rx.rst_n, rx.wr_en, rx.rd_en, rx.full, rx.empty} {
      wildcard bins write_when_full       = (5'b11010 => 5'b???10);
    }
    write_when_empty_cp     : coverpoint {rx.rst_n, rx.wr_en, rx.rd_en, rx.full, rx.empty} {
      wildcard bins write_when_empty      = (5'b11001 => 5'b???00);
    }
    read_when_full_cp       : coverpoint {rx.rst_n, rx.wr_en, rx.rd_en, rx.full, rx.empty} {
      wildcard bins read_when_full        = (5'b10110 => 5'b???00);
    }
    read_when_empty_cp      : coverpoint {rx.rst_n, rx.wr_en, rx.rd_en, rx.full, rx.empty} {
      wildcard bins read_when_empty       = (5'b10101 => 5'b???01);
    }
    write_until_full_cp     : coverpoint {rx.rst_n, rx.wr_en, rx.rd_en, rx.full, rx.empty} {
      wildcard bins write_until_full      = (5'b11000 => 5'b???10);
    }
    read_until_empty_cp     : coverpoint {rx.rst_n, rx.wr_en, rx.rd_en, rx.full, rx.empty} {
      wildcard bins read_until_empty      = (5'b10100 => 5'b???01);
    }
    write_read_when_full_cp : coverpoint {rx.rst_n, rx.wr_en, rx.rd_en, rx.full, rx.empty} {
      wildcard bins write_read_when_full  = (5'b11110 => 5'b???00);
    }
    write_read_when_empty_cp: coverpoint {rx.rst_n, rx.wr_en, rx.rd_en, rx.full, rx.empty} {
      wildcard bins write_read_when_empty = (5'b11101 => 5'b???00);
    }
    reset_write_read_cp     : coverpoint {rx.rst_n, rx.wr_en, rx.rd_en, rx.full, rx.empty} {
      wildcard bins reset_write_read      = (5'b011?? => 5'b???01);
    }
    wr_ptr_wraparound_cp    : coverpoint {rx.wr_ptr} {
      bins wr_ptr_wraparound              = (`DEPTH - 1 => 0);
    }
    rd_ptr_wraparound_cp    : coverpoint {rx.rd_ptr} {
      bins rd_ptr_wraparound              = (`DEPTH - 1 => 0);
    }
    illegal_state_cp        : coverpoint {rx.full, rx.empty} {
      illegal_bins illegal_state          = {2'b11};
    }
  endgroup

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // CONSTRUCTOR

  function new (string name = "fifo_coverage", uvm_component parent = null);
    super.new (name, parent);
    corner_case_cg = new ();
    corner_case_cg.set_inst_name ({get_full_name (), ".corner_case_cg"});
  endfunction

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // TRANSACTION SAMPLING

  function void write (fifo_sequence_item t);
    rx = t;
    corner_case_cg.sample ();
  endfunction

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // REPORT PHASE

  function void report_phase (uvm_phase phase);
    super.report_phase (phase);
    `uvm_info ("COV",            "==========================================================",                                                           UVM_NONE);
    `uvm_info ("COV",            "COVERAGE REPORT",                                                                                                      UVM_NONE);
    `uvm_info ("COV",            "==========================================================",                                                           UVM_NONE);
    `uvm_info ("COV", $sformatf ("RESET WHEN FIFO IS FULL                          | %6.2f%%", corner_case_cg.reset_when_full_cp.      get_coverage ()), UVM_NONE);
    `uvm_info ("COV", $sformatf ("RESET WHEN FIFO IS EMPTY                         | %6.2f%%", corner_case_cg.reset_when_empty_cp.     get_coverage ()), UVM_NONE);
    `uvm_info ("COV", $sformatf ("WRITE WHEN FIFO IS FULL                          | %6.2f%%", corner_case_cg.write_when_full_cp.      get_coverage ()), UVM_NONE);
    `uvm_info ("COV", $sformatf ("WRITE WHEN FIFO IS EMPTY                         | %6.2f%%", corner_case_cg.write_when_empty_cp.     get_coverage ()), UVM_NONE);
    `uvm_info ("COV", $sformatf ("READ WHEN FIFO IS FULL                           | %6.2f%%", corner_case_cg.read_when_full_cp.       get_coverage ()), UVM_NONE);
    `uvm_info ("COV", $sformatf ("READ WHEN FIFO IS EMPTY                          | %6.2f%%", corner_case_cg.read_when_empty_cp.      get_coverage ()), UVM_NONE);
    `uvm_info ("COV", $sformatf ("WRITE LAST ELEMENT TO MAKE FIFO FULL             | %6.2f%%", corner_case_cg.write_until_full_cp.     get_coverage ()), UVM_NONE);
    `uvm_info ("COV", $sformatf ("READ LAST ELEMENT TO MAKE FIFO EMPTY             | %6.2f%%", corner_case_cg.read_until_empty_cp.     get_coverage ()), UVM_NONE);
    `uvm_info ("COV", $sformatf ("WRITE AND READ SIMULTANEOUSLY WHEN FIFO IS FULL  | %6.2f%%", corner_case_cg.write_read_when_full_cp. get_coverage ()), UVM_NONE);
    `uvm_info ("COV", $sformatf ("WRITE AND READ SIMULTANEOUSLY WHEN FIFO IS EMPTY | %6.2f%%", corner_case_cg.write_read_when_empty_cp.get_coverage ()), UVM_NONE);
    `uvm_info ("COV", $sformatf ("RESET, WRITE, AND READ SIMULTANEOUSLY            | %6.2f%%", corner_case_cg.reset_write_read_cp.     get_coverage ()), UVM_NONE);
    `uvm_info ("COV", $sformatf ("WRITE POINTER WRAPAROUND                         | %6.2f%%", corner_case_cg.wr_ptr_wraparound_cp.    get_coverage ()), UVM_NONE);
    `uvm_info ("COV", $sformatf ("READ POINTER WRAPAROUND                          | %6.2f%%", corner_case_cg.rd_ptr_wraparound_cp.    get_coverage ()), UVM_NONE);

  endfunction

endclass




// -------------------------------------------------------------------------------------------------
// ENVIRONMENT
// -------------------------------------------------------------------------------------------------

class fifo_env extends uvm_env;

  `uvm_component_utils(fifo_env)

  // Three components created by environment
  fifo_agent      agent;
  fifo_scoreboard scoreboard;
  fifo_coverage   cov;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // CONSTRUCTOR

  function new (string name = "fifo_env", uvm_component parent = null);
    super.new (name, parent);
  endfunction

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // BUILD PHASE

  function void build_phase (uvm_phase phase);
    super.build_phase (phase);
    agent      = fifo_agent     ::type_id::create ("agent",      this);
    scoreboard = fifo_scoreboard::type_id::create ("scoreboard", this);
    cov        = fifo_coverage  ::type_id::create ("cov",        this);
  endfunction

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // CONNECT PHASE

  function void connect_phase (uvm_phase phase);
    super.connect_phase (phase);
    agent.monitor.analysis_port.connect (scoreboard.analysis_imp);  // Connect monitor to scoreboard
    agent.monitor.analysis_port.connect (cov.analysis_export);      // Connect monitor to coverage
  endfunction

endclass




// -------------------------------------------------------------------------------------------------
// TEST
// -------------------------------------------------------------------------------------------------

class fifo_test extends uvm_test;

  `uvm_component_utils (fifo_test)

  // Two components/objects created by test
  fifo_env      env;
  fifo_sequence seq;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // CONSTRUCTOR

  function new (string name = "fifo_test", uvm_component parent = null);
    super.new (name, parent);
  endfunction

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // BUILD PHASE

  function void build_phase (uvm_phase phase);
    super.build_phase (phase);
    env = fifo_env     ::type_id::create ("env", this);
    seq = fifo_sequence::type_id::create ("seq");
  endfunction

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // RUN PHASE

  task run_phase (uvm_phase phase);
    phase.raise_objection (this);                  // Start test
    seq.start (env.agent.sequencer);               // Call sequence to start task
    phase.phase_done.set_drain_time (this, 10ns);  // Wait for scoreboard to verify all transactions
    phase.drop_objection (this);                   // End test
  endtask

endclass




// -------------------------------------------------------------------------------------------------
// TESTBENCH TOP
// -------------------------------------------------------------------------------------------------

module fifo_tb_top ();

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // INSTANTIATE INTERFACE

  fifo_if #(.WIDTH (`WIDTH), .DEPTH (`DEPTH)) vif ();

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // INSTANTIATE DUT

  fifo #(
    .WIDTH (`WIDTH),
    .DEPTH (`DEPTH)
  ) dut (
    .clk     (vif.clk),
    .rst_n   (vif.rst_n),
    .wr_en   (vif.wr_en),
    .rd_en   (vif.rd_en),
    .wr_data (vif.wr_data),
    .rd_data (vif.rd_data),
    .full    (vif.full),
    .empty   (vif.empty)
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // CONNECT DUT INTERNAL SIGNALS

  assign vif.wr_ptr = dut.wr_ptr;
  assign vif.rd_ptr = dut.rd_ptr;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // GENERATE CLOCK

  always #5 vif.clk = ~vif.clk;
  initial   vif.clk = 0;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // DUMP WAVEFORM

  initial begin
    $dumpfile ("dump.vcd");
    $dumpvars (0, fifo_tb_top);
  end

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // RUN TEST

  initial begin
    vif.rst_n = 0;
    uvm_config_db #(virtual fifo_if #(`WIDTH, `DEPTH))::set (null, "*", "vif", vif);
    run_test ("fifo_test");
  end

endmodule
