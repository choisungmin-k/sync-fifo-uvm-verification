////////////////////////////////////////////////////////////////////////////////////////////////////
// COVERAGE
//
// The following corner-case scenarios are covered:
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
//
// Full and empty flags should never be high at the same time. This is an illegal state, which is
// also covered.

class fifo_coverage extends uvm_subscriber#(fifo_sequence_item);

  `uvm_component_utils(fifo_coverage)

  fifo_sequence_item rx;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // COVERGROUP FOR CORNER-CASE SCENARIOS

  covergroup corner_case_cg;
    reset_when_full_cp: coverpoint {rx.rst_n, rx.wr_en, rx.rd_en, rx.full, rx.empty} {
      wildcard bins reset_when_full = (5'b0??10 => 5'b???01);
    }
    reset_when_empty_cp: coverpoint {rx.rst_n, rx.wr_en, rx.rd_en, rx.full, rx.empty} {
      wildcard bins reset_when_empty = (5'b0??01 => 5'b???01);
    }
    write_when_full_cp: coverpoint {rx.rst_n, rx.wr_en, rx.rd_en, rx.full, rx.empty} {
      wildcard bins write_when_full = (5'b11010 => 5'b???10);
    }
    write_when_empty_cp: coverpoint {rx.rst_n, rx.wr_en, rx.rd_en, rx.full, rx.empty} {
      wildcard bins write_when_empty = (5'b11001 => 5'b???00);
    }
    read_when_full_cp: coverpoint {rx.rst_n, rx.wr_en, rx.rd_en, rx.full, rx.empty} {
      wildcard bins read_when_full = (5'b10110 => 5'b???00);
    }
    read_when_empty_cp: coverpoint {rx.rst_n, rx.wr_en, rx.rd_en, rx.full, rx.empty} {
      wildcard bins read_when_empty = (5'b10101 => 5'b???01);
    }
    write_last_element_cp: coverpoint {rx.rst_n, rx.wr_en, rx.rd_en, rx.full, rx.empty} {
      wildcard bins write_last_element = (5'b11000 => 5'b???10);
    }
    read_last_element_cp: coverpoint {rx.rst_n, rx.wr_en, rx.rd_en, rx.full, rx.empty} {
      wildcard bins read_last_element = (5'b10100 => 5'b???01);
    }
    write_read_when_full_cp: coverpoint {rx.rst_n, rx.wr_en, rx.rd_en, rx.full, rx.empty} {
      wildcard bins write_read_when_full = (5'b11110 => 5'b???00);
    }
    write_read_when_empty_cp: coverpoint {rx.rst_n, rx.wr_en, rx.rd_en, rx.full, rx.empty} {
      wildcard bins write_read_when_empty = (5'b11101 => 5'b???00);
    }
    reset_write_read_cp: coverpoint {rx.rst_n, rx.wr_en, rx.rd_en, rx.full, rx.empty} {
      wildcard bins reset_write_read = (5'b011?? => 5'b???01);
    }
    wr_ptr_wraparound_cp: coverpoint rx.wr_ptr {
      bins wr_ptr_wraparound = (DEPTH - 1 => 0);
    }
    rd_ptr_wraparound_cp: coverpoint rx.rd_ptr {
      bins rd_ptr_wraparound = (DEPTH - 1 => 0);
    }
    illegal_state_cp: coverpoint {rx.full, rx.empty} {
      illegal_bins illegal_state = {2'b11};
    }
  endgroup

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // CONSTRUCTOR

  function new(string name = "fifo_coverage", uvm_component parent = null);
    super.new(name, parent);
    corner_case_cg = new();
    corner_case_cg.set_inst_name({get_full_name(), ".corner_case_cg"});
  endfunction

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // TRANSACTION SAMPLING

  function void write(fifo_sequence_item t);
    rx = t;
    corner_case_cg.sample();
  endfunction

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // REPORT PHASE

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("COV", "==========================================================", UVM_NONE)
    `uvm_info("COV", "COVERAGE REPORT", UVM_NONE)
    `uvm_info("COV", "==========================================================", UVM_NONE)
    `uvm_info("COV", $sformatf("Reset when FIFO is full                          | %6.2f%%", corner_case_cg.reset_when_full_cp.get_coverage()), UVM_NONE)
    `uvm_info("COV", $sformatf("Reset when FIFO is empty                         | %6.2f%%", corner_case_cg.reset_when_empty_cp.get_coverage()), UVM_NONE)
    `uvm_info("COV", $sformatf("Write when FIFO is full                          | %6.2f%%", corner_case_cg.write_when_full_cp.get_coverage()), UVM_NONE)
    `uvm_info("COV", $sformatf("Write when FIFO is empty                         | %6.2f%%", corner_case_cg.write_when_empty_cp.get_coverage()), UVM_NONE)
    `uvm_info("COV", $sformatf("Read when FIFO is full                           | %6.2f%%", corner_case_cg.read_when_full_cp.get_coverage()), UVM_NONE)
    `uvm_info("COV", $sformatf("Read when FIFO is empty                          | %6.2f%%", corner_case_cg.read_when_empty_cp.get_coverage()), UVM_NONE)
    `uvm_info("COV", $sformatf("Write last element to make FIFO full             | %6.2f%%", corner_case_cg.write_last_element_cp.get_coverage()), UVM_NONE)
    `uvm_info("COV", $sformatf("Read last element to make FIFO empty             | %6.2f%%", corner_case_cg.read_last_element_cp.get_coverage()), UVM_NONE)
    `uvm_info("COV", $sformatf("Write and read simultaneously when FIFO is full  | %6.2f%%", corner_case_cg.write_read_when_full_cp.get_coverage()), UVM_NONE)
    `uvm_info("COV", $sformatf("Write and read simultaneously when FIFO is empty | %6.2f%%", corner_case_cg.write_read_when_empty_cp.get_coverage()), UVM_NONE)
    `uvm_info("COV", $sformatf("Reset, write, and read simultaneously            | %6.2f%%", corner_case_cg.reset_write_read_cp.get_coverage()), UVM_NONE)
    `uvm_info("COV", $sformatf("Write pointer wraparound                         | %6.2f%%", corner_case_cg.wr_ptr_wraparound_cp.get_coverage()), UVM_NONE)
    `uvm_info("COV", $sformatf("Read pointer wraparound                          | %6.2f%%", corner_case_cg.rd_ptr_wraparound_cp.get_coverage()), UVM_NONE)
  endfunction

endclass
