set device  [lindex $argv 0]
set bitfile [lindex $argv 1]

puts "device:   $device"
puts "bit file: $bitfile"

open_hw

connect_hw_server

open_hw_target

foreach d [get_hw_devices] {
  puts $d
  if { [string match $device* $d] } { 
    set dev $d
    break
  }
}

current_hw_device [get_hw_devices $dev]
refresh_hw_device -update_hw_probes false [lindex [get_hw_devices $dev] 0]

set_property PROGRAM.FILE $bitfile [get_hw_devices $dev]
set_property PROBES.FILE {} [get_hw_devices $dev]
set_property FULL_PROBES.FILE {} [get_hw_devices $dev]
set_property PROGRAM.FILE $bitfile [get_hw_devices $dev]

program_hw_devices [get_hw_devices $dev]

refresh_hw_device [lindex [get_hw_devices $dev] 0]

