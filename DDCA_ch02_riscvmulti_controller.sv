// risc-v multicycle controller testbench
// Josh Brake
// jbrake@hmc.edu
// 4/15/2020

module testbench();
  logic        clk;
  logic        reset;
  
  logic [6:0]  op;
  logic [2:0]  funct3;
  logic        funct7b5;
  logic        Zero;
  logic [1:0]  ImmSrc;
  logic [1:0]  ALUSrcA, ALUSrcB;
  logic [1:0]  ResultSrc;
  logic        AdrSrc;
  logic [2:0]  ALUControl;
  logic        IRWrite, PCWrite;
  logic        RegWrite, MemWrite;
  
  logic [31:0] vectornum, errors;
  logic [39:0] testvectors[10000:0];
  
  logic [15:0] actual, expected;


  // instantiate device to be tested
  controller dut(clk, reset, op, funct3, funct7b5, Zero,
                 ImmSrc, ALUSrcA, ALUSrcB, ResultSrc, AdrSrc, ALUControl, IRWrite, PCWrite, RegWrite, MemWrite);
  
  // generate clock
  always 
    begin
      clk = 1; #5; clk = 0; #5;
    end

  // at start of test, load vectors
  // and pulse reset
  initial
    begin
      $readmemb("controller.tv", testvectors);
      vectornum = 0; errors = 0;
      reset = 1; #22; reset = 0;
    end
	 
  // apply test vectors on rising edge of clk
  always @(posedge clk)
    begin
      #1; {op, funct3, funct7b5, Zero, expected} = testvectors[vectornum];
    end

  // check results on falling edge of clk
  always @(negedge clk)
    if (~reset) begin // skip cycles during reset
      actual = {ImmSrc, ALUSrcA, ALUSrcB, ResultSrc, AdrSrc, ALUControl, IRWrite, PCWrite, RegWrite, MemWrite};
      
      if (actual !== expected) begin  // check result
        $display("Error on vector %d: inputs: op = %h funct3 = %h funct7b5 = %h; outputs = %h (%h expected)", 
			  vectornum, op, funct3, funct7b5, actual, expected); 
  	    // provide some detailed errors to help debug
  	     if (expected[15:14] !== 2'bx)
          if (ImmSrc !== expected[15:14])   $display("   ImmSrc = %b.  Expected %b", ImmSrc, expected[15:14]);
        if (ALUSrcA !== expected[13:12])    $display("   ALUSrcA = %b.  Expected %b", ALUSrcA, expected[13:12]);
        if (ALUSrcB !== expected[11:10])    $display("   ALUSrcB = %b.  Expected %b", ALUSrcB, expected[11:10]);
        if (ResultSrc !== expected[9:8])     $display("   ResultSrc = %b.  Expected %b", ResultSrc, expected[9:8]);
        if (AdrSrc !== expected[7])      $display("   AdrSrc = %b.  Expected %b", AdrSrc, expected[7]);
        if (ALUControl !== expected[6:4])    $display("   ALUControl = %b.  Expected %b", ALUControl, expected[6:4]);
        if (IRWrite !== expected[3])      $display("   IRWrite = %b.  Expected %b", IRWrite, expected[3]);
        if (PCWrite !== expected[2])    $display("   PCWrite = %b.  Expected %b", PCWrite, expected[2]);
        if (RegWrite !== expected[1])  $display("   RegWrite = %b.  Expected %b", RegWrite, expected[1]);
        if (MemWrite !== expected[0])     $display("   MemWrite = %b.  Expected %b", MemWrite, expected[0]);		
	      errors = errors + 1;
      end

      vectornum = vectornum + 1;

      if (testvectors[vectornum] === 'bx) begin 
        $display("%d tests completed with %d errors", 
	         vectornum, errors);
        $stop;
      end
    end

endmodule

// RISC-V Multicycle Controller
// Sarah.Harris@unlv.edu
// David_Harris@hmc.edu
// July 2021

module controller(input  logic       clk,
                  input  logic       reset,  
                  input  logic [6:0] op,
                  input  logic [2:0] funct3,
                  input  logic       funct7b5,
                  input  logic       Zero,
                  output logic [1:0] ImmSrc,
                  output logic [1:0] ALUSrcA, ALUSrcB,
                  output logic [1:0] ResultSrc, 
                  output logic       AdrSrc,
                  output logic [2:0] ALUControl,
                  output logic       IRWrite, PCWrite, 
                  output logic       RegWrite, MemWrite);

  logic [1:0] ALUOp;
  logic       Branch, PCUpdate;

  // Main FSM
  mainfsm fsm(clk, reset, op,
              ALUSrcA, ALUSrcB, ResultSrc, AdrSrc, 
              IRWrite, PCUpdate, RegWrite, MemWrite, 
              ALUOp, Branch);

  // ALU Decoder
  aludec  ad(op[5], funct3, funct7b5, ALUOp, ALUControl);
  
  // Instruction Decoder
  instrdec id(op, ImmSrc);
  
  // Branch logic
  assign PCWrite = (Branch & Zero) | PCUpdate; 
  
endmodule

module mainfsm(input  logic         clk,
               input  logic         reset,
               input  logic [6:0]   op,
               output logic [1:0]   ALUSrcA, ALUSrcB,
               output logic [1:0]   ResultSrc,
               output logic         AdrSrc,  
               output logic         IRWrite, PCUpdate,
               output logic         RegWrite, MemWrite,
               output logic [1:0]   ALUOp,
               output logic         Branch);  
              
  typedef enum logic [3:0] {FETCH, DECODE, MEMADR, MEMREAD, MEMWB, MEMWRITE, 
                            EXECUTER, EXECUTEI, ALUWB, 
                            BEQ, JAL, UNKNOWN} statetype;
  
  statetype state, nextstate;
  logic [14:0] controls;
  
  // state register
  always @(posedge clk or posedge reset)
    if (reset) state <= FETCH;
    else state <= nextstate;
  
  // next state logic
  always_comb
    case(state)
      FETCH:                     nextstate = DECODE;
      DECODE: casez(op)
                7'b0?00011:      nextstate = MEMADR;    // lw or sw
                7'b0110011:      nextstate = EXECUTER;  // R-type
                7'b0010011:      nextstate = EXECUTEI;  // addi
                7'b1100011:      nextstate = BEQ;       // beq
                7'b1101111:      nextstate = JAL;       // jal
                default:         nextstate = UNKNOWN;
              endcase
      MEMADR: 
        if (op[5])               nextstate = MEMWRITE;  // sw
        else                     nextstate = MEMREAD;   // lw
      MEMREAD:                   nextstate = MEMWB;
      EXECUTER:                  nextstate = ALUWB;
      EXECUTEI:                  nextstate = ALUWB;
      JAL:                       nextstate = ALUWB;
      default:                   nextstate = FETCH; 
    endcase
    
  // state-dependent output logic
  always_comb
    case(state)
      FETCH: 	controls = 15'b00_10_10_0_1100_00_0; 
      DECODE:  	controls = 15'b01_01_00_0_0000_00_0;      
      MEMADR:  	controls = 15'b10_01_00_0_0000_00_0;
      MEMREAD:  controls = 15'b00_00_00_1_0000_00_0;
      MEMWRITE: controls = 15'b00_00_00_1_0001_00_0;
      MEMWB:   	controls = 15'b00_00_01_0_0010_00_0;
      EXECUTER:	controls = 15'b10_00_00_0_0000_10_0;
      EXECUTEI: controls = 15'b10_01_00_0_0000_10_0;
      ALUWB:    controls = 15'b00_00_00_0_0010_00_0;
      BEQ:  	controls = 15'b10_00_00_0_0000_01_1;
      JAL:  	controls = 15'b01_10_00_0_0100_00_0;
      default: 	controls = 15'bxx_xx_xx_x_xxxx_xx_x;
    endcase

  assign {ALUSrcA, ALUSrcB, ResultSrc, AdrSrc, IRWrite, PCUpdate, 
  RegWrite, MemWrite, ALUOp, Branch} = controls;
          
endmodule  

module aludec(input  logic       opb5,
              input  logic [2:0] funct3,
              input  logic       funct7b5, 
              input  logic [1:0] ALUOp,
              output logic [2:0] ALUControl);

  logic  RtypeSub;
  assign RtypeSub = funct7b5 & opb5;  // TRUE for R-type subtract instruction

  always_comb
    case(ALUOp)
      2'b00:                ALUControl = 3'b000; // addition
      2'b01:                ALUControl = 3'b001; // subtraction
      default: case(funct3) // R-type or I-type ALU
                 3'b000:  if (RtypeSub) 
                            ALUControl = 3'b001; // sub
                          else          
                            ALUControl = 3'b000; // add, addi
                 3'b010:    ALUControl = 3'b101; // slt, slti
                 3'b110:    ALUControl = 3'b011; // or, ori
                 3'b111:    ALUControl = 3'b010; // and, andi
                 default:   ALUControl = 3'bxxx; // ???
               endcase
    endcase
endmodule

module instrdec (input  logic [6:0] op, 
                 output logic [1:0] ImmSrc);
  always_comb
    case(op)
      7'b0110011: ImmSrc = 2'bxx; // R-type
      7'b0010011: ImmSrc = 2'b00; // I-type ALU
      7'b0000011: ImmSrc = 2'b00; // lw
      7'b0100011: ImmSrc = 2'b01; // sw
      7'b1100011: ImmSrc = 2'b10; // beq
      7'b1101111: ImmSrc = 2'b11; // jal
      default:    ImmSrc = 2'bxx; // ???
    endcase
endmodule

