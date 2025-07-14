module testbench;
    
    parameter DATA_W = 8;

    reg                 clk=0;
    reg                 reset=1;

    reg                 write, read;
    reg [DATA_W-1:0]    datain;

    wire                val_sh, val_cr;
    wire                full_sh, full_cr;
    wire [DATA_W-1:0]   dataot_sh, dataout_cr;

    always
        #1 clk = ~clk;

    initial begin
        repeat (3) @(posedge clk);
        reset <= 1'b0;
        #100000
        $finish();
    end

    ring_fifo #(
        .DEPTH(16),
        .DATA_WIDTH(DATA_W)
    ) fifo_sh (
        .clk(clk),
        .reset(reset),
        .write(write),
        .datain(datain),
        .read(read),
        .dataout(dataot_sh),
        .val(val_sh),
        .full(full_sh)
    );

    fifo #(
        .DEPTH(16),
        .DATA_WIDTH(DATA_W)
    ) fifo_cr (
        .clk(clk),
        .reset(reset),
        .write(write),
        .datain(datain),
        .read(read),
        .dataout(dataout_cr),
        .val(val_cr),
        .full(full_cr)
    );

    always @(posedge clk)
    begin
        datain  <= ($random())%(1<<DATA_W);
        write   <=  $random()%2;
        read    <=  ($random()%2) & ~read ;
    end

    always @(negedge clk)
    begin
        if( val_sh !== val_cr) begin
            $display("VAL ERROR");
            $stop();
        end
        else (val_sh & (dataot_sh !== dataot_cr))begin
            $display("DATA ERROR");
            $stop();
        end
        if( full_sh !== full_cr) begin
            $display("FULL ERROR");
            $stop();
        end
    end

endmodule
