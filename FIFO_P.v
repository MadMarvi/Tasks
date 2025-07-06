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
    integer i;
    assign dataout = buffer[cnt - 1];
    always @(posedge clk) begin
        if (reset) begin
            cnt <= 0;
            empty <= 1;
        end
        else if (read && !write && !empty) begin
            if (cnt == 0) begin
                empty <= 1;
            end else begin
                cnt <= cnt - 1;
            end
        end
        else if (write && !read && !full) begin
            for (i = DEPTH-1; i > 0; i= i-1) begin
                buffer[i] <= buffer[i-1];  
            end
            buffer[0] <= datain;          
            cnt <= cnt + 1;
            empty <= 0;
            end 
        else if(read && write && !empty) begin
            for (i = DEPTH-1; i > 0; i = i - 1) begin
                    buffer[i] <= buffer[i-1];  
                end
                buffer[0] <= datain;

        end
    end        
endmodule