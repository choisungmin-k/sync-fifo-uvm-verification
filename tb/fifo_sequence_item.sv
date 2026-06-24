////////////////////////////////////////////////////////////////////////////////////////////////////
// SEQUENCE ITEM
//
// Two constraints are applied to the DUT inputs to get the desired DUT behavior:
// - Resets will occur 3% of the time to allow the DUT to operate mostly uninterrupted.
// - The DUT will be idle 10% of the time, only read 10% of the time, only write 40% of the time,
//   and do both 40% of the time. This is to allow the DUT to fill up more easily and to ensure that
//   the simultaneous operation is tested more often.

class fifo_sequence_item extends uvm_sequence_item;

  `uvm_object_utils(fifo_sequence_item)

  // DUT inputs - to be randomized
  rand bit rst_n;
  rand bit wr_en;
  rand bit rd_en;
  rand bit [WIDTH-1:0] wr_data;

  // DUT outputs - to be observed
  bit [WIDTH-1:0] rd_data;
  bit full;
  bit empty;

  // Write and read pointers - to be used for coverage
  bit [$clog2(DEPTH)-1:0] wr_ptr;
  bit [$clog2(DEPTH)-1:0] rd_ptr;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // CONSTRUCTOR

  function new(string name = "fifo_sequence_item");
    super.new(name);
  endfunction

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // CONSTRAINTS

  constraint reset {
    rst_n dist {
      0 := 3,
      1 := 97
    };
  }

  constraint enable {
    {wr_en, rd_en} dist {
      2'b00 := 10,  // Idle
      2'b01 := 10,  // Read only
      2'b10 := 40,  // Write only
      2'b11 := 40   // Simultaneous write-read
    };
  }

endclass
