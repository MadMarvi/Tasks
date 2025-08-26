module Zero_Counter #(
    parameter DATA_WIDTH = 16,
    parameter ZERO_WIDTH = $clog2(DATA_WIDTH+1),
    parameter LEFT_CNT = 1                  // 1 - считать старшие нули (слева), 0 - младшие (справа)
)(
    input wire [DATA_WIDTH-1:0] data,
    output wire [ZERO_WIDTH-1:0] zero_num
);

wire [DATA_WIDTH-1:0] data_reversed;
wire [ZERO_WIDTH-1:0] nmb [0:DATA_WIDTH];   //количество нулей
wire flag [0:DATA_WIDTH];                   //указатель на нахождение первой единицы

// Разворот данных, если нужно считать младшие нули
generate
    genvar i;
    for (i = 0; i < DATA_WIDTH; i = i + 1) begin: reverse_data
        assign data_reversed[i] = data[DATA_WIDTH-1-i];
    end
endgenerate

wire [DATA_WIDTH-1:0] data_processed = (LEFT_CNT) ? data : data_reversed;

assign flag[DATA_WIDTH] = 0;
assign nmb[DATA_WIDTH] = 0;

// Подсчет нулей
generate
    for (i = DATA_WIDTH-1; i >= 0; i = i - 1) begin: count_zeros
        assign flag[i] = flag[i+1] || data_processed[i];
        assign nmb[i] = (flag[i+1] || data_processed[i]) ? nmb[i+1] : (nmb[i+1] + 1);
    end
endgenerate

assign zero_num = nmb[0];

endmodule
