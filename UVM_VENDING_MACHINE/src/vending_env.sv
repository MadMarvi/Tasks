class vending_env extends uvm_env;
   `uvm_component_utils(vending_env)
 
   user_agent         agent;
 
   function new(string name, uvm_component parent);
      super.new(name, parent);
   endfunction: new
 
   function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      agent = user_agent::type_id::create(.name("agent"), .parent(this));
    endfunction: build_phase

endclass: vending_env
