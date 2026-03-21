// ahb_lite.sv
// David_Harris@hmc.edu 3 January 2014
// Simple AHB bus
//

module testbench;
  logic HCLK, HRESETn, HWRITE;
  logic [31:0] HADDR, HWDATA, HRDATA, HREXPECTED;
  tri   [31:0] pins;
  
  logic [97:0] vectors[1000];
  logic [97:0] vnow, vprev;
  int          curvec;
  int          errors;
  
  initial begin
  	$readmemh("ahb_vectors.dat", vectors);
  	curvec = 1;
  	errors = 0;
  end
  	
  initial begin
    HRESETn <= 0; #110;
    HRESETn <= 1; 
  end
  
  initial 
    forever begin
      HCLK <= 1; #50; 
      HCLK <= 0; #50;
    end
    
  assign vnow = vectors[curvec];
  assign vprev = vectors[curvec-1];
    
  always @(posedge HCLK) begin
    #1;
    if (vectors[curvec][97]) begin
      $display("%d vectors applied with %d errors", curvec, errors);
      $stop;
    end
    HWRITE <= vnow[96];
    HADDR  <= vnow[95:64];
    HWDATA <= vprev[63:32];
    HREXPECTED <= vprev[31:0];
  end
  
  always @(negedge HCLK) begin
    if (HREXPECTED != HRDATA) begin
      $display("Vector %d read match: %h / %h expected\n",
        curvec, HRDATA, HREXPECTED);
      errors++;
    end
    curvec++;
  end
  
  // DUT
  ahb_lite dut(HCLK, HRESETn, HADDR, HWRITE, HWDATA, HRDATA, pins);
  
  // drive some input pins
  assign pins[31:28] = 4'h6;
endmodule
  