TOPLEVEL=eval_4_isog_FSM
# TOPLEVEL=controller
PARTNAME=xc7vx690tffg1157-3
# PARTNAME=xc7a200tfbg676-3

RADIX=32
prime=434
prime_round=448

WIDTH_REAL = $(shell python -c "from math import ceil; print int(ceil($(prime_round)/$(RADIX)))")

WIDTH = $(WIDTH_REAL)

BOARD=board

DSP=yes

TARGET=proj

SRC=$(TARGET).src

ADD_SOURCE_RTL = ../../fp2_sub_add_correction
 
all: synth_system.bit

include $(ADD_SOURCE_RTL)/gen.mk

REPORT=report-TOPLEVEL-$(TOPLEVEL)-RADIX-$(RADIX)-prime-$(prime)-prime_round-$(prime_round)-WIDTH_REAL-$(WIDTH_REAL)-partname-$(PARTNAME)-DSP-$(DSP).txt

 
set_params: $(ADD_SOURCE_RTL)/serial_comparator.v
	sed -i 's/.*parameter RADIX =.*/  parameter RADIX = $(RADIX),/' ../controller.v
	sed -i 's/.*parameter WIDTH_REAL =.*/  parameter WIDTH_REAL = $(WIDTH_REAL),/' ../controller.v
	sed -i 's/.*(* use_dsp = ".*/ (* use_dsp = "$(DSP)" *) module multiplier/' ../../Montgomery_multiplier_two_cycle_pipeline/multiplier.v

synth_system.bit: set_params $(SRC)   
	vivado -nojournal -log log.log -mode batch -source $(BOARD).tcl -tclargs $(TOPLEVEL) $(SRC) $(PARTNAME) | tee -a $(REPORT)

program: synth_system.bit #xczu9eg xc7a200t
	vivado -nojournal -log program.log -mode batch -source program.tcl -tclargs xczu9eg synth_system.bit

#debug: projects/murax/demo/build/demo.hex
#	/opt/riscv/bin/riscv64-unknown-elf-gdb projects/murax/demo/build/demo.elf -x gdb.txt

clean: gen_clean
	rm -rf .Xil *.log *.bin *.mem synth_system.bit usage_statistics_webtalk.html usage_statistics_webtalk.xml vivado.jou fsm_encoding.os *.jou

