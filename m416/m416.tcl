#! /usr/bin/env wish

################################################
# M416 simulator
################################################
wm geometry . 590x410
wm minsize . 590 410

set maxRam 0x1000
set instruction ""

array set regAction {}
array set memAction {}

array set register {
	pc  0x0000
	acu 0x0000
	psp 0x0000
	pst 0x0000
	stp 0x0000
	mp  0x0000
	ret 0x0000
	stk 0x0000
	std 0x0000
	carry 0
}

for {set x 0} {$x < 8} {incr x} {
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
		{"M416 RAM Description" {.416 .ram}}
		{"Text File" .txt}
		{"All Files" *}
	} -defaultextension .416]
	if {$fname != {}} {
		loadFile $fname
	}
}

################################################# GUI

proc uiFont {} {return {"DejaVu Sans Mono" 10}}

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
		-font [uiFont] -listvariable ram -selectmode single] \
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
		380 160
	} -width 4
	
	# data bus ##############
	.c create text {15 350} -text "Data Bus" -anchor w
	.c create line {
		5 360
		400 360
	} -width 4 -arrow both -joinstyle miter
	
	# ALU ###################
	.c create rectangle {280 16 380 90} -fill white
	.c create text {300 26} -text "ALU"
	set yy 40
	foreach {x y} {one/add 01 nil/and 02 all/or 03 rsh/xor 04} {
		.c create text 370 $yy -text "$x:$y" -anchor e \
			-font [uiFont]
		incr yy 10
	}
	
	.c create line {
		355 90
		355 160
	} -arrow first
	label .c.acu -textvariable register(acu) \
		-bg white -font [uiFont] -width 6 -relief sunken
	.c create window {290 135} -window .c.acu -anchor sw
	.c create text {288 130} -text "acu:00" -anchor se \
		-font [uiFont]
	.c create line {
		315 90
		315 115
	} -arrow last
	.c create line {
		315 135
		315 160
	} -arrow both
	
	radiobutton .c.carry -variable register(carry) \
		-state disabled -value 1
	.c create window {400 130} -window .c.carry -anchor e
	.c create text {400 130} -text "carry" -anchor w \
		-font [uiFont]
	
	# address control #######
	set yy 114
	foreach {x y} {psp 13 mp 15 stp 05 pc 11} {
		label .c.$x -textvariable register($x) \
			-bg white -font [uiFont] -width 6 -relief sunken
		.c create window 96 $yy -window .c.$x -anchor sw
		.c create text 94 [expr $yy - 5] -text "$x:$y" -anchor se \
			-font [uiFont]
		incr yy -21
	}
	.c create line {
		120 114
		120 160
	} -arrow both
	incr yy 84
	label .c.ret -textvariable register(ret) \
		-bg white -font [uiFont] -width 6 -relief sunken
	.c create window 200 $yy -window .c.ret -anchor sw
	.c create text 198 [expr $yy - 5] -text "ret:12" -anchor se \
		-font [uiFont]
	.c create line \
		215 $yy \
		215 160 \
		-arrow both
	.c create line \
		140 [expr $yy - 74] \
		215 [expr $yy - 74] \
		215 [expr $yy - 21] \
		-arrow last
	
	# data ##################
	set yy 185
	foreach {x y} {std 06 stk 07 pst 14} {
		label .c.$x -textvariable register($x) \
			-bg white -font [uiFont] -width 6 -relief sunken
		.c create window 95 $yy -window .c.$x -anchor nw
		.c create text 93 [expr $yy + 5] -text "$x:$y" -anchor ne \
			-font [uiFont]
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
	set xx 290
	set yy 185
	for {set y 0} {$y < 8} {incr y} {
		set reg m$y
		label .c.$reg -textvariable register($reg) -bg white \
			-padx 0 -pady 0 -width 6 -font [uiFont] -relief sunken
		.c create window $xx $yy -window .c.$reg -anchor nw
		.c create text [expr $xx-3] [expr $yy+5] \
			-text "m$y:[format %02x [expr $y+8]]" \
			-anchor ne -font [uiFont]
		incr yy 19
	}
	.c create line \
		[expr $xx+25] 185 \
		[expr $xx+25] 160 \
		-arrow both
	.c create line \
		[expr $xx+25] $yy \
		[expr $xx+25] 360 \
		-arrow both
	
	label .c.instruction -textvariable instruction \
		-font [uiFont] -width 20
	.c create window 130 0 -window .c.instruction -anchor nw
	
	# Color registers accessible from packed insturction:
	foreach x [winfo children .c] {
		set xx [lindex [split $x .] end]
		puts $xx
		if {[lsearch -exact {
			acu stp std stk
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
	if [string match "0x*" [lindex $thisRam 1]] {
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
	if [isComplete $sel $thisRam] {
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
	if [isComplete $sel $thisRam] {
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
			if {$sel < [expr {$maxRam -1}]} {
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
	if {[expr {$sel & 0xfff8}] == $register(mp)} {
		set cell [expr {$sel & 0x0007}]
		set register(m$cell) $val
	}
	
	#set psel [expr {($sel-1) % $maxRam}]
	#set nsel [expr {($sel+1) % $maxRam}]
	set psel [expr {$sel-1}]
	set nsel [expr {$sel+1}]
	set pval [format "0x%04x" [readMem $psel]]
	set nval [format "0x%04x" [readMem $nsel]]
	if {$sel == $register(stp)} {
		set register(stk) $pval
		set register(std) $val
	}
	if {$nsel == $register(stp)} {
		set register(stk) $val
		set register(std) $nval
	}
	if {$sel == $register(psp)} {
		set register(pst) $pval
	}
	if {$nsel == $register(psp)} {
		set register(pst) $val
	}
}

proc writeWindow {cell val {mode 0}} {
	global register
	
	set sel [expr {$register(mp) | $cell}]
	writeMem $sel $val $mode
}

proc switchWindow {val {mode 0}} {
	global register
	global ram
	#global maxRam
	
	#set val [format "0x%04x" [expr {($val & 0xfff8) % $maxRam}]]
	set val [format "0x%04x" [expr {$val & 0xfff8}]]
	set register(mp) $val
	for {set x 0} {$x < 8} {incr x} {
		set sel [expr {$val + $x}]
		set register(m$x) [readMem $sel]
	}
}

proc writeStack {stack val {mode 0}} {
	global register
	
	set sel $register($stack)
	writeMem $sel $val $mode
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

proc pointStack {stack val {mode 0}} {
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
	set regAction([expr $address]) [list $readproc $writeproc]
}

proc detachRegHandler {address} {
	global regAction
	if [info exists regAction([expr $address])] {
		unset regAction([expr $address])
	}
}

proc attachRamHandler {address readproc writeproc} {
	global memAction
	set memAction([expr $address]) [list $readproc $writeproc]
}

proc detachRamHandler {address} {
	global memAction
	if [info exists memAction([expr $address])] {
		unset memAction([expr $address])
	}
}

proc writeReg {address val {mode 0}} {
	global regAction
	set address [expr $address]
	
	if {$mode != 0} {
		if {$mode == 1} {
			set val [expr {($val >> 8) & 0x00ff}]
		} elseif {$mode == 2} {
			set val [expr {($val << 8) & 0xff00}]
		} elseif {$mode == 3} {
			set val [expr {$val & 0x00ff}]
		}
	}
	
	if [info exists regAction($address)] {
		eval [lindex $regAction($address) 1] $val $mode
	}
}

proc readReg {address} {
	global regAction
	set address [expr $address]
	if [info exists regAction($address)] {
		set x [lindex $regAction($address) 0]
		if {$x != "nothing"} {
			return [eval $x]
		}
	}
	return 0xffff
}

proc writeMem {address val mode} {
	global memAction
	set address [expr $address]
	
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
	
	if [info exists memAction($address)] {
		eval [lindex $memAction($address) 1] $val $mode
	} else {
		setValue $address $val
	}
}

proc readMem {address} {
	global memAction
	set address [expr $address]
	if [info exists memAction($address)] {
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
	proc W {reg val mode} {
		global register; set register($reg) [format "0x%04x" $val]
	}
	proc lit {} {
		global register
		set sel $register(pc)
		regincr pc
		showInst
		return [readMem $sel]
	}
	proc call {val mode} {
		global register
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
	proc add {val mode} {
		global register
		set register(acu) [expr {$register(acu) + $val}]
		set register(carry) [expr {($register(acu) >> 16) & 1}]
		set register(acu) [format "0x%04x" [expr {$register(acu) & 0xffff}]]
	}
	proc rsh {} {
		global register
		return [format "0x%04x" [expr {$register(acu) >> 1}]]
	}
	proc and {val mode} {
		global register
		set register(acu) [format "0x%04x" [expr {$register(acu) & $val}]]
	}
	proc or {val mode} {
		global register
		set register(acu) [format "0x%04x" [expr {$register(acu) | $val}]]
	}
	proc xor {val mode} {
		global register
		set register(acu) [format "0x%04x" [expr {$register(acu) ^ $val}]]
	}
    proc stdW {val mode} {
        global register
        set sel $register(stp)
        writeMem $sel $val $mode
    }
}
basicDevs

proc devHandlers {} {
    attachRegHandler  0 {R acu} {W acu}
    attachRegHandler  1 {one} {add}
    attachRegHandler  2 {nil} {and}
    attachRegHandler  3 {all} {or}
    attachRegHandler  4 {rsh} {xor}
    attachRegHandler  5 {R stp} {pointStack stp}
    attachRegHandler  6 {R std} {stdW}
    attachRegHandler  7 {readStack stp} {writeStack stp}
	
    for {set x 0} {$x < 8} {incr x} {
        attachRegHandler [expr $x+8] "R m$x" "writeWindow $x"
	}
	attachRegHandler 16 {lit} {nothing}
	attachRegHandler 17 {R pc} {call}
	attachRegHandler 18 {R ret} {W ret}
	attachRegHandler 19 {R psp} {pointStack psp}
    attachRegHandler 20 {readStack psp} {writeStack psp}
    attachRegHandler 21 {R mp} {switchWindow}
}
devHandlers

################################################# Simulate

set sim 0
proc startSim {} {
	global sim
	global register
	set sim 1
	checkRam $register(stp)
	checkRam $register(psp)
	switchWindow $register(mp)
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
	checkRam $register(stp)
	checkRam $register(psp)
	switchWindow $register(mp)
	simUpdate
}

proc showInst {} {
	global register
	.f.f.l selection clear 0 end
	.f.f.l selection set $register(pc)
	.f.f.l see $register(pc)
}

array set asmW {
	0 acu 1 add
	2 and 3 or
	4 xor 5 stp
	6 std 7 stk	
	8  m0 9 m1
	10 m2 11 m3
	12 m4 13 m5
	14 m6 15 m7	
	17 pc
	18 ret 19 psp
	20 pst 21 mp
}

array set asmR {
	0 acu 1 one
	2 nil 3 all
	4 rsh 5 stp
	6 std 7 stk	
	8  m0 9 m1
	10 m2 11 m3
	12 m4 13 m5
	14 m6 15 m7	
	16 lit 17 pc
	18 ret 19 psp
	20 pst 21 mp
}

array set asmM {
	0 "="
	1 "/"
	2 "\\"
	3 "-"
}

array set asmC {
	0 {}
	1 z
	2 nz
	3 c
	4 nc
	5 s
}

proc disasm {dst mode cond src {lit ""}} {
	global instruction asmR asmW asmM asmC
	set instruction "$asmW($dst) $asmC($cond)$asmM($mode) $asmR($src) $lit"
}

proc disasmPacked {dst src dst2 src2} {
	global instruction asmR asmW asmM asmC
	set instruction "$asmW($dst) = $asmR($src); $asmW($dst2) = $asmR($src2)"
}

proc simUpdate {{unroll 0}} {
	global register
	global sim
	global asmR
	
	set inst [readMem $register(pc)]
	regincr pc
	
	# single step nop support:
	if {$inst != 0} {
		set type [expr {$inst & 0x8000}]
		if {$type == 0} {
			# 16bit instruction:
			set dst [expr {($inst >> 8) & 0x1f}]
			set src [expr {$inst & 0x1f}]
			set mode [expr {($inst >> 13) & 0x3}]
			set cond [expr {($inst >>  5) & 0x7}]
			if {$cond == 5} {
				set sign [expr {$register(acu) & 0x8000}]
			}
			
			set lit ""
			set sval [readReg $src]
			
			if {$unroll == 0} {
				if {$asmR($src) == "lit"} {
					disasm $dst $mode $cond $src $sval
				} else {
					disasm $dst $mode $cond $src
				}
			}
			
			if {($cond == 0) ||
				($cond == 1 && $register(acu) == 0)   ||
				($cond == 2 && $register(acu) != 0)   ||
				($cond == 3 && $register(carry) != 0) ||
				($cond == 4 && $register(carry) == 0) ||
				($cond == 5 && $sign != 0)} {
				
				writeReg $dst $sval $mode
			}
		} else {
			# 8bit packed instruction:
			set dst [expr {($inst >> 12) & 0x7}]
			set src [expr {($inst >> 8) & 0xf}]
			set dst2 [expr {($inst >> 4) & 0xf}]
			set src2 [expr {$inst & 0xf}]
			
			if {$unroll == 0} {
				disasmPacked $dst $src $dst2 $src2
			}
			
			writeReg $dst [readReg $src] 0
			writeReg $dst2 [readReg $src2] 0
		}
	}
	
	if $sim {
		# Event unrolling. Enter the event loop once every N instruction cycle.
		# This significantly speeds up simulation but increases the granularity
		# of event processing.
		if {$unroll == 0} {
			for {set N 0} {$N < 127 && $sim} {incr N} {
				simUpdate 1
			}
			after 1 simUpdate
		}
			showInst
	} else {
		showInst
	}
}

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
			pack [entry $t.$n.e -width 9 -textvariable ramDevice($n)] -side right
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
	set fname [tk_getOpenFile -filetypes {
		{"Device Description" .dev}
		{"Tcl Code" .tcl}
		{"All Files" *}
	} -defaultextension .dev]
	if {$fname != {}} {
		set f [open $fname]
		set test [read $f 8]
		close $f
		if {$test == "#mm16dev"} {
			proc attachRamDevice {name args} \
				"return \[processAttachRamDevice \$name \$args {}\]"
			source $fname
		}
	}
}

proc loadDevice {fname args} {
	proc attachRamDevice {name args} \
		"return \[processAttachRamDevice \$name \$args [list $args]\]"
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


if {[file exists m416asm.tcl]} {
	# Requires that the m416asm.tcl file is in our working directory.
	proc assemble {src bin} {
		exec tclsh m416asm.tcl $src > $bin
	}
}
