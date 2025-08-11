module operand_analyzer #(
    parameter EXP_WIDTH = 8,
    parameter MANT_WIDTH = 23
)(
    input wire [EXP_WIDTH+MANT_WIDTH:0] operand,  // [sign][exp][mantissa]
    output wire is_zero,
    output wire is_normal,
    output wire is_denormal,
    output wire is_infinity,
    output wire is_nan
);
    localparam TOTAL_WIDTH = EXP_WIDTH + MANT_WIDTH + 1;
    
    wire sign = operand[TOTAL_WIDTH-1];
    wire [EXP_WIDTH-1:0] exponent = operand[TOTAL_WIDTH-2:MANT_WIDTH];
    wire [MANT_WIDTH-1:0] mantissa = operand[MANT_WIDTH-1:0];
    
    wire all_ones_exp = &exponent;  // Все биты экспоненты = 1
    wire all_zeros_exp = ~|exponent; // Все биты экспоненты = 0
    wire non_zero_mantissa = |mantissa;
    
    assign is_zero = all_zeros_exp && ~non_zero_mantissa;
    assign is_denormal = all_zeros_exp && non_zero_mantissa;
    assign is_normal = ~all_zeros_exp && ~all_ones_exp;
    assign is_infinity = all_ones_exp && ~non_zero_mantissa;
    assign is_nan = all_ones_exp && non_zero_mantissa;

endmodule

module operation_analyzer #(
    parameter EXP_WIDTH = 8,
    parameter MANT_WIDTH = 23
)(
    input wire [EXP_WIDTH+MANT_WIDTH:0] op1,
    input wire [EXP_WIDTH+MANT_WIDTH:0] op2,
    output wire invalid_operation,
    output wire is_nan_operand
);
    operand_analyzer #(.EXP_WIDTH(EXP_WIDTH), .MANT_WIDTH(MANT_WIDTH)) op1_analyzer (
        .operand(op1),
        .is_zero(is_zero1),
        .is_normal(),
        .is_denormal(),
        .is_infinity(is_inf1),
        .is_nan(is_nan1)
    );
    
    operand_analyzer #(.EXP_WIDTH(EXP_WIDTH), .MANT_WIDTH(MANT_WIDTH)) op2_analyzer (
        .operand(op2),
        .is_zero(is_zero2),
        .is_normal(),
        .is_denormal(),
        .is_infinity(is_inf2),
        .is_nan(is_nan2)
    );
    
    // Неправильная операция inf * 0
    assign invalid_operation = (is_inf1 && is_zero2) || (is_inf2 && is_zero1);
    
    // Хотя бы один операнд NaN
    assign is_nan_operand = is_nan1 || is_nan2;
endmodule
