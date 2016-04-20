#ifndef s16
#define s16

#include "registers.h"
#include "memory.h"
#include "datatypes.h"

#define ACU    0x00
#define ADD    0x01
#define ONE    0x01
#define SUB    0x02
#define NIL    0x02
#define AND    0x03
#define ALL    0x03
#define RSH    0x04
#define OR     0x04
#define Aptr   0x05
#define A      0x06
#define PlusA  0x07
#define Aminus 0x07
#define M(x)   0x08 + x
#define XOR    0x28
#define INV    0x28
#define MinusA 0x29
#define Aplus  0x29
#define HIGH   0x2a
#define LOW    0x2b
#define Bptr   0x2c
#define B      0x2d
#define PlusB  0x2e
#define Bminus 0x2e
#define PC     0x2f
#define PCZ    0x30
#define LIT    0x30
#define PCC    0x31
#define CONF   0x31
#define RET    0x32
#define Mptr   0x33
#define BANK   0x34
#define BNKA   0x35

extern int instCount;

extern void initCPU ();
extern void exec();

#endif