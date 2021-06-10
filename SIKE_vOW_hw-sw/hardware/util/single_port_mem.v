// single-ported memory, in one clock, can either do one read, or one write. 
// => only one memory access at a time.

module single_port_mem
  #(
    parameter WIDTH = 8,
    parameter DEPTH = 64,
    parameter FILE = "",
    parameter INIT = 0
  )
  (
    input wire                     clock,
    input wire [WIDTH-1:0]         data,
    input wire [`CLOG2(DEPTH)-1:0] address,
    input wire                     wr_en,
    output reg [WIDTH-1:0]         q
  );
  
  reg [WIDTH-1:0] mem [DEPTH-1:0]/* synthesis ramstyle = "M20K" */;
   
  integer file;
  integer scan;
  integer i;
  
  initial
    begin
      // read file contents if FILE is given
      if (FILE != "")
        $readmemb(FILE, mem);
      
      // set all data to 0 if INIT is true
      if (INIT)
        for (i = 0; i < DEPTH; i = i + 1)
          mem[i] = {WIDTH{1'b0}};
    end
  
  always @(posedge clock)
    begin
      if (wr_en)
        begin
          mem[address] <= data;
          q <= data;
        end
      q <= mem[address];
    end
  
endmodule
  