###
 # Author:        Wen Wang <wen.wang.ww349@yale.edu>
 # Updated:       2021-04-12
 # Abstract:      Makefile for testing get_4_isog hardware
###

SHELL := /bin/bash

SEED = 17

RADIX = 32
prime = 128 
prime_round = 128

WIDTH_REAL = $(shell python -c "from math import ceil; print int(ceil($(prime_round)/$(RADIX)))")

WIDTH = $(WIDTH_REAL)

all: run

UTIL = ../../util
ADD_SOURCE_RTL = ../../fp2_sub_add_correction
ADDER_SOURCE_RTL = ../../fp_sub_and_add
MUL_SOURCE_RTL = ../../fp2_mont_mul_one_cycle_pipeline
STEP_SOURCE_RTL = ../../Montgomery_multiplier_two_cycle_pipeline

include $(ADD_SOURCE_RTL)/gen.mk

gen_input: gen_test.sage
	sage gen_test.sage -w $(RADIX) -prime $(prime) -R $(prime_round) -s $(SEED) 

serial_comparator.v: $(ADD_SOURCE_RTL)/gen_serial_comparator.py 
	python $(ADD_SOURCE_RTL)/gen_serial_comparator.py -w $(RADIX) -n $(WIDTH) > serial_comparator.v

controller_tb: $(UTIL)/clog2.v $(UTIL)/delay.v $(UTIL)/single_port_mem.v controller_tb.v ../controller.v ../get_4_isog_FSM.v ../double_to_single_memory_wrapper.v $(MUL_SOURCE_RTL)/fp2_mont_mul.v $(STEP_SOURCE_RTL)/step_sub.v $(STEP_SOURCE_RTL)/step_add.v $(STEP_SOURCE_RTL)/multiplier.v $(ADD_SOURCE_RTL)/fp2_sub_add_correction.v serial_comparator.v $(ADDER_SOURCE_RTL)/unit_adder.v $(ADDER_SOURCE_RTL)/fp_adder.v
	@iverilog -Wall -DRADIX=$(RADIX) -DWIDTH_REAL=$(WIDTH_REAL) -Wno-timescale $^ -o controller_tb 

tb: controller_tb
	./controller_tb 

run: gen_input tb
	@diff sim_t5_0.txt sage_get_4_isog_t5_0.txt
	@diff sim_t5_1.txt sage_get_4_isog_t5_1.txt
	@diff sim_t1_0.txt sage_get_4_isog_t1_0.txt
	@diff sim_t1_1.txt sage_get_4_isog_t1_1.txt
	@diff sim_t2_0.txt sage_get_4_isog_t2_0.txt
	@diff sim_t2_1.txt sage_get_4_isog_t2_1.txt
	@diff sim_t3_0.txt sage_get_4_isog_t3_0.txt
	@diff sim_t3_1.txt sage_get_4_isog_t3_1.txt
	@diff sim_t4_0.txt sage_get_4_isog_t4_0.txt
	@diff sim_t4_1.txt sage_get_4_isog_t4_1.txt 

diff:
	diff sim_t5_0.txt sage_get_4_isog_t5_0.txt
	diff sim_t5_1.txt sage_get_4_isog_t5_1.txt
	diff sim_t1_0.txt sage_get_4_isog_t1_0.txt
	diff sim_t1_1.txt sage_get_4_isog_t1_1.txt
	diff sim_t4_0.txt sage_get_4_isog_t4_0.txt
	diff sim_t4_1.txt sage_get_4_isog_t4_1.txt 
	diff sim_t3_0.txt sage_get_4_isog_t3_0.txt
	diff sim_t3_1.txt sage_get_4_isog_t3_1.txt


clean:
	rm -f *.sage.py controller_tb *.txt *.vcd *.sage.py *.mem serial_comparator.v
