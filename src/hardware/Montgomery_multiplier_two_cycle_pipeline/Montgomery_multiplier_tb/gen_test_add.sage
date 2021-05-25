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
#n_32 = int(log(R,2)/32)
#w_32 = 32
n_32 = n
w_32 = w

# force unsigned arithmetic
Z = IntegerRing()
Fr = IntegerModRing(R)
pp = Fr(-p^-1)
assert((pp % 2^w) == 1)

OK=true

for k in range(1):

    oa0 = [Z(0)]*n
    ob0 = [Z(0)]*n
    oa1 = [Z(0)]*n
    ob1 = [Z(0)]*n 

    a0 = Z(0)
    b0 = Z(0)
    a1 = Z(0)
    b1 = Z(0)
    
    # read in a_0
    with open("mem_0_a_0.txt") as file_in:
        lines = []
        for line in file_in:
            lines.append(line)
    file_in.close()

    for i in range(n_32):
        x = Z(int(lines[i], 16)) 
        a0 += Z(x*2^(w_32*i)) 
    
    # read in a_1
    with open("mem_0_a_1.txt") as file_in:
        lines = []
        for line in file_in:
            lines.append(line)
    file_in.close()
    
    for i in range(n_32):
        x = Z(int(lines[i], 16)) 
        a1 += x*2^(w_32*i)
    
    # read in b_0
    with open("mem_0_b_0.txt") as file_in:
        lines = []
        for line in file_in:
            lines.append(line)
    file_in.close()

    for i in range(n_32):
        x = Z(int(lines[i], 16))
        b0 += x*2^(w_32*i)

    # read in b_1
    with open("mem_0_b_1.txt") as file_in:
        lines = []
        for line in file_in:
            lines.append(line)
    file_in.close()

    for i in range(n_32):
        x = Z(int(lines[i], 16))
        b1 += x*2^(w_32*i)

    f_a_0 = open("mult_" + str(k) + "_a_0" + ".txt", "w");
    f_a_1 = open("mult_" + str(k) + "_a_1" + ".txt", "w");
    f_b_0 = open("mult_" + str(k) + "_b_0" + ".txt", "w");
    f_b_1 = open("mult_" + str(k) + "_b_1" + ".txt", "w");
    
    # direct result, for comparison 
    c = Fp(a0*b1+a1*b0)
    
    # main algorithm: integrated multi-precision multiplication and Montgomery reduction
    # algorithm in operand scanning form - FIOS (schoolbook)
    # compute MontRed(a0*b1+a1*b0)
    # preliminaries
    m = [Z(0)]*n

    f_c_1 = open("mem_c_1.mem", "w"); 

    for i in range(n):
        m[i] = ((p+1) >> (w*i)) % 2^w
        f_c_1.write(format_element.format(m[i]))
        f_c_1.write("\n")
     
    for i in range(n):  
        oa0[i] = Z((Z(a0) >> (w*i)) % 2^w) 
        f_a_0.write(hex_format_element.format(oa0[i]))
        f_a_0.write("\n")
        ob0[i] = Z((Z(b0) >> (w*i)) % 2^w)
        f_b_1.write(hex_format_element.format(ob0[i]))
        f_b_1.write("\n")
        oa1[i] = Z((Z(a1) >> (w*i)) % 2^w)
        f_b_0.write(hex_format_element.format(oa1[i]))
        f_b_0.write("\n")
        ob1[i] = Z((Z(b1) >> (w*i)) % 2^w)
        f_a_1.write(hex_format_element.format(ob1[i]))
        f_a_1.write("\n")
   
    f_a_0.close()
    f_a_1.close()
    f_b_0.close()
    f_b_1.close()
    f_c_1.close()
    
    # actual Montgomery multiplication algorithm
    # CS = (C, S), C is (w+1)-bits, and S is w bits. C gets sign-extended for addition in the inner j loop
    t = [Z(0)]*n
    f_res = open("mult_" + str(k) + "_res_sage" + ".txt", "w")
    f_sum = open("mult_" + str(k) + "_sum_sage" + ".txt", "w")
    f_carry = open("mult_" + str(k) + "_carry_sage" + ".txt", "w")
    f_CS = open("mult_" + str(k) + "_CS_sage" + ".txt", "w")
    f_res_all = open("mult_" + str(k) + "_add_res_all_sage" + ".txt", "w") 

    for i in range(n): 
        CS = oa0[0]*ob1[i] + oa1[0]*ob0[i] + t[0] 
        f_CS.write(bindigits(CS, 2*w+2))
        f_CS.write("\n")
        S = CS % 2^w
        C = CS >> w
        f_sum.write(format_element.format(S))
        f_sum.write("\n") 
        f_carry.write(bindigits(C, w+2))
        f_carry.write("\n")
        mm = S
        for j in range(1, n): 
            CS = oa0[j]*ob1[i] + oa1[j]*ob0[i] + mm*m[j] + t[j] + C 
            f_CS.write(bindigits(CS, 2*w+2))
            f_CS.write("\n")
            S = CS % 2^w
            C = CS >> w
            t[j-1] = S
            f_sum.write(format_element.format(S))
            f_sum.write("\n") 
            f_res_all.write(str(i) + "  ")

            f_res_all.write(str(j-1) + "  ")
            f_res_all.write(hex_format_element.format(t[j-1]))
            f_res_all.write("\n") 
            f_carry.write(bindigits(C, w+2))
            f_carry.write("\n")
        t[n-1] = C  
        f_res_all.write(str(i) + "  ")
        f_res_all.write(str(n-1) + "  ")
        f_res_all.write(hex_format_element.format(t[n-1]))
        f_res_all.write("\n\n")
    
    f_sum.close()
    f_carry.close()
    f_CS.close()
    f_res_all.close()

    
    # Assembling result, not needed in hw
    e = 0
    for i in range(n):
        e += t[i]*2^(w*i)
 
    assert(e >= 0)
    assert(e <= 2*p)
    '''    
    if (e > p):
        print "correcting p\n"
        e -= p
    '''
    oe = [Z(0)]*n

    for i in range(n):  
        oe[i] = Z((Z(e) >> (w*i)) % 2^w)

    for i in range(n):
        f_res.write(hex_format_element.format(oe[i]))
        f_res.write("\n")
    
    f_res.close()
    
    # conversion to Montgomery form*R
    e = Fp(e*R)
    
    # verification of results
    if (Z(c) != Z(e)):
        OK = false
        break

if OK:
    print "Sage Software Verification Result:"
    print "    PASSED"
    print "\n"
else:
    print "FAILED"
    print "\n"
