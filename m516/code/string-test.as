include 516inc.as
include strings.as
autopack

define SCRATCH 0x1c0
define STACK   0x1e0

{:INIT
	*b lit STACK
	*m lit SCRATCH
}


goto MAIN

bytestring HELLO "hello"
bytestring HELLO_WORLD "henllo world"

:MAIN

bytestrstart HELLO HELLO_WORLD

:END
goto END
