RADIX = 64
SEED = 12302121

# testing purpose
# p = 2^32*3^20*23-1  
# prime = 128
# prime_round = 128

# p = 2^191*3^117-1
prime = 377
# prime_round = 384
prime_round = 408

#p = 2^216*3^137-1
# prime = 434
# prime_round = 448
# prime_round = 456
# prime_round = 442
# prime_round = 459

#p = 2^250*3^159-1
# prime = 503
# prime_round = 512
# prime_round = 528
# prime_round = 510

#p = 2^372*3^239-1
# prime = 751
# prime_round = 768
#prime_round = 782
# prime_round = 765

WIDTH = $(shell python -c "from math import ceil; print int(ceil($(prime_round)/$(RADIX)))")

BOARD=board

TARGET = proj

SRC = $(TARGET).src
 
all: synth_system.bit

set_params:
	sed -i 's/.*parameter RADIX =.*/  parameter RADIX = $(RADIX),/' ../Montgomery_multiplier_sub.v
	sed -i 's/.*parameter WIDTH =.*/  parameter WIDTH = $(WIDTH),/' ../Montgomery_multiplier_sub.v

synth_system.bit: set_params $(SRC)  
	vivado -nojournal -log log.log -mode batch -source $(BOARD).tcl -tclargs Montgomery_multiplier_sub $(SRC)

program: synth_system.bit #xczu9eg xc7a200t
	vivado -nojournal -log program.log -mode batch -source program.tcl -tclargs xczu9eg synth_system.bit

#debug: projects/murax/demo/build/demo.hex
#	/opt/riscv/bin/riscv64-unknown-elf-gdb projects/murax/demo/build/demo.elf -x gdb.txt

clean:  
	rm -rf .Xil *.log *.bin *.mem synth_system.bit usage_statistics_webtalk.html usage_statistics_webtalk.xml vivado.jou fsm_encoding.os *.jou

