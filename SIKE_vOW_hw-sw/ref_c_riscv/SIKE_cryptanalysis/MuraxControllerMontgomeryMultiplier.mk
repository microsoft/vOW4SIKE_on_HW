CFLAGS += -DCONTROLLER_HARDWARE
CFLAGS += -DXDBLE_HARDWARE
CFLAGS += -DXADD_LOOP_HARDWARE
CFLAGS += -DGET_4_ISOG_AND_EVAL_4_ISOG_HARDWARE
CFLAGS += -DMontgomeryMultiplier_HARDWARE

VPATH += ../hardware/library/

INC += -I../hardware/include/

SOURCES += ../hardware/library/xDBLe_hw.c
SOURCES += ../hardware/library/xADD_loop_hw.c
SOURCES += ../hardware/library/get_4_isog_and_eval_4_isog_hw.c
SOURCES += ../hardware/library/fp2mul_mont_hw.c