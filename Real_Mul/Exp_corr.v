module exp_corr  #(
    parameter IS_DOUBLE  = 0,
    parameter EXP_WIDTH  = IS_DOUBLE == 1 ? 11 : 8
)(
    input  wire                  overflow,
    input  wire [23:0]           mant,
    input  wire [EXP_WIDTH-1:0]  exp_a,
    input  wire [EXP_WIDTH-1:0]  exp_b,
    output wire [EXP_WIDTH+1:0]  exp_crr
);

    // Вычисляем bias в зависимости от типа
    localparam BIAS = IS_DOUBLE ? 1023 : 127;
    
    // Сумма мантисс
    wire [EXP_WIDTH:0] exp_sum;
    assign exp_sum = exp_a + exp_b;
    
    // Определяем паттерны старших битов
    wire pattern_01 = (mant[23:22] == 2'b01);
    wire pattern_10 = (mant[23:22] == 2'b10);
    wire pattern_11 = (mant[23:22] == 2'b11);
    
    // Корректирующее значение
    wire [1:0] correction_value;
    assign correction_value = pattern_01 ? {1'b0, overflow} :           // +1 если страшие биты 01 и есть окргуление
                              pattern_10 ?  2'b01 :                     // +1 если страшие биты 10
                              pattern_11 ? (overflow ? 2'b10 : 2'b01) : // +1 если страшие биты 11 и нет округления или +2 если оно есть
                                            2'b00;                      // +0 
    
    // Корректированная сумма
    assign exp_crr = exp_sum + correction_value - BIAS;

endmodule
