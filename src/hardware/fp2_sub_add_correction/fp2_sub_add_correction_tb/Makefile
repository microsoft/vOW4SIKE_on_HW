SHELL := /bin/bash


SEED = 125

RADIX = 32
prime = 128 
prime_round = 128

# RADIX = 64
# prime = 377 
# prime_round = 384

# RADIX = 64
# prime = 434
# prime_round = 448

# RADIX = 32
# prime = 503 
# prime_round = 512

# RADIX = 32
# prime = 610 
# prime_round = 640
 
# RADIX = 16
# prime = 751 
# prime_round = 768

cmd = 5
extension_field = 1

WIDTH = $(shell python -c "from math import ceil; print int(ceil($(prime_round)/$(RADIX)))")

UTIL = ../../util
ADD_SOURCE_RTL = ..
ADDER_RTL = ../../fp_sub_and_add

all: run

include ../gen.mk

gen_input: gen_test.sage
	sage gen_test.sage -w $(RADIX) --prime $(prime) -R $(prime_round) --cmd $(cmd) --ef $(extension_field) #-s $(SEED) 

fp2_sub_add_correction_tb: $(UTIL)/clog2.v $(UTIL)/delay.v $(UTIL)/single_port_mem.v fp2_sub_add_correction_tb.v ../fp2_sub_add_correction.v $(ADD_SOURCE_RTL)/serial_comparator.v $(ADDER_RTL)/unit_adder.v $(ADDER_RTL)/fp_adder.v  
	@iverilog -Wall -DRADIX=$(RADIX) -DDIGITS=$(WIDTH) -DCMD=$(cmd) -DEXTENSION_FIELD=$(extension_field) -Wno-timescale $^ -o fp2_sub_add_correction_tb 

tb: fp2_sub_add_correction_tb
	./fp2_sub_add_correction_tb 

run: gen_input tb
	@diff Sage_c_0.txt Simulation_c_0.txt
ifeq ($(extension_field), 1) 
	@diff Sage_c_1.txt Simulation_c_1.txt 
endif

clean: gen_clean
	rm -f fp2_sub_add_correction_tb *.vcd *.txt *.sage.py *.mem  