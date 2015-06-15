package main

import (
	"fmt"
	"os"
)

var cpu *CPU

func InitAsm(c *CPU) {
	cpu = c
}

func Asm(dst string, src string) Word {
	return (Word(cpu.reg.addr[dst]) << 7) | Word(cpu.reg.addr[src])
}

func Asmlit(dst string, val Word) Word {
	destination := Word(cpu.reg.addr[dst])

	if destination > 0x03 {
		fmt.Println("dst out of range")
		os.Exit(1)
	}
	if val > 0xfff {
		fmt.Println("lit too big")
		os.Exit(1)
	}

	return 0x4000 | (destination << 12) | val
}
