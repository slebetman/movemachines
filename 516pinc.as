# Common utility macros:

include 516mem.as

# Position independent gotos:
macro pjump $addr {
	+b acu
	acu $addr-$$:RETURN+3
	add pc
	ret acu
	acu b-
	pc ret
	:$$:RETURN
}

macro pzjump $addr {
	+b acu
	acu $addr-$$:RETURN+3
	add pc
	ret acu
	acu b-
	pcz ret
	:$$:RETURN
}

macro pcjump $addr {
	+b acu
	acu $addr-$$:RETURN+3
	add pc
	ret acu
	acu b-
	pcc ret
	:$$:RETURN
}

macro goto $addr {pjump $addr}

macro call $addr {pjump $addr}

macro ifFALSE $false else $true {
	pzjump $false
	pjump $true
}

macro ifFALSE $false {pzjump $false}

macro ifTRUE $true else $false {
	ifFALSE $false else $true
}

macro ifTRUE $true {
	ifFALSE $$:END else $true
	:$$:END
}

macro ifCARRY $true else $false {
	pcjump $true
	pjump $false
}

macro ifCARRY $true {pcjump $true}

macro ifBORROW $true else $false {
	ifCARRY $false else $true
}

macro ifBORROW $true {
	ifCARRY $$:END else $true
	:$$:END
}

macro saveret {+b ret}

macro return {pc b-}

macro routine $NAME {
	:$NAME
	saveret
}
