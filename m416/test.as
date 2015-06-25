# Set up our environment
	psp = lit
	0x100
	mp = lit
	0x200
	pc = MAIN

# This is the test array
:TEST_ARRAY
	321
	3435
	231
	343
	5426
	213
	435
	5462
	432
	4362
	332
	12
	3
	45
	31
	6
	7
	98
	5
	3
	6543
	67
	986
	4325
	876
	5644
	76
	43
	76
	856
	65
	8
	624
	43
	5634
	7325
	54
	6
	764
	4

:MAIN
	m0 = lit
	TEST_ARRAY
	m1 = lit
	40
	pc = lit
	HEAP_SORT
	pc = lit
	FOREVER

####################################################
# Example Code 4:
# Heapsort
# Subroutine accepts the address of the array in m0
# and the length of the array in m1
####################################################

: HEAP_SORT
define ARRAY m0
define n m1
define i m2
define parent m3
define child m4
define t m5
define temp m6

	pst = ret

#				i = n/2
	acu = n; i = rsh

:MAIN_LOOP
#				while (1) {
#					if (i > 0) {
	acu = i
	pc z= lit
	ELSE1
#						i--;
	add = all; i = acu
#						t = arr[i];
	add = ARRAY; stp = acu
	t = std
	pc = lit
	NEXT1
#					} else {
:ELSE1
#						n--;
	acu = n; add = all
#						if (n == 0) return;
	pc z= pst
	n = acu
#						t = arr[n];
	add = ARRAY; stp = n
	t = std
#						arr[n] = arr[0];
	stp = ARRAY; temp = std
	acu = n; add = ARRAY
	stp = acu; std = temp
#					}
:NEXT1

#					parent = i;
	parent = i
#					child = i*2 + 1;
	acu = i; add = acu
	add = one; child = acu
	
:CHILD_LOOP
#					while (child < n) {
	acu = child; xor = all
	add = one; add = n
	pc nc= lit
	NEXT3
#						if (child + 1 < n) {
	acu = child; xor = all
	add = n
	pc nc= lit
	NEXT2
#							if (arr[child + 1] > arr[child]) {
	acu = child; add = one
	add = ARRAY; stp = acu
	temp = std
	add = all; stp = acu
	acu = std; xor = all
	add = one; add = temp
	pc nc= lit
	NEXT2
#								child++;
	acu = child; add = one
	child = acu
#							}
#						}
:NEXT2
#						if (arr[child] > t) {
	acu = child; add = ARRAY
	stp = acu; temp = std
	acu = t; xor = all
	add = one; add = temp
	pc nc= lit
	NEXT3
#							arr[parent] = arr[child];
	acu = child; add = ARRAY
	stp = acu; temp = std
	acu = parent; add = ARRAY
	stp = acu; std = temp
#							parent = child;
	parent = child
#							child = parent*2 + 1;
	acu = parent; add = acu
	add = one; child = acu
#						} else {
#							break;
#						}
	pc = lit
	CHILD_LOOP
#					}
:NEXT3
#					arr[parent] = t;
	acu = parent; add = ARRAY
	stp = acu; std = t
	pc = lit
	MAIN_LOOP
#				}

:FOREVER
	pc = lit
	FOREVER
:END
