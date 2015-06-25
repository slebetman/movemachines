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
