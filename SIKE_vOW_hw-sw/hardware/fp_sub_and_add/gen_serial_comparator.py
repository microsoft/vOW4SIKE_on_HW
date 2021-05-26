'''
   This file is the code generation file for serial_comparator.v
'''

import sys
import math
import argparse

parser = argparse.ArgumentParser(description='Generate serial_comparator module.',
                formatter_class=argparse.ArgumentDefaultsHelpFormatter)
 
parser.add_argument('-w', dest='w', type=int, default=32,  
          help='radix; default = 32')
   
parser.add_argument('-n', '--n', dest='n', type=int, default=14,
          help='number of digits; default = 14')
 
args = parser.parse_args()

w = args.w
n = args.n
  
print """
// compare two large input values and output the comparison result
// inputs: A, B, both are positive values
// output:
//  if A > B, res = 1
//  else,      res = 0
// output signals are all buffered already

// idea behind this module, here is a motivation sample:
// A = (a3, a2, a1, a0), B = (b3, b2, b1, b0)
// (A > B) = (a3 > b3) |
//           ((a3 == b3) & (a2 > b2)) |
//           ((a3 == b3) & (a2 == b2) & (a1 > b1)) |
//           ((a3 == b3) & (a2 == b2) & (a1 == b1) & (a0 > b0))

module serial_comparator 
#(
  parameter RADIX = 32,
  parameter DIGITS = 14
  )
(
  input wire start,
  input wire rst,
  input wire clk,

  input wire digit_valid,
  // input value A
  input wire [RADIX-1:0] digit_a, 
  // input value B
  input wire [RADIX-1:0] digit_b, 
  // comparison result
  output reg a_bigger_than_b,
  output reg done
);

reg comp_array [DIGITS-1:0];

reg [`CLOG2(DIGITS)-1:0] counter;

reg running;

reg done_buf;

wire digit_a_bigger_than_b;
wire digit_a_equal_to_b;

assign digit_a_bigger_than_b = digit_valid & (digit_a > digit_b);
assign digit_a_equal_to_b = digit_valid & (digit_a == digit_b); 

always @(posedge clk) begin
  if (rst) begin""" 

for i in range(n):
  print "    comp_array[{0}] <= 1'b0;".format(i)

print """  end
  else begin"""

for i in range(n-1):
  print """    comp_array[{0}] <= digit_valid & (counter == {0}) ? digit_a_bigger_than_b :
                     digit_valid ? comp_array[{0}] & digit_a_equal_to_b :
                     comp_array[{0}];
""".format(i)
print "    comp_array[{0}] <= digit_valid & (counter == {0}) ? digit_a_bigger_than_b : comp_array[{0}];".format(n-1)
print """  end
end
"""
res_str = ""
for i in range(n-1):
  res_str += "comp_array[{0}] | ".format(i)
res_str += "comp_array[{0}]".format(n-1)

print """
always @(posedge clk) begin
  if (rst) begin
    running <= 1'b0;
    done_buf <= 1'b0;
    done <= 1'b0;
    a_bigger_than_b <= 1'b0;
    counter <= {{`CLOG2(DIGITS){{1'b0}}}};
  end 
  else begin
    running <= done ? 1'b0 :
               start ? 1'b1 :
               running;

    counter <= done ? {{`CLOG2(DIGITS){{1'b0}}}} :
               (start | running) & digit_valid ? counter + 1 :
               counter;

    done_buf <= digit_valid & (counter == (DIGITS-1)) ? 1'b1 : 1'b0;
    done <= done_buf;

    a_bigger_than_b <= {0};
  end
end
""".format(res_str )

for i in range(n):
  print "wire comp_array_{0};".format(i)

for i in range(n):
  print "assign comp_array_{0} = comp_array[{0}];".format(i)
 


print "endmodule\n\n"
 