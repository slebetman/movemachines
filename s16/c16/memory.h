#include "datatypes.h"

extern word RAM[0x10000];
extern void (*observeRAM)(word, word);

extern word getRAM (word addr);
extern void setRAM (word addr, word val);
extern void initRAM ();
