module ring_fifo #(
    parameter DEPTH = 16,              
    parameter DATA_WIDTH = 8           
) (
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
    reg [$clog2(DEPTH)-1:0] wr_ptr;
    reg [$clog2(DEPTH)-1:0] rd_ptr;
    wire empty = (wr_ptr == rd_ptr);
    wire full = (wr_ptr + 1 == rd_ptr) || (wr_ptr == DEPTH-1 && rd_ptr == 0);
    assign dataout = buffer[rd_ptr];
    assign val = ~empty;
    
    always @(posedge clk) begin
        if (reset) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
        end else begin
            if (write && !full) begin
                buffer[wr_ptr] <= datain;
                wr_ptr <= (wr_ptr == DEPTH-1) ? 0 : wr_ptr + 1;
            end
            else if (read && !empty) begin
                rd_ptr <= (rd_ptr == DEPTH-1) ? 0 : rd_ptr + 1;
            end
            else if (read && !empty && write) begin
                buffer[wr_ptr] <= datain;
                rd_ptr <= (rd_ptr == DEPTH-1) ? 0 : rd_ptr + 1;
                wr_ptr <= (wr_ptr == DEPTH-1) ? 0 : wr_ptr + 1;
            end
        end
    end
endmodule