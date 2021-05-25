SHELL := /bin/bash


TARGET_DIR = $(shell pwd)

BUS_WIDTH = 32
RADIX = 32
prime = 128
prime_round = 128
WIDTH_REAL = $(shell python -c "from math import ceil; print int(ceil($(prime_round)/$(RADIX)))")

SK_MEM_WIDTH = $(BUS_WIDTH)
SK_MEM_DEPTH = 32 # fixed  

DSP=yes

MONTMUL_ONE_CYCLE_PATH = ../../src/hardware/Montgomery_multiplier_one_cycle_pipeline
MONTMUL_TWO_CYCLE_PATH = ../../src/hardware/Montgomery_multiplier_two_cycle_pipeline
ADD_SOURCE_RTL = ../../src/hardware/fp2_sub_add_correction
TOP_CONTROLLER_RTL = ../../src/hardware/top_controller

RTL = ../rtl

gen_verilog_files: $(ADD_SOURCE_RTL)/gen_serial_comparator.py
	python $(ADD_SOURCE_RTL)/gen_serial_comparator.py -w $(RADIX) -n $(WIDTH_REAL) > serial_comparator.v
	python $(TOP_CONTROLLER_RTL)/gen_mem_wrapper.py -w $(RADIX) -d $(WIDTH_REAL) -n 4 > memory_4_to_1_wrapper.v
	python $(TOP_CONTROLLER_RTL)/gen_mem_wrapper.py -w $(RADIX) -d $(WIDTH_REAL) -n 3 > memory_3_to_1_wrapper.v
	python $(TOP_CONTROLLER_RTL)/gen_mem_wrapper.py -w $(RADIX) -d $(WIDTH_REAL) -n 2 > memory_2_to_1_wrapper.v

set_params: 
	sed -i 's/.*parameter RADIX =.*/  parameter RADIX = $(RADIX),/' $(RTL)/Apb3Fp2MontMultiplier_RADIX_32.v
	sed -i 's/.*parameter WIDTH_REAL =.*/  parameter WIDTH_REAL = $(WIDTH_REAL),/' $(RTL)/Apb3Fp2MontMultiplier_RADIX_32.v
	sed -i 's/.*parameter RADIX =.*/  parameter RADIX = $(RADIX),/' $(RTL)/Apb3Fp2MontMultiplier_RADIX_64.v
	sed -i 's/.*parameter WIDTH_REAL =.*/  parameter WIDTH_REAL = $(WIDTH_REAL),/' $(RTL)/Apb3Fp2MontMultiplier_RADIX_64.v
	sed -i 's/.*parameter RADIX =.*/  parameter RADIX = $(RADIX),/' $(RTL)/Apb3Controller_RADIX_32.v
	sed -i 's/.*parameter WIDTH_REAL =.*/  parameter WIDTH_REAL = $(WIDTH_REAL),/' $(RTL)/Apb3Controller_RADIX_32.v
	sed -i 's/.*parameter SK_MEM_WIDTH =.*/  parameter SK_MEM_WIDTH = $(SK_MEM_WIDTH),/' $(RTL)/Apb3Controller_RADIX_32.v
	sed -i 's/.*parameter SK_MEM_DEPTH =.*/  parameter SK_MEM_DEPTH = $(SK_MEM_DEPTH),/' $(RTL)/Apb3Controller_RADIX_32.v
	sed -i 's/.*parameter RADIX =.*/  parameter RADIX = $(RADIX),/' $(RTL)/Apb3Controller_RADIX_64.v
	sed -i 's/.*parameter WIDTH_REAL =.*/  parameter WIDTH_REAL = $(WIDTH_REAL),/' $(RTL)/Apb3Controller_RADIX_64.v
	sed -i 's/.*parameter SK_MEM_WIDTH =.*/  parameter SK_MEM_WIDTH = $(SK_MEM_WIDTH),/' $(RTL)/Apb3Controller_RADIX_64.v
	sed -i 's/.*parameter SK_MEM_DEPTH =.*/  parameter SK_MEM_DEPTH = $(SK_MEM_DEPTH),/' $(RTL)/Apb3Controller_RADIX_64.v
	sed -i 's/.*parameter RADIX =.*/  parameter RADIX = $(RADIX),/' $(RTL)/Apb3ControllerMontMul_RADIX_32.v
	sed -i 's/.*parameter WIDTH_REAL =.*/  parameter WIDTH_REAL = $(WIDTH_REAL),/' $(RTL)/Apb3ControllerMontMul_RADIX_32.v
	sed -i 's/.*parameter SK_MEM_WIDTH =.*/  parameter SK_MEM_WIDTH = $(SK_MEM_WIDTH),/' $(RTL)/Apb3ControllerMontMul_RADIX_32.v
	sed -i 's/.*parameter SK_MEM_DEPTH =.*/  parameter SK_MEM_DEPTH = $(SK_MEM_DEPTH),/' $(RTL)/Apb3ControllerMontMul_RADIX_32.v
	sed -i 's/.*parameter RADIX =.*/  parameter RADIX = $(RADIX),/' $(RTL)/Apb3ControllerMontMul_RADIX_64.v
	sed -i 's/.*parameter WIDTH_REAL =.*/  parameter WIDTH_REAL = $(WIDTH_REAL),/' $(RTL)/Apb3ControllerMontMul_RADIX_64.v
	sed -i 's/.*parameter SK_MEM_WIDTH =.*/  parameter SK_MEM_WIDTH = $(SK_MEM_WIDTH),/' $(RTL)/Apb3ControllerMontMul_RADIX_64.v
	sed -i 's/.*parameter SK_MEM_DEPTH =.*/  parameter SK_MEM_DEPTH = $(SK_MEM_DEPTH),/' $(RTL)/Apb3ControllerMontMul_RADIX_64.v
	sed -i 's/.*(* use_dsp = ".*/ (* use_dsp = "$(DSP)" *) module multiplier/' $(MONTMUL_TWO_CYCLE_PATH)/multiplier.v

# constants during Montgomery multiplication
mem_p_plus_one.mem: ../AC701/gen_p_mem.sage 
	sage ../AC701/gen_p_mem.sage -w $(RADIX) -prime $(prime) -R $(prime_round) -sw $(SK_MEM_WIDTH) -sd $(SK_MEM_DEPTH)

px2.mem: mem_p_plus_one.mem

px4.mem: px2.mem

$(TARGET).v:  
	make -C ../Murax TARGET=$(TARGET) TARGET_DIR=$(TARGET_DIR)
	cp ../Murax/cpu0.yaml .

gen_clean:
	rm -rf $(TARGET).v *.v serial_comparator.v ../AC701/serial_comparator.v
	rm -rf cpu0.yaml *.src

