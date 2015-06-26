#include "datatypes.h"

word Asm (address dst, address src, address dst2, address src2) {
	return (dst << 12) | (src << 8) | (dst2 << 4) | src2;
}