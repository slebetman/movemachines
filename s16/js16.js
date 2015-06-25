#! /usr/bin/env node

var hex = require('hex');
var Memory = require('memory');
var Registers = require('registers');

var instCount = 0;
var PC = 0;
var A = 0;
var B = 0;
var CP = 0;
var DP = 0;
var CARRY = 0;

var reg = new Registers(0x0f);
var RAM = new Memory();
RAM.clear();

var decode = (function(){
	function copy (dst,src) {
		instCount ++;
		// console.log(reg[dst].name.write + ' = ' + reg[src].name.read);
		reg[dst].write(reg[src].read());
	}
	
	return function (word) {
		copy((word >> 12) & 0x0f, (word >> 8) & 0x0f);
		copy((word >> 4) & 0x0f, word & 0x0f);
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

R(0x00,'A',function(){return A});
W(0x00,'A',function(v){
	A = v;
	if ((A+B) > 0xffff) {
		CARRY = 1;
	}
	else {
		CARRY = 0;
	}
});
R(0x01,'B',function(){return B});
W(0x01,'B',function(v){
	B = v;
	if ((A+B) > 0xffff) {
		CARRY = 1;
	}
	else {
		CARRY = 0;
	}
});
R(0x02,'add',function(v){return (A+B)&0xffff});
W(0x02,'pc',function(v){PC = v});
R(0x03,'and',function(v){return A&B});
W(0x03,'pcz',function(v){
	if (((A+B)&0xffff)==0) {
		PC = v
	}
});
R(0x04,'or',function(v){return A|B});
W(0x04,'pcn',function(v){
	if ((A+B)&0xffff) {
		PC = v
	}
});
R(0x05,'xor',function(v){return A^B});
W(0x05,'pcc',function(v){if (CARRY) PC = v});
R(0x06,'rsh',function(v){return A>>1});
W(0x06,'pczc',function(v){if (RAM[CP]==0) PC = v});
R(0x07,'lit',function(v){
	var literal = RAM[PC];
	// console.log('  ' + literal);
	PC++;
	return literal;
});
W(0x07,'pczd',function(v){if (RAM[DP]==0) PC = v});

R(0x08,'Cp',function(){return CP});
W(0x08,'Cp',function(v){CP = v});
R(0x09,'C',function(){return RAM[CP]});
W(0x09,'C',function(v){RAM.set(CP,v)});
R(0x0a,'C-',function(){
	CP--;
	return RAM[CP+1];
});
W(0x0a,'+C',function(v){
	CP++;
	RAM.set(CP,v);
});
R(0x0b,'C+',function(){
	CP++;
	return RAM[CP-1];
});
W(0x0b,'-C',function(v){
	CP--;
	RAM.set(CP,v);
});

R(0x0c,'Dp',function(){return DP});
W(0x0c,'Dp',function(v){DP = v});
R(0x0d,'D',function(){return RAM[DP]});
W(0x0d,'D',function(v){RAM.set(DP,v)});
R(0x0e,'-D',function(){
	DP--;
	return RAM[DP];
});
W(0x0e,'D+',function(v){
	DP++;
	RAM.set(DP-1,v);
});
R(0x0f,'+D',function(){
	DP++;
	return RAM[DP];
});
W(0x0f,'D-',function(v){
	DP--;
	RAM.set(DP+1,v);
});

function exec () {
	var instruction = RAM[PC];
	PC ++;
	decode(instruction);
}

// reg.dump(0x00, 0x1f);

function asm (dst,src,dst2,src2) {
	var inst = (reg.address[dst] << 12) | (reg.address[src] << 8);
	if (dst2 && src2) {
		inst |= (reg.address[dst2] << 4) | reg.address[src2];
	}
	return inst;
}

var program = [
	asm('Dp','lit',  // 0
		'D','lit'),
	0x40,            // 1
	0x0fff,          // 2
	asm('A','lit',   // 3 -- $0
		'B','lit'),
	0xfff,           // 4
	0xffff,          // 5 (-1)
	asm('Cp','lit'), // 6
	0xff,            // 7
	asm('A','add',   // 8 -- $1
		'+C','A'),
	asm('pcn','lit'),// 9 -- LOOP $1
    8,               // 10
	asm('A','D',     // 11
		'D','add'),
	asm('pcn','lit'),// 12
	3,               // 13
	asm('pc','lit'), // 14
	14
];

RAM.load(program);

RAM.onchange = function (i,v) {
	// Amazingly this is fast!
	if (i == DP) {
		process.stdout.write('\rD = ' + hex(v) + '  ');
	}
};
 
var start = Date.now();
while (PC < 14) {
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

console.log(RAM.dump(0,0x1f));
