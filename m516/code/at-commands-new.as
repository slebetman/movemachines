include 516inc.as
include strings.as
autopack

define SCRATCH 0x1c0
define STACK   0x1e0

define CHAR_BUFFER 0x1a0
define BUFFER_MAX  16
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

	clear CHAR_BUFFER 17
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
	ifCARRY $$FAIL
	ifFALSE $$FAIL

	// Save data to buffer
	acu CHAR_BUFFER
	add buffer_ptr
	*a acu
	a $$temp
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
	add CHAR_BUFFER
	*a acu
	a nil
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

	// Check if buffer contains 'at'
	streq STR_AT CHAR_BUFFER
	pcz $$NEXT2
	{
		acu STR_OK
		call PRINT_STRING
	}
	goto INIT
:$$NEXT2
	// Check if buffer contains 'AT'
	streq STR_AT_UPPERCASE CHAR_BUFFER
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