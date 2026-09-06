module interrupt_controller(
  input  logic        clk_i,
  input  logic        rst_i,
  input  logic        exception_i,
  input  logic [15:0] irq_req_i,
  input  logic [15:0] mie_i,
  input  logic        mret_i,

  output logic [15:0] irq_ret_o,
  output logic [31:0] irq_cause_o,
  output logic        irq_o
);
	logic exc_h;
	logic irq_h;
	always_ff @(posedge clk_i) begin
		if (rst_i) begin
			exc_h <= 0;
			irq_h <= 0;
		end else begin
			exc_h <= ((exc_h | exception_i) & ~mret_i);
			irq_h <= ((irq_o  | irq_h) & (~(mret_i & (~(exc_h | exception_i)))));
		end
	end

	logic [15:0] masked_irq;
	logic        ready;
	logic        irq_ret_i;

	assign masked_irq = irq_req_i & mie_i;
	assign ready      = ~(irq_h | (exc_h | exception_i));
	assign irq_ret_i  = (mret_i & (~(exc_h | exception_i)));

	// Блок приоритетных прерываний (ЛР№12) - заменил собой прежний
	// жёстко зашитый одноисточниковый расчёт irq_o/irq_cause_o/irq_ret_o
	daisy_chain daisy_chain_core (
		.clk_i        (clk_i),
		.rst_i        (rst_i),

		.masked_irq_i (masked_irq),
		.irq_ret_i    (irq_ret_i),
		.ready_i      (ready),

		.irq_o        (irq_o),
		.irq_cause_o  (irq_cause_o),
		.irq_ret_o    (irq_ret_o)
	);

endmodule
