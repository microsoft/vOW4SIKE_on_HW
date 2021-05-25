set fileName [lindex $argv 1]

catch {set fptr [open $fileName r]} ;
set contents [read -nonewline $fptr] ;
close $fptr ;

set splitCont [split $contents "\n"] ;
foreach f $splitCont {
  puts $f
  set pat ".vhd"
  if [string match *$pat $f] {
    read_vhdl $f
  } else {
    read_verilog $f
  }
}

set module [lindex $argv 0]

# set partname "xc7s50csga324-1"
# set brd_part "digilentinc.com:arty-s7-50:part0:1.0"

# set partname "xc7a200tfbg676-1"
# set partname "xczu9eg-ffvb1156-1-e"
# set partname "xc7vx690tffg1157-3"
# set partname "xc7a200tfbg676-3"

set partname [lindex $argv 2]

set_property SEVERITY {Warning} [get_drc_checks NSTD-1]
set_property SEVERITY {Warning} [get_drc_checks UCIO-1]

# synth_design -part $partname -top $module
# When IO exceeds limits
synth_design -part $partname -top $module -mode out_of_context

read_xdc board.xdc

report_clocks

opt_design
place_design
route_design

report_utilization
report_timing


#write_verilog -force synth_system.v
# write_bitstream -force synth_system.bit

