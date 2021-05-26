## This file is a general .xdc for the FPGA board 
## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project

## Clock signal  
create_clock -add -name sys_clk_pin -period 5.40 [get_ports { clk }];
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets clk_IBUF]  
 
 
## Configuration options, can be used for all designs
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]

 