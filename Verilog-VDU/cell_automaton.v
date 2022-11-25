// Verilog HDL for "COMP32211", "drawing_dummy" "functional"
// This is an inactive cell which takes the place of a drawing function.
// It 'ties off' outputs tidily.

`define TPD 2

module cell_automaton(input  wire        clk,
                      input  wire        req,
                      output reg         ack,
                      output wire        busy,
                      output wire        de_req,
                      input  wire        de_ack,
                      output wire [17:0] de_addr,
                      output wire  [3:0] de_nbyte,
                      output wire [31:0] de_w_data);


reg [3:0] nbyte;
reg [17:0] addr;
reg int_req, int_busy;
reg [7:0] addr_A,addr_B,addr_C,addr_D,addr_E,addr_F;
reg [3:0] A, B, C, D, E, F;
reg RAM_r, RAM_w, stall;

//contnuous assignment
assign busy = int_busy;
assign de_addr = addr;
assign de_req = int_req;
assign de_nbyte = nbyte;
assign de_w_data = 32'hFFFF_FFFF;

//RAM on the FPGA
reg [3:0] block_RAM_A [0:159];
reg [3:0] block_RAM_B [0:159];
reg [3:0] block_RAM_C [0:159];
reg [3:0] block_RAM_D [0:159];
reg [3:0] block_RAM_E [0:159];
reg [3:0] block_RAM_F [0:159];
reg [1:0] stage;
reg line;

/* Line Ordering
* 1 -> Writing and Calculating ABC, Reading DEF
* 0 -> Writing and Calculating DEF, Reading ABC
*/

/* Stage Ordering
* 00 -> Write C
     -> Calculate A
     -> Read F

* 01 -> Write A 
     -> Calculate B
     -> Read D

* 10 -> Write B
     -> Calculate C
     -> Read E
*/

//for reads from RAM-> read data in preparation for next stage
always @ (posedge clk) begin 
  if(!stall && RAM_r) begin
    if (line) begin
      case(stage)
      2'b00:   begin
        F = block_RAM_F[addr_F];
        addr_F += 3; end
      2'b01:   begin
        D = block_RAM_D[addr_D];
        addr_D += 3; end
      default: begin
        E = block_RAM_E[addr_E];
        addr_E += 3; end
      endcase
    end
    if (!line) begin
      case(stage)
      2'b00:   begin
        C = block_RAM_C[addr_C];
        addr_C += 3; end
      2'b01:   begin
        A = block_RAM_A[addr_A];
        addr_A += 3; end
      default: begin
        B = block_RAM_B[addr_B];
        addr_B += 3; end
      endcase
    end
    RAM_r = 0;
  end
end

//for memory writes to the VDU
always @ (posedge clk) begin
  @ (addr);
  int_req = 1;
  stall = 1;
  @(de_ack);
  stall = 0;
  int_req = 0;
end 

//for writes to RAM-> write data calculated previous stage
always @ (posedge clk) begin
  if (!stall && RAM_w) begin
    if (line) begin
      case(stage)
      2'b00:   begin
        block_RAM_C[addr_C] = C;
        nbyte = C;
        addr_C += 3; end
      2'b01:   begin
        block_RAM_A[addr_A] = A;
        nbyte = A;
        addr_A += 3; end
      default: begin
        block_RAM_B[addr_B] = B;
        nbyte = B;
        addr_B += 3; end
      endcase
    end
    if (!line) begin
      case(stage)
      2'b00:   begin
        block_RAM_F[addr_F] = F;
        nbyte = F;
        addr_F += 3; end
      2'b01:   begin
        block_RAM_D[addr_D] = D;
        nbyte = D;
        addr_D += 3; end
      default: begin
        block_RAM_E[addr_E] = E;
        nbyte = E;
        addr_E += 3; end 
      endcase
    end
    addr += 1;
    RAM_w = 0;
  end
end

//for calculation -> calculate current
always @ (posedge clk) begin
  if (!stall) begin
    if (line) begin
      case(stage)
      2'b00:   A = newline({F[3],D[3:0],E[0]});
      2'b01:   B = newline({D[3],E[3:0],F[0]});
      default: C = newline({E[3],F[3:0],D[0]});
      endcase
    end
    if (!line) begin
      case(stage)
      2'b00:   A = newline({C[3],A[3:0],B[0]});
      2'b01:   B = newline({A[3],B[3:0],C[0]});
      default: C = newline({B[3],C[3:0],A[0]});
      endcase
    end
  end
end

//Detecting End of Line Switches
always @ (posedge clk) begin
  if ((line) && (addr_A >= 640) && (addr_B >= 640) && (addr_C >= 640)) line = !(line);
  if ((!line) && (addr_D >= 640) && (addr_E >= 640) && (addr_F >= 640)) line = !(line);
end 

//Resetting at the end of the line
always @ (line) begin
  addr_A = 0;
  addr_B = 1;
  addr_C = -1;
  addr_D = 0;
  addr_E = 1;
  addr_F = -1;
  A = block_RAM_A[addr_A];
  B = block_RAM_B[addr_B];
  D = block_RAM_D[addr_D];
  E = block_RAM_E[addr_E];
  C = 4'b0000; 
  F = 4'b0000;
  stage = 2'b00; 
end

//Creating a new set of 4 pixels
function [3:0] newline (input [5:0] previous);
begin
  newline[0] = rules(previous[2:0]);
  newline[1] = rules(previous[3:1]);
  newline[2] = rules(previous[4:2]);
  newline[3] = rules(previous[5:3]);
end
endfunction

//Induvidual Pixel Rules
function rules (input [2:0] previous); 
begin
  case(previous)
  3'b000:  rules = 0;
  3'b001:  rules = 1;
  3'b010:  rules = 1;
  3'b100:  rules = 1;
  3'b011:  rules = 0;
  3'b101:  rules = 0;
  3'b110:  rules = 1;
  3'b111:  rules = 0;
  default: rules = 0;
  endcase
end 
endfunction

//Stage FSM
always @ (negedge clk) begin
  if (int_busy && !stall) begin
    case(stage)
    2'b00: stage = 2'b01;
    2'b01: stage = 2'b10;
    2'b10: stage = 2'b00; 
    endcase
    RAM_r = 1; 
    RAM_w = 1;
  end
end 


always @ (posedge clk) begin
  if (req) begin
    stage = 2'b00;
    line  = 0;
    ack   = 1;
    int_busy  = 1; 
    stall = 0;
    end 
  else begin
    ack = 0; end                     
end

initial 
begin
  line = 1; 
  int_busy = 0;
  int_req = 0;
  ack = 0;
  addr = 0;
  nbyte = 4'b1111;
  $readmemh("initial.mem", block_RAM_A);
  $readmemh("initial.mem", block_RAM_B);
  $readmemh("initial.mem", block_RAM_C);
  $readmemh("initial.mem", block_RAM_D);
  $readmemh("initial.mem", block_RAM_E);
  $readmemh("initial.mem", block_RAM_F);
end 

endmodule
