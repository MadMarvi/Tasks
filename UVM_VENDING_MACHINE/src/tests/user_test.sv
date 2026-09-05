class user_test extends uvm_test;
   `uvm_component_utils(user_test)

   vending_env env;

   function new(string name, uvm_component parent);
      super.new(name, parent);
   endfunction

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      env = vending_env::type_id::create("env", this);
   endfunction

   task run_phase(uvm_phase phase);
      coin_queue_sequence seq;

      phase.raise_objection(this);
      seq = coin_queue_sequence::type_id::create("seq");
      `uvm_info("user_test", "Starting coin_queue_sequence", UVM_LOW)
      seq.start(env.agent.seqr);
      
      phase.drop_objection(this);
   endtask

endclass
