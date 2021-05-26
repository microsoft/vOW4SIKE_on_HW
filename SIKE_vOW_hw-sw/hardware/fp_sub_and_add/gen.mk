SHELL := /bin/bash
 
$(ADD_SOURCE_RTL)/serial_comparator.v: $(ADD_SOURCE_RTL)/gen_serial_comparator.py 
	python $(ADD_SOURCE_RTL)/gen_serial_comparator.py -w $(RADIX) -n $(WIDTH) > $(ADD_SOURCE_RTL)/serial_comparator.v

gen_clean:
	rm -f $(ADD_SOURCE_RTL)/serial_comparator.v