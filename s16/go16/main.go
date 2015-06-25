package main

import (
	"fmt"
	"time"
	// "github.com/davecheney/profile"
)

func freq(f float64) string {
	if f < 1000 {
		return fmt.Sprintf("%0.2f Hz", f)
	}
	f /= 1000
	if f < 1000 {
		return fmt.Sprintf("%0.2f kHz", f)
	}
	f /= 1000
	if f < 1000 {
		return fmt.Sprintf("%0.2f MHz", f)
	}
	f /= 1000
	return fmt.Sprintf("%0.2f GHz", f)
}

func main() {
	var cpu = NewCPU()
	// cpu.ram.clear()

	var program = []Word{
		Asm(DP,LIT,      // 0
			D,LIT),
		0x40,            // 1
		0x0fff,          // 2
		Asm(A,LIT,       // 3 -- $0
			B,LIT),
		0xfff,           // 4
		0xffff,          // 5 (-1)
		Asm(CP,LIT,A,A), // 6
		0xff,            // 7
		Asm(A,ADD,       // 8 -- $1
			PlusC,A),
		Asm(PCN,LIT,A,A),// 9 -- LOOP $1
		8,               // 10
		Asm(A,D,         // 11
			D,ADD),
		Asm(PCN,LIT,A,A),// 12
		3,               // 13
		Asm(PC,LIT,A,A), // 14
		14,
	}

	cpu.ram.load(program)

	cpu.ram.observer = func(addr Word, value Word) {
		if addr == cpu.reg.value[DP] {
			fmt.Printf("\rD = %04x    ", value)
		}
	}

	cpu.GOTO(0)
	cpu.instCount = 0

	// pprof := profile.Start(profile.CPUProfile)

	start := time.Now()
	for cpu.PC() < 14 {
		cpu.Exec()
	}
	lapsed := time.Since(start)

	// pprof.Stop()

	fmt.Println(freq(float64(cpu.instCount) / (float64(lapsed) / float64(time.Second))))

	// cpu.ram.dump(0, 0x1f)
}
