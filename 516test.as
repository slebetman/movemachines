include 516pinc.as

# The following comments should not be substituted:
# macros
# macro:
# macro testing 1 2 3 { bla $$ bla }

define temp 0x100

define x 0x101
define y 0x102

memset temp END
memset x 10
{
	:$$:LOOP
	memset y 10
	{
		:$$:LOOP
		*a y
		acu a
		*a temp
		memset a acu
		incr temp
		decr y
		ifTRUE $$:LOOP
	}
	decr x
	ifTRUE $$:LOOP
}

:FOREVER
goto FOREVER

:END
