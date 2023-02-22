##########
# Set-up script for test.416
##########
# Common commands for set-up scripts:
#	assemble <source file> <target file> - executes the m416 assembler
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

assemble counter3_516.as counter3.516
newRam
loadFile counter3.516
loadDevice {./devices/Calculator.dev} 0xf000 0xf001 0xf002 0xf003
