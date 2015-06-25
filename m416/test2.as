# Set up our environment
	acu = END + 10
	psp = acu
	add = acu; add = acu
	mp = acu
	acu = nil
:LOOP
	or = one; add = acu
	pc nc= LOOP
:LOOP2
	acu = rsh
	pc nz= LOOP2
	
	pc = LOOP
:END