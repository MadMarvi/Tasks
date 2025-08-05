module Alg_Boot_Three #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] op_2,
    output wire [WIDTH/2:0]  val,  
    output wire [WIDTH/2:0]  sign,     // Знак , 1 - отрицательный
    output wire [WIDTH/2:0]  double    // Удвоение, 1 умножить на 2
);

    wire [WIDTH:0] op_2_add = {op_2, 1'b0}; // Расширяем операнд на 1 бит для обработки
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 2) begin : encoder_loop
            localparam integer idx = i/2;
            wire [2:0] booth_bits = opp_2_add[i+2:i];
            
            assign val[idx]    = (booth_bits == 3'b000 || booth_bits == 3'b111) ? 1'b0 : 1'b1;
            assign sign[idx] = booth_bits[2] ^ (booth_bits[1] & booth_bits[0]); // по таблице выставляем знак
            assign double[idx] = (booth_bits == 3'b100 || booth_bits == 3'b011);
        end
    endgenerate
endmodule

module mul_Alg_Boot_Three#(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] op_1,
    input  wire [WIDTH-1:0] op_2,
    output wire [2*WIDTH-1:0] result
);
    localparam NUM = (WIDTH/2) + 1;
    
    wire [NUM-1:0] val;
    wire [NUM-1:0] sign;
    wire [NUM-1:0] double;
    
    Alg_Boot_Three #(
        .WIDTH(WIDTH)
    ) encoder (
        .op_2(op_2),
        .val(val),
        .sign(sign),
        .double(double)
    );
    
    
    wire [2*WIDTH-1:0] part_product [NUM-2:0]; // Частичные произведения(количество 4 штуки)
    
  endmodule