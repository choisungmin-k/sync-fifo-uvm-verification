////////////////////////////////////////////////////////////////////////////////////////////////////
// SCOREBOARD
//
// Since the monitor observes all DUT signals at the same time, the current DUT inputs correspond to
// the previous DUT outputs. To handle this mismatch, the scoreboard creates a "delay" by using the
// previous DUT inputs while storing the current DUT inputs to be used in the next cycle.

class fifo_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(fifo_scoreboard)

  uvm_analysis_imp#(fifo_sequence_item, fifo_scoreboard) port;

  // Expected DUT outputs 
  bit [WIDTH-1:0] ref_mem[$];
  bit [WIDTH-1:0] ref_rd_data;
  bit ref_full;
  bit ref_empty;

  // Previous DUT inputs
  bit prev_valid;
  bit prev_rst_n;
  bit prev_wr_en;
  bit prev_rd_en;
  bit [WIDTH-1:0] prev_wr_data;

  // Final DUT signals
  bit final_rst_n;
  bit final_wr_en;
  bit final_rd_en;
  bit [WIDTH-1:0] final_wr_data;
  bit [WIDTH-1:0] final_rd_data;
  bit final_full;
  bit final_empty;

  // Correctness check variables
  int total;
  int correct;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // CONSTRUCTOR

  function new(string name = "fifo_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    port = new("port", this);
  endfunction

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // REFERENCE MODEL

  function void write(fifo_sequence_item t);

    if (prev_valid) begin

      // Use previous DUT inputs
      final_rst_n = prev_rst_n;
      final_wr_en = prev_wr_en;
      final_rd_en = prev_rd_en;
      final_wr_data = prev_wr_data;

      // Reset - clear queue and set rd_data to 0
      // Write - push data to back of queue
      // Read - pop data from front of queue and read value
      if (!final_rst_n) begin
        ref_mem.delete();
        ref_rd_data = 0;
      end else begin
        if (final_wr_en && !ref_full) ref_mem.push_back(final_wr_data);
        if (final_rd_en && !ref_empty) ref_rd_data = ref_mem.pop_front();
      end

      // Update status flags
      ref_full = (ref_mem.size() == DEPTH);
      ref_empty = (ref_mem.size() == 0);

    end

    // Store current DUT inputs and use current DUT outputs
    prev_valid = 1;
    prev_rst_n = t.rst_n;
    prev_wr_en = t.wr_en;
    prev_rd_en = t.rd_en;
    prev_wr_data = t.wr_data;
    final_rd_data = t.rd_data;
    final_full = t.full;
    final_empty = t.empty;

    // Check correctness
    if ((final_rd_data == ref_rd_data) && (final_full == ref_full) && (final_empty == ref_empty)) begin
      `uvm_info("SCB_PASS", $sformatf("Transaction #%0d correct", total), UVM_NONE)
      total++;
      correct++;
    end else begin
      `uvm_error("SCB_FAIL", $sformatf("Transaction #%0d incorrect | Expected: rd_data=%0h, full=%0d, empty=%0d | Actual: rd_data=%0h, full=%0d, empty=%0d", (total > 0) ? total : 'x, ref_rd_data, ref_full, ref_empty, final_rd_data, final_full, final_empty))
      total++;
    end

  endfunction

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // REPORT PHASE

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
      `uvm_info("SCB", "================================================", UVM_NONE)
      `uvm_info("SCB", "SCOREBOARD REPORT", UVM_NONE)
      `uvm_info("SCB", "================================================", UVM_NONE)
      `uvm_info("SCB", $sformatf("Total number of transactions evaluated | %0d", total - 1), UVM_NONE)
      `uvm_info("SCB", $sformatf("Total number of correct transactions   | %0d", correct - 1), UVM_NONE)
      `uvm_info("SCB", $sformatf("Total number of incorrect transactions | %0d", total - correct), UVM_NONE)
      `uvm_info("SCB", $sformatf("Overall test score                     | %0.2f%%", (total > 1) ? ((correct - 1) * 100.0) / (total - 1) : 0.0), UVM_NONE)
  endfunction

endclass
