module Z_C #(
    parameter DATA_WIDTH = 16,
    parameter ZERO_WIDTH = $clog2(DATA_WIDTH+1)
)(
    input wire [DATA_WIDTH-1:0] data,
    output wire [ZERO_WIDTH-1:0] zero_num
);

wire [ZERO_WIDTH-1:0] nmb [DATA_WIDTH:0];
assign nmb[DATA_WIDTH] = 0;
wire flag [0:DATA_WIDTH];
assign flag[DATA_WIDTH] = 0;

genvar i;
generate
    for (i = DATA_WIDTH-1; i >= 0; i = i - 1) begin: ZERO_SUM
        assign flag[i] = flag[i+1] || data[i];
        assign nmb[i] = (flag[i+1] || data[i]) ? 0 : (nmb[i+1] + 1); 
    end
endgenerate

assign zero_num = nmb[0];

endmodule
