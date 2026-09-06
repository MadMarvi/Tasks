module interrupt_controller(
  input  logic        clk_i,
  input  logic        rst_i,
  input  logic        exception_i,
  input  logic        irq_req_i,
  input  logic        mie_i,
  input  logic        mret_i,

  output logic        irq_ret_o,
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
	
	assign irq_o       = ((irq_req_i & mie_i) & ~(irq_h | (exc_h | exception_i)));
	assign irq_ret_o   = (mret_i & (~(exc_h | exception_i)));
	assign irq_cause_o = 32'h8000_0010;

endmodule
