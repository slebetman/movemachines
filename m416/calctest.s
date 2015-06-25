##########
# Set-up script for calculator test
##########
# Common commands for set-up scripts:
#   newRam - clears memory
#   loadFile <file> - loads an m416 ram file into memory
#   source <file> - loads another set-up script or tcl script
#	loadDevice <file> <args> - loads a device file
#
# Note that this set up script refers to files relative to itself.
#
# This is a full Tcl script so anything goes here. Some other interesting
# commands to use in this script are:
#   startSim - automatically start simulation after loading this file
#   setValue <address> <value> - write directly to memory location
##########

exec tclsh m416asm.tcl calctest.as > calctest.416
newRam
loadFile calctest.416
loadDevice {./devices/Calculator.dev} 0x1000 0x1001 0x1002 0x1003
#console show
