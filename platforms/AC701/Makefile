###
 # Author:        Wen Wang <wen.wang.ww349@yale.edu>
 # Updated:       2021-04-12
 # Abstract:      Makefile for SW-HW co-design testing
###

SHELL := /bin/bash

# TOPLEVEL=Murax 
TOPLEVEL=MuraxControllerMontgomeryMultiplier

# PARTNAME=xc7vx690tffg1157-3
PARTNAME=xc7a200tfbg676-3

BOARD=ac701
 
PROJECT = $(TARGET)

SRC = $(TARGET).src
  

SOURCE_FILES = $(shell grep -v '\#' ../DE1-SoC/$(PROJECT).qsf | grep  "VERILOG_FILE\|VHDL_FILE\|TEXT_FILE" | cut -d " " -f 4)

all: synth_system.bit

include ../DE1-SoC/gen.mk

REPORT=report-TOPLEVEL-$(TOPLEVEL)-RADIX-$(RADIX)-prime-$(prime)-prime_round-$(prime_round)-WIDTH_REAL-$(WIDTH_REAL)-partname-$(PARTNAME)-DSP-$(DSP).txt
 
$(SRC):  set_params ../DE1-SoC/$(PROJECT).qsf 
	sed -i 's/.*component Murax.*/component $(TARGET)/' src/main.vhd
	sed -i 's/.*core: Murax.*/  core: $(TARGET) port map(/' src/main.vhd	
	echo $(SOURCE_FILES) | sed "s/ /\n/g" > $(SRC)
	echo "src/main.vhd" >> $(SRC) 

synth_system.bit: gen_verilog_files $(SOURCE_FILES) $(SRC) mem_p_plus_one.mem px2.mem px4.mem 
	vivado -nojournal -log log.log -mode batch -source $(BOARD).tcl -tclargs main $(SRC) $(PARTNAME) | tee -a $(REPORT)

program: synth_system.bit
	vivado -nojournal -log program.log -mode batch -source program.tcl -tclargs xc7a200t synth_system.bit

#debug: projects/murax/demo/build/demo.hex
#	/opt/riscv/bin/riscv64-unknown-elf-gdb projects/murax/demo/build/demo.elf -x gdb.txt

clean: gen_clean
	rm -rf $(SRC) serial_comparator.v memory_4_to_1_wrapper.v memory_3_to_1_wrapper.v memory_2_to_1_wrapper.v
	rm -rf *.sage.py .Xil *.log *.bin mul* *.mem synth_system.bit usage_statistics_webtalk.html usage_statistics_webtalk.xml vivado.jou fsm_encoding.os *.jou

