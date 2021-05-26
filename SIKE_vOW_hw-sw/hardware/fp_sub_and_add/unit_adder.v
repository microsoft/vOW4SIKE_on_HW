/* 
 * Author:        Wen Wang <wen.wang.ww349@yale.edu>
 * Updated:       2021-04-12
 * Abstract:      building block for carry-ripple adder
 * 
*/
 
module unit_adder 
#(
  parameter RADIX = 32
  )
(
  input wire carry_in, // 0 or 1
  // input a: positive
  input wire [RADIX-1:0] din_a,
  // input b: positive
  input wire [RADIX-1:0] din_b,
  
  output wire [RADIX-1:0] dout,
  output wire carry_out // 0 or 1
	);

wire [RADIX:0] dout_full;

assign dout_full = din_a + din_b + carry_in;

assign dout = dout_full[RADIX-1:0];
assign carry_out = dout_full[RADIX];

endmodule