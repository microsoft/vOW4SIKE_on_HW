###
 # Author:        Wen Wang <wen.wang.ww349@yale.edu>
 # Updated:       2021-04-12
 # Abstract:      Makefile for SIKE cryptanalysis test on the SW-HW co-design
###

ifeq ($(TARGET),x86)
  CC = /usr/bin/gcc
  CFLAGS = -O3 -std=gnu11 -march=native 
else
  DEBUG=no
  BENCH=no
  MULDIV=yes 
   
  SOURCES = util/crt.S \
            util/util.c \
            util/Murax.c

  HEADERS = util/util.h
   
  INC += -I../../murax/software/VexRiscvSocSoftware/libs/
  INC += -I../../murax/software/VexRiscvSocSoftware/projects/murax/libs/
  INC += -Iutil/
   
  LDSCRIPT = resources/linker.ld

  include resources/gcc.mk
  include resources/subproject.mk
  include $(TARGET).mk

endif  

OBJDIR = tests

PROJ_NAME=$(TARGET)_$(PROJ)

# Pick a prime for the P128 implementation. Available options: p_32_20, p_36_22
CFLAGS += -DP128
P128_PRIME=p_32_20
CFLAGS += -D$(P128_PRIME)

# P434
# CFLAGS += -DP434

CFLAGS += -D$(TARGET)
CFLAGS += -D_GENERIC_
CFLAGS += -D_X86_
CFLAGS += -D__LINUX__

 
LDFLAGS += -lm 

ifdef SIM
	CFLAGS += -DSIM
else
	CFLAGS += -DDE1_SoC
endif
 

all: $(OBJDIR)/$(PROJ_NAME)

SOURCES += ../../ref_c/random/random.c

SOURCES += ../../ref_c/SIKE_vOW_software/src/xxhash/xxhash.c
SOURCES += ../../ref_c/SIKE_vOW_software/src/aes/aes.c
SOURCES += ../../ref_c/SIKE_vOW_software/src/aes/aes_c.c
SOURCES += ../../ref_c/SIKE_vOW_software/src/sha3/fips202.c

SOURCES += ../../ref_c/SIKE_vOW_software/src/prng.c
SOURCES += ../../ref_c/SIKE_vOW_software/src/sike_vow.c
SOURCES += ../../ref_c/SIKE_vOW_software/src/sike_vow_constants.c

SOURCES += ../../ref_c/SIKE_vOW_software/src/P128/P128.c
SOURCES += ../../ref_c/SIKE_vOW_software/src/P128/generic/fp_generic.c

# SOURCES += ../../ref_c/SIKE_vOW_software/src/P434/P434.c
# SOURCES += ../../ref_c/SIKE_vOW_software/src/P434/generic/fp_generic.c

SOURCES += tests/test_extras.c 


$(OBJDIR)/$(TARGET)_%: $(OBJDIR)/%.c $(SOURCES) $(OBJS) $(HEADERS)
	$(CC) $(CFLAGS) $(INC) -o $@ $(SOURCES) $< $(LDFLAGS)


ifeq ($(TARGET),x86)
run: $(OBJDIR)/$(PROJ_NAME)
	$(OBJDIR)/$(PROJ_NAME)
else
run: all
	/opt/riscv/bin/riscv64-unknown-elf-gdb \
         -ex "target remote localhost:3333" \
         -ex "set remotetimeout 60" \
         -ex "set arch riscv:rv32" \
         -ex "monitor reset halt" \
         -ex "load" \
         -ex "continue" \
         $(OBJDIR)/$(PROJ_NAME)
endif
# -ex "break 604" \

clean:
	rm -rf *.req objs434* objs503* objs610* objs751* objs lib434* lib503* lib610* lib751* sidh434* sidh503* sidh610* sidh751* sike434* sike503* sike610* sike751* arith_tests-*
	-$(RM) test_SIKE434 $(OBJDIR)/$(PROJ_NAME)
	-$(RM) $(UI) tests/*.map tests/Murax_test_vOW_SIKE