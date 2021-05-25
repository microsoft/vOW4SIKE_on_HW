
TARGETS = $(shell ls Murax*.qsf | sed "s/\.qsf//" | sed "s/_precomp/ PRECOMP=yes/" | sort  | paste -sd "," - | sed "s/,/, /g")

ifndef TARGET
  $(error $(TARGET) Choose TARGET from list "$(TARGETS)", eg. "make TARGET=MuraxChain PRECOMP=yes")
endif
 
PROJECT = $(TARGET)
  
SOURCE_FILES = $(shell grep -v '\#' $(PROJECT).qsf | grep  "VERILOG_FILE\|TEXT_FILE" | cut -d " " -f 4)

include quartus.mk

include gen.mk

clean:
	make quartus_clean
	make gen_clean *.sof

