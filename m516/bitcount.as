# Bit count test:
include 516inc.as

*b END
*m END+0x20&0xffe0

goto START

routine BIT_COUNT {
	m7 nil // bit count
	m6 acu // save input data

	ifFALSE $$END
	{:$$LOOP
		acu m7
		add one
		m7 acu
		acu m6
		sub one
		and m6
		m6 acu
		ifTRUE $$LOOP
	}
	:$$END

	acu m7
	return
}

:START
	goto START

:END
