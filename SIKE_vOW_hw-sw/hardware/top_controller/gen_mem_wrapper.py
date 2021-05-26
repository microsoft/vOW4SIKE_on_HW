'''
 * Author:        Wen Wang <wen.wang.ww349@yale.edu>
 * Updated:       2021-04-12
 * Abstract:      code generation file for memory wrapper hardware module
'''

import sys
import argparse  

parser = argparse.ArgumentParser(description='memory wrapper.',
                formatter_class=argparse.ArgumentDefaultsHelpFormatter)

parser.add_argument('-w', '--w', dest='w', type=int, default=32,
          help='single mem width')
parser.add_argument('-d', '--d', dest='d', type=int, default=14,
          help='single mem depth')
parser.add_argument('-n', '--n', dest='n', type=int, default=2,
          help='number of memory pieces') 
args = parser.parse_args()
 
width=args.w 
depth=args.d 
num=args.n

print '''
module memory_{0}_to_{1}_wrapper
  #(
    parameter WIDTH = {2},
    parameter SINGLE_MEM_DEPTH = {3},
    parameter FULL_MEM_DEPTH = {4},
    parameter SINGLE_MEM_DEPTH_LOG = `CLOG2(SINGLE_MEM_DEPTH),
    parameter FULL_MEM_DEPTH_LOG = `CLOG2(FULL_MEM_DEPTH),'''.format(num, 1, width, depth, depth*num)

for i in range(num):
  if (i < (num-1)):
    print "    parameter MEM_{0}_START_ADDR = {1},".format(i, i*depth)
  else:
    print "    parameter MEM_{0}_START_ADDR = {1}".format(i, i*depth)

print """
  )
  (
    input  wire                            clk,"""
    # output wire                            mem_dout,"""

for i in range(num):
  print '''    // memory {0}
    input  wire                            mem_{0}_wr_en,
    input  wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_{0}_wr_addr,
    input  wire [WIDTH-1:0]                mem_{0}_din,
    input  wire                            mem_{0}_rd_en,
    input  wire [SINGLE_MEM_DEPTH_LOG-1:0] mem_{0}_rd_addr,'''.format(i)

print '''    output wire [WIDTH-1:0]                mem_dout
  );'''

print '''
// interface to single port memory
wire [WIDTH-1:0] mem_din;
wire mem_wr_en;
wire [FULL_MEM_DEPTH_LOG-1:0] mem_wr_addr; 
wire [FULL_MEM_DEPTH_LOG-1:0] mem_rd_addr; 

// addr zeroes
wire [FULL_MEM_DEPTH_LOG-SINGLE_MEM_DEPTH_LOG-1:0] const_zeroes;
assign const_zeroes = {(FULL_MEM_DEPTH_LOG-SINGLE_MEM_DEPTH_LOG){1'b0}};
''' 

mem_wr_en_str = ""
for i in range(num):
  if (i < (num-1)):
    mem_wr_en_str += "mem_{0}_wr_en | ".format(i)
  else:
    mem_wr_en_str += "mem_{0}_wr_en".format(i)

mem_wr_addr_str = ""
for i in range(num):
  if (i == 0):
    mem_wr_addr_str += "mem_{0}_wr_en ? {{const_zeroes, mem_{0}_wr_addr}} + MEM_{0}_START_ADDR :\n".format(i)
  elif (i < (num-1)):
    mem_wr_addr_str += "                     mem_{0}_wr_en ? {{const_zeroes, mem_{0}_wr_addr}} + MEM_{0}_START_ADDR :\n".format(i)
  else:
    mem_wr_addr_str += "                     mem_{0}_wr_en ? {{const_zeroes, mem_{0}_wr_addr}} + MEM_{0}_START_ADDR : \n                     {{FULL_MEM_DEPTH_LOG{{1'b0}}}}".format(i,depth*i)

mem_din_str = ""
for i in range(num):
  if (i == 0):
    mem_din_str += "mem_{0}_wr_en ? mem_{0}_din :\n".format(i)
  elif (i < (num-1)):
    mem_din_str += "                 mem_{0}_wr_en ? mem_{0}_din :\n".format(i)
  else:
    mem_din_str += "                 mem_{0}_wr_en ? mem_{0}_din :\n                 {{WIDTH{{1'b0}}}}".format(i)

mem_rd_addr_str = ""
for i in range(num):
  if (i == 0):
    mem_rd_addr_str += "mem_{0}_rd_en ? {{const_zeroes, mem_{0}_rd_addr}} + MEM_{0}_START_ADDR :\n".format(i)
  elif (i < (num-1)):
    mem_rd_addr_str += "                     mem_{0}_rd_en ? {{const_zeroes, mem_{0}_rd_addr}} + MEM_{0}_START_ADDR :\n".format(i,depth*i)
  else:
    mem_rd_addr_str += "                     mem_{0}_rd_en ? {{const_zeroes, mem_{0}_rd_addr}} + MEM_{0}_START_ADDR :\n                     {{FULL_MEM_DEPTH_LOG{{1'b0}}}}".format(i,depth*i)

print '''
assign mem_wr_en = {0};

assign mem_wr_addr = {1};

assign mem_din = {2};

assign mem_rd_addr = {3};
'''.format(mem_wr_en_str, mem_wr_addr_str, mem_din_str, mem_rd_addr_str)

print '''
single_port_mem #(.WIDTH(WIDTH), .DEPTH(FULL_MEM_DEPTH)) single_port_mem_inst (  
  .clock(clk),
  .data(mem_din),
  .address(mem_wr_en ? mem_wr_addr : mem_rd_addr),
  .wr_en(mem_wr_en),
  .q(mem_dout)
  );

endmodule

'''