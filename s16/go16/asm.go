package main

func Asm(dst Word, src Word,dst2 Word, src2 Word) Word {
	return (dst << 12) | (src << 8) | (dst2 << 4) | src2
}
