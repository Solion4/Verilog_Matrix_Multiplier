`timescale 1ns/10ps

// Test bench module
module tb_lab6;

/////////////////////////////////////////////////////////
//                  Test Bench Signals                 //
/////////////////////////////////////////////////////////
reg clk;
integer i, k;
integer start_idx, end_idx;

// CSR Arrays and Vectors
reg signed [7:0]  matrixVal [63:0]; // 64 non-zero values
reg        [3:0]  matrixCol [63:0]; // 64 column indices (4-bit)
reg        [6:0]  matrixRow [16:0]; // 17 row pointers (7-bit)
reg signed [7:0]  vectorB   [15:0]; // 16x1 input vector
reg signed [18:0] vectorC   [15:0]; // 16x1 expected output vector

// Comparison Flag
reg comparison;

/////////////////////////////////////////////////////////
//                  I/O Declarations                   //
/////////////////////////////////////////////////////////
reg start;
reg reset;

wire done;
wire [10:0] clock_count;

/////////////////////////////////////////////////////////
//               Submodule Instantiation               //
/////////////////////////////////////////////////////////

matrix_multiply DUT
(
    .clk   (clk),
    .start (start),
    .reset (reset),
    .done       (done),
    .clock_count (clock_count)
);

initial begin
  
  // Initialize CSR Matrices and Vector
  $readmemb("val.txt", matrixVal);
  $readmemb("col.txt", matrixCol);
  $readmemb("row.txt", matrixRow); // Read the row pointers
  $readmemb("vec.txt", vectorB);
  
  // Setup Debugging Output
  // $monitor will print automatically whenever any of these signals change
  //$monitor("Time=%0t | State=%d | Row=%d | k=%d | Addr_val=%d | Addr_vec=%d | MAC_Out=%d | WE=%b", 
  //         $time, DUT.state, DUT.row, DUT.k, DUT.addr_val, DUT.addr_vec, DUT.mac_out, DUT.ram_C_we);
  
  /////////////////////////////////////////////////////////
  //                    Perform Test                     //
  /////////////////////////////////////////////////////////
  reset <= 1'b1;
  start <= 1'b0;
  clk <= 1'b0;
  repeat(2) @(posedge clk);
  reset <= 1'b0;
  repeat(2) @(posedge clk);
  start <= 1'b1;
  repeat(1) @(posedge clk);
  start <= 1'b0;
  
  // ------------------------
  // Wait for done or timeout
  fork : wait_or_timeout
  begin
    repeat(1500) @(posedge clk); // Increased timeout slightly for dynamic sizing
    disable wait_or_timeout;
  end
  begin
    @(posedge done);
    disable wait_or_timeout;
  end
  join
  // End Timeout Routing
  //-------------------------
  
  /////////////////////////////////////////////////////////
  //                Verify Computation                   //
  /////////////////////////////////////////////////////////
  
  // Generate Expected Result (Fully Dynamic SpMV CSR logic)
  for(i=0; i<16; i=i+1) begin
    vectorC[i] = 0;
    
	 // Use same algorithm
    // Extract start and end indices for the current row
    start_idx = matrixRow[i];
    end_idx   = matrixRow[i+1];
    
    // Loop only for the exact number of non-zero elements in this row
    for(k=start_idx; k<end_idx; k=k+1) begin
      // C[row] += Val[k] * VectorB[Col_Index[k]]
      vectorC[i] = vectorC[i] + matrixVal[k] * vectorB[matrixCol[k]];
    end
  end
  
  // Display Expected Result
  $display("\nExpected Result Vector C (16x1):");
  for(i=0; i<16; i=i+1) begin
    $display("[%2d] : %d", i, vectorC[i]);
  end
  
  // Display Output Matrix from RAM
  $display("\nGenerated Result from RAM:");
  for(i=0; i<16; i=i+1) begin
    $display("[%2d] : %d", i, DUT.RAMOUTPUT.mem[i]);
  end

  // Test if the two vectors match
  comparison = 1'b0;
  for(i=0; i<16; i=i+1) begin
      if (vectorC[i] != DUT.RAMOUTPUT.mem[i]) begin
        $display("Mismatch at index [%2d]: Expected %d, Got %d", i, vectorC[i], DUT.RAMOUTPUT.mem[i]);
        comparison = 1'b1;
      end
  end
  
  if (comparison == 1'b0) begin
    $display("\nsuccess :)");
  end
  
  $display("Running Time = %d clock cycles", clock_count);
  
  $stop; // End Simulation
end

// Clock
always begin
   #10;            // wait for initial block to initialize clock
   clk = ~clk;
end

endmodule