class user_monitor extends uvm_monitor;
   `uvm_component_utils(user_monitor)
 
   uvm_analysis_port#(user_transaction) ap;
 
   virtual user_interface vif;
 
   function new(string name, uvm_component parent);
      super.new(name, parent);
   endfunction: new
 
   function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      void'(uvm_resource_db#(virtual user_interface)::read_by_name
           (.scope("ifs"), .name("user_if"), .val(vif)));
      ap = new(.name("ap"), .parent(this));
   endfunction: build_phase
 
   task run_phase(uvm_phase phase);
      user_transaction tx;
      @(vif.slave_cb);
      while (vif.rst_n !== 1) begin
            @(vif.slave_cb);
        end


      forever begin
         @vif.slave_cb;

      //СОЗДАНИЕ ТРАНЗАКЦИИ ТОЛЬКО ПРИ ID_VALID = 1
         while(vif.slave_cb.id_valid!==1) begin
            @vif.slave_cb;
         end

         tx = user_transaction::type_id::create(.name("tx"), .contxt(get_full_name()));

         tx.id_valid  = vif.slave_cb.id_valid;
         tx.client_id = vif.slave_cb.client_id;

      //НАЧАЛО ВСТАВКИ МОНЕТ
         tx.coins = {};
         @(vif.slave_cb);
         while (vif.slave_cb.coin_insert !== 1) begin
            @(vif.slave_cb);
         end

         `uvm_info(get_type_name(), "COINS INSERTION", UVM_LOW)

      //ВЫВОД ВСТАВЛЕННЫХ МОНЕТ
         while (vif.slave_cb.coin_insert == 1) begin
                if (vif.slave_cb.coin_in != 0) begin
                    tx.coins.push_back(vif.slave_cb.coin_in);
                    tx.currency_type = vif.slave_cb.currency_type;
                end
                @(vif.slave_cb);
            end

      //ВЫВОД ВЫБРАННОГО ТОВАРА ПРИ НЕНУЛЕВОМ НОМЕРЕ
         while (vif.slave_cb.item_select == 0) begin
                @(vif.slave_cb);
            end
            
            tx.item_select = vif.slave_cb.item_select;
            
            
      //ОЖИДАНИЕ CONFIRM
         while (vif.slave_cb.confirm !== 1) begin
                @(vif.slave_cb);
            end
            
            tx.confirm = vif.slave_cb.confirm;
            
         @(vif.slave_cb);
            
         // ОЖИДАНИЕ item_out или item_empty 
            while (vif.master_cb.item_out == 0 && vif.master_cb.item_empty == 0) begin
                @(vif.slave_cb);
            end
         //ЧТЕНИЕ ВЫХОДНЫХ СИГНАЛОВ 
            tx.item_out   = vif.master_cb.item_out;
            tx.item_empty = vif.master_cb.item_empty;
            tx.change_out = vif.master_cb.change_out;
            tx.no_change  = vif.master_cb.no_change;
            tx.client_points = vif.master_cb.client_points;

         `uvm_info(get_type_name(), tx.convert2string(), UVM_LOW)

          ap.write(tx);
      end
   endtask: run_phase
endclass: user_monitor
