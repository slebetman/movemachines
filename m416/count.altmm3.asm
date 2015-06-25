# 7 segment LED counter (2 characters, 00-99)
# The memory map of the hardware is as follows:
#
# 0000 - 0fff	Flash/ROM used for program memory (READ ONLY)
# 3000 - 30ff	256 bytes of conventional RAM
# 5000		8 bit input port
# 5001 - 5002	7 segment LEDs

# assembler directives describing the hardware
startram		0x3000
endram			0x30ff
startstack		0x3000
stacksize		8

# hardware devices
define INPUT	0x5000
define LED1		0x5001
define LED2		0x5002

# global variables (located within same page)
page
define count1
define count2

== INIT
	# initialise CPU
	lit startstack:1 > sp1
	lit startstack:0 > sp0
	lit startram:1 > mp1
	lit startram:0 > mp0
	
	# initialise global variables
	lit 0
	> count1
	> count2
	
	goto MAIN

== FONT
	lit 0x55; return    # 0
	lit 0x55; return    # 1
	lit 0x55; return    # 2
	lit 0x55; return    # 3
	lit 0x55; return    # 4
	lit 0x55; return    # 5
	lit 0x55; return    # 6
	lit 0x55; return    # 7
	lit 0x55; return    # 8
	lit 0x55; return    # 9
	lit 0x55; return    # a
	lit 0x55; return    # b
	lit 0x55; return    # c
	lit 0x55; return    # d
	lit 0x55; return    # e
	lit 0x55; return    # f

== MAIN
	call DISPLAY_COUNT
	call READ_INPUT
	jmz NEXT1
	goto MAIN
	== NEXT1
	call INCREMENT_COUNT
	goto MAIN

== INCREMENT_COUNT
	lit count1:1 > mp1
	count1 > acu
	inc > count1
	
	# see if number is >= 10
	lit 9 > sub
	jmc NEXT2
	
	# number is >= 10, set to zero and increment count2
	lit 0 > count 1
	count2 > acu
	inc > count2
	
	# see if number is >= 10
	lit 9 > sub
	jmc NEXT2
	
	# number is >= 10, set to zero
	lit 0 > count 2
	
	== NEXT2
	# return with accumulator value. Necessary to prevent
	# the return from being merged with the instruction above
	< acu; return

== DISPLAY_COUNT
	lit count1:1 > mp1
	count1 > acu
	call GETFONT
	lit LED1:1 > mp1
	acu > LED1
	
	lit count2:1 > mp1
	count2 > acu
	call GETFONT
	lit LED2:1 > mp1
	acu > LED2
	return

== GETFONT
	lit FONT:0 > add
	acu > pc0
	lit FONT:1 > pc1
	
	> acu
	return

== READ_INPUT
	lit INPUT:1 > mp1
	INPUT > acu
	return
