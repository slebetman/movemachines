// This is slower (due to function call) but is less code

include 516inc.as
autopack

*m lit 0x20
*a lit 0x20
a nil
+a nil
+a nil
+a nil

:LOOP
	*a lit 0x20
	pc lit INCREMENT
	pcz lit INCREMENT
	pcz lit INCREMENT
	pcz lit INCREMENT
goto LOOP

:INCREMENT
	acu a
	add one
	a acu
	acu a+          // stupid trick to increment *a
	and lit 0xff
	pc ret
