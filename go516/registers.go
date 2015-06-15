package main

type Registers struct {
	read  [0x80]func() Word
	write [0x80]func(Word)
	value map[string]Word
	name  [0x80]struct {
		read  string
		write string
	}
	addr map[string]Addr
}

func NewRegisters() *Registers {
	return &Registers{
		value: make(map[string]Word),
		addr:  make(map[string]Addr),
	}
}

func (r *Registers) R(addr Addr, name string, fn func() Word) {
	r.read[addr] = fn
	r.name[addr].read = name
	r.addr[name] = addr
}

func (r *Registers) W(addr Addr, name string, fn func(Word)) {
	r.write[addr] = fn
	r.name[addr].write = name
	r.addr[name] = addr
}

func (r *Registers) Plain(addr Addr, name string) {
	r.value[name] = 0
	r.R(addr, name, func() Word {
		return r.value[name]
	})
	r.W(addr, name, func(val Word) {
		r.value[name] = val
	})
}
