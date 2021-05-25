## This file is a general .xdc for the AC701 board 
## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project

## Clock signal 
## Real FPGA programming
# 3.3v 90MHz FPGA_EMCCLK
set_property -dict { PACKAGE_PIN P16 IOSTANDARD LVCMOS33 } [get_ports {CLK}]; 
create_clock -add -name sys_clk_pin -period 11.100 [get_ports { CLK }]; 
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets CLK_IBUF] 

# To get Fmax:
#create_clock -add -name sys_clk_pin -period 6.0 [get_ports { CLK }]; 
 
## JTAG Interface
# https://www.ftdichip.com/Support/Documents/DataSheets/Cables/DS_C232HM_MPSSE_CABLE.PDF

# Red: Power -> J16-1 

# Black: GND J16-3  

# Brown -> J16-5 FMC H31
set_property -dict { PACKAGE_PIN K22   IOSTANDARD LVCMOS25 } [get_ports { TMS }]; # FMC POS: J16-5

# Orange -> J16-7 FMC H32
set_property -dict { PACKAGE_PIN K23   IOSTANDARD LVCMOS25 } [get_ports { TCK }]; # FMC POS: J16-7
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets TCK_IBUF] 

# Yellow -> J16-9 FMC G30
set_property -dict { PACKAGE_PIN G24   IOSTANDARD LVCMOS25 } [get_ports { TDI }]; # FMC POS: J16-9

# Green -> J16-11 FMC G31
set_property -dict { PACKAGE_PIN F24   IOSTANDARD LVCMOS25 } [get_ports { TDO }]; # FMC POS: J16-11 
  
 

## USB-UART Interface 
# https://www.ftdichip.com/Support/Documents/DataSheets/Cables/DS_TTL-232RG_CABLES.pdf
# red -> J16-2

# black: GND -> J16-4

# brown: GND FMC: J19-2

# green: GND FMC: J5-2

# Orange -> J16-8 FMC H35
set_property -dict { PACKAGE_PIN D25   IOSTANDARD LVCMOS25 } [get_ports { UART_TXD }]; # FMC POS: J16-8
  
# Yellow -> J16-10 FMC G33
set_property -dict { PACKAGE_PIN E26   IOSTANDARD LVCMOS25 } [get_ports { UART_RXD }]; # FMC POS: J16-10 

## RESET
#FPGA: CPU_RESET; U4
set_property -dict { PACKAGE_PIN U4   IOSTANDARD SSTL15 } [get_ports { RST }];  
 
 
## Configuration options, can be used for all designs
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]

 
