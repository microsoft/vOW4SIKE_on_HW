def_params:
	sed -i 's/.*RADIX = .*/RADIX = $(RADIX)/' Makefile
	sed -i 's/.*prime = .*/prime = $(prime)/' Makefile
	sed -i 's/.*prime_round = .*/prime_round = $(prime_round)/' Makefile
	sed -i 's/.*DSP = .*/DSP = $(DSP)/' Makefile
	sed -i 's/.*create_clock -add -name sys_clk_pin -period.*/create_clock -add -name sys_clk_pin -period $(PERIOD) [get_ports { clk }];/' Makefile