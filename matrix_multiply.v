/*
matrix_multiply.v
Top-level module for task 2. 
We instantiate two RAM_input modules
We instantiate a RAMOUTPUT
We instantiate a MAC
We use a basic FSM for control logic
Lengthy, but still generally straightforward
Hint: Follow block diagram
*/

`timescale 1ns / 1ns

module matrix_multiply(
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
    localparam IDLE = 2'd0;
    localparam RUN  = 2'd1;
	 localparam DRAIN = 2'd2;
    localparam DONE = 2'd3;
    
    reg [1:0] state;

    // Loop Counters
    reg [3:0] k;   // Inner loop, 0-9
    reg [2:0] row; // Rows 0-7
    reg [2:0] col; // Cols 0-7
    
    // RAM Signals
    reg  [5:0] addr_A;
    reg  [5:0] addr_B;
    wire [5:0] addr_C;
    
    wire signed [7:0]  data_out_A;
    wire signed [7:0]  data_out_B;
    wire signed [18:0] mac_out;
	 
    
    // Control Signals
    reg macc_clear;
    reg ram_C_we;
	 reg [2:0] write_row;
	 reg [2:0] write_col;

    // Instantiate Input RAM_A
    RAM_input #(.INIT_FILE("ram_a_init.txt")) RAM_A (
        .clk(clk),
        .addr(addr_A),
		  .we(1'b0),
		  .data_in(8'b0),
        .data_out(data_out_A)
    );

    // Instantiate Input RAM_B
    RAM_input #(.INIT_FILE("ram_b_init.txt")) RAM_B (
        .clk(clk),
        .addr(addr_B),
		  .we(1'b0),
		  .data_in(8'b0),
        .data_out(data_out_B)
    );

    // MAC Unit Instantiation
    MAC MAC_Unit (
        .clk(clk),
        .reset(reset),
        .macc_clear(macc_clear),
        .A(data_out_A),
        .B(data_out_B),
        .out(mac_out)
    );

    // automatically creating 8 by 8 matrix
    // Column Major Order
    assign addr_C = {write_col, write_row};
    
    RAMOUTPUT RAMOUTPUT (
        .clk(clk),
        .we(ram_C_we),
        .addr(addr_C),
        .data_in(mac_out),
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
            addr_B <= 0;
				write_col <= 0;
				write_row <= 0;
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
								  addr_A <= 100; // random values
								  addr_B <= 100;
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
								 addr_B <= (col << 3) + k;
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
								
								// Update all 64 rows and columns accordingly
								if (row == 7) begin
                            row <= 0;
                            
                            if (col == 7) begin
                                state <= DRAIN;
                            end else begin
                                col <= col + 1;
									 end
                         end else begin
                                row <= row + 1;
                        end
								
						  end
						  
						  // writin on next iteration, from previous
						  if (clock_count > 5 & k == 1) begin
						      // are we writing to the correct row? 
								// doesn't seem like it right now
							   ram_C_we <= 1'b1;
						  end else begin
						      ram_C_we <= 1'b0;
						  end
						  
					  end  
					  
					  DRAIN: begin
					     clock_count <= clock_count + 1;
					  
						  if (k < 8) begin
						       addr_A <= ( k << 3) + row;
								 addr_B <= (col << 3) + k;

						  end
					  
					     k <= k + 1;
						  
						  if (k == 1) begin
						      ram_C_we <= 1'b1;
						  end else begin
						      ram_C_we <= 1'b0;
						  end
						  
						  if (k == 3) begin
						     state <= DONE;
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


