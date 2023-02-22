include 516inc.as
autopack

*m lit 0x20
m0 nil
m1 nil
m2 nil
m3 nil

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
	m3 acu
goto LOOP
