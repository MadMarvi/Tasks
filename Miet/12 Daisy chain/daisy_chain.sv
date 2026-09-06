module daisy_chain (
  input  logic        clk_i,
  input  logic        rst_i,

  input  logic [15:0] masked_irq_i,
  input  logic        irq_ret_i,
  input  logic        ready_i,

  output logic         irq_o,
  output logic [31:0]  irq_cause_o,
  output logic [15:0]  irq_ret_o
);

  logic [15:0] ready; // "Приоритет" - верхний ряд элементов И (рис. 1)
  logic [15:0] cause; // сигнал y - нижний ряд элементов И (рис. 1), one-hot

  // Нижний массив элементов И - побитовое И между ready и запросами
  assign cause    = ready & masked_irq_i;

  // Верхний массив элементов И - каждый следующий ready зависит от
  // предыдущего ready и предыдущего cause (генерируется через generate for)
  assign ready[0] = ready_i;

  genvar i;
  generate
    for (i = 1; i < 16; i++) begin : gen_ready_chain
      assign ready[i] = ready[i-1] & ~cause[i-1];
    end
  endgenerate

  assign irq_o       = |cause;
  // Формирование mcause: старший бит - 1 (аппаратное прерывание),
  // средние 16 бит - причина (one-hot), младшие 4 бита - 0
  assign irq_cause_o = {12'h800, cause, 4'b0000};

  // Регистр хранения причины прерывания на время его обработки
  logic [15:0] cause_reg;

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      cause_reg <= '0;
    end
    else if (irq_o) begin
      cause_reg <= cause;
    end
  end

  assign irq_ret_o = irq_ret_i ? cause_reg : '0;

endmodule
