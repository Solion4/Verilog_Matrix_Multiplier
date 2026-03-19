// testbench for multiply-accumulator MAC unit

`timescale 1ns / 1ps

module tb_MAC;

    // Inputs
    reg clk;
    reg reset;   
    reg macc_clear;
    reg signed [7:0] A;
    reg signed [7:0] B;
    
    // Outputs
    wire signed [18:0] out;

    MAC uut (
        .clk(clk), 
        .reset(reset),
        .macc_clear(macc_clear), 
        .A(A), 
        .B(B), 
        .out(out)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1; // start with reset enabled
        macc_clear = 0;
        A = 0;
        B = 0;

        // Monitor changes in console
        $monitor("Time=%0t | Reset=%b Clear=%b | A=%d B=%d | Out=%d", 
                 $time, reset, macc_clear, A, B, out);

        #20;
        reset = 0;
        $display("--- Reset Released ---");

        // ---------------------------------------------------------
        // TEST CASE 1: Simple Multiply & Accumulate (Positive)
        // ---------------------------------------------------------
        // Operation: out = 0 + (2 * 5) = 10
        @ (negedge clk);
        A = 8'd2; 
        B = 8'd5;
        
        // Operation: out = 10 + (3 * 4) = 22
        @ (negedge clk);
        A = 8'd3; 
        B = 8'd4;

        // ---------------------------------------------------------
        // TEST CASE 2: macc_clear Behavior
        // ---------------------------------------------------------
        // Operation: Clear should discard '22'. 
        // Expected: out = (10 * 10) = 100 (NOT 122)
        @ (negedge clk);
        macc_clear = 1;
        A = 8'd10; 
        B = 8'd10;

        // ---------------------------------------------------------
        // TEST CASE 3: Signed Arithmetic (Negative Numbers)
        // ---------------------------------------------------------
        // Operation: Resume accumulation. 
        // Expected: out = 100 + (-5 * 2) = 90
        @ (negedge clk);
        macc_clear = 0;
        A = -8'd5; 
        B = 8'd2;

        // Operation: Negative * Negative
        // Expected: out = 90 + (-2 * -3) = 96
        @ (negedge clk);
        A = -8'd2; 
        B = -8'd3;

        // ---------------------------------------------------------
        // TEST CASE 4: Reset during operation
        // ---------------------------------------------------------
        @ (negedge clk);
        reset = 1;
        A = 50; B = 2; // should not matter
        
        #20;
        
        $display("--- Test Completed ---");
        $stop;
    end
      
endmodule