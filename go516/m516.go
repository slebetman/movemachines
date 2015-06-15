package main

import "fmt"

type CPU struct {
	reg       *Registers
	ram       *Memory
	instCount int
}

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
	return c.reg.value["pc"]
}

func (c *CPU) GOTO(address Word) {
	c.reg.value["pc"] = address
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

	reg.value["carry"] = 0
	reg.Plain(0x00, "acu")
	reg.R(0x01, "one", func() Word { return 1 })
	reg.R(0x02, "nil", func() Word { return 0 })
	reg.R(0x03, "all", func() Word { return 0xffff })
	reg.W(0x01, "add", func(v Word) { reg.value["acu"] += v })
	reg.W(0x02, "sub", func(v Word) { reg.value["acu"] -= v })
	reg.W(0x03, "and", func(v Word) { reg.value["acu"] &= v })
	reg.R(0x04, "rsh", func() Word { return reg.value["acu"] >> 1 })
	reg.W(0x04, "or", func(v Word) { reg.value["acu"] |= v })
	reg.Plain(0x05, "*a")
	reg.R(0x28, "inv", func() Word { return reg.value["acu"] ^ 0xffff })
	reg.W(0x28, "xor", func(v Word) { reg.value["acu"] ^= v })
	reg.Plain(0x2c, "*b")
	reg.Plain(0x2f, "pc")
	reg.W(0x2f, "pc", func(v Word) {
		reg.value["ret"] = reg.value["pc"]
		reg.value["pc"] = v
	})
	reg.Plain(0x32, "ret")
	reg.Plain(0x33, "*m")
	reg.W(0x33, "*m", func(v Word) { reg.value["*m"] = v & 0xffe0 })
	reg.R(0x06, "a", func() Word { return RAM.get(reg.value["*a"]) })
	reg.W(0x06, "a", func(v Word) { RAM.set(reg.value["*a"], v) })
	reg.R(0x07, "a-", func() Word {
		reg.value["*a"]--
		return RAM.get(reg.value["*a"] + 1)
	})
	reg.W(0x07, "+a", func(v Word) {
		reg.value["*a"]++
		RAM.set(reg.value["*a"], v)
	})
	reg.R(0x29, "a+", func() Word {
		reg.value["*a"]++
		return RAM.get(reg.value["*a"] - 1)
	})
	reg.W(0x29, "-a", func(v Word) {
		reg.value["*a"]--
		RAM.set(reg.value["*a"], v)
	})
	reg.R(0x2a, "high", func() Word {
		return RAM.get(reg.value["*a"]) >> 8
	})
	reg.W(0x2a, "high", func(v Word) {
		mvalue := RAM.get(reg.value["*a"]) & 0x00ff
		RAM.set(reg.value["*a"], mvalue|(v<<8))
	})
	reg.R(0x2b, "low", func() Word {
		return RAM.get(reg.value["*a"]) & 0xff
	})
	reg.W(0x2b, "low", func(v Word) {
		mvalue := RAM.get(reg.value["*a"]) & 0xff00
		RAM.set(reg.value["*a"], mvalue|(v&0x00ff))
	})
	reg.R(0x2d, "b", func() Word { return RAM.get(reg.value["*b"]) })
	reg.W(0x2d, "b", func(v Word) { RAM.set(reg.value["*b"], v) })
	reg.R(0x2e, "b-", func() Word {
		reg.value["*b"]--
		return RAM.get(reg.value["*b"] + 1)
	})
	reg.W(0x2e, "+b", func(v Word) {
		reg.value["*b"]++
		RAM.set(reg.value["*b"], v)
	})
	reg.W(0x30, "pcz", func(v Word) {
		if reg.value["acu"] == 0 {
			reg.write[reg.addr["pc"]](v)
		}
	})
	reg.R(0x30, "lit", func() Word {
		reg.value["pc"]++
		return RAM.get(reg.value["pc"] - 1)
	})
	reg.W(0x31, "pcc", func(v Word) {
		if reg.value["carry"] != 0 {
			reg.write[reg.addr["pc"]](v)
		}
	})
	reg.R(0x31, "conf", func() Word { return 0x0001 })
	
	for i, m := 0x08, 0; i <= 0x27; i, m = i+1, m+1 {
		reg.R(Addr(i), fmt.Sprintf("m%d",m), func (offset Word) func () Word {
			return func () Word {
				return RAM.get(reg.value["*m"] + offset)
			}
		}(Word(m)))
		
		reg.W(Addr(i),fmt.Sprintf("m%d",m), func (offset Word) func (Word) {
			return func (v Word){
				RAM.set(reg.value["*m"]+offset,v);
			}
		}(Word(m)))
	}

	return &CPU{
		reg: reg,
		ram: RAM,
	}
}
