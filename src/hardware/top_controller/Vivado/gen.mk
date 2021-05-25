gen: gen_mem_wrapper_4 gen_mem_wrapper_3 gen_mem_wrapper_2

gen_mem_wrapper_4: ../gen_mem_wrapper.py
	python ../gen_mem_wrapper.py -w $(RADIX) -d $(WIDTH_REAL) -n 4 > ../memory_4_to_1_wrapper.v

gen_mem_wrapper_3: ../gen_mem_wrapper.py
	python ../gen_mem_wrapper.py -w $(RADIX) -d $(WIDTH_REAL) -n 3 > ../memory_3_to_1_wrapper.v

gen_mem_wrapper_2: ../gen_mem_wrapper.py
	python ../gen_mem_wrapper.py -w $(RADIX) -d $(WIDTH_REAL) -n 2 > ../memory_2_to_1_wrapper.v


