# package require fileparse

proc debug {txt} {
	# puts $txt
}

proc eachline {var filename body} {
	upvar 1 $var v
	set f [open $filename]
	set txt [read $f]
	close $f
	
	foreach l [split $txt "\n"] {
		set v $l
		uplevel 1 $body
	}
}

namespace eval mmacro {
	proc init {} {
		global defines labels macros macroBuffer magic magiclist ifdef ifdefBraceCount
		
		array set defines {}
		array set labels {}

		set macros [list]
		set macroBuffer ""
		set magic 0
		set magiclist $magic
		set ifdefBraceCount 0
		set ifdef ""
	}

	proc lookUp {x definitions} {
		foreach def $definitions {global $def}
		while 1 {
			set found 0
			foreach def $definitions {
				if {[info exists ${def}($x)]} {
					set x [set ${def}($x)]
					set found 1
				}
			}
			if {!$found || [string is integer -strict $x]} break
		}
		return $x
	}
	
	proc existDefs {expression definitions} {
		foreach d $definitions {
			global $d
			array set def [array get $d]
		}
		
		set ret ""
		set prev 0
		foreach i [regexp -indices -all -inline \
			{[\+\-\*\/\%\&\|]} $expression] {
			
			set i [lindex $i 0]
			set x [string range $expression $prev [expr {$i-1}]]
			set prev [expr {$i+1}]
			
			if {
				[info exists def($x)] == 0 &&
				[string is integer -strict $x] == 0
			} {return 0}
		}
		set x [string range $expression $prev end]
		if {
			[info exists def($x)] == 0 &&
			[string is integer -strict $x] == 0
		} {return 0}
		return 1
	}

	proc exprDefs {expression definitions} {
		foreach def $definitions {global $def}
		
		set ret ""
		set prev 0
		foreach i [regexp -indices -all -inline \
			{[\+\-\*\/\%\&\|]} $expression] {
			
			set i [lindex $i 0]
			set x [string range $expression $prev [expr {$i-1}]]
			set op [string index $expression $i]
			set prev [expr {$i+1}]
			
			append ret [lookUp $x $definitions]
			append ret $op
		}
		set x [string range $expression $prev end]
		append ret [lookUp $x $definitions]
		set ret [expr $ret]
		return [expr {$ret&0xffff}]
	}

	proc parseDefine {raw} {
		global defines labels ifdef ifdefBraceCount

		set ret ""
		foreach line [split $raw \n] {
			if {[regexp -- {^\s*end (un)?defined} $line]} {
				set ifdef ""
				continue
			}
			if {$ifdef != ""} {
				debug "ifdef = $ifdef"

				if {$ifdef == "IGNORE"} {
					continue
				}
			}

			if {[regexp -- {^\s*if defined\s+(\S+)} $line -> name]} {
				if {[info exists defines($name)]} {
					debug DEFINED
					set ifdef "OK"
				} else {
					debug UNDEFINED
					set ifdef "IGNORE"
				}
			} elseif {[regexp -- {^\s*if undefined\s+(\S+)} $line -> name]} {
				if {[info exists defines($name)]} {
					debug DEFINED
					set ifdef "IGNORE"
				} else {
					debug UNDEFINED
					set ifdef "OK"
				}
			} elseif {[regexp -- {^\s*define\s+(\S+)\s+(.+)} $line -> name val]} {
				set defines($name) [list]
				foreach v $val {
					if {[string is integer -strict $v]} {
						lappend defines($name) $v
					} elseif {[info exists defines($v)]} {
						lappend defines($name) $defines($v)
					} elseif {[regexp -- {[\+\-\*\/\%\&\|]} $v]} {
						lappend defines($name) [exprDefs $v {defines}]
					} else {
						lappend defines($name) $v
					}
				}
				if {[string is integer -strict $defines($name)]} {
					set defines($name) [format 0x%x $defines($name)]
				}
			} else {
				if {[regexp -- {^\s*\:(\S+)} $line -> lab]} {
					# Set label to nothing for now..
					set labels($lab) {}
				}
				append ret "$line\n"
			}
		}
		return $ret
	}

	proc parseMacro {raw} {
		global macroBuffer
		
		set ret ""
		foreach line [split $raw \n] {
			if {$macroBuffer != "" || [regexp -- {^\s*macro} $line]} {
				append macroBuffer "$line\n"
				
				set L [regexp -all -- {\{} $macroBuffer]
				set R [regexp -all -- {\}} $macroBuffer]
				
				if {$R > $L} {
					error "Unbalanced close brace in:\n\t$macroBuffer"
				}
				if {$R == $L && $L > 0} {
					getMacro $macroBuffer
					set macroBuffer ""
				}
			} else {
				append ret "$line\n"
			}
		}
		return $ret
	}

	proc getMacro {macrodef} {
		global macros
		
		set macrodef [string trim $macrodef]
		
		if {[set n [string first "\{" $macrodef]] > 0} {
			set body [string range $macrodef [expr {$n+1}] end-1]
			set pattern [list]
			set vars [list]
			foreach p [string range $macrodef 5 [expr {$n-1}]] {
				if {[regexp -- {^\$} $p]} {
					lappend vars $p
					lappend pattern "(\\S+)"
				} else {
					set p [regsub -all -- \
						{[\[\]\\\+\.\*\^\$\(\)\?\!\{\}]} $p {\\&}]
					
					lappend pattern $p
				}
			}
			set body [substMacros [scopeMagic $body {$$_}]]
			lappend macros [list [join $pattern {[ \t]+}] $vars $body]
		} else {
			error "Empty body in macro:\n\t$macrodef"
		}
	}

	# Replaces macros in regular code:
	proc substMacros {raw} {
		global macros magic magiclist

		debug "------------ substMacros"

		foreach x $macros {
			set pattern [lindex $x 0]
			set vars [lindex $x 1]
			set body [lindex $x 2]
			
			# Process scope magic on macro body before insertion:
			lappend magiclist [incr magic]
			set body [scopeMagic $body {$$_}]
			set magiclist [lrange $magiclist 0 end-1]
			
			# Substitute macros until done:
			set done 0
			while {!$done} {
				set done 1
				
				set match [regexp -inline -- $pattern $raw]
				if {$match != ""} {
					set done 0
					set vals [lrange $match 1 end]
					set match [lindex $match 0]
					set map [list]
					# Map variable substitution:
					foreach x $vars y $vals {
						lappend map [list $x $y]
					}
					
					set map [join [lsort -decreasing $map]]
					set sub [string map $map $body]
					debug "----------- SUB\n$sub"
					set sub [parseDefine $sub]
					set raw [regsub -- "(?q)$match" $raw $sub]
				}
			}
		}
		return $raw
	}

	proc substDefines {raw} {
		global defines
		set ret ""
		foreach line [split $raw \n] {
			set x ""
			foreach word [split $line " \t"] {
				if {[info exists defines($word)]} {
					append x "$defines($word) "
				} else {
					append x "$word "
				}
			}
			append ret "[string trim $x]\n"
		}
		return $ret
	}

	# Resolve magic $$ variables by replacing them
	# with unique labels in each "scope":
	proc scopeMagic {raw {prefix _s}} {
		global magic magiclist

		set ret ""
		set indices [regexp -inline -indices -all -- {[{}]} $raw]
		set prev 0
		foreach i $indices {
			set i [lindex $i 0]
			
			if {[llength $magiclist] == 0} {
				error "Scope processing error"
			}
			
			set map [list {$$} ${prefix}[
				format %02x [lindex $magiclist end]]]
			append ret [string map $map \
				[string range $raw $prev [expr {$i-1}]]]
			
			# Create new scope or pop a scope:
			if {[string index $raw $i] == "\{"} {
				lappend magiclist [incr magic]
			} elseif {[string index $raw $i] == "\}"} {
				set magiclist [lrange $magiclist 0 end-1]
			}
			set prev [expr {$i+1}]
		}
		
		if {[llength $magiclist] == 0} {
			error "Scope processing error"
		}
		
		set map [list {$$} ${prefix}[
			format %02x [lindex $magiclist end]]]
		append ret [string map $map [string range $raw $prev end]]
		return $ret
	}

	# Remove comments:
	proc stripComments {raw} {
		foreach comment {
			{\s*#.*$} {\/\/.*$}
		} {
			set raw [regsub -- $comment $raw {}]
		}
		return $raw
	}

	proc parseLine {line} {
		set line [stripComments $line]
		set line [parseMacro $line]
		set line [substMacros $line]
		set line [scopeMagic $line]
		set line [parseDefine $line]
		set line [substDefines $line]
	}

	proc parse {var fname script} {
		upvar 1 $var line
		set i 1
		set ret ""
		
		eachline line $fname {
			if {[catch {parseLine $line} line]} {
				error "$fname, line $i: $line"
			}
			
			# Handle includes here:
			set temp [split $line \n]
			set line [list]
			foreach n $temp {
				if {$n != ""} {
					debug "// $fname:$i -- [string trim $n]"
				}

				if {[regexp -- {^\s*include\s+(.+)} $n -> incfile]} {
					set incfile [string trim $incfile]
					set n [uplevel 1 [list mmacro::parse n $incfile $script]]
				}
				append line "$n\n"
			}
			
			foreach line [split $line \n] {
				if {[string trim $line] != ""} {
					if {[catch {uplevel 1 $script} line]} {
						error "$fname, line $i: $line"
					}
					append ret "$line\n"
				}
			}
			incr i
		}
		return $ret
	}

	proc substLabels {raw} {
		global labels
		
		set ret ""
		foreach line [split $raw \n] {
			set line [string trim $line]
			if {$line != ""} {
				set x ""
				foreach word $line {
					if {[info exists labels($word)]} {
						append x "$labels($word) "
					} else {
						append x "$word "
					}
				}
				append ret "$x\n"
			}
		}
		return $ret
	}
}
