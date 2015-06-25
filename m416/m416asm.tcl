#! /usr/bin/env tclsh

set insCount 0
array set vars {}
array set labels {}

proc errMsg {msg} {
	puts stderr $msg
}

proc unlist {ls args} {
	foreach val $ls var $args {
		upvar 1 $var assign
		set assign $val
	}
}

proc addNew {a key {val {}}} {
	set i 0
	upvar 1 $a arr
	set x [string trim $key]
	set key "$x"
	while {[info exists arr($key)]} {
		set key "$x.$i"
		incr i
	}
	set arr($key) [string trim $val]
	return "$key"
}

proc strip_comment {c l} {
	set comment [string first $c $l]
	if {$comment != -1} {
		return [string range $l 0 [expr $comment -1]]
	}
	return $l
}

proc lastAdded {a key} {
	upvar 1 $a arr
	return [lindex [lsort -dictionary [array names arr $key*]] end]
}

proc isPackedIns {code} {
	if {[string first ";" $code] != -1} {
		return 1
	}
	return 0
}

proc isLabel {code} {
	if {[string index [string trim $code] 0] == ":"} {
		return 1
	}
	return 0
}

proc mangle {code} {
	global vars labels
	
	# Label & define mangling
	# Also do literal and define substitution
	set ret ""
	set lineCount 0
	foreach line $code {
		incr lineCount
		set line [string trim [strip_comment "#" $line]]
		if {$line == ""} continue
		
		if {[isLabel $line]} {
			unlist [split [string range $line 1 end] "@"] line L
			set line [string trim $line]
			set L [string trim $L]
			set line [addNew labels $line $L]
			lappend ret [list ":$line" $lineCount]
		} elseif {[string compare -length 6 $line "define"] == 0} {
			set line [split $line " "]
			addNew vars [lindex $line 1] [lindex $line 2]
		} else {
			if {[isPackedIns $line]} {
				set line [split $line ";"]
				if {[llength $line] == 2} {
					unlist $line i1 i2
					unlist $i1 dst op src
					set d [lastAdded vars $dst]
					if {$d != ""} {set dst $d}
					set s [lastAdded vars $src]
					if {$s != ""} {set src $s}
					set i1 "$dst = $src"
					unlist $i2 dst op src
					set d [lastAdded vars $dst]
					if {$d != ""} {set dst $d}
					set s [lastAdded vars $src]
					if {$s != ""} {set src $s}
					set i2 "$dst = $src"
					lappend ret [list "$i1 ; $i2" $lineCount]
				} else {
					error "Syntax error $lineCount: $line"
				}
			} else {
				unlist [split $line " "] dst op src
				if {[info exists vars($dst)]} {
					set dst $vars([lastAdded vars $dst])
				}
				if {$op == ""} {
					if {[string compare -length 4 $dst "NEXT"] == 0} {
						set s [lastAdded labels $dst]
						if {$s != ""} {
							unlist [split $s "."] s v
							if {$v == ""} {
								set dst "$s.0"
							} else {
								set dst "$s.[expr $v+1]"
							}
						}
					}
					lappend ret [list $dst $lineCount]
				} else {
					if {[string compare -length 4 $src "NEXT"] == 0} {
						set s [lastAdded labels $src]
						if {$s != ""} {
							unlist [split $s "."] s v
							if {$v == ""} {
								set src "$s.0"
							} else {
								set src "$s.[expr $v+1]"
							}
						}
					}
					lappend ret [list [list $dst $op $src] $lineCount]
				}
			}
		}
	}
	return $ret
}

proc subLiteral {code n} {
	global vars labels
	upvar 1 $n loc
	
	set ret ""
	foreach res $code {
		unlist $res line lineCount
		if {[isLabel $line]} {
			set line [string range $line 1 end]
			if {$labels($line) != ""} {
				set loc $labels($line)
			} else {
				set labels($line) $loc
			}
		} else {
			if {[isPackedIns $line] == 0} {
				unlist [split $line " "] d o s
				if {$o == ""} {
					lappend ret [list $d $lineCount $loc]
					incr loc
				} else {
					set src [lastAdded labels $s]
					if {$src == ""} {
						set src [lastAdded vars $s]
						if {$src == ""} {
							if {[string is integer -strict $s]} {
								if {$s == 1} {
									lappend ret [list "$d $o one" $lineCount $loc]
								} elseif {$s == 0} {
									lappend ret [list "$d $o nil" $lineCount $loc]
								} elseif {$s == 65535} {
									lappend ret [list "$d $o all" $lineCount $loc]
								} elseif {$s == -1} {
									lappend ret [list "$d $o all" $lineCount $loc]
								} else {
									lappend ret [list "$d $o lit" $lineCount $loc]
									incr loc
									lappend ret [list "$s" $lineCount $loc]
								}
							} else {
								lappend ret [list "$d $o $s" $lineCount $loc]
							}
							incr loc
						} else {
							# do define substitution as well:
							# currently we don't support nested defines.
							set val $vars($src)
							if {[string is integer -strict $val]} {
								if {$val == 1} {
									lappend ret [list "$d $o one" $lineCount $loc]
								} elseif {$val == 0} {
									lappend ret [list "$d $o nil" $lineCount $loc]
								} elseif {$val == 65535} {
									lappend ret [list "$d $o all" $lineCount $loc]
								} elseif {$val == -1} {
									lappend ret [list "$d $o all" $lineCount $loc]
								} else {
									lappend ret [list "$d $o lit" $lineCount $loc]
									incr loc
									lappend ret [list "$s" $lineCount $loc]
								}
							} else {
								lappend ret [list "$d $o $val" $lineCount $loc]
							}
							incr loc
						}
					} else {
						lappend ret [list "$d $o lit" $lineCount $loc]
						incr loc
						lappend ret [list "$s" $lineCount $loc]
						incr loc
					}
				}
			} else {
				lappend ret [list $line $lineCount $loc]
				incr loc
			}
		}
	}
	return $ret
}

proc subLabels {code} {
	global vars labels
	
	# Label substitution
	set ret ""
	foreach res $code {
		unlist $res line lineCount loc
		if {[llength $line] == 1} {
			if {[info exists labels($line)]} {
				lappend ret [list $labels($line) $lineCount $loc]
				continue
			}
		}
		lappend ret [list $line $lineCount $loc]
	}
	return $ret
}

proc subVars {code} {
	global vars labels
	
	# Variable substitution
	set ret ""
	foreach res $code {
		unlist $res line lineCount loc
		if {[isPackedIns $line] == 0} {
			set l ""
			foreach x $line {
				if {[info exists labels($x)]} {
					lappend l $labels($x)
					continue
				}
				lappend l $x
			}
			set line $l
		}
		set l ""
		foreach x $line {
			if {[info exists vars($x)]} {
				if {$vars($x) != ""} {
					lappend l $vars($x)
				}
				continue
			}
			lappend l $x
		}
		lappend ret [list [join $l " "] $lineCount $loc]
	}
	return $ret
}

array set ins {
	acu 0x00
	add 0x01 one 0x01
	and 0x02 nil 0x02
	all 0x03 or 0x03
	xor 0x04 rsh 0x04
	stp 0x05
	std 0x06
	stk 0x07
	m0 0x08 m1 0x09 m2 0x0a m3 0x0b
	m4 0x0c m5 0x0d m6 0x0e m7 0x0f
	lit 0x10
	pc  0x11
	ret 0x12
	psp 0x13
	pst 0x14
	mp  0x15
}

array set cond {
	{} 0
	z  1
	nz 2
	c  3
	nc 4
	s  5
}

array set mode {
	= 0
	/ 1
	\\ 2
	- 3
}

proc asm {code} {
	global ins cond mode
	set ret ""
	foreach res $code {
		unlist $res line lineCount loc
		if {[isPackedIns $line]} {
			unlist [split $line " "] d1 x s1 x d2 x s2
			
			foreach x "$s1 $d1 $s2 $d2" {
				if {[info exists ins($x)] == 0} {
					error "Instruction error $lineCount: $line. Invalid register $x"
				}
			}
			if {$ins($d1) > 0x7} {
				error "Packed Instruction error $lineCount: $line. Invalid first dest $d1"
			}
			foreach x "$s1 $s2 $d2" {
				if {$ins($x) > 0xf} {
					error "Packed Instruction error $lineCount: $line. Invalid register $x"
				}
			}
			set i [expr {
				0x8000          |
				($ins($d1)<<12) |
				($ins($s1)<<8)  |
				($ins($d2)<<4)  |
				$ins($s2)
			}]
		} elseif {[string is integer $line]} {
			set i $line
		} else {
			unlist [split $line " "] d o s
			set m [string index $o end]
			set c [string range $o 0 end-1]			
			if {[info exists ins($d)] == 0} {
				error "Instruction error $lineCount: $line. Invalid register $d"
			}
			if {[info exists ins($s)] == 0} {
				error "Instruction error $lineCount: $line. Invalid register $s"
			}
			if {[info exists mode($m)] == 0} {
				error "Instruction error $lineCount: $line. Invalid mode $m"
			}
			if {[info exists cond($c)] == 0} {
				error "Instruction error $lineCount: $line. Invalid condition $c"
			}
			set i [expr {
				($mode($m)<<13) |
				($ins($d)<<8)   |
				($cond($c)<<5)  |
				$ins($s)
			}]
		}
		set i [format "0x%04x" [expr {$i % 65536}]]
		append i "  ;$line"
		lappend ret "$loc  $i"
	}
	return $ret
}

proc m416 {outFile args} {
	set res ""
	foreach asmFile $args {
		# Process in 4 phases:
		# 1. Label & define mangling
		# 2. Literal substitution
		# 3. Label & defined substitution
		# 4. Code generation
		
		set f [open $asmFile "r"]
		append res "[read $f]\n"
		close $f
	}
	
	set n 0
	set res [split $res "\n"]
	if {[catch {
		set res [mangle $res]
		set res [subLiteral $res n]
		set res [subLabels $res]
		set res [subVars $res]
		set res [asm $res]
	} err]} {
		errMsg $err
	} else {	
		# Output
		puts $outFile [join [lsort -dictionary $res] "\n"]
	}
	return $err
}


if {$argc < 1} {
	if {[lsearch -exact [package names] "Tk"] == -1} {
		puts "M416 Assembler"
		puts "usage: m416asm file file file..."
		puts "outputs to stdout."
		exit
	}
	proc makeConsole {} {
		pack [text .t -yscrollcommand {.s set} -font "Courier 8"] \
			-fill both -expand 1 -side left
		pack [scrollbar .s -command {.t.internal yview} -orient vertical] -side right -fill y
		focus -force .t
		.t tag configure head -background "#ccccff"
		
		bind .t <KeyPress-Return> handlekey
		
		.t insert end ">"
		
		rename .t .t.internal
	}
	
	proc errMsg {msg} {}
	
	proc handlekey {} {
		global widget
		global pass
		global functions
		set idx [.t.internal index {end -1 lines}]
		set key [string trim [.t.internal get "$idx +1 chars" end]]
		
		.t.internal insert end "\n[eval $key]"
		
		after 50 {.t.internal insert end ">"}
	}
	
	proc dir {} {
		set ret ""
		foreach {x} [glob *] {
			append ret "$x\n"
		}
		return $ret
	}
	
	proc notEnd {} {
		set current [split [.t.internal index insert] "."]
		set this [lindex $current 0]
		set that [lindex [split [.t.internal index end] "."] 0]
		incr this
		if {$this != $that} {
			return 1
		}
		set this [lindex $current 1]
		if {$this <= 1} {
			return 1
		}
		return 0
	}
	
	makeConsole
	
	proc .t {args} {
		if {[lindex $args 0] == "insert" &&
			[lindex $args 1] != "end"} {
			if {[notEnd]} {
				set args [lreplace $args 1 1 "end"]
				.t.internal mark set insert end
			}
		} elseif {[lindex $args 0] == "delete"} {
			if {[notEnd]} {
				return
			}
		}
		eval .t.internal $args
	}
	
	proc unknown {args} {
		return "Invalid command name"
	}

} else {
	eval m416 stdout $argv
}
