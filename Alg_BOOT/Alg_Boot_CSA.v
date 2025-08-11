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

    Alg_Boot #(.WIDTH(WIDTH)) alg_boot_inst (
        .op_1(op_1),
        .op_2(op_2),
        .val(val),
        .sign(sign)
    );

    wire [2*WIDTH-1:0] part_product [0:WIDTH - 1]; 
    
    genvar i;
    generate 
        for(i = WIDTH-1; i>0; i=i-1) begin: loop1
            assign part_product[i] = val[i] ? 
                                            ({2*WIDTH{sign[i]}} ^ op_1) + sign[i] << i 
                                        :    {2*WIDTH{1'b0}};
        end
    endgenerate
    
    wire [2*WIDTH-1:0] csa_in_a [0:5];
    wire [2*WIDTH-1:0] csa_in_b [0:5];
    wire [2*WIDTH-1:0] csa_in_c [0:5];
    wire [2*WIDTH-1:0] csa_out_a [0:5];
    wire [2*WIDTH-1:0] csa_out_b [0:5];

    //комутация соединений
    assign csa_in_a[0] = part_product[0];
    assign csa_in_b[0] = part_product[1];
    assign csa_in_c[0] = part_product[2];
    
    assign csa_in_a[1] = part_product[3];
    assign csa_in_b[1] = part_product[4];
    assign csa_in_c[1] = part_product[5];
    
    assign csa_in_a[2] = csa_out_a[0];
    assign csa_in_b[2] = csa_out_b[0];
    assign csa_in_c[2] = csa_out_a[1];
    
    assign csa_in_a[3] = part_product[6];
    assign csa_in_b[3] = part_product[7];
    assign csa_in_c[3] = csa_out_b[1];
    
    assign csa_in_a[4] = csa_out_a[2];
    assign csa_in_b[4] = csa_out_b[2];
    assign csa_in_c[4] = csa_out_a[3];
    
    assign csa_in_a[5] = csa_out_a[4];
    assign csa_in_b[5] = csa_out_b[4];
    assign csa_in_c[5] = csa_out_b[3];
    
    generate 
        for (i = 0; i < 6; i = i + 1) begin: loop2
            assign csa_out_a[i] = csa_in_a[i] ^ csa_in_b[i] ^ csa_in_c[i];
            assign csa_out_b[i] = (csa_in_a[i] & csa_in_b[i] |
                                 csa_in_b[i] & csa_in_c[i] |
                                 csa_in_a[i] & csa_in_c[i]) << 1;
        end
    endgenerate

    // Подключение выхода
    assign result = csa_out_a[5] + csa_out_b[5];
endmodule
