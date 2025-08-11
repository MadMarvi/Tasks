module operand_analyzer #(
    parameter IS_DOUBLE = 0,
    parameter EXP_WIDTH = IS_DOUBLE == 1 ? 11 : 8,
    parameter MANT_WIDTH = IS_DOUBLE == 1 ? 52 : 23
)(
    input wire [EXP_WIDTH+MANT_WIDTH:0] operand,  // [sign][exp][mantissa]
    output wire [4:0] operand_status              // [is_nan, is_infinity, is_denormal, is_normal, is_zero]
);
    localparam TOTAL_WIDTH = EXP_WIDTH + MANT_WIDTH + 1;
    
    wire sign = operand[TOTAL_WIDTH-1];
    wire [EXP_WIDTH-1:0] exponent = operand[TOTAL_WIDTH-2:MANT_WIDTH];
    wire [MANT_WIDTH-1:0] mantissa = operand[MANT_WIDTH-1:0];
    
    wire all_ones_exp = &exponent;  // Все биты экспоненты = 1
    wire all_zeros_exp = ~|exponent; // Все биты экспоненты = 0
    wire non_zero_mantissa = |mantissa;
    
    //вектор состояний операндов
    assign operand_status = {
        all_ones_exp && non_zero_mantissa,    // is_nan
        all_ones_exp && ~non_zero_mantissa,  // is_infinity
        all_zeros_exp && non_zero_mantissa,  // is_denormal
        ~all_zeros_exp && ~all_ones_exp,     // is_normal
        all_zeros_exp && ~non_zero_mantissa  // is_zero
    };

endmodule

module operation_analyzer #(
    parameter IS_DOUBLE = 0,
    parameter EXP_WIDTH = IS_DOUBLE == 1 ? 11 : 8,
    parameter MANT_WIDTH = IS_DOUBLE == 1 ? 52 : 23
)(
    input wire [EXP_WIDTH+MANT_WIDTH:0] op1,
    input wire [EXP_WIDTH+MANT_WIDTH:0] op2,
    output wire [3:0] operation_status       // [result_is_nan, result_is_clear_inf, result_is_zero, invalid_operation]
);
    wire invalid_operation;
    wire is_nan_operand;
    wire [4:0] op1_status;
    wire [4:0] op2_status;
    
    operand_analyzer #(
        .IS_DOUBLE(IS_DOUBLE),
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) op1_analyzer (
        .operand(op1),
        .operand_status(op1_status)
    );
    
    operand_analyzer #(
        .IS_DOUBLE(IS_DOUBLE),
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) op2_analyzer (
        .operand(op2),
        .operand_status(op2_status)
    );
    
    wire is_zero1 = op1_status[0];
    wire is_inf1 = op1_status[3];
    wire is_nan1 = op1_status[4];
    
    wire is_zero2 = op2_status[0];
    wire is_inf2 = op2_status[3];
    wire is_nan2 = op2_status[4];
    
    // Хотя бы один операнд NaN
    assign is_nan_operand = is_nan1 || is_nan2;
    
    // недопустимые опрации inf * 0
    assign invalid_operation = (is_inf1 && is_zero2) || (is_inf2 && is_zero1);
    
    // Вектор состояний операции
    assign operation_status = {
        is_nan_operand,                                     // result_is_nan
        (is_inf1 || is_inf2) && !is_nan_operand,           // result_is_clear_inf
        (is_zero1 || is_zero2) && !is_nan_operand,         // result_is_zero
        invalid_operation                                  // invalid_operation
    };
endmodule





