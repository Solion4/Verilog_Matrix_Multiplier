// Contains the core ALU 
// Takes two 8-unit inputs and accumulates them into a 19-bit output

// Should be fast, either does just multiplication,
// Or both multiplication and addition

module MAC (
    input  wire  clk, reset, macc_clear,  
    input  wire signed [7:0] A,
    input  wire signed [7:0] B,
    output reg  signed [18:0] out
);
    wire signed [18:0] product = $signed(A) * $signed(B);
    always @(posedge clk) begin
        if (reset) begin
            out <= 19'd0;
        end 
        else begin
            if (macc_clear) begin
                out <= product; // once we have done multiplication, assert product       
            end 
            else begin
                out <= out + product;
            end
        end
    end

endmodule