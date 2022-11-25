
// Verilog stimulus file.
//The Clock with a frequency of 40ns
/*
initial
  begin
    clk = 0; 
    forever #20 clk = !clk; 
$stop;
end

integer file_handle; 
reg fake_req;
reg allow_memory;
reg [15:0] xs, ys, xe, ye;

task error_handler (input [3:0] error); 
    begin 
        case (error)  
          0: $fdisplay(file_handle, "req allowed to interrupt while busy at time %t", $time);//
          1: $fdisplay(file_handle, "memory didnt wait for permission from de_ack at %t ", $time);//
          2: $fdisplay(file_handle, "Early start error at time %t ", $time );//
          3: $fdisplay(file_handle, "acknowldge/busy error at time %t ", $time );//
          4: $fdisplay(file_handle, "de_req error at time %t ", $time );//
          default: $fdisplay(file_handle, "Unknown error at time %t ", $time);
        endcase
    end
endtask

//does the unit wait until input request to start ? 
always @ (posedge busy, posedge ack) begin
  if (!(req)) error_handler(2);
end 

// does the unit acknowledge the request properly?
always @ (posedge req) begin
  if (!fake_req) begin
    #1 if (!busy) error_handler(3);
    if (!ack) error_handler(3);

    #40 if (!(busy)) error_handler(3);
    if (ack) error_handler(3);
  end
end


// does the unit request permission to begin memory access?
always @ (posedge busy) begin 
  #40 if (de_req != 1'b1) error_handler(4);
end

//responding to de_req responses
always @ (posedge de_req) begin
    if(de_req === 1) begin
      @(posedge clk);
      while (de_req) begin
        #40 de_ack = !de_ack;
      end
    end
  de_ack = 0; 
end 


always @ (posedge de_ack) begin
  allow_memory = 1;
end

//does the unit wait for de_ack to write to memory
always @ (de_addr, de_data, de_nbyte) begin
  #10 if (allow_memory == 0) error_handler(1);
  allow_memory = 0;
end

//checking to see if req can be allowed to alter/interrupt when busy
always @ (posedge busy) begin
  #80 repeat($random & 3) @(posedge clk);
  r0 = 0; r1 = 0; r2 = 0; r3 = 0; r6 = 0;
  fake_req = 1; req = 1; 
  if ((de_addr == 0) || (de_data == 0)) error_handler(0);
  #40 req = 0; fake_req = 0;
end

always @ (posedge de_req) begin 
  $fdisplay(,file_handle,"%b", de_nbyte);
  if ((de_addr+1)%640 == 0) $fdisplay(file_handle,"\n");
    
end

task test();
  begin
    //Setting Up
    de_ack = 1;
    #40 de_ack = 0;
    #40 allow_memory = 1; req = 1;
    @(ack);
    #40 req = 0;
  end
endtask

initial
  begin
  file_handle = $fopen("output.txt");
  #100
    @(posedge clk);
    test();
    @(negedge busy);
    $stop;

    @(posedge clk);
    test();
    @(negedge busy);
    $stop;
  
  $fclose(file_handle);
  #100 $finish;
end
*/

`timescale 1ns/100ps

module cell_automaton_tb ();
  reg clk, req;
  wire ack;
  wire busy, de_req;
  reg de_ack;
  wire [17:0] de_addr;
  wire  [3:0] de_nbyte;
  wire [31:0] de_w_data;
  integer file_handle; 
  reg fake_req;
  reg allow_memory;
  reg [15:0] xs, ys, xe, ye;

cell_automaton ca (clk, req, ack, busy, de_req, de_ack, de_addr, de_nbyte, de_w_data);

//The Clock with a frequency of 40ns
initial
  begin
    clk = 0; 
    forever #20 clk = !clk; 
$stop;
end

initial
begin
  #20000 $finish; 
end

//responding to de_req responses
always @ (posedge de_req) begin
    if(de_req === 1) begin
      @(posedge clk);
      while (de_req) begin
        #40 de_ack = !de_ack;
      end
    end
  de_ack = 0; 
end 

//Tests task, that runs a test
task test();
  begin
    //Setting Up
    de_ack = 1;
    #40 de_ack = 0;
    #40 allow_memory = 1; req = 1;
    @(ack);
    #40 req = 0;
  end
endtask

always @ (posedge de_ack) begin
  allow_memory = 1;
end

always @ (posedge de_req) begin 
  $fdisplay(file_handle,"%b", de_nbyte);
  if ((de_addr+1)%640 == 0) $fdisplay(file_handle,"\n");
end

//Driver Block for tests
initial
  begin
  file_handle = $fopen("output.txt");
  #100
    @(posedge clk);
    test();
    @(negedge busy);
    $stop;
  $fclose(file_handle);
  #100 $finish;
end

initial 
begin
  $dumpfile("cell_automaton_tb_results.vcd");
  $dumpvars;
end
endmodule