include 516inc.as
include strings.as
autopack

define SCRATCH 0x1c0
define STACK   0x1e0

define CHAR_BUFFER 0x1a0
define BUFFER_MAX  31
define buffer_ptr  m0
define NEWLINE     10
define BACKSPACE   8

define UART_STATUS 0xf0f0
define UART_TX     0xf0f1
define UART_RX     0xf0f2
define TXF_MASK    0x0001
define RXF_MASK    0x0100

{:INIT
	*b lit STACK
	*m lit SCRATCH

	clear CHAR_BUFFER 16
	buffer_ptr nil
}

goto MAIN

// Strings

bytestring STR_AT                 "at"
bytestring STR_AT_UPPERCASE       "AT"
bytestring STR_AT_WRITE           "at w "
bytestring STR_AT_WRITE_UPPERCASE "AT W "
bytestring STR_OK                 "OK\n"
bytestring STR_INVALID_CMD        "ERROR: Invalid command\n"

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

// in: acu, out: acu
routine MULT_TEN {
	+b *a
	+b acu
	add acu // x2
	add acu // x4
	add acu // x8
	add b   // +1
	add b   // +1
			//----
			// 10
	
	*a b-
	*a b-
	return
}

// in: *a, out: acu
routine PARSE_INT {
	+b nil // keep the parsed value on top of stack

:$$LOOP
	// Check if character is between 0x30 and 0x39
	acu a
	sub lit 0x30
	ifCARRY $$END

	acu a
	sub lit 0x40
	ifCARRY $$NEXT else $$END

:$$NEXT

	acu b
	call MULT_TEN
	b acu

	acu a
	and lit 0x0f
	add b
	b acu

	incr_reg *a

	goto $$LOOP

:$$END
	acu b-
	return
}

routine SAVE_BUFFER {
	define $$temp m8

	$$temp acu

	// Check if buffer is full
	acu BUFFER_MAX
	sub buffer_ptr
	ifCARRY $$FAIL
	ifFALSE $$FAIL

	// Save data to buffer
	acu buffer_ptr
	acu rsh
	add CHAR_BUFFER
	*a acu

	acu buffer_ptr
	and one
	ifFALSE $$LOW_BYTE

:$$HIGH_BYTE
	high $$temp
	goto $$END
:$$LOW_BYTE
	low $$temp

:$$END
	incr_reg buffer_ptr
	acu one
	return

:$$FAIL
	acu nil
	return
}

routine DELETE_BUFFER {
	define $$temp m8
	
	$$temp acu
	
	// Check if buffer is empty
	acu buffer_ptr
	ifFALSE $$FAIL
	
	acu buffer_ptr
	sub one
	buffer_ptr acu

	acu rsh
	add CHAR_BUFFER
	*a acu

	acu buffer_ptr
	and one
	ifFALSE $$LOW_BYTE
:$$HIGH_BYTE
	high nil
	goto $$END
:$$LOW_BYTE
	low nil
:$$END
	acu one
	return

:$$FAIL
	acu nil
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
	acu low
	ifFALSE $$END // found null terminator

	call WRITE_CHAR

	*a $$string_idx
	acu high
	ifFALSE $$END // found null terminator

	call WRITE_CHAR

	incr_reg $$string_idx
	goto $$LOOP

:$$END
	return
}

macro print $STR {
	acu $STR
	call PRINT_STRING
}

{:MAIN
	define $$char m16
	call READ_CHAR
	$$char acu

	// Skip if no data
	sub 0xffff
	ifFALSE $$END

:$$NEXT
	// Check if char is newline:
	acu $$char
	sub NEWLINE
	ifTRUE $$BEFORE_END
	
	acu NEWLINE
	call WRITE_CHAR

	bytestrequal STR_AT CHAR_BUFFER
	pcz $$NEXT2
	{
		print STR_OK
	}
	goto INIT
:$$NEXT2
	// Check if buffer contains 'AT'
	bytestrequal STR_AT_UPPERCASE CHAR_BUFFER
	pcz $$NEXT3
	{
		print STR_OK
	}
	goto INIT
:$$NEXT3
	{
		print STR_INVALID_CMD
	}
	goto INIT

:$$BEFORE_END
	acu $$char
	// Check if char is backspace here to handle delete char from buffer
	sub BACKSPACE
	ifTRUE $$HANDLE_CHAR
:$$HANDLE_DELETE
	call DELETE_BUFFER
	goto $$ECHO
:$$HANDLE_CHAR
	acu $$char
	call SAVE_BUFFER
:$$ECHO
	ifFALSE $$END
	acu $$char
	call WRITE_CHAR

:$$END
	goto MAIN
}