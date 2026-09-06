module processor_system(
  input  logic        clk_i,
  input  logic        rst_i
);
	
	logic [31:0] instr;
	logic        stall;
	logic [31:0] read_data_o;
	
	//Порты для Core
	logic        mem_req_o;
	logic [31:0] mem_wd_o;
	logic        mem_we_o;
	logic [31:0] instr_addr;
	logic [31:0] mem_addr_o;
	logic [2 :0] mem_size_o;
	logic [3 :0] mem_be_o;
	
	//Порты для data_mem
	logic memd_req_o;
	logic memd_we_o;
	logic [3 :0] memd_be_o;
	logic [31:0] memd_wd_o;
	logic [31:0] memd_addr_o;
	logic [31:0] memd_rd_i;
	logic ready;

	//Подключение процессорного ядра
	processor_core core(
	 .clk_i(clk_i),
	 .rst_i(rst_i),
	 .stall_i(stall),
	 .instr_i(instr),
	 .mem_rd_i(read_data_o),
	
	 .instr_addr_o(instr_addr),
	 .mem_addr_o(mem_addr_o),
	 .mem_size_o(mem_size_o),
	 .mem_req_o(mem_req_o),
	 .mem_we_o(mem_we_o),
	 .mem_wd_o(mem_wd_o)
	);
	
	//Подключение памяти инструкций
	instr_mem instr_mem_core(
	 .read_addr_i(instr_addr),
    .read_data_o(instr)
	);
	
	//Подключение памяти данных
	data_mem data_mem_core(
    .clk_i(clk_i),
    .mem_req_i(memd_req_o),
    .write_enable_i(memd_we_o),
    .byte_enable_i(memd_be_o),
    .addr_i(memd_addr_o),
    .write_data_i(memd_wd_o),
	 
    .read_data_o(memd_rd_i),
    .ready_o(ready)
);
	//Подключение LSU
	lsu lsu_core(
	 .clk_i(clk_i),
    .rst_i(rst_i),

  // Интерфейс с ядром
    .core_req_i(mem_req_o),
    .core_we_i(mem_we_o),
	 .core_size_i(mem_size_o),
    .core_addr_i(mem_addr_o),
    .core_wd_i(mem_wd_o),
    .core_rd_o(read_data_o),
    .core_stall_o(stall),

  // Интерфейс с памятью
	 .mem_req_o(memd_req_o),
    .mem_we_o(memd_we_o),
    .mem_be_o(memd_be_o),
    .mem_addr_o(memd_addr_o),
    .mem_wd_o(memd_wd_o),
    .mem_rd_i(memd_rd_i),
    .mem_ready_i(ready)
);
				
endmodule
