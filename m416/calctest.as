#=============================
# Test Program
#=============================

define LED 0x1000
define LED01 0x1000
define LED23 0x1001
define LED45 0x1002
define KEYPAD 0x1003

pc = START

#----------------------------------------------------
#use 7 segment lcds memory mapped to 0x200 - 0x203

:FONT_TABLE
	0x77  # 0
	0x24  # 1
	0x5d  # 2
	0x6d  # 3
	0x2e  # 4
	0x6b  # 5
	0x7b  # 6
	0x25  # 7
	0x7f  # 8
	0x2f  # 9
	0x3f  # a
	0x7a  # b
	0x53  # c
	0x7c  # d
	0x5b  # e
	0x1b  # f

#note: for subroutines, the comment convention is:
#(passed via pst)[passed via acu]
:START
#point mpa and mpb to more sensible locations
	mp = 0x100
#now point the stacks to more sensible locations
	psp = 0x120
#clear display
	stp = mp
	stk = nil; stk = nil
	stk = nil; stk = nil
	stk = nil; stk = nil
	stk = nil; stk = nil
	stp = LED01
	stk = nil; stk = nil
	stk = nil; stk = nil

define scan m7
define input m6
define disp m5
	
:LOOP
	#scan keypad:
	stp = KEYPAD
	std = scan
	acu = std; input = acu
	
	#display keypad value:
	and = 0xf
	pc = GET_FONT
	disp - acu
	acu = input; acu = rsh
	acu = rsh; acu = rsh
	acu = rsh
	pc = GET_FONT
	disp \ acu
	
	acu = LED
	add = scan; stp = acu
	std = disp
	
	#set scan to next:
	acu = scan; add = one
	and = 3
	scan = acu
	
	pc = LOOP
	
:GET_FONT #in[val] out[val]
	and = 0x0f
	add = FONT_TABLE
	stp = acu; acu = std
	pc = ret
