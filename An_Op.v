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