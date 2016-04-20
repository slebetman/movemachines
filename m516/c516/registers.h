#include "datatypes.h"

typedef void (*write_callback)(word);
typedef word (*read_callback)();

extern write_callback W[0x10];
extern read_callback R[0x10];
extern word Val[0x10];

extern void initRegisters ();
