#! /usr/bin/env wish

################################################
# M516 simulator
################################################

wm geometry . 610x410
wm minsize . 610 410

set maxRam 0x0200
set instruction ""
set speedHz "-"
set hzCount 0

array set regAction {}
array set memAction {}

array set register {
	pc  0x0000
	acu 0x0000
	ret 0x0000
	*a   0x0000
	a    0x0000
	+a   0x0000
	-a   0x0000
	*b   0x0000
	b    0x0000
	+b   0x0000
	-b   0x0000
	*m   0x0000
	conf 0x0000
	carry 0
}

# Enable TINY support but disable banking:
set register(conf) 0x0001

for {set x 0} {$x < 32} {incr x} {
	set register(m$x) 0x0000
}

################################################# Ram

proc newRam {} {
	global ram
	global maxRam
	set ram ""
	for {set x 0} {$x < $maxRam} {incr x} {
		lappend ram [format "%04x: " $x]0x0000
	}
	.f.f.l selection set 0
}

proc loadFile {fname} {
	global ram
	set f [open $fname]
	while {[eof $f] == 0} {
		set val [string trim [gets $f]]
		set x [string first ";" $val]
		if {$x != -1} {
			set val [string trim [string range $val 0 [expr {$x-1}]]]
		}
		set x [string first "#" $val]
		if {$x != -1} {
			set val [string trim [string range $val 0 [expr {$x-1}]]]
		}
		if {$val != ""} {
			setValue [lindex $val 0] [lindex $val 1]
		}
	}
	close $f
}

proc loadRam {} {
	newRam
	mergeRam
}

proc mergeRam {} {
	set fname [tk_getOpenFile -filetypes {
		{"M516 RAM Description" {.516 .ram}}
		{"Text File" .txt}
		{"All Files" *}
	} -defaultextension .516]
	if {$fname != {}} {
		loadFile $fname
	}
}

################################################# GUI

proc makeGUI {} {
	global ram
	pack [frame .b] -fill x -side bottom
	pack [button .b.stop -command stopSim \
		-text {Stop (F8)} -width 10] -side right
	pack [button .b.pause -command pauseSim \
		-text {Pause (F7)} -width 10] -side right
	pack [button .b.step -command stepSim \
		-text {Step (F6)} -width 10] -side right
	pack [button .b.start -command startSim \
		-text {Start (F5)} -width 10] -side right
	pack [frame .f -relief groove -bd 2] -fill y -side left
	pack [frame .f.f] -fill both -expand 1 -side bottom
	pack [label .f.ram -text "RAM"] -side left -expand 1
	pack [button .f.ld -text "Load" -command {loadRam}] -side right
	pack [listbox .f.f.l -yscrollcommand {.f.f.s set} -width 13 \
		-font {Courier 8} -listvariable ram -selectmode single] \
		-fill both -side left
	pack [scrollbar .f.f.s -orient vertical -command {.f.f.l yview}] \
		-fill y -side right
	pack [canvas .c] -fill both -side right -expand 1
	
	makeCDisplay
	makeMenu
	
	bind . <KeyPress> {handleKey %K}
}

proc makeCDisplay {} {	
	# address bus ###########
	.c create text {15 10} -text "Address Bus" -anchor w
	.c create line {
		5 20
		120 20
		120 40
	} -width 4 -arrow first -joinstyle miter
	
	# int data bus ##########
	.c create text {15 150} -text "Internal Data Bus" -anchor w
	.c create line {
		68 160
		440 160
	} -width 4
	
	# data bus ##############
	.c create text {15 350} -text "Data Bus" -anchor w
	.c create line {
		5 360
		480 360
	} -width 4 -arrow both -joinstyle miter
	
	# ALU ###################
	.c create rectangle {300 6 400 90} -fill white
	.c create text {320 16} -text "ALU"
	set yy 30
	foreach {x y} {one/add 01 nil/sub 02 all/and 03 rsh/or 04 inv/xor 28} {
		.c create text 390 $yy -text "$x:$y" -anchor e \
			-font {Courier 8}
		incr yy 10
	}
	
	.c create line {
		375 90
		375 160
	} -arrow first
	label .c.acu -textvariable register(acu) \
		-bg white -font {Courier 8} -width 6 -relief sunken
	.c create window {310 135} -window .c.acu -anchor sw
	.c create text {308 130} -text "acu:00" -anchor se \
		-font {Courier 8}
	.c create line {
		335 90
		335 115
	} -arrow last
	.c create line {
		335 135
		335 160
	} -arrow both
	
	radiobutton .c.carry -variable register(carry) \
		-state disabled -value 1
	.c create window {440 130} -window .c.carry -anchor e
	.c create text {440 130} -text "carry" -anchor w \
		-font {Courier 8}
	
	# address control #######
	set yy 114
	foreach {x y} {*m 33 *b 2c *a 05 pc 2f} {
		label .c.$x -textvariable register($x) \
			-bg white -font {Courier 8} -width 6 -relief sunken
		.c create window 96 $yy -window .c.$x -anchor sw
		.c create text 94 [expr {$yy-5}] -text "$x:$y" -anchor se \
			-font {Courier 8}
		incr yy -21
	}
	.c create line {
		120 114
		120 160
	} -arrow both
	incr yy 84
	label .c.ret -textvariable register(ret) \
		-bg white -font {Courier 8} -width 6 -relief sunken
	.c create window 200 $yy -window .c.ret -anchor sw
	.c create text 198 [expr {$yy-5}] -text "ret:32" -anchor se \
		-font {Courier 8}
	.c create line \
		215 $yy \
		215 160 \
		-arrow both
	.c create line \
		140 [expr {$yy-74}] \
		215 [expr {$yy-74}] \
		215 [expr {$yy-21}] \
		-arrow last
	
	# data ##################
	set yy 185
	foreach {x y} {+a {+ } a 06 -a {- } +b {+ } b 25 -b {- }} {
		label .c.$x -textvariable register($x) \
			-bg white -font {Courier 8} -width 6 -relief sunken
		.c create window 95 $yy -window .c.$x -anchor nw
		.c create text 93 [expr {$yy+5}] -text "[string trim $x +-]:$y" \
			-anchor ne -font {Courier 8}
		incr yy 21
	}
	.c create line {
		120 185
		120 160
	} -arrow both
	.c create line \
		120 $yy \
		120 360 \
		-arrow both
	
	# ram windows ###########
	set xx 170
	foreach {add range} {08 0 10 8 18 16 20 24} {
	set yy 185
		
		.c create text [expr {$xx-2}] [expr {$yy-2}] -text "$add" -anchor sw \
			-font {Courier 8}
		
	for {set y 0} {$y < 8} {incr y} {
			set reg m[expr {$y+$range}]
		label .c.$reg -textvariable register($reg) -bg white \
			-padx 0 -pady 0 -width 6 -font {Courier 8} -relief sunken
		.c create window $xx $yy -window .c.$reg -anchor nw
		.c create text [expr {$xx-3}] [expr {$yy+5}] \
				-text $reg -anchor ne
		incr yy 19
	}
	.c create line \
		[expr {$xx+25}] 185 \
		[expr {$xx+25}] 160 \
		-arrow both
	.c create line \
		[expr {$xx+25}] $yy \
		[expr {$xx+25}] 360 \
		-arrow both
	
		incr xx 76
	}
	
	label .c.instruction -textvariable instruction \
		-font {Courier 8} -width 20
	.c create window 130 0 -window .c.instruction -anchor nw
	
	label .c.speed -textvariable speedHz \
		-font {Courier 8} -width 20
	.c create window 130 16 -window .c.speed -anchor nw
	
	# Color registers accessible from packed insturction:
	foreach x [winfo children .c] {
		set xx [lindex [split $x .] end]
		puts $xx
		if {[lsearch -exact {
			acu *a a +a -a
			m0 m1 m2 m3 m4 m5 m6 m7
		} $xx] != -1} {
			$x configure -bg #ffffcc
		}
	}
}

proc makeMenu {} {
	menu .mtop -tearoff 0
	.mtop add cascade -label "File" -menu .file
	.mtop add cascade -label "Simulate" -menu .sim
	menu .sim -tearoff 0
	.sim add command -label "Start Simulation" -command {startSim}
	.sim add command -label "Reset Simulation" -command {stopSim}
	.sim add separator
	.sim add command -label "Load Device" -command {loadDeviceFile}
	.sim add cascade -label "Unload Device" -menu .dev
	menu .file -tearoff 0
	.file add command -label "Clear Ram" -command {newRam}
	.file add command -label "Load New Ram.." -command {loadRam}
	.file add command -label "Merge Load Ram.." -command {mergeRam}
	#.file add command -label "Save Ram As.." -command {} -state disabled
	.file add separator
	.file add command -label "Load Script.." -command {loadScript}
	.file add separator
	.file add command -label "Exit" -command {exit}
	menu .dev -tearoff 0
	
	. configure -menu .mtop
}

proc devMenu {} {
	global devices
	.dev delete 0 end
	foreach {dev name} [array get devices "*.name"] {
		set dev [lindex [split $dev "."] 0]
		.dev add command -label $name -command $devices($dev.kill)
	}
}

################################################# RAM Editor

proc isComplete {sel thisRam} {
	global ram
	if {[string match "0x*" [lindex $thisRam 1]]} {
		return 1
	}
	return 0
}

proc complete {sel thisRam} {
	global ram
	if {[isComplete $sel $thisRam] == 0} {
		set val 0x0[lindex $thisRam 1]
		set thisRam [lreplace $thisRam 1 1 [format "0x%04x" $val]]
		set ram [lreplace $ram $sel $sel $thisRam]
	}
}

proc typeValue {sel val thisRam} {
	global ram
	set thisVal [lindex $thisRam 1]
	if {[isComplete $sel $thisRam]} {
		set thisRam [lreplace $thisRam 1 1 $val]
	} elseif {[string length $thisVal] < 4} {
		append thisVal $val
		set thisRam [lreplace $thisRam 1 1 $thisVal]
	}
	set ram [lreplace $ram $sel $sel $thisRam]
	update
}

proc deleteVal {sel thisRam} {
	global ram
	set thisVal [lindex $thisRam 1]
	if {[isComplete $sel $thisRam]} {
		set thisRam [lreplace $thisRam 1 1 {}]
	} elseif {[string length $thisVal] < 4} {
		set thisVal [string range $thisVal 0 end-1]
		set thisRam [lreplace $thisRam 1 1 $thisVal]
	}
	set ram [lreplace $ram $sel $sel $thisRam]
	update
}

proc handleKey {ksym} {
	global register
	global ram
	global maxRam
	
	set sel [.f.f.l curselection]
	set thisRam [lindex $ram $sel]
	switch -exact -- $ksym {
		"Up" {
			complete $sel $thisRam
			if {$sel > 0} {
				incr sel -1
				.f.f.l selection clear 0 end
				.f.f.l selection set $sel
			}
			.f.f.l see $sel
		}
		"Down" {
			complete $sel $thisRam
			if {$sel < [expr {$maxRam-1}]} {
				incr sel
				.f.f.l selection clear 0 end
				.f.f.l selection set $sel
			}
			.f.f.l see $sel
		}
		"Return" {
			complete $sel $thisRam
		}
		"BackSpace" {
			deleteVal $sel $thisRam
		}
		"F5" startSim
		"F6" stepSim
		"F7" pauseSim
		"F8" stopSim
		default {
			if {[string length $ksym] == 1 &&
				[string is xdigit $ksym]
			} {
				typeValue $sel $ksym $thisRam
			}
		}
	}
}

makeGUI
newRam

focus -force .

################################################# Behaviour

proc setValue {sel val} {
	global ram
	set thisRam [lindex $ram $sel]
	set thisRam [lreplace $thisRam 1 1 [format "0x%04x" $val]]
	set ram [lreplace $ram $sel $sel $thisRam]
	checkRam $sel
}

proc getValue {sel} {
	global ram
	return [lindex [lindex $ram $sel] 1]
}

proc checkRam {sel} {
	global register
	global ram
	#global maxRam
	
	set val [format "0x%04x" [readMem $sel]]
	if {[expr {$sel & 0xffe0}] == $register(*m)} {
		set cell [expr {$sel & 0x0007}]
		set register(m$cell) $val
	}
	
	#set psel [expr {($sel-1) % $maxRam}]
	#set nsel [expr {($sel+1) % $maxRam}]
	set psel [expr {$sel-1}]
	set nsel [expr {$sel+1}]
	foreach s [list $sel $psel $nsel] {
		set p [expr {$s-1}]
		set n [expr {$s+1}]
		set pval [format "0x%04x" [readMem $p]]
		set nval [format "0x%04x" [readMem $n]]
		if {$s == $register(*a)} {
			set register(-a) $pval
			set register(a)  $val
			set register(+a) $nval
		}
		if {$s == $register(*b)} {
			set register(-b) $pval
			set register(b)  $val
			set register(+b) $nval
		}
	}
}

proc writeWindow {cell val} {
	global register
	
	set sel [expr {$register(*m) | $cell}]
	writeMem $sel $val 0
}

proc switchWindow {val} {
	global register
	global ram
	
	set val [format "0x%04x" [expr {$val & 0xffe0}]]
	set register(*m) $val
	for {set x 0} {$x < 32} {incr x} {
		set sel [expr {$val + $x}]
		set register(m$x) [readMem $sel]
	}
}

proc writeStack {stack val} {
	global register
	
	set sel $register($stack)
	writeMem $sel $val 0
	regincr $stack
	checkRam $sel
}

proc readStack {stack} {
	global register
	global ram
	
	regincr $stack -1
	set sel $register($stack)
	set val [readMem $sel]
	set register($stack) [format "0x%04x" $register($stack)]
	checkRam $sel
	return $val
}

proc pointStack {stack val} {
	global register
	
	set register($stack) [format "0x%04x" $val]
	checkRam $val
}

proc regincr {reg {val 1}} {
	global register
	#global maxRam
	incr register($reg) $val
	#set register($reg) [format "0x%04x" [expr {$register($reg) % $maxRam}]]
	set register($reg) [format "0x%04x" [expr {$register($reg) % 65536}]]
}

################################################# Device handlers

proc attachRegHandler {address readproc writeproc} {
	global regAction
	set regAction([expr {$address}]) [list $readproc $writeproc]
}

proc detachRegHandler {address} {
	global regAction
	if {[info exists regAction([expr {$address}])]} {
		unset regAction([expr {$address}])
	}
}

proc attachRamHandler {address readproc writeproc} {
	global memAction
	set memAction([expr {$address}]) [list $readproc $writeproc]
}

proc detachRamHandler {address} {
	global memAction
	if {[info exists memAction([expr {$address}])]} {
		unset memAction([expr {$address}])
	}
}

proc writeReg {address val} {
	global regAction
	set address [expr {$address}]
	
	if {[info exists regAction($address)]} {
		eval [lindex $regAction($address) 1] $val
	}
}

proc readReg {address} {
	global regAction
	set address [expr {$address}]
	if {[info exists regAction($address)]} {
		set x [lindex $regAction($address) 0]
		if {$x != "nothing"} {
			return [eval $x]
		}
	}
	return 0xffff
}

proc writeMem {address val mode} {
	global memAction maxRam
	set address [expr {$address}]
	
	# A note on modes:
	# -------------------------------
	# 0 = full width 16 bit move
	# 1 = upper 8 bit to lower
	# 2 = lower 8 bit to upper
	# 3 = lower 8 bit
	
	if {$mode != 0} {
		set thisVal [readMem $address]
		if {$mode == 1} {
			set val [expr {$val | ($thisVal & 0xff00)}]
		} elseif {$mode == 2} {
			set val [expr {$val | ($thisVal & 0x00ff)}]
		} elseif {$mode == 3} {
			set val [expr {$val | ($thisVal & 0xff00)}]
		}
	}
	
	if {[info exists memAction($address)]} {
		eval [lindex $memAction($address) 1] $val $mode
	} elseif {$address < $maxRam} {
		setValue $address $val
	}
}

proc readMem {address} {
	global memAction
	set address [expr {$address}]
	if {[info exists memAction($address)]} {
		set x [lindex $memAction($address) 0]
		if {$x != "nothing"} {
			return [eval $x]
		}
	}
	set ret [getValue $address]
	if {$ret == ""} {set ret 0x0000}
	return $ret
}

################################################# Devices

proc basicDevs {} {
	proc nothing {args} {}
	proc R {reg} {
		global register; return $register($reg)
	}
	proc R~ {ptr} {
		global register
		set sel $register($ptr)
		checkRam $sel
		return [readMem $sel]
	}
	proc W {reg val} {
		global register; set register($reg) [format "0x%04x" $val]
	}
	proc R+ {ptr} {
		global register
		set sel $register($ptr)
		set ret [readMem $sel]
		regincr $ptr
		set sel $register($ptr)
		checkRam $sel
		return $ret
	}
	proc R- {ptr} {
		global register
		set sel $register($ptr)
		set ret [readMem $sel]
		regincr $ptr -1
		set sel $register($ptr)
		checkRam $sel
		return $ret
	}
	proc +W {reg val} {
		global register
		regincr $reg
		set sel $register($reg)
		writeMem $sel $val 0
		checkRam $sel
	}
	proc -W {reg val} {
		global register
		regincr $reg -1
		set sel $register($reg)
		writeMem $sel $val 0
		checkRam $sel
	}
	proc W~ {reg val} {
		global register
		set sel $register($reg)
		writeMem $sel $val 0
		checkRam $sel
	}
	proc Wlow {ptr val} {
		global register
		set val [expr {$val&0x00ff}]
		set sel $register($ptr)
		writeMem $sel $val 3
		checkRam $sel
	}
	proc Whigh {ptr val} {
		global register
		set val [expr {($val<<8)&0xff00}]
		set sel $register($ptr)
		writeMem $sel $val 2
		checkRam $sel
	}
	proc Rlow {ptr} {
		global register
		set sel $register($ptr)
		set val [readMem $sel]
		return [format "0x%04x" [expr {$val&0x00ff}]]
	}
	proc Rhigh {ptr} {
		global register
		set sel $register($ptr)
		set val [readMem $sel]
		return [format "0x%04x" [expr {($val>>8)&0xff}]]
	}
	proc lit {} {
		global register
		set sel $register(pc)
		regincr pc
		showInst
		return [readMem $sel]
	}
	proc call {cond val} {
		global register
		switch -exact -- $cond {
			zero  {if {$register(acu)   != 0} return}
			carry {if {$register(carry) == 0} return}
		}
		set register(ret) $register(pc)
		set register(pc) $val
	}
	proc one {} {
		return "0x0001"
	}
	proc nil {} {
		return "0x0000"
	}
	proc all {} {
		return "0xffff"
	}
	proc add {val} {
		global register
		set register(acu) [expr {$register(acu) + $val}]
		set register(carry) [expr {($register(acu) >> 16) & 1}]
		set register(acu) [format "0x%04x" [expr {$register(acu) & 0xffff}]]
	}
	proc sub {val} {
		global register
		set register(acu) [expr {$register(acu) - $val}]
		set register(carry) [expr {($register(acu) >> 16) & 1}]
		set register(acu) [format "0x%04x" [expr {$register(acu) & 0xffff}]]
	}
	proc rsh {} {
		global register
		return [format "0x%04x" [expr {$register(acu) >> 1}]]
	}
	proc inv {} {
		global register
		return [format "0x%04x" [expr {~$register(acu)}]]
	}
	proc and {val} {
		global register
		set register(acu) [format "0x%04x" [expr {$register(acu) & $val}]]
	}
	proc or {val} {
		global register
		set register(acu) [format "0x%04x" [expr {$register(acu) | $val}]]
	}
	proc xor {val} {
		global register
		set register(acu) [format "0x%04x" [expr {$register(acu) ^ $val}]]
	}
	proc stdW {val} {
		global register
		set sel $register(stp)
		writeMem $sel $val 0
	}
}
basicDevs

proc devHandlers {} {
	attachRegHandler  0x00 {R acu} {W acu}
	attachRegHandler  0x01 {one} {add}
	attachRegHandler  0x02 {nil} {sub}
	attachRegHandler  0x03 {all} {and}
	attachRegHandler  0x04 {rsh} {or}
	attachRegHandler  0x05 {R *a} {pointStack *a}
	attachRegHandler  0x06 {R~ *a} {W~ *a}
	attachRegHandler  0x07 {R- *a} {+W *a}
	
	for {set x 0} {$x < 32} {incr x} {
		attachRegHandler [expr {$x+8}] "R m$x" "writeWindow $x"
	}
	attachRegHandler 0x28 {inv} {xor}
	attachRegHandler 0x29 {R+ *a} {-W *a}
	attachRegHandler 0x2a {Rhigh *a} {Whigh *a}
	attachRegHandler 0x2b {Rlow *a} {Wlow *a}
	attachRegHandler 0x2c {R *b} {pointStack *b}
	attachRegHandler 0x2d {R~ *b} {W~ *b}
	attachRegHandler 0x2e {R- *b} {+W *b}
	attachRegHandler 0x2f {R pc} {call always}
	attachRegHandler 0x30 {lit} {call zero}
	attachRegHandler 0x31 {R conf} {call carry}
	attachRegHandler 0x32 {R ret} {W ret}
	attachRegHandler 0x33 {R *m} {switchWindow}
	attachRegHandler 0x34 {nothing} {nothing}
	attachRegHandler 0x35 {nothing} {nothing}
	
	for {set x 54} {$x < 128} {incr x} {
		attachRegHandler $x {nothing} {nothing}
	}
}
devHandlers

################################################# Simulate

proc updateHz {} {
	global hzCount
	global speedHz
	
	set hz [expr {double($hzCount)}]
	
	if {$hz < 1000} {
		set speedHz "$hz Hz"
	} elseif {$hz < 1000000} {
		set speedHz "[expr $hz/1000] kHz"
	} else {
		set speedHz "[expr $hz/1000000] MHz"
	}
	
	set hzCount 0
	
	after 1000 updateHz
}

updateHz

set sim 0
proc startSim {} {
	global sim
	if {$sim} return
	
	global register
	set sim 1
	checkRam $register(*a)
	checkRam $register(*b)
	switchWindow $register(*m)
	simUpdate
}

proc stopSim {} {
	global sim
	global register
	set sim 0
	after 100 {
		global register
		foreach x [array names register] {
			set register($x) 0x0000
		}
		.f.f.l selection clear 0 end
		.f.f.l selection set $register(pc)
		.f.f.l see $register(pc)
		printAsm
		update
	}
}

proc pauseSim {} {
	global sim
	set sim 0
}

proc stepSim {} {
	global sim
	global register
	set sim 0
	checkRam $register(*a)
	checkRam $register(*b)
	switchWindow $register(*m)
	simUpdate
}

proc showInst {} {
	global register
	.f.f.l selection clear 0 end
	.f.f.l selection set $register(pc)
	.f.f.l see $register(pc)
}

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

for {set i 0} {$i < [llength $wreg]} {incr i} {
	set asmW($i) [lindex $wreg $i]
}

for {set i 0} {$i < [llength $rreg]} {incr i} {
	set asmR($i) [lindex $rreg $i]
}

set asmR() {}

proc disasm {dst src {lit ""}} {
	global instruction asmR asmW
	set instruction "$asmW($dst) = $asmR($src) $lit"
}

proc disasmPacked {dst src dst2 src2} {
	global instruction asmR asmW asmM asmC
	set instruction "$asmW($dst) = $asmR($src); $asmW($dst2) = $asmR($src2)"
}

proc decode {inst body} {
	global asmR register
	foreach {
		arg16     script16
		argshort  scriptshort
		argpacked scriptpacked
	} $body break
	
	set type [expr {$inst & 0x8000}]
	if {$type == 0} {
		set type [expr {$inst & 0x4000}]
		if {$type == 0} {
			# 16bit instruction:
			set [lindex $arg16 0] [expr {($inst >> 7) & 0x7f}]
			set [lindex $arg16 1] [expr {$inst & 0x7f}]
			eval $script16
		} else {
			# Short literal:
			set [lindex $argshort 0] [expr {($inst >> 12) & 0x03}]
			set [lindex $argshort 1] [expr {$inst & 0x0fff}]
			eval $scriptshort
		}
	} else {
		# 8bit packed instruction:
		set [lindex $argpacked 0] [expr {($inst >> 12) & 0x7}]
		set [lindex $argpacked 1] [expr {($inst >> 8) & 0xf}]
		set [lindex $argpacked 2] [expr {($inst >> 4) & 0xf}]
		set [lindex $argpacked 3] [expr {$inst & 0xf}]
		eval $scriptpacked
	}
}

proc printAsm {} {
	global register instruction
	
	set inst [readMem $register(pc)]
	
	if {$inst != 0} {
		decode $inst {
			{dst src} {
				if {$asmR($src) == "lit"} {
					disasm $dst $src \
						[readMem [expr {$register(pc)+1}]]
				} else {
					disasm $dst $src
				}
			}
			{dst sval} {
				disasm $dst {} "lit; $sval"
			}
			{dst src dst2 src2} {
				disasmPacked $dst $src $dst2 $src2
			}
		}
	} else {
		set instruction "no op"
	}
}

proc simUpdate {{unroll 0}} [string map {%EXEC% {
	incr hzCount
	set inst [readMem $register(pc)]
	regincr pc
	
	# single step nop support:
	if {$inst != 0} {
		decode $inst {
			{dst src} {
				writeReg $dst [readReg $src]
			}
			{dst sval} {
				writeReg $dst $sval
			}
			{dst src dst2 src2} {
				writeReg $dst [readReg $src]
				writeReg $dst2 [readReg $src2]
			}
		}
	}
}} {
	global register
	global sim
	global asmR
	global hzCount
	
	%EXEC%
	
	# Disassemble next insturction:
	if {$unroll == 0} {
		printAsm
	}
	
	if {$sim} {
		# Event unrolling. Enter the event loop once every N instruction
		# cycle. This significantly speeds up simulation but increases the
		# granularity of event processing.
		if {$unroll == 0} {
			for {set N 0} {$N < 40 && $sim} {incr N} {
				simUpdate 1
				%EXEC%		
			}
			after 1 simUpdate
		}
		showInst
	} else {
		showInst
	}
}]

################################################# External Device Loading

proc device {name description proclist} {
	global devices
	set devices($name.name) $description
	foreach {null procname varlist body} $proclist {
		if {$procname == "init"} {
			set init $body
		} elseif {$procname == "kill"} {
			set devices($name.kill) $body
		} else {
			lappend devices($name.procs) $procname
			proc $procname $varlist $body
		}
	}
	eval $init
}

proc processAttachRamDevice {name params values} {
	global ramDevice
	global devices
	set ret ""
	global n
	set n 0
	set do_dialog 0
	set t [toplevel .attachRamDevice]
	pack [label $t.l -text "Attach $name device to:"]
	foreach {txt r w} $params v $values {
		if {$v == ""} {
			set do_dialog 1
			pack [frame $t.$n] -fill x
			pack [label $t.$n.l -text $txt] -side left
			pack [entry $t.$n.e -width 9] -side right -textvariable ramDevice($n)] -side right
		} else {
			set ramDevice($n) $v
		}
		incr n
	}
	if {$do_dialog} {
		pack [frame $t.btn] -fill x
		pack [button $t.btn.cancel -command {set n 0} \
			-text "Cancel" -width 6] -expand 1 -fill x -side left
		pack [button $t.btn.ok -command {set n 1} \
			-text "OK" -width 6] -expand 1 -fill x -side right
		wm protocol $t WM_DELETE_WINDOW {global n; set n 0}
		update
		vwait n
	} else {
		set n 1
	}
	destroy $t
	if {$n == 1} {
		foreach x [array names ramDevice] {txt r w} $params {
			lappend devices($name) $ramDevice($x)
			attachRamHandler $ramDevice($x) $r $w
		}
		set ret 1
		devMenu
	} else {
		set ret 0
	}
	array unset ramDevice
	unset n
	return $ret
}

proc detachRamDevice {name} {
	global devices
	foreach x $devices($name) {
		detachRamHandler $x
	}
	array unset devices $name*
	devMenu
}

proc loadDeviceFile {} {
	set dir devices
	if {![file isdirectory $dir]} {
		set dir .
	}
	set fname [tk_getOpenFile -filetypes {
		{"Device Description" .dev}
		{"Tcl Code" .tcl}
		{"All Files" *}
	} -defaultextension .dev -initialdir $dir]
	if {$fname != {}} {
		set f [open $fname]
		set test [read $f 8]
		close $f
		if {$test == "#mm16dev" ||
			$test == "#m416dev" ||
			$test == "#m516dev"
		} {
			proc attachRamDevice {name args} {
				return [processAttachRamDevice $name $args {}]
			}
			source $fname
		}
	}
}

proc loadDevice {fname args} {
	proc attachRamDevice {name args} [string map [list %args% $args] {
		return [processAttachRamDevice $name $args {%args%}]
	}]
	source $fname
}

proc loadScript {} {
	set fname [tk_getOpenFile -filetypes {
		{"System Set-up Script" {.sss .s}}
		{"Tcl File" .tcl}
		{"Text File" .txt}
		{"All Files" *}
	} -defaultextension .sss]
	if {$fname != {}} {
		set cdir [pwd]
		set xdir [file normalize [file dirname $fname]]
		set fname [file tail $fname]
		cd $xdir
		source $fname
		cd $cdir
	}
}


if {[file exists m516asm.tcl]} {
	# Requires that the m516asm.tcl file is in our working directory.
	proc assemble {src bin} {
		exec tclsh m516asm.tcl $src > $bin
	}
}

