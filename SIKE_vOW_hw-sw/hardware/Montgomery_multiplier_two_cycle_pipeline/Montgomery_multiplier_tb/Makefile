SHELL := /bin/bash

RADIX = 32
SEED = 2023

## testing purpose
## p = 2^32*3^20*23-1  
# prime = 128
# prime_round = 128

## p = 2^191*3^117-1
# prime = 377
# prime_round = 384
# prime_round = 382
# prime_round = 408

##p = 2^216*3^137-1
prime = 434
prime_round = 448
# prime_round = 512
# prime_round = 456
# prime_round = 442
# prime_round = 459

##p = 2^250*3^159-1
# prime = 503
# prime_round = 512
# prime_round = 508
# prime_round = 528
# prime_round = 510

##p = 2^372*3^239-1
# prime = 751
# prime_round = 768
# prime_round = 760 
# prime_round = 782
# prime_round = 765

WIDTH = $(shell python -c "from math import ceil; print int(ceil($(prime_round)/$(RADIX)))")

all: run_add run_sub

UTIL = ../../util
C_SRC_PATH = ../../../ref_c_riscv/2020_SIKE/

gen_input:
	make -C $(C_SRC_PATH) TARGET=x86 PROJ=fp2_mul_test clean
	make -C $(C_SRC_PATH) TARGET=x86 PROJ=fp2_mul_test run
	cp $(C_SRC_PATH)/*.txt . 

gen_res_sub: gen_input gen_test_sub.sage 
	sage gen_test_sub.sage -w $(RADIX) -s $(SEED) 

gen_res_add: gen_input gen_test_add.sage 
	sage gen_test_add.sage -w $(RADIX) -s $(SEED)   

Montgomery_multiplier_sub_tb: $(UTIL)/clog2.v $(UTIL)/delay.v $(UTIL)/single_port_mem.v Montgomery_multiplier_tb.v ../Montgomery_multiplier_sub.v ../step_sub.v ../multiplier.v
	sed -i 's/\bMontgomery_multiplier\b/Montgomery_multiplier_sub/g' Montgomery_multiplier_tb.v
	iverilog -Wall -DRADIX=$(RADIX) -DWIDTH=$(WIDTH) -Wno-timescale $^ -o Montgomery_multiplier_sub_tb
	sed -i 's/\Montgomery_multiplier_sub\b/Montgomery_multiplier/g' Montgomery_multiplier_tb.v

Montgomery_multiplier_add_tb: $(UTIL)/clog2.v $(UTIL)/delay.v $(UTIL)/single_port_mem.v Montgomery_multiplier_tb.v ../Montgomery_multiplier_add.v ../step_add.v ../multiplier.v
	sed -i 's/\bMontgomery_multiplier\b/Montgomery_multiplier_add/g' Montgomery_multiplier_tb.v
	iverilog -Wall -DRADIX=$(RADIX) -DWIDTH=$(WIDTH) -Wno-timescale $^ -o Montgomery_multiplier_add_tb
	sed -i 's/\Montgomery_multiplier_add\b/Montgomery_multiplier/g' Montgomery_multiplier_tb.v	

mem_c_1.mem: gen_res_sub
	
tb_sub: Montgomery_multiplier_sub_tb
	./Montgomery_multiplier_sub_tb

tb_add: Montgomery_multiplier_add_tb
	./Montgomery_multiplier_add_tb

run_sub: gen_res_sub tb_sub
	@diff mult_0_res_sage.txt mult_0_res_sim.txt
	@diff mult_1_res_sage.txt mult_1_res_sim.txt

run_add: gen_res_add tb_add
	@diff mult_0_res_sage.txt mult_0_res_sim.txt
	@diff mult_1_res_sage.txt mult_1_res_sim.txt

clean:
	rm -f *.sage.py Montgomery_multiplier_tb *.txt *.vcd *.sage.py *.mem Montgomery_multiplier_sub_tb Montgomery_multiplier_add_tb