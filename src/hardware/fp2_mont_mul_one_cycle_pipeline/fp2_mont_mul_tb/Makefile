###
 # Author:        Wen Wang <wen.wang.ww349@yale.edu>
 # Updated:       2021-04-12
 # Abstract:      Makefile for testing F(p^2) multiplier
###

SHELL := /bin/bash

SEED = 123

RADIX = 32
prime = 128 
prime_round = 128 

# RADIX = 32
# prime = 503 
# prime_round = 512

# RADIX = 32
# prime = 434 
# prime_round = 448 

# RADIX = 128
# prime = 503 
# prime_round = 512

# RADIX = 128
# prime = 610 
# prime_round = 640

# RADIX = 64
# prime = 751 
# prime_round = 768

WIDTH_REAL = $(shell python -c "from math import ceil; print int(ceil($(prime_round)/$(RADIX)))")

all: run

UTIL = ../../util
SRC = ../../Montgomery_multiplier_two_cycle_pipeline
C_SRC_PATH = ../../../ref_c_riscv/2020_SIKE_cryptanalysis/

gen_input_C: 
	make -C $(C_SRC_PATH) TARGET=x86 PROJ=fp2_mul_test clean
	make -C $(C_SRC_PATH) TARGET=x86 PROJ=fp2_mul_test run
	cp $(C_SRC_PATH)/*.txt .

gen_input_Sage: gen_input.sage
	sage gen_input.sage -w $(RADIX) -prime $(prime) -R $(prime_round) #-s $(SEED) 

gen_res_sub: $(SRC)/Montgomery_multiplier_tb/gen_test_sub.sage 
	sage $(SRC)/Montgomery_multiplier_tb/gen_test_sub.sage -w $(RADIX) -prime $(prime) -R $(prime_round) -s $(SEED) 
	cp mult_0_res_sage.txt sub_mult_res_sage.txt 

gen_res_add: $(SRC)/Montgomery_multiplier_tb/gen_test_add.sage 
	sage $(SRC)/Montgomery_multiplier_tb/gen_test_add.sage -w $(RADIX) -prime $(prime) -R $(prime_round) -s $(SEED) 
	cp mult_0_res_sage.txt add_mult_res_sage.txt 

fp2_mont_mul_tb: $(UTIL)/clog2.v $(UTIL)/delay.v $(UTIL)/single_port_mem.v fp2_mont_mul_tb.v ../../fp_sub_and_add/fp_adder.v ../../fp_sub_and_add/unit_adder.v ../fp2_mont_mul.v $(SRC)/step_sub.v $(SRC)/step_add.v $(SRC)/multiplier.v 
	@iverilog -Wall -DRADIX=$(RADIX) -DWIDTH_REAL=$(WIDTH_REAL) -Wno-timescale $^ -o fp2_mont_mul_tb 

mem_c_1.mem: gen_res_sub

tb: fp2_mont_mul_tb
	./fp2_mont_mul_tb 

run: gen_input_Sage gen_res_add gen_res_sub tb 
	@diff sub_mult_res_sage.txt sub_mult_res_sim.txt
	@diff add_mult_res_sage.txt add_mult_res_sim.txt 

clean:
	rm -f fp2_mont_mul_tb *.txt *.vcd *.sage.py *.mem
