##########
# Set-up script for test.416
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

newRam
loadFile counter.416
loadDevice {./devices/7 seg LED 16bit.dev} 0x200 0x201