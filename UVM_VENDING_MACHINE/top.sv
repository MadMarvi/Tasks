`include "uvm_macros.svh"
import uvm_pkg::*;
import vending_pkg::*;

`timescale 1ns/1ps

module top;

   localparam NUM_ITEMS = 10;
   logic clk, rst_n;
   user_interface vif(clk,rst_n);
   vending_machine   dut( 
      .clk  (clk),          
      .rst_n(rst_n),

      .regs_data_in  (32'b0),
      .regs_data_out (),
      .regs_we       (1'b0),
      .regs_addr     (8'b0),

      .id_valid      (vif.id_valid),
      .client_id     (vif.client_id),
      .coin_in       (vif.coin_in),
      .currency_type (vif.currency_type),
      .coin_insert   (vif.coin_insert),
      .item_select   (vif.item_select),
      .confirm       (vif.confirm),

      .admin_mode    (1'b0),
      .admin_password(32'b0),

      .tamper_detect (1'b0),
      .jam_detect    (1'b0),
      .power_loss    (1'b0),

      .access_error  (),
      .item_out      (vif.item_out),
      .change_out    (vif.change_out),
      .no_change     (vif.no_change),
      .item_empty    (vif.item_empty),
      .client_points (vif.client_points),
      .alarm         ()
    );  
 
   // clock generation
   initial begin 
      clk = 0;
      #5ns ;
      forever #5ns clk =  ~clk;
   end

   initial begin
        rst_n = 0;
        #20ns;
        rst_n = 1;
    end


   initial begin
      uvm_resource_db#(virtual user_interface)::set
        (.scope("ifs"), .name("user_if"), .val(vif));
      run_test("user_test");
   end
endmodule: top
