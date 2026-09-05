// -----------------------------------------------------------------------------
//  Vending Machine Controller (SystemVerilog)
//  Ревизия: 2025‑07‑16  — учтены все ранее озвученные замечания
// -----------------------------------------------------------------------------

`timescale 1ns/1ps

module vending_machine #(
    parameter int NUM_ITEMS    = 10,
    parameter int MAX_CLIENTS  = 100,
    parameter logic [31:0] ADMIN_PASSWORD = 32'hA5A5_F00D
)(
    //‑‑‑‑‑‑‑‑‑‑‑‑ System
    input  logic               clk,
    input  logic               rst_n,

    //‑‑‑‑‑‑‑‑‑‑‑‑ Register interface
    input  logic [31:0]        regs_data_in,
    output logic [31:0]        regs_data_out,
    input  logic               regs_we,
    input  logic [7:0]         regs_addr,

    //‑‑‑‑‑‑‑‑‑‑‑‑ User interface
    input  logic               id_valid,
    input  logic [8:0]         client_id,
    input  logic [5:0]         coin_in,
    input  logic [1:0]         currency_type,
    input  logic               coin_insert,
    input  logic [NUM_ITEMS-1:0] item_select,
    input  logic               confirm,

    //‑‑‑‑‑‑‑‑‑‑‑‑ Admin interface
    input  logic               admin_mode,
    input  logic [31:0]        admin_password,

    //‑‑‑‑‑‑‑‑‑‑‑‑ System IRQ
    input  logic               tamper_detect,
    input  logic               jam_detect,
    input  logic               power_loss,

    //‑‑‑‑‑‑‑‑‑‑‑‑ Outputs
    output logic                 access_error,
    output logic [NUM_ITEMS-1:0] item_out,
    output logic [31:0]          change_out,
    output logic                 no_change,
    output logic [NUM_ITEMS-1:0] item_empty,
    output logic [7:0]           client_points,
    output logic                 alarm
);

    // =============================================================
    // 1. Configuration registers
    // =============================================================
    logic [31:0] r_current_admin_password;

    logic [4:0]  r_num_items;
    logic [7:0]  r_max_coins;
    logic [10:0] r_idle_timeout;
    logic [7:0]  r_exchange_rate;
    logic [7:0]  r_max_clients;

    logic [7:0]  r_item_prices   [NUM_ITEMS];
    logic [7:0]  r_item_count    [NUM_ITEMS];
    logic [7:0]  r_item_discount [NUM_ITEMS];

    logic admin_access_granted;

    // Password check
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            admin_access_granted <= 1'b0;
        else if (admin_mode && admin_password == r_current_admin_password)
            admin_access_granted <= 1'b1;
        else if (!admin_mode)
            admin_access_granted <= 1'b0;
    end

    // Write Register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_num_items     <= 5'(NUM_ITEMS);
            r_max_coins     <= 8'd100;
            r_idle_timeout  <= 11'd10;
            r_exchange_rate <= 8'd2;
            r_max_clients   <= 8'(MAX_CLIENTS);
            r_current_admin_password <= ADMIN_PASSWORD;

            for (int i = 0; i < NUM_ITEMS; i++) begin
                r_item_prices[i]   <= (i+1)*8'd10;
                r_item_count[i]    <= 8'd5;
                r_item_discount[i] <= 8'd0;
            end
        end else if (regs_we && admin_access_granted) begin
            unique case (regs_addr)
                8'h00: begin
                    r_num_items     <= regs_data_in[4:0];
                    r_max_coins     <= regs_data_in[12:5];
                    r_idle_timeout  <= regs_data_in[23:13];
                    r_exchange_rate <= regs_data_in[31:24];
                end
                8'h04: r_max_clients <= regs_data_in[7:0];
                8'h08: begin
                    if (regs_data_in[31:0] != 32'h0 && |regs_data_in[31:8]) begin
                        r_current_admin_password <= regs_data_in;
                    end
                end
                default: if (regs_addr >= 8'h0C && regs_addr < 8'h0C + NUM_ITEMS*4) begin
                    automatic int idx = (regs_addr - 8'h0C) / 4;
                    r_item_prices[idx]   <= regs_data_in[7:0];
                    r_item_count[idx]    <= regs_data_in[15:8];
                    r_item_discount[idx] <= regs_data_in[23:16];
                end
            endcase
        end
    end

    // Read Register
    always_comb begin
        regs_data_out = 32'h0;
        if (admin_access_granted) begin
            unique case (regs_addr)
                8'h00: regs_data_out = {r_exchange_rate, r_idle_timeout, r_max_coins, r_num_items};
                8'h04: regs_data_out = {24'h0, r_max_clients};
                8'h08: regs_data_out = r_current_admin_password;
                default: if (regs_addr >= 8'h0C && regs_addr < 8'h0C + NUM_ITEMS*8) begin
                    automatic int idx = (regs_addr - 8'h0C) / 8;
                    automatic int field = (regs_addr - 8'h0C) % 8;
                    case (field)
                        0: regs_data_out = {24'h0, r_item_prices[idx]};
                        4: regs_data_out = {24'h0, r_item_count[idx]};
                        6: regs_data_out = {24'h0, r_item_discount[idx]};
                    endcase
                end
            endcase
        end else begin
            regs_data_out = 32'hDEAD_BEEF; // access error
        end
    end



    // =============================================================
    // 2. Client database
    // =============================================================
    typedef struct packed {
        logic [7:0] points;
        logic [1:0] discount;
        logic       is_vip;
    } client_data_t;

    client_data_t clients [MAX_CLIENTS];
    client_data_t current_client;
    logic  [8:0]  current_id;


    // =============================================================
    // 3. Main FSM
    // =============================================================
    typedef enum logic [2:0] {
        IDLE,
        ACCEPT_COINS,
        WAIT_CONFIRM,
        DISPENSE_ITEM,
        GIVE_CHANGE,
        ERROR_STATE,
        EMERGENCY
    } state_t;

    state_t current_state, next_state;

    logic [31:0] balance_rubles;
    logic [31:0] idle_timer;
    logic [1:0]  admin_substate;

    logic [5:0] r_id_valid, rr_id_valid;
    logic [8:0] r_client_id, rr_client_id;
    logic [5:0] r_coin_in, rr_coin_in;
    logic [1:0] r_currency_type, rr_currency_type;
    logic       r_coin_insert, rr_coin_insert;
    logic [NUM_ITEMS-1:0] r_item_select, rr_item_select;
    logic       r_confirm, rr_confirm;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_id_valid <= 0;
            r_client_id <= 0;
            r_coin_in <= 0;
            r_currency_type <= 0;
            r_coin_insert <= 0;
            r_item_select <= 0;
            r_confirm <= 0;
        end else begin
            r_id_valid <= id_valid;
            r_client_id <= client_id;
            r_coin_in <= coin_in;
            r_currency_type <= currency_type;
            r_coin_insert <= coin_insert;
            r_item_select <= item_select;
            r_confirm <= confirm;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rr_id_valid <= 0;
            rr_client_id <= 0;
            rr_coin_in <= 0;
            rr_currency_type <= 0;
            rr_coin_insert <= 0;
            rr_item_select <= 0;
            rr_confirm <= 0;
        end else begin
            rr_id_valid <= r_id_valid;
            rr_client_id <= r_client_id;
            rr_coin_in <= r_coin_in;
            rr_currency_type <= r_currency_type;
            rr_coin_insert <= r_coin_insert;
            rr_item_select <= r_item_select;
            rr_confirm <= r_confirm;
        end
    end


    // =============================================================
    // 2. Errors Detection
    // =============================================================

    typedef enum logic [2:0] {
        ERR_NO_ERROR,
        ERR_SOLD_OUT,
        ERR_INVALID_ITEM,
        ERR_INSUFFICIENT_FUNDS
    } error_code_t;

    error_code_t current_error;


    always_ff @(posedge clk) begin
        if (current_state == WAIT_CONFIRM && r_confirm) begin
            int item;
            item = get_item_index(r_item_select);
            if (item == -1)
                current_error <= ERR_INVALID_ITEM;
            else if (r_item_count[item] == 0)
                current_error <= ERR_SOLD_OUT;
            else if (balance_rubles < get_discounted_price(item))
                current_error <= ERR_INSUFFICIENT_FUNDS;
        end
    end


    //-------------------------------------------------
    // Emergency interrupt handling (edge‑detect)
    //-------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) alarm <= 1'b0;
        else if (tamper_detect | jam_detect | power_loss) alarm <= 1'b1;
        else if (current_state == EMERGENCY && !(tamper_detect | jam_detect | power_loss)) alarm <= 1'b0;
    end

    //-------------------------------------------------
    // Sequential register of current_state
    //-------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) current_state <= IDLE;
        else        current_state <= next_state;
    end

    //-------------------------------------------------
    // Combinational next_state & outputs default
    //-------------------------------------------------
    always_comb begin
        // defaults
        next_state = current_state;

        unique case (current_state)
            //--------------------------------------------------
            IDLE: begin
                if (r_coin_insert) begin
                    next_state = ACCEPT_COINS;
                end
            end

            //--------------------------------------------------
            ACCEPT_COINS: begin
                if (r_coin_insert) begin
                    // balance update is sequential
                end else if (r_item_select != '0) begin
                    next_state = WAIT_CONFIRM;
                end else if (idle_timer >= r_idle_timeout) begin
                    next_state = GIVE_CHANGE;
                end
            end

            //--------------------------------------------------
            WAIT_CONFIRM: begin
                if (r_confirm) begin
                    int item;
                    item = get_item_index(r_item_select);
                    if (item == -1) begin
                        next_state = ERROR_STATE;
                    end else if (r_item_count[item] == 0) begin
                        next_state = ERROR_STATE;
                    end else if (balance_rubles >= get_discounted_price(item)) begin
                        next_state = DISPENSE_ITEM;
                    end else if (idle_timer >= r_idle_timeout) begin
                        next_state = GIVE_CHANGE;
                    end
                end
            end

            //--------------------------------------------------
            DISPENSE_ITEM: begin
                next_state = GIVE_CHANGE;
            end

            //--------------------------------------------------
            GIVE_CHANGE: begin
                next_state = IDLE;
            end

            //--------------------------------------------------
            EMERGENCY: begin
                if (!(tamper_detect | jam_detect | power_loss)) next_state = IDLE;
            end

            //--------------------------------------------------
            ERROR_STATE: begin
                if (idle_timer >= r_idle_timeout) begin
                    next_state = IDLE;
                end
            end
        endcase
    end

    //-------------------------------------------------
    // Sequential actions (balance, counters, timers)
    //-------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            balance_rubles <= '0;
            idle_timer     <= '0;
            admin_substate <= 2'd0;
            item_empty     <= '0;
        end else begin
            // Idle timer
            if (current_state == IDLE && r_id_valid && r_client_id < r_max_clients)
                idle_timer <= 0;
            else if (next_state == current_state)
                idle_timer <= idle_timer + 1;
            else
                idle_timer <= 0;

            // Balance update
            if (current_state == ACCEPT_COINS && r_coin_insert)
                balance_rubles <= balance_rubles + convert_to_rubles(r_coin_in, r_currency_type);
            else if (current_state == GIVE_CHANGE)
                balance_rubles <= 0;


            // Dispense item
            if (current_state == DISPENSE_ITEM) begin
                int item;
                item = get_item_index(rr_item_select);
                if (item != -1) begin
                    balance_rubles <= balance_rubles - get_discounted_price(item);
                end
            end

            // Error flags
            if (current_state == DISPENSE_ITEM) begin
                int item;
                item = get_item_index(rr_item_select);
                if (item != -1 && r_item_count[item] == 0) begin
                    item_empty[item] <= 1'b1;
                end else if (current_state == IDLE) begin
                    item_empty <= '0;
                end
            end
        end
    end


    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            no_change <= 1'b0;
        end else begin
            if (current_state == GIVE_CHANGE) begin
                no_change <= (balance_rubles == 0);
            end else begin
                no_change <= 1'b0;
            end
        end
    end


    // Separate register for access error
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            access_error <= 1'b0;
        end else begin
            // Reset error at the beginning of each operation
            access_error <= 1'b0;

            // Setting the error in cases:
            // а) Attempt to write without rights
            if (regs_we && !admin_access_granted) begin
                access_error <= 1'b1;
            end
            // б) Invalid password format
            else if (regs_we && regs_addr == 8'h08 &&
                    (regs_data_in == 32'h0 || !(|regs_data_in[31:8]))) begin
                access_error <= 1'b1;
            end
        end
    end


    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            item_out <= '0;
        end else begin
            item_out <= '0;
            if (current_state == DISPENSE_ITEM) begin
                int item;
                item = get_item_index(rr_item_select);
                if (item != -1 && item < NUM_ITEMS) begin
                    item_out[item] <= 1'b1;
                end
            end
        end
    end


    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            change_out <= '0;
        end else if (current_state == GIVE_CHANGE) begin
            change_out <= (balance_rubles > 0) ? balance_rubles : '0;
        end else begin
            change_out <= '0;
        end
    end


    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            client_points <= '0;
        end else begin
            client_points <= clients[current_id].points;
        end
    end


    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Initializing clients
            for (int i = 0; i < MAX_CLIENTS; i++) begin
                clients[i] <= '{points: (i % 20),
                                discount: (i % 3),
                                is_vip: (i % 10 == 0)};
            end
            current_client <= '{0, 0, 0};
            current_id <= 0;
        end
        else begin
            // Update current_client when changing client
            if (current_state == IDLE && r_id_valid && r_client_id < r_max_clients) begin
                current_id <= r_client_id;
                current_client <= clients[r_client_id];
            end

            // Updating points when issuing goods
            if (current_state == DISPENSE_ITEM && current_id < r_max_clients) begin
                int item;
                item = get_item_index(rr_item_select);
                if (item != -1) begin
                    // Calculation of new points with overflow protection
                    int new_points;
                    new_points = clients[current_id].points + (get_discounted_price(item)/20);
                    if (new_points > 255) new_points = 255;

                    // Atomic update
                    clients[current_id].points <= new_points;
                    current_client.points <= new_points;
                end
            end
        end
    end


    // =============================================================
    // 4. Helper functions
    // =============================================================
    // Convert external coin amount to rubles
    function automatic int convert_to_rubles(input int amount, input int currency);
        unique case (currency)
            0: convert_to_rubles = amount;                           // RUB
            1: convert_to_rubles = amount * r_exchange_rate;         // USD
            2: convert_to_rubles = (amount * r_exchange_rate * 3)/2; // EUR ≈1.5 USD
            default: convert_to_rubles = amount;
        endcase
    endfunction

    // Discounted price for current_client
    function automatic int get_discounted_price(input int item_idx);
        int base = r_item_prices[item_idx];
        int disc = (current_client.discount * 10) + (current_client.is_vip ? 10 : 0);
        get_discounted_price = (base * (100 - disc)) / 100;
    endfunction

    // One‑hot item_select → index
    function automatic int get_item_index(input logic [NUM_ITEMS-1:0] sel);
        if ($countones(sel) != 1) return -1;
        for (int i = 0; i < NUM_ITEMS; i++) begin
            if (sel[i]) begin
                return i;
            end
        end
        return -1;
    endfunction

endmodule
