////////////////////////////////////////////////////////////////////////////////////////////////////
// ENVIRONMENT

class fifo_env extends uvm_env;

  `uvm_component_utils(fifo_env)

  fifo_agent agt;
  fifo_scoreboard scb;
  fifo_coverage cov;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // CONSTRUCTOR

  function new(string name = "fifo_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // BUILD PHASE

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agt = fifo_agent::type_id::create("agt", this);
    scb = fifo_scoreboard::type_id::create("scb", this);
    cov = fifo_coverage::type_id::create("cov", this);
  endfunction

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // CONNECT PHASE

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agt.mon.port.connect(scb.port);             // Connect monitor to scoreboard
    agt.mon.port.connect(cov.analysis_export);  // Connect monitor to coverage
  endfunction

endclass
