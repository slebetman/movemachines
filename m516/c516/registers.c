#include "registers.h"

write_callback W[0x10];
read_callback R[0x10];
word Val[0x10];

void defaultWrite (word val) {}
word defaultRead () {return 0;}

void initRegisters () {
	address i;
	
	for (i=0;i<0x10;i++) {
		W[i] = &defaultWrite;
		R[i] = &defaultRead;
		Val[i] = 0;
	}
}
