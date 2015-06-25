#=============================
# Simple Calculator
#=============================

include 516inc.as
autopack

define LED01   0x200
define LED23   0x201
define LED45   0x202
define KEYPAD  0x203

define SCRATCH 0x100
define STACK   0x140

define in      0x100
define in01    0x100
define in23    0x101
define in45    0x102

define mem     0x103
define mem01   0x103
define mem23   0x104
define mem45   0x105

define _keyBuff 0x106
define keyBuff m6

# m7 is at 0x107:
define _temp   0x107
define temp    m7

{:INIT
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

macro BCD++ $register {
	acu $register
	call INCR_BCD
	$register b-
}
macro BCDlow++ $addr {
	getLow acu $addr
	call INCR_BCD
	low b-
}
macro BCDhigh++ $addr {
	getHigh acu $addr
	call INCR_BCD
	high b-
}
routine INCR_BCD { // in[val] out(val)[carry]
	add one
	temp acu
	sub lit 10
	pcc lit $$NEXT
	ret b-
	+b nil
	acu one
	pc ret

	:$$NEXT
	ret b-
	+b temp
	acu nil
	pc ret
}

macro $dest $mode getFont $register {
	acu $register
	call GET_FONT
	*a $dest
	$mode acu
}
macro $dest getFontLow $addr {
	getLow acu $addr
	call GET_FONT
	setLow $dest acu
}
macro $dest getFontHigh $addr {
	getHigh acu $addr
	call GET_FONT
	setHigh $dest acu
}
routine GET_FONT { // in[val] out[val]
	and 0x0f
	add FONT_TABLE
	*a acu
	acu a
	return
}

macro displayValue $bcd {
	acu $bcd
	call DISPLAY_VALUE
}
routine DISPLAY_VALUE { // in[base]
	+b acu
	LED01 getFontLow  b
	LED01 getFontHigh b
	acu b
	add one
	b acu
	LED23 getFontLow  b
	LED23 getFontHigh b
	acu b
	add one
	b acu
	LED45 getFontLow  b
	LED45 getFontHigh b-
	return
}

routine DEBOUNCE {
	temp a
	{:$$LOOP
		acu a
		ifTRUE $$LOOP
	}
	return
}

macro scanRow $scancode {
	acu $scancode
	call SCAN_ROW
}
routine SCAN_ROW { // in[scancode] out[keycode]
	+b acu
	*a KEYPAD
	a acu
	call DEBOUNCE
	acu temp
	ifFALSE $$END
		setHigh _temp b
	:$$END
	temp b- // discard top of stack
	return
}

macro $dest = scanKeypad {
	call SCAN_KEYPAD
	$dest acu
}
routine SCAN_KEYPAD { // out[keycode]
	scanRow 0
	ifTRUE $$NEXT
	scanRow 1
	ifTRUE $$NEXT
	scanRow 2
	ifTRUE $$NEXT
	scanRow 3

	:$$NEXT
	return
}

routine INSERT_NUMBER {
	return
}

routine KEY_COMMAND {
	return
}

macro $register = decodeKey $buff {
	acu $buff
	call DECODE_KEY
	$register acu
}
routine DECODE_KEY { // in[keycode] out(number)[command?]
	m0 acu
	return
}

:START

{:$$LOOP

	keyBuff = scanKeypad
	
	goto $$LOOP
}

