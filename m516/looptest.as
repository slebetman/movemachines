*m lit 0x20
m31 lit 0xff

:LOOP
	acu m0
	add one
	m0 acu
	and m31
	pcz lit INCR_M1
	pc lit LOOP
	:INCR_M1
		acu m1
		add one
		m1 acu
		and m31
		pcz lit INCR_M2
		pc lit LOOP
		:INCR_M2
			acu m2
			add one
			m2 acu
			pcz lit INCR_M3
			pc lit LOOP
			:INCR_M3
				acu m3
				add one
				pc lit LOOP
