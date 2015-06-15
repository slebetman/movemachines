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
		Asm(Mptr, LIT),     // 0
		0x40,               // 1
		Asm(M0, LIT),       // 2
		0x0fff,             // 3
		Asmlit(ACU, 0xfff), // 4 -- $0
		Asm(Aptr, LIT),     // 5
		0xff,               // 6
		Asm(SUB, ONE),      // 7 -- $1
		Asm(PlusA, ACU),    // 8
		Asm(PCZ, LIT),      // 9
		13,                 // 10
		Asm(PC, LIT),       // 11
		7,                  // 12 -- LOOP $1
		Asm(ACU, M0),       // 13
		Asm(SUB, ONE),      // 14
		Asm(M0, ACU),       // 15
		Asm(PCZ, LIT),      // 16
		20,                 // 17
		Asm(PC, LIT),       // 18
		4,                  // 19 -- LOOP $0
		Asm(PC, LIT),       // 20
		20,
	}

	cpu.ram.load(program)

	cpu.ram.observer = func(addr Word, value Word) {
		if addr == cpu.reg.value[Mptr] {
			fmt.Printf("\rm0 = %04x    ", value)
		}
	}

	cpu.GOTO(0)
	cpu.instCount = 0

	// pprof := profile.Start(profile.CPUProfile)

	start := time.Now()
	for cpu.PC() < 20 {
		cpu.Exec()
		// fmt.Printf("\rpc = %04x",cpu.PC())
	}
	lapsed := time.Since(start)

	// pprof.Stop()

	fmt.Println(freq(float64(cpu.instCount) / (float64(lapsed) / float64(time.Second))))

	cpu.ram.dump(0, 0xff)
}
