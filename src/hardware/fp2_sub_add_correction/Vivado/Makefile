TOPLEVEL=fp2_sub_add_correction
PARTNAME=xc7vx690tffg1157-3
# PARTNAME=xc7a200tfbg676-3

RADIX=32
prime=434
prime_round=448

WIDTH = $(shell python -c "from math import ceil; print int(ceil($(prime_round)/$(RADIX)))")

BOARD=board

TARGET=proj

SRC=$(TARGET).src


ADD_SOURCE_RTL = ..
ADDER_RTL = ../../fp_sub_and_add

 
all: synth_system.bit


include ../gen.mk

REPORT=report-RADIX-$(RADIX)-prime-$(prime)-prime_round-$(prime_round)-WIDTH-$(WIDTH_REAL)-partname-$(PARTNAME).txt

 
set_params: $(ADD_SOURCE_RTL)/serial_comparator.v
	sed -i 's/.*parameter RADIX =.*/  parameter RADIX = $(RADIX),/' ../fp2_sub_add_correction.v
	sed -i 's/.*parameter DIGITS =.*/  parameter DIGITS = $(WIDTH),/' ../fp2_sub_add_correction.v 

synth_system.bit: set_params $(SRC)   
	vivado -nojournal -log log.log -mode batch -source $(BOARD).tcl -tclargs $(TOPLEVEL) $(SRC) $(PARTNAME) | tee -a $(REPORT)

program: synth_system.bit #xczu9eg xc7a200t
	vivado -nojournal -log program.log -mode batch -source program.tcl -tclargs xczu9eg synth_system.bit

#debug: projects/murax/demo/build/demo.hex
#	/opt/riscv/bin/riscv64-unknown-elf-gdb projects/murax/demo/build/demo.elf -x gdb.txt

clean: gen_clean
	rm -rf .Xil *.log *.bin *.mem synth_system.bit usage_statistics_webtalk.html usage_statistics_webtalk.xml vivado.jou fsm_encoding.os *.jou

