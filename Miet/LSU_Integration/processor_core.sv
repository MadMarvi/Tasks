module processor_core (
  input  logic        clk_i,
  input  logic        rst_i,

  input  logic        stall_i,
  input  logic [31:0] instr_i,
  input  logic [31:0] mem_rd_i,

  output logic [31:0] instr_addr_o,
  output logic [31:0] mem_addr_o,
  output logic [ 2:0] mem_size_o,
  output logic        mem_req_o,
  output logic        mem_we_o,
  output logic [31:0] mem_wd_o
);
	logic [31:0] program_counter;
	logic [31:0] cmd_I, cmd_U, cmd_B, cmd_J, cmd_S; //Константы команд
	logic [31:0] wb_data;
    logic [31:0] sum_frst,sum_zero, cmd, pre_sum_zero;                 // Вспомогательные провода для PC
    logic        mux_psz;
	
	// Провода для декодера
	logic [1:0] a_sel_o;
	logic [2:0] b_sel_o;
	logic [4:0] alu_op_o;
	logic       gpr_we_o;
	logic [1:0] wb_sel_o;
	logic       jal_o;
	logic       jalr_o;
	logic       branch_o;
	
	
	
	
	//Подключение декодера инструкций
	decoder decoder_core(
	 .fetched_instr_i(instr_i),
	 .a_sel_o(a_sel_o),
    .b_sel_o(b_sel_o),
    .alu_op_o(alu_op_o),
    .csr_op_o(),
    .csr_we_o(),
    .mem_req_o(mem_req_o),
    .mem_we_o(mem_we_o),
    .mem_size_o(mem_size_o),
    .gpr_we_o(gpr_we_o),
    .wb_sel_o(wb_sel_o),
    .illegal_instr_o(),
    .branch_o(branch_o),
    .jal_o(jal_o),
    .jalr_o(jalr_o),
    .mret_o()
);

	// Провода для АЛУ
	logic        flag_o;
	logic [31:0] result_o;
	logic [31:0] a_i, b_i;



	//Подключение АЛУ
	alu alu_core(
	 .a_i(a_i),
	 .b_i(b_i),
	 .alu_op_i(alu_op_o),
	 .flag_o(flag_o),
	 .result_o(result_o)
	 
);


	// Провода для регистрового файла
		logic [4:0]  read_addr1_i;
		logic [4:0]  read_addr2_i;
		logic [4:0]  write_addr_i;
		logic        write_enable_i;
		logic [31:0] write_data_i;
		logic [31:0] read_data1_o;
		logic [31:0] read_data2_o;

	//Подключение регистрового файла
	register_file register_file_core (
    .clk_i(clk_i),
    .write_enable_i(write_enable_i),
    .write_addr_i(write_addr_i),
    .read_addr1_i(read_addr1_i),
    .read_addr2_i(read_addr2_i),
    .write_data_i(write_data_i),
    .read_data1_o(read_data1_o),
    .read_data2_o(read_data2_o)
);
	assign write_enable_i = ~stall_i && gpr_we_o; // разрешение на запись с декодера
	assign mem_wd_o       = read_data2_o;

	//Входы регистровго файла								
	assign read_addr1_i   = instr_i[19:15];
	assign read_addr2_i   = instr_i[24:20];
	assign write_addr_i   = instr_i[11:07];
    assign write_data_i   = wb_data;
	
    //Описание констнат со знакорасширением
	assign cmd_I          = {{20{instr_i[31]}},instr_i[31:20]};
	assign cmd_U          = {instr_i[31:12],12'b0};
	assign cmd_S          = {{20{instr_i[31]}},instr_i[31:25],instr_i[11:7]};
	assign cmd_B          = {{19{instr_i[31]}},instr_i[31],instr_i[7],instr_i[30:25],instr_i[11:8],1'b0};
	assign cmd_J          = {{11{instr_i[31]}},instr_i[31],instr_i[19:12],instr_i[20],instr_i[30:21],1'b0};
	

    //Входы АЛУ
    always_comb begin
        case(b_sel_o) 
			3'd0:   b_i = read_data2_o;
			3'd1:   b_i = cmd_I;
			3'd2:   b_i = cmd_U;
			3'd3:   b_i = cmd_S;
		 default:   b_i = 32'b0;
		endcase

        case(a_sel_o) 
			2'd0:   a_i = read_data1_o;
			2'd1:   a_i = program_counter;
			2'd2:   a_i = 32'b0;
		 default:   a_i = 32'b0;
		endcase;
    end
                         
					
	assign mem_addr_o     = result_o;
	
    always_comb begin
        case(wb_sel_o)
            2'd0: wb_data = result_o;
            2'd1: wb_data = mem_rd_i;
         default: wb_data = 32'b0;
        endcase
    end
    
    assign instr_addr_o   = program_counter;

    //Логика работы PC
    always_comb begin
        sum_frst      = cmd_I + read_data1_o;
        case (branch_o)
            1'd0: cmd = cmd_J;
            1'd1: cmd = cmd_B;
         default: cmd = 32'b0;
        endcase

        mux_psz       = ((flag_o & branch_o) | jal_o);

        case(mux_psz)
            1'd0:  pre_sum_zero = 32'd4;
            1'd1:  pre_sum_zero = cmd;
         default:  pre_sum_zero = 32'b0;
        endcase
		  sum_zero      = program_counter + pre_sum_zero;
    end
        
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            program_counter <= 32'b0;
        end
        else begin
            if (~stall_i) begin
                case(jalr_o)
                    1'd0:    program_counter <= sum_zero;
                    1'd1:    program_counter <= {sum_frst[31:1],1'b0};
                    default: program_counter <= program_counter;
                endcase
            end
        end
    end

endmodule
