package vending_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "agents/user_agent/user_transaction.sv"
    `include "agents/user_agent/user_sequencer.sv"
    `include "agents/user_agent/user_driver.sv"
    `include "agents/user_agent/user_monitor.sv"
    `include "agents/user_agent/user_agent.sv"
    `include "agents/user_agent/coin_queue_sequence.sv"
    `include "vending_env.sv"
    `include "tests/user_test.sv"

endpackage: vending_pkg
