module Alg_Boot #(
    parameter SIZE = 4
)(
    input wire [SIZE-1:0]   x,
    input wire [SIZE-1:0]   y,
    output wire [SIZE*2-1:0] p,
    input wire clk,
    input wire rst
);

    genvar           i;
    reg [2*SIZE-1:0] m;
    assign       p = m;

    generate for(i = SIZE - 1; i > 0; i = i - 1) 
        begin: mult
        always @(posedge clk) begin
            if (rst) begin
            m = 0;
        end
            else begin
                m <=  m << 1; 
                m <= (y[i:i-1] == 01) ? m + x : (y[i:i-1] == 10) ? m - x : m;
                end
            end
        end
        endgenerate     
endmodule