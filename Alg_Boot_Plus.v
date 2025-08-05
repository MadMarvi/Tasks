module Alg_Boot #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1 : 0] op_1,
    input  wire [WIDTH-1 : 0] op_2,
    output wire [WIDTH-1 : 0] val,
    output wire [WIDTH-1 : 0] sign
);
    wire [WIDTH : 0] op_2_add = {op_2,1'b0}; // дополненный опернад 2, с 0 после ,
    
    genvar i;

    generate
        for(i = WIDTH - 1; i>0; i = i - 1)
        begin: loop0
            assign val[i]   = op_2_add[i] ^ op_2_add[i-1]; // создаем вектор валидности, для 01 и 10 валидность 1
            assign sign[i]  = op_2_add[i]; // создаем знаковый вектор, 1 для -, 0 для +
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

    Alg_Boot #(
        .WIDTH(WIDTH)
    ) alg_boot_inst (
        .op_1(op_1),     
        .op_2(op_2),      
        .val(val),   
        .sign(sign)    
    );

    wire [2*WIDTH-1:0] part_product [WIDTH:0];
    
    genvar i;
    generate 
        for(i = WIDTH - 1; i>0; i = i - 1) 
            begin: loop1
            assign part_product[i] = val[i] ? 
                                                 ({2*WIDTH{sign[i]}} ^ op_1) + sign[i] << i 
                                            :    {2*WIDTH{1'b0}};
        end
    endgenerate
    
    // Суммирование всех part_product
    wire [2*WIDTH-1:0] sum [WIDTH:0];
    
    assign sum[0] = part_product[0];
    
    generate
        for(i=1; i<=WIDTH; i=i+1) begin: sum_loop
            assign sum[i] = sum[i-1] + part_product[i];
        end
    endgenerate
    
    assign result = sum[WIDTH];
endmodule


