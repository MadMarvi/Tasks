module Exp_Normalizer #(
    parameter IS_DOUBLE = 0,
    parameter EXP_WIDTH = IS_DOUBLE ? 11 : 8,
    parameter MANT_WIDTH = IS_DOUBLE ? 53 : 24;
    parameter EXP_BIAS = IS_DOUBLE ? 1023 : 127
) (
    input wire is_normalized1,
    input wire is_normalized2,
    input wire [EXP_WIDTH+1:0] exp_in,
    output wire [EXP_WIDTH-1:0] exp_out,
);
   
endmodule
