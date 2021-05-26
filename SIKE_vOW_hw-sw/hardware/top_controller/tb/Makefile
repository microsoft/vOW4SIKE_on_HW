###
 # Author:        Wen Wang <wen.wang.ww349@yale.edu>
 # Updated:       2021-04-12
 # Abstract:      Makefile for testing top controller
###

SHELL := /bin/bash
 
SEED = 12345 
LOOPS = 10
SK_WIDTH = 32
SK_DEPTH = 32
START_INDEX = 0
END_INDEX = 2

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
CONTROLLER_RTL = ../../controller_xDBL_get_4_isog_xADD_eval_4_isog
CONTROLLER_XDBL_RTL = ../../controller_xDBL
CONTROLLER_GET_4_ISOG_RTL = ../../controller_get_4_isog
CONTROLLER_EVAL_4_ISOG_RTL = ../../controller_eval_4_isog
CONTROLLER_XADD_RTL = ../../controller_xADD
OPT_DIR = opt

include $(ADD_SOURCE_RTL)/gen.mk

gen_mem_wrapper_4: ../gen_mem_wrapper.py
	python ../gen_mem_wrapper.py -w $(RADIX) -d $(WIDTH_REAL) -n 4 > ../memory_wrapper_4_to_1_wrapper.v

gen_mem_wrapper_3: ../gen_mem_wrapper.py
	python ../gen_mem_wrapper.py -w $(RADIX) -d $(WIDTH_REAL) -n 3 > ../memory_wrapper_3_to_1_wrapper.v

gen_mem_wrapper_2: ../gen_mem_wrapper.py
	python ../gen_mem_wrapper.py -w $(RADIX) -d $(WIDTH_REAL) -n 2 > ../memory_wrapper_2_to_1_wrapper.v

gen_input: gen_mem_wrapper_4 gen_mem_wrapper_3 gen_mem_wrapper_2 gen_test.sage
	sage gen_test.sage -w $(RADIX) -prime $(prime) -R $(prime_round) -l $(LOOPS) -b $(START_INDEX) -e $(END_INDEX) -sw $(SK_WIDTH) -sd $(SK_DEPTH) #-s $(SEED)

top_tb: $(UTIL)/clog2.v $(UTIL)/delay.v $(UTIL)/single_port_mem.v top_tb.v ../$(OPT_DIR)/top_controller.v ../memory_wrapper_4_to_1_wrapper.v ../memory_wrapper_3_to_1_wrapper.v ../memory_wrapper_2_to_1_wrapper.v $(CONTROLLER_RTL)/controller.v $(CONTROLLER_RTL)/single_to_double_memory_wrapper.v $(CONTROLLER_XDBL_RTL)/xDBL_FSM.v $(CONTROLLER_GET_4_ISOG_RTL)/get_4_isog_FSM.v $(CONTROLLER_EVAL_4_ISOG_RTL)/eval_4_isog_FSM.v $(CONTROLLER_XADD_RTL)/xADD_FSM.v $(MUL_SOURCE_RTL)/fp2_mont_mul.v $(STEP_SOURCE_RTL)/step_sub.v $(STEP_SOURCE_RTL)/step_add.v $(STEP_SOURCE_RTL)/multiplier.v $(ADD_SOURCE_RTL)/fp2_sub_add_correction.v $(ADD_SOURCE_RTL)/serial_comparator.v $(ADDER_SOURCE_RTL)/unit_adder.v $(ADDER_SOURCE_RTL)/fp_adder.v
	@iverilog -Wall -DRADIX=$(RADIX) -DWIDTH_REAL=$(WIDTH_REAL) -DLOOPS=$(LOOPS) -DSK_WIDTH=$(SK_WIDTH) -DSK_DEPTH=$(SK_DEPTH) -DSTART_INDEX=$(START_INDEX) -DEND_INDEX=$(END_INDEX)  -Wno-timescale $^ -o top_tb 

tb: top_tb
	./top_tb 

run: gen_input tb 
	@diff sage_XQ_0.txt sim_XQ_0.txt
	@diff sage_XQ_1.txt sim_XQ_1.txt
	@diff sage_ZQ_0.txt sim_ZQ_0.txt
	@diff sage_ZQ_1.txt sim_ZQ_1.txt
	@diff sage_xPQ_0.txt sim_xPQ_0.txt
	@diff sage_xPQ_1.txt sim_xPQ_1.txt 
	@diff sage_zPQ_1.txt sim_zPQ_1.txt
	@diff sage_X_0.txt sim_X_0.txt	
	@diff sage_X_1.txt sim_X_1.txt
	@diff sage_Z_0.txt sim_Z_0.txt	
	@diff sage_Z_1.txt sim_Z_1.txt
	@diff sage_A24_0.txt sim_A24_0.txt
	@diff sage_A24_1.txt sim_A24_1.txt
	@diff sage_C24_0.txt sim_C24_0.txt
	@diff sage_C24_1.txt sim_C24_1.txt
	@diff 0-sim_t10_0.txt 0-sage_eval_4_isog_t10_0.txt
	@diff 0-sim_t10_1.txt 0-sage_eval_4_isog_t10_1.txt
	@diff 0-sim_t11_0.txt 0-sage_eval_4_isog_t11_0.txt
	@diff 0-sim_t11_1.txt 0-sage_eval_4_isog_t11_1.txt
	@diff 1-sim_t10_0.txt 1-sage_eval_4_isog_t10_0.txt
	@diff 1-sim_t10_1.txt 1-sage_eval_4_isog_t10_1.txt
	@diff 1-sim_t11_0.txt 1-sage_eval_4_isog_t11_0.txt
	@diff 1-sim_t11_1.txt 1-sage_eval_4_isog_t11_1.txt
	@diff 2-sim_t10_0.txt 2-sage_eval_4_isog_t10_0.txt
	@diff 2-sim_t10_1.txt 2-sage_eval_4_isog_t10_1.txt
	@diff 2-sim_t11_0.txt 2-sage_eval_4_isog_t11_0.txt
	@diff 2-sim_t11_1.txt 2-sage_eval_4_isog_t11_1.txt 

diff:
	diff sage_X_0.txt sim_X_0.txt	
	diff sage_X_1.txt sim_X_1.txt
	diff sage_Z_0.txt sim_Z_0.txt	
	diff sage_Z_1.txt sim_Z_1.txt
	diff sage_XQ_0.txt sim_XQ_0.txt
	diff sage_XQ_1.txt sim_XQ_1.txt
	diff sage_ZQ_0.txt sim_ZQ_0.txt
	diff sage_ZQ_1.txt sim_ZQ_1.txt
	diff sage_xPQ_0.txt sim_xPQ_0.txt
	diff sage_xPQ_1.txt sim_xPQ_1.txt 
	diff sage_zPQ_1.txt sim_zPQ_1.txt
	diff sage_A24_0.txt sim_A24_0.txt
	diff sage_A24_1.txt sim_A24_1.txt
	diff sage_C24_0.txt sim_C24_0.txt
	diff sage_C24_1.txt sim_C24_1.txt
	diff 0-sim_t10_0.txt 0-sage_eval_4_isog_t10_0.txt
	diff 0-sim_t10_1.txt 0-sage_eval_4_isog_t10_1.txt
	diff 0-sim_t11_0.txt 0-sage_eval_4_isog_t11_0.txt
	diff 0-sim_t11_1.txt 0-sage_eval_4_isog_t11_1.txt
	diff 1-sim_t10_0.txt 1-sage_eval_4_isog_t10_0.txt
	diff 1-sim_t10_1.txt 1-sage_eval_4_isog_t10_1.txt
	diff 1-sim_t11_0.txt 1-sage_eval_4_isog_t11_0.txt
	diff 1-sim_t11_1.txt 1-sage_eval_4_isog_t11_1.txt
	diff 2-sim_t10_0.txt 2-sage_eval_4_isog_t10_0.txt
	diff 2-sim_t10_1.txt 2-sage_eval_4_isog_t10_1.txt
	diff 2-sim_t11_0.txt 2-sage_eval_4_isog_t11_0.txt
	diff 2-sim_t11_1.txt 2-sage_eval_4_isog_t11_1.txt	

clean:
	rm -f top_tb *.txt *.vcd *.sage.py *.mem $(ADD_SOURCE_RTL)/serial_comparator.v ../memory_wrapper_4_to_1_wrapper.v memory_wrapper_4_to_1_wrapper.v ../memory_wrapper_3_to_1_wrapper.v memory_wrapper_3_to_1_wrapper.v ../memory_wrapper_2_to_1_wrapper.v memory_wrapper_2_to_1_wrapper.v
