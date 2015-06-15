# xmacro: mmacro-like macro processor.
#
# The following keywords are recognised by the macro processor:
#
# @define VARNAME <VALUE>
# @macro MACRO PATTERN {SCOPE}
# @if VAR OP COND
# @else if VAR OP COND
# @elseif VAR OP COND
# @else
# @end if
# @endif
# @include filename
# @comment {SCOPE}
# @quote {SCOPE}
# @type
# @extract /REGEXP/ from VAR as VAR
#
# @macro Pattern:
# A macro pattern is a string which when matched is replaced by the macro.
# If the pattern contains a $ sign followed by an alphanumeric word then it is
# recognised as a parameter to the macro. A word may contain the characters
# A-Z, a-z, numbers 0-9, the underscore _ and the $ sign. All other characters
# are considered word delimiters.
# Spaces and tabs in the macro pattern are recognised as whitespace. When
# searching for a match, the whitespace in the pattern and the matched
# string are collapsed. As such, any number consecutive whitespace equals to
# exactly a single space.
# The special sequence .. (two dots) is recognised as a sequence of zero or more
# whitespace. As with whitespace matching, the sequence matches any number of
# consecutive whitespace. In addition it also matches 'nothing'.
#
# @if Parameters:
# The parameters to @if has three parts: the variable or string to check, the
# operation and the condition to check against. The operations available are:
#
#   is , == , != , < , > , <= , >=
#
# The math operators are obvious. The operators '==' and '!=' can also be used
# on strings. The 'is' operator is used to check on the type-ness or class of
# the given variable or string. The conditionals available to the 'is' operator
# are:
#
# alnum      alphanumeric
# alpha      alphabets
# boolean    either 1, 0, true, false, yes or no
# integer    integers
# true       either 1, true or yes
# false      either 0, false or no
# lower      lower case alphabets
# upper      upper case alphabets
# defined    macro variable is defined
#
# The 'is' operator can be negated by adding 'not'. For example:
#
#   @if MYVAR is not defined
#     @define MYVAR
#   @else if MYVAR isnot integer
#     @define MYVAR 1
#   @endif
#
# Like the keywords, the 'not' operator can either be concatenated to the 'is'
# operator or a separate word.
#
# Scopes:
# Braces {} in xmacro defines scopes. A scope is simply a block of code and
# is processed just like any other blocks of code. What makes a scope special
# is $$ substitution. Within each scope, the sequence $$ (two dollar signs)
# is replaced with a unique string.
#
# The primary purpose of scopes is to allow reuse of label/variable names. As
# a side effect, scoping leads to a more structured programming style.
#

package require fileparse
package require adlib

namespace eval xmacro {
	array set E {
		if         {^\s*\@if\s+(\S+)\s+(.*)}
		else       {^\s*\@else}
		elseif     {^\s*\@else\s*if\s+(\S+)\s+(.*)}
		endif      {^\s*\@end\s*if}
		vars       {([\w\$]*)([^\w\$]*)}
		include    {^\s*\@include\s+(.+)}
		macro      {^\s*\@macro}
		define     {^\s*@define\s+(\S+)(.*)}
		type       {^\s*@type\s+(\S+)(.*)}
		expsplit   {[\+\-\*\/\%\&\|]}
		rechars    {[\[\]\\\+\.\*\^\$\(\)\?\!\{\}]}
		comment    {^\s*\@comment}
		quote      {^\s*\@quote}
		extract    {^\s*\@extract\s+/(.+)/\s+from\s+(\S+)\s+as\s+(\S+)}
	}

	proc init {} {
		global defines types
		catch {
			unset defines
			unset types
		}
		array set defines {}
		array set types {
			alnum    {[[:alnum:]]+}
			alpha    {[[:alpha:]]+}
			boolean  {(0x)?0*(0|1)}
			integer  {0x[\da-fA-F]+|\d}
			lower    {[a-z]+}
			upper    {[A-Z]+}
		}
		
		foreach {var val} {
			macros {}
			macroBuffer ""
			magic 0
			magiclist 0
			ifBuffer ""
			commentBuffer ""
			quoteBuffer ""
		} {
			global $var
			set $var $val
		}
	}
	
	proc getBlock {line startblock endblock buffername} {
		upvar 1 $buffername buffer
		
		set ret ""
		append buffer "$line\n"
		
		set L [regexp -all -lineanchor -- $startblock $buffer]
		set R [regexp -all -lineanchor -- $endblock $buffer]
		
		if {$R > $L} {
			error "Unbalanced close brace in:\n\t$buffer"
		}
		if {$R == $L && $L > 0} {
			set ret $buffer
			set buffer ""
		}
		return $ret
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
		foreach i [regexp -indices -all -inline $xmacro::E(expsplit) $expression] {
			
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
		foreach i [regexp -indices -all -inline $xmacro::E(expsplit) $expression] {
			
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

	proc setDefines {name val} {
		global defines
		
		set defines($name) [list]
		if {$val == ""} {
			set defines($name) ""
		} else {
			foreach v $val {
				if {[string is integer -strict $v]} {
					lappend defines($name) $v
				} elseif {[info exists defines($v)]} {
					lappend defines($name) $defines($v)
				} elseif {[regexp -- $xmacro::E(expsplit) $v]} {
					lappend defines($name) [exprDefs $v {defines}]
				} else {
					lappend defines($name) $v
				}
			}
			if {[string is integer -strict $defines($name)]} {
				set defines($name) [format 0x%x $defines($name)]
			}
		}
	}

	proc parseDefine {raw} {
		global defines types
		
		set ret ""
		foreach line [split $raw \n] {
			if {[regexp -- $xmacro::E(define) $line -> name val]} {
				setDefines $name $val
			} elseif {[regexp -- $xmacro::E(extract) $line -> re var name]} {
				if {[regexp -- $re $var -> val]} {
					setDefines $name $val
				} else {
					error "Failed extract:\n\t/$re/ from $var"
				}
			} elseif {[regexp -- $xmacro::E(type) $line -> name val]} {
				foreach {t v} [array get types] {
					regsub -all -- "\\\[:$t:\\\]" $val $v val
				}
				set types($name) $val
			} else {
				append ret "$line\n"
			}
		}
		return $ret
	}

	proc parseMacro {raw} {
		global macroBuffer
		
		set ret ""
		foreach line [split $raw \n] {
			if {$macroBuffer != "" || [regexp -- $xmacro::E(macro) $line]} {
				set macrodef [getBlock $line {\{} {\}} macroBuffer]
				if {$macrodef != ""} {
					getMacro $macrodef
				}
			} else {
				append ret "$line\n"
			}
		}
		return $ret
	}
	
	proc parseIf {raw} {
		global ifBuffer
		
		set ret ""
		foreach line [split $raw \n] {
			if {$ifBuffer != "" || [regexp -- $xmacro::E(if) $line]} {
				set block [getBlock $line $xmacro::E(if) $xmacro::E(endif) ifBuffer]
				if {$block != ""} {
					append ret [trimIf {} {} $block]
				}
			} else {
				append ret "$line\n"
			}
		}
		return $ret
	}
	
	proc parseQuote {rawvar} {
		global quoteBuffer
		upvar 1 $rawvar raw
		
		set ret ""
		set quote ""
		foreach line [split $raw \n] {
			if {$quoteBuffer != "" || [regexp -- $xmacro::E(quote) $line]} {
				set quote [getBlock $line {\{} {\}} quoteBuffer]
			} else {
				append ret "$line\n"
			}
		}
		set raw $ret
		return [lindex $quote 1]
	}
	
	proc parseBlockComment {raw} {
		global commentBuffer
		
		set ret ""
		foreach line [split $raw \n] {
			if {$commentBuffer != "" || [regexp -- $xmacro::E(comment) $line]} {
				getBlock $line {\{} {\}} commentBuffer
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
			set pattern ""
			set vars [list]
			set patterndef [string range $macrodef 6 [expr {$n-1}]]
			foreach {match p sep} [regexp -inline -all -- $xmacro::E(vars) $patterndef] {
				if {[regexp -- {^\$} $p]} {
					lappend vars $p
					append pattern {([\w\$]+)}
				} else {
					append pattern $p
				}
				set sep [regsub -all -- $xmacro::E(rechars) $sep {\\&}]
				set sep [regsub -all -- {\\\.\\\.} $sep {\s*}]
				append pattern $sep
			}
			set pattern [string trim $pattern]
			set pattern [regsub -all -- {\s+} $pattern {[ \t]+}]
			lappend macros [list $pattern $vars $body]
		} else {
			error "Empty body in macro:\n\t$macrodef"
		}
	}
	
	proc exprcond {vars vals value condition} {
		global defines types
		
		if {[regexp -- {(\S+)\s+(\S+)} $condition -> cond param]} {
			array set v {}
			foreach x $vars y $vals {
				set v($x) $y
			}
			
			if {[info exists v($value)]} {
				set val $v($value)
			} elseif {[info exists defines($value)]} {
				set val $defines($value)
			} else {
				set val $value
			}
			
			switch -- $cond {
				is {
					if {$param == "not"} {
						regexp -- {(\S+)\s+not\s+(\S+)} $condition -> cond param
						if {$param == "defined"} {
							return [expr {1-[info exists defines($value)]}]
						} else {
							if {[info exists types($param)]} {
								return [regexp -- "^($param)\$" $val]
							} else {
								error "unknown type: $param"
							}
						}
					} else {
						if {$param == "defined"} {
							return [info exists defines($value)]
						} else {
							if {[info exists types($param)]} {
								return [regexp -- "^($param)\$" $val]
							} else {
								error "unknown type: $param"
							}
						}
					}
				}
				isnot {
					if {$param == "defined"} {
						return [expr {1-[info exists defines($value)]}]
					} else {
						return [expr {1-[string is $param -strict $val]}]
					}
				}
				default {
					if {[info exists v($param)]} {
						return [expr {$val} $cond {$v($param)}]
					} else {
						return [expr {$val} $cond {$param}]
					}
				}
			}
		}
		return 0
	}
	
	proc while..if {thelist command true {else ""} {false ""}} {
		upvar 1 $thelist ls
		regsub -all -- {^(\s*)continue(\s*)$} $true {\1return -code continue} true
		regsub -all -- {^(\s*)continue(\s*)$} $false {\1return -code continue} false
		regsub -all -- {^(\s*)break(\s*)$} $true {\1return -code break} true
		regsub -all -- {^(\s*)break(\s*)$} $false {\1return -code break} false
		
		if {[uplevel 1 $command] != 0} {
			while {[llength $ls]} {
				uplevel 1 $true
			}
		} elseif {$else == "while..else"} {
			while {[llength $ls]} {
				uplevel 1 $false
			}
		} elseif {$else == "else"} {
			uplevel 1 $false
		}
	}
	
	
	proc getIf {vars vals value condition rawvar} {
		upvar 1 $rawvar raw
		
		array set v {}
		foreach x $vars y $vals {
			set v($x) $y
		}
		
		set ret ""
		while..if raw {exprcond $vars $vals $value $condition} {
			set line [shift raw]
			
			if {[regexp -- $xmacro::E(if) $line -> var cond]} {
				append ret [getIf $vars $vals $var $cond raw]
			} else {
				# ignore until @endif
				if {[regexp -- $xmacro::E(else) $line]} {
					while {[llength $raw]} {
						set line [shift raw]
						if {[regexp -- $xmacro::E(if) $line -> var cond]} {
							getIf $vars $vals {} {} raw
						}
						if {[regexp -- $xmacro::E(endif) $line]} {
							return $ret
						}
					}
				}
				if {[regexp -- $xmacro::E(endif) $line]} {
					return $ret
				}
				
				set line [parseDefine $line]
				append ret "$line\n"
			}
		} while..else {
			set line [shift raw]
			# ignore:
			while..if raw {regexp -- $xmacro::E(if) $line} {
				set line [shift raw]
				if {[regexp -- $xmacro::E(if) $line -> var cond]} {
					getIf $vars $vals {} {} raw
				}
				if {[regexp -- $xmacro::E(endif) $line]} {
					set line [shift raw]
					break
				}
			}
			if {[regexp -- $xmacro::E(else) $line]} {
				if {[regexp -- $xmacro::E(elseif) $line -> var cond]} {
					while..if raw {exprcond $vars $vals $var $cond} {
						# add from here to @endif or @else
						set line [shift raw]
						
						if {[regexp -- $xmacro::E(if) $line -> var cond]} {
							append ret [getIf $vars $vals $var $cond raw]
						} else {
							# ignore from @else to end:
							while..if raw {regexp -- $xmacro::E(else) $line} {
								set line [shift raw]
								if {[regexp -- $xmacro::E(if) $line -> var cond]} {
									getIf $vars $vals {} {} raw
								}
								if {[regexp -- $xmacro::E(endif) $line]} {
									return $ret
								}
							}
							if {[regexp -- $xmacro::E(endif) $line]} {
								return $ret
							}
							
							set line [parseDefine $line]
							append ret "$line\n"
						}
					} else {
						continue
					}
				} else {
					# add from @else to @endif
					while {[llength $raw]} {
						set line [shift raw]
						
						if {[regexp -- $xmacro::E(if) $line -> var cond]} {
							append ret [getIf $vars $vals $var $cond raw]
						} else {						
							if {[regexp -- $xmacro::E(endif) $line]} {
								return $ret
							}
							
							set line [parseDefine $line]
							append ret "$line\n"
						}
					}
				}
			}
			if {[string trim $line] == "@endif"} {
				return $ret
			}
		}
		return $ret
	}
	
	# Process macro conditionals:
	proc trimIf {vars vals raw} {
		array set v {}
		foreach x $vars y $vals {
			set v($x) $y
		}
		
		set raw [split $raw \n]
		set ret ""
		while {[llength $raw]} {
			set line [shift raw]
			
			if {[regexp -- $xmacro::E(if) $line -> var cond]} {
				append ret [getIf $vars $vals $var $cond raw]
			} else {
				if {
					[string trim $line] != "@endif" &&
					[string trim $line] != "@else"
				} {
					set line [parseDefine $line]
					append ret "$line\n"
				}
			}
		}
		return $ret
	}

	proc byKeyLength {a b} {
		expr {[llength [lindex $a 0]]-[llength [lindex $b 0]]}
	}

	# Replaces macros in regular code:
	proc substMacros {raw {stage final}} {
		global macros magic magiclist
		
		set ret ""
		foreach line [split $raw \n] {
		# Substitute macros until done:
			set done 0
			while {!$done} {
				set done 1
				foreach x $macros {
					set pattern [lindex $x 0]
					set vars [lindex $x 1]
					set body [lindex $x 2]
					
					# Process scope magic on macro body before insertion:
					lappend magiclist [incr magic]
					set body [scopeMagic $body {$$_}]
					set magiclist [lrange $magiclist 0 end-1]
					
					set match [regexp -inline -- $pattern $line]
					if {$match != ""} {
						set done 0
						set vals [lrange $match 1 end]
						set match [lindex $match 0]
						set map [list]
						
						# Variable substitution:
						set sub [trimIf $vars $vals $body]
						foreach x $vars y $vals {
							set x "\\$x\(\\W|\$\)"
							set y "$y\\1"
							
							set sub [regsub -all -- $x $sub $y]
						}
						set line [regsub -- "(?q)$match" $line $sub]
					}
				}
			}
			set line [parseDefine $line]
			append ret "$line\n"
		}
		
		return $ret
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
	proc stripComments {varname} {
		upvar 1 $varname raw
		
		set ret ""
		foreach comment {
			{\s*#.*$} {\/\/.*$}
		} {
			set raw [regsub -- $comment $raw {}]
		}
		# Special processing of assembly compatible comments:
		if {[regexp -- {;.*$} $raw match]} {
			set raw [regsub -- "(?q)$match" $raw {}]
			set ret $match
		}
		return $ret
	}

	proc parseLine {line} {
		set line [parseBlockComment $line]
		set quote [parseQuote line]
		set comment [stripComments line]
		set line [parseMacro $line]
		set line [parseIf $line]
		set line [substMacros $line]
		set line [scopeMagic $line]
		set line [parseDefine $line]
		set line [substDefines $line]
		join [list $comment $quote $line] "\n"
	}

	proc parse {var fname script} {
		upvar 1 $var line
		set i 1
		
		eachline line $fname {
			if {[catch {parseLine $line} line]} {
				error "$fname, line $i: $line"
			}
			
			# Handle includes here:
			set temp [split $line \n]
			set line [list]
			foreach n $temp {
				if {[regexp -- $xmacro::E(include) $n -> incfile]} {
					set incfile [string trim $incfile]
					set n [uplevel 1 [list xmacro::parse n $incfile $script]]
				}
				append line "$n\n"
			}
			
			foreach line [split $line \n] {
				if {[string trim $line] != ""} {
					if {[catch {uplevel 1 $script} line]} {
						error "$fname, line $i: $line"
					}
				}
			}
			incr i
		}
	}
}
