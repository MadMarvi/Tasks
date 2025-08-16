module rounding_module #(
    parameter IS_DOUBLE = 0
) (         
    input wire [((IS_DOUBLE) ? 105 : 47):0] data_in,  
    input wire [1:0] round_mode,  // 00 - Округление к нулю
                                  // 01 - Округление к + inf
                                  // 10 - Округление к - inf
                                  // 11 - Округление к ближайшему четному
    output wire [((IS_DOUBLE) ? 52 : 23):0] data_out, 
    output wire inexact              // Флаг точности (1 - округление не потребовалось)
);

localparam HIGH_PART_WIDTH = (IS_DOUBLE) ? 52 : 23;
localparam LOW_PART_WIDTH = (IS_DOUBLE) ? 53 : 24;
localparam TOTAL_WIDTH = (IS_DOUBLE) ? 106 : 48;

wire [HIGH_PART_WIDTH:0] high_part = data_in[TOTAL_WIDTH-1:LOW_PART_WIDTH];
wire [LOW_PART_WIDTH-1:0] low_part = data_in[LOW_PART_WIDTH-1:0];

wire low_part_is_zero = (low_part == 0); // флаг на то что округления не было
wire sign_bit = high_part[HIGH_PART_WIDTH]; // Знаковый бит

// биты для окургления к четному
wire round_bit  = high_part[0];
wire guard_bit  = low_part[LOW_PART_WIDTH-1];
wire sticky_bit = (IS_DOUBLE) ? (|low_part[LOW_PART_WIDTH-2:0]) : (|low_part[22:0]);

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
assign data_out = high_part + increment;
assign inexact = ~low_part_is_zero;

endmodule
