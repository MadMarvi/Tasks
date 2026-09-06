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

	//Подключение процессорного ядра
	processor_core core(
	 .clk_i(clk_i),
	 .rst_i(rst_i),
	 .stall_i(stall),
	 .instr_i(instr),
	 .mem_rd_i(read_data_o),
	
	 .instr_addr_o(instr_addr),
	 .mem_addr_o(mem_addr_o),
	 .mem_size_o(),
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
    .mem_req_i(mem_req_o),
    .write_enable_i(mem_we_o),
    .byte_enable_i(4'b1111),
    .addr_i(mem_addr_o),
    .write_data_i(mem_wd_o),
	 
    .read_data_o(read_data_o),
    .ready_o()
);
	always_ff @(posedge clk_i) begin
		if (rst_i) begin
			stall <= 0;
		end else begin
			stall <= (~stall & mem_req_o);
		end
	end				
endmodule
