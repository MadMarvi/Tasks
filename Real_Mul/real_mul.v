module real_mul #(
    parameter IS_DOUBLE = 0,
    parameter EXP_WIDTH = IS_DOUBLE == 1 ? 11 : 8,
    parameter MANT_WIDTH = IS_DOUBLE == 1 ? 52 : 23,
    parameter TOTAL_WIDTH = EXP_WIDTH + MANT_WIDTH + 1,
    parameter ROUND_MODE = 2'b11
)(
    input wire clk,
    input wire rst,
    input wire [TOTAL_WIDTH-1:0] op1,
    input wire [TOTAL_WIDTH-1:0] op2,
    output reg [TOTAL_WIDTH-1:0] result
);
    // Анализ знака через XOR старших битов
    wire result_sign;
    assign result_sign = op1[TOTAL_WIDTH-1] ^ op2[TOTAL_WIDTH-1];

    // Анализ операндов
    wire [4:0] op1_status;
    wire [4:0] op2_status;

    operand_analyzer #(
        .IS_DOUBLE(IS_DOUBLE),
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) op1_analyzer_inst (
        .operand(op1),
        .operand_status(op1_status)
    );

    operand_analyzer #(
        .IS_DOUBLE(IS_DOUBLE),
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) op2_analyzer_inst (
        .operand(op2),
        .operand_status(op2_status)
    );

    // Анализ операции
    wire [3:0] operation_status;

    operation_analyzer #(
        .IS_DOUBLE(IS_DOUBLE),
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) operation_analyzer_inst (
        .op1(op1),
        .op2(op2),
        .operation_status(operation_status)
    );

    // Умножение мантисс (добавляем скрытые биты)
    wire [2*MANT_WIDTH+1:0] mant_mul_full;
    wire [MANT_WIDTH:0] mant1_with_hidden = {1'b1, op1[MANT_WIDTH-1:0]};
    wire [MANT_WIDTH:0] mant2_with_hidden = {1'b1, op2[MANT_WIDTH-1:0]};

    assign mant_mul_full = mant1_with_hidden * mant2_with_hidden;

    // Проверка старшего бита и нормализация (приводим произведение к виду 1.xxxx)
    wire [2*MANT_WIDTH+1:0] normalized_mant;
    assign normalized_mant = mant_mul_full[2*MANT_WIDTH+1] ? mant_mul_full : (mant_mul_full << 1);

    // Подключение модуля округления
    wire overflow;
    wire [MANT_WIDTH-1:0] rounded_mantissa;

    rounding_module #(
        .IS_DOUBLE(IS_DOUBLE),
        .ROUND_MODE(ROUND_MODE)
    ) round_inst (
        .res_sign(result_sign),
        .data_in(normalized_mant),
        .data_out(rounded_mantissa),
        .overflow(overflow),
        .inexact()
    );

    // Коррекция экспоненты
    wire [EXP_WIDTH-1:0] exp_crr;
    wire exp_overflow;
    wire exp_underflow;

    exp_corr #(
        .IS_DOUBLE(IS_DOUBLE),
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) exp_corr_inst (
        .overflow(overflow),
        .mant(mant_mul_full),
        .exp_a(op1[TOTAL_WIDTH-2:MANT_WIDTH]), // экспонента op1 (без знака)
        .exp_b(op2[TOTAL_WIDTH-2:MANT_WIDTH]), // экспонента op2 (без знака)
        .exp_crr(exp_crr),
        .exp_overflow(exp_overflow),
        .exp_underflow(exp_underflow)
    );

    // Предварительный результат (NaN, inf, 0, inf*0)
    wire [TOTAL_WIDTH-1:0] pre_result;
    wire pre_result_is_special;

    pre_res #(
        .IS_DOUBLE(IS_DOUBLE),
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH),
        .TOTAL_WIDTH(TOTAL_WIDTH)
    ) pre_res_inst (
        .result_sign(result_sign),
        .op1(op1),
        .op2(op2),
        .op1_status(op1_status),
        .op2_status(op2_status),
        .operation_status(operation_status),
        .result(pre_result),
        .is_special_case(pre_result_is_special)
    );

    always @(posedge clk) begin
        if (rst) begin
            result <= {TOTAL_WIDTH{1'b0}};
        end else begin
            if (pre_result_is_special) begin
                result <= pre_result;
            end else if (exp_overflow) begin
                // Показатель степени вышел за пределы диапазона 
                result <= {result_sign, {EXP_WIDTH{1'b1}}, {MANT_WIDTH{1'b0}}};
            end else if (exp_underflow) begin
                // Показатель степени ушёл ниже нуля 
                result <= {result_sign, {EXP_WIDTH{1'b0}}, {MANT_WIDTH{1'b0}}};
            end else begin
                // Формируем результат: [sign][exp][mant]
                result <= {result_sign, exp_crr, rounded_mantissa};
            end
        end
    end

endmodule
