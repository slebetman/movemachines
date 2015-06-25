#! /usr/bin/env node

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

var reg = new Registers(0x3f);
var RAM = new Memory();
RAM.clear();

var decode = (function(){
	function copy (dst,src,cond,mode) {
		instCount ++;
		
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
R(0x0e,'mpa',function(v){return MPA});
W(0x0f,'mpb',function(v){MPB = v & 0xfff0});
R(0x0f,'mpb',function(v){return MPB});

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
		case '=': break;
		case 'z=': inst |= (1 << 6); break;
		case 'nz=': inst |= (2 << 6); break;
		case 'c=': inst |= (3 << 6); break;
		case '/': inst |= (1 << 14); break;
		case 'z/': inst |= (1 << 14) | (1 << 6); break;
		case 'nz/': inst |= (1 << 14) | (2 << 6); break;
		case 'c/': inst |= (1 << 14) | (3 << 6); break;
		case '\\': inst |= (2 << 14); break;
		case 'z\\': inst |= (2 << 14) | (1 << 6); break;
		case 'nz\\': inst |= (2 << 14) | (2 << 6); break;
		case 'c\\': inst |= (2 << 14) | (3 << 6); break;
		case '-': inst |= (3 << 14); break;
		case 'z-': inst |= (3 << 14) | (1 << 6); break;
		case 'nz-': inst |= (3 << 14) | (2 << 6); break;
		case 'c-': inst |= (3 << 14) | (3 << 6); break;
		default : console.log('Invalid op: ' + op); process.exit();
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

RAM.load(program);


RAM.onchange = function (i,v) {
	// Amazingly this is fast!
	if (i == MPA) {
		process.stdout.write('\rma0 = ' + hex(v) + '  ');
	}
};
 
var start = Date.now();
while (PC < 19) {
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

// console.log(RAM.dump(0,0x1f));
