#! /usr/bin/env node

var hex = require('hex');
var Memory = require('memory');
var Registers = require('registers');

var instCount = 0;
var PC = 0;
var ACU = 0;
var RET = 0;
var A_PTR = 0;
var CARRY = 0;

var reg = new Registers(0x7f);
var RAM = new Memory();
RAM.clear();

var decode = (function(){
	function copy (dst,src) {
		instCount ++;
		var val = reg[src].read();
		reg[dst].write(val);
	}
	
	function literal (dst,val) {
		instCount ++;
		reg[dst].write(val);
	}
	
	return function (word) {
		var format = (word & 0xc000) >> 14;
		
		if (format == 0) {
			// 16 bit instruction
			copy(word >> 7, word & 0x7f);
		}
		else if (format == 1) {
			// short literal
			literal((word >> 12) & 0x03, word & 0x0fff);
		}
		else {
			// packed instruction
			copy((word >> 12) & 0x07, (word >> 8) & 0x0f),
			copy((word >> 4) & 0x0f, word & 0x0f)
		}
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

// plainRegister(0x00,'acu');
R(0x00,'acu',function(){return ACU});
W(0x00,'acu',function(v){ACU = v});
R(0x01,'one',function(){return 0x0001});
R(0x02,'nil',function(){return 0x0000});
R(0x03,'all',function(){return 0xffff});
W(0x01,'add',function(v){
	ACU += v;
	if (ACU > 0xffff) {
		CARRY = 1;
	}
	else {
		CARRY = 0;
	}
	ACU &= 0xffff;
});
W(0x02,'sub',function(v){
	ACU -= v;
	if (ACU < 0) {
		CARRY = 0;
	}
	else {
		CARRY = 1;
	}
	ACU &= 0xffff;
});
W(0x03,'and',function(v){ACU &= v});
R(0x04,'rsh',function(){return ACU >> 1});
W(0x04,'or',function(v){ACU |= v});
// plainRegister(0x05,'*a');
R(0x05,'*a',function(){return A_PTR});
W(0x05,'*a',function(v){A_PTR = v});
R(0x28,'inv',function(){return ACU ^ 0xffff});
W(0x28,'xor',function(v){ACU ^= v});
plainRegister(0x2c,'*b');
plainRegister(0x2f,'pc');
W(0x2f,'pc',function(v){RET = PC; PC = v});
//plainRegister(0x32,'ret');
R(0x32,'ret',function(){return RET});
W(0x32,'ret',function(v){RET = v});
plainRegister(0x33,'*m');
W(0x33,'*m',function(v){reg['*m'] = v & 0xffe0});
R(0x06,'a',function(){return RAM[A_PTR]});
W(0x06,'a',function(v){RAM.set(A_PTR,v)});
R(0x07,'a-',function(){
	A_PTR--;
	return RAM[A_PTR+1];
});
W(0x07,'+a',function(v){
	A_PTR++;
	RAM.set(A_PTR,v);
});
R(0x29,'a+',function(){
	A_PTR++;
	return RAM[A_PTR-1];
});
W(0x29,'-a',function(v){
	A_PTR--;
	RAM.set(A_PTR,v);
});
R(0x2a,'high',function(){
	return (RAM[A_PTR] >> 8) & 0x00ff;
});
W(0x2a,'high',function(v){
	var mval = RAM[A_PTR] & 0x00ff;
	RAM[A_PTR] = mval | ((v << 8) & 0xff00);
});
R(0x2b,'low',function(){
	return RAM[A_PTR] & 0x00ff;
});
W(0x2b,'low',function(v){
	var mval = RAM[A_PTR] & 0xff00;
	RAM[A_PTR] = mval | (v & 0x00ff);
});
R(0x2d,'b',function(){return RAM[reg['*b']]});
W(0x2d,'b',function(v){RAM.set(reg['*b'],v)});
R(0x2e,'b-',function(){
	reg['*b']--;
	return RAM[reg['*b']+1];
});
W(0x2e,'+b',function(v){
	reg['*b']++;
	RAM.set(reg['*b'],v);
});
W(0x30,'pcz',function(v){
	if (ACU == 0) {
		RET = PC; PC = v
	}
});
R(0x30,'lit',function(){
	PC++;
	return RAM[PC-1];
});
W(0x31,'pcc',function(v){
	if (CARRY) {
		RET = PC; PC = v
	}
});
R(0x31,'conf',function(){return 0x0001});

for (var i=0x08,m=0;i<=0x27;i++,m++) {
	R(i,'m'+m,function(offset){
		return function(){
			return RAM[reg['*m']+offset];
		};
	}(m));
	W(i,'m'+m,function(offset){
		return function(v){
			RAM.set(reg['*m']+offset,v);
		};
	}(m));
}

function exec () {
	var instruction = RAM[PC];
	PC ++;
	decode(instruction);
}

// reg.dump(0x00, 0x35);

function asm (dst,src) {
	return (reg.address[dst] << 7) | reg.address[src]
}

function asmpack (dst1,src1,dst2,src2) {
	dst1 = reg.address[dst1];
	dst2 = reg.address[dst2];
	src1 = reg.address[src1];
	src2 = reg.address[src2];
	
	if (dst1 > 0x7) throw "dst1 out of range";
	if (dst2 > 0xf) throw "dst2 out of range";
	if (src1 > 0xf) throw "src1 out of range";
	if (src2 > 0xf) throw "src2 out of range";
	
	return 0x8000 | (dst1<<12) | (src1<<8) | (dst2<<4) | src2;
}

function asmlit (dst,val) {
	dst = reg.address[dst];
	
	if (dst > 0x3) throw "dst out of range";
	if (val > 0xfff) throw "lit too big";
	
	return 0x4000 | (dst<<12) | val;
}

var program1 = [
	asm('*m','lit'),  // 0
	0x40,             // 1
	asm('m0','lit'),  // 2
	0x0fff,           // 3
	
	asmlit('acu',0xfff), // 4 -- $0
	asm('*a','lit'),  // 5
	0xff,             // 6
	
	asmpack('sub','one','+a','acu'), // 7 -- $1
	asm('pcz','lit'), // 8
    12,               // 9
	asm('pc','lit'),  // 10
	7,                // 11 -- LOOP $1
	
	asmpack('acu','m0','sub','one'),  // 12
	asm('m0','acu'),  // 13
	asm('pcz','lit'), // 14
	18,               // 15
	asm('pc','lit'),  // 16
	4,                // 17 -- LOOP $0
	
	asm('pc','lit'),  // 18
	18
];

var program2 = [
	asm('*m','lit'),  // 0
	0x40,             // 1
	asm('m0','lit'),  // 2
	0x0fff,           // 3
	
	asmlit('acu',0xfff), // 4 -- $0
	asm('*a','lit'),  // 5
	0xff,             // 6
	
	asm('sub','one'), // 7 -- $1
	asm('+a','acu'),  // 8
	asm('pcz','lit'), // 9
	13,               // 10
	asm('pc','lit'),  // 11
	7,                // 12 -- LOOP $1
	
	asm('acu','m0'),  // 13
	asm('sub','one'), // 14
	asm('m0','acu'),  // 15
	asm('pcz','lit'), // 16
	20,               // 17
	asm('pc','lit'),  // 18
	4,                // 19 -- LOOP $0
	
	asm('pc','lit'),  // 20
	20
];

RAM.load(program2);


RAM.onchange = function (i,v) {
	// Amazingly this is fast!
	// if (i == reg['*m']) {
	// 	process.stdout.write('\rm0 = ' + hex(v) + '  ');
	// }
};

while (PC < 20) {
	exec();
}

PC = 0;
instCount = 0;

var start = Date.now();
while (PC < 20) {
	exec();
}
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

console.log(freq(instCount/((end-start)/1000)));
console.log('instructions executed:' + instCount + ', elapsed time:' + (end-start)/1000);
console.log('elapsed time assuming 5MHz: ' + instCount/5000000);

// console.log(RAM.dump(0,0xff));

// clear();
// 
// var start = Date.now();
// function loop () {
// 	for (var i=10000000;i--;) exec();
// 	// if (reg.pc >= 20) {
// 	// 	var end = Date.now();
// 	// 	console.log(freq(instCount/((end-start)/1000)));
// 	// }
// 	// else {
// 		setTimeout(loop,0);
// 	// }
// }
// loop();
// 
// setInterval(function(){
// 	process.stdout.write(GOTO(0,2) + freq(instCount/2) + '  ');
// 	instCount = 0;
// },2000);
// 
// function ESC (txt) {
// 	return '\x1b' + txt;
// }
// 
// function ESC_ (txt) {
// 	return ESC('[');
// }
// 
// function GOTO (x, y) {
// 	return ESC('[' + y + ';' + x + 'H');
// }
// 
// function clear () {
// 	process.stdout.write(ESC('[2J'));
// }