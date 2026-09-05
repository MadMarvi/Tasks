class user_agent extends uvm_agent;
   `uvm_component_utils(user_agent)
 
   uvm_analysis_port#(user_transaction) ap;
 
   user_sequencer seqr;
   user_driver    drvr;
   user_monitor   mon;
 
   function new(string name, uvm_component parent);
      super.new(name, parent);
   endfunction: new
 
   function void build_phase(uvm_phase phase);
      super.build_phase(phase);
 
      ap = new(.name("ap"), .parent(this));
      seqr = user_sequencer::type_id::create(.name("seqr"), .parent(this));
      drvr = user_driver::type_id::create(.name("drvr"), .parent(this));
      mon  = user_monitor::type_id::create(.name("mon"), .parent(this));
   endfunction: build_phase
 
   function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      drvr.seq_item_port.connect(seqr.seq_item_export);
      mon.ap.connect(ap);
   endfunction: connect_phase
endclass: user_agent
