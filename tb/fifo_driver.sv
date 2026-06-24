////////////////////////////////////////////////////////////////////////////////////////////////////
// DRIVER

class fifo_driver extends uvm_driver#(fifo_sequence_item);

  `uvm_component_utils(fifo_driver)

  virtual fifo_if#(WIDTH, DEPTH) vif;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // CONSTRUCTOR

  function new(string name = "fifo_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // BUILD PHASE

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual fifo_if#(WIDTH, DEPTH))::get(this, "", "vif", vif)) `uvm_fatal("VIF_FAIL", "Virtual interface not found")
  endfunction

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // RUN PHASE

  task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(req);  // Wait to receive transaction from sequencer
      drive_tx(req);                     // Drive transaction to DUT
      seq_item_port.item_done();         // Notify sequencer of completion
    end
  endtask

  task drive_tx(fifo_sequence_item tx);
    @(posedge vif.clk);
    vif.rst_n <= tx.rst_n;
    vif.wr_en <= tx.wr_en;
    vif.rd_en <= tx.rd_en;
    vif.wr_data <= tx.wr_data;
  endtask

endclass
