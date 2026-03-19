/*
RAM_input.v
A generic 64x8 RAM module to store matrix A and B.
Will be instantiated twice
*/

module RAM_input #( parameter INIT_FILE = "" )(
    input  wire clk,
    input  wire we,       
    input  wire [5:0] addr, // 64-bit address requires 6 bits
    input  wire signed [7:0] data_in,  
    output reg  signed [7:0] data_out
);

    // memory array
    reg signed [7:0] mem [0:63];

    // read the input file
    initial begin
        if (INIT_FILE != "") begin
            $readmemb(INIT_FILE, mem);
        end
    end

    always @(posedge clk) begin
        if (we) begin
            mem[addr] <= data_in;
        end
        data_out <= mem[addr];
    end

endmodule