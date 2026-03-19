/*
matrix_multiply_opt.v
Top-level module for task 4. 
Uses four MAC instances and dual-port RAMs
Calculates four results simultaneously
*/

`timescale 1ns / 1ns

module matrix_multiply_opt(
    input  wire clk,
    // start signal.  Module doesn't begin calculation until this signal is asserted high
    input  wire start, 
    // should reset module to its default waiting state. should NOT clear contents of ram
    input  wire reset,
    
    // completion signal. should be '0' while module is running, and '1' when multiplication complete
    output reg done,
    // tracking number of elapsed clock cycles. Increments by 1 every clock cycle until done multiplication
    output reg [10:0] clock_count
);

    // fsm state tracker
    localparam IDLE  = 2'd0;
    localparam RUN   = 2'd1;
    localparam DRAIN = 2'd2;
    localparam DONE  = 2'd3;
    
    reg [1:0] state;

    // Loop Counters
    reg [3:0] k;   // Inner loop, 0-9
    reg [2:0] row; // Rows 0-7
    reg [2:0] col; // Cols 0-7
    
    // RAM Signals
    reg  [5:0] addr_A;
    reg  [5:0] addr_A2;
    reg  [5:0] addr_B;
    reg  [5:0] addr_B2; 
    wire [5:0] addr_C;
    wire [5:0] addr_C2; 
    
    wire signed [7:0]  data_out_A;
    wire signed [7:0]  data_out_A2;
    wire signed [7:0]  data_out_B;
    wire signed [7:0]  data_out_B2; 
     
    wire signed [18:0] mac_out;
    wire signed [18:0] mac_out2;
    wire signed [18:0] mac_out3; 
    wire signed [18:0] mac_out4; 
    
    reg  signed [18:0] mac_out2_buffer;
    reg  signed [18:0] mac_out3_buffer; 
    reg  signed [18:0] mac_out4_buffer; 
    wire signed [18:0] mac_out_mux;
     
    // Control Signals
    reg macc_clear;
    reg ram_C_we;
    reg [2:0] write_row;
    reg [2:0] write_row2;
    reg [2:0] write_col;
    reg [2:0] write_col2;

    // Instantiate Input RAM_A
    RAM_dual #(.INIT_FILE("ram_a_init.txt")) RAM_A (
        .clk(clk),
        .addr1(addr_A),
        .addr2(addr_A2),
        .data_out1(data_out_A),
        .data_out2(data_out_A2)
    );
     
    // Instantiate Input RAM_B (Changed to Dual Port for 4 MACs)
    RAM_dual #(.INIT_FILE("ram_b_init.txt")) RAM_B (
        .clk(clk),
        .addr1(addr_B),
        .addr2(addr_B2),
        .data_out1(data_out_B),
        .data_out2(data_out_B2)
    );

    // MAC Unit Instantiation
    MAC MAC_Unit1 (
        .clk(clk),
        .reset(reset),
        .macc_clear(macc_clear),
        .A(data_out_A),
        .B(data_out_B),
        .out(mac_out)
    );
     
    MAC MAC_Unit2 (
        .clk(clk),
        .reset(reset),
        .macc_clear(macc_clear),
        .A(data_out_A2),
        .B(data_out_B),
        .out(mac_out2)
    );
    
    // Added MAC 3 and 4
    MAC MAC_Unit3 (
        .clk(clk),
        .reset(reset),
        .macc_clear(macc_clear),
        .A(data_out_A),
        .B(data_out_B2),
        .out(mac_out3)
    );
     
    MAC MAC_Unit4 (
        .clk(clk),
        .reset(reset),
        .macc_clear(macc_clear),
        .A(data_out_A2),
        .B(data_out_B2),
        .out(mac_out4)
    );
     

    // automatically creating 8 by 8 matrix
    // Column Major Order - Expanded to 4 cycles
    assign addr_C = (k == 2) ? {write_col, write_row} : 
                    (k == 4) ? {write_col, write_row2} : 
                    (k == 6) ? {write_col2, write_row} : 
                               {write_col2, write_row2};
	 
    //                           
    assign mac_out_mux = (k == 2) ? mac_out : 
                         (k == 4) ? mac_out2_buffer : 
                         (k == 6) ? mac_out3_buffer : 
                                    mac_out4_buffer;
     
     
    RAMOUTPUT RAMOUTPUT (
        .clk(clk),
        .we(ram_C_we),
        .addr(addr_C),
        .data_in(mac_out_mux),
        .data_out() // output only used by testbench for verification
    );

    // control logic
    always @(posedge clk) begin
         // If reset, we set all values to 0. Notice what if we were in state done, everything is reset again
        if (reset) begin
            state <= IDLE;
            done <= 1'b0; // by default, we aren't done
            clock_count <= 11'd0; // by default, start with 0 clock cycles
            row <= 0;
            col <= 0;
            k <= 0;
            ram_C_we <= 1'b0;
            macc_clear <= 1'b0;
            addr_A <= 0;
            addr_A2 <= 0;
            addr_B <= 0;
            addr_B2 <= 0;
            write_col <= 0;
            write_col2 <= 0;
            write_row <= 0;
            write_row2 <= 0;
        end 
        else begin
            case (state)
                /*
                STATE 1: IDLE
                We stay in the idle state until start is 1
                Then, go to RUN state
                */
                IDLE: begin
                    if (start) begin
                        state <= RUN;
                        done <= 0;
                        clock_count <= 0;
                         
                        row <= 0;
                        col <= 0;
                        k <= 0;
                        addr_A <= 0; // random values
                        addr_A2 <= 0;
                        addr_B <= 0;
                        addr_B2 <= 0;
                        macc_clear <= 1'b1; // clear mac so it's 0

                    end
                end
                /*
                STATE 2: RUN
                Perform computational logic, update C values. 
                Continue until evey C matrix value has been updated 
                */
                RUN: begin
                    clock_count <= clock_count + 1;
                    k <= k + 1;
                     
                    if (k < 8) begin
                        addr_A <= ( k << 3) + row;
                        addr_A2 <= ( k << 3) + row + 1;
                        addr_B <= (col << 3) + k;
                        addr_B2 <= ((col + 1) << 3) + k; 
                    end
                     
                    if (k == 1) begin
                        macc_clear <= 1'b1;
                    end else begin
                        macc_clear <= 1'b0;
                    end
                     
                    if (k == 7) begin
                        k <= 0;
                        
                        write_row <= row;
                        write_col <= col;
                        write_row2 <= row + 1;
                        write_col2 <= col + 1; 
                        
                        //Update all 64 rows and columns accordingly
                        if (row == 6) begin
                            row <= 0;
                            
                            // Check against 6 instead of 7 because we process 2 cols at once
                            if (col == 6) begin
                                state <= DRAIN;
                            end else begin
                                col <= col + 2; // Jump by 2
                            end
                        end else begin
                            row <= row + 2;
                        end
                    end
                     
                    // Simplified write enable logic for 4 cycles
                    if (clock_count > 5 & (k == 1 | k == 3 | k == 5 | k == 6)) begin
                        ram_C_we <= 1'b1;
                    end else begin
                        ram_C_we <= 1'b0;
                    end
                     
                    // Buffer MAC outputs 2, 3, and 4
                    if (clock_count > 5 & k == 2) begin
								
                        mac_out2_buffer <= mac_out2;
                        mac_out3_buffer <= mac_out3;
                        mac_out4_buffer <= mac_out4;
                    end             
                end
                     
                DRAIN: begin
                    clock_count = clock_count + 1;
                    k <= k + 1;
                     
                    if (clock_count > 5 & (k == 1 | k == 3 | k == 5 | k == 6)) begin
                        ram_C_we <= 1'b1;
                    end else begin
                        ram_C_we <= 1'b0;
                    end
                     
                    if (clock_count > 5 & k == 2) begin
                        mac_out2_buffer <= mac_out2;
                        mac_out3_buffer <= mac_out3;
                        mac_out4_buffer <= mac_out4;
                    end
                     
                    // Changed from 3 to 7 so all 4 writes can finish draining
                    if (k == 7) begin
                        state <= DONE;
                    end
                end  
                     
                DONE: begin
                    done <= 1'b1;
                    ram_C_we <= 1'b0;
                    // stay here until reset
                end
                
            endcase
        end
    end

endmodule