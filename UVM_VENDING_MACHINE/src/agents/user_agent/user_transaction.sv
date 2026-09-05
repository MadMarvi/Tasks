class user_transaction extends uvm_sequence_item;
    localparam NUM_ITEMS = 10;
    localparam NUM_COINS = 3;
    
    // INPUT
    bit        id_valid;
    bit        confirm;
    bit [8:0]  client_id;
    bit [7:0]  item_select;
    bit [5:0]  coins[$];
    bit [1:0]  currency_type;  

    // OUTPUT
    bit        no_change;
    bit [31:0] change_out;
    bit [7:0]  client_points;
    bit [NUM_ITEMS-1:0]  item_out;
    bit [NUM_ITEMS-1:0]  item_empty;

    function new(string name = "user_transaction");
        super.new(name);
        coins = {};
        currency_type = 2'b00; 
    endfunction: new

    `uvm_object_utils_begin(user_transaction)
        `uvm_field_int(id_valid, UVM_ALL_ON)
        `uvm_field_int(confirm, UVM_ALL_ON)
        `uvm_field_int(client_id, UVM_ALL_ON)
        `uvm_field_queue_int(coins, UVM_ALL_ON)
        `uvm_field_int(currency_type, UVM_ALL_ON)
        `uvm_field_int(item_select, UVM_ALL_ON)
        `uvm_field_int(no_change, UVM_ALL_ON)
        `uvm_field_int(change_out, UVM_ALL_ON)
        `uvm_field_int(client_points, UVM_ALL_ON)
        `uvm_field_int(item_out, UVM_ALL_ON)
        `uvm_field_int(item_empty, UVM_ALL_ON)
    `uvm_object_utils_end

endclass: user_transaction
