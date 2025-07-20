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
    wire write_permitted = (!full | read) & write;
    wire read_permitted = val & read;
    wire wr_n_rd_simult = write & read & !empty;
    assign dataout = buffer[0];

    always @(posedge clk) begin
        if (reset) begin
            cnt <= 0;
            empty <= 1;
        end
        else if (read_permitted & ~write_permitted) begin
            empty <= (cnt == 1) ? 1'b1 : 1'b0;
            cnt   <= cnt - 1;
        end
        else if (write_permitted & ~read_permitted) begin           
            cnt <= cnt + 1;
            empty <= 0;
        end 
    end   

    generate for(i=1; i<DEPTH; i = i + 1)
    begin: loop0
        always @(posedge clk)
            if(~reset)
                buffer[i] <= wr_n_rd_simult             ?               
                                                           (i+1== cnt) ? datain :
                                                           (i+1 < cnt) ? buffer[i+1] : buffer[i] :
                            write_permitted & (i==cnt)  ?  datain      :
                            read_permitted  & (i<cnt)   ?  buffer[i+1] : 
                                                           buffer[i]   ;
    end
    endgenerate    
endmodule
