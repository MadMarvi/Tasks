module rounding_module #(
    parameter IS_DOUBLE = 0
) (
    input wire clk,            
    input wire rst,         
    input wire [((IS_DOUBLE) ? 105 : 47):0] data_in,  
    input wire [1:0] round_mode,
                                  // 00 - Округление к нулю
                                  // 01 - Округление к + inf
                                  // 10 - Округление к - inf
                                  // 11 - Округление к ближайшему четному
    output reg [((IS_DOUBLE) ? 52 : 23):0] data_out, 
    output reg acc            // Флаг точности (1 - округление не потребовалось)
);

wire [((IS_DOUBLE) ? 52 : 23):0] high_part = data_in[((IS_DOUBLE) ? 105 : 47):((IS_DOUBLE) ? 53 : 24)];
wire [((IS_DOUBLE) ? 52 : 23):0] low_part  = data_in[((IS_DOUBLE) ? 52 : 23):0];


wire low_part_is_zero = (low_part == 0); // флаг на то что округления не было
wire sign_bit = high_part[((IS_DOUBLE) ? 52 : 23)]; // Знаковый бит

// биты для окургления к четному
wire round_bit  = high_part[0];
wire guard_bit  = low_part[((IS_DOUBLE) ? 52 : 23)];
wire sticky_bit = (IS_DOUBLE) ? (|low_part[51:0]) : (|low_part[22:0]);


// Вычисление инкремента для каждого режима округления
wire round_up_plus_inf  = ~sign_bit & ~low_part_is_zero; // Для + inf если число положительное
wire round_up_min_inf   =  sign_bit & ~low_part_is_zero; // Для - inf если число отрицательное

wire round_nearest_even = ((guard_bit & sticky_bit) | 
                         (guard_bit & ~sticky_bit & round_bit));

// Выбор инкремента на основе режима округления
wire increment =
    (round_mode == 2'b01) ? round_up_plus_inf :
    (round_mode == 2'b10) ? round_up_min_inf :
    (round_mode == 2'b11) ? round_nearest_even :
    1'b0;

// Финальное округленное значение
wire [((IS_DOUBLE) ? 52 : 23):0] rounded_data = (low_part_is_zero ? high_part : high_part + increment);
 
always @(posedge clk) begin
    if (rst) begin
        data_out <= 0;
        acc <= 1'b0;
    end else begin
        data_out <= rounded_data;
        acc <= low_part_is_zero;
    end
end

endmodule
