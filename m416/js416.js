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
var MP = 0;

var reg = new Registers(0x1f);
var RAM = new Memory();
RAM.clear();

var decode = (function(){
	function copy (dst,src,cond,mode) {
		instCount ++;
		
		if (cond == 0 ||(
			cond == 1 && ACU == 0)||(
			cond == 2 && ACU != 0)||(
			cond == 3 && CARRY)||(
			cond == 4 && !CARRY)||(
			cond == 5 && (ACU & 0x8000))
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
		var format = (word & 0x8000) >> 15;
		
		if (format == 0) {
			// 16 bit instruction
			copy((word >> 8) & 0x1f, word & 0x1f, (word >> 5) & 0x07, (word >> 13) & 0x03);
		}
		else if (format == 1) {
			// packed instruction
			copy((word >> 12) & 0x07, (word >> 8) & 0x0f,0,0);
			copy((word >> 4) & 0x0f, word & 0x0f,0,0);
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
W(0x02,'and',function(v){ACU &= v});
W(0x03,'or',function(v){ACU |= v});
W(0x04,'xor',function(v){ACU ^= v});
R(0x04,'rsh',function(){return ACU >> 1});
R(0x05,'stp',function(){return STP});
W(0x05,'stp',function(v){STP = v});
R(0x06,'std',function(){return RAM[STP]});
W(0x06,'std',function(v){RAM.set(STP,v)});
R(0x07,'stk',function(){
	STP--;
	return RAM[STP+1];
});
W(0x07,'stk',function(v){
	STP++;
	RAM.set(STP,v);
});

for (var i=0x08,m=0;i<=0x0f;i++,m++) {
	R(i,'m'+m,function(offset){
		return function(){
			return RAM[MP+offset];
		};
	}(m));
	W(i,'m'+m,function(offset){
		return function(v){
			RAM.set(MP+offset,v);
		};
	}(m));
}

W(0x10,'lit',function(v){});
R(0x10,'lit',function(){
	PC++;
	return RAM[PC-1];
});
W(0x11,'pc',function(v){RET = PC; PC = v});
R(0x11,'pc',function(v){return PC});
W(0x12,'ret',function(v){RET = v});
R(0x12,'ret',function(v){return RET});
plainRegister(0x13,'psp');
R(0x14,'pst',function(){
	reg.psp--;
	return RAM[reg.psp+1];
});
W(0x14,'pst',function(v){
	reg.psp++;
	RAM.set(reg.psp,v);
});
W(0x15,'mp',function(v){MP = v & 0xfff8});
R(0x15,'mp',function(v){return MP});

function exec () {
	var instruction = RAM[PC];
	PC ++;
	decode(instruction);
}

// reg.dump(0x00, 0x1f);

function asm (dst,op,src) {
	var inst = (reg.address[dst] << 8) | reg.address[src];
	switch (op) {
		case '=': break;
		case 'z=': inst |= (1 << 5); break;
		case 'nz=': inst |= (2 << 5); break;
		case 'c=': inst |= (3 << 5); break;
		case 'nc=': inst |= (4 << 5); break;
		case 's=': inst |= (5 << 5); break;
		case '/': inst |= (1 << 13); break;
		case 'z/': inst |= (1 << 13) | (1 << 5); break;
		case 'nz/': inst |= (1 << 13) | (2 << 5); break;
		case 'c/': inst |= (1 << 13) | (3 << 5); break;
		case 'nc/': inst |= (1 << 13) | (4 << 5); break;
		case 's/': inst |= (1 << 13) | (5 << 5); break;
		case '\\': inst |= (2 << 13); break;
		case 'z\\': inst |= (2 << 13) | (1 << 5); break;
		case 'nz\\': inst |= (2 << 13) | (2 << 5); break;
		case 'c\\': inst |= (2 << 13) | (3 << 5); break;
		case 'nc\\': inst |= (2 << 13) | (4 << 5); break;
		case 's\\': inst |= (2 << 13) | (5 << 5); break;
		case '-': inst |= (3 << 13); break;
		case 'z-': inst |= (3 << 13) | (1 << 5); break;
		case 'nz-': inst |= (3 << 13) | (2 << 5); break;
		case 'c-': inst |= (3 << 13) | (3 << 5); break;
		case 'nc-': inst |= (3 << 13) | (4 << 5); break;
		case 's-': inst |= (3 << 13) | (5 << 5); break;
		default : console.log('Invalid op: ' + op); process.exit();
	}
	return inst;
}

var program = [
	asm('mp','=','lit'),  // 0
	0x40,                 // 1
	asm('m0','=','lit'),  // 2
	0x0fff,               // 3
	asm('acu','=','lit'), // 4 -- $0
	0xfff,                // 5
	asm('stp','=','lit'), // 6
	0xff,                 // 7
	asm('add','=','all'), // 8 -- $1
	asm('stk','=','acu'), // 9
	asm('pc','nz=','lit'),// 10
    8,                    // 11 -- LOOP $1
	asm('acu','=','m0'),  // 12
	asm('add','=','all'), // 13
	asm('m0','=','acu'),  // 14
	asm('pc','nz=','lit'),// 15
	4,                    // 16 -- LOOP $0
	asm('pc','=','lit'),  // 17
	18
];

RAM.load(program);


RAM.onchange = function (i,v) {
	// Amazingly this is fast!
	if (i == MP) {
		process.stdout.write('\rm0 = ' + hex(v) + '  ');
	}
};
 
var start = Date.now();
while (PC < 17) {
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
