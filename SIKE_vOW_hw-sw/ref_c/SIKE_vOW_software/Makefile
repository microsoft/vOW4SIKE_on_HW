####  Makefile for compilation on Linux  ####

OPT=-O3   # Optimization option by default

CC=gcc

# Pick a prime for the P128 implementation. Available options: p_32_20, p_36_22
P128_PRIME=p_32_20

# ld sometimes struggles finding -lgomp. The following variable points it directly there.
LDOMP=-L/usr/lib/x86_64-linux-gnu/ -l:libgomp.so.1

ifeq "$(CC)" "gcc"
    COMPILER=gcc
else ifeq "$(CC)" "clang"
    COMPILER=clang
endif

ARCHITECTURE=_AMD64_
USE_OPT_LEVEL=_FAST_
ifeq "$(ARCH)" "x64"
    ARCHITECTURE=_AMD64_
    USE_OPT_LEVEL=_FAST_
else ifeq "$(ARCH)" "x86"
    ARCHITECTURE=_X86_
    USE_OPT_LEVEL=_GENERIC_
endif

ifeq "$(OPT_LEVEL)" "GENERIC"
    USE_OPT_LEVEL=_GENERIC_
endif

ifeq "$(ARCHITECTURE)" "_AMD64_"
	ifeq "$(USE_OPT_LEVEL)" "_FAST_"
		MULX=-D _MULX_
		ifeq "$(USE_MULX)" "FALSE"
			MULX=
		else
			ADX=-D _ADX_
			ifeq "$(USE_ADX)" "FALSE"
				ADX=
			endif
		endif
	endif
endif

ifeq "$(SET)" "EXTENDED"
    ADDITIONAL_SETTINGS=-fwrapv -fomit-frame-pointer -march=native
endif

AR=ar rcs
RANLIB=ranlib

CFLAGS=$(OPT) $(ADDITIONAL_SETTINGS) -D $(ARCHITECTURE) -D __LINUX__ -D $(USE_OPT_LEVEL) -D $(P128_PRIME) $(MULX) $(ADX) -fPIE
LDFLAGS=-lm

ifeq "$(ARCHITECTURE)" "_AMD64_"
ifeq "$(USE_OPT_LEVEL)" "_FAST_"
CFLAGS += -mavx2 -maes -msse2
endif
endif

ifeq "$(USE_OPT_LEVEL)" "_GENERIC_"
    EXTRA_OBJECTS_128=objs128/fp_generic.o
    EXTRA_OBJECTS_377=objs377/fp_generic.o
    EXTRA_OBJECTS_434=objs434/fp_generic.o
    EXTRA_OBJECTS_503=objs503/fp_generic.o
    EXTRA_OBJECTS_546=objs546/fp_generic.o
    EXTRA_OBJECTS_610=objs610/fp_generic.o
    EXTRA_OBJECTS_697=objs697/fp_generic.o
    EXTRA_OBJECTS_751=objs751/fp_generic.o
else ifeq "$(USE_OPT_LEVEL)" "_FAST_"
ifeq "$(ARCHITECTURE)" "_AMD64_"
	EXTRA_OBJECTS_128=objs128/fp_x64.o objs128/fp_x64_asm.o
	EXTRA_OBJECTS_377=objs377/fp_x64.o objs377/fp_x64_asm.o
	EXTRA_OBJECTS_434=objs434/fp_x64.o objs434/fp_x64_asm.o
	EXTRA_OBJECTS_503=objs503/fp_x64.o objs503/fp_x64_asm.o
	EXTRA_OBJECTS_546=objs546/fp_x64.o objs546/fp_x64_asm.o
	EXTRA_OBJECTS_610=objs610/fp_x64.o objs610/fp_x64_asm.o
	EXTRA_OBJECTS_697=objs697/fp_x64.o objs697/fp_x64_asm.o
	EXTRA_OBJECTS_751=objs751/fp_x64.o objs751/fp_x64_asm.o
	CFLAGS+= -fPIC
endif
endif
OBJECTS_128=objs128/P128.o $(EXTRA_OBJECTS_128) objs/random.o objs/fips202.o
OBJECTS_377=objs377/P377.o $(EXTRA_OBJECTS_377) objs/random.o objs/fips202.o
OBJECTS_434=objs434/P434.o $(EXTRA_OBJECTS_434) objs/random.o objs/fips202.o
OBJECTS_503=objs503/P503.o $(EXTRA_OBJECTS_503) objs/random.o objs/fips202.o
OBJECTS_546=objs546/P546.o $(EXTRA_OBJECTS_546) objs/random.o objs/fips202.o
OBJECTS_610=objs610/P610.o $(EXTRA_OBJECTS_610) objs/random.o objs/fips202.o
OBJECTS_697=objs697/P697.o $(EXTRA_OBJECTS_697) objs/random.o objs/fips202.o
OBJECTS_751=objs751/P751.o $(EXTRA_OBJECTS_751) objs/random.o objs/fips202.o

all: lib128 lib377 lib434 lib503 lib546 lib610 lib697 lib751 tests tests_vow_sike

objs128/%.o: src/P128/%.c
	@mkdir -p $(@D)
	$(CC) -c $(CFLAGS) $< -o $@

objs377/%.o: src/P377/%.c
	@mkdir -p $(@D)
	$(CC) -c $(CFLAGS) $< -o $@

objs434/%.o: src/P434/%.c
	@mkdir -p $(@D)
	$(CC) -c $(CFLAGS) $< -o $@

objs503/%.o: src/P503/%.c
	@mkdir -p $(@D)
	$(CC) -c $(CFLAGS) $< -o $@

objs546/%.o: src/P546/%.c
	@mkdir -p $(@D)
	$(CC) -c $(CFLAGS) $< -o $@

objs610/%.o: src/P610/%.c
	@mkdir -p $(@D)
	$(CC) -c $(CFLAGS) $< -o $@

objs697/%.o: src/P697/%.c
	@mkdir -p $(@D)
	$(CC) -c $(CFLAGS) $< -o $@

objs751/%.o: src/P751/%.c
	@mkdir -p $(@D)
	$(CC) -c $(CFLAGS) $< -o $@


ifeq "$(USE_OPT_LEVEL)" "_GENERIC_"
objs128/fp_generic.o: src/P128/generic/fp_generic.c
	$(CC) -c $(CFLAGS) src/P128/generic/fp_generic.c -o objs128/fp_generic.o

objs377/fp_generic.o: src/P377/generic/fp_generic.c
	$(CC) -c $(CFLAGS) src/P377/generic/fp_generic.c -o objs377/fp_generic.o

objs434/fp_generic.o: src/P434/generic/fp_generic.c
	$(CC) -c $(CFLAGS) src/P434/generic/fp_generic.c -o objs434/fp_generic.o

objs503/fp_generic.o: src/P503/generic/fp_generic.c
	$(CC) -c $(CFLAGS) src/P503/generic/fp_generic.c -o objs503/fp_generic.o

objs546/fp_generic.o: src/P546/generic/fp_generic.c
	$(CC) -c $(CFLAGS) src/P546/generic/fp_generic.c -o objs546/fp_generic.o

objs610/fp_generic.o: src/P610/generic/fp_generic.c
	$(CC) -c $(CFLAGS) src/P610/generic/fp_generic.c -o objs610/fp_generic.o

objs697/fp_generic.o: src/P697/generic/fp_generic.c
	$(CC) -c $(CFLAGS) src/P697/generic/fp_generic.c -o objs697/fp_generic.o

objs751/fp_generic.o: src/P751/generic/fp_generic.c
	$(CC) -c $(CFLAGS) src/P751/generic/fp_generic.c -o objs751/fp_generic.o
else ifeq "$(USE_OPT_LEVEL)" "_FAST_"
ifeq "$(ARCHITECTURE)" "_AMD64_"
objs128/fp_x64.o: src/P128/AMD64/fp_x64.c
	$(CC) -c $(CFLAGS) src/P128/AMD64/fp_x64.c -o objs128/fp_x64.o

objs128/fp_x64_asm.o: src/P128/AMD64/fp_x64_asm.S
	$(CC) -c $(CFLAGS) src/P128/AMD64/fp_x64_asm.S -o objs128/fp_x64_asm.o

objs377/fp_x64.o: src/P377/AMD64/fp_x64.c
	$(CC) -c $(CFLAGS) src/P377/AMD64/fp_x64.c -o objs377/fp_x64.o

objs377/fp_x64_asm.o: src/P377/AMD64/fp_x64_asm.S
	$(CC) -c $(CFLAGS) src/P377/AMD64/fp_x64_asm.S -o objs377/fp_x64_asm.o

objs434/fp_x64.o: src/P434/AMD64/fp_x64.c
	$(CC) -c $(CFLAGS) src/P434/AMD64/fp_x64.c -o objs434/fp_x64.o

objs434/fp_x64_asm.o: src/P434/AMD64/fp_x64_asm.S
	$(CC) -c $(CFLAGS) src/P434/AMD64/fp_x64_asm.S -o objs434/fp_x64_asm.o

objs503/fp_x64.o: src/P503/AMD64/fp_x64.c
	$(CC) -c $(CFLAGS) src/P503/AMD64/fp_x64.c -o objs503/fp_x64.o

objs503/fp_x64_asm.o: src/P503/AMD64/fp_x64_asm.S
	$(CC) -c $(CFLAGS) src/P503/AMD64/fp_x64_asm.S -o objs503/fp_x64_asm.o

objs546/fp_x64.o: src/P546/AMD64/fp_x64.c
	$(CC) -c $(CFLAGS) src/P546/AMD64/fp_x64.c -o objs546/fp_x64.o

objs546/fp_x64_asm.o: src/P546/AMD64/fp_x64_asm.S
	$(CC) -c $(CFLAGS) src/P546/AMD64/fp_x64_asm.S -o objs546/fp_x64_asm.o

objs610/fp_x64.o: src/P610/AMD64/fp_x64.c
	$(CC) -c $(CFLAGS) src/P610/AMD64/fp_x64.c -o objs610/fp_x64.o

objs610/fp_x64_asm.o: src/P610/AMD64/fp_x64_asm.S
	$(CC) -c $(CFLAGS) src/P610/AMD64/fp_x64_asm.S -o objs610/fp_x64_asm.o

objs697/fp_x64.o: src/P697/AMD64/fp_x64.c
	$(CC) -c $(CFLAGS) src/P697/AMD64/fp_x64.c -o objs697/fp_x64.o

objs697/fp_x64_asm.o: src/P697/AMD64/fp_x64_asm.S
	$(CC) -c $(CFLAGS) src/P697/AMD64/fp_x64_asm.S -o objs697/fp_x64_asm.o

objs751/fp_x64.o: src/P751/AMD64/fp_x64.c
	$(CC) -c $(CFLAGS) src/P751/AMD64/fp_x64.c -o objs751/fp_x64.o

objs751/fp_x64_asm.o: src/P751/AMD64/fp_x64_asm.S
	$(CC) -c $(CFLAGS) src/P751/AMD64/fp_x64_asm.S -o objs751/fp_x64_asm.o
endif
endif

INDEPENDENT_OBJS=objs/random.o objs/fips202.o objs/prng.o objs/sike_vow.o objs/sike_vow_constants.o objs/xxhash.o
objs/random.o: src/random/random.c
objs/fips202.o: src/sha3/fips202.c
objs/prng.o: src/prng.c
objs/sike_vow.o: src/sike_vow.c
objs/sike_vow_constants.o: src/sike_vow_constants.c
objs/xxhash.o: src/xxhash/xxhash.c

DEPENDENT_OBJS_128=objs/sike_vow128.o objs/sike_vow_constants128.o 
objs/sike_vow128.o: src/sike_vow.c
objs/sike_vow_constants128.o: src/sike_vow_constants.c
$(DEPENDENT_OBJS_128):
	@mkdir -p $(@D)
	$(CC) -c $(CFLAGS) -D P128 $< -o $@

DEPENDENT_OBJS_377=objs/sike_vow377.o objs/sike_vow_constants377.o
objs/sike_vow377.o: src/sike_vow.c
$(DEPENDENT_OBJS_377):
	@mkdir -p $(@D)
	$(CC) -c $(CFLAGS) -D P377 $< -o $@

DEPENDENT_OBJS_434=objs/sike_vow434.o objs/sike_vow_constants434.o
objs/sike_vow434.o: src/sike_vow.c
$(DEPENDENT_OBJS_434):
	@mkdir -p $(@D)
	$(CC) -c $(CFLAGS) -D P434 $< -o $@

$(INDEPENDENT_OBJS):
	@mkdir -p $(@D)
	$(CC) -c $(CFLAGS) $< -o $@

lib128: $(OBJECTS_128)
	rm -rf lib128 sike128
	mkdir lib128 sike128
	$(AR) lib128/libsidh.a $^
	$(RANLIB) lib128/libsidh.a

lib377: $(OBJECTS_377)
	rm -rf lib377 sike377
	mkdir lib377 sike377
	$(AR) lib377/libsidh.a $^
	$(RANLIB) lib377/libsidh.a

lib434: $(OBJECTS_434)
	rm -rf lib434 sike434
	mkdir lib434 sike434
	$(AR) lib434/libsidh.a $^
	$(RANLIB) lib434/libsidh.a

lib503: $(OBJECTS_503)
	rm -rf lib503 sike503
	mkdir lib503 sike503
	$(AR) lib503/libsidh.a $^
	$(RANLIB) lib503/libsidh.a

lib546: $(OBJECTS_546)
	rm -rf lib546 sike546
	mkdir lib546 sike546
	$(AR) lib546/libsidh.a $^
	$(RANLIB) lib546/libsidh.a

lib610: $(OBJECTS_610)
	rm -rf lib610 sike610
	mkdir lib610 sike610
	$(AR) lib610/libsidh.a $^
	$(RANLIB) lib610/libsidh.a

lib697: $(OBJECTS_697)
	rm -rf lib697 sike697
	mkdir lib697 sike697
	$(AR) lib697/libsidh.a $^
	$(RANLIB) lib697/libsidh.a

lib751: $(OBJECTS_751)
	rm -rf lib751 sike751
	mkdir lib751 sike751
	$(AR) lib751/libsidh.a $^
	$(RANLIB) lib751/libsidh.a

tests: lib128 lib377 lib434 lib503 lib546 lib610 lib697 lib751
	$(CC) $(CFLAGS) -L./lib128 tests/arith_tests-p128.c tests/test_extras.c -lsidh $(LDFLAGS) -o arith_tests-p128
	$(CC) $(CFLAGS) -L./lib377 tests/arith_tests-p377.c tests/test_extras.c -lsidh $(LDFLAGS) -o arith_tests-p377
	$(CC) $(CFLAGS) -L./lib434 tests/arith_tests-p434.c tests/test_extras.c -lsidh $(LDFLAGS) -o arith_tests-p434
	$(CC) $(CFLAGS) -L./lib503 tests/arith_tests-p503.c tests/test_extras.c -lsidh $(LDFLAGS) -o arith_tests-p503
	$(CC) $(CFLAGS) -L./lib546 tests/arith_tests-p546.c tests/test_extras.c -lsidh $(LDFLAGS) -o arith_tests-p546
	$(CC) $(CFLAGS) -L./lib610 tests/arith_tests-p610.c tests/test_extras.c -lsidh $(LDFLAGS) -o arith_tests-p610
	$(CC) $(CFLAGS) -L./lib697 tests/arith_tests-p697.c tests/test_extras.c -lsidh $(LDFLAGS) -o arith_tests-p697
	$(CC) $(CFLAGS) -L./lib751 tests/arith_tests-p751.c tests/test_extras.c -lsidh $(LDFLAGS) -o arith_tests-p751

tests_sike377: lib377
	$(CC) $(CFLAGS) -L./lib377 tests/test_SIKEp377.c tests/test_extras.c -lsidh $(LDFLAGS) -o sike377/test_SIKE
tests_sike434: lib434
	$(CC) $(CFLAGS) -L./lib434 tests/test_SIKEp434.c tests/test_extras.c -lsidh $(LDFLAGS) -o sike434/test_SIKE
tests_sike503: lib503
	$(CC) $(CFLAGS) -L./lib503 tests/test_SIKEp503.c tests/test_extras.c -lsidh $(LDFLAGS) -o sike503/test_SIKE
tests_sike546: lib546
	$(CC) $(CFLAGS) -L./lib546 tests/test_SIKEp546.c tests/test_extras.c -lsidh $(LDFLAGS) -o sike546/test_SIKE
tests_sike610: lib610
	$(CC) $(CFLAGS) -L./lib610 tests/test_SIKEp610.c tests/test_extras.c -lsidh $(LDFLAGS) -o sike610/test_SIKE
tests_sike697: lib697
	$(CC) $(CFLAGS) -L./lib697 tests/test_SIKEp697.c tests/test_extras.c -lsidh $(LDFLAGS) -o sike697/test_SIKE
tests_sike751: lib751
	$(CC) $(CFLAGS) -L./lib751 tests/test_SIKEp751.c tests/test_extras.c -lsidh $(LDFLAGS) -o sike751/test_SIKE

tests_sike: tests_sike377 tests_sike434 tests_sike503 tests_sike546 tests_sike610 tests_sike697 tests_sike751
	
# AES
AES_OBJS=objs/aes/aes.o objs/aes/aes_c.o
objs/aes/aes.o: src/aes/aes.c
objs/aes/aes_c.o: src/aes/aes_c.c
ifeq "$(ARCHITECTURE)" "_AMD64_"
ifeq "$(USE_OPT_LEVEL)" "_FAST_"
AES_OBJS=objs/aes/aes.o objs/aes/aes_ni.o
objs/aes/aes.o: src/aes/aes.c
objs/aes/aes_ni.o: src/aes/aes_ni.c
endif
endif
$(AES_OBJS):
	@mkdir -p $(@D)
	$(CC) -c $(CFLAGS) $< -o $@

## vOW against a SIKE 2-isogeny tree

vow_sike128: objs/sike_vow128.o objs/prng.o objs/sike_vow_constants128.o objs/xxhash.o objs/fips202.o $(AES_OBJS)
	rm -rf vow_sike
	mkdir vow_sike
	$(AR) vow_sike/libvow_sike.a $^
	$(RANLIB) vow_sike/libvow_sike.a

vow_sike377: objs/sike_vow377.o objs/prng.o objs/sike_vow_constants.o objs/xxhash.o objs/fips202.o $(AES_OBJS)
	rm -rf vow_sike
	mkdir vow_sike
	$(AR) vow_sike/libvow_sike.a $^
	$(RANLIB) vow_sike/libvow_sike.a

vow_sike434: objs/sike_vow434.o objs/prng.o objs/sike_vow_constants.o objs/xxhash.o objs/fips202.o $(AES_OBJS)
	rm -rf vow_sike
	mkdir vow_sike
	$(AR) vow_sike/libvow_sike.a $^
	$(RANLIB) vow_sike/libvow_sike.a

vow_sike: vow_sike128 vow_sike377 vow_sike434 

tests_vow_sike128: vow_sike128 lib128
	$(CC) $(CFLAGS) -D P128 -L./vow_sike -L./lib128 tests/test_vOW_SIKE.c tests/test_extras.c -lvow_sike -lsidh $(LDFLAGS) -o test_vOW_SIKE_128
	
tests_vow_sike377: vow_sike377 lib377
	$(CC) $(CFLAGS) -D P377 -L./vow_sike -L./lib377 tests/test_vOW_SIKE.c tests/test_extras.c -lvow_sike -lsidh $(LDFLAGS) -o test_vOW_SIKE_377

tests_vow_sike434: vow_sike434 lib434
	$(CC) $(CFLAGS) -D P434 -L./vow_sike -L./lib434 tests/test_vOW_SIKE.c tests/test_extras.c -lvow_sike -lsidh $(LDFLAGS) -o test_vOW_SIKE_434

tests_vow_sike: tests_vow_sike128 tests_vow_sike377 tests_vow_sike434

check: tests tests_sike tests_vow_sike

.PHONY: clean

clean:
	rm -rf *.req objs* lib* sike* arith_tests-* vow_* test_vOW_*
