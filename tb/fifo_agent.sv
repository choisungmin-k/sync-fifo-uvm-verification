////////////////////////////////////////////////////////////////////////////////////////////////////
// AGENT

class fifo_agent extends uvm_agent;

  `uvm_component_utils(fifo_agent)

  fifo_sequencer seqr;
  fifo_driver drv;
  fifo_monitor mon;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // CONSTRUCTOR

  function new(string name = "fifo_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // BUILD PHASE

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    seqr = fifo_sequencer::type_id::create("seqr", this);
    drv = fifo_driver::type_id::create("drv", this);
    mon = fifo_monitor::type_id::create("mon", this);
  endfunction

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // CONNECT PHASE

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(seqr.seq_item_export);  // Connect driver to sequencer
  endfunction

endclass
