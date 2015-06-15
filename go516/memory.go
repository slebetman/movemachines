package main

import "fmt"

type Memory struct {
	value    [0x10000]Word
	observer func(address Word, value Word)
}

func NewMemory() *Memory {
	return &Memory{
		observer: func(addr Word, val Word) {},
	}
}

func (m *Memory) get(addr Word) Word {
	return m.value[addr]
}

func (m *Memory) set(addr Word, val Word) {
	m.value[addr] = val
	m.observer(addr,val)
}

func (m *Memory) load(dat []Word) {
	for i, d := range dat {
		m.value[i] = d
	}
}

func (m *Memory) clear() {
	for i, _ := range m.value {
		m.value[i] = 0x0000
	}
}

func (m *Memory) dump(from int, to int) {
	for i := from & 0xfff0; i <= to; i += 16 {
		fmt.Printf("%04x: ", i)
		for j := 0; j < 16; j++ {
			fmt.Printf("%04x ", m.value[i+j])
		}
		fmt.Print("\n")
	}
}
