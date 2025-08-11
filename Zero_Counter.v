module Z_C #(
    parameter DATA_WIDTH = 16,
    parameter ZERO_WIDTH = $clog2(DATA_WIDTH+1) // Разрядность суммы(+1 так как нулей может быть 16)
    parameter LEFT_CNT = 0
)(
    input wire [DATA_WIDTH-1:0] data, // входные данные
    output wire [ZERO_WIDTH-1:0] zero_num // выходные данные
);

wire [ZERO_WIDTH-1:0] nmb [0:DATA_WIDTH]; //Хранение количества 0
assign nmb[DATA_WIDTH] = 0; //Начальное значение для сравнения в цикле
wire flag [0:DATA_WIDTH]; //Указатель на нахождение 1 после старших 0
assign flag[DATA_WIDTH] = 0; // 1 элемент равен 0(изначально ноль нулей)
wire [DATA_WIDTH-1:0] data_1;
genvar i;

generate if (LEFT_CNT==1) // Вопрос к модулю, успеет ли перевернуться входные данные, до срабатывания подсчета нулей
begin: cnt_high_bits
    assign data_1 = data;
end
else begin: cnt_low_bits
    for (i = 0; i<=DATA_WIDTH; i = i + 1) begin:
    assign data_1 = data[DATA_WIDTH-1-i];
    end
end
endgenerate


generate
    for (i = DATA_WIDTH-1; i >= 0; i = i - 1) begin: ZERO_SUM //Идем с левого конца
        assign flag[i] = flag[i+1] || data[i]; // поиск 1, если была найдена 1, то далее флаг будет выдавать 1 каждую итерацию, иначе 0(Флаг в обратную сторону, nmb слева направо)
        assign nmb[i] = (flag[i+1] || data[i]) ? nmb[i+1] : (nmb[i+1] + 1); // Если был флаг, то в ячейку записывает предыдущее, если нет, к предыдущему значению в ячейку +1, после нахождения первой единицы флаг всегда 1 и следоватенльно всегда записывется максимальное найденное число 0   
        end  
endgenerate

assign zero_num = nmb[0];

endmodule
