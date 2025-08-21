module pre_res #(
    parameter IS_DOUBLE = 0,
    parameter EXP_WIDTH = IS_DOUBLE == 1 ? 11 : 8,
    parameter MANT_WIDTH = IS_DOUBLE == 1 ? 52 : 23,
    parameter TOTAL_WIDTH = EXP_WIDTH + MANT_WIDTH + 1
)(
    input  wire result_sign,  
    input  wire [TOTAL_WIDTH-1:0] op1,
    input  wire [TOTAL_WIDTH-1:0] op2,
    input  wire [4:0] op1_status,        // [is_nan, is_infinity, is_denormal, is_normal, is_zero]
    input  wire [4:0] op2_status,
    input  wire [3:0] operation_status,  // [result_is_nan, result_is_clear_inf, result_is_zero, invalid_operation]
    output wire [TOTAL_WIDTH-1:0] result
);

    // Извлекаем флаги из статусов
    wire is_nan1  = op1_status[4];
    wire is_inf1  = op1_status[3];
    wire is_zero1 = op1_status[0];
    
    wire is_nan2  = op2_status[4];
    wire is_inf2  = op2_status[3];
    wire is_zero2 = op2_status[0];
    
    wire result_is_nan       = operation_status[3];
    wire result_is_clear_inf = operation_status[2];
    wire result_is_zero      = operation_status[1];
    wire invalid_operation   = operation_status[0];
    
    // Обработка NaN 
    wire [TOTAL_WIDTH-1:0] nan_result;
    wire [TOTAL_WIDTH-1:0] op1_with_nan_fix = {op1[TOTAL_WIDTH-1:MANT_WIDTH], 1'b1, op1[MANT_WIDTH-2:0]};
    wire [TOTAL_WIDTH-1:0] op2_with_nan_fix = {op2[TOTAL_WIDTH-1:MANT_WIDTH], 1'b1, op2[MANT_WIDTH-2:0]};
    
    assign nan_result =  is_nan1 ? op1_with_nan_fix : op2_with_nan_fix; 
                        
    
    // Обработка inf * zero
    wire [TOTAL_WIDTH-1:0] inf_zero_result;
    assign inf_zero_result = {1'b1, {EXP_WIDTH{1'b1}}, {1'b1, {MANT_WIDTH-1{1'b0}}}};
    
    // Обработка нуля
    wire [TOTAL_WIDTH-1:0] zero_result;
    assign zero_result = {result_sign, {EXP_WIDTH{1'b0}}, {MANT_WIDTH{1'b0}}};
    
    // Обработка бесконечности
    wire [TOTAL_WIDTH-1:0] inf_result;
    assign inf_result = {result_sign, {EXP_WIDTH{1'b1}}, {MANT_WIDTH{1'b0}}};
    
    // Параллельный выбор результата с использованием маскирования
    wire [TOTAL_WIDTH-1:0] default_result = {TOTAL_WIDTH{1'b0}};
    
    assign result = ({TOTAL_WIDTH{result_is_nan}}       & nan_result)      |
                    ({TOTAL_WIDTH{invalid_operation}}   & inf_zero_result) |
                    ({TOTAL_WIDTH{result_is_zero}}      & zero_result)     |
                    ({TOTAL_WIDTH{result_is_clear_inf}} & inf_result)      |
                    ({TOTAL_WIDTH{!(result_is_nan | invalid_operation | result_is_zero | result_is_clear_inf)}} & default_result);
endmodule
