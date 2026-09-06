import memory_pkg::DATA_MEM_SIZE_BYTES;
import memory_pkg::DATA_MEM_SIZE_WORDS;
module data_mem
(
    input  logic        clk_i,
    input  logic        mem_req_i,
    input  logic        write_enable_i,
    input  logic [3:0]  byte_enable_i,
    input  logic [31:0] addr_i,
    input  logic [31:0] write_data_i,
	 
    output logic [31:0] read_data_o,
    output logic        ready_o
);

    // Память: массив 32-битных слов
    logic [31:0] ram [0:DATA_MEM_SIZE_WORDS-1];
    
    // Выходной регистр для синхронного чтения
    logic [31:0] read_data_reg;
    
    // Сигнал ready_o всегда равен 1 (данные готовы через 1 такт)
    assign ready_o = 1'b1;
    
    // Выдача данных на выход
    assign read_data_o = read_data_reg;
    
	 
    logic [$clog2(DATA_MEM_SIZE_WORDS)-1:0] word_index;
	 assign word_index = addr_i >> 2;  
    
    // Основной блок: синхронное чтение и запись
    always_ff @(posedge clk_i) begin
        if (mem_req_i) begin
            if (write_enable_i) begin
                // Запись: обновляем только выбранные байты
                if (byte_enable_i[0]) ram[word_index][7:0]   <= write_data_i[7:0];
                if (byte_enable_i[1]) ram[word_index][15:8]  <= write_data_i[15:8];
                if (byte_enable_i[2]) ram[word_index][23:16] <= write_data_i[23:16];
                if (byte_enable_i[3]) ram[word_index][31:24] <= write_data_i[31:24];
            end
            
            // Чтение (происходит всегда при mem_req_i, даже при записи)
            // Согласно спецификации: при write_enable_i == 0 происходит запрос на чтение
            // При записи тоже можно читать старое значение или не менять регистр?
            // По заданию: "Если mem_req_i == 1 и write_enable_i == 0, то происходит запрос на чтение"
            // Если write_enable_i == 1, чтение не производится, read_data_o сохраняет предыдущее значение
            if (!write_enable_i) begin
                read_data_reg <= ram[word_index];
            end
        end
        // Если mem_req_i == 0, ничего не делаем (read_data_reg сохраняет значение)
    end

endmodule
