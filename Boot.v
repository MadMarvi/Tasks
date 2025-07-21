module Alg_Boot #(
    parameter SIZE = 4
)(
    input wire [SIZE-1:0]   x,  
    input wire [SIZE-1:0]   y,
    output wire [SIZE*2-1:0] p,
    input wire clk,
    input wire rst
);
    wire m_temp;
    genvar           i;
    reg [2*SIZE-1:0] m;                         // регистр для храения сумм
    assign       p = m;
    assign m_temp = m << 1                      // провод для сдвига 

    generate for(i = SIZE - 1; i > 0; i = i - 1) 
        begin: mult
        always @(posedge clk) begin
            if (rst) begin
            m = 0;
        end
            else begin 
                m <= (y[i:i-1] == 01) ? m_temp + x : (y[i:i-1] == 10) ? m_temp - x : m_temp;     //Логика работы алгоритма Бута
                end
            end
        end
        endgenerate     
endmodule
