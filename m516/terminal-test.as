include 516inc.as
autopack

define UART_STATUS 0x02f0
define UART_TX     0x02f1
define UART_RX     0x02f2
define TXF_MASK    0x0001

goto MAIN

:HELLO_STRING
	'H'
	'e'
	'l'
	'l'
	'o'
	' '
	'W'
	'o'
	'r'
	'l'
	'd'
	'\n'
	0x00

:MAIN

:PRINT_STRING
	*a HELLO_STRING
	:PRINT_CHAR_LOOP
		acu a
		ifFALSE PRINT_STRING

		*b UART_STATUS
		:TX_BUSY_LOOP
			acu b
			and TXF_MASK
			ifTRUE TX_BUSY_LOOP

		*b UART_TX
		b a+

		goto PRINT_CHAR_LOOP

