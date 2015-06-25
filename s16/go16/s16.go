package main

type CPU struct {
	reg       *Registers
	ram       *Memory
	instCount int
}

const (
	A, _ = iota, iota
	B, _
	PC, ADD
	PCZ, AND
	PCN, OR
	PCC, XOR
	PCZC, RSH
	PCZD, LIT
	CP, _
	C, _
	PlusC, Cminus
	MinusC, Cplus
	DP, _
	D, _
	Dplus, MinusD
	Dminus, PlusD
	CARRY, _
)

func (c *CPU) Decode(instruction Word) {
	c.copy(Addr((instruction>>12)&0x0f), Addr((instruction>>8)&0x0f))
	c.copy(Addr((instruction>>4)&0x0f), Addr(instruction&0x0f))
}

func (c *CPU) copy(dst Addr, src Addr) {
	c.instCount++
	
	val := c.reg.read[src]()
	
	c.reg.write[dst](val)
}

func (c *CPU) PC() Word {
	return c.reg.value[PC]
}

func (c *CPU) GOTO(address Word) {
	c.reg.value[PC] = address
}

func (c *CPU) Exec() {
	pc := c.PC()
	instruction := c.ram.get(pc)
	c.GOTO(pc + 1)
	c.Decode(instruction)
}

func NewCPU() *CPU {
	var reg = NewRegisters()
	var RAM = NewMemory()

	reg.value[CARRY] = 0
	reg.R(A, func() Word {
		return reg.value[A]
	})
	reg.R(B,func() Word {
		return reg.value[B]
	})
	reg.W(A, func(v Word) {
		var calc int32

		reg.value[A] = v;
		
		calc = int32(reg.value[A]) + int32(reg.value[B])
		if calc > 0xffff {
			reg.value[CARRY] = 1
		} else {
			reg.value[CARRY] = 0
		}
	})
	reg.W(B, func(v Word) {
		var calc int32

		reg.value[B] = v;
		
		calc = int32(reg.value[A]) + int32(reg.value[B])
		if calc > 0xffff {
			reg.value[CARRY] = 1
		} else {
			reg.value[CARRY] = 0
		}
	})
	reg.R(ADD, func() Word {
		return reg.value[A]+reg.value[B]
	})
	reg.R(AND, func() Word { return reg.value[A]&reg.value[B] })
	reg.R(OR, func() Word { return reg.value[A]|reg.value[B] })
	reg.R(XOR, func() Word { return reg.value[A]^reg.value[B] })
	reg.R(RSH, func() Word { return reg.value[A]>>1 })
	
	reg.W(PC, func(v Word) {
		reg.value[PC] = v
	})
	reg.W(PCZ, func(v Word) {
		if (reg.value[A] + reg.value[B]) == 0 {
			reg.value[PC] = v
		}
	})
	reg.W(PCN, func(v Word) {
		if (reg.value[A] + reg.value[B]) != 0 {
			reg.value[PC] = v
		}
	})
	reg.W(PCC, func(v Word) {
		if reg.value[CARRY] != 0 {
			reg.value[PC] = v
		}
	})
	reg.W(PCZC, func(v Word) {
		if RAM.get(reg.value[CP]) != 0 {
			reg.value[PC] = v
		}
	})
	reg.W(PCZD, func(v Word) {
		if RAM.get(reg.value[DP]) != 0 {
			reg.value[PC] = v
		}
	})
	
	reg.Plain(CP);
	reg.R(C, func() Word { return RAM.get(reg.value[CP]) })
	reg.W(C, func(v Word) { RAM.set(reg.value[CP], v) })
	reg.R(Cminus, func() Word {
		reg.value[CP]--
		return RAM.get(reg.value[CP] + 1)
	})
	reg.W(PlusC, func(v Word) {
		reg.value[CP]++
		RAM.set(reg.value[CP], v)
	})
	reg.R(Cplus, func() Word {
		reg.value[CP]++
		return RAM.get(reg.value[CP] - 1)
	})
	reg.W(MinusC, func(v Word) {
		reg.value[CP]--
		RAM.set(reg.value[CP], v)
	})
	reg.R(LIT, func() Word {
		reg.value[PC]++
		return RAM.get(reg.value[PC] - 1)
	})

	reg.Plain(DP);
	reg.R(D, func() Word { return RAM.get(reg.value[DP]) })
	reg.W(D, func(v Word) { RAM.set(reg.value[DP], v) })
	reg.R(MinusD, func() Word {
		reg.value[DP]--
		return RAM.get(reg.value[DP])
	})
	reg.W(Dplus, func(v Word) {
		reg.value[DP]++
		RAM.set(reg.value[DP] - 1, v)
	})
	reg.R(PlusD, func() Word {
		reg.value[DP]++
		return RAM.get(reg.value[DP])
	})
	reg.W(Dminus, func(v Word) {
		reg.value[DP]--
		RAM.set(reg.value[DP] + 1, v)
	})
	
	reg.R(LIT, func() Word {
		literal := RAM.get(reg.value[PC])
		reg.value[PC]++
		return literal
	})


	return &CPU{
		reg: reg,
		ram: RAM,
	}
}
