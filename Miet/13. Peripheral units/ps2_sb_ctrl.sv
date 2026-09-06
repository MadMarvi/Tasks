module ps2_sb_ctrl(
/*
    Часть интерфейса модуля, отвечающая за подключение к системной шине
*/
  input  logic         clk_i,
  input  logic         rst_i,
  input  logic [31:0]  addr_i,
  input  logic         req_i,
  input  logic [31:0]  write_data_i,
  input  logic         write_enable_i,
  output logic [31:0]  read_data_o,

/*
    Часть интерфейса модуля, отвечающая за отправку запросов на прерывание
    процессорного ядра
*/

  output logic        interrupt_request_o,
  input  logic        interrupt_return_i,

/*
    Часть интерфейса модуля, отвечающая за подключение к модулю,
    осуществляющему приём данных с клавиатуры
*/
  input  logic kclk_i,
  input  logic kdata_i
);

logic [7:0] scan_code;
logic       scan_code_is_unread;

logic [7:0] keycode;
logic       keycode_valid;

PS2Receiver ps2_receiver (
  .clk_i          (clk_i),
  .rst_i          (rst_i),
  .kclk_i         (kclk_i),
  .kdata_i        (kdata_i),
  .keycode_o      (keycode),
  .keycode_valid_o(keycode_valid)
);

// Регистры scan_code / scan_code_is_unread
always_ff @(posedge clk_i) begin
  if (rst_i) begin
    scan_code           <= '0;
    scan_code_is_unread <= 1'b0;
  end
  else if (keycode_valid) begin
    // Приём нового скан-кода имеет наивысший приоритет
    scan_code           <= keycode;
    scan_code_is_unread <= 1'b1;
  end
  else if (req_i && write_enable_i && (addr_i == 32'h24) && write_data_i[0]) begin
    // Запрос на запись сигнала сброса
    scan_code           <= '0;
    scan_code_is_unread <= 1'b0;
  end
  else if (req_i && !write_enable_i && (addr_i == 32'h00)) begin
    // Запрос на чтение scan_code - непрочитанные данные считаны
    scan_code_is_unread <= 1'b0;
  end
  else if (interrupt_return_i) begin
    // Завершение обработки прерывания
    scan_code_is_unread <= 1'b0;
  end
end

// Синхронное чтение
always_ff @(posedge clk_i) begin
  if (rst_i) begin
    read_data_o <= '0;
  end
  else if (req_i && !write_enable_i) begin
    case (addr_i)
      32'h00:  read_data_o <= {24'b0, scan_code};
      32'h04:  read_data_o <= {31'b0, scan_code_is_unread};
      default: read_data_o <= read_data_o;
    endcase
  end
end

assign interrupt_request_o = scan_code_is_unread;

endmodule
