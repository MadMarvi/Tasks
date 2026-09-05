`timescale 1ns/1ps

interface user_interface(
    input logic clk,
    input logic rst_n
);
    localparam NUM_ITEMS = 10;

    //INPUT
    logic                 id_valid;
    logic                 coin_insert;
    logic                 confirm;
    logic [8 : 0]         client_id;
    logic [5 : 0]         coin_in;
    logic [NUM_ITEMS-1:0] item_select;

    logic [1:0] currency_type;

    //OUTPUT
    logic                 no_change;
    logic [31: 0]         change_out;
    logic [7 : 0]         client_points;
    logic [NUM_ITEMS-1:0] item_out;
    logic [NUM_ITEMS-1:0] item_empty;

    //CLOCKING BLOCKS
    clocking master_cb @ (posedge clk);
        default input #1step output #1ns;
        output id_valid, coin_insert, confirm, client_id, coin_in, currency_type, item_select;
        input  no_change, change_out, client_points, item_out, item_empty;
    endclocking: master_cb

    clocking slave_cb @ (posedge clk);
        default input #1step output #1ns;
        input  id_valid, coin_insert, confirm, client_id, coin_in, currency_type, item_select;
        output no_change, change_out, client_points, item_out, item_empty;
    endclocking: slave_cb

    //MODPORTS
    modport master_mp(    
        input  item_out, change_out, no_change,
        input  item_empty, client_points,
        output id_valid, client_id, coin_in, currency_type, coin_insert,
        output confirm, item_select
    );

    modport slave_mp(
        input  id_valid, client_id, coin_in, currency_type, coin_insert,
        input  confirm, item_select,   
        output item_out, change_out, no_change,
        output item_empty, client_points
    );

    modport master_sync_mp(clocking master_cb);
    modport slave_sync_mp(clocking slave_cb);

    
endinterface: user_interface
