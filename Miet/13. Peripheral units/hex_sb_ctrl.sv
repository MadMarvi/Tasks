module hex_sb_ctrl(
/*
    Часть интерфейса модуля, отвечающая за подключение к системной шине
*/
  input  logic        clk_i,
  input  logic        rst_i,
  input  logic [31:0] addr_i,
  input  logic        req_i,
  input  logic [31:0] write_data_i,
  input  logic        write_enable_i,
  output logic [31:0] read_data_o,

/*
    Часть интерфейса модуля, отвечающая за подключение к модулю,
    осуществляющему вывод цифр на семисегментные индикаторы
*/
  output logic [6:0] hex_led,
  output logic [7:0] hex_sel
);

  logic [3:0] hex0, hex1, hex2, hex3, hex4, hex5, hex6, hex7;
  logic [7:0] bitmask;

  // Регистры hex0-hex7, bitmask + сброс
  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      hex0 <= '0; hex1 <= '0; hex2 <= '0; hex3 <= '0;
      hex4 <= '0; hex5 <= '0; hex6 <= '0; hex7 <= '0;
      bitmask <= 8'hFF;
    end
    else if (req_i && write_enable_i) begin
      case (addr_i)
        32'h00: hex0 <= write_data_i[3:0];
        32'h04: hex1 <= write_data_i[3:0];
        32'h08: hex2 <= write_data_i[3:0];
        32'h0C: hex3 <= write_data_i[3:0];
        32'h10: hex4 <= write_data_i[3:0];
        32'h14: hex5 <= write_data_i[3:0];
        32'h18: hex6 <= write_data_i[3:0];
        32'h1C: hex7 <= write_data_i[3:0];
        32'h20: bitmask <= write_data_i[7:0];
        32'h24: begin
          if (write_data_i[0]) begin
            hex0 <= '0; hex1 <= '0; hex2 <= '0; hex3 <= '0;
            hex4 <= '0; hex5 <= '0; hex6 <= '0; hex7 <= '0;
            bitmask <= 8'hFF;
          end
        end
        default: ;
      endcase
    end
  end

  // Синхронное чтение
  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      read_data_o <= '0;
    end
    else if (req_i && !write_enable_i) begin
      case (addr_i)
        32'h00:  read_data_o <= {28'b0, hex0};
        32'h04:  read_data_o <= {28'b0, hex1};
        32'h08:  read_data_o <= {28'b0, hex2};
        32'h0C:  read_data_o <= {28'b0, hex3};
        32'h10:  read_data_o <= {28'b0, hex4};
        32'h14:  read_data_o <= {28'b0, hex5};
        32'h18:  read_data_o <= {28'b0, hex6};
        32'h1C:  read_data_o <= {28'b0, hex7};
        32'h20:  read_data_o <= {24'b0, bitmask};
        default: read_data_o <= read_data_o;
      endcase
    end
  end

  hex_digits hex_digits_core (
    .clk_i    (clk_i),
    .rst_i    (rst_i),
    .hex0_i   (hex0),
    .hex1_i   (hex1),
    .hex2_i   (hex2),
    .hex3_i   (hex3),
    .hex4_i   (hex4),
    .hex5_i   (hex5),
    .hex6_i   (hex6),
    .hex7_i   (hex7),
    .bitmask_i(bitmask),
    .hex_led_o(hex_led),
    .hex_sel_o(hex_sel)
  );

endmodule
