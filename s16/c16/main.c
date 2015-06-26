#include "s16.h"
#include <stdio.h>
#include <sys/time.h>

void watcher (word addr, word val) {
	if (addr == Val[DP]) {
		printf("\rD = %04x    ", val);
	}
}

void freq(double f) {
	if (f < 1000) {
		printf("%0.2f Hz\n", f);
		return;
	}
	f /= 1000;
	if (f < 1000) {
		printf("%0.2f kHz\n", f);
		return;
	}
	f /= 1000;
	if (f < 1000) {
		printf("%0.2f MHz\n", f);
		return;
	}
	f /= 1000;
	printf("%0.2f GHz\n", f);
}

int main () {
	struct timeval tval_before, tval_after, tval_result;
	long int usec;
	double hz;

	initCPU();

	RAM[0]= Asm(DP,LIT,
				D,LIT);
	RAM[1]= 0x40;
	RAM[2]= 0x0fff;
	RAM[3]= Asm(A,LIT,       // -- $0
				B,LIT);
	RAM[4]= 0xfff;
	RAM[5]= 0xffff;          // (-1)
	RAM[6]= Asm(CP,LIT,A,A);
	RAM[7]= 0xff;
	RAM[8]= Asm(A,ADD,       // -- $1
				INC_C,A);
	RAM[9]= Asm(PCN,LIT,A,A);// -- LOOP $1
	RAM[10]=8;
	RAM[11]=Asm(A,D,
				D,ADD);
	RAM[12]=Asm(PCN,LIT,A,A);// -- LOOP $0
	RAM[13]=3;
	RAM[14]=Asm(PC,LIT,A,A);
	RAM[15]=14;

	observeRAM = watcher;
	
	Val[PC] = 0;
	
	gettimeofday(&tval_before, NULL);
	while (Val[PC] < 14) {
		exec();
	}
	gettimeofday(&tval_after, NULL);

	timersub(&tval_after, &tval_before, &tval_result);

	usec = (long int)tval_result.tv_sec * 1000000 + (long int)tval_result.tv_usec;
	hz = (instCount / usec) * 1000000;

	freq(hz);
	printf("Time elapsed: %ld.%06ld\n",
		(long int)tval_result.tv_sec,
		(long int)tval_result.tv_usec
	);
}
