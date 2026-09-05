class user_driver extends uvm_driver#(user_transaction);
   `uvm_component_utils(user_driver)
 
   virtual user_interface vif;
 
   function new(string name, uvm_component parent);
      super.new(name, parent);
   endfunction: new
 
   function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      void'(uvm_resource_db#(virtual user_interface)::read_by_name
            (.scope("ifs"), .name("user_if"), .val(vif)));
   endfunction: build_phase
 
   task run_phase(uvm_phase phase);
      user_transaction tx;
 
      forever begin
         seq_item_port.get_next_item(tx);

        //Авторизация клинета
         @(vif.master_cb);

         vif.master_cb.id_valid      <= tx.id_valid;
         vif.master_cb.client_id     <= tx.client_id;

         @(vif.master_cb);
         vif.master_cb.id_valid      <= 0;

        //Внесение монеток
         @(vif.master_cb);
         vif.master_cb.coin_insert   <= 1;

         foreach (tx.coins[i]) begin
            @(vif.master_cb);
            vif.master_cb.currency_type <= tx.currency_type;
            vif.master_cb.coin_in       <= tx.coins[i];
         end

         @(vif.master_cb);
         vif.master_cb.coin_in      <= 0;
         vif.master_cb.coin_insert  <= 0;

        //Выбор товара
         @(vif.master_cb);
         vif.master_cb.item_select <= tx.item_select;

         @(vif.master_cb);
         vif.master_cb.confirm <= tx.confirm;
         vif.master_cb.item_select <= 0;

         @(vif.master_cb);
         vif.master_cb.confirm <= 0;

         seq_item_port.item_done();
      end
   endtask: run_phase
endclass: user_driver
