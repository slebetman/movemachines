#! /usr/bin/env tclsh

package require adlib
source mmacro.tcl

# Set this to 0 to disable autopack:
set enable_autopack 1

array set specialregs {}

proc defineRegisters {w r regdef} {
	upvar 1 $w wreg
	upvar 1 $r rreg
	
	foreach x [split $regdef \n] {
		set x [string trim $x]
		switch -- [llength $x] {
			1 {
				lappend wreg $x
				lappend rreg $x
			}
			2 {
				lappend wreg [lindex $x 0]
				lappend rreg [lindex $x 1]
			}
			4 {
				for {set i [lindex $x 1]} {$i <= [lindex $x 3]} {incr i} {
					set r [lindex $x 0]
					append r $i
					lappend wreg $r
					lappend rreg $r
				}
			}
		}
	}
}

defineRegisters wreg rreg {
	acu
	add one
	sub nil
	and all
	or rsh
	*a
	a
	+a a-
	m 0 -> 31
	xor inv
	-a a+
	high
	low
	*b
	b
	+b b-
	pc
	pcz lit
	pcc conf
	ret
	*m
	bank
	bnka
}

proc instpacked {inst1 inst2} {
	return "$inst1;$inst2"
}

set prevInst ""
proc inst16 {inst} {
	global prevInst
	
	if {[set ret [normaliseLiteral $inst]] != ""} {
		if {$prevInst != ""} {
			set ret "$prevInst\n$ret"
			set prevInst ""
		}
		return $ret
	} else {
		if {[set ret [autopack $inst $prevInst]] != ""} {
			set prevInst ""
			return $ret
		} else {
			set prevInst $inst
		}
	}
	return
}

proc normaliseLiteral {inst} {
	global labels wreg
	
	if {[llength $inst] == 1} {
		# Literal on a line
		if {[string is integer -strict $inst] ||
			[mmacro::existDefs $inst {labels defines}]} {
			
			return  $inst
		} else {
			error "Unable to resolve literal: $inst"
		}
	} elseif {[llength $inst] == 2} {
		# Regular instruction, check for literal:
		foreach {dst src} $inst break
		if {[string is integer -strict $src]} {
			if {$src == 0} {
				return "\t\t$dst nil"
			} elseif {$src == 1} {
				return "\t\t$dst one"
			} elseif {($src%0xffff) == 0xffff} {
				return "\t\t$dst all"
			} else {
				set dreg [lsearch -exact $wreg $dst]
				if {
					$dreg >= 0 &&
					$dreg < 4  &&
					($src&0xffff) <= 0xfff
				} {
					return "\t\t$dst lit;$src"
				} else {
					return "\t\t$dst lit\n\t\t$src"
				}
			}
		} elseif {[mmacro::existDefs $src {labels defines}]} {
			return "\t\t$dst lit\n\t\t$src"
		}
	} elseif {[llength $inst] == 3} {
		foreach {dst lit val} $inst break
		if {$lit == "lit"} {
			set dreg [lsearch -exact $wreg $dst]
			
			if {
				$dreg >= 0 &&
				$dreg < 4  &&
				($val&0xffff) <= 0xfff
			} {
				return "\t\t$dst lit;$val"
			} else {
				return "\t\t$dst lit\n\t\t$val"
			}
		} else {
			error "Syntax error: $inst"
		}
	} else {
		error "Syntax error: $inst"
	}
	return
}

proc normaliseAndPack {line} {
	global prevInst
	
	# Figure out if this is a packed instruction:
	set x [split $line {;}]
	if {[llength $x] == 1} {
		# single instruction
		return [inst16 [lindex $x 0]]
	} elseif {[llength $x] == 2} {
		# packed instruction
		set ret [instpacked [lindex $x 0] [lindex $x 1]]
		if {$prevInst != ""} {
			set ret "$prevInst\n$ret"
			set prevInst ""
		}
		return $ret
	} else {
		error "Invalid instruction format: $line"
	}
	return
}

proc codeGen {inst} {
	global wreg rreg specialregs
	
	set i [split $inst {;}]
	switch -- [llength $i] {
		1 {
			set i [lindex $i 0]
			switch -- [llength $i] {
				1 {
					set i [lindex $i 0]
					if {[string is integer -strict $i]} {
						set inst $i
					} else {
						error "Invalid instruction: $inst"
					}
				}
				2 {
					foreach {d s} $i break
					if {[info exists specialregs($d)]} {
						set d $specialregs($d)
					} 
					if {![string is integer -strict $d]} {
						set d [lsearch -exact $wreg $d]
					}
					if {[info exists specialregs($s)]} {
						set s $specialregs($s)
					} 
					if {![string is integer -strict $s]} {
						set s [lsearch -exact $rreg $s]
					}
					if {
						$d >= 0 && $d < 0x7f &&
						$s >= 0 && $s < 0x7f
					} {
						set inst [expr {($d<<7)|$s}]
					} else {
						error "Invalid instruction: $inst"
					}
				}
				default {
					error "Invalid instruction: $inst"
				}
			}
		}
		2 {
			switch -- [llength [lindex $i 1]] {
				1 {
					foreach {
						d lit
					} [lindex $i 0] {
						val
					} [lindex $i 1] break
					
					if {[info exists specialregs($d)]} {
						set d $specialregs($d)
					} 
					if {![string is integer -strict $d]} {
						set d [lsearch -exact $wreg $d]
					}
					
					if {
						$lit == "lit" &&
						[string is integer -strict $val] &&
						$val <= 0xfff &&
						$d >= 0 && $d < 4
					} {
						set inst [expr {0x4000|($d<<12)|$val}]
					} else {
						error "Invalid instruction: $inst"
					}
				}
				2 {
					foreach {
						d1 s1
					} [lindex $i 0] {
						d2 s2
					} [lindex $i 1] break
					
					foreach d {d1 d2} s {s1 s2} {
						if {[info exists specialregs([set $d])]} {
							set $d $specialregs([set $d])
						} 
						if {![string is integer -strict [set $d]]} {
							set $d [lsearch -exact $wreg [set $d]]
						}
						if {[info exists specialregs([set $s])]} {
							set $s $specialregs([set $s])
						} 
						if {![string is integer -strict [set $s]]} {
							set $s [lsearch -exact $rreg [set $s]]
						}
					}
					if {
						$d1 >= 0 && $d1 < 8 &&
						$d2 >= 0 && $d2 < 16 &&
						$s1 >= 0 && $s1 < 16 &&
						$s2 >= 0 && $s2 < 16
					} {
						set inst [expr {
							0x8000|
							($d1<<12)|($s1<<8)|
							($d2<<4)|$s2
						}]
					} else {
						error "Invalid instruction: $inst"
					}
				}
			}
		}
		default {
			error "Invalid instruction: $inst"
		}
	}
	return [format 0x%04x $inst]
}

proc autopack {inst prev} {
	global rreg wreg enable_autopack
	
	if {$enable_autopack == 0} {
		return [join [list $prev $inst] \n]
	}
	
	foreach {dst src} $inst break
	set dst [lsearch -exact $wreg [string trim $dst]]
	set src [lsearch -exact $rreg [string trim $src]]
	if {[string trim $prev] == ""} {
		# If packable return nothing, else return instruction:
		if {
			$dst >= 0 && $dst < 8 &&
			$src >= 0 && $src < 16
		} {
			return
		}
		return $inst
	}
	# Return packed instruction or two separate instructions:
	if {
		$dst >= 0 && $dst < 16 &&
		$src >= 0 && $src < 16
	} {
		return "$prev;$inst"
	}
	return "$prev\n$inst"
}

proc shrink {loc} {
	global labels
	
	foreach {name val} [array get labels] {
		if {$val > $loc} {
			incr val -1
			set labels($name) $val
		}
	}
}

proc shrinkLabels {raw} {
	global labels wreg enable_autopack
	
	set ret [list]
	while {[llength $raw]} {
		set line [string trim [shift raw]]
		set line [regsub -all -- {\s+} $line " "]
		set line [split $line " "]
		set dst [lsearch -exact $wreg [lindex $line 0]]
		if {
			[lindex $line 1] == "lit" &&
			$dst >= 0 &&
			$dst < 4
		} {
			set lab [shift raw]
			if {[mmacro::existDefs $lab {labels defines}]} {
				set addr [mmacro::exprDefs $lab {labels defines}]
				if {$addr <= 0xfff && $enable_autopack} {
					shrink [llength $ret]
					lappend ret "[join $line]; $lab"
				} else {
					lappend ret [join $line] $lab
				}
			} else {
				error "Unknown label: $lab"
			}
		} elseif {$line != ""} {
			lappend ret [join $line]
		}
	}
	return $ret
}

proc substLabels {raw} {
	global labels wreg enable_autopack
	
	set ret [list]
	while {[llength $raw]} {
		set line [string trim [shift raw]]
		set line [regsub -all -- {\s+} $line " "]
		set line [split $line " "]
		set dst [lsearch -exact $wreg [lindex $line 0]]
		if {$line != ""} {
			set x ""
			foreach word $line {
				if {[mmacro::existDefs $word {labels defines}]} {
					append x [mmacro::exprDefs $word {labels defines}]
					append x " "
				} else {
					append x "$word "
				}
			}
			lappend ret [join $x]
		}
	}
	return $ret
}

# test:
mmacro::init
set asm [list]
set loc 0
if {[catch {
	foreach fname $argv {
		set code [list]
		mmacro::parse x $fname {lappend code $x}
		
		set linecount 1
		foreach x $code {
			set x [string trim $x]
			if {[catch {
				if {[regexp -- {^\s*\:} $x]} {
					# Label:
					set labels([string trimleft $x :]) [llength $asm]
					# Don't autopack at a label:
					if {$prevInst != ""} {
						lappend asm [string trim $prevInst]
						set prevInst ""
					}
				} elseif {$x == "autopack"} {
					set enable_autopack 1
				} elseif {$x == "noautopack"} {
					set enable_autopack 0
				} elseif {[lindex $x 0] == "register"} {
					set specialregs([lindex $x 1]) [lindex $x 2]
				} else {
					set x [string trim [normaliseAndPack $x]]
					foreach inst [split $x \n] {
						set inst [string trim $inst]
						if {$inst != ""} {
							lappend asm $inst
						}
					}
				}
			} err]} {
				error "$fname, line $linecount: $err"
			}
			incr linecount
		}
	}
	set asm [shrinkLabels $asm]
	set asm [substLabels $asm]
	foreach inst [string trim $asm] {
		puts -nonewline "$loc [codeGen $inst] ;"
		if {[string is integer -strict $inst] &&
			($inst & 0x8000)
		} {
			set inst [expr {((~($inst-1))&0xffff)*-1}]
		}
		puts $inst
		incr loc
	}
} err]} {
	error $err
}
