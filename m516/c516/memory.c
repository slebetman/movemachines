#include "memory.h"
#include <stddef.h>

word RAM[0x10000];

void (*observeRAM)(word, word);

word getRAM (word addr) {
	return RAM[addr];
}

void setRAM (word addr, word val) {
	RAM[addr] = val;
	
	if (observeRAM != NULL) {
		(*observeRAM)(addr, val);
	}
}

void initRAM () {
	observeRAM = NULL;
}
