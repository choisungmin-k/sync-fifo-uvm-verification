////////////////////////////////////////////////////////////////////////////////////////////////////
// MONITOR

class fifo_monitor extends uvm_monitor;

  `uvm_component_utils(fifo_monitor)

  uvm_analysis_port#(fifo_sequence_item) port;
  virtual fifo_if#(WIDTH, DEPTH) vif;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // CONSTRUCTOR

  function new(string name = "fifo_monitor", uvm_component parent = null);
    super.new(name, parent);
    port = new("port", this);
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
    fifo_sequence_item rx;
    forever begin
      rx = fifo_sequence_item::type_id::create("rx");
      @(posedge vif.clk);
      rx.rst_n = vif.rst_n;
      rx.wr_en = vif.wr_en;
      rx.rd_en = vif.rd_en;
      rx.wr_data = vif.wr_data;
      rx.rd_data = vif.rd_data;
      rx.full = vif.full;
      rx.empty = vif.empty;
      rx.wr_ptr = vif.wr_ptr;  // To be used for coverage
      rx.rd_ptr = vif.rd_ptr;  // To be used for coverage
      port.write(rx);          // Send transaction to scoreboard and coverage
    end
  endtask

endclass
