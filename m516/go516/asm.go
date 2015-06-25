package main

import (
	"fmt"
	"os"
)

func Asm(dst Word, src Word) Word {
	return (dst << 7) | src
}

func Asmlit(dst Word, val Word) Word {
	if dst > 0x03 {
		fmt.Println("dst out of range")
		os.Exit(1)
	}
	if val > 0xfff {
		fmt.Println("lit too big")
		os.Exit(1)
	}

	return 0x4000 | (dst << 12) | val
}
