/*
matrix_multiply_spmv_dynamic.v
Top-level module for Task 4 Extra Credit. 
Fully dynamic SpMV based on the CSR format using provided .txt files.
16x16 matrix, 16x1 vector, handles variable non-zero elements per row.
*/

`timescale 1ns / 1ps

module matrix_multiply(
    input  wire clk,
    input  wire start, 
    input  wire reset,
    output reg done,
    output reg [10:0] clock_count
);

    // fsm state tracker
    localparam IDLE = 2'd0;
    localparam RUN  = 2'd1;
    localparam DONE = 2'd2;
    
    reg [1:0] state;

    // Loop Counters
    reg [6:0] k;   // Inner loop, dynamically sizes to row length
    reg [3:0] row; // Rows 0-15
    
    // RAM Signals
    reg  [5:0] addr_val;
    reg  [5:0] addr_vec;
    wire [5:0] addr_C;
    
    wire signed [7:0]  data_out_val;
    wire signed [7:0]  data_out_vec;
    wire signed [18:0] mac_out;
    
    // Control Signals
    reg macc_clear;
    reg ram_C_we;

    // load col.txt
	 // col_ind specifies at what column each value is actually at
    reg [3:0] col_ind [0:63];
    initial $readmemb("col.txt", col_ind);

    // load row.txt
    // 17 elements, using 7 bits to store values up to 64
    reg [6:0] row_ptr [0:16];
    initial $readmemb("row.txt", row_ptr);

    // the row_ptr at every row gives the total number of elements up to that row. 
	 // To determine the number of elements for a specific row, 
	 // we look at the total elements for a row, and the next row, and then subtract the two
    wire [6:0] start_idx = row_ptr[row];
    wire [6:0] end_idx   = row_ptr[row + 1];
    wire [6:0] num_elements = end_idx - start_idx;

    // Instantiate Input RAM_VAL (Holds the 64 non-zero Matrix values)
    RAM_input #(.INIT_FILE("val.txt")) RAM_VAL (
        .clk(clk),
        .we(1'b0),     
        .addr(addr_val),
        .data_in(8'd0),
        .data_out(data_out_val)
    );

    // Instantiate Input RAM_VEC (Holds the 16 Vector values)
    RAM_input #(.INIT_FILE("vec.txt")) RAM_VEC (
        .clk(clk),
        .we(1'b0),
        .addr(addr_vec),
        .data_in(8'd0),
        .data_out(data_out_vec)
    );

    // MAC Unit Instantiation
    MAC MAC_Unit (
        .clk(clk),
        .reset(reset),
        .macc_clear(macc_clear),
        .A(data_out_val),
        .B(data_out_vec),
        .out(mac_out)
    );

    // Output Vector C is 16x1, map directly to row
    assign addr_C = {2'b00, row}; 
    
    RAMOUTPUT RAMOUTPUT (
        .clk(clk),
        .we(ram_C_we),
        .addr(addr_C),
        .data_in(mac_out),
        .data_out() // output only used by testbench for verification
    );

    // control logic
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            done <= 1'b0;
            clock_count <= 11'd0;
            row <= 0;
            k <= 0;
            ram_C_we <= 1'b0;
            macc_clear <= 1'b0;
            addr_val <= 0;
            addr_vec <= 0;
        end 
        else begin
            case (state)
            
                // case 1: IDLE
                IDLE: begin
                    if (start) begin
                        state <= RUN;
                        clock_count <= 0;
                        done <= 0;
                        
                        row <= 0;
                        k <= 0;
                        // Pre-fetch the first element of row 0
                        addr_val <= row_ptr[0]; 
                        addr_vec <= col_ind[row_ptr[0]]; 
                    end
                end

                RUN: begin
                    clock_count <= clock_count + 1;
						  
						  
                    if (k < row_ptr[row + 1]) begin
                        addr_val <= k;
                        addr_vec <= col_ind[k];
                    end
                    
                    if (k == row_ptr[row] + 1) begin
                        macc_clear <= 1'b1;
                    end else begin
                        macc_clear <= 1'b0;
                    end
                        
                    if (k == row_ptr[row + 1] + 1) begin
                        ram_C_we <= 1'b1;
                    end else begin
                        ram_C_we <= 1'b0;
                    end

                    if (k == row_ptr[row + 1] + 2) begin
                        // We just triggered the write for the current row.
                        if (row == 15) begin
                            state <= DONE;
                        end else begin
                            // Move to the next row
                            row <= row + 1;
                            // Reset k to the absolute start index of the new row
                            k <= row_ptr[row + 1];
                        end
                    end else begin
                        // Keep incrementing our absolute index
                        k <= k + 1;
                    end
                    
						  
                end

                DONE: begin
                    done <= 1'b1;
                    ram_C_we <= 1'b0;
                    // Stay until reset
                end      
            endcase
        end
    end

endmodule