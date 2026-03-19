/* 
RAMOUTPUT.v
write the output RAM to this module,
required by manual to tast test-cases can properly run
*/

module RAMOUTPUT (
    input  wire clk,
    input  wire we,  
    input  wire [5:0] addr,     
    input  wire signed [18:0] data_in, 
    output reg  signed [18:0] data_out
);

    // 64x19 in column-major order
    reg signed [18:0] mem [0:63];

    // initialize the entire mem to 0 by default to avoid bugs
    integer i;
    initial begin
        for (i = 0; i < 64; i = i + 1) begin
            mem[i] = 19'sd0;
        end
    end

    always @(posedge clk) begin
        if (we) begin
            mem[addr] <= data_in;
        end
        data_out <= mem[addr];
    end

endmodule