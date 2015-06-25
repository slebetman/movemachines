###################################################
# This is to test the bit_count function
###################################################
psp = lit
0x100
mp = lit
0x200

acu = lit
0x1234
pc = BIT_COUNT
# save result into m0:
m0 = acu
: FOREVER
pc = FOREVER

####################################################
# Fast bit count function.
# Subroutine accepts parameter and returns via acu
#
#int bit_count(long x) {
#	int n = 0;
#	if (x) {
#		do {
#			n++;
#   	} while ((x &= x-1));
#	}
#	return(n);
#}
####################################################
: BIT_COUNT
	define X m0
	define N m1
	
	pst = ret
	
	pc z= BIT_COUNT_END
	X = acu
	N = nil
	: LOOP
		acu = N; add = one
		N = acu
		
		acu = X; add = all
		and = X; X = acu
		pc nz= LOOP
	acu = N
	: BIT_COUNT_END
	pc = pst
