#ifndef s16
#define s16

#include "registers.h"
#include "memory.h"
#include "datatypes.h"

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

extern int instCount;

extern void initCPU ();
extern void exec();

#endif