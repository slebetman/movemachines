include 516inc.as
autopack

*m lit 0x20

:LOOP
	acu m0
	add one
	m0 acu
	and lit 0xff
	ifTRUE LOOP

	acu m1
	add one
	m1 acu
	and lit 0xff
	ifTRUE LOOP

	acu m2
	add one
	m2 acu
	and lit 0xff
	ifTRUE LOOP

	acu m3
	add one
goto LOOP
