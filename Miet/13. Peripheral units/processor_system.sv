module processor_system(
  input  logic        clk_i,
  input  logic        resetn_i,

  // Входы и выходы периферии
  input  logic [15:0] sw_i,       // Переключатели

  output logic [15:0] led_o,      // Светодиоды

  input  logic        kclk_i,     // Тактирующий сигнал клавиатуры
  input  logic        kdata_i,    // Сигнал данных клавиатуры

  output logic [ 6:0] hex_led_o,  // Вывод семисегментных индикаторов
  output logic [ 7:0] hex_sel_o,  // Селектор семисегментных индикаторов

  input  logic        rx_i,       // Линия приёма по UART
  output logic        tx_o,       // Линия передачи по UART

  output logic [3:0]  vga_r_o,    // Красный канал vga
  output logic [3:0]  vga_g_o,    // Зелёный канал vga
  output logic [3:0]  vga_b_o,    // Синий канал vga
  output logic        vga_hs_o,   // Линия горизонтальной синхронизации vga
  output logic        vga_vs_o    // Линия вертикальной синхронизации vga
);

	import peripheral_pkg::*;

	logic sysclk, rst;
	sys_clk_rst_gen divider(.ex_clk_i(clk_i),.ex_areset_n_i(resetn_i),.div_i(5),.sys_clk_o(sysclk), .sys_reset_o(rst));

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
	logic [15:0] irq_req;
	logic [15:0] irq_ret;

	//Порты системной шины (общие для памяти данных и периферии)
	logic memd_req_o;
	logic memd_we_o;
	logic [3 :0] memd_be_o;
	logic [31:0] memd_wd_o;
	logic [31:0] memd_addr_o;
	logic [31:0] memd_rd_i;
	logic ready;

	//Подключение процессорного ядра
	processor_core core(
	 .clk_i(sysclk),
	 .rst_i(rst),
	 .stall_i(stall),
	 .instr_i(instr),
	 .mem_rd_i(read_data_o),
	 .irq_req_i(irq_req),

	 .instr_addr_o(instr_addr),
	 .mem_addr_o(mem_addr_o),
	 .mem_size_o(mem_size_o),
	 .mem_req_o(mem_req_o),
	 .mem_we_o(mem_we_o),
	 .mem_wd_o(mem_wd_o),
	 .irq_ret_o(irq_ret)
	);

	//Подключение памяти инструкций
	instr_mem instr_mem_core(
	 .read_addr_i(instr_addr),
    .read_data_o(instr)
	);

	//Подключение LSU
	lsu lsu_core(
	 .clk_i(sysclk),
    .rst_i(rst),

  // Интерфейс с ядром
    .core_req_i(mem_req_o),
    .core_we_i(mem_we_o),
	 .core_size_i(mem_size_o),
    .core_addr_i(mem_addr_o),
    .core_wd_i(mem_wd_o),
    .core_rd_o(read_data_o),
    .core_stall_o(stall),

  // Интерфейс с системной шиной
	 .mem_req_o(memd_req_o),
    .mem_we_o(memd_we_o),
    .mem_be_o(memd_be_o),
    .mem_addr_o(memd_addr_o),
    .mem_wd_o(memd_wd_o),
    .mem_rd_i(memd_rd_i),
    .mem_ready_i(1'b1) // все реализованные контроллеры всегда готовы
);

	// -----------------------------------------------------------------
	// Системная шина: унитарный (one-hot) дешифратор адреса
	// -----------------------------------------------------------------
	logic [255:0] periph_sel;
	assign periph_sel = 256'd1 << memd_addr_o[31:24];

	logic dmem_req;
	logic ps2_req;
	logic hex_req;

	assign dmem_req = memd_req_o & periph_sel[DMEM_ADDR_HIGH];
	assign ps2_req  = memd_req_o & periph_sel[PS2_ADDR_HIGH];
	assign hex_req  = memd_req_o & periph_sel[HEX_ADDR_HIGH];

	// Адрес с обнулённой старшей частью, общий для всех контроллеров
	logic [31:0] periph_addr;
	assign periph_addr = {8'h00, memd_addr_o[23:0]};

	//Подключение памяти данных
	logic [31:0] dmem_rd;
	data_mem data_mem_core(
    .clk_i(sysclk),
    .mem_req_i(dmem_req),
    .write_enable_i(memd_we_o),
    .byte_enable_i(memd_be_o),
    .addr_i(memd_addr_o),
    .write_data_i(memd_wd_o),

    .read_data_o(dmem_rd),
    .ready_o(ready)
);

	//Подключение контроллера клавиатуры PS/2 (устройство ввода варианта)
	logic [31:0] ps2_rd;
	logic        ps2_irq;

	ps2_sb_ctrl ps2_ctrl (
		.clk_i          (sysclk),
		.rst_i          (rst),
		.addr_i         (periph_addr),
		.req_i          (ps2_req),
		.write_data_i   (memd_wd_o),
		.write_enable_i (memd_we_o),
		.read_data_o    (ps2_rd),

		.interrupt_request_o (ps2_irq),
		.interrupt_return_i  (irq_ret[0]),

		.kclk_i  (kclk_i),
		.kdata_i (kdata_i)
	);

	//Подключение контроллера семисегментных индикаторов (устройство вывода варианта)
	logic [31:0] hex_rd;

	hex_sb_ctrl hex_ctrl (
		.clk_i          (sysclk),
		.rst_i          (rst),
		.addr_i         (periph_addr),
		.req_i          (hex_req),
		.write_data_i   (memd_wd_o),
		.write_enable_i (memd_we_o),
		.read_data_o    (hex_rd),

		.hex_led (hex_led_o),
		.hex_sel (hex_sel_o)
	);

	// PS/2 подключена к нулевой линии daisy chain (см. ps2_hex.S: mie = 0x00010000)
	assign irq_req = {15'b0, ps2_irq};

	// Мультиплексор чтения по старшей части адреса
	always_comb begin
		case (memd_addr_o[31:24])
			DMEM_ADDR_HIGH: memd_rd_i = dmem_rd;
			PS2_ADDR_HIGH:  memd_rd_i = ps2_rd;
			HEX_ADDR_HIGH:  memd_rd_i = hex_rd;
			default:        memd_rd_i = '0;
		endcase
	end

	// Периферия, не входящая в этот вариант - порты объявлены по требованию
	// методички, но не подключены ни к какой логике
	assign led_o    = '0;
	assign tx_o     = 1'b1;
	assign vga_r_o  = '0;
	assign vga_g_o  = '0;
	assign vga_b_o  = '0;
	assign vga_hs_o = 1'b0;
	assign vga_vs_o = 1'b0;

endmodule
