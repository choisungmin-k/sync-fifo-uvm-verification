////////////////////////////////////////////////////////////////////////////////////////////////////
// SEQUENCE
//
// The current test size is 2,000. This can be changed in fifo_tb_pkg.sv.

class fifo_sequence extends uvm_sequence#(fifo_sequence_item);

  `uvm_object_utils(fifo_sequence)

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // CONSTRUCTOR

  function new(string name = "fifo_sequence");
    super.new(name);
  endfunction

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // MAIN TASK

  task body();
    fifo_sequence_item tx;
    for (int i = 0; i < TEST_SIZE; i++) begin
      tx = fifo_sequence_item::type_id::create("tx");
      start_item(tx);   // Wait for grant from sequencer
      if (!tx.randomize()) `uvm_fatal("RAND_FAIL", "Randomization failed")
      `uvm_info("SEQ", $sformatf("Transaction %0d created: rst_n=%0d, wr_en=%0d, rd_en=%0d, wr_data=%0h", i + 1, tx.rst_n, tx.wr_en, tx.rd_en, tx.wr_data), UVM_NONE)
      finish_item(tx);  // Send transaction to driver and wait for completion
    end
  endtask

endclass
