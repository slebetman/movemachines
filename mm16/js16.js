var hex = require('hex');
var Memory = require('memory');
var Registers = require('registers');

var instCount = 0;
var PC = 0;
var ACU = 0;
var RET = 0;
var STP = 0;
var CARRY = 0;
var MPA = 0;
var MPB = 0;
var INT = 0;
var CPUCON_USR = false;
var CPUCON_PGE = false;
var CPUCON_GIE = false;
var PG = 0;
var TRAP = 0;
var INTERRUPT_TRAP = 7;
var RFI = 0;
var SBUF = 0;
var REPEAT = 0;
var INTERRUPTED = false;

var reg = new Registers(0x3f);
var RAM = new Memory();
RAM.clear();

function log (msg) {
	var l = document.createElement('div');
	l.innerHTML = msg;
	document.getElementById('logmsg').appendChild(l);
}

var decode = (function(){
	function copy (dst,src,cond,mode) {
		instCount ++;
		
		if (dst == 0) return; // lit as dest is a no-op
		
		if (cond == 0 ||(
			cond == 1 && ACU == 0)||(
			cond == 2 && ACU != 0)||(
			cond == 3 && CARRY)
		) {
			switch (mode) {
				case 0:
					var val = reg[src].read();
					reg[dst].write(val);
					break;
				case 1:
					var val = (reg[src].read() >> 8) | (reg[dst].read() & 0xff00);
					reg[dst].write(val);
					break;
				case 2:
					var val = (reg[src].read() << 8) | (reg[dst].read() & 0x00ff);
					reg[dst].write(val);
					break;
				case 3:
					var val = (reg[src].read() & 0x00ff) | (reg[dst].read() & 0xff00);
					reg[dst].write(val);
			}
		}
	}
	
	return function (word) {
		copy((word >> 8) & 0x3f, word & 0x3f, (word >> 6) & 0x03, (word >> 14) & 0x03);
	}
})();

function R (addr, name, fn) {
	reg.R(addr,name,fn);
}

function W (addr, name, fn) {
	reg.W(addr, name, fn);
}

function plainRegister (addr, name) {
	reg.plain(addr,name);
}

function setBit (val, bit) {
	return (val | (1 << bit)) & 0xffff;
}

function clearBit (val, bit) {
	return (val & (~(1 << bit))) & 0xffff;
}

function getBit (val, bit) {
	return (val & (1 << bit)) & 0xffff;
}

function interrupt (source) {
	if (!INTERRUPTED && CPUCON_GIE) {
		source &= 0xff;
		if (getBit(INT, 8+source)) {
			INTERRUPTED = true;
			setBit(INT,source);
			RFI = PC; PC = 0x0002; // ISR location
		}
	}
}

function interrupt_return (v) {
	INTERRUPTED = false;
	INT = INT & 0xff00; // clear interrupt source bits
	PC = v;
}

function clear_paging_table () {}

W(0x00,'lit',function(v){});
R(0x00,'lit',function(){
	PC++;
	return RAM[PC-1];
});

W(0x01,'pc',function(v){PC = v});
R(0x01,'pc',function(v){return PC});
W(0x02,'call',function(v){RET = PC; PC = v});
R(0x02,'ret',function(v){return RET});
plainRegister(0x03,'psp');
R(0x04,'pst',function(){
	reg.psp--;
	return RAM[reg.psp+1];
});
W(0x04,'pst',function(v){
	reg.psp++;
	RAM.set(reg.psp,v);
});

R(0x05,'acu',function(){return ACU});
W(0x05,'acu',function(v){ACU = v});
R(0x06,'inc',function(){return ACU + 1});
R(0x07,'inv',function(){return ACU ^ 0xffff});
R(0x08,'rsh',function(){return ACU >> 1});
R(0x09,'rs2',function(){return ACU >> 2});
R(0x0a,'ls2',function(){return (ACU << 2) & 0xffff});
W(0x06,'add',function(v){
	ACU += v;
	if (ACU > 0xffff) {
		CARRY = 1;
	}
	else {
		CARRY = 0;
	}
	ACU &= 0xffff;
});
W(0x07,'sub',function(v){
	ACU -= v;
	if (ACU > 0) {
		CARRY = 1;
	}
	else {
		CARRY = 0;
	}
	ACU &= 0xffff;
});
W(0x08,'and',function(v){ACU &= v});
W(0x09,'or',function(v){ACU |= v});
W(0x0a,'xor',function(v){ACU ^= v});

R(0x0b,'stp',function(){return STP});
W(0x0b,'stp',function(v){STP = v});
R(0x0c,'stk',function(){
	STP--;
	return RAM[STP+1];
});
W(0x0c,'stk',function(v){
	STP++;
	RAM.set(STP,v);
});
R(0x0d,'std',function(){return RAM[STP]});
W(0x0d,'std',function(v){RAM.set(STP,v)});
W(0x0e,'mpa',function(v){MPA = v & 0xfff0});
R(0x0e,'mpa',function(){return MPA});
W(0x0f,'mpb',function(v){MPB = v & 0xfff0});
R(0x0f,'mpb',function(){return MPB});

W(0x10,'int',function(v){INT = (INT & 0x00ff) | (v & 0xff00)});
R(0x10,'int',function(){return INT});
W(0x11,'cpucon',function(v){
	if (getBit(v,0)) CPUCON_GIE = false;
	if (getBit(v,1)) CPUCON_GIE = true;
	if (getBit(v,2)) CPUCON_PGE = false;
	if (getBit(v,3)) CPUCON_PGE = true;
	if (getBit(v,4)) CPUCON_USR = false;
	if (getBit(v,5)) CPUCON_USR = true;
	
	if (getBit(v,6)) clear_paging_table();
	
	if (getBit(v,14)) CARRY = 0;
	if (getBit(v,15)) CARRY = 1;
});
R(0x11,'cpucon',function(){
	var ret = 0x0000;
	
	if (CARRY) ret = setBit(ret,15);
	else ret = setBit(ret,14);
	
	if (CPUCON_GIE) ret = setBit(ret,1);
	else ret = setBit(ret,0);
	
	if (CPUCON_PGE) ret = setBit(ret,3);
	else ret = setBit(ret,2);
	
	if (CPUCON_USR) ret = setBit(ret,5);
	else ret = setBit(ret,4);
	
	return ret;
});
// 0x12 is paging register
W(0x13,'trap',function(v){
	TRAP = v;
	interrupt(INTERRUPT_TRAP);
});
R(0x13,'trap',function(){return TRAP});
W(0x14,'rfi',interrupt_return);
R(0x14,'rfi',function(){return RFI});
W(0x15,'sbuf',function(v){SBUF = v});
R(0x15,'sbuf',function(){return SBUF});
// 0x16 is repeat

for (var i=0x20,m=0;i<=0x2f;i++,m++) {
	R(i,'ma'+m,function(offset){
		return function(){
			return RAM[MPA+offset];
		};
	}(m));
	W(i,'ma'+m,function(offset){
		return function(v){
			RAM.set(MPA+offset,v);
		};
	}(m));
}
for (var i=0x30,m=0;i<=0x3f;i++,m++) {
	R(i,'mb'+m,function(offset){
		return function(){
			return RAM[MPB+offset];
		};
	}(m));
	W(i,'mb'+m,function(offset){
		return function(v){
			RAM.set(MPB+offset,v);
		};
	}(m));
}

function exec () {
	var instruction = RAM[PC];
	PC ++;
	decode(instruction);
}

// reg.dump(0x00, 0x3f);

function asm (dst,op,src) {
	var inst = (reg.address[dst] << 8) | reg.address[src];
	switch (op) {
		case '='   :                               break;
		case 'z='  : inst |= (1 << 6);             break;
		case 'nz=' : inst |= (2 << 6);             break;
		case 'c='  : inst |= (3 << 6);             break;
		case '/'   : inst |= (1 << 14);            break;
		case 'z/'  : inst |= (1 << 14) | (1 << 6); break;
		case 'nz/' : inst |= (1 << 14) | (2 << 6); break;
		case 'c/'  : inst |= (1 << 14) | (3 << 6); break;
		case '\\'  : inst |= (2 << 14);            break;
		case 'z\\' : inst |= (2 << 14) | (1 << 6); break;
		case 'nz\\': inst |= (2 << 14) | (2 << 6); break;
		case 'c\\' : inst |= (2 << 14) | (3 << 6); break;
		case '-'   : inst |= (3 << 14);            break;
		case 'z-'  : inst |= (3 << 14) | (1 << 6); break;
		case 'nz-' : inst |= (3 << 14) | (2 << 6); break;
		case 'c-'  : inst |= (3 << 14) | (3 << 6); break;
		default    : console.log('Invalid op: ' + op); process.exit();
	}
	return inst;
}

var program = [
	asm('mpa','=','lit'), // 0
	0x40,                 // 1
	asm('ma0','=','lit'), // 2
	0x0fff,               // 3
	asm('acu','=','lit'), // 4 -- $0
	0xfff,                // 5
	asm('stp','=','lit'), // 6
	0xff,                 // 7
	asm('sub','=','lit'), // 8 -- $1
	1,                    // 9
	asm('stk','=','acu'), // 10
	asm('pc','nz=','lit'),// 11
    8,                    // 12 -- LOOP $1
	asm('acu','=','ma0'), // 13
	asm('sub','=','lit'), // 14
	1,                    // 15
	asm('ma0','=','acu'), // 16
	asm('pc','nz=','lit'),// 17
	4,                    // 18
	asm('pc','=','lit'),  // 19 -- LOOP $0
	18
];

var program2 = [
	asm('pc','=','lit'),     // 0
	18,                      // 1
	asm('pst','=','cpucon'), // 2 -- ISR, save cpucon
	asm('pst','=','acu'),    // 3 -- save accumulator
	asm('acu','=','int'),    // 4
	asm('and','=','lit'),    // 5 -- check if TRAP
	0x0080,                  // 6
	asm('pcz','=','lit'),    // 7 -- GOTO ISR_END if not TRAP
	12,                      // 8
	asm('add','=','pst'),    // 9 -- double
	asm('cpucon','=','pst'), // 10
	asm('rfi','=','rfi'),    // 11 -- return
	asm('acu','=','pst'),    // 12
	asm('cpucon','=','pst'), // 13
	asm('rfi','=','rfi'),    // 14 -- return
	0,                       // 15
	0,                       // 16
	0,                       // 17
	asm('mpa','=','lit'),    // 18
	40,                      // 19
	asm('stp','=','lit'),    // 20
	50,                      // 21
	asm('int','=','lit'),    // 22
	0x8000,                  // 23 -- enable TRAP
	asm('cpucon','=','lit'), // 24
	0x0002,                  // 25 -- enable GIE
	asm('acu','=','lit'),    // 26
	1,                       // 27
	asm('trap','=','lit'),   // 28
	0,                       // 29 -- cause a software interrupt
	asm('ma0','=','acu'),    // 30
	asm('pc','nz=','lit'),   // 31
	28,                      // 32 -- loop until ACU overflow
	asm('pc','=','lit'),     // 33 -- GOTO forever
	33                       // 34
];

RAM.load(program2);


RAM.onchange = function (i,v) {
	// Amazingly this is fast!
	// if (i == MPA) {
	// 	process.stdout.write('\rma0 = ' + hex(v) + '  ');
	// }
	if (i == MPA) document.getElementById('stat').innerHTML = 'ma0 = ' + hex(v);
};

function exec_loop (callback) {
	//var i=500000;
	var i=1;
	var END = 33;
	
	while (i--) {
		if (PC >= END) break
		exec();
	}
	if (PC < END) {
		setTimeout(function(){
			exec_loop(callback);
		},100);
	}
	else callback();
}
 
var start = Date.now();
exec_loop(function(){
	var end = Date.now();
	
	function freq (hz) {
		if (hz < 1000) return hz.toFixed(2) + ' Hz';
		hz /= 1000;
		if (hz < 1000) return hz.toFixed(2) + ' kHz';
		hz /= 1000;
		if (hz < 1000) return hz.toFixed(2) + ' MHz';
		hz /= 1000;
		if (hz < 1000) return hz.toFixed(2) + ' GHz';
	}
	
	log(freq(instCount/((end-start)/1000)));
	log('instructions executed:' + instCount + ', elapsed time:' + (end-start)/1000);
	log('elapsed time assuming 5MHz: ' + instCount/5000000);
	
	// console.log(RAM.dump(0,0x1f));
});	