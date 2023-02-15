function asm (dst,src) {
	return (reg.address[dst] << 7) | reg.address[src]
}

function asmpack (dst1,src1,dst2,src2) {
	dst1 = reg.address[dst1];
	dst2 = reg.address[dst2];
	src1 = reg.address[src1];
	src2 = reg.address[src2];
	
	if (dst1 > 0x7) throw "dst1 out of range";
	if (dst2 > 0xf) throw "dst2 out of range";
	if (src1 > 0xf) throw "src1 out of range";
	if (src2 > 0xf) throw "src2 out of range";
	
	return 0x8000 | (dst1<<12) | (src1<<8) | (dst2<<4) | src2;
}

function asmlit (dst,val) {
	dst = reg.address[dst];
	
	if (dst > 0x3) throw "dst out of range";
	if (val > 0xfff) throw "lit too big";
	
	return 0x4000 | (dst<<12) | val;
}