#include "registers.h"
#include "memory.h"
#include "datatypes.h"
#include <stdio.h>

#define A    0x00
#define B    0x01
#define PC   0x02
#define ADD  0x02
#define PCZ  0x03
#define AND  0x03
#define PCN  0x04
#define OR   0x04
#define PCC  0x05
#define XOR  0x05
#define PCZC 0x06
#define RSH  0x06
#define PCZD 0x07
#define LIT  0x07
#define CP    0x08
#define C     0x09
#define INC_C 0x0a
#define C_DEC 0x0a
#define DEC_C 0x0b
#define C_INC 0x0b
#define DP    0x0c
#define D     0x0d
#define D_INC 0x0e
#define DEC_D 0x0e
#define D_DEC 0x0f
#define INC_D 0x0f

int instCount;

int carry () {
	int32_t sum;
	
	sum = Val[A] + Val[B];
	
	if (sum > 0xffff) {
		return 1;
	}
	return 0;
}

void writeA (word val) {
	Val[A] = val;
}
word readA () {
	return Val[A];
}

void writeB (word val) {
	Val[B] = val;
}
word readB () {
	return Val[B];
}

word add () {
	return Val[A] + Val[B];
}
word and () {
	return Val[A] & Val[B];
}
word or () {
	return Val[A] | Val[B];
}
word xor () {
	return Val[A] ^ Val[B];
}
word rsh () {
	return Val[A] >> 1;
}
word lit () {
	word ret;
	ret = RAM[Val[PC]];
	Val[PC]++;
	return ret;
}

void pc (word val) {
	Val[PC] = val;
}
void pcz (word val) {
	if (!(Val[A]+Val[B])) {
		Val[PC] = val;
	}
}
void pcn (word val) {
	if (Val[A]+Val[B]) {
		Val[PC] = val;
	}
}
void pcc (word val) {
	if (carry()) {
		Val[PC] = val;
	}
}
void pczc (word val) {
	if (!(Val[C])) {
		Val[PC] = val;
	}
}
void pczd (word val) {
	if (!(Val[D])) {
		Val[PC] = val;
	}
}

word readCP () {
	return Val[CP];
}
void writeCP (word val) {
	Val[CP] = val;
}
word readC () {
	return RAM[Val[CP]];
}
void writeC (word val) {
	setRAM(Val[CP], val);
}
word c_dec () {
	word ret;
	ret = RAM[Val[CP]];
	Val[CP]--;
	return ret;
}
void inc_c (word val) {
	Val[CP]++;
	setRAM(Val[CP], val);
}
word c_inc () {
	word ret;
	ret = RAM[Val[CP]];
	Val[CP]++;
	return ret;
}
void dec_c (word val) {
	Val[CP]--;
	setRAM(Val[CP], val);
}

word readDP () {
	return Val[DP];
}
void writeDP (word val) {
	Val[DP] = val;
}
word readD () {
	return RAM[Val[DP]];
}
void writeD (word val) {
	setRAM(Val[DP], val);
}
word dec_d () {
	Val[DP]--;
	return RAM[Val[DP]];
}
void d_inc (word val) {
	setRAM(Val[DP], val);
	Val[DP]++;
}
word inc_d () {
	Val[DP]++;
	return RAM[Val[DP]];
}
void d_dec (word val) {
	setRAM(Val[DP], val);
	Val[DP]--;
}

void initCPU () {
	initRAM();
	initRegisters();
	instCount = 0;
	
	R[A] = readA;
	W[A] = writeA;
	R[B] = readB;
	W[B] = writeB;
	R[ADD] = add;
	W[PC] = pc;
	R[AND] = and;
	W[PCZ] = pcz;
	R[OR] = or;
	W[PCN] = pcn;
	R[XOR] = xor;
	W[PCC] = pcc;
	R[RSH] = rsh;
	W[PCZC] = pczc;
	R[LIT] = lit;
	W[PCZD] = pczd;
	R[CP] = readCP;
	W[CP] = writeCP;
	R[C] = readC;
	W[C] = writeC;
	R[C_DEC] = c_dec;
	W[INC_C] = inc_c;
	R[C_INC] = c_inc;
	W[DEC_C] = dec_c;
	R[DP] = readDP;
	W[DP] = writeDP;
	R[D] = readD;
	W[D] = writeD;
	R[DEC_D] = dec_d;
	W[D_INC] = d_inc;
	R[INC_D] = inc_d;
	W[D_DEC] = d_dec;
}

void copy (address dst, address src) {
	instCount++;
	(*W[dst])((*R[src])());
}

void decode (word instruction) {
	copy((instruction>>12) & 0xf, (instruction>>8) & 0xf);
	copy((instruction>>4) & 0xf, instruction & 0xf);
}

void exec() {
	word instruction;
	
	instruction = RAM[Val[PC]];
	Val[PC]++;
	
	decode(instruction);
}
