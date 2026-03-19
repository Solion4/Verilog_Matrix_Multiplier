/*
RAM_dual.v
Dual-ported version of the input RAM_dualReads two values at once
*/


module RAM_dual #(
    parameter INIT_FILE = ""
)(
    input  wire                 clk,
    input  wire [5:0]           addr1,
    input  wire [5:0]           addr2,
    output reg  signed [7:0]    data_out1,
    output reg  signed [7:0]    data_out2
);

    reg signed [7:0] mem [0:63];

    initial begin
        if (INIT_FILE != "") begin
            $readmemb(INIT_FILE, mem);
        end
    end

    always @(posedge clk) begin
        data_out1 <= mem[addr1];
        data_out2 <= mem[addr2];
    end

endmodule