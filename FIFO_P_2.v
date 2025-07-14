module fifo #(
    parameter DEPTH = 16,          
    parameter DATA_WIDTH = 8       
)(
    input wire clk,
    input wire reset,
    input wire write,
    input wire [DATA_WIDTH-1:0] datain,
    input wire read,
    output wire [DATA_WIDTH-1:0] dataout,
    output wire val,
    output wire full
);
    reg [DATA_WIDTH-1:0] buffer [0:DEPTH-1]; 
    reg [$clog2(DEPTH):0] cnt;             
    reg empty;
    assign val = ~empty;
    assign full = (cnt == DEPTH);
    genvar  i;
    wire write_permitted = !full | read;
    assign dataout = buffer[0];

    always @(posedge clk) begin
        if (reset) begin
            cnt <= 0;
            empty <= 1;
        end
        else if (read && !write && !empty) begin
            if (cnt == 1) begin
                empty <= 1;
            cnt <= cnt - 1;
            end
        end
        else if (write && !read && !full) begin  
            buffer[cnt] <= datain;          
            cnt <= cnt + 1;
            empty <= 0;
            end 
        else if(read && write && !empty) begin
                buffer[cnt] <= datain;
        end
    end    

    generate for(i=1; i<DEPTH; i = i + 1)
    begin: loop0
        always @(posedge clk)
            buffer[i] <= write & write_permitted & (i<cnt) ? buffer[i-1] : buffer[i];
    end
    endgenerate    
endmodule