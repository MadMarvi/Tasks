module exp_corr #(
    parameter IS_DOUBLE  = 0,
    parameter EXP_WIDTH  = IS_DOUBLE == 1 ? 11 : 8,
    parameter MANT_WIDTH = IS_DOUBLE == 1 ? 52 : 23
)(
    input  wire                    overflow,   // перенос при округлении (из rounding_module)
    input  wire [2*MANT_WIDTH+1:0] mant,       // НЕнормализованное произведение мантисс (mant_mul_full)
    input  wire [EXP_WIDTH-1:0]    exp_a,
    input  wire [EXP_WIDTH-1:0]    exp_b,
    output wire [EXP_WIDTH-1:0]    exp_crr,
    output wire                    exp_overflow, // результат должен стать +-inf
    output wire                    exp_underflow // результат должен стать +-0 
);

    // Вычисляем bias в зависимости от типа
    localparam BIAS = IS_DOUBLE ? 1023 : 127;

    // 01 - нужен сдвиг на 1, показатель степени не растёт (если нет переноса при округлении)
    // 10 - сдвиг не нужен, показатель степени +1
    // 11 - сдвиг не нужен, показатель степени +1 (+2 если перенос при округлении)
    wire pattern_01 = (mant[2*MANT_WIDTH+1:2*MANT_WIDTH] == 2'b01);
    wire pattern_10 = (mant[2*MANT_WIDTH+1:2*MANT_WIDTH] == 2'b10);
    wire pattern_11 = (mant[2*MANT_WIDTH+1:2*MANT_WIDTH] == 2'b11);

    // Корректирующее значение
    wire [1:0] correction_value;
    assign correction_value = pattern_01 ? {1'b0, overflow} :            // +1, если старшие биты 01 и было округление вверх
                              pattern_10 ?  2'b01 :                      // +1, если старшие биты 10
                              pattern_11 ? (overflow ? 2'b10 : 2'b01) :   // +1 если 11 без переполнения округления, +2 если с ним
                                            2'b00;                        // +0 (произведение < 1 невозможно для нормализованных операндов)

    // Сумма экспонент с учётом смещения и коррекции.
    localparam signed [EXP_WIDTH+3:0] MAX_EXP_VAL = {EXP_WIDTH{1'b1}}; // все единицы - зарезервировано под inf/NaN

    wire signed [EXP_WIDTH+3:0] exp_sum_wide =
        $signed({4'b0, exp_a}) + $signed({4'b0, exp_b}) - BIAS + $signed({2'b0, correction_value});

    assign exp_overflow  = (exp_sum_wide >= MAX_EXP_VAL);
    assign exp_underflow = (exp_sum_wide <= 0);

    assign exp_crr = exp_overflow  ? {EXP_WIDTH{1'b1}} :
                      exp_underflow ? {EXP_WIDTH{1'b0}} :
                                      exp_sum_wide[EXP_WIDTH-1:0];

endmodule
