#=============================
# Test Program
#=============================

include 516inc.as
autopack

define LED0    0xf000
define LED1    0xf001
define LED2    0xf002
define LED3    0xf003

define SCRATCH 0x100
define STACK   0x140

{:INIT
#point *b to top of stack
	*b lit STACK
	*m lit SCRATCH

#----------------------------------------------------
#use 7 segment lcds memory mapped to 0xf000 - 0xf003

#note: for subroutines, the comment convention is:
#(passed via b)[passed via acu]

#clear display
	*a lit SCRATCH
	a nil
	+a nil
	+a nil
	+a nil
	*a lit LED0
	a nil
	+a nil
	+a nil
	+a nil
}
	
	goto START
{:INCR_BCD // in[val] out(val)[carry]
	+b ret
	add one
	m7 acu
	sub lit 10
	pcc lit $$NEXT
	ret b-
	+b nil
	acu one
	pc ret

	:$$NEXT
	ret b-
	+b m7
	acu nil
	pc ret
}
macro BCD++ $register {
	acu $register
	call INCR_BCD
	$register b-
}


{:GET_FONT // in[val] out[val]
	and 0x0f
	add FONT_TABLE
	*a acu
	acu a
	pc ret
}
macro $dest = getFont $register {
	acu $register
	call GET_FONT
	*a $dest
	a acu
}

:START

{:$$LOOP

	#increment number
	BCD++ m0
	ifFALSE $$NEXT
	BCD++ m1
	ifFALSE $$NEXT
	BCD++ m2
	ifFALSE $$NEXT
	BCD++ m3
	
	:$$NEXT

	#display value
	LED0 = getFont m0
	LED1 = getFont m1
	LED2 = getFont m2
	LED3 = getFont m3
	
	goto $$LOOP
}



{:FONT_TABLE
	0x77  // 0
	0x24  // 1
	0x5d  // 2
	0x6d  // 3
	0x2e  // 4
	0x6b  // 5
	0x7b  // 6
	0x25  // 7
	0x7f  // 8
	0x2f  // 9
	0x3f  // a
	0x7a  // b
	0x53  // c
	0x7c  // d
	0x5b  // e
	0x1b  // f
}

:END
