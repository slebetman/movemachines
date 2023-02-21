include 516inc.as
autopack

define SCRATCH 0x1c0
define STACK   0x1e0

define CHAR_BUFFER 0x1a0
define BUFFER_MAX  16
define buffer_ptr  m0
define NEWLINE     10

define UART_STATUS 0x02f0
define UART_TX     0x02f1
define UART_RX     0x02f2
define TXF_MASK    0x0001
define RXF_MASK    0x0100

{:INIT
	*b lit STACK
	*m lit SCRATCH

	clear CHAR_BUFFER BUFFER_MAX
	buffer_ptr nil
}

goto MAIN

// Strings

string STR_AT                 "at"
string STR_AT_UPPERCASE       "AT"
string STR_AT_WRITE           "at w "
string STR_AT_WRITE_UPPERCASE "AT W "
string STR_OK                 "OK\n"
string STR_INVALID_CMD        "ERROR: Invalid command\n"

macro incr_reg $REG {
	acu $REG
	add one
	$REG acu
}

{:CHAR_COMPARE
	define $$string_idx m8
	define $$buffer_idx m9
	define $$result     m10
	define $$tmp        m24

	*a $$string_idx
	incr_reg $$string_idx
	$$tmp a

	*a $$buffer_idx
	incr_reg $$buffer_idx

	// Compare string with buffer -- 0 if same
	acu $$tmp
	sub a
	$$result acu

	pc ret
}

routine BUF_EQUAL {
	define $$string_idx m8
	define $$buffer_idx m9
	define $$result     m10
	define $$end_buf    m11
	define $$end_str    m12
	define $$tmp        m13

	$$string_idx acu
	$$buffer_idx CHAR_BUFFER
	$$result nil
	$$end_buf nil
	$$end_str nil

:$$LOOP
	call CHAR_COMPARE
	ifTRUE $$END

	// Check if max buffer
	acu $$buffer_idx
	sub CHAR_BUFFER
	$$tmp acu
	acu BUFFER_MAX
	sub $$tmp
	ifFALSE $$BUFFER_END

	// Check if end of string
	*a $$string_idx
	acu a
	ifFALSE $$STRING_END

	goto $$LOOP

// If both buffer and string end then they are the same
:$$BUFFER_END
	// Check if end of string
	*a $$string_idx
	acu a
	ifFALSE $$END_TRUE else $$END_FALSE
:$$STRING_END
	// Check if end of buffer
	*a $$buffer_idx
	acu a
	ifFALSE $$END_TRUE else $$END_FALSE

// invert result to get conventional true/false value	
:$$END
	acu $$result
	ifFALSE $$END_TRUE
	goto $$END_FALSE
:$$END_TRUE
	acu one
	return
:$$END_FALSE
	acu nil
	return
}

routine BUF_STARTSWITH {
	define $$string_idx m8
	define $$buffer_idx m9
	define $$result     m10
	define $$end_buf    m11
	define $$end_str    m12
	define $$tmp        m13

	$$string_idx acu
	$$buffer_idx CHAR_BUFFER
	$$result nil
	$$end_buf nil
	$$end_str nil

:$$LOOP
	call CHAR_COMPARE
	ifTRUE $$END

	// Check if end of string
	*a $$string_idx
	acu a
	ifFALSE $$END

	// Check if end of buffer
	acu $$buffer_idx
	sub CHAR_BUFFER
	$$tmp acu
	acu BUFFER_MAX
	sub $$tmp
	ifFALSE $$BUFFER_END

	goto $$LOOP

:$$BUFFER_END
	// Not end of string so obviously buffer does not start with string
	$$result one

// invert result to get conventional true/false value
:$$END
	acu $$result
	ifFALSE $$END_TRUE
	goto $$END_FALSE
:$$END_TRUE
	acu one
	return
:$$END_FALSE
	acu nil
	return
}

routine READ_CHAR {
	define $$temp m8
	$$temp 0xffff // this value means no data is read

	// Check if there is data
	*a UART_STATUS
	acu a
	and RXF_MASK
	ifFALSE $$END

	// Read data to temp
	*a UART_RX
	$$temp a

:$$END
	acu $$temp

	return
}

routine SAVE_BUFFER {
	define $$temp m8

	$$temp acu

	// Check if buffer is full
	acu BUFFER_MAX
	sub buffer_ptr
	ifCARRY $$END
	ifFALSE $$END

	// Save data to buffer
	acu CHAR_BUFFER
	add buffer_ptr
	*a acu
	a $$temp
	incr_reg buffer_ptr

:$$END
	return
}

routine WRITE_CHAR {
	define $$temp m17

	$$temp acu

	// Wait if TX is busy
	*a UART_STATUS
	{:$$BUSY_LOOP
		acu a
		and TXF_MASK
		ifTRUE $$BUSY_LOOP
	}

	*a UART_TX
	a $$temp

	return
}

routine PRINT_STRING {
	define $$string_idx m8

:$$LOOP
	$$string_idx acu
	*a $$string_idx
	acu a
	ifFALSE $$END // found null terminator

	call WRITE_CHAR

	incr_reg $$string_idx
	goto $$LOOP

:$$END
	return
}

{:MAIN
	define $$char m16
	call READ_CHAR
	$$char acu

	// Echo if typed
	sub 0xffff
	ifFALSE $$END
	acu $$char
	call WRITE_CHAR

:$$NEXT
	// Check if char is newline:
	acu $$char
	sub NEWLINE
	ifTRUE $$BEFORE_END

	// Check if buffer contains 'at'
	acu STR_AT
	call BUF_EQUAL
	pcz $$NEXT2
	{
		acu STR_OK
		call PRINT_STRING
	}
	goto INIT
:$$NEXT2
	// Check if buffer contains 'AT'
	acu STR_AT_UPPERCASE
	call BUF_EQUAL
	pcz $$NEXT3
	{
		acu STR_OK
		call PRINT_STRING
	}
	goto INIT
:$$NEXT3
	{
		acu STR_INVALID_CMD
		call PRINT_STRING
	}
	goto INIT

:$$BEFORE_END
acu $$char
call SAVE_BUFFER

:$$END
	goto MAIN
}