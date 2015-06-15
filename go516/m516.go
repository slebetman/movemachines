package main

type CPU struct {
	reg       *Registers
	ram       *Memory
	instCount int
}

const (
	ACU, _ = iota, iota
	ADD, ONE
	SUB, NIL
	AND, ALL
	OR, RSH
	Aptr, _
	A, _
	PlusA, Aminus
	M0, _
	M1, _
	M2, _
	M3, _
	M4, _
	M5, _
	M6, _
	M7, _
	M8, _
	M9, _
	M10, _
	M11, _
	M12, _
	M13, _
	M14, _
	M15, _
	M16, _
	M17, _
	M18, _
	M19, _
	M20, _
	M21, _
	M22, _
	M23, _
	M24, _
	M25, _
	M26, _
	M27, _
	M28, _
	M29, _
	M30, _
	M31, _
	XOR, INV
	MinusA, Aplus
	HIGH, _
	LOW, _
	Bptr, _
	B, _
	PlusB, Bminus
	PC, _
	PCZ, LIT
	PCC, CONF
	RET, _
	Mptr, _
)

const CARRY = 0x80

func (c *CPU) Decode(instruction Word) {
	format := instruction >> 14

	if format == 0 {
		c.copy(Addr((instruction>>7)&0x7f), Addr(instruction&0x7f))
	} else if format == 1 {
		c.literal(Addr((instruction>>12)&0x03), instruction&0xfff)
	} else {
		c.copy(Addr((instruction>>12)&0x07), Addr((instruction>>8)&0x0f))
		c.copy(Addr((instruction>>4)&0x0f), Addr(instruction&0x0f))
	}
}

func (c *CPU) literal(dst Addr, val Word) {
	c.instCount++
	c.reg.write[dst](val)
}

func (c *CPU) copy(dst Addr, src Addr) {
	c.instCount++
	c.reg.write[dst](c.reg.read[src]())
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
	reg.Plain(ACU)
	reg.R(ONE, func() Word { return 1 })
	reg.R(NIL, func() Word { return 0 })
	reg.R(ALL, func() Word { return 0xffff })
	reg.W(ADD, func(v Word) {
		var calc int32
		calc = int32(reg.value[ACU]) + int32(v)
		if calc > 0xffff {
			reg.value[CARRY] = 1
		} else {
			reg.value[CARRY] = 0
		}
		reg.value[ACU] = Word(calc)
	})
	reg.W(SUB, func(v Word) {
		var calc int32
		calc = int32(reg.value[ACU]) - int32(v)
		if calc < 0 {
			reg.value[CARRY] = 0
		} else {
			reg.value[CARRY] = 1
		}
		reg.value[ACU] = Word(calc)
	})
	reg.W(AND, func(v Word) { reg.value[ACU] &= v })
	reg.R(RSH, func() Word { return reg.value[ACU] >> 1 })
	reg.W(OR, func(v Word) { reg.value[ACU] |= v })
	reg.Plain(Aptr)
	reg.R(INV, func() Word { return reg.value[ACU] ^ 0xffff })
	reg.W(XOR, func(v Word) { reg.value[ACU] ^= v })
	reg.Plain(Bptr)
	reg.Plain(PC)
	reg.W(PC, func(v Word) {
		reg.value[RET] = reg.value[PC]
		reg.value[PC] = v
	})
	reg.Plain(RET)
	reg.Plain(Mptr)
	reg.W(Mptr, func(v Word) { reg.value[Mptr] = v & 0xffe0 })
	reg.R(A, func() Word { return RAM.get(reg.value[Aptr]) })
	reg.W(A, func(v Word) { RAM.set(reg.value[Aptr], v) })
	reg.R(Aminus, func() Word {
		reg.value[Aptr]--
		return RAM.get(reg.value[Aptr] + 1)
	})
	reg.W(PlusA, func(v Word) {
		reg.value[Aptr]++
		RAM.set(reg.value[Aptr], v)
	})
	reg.R(Aplus, func() Word {
		reg.value[Aptr]++
		return RAM.get(reg.value[Aptr] - 1)
	})
	reg.W(MinusA, func(v Word) {
		reg.value[Aptr]--
		RAM.set(reg.value[Aptr], v)
	})
	reg.R(HIGH, func() Word {
		return RAM.get(reg.value[Aptr]) >> 8
	})
	reg.W(HIGH, func(v Word) {
		mvalue := RAM.get(reg.value[Aptr]) & 0x00ff
		RAM.set(reg.value[Aptr], mvalue|(v<<8))
	})
	reg.R(LOW, func() Word {
		return RAM.get(reg.value[Aptr]) & 0xff
	})
	reg.W(LOW, func(v Word) {
		mvalue := RAM.get(reg.value[Aptr]) & 0xff00
		RAM.set(reg.value[Aptr], mvalue|(v&0x00ff))
	})
	reg.R(B, func() Word { return RAM.get(reg.value[Bptr]) })
	reg.W(B, func(v Word) { RAM.set(reg.value[Bptr], v) })
	reg.R(Bminus, func() Word {
		reg.value[Bptr]--
		return RAM.get(reg.value[Bptr] + 1)
	})
	reg.W(PlusB, func(v Word) {
		reg.value[Bptr]++
		RAM.set(reg.value[Bptr], v)
	})
	reg.W(PCZ, func(v Word) {
		if reg.value[ACU] == 0 {
			reg.write[PC](v)
		}
	})
	reg.R(LIT, func() Word {
		reg.value[PC]++
		return RAM.get(reg.value[PC] - 1)
	})
	reg.W(PCC, func(v Word) {
		if reg.value[CARRY] != 0 {
			reg.write[PC](v)
		}
	})
	reg.R(CONF, func() Word { return 0x0001 })

	for i, m := 0x08, 0; i <= 0x27; i, m = i+1, m+1 {
		reg.R(Addr(i), func(offset Word) func() Word {
			return func() Word {
				return RAM.get(reg.value[Mptr] + offset)
			}
		}(Word(m)))

		reg.W(Addr(i), func(offset Word) func(Word) {
			return func(v Word) {
				RAM.set(reg.value[Mptr]+offset, v)
			}
		}(Word(m)))
	}

	return &CPU{
		reg: reg,
		ram: RAM,
	}
}
