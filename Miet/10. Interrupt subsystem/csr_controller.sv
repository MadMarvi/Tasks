import csr_pkg::*;
module csr_controller(
  input  logic        clk_i,
  input  logic        rst_i,
  input  logic        trap_i,
  input  logic [ 2:0] opcode_i,
  input  logic [11:0] addr_i,
  input  logic [31:0] pc_i,
  input  logic [31:0] mcause_i,
  input  logic [31:0] rs1_data_i,
  input  logic [31:0] imm_data_i,
  input  logic        write_enable_i,
  output logic [31:0] read_data_o,
  output logic [31:0] mie_o,
  output logic [31:0] mepc_o,
  output logic [31:0] mtvec_o
);

  logic [31:0] mux_1;
  logic        mux_2_1, mux_2_2, mux_2_3, mux_2_4, mux_2_5;
  logic [31:0] reg_1, reg_2, reg_3, reg_4, reg_5;
  logic [31:0] current_read;  // промежуточный сигнал
  
  assign mie_o   = reg_1;
  assign mtvec_o = reg_2;
  assign mepc_o  = reg_4;
  
  always_comb begin
    // Сначала определяем read_data_o 
    case (addr_i)
      12'h304: read_data_o = reg_1;
      12'h305: read_data_o = reg_2;
      12'h340: read_data_o = reg_3;
      12'h341: read_data_o = reg_4;
      12'h342: read_data_o = reg_5;
      default: read_data_o = 32'h0;
    endcase
    
    current_read = read_data_o;  
    
    // Формирование данных для записи
    case (opcode_i)
      3'b001: mux_1 = rs1_data_i;                    
      3'b010: mux_1 = rs1_data_i | current_read;      
      3'b011: mux_1 = ~rs1_data_i & current_read;    
      3'b101: mux_1 = imm_data_i;                   
      3'b110: mux_1 = imm_data_i | current_read;    
      3'b111: mux_1 = ~imm_data_i & current_read;     
      default: mux_1 = current_read;
    endcase
    
    // Сигналы разрешения записи в регистры
    mux_2_1 = 1'b0;
    mux_2_2 = 1'b0;
    mux_2_3 = 1'b0;
    mux_2_4 = 1'b0;
    mux_2_5 = 1'b0;
    
    case (addr_i)
      12'h304: mux_2_1 = write_enable_i;
      12'h305: mux_2_2 = write_enable_i;
      12'h340: mux_2_3 = write_enable_i;
      12'h341: mux_2_4 = write_enable_i;
      12'h342: mux_2_5 = write_enable_i;
    endcase
  end
  
  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      reg_1 <= 32'h0;
      reg_2 <= 32'h0;
      reg_3 <= 32'h0;
      reg_4 <= 32'h0;
      reg_5 <= 32'h0;
    end else begin
      reg_1 <= mux_2_1 ? mux_1 : reg_1;
      reg_2 <= mux_2_2 ? mux_1 : reg_2;
      reg_3 <= mux_2_3 ? mux_1 : reg_3;
      reg_4 <= (mux_2_4 || trap_i) ? (trap_i ? pc_i : mux_1) : reg_4;
      reg_5 <= (mux_2_5 || trap_i) ? (trap_i ? mcause_i : mux_1) : reg_5;
    end
  end
endmodule
