module lsu(
  input logic clk_i,
  input logic rst_i,

  // Интерфейс с ядром
  input  logic        core_req_i,
  input  logic        core_we_i,
  input  logic [ 2:0] core_size_i,
  input  logic [31:0] core_addr_i,
  input  logic [31:0] core_wd_i,
  output logic [31:0] core_rd_o,
  output logic        core_stall_o,

  // Интерфейс с памятью
  output logic        mem_req_o,
  output logic        mem_we_o,
  output logic [ 3:0] mem_be_o,
  output logic [31:0] mem_addr_o,
  output logic [31:0] mem_wd_o,
  input  logic [31:0] mem_rd_i,
  input  logic        mem_ready_i
);
	import decoder_pkg::*;
	logic          stall;
	logic [1 : 0]  byte_offset;
	logic          half_offset;
	logic [31: 0] ldst_b_i, ldst_w_i, ldst_bu_i, ldst_h_i, ldst_hu_i; // Выходные значения с мультиплексоров для core_rd_o
	
	assign byte_offset  = core_addr_i[1 : 0];
	assign half_offset  = core_addr_i[1    ];
	assign mem_addr_o   = core_addr_i;
	assign mem_we_o     = core_we_i;
	assign mem_req_o    = core_req_i;
	assign core_stall_o = (~(mem_ready_i & stall) & core_req_i);
	
	always_comb begin
	
		// Логика управления mem_be_o
		case(core_size_i)
			LDST_W : mem_be_o = 4'b1111;
			LDST_H : mem_be_o = half_offset ? 4'b1100 : 4'b0011;
			LDST_B : mem_be_o = 4'b0001 << core_addr_i[1:0];
			default: mem_be_o = 4'b0;
		endcase
		
		//Логика управления core_rd_o
		ldst_w_i = mem_rd_i;
		
		case(byte_offset)
			2'b00:   ldst_b_i = {{24{mem_rd_i[7 ]}}, mem_rd_i[7 : 0]};
			2'b01:   ldst_b_i = {{24{mem_rd_i[15]}}, mem_rd_i[15: 8]};
			2'b10:   ldst_b_i = {{24{mem_rd_i[23]}}, mem_rd_i[23:16]};
			2'b11:   ldst_b_i = {{24{mem_rd_i[31]}}, mem_rd_i[31:24]};
		endcase
		
		case(byte_offset)
			2'b00:   ldst_bu_i = {24'b0, mem_rd_i[7 : 0]};
			2'b01:   ldst_bu_i = {24'b0, mem_rd_i[15: 8]};
			2'b10:   ldst_bu_i = {24'b0, mem_rd_i[23:16]};
			2'b11:   ldst_bu_i = {24'b0, mem_rd_i[31:24]};
		endcase
		
		ldst_h_i  = half_offset ? {{16{mem_rd_i[31]}},mem_rd_i[31:16]} : {{16{mem_rd_i[15]}},mem_rd_i[15:0]};
		ldst_hu_i = half_offset ? {16'b0,mem_rd_i[31:16]}              : {16'b0,mem_rd_i[15:0]};
		
		case(core_size_i)
			LDST_W : core_rd_o = ldst_w_i;
			LDST_B : core_rd_o = ldst_b_i;
			LDST_BU: core_rd_o = ldst_bu_i;
			LDST_H : core_rd_o = ldst_h_i;
			LDST_HU: core_rd_o = ldst_hu_i;
			default: core_rd_o = 32'b0;
		endcase
		
		//Логика управления mem_wd_o
		case(core_size_i)
			LDST_H : mem_wd_o = {{2{core_wd_i[15: 0]}}};
			LDST_W : mem_wd_o = core_wd_i;
			LDST_B : mem_wd_o = {{4{core_wd_i[7 : 0]}}};
			default: mem_wd_o = core_wd_i;
		endcase
	end
	
		//Логика управления регистром stall
	always_ff @(posedge clk_i) begin
		if(rst_i) begin
			stall <= 1'b0;
		end else begin
			stall <= (~(mem_ready_i & stall) & core_req_i);
		end
	end
endmodule
