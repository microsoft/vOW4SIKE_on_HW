# generate memory contents for c_1, which equals to p

import sys
import argparse 
import random

parser = argparse.ArgumentParser(description='Montgomery multiplication software.',
                formatter_class=argparse.ArgumentDefaultsHelpFormatter)

parser.add_argument('-w', '--w', dest='w', type=int, default=32,
          help='radix w')
parser.add_argument('-prime', '--prime', dest='prime', type=int, default=434,
          help='prime width')
parser.add_argument('-R', '--R', dest='R', type=int, default=448,
          help='rounded prime width') 
parser.add_argument('-sw', dest='sw', type=int, default=0,
          help='width of sk')       
parser.add_argument('-sd', dest='sd', type=int, default=0,
          help='depth of sk') 
args = parser.parse_args()
 
# radix, can be 8, 16, 32, 64, etc, need to be careful about overflow 
w=args.w
prime=args.prime
R=args.R
sk_width=args.sw
sk_depth=args.sd


format_element = "{0:0" + str(w) +"b}"

if (prime == 128): 
    p = 2^32*3^20*23-1
elif (prime == 377):
    p = 2^191*3^117-1
elif (prime == 434): 
    p = 2^216*3^137-1  
elif (prime == 503):
    p = 2^250*3^159-1 
elif (prime == 610):
    p = 2^305*3^192-1
elif (prime == 751):
    p = 2^372*3^239-1 
else:
  print "Error!!\n\n  Please specify a valid value for prime p!\n"

# Finite field
Fp = GF(p)

# number of digits in operands a and b
n = int(R/w)
 

f_c_1 = open("mem_p_plus_one.mem", "w"); 

Z = IntegerRing()

m = [Z(0)]*n

for i in range(n):
    m[i] = ((p+1) >> (w*i)) % 2^w 
    f_c_1.write(format_element.format(m[i]))
    f_c_1.write("\n")

f_c_1.close()

# write value 2*p to a file
t = 2*p

ot = [Z(0)]*n 

f_t = open("px2.mem", "w"); 

for i in range(n):  
    ot[i] = Z((Z(t) >> (w*i)) % 2^w) 
    f_t.write(format_element.format(ot[i]))
    f_t.write("\n") 

f_t.close() 

# write value 4*p to a file
t = 4*p

ot = [Z(0)]*n 

f_t = open("px4.mem", "w"); 

for i in range(n):  
    ot[i] = Z((Z(t) >> (w*i)) % 2^w) 
    f_t.write(format_element.format(ot[i]))
    f_t.write("\n") 

f_t.close() 

# generate sk array and write to memory
sk = [0]*(sk_width*sk_depth)
f = open("sk.mem", "w")
for i in range(sk_depth):
  sk_string = ""
  for j in range(sk_width):
    #print i, j
    sk[i*sk_width+j] = random.randint(0,1)
    sk_string = str(sk[i*sk_width+j]) + sk_string
  f.write(sk_string) 
  f.write("\n")
f.close()