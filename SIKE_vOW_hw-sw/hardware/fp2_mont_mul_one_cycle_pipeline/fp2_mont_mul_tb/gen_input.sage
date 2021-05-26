###
 # Author:        Wen Wang <wen.wang.ww349@yale.edu>
 # Updated:       2021-04-12
 # Abstract:      software testing file for F(p^2) multiplier
###

import sys
import argparse 

parser = argparse.ArgumentParser(description='Montgomery multiplication software.',
                formatter_class=argparse.ArgumentDefaultsHelpFormatter)

parser.add_argument('-w', '--w', dest='w', type=int, default=32,
          help='radix w')
parser.add_argument('-s', '--seed', dest='seed', type=int, required=False, default=None,
          help='seed')
parser.add_argument('-prime', '--prime', dest='prime', type=int, default=434,
          help='prime width')
parser.add_argument('-R', '--R', dest='R', type=int, default=448,
          help='rounded prime width')
args = parser.parse_args()

if args.seed:
  set_random_seed(args.seed)

# radix, can be 8, 16, 32, 64, etc, need to be careful about overflow 
w=args.w 
prime=args.prime
R=2^(args.R) 

hex_format_element = "{0:0" + str(w/4) +"x}"
format_element = "{0:0" + str(w) +"b}"
format_carry = "{0:0" + str(w+1) +"b}"
format_CS = "{0:0" + str(2*w+1) +"b}"

def bindigits(n, bits):
    s = bin(n & int("1"*bits, 2))[2:]
    return ("{0:0>%s}" % (bits)).format(s)

# pick a prime:
# testing purpose
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
elif (prime == 546):
    p = 2^273*3^172-1
elif (prime == 697):
    p = 2^356*3^215-1
else:
  print "Error!!\n\n  Please specify a valid value for prime p!\n"


# Finite field
Fp = GF(p)
 
# number of digits in operands a and b
n = int(log(R,2)/w)

# force unsigned arithmetic
Z = IntegerRing()
Fr = IntegerModRing(R)
pp = Fr(-p^-1)
assert((pp % 2^w) == 1)

OK=true

a0 = Fp.random_element()  
b0 = Fp.random_element()  
a1 = Fp.random_element()  
b1 = Fp.random_element() 

 
oa0 = [Z(0)]*n
ob0 = [Z(0)]*n
oa1 = [Z(0)]*n
ob1 = [Z(0)]*n

f_a_0 = open("mem_" + str(0) + "_a_0" + ".txt", "w");
f_a_1 = open("mem_" + str(0) + "_a_1" + ".txt", "w");
f_b_0 = open("mem_" + str(0) + "_b_0" + ".txt", "w");
f_b_1 = open("mem_" + str(0) + "_b_1" + ".txt", "w");


for i in range(n):  
  oa0[i] = Z((Z(a0) >> (w*i)) % 2^w) 
  f_a_0.write(hex_format_element.format(oa0[i]))
  f_a_0.write("\n")
  ob0[i] = Z((Z(b0) >> (w*i)) % 2^w) 
  f_a_1.write(hex_format_element.format(ob0[i]))
  f_a_1.write("\n")
  oa1[i] = Z((Z(a1) >> (w*i)) % 2^w)
  f_b_0.write(hex_format_element.format(oa1[i]))
  f_b_0.write("\n")
  ob1[i] = Z((Z(b1) >> (w*i)) % 2^w)
  f_b_1.write(hex_format_element.format(ob1[i]))
  f_b_1.write("\n")
   
f_a_0.close()
f_a_1.close()
f_b_0.close()
f_b_1.close()

f_c_1 = open("mem_c_1.mem", "w"); 
m = [Z(0)]*n 

for i in range(n):
  m[i] = ((p+1) >> (w*i)) % 2^w
  f_c_1.write(format_element.format(m[i]))
  f_c_1.write("\n")
f_c_1.close()



f_p = open("p.mem", "w")
m = [Z(0)]*n

for i in range(n):
  m[i] = ((p) >> (w*i)) % 2^w
  f_p.write(hex_format_element.format(m[i]))
  f_p.write("\n")
f_p.close()


