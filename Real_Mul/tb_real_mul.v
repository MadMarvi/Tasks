`timescale 1ns/1ps

module tb_real_mul;

    reg clk;
    reg rst;

    //Одиночная точность(32 бит)
    reg  [31:0] op1_s, op2_s;
    wire [31:0] res_s;

    real_mul #(.IS_DOUBLE(0)) dut_single (
        .clk(clk),
        .rst(rst),
        .op1(op1_s),
        .op2(op2_s),
        .result(res_s)
    );

    //Двойная точность(64 ьит)
    reg  [63:0] op1_d, op2_d;
    wire [63:0] res_d;

    real_mul #(.IS_DOUBLE(1)) dut_double (
        .clk(clk),
        .rst(rst),
        .op1(op1_d),
        .op2(op2_d),
        .result(res_d)
    );

    integer checks = 0;
    integer errors = 0;

    always #5 clk = ~clk;

    task check_single(input [31:0] a, input [31:0] b, input [31:0] expected, input [255:0] name);
        begin
            op1_s = a;
            op2_s = b;
            @(posedge clk);
            @(posedge clk);
            checks = checks + 1;
            if (res_s !== expected) begin
                errors = errors + 1;
                $display("[FAIL] %0s : op1=%h op2=%h -> got=%h expected=%h", name, a, b, res_s, expected);
            end else begin
                $display("[PASS] %0s : op1=%h op2=%h -> %h", name, a, b, res_s);
            end
        end
    endtask

    task check_double(input [63:0] a, input [63:0] b, input [63:0] expected, input [255:0] name);
        begin
            op1_d = a;
            op2_d = b;
            @(posedge clk);
            @(posedge clk);
            checks = checks + 1;
            if (res_d !== expected) begin
                errors = errors + 1;
                $display("[FAIL] %0s : op1=%h op2=%h -> got=%h expected=%h", name, a, b, res_d, expected);
            end else begin
                $display("[PASS] %0s : op1=%h op2=%h -> %h", name, a, b, res_d);
            end
        end
    endtask

    initial begin
        clk   = 0;
        rst   = 1;
        op1_s = 0; op2_s = 0;
        op1_d = 0; op2_d = 0;
        repeat (2) @(posedge clk);
        rst = 0;

        // Обычное умножение 
        check_single(32'h40000000, 32'h40400000, 32'h40C00000, "2.0 * 3.0 = 6.0");
        check_single(32'h3FC00000, 32'h40000000, 32'h40400000, "1.5 * 2.0 = 3.0");
        check_single(32'h3FC00000, 32'h3FC00000, 32'h40100000, "1.5 * 1.5 = 2.25");

        // Знаки 
        check_single(32'hC0000000, 32'h40400000, 32'hC0C00000, "-2.0 * 3.0 = -6.0");
        check_single(32'hC0000000, 32'hC0400000, 32'h40C00000, "-2.0 * -3.0 = 6.0");

        // Ноль 
        check_single(32'h00000000, 32'h40A00000, 32'h00000000, "0.0 * 5.0 = 0.0");
        check_single(32'h80000000, 32'h40A00000, 32'h80000000, "-0.0 * 5.0 = -0.0");

        // Бесконечность
        check_single(32'h7F800000, 32'h40000000, 32'h7F800000, "+inf * 2.0 = +inf");

        //Недопустимая операция: inf * 0 = NaN
        check_single(32'h7F800000, 32'h00000000, 32'hFFC00000, "+inf * 0 = NaN");

        //Распространение NaN 
        check_single(32'h7FC00001, 32'h40000000, 32'h7FC00001, "NaN * 2.0 = NaN");

        //Переполнение экспоненты 
        check_single(32'h5F800000, 32'h5F800000, 32'h7F800000, "2^64 * 2^64 -> +inf (overflow)");

        //Антипереполнение
        check_single(32'h1F800000, 32'h1F800000, 32'h00000000, "2^-64 * 2^-64 -> 0 (underflow)");

        //Двойная точность
        check_double(64'h3FF0000000000000, 64'h3FF0000000000000, 64'h3FF0000000000000, "double 1.0 * 1.0 = 1.0");
        check_double(64'h4000000000000000, 64'h4008000000000000, 64'h4018000000000000, "double 2.0 * 3.0 = 6.0");

        $display("----------------------------------------");
        $display("Total checks: %0d, Failures: %0d", checks, errors);
        if (errors == 0)
            $display(">>> ALL TESTS PASSED <<<");
        else
            $display(">>> SOME TESTS FAILED <<<");

        $finish;
    end

endmodule
