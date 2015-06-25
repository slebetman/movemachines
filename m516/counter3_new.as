#=============================
# Test Program
#=============================

include 516inc.as
autopack

define LED01   0x200
define LED23   0x201
define LED45   0x202

define SCRATCH 0x100
define STACK   0x140

define n01 0x100
define n23 0x101
define n45 0x102

:INIT
{
#point *b to top of stack
	*b lit STACK
	*m lit SCRATCH

#----------------------------------------------------
#use 7 segment lcds memory mapped to 0x200 and 0x201

#note: for subroutines, the comment convention is:
#(passed via b)[passed via acu]

#clear display
	*a lit SCRATCH
	a nil
	+a nil
	+a nil
	+a nil
	*a lit LED01
	a nil
	+a nil
}
	
goto START

:FONT_TABLE
{
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

routine INCR_BCD // in[val] out(val)[carry]
{
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
	
	return

	macro BCD++ $register
	{
		acu $register
		call INCR_BCD
		$register b-
	}
	macro BCDlow++ $addr
	{
		*a $addr
		acu low
		call INCR_BCD
		low b-
	}
	macro BCDhigh++ $addr
	{
		*a $addr
		acu high
		call INCR_BCD
		high b-
	}
}


routine GET_FONT // in[val] out[val]
{
	and 0x0f
	add FONT_TABLE
	*a acu
	acu a
	
	return

	macro $dest $mode getFont $register
	{
		acu $register
		call GET_FONT
		*a $dest
		$mode acu
	}
	macro $dest getFontLow $addr
	{
		*a $addr
		acu low
		call GET_FONT
		*a $dest
		low acu
	}
	macro $dest getFontHigh $addr
	{
		*a $addr
		acu high
		call GET_FONT
		*a $dest
		high acu
	}
}

:START
{
	:$$LOOP

	#increment number
	BCDlow++ n01
	ifFALSE $$NEXT
	BCDhigh++ n01
	ifFALSE $$NEXT
	BCDlow++ n23
	ifFALSE $$NEXT
	BCDhigh++ n23
	ifFALSE $$NEXT
	BCDlow++ n45
	ifFALSE $$NEXT
	BCDhigh++ n45
	
	:$$NEXT

	#display value
	LED01 getFontLow n01
	LED01 getFontHigh n01
	LED23 getFontLow n23
	LED23 getFontHigh n23
	LED45 getFontLow n45
	LED45 getFontHigh n45
	
	goto $$LOOP
}

