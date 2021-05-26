module single_to_double_memory_wrapper 
#(
  parameter SINGLE_MEM_WIDTH = 32, // RADIX
  parameter SINGLE_MEM_DEPTH = 14, // WIDTH_REAL
  parameter DOUBLE_MEM_WIDTH = 2*SINGLE_MEM_WIDTH,
  parameter DOUBLE_MEM_DEPTH = ((SINGLE_MEM_DEPTH+1)/2)
)
(
  input wire clk,
  input wire rst,
  input wire single_mem_rd_en,
  input wire [`CLOG2(SINGLE_MEM_DEPTH)-1:0] single_mem_rd_addr,
  output wire [SINGLE_MEM_WIDTH-1:0] single_mem_dout,

  output wire double_mem_rd_en,
  output wire [`CLOG2(DOUBLE_MEM_DEPTH)-1:0] double_mem_rd_addr,
  input wire [DOUBLE_MEM_WIDTH-1:0] double_mem_dout

);

wire [`CLOG2(SINGLE_MEM_DEPTH)-1:0] single_mem_rd_addr_buf;

assign double_mem_rd_en = single_mem_rd_en;
// double_mem_rd_addr = (single_mem_rd_addr >> 1)
assign double_mem_rd_addr = single_mem_rd_addr[`CLOG2(SINGLE_MEM_DEPTH)-1:1]; 
assign single_mem_dout = (single_mem_rd_addr_buf[0] == 1'b0) ? double_mem_dout[DOUBLE_MEM_WIDTH-1:SINGLE_MEM_WIDTH] : double_mem_dout[SINGLE_MEM_WIDTH-1:0];

delay #(.WIDTH(`CLOG2(SINGLE_MEM_DEPTH)), .DELAY(1)) single_mem_rd_addr_buf_delay_inst(
  .clk(clk),
  .rst(rst),
  .din(single_mem_rd_addr),
  .dout(single_mem_rd_addr_buf)
  ); 
                         
endmodule
