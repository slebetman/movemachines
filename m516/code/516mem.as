# Memory related macros:

macro memset $addr $val {
	*a $addr
	a $val
}

macro *memset $addr $val {
	*a $addr
	*a a
	a $val
}

macro getArray $register $base $index {
	acu $base
	add $index
	*a acu
	$register a
}

macro setArray $base $index $val {
	acu $base
	add $index
	*a acu
	a $val
}

macro getByteArray $register $base $index {
	acu $index
	acu rsh
	add $base
	*a acu
	acu $index
	and one
	pcz $$EVEN
:$$ODD
	$register high
	goto $$END
:$$EVEN
	$register low
:$$END
}

macro setByteArray $base $index $val {
	acu $index
	acu rsh
	add $base
	*a acu
	acu $index
	and one
	pcz $$EVEN
:$$ODD
	high $val
	goto $$END
:$$EVEN
	low $val
:$$END
}

macro clear $addr $size {
	acu $addr
	add all
	*a acu
	acu $size
	{
		:$$:LOOP
			+a nil
			add all
		ifTRUE $$:LOOP
	}
}

macro incr $x {
	*a $x
	acu a
	add one
	a acu
}

macro decr $x {
	*a $x
	acu a
	add all
	a acu
}

macro getLow $register $addr {
	*a $addr
	$register low
}

macro getHigh $register $addr {
	*a $addr
	$register high
}

macro setLow $addr $val {
	*a $addr
	low $val
}

macro setHigh $addr $val {
	*a $addr
	high $val
}
