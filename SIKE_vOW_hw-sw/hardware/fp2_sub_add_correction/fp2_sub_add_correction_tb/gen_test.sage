###
 # Author:        Wen Wang <wen.wang.ww349@yale.edu>
 # Updated:       2021-04-12
 # Abstract:      software testing file for F(p^2) adder/subtractor
###

import sys
import argparse
import random 

parser = argparse.ArgumentParser(description='generate test inputs for adder/comparator.',
                formatter_class=argparse.ArgumentDefaultsHelpFormatter)

parser.add_argument('-w', '--w', dest='w', type=int, default=32,
          help='radix w')
parser.add_argument('-s', '--seed', dest='seed', type=int, required=False, default=None,
          help='seed')
parser.add_argument('-prime', '--prime', dest='prime', type=int, default=434,
          help='prime width')
parser.add_argument('-R', '--R', dest='R', type=int, default=448,
          help='rounded prime width')
parser.add_argument('-cmd', '--cmd', dest='cmd', type=int, default=1,
          help='cmd')
parser.add_argument('-ef', '--ef', dest='extension_field', type=int, default=0,
          help='if it is operation on extension field')
args = parser.parse_args()

if args.seed:
  set_random_seed(args.seed)
  random.seed(args.seed)

cmd = args.cmd
extension_field = args.extension_field

# radix, can be 8, 16, 32, 64, etc, need to be careful about overflow 
w=args.w 
prime=args.prime
R=2^(args.R)

hex_format_element = "{0:0" + str(w/4) +"x}"
format_element = "{0:0" + str(w) +"b}"

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
else:
  print "Error!!\n\n  Please specify a valid value for prime p!\n"


# Finite field
Fp = GF(p)
  
# number of digits in operands a and b
n = int(log(R,2)/w)

# force unsigned arithmetic
Z = IntegerRing() 

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

# generate random inputs in specified range for different functions
if (cmd == 3):
  a0 = Z(random.randint(0, 32*p))
  b0 = Z(random.randint(0, 32*p))
elif (cmd == 5):
  a0 = Z(random.randint(0, 4*p))
  b0 = Z(random.randint(0, 4*p)) 
else:
  a0 = Z(random.randint(0, 2*p))
  b0 = Z(random.randint(0, 2*p))

if (extension_field == 1):
  if (cmd == 3):
    a1 = Z(random.randint(0, 32*p))
    b1 = Z(random.randint(0, 32*p))
  elif (cmd == 5):
    a1 = Z(random.randint(0, 4*p))
    b1 = Z(random.randint(0, 4*p)) 
  else:
    a1 = Z(random.randint(0, 2*p))
    b1 = Z(random.randint(0, 2*p))

# write digits in a and b into files
oa = [Z(0)]*n
ob = [Z(0)]*n

f_a = open("Sage_mem_a_0.txt", "w");
f_b = open("Sage_mem_b_0.txt", "w");

for i in range(n):  
    oa[i] = Z((Z(a0) >> (w*i)) % 2^w)
    ob[i] = Z((Z(b0) >> (w*i)) % 2^w)
    f_a.write(hex_format_element.format(oa[i]))
    f_a.write("\n")
    f_b.write(hex_format_element.format(ob[i]))
    f_b.write("\n")

f_a.close()
f_b.close()

if (extension_field == 1):
  # write digits in a and b into files
  oa = [Z(0)]*n
  ob = [Z(0)]*n

  f_a = open("Sage_mem_a_1.txt", "w");
  f_b = open("Sage_mem_b_1.txt", "w");

  for i in range(n):  
      oa[i] = Z((Z(a1) >> (w*i)) % 2^w)
      ob[i] = Z((Z(b1) >> (w*i)) % 2^w)
      f_a.write(hex_format_element.format(oa[i]))
      f_a.write("\n")
      f_b.write(hex_format_element.format(ob[i]))
      f_b.write("\n")

  f_a.close()
  f_b.close()

# result of different functions
if (cmd == 1):
  c0 = Z(a0+b0)
  if (c0 > 2*p):
    c0 -= 2*p
elif (cmd == 2):
  c0 = Z(a0-b0)
  if (c0 < 0):
    c0 += 2*p
elif (cmd == 3):
  c0 = Z(a0+b0)
elif (cmd == 4):
  c0 = Z(a0-b0)+2*p
elif (cmd == 5):
  c0 = Z(a0-b0)+4*p
else:
  print "Please choose a valid cmd!\n"
 
# write digits in c into files
oc = [Z(0)]*n 

f_c = open("Sage_c_0.txt", "w"); 

for i in range(n):  
    oc[i] = Z((Z(c0) >> (w*i)) % 2^w) 
    f_c.write(hex_format_element.format(oc[i]))
    f_c.write("\n") 

f_c.close() 

if (extension_field == 1):
   # result of different functions
  if (cmd == 1):
    c1 = Z(a1+b1)
    if (c1 > 2*p):
      c1 -= 2*p
  elif (cmd == 2):
    c1 = Z(a1-b1)
    if (c1 < 0):
      c1 += 2*p
  elif (cmd == 3):
    c1 = Z(a1+b1)
  elif (cmd == 4):
    c1 = Z(a1-b1)+2*p
  elif (cmd == 5):
    c1 = Z(a1-b1)+4*p
  else:
    print "Please choose a valid cmd!\n"
   
  # write digits in c into files
  oc = [Z(0)]*n 

  f_c = open("Sage_c_1.txt", "w"); 

  for i in range(n):  
      oc[i] = Z((Z(c1) >> (w*i)) % 2^w) 
      f_c.write(hex_format_element.format(oc[i]))
      f_c.write("\n") 

  f_c.close() 


 
