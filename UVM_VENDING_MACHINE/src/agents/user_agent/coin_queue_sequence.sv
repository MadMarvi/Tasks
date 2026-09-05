class coin_queue_sequence extends uvm_sequence#(user_transaction);
   `uvm_object_utils(coin_queue_sequence)

   function new(string name = "coin_queue_sequence");
      super.new(name);
   endfunction

   task body();
      user_transaction tx;
      tx = user_transaction::type_id::create("tx");
      start_item(tx);
      tx.id_valid = 1'b1;
      tx.client_id = 12;
      tx.coins = {};
      tx.coins.push_back(50);
      tx.coins.push_back(25);
      tx.coins.push_back(10);
      tx.currency_type = 2'b00; 
      tx.item_select = 4;
      tx.confirm = 1'b1;
      finish_item(tx);
    endtask: body

endclass: coin_queue_sequence
