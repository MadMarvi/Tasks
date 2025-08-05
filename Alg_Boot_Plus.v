module Alg_Boot #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] op_1,
    input  wire [WIDTH-1:0] op_2,
    output wire [WIDTH-1:0] val,
    output wire [WIDTH-1:0] sign
);
    wire [WIDTH:0] op_2_add = {op_2,1'b0};
    
    genvar i;
    generate
        for(i = WIDTH-1; i >= 0; i = i - 1) begin: loop0
            assign val[i] = (i > 0) ? (op_2_add[i] ^ op_2_add[i-1]) : 1'b0;
            assign sign[i] = op_2_add[i];
        end
    endgenerate
endmodule

module mul #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] op_1,
    input  wire [WIDTH-1:0] op_2,
    output wire [2*WIDTH-1:0] result
);
    wire [WIDTH-1:0] val;
    wire [WIDTH-1:0] sign;

    Alg_Boot #(.WIDTH(WIDTH)) alg_boot_inst (
        .op_1(op_1),
        .op_2(op_2),
        .val(val),
        .sign(sign)
    );

    wire [2*WIDTH-1:0] part_product [0:WIDTH-1];
    
    genvar i;
    generate 
        for(i = 0; i < WIDTH; i = i + 1) begin: loop1
            assign part_product[i] = val[i] ? 
                (({2*WIDTH{sign[i]}} ^ {{WIDTH{1'b0}}, op_1}) + { {2*WIDTH-1{1'b0}}, sign[i] }) << i : 
                {2*WIDTH{1'b0}};
        end
    endgenerate
    
    // Суммирование всех part_product
    wire [2*WIDTH-1:0] sum = part_product[0];
    
    generate
        for(i = 1; i < WIDTH; i = i + 1) begin: sum_loop
            assign sum = sum + part_product[i];
        end
    endgenerate
    
    assign result = sum;
endmodule



