package main

type Registers struct {
	read  [0x10]func() Word
	write [0x10]func(Word)
	value [0x11]Word
}

func NewRegisters() *Registers {
	return &Registers{}
}

func (r *Registers) R(addr Addr, fn func() Word) {
	r.read[addr] = fn
}

func (r *Registers) W(addr Addr, fn func(Word)) {
	r.write[addr] = fn
}

func (r *Registers) Plain(addr Addr) {
	r.value[addr] = 0
	r.R(addr, func() Word {
		return r.value[addr]
	})
	r.W(addr, func(val Word) {
		r.value[addr] = val
	})
}
