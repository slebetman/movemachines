# Common utility macros:

include 516mem.as

macro goto $addr {pc $addr}

macro call $addr {goto $addr}

macro ifFALSE $false else $true {
	pcz $false
	pc $true
}

macro ifFALSE $false {pcz $false}

macro ifTRUE $true else $false {
	ifFALSE $false else $true
}

macro ifTRUE $true {
	ifFALSE $$:END else $true
	:$$:END
}

macro ifCARRY $true else $false {
	pcc $true
	pc $false
}

macro ifCARRY $true {pcc $true}

macro ifBORROW $true else $false {
	ifCARRY $false else $true
}

macro ifBORROW $true {
	ifCARRY $$:END else $true
	:$$:END
}

macro if ( $a == $b ) $addr {
	*a $a
	acu a
	*a $b
	sub a
	ifFALSE $addr
}

macro if ( $a != $b ) $addr {
	*a $a
	acu a
	*a $b
	sub a
	ifTRUE $addr
}

macro if [ $a == $b ] $addr {
	acu $a
	sub $b
	ifFALSE $addr
}

macro if [ $a != $b ] $addr {
	acu $a
	sub $b
	ifTRUE $addr
}

macro saveret {+b ret}

macro return {pc b-}

macro routine $NAME {
	:$NAME
	saveret
}
