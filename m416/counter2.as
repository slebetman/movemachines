#=============================
# Test Program
#=============================

define LED01 0x1000
define LED23 0x1001
define LED45 0x1002

#----------------------------------------------------
#use 7 segment lcds memory mapped to 0x200 - 0x203

:FONT_TABLE @ 110
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
:START @ 0
#point mpa and mpb to more sensible locations
	mp = 0x100
#now point the stacks to more sensible locations
	psp = 0x120
#clear display
	m0 = nil
	m1 = nil
	m2 = nil
	stp = LED01
	stk = nil; stk = nil
	stk = nil; stk = nil
	
:LOOP
	#increment number
	acu - m0
	pc = INCR_BCD
	m0 - pst
	pc z= NEXT
	acu / m0
	pc = INCR_BCD
	m0 \ pst
	pc z= NEXT
	
	acu - m1
	pc = INCR_BCD
	m1 - pst
	pc z= NEXT
	acu / m1
	pc = INCR_BCD
	m1 \ pst
	pc z= NEXT
	
	acu - m2
	pc = INCR_BCD
	m2 - pst
	pc z= NEXT
	acu / m2
	pc = INCR_BCD
	m2 \ pst
	
	:NEXT
	#display value
	acu - m0
	pc = GET_FONT
	stp = LED01
	std - acu
	acu / m0
	pc = GET_FONT
	stp = LED01
	std \ acu
	
	acu - m1
	pc = GET_FONT
	stp = LED23
	std - acu
	acu / m1
	pc = GET_FONT
	stp = LED23
	std \ acu
	
	acu - m2
	pc = GET_FONT
	stp = LED45
	std - acu
	acu / m2
	pc = GET_FONT
	stp = LED45
	std \ acu
	
	pc = LOOP

:INCR_BCD #in[val] out(val)[carry]
	pst = ret
	add = one; m7 = acu
	add = -10
	pc c= NEXT
	ret = pst
	pst = m7
	acu = nil
	pc = ret
	:NEXT
	ret = pst
	pst = nil
	acu = one
	pc = ret

:GET_FONT #in[val] out[val]
	and = 0x0f
	add = FONT_TABLE
	stp = acu; acu = std
	pc = ret
