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

function disassemble (val) {
	let packed = val & 0x8000;
	let lit = val & 0x4000;
	let dst, src, dst2, src2;

	if (packed) {
		dst = reg[(val & 0x7000) >> 12].name.write;
		src = reg[(val & 0x0f00) >> 8].name.read;
		dst2 = reg[(val & 0x00f0) >> 4].name.write;
		src2 = reg[val & 0x000f].name.read;

		return `${dst} ${src} ${dst2} ${src2}`;
	}
	else {
		if (lit) {
			dst = reg[(val & 0x3000) >> 12].name.write;
			src = val & 0x0fff;
			return `${dst} lit ${formatCell(src)}`;
		}
		else {
			dst = reg[(val & 0x3f80) >> 7].name.write;
			src = reg[val & 0x007f].name.read;
			return `${dst} ${src}`;
		}
	}
}
