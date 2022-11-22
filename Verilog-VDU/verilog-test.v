
// Verilog stimulus file.
//The Clock with a frequency of 40ns

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

