module CYBERcobra (
  input  logic         clk_i,
  input  logic         rst_i,
  input  logic [15:0]  sw_i,
  output logic [31:0]  out_o
);


	logic [31:0] pc_counter;                       // Счетчик команд
	logic [31:0] cob_instr_mem_o;                  // выходная шина с инструкцией
	logic [31:0] write_data_cob;                   // Провод с Write data для регистрового файла
	logic [1:0]  adjust_signal;                    // Управляющий сигнал для мультиплескора перед регистровым файлом
	logic [31:0] alu_cob_o;                        // Выход с АЛУ для арифметических операций
	logic [31:0] a_cob_i, b_cob_i;                 // Входы АЛУ
	logic [31:0] sum_o;                            // Выход для сумматора
	logic        en_sum;                           // Управляющий сигнал для мультиплескора перед сумматором
	logic [31:0] b_sum_in;                         // Нижний вход мультиплексора перед сумматором
	logic        alu_flag;                         // Выходной флаг с АЛУ
	
	assign b_sum_in      = en_sum ? {{22{cob_instr_mem_o[12]}},cob_instr_mem_o[12:5],2'b0} : 32'd4;    // провод выхода мультиплексора перед сумматором (константа или обычный шаг)
	assign en_sum        = ((cob_instr_mem_o[30] & alu_flag) || cob_instr_mem_o[31]);                    // управляющий провод для мультиплексора перед сумматором (выполненый условный переход или безусловный)
	assign out_o         = a_cob_i;
	assign adjust_signal = cob_instr_mem_o[29:28];
	
	
	//Мультиплексор перед регистровым файлом
	always_comb begin
		if (rst_i) begin
			write_data_cob = 32'd0;
		end else begin
			case (adjust_signal)    
					2'd0: write_data_cob = { {9{cob_instr_mem_o[27]}}, cob_instr_mem_o[27:5] };
					2'd1: write_data_cob = alu_cob_o;
					2'd2: write_data_cob = {{16{sw_i[15]}},sw_i};
					default: write_data_cob = 32'd0;
			endcase
		end
	end
	
	// Модуль памяти инструкций
	instr_mem imem(
	.read_addr_i(pc_counter),
	.read_data_o(cob_instr_mem_o)
	);

	// Модлуь регистрового файла
	register_file cob_register_file(
	.clk_i(clk_i),
	.write_enable_i(!(cob_instr_mem_o[30] || cob_instr_mem_o[31])),
	.write_addr_i(cob_instr_mem_o[4:0]),
	.read_addr1_i(cob_instr_mem_o[22:18]),
	.read_addr2_i(cob_instr_mem_o[17:13]),
	.write_data_i(write_data_cob),
	.read_data1_o(a_cob_i),
	.read_data2_o(b_cob_i)
	
	);
	
	// Модуль Алу
	alu cob_alu (
	.a_i(a_cob_i),
	.b_i(b_cob_i),
	.alu_op_i(cob_instr_mem_o[27:23]),
	.flag_o(alu_flag),
	.result_o(alu_cob_o)
	);
	
	// Модуль сумматора
	fulladder32 fulladder32_cob(
	.a_i(pc_counter),
	.b_i(b_sum_in),
	.carry_i(32'b0),
	.sum_o(sum_o),
	.carry_o()
	);
	
	//Логика переключения счетчика программ 
	always_ff @(posedge clk_i) begin
		if (rst_i) begin
			pc_counter <= 32'b0;
		end else begin
			pc_counter <= sum_o;
		end
	end

endmodule
