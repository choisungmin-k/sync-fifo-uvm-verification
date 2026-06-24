////////////////////////////////////////////////////////////////////////////////////////////////////
// TEST

class fifo_test extends uvm_test;

  `uvm_component_utils(fifo_test)

  fifo_sequence seq;
  fifo_env env;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // CONSTRUCTOR

  function new(string name = "fifo_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // BUILD PHASE

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    seq = fifo_sequence::type_id::create("seq");
    env = fifo_env::type_id::create("env", this);
  endfunction

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // RUN PHASE

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);                  // Start test
    seq.start(env.agt.seqr);                      // Call sequence to start
    phase.phase_done.set_drain_time(this, 10ns);  // Wait for scoreboard to verify all transactions
    phase.drop_objection(this);                   // End test
  endtask

endclass
