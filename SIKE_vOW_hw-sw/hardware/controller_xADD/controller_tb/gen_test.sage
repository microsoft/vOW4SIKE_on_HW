###
 # Author:        Wen Wang <wen.wang.ww349@yale.edu>
 # Updated:       2021-04-12
 # Abstract:      software testing file for xADD
###

import sys
import argparse 
import random

parser = argparse.ArgumentParser(description='xADD_hw software.',
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
  random.seed(args.seed)

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

# define a class for GF(p^2) field
class Fp2_element:
#  def __init__(self, realpart, imagpart):
    r = Z(0)
    i = Z(0)

def fp2_random_init(a):
  a.r = Z(random.randint(0, 2*p))
  a.i = Z(random.randint(0, 2*p))
  return a
 

def fp_mont_mul_add(a0, a1, b0, b1):
  oa0 = [Z(0)]*n
  ob0 = [Z(0)]*n
  oa1 = [Z(0)]*n
  ob1 = [Z(0)]*n  

  m = [Z(0)]*n  

  for i in range(n):
      m[i] = ((p+1) >> (w*i)) % 2^w 
   
  for i in range(n):  
      oa0[i] = Z((Z(a0) >> (w*i)) % 2^w)  
      ob0[i] = Z((Z(b0) >> (w*i)) % 2^w) 
      oa1[i] = Z((Z(a1) >> (w*i)) % 2^w) 
      ob1[i] = Z((Z(b1) >> (w*i)) % 2^w) 

  # actual Montgomery multiplication algorithm
  # CS = (C, S), C is (w+1)-bits, and S is w bits. C gets sign-extended for addition in the inner j loop
  t = [Z(0)]*n 
  for i in range(n): 
      CS = oa0[0]*ob1[i] + oa1[0]*ob0[i] + t[0]  
      S = CS % 2^w
      C = CS >> w 
      mm = S
      for j in range(1, n): 
          CS = oa0[j]*ob1[i] + oa1[j]*ob0[i] + mm*m[j] + t[j] + C  
          S = CS % 2^w
          C = CS >> w
          t[j-1] = S 
      t[n-1] = C 
    
  # Assembling result, not needed in hw
  e = 0
  for i in range(n):
      e += t[i]*2^(w*i)

  assert(e >= 0)
  assert(e <= 2*p) 

  # conversion to standard form
  ee = Fp(e*R)

  # direct result, for comparison
  c = Fp(a0*b1+a1*b0) 

  # verification of results
  assert(Z(c) == Z(ee))
 
  return e

def fp_mont_mul_sub(a0, a1, b0, b1):
  oa0 = [Z(0)]*n
  ob0 = [Z(0)]*n
  oa1 = [Z(0)]*n
  ob1 = [Z(0)]*n  

  m = [Z(0)]*n  

  for i in range(n):
      m[i] = ((p+1) >> (w*i)) % 2^w 
   
  for i in range(n):  
      oa0[i] = Z((Z(a0) >> (w*i)) % 2^w)  
      ob0[i] = Z((Z(b0) >> (w*i)) % 2^w) 
      oa1[i] = Z((Z(a1) >> (w*i)) % 2^w) 
      ob1[i] = Z((Z(b1) >> (w*i)) % 2^w) 

  # actual Montgomery multiplication algorithm
  # CS = (C, S), C is (w+1)-bits, and S is w bits. C gets sign-extended for addition in the inner j loop
  t = [Z(0)]*n 
  for i in range(n): 
      CS = oa0[0]*ob0[i] - oa1[0]*ob1[i] + t[0]  
      S = CS % 2^w
      C = CS >> w 
      mm = S
      for j in range(1, n): 
          CS = oa0[j]*ob0[i] - oa1[j]*ob1[i] + mm*m[j] + t[j] + C  
          S = CS % 2^w
          C = CS >> w
          t[j-1] = S 
      t[n-1] = C 
    
  # Assembling result, not needed in hw
  e = 0
  for i in range(n):
      e += t[i]*2^(w*i)

  # check if sub result is negative and correct it to being positive
  if (e < 0):
    print "\nresult e is SMALLER than 0!\n"
    e += 2*p
  assert(e >= 0)
  assert(e <= 2*p) 

  # conversion to standard form
  ee = Fp(e*R)

  # direct result, for comparison
  c = Fp(a0*b0-a1*b1) 

  # verification of results
  assert(Z(c) == Z(ee))
 
  return e

def fp2_mult(a, b): 
  c = Fp2_element()
  a0 = a.r
  a1 = a.i
  b0 = b.r
  b1 = b.i
  c0 = fp_mont_mul_sub(a0, a1, b0, b1)
  c1 = fp_mont_mul_add(a0, a1, b0, b1)
  #c0 = Fp(a0*b0-a1*b1)
  #c1 = Fp(a0*b1+a1*b0)
  c.r = c0
  c.i = c1
  return c

def fp2_add(a, b):
  c = Fp2_element()
  a0 = a.r
  a1 = a.i
  b0 = b.r
  b1 = b.i
  c0 = a0+b0
  c1 = a1+b1
  if (c0 >= 2*p):
    c0 -= 2*p
  if (c1 >= 2*p):
    c1 -= 2*p
  c.r = c0
  c.i = c1
  return c

def fp2_sub(a, b):
  c = Fp2_element()
  a0 = a.r
  a1 = a.i
  b0 = b.r
  b1 = b.i
  c0 = a0-b0
  c1 = a1-b1
  if (c0 < 0):
    c0 += 2*p
  if (c1 < 0):
    c1 += 2*p
  c.r = c0
  c.i = c1
  return c


def xADD_and_mul(XP,ZP,XQ,ZQ,xPQ,zPQ):
  t0 = Fp2_element()
  t1 = Fp2_element()
  t2 = Fp2_element()
  t3 = Fp2_element() 
  t5 = Fp2_element()
  t6 = Fp2_element()
  t7 = Fp2_element()

  t0 = fp2_add(XP,ZP)
  t1 = fp2_sub(XP,ZP)

  t2 = fp2_add(XQ,ZQ)
  t3 = fp2_sub(XQ,ZQ)

  t6 = fp2_mult(t0,t3)      
  t7 = fp2_mult(t1,t2)  

  t0 = fp2_sub(t6,t7)
  t1 = fp2_add(t6,t7)

  t6 = fp2_mult(t0,t0)         
  t7 = fp2_mult(t1,t1) 

  t5 = fp2_mult(xPQ,t6) 

  XQ = fp2_mult(t7,zPQ)
  ZQ = t5

  return XQ,ZQ
 
 

def xADD_and_mul_hw(XP,ZP,XQ,ZQ,xPQ,zPQ):
  t0 = Fp2_element()
  t1 = Fp2_element()
  t2 = Fp2_element()
  t3 = Fp2_element()
  t4 = Fp2_element()
  t5 = Fp2_element() 

  t0 = fp2_add(XP,ZP)
  t1 = fp2_sub(XP,ZP)
  
  t4 = t0
  t5 = t1

  #fp2_write_to_file_in_hex(t4, n, "0-sage_xADD_t4_0.txt", "0-sage_xADD_t4_1.txt")
  #fp2_write_to_file_in_hex(t5, n, "0-sage_xADD_t5_0.txt", "0-sage_xADD_t5_1.txt")
  
  t0 = fp2_add(XQ,ZQ)
  t1 = fp2_sub(XQ,ZQ)

  t2 = fp2_mult(t1,t4)           
  t3 = fp2_mult(t0,t5)          
                          
  t0 = fp2_sub(t2,t3)
  t1 = fp2_add(t2,t3)                            
   
  t2 = fp2_mult(t1,t1)          
  t3 = fp2_mult(t0,t0)         
  
  t4 = t2 
  t5 = t3

  #fp2_write_to_file_in_hex(t4, n, "1-sage_xADD_t4_0.txt", "1-sage_xADD_t4_1.txt")
  #fp2_write_to_file_in_hex(t5, n, "1-sage_xADD_t5_0.txt", "1-sage_xADD_t5_1.txt")

  t2 = fp2_mult(zPQ,t4)         
  t3 = fp2_mult(xPQ,t5)           
  
  XQ = t2
  ZQ = t3

  return XQ,ZQ


def fp2_write_to_file_in_hex(a, n, FILE_NAME_0, FILE_NAME_1):
  fp0 = open(FILE_NAME_0, "w")
  fp1 = open(FILE_NAME_1, "w")
  a0 = a.r
  a1 = a.i
  oa0 = [Z(0)]*n
  oa1 = [Z(0)]*n
  for i in range(n):
    oa0[i] = Z((Z(a0) >> (w*i)) % 2^w)
    fp0.write(hex_format_element.format(oa0[i]))
    fp0.write("\n")
    oa1[i] = Z((Z(a1) >> (w*i)) % 2^w)
    fp1.write(hex_format_element.format(oa1[i]))
    fp1.write("\n")
  fp0.close()
  fp1.close() 

def fp2_write_to_file(a, n, FILE_NAME_0, FILE_NAME_1):
  fp0 = open(FILE_NAME_0, "w")
  fp1 = open(FILE_NAME_1, "w")
  a0 = a.r
  a1 = a.i
  oa0 = [Z(0)]*n
  oa1 = [Z(0)]*n
  for i in range(n):
    oa0[i] = Z((Z(a0) >> (w*i)) % 2^w)
    fp0.write(format_element.format(oa0[i]))
    fp0.write("\n")
    oa1[i] = Z((Z(a1) >> (w*i)) % 2^w)
    fp1.write(format_element.format(oa1[i]))
    fp1.write("\n")
  fp0.close()
  fp1.close()

def fp_write_to_file(a, FILE_NAME):
  fp = open(FILE_NAME, "w") 
  m = [Z(0)]*n 
  for i in range(n):
    m[i] = Z((Z(a) >> (w*i)) % 2^w)
    fp.write(format_element.format(m[i]))
    fp.write("\n") 
  fp.close() 

# write constants to memory
fp_write_to_file(p+1, "mem_p_plus_one.mem")
fp_write_to_file(2*p, "px2.mem")
fp_write_to_file(4*p, "px4.mem")


XP = Fp2_element()
ZP = Fp2_element()
XQ = Fp2_element()
ZQ = Fp2_element() 
xPQ = Fp2_element()
zPQ = Fp2_element()

XP = fp2_random_init(XP)
ZP = fp2_random_init(ZP)
XQ = fp2_random_init(XQ)
ZQ = fp2_random_init(ZQ) 
xPQ = fp2_random_init(xPQ)
zPQ = fp2_random_init(zPQ)
 
fp2_write_to_file(XP, n, "xADD_mem_XP_0.txt", "xADD_mem_XP_1.txt")
fp2_write_to_file(ZP, n, "xADD_mem_ZP_0.txt", "xADD_mem_ZP_1.txt")
fp2_write_to_file(XQ, n, "xADD_mem_XQ_0.txt", "xADD_mem_XQ_1.txt")
fp2_write_to_file(ZQ, n, "xADD_mem_ZQ_0.txt", "xADD_mem_ZQ_1.txt") 
fp2_write_to_file(xPQ, n, "xADD_mem_xPQ_0.txt", "xADD_mem_xPQ_1.txt")
fp2_write_to_file(zPQ, n, "xADD_mem_zPQ_0.txt", "xADD_mem_zPQ_1.txt")

# check if the hw-friendly sage function fits to the software one
(a, b) = xADD_and_mul(XP,ZP,XQ,ZQ,xPQ,zPQ)  

(e, f) = xADD_and_mul_hw(XP,ZP,XQ,ZQ,xPQ,zPQ) 

assert((a.r, a.i) == (e.r, e.i))
assert((b.r, b.i) == (f.r, f.i)) 

 
fp2_write_to_file(e, n, "sage_xADD_t2_0.txt", "sage_xADD_t2_1.txt")
fp2_write_to_file(f, n, "sage_xADD_t3_0.txt", "sage_xADD_t3_1.txt") 

 





