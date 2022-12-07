
`define TPD 2

module drawing_dummy( input  wire        clk,
                      input  wire        req,
                      output reg         ack,
                      output wire        busy,
                      input  wire [15:0] r0,
                      input  wire [15:0] r1,
                      input  wire [15:0] r2,
                      input  wire [15:0] r3,
                      input  wire [15:0] r4,
                      input  wire [15:0] r5,
                      input  wire [15:0] r6,
                      input  wire [15:0] r7,
                      output wire        de_req,
                      input  wire        de_ack,
                      output wire [17:0] de_addr,
                      output wire  [3:0] de_nbyte,
                      output wire        de_rnw,
                      output wire [31:0] de_w_data,
                      input  wire [31:0] de_r_data );

//For Continuous assignment to output wires
reg [3:0] nbyte;
reg [17:0] addr;
reg int_req, int_busy;
reg [31:0] w_data;

//For Latching input Data
reg [15:0] reg1, reg2, reg3;

//Internal Registers
reg [31:0] w_data_X, w_data_Y, w_data_Z;
reg [15:0] line_number;
reg [7:0] addr_A,addr_B,addr_C,addr_D,addr_E,addr_F,line_counter;
reg [3:0] A, B, C, D, E, F;
reg [1:0] stage;
reg stall, line, reset;
integer j, i, k;

//continuous assignment
assign busy = int_busy;
assign de_addr = (addr);
assign de_req = int_req;
assign de_nbyte = nbyte;
assign de_w_data = w_data;
assign rnw = 0;

//RAM on the FPGA
reg [3:0] block_RAM_A [0:159];
reg [3:0] block_RAM_B [0:159];
reg [3:0] block_RAM_C [0:159];
reg [3:0] block_RAM_D [0:159];
reg [3:0] block_RAM_E [0:159];
reg [3:0] block_RAM_F [0:159];


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

/* TriState version
  This will allow the user to enter 2 rule sets
  The pixel colour will depend on both
  * Both True -> Pixel will be Red
  * One True  -> Pixel will be Black
  * Non True  -> Pixel will be White
*/

//for memory writes to the VDU
always @ (posedge clk) begin
  if (req && !busy) begin
    line = 0;
    stall = 0;
    int_busy = 1;
  end
  if (de_ack) begin 
    int_req = 0; 
    stall = 0;
  end 
  if (int_req) begin
    stall = 1;
  end
  if (line_counter == 160) begin 
    if (line_number == reg3||line_number==419) begin
      stall = 1;
      reset = 1; 
    end
    else line = !line;
  end
  if (j == 160) begin
    int_busy = 0;
    reset = 0;
    j = 0; 
  end
end 

//Creating a new set of 4 pixels
function [3:0] newline (input [7:0] previous);
begin
  newline[0] = rules(previous[4:0]);
  newline[1] = rules(previous[5:1]);
  newline[2] = rules(previous[6:2]);
  newline[3] = rules(previous[7:3]);
end
endfunction

/* Induvidual Pixel Rules
  *  -> reg1 is used to define the rules for the calculation only if it doesn't equal zero or all 1's
  *  -> Only the first 8 bits are used if binary state, Otherwise all bits used
  *  -> Rule 90 style structure,  see @https://en.wikipedia.org/wiki/Rule_90#:~:text=Rule%2090%20is%20an%20elementary%20cellular%20automaton.,cells%20is%20called%20a%20configuration.*/
function rules (input [4:0] previous); 
begin
  //3bit Neighbourhoods
  if (reg2 == 0)  begin
    casex(previous)
    5'bx000x:  rules = 0; //Safety precation to stop screen being just black pixels
    5'bx001x:  rules = (reg1[1] || reg1[9]);
    5'bx010x:  rules = (reg1[2] || reg1[10]);
    5'bx011x:  rules = (reg1[3] || reg1[11]);
    5'bx100x:  rules = (reg1[4] || reg1[12]);
    5'bx101x:  rules = (reg1[5] || reg1[13]);
    5'bx110x:  rules = (reg1[6] || reg1[14]);
    5'bx111x:  rules = (reg1[7] || reg1[15]);
    default: rules = 0;
    endcase
  end
  //5bit Neighbourhoods
  
  if (reg2 != 0) begin 
    for (i = 0; i < 32; i=i+1) begin
      if (i == 0) rules = 8'hFF; //Safety precation to stop screen being just black pixels
      else if (i == previous) begin
        if (i<16) rules = reg1[i];
        else      rules = reg2[i%16];
      end
    end
  end
end
endfunction

function [31:0] newColours (input [7:0] previous);
begin
  newColours[7:0]   = rulesCol(previous[4:0]);
  newColours[15:8]  = rulesCol(previous[5:1]);
  newColours[23:16] = rulesCol(previous[6:2]);
  newColours[31:24] = rulesCol(previous[7:3]);
end
endfunction

function [7:0] rulesCol (input [4:0] previous); 
begin
  //3bit Neighbourhoods
  if (reg2 == 0)  begin
    casex(previous)
    5'bx000x:  rulesCol = 8'hFF; //Safety precation to stop screen being just black pixels
    5'bx001x:  rulesCol = col(reg1[1], reg1[9]);
    5'bx010x:  rulesCol = col(reg1[2], reg1[10]);
    5'bx011x:  rulesCol = col(reg1[3], reg1[11]);
    5'bx100x:  rulesCol = col(reg1[4], reg1[12]);
    5'bx101x:  rulesCol = col(reg1[5], reg1[13]);
    5'bx110x:  rulesCol = col(reg1[6], reg1[14]);
    5'bx111x:  rulesCol = col(reg1[7], reg1[15]);
    default: rulesCol = 8'hFF;
    endcase
  end
  
  //5bit Neighbourhoods
  if (reg2 != 0) begin
    for (k = 0; k < 32; k=k+1) begin
      if (k == 0) rulesCol = 8'hFF; //Safety precation to stop screen being just black pixels
      else if (k == previous) begin
        if (k<16) rulesCol = col(reg1[k], 0);
        else      rulesCol = col(reg2[k%16],0);
      end
    end
  end
  
end
endfunction

function [7:0] col (input A, input B); 
begin
  if (A && B)      col = 8'hE0; //Red
  else if (A || B) col = 8'h00; //Black
  else             col = 8'hFF; //White
end
endfunction

//Stage FSM
always @ (posedge clk) begin
  if (de_ack) begin 
    int_req = 0; 
  end
  if (int_busy && !stall) begin
    if (line_counter == 160) begin
      line_counter = 1;
      addr_A = 0; addr_B = 1; addr_C = -1;
      addr_D = 0; addr_E = 1; addr_F = -1;
      A = block_RAM_A[addr_A];
      B = block_RAM_B[addr_B];
      D = block_RAM_D[addr_D];
      E = block_RAM_E[addr_E];
      C = 4'b0000; 
      F = 4'b0000;
      stage = 2'b00;
      if (line_number != reg3) line_number = line_number + 1; 
    end
    case(stage)
    2'b00: begin
      if (line) begin
        //Calculate A colours and Nbyte
        A = newline({E[1],E[0],D[3],D[2],D[1],D[0],F[3],F[2]});
        w_data_X = newColours({E[1],E[0],D[3],D[2],D[1],D[0],F[3],F[2]});

        //Increment then Read F 
        addr_F = addr_F + 3;
        F = block_RAM_F[addr_F];

        //Increment then Write C to VDU + RAM
        if (addr_C < 160)begin
          block_RAM_C[addr_C] = C;
          addr_C = addr_C + 3;
        end
        nbyte = C; 
        w_data = w_data_Z;
      end
      if (!line) begin
        //Calculate D colours and Nbyte
        D = newline({B[1],B[0],A[3],A[2],A[1],A[0],C[3],C[2]});
        w_data_X = newColours({B[1],B[0],A[3],A[2],A[1],A[0],C[3],C[2]});

        //Increment then Read C
        addr_C = addr_C + 3;
        C = block_RAM_C[addr_C];

        //Increment then Write F to VDU + RAM
        block_RAM_F[addr_F] = F;
        addr_F = addr_F + 3;
        nbyte = F;
        w_data = w_data_Z;
      end
      stage = 2'b01;
    end
    2'b01: begin
      if (line) begin
        //Calculate B colours and Nbyte
        B = newline({F[1],F[0],E[3],E[2],E[1],E[0],D[3],D[2]});
        w_data_Y = newColours({F[1],F[0],E[3],E[2],E[1],E[0],D[3],D[2]});

        //Increment then Read F 
        addr_D = addr_D + 3;
        D = block_RAM_D[addr_D];

        //Increment then Write A to VDU + RAM
        block_RAM_A[addr_A] = A;
        addr_A = addr_A + 3;
        nbyte = A;
        w_data = w_data_X;
      end
      if (!line) begin
        //Calculate D colours and Nbyte
        E = newline({C[1],C[0],B[3],B[2],B[1],B[0],A[3],A[2]});
        w_data_Y = newColours({C[1],C[0],B[3],B[2],B[1],B[0],A[3],A[2]});

        //Increment then Read A
        addr_A = addr_A + 3;
        A = block_RAM_A[addr_A];

        //Increment then Write D to VDU + RAM
        block_RAM_D[addr_D] = D;
        addr_D = addr_D + 3;
        nbyte = D;
        w_data = w_data_X;
      end
      stage = 2'b10;
    end
    2'b10: begin
      if (line) begin
        //Calculate C colours and Nbyte
        C = newline({D[1],D[0],F[3],F[2],F[1],F[0],E[3],E[2]});
        w_data_Z = newColours({D[1],D[0],F[3],F[2],F[1],F[0],E[3],E[2]});

        //Increment then Read E
        addr_E =addr_E + 3;
        E = block_RAM_E[addr_E];

        //Increment then Write B to VDU + RAM
        block_RAM_B[addr_B] = B;
        addr_B = addr_B + 3;
        nbyte = B;
        w_data = w_data_Y;
      end
      if (!line) begin
        //Calculate D colours and Nbyte
        F = newline({A[1],A[0],C[3],C[2],C[1],C[0],B[3],B[2]});
        w_data_Z = newColours({A[1],A[0],C[3],C[2],C[1],C[0],B[3],B[2]});

        //Increment then Read B
        addr_B = addr_B + 3;
        B = block_RAM_B[addr_B]; 

        //Increment then Write E to VDU + RAM
        block_RAM_E[addr_E] = E; //Write E
        addr_E = addr_E + 3;
        nbyte = E;
        w_data = w_data_Y;
      end
      stage = 2'b00; 
    end
    endcase
    addr = addr + 1;
    line_counter = line_counter + 1;
    int_req = 1;
  end
end 

always @ (posedge clk) begin
  if (req && !busy) begin
    line_number = 0; 
    line_counter = 1;
    stage = 2'b00;
    ack   = 1;
    reg1 = r1;
    reg2 = r2; 
    reg3 = r3;
    end 
  else begin
    ack = 0; end                     
end

initial begin 
  reset = 1; 
  nbyte = 4'b0000;
  j = 0;
end 

always @ (posedge clk) begin
    if (reset) begin
    block_RAM_A[j] = {4{1'b0}};
    block_RAM_B[j] = {4{1'b0}};
    block_RAM_C[j] = {4{1'b0}};
    block_RAM_D[j] = {4{1'b0}};
    block_RAM_E[j] = {4{1'b0}};
    block_RAM_F[j] = {4{1'b0}};
    j = j+1;
  end
  if (reset) begin
    line_counter = 1;
    addr = -1;
     w_data = 32'hFFFFFFFF;
    block_RAM_B [100] = 4'b0010;
  end
end 

endmodule
